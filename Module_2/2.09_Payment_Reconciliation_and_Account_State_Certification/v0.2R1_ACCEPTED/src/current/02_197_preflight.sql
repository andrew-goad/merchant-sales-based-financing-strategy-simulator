/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.9 — Payment Reconciliation, Exception Resolution
             & Account State Certification

Program     : 197_msbf_m2_9_preflight_validation_v0_2.sql
Version     : v0.2

Purpose
-------
Fail closed unless the accepted M2.8 lifecycle, registry, schema, gate,
combined hash, 59 account rows, 7 payment events, 67 lifecycle transitions,
exact 57/1/1 account posture, governed M2.9 policy and dictionaries, and empty
M2.9 generation targets are all exact.

Writes
------
None. The session-preserved result remains filterable.

Required result
---------------
preflight_status = PASS.
============================================================================ */
SET statement_timeout='35min'; SET jit=off;
/* ============================================================================
Section 1 — Reconstruct accepted source, dictionaries, and empty targets
============================================================================ */
DROP TABLE IF EXISTS _m2_9_preflight;
CREATE TEMP TABLE _m2_9_preflight ON COMMIT PRESERVE ROWS AS
WITH run_context AS(
 SELECT run_id,run_status,population_id,as_of_date FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
policy AS(SELECT * FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM run_context)),
source_registry AS(
 SELECT count(*) registry_rows,max(contract_status) contract_status,max(contract_code) contract_code,
 max(contract_version) contract_version,max(schema_version) schema_version,max(methodology_version) methodology_version,
 max(combined_set_hash) combined_set_hash,max(latest_rows) latest_rows,max(payment_event_rows) payment_event_rows,
 max(lifecycle_transition_rows) lifecycle_transition_rows,max(comparison_rows) comparison_rows,max(canonical_entities) canonical_entities
 FROM msbf_ctl.m2_8_servicing_execution_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)),
source_gate AS(
 SELECT count(*) gate_rows,max(result_status) gate_status FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND review_version=1),
account_source AS(
 SELECT count(*) account_rows,count(DISTINCT scenario_id::text||'|'||merchant_application_id) distinct_grain_rows,
 count(*) FILTER(WHERE no_processing_required_flag) no_activity_rows,
 count(*) FILTER(WHERE processing_authorized_flag) payment_activity_rows,
 count(*) FILTER(WHERE processing_review_required_flag) review_hold_rows,
 round(sum(processed_payment_amount),2) processed_amount,round(sum(returned_payment_amount),2) returned_amount,
 round(sum(retry_payment_amount),2) retry_amount,round(sum(ending_simulated_exposure_amount),2) ending_exposure,
 count(*) FILTER(WHERE scenario_id IS NULL OR scenario_code='' OR merchant_application_id='' OR synthetic_account_id='' OR synthetic_advance_id='' OR contract_row_hash IS NULL OR jsonb_typeof(execution_reason_codes)<>'array') invalid_rows
 FROM msbf_m2.application_servicing_execution_latest WHERE module1_run_id=(SELECT run_id FROM run_context)),
payment_source AS(
 SELECT count(*) payment_rows,count(DISTINCT scenario_id::text||'|'||merchant_application_id||'|'||event_sequence) distinct_payment_rows,
 count(*) FILTER(WHERE payment_status_code='SIMULATED_SETTLED') settled_rows,
 count(*) FILTER(WHERE payment_status_code='SIMULATED_RETURNED') returned_rows,
 count(*) FILTER(WHERE payment_status_code='SIMULATED_RETRY_SETTLED') retry_rows,
 round(sum(scheduled_payment_amount),2) scheduled_amount,round(sum(processed_payment_amount),2) processed_amount,
 round(sum(returned_payment_amount),2) returned_amount,round(sum(retry_payment_amount),2) retry_amount,
 count(*) FILTER(WHERE row_hash IS NULL OR source_execution_row_hash IS NULL) invalid_rows
 FROM msbf_m2.synthetic_payment_processing_event WHERE module1_run_id=(SELECT run_id FROM run_context)),
transition_source AS(
 SELECT count(*) transition_rows,count(DISTINCT scenario_id::text||'|'||merchant_application_id||'|'||transition_sequence) distinct_transition_rows,
 count(*) FILTER(WHERE transition_sequence=0) initial_rows,
 count(*) FILTER(WHERE transition_type_code IN('PAYMENT_PROCESSING_EVENT','PAYMENT_RETURN_EVENT','PAYMENT_RETRY_EVENT')) payment_transition_rows,
 count(*) FILTER(WHERE transition_type_code='REASSESSMENT_CHECKPOINT') checkpoint_rows,
 count(*) FILTER(WHERE row_hash IS NULL OR source_execution_row_hash IS NULL) invalid_rows
 FROM msbf_m2.account_lifecycle_transition_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)),
