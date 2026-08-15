/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.9 — Payment Reconciliation, Exception Resolution
             & Account State Certification

Program     : 198B_msbf_m2_9_generation_reconciliation_reconstructed_v0_2.sql
Version     : v0.2

Purpose
-------
Read-only reconstruction of Program 198's committed generation checkpoint if
DBeaver loses or suppresses the successful result tab.

Required result
---------------
generation_reconstruction_status = PASS.
============================================================================ */
WITH run_context AS(SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
registry AS(SELECT * FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)),
physical AS(SELECT
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
(SELECT count(*) FROM msbf_m2.v_m2_9_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context)) AS comparison_rows,
(SELECT canonical_entities FROM msbf_m2.v_m2_9_canonical_hash WHERE module1_run_id=(SELECT run_id FROM run_context)) AS canonical_entities,
(SELECT combined_set_hash FROM msbf_m2.v_m2_9_canonical_hash WHERE module1_run_id=(SELECT run_id FROM run_context)) AS physical_combined_set_hash,
(SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context) AND evidence_code LIKE 'M2_9_%'
 AND evidence_code NOT LIKE 'M2_9_POS_%' AND evidence_code NOT LIKE 'M2_9_NEG_%' AND evidence_code<>'M2_9_ACCEPTANCE_SUMMARY') AS generation_evidence_rows,
(SELECT count(*) FROM msbf_m2.v_m2_9_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context)
 AND (stress_certification_permission_improvement_flag OR stress_certification_rank_improvement_flag OR stress_exposure_improvement_flag)) AS stress_improvement_rows)
SELECT run_context.run_status,registry.contract_status,physical.*,registry.no_payment_activity_rows,
registry.reconciled_after_retry_rows,registry.review_hold_rows,registry.certified_closed_rows,
registry.certified_reassessment_rows,registry.certified_review_hold_rows,registry.settled_event_rows,
registry.returned_event_rows,registry.retry_event_rows,registry.exception_opened_rows,
registry.exception_resolved_rows,registry.unresolved_exception_rows,registry.scheduled_payment_amount,
registry.processed_payment_amount,registry.returned_payment_amount,registry.retry_payment_amount,
registry.exception_amount,registry.reconciliation_variance_amount,registry.exposure_variance_amount,
registry.active_certified_exposure_amount,registry.review_hold_exposure_amount,
registry.portfolio_certified_exposure_amount,registry.contract_set_hash,registry.combined_set_hash,
CASE WHEN run_context.run_status IN('M2_9_GENERATED','M2_9_VALIDATED','M2_9_ACCEPTED')
AND registry.contract_status IN('GENERATED','VALIDATED','ACCEPTED')
AND physical.account_source_rows=59 AND physical.payment_source_rows=7 AND physical.transition_source_rows=67
AND physical.payment_reconciliation_rows=7 AND physical.exception_case_rows=1
AND physical.account_reconciliation_rows=59 AND physical.certification_rows=59 AND physical.portfolio_rows=2
AND physical.latest_rows=59 AND physical.archive_rows=59 AND physical.comparison_rows=15
AND physical.canonical_entities=438 AND physical.generation_evidence_rows=24 AND physical.stress_improvement_rows=0
AND registry.no_payment_activity_rows=57 AND registry.reconciled_after_retry_rows=1 AND registry.review_hold_rows=1
AND registry.certified_closed_rows=57 AND registry.certified_reassessment_rows=1 AND registry.certified_review_hold_rows=1
AND registry.settled_event_rows=5 AND registry.returned_event_rows=1 AND registry.retry_event_rows=1
AND registry.exception_opened_rows=1 AND registry.exception_resolved_rows=1 AND registry.unresolved_exception_rows=0
AND registry.scheduled_payment_amount=194.25 AND registry.processed_payment_amount=194.25
AND registry.returned_payment_amount=27.75 AND registry.retry_payment_amount=27.75 AND registry.exception_amount=27.75
AND registry.reconciliation_variance_amount=0 AND registry.exposure_variance_amount=0
AND registry.active_certified_exposure_amount=323.79 AND registry.review_hold_exposure_amount=461.69
AND registry.portfolio_certified_exposure_amount=785.48
AND registry.combined_set_hash IS NOT DISTINCT FROM physical.physical_combined_set_hash
THEN 'PASS' ELSE 'FAIL' END AS generation_reconstruction_status
FROM run_context CROSS JOIN registry CROSS JOIN physical;
