/* M2.2 Program 146 v0.2R2 — Master Report. Read-only. */
WITH r AS(SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),c AS(SELECT * FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)),ev AS(SELECT count(*) FILTER(WHERE evidence_code LIKE 'M2_2_POS_%') AS positive_checks,count(*) FILTER(WHERE evidence_code LIKE 'M2_2_POS_%' AND status='PASS') AS positive_passes,count(*) FILTER(WHERE evidence_code LIKE 'M2_2_NEG_%') AS negative_checks,count(*) FILTER(WHERE evidence_code LIKE 'M2_2_NEG_%' AND status='PASS') AS negative_passes,count(*) FILTER(WHERE status='FAIL') AS failed_evidence FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)),dist AS(SELECT count(*) FILTER(WHERE pricing_disposition_code='STRUCTURE_READY') AS structure_ready_rows,count(*) FILTER(WHERE pricing_disposition_code='COUNTEROFFER_FOUNDATION_REVIEW') AS counteroffer_foundation_rows,count(*) FILTER(WHERE pricing_disposition_code='NO_STRUCTURE_INSUFFICIENT_EVIDENCE') AS insufficient_rows,count(*) FILTER(WHERE pricing_disposition_code='NO_STRUCTURE_POLICY_DECLINE') AS policy_decline_rows FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=(SELECT run_id FROM r)),gate AS(SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' ORDER BY review_version DESC LIMIT 1),diag AS(
 SELECT
  (
   SELECT count(*)
   FROM msbf_m2.v_m2_2_matched_scenario_comparison
   WHERE module1_run_id=(SELECT run_id FROM r)
     AND stress_structure_improvement_flag
  ) AS stress_improvements,
  (
   SELECT count(*)
   FROM msbf_m2.application_pricing_structure_latest
   WHERE module1_run_id=(SELECT run_id FROM r)
     AND stress_nonimprovement_applied_flag
  ) AS stress_floor_applied_rows
)
SELECT r.run_status,c.contract_status,gate.result_status AS acceptance_gate_status,c.methodology_version,c.request_contract_code,c.pricing_contract_code,c.source_m2_1_combined_hash,c.source_m1_3_application_hash,c.policy_rows,c.template_rows,c.reason_rows,c.disposition_rows,c.request_snapshot_rows,c.request_latest_rows,c.request_archive_rows,c.candidate_rows,c.pricing_snapshot_rows,c.pricing_latest_rows,c.pricing_archive_rows,c.comparison_rows,c.canonical_entities,dist.structure_ready_rows,dist.counteroffer_foundation_rows,dist.insufficient_rows,dist.policy_decline_rows,ev.positive_passes,ev.positive_checks,ev.negative_passes,ev.negative_checks,ev.failed_evidence,diag.stress_improvements,diag.stress_floor_applied_rows,c.policy_set_hash,c.template_set_hash,c.reason_set_hash,c.disposition_set_hash,c.request_snapshot_set_hash,c.request_latest_set_hash,c.request_archive_set_hash,c.candidate_set_hash,c.pricing_snapshot_set_hash,c.pricing_latest_set_hash,c.pricing_archive_set_hash,c.request_contract_set_hash,c.pricing_contract_set_hash,c.combined_set_hash,
CASE WHEN r.run_status='M2_2_ACCEPTED' AND c.contract_status='ACCEPTED' AND gate.result_status='PASS' AND ev.positive_passes=120 AND ev.positive_checks=120 AND ev.negative_passes=20 AND ev.negative_checks=20 AND ev.failed_evidence=0 AND diag.stress_improvements=0 THEN 'PASS' ELSE 'FAIL' END AS overall_m2_2_status
FROM r CROSS JOIN c CROSS JOIN ev CROSS JOIN dist CROSS JOIN gate CROSS JOIN diag;
