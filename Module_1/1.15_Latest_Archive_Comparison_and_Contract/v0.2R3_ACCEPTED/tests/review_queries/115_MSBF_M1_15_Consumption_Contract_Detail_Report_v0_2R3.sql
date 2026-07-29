/* ============================================================================
MSBF M1.15 Detailed Evidence Report
Program : 115_MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3.sql
Version : v0.2R3
Purpose : Produce 20 labeled result sets covering contract state, cardinality,
          latest/archive lineage, matched deltas, analytical distributions,
          governed evidence, deterministic mismatches, and blocking errors.
Mode    : Read-only reporting. Temporary report tables survive commit within
          the current DBeaver session for sorting and filtering.
============================================================================ */

BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m1_15_detail_latest;
CREATE TEMP TABLE _m1_15_detail_latest ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.application_module1_latest
WHERE module1_run_id=(
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
);

DROP TABLE IF EXISTS _m1_15_detail_archive;
CREATE TEMP TABLE _m1_15_detail_archive ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.application_module1_archive
WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_15_detail_latest);

DROP TABLE IF EXISTS _m1_15_detail_comparison;
CREATE TEMP TABLE _m1_15_detail_comparison ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.application_module1_scenario_comparison
WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_15_detail_latest);

COMMIT;

/* Result Set 1 — Run and Contract Acceptance State */
SELECT
    r.run_id,r.run_code,r.run_version,r.run_status,r.population_id,r.as_of_date,
    c.contract_code,c.contract_version,c.schema_version,c.contract_status,
    c.generated_at,c.validated_at,
    g.result_status AS latest_gate_status,g.review_version,g.reviewed_at
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m1_15_consumption_contract_registry c ON c.module1_run_id=r.run_id
LEFT JOIN LATERAL (
    SELECT result_status,review_version,reviewed_at
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=r.run_id AND gate_id='M1_15_CONSUMPTION_CONTRACT'
    ORDER BY review_version DESC LIMIT 1
) g ON true
WHERE r.run_id=(SELECT min(module1_run_id) FROM _m1_15_detail_latest);

/* Result Set 2 — Entity and Contract Cardinality */
SELECT
    (SELECT count(*) FROM _m1_15_detail_latest) AS latest_rows,
    (SELECT count(*) FROM _m1_15_detail_archive) AS archive_rows,
    (SELECT count(*) FROM _m1_15_detail_comparison) AS comparison_rows,
    (SELECT count(DISTINCT merchant_application_id) FROM _m1_15_detail_latest) AS applications,
    (SELECT count(DISTINCT scenario_id) FROM _m1_15_detail_latest) AS scenarios,
    1 AS contract_registry_rows,
    (SELECT count(*) FROM _m1_15_detail_latest)
      +(SELECT count(*) FROM _m1_15_detail_archive)
      +(SELECT count(*) FROM _m1_15_detail_comparison)+1 AS canonical_entities;

/* Result Set 3 — Scenario Distribution */
SELECT scenario_code,count(*) AS rows,
       count(DISTINCT merchant_application_id) AS applications,
       count(*) FILTER(WHERE contract_evidence_status='COMPLETE') AS complete_rows,
       count(*) FILTER(WHERE contract_evidence_status='PARTIAL') AS partial_rows,
       count(*) FILTER(WHERE contract_evidence_status='BLOCKED') AS blocked_rows
FROM _m1_15_detail_latest
GROUP BY scenario_code ORDER BY scenario_code;

/* Result Set 4 — Contract Evidence, Review, and Hard-Stop Distribution */
SELECT scenario_code,contract_evidence_status,
       hard_stop_recommended_flag,manual_review_recommended_flag,
       count(*) AS rows
FROM _m1_15_detail_latest
GROUP BY scenario_code,contract_evidence_status,
         hard_stop_recommended_flag,manual_review_recommended_flag
ORDER BY scenario_code,contract_evidence_status,
         hard_stop_recommended_flag,manual_review_recommended_flag;

/* Result Set 5 — Data Confidence and Verification */
SELECT scenario_code,data_confidence_tier,verification_disposition,
       fraud_risk_tier,processor_continuity_status,
       count(*) AS rows,round(avg(source_confidence_score),6) AS avg_source_confidence
FROM _m1_15_detail_latest
GROUP BY scenario_code,data_confidence_tier,verification_disposition,
         fraud_risk_tier,processor_continuity_status
ORDER BY scenario_code,data_confidence_tier,verification_disposition,fraud_risk_tier;

/* Result Set 6 — Cash-Flow and Liquidity Summary */
SELECT scenario_code,
       round(avg(avg_daily_eligible_sales_30d),2) AS avg_daily_sales_30d,
       round(avg(annualized_eligible_sales),2) AS avg_annualized_sales,
       round(avg(average_available_balance_30d),2) AS avg_available_balance_30d,
       round(avg(negative_balance_day_rate_30d),6) AS avg_negative_balance_rate,
       round(avg(nsf_count_30d),4) AS avg_nsf_count
