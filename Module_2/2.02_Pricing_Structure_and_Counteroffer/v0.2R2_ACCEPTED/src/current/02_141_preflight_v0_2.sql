/* ============================================================================
M2.2 Program 141 — Hard-Stop Preflight Validation
Read-only. Required: preflight_status = PASS.
============================================================================ */
SET statement_timeout='20min'; SET jit=off;
DROP TABLE IF EXISTS _m2_2_preflight;
CREATE TEMP TABLE _m2_2_preflight ON COMMIT PRESERVE ROWS AS
WITH r AS(SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
p AS(SELECT * FROM msbf_ctl.m2_2_policy_profile WHERE policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1'),
m21 AS(SELECT * FROM msbf_ctl.m2_1_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)),
gates AS(
 SELECT
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING' ORDER BY review_version DESC LIMIT 1) AS m2_1_gate_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) AS m1_3_gate_status),
source AS(
 SELECT count(*) AS routing_rows,count(DISTINCT merchant_application_id) AS applications,count(DISTINCT scenario_id) AS scenarios,
 count(*) FILTER(WHERE scenario_code='BASELINE') AS baseline_rows,count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_rows,
 count(*) FILTER(WHERE final_route_code='ELIGIBLE_FOR_OFFER_DESIGN') AS eligible_rows,
 count(*) FILTER(WHERE final_route_code='MANUAL_REVIEW') AS manual_review_rows,
 count(*) FILTER(WHERE final_route_code='INSUFFICIENT_EVIDENCE') AS insufficient_rows,
 count(*) FILTER(WHERE final_route_code='DECLINE_POLICY') AS decline_rows
 FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=(SELECT run_id FROM r)),
requests AS(SELECT count(*) AS request_rows,count(DISTINCT merchant_application_id) AS request_applications FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)),
g2 AS(SELECT count(*) AS g2_rows,count(DISTINCT merchant_application_id) AS g2_applications,count(DISTINCT scenario_id) AS g2_scenarios FROM msbf_m1.v_m1_17_g2_integrated_consumption WHERE module1_run_id=(SELECT run_id FROM r)),
refs AS(
 SELECT (SELECT count(*) FROM msbf_m2.pricing_structure_candidate_template WHERE module1_run_id=(SELECT run_id FROM r)) AS template_rows,
 (SELECT count(*) FROM msbf_m2.pricing_structure_reason_definition WHERE module1_run_id=(SELECT run_id FROM r)) AS reason_rows,
 (SELECT count(*) FROM msbf_m2.pricing_structure_disposition_definition WHERE module1_run_id=(SELECT run_id FROM r)) AS disposition_rows),
targets AS(
 SELECT
 (SELECT count(*) FROM msbf_m2.application_request_structure_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS request_snapshot_rows,
 (SELECT count(*) FROM msbf_m2.application_request_structure_latest WHERE module1_run_id=(SELECT run_id FROM r)) AS request_latest_rows,
 (SELECT count(*) FROM msbf_m2.application_request_structure_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS request_archive_rows,
 (SELECT count(*) FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=(SELECT run_id FROM r)) AS candidate_rows,
 (SELECT count(*) FROM msbf_m2.application_pricing_structure_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS pricing_snapshot_rows,
 (SELECT count(*) FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=(SELECT run_id FROM r)) AS pricing_latest_rows,
 (SELECT count(*) FROM msbf_m2.application_pricing_structure_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS pricing_archive_rows,
 (SELECT count(*) FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)) AS registry_rows,
 (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M2_2_%') AS evidence_rows,
 (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER') AS acceptance_rows),
boundary AS(
 SELECT count(*) AS prohibited_columns FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN('application_request_structure_snapshot','application_request_structure_latest','application_request_structure_archive','application_pricing_structure_candidate','application_pricing_structure_snapshot','application_pricing_structure_latest','application_pricing_structure_archive') AND lower(column_name) IN('approval_flag','decline_flag','final_decision_code','adverse_action_code','booking_status','funding_status'))
SELECT r.run_id,r.run_status,p.policy_status,p.configuration_hash,m21.contract_status AS source_m2_1_contract_status,m21.combined_set_hash AS source_m2_1_combined_hash,gates.m2_1_gate_status,gates.m1_3_gate_status,
 source.*,requests.*,g2.*,refs.*,targets.*,boundary.prohibited_columns,
 CASE WHEN r.run_status='M2_1_ACCEPTED' AND p.policy_status='APPROVED' AND m21.contract_status='ACCEPTED' AND m21.combined_set_hash='e5ace7f32060ffb191c7bd0f8dd0c863' AND gates.m2_1_gate_status='PASS' AND gates.m1_3_gate_status='PASS'
 AND source.routing_rows=1500 AND source.applications=750 AND source.scenarios=2 AND source.baseline_rows=750 AND source.stress_rows=750 AND source.eligible_rows=59 AND source.manual_review_rows=190 AND source.insufficient_rows=178 AND source.decline_rows=1073
 AND requests.request_rows=750 AND requests.request_applications=750 AND g2.g2_rows=1500 AND g2.g2_applications=750 AND g2.g2_scenarios=2 AND refs.template_rows=5 AND refs.reason_rows=18 AND refs.disposition_rows=4
 AND targets.request_snapshot_rows=0 AND targets.request_latest_rows=0 AND targets.request_archive_rows=0 AND targets.candidate_rows=0 AND targets.pricing_snapshot_rows=0 AND targets.pricing_latest_rows=0 AND targets.pricing_archive_rows=0 AND targets.registry_rows=0 AND targets.evidence_rows=0 AND targets.acceptance_rows=0 AND boundary.prohibited_columns=0 THEN 'PASS' ELSE 'FAIL' END AS preflight_status
FROM r CROSS JOIN p CROSS JOIN m21 CROSS JOIN gates CROSS JOIN source CROSS JOIN requests CROSS JOIN g2 CROSS JOIN refs CROSS JOIN targets CROSS JOIN boundary;
DO $guard$ DECLARE v record; BEGIN SELECT * INTO v FROM _m2_2_preflight; IF v.preflight_status<>'PASS' THEN RAISE EXCEPTION 'M2.2 preflight failed: %',row_to_json(v); END IF; PERFORM msbf_ctl.m2_2_assert_generation_ready(v.run_id); END; $guard$;
SELECT * FROM _m2_2_preflight;
