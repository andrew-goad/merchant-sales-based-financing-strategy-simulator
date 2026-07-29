/* ============================================================================
MSBF G1 Governed Run Readiness Validation
Version : v0.2
Purpose : Evaluate blocking G1 checks, persist run evidence, and move the run
          to G1_VALIDATED only when every positive readiness check passes.
============================================================================ */

BEGIN;

CREATE TEMP TABLE tmp_g1_checks (
    check_code text PRIMARY KEY,
    check_name text NOT NULL,
    severity text NOT NULL,
    expected_value text NOT NULL,
    observed_value text NOT NULL,
    result_status text NOT NULL,
    finding text NOT NULL
) ON COMMIT DROP;

/* 01. Run identity and pre-execution state. */
WITH ctx AS (
    SELECT * FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
)
INSERT INTO tmp_g1_checks
SELECT
    'G1_POS_01_RUN_IDENTITY',
    'Unique governed baseline run identity',
    'BLOCKING',
    '1 complete run',
    format('count=%s; run_id=%s; status=%s; population=%s; as_of=%s',
           COUNT(*), MIN(run_id), MIN(run_status), MIN(population_id), MIN(as_of_date)),
    CASE WHEN COUNT(*) = 1
              AND bool_and(module_code = 'M1')
              AND bool_and(run_type = 'BASELINE_CONFIGURATION')
              AND bool_and(population_id = 'MSBF_POP_0001')
              AND bool_and(as_of_date = DATE '2026-07-23')
              AND bool_and(code_version = 'MSBF_M1_V0_2_G1')
         THEN 'PASS' ELSE 'FAIL' END,
    'The run must resolve to one deterministic baseline identity.'
FROM ctx;

WITH ctx AS (
    SELECT * FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
)
INSERT INTO tmp_g1_checks
SELECT
    'G1_POS_02_PREEXECUTION_STATUS',
    'Pre-execution run state',
    'BLOCKING',
    'READY_FOR_G1_VALIDATION with no execution timestamps and row_count=0',
    format('status=%s; started_at=%s; completed_at=%s; row_count=%s',
           run_status, COALESCE(started_at::text,'NULL'), COALESCE(completed_at::text,'NULL'), COALESCE(row_count::text,'NULL')),
    CASE WHEN run_status IN ('READY_FOR_G1_VALIDATION','G1_VALIDATED')
              AND started_at IS NULL
              AND completed_at IS NULL
              AND COALESCE(row_count,0) = 0
         THEN 'PASS' ELSE 'FAIL' END,
    'Analytical execution must not begin before G1 acceptance.'
FROM ctx;

/* 03-06. Parameter completeness, count, and hash. */
WITH ctx AS (
    SELECT run_id, parameter_set_id, parameter_snapshot_hash
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
), obs AS (
    SELECT
        ctx.run_id,
        COUNT(*) AS snapshot_rows,
        COUNT(DISTINCT s.parameter_name) AS parameter_names,
        COUNT(*) FILTER (WHERE s.parameter_name = 'funding_to_annualized_sales_center') AS funding_center_rows,
        md5(string_agg(
            s.parameter_name || '|' || s.scope_key || '|' || s.snapshot_hash,
            '||' ORDER BY s.parameter_name, s.scope_key
        )) AS recomputed_hash,
        ctx.parameter_snapshot_hash,
        ps.parameter_set_hash,
        ps.parameter_set_code,
        ps.parameter_set_version,
        ps.status AS parameter_set_status
    FROM ctx
    JOIN msbf_ctl.run_parameter_snapshot s ON s.run_id = ctx.run_id
    JOIN msbf_ctl.parameter_set ps ON ps.parameter_set_id = ctx.parameter_set_id
    GROUP BY ctx.run_id, ctx.parameter_snapshot_hash, ps.parameter_set_hash,
             ps.parameter_set_code, ps.parameter_set_version, ps.status
)
INSERT INTO tmp_g1_checks
SELECT 'G1_POS_03_PARAMETER_SET', 'Approved complete parameter set', 'BLOCKING',
       'M1_G1_BASELINE_DEMO v1 APPROVED',
       format('%s v%s %s', parameter_set_code, parameter_set_version, parameter_set_status),
       CASE WHEN parameter_set_code='M1_G1_BASELINE_DEMO' AND parameter_set_version=1 AND parameter_set_status='APPROVED'
            THEN 'PASS' ELSE 'FAIL' END,
       'The run must use the complete G1 parameter-set version.'
