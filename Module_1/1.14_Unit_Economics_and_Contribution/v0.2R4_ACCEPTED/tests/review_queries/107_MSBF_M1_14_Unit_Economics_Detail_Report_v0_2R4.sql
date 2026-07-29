/* ============================================================================
MSBF M1.14 Unit Economics & Risk-Adjusted Contribution — Detailed Report
Program : 107_MSBF_M1_14_Unit_Economics_Detail_Report_v0_2R4.sql
Version : v0.2R4
Purpose : Produce a structured 20-result-set evidence package covering run
          state, methodology, revenue, costs, loss, capital, contribution,
          return, hurdle, routing, segment diagnostics, hashes, and errors.
Mode    : Read-only. Working tables are session-scoped and preserved after
          commit so DBeaver grids remain filterable in the same session.
============================================================================ */

BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL statement_timeout='15min';

DROP TABLE IF EXISTS _m1_14_detail_economics;
CREATE TEMP TABLE _m1_14_detail_economics ON COMMIT PRESERVE ROWS AS
SELECT e.*,sr.scenario_code
FROM msbf_m1.application_unit_economics_snapshot e
JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
WHERE e.module1_run_id=(
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
);
CREATE UNIQUE INDEX ON _m1_14_detail_economics(scenario_id,merchant_application_id);
ANALYZE _m1_14_detail_economics;

DROP TABLE IF EXISTS _m1_14_detail_components;
CREATE TEMP TABLE _m1_14_detail_components ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.unit_economics_component_value
WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_14_detail_economics);
CREATE INDEX ON _m1_14_detail_components(scenario_id,component_code);
ANALYZE _m1_14_detail_components;

COMMIT;

/* 01 — Run and Acceptance State */
SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.population_id,r.as_of_date,
       g.review_version,g.result_status AS gate_status,g.reviewed_at,
       p.status AS policy_status,p.profile_payload->>'methodology_version' AS methodology_version
FROM msbf_ctl.run_registry r
LEFT JOIN LATERAL (
    SELECT * FROM msbf_ctl.acceptance_gate_result x
    WHERE x.run_id=r.run_id AND x.gate_id='M1_14_UNIT_ECONOMICS_CONTRIBUTION'
    ORDER BY review_version DESC LIMIT 1
) g ON true
LEFT JOIN msbf_ctl.policy_profile p
  ON p.profile_code='M1_14_UNIT_ECONOMICS_CONTRIBUTION' AND p.profile_version=1
WHERE r.run_id=(SELECT min(module1_run_id) FROM _m1_14_detail_economics);

/* 02 — Entity and Stage-Boundary Row Counts */
SELECT
    (SELECT count(*) FROM _m1_14_detail_economics) AS snapshot_rows,
    (SELECT count(*) FROM _m1_14_detail_components) AS component_rows,
    (SELECT count(DISTINCT merchant_application_id) FROM _m1_14_detail_economics) AS applications,
    (SELECT count(DISTINCT scenario_id) FROM _m1_14_detail_economics) AS scenarios,
    (SELECT count(DISTINCT component_code) FROM _m1_14_detail_components) AS component_codes,
    (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_14_detail_economics)) AS latest_rows,
    (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_14_detail_economics)) AS archive_rows;

/* 03 — Governed Methodology and Economic Parameters */
SELECT profile_code,profile_version,status,policy_domain,
       profile_payload->>'methodology_version' AS methodology_version,
       profile_payload->>'contribution_basis_code' AS contribution_basis_code,
       profile_payload->>'comparative_loss_basis_code' AS comparative_loss_basis_code,
       profile_payload->>'funding_cost_basis_code' AS funding_cost_basis_code,
       profile_payload->>'risk_capital_charge_basis_code' AS capital_charge_basis_code,
       profile_payload->>'hurdle_basis_code' AS hurdle_basis_code,
       (profile_payload->>'processor_payment_cost_rate')::numeric AS processor_payment_cost_rate,
       (profile_payload->>'default_partner_acquisition_cost_rate')::numeric AS default_partner_acquisition_cost_rate,
       (profile_payload->>'funding_cost_annual_rate')::numeric AS funding_cost_annual_rate,
       (profile_payload->>'risk_capital_allocation_rate')::numeric AS risk_capital_allocation_rate,
       (profile_payload->>'risk_capital_cost_annual_rate')::numeric AS risk_capital_cost_annual_rate,
       (profile_payload->>'hurdle_annual_return_rate')::numeric AS hurdle_annual_return_rate
