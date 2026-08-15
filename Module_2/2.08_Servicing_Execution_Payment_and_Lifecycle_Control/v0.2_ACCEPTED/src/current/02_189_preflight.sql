/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.8 — Servicing Execution Simulation, Payment Processing
             & Account Lifecycle Control

Program     : 189_msbf_m2_8_preflight_validation_v0_2.sql
Version     : v0.2

Purpose
-------
Fail closed unless the accepted M2.7 lifecycle, contract, gate, combined
hash, 59-row latest population, exact 57/1/1 posture, dictionaries, policy
boundaries, and empty M2.8 target state are exact.

Stage boundary
--------------
All servicing, payment, processor-reference, return, retry, and lifecycle
outputs are deterministic synthetic evidence. No real funds move; no bank or
routing data is used; no ACH/network transmission, external processor call,
merchant contact, write-off/collection/legal execution, external notice, or
production adverse action occurs.

Required result
---------------
preflight_status = PASS.
============================================================================ */

SET statement_timeout='30min'; SET jit=off;
DROP TABLE IF EXISTS _m2_8_preflight;
CREATE TEMP TABLE _m2_8_preflight ON COMMIT PRESERVE ROWS AS
WITH r AS(SELECT run_id,run_status,population_id,as_of_date FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
p AS(SELECT * FROM msbf_ctl.m2_8_policy_profile WHERE module1_run_id=(SELECT run_id FROM r)),
sr AS(SELECT count(*) registry_rows,max(contract_status) contract_status,max(contract_code) contract_code,max(contract_version) contract_version,max(schema_version) schema_version,max(methodology_version) methodology_version,max(combined_set_hash) combined_set_hash,max(latest_rows) latest_rows,max(archive_rows) archive_rows,max(comparison_rows) comparison_rows,max(canonical_entities) canonical_entities FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)),
sg AS(SELECT count(*) gate_rows,max(result_status) gate_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND review_version=1),
sp AS(SELECT count(*) source_rows,count(DISTINCT scenario_id::text||'|'||merchant_application_id) distinct_grain_rows,count(DISTINCT merchant_application_id) distinct_applications,
 count(*) FILTER(WHERE scenario_id IS NULL OR scenario_code='' OR merchant_application_id='' OR merchant_id='' OR synthetic_account_id='' OR synthetic_advance_id='' OR operational_setup_outcome_code='' OR operational_setup_action_code='' OR account_setup_status_code='' OR synthetic_operational_case_id='' OR synthetic_account_setup_id='' OR primary_setup_reason_code='' OR contract_row_hash IS NULL OR jsonb_typeof(setup_reason_codes)<>'array' OR jsonb_typeof(setup_parameter_payload)<>'object') invalid_source_rows,
 count(*) FILTER(WHERE operational_setup_outcome_code='NO_OPERATIONAL_SETUP_REQUIRED' AND operational_setup_action_code='CLOSE_WITHOUT_SETUP' AND account_setup_status_code='NOT_REQUIRED' AND no_setup_required_flag) no_setup_source_rows,
 count(*) FILTER(WHERE operational_setup_outcome_code='TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY' AND operational_setup_action_code='CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT' AND account_setup_status_code='SIMULATED_BLUEPRINT_READY' AND setup_authorized_flag) temporary_source_rows,
 count(*) FILTER(WHERE operational_setup_outcome_code='OPERATIONAL_SETUP_REVIEW_REQUIRED' AND operational_setup_action_code='ROUTE_OPERATIONAL_GOVERNANCE_REVIEW' AND account_setup_status_code='OPERATIONAL_REVIEW_REQUIRED' AND setup_review_required_flag) review_source_rows,
 round(sum(source_recommended_action_exposure_amount),2) source_exposure_amount,
 round(sum(CASE WHEN operational_setup_outcome_code='TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY' THEN source_recommended_action_exposure_amount ELSE 0 END),2) temporary_exposure_amount,
 round(sum(CASE WHEN operational_setup_outcome_code='OPERATIONAL_SETUP_REVIEW_REQUIRED' THEN source_recommended_action_exposure_amount ELSE 0 END),2) review_exposure_amount
 FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=(SELECT run_id FROM r)),
