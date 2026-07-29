/* ============================================================================
MSBF M1.7 Source Quality & Data Confidence — Generation
Version : v0.2
Purpose : Create one governed application/source snapshot for each of seven
          approved source families.

Performance design learned from M1.6:
  * Read accepted physical M1.4/M1.5 histories directly.
  * Use bounded, materialized aggregations over accepted daily histories.
  * Materialize the 750-row merchant inputs and the 5,250-row source grid once.
  * Never rebuild M1.4, M1.5, or M1.6 wide blueprints.
  * Materialize expected and actual canonical snapshots exactly once.
  * Disable JIT and apply a bounded statement timeout for fail-fast operation.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='15min';

INSERT INTO msbf_ref.acceptance_gate_catalog(
    gate_id, gate_name, module_code, severity, description
)
VALUES(
    'M1_7_SOURCE_QUALITY_CONFIDENCE',
    'M1.7 Source Quality and Data Confidence',
    'M1',
    'BLOCKING',
    'Application/source availability, depth, freshness, completeness, reconciliation, confidence, fallback, deterministic reproduction, and stage-boundary acceptance.'
)
ON CONFLICT(gate_id) DO NOTHING;

CREATE OR REPLACE FUNCTION msbf_m1.m1_7_source_row_hash(
    p_module1_run_id bigint,
    p_merchant_application_id text,
    p_source_code text,
    p_source_contract_id bigint,
    p_as_of_timestamp timestamptz,
    p_history_start_date date,
    p_history_end_date date,
    p_expected_observation_count integer,
    p_observed_observation_count integer,
    p_completeness_rate numeric,
    p_freshness_age_hours integer,
    p_reconciliation_rate numeric,
    p_availability_status text,
    p_quality_status text,
    p_data_confidence_score numeric,
    p_fallback_path_code text
)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $fn$
SELECT md5(
    concat_ws(
        '|',
        coalesce(p_module1_run_id::text,'<NULL>'),
        coalesce(p_merchant_application_id,'<NULL>'),
        coalesce(p_source_code,'<NULL>'),
        coalesce(p_source_contract_id::text,'<NULL>'),
        coalesce(to_char(p_as_of_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS'),'<NULL>'),
        coalesce(p_history_start_date::text,'<NULL>'),
        coalesce(p_history_end_date::text,'<NULL>'),
        coalesce(p_expected_observation_count::text,'<NULL>'),
        coalesce(p_observed_observation_count::text,'<NULL>'),
        coalesce(to_char(p_completeness_rate::numeric(9,6),'FM9999999990.000000'),'<NULL>'),
        coalesce(p_freshness_age_hours::text,'<NULL>'),
        coalesce(to_char(p_reconciliation_rate::numeric(9,6),'FM9999999990.000000'),'<NULL>'),
        coalesce(p_availability_status,'<NULL>'),
        coalesce(p_quality_status,'<NULL>'),
        coalesce(to_char(p_data_confidence_score::numeric(9,6),'FM9999999990.000000'),'<NULL>'),
        coalesce(p_fallback_path_code,'<NULL>')
    )
);
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_7_actual_source_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text, row_hash text)
LANGUAGE sql
STABLE
AS $fn$
SELECT
    s.merchant_application_id || '|' || s.source_code AS entity_key,
    msbf_m1.m1_7_source_row_hash(
        s.module1_run_id,
        s.merchant_application_id,
        s.source_code,
        s.source_contract_id,
        s.as_of_timestamp,
        s.history_start_date,
        s.history_end_date,
        s.expected_observation_count,
        s.observed_observation_count,
        s.completeness_rate,
        s.freshness_age_hours,
        s.reconciliation_rate,
        s.availability_status,
        s.quality_status,
        s.data_confidence_score,
        s.fallback_path_code
    ) AS row_hash
FROM msbf_m1.source_snapshot s
WHERE s.module1_run_id=p_run_id;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_7_assert_configuration(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_as_of_date date;
    v_parameter_rows integer;
    v_parameter_names integer;
    v_missing_values integer;
    v_source_rows integer;
    v_ready_sources integer;
    v_invalid_contracts integer;
    v_pos_min numeric;
    v_dep_min numeric;
    v_fresh_pass numeric;
    v_fresh_warn numeric;
    v_complete_pass numeric;
    v_complete_warn numeric;
    v_recon_pass numeric;
    v_recon_warn numeric;
    v_pos_penalty numeric;
    v_dep_penalty numeric;
    v_conflict_threshold numeric;
BEGIN
    SELECT as_of_date
      INTO STRICT v_as_of_date
      FROM msbf_ctl.run_registry
     WHERE run_id=p_run_id;

    SELECT count(*),
           count(DISTINCT parameter_name),
           count(*) FILTER (
               WHERE NOT (resolved_value ? 'value_numeric')
                  OR resolved_value->>'value_numeric' IS NULL
           )
      INTO v_parameter_rows, v_parameter_names, v_missing_values
      FROM msbf_ctl.run_parameter_snapshot
     WHERE run_id=p_run_id
       AND (
           (
               scope_key='GLOBAL'
               AND parameter_name IN (
                   'pos_minimum_history_days',
                   'deposit_minimum_history_days',
                   'source_freshness_pass_days',
                   'source_freshness_warning_days',
                   'source_completeness_pass_rate',
                   'source_completeness_warning_rate',
                   'pos_deposit_reconciliation_pass_rate',
                   'pos_deposit_reconciliation_warning_rate',
                   'missing_pos_source_confidence_penalty',
                   'missing_deposit_source_confidence_penalty',
                   'source_conflict_manual_review_threshold'
               )
           )
           OR (
               scope_key LIKE 'SOURCE:%'
               AND parameter_name='source_outage_probability'
           )
       );

    IF v_parameter_rows<>18 OR v_parameter_names<>12 OR v_missing_values<>0 THEN
        RAISE EXCEPTION
            'M1.7 configuration requires 18 typed parameter rows across 12 names; observed rows %, names %, missing typed values %.',
            v_parameter_rows, v_parameter_names, v_missing_values;
    END IF;

    SELECT
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='pos_minimum_history_days' AND scope_key='GLOBAL'),
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='deposit_minimum_history_days' AND scope_key='GLOBAL'),
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='source_freshness_pass_days' AND scope_key='GLOBAL'),
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='source_freshness_warning_days' AND scope_key='GLOBAL'),
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='source_completeness_pass_rate' AND scope_key='GLOBAL'),
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='source_completeness_warning_rate' AND scope_key='GLOBAL'),
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='pos_deposit_reconciliation_pass_rate' AND scope_key='GLOBAL'),
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='pos_deposit_reconciliation_warning_rate' AND scope_key='GLOBAL'),
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='missing_pos_source_confidence_penalty' AND scope_key='GLOBAL'),
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='missing_deposit_source_confidence_penalty' AND scope_key='GLOBAL'),
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='source_conflict_manual_review_threshold' AND scope_key='GLOBAL')
      INTO
        v_pos_min, v_dep_min, v_fresh_pass, v_fresh_warn,
        v_complete_pass, v_complete_warn, v_recon_pass, v_recon_warn,
        v_pos_penalty, v_dep_penalty, v_conflict_threshold
      FROM msbf_ctl.run_parameter_snapshot
     WHERE run_id=p_run_id;

    IF v_pos_min<1 OR v_dep_min<1
       OR v_fresh_pass<0 OR v_fresh_warn<v_fresh_pass
       OR v_complete_warn NOT BETWEEN 0 AND 1
       OR v_complete_pass NOT BETWEEN 0 AND 1
       OR v_complete_warn>v_complete_pass
       OR v_recon_warn NOT BETWEEN 0 AND 1
       OR v_recon_pass NOT BETWEEN 0 AND 1
       OR v_recon_warn>v_recon_pass
       OR v_pos_penalty NOT BETWEEN 0 AND 1
       OR v_dep_penalty NOT BETWEEN 0 AND 1
       OR v_conflict_threshold<1
    THEN
        RAISE EXCEPTION 'M1.7 global threshold configuration is invalid or non-monotonic.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM msbf_ctl.run_parameter_snapshot
        WHERE run_id=p_run_id
          AND parameter_name='source_outage_probability'
          AND (resolved_value->>'value_numeric')::numeric NOT BETWEEN 0 AND 1
    ) THEN
        RAISE EXCEPTION 'M1.7 source-outage probabilities must be within [0,1].';
    END IF;

    SELECT count(*),
           count(*) FILTER (
               WHERE rss.quality_status='CONTRACT_READY_PRE_GENERATION'
                 AND sc.status='APPROVED'
                 AND sc.effective_start_date<=v_as_of_date
                 AND (sc.effective_end_date IS NULL OR sc.effective_end_date>v_as_of_date)
                 AND rc.active_flag
           ),
           count(*) FILTER (
               WHERE sc.required_history_days<0
                  OR sc.minimum_completeness_rate NOT BETWEEN 0 AND 1
                  OR (sc.reconciliation_tolerance_rate IS NOT NULL
                      AND sc.reconciliation_tolerance_rate NOT BETWEEN 0 AND 1)
           )
      INTO v_source_rows, v_ready_sources, v_invalid_contracts
      FROM msbf_ctl.run_source_snapshot rss
      JOIN msbf_ctl.source_contract sc
        ON sc.source_contract_id=rss.source_contract_id
      JOIN msbf_ref.source_code rc
        ON rc.source_code=rss.source_code
     WHERE rss.run_id=p_run_id;

    IF v_source_rows<>7 OR v_ready_sources<>7 OR v_invalid_contracts<>0 THEN
        RAISE EXCEPTION
            'M1.7 requires seven approved, effective, contract-ready source families; rows %, ready %, invalid contracts %.',
            v_source_rows, v_ready_sources, v_invalid_contracts;
    END IF;

    IF (
        SELECT string_agg(source_code,',' ORDER BY source_code)
        FROM msbf_ctl.run_source_snapshot
        WHERE run_id=p_run_id
    ) IS DISTINCT FROM
       'BUSINESS_CREDIT,COLLATERAL_AVAILABILITY,DEPOSIT_DAILY,OBLIGATIONS,OWNER_CREDIT,POS_DAILY,VERIFICATION'
    THEN
        RAISE EXCEPTION 'M1.7 source-family set does not match the governed seven-source contract.';
    END IF;
END;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_7_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_status text;
    v_existing bigint;
    v_applications bigint;
    v_pos bigint;
    v_deposit bigint;
    v_pos_scenario bigint;
    v_deposit_scenario bigint;
    v_downstream bigint;
    v_gate text;
    v_errors bigint;
BEGIN
    PERFORM msbf_m1.m1_7_assert_configuration(p_run_id);

    SELECT run_status
      INTO STRICT v_status
      FROM msbf_ctl.run_registry
     WHERE run_id=p_run_id
     FOR UPDATE;

    IF v_status<>'M1_6_ACCEPTED' THEN
        RAISE EXCEPTION 'M1.7 generation requires M1_6_ACCEPTED; observed %.', v_status;
    END IF;

    SELECT count(*)
      INTO v_existing
      FROM msbf_m1.source_snapshot
     WHERE module1_run_id=p_run_id;

    IF v_existing<>0 THEN
        RAISE EXCEPTION 'M1.7 source snapshots already exist: %.', v_existing;
    END IF;

    SELECT count(*) INTO v_applications
      FROM msbf_m1.merchant_application
     WHERE created_by_run_id=p_run_id;
    SELECT count(*) INTO v_pos
      FROM msbf_m1.merchant_pos_daily_base
     WHERE generated_by_run_id=p_run_id;
    SELECT count(*) INTO v_deposit
      FROM msbf_m1.merchant_deposit_daily_base
     WHERE generated_by_run_id=p_run_id;
    SELECT count(*) INTO v_pos_scenario
      FROM msbf_m1.merchant_pos_daily_scenario
     WHERE generated_by_run_id=p_run_id;
    SELECT count(*) INTO v_deposit_scenario
      FROM msbf_m1.merchant_deposit_daily_scenario
     WHERE generated_by_run_id=p_run_id;

    IF v_applications<>750 OR v_pos<>135000 OR v_deposit<>135000
       OR v_pos_scenario<>270000 OR v_deposit_scenario<>270000
    THEN
        RAISE EXCEPTION
            'M1.7 accepted-history prerequisites failed: applications %, POS %, deposit %, scenario POS %, scenario deposit %.',
            v_applications, v_pos, v_deposit, v_pos_scenario, v_deposit_scenario;
    END IF;

    SELECT result_status
      INTO v_gate
      FROM msbf_ctl.acceptance_gate_result
     WHERE run_id=p_run_id
       AND gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS'
     ORDER BY review_version DESC
     LIMIT 1;

    IF v_gate IS DISTINCT FROM 'PASS' THEN
        RAISE EXCEPTION 'M1.7 requires the latest M1.6 gate to be PASS; observed %.', coalesce(v_gate,'<NULL>');
    END IF;

    SELECT
        (SELECT count(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=p_run_id)
      + (SELECT count(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=p_run_id)
      + (SELECT count(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=p_run_id)
      + (SELECT count(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=p_run_id)
      + (SELECT count(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=p_run_id)
      + (SELECT count(*) FROM msbf_m1.verification_result WHERE created_by_run_id=p_run_id)
      + (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=p_run_id)
      + (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=p_run_id)
      + (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=p_run_id)
      + (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=p_run_id)
      + (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=p_run_id)
      INTO v_downstream;

    IF v_downstream<>0 THEN
        RAISE EXCEPTION 'M1.7 downstream stage tables are not empty: % rows.', v_downstream;
    END IF;

    SELECT count(*)
      INTO v_errors
      FROM msbf_ctl.profile_resolution_error
     WHERE run_id=p_run_id AND severity='BLOCKING';

    IF v_errors<>0 THEN
        RAISE EXCEPTION 'M1.7 cannot start with % blocking configuration errors.', v_errors;
    END IF;
END;
$fn$;

DO $notice$
BEGIN
    RAISE NOTICE 'M1.7 Phase 1/5 — validate configuration and materialize accepted inputs';
END;
$notice$;

CREATE TEMP TABLE _m1_7_ctx ON COMMIT DROP AS
SELECT
    r.run_id,
    r.population_id,
    r.as_of_date,
    p.history_start_date,
    p.history_end_date,
    p.deterministic_seed_version,
    ((r.as_of_date + time '23:59:59') AT TIME ZONE 'UTC') AS as_of_timestamp,
    (max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='pos_minimum_history_days' AND s.scope_key='GLOBAL'))::integer AS pos_min_days,
    (max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='deposit_minimum_history_days' AND s.scope_key='GLOBAL'))::integer AS deposit_min_days,
    (max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='source_freshness_pass_days' AND s.scope_key='GLOBAL'))::integer AS fresh_pass_days,
    (max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='source_freshness_warning_days' AND s.scope_key='GLOBAL'))::integer AS fresh_warn_days,
    max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='source_completeness_pass_rate' AND s.scope_key='GLOBAL') AS complete_pass,
    max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='source_completeness_warning_rate' AND s.scope_key='GLOBAL') AS complete_warn,
    max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='pos_deposit_reconciliation_pass_rate' AND s.scope_key='GLOBAL') AS recon_pass,
    max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='pos_deposit_reconciliation_warning_rate' AND s.scope_key='GLOBAL') AS recon_warn,
    max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='missing_pos_source_confidence_penalty' AND s.scope_key='GLOBAL') AS missing_pos_penalty,
    max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='missing_deposit_source_confidence_penalty' AND s.scope_key='GLOBAL') AS missing_deposit_penalty,
    (max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='source_conflict_manual_review_threshold' AND s.scope_key='GLOBAL'))::integer AS conflict_review_threshold,
    (SELECT count(*) FROM msbf_ref.verification_check_code WHERE active_flag) AS verification_check_count
FROM msbf_ctl.run_registry r
JOIN msbf_m1.population_registry p
  ON p.population_id=r.population_id
JOIN msbf_ctl.run_parameter_snapshot s
  ON s.run_id=r.run_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
  AND r.run_version=1
GROUP BY
    r.run_id,
    r.population_id,
    r.as_of_date,
    p.history_start_date,
    p.history_end_date,
    p.deterministic_seed_version;

SELECT msbf_m1.m1_7_assert_generation_ready(run_id)
FROM _m1_7_ctx;

CREATE TEMP TABLE _m1_7_sources ON COMMIT DROP AS
SELECT
    rss.source_code,
    rss.source_contract_id,
    sc.required_history_days,
    sc.freshness_sla_hours,
    sc.minimum_completeness_rate,
    sc.reconciliation_tolerance_rate,
    rc.restricted_data_flag,
    (rps.resolved_value->>'value_numeric')::numeric AS outage_probability
FROM msbf_ctl.run_source_snapshot rss
JOIN msbf_ctl.source_contract sc
  ON sc.source_contract_id=rss.source_contract_id
JOIN msbf_ref.source_code rc
  ON rc.source_code=rss.source_code
JOIN msbf_ctl.run_parameter_snapshot rps
  ON rps.run_id=rss.run_id
 AND rps.parameter_name='source_outage_probability'
 AND rps.scope_key='SOURCE:' || rss.source_code
WHERE rss.run_id=(SELECT run_id FROM _m1_7_ctx)
  AND rss.quality_status='CONTRACT_READY_PRE_GENERATION'
  AND sc.status='APPROVED';
CREATE UNIQUE INDEX ON _m1_7_sources(source_code);

CREATE TEMP TABLE _m1_7_liq_profile ON COMMIT DROP AS
SELECT merchant_id, deposit_source_available_flag, merchant_capture_rate
FROM msbf_m1.m1_5_merchant_liquidity_profile((SELECT run_id FROM _m1_7_ctx));
CREATE UNIQUE INDEX ON _m1_7_liq_profile(merchant_id);

CREATE TEMP TABLE _m1_7_apps ON COMMIT DROP AS
SELECT
    a.merchant_application_id,
    a.merchant_id,
    a.processor_account_id,
    a.partner_channel_id,
    a.application_date,
    a.as_of_date,
    pa.processor_account_open_date,
    mm.merchant_size_tier,
    ia.industry_code,
    oc.owner_count,
    lp.deposit_source_available_flag,
    lp.merchant_capture_rate
FROM msbf_m1.merchant_application a
JOIN msbf_m1.processor_account pa
  ON pa.processor_account_id=a.processor_account_id
JOIN msbf_m1.merchant_master mm
  ON mm.merchant_id=a.merchant_id
JOIN msbf_m1.merchant_industry_assignment ia
  ON ia.merchant_id=a.merchant_id
 AND ia.assignment_type='PRIMARY'
JOIN (
    SELECT merchant_id, count(*)::integer AS owner_count
    FROM msbf_m1.merchant_owner_guarantor
    WHERE created_by_run_id=(SELECT run_id FROM _m1_7_ctx)
    GROUP BY merchant_id
) oc
  ON oc.merchant_id=a.merchant_id
JOIN _m1_7_liq_profile lp
  ON lp.merchant_id=a.merchant_id
WHERE a.created_by_run_id=(SELECT run_id FROM _m1_7_ctx);
CREATE UNIQUE INDEX ON _m1_7_apps(merchant_application_id);
CREATE INDEX ON _m1_7_apps(merchant_id);
ANALYZE _m1_7_sources;
ANALYZE _m1_7_apps;

DO $notice$
BEGIN
    RAISE NOTICE 'M1.7 Phase 2/5 — aggregate accepted daily histories once and calculate paired-source state';
END;
$notice$;

CREATE TEMP TABLE _m1_7_daily_agg ON COMMIT DROP AS
SELECT
    p.merchant_id,
    count(*) FILTER (
        WHERE p.observation_date>=a.processor_account_open_date
    )::integer AS active_calendar_rows,
    count(*) FILTER (
        WHERE p.observation_date>=a.processor_account_open_date
          AND p.data_connection_status IN ('CONNECTED','DELAYED')
    )::integer AS pos_observed_rows,
    min(p.observation_date) FILTER (
        WHERE p.observation_date>=a.processor_account_open_date
          AND p.data_connection_status IN ('CONNECTED','DELAYED')
    ) AS pos_observed_start_date,
    max(p.observation_date) FILTER (
        WHERE p.observation_date>=a.processor_account_open_date
          AND p.data_connection_status IN ('CONNECTED','DELAYED')
    ) AS pos_observed_end_date,
    coalesce(sum(p.net_merchant_proceeds) FILTER (
        WHERE p.observation_date>=a.processor_account_open_date
          AND p.data_connection_status IN ('CONNECTED','DELAYED')
    ),0)::numeric AS aligned_net_proceeds,
    coalesce(sum(d.deposit_amount) FILTER (
        WHERE p.observation_date>=a.processor_account_open_date
          AND p.data_connection_status IN ('CONNECTED','DELAYED')
    ),0)::numeric AS aligned_deposits
FROM msbf_m1.merchant_pos_daily_base p
JOIN msbf_m1.merchant_deposit_daily_base d
  ON d.population_id=p.population_id
 AND d.merchant_id=p.merchant_id
 AND d.observation_date=p.observation_date
JOIN _m1_7_apps a
  ON a.merchant_id=p.merchant_id
WHERE p.generated_by_run_id=(SELECT run_id FROM _m1_7_ctx)
  AND d.generated_by_run_id=(SELECT run_id FROM _m1_7_ctx)
GROUP BY p.merchant_id;
CREATE UNIQUE INDEX ON _m1_7_daily_agg(merchant_id);
ANALYZE _m1_7_daily_agg;

CREATE TEMP TABLE _m1_7_pair_state ON COMMIT DROP AS
SELECT
    a.merchant_application_id,
    (
        msbf_ctl.deterministic_uniform(
            a.merchant_application_id,
            c.deterministic_seed_version || ':M1_7:POS_DAILY:OUTAGE'
        ) < (SELECT outage_probability FROM _m1_7_sources WHERE source_code='POS_DAILY')
    ) AS pos_outage_flag,
    (
        NOT a.deposit_source_available_flag
        OR msbf_ctl.deterministic_uniform(
            a.merchant_application_id,
            c.deterministic_seed_version || ':M1_7:DEPOSIT_DAILY:OUTAGE'
        ) < (SELECT outage_probability FROM _m1_7_sources WHERE source_code='DEPOSIT_DAILY')
    ) AS deposit_outage_flag
FROM _m1_7_apps a
CROSS JOIN _m1_7_ctx c;
CREATE UNIQUE INDEX ON _m1_7_pair_state(merchant_application_id);

DO $notice$
BEGIN
    RAISE NOTICE 'M1.7 Phase 3/5 — transform the 5,250-row application/source grid';
END;
$notice$;

CREATE TEMP TABLE _m1_7_grid ON COMMIT DROP AS
SELECT
    c.*,
    a.merchant_application_id,
    a.merchant_id,
    a.processor_account_id,
    a.partner_channel_id,
    a.application_date,
    a.as_of_date AS application_as_of_date,
    a.processor_account_open_date,
    a.merchant_size_tier,
    a.industry_code,
    a.owner_count,
    a.deposit_source_available_flag,
    a.merchant_capture_rate,
    s.source_code,
    s.source_contract_id,
    s.required_history_days,
    s.freshness_sla_hours,
    s.minimum_completeness_rate,
    s.reconciliation_tolerance_rate,
    s.restricted_data_flag,
    s.outage_probability,
    greatest(
        0,
        a.as_of_date-greatest(c.history_start_date,a.processor_account_open_date)+1
    )::integer AS active_days,
    ps.pos_outage_flag,
    ps.deposit_outage_flag,
    msbf_ctl.deterministic_uniform(
        a.merchant_application_id,
        c.deterministic_seed_version || ':M1_7:' || s.source_code || ':OUTAGE'
    ) AS u_outage,
    msbf_ctl.deterministic_uniform(
        a.merchant_application_id,
        c.deterministic_seed_version || ':M1_7:' || s.source_code || ':FRESH'
    ) AS u_fresh,
    msbf_ctl.deterministic_uniform(
        a.merchant_application_id,
        c.deterministic_seed_version || ':M1_7:' || s.source_code || ':PARTIAL'
    ) AS u_partial,
    msbf_ctl.deterministic_uniform(
        a.merchant_application_id,
        c.deterministic_seed_version || ':M1_7:' || s.source_code || ':PARTIAL_COUNT'
    ) AS u_partial_count,
    msbf_ctl.deterministic_uniform(
        a.merchant_application_id,
        c.deterministic_seed_version || ':M1_7:' || s.source_code || ':CONFLICT'
    ) AS u_conflict,
    da.pos_observed_rows,
    da.pos_observed_start_date,
    da.pos_observed_end_date,
    da.aligned_net_proceeds,
    da.aligned_deposits,
    CASE
        WHEN coalesce(da.aligned_net_proceeds,0)<=0
         AND coalesce(da.aligned_deposits,0)<=0
            THEN 1::numeric
        WHEN coalesce(da.aligned_net_proceeds,0)<=0
          OR coalesce(da.aligned_deposits,0)<=0
            THEN 0::numeric
        ELSE least(
            da.aligned_deposits
                / nullif(da.aligned_net_proceeds*a.merchant_capture_rate,0),
            (da.aligned_net_proceeds*a.merchant_capture_rate)
                / nullif(da.aligned_deposits,0),
            1::numeric
        )
    END AS merchant_reconciliation_score
FROM _m1_7_apps a
JOIN _m1_7_pair_state ps
  ON ps.merchant_application_id=a.merchant_application_id
LEFT JOIN _m1_7_daily_agg da
  ON da.merchant_id=a.merchant_id
CROSS JOIN _m1_7_ctx c
CROSS JOIN _m1_7_sources s;
CREATE INDEX ON _m1_7_grid(merchant_application_id,source_code);

CREATE TEMP TABLE _m1_7_raw ON COMMIT DROP AS
WITH expected AS (
    SELECT
        g.*,
        CASE g.source_code
            WHEN 'POS_DAILY' THEN g.active_days
            WHEN 'DEPOSIT_DAILY' THEN g.active_days
            WHEN 'OWNER_CREDIT' THEN g.owner_count
            WHEN 'VERIFICATION' THEN g.verification_check_count
            ELSE 1
        END::integer AS expected_count,
        CASE g.source_code
            WHEN 'BUSINESS_CREDIT' THEN floor(8*g.u_fresh)::integer
            WHEN 'OWNER_CREDIT' THEN floor(10*g.u_fresh)::integer
            WHEN 'VERIFICATION' THEN floor(4*g.u_fresh)::integer
            WHEN 'OBLIGATIONS' THEN floor(7*g.u_fresh)::integer
            WHEN 'COLLATERAL_AVAILABILITY' THEN floor(12*g.u_fresh)::integer
            ELSE 0
        END AS point_freshness_days,
        CASE g.source_code
            WHEN 'POS_DAILY' THEN g.pos_outage_flag
            WHEN 'DEPOSIT_DAILY' THEN g.deposit_outage_flag
            ELSE g.u_outage<g.outage_probability
        END AS outage_flag,
        (
            g.source_code IN ('OWNER_CREDIT','VERIFICATION')
            AND (
                CASE g.source_code
                    WHEN 'OWNER_CREDIT' THEN g.owner_count
                    WHEN 'VERIFICATION' THEN g.verification_check_count
                END
            )>1
            AND g.u_partial<least(0.25,g.outage_probability*2.0)
        ) AS partial_flag
    FROM _m1_7_grid g
),
observed AS (
    SELECT
        e.*,
        CASE
            WHEN e.outage_flag THEN 0
            WHEN e.source_code='POS_DAILY' THEN coalesce(e.pos_observed_rows,0)
            WHEN e.source_code='DEPOSIT_DAILY' THEN e.expected_count
            WHEN e.partial_flag THEN greatest(
                1,
                e.expected_count
                  - 1
                  - floor(e.u_partial_count*least(2,e.expected_count-1))::integer
            )
            ELSE e.expected_count
        END::integer AS observed_count
    FROM expected e
),
metrics AS (
    SELECT
        o.*,
        CASE
            WHEN o.expected_count=0 THEN 1::numeric
            ELSE o.observed_count::numeric/o.expected_count
        END AS completeness_calc,
        CASE
            WHEN o.observed_count=0 THEN NULL::date
            WHEN o.source_code='POS_DAILY' THEN o.pos_observed_start_date
            WHEN o.source_code='DEPOSIT_DAILY'
                THEN greatest(o.history_start_date,o.processor_account_open_date)
            ELSE o.application_as_of_date-o.point_freshness_days
        END AS source_history_start,
        CASE
            WHEN o.observed_count=0 THEN NULL::date
            WHEN o.source_code='POS_DAILY' THEN o.pos_observed_end_date
            WHEN o.source_code='DEPOSIT_DAILY' THEN o.application_as_of_date
            ELSE o.application_as_of_date-o.point_freshness_days
        END AS source_history_end,
        CASE
            WHEN o.observed_count=0 THEN 999999
            WHEN o.source_code='POS_DAILY'
                THEN greatest(0,(o.application_as_of_date-o.pos_observed_end_date)*24)
            WHEN o.source_code='DEPOSIT_DAILY' THEN 0
            ELSE o.point_freshness_days*24
        END::integer AS freshness_hours_calc,
        CASE
            WHEN o.source_code IN ('POS_DAILY','DEPOSIT_DAILY')
             AND NOT o.pos_outage_flag
             AND NOT o.deposit_outage_flag
                THEN greatest(0,least(1,o.merchant_reconciliation_score))::numeric
            ELSE NULL::numeric
        END AS reconciliation_calc,
        CASE
            WHEN o.source_code='POS_DAILY'
                THEN greatest(o.pos_min_days,o.required_history_days)
            WHEN o.source_code='DEPOSIT_DAILY'
                THEN greatest(o.deposit_min_days,o.required_history_days)
            ELSE 0
        END::integer AS effective_required_history_days,
        greatest(o.complete_pass,o.minimum_completeness_rate) AS effective_complete_pass,
        least(greatest(o.complete_warn,0),greatest(o.complete_pass,o.minimum_completeness_rate))
            AS effective_complete_warn,
        least(
            o.fresh_pass_days*24,
            coalesce(o.freshness_sla_hours,o.fresh_pass_days*24)
        )::integer AS effective_fresh_pass_hours,
        greatest(
            o.fresh_warn_days*24,
            least(o.fresh_pass_days*24,
                  coalesce(o.freshness_sla_hours,o.fresh_pass_days*24))
        )::integer AS effective_fresh_warn_hours,
        greatest(
            o.recon_pass,
            CASE
                WHEN o.reconciliation_tolerance_rate IS NULL THEN 0
                ELSE 1-o.reconciliation_tolerance_rate
            END
        ) AS effective_recon_pass,
        least(
            greatest(o.recon_warn,0),
            greatest(
                o.recon_pass,
                CASE
                    WHEN o.reconciliation_tolerance_rate IS NULL THEN 0
                    ELSE 1-o.reconciliation_tolerance_rate
                END
            )
        ) AS effective_recon_warn
    FROM observed o
),
classified AS (
    SELECT
        m.*,
        CASE
            WHEN m.observed_count=0 THEN 'UNAVAILABLE'
            WHEN m.observed_count<m.expected_count THEN 'PARTIAL'
            ELSE 'AVAILABLE'
        END AS availability_calc,
        (
            CASE
                WHEN m.source_code IN ('POS_DAILY','DEPOSIT_DAILY')
                    THEN NOT m.pos_outage_flag
                     AND NOT m.deposit_outage_flag
                     AND m.merchant_reconciliation_score<m.effective_recon_warn
                ELSE NOT m.outage_flag
                 AND m.u_conflict<m.outage_probability*0.40
            END
        ) AS conflict_flag,
        (
            CASE
                WHEN m.source_code IN ('POS_DAILY','DEPOSIT_DAILY')
                    THEN m.observed_count>=m.effective_required_history_days
                ELSE true
            END
        ) AS history_sufficient_flag
    FROM metrics m
),
quality AS (
    SELECT
        c.*,
        CASE
            WHEN c.observed_count=0 THEN 'UNAVAILABLE'
            WHEN c.conflict_flag THEN 'CONFLICT'
            WHEN NOT c.history_sufficient_flag THEN 'FAIL'
            WHEN c.completeness_calc>=c.effective_complete_pass
             AND c.freshness_hours_calc<=c.effective_fresh_pass_hours
             AND (
                 c.reconciliation_calc IS NULL
                 OR c.reconciliation_calc>=c.effective_recon_pass
             )
                THEN 'PASS'
            WHEN c.completeness_calc>=c.effective_complete_warn
             AND c.freshness_hours_calc<=c.effective_fresh_warn_hours
             AND (
                 c.reconciliation_calc IS NULL
                 OR c.reconciliation_calc>=c.effective_recon_warn
             )
                THEN 'WARNING'
            ELSE 'FAIL'
        END AS quality_calc
    FROM classified c
),
scored AS (
    SELECT
        q.*,
        CASE
            WHEN q.observed_count=0 THEN 0::numeric
            ELSE greatest(
                0,
                least(
                    1,
                    0.35*CASE WHEN q.observed_count<q.expected_count THEN 0.70 ELSE 1 END
                  + 0.30*q.completeness_calc
                  + 0.20*CASE
                        WHEN q.freshness_hours_calc<=q.effective_fresh_pass_hours THEN 1
                        WHEN q.freshness_hours_calc<=q.effective_fresh_warn_hours THEN 0.75
                        ELSE 0.35
                    END
                  + 0.15*coalesce(q.reconciliation_calc,1)
                  - CASE WHEN q.conflict_flag THEN 0.25 ELSE 0 END
                  - CASE WHEN NOT q.history_sufficient_flag THEN 0.25 ELSE 0 END
                )
            )
        END AS confidence_calc
    FROM quality q
)
SELECT
    s.*,
    CASE
        WHEN s.quality_calc='PASS' THEN 'NONE'
        WHEN s.conflict_flag THEN 'MANUAL_REVIEW_SOURCE_CONFLICT'
        WHEN s.source_code='POS_DAILY' AND s.observed_count=0 THEN 'FAIL_CLOSED_NO_POS'
        WHEN s.source_code='VERIFICATION' AND s.observed_count=0 THEN 'FAIL_CLOSED_VERIFICATION'
        WHEN s.source_code='DEPOSIT_DAILY' AND s.observed_count=0 THEN 'POS_ONLY'
        WHEN s.source_code='BUSINESS_CREDIT' AND s.observed_count=0 THEN 'CASHFLOW_OWNER_FALLBACK'
        WHEN s.source_code='OWNER_CREDIT' AND s.observed_count=0 THEN 'BUSINESS_CASHFLOW_REVIEW'
        WHEN s.source_code='OBLIGATIONS' AND s.observed_count=0 THEN 'MANUAL_OBLIGATION_REVIEW'
        WHEN s.source_code='COLLATERAL_AVAILABILITY' AND s.observed_count=0 THEN 'UNSECURED_PATH'
        WHEN s.source_code='POS_DAILY' AND NOT s.history_sufficient_flag
            THEN 'INSUFFICIENT_POS_HISTORY'
        WHEN s.source_code='DEPOSIT_DAILY' AND NOT s.history_sufficient_flag
            THEN 'INSUFFICIENT_DEPOSIT_HISTORY'
        WHEN s.quality_calc='WARNING' THEN 'SOURCE_REFRESH'
        ELSE 'MANUAL_REVIEW_DATA_QUALITY'
    END AS fallback_calc
FROM scored s;
CREATE UNIQUE INDEX ON _m1_7_raw(merchant_application_id,source_code);
ANALYZE _m1_7_raw;

CREATE TEMP TABLE _m1_7_blueprint ON COMMIT DROP AS
SELECT
    run_id AS module1_run_id,
    merchant_application_id,
    source_code,
    source_contract_id,
    as_of_timestamp,
    source_history_start AS history_start_date,
    source_history_end AS history_end_date,
    expected_count AS expected_observation_count,
    observed_count AS observed_observation_count,
    round(completeness_calc,6)::numeric(9,6) AS completeness_rate,
    freshness_hours_calc AS freshness_age_hours,
    CASE
        WHEN reconciliation_calc IS NULL THEN NULL
        ELSE round(reconciliation_calc,6)::numeric(9,6)
    END AS reconciliation_rate,
    availability_calc AS availability_status,
    quality_calc AS quality_status,
    round(confidence_calc,6)::numeric(9,6) AS data_confidence_score,
    fallback_calc AS fallback_path_code,
    msbf_m1.m1_7_source_row_hash(
        run_id,
        merchant_application_id,
        source_code,
        source_contract_id,
        as_of_timestamp,
        source_history_start,
        source_history_end,
        expected_count,
        observed_count,
        round(completeness_calc,6),
        freshness_hours_calc,
        CASE
            WHEN reconciliation_calc IS NULL THEN NULL
            ELSE round(reconciliation_calc,6)
        END,
        availability_calc,
        quality_calc,
        round(confidence_calc,6),
        fallback_calc
    ) AS source_hash
FROM _m1_7_raw;
CREATE UNIQUE INDEX ON _m1_7_blueprint(merchant_application_id,source_code);

DO $countcheck$
DECLARE
    v_rows bigint;
    v_apps bigint;
    v_sources integer;
BEGIN
    SELECT count(*),
           count(DISTINCT merchant_application_id),
           count(DISTINCT source_code)
      INTO v_rows, v_apps, v_sources
      FROM _m1_7_blueprint;

    IF v_rows<>5250 OR v_apps<>750 OR v_sources<>7 THEN
        RAISE EXCEPTION
            'M1.7 blueprint cardinality failed: rows %, applications %, sources %.',
            v_rows, v_apps, v_sources;
    END IF;
END;
$countcheck$;

DO $notice$
BEGIN
    RAISE NOTICE 'M1.7 Phase 4/5 — persist snapshots, refresh statistics, and reconcile canonical rows';
END;
$notice$;

INSERT INTO msbf_m1.source_snapshot(
    module1_run_id,
    merchant_application_id,
    source_code,
    source_contract_id,
    as_of_timestamp,
    history_start_date,
    history_end_date,
    expected_observation_count,
    observed_observation_count,
    completeness_rate,
    freshness_age_hours,
    reconciliation_rate,
    availability_status,
    quality_status,
    data_confidence_score,
    fallback_path_code,
    source_hash
)
SELECT
    module1_run_id,
    merchant_application_id,
    source_code,
    source_contract_id,
    as_of_timestamp,
    history_start_date,
    history_end_date,
    expected_observation_count,
    observed_observation_count,
    completeness_rate,
    freshness_age_hours,
    reconciliation_rate,
    availability_status,
    quality_status,
    data_confidence_score,
    fallback_path_code,
    source_hash
FROM _m1_7_blueprint;

ANALYZE msbf_m1.source_snapshot;

CREATE TEMP TABLE _m1_7_expected ON COMMIT DROP AS
SELECT
    merchant_application_id || '|' || source_code AS entity_key,
    source_hash AS row_hash
FROM _m1_7_blueprint;
CREATE UNIQUE INDEX ON _m1_7_expected(entity_key);

CREATE TEMP TABLE _m1_7_actual ON COMMIT DROP AS
SELECT *
FROM msbf_m1.m1_7_actual_source_snapshot((SELECT run_id FROM _m1_7_ctx));
CREATE UNIQUE INDEX ON _m1_7_actual(entity_key);
ANALYZE _m1_7_expected;
ANALYZE _m1_7_actual;

DO $evidence$
DECLARE
    v_run_id bigint;
    v_expected bigint;
    v_actual bigint;
    v_mismatch bigint;
    v_expected_hash text;
    v_actual_hash text;
    v_pass bigint;
    v_warning bigint;
    v_fail bigint;
    v_unavailable bigint;
    v_conflict bigint;
    v_fallback bigint;
BEGIN
    SELECT run_id INTO v_run_id FROM _m1_7_ctx;

    SELECT count(*),
           md5(string_agg(entity_key || '|' || row_hash,'||' ORDER BY entity_key))
      INTO v_expected, v_expected_hash
      FROM _m1_7_expected;

    SELECT count(*),
           md5(string_agg(entity_key || '|' || row_hash,'||' ORDER BY entity_key))
      INTO v_actual, v_actual_hash
      FROM _m1_7_actual;

    SELECT count(*)
      INTO v_mismatch
      FROM _m1_7_expected e
      FULL JOIN _m1_7_actual a USING(entity_key)
     WHERE e.row_hash IS DISTINCT FROM a.row_hash;

    SELECT
        count(*) FILTER (WHERE quality_status='PASS'),
        count(*) FILTER (WHERE quality_status='WARNING'),
        count(*) FILTER (WHERE quality_status='FAIL'),
        count(*) FILTER (WHERE availability_status='UNAVAILABLE'),
        count(*) FILTER (WHERE quality_status='CONFLICT'),
        count(*) FILTER (WHERE fallback_path_code<>'NONE')
      INTO v_pass, v_warning, v_fail, v_unavailable, v_conflict, v_fallback
      FROM msbf_m1.source_snapshot
     WHERE module1_run_id=v_run_id;

    IF v_expected<>5250
       OR v_actual<>5250
       OR v_mismatch<>0
       OR v_expected_hash IS DISTINCT FROM v_actual_hash
    THEN
        RAISE EXCEPTION
            'M1.7 canonical reconciliation failed: expected %, actual %, mismatches %, hashes % / %.',
            v_expected, v_actual, v_mismatch, v_expected_hash, v_actual_hash;
    END IF;

    INSERT INTO msbf_ctl.run_evidence(
        run_id,
        evidence_code,
        segment_key,
        metric_name,
        metric_value_text,
        unit_code,
        status,
        interpretation
    )
    VALUES
    (
        v_run_id,
        'M1_7_GENERATION_SPEC',
        'PORTFOLIO',
        'M1.7 generation specification',
        'Seven source families; bounded accepted-history aggregation; one materialized M1.5 merchant profile; 5,250 deterministic snapshots; paired POS/deposit outage and reconciliation logic; no wide blueprint regeneration.',
        'TEXT',
        'PASS',
        'Governed M1.7 source-quality generation design.'
    ),
    (
        v_run_id,
        'M1_7_SOURCE_SET_HASH',
        'PORTFOLIO',
        'M1.7 source-snapshot set hash',
        v_actual_hash,
        'MD5',
        'PASS',
        'Persisted source-snapshot hashes reconcile to the generation blueprint.'
    ),
    (
        v_run_id,
        'M1_7_GENERATION_CANONICAL_RECON',
        'PORTFOLIO',
        'M1.7 canonical reconciliation',
        format('expected=%s actual=%s mismatches=%s',v_expected,v_actual,v_mismatch),
        'TEXT',
        'PASS',
        'Generation-time expected and actual canonical snapshots reconcile.'
    ),
    (
        v_run_id,
        'M1_7_GENERATION_SUMMARY',
        'PORTFOLIO',
        'M1.7 source-quality generation summary',
        format(
            'rows=5250 pass=%s warning=%s fail=%s unavailable=%s conflict=%s fallback=%s',
            v_pass,v_warning,v_fail,v_unavailable,v_conflict,v_fallback
        ),
        'TEXT',
        'PASS',
        'Source availability, quality, confidence, conflict, and fallback snapshots generated.'
    ),
    (
        v_run_id,
        'M1_7_GENERATION_EXPECTED_ROWS',
        'PORTFOLIO',
        'M1.7 expected canonical rows',
        v_expected::text,
        'COUNT',
        'PASS',
        'Expected generation row count.'
    ),
    (
        v_run_id,
        'M1_7_GENERATION_ACTUAL_ROWS',
        'PORTFOLIO',
        'M1.7 actual canonical rows',
        v_actual::text,
        'COUNT',
        'PASS',
        'Actual persisted row count.'
    ),
    (
        v_run_id,
        'M1_7_GENERATION_ROW_MISMATCHES',
        'PORTFOLIO',
        'M1.7 row-level mismatches',
        v_mismatch::text,
        'COUNT',
        'PASS',
        'Zero deterministic row mismatches required.'
    )
    ON CONFLICT(run_id,evidence_code,segment_key)
    DO UPDATE SET
        metric_name=EXCLUDED.metric_name,
        metric_value_numeric=NULL,
        metric_value_text=EXCLUDED.metric_value_text,
        unit_code=EXCLUDED.unit_code,
        status=EXCLUDED.status,
        threshold_value_numeric=NULL,
        interpretation=EXCLUDED.interpretation,
        created_at=clock_timestamp();

    UPDATE msbf_ctl.run_registry
       SET run_status='M1_7_GENERATED',
           completed_at=NULL,
           notes=coalesce(notes,'')
               || E'\nM1.7 source-quality snapshots generated: 5,250 rows; set hash '
               || v_actual_hash || '.'
     WHERE run_id=v_run_id;
END;
$evidence$;

DO $notice$
BEGIN
    RAISE NOTICE 'M1.7 Phase 5/5 — committed generation checkpoint';
END;
$notice$;

COMMIT;

WITH r AS (
    SELECT run_id, run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
)
SELECT
    r.run_id,
    r.run_status,
    (SELECT count(*) FROM msbf_m1.source_snapshot
      WHERE module1_run_id=r.run_id) AS source_snapshot_rows,
    (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.source_snapshot
      WHERE module1_run_id=r.run_id) AS applications,
    (SELECT count(DISTINCT source_code) FROM msbf_m1.source_snapshot
      WHERE module1_run_id=r.run_id) AS source_codes,
    (SELECT count(*) FROM msbf_m1.source_snapshot
      WHERE module1_run_id=r.run_id AND fallback_path_code<>'NONE') AS fallback_rows,
    (SELECT metric_value_text FROM msbf_ctl.run_evidence
      WHERE run_id=r.run_id AND evidence_code='M1_7_SOURCE_SET_HASH') AS source_set_hash,
    (SELECT metric_value_text FROM msbf_ctl.run_evidence
      WHERE run_id=r.run_id AND evidence_code='M1_7_GENERATION_CANONICAL_RECON') AS canonical_reconciliation,
    CASE
        WHEN r.run_status='M1_7_GENERATED'
         AND (SELECT count(*) FROM msbf_m1.source_snapshot
               WHERE module1_run_id=r.run_id)=5250
        THEN 'PASS'
        ELSE 'FAIL'
    END AS generation_status
FROM r;