definitions AS(
 SELECT (SELECT count(*) FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND definition_status='APPROVED') outcome_rows,
 (SELECT count(*) FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND definition_status='APPROVED') action_rows,
 (SELECT count(*) FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND definition_status='APPROVED') certification_rows,
 (SELECT count(*) FROM msbf_m2.payment_reconciliation_reason_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND definition_status='APPROVED') reason_rows,
 (SELECT count(*) FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND (real_funds_moved_flag OR production_state_updated_flag))+
 (SELECT count(*) FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND (real_funds_moved_flag OR external_system_called_flag))+
 (SELECT count(*) FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND production_account_state_flag)+
 (SELECT count(*) FROM msbf_m2.payment_reconciliation_reason_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND (real_execution_reason_flag OR production_adverse_action_flag)) prohibited_definition_flags),
targets AS(
 SELECT (SELECT count(*) FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) target_account_source_rows,
 (SELECT count(*) FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM run_context)) target_payment_source_rows,
 (SELECT count(*) FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=(SELECT run_id FROM run_context)) target_transition_source_rows,
 (SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) target_payment_reconciliation_rows,
 (SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) target_exception_rows,
 (SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) target_account_reconciliation_rows,
 (SELECT count(*) FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) target_certification_rows,
 (SELECT count(*) FROM msbf_m2.payment_reconciliation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM run_context)) target_portfolio_rows,
 (SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=(SELECT run_id FROM run_context)) target_latest_rows,
 (SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_archive WHERE module1_run_id=(SELECT run_id FROM run_context)) target_archive_rows,
 (SELECT count(*) FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)) target_registry_rows,
 (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context) AND evidence_code LIKE 'M2_9_%') target_evidence_rows,
 (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION') target_acceptance_rows,
 (SELECT count(*) FROM information_schema.tables WHERE table_schema IN('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_10%') premature_m2_10_tables,
 (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN('payment_event_reconciliation_snapshot','payment_exception_case_snapshot','account_payment_reconciliation_snapshot','account_state_certification_snapshot','application_payment_reconciliation_certification_latest','application_payment_reconciliation_certification_archive') AND lower(column_name) IN('bank_account_number','routing_number','ach_trace_number','real_funds_moved_amount','external_notice_payload','production_adverse_action_notice')) prohibited_columns)
SELECT run_context.run_id,run_context.run_status,run_context.population_id,run_context.as_of_date,
policy.policy_status,policy.methodology_version,policy.contract_code,policy.contract_version,policy.schema_version,
policy.source_contract_code policy_source_contract_code,policy.source_schema_version policy_source_schema_version,
policy.source_acceptance_gate_id policy_source_acceptance_gate_id,policy.source_combined_set_hash policy_source_combined_set_hash,policy.configuration_hash,
source_registry.registry_rows source_registry_rows,source_registry.contract_status source_contract_status,source_registry.contract_code source_contract_code,
source_registry.contract_version source_contract_version,source_registry.schema_version source_schema_version,source_registry.methodology_version source_methodology_version,
source_registry.combined_set_hash source_combined_set_hash,source_registry.latest_rows source_latest_rows,source_registry.payment_event_rows source_payment_event_rows,
source_registry.lifecycle_transition_rows source_transition_rows,source_registry.comparison_rows source_comparison_rows,source_registry.canonical_entities source_canonical_entities,
source_gate.gate_rows source_gate_rows,source_gate.gate_status source_gate_status,
account_source.account_rows,account_source.distinct_grain_rows,account_source.no_activity_rows,account_source.payment_activity_rows,account_source.review_hold_rows,
account_source.processed_amount account_processed_amount,account_source.returned_amount account_returned_amount,account_source.retry_amount account_retry_amount,
account_source.ending_exposure account_ending_exposure,account_source.invalid_rows invalid_account_rows,
payment_source.payment_rows,payment_source.distinct_payment_rows,payment_source.settled_rows,payment_source.returned_rows,payment_source.retry_rows,
payment_source.scheduled_amount,payment_source.processed_amount payment_processed_amount,payment_source.returned_amount payment_returned_amount,payment_source.retry_amount payment_retry_amount,payment_source.invalid_rows invalid_payment_rows,
transition_source.transition_rows,transition_source.distinct_transition_rows,transition_source.initial_rows,transition_source.payment_transition_rows,transition_source.checkpoint_rows,transition_source.invalid_rows invalid_transition_rows,
definitions.outcome_rows,definitions.action_rows,definitions.certification_rows,definitions.reason_rows,definitions.prohibited_definition_flags,targets.*,
CASE WHEN run_context.run_status='M2_8_ACCEPTED' AND policy.policy_status='APPROVED' AND policy.methodology_version='M2_9_METHOD_V1' AND policy.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND policy.contract_version=1 AND policy.schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'
AND policy.source_contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND policy.source_schema_version='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1' AND policy.source_acceptance_gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND policy.source_combined_set_hash='ab32d80ba20c2c8f0a6ec9ec97c2ed26'
AND policy.synthetic_data_only_flag AND policy.reconciliation_certification_only_flag AND policy.preserve_m2_8_history_flag AND policy.no_real_funds_movement_flag AND policy.no_bank_account_data_flag AND policy.no_ach_or_network_transmission_flag AND policy.no_external_processor_call_flag AND policy.no_real_merchant_contact_flag AND policy.no_write_off_or_collection_execution_flag AND policy.no_external_notice_generation_flag AND policy.no_production_adverse_action_flag
AND source_registry.registry_rows=1 AND source_registry.contract_status='ACCEPTED' AND source_registry.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND source_registry.contract_version=1 AND source_registry.schema_version='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1' AND source_registry.methodology_version='M2_8_METHOD_V1' AND source_registry.combined_set_hash='ab32d80ba20c2c8f0a6ec9ec97c2ed26' AND source_registry.latest_rows=59 AND source_registry.payment_event_rows=7 AND source_registry.lifecycle_transition_rows=67 AND source_registry.comparison_rows=15 AND source_registry.canonical_entities=367
AND source_gate.gate_rows=1 AND source_gate.gate_status='PASS'
AND account_source.account_rows=59 AND account_source.distinct_grain_rows=59 AND account_source.no_activity_rows=57 AND account_source.payment_activity_rows=1 AND account_source.review_hold_rows=1 AND account_source.processed_amount=194.25 AND account_source.returned_amount=27.75 AND account_source.retry_amount=27.75 AND account_source.ending_exposure=785.48 AND account_source.invalid_rows=0
AND payment_source.payment_rows=7 AND payment_source.distinct_payment_rows=7 AND payment_source.settled_rows=5 AND payment_source.returned_rows=1 AND payment_source.retry_rows=1 AND payment_source.scheduled_amount=194.25 AND payment_source.processed_amount=194.25 AND payment_source.returned_amount=27.75 AND payment_source.retry_amount=27.75 AND payment_source.invalid_rows=0
AND transition_source.transition_rows=67 AND transition_source.distinct_transition_rows=67 AND transition_source.initial_rows=59 AND transition_source.payment_transition_rows=7 AND transition_source.checkpoint_rows=1 AND transition_source.invalid_rows=0
AND definitions.outcome_rows=7 AND definitions.action_rows=7 AND definitions.certification_rows=7 AND definitions.reason_rows=36 AND definitions.prohibited_definition_flags=0
AND targets.target_account_source_rows=0 AND targets.target_payment_source_rows=0 AND targets.target_transition_source_rows=0 AND targets.target_payment_reconciliation_rows=0 AND targets.target_exception_rows=0 AND targets.target_account_reconciliation_rows=0 AND targets.target_certification_rows=0 AND targets.target_portfolio_rows=0 AND targets.target_latest_rows=0 AND targets.target_archive_rows=0 AND targets.target_registry_rows=0 AND targets.target_evidence_rows=0 AND targets.target_acceptance_rows=0 AND targets.premature_m2_10_tables=0 AND targets.prohibited_columns=0
THEN 'PASS' ELSE 'FAIL' END preflight_status
FROM run_context CROSS JOIN policy CROSS JOIN source_registry CROSS JOIN source_gate CROSS JOIN account_source CROSS JOIN payment_source CROSS JOIN transition_source CROSS JOIN definitions CROSS JOIN targets;
/* ============================================================================
Section 2 — Fail-closed preflight and generation readiness
============================================================================ */
DO $m2_9_preflight_guard$ DECLARE v record; BEGIN SELECT * INTO v FROM _m2_9_preflight; IF v.preflight_status<>'PASS' THEN RAISE EXCEPTION 'M2.9 preflight failed: %.',row_to_json(v); END IF; PERFORM msbf_ctl.m2_9_assert_generation_ready(v.run_id); END; $m2_9_preflight_guard$;
/* ============================================================================
Section 3 — Session-preserved checkpoint
============================================================================ */
SELECT * FROM _m2_9_preflight;
