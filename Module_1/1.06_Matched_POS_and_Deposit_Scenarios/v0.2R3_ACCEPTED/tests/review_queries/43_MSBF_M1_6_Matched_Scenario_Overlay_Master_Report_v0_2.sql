/**********************************************************************
MSBF M1.6 Matched POS and Deposit Scenario Overlay Master Report
Version : v0.2
Purpose : One-row live-execution and acceptance report for the matched
          BASELINE and RECESSION_ENERGY scenario panels, deterministic
          reproduction, direct/propagated stress effects, and stage controls.
**********************************************************************/
WITH ctx AS (
 SELECT r.*,p.population_status,p.population_hash,p.population_version,p.merchant_count,
        p.deterministic_seed_version,p.history_start_date,p.history_end_date,
        (p.history_end_date-p.history_start_date+1)::integer AS history_days
 FROM msbf_ctl.run_registry r
 JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
), gates AS (
 SELECT
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1) AS g1_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1) AS m12_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) AS m13_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_4_DAILY_POS_HISTORY' ORDER BY review_version DESC LIMIT 1) AS m14_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY' ORDER BY review_version DESC LIMIT 1) AS m15_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' ORDER BY review_version DESC LIMIT 1) AS m16_status,
  (SELECT review_version FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' ORDER BY review_version DESC LIMIT 1) AS m16_review_version,
  (SELECT reviewed_at FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' ORDER BY review_version DESC LIMIT 1) AS m16_reviewed_at,
  (SELECT finding FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' ORDER BY review_version DESC LIMIT 1) AS m16_finding
), g1_hashes AS (
 SELECT
  (SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key)) FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS parameter_hash,
  (SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code)) FROM msbf_ctl.run_profile_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS profile_hash,
  (SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code)) FROM msbf_ctl.run_source_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS source_hash
), upstream_hashes AS (
 SELECT
  (SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM ctx))) AS population_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM ctx))) AS application_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_4_actual_pos_snapshot((SELECT run_id FROM ctx))) AS base_pos_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_5_actual_deposit_snapshot((SELECT run_id FROM ctx))) AS base_deposit_hash
), scenario_profile AS (
 SELECT * FROM msbf_m1.m1_6_scenario_profile((SELECT run_id FROM ctx))
), pos_obs AS (
 SELECT sr.scenario_code,
        COUNT(*) AS pos_rows,COUNT(DISTINCT p.merchant_id) AS merchants,COUNT(DISTINCT p.observation_date) AS dates,
        MIN(p.observation_date) AS min_date,MAX(p.observation_date) AS max_date,
        SUM(p.gross_pos_sales) AS gross_sales,SUM(p.eligible_pos_sales) AS eligible_sales,
        SUM(p.refund_amount) AS refunds,SUM(p.chargeback_amount) AS chargebacks,
        SUM(p.processor_fee_amount) AS processor_fees,SUM(p.settlement_amount) AS settlements,
        SUM(p.net_merchant_proceeds) AS net_proceeds,
        COUNT(*) FILTER(WHERE p.zero_sales_day_flag) AS zero_sales_rows,
        COUNT(*) FILTER(WHERE p.processor_status='OUTAGE') AS outage_rows
 FROM msbf_m1.merchant_pos_daily_scenario p
 JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=p.scenario_id
 WHERE p.generated_by_run_id=(SELECT run_id FROM ctx)
 GROUP BY sr.scenario_code
), dep_obs AS (
 SELECT sr.scenario_code,
        COUNT(*) AS deposit_rows,COUNT(DISTINCT d.merchant_id) AS merchants,COUNT(DISTINCT d.observation_date) AS dates,
        SUM(d.deposit_amount) AS deposits,SUM(d.withdrawal_amount) AS withdrawals,
        SUM(d.nsf_count) AS nsf_events,COUNT(*) FILTER(WHERE d.negative_balance_flag) AS negative_balance_rows,
        MIN(d.minimum_balance) AS minimum_balance,
        SUM((d.scenario_overlay_payload->>'support_deposit_amount')::numeric) AS support_deposits
 FROM msbf_m1.merchant_deposit_daily_scenario d
 JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=d.scenario_id
 WHERE d.generated_by_run_id=(SELECT run_id FROM ctx)
 GROUP BY sr.scenario_code
), windows AS (
 SELECT
  COUNT(*) FILTER(WHERE scenario_code='RECESSION_ENERGY' AND shock_active_flag) AS direct_window_rows,
  COUNT(*) FILTER(WHERE scenario_code='RECESSION_ENERGY' AND propagation_active_flag) AS propagated_window_rows,
  MIN(observation_date) FILTER(WHERE scenario_code='RECESSION_ENERGY' AND shock_active_flag) AS direct_start_date,
  MIN(observation_date) FILTER(WHERE scenario_code='RECESSION_ENERGY' AND propagation_active_flag) AS propagation_start_date
 FROM msbf_m1.m1_6_pos_scenario_blueprint((SELECT run_id FROM ctx))
), industry AS (
 SELECT e.industry_code,
        1-SUM(e.gross_pos_sales)/NULLIF(SUM(b.gross_pos_sales),0) AS gross_sales_decline
 FROM msbf_m1.m1_6_pos_scenario_blueprint((SELECT run_id FROM ctx)) e
 JOIN msbf_m1.merchant_pos_daily_base b
   ON b.population_id=e.population_id AND b.merchant_id=e.merchant_id
  AND b.processor_account_id=e.processor_account_id AND b.observation_date=e.observation_date
 WHERE e.scenario_code='RECESSION_ENERGY' AND e.shock_active_flag
 GROUP BY e.industry_code
), canonical AS (
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.m1_6_expected_scenario_snapshot((SELECT run_id FROM ctx))) AS expected_rows,
  (SELECT COUNT(*) FROM msbf_m1.m1_6_actual_scenario_snapshot((SELECT run_id FROM ctx))) AS actual_rows,
  (SELECT COUNT(*) FROM msbf_m1.m1_6_expected_scenario_snapshot((SELECT run_id FROM ctx)) e
    FULL JOIN msbf_m1.m1_6_actual_scenario_snapshot((SELECT run_id FROM ctx)) a USING(entity_type,entity_key)
    WHERE e.row_hash IS DISTINCT FROM a.row_hash) AS mismatches,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_6_expected_scenario_snapshot((SELECT run_id FROM ctx)) WHERE entity_type='POS_SCENARIO') AS expected_pos_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_6_actual_scenario_snapshot((SELECT run_id FROM ctx)) WHERE entity_type='POS_SCENARIO') AS actual_pos_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_6_expected_scenario_snapshot((SELECT run_id FROM ctx)) WHERE entity_type='DEPOSIT_SCENARIO') AS expected_deposit_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_6_actual_scenario_snapshot((SELECT run_id FROM ctx)) WHERE entity_type='DEPOSIT_SCENARIO') AS actual_deposit_hash,
  (SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_6_expected_scenario_snapshot((SELECT run_id FROM ctx))) AS expected_combined_hash,
  (SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_6_actual_scenario_snapshot((SELECT run_id FROM ctx))) AS actual_combined_hash,
  (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM ctx) AND evidence_code='M1_6_POS_SCENARIO_SET_HASH' AND segment_key='PORTFOLIO') AS stored_pos_hash,
  (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM ctx) AND evidence_code='M1_6_DEPOSIT_SCENARIO_SET_HASH' AND segment_key='PORTFOLIO') AS stored_deposit_hash,
  (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM ctx) AND evidence_code='M1_6_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS stored_combined_hash
), evidence_obs AS (
 SELECT
  COUNT(*) FILTER(WHERE evidence_code ~ '^M1_6_POS_[0-9]{2}_') AS positive_checks,
  COUNT(*) FILTER(WHERE evidence_code ~ '^M1_6_POS_[0-9]{2}_' AND status='PASS') AS positive_passes,
  COUNT(*) FILTER(WHERE evidence_code LIKE 'M1_6_NEG_%') AS negative_controls,
  COUNT(*) FILTER(WHERE evidence_code LIKE 'M1_6_NEG_%' AND status='PASS') AS negative_passes,
  COUNT(*) FILTER(WHERE (evidence_code ~ '^M1_6_POS_[0-9]{2}_' OR evidence_code LIKE 'M1_6_NEG_%') AND status='FAIL') AS failed_evidence
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM ctx)
), downstream AS (
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM ctx)) AS downstream_rows
), errors AS (
 SELECT COUNT(*) AS blocking_errors FROM msbf_ctl.profile_resolution_error
 WHERE run_id=(SELECT run_id FROM ctx) AND severity='BLOCKING'
)
SELECT
 clock_timestamp() AS report_timestamp,current_database() AS database_name,current_user AS database_user,
 current_setting('server_version') AS postgresql_version,
 ctx.run_id,ctx.run_code,ctx.run_version,ctx.run_status,ctx.as_of_date,ctx.population_id,
 ctx.population_version,ctx.population_status,ctx.merchant_count AS planned_merchants,
 ctx.history_start_date,ctx.history_end_date,ctx.history_days,ctx.deterministic_seed_version,
 gates.g1_status,gates.m12_status,gates.m13_status,gates.m14_status,gates.m15_status,gates.m16_status,
 gates.m16_review_version,gates.m16_reviewed_at,gates.m16_finding,
 ctx.parameter_snapshot_hash,g1_hashes.parameter_hash AS recomputed_parameter_hash,
 ctx.profile_snapshot_hash,g1_hashes.profile_hash AS recomputed_profile_hash,
 ctx.source_snapshot_hash,g1_hashes.source_hash AS recomputed_source_hash,
 ctx.population_hash,upstream_hashes.population_hash AS recomputed_population_hash,
 upstream_hashes.application_hash,upstream_hashes.base_pos_hash,upstream_hashes.base_deposit_hash,
 (SELECT COUNT(*) FROM scenario_profile) AS approved_scenarios,
 (SELECT shock_start_date FROM scenario_profile WHERE scenario_code='RECESSION_ENERGY') AS stress_start_date,
 (SELECT propagation_start_date FROM scenario_profile WHERE scenario_code='RECESSION_ENERGY') AS propagation_start_date,
 windows.direct_window_rows,windows.propagated_window_rows,
 (SELECT pos_rows FROM pos_obs WHERE scenario_code='BASELINE') AS baseline_pos_rows,
 (SELECT pos_rows FROM pos_obs WHERE scenario_code='RECESSION_ENERGY') AS stress_pos_rows,
 (SELECT deposit_rows FROM dep_obs WHERE scenario_code='BASELINE') AS baseline_deposit_rows,
 (SELECT deposit_rows FROM dep_obs WHERE scenario_code='RECESSION_ENERGY') AS stress_deposit_rows,
 (SELECT gross_sales FROM pos_obs WHERE scenario_code='BASELINE') AS baseline_gross_sales,
 (SELECT gross_sales FROM pos_obs WHERE scenario_code='RECESSION_ENERGY') AS stress_gross_sales,
 1-(SELECT gross_sales FROM pos_obs WHERE scenario_code='RECESSION_ENERGY')/NULLIF((SELECT gross_sales FROM pos_obs WHERE scenario_code='BASELINE'),0) AS gross_sales_decline_rate,
 (SELECT eligible_sales FROM pos_obs WHERE scenario_code='BASELINE') AS baseline_eligible_sales,
 (SELECT eligible_sales FROM pos_obs WHERE scenario_code='RECESSION_ENERGY') AS stress_eligible_sales,
 (SELECT refunds/NULLIF(gross_sales,0) FROM pos_obs WHERE scenario_code='BASELINE') AS baseline_refund_rate,
 (SELECT refunds/NULLIF(gross_sales,0) FROM pos_obs WHERE scenario_code='RECESSION_ENERGY') AS stress_refund_rate,
 (SELECT chargebacks/NULLIF(gross_sales,0) FROM pos_obs WHERE scenario_code='BASELINE') AS baseline_chargeback_rate,
 (SELECT chargebacks/NULLIF(gross_sales,0) FROM pos_obs WHERE scenario_code='RECESSION_ENERGY') AS stress_chargeback_rate,
 (SELECT outage_rows::numeric/NULLIF(pos_rows,0) FROM pos_obs WHERE scenario_code='BASELINE') AS baseline_outage_share,
 (SELECT outage_rows::numeric/NULLIF(pos_rows,0) FROM pos_obs WHERE scenario_code='RECESSION_ENERGY') AS stress_outage_share,
 (SELECT deposits FROM dep_obs WHERE scenario_code='BASELINE') AS baseline_deposits,
 (SELECT deposits FROM dep_obs WHERE scenario_code='RECESSION_ENERGY') AS stress_deposits,
 (SELECT withdrawals FROM dep_obs WHERE scenario_code='BASELINE') AS baseline_withdrawals,
 (SELECT withdrawals FROM dep_obs WHERE scenario_code='RECESSION_ENERGY') AS stress_withdrawals,
 (SELECT nsf_events FROM dep_obs WHERE scenario_code='BASELINE') AS baseline_nsf_events,
 (SELECT nsf_events FROM dep_obs WHERE scenario_code='RECESSION_ENERGY') AS stress_nsf_events,
 (SELECT negative_balance_rows::numeric/NULLIF(deposit_rows,0) FROM dep_obs WHERE scenario_code='BASELINE') AS baseline_negative_balance_share,
 (SELECT negative_balance_rows::numeric/NULLIF(deposit_rows,0) FROM dep_obs WHERE scenario_code='RECESSION_ENERGY') AS stress_negative_balance_share,
 (SELECT support_deposits FROM dep_obs WHERE scenario_code='RECESSION_ENERGY') AS stress_support_deposits,
 (SELECT gross_sales_decline FROM industry WHERE industry_code='ENERGY_SERVICES') AS energy_gross_sales_decline,
 (SELECT gross_sales_decline FROM industry WHERE industry_code='HEALTHCARE_SERVICES') AS healthcare_gross_sales_decline,
 canonical.expected_rows,canonical.actual_rows,canonical.mismatches,
 canonical.stored_pos_hash,canonical.expected_pos_hash,canonical.actual_pos_hash,
 canonical.stored_deposit_hash,canonical.expected_deposit_hash,canonical.actual_deposit_hash,
 canonical.stored_combined_hash,canonical.expected_combined_hash,canonical.actual_combined_hash,
 evidence_obs.positive_checks,evidence_obs.positive_passes,evidence_obs.negative_controls,evidence_obs.negative_passes,
 evidence_obs.failed_evidence,downstream.downstream_rows,errors.blocking_errors,
 CASE WHEN ctx.run_status='M1_6_ACCEPTED' AND gates.g1_status='PASS' AND gates.m12_status='PASS'
            AND gates.m13_status='PASS' AND gates.m14_status='PASS' AND gates.m15_status='PASS' AND gates.m16_status='PASS'
            AND (SELECT pos_rows FROM pos_obs WHERE scenario_code='BASELINE')=135000
            AND (SELECT pos_rows FROM pos_obs WHERE scenario_code='RECESSION_ENERGY')=135000
            AND (SELECT deposit_rows FROM dep_obs WHERE scenario_code='BASELINE')=135000
            AND (SELECT deposit_rows FROM dep_obs WHERE scenario_code='RECESSION_ENERGY')=135000
            AND canonical.expected_rows=540000 AND canonical.actual_rows=540000 AND canonical.mismatches=0
            AND canonical.stored_pos_hash=canonical.expected_pos_hash AND canonical.stored_pos_hash=canonical.actual_pos_hash
            AND canonical.stored_deposit_hash=canonical.expected_deposit_hash AND canonical.stored_deposit_hash=canonical.actual_deposit_hash
            AND canonical.stored_combined_hash=canonical.expected_combined_hash AND canonical.stored_combined_hash=canonical.actual_combined_hash
            AND evidence_obs.positive_checks=62 AND evidence_obs.positive_passes=62
            AND evidence_obs.negative_controls=5 AND evidence_obs.negative_passes=5 AND evidence_obs.failed_evidence=0
            AND downstream.downstream_rows=0 AND errors.blocking_errors=0
      THEN 'PASS' ELSE 'FAIL' END AS overall_m1_6_status
FROM ctx CROSS JOIN gates CROSS JOIN g1_hashes CROSS JOIN upstream_hashes CROSS JOIN windows
CROSS JOIN canonical CROSS JOIN evidence_obs CROSS JOIN downstream CROSS JOIN errors;
