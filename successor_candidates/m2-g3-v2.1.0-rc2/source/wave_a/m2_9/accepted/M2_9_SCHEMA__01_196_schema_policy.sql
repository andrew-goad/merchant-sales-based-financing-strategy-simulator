/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.9 — Payment Reconciliation, Exception Resolution
             & Account State Certification

Program     : 196_msbf_m2_9_schema_policy_reconciliation_certification_extension_v0_2.sql
Version     : v0.2

Purpose
-------
Create the governed M2.9 policy, payment-reconciliation outcome, exception-
resolution action, account-state certification, and reason dictionaries;
accepted M2.8 account, payment-event, and lifecycle-transition source
snapshots; event and account reconciliation, exception-case, certification,
portfolio, latest, archive, and registry structures; deterministic hash and
lifecycle assertions; archive immutability; and consumption, comparison,
Power BI, lineage, exception-ledger, and canonical views.

Stage boundary
--------------
M2.9 reconciles and certifies synthetic evidence only. It does not move real
funds, use bank-account or routing data, transmit ACH or payment-network
instructions, call an external processor, contact a merchant, post a write-
off, initiate collections or legal action, generate an external notice, or
create a production adverse-action event.

Required result
---------------
schema_policy_status = PASS.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='40min';
SET LOCAL jit=off;

/* ============================================================================
Section 1 — Deterministic hash utilities
============================================================================ */
CREATE OR REPLACE FUNCTION msbf_ctl.m2_9_hash_jsonb(p_payload jsonb)
RETURNS text LANGUAGE sql IMMUTABLE STRICT
AS $function$ SELECT md5(p_payload::text); $function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_9_registry_row_hash(p_payload jsonb)
RETURNS text LANGUAGE sql IMMUTABLE STRICT
AS $function$
 SELECT msbf_ctl.m2_9_hash_jsonb
 (
   p_payload-'registry_id'-'contract_status'-'generated_at'-'validated_at'-
   'accepted_at'-'row_hash'-'created_at'-'contract_set_hash'-'combined_set_hash'
 );
$function$;

/* ============================================================================
Section 2 — Policy and governed dictionaries
============================================================================ */
CREATE TABLE IF NOT EXISTS msbf_ctl.m2_9_policy_profile
(
 module1_run_id bigint PRIMARY KEY,
 policy_code text NOT NULL, policy_version integer NOT NULL, policy_status text NOT NULL,
 methodology_version text NOT NULL, contract_code text NOT NULL,
 contract_version integer NOT NULL, schema_version text NOT NULL,
 source_registry_name text NOT NULL, source_latest_name text NOT NULL,
 source_payment_name text NOT NULL, source_transition_name text NOT NULL,
 source_contract_code text NOT NULL, source_contract_version integer NOT NULL,
 source_schema_version text NOT NULL, source_methodology_version text NOT NULL,
 source_policy_code text NOT NULL, source_acceptance_gate_id text NOT NULL,
 source_combined_set_hash text NOT NULL,
 synthetic_data_only_flag boolean NOT NULL,
 reconciliation_certification_only_flag boolean NOT NULL,
 preserve_m2_8_history_flag boolean NOT NULL,
 no_real_funds_movement_flag boolean NOT NULL,
 no_bank_account_data_flag boolean NOT NULL,
 no_ach_or_network_transmission_flag boolean NOT NULL,
 no_external_processor_call_flag boolean NOT NULL,
 no_real_merchant_contact_flag boolean NOT NULL,
 no_write_off_or_collection_execution_flag boolean NOT NULL,
 no_external_notice_generation_flag boolean NOT NULL,
 no_production_adverse_action_flag boolean NOT NULL,
 reconciliation_tolerance_amount numeric(18,2) NOT NULL,
 exposure_tolerance_amount numeric(18,2) NOT NULL,
 maximum_exception_resolution_days integer NOT NULL,
 expected_policy_rows bigint NOT NULL,
 expected_reconciliation_outcome_rows bigint NOT NULL,
 expected_resolution_action_rows bigint NOT NULL,
 expected_certification_state_rows bigint NOT NULL,
 expected_reason_rows bigint NOT NULL,
 expected_account_source_rows bigint NOT NULL,
 expected_payment_source_rows bigint NOT NULL,
 expected_transition_source_rows bigint NOT NULL,
 expected_payment_reconciliation_rows bigint NOT NULL,
 expected_exception_case_rows bigint NOT NULL,
 expected_account_reconciliation_rows bigint NOT NULL,
 expected_state_certification_rows bigint NOT NULL,
 expected_portfolio_summary_rows bigint NOT NULL,
 expected_latest_rows bigint NOT NULL,
 expected_archive_rows bigint NOT NULL,
 expected_comparison_rows bigint NOT NULL,
 expected_registry_rows bigint NOT NULL,
 expected_canonical_entities bigint NOT NULL,
 expected_positive_controls integer NOT NULL,
 expected_negative_controls integer NOT NULL,
 expected_generation_evidence_rows integer NOT NULL,
 expected_detail_result_sets integer NOT NULL,
 configuration_payload jsonb NOT NULL, configuration_hash text NOT NULL,
 row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CONSTRAINT ck_m2_9_policy_identity CHECK
 (policy_code='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1' AND policy_version=1 AND methodology_version='M2_9_METHOD_V1'
  AND contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND contract_version=1 AND schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'),
 CONSTRAINT ck_m2_9_policy_status CHECK(policy_status IN ('APPROVED','RETIRED')),
 CONSTRAINT ck_m2_9_policy_boundaries CHECK
 (synthetic_data_only_flag AND reconciliation_certification_only_flag AND preserve_m2_8_history_flag
  AND no_real_funds_movement_flag AND no_bank_account_data_flag
  AND no_ach_or_network_transmission_flag AND no_external_processor_call_flag
  AND no_real_merchant_contact_flag AND no_write_off_or_collection_execution_flag
  AND no_external_notice_generation_flag AND no_production_adverse_action_flag
  AND reconciliation_tolerance_amount>=0 AND exposure_tolerance_amount>=0
  AND maximum_exception_resolution_days BETWEEN 0 AND 30),
 CONSTRAINT ck_m2_9_policy_hashes CHECK
 (length(configuration_hash)=32 AND configuration_hash~'^[0-9a-f]+$'
  AND length(row_hash)=32 AND row_hash~'^[0-9a-f]+$')
);

CREATE TABLE IF NOT EXISTS msbf_m2.payment_reconciliation_outcome_definition
(
 module1_run_id bigint NOT NULL, reconciliation_outcome_code text NOT NULL,
 reconciliation_outcome_rank integer NOT NULL, reconciliation_certified_flag boolean NOT NULL,
 exception_resolved_flag boolean NOT NULL, exception_open_flag boolean NOT NULL,
 review_hold_certified_flag boolean NOT NULL,
 real_funds_moved_flag boolean NOT NULL, production_state_updated_flag boolean NOT NULL,
 definition_status text NOT NULL, description text NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,reconciliation_outcome_code),
 CONSTRAINT ck_m2_9_outcome_rank CHECK(reconciliation_outcome_rank BETWEEN 0 AND 9),
 CONSTRAINT ck_m2_9_outcome_status CHECK(definition_status IN ('APPROVED','RETIRED')),
 CONSTRAINT ck_m2_9_outcome_flags CHECK(NOT(exception_resolved_flag AND exception_open_flag)),
 CONSTRAINT ck_m2_9_outcome_boundary CHECK(NOT real_funds_moved_flag AND NOT production_state_updated_flag)
);

CREATE TABLE IF NOT EXISTS msbf_m2.exception_resolution_action_definition
(
 module1_run_id bigint NOT NULL, resolution_action_code text NOT NULL,
 resolution_action_rank integer NOT NULL, exception_case_flag boolean NOT NULL,
 retry_resolution_flag boolean NOT NULL, review_hold_flag boolean NOT NULL,
 certification_block_flag boolean NOT NULL,
 real_funds_moved_flag boolean NOT NULL, external_system_called_flag boolean NOT NULL,
 definition_status text NOT NULL, description text NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,resolution_action_code),
 CONSTRAINT ck_m2_9_action_rank CHECK(resolution_action_rank BETWEEN 0 AND 9),
 CONSTRAINT ck_m2_9_action_status CHECK(definition_status IN ('APPROVED','RETIRED')),
 CONSTRAINT ck_m2_9_action_boundary CHECK(NOT real_funds_moved_flag AND NOT external_system_called_flag)
);

CREATE TABLE IF NOT EXISTS msbf_m2.account_state_certification_definition
(
 module1_run_id bigint NOT NULL, certification_state_code text NOT NULL,
 certification_state_rank integer NOT NULL, state_certified_flag boolean NOT NULL,
 active_state_flag boolean NOT NULL, closed_state_flag boolean NOT NULL,
 review_hold_state_flag boolean NOT NULL,
 production_account_state_flag boolean NOT NULL,
 definition_status text NOT NULL, description text NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,certification_state_code),
 CONSTRAINT ck_m2_9_cert_rank CHECK(certification_state_rank BETWEEN 0 AND 9),
 CONSTRAINT ck_m2_9_cert_status CHECK(definition_status IN ('APPROVED','RETIRED')),
 CONSTRAINT ck_m2_9_cert_boundary CHECK(NOT production_account_state_flag),
 CONSTRAINT ck_m2_9_cert_flags CHECK
 (num_nonnulls(NULLIF(active_state_flag,FALSE),NULLIF(closed_state_flag,FALSE),NULLIF(review_hold_state_flag,FALSE))<=1)
);

