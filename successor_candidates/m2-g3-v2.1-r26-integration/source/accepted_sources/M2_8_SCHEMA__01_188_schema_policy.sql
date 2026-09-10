/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.8 — Servicing Execution Simulation, Payment Processing
             & Account Lifecycle Control

Program     : 188_msbf_m2_8_schema_policy_payment_lifecycle_extension_v0_2.sql
Version     : v0.2

Purpose
-------
Create the governed M2.8 policy, execution outcome/action, lifecycle state,
and reason dictionaries; source, execution, payment-event, lifecycle,
portfolio, latest, archive, and registry structures; deterministic assertions;
archive immutability; and consumption, comparison, Power BI, lineage, and
canonical views.

Stage boundary
--------------
All servicing, payment, processor-reference, return, retry, and lifecycle
outputs are deterministic synthetic evidence. No real funds move; no bank or
routing data is used; no ACH/network transmission, external processor call,
merchant contact, write-off/collection/legal execution, external notice, or
production adverse action occurs.

Required result
---------------
schema_policy_status = PASS.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='35min';
SET LOCAL jit=off;

/* ============================================================================
Section 1 — Deterministic hash utilities
============================================================================ */
CREATE OR REPLACE FUNCTION msbf_ctl.m2_8_hash_jsonb(p_payload jsonb)
RETURNS text LANGUAGE sql IMMUTABLE STRICT
AS $function$ SELECT md5(p_payload::text); $function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_8_registry_row_hash(p_payload jsonb)
RETURNS text LANGUAGE sql IMMUTABLE STRICT
AS $function$
 SELECT msbf_ctl.m2_8_hash_jsonb(p_payload-'registry_id'-'contract_status'-'generated_at'-'validated_at'-'accepted_at'-'row_hash'-'created_at'-'contract_set_hash'-'combined_set_hash');
$function$;

/* ============================================================================
Section 2 — Policy and dictionaries
============================================================================ */
CREATE TABLE IF NOT EXISTS msbf_ctl.m2_8_policy_profile
(
 module1_run_id bigint PRIMARY KEY,
 policy_code text NOT NULL, policy_version integer NOT NULL, policy_status text NOT NULL,
 methodology_version text NOT NULL, contract_code text NOT NULL,
 contract_version integer NOT NULL, schema_version text NOT NULL,
 source_registry_name text NOT NULL, source_latest_name text NOT NULL,
 source_contract_code text NOT NULL, source_contract_version integer NOT NULL,
 source_schema_version text NOT NULL, source_methodology_version text NOT NULL,
 source_policy_code text NOT NULL, source_acceptance_gate_id text NOT NULL,
 source_combined_set_hash text NOT NULL,
 synthetic_data_only_flag boolean NOT NULL,
 simulated_servicing_execution_only_flag boolean NOT NULL,
 preserve_m2_7_history_flag boolean NOT NULL,
 no_real_funds_movement_flag boolean NOT NULL,
 no_bank_account_data_flag boolean NOT NULL,
 no_ach_or_network_transmission_flag boolean NOT NULL,
 no_external_processor_call_flag boolean NOT NULL,
 no_real_merchant_contact_flag boolean NOT NULL,
 no_write_off_or_collection_execution_flag boolean NOT NULL,
 no_external_notice_generation_flag boolean NOT NULL,
 no_production_adverse_action_flag boolean NOT NULL,
 servicing_cycle_days integer NOT NULL,
 synthetic_return_event_sequence integer NOT NULL,
 synthetic_retry_event_sequence integer NOT NULL,
 retry_catchup_multiplier numeric(9,6) NOT NULL,
 default_temporary_payment_factor numeric(9,6) NOT NULL,
 default_setup_duration_days integer NOT NULL,
 default_reassessment_interval_days integer NOT NULL,
 expected_policy_rows bigint NOT NULL, expected_outcome_rows bigint NOT NULL,
 expected_action_rows bigint NOT NULL, expected_lifecycle_state_rows bigint NOT NULL,
 expected_reason_rows bigint NOT NULL, expected_source_rows bigint NOT NULL,
 expected_execution_rows bigint NOT NULL, expected_payment_event_rows bigint NOT NULL,
 expected_lifecycle_transition_rows bigint NOT NULL,
 expected_portfolio_summary_rows bigint NOT NULL, expected_latest_rows bigint NOT NULL,
 expected_archive_rows bigint NOT NULL, expected_comparison_rows bigint NOT NULL,
 expected_registry_rows bigint NOT NULL, expected_canonical_entities bigint NOT NULL,
 expected_positive_controls integer NOT NULL, expected_negative_controls integer NOT NULL,
 expected_generation_evidence_rows integer NOT NULL,
 expected_detail_result_sets integer NOT NULL,
 configuration_payload jsonb NOT NULL, configuration_hash text NOT NULL,
 row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CONSTRAINT ck_m2_8_policy_identity CHECK
 (policy_code='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1' AND policy_version=1 AND methodology_version='M2_8_METHOD_V1'
  AND contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND contract_version=1 AND schema_version='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1'),
 CONSTRAINT ck_m2_8_policy_status CHECK(policy_status IN ('APPROVED','RETIRED')),
 CONSTRAINT ck_m2_8_policy_boundaries CHECK
 (synthetic_data_only_flag AND simulated_servicing_execution_only_flag
  AND preserve_m2_7_history_flag AND no_real_funds_movement_flag
  AND no_bank_account_data_flag AND no_ach_or_network_transmission_flag
  AND no_external_processor_call_flag AND no_real_merchant_contact_flag
  AND no_write_off_or_collection_execution_flag AND no_external_notice_generation_flag
  AND no_production_adverse_action_flag AND servicing_cycle_days BETWEEN 1 AND 31
  AND synthetic_return_event_sequence BETWEEN 1 AND servicing_cycle_days
  AND synthetic_retry_event_sequence BETWEEN 1 AND servicing_cycle_days
  AND synthetic_retry_event_sequence>synthetic_return_event_sequence
  AND retry_catchup_multiplier BETWEEN 1.00 AND 3.00
  AND default_temporary_payment_factor BETWEEN 0.10 AND 1.00
  AND default_setup_duration_days BETWEEN 1 AND 90
  AND default_reassessment_interval_days BETWEEN 1 AND 30),
 CONSTRAINT ck_m2_8_policy_hash CHECK
 (length(configuration_hash)=32 AND configuration_hash ~ '^[0-9a-f]+$'
  AND length(row_hash)=32 AND row_hash ~ '^[0-9a-f]+$')
);

CREATE TABLE IF NOT EXISTS msbf_m2.servicing_execution_outcome_definition
(
 module1_run_id bigint NOT NULL, servicing_execution_outcome_code text NOT NULL,
 servicing_execution_outcome_rank integer NOT NULL,
 processing_authorized_flag boolean NOT NULL,
 processing_review_required_flag boolean NOT NULL,
 no_processing_required_flag boolean NOT NULL,
 real_funds_moved_flag boolean NOT NULL, bank_account_data_present_flag boolean NOT NULL,
 ach_or_network_transmitted_flag boolean NOT NULL, external_processor_called_flag boolean NOT NULL,
 merchant_contact_executed_flag boolean NOT NULL, write_off_or_collection_flag boolean NOT NULL,
 external_notice_generated_flag boolean NOT NULL, production_adverse_action_flag boolean NOT NULL,
 definition_status text NOT NULL, description text NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,servicing_execution_outcome_code),
 CONSTRAINT ck_m2_8_outcome_rank CHECK(servicing_execution_outcome_rank BETWEEN 0 AND 9),
 CONSTRAINT ck_m2_8_outcome_status CHECK(definition_status IN ('APPROVED','RETIRED')),
 CONSTRAINT ck_m2_8_outcome_exclusive CHECK
 (num_nonnulls(NULLIF(processing_authorized_flag,FALSE),NULLIF(processing_review_required_flag,FALSE),NULLIF(no_processing_required_flag,FALSE))=1),
 CONSTRAINT ck_m2_8_outcome_boundary CHECK
 (NOT real_funds_moved_flag AND NOT bank_account_data_present_flag
  AND NOT ach_or_network_transmitted_flag AND NOT external_processor_called_flag
  AND NOT merchant_contact_executed_flag AND NOT write_off_or_collection_flag
  AND NOT external_notice_generated_flag AND NOT production_adverse_action_flag)
);

CREATE TABLE IF NOT EXISTS msbf_m2.servicing_execution_action_definition
(
 module1_run_id bigint NOT NULL, servicing_execution_action_code text NOT NULL,
 servicing_execution_action_rank integer NOT NULL, payment_cycle_flag boolean NOT NULL,
 temporary_cycle_flag boolean NOT NULL, restructure_cycle_flag boolean NOT NULL,
 recovery_cycle_flag boolean NOT NULL, charge_off_control_flag boolean NOT NULL,
 review_hold_flag boolean NOT NULL,
 real_funds_moved_flag boolean NOT NULL, bank_account_data_present_flag boolean NOT NULL,
 ach_or_network_transmitted_flag boolean NOT NULL, external_processor_called_flag boolean NOT NULL,
 merchant_contact_executed_flag boolean NOT NULL, write_off_or_collection_flag boolean NOT NULL,
 external_notice_generated_flag boolean NOT NULL, production_adverse_action_flag boolean NOT NULL,
 definition_status text NOT NULL, description text NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,servicing_execution_action_code),
 CONSTRAINT ck_m2_8_action_rank CHECK(servicing_execution_action_rank BETWEEN 0 AND 9),
 CONSTRAINT ck_m2_8_action_status CHECK(definition_status IN ('APPROVED','RETIRED')),
 CONSTRAINT ck_m2_8_action_boundary CHECK
 (NOT real_funds_moved_flag AND NOT bank_account_data_present_flag
  AND NOT ach_or_network_transmitted_flag AND NOT external_processor_called_flag
  AND NOT merchant_contact_executed_flag AND NOT write_off_or_collection_flag
  AND NOT external_notice_generated_flag AND NOT production_adverse_action_flag)
);