FROM obs
UNION ALL
SELECT 'G1_POS_04_PARAMETER_SNAPSHOT_COUNTS', 'Parameter snapshot completeness', 'BLOCKING',
       '401 scoped rows; 155 unique names; 4 funding centers',
       format('rows=%s; names=%s; funding_centers=%s', snapshot_rows, parameter_names, funding_center_rows),
       CASE WHEN snapshot_rows=401 AND parameter_names=155 AND funding_center_rows=4 THEN 'PASS' ELSE 'FAIL' END,
       'Every required parameter must resolve, including four merchant-size funding/sales centers.'
FROM obs
UNION ALL
SELECT 'G1_POS_05_PARAMETER_HASH', 'Parameter snapshot hash reconciliation', 'BLOCKING',
       'run hash = recomputed hash = parameter-set hash',
       format('run=%s; recomputed=%s; set=%s', parameter_snapshot_hash, recomputed_hash, parameter_set_hash),
       CASE WHEN parameter_snapshot_hash IS NOT NULL
                  AND parameter_snapshot_hash = recomputed_hash
                  AND parameter_snapshot_hash = parameter_set_hash
            THEN 'PASS' ELSE 'FAIL' END,
       'The frozen parameter configuration must be exactly reproducible.'
FROM obs;

WITH ctx AS (
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), invalid AS (
    SELECT COUNT(*) AS invalid_rows
    FROM ctx
    JOIN msbf_ctl.run_parameter_snapshot s ON s.run_id=ctx.run_id
    JOIN msbf_ctl.parameter_definition pd ON pd.parameter_name=s.parameter_name
    WHERE s.source_parameter_value_id IS NULL
       OR s.snapshot_hash IS NULL
       OR s.resolved_value IS NULL
       OR pd.status <> 'ACTIVE'
)
INSERT INTO tmp_g1_checks
SELECT 'G1_POS_06_PARAMETER_LINEAGE', 'Parameter lineage and definition status', 'BLOCKING',
       '0 invalid rows', invalid_rows::text,
       CASE WHEN invalid_rows=0 THEN 'PASS' ELSE 'FAIL' END,
       'Every snapshot row must trace to one active definition and one source value.'
FROM invalid;

/* 07-09. Profile snapshot and risk appetite. */
WITH ctx AS (
    SELECT run_id, profile_snapshot_hash
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), obs AS (
    SELECT
        ctx.run_id,
        COUNT(*) AS profile_rows,
        COUNT(DISTINCT p.profile_domain) AS profile_domains,
        COUNT(*) FILTER (WHERE p.profile_domain='RISK_APPETITE_LIMIT') AS risk_limit_rows,
        COUNT(*) FILTER (WHERE p.profile_domain='FEATURE_DEFINITION_SET') AS feature_set_rows,
        md5(string_agg(
            p.profile_domain || '|' || p.profile_code || '|' ||
            p.profile_version::text || '|' || p.profile_hash,
            '||' ORDER BY p.profile_domain, p.profile_code
        )) AS recomputed_hash,
        ctx.profile_snapshot_hash
    FROM ctx
    JOIN msbf_ctl.run_profile_snapshot p ON p.run_id=ctx.run_id
    GROUP BY ctx.run_id, ctx.profile_snapshot_hash
)
INSERT INTO tmp_g1_checks
SELECT 'G1_POS_07_PROFILE_SNAPSHOT_COUNTS', 'Profile snapshot completeness', 'BLOCKING',
       '18 rows; 15 domains; 4 risk limits; 1 feature set',
       format('rows=%s; domains=%s; risk_limits=%s; feature_sets=%s', profile_rows, profile_domains, risk_limit_rows, feature_set_rows),
       CASE WHEN profile_rows=18 AND profile_domains=15 AND risk_limit_rows=4 AND feature_set_rows=1 THEN 'PASS' ELSE 'FAIL' END,
       'All required effective-dated profiles and control sets must be frozen.'
