/* ============================================================================
M1.13 v0.2R1 BOOLEAN-PARAMETER AGGREGATION HOTFIX
Source  : 95_msbf_m1_13_exposure_recovery_loss_validation_v0_2.sql
Role    : Positive validation; executable logic unchanged from v0.2.
Revision: File name is version-aligned to v0.2R1. Except where explicitly
          documented in HOTFIX_NOTES_v0_2R1.md, executable logic is unchanged.
============================================================================ */

/* ============================================================================
MSBF M1.13 Exposure, Recovery & Expected Loss Foundations — Positive Validation
Version : v0.2
Purpose : Validate accepted lineage, daily EAD paths, recovery/LGD foundations,
          comparative loss identities, matched stress behavior, deterministic
          hashes, governance evidence, and downstream boundaries.
Mode    : Read persisted M1.13 rows; write 82 governed positive-control results.
Output  : One 82-row filterable DBeaver result set.
Required: 82 / 82 PASS and run_status = M1_13_VALIDATED.
============================================================================ */

BEGIN;
SET LOCAL work_mem = '128MB';
SET LOCAL jit = off;
SET LOCAL statement_timeout = '20min';

/* ---------------------------------------------------------------------------
1. Materialize persisted validation inputs once
--------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m1_13_vctx;
DROP TABLE IF EXISTS _m1_13_vgates;
DROP TABLE IF EXISTS _m1_13_vpolicy;
DROP TABLE IF EXISTS _m1_13_vparams;
DROP TABLE IF EXISTS _m1_13_vscope;
DROP TABLE IF EXISTS _m1_13_vhash_lineage;
DROP TABLE IF EXISTS _m1_13_vloss;
DROP TABLE IF EXISTS _m1_13_vpath;
DROP TABLE IF EXISTS _m1_13_vactual;
DROP TABLE IF EXISTS _m1_13_vhashes;
DROP TABLE IF EXISTS _m1_13_vboundary;
DROP TABLE IF EXISTS _m1_13_validation;

CREATE TEMP TABLE _m1_13_vctx ON COMMIT DROP AS
SELECT
    run_id, run_status, population_id, as_of_date,
    parameter_snapshot_hash, profile_snapshot_hash, source_snapshot_hash
FROM msbf_ctl.run_registry
WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
  AND run_version = 1;

CREATE TEMP TABLE _m1_13_vgates ON COMMIT DROP AS
SELECT DISTINCT ON (gate_id)
    gate_id, result_status, review_version
FROM msbf_ctl.acceptance_gate_result
WHERE run_id = (SELECT run_id FROM _m1_13_vctx)
ORDER BY gate_id, review_version DESC;
CREATE UNIQUE INDEX ON _m1_13_vgates(gate_id);

CREATE TEMP TABLE _m1_13_vpolicy ON COMMIT DROP AS
SELECT status, profile_payload
FROM msbf_ctl.policy_profile
WHERE profile_code = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
  AND profile_version = 1;

CREATE TEMP TABLE _m1_13_vparams ON COMMIT DROP AS
SELECT
    count(*) FILTER (WHERE parameter_name='default_timing_weight' AND scope_key LIKE 'PATH_DAY_BUCKET:%') AS timing_rows,
    count(*) FILTER (WHERE parameter_name='paydown_curve_shape' AND scope_key LIKE 'EXPECTED_PAYOFF_DAYS:%') AS paydown_rows,
    count(*) FILTER (WHERE parameter_name='industry_lgd_baseline' AND scope_key LIKE 'INDUSTRY:%') AS industry_rows,
    count(*) FILTER (WHERE parameter_name IN ('collateral_availability_lgd_haircut','guarantee_availability_lgd_haircut','lgd_floor','lgd_cap','expected_loss_tolerance_amount','ead_weight_tolerance','simple_el_publish_flag','schedule_adjusted_el_publish_flag') AND scope_key='GLOBAL') AS global_rows,
    sum((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='default_timing_weight' AND scope_key LIKE 'PATH_DAY_BUCKET:%') AS timing_weight_sum,
    max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='lgd_floor' AND scope_key='GLOBAL') AS lgd_floor,
    max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='lgd_cap' AND scope_key='GLOBAL') AS lgd_cap,
    max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='expected_loss_tolerance_amount' AND scope_key='GLOBAL') AS loss_tolerance,
    max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='ead_weight_tolerance' AND scope_key='GLOBAL') AS ead_weight_tolerance
FROM msbf_ctl.run_parameter_snapshot
WHERE run_id = (SELECT run_id FROM _m1_13_vctx);

CREATE TEMP TABLE _m1_13_vscope ON COMMIT DROP AS
SELECT
    count(DISTINCT l.scenario_id) AS scenario_count,
    count(DISTINCT l.scenario_id) FILTER (WHERE sr.scenario_code='BASELINE') AS baseline_count,
    count(DISTINCT l.scenario_id) FILTER (WHERE sr.scenario_code='RECESSION_ENERGY') AS stress_count,
    (SELECT sum(requested_expected_payoff_days+1)::bigint*2 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM _m1_13_vctx)) AS expected_path_rows
FROM msbf_m1.application_exposure_recovery_loss_snapshot l
JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
WHERE l.module1_run_id = (SELECT run_id FROM _m1_13_vctx);

CREATE TEMP TABLE _m1_13_vhash_lineage ON COMMIT DROP AS
SELECT
    (SELECT population_hash FROM msbf_m1.population_registry WHERE population_id=(SELECT population_id FROM _m1_13_vctx)) AS population_hash,
    (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_13_vctx) AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') AS application_hash,
    (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_13_vctx) AND evidence_code='M1_6_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS scenario_hash,
    (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_13_vctx) AND evidence_code='M1_10_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS capacity_hash,
    (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_13_vctx) AND evidence_code='M1_12_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS integrated_risk_hash;

CREATE TEMP TABLE _m1_13_vloss ON COMMIT DROP AS
SELECT *
FROM msbf_m1.application_exposure_recovery_loss_snapshot
WHERE module1_run_id = (SELECT run_id FROM _m1_13_vctx);
CREATE UNIQUE INDEX ON _m1_13_vloss(scenario_id, merchant_application_id);
CREATE INDEX ON _m1_13_vloss(merchant_application_id, scenario_id);
ANALYZE _m1_13_vloss;

CREATE TEMP TABLE _m1_13_vpath ON COMMIT DROP AS
SELECT *
FROM msbf_m1.application_ead_path_value
WHERE module1_run_id = (SELECT run_id FROM _m1_13_vctx);
CREATE UNIQUE INDEX ON _m1_13_vpath(scenario_id, merchant_application_id, path_day);
CREATE INDEX ON _m1_13_vpath(merchant_application_id, scenario_id, path_day);
ANALYZE _m1_13_vpath;

CREATE TEMP TABLE _m1_13_vactual ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_13_actual_path_snapshot((SELECT run_id FROM _m1_13_vctx))
UNION ALL
SELECT * FROM msbf_m1.m1_13_actual_loss_snapshot((SELECT run_id FROM _m1_13_vctx));
CREATE UNIQUE INDEX ON _m1_13_vactual(entity_key);

CREATE TEMP TABLE _m1_13_vhashes ON COMMIT DROP AS
SELECT
    (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM _m1_13_vactual WHERE entity_key LIKE 'PATH|%') AS path_hash,
    (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM _m1_13_vactual WHERE entity_key LIKE 'LOSS|%') AS snapshot_hash,
    (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM _m1_13_vactual) AS combined_hash,
    (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_13_vctx) AND evidence_code='M1_13_PATH_SET_HASH' AND segment_key='PORTFOLIO') AS stored_path_hash,
    (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_13_vctx) AND evidence_code='M1_13_SNAPSHOT_SET_HASH' AND segment_key='PORTFOLIO') AS stored_snapshot_hash,
    (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_13_vctx) AND evidence_code='M1_13_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS stored_combined_hash;

CREATE TEMP TABLE _m1_13_vboundary ON COMMIT DROP AS
SELECT
    (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_13_vctx))
  + (SELECT count(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM _m1_13_vctx))
  + (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_13_vctx))
  + (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM _m1_13_vctx))
  + (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM _m1_13_vctx)) AS downstream_rows,
    (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_13_vctx) AND severity='BLOCKING') AS blocking_errors;

/* ---------------------------------------------------------------------------
2. Filterable validation result table and helper
--------------------------------------------------------------------------- */
CREATE TEMP TABLE _m1_13_validation (
    evidence_code text PRIMARY KEY,
    metric_name text NOT NULL,
    observed_value text,
    threshold_value text,
    status text NOT NULL,
    interpretation text
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m1_13_add_check(
    p_code text,
    p_name text,
    p_observed text,
    p_threshold text,
    p_passed boolean,
    p_interpretation text
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO _m1_13_validation(
        evidence_code, metric_name, observed_value,
        threshold_value, status, interpretation
    )
    VALUES (
        p_code, p_name, p_observed, p_threshold,
        CASE WHEN p_passed THEN 'PASS' ELSE 'FAIL' END,
        p_interpretation
    );
END;
$$;

/* ---------------------------------------------------------------------------
3. Execute the complete positive-control inventory
--------------------------------------------------------------------------- */
DO $checks$
BEGIN
    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_01_RUN_STATUS',
        'Run status',
        coalesce(((SELECT run_status FROM _m1_13_vctx))::text, 'NULL'),
        'M1_13_GENERATED',
        coalesce(((SELECT run_status='M1_13_GENERATED' FROM _m1_13_vctx))::boolean, false),
        'Positive validation begins only from the committed M1.13 generated state.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_02_G1_CONTROL_PLANE',
        'G1_CONTROL_PLANE acceptance gate',
        coalesce((coalesce((SELECT result_status FROM _m1_13_vgates WHERE gate_id='G1_CONTROL_PLANE'),'MISSING'))::text, 'NULL'),
        'PASS',
        coalesce((coalesce((SELECT result_status='PASS' FROM _m1_13_vgates WHERE gate_id='G1_CONTROL_PLANE'),false))::boolean, false),
        'The accepted predecessor gate G1_CONTROL_PLANE remains PASS.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_03_M1_2_POPULATION',
        'M1_2_POPULATION acceptance gate',
        coalesce((coalesce((SELECT result_status FROM _m1_13_vgates WHERE gate_id='M1_2_POPULATION'),'MISSING'))::text, 'NULL'),
        'PASS',
        coalesce((coalesce((SELECT result_status='PASS' FROM _m1_13_vgates WHERE gate_id='M1_2_POPULATION'),false))::boolean, false),
        'The accepted predecessor gate M1_2_POPULATION remains PASS.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_04_M1_3_APPLICATION_REQUEST',
        'M1_3_APPLICATION_REQUEST acceptance gate',
        coalesce((coalesce((SELECT result_status FROM _m1_13_vgates WHERE gate_id='M1_3_APPLICATION_REQUEST'),'MISSING'))::text, 'NULL'),
        'PASS',
        coalesce((coalesce((SELECT result_status='PASS' FROM _m1_13_vgates WHERE gate_id='M1_3_APPLICATION_REQUEST'),false))::boolean, false),
        'The accepted predecessor gate M1_3_APPLICATION_REQUEST remains PASS.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_05_M1_4_DAILY_POS_HISTORY',
        'M1_4_DAILY_POS_HISTORY acceptance gate',
        coalesce((coalesce((SELECT result_status FROM _m1_13_vgates WHERE gate_id='M1_4_DAILY_POS_HISTORY'),'MISSING'))::text, 'NULL'),
        'PASS',
        coalesce((coalesce((SELECT result_status='PASS' FROM _m1_13_vgates WHERE gate_id='M1_4_DAILY_POS_HISTORY'),false))::boolean, false),
        'The accepted predecessor gate M1_4_DAILY_POS_HISTORY remains PASS.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_06_M1_5_DAILY_DEPOSIT_LIQUIDITY',
        'M1_5_DAILY_DEPOSIT_LIQUIDITY acceptance gate',
        coalesce((coalesce((SELECT result_status FROM _m1_13_vgates WHERE gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY'),'MISSING'))::text, 'NULL'),
        'PASS',
        coalesce((coalesce((SELECT result_status='PASS' FROM _m1_13_vgates WHERE gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY'),false))::boolean, false),
        'The accepted predecessor gate M1_5_DAILY_DEPOSIT_LIQUIDITY remains PASS.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_07_M1_6_MATCHED_SCENARIO_OVERLAYS',
        'M1_6_MATCHED_SCENARIO_OVERLAYS acceptance gate',
        coalesce((coalesce((SELECT result_status FROM _m1_13_vgates WHERE gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS'),'MISSING'))::text, 'NULL'),
        'PASS',
        coalesce((coalesce((SELECT result_status='PASS' FROM _m1_13_vgates WHERE gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS'),false))::boolean, false),
        'The accepted predecessor gate M1_6_MATCHED_SCENARIO_OVERLAYS remains PASS.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_08_M1_7_SOURCE_QUALITY_CONFIDENCE',
        'M1_7_SOURCE_QUALITY_CONFIDENCE acceptance gate',
        coalesce((coalesce((SELECT result_status FROM _m1_13_vgates WHERE gate_id='M1_7_SOURCE_QUALITY_CONFIDENCE'),'MISSING'))::text, 'NULL'),
        'PASS',
        coalesce((coalesce((SELECT result_status='PASS' FROM _m1_13_vgates WHERE gate_id='M1_7_SOURCE_QUALITY_CONFIDENCE'),false))::boolean, false),
        'The accepted predecessor gate M1_7_SOURCE_QUALITY_CONFIDENCE remains PASS.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_09_M1_8_VERIFICATION_FRAUD_CONTINUITY',
        'M1_8_VERIFICATION_FRAUD_CONTINUITY acceptance gate',
        coalesce((coalesce((SELECT result_status FROM _m1_13_vgates WHERE gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY'),'MISSING'))::text, 'NULL'),
        'PASS',
        coalesce((coalesce((SELECT result_status='PASS' FROM _m1_13_vgates WHERE gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY'),false))::boolean, false),
        'The accepted predecessor gate M1_8_VERIFICATION_FRAUD_CONTINUITY remains PASS.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_10_M1_9_ASOF_CASHFLOW_FEATURES',
        'M1_9_ASOF_CASHFLOW_FEATURES acceptance gate',
        coalesce((coalesce((SELECT result_status FROM _m1_13_vgates WHERE gate_id='M1_9_ASOF_CASHFLOW_FEATURES'),'MISSING'))::text, 'NULL'),
        'PASS',
        coalesce((coalesce((SELECT result_status='PASS' FROM _m1_13_vgates WHERE gate_id='M1_9_ASOF_CASHFLOW_FEATURES'),false))::boolean, false),
        'The accepted predecessor gate M1_9_ASOF_CASHFLOW_FEATURES remains PASS.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_11_M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY',
        'M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY acceptance gate',
        coalesce((coalesce((SELECT result_status FROM _m1_13_vgates WHERE gate_id='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY'),'MISSING'))::text, 'NULL'),
        'PASS',
        coalesce((coalesce((SELECT result_status='PASS' FROM _m1_13_vgates WHERE gate_id='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY'),false))::boolean, false),
        'The accepted predecessor gate M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY remains PASS.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_12_M1_11_CASHFLOW_ARCHETYPE_RESILIENCE',
        'M1_11_CASHFLOW_ARCHETYPE_RESILIENCE acceptance gate',
        coalesce((coalesce((SELECT result_status FROM _m1_13_vgates WHERE gate_id='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE'),'MISSING'))::text, 'NULL'),
        'PASS',
        coalesce((coalesce((SELECT result_status='PASS' FROM _m1_13_vgates WHERE gate_id='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE'),false))::boolean, false),
        'The accepted predecessor gate M1_11_CASHFLOW_ARCHETYPE_RESILIENCE remains PASS.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_13_M1_12_INTEGRATED_RISK_PROXY',
        'M1_12_INTEGRATED_RISK_PROXY acceptance gate',
        coalesce((coalesce((SELECT result_status FROM _m1_13_vgates WHERE gate_id='M1_12_INTEGRATED_RISK_PROXY'),'MISSING'))::text, 'NULL'),
        'PASS',
        coalesce((coalesce((SELECT result_status='PASS' FROM _m1_13_vgates WHERE gate_id='M1_12_INTEGRATED_RISK_PROXY'),false))::boolean, false),
        'The accepted predecessor gate M1_12_INTEGRATED_RISK_PROXY remains PASS.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_14_PARAMETER_HASH',
        'Parameter Hash',
        coalesce(((SELECT parameter_snapshot_hash FROM _m1_13_vctx))::text, 'NULL'),
        'bd09e598c82db96e47459d77fd11e7c8',
        coalesce(((SELECT parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8' FROM _m1_13_vctx))::boolean, false),
        'The accepted governed run identity remains unchanged.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_15_PROFILE_HASH',
        'Profile Hash',
        coalesce(((SELECT profile_snapshot_hash FROM _m1_13_vctx))::text, 'NULL'),
        '462cbd2ed92f68e5bdecf6b17537a973',
        coalesce(((SELECT profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973' FROM _m1_13_vctx))::boolean, false),
        'The accepted governed run identity remains unchanged.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_16_SOURCE_HASH',
        'Source Hash',
        coalesce(((SELECT source_snapshot_hash FROM _m1_13_vctx))::text, 'NULL'),
        '93c3d1368fb2450ab4a08e2b721f92d3',
        coalesce(((SELECT source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3' FROM _m1_13_vctx))::boolean, false),
        'The accepted governed run identity remains unchanged.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_17_POPULATION_HASH',
        'Population hash',
        coalesce(((SELECT population_hash FROM _m1_13_vhash_lineage))::text, 'NULL'),
        '9b706c926260a3ef1ae8ac95eed5d0bf',
        coalesce(((SELECT population_hash='9b706c926260a3ef1ae8ac95eed5d0bf' FROM _m1_13_vhash_lineage))::boolean, false),
        'The accepted M1.2 population identity remains unchanged.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_18_APPLICATION_HASH',
        'Application set hash',
        coalesce(((SELECT application_hash FROM _m1_13_vhash_lineage))::text, 'NULL'),
        '01485256b9b5748fb412743d35ced602',
        coalesce(((SELECT application_hash='01485256b9b5748fb412743d35ced602' FROM _m1_13_vhash_lineage))::boolean, false),
        'The accepted M1.3 application population remains unchanged.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_19_SCENARIO_SET_HASH',
        'Scenario set hash',
        coalesce(((SELECT scenario_hash FROM _m1_13_vhash_lineage))::text, 'NULL'),
        '3f85921bf6fc30ddc6cee146085e58c5',
        coalesce(((SELECT scenario_hash='3f85921bf6fc30ddc6cee146085e58c5' FROM _m1_13_vhash_lineage))::boolean, false),
        'The accepted M1.6 matched scenario population remains unchanged.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_20_CAPACITY_SET_HASH',
        'Capacity set hash',
        coalesce(((SELECT capacity_hash FROM _m1_13_vhash_lineage))::text, 'NULL'),
        'a91e82a315305a98953d013043a17d9a',
        coalesce(((SELECT capacity_hash='a91e82a315305a98953d013043a17d9a' FROM _m1_13_vhash_lineage))::boolean, false),
        'The accepted M1.10 capacity evidence remains unchanged.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_21_INTEGRATED_RISK_SET_HASH',
        'Integrated risk set hash',
        coalesce(((SELECT integrated_risk_hash FROM _m1_13_vhash_lineage))::text, 'NULL'),
        'fb583c3fdd92f141ba5af1ddf942ffba',
        coalesce(((SELECT integrated_risk_hash='fb583c3fdd92f141ba5af1ddf942ffba' FROM _m1_13_vhash_lineage))::boolean, false),
        'The accepted M1.12 integrated-risk evidence remains unchanged.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_22_POLICY_APPROVED',
        'Policy approved',
        coalesce(((SELECT status FROM _m1_13_vpolicy))::text, 'NULL'),
        'APPROVED',
        coalesce(((SELECT status='APPROVED' FROM _m1_13_vpolicy))::boolean, false),
        'M1.13 uses an approved governed policy profile.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_23_METHODOLOGY_VERSION',
        'Methodology version',
        coalesce(((SELECT profile_payload->>'methodology_version' FROM _m1_13_vpolicy))::text, 'NULL'),
        'M1_13_METHOD_V1',
        coalesce(((SELECT profile_payload->>'methodology_version'='M1_13_METHOD_V1' FROM _m1_13_vpolicy))::boolean, false),
        'The accepted M1.13 methodology version is explicit.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_24_METHOD_BASIS',
        'Exposure and EAD basis',
        coalesce(((SELECT concat_ws('|',profile_payload->>'exposure_basis_code',profile_payload->>'ead_method_code',profile_payload->>'default_timing_basis_code') FROM _m1_13_vpolicy))::text, 'NULL'),
        'CONTRACTUAL_RECEIVABLE|WEIGHTED_DAILY_BALANCE|EARLY_MIDDLE_LATE',
        coalesce(((SELECT profile_payload->>'exposure_basis_code'='CONTRACTUAL_RECEIVABLE' AND profile_payload->>'ead_method_code'='WEIGHTED_DAILY_BALANCE' AND profile_payload->>'default_timing_basis_code'='EARLY_MIDDLE_LATE' FROM _m1_13_vpolicy))::boolean, false),
        'Exposure, EAD, and default-timing bases match the governed design.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_25_STRESS_FLOORS_ENABLED',
        'Stress non-improvement controls',
        coalesce(((SELECT concat_ws('|',profile_payload->>'stress_payment_cap_to_baseline',profile_payload->>'stress_ead_floor_to_baseline',profile_payload->>'stress_lgd_floor_to_baseline',profile_payload->>'stress_loss_floor_to_baseline') FROM _m1_13_vpolicy))::text, 'NULL'),
        'true|true|true|true',
        coalesce(((SELECT (profile_payload->>'stress_payment_cap_to_baseline')::boolean AND (profile_payload->>'stress_ead_floor_to_baseline')::boolean AND (profile_payload->>'stress_lgd_floor_to_baseline')::boolean AND (profile_payload->>'stress_loss_floor_to_baseline')::boolean FROM _m1_13_vpolicy))::boolean, false),
        'Adverse scenarios cannot improve payment pace, EAD, LGD, or comparative loss interpretation.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_26_PARAMETER_INVENTORY',
        'Frozen parameter inventory',
        coalesce(((SELECT format('timing=%s|shape=%s|industry=%s|global=%s',timing_rows,paydown_rows,industry_rows,global_rows) FROM _m1_13_vparams))::text, 'NULL'),
        'timing=3|shape=3|industry=8|global=8',
        coalesce(((SELECT timing_rows=3 AND paydown_rows=3 AND industry_rows=8 AND global_rows=8 FROM _m1_13_vparams))::boolean, false),
        'All required frozen exposure, timing, LGD, and publication parameters are present.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_27_TIMING_WEIGHT_SUM',
        'Default timing weight sum',
        coalesce(((SELECT timing_weight_sum::text FROM _m1_13_vparams))::text, 'NULL'),
        '1.000000',
        coalesce(((SELECT abs(timing_weight_sum-1.0)<=0.000001 FROM _m1_13_vparams))::boolean, false),
        'The governed early/middle/late timing weights sum to one.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_28_LGD_BOUND_ORDER',
        'LGD floor and cap order',
        coalesce(((SELECT format('floor=%s|cap=%s',lgd_floor,lgd_cap) FROM _m1_13_vparams))::text, 'NULL'),
        '0 <= floor < cap <= 1',
        coalesce(((SELECT lgd_floor>=0 AND lgd_cap<=1 AND lgd_floor<lgd_cap FROM _m1_13_vparams))::boolean, false),
        'The frozen LGD bounds are valid and monotonic.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_29_SCENARIO_SCOPE',
        'Matched scenario scope',
        coalesce(((SELECT format('scenarios=%s|baseline=%s|stress=%s',scenario_count,baseline_count,stress_count) FROM _m1_13_vscope))::text, 'NULL'),
        'scenarios=2|baseline=1|stress=1',
        coalesce(((SELECT scenario_count=2 AND baseline_count=1 AND stress_count=1 FROM _m1_13_vscope))::boolean, false),
        'Exactly one accepted baseline and one accepted recession/energy scenario are represented.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_30_SNAPSHOT_COUNT',
        'Loss snapshot row count',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss))::text, 'NULL'),
        '1500',
        coalesce(((SELECT count(*)=1500 FROM _m1_13_vloss))::boolean, false),
        'Every accepted application is represented under both matched scenarios.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_31_PATH_COUNT',
        'Daily EAD path row count',
        coalesce(((SELECT count(*)::text FROM _m1_13_vpath))::text, 'NULL'),
        coalesce(((SELECT expected_path_rows::text FROM _m1_13_vscope))::text, 'NULL'),
        coalesce(((SELECT (SELECT count(*) FROM _m1_13_vpath)=expected_path_rows FROM _m1_13_vscope))::boolean, false),
        'The path contains every governed day from zero through expected payoff for both scenarios.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_32_APPLICATION_COUNT',
        'Application count',
        coalesce(((SELECT count(DISTINCT merchant_application_id)::text FROM _m1_13_vloss))::text, 'NULL'),
        '750',
        coalesce(((SELECT count(DISTINCT merchant_application_id)=750 FROM _m1_13_vloss))::boolean, false),
        'The complete accepted application population is represented.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_33_SCENARIO_COUNT',
        'Scenario count',
        coalesce(((SELECT count(DISTINCT scenario_id)::text FROM _m1_13_vloss))::text, 'NULL'),
        '2',
        coalesce(((SELECT count(DISTINCT scenario_id)=2 FROM _m1_13_vloss))::boolean, false),
        'Two matched scenarios are represented.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_34_UNIQUE_SNAPSHOT_GRAIN',
        'Unique loss snapshot grain',
        coalesce(((SELECT count(*)-count(DISTINCT (scenario_id,merchant_application_id)) FROM _m1_13_vloss)::text)::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT (scenario_id,merchant_application_id)) FROM _m1_13_vloss))::boolean, false),
        'The scenario/application snapshot grain is unique.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_35_UNIQUE_PATH_GRAIN',
        'Unique daily path grain',
        coalesce(((SELECT count(*)-count(DISTINCT (scenario_id,merchant_application_id,path_day)) FROM _m1_13_vpath)::text)::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT (scenario_id,merchant_application_id,path_day)) FROM _m1_13_vpath))::boolean, false),
        'The scenario/application/day path grain is unique.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_36_COMPLETE_PATH_COVERAGE',
        'Complete path coverage',
        coalesce(((SELECT count(*)::text FROM (SELECT p.scenario_id,p.merchant_application_id,count(*) n,max(p.path_day) max_day,l.requested_expected_payoff_days payoff FROM _m1_13_vpath p JOIN _m1_13_vloss l USING(scenario_id,merchant_application_id) GROUP BY p.scenario_id,p.merchant_application_id,l.requested_expected_payoff_days HAVING count(*)<>l.requested_expected_payoff_days+1 OR max(p.path_day)<>l.requested_expected_payoff_days) q))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM (SELECT p.scenario_id,p.merchant_application_id,count(*) n,max(p.path_day) max_day,l.requested_expected_payoff_days payoff FROM _m1_13_vpath p JOIN _m1_13_vloss l USING(scenario_id,merchant_application_id) GROUP BY p.scenario_id,p.merchant_application_id,l.requested_expected_payoff_days HAVING count(*)<>l.requested_expected_payoff_days+1 OR max(p.path_day)<>l.requested_expected_payoff_days) q))::boolean, false),
        'Each path begins at day zero and ends at the governed payoff horizon.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_37_PATH_DAY_RANGE',
        'Path-day range',
        coalesce(((SELECT format('min=%s|max=%s',min(path_day),max(path_day)) FROM _m1_13_vpath))::text, 'NULL'),
        'min=0|max=90',
        coalesce(((SELECT min(path_day)=0 AND max(path_day)=90 FROM _m1_13_vpath))::boolean, false),
        'Path days remain within the governed 30/60/90-day structure range.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_38_PATH_BUCKET_DOMAIN',
        'Path bucket domain and counts',
        coalesce(((SELECT count(*)::text FROM _m1_13_vpath WHERE path_bucket NOT IN ('EARLY','MIDDLE','LATE') OR path_bucket_day_count<=0))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vpath WHERE path_bucket NOT IN ('EARLY','MIDDLE','LATE') OR path_bucket_day_count<=0))::boolean, false),
        'Every path day has a valid timing bucket and positive bucket-day count.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_39_TIMING_WEIGHT_IDENTITY',
        'Per-path timing weight identity',
        coalesce(((SELECT count(*)::text FROM (SELECT scenario_id,merchant_application_id FROM _m1_13_vpath GROUP BY scenario_id,merchant_application_id HAVING abs(sum(default_timing_weight)-1.0)>(SELECT ead_weight_tolerance FROM _m1_13_vparams)) q))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM (SELECT scenario_id,merchant_application_id FROM _m1_13_vpath GROUP BY scenario_id,merchant_application_id HAVING abs(sum(default_timing_weight)-1.0)>(SELECT ead_weight_tolerance FROM _m1_13_vparams)) q))::boolean, false),
        'Default timing weights sum to one for every application and scenario.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_40_TIMING_WEIGHT_BOUNDS',
        'Timing weight bounds',
        coalesce(((SELECT count(*)::text FROM _m1_13_vpath WHERE default_timing_weight<0 OR default_timing_weight>1))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vpath WHERE default_timing_weight<0 OR default_timing_weight>1))::boolean, false),
        'Every path-day timing weight is bounded from zero through one.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_41_PATH_AMOUNT_BOUNDS',
        'Path amount bounds',
        coalesce(((SELECT count(*)::text FROM _m1_13_vpath WHERE beginning_exposure_amount<0 OR scheduled_remittance_amount<0 OR expected_receivable_reduction_amount<0 OR ending_exposure_amount<0 OR weighted_ead_amount<0))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vpath WHERE beginning_exposure_amount<0 OR scheduled_remittance_amount<0 OR expected_receivable_reduction_amount<0 OR ending_exposure_amount<0 OR weighted_ead_amount<0))::boolean, false),
        'All daily exposure-path values are nonnegative.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_42_EXPOSURE_MONOTONICITY',
        'Exposure-path monotonicity',
        coalesce(((SELECT count(*)::text FROM (SELECT *,lag(ending_exposure_amount) OVER(PARTITION BY scenario_id,merchant_application_id ORDER BY path_day) prev_end FROM _m1_13_vpath) q WHERE prev_end IS NOT NULL AND ending_exposure_amount>prev_end))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM (SELECT *,lag(ending_exposure_amount) OVER(PARTITION BY scenario_id,merchant_application_id ORDER BY path_day) prev_end FROM _m1_13_vpath) q WHERE prev_end IS NOT NULL AND ending_exposure_amount>prev_end))::boolean, false),
        'Expected contractual-receivable exposure never increases across the daily path.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_43_DAY_ZERO_EXPOSURE_IDENTITY',
        'Day-zero exposure identity',
        coalesce(((SELECT count(*)::text FROM _m1_13_vpath p JOIN _m1_13_vloss l USING(scenario_id,merchant_application_id) WHERE p.path_day=0 AND (p.beginning_exposure_amount<>l.initial_receivable_exposure_amount OR p.ending_exposure_amount<>l.initial_receivable_exposure_amount)))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vpath p JOIN _m1_13_vloss l USING(scenario_id,merchant_application_id) WHERE p.path_day=0 AND (p.beginning_exposure_amount<>l.initial_receivable_exposure_amount OR p.ending_exposure_amount<>l.initial_receivable_exposure_amount)))::boolean, false),
        'Day zero equals the contractual receivable before any scheduled remittance.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_44_SCHEDULED_PAYMENT_IDENTITY',
        'Scheduled remittance identity',
        coalesce(((SELECT count(*)::text FROM _m1_13_vpath p JOIN _m1_13_vloss l USING(scenario_id,merchant_application_id) WHERE p.scheduled_remittance_amount IS DISTINCT FROM CASE WHEN p.path_day=0 THEN 0::numeric ELSE least(l.governed_path_daily_payment,p.beginning_exposure_amount)::numeric(18,2) END))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vpath p JOIN _m1_13_vloss l USING(scenario_id,merchant_application_id) WHERE p.scheduled_remittance_amount IS DISTINCT FROM CASE WHEN p.path_day=0 THEN 0::numeric ELSE least(l.governed_path_daily_payment,p.beginning_exposure_amount)::numeric(18,2) END))::boolean, false),
        'Scheduled remittance follows the governed scenario/baseline payment basis.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_45_RECEIVABLE_REDUCTION_IDENTITY',
        'Receivable reduction identity',
        coalesce(((SELECT count(*)::text FROM _m1_13_vpath WHERE expected_receivable_reduction_amount IS DISTINCT FROM greatest(beginning_exposure_amount-ending_exposure_amount,0)::numeric(18,2)))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vpath WHERE expected_receivable_reduction_amount IS DISTINCT FROM greatest(beginning_exposure_amount-ending_exposure_amount,0)::numeric(18,2)))::boolean, false),
        'Expected receivable reduction reconciles to beginning less ending exposure.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_46_FINAL_EXPOSURE_ZERO',
        'Final exposure exhaustion',
        coalesce(((SELECT count(*)::text FROM _m1_13_vpath p JOIN _m1_13_vloss l USING(scenario_id,merchant_application_id) WHERE p.path_day=l.requested_expected_payoff_days AND p.ending_exposure_amount<>0))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vpath p JOIN _m1_13_vloss l USING(scenario_id,merchant_application_id) WHERE p.path_day=l.requested_expected_payoff_days AND p.ending_exposure_amount<>0))::boolean, false),
        'The governed path reaches zero exposure by the requested payoff horizon.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_47_PATH_ROW_HASH',
        'Path row-hash reconstruction',
        coalesce(((SELECT count(*)::text FROM msbf_m1.application_ead_path_value p WHERE p.module1_run_id=(SELECT run_id FROM _m1_13_vctx) AND p.path_hash<>msbf_m1.m1_13_hash_jsonb(to_jsonb(p)-'path_hash'-'created_at')))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m1.application_ead_path_value p WHERE p.module1_run_id=(SELECT run_id FROM _m1_13_vctx) AND p.path_hash<>msbf_m1.m1_13_hash_jsonb(to_jsonb(p)-'path_hash'-'created_at')))::boolean, false),
        'Every persisted path row hash independently reconstructs from physical fields.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_48_PATH_SET_HASH',
        'Path set-hash reconstruction',
        coalesce(((SELECT path_hash FROM _m1_13_vhashes))::text, 'NULL'),
        coalesce(((SELECT stored_path_hash FROM _m1_13_vhashes))::text, 'NULL'),
        coalesce(((SELECT path_hash=stored_path_hash FROM _m1_13_vhashes))::boolean, false),
        'The independently reconstructed path-set hash matches governed generation evidence.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_49_SNAPSHOT_ROW_HASH',
        'Loss snapshot row-hash reconstruction',
        coalesce(((SELECT count(*)::text FROM msbf_m1.application_exposure_recovery_loss_snapshot s WHERE s.module1_run_id=(SELECT run_id FROM _m1_13_vctx) AND s.row_hash<>msbf_m1.m1_13_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m1.application_exposure_recovery_loss_snapshot s WHERE s.module1_run_id=(SELECT run_id FROM _m1_13_vctx) AND s.row_hash<>msbf_m1.m1_13_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')))::boolean, false),
        'Every persisted loss snapshot hash independently reconstructs from physical fields.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_50_SNAPSHOT_SET_HASH',
        'Loss snapshot set-hash reconstruction',
        coalesce(((SELECT snapshot_hash FROM _m1_13_vhashes))::text, 'NULL'),
        coalesce(((SELECT stored_snapshot_hash FROM _m1_13_vhashes))::text, 'NULL'),
        coalesce(((SELECT snapshot_hash=stored_snapshot_hash FROM _m1_13_vhashes))::boolean, false),
        'The independently reconstructed loss-snapshot set hash matches governed evidence.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_51_COMBINED_SET_HASH',
        'Combined set-hash reconstruction',
        coalesce(((SELECT combined_hash FROM _m1_13_vhashes))::text, 'NULL'),
        coalesce(((SELECT stored_combined_hash FROM _m1_13_vhashes))::text, 'NULL'),
        coalesce(((SELECT combined_hash=stored_combined_hash FROM _m1_13_vhashes))::boolean, false),
        'The complete M1.13 canonical set hash reconciles.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_52_INITIAL_EXPOSURE_IDENTITY',
        'Initial exposure identity',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss WHERE initial_receivable_exposure_amount<>requested_total_repayment_amount))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss WHERE initial_receivable_exposure_amount<>requested_total_repayment_amount))::boolean, false),
        'Initial exposure equals the governed contractual receivable amount.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_53_PATH_WEIGHTED_EAD_IDENTITY',
        'Path-weighted EAD identity',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN (SELECT scenario_id,merchant_application_id,round(sum(weighted_ead_amount),2)::numeric(18,2) ead FROM _m1_13_vpath GROUP BY scenario_id,merchant_application_id) p USING(scenario_id,merchant_application_id) WHERE l.path_weighted_ead_amount<>p.ead))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN (SELECT scenario_id,merchant_application_id,round(sum(weighted_ead_amount),2)::numeric(18,2) ead FROM _m1_13_vpath GROUP BY scenario_id,merchant_application_id) p USING(scenario_id,merchant_application_id) WHERE l.path_weighted_ead_amount<>p.ead))::boolean, false),
        'Snapshot EAD equals the sum of persisted daily weighted exposure.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_54_EAD_RATE_IDENTITY',
        'Expected EAD rate identity',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss WHERE expected_ead_rate IS DISTINCT FROM round(path_weighted_ead_amount/nullif(initial_receivable_exposure_amount,0),8)::numeric(12,8)))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss WHERE expected_ead_rate IS DISTINCT FROM round(path_weighted_ead_amount/nullif(initial_receivable_exposure_amount,0),8)::numeric(12,8)))::boolean, false),
        'Expected EAD rate reconciles to path-weighted EAD divided by initial exposure.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_55_EAD_BOUNDS',
        'EAD amount and rate bounds',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss WHERE path_weighted_ead_amount<0 OR path_weighted_ead_amount>initial_receivable_exposure_amount OR expected_ead_rate<0 OR expected_ead_rate>1))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss WHERE path_weighted_ead_amount<0 OR path_weighted_ead_amount>initial_receivable_exposure_amount OR expected_ead_rate<0 OR expected_ead_rate>1))::boolean, false),
        'Path-weighted EAD remains between zero and initial exposure.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_56_BASELINE_PAYMENT_IDENTITY',
        'Baseline payment identity',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) WHERE sr.scenario_code='BASELINE' AND (l.scenario_expected_daily_remittance<>l.baseline_expected_daily_remittance OR l.governed_path_daily_payment<>l.baseline_expected_daily_remittance)))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) WHERE sr.scenario_code='BASELINE' AND (l.scenario_expected_daily_remittance<>l.baseline_expected_daily_remittance OR l.governed_path_daily_payment<>l.baseline_expected_daily_remittance)))::boolean, false),
        'The baseline path uses the accepted baseline daily remittance.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_57_STRESS_PAYMENT_CAP',
        'Stress payment cap to baseline',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) WHERE sr.scenario_code='RECESSION_ENERGY' AND l.governed_path_daily_payment>l.baseline_expected_daily_remittance))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) WHERE sr.scenario_code='RECESSION_ENERGY' AND l.governed_path_daily_payment>l.baseline_expected_daily_remittance))::boolean, false),
        'The adverse scenario cannot assume faster daily paydown than baseline.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_58_STRESS_EAD_NONIMPROVEMENT',
        'Stress EAD non-improvement',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) JOIN (SELECT merchant_application_id,path_weighted_ead_amount FROM _m1_13_vloss b JOIN msbf_ctl.scenario_registry srb USING(scenario_id) WHERE srb.scenario_code='BASELINE') b USING(merchant_application_id) WHERE sr.scenario_code='RECESSION_ENERGY' AND l.path_weighted_ead_amount<b.path_weighted_ead_amount))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) JOIN (SELECT merchant_application_id,path_weighted_ead_amount FROM _m1_13_vloss b JOIN msbf_ctl.scenario_registry srb USING(scenario_id) WHERE srb.scenario_code='BASELINE') b USING(merchant_application_id) WHERE sr.scenario_code='RECESSION_ENERGY' AND l.path_weighted_ead_amount<b.path_weighted_ead_amount))::boolean, false),
        'Adverse-scenario EAD cannot improve relative to baseline.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_59_INDUSTRY_LGD_MAPPING',
        'Industry LGD baseline mapping',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN msbf_ctl.run_parameter_snapshot p ON p.run_id=l.module1_run_id AND p.parameter_name='industry_lgd_baseline' AND p.scope_key='INDUSTRY:'||l.industry_code WHERE l.industry_lgd_baseline_rate IS DISTINCT FROM (p.resolved_value->>'value_numeric')::numeric(12,8)))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN msbf_ctl.run_parameter_snapshot p ON p.run_id=l.module1_run_id AND p.parameter_name='industry_lgd_baseline' AND p.scope_key='INDUSTRY:'||l.industry_code WHERE l.industry_lgd_baseline_rate IS DISTINCT FROM (p.resolved_value->>'value_numeric')::numeric(12,8)))::boolean, false),
        'Industry LGD foundations reproduce the frozen governed parameter snapshot.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_60_SCENARIO_LGD_ADDON',
        'Scenario LGD add-on mapping',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) CROSS JOIN _m1_13_vpolicy p WHERE l.scenario_lgd_addon_rate IS DISTINCT FROM CASE WHEN sr.scenario_code='RECESSION_ENERGY' THEN round((p.profile_payload->>'stress_lgd_addon_base_rate')::numeric*coalesce((p.profile_payload->'industry_stress_multiplier'->>l.industry_code)::numeric,0),8)::numeric(12,8) ELSE 0::numeric(12,8) END))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) CROSS JOIN _m1_13_vpolicy p WHERE l.scenario_lgd_addon_rate IS DISTINCT FROM CASE WHEN sr.scenario_code='RECESSION_ENERGY' THEN round((p.profile_payload->>'stress_lgd_addon_base_rate')::numeric*coalesce((p.profile_payload->'industry_stress_multiplier'->>l.industry_code)::numeric,0),8)::numeric(12,8) ELSE 0::numeric(12,8) END))::boolean, false),
        'Scenario severity follows the governed industry-transmission mapping.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_61_RECOVERY_CREDIT_BOUNDS',
        'Recovery credit bounds',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l CROSS JOIN _m1_13_vpolicy p WHERE l.collateral_recovery_credit_rate<0 OR l.guarantee_recovery_credit_rate<0 OR l.total_recovery_credit_rate<0 OR l.total_recovery_credit_rate>(p.profile_payload->>'recovery_credit_cap_rate')::numeric OR l.total_recovery_credit_rate>l.collateral_recovery_credit_rate+l.guarantee_recovery_credit_rate))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l CROSS JOIN _m1_13_vpolicy p WHERE l.collateral_recovery_credit_rate<0 OR l.guarantee_recovery_credit_rate<0 OR l.total_recovery_credit_rate<0 OR l.total_recovery_credit_rate>(p.profile_payload->>'recovery_credit_cap_rate')::numeric OR l.total_recovery_credit_rate>l.collateral_recovery_credit_rate+l.guarantee_recovery_credit_rate))::boolean, false),
        'Supported recovery credits remain nonnegative and within the governed cap.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_62_RECOVERY_BASIS_MAPPING',
        'Recovery basis mapping',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss WHERE recovery_basis_code IS DISTINCT FROM CASE WHEN recovery_evidence_status='CONFLICT' THEN 'SOURCE_CONFLICT' WHEN collateral_available_value>0 AND guarantee_capacity_amount>0 THEN 'COLLATERAL_AND_GUARANTEE_SUPPORTED' WHEN collateral_available_value>0 THEN 'COLLATERAL_SUPPORTED' WHEN guarantee_capacity_amount>0 THEN 'GUARANTEE_SUPPORTED' ELSE 'INDUSTRY_PARAMETER_ONLY' END))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss WHERE recovery_basis_code IS DISTINCT FROM CASE WHEN recovery_evidence_status='CONFLICT' THEN 'SOURCE_CONFLICT' WHEN collateral_available_value>0 AND guarantee_capacity_amount>0 THEN 'COLLATERAL_AND_GUARANTEE_SUPPORTED' WHEN collateral_available_value>0 THEN 'COLLATERAL_SUPPORTED' WHEN guarantee_capacity_amount>0 THEN 'GUARANTEE_SUPPORTED' ELSE 'INDUSTRY_PARAMETER_ONLY' END))::boolean, false),
        'Recovery basis codes align with substantive recovery support and source conflicts.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_63_LGD_IDENTITY',
        'LGD identity and stress floor',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) CROSS JOIN _m1_13_vparams p JOIN (SELECT merchant_application_id,lgd_input_rate baseline_lgd FROM _m1_13_vloss b JOIN msbf_ctl.scenario_registry srb USING(scenario_id) WHERE srb.scenario_code='BASELINE') b USING(merchant_application_id) WHERE l.lgd_input_rate IS DISTINCT FROM CASE WHEN sr.scenario_code='RECESSION_ENERGY' THEN greatest(greatest(p.lgd_floor,least(p.lgd_cap,l.industry_lgd_baseline_rate+l.scenario_lgd_addon_rate-l.total_recovery_credit_rate)),b.baseline_lgd)::numeric(12,8) ELSE greatest(p.lgd_floor,least(p.lgd_cap,l.industry_lgd_baseline_rate+l.scenario_lgd_addon_rate-l.total_recovery_credit_rate))::numeric(12,8) END))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) CROSS JOIN _m1_13_vparams p JOIN (SELECT merchant_application_id,lgd_input_rate baseline_lgd FROM _m1_13_vloss b JOIN msbf_ctl.scenario_registry srb USING(scenario_id) WHERE srb.scenario_code='BASELINE') b USING(merchant_application_id) WHERE l.lgd_input_rate IS DISTINCT FROM CASE WHEN sr.scenario_code='RECESSION_ENERGY' THEN greatest(greatest(p.lgd_floor,least(p.lgd_cap,l.industry_lgd_baseline_rate+l.scenario_lgd_addon_rate-l.total_recovery_credit_rate)),b.baseline_lgd)::numeric(12,8) ELSE greatest(p.lgd_floor,least(p.lgd_cap,l.industry_lgd_baseline_rate+l.scenario_lgd_addon_rate-l.total_recovery_credit_rate))::numeric(12,8) END))::boolean, false),
        'LGD equals the bounded industry/stress/recovery foundation with an adverse-scenario floor.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_64_LGD_BOUNDS',
        'LGD bounds',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l CROSS JOIN _m1_13_vparams p WHERE l.lgd_input_rate<p.lgd_floor OR l.lgd_input_rate>p.lgd_cap))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l CROSS JOIN _m1_13_vparams p WHERE l.lgd_input_rate<p.lgd_floor OR l.lgd_input_rate>p.lgd_cap))::boolean, false),
        'Every LGD input remains within the frozen floor and cap.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_65_STRESS_LGD_NONIMPROVEMENT',
        'Stress LGD non-improvement',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) JOIN (SELECT merchant_application_id,lgd_input_rate baseline_lgd FROM _m1_13_vloss b JOIN msbf_ctl.scenario_registry srb USING(scenario_id) WHERE srb.scenario_code='BASELINE') b USING(merchant_application_id) WHERE sr.scenario_code='RECESSION_ENERGY' AND l.lgd_input_rate<b.baseline_lgd))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) JOIN (SELECT merchant_application_id,lgd_input_rate baseline_lgd FROM _m1_13_vloss b JOIN msbf_ctl.scenario_registry srb USING(scenario_id) WHERE srb.scenario_code='BASELINE') b USING(merchant_application_id) WHERE sr.scenario_code='RECESSION_ENERGY' AND l.lgd_input_rate<b.baseline_lgd))::boolean, false),
        'Adverse-scenario LGD cannot improve relative to baseline.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_66_RECOVERY_RATE_IDENTITY',
        'Recovery-rate identity',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss WHERE recovery_rate_assumption IS DISTINCT FROM (1.0-lgd_input_rate)::numeric(12,8)))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss WHERE recovery_rate_assumption IS DISTINCT FROM (1.0-lgd_input_rate)::numeric(12,8)))::boolean, false),
        'Recovery rate equals one minus the governed LGD input.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_67_BLOCKED_LOSS_SUPPRESSION',
        'Blocked loss suppression',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss WHERE loss_evidence_status='BLOCKED' AND (synthetic_merchant_risk_proxy IS NOT NULL OR simple_comparative_expected_loss_amount IS NOT NULL OR schedule_adjusted_comparative_expected_loss_amount IS NOT NULL OR simple_comparative_loss_rate IS NOT NULL OR schedule_adjusted_comparative_loss_rate IS NOT NULL)))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss WHERE loss_evidence_status='BLOCKED' AND (synthetic_merchant_risk_proxy IS NOT NULL OR simple_comparative_expected_loss_amount IS NOT NULL OR schedule_adjusted_comparative_expected_loss_amount IS NOT NULL OR simple_comparative_loss_rate IS NOT NULL OR schedule_adjusted_comparative_loss_rate IS NOT NULL)))::boolean, false),
        'Blocked risk evidence does not produce fabricated comparative loss values.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_68_SIMPLE_LOSS_IDENTITY',
        'Simple comparative loss identity',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l CROSS JOIN _m1_13_vparams p WHERE l.synthetic_merchant_risk_proxy IS NOT NULL AND l.simple_comparative_expected_loss_amount IS DISTINCT FROM round(l.initial_receivable_exposure_amount*l.synthetic_merchant_risk_proxy*l.lgd_input_rate,2)::numeric(18,2)))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l CROSS JOIN _m1_13_vparams p WHERE l.synthetic_merchant_risk_proxy IS NOT NULL AND l.simple_comparative_expected_loss_amount IS DISTINCT FROM round(l.initial_receivable_exposure_amount*l.synthetic_merchant_risk_proxy*l.lgd_input_rate,2)::numeric(18,2)))::boolean, false),
        'Simple comparative loss equals exposure multiplied by synthetic proxy and LGD.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_69_SCHEDULE_LOSS_IDENTITY',
        'Schedule-adjusted comparative loss identity',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss WHERE synthetic_merchant_risk_proxy IS NOT NULL AND schedule_adjusted_comparative_expected_loss_amount IS DISTINCT FROM round(path_weighted_ead_amount*synthetic_merchant_risk_proxy*lgd_input_rate,2)::numeric(18,2)))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss WHERE synthetic_merchant_risk_proxy IS NOT NULL AND schedule_adjusted_comparative_expected_loss_amount IS DISTINCT FROM round(path_weighted_ead_amount*synthetic_merchant_risk_proxy*lgd_input_rate,2)::numeric(18,2)))::boolean, false),
        'Schedule-adjusted comparative loss uses path-weighted EAD, synthetic proxy, and LGD.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_70_LOSS_RATE_IDENTITY',
        'Comparative loss-rate identities',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss WHERE (simple_comparative_expected_loss_amount IS NOT NULL AND simple_comparative_loss_rate IS DISTINCT FROM round(simple_comparative_expected_loss_amount/initial_receivable_exposure_amount,8)::numeric(12,8)) OR (schedule_adjusted_comparative_expected_loss_amount IS NOT NULL AND schedule_adjusted_comparative_loss_rate IS DISTINCT FROM round(schedule_adjusted_comparative_expected_loss_amount/initial_receivable_exposure_amount,8)::numeric(12,8))))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss WHERE (simple_comparative_expected_loss_amount IS NOT NULL AND simple_comparative_loss_rate IS DISTINCT FROM round(simple_comparative_expected_loss_amount/initial_receivable_exposure_amount,8)::numeric(12,8)) OR (schedule_adjusted_comparative_expected_loss_amount IS NOT NULL AND schedule_adjusted_comparative_loss_rate IS DISTINCT FROM round(schedule_adjusted_comparative_expected_loss_amount/initial_receivable_exposure_amount,8)::numeric(12,8))))::boolean, false),
        'Loss rates reconcile to their corresponding loss amounts divided by initial exposure.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_71_SCHEDULE_NOT_ABOVE_SIMPLE',
        'Schedule-adjusted loss not above simple loss',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss WHERE schedule_adjusted_comparative_expected_loss_amount>simple_comparative_expected_loss_amount))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss WHERE schedule_adjusted_comparative_expected_loss_amount>simple_comparative_expected_loss_amount))::boolean, false),
        'Path-weighted EAD cannot produce a greater loss than day-zero simple exposure under the same proxy and LGD.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_72_STRESS_SIMPLE_LOSS_NONIMPROVEMENT',
        'Stress simple-loss non-improvement',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) JOIN (SELECT merchant_application_id,simple_comparative_expected_loss_amount baseline_loss FROM _m1_13_vloss b JOIN msbf_ctl.scenario_registry srb USING(scenario_id) WHERE srb.scenario_code='BASELINE') b USING(merchant_application_id) WHERE sr.scenario_code='RECESSION_ENERGY' AND l.simple_comparative_expected_loss_amount<b.baseline_loss))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) JOIN (SELECT merchant_application_id,simple_comparative_expected_loss_amount baseline_loss FROM _m1_13_vloss b JOIN msbf_ctl.scenario_registry srb USING(scenario_id) WHERE srb.scenario_code='BASELINE') b USING(merchant_application_id) WHERE sr.scenario_code='RECESSION_ENERGY' AND l.simple_comparative_expected_loss_amount<b.baseline_loss))::boolean, false),
        'Adverse-scenario simple comparative loss cannot improve relative to baseline.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_73_STRESS_SCHEDULE_LOSS_NONIMPROVEMENT',
        'Stress schedule-loss non-improvement',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) JOIN (SELECT merchant_application_id,schedule_adjusted_comparative_expected_loss_amount baseline_loss FROM _m1_13_vloss b JOIN msbf_ctl.scenario_registry srb USING(scenario_id) WHERE srb.scenario_code='BASELINE') b USING(merchant_application_id) WHERE sr.scenario_code='RECESSION_ENERGY' AND l.schedule_adjusted_comparative_expected_loss_amount<b.baseline_loss))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN msbf_ctl.scenario_registry sr USING(scenario_id) JOIN (SELECT merchant_application_id,schedule_adjusted_comparative_expected_loss_amount baseline_loss FROM _m1_13_vloss b JOIN msbf_ctl.scenario_registry srb USING(scenario_id) WHERE srb.scenario_code='BASELINE') b USING(merchant_application_id) WHERE sr.scenario_code='RECESSION_ENERGY' AND l.schedule_adjusted_comparative_expected_loss_amount<b.baseline_loss))::boolean, false),
        'Adverse-scenario schedule-adjusted comparative loss cannot improve relative to baseline.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_74_EVIDENCE_STATUS_MAPPING',
        'Loss evidence-status mapping',
        coalesce(((
        SELECT count(*)::text
        FROM _m1_13_vloss l
        JOIN msbf_m1.source_snapshot s
          ON s.module1_run_id = l.module1_run_id
         AND s.merchant_application_id = l.merchant_application_id
         AND s.source_code = 'COLLATERAL_AVAILABILITY'
        WHERE l.loss_evidence_status IS DISTINCT FROM CASE
            WHEN l.integrated_risk_evidence_status = 'BLOCKED'
              OR l.synthetic_merchant_risk_proxy IS NULL THEN 'BLOCKED'
            WHEN l.recovery_evidence_status = 'SUPPORTED'
              AND s.quality_status = 'PASS' THEN 'COMPLETE'
            ELSE 'PARTIAL'
        END
    ))::text, 'NULL'),
        '0',
        coalesce(((
        SELECT count(*) = 0
        FROM _m1_13_vloss l
        JOIN msbf_m1.source_snapshot s
          ON s.module1_run_id = l.module1_run_id
         AND s.merchant_application_id = l.merchant_application_id
         AND s.source_code = 'COLLATERAL_AVAILABILITY'
        WHERE l.loss_evidence_status IS DISTINCT FROM CASE
            WHEN l.integrated_risk_evidence_status = 'BLOCKED'
              OR l.synthetic_merchant_risk_proxy IS NULL THEN 'BLOCKED'
            WHEN l.recovery_evidence_status = 'SUPPORTED'
              AND s.quality_status = 'PASS' THEN 'COMPLETE'
            ELSE 'PARTIAL'
        END
    ))::boolean, false),
        'Loss evidence status separates complete, parameter-only/conflict, and blocked evidence.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_75_MANUAL_REVIEW_IDENTITY',
        'Manual-review identity',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN msbf_m1.application_integrated_risk_proxy_snapshot r USING(module1_run_id,scenario_id,merchant_application_id) JOIN msbf_m1.application_liquidity_capacity_snapshot c USING(module1_run_id,scenario_id,merchant_application_id) CROSS JOIN _m1_13_vpolicy p WHERE l.manual_review_recommended_flag IS DISTINCT FROM (r.manual_review_recommended_flag OR c.manual_review_recommended_flag OR l.hard_stop_recommended_flag OR l.loss_evidence_status='BLOCKED' OR l.recovery_evidence_status='CONFLICT' OR l.lgd_input_rate>=(p.profile_payload->>'manual_review_lgd_threshold')::numeric OR (l.schedule_adjusted_comparative_loss_rate IS NOT NULL AND l.schedule_adjusted_comparative_loss_rate>=(p.profile_payload->>'manual_review_loss_rate_threshold')::numeric))))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN msbf_m1.application_integrated_risk_proxy_snapshot r USING(module1_run_id,scenario_id,merchant_application_id) JOIN msbf_m1.application_liquidity_capacity_snapshot c USING(module1_run_id,scenario_id,merchant_application_id) CROSS JOIN _m1_13_vpolicy p WHERE l.manual_review_recommended_flag IS DISTINCT FROM (r.manual_review_recommended_flag OR c.manual_review_recommended_flag OR l.hard_stop_recommended_flag OR l.loss_evidence_status='BLOCKED' OR l.recovery_evidence_status='CONFLICT' OR l.lgd_input_rate>=(p.profile_payload->>'manual_review_lgd_threshold')::numeric OR (l.schedule_adjusted_comparative_loss_rate IS NOT NULL AND l.schedule_adjusted_comparative_loss_rate>=(p.profile_payload->>'manual_review_loss_rate_threshold')::numeric))))::boolean, false),
        'Manual review reconciles to accepted upstream review, evidence, LGD, and comparative loss conditions.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_76_HARD_STOP_LINEAGE',
        'Hard-stop lineage',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN msbf_m1.application_integrated_risk_proxy_snapshot r USING(module1_run_id,scenario_id,merchant_application_id) WHERE l.hard_stop_recommended_flag IS DISTINCT FROM r.hard_stop_recommended_flag))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN msbf_m1.application_integrated_risk_proxy_snapshot r USING(module1_run_id,scenario_id,merchant_application_id) WHERE l.hard_stop_recommended_flag IS DISTINCT FROM r.hard_stop_recommended_flag))::boolean, false),
        'M1.13 preserves the accepted M1.12 hard-stop recommendation without reinterpretation.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_77_FALLBACK_DOMAIN',
        'Fallback-path domain',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss WHERE fallback_path_code NOT IN ('NONE','PARAMETER_ONLY_RECOVERY','RECOVERY_SOURCE_REVIEW','INSUFFICIENT_RISK_EVIDENCE','VERIFICATION_STOP','MANUAL_LOSS_REVIEW')))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss WHERE fallback_path_code NOT IN ('NONE','PARAMETER_ONLY_RECOVERY','RECOVERY_SOURCE_REVIEW','INSUFFICIENT_RISK_EVIDENCE','VERIFICATION_STOP','MANUAL_LOSS_REVIEW')))::boolean, false),
        'All fallback routes are within the approved controlled domain.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_78_REASON_CODE_DOMAIN',
        'Primary reason-code domain',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss WHERE primary_loss_reason_code NOT IN ('VERIFICATION_HARD_STOP','INSUFFICIENT_RISK_EVIDENCE','RECOVERY_SOURCE_CONFLICT','HIGH_LGD_FOUNDATION','HIGH_COMPARATIVE_LOSS_RATE','PARAMETER_ONLY_RECOVERY','ELEVATED_PATH_WEIGHTED_EAD','STANDARD_LOSS_FOUNDATION')))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss WHERE primary_loss_reason_code NOT IN ('VERIFICATION_HARD_STOP','INSUFFICIENT_RISK_EVIDENCE','RECOVERY_SOURCE_CONFLICT','HIGH_LGD_FOUNDATION','HIGH_COMPARATIVE_LOSS_RATE','PARAMETER_ONLY_RECOVERY','ELEVATED_PATH_WEIGHTED_EAD','STANDARD_LOSS_FOUNDATION')))::boolean, false),
        'Primary loss-foundation reason codes remain within the governed domain.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_79_UPSTREAM_HASH_LINEAGE',
        'Upstream row-hash lineage',
        coalesce(((SELECT count(*)::text FROM _m1_13_vloss l JOIN msbf_m1.application_integrated_risk_proxy_snapshot r USING(module1_run_id,scenario_id,merchant_application_id) JOIN msbf_m1.application_liquidity_capacity_snapshot c USING(module1_run_id,scenario_id,merchant_application_id) JOIN msbf_m1.merchant_application a USING(merchant_application_id) WHERE l.integrated_risk_snapshot_hash<>r.row_hash OR l.liquidity_capacity_snapshot_hash<>c.row_hash OR l.application_request_hash<>a.request_hash))::text, 'NULL'),
        '0',
        coalesce(((SELECT count(*)=0 FROM _m1_13_vloss l JOIN msbf_m1.application_integrated_risk_proxy_snapshot r USING(module1_run_id,scenario_id,merchant_application_id) JOIN msbf_m1.application_liquidity_capacity_snapshot c USING(module1_run_id,scenario_id,merchant_application_id) JOIN msbf_m1.merchant_application a USING(merchant_application_id) WHERE l.integrated_risk_snapshot_hash<>r.row_hash OR l.liquidity_capacity_snapshot_hash<>c.row_hash OR l.application_request_hash<>a.request_hash))::boolean, false),
        'Every loss snapshot retains exact accepted upstream row-hash lineage.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_80_GENERATION_EVIDENCE',
        'Generation evidence completeness',
        coalesce(((SELECT count(*)::text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_13_vctx) AND evidence_code IN ('M1_13_GENERATION_SPEC','M1_13_PATH_SET_HASH','M1_13_SNAPSHOT_SET_HASH','M1_13_COMBINED_SET_HASH','M1_13_PATH_ROW_COUNT','M1_13_SNAPSHOT_ROW_COUNT','M1_13_CANONICAL_ENTITY_COUNT','M1_13_CANONICAL_MISMATCH_COUNT','M1_13_PORTFOLIO_SCHEDULE_LOSS_AMOUNT','M1_13_GENERATION_SUMMARY') AND status='PASS'))::text, 'NULL'),
        '10',
        coalesce(((SELECT count(*)=10 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_13_vctx) AND evidence_code IN ('M1_13_GENERATION_SPEC','M1_13_PATH_SET_HASH','M1_13_SNAPSHOT_SET_HASH','M1_13_COMBINED_SET_HASH','M1_13_PATH_ROW_COUNT','M1_13_SNAPSHOT_ROW_COUNT','M1_13_CANONICAL_ENTITY_COUNT','M1_13_CANONICAL_MISMATCH_COUNT','M1_13_PORTFOLIO_SCHEDULE_LOSS_AMOUNT','M1_13_GENERATION_SUMMARY') AND status='PASS'))::boolean, false),
        'All required M1.13 generation evidence is persisted.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_81_STAGE_BOUNDARY',
        'Downstream stage boundary',
        coalesce(((SELECT downstream_rows::text FROM _m1_13_vboundary))::text, 'NULL'),
        '0',
        coalesce(((SELECT downstream_rows=0 FROM _m1_13_vboundary))::boolean, false),
        'M1.13 does not populate legacy risk, production EAD, latest, or archive contract outputs.'
    );

    PERFORM pg_temp.m1_13_add_check(
        'M1_13_POS_82_BLOCKING_ERRORS',
        'Blocking resolution errors',
        coalesce(((SELECT blocking_errors::text FROM _m1_13_vboundary))::text, 'NULL'),
        '0',
        coalesce(((SELECT blocking_errors=0 FROM _m1_13_vboundary))::boolean, false),
        'No blocking profile or parameter resolution errors remain.'
    );
