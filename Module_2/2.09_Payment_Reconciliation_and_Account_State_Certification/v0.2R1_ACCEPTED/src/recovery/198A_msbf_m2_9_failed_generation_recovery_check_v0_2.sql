/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.9 — Payment Reconciliation, Exception Resolution
             & Account State Certification

Program     : 198A_msbf_m2_9_failed_generation_recovery_check_v0_2.sql
Version     : v0.2

Purpose
-------
Read-only proof after failed or cancelled Program 198. Execute ROLLBACK first.
Programs 196 and 197 remain authoritative and all generated M2.9 targets must
remain empty.

Required result
---------------
recovery_status = PASS.
============================================================================ */
WITH run_context AS(SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
state AS(SELECT
(SELECT count(*) FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS account_source_rows,
(SELECT count(*) FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM run_context)) AS payment_source_rows,
(SELECT count(*) FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=(SELECT run_id FROM run_context)) AS transition_source_rows,
(SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS payment_reconciliation_rows,
(SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS exception_case_rows,
(SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS account_reconciliation_rows,
(SELECT count(*) FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS certification_rows,
(SELECT count(*) FROM msbf_m2.payment_reconciliation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM run_context)) AS portfolio_rows,
(SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=(SELECT run_id FROM run_context)) AS latest_rows,
(SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_archive WHERE module1_run_id=(SELECT run_id FROM run_context)) AS archive_rows,
(SELECT count(*) FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)) AS registry_rows,
(SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context) AND evidence_code LIKE 'M2_9_%') AS evidence_rows,
(SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION') AS acceptance_rows)
SELECT run_context.run_status,state.*,
CASE WHEN run_context.run_status='M2_8_ACCEPTED' AND state.account_source_rows=0 AND state.payment_source_rows=0
AND state.transition_source_rows=0 AND state.payment_reconciliation_rows=0 AND state.exception_case_rows=0
AND state.account_reconciliation_rows=0 AND state.certification_rows=0 AND state.portfolio_rows=0
AND state.latest_rows=0 AND state.archive_rows=0 AND state.registry_rows=0 AND state.evidence_rows=0 AND state.acceptance_rows=0
THEN 'PASS' ELSE 'FAIL' END AS recovery_status FROM run_context CROSS JOIN state;
