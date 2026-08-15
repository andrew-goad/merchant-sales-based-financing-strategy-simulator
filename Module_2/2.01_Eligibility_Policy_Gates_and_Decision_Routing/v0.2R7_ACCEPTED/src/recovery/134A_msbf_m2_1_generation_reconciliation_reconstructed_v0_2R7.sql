/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M2.1 — Eligibility, Policy Gates & Decision Routing Foundations

Program : 134A_msbf_m2_1_generation_reconciliation_reconstructed_v0_2R7.sql
Version : v0.2R7
Title   : Committed Generation Checkpoint Reconstruction

Purpose
Reconstruct the Program 134 checkpoint from persisted M2.1 rows when DBeaver loses or suppresses the generation result tab.

Inputs
Committed M2.1 generation tables and contract registry.

Outputs
One read-only generation reconciliation result.

Stage boundary
Use only after Program 134 committed successfully. It does not modify data, evidence, hashes, lifecycle or run status.

Execution standard
Run the complete file with DBeaver Execute SQL Script. Stop at the first
PostgreSQL error. Never use Retry, Skip or Skip All. Execute ROLLBACK after a
failed transactional program.
============================================================================ */

WITH r AS (
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), c AS (
 SELECT * FROM msbf_ctl.m2_1_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)
), counts AS (
 SELECT
  (SELECT count(*) FROM msbf_m2.strategy_campaign WHERE module1_run_id=(SELECT run_id FROM r)) campaign_rows,
  (SELECT count(*) FROM msbf_m2.policy_gate_definition WHERE module1_run_id=(SELECT run_id FROM r)) gate_definition_rows,
  (SELECT count(*) FROM msbf_m2.reason_code_definition WHERE module1_run_id=(SELECT run_id FROM r)) reason_rows,
  (SELECT count(*) FROM msbf_m2.routing_outcome_definition WHERE module1_run_id=(SELECT run_id FROM r)) outcome_rows,
  (SELECT count(*) FROM msbf_m2.application_policy_gate_result WHERE module1_run_id=(SELECT run_id FROM r)) gate_result_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) snapshot_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=(SELECT run_id FROM r)) latest_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=(SELECT run_id FROM r)) archive_rows,
  (SELECT count(*) FROM msbf_m2.v_m2_1_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM r)) comparison_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code IN(
    'M2_1_CAMPAIGN_ROW_COUNT','M2_1_GATE_DEFINITION_ROW_COUNT','M2_1_REASON_CODE_ROW_COUNT',
    'M2_1_OUTCOME_DEFINITION_ROW_COUNT','M2_1_GATE_RESULT_ROW_COUNT','M2_1_ROUTING_SNAPSHOT_ROW_COUNT',
    'M2_1_LATEST_ROW_COUNT','M2_1_ARCHIVE_ROW_COUNT','M2_1_COMPARISON_ROW_COUNT',
    'M2_1_CANONICAL_ENTITY_COUNT','M2_1_CANONICAL_MISMATCH_COUNT','M2_1_CAMPAIGN_SET_HASH',
    'M2_1_GATE_DEFINITION_SET_HASH','M2_1_REASON_CODE_SET_HASH','M2_1_OUTCOME_DEFINITION_SET_HASH',
    'M2_1_GATE_RESULT_SET_HASH','M2_1_ROUTING_SNAPSHOT_SET_HASH','M2_1_COMBINED_SET_HASH')) generation_evidence_rows
)
SELECT r.run_status,c.contract_status,counts.*,c.canonical_entities,c.campaign_set_hash,
 c.gate_definition_set_hash,c.reason_code_set_hash,c.outcome_definition_set_hash,
 c.gate_result_set_hash,c.routing_snapshot_set_hash,c.latest_set_hash,c.archive_set_hash,
 c.contract_set_hash,c.combined_set_hash,
 CASE WHEN r.run_status IN ('M2_1_GENERATED','M2_1_VALIDATED','M2_1_ACCEPTED')
       AND c.contract_status IN ('GENERATED','VALIDATED','ACCEPTED')
       AND counts.campaign_rows=1 AND counts.gate_definition_rows=12 AND counts.reason_rows=23
       AND counts.outcome_rows=4 AND counts.gate_result_rows=18000 AND counts.snapshot_rows=1500
       AND counts.latest_rows=1500 AND counts.archive_rows=1500 AND counts.comparison_rows=750
       AND counts.generation_evidence_rows=18 AND c.canonical_entities=22541
       AND c.combined_set_hash IS NOT NULL
      THEN 'PASS' ELSE 'FAIL' END AS generation_reconciliation_status
FROM r CROSS JOIN c CROSS JOIN counts;