CREATE TABLE IF NOT EXISTS msbf_m2.payment_reconciliation_reason_definition
(
 module1_run_id bigint NOT NULL, reconciliation_reason_code text NOT NULL,
 mapped_outcome_code text NOT NULL, mapped_action_code text NOT NULL,
 real_execution_reason_flag boolean NOT NULL, production_adverse_action_flag boolean NOT NULL,
 definition_status text NOT NULL, description text NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,reconciliation_reason_code),
 FOREIGN KEY(module1_run_id,mapped_outcome_code)
  REFERENCES msbf_m2.payment_reconciliation_outcome_definition(module1_run_id,reconciliation_outcome_code),
 FOREIGN KEY(module1_run_id,mapped_action_code)
  REFERENCES msbf_m2.exception_resolution_action_definition(module1_run_id,resolution_action_code),
 CONSTRAINT ck_m2_9_reason_status CHECK(definition_status IN ('APPROVED','RETIRED')),
 CONSTRAINT ck_m2_9_reason_boundary CHECK(NOT real_execution_reason_flag AND NOT production_adverse_action_flag)
);

/* ============================================================================
Section 3 — Accepted M2.8 source snapshots
============================================================================ */
CREATE TABLE IF NOT EXISTS msbf_m2.account_reconciliation_source_snapshot
(
 module1_run_id bigint NOT NULL, scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, merchant_id text NOT NULL,
 synthetic_account_id text NOT NULL, synthetic_advance_id text NOT NULL,
 source_servicing_execution_outcome_code text NOT NULL,
 source_servicing_execution_action_code text NOT NULL,
 source_execution_queue_code text NOT NULL,
 source_processing_authorized_flag boolean NOT NULL,
 source_processing_review_required_flag boolean NOT NULL,
 source_no_processing_required_flag boolean NOT NULL,
 source_exposure_amount numeric(18,2) NOT NULL,
 source_final_lifecycle_state_code text NOT NULL,
 source_payment_event_count integer NOT NULL,
 source_settled_event_count integer NOT NULL,
 source_returned_event_count integer NOT NULL,
 source_retry_event_count integer NOT NULL,
 source_scheduled_payment_amount numeric(18,2) NOT NULL,
 source_processed_payment_amount numeric(18,2) NOT NULL,
 source_returned_payment_amount numeric(18,2) NOT NULL,
 source_retry_payment_amount numeric(18,2) NOT NULL,
 source_ending_exposure_amount numeric(18,2) NOT NULL,
 source_primary_reason_code text NOT NULL, source_reason_codes jsonb NOT NULL,
 source_contract_row_hash text NOT NULL, source_combined_set_hash text NOT NULL,
 source_payload jsonb NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
 CONSTRAINT ck_m2_9_account_source_amounts CHECK
 (source_exposure_amount>=0 AND source_scheduled_payment_amount>=0 AND source_processed_payment_amount>=0
  AND source_returned_payment_amount>=0 AND source_retry_payment_amount>=0 AND source_ending_exposure_amount>=0),
 CONSTRAINT ck_m2_9_account_source_reasons CHECK(jsonb_typeof(source_reason_codes)='array')
);

CREATE TABLE IF NOT EXISTS msbf_m2.payment_reconciliation_source_event
(
 module1_run_id bigint NOT NULL, scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, synthetic_account_id text NOT NULL,
 synthetic_advance_id text NOT NULL, synthetic_servicing_execution_id text NOT NULL,
 synthetic_servicing_plan_id text NOT NULL, event_sequence integer NOT NULL,
 event_date date NOT NULL, payment_event_type_code text NOT NULL,
 payment_status_code text NOT NULL, scheduled_payment_amount numeric(18,2) NOT NULL,
 retry_payment_amount numeric(18,2) NOT NULL, returned_payment_amount numeric(18,2) NOT NULL,
 processed_payment_amount numeric(18,2) NOT NULL, cumulative_processed_amount numeric(18,2) NOT NULL,
 simulated_outstanding_exposure_amount numeric(18,2) NOT NULL,
 lifecycle_state_before_code text NOT NULL, lifecycle_state_after_code text NOT NULL,
 primary_event_reason_code text NOT NULL, synthetic_payment_instruction_id text NOT NULL,
 synthetic_processor_reference_id text NOT NULL, source_event_row_hash text NOT NULL,
 source_combined_set_hash text NOT NULL, source_payload jsonb NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id,event_sequence),
 CONSTRAINT ck_m2_9_payment_source_amounts CHECK
 (scheduled_payment_amount>=0 AND retry_payment_amount>=0 AND returned_payment_amount>=0
  AND processed_payment_amount>=0 AND cumulative_processed_amount>=0 AND simulated_outstanding_exposure_amount>=0)
);

CREATE TABLE IF NOT EXISTS msbf_m2.lifecycle_certification_source_transition
(
 module1_run_id bigint NOT NULL, scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, synthetic_account_id text NOT NULL,
 synthetic_advance_id text NOT NULL, synthetic_servicing_execution_id text NOT NULL,
 transition_sequence integer NOT NULL, transition_date date NOT NULL,
 transition_type_code text NOT NULL, lifecycle_state_before_code text NOT NULL,
 lifecycle_state_after_code text NOT NULL, related_payment_event_sequence integer,
 related_payment_instruction_id text, primary_transition_reason_code text NOT NULL,
 source_execution_row_hash text NOT NULL, related_payment_event_row_hash text,
 source_transition_row_hash text NOT NULL, source_combined_set_hash text NOT NULL,
 source_payload jsonb NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id,transition_sequence)
);

/* ============================================================================
Section 4 — Reconciliation, exception, and certification outputs
============================================================================ */
CREATE TABLE IF NOT EXISTS msbf_m2.payment_event_reconciliation_snapshot
(
 module1_run_id bigint NOT NULL, scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, synthetic_account_id text NOT NULL,
 event_sequence integer NOT NULL, event_date date NOT NULL,
 payment_status_code text NOT NULL, scheduled_payment_amount numeric(18,2) NOT NULL,
 returned_payment_amount numeric(18,2) NOT NULL, retry_payment_amount numeric(18,2) NOT NULL,
 processed_payment_amount numeric(18,2) NOT NULL,
 expected_effective_processed_amount numeric(18,2) NOT NULL,
 reconciliation_variance_amount numeric(18,2) NOT NULL,
 event_reconciliation_status_code text NOT NULL,
 exception_case_required_flag boolean NOT NULL, exception_resolved_flag boolean NOT NULL,
 synthetic_exception_case_id text, primary_reconciliation_reason_code text NOT NULL,
 real_funds_moved_flag boolean NOT NULL, external_system_called_flag boolean NOT NULL,
 source_event_row_hash text NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id,event_sequence),
 FOREIGN KEY(module1_run_id,primary_reconciliation_reason_code)
  REFERENCES msbf_m2.payment_reconciliation_reason_definition(module1_run_id,reconciliation_reason_code),
 CONSTRAINT ck_m2_9_event_status CHECK(event_reconciliation_status_code IN
 ('RECONCILED_SETTLED','RECONCILED_RETURN','RECONCILED_RETRY_SETTLED','RECONCILIATION_VARIANCE')),
 CONSTRAINT ck_m2_9_event_boundary CHECK(NOT real_funds_moved_flag AND NOT external_system_called_flag)
);

CREATE TABLE IF NOT EXISTS msbf_m2.payment_exception_case_snapshot
(
 module1_run_id bigint NOT NULL, scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, synthetic_account_id text NOT NULL,
 synthetic_exception_case_id text NOT NULL, originating_event_sequence integer NOT NULL,
 originating_event_date date NOT NULL, resolving_event_sequence integer,
 resolving_event_date date, exception_amount numeric(18,2) NOT NULL,
 exception_status_code text NOT NULL, resolution_action_code text NOT NULL,
 exception_open_days integer NOT NULL, unresolved_exception_flag boolean NOT NULL,
 real_funds_moved_flag boolean NOT NULL, external_system_called_flag boolean NOT NULL,
 originating_event_row_hash text NOT NULL, resolving_event_row_hash text,
 row_hash text NOT NULL, created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id,synthetic_exception_case_id),
 FOREIGN KEY(module1_run_id,resolution_action_code)
  REFERENCES msbf_m2.exception_resolution_action_definition(module1_run_id,resolution_action_code),
 CONSTRAINT ck_m2_9_exception_status CHECK(exception_status_code IN
 ('RESOLVED_BY_RETRY','OPEN','ESCALATED','CERTIFICATION_BLOCKED')),
 CONSTRAINT ck_m2_9_exception_boundary CHECK(NOT real_funds_moved_flag AND NOT external_system_called_flag)
);