FROM msbf_ctl.policy_profile
WHERE profile_code='M1_14_UNIT_ECONOMICS_CONTRIBUTION' AND profile_version=1;

/* 04 — Portfolio Economics Summary by Scenario */
SELECT scenario_code,count(*) AS snapshots,
       round(sum(gross_finance_revenue_amount),2) AS gross_revenue,
       round(sum(total_non_loss_cost_amount),2) AS total_non_loss_cost,
       round(sum(comparative_expected_loss_amount),2) AS comparative_loss,
       round(sum(risk_capital_charge_amount),2) AS risk_capital_charge,
       round(sum(risk_adjusted_contribution_amount),2) AS risk_adjusted_contribution,
       round(sum(hurdle_required_contribution_amount),2) AS hurdle_requirement,
       round(sum(economic_surplus_amount),2) AS economic_surplus,
       round(avg(annualized_risk_adjusted_return_rate),6) AS avg_annualized_risk_adjusted_return
FROM _m1_14_detail_economics GROUP BY scenario_code ORDER BY scenario_code;

/* 05 — Revenue and Gross Yield Diagnostics */
SELECT scenario_code,requested_expected_payoff_days,count(*) AS applications,
       round(avg(requested_funding_amount),2) AS avg_requested_funding,
       round(avg(payback_multiple),6) AS avg_payback_multiple,
       round(avg(gross_finance_charge_rate),6) AS avg_finance_charge_rate,
       round(avg(annualized_gross_yield_rate),6) AS avg_annualized_gross_yield,
       round(sum(gross_finance_revenue_amount),2) AS gross_revenue
FROM _m1_14_detail_economics
GROUP BY scenario_code,requested_expected_payoff_days
ORDER BY scenario_code,requested_expected_payoff_days;

/* 06 — Processor and Partner Cost Diagnostics */
SELECT scenario_code,channel_type,channel_cost_evidence_status,count(*) AS applications,
       round(avg(processor_payment_cost_rate),6) AS avg_processor_cost_rate,
       round(sum(processor_payment_cost_amount),2) AS processor_cost,
       round(avg(partner_acquisition_cost_rate),6) AS avg_partner_cost_rate,
       round(sum(partner_acquisition_cost_amount),2) AS partner_acquisition_cost
FROM _m1_14_detail_economics
GROUP BY scenario_code,channel_type,channel_cost_evidence_status
ORDER BY scenario_code,channel_type,channel_cost_evidence_status;

/* 07 — Funding Cost Diagnostics */
SELECT scenario_code,requested_expected_payoff_days,count(*) AS applications,
       round(avg(path_weighted_ead_amount),2) AS avg_path_weighted_ead,
       round(avg(funding_cost_annual_rate),6) AS avg_funding_rate,
       round(sum(funding_cost_amount),2) AS funding_cost,
       round(avg(funding_cost_amount/requested_funding_amount),6) AS avg_funding_cost_to_funded_rate
FROM _m1_14_detail_economics
GROUP BY scenario_code,requested_expected_payoff_days
ORDER BY scenario_code,requested_expected_payoff_days;

/* 08 — Servicing and Operating Cost Diagnostics */
SELECT scenario_code,count(*) AS applications,
       round(sum(servicing_cost_amount),2) AS servicing_cost,
       round(sum(operating_cost_amount),2) AS operating_cost,
       round(avg(servicing_cost_amount/requested_funding_amount),6) AS avg_servicing_cost_rate,
       round(avg(operating_cost_amount/requested_funding_amount),6) AS avg_operating_cost_rate
FROM _m1_14_detail_economics GROUP BY scenario_code ORDER BY scenario_code;

/* 09 — Non-Loss Cost Composition */
SELECT sr.scenario_code,c.component_code,count(*) AS rows,
       round(sum(c.component_amount),2) AS component_amount,
       round(avg(c.component_rate),6) AS avg_component_rate
FROM _m1_14_detail_components c
JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
WHERE c.component_code IN ('PROCESSOR_PAYMENT_COST','PARTNER_ACQUISITION_COST','FUNDING_COST','SERVICING_COST','OPERATING_COST','TOTAL_NON_LOSS_COST')
GROUP BY sr.scenario_code,c.component_code
ORDER BY sr.scenario_code,c.component_code;

