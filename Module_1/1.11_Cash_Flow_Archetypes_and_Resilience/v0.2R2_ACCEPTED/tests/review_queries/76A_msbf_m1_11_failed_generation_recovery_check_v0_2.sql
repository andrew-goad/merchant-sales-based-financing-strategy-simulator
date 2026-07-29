/* M1.11 failed-generation recovery check v0.2 — read only */
WITH r AS (SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
counts AS (
 SELECT (SELECT count(*) FROM msbf_m1.application_operating_resilience_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) snapshot_rows,
        (SELECT count(*) FROM msbf_m1.operating_resilience_component_value WHERE module1_run_id=(SELECT run_id FROM r)) component_rows,
        (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_11_%') evidence_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE') gate_rows,
        (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') blocking_errors)
SELECT r.*,c.*,
 CASE WHEN r.run_status='M1_10_ACCEPTED' AND c.snapshot_rows=0 AND c.component_rows=0 AND c.evidence_rows=0 AND c.gate_rows=0 AND c.blocking_errors=0 THEN 'PASS' ELSE 'FAIL' END recovery_state_status
FROM r CROSS JOIN counts c;
