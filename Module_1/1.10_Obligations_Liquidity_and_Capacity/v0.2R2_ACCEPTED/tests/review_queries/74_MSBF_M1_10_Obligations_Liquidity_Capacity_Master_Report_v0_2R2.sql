/* ============================================================================
MSBF M1.10 Obligations, Liquidity & Residual Cash Flow — Master Report
Version : v0.2R2
Purpose : One-row executive and validation evidence after formal acceptance.
============================================================================ */
WITH r AS (
 SELECT run_id,run_status,population_id,as_of_date FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), gate AS (
 SELECT * FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r)
 AND gate_id='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY' ORDER BY review_version DESC LIMIT 1
), e AS (
 SELECT max(metric_value_text) FILTER(WHERE evidence_code='M1_10_OBLIGATION_SET_HASH') obligation_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_10_CAPACITY_SET_HASH') capacity_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_10_COMBINED_SET_HASH') combined_hash,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_10_POS_%') positive_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_10_POS_%' AND status='PASS') positive_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_10_NEG_%') negative_controls,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_10_NEG_%' AND status='PASS') negative_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_10_%' AND status='FAIL') failed_evidence
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
), ob AS (
 SELECT count(*) obligation_rows,count(DISTINCT merchant_application_id) obligation_applications,
        count(*) FILTER(WHERE short_term_financing_flag) short_term_rows,
        round(sum(outstanding_balance),2) total_outstanding_balance,
        round(sum(daily_payment_amount),2) total_daily_payment
 FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)
), c AS (
 SELECT count(*) capacity_rows,count(DISTINCT merchant_application_id) applications,count(DISTINCT scenario_id) scenarios,
        count(*) FILTER(WHERE affordability_status='AFFORDABLE') affordable_rows,
        count(*) FILTER(WHERE affordability_status='MARGINAL') marginal_rows,
        count(*) FILTER(WHERE affordability_status='UNAFFORDABLE') unaffordable_rows,
        count(*) FILTER(WHERE affordability_status='INSUFFICIENT_EVIDENCE') insufficient_rows,
        count(*) FILTER(WHERE manual_review_recommended_flag) manual_review_rows,
        round(avg(sales_linked_payment_coverage_ratio),6) avg_coverage,
        round(avg(total_obligation_to_sales_rate),6) avg_burden_rate,
        round(avg(residual_daily_operating_cash_flow),2) avg_residual_daily_cash,
        round(avg(post_financing_liquidity_buffer_amount),2) avg_post_financing_buffer
 FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=(SELECT run_id FROM r)
), mismatch AS (
 SELECT count(*) mismatches FROM (
  SELECT 'OBLIGATION|'||merchant_application_id||'|'||obligation_id||'|'||as_of_date entity_key,row_hash
  FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)
  UNION ALL
  SELECT 'CAPACITY|'||scenario_id||'|'||merchant_application_id,row_hash
  FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=(SELECT run_id FROM r)
 ) st FULL JOIN (
  SELECT * FROM msbf_m1.m1_10_actual_obligation((SELECT run_id FROM r))
  UNION ALL SELECT * FROM msbf_m1.m1_10_actual_capacity((SELECT run_id FROM r))
 ) ac USING(entity_key) WHERE st.row_hash IS DISTINCT FROM ac.row_hash
), stress AS (
 SELECT count(*) FILTER(WHERE s.scenario_code='RECESSION_ENERGY' AND c.capacity_tier<c.baseline_capacity_tier) stress_improvements,
        count(*) FILTER(WHERE s.scenario_code='RECESSION_ENERGY' AND c.capacity_tier>c.baseline_capacity_tier) stress_worsenings
 FROM msbf_m1.application_liquidity_capacity_snapshot c JOIN msbf_ctl.scenario_registry s USING(scenario_id)
 WHERE c.module1_run_id=(SELECT run_id FROM r)
), b AS (
 SELECT
  (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))+
  (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))+
  (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))+
  (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) downstream_rows,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') blocking_errors
), p AS (
 SELECT profile_payload->>'methodology_version' methodology_version,
        profile_payload->>'requested_burden_basis' requested_burden_basis,
        (profile_payload->>'stress_capacity_tier_floor_to_baseline')::boolean stress_floor_enabled
 FROM msbf_ctl.policy_profile WHERE profile_code='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY'
 AND profile_version=1 AND status='APPROVED'
)
SELECT current_database() database_name,current_user database_user,current_setting('server_version') postgresql_version,
 clock_timestamp() report_timestamp,r.run_id,r.run_status,r.population_id,r.as_of_date,
 gate.gate_id,gate.review_version,gate.result_status gate_status,
 ob.*,c.*,e.positive_checks,e.positive_passes,e.negative_controls,e.negative_passes,e.failed_evidence,
 mismatch.mismatches,stress.stress_improvements,stress.stress_worsenings,b.downstream_rows,b.blocking_errors,
 p.methodology_version,p.requested_burden_basis,p.stress_floor_enabled,e.obligation_hash,e.capacity_hash,e.combined_hash,
 CASE WHEN r.run_status='M1_10_ACCEPTED' AND gate.result_status='PASS'
       AND c.capacity_rows=1500 AND c.applications=750 AND c.scenarios=2
       AND e.positive_checks=70 AND e.positive_passes=70
       AND e.negative_controls=6 AND e.negative_passes=6
       AND e.failed_evidence=0 AND mismatch.mismatches=0 AND stress.stress_improvements=0
       AND b.downstream_rows=0 AND b.blocking_errors=0
       AND p.methodology_version='M1_10_METHOD_V1' AND p.requested_burden_basis='MAX_RATE_OR_HORIZON'
       AND p.stress_floor_enabled THEN 'PASS' ELSE 'FAIL' END AS overall_m1_10_status
FROM r CROSS JOIN gate CROSS JOIN e CROSS JOIN ob CROSS JOIN c CROSS JOIN mismatch CROSS JOIN stress CROSS JOIN b CROSS JOIN p;