/* 10 — Contribution Before and After Comparative Loss */
SELECT scenario_code,unit_economics_evidence_status,count(*) AS applications,
       round(sum(contribution_before_comparative_loss_amount),2) AS contribution_before_loss,
       round(sum(comparative_expected_loss_amount),2) AS comparative_loss,
       round(sum(contribution_after_comparative_loss_amount),2) AS contribution_after_loss,
       round(avg(contribution_before_loss_margin_rate),6) AS avg_before_loss_margin,
       round(avg(contribution_after_loss_margin_rate),6) AS avg_after_loss_margin
FROM _m1_14_detail_economics
GROUP BY scenario_code,unit_economics_evidence_status
ORDER BY scenario_code,unit_economics_evidence_status;

/* 11 — Comparative Loss and Synthetic Capital Charge */
SELECT scenario_code,integrated_risk_tier,count(*) AS applications,
       round(sum(comparative_expected_loss_amount),2) AS comparative_loss,
       round(sum(risk_capital_charge_amount),2) AS risk_capital_charge,
       round(avg(schedule_adjusted_comparative_loss_rate),6) AS avg_comparative_loss_rate,
       round(avg(risk_capital_charge_amount/requested_funding_amount),6) AS avg_capital_charge_rate
FROM _m1_14_detail_economics
GROUP BY scenario_code,integrated_risk_tier
ORDER BY scenario_code,integrated_risk_tier;

/* 12 — Risk-Adjusted Return and Hurdle Diagnostics */
SELECT scenario_code,economic_status,count(*) AS applications,
       round(sum(risk_adjusted_contribution_amount),2) AS risk_adjusted_contribution,
       round(sum(hurdle_required_contribution_amount),2) AS hurdle_requirement,
       round(sum(economic_surplus_amount),2) AS economic_surplus,
       round(avg(risk_adjusted_contribution_margin_rate),6) AS avg_risk_adjusted_margin,
       round(avg(annualized_risk_adjusted_return_rate),6) AS avg_annualized_return
FROM _m1_14_detail_economics
GROUP BY scenario_code,economic_status
ORDER BY scenario_code,economic_status;

/* 13 — Economic Tier and Status Distribution */
SELECT scenario_code,economic_tier,economic_status,unit_economics_evidence_status,
       count(*) AS applications,count(*) FILTER(WHERE hurdle_pass_flag) AS hurdle_passes,
       count(*) FILTER(WHERE manual_review_recommended_flag) AS manual_reviews,
       count(*) FILTER(WHERE hard_stop_recommended_flag) AS hard_stops
FROM _m1_14_detail_economics
GROUP BY scenario_code,economic_tier,economic_status,unit_economics_evidence_status
ORDER BY scenario_code,economic_tier,economic_status;

/* 14 — Matched Stress Migration */
SELECT b.economic_tier AS baseline_tier,s.economic_tier AS stress_tier,
       count(*) AS applications,
       count(*) FILTER(WHERE s.risk_adjusted_contribution_amount<b.risk_adjusted_contribution_amount) AS contribution_worsenings,
       count(*) FILTER(WHERE s.risk_adjusted_contribution_amount>b.risk_adjusted_contribution_amount) AS contribution_improvements,
       count(*) FILTER(WHERE s.annualized_risk_adjusted_return_rate<b.annualized_risk_adjusted_return_rate) AS return_worsenings,
       count(*) FILTER(WHERE s.annualized_risk_adjusted_return_rate>b.annualized_risk_adjusted_return_rate) AS return_improvements
FROM _m1_14_detail_economics b
JOIN _m1_14_detail_economics s USING(merchant_application_id)
WHERE b.scenario_code='BASELINE' AND s.scenario_code='RECESSION_ENERGY'
GROUP BY b.economic_tier,s.economic_tier
ORDER BY b.economic_tier,s.economic_tier;

/* 15 — Partner Channel Diagnostics */
SELECT partner_channel_id,channel_type,scenario_code,count(*) AS applications,
       round(sum(gross_finance_revenue_amount),2) AS gross_revenue,
       round(sum(total_non_loss_cost_amount),2) AS non_loss_cost,
       round(sum(risk_adjusted_contribution_amount),2) AS risk_adjusted_contribution,
       round(avg(annualized_risk_adjusted_return_rate),6) AS avg_annualized_return,
       count(*) FILTER(WHERE hurdle_pass_flag) AS hurdle_passes
