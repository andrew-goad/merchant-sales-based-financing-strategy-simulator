/* ============================================================================
MSBF M1.9 As-of Cash-Flow Feature Engineering — Detailed Evidence Report
Version : v0.2R5
Purpose : Produce 20 read-only evidence result sets after acceptance.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';SET LOCAL jit=off;SET LOCAL statement_timeout='15min';
DROP TABLE IF EXISTS _m1_9_dr_ctx;
CREATE TEMP TABLE _m1_9_dr_ctx ON COMMIT PRESERVE ROWS AS
SELECT run_id,run_status,population_id,as_of_date FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
DROP TABLE IF EXISTS _m1_9_dr_s;
CREATE TEMP TABLE _m1_9_dr_s ON COMMIT PRESERVE ROWS AS
SELECT s.*,sc.scenario_code FROM msbf_m1.application_cashflow_feature_snapshot s JOIN msbf_ctl.scenario_registry sc USING(scenario_id)
WHERE s.module1_run_id=(SELECT run_id FROM _m1_9_dr_ctx);
CREATE UNIQUE INDEX ON _m1_9_dr_s(scenario_id,merchant_application_id);CREATE INDEX ON _m1_9_dr_s(merchant_id);
DROP TABLE IF EXISTS _m1_9_dr_v;
CREATE TEMP TABLE _m1_9_dr_v ON COMMIT PRESERVE ROWS AS
SELECT v.*,sc.scenario_code FROM msbf_m1.cashflow_feature_value v JOIN msbf_ctl.scenario_registry sc USING(scenario_id)
WHERE v.module1_run_id=(SELECT run_id FROM _m1_9_dr_ctx);
CREATE INDEX ON _m1_9_dr_v(feature_code,scenario_code,value_status);
DROP TABLE IF EXISTS _m1_9_dr_actual;
CREATE TEMP TABLE _m1_9_dr_actual ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.m1_9_actual_snapshot((SELECT run_id FROM _m1_9_dr_ctx))
UNION ALL SELECT * FROM msbf_m1.m1_9_actual_feature_value((SELECT run_id FROM _m1_9_dr_ctx));
CREATE UNIQUE INDEX ON _m1_9_dr_actual(entity_key);
ANALYZE _m1_9_dr_s;ANALYZE _m1_9_dr_v;ANALYZE _m1_9_dr_actual;

-- 01 Run and Acceptance State
SELECT r.*,g.review_version,g.result_status gate_status,g.finding,g.residual_limitation,g.reviewed_at
FROM _m1_9_dr_ctx r LEFT JOIN LATERAL(SELECT * FROM msbf_ctl.acceptance_gate_result x WHERE x.run_id=r.run_id AND x.gate_id='M1_9_ASOF_CASHFLOW_FEATURES' ORDER BY review_version DESC LIMIT 1)g ON true;
-- 02 Entity and Stage-Boundary Row Counts
SELECT
 (SELECT count(*) FROM _m1_9_dr_s) snapshot_rows,
 (SELECT count(*) FROM _m1_9_dr_v) feature_value_rows,
 (SELECT count(DISTINCT merchant_application_id) FROM _m1_9_dr_s) applications,
 (SELECT count(DISTINCT scenario_id) FROM _m1_9_dr_s) scenarios,
 (SELECT count(DISTINCT feature_code) FROM _m1_9_dr_v) governed_features,
 (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_9_dr_ctx)) downstream_feature_rows,
 (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_9_dr_ctx)) risk_rows,
 (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_9_dr_ctx)) ead_rows,
 (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM _m1_9_dr_ctx)) latest_rows,
 (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM _m1_9_dr_ctx)) archive_rows;
-- 03 Feature Completeness and Routing
SELECT scenario_code,feature_completeness_status,downstream_routing_status,ready_for_downstream_flag,manual_review_recommended_flag,count(*) snapshots
FROM _m1_9_dr_s GROUP BY scenario_code,feature_completeness_status,downstream_routing_status,ready_for_downstream_flag,manual_review_recommended_flag
ORDER BY scenario_code,feature_completeness_status,downstream_routing_status;
-- 04 Source Confidence and Data-Confidence Tiers
SELECT scenario_code,data_confidence_tier,count(*) snapshots,round(min(source_confidence_score),6) min_confidence,
 round(avg(source_confidence_score),6) avg_confidence,round(max(source_confidence_score),6) max_confidence
FROM _m1_9_dr_s GROUP BY scenario_code,data_confidence_tier ORDER BY scenario_code,data_confidence_tier;
-- 05 POS and Deposit Quality Diagnostics
SELECT scenario_code,pos_quality_status,deposit_quality_status,count(*) snapshots,
 round(avg(pos_history_days),2) avg_pos_days,round(avg(deposit_history_days),2) avg_deposit_days,
 count(*) FILTER(WHERE ready_for_downstream_flag) ready_snapshots
FROM _m1_9_dr_s GROUP BY scenario_code,pos_quality_status,deposit_quality_status ORDER BY scenario_code,pos_quality_status,deposit_quality_status;
-- 06 Revenue-Level Diagnostics
SELECT scenario_code,count(*) snapshots,round(avg(avg_daily_eligible_sales_7d),2) avg_7d,
 round(avg(avg_daily_eligible_sales_30d),2) avg_30d,round(avg(avg_daily_eligible_sales_60d),2) avg_60d,
 round(avg(avg_daily_eligible_sales_90d),2) avg_90d,round(avg(annualized_eligible_sales),2) avg_annualized,
 count(*) FILTER(WHERE (avg_daily_eligible_sales_90d IS NULL AND annualized_eligible_sales IS NOT NULL) OR (avg_daily_eligible_sales_90d IS NOT NULL AND annualized_eligible_sales IS DISTINCT FROM round(avg_daily_eligible_sales_90d*(SELECT (profile_payload->>'annualization_days')::numeric FROM msbf_ctl.policy_profile WHERE profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING' AND profile_version=1 AND status='APPROVED'),2)::numeric(18,2))) annualized_identity_violations
FROM _m1_9_dr_s GROUP BY scenario_code ORDER BY scenario_code;
-- 07 Trend, Volatility and Seasonality Diagnostics
SELECT scenario_code,round(avg(sales_growth_7d_vs_30d),6) avg_growth_7_30,
 round(avg(sales_growth_30d_vs_90d),6) avg_growth_30_90,round(avg(daily_sales_cv_30d),6) avg_cv_30,
 round(avg(daily_sales_cv_90d),6) avg_cv_90,round(avg(seasonality_index_180d),6) avg_seasonality,
 round(avg(largest_30d_share_180d),6) avg_largest_30d_share
FROM _m1_9_dr_s GROUP BY scenario_code ORDER BY scenario_code;
-- 08 Transaction-Quality Diagnostics
SELECT scenario_code,round(avg(refund_rate_30d),6) avg_refund_rate,
 round(avg(chargeback_rate_30d),6) avg_chargeback_rate,round(avg(reversal_rate_30d),6) avg_reversal_rate
FROM _m1_9_dr_s GROUP BY scenario_code ORDER BY scenario_code;
-- 09 Liquidity Diagnostics
SELECT scenario_code,round(avg(deposit_to_eligible_sales_rate_30d),6) avg_deposit_sales_rate,
 round(avg(pos_deposit_reconciliation_rate_30d),6) avg_reconciliation,round(avg(negative_balance_day_rate_30d),6) avg_negative_rate,
 round(avg(nsf_count_30d),4) avg_nsf,round(avg(average_available_balance_30d),2) avg_available_balance,
 round(min(minimum_balance_30d),2) portfolio_minimum_balance,round(avg(cash_flow_buffer_days),4) avg_buffer_days
FROM _m1_9_dr_s GROUP BY scenario_code ORDER BY scenario_code;
-- 10 Processor Continuity Diagnostics
SELECT scenario_code,processor_continuity_status,processor_continuity_risk_tier,count(*) snapshots,
 round(avg(processor_outage_day_rate_30d),6) avg_outage_rate,round(avg(processor_degraded_day_rate_30d),6) avg_degraded_rate
FROM _m1_9_dr_s GROUP BY scenario_code,processor_continuity_status,processor_continuity_risk_tier
ORDER BY scenario_code,processor_continuity_risk_tier;
-- 11 Matched Scenario Delta Summary
SELECT scenario_code,round(avg(scenario_eligible_sales_delta_rate_30d),6) avg_sales_delta_30,
 round(avg(scenario_eligible_sales_delta_rate_90d),6) avg_sales_delta_90,
 round(avg(scenario_deposit_delta_rate_30d),6) avg_deposit_delta,
 round(avg(scenario_withdrawal_delta_rate_30d),6) avg_withdrawal_delta,
 round(avg(scenario_available_balance_delta_rate_30d),6) avg_available_balance_delta,
 round(avg(scenario_negative_balance_rate_delta_30d),6) avg_negative_rate_delta,
 round(avg(scenario_nsf_count_delta_30d),4) avg_nsf_delta,
 round(avg(scenario_processor_outage_rate_delta_30d),6) avg_outage_delta,
 round(avg(scenario_refund_rate_delta_30d),6) avg_refund_delta,
 round(avg(scenario_chargeback_rate_delta_30d),6) avg_chargeback_delta
FROM _m1_9_dr_s GROUP BY scenario_code ORDER BY scenario_code;
-- 12 Industry Diagnostics
SELECT s.scenario_code,i.industry_code,count(*) snapshots,round(avg(s.avg_daily_eligible_sales_30d),2) avg_sales_30,
 round(avg(s.daily_sales_cv_30d),6) avg_cv_30,round(avg(s.average_available_balance_30d),2) avg_available_balance,
 round(avg(s.source_confidence_score),6) avg_confidence,count(*) FILTER(WHERE s.ready_for_downstream_flag) ready_snapshots
FROM _m1_9_dr_s s JOIN msbf_m1.merchant_industry_assignment i ON i.merchant_id=s.merchant_id AND i.assignment_type='PRIMARY'
GROUP BY s.scenario_code,i.industry_code ORDER BY s.scenario_code,i.industry_code;
-- 13 Merchant-Size Diagnostics
SELECT s.scenario_code,m.merchant_size_tier,count(*) snapshots,round(avg(s.avg_daily_eligible_sales_30d),2) avg_sales_30,
 round(avg(s.annualized_eligible_sales),2) avg_annualized_sales,round(avg(s.cash_flow_buffer_days),4) avg_buffer_days,
 count(*) FILTER(WHERE s.manual_review_recommended_flag) review_snapshots
FROM _m1_9_dr_s s JOIN msbf_m1.merchant_master m ON m.merchant_id=s.merchant_id
GROUP BY s.scenario_code,m.merchant_size_tier ORDER BY s.scenario_code,m.merchant_size_tier;
-- 14 Relationship-Stage Diagnostics
SELECT s.scenario_code,r.relationship_stage,count(*) snapshots,round(avg(s.avg_daily_eligible_sales_30d),2) avg_sales_30,
 round(avg(s.source_confidence_score),6) avg_confidence,round(avg(s.average_available_balance_30d),2) avg_available_balance,
 count(*) FILTER(WHERE s.ready_for_downstream_flag) ready_snapshots
FROM _m1_9_dr_s s JOIN msbf_m1.merchant_relationship_snapshot r ON r.merchant_id=s.merchant_id AND r.as_of_date=s.as_of_date
GROUP BY s.scenario_code,r.relationship_stage ORDER BY s.scenario_code,r.relationship_stage;
-- 15 Partner/Channel Diagnostics
SELECT s.scenario_code,coalesce(pc.channel_type,'UNASSIGNED') channel_type,count(*) snapshots,
 round(avg(s.source_confidence_score),6) avg_confidence,round(avg(s.avg_daily_eligible_sales_30d),2) avg_sales_30,
 count(*) FILTER(WHERE s.feature_completeness_status='COMPLETE') complete_snapshots,
 count(*) FILTER(WHERE s.feature_completeness_status='BLOCKED') blocked_snapshots
FROM _m1_9_dr_s s JOIN msbf_m1.merchant_application a USING(merchant_application_id)
LEFT JOIN msbf_m1.partner_channel pc ON pc.partner_channel_id=a.partner_channel_id
GROUP BY s.scenario_code,coalesce(pc.channel_type,'UNASSIGNED') ORDER BY s.scenario_code,channel_type;
-- 16 Feature Availability by Feature and Scenario
SELECT scenario_code,feature_code,count(*) rows,
 count(*) FILTER(WHERE value_status='AVAILABLE') available_rows,
 count(*) FILTER(WHERE value_status='NOT_AVAILABLE') unavailable_rows,
 round(avg(value_numeric) FILTER(WHERE value_status='AVAILABLE'),6) avg_available_value
FROM _m1_9_dr_v GROUP BY scenario_code,feature_code ORDER BY feature_code,scenario_code;
-- 17 Sample Matched Application Profiles
SELECT b.merchant_application_id,b.merchant_id,b.data_confidence_tier,b.verification_disposition,b.fraud_risk_tier,
 b.avg_daily_eligible_sales_30d baseline_sales_30,s.avg_daily_eligible_sales_30d stress_sales_30,
 b.average_available_balance_30d baseline_available_balance,s.average_available_balance_30d stress_available_balance,
 s.scenario_eligible_sales_delta_rate_30d,s.scenario_available_balance_delta_rate_30d,
 b.feature_completeness_status baseline_completeness,s.feature_completeness_status stress_completeness
FROM _m1_9_dr_s b JOIN _m1_9_dr_s s USING(merchant_application_id)
WHERE b.scenario_code='BASELINE' AND s.scenario_code='RECESSION_ENERGY'
ORDER BY s.scenario_eligible_sales_delta_rate_30d NULLS LAST,b.merchant_application_id LIMIT 40;
-- 18 M1.9 Evidence
SELECT evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,threshold_value_numeric,interpretation,created_at
FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_dr_ctx) AND evidence_code LIKE 'M1_9_%'
ORDER BY evidence_code,segment_key;
-- 19 Row-Level Deterministic Mismatches (must be empty)
SELECT coalesce(st.entity_key,a.entity_key) entity_key,st.row_hash stored_row_hash,a.row_hash recomputed_row_hash
FROM (
 SELECT 'SNAPSHOT|'||scenario_id||'|'||merchant_application_id entity_key,feature_snapshot_hash row_hash FROM _m1_9_dr_s
 UNION ALL SELECT 'FEATURE|'||scenario_id||'|'||merchant_application_id||'|'||feature_code||'|v'||feature_version,calculation_hash FROM _m1_9_dr_v
) st FULL JOIN _m1_9_dr_actual a USING(entity_key)
WHERE st.row_hash IS DISTINCT FROM a.row_hash ORDER BY entity_key;
-- 20 Blocking Resolution Errors (must be empty)
SELECT profile_domain,scope_key,error_code,severity,error_message,created_at
FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_9_dr_ctx) AND severity='BLOCKING'
ORDER BY created_at,error_code;
COMMIT;
