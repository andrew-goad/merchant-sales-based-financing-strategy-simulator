/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.7 — Operational Activation & Account Setup
============================================================================ */

/* ============================================================================
Program     : 180_msbf_m2_7_schema_policy_operational_setup_extension_v0_2.sql
Version     : v0.2

Purpose
-------
Create the governed M2.7 physical, policy, reference, contract, lineage,
archive, comparison, and canonical-hash layer.

Stage boundary
--------------
M2.7 creates synthetic operational setup blueprints only. It does not create
a real core account, alter a real payment obligation, use bank-account or
routing data, transmit ACH/network instructions, contact a merchant, post a
write-off, refer an account to collections, initiate legal action, or generate
an external or production adverse-action notice.

Required result
---------------
schema_policy_status = PASS.
============================================================================ */

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '30min';
SET LOCAL jit = off;

CREATE SCHEMA IF NOT EXISTS msbf_ctl;
CREATE SCHEMA IF NOT EXISTS msbf_m2;

/* Section 1 — Deterministic utilities. */

CREATE OR REPLACE FUNCTION msbf_ctl.m2_7_hash_jsonb(p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $function$
    SELECT md5(p_payload::text);
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_7_registry_row_hash(p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $function$
    SELECT msbf_ctl.m2_7_hash_jsonb
    (
        p_payload
        - 'registry_id'
        - 'contract_status'
        - 'generated_at'
        - 'validated_at'
        - 'accepted_at'
        - 'contract_set_hash'
        - 'combined_set_hash'
        - 'row_hash'
        - 'created_at'
    );
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_7_assert_no_real_operational_payload
(
    p_payload jsonb
)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_key text;
BEGIN
    SELECT key
    INTO v_key
    FROM jsonb_object_keys(coalesce(p_payload,'{}'::jsonb)) AS key
    WHERE lower(key) IN
    (
        'real_core_account_number',
        'core_account_id',
        'bank_account_number',
        'routing_number',
        'settlement_account_number',
        'ach_trace_number',
        'payment_network_confirmation',
        'real_payment_change',
        'real_payment_instruction',
        'merchant_contact_executed',
        'write_off_posted',
        'charge_off_posted',
        'collection_agency_referral',
        'legal_action_executed',
        'external_notice_payload',
        'production_adverse_action_notice'
    )
    LIMIT 1;

    IF v_key IS NOT NULL THEN
        RAISE EXCEPTION
            'M2.7 rejected prohibited operational payload key %.',
            v_key;
    END IF;
END;
$function$;

/* Section 2 — Governed policy and definitions. */

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_7_policy_profile
(
    module1_run_id bigint PRIMARY KEY,
    policy_code text NOT NULL,
    policy_version integer NOT NULL,
    policy_status text NOT NULL,
    methodology_version text NOT NULL,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,

    source_registry_name text NOT NULL,
    source_latest_name text NOT NULL,
    source_contract_code text NOT NULL,
    source_contract_version integer NOT NULL,
    source_schema_version text NOT NULL,
    source_acceptance_gate_id text NOT NULL,
    source_combined_set_hash text NOT NULL,

    synthetic_data_only_flag boolean NOT NULL,
    simulated_operational_setup_only_flag boolean NOT NULL,
    preserve_m2_6_history_flag boolean NOT NULL,
    no_real_core_account_creation_flag boolean NOT NULL,
    no_real_payment_change_execution_flag boolean NOT NULL,
    no_bank_account_data_flag boolean NOT NULL,
    no_ach_or_network_transmission_flag boolean NOT NULL,
    no_external_notice_generation_flag boolean NOT NULL,
    no_merchant_contact_execution_flag boolean NOT NULL,
    no_write_off_posting_flag boolean NOT NULL,
    no_collection_or_legal_execution_flag boolean NOT NULL,

    default_temporary_payment_factor numeric(9,6) NOT NULL,
    default_setup_duration_days integer NOT NULL,
    default_reassessment_interval_days integer NOT NULL,
    activation_effective_lag_days integer NOT NULL,

    expected_policy_rows bigint NOT NULL,
    expected_outcome_rows bigint NOT NULL,
    expected_action_rows bigint NOT NULL,
    expected_reason_rows bigint NOT NULL,
    expected_source_rows bigint NOT NULL,
    expected_activation_rows bigint NOT NULL,
    expected_account_setup_rows bigint NOT NULL,
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

    configuration_payload jsonb NOT NULL,
    configuration_hash text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT ck_m2_7_policy_identity CHECK
    (
        policy_code='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1'
        AND policy_version=1
        AND methodology_version='M2_7_METHOD_V1'
        AND contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
        AND contract_version=1
        AND schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
    ),

    CONSTRAINT ck_m2_7_policy_status CHECK
    (
        policy_status IN ('APPROVED','RETIRED')
    ),

    CONSTRAINT ck_m2_7_policy_boundaries CHECK
    (
        synthetic_data_only_flag
        AND simulated_operational_setup_only_flag
        AND preserve_m2_6_history_flag
        AND no_real_core_account_creation_flag
        AND no_real_payment_change_execution_flag
        AND no_bank_account_data_flag
        AND no_ach_or_network_transmission_flag
        AND no_external_notice_generation_flag
        AND no_merchant_contact_execution_flag
        AND no_write_off_posting_flag
        AND no_collection_or_legal_execution_flag
        AND default_temporary_payment_factor BETWEEN 0.10 AND 1.00
        AND default_setup_duration_days BETWEEN 1 AND 90
        AND default_reassessment_interval_days BETWEEN 1 AND 30
        AND activation_effective_lag_days BETWEEN 0 AND 30
    ),

    CONSTRAINT ck_m2_7_policy_hashes CHECK
    (
        length(configuration_hash)=32
        AND configuration_hash ~ '^[0-9a-f]+$'
        AND length(row_hash)=32
        AND row_hash ~ '^[0-9a-f]+$'
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.operational_setup_outcome_definition
(
    module1_run_id bigint NOT NULL,
    operational_setup_outcome_code text NOT NULL,
    operational_setup_outcome_rank integer NOT NULL,
    setup_authorized_flag boolean NOT NULL,
    blueprint_created_flag boolean NOT NULL,
    setup_review_required_flag boolean NOT NULL,
    no_setup_required_flag boolean NOT NULL,
    real_core_account_created_flag boolean NOT NULL,
    real_payment_change_executed_flag boolean NOT NULL,
    external_notice_generated_flag boolean NOT NULL,
    production_adverse_action_flag boolean NOT NULL,
    definition_status text NOT NULL,
    description text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id,operational_setup_outcome_code),

    CONSTRAINT ck_m2_7_outcome_rank CHECK
    (
        operational_setup_outcome_rank BETWEEN 0 AND 9
    ),

    CONSTRAINT ck_m2_7_outcome_status CHECK
    (
        definition_status IN ('APPROVED','RETIRED')
    ),

    CONSTRAINT ck_m2_7_outcome_exclusive CHECK
    (
        num_nonnulls
        (
            NULLIF(setup_authorized_flag,FALSE),
            NULLIF(setup_review_required_flag,FALSE),
            NULLIF(no_setup_required_flag,FALSE)
        )=1
        AND blueprint_created_flag=setup_authorized_flag
    ),

    CONSTRAINT ck_m2_7_outcome_no_execution CHECK
    (
        real_core_account_created_flag IS FALSE
        AND real_payment_change_executed_flag IS FALSE
        AND external_notice_generated_flag IS FALSE
        AND production_adverse_action_flag IS FALSE
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.operational_setup_action_definition
(
    module1_run_id bigint NOT NULL,
    operational_setup_action_code text NOT NULL,
    operational_setup_action_rank integer NOT NULL,
    account_blueprint_review_flag boolean NOT NULL,
    temporary_adjustment_setup_flag boolean NOT NULL,
    restructure_setup_flag boolean NOT NULL,
    recovery_setup_flag boolean NOT NULL,
    charge_off_setup_flag boolean NOT NULL,
    governance_review_flag boolean NOT NULL,

    real_core_account_created_flag boolean NOT NULL,
    real_payment_change_executed_flag boolean NOT NULL,
    ach_or_network_transmission_flag boolean NOT NULL,
    merchant_contact_executed_flag boolean NOT NULL,
    write_off_posted_flag boolean NOT NULL,
    collection_or_legal_executed_flag boolean NOT NULL,
    external_notice_generated_flag boolean NOT NULL,
    production_adverse_action_flag boolean NOT NULL,

    definition_status text NOT NULL,
    description text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id,operational_setup_action_code),

    CONSTRAINT ck_m2_7_action_rank CHECK
    (
        operational_setup_action_rank BETWEEN 0 AND 9
    ),

    CONSTRAINT ck_m2_7_action_status CHECK
    (
        definition_status IN ('APPROVED','RETIRED')
    ),

    CONSTRAINT ck_m2_7_action_no_execution CHECK
    (
        real_core_account_created_flag IS FALSE
        AND real_payment_change_executed_flag IS FALSE
        AND ach_or_network_transmission_flag IS FALSE
        AND merchant_contact_executed_flag IS FALSE
        AND write_off_posted_flag IS FALSE
        AND collection_or_legal_executed_flag IS FALSE
        AND external_notice_generated_flag IS FALSE
        AND production_adverse_action_flag IS FALSE
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.operational_setup_reason_definition
(
    module1_run_id bigint NOT NULL,
    operational_setup_reason_code text NOT NULL,
    mapped_outcome_code text NOT NULL,
    mapped_action_code text NOT NULL,
    executed_action_flag boolean NOT NULL,
    production_adverse_action_flag boolean NOT NULL,
    definition_status text NOT NULL,
    description text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id,operational_setup_reason_code),

    CONSTRAINT fk_m2_7_reason_outcome FOREIGN KEY
    (
        module1_run_id,mapped_outcome_code
    )
    REFERENCES msbf_m2.operational_setup_outcome_definition
    (
        module1_run_id,operational_setup_outcome_code
    ),

    CONSTRAINT fk_m2_7_reason_action FOREIGN KEY
    (
        module1_run_id,mapped_action_code
    )
    REFERENCES msbf_m2.operational_setup_action_definition
    (
        module1_run_id,operational_setup_action_code
    ),

    CONSTRAINT ck_m2_7_reason_status CHECK
    (
        definition_status IN ('APPROVED','RETIRED')
    ),

    CONSTRAINT ck_m2_7_reason_no_execution CHECK
    (
        executed_action_flag IS FALSE
        AND production_adverse_action_flag IS FALSE
    )
);

/* Section 3 — Source, activation, setup, latest, archive, and registry. */

CREATE TABLE IF NOT EXISTS msbf_m2.operational_activation_source_snapshot
(
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    merchant_id text NOT NULL,
    synthetic_account_id text NOT NULL,
    synthetic_advance_id text NOT NULL,

    source_strategy_outcome_code text NOT NULL,
    source_servicing_action_code text NOT NULL,
    source_recommended_action_flag boolean NOT NULL,
    source_review_required_flag boolean NOT NULL,
    source_recommended_action_exposure_amount numeric(18,2) NOT NULL,
    source_temporary_payment_factor numeric(9,6),
    source_review_duration_days integer,
    source_reassessment_interval_days integer,

    source_contract_row_hash text NOT NULL,
    source_combined_set_hash text NOT NULL,
    source_payload jsonb NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),

    CONSTRAINT ck_m2_7_source_amount CHECK
    (
        source_recommended_action_exposure_amount>=0
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_operational_activation_snapshot
(
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    merchant_id text NOT NULL,
    synthetic_account_id text NOT NULL,
    synthetic_advance_id text NOT NULL,

    source_strategy_outcome_code text NOT NULL,
    source_servicing_action_code text NOT NULL,
    source_recommended_action_exposure_amount numeric(18,2) NOT NULL,

    operational_setup_outcome_code text NOT NULL,
    operational_setup_action_code text NOT NULL,
    operational_setup_priority_rank integer NOT NULL,
    operational_setup_queue_code text NOT NULL,

    setup_authorized_flag boolean NOT NULL,
    blueprint_created_flag boolean NOT NULL,
    setup_review_required_flag boolean NOT NULL,
    no_setup_required_flag boolean NOT NULL,

    synthetic_operational_case_id text NOT NULL,
    primary_setup_reason_code text NOT NULL,
    setup_reason_codes jsonb NOT NULL,

    real_core_account_created_flag boolean NOT NULL,
    real_payment_change_executed_flag boolean NOT NULL,
    bank_account_data_present_flag boolean NOT NULL,
    ach_or_network_transmission_flag boolean NOT NULL,
    external_notice_generated_flag boolean NOT NULL,
    merchant_contact_executed_flag boolean NOT NULL,
    write_off_posted_flag boolean NOT NULL,
    collection_or_legal_executed_flag boolean NOT NULL,
    production_adverse_action_flag boolean NOT NULL,

    source_contract_row_hash text NOT NULL,
    source_snapshot_row_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),

    CONSTRAINT fk_m2_7_activation_outcome FOREIGN KEY
    (
        module1_run_id,operational_setup_outcome_code
    )
    REFERENCES msbf_m2.operational_setup_outcome_definition
    (
        module1_run_id,operational_setup_outcome_code
    ),

    CONSTRAINT fk_m2_7_activation_action FOREIGN KEY
    (
        module1_run_id,operational_setup_action_code
    )
    REFERENCES msbf_m2.operational_setup_action_definition
    (
        module1_run_id,operational_setup_action_code
    ),

    CONSTRAINT fk_m2_7_activation_reason FOREIGN KEY
    (
        module1_run_id,primary_setup_reason_code
    )
    REFERENCES msbf_m2.operational_setup_reason_definition
    (
        module1_run_id,operational_setup_reason_code
    ),

    CONSTRAINT ck_m2_7_activation_exclusive CHECK
    (
        num_nonnulls
        (
            NULLIF(setup_authorized_flag,FALSE),
            NULLIF(setup_review_required_flag,FALSE),
            NULLIF(no_setup_required_flag,FALSE)
        )=1
        AND blueprint_created_flag=setup_authorized_flag
    ),

    CONSTRAINT ck_m2_7_activation_no_execution CHECK
    (
        real_core_account_created_flag IS FALSE
        AND real_payment_change_executed_flag IS FALSE
        AND bank_account_data_present_flag IS FALSE
        AND ach_or_network_transmission_flag IS FALSE
        AND external_notice_generated_flag IS FALSE
        AND merchant_contact_executed_flag IS FALSE
        AND write_off_posted_flag IS FALSE
        AND collection_or_legal_executed_flag IS FALSE
        AND production_adverse_action_flag IS FALSE
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.operational_account_setup_snapshot
(
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    synthetic_account_id text NOT NULL,
    synthetic_advance_id text NOT NULL,

    operational_setup_outcome_code text NOT NULL,
    operational_setup_action_code text NOT NULL,
    account_setup_status_code text NOT NULL,
    operational_setup_queue_code text NOT NULL,

    synthetic_account_setup_id text NOT NULL,
    synthetic_servicing_plan_id text,
    operational_activation_date date,
    next_reassessment_date date,

    applied_temporary_payment_factor numeric(9,6),
    applied_setup_duration_days integer,
    applied_reassessment_interval_days integer,
    setup_parameter_payload jsonb NOT NULL,

    real_core_account_created_flag boolean NOT NULL,
    real_payment_change_executed_flag boolean NOT NULL,
    bank_account_data_present_flag boolean NOT NULL,
    ach_or_network_transmission_flag boolean NOT NULL,
    external_notice_generated_flag boolean NOT NULL,
    merchant_contact_executed_flag boolean NOT NULL,
    write_off_posted_flag boolean NOT NULL,
    collection_or_legal_executed_flag boolean NOT NULL,
    production_adverse_action_flag boolean NOT NULL,

    source_activation_row_hash text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),

    CONSTRAINT ck_m2_7_setup_status CHECK
    (
        account_setup_status_code IN
        (
            'NOT_REQUIRED',
            'SIMULATED_BLUEPRINT_READY',
            'OPERATIONAL_REVIEW_REQUIRED'
        )
    ),

    CONSTRAINT ck_m2_7_setup_plan_identity CHECK
    (
        (
            account_setup_status_code='SIMULATED_BLUEPRINT_READY'
            AND synthetic_servicing_plan_id IS NOT NULL
            AND operational_activation_date IS NOT NULL
            AND next_reassessment_date IS NOT NULL
        )
        OR
        (
            account_setup_status_code<>'SIMULATED_BLUEPRINT_READY'
            AND synthetic_servicing_plan_id IS NULL
            AND operational_activation_date IS NULL
            AND next_reassessment_date IS NULL
        )
    ),

    CONSTRAINT ck_m2_7_setup_no_execution CHECK
    (
        real_core_account_created_flag IS FALSE
        AND real_payment_change_executed_flag IS FALSE
        AND bank_account_data_present_flag IS FALSE
        AND ach_or_network_transmission_flag IS FALSE
        AND external_notice_generated_flag IS FALSE
        AND merchant_contact_executed_flag IS FALSE
        AND write_off_posted_flag IS FALSE
        AND collection_or_legal_executed_flag IS FALSE
        AND production_adverse_action_flag IS FALSE
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.operational_activation_portfolio_summary
(
    module1_run_id bigint NOT NULL,
    scenario_code text NOT NULL,
    source_rows bigint NOT NULL,
    setup_ready_rows bigint NOT NULL,
    review_required_rows bigint NOT NULL,
    no_setup_required_rows bigint NOT NULL,
    standard_setup_rows bigint NOT NULL,
    temporary_adjustment_setup_rows bigint NOT NULL,
    restructure_setup_rows bigint NOT NULL,
    recovery_setup_rows bigint NOT NULL,
    charge_off_setup_rows bigint NOT NULL,
    setup_authorized_amount numeric(24,2) NOT NULL,
    review_required_amount numeric(24,2) NOT NULL,
    maximum_setup_priority_rank integer NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id,scenario_code),

    CONSTRAINT ck_m2_7_portfolio_count_identity CHECK
    (
        setup_ready_rows+review_required_rows+no_setup_required_rows=source_rows
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_operational_activation_latest
(
    module1_run_id bigint NOT NULL,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    methodology_version text NOT NULL,

    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    merchant_id text NOT NULL,
    synthetic_account_id text NOT NULL,
    synthetic_advance_id text NOT NULL,

    source_strategy_outcome_code text NOT NULL,
    source_servicing_action_code text NOT NULL,
    source_recommended_action_exposure_amount numeric(18,2) NOT NULL,

    operational_setup_outcome_code text NOT NULL,
    operational_setup_action_code text NOT NULL,
    operational_setup_priority_rank integer NOT NULL,
    operational_setup_queue_code text NOT NULL,
    account_setup_status_code text NOT NULL,

    setup_authorized_flag boolean NOT NULL,
    blueprint_created_flag boolean NOT NULL,
    setup_review_required_flag boolean NOT NULL,
    no_setup_required_flag boolean NOT NULL,

    synthetic_operational_case_id text NOT NULL,
    synthetic_account_setup_id text NOT NULL,
    synthetic_servicing_plan_id text,
    operational_activation_date date,
    next_reassessment_date date,

    applied_temporary_payment_factor numeric(9,6),
    applied_setup_duration_days integer,
    applied_reassessment_interval_days integer,

    primary_setup_reason_code text NOT NULL,
    setup_reason_codes jsonb NOT NULL,
    setup_parameter_payload jsonb NOT NULL,

    source_contract_row_hash text NOT NULL,
    source_snapshot_row_hash text NOT NULL,
    activation_snapshot_row_hash text NOT NULL,
    account_setup_snapshot_row_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    contract_row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),

    CONSTRAINT ck_m2_7_latest_identity CHECK
    (
        contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
        AND contract_version=1
        AND schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
        AND methodology_version='M2_7_METHOD_V1'
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_operational_activation_archive
(
    archive_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id bigint NOT NULL,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    methodology_version text NOT NULL,

    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    merchant_id text NOT NULL,
    synthetic_account_id text NOT NULL,
    synthetic_advance_id text NOT NULL,

    source_strategy_outcome_code text NOT NULL,
    source_servicing_action_code text NOT NULL,
    source_recommended_action_exposure_amount numeric(18,2) NOT NULL,

    operational_setup_outcome_code text NOT NULL,
    operational_setup_action_code text NOT NULL,
    operational_setup_priority_rank integer NOT NULL,
    operational_setup_queue_code text NOT NULL,
    account_setup_status_code text NOT NULL,

    setup_authorized_flag boolean NOT NULL,
    blueprint_created_flag boolean NOT NULL,
    setup_review_required_flag boolean NOT NULL,
    no_setup_required_flag boolean NOT NULL,

    synthetic_operational_case_id text NOT NULL,
    synthetic_account_setup_id text NOT NULL,
    synthetic_servicing_plan_id text,
    operational_activation_date date,
    next_reassessment_date date,

    applied_temporary_payment_factor numeric(9,6),
    applied_setup_duration_days integer,
    applied_reassessment_interval_days integer,

    primary_setup_reason_code text NOT NULL,
    setup_reason_codes jsonb NOT NULL,
    setup_parameter_payload jsonb NOT NULL,

    source_contract_row_hash text NOT NULL,
    source_snapshot_row_hash text NOT NULL,
    activation_snapshot_row_hash text NOT NULL,
    account_setup_snapshot_row_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    contract_row_hash text NOT NULL,

    contract_payload jsonb NOT NULL,
    archive_row_hash text NOT NULL,
    archived_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    UNIQUE
    (
        module1_run_id,contract_version,scenario_id,merchant_application_id
    ),

    CONSTRAINT ck_m2_7_archive_identity CHECK
    (
        contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
        AND contract_version=1
        AND schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
        AND methodology_version='M2_7_METHOD_V1'
    )
);

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_7_operational_activation_contract_registry
(
    registry_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id bigint NOT NULL UNIQUE,

    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    methodology_version text NOT NULL,

    source_contract_code text NOT NULL,
    source_contract_version integer NOT NULL,
    source_schema_version text NOT NULL,
    source_acceptance_gate_id text NOT NULL,
    source_combined_set_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,

    policy_rows bigint NOT NULL,
    outcome_rows bigint NOT NULL,
    action_rows bigint NOT NULL,
    reason_rows bigint NOT NULL,
    source_rows bigint NOT NULL,
    activation_rows bigint NOT NULL,
    account_setup_rows bigint NOT NULL,
    portfolio_summary_rows bigint NOT NULL,
    latest_rows bigint NOT NULL,
    archive_rows bigint NOT NULL,
    comparison_rows bigint NOT NULL,
    registry_rows bigint NOT NULL,
    canonical_entities bigint NOT NULL,

    no_setup_required_rows bigint NOT NULL,
    standard_setup_rows bigint NOT NULL,
    temporary_adjustment_setup_rows bigint NOT NULL,
    restructure_setup_rows bigint NOT NULL,
    recovery_setup_rows bigint NOT NULL,
    charge_off_setup_rows bigint NOT NULL,
    review_required_rows bigint NOT NULL,
    setup_authorized_rows bigint NOT NULL,
    setup_authorized_amount numeric(24,2) NOT NULL,
    review_required_amount numeric(24,2) NOT NULL,

    policy_set_hash text NOT NULL,
    outcome_set_hash text NOT NULL,
    action_set_hash text NOT NULL,
    reason_set_hash text NOT NULL,
    source_set_hash text NOT NULL,
    activation_set_hash text NOT NULL,
    account_setup_set_hash text NOT NULL,
    portfolio_summary_set_hash text NOT NULL,
    latest_set_hash text NOT NULL,
    archive_set_hash text NOT NULL,
    contract_set_hash text NOT NULL,
    combined_set_hash text NOT NULL,

    contract_status text NOT NULL,
    generated_at timestamptz,
    validated_at timestamptz,
    accepted_at timestamptz,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT ck_m2_7_registry_identity CHECK
    (
        contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
        AND contract_version=1
        AND schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
        AND methodology_version='M2_7_METHOD_V1'
    ),

    CONSTRAINT ck_m2_7_registry_status CHECK
    (
        contract_status IN ('GENERATED','VALIDATED','ACCEPTED')
    )
);

/* Section 4 — Archive immutability, indexes, and lifecycle assertions. */

CREATE OR REPLACE FUNCTION msbf_ctl.m2_7_archive_immutable()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    RAISE EXCEPTION
        'M2.7 operational activation archive is immutable; % is not permitted.',
        TG_OP;
END;
$function$;

DROP TRIGGER IF EXISTS trg_m2_7_activation_archive_immutable
ON msbf_m2.application_operational_activation_archive;

CREATE TRIGGER trg_m2_7_activation_archive_immutable
BEFORE UPDATE OR DELETE
ON msbf_m2.application_operational_activation_archive
FOR EACH ROW
EXECUTE FUNCTION msbf_ctl.m2_7_archive_immutable();

CREATE INDEX IF NOT EXISTS ix_m2_7_source_account
ON msbf_m2.operational_activation_source_snapshot
(module1_run_id,synthetic_account_id);

CREATE INDEX IF NOT EXISTS ix_m2_7_activation_outcome
ON msbf_m2.application_operational_activation_snapshot
(module1_run_id,scenario_code,operational_setup_outcome_code);

CREATE INDEX IF NOT EXISTS ix_m2_7_setup_status
ON msbf_m2.operational_account_setup_snapshot
(module1_run_id,scenario_code,account_setup_status_code);

CREATE INDEX IF NOT EXISTS ix_m2_7_latest_outcome
ON msbf_m2.application_operational_activation_latest
(module1_run_id,scenario_code,operational_setup_outcome_code);

CREATE OR REPLACE FUNCTION msbf_ctl.m2_7_assert_configuration(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v record;
BEGIN
    SELECT *
    INTO v
    FROM msbf_ctl.m2_7_policy_profile
    WHERE module1_run_id=p_run_id;

    IF v.module1_run_id IS NULL
       OR v.policy_status<>'APPROVED'
       OR v.policy_code<>'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1'
       OR v.methodology_version<>'M2_7_METHOD_V1'
       OR v.contract_code<>'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
       OR v.contract_version<>1
       OR v.schema_version<>'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
       OR v.source_registry_name<>'msbf_ctl.m2_6_intervention_strategy_contract_registry'
       OR v.source_latest_name<>'msbf_m2.advance_intervention_strategy_latest'
       OR v.source_contract_code<>'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'
       OR v.source_schema_version<>'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1'
       OR v.source_acceptance_gate_id<>'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'
       OR v.source_combined_set_hash<>'868125bff29270490cab4d2e55cb1388'
       OR NOT v.synthetic_data_only_flag
       OR NOT v.simulated_operational_setup_only_flag
       OR NOT v.preserve_m2_6_history_flag
       OR NOT v.no_real_core_account_creation_flag
       OR NOT v.no_real_payment_change_execution_flag
       OR NOT v.no_bank_account_data_flag
       OR NOT v.no_ach_or_network_transmission_flag
       OR NOT v.no_external_notice_generation_flag
       OR NOT v.no_merchant_contact_execution_flag
       OR NOT v.no_write_off_posting_flag
       OR NOT v.no_collection_or_legal_execution_flag
       OR v.configuration_hash IS DISTINCT FROM
          msbf_ctl.m2_7_hash_jsonb(v.configuration_payload)
       OR v.row_hash IS DISTINCT FROM
          msbf_ctl.m2_7_hash_jsonb
          (
              to_jsonb(v)-'row_hash'-'created_at'-'updated_at'
          )
    THEN
        RAISE EXCEPTION
            'M2.7 configuration assertion failed for run_id %.',
            p_run_id;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_7_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_status text;
BEGIN
    PERFORM msbf_ctl.m2_7_assert_configuration(p_run_id);

    SELECT run_status
    INTO v_status
    FROM msbf_ctl.run_registry
    WHERE run_id=p_run_id;

    IF v_status<>'M2_6_ACCEPTED' THEN
        RAISE EXCEPTION
            'M2.7 generation requires M2_6_ACCEPTED; observed %.',
            v_status;
    END IF;

    IF EXISTS
    (
        SELECT 1 FROM msbf_m2.operational_activation_source_snapshot
        WHERE module1_run_id=p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.application_operational_activation_snapshot
        WHERE module1_run_id=p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.operational_account_setup_snapshot
        WHERE module1_run_id=p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.operational_activation_portfolio_summary
        WHERE module1_run_id=p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.application_operational_activation_latest
        WHERE module1_run_id=p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.application_operational_activation_archive
        WHERE module1_run_id=p_run_id
        UNION ALL
        SELECT 1 FROM msbf_ctl.m2_7_operational_activation_contract_registry
        WHERE module1_run_id=p_run_id
        UNION ALL
        SELECT 1 FROM msbf_ctl.run_evidence
        WHERE run_id=p_run_id AND evidence_code LIKE 'M2_7_%'
        UNION ALL
        SELECT 1 FROM msbf_ctl.acceptance_gate_result
        WHERE run_id=p_run_id AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
    )
    THEN
        RAISE EXCEPTION
            'M2.7 generation requires empty M2.7 targets for run_id %.',
            p_run_id;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_7_assert_validation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_status text;
    v_contract_status text;
BEGIN
    PERFORM msbf_ctl.m2_7_assert_configuration(p_run_id);

    SELECT run_status
    INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id=p_run_id;

    SELECT contract_status
    INTO v_contract_status
    FROM msbf_ctl.m2_7_operational_activation_contract_registry
    WHERE module1_run_id=p_run_id;

    IF NOT
    (
        (v_run_status='M2_7_GENERATED' AND v_contract_status='GENERATED')
        OR
        (v_run_status='M2_7_VALIDATED' AND v_contract_status='VALIDATED')
    )
    THEN
        RAISE EXCEPTION
            'M2.7 validation requires aligned generated or validated state; run %, contract %.',
            v_run_status,
            v_contract_status;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_7_assert_acceptance_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_status text;
    v_contract_status text;
    v_positive_passes bigint;
    v_negative_passes bigint;
BEGIN
    PERFORM msbf_ctl.m2_7_assert_configuration(p_run_id);

    SELECT run_status
    INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id=p_run_id;

    SELECT contract_status
    INTO v_contract_status
    FROM msbf_ctl.m2_7_operational_activation_contract_registry
    WHERE module1_run_id=p_run_id;

    SELECT
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_POS_%' AND status='PASS'
        ),
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_NEG_%' AND status='PASS'
        )
    INTO v_positive_passes,v_negative_passes
    FROM msbf_ctl.run_evidence
    WHERE run_id=p_run_id;

    IF v_run_status<>'M2_7_VALIDATED'
       OR v_contract_status<>'VALIDATED'
       OR v_positive_passes<>120
       OR v_negative_passes<>20
    THEN
        RAISE EXCEPTION
            'M2.7 acceptance not ready: run %, contract %, positive %, negative %.',
            v_run_status,
            v_contract_status,
            v_positive_passes,
            v_negative_passes;
    END IF;
END;
$function$;

/* Section 5 — Gate registration and governed policy/dictionary seeds. */

INSERT INTO msbf_ref.acceptance_gate_catalog
(
    gate_id,gate_name,module_code,severity,active_flag,description
)
VALUES
(
    'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP',
    'M2.7 Operational Activation & Account Setup',
    'M2.7',
    'BLOCKING',
    TRUE,
    'Accepts deterministic synthetic operational setup blueprints while prohibiting real account creation, payment changes, bank data, payment-network transmission, contact, write-off posting, collection/legal execution, and external or adverse-action notices.'
)
ON CONFLICT(gate_id)
DO UPDATE SET
    gate_name=EXCLUDED.gate_name,
    module_code=EXCLUDED.module_code,
    severity=EXCLUDED.severity,
    active_flag=EXCLUDED.active_flag,
    description=EXCLUDED.description;

WITH seed AS
(
    SELECT
        registry.module1_run_id::bigint AS module1_run_id,
        'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1'::text AS policy_code,
        1::integer AS policy_version,
        'APPROVED'::text AS policy_status,
        'M2_7_METHOD_V1'::text AS methodology_version,
        'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'::text AS contract_code,
        1::integer AS contract_version,
        'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'::text AS schema_version,

        'msbf_ctl.m2_6_intervention_strategy_contract_registry'::text AS source_registry_name,
        'msbf_m2.advance_intervention_strategy_latest'::text AS source_latest_name,
        'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'::text AS source_contract_code,
        1::integer AS source_contract_version,
        'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1'::text AS source_schema_version,
        'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'::text AS source_acceptance_gate_id,
        '868125bff29270490cab4d2e55cb1388'::text AS source_combined_set_hash,

        TRUE::boolean AS synthetic_data_only_flag,
        TRUE::boolean AS simulated_operational_setup_only_flag,
        TRUE::boolean AS preserve_m2_6_history_flag,
        TRUE::boolean AS no_real_core_account_creation_flag,
        TRUE::boolean AS no_real_payment_change_execution_flag,
        TRUE::boolean AS no_bank_account_data_flag,
        TRUE::boolean AS no_ach_or_network_transmission_flag,
        TRUE::boolean AS no_external_notice_generation_flag,
        TRUE::boolean AS no_merchant_contact_execution_flag,
        TRUE::boolean AS no_write_off_posting_flag,
        TRUE::boolean AS no_collection_or_legal_execution_flag,

        0.750000::numeric(9,6) AS default_temporary_payment_factor,
        14::integer AS default_setup_duration_days,
        7::integer AS default_reassessment_interval_days,
        1::integer AS activation_effective_lag_days,

        1::bigint AS expected_policy_rows,
        7::bigint AS expected_outcome_rows,
        7::bigint AS expected_action_rows,
        28::bigint AS expected_reason_rows,
        59::bigint AS expected_source_rows,
        59::bigint AS expected_activation_rows,
        59::bigint AS expected_account_setup_rows,
        2::bigint AS expected_portfolio_summary_rows,
        59::bigint AS expected_latest_rows,
        59::bigint AS expected_archive_rows,
        15::bigint AS expected_comparison_rows,
        1::bigint AS expected_registry_rows,
        341::bigint AS expected_canonical_entities,
        120::integer AS expected_positive_controls,
        20::integer AS expected_negative_controls,
        24::integer AS expected_generation_evidence_rows,
        24::integer AS expected_detail_result_sets,

        '{"acceptance_gate":"M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP","activation_effective_lag_days":1,"contract_code":"M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION","contract_version":1,"default_reassessment_interval_days":7,"default_setup_duration_days":14,"default_temporary_payment_factor":0.75,"expected":{"actions":7,"activation":59,"archive":59,"canonical":341,"comparison":15,"detail_sets":24,"generation_evidence":24,"latest":59,"negative":20,"outcomes":7,"policy":1,"portfolio":2,"positive":120,"reasons":28,"registry":1,"setup":59,"source":59},"methodology":"M2_7_METHOD_V1","no_ach_or_network_transmission":true,"no_bank_account_data":true,"no_collection_or_legal_execution":true,"no_external_notice_generation":true,"no_merchant_contact_execution":true,"no_real_core_account_creation":true,"no_real_payment_change_execution":true,"no_write_off_posting":true,"policy_code":"M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1","preserve_m2_6_history":true,"schema_version":"M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1","simulated_operational_setup_only":true,"source_combined_hash":"868125bff29270490cab4d2e55cb1388","source_contract":"M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION","source_gate":"M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY","source_latest":"msbf_m2.advance_intervention_strategy_latest","source_registry":"msbf_ctl.m2_6_intervention_strategy_contract_registry","source_schema":"M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1","synthetic_data_only":true}'::jsonb AS configuration_payload,
        msbf_ctl.m2_7_hash_jsonb('{"acceptance_gate":"M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP","activation_effective_lag_days":1,"contract_code":"M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION","contract_version":1,"default_reassessment_interval_days":7,"default_setup_duration_days":14,"default_temporary_payment_factor":0.75,"expected":{"actions":7,"activation":59,"archive":59,"canonical":341,"comparison":15,"detail_sets":24,"generation_evidence":24,"latest":59,"negative":20,"outcomes":7,"policy":1,"portfolio":2,"positive":120,"reasons":28,"registry":1,"setup":59,"source":59},"methodology":"M2_7_METHOD_V1","no_ach_or_network_transmission":true,"no_bank_account_data":true,"no_collection_or_legal_execution":true,"no_external_notice_generation":true,"no_merchant_contact_execution":true,"no_real_core_account_creation":true,"no_real_payment_change_execution":true,"no_write_off_posting":true,"policy_code":"M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1","preserve_m2_6_history":true,"schema_version":"M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1","simulated_operational_setup_only":true,"source_combined_hash":"868125bff29270490cab4d2e55cb1388","source_contract":"M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION","source_gate":"M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY","source_latest":"msbf_m2.advance_intervention_strategy_latest","source_registry":"msbf_ctl.m2_6_intervention_strategy_contract_registry","source_schema":"M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1","synthetic_data_only":true}'::jsonb)
            AS configuration_hash
    FROM msbf_ctl.m2_6_intervention_strategy_contract_registry AS registry
    JOIN msbf_ctl.run_registry AS run
      ON run.run_id=registry.module1_run_id
    WHERE run.run_code='M1_V0_2_BASELINE_BUILD'
      AND run.run_version=1
      AND run.run_status='M2_6_ACCEPTED'
      AND registry.contract_status='ACCEPTED'
      AND registry.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'
      AND registry.contract_version=1
      AND registry.schema_version='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1'
      AND registry.combined_set_hash='868125bff29270490cab4d2e55cb1388'
),
hashed AS
(
    SELECT
        seed.*,
        msbf_ctl.m2_7_hash_jsonb(to_jsonb(seed)) AS row_hash
    FROM seed
)
INSERT INTO msbf_ctl.m2_7_policy_profile
(
    module1_run_id,policy_code,policy_version,policy_status,
    methodology_version,contract_code,contract_version,schema_version,
    source_registry_name,source_latest_name,source_contract_code,
    source_contract_version,source_schema_version,
    source_acceptance_gate_id,source_combined_set_hash,
    synthetic_data_only_flag,simulated_operational_setup_only_flag,
    preserve_m2_6_history_flag,no_real_core_account_creation_flag,
    no_real_payment_change_execution_flag,no_bank_account_data_flag,
    no_ach_or_network_transmission_flag,no_external_notice_generation_flag,
    no_merchant_contact_execution_flag,no_write_off_posting_flag,
    no_collection_or_legal_execution_flag,
    default_temporary_payment_factor,default_setup_duration_days,
    default_reassessment_interval_days,activation_effective_lag_days,
    expected_policy_rows,expected_outcome_rows,expected_action_rows,
    expected_reason_rows,expected_source_rows,expected_activation_rows,
    expected_account_setup_rows,expected_portfolio_summary_rows,
    expected_latest_rows,expected_archive_rows,expected_comparison_rows,
    expected_registry_rows,expected_canonical_entities,
    expected_positive_controls,expected_negative_controls,
    expected_generation_evidence_rows,expected_detail_result_sets,
    configuration_payload,configuration_hash,row_hash
)
SELECT
    module1_run_id,policy_code,policy_version,policy_status,
    methodology_version,contract_code,contract_version,schema_version,
    source_registry_name,source_latest_name,source_contract_code,
    source_contract_version,source_schema_version,
    source_acceptance_gate_id,source_combined_set_hash,
    synthetic_data_only_flag,simulated_operational_setup_only_flag,
    preserve_m2_6_history_flag,no_real_core_account_creation_flag,
    no_real_payment_change_execution_flag,no_bank_account_data_flag,
    no_ach_or_network_transmission_flag,no_external_notice_generation_flag,
    no_merchant_contact_execution_flag,no_write_off_posting_flag,
    no_collection_or_legal_execution_flag,
    default_temporary_payment_factor,default_setup_duration_days,
    default_reassessment_interval_days,activation_effective_lag_days,
    expected_policy_rows,expected_outcome_rows,expected_action_rows,
    expected_reason_rows,expected_source_rows,expected_activation_rows,
    expected_account_setup_rows,expected_portfolio_summary_rows,
    expected_latest_rows,expected_archive_rows,expected_comparison_rows,
    expected_registry_rows,expected_canonical_entities,
    expected_positive_controls,expected_negative_controls,
    expected_generation_evidence_rows,expected_detail_result_sets,
    configuration_payload,configuration_hash,row_hash
FROM hashed
ON CONFLICT(module1_run_id) DO NOTHING;

WITH ctx AS
(
    SELECT module1_run_id
    FROM msbf_ctl.m2_7_policy_profile
    WHERE policy_code='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1'
),
seed AS
(
    SELECT
        ctx.module1_run_id,
        source.operational_setup_outcome_code::text,
        source.operational_setup_outcome_rank::integer,
        source.setup_authorized_flag::boolean,
        source.blueprint_created_flag::boolean,
        source.setup_review_required_flag::boolean,
        source.no_setup_required_flag::boolean,
        FALSE::boolean AS real_core_account_created_flag,
        FALSE::boolean AS real_payment_change_executed_flag,
        FALSE::boolean AS external_notice_generated_flag,
        FALSE::boolean AS production_adverse_action_flag,
        'APPROVED'::text AS definition_status,
        source.description::text
    FROM ctx
    CROSS JOIN
    (
        VALUES
        ('NO_OPERATIONAL_SETUP_REQUIRED', 0, FALSE, FALSE, FALSE, TRUE, 'Accepted source requires no operational account setup.'),
        ('STANDARD_SERVICING_SETUP_READY', 1, TRUE, TRUE, FALSE, FALSE, 'A synthetic standard-servicing setup blueprint is ready.'),
        ('TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY', 2, TRUE, TRUE, FALSE, FALSE, 'A synthetic temporary payment-adjustment setup blueprint is ready.'),
        ('RESTRUCTURE_SETUP_READY', 3, TRUE, TRUE, FALSE, FALSE, 'A synthetic restructure-account setup blueprint is ready.'),
        ('CONTROLLED_RECOVERY_SETUP_READY', 4, TRUE, TRUE, FALSE, FALSE, 'A synthetic controlled-recovery setup blueprint is ready.'),
        ('CHARGE_OFF_SETUP_READY', 5, TRUE, TRUE, FALSE, FALSE, 'A synthetic charge-off state blueprint is ready.'),
        ('OPERATIONAL_SETUP_REVIEW_REQUIRED', 9, FALSE, FALSE, TRUE, FALSE, 'An unresolved or review-only source requires operational governance.')
    ) AS source
    (
        operational_setup_outcome_code,
        operational_setup_outcome_rank,
        setup_authorized_flag,
        blueprint_created_flag,
        setup_review_required_flag,
        no_setup_required_flag,
        description
    )
),
hashed AS
(
    SELECT seed.*,msbf_ctl.m2_7_hash_jsonb(to_jsonb(seed)) AS row_hash
    FROM seed
)
INSERT INTO msbf_m2.operational_setup_outcome_definition
(
    module1_run_id,operational_setup_outcome_code,
    operational_setup_outcome_rank,setup_authorized_flag,
    blueprint_created_flag,setup_review_required_flag,
    no_setup_required_flag,real_core_account_created_flag,
    real_payment_change_executed_flag,external_notice_generated_flag,
    production_adverse_action_flag,definition_status,description,row_hash
)
SELECT
    module1_run_id,operational_setup_outcome_code,
    operational_setup_outcome_rank,setup_authorized_flag,
    blueprint_created_flag,setup_review_required_flag,
    no_setup_required_flag,real_core_account_created_flag,
    real_payment_change_executed_flag,external_notice_generated_flag,
    production_adverse_action_flag,definition_status,description,row_hash
FROM hashed
ON CONFLICT(module1_run_id,operational_setup_outcome_code) DO NOTHING;

WITH ctx AS
(
    SELECT module1_run_id
    FROM msbf_ctl.m2_7_policy_profile
    WHERE policy_code='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1'
),
seed AS
(
    SELECT
        ctx.module1_run_id,
        source.operational_setup_action_code::text,
        source.operational_setup_action_rank::integer,
        source.account_blueprint_review_flag::boolean,
        source.temporary_adjustment_setup_flag::boolean,
        source.restructure_setup_flag::boolean,
        source.recovery_setup_flag::boolean,
        source.charge_off_setup_flag::boolean,
        source.governance_review_flag::boolean,
        FALSE::boolean AS real_core_account_created_flag,
        FALSE::boolean AS real_payment_change_executed_flag,
        FALSE::boolean AS ach_or_network_transmission_flag,
        FALSE::boolean AS merchant_contact_executed_flag,
        FALSE::boolean AS write_off_posted_flag,
        FALSE::boolean AS collection_or_legal_executed_flag,
        FALSE::boolean AS external_notice_generated_flag,
        FALSE::boolean AS production_adverse_action_flag,
        'APPROVED'::text AS definition_status,
        source.description::text
    FROM ctx
    CROSS JOIN
    (
        VALUES
        ('CLOSE_WITHOUT_SETUP', 0, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, 'No operational setup is required.'),
        ('CREATE_STANDARD_SERVICING_BLUEPRINT', 1, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, 'Create a synthetic standard-servicing blueprint.'),
        ('CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT', 2, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, 'Create a synthetic temporary-adjustment blueprint.'),
        ('CREATE_RESTRUCTURE_BLUEPRINT', 3, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, 'Create a synthetic restructure blueprint.'),
        ('CREATE_RECOVERY_BLUEPRINT', 4, TRUE, FALSE, FALSE, TRUE, FALSE, FALSE, 'Create a synthetic controlled-recovery blueprint.'),
        ('CREATE_CHARGE_OFF_BLUEPRINT', 5, TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, 'Create a synthetic charge-off state blueprint.'),
        ('ROUTE_OPERATIONAL_GOVERNANCE_REVIEW', 9, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, 'Route an unresolved source to operational governance review.')
    ) AS source
    (
        operational_setup_action_code,
        operational_setup_action_rank,
        account_blueprint_review_flag,
        temporary_adjustment_setup_flag,
        restructure_setup_flag,
        recovery_setup_flag,
        charge_off_setup_flag,
        governance_review_flag,
        description
    )
),
hashed AS
(
    SELECT seed.*,msbf_ctl.m2_7_hash_jsonb(to_jsonb(seed)) AS row_hash
    FROM seed
)
INSERT INTO msbf_m2.operational_setup_action_definition
(
    module1_run_id,operational_setup_action_code,
    operational_setup_action_rank,account_blueprint_review_flag,
    temporary_adjustment_setup_flag,restructure_setup_flag,
    recovery_setup_flag,charge_off_setup_flag,governance_review_flag,
    real_core_account_created_flag,real_payment_change_executed_flag,
    ach_or_network_transmission_flag,merchant_contact_executed_flag,
    write_off_posted_flag,collection_or_legal_executed_flag,
    external_notice_generated_flag,production_adverse_action_flag,
    definition_status,description,row_hash
)
SELECT
    module1_run_id,operational_setup_action_code,
    operational_setup_action_rank,account_blueprint_review_flag,
    temporary_adjustment_setup_flag,restructure_setup_flag,
    recovery_setup_flag,charge_off_setup_flag,governance_review_flag,
    real_core_account_created_flag,real_payment_change_executed_flag,
    ach_or_network_transmission_flag,merchant_contact_executed_flag,
    write_off_posted_flag,collection_or_legal_executed_flag,
    external_notice_generated_flag,production_adverse_action_flag,
    definition_status,description,row_hash
FROM hashed
ON CONFLICT(module1_run_id,operational_setup_action_code) DO NOTHING;

WITH ctx AS
(
    SELECT module1_run_id
    FROM msbf_ctl.m2_7_policy_profile
    WHERE policy_code='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1'
),
seed AS
(
    SELECT
        ctx.module1_run_id,
        source.operational_setup_reason_code::text,
        source.mapped_outcome_code::text,
        source.mapped_action_code::text,
        FALSE::boolean AS executed_action_flag,
        FALSE::boolean AS production_adverse_action_flag,
        'APPROVED'::text AS definition_status,
        source.description::text
    FROM ctx
    CROSS JOIN
    (
        VALUES
        ('M2_7_REASON_SOURCE_NO_SETUP', 'NO_OPERATIONAL_SETUP_REQUIRED', 'CLOSE_WITHOUT_SETUP', 'Accepted M2.6 source requires no operational setup.'),
        ('M2_7_REASON_SOURCE_STANDARD_SETUP', 'STANDARD_SERVICING_SETUP_READY', 'CREATE_STANDARD_SERVICING_BLUEPRINT', 'Accepted M2.6 source maps to standard servicing setup.'),
        ('M2_7_REASON_SOURCE_TEMPORARY_ADJUSTMENT', 'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY', 'CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT', 'Accepted M2.6 source maps to temporary adjustment setup.'),
        ('M2_7_REASON_SOURCE_RESTRUCTURE', 'RESTRUCTURE_SETUP_READY', 'CREATE_RESTRUCTURE_BLUEPRINT', 'Accepted M2.6 source maps to restructure setup.'),
        ('M2_7_REASON_SOURCE_CONTROLLED_RECOVERY', 'CONTROLLED_RECOVERY_SETUP_READY', 'CREATE_RECOVERY_BLUEPRINT', 'Accepted M2.6 source maps to controlled recovery setup.'),
        ('M2_7_REASON_SOURCE_CHARGE_OFF', 'CHARGE_OFF_SETUP_READY', 'CREATE_CHARGE_OFF_BLUEPRINT', 'Accepted M2.6 source maps to charge-off setup.'),
        ('M2_7_REASON_SOURCE_REVIEW_ONLY', 'OPERATIONAL_SETUP_REVIEW_REQUIRED', 'ROUTE_OPERATIONAL_GOVERNANCE_REVIEW', 'Accepted M2.6 source remains recommendation-only and requires governance review.'),
        ('M2_7_REASON_SOURCE_UNRESOLVED', 'OPERATIONAL_SETUP_REVIEW_REQUIRED', 'ROUTE_OPERATIONAL_GOVERNANCE_REVIEW', 'Source authorization did not resolve to a governed mapping.'),
        ('M2_7_REASON_ACCOUNT_ID_PRESENT', 'STANDARD_SERVICING_SETUP_READY', 'CREATE_STANDARD_SERVICING_BLUEPRINT', 'Synthetic account identity is present.'),
        ('M2_7_REASON_ADVANCE_ID_PRESENT', 'STANDARD_SERVICING_SETUP_READY', 'CREATE_STANDARD_SERVICING_BLUEPRINT', 'Synthetic advance identity is present.'),
        ('M2_7_REASON_EXPOSURE_PRESENT', 'STANDARD_SERVICING_SETUP_READY', 'CREATE_STANDARD_SERVICING_BLUEPRINT', 'Positive source exposure is present.'),
        ('M2_7_REASON_EXPOSURE_ZERO', 'NO_OPERATIONAL_SETUP_REQUIRED', 'CLOSE_WITHOUT_SETUP', 'Source exposure is zero.'),
        ('M2_7_REASON_TEMPORARY_FACTOR_PRESENT', 'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY', 'CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT', 'Accepted temporary factor is present.'),
        ('M2_7_REASON_TEMPORARY_FACTOR_DEFAULTED', 'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY', 'CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT', 'Governed temporary factor default was applied.'),
        ('M2_7_REASON_DURATION_PRESENT', 'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY', 'CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT', 'Accepted review duration is present.'),
        ('M2_7_REASON_DURATION_DEFAULTED', 'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY', 'CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT', 'Governed review duration default was applied.'),
        ('M2_7_REASON_REASSESSMENT_PRESENT', 'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY', 'CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT', 'Accepted reassessment interval is present.'),
        ('M2_7_REASON_REASSESSMENT_DEFAULTED', 'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY', 'CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT', 'Governed reassessment default was applied.'),
        ('M2_7_REASON_BASELINE_SCENARIO', 'STANDARD_SERVICING_SETUP_READY', 'CREATE_STANDARD_SERVICING_BLUEPRINT', 'Record belongs to the baseline scenario.'),
        ('M2_7_REASON_STRESS_SCENARIO', 'OPERATIONAL_SETUP_REVIEW_REQUIRED', 'ROUTE_OPERATIONAL_GOVERNANCE_REVIEW', 'Record belongs to the governed stress scenario.'),
        ('M2_7_REASON_SOURCE_HASH_PRESENT', 'STANDARD_SERVICING_SETUP_READY', 'CREATE_STANDARD_SERVICING_BLUEPRINT', 'Accepted source row hash is present.'),
        ('M2_7_REASON_SOURCE_CONTRACT_ACCEPTED', 'STANDARD_SERVICING_SETUP_READY', 'CREATE_STANDARD_SERVICING_BLUEPRINT', 'M2.6 source contract is accepted.'),
        ('M2_7_REASON_SETUP_AUTHORIZED', 'STANDARD_SERVICING_SETUP_READY', 'CREATE_STANDARD_SERVICING_BLUEPRINT', 'Synthetic operational setup is authorized.'),
        ('M2_7_REASON_SETUP_NOT_AUTHORIZED', 'NO_OPERATIONAL_SETUP_REQUIRED', 'CLOSE_WITHOUT_SETUP', 'Synthetic operational setup is not authorized.'),
        ('M2_7_REASON_REVIEW_REQUIRED', 'OPERATIONAL_SETUP_REVIEW_REQUIRED', 'ROUTE_OPERATIONAL_GOVERNANCE_REVIEW', 'Operational governance review is required.'),
        ('M2_7_REASON_HISTORY_PRESERVED', 'STANDARD_SERVICING_SETUP_READY', 'CREATE_STANDARD_SERVICING_BLUEPRINT', 'Accepted M2.6 history is preserved.'),
        ('M2_7_REASON_REAL_EXECUTION_PROHIBITED', 'STANDARD_SERVICING_SETUP_READY', 'CREATE_STANDARD_SERVICING_BLUEPRINT', 'Real operational execution remains prohibited.'),
        ('M2_7_REASON_SYNTHETIC_ONLY', 'STANDARD_SERVICING_SETUP_READY', 'CREATE_STANDARD_SERVICING_BLUEPRINT', 'The operational setup is synthetic only.')
    ) AS source
    (
        operational_setup_reason_code,
        mapped_outcome_code,
        mapped_action_code,
        description
    )
),
hashed AS
(
    SELECT seed.*,msbf_ctl.m2_7_hash_jsonb(to_jsonb(seed)) AS row_hash
    FROM seed
)
INSERT INTO msbf_m2.operational_setup_reason_definition
(
    module1_run_id,operational_setup_reason_code,mapped_outcome_code,
    mapped_action_code,executed_action_flag,production_adverse_action_flag,
    definition_status,description,row_hash
)
SELECT
    module1_run_id,operational_setup_reason_code,mapped_outcome_code,
    mapped_action_code,executed_action_flag,production_adverse_action_flag,
    definition_status,description,row_hash
FROM hashed
ON CONFLICT(module1_run_id,operational_setup_reason_code) DO NOTHING;

/* Section 6 — Consumption, comparison, lineage, and canonical views. */

CREATE OR REPLACE VIEW msbf_m2.v_m2_7_operational_activation_latest
AS
SELECT
    latest.*,
    outcome.description AS outcome_description,
    action.description AS action_description
FROM msbf_m2.application_operational_activation_latest AS latest
JOIN msbf_m2.operational_setup_outcome_definition AS outcome
  ON outcome.module1_run_id=latest.module1_run_id
 AND outcome.operational_setup_outcome_code=
     latest.operational_setup_outcome_code
JOIN msbf_m2.operational_setup_action_definition AS action
  ON action.module1_run_id=latest.module1_run_id
 AND action.operational_setup_action_code=
     latest.operational_setup_action_code;

CREATE OR REPLACE VIEW msbf_m2.v_m2_7_matched_scenario_comparison
AS
SELECT
    baseline.module1_run_id,
    baseline.merchant_application_id,
    baseline.operational_setup_outcome_code
        AS baseline_operational_setup_outcome_code,
    stress.operational_setup_outcome_code
        AS stress_operational_setup_outcome_code,
    baseline.operational_setup_priority_rank
        AS baseline_operational_setup_priority_rank,
    stress.operational_setup_priority_rank
        AS stress_operational_setup_priority_rank,
    baseline.setup_authorized_flag AS baseline_setup_authorized_flag,
    stress.setup_authorized_flag AS stress_setup_authorized_flag,
    baseline.source_recommended_action_exposure_amount
        AS baseline_source_exposure_amount,
    stress.source_recommended_action_exposure_amount
        AS stress_source_exposure_amount,
    (
        stress.setup_authorized_flag
        AND NOT baseline.setup_authorized_flag
    ) AS stress_setup_permission_improvement_flag,
    (
        stress.operational_setup_priority_rank
        <
        baseline.operational_setup_priority_rank
    ) AS stress_priority_improvement_flag
FROM msbf_m2.application_operational_activation_latest AS baseline
JOIN msbf_m2.application_operational_activation_latest AS stress
  ON stress.module1_run_id=baseline.module1_run_id
 AND stress.merchant_application_id=baseline.merchant_application_id
 AND stress.scenario_code='RECESSION_ENERGY'
WHERE baseline.scenario_code='BASELINE';

CREATE OR REPLACE VIEW msbf_m2.v_m2_7_power_bi_operational_setup
AS
SELECT
    module1_run_id,scenario_code,merchant_application_id,
    synthetic_account_id,synthetic_advance_id,
    source_strategy_outcome_code,source_servicing_action_code,
    operational_setup_outcome_code,operational_setup_action_code,
    operational_setup_priority_rank,operational_setup_queue_code,
    account_setup_status_code,setup_authorized_flag,
    setup_review_required_flag,no_setup_required_flag,
    source_recommended_action_exposure_amount,
    operational_activation_date,next_reassessment_date
FROM msbf_m2.application_operational_activation_latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_7_lineage
AS
SELECT
    module1_run_id,scenario_id,scenario_code,merchant_application_id,
    synthetic_account_id,synthetic_advance_id,contract_code,
    contract_version,schema_version,source_contract_row_hash,
    source_snapshot_row_hash,activation_snapshot_row_hash,
    account_setup_snapshot_row_hash,contract_row_hash
FROM msbf_m2.application_operational_activation_latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_7_canonical_entity
AS
SELECT
    module1_run_id,'POLICY'::text AS entity_type,
    policy_code||'|v'||policy_version::text AS entity_key,row_hash
FROM msbf_ctl.m2_7_policy_profile
UNION ALL
SELECT module1_run_id,'OUTCOME_DEFINITION',
       operational_setup_outcome_code,row_hash
FROM msbf_m2.operational_setup_outcome_definition
UNION ALL
SELECT module1_run_id,'ACTION_DEFINITION',
       operational_setup_action_code,row_hash
FROM msbf_m2.operational_setup_action_definition
UNION ALL
SELECT module1_run_id,'REASON_DEFINITION',
       operational_setup_reason_code,row_hash
FROM msbf_m2.operational_setup_reason_definition
UNION ALL
SELECT module1_run_id,'SOURCE',
       scenario_id::text||'|'||merchant_application_id,row_hash
FROM msbf_m2.operational_activation_source_snapshot
UNION ALL
SELECT module1_run_id,'ACTIVATION',
       scenario_id::text||'|'||merchant_application_id,row_hash
FROM msbf_m2.application_operational_activation_snapshot
UNION ALL
SELECT module1_run_id,'ACCOUNT_SETUP',
       scenario_id::text||'|'||merchant_application_id,row_hash
FROM msbf_m2.operational_account_setup_snapshot
UNION ALL
SELECT module1_run_id,'PORTFOLIO_SUMMARY',scenario_code,row_hash
FROM msbf_m2.operational_activation_portfolio_summary
UNION ALL
SELECT module1_run_id,'LATEST',
       scenario_id::text||'|'||merchant_application_id,contract_row_hash
FROM msbf_m2.application_operational_activation_latest
UNION ALL
SELECT module1_run_id,'ARCHIVE',
       scenario_id::text||'|'||merchant_application_id,archive_row_hash
FROM msbf_m2.application_operational_activation_archive
UNION ALL
SELECT module1_run_id,'REGISTRY',
       contract_code||'|v'||contract_version::text,row_hash
FROM msbf_ctl.m2_7_operational_activation_contract_registry;

CREATE OR REPLACE VIEW msbf_m2.v_m2_7_canonical_hash
AS
SELECT
    module1_run_id,
    count(*)::bigint AS canonical_entities,
    md5
    (
        string_agg
        (
            entity_type||'|'||entity_key||'|'||row_hash,
            '|' ORDER BY entity_type,entity_key
        )
    ) AS combined_set_hash
FROM msbf_m2.v_m2_7_canonical_entity
GROUP BY module1_run_id;

/* Section 7 — Schema/policy guard and result. */

DO $m2_7_schema_guard$
DECLARE
    v_run_id bigint;
    v_gate bigint;
    v_outcomes bigint;
    v_actions bigint;
    v_reasons bigint;
BEGIN
    SELECT module1_run_id
    INTO v_run_id
    FROM msbf_ctl.m2_7_policy_profile
    WHERE policy_code='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1';

    PERFORM msbf_ctl.m2_7_assert_configuration(v_run_id);

    SELECT count(*) INTO v_gate
    FROM msbf_ref.acceptance_gate_catalog
    WHERE gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND active_flag;

    SELECT count(*) INTO v_outcomes
    FROM msbf_m2.operational_setup_outcome_definition
    WHERE module1_run_id=v_run_id AND definition_status='APPROVED';

    SELECT count(*) INTO v_actions
    FROM msbf_m2.operational_setup_action_definition
    WHERE module1_run_id=v_run_id AND definition_status='APPROVED';

    SELECT count(*) INTO v_reasons
    FROM msbf_m2.operational_setup_reason_definition
    WHERE module1_run_id=v_run_id AND definition_status='APPROVED';

    IF v_gate<>1
       OR v_outcomes<>7
       OR v_actions<>7
       OR v_reasons<>28
    THEN
        RAISE EXCEPTION
            'M2.7 schema/policy extension failed: gate %, outcomes %, actions %, reasons %.',
            v_gate,v_outcomes,v_actions,v_reasons;
    END IF;
END;
$m2_7_schema_guard$;

COMMIT;

SELECT
    policy.module1_run_id,policy.policy_code,policy.policy_version,
    policy.policy_status,policy.methodology_version,policy.contract_code,
    policy.contract_version,policy.schema_version,
    policy.source_contract_code,policy.source_schema_version,
    policy.source_acceptance_gate_id,policy.source_combined_set_hash,
    policy.configuration_hash,
    (
        SELECT count(*) FROM msbf_ref.acceptance_gate_catalog
        WHERE gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND active_flag
    ) AS acceptance_gate_catalog_rows,
    (
        SELECT count(*) FROM msbf_m2.operational_setup_outcome_definition
        WHERE module1_run_id=policy.module1_run_id
    ) AS outcome_definition_rows,
    (
        SELECT count(*) FROM msbf_m2.operational_setup_action_definition
        WHERE module1_run_id=policy.module1_run_id
    ) AS action_definition_rows,
    (
        SELECT count(*) FROM msbf_m2.operational_setup_reason_definition
        WHERE module1_run_id=policy.module1_run_id
    ) AS reason_definition_rows,
    CASE
        WHEN policy.policy_status='APPROVED'
         AND policy.synthetic_data_only_flag
         AND policy.simulated_operational_setup_only_flag
         AND policy.preserve_m2_6_history_flag
         AND policy.no_real_core_account_creation_flag
         AND policy.no_real_payment_change_execution_flag
         AND policy.no_bank_account_data_flag
         AND policy.no_ach_or_network_transmission_flag
         AND policy.no_external_notice_generation_flag
         AND policy.no_merchant_contact_execution_flag
         AND policy.no_write_off_posting_flag
         AND policy.no_collection_or_legal_execution_flag
        THEN 'PASS'
        ELSE 'FAIL'
    END AS schema_policy_status
FROM msbf_ctl.m2_7_policy_profile AS policy
WHERE policy.policy_code='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_POLICY_V1';
