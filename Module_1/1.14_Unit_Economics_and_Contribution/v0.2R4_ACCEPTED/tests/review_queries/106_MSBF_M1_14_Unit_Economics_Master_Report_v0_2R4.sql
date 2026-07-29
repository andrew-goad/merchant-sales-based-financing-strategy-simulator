/* ============================================================================
MSBF M1.14 Unit Economics & Risk-Adjusted Contribution — Master Report
Program : 106_MSBF_M1_14_Unit_Economics_Master_Report_v0_2R4.sql
Version : v0.2R4
Purpose : Produce a single executive-quality acceptance and portfolio summary
          from persisted M1.14 evidence. No business logic is regenerated.
Mode    : Read-only.
Required: overall_m1_14_status = PASS after formal acceptance.
============================================================================ */

WITH r AS (
    SELECT run_id,run_status,population_id,as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), gate AS (
    SELECT * FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM r)
      AND gate_id='M1_14_UNIT_ECONOMICS_CONTRIBUTION'
    ORDER BY review_version DESC LIMIT 1
), pos AS (
    SELECT count(*) checks,count(*) FILTER(WHERE status='PASS') passes,
           count(*) FILTER(WHERE status='FAIL') failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_14_POS_%'
), neg AS (
    SELECT count(*) controls,count(*) FILTER(WHERE status='PASS') passes,
           count(*) FILTER(WHERE status='FAIL') failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_14_NEG_%'
), e AS (
    SELECT e.*,sr.scenario_code
    FROM msbf_m1.application_unit_economics_snapshot e
    JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
    WHERE e.module1_run_id=(SELECT run_id FROM r)
), totals AS (
    SELECT
        count(*) AS snapshot_rows,
        count(DISTINCT merchant_application_id) AS applications,
        count(DISTINCT scenario_id) AS scenarios,
        sum(gross_finance_revenue_amount) AS gross_revenue,
        sum(total_non_loss_cost_amount) AS non_loss_cost,
        sum(comparative_expected_loss_amount) AS comparative_loss,
        sum(risk_capital_charge_amount) AS capital_charge,
        sum(risk_adjusted_contribution_amount) AS risk_adjusted_contribution,
        sum(hurdle_required_contribution_amount) AS hurdle_requirement,
        sum(economic_surplus_amount) AS economic_surplus,
        avg(annualized_gross_yield_rate) AS avg_annualized_gross_yield,
        avg(annualized_risk_adjusted_return_rate) AS avg_annualized_risk_adjusted_return,
        count(*) FILTER(WHERE economic_status='ABOVE_HURDLE') AS above_hurdle_rows,
        count(*) FILTER(WHERE economic_status='BELOW_HURDLE') AS below_hurdle_rows,
        count(*) FILTER(WHERE economic_status='NEGATIVE_CONTRIBUTION') AS negative_contribution_rows,
        count(*) FILTER(WHERE economic_status='INSUFFICIENT_EVIDENCE') AS insufficient_evidence_rows,
        count(*) FILTER(WHERE manual_review_recommended_flag) AS manual_review_rows,
        count(*) FILTER(WHERE hard_stop_recommended_flag) AS hard_stop_rows,
        count(*) FILTER(WHERE stress_economic_worsening_flag) AS stress_worsenings,
        count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY' AND risk_adjusted_contribution_amount>baseline_risk_adjusted_contribution_amount) AS stress_contribution_improvements,
        count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY' AND annualized_risk_adjusted_return_rate>baseline_annualized_risk_adjusted_return_rate) AS stress_return_improvements,
        count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY' AND economic_tier<baseline_economic_tier) AS stress_tier_improvements
    FROM e
), hashes AS (
    SELECT
        max(metric_value_text) FILTER(WHERE evidence_code='M1_14_SNAPSHOT_SET_HASH') AS snapshot_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_14_COMPONENT_SET_HASH') AS component_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_14_COMBINED_SET_HASH') AS combined_hash,
        (max(metric_value_numeric) FILTER(WHERE evidence_code='M1_14_CANONICAL_MISMATCH_COUNT'))::bigint AS mismatch_count
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
), policy AS (
    SELECT status,profile_payload
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_14_UNIT_ECONOMICS_CONTRIBUTION' AND profile_version=1
), boundaries AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))
      + (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS downstream_rows,
        (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors
)
SELECT
    r.run_id,r.run_status,r.population_id,r.as_of_date,
    gate.review_version,gate.result_status AS gate_status,
    pos.checks AS positive_checks,pos.passes AS positive_passes,pos.failures AS positive_failures,
    neg.controls AS negative_controls,neg.passes AS negative_passes,neg.failures AS negative_failures,
    totals.*,
    (SELECT count(*) FROM msbf_m1.unit_economics_component_value WHERE module1_run_id=r.run_id) AS component_rows,
    hashes.snapshot_hash,hashes.component_hash,hashes.combined_hash,hashes.mismatch_count,
    policy.profile_payload->>'methodology_version' AS methodology_version,
    policy.profile_payload->>'contribution_basis_code' AS contribution_basis_code,
    policy.profile_payload->>'comparative_loss_basis_code' AS comparative_loss_basis_code,
    policy.profile_payload->>'hurdle_basis_code' AS hurdle_basis_code,
    boundaries.downstream_rows,boundaries.blocking_errors,
    CASE
        WHEN r.run_status='M1_14_ACCEPTED'
         AND gate.result_status='PASS'
         AND pos.checks=82 AND pos.passes=82 AND pos.failures=0
         AND neg.controls=7 AND neg.passes=7 AND neg.failures=0
         AND totals.snapshot_rows=1500
         AND (SELECT count(*) FROM msbf_m1.unit_economics_component_value WHERE module1_run_id=r.run_id)=21000
         AND hashes.mismatch_count=0
         AND totals.stress_contribution_improvements=0
         AND totals.stress_return_improvements=0
         AND totals.stress_tier_improvements=0
         AND boundaries.downstream_rows=0 AND boundaries.blocking_errors=0
        THEN 'PASS' ELSE 'FAIL'
    END AS overall_m1_14_status
FROM r CROSS JOIN gate CROSS JOIN pos CROSS JOIN neg CROSS JOIN totals CROSS JOIN hashes CROSS JOIN policy CROSS JOIN boundaries;