FROM obs
UNION ALL
SELECT 'G1_POS_08_PROFILE_HASH', 'Profile snapshot hash reconciliation', 'BLOCKING',
       'run hash = recomputed hash',
       format('run=%s; recomputed=%s', profile_snapshot_hash, recomputed_hash),
       CASE WHEN profile_snapshot_hash IS NOT NULL AND profile_snapshot_hash=recomputed_hash THEN 'PASS' ELSE 'FAIL' END,
       'The frozen profile configuration must be exactly reproducible.'
FROM obs
UNION ALL
SELECT 'G1_POS_09_RISK_APPETITE_LIMITS', 'Module 1 risk-appetite limit set', 'BLOCKING',
       '4 approved limits', risk_limit_rows::text,
       CASE WHEN risk_limit_rows=4 THEN 'PASS' ELSE 'FAIL' END,
       'Risk-cap, source-conflict, mixed-signal, and matched-scenario limits must be present.'
FROM obs;

/* 10-12. Source snapshot and cutoffs. */
WITH ctx AS (
    SELECT run_id, as_of_date, source_snapshot_hash
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), obs AS (
    SELECT
        ctx.run_id,
        COUNT(*) AS source_rows,
        COUNT(DISTINCT s.source_code) AS source_codes,
        COUNT(*) FILTER (WHERE s.quality_status='CONTRACT_READY_PRE_GENERATION') AS ready_rows,
        COUNT(*) FILTER (WHERE s.source_row_count=0) AS zero_row_sources,
        COUNT(*) FILTER (
            WHERE s.source_cutoff_timestamp <= (((ctx.as_of_date + 1)::timestamp AT TIME ZONE 'UTC') - interval '1 microsecond')
        ) AS valid_cutoff_rows,
        md5(string_agg(
            s.source_code || '|' ||
            to_char(s.source_cutoff_timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US') || '|' || s.source_hash || '|' ||
            s.quality_status,
            '||' ORDER BY s.source_code
        )) AS recomputed_hash,
        ctx.source_snapshot_hash
    FROM ctx
    JOIN msbf_ctl.run_source_snapshot s ON s.run_id=ctx.run_id
    GROUP BY ctx.run_id, ctx.as_of_date, ctx.source_snapshot_hash
)
INSERT INTO tmp_g1_checks
SELECT 'G1_POS_10_SOURCE_SNAPSHOT_COUNTS', 'Required source-contract snapshot', 'BLOCKING',
       '7 sources, all contract-ready and pre-generation row_count=0',
       format('rows=%s; codes=%s; ready=%s; zero_rows=%s', source_rows, source_codes, ready_rows, zero_row_sources),
       CASE WHEN source_rows=7 AND source_codes=7 AND ready_rows=7 AND zero_row_sources=7 THEN 'PASS' ELSE 'FAIL' END,
       'All seven governed source families must be frozen before generation.'
FROM obs
UNION ALL
SELECT 'G1_POS_11_SOURCE_CUTOFFS', 'Source cutoff temporal integrity', 'BLOCKING',
       '7 cutoffs no later than the as-of end-of-day', valid_cutoff_rows::text,
       CASE WHEN valid_cutoff_rows=7 THEN 'PASS' ELSE 'FAIL' END,
       'Source cutoffs may not extend beyond the application as-of date.'
FROM obs
UNION ALL
SELECT 'G1_POS_12_SOURCE_HASH', 'Source snapshot hash reconciliation', 'BLOCKING',
       'run hash = recomputed hash',
       format('run=%s; recomputed=%s', source_snapshot_hash, recomputed_hash),
       CASE WHEN source_snapshot_hash IS NOT NULL AND source_snapshot_hash=recomputed_hash THEN 'PASS' ELSE 'FAIL' END,
       'The frozen source-contract set must be exactly reproducible.'
FROM obs;

/* 13-15. Contract, feature set, and scenario family. */
WITH ctx AS (
    SELECT r.*, c.contract_code, c.contract_version, c.status AS contract_status,
           s.scenario_code, s.scenario_type, s.status AS scenario_status, s.scenario_set_id
    FROM msbf_ctl.run_registry r
    LEFT JOIN msbf_ctl.contract_registry c ON c.contract_id=r.contract_id
    LEFT JOIN msbf_ctl.scenario_registry s ON s.scenario_id=r.scenario_id
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
), feature_obs AS (
    SELECT COUNT(*) AS active_features
    FROM msbf_m1.feature_definition WHERE active_flag
), scenario_obs AS (
    SELECT COUNT(*) AS scenario_count,
           COUNT(*) FILTER (WHERE scenario_code='BASELINE') AS baseline_count,
           COUNT(*) FILTER (WHERE scenario_code='RECESSION_ENERGY') AS stress_count
    FROM msbf_ctl.scenario_registry
    WHERE scenario_set_id=(SELECT scenario_set_id FROM ctx)
      AND status='APPROVED'
)
INSERT INTO tmp_g1_checks
SELECT 'G1_POS_13_OUTPUT_CONTRACT', 'Module 1 output contract', 'BLOCKING',
       'M1_APPLICATION_RISK_SNAPSHOT v1 APPROVED',
       format('%s v%s %s', contract_code, contract_version, contract_status),
       CASE WHEN contract_code='M1_APPLICATION_RISK_SNAPSHOT' AND contract_version=1 AND contract_status='APPROVED'
            THEN 'PASS' ELSE 'FAIL' END,
       'Module 2 must receive the approved Module 1 application-risk snapshot contract.'
FROM ctx
UNION ALL
SELECT 'G1_POS_14_FEATURE_DEFINITIONS', 'Active Module 1 feature definitions', 'BLOCKING',
       '32 active definitions', active_features::text,
       CASE WHEN active_features=32 THEN 'PASS' ELSE 'FAIL' END,
       'The feature-definition inventory must match the accepted Module 1 design.'
FROM feature_obs
UNION ALL
SELECT 'G1_POS_15_SCENARIO_FAMILY', 'Matched baseline/stress scenario family', 'BLOCKING',
       '2 approved scenarios including BASELINE and RECESSION_ENERGY',
       format('total=%s; baseline=%s; stress=%s', scenario_count, baseline_count, stress_count),
       CASE WHEN scenario_count=2 AND baseline_count=1 AND stress_count=1 THEN 'PASS' ELSE 'FAIL' END,
       'The baseline run must be comparison-ready without changing the deterministic population.'
FROM scenario_obs;

/* 16-17. Population identity and history window. */
WITH ctx AS (
    SELECT r.run_id, r.population_id, r.parameter_set_id, r.as_of_date,
           p.population_version, p.parameter_set_id AS population_parameter_set_id,
           p.deterministic_seed_version, p.merchant_count,
           p.history_start_date, p.history_end_date, p.population_status,
           (p.history_end_date - p.history_start_date + 1) AS inclusive_history_days
    FROM msbf_ctl.run_registry r
    LEFT JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
)
INSERT INTO tmp_g1_checks
SELECT 'G1_POS_16_POPULATION_IDENTITY', 'Deterministic population identity', 'BLOCKING',
       'MSBF_POP_0001 v1; 750 merchants; DET_HASH_V1; same parameter set',
       format('%s v%s; merchants=%s; seed=%s; status=%s', population_id, population_version, merchant_count, deterministic_seed_version, population_status),
       CASE WHEN population_id='MSBF_POP_0001' AND population_version=1 AND merchant_count=750
                  AND deterministic_seed_version='DET_HASH_V1'
                  AND parameter_set_id=population_parameter_set_id
            THEN 'PASS' ELSE 'FAIL' END,
       'Population identity must be stable before any merchant rows are generated.'
FROM ctx
UNION ALL
SELECT 'G1_POS_17_HISTORY_WINDOW', 'As-of and history-window integrity', 'BLOCKING',
       '180 inclusive days ending on as_of_date',
       format('start=%s; end=%s; as_of=%s; days=%s', history_start_date, history_end_date, as_of_date, inclusive_history_days),
       CASE WHEN history_end_date=as_of_date AND inclusive_history_days=180 AND history_start_date<=history_end_date
            THEN 'PASS' ELSE 'FAIL' END,
       'No future observation date may enter the Module 1 underwriting window.'
FROM ctx;

/* 18. Synthetic and non-production boundaries. */
WITH ctx AS (
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), flags AS (
    SELECT
        COUNT(*) FILTER (WHERE parameter_name='synthetic_data_only_flag' AND resolved_value->>'value_boolean'='true') AS synthetic_true,
        COUNT(*) FILTER (WHERE parameter_name='real_cardholder_data_allowed_flag' AND resolved_value->>'value_boolean'='false') AS card_false,
        COUNT(*) FILTER (WHERE parameter_name='real_merchant_pii_allowed_flag' AND resolved_value->>'value_boolean'='false') AS pii_false,
        COUNT(*) FILTER (WHERE parameter_name='production_decisioning_allowed_flag' AND resolved_value->>'value_boolean'='false') AS prod_false,
        COUNT(*) FILTER (WHERE parameter_name='legal_conclusion_allowed_flag' AND resolved_value->>'value_boolean'='false') AS legal_false,
        COUNT(*) FILTER (WHERE parameter_name='regulatory_certification_allowed_flag' AND resolved_value->>'value_boolean'='false') AS reg_false,
        COUNT(*) FILTER (WHERE parameter_name='fair_lending_conclusion_allowed_flag' AND resolved_value->>'value_boolean'='false') AS fair_false,
        COUNT(*) FILTER (WHERE parameter_name='unsupported_feature_fail_closed_flag' AND resolved_value->>'value_boolean'='true') AS fail_closed_true
    FROM ctx JOIN msbf_ctl.run_parameter_snapshot s ON s.run_id=ctx.run_id
)
INSERT INTO tmp_g1_checks
SELECT 'G1_POS_18_BOUNDARY_FLAGS', 'Synthetic/non-production boundary flags', 'BLOCKING',
       '8 required boundary values',
       format('synthetic=%s; card=%s; pii=%s; production=%s; legal=%s; regulatory=%s; fair=%s; fail_closed=%s',
              synthetic_true, card_false, pii_false, prod_false, legal_false, reg_false, fair_false, fail_closed_true),
       CASE WHEN synthetic_true=1 AND card_false=1 AND pii_false=1 AND prod_false=1
                  AND legal_false=1 AND reg_false=1 AND fair_false=1 AND fail_closed_true=1
            THEN 'PASS' ELSE 'FAIL' END,
       'The public simulator must remain synthetic, non-production, and fail closed.'
FROM flags;

/* 19. No blocking resolution errors. */
WITH ctx AS (
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), obs AS (
    SELECT COUNT(*) AS blocking_errors
    FROM ctx LEFT JOIN msbf_ctl.profile_resolution_error e
      ON e.run_id=ctx.run_id AND e.severity='BLOCKING'
    WHERE e.resolution_error_id IS NOT NULL
)
INSERT INTO tmp_g1_checks
SELECT 'G1_POS_19_NO_BLOCKING_ERRORS', 'Profile/parameter/source resolution errors', 'BLOCKING',
       '0 blocking errors', blocking_errors::text,
       CASE WHEN blocking_errors=0 THEN 'PASS' ELSE 'FAIL' END,
       'Any missing, stale, ambiguous, or invalid configuration must block G1.'
FROM obs;

/* 20. Entire Module 1 analytical state remains empty. */
WITH obs AS (
    SELECT
          (SELECT COUNT(*) FROM msbf_m1.merchant_master) AS merchant_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor) AS owner_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_industry_assignment) AS industry_rows,
          (SELECT COUNT(*) FROM msbf_m1.partner_channel) AS partner_rows,
          (SELECT COUNT(*) FROM msbf_m1.processor_account) AS processor_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_relationship_snapshot) AS relationship_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_application) AS application_rows,
          (SELECT COUNT(*) FROM msbf_m1.source_snapshot) AS source_rows,
          (SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot) AS obligation_rows,
          (SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot) AS collateral_rows,
          (SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot) AS guarantee_rows,
          (SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot) AS business_credit_rows,
          (SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot) AS owner_credit_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base) AS pos_base_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario) AS pos_scenario_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base) AS deposit_base_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario) AS deposit_scenario_rows,
          (SELECT COUNT(*) FROM msbf_m1.verification_result) AS verification_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot) AS feature_snapshot_rows,
          (SELECT COUNT(*) FROM msbf_m1.feature_value) AS feature_value_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot) AS risk_rows,
          (SELECT COUNT(*) FROM msbf_m1.risk_component_detail) AS risk_component_rows,
          (SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot) AS ead_rows,
          (SELECT COUNT(*) FROM msbf_m1.module1_latest) AS latest_rows,
          (SELECT COUNT(*) FROM msbf_m1.module1_archive) AS archive_rows
), total AS (
    SELECT obs.*,
           merchant_rows + owner_rows + industry_rows + partner_rows + processor_rows + relationship_rows +
           application_rows + source_rows + obligation_rows + collateral_rows + guarantee_rows +
           business_credit_rows + owner_credit_rows + pos_base_rows + pos_scenario_rows + deposit_base_rows +
           deposit_scenario_rows + verification_rows + feature_snapshot_rows + feature_value_rows + risk_rows +
           risk_component_rows + ead_rows + latest_rows + archive_rows AS total_analytical_rows
    FROM obs
)
INSERT INTO tmp_g1_checks
SELECT 'G1_POS_20_EMPTY_ANALYTICAL_STATE', 'Empty analytical state before authorization', 'BLOCKING',
       '0 analytical rows',
       format('total=%s; merchants=%s; applications=%s; pos=%s; deposits=%s; features=%s; risk=%s; latest=%s; archive=%s',
              total_analytical_rows, merchant_rows, application_rows,
              pos_base_rows+pos_scenario_rows, deposit_base_rows+deposit_scenario_rows,
              feature_snapshot_rows+feature_value_rows, risk_rows+risk_component_rows,
              latest_rows, archive_rows),
       CASE WHEN total_analytical_rows=0 THEN 'PASS' ELSE 'FAIL' END,
       'G1 authorizes configuration only; no analytical generation may precede acceptance.'
