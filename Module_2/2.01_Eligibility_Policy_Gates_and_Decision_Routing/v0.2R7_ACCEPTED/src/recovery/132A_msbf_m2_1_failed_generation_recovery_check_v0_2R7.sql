/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M2.1 — Eligibility, Policy Gates & Decision Routing Foundations

Program : 132A_msbf_m2_1_failed_generation_recovery_check_v0_2R7.sql
Version : v0.2R7
Title   : Failed-Generation Rollback-State Recovery Check

Purpose
Confirm that a failed or cancelled Program 134 transaction left the accepted G2 boundary and M2.1 schema/reference layer intact while all M2.1 application, contract, evidence and gate-result targets remain pristine.

Inputs
Database state after user executes ROLLBACK following failed Program 134.

Outputs
One read-only recovery checkpoint.

Stage boundary
Use only after failed or cancelled generation. It never repairs data or changes run status.

Execution standard
Run the complete file with DBeaver Execute SQL Script. Stop at the first
PostgreSQL error. Never use Retry, Skip or Skip All. Execute ROLLBACK after a
failed transactional program.
============================================================================ */

WITH r AS (
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), c AS (
 SELECT
  (SELECT count(*) FROM msbf_m2.strategy_campaign WHERE module1_run_id=(SELECT run_id FROM r)) campaign_rows,
  (SELECT count(*) FROM msbf_m2.policy_gate_definition WHERE module1_run_id=(SELECT run_id FROM r)) gate_definition_rows,
  (SELECT count(*) FROM msbf_m2.reason_code_definition WHERE module1_run_id=(SELECT run_id FROM r)) reason_rows,
  (SELECT count(*) FROM msbf_m2.routing_outcome_definition WHERE module1_run_id=(SELECT run_id FROM r)) outcome_rows,
  (SELECT count(*) FROM msbf_m2.application_policy_gate_result WHERE module1_run_id=(SELECT run_id FROM r)) gate_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) snapshot_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=(SELECT run_id FROM r)) latest_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=(SELECT run_id FROM r)) archive_rows,
  (SELECT count(*) FROM msbf_ctl.m2_1_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)) registry_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M2_1_%') evidence_rows,
  (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING') acceptance_rows,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') blocking_errors
)
SELECT r.run_status,c.*,
 CASE WHEN r.run_status='M1_17_ACCEPTED'
       AND c.campaign_rows=1 AND c.gate_definition_rows=12 AND c.reason_rows=23 AND c.outcome_rows=4
       AND c.gate_rows=0 AND c.snapshot_rows=0 AND c.latest_rows=0 AND c.archive_rows=0
       AND c.registry_rows=0 AND c.evidence_rows=0 AND c.acceptance_rows=0 AND c.blocking_errors=0
      THEN 'PASS' ELSE 'FAIL' END AS recovery_status
FROM r CROSS JOIN c;
