/* ============================================================================
MSBF M1.7 Source Quality & Data Confidence — Positive Validation
Version : v0.2
Purpose : Execute 55 blocking checks against persisted 5,250-row source
          snapshots. Accepted daily histories are not rebuilt.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='15min';

DO $pre$
DECLARE
    v_run_id bigint;
    v_status text;
BEGIN
    SELECT run_id, run_status
      INTO STRICT v_run_id, v_status
      FROM msbf_ctl.run_registry
     WHERE run_code='M1_V0_2_BASELINE_BUILD'
       AND run_version=1
     FOR UPDATE;

    IF v_status NOT IN ('M1_7_GENERATED','M1_7_FAILED') THEN
        RAISE EXCEPTION
            'M1.7 validation requires M1_7_GENERATED or M1_7_FAILED; observed %.',
            v_status;
    END IF;
END;
$pre$;

CREATE TEMP TABLE _m1_7_vctx ON COMMIT DROP AS
SELECT
    r.run_id,
    r.run_status,
    r.population_id,
    r.as_of_date,
    p.history_start_date,
    p.history_end_date,
    p.deterministic_seed_version,
    p.population_hash,
    r.parameter_snapshot_hash,
    r.profile_snapshot_hash,
    r.source_snapshot_hash,
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
    r.run_status,
    r.population_id,
    r.as_of_date,
    p.history_start_date,
    p.history_end_date,
    p.deterministic_seed_version,
    p.population_hash,
    r.parameter_snapshot_hash,
    r.profile_snapshot_hash,
    r.source_snapshot_hash;

CREATE TEMP TABLE _m1_7_vs ON COMMIT DROP AS
SELECT
    s.*,
    a.merchant_id,
    a.processor_account_id,
    a.partner_channel_id,
    a.as_of_date,
    pa.processor_account_open_date,
    sc.source_code AS contract_source_code,
    sc.required_history_days,
    sc.freshness_sla_hours,
    sc.minimum_completeness_rate,
    sc.reconciliation_tolerance_rate,
    sc.status AS contract_status,
    sc.effective_start_date AS contract_effective_start_date,
    sc.effective_end_date AS contract_effective_end_date,
    rps.resolved_value AS outage_value,
    CASE
        WHEN s.source_code='POS_DAILY'
            THEN greatest((SELECT pos_min_days FROM _m1_7_vctx),sc.required_history_days)
        WHEN s.source_code='DEPOSIT_DAILY'
            THEN greatest((SELECT deposit_min_days FROM _m1_7_vctx),sc.required_history_days)
        ELSE 0
    END::integer AS effective_required_history_days,
    greatest((SELECT complete_pass FROM _m1_7_vctx),sc.minimum_completeness_rate)
        AS effective_complete_pass,
    least(
        greatest((SELECT complete_warn FROM _m1_7_vctx),0),
        greatest((SELECT complete_pass FROM _m1_7_vctx),sc.minimum_completeness_rate)
    ) AS effective_complete_warn,
    least(
        (SELECT fresh_pass_days FROM _m1_7_vctx)*24,
        coalesce(sc.freshness_sla_hours,(SELECT fresh_pass_days FROM _m1_7_vctx)*24)
    )::integer AS effective_fresh_pass_hours,
    greatest(
        (SELECT fresh_warn_days FROM _m1_7_vctx)*24,
        least(
            (SELECT fresh_pass_days FROM _m1_7_vctx)*24,
            coalesce(sc.freshness_sla_hours,(SELECT fresh_pass_days FROM _m1_7_vctx)*24)
        )
    )::integer AS effective_fresh_warn_hours,
    greatest(
        (SELECT recon_pass FROM _m1_7_vctx),
        CASE
            WHEN sc.reconciliation_tolerance_rate IS NULL THEN 0
            ELSE 1-sc.reconciliation_tolerance_rate
        END
    ) AS effective_recon_pass,
    least(
        greatest((SELECT recon_warn FROM _m1_7_vctx),0),
        greatest(
            (SELECT recon_pass FROM _m1_7_vctx),
            CASE
                WHEN sc.reconciliation_tolerance_rate IS NULL THEN 0
                ELSE 1-sc.reconciliation_tolerance_rate
            END
        )
    ) AS effective_recon_warn
FROM msbf_m1.source_snapshot s
JOIN msbf_m1.merchant_application a
  ON a.merchant_application_id=s.merchant_application_id
JOIN msbf_m1.processor_account pa
  ON pa.processor_account_id=a.processor_account_id
JOIN msbf_ctl.source_contract sc
  ON sc.source_contract_id=s.source_contract_id
JOIN msbf_ctl.run_parameter_snapshot rps
  ON rps.run_id=s.module1_run_id
 AND rps.parameter_name='source_outage_probability'
 AND rps.scope_key='SOURCE:' || s.source_code
WHERE s.module1_run_id=(SELECT run_id FROM _m1_7_vctx);
CREATE UNIQUE INDEX ON _m1_7_vs(merchant_application_id,source_code);
CREATE INDEX ON _m1_7_vs(source_code,quality_status);

CREATE TEMP TABLE _m1_7_vactual ON COMMIT DROP AS
SELECT *
FROM msbf_m1.m1_7_actual_source_snapshot((SELECT run_id FROM _m1_7_vctx));
CREATE UNIQUE INDEX ON _m1_7_vactual(entity_key);

CREATE TEMP TABLE _m1_7_pos_actual ON COMMIT DROP AS
SELECT
    p.merchant_id,
    count(*) FILTER (
        WHERE p.observation_date>=pa.processor_account_open_date
          AND p.data_connection_status IN ('CONNECTED','DELAYED')
    )::integer AS observed_rows,
    max(p.observation_date) FILTER (
        WHERE p.observation_date>=pa.processor_account_open_date
          AND p.data_connection_status IN ('CONNECTED','DELAYED')
    ) AS observed_end
FROM msbf_m1.merchant_pos_daily_base p
JOIN msbf_m1.processor_account pa
  ON pa.processor_account_id=p.processor_account_id
WHERE p.generated_by_run_id=(SELECT run_id FROM _m1_7_vctx)
GROUP BY p.merchant_id;
CREATE UNIQUE INDEX ON _m1_7_pos_actual(merchant_id);

CREATE TEMP TABLE _m1_7_vliq ON COMMIT DROP AS
SELECT merchant_id, deposit_source_available_flag
FROM msbf_m1.m1_5_merchant_liquidity_profile((SELECT run_id FROM _m1_7_vctx));
CREATE UNIQUE INDEX ON _m1_7_vliq(merchant_id);

CREATE TEMP TABLE _m1_7_vapp ON COMMIT DROP AS
SELECT
    merchant_application_id,
    greatest(
        0,
        least(
            1,
            sum(
                data_confidence_score
                * CASE source_code
                    WHEN 'POS_DAILY' THEN 0.35
                    WHEN 'DEPOSIT_DAILY' THEN 0.20
                    WHEN 'VERIFICATION' THEN 0.15
                    WHEN 'BUSINESS_CREDIT' THEN 0.10
                    WHEN 'OWNER_CREDIT' THEN 0.08
                    WHEN 'OBLIGATIONS' THEN 0.07
                    WHEN 'COLLATERAL_AVAILABILITY' THEN 0.05
                  END
            )
            - coalesce(
                max((SELECT missing_pos_penalty FROM _m1_7_vctx))
                    FILTER (WHERE source_code='POS_DAILY' AND availability_status='UNAVAILABLE'),
                0
              )
            - coalesce(
                max((SELECT missing_deposit_penalty FROM _m1_7_vctx))
                    FILTER (WHERE source_code='DEPOSIT_DAILY' AND availability_status='UNAVAILABLE'),
                0
              )
        )
    )::numeric AS application_confidence_score,
    count(*) FILTER (WHERE quality_status='CONFLICT') AS conflict_count,
    bool_or(source_code='POS_DAILY' AND availability_status='UNAVAILABLE') AS pos_unavailable,
    bool_or(source_code='VERIFICATION' AND availability_status='UNAVAILABLE') AS verification_unavailable,
    count(*) FILTER (WHERE quality_status<>'PASS') AS nonpass_count
FROM _m1_7_vs
GROUP BY merchant_application_id;
CREATE UNIQUE INDEX ON _m1_7_vapp(merchant_application_id);

ANALYZE _m1_7_vs;
ANALYZE _m1_7_vactual;
ANALYZE _m1_7_pos_actual;
ANALYZE _m1_7_vapp;

CREATE TEMP TABLE _m1_7_checks(
    code text,
    name text,
    observed text,
    threshold text,
    status text,
    interpretation text
) ON COMMIT DROP;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_01_RUN_STATUS','Run status',run_status,'M1_7_GENERATED or M1_7_FAILED',
       CASE WHEN run_status IN ('M1_7_GENERATED','M1_7_FAILED') THEN 'PASS' ELSE 'FAIL' END,
       'Validation begins from the generated source-quality state.'
FROM _m1_7_vctx;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_02_M1_6_GATE','Accepted M1.6 gate',
       coalesce((
           SELECT result_status
           FROM msbf_ctl.acceptance_gate_result
           WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
             AND gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS'
           ORDER BY review_version DESC
           LIMIT 1
       ),'<NULL>'),
       'PASS',
       CASE WHEN (
           SELECT result_status
           FROM msbf_ctl.acceptance_gate_result
           WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
             AND gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS'
           ORDER BY review_version DESC
           LIMIT 1
       )='PASS' THEN 'PASS' ELSE 'FAIL' END,
       'M1.6 must remain accepted.';

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_03_PARAMETER_HASH','Parameter snapshot hash',parameter_snapshot_hash,
       'bd09e598c82db96e47459d77fd11e7c8',
       CASE WHEN parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8' THEN 'PASS' ELSE 'FAIL' END,
       'Frozen parameter identity remains unchanged.'
FROM _m1_7_vctx;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_04_PROFILE_HASH','Profile snapshot hash',profile_snapshot_hash,
       '462cbd2ed92f68e5bdecf6b17537a973',
       CASE WHEN profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973' THEN 'PASS' ELSE 'FAIL' END,
       'Frozen profile identity remains unchanged.'
FROM _m1_7_vctx;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_05_SOURCE_HASH','Run-source snapshot hash',source_snapshot_hash,
       '93c3d1368fb2450ab4a08e2b721f92d3',
       CASE WHEN source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3' THEN 'PASS' ELSE 'FAIL' END,
       'Frozen run-source identity remains unchanged.'
FROM _m1_7_vctx;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_06_POPULATION_HASH','Population hash',population_hash,
       '9b706c926260a3ef1ae8ac95eed5d0bf',
       CASE WHEN population_hash='9b706c926260a3ef1ae8ac95eed5d0bf' THEN 'PASS' ELSE 'FAIL' END,
       'Accepted population identity remains unchanged.'
FROM _m1_7_vctx;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_07_APPLICATION_HASH','Application set hash',
       coalesce((SELECT metric_value_text FROM msbf_ctl.run_evidence
                 WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
                   AND evidence_code='M1_3_APPLICATION_SET_HASH'),'<NULL>'),
       '01485256b9b5748fb412743d35ced602',
       CASE WHEN (SELECT metric_value_text FROM msbf_ctl.run_evidence
                  WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
                    AND evidence_code='M1_3_APPLICATION_SET_HASH')
                  ='01485256b9b5748fb412743d35ced602'
            THEN 'PASS' ELSE 'FAIL' END,
       'Accepted M1.3 identity remains unchanged.';

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_08_POS_HASH','Baseline POS hash',
       coalesce((SELECT metric_value_text FROM msbf_ctl.run_evidence
                 WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
                   AND evidence_code='M1_4_POS_SET_HASH'),'<NULL>'),
       'd1971e8d319483c187ec0c0483a31e33',
       CASE WHEN (SELECT metric_value_text FROM msbf_ctl.run_evidence
                  WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
                    AND evidence_code='M1_4_POS_SET_HASH')
                  ='d1971e8d319483c187ec0c0483a31e33'
            THEN 'PASS' ELSE 'FAIL' END,
       'Accepted baseline POS history remains unchanged.';

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_09_DEPOSIT_HASH','Baseline deposit hash',
       coalesce((SELECT metric_value_text FROM msbf_ctl.run_evidence
                 WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
                   AND evidence_code='M1_5_DEPOSIT_SET_HASH'),'<NULL>'),
       'bbe96dd24fbbba3af4a587dd475a88d0',
       CASE WHEN (SELECT metric_value_text FROM msbf_ctl.run_evidence
                  WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
                    AND evidence_code='M1_5_DEPOSIT_SET_HASH')
                  ='bbe96dd24fbbba3af4a587dd475a88d0'
            THEN 'PASS' ELSE 'FAIL' END,
       'Accepted baseline deposit history remains unchanged.';

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_10_SCENARIO_HASH','M1.6 combined scenario hash',
       coalesce((SELECT metric_value_text FROM msbf_ctl.run_evidence
                 WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
                   AND evidence_code='M1_6_COMBINED_SET_HASH'),'<NULL>'),
       '3f85921bf6fc30ddc6cee146085e58c5',
       CASE WHEN (SELECT metric_value_text FROM msbf_ctl.run_evidence
                  WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
                    AND evidence_code='M1_6_COMBINED_SET_HASH')
                  ='3f85921bf6fc30ddc6cee146085e58c5'
            THEN 'PASS' ELSE 'FAIL' END,
       'Accepted matched-scenario identity remains unchanged.';

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_11_ROW_COUNT','Source snapshot row count',count(*)::text,'5250',
       CASE WHEN count(*)=5250 THEN 'PASS' ELSE 'FAIL' END,
       'Seven source snapshots per 750 applications.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_12_APPLICATION_COUNT','Application coverage',
       count(DISTINCT merchant_application_id)::text,'750',
       CASE WHEN count(DISTINCT merchant_application_id)=750 THEN 'PASS' ELSE 'FAIL' END,
       'Every accepted application is represented.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_13_SOURCE_COUNT','Source family coverage',
       count(DISTINCT source_code)::text,'7',
       CASE WHEN count(DISTINCT source_code)=7 THEN 'PASS' ELSE 'FAIL' END,
       'All seven approved source families are represented.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_14_UNIQUE_GRAIN','Unique application/source grain',
       count(*)::text || '/' ||
       count(DISTINCT merchant_application_id || '|' || source_code)::text,
       '5250/5250',
       CASE WHEN count(*)=count(DISTINCT merchant_application_id || '|' || source_code)
            THEN 'PASS' ELSE 'FAIL' END,
       'The physical application/source grain is unique.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_15_SEVEN_PER_APPLICATION','Seven sources per application',
       count(*) FILTER (WHERE n<>7)::text,'0',
       CASE WHEN count(*) FILTER (WHERE n<>7)=0 THEN 'PASS' ELSE 'FAIL' END,
       'Every application has exactly seven source snapshots.'
FROM (
    SELECT merchant_application_id,count(*) AS n
    FROM _m1_7_vs
    GROUP BY merchant_application_id
) q;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_16_CONTRACT_ALIGNMENT','Source-contract alignment',
       count(*) FILTER (
           WHERE source_contract_id IS NULL
              OR source_code IS DISTINCT FROM contract_source_code
              OR contract_status<>'APPROVED'
              OR contract_effective_start_date>as_of_date
              OR (contract_effective_end_date IS NOT NULL
                  AND contract_effective_end_date<=as_of_date)
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE source_contract_id IS NULL
              OR source_code IS DISTINCT FROM contract_source_code
              OR contract_status<>'APPROVED'
              OR contract_effective_start_date>as_of_date
              OR (contract_effective_end_date IS NOT NULL
                  AND contract_effective_end_date<=as_of_date)
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Every source snapshot references the approved effective source contract.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_17_ASOF_CONTROL','As-of timestamp control',
       count(*) FILTER (
           WHERE as_of_timestamp>((as_of_date+time '23:59:59') AT TIME ZONE 'UTC')
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE as_of_timestamp>((as_of_date+time '23:59:59') AT TIME ZONE 'UTC')
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'No source snapshot is later than the application as-of time.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_18_HISTORY_DATE_CONTROL','History date control',
       count(*) FILTER (
           WHERE history_end_date>as_of_date
              OR (history_start_date IS NOT NULL AND history_start_date>history_end_date)
              OR (observed_observation_count=0
                  AND (history_start_date IS NOT NULL OR history_end_date IS NOT NULL))
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE history_end_date>as_of_date
              OR (history_start_date IS NOT NULL AND history_start_date>history_end_date)
              OR (observed_observation_count=0
                  AND (history_start_date IS NOT NULL OR history_end_date IS NOT NULL))
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Source history is nonfuture, noninverted, and absent when no observation exists.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_19_COUNT_BOUNDS','Observation-count bounds',
       count(*) FILTER (
           WHERE expected_observation_count<0
              OR observed_observation_count<0
              OR observed_observation_count>expected_observation_count
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE expected_observation_count<0
              OR observed_observation_count<0
              OR observed_observation_count>expected_observation_count
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Observed counts cannot exceed expected counts.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_20_COMPLETENESS_IDENTITY','Completeness identity',
       count(*) FILTER (
           WHERE abs(
               completeness_rate
               - CASE
                   WHEN expected_observation_count=0 THEN 1
                   ELSE observed_observation_count::numeric/expected_observation_count
                 END
           )>0.000001
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE abs(
               completeness_rate
               - CASE
                   WHEN expected_observation_count=0 THEN 1
                   ELSE observed_observation_count::numeric/expected_observation_count
                 END
           )>0.000001
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Completeness reconciles to observed divided by expected observations.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_21_COMPLETENESS_RANGE','Completeness range',
       count(*) FILTER (WHERE completeness_rate NOT BETWEEN 0 AND 1)::text,'0',
       CASE WHEN count(*) FILTER (WHERE completeness_rate NOT BETWEEN 0 AND 1)=0
            THEN 'PASS' ELSE 'FAIL' END,
       'Completeness remains within [0,1].'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_22_FRESHNESS_RANGE','Freshness range',
       count(*) FILTER (WHERE freshness_age_hours<0)::text,'0',
       CASE WHEN count(*) FILTER (WHERE freshness_age_hours<0)=0
            THEN 'PASS' ELSE 'FAIL' END,
       'Freshness age is nonnegative.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_23_RECON_RANGE','Reconciliation range',
       count(*) FILTER (
           WHERE reconciliation_rate IS NOT NULL
             AND reconciliation_rate NOT BETWEEN 0 AND 1
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE reconciliation_rate IS NOT NULL
             AND reconciliation_rate NOT BETWEEN 0 AND 1
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Reconciliation remains within [0,1].'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_24_CONFIDENCE_RANGE','Source confidence range',
       count(*) FILTER (WHERE data_confidence_score NOT BETWEEN 0 AND 1)::text,'0',
       CASE WHEN count(*) FILTER (WHERE data_confidence_score NOT BETWEEN 0 AND 1)=0
            THEN 'PASS' ELSE 'FAIL' END,
       'Source confidence remains within [0,1].'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_25_AVAILABILITY_VALUES','Availability-status domain',
       count(*) FILTER (
           WHERE availability_status NOT IN ('AVAILABLE','PARTIAL','UNAVAILABLE')
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE availability_status NOT IN ('AVAILABLE','PARTIAL','UNAVAILABLE')
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Only governed availability statuses are used.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_26_QUALITY_VALUES','Quality-status domain',
       count(*) FILTER (
           WHERE quality_status NOT IN ('PASS','WARNING','FAIL','CONFLICT','UNAVAILABLE')
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE quality_status NOT IN ('PASS','WARNING','FAIL','CONFLICT','UNAVAILABLE')
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Only governed quality statuses are used.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_27_FALLBACK_COMPLETENESS','Fallback completeness',
       count(*) FILTER (
           WHERE quality_status<>'PASS'
             AND (fallback_path_code IS NULL OR fallback_path_code='NONE')
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE quality_status<>'PASS'
             AND (fallback_path_code IS NULL OR fallback_path_code='NONE')
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Every non-pass source has an explicit fallback or review path.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_28_PASS_NO_FALLBACK','Passing rows use no fallback',
       count(*) FILTER (
           WHERE quality_status='PASS' AND fallback_path_code<>'NONE'
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE quality_status='PASS' AND fallback_path_code<>'NONE'
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Passing source evidence requires no fallback.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_29_POS_EXPECTED_HISTORY','POS expected-history logic',
       count(*) FILTER (
           WHERE source_code='POS_DAILY'
             AND expected_observation_count<>greatest(
                 0,
                 as_of_date-greatest((SELECT history_start_date FROM _m1_7_vctx),
                                     processor_account_open_date)+1
             )
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE source_code='POS_DAILY'
             AND expected_observation_count<>greatest(
                 0,
                 as_of_date-greatest((SELECT history_start_date FROM _m1_7_vctx),
                                     processor_account_open_date)+1
             )
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'POS expected history follows the active processor window.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_30_POS_OBSERVED_HISTORY','POS observed-history logic',
       count(*) FILTER (
           WHERE v.source_code='POS_DAILY'
             AND v.availability_status<>'UNAVAILABLE'
             AND v.observed_observation_count<>p.observed_rows
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE v.source_code='POS_DAILY'
             AND v.availability_status<>'UNAVAILABLE'
             AND v.observed_observation_count<>p.observed_rows
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Available POS observed count matches accepted connected or delayed rows.'
FROM _m1_7_vs v
JOIN _m1_7_pos_actual p USING(merchant_id);

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_31_POS_FRESHNESS','POS freshness logic',
       count(*) FILTER (
           WHERE v.source_code='POS_DAILY'
             AND v.availability_status<>'UNAVAILABLE'
             AND v.freshness_age_hours<>greatest(0,(v.as_of_date-p.observed_end)*24)
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE v.source_code='POS_DAILY'
             AND v.availability_status<>'UNAVAILABLE'
             AND v.freshness_age_hours<>greatest(0,(v.as_of_date-p.observed_end)*24)
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'POS freshness is based on the latest usable accepted row.'
FROM _m1_7_vs v
JOIN _m1_7_pos_actual p USING(merchant_id);

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_32_DEPOSIT_EXPECTED_HISTORY','Deposit expected-history logic',
       count(*) FILTER (
           WHERE source_code='DEPOSIT_DAILY'
             AND expected_observation_count<>greatest(
                 0,
                 as_of_date-greatest((SELECT history_start_date FROM _m1_7_vctx),
                                     processor_account_open_date)+1
             )
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE source_code='DEPOSIT_DAILY'
             AND expected_observation_count<>greatest(
                 0,
                 as_of_date-greatest((SELECT history_start_date FROM _m1_7_vctx),
                                     processor_account_open_date)+1
             )
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Deposit expected history follows the active processor window.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_33_DEPOSIT_AVAILABILITY','Deposit-source availability alignment',
       count(*) FILTER (
           WHERE v.source_code='DEPOSIT_DAILY'
             AND NOT lp.deposit_source_available_flag
             AND v.availability_status<>'UNAVAILABLE'
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE v.source_code='DEPOSIT_DAILY'
             AND NOT lp.deposit_source_available_flag
             AND v.availability_status<>'UNAVAILABLE'
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'M1.5 governed deposit-source missingness is preserved.'
FROM _m1_7_vs v
JOIN _m1_7_vliq lp USING(merchant_id);

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_34_DEPOSIT_OBSERVED_COUNT','Deposit observed-count logic',
       count(*) FILTER (
           WHERE source_code='DEPOSIT_DAILY'
             AND availability_status='AVAILABLE'
             AND observed_observation_count<>expected_observation_count
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE source_code='DEPOSIT_DAILY'
             AND availability_status='AVAILABLE'
             AND observed_observation_count<>expected_observation_count
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Available deposit history is complete at the accepted physical source grain.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_35_POINT_EXPECTED_COUNTS','Point-source expected counts',
       count(*) FILTER (
           WHERE (source_code='OWNER_CREDIT'
                  AND expected_observation_count<>(
                      SELECT count(*)
                      FROM msbf_m1.merchant_owner_guarantor o
                      WHERE o.merchant_id=v.merchant_id
                  ))
              OR (source_code='VERIFICATION'
                  AND expected_observation_count<>(SELECT verification_check_count FROM _m1_7_vctx))
              OR (source_code IN ('BUSINESS_CREDIT','OBLIGATIONS','COLLATERAL_AVAILABILITY')
                  AND expected_observation_count<>1)
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE (source_code='OWNER_CREDIT'
                  AND expected_observation_count<>(
                      SELECT count(*)
                      FROM msbf_m1.merchant_owner_guarantor o
                      WHERE o.merchant_id=v.merchant_id
                  ))
              OR (source_code='VERIFICATION'
                  AND expected_observation_count<>(SELECT verification_check_count FROM _m1_7_vctx))
              OR (source_code IN ('BUSINESS_CREDIT','OBLIGATIONS','COLLATERAL_AVAILABILITY')
                  AND expected_observation_count<>1)
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Point-source expected counts match governed source semantics.'
FROM _m1_7_vs v;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_36_UNAVAILABLE_ZERO_OBS','Unavailable rows have zero observations',
       count(*) FILTER (
           WHERE availability_status='UNAVAILABLE' AND observed_observation_count<>0
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE availability_status='UNAVAILABLE' AND observed_observation_count<>0
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Unavailable sources are not represented as observed merchant evidence.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_37_PARTIAL_COUNTS','Partial rows have partial counts',
       count(*) FILTER (
           WHERE availability_status='PARTIAL'
             AND NOT (
                 observed_observation_count>0
                 AND observed_observation_count<expected_observation_count
             )
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE availability_status='PARTIAL'
             AND NOT (
                 observed_observation_count>0
                 AND observed_observation_count<expected_observation_count
             )
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Partial sources retain some but not all expected observations.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_38_THRESHOLD_ORDER','Threshold ordering',
       format(
           'fresh=%s<=%s complete=%s<=%s recon=%s<=%s',
           fresh_pass_days,fresh_warn_days,
           complete_warn,complete_pass,
           recon_warn,recon_pass
       ),
       'ordered',
       CASE WHEN fresh_pass_days<=fresh_warn_days
              AND complete_warn<=complete_pass
              AND recon_warn<=recon_pass
            THEN 'PASS' ELSE 'FAIL' END,
       'Governed global thresholds remain monotonic.'
FROM _m1_7_vctx;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_39_DETERMINISTIC_OUTAGE','Deterministic source-outage assignment',
       count(*) FILTER (
           WHERE msbf_ctl.deterministic_uniform(
                     merchant_application_id,
                     (SELECT deterministic_seed_version FROM _m1_7_vctx)
                       || ':M1_7:' || source_code || ':OUTAGE'
                 ) < (outage_value->>'value_numeric')::numeric
             AND availability_status<>'UNAVAILABLE'
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE msbf_ctl.deterministic_uniform(
                     merchant_application_id,
                     (SELECT deterministic_seed_version FROM _m1_7_vctx)
                       || ':M1_7:' || source_code || ':OUTAGE'
                 ) < (outage_value->>'value_numeric')::numeric
             AND availability_status<>'UNAVAILABLE'
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Deterministic as-of outages always produce unavailable evidence.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_40_CONTRACT_THRESHOLDS','Contract and global threshold enforcement',
       count(*) FILTER (
           WHERE quality_status='PASS'
             AND (
                 (source_code IN ('POS_DAILY','DEPOSIT_DAILY')
                  AND observed_observation_count<effective_required_history_days)
                 OR completeness_rate<effective_complete_pass
                 OR freshness_age_hours>effective_fresh_pass_hours
                 OR (reconciliation_rate IS NOT NULL
                     AND reconciliation_rate<effective_recon_pass)
             )
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE quality_status='PASS'
             AND (
                 (source_code IN ('POS_DAILY','DEPOSIT_DAILY')
                  AND observed_observation_count<effective_required_history_days)
                 OR completeness_rate<effective_complete_pass
                 OR freshness_age_hours>effective_fresh_pass_hours
                 OR (reconciliation_rate IS NOT NULL
                     AND reconciliation_rate<effective_recon_pass)
             )
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'No passing source violates governed contract or global thresholds.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_41_FALLBACK_LOGIC','Critical fallback logic',
       count(*) FILTER (
           WHERE (source_code='POS_DAILY'
                  AND availability_status='UNAVAILABLE'
                  AND fallback_path_code<>'FAIL_CLOSED_NO_POS')
              OR (source_code='VERIFICATION'
                  AND availability_status='UNAVAILABLE'
                  AND fallback_path_code<>'FAIL_CLOSED_VERIFICATION')
              OR (source_code='DEPOSIT_DAILY'
                  AND availability_status='UNAVAILABLE'
                  AND fallback_path_code<>'POS_ONLY')
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE (source_code='POS_DAILY'
                  AND availability_status='UNAVAILABLE'
                  AND fallback_path_code<>'FAIL_CLOSED_NO_POS')
              OR (source_code='VERIFICATION'
                  AND availability_status='UNAVAILABLE'
                  AND fallback_path_code<>'FAIL_CLOSED_VERIFICATION')
              OR (source_code='DEPOSIT_DAILY'
                  AND availability_status='UNAVAILABLE'
                  AND fallback_path_code<>'POS_ONLY')
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Critical source gaps fail closed or use the explicitly approved fallback.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_42_RECON_PAIR_CONSISTENCY','POS/deposit reconciliation consistency',
       count(*) FILTER (
           WHERE p.reconciliation_rate IS DISTINCT FROM d.reconciliation_rate
       )::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE p.reconciliation_rate IS DISTINCT FROM d.reconciliation_rate
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'POS and deposit snapshots share the same paired-source reconciliation evidence.'
FROM _m1_7_vs p
JOIN _m1_7_vs d
  ON d.merchant_application_id=p.merchant_application_id
 AND d.source_code='DEPOSIT_DAILY'
WHERE p.source_code='POS_DAILY';

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_43_CRITICAL_POS_FAIL_CLOSED','Missing POS fail-closed route',
       count(*) FILTER (
           WHERE source_code='POS_DAILY'
             AND availability_status='UNAVAILABLE'
             AND fallback_path_code='FAIL_CLOSED_NO_POS'
       )::text,
       'all missing POS',
       CASE WHEN count(*) FILTER (
           WHERE source_code='POS_DAILY'
             AND availability_status='UNAVAILABLE'
             AND fallback_path_code<>'FAIL_CLOSED_NO_POS'
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Unavailable POS is never interpreted as zero merchant sales.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_44_VERIFICATION_FAIL_CLOSED','Missing verification fail-closed route',
       count(*) FILTER (
           WHERE source_code='VERIFICATION'
             AND availability_status='UNAVAILABLE'
             AND fallback_path_code='FAIL_CLOSED_VERIFICATION'
       )::text,
       'all missing verification',
       CASE WHEN count(*) FILTER (
           WHERE source_code='VERIFICATION'
             AND availability_status='UNAVAILABLE'
             AND fallback_path_code<>'FAIL_CLOSED_VERIFICATION'
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Unavailable verification is a hard-stop source condition.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_45_DEPOSIT_POS_ONLY','Missing deposit POS-only route',
       count(*) FILTER (
           WHERE source_code='DEPOSIT_DAILY'
             AND availability_status='UNAVAILABLE'
             AND fallback_path_code='POS_ONLY'
       )::text,
       'all missing deposit',
       CASE WHEN count(*) FILTER (
           WHERE source_code='DEPOSIT_DAILY'
             AND availability_status='UNAVAILABLE'
             AND fallback_path_code<>'POS_ONLY'
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Unavailable deposit evidence routes to the governed POS-only pathway.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_46_CONFLICT_REVIEW','Conflict manual-review route',
       count(*) FILTER (
           WHERE quality_status='CONFLICT'
             AND fallback_path_code='MANUAL_REVIEW_SOURCE_CONFLICT'
       )::text,
       'all conflicts',
       CASE WHEN count(*) FILTER (
           WHERE quality_status='CONFLICT'
             AND fallback_path_code<>'MANUAL_REVIEW_SOURCE_CONFLICT'
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Source conflicts route to manual review.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_47_QUALITY_DIVERSITY','Quality-outcome diversity',
       count(DISTINCT quality_status)::text,
       '>=2 with pass and nonpass',
       CASE WHEN count(DISTINCT quality_status)>=2
              AND count(*) FILTER (WHERE quality_status='PASS')>0
              AND count(*) FILTER (WHERE quality_status<>'PASS')>0
            THEN 'PASS' ELSE 'FAIL' END,
       'The synthetic portfolio contains both passing and non-passing source evidence.'
FROM _m1_7_vs;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_48_APP_CONFIDENCE_RANGE','Application confidence range',
       count(*) FILTER (WHERE application_confidence_score NOT BETWEEN 0 AND 1)::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE application_confidence_score NOT BETWEEN 0 AND 1
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Derived application confidence remains bounded.'
FROM _m1_7_vapp;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_49_MANUAL_REVIEW_THRESHOLD','Conflict review threshold',
       format(
           'threshold=%s review_apps=%s',
           (SELECT conflict_review_threshold FROM _m1_7_vctx),
           count(*) FILTER (
               WHERE conflict_count>=(SELECT conflict_review_threshold FROM _m1_7_vctx)
           )
       ),
       'threshold >= 1',
       CASE WHEN (SELECT conflict_review_threshold FROM _m1_7_vctx)>=1
            THEN 'PASS' ELSE 'FAIL' END,
       'The governed source-conflict threshold is valid and produces review diagnostics.'
FROM _m1_7_vapp;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_50_ROW_HASH','Physical row-hash recomputation',
       count(*) FILTER (WHERE s.source_hash IS DISTINCT FROM a.row_hash)::text,
       '0',
       CASE WHEN count(*) FILTER (
           WHERE s.source_hash IS DISTINCT FROM a.row_hash
       )=0 THEN 'PASS' ELSE 'FAIL' END,
       'Every persisted source hash recomputes from the physical source fields.'
FROM _m1_7_vs s
JOIN _m1_7_vactual a
  ON a.entity_key=s.merchant_application_id || '|' || s.source_code;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_51_SET_HASH','Source-set hash reconciliation',
       coalesce((
           SELECT metric_value_text
           FROM msbf_ctl.run_evidence
           WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
             AND evidence_code='M1_7_SOURCE_SET_HASH'
       ),'<NULL>')
       || '/'
       || md5(string_agg(entity_key || '|' || row_hash,'||' ORDER BY entity_key)),
       'equal',
       CASE WHEN (
           SELECT metric_value_text
           FROM msbf_ctl.run_evidence
           WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
             AND evidence_code='M1_7_SOURCE_SET_HASH'
       )=md5(string_agg(entity_key || '|' || row_hash,'||' ORDER BY entity_key))
       THEN 'PASS' ELSE 'FAIL' END,
       'Stored and independently recomputed physical source-set hashes agree.'
FROM _m1_7_vactual;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_52_GENERATION_EVIDENCE','Generation evidence',
       coalesce((
           SELECT metric_value_text
           FROM msbf_ctl.run_evidence
           WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
             AND evidence_code='M1_7_GENERATION_CANONICAL_RECON'
       ),'<NULL>'),
       'expected=5250 actual=5250 mismatches=0',
       CASE WHEN (
           SELECT metric_value_text
           FROM msbf_ctl.run_evidence
           WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
             AND evidence_code='M1_7_GENERATION_CANONICAL_RECON'
       )='expected=5250 actual=5250 mismatches=0'
       THEN 'PASS' ELSE 'FAIL' END,
       'Generation-time expected and actual snapshots reconciled before commit.';

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_53_BASE_HISTORY_UNCHANGED','Accepted histories unchanged',
       format(
           'POS=%s DEP=%s SCEN_POS=%s SCEN_DEP=%s',
           (SELECT count(*) FROM msbf_m1.merchant_pos_daily_base
             WHERE generated_by_run_id=(SELECT run_id FROM _m1_7_vctx)),
           (SELECT count(*) FROM msbf_m1.merchant_deposit_daily_base
             WHERE generated_by_run_id=(SELECT run_id FROM _m1_7_vctx)),
           (SELECT count(*) FROM msbf_m1.merchant_pos_daily_scenario
             WHERE generated_by_run_id=(SELECT run_id FROM _m1_7_vctx)),
           (SELECT count(*) FROM msbf_m1.merchant_deposit_daily_scenario
             WHERE generated_by_run_id=(SELECT run_id FROM _m1_7_vctx))
       ),
       '135000/135000/270000/270000',
       CASE WHEN
           (SELECT count(*) FROM msbf_m1.merchant_pos_daily_base
             WHERE generated_by_run_id=(SELECT run_id FROM _m1_7_vctx))=135000
       AND (SELECT count(*) FROM msbf_m1.merchant_deposit_daily_base
             WHERE generated_by_run_id=(SELECT run_id FROM _m1_7_vctx))=135000
       AND (SELECT count(*) FROM msbf_m1.merchant_pos_daily_scenario
             WHERE generated_by_run_id=(SELECT run_id FROM _m1_7_vctx))=270000
       AND (SELECT count(*) FROM msbf_m1.merchant_deposit_daily_scenario
             WHERE generated_by_run_id=(SELECT run_id FROM _m1_7_vctx))=270000
       THEN 'PASS' ELSE 'FAIL' END,
       'M1.7 does not modify accepted baseline or scenario histories.';

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_54_STAGE_BOUNDARY','Strict stage boundary',
       v::text,'0',
       CASE WHEN v=0 THEN 'PASS' ELSE 'FAIL' END,
       'M1.7 does not create obligations, credit, verification, features, risk, EAD, latest, or archive outputs.'
FROM (
    SELECT
        (SELECT count(*) FROM msbf_m1.application_obligation_snapshot
          WHERE created_by_run_id=(SELECT run_id FROM _m1_7_vctx))
      + (SELECT count(*) FROM msbf_m1.collateral_availability_snapshot
          WHERE created_by_run_id=(SELECT run_id FROM _m1_7_vctx))
      + (SELECT count(*) FROM msbf_m1.guarantee_availability_snapshot
          WHERE created_by_run_id=(SELECT run_id FROM _m1_7_vctx))
      + (SELECT count(*) FROM msbf_m1.application_business_credit_snapshot
          WHERE created_by_run_id=(SELECT run_id FROM _m1_7_vctx))
      + (SELECT count(*) FROM msbf_m1.application_owner_credit_snapshot
          WHERE created_by_run_id=(SELECT run_id FROM _m1_7_vctx))
      + (SELECT count(*) FROM msbf_m1.verification_result
          WHERE created_by_run_id=(SELECT run_id FROM _m1_7_vctx))
      + (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot
          WHERE module1_run_id=(SELECT run_id FROM _m1_7_vctx))
      + (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot
          WHERE module1_run_id=(SELECT run_id FROM _m1_7_vctx))
      + (SELECT count(*) FROM msbf_m1.ead_path_snapshot
          WHERE module1_run_id=(SELECT run_id FROM _m1_7_vctx))
      + (SELECT count(*) FROM msbf_m1.module1_latest
          WHERE module1_run_id=(SELECT run_id FROM _m1_7_vctx))
      + (SELECT count(*) FROM msbf_m1.module1_archive
          WHERE module1_run_id=(SELECT run_id FROM _m1_7_vctx))
      AS v
) q;

INSERT INTO _m1_7_checks
SELECT 'M1_7_POS_55_BLOCKING_ERRORS','Blocking configuration errors',
       count(*)::text,'0',
       CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END,
       'No blocking configuration errors may remain.'
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
  AND severity='BLOCKING';

DELETE FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m1_7_vctx)
  AND evidence_code~'^M1_7_POS_[0-9]{2}_';

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
SELECT
    (SELECT run_id FROM _m1_7_vctx),
    code,
    'PORTFOLIO',
    name,
    observed,
    'TEXT',
    status,
    interpretation
FROM _m1_7_checks;

UPDATE msbf_ctl.run_registry
   SET run_status=CASE
       WHEN (SELECT count(*) FILTER (WHERE status='FAIL') FROM _m1_7_checks)=0
           THEN 'M1_7_VALIDATED'
       ELSE 'M1_7_FAILED'
   END,
       notes=coalesce(notes,'')
           || E'\nM1.7 positive validation: '
           || (SELECT count(*) FILTER (WHERE status='PASS') FROM _m1_7_checks)
           || '/55 PASS.'
 WHERE run_id=(SELECT run_id FROM _m1_7_vctx);

COMMIT;

SELECT
    evidence_code,
    metric_name,
    metric_value_text AS observed,
    status,
    interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
)
  AND evidence_code~'^M1_7_POS_[0-9]{2}_'
ORDER BY evidence_code;
