/* ============================================================================
MSBF M1.7 Source Quality & Data Confidence — Preflight Validation
Version : v0.2
Purpose : Confirm accepted G0–M1.6 state, complete effective source contracts
          and parameters, empty M1.7 targets, unchanged accepted identities,
          and monotonic source-quality controls before generation.
Performance : Read-only catalog/count checks; no daily-history reconstruction.
============================================================================ */
WITH r AS (
    SELECT run_id, run_status, population_id, as_of_date,
           parameter_snapshot_hash, profile_snapshot_hash, source_snapshot_hash
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
),
p AS (
    SELECT population_id, history_start_date, history_end_date,
           population_status, population_hash, merchant_count
    FROM msbf_m1.population_registry
    WHERE population_id=(SELECT population_id FROM r)
),
latest_gates AS (
    SELECT gate_id, result_status
    FROM (
        SELECT gate_id, result_status,
               row_number() OVER (PARTITION BY gate_id ORDER BY review_version DESC) AS rn
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id=(SELECT run_id FROM r)
    ) x
    WHERE rn=1
),
gate_summary AS (
    SELECT count(*) FILTER (
               WHERE gate_id IN (
                   'G1_CONTROL_PLANE',
                   'M1_2_POPULATION',
                   'M1_3_APPLICATION_REQUEST',
                   'M1_4_DAILY_POS_HISTORY',
                   'M1_5_DAILY_DEPOSIT_LIQUIDITY',
                   'M1_6_MATCHED_SCENARIO_OVERLAYS'
               )
           ) AS prerequisite_gates,
           count(*) FILTER (
               WHERE gate_id IN (
                   'G1_CONTROL_PLANE',
                   'M1_2_POPULATION',
                   'M1_3_APPLICATION_REQUEST',
                   'M1_4_DAILY_POS_HISTORY',
                   'M1_5_DAILY_DEPOSIT_LIQUIDITY',
                   'M1_6_MATCHED_SCENARIO_OVERLAYS'
               )
               AND result_status='PASS'
           ) AS prerequisite_passes
    FROM latest_gates
),
prm AS (
    SELECT count(*) AS scoped_rows,
           count(DISTINCT parameter_name) AS parameter_names,
           count(*) FILTER (
               WHERE NOT (resolved_value ? 'value_numeric')
                  OR (resolved_value->>'value_numeric') IS NULL
           ) AS missing_typed_values,
           count(*) FILTER (
               WHERE parameter_name='source_outage_probability'
                 AND (resolved_value->>'value_numeric')::numeric NOT BETWEEN 0 AND 1
           ) AS invalid_outage_rates
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=(SELECT run_id FROM r)
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
      )
),
thresholds AS (
    SELECT
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='pos_minimum_history_days' AND scope_key='GLOBAL') AS pos_min_days,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='deposit_minimum_history_days' AND scope_key='GLOBAL') AS deposit_min_days,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='source_freshness_pass_days' AND scope_key='GLOBAL') AS freshness_pass_days,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='source_freshness_warning_days' AND scope_key='GLOBAL') AS freshness_warning_days,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='source_completeness_pass_rate' AND scope_key='GLOBAL') AS completeness_pass_rate,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='source_completeness_warning_rate' AND scope_key='GLOBAL') AS completeness_warning_rate,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='pos_deposit_reconciliation_pass_rate' AND scope_key='GLOBAL') AS reconciliation_pass_rate,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='pos_deposit_reconciliation_warning_rate' AND scope_key='GLOBAL') AS reconciliation_warning_rate,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='missing_pos_source_confidence_penalty' AND scope_key='GLOBAL') AS missing_pos_penalty,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='missing_deposit_source_confidence_penalty' AND scope_key='GLOBAL') AS missing_deposit_penalty,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='source_conflict_manual_review_threshold' AND scope_key='GLOBAL') AS conflict_review_threshold
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=(SELECT run_id FROM r)
),
src AS (
    SELECT count(*) AS source_rows,
           count(DISTINCT rss.source_code) AS source_codes,
           count(*) FILTER (
               WHERE rss.quality_status='CONTRACT_READY_PRE_GENERATION'
                 AND sc.status='APPROVED'
                 AND sc.effective_start_date <= (SELECT as_of_date FROM r)
                 AND (sc.effective_end_date IS NULL OR sc.effective_end_date > (SELECT as_of_date FROM r))
                 AND rc.active_flag
           ) AS ready_effective_rows,
           count(*) FILTER (
               WHERE sc.required_history_days < 0
                  OR sc.minimum_completeness_rate NOT BETWEEN 0 AND 1
                  OR (sc.reconciliation_tolerance_rate IS NOT NULL
                      AND sc.reconciliation_tolerance_rate NOT BETWEEN 0 AND 1)
           ) AS invalid_contract_rows
    FROM msbf_ctl.run_source_snapshot rss
    JOIN msbf_ctl.source_contract sc
      ON sc.source_contract_id=rss.source_contract_id
    JOIN msbf_ref.source_code rc
      ON rc.source_code=rss.source_code
    WHERE rss.run_id=(SELECT run_id FROM r)
),
src_set AS (
    SELECT string_agg(source_code,',' ORDER BY source_code) AS source_codes
    FROM msbf_ctl.run_source_snapshot
    WHERE run_id=(SELECT run_id FROM r)
),
rows AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.merchant_application
          WHERE created_by_run_id=(SELECT run_id FROM r)) AS applications,
        (SELECT count(*) FROM msbf_m1.merchant_pos_daily_base
          WHERE generated_by_run_id=(SELECT run_id FROM r)) AS pos_rows,
        (SELECT count(*) FROM msbf_m1.merchant_deposit_daily_base
          WHERE generated_by_run_id=(SELECT run_id FROM r)) AS deposit_rows,
        (SELECT count(*) FROM msbf_m1.merchant_pos_daily_scenario
          WHERE generated_by_run_id=(SELECT run_id FROM r)) AS pos_scenario_rows,
        (SELECT count(*) FROM msbf_m1.merchant_deposit_daily_scenario
          WHERE generated_by_run_id=(SELECT run_id FROM r)) AS deposit_scenario_rows,
        (SELECT count(*) FROM msbf_m1.source_snapshot
          WHERE module1_run_id=(SELECT run_id FROM r)) AS source_snapshot_rows,
        (SELECT count(*) FROM msbf_m1.application_obligation_snapshot
          WHERE created_by_run_id=(SELECT run_id FROM r)) AS obligation_rows,
        (SELECT count(*) FROM msbf_m1.collateral_availability_snapshot
          WHERE created_by_run_id=(SELECT run_id FROM r)) AS collateral_rows,
        (SELECT count(*) FROM msbf_m1.guarantee_availability_snapshot
          WHERE created_by_run_id=(SELECT run_id FROM r)) AS guarantee_rows,
        (SELECT count(*) FROM msbf_m1.application_business_credit_snapshot
          WHERE created_by_run_id=(SELECT run_id FROM r)) AS business_credit_rows,
        (SELECT count(*) FROM msbf_m1.application_owner_credit_snapshot
          WHERE created_by_run_id=(SELECT run_id FROM r)) AS owner_credit_rows,
        (SELECT count(*) FROM msbf_m1.verification_result
          WHERE created_by_run_id=(SELECT run_id FROM r)) AS verification_rows,
        (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot
          WHERE module1_run_id=(SELECT run_id FROM r)) AS feature_rows,
        (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot
          WHERE module1_run_id=(SELECT run_id FROM r)) AS risk_rows,
        (SELECT count(*) FROM msbf_m1.ead_path_snapshot
          WHERE module1_run_id=(SELECT run_id FROM r)) AS ead_rows,
        (SELECT count(*) FROM msbf_m1.module1_latest
          WHERE module1_run_id=(SELECT run_id FROM r)) AS latest_rows,
        (SELECT count(*) FROM msbf_m1.module1_archive
          WHERE module1_run_id=(SELECT run_id FROM r)) AS archive_rows
),
hashes AS (
    SELECT
        (SELECT metric_value_text FROM msbf_ctl.run_evidence
          WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_3_APPLICATION_SET_HASH') AS application_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence
          WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_4_POS_SET_HASH') AS pos_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence
          WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_5_DEPOSIT_SET_HASH') AS deposit_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence
          WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_6_COMBINED_SET_HASH') AS scenario_hash
),
errors AS (
    SELECT count(*) AS blocking_errors
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING'
)
SELECT
    r.run_id,
    r.run_status,
    p.population_status,
    r.as_of_date,
    p.history_start_date,
    p.history_end_date,
    gs.prerequisite_gates,
    gs.prerequisite_passes,
    prm.scoped_rows AS required_parameter_scope_rows,
    prm.parameter_names AS required_parameter_names,
    prm.missing_typed_values,
    prm.invalid_outage_rates,
    src.source_rows AS run_source_rows,
    src.source_codes AS distinct_source_codes,
    src.ready_effective_rows AS contract_ready_effective_sources,
    src.invalid_contract_rows,
    src_set.source_codes AS source_code_set,
    rows.*,
    thresholds.*,
    hashes.*,
    errors.blocking_errors,
    CASE
        WHEN r.run_status='M1_6_ACCEPTED'
         AND p.population_status='M1_2_ACCEPTED'
         AND gs.prerequisite_gates=6
         AND gs.prerequisite_passes=6
         AND r.parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
         AND r.profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
         AND r.source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3'
         AND p.population_hash='9b706c926260a3ef1ae8ac95eed5d0bf'
         AND hashes.application_hash='01485256b9b5748fb412743d35ced602'
         AND hashes.pos_hash='d1971e8d319483c187ec0c0483a31e33'
         AND hashes.deposit_hash='bbe96dd24fbbba3af4a587dd475a88d0'
         AND hashes.scenario_hash='3f85921bf6fc30ddc6cee146085e58c5'
         AND prm.scoped_rows=18
         AND prm.parameter_names=12
         AND prm.missing_typed_values=0
         AND prm.invalid_outage_rates=0
         AND src.source_rows=7
         AND src.source_codes=7
         AND src.ready_effective_rows=7
         AND src.invalid_contract_rows=0
         AND src_set.source_codes=
             'BUSINESS_CREDIT,COLLATERAL_AVAILABILITY,DEPOSIT_DAILY,OBLIGATIONS,OWNER_CREDIT,POS_DAILY,VERIFICATION'
         AND rows.applications=750
         AND rows.pos_rows=135000
         AND rows.deposit_rows=135000
         AND rows.pos_scenario_rows=270000
         AND rows.deposit_scenario_rows=270000
         AND rows.source_snapshot_rows=0
         AND rows.obligation_rows+rows.collateral_rows+rows.guarantee_rows+
             rows.business_credit_rows+rows.owner_credit_rows+rows.verification_rows+
             rows.feature_rows+rows.risk_rows+rows.ead_rows+rows.latest_rows+
             rows.archive_rows=0
         AND thresholds.pos_min_days>=1
         AND thresholds.deposit_min_days>=1
         AND thresholds.freshness_pass_days<=thresholds.freshness_warning_days
         AND thresholds.completeness_warning_rate<=thresholds.completeness_pass_rate
         AND thresholds.reconciliation_warning_rate<=thresholds.reconciliation_pass_rate
         AND thresholds.completeness_warning_rate BETWEEN 0 AND 1
         AND thresholds.completeness_pass_rate BETWEEN 0 AND 1
         AND thresholds.reconciliation_warning_rate BETWEEN 0 AND 1
         AND thresholds.reconciliation_pass_rate BETWEEN 0 AND 1
         AND thresholds.missing_pos_penalty BETWEEN 0 AND 1
         AND thresholds.missing_deposit_penalty BETWEEN 0 AND 1
         AND thresholds.conflict_review_threshold>=1
         AND errors.blocking_errors=0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS preflight_status
FROM r
CROSS JOIN p
CROSS JOIN gate_summary gs
CROSS JOIN prm
CROSS JOIN thresholds
CROSS JOIN src
CROSS JOIN src_set
CROSS JOIN rows
CROSS JOIN hashes
CROSS JOIN errors;
