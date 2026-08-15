/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.8 — Servicing Execution Simulation, Payment Processing
             & Account Lifecycle Control

Program     : 190A_msbf_m2_8_failed_generation_recovery_check_v0_2.sql
Version     : v0.2

Purpose
-------
Verify clean rollback after failed or cancelled Program 190. Execute
ROLLBACK first. Programs 188 and 189 remain authoritative.

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

WITH r AS(SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),s AS(SELECT
 (SELECT count(*) FROM msbf_m2.servicing_execution_source_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) source_rows,
 (SELECT count(*) FROM msbf_m2.application_servicing_execution_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) execution_rows,
 (SELECT count(*) FROM msbf_m2.synthetic_payment_processing_event WHERE module1_run_id=(SELECT run_id FROM r)) payment_event_rows,
 (SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) lifecycle_transition_rows,
 (SELECT count(*) FROM msbf_m2.servicing_execution_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM r)) portfolio_rows,
 (SELECT count(*) FROM msbf_m2.application_servicing_execution_latest WHERE module1_run_id=(SELECT run_id FROM r)) latest_rows,
 (SELECT count(*) FROM msbf_m2.application_servicing_execution_archive WHERE module1_run_id=(SELECT run_id FROM r)) archive_rows,
 (SELECT count(*) FROM msbf_ctl.m2_8_servicing_execution_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)) registry_rows,
 (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M2_8_%') evidence_rows,
 (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL') acceptance_rows)
SELECT r.run_status,s.*,CASE WHEN r.run_status='M2_7_ACCEPTED' AND s.source_rows=0 AND s.execution_rows=0 AND s.payment_event_rows=0 AND s.lifecycle_transition_rows=0 AND s.portfolio_rows=0 AND s.latest_rows=0 AND s.archive_rows=0 AND s.registry_rows=0 AND s.evidence_rows=0 AND s.acceptance_rows=0 THEN 'PASS' ELSE 'FAIL' END recovery_status FROM r CROSS JOIN s;
