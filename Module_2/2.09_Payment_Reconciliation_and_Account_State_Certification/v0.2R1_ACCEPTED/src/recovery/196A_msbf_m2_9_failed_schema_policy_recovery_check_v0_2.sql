/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.9 — Payment Reconciliation, Exception Resolution
             & Account State Certification

Program     : 196A_msbf_m2_9_failed_schema_policy_recovery_check_v0_2.sql
Version     : v0.2

Purpose
-------
Read-only proof that a failed Program 196 transaction left no M2.9 objects,
evidence, or acceptance rows while the accepted M2.8 run, contract, gate, and
combined hash remain unchanged.

Required result
---------------
recovery_status = PASS.
============================================================================ */
WITH run_context AS(
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
source_registry AS(
 SELECT count(*) registry_rows,max(contract_status) contract_status,max(contract_code) contract_code,
 max(contract_version) contract_version,max(schema_version) schema_version,max(combined_set_hash) combined_set_hash
 FROM msbf_ctl.m2_8_servicing_execution_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)),
source_gate AS(
 SELECT count(*) gate_rows,max(result_status) gate_status FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND review_version=1),
object_state AS(
 SELECT count(*) FILTER(WHERE table_schema='msbf_ctl' AND table_name IN('m2_9_policy_profile','m2_9_reconciliation_certification_contract_registry')) control_tables,
 count(*) FILTER(WHERE table_schema='msbf_m2' AND table_name IN('payment_reconciliation_outcome_definition','exception_resolution_action_definition','account_state_certification_definition','payment_reconciliation_reason_definition','account_reconciliation_source_snapshot','payment_reconciliation_source_event','lifecycle_certification_source_transition','payment_event_reconciliation_snapshot','payment_exception_case_snapshot','account_payment_reconciliation_snapshot','account_state_certification_snapshot','payment_reconciliation_portfolio_summary','application_payment_reconciliation_certification_latest','application_payment_reconciliation_certification_archive')) business_tables
 FROM information_schema.tables),
row_state AS(
 SELECT (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context) AND evidence_code LIKE 'M2_9_%') evidence_rows,
 (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION') acceptance_rows,
 (SELECT count(*) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION') gate_catalog_rows)
SELECT run_context.run_status,source_registry.registry_rows source_registry_rows,source_registry.contract_status source_contract_status,
source_registry.contract_code source_contract_code,source_registry.contract_version source_contract_version,
source_registry.schema_version source_schema_version,source_registry.combined_set_hash source_combined_set_hash,
source_gate.gate_rows source_gate_rows,source_gate.gate_status source_gate_status,
object_state.control_tables,object_state.business_tables,row_state.evidence_rows,row_state.acceptance_rows,row_state.gate_catalog_rows,
CASE WHEN run_context.run_status='M2_8_ACCEPTED' AND source_registry.registry_rows=1 AND source_registry.contract_status='ACCEPTED'
AND source_registry.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND source_registry.contract_version=1 AND source_registry.schema_version='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1'
AND source_registry.combined_set_hash='ab32d80ba20c2c8f0a6ec9ec97c2ed26' AND source_gate.gate_rows=1 AND source_gate.gate_status='PASS'
AND object_state.control_tables=0 AND object_state.business_tables=0 AND row_state.evidence_rows=0 AND row_state.acceptance_rows=0 AND row_state.gate_catalog_rows=0
THEN 'PASS' ELSE 'FAIL' END recovery_status
FROM run_context CROSS JOIN source_registry CROSS JOIN source_gate CROSS JOIN object_state CROSS JOIN row_state;
