/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.8 — Servicing Execution Simulation, Payment Processing
             & Account Lifecycle Control

Program     : 188A_msbf_m2_8_failed_schema_policy_recovery_check_v0_2.sql
Version     : v0.2

Purpose
-------
Verify that a failed Program 188 transaction left no M2.8 objects, evidence,
or gate records while accepted M2.7 remains unchanged.

Stage boundary
--------------
All servicing, payment, processor-reference, return, retry, and lifecycle
outputs are deterministic synthetic evidence. No real funds move; no bank or
routing data is used; no ACH/network transmission, external processor call,
merchant contact, write-off/collection/legal execution, external notice, or
production adverse action occurs.

Required result
---------------
recovery_status = PASS.
============================================================================ */

WITH r AS(SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
s AS(SELECT count(*) registry_rows,max(contract_status) contract_status,max(contract_code) contract_code,max(contract_version) contract_version,max(schema_version) schema_version,max(combined_set_hash) combined_set_hash FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)),
g AS(SELECT count(*) gate_rows,max(result_status) gate_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND review_version=1),
o AS(SELECT count(*) FILTER(WHERE table_schema='msbf_ctl' AND table_name IN ('m2_8_policy_profile','m2_8_servicing_execution_contract_registry')) control_tables,
 count(*) FILTER(WHERE table_schema='msbf_m2' AND table_name IN ('servicing_execution_outcome_definition','servicing_execution_action_definition','account_lifecycle_state_definition','servicing_execution_reason_definition','servicing_execution_source_snapshot','application_servicing_execution_snapshot','synthetic_payment_processing_event','account_lifecycle_transition_snapshot','servicing_execution_portfolio_summary','application_servicing_execution_latest','application_servicing_execution_archive')) business_tables FROM information_schema.tables),
x AS(SELECT
 (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M2_8_%') evidence_rows,
 (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL') acceptance_rows,
 (SELECT count(*) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL') gate_catalog_rows)
SELECT r.run_status,s.registry_rows source_registry_rows,s.contract_status source_contract_status,s.contract_code source_contract_code,
 s.contract_version source_contract_version,s.schema_version source_schema_version,s.combined_set_hash source_combined_set_hash,
 g.gate_rows source_gate_rows,g.gate_status source_gate_status,o.control_tables,o.business_tables,x.evidence_rows,x.acceptance_rows,x.gate_catalog_rows,
 CASE WHEN r.run_status='M2_7_ACCEPTED' AND s.registry_rows=1 AND s.contract_status='ACCEPTED'
 AND s.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND s.contract_version=1 AND s.schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
 AND s.combined_set_hash='c8e3a472afd2a16b1183677324e9db98' AND g.gate_rows=1 AND g.gate_status='PASS'
 AND o.control_tables=0 AND o.business_tables=0 AND x.evidence_rows=0 AND x.acceptance_rows=0 AND x.gate_catalog_rows=0
 THEN 'PASS' ELSE 'FAIL' END recovery_status
FROM r CROSS JOIN s CROSS JOIN g CROSS JOIN o CROSS JOIN x;
