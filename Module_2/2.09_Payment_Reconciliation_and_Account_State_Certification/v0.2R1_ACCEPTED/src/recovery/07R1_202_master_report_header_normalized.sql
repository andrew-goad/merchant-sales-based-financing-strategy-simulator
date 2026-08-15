/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.9 — Payment Reconciliation, Exception Resolution
             & Account State Certification

Program     : 202_MSBF_M2_9_Master_Report_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Produce one executive/governance summary row after formal M2.9 acceptance,
reconciling lifecycle, accepted M2.8 identity, physical cardinalities, payment
and exposure variance, exception resolution, account-state certification,
evidence, non-production boundaries, latest/archive reproduction, stress
non-improvement, and canonical identity.

Writes
------
None.

Required result
---------------
overall_m2_9_status = PASS.
============================================================================ */
SET statement_timeout='40min'; SET jit=off;
/* ============================================================================
Section 1 — Reconstruct accepted lifecycle, business, and boundary state
============================================================================ */
WITH run_context AS(SELECT run_id,run_code,run_version,run_status FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
policy AS(SELECT * FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM run_context)),
registry AS(SELECT * FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)),
gate AS(SELECT result_status AS gate_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context)
AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND review_version=1),
evidence AS(SELECT
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_POS_%' AND status='PASS')::bigint AS positive_passes,
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_POS_%')::bigint AS positive_checks,
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_NEG_%' AND status='PASS')::bigint AS negative_passes,
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_NEG_%')::bigint AS negative_checks,
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_%' AND evidence_code NOT LIKE 'M2_9_POS_%'
 AND evidence_code NOT LIKE 'M2_9_NEG_%' AND evidence_code<>'M2_9_ACCEPTANCE_SUMMARY')::bigint AS generation_evidence_rows,
