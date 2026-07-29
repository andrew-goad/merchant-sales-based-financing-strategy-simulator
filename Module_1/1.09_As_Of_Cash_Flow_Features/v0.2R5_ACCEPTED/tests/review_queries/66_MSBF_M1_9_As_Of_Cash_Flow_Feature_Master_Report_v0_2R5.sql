/* ============================================================================
MSBF M1.9 As-of Cash-Flow Feature Engineering — Master Acceptance Report
Version : v0.2R5
Purpose : One-row executive and validation evidence after formal acceptance.
============================================================================ */
WITH r AS (
 SELECT run_id,run_status,population_id,as_of_date FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), gate AS (
 SELECT * FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_9_ASOF_CASHFLOW_FEATURES' ORDER BY review_version DESC LIMIT 1
), e AS (
 SELECT max(metric_value_text) FILTER(WHERE evidence_code='M1_9_SNAPSHOT_SET_HASH') snapshot_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_9_FEATURE_VALUE_SET_HASH') feature_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_9_COMBINED_SET_HASH') combined_hash,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_9_POS_%') positive_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_9_POS_%' AND status='PASS') positive_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_9_NEG_%') negative_controls,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_9_NEG_%' AND status='PASS') negative_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_9_%' AND status='FAIL') failed_evidence
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
), s AS (
 SELECT count(*) snapshot_rows,count(DISTINCT merchant_application_id) applications,count(DISTINCT scenario_id) scenarios,
        count(*) FILTER(WHERE feature_completeness_status='COMPLETE') complete_rows,
        count(*) FILTER(WHERE feature_completeness_status='PARTIAL') partial_rows,
        count(*) FILTER(WHERE feature_completeness_status='BLOCKED') blocked_rows,
        count(*) FILTER(WHERE ready_for_downstream_flag) downstream_ready_rows,
        count(*) FILTER(WHERE manual_review_recommended_flag) manual_review_rows,
        round(avg(source_confidence_score),6) avg_source_confidence,
        round(avg(avg_daily_eligible_sales_30d),2) avg_30d_daily_sales,
        round(avg(average_available_balance_30d),2) avg_30d_available_balance
 FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r)
), v AS (
 SELECT count(*) feature_value_rows,count(DISTINCT feature_code) governed_features,
        count(*) FILTER(WHERE value_status='AVAILABLE') available_values,
        count(*) FILTER(WHERE value_status='NOT_AVAILABLE') unavailable_values
 FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=(SELECT run_id FROM r)
), mismatch AS (
 SELECT count(*) mismatches FROM (
  SELECT 'SNAPSHOT|'||scenario_id||'|'||merchant_application_id entity_key,feature_snapshot_hash row_hash FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r)
  UNION ALL SELECT 'FEATURE|'||scenario_id||'|'||merchant_application_id||'|'||feature_code||'|v'||feature_version,calculation_hash FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=(SELECT run_id FROM r)
 ) st FULL JOIN (
  SELECT * FROM msbf_m1.m1_9_actual_snapshot((SELECT run_id FROM r)) UNION ALL
  SELECT * FROM msbf_m1.m1_9_actual_feature_value((SELECT run_id FROM r))
 ) ac USING(entity_key) WHERE st.row_hash IS DISTINCT FROM ac.row_hash
), policy AS (
 SELECT (profile_payload->>'annualization_days')::numeric annualization_days,profile_payload->>'annualized_sales_basis' annualized_sales_basis
 FROM msbf_ctl.policy_profile WHERE profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING' AND profile_version=1 AND status='APPROVED'
), identity AS (
 SELECT count(*) FILTER(WHERE (avg_daily_eligible_sales_90d IS NULL AND annualized_eligible_sales IS NOT NULL) OR (avg_daily_eligible_sales_90d IS NOT NULL AND annualized_eligible_sales IS DISTINCT FROM round(avg_daily_eligible_sales_90d*(SELECT annualization_days FROM policy),2)::numeric(18,2))) annualized_identity_violations
 FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r)
), b AS (
 SELECT
  (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r))+
  (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))+
  (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))+
  (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))+
  (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) downstream_rows,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') blocking_errors
)
SELECT current_database() database_name,current_user database_user,current_setting('server_version') postgresql_version,clock_timestamp() report_timestamp,
 r.run_id,r.run_status,r.population_id,r.as_of_date,g.gate_id,g.review_version,g.result_status gate_status,
 s.snapshot_rows,s.applications,s.scenarios,v.feature_value_rows,v.governed_features,v.available_values,v.unavailable_values,
 s.complete_rows,s.partial_rows,s.blocked_rows,s.downstream_ready_rows,s.manual_review_rows,s.avg_source_confidence,
 s.avg_30d_daily_sales,s.avg_30d_available_balance,e.positive_checks,e.positive_passes,e.negative_controls,e.negative_passes,
 e.failed_evidence,m.mismatches,i.annualized_identity_violations,p.annualization_days,p.annualized_sales_basis,b.downstream_rows,b.blocking_errors,e.snapshot_hash,e.feature_hash,e.combined_hash,
 CASE WHEN r.run_status='M1_9_ACCEPTED' AND g.result_status='PASS'
       AND s.snapshot_rows=1500 AND s.applications=750 AND s.scenarios=2
       AND v.feature_value_rows=54000 AND v.governed_features=36
       AND e.positive_checks=66 AND e.positive_passes=66 AND e.negative_controls=6 AND e.negative_passes=6
       AND e.failed_evidence=0 AND m.mismatches=0 AND i.annualized_identity_violations=0 AND p.annualization_days=365 AND p.annualized_sales_basis='PERSISTED_ROUNDED_90D_AVERAGE' AND b.downstream_rows=0 AND b.blocking_errors=0
      THEN 'PASS' ELSE 'FAIL' END AS overall_m1_9_status
FROM r CROSS JOIN gate g CROSS JOIN e CROSS JOIN s CROSS JOIN v CROSS JOIN mismatch m CROSS JOIN policy p CROSS JOIN identity i CROSS JOIN b;