FROM _m1_14_detail_economics
GROUP BY partner_channel_id,channel_type,scenario_code
ORDER BY partner_channel_id,scenario_code;

/* 16 — Industry Diagnostics */
SELECT industry_code,scenario_code,count(*) AS applications,
       round(sum(gross_finance_revenue_amount),2) AS gross_revenue,
       round(sum(comparative_expected_loss_amount),2) AS comparative_loss,
       round(sum(risk_adjusted_contribution_amount),2) AS risk_adjusted_contribution,
       round(avg(annualized_risk_adjusted_return_rate),6) AS avg_annualized_return,
       round(avg(economic_tier),4) AS avg_economic_tier
FROM _m1_14_detail_economics
GROUP BY industry_code,scenario_code
ORDER BY industry_code,scenario_code;

/* 17 — Sample Matched Application Profiles */
SELECT merchant_application_id,scenario_code,industry_code,merchant_size_tier,
       relationship_stage,channel_type,unit_economics_evidence_status,
       requested_funding_amount,gross_finance_revenue_amount,total_non_loss_cost_amount,
       comparative_expected_loss_amount,risk_capital_charge_amount,
       risk_adjusted_contribution_amount,annualized_risk_adjusted_return_rate,
       hurdle_required_contribution_amount,economic_surplus_amount,economic_tier,
       economic_status,fallback_path_code,primary_economic_reason_code
FROM _m1_14_detail_economics
WHERE merchant_application_id IN (
    SELECT merchant_application_id FROM _m1_14_detail_economics
    WHERE scenario_code='BASELINE'
    ORDER BY merchant_application_id LIMIT 12
)
ORDER BY merchant_application_id,scenario_code;

/* 18 — M1.14 Governed Evidence */
SELECT evidence_code,segment_key,metric_name,metric_value_text,metric_value_numeric,
       unit_code,status,interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT min(module1_run_id) FROM _m1_14_detail_economics)
  AND evidence_code LIKE 'M1_14_%'
ORDER BY evidence_code,segment_key;

/* 19 — Row-Level Deterministic Mismatches */
WITH run_scope AS (
    SELECT min(module1_run_id) AS run_id
    FROM _m1_14_detail_economics
),
snapshot_mismatch AS (
    SELECT
        'ECON|' || s.scenario_id || '|' || s.merchant_application_id AS entity_key,
        s.row_hash AS stored_hash,
        msbf_m1.m1_14_hash_jsonb(to_jsonb(s) - 'row_hash' - 'created_at') AS recomputed_hash
    FROM msbf_m1.application_unit_economics_snapshot s
    CROSS JOIN run_scope r
    WHERE s.module1_run_id = r.run_id
      AND s.row_hash IS DISTINCT FROM
          msbf_m1.m1_14_hash_jsonb(to_jsonb(s) - 'row_hash' - 'created_at')
),
component_mismatch AS (
    SELECT
        'COMP|' || c.scenario_id || '|' || c.merchant_application_id || '|' || c.component_code AS entity_key,
        c.calculation_hash AS stored_hash,
        msbf_m1.m1_14_hash_jsonb(to_jsonb(c) - 'calculation_hash' - 'created_at') AS recomputed_hash
    FROM msbf_m1.unit_economics_component_value c
    CROSS JOIN run_scope r
    WHERE c.module1_run_id = r.run_id
      AND c.calculation_hash IS DISTINCT FROM
          msbf_m1.m1_14_hash_jsonb(to_jsonb(c) - 'calculation_hash' - 'created_at')
)
SELECT entity_key,stored_hash,recomputed_hash
FROM snapshot_mismatch
UNION ALL
SELECT entity_key,stored_hash,recomputed_hash
FROM component_mismatch
ORDER BY entity_key;

/* 20 — Blocking Resolution Errors */
SELECT resolution_error_id,run_id,profile_domain,scope_key,error_code,severity,
       error_message,created_at
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT min(module1_run_id) FROM _m1_14_detail_economics)
  AND severity='BLOCKING'
ORDER BY resolution_error_id;
