/* ============================================================================
MSBF M1.10 Obligations, Liquidity & Residual Cash Flow — Detailed Report
Version : v0.2R2
Purpose : Produce 18 read-only evidence result sets after acceptance.
All working tables preserve rows for the current DBeaver session so users may
filter or sort the result grids after COMMIT.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB'; SET LOCAL jit=off; SET LOCAL statement_timeout='15min';
DROP TABLE IF EXISTS _m1_10_dr_ctx; DROP TABLE IF EXISTS _m1_10_dr_ob;
DROP TABLE IF EXISTS _m1_10_dr_cap; DROP TABLE IF EXISTS _m1_10_dr_actual;
CREATE TEMP TABLE _m1_10_dr_ctx ON COMMIT PRESERVE ROWS AS
SELECT run_id,run_status,population_id,as_of_date FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
CREATE TEMP TABLE _m1_10_dr_ob ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM _m1_10_dr_ctx);
CREATE INDEX ON _m1_10_dr_ob(merchant_application_id,obligation_type);
CREATE TEMP TABLE _m1_10_dr_cap ON COMMIT PRESERVE ROWS AS
SELECT c.*,s.scenario_code FROM msbf_m1.application_liquidity_capacity_snapshot c
JOIN msbf_ctl.scenario_registry s USING(scenario_id)
WHERE c.module1_run_id=(SELECT run_id FROM _m1_10_dr_ctx);
CREATE UNIQUE INDEX ON _m1_10_dr_cap(scenario_id,merchant_application_id);
CREATE INDEX ON _m1_10_dr_cap(merchant_id,scenario_code,capacity_tier);
CREATE TEMP TABLE _m1_10_dr_actual ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.m1_10_actual_obligation((SELECT run_id FROM _m1_10_dr_ctx))
UNION ALL SELECT * FROM msbf_m1.m1_10_actual_capacity((SELECT run_id FROM _m1_10_dr_ctx));
CREATE UNIQUE INDEX ON _m1_10_dr_actual(entity_key);
ANALYZE _m1_10_dr_ob; ANALYZE _m1_10_dr_cap; ANALYZE _m1_10_dr_actual;

-- 01 Run and Acceptance State
SELECT r.*,g.review_version,g.result_status gate_status,g.finding,g.residual_limitation,g.reviewed_at
FROM _m1_10_dr_ctx r LEFT JOIN LATERAL(SELECT * FROM msbf_ctl.acceptance_gate_result x
 WHERE x.run_id=r.run_id AND x.gate_id='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY'
 ORDER BY review_version DESC LIMIT 1) g ON true;
-- 02 Entity and Stage-Boundary Row Counts
SELECT (SELECT count(*) FROM _m1_10_dr_ob) obligation_rows,
 (SELECT count(*) FROM _m1_10_dr_cap) capacity_rows,
 (SELECT count(DISTINCT merchant_application_id) FROM _m1_10_dr_cap) applications,
 (SELECT count(DISTINCT scenario_id) FROM _m1_10_dr_cap) scenarios,
 (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_10_dr_ctx)) risk_rows,
 (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_10_dr_ctx)) ead_rows,
 (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM _m1_10_dr_ctx)) latest_rows,
 (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM _m1_10_dr_ctx)) archive_rows;
-- 03 Obligation Type and Payment Diagnostics
SELECT obligation_type,payment_frequency,count(*) obligations,count(DISTINCT merchant_application_id) applications,
 round(sum(outstanding_balance),2) outstanding_balance,round(avg(daily_payment_amount),2) avg_daily_payment,
 round(sum(daily_payment_amount),2) total_daily_payment,count(*) FILTER(WHERE secured_flag) secured_rows,
 count(*) FILTER(WHERE short_term_financing_flag) short_term_rows
FROM _m1_10_dr_ob GROUP BY obligation_type,payment_frequency ORDER BY obligation_type;
-- 04 Obligation Availability and Quality Diagnostics
SELECT c.obligation_availability_status,c.obligation_quality_status,c.capacity_evidence_status,
 count(*) snapshots,count(DISTINCT c.merchant_application_id) applications,
 round(avg(c.obligation_confidence_score),6) avg_confidence,
 count(*) FILTER(WHERE c.manual_review_recommended_flag) review_rows
FROM _m1_10_dr_cap c GROUP BY c.obligation_availability_status,c.obligation_quality_status,c.capacity_evidence_status
ORDER BY 1,2,3;
-- 05 Existing Burden and Stacking Diagnostics
SELECT scenario_code,stacking_depth,max_stacking_sequence,count(*) snapshots,
 round(avg(existing_outstanding_balance),2) avg_outstanding,
 round(avg(existing_daily_payment_amount),2) avg_existing_daily,
 round(avg(obligation_concentration_rate),6) avg_concentration,
 count(*) FILTER(WHERE manual_review_recommended_flag) review_rows
FROM _m1_10_dr_cap GROUP BY scenario_code,stacking_depth,max_stacking_sequence ORDER BY scenario_code,stacking_depth,max_stacking_sequence;
-- 06 Requested Burden Diagnostics
SELECT scenario_code,count(*) snapshots,round(avg(requested_rate_based_daily_remittance),2) avg_rate_based,
 round(avg(requested_horizon_required_daily_repayment),2) avg_horizon_required,
 round(avg(requested_daily_remittance_amount),2) avg_governed_requested_daily,
 count(*) FILTER(WHERE requested_daily_remittance_amount=requested_horizon_required_daily_repayment) horizon_binding_rows,
 count(*) FILTER(WHERE requested_rate_based_daily_remittance IS NOT NULL AND requested_daily_remittance_amount=requested_rate_based_daily_remittance) rate_binding_rows
FROM _m1_10_dr_cap GROUP BY scenario_code ORDER BY scenario_code;
-- 07 Coverage and Burden-Rate Diagnostics
SELECT scenario_code,capacity_tier,count(*) snapshots,
 round(avg(sales_linked_payment_coverage_ratio),6) avg_coverage,
 round(avg(total_obligation_to_sales_rate),6) avg_burden_rate,
 round(avg(existing_obligation_to_sales_rate),6) avg_existing_burden_rate
FROM _m1_10_dr_cap GROUP BY scenario_code,capacity_tier ORDER BY scenario_code,capacity_tier;
-- 08 Residual Cash-Flow Diagnostics
SELECT scenario_code,affordability_status,count(*) snapshots,
 round(avg(estimated_daily_operating_cash_flow),2) avg_operating_cash,
 round(avg(total_daily_obligation_burden),2) avg_daily_burden,
 round(avg(residual_daily_operating_cash_flow),2) avg_residual_daily,
 round(avg(residual_monthly_operating_cash_flow),2) avg_residual_monthly,
 count(*) FILTER(WHERE residual_daily_operating_cash_flow<0) negative_residual_rows
FROM _m1_10_dr_cap GROUP BY scenario_code,affordability_status ORDER BY scenario_code,affordability_status;
-- 09 Post-Financing Liquidity Diagnostics
SELECT scenario_code,capacity_tier,count(*) snapshots,
 round(avg(current_liquidity_buffer_amount),2) avg_current_buffer,
 round(avg(post_financing_liquidity_buffer_amount),2) avg_post_buffer,
 round(avg(post_financing_buffer_days),4) avg_post_buffer_days,
 count(*) FILTER(WHERE post_financing_liquidity_buffer_amount<0) negative_post_buffer_rows
FROM _m1_10_dr_cap GROUP BY scenario_code,capacity_tier ORDER BY scenario_code,capacity_tier;
-- 10 Capacity Tier and Affordability Summary
SELECT scenario_code,capacity_tier,affordability_status,count(*) snapshots,
 count(*) FILTER(WHERE manual_review_recommended_flag) manual_review_rows,
 round(avg(sales_linked_payment_coverage_ratio),6) avg_coverage,
 round(avg(total_obligation_to_sales_rate),6) avg_burden_rate,
 round(avg(post_financing_buffer_days),4) avg_buffer_days
FROM _m1_10_dr_cap GROUP BY scenario_code,capacity_tier,affordability_status
ORDER BY scenario_code,capacity_tier,affordability_status;
-- 11 Matched Scenario Capacity Migration
SELECT b.capacity_tier baseline_tier,s.capacity_tier stress_tier,
 s.capacity_tier-b.capacity_tier tier_delta,count(*) applications,
 count(*) FILTER(WHERE s.capacity_tier>b.capacity_tier) worsening_apps,
 round(avg(s.sales_linked_payment_coverage_ratio-b.sales_linked_payment_coverage_ratio),6) avg_coverage_delta,
 round(avg(s.residual_daily_operating_cash_flow-b.residual_daily_operating_cash_flow),2) avg_residual_delta,
 round(avg(s.post_financing_liquidity_buffer_amount-b.post_financing_liquidity_buffer_amount),2) avg_liquidity_delta
FROM _m1_10_dr_cap b JOIN _m1_10_dr_cap s USING(merchant_application_id)
WHERE b.scenario_code='BASELINE' AND s.scenario_code='RECESSION_ENERGY'
GROUP BY b.capacity_tier,s.capacity_tier ORDER BY b.capacity_tier,s.capacity_tier;
-- 12 Industry Diagnostics
SELECT c.scenario_code,i.industry_code,count(*) snapshots,
 round(avg(c.sales_linked_payment_coverage_ratio),6) avg_coverage,
 round(avg(c.total_obligation_to_sales_rate),6) avg_burden_rate,
 round(avg(c.residual_daily_operating_cash_flow),2) avg_residual_daily,
 round(avg(c.post_financing_buffer_days),4) avg_buffer_days,
 count(*) FILTER(WHERE c.manual_review_recommended_flag) review_rows
FROM _m1_10_dr_cap c JOIN msbf_m1.merchant_industry_assignment i
 ON i.merchant_id=c.merchant_id AND i.assignment_type='PRIMARY'
GROUP BY c.scenario_code,i.industry_code ORDER BY c.scenario_code,i.industry_code;
-- 13 Merchant-Size and Relationship Diagnostics
SELECT c.scenario_code,m.merchant_size_tier,r.relationship_stage,count(*) snapshots,
 round(avg(c.existing_outstanding_balance),2) avg_existing_balance,
 round(avg(c.requested_daily_remittance_amount),2) avg_requested_daily,
 round(avg(c.sales_linked_payment_coverage_ratio),6) avg_coverage,
 count(*) FILTER(WHERE c.manual_review_recommended_flag) review_rows
FROM _m1_10_dr_cap c JOIN msbf_m1.merchant_master m USING(merchant_id)
JOIN msbf_m1.merchant_relationship_snapshot r ON r.merchant_id=c.merchant_id AND r.as_of_date=c.as_of_date
GROUP BY c.scenario_code,m.merchant_size_tier,r.relationship_stage
ORDER BY c.scenario_code,m.merchant_size_tier,r.relationship_stage;
-- 14 Fallback, Reason and Review Diagnostics
SELECT scenario_code,fallback_path_code,primary_capacity_reason_code,manual_review_recommended_flag,
 count(*) snapshots,round(avg(obligation_confidence_score),6) avg_obligation_confidence
FROM _m1_10_dr_cap GROUP BY scenario_code,fallback_path_code,primary_capacity_reason_code,manual_review_recommended_flag
ORDER BY scenario_code,fallback_path_code,primary_capacity_reason_code;
-- 15 Sample Matched Application Profiles
SELECT b.merchant_application_id,b.merchant_id,b.obligation_count,b.stacking_depth,b.existing_outstanding_balance,
 b.requested_daily_remittance_amount,b.sales_linked_payment_coverage_ratio baseline_coverage,
 s.sales_linked_payment_coverage_ratio stress_coverage,b.residual_daily_operating_cash_flow baseline_residual,
 s.residual_daily_operating_cash_flow stress_residual,b.post_financing_buffer_days baseline_buffer_days,
 s.post_financing_buffer_days stress_buffer_days,b.capacity_tier baseline_tier,s.capacity_tier stress_tier,
 s.fallback_path_code,s.primary_capacity_reason_code
FROM _m1_10_dr_cap b JOIN _m1_10_dr_cap s USING(merchant_application_id)
WHERE b.scenario_code='BASELINE' AND s.scenario_code='RECESSION_ENERGY'
ORDER BY s.capacity_tier DESC,s.sales_linked_payment_coverage_ratio NULLS FIRST,b.merchant_application_id LIMIT 50;
-- 16 M1.10 Evidence
SELECT evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,threshold_value_numeric,interpretation,created_at
FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_10_dr_ctx) AND evidence_code LIKE 'M1_10_%'
ORDER BY evidence_code,segment_key;
-- 17 Row-Level Deterministic Mismatches (must be empty)
SELECT coalesce(st.entity_key,a.entity_key) entity_key,st.row_hash stored_row_hash,a.row_hash recomputed_row_hash
FROM (
 SELECT 'OBLIGATION|'||merchant_application_id||'|'||obligation_id||'|'||as_of_date entity_key,row_hash FROM _m1_10_dr_ob
 UNION ALL SELECT 'CAPACITY|'||scenario_id||'|'||merchant_application_id,row_hash FROM _m1_10_dr_cap
) st FULL JOIN _m1_10_dr_actual a USING(entity_key)
WHERE st.row_hash IS DISTINCT FROM a.row_hash ORDER BY entity_key;
-- 18 Blocking Resolution Errors (must be empty)
SELECT profile_domain,scope_key,error_code,severity,error_message,created_at
FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_10_dr_ctx) AND severity='BLOCKING'
ORDER BY created_at,error_code;
COMMIT;
