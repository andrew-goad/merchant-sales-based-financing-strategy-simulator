/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.9 — Payment Reconciliation, Exception Resolution
             & Account State Certification

Program     : 201_msbf_m2_9_acceptance_finalize_v0_2.sql
Version     : v0.2

Purpose
-------
Independently verify accepted M2.8 lineage, all control evidence, physical
cardinalities, event and account reconciliation, exception resolution,
account-state certification, non-production boundaries, latest/archive
reproduction, stress non-improvement, canonical identity, and absence of
premature downstream objects before issuing formal M2.9 acceptance.

Required result
---------------
acceptance_status=PASS, final_run_status=M2_9_ACCEPTED,
final_contract_status=ACCEPTED, gate_status=PASS.
============================================================================ */
BEGIN; SET LOCAL work_mem='160MB'; SET LOCAL statement_timeout='55min'; SET LOCAL jit=off;
/* ============================================================================
Section 1 — Independently reconstruct all acceptance preconditions
============================================================================ */
DROP TABLE IF EXISTS _m2_9_acceptance;
CREATE TEMP TABLE _m2_9_acceptance ON COMMIT PRESERVE ROWS AS
WITH run_context AS(SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
registry AS(SELECT * FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)),
source_registry AS(SELECT contract_status,contract_code,contract_version,schema_version,methodology_version,combined_set_hash
FROM msbf_ctl.m2_8_servicing_execution_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)),
source_gate AS(SELECT result_status AS gate_status FROM msbf_ctl.acceptance_gate_result
WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND review_version=1),
controls AS(SELECT
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_POS_%')::bigint AS positive_checks,
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_POS_%' AND status='PASS')::bigint AS positive_passes,
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_POS_%' AND status<>'PASS')::bigint AS positive_failures,
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_NEG_%')::bigint AS negative_checks,
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_NEG_%' AND status='PASS')::bigint AS negative_passes,
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_NEG_%' AND status<>'PASS')::bigint AS negative_failures,
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_%' AND evidence_code NOT LIKE 'M2_9_POS_%'
 AND evidence_code NOT LIKE 'M2_9_NEG_%' AND evidence_code<>'M2_9_ACCEPTANCE_SUMMARY')::bigint AS generation_evidence_rows,