count(*) FILTER(WHERE evidence_code='M2_9_ACCEPTANCE_SUMMARY' AND status='PASS')::bigint AS acceptance_evidence_rows,
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_%' AND status='FAIL')::bigint AS failed_evidence_rows
FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context)),
business AS(SELECT count(*)::bigint AS latest_rows,
count(*) FILTER(WHERE reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED')::bigint AS no_payment_activity_rows,
count(*) FILTER(WHERE reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY')::bigint AS reconciled_after_retry_rows,
count(*) FILTER(WHERE reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD')::bigint AS review_hold_rows,
count(*) FILTER(WHERE state_certified_flag)::bigint AS state_certified_rows,
sum(payment_event_count)::bigint AS payment_event_rows,sum(settled_event_count)::bigint AS settled_event_rows,
sum(returned_event_count)::bigint AS returned_event_rows,sum(retry_event_count)::bigint AS retry_event_rows,
sum(exception_case_count)::bigint AS exception_opened_rows,sum(resolved_exception_count)::bigint AS exception_resolved_rows,
sum(unresolved_exception_count)::bigint AS unresolved_exception_rows,
round(sum(scheduled_payment_amount),2) AS scheduled_payment_amount,round(sum(processed_payment_amount),2) AS processed_payment_amount,
round(sum(returned_payment_amount),2) AS returned_payment_amount,round(sum(retry_payment_amount),2) AS retry_payment_amount,
round(sum(reconciliation_variance_amount),2) AS reconciliation_variance_amount,
round(sum(exposure_variance_amount),2) AS exposure_variance_amount,
round(sum(certified_exposure_amount),2) AS portfolio_certified_exposure_amount,
round(sum(certified_exposure_amount) FILTER(WHERE active_state_flag),2) AS active_certified_exposure_amount,
round(sum(certified_exposure_amount) FILTER(WHERE review_hold_state_flag),2) AS review_hold_exposure_amount
FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=(SELECT run_id FROM run_context)),
exception_summary AS(SELECT count(*)::bigint AS exception_case_rows,
count(*) FILTER(WHERE exception_status_code='RESOLVED_BY_RETRY')::bigint AS resolved_exception_rows,
count(*) FILTER(WHERE unresolved_exception_flag)::bigint AS unresolved_exception_rows,
round(sum(exception_amount),2) AS exception_amount,min(originating_event_date) AS exception_open_date,
max(resolving_event_date) AS exception_resolution_date,max(exception_open_days) AS maximum_exception_open_days
FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)),
cert_summary AS(SELECT count(*) FILTER(WHERE certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING')::bigint AS certified_closed_rows,
count(*) FILTER(WHERE certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY')::bigint AS certified_reassessment_rows,
count(*) FILTER(WHERE certified_state_code='CERTIFIED_REVIEW_HOLD')::bigint AS certified_review_hold_rows,
min(certification_date) AS first_certification_date,max(certification_date) AS last_certification_date
FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)),
boundary AS(SELECT
(SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context) AND (real_funds_moved_flag OR external_system_called_flag))
+(SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context) AND (real_funds_moved_flag OR external_system_called_flag))
+(SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context) AND
(real_funds_moved_flag OR bank_account_data_present_flag OR ach_or_network_transmitted_flag OR external_processor_called_flag OR merchant_contact_executed_flag OR write_off_or_collection_flag OR external_notice_generated_flag OR production_adverse_action_flag))
+(SELECT count(*) FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context) AND
(real_funds_moved_flag OR production_account_state_flag OR external_system_update_flag))::bigint AS boundary_rows),
diagnostics AS(SELECT
(SELECT canonical_entities FROM msbf_m2.v_m2_9_canonical_hash WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS physical_canonical_entities,
(SELECT combined_set_hash FROM msbf_m2.v_m2_9_canonical_hash WHERE module1_run_id=(SELECT run_id FROM run_context)) AS physical_combined_set_hash,
(SELECT count(*) FROM msbf_m2.v_m2_9_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context) AND
(stress_certification_permission_improvement_flag OR stress_certification_rank_improvement_flag OR stress_exposure_improvement_flag))::bigint AS stress_improvement_rows,
(SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest AS latest FULL OUTER JOIN
msbf_m2.application_payment_reconciliation_certification_archive AS archive
ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version
AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id
WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=(SELECT run_id FROM run_context)
AND (latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at')))::bigint AS archive_mismatches,
(SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN
('payment_event_reconciliation_snapshot','payment_exception_case_snapshot','account_payment_reconciliation_snapshot',
'account_state_certification_snapshot','application_payment_reconciliation_certification_latest',
'application_payment_reconciliation_certification_archive') AND lower(column_name) IN
('real_bank_account_number','bank_account_number','routing_number','ach_trace_number','payment_network_confirmation',
'processor_authorization_code','external_notice_payload','production_adverse_action_notice'))::bigint AS prohibited_columns,
(SELECT count(*) FROM information_schema.tables WHERE table_schema IN('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_10%')::bigint AS premature_m2_10_tables)
/* ============================================================================
Section 2 — Executive governed checkpoint and overall status
============================================================================ */
SELECT run_context.run_code,run_context.run_version,run_context.run_status,
policy.policy_code,policy.policy_version,policy.policy_status,policy.methodology_version,
policy.contract_code,policy.contract_version,policy.schema_version,policy.source_contract_code,
policy.source_contract_version,policy.source_schema_version,policy.source_acceptance_gate_id,
policy.source_combined_set_hash,policy.configuration_hash,registry.contract_status,gate.gate_status,
registry.policy_rows,registry.reconciliation_outcome_rows,registry.resolution_action_rows,
registry.certification_state_rows,registry.reason_rows,registry.account_source_rows,registry.payment_source_rows,
registry.transition_source_rows,registry.payment_reconciliation_rows,registry.exception_case_rows,
registry.account_reconciliation_rows,registry.state_certification_rows,registry.portfolio_summary_rows,
registry.latest_rows,registry.archive_rows,registry.comparison_rows,registry.registry_rows,registry.canonical_entities,
business.no_payment_activity_rows,business.reconciled_after_retry_rows,business.review_hold_rows,
business.state_certified_rows,business.payment_event_rows,business.settled_event_rows,business.returned_event_rows,
business.retry_event_rows,business.exception_opened_rows,business.exception_resolved_rows,business.unresolved_exception_rows,
business.scheduled_payment_amount,business.processed_payment_amount,business.returned_payment_amount,
business.retry_payment_amount,business.reconciliation_variance_amount,business.exposure_variance_amount,
business.active_certified_exposure_amount,business.review_hold_exposure_amount,business.portfolio_certified_exposure_amount,
exception_summary.exception_case_rows AS physical_exception_case_rows,exception_summary.resolved_exception_rows AS physical_resolved_exception_rows,
exception_summary.unresolved_exception_rows AS physical_unresolved_exception_rows,exception_summary.exception_amount,
exception_summary.exception_open_date,exception_summary.exception_resolution_date,exception_summary.maximum_exception_open_days,
cert_summary.certified_closed_rows,cert_summary.certified_reassessment_rows,cert_summary.certified_review_hold_rows,
cert_summary.first_certification_date,cert_summary.last_certification_date,
evidence.positive_passes,evidence.positive_checks,evidence.negative_passes,evidence.negative_checks,
evidence.generation_evidence_rows,evidence.acceptance_evidence_rows,evidence.failed_evidence_rows,
boundary.boundary_rows,diagnostics.physical_canonical_entities,diagnostics.stress_improvement_rows,
diagnostics.archive_mismatches,diagnostics.prohibited_columns,diagnostics.premature_m2_10_tables,
registry.policy_set_hash,registry.reconciliation_outcome_set_hash,registry.resolution_action_set_hash,
registry.certification_state_set_hash,registry.reason_set_hash,registry.account_source_set_hash,
registry.payment_source_set_hash,registry.transition_source_set_hash,registry.payment_reconciliation_set_hash,
registry.exception_case_set_hash,registry.account_reconciliation_set_hash,registry.state_certification_set_hash,
registry.portfolio_summary_set_hash,registry.latest_set_hash,registry.archive_set_hash,registry.contract_set_hash,
registry.combined_set_hash,
CASE WHEN run_context.run_status='M2_9_ACCEPTED' AND policy.policy_status='APPROVED'
AND policy.synthetic_data_only_flag AND policy.reconciliation_certification_only_flag AND policy.preserve_m2_8_history_flag
AND policy.no_real_funds_movement_flag AND policy.no_bank_account_data_flag AND policy.no_ach_or_network_transmission_flag
AND policy.no_external_processor_call_flag AND policy.no_real_merchant_contact_flag
AND policy.no_write_off_or_collection_execution_flag AND policy.no_external_notice_generation_flag
AND policy.no_production_adverse_action_flag AND registry.contract_status='ACCEPTED' AND gate.gate_status='PASS'
AND registry.policy_rows=1 AND registry.reconciliation_outcome_rows=7 AND registry.resolution_action_rows=7
AND registry.certification_state_rows=7 AND registry.reason_rows=36 AND registry.account_source_rows=59
AND registry.payment_source_rows=7 AND registry.transition_source_rows=67 AND registry.payment_reconciliation_rows=7
AND registry.exception_case_rows=1 AND registry.account_reconciliation_rows=59 AND registry.state_certification_rows=59
AND registry.portfolio_summary_rows=2 AND registry.latest_rows=59 AND registry.archive_rows=59
AND registry.comparison_rows=15 AND registry.registry_rows=1 AND registry.canonical_entities=438
AND business.no_payment_activity_rows=57 AND business.reconciled_after_retry_rows=1 AND business.review_hold_rows=1
AND business.state_certified_rows=59 AND business.payment_event_rows=7 AND business.settled_event_rows=5
AND business.returned_event_rows=1 AND business.retry_event_rows=1 AND business.exception_opened_rows=1
AND business.exception_resolved_rows=1 AND business.unresolved_exception_rows=0
AND business.scheduled_payment_amount=194.25 AND business.processed_payment_amount=194.25
AND business.returned_payment_amount=27.75 AND business.retry_payment_amount=27.75
AND business.reconciliation_variance_amount=0 AND business.exposure_variance_amount=0
AND business.active_certified_exposure_amount=323.79 AND business.review_hold_exposure_amount=461.69
AND business.portfolio_certified_exposure_amount=785.48
AND exception_summary.exception_case_rows=1 AND exception_summary.resolved_exception_rows=1
AND exception_summary.unresolved_exception_rows=0 AND exception_summary.exception_amount=27.75
AND exception_summary.exception_open_date=DATE '2026-07-27' AND exception_summary.exception_resolution_date=DATE '2026-07-28'
AND exception_summary.maximum_exception_open_days=1
AND cert_summary.certified_closed_rows=57 AND cert_summary.certified_reassessment_rows=1
AND cert_summary.certified_review_hold_rows=1 AND evidence.positive_passes=120 AND evidence.positive_checks=120
AND evidence.negative_passes=20 AND evidence.negative_checks=20 AND evidence.generation_evidence_rows=24
AND evidence.acceptance_evidence_rows=1 AND evidence.failed_evidence_rows=0 AND boundary.boundary_rows=0
AND diagnostics.physical_canonical_entities=438 AND registry.combined_set_hash IS NOT DISTINCT FROM diagnostics.physical_combined_set_hash
AND diagnostics.stress_improvement_rows=0 AND diagnostics.archive_mismatches=0 AND diagnostics.prohibited_columns=0
AND diagnostics.premature_m2_10_tables=0 THEN 'PASS' ELSE 'FAIL' END AS overall_m2_9_status
FROM run_context CROSS JOIN policy CROSS JOIN registry CROSS JOIN gate CROSS JOIN evidence
CROSS JOIN business CROSS JOIN exception_summary CROSS JOIN cert_summary CROSS JOIN boundary CROSS JOIN diagnostics;