CREATE TABLE IF NOT EXISTS msbf_m2.account_payment_reconciliation_snapshot
(
 module1_run_id bigint NOT NULL, scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, merchant_id text NOT NULL,
 synthetic_account_id text NOT NULL, synthetic_advance_id text NOT NULL,
 source_final_lifecycle_state_code text NOT NULL, source_exposure_amount numeric(18,2) NOT NULL,
 payment_event_count integer NOT NULL, settled_event_count integer NOT NULL,
 returned_event_count integer NOT NULL, retry_event_count integer NOT NULL,
 scheduled_payment_amount numeric(18,2) NOT NULL, processed_payment_amount numeric(18,2) NOT NULL,
 returned_payment_amount numeric(18,2) NOT NULL, retry_payment_amount numeric(18,2) NOT NULL,
 expected_net_processed_amount numeric(18,2) NOT NULL,
 reconciliation_variance_amount numeric(18,2) NOT NULL,
 source_ending_exposure_amount numeric(18,2) NOT NULL,
 expected_ending_exposure_amount numeric(18,2) NOT NULL,
 exposure_variance_amount numeric(18,2) NOT NULL,
 exception_case_count integer NOT NULL, resolved_exception_count integer NOT NULL,
 unresolved_exception_count integer NOT NULL,
 reconciliation_outcome_code text NOT NULL, resolution_action_code text NOT NULL,
 certification_candidate_state_code text NOT NULL,
 reconciliation_certified_flag boolean NOT NULL,
 review_hold_certified_flag boolean NOT NULL, certification_blocked_flag boolean NOT NULL,
 certification_date date NOT NULL, primary_reconciliation_reason_code text NOT NULL,
 reconciliation_reason_codes jsonb NOT NULL,
 real_funds_moved_flag boolean NOT NULL, bank_account_data_present_flag boolean NOT NULL,
 ach_or_network_transmitted_flag boolean NOT NULL, external_processor_called_flag boolean NOT NULL,
 merchant_contact_executed_flag boolean NOT NULL, write_off_or_collection_flag boolean NOT NULL,
 external_notice_generated_flag boolean NOT NULL, production_adverse_action_flag boolean NOT NULL,
 source_contract_row_hash text NOT NULL, account_source_row_hash text NOT NULL,
 payment_reconciliation_set_hash text NOT NULL, transition_certification_set_hash text NOT NULL,
 policy_configuration_hash text NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
 FOREIGN KEY(module1_run_id,reconciliation_outcome_code)
  REFERENCES msbf_m2.payment_reconciliation_outcome_definition(module1_run_id,reconciliation_outcome_code),
 FOREIGN KEY(module1_run_id,resolution_action_code)
  REFERENCES msbf_m2.exception_resolution_action_definition(module1_run_id,resolution_action_code),
 FOREIGN KEY(module1_run_id,certification_candidate_state_code)
  REFERENCES msbf_m2.account_state_certification_definition(module1_run_id,certification_state_code),
 FOREIGN KEY(module1_run_id,primary_reconciliation_reason_code)
  REFERENCES msbf_m2.payment_reconciliation_reason_definition(module1_run_id,reconciliation_reason_code),
 CONSTRAINT ck_m2_9_account_recon_reasons CHECK(jsonb_typeof(reconciliation_reason_codes)='array'),
 CONSTRAINT ck_m2_9_account_recon_boundary CHECK
 (NOT real_funds_moved_flag AND NOT bank_account_data_present_flag AND NOT ach_or_network_transmitted_flag
  AND NOT external_processor_called_flag AND NOT merchant_contact_executed_flag
  AND NOT write_off_or_collection_flag AND NOT external_notice_generated_flag
  AND NOT production_adverse_action_flag)
);

CREATE TABLE IF NOT EXISTS msbf_m2.account_state_certification_snapshot
(
 module1_run_id bigint NOT NULL, scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, synthetic_account_id text NOT NULL,
 synthetic_advance_id text NOT NULL, source_final_lifecycle_state_code text NOT NULL,
 certified_state_code text NOT NULL, state_certified_flag boolean NOT NULL,
 active_state_flag boolean NOT NULL, closed_state_flag boolean NOT NULL,
 review_hold_state_flag boolean NOT NULL, exception_resolved_flag boolean NOT NULL,
 certified_exposure_amount numeric(18,2) NOT NULL, certification_date date NOT NULL,
 primary_certification_reason_code text NOT NULL, certification_reason_codes jsonb NOT NULL,
 real_funds_moved_flag boolean NOT NULL, production_account_state_flag boolean NOT NULL,
 external_system_update_flag boolean NOT NULL,
 source_account_reconciliation_row_hash text NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
 FOREIGN KEY(module1_run_id,certified_state_code)
  REFERENCES msbf_m2.account_state_certification_definition(module1_run_id,certification_state_code),
 FOREIGN KEY(module1_run_id,primary_certification_reason_code)
  REFERENCES msbf_m2.payment_reconciliation_reason_definition(module1_run_id,reconciliation_reason_code),
 CONSTRAINT ck_m2_9_certification_reasons CHECK(jsonb_typeof(certification_reason_codes)='array'),
 CONSTRAINT ck_m2_9_certification_boundary CHECK
 (NOT real_funds_moved_flag AND NOT production_account_state_flag AND NOT external_system_update_flag)
);

CREATE TABLE IF NOT EXISTS msbf_m2.payment_reconciliation_portfolio_summary
(
 module1_run_id bigint NOT NULL, scenario_code text NOT NULL,
 source_rows bigint NOT NULL, certified_rows bigint NOT NULL,
 no_payment_activity_rows bigint NOT NULL, reconciled_after_retry_rows bigint NOT NULL,
 review_hold_rows bigint NOT NULL, payment_event_rows bigint NOT NULL,
 exception_case_rows bigint NOT NULL, resolved_exception_rows bigint NOT NULL,
 unresolved_exception_rows bigint NOT NULL,
 scheduled_payment_amount numeric(24,2) NOT NULL, processed_payment_amount numeric(24,2) NOT NULL,
 returned_payment_amount numeric(24,2) NOT NULL, retry_payment_amount numeric(24,2) NOT NULL,
 reconciliation_variance_amount numeric(24,2) NOT NULL,
 certified_exposure_amount numeric(24,2) NOT NULL, exposure_variance_amount numeric(24,2) NOT NULL,
 maximum_reconciliation_rank integer NOT NULL, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_code),
 CONSTRAINT ck_m2_9_portfolio_counts CHECK(certified_rows=source_rows)
);

