/* ============================================================================
M1.13 v0.2R1 BOOLEAN-PARAMETER AGGREGATION HOTFIX
Source  : 93_msbf_m1_13_preflight_validation_v0_2.sql
Role    : Read-only preflight validation; executable logic unchanged from v0.2.
Revision: File name is version-aligned to v0.2R1. Except where explicitly
          documented in HOTFIX_NOTES_v0_2R1.md, executable logic is unchanged.
============================================================================ */

/* ============================================================================
MSBF M1.13 Exposure, Recovery & Expected Loss Foundations — Preflight Validation
Version : v0.2
Purpose : Prove that the accepted M1.12 state, frozen EAD/LGD parameters,
          approved M1.13 policy, matched scenario inputs, schema extension,
          empty targets, and downstream boundaries are ready for generation.
Mode    : Read-only.
Required: preflight_status = PASS.
============================================================================ */

WITH run_context AS (
    SELECT
        run_id, run_status, population_id, as_of_date,
        parameter_snapshot_hash, profile_snapshot_hash, source_snapshot_hash
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
passed_gates AS (
    SELECT count(*) AS passed_gate_count
    FROM (
        SELECT DISTINCT ON (gate_id) gate_id, result_status
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id = (SELECT run_id FROM run_context)
          AND gate_id IN (
              'G1_CONTROL_PLANE',
              'M1_2_POPULATION',
              'M1_3_APPLICATION_REQUEST',
              'M1_4_DAILY_POS_HISTORY',
              'M1_5_DAILY_DEPOSIT_LIQUIDITY',
              'M1_6_MATCHED_SCENARIO_OVERLAYS',
              'M1_7_SOURCE_QUALITY_CONFIDENCE',
              'M1_8_VERIFICATION_FRAUD_CONTINUITY',
              'M1_9_ASOF_CASHFLOW_FEATURES',
              'M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY',
              'M1_11_CASHFLOW_ARCHETYPE_RESILIENCE',
              'M1_12_INTEGRATED_RISK_PROXY'
          )
        ORDER BY gate_id, review_version DESC
    ) latest
    WHERE result_status = 'PASS'
),
policy AS (
    SELECT
        status,
        profile_payload,
        profile_payload ->> 'methodology_version' AS methodology_version,
        profile_payload ->> 'exposure_basis_code' AS exposure_basis_code,
        profile_payload ->> 'ead_method_code' AS ead_method_code,
        (profile_payload ->> 'stress_payment_cap_to_baseline')::boolean AS payment_floor,
        (profile_payload ->> 'stress_ead_floor_to_baseline')::boolean AS ead_floor,
        (profile_payload ->> 'stress_lgd_floor_to_baseline')::boolean AS lgd_floor_enabled,
        (profile_payload ->> 'stress_loss_floor_to_baseline')::boolean AS loss_floor,
        (profile_payload ->> 'recovery_credit_cap_rate')::numeric AS recovery_credit_cap,
        (profile_payload ->> 'stress_lgd_addon_base_rate')::numeric AS stress_lgd_addon
    FROM msbf_ctl.policy_profile
    WHERE profile_code = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
      AND profile_version = 1
),
scenario_scope AS (
    SELECT
        count(DISTINCT r.scenario_id) AS scenario_count,
        count(DISTINCT r.scenario_id) FILTER (WHERE sr.scenario_code = 'BASELINE') AS baseline_count,
        count(DISTINCT r.scenario_id) FILTER (WHERE sr.scenario_code = 'RECESSION_ENERGY') AS stress_count,
        count(*) AS risk_rows,
        count(DISTINCT r.merchant_application_id) AS applications
    FROM msbf_m1.application_integrated_risk_proxy_snapshot r
    JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id = r.scenario_id
    JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id = sr.scenario_set_id
    WHERE r.module1_run_id = (SELECT run_id FROM run_context)
      AND ss.scenario_set_code = 'M1_V0_2_BASELINE_AND_STRESS'
      AND ss.scenario_set_version = 1
      AND ss.status = 'APPROVED'
      AND sr.status = 'APPROVED'
      AND sr.scenario_version = 1
      AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY')
),
input_counts AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.merchant_application
         WHERE created_by_run_id = (SELECT run_id FROM run_context)) AS applications,
        (SELECT count(*) FROM msbf_m1.application_integrated_risk_proxy_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS risk_rows,
        (SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS capacity_rows,
        (SELECT count(*) FROM msbf_m1.source_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND source_code = 'COLLATERAL_AVAILABILITY') AS collateral_source_rows,
        (SELECT count(*) FROM msbf_m1.collateral_availability_snapshot
         WHERE created_by_run_id = (SELECT run_id FROM run_context)) AS collateral_rows,
        (SELECT count(*) FROM msbf_m1.guarantee_availability_snapshot
         WHERE created_by_run_id = (SELECT run_id FROM run_context)) AS guarantee_rows,
        (SELECT sum(requested_expected_payoff_days + 1)::bigint * 2
         FROM msbf_m1.merchant_application
         WHERE created_by_run_id = (SELECT run_id FROM run_context)) AS expected_path_rows
),
parameter_inventory AS (
    SELECT
        count(*) FILTER (WHERE parameter_name = 'ead_method_code' AND scope_key = 'GLOBAL') AS ead_method_rows,
        count(*) FILTER (WHERE parameter_name = 'default_timing_weight' AND scope_key LIKE 'PATH_DAY_BUCKET:%') AS timing_rows,
        count(*) FILTER (WHERE parameter_name = 'paydown_curve_shape' AND scope_key LIKE 'EXPECTED_PAYOFF_DAYS:%') AS paydown_rows,
        count(*) FILTER (WHERE parameter_name = 'industry_lgd_baseline' AND scope_key LIKE 'INDUSTRY:%') AS industry_lgd_rows,
        count(*) FILTER (WHERE parameter_name IN (
            'collateral_availability_lgd_haircut',
            'guarantee_availability_lgd_haircut',
            'lgd_floor', 'lgd_cap', 'expected_loss_tolerance_amount',
            'ead_weight_tolerance', 'simple_el_publish_flag',
            'schedule_adjusted_el_publish_flag'
        ) AND scope_key = 'GLOBAL') AS global_loss_rows,
        sum((resolved_value ->> 'value_numeric')::numeric)
            FILTER (WHERE parameter_name = 'default_timing_weight'
                    AND scope_key LIKE 'PATH_DAY_BUCKET:%') AS timing_weight_sum,
        max((resolved_value ->> 'value_numeric')::numeric)
            FILTER (WHERE parameter_name = 'lgd_floor' AND scope_key = 'GLOBAL') AS lgd_floor,
        max((resolved_value ->> 'value_numeric')::numeric)
            FILTER (WHERE parameter_name = 'lgd_cap' AND scope_key = 'GLOBAL') AS lgd_cap
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id = (SELECT run_id FROM run_context)
),
target_counts AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.application_ead_path_value
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS path_rows,
        (SELECT count(*) FROM msbf_m1.application_exposure_recovery_loss_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS snapshot_rows,
        (SELECT count(*) FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code LIKE 'M1_13_%') AS evidence_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
         WHERE run_id = (SELECT run_id FROM run_context)
           AND gate_id = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS') AS gate_rows
),
stage_boundary AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS legacy_risk_rows,
        (SELECT count(*) FROM msbf_m1.risk_component_detail
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS legacy_component_rows,
        (SELECT count(*) FROM msbf_m1.ead_path_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS legacy_ead_rows,
        (SELECT count(*) FROM msbf_m1.module1_latest
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS latest_rows,
        (SELECT count(*) FROM msbf_m1.module1_archive
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS archive_rows,
        (SELECT count(*) FROM msbf_ctl.profile_resolution_error
         WHERE run_id = (SELECT run_id FROM run_context)
           AND severity = 'BLOCKING') AS blocking_errors
),
accepted_hashes AS (
    SELECT
        (SELECT population_hash FROM msbf_m1.population_registry
         WHERE population_id = (SELECT population_id FROM run_context)) AS population_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code = 'M1_3_APPLICATION_SET_HASH'
           AND segment_key = 'PORTFOLIO') AS application_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code = 'M1_6_COMBINED_SET_HASH'
           AND segment_key = 'PORTFOLIO') AS scenario_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code = 'M1_10_COMBINED_SET_HASH'
           AND segment_key = 'PORTFOLIO') AS capacity_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code = 'M1_12_COMBINED_SET_HASH'
           AND segment_key = 'PORTFOLIO') AS integrated_risk_hash
),
schema_state AS (
    SELECT
        to_regclass('msbf_m1.application_ead_path_value') IS NOT NULL AS path_table_exists,
        to_regclass('msbf_m1.application_exposure_recovery_loss_snapshot') IS NOT NULL AS snapshot_table_exists,
        to_regclass('msbf_m1.v_m1_13_exposure_recovery_loss_lineage') IS NOT NULL AS lineage_view_exists,
        (SELECT count(*) FROM msbf_m1.feature_definition
         WHERE feature_family_code = 'EXPOSURE_RECOVERY_LOSS' AND active_flag) AS active_feature_definitions
)
SELECT
    r.run_id,
    r.run_status,
    g.passed_gate_count,
    p.status AS policy_status,
    p.methodology_version,
    p.exposure_basis_code,
    p.ead_method_code,
    p.payment_floor,
    p.ead_floor,
    p.lgd_floor_enabled,
    p.loss_floor,
    p.recovery_credit_cap,
    p.stress_lgd_addon,
    s.scenario_count,
    s.baseline_count,
    s.stress_count,
    i.applications,
    i.risk_rows,
    i.capacity_rows,
    i.collateral_source_rows,
    i.collateral_rows,
    i.guarantee_rows,
    i.expected_path_rows,
    pi.ead_method_rows,
    pi.timing_rows,
    pi.paydown_rows,
    pi.industry_lgd_rows,
    pi.global_loss_rows,
    pi.timing_weight_sum,
    pi.lgd_floor,
    pi.lgd_cap,
    t.path_rows,
    t.snapshot_rows,
    t.evidence_rows,
    t.gate_rows,
    b.legacy_risk_rows,
    b.legacy_component_rows,
    b.legacy_ead_rows,
    b.latest_rows,
    b.archive_rows,
    b.blocking_errors,
    h.population_hash,
    h.application_hash,
    h.scenario_hash,
    h.capacity_hash,
    h.integrated_risk_hash,
    sc.path_table_exists,
    sc.snapshot_table_exists,
    sc.lineage_view_exists,
    sc.active_feature_definitions,
    CASE
        WHEN r.run_status = 'M1_12_ACCEPTED'
         AND g.passed_gate_count = 12
         AND p.status = 'APPROVED'
         AND p.methodology_version = 'M1_13_METHOD_V1'
         AND p.exposure_basis_code = 'CONTRACTUAL_RECEIVABLE'
         AND p.ead_method_code = 'WEIGHTED_DAILY_BALANCE'
         AND p.payment_floor AND p.ead_floor AND p.lgd_floor_enabled AND p.loss_floor
         AND p.recovery_credit_cap BETWEEN 0 AND 1
         AND p.stress_lgd_addon BETWEEN 0 AND 1
         AND s.scenario_count = 2 AND s.baseline_count = 1 AND s.stress_count = 1
         AND i.applications = 750 AND i.risk_rows = 1500 AND i.capacity_rows = 1500
         AND i.collateral_source_rows = 750
         AND i.expected_path_rows > 0
         AND pi.ead_method_rows = 1
         AND pi.timing_rows = 3
         AND pi.paydown_rows = 3
         AND pi.industry_lgd_rows = 8
         AND pi.global_loss_rows = 8
         AND abs(pi.timing_weight_sum - 1.0) <= 0.000001
         AND pi.lgd_floor < pi.lgd_cap
         AND t.path_rows = 0 AND t.snapshot_rows = 0
         AND t.evidence_rows = 0 AND t.gate_rows = 0
         AND b.legacy_risk_rows = 0 AND b.legacy_component_rows = 0
         AND b.legacy_ead_rows = 0 AND b.latest_rows = 0 AND b.archive_rows = 0
         AND b.blocking_errors = 0
         AND h.population_hash IS NOT NULL
         AND h.application_hash IS NOT NULL
         AND h.scenario_hash IS NOT NULL
         AND h.capacity_hash IS NOT NULL
         AND h.integrated_risk_hash IS NOT NULL
         AND sc.path_table_exists AND sc.snapshot_table_exists AND sc.lineage_view_exists
         AND sc.active_feature_definitions = 10
        THEN 'PASS'
        ELSE 'FAIL'
    END AS preflight_status
FROM run_context r
CROSS JOIN passed_gates g
CROSS JOIN policy p
CROSS JOIN scenario_scope s
CROSS JOIN input_counts i
CROSS JOIN parameter_inventory pi
CROSS JOIN target_counts t
CROSS JOIN stage_boundary b
CROSS JOIN accepted_hashes h
CROSS JOIN schema_state sc;
