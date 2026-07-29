/* ============================================================================
MSBF M1.12 Merchant Risk Components & Integrated Risk Proxy — Master Report
Version : v0.2
Purpose : Return a single executive acceptance record covering governance,
          cardinality, risk distribution, evidence routing, stress migration,
          deterministic reconciliation, and final stage status.
Mode    : Read-only after M1.12 acceptance.
Required: overall_m1_12_status = PASS.
============================================================================ */

WITH
/* 1. Governed run and gate state */
r AS (
 SELECT run_id,run_status,population_id,as_of_date
 FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), gate AS (
 SELECT review_version,result_status,reviewed_at
 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_12_INTEGRATED_RISK_PROXY'
 ORDER BY review_version DESC LIMIT 1
), policy AS (
 SELECT status,profile_payload
 FROM msbf_ctl.policy_profile
 WHERE profile_code='M1_12_INTEGRATED_RISK_PROXY' AND profile_version=1
),
/* 2. Physical population and distribution */
counts AS (
 SELECT count(*) AS snapshots,count(DISTINCT merchant_application_id) AS applications,
        count(DISTINCT scenario_id) AS scenarios,
        count(*) FILTER(WHERE integrated_risk_evidence_status='COMPLETE') AS complete_rows,
        count(*) FILTER(WHERE integrated_risk_evidence_status='PARTIAL') AS partial_rows,
        count(*) FILTER(WHERE integrated_risk_evidence_status='BLOCKED') AS blocked_rows,
        count(*) FILTER(WHERE manual_review_recommended_flag) AS manual_review_rows,
        count(*) FILTER(WHERE hard_stop_recommended_flag) AS hard_stop_rows,
        count(*) FILTER(WHERE integrated_risk_tier=1) AS tier_1_rows,
        count(*) FILTER(WHERE integrated_risk_tier=2) AS tier_2_rows,
        count(*) FILTER(WHERE integrated_risk_tier=3) AS tier_3_rows,
        count(*) FILTER(WHERE integrated_risk_tier=4) AS tier_4_rows,
        count(*) FILTER(WHERE integrated_risk_tier=5) AS tier_5_rows,
        round(avg(integrated_risk_score),6) AS average_integrated_risk_score,
        round(avg(synthetic_merchant_risk_proxy),8) AS average_synthetic_risk_proxy
 FROM msbf_m1.application_integrated_risk_proxy_snapshot
 WHERE module1_run_id=(SELECT run_id FROM r)
), component AS (
 SELECT count(*) AS component_rows,count(DISTINCT component_code) AS component_codes,
        count(*) FILTER(WHERE component_status='AVAILABLE') AS available_component_rows,
        count(*) FILTER(WHERE component_status='UNAVAILABLE') AS unavailable_component_rows,
        round(avg(weighted_risk_points),6) AS average_weighted_risk_points
 FROM msbf_m1.integrated_risk_component_value
 WHERE module1_run_id=(SELECT run_id FROM r)
), stress AS (
 SELECT count(*) FILTER(WHERE sr.scenario_code='RECESSION_ENERGY' AND s.stress_risk_worsening_flag) AS stress_worsenings,
        count(*) FILTER(WHERE sr.scenario_code='RECESSION_ENERGY' AND s.integrated_risk_score<s.baseline_integrated_risk_score) AS score_improvements,
        count(*) FILTER(WHERE sr.scenario_code='RECESSION_ENERGY' AND s.integrated_risk_tier<s.baseline_risk_tier) AS tier_improvements
 FROM msbf_m1.application_integrated_risk_proxy_snapshot s
 JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
 WHERE s.module1_run_id=(SELECT run_id FROM r)
), evidence AS (
 SELECT count(*) FILTER(WHERE evidence_code LIKE 'M1_12_POS_%') AS positive_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_12_POS_%' AND status='PASS') AS positive_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_12_NEG_%') AS negative_controls,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_12_NEG_%' AND status='PASS') AS negative_passes,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_12_SNAPSHOT_SET_HASH') AS snapshot_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_12_COMPONENT_SET_HASH') AS component_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_12_COMBINED_SET_HASH') AS combined_hash,
        (max(metric_value_numeric) FILTER(WHERE evidence_code='M1_12_CANONICAL_MISMATCH_COUNT'))::bigint AS canonical_mismatches
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
), boundary AS (
 SELECT (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
       +(SELECT count(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM r))
       +(SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
       +(SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))
       +(SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS downstream_rows,
        (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors
)
SELECT r.run_id,r.run_status,r.population_id,r.as_of_date,
       gate.review_version,gate.result_status AS gate_status,gate.reviewed_at,
       policy.status AS policy_status,
       policy.profile_payload->>'methodology_version' AS methodology_version,
       policy.profile_payload->>'composite_score_basis' AS composite_score_basis,
       counts.*,component.*,stress.*,evidence.*,boundary.*,
       CASE WHEN r.run_status='M1_12_ACCEPTED' AND gate.result_status='PASS'
         AND counts.snapshots=1500 AND component.component_rows=10500
         AND counts.applications=750 AND counts.scenarios=2 AND component.component_codes=7
         AND stress.score_improvements=0 AND stress.tier_improvements=0
         AND evidence.positive_checks=80 AND evidence.positive_passes=80
         AND evidence.negative_controls=7 AND evidence.negative_passes=7
         AND evidence.canonical_mismatches=0
         AND boundary.downstream_rows=0 AND boundary.blocking_errors=0
         AND policy.status='APPROVED'
         AND policy.profile_payload->>'methodology_version'='M1_12_METHOD_V1'
         AND policy.profile_payload->>'composite_score_basis'='SUM_PERSISTED_WEIGHTED_RISK_COMPONENTS'
       THEN 'PASS' ELSE 'FAIL' END AS overall_m1_12_status
FROM r CROSS JOIN gate CROSS JOIN policy CROSS JOIN counts CROSS JOIN component CROSS JOIN stress CROSS JOIN evidence CROSS JOIN boundary;