CREATE TABLE IF NOT EXISTS msbf_m2.account_lifecycle_state_definition
(
 module1_run_id bigint NOT NULL, lifecycle_state_code text NOT NULL,
 lifecycle_state_rank integer NOT NULL, active_flag boolean NOT NULL,
 exception_flag boolean NOT NULL, closed_flag boolean NOT NULL,
 real_funds_moved_flag boolean NOT NULL, production_account_state_flag boolean NOT NULL,
 definition_status text NOT NULL, description text NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,lifecycle_state_code),
 CONSTRAINT ck_m2_8_lifecycle_rank CHECK(lifecycle_state_rank BETWEEN 0 AND 9),
 CONSTRAINT ck_m2_8_lifecycle_status CHECK(definition_status IN ('APPROVED','RETIRED')),
 CONSTRAINT ck_m2_8_lifecycle_boundary CHECK(NOT real_funds_moved_flag AND NOT production_account_state_flag)
);

CREATE TABLE IF NOT EXISTS msbf_m2.servicing_execution_reason_definition
(
 module1_run_id bigint NOT NULL, servicing_execution_reason_code text NOT NULL,
 mapped_outcome_code text NOT NULL, mapped_action_code text NOT NULL,
 real_execution_reason_flag boolean NOT NULL, production_adverse_action_flag boolean NOT NULL,
 definition_status text NOT NULL, description text NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,servicing_execution_reason_code),
 FOREIGN KEY(module1_run_id,mapped_outcome_code)
  REFERENCES msbf_m2.servicing_execution_outcome_definition(module1_run_id,servicing_execution_outcome_code),
 FOREIGN KEY(module1_run_id,mapped_action_code)
  REFERENCES msbf_m2.servicing_execution_action_definition(module1_run_id,servicing_execution_action_code),
 CONSTRAINT ck_m2_8_reason_status CHECK(definition_status IN ('APPROVED','RETIRED')),
 CONSTRAINT ck_m2_8_reason_boundary CHECK(NOT real_execution_reason_flag AND NOT production_adverse_action_flag)
);

/* ============================================================================
Section 3 — Source, execution, payment, lifecycle, portfolio, latest, archive
============================================================================ */
CREATE TABLE IF NOT EXISTS msbf_m2.servicing_execution_source_snapshot
(
 module1_run_id bigint NOT NULL, scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, merchant_id text NOT NULL,
 synthetic_account_id text NOT NULL, synthetic_advance_id text NOT NULL,
 source_operational_setup_outcome_code text NOT NULL,
 source_operational_setup_action_code text NOT NULL, source_setup_status_code text NOT NULL,
 source_setup_authorized_flag boolean NOT NULL, source_setup_review_required_flag boolean NOT NULL,
 source_no_setup_required_flag boolean NOT NULL, source_exposure_amount numeric(18,2) NOT NULL,
 source_operational_case_id text NOT NULL, source_account_setup_id text NOT NULL,
 source_servicing_plan_id text, source_activation_date date, source_reassessment_date date,
 source_payment_factor numeric(9,6), source_setup_duration_days integer,
 source_reassessment_interval_days integer, source_primary_reason_code text NOT NULL,
 source_reason_codes jsonb NOT NULL, source_setup_parameter_payload jsonb NOT NULL,
 source_contract_row_hash text NOT NULL, source_combined_set_hash text NOT NULL,
 source_payload jsonb NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
 CONSTRAINT ck_m2_8_source_amount CHECK(source_exposure_amount>=0),
 CONSTRAINT ck_m2_8_source_json CHECK(jsonb_typeof(source_reason_codes)='array' AND jsonb_typeof(source_setup_parameter_payload)='object' AND jsonb_typeof(source_payload)='object')
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_servicing_execution_snapshot
(
 module1_run_id bigint NOT NULL, scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, merchant_id text NOT NULL,
 synthetic_account_id text NOT NULL, synthetic_advance_id text NOT NULL,
 source_operational_setup_outcome_code text NOT NULL,
 source_operational_setup_action_code text NOT NULL, source_account_setup_status_code text NOT NULL,
 source_exposure_amount numeric(18,2) NOT NULL,
 servicing_execution_outcome_code text NOT NULL, servicing_execution_action_code text NOT NULL,
 servicing_execution_priority_rank integer NOT NULL, servicing_execution_queue_code text NOT NULL,
 processing_authorized_flag boolean NOT NULL, processing_review_required_flag boolean NOT NULL,
 no_processing_required_flag boolean NOT NULL, synthetic_servicing_execution_id text NOT NULL,
 initial_lifecycle_state_code text NOT NULL, final_lifecycle_state_code text NOT NULL,
 payment_event_count integer NOT NULL, settled_event_count integer NOT NULL,
 returned_event_count integer NOT NULL, retry_event_count integer NOT NULL,
 standard_daily_payment_amount numeric(18,2) NOT NULL,
 temporary_daily_payment_amount numeric(18,2) NOT NULL,
 scheduled_payment_amount numeric(18,2) NOT NULL, processed_payment_amount numeric(18,2) NOT NULL,
 returned_payment_amount numeric(18,2) NOT NULL, retry_payment_amount numeric(18,2) NOT NULL,
 ending_simulated_exposure_amount numeric(18,2) NOT NULL,
 primary_execution_reason_code text NOT NULL, execution_reason_codes jsonb NOT NULL,
 real_funds_moved_flag boolean NOT NULL, bank_account_data_present_flag boolean NOT NULL,
 ach_or_network_transmitted_flag boolean NOT NULL, external_processor_called_flag boolean NOT NULL,
 merchant_contact_executed_flag boolean NOT NULL, write_off_or_collection_flag boolean NOT NULL,
 external_notice_generated_flag boolean NOT NULL, production_adverse_action_flag boolean NOT NULL,
 source_contract_row_hash text NOT NULL, source_snapshot_row_hash text NOT NULL,
 policy_configuration_hash text NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
 FOREIGN KEY(module1_run_id,servicing_execution_outcome_code)
  REFERENCES msbf_m2.servicing_execution_outcome_definition(module1_run_id,servicing_execution_outcome_code),
 FOREIGN KEY(module1_run_id,servicing_execution_action_code)
  REFERENCES msbf_m2.servicing_execution_action_definition(module1_run_id,servicing_execution_action_code),
 FOREIGN KEY(module1_run_id,primary_execution_reason_code)
  REFERENCES msbf_m2.servicing_execution_reason_definition(module1_run_id,servicing_execution_reason_code),
 FOREIGN KEY(module1_run_id,initial_lifecycle_state_code)
  REFERENCES msbf_m2.account_lifecycle_state_definition(module1_run_id,lifecycle_state_code),
 FOREIGN KEY(module1_run_id,final_lifecycle_state_code)
  REFERENCES msbf_m2.account_lifecycle_state_definition(module1_run_id,lifecycle_state_code),
 CONSTRAINT ck_m2_8_exec_exclusive CHECK
 (num_nonnulls(NULLIF(processing_authorized_flag,FALSE),NULLIF(processing_review_required_flag,FALSE),NULLIF(no_processing_required_flag,FALSE))=1),
 CONSTRAINT ck_m2_8_exec_counts CHECK(payment_event_count>=0 AND settled_event_count>=0 AND returned_event_count>=0 AND retry_event_count>=0 AND settled_event_count+returned_event_count+retry_event_count=payment_event_count),
 CONSTRAINT ck_m2_8_exec_amounts CHECK(standard_daily_payment_amount>=0 AND temporary_daily_payment_amount>=0 AND scheduled_payment_amount>=0 AND processed_payment_amount>=0 AND returned_payment_amount>=0 AND retry_payment_amount>=0 AND ending_simulated_exposure_amount>=0),
 CONSTRAINT ck_m2_8_exec_boundary CHECK
 (NOT real_funds_moved_flag AND NOT bank_account_data_present_flag AND NOT ach_or_network_transmitted_flag AND NOT external_processor_called_flag AND NOT merchant_contact_executed_flag AND NOT write_off_or_collection_flag AND NOT external_notice_generated_flag AND NOT production_adverse_action_flag)
);

CREATE TABLE IF NOT EXISTS msbf_m2.synthetic_payment_processing_event
(
 module1_run_id bigint NOT NULL, scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, synthetic_account_id text NOT NULL,
 synthetic_advance_id text NOT NULL, synthetic_servicing_execution_id text NOT NULL,
 synthetic_servicing_plan_id text NOT NULL, event_sequence integer NOT NULL,
 event_date date NOT NULL, payment_event_type_code text NOT NULL,
 payment_status_code text NOT NULL, standard_daily_payment_amount numeric(18,2) NOT NULL,
 applied_payment_factor numeric(9,6) NOT NULL, scheduled_payment_amount numeric(18,2) NOT NULL,
 retry_payment_amount numeric(18,2) NOT NULL, returned_payment_amount numeric(18,2) NOT NULL,
 processed_payment_amount numeric(18,2) NOT NULL, cumulative_processed_amount numeric(18,2) NOT NULL,
 simulated_outstanding_exposure_amount numeric(18,2) NOT NULL,
 lifecycle_state_before_code text NOT NULL, lifecycle_state_after_code text NOT NULL,
 primary_event_reason_code text NOT NULL, synthetic_payment_instruction_id text NOT NULL,
 synthetic_processor_reference_id text NOT NULL,
 real_funds_moved_flag boolean NOT NULL, bank_account_data_present_flag boolean NOT NULL,
 ach_or_network_transmitted_flag boolean NOT NULL, external_processor_called_flag boolean NOT NULL,
 merchant_contact_executed_flag boolean NOT NULL, external_notice_generated_flag boolean NOT NULL,
 production_adverse_action_flag boolean NOT NULL, source_execution_row_hash text NOT NULL,
 row_hash text NOT NULL, created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id,event_sequence),
 FOREIGN KEY(module1_run_id,lifecycle_state_before_code)
  REFERENCES msbf_m2.account_lifecycle_state_definition(module1_run_id,lifecycle_state_code),
 FOREIGN KEY(module1_run_id,lifecycle_state_after_code)
  REFERENCES msbf_m2.account_lifecycle_state_definition(module1_run_id,lifecycle_state_code),
 FOREIGN KEY(module1_run_id,primary_event_reason_code)
  REFERENCES msbf_m2.servicing_execution_reason_definition(module1_run_id,servicing_execution_reason_code),
 CONSTRAINT ck_m2_8_payment_seq CHECK(event_sequence BETWEEN 1 AND 31),
 CONSTRAINT ck_m2_8_payment_type CHECK(payment_event_type_code IN ('SYNTHETIC_SCHEDULED_PAYMENT','SYNTHETIC_PAYMENT_RETURN','SYNTHETIC_RETRY_PAYMENT')),
 CONSTRAINT ck_m2_8_payment_status CHECK(payment_status_code IN ('SIMULATED_SETTLED','SIMULATED_RETURNED','SIMULATED_RETRY_SETTLED')),
 CONSTRAINT ck_m2_8_payment_amounts CHECK(standard_daily_payment_amount>=0 AND applied_payment_factor BETWEEN .10 AND 1.00 AND scheduled_payment_amount>=0 AND retry_payment_amount>=0 AND returned_payment_amount>=0 AND processed_payment_amount>=0 AND cumulative_processed_amount>=0 AND simulated_outstanding_exposure_amount>=0),
 CONSTRAINT ck_m2_8_payment_boundary CHECK
 (NOT real_funds_moved_flag AND NOT bank_account_data_present_flag AND NOT ach_or_network_transmitted_flag AND NOT external_processor_called_flag AND NOT merchant_contact_executed_flag AND NOT external_notice_generated_flag AND NOT production_adverse_action_flag)
);

