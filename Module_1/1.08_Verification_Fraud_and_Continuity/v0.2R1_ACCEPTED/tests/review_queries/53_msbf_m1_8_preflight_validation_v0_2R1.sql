/* ============================================================================
MSBF M1.8 Verification, Fraud & Processor Continuity — Preflight Validation
Version : v0.2R1
Purpose : Confirm accepted M1.7 state, approved corrected M1.8 methodology, complete
          source-quality and fraud parameters, empty M1.8 targets, unchanged
          accepted identities, and strict downstream stage boundaries.
Performance: Read-only bounded checks; no daily blueprint reconstruction.
============================================================================ */
WITH r AS (
    SELECT run_id,run_status,population_id,as_of_date,
           parameter_snapshot_hash,profile_snapshot_hash,source_snapshot_hash
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
),
p AS (
    SELECT population_id,population_status,population_hash,merchant_count,
           history_start_date,history_end_date
    FROM msbf_m1.population_registry
    WHERE population_id=(SELECT population_id FROM r)
),
latest_gates AS (
    SELECT gate_id,result_status
    FROM (
        SELECT gate_id,result_status,
               row_number() OVER(PARTITION BY gate_id ORDER BY review_version DESC) AS rn
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id=(SELECT run_id FROM r)
    ) x
    WHERE rn=1
),
gates AS (
    SELECT count(*) FILTER (WHERE gate_id IN (
               'G1_CONTROL_PLANE','M1_2_POPULATION','M1_3_APPLICATION_REQUEST',
               'M1_4_DAILY_POS_HISTORY','M1_5_DAILY_DEPOSIT_LIQUIDITY',
               'M1_6_MATCHED_SCENARIO_OVERLAYS','M1_7_SOURCE_QUALITY_CONFIDENCE'
           )) AS prerequisite_gates,
           count(*) FILTER (WHERE gate_id IN (
               'G1_CONTROL_PLANE','M1_2_POPULATION','M1_3_APPLICATION_REQUEST',
               'M1_4_DAILY_POS_HISTORY','M1_5_DAILY_DEPOSIT_LIQUIDITY',
               'M1_6_MATCHED_SCENARIO_OVERLAYS','M1_7_SOURCE_QUALITY_CONFIDENCE'
           ) AND result_status='PASS') AS prerequisite_passes
    FROM latest_gates
),
prm AS (
    SELECT count(*) AS scoped_rows,
           count(DISTINCT parameter_name) AS parameter_names,
           count(*) FILTER (
               WHERE parameter_name IN ('verification_hard_stop_check','verification_review_check')
                 AND (NOT (resolved_value ? 'value_boolean') OR resolved_value->>'value_boolean' IS NULL)
           ) AS missing_boolean_values,
           count(*) FILTER (
               WHERE parameter_name NOT IN ('verification_hard_stop_check','verification_review_check')
                 AND (NOT (resolved_value ? 'value_numeric') OR resolved_value->>'value_numeric' IS NULL)
           ) AS missing_numeric_values
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=(SELECT run_id FROM r)
      AND (
          (scope_key='GLOBAL' AND parameter_name IN (
              'fraud_base_probability','bank_account_mismatch_fraud_points',
              'processor_mismatch_fraud_points','identity_conflict_fraud_points',
              'abnormal_refund_fraud_points','abnormal_chargeback_fraud_points',
              'fraud_tier_2_threshold','fraud_tier_3_threshold',
              'fraud_tier_4_threshold','fraud_tier_5_threshold'
          ))
          OR (
              scope_key LIKE 'VERIFICATION_CHECK:%'
              AND parameter_name IN ('verification_hard_stop_check','verification_review_check')
          )
      )
),
thresholds AS (
    SELECT
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='fraud_base_probability' AND scope_key='GLOBAL') AS fraud_base_probability,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='bank_account_mismatch_fraud_points' AND scope_key='GLOBAL') AS bank_points,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='processor_mismatch_fraud_points' AND scope_key='GLOBAL') AS processor_points,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='identity_conflict_fraud_points' AND scope_key='GLOBAL') AS identity_points,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='abnormal_refund_fraud_points' AND scope_key='GLOBAL') AS refund_points,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='abnormal_chargeback_fraud_points' AND scope_key='GLOBAL') AS chargeback_points,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='fraud_tier_2_threshold' AND scope_key='GLOBAL') AS tier2,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='fraud_tier_3_threshold' AND scope_key='GLOBAL') AS tier3,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='fraud_tier_4_threshold' AND scope_key='GLOBAL') AS tier4,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='fraud_tier_5_threshold' AND scope_key='GLOBAL') AS tier5
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=(SELECT run_id FROM r)
),
checks AS (
    SELECT count(*) AS active_checks,
           string_agg(check_code,',' ORDER BY check_code) AS check_set
    FROM msbf_ref.verification_check_code
    WHERE active_flag
),
policy AS (
    SELECT policy_profile_id,status,effective_start_date,effective_end_date,
           profile_payload,md5(profile_payload::text) AS policy_hash,
           (profile_payload->>'generation_enabled')::boolean AS generation_enabled,
           profile_payload->>'methodology_version' AS methodology_version,
           coalesce((profile_payload->>'stress_continuity_tier_floor_to_baseline')::boolean,false) AS stress_floor_enabled,
           count(*) OVER() AS policy_rows
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY'
      AND profile_version=1
),
policy_keys AS (
    SELECT count(*) AS present_keys
    FROM policy p
    CROSS JOIN LATERAL jsonb_object_keys(p.profile_payload) k
    WHERE k IN (
        'generation_enabled','methodology_version','stress_continuity_tier_floor_to_baseline','recent_window_days',
        'kyb_fail_multiplier','beneficial_owner_fail_multiplier','sanctions_fail_multiplier',
        'bank_account_mismatch_multiplier','processor_mismatch_multiplier',
        'identity_conflict_multiplier','review_band_multiplier',
        'refund_rate_multiplier_threshold','refund_rate_absolute_floor',
        'chargeback_rate_multiplier_threshold','chargeback_rate_absolute_floor',
        'continuity_tier_2_degraded_rate','continuity_tier_3_degraded_rate','continuity_tier_4_degraded_rate',
        'continuity_tier_2_outage_rate','continuity_tier_3_outage_rate','continuity_tier_4_outage_rate',
        'continuity_tier_2_connection_gap_rate','continuity_tier_3_connection_gap_rate','continuity_tier_4_connection_gap_rate',
        'continuity_tier_2_recent_outage_rate','continuity_tier_3_recent_outage_rate','continuity_tier_4_recent_outage_rate',
        'manual_review_fraud_tier','hard_stop_fraud_tier',
        'manual_review_continuity_tier','hard_stop_continuity_tier'
    )
),
rows AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)) AS applications,
        (SELECT count(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS source_rows,
        (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS source_applications,
        (SELECT count(DISTINCT source_code) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS source_families,
        (SELECT count(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r)) AS pos_rows,
        (SELECT count(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM r)) AS scenario_pos_rows,
        (SELECT count(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM r)) AS verification_rows,
        (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS summary_rows,
        (SELECT count(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)) AS obligation_rows,
        (SELECT count(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)) AS collateral_rows,
        (SELECT count(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)) AS guarantee_rows,
        (SELECT count(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)) AS business_credit_rows,
        (SELECT count(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)) AS owner_credit_rows,
        (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS feature_rows,
        (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS risk_rows,
        (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS ead_rows,
        (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r)) AS latest_rows,
        (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS archive_rows
),
hashes AS (
    SELECT
        (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_3_APPLICATION_SET_HASH') AS application_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_4_POS_SET_HASH') AS pos_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_5_DEPOSIT_SET_HASH') AS deposit_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_6_COMBINED_SET_HASH') AS scenario_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_7_SOURCE_SET_HASH') AS source_quality_hash
),
source_hash AS (
    SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS recomputed_hash
    FROM msbf_m1.m1_7_actual_source_snapshot((SELECT run_id FROM r))
),
errors AS (
    SELECT count(*) AS blocking_errors
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING'
)
SELECT
    r.run_id,r.run_status,p.population_status,r.as_of_date,p.history_start_date,p.history_end_date,
    g.prerequisite_gates,g.prerequisite_passes,
    prm.scoped_rows AS required_parameter_rows,prm.parameter_names AS required_parameter_names,
    prm.missing_boolean_values,prm.missing_numeric_values,
    checks.active_checks,checks.check_set,
    policy.policy_profile_id,policy.status AS policy_status,policy.policy_hash,
    policy.generation_enabled,policy.methodology_version,policy.stress_floor_enabled,policy.policy_rows,
    policy_keys.present_keys AS policy_keys_present,
    rows.*,thresholds.*,hashes.*,source_hash.recomputed_hash AS recomputed_source_quality_hash,
    errors.blocking_errors,
    CASE
        WHEN r.run_status='M1_7_ACCEPTED'
         AND p.population_status='M1_2_ACCEPTED'
         AND g.prerequisite_gates=7 AND g.prerequisite_passes=7
         AND r.parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
         AND r.profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
         AND r.source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3'
         AND p.population_hash='9b706c926260a3ef1ae8ac95eed5d0bf'
         AND hashes.application_hash='01485256b9b5748fb412743d35ced602'
         AND hashes.pos_hash='d1971e8d319483c187ec0c0483a31e33'
         AND hashes.deposit_hash='bbe96dd24fbbba3af4a587dd475a88d0'
         AND hashes.scenario_hash='3f85921bf6fc30ddc6cee146085e58c5'
         AND hashes.source_quality_hash='de56a458d9ec0b344886850592c4e6c8'
         AND source_hash.recomputed_hash=hashes.source_quality_hash
         AND prm.scoped_rows=22 AND prm.parameter_names=12
         AND prm.missing_boolean_values=0 AND prm.missing_numeric_values=0
         AND thresholds.fraud_base_probability BETWEEN 0 AND 1
         AND thresholds.bank_points>=0 AND thresholds.processor_points>=0
         AND thresholds.identity_points>=0 AND thresholds.refund_points>=0 AND thresholds.chargeback_points>=0
         AND thresholds.tier2<thresholds.tier3 AND thresholds.tier3<thresholds.tier4 AND thresholds.tier4<thresholds.tier5
         AND thresholds.tier2>=0 AND thresholds.tier5<=100
         AND checks.active_checks=6
         AND checks.check_set='BANK_ACCOUNT_MATCH,BENEFICIAL_OWNER,FRAUD_SCREEN,KYB_ENTITY,PROCESSOR_MATCH,SANCTIONS'
         AND policy.policy_rows=1 AND policy.status='APPROVED'
         AND policy.effective_start_date<=r.as_of_date
         AND (policy.effective_end_date IS NULL OR policy.effective_end_date>r.as_of_date)
         AND policy.generation_enabled
         AND policy.methodology_version='M1_8_METHOD_V1_1'
         AND policy.stress_floor_enabled
         AND policy_keys.present_keys=31
         AND rows.applications=750 AND rows.source_rows=5250
         AND rows.source_applications=750 AND rows.source_families=7
         AND rows.pos_rows=135000 AND rows.scenario_pos_rows=270000
         AND rows.verification_rows=0 AND rows.summary_rows=0
         AND rows.obligation_rows+rows.collateral_rows+rows.guarantee_rows+
             rows.business_credit_rows+rows.owner_credit_rows+rows.feature_rows+
             rows.risk_rows+rows.ead_rows+rows.latest_rows+rows.archive_rows=0
         AND errors.blocking_errors=0
        THEN 'PASS' ELSE 'FAIL'
    END AS preflight_status
FROM r CROSS JOIN p CROSS JOIN gates g CROSS JOIN prm CROSS JOIN thresholds
CROSS JOIN checks CROSS JOIN policy CROSS JOIN policy_keys CROSS JOIN rows
CROSS JOIN hashes CROSS JOIN source_hash CROSS JOIN errors;