END;
$checks$;

/* ---------------------------------------------------------------------------
4. Persist evidence and advance the run state
--------------------------------------------------------------------------- */
INSERT INTO msbf_ctl.run_evidence (
    run_id, evidence_code, segment_key, metric_name,
    metric_value_text, unit_code, status, interpretation
)
SELECT
    (SELECT run_id FROM _m1_13_vctx),
    evidence_code,
    'PORTFOLIO',
    metric_name,
    observed_value,
    'TEXT',
    status,
    interpretation
FROM _m1_13_validation
ON CONFLICT (run_id, evidence_code, segment_key) DO UPDATE SET
    metric_name = EXCLUDED.metric_name,
    metric_value_text = EXCLUDED.metric_value_text,
    metric_value_numeric = NULL,
    unit_code = EXCLUDED.unit_code,
    status = EXCLUDED.status,
    interpretation = EXCLUDED.interpretation,
    created_at = clock_timestamp();

UPDATE msbf_ctl.run_registry r
SET run_status = CASE
        WHEN (SELECT count(*) FROM _m1_13_validation WHERE status='PASS') = 82
         AND (SELECT count(*) FROM _m1_13_validation WHERE status='FAIL') = 0
        THEN 'M1_13_VALIDATED'
        ELSE 'M1_13_FAILED'
    END,
    notes = coalesce(r.notes,'') || E'\nM1.13 v0.2 positive validation completed.'
WHERE r.run_id = (SELECT run_id FROM _m1_13_vctx);

COMMIT;

SELECT
    evidence_code,
    metric_name,
    observed_value,
    threshold_value,
    status,
    interpretation
FROM _m1_13_validation
ORDER BY evidence_code;