d AS(SELECT
 (SELECT count(*) FROM msbf_m2.servicing_execution_outcome_definition WHERE module1_run_id=(SELECT run_id FROM r) AND definition_status='APPROVED') outcome_rows,
 (SELECT count(*) FROM msbf_m2.servicing_execution_action_definition WHERE module1_run_id=(SELECT run_id FROM r) AND definition_status='APPROVED') action_rows,
 (SELECT count(*) FROM msbf_m2.account_lifecycle_state_definition WHERE module1_run_id=(SELECT run_id FROM r) AND definition_status='APPROVED') lifecycle_state_rows,
 (SELECT count(*) FROM msbf_m2.servicing_execution_reason_definition WHERE module1_run_id=(SELECT run_id FROM r) AND definition_status='APPROVED') reason_rows,
 (SELECT count(*) FROM msbf_m2.servicing_execution_outcome_definition WHERE module1_run_id=(SELECT run_id FROM r) AND (real_funds_moved_flag OR bank_account_data_present_flag OR ach_or_network_transmitted_flag OR external_processor_called_flag OR merchant_contact_executed_flag OR write_off_or_collection_flag OR external_notice_generated_flag OR production_adverse_action_flag))+
 (SELECT count(*) FROM msbf_m2.servicing_execution_action_definition WHERE module1_run_id=(SELECT run_id FROM r) AND (real_funds_moved_flag OR bank_account_data_present_flag OR ach_or_network_transmitted_flag OR external_processor_called_flag OR merchant_contact_executed_flag OR write_off_or_collection_flag OR external_notice_generated_flag OR production_adverse_action_flag))+
 (SELECT count(*) FROM msbf_m2.account_lifecycle_state_definition WHERE module1_run_id=(SELECT run_id FROM r) AND (real_funds_moved_flag OR production_account_state_flag))+
 (SELECT count(*) FROM msbf_m2.servicing_execution_reason_definition WHERE module1_run_id=(SELECT run_id FROM r) AND (real_execution_reason_flag OR production_adverse_action_flag)) prohibited_definition_flags),