CREATE TABLE IF NOT EXISTS msbf_m2.account_lifecycle_transition_snapshot
(
 module1_run_id bigint NOT NULL, scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, synthetic_account_id text NOT NULL,
 synthetic_advance_id text NOT NULL, synthetic_servicing_execution_id text NOT NULL,
 transition_sequence integer NOT NULL, transition_date date NOT NULL,
 transition_type_code text NOT NULL, lifecycle_state_before_code text NOT NULL,
 lifecycle_state_after_code text NOT NULL, related_payment_event_sequence integer,
 related_payment_instruction_id text, primary_transition_reason_code text NOT NULL,
 real_funds_moved_flag boolean NOT NULL, production_account_state_flag boolean NOT NULL,
 external_system_update_flag boolean NOT NULL, source_execution_row_hash text NOT NULL,
 related_payment_event_row_hash text, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id,transition_sequence),
 FOREIGN KEY(module1_run_id,lifecycle_state_before_code)
  REFERENCES msbf_m2.account_lifecycle_state_definition(module1_run_id,lifecycle_state_code),
 FOREIGN KEY(module1_run_id,lifecycle_state_after_code)
  REFERENCES msbf_m2.account_lifecycle_state_definition(module1_run_id,lifecycle_state_code),
 FOREIGN KEY(module1_run_id,primary_transition_reason_code)
  REFERENCES msbf_m2.servicing_execution_reason_definition(module1_run_id,servicing_execution_reason_code),
 CONSTRAINT ck_m2_8_transition_seq CHECK(transition_sequence BETWEEN 0 AND 31),
 CONSTRAINT ck_m2_8_transition_type CHECK(transition_type_code IN ('INITIAL_ACCOUNT_CONTROL','PAYMENT_PROCESSING_EVENT','PAYMENT_RETURN_EVENT','PAYMENT_RETRY_EVENT','REASSESSMENT_CHECKPOINT')),
 CONSTRAINT ck_m2_8_transition_boundary CHECK(NOT real_funds_moved_flag AND NOT production_account_state_flag AND NOT external_system_update_flag)
);