FROM _m1_15_detail_latest
GROUP BY scenario_code ORDER BY scenario_code;

/* Result Set 7 — Capacity and Affordability */
SELECT scenario_code,capacity_tier,capacity_evidence_status,affordability_status,
       count(*) AS rows,
       round(avg(sales_linked_payment_coverage_ratio),6) AS avg_payment_coverage,
       round(avg(residual_daily_operating_cash_flow),2) AS avg_residual_daily_cash_flow,
       round(avg(post_financing_liquidity_buffer_amount),2) AS avg_post_financing_buffer
FROM _m1_15_detail_latest
GROUP BY scenario_code,capacity_tier,capacity_evidence_status,affordability_status
ORDER BY scenario_code,capacity_tier,capacity_evidence_status,affordability_status;

/* Result Set 8 — Archetype and Operating Resilience */
SELECT scenario_code,archetype_code,resilience_tier,resilience_status,
       count(*) AS rows,
       round(avg(operating_resilience_score),6) AS avg_resilience_score
FROM _m1_15_detail_latest
GROUP BY scenario_code,archetype_code,resilience_tier,resilience_status
ORDER BY scenario_code,resilience_tier,archetype_code;

/* Result Set 9 — Integrated Risk */
SELECT scenario_code,integrated_risk_tier,integrated_risk_status,
       integrated_risk_evidence_status,count(*) AS rows,
       round(avg(integrated_risk_score),6) AS avg_integrated_risk_score,
       round(avg(synthetic_merchant_risk_proxy),8) AS avg_synthetic_risk_proxy
FROM _m1_15_detail_latest
GROUP BY scenario_code,integrated_risk_tier,integrated_risk_status,
         integrated_risk_evidence_status
ORDER BY scenario_code,integrated_risk_tier,integrated_risk_status;

/* Result Set 10 — Exposure, Recovery, LGD, and Comparative Loss */
SELECT scenario_code,loss_evidence_status,count(*) AS rows,
       round(avg(path_weighted_ead_amount),2) AS avg_path_weighted_ead,
       round(avg(expected_ead_rate),8) AS avg_expected_ead_rate,
       round(avg(recovery_rate_assumption),8) AS avg_recovery_rate,
       round(avg(lgd_input_rate),8) AS avg_lgd,
       round(sum(schedule_adjusted_comparative_expected_loss_amount),2) AS total_comparative_loss
FROM _m1_15_detail_latest
GROUP BY scenario_code,loss_evidence_status
ORDER BY scenario_code,loss_evidence_status;

/* Result Set 11 — Unit Economics */
SELECT scenario_code,economic_tier,economic_status,unit_economics_evidence_status,
       count(*) AS rows,
       round(sum(gross_finance_revenue_amount),2) AS gross_finance_revenue,
       round(sum(total_non_loss_cost_amount),2) AS total_non_loss_cost,
       round(sum(risk_adjusted_contribution_amount),2) AS risk_adjusted_contribution,
       round(avg(annualized_risk_adjusted_return_rate),8) AS avg_annualized_return,
       round(sum(economic_surplus_amount),2) AS economic_surplus
FROM _m1_15_detail_latest
GROUP BY scenario_code,economic_tier,economic_status,unit_economics_evidence_status
ORDER BY scenario_code,economic_tier,economic_status;

/* Result Set 12 — Matched Scenario Delta Summary */
SELECT
    round(avg(source_confidence_delta),8) AS avg_source_confidence_delta,
    round(avg(sales_delta_amount),2) AS avg_sales_delta,
    round(avg(available_balance_delta_amount),2) AS avg_available_balance_delta,
    round(avg(resilience_score_delta),6) AS avg_resilience_score_delta,
    round(avg(resilience_tier_delta),4) AS avg_resilience_tier_delta,
    round(avg(integrated_risk_score_delta),6) AS avg_integrated_risk_score_delta,
    round(avg(integrated_risk_tier_delta),4) AS avg_integrated_risk_tier_delta,
    round(avg(path_weighted_ead_delta_amount),2) AS avg_ead_delta,
    round(avg(lgd_delta_rate),8) AS avg_lgd_delta,
    round(avg(comparative_loss_delta_amount),2) AS avg_comparative_loss_delta,
    round(avg(risk_adjusted_contribution_delta_amount),2) AS avg_contribution_delta,
    round(avg(annualized_return_delta_rate),8) AS avg_return_delta
FROM _m1_15_detail_comparison;

