/* ============================================================================
MSBF M1.9 As-of Cash-Flow Feature Engineering — Preflight Validation
Version : v0.2R5
Purpose : Confirm the accepted M1.8 state, M1.9 schema/policy readiness,
          accepted scenario/source inputs, feature definitions, and empty targets.
============================================================================ */
WITH ctx AS (
    SELECT run_id,run_status,population_id,as_of_date,
           parameter_snapshot_hash,profile_snapshot_hash,source_snapshot_hash
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), gates AS (
    SELECT count(*) AS gate_count,
           count(*) FILTER(WHERE result_status='PASS') AS gate_passes
    FROM (
        SELECT DISTINCT ON(gate_id) gate_id,result_status
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id=(SELECT run_id FROM ctx)
          AND gate_id IN (
            'G1_CONTROL_PLANE','M1_2_POPULATION','M1_3_APPLICATION_REQUEST',
            'M1_4_DAILY_POS_HISTORY','M1_5_DAILY_DEPOSIT_LIQUIDITY',
            'M1_6_MATCHED_SCENARIO_OVERLAYS','M1_7_SOURCE_QUALITY_CONFIDENCE',
            'M1_8_VERIFICATION_FRAUD_CONTINUITY'
          )
        ORDER BY gate_id,review_version DESC
    ) g
), pos_scenarios AS (
    SELECT scenario_id,count(*) AS pos_rows
    FROM msbf_m1.merchant_pos_daily_scenario
    WHERE generated_by_run_id=(SELECT run_id FROM ctx)
    GROUP BY scenario_id
), deposit_scenarios AS (
    SELECT scenario_id,count(*) AS deposit_rows
    FROM msbf_m1.merchant_deposit_daily_scenario
    WHERE generated_by_run_id=(SELECT run_id FROM ctx)
    GROUP BY scenario_id
), accepted_m1_6_scenarios AS (
    SELECT sr.scenario_id,sr.scenario_code,sr.scenario_version,
           ss.scenario_set_code,ss.scenario_set_version,
           p.pos_rows,d.deposit_rows
    FROM pos_scenarios p
    JOIN deposit_scenarios d USING(scenario_id)
    JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=p.scenario_id
    JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
    WHERE p.pos_rows=135000
      AND d.deposit_rows=135000
      AND ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS'
      AND ss.scenario_set_version=1
      AND ss.status='APPROVED'
      AND sr.status='APPROVED'
      AND sr.scenario_version=1
      AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY')
), scenarios AS (
    SELECT count(*) AS scenario_count,
           count(*) FILTER(WHERE scenario_code='BASELINE') AS baseline_count,
           count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_count
    FROM accepted_m1_6_scenarios
), sources AS (
    SELECT count(*) AS source_rows,
           count(*) FILTER(WHERE source_code='POS_DAILY') AS pos_rows,
           count(*) FILTER(WHERE source_code='DEPOSIT_DAILY') AS deposit_rows
    FROM msbf_m1.source_snapshot
    WHERE module1_run_id=(SELECT run_id FROM ctx)
), policy AS (
    SELECT count(*) AS policy_rows,
           count(*) FILTER(WHERE status='APPROVED'
             AND (profile_payload->>'generation_enabled')::boolean
             AND profile_payload->>'methodology_version'='M1_9_METHOD_V1'
             AND profile_payload->>'annualized_sales_basis'='PERSISTED_ROUNDED_90D_AVERAGE') AS ready_rows
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING' AND profile_version=1
), features AS (
    SELECT count(*) AS feature_rows,
           count(*) FILTER(WHERE active_flag) AS active_rows
    FROM msbf_m1.feature_definition
    WHERE feature_code IN ('AVG_DAILY_ELIGIBLE_SALES_7D','AVG_DAILY_ELIGIBLE_SALES_30D','AVG_DAILY_ELIGIBLE_SALES_60D','AVG_DAILY_ELIGIBLE_SALES_90D','ANNUALIZED_ELIGIBLE_SALES','SALES_GROWTH_7D_VS_30D','SALES_GROWTH_30D_VS_90D','DAILY_SALES_CV_30D','DAILY_SALES_CV_90D','ZERO_SALES_DAY_RATE_30D','ACTIVE_SALES_DAY_RATE_30D','SEASONALITY_INDEX_180D','LARGEST_30D_SHARE_180D','REFUND_RATE_30D','CHARGEBACK_RATE_30D','REVERSAL_RATE_30D','DEPOSIT_TO_ELIGIBLE_SALES_RATE_30D','POS_DEPOSIT_RECONCILIATION_RATE_30D','NEGATIVE_BALANCE_DAY_RATE_30D','NSF_COUNT_30D','AVERAGE_AVAILABLE_BALANCE_30D','MINIMUM_BALANCE_30D','CASH_FLOW_BUFFER_DAYS','PROCESSOR_OUTAGE_DAY_RATE_30D','PROCESSOR_DEGRADED_DAY_RATE_30D','SOURCE_CONFIDENCE_SCORE','SCENARIO_ELIGIBLE_SALES_DELTA_RATE_30D','SCENARIO_ELIGIBLE_SALES_DELTA_RATE_90D','SCENARIO_DEPOSIT_DELTA_RATE_30D','SCENARIO_WITHDRAWAL_DELTA_RATE_30D','SCENARIO_AVAILABLE_BALANCE_DELTA_RATE_30D','SCENARIO_NEGATIVE_BALANCE_RATE_DELTA_30D','SCENARIO_NSF_COUNT_DELTA_30D','SCENARIO_PROCESSOR_OUTAGE_RATE_DELTA_30D','SCENARIO_REFUND_RATE_DELTA_30D','SCENARIO_CHARGEBACK_RATE_DELTA_30D') AND feature_version=1
), boundaries AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot
        WHERE module1_run_id=(SELECT run_id FROM ctx)) AS snapshot_rows,
      (SELECT count(*) FROM msbf_m1.cashflow_feature_value
        WHERE module1_run_id=(SELECT run_id FROM ctx)) AS feature_value_rows,
      (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot
        WHERE module1_run_id=(SELECT run_id FROM ctx)) AS final_feature_rows,
      (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot
        WHERE module1_run_id=(SELECT run_id FROM ctx)) AS risk_rows,
      (SELECT count(*) FROM msbf_m1.module1_latest
        WHERE module1_run_id=(SELECT run_id FROM ctx)) AS latest_rows,
      (SELECT count(*) FROM msbf_m1.module1_archive
        WHERE module1_run_id=(SELECT run_id FROM ctx)) AS archive_rows
), errors AS (
    SELECT count(*) AS blocking_errors
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=(SELECT run_id FROM ctx) AND severity='BLOCKING'
)
SELECT
    current_database() AS database_name,
    current_user AS database_user,
    current_setting('server_version') AS postgresql_version,
    clock_timestamp() AS validation_timestamp,
    c.run_id,c.run_status,c.population_id,c.as_of_date,
    g.gate_count,g.gate_passes,
    (SELECT count(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=c.run_id) AS applications,
    (SELECT count(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=c.run_id) AS pos_scenario_rows,
    (SELECT count(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=c.run_id) AS deposit_scenario_rows,
    (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=c.run_id) AS m1_8_summary_rows,
    s.scenario_count,s.baseline_count,s.stress_count,
    so.source_rows,so.pos_rows,so.deposit_rows,
    p.policy_rows,p.ready_rows,
    f.feature_rows,f.active_rows,
    b.snapshot_rows,b.feature_value_rows,b.final_feature_rows,b.risk_rows,b.latest_rows,b.archive_rows,
    e.blocking_errors,
    CASE WHEN
        c.run_status='M1_8_ACCEPTED'
        AND g.gate_count=8 AND g.gate_passes=8
        AND (SELECT count(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=c.run_id)=750
        AND (SELECT count(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=c.run_id)=270000
        AND (SELECT count(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=c.run_id)=270000
        AND (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=c.run_id)=750
        AND s.scenario_count=2 AND s.baseline_count=1 AND s.stress_count=1
        AND so.source_rows=5250 AND so.pos_rows=750 AND so.deposit_rows=750
        AND p.policy_rows=1 AND p.ready_rows=1
        AND f.feature_rows=36 AND f.active_rows=36
        AND b.snapshot_rows=0 AND b.feature_value_rows=0
        AND b.final_feature_rows=0 AND b.risk_rows=0 AND b.latest_rows=0 AND b.archive_rows=0
        AND e.blocking_errors=0
      THEN 'PASS' ELSE 'FAIL' END AS preflight_status
FROM ctx c CROSS JOIN gates g CROSS JOIN scenarios s CROSS JOIN sources so
CROSS JOIN policy p CROSS JOIN features f CROSS JOIN boundaries b CROSS JOIN errors e;
