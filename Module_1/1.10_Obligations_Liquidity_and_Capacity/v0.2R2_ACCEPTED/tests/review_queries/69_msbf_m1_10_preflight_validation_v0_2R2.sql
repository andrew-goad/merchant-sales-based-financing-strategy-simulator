/* M1.10 final clean-build package revision v0.2R2; corrected M1.2 population-hash source. */
/* ============================================================================
MSBF M1.10 Obligations, Liquidity & Residual Cash Flow — Preflight Validation
Version : v0.2R1
Purpose : Prove that the accepted M1.9 state, governed M1.10 policy, obligation
          source evidence, scenario feature population and empty target state
          are ready for deterministic generation.
============================================================================ */
WITH r AS (
    SELECT run_id,run_status,population_id,as_of_date,
           parameter_snapshot_hash,profile_snapshot_hash,source_snapshot_hash
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), gates AS (
    SELECT count(*) AS passed_gates
    FROM (
        SELECT DISTINCT ON(gate_id) gate_id,result_status
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id=(SELECT run_id FROM r)
          AND gate_id IN ('G1_CONTROL_PLANE','M1_2_POPULATION','M1_3_APPLICATION_REQUEST',
                          'M1_4_DAILY_POS_HISTORY','M1_5_DAILY_DEPOSIT_LIQUIDITY',
                          'M1_6_MATCHED_SCENARIO_OVERLAYS','M1_7_SOURCE_QUALITY_CONFIDENCE',
                          'M1_8_VERIFICATION_FRAUD_CONTINUITY','M1_9_ASOF_CASHFLOW_FEATURES')
        ORDER BY gate_id,review_version DESC
    ) x WHERE result_status='PASS'
), p AS (
    SELECT policy_profile_id,status,profile_payload,
           profile_payload->>'methodology_version' AS methodology_version
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY' AND profile_version=1
), s AS (
    SELECT count(DISTINCT f.scenario_id) AS scenario_count,
           count(DISTINCT f.scenario_id) FILTER(WHERE sr.scenario_code='BASELINE') AS baseline_count,
           count(DISTINCT f.scenario_id) FILTER(WHERE sr.scenario_code='RECESSION_ENERGY') AS stress_count,
           count(*) AS feature_snapshot_rows,
           count(DISTINCT f.merchant_application_id) AS feature_applications
    FROM msbf_m1.application_cashflow_feature_snapshot f
    JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=f.scenario_id
    JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
    WHERE f.module1_run_id=(SELECT run_id FROM r)
      AND ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS'
      AND ss.scenario_set_version=1 AND ss.status='APPROVED'
      AND sr.status='APPROVED' AND sr.scenario_version=1
), inputs AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)) AS applications,
      (SELECT count(*) FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)) AS relationships,
      (SELECT count(*) FROM msbf_m1.merchant_industry_assignment WHERE created_by_run_id=(SELECT run_id FROM r) AND assignment_type='PRIMARY') AS industries,
      (SELECT count(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM r) AND source_code='OBLIGATIONS') AS obligation_sources,
      (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS verification_summaries,
      (SELECT count(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)) AS obligation_rows,
      (SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS capacity_rows,
      (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors,
      (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS risk_rows,
      (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS ead_rows,
      (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r)) AS latest_rows,
      (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS archive_rows
) , population AS (
    SELECT pr.population_hash AS m12_hash
    FROM msbf_m1.population_registry pr
    WHERE pr.population_id=(SELECT population_id FROM r)
), hashes AS (
    SELECT
      max(metric_value_text) FILTER(WHERE evidence_code='M1_9_COMBINED_SET_HASH') AS m19_hash,
      max(metric_value_text) FILTER(WHERE evidence_code='M1_8_COMBINED_SET_HASH') AS m18_hash,
      max(metric_value_text) FILTER(WHERE evidence_code='M1_7_SOURCE_SET_HASH') AS m17_hash,
      max(metric_value_text) FILTER(WHERE evidence_code='M1_6_COMBINED_SET_HASH') AS m16_hash,
      max(metric_value_text) FILTER(WHERE evidence_code='M1_5_DEPOSIT_SET_HASH') AS m15_hash,
      max(metric_value_text) FILTER(WHERE evidence_code='M1_4_POS_SET_HASH') AS m14_hash,
      max(metric_value_text) FILTER(WHERE evidence_code='M1_3_APPLICATION_SET_HASH') AS m13_hash
    FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
), schema_check AS (
    SELECT
      to_regclass('msbf_m1.application_liquidity_capacity_snapshot') IS NOT NULL AS capacity_table_exists,
      to_regclass('msbf_m1.v_m1_10_capacity_lineage') IS NOT NULL AS lineage_view_exists,
      (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m1'
         AND table_name='application_obligation_snapshot'
         AND column_name IN ('obligation_status','payment_frequency','maturity_date','secured_flag',
                             'data_confidence_score','obligation_quality_status','obligation_reason_code','row_hash','created_at')) AS obligation_extension_columns
)
SELECT
    clock_timestamp() AS execution_timestamp,
    current_database() AS database_name,
    current_user AS database_user,
    current_setting('server_version') AS postgresql_version,
    r.run_id,r.run_status,r.population_id,r.as_of_date,
    gates.passed_gates,
    s.scenario_count,s.baseline_count,s.stress_count,s.feature_snapshot_rows,s.feature_applications,
    inputs.applications,inputs.relationships,inputs.industries,inputs.obligation_sources,
    inputs.verification_summaries,inputs.obligation_rows,inputs.capacity_rows,
    inputs.risk_rows,inputs.ead_rows,inputs.latest_rows,inputs.archive_rows,inputs.blocking_errors,
    p.policy_profile_id,p.status AS policy_status,p.methodology_version,
    schema_check.capacity_table_exists,schema_check.lineage_view_exists,schema_check.obligation_extension_columns,
    r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,
    population.m12_hash,hashes.m13_hash,hashes.m14_hash,hashes.m15_hash,
    hashes.m16_hash,hashes.m17_hash,hashes.m18_hash,hashes.m19_hash,
    CASE WHEN current_database()='msbf_strategy'
          AND r.run_status='M1_9_ACCEPTED'
          AND gates.passed_gates=9
          AND s.scenario_count=2 AND s.baseline_count=1 AND s.stress_count=1
          AND s.feature_snapshot_rows=1500 AND s.feature_applications=750
          AND inputs.applications=750 AND inputs.relationships=750 AND inputs.industries=750
          AND inputs.obligation_sources=750 AND inputs.verification_summaries=750
          AND inputs.obligation_rows=0 AND inputs.capacity_rows=0
          AND inputs.risk_rows=0 AND inputs.ead_rows=0 AND inputs.latest_rows=0 AND inputs.archive_rows=0
          AND inputs.blocking_errors=0
          AND p.status='APPROVED' AND p.methodology_version='M1_10_METHOD_V1'
          AND coalesce((p.profile_payload->>'generation_enabled')::boolean,false)
          AND schema_check.capacity_table_exists AND schema_check.lineage_view_exists
          AND schema_check.obligation_extension_columns=9
          AND r.parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
          AND r.profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
          AND r.source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3'
          AND population.m12_hash='9b706c926260a3ef1ae8ac95eed5d0bf'
          AND hashes.m13_hash='01485256b9b5748fb412743d35ced602'
          AND hashes.m14_hash='d1971e8d319483c187ec0c0483a31e33'
          AND hashes.m15_hash='bbe96dd24fbbba3af4a587dd475a88d0'
          AND hashes.m16_hash='3f85921bf6fc30ddc6cee146085e58c5'
          AND hashes.m17_hash='de56a458d9ec0b344886850592c4e6c8'
          AND hashes.m18_hash='604a5640a25da92a850840dbe13e3d56'
          AND hashes.m19_hash='7c25acac533179f42789a6daa79d0cc3'
         THEN 'PASS' ELSE 'FAIL' END AS preflight_status
FROM r CROSS JOIN gates CROSS JOIN p CROSS JOIN s CROSS JOIN inputs CROSS JOIN population CROSS JOIN hashes CROSS JOIN schema_check;