/* Result Set 13 — Matched Worsening Indicators */
SELECT
    count(*) FILTER(WHERE capacity_worsening_flag) AS capacity_worsenings,
    count(*) FILTER(WHERE resilience_worsening_flag) AS resilience_worsenings,
    count(*) FILTER(WHERE integrated_risk_worsening_flag) AS risk_worsenings,
    count(*) FILTER(WHERE comparative_loss_worsening_flag) AS loss_worsenings,
    count(*) FILTER(WHERE economic_worsening_flag) AS economic_worsenings,
    count(*) FILTER(WHERE manual_review_escalation_flag) AS review_escalations,
    count(*) FILTER(WHERE hard_stop_escalation_flag) AS hard_stop_escalations
FROM _m1_15_detail_comparison;

/* Result Set 14 — Comparison Evidence Status */
SELECT comparison_evidence_status,count(*) AS rows,
       round(avg(integrated_risk_score_delta),6) AS avg_risk_delta,
       round(avg(risk_adjusted_contribution_delta_amount),2) AS avg_contribution_delta
FROM _m1_15_detail_comparison
GROUP BY comparison_evidence_status
ORDER BY comparison_evidence_status;

/* Result Set 15 — Partner and Channel Diagnostics */
SELECT scenario_code,channel_type,partner_channel_id,
       count(*) AS rows,
       round(avg(source_confidence_score),6) AS avg_source_confidence,
       round(avg(integrated_risk_score),6) AS avg_risk_score,
       round(avg(annualized_risk_adjusted_return_rate),8) AS avg_return
FROM _m1_15_detail_latest
GROUP BY scenario_code,channel_type,partner_channel_id
ORDER BY scenario_code,channel_type,partner_channel_id;

/* Result Set 16 — Industry Diagnostics */
SELECT scenario_code,industry_code,count(*) AS rows,
       round(avg(avg_daily_eligible_sales_30d),2) AS avg_daily_sales,
       round(avg(operating_resilience_score),6) AS avg_resilience,
       round(avg(integrated_risk_score),6) AS avg_risk,
       round(avg(lgd_input_rate),8) AS avg_lgd,
       round(avg(annualized_risk_adjusted_return_rate),8) AS avg_return
FROM _m1_15_detail_latest
GROUP BY scenario_code,industry_code
ORDER BY scenario_code,industry_code;

/* Result Set 17 — Sample Matched Application Contracts */
SELECT
    b.merchant_application_id,b.industry_code,b.merchant_size_tier,
    b.relationship_stage,b.channel_type,
    b.contract_evidence_status AS baseline_evidence_status,
    s.contract_evidence_status AS stress_evidence_status,
    b.avg_daily_eligible_sales_30d AS baseline_sales,
    s.avg_daily_eligible_sales_30d AS stress_sales,
    b.integrated_risk_score AS baseline_risk,
    s.integrated_risk_score AS stress_risk,
    b.risk_adjusted_contribution_amount AS baseline_contribution,
    s.risk_adjusted_contribution_amount AS stress_contribution,
    b.contract_row_hash AS baseline_contract_hash,
    s.contract_row_hash AS stress_contract_hash
FROM _m1_15_detail_latest b
JOIN _m1_15_detail_latest s
  ON s.module1_run_id=b.module1_run_id
 AND s.merchant_application_id=b.merchant_application_id
WHERE b.scenario_code='BASELINE' AND s.scenario_code='RECESSION_ENERGY'
ORDER BY b.merchant_application_id
LIMIT 25;

/* Result Set 18 — Governed M1.15 Evidence */
SELECT evidence_code,segment_key,metric_name,
       metric_value_numeric,metric_value_text,unit_code,status,interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT min(module1_run_id) FROM _m1_15_detail_latest)
  AND evidence_code LIKE 'M1_15_%'
ORDER BY evidence_code,segment_key;

/* Result Set 19 — Row-Level Deterministic Mismatches */
SELECT 'LATEST_ROW_HASH' AS mismatch_type,
       scenario_id::text AS segment_key,merchant_application_id,
       contract_row_hash AS stored_hash,
       msbf_m1.m1_15_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at') AS recomputed_hash
FROM msbf_m1.application_module1_latest l
WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_15_detail_latest)
  AND contract_row_hash IS DISTINCT FROM
      msbf_m1.m1_15_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')
UNION ALL
SELECT 'COMPARISON_ROW_HASH',NULL::text,merchant_application_id,
       comparison_row_hash,
       msbf_m1.m1_15_hash_jsonb(to_jsonb(c)-'comparison_row_hash'-'created_at')
FROM msbf_m1.application_module1_scenario_comparison c
WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_15_detail_latest)
  AND comparison_row_hash IS DISTINCT FROM
      msbf_m1.m1_15_hash_jsonb(to_jsonb(c)-'comparison_row_hash'-'created_at');

/* Result Set 20 — Blocking Resolution Errors */
SELECT
    resolution_error_id,run_id,profile_domain,scope_key,error_code,
    severity,error_message,created_at
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT min(module1_run_id) FROM _m1_15_detail_latest)
  AND severity='BLOCKING'
ORDER BY resolution_error_id;
