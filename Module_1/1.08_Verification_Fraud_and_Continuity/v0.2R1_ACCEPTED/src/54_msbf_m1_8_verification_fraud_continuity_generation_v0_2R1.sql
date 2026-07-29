/* ============================================================================
MSBF M1.8 Verification, Fraud & Processor Continuity — Generation
Version : v0.2R1
Purpose : Generate six application-level verification/fraud checks and one
          independent application-level fraud/continuity summary for every
          accepted application.
Performance design:
  * Read accepted physical M1.4/M1.6 histories directly and aggregate once.
  * Materialize 750-row application inputs and 4,500-row check output once.
  * Never rebuild M1.4, M1.5, M1.6, or M1.7 business blueprints.
  * Recompute downstream hashes from persisted physical fields only.
  * Keep data confidence, fraud risk, processor continuity, and credit risk
    explicitly separate.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='15min';

CREATE OR REPLACE FUNCTION msbf_m1.m1_8_verification_row_hash(
    p_merchant_application_id text,
    p_check_code text,
    p_check_version integer,
    p_as_of_timestamp timestamptz,
    p_result_status text,
    p_risk_tier smallint,
    p_hard_stop boolean,
    p_manual_review boolean,
    p_result_reason_code text,
    p_evidence_payload jsonb,
    p_source_snapshot_id bigint,
    p_created_by_run_id bigint
)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $fn$
SELECT md5(concat_ws('|',
    coalesce(p_merchant_application_id,'<NULL>'),
    coalesce(p_check_code,'<NULL>'),
    coalesce(p_check_version::text,'<NULL>'),
    coalesce(to_char(p_as_of_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS'),'<NULL>'),
    coalesce(p_result_status,'<NULL>'),
    coalesce(p_risk_tier::text,'<NULL>'),
    coalesce(p_hard_stop::text,'<NULL>'),
    coalesce(p_manual_review::text,'<NULL>'),
    coalesce(p_result_reason_code,'<NULL>'),
    coalesce(p_evidence_payload::text,'<NULL>'),
    coalesce(p_source_snapshot_id::text,'<NULL>'),
    coalesce(p_created_by_run_id::text,'<NULL>')
));
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_8_summary_row_hash(
    p_module1_run_id bigint,
    p_merchant_application_id text,
    p_as_of_timestamp timestamptz,
    p_verification_source_snapshot_id bigint,
    p_pos_source_snapshot_id bigint,
    p_deposit_source_snapshot_id bigint,
    p_verification_pass_count smallint,
    p_verification_review_count smallint,
    p_verification_fail_count smallint,
    p_verification_unavailable_count smallint,
    p_critical_fail_count smallint,
    p_fraud_score numeric,
    p_fraud_risk_tier smallint,
    p_processor_continuity_status text,
    p_processor_continuity_risk_tier smallint,
    p_stress_processor_continuity_status text,
    p_stress_processor_continuity_risk_tier smallint,
    p_processor_active_day_rate numeric,
    p_processor_degraded_day_rate numeric,
    p_processor_outage_day_rate numeric,
    p_recent_processor_outage_day_rate numeric,
    p_data_connection_gap_day_rate numeric,
    p_stress_processor_degraded_day_rate numeric,
    p_stress_processor_outage_day_rate numeric,
    p_stress_data_connection_gap_day_rate numeric,
    p_continuity_stress_worsening_flag boolean,
    p_hard_stop_recommended_flag boolean,
    p_manual_review_recommended_flag boolean,
    p_verification_disposition text,
    p_primary_reason_code text,
    p_secondary_reason_codes text[],
    p_fraud_reason_flags jsonb,
    p_created_by_run_id bigint
)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $fn$
SELECT md5(concat_ws('|',
    coalesce(p_module1_run_id::text,'<NULL>'),
    coalesce(p_merchant_application_id,'<NULL>'),
    coalesce(to_char(p_as_of_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS'),'<NULL>'),
    coalesce(p_verification_source_snapshot_id::text,'<NULL>'),
    coalesce(p_pos_source_snapshot_id::text,'<NULL>'),
    coalesce(p_deposit_source_snapshot_id::text,'<NULL>'),
    coalesce(p_verification_pass_count::text,'<NULL>'),
    coalesce(p_verification_review_count::text,'<NULL>'),
    coalesce(p_verification_fail_count::text,'<NULL>'),
    coalesce(p_verification_unavailable_count::text,'<NULL>'),
    coalesce(p_critical_fail_count::text,'<NULL>'),
    coalesce(to_char(p_fraud_score::numeric(9,6),'FM999999990.000000'),'<NULL>'),
    coalesce(p_fraud_risk_tier::text,'<NULL>'),
    coalesce(p_processor_continuity_status,'<NULL>'),
    coalesce(p_processor_continuity_risk_tier::text,'<NULL>'),
    coalesce(p_stress_processor_continuity_status,'<NULL>'),
    coalesce(p_stress_processor_continuity_risk_tier::text,'<NULL>'),
    coalesce(to_char(p_processor_active_day_rate::numeric(9,6),'FM0.000000'),'<NULL>'),
    coalesce(to_char(p_processor_degraded_day_rate::numeric(9,6),'FM0.000000'),'<NULL>'),
    coalesce(to_char(p_processor_outage_day_rate::numeric(9,6),'FM0.000000'),'<NULL>'),
    coalesce(to_char(p_recent_processor_outage_day_rate::numeric(9,6),'FM0.000000'),'<NULL>'),
    coalesce(to_char(p_data_connection_gap_day_rate::numeric(9,6),'FM0.000000'),'<NULL>'),
    coalesce(to_char(p_stress_processor_degraded_day_rate::numeric(9,6),'FM0.000000'),'<NULL>'),
    coalesce(to_char(p_stress_processor_outage_day_rate::numeric(9,6),'FM0.000000'),'<NULL>'),
    coalesce(to_char(p_stress_data_connection_gap_day_rate::numeric(9,6),'FM0.000000'),'<NULL>'),
    coalesce(p_continuity_stress_worsening_flag::text,'<NULL>'),
    coalesce(p_hard_stop_recommended_flag::text,'<NULL>'),
    coalesce(p_manual_review_recommended_flag::text,'<NULL>'),
    coalesce(p_verification_disposition,'<NULL>'),
    coalesce(p_primary_reason_code,'<NULL>'),
    coalesce(array_to_string(p_secondary_reason_codes,','),'<NULL>'),
    coalesce(p_fraud_reason_flags::text,'<NULL>'),
    coalesce(p_created_by_run_id::text,'<NULL>')
));
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_8_actual_verification_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text)
LANGUAGE sql
STABLE
AS $fn$
SELECT
    v.merchant_application_id || '|' || v.check_code AS entity_key,
    msbf_m1.m1_8_verification_row_hash(
        v.merchant_application_id,v.check_code,v.check_version,v.as_of_timestamp,
        v.result_status,v.risk_tier,v.hard_stop_recommended_flag,
        v.manual_review_recommended_flag,v.result_reason_code,v.evidence_payload,
        v.source_snapshot_id,v.created_by_run_id
    ) AS row_hash
FROM msbf_m1.verification_result v
WHERE v.created_by_run_id=p_run_id;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_8_actual_summary_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text)
LANGUAGE sql
STABLE
AS $fn$
SELECT
    s.merchant_application_id AS entity_key,
    msbf_m1.m1_8_summary_row_hash(
        s.module1_run_id,s.merchant_application_id,s.as_of_timestamp,
        s.verification_source_snapshot_id,s.pos_source_snapshot_id,s.deposit_source_snapshot_id,
        s.verification_pass_count,s.verification_review_count,s.verification_fail_count,
        s.verification_unavailable_count,s.critical_fail_count,s.fraud_score,s.fraud_risk_tier,
        s.processor_continuity_status,s.processor_continuity_risk_tier,
        s.stress_processor_continuity_status,s.stress_processor_continuity_risk_tier,
        s.processor_active_day_rate,s.processor_degraded_day_rate,s.processor_outage_day_rate,
        s.recent_processor_outage_day_rate,s.data_connection_gap_day_rate,
        s.stress_processor_degraded_day_rate,s.stress_processor_outage_day_rate,
        s.stress_data_connection_gap_day_rate,s.continuity_stress_worsening_flag,
        s.hard_stop_recommended_flag,s.manual_review_recommended_flag,
        s.verification_disposition,s.primary_reason_code,s.secondary_reason_codes,
        s.fraud_reason_flags,s.created_by_run_id
    ) AS row_hash
FROM msbf_m1.application_verification_fraud_snapshot s
WHERE s.module1_run_id=p_run_id;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_8_actual_entity_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text)
LANGUAGE sql
STABLE
AS $fn$
SELECT 'VERIFICATION|'||entity_key,row_hash
FROM msbf_m1.m1_8_actual_verification_snapshot(p_run_id)
UNION ALL
SELECT 'SUMMARY|'||entity_key,row_hash
FROM msbf_m1.m1_8_actual_summary_snapshot(p_run_id);
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_8_assert_configuration(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_as_of_date date;
    v_parameter_rows integer;
    v_parameter_names integer;
    v_missing_boolean integer;
    v_missing_numeric integer;
    v_check_rows integer;
    v_check_set text;
    v_policy_rows integer;
    v_policy_status text;
    v_policy jsonb;
    v_source_rows integer;
    v_source_apps integer;
    v_source_families integer;
    v_t2 numeric; v_t3 numeric; v_t4 numeric; v_t5 numeric;
BEGIN
    SELECT as_of_date INTO STRICT v_as_of_date
    FROM msbf_ctl.run_registry WHERE run_id=p_run_id;

    SELECT count(*),count(DISTINCT parameter_name),
           count(*) FILTER (
               WHERE parameter_name IN ('verification_hard_stop_check','verification_review_check')
                 AND (NOT (resolved_value?'value_boolean') OR resolved_value->>'value_boolean' IS NULL)
           ),
           count(*) FILTER (
               WHERE parameter_name NOT IN ('verification_hard_stop_check','verification_review_check')
                 AND (NOT (resolved_value?'value_numeric') OR resolved_value->>'value_numeric' IS NULL)
           )
    INTO v_parameter_rows,v_parameter_names,v_missing_boolean,v_missing_numeric
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=p_run_id
      AND (
          (scope_key='GLOBAL' AND parameter_name IN (
              'fraud_base_probability','bank_account_mismatch_fraud_points',
              'processor_mismatch_fraud_points','identity_conflict_fraud_points',
              'abnormal_refund_fraud_points','abnormal_chargeback_fraud_points',
              'fraud_tier_2_threshold','fraud_tier_3_threshold',
              'fraud_tier_4_threshold','fraud_tier_5_threshold'
          ))
          OR (scope_key LIKE 'VERIFICATION_CHECK:%'
              AND parameter_name IN ('verification_hard_stop_check','verification_review_check'))
      );

    IF v_parameter_rows<>22 OR v_parameter_names<>12 OR v_missing_boolean<>0 OR v_missing_numeric<>0 THEN
        RAISE EXCEPTION 'M1.8 requires 22 typed parameter rows across 12 names; rows %, names %, missing boolean %, missing numeric %.',
            v_parameter_rows,v_parameter_names,v_missing_boolean,v_missing_numeric;
    END IF;

    SELECT
        max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='fraud_tier_2_threshold'),
        max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='fraud_tier_3_threshold'),
        max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='fraud_tier_4_threshold'),
        max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='fraud_tier_5_threshold')
    INTO v_t2,v_t3,v_t4,v_t5
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=p_run_id AND scope_key='GLOBAL';

    IF NOT (v_t2<v_t3 AND v_t3<v_t4 AND v_t4<v_t5 AND v_t2>=0 AND v_t5<=100) THEN
        RAISE EXCEPTION 'M1.8 fraud thresholds must be strictly increasing within [0,100].';
    END IF;

    SELECT count(*),string_agg(check_code,',' ORDER BY check_code)
    INTO v_check_rows,v_check_set
    FROM msbf_ref.verification_check_code WHERE active_flag;

    IF v_check_rows<>6 OR v_check_set<>'BANK_ACCOUNT_MATCH,BENEFICIAL_OWNER,FRAUD_SCREEN,KYB_ENTITY,PROCESSOR_MATCH,SANCTIONS' THEN
        RAISE EXCEPTION 'M1.8 requires six active verification checks; rows %, set %.',v_check_rows,v_check_set;
    END IF;

    SELECT count(*),max(status),(jsonb_agg(profile_payload))->0
    INTO v_policy_rows,v_policy_status,v_policy
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY'
      AND profile_version=1
      AND effective_start_date<=v_as_of_date
      AND (effective_end_date IS NULL OR effective_end_date>v_as_of_date);

    IF v_policy_rows<>1 OR v_policy_status<>'APPROVED' OR NOT coalesce((v_policy->>'generation_enabled')::boolean,false) THEN
        RAISE EXCEPTION 'M1.8 requires one approved, effective, enabled methodology policy profile.';
    END IF;

    IF v_policy->>'methodology_version'<>'M1_8_METHOD_V1_1'
       OR NOT coalesce((v_policy->>'stress_continuity_tier_floor_to_baseline')::boolean,false)
       OR (SELECT count(*) FROM jsonb_object_keys(v_policy))<>31
       OR (v_policy->>'recent_window_days')::integer<1
       OR (v_policy->>'manual_review_fraud_tier')::integer NOT BETWEEN 1 AND 5
       OR (v_policy->>'hard_stop_fraud_tier')::integer NOT BETWEEN 1 AND 5
       OR (v_policy->>'manual_review_continuity_tier')::integer NOT BETWEEN 1 AND 5
       OR (v_policy->>'hard_stop_continuity_tier')::integer NOT BETWEEN 1 AND 5
       OR (v_policy->>'manual_review_fraud_tier')::integer>(v_policy->>'hard_stop_fraud_tier')::integer
       OR (v_policy->>'manual_review_continuity_tier')::integer>(v_policy->>'hard_stop_continuity_tier')::integer
       OR NOT (
           (v_policy->>'continuity_tier_2_degraded_rate')::numeric < (v_policy->>'continuity_tier_3_degraded_rate')::numeric
           AND (v_policy->>'continuity_tier_3_degraded_rate')::numeric < (v_policy->>'continuity_tier_4_degraded_rate')::numeric
           AND (v_policy->>'continuity_tier_2_outage_rate')::numeric < (v_policy->>'continuity_tier_3_outage_rate')::numeric
           AND (v_policy->>'continuity_tier_3_outage_rate')::numeric < (v_policy->>'continuity_tier_4_outage_rate')::numeric
           AND (v_policy->>'continuity_tier_2_connection_gap_rate')::numeric < (v_policy->>'continuity_tier_3_connection_gap_rate')::numeric
           AND (v_policy->>'continuity_tier_3_connection_gap_rate')::numeric < (v_policy->>'continuity_tier_4_connection_gap_rate')::numeric
       )
    THEN
        RAISE EXCEPTION 'M1.8 methodology policy payload is incomplete or non-monotonic.';
    END IF;

    SELECT count(*),count(DISTINCT merchant_application_id),count(DISTINCT source_code)
    INTO v_source_rows,v_source_apps,v_source_families
    FROM msbf_m1.source_snapshot
    WHERE module1_run_id=p_run_id;

    IF v_source_rows<>5250 OR v_source_apps<>750 OR v_source_families<>7 THEN
        RAISE EXCEPTION 'M1.8 requires accepted M1.7 source evidence: rows %, applications %, source families %.',
            v_source_rows,v_source_apps,v_source_families;
    END IF;
END;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_8_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_status text;
    v_verification_rows bigint;
    v_summary_rows bigint;
    v_blocking_errors bigint;
BEGIN
    PERFORM msbf_m1.m1_8_assert_configuration(p_run_id);

    SELECT run_status INTO STRICT v_status
    FROM msbf_ctl.run_registry WHERE run_id=p_run_id FOR UPDATE;

    IF v_status<>'M1_7_ACCEPTED' THEN
        RAISE EXCEPTION 'M1.8 generation requires M1_7_ACCEPTED; observed %.',v_status;
    END IF;

    SELECT count(*) INTO v_verification_rows
    FROM msbf_m1.verification_result WHERE created_by_run_id=p_run_id;
    SELECT count(*) INTO v_summary_rows
    FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=p_run_id;
    SELECT count(*) INTO v_blocking_errors
    FROM msbf_ctl.profile_resolution_error WHERE run_id=p_run_id AND severity='BLOCKING';

    IF v_verification_rows<>0 OR v_summary_rows<>0 THEN
        RAISE EXCEPTION 'M1.8 generation is one-time; existing verification rows %, summary rows %.',
            v_verification_rows,v_summary_rows;
    END IF;
    IF v_blocking_errors<>0 THEN
        RAISE EXCEPTION 'M1.8 generation blocked by % unresolved configuration errors.',v_blocking_errors;
    END IF;
END;
$fn$;

DO $start$
DECLARE v_run_id bigint;
BEGIN
    SELECT run_id INTO STRICT v_run_id
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
    PERFORM msbf_m1.m1_8_assert_generation_ready(v_run_id);
END;
$start$;

DO $notice$ BEGIN RAISE NOTICE 'M1.8 Phase 1/5 — materialize accepted application, source, owner, POS, and continuity inputs'; END $notice$;

CREATE TEMP TABLE _m1_8_ctx ON COMMIT DROP AS
SELECT
    r.run_id,r.as_of_date,r.population_id,
    ((r.as_of_date+time '23:59:59') AT TIME ZONE 'UTC') AS as_of_timestamp,
    pp.policy_profile_id,pp.profile_payload,md5(pp.profile_payload::text) AS policy_hash,
    max((rp.resolved_value->>'value_numeric')::numeric) FILTER (WHERE rp.parameter_name='fraud_base_probability' AND rp.scope_key='GLOBAL') AS fraud_base_probability,
    max((rp.resolved_value->>'value_numeric')::numeric) FILTER (WHERE rp.parameter_name='bank_account_mismatch_fraud_points' AND rp.scope_key='GLOBAL') AS bank_points,
    max((rp.resolved_value->>'value_numeric')::numeric) FILTER (WHERE rp.parameter_name='processor_mismatch_fraud_points' AND rp.scope_key='GLOBAL') AS processor_points,
    max((rp.resolved_value->>'value_numeric')::numeric) FILTER (WHERE rp.parameter_name='identity_conflict_fraud_points' AND rp.scope_key='GLOBAL') AS identity_points,
    max((rp.resolved_value->>'value_numeric')::numeric) FILTER (WHERE rp.parameter_name='abnormal_refund_fraud_points' AND rp.scope_key='GLOBAL') AS refund_points,
    max((rp.resolved_value->>'value_numeric')::numeric) FILTER (WHERE rp.parameter_name='abnormal_chargeback_fraud_points' AND rp.scope_key='GLOBAL') AS chargeback_points,
    max((rp.resolved_value->>'value_numeric')::numeric) FILTER (WHERE rp.parameter_name='fraud_tier_2_threshold' AND rp.scope_key='GLOBAL') AS tier2,
    max((rp.resolved_value->>'value_numeric')::numeric) FILTER (WHERE rp.parameter_name='fraud_tier_3_threshold' AND rp.scope_key='GLOBAL') AS tier3,
    max((rp.resolved_value->>'value_numeric')::numeric) FILTER (WHERE rp.parameter_name='fraud_tier_4_threshold' AND rp.scope_key='GLOBAL') AS tier4,
    max((rp.resolved_value->>'value_numeric')::numeric) FILTER (WHERE rp.parameter_name='fraud_tier_5_threshold' AND rp.scope_key='GLOBAL') AS tier5
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.policy_profile pp
  ON pp.profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY' AND pp.profile_version=1
JOIN msbf_ctl.run_parameter_snapshot rp ON rp.run_id=r.run_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
GROUP BY r.run_id,r.as_of_date,r.population_id,pp.policy_profile_id,pp.profile_payload;

CREATE TEMP TABLE _m1_8_check_policy ON COMMIT DROP AS
SELECT
    c.check_code,c.check_domain,c.hard_stop_eligible_flag,
    bool_or((h.resolved_value->>'value_boolean')::boolean) AS hard_stop_policy,
    bool_or((rv.resolved_value->>'value_boolean')::boolean) AS review_policy
FROM msbf_ref.verification_check_code c
JOIN _m1_8_ctx x ON true
LEFT JOIN msbf_ctl.run_parameter_snapshot h
  ON h.run_id=x.run_id
 AND h.parameter_name='verification_hard_stop_check'
 AND h.scope_key='VERIFICATION_CHECK:'||c.check_code
LEFT JOIN msbf_ctl.run_parameter_snapshot rv
  ON rv.run_id=x.run_id
 AND rv.parameter_name='verification_review_check'
 AND rv.scope_key='VERIFICATION_CHECK:'||c.check_code
WHERE c.active_flag
GROUP BY c.check_code,c.check_domain,c.hard_stop_eligible_flag;
CREATE UNIQUE INDEX ON _m1_8_check_policy(check_code);

CREATE TEMP TABLE _m1_8_source_pivot ON COMMIT DROP AS
SELECT
    s.merchant_application_id,
    max(s.source_snapshot_id) FILTER (WHERE s.source_code='VERIFICATION') AS verification_source_snapshot_id,
    max(s.availability_status) FILTER (WHERE s.source_code='VERIFICATION') AS verification_availability,
    max(s.quality_status) FILTER (WHERE s.source_code='VERIFICATION') AS verification_quality,
    max(s.data_confidence_score) FILTER (WHERE s.source_code='VERIFICATION') AS verification_confidence,
    max(s.source_snapshot_id) FILTER (WHERE s.source_code='POS_DAILY') AS pos_source_snapshot_id,
    max(s.availability_status) FILTER (WHERE s.source_code='POS_DAILY') AS pos_availability,
    max(s.quality_status) FILTER (WHERE s.source_code='POS_DAILY') AS pos_quality,
    max(s.data_confidence_score) FILTER (WHERE s.source_code='POS_DAILY') AS pos_confidence,
    max(s.source_snapshot_id) FILTER (WHERE s.source_code='DEPOSIT_DAILY') AS deposit_source_snapshot_id,
    max(s.availability_status) FILTER (WHERE s.source_code='DEPOSIT_DAILY') AS deposit_availability,
    max(s.quality_status) FILTER (WHERE s.source_code='DEPOSIT_DAILY') AS deposit_quality,
    max(s.data_confidence_score) FILTER (WHERE s.source_code='DEPOSIT_DAILY') AS deposit_confidence
FROM msbf_m1.source_snapshot s
JOIN _m1_8_ctx x ON s.module1_run_id=x.run_id
GROUP BY s.merchant_application_id;
CREATE UNIQUE INDEX ON _m1_8_source_pivot(merchant_application_id);

CREATE TEMP TABLE _m1_8_owner_summary ON COMMIT DROP AS
SELECT
    o.merchant_id,count(*) AS owner_count,
    coalesce(sum(o.ownership_rate),0)::numeric(9,6) AS ownership_total,
    bool_or(o.major_derogatory_flag) AS any_major_derogatory,
    bool_or(o.bankruptcy_flag) AS any_bankruptcy
FROM msbf_m1.merchant_owner_guarantor o
JOIN _m1_8_ctx x ON o.created_by_run_id=x.run_id
GROUP BY o.merchant_id;
CREATE UNIQUE INDEX ON _m1_8_owner_summary(merchant_id);

CREATE TEMP TABLE _m1_8_pos_base_summary ON COMMIT DROP AS
SELECT
    p.merchant_id,
    count(*) AS history_days,
    count(*) FILTER (WHERE p.processor_status='ACTIVE')::numeric/count(*) AS active_day_rate,
    count(*) FILTER (WHERE p.processor_status='DEGRADED')::numeric/count(*) AS degraded_day_rate,
    count(*) FILTER (WHERE p.processor_status='OUTAGE')::numeric/count(*) AS outage_day_rate,
    count(*) FILTER (WHERE p.data_connection_status<>'CONNECTED')::numeric/count(*) AS connection_gap_day_rate,
    count(*) FILTER (
        WHERE p.observation_date>=x.as_of_date-((x.profile_payload->>'recent_window_days')::integer-1)
          AND p.processor_status='OUTAGE'
    )::numeric
      / nullif(count(*) FILTER (
        WHERE p.observation_date>=x.as_of_date-((x.profile_payload->>'recent_window_days')::integer-1)
      ),0) AS recent_outage_day_rate,
    sum(p.gross_pos_sales) AS gross_sales,
    sum(p.refund_amount) AS refund_amount,
    sum(p.chargeback_amount) AS chargeback_amount,
    CASE WHEN sum(p.gross_pos_sales)>0 THEN sum(p.refund_amount)/sum(p.gross_pos_sales) ELSE 0 END AS refund_rate,
    CASE WHEN sum(p.gross_pos_sales)>0 THEN sum(p.chargeback_amount)/sum(p.gross_pos_sales) ELSE 0 END AS chargeback_rate
FROM msbf_m1.merchant_pos_daily_base p
JOIN msbf_m1.processor_account pa ON pa.processor_account_id=p.processor_account_id
JOIN _m1_8_ctx x ON p.generated_by_run_id=x.run_id
WHERE p.observation_date>=pa.processor_account_open_date
GROUP BY p.merchant_id;
CREATE UNIQUE INDEX ON _m1_8_pos_base_summary(merchant_id);

CREATE TEMP TABLE _m1_8_pos_stress_summary ON COMMIT DROP AS
SELECT
    p.merchant_id,
    count(*) FILTER (WHERE p.processor_status='DEGRADED')::numeric/count(*) AS degraded_day_rate,
    count(*) FILTER (WHERE p.processor_status='OUTAGE')::numeric/count(*) AS outage_day_rate,
    count(*) FILTER (WHERE p.data_connection_status<>'CONNECTED')::numeric/count(*) AS connection_gap_day_rate
FROM msbf_m1.merchant_pos_daily_scenario p
JOIN msbf_m1.processor_account pa ON pa.processor_account_id=p.processor_account_id
JOIN msbf_ctl.scenario_registry s ON s.scenario_id=p.scenario_id
JOIN _m1_8_ctx x ON p.generated_by_run_id=x.run_id
WHERE s.scenario_code='RECESSION_ENERGY'
  AND p.observation_date>=pa.processor_account_open_date
GROUP BY p.merchant_id;
CREATE UNIQUE INDEX ON _m1_8_pos_stress_summary(merchant_id);

CREATE TEMP TABLE _m1_8_industry_quality ON COMMIT DROP AS
SELECT i.industry_code,
       avg(b.refund_rate) AS average_refund_rate,
       avg(b.chargeback_rate) AS average_chargeback_rate
FROM _m1_8_pos_base_summary b
JOIN msbf_m1.merchant_industry_assignment i ON i.merchant_id=b.merchant_id AND i.assignment_type='PRIMARY'
GROUP BY i.industry_code;
CREATE UNIQUE INDEX ON _m1_8_industry_quality(industry_code);

CREATE TEMP TABLE _m1_8_application_input ON COMMIT DROP AS
SELECT
    a.merchant_application_id,a.merchant_id,a.processor_account_id,a.partner_channel_id,
    a.as_of_date,x.as_of_timestamp,m.legal_entity_type,m.merchant_size_tier,
    i.industry_code,coalesce(rel.relationship_stage,'NEW') AS relationship_stage,
    coalesce(rel.deposit_relationship_flag,false) AS deposit_relationship_flag,
    pa.processor_account_open_date,pa.processor_risk_tier,pa.split_funding_capable_flag,
    coalesce(pc.partner_risk_tier,3) AS partner_risk_tier,
    coalesce(os.owner_count,1) AS owner_count,coalesce(os.ownership_total,1)::numeric(9,6) AS ownership_total,
    coalesce(os.any_major_derogatory,false) AS any_major_derogatory,
    coalesce(os.any_bankruptcy,false) AS any_bankruptcy,
    sp.verification_source_snapshot_id,sp.verification_availability,sp.verification_quality,sp.verification_confidence,
    sp.pos_source_snapshot_id,sp.pos_availability,sp.pos_quality,sp.pos_confidence,
    sp.deposit_source_snapshot_id,sp.deposit_availability,sp.deposit_quality,sp.deposit_confidence,
    b.history_days,
    round(b.active_day_rate,6) AS active_day_rate,
    round(b.degraded_day_rate,6) AS degraded_day_rate,
    round(b.outage_day_rate,6) AS outage_day_rate,
    round(coalesce(b.recent_outage_day_rate,0),6) AS recent_outage_day_rate,
    round(b.connection_gap_day_rate,6) AS connection_gap_day_rate,
    round(st.degraded_day_rate,6) AS stress_degraded_day_rate,
    round(st.outage_day_rate,6) AS stress_outage_day_rate,
    round(st.connection_gap_day_rate,6) AS stress_connection_gap_day_rate,
    round(b.refund_rate,8) AS refund_rate,round(b.chargeback_rate,8) AS chargeback_rate,
    round(q.average_refund_rate,8) AS industry_refund_rate,
    round(q.average_chargeback_rate,8) AS industry_chargeback_rate,
    x.run_id,x.profile_payload,x.fraud_base_probability,x.bank_points,x.processor_points,
    x.identity_points,x.refund_points,x.chargeback_points,x.tier2,x.tier3,x.tier4,x.tier5
FROM msbf_m1.merchant_application a
JOIN _m1_8_ctx x ON a.created_by_run_id=x.run_id
JOIN msbf_m1.merchant_master m ON m.merchant_id=a.merchant_id
JOIN msbf_m1.processor_account pa ON pa.processor_account_id=a.processor_account_id
LEFT JOIN msbf_m1.partner_channel pc ON pc.partner_channel_id=a.partner_channel_id
JOIN msbf_m1.merchant_industry_assignment i ON i.merchant_id=a.merchant_id AND i.assignment_type='PRIMARY'
LEFT JOIN msbf_m1.merchant_relationship_snapshot rel ON rel.merchant_id=a.merchant_id AND rel.as_of_date=a.as_of_date
LEFT JOIN _m1_8_owner_summary os ON os.merchant_id=a.merchant_id
JOIN _m1_8_source_pivot sp ON sp.merchant_application_id=a.merchant_application_id
JOIN _m1_8_pos_base_summary b ON b.merchant_id=a.merchant_id
JOIN _m1_8_pos_stress_summary st ON st.merchant_id=a.merchant_id
JOIN _m1_8_industry_quality q ON q.industry_code=i.industry_code;
CREATE UNIQUE INDEX ON _m1_8_application_input(merchant_application_id);
ANALYZE _m1_8_application_input;

DO $notice$ BEGIN RAISE NOTICE 'M1.8 Phase 2/5 — generate five atomic verification checks and the independent fraud screen'; END $notice$;

CREATE TEMP TABLE _m1_8_atomic_seed ON COMMIT DROP AS
SELECT
    a.*,c.check_code,c.hard_stop_eligible_flag,c.hard_stop_policy,c.review_policy,
    CASE c.check_code
      WHEN 'BANK_ACCOUNT_MATCH' THEN a.deposit_source_snapshot_id
      WHEN 'PROCESSOR_MATCH' THEN a.pos_source_snapshot_id
      ELSE a.verification_source_snapshot_id END AS source_snapshot_id,
    CASE c.check_code
      WHEN 'BANK_ACCOUNT_MATCH' THEN a.deposit_availability
      WHEN 'PROCESSOR_MATCH' THEN a.pos_availability
      ELSE a.verification_availability END AS source_availability,
    CASE c.check_code
      WHEN 'BANK_ACCOUNT_MATCH' THEN a.deposit_quality
      WHEN 'PROCESSOR_MATCH' THEN a.pos_quality
      ELSE a.verification_quality END AS source_quality,
    CASE c.check_code
      WHEN 'BANK_ACCOUNT_MATCH' THEN a.deposit_confidence
      WHEN 'PROCESSOR_MATCH' THEN a.pos_confidence
      ELSE a.verification_confidence END AS source_confidence,
    msbf_ctl.deterministic_uniform(a.merchant_application_id||'|'||c.check_code,'M1_8_CHECK_V1') AS signal_draw,
    least(0.15,a.fraud_base_probability * CASE c.check_code
        WHEN 'KYB_ENTITY' THEN (a.profile_payload->>'kyb_fail_multiplier')::numeric
            * (1 + CASE WHEN a.as_of_date-a.processor_account_open_date<365 THEN 0.15 ELSE 0 END)
        WHEN 'BENEFICIAL_OWNER' THEN (a.profile_payload->>'beneficial_owner_fail_multiplier')::numeric
            * (1 + greatest(a.owner_count-1,0)*0.10)
        WHEN 'SANCTIONS' THEN (a.profile_payload->>'sanctions_fail_multiplier')::numeric
        WHEN 'BANK_ACCOUNT_MATCH' THEN (a.profile_payload->>'bank_account_mismatch_multiplier')::numeric
            * (1 + CASE WHEN NOT a.deposit_relationship_flag THEN 0.10 ELSE 0 END)
        WHEN 'PROCESSOR_MATCH' THEN (a.profile_payload->>'processor_mismatch_multiplier')::numeric
            * (1 + greatest(a.processor_risk_tier-1,0)*0.08)
        ELSE 0 END
    ) AS fail_probability
FROM _m1_8_application_input a
JOIN _m1_8_check_policy c ON c.check_code<>'FRAUD_SCREEN';

CREATE TEMP TABLE _m1_8_atomic_blueprint ON COMMIT DROP AS
WITH classified AS (
    SELECT s.*,
           least(0.30,s.fail_probability + s.fraud_base_probability*(s.profile_payload->>'review_band_multiplier')::numeric) AS review_probability,
           CASE
             WHEN s.source_availability='UNAVAILABLE' THEN 'UNAVAILABLE'
             WHEN s.source_availability='PARTIAL' OR s.source_quality IN ('WARNING','FAIL','CONFLICT') THEN 'REVIEW'
             WHEN s.signal_draw<s.fail_probability THEN 'FAIL'
             WHEN s.signal_draw<least(0.30,s.fail_probability+s.fraud_base_probability*(s.profile_payload->>'review_band_multiplier')::numeric) THEN 'REVIEW'
             ELSE 'PASS' END AS result_status
    FROM _m1_8_atomic_seed s
), prepared AS (
    SELECT c.*,
           CASE c.result_status WHEN 'PASS' THEN 1 WHEN 'REVIEW' THEN 3 WHEN 'FAIL' THEN 5 ELSE NULL END::smallint AS risk_tier,
           (c.result_status IN ('FAIL','UNAVAILABLE') AND c.hard_stop_policy)::boolean AS hard_stop_recommended_flag,
           (
             c.result_status='REVIEW'
             OR (c.result_status='UNAVAILABLE' AND NOT c.hard_stop_policy)
           )::boolean AS manual_review_recommended_flag,
           CASE
             WHEN c.result_status='UNAVAILABLE' THEN 'SOURCE_UNAVAILABLE'
             WHEN c.source_availability='PARTIAL' THEN 'PARTIAL_SOURCE_EVIDENCE'
             WHEN c.source_quality='CONFLICT' THEN 'SOURCE_CONFLICT_REVIEW'
             WHEN c.source_quality IN ('WARNING','FAIL') THEN 'SOURCE_QUALITY_REVIEW'
             WHEN c.result_status='FAIL' THEN c.check_code||'_FAIL'
             WHEN c.result_status='REVIEW' THEN c.check_code||'_REVIEW'
             ELSE c.check_code||'_PASS' END AS result_reason_code,
           jsonb_build_object(
             'source_availability_status',c.source_availability,
             'source_quality_status',c.source_quality,
             'source_confidence',round(c.source_confidence,6),
             'signal_draw',round(c.signal_draw,8),
             'fail_probability',round(c.fail_probability,8),
             'review_probability',round(c.review_probability,8),
             'legal_entity_type',c.legal_entity_type,
             'owner_count',c.owner_count,
             'ownership_total',c.ownership_total,
             'processor_risk_tier',c.processor_risk_tier,
             'partner_risk_tier',c.partner_risk_tier,
             'deposit_relationship_flag',c.deposit_relationship_flag
           ) AS evidence_payload
    FROM classified c
)
SELECT
    p.merchant_application_id,p.check_code,1 AS check_version,p.as_of_timestamp,
    p.result_status,p.risk_tier,p.hard_stop_recommended_flag,
    p.manual_review_recommended_flag,p.result_reason_code,p.evidence_payload,
    p.source_snapshot_id,p.run_id AS created_by_run_id,
    msbf_m1.m1_8_verification_row_hash(
        p.merchant_application_id,p.check_code,1,p.as_of_timestamp,p.result_status,p.risk_tier,
        p.hard_stop_recommended_flag,p.manual_review_recommended_flag,p.result_reason_code,
        p.evidence_payload,p.source_snapshot_id,p.run_id
    ) AS row_hash
FROM prepared p;
CREATE UNIQUE INDEX ON _m1_8_atomic_blueprint(merchant_application_id,check_code);

CREATE TEMP TABLE _m1_8_atomic_status_pivot ON COMMIT DROP AS
SELECT
    merchant_application_id,
    max(result_status) FILTER (WHERE check_code='KYB_ENTITY') AS kyb_status,
    max(result_status) FILTER (WHERE check_code='BENEFICIAL_OWNER') AS owner_status,
    max(result_status) FILTER (WHERE check_code='SANCTIONS') AS sanctions_status,
    max(result_status) FILTER (WHERE check_code='BANK_ACCOUNT_MATCH') AS bank_status,
    max(result_status) FILTER (WHERE check_code='PROCESSOR_MATCH') AS processor_status_result
FROM _m1_8_atomic_blueprint
GROUP BY merchant_application_id;
CREATE UNIQUE INDEX ON _m1_8_atomic_status_pivot(merchant_application_id);

CREATE TEMP TABLE _m1_8_fraud_blueprint ON COMMIT DROP AS
WITH flags AS (
    SELECT a.*,p.kyb_status,p.owner_status,p.sanctions_status,p.bank_status,p.processor_status_result,
           (p.bank_status='FAIL') AS bank_mismatch_flag,
           (p.processor_status_result='FAIL') AS processor_mismatch_flag,
           (
             p.kyb_status='FAIL' OR p.owner_status='FAIL'
             OR msbf_ctl.deterministic_uniform(a.merchant_application_id,'M1_8_IDENTITY_CONFLICT_V1')
                < a.fraud_base_probability*(a.profile_payload->>'identity_conflict_multiplier')::numeric
           ) AS identity_conflict_flag,
           (a.refund_rate>=greatest(
                a.industry_refund_rate*(a.profile_payload->>'refund_rate_multiplier_threshold')::numeric,
                (a.profile_payload->>'refund_rate_absolute_floor')::numeric
           )) AS abnormal_refund_flag,
           (a.chargeback_rate>=greatest(
                a.industry_chargeback_rate*(a.profile_payload->>'chargeback_rate_multiplier_threshold')::numeric,
                (a.profile_payload->>'chargeback_rate_absolute_floor')::numeric
           )) AS abnormal_chargeback_flag
    FROM _m1_8_application_input a
    JOIN _m1_8_atomic_status_pivot p USING(merchant_application_id)
), scored AS (
    SELECT f.*,
           least(100::numeric,
               f.fraud_base_probability*100
               + CASE WHEN f.bank_mismatch_flag THEN f.bank_points ELSE 0 END
               + CASE WHEN f.processor_mismatch_flag THEN f.processor_points ELSE 0 END
               + CASE WHEN f.identity_conflict_flag THEN f.identity_points ELSE 0 END
               + CASE WHEN f.abnormal_refund_flag THEN f.refund_points ELSE 0 END
               + CASE WHEN f.abnormal_chargeback_flag THEN f.chargeback_points ELSE 0 END
           )::numeric(9,6) AS fraud_score
    FROM flags f
), tiered AS (
    SELECT s.*,
           CASE
             WHEN s.fraud_score>=s.tier5 THEN 5
             WHEN s.fraud_score>=s.tier4 THEN 4
             WHEN s.fraud_score>=s.tier3 THEN 3
             WHEN s.fraud_score>=s.tier2 THEN 2
             ELSE 1 END::smallint AS fraud_tier
    FROM scored s
), prepared AS (
    SELECT t.*,
           CASE
             WHEN t.verification_availability='UNAVAILABLE' THEN 'REVIEW'
             WHEN t.fraud_tier>=5 THEN 'FAIL'
             WHEN t.fraud_tier>=3 OR t.verification_quality<>'PASS' THEN 'REVIEW'
             ELSE 'PASS' END AS result_status,
           CASE
             WHEN t.verification_availability='UNAVAILABLE' THEN 'PARTIAL_FRAUD_EVIDENCE'
             WHEN t.fraud_tier>=5 THEN 'FRAUD_TIER_5_FAIL'
             WHEN t.fraud_tier>=3 THEN 'ELEVATED_FRAUD_REVIEW'
             WHEN t.verification_quality<>'PASS' THEN 'SOURCE_QUALITY_REVIEW'
             ELSE 'FRAUD_SCREEN_PASS' END AS result_reason_code,
           jsonb_build_object(
             'fraud_score',t.fraud_score,
             'fraud_tier',t.fraud_tier,
             'fraud_reason_flags',jsonb_build_object(
                'bank_account_mismatch',t.bank_mismatch_flag,
                'processor_mismatch',t.processor_mismatch_flag,
                'identity_conflict',t.identity_conflict_flag,
                'abnormal_refund_rate',t.abnormal_refund_flag,
                'abnormal_chargeback_rate',t.abnormal_chargeback_flag
             ),
             'point_contributions',jsonb_build_object(
                'base',t.fraud_base_probability*100,
                'bank_account_mismatch',CASE WHEN t.bank_mismatch_flag THEN t.bank_points ELSE 0 END,
                'processor_mismatch',CASE WHEN t.processor_mismatch_flag THEN t.processor_points ELSE 0 END,
                'identity_conflict',CASE WHEN t.identity_conflict_flag THEN t.identity_points ELSE 0 END,
                'abnormal_refund_rate',CASE WHEN t.abnormal_refund_flag THEN t.refund_points ELSE 0 END,
                'abnormal_chargeback_rate',CASE WHEN t.abnormal_chargeback_flag THEN t.chargeback_points ELSE 0 END
             ),
             'refund_rate',t.refund_rate,
             'industry_refund_rate',t.industry_refund_rate,
             'chargeback_rate',t.chargeback_rate,
             'industry_chargeback_rate',t.industry_chargeback_rate,
             'verification_source_availability',t.verification_availability,
             'verification_source_quality',t.verification_quality,
             'verification_source_confidence',t.verification_confidence
           ) AS evidence_payload
    FROM tiered t
)
SELECT
    p.merchant_application_id,'FRAUD_SCREEN'::text AS check_code,1 AS check_version,p.as_of_timestamp,
    p.result_status,p.fraud_tier AS risk_tier,false AS hard_stop_recommended_flag,
    (p.result_status='REVIEW') AS manual_review_recommended_flag,
    p.result_reason_code,p.evidence_payload,p.verification_source_snapshot_id AS source_snapshot_id,
    p.run_id AS created_by_run_id,
    msbf_m1.m1_8_verification_row_hash(
        p.merchant_application_id,'FRAUD_SCREEN',1,p.as_of_timestamp,p.result_status,p.fraud_tier,
        false,(p.result_status='REVIEW'),p.result_reason_code,p.evidence_payload,
        p.verification_source_snapshot_id,p.run_id
    ) AS row_hash
FROM prepared p;
CREATE UNIQUE INDEX ON _m1_8_fraud_blueprint(merchant_application_id,check_code);

CREATE TEMP TABLE _m1_8_verification_blueprint ON COMMIT DROP AS
SELECT * FROM _m1_8_atomic_blueprint
UNION ALL
SELECT * FROM _m1_8_fraud_blueprint;
CREATE UNIQUE INDEX ON _m1_8_verification_blueprint(merchant_application_id,check_code);
ANALYZE _m1_8_verification_blueprint;

INSERT INTO msbf_m1.verification_result(
    merchant_application_id,check_code,check_version,as_of_timestamp,result_status,risk_tier,
    hard_stop_recommended_flag,manual_review_recommended_flag,result_reason_code,
    evidence_payload,source_snapshot_id,created_by_run_id,row_hash
)
SELECT
    merchant_application_id,check_code,check_version,as_of_timestamp,result_status,risk_tier,
    hard_stop_recommended_flag,manual_review_recommended_flag,result_reason_code,
    evidence_payload,source_snapshot_id,created_by_run_id,row_hash
FROM _m1_8_verification_blueprint;
ANALYZE msbf_m1.verification_result;

DO $notice$ BEGIN RAISE NOTICE 'M1.8 Phase 3/5 — aggregate independent fraud and processor-continuity dispositions'; END $notice$;

CREATE TEMP TABLE _m1_8_summary_blueprint ON COMMIT DROP AS
WITH check_summary AS (
    SELECT
        v.merchant_application_id,
        count(*) FILTER (WHERE v.result_status='PASS')::smallint AS pass_count,
        count(*) FILTER (WHERE v.result_status='REVIEW')::smallint AS review_count,
        count(*) FILTER (WHERE v.result_status='FAIL')::smallint AS fail_count,
        count(*) FILTER (WHERE v.result_status='UNAVAILABLE')::smallint AS unavailable_count,
        count(*) FILTER (WHERE v.hard_stop_recommended_flag)::smallint AS critical_fail_count,
        count(*) FILTER (WHERE v.result_status='UNAVAILABLE' AND v.hard_stop_recommended_flag) AS unavailable_hard_stop_count,
        count(*) FILTER (WHERE v.result_status='FAIL' AND v.hard_stop_recommended_flag) AS failed_hard_stop_count,
        max(v.risk_tier) FILTER (WHERE v.check_code='FRAUD_SCREEN')::smallint AS fraud_tier,
        max((v.evidence_payload->>'fraud_score')::numeric) FILTER (WHERE v.check_code='FRAUD_SCREEN')::numeric(9,6) AS fraud_score,
        (jsonb_agg(v.evidence_payload->'fraud_reason_flags') FILTER (WHERE v.check_code='FRAUD_SCREEN'))->0 AS fraud_reason_flags,
        max(v.result_status) FILTER (WHERE v.check_code='SANCTIONS') AS sanctions_status,
        max(v.result_status) FILTER (WHERE v.check_code='KYB_ENTITY') AS kyb_status,
        max(v.result_status) FILTER (WHERE v.check_code='BENEFICIAL_OWNER') AS owner_status,
        max(v.result_status) FILTER (WHERE v.check_code='BANK_ACCOUNT_MATCH') AS bank_status,
        max(v.result_status) FILTER (WHERE v.check_code='PROCESSOR_MATCH') AS processor_match_status
    FROM msbf_m1.verification_result v
    JOIN _m1_8_ctx x ON v.created_by_run_id=x.run_id
    GROUP BY v.merchant_application_id
), continuity_raw AS (
    SELECT a.*,
           CASE
             WHEN a.pos_availability='UNAVAILABLE' THEN 5
             WHEN a.outage_day_rate<=(a.profile_payload->>'continuity_tier_2_outage_rate')::numeric
              AND a.degraded_day_rate<=(a.profile_payload->>'continuity_tier_2_degraded_rate')::numeric
              AND a.connection_gap_day_rate<=(a.profile_payload->>'continuity_tier_2_connection_gap_rate')::numeric
              AND a.recent_outage_day_rate<=(a.profile_payload->>'continuity_tier_2_recent_outage_rate')::numeric THEN 1
             WHEN a.outage_day_rate<=(a.profile_payload->>'continuity_tier_3_outage_rate')::numeric
              AND a.degraded_day_rate<=(a.profile_payload->>'continuity_tier_3_degraded_rate')::numeric
              AND a.connection_gap_day_rate<=(a.profile_payload->>'continuity_tier_3_connection_gap_rate')::numeric
              AND a.recent_outage_day_rate<=(a.profile_payload->>'continuity_tier_3_recent_outage_rate')::numeric THEN 2
             WHEN a.outage_day_rate<=(a.profile_payload->>'continuity_tier_4_outage_rate')::numeric
              AND a.degraded_day_rate<=(a.profile_payload->>'continuity_tier_4_degraded_rate')::numeric
              AND a.connection_gap_day_rate<=(a.profile_payload->>'continuity_tier_4_connection_gap_rate')::numeric
              AND a.recent_outage_day_rate<=(a.profile_payload->>'continuity_tier_4_recent_outage_rate')::numeric THEN 3
             ELSE 4 END::smallint AS baseline_continuity_tier,
           CASE
             WHEN a.pos_availability='UNAVAILABLE' THEN 5
             WHEN a.stress_outage_day_rate<=(a.profile_payload->>'continuity_tier_2_outage_rate')::numeric
              AND a.stress_degraded_day_rate<=(a.profile_payload->>'continuity_tier_2_degraded_rate')::numeric
              AND a.stress_connection_gap_day_rate<=(a.profile_payload->>'continuity_tier_2_connection_gap_rate')::numeric THEN 1
             WHEN a.stress_outage_day_rate<=(a.profile_payload->>'continuity_tier_3_outage_rate')::numeric
              AND a.stress_degraded_day_rate<=(a.profile_payload->>'continuity_tier_3_degraded_rate')::numeric
              AND a.stress_connection_gap_day_rate<=(a.profile_payload->>'continuity_tier_3_connection_gap_rate')::numeric THEN 2
             WHEN a.stress_outage_day_rate<=(a.profile_payload->>'continuity_tier_4_outage_rate')::numeric
              AND a.stress_degraded_day_rate<=(a.profile_payload->>'continuity_tier_4_degraded_rate')::numeric
              AND a.stress_connection_gap_day_rate<=(a.profile_payload->>'continuity_tier_4_connection_gap_rate')::numeric THEN 3
             ELSE 4 END::smallint AS raw_stress_continuity_tier
    FROM _m1_8_application_input a
), continuity AS (
    SELECT c.*,
           greatest(c.baseline_continuity_tier,c.raw_stress_continuity_tier)::smallint
             AS stress_continuity_tier
    FROM continuity_raw c
), prepared AS (
    SELECT
        c.*,
        s.pass_count,s.review_count,s.fail_count,s.unavailable_count,s.critical_fail_count,
        s.unavailable_hard_stop_count,s.failed_hard_stop_count,s.fraud_tier,s.fraud_score,
        s.fraud_reason_flags,s.sanctions_status,s.kyb_status,s.owner_status,s.bank_status,s.processor_match_status,
        CASE c.baseline_continuity_tier WHEN 1 THEN 'STABLE' WHEN 2 THEN 'MONITORED' WHEN 3 THEN 'WATCH' WHEN 4 THEN 'DISRUPTED' ELSE 'UNAVAILABLE' END AS baseline_continuity_status,
        CASE c.stress_continuity_tier WHEN 1 THEN 'STABLE' WHEN 2 THEN 'MONITORED' WHEN 3 THEN 'WATCH' WHEN 4 THEN 'DISRUPTED' ELSE 'UNAVAILABLE' END AS stress_continuity_status,
        (c.stress_continuity_tier>c.baseline_continuity_tier) AS stress_worsening,
        (
            s.unavailable_hard_stop_count>0
            OR s.failed_hard_stop_count>0
            OR s.fraud_tier>=(c.profile_payload->>'hard_stop_fraud_tier')::integer
            OR c.baseline_continuity_tier>=(c.profile_payload->>'hard_stop_continuity_tier')::integer
        ) AS hard_stop_flag,
        (
            s.review_count>0 OR s.fail_count>0 OR s.unavailable_count>0
            OR s.fraud_tier>=(c.profile_payload->>'manual_review_fraud_tier')::integer
            OR c.baseline_continuity_tier>=(c.profile_payload->>'manual_review_continuity_tier')::integer
            OR c.stress_continuity_tier>=4
        ) AS review_flag
    FROM continuity c
    JOIN check_summary s ON s.merchant_application_id=c.merchant_application_id
), routed AS (
    SELECT p.*,
           CASE
             WHEN p.unavailable_hard_stop_count>0 THEN 'INSUFFICIENT_EVIDENCE'
             WHEN p.hard_stop_flag THEN 'STOP'
             WHEN p.review_flag THEN 'REVIEW'
             ELSE 'CLEAR' END AS disposition,
           CASE
             WHEN p.unavailable_hard_stop_count>0 THEN 'CRITICAL_SOURCE_UNAVAILABLE'
             WHEN p.sanctions_status='FAIL' THEN 'SANCTIONS_HIT'
             WHEN p.kyb_status='FAIL' THEN 'KYB_FAILURE'
             WHEN p.owner_status='FAIL' THEN 'BENEFICIAL_OWNER_FAILURE'
             WHEN p.bank_status='FAIL' THEN 'BANK_ACCOUNT_MISMATCH'
             WHEN p.processor_match_status='FAIL' THEN 'PROCESSOR_ACCOUNT_MISMATCH'
             WHEN p.fraud_tier>=(p.profile_payload->>'hard_stop_fraud_tier')::integer THEN 'FRAUD_TIER_5'
             WHEN p.fraud_tier>=(p.profile_payload->>'manual_review_fraud_tier')::integer THEN 'FRAUD_REVIEW'
             WHEN p.baseline_continuity_tier>=(p.profile_payload->>'manual_review_continuity_tier')::integer
               OR p.stress_continuity_tier>=4 THEN 'PROCESSOR_CONTINUITY_REVIEW'
             WHEN p.review_count>0 OR p.fail_count>0 OR p.unavailable_count>0 THEN 'VERIFICATION_REVIEW'
             ELSE 'CLEAR' END AS primary_reason,
           array_remove(ARRAY[
             CASE WHEN p.sanctions_status='FAIL' THEN 'SANCTIONS_HIT' END,
             CASE WHEN p.kyb_status='FAIL' THEN 'KYB_FAILURE' END,
             CASE WHEN p.owner_status='FAIL' THEN 'BENEFICIAL_OWNER_FAILURE' END,
             CASE WHEN p.bank_status='FAIL' THEN 'BANK_ACCOUNT_MISMATCH' END,
             CASE WHEN p.processor_match_status='FAIL' THEN 'PROCESSOR_ACCOUNT_MISMATCH' END,
             CASE WHEN p.fraud_tier>=3 THEN 'ELEVATED_FRAUD_TIER' END,
             CASE WHEN p.baseline_continuity_tier>=3 THEN 'BASELINE_CONTINUITY_WATCH' END,
             CASE WHEN p.stress_continuity_tier>p.baseline_continuity_tier THEN 'STRESS_CONTINUITY_DETERIORATION' END,
             CASE WHEN p.unavailable_count>0 THEN 'UNAVAILABLE_VERIFICATION_EVIDENCE' END,
             CASE WHEN p.review_count>0 THEN 'CHECK_LEVEL_REVIEW' END
           ]::text[],NULL) AS secondary_reasons
    FROM prepared p
)
SELECT
    r.run_id AS module1_run_id,r.merchant_application_id,r.as_of_timestamp,
    r.verification_source_snapshot_id,r.pos_source_snapshot_id,r.deposit_source_snapshot_id,
    r.pass_count,r.review_count,r.fail_count,r.unavailable_count,r.critical_fail_count,
    r.fraud_score,r.fraud_tier,
    r.baseline_continuity_status,r.baseline_continuity_tier,
    r.stress_continuity_status,r.stress_continuity_tier,
    r.active_day_rate,r.degraded_day_rate,r.outage_day_rate,r.recent_outage_day_rate,
    r.connection_gap_day_rate,r.stress_degraded_day_rate,r.stress_outage_day_rate,
    r.stress_connection_gap_day_rate,r.stress_worsening,
    (r.disposition IN ('STOP','INSUFFICIENT_EVIDENCE')) AS hard_stop_recommended_flag,
    (r.disposition='REVIEW') AS manual_review_recommended_flag,
    r.disposition,r.primary_reason,r.secondary_reasons,
    coalesce(r.fraud_reason_flags,'{}'::jsonb) AS fraud_reason_flags,
    msbf_m1.m1_8_summary_row_hash(
        r.run_id,r.merchant_application_id,r.as_of_timestamp,
        r.verification_source_snapshot_id,r.pos_source_snapshot_id,r.deposit_source_snapshot_id,
        r.pass_count,r.review_count,r.fail_count,r.unavailable_count,r.critical_fail_count,
        r.fraud_score,r.fraud_tier,r.baseline_continuity_status,r.baseline_continuity_tier,
        r.stress_continuity_status,r.stress_continuity_tier,
        r.active_day_rate,r.degraded_day_rate,r.outage_day_rate,r.recent_outage_day_rate,
        r.connection_gap_day_rate,r.stress_degraded_day_rate,r.stress_outage_day_rate,
        r.stress_connection_gap_day_rate,r.stress_worsening,
        (r.disposition IN ('STOP','INSUFFICIENT_EVIDENCE')),(r.disposition='REVIEW'),
        r.disposition,r.primary_reason,r.secondary_reasons,coalesce(r.fraud_reason_flags,'{}'::jsonb),r.run_id
    ) AS row_hash,
    r.run_id AS created_by_run_id
FROM routed r;
CREATE UNIQUE INDEX ON _m1_8_summary_blueprint(merchant_application_id);

INSERT INTO msbf_m1.application_verification_fraud_snapshot(
    module1_run_id,merchant_application_id,as_of_timestamp,
    verification_source_snapshot_id,pos_source_snapshot_id,deposit_source_snapshot_id,
    verification_pass_count,verification_review_count,verification_fail_count,
    verification_unavailable_count,critical_fail_count,fraud_score,fraud_risk_tier,
    processor_continuity_status,processor_continuity_risk_tier,
    stress_processor_continuity_status,stress_processor_continuity_risk_tier,
    processor_active_day_rate,processor_degraded_day_rate,processor_outage_day_rate,
    recent_processor_outage_day_rate,data_connection_gap_day_rate,
    stress_processor_degraded_day_rate,stress_processor_outage_day_rate,
    stress_data_connection_gap_day_rate,continuity_stress_worsening_flag,
    hard_stop_recommended_flag,manual_review_recommended_flag,verification_disposition,
    primary_reason_code,secondary_reason_codes,fraud_reason_flags,row_hash,created_by_run_id
)
SELECT
    module1_run_id,merchant_application_id,as_of_timestamp,
    verification_source_snapshot_id,pos_source_snapshot_id,deposit_source_snapshot_id,
    pass_count,review_count,fail_count,unavailable_count,critical_fail_count,fraud_score,fraud_tier,
    baseline_continuity_status,baseline_continuity_tier,stress_continuity_status,stress_continuity_tier,
    active_day_rate,degraded_day_rate,outage_day_rate,recent_outage_day_rate,connection_gap_day_rate,
    stress_degraded_day_rate,stress_outage_day_rate,stress_connection_gap_day_rate,stress_worsening,
    hard_stop_recommended_flag,manual_review_recommended_flag,disposition,primary_reason,
    secondary_reasons,fraud_reason_flags,row_hash,created_by_run_id
FROM _m1_8_summary_blueprint;
ANALYZE msbf_m1.application_verification_fraud_snapshot;

DO $notice$ BEGIN RAISE NOTICE 'M1.8 Phase 4/5 — materialize canonical snapshots and reconcile persisted evidence'; END $notice$;

CREATE TEMP TABLE _m1_8_expected_entities ON COMMIT DROP AS
SELECT 'VERIFICATION|'||merchant_application_id||'|'||check_code AS entity_key,row_hash
FROM _m1_8_verification_blueprint
UNION ALL
SELECT 'SUMMARY|'||merchant_application_id,row_hash
FROM _m1_8_summary_blueprint;
CREATE UNIQUE INDEX ON _m1_8_expected_entities(entity_key);

CREATE TEMP TABLE _m1_8_actual_entities ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_8_actual_entity_snapshot((SELECT run_id FROM _m1_8_ctx));
CREATE UNIQUE INDEX ON _m1_8_actual_entities(entity_key);
ANALYZE _m1_8_expected_entities;
ANALYZE _m1_8_actual_entities;

DO $reconcile$
DECLARE
    v_run_id bigint;
    v_expected bigint;v_actual bigint;v_mismatch bigint;
    v_verification_hash text;v_summary_hash text;v_combined_hash text;
    v_verification_rows bigint;v_summary_rows bigint;
    v_policy_hash text;
BEGIN
    SELECT run_id,policy_hash INTO STRICT v_run_id,v_policy_hash FROM _m1_8_ctx;
    SELECT count(*) INTO v_expected FROM _m1_8_expected_entities;
    SELECT count(*) INTO v_actual FROM _m1_8_actual_entities;
    SELECT count(*) INTO v_mismatch
    FROM _m1_8_expected_entities e
    FULL JOIN _m1_8_actual_entities a USING(entity_key)
    WHERE e.row_hash IS DISTINCT FROM a.row_hash;

    SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
      INTO v_verification_hash
      FROM _m1_8_actual_entities WHERE entity_key LIKE 'VERIFICATION|%';
    SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
      INTO v_summary_hash
      FROM _m1_8_actual_entities WHERE entity_key LIKE 'SUMMARY|%';
    SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
      INTO v_combined_hash
      FROM _m1_8_actual_entities;

    SELECT count(*) INTO v_verification_rows
    FROM msbf_m1.verification_result WHERE created_by_run_id=v_run_id;
    SELECT count(*) INTO v_summary_rows
    FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=v_run_id;

    IF v_expected<>5250 OR v_actual<>5250 OR v_mismatch<>0
       OR v_verification_rows<>4500 OR v_summary_rows<>750 THEN
        RAISE EXCEPTION 'M1.8 canonical reconciliation failed: expected %, actual %, mismatches %, verification %, summary %.',
            v_expected,v_actual,v_mismatch,v_verification_rows,v_summary_rows;
    END IF;

    INSERT INTO msbf_ctl.run_evidence(
        run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation
    ) VALUES
      (v_run_id,'M1_8_POLICY_PROFILE_HASH','PORTFOLIO','M1.8 policy profile hash',v_policy_hash,'HASH','PASS','Approved effective M1.8 methodology profile.'),
      (v_run_id,'M1_8_VERIFICATION_SET_HASH','PORTFOLIO','M1.8 verification set hash',v_verification_hash,'HASH','PASS','Canonical hash across 4,500 verification-result entities.'),
      (v_run_id,'M1_8_SUMMARY_SET_HASH','PORTFOLIO','M1.8 summary set hash',v_summary_hash,'HASH','PASS','Canonical hash across 750 verification/fraud/continuity summaries.'),
      (v_run_id,'M1_8_COMBINED_SET_HASH','PORTFOLIO','M1.8 combined set hash',v_combined_hash,'HASH','PASS','Canonical hash across 5,250 M1.8 entities.'),
      (v_run_id,'M1_8_GENERATION_SPEC','PORTFOLIO','M1.8 generation specification','M1_8_METHOD_V1_1|750 applications|6 checks|baseline+stress continuity|stress tier floor to baseline|independent fraud tier','TEXT','PASS','Governed synthetic M1.8 generation specification.'),
      (v_run_id,'M1_8_GENERATION_SUMMARY','PORTFOLIO','M1.8 generation summary',
       format('verification=%s summary=%s expected=%s actual=%s mismatches=%s',v_verification_rows,v_summary_rows,v_expected,v_actual,v_mismatch),
       'TEXT','PASS','Committed M1.8 generation and deterministic reconciliation.')
    ON CONFLICT(run_id,evidence_code,segment_key)
    DO UPDATE SET metric_value_numeric=NULL,metric_value_text=EXCLUDED.metric_value_text,
                  unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
                  threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,
                  created_at=clock_timestamp();

    UPDATE msbf_ctl.run_registry
       SET run_status='M1_8_GENERATED',started_at=coalesce(started_at,clock_timestamp()),
           completed_at=NULL,row_count=5250,
           notes=coalesce(notes,'')||E'
M1.8 verification, fraud and processor-continuity evidence generated.'
     WHERE run_id=v_run_id;
END;
$reconcile$;

COMMIT;

DO $notice$ BEGIN RAISE NOTICE 'M1.8 Phase 5/5 — committed generation checkpoint'; END $notice$;

WITH r AS (
    SELECT run_id,run_status FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), hashes AS (
    SELECT
      max(metric_value_text) FILTER (WHERE evidence_code='M1_8_VERIFICATION_SET_HASH') AS verification_hash,
      max(metric_value_text) FILTER (WHERE evidence_code='M1_8_SUMMARY_SET_HASH') AS summary_hash,
      max(metric_value_text) FILTER (WHERE evidence_code='M1_8_COMBINED_SET_HASH') AS combined_hash
    FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
)
SELECT
    r.run_id,r.run_status,
    (SELECT count(*) FROM msbf_m1.verification_result WHERE created_by_run_id=r.run_id) AS verification_rows,
    (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.verification_result WHERE created_by_run_id=r.run_id) AS applications,
    (SELECT count(DISTINCT check_code) FROM msbf_m1.verification_result WHERE created_by_run_id=r.run_id) AS checks,
    (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=r.run_id) AS summary_rows,
    5250 AS expected_canonical_rows,
    (SELECT count(*) FROM msbf_m1.m1_8_actual_entity_snapshot(r.run_id)) AS actual_canonical_rows,
    hashes.verification_hash,hashes.summary_hash,hashes.combined_hash,
    CASE
      WHEN r.run_status='M1_8_GENERATED'
       AND (SELECT count(*) FROM msbf_m1.verification_result WHERE created_by_run_id=r.run_id)=4500
       AND (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=r.run_id)=750
       AND (SELECT count(*) FROM msbf_m1.m1_8_actual_entity_snapshot(r.run_id))=5250
       AND hashes.verification_hash IS NOT NULL AND hashes.summary_hash IS NOT NULL AND hashes.combined_hash IS NOT NULL
      THEN 'PASS' ELSE 'FAIL' END AS generation_status
FROM r CROSS JOIN hashes;
