/* M1.10 failed-generation recovery check — run only after ROLLBACK. */
WITH r AS (
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), x AS (
 SELECT
  (SELECT count(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)) obligation_rows,
  (SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) capacity_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_10_%') evidence_rows,
  (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY') gate_rows,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') blocking_errors
)
SELECT r.run_id,r.run_status,x.*,
 CASE WHEN r.run_status='M1_9_ACCEPTED' AND x.obligation_rows=0 AND x.capacity_rows=0
       AND x.evidence_rows=0 AND x.gate_rows=0 AND x.blocking_errors=0
      THEN 'PASS' ELSE 'FAIL' END recovery_state_status
FROM r CROSS JOIN x;