count(*) FILTER(WHERE evidence_code LIKE 'M2_9_%' AND status='FAIL')::bigint AS failed_evidence_rows
FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context)),
physical AS(SELECT
(SELECT count(*) FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS policy_rows,
(SELECT count(*) FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS outcome_rows,
(SELECT count(*) FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS action_rows,
(SELECT count(*) FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS certification_definition_rows,
(SELECT count(*) FROM msbf_m2.payment_reconciliation_reason_definition WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS reason_rows,
(SELECT count(*) FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS account_source_rows,
(SELECT count(*) FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS payment_source_rows,
(SELECT count(*) FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS transition_source_rows,
(SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS payment_reconciliation_rows,
(SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS exception_case_rows,
(SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS account_reconciliation_rows,
(SELECT count(*) FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS certification_rows,
(SELECT count(*) FROM msbf_m2.payment_reconciliation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS portfolio_rows,
(SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS latest_rows,
(SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_archive WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS archive_rows,
(SELECT count(*) FROM msbf_m2.v_m2_9_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS comparison_rows,
(SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context) AND (real_funds_moved_flag OR external_system_called_flag))
 +(SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context) AND (real_funds_moved_flag OR external_system_called_flag))
 +(SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context) AND
 (real_funds_moved_flag OR bank_account_data_present_flag OR ach_or_network_transmitted_flag OR external_processor_called_flag
 OR merchant_contact_executed_flag OR write_off_or_collection_flag OR external_notice_generated_flag OR production_adverse_action_flag))
 +(SELECT count(*) FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context) AND
 (real_funds_moved_flag OR production_account_state_flag OR external_system_update_flag)) AS boundary_rows,
(SELECT count(*) FROM msbf_m2.v_m2_9_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context)
 AND (stress_certification_permission_improvement_flag OR stress_certification_rank_improvement_flag OR stress_exposure_improvement_flag))::bigint AS stress_improvement_rows,
(SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest AS latest FULL OUTER JOIN
 msbf_m2.application_payment_reconciliation_certification_archive AS archive
 ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version
 AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id
 WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=(SELECT run_id FROM run_context)
 AND (latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash
 OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at')))::bigint AS archive_mismatches,
(SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN
 ('payment_event_reconciliation_snapshot','payment_exception_case_snapshot','account_payment_reconciliation_snapshot',
 'account_state_certification_snapshot','application_payment_reconciliation_certification_latest',
 'application_payment_reconciliation_certification_archive') AND lower(column_name) IN
 ('real_bank_account_number','bank_account_number','routing_number','ach_trace_number','payment_network_confirmation',
 'processor_authorization_code','external_notice_payload','production_adverse_action_notice'))::bigint AS prohibited_columns,
(SELECT count(*) FROM information_schema.tables WHERE table_schema IN('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_10%')::bigint AS premature_m2_10_tables,
(SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION')::bigint AS existing_gate_rows,
(SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM run_context) AND severity='BLOCKING')::bigint AS blocking_errors,
(SELECT canonical_entities FROM msbf_m2.v_m2_9_canonical_hash WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS physical_canonical_entities,
(SELECT combined_set_hash FROM msbf_m2.v_m2_9_canonical_hash WHERE module1_run_id=(SELECT run_id FROM run_context)) AS physical_combined_set_hash),
business AS(SELECT
count(*) FILTER(WHERE reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED')::bigint AS no_payment_activity_rows,
count(*) FILTER(WHERE reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY')::bigint AS reconciled_after_retry_rows,
count(*) FILTER(WHERE reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD')::bigint AS review_hold_rows,
count(*) FILTER(WHERE reconciliation_certified_flag)::bigint AS reconciliation_certified_rows,
sum(payment_event_count)::bigint AS payment_event_rows,sum(settled_event_count)::bigint AS settled_event_rows,
sum(returned_event_count)::bigint AS returned_event_rows,sum(retry_event_count)::bigint AS retry_event_rows,
sum(exception_case_count)::bigint AS exception_opened_rows,sum(resolved_exception_count)::bigint AS exception_resolved_rows,
sum(unresolved_exception_count)::bigint AS unresolved_exception_rows,
round(sum(scheduled_payment_amount),2) AS scheduled_payment_amount,round(sum(processed_payment_amount),2) AS processed_payment_amount,
round(sum(returned_payment_amount),2) AS returned_payment_amount,round(sum(retry_payment_amount),2) AS retry_payment_amount,
round(sum(reconciliation_variance_amount),2) AS reconciliation_variance_amount,round(sum(exposure_variance_amount),2) AS exposure_variance_amount
FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)),
certification AS(SELECT count(*) FILTER(WHERE state_certified_flag)::bigint AS state_certified_rows,
count(*) FILTER(WHERE certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING')::bigint AS certified_closed_rows,
count(*) FILTER(WHERE certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY')::bigint AS certified_reassessment_rows,
count(*) FILTER(WHERE certified_state_code='CERTIFIED_REVIEW_HOLD')::bigint AS certified_review_hold_rows,
round(sum(certified_exposure_amount) FILTER(WHERE active_state_flag),2) AS active_certified_exposure_amount,
round(sum(certified_exposure_amount) FILTER(WHERE review_hold_state_flag),2) AS review_hold_exposure_amount,
round(sum(certified_exposure_amount),2) AS portfolio_certified_exposure_amount
FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)),
exception_summary AS(SELECT count(*)::bigint AS exception_rows,
count(*) FILTER(WHERE exception_status_code='RESOLVED_BY_RETRY' AND NOT unresolved_exception_flag)::bigint AS resolved_rows,
count(*) FILTER(WHERE unresolved_exception_flag)::bigint AS unresolved_rows,round(sum(exception_amount),2) AS exception_amount
FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))
SELECT run_context.run_id,run_context.run_status AS prior_run_status,registry.contract_status AS prior_contract_status,
source_registry.contract_status AS source_contract_status,source_registry.contract_code AS source_contract_code,
source_registry.contract_version AS source_contract_version,source_registry.schema_version AS source_schema_version,
source_registry.methodology_version AS source_methodology_version,source_registry.combined_set_hash AS source_combined_set_hash,
source_gate.gate_status AS source_gate_status,controls.*,physical.*,business.*,certification.*,exception_summary.*,
registry.canonical_entities,registry.contract_set_hash,registry.combined_set_hash,
CASE WHEN run_context.run_status='M2_9_VALIDATED' AND registry.contract_status='VALIDATED'
AND source_registry.contract_status='ACCEPTED' AND source_registry.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION'
AND source_registry.contract_version=1 AND source_registry.schema_version='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1'
AND source_registry.methodology_version='M2_8_METHOD_V1' AND source_registry.combined_set_hash='ab32d80ba20c2c8f0a6ec9ec97c2ed26'
AND source_gate.gate_status='PASS' AND controls.positive_checks=120 AND controls.positive_passes=120
AND controls.positive_failures=0 AND controls.negative_checks=20 AND controls.negative_passes=20
AND controls.negative_failures=0 AND controls.generation_evidence_rows=24 AND controls.failed_evidence_rows=0
AND physical.policy_rows=1 AND physical.outcome_rows=7 AND physical.action_rows=7
AND physical.certification_definition_rows=7 AND physical.reason_rows=36 AND physical.account_source_rows=59
AND physical.payment_source_rows=7 AND physical.transition_source_rows=67 AND physical.payment_reconciliation_rows=7
AND physical.exception_case_rows=1 AND physical.account_reconciliation_rows=59 AND physical.certification_rows=59
AND physical.portfolio_rows=2 AND physical.latest_rows=59 AND physical.archive_rows=59 AND physical.comparison_rows=15
AND business.no_payment_activity_rows=57 AND business.reconciled_after_retry_rows=1 AND business.review_hold_rows=1
AND business.reconciliation_certified_rows=59 AND business.payment_event_rows=7 AND business.settled_event_rows=5
AND business.returned_event_rows=1 AND business.retry_event_rows=1 AND business.exception_opened_rows=1
AND business.exception_resolved_rows=1 AND business.unresolved_exception_rows=0
AND business.scheduled_payment_amount=194.25 AND business.processed_payment_amount=194.25
AND business.returned_payment_amount=27.75 AND business.retry_payment_amount=27.75
AND business.reconciliation_variance_amount=0 AND business.exposure_variance_amount=0
AND certification.state_certified_rows=59 AND certification.certified_closed_rows=57
AND certification.certified_reassessment_rows=1 AND certification.certified_review_hold_rows=1
AND certification.active_certified_exposure_amount=323.79 AND certification.review_hold_exposure_amount=461.69
AND certification.portfolio_certified_exposure_amount=785.48
AND exception_summary.exception_rows=1 AND exception_summary.resolved_rows=1 AND exception_summary.unresolved_rows=0
AND exception_summary.exception_amount=27.75 AND physical.boundary_rows=0 AND physical.stress_improvement_rows=0
AND physical.archive_mismatches=0 AND physical.prohibited_columns=0 AND physical.premature_m2_10_tables=0
AND physical.existing_gate_rows=0 AND physical.blocking_errors=0 AND registry.canonical_entities=438
AND physical.physical_canonical_entities=438 AND registry.combined_set_hash IS NOT DISTINCT FROM physical.physical_combined_set_hash
AND registry.contract_set_hash IS NOT NULL AND registry.combined_set_hash IS NOT NULL
THEN 'PASS' ELSE 'FAIL' END AS acceptance_status
FROM run_context CROSS JOIN registry CROSS JOIN source_registry CROSS JOIN source_gate CROSS JOIN controls
CROSS JOIN physical CROSS JOIN business CROSS JOIN certification CROSS JOIN exception_summary;
/* ============================================================================
Section 2 — Fail-closed acceptance guard
============================================================================ */
DO $guard$ DECLARE v record; BEGIN SELECT * INTO v FROM _m2_9_acceptance;
IF v.acceptance_status<>'PASS' THEN RAISE EXCEPTION 'M2.9 acceptance preconditions failed: %.',row_to_json(v); END IF;
PERFORM msbf_ctl.m2_9_assert_acceptance_ready(v.run_id); END;$guard$;
/* ============================================================================
Section 3 — Persist accepted lifecycle, gate, and evidence
============================================================================ */
UPDATE msbf_ctl.m2_9_reconciliation_certification_contract_registry SET contract_status='ACCEPTED',accepted_at=clock_timestamp()
WHERE module1_run_id=(SELECT run_id FROM _m2_9_acceptance);
UPDATE msbf_ctl.run_registry SET run_status='M2_9_ACCEPTED',notes=coalesce(notes,'')||' | M2.9 payment reconciliation, exception resolution, and account state certification accepted.'
WHERE run_id=(SELECT run_id FROM _m2_9_acceptance);
INSERT INTO msbf_ctl.acceptance_gate_result
(run_id,gate_id,review_version,result_status,observed_value,threshold_value,finding,residual_limitation,reviewer_role)
SELECT run_id,'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION',1,'PASS',combined_set_hash,
'120/120 positive; 20/20 negative; exact M2.8 lineage; 7 reconciled payment events; 1 exception resolved; 59 certified states; zero variance, unresolved exception, real-execution, stress, archive, or stage-boundary violations',
'M2.9 payment reconciliation, exception resolution, and account state certification accepted.',
'Synthetic certification only; no real funds movement, bank data, network transmission, processor call, merchant contact, write-off or collection execution, external notice, or production adverse action.',
'Independent Validation / Project Owner' FROM _m2_9_acceptance;
INSERT INTO msbf_ctl.run_evidence
(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,interpretation)
SELECT run_id,'M2_9_ACCEPTANCE_SUMMARY','PORTFOLIO','M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_ACCEPTANCE',
NULL::numeric(28,10),combined_set_hash,'ACCEPTANCE','PASS',
'Formal M2.9 acceptance with exact M2.8 lineage, 120 positive controls, 20 negative controls, 438 canonical entities, zero payment and exposure variance, one resolved exception, 59 certified account states, and zero blocking exceptions.'
FROM _m2_9_acceptance;
/* ============================================================================
Section 4 — Reconstruct and verify final accepted state
============================================================================ */
ALTER TABLE _m2_9_acceptance ADD COLUMN final_run_status text,ADD COLUMN final_contract_status text,ADD COLUMN gate_status text;
UPDATE _m2_9_acceptance AS a SET
final_run_status=(SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=a.run_id),
final_contract_status=(SELECT contract_status FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=a.run_id),
gate_status=(SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=a.run_id AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND review_version=1)
WHERE a.run_id IS NOT NULL;
DO $final$ DECLARE v record; BEGIN SELECT final_run_status,final_contract_status,gate_status INTO v FROM _m2_9_acceptance;
IF v.final_run_status<>'M2_9_ACCEPTED' OR v.final_contract_status<>'ACCEPTED' OR v.gate_status<>'PASS'
THEN RAISE EXCEPTION 'M2.9 final acceptance state failed: %.',row_to_json(v); END IF; END;$final$;
COMMIT;
/* ============================================================================
Section 5 — Session-preserved acceptance checkpoint
============================================================================ */
SELECT * FROM _m2_9_acceptance;
