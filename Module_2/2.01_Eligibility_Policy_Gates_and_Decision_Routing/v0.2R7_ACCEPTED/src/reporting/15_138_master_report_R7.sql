/* ============================================================================
MSBF M2.1 — Eligibility, Policy Gates & Decision Routing Foundations
Program 138 — Executive Master Report
Version v0.2R7
Read-only one-row acceptance and portfolio summary.
============================================================================ */
WITH r AS (
 SELECT run_id,run_code,run_version,run_status,as_of_date FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), c AS (
 SELECT * FROM msbf_ctl.m2_1_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)
), controls AS (
 SELECT
  count(*) FILTER(WHERE evidence_code LIKE 'M2_1_POS_%') positive_checks,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_1_POS_%' AND status='PASS') positive_passes,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_1_NEG_%') negative_checks,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_1_NEG_%' AND status='PASS') negative_passes
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
), routes AS (
 SELECT
  count(*) FILTER(WHERE final_route_code='ELIGIBLE_FOR_OFFER_DESIGN') eligible_rows,
  count(*) FILTER(WHERE final_route_code='MANUAL_REVIEW') review_rows,
  count(*) FILTER(WHERE final_route_code='INSUFFICIENT_EVIDENCE') insufficient_rows,
  count(*) FILTER(WHERE final_route_code='DECLINE_POLICY') decline_rows,
  count(*) FILTER(WHERE hard_stop_flag) hard_stop_rows,
  count(*) FILTER(WHERE stress_floor_applied_flag) stress_floor_rows,
  count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY' AND final_route_rank<baseline_route_rank) stress_improvements
 FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=(SELECT run_id FROM r)
), evidence AS (
 SELECT count(*) FILTER(WHERE routing_evidence_status='COMPLETE') complete_rows,
        count(*) FILTER(WHERE routing_evidence_status='PARTIAL') partial_rows,
        count(*) FILTER(WHERE routing_evidence_status='BLOCKED') blocked_rows
 FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=(SELECT run_id FROM r)
), gate AS (
 SELECT result_status FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING' ORDER BY review_version DESC LIMIT 1
)
SELECT r.run_code,r.run_version,r.run_status,r.as_of_date,
 c.contract_code,c.contract_version,c.schema_version,c.methodology_version,c.contract_status,
 c.source_g2_combined_hash,c.policy_configuration_hash,
 c.strategy_campaign_rows,c.gate_definition_rows,c.reason_code_rows,c.outcome_definition_rows,
 c.gate_result_rows,c.routing_snapshot_rows,c.latest_rows,c.archive_rows,c.comparison_rows,c.canonical_entities,
 routes.*,evidence.*,controls.*,
 c.campaign_set_hash,c.gate_definition_set_hash,c.reason_code_set_hash,c.outcome_definition_set_hash,
 c.gate_result_set_hash,c.routing_snapshot_set_hash,c.latest_set_hash,c.archive_set_hash,c.contract_set_hash,c.combined_set_hash,
 gate.result_status AS acceptance_gate_status,
 (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=r.run_id AND severity='BLOCKING') AS blocking_errors,
 CASE WHEN r.run_status='M2_1_ACCEPTED' AND c.contract_status='ACCEPTED' AND gate.result_status='PASS'
       AND controls.positive_passes=112 AND controls.negative_passes=20 AND routes.stress_improvements=0
       AND (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=r.run_id AND severity='BLOCKING')=0
      THEN 'PASS' ELSE 'FAIL' END AS overall_m2_1_status
FROM r CROSS JOIN c CROSS JOIN controls CROSS JOIN routes CROSS JOIN evidence CROSS JOIN gate;
