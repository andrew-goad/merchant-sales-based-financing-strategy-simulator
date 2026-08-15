/* M2.2 Program 140A — Failed Generation Recovery Check. Read-only. */
WITH r AS(SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),x AS(
SELECT
 (SELECT count(*) FROM msbf_m2.application_request_structure_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS request_rows,
 (SELECT count(*) FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=(SELECT run_id FROM r)) AS candidate_rows,
 (SELECT count(*) FROM msbf_m2.application_pricing_structure_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS pricing_rows,
 (SELECT count(*) FROM msbf_m2.application_request_structure_archive WHERE module1_run_id=(SELECT run_id FROM r))+(SELECT count(*) FROM msbf_m2.application_pricing_structure_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS archive_rows,
 (SELECT count(*) FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)) AS registry_rows,
 (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M2_2_%') AS evidence_rows,
 (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER') AS acceptance_rows)
SELECT r.run_status,x.*,CASE WHEN r.run_status='M2_1_ACCEPTED' AND x.request_rows=0 AND x.candidate_rows=0 AND x.pricing_rows=0 AND x.archive_rows=0 AND x.registry_rows=0 AND x.evidence_rows=0 AND x.acceptance_rows=0 THEN 'PASS' ELSE 'FAIL' END AS recovery_status FROM r CROSS JOIN x;