/* ============================================================================
Section 5 — Latest, archive, and registry contracts
============================================================================ */
CREATE TABLE IF NOT EXISTS msbf_m2.application_payment_reconciliation_certification_latest
(
 module1_run_id bigint NOT NULL, contract_code text NOT NULL, contract_version integer NOT NULL,
 schema_version text NOT NULL, methodology_version text NOT NULL,
 scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, merchant_id text NOT NULL,
 synthetic_account_id text NOT NULL, synthetic_advance_id text NOT NULL,
 source_final_lifecycle_state_code text NOT NULL, source_exposure_amount numeric(18,2) NOT NULL,
 payment_event_count integer NOT NULL, settled_event_count integer NOT NULL,
 returned_event_count integer NOT NULL, retry_event_count integer NOT NULL,
 scheduled_payment_amount numeric(18,2) NOT NULL, processed_payment_amount numeric(18,2) NOT NULL,
 returned_payment_amount numeric(18,2) NOT NULL, retry_payment_amount numeric(18,2) NOT NULL,
 expected_net_processed_amount numeric(18,2) NOT NULL,
 reconciliation_variance_amount numeric(18,2) NOT NULL,
 source_ending_exposure_amount numeric(18,2) NOT NULL,
 expected_ending_exposure_amount numeric(18,2) NOT NULL,
 exposure_variance_amount numeric(18,2) NOT NULL,
 exception_case_count integer NOT NULL, resolved_exception_count integer NOT NULL,
 unresolved_exception_count integer NOT NULL,
 reconciliation_outcome_code text NOT NULL, resolution_action_code text NOT NULL,
 certified_state_code text NOT NULL, state_certified_flag boolean NOT NULL,
 active_state_flag boolean NOT NULL, closed_state_flag boolean NOT NULL,
 review_hold_state_flag boolean NOT NULL, exception_resolved_flag boolean NOT NULL,
 certified_exposure_amount numeric(18,2) NOT NULL, certification_date date NOT NULL,
 primary_reconciliation_reason_code text NOT NULL, reconciliation_reason_codes jsonb NOT NULL,
 source_contract_row_hash text NOT NULL, account_source_row_hash text NOT NULL,
 account_reconciliation_row_hash text NOT NULL, state_certification_row_hash text NOT NULL,
 policy_configuration_hash text NOT NULL, contract_row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
 CONSTRAINT ck_m2_9_latest_identity CHECK
 (contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND contract_version=1 AND schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1' AND methodology_version='M2_9_METHOD_V1')
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_payment_reconciliation_certification_archive
(
 archive_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 module1_run_id bigint NOT NULL, contract_code text NOT NULL, contract_version integer NOT NULL,
 schema_version text NOT NULL, methodology_version text NOT NULL,
 scenario_id bigint NOT NULL, scenario_code text NOT NULL,
 merchant_application_id text NOT NULL, merchant_id text NOT NULL,
 synthetic_account_id text NOT NULL, synthetic_advance_id text NOT NULL,
 source_final_lifecycle_state_code text NOT NULL, source_exposure_amount numeric(18,2) NOT NULL,
 payment_event_count integer NOT NULL, settled_event_count integer NOT NULL,
 returned_event_count integer NOT NULL, retry_event_count integer NOT NULL,
 scheduled_payment_amount numeric(18,2) NOT NULL, processed_payment_amount numeric(18,2) NOT NULL,
 returned_payment_amount numeric(18,2) NOT NULL, retry_payment_amount numeric(18,2) NOT NULL,
 expected_net_processed_amount numeric(18,2) NOT NULL,
 reconciliation_variance_amount numeric(18,2) NOT NULL,
 source_ending_exposure_amount numeric(18,2) NOT NULL,
 expected_ending_exposure_amount numeric(18,2) NOT NULL,
 exposure_variance_amount numeric(18,2) NOT NULL,
 exception_case_count integer NOT NULL, resolved_exception_count integer NOT NULL,
 unresolved_exception_count integer NOT NULL,
 reconciliation_outcome_code text NOT NULL, resolution_action_code text NOT NULL,
 certified_state_code text NOT NULL, state_certified_flag boolean NOT NULL,
 active_state_flag boolean NOT NULL, closed_state_flag boolean NOT NULL,
 review_hold_state_flag boolean NOT NULL, exception_resolved_flag boolean NOT NULL,
 certified_exposure_amount numeric(18,2) NOT NULL, certification_date date NOT NULL,
 primary_reconciliation_reason_code text NOT NULL, reconciliation_reason_codes jsonb NOT NULL,
 source_contract_row_hash text NOT NULL, account_source_row_hash text NOT NULL,
 account_reconciliation_row_hash text NOT NULL, state_certification_row_hash text NOT NULL,
 policy_configuration_hash text NOT NULL, contract_row_hash text NOT NULL,
 contract_payload jsonb NOT NULL, archive_row_hash text NOT NULL,
 archived_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(module1_run_id,contract_version,scenario_id,merchant_application_id),
 CONSTRAINT ck_m2_9_archive_identity CHECK
 (contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND contract_version=1 AND schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1' AND methodology_version='M2_9_METHOD_V1')
);

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_9_reconciliation_certification_contract_registry
(
 registry_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, module1_run_id bigint NOT NULL UNIQUE,
 contract_code text NOT NULL, contract_version integer NOT NULL, schema_version text NOT NULL,
 methodology_version text NOT NULL, source_contract_code text NOT NULL,
 source_contract_version integer NOT NULL, source_schema_version text NOT NULL,
 source_acceptance_gate_id text NOT NULL, source_combined_set_hash text NOT NULL,
 policy_configuration_hash text NOT NULL,
 policy_rows bigint NOT NULL, reconciliation_outcome_rows bigint NOT NULL,
 resolution_action_rows bigint NOT NULL, certification_state_rows bigint NOT NULL,
 reason_rows bigint NOT NULL, account_source_rows bigint NOT NULL,
 payment_source_rows bigint NOT NULL, transition_source_rows bigint NOT NULL,
 payment_reconciliation_rows bigint NOT NULL, exception_case_rows bigint NOT NULL,
 account_reconciliation_rows bigint NOT NULL, state_certification_rows bigint NOT NULL,
 portfolio_summary_rows bigint NOT NULL, latest_rows bigint NOT NULL, archive_rows bigint NOT NULL,
 comparison_rows bigint NOT NULL, registry_rows bigint NOT NULL, canonical_entities bigint NOT NULL,
 no_payment_activity_rows bigint NOT NULL, reconciled_after_retry_rows bigint NOT NULL,
 review_hold_rows bigint NOT NULL, certified_closed_rows bigint NOT NULL,
 certified_reassessment_rows bigint NOT NULL, certified_review_hold_rows bigint NOT NULL,
 settled_event_rows bigint NOT NULL, returned_event_rows bigint NOT NULL, retry_event_rows bigint NOT NULL,
 exception_opened_rows bigint NOT NULL, exception_resolved_rows bigint NOT NULL,
 unresolved_exception_rows bigint NOT NULL,
 scheduled_payment_amount numeric(24,2) NOT NULL, processed_payment_amount numeric(24,2) NOT NULL,
 returned_payment_amount numeric(24,2) NOT NULL, retry_payment_amount numeric(24,2) NOT NULL,
 exception_amount numeric(24,2) NOT NULL, reconciliation_variance_amount numeric(24,2) NOT NULL,
 exposure_variance_amount numeric(24,2) NOT NULL,
 active_certified_exposure_amount numeric(24,2) NOT NULL,
 review_hold_exposure_amount numeric(24,2) NOT NULL,
 portfolio_certified_exposure_amount numeric(24,2) NOT NULL,
 policy_set_hash text NOT NULL, reconciliation_outcome_set_hash text NOT NULL,
 resolution_action_set_hash text NOT NULL, certification_state_set_hash text NOT NULL,
 reason_set_hash text NOT NULL, account_source_set_hash text NOT NULL,
 payment_source_set_hash text NOT NULL, transition_source_set_hash text NOT NULL,
 payment_reconciliation_set_hash text NOT NULL, exception_case_set_hash text NOT NULL,
 account_reconciliation_set_hash text NOT NULL, state_certification_set_hash text NOT NULL,
 portfolio_summary_set_hash text NOT NULL, latest_set_hash text NOT NULL,
 archive_set_hash text NOT NULL, contract_set_hash text NOT NULL, combined_set_hash text NOT NULL,
 contract_status text NOT NULL, generated_at timestamptz, validated_at timestamptz,
 accepted_at timestamptz, row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CONSTRAINT ck_m2_9_registry_identity CHECK
 (contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND contract_version=1 AND schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1' AND methodology_version='M2_9_METHOD_V1'),
 CONSTRAINT ck_m2_9_registry_status CHECK(contract_status IN ('GENERATED','VALIDATED','ACCEPTED'))
);

/* ============================================================================
Section 6 — Immutability, indexes, and lifecycle assertions
============================================================================ */
CREATE OR REPLACE FUNCTION msbf_ctl.m2_9_archive_immutable()
RETURNS trigger LANGUAGE plpgsql AS $function$
BEGIN RAISE EXCEPTION 'M2.9 reconciliation certification archive is immutable; % is not permitted.',TG_OP; END;
$function$;
DROP TRIGGER IF EXISTS trg_m2_9_archive_immutable
ON msbf_m2.application_payment_reconciliation_certification_archive;
CREATE TRIGGER trg_m2_9_archive_immutable
BEFORE UPDATE OR DELETE ON msbf_m2.application_payment_reconciliation_certification_archive
FOR EACH ROW EXECUTE FUNCTION msbf_ctl.m2_9_archive_immutable();

CREATE INDEX IF NOT EXISTS ix_m2_9_account_source ON msbf_m2.account_reconciliation_source_snapshot(module1_run_id,scenario_code,synthetic_account_id);
CREATE INDEX IF NOT EXISTS ix_m2_9_payment_source ON msbf_m2.payment_reconciliation_source_event(module1_run_id,synthetic_account_id,event_sequence);
CREATE INDEX IF NOT EXISTS ix_m2_9_transition_source ON msbf_m2.lifecycle_certification_source_transition(module1_run_id,synthetic_account_id,transition_sequence);
CREATE INDEX IF NOT EXISTS ix_m2_9_event_status ON msbf_m2.payment_event_reconciliation_snapshot(module1_run_id,event_reconciliation_status_code);
CREATE INDEX IF NOT EXISTS ix_m2_9_exception_status ON msbf_m2.payment_exception_case_snapshot(module1_run_id,exception_status_code);
CREATE INDEX IF NOT EXISTS ix_m2_9_account_outcome ON msbf_m2.account_payment_reconciliation_snapshot(module1_run_id,scenario_code,reconciliation_outcome_code);
CREATE INDEX IF NOT EXISTS ix_m2_9_cert_state ON msbf_m2.account_state_certification_snapshot(module1_run_id,scenario_code,certified_state_code);
CREATE INDEX IF NOT EXISTS ix_m2_9_latest_state ON msbf_m2.application_payment_reconciliation_certification_latest(module1_run_id,scenario_code,certified_state_code);

CREATE OR REPLACE FUNCTION msbf_ctl.m2_9_assert_configuration(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v record;
BEGIN
 SELECT * INTO v FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=p_run_id;
 IF v.module1_run_id IS NULL OR v.policy_status<>'APPROVED' OR v.policy_code<>'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1'
 OR v.methodology_version<>'M2_9_METHOD_V1' OR v.contract_code<>'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'
 OR v.contract_version<>1 OR v.schema_version<>'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'
 OR v.source_registry_name<>'msbf_ctl.m2_8_servicing_execution_contract_registry' OR v.source_latest_name<>'msbf_m2.application_servicing_execution_latest'
 OR v.source_payment_name<>'msbf_m2.synthetic_payment_processing_event' OR v.source_transition_name<>'msbf_m2.account_lifecycle_transition_snapshot'
 OR v.source_contract_code<>'M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' OR v.source_schema_version<>'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1'
 OR v.source_methodology_version<>'M2_8_METHOD_V1' OR v.source_policy_code<>'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1'
 OR v.source_acceptance_gate_id<>'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' OR v.source_combined_set_hash<>'ab32d80ba20c2c8f0a6ec9ec97c2ed26'
 OR NOT v.synthetic_data_only_flag OR NOT v.reconciliation_certification_only_flag
 OR NOT v.preserve_m2_8_history_flag OR NOT v.no_real_funds_movement_flag
 OR NOT v.no_bank_account_data_flag OR NOT v.no_ach_or_network_transmission_flag
 OR NOT v.no_external_processor_call_flag OR NOT v.no_real_merchant_contact_flag
 OR NOT v.no_write_off_or_collection_execution_flag OR NOT v.no_external_notice_generation_flag
 OR NOT v.no_production_adverse_action_flag
 OR v.configuration_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(v.configuration_payload)
 OR v.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(v)-'row_hash'-'created_at'-'updated_at')
 THEN RAISE EXCEPTION 'M2.9 configuration assertion failed for run_id %.',p_run_id; END IF;
END;$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_9_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_status text;
BEGIN
 PERFORM msbf_ctl.m2_9_assert_configuration(p_run_id);
 SELECT run_status INTO v_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
 IF v_status<>'M2_8_ACCEPTED' THEN RAISE EXCEPTION 'M2.9 generation requires M2_8_ACCEPTED; observed %.',v_status; END IF;
 IF EXISTS(
  SELECT 1 FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.payment_reconciliation_portfolio_summary WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_m2.application_payment_reconciliation_certification_archive WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=p_run_id UNION ALL
  SELECT 1 FROM msbf_ctl.run_evidence WHERE run_id=p_run_id AND evidence_code LIKE 'M2_9_%' UNION ALL
  SELECT 1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'
 ) THEN RAISE EXCEPTION 'M2.9 generation requires empty M2.9 targets for run_id %.',p_run_id; END IF;
END;$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_9_assert_validation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE vr text; vc text;
BEGIN
 PERFORM msbf_ctl.m2_9_assert_configuration(p_run_id);
 SELECT run_status INTO vr FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
 SELECT contract_status INTO vc FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=p_run_id;
 IF NOT((vr='M2_9_GENERATED' AND vc='GENERATED') OR (vr='M2_9_VALIDATED' AND vc='VALIDATED'))
 THEN RAISE EXCEPTION 'M2.9 validation requires aligned generated or validated state; run %, contract %.',vr,vc; END IF;
END;$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_9_assert_acceptance_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE vr text; vc text; vp bigint; vn bigint;
BEGIN
 PERFORM msbf_ctl.m2_9_assert_configuration(p_run_id);
 SELECT run_status INTO vr FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
 SELECT contract_status INTO vc FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=p_run_id;
 SELECT count(*) FILTER(WHERE evidence_code LIKE 'M2_9_POS_%' AND status='PASS'),
        count(*) FILTER(WHERE evidence_code LIKE 'M2_9_NEG_%' AND status='PASS')
 INTO vp,vn FROM msbf_ctl.run_evidence WHERE run_id=p_run_id;
 IF vr<>'M2_9_VALIDATED' OR vc<>'VALIDATED' OR vp<>120 OR vn<>20
 THEN RAISE EXCEPTION 'M2.9 acceptance not ready: run %, contract %, positive %, negative %.',vr,vc,vp,vn; END IF;
END;$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_9_assert_no_real_reconciliation_payload(p_payload jsonb)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_key text;
BEGIN
 SELECT key INTO v_key FROM jsonb_object_keys(coalesce(p_payload,'{}'::jsonb)) AS key
 WHERE lower(key) IN('real_bank_account_number','bank_account_number','routing_number','ach_trace_number',
 'payment_network_confirmation','processor_authorization_code','real_funds_moved','real_payment_instruction',
 'merchant_contact_executed','write_off_posted','collection_agency_referral','legal_action_executed',
 'external_notice_payload','production_adverse_action_notice') LIMIT 1;
 IF v_key IS NOT NULL THEN RAISE EXCEPTION 'M2.9 rejected prohibited reconciliation payload key %.',v_key; END IF;
END;$function$;

/* ============================================================================
Section 7 — Gate registration and governed seed records
============================================================================ */
INSERT INTO msbf_ref.acceptance_gate_catalog(gate_id,gate_name,module_code,severity,active_flag,description)
VALUES('M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION','M2.9 Payment Reconciliation, Exception Resolution & Account State Certification','M2.9','BLOCKING',TRUE,
'Accepts deterministic synthetic payment reconciliation, exception resolution, and account-state certification while prohibiting real funds movement, bank data, network transmission, processor calls, contact, write-off or collection execution, and external or adverse-action notice generation.')
ON CONFLICT(gate_id) DO UPDATE SET gate_name=EXCLUDED.gate_name,module_code=EXCLUDED.module_code,severity=EXCLUDED.severity,active_flag=EXCLUDED.active_flag,description=EXCLUDED.description;

WITH seed AS(
 SELECT registry.module1_run_id::bigint AS module1_run_id,
 'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1'::text AS policy_code,1::integer AS policy_version,'APPROVED'::text AS policy_status,
 'M2_9_METHOD_V1'::text AS methodology_version,'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'::text AS contract_code,1::integer AS contract_version,'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'::text AS schema_version,
 'msbf_ctl.m2_8_servicing_execution_contract_registry'::text AS source_registry_name,'msbf_m2.application_servicing_execution_latest'::text AS source_latest_name,
 'msbf_m2.synthetic_payment_processing_event'::text AS source_payment_name,'msbf_m2.account_lifecycle_transition_snapshot'::text AS source_transition_name,
 'M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION'::text AS source_contract_code,1::integer AS source_contract_version,
 'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1'::text AS source_schema_version,'M2_8_METHOD_V1'::text AS source_methodology_version,
 'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1'::text AS source_policy_code,'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL'::text AS source_acceptance_gate_id,'ab32d80ba20c2c8f0a6ec9ec97c2ed26'::text AS source_combined_set_hash,
 TRUE::boolean AS synthetic_data_only_flag,TRUE::boolean AS reconciliation_certification_only_flag,
 TRUE::boolean AS preserve_m2_8_history_flag,TRUE::boolean AS no_real_funds_movement_flag,
 TRUE::boolean AS no_bank_account_data_flag,TRUE::boolean AS no_ach_or_network_transmission_flag,
 TRUE::boolean AS no_external_processor_call_flag,TRUE::boolean AS no_real_merchant_contact_flag,
 TRUE::boolean AS no_write_off_or_collection_execution_flag,TRUE::boolean AS no_external_notice_generation_flag,
 TRUE::boolean AS no_production_adverse_action_flag,0.00::numeric(18,2) AS reconciliation_tolerance_amount,
 0.00::numeric(18,2) AS exposure_tolerance_amount,1::integer AS maximum_exception_resolution_days,
 1::bigint AS expected_policy_rows,7::bigint AS expected_reconciliation_outcome_rows,
 7::bigint AS expected_resolution_action_rows,7::bigint AS expected_certification_state_rows,
 36::bigint AS expected_reason_rows,59::bigint AS expected_account_source_rows,
 7::bigint AS expected_payment_source_rows,67::bigint AS expected_transition_source_rows,
 7::bigint AS expected_payment_reconciliation_rows,1::bigint AS expected_exception_case_rows,
 59::bigint AS expected_account_reconciliation_rows,59::bigint AS expected_state_certification_rows,
 2::bigint AS expected_portfolio_summary_rows,59::bigint AS expected_latest_rows,59::bigint AS expected_archive_rows,
 15::bigint AS expected_comparison_rows,1::bigint AS expected_registry_rows,438::bigint AS expected_canonical_entities,
 120::integer AS expected_positive_controls,20::integer AS expected_negative_controls,
 24::integer AS expected_generation_evidence_rows,24::integer AS expected_detail_result_sets,
 '{"acceptance_gate":"M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION","contract_code":"M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION","contract_version":1,"expected":{"account_reconciliation_rows":59,"account_source_rows":59,"active_certified_exposure_amount":"323.79","archive_rows":59,"canonical_entities":438,"certification_state_rows":7,"certified_closed_rows":57,"certified_reassessment_rows":1,"certified_review_hold_rows":1,"comparison_rows":15,"detail_result_sets":24,"exception_amount":"27.75","exception_case_rows":1,"exception_opened_rows":1,"exception_resolved_rows":1,"exposure_variance_amount":"0.00","generation_evidence_rows":24,"latest_rows":59,"negative_controls":20,"no_payment_activity_rows":57,"payment_reconciliation_rows":7,"payment_source_rows":7,"policy_rows":1,"portfolio_certified_exposure_amount":"785.48","portfolio_summary_rows":2,"positive_controls":120,"processed_payment_amount":"194.25","reason_rows":36,"reconciled_after_retry_rows":1,"reconciliation_outcome_rows":7,"reconciliation_variance_amount":"0.00","registry_rows":1,"resolution_action_rows":7,"retry_event_rows":1,"retry_payment_amount":"27.75","returned_event_rows":1,"returned_payment_amount":"27.75","review_hold_exposure_amount":"461.69","review_hold_rows":1,"scheduled_payment_amount":"194.25","settled_event_rows":5,"state_certification_rows":59,"transition_source_rows":67,"unresolved_exception_rows":0},"exposure_tolerance_amount":0.0,"maximum_exception_resolution_days":1,"methodology":"M2_9_METHOD_V1","no_ach_or_network_transmission":true,"no_bank_account_data":true,"no_external_notice_generation":true,"no_external_processor_call":true,"no_production_adverse_action":true,"no_real_funds_movement":true,"no_real_merchant_contact":true,"no_write_off_or_collection_execution":true,"policy_code":"M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1","preserve_m2_8_history":true,"reconciliation_certification_only":true,"reconciliation_tolerance_amount":0.0,"schema_version":"M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1","source_contract":"M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION","source_gate":"M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL","source_hash":"ab32d80ba20c2c8f0a6ec9ec97c2ed26","source_latest":"msbf_m2.application_servicing_execution_latest","source_methodology":"M2_8_METHOD_V1","source_payment":"msbf_m2.synthetic_payment_processing_event","source_policy":"M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1","source_registry":"msbf_ctl.m2_8_servicing_execution_contract_registry","source_schema":"M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1","source_transition":"msbf_m2.account_lifecycle_transition_snapshot","synthetic_data_only":true}'::jsonb AS configuration_payload,msbf_ctl.m2_9_hash_jsonb('{"acceptance_gate":"M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION","contract_code":"M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION","contract_version":1,"expected":{"account_reconciliation_rows":59,"account_source_rows":59,"active_certified_exposure_amount":"323.79","archive_rows":59,"canonical_entities":438,"certification_state_rows":7,"certified_closed_rows":57,"certified_reassessment_rows":1,"certified_review_hold_rows":1,"comparison_rows":15,"detail_result_sets":24,"exception_amount":"27.75","exception_case_rows":1,"exception_opened_rows":1,"exception_resolved_rows":1,"exposure_variance_amount":"0.00","generation_evidence_rows":24,"latest_rows":59,"negative_controls":20,"no_payment_activity_rows":57,"payment_reconciliation_rows":7,"payment_source_rows":7,"policy_rows":1,"portfolio_certified_exposure_amount":"785.48","portfolio_summary_rows":2,"positive_controls":120,"processed_payment_amount":"194.25","reason_rows":36,"reconciled_after_retry_rows":1,"reconciliation_outcome_rows":7,"reconciliation_variance_amount":"0.00","registry_rows":1,"resolution_action_rows":7,"retry_event_rows":1,"retry_payment_amount":"27.75","returned_event_rows":1,"returned_payment_amount":"27.75","review_hold_exposure_amount":"461.69","review_hold_rows":1,"scheduled_payment_amount":"194.25","settled_event_rows":5,"state_certification_rows":59,"transition_source_rows":67,"unresolved_exception_rows":0},"exposure_tolerance_amount":0.0,"maximum_exception_resolution_days":1,"methodology":"M2_9_METHOD_V1","no_ach_or_network_transmission":true,"no_bank_account_data":true,"no_external_notice_generation":true,"no_external_processor_call":true,"no_production_adverse_action":true,"no_real_funds_movement":true,"no_real_merchant_contact":true,"no_write_off_or_collection_execution":true,"policy_code":"M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1","preserve_m2_8_history":true,"reconciliation_certification_only":true,"reconciliation_tolerance_amount":0.0,"schema_version":"M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1","source_contract":"M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION","source_gate":"M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL","source_hash":"ab32d80ba20c2c8f0a6ec9ec97c2ed26","source_latest":"msbf_m2.application_servicing_execution_latest","source_methodology":"M2_8_METHOD_V1","source_payment":"msbf_m2.synthetic_payment_processing_event","source_policy":"M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_POLICY_V1","source_registry":"msbf_ctl.m2_8_servicing_execution_contract_registry","source_schema":"M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1","source_transition":"msbf_m2.account_lifecycle_transition_snapshot","synthetic_data_only":true}'::jsonb) AS configuration_hash
 FROM msbf_ctl.m2_8_servicing_execution_contract_registry AS registry JOIN msbf_ctl.run_registry AS run ON run.run_id=registry.module1_run_id
 WHERE run.run_code='M1_V0_2_BASELINE_BUILD' AND run.run_version=1 AND run.run_status='M2_8_ACCEPTED'
 AND registry.contract_status='ACCEPTED' AND registry.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND registry.contract_version=1
 AND registry.schema_version='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1' AND registry.combined_set_hash='ab32d80ba20c2c8f0a6ec9ec97c2ed26'
), hashed AS(SELECT seed.*,msbf_ctl.m2_9_hash_jsonb(to_jsonb(seed)) AS row_hash FROM seed)
INSERT INTO msbf_ctl.m2_9_policy_profile
(module1_run_id,policy_code,policy_version,policy_status,methodology_version,contract_code,contract_version,schema_version,
source_registry_name,source_latest_name,source_payment_name,source_transition_name,source_contract_code,source_contract_version,
source_schema_version,source_methodology_version,source_policy_code,source_acceptance_gate_id,source_combined_set_hash,
synthetic_data_only_flag,reconciliation_certification_only_flag,preserve_m2_8_history_flag,no_real_funds_movement_flag,
no_bank_account_data_flag,no_ach_or_network_transmission_flag,no_external_processor_call_flag,no_real_merchant_contact_flag,
no_write_off_or_collection_execution_flag,no_external_notice_generation_flag,no_production_adverse_action_flag,
reconciliation_tolerance_amount,exposure_tolerance_amount,maximum_exception_resolution_days,
expected_policy_rows,expected_reconciliation_outcome_rows,expected_resolution_action_rows,expected_certification_state_rows,
expected_reason_rows,expected_account_source_rows,expected_payment_source_rows,expected_transition_source_rows,
expected_payment_reconciliation_rows,expected_exception_case_rows,expected_account_reconciliation_rows,
expected_state_certification_rows,expected_portfolio_summary_rows,expected_latest_rows,expected_archive_rows,
expected_comparison_rows,expected_registry_rows,expected_canonical_entities,expected_positive_controls,
expected_negative_controls,expected_generation_evidence_rows,expected_detail_result_sets,configuration_payload,configuration_hash,row_hash)
SELECT module1_run_id,policy_code,policy_version,policy_status,methodology_version,contract_code,contract_version,schema_version,
source_registry_name,source_latest_name,source_payment_name,source_transition_name,source_contract_code,source_contract_version,
source_schema_version,source_methodology_version,source_policy_code,source_acceptance_gate_id,source_combined_set_hash,
synthetic_data_only_flag,reconciliation_certification_only_flag,preserve_m2_8_history_flag,no_real_funds_movement_flag,
no_bank_account_data_flag,no_ach_or_network_transmission_flag,no_external_processor_call_flag,no_real_merchant_contact_flag,
no_write_off_or_collection_execution_flag,no_external_notice_generation_flag,no_production_adverse_action_flag,
reconciliation_tolerance_amount,exposure_tolerance_amount,maximum_exception_resolution_days,
expected_policy_rows,expected_reconciliation_outcome_rows,expected_resolution_action_rows,expected_certification_state_rows,
expected_reason_rows,expected_account_source_rows,expected_payment_source_rows,expected_transition_source_rows,
expected_payment_reconciliation_rows,expected_exception_case_rows,expected_account_reconciliation_rows,
expected_state_certification_rows,expected_portfolio_summary_rows,expected_latest_rows,expected_archive_rows,
expected_comparison_rows,expected_registry_rows,expected_canonical_entities,expected_positive_controls,
expected_negative_controls,expected_generation_evidence_rows,expected_detail_result_sets,configuration_payload,configuration_hash,row_hash
FROM hashed ON CONFLICT(module1_run_id) DO NOTHING;

WITH rc AS(SELECT module1_run_id FROM msbf_ctl.m2_9_policy_profile WHERE policy_code='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1'), seed AS(
 SELECT rc.module1_run_id,v.reconciliation_outcome_code::text,v.reconciliation_outcome_rank::integer,
 v.reconciliation_certified_flag::boolean,v.exception_resolved_flag::boolean,v.exception_open_flag::boolean,
 v.review_hold_certified_flag::boolean,FALSE::boolean AS real_funds_moved_flag,FALSE::boolean AS production_state_updated_flag,
 'APPROVED'::text AS definition_status,v.description::text FROM rc CROSS JOIN(VALUES
 ('NO_PAYMENT_ACTIVITY_RECONCILED', 0, TRUE, FALSE, FALSE, FALSE, 'No payment activity exists and the account is reconciled.'),
        ('PAYMENT_ACTIVITY_RECONCILED', 1, TRUE, FALSE, FALSE, FALSE, 'Synthetic payment activity reconciles without exception.'),
        ('PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY', 2, TRUE, TRUE, FALSE, FALSE, 'Returned payment is fully resolved by the governed retry.'),
        ('PAYMENT_ACTIVITY_VARIANCE', 3, FALSE, FALSE, TRUE, FALSE, 'Synthetic payment activity contains a reconciliation variance.'),
        ('PAYMENT_EXCEPTION_UNRESOLVED', 4, FALSE, FALSE, TRUE, FALSE, 'A synthetic payment exception remains unresolved.'),
        ('RECONCILIATION_REVIEW_HOLD', 5, TRUE, FALSE, FALSE, TRUE, 'The account has no executable payment history and its review-hold state is certified.'),
        ('RECONCILIATION_CERTIFICATION_FAILED', 9, FALSE, FALSE, TRUE, FALSE, 'Account reconciliation or state certification failed.')
 ) AS v(reconciliation_outcome_code,reconciliation_outcome_rank,reconciliation_certified_flag,exception_resolved_flag,exception_open_flag,review_hold_certified_flag,description)
), hashed AS(SELECT seed.*,msbf_ctl.m2_9_hash_jsonb(to_jsonb(seed)) AS row_hash FROM seed)
INSERT INTO msbf_m2.payment_reconciliation_outcome_definition
(module1_run_id,reconciliation_outcome_code,reconciliation_outcome_rank,reconciliation_certified_flag,exception_resolved_flag,
exception_open_flag,review_hold_certified_flag,real_funds_moved_flag,production_state_updated_flag,definition_status,description,row_hash)
SELECT module1_run_id,reconciliation_outcome_code,reconciliation_outcome_rank,reconciliation_certified_flag,exception_resolved_flag,
exception_open_flag,review_hold_certified_flag,real_funds_moved_flag,production_state_updated_flag,definition_status,description,row_hash
FROM hashed ON CONFLICT(module1_run_id,reconciliation_outcome_code) DO NOTHING;

WITH rc AS(SELECT module1_run_id FROM msbf_ctl.m2_9_policy_profile WHERE policy_code='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1'), seed AS(
 SELECT rc.module1_run_id,v.resolution_action_code::text,v.resolution_action_rank::integer,v.exception_case_flag::boolean,
 v.retry_resolution_flag::boolean,v.review_hold_flag::boolean,v.certification_block_flag::boolean,
 FALSE::boolean AS real_funds_moved_flag,FALSE::boolean AS external_system_called_flag,'APPROVED'::text AS definition_status,
 v.description::text FROM rc CROSS JOIN(VALUES
 ('NO_EXCEPTION_ACTION_REQUIRED', 0, FALSE, FALSE, FALSE, FALSE, 'No exception action is required.'),
        ('CERTIFY_NO_PAYMENT_ACTIVITY', 1, FALSE, FALSE, FALSE, FALSE, 'Certify the absence of payment activity.'),
        ('CERTIFY_RECONCILED_PAYMENT_HISTORY', 2, FALSE, FALSE, FALSE, FALSE, 'Certify a fully reconciled payment history.'),
        ('RESOLVE_RETURN_WITH_RETRY', 3, TRUE, TRUE, FALSE, FALSE, 'Resolve a synthetic payment return with the governed retry.'),
        ('HOLD_FOR_ACCOUNT_STATE_REVIEW', 4, FALSE, FALSE, TRUE, FALSE, 'Certify and retain the account on review hold.'),
        ('ESCALATE_UNRESOLVED_PAYMENT_EXCEPTION', 5, TRUE, FALSE, TRUE, FALSE, 'Escalate an unresolved synthetic payment exception.'),
        ('BLOCK_ACCOUNT_STATE_CERTIFICATION', 9, FALSE, FALSE, FALSE, TRUE, 'Block account-state certification.')
 ) AS v(resolution_action_code,resolution_action_rank,exception_case_flag,retry_resolution_flag,review_hold_flag,certification_block_flag,description)
), hashed AS(SELECT seed.*,msbf_ctl.m2_9_hash_jsonb(to_jsonb(seed)) AS row_hash FROM seed)
INSERT INTO msbf_m2.exception_resolution_action_definition
(module1_run_id,resolution_action_code,resolution_action_rank,exception_case_flag,retry_resolution_flag,review_hold_flag,
certification_block_flag,real_funds_moved_flag,external_system_called_flag,definition_status,description,row_hash)
SELECT module1_run_id,resolution_action_code,resolution_action_rank,exception_case_flag,retry_resolution_flag,review_hold_flag,
certification_block_flag,real_funds_moved_flag,external_system_called_flag,definition_status,description,row_hash
FROM hashed ON CONFLICT(module1_run_id,resolution_action_code) DO NOTHING;

WITH rc AS(SELECT module1_run_id FROM msbf_ctl.m2_9_policy_profile WHERE policy_code='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1'), seed AS(
 SELECT rc.module1_run_id,v.certification_state_code::text,v.certification_state_rank::integer,v.state_certified_flag::boolean,
 v.active_state_flag::boolean,v.closed_state_flag::boolean,v.review_hold_state_flag::boolean,
 FALSE::boolean AS production_account_state_flag,'APPROVED'::text AS definition_status,v.description::text
 FROM rc CROSS JOIN(VALUES
 ('CERTIFIED_CLOSED_NO_PROCESSING', 0, TRUE, FALSE, TRUE, FALSE, 'Closed no-processing account state is certified.'),
        ('CERTIFIED_ACTIVE_CURRENT', 1, TRUE, TRUE, FALSE, FALSE, 'Active current account state is certified.'),
        ('CERTIFIED_ACTIVE_AFTER_RETRY', 2, TRUE, TRUE, FALSE, FALSE, 'Active account state after retry is certified.'),
        ('CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY', 3, TRUE, TRUE, FALSE, FALSE, 'Reassessment-due state after resolved retry is certified.'),
        ('CERTIFIED_REVIEW_HOLD', 4, TRUE, FALSE, FALSE, TRUE, 'Review-hold account state is certified.'),
        ('CERTIFICATION_PENDING', 5, FALSE, FALSE, FALSE, TRUE, 'Account-state certification remains pending.'),
        ('CERTIFICATION_FAILED', 9, FALSE, FALSE, FALSE, FALSE, 'Account-state certification failed.')
 ) AS v(certification_state_code,certification_state_rank,state_certified_flag,active_state_flag,closed_state_flag,review_hold_state_flag,description)
), hashed AS(SELECT seed.*,msbf_ctl.m2_9_hash_jsonb(to_jsonb(seed)) AS row_hash FROM seed)
INSERT INTO msbf_m2.account_state_certification_definition
(module1_run_id,certification_state_code,certification_state_rank,state_certified_flag,active_state_flag,closed_state_flag,
review_hold_state_flag,production_account_state_flag,definition_status,description,row_hash)
SELECT module1_run_id,certification_state_code,certification_state_rank,state_certified_flag,active_state_flag,closed_state_flag,
review_hold_state_flag,production_account_state_flag,definition_status,description,row_hash
FROM hashed ON CONFLICT(module1_run_id,certification_state_code) DO NOTHING;

WITH rc AS(SELECT module1_run_id FROM msbf_ctl.m2_9_policy_profile WHERE policy_code='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1'), seed AS(
 SELECT rc.module1_run_id,v.reconciliation_reason_code::text,v.mapped_outcome_code::text,v.mapped_action_code::text,
 FALSE::boolean AS real_execution_reason_flag,FALSE::boolean AS production_adverse_action_flag,
 'APPROVED'::text AS definition_status,v.description::text FROM rc CROSS JOIN(VALUES
 ('M2_9_REASON_SOURCE_NO_ACTIVITY', 'NO_PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_NO_PAYMENT_ACTIVITY', 'Accepted M2.8 source requires no payment reconciliation.'),
        ('M2_9_REASON_SOURCE_PAYMENT_ACTIVITY', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Accepted M2.8 source contains synthetic payment activity.'),
        ('M2_9_REASON_SOURCE_RETRY_RESOLVED', 'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY', 'RESOLVE_RETURN_WITH_RETRY', 'Accepted M2.8 source contains a returned payment resolved by retry.'),
        ('M2_9_REASON_SOURCE_REVIEW_HOLD', 'RECONCILIATION_REVIEW_HOLD', 'HOLD_FOR_ACCOUNT_STATE_REVIEW', 'Accepted M2.8 source remains on servicing review hold.'),
        ('M2_9_REASON_SOURCE_UNRESOLVED', 'RECONCILIATION_CERTIFICATION_FAILED', 'BLOCK_ACCOUNT_STATE_CERTIFICATION', 'Accepted source could not be reconciled.'),
        ('M2_9_REASON_SCHEDULED_AMOUNT_PRESENT', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Scheduled payment amount is present.'),
        ('M2_9_REASON_PROCESSED_AMOUNT_PRESENT', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Processed payment amount is present.'),
        ('M2_9_REASON_RETURN_DETECTED', 'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY', 'RESOLVE_RETURN_WITH_RETRY', 'A synthetic payment return is detected.'),
        ('M2_9_REASON_RETRY_DETECTED', 'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY', 'RESOLVE_RETURN_WITH_RETRY', 'A synthetic retry settlement is detected.'),
        ('M2_9_REASON_EXCEPTION_OPENED', 'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY', 'RESOLVE_RETURN_WITH_RETRY', 'A synthetic exception case is opened.'),
        ('M2_9_REASON_EXCEPTION_RESOLVED_BY_RETRY', 'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY', 'RESOLVE_RETURN_WITH_RETRY', 'The synthetic exception is resolved by retry.'),
        ('M2_9_REASON_NET_FORMULA_BALANCED', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Processed equals scheduled less returned plus retry.'),
        ('M2_9_REASON_CUMULATIVE_AMOUNT_BALANCED', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Cumulative processed amount reconciles.'),
        ('M2_9_REASON_ENDING_EXPOSURE_BALANCED', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Certified ending exposure reconciles to source.'),
        ('M2_9_REASON_LIFECYCLE_CLOSED_CERTIFIED', 'NO_PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_NO_PAYMENT_ACTIVITY', 'Closed no-processing lifecycle is certified.'),
        ('M2_9_REASON_LIFECYCLE_REASSESSMENT_CERTIFIED', 'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY', 'RESOLVE_RETURN_WITH_RETRY', 'Reassessment-due lifecycle is certified.'),
        ('M2_9_REASON_LIFECYCLE_REVIEW_CERTIFIED', 'RECONCILIATION_REVIEW_HOLD', 'HOLD_FOR_ACCOUNT_STATE_REVIEW', 'Review-hold lifecycle is certified.'),
        ('M2_9_REASON_SOURCE_HASH_PRESENT', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Accepted M2.8 account hash is present.'),
        ('M2_9_REASON_SOURCE_CONTRACT_ACCEPTED', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'M2.8 source contract is accepted.'),
        ('M2_9_REASON_PAYMENT_HASH_PRESENT', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Accepted M2.8 payment-event hash is present.'),
        ('M2_9_REASON_TRANSITION_HASH_PRESENT', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Accepted M2.8 transition hash is present.'),
        ('M2_9_REASON_HISTORY_PRESERVED', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Accepted M2.8 history is preserved.'),
        ('M2_9_REASON_NO_REAL_FUNDS', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'No real funds movement occurs.'),
        ('M2_9_REASON_NO_BANK_DATA', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'No bank-account data is present.'),
        ('M2_9_REASON_NO_NETWORK_TRANSMISSION', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'No ACH or payment-network transmission occurs.'),
        ('M2_9_REASON_NO_PROCESSOR_CALL', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'No external processor is called.'),
        ('M2_9_REASON_NO_MERCHANT_CONTACT', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'No merchant contact occurs.'),
        ('M2_9_REASON_NO_WRITE_OFF_COLLECTION', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'No write-off, collection, or legal execution occurs.'),
        ('M2_9_REASON_NO_EXTERNAL_NOTICE', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'No external notice is generated.'),
        ('M2_9_REASON_NO_ADVERSE_ACTION', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'No production adverse action occurs.'),
        ('M2_9_REASON_ZERO_RECONCILIATION_VARIANCE', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Payment reconciliation variance is zero.'),
        ('M2_9_REASON_ZERO_EXPOSURE_VARIANCE', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Certified exposure variance is zero.'),
        ('M2_9_REASON_ZERO_UNRESOLVED_EXCEPTIONS', 'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY', 'RESOLVE_RETURN_WITH_RETRY', 'No unresolved payment exceptions remain.'),
        ('M2_9_REASON_CERTIFICATION_READY', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'Account state is ready for certification.'),
        ('M2_9_REASON_CERTIFIED_REVIEW_HOLD', 'RECONCILIATION_REVIEW_HOLD', 'HOLD_FOR_ACCOUNT_STATE_REVIEW', 'Review-hold account state is certified.'),
        ('M2_9_REASON_SYNTHETIC_ONLY', 'PAYMENT_ACTIVITY_RECONCILED', 'CERTIFY_RECONCILED_PAYMENT_HISTORY', 'All reconciliation and certification evidence is synthetic.')
 ) AS v(reconciliation_reason_code,mapped_outcome_code,mapped_action_code,description)
), hashed AS(SELECT seed.*,msbf_ctl.m2_9_hash_jsonb(to_jsonb(seed)) AS row_hash FROM seed)
INSERT INTO msbf_m2.payment_reconciliation_reason_definition
(module1_run_id,reconciliation_reason_code,mapped_outcome_code,mapped_action_code,real_execution_reason_flag,
production_adverse_action_flag,definition_status,description,row_hash)
SELECT module1_run_id,reconciliation_reason_code,mapped_outcome_code,mapped_action_code,real_execution_reason_flag,
production_adverse_action_flag,definition_status,description,row_hash FROM hashed
ON CONFLICT(module1_run_id,reconciliation_reason_code) DO NOTHING;

/* ============================================================================
Section 8 — Consumption, comparison, exception, lineage, and canonical views
============================================================================ */
CREATE OR REPLACE VIEW msbf_m2.v_m2_9_reconciliation_certification_latest AS
SELECT latest.* FROM msbf_m2.application_payment_reconciliation_certification_latest AS latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_9_matched_scenario_comparison AS
WITH paired AS(
 SELECT module1_run_id,merchant_application_id,
 max(reconciliation_outcome_code) FILTER(WHERE scenario_code='BASELINE') AS baseline_reconciliation_outcome_code,
 max(reconciliation_outcome_code) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_reconciliation_outcome_code,
 max(certified_state_code) FILTER(WHERE scenario_code='BASELINE') AS baseline_certified_state_code,
 max(certified_state_code) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_certified_state_code,
 max(certified_exposure_amount) FILTER(WHERE scenario_code='BASELINE') AS baseline_certified_exposure_amount,
 max(certified_exposure_amount) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_certified_exposure_amount,
 bool_or(state_certified_flag) FILTER(WHERE scenario_code='BASELINE') AS baseline_state_certified_flag,
 bool_or(state_certified_flag) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_state_certified_flag,
 count(*) FILTER(WHERE scenario_code='BASELINE') AS baseline_rows,
 count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_rows
 FROM msbf_m2.application_payment_reconciliation_certification_latest
 GROUP BY module1_run_id,merchant_application_id
), ranked AS(
 SELECT paired.*,
 b.certification_state_rank AS baseline_certification_rank,
 s.certification_state_rank AS stress_certification_rank
 FROM paired
 JOIN msbf_m2.account_state_certification_definition AS b
  ON b.module1_run_id=paired.module1_run_id AND b.certification_state_code=paired.baseline_certified_state_code
 JOIN msbf_m2.account_state_certification_definition AS s
  ON s.module1_run_id=paired.module1_run_id AND s.certification_state_code=paired.stress_certified_state_code
 WHERE paired.baseline_rows=1 AND paired.stress_rows=1
)
SELECT ranked.*,
 (stress_state_certified_flag AND NOT baseline_state_certified_flag) AS stress_certification_permission_improvement_flag,
 (stress_certification_rank<baseline_certification_rank) AS stress_certification_rank_improvement_flag,
 (stress_certified_exposure_amount<baseline_certified_exposure_amount) AS stress_exposure_improvement_flag
FROM ranked;

CREATE OR REPLACE VIEW msbf_m2.v_m2_9_exception_resolution_ledger AS
SELECT * FROM msbf_m2.payment_exception_case_snapshot;

CREATE OR REPLACE VIEW msbf_m2.v_m2_9_power_bi_account_certification AS
SELECT module1_run_id,scenario_code,merchant_application_id,synthetic_account_id,synthetic_advance_id,
reconciliation_outcome_code,resolution_action_code,certified_state_code,state_certified_flag,
closed_state_flag,active_state_flag,review_hold_state_flag,exception_resolved_flag,
payment_event_count,scheduled_payment_amount,processed_payment_amount,returned_payment_amount,retry_payment_amount,
reconciliation_variance_amount,certified_exposure_amount,exposure_variance_amount,certification_date
FROM msbf_m2.application_payment_reconciliation_certification_latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_9_lineage AS
SELECT module1_run_id,scenario_id,scenario_code,merchant_application_id,synthetic_account_id,contract_code,contract_version,
source_contract_row_hash,account_source_row_hash,account_reconciliation_row_hash,state_certification_row_hash,contract_row_hash
FROM msbf_m2.application_payment_reconciliation_certification_latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_9_canonical_entity AS
SELECT module1_run_id,'POLICY'::text AS entity_type,policy_code||'|v'||policy_version::text AS entity_key,row_hash FROM msbf_ctl.m2_9_policy_profile
UNION ALL SELECT module1_run_id,'RECONCILIATION_OUTCOME',reconciliation_outcome_code,row_hash FROM msbf_m2.payment_reconciliation_outcome_definition
UNION ALL SELECT module1_run_id,'RESOLUTION_ACTION',resolution_action_code,row_hash FROM msbf_m2.exception_resolution_action_definition
UNION ALL SELECT module1_run_id,'CERTIFICATION_STATE',certification_state_code,row_hash FROM msbf_m2.account_state_certification_definition
UNION ALL SELECT module1_run_id,'REASON_DEFINITION',reconciliation_reason_code,row_hash FROM msbf_m2.payment_reconciliation_reason_definition
UNION ALL SELECT module1_run_id,'ACCOUNT_SOURCE',scenario_id::text||'|'||merchant_application_id,row_hash FROM msbf_m2.account_reconciliation_source_snapshot
UNION ALL SELECT module1_run_id,'PAYMENT_SOURCE',scenario_id::text||'|'||merchant_application_id||'|'||event_sequence::text,row_hash FROM msbf_m2.payment_reconciliation_source_event
UNION ALL SELECT module1_run_id,'TRANSITION_SOURCE',scenario_id::text||'|'||merchant_application_id||'|'||transition_sequence::text,row_hash FROM msbf_m2.lifecycle_certification_source_transition
UNION ALL SELECT module1_run_id,'PAYMENT_RECONCILIATION',scenario_id::text||'|'||merchant_application_id||'|'||event_sequence::text,row_hash FROM msbf_m2.payment_event_reconciliation_snapshot
UNION ALL SELECT module1_run_id,'EXCEPTION_CASE',scenario_id::text||'|'||merchant_application_id||'|'||synthetic_exception_case_id,row_hash FROM msbf_m2.payment_exception_case_snapshot
UNION ALL SELECT module1_run_id,'ACCOUNT_RECONCILIATION',scenario_id::text||'|'||merchant_application_id,row_hash FROM msbf_m2.account_payment_reconciliation_snapshot
UNION ALL SELECT module1_run_id,'STATE_CERTIFICATION',scenario_id::text||'|'||merchant_application_id,row_hash FROM msbf_m2.account_state_certification_snapshot
UNION ALL SELECT module1_run_id,'PORTFOLIO_SUMMARY',scenario_code,row_hash FROM msbf_m2.payment_reconciliation_portfolio_summary
UNION ALL SELECT module1_run_id,'LATEST',scenario_id::text||'|'||merchant_application_id,contract_row_hash FROM msbf_m2.application_payment_reconciliation_certification_latest
UNION ALL SELECT module1_run_id,'ARCHIVE',scenario_id::text||'|'||merchant_application_id,archive_row_hash FROM msbf_m2.application_payment_reconciliation_certification_archive
UNION ALL SELECT module1_run_id,'REGISTRY',contract_code||'|v'||contract_version::text,row_hash FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry;

CREATE OR REPLACE VIEW msbf_m2.v_m2_9_canonical_hash AS
SELECT module1_run_id,count(*)::bigint AS canonical_entities,
md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'|' ORDER BY entity_type,entity_key)) AS combined_set_hash
FROM msbf_m2.v_m2_9_canonical_entity GROUP BY module1_run_id;

/* ============================================================================
Section 9 — Final schema and policy checkpoint
============================================================================ */
DO $m2_9_schema_guard$
DECLARE vr bigint; vg bigint; vo bigint; va bigint; vc bigint; vrs bigint;
BEGIN
 SELECT module1_run_id INTO vr FROM msbf_ctl.m2_9_policy_profile WHERE policy_code='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1';
 PERFORM msbf_ctl.m2_9_assert_configuration(vr);
 SELECT count(*) INTO vg FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND active_flag;
 SELECT count(*) INTO vo FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=vr AND definition_status='APPROVED';
 SELECT count(*) INTO va FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=vr AND definition_status='APPROVED';
 SELECT count(*) INTO vc FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=vr AND definition_status='APPROVED';
 SELECT count(*) INTO vrs FROM msbf_m2.payment_reconciliation_reason_definition WHERE module1_run_id=vr AND definition_status='APPROVED';
 IF vg<>1 OR vo<>7 OR va<>7 OR vc<>7 OR vrs<>36
 THEN RAISE EXCEPTION 'M2.9 schema/policy extension failed: gate %, outcomes %, actions %, certifications %, reasons %.',vg,vo,va,vc,vrs; END IF;
END;$m2_9_schema_guard$;
COMMIT;

SELECT policy.module1_run_id,policy.policy_code,policy.policy_version,policy.policy_status,
policy.methodology_version,policy.contract_code,policy.contract_version,policy.schema_version,
policy.source_contract_code,policy.source_schema_version,policy.source_acceptance_gate_id,
policy.source_combined_set_hash,policy.configuration_hash,
(SELECT count(*) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND active_flag) AS acceptance_gate_catalog_rows,
(SELECT count(*) FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=policy.module1_run_id) AS reconciliation_outcome_definition_rows,
(SELECT count(*) FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=policy.module1_run_id) AS resolution_action_definition_rows,
(SELECT count(*) FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=policy.module1_run_id) AS certification_state_definition_rows,
(SELECT count(*) FROM msbf_m2.payment_reconciliation_reason_definition WHERE module1_run_id=policy.module1_run_id) AS reason_definition_rows,
CASE WHEN policy.policy_status='APPROVED' AND policy.synthetic_data_only_flag AND policy.reconciliation_certification_only_flag
AND policy.preserve_m2_8_history_flag AND policy.no_real_funds_movement_flag AND policy.no_bank_account_data_flag
AND policy.no_ach_or_network_transmission_flag AND policy.no_external_processor_call_flag
AND policy.no_real_merchant_contact_flag AND policy.no_write_off_or_collection_execution_flag
AND policy.no_external_notice_generation_flag AND policy.no_production_adverse_action_flag
THEN 'PASS' ELSE 'FAIL' END AS schema_policy_status
FROM msbf_ctl.m2_9_policy_profile AS policy WHERE policy.policy_code='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1';