CREATE TABLE IF NOT EXISTS msbf_m2.servicing_execution_portfolio_summary
(
 module1_run_id bigint NOT NULL, scenario_code text NOT NULL,
 source_rows bigint NOT NULL, processing_authorized_rows bigint NOT NULL,
 review_hold_rows bigint NOT NULL, no_processing_required_rows bigint NOT NULL,
 payment_event_rows bigint NOT NULL, settled_event_rows bigint NOT NULL,
 returned_event_rows bigint NOT NULL, retry_event_rows bigint NOT NULL,
 lifecycle_transition_rows bigint NOT NULL, scheduled_payment_amount numeric(24,2) NOT NULL,
 processed_payment_amount numeric(24,2) NOT NULL, returned_payment_amount numeric(24,2) NOT NULL,
 retry_payment_amount numeric(24,2) NOT NULL, ending_simulated_exposure_amount numeric(24,2) NOT NULL,
 maximum_execution_priority_rank integer NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_code),
 CONSTRAINT ck_m2_8_portfolio_counts CHECK(processing_authorized_rows+review_hold_rows+no_processing_required_rows=source_rows)
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_servicing_execution_latest
(
 module1_run_id bigint NOT NULL, contract_code text NOT NULL, contract_version integer NOT NULL,
 schema_version text NOT NULL, methodology_version text NOT NULL,
 scenario_id bigint NOT NULL, scenario_code text NOT NULL, merchant_application_id text NOT NULL,
 merchant_id text NOT NULL, synthetic_account_id text NOT NULL, synthetic_advance_id text NOT NULL,
 source_operational_setup_outcome_code text NOT NULL, source_operational_setup_action_code text NOT NULL,
 source_account_setup_status_code text NOT NULL, source_exposure_amount numeric(18,2) NOT NULL,
 servicing_execution_outcome_code text NOT NULL, servicing_execution_action_code text NOT NULL,
 servicing_execution_priority_rank integer NOT NULL, servicing_execution_queue_code text NOT NULL,
 processing_authorized_flag boolean NOT NULL, processing_review_required_flag boolean NOT NULL,
 no_processing_required_flag boolean NOT NULL, synthetic_servicing_execution_id text NOT NULL,
 initial_lifecycle_state_code text NOT NULL, final_lifecycle_state_code text NOT NULL,
 payment_event_count integer NOT NULL, settled_event_count integer NOT NULL,
 returned_event_count integer NOT NULL, retry_event_count integer NOT NULL,
 standard_daily_payment_amount numeric(18,2) NOT NULL, temporary_daily_payment_amount numeric(18,2) NOT NULL,
 scheduled_payment_amount numeric(18,2) NOT NULL, processed_payment_amount numeric(18,2) NOT NULL,
 returned_payment_amount numeric(18,2) NOT NULL, retry_payment_amount numeric(18,2) NOT NULL,
 ending_simulated_exposure_amount numeric(18,2) NOT NULL,
 primary_execution_reason_code text NOT NULL, execution_reason_codes jsonb NOT NULL,
 source_contract_row_hash text NOT NULL, source_snapshot_row_hash text NOT NULL,
 execution_snapshot_row_hash text NOT NULL, policy_configuration_hash text NOT NULL,
 contract_row_hash text NOT NULL, created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
 CONSTRAINT ck_m2_8_latest_identity CHECK(contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND contract_version=1 AND schema_version='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1' AND methodology_version='M2_8_METHOD_V1')
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_servicing_execution_archive
(
 archive_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 module1_run_id bigint NOT NULL, contract_code text NOT NULL, contract_version integer NOT NULL,
 schema_version text NOT NULL, methodology_version text NOT NULL,
 scenario_id bigint NOT NULL, scenario_code text NOT NULL, merchant_application_id text NOT NULL,
 merchant_id text NOT NULL, synthetic_account_id text NOT NULL, synthetic_advance_id text NOT NULL,
 source_operational_setup_outcome_code text NOT NULL, source_operational_setup_action_code text NOT NULL,
 source_account_setup_status_code text NOT NULL, source_exposure_amount numeric(18,2) NOT NULL,
 servicing_execution_outcome_code text NOT NULL, servicing_execution_action_code text NOT NULL,
 servicing_execution_priority_rank integer NOT NULL, servicing_execution_queue_code text NOT NULL,
 processing_authorized_flag boolean NOT NULL, processing_review_required_flag boolean NOT NULL,
 no_processing_required_flag boolean NOT NULL, synthetic_servicing_execution_id text NOT NULL,
 initial_lifecycle_state_code text NOT NULL, final_lifecycle_state_code text NOT NULL,
 payment_event_count integer NOT NULL, settled_event_count integer NOT NULL,
 returned_event_count integer NOT NULL, retry_event_count integer NOT NULL,
 standard_daily_payment_amount numeric(18,2) NOT NULL, temporary_daily_payment_amount numeric(18,2) NOT NULL,
 scheduled_payment_amount numeric(18,2) NOT NULL, processed_payment_amount numeric(18,2) NOT NULL,
 returned_payment_amount numeric(18,2) NOT NULL, retry_payment_amount numeric(18,2) NOT NULL,
 ending_simulated_exposure_amount numeric(18,2) NOT NULL,
 primary_execution_reason_code text NOT NULL, execution_reason_codes jsonb NOT NULL,
 source_contract_row_hash text NOT NULL, source_snapshot_row_hash text NOT NULL,
 execution_snapshot_row_hash text NOT NULL, policy_configuration_hash text NOT NULL,
 contract_row_hash text NOT NULL, contract_payload jsonb NOT NULL, archive_row_hash text NOT NULL,
 archived_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(module1_run_id,contract_version,scenario_id,merchant_application_id),
 CONSTRAINT ck_m2_8_archive_identity CHECK(contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND contract_version=1 AND schema_version='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1' AND methodology_version='M2_8_METHOD_V1')
);

/* ============================================================================
Section 4 — Registry, immutability, indexes, assertions
============================================================================ */
CREATE TABLE IF NOT EXISTS msbf_ctl.m2_8_servicing_execution_contract_registry
(
 registry_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, module1_run_id bigint NOT NULL UNIQUE,
 contract_code text NOT NULL, contract_version integer NOT NULL, schema_version text NOT NULL,
 methodology_version text NOT NULL, source_contract_code text NOT NULL,
 source_contract_version integer NOT NULL, source_schema_version text NOT NULL,
 source_acceptance_gate_id text NOT NULL, source_combined_set_hash text NOT NULL,
 policy_configuration_hash text NOT NULL,
 policy_rows bigint NOT NULL, outcome_rows bigint NOT NULL, action_rows bigint NOT NULL,
 lifecycle_state_rows bigint NOT NULL, reason_rows bigint NOT NULL, source_rows bigint NOT NULL,
 execution_rows bigint NOT NULL, payment_event_rows bigint NOT NULL,
 lifecycle_transition_rows bigint NOT NULL, portfolio_summary_rows bigint NOT NULL,
 latest_rows bigint NOT NULL, archive_rows bigint NOT NULL, comparison_rows bigint NOT NULL,
 registry_rows bigint NOT NULL, canonical_entities bigint NOT NULL,
 no_processing_required_rows bigint NOT NULL, temporary_processing_rows bigint NOT NULL,
 review_hold_rows bigint NOT NULL, settled_event_rows bigint NOT NULL,
 returned_event_rows bigint NOT NULL, retry_event_rows bigint NOT NULL,
 initial_transition_rows bigint NOT NULL, payment_transition_rows bigint NOT NULL,
 checkpoint_transition_rows bigint NOT NULL, processing_authorized_amount numeric(24,2) NOT NULL,
 review_hold_amount numeric(24,2) NOT NULL, scheduled_payment_amount numeric(24,2) NOT NULL,
 processed_payment_amount numeric(24,2) NOT NULL, returned_payment_amount numeric(24,2) NOT NULL,
 retry_payment_amount numeric(24,2) NOT NULL, ending_simulated_exposure_amount numeric(24,2) NOT NULL,
 policy_set_hash text NOT NULL, outcome_set_hash text NOT NULL, action_set_hash text NOT NULL,
 lifecycle_state_set_hash text NOT NULL, reason_set_hash text NOT NULL, source_set_hash text NOT NULL,
 execution_set_hash text NOT NULL, payment_event_set_hash text NOT NULL,
 lifecycle_transition_set_hash text NOT NULL, portfolio_summary_set_hash text NOT NULL,
 latest_set_hash text NOT NULL, archive_set_hash text NOT NULL, contract_set_hash text NOT NULL,
 combined_set_hash text NOT NULL, contract_status text NOT NULL, generated_at timestamptz,
 validated_at timestamptz, accepted_at timestamptz, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CONSTRAINT ck_m2_8_registry_identity CHECK(contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND contract_version=1 AND schema_version='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1' AND methodology_version='M2_8_METHOD_V1'),
 CONSTRAINT ck_m2_8_registry_status CHECK(contract_status IN ('GENERATED','VALIDATED','ACCEPTED'))
);

CREATE OR REPLACE FUNCTION msbf_ctl.m2_8_archive_immutable()
RETURNS trigger LANGUAGE plpgsql AS $function$
BEGIN RAISE EXCEPTION 'M2.8 servicing execution archive is immutable; % is not permitted.',TG_OP; END;
$function$;
DROP TRIGGER IF EXISTS trg_m2_8_servicing_archive_immutable ON msbf_m2.application_servicing_execution_archive;
CREATE TRIGGER trg_m2_8_servicing_archive_immutable BEFORE UPDATE OR DELETE
ON msbf_m2.application_servicing_execution_archive FOR EACH ROW
EXECUTE FUNCTION msbf_ctl.m2_8_archive_immutable();

CREATE INDEX IF NOT EXISTS ix_m2_8_source_account ON msbf_m2.servicing_execution_source_snapshot(module1_run_id,scenario_code,synthetic_account_id);
CREATE INDEX IF NOT EXISTS ix_m2_8_execution_outcome ON msbf_m2.application_servicing_execution_snapshot(module1_run_id,scenario_code,servicing_execution_outcome_code);
CREATE INDEX IF NOT EXISTS ix_m2_8_payment_account_date ON msbf_m2.synthetic_payment_processing_event(module1_run_id,synthetic_account_id,event_date,event_sequence);
CREATE INDEX IF NOT EXISTS ix_m2_8_transition_account_sequence ON msbf_m2.account_lifecycle_transition_snapshot(module1_run_id,synthetic_account_id,transition_sequence);
CREATE INDEX IF NOT EXISTS ix_m2_8_latest_outcome ON msbf_m2.application_servicing_execution_latest(module1_run_id,scenario_code,servicing_execution_outcome_code);

CREATE OR REPLACE FUNCTION msbf_ctl.m2_8_assert_configuration(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v record;
BEGIN
 SELECT * INTO v FROM msbf_ctl.m2_8_policy_profile WHERE module1_run_id=p_run_id;
 IF v.module1_run_id IS NULL OR v.policy_status<>'APPROVED' OR v.policy_code<>'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1'
 OR v.methodology_version<>'M2_8_METHOD_V1' OR v.contract_code<>'M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION'
 OR v.schema_version<>'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1' OR v.source_registry_name<>'msbf_ctl.m2_7_operational_activation_contract_registry'
 OR v.source_latest_name<>'msbf_m2.application_operational_activation_latest' OR v.source_contract_code<>'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
 OR v.source_schema_version<>'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1' OR v.source_methodology_version<>'M2_7_METHOD_V1'
 OR v.source_policy_code<>'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1' OR v.source_acceptance_gate_id<>'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
 OR v.source_combined_set_hash<>'c8e3a472afd2a16b1183677324e9db98'
 OR NOT v.synthetic_data_only_flag OR NOT v.simulated_servicing_execution_only_flag
 OR NOT v.preserve_m2_7_history_flag OR NOT v.no_real_funds_movement_flag
 OR NOT v.no_bank_account_data_flag OR NOT v.no_ach_or_network_transmission_flag
 OR NOT v.no_external_processor_call_flag OR NOT v.no_real_merchant_contact_flag
 OR NOT v.no_write_off_or_collection_execution_flag OR NOT v.no_external_notice_generation_flag
 OR NOT v.no_production_adverse_action_flag
 OR v.configuration_hash IS DISTINCT FROM msbf_ctl.m2_8_hash_jsonb(v.configuration_payload)
 OR v.row_hash IS DISTINCT FROM msbf_ctl.m2_8_hash_jsonb(to_jsonb(v)-'row_hash'-'created_at'-'updated_at')
 THEN RAISE EXCEPTION 'M2.8 configuration assertion failed for run_id %.',p_run_id; END IF;
END;$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_8_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_status text;
BEGIN
 PERFORM msbf_ctl.m2_8_assert_configuration(p_run_id);
 SELECT run_status INTO v_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
 IF v_status<>'M2_7_ACCEPTED' THEN RAISE EXCEPTION 'M2.8 generation requires M2_7_ACCEPTED; observed %.',v_status; END IF;
 IF EXISTS(
  SELECT 1 FROM msbf_m2.servicing_execution_source_snapshot WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.application_servicing_execution_snapshot WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.synthetic_payment_processing_event WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.account_lifecycle_transition_snapshot WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.servicing_execution_portfolio_summary WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.application_servicing_execution_latest WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.application_servicing_execution_archive WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_ctl.m2_8_servicing_execution_contract_registry WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_ctl.run_evidence WHERE run_id=p_run_id AND evidence_code LIKE 'M2_8_%' UNION ALL
  SELECT 1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL')
 THEN RAISE EXCEPTION 'M2.8 generation requires empty M2.8 targets for run_id %.',p_run_id; END IF;
END;$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_8_assert_validation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE r text;c text;
BEGIN
 PERFORM msbf_ctl.m2_8_assert_configuration(p_run_id);
 SELECT run_status INTO r FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
 SELECT contract_status INTO c FROM msbf_ctl.m2_8_servicing_execution_contract_registry WHERE module1_run_id=p_run_id;
 IF NOT ((r='M2_8_GENERATED' AND c='GENERATED') OR (r='M2_8_VALIDATED' AND c='VALIDATED'))
 THEN RAISE EXCEPTION 'M2.8 validation requires aligned state; run %, contract %.',r,c; END IF;
END;$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_8_assert_acceptance_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE r text;c text;p bigint;n bigint;
BEGIN
 PERFORM msbf_ctl.m2_8_assert_configuration(p_run_id);
 SELECT run_status INTO r FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
 SELECT contract_status INTO c FROM msbf_ctl.m2_8_servicing_execution_contract_registry WHERE module1_run_id=p_run_id;
 SELECT count(*) FILTER(WHERE evidence_code LIKE 'M2_8_POS_%' AND status='PASS'),
        count(*) FILTER(WHERE evidence_code LIKE 'M2_8_NEG_%' AND status='PASS') INTO p,n
 FROM msbf_ctl.run_evidence WHERE run_id=p_run_id;
 IF r<>'M2_8_VALIDATED' OR c<>'VALIDATED' OR p<>120 OR n<>20
 THEN RAISE EXCEPTION 'M2.8 acceptance not ready: run %, contract %, positive %, negative %.',r,c,p,n; END IF;
END;$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_8_assert_no_real_payment_payload(p_payload jsonb)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE k text;
BEGIN
 SELECT key INTO k FROM jsonb_object_keys(coalesce(p_payload,'{}'::jsonb)) key
 WHERE lower(key) IN ('real_bank_account_number','bank_account_number','routing_number','settlement_account_number','ach_trace_number','payment_network_confirmation','processor_authorization_code','real_funds_moved','real_payment_instruction','merchant_contact_executed','write_off_posted','collection_agency_referral','legal_action_executed','external_notice_payload','production_adverse_action_notice') LIMIT 1;
 IF k IS NOT NULL THEN RAISE EXCEPTION 'M2.8 rejected prohibited payment payload key %.',k; END IF;
END;$function$;

/* ============================================================================
Section 5 — Gate and governed seed records
============================================================================ */
INSERT INTO msbf_ref.acceptance_gate_catalog(gate_id,gate_name,module_code,severity,active_flag,description)
VALUES('M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL','M2.8 Servicing Execution Simulation, Payment Processing & Account Lifecycle Control','M2.8','BLOCKING',TRUE,'Accepts deterministic synthetic servicing execution, payment events, and lifecycle evidence while prohibiting production execution.')
ON CONFLICT(gate_id) DO UPDATE SET gate_name=EXCLUDED.gate_name,module_code=EXCLUDED.module_code,severity=EXCLUDED.severity,active_flag=EXCLUDED.active_flag,description=EXCLUDED.description;

WITH seed AS(
 SELECT registry.module1_run_id::bigint module1_run_id,'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1'::text policy_code,1::integer policy_version,'APPROVED'::text policy_status,
 'M2_8_METHOD_V1'::text methodology_version,'M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION'::text contract_code,1::integer contract_version,'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1'::text schema_version,
 'msbf_ctl.m2_7_operational_activation_contract_registry'::text source_registry_name,'msbf_m2.application_operational_activation_latest'::text source_latest_name,'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'::text source_contract_code,
 1::integer source_contract_version,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'::text source_schema_version,'M2_7_METHOD_V1'::text source_methodology_version,
 'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1'::text source_policy_code,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'::text source_acceptance_gate_id,'c8e3a472afd2a16b1183677324e9db98'::text source_combined_set_hash,
 TRUE synthetic_data_only_flag,TRUE simulated_servicing_execution_only_flag,TRUE preserve_m2_7_history_flag,
 TRUE no_real_funds_movement_flag,TRUE no_bank_account_data_flag,TRUE no_ach_or_network_transmission_flag,
 TRUE no_external_processor_call_flag,TRUE no_real_merchant_contact_flag,TRUE no_write_off_or_collection_execution_flag,
 TRUE no_external_notice_generation_flag,TRUE no_production_adverse_action_flag,
 7 servicing_cycle_days,4 synthetic_return_event_sequence,5 synthetic_retry_event_sequence,2.000000::numeric(9,6) retry_catchup_multiplier,
 .750000::numeric(9,6) default_temporary_payment_factor,14 default_setup_duration_days,7 default_reassessment_interval_days,
 1::bigint expected_policy_rows,7::bigint expected_outcome_rows,7::bigint expected_action_rows,7::bigint expected_lifecycle_state_rows,32::bigint expected_reason_rows,
 59::bigint expected_source_rows,59::bigint expected_execution_rows,7::bigint expected_payment_event_rows,67::bigint expected_lifecycle_transition_rows,
 2::bigint expected_portfolio_summary_rows,59::bigint expected_latest_rows,59::bigint expected_archive_rows,15::bigint expected_comparison_rows,
 1::bigint expected_registry_rows,367::bigint expected_canonical_entities,120 expected_positive_controls,20 expected_negative_controls,
 24 expected_generation_evidence_rows,24 expected_detail_result_sets,'{"contract":"M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION","default_reassessment_interval_days":7,"default_setup_duration_days":14,"default_temporary_payment_factor":0.75,"expected":{"action_rows":7,"active_ending_exposure_amount":"323.79","archive_rows":59,"canonical_entities":367,"checkpoint_transition_rows":1,"comparison_rows":15,"detail_result_sets":24,"execution_rows":59,"generation_evidence_rows":24,"initial_transition_rows":59,"latest_rows":59,"lifecycle_state_rows":7,"lifecycle_transition_rows":67,"negative_controls":20,"no_processing_required_rows":57,"outcome_rows":7,"payment_event_rows":7,"payment_transition_rows":7,"policy_rows":1,"portfolio_ending_exposure_amount":"785.48","portfolio_summary_rows":2,"positive_controls":120,"processed_payment_amount":"194.25","processing_authorized_amount":"518.04","reason_rows":32,"registry_rows":1,"retry_event_rows":1,"retry_payment_amount":"27.75","returned_event_rows":1,"returned_payment_amount":"27.75","review_hold_amount":"461.69","review_hold_rows":1,"scheduled_payment_amount":"194.25","settled_event_rows":5,"source_rows":59,"standard_daily_payment_amount":"37.00","temporary_daily_payment_amount":"27.75","temporary_processing_rows":1},"gate":"M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL","methodology":"M2_8_METHOD_V1","no_ach_or_network_transmission":true,"no_bank_account_data":true,"no_external_notice_generation":true,"no_external_processor_call":true,"no_production_adverse_action":true,"no_real_funds_movement":true,"no_real_merchant_contact":true,"no_write_off_or_collection_execution":true,"policy":"M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1","preserve_m2_7_history":true,"retry_catchup_multiplier":2.0,"run_code":"M1_V0_2_BASELINE_BUILD","run_version":1,"schema":"M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1","servicing_cycle_days":7,"simulated_servicing_execution_only":true,"source_archive":"msbf_m2.application_operational_activation_archive","source_contract":"M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION","source_gate":"M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP","source_hash":"c8e3a472afd2a16b1183677324e9db98","source_latest":"msbf_m2.application_operational_activation_latest","source_methodology":"M2_7_METHOD_V1","source_policy":"M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1","source_registry":"msbf_ctl.m2_7_operational_activation_contract_registry","source_schema":"M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1","synthetic_data_only":true,"synthetic_retry_event_sequence":5,"synthetic_return_event_sequence":4}'::jsonb configuration_payload,
 msbf_ctl.m2_8_hash_jsonb('{"contract":"M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION","default_reassessment_interval_days":7,"default_setup_duration_days":14,"default_temporary_payment_factor":0.75,"expected":{"action_rows":7,"active_ending_exposure_amount":"323.79","archive_rows":59,"canonical_entities":367,"checkpoint_transition_rows":1,"comparison_rows":15,"detail_result_sets":24,"execution_rows":59,"generation_evidence_rows":24,"initial_transition_rows":59,"latest_rows":59,"lifecycle_state_rows":7,"lifecycle_transition_rows":67,"negative_controls":20,"no_processing_required_rows":57,"outcome_rows":7,"payment_event_rows":7,"payment_transition_rows":7,"policy_rows":1,"portfolio_ending_exposure_amount":"785.48","portfolio_summary_rows":2,"positive_controls":120,"processed_payment_amount":"194.25","processing_authorized_amount":"518.04","reason_rows":32,"registry_rows":1,"retry_event_rows":1,"retry_payment_amount":"27.75","returned_event_rows":1,"returned_payment_amount":"27.75","review_hold_amount":"461.69","review_hold_rows":1,"scheduled_payment_amount":"194.25","settled_event_rows":5,"source_rows":59,"standard_daily_payment_amount":"37.00","temporary_daily_payment_amount":"27.75","temporary_processing_rows":1},"gate":"M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL","methodology":"M2_8_METHOD_V1","no_ach_or_network_transmission":true,"no_bank_account_data":true,"no_external_notice_generation":true,"no_external_processor_call":true,"no_production_adverse_action":true,"no_real_funds_movement":true,"no_real_merchant_contact":true,"no_write_off_or_collection_execution":true,"policy":"M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1","preserve_m2_7_history":true,"retry_catchup_multiplier":2.0,"run_code":"M1_V0_2_BASELINE_BUILD","run_version":1,"schema":"M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1","servicing_cycle_days":7,"simulated_servicing_execution_only":true,"source_archive":"msbf_m2.application_operational_activation_archive","source_contract":"M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION","source_gate":"M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP","source_hash":"c8e3a472afd2a16b1183677324e9db98","source_latest":"msbf_m2.application_operational_activation_latest","source_methodology":"M2_7_METHOD_V1","source_policy":"M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1","source_registry":"msbf_ctl.m2_7_operational_activation_contract_registry","source_schema":"M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1","synthetic_data_only":true,"synthetic_retry_event_sequence":5,"synthetic_return_event_sequence":4}'::jsonb) configuration_hash
 FROM msbf_ctl.m2_7_operational_activation_contract_registry registry JOIN msbf_ctl.run_registry run ON run.run_id=registry.module1_run_id
 WHERE run.run_code='M1_V0_2_BASELINE_BUILD' AND run.run_version=1 AND run.run_status='M2_7_ACCEPTED'
 AND registry.contract_status='ACCEPTED' AND registry.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND registry.contract_version=1
 AND registry.schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1' AND registry.combined_set_hash='c8e3a472afd2a16b1183677324e9db98'),
hashed AS(SELECT seed.*,msbf_ctl.m2_8_hash_jsonb(to_jsonb(seed)) row_hash FROM seed)
INSERT INTO msbf_ctl.m2_8_policy_profile(
 module1_run_id,policy_code,policy_version,policy_status,methodology_version,contract_code,contract_version,schema_version,
 source_registry_name,source_latest_name,source_contract_code,source_contract_version,source_schema_version,source_methodology_version,
 source_policy_code,source_acceptance_gate_id,source_combined_set_hash,synthetic_data_only_flag,simulated_servicing_execution_only_flag,
 preserve_m2_7_history_flag,no_real_funds_movement_flag,no_bank_account_data_flag,no_ach_or_network_transmission_flag,
 no_external_processor_call_flag,no_real_merchant_contact_flag,no_write_off_or_collection_execution_flag,no_external_notice_generation_flag,
 no_production_adverse_action_flag,servicing_cycle_days,synthetic_return_event_sequence,synthetic_retry_event_sequence,retry_catchup_multiplier,
 default_temporary_payment_factor,default_setup_duration_days,default_reassessment_interval_days,expected_policy_rows,expected_outcome_rows,
 expected_action_rows,expected_lifecycle_state_rows,expected_reason_rows,expected_source_rows,expected_execution_rows,expected_payment_event_rows,
 expected_lifecycle_transition_rows,expected_portfolio_summary_rows,expected_latest_rows,expected_archive_rows,expected_comparison_rows,
 expected_registry_rows,expected_canonical_entities,expected_positive_controls,expected_negative_controls,expected_generation_evidence_rows,
 expected_detail_result_sets,configuration_payload,configuration_hash,row_hash)
SELECT module1_run_id,policy_code,policy_version,policy_status,methodology_version,contract_code,contract_version,schema_version,source_registry_name,source_latest_name,source_contract_code,source_contract_version,source_schema_version,source_methodology_version,source_policy_code,source_acceptance_gate_id,source_combined_set_hash,synthetic_data_only_flag,simulated_servicing_execution_only_flag,preserve_m2_7_history_flag,no_real_funds_movement_flag,no_bank_account_data_flag,no_ach_or_network_transmission_flag,no_external_processor_call_flag,no_real_merchant_contact_flag,no_write_off_or_collection_execution_flag,no_external_notice_generation_flag,no_production_adverse_action_flag,servicing_cycle_days,synthetic_return_event_sequence,synthetic_retry_event_sequence,retry_catchup_multiplier,default_temporary_payment_factor,default_setup_duration_days,default_reassessment_interval_days,expected_policy_rows,expected_outcome_rows,expected_action_rows,expected_lifecycle_state_rows,expected_reason_rows,expected_source_rows,expected_execution_rows,expected_payment_event_rows,expected_lifecycle_transition_rows,expected_portfolio_summary_rows,expected_latest_rows,expected_archive_rows,expected_comparison_rows,expected_registry_rows,expected_canonical_entities,expected_positive_controls,expected_negative_controls,expected_generation_evidence_rows,expected_detail_result_sets,configuration_payload,configuration_hash,row_hash FROM hashed ON CONFLICT(module1_run_id) DO NOTHING;

WITH r AS(SELECT module1_run_id FROM msbf_ctl.m2_8_policy_profile WHERE policy_code='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1'),
seed AS(SELECT r.module1_run_id,v.*,FALSE real_funds_moved_flag,FALSE bank_account_data_present_flag,FALSE ach_or_network_transmitted_flag,FALSE external_processor_called_flag,FALSE merchant_contact_executed_flag,FALSE write_off_or_collection_flag,FALSE external_notice_generated_flag,FALSE production_adverse_action_flag,'APPROVED'::text definition_status FROM r CROSS JOIN(VALUES ('NO_SERVICING_EXECUTION_REQUIRED', 0, FALSE, FALSE, TRUE, 'Accepted M2.7 source requires no servicing execution.'),
        ('SIMULATED_STANDARD_PAYMENT_PROCESSING_ACTIVE', 1, TRUE, FALSE, FALSE, 'Synthetic standard payment-processing cycle is active.'),
        ('SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 2, TRUE, FALSE, FALSE, 'Synthetic temporary-adjustment payment-processing cycle is active.'),
        ('SIMULATED_RESTRUCTURE_PAYMENT_PROCESSING_ACTIVE', 3, TRUE, FALSE, FALSE, 'Synthetic restructure payment-processing cycle is active.'),
        ('SIMULATED_RECOVERY_PAYMENT_PROCESSING_ACTIVE', 4, TRUE, FALSE, FALSE, 'Synthetic recovery payment-processing cycle is active.'),
        ('SIMULATED_CHARGE_OFF_LIFECYCLE_CONTROL', 5, TRUE, FALSE, FALSE, 'Synthetic charge-off lifecycle control is active without posting.'),
        ('SERVICING_EXECUTION_REVIEW_HOLD', 9, FALSE, TRUE, FALSE, 'Servicing execution remains on governed review hold.')) v(servicing_execution_outcome_code,servicing_execution_outcome_rank,processing_authorized_flag,processing_review_required_flag,no_processing_required_flag,description)),
h AS(SELECT seed.*,msbf_ctl.m2_8_hash_jsonb(to_jsonb(seed)) row_hash FROM seed)
INSERT INTO msbf_m2.servicing_execution_outcome_definition(module1_run_id,servicing_execution_outcome_code,servicing_execution_outcome_rank,processing_authorized_flag,processing_review_required_flag,no_processing_required_flag,description,real_funds_moved_flag,bank_account_data_present_flag,ach_or_network_transmitted_flag,external_processor_called_flag,merchant_contact_executed_flag,write_off_or_collection_flag,external_notice_generated_flag,production_adverse_action_flag,definition_status,row_hash)
SELECT module1_run_id,servicing_execution_outcome_code,servicing_execution_outcome_rank,processing_authorized_flag,processing_review_required_flag,no_processing_required_flag,description,real_funds_moved_flag,bank_account_data_present_flag,ach_or_network_transmitted_flag,external_processor_called_flag,merchant_contact_executed_flag,write_off_or_collection_flag,external_notice_generated_flag,production_adverse_action_flag,definition_status,row_hash FROM h ON CONFLICT DO NOTHING;

WITH r AS(SELECT module1_run_id FROM msbf_ctl.m2_8_policy_profile WHERE policy_code='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1'),
seed AS(SELECT r.module1_run_id,v.*,FALSE real_funds_moved_flag,FALSE bank_account_data_present_flag,FALSE ach_or_network_transmitted_flag,FALSE external_processor_called_flag,FALSE merchant_contact_executed_flag,FALSE write_off_or_collection_flag,FALSE external_notice_generated_flag,FALSE production_adverse_action_flag,'APPROVED'::text definition_status FROM r CROSS JOIN(VALUES ('NO_PAYMENT_PROCESSING', 0, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, 'No synthetic payment processing is required.'),
        ('EXECUTE_STANDARD_SYNTHETIC_PAYMENT_CYCLE', 1, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, 'Execute a synthetic standard payment cycle.'),
        ('EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 2, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, 'Execute a synthetic temporary-adjustment payment cycle.'),
        ('EXECUTE_RESTRUCTURE_SYNTHETIC_PAYMENT_CYCLE', 3, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, 'Execute a synthetic restructure payment cycle.'),
        ('EXECUTE_RECOVERY_SYNTHETIC_PAYMENT_CYCLE', 4, TRUE, FALSE, FALSE, TRUE, FALSE, FALSE, 'Execute a synthetic recovery payment cycle.'),
        ('EXECUTE_CHARGE_OFF_LIFECYCLE_SIMULATION', 5, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, 'Execute synthetic charge-off lifecycle simulation without posting.'),
        ('HOLD_FOR_SERVICING_REVIEW', 9, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, 'Hold servicing execution for governed review.')) v(servicing_execution_action_code,servicing_execution_action_rank,payment_cycle_flag,temporary_cycle_flag,restructure_cycle_flag,recovery_cycle_flag,charge_off_control_flag,review_hold_flag,description)),
h AS(SELECT seed.*,msbf_ctl.m2_8_hash_jsonb(to_jsonb(seed)) row_hash FROM seed)
INSERT INTO msbf_m2.servicing_execution_action_definition(module1_run_id,servicing_execution_action_code,servicing_execution_action_rank,payment_cycle_flag,temporary_cycle_flag,restructure_cycle_flag,recovery_cycle_flag,charge_off_control_flag,review_hold_flag,description,real_funds_moved_flag,bank_account_data_present_flag,ach_or_network_transmitted_flag,external_processor_called_flag,merchant_contact_executed_flag,write_off_or_collection_flag,external_notice_generated_flag,production_adverse_action_flag,definition_status,row_hash)
SELECT module1_run_id,servicing_execution_action_code,servicing_execution_action_rank,payment_cycle_flag,temporary_cycle_flag,restructure_cycle_flag,recovery_cycle_flag,charge_off_control_flag,review_hold_flag,description,real_funds_moved_flag,bank_account_data_present_flag,ach_or_network_transmitted_flag,external_processor_called_flag,merchant_contact_executed_flag,write_off_or_collection_flag,external_notice_generated_flag,production_adverse_action_flag,definition_status,row_hash FROM h ON CONFLICT DO NOTHING;

WITH r AS(SELECT module1_run_id FROM msbf_ctl.m2_8_policy_profile WHERE policy_code='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1'),
seed AS(SELECT r.module1_run_id,v.*,FALSE real_funds_moved_flag,FALSE production_account_state_flag,'APPROVED'::text definition_status FROM r CROSS JOIN(VALUES ('NOT_STARTED', 0, FALSE, FALSE, FALSE, 'Synthetic servicing lifecycle has not started.'),
        ('CLOSED_NO_PROCESSING_REQUIRED', 1, FALSE, FALSE, TRUE, 'No payment processing is required and the synthetic lifecycle is closed.'),
        ('ACTIVE_PAYMENT_PLAN', 2, TRUE, FALSE, FALSE, 'Synthetic payment plan is active.'),
        ('PAYMENT_RETURNED_PENDING_RETRY', 3, TRUE, TRUE, FALSE, 'Synthetic payment returned and awaits retry.'),
        ('ACTIVE_AFTER_RETRY', 4, TRUE, FALSE, FALSE, 'Synthetic payment plan resumed after retry.'),
        ('REASSESSMENT_DUE', 5, TRUE, FALSE, FALSE, 'Synthetic plan reached its governed reassessment checkpoint.'),
        ('SERVICING_REVIEW_HOLD', 9, FALSE, TRUE, FALSE, 'Synthetic servicing execution is held for governed review.')) v(lifecycle_state_code,lifecycle_state_rank,active_flag,exception_flag,closed_flag,description)),
h AS(SELECT seed.*,msbf_ctl.m2_8_hash_jsonb(to_jsonb(seed)) row_hash FROM seed)
INSERT INTO msbf_m2.account_lifecycle_state_definition(module1_run_id,lifecycle_state_code,lifecycle_state_rank,active_flag,exception_flag,closed_flag,description,real_funds_moved_flag,production_account_state_flag,definition_status,row_hash)
SELECT module1_run_id,lifecycle_state_code,lifecycle_state_rank,active_flag,exception_flag,closed_flag,description,real_funds_moved_flag,production_account_state_flag,definition_status,row_hash FROM h ON CONFLICT DO NOTHING;

WITH r AS(SELECT module1_run_id FROM msbf_ctl.m2_8_policy_profile WHERE policy_code='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1'),
seed AS(SELECT r.module1_run_id,v.*,FALSE real_execution_reason_flag,FALSE production_adverse_action_flag,'APPROVED'::text definition_status FROM r CROSS JOIN(VALUES ('M2_8_REASON_SOURCE_NO_PROCESSING', 'NO_SERVICING_EXECUTION_REQUIRED', 'NO_PAYMENT_PROCESSING', 'Accepted M2.7 source requires no payment processing.'),
        ('M2_8_REASON_SOURCE_STANDARD_PROCESSING', 'SIMULATED_STANDARD_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_STANDARD_SYNTHETIC_PAYMENT_CYCLE', 'Accepted M2.7 source maps to standard synthetic processing.'),
        ('M2_8_REASON_SOURCE_TEMPORARY_PROCESSING', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Accepted M2.7 source maps to temporary synthetic processing.'),
        ('M2_8_REASON_SOURCE_RESTRUCTURE_PROCESSING', 'SIMULATED_RESTRUCTURE_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_RESTRUCTURE_SYNTHETIC_PAYMENT_CYCLE', 'Accepted M2.7 source maps to restructure synthetic processing.'),
        ('M2_8_REASON_SOURCE_RECOVERY_PROCESSING', 'SIMULATED_RECOVERY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_RECOVERY_SYNTHETIC_PAYMENT_CYCLE', 'Accepted M2.7 source maps to recovery synthetic processing.'),
        ('M2_8_REASON_SOURCE_CHARGE_OFF_CONTROL', 'SIMULATED_CHARGE_OFF_LIFECYCLE_CONTROL', 'EXECUTE_CHARGE_OFF_LIFECYCLE_SIMULATION', 'Accepted M2.7 source maps to charge-off lifecycle simulation.'),
        ('M2_8_REASON_SOURCE_REVIEW_HOLD', 'SERVICING_EXECUTION_REVIEW_HOLD', 'HOLD_FOR_SERVICING_REVIEW', 'Accepted M2.7 source maps to servicing review hold.'),
        ('M2_8_REASON_SOURCE_UNRESOLVED', 'SERVICING_EXECUTION_REVIEW_HOLD', 'HOLD_FOR_SERVICING_REVIEW', 'Accepted source did not resolve to a synthetic execution posture.'),
        ('M2_8_REASON_SETUP_AUTHORIZED', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'M2.7 authorized a synthetic setup blueprint.'),
        ('M2_8_REASON_SETUP_NOT_AUTHORIZED', 'NO_SERVICING_EXECUTION_REQUIRED', 'NO_PAYMENT_PROCESSING', 'M2.7 did not authorize a synthetic setup blueprint.'),
        ('M2_8_REASON_PAYMENT_FACTOR_PRESENT', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Accepted temporary payment factor is present.'),
        ('M2_8_REASON_PAYMENT_FACTOR_DEFAULTED', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Governed default temporary payment factor is applied.'),
        ('M2_8_REASON_SETUP_DURATION_PRESENT', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Accepted setup duration is present.'),
        ('M2_8_REASON_SETUP_DURATION_DEFAULTED', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Governed default setup duration is applied.'),
        ('M2_8_REASON_REASSESSMENT_PRESENT', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Accepted reassessment interval is present.'),
        ('M2_8_REASON_REASSESSMENT_DEFAULTED', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Governed default reassessment interval is applied.'),
        ('M2_8_REASON_PAYMENT_SCHEDULED', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Synthetic payment is scheduled.'),
        ('M2_8_REASON_PAYMENT_SETTLED', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Synthetic payment is settled.'),
        ('M2_8_REASON_PAYMENT_RETURNED', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Synthetic payment is returned.'),
        ('M2_8_REASON_RETRY_INITIATED', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Synthetic retry is initiated.'),
        ('M2_8_REASON_RETRY_SETTLED', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Synthetic retry is settled.'),
        ('M2_8_REASON_LIFECYCLE_OPENED', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Synthetic lifecycle is opened.'),
        ('M2_8_REASON_LIFECYCLE_CLOSED_NO_PROCESSING', 'NO_SERVICING_EXECUTION_REQUIRED', 'NO_PAYMENT_PROCESSING', 'Synthetic lifecycle closes without processing.'),
        ('M2_8_REASON_LIFECYCLE_REVIEW_HOLD', 'SERVICING_EXECUTION_REVIEW_HOLD', 'HOLD_FOR_SERVICING_REVIEW', 'Synthetic lifecycle enters review hold.'),
        ('M2_8_REASON_REASSESSMENT_DUE', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Synthetic lifecycle reaches reassessment.'),
        ('M2_8_REASON_SOURCE_HASH_PRESENT', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Accepted M2.7 source row hash is present.'),
        ('M2_8_REASON_SOURCE_CONTRACT_ACCEPTED', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'M2.7 source contract is accepted.'),
        ('M2_8_REASON_HISTORY_PRESERVED', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'Accepted M2.7 history is preserved.'),
        ('M2_8_REASON_NO_BANK_DATA', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'No bank-account data is present.'),
        ('M2_8_REASON_NO_NETWORK_TRANSMISSION', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'No ACH or payment-network transmission occurs.'),
        ('M2_8_REASON_NO_REAL_FUNDS_MOVEMENT', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'No real funds movement occurs.'),
        ('M2_8_REASON_SYNTHETIC_ONLY', 'SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE', 'EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE', 'All payment and lifecycle outputs are synthetic.')) v(servicing_execution_reason_code,mapped_outcome_code,mapped_action_code,description)),
h AS(SELECT seed.*,msbf_ctl.m2_8_hash_jsonb(to_jsonb(seed)) row_hash FROM seed)
INSERT INTO msbf_m2.servicing_execution_reason_definition(module1_run_id,servicing_execution_reason_code,mapped_outcome_code,mapped_action_code,description,real_execution_reason_flag,production_adverse_action_flag,definition_status,row_hash)
SELECT module1_run_id,servicing_execution_reason_code,mapped_outcome_code,mapped_action_code,description,real_execution_reason_flag,production_adverse_action_flag,definition_status,row_hash FROM h ON CONFLICT DO NOTHING;

/* ============================================================================
Section 6 — Consumption and canonical views
============================================================================ */
CREATE OR REPLACE VIEW msbf_m2.v_m2_8_servicing_execution_latest AS SELECT latest.* FROM msbf_m2.application_servicing_execution_latest latest;
CREATE OR REPLACE VIEW msbf_m2.v_m2_8_matched_scenario_comparison AS
WITH p AS(
 SELECT module1_run_id,merchant_application_id,
 max(servicing_execution_outcome_code) FILTER(WHERE scenario_code='BASELINE') baseline_servicing_execution_outcome_code,
 max(servicing_execution_outcome_code) FILTER(WHERE scenario_code='RECESSION_ENERGY') stress_servicing_execution_outcome_code,
 max(servicing_execution_priority_rank) FILTER(WHERE scenario_code='BASELINE') baseline_servicing_execution_priority_rank,
 max(servicing_execution_priority_rank) FILTER(WHERE scenario_code='RECESSION_ENERGY') stress_servicing_execution_priority_rank,
 bool_or(processing_authorized_flag) FILTER(WHERE scenario_code='BASELINE') baseline_processing_authorized_flag,
 bool_or(processing_authorized_flag) FILTER(WHERE scenario_code='RECESSION_ENERGY') stress_processing_authorized_flag,
 max(ending_simulated_exposure_amount) FILTER(WHERE scenario_code='BASELINE') baseline_ending_exposure_amount,
 max(ending_simulated_exposure_amount) FILTER(WHERE scenario_code='RECESSION_ENERGY') stress_ending_exposure_amount,
 count(*) FILTER(WHERE scenario_code='BASELINE') baseline_rows,count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') stress_rows
 FROM msbf_m2.application_servicing_execution_latest GROUP BY module1_run_id,merchant_application_id)
SELECT p.*,
 (stress_processing_authorized_flag AND NOT baseline_processing_authorized_flag) stress_processing_permission_improvement_flag,
 (stress_servicing_execution_priority_rank<baseline_servicing_execution_priority_rank) stress_priority_improvement_flag,
 (stress_ending_exposure_amount<baseline_ending_exposure_amount) stress_exposure_improvement_flag
FROM p WHERE baseline_rows=1 AND stress_rows=1;
CREATE OR REPLACE VIEW msbf_m2.v_m2_8_payment_event_ledger AS SELECT * FROM msbf_m2.synthetic_payment_processing_event;
CREATE OR REPLACE VIEW msbf_m2.v_m2_8_power_bi_servicing_execution AS
SELECT module1_run_id,scenario_code,merchant_application_id,synthetic_account_id,synthetic_advance_id,
 source_operational_setup_outcome_code,servicing_execution_outcome_code,servicing_execution_action_code,
 servicing_execution_priority_rank,servicing_execution_queue_code,processing_authorized_flag,
 processing_review_required_flag,no_processing_required_flag,final_lifecycle_state_code,payment_event_count,
 settled_event_count,returned_event_count,retry_event_count,scheduled_payment_amount,processed_payment_amount,
 returned_payment_amount,retry_payment_amount,ending_simulated_exposure_amount
FROM msbf_m2.application_servicing_execution_latest;
CREATE OR REPLACE VIEW msbf_m2.v_m2_8_lineage AS
SELECT module1_run_id,scenario_id,scenario_code,merchant_application_id,synthetic_account_id,synthetic_advance_id,
 contract_code,contract_version,schema_version,source_contract_row_hash,source_snapshot_row_hash,
 execution_snapshot_row_hash,contract_row_hash FROM msbf_m2.application_servicing_execution_latest;
CREATE OR REPLACE VIEW msbf_m2.v_m2_8_canonical_entity AS
SELECT module1_run_id,'POLICY'::text entity_type,policy_code||'|v'||policy_version entity_key,row_hash FROM msbf_ctl.m2_8_policy_profile
UNION ALL SELECT module1_run_id,'OUTCOME_DEFINITION',servicing_execution_outcome_code,row_hash FROM msbf_m2.servicing_execution_outcome_definition
UNION ALL SELECT module1_run_id,'ACTION_DEFINITION',servicing_execution_action_code,row_hash FROM msbf_m2.servicing_execution_action_definition
UNION ALL SELECT module1_run_id,'LIFECYCLE_STATE_DEFINITION',lifecycle_state_code,row_hash FROM msbf_m2.account_lifecycle_state_definition
UNION ALL SELECT module1_run_id,'REASON_DEFINITION',servicing_execution_reason_code,row_hash FROM msbf_m2.servicing_execution_reason_definition
UNION ALL SELECT module1_run_id,'SOURCE',scenario_id::text||'|'||merchant_application_id,row_hash FROM msbf_m2.servicing_execution_source_snapshot
UNION ALL SELECT module1_run_id,'EXECUTION',scenario_id::text||'|'||merchant_application_id,row_hash FROM msbf_m2.application_servicing_execution_snapshot
UNION ALL SELECT module1_run_id,'PAYMENT_EVENT',scenario_id::text||'|'||merchant_application_id||'|'||event_sequence,row_hash FROM msbf_m2.synthetic_payment_processing_event
UNION ALL SELECT module1_run_id,'LIFECYCLE_TRANSITION',scenario_id::text||'|'||merchant_application_id||'|'||transition_sequence,row_hash FROM msbf_m2.account_lifecycle_transition_snapshot
UNION ALL SELECT module1_run_id,'PORTFOLIO_SUMMARY',scenario_code,row_hash FROM msbf_m2.servicing_execution_portfolio_summary
UNION ALL SELECT module1_run_id,'LATEST',scenario_id::text||'|'||merchant_application_id,contract_row_hash FROM msbf_m2.application_servicing_execution_latest
UNION ALL SELECT module1_run_id,'ARCHIVE',scenario_id::text||'|'||merchant_application_id,archive_row_hash FROM msbf_m2.application_servicing_execution_archive
UNION ALL SELECT module1_run_id,'REGISTRY',contract_code||'|v'||contract_version,row_hash FROM msbf_ctl.m2_8_servicing_execution_contract_registry;
CREATE OR REPLACE VIEW msbf_m2.v_m2_8_canonical_hash AS
SELECT module1_run_id,count(*)::bigint canonical_entities,
 md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'|' ORDER BY entity_type,entity_key)) combined_set_hash
FROM msbf_m2.v_m2_8_canonical_entity GROUP BY module1_run_id;

/* ============================================================================
Section 7 — Schema/policy checkpoint
============================================================================ */
DO $guard$
DECLARE r bigint;g bigint;o bigint;a bigint;s bigint;x bigint;
BEGIN
 SELECT module1_run_id INTO r FROM msbf_ctl.m2_8_policy_profile WHERE policy_code='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1';
 PERFORM msbf_ctl.m2_8_assert_configuration(r);
 SELECT count(*) INTO g FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND active_flag;
 SELECT count(*) INTO o FROM msbf_m2.servicing_execution_outcome_definition WHERE module1_run_id=r AND definition_status='APPROVED';
 SELECT count(*) INTO a FROM msbf_m2.servicing_execution_action_definition WHERE module1_run_id=r AND definition_status='APPROVED';
 SELECT count(*) INTO s FROM msbf_m2.account_lifecycle_state_definition WHERE module1_run_id=r AND definition_status='APPROVED';
 SELECT count(*) INTO x FROM msbf_m2.servicing_execution_reason_definition WHERE module1_run_id=r AND definition_status='APPROVED';
 IF g<>1 OR o<>7 OR a<>7 OR s<>7 OR x<>32 THEN RAISE EXCEPTION 'M2.8 schema/policy extension failed: gate %, outcomes %, actions %, states %, reasons %.',g,o,a,s,x; END IF;
END;$guard$;
COMMIT;
SELECT p.module1_run_id,p.policy_code,p.policy_version,p.policy_status,p.methodology_version,p.contract_code,p.contract_version,p.schema_version,
 p.source_contract_code,p.source_schema_version,p.source_acceptance_gate_id,p.source_combined_set_hash,p.configuration_hash,
 (SELECT count(*) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND active_flag) acceptance_gate_catalog_rows,
 (SELECT count(*) FROM msbf_m2.servicing_execution_outcome_definition WHERE module1_run_id=p.module1_run_id) outcome_definition_rows,
 (SELECT count(*) FROM msbf_m2.servicing_execution_action_definition WHERE module1_run_id=p.module1_run_id) action_definition_rows,
 (SELECT count(*) FROM msbf_m2.account_lifecycle_state_definition WHERE module1_run_id=p.module1_run_id) lifecycle_state_definition_rows,
 (SELECT count(*) FROM msbf_m2.servicing_execution_reason_definition WHERE module1_run_id=p.module1_run_id) reason_definition_rows,
 CASE WHEN p.policy_status='APPROVED' AND p.synthetic_data_only_flag AND p.simulated_servicing_execution_only_flag
 AND p.preserve_m2_7_history_flag AND p.no_real_funds_movement_flag AND p.no_bank_account_data_flag
 AND p.no_ach_or_network_transmission_flag AND p.no_external_processor_call_flag AND p.no_real_merchant_contact_flag
 AND p.no_write_off_or_collection_execution_flag AND p.no_external_notice_generation_flag AND p.no_production_adverse_action_flag
 THEN 'PASS' ELSE 'FAIL' END schema_policy_status
FROM msbf_ctl.m2_8_policy_profile p WHERE p.policy_code='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1';