FROM total;

/* Persist latest readiness evidence. */
WITH ctx AS (
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
)
INSERT INTO msbf_ctl.run_evidence (
    run_id, evidence_code, segment_key, metric_name,
    metric_value_text, unit_code, status, interpretation
)
SELECT
    ctx.run_id,
    c.check_code,
    'PORTFOLIO',
    c.check_name,
    c.observed_value,
    'TEXT',
    c.result_status,
    c.finding || ' Expected: ' || c.expected_value
FROM ctx
CROSS JOIN tmp_g1_checks c
ON CONFLICT (run_id, evidence_code, segment_key)
DO UPDATE SET
    metric_name = EXCLUDED.metric_name,
    metric_value_numeric = NULL,
    metric_value_text = EXCLUDED.metric_value_text,
    unit_code = EXCLUDED.unit_code,
    status = EXCLUDED.status,
    threshold_value_numeric = NULL,
    interpretation = EXCLUDED.interpretation,
    created_at = clock_timestamp();

/* Status transition: validation, not final gate acceptance. */
WITH ctx AS (
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), summary AS (
    SELECT COUNT(*) FILTER (WHERE result_status='FAIL') AS failed_checks
    FROM tmp_g1_checks
)
UPDATE msbf_ctl.run_registry r
   SET run_status = CASE WHEN summary.failed_checks=0 THEN 'G1_VALIDATED' ELSE 'G1_FAILED' END,
       notes = CASE WHEN summary.failed_checks=0
                    THEN 'G1 positive readiness checks passed; negative controls and final acceptance pending.'
                    ELSE 'G1 readiness validation failed; review G1_POS evidence and resolution errors.' END
  FROM ctx, summary
 WHERE r.run_id=ctx.run_id;

COMMIT;

SELECT
    r.run_id,
    r.run_code,
    r.run_status,
    COUNT(*) FILTER (WHERE e.evidence_code LIKE 'G1_POS_%') AS positive_check_count,
    COUNT(*) FILTER (WHERE e.evidence_code LIKE 'G1_POS_%' AND e.status='PASS') AS positive_pass_count,
    COUNT(*) FILTER (WHERE e.evidence_code LIKE 'G1_POS_%' AND e.status='FAIL') AS positive_fail_count,
    r.parameter_snapshot_hash,
    r.profile_snapshot_hash,
    r.source_snapshot_hash
FROM msbf_ctl.run_registry r
LEFT JOIN msbf_ctl.run_evidence e ON e.run_id=r.run_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
GROUP BY r.run_id, r.run_code, r.run_status,
         r.parameter_snapshot_hash, r.profile_snapshot_hash, r.source_snapshot_hash;

SELECT
    evidence_code,
    metric_name,
    status,
    metric_value_text,
    interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
)
  AND evidence_code LIKE 'G1_POS_%'
ORDER BY evidence_code;