t AS(SELECT
 (SELECT count(*) FROM msbf_m2.servicing_execution_source_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) target_source_rows,
 (SELECT count(*) FROM msbf_m2.application_servicing_execution_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) target_execution_rows,
 (SELECT count(*) FROM msbf_m2.synthetic_payment_processing_event WHERE module1_run_id=(SELECT run_id FROM r)) target_payment_event_rows,
 (SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) target_lifecycle_transition_rows,
 (SELECT count(*) FROM msbf_m2.servicing_execution_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM r)) target_portfolio_rows,
 (SELECT count(*) FROM msbf_m2.application_servicing_execution_latest WHERE module1_run_id=(SELECT run_id FROM r)) target_latest_rows,
 (SELECT count(*) FROM msbf_m2.application_servicing_execution_archive WHERE module1_run_id=(SELECT run_id FROM r)) target_archive_rows,
 (SELECT count(*) FROM msbf_ctl.m2_8_servicing_execution_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)) target_registry_rows,
 (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M2_8_%') target_evidence_rows,
 (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL') target_acceptance_rows,
 (SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_9%') premature_m2_9_tables,
 (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN ('application_servicing_execution_snapshot','synthetic_payment_processing_event','account_lifecycle_transition_snapshot','application_servicing_execution_latest','application_servicing_execution_archive') AND lower(column_name) IN ('real_bank_account_number','bank_account_number','routing_number','settlement_account_number','ach_trace_number','payment_network_confirmation','processor_authorization_code','external_notice_payload','production_adverse_action_notice')) prohibited_columns)
SELECT r.run_id,r.run_status,r.population_id,r.as_of_date,p.policy_status,p.methodology_version,p.contract_code,p.contract_version,p.schema_version,
 p.source_contract_code policy_source_contract_code,p.source_contract_version policy_source_contract_version,p.source_schema_version policy_source_schema_version,
 p.source_acceptance_gate_id policy_source_acceptance_gate_id,p.source_combined_set_hash policy_source_combined_set_hash,p.configuration_hash,
 sr.registry_rows source_registry_rows,sr.contract_status source_contract_status,sr.contract_code source_contract_code,sr.contract_version source_contract_version,
 sr.schema_version source_schema_version,sr.methodology_version source_methodology_version,sr.combined_set_hash source_combined_set_hash,
 sr.latest_rows source_latest_rows,sr.archive_rows source_archive_rows,sr.comparison_rows source_comparison_rows,sr.canonical_entities source_canonical_entities,
 sg.gate_rows source_gate_rows,sg.gate_status source_gate_status,sp.*,d.*,t.*,
 CASE WHEN r.run_status='M2_7_ACCEPTED' AND p.policy_status='APPROVED' AND p.methodology_version='M2_8_METHOD_V1'
 AND p.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND p.contract_version=1 AND p.schema_version='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1'
 AND p.source_contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND p.source_contract_version=1 AND p.source_schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
 AND p.source_acceptance_gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND p.source_combined_set_hash='c8e3a472afd2a16b1183677324e9db98'
 AND p.synthetic_data_only_flag AND p.simulated_servicing_execution_only_flag AND p.preserve_m2_7_history_flag
 AND p.no_real_funds_movement_flag AND p.no_bank_account_data_flag AND p.no_ach_or_network_transmission_flag
 AND p.no_external_processor_call_flag AND p.no_real_merchant_contact_flag AND p.no_write_off_or_collection_execution_flag
 AND p.no_external_notice_generation_flag AND p.no_production_adverse_action_flag
 AND sr.registry_rows=1 AND sr.contract_status='ACCEPTED' AND sr.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND sr.contract_version=1
 AND sr.schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1' AND sr.methodology_version='M2_7_METHOD_V1' AND sr.combined_set_hash='c8e3a472afd2a16b1183677324e9db98'
 AND sr.latest_rows=59 AND sr.archive_rows=59 AND sr.comparison_rows=15 AND sr.canonical_entities=341 AND sg.gate_rows=1 AND sg.gate_status='PASS'
 AND sp.source_rows=59 AND sp.distinct_grain_rows=59 AND sp.invalid_source_rows=0 AND sp.no_setup_source_rows=57 AND sp.temporary_source_rows=1
 AND sp.review_source_rows=1 AND sp.source_exposure_amount=979.73 AND sp.temporary_exposure_amount=518.04 AND sp.review_exposure_amount=461.69
 AND d.outcome_rows=7 AND d.action_rows=7 AND d.lifecycle_state_rows=7 AND d.reason_rows=32 AND d.prohibited_definition_flags=0
 AND t.target_source_rows=0 AND t.target_execution_rows=0 AND t.target_payment_event_rows=0 AND t.target_lifecycle_transition_rows=0
 AND t.target_portfolio_rows=0 AND t.target_latest_rows=0 AND t.target_archive_rows=0 AND t.target_registry_rows=0
 AND t.target_evidence_rows=0 AND t.target_acceptance_rows=0 AND t.premature_m2_9_tables=0 AND t.prohibited_columns=0
 THEN 'PASS' ELSE 'FAIL' END preflight_status
FROM r CROSS JOIN p CROSS JOIN sr CROSS JOIN sg CROSS JOIN sp CROSS JOIN d CROSS JOIN t;
DO $guard$ DECLARE v record;BEGIN SELECT * INTO v FROM _m2_8_preflight;IF v.preflight_status<>'PASS' THEN RAISE EXCEPTION 'M2.8 preflight failed: %.',row_to_json(v);END IF;PERFORM msbf_ctl.m2_8_assert_generation_ready(v.run_id);END;$guard$;
SELECT * FROM _m2_8_preflight;
