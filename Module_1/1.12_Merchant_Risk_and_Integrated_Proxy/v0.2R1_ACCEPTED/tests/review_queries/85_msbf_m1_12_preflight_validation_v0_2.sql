/* ============================================================================
MSBF M1.12 Merchant Risk Components & Integrated Risk Proxy — Preflight Validation
Version : v0.2
Purpose : Prove that the accepted M1.11 state, governed M1.12 methodology,
          scenario-aware M1.8/M1.10/M1.11 inputs, schema extension, upstream
          hashes, empty targets, and stage boundaries are ready for generation.
Mode    : Read-only.
Required: preflight_status = PASS.
============================================================================ */

WITH run_context AS (
    SELECT
        run_id,
        run_status,
        population_id,
        as_of_date,
        parameter_snapshot_hash,
        profile_snapshot_hash,
        source_snapshot_hash
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
passed_gates AS (
    SELECT count(*) AS passed_gate_count
    FROM (
        SELECT DISTINCT ON (gate_id)
            gate_id,
            result_status
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
              'M1_11_CASHFLOW_ARCHETYPE_RESILIENCE'
          )
        ORDER BY gate_id, review_version DESC
    ) latest
    WHERE result_status = 'PASS'
),
policy AS (
    SELECT
        policy_profile_id,
        status,
        profile_payload,
        profile_payload ->> 'methodology_version' AS methodology_version,
        profile_payload ->> 'composite_score_basis' AS composite_score_basis,
        (profile_payload ->> 'component_weight_operating_resilience')::numeric
      + (profile_payload ->> 'component_weight_capacity_burden')::numeric
      + (profile_payload ->> 'component_weight_liquidity')::numeric
      + (profile_payload ->> 'component_weight_source_confidence')::numeric
      + (profile_payload ->> 'component_weight_verification_fraud')::numeric
      + (profile_payload ->> 'component_weight_processor_continuity')::numeric
      + (profile_payload ->> 'component_weight_industry_relationship')::numeric
            AS component_weight_sum,
        (profile_payload ->> 'risk_tier_1_max')::numeric AS tier_1_max,
        (profile_payload ->> 'risk_tier_2_max')::numeric AS tier_2_max,
        (profile_payload ->> 'risk_tier_3_max')::numeric AS tier_3_max,
        (profile_payload ->> 'risk_tier_4_max')::numeric AS tier_4_max
    FROM msbf_ctl.policy_profile
    WHERE profile_code = 'M1_12_INTEGRATED_RISK_PROXY'
      AND profile_version = 1
),
scenario_scope AS (
    SELECT
        count(DISTINCT r.scenario_id) AS scenario_count,
        count(DISTINCT r.scenario_id)
            FILTER (WHERE sr.scenario_code = 'BASELINE') AS baseline_count,
        count(DISTINCT r.scenario_id)
            FILTER (WHERE sr.scenario_code = 'RECESSION_ENERGY') AS stress_count,
        count(*) AS resilience_rows,
        count(DISTINCT r.merchant_application_id) AS applications
    FROM msbf_m1.application_operating_resilience_snapshot r
    JOIN msbf_ctl.scenario_registry sr
      ON sr.scenario_id = r.scenario_id
    JOIN msbf_ctl.scenario_set ss
      ON ss.scenario_set_id = sr.scenario_set_id
    WHERE r.module1_run_id = (SELECT run_id FROM run_context)
      AND ss.scenario_set_code = 'M1_V0_2_BASELINE_AND_STRESS'
      AND ss.scenario_set_version = 1
      AND ss.status = 'APPROVED'
      AND sr.status = 'APPROVED'
      AND sr.scenario_version = 1
      AND sr.scenario_code IN ('BASELINE', 'RECESSION_ENERGY')
),
input_counts AS (
    SELECT
        (SELECT count(*)
         FROM msbf_m1.merchant_application
         WHERE created_by_run_id = (SELECT run_id FROM run_context)) AS merchant_applications,
        (SELECT count(*)
         FROM msbf_m1.application_verification_fraud_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS verification_rows,
        (SELECT count(*)
         FROM msbf_m1.application_liquidity_capacity_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS capacity_rows,
        (SELECT count(*)
         FROM msbf_m1.application_operating_resilience_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS resilience_rows,
        (SELECT count(*)
         FROM msbf_m1.operating_resilience_component_value
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS resilience_component_rows
),
target_counts AS (
    SELECT
        (SELECT count(*)
         FROM msbf_m1.application_integrated_risk_proxy_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS risk_snapshot_rows,
        (SELECT count(*)
         FROM msbf_m1.integrated_risk_component_value
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS risk_component_rows,
        (SELECT count(*)
         FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code LIKE 'M1_12_%') AS m1_12_evidence_rows,
        (SELECT count(*)
         FROM msbf_ctl.acceptance_gate_result
         WHERE run_id = (SELECT run_id FROM run_context)
           AND gate_id = 'M1_12_INTEGRATED_RISK_PROXY') AS m1_12_gate_rows
),
stage_boundary AS (
    SELECT
        (SELECT count(*)
         FROM msbf_m1.merchant_risk_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS legacy_risk_rows,
        (SELECT count(*)
         FROM msbf_m1.risk_component_detail
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS legacy_component_rows,
        (SELECT count(*)
         FROM msbf_m1.ead_path_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS ead_rows,
        (SELECT count(*)
         FROM msbf_m1.module1_latest
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS latest_rows,
        (SELECT count(*)
         FROM msbf_m1.module1_archive
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS archive_rows,
        (SELECT count(*)
         FROM msbf_ctl.profile_resolution_error
         WHERE run_id = (SELECT run_id FROM run_context)
           AND severity = 'BLOCKING') AS blocking_errors
),
accepted_hashes AS (
    SELECT
        (SELECT population_hash
         FROM msbf_m1.population_registry
         WHERE population_id = (SELECT population_id FROM run_context)) AS population_hash,
        (SELECT metric_value_text
         FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code = 'M1_3_APPLICATION_SET_HASH'
           AND segment_key = 'PORTFOLIO') AS application_hash,
        (SELECT metric_value_text
         FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code = 'M1_7_SOURCE_SET_HASH'
           AND segment_key = 'PORTFOLIO') AS source_quality_hash,
        (SELECT metric_value_text
         FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code = 'M1_8_COMBINED_SET_HASH'
           AND segment_key = 'PORTFOLIO') AS verification_hash,
        (SELECT metric_value_text
         FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code = 'M1_9_COMBINED_SET_HASH'
           AND segment_key = 'PORTFOLIO') AS cashflow_hash,
        (SELECT metric_value_text
         FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code = 'M1_10_COMBINED_SET_HASH'
           AND segment_key = 'PORTFOLIO') AS capacity_hash,
        (SELECT metric_value_text
         FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code = 'M1_11_COMBINED_SET_HASH'
           AND segment_key = 'PORTFOLIO') AS resilience_hash
),
schema_state AS (
    SELECT
        to_regclass('msbf_m1.application_integrated_risk_proxy_snapshot') IS NOT NULL
            AS risk_snapshot_table_exists,
        to_regclass('msbf_m1.integrated_risk_component_value') IS NOT NULL
            AS risk_component_table_exists,
        to_regclass('msbf_m1.v_m1_12_integrated_risk_lineage') IS NOT NULL
            AS lineage_view_exists,
        (SELECT count(*)
         FROM msbf_ref.risk_component_code
         WHERE component_code IN (
             'OPERATING_RESILIENCE_RISK',
             'CAPACITY_BURDEN_RISK',
             'LIQUIDITY_RISK',
             'SOURCE_CONFIDENCE_RISK',
             'VERIFICATION_FRAUD_RISK',
             'PROCESSOR_CONTINUITY_RISK',
             'INDUSTRY_RELATIONSHIP_RISK'
         )
           AND active_flag) AS active_component_codes
)
SELECT
    r.run_id,
    r.run_status,
    g.passed_gate_count,
    p.status AS policy_status,
    p.methodology_version,
    p.composite_score_basis,
    p.component_weight_sum,
    p.tier_1_max,
    p.tier_2_max,
    p.tier_3_max,
    p.tier_4_max,
    s.scenario_count,
    s.baseline_count,
    s.stress_count,
    i.merchant_applications,
    i.verification_rows,
    i.capacity_rows,
    i.resilience_rows,
    i.resilience_component_rows,
    t.risk_snapshot_rows,
    t.risk_component_rows,
    t.m1_12_evidence_rows,
    t.m1_12_gate_rows,
    b.legacy_risk_rows,
    b.legacy_component_rows,
    b.ead_rows,
    b.latest_rows,
    b.archive_rows,
    b.blocking_errors,
    h.population_hash,
    h.application_hash,
    h.source_quality_hash,
    h.verification_hash,
    h.cashflow_hash,
    h.capacity_hash,
    h.resilience_hash,
    sc.risk_snapshot_table_exists,
    sc.risk_component_table_exists,
    sc.lineage_view_exists,
    sc.active_component_codes,
    CASE
        WHEN r.run_status = 'M1_11_ACCEPTED'
         AND g.passed_gate_count = 11
         AND p.status = 'APPROVED'
         AND p.methodology_version = 'M1_12_METHOD_V1'
         AND p.composite_score_basis = 'SUM_PERSISTED_WEIGHTED_RISK_COMPONENTS'
         AND abs(p.component_weight_sum - 1.0) <= 0.0000001
         AND p.tier_1_max < p.tier_2_max
         AND p.tier_2_max < p.tier_3_max
         AND p.tier_3_max < p.tier_4_max
         AND s.scenario_count = 2
         AND s.baseline_count = 1
         AND s.stress_count = 1
         AND i.merchant_applications = 750
         AND i.verification_rows = 750
         AND i.capacity_rows = 1500
         AND i.resilience_rows = 1500
         AND i.resilience_component_rows = 7500
         AND t.risk_snapshot_rows = 0
         AND t.risk_component_rows = 0
         AND t.m1_12_evidence_rows = 0
         AND t.m1_12_gate_rows = 0
         AND b.legacy_risk_rows = 0
         AND b.legacy_component_rows = 0
         AND b.ead_rows = 0
         AND b.latest_rows = 0
         AND b.archive_rows = 0
         AND b.blocking_errors = 0
         AND r.parameter_snapshot_hash = 'bd09e598c82db96e47459d77fd11e7c8'
         AND r.profile_snapshot_hash = '462cbd2ed92f68e5bdecf6b17537a973'
         AND r.source_snapshot_hash = '93c3d1368fb2450ab4a08e2b721f92d3'
         AND h.population_hash = '9b706c926260a3ef1ae8ac95eed5d0bf'
         AND h.application_hash = '01485256b9b5748fb412743d35ced602'
         AND h.source_quality_hash = 'de56a458d9ec0b344886850592c4e6c8'
         AND h.verification_hash = '604a5640a25da92a850840dbe13e3d56'
         AND h.cashflow_hash = '7c25acac533179f42789a6daa79d0cc3'
         AND h.capacity_hash = 'a91e82a315305a98953d013043a17d9a'
         AND h.resilience_hash = 'd219b2a0cb6d32f400b1ab71be6521fb'
         AND sc.risk_snapshot_table_exists
         AND sc.risk_component_table_exists
         AND sc.lineage_view_exists
         AND sc.active_component_codes = 7
        THEN 'PASS'
        ELSE 'FAIL'
    END AS preflight_status
FROM run_context r
CROSS JOIN passed_gates g
CROSS JOIN policy p
CROSS JOIN scenario_scope s
CROSS JOIN input_counts i
CROSS JOIN target_counts t
CROSS JOIN stage_boundary b
CROSS JOIN accepted_hashes h
CROSS JOIN schema_state sc;
