/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 204_msbf_m2_10_schema_policy_portfolio_analytics_extension_v0_2.sql
Version     : v0.2

Purpose
-------
Create the governed M2.10 policy, KPI, performance-tier, servicing-queue, and
reason dictionaries; accepted M2.9 source, account-performance, portfolio
scope, KPI, queue, latest, archive, and registry structures; deterministic
hash and lifecycle assertions; archive immutability; and consumption,
comparison, Power BI, lineage, and canonical views.

Stage boundary
--------------
M2.10 is analytics-only. It does not regenerate accepted M2.9 evidence, make a
production decision, change an account, move funds, contact a merchant,
execute servicing, post accounting, perform collections or legal activity, or
generate an external notice or production adverse action.

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

CREATE OR REPLACE FUNCTION msbf_ctl.m2_10_hash_jsonb(p_payload jsonb)
RETURNS text LANGUAGE sql IMMUTABLE STRICT
AS $function$ SELECT md5(p_payload::text); $function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_10_registry_row_hash(p_payload jsonb)
RETURNS text LANGUAGE sql IMMUTABLE STRICT
AS $function$
    SELECT msbf_ctl.m2_10_hash_jsonb
    (
        p_payload
        - 'registry_id' - 'contract_status' - 'generated_at'
        - 'validated_at' - 'accepted_at' - 'row_hash' - 'created_at'
        - 'contract_set_hash' - 'combined_set_hash'
    );
$function$;

/* ============================================================================
Section 2 — Policy and governed dictionaries
============================================================================ */

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_10_policy_profile
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
    source_methodology_version text NOT NULL,
    source_policy_code text NOT NULL,
    source_acceptance_gate_id text NOT NULL,
    source_combined_set_hash text NOT NULL,

    synthetic_data_only_flag boolean NOT NULL,
    analytics_only_flag boolean NOT NULL,
    preserve_m2_9_history_flag boolean NOT NULL,
    no_production_decisioning_flag boolean NOT NULL,
    no_real_funds_movement_flag boolean NOT NULL,
    no_external_system_update_flag boolean NOT NULL,
    no_merchant_contact_flag boolean NOT NULL,
    no_write_off_collection_legal_flag boolean NOT NULL,

    closed_burden_units numeric(12,6) NOT NULL,
    active_burden_units numeric(12,6) NOT NULL,
    review_burden_units numeric(12,6) NOT NULL,
    rate_decimal_scale integer NOT NULL,

    expected_policy_rows bigint NOT NULL,
    expected_kpi_definition_rows bigint NOT NULL,
    expected_performance_tier_rows bigint NOT NULL,
    expected_servicing_queue_rows bigint NOT NULL,
    expected_reason_rows bigint NOT NULL,
    expected_source_rows bigint NOT NULL,
    expected_account_performance_rows bigint NOT NULL,
    expected_scope_summary_rows bigint NOT NULL,
    expected_kpi_snapshot_rows bigint NOT NULL,
    expected_queue_summary_rows bigint NOT NULL,
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

    CONSTRAINT ck_m2_10_policy_identity CHECK
    (
        policy_code='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_POLICY_V1' AND policy_version=1
        AND methodology_version='M2_10_METHOD_V1'
        AND contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND contract_version=1
        AND schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'
    ),
    CONSTRAINT ck_m2_10_policy_status CHECK
    (policy_status IN ('APPROVED','RETIRED')),
    CONSTRAINT ck_m2_10_policy_boundary CHECK
    (
        synthetic_data_only_flag AND analytics_only_flag
        AND preserve_m2_9_history_flag AND no_production_decisioning_flag
        AND no_real_funds_movement_flag AND no_external_system_update_flag
        AND no_merchant_contact_flag AND no_write_off_collection_legal_flag
        AND closed_burden_units=0
        AND active_burden_units>closed_burden_units
        AND review_burden_units>active_burden_units
        AND rate_decimal_scale BETWEEN 4 AND 10
    ),
    CONSTRAINT ck_m2_10_policy_hash CHECK
    (length(configuration_hash)=32 AND configuration_hash~'^[0-9a-f]+$'
     AND length(row_hash)=32 AND row_hash~'^[0-9a-f]+$')
);

CREATE TABLE IF NOT EXISTS msbf_m2.portfolio_kpi_definition
(
    module1_run_id bigint NOT NULL,
    kpi_code text NOT NULL,
    kpi_rank integer NOT NULL,
    unit_code text NOT NULL,
    zero_denominator_numeric_flag boolean NOT NULL,
    description text NOT NULL,
    definition_status text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,kpi_code),
    CONSTRAINT ck_m2_10_kpi_rank CHECK(kpi_rank BETWEEN 1 AND 99),
    CONSTRAINT ck_m2_10_kpi_status CHECK(definition_status IN ('APPROVED','RETIRED'))
);

CREATE TABLE IF NOT EXISTS msbf_m2.portfolio_performance_tier_definition
(
    module1_run_id bigint NOT NULL,
    performance_tier_code text NOT NULL,
    performance_tier_rank integer NOT NULL,
    burden_units numeric(12,6) NOT NULL,
    description text NOT NULL,
    definition_status text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,performance_tier_code),
    CONSTRAINT ck_m2_10_tier_rank CHECK(performance_tier_rank BETWEEN 0 AND 9),
    CONSTRAINT ck_m2_10_tier_burden CHECK(burden_units>=0),
    CONSTRAINT ck_m2_10_tier_status CHECK(definition_status IN ('APPROVED','RETIRED'))
);

CREATE TABLE IF NOT EXISTS msbf_m2.servicing_queue_definition
(
    module1_run_id bigint NOT NULL,
    servicing_queue_code text NOT NULL,
    servicing_queue_rank integer NOT NULL,
    burden_units numeric(12,6) NOT NULL,
    manual_review_flag boolean NOT NULL,
    description text NOT NULL,
    definition_status text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,servicing_queue_code),
    CONSTRAINT ck_m2_10_queue_rank CHECK(servicing_queue_rank BETWEEN 0 AND 9),
    CONSTRAINT ck_m2_10_queue_burden CHECK(burden_units>=0),
    CONSTRAINT ck_m2_10_queue_status CHECK(definition_status IN ('APPROVED','RETIRED'))
);

CREATE TABLE IF NOT EXISTS msbf_m2.portfolio_analytics_reason_definition
(
    module1_run_id bigint NOT NULL,
    portfolio_analytics_reason_code text NOT NULL,
    production_action_flag boolean NOT NULL,
    description text NOT NULL,
    definition_status text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,portfolio_analytics_reason_code),
    CONSTRAINT ck_m2_10_reason_status CHECK(definition_status IN ('APPROVED','RETIRED')),
    CONSTRAINT ck_m2_10_reason_boundary CHECK(production_action_flag IS FALSE)
);

/* ============================================================================
Section 3 — Accepted source and account-performance fact
============================================================================ */

CREATE TABLE IF NOT EXISTS msbf_m2.portfolio_performance_source_snapshot
(
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    merchant_id text NOT NULL,
    synthetic_account_id text NOT NULL,
    synthetic_advance_id text NOT NULL,
    source_final_lifecycle_state_code text NOT NULL,
    source_exposure_amount numeric(18,2) NOT NULL,
    payment_event_count integer NOT NULL,
    settled_event_count integer NOT NULL,
    returned_event_count integer NOT NULL,
    retry_event_count integer NOT NULL,
    scheduled_payment_amount numeric(18,2) NOT NULL,
    processed_payment_amount numeric(18,2) NOT NULL,
    returned_payment_amount numeric(18,2) NOT NULL,
    retry_payment_amount numeric(18,2) NOT NULL,
    reconciliation_variance_amount numeric(18,2) NOT NULL,
    exposure_variance_amount numeric(18,2) NOT NULL,
    exception_case_count integer NOT NULL,
    resolved_exception_count integer NOT NULL,
    unresolved_exception_count integer NOT NULL,
    reconciliation_outcome_code text NOT NULL,
    resolution_action_code text NOT NULL,
    certified_state_code text NOT NULL,
    state_certified_flag boolean NOT NULL,
    active_state_flag boolean NOT NULL,
    closed_state_flag boolean NOT NULL,
    review_hold_state_flag boolean NOT NULL,
    exception_resolved_flag boolean NOT NULL,
    certified_exposure_amount numeric(18,2) NOT NULL,
    certification_date date NOT NULL,
    primary_reconciliation_reason_code text NOT NULL,
    reconciliation_reason_codes jsonb NOT NULL,
    source_contract_row_hash text NOT NULL,
    source_combined_set_hash text NOT NULL,
    source_payload jsonb NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_10_source_nonnegative CHECK
    (
        payment_event_count>=0 AND settled_event_count>=0
        AND returned_event_count>=0 AND retry_event_count>=0
        AND exception_case_count>=0 AND resolved_exception_count>=0
        AND unresolved_exception_count>=0 AND source_exposure_amount>=0
        AND scheduled_payment_amount>=0 AND processed_payment_amount>=0
        AND returned_payment_amount>=0 AND retry_payment_amount>=0
        AND certified_exposure_amount>=0
    ),
    CONSTRAINT ck_m2_10_source_reasons CHECK(jsonb_typeof(reconciliation_reason_codes)='array')
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_portfolio_performance_snapshot
(
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    merchant_id text NOT NULL,
    synthetic_account_id text NOT NULL,
    synthetic_advance_id text NOT NULL,
    source_final_lifecycle_state_code text NOT NULL,
    certified_state_code text NOT NULL,
    state_certified_flag boolean NOT NULL,
    performance_tier_code text NOT NULL,
    servicing_queue_code text NOT NULL,
    payment_activity_flag boolean NOT NULL,
    exception_incident_flag boolean NOT NULL,
    exception_resolved_flag boolean NOT NULL,
    payment_event_count integer NOT NULL,
    settled_event_count integer NOT NULL,
    returned_event_count integer NOT NULL,
    retry_event_count integer NOT NULL,
    exception_case_count integer NOT NULL,
    resolved_exception_count integer NOT NULL,
    unresolved_exception_count integer NOT NULL,
    source_exposure_amount numeric(18,2) NOT NULL,
    certified_exposure_amount numeric(18,2) NOT NULL,
    scheduled_payment_amount numeric(18,2) NOT NULL,
    processed_payment_amount numeric(18,2) NOT NULL,
    returned_payment_amount numeric(18,2) NOT NULL,
    retry_payment_amount numeric(18,2) NOT NULL,
    reconciliation_variance_amount numeric(18,2) NOT NULL,
    exposure_variance_amount numeric(18,2) NOT NULL,
    gross_collection_rate numeric(18,6),
    return_rate numeric(18,6),
    retry_cure_rate numeric(18,6),
    exposure_retention_rate numeric(18,6),
    servicing_burden_units numeric(12,6) NOT NULL,
    primary_portfolio_reason_code text NOT NULL,
    portfolio_reason_codes jsonb NOT NULL,
    production_decision_executed_flag boolean NOT NULL,
    external_system_updated_flag boolean NOT NULL,
    merchant_contact_executed_flag boolean NOT NULL,
    source_contract_row_hash text NOT NULL,
    source_snapshot_row_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    FOREIGN KEY(module1_run_id,performance_tier_code)
      REFERENCES msbf_m2.portfolio_performance_tier_definition(module1_run_id,performance_tier_code),
    FOREIGN KEY(module1_run_id,servicing_queue_code)
      REFERENCES msbf_m2.servicing_queue_definition(module1_run_id,servicing_queue_code),
    FOREIGN KEY(module1_run_id,primary_portfolio_reason_code)
      REFERENCES msbf_m2.portfolio_analytics_reason_definition(module1_run_id,portfolio_analytics_reason_code),
    CONSTRAINT ck_m2_10_performance_reasons CHECK(jsonb_typeof(portfolio_reason_codes)='array'),
    CONSTRAINT ck_m2_10_performance_rates CHECK
    (
        (gross_collection_rate IS NULL OR gross_collection_rate>=0)
        AND (return_rate IS NULL OR return_rate>=0)
        AND (retry_cure_rate IS NULL OR retry_cure_rate>=0)
        AND (exposure_retention_rate IS NULL OR exposure_retention_rate>=0)
    ),
    CONSTRAINT ck_m2_10_performance_boundary CHECK
    (
        production_decision_executed_flag IS FALSE
        AND external_system_updated_flag IS FALSE
        AND merchant_contact_executed_flag IS FALSE
    )
);

/* ============================================================================
Section 4 — Scope, KPI, and servicing-queue analytics
============================================================================ */

CREATE TABLE IF NOT EXISTS msbf_m2.portfolio_performance_scope_summary
(
    module1_run_id bigint NOT NULL,
    scope_code text NOT NULL,
    scope_type text NOT NULL,
    scenario_code text,
    account_count bigint NOT NULL,
    certified_account_count bigint NOT NULL,
    active_account_count bigint NOT NULL,
    closed_account_count bigint NOT NULL,
    review_hold_account_count bigint NOT NULL,
    certified_exposure_amount numeric(24,2) NOT NULL,
    active_exposure_amount numeric(24,2) NOT NULL,
    review_hold_exposure_amount numeric(24,2) NOT NULL,
    scheduled_payment_amount numeric(24,2) NOT NULL,
    processed_payment_amount numeric(24,2) NOT NULL,
    returned_payment_amount numeric(24,2) NOT NULL,
    retry_payment_amount numeric(24,2) NOT NULL,
    reconciliation_variance_amount numeric(24,2) NOT NULL,
    exposure_variance_amount numeric(24,2) NOT NULL,
    exception_case_count bigint NOT NULL,
    resolved_exception_count bigint NOT NULL,
    unresolved_exception_count bigint NOT NULL,
    servicing_burden_units numeric(24,6) NOT NULL,
    certification_rate numeric(18,6) NOT NULL,
    gross_collection_rate numeric(18,6),
    return_rate numeric(18,6),
    retry_cure_rate numeric(18,6),
    exception_resolution_rate numeric(18,6),
    average_burden_per_account numeric(18,6) NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scope_code),
    CONSTRAINT ck_m2_10_scope_type CHECK(scope_type IN ('PORTFOLIO','SCENARIO')),
    CONSTRAINT ck_m2_10_scope_counts CHECK
    (
        account_count>=0 AND certified_account_count>=0
        AND active_account_count+closed_account_count+review_hold_account_count=account_count
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.portfolio_kpi_snapshot
(
    module1_run_id bigint NOT NULL,
    scope_code text NOT NULL,
    scope_type text NOT NULL,
    scenario_code text,
    kpi_code text NOT NULL,
    kpi_rank integer NOT NULL,
    unit_code text NOT NULL,
    applicable_flag boolean NOT NULL,
    kpi_value_numeric numeric(28,10),
    kpi_value_text text,
    numerator_value numeric(28,10),
    denominator_value numeric(28,10),
    primary_portfolio_reason_code text NOT NULL,
    source_scope_row_hash text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scope_code,kpi_code),
    FOREIGN KEY(module1_run_id,kpi_code)
      REFERENCES msbf_m2.portfolio_kpi_definition(module1_run_id,kpi_code),
    FOREIGN KEY(module1_run_id,primary_portfolio_reason_code)
      REFERENCES msbf_m2.portfolio_analytics_reason_definition(module1_run_id,portfolio_analytics_reason_code),
    CONSTRAINT ck_m2_10_kpi_value CHECK(num_nonnulls(kpi_value_numeric,kpi_value_text)=1),
    CONSTRAINT ck_m2_10_kpi_applicability CHECK
    (
        (applicable_flag AND kpi_value_numeric IS NOT NULL)
        OR (NOT applicable_flag AND kpi_value_text='NOT_APPLICABLE')
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.servicing_queue_analytics_snapshot
(
    module1_run_id bigint NOT NULL,
    servicing_queue_code text NOT NULL,
    account_count bigint NOT NULL,
    scenario_count bigint NOT NULL,
    certified_exposure_amount numeric(24,2) NOT NULL,
    payment_event_count bigint NOT NULL,
    exception_case_count bigint NOT NULL,
    resolved_exception_count bigint NOT NULL,
    unresolved_exception_count bigint NOT NULL,
    servicing_burden_units numeric(24,6) NOT NULL,
    maximum_tier_rank integer NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,servicing_queue_code),
    FOREIGN KEY(module1_run_id,servicing_queue_code)
      REFERENCES msbf_m2.servicing_queue_definition(module1_run_id,servicing_queue_code)
);

/* ============================================================================
Section 5 — Latest, archive, and registry
============================================================================ */

CREATE TABLE IF NOT EXISTS msbf_m2.application_portfolio_performance_latest
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
    source_final_lifecycle_state_code text NOT NULL,
    certified_state_code text NOT NULL,
    state_certified_flag boolean NOT NULL,
    performance_tier_code text NOT NULL,
    servicing_queue_code text NOT NULL,
    payment_activity_flag boolean NOT NULL,
    exception_incident_flag boolean NOT NULL,
    exception_resolved_flag boolean NOT NULL,
    payment_event_count integer NOT NULL,
    settled_event_count integer NOT NULL,
    returned_event_count integer NOT NULL,
    retry_event_count integer NOT NULL,
    exception_case_count integer NOT NULL,
    resolved_exception_count integer NOT NULL,
    unresolved_exception_count integer NOT NULL,
    source_exposure_amount numeric(18,2) NOT NULL,
    certified_exposure_amount numeric(18,2) NOT NULL,
    scheduled_payment_amount numeric(18,2) NOT NULL,
    processed_payment_amount numeric(18,2) NOT NULL,
    returned_payment_amount numeric(18,2) NOT NULL,
    retry_payment_amount numeric(18,2) NOT NULL,
    reconciliation_variance_amount numeric(18,2) NOT NULL,
    exposure_variance_amount numeric(18,2) NOT NULL,
    gross_collection_rate numeric(18,6),
    return_rate numeric(18,6),
    retry_cure_rate numeric(18,6),
    exposure_retention_rate numeric(18,6),
    servicing_burden_units numeric(12,6) NOT NULL,
    primary_portfolio_reason_code text NOT NULL,
    portfolio_reason_codes jsonb NOT NULL,
    source_contract_row_hash text NOT NULL,
    source_snapshot_row_hash text NOT NULL,
    performance_snapshot_row_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    contract_row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_10_latest_identity CHECK
    (
        contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND contract_version=1
        AND schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'
        AND methodology_version='M2_10_METHOD_V1'
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_portfolio_performance_archive
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
    source_final_lifecycle_state_code text NOT NULL,
    certified_state_code text NOT NULL,
    state_certified_flag boolean NOT NULL,
    performance_tier_code text NOT NULL,
    servicing_queue_code text NOT NULL,
    payment_activity_flag boolean NOT NULL,
    exception_incident_flag boolean NOT NULL,
    exception_resolved_flag boolean NOT NULL,
    payment_event_count integer NOT NULL,
    settled_event_count integer NOT NULL,
    returned_event_count integer NOT NULL,
    retry_event_count integer NOT NULL,
    exception_case_count integer NOT NULL,
    resolved_exception_count integer NOT NULL,
    unresolved_exception_count integer NOT NULL,
    source_exposure_amount numeric(18,2) NOT NULL,
    certified_exposure_amount numeric(18,2) NOT NULL,
    scheduled_payment_amount numeric(18,2) NOT NULL,
    processed_payment_amount numeric(18,2) NOT NULL,
    returned_payment_amount numeric(18,2) NOT NULL,
    retry_payment_amount numeric(18,2) NOT NULL,
    reconciliation_variance_amount numeric(18,2) NOT NULL,
    exposure_variance_amount numeric(18,2) NOT NULL,
    gross_collection_rate numeric(18,6),
    return_rate numeric(18,6),
    retry_cure_rate numeric(18,6),
    exposure_retention_rate numeric(18,6),
    servicing_burden_units numeric(12,6) NOT NULL,
    primary_portfolio_reason_code text NOT NULL,
    portfolio_reason_codes jsonb NOT NULL,
    source_contract_row_hash text NOT NULL,
    source_snapshot_row_hash text NOT NULL,
    performance_snapshot_row_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    contract_row_hash text NOT NULL,
    contract_payload jsonb NOT NULL,
    archive_row_hash text NOT NULL,
    archived_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE(module1_run_id,contract_version,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_10_archive_identity CHECK
    (
        contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND contract_version=1
        AND schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'
        AND methodology_version='M2_10_METHOD_V1'
    )
);

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_10_portfolio_analytics_contract_registry
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
    kpi_definition_rows bigint NOT NULL,
    performance_tier_rows bigint NOT NULL,
    servicing_queue_rows bigint NOT NULL,
    reason_rows bigint NOT NULL,
    source_rows bigint NOT NULL,
    account_performance_rows bigint NOT NULL,
    scope_summary_rows bigint NOT NULL,
    kpi_snapshot_rows bigint NOT NULL,
    queue_summary_rows bigint NOT NULL,
    latest_rows bigint NOT NULL,
    archive_rows bigint NOT NULL,
    comparison_rows bigint NOT NULL,
    registry_rows bigint NOT NULL,
    canonical_entities bigint NOT NULL,
    portfolio_account_rows bigint NOT NULL,
    baseline_account_rows bigint NOT NULL,
    stress_account_rows bigint NOT NULL,
    closed_stable_rows bigint NOT NULL,
    active_reconciled_rows bigint NOT NULL,
    controlled_review_rows bigint NOT NULL,
    no_servicing_queue_rows bigint NOT NULL,
    active_reassessment_queue_rows bigint NOT NULL,
    governance_review_queue_rows bigint NOT NULL,
    certified_account_rows bigint NOT NULL,
    certification_rate numeric(18,6) NOT NULL,
    certified_exposure_amount numeric(24,2) NOT NULL,
    active_exposure_amount numeric(24,2) NOT NULL,
    review_hold_exposure_amount numeric(24,2) NOT NULL,
    scheduled_payment_amount numeric(24,2) NOT NULL,
    processed_payment_amount numeric(24,2) NOT NULL,
    gross_collection_rate numeric(18,6) NOT NULL,
    returned_payment_amount numeric(24,2) NOT NULL,
    return_rate numeric(18,6) NOT NULL,
    retry_payment_amount numeric(24,2) NOT NULL,
    retry_cure_rate numeric(18,6) NOT NULL,
    reconciliation_variance_amount numeric(24,2) NOT NULL,
    exposure_variance_amount numeric(24,2) NOT NULL,
    exception_case_count bigint NOT NULL,
    resolved_exception_count bigint NOT NULL,
    exception_resolution_rate numeric(18,6) NOT NULL,
    unresolved_exception_count bigint NOT NULL,
    servicing_burden_units numeric(24,6) NOT NULL,
    average_burden_per_account numeric(18,6) NOT NULL,
    policy_set_hash text NOT NULL,
    kpi_definition_set_hash text NOT NULL,
    performance_tier_set_hash text NOT NULL,
    servicing_queue_set_hash text NOT NULL,
    reason_set_hash text NOT NULL,
    source_set_hash text NOT NULL,
    account_performance_set_hash text NOT NULL,
    scope_summary_set_hash text NOT NULL,
    kpi_snapshot_set_hash text NOT NULL,
    queue_summary_set_hash text NOT NULL,
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
    CONSTRAINT ck_m2_10_registry_identity CHECK
    (
        contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND contract_version=1
        AND schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'
        AND methodology_version='M2_10_METHOD_V1'
    ),
    CONSTRAINT ck_m2_10_registry_status CHECK
    (contract_status IN ('GENERATED','VALIDATED','ACCEPTED'))
);

/* ============================================================================
Section 6 — Immutability, indexes, and assertions
============================================================================ */

CREATE OR REPLACE FUNCTION msbf_ctl.m2_10_archive_immutable()
RETURNS trigger LANGUAGE plpgsql AS $function$
BEGIN
    RAISE EXCEPTION 'M2.10 portfolio performance archive is immutable; % is not permitted.',TG_OP;
END;
$function$;

DROP TRIGGER IF EXISTS trg_m2_10_portfolio_archive_immutable
ON msbf_m2.application_portfolio_performance_archive;
CREATE TRIGGER trg_m2_10_portfolio_archive_immutable
BEFORE UPDATE OR DELETE ON msbf_m2.application_portfolio_performance_archive
FOR EACH ROW EXECUTE FUNCTION msbf_ctl.m2_10_archive_immutable();

CREATE INDEX IF NOT EXISTS ix_m2_10_source_state
ON msbf_m2.portfolio_performance_source_snapshot
(module1_run_id,scenario_code,certified_state_code);
CREATE INDEX IF NOT EXISTS ix_m2_10_performance_tier
ON msbf_m2.application_portfolio_performance_snapshot
(module1_run_id,scenario_code,performance_tier_code);
CREATE INDEX IF NOT EXISTS ix_m2_10_performance_queue
ON msbf_m2.application_portfolio_performance_snapshot
(module1_run_id,servicing_queue_code);
CREATE INDEX IF NOT EXISTS ix_m2_10_kpi_scope
ON msbf_m2.portfolio_kpi_snapshot(module1_run_id,scope_code,kpi_rank);
CREATE INDEX IF NOT EXISTS ix_m2_10_latest_tier
ON msbf_m2.application_portfolio_performance_latest
(module1_run_id,scenario_code,performance_tier_code);

CREATE OR REPLACE FUNCTION msbf_ctl.m2_10_assert_configuration(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v msbf_ctl.m2_10_policy_profile%ROWTYPE;
BEGIN
    SELECT * INTO v FROM msbf_ctl.m2_10_policy_profile
    WHERE module1_run_id=p_run_id;
    IF v.module1_run_id IS NULL OR v.policy_status<>'APPROVED'
       OR v.policy_code<>'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_POLICY_V1'
       OR v.methodology_version<>'M2_10_METHOD_V1'
       OR v.contract_code<>'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' OR v.contract_version<>1
       OR v.schema_version<>'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'
       OR v.source_registry_name<>'msbf_ctl.m2_9_reconciliation_certification_contract_registry'
       OR v.source_latest_name<>'msbf_m2.application_payment_reconciliation_certification_latest'
       OR v.source_contract_code<>'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'
       OR v.source_schema_version<>'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'
       OR v.source_methodology_version<>'M2_9_METHOD_V1'
       OR v.source_policy_code<>'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1'
       OR v.source_acceptance_gate_id<>'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'
       OR v.source_combined_set_hash<>'6af76d0059b47623619ebc09330b15fe'
       OR NOT v.synthetic_data_only_flag OR NOT v.analytics_only_flag
       OR NOT v.preserve_m2_9_history_flag
       OR NOT v.no_production_decisioning_flag
       OR NOT v.no_real_funds_movement_flag
       OR NOT v.no_external_system_update_flag
       OR NOT v.no_merchant_contact_flag
       OR NOT v.no_write_off_collection_legal_flag
       OR v.configuration_hash IS DISTINCT FROM
          msbf_ctl.m2_10_hash_jsonb(v.configuration_payload)
       OR v.row_hash IS DISTINCT FROM
          msbf_ctl.m2_10_hash_jsonb(to_jsonb(v)-'row_hash'-'created_at'-'updated_at')
    THEN RAISE EXCEPTION 'M2.10 configuration assertion failed for run_id %.',p_run_id;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_10_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_status text;
BEGIN
    PERFORM msbf_ctl.m2_10_assert_configuration(p_run_id);
    SELECT run_status INTO v_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    IF v_status<>'M2_9_ACCEPTED' THEN
        RAISE EXCEPTION 'M2.10 generation requires M2_9_ACCEPTED; observed %.',v_status;
    END IF;
    IF EXISTS
    (
        SELECT 1 FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=p_run_id
        UNION ALL SELECT 1 FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=p_run_id
        UNION ALL SELECT 1 FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=p_run_id
        UNION ALL SELECT 1 FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=p_run_id
        UNION ALL SELECT 1 FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=p_run_id
        UNION ALL SELECT 1 FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=p_run_id
        UNION ALL SELECT 1 FROM msbf_m2.application_portfolio_performance_archive WHERE module1_run_id=p_run_id
        UNION ALL SELECT 1 FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=p_run_id
        UNION ALL SELECT 1 FROM msbf_ctl.run_evidence WHERE run_id=p_run_id AND evidence_code LIKE 'M2_10_%'
        UNION ALL SELECT 1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
    ) THEN RAISE EXCEPTION 'M2.10 generation requires empty targets for run_id %.',p_run_id;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_10_assert_validation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_run text; v_contract text;
BEGIN
    PERFORM msbf_ctl.m2_10_assert_configuration(p_run_id);
    SELECT run_status INTO v_run FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    SELECT contract_status INTO v_contract
    FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
    WHERE module1_run_id=p_run_id;
    IF NOT ((v_run='M2_10_GENERATED' AND v_contract='GENERATED')
       OR (v_run='M2_10_VALIDATED' AND v_contract='VALIDATED'))
    THEN RAISE EXCEPTION 'M2.10 validation state mismatch; run %, contract %.',v_run,v_contract;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_10_assert_acceptance_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_run text; v_contract text; v_positive bigint; v_negative bigint;
BEGIN
    PERFORM msbf_ctl.m2_10_assert_configuration(p_run_id);
    SELECT run_status INTO v_run FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    SELECT contract_status INTO v_contract
    FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
    WHERE module1_run_id=p_run_id;
    SELECT count(*) FILTER(WHERE evidence_code LIKE 'M2_10_POS_%' AND status='PASS'),
           count(*) FILTER(WHERE evidence_code LIKE 'M2_10_NEG_%' AND status='PASS')
    INTO v_positive,v_negative FROM msbf_ctl.run_evidence WHERE run_id=p_run_id;
    IF v_run<>'M2_10_VALIDATED' OR v_contract<>'VALIDATED'
       OR v_positive<>120 OR v_negative<>20
    THEN RAISE EXCEPTION 'M2.10 acceptance not ready; run %, contract %, positive %, negative %.',
        v_run,v_contract,v_positive,v_negative;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_10_assert_no_production_analytics_payload(p_payload jsonb)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_key text;
BEGIN
    SELECT key INTO v_key
    FROM jsonb_object_keys(coalesce(p_payload,'{}'::jsonb)) AS key
    WHERE lower(key) IN
    ('production_decision','production_strategy_change','real_funds_moved',
     'external_system_updated','merchant_contact_executed','write_off_posted',
     'collection_agency_referral','legal_action_executed',
     'external_notice_payload','production_adverse_action_notice')
    LIMIT 1;
    IF v_key IS NOT NULL THEN
        RAISE EXCEPTION 'M2.10 rejected prohibited analytics payload key %.',v_key;
    END IF;
END;
$function$;

/* ============================================================================
Section 7 — Acceptance gate and seeds
============================================================================ */

INSERT INTO msbf_ref.acceptance_gate_catalog
(gate_id,gate_name,module_code,severity,active_flag,description)
VALUES
('M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS','M2.10 Portfolio Performance, KPI & Servicing Analytics',
 'M2.10','BLOCKING',TRUE,
 'Accepts deterministic account-performance, portfolio KPI, queue, latest/archive, comparison, and canonical analytics while prohibiting production decisioning and execution.')
ON CONFLICT(gate_id) DO UPDATE SET
 gate_name=EXCLUDED.gate_name,module_code=EXCLUDED.module_code,
 severity=EXCLUDED.severity,active_flag=EXCLUDED.active_flag,
 description=EXCLUDED.description;

WITH seed AS
(
    SELECT registry.module1_run_id::bigint AS module1_run_id,
      'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_POLICY_V1'::text AS policy_code,1::integer AS policy_version,
      'APPROVED'::text AS policy_status,'M2_10_METHOD_V1'::text AS methodology_version,
      'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'::text AS contract_code,1::integer AS contract_version,
      'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'::text AS schema_version,
      'msbf_ctl.m2_9_reconciliation_certification_contract_registry'::text AS source_registry_name,
      'msbf_m2.application_payment_reconciliation_certification_latest'::text AS source_latest_name,
      'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'::text AS source_contract_code,
      1::integer AS source_contract_version,'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'::text AS source_schema_version,
      'M2_9_METHOD_V1'::text AS source_methodology_version,
      'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1'::text AS source_policy_code,
      'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'::text AS source_acceptance_gate_id,
      '6af76d0059b47623619ebc09330b15fe'::text AS source_combined_set_hash,
      TRUE::boolean AS synthetic_data_only_flag,
      TRUE::boolean AS analytics_only_flag,
      TRUE::boolean AS preserve_m2_9_history_flag,
      TRUE::boolean AS no_production_decisioning_flag,
      TRUE::boolean AS no_real_funds_movement_flag,
      TRUE::boolean AS no_external_system_update_flag,
      TRUE::boolean AS no_merchant_contact_flag,
      TRUE::boolean AS no_write_off_collection_legal_flag,
      0.000000::numeric(12,6) AS closed_burden_units,
      2.000000::numeric(12,6) AS active_burden_units,
      5.000000::numeric(12,6) AS review_burden_units,
      6::integer AS rate_decimal_scale,
      1::bigint AS expected_policy_rows,
      24::bigint AS expected_kpi_definition_rows,
      3::bigint AS expected_performance_tier_rows,
      3::bigint AS expected_servicing_queue_rows,
      24::bigint AS expected_reason_rows,
      59::bigint AS expected_source_rows,
      59::bigint AS expected_account_performance_rows,
      3::bigint AS expected_scope_summary_rows,
      72::bigint AS expected_kpi_snapshot_rows,
      3::bigint AS expected_queue_summary_rows,
      59::bigint AS expected_latest_rows,
      59::bigint AS expected_archive_rows,
      15::bigint AS expected_comparison_rows,
      1::bigint AS expected_registry_rows,
      370::bigint AS expected_canonical_entities,
      120::integer AS expected_positive_controls,
      20::integer AS expected_negative_controls,
      24::integer AS expected_generation_evidence_rows,
      24::integer AS expected_detail_result_sets,
      '{"acceptance_gate":"M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS","active_burden_units":2.0,"analytics_only":true,"closed_burden_units":0.0,"contract_code":"M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION","contract_version":1,"expected":{"account_performance_rows":59,"active_exposure_amount":"323.79","active_reassessment_queue_rows":1,"active_reconciled_rows":1,"archive_rows":59,"average_burden_per_account":"0.118644","baseline_account_rows":44,"canonical_entities":370,"certification_rate":"1.000000","certified_account_rows":59,"certified_exposure_amount":"785.48","closed_stable_rows":57,"comparison_rows":15,"controlled_review_rows":1,"detail_result_sets":24,"exception_case_count":1,"exception_resolution_rate":"1.000000","exposure_variance_amount":"0.00","generation_evidence_rows":24,"governance_review_queue_rows":1,"gross_collection_rate":"1.000000","kpi_definition_rows":24,"kpi_snapshot_rows":72,"latest_rows":59,"negative_controls":20,"no_servicing_queue_rows":57,"performance_tier_rows":3,"policy_rows":1,"portfolio_account_rows":59,"positive_controls":120,"processed_payment_amount":"194.25","queue_summary_rows":3,"reason_rows":24,"reconciliation_variance_amount":"0.00","registry_rows":1,"resolved_exception_count":1,"retry_cure_rate":"1.000000","retry_payment_amount":"27.75","return_rate":"0.142857","returned_payment_amount":"27.75","review_hold_exposure_amount":"461.69","scheduled_payment_amount":"194.25","scope_summary_rows":3,"servicing_burden_units":"7.000000","servicing_queue_rows":3,"source_rows":59,"stress_account_rows":15,"unresolved_exception_count":0},"methodology":"M2_10_METHOD_V1","no_external_system_update":true,"no_merchant_contact":true,"no_production_decisioning":true,"no_real_funds_movement":true,"no_write_off_collection_legal":true,"policy_code":"M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_POLICY_V1","preserve_m2_9_history":true,"rate_decimal_scale":6,"review_burden_units":5.0,"schema_version":"M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1","source_contract":"M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION","source_gate":"M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION","source_hash":"6af76d0059b47623619ebc09330b15fe","source_latest":"msbf_m2.application_payment_reconciliation_certification_latest","source_methodology":"M2_9_METHOD_V1","source_policy":"M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1","source_registry":"msbf_ctl.m2_9_reconciliation_certification_contract_registry","source_schema":"M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1","synthetic_data_only":true}'::jsonb AS configuration_payload,
      msbf_ctl.m2_10_hash_jsonb('{"acceptance_gate":"M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS","active_burden_units":2.0,"analytics_only":true,"closed_burden_units":0.0,"contract_code":"M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION","contract_version":1,"expected":{"account_performance_rows":59,"active_exposure_amount":"323.79","active_reassessment_queue_rows":1,"active_reconciled_rows":1,"archive_rows":59,"average_burden_per_account":"0.118644","baseline_account_rows":44,"canonical_entities":370,"certification_rate":"1.000000","certified_account_rows":59,"certified_exposure_amount":"785.48","closed_stable_rows":57,"comparison_rows":15,"controlled_review_rows":1,"detail_result_sets":24,"exception_case_count":1,"exception_resolution_rate":"1.000000","exposure_variance_amount":"0.00","generation_evidence_rows":24,"governance_review_queue_rows":1,"gross_collection_rate":"1.000000","kpi_definition_rows":24,"kpi_snapshot_rows":72,"latest_rows":59,"negative_controls":20,"no_servicing_queue_rows":57,"performance_tier_rows":3,"policy_rows":1,"portfolio_account_rows":59,"positive_controls":120,"processed_payment_amount":"194.25","queue_summary_rows":3,"reason_rows":24,"reconciliation_variance_amount":"0.00","registry_rows":1,"resolved_exception_count":1,"retry_cure_rate":"1.000000","retry_payment_amount":"27.75","return_rate":"0.142857","returned_payment_amount":"27.75","review_hold_exposure_amount":"461.69","scheduled_payment_amount":"194.25","scope_summary_rows":3,"servicing_burden_units":"7.000000","servicing_queue_rows":3,"source_rows":59,"stress_account_rows":15,"unresolved_exception_count":0},"methodology":"M2_10_METHOD_V1","no_external_system_update":true,"no_merchant_contact":true,"no_production_decisioning":true,"no_real_funds_movement":true,"no_write_off_collection_legal":true,"policy_code":"M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_POLICY_V1","preserve_m2_9_history":true,"rate_decimal_scale":6,"review_burden_units":5.0,"schema_version":"M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1","source_contract":"M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION","source_gate":"M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION","source_hash":"6af76d0059b47623619ebc09330b15fe","source_latest":"msbf_m2.application_payment_reconciliation_certification_latest","source_methodology":"M2_9_METHOD_V1","source_policy":"M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_POLICY_V1","source_registry":"msbf_ctl.m2_9_reconciliation_certification_contract_registry","source_schema":"M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1","synthetic_data_only":true}'::jsonb) AS configuration_hash
    FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry AS registry
    JOIN msbf_ctl.run_registry AS run ON run.run_id=registry.module1_run_id
    WHERE run.run_code='M1_V0_2_BASELINE_BUILD' AND run.run_version=1
      AND run.run_status='M2_9_ACCEPTED' AND registry.contract_status='ACCEPTED'
      AND registry.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND registry.contract_version=1
      AND registry.schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'
      AND registry.combined_set_hash='6af76d0059b47623619ebc09330b15fe'
), hashed AS
(
    SELECT seed.*,msbf_ctl.m2_10_hash_jsonb(to_jsonb(seed)) AS row_hash FROM seed
)
INSERT INTO msbf_ctl.m2_10_policy_profile
(
 module1_run_id,policy_code,policy_version,policy_status,methodology_version,
 contract_code,contract_version,schema_version,source_registry_name,
 source_latest_name,source_contract_code,source_contract_version,
 source_schema_version,source_methodology_version,source_policy_code,
 source_acceptance_gate_id,source_combined_set_hash,synthetic_data_only_flag,
 analytics_only_flag,preserve_m2_9_history_flag,no_production_decisioning_flag,
 no_real_funds_movement_flag,no_external_system_update_flag,
 no_merchant_contact_flag,no_write_off_collection_legal_flag,
 closed_burden_units,active_burden_units,review_burden_units,
 rate_decimal_scale,expected_policy_rows,expected_kpi_definition_rows,
 expected_performance_tier_rows,expected_servicing_queue_rows,
 expected_reason_rows,expected_source_rows,expected_account_performance_rows,
 expected_scope_summary_rows,expected_kpi_snapshot_rows,
 expected_queue_summary_rows,expected_latest_rows,expected_archive_rows,
 expected_comparison_rows,expected_registry_rows,expected_canonical_entities,
 expected_positive_controls,expected_negative_controls,
 expected_generation_evidence_rows,expected_detail_result_sets,
 configuration_payload,configuration_hash,row_hash,created_at,updated_at
)
SELECT module1_run_id,policy_code,policy_version,policy_status,
 methodology_version,contract_code,contract_version,schema_version,
 source_registry_name,source_latest_name,source_contract_code,
 source_contract_version,source_schema_version,source_methodology_version,
 source_policy_code,source_acceptance_gate_id,source_combined_set_hash,
 synthetic_data_only_flag,analytics_only_flag,preserve_m2_9_history_flag,
 no_production_decisioning_flag,no_real_funds_movement_flag,
 no_external_system_update_flag,no_merchant_contact_flag,
 no_write_off_collection_legal_flag,closed_burden_units,
 active_burden_units,review_burden_units,rate_decimal_scale,
 expected_policy_rows,expected_kpi_definition_rows,
 expected_performance_tier_rows,expected_servicing_queue_rows,
 expected_reason_rows,expected_source_rows,expected_account_performance_rows,
 expected_scope_summary_rows,expected_kpi_snapshot_rows,
 expected_queue_summary_rows,expected_latest_rows,expected_archive_rows,
 expected_comparison_rows,expected_registry_rows,expected_canonical_entities,
 expected_positive_controls,expected_negative_controls,
 expected_generation_evidence_rows,expected_detail_result_sets,
 configuration_payload,configuration_hash,row_hash,
 clock_timestamp(),clock_timestamp()
FROM hashed
ON CONFLICT(module1_run_id) DO NOTHING;

WITH ctx AS
(SELECT module1_run_id FROM msbf_ctl.m2_10_policy_profile WHERE policy_code='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_POLICY_V1'),
seed AS
(
 SELECT ctx.module1_run_id,v.kpi_code::text,v.kpi_rank::integer,v.unit_code::text,
        v.zero_numeric::boolean,v.description::text,'APPROVED'::text AS definition_status
 FROM ctx CROSS JOIN (VALUES ('ACCOUNT_COUNT', 1, 'COUNT', TRUE, 'Account count.'),
        ('CERTIFIED_ACCOUNT_COUNT', 2, 'COUNT', TRUE, 'Certified account count.'),
        ('CERTIFICATION_RATE', 3, 'RATE', TRUE, 'Certified accounts divided by account count.'),
        ('ACTIVE_ACCOUNT_COUNT', 4, 'COUNT', TRUE, 'Active reconciled account count.'),
        ('CLOSED_ACCOUNT_COUNT', 5, 'COUNT', TRUE, 'Closed stable account count.'),
        ('REVIEW_HOLD_ACCOUNT_COUNT', 6, 'COUNT', TRUE, 'Controlled review-hold account count.'),
        ('CERTIFIED_EXPOSURE_AMOUNT', 7, 'USD', TRUE, 'Certified portfolio exposure.'),
        ('ACTIVE_EXPOSURE_AMOUNT', 8, 'USD', TRUE, 'Certified active exposure.'),
        ('REVIEW_HOLD_EXPOSURE_AMOUNT', 9, 'USD', TRUE, 'Certified review-hold exposure.'),
        ('SCHEDULED_PAYMENT_AMOUNT', 10, 'USD', TRUE, 'Scheduled payment amount.'),
        ('PROCESSED_PAYMENT_AMOUNT', 11, 'USD', TRUE, 'Processed payment amount.'),
        ('GROSS_COLLECTION_RATE', 12, 'RATE', FALSE, 'Processed payment divided by scheduled payment.'),
        ('RETURNED_PAYMENT_AMOUNT', 13, 'USD', TRUE, 'Returned payment amount.'),
        ('RETURN_RATE', 14, 'RATE', FALSE, 'Returned payment divided by scheduled payment.'),
        ('RETRY_PAYMENT_AMOUNT', 15, 'USD', TRUE, 'Retry payment amount.'),
        ('RETRY_CURE_RATE', 16, 'RATE', FALSE, 'Retry amount divided by returned amount.'),
        ('RECONCILIATION_VARIANCE_AMOUNT', 17, 'USD', TRUE, 'Absolute reconciliation variance.'),
        ('EXPOSURE_VARIANCE_AMOUNT', 18, 'USD', TRUE, 'Absolute exposure variance.'),
        ('EXCEPTION_CASE_COUNT', 19, 'COUNT', TRUE, 'Payment exception case count.'),
        ('RESOLVED_EXCEPTION_COUNT', 20, 'COUNT', TRUE, 'Resolved exception count.'),
        ('EXCEPTION_RESOLUTION_RATE', 21, 'RATE', FALSE, 'Resolved exception count divided by exception count.'),
        ('UNRESOLVED_EXCEPTION_COUNT', 22, 'COUNT', TRUE, 'Unresolved exception count.'),
        ('SERVICING_BURDEN_UNITS', 23, 'UNITS', TRUE, 'Governed servicing workload units.'),
        ('AVERAGE_BURDEN_PER_ACCOUNT', 24, 'UNITS_PER_ACCOUNT', TRUE, 'Servicing burden divided by account count.'))
 AS v(kpi_code,kpi_rank,unit_code,zero_numeric,description)
), hashed AS
(SELECT seed.*,msbf_ctl.m2_10_hash_jsonb(to_jsonb(seed)) AS row_hash FROM seed)
INSERT INTO msbf_m2.portfolio_kpi_definition
(module1_run_id,kpi_code,kpi_rank,unit_code,zero_denominator_numeric_flag,
 description,definition_status,row_hash)
SELECT * FROM hashed ON CONFLICT(module1_run_id,kpi_code) DO NOTHING;

WITH ctx AS
(SELECT module1_run_id FROM msbf_ctl.m2_10_policy_profile WHERE policy_code='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_POLICY_V1'),
seed AS
(
 SELECT ctx.module1_run_id,v.code::text,v.rank::integer,v.burden::numeric(12,6),
        v.description::text,'APPROVED'::text AS definition_status
 FROM ctx CROSS JOIN (VALUES ('CLOSED_STABLE', 0, '0.000000', 'Certified closed account with no servicing activity.'),
        ('ACTIVE_RECONCILED', 1, '2.000000', 'Certified active account with reconciled payment activity.'),
        ('CONTROLLED_REVIEW', 2, '5.000000', 'Certified review-hold account requiring governed attention.'))
 AS v(code,rank,burden,description)
), hashed AS
(SELECT seed.*,msbf_ctl.m2_10_hash_jsonb(to_jsonb(seed)) AS row_hash FROM seed)
INSERT INTO msbf_m2.portfolio_performance_tier_definition
(module1_run_id,performance_tier_code,performance_tier_rank,burden_units,
 description,definition_status,row_hash)
SELECT * FROM hashed ON CONFLICT(module1_run_id,performance_tier_code) DO NOTHING;

WITH ctx AS
(SELECT module1_run_id FROM msbf_ctl.m2_10_policy_profile WHERE policy_code='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_POLICY_V1'),
seed AS
(
 SELECT ctx.module1_run_id,v.code::text,v.rank::integer,v.burden::numeric(12,6),
        v.manual::boolean,v.description::text,'APPROVED'::text AS definition_status
 FROM ctx CROSS JOIN (VALUES ('NO_SERVICING_REQUIRED', 0, '0.000000', FALSE, 'No servicing workload is required.'),
        ('ACTIVE_REASSESSMENT', 1, '2.000000', FALSE, 'Active account awaits governed reassessment.'),
        ('GOVERNANCE_REVIEW_HOLD', 2, '5.000000', TRUE, 'Account remains in controlled governance review.'))
 AS v(code,rank,burden,manual,description)
), hashed AS
(SELECT seed.*,msbf_ctl.m2_10_hash_jsonb(to_jsonb(seed)) AS row_hash FROM seed)
INSERT INTO msbf_m2.servicing_queue_definition
(module1_run_id,servicing_queue_code,servicing_queue_rank,burden_units,
 manual_review_flag,description,definition_status,row_hash)
SELECT * FROM hashed ON CONFLICT(module1_run_id,servicing_queue_code) DO NOTHING;

WITH ctx AS
(SELECT module1_run_id FROM msbf_ctl.m2_10_policy_profile WHERE policy_code='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_POLICY_V1'),
seed AS
(
 SELECT ctx.module1_run_id,v.code::text,FALSE::boolean AS production_action_flag,
        v.description::text,'APPROVED'::text AS definition_status
 FROM ctx CROSS JOIN (VALUES ('M2_10_REASON_SOURCE_CERTIFIED', 'Accepted M2.9 account state is certified.'),
        ('M2_10_REASON_CLOSED_STABLE', 'Certified account is closed with no processing requirement.'),
        ('M2_10_REASON_ACTIVE_RECONCILED', 'Certified active account has reconciled payment activity.'),
        ('M2_10_REASON_CONTROLLED_REVIEW', 'Certified account remains on controlled review hold.'),
        ('M2_10_REASON_PAYMENT_ACTIVITY_PRESENT', 'Account contains certified payment activity.'),
        ('M2_10_REASON_NO_PAYMENT_ACTIVITY', 'Account contains no payment activity.'),
        ('M2_10_REASON_COLLECTION_COMPLETE', 'Processed payment equals scheduled payment.'),
        ('M2_10_REASON_RETURN_PRESENT', 'Certified payment return is present.'),
        ('M2_10_REASON_RETRY_CURED', 'Returned amount is fully cured by retry.'),
        ('M2_10_REASON_NO_EXCEPTION', 'No payment exception case is present.'),
        ('M2_10_REASON_EXCEPTION_RESOLVED', 'Payment exception case is resolved.'),
        ('M2_10_REASON_NO_UNRESOLVED_EXCEPTION', 'No unresolved payment exception remains.'),
        ('M2_10_REASON_ZERO_RECON_VARIANCE', 'Reconciliation variance is zero.'),
        ('M2_10_REASON_ZERO_EXPOSURE_VARIANCE', 'Exposure variance is zero.'),
        ('M2_10_REASON_ACTIVE_EXPOSURE', 'Certified active exposure remains.'),
        ('M2_10_REASON_REVIEW_HOLD_EXPOSURE', 'Certified review-hold exposure remains.'),
        ('M2_10_REASON_NO_SERVICING_QUEUE', 'No servicing queue burden is assigned.'),
        ('M2_10_REASON_ACTIVE_REASSESSMENT_QUEUE', 'Account is assigned to active reassessment.'),
        ('M2_10_REASON_GOVERNANCE_REVIEW_QUEUE', 'Account is assigned to governance review hold.'),
        ('M2_10_REASON_KPI_APPLICABLE', 'KPI denominator is available and the metric is applicable.'),
        ('M2_10_REASON_KPI_NOT_APPLICABLE', 'KPI denominator is zero and the metric is not applicable.'),
        ('M2_10_REASON_SOURCE_HASH_PRESENT', 'Accepted M2.9 source hash is preserved.'),
        ('M2_10_REASON_HISTORY_PRESERVED', 'Accepted M2.9 history remains immutable.'),
        ('M2_10_REASON_SYNTHETIC_ONLY', 'Analytics outputs remain synthetic and non-production.')) AS v(code,description)
), hashed AS
(SELECT seed.*,msbf_ctl.m2_10_hash_jsonb(to_jsonb(seed)) AS row_hash FROM seed)
INSERT INTO msbf_m2.portfolio_analytics_reason_definition
(module1_run_id,portfolio_analytics_reason_code,production_action_flag,
 description,definition_status,row_hash)
SELECT * FROM hashed ON CONFLICT(module1_run_id,portfolio_analytics_reason_code) DO NOTHING;

/* ============================================================================
Section 8 — Consumption, comparison, Power BI, lineage, and canonical views
============================================================================ */

CREATE OR REPLACE VIEW msbf_m2.v_m2_10_portfolio_performance_latest AS
SELECT latest.* FROM msbf_m2.application_portfolio_performance_latest AS latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_10_matched_scenario_comparison AS
WITH paired AS
(
 SELECT latest.module1_run_id,latest.merchant_application_id,
   max(latest.performance_tier_code) FILTER(WHERE latest.scenario_code='BASELINE') AS baseline_performance_tier_code,
   max(latest.performance_tier_code) FILTER(WHERE latest.scenario_code='RECESSION_ENERGY') AS stress_performance_tier_code,
   max(tier.performance_tier_rank) FILTER(WHERE latest.scenario_code='BASELINE') AS baseline_performance_tier_rank,
   max(tier.performance_tier_rank) FILTER(WHERE latest.scenario_code='RECESSION_ENERGY') AS stress_performance_tier_rank,
   max(latest.servicing_burden_units) FILTER(WHERE latest.scenario_code='BASELINE') AS baseline_servicing_burden_units,
   max(latest.servicing_burden_units) FILTER(WHERE latest.scenario_code='RECESSION_ENERGY') AS stress_servicing_burden_units,
   max(latest.certified_exposure_amount) FILTER(WHERE latest.scenario_code='BASELINE') AS baseline_certified_exposure_amount,
   max(latest.certified_exposure_amount) FILTER(WHERE latest.scenario_code='RECESSION_ENERGY') AS stress_certified_exposure_amount,
   count(*) FILTER(WHERE latest.scenario_code='BASELINE') AS baseline_rows,
   count(*) FILTER(WHERE latest.scenario_code='RECESSION_ENERGY') AS stress_rows
 FROM msbf_m2.application_portfolio_performance_latest AS latest
 JOIN msbf_m2.portfolio_performance_tier_definition AS tier
   ON tier.module1_run_id=latest.module1_run_id
  AND tier.performance_tier_code=latest.performance_tier_code
 GROUP BY latest.module1_run_id,latest.merchant_application_id
)
SELECT paired.*,
 (stress_performance_tier_rank<baseline_performance_tier_rank) AS stress_tier_improvement_flag,
 (stress_servicing_burden_units<baseline_servicing_burden_units) AS stress_burden_improvement_flag,
 (stress_certified_exposure_amount<baseline_certified_exposure_amount) AS stress_exposure_improvement_flag
FROM paired WHERE baseline_rows=1 AND stress_rows=1;

CREATE OR REPLACE VIEW msbf_m2.v_m2_10_kpi_matrix AS
SELECT module1_run_id,scope_code,scope_type,scenario_code,kpi_code,kpi_rank,
 unit_code,applicable_flag,kpi_value_numeric,kpi_value_text,numerator_value,
 denominator_value FROM msbf_m2.portfolio_kpi_snapshot;

CREATE OR REPLACE VIEW msbf_m2.v_m2_10_servicing_queue_analytics AS
SELECT * FROM msbf_m2.servicing_queue_analytics_snapshot;

CREATE OR REPLACE VIEW msbf_m2.v_m2_10_power_bi_portfolio_analytics AS
SELECT module1_run_id,scenario_code,merchant_application_id,synthetic_account_id,
 performance_tier_code,servicing_queue_code,state_certified_flag,
 payment_activity_flag,exception_incident_flag,exception_resolved_flag,
 certified_exposure_amount,scheduled_payment_amount,processed_payment_amount,
 returned_payment_amount,retry_payment_amount,gross_collection_rate,return_rate,
 retry_cure_rate,servicing_burden_units
FROM msbf_m2.application_portfolio_performance_latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_10_lineage AS
SELECT module1_run_id,scenario_id,scenario_code,merchant_application_id,
 contract_code,contract_version,schema_version,source_contract_row_hash,
 source_snapshot_row_hash,performance_snapshot_row_hash,contract_row_hash
FROM msbf_m2.application_portfolio_performance_latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_10_canonical_entity AS
SELECT module1_run_id,'POLICY'::text AS entity_type,policy_code||'|v'||policy_version::text AS entity_key,row_hash FROM msbf_ctl.m2_10_policy_profile
UNION ALL SELECT module1_run_id,'KPI_DEFINITION',kpi_code,row_hash FROM msbf_m2.portfolio_kpi_definition
UNION ALL SELECT module1_run_id,'PERFORMANCE_TIER_DEFINITION',performance_tier_code,row_hash FROM msbf_m2.portfolio_performance_tier_definition
UNION ALL SELECT module1_run_id,'SERVICING_QUEUE_DEFINITION',servicing_queue_code,row_hash FROM msbf_m2.servicing_queue_definition
UNION ALL SELECT module1_run_id,'REASON_DEFINITION',portfolio_analytics_reason_code,row_hash FROM msbf_m2.portfolio_analytics_reason_definition
UNION ALL SELECT module1_run_id,'SOURCE',scenario_id::text||'|'||merchant_application_id,row_hash FROM msbf_m2.portfolio_performance_source_snapshot
UNION ALL SELECT module1_run_id,'ACCOUNT_PERFORMANCE',scenario_id::text||'|'||merchant_application_id,row_hash FROM msbf_m2.application_portfolio_performance_snapshot
UNION ALL SELECT module1_run_id,'SCOPE_SUMMARY',scope_code,row_hash FROM msbf_m2.portfolio_performance_scope_summary
UNION ALL SELECT module1_run_id,'KPI_SNAPSHOT',scope_code||'|'||kpi_code,row_hash FROM msbf_m2.portfolio_kpi_snapshot
UNION ALL SELECT module1_run_id,'QUEUE_SUMMARY',servicing_queue_code,row_hash FROM msbf_m2.servicing_queue_analytics_snapshot
UNION ALL SELECT module1_run_id,'LATEST',scenario_id::text||'|'||merchant_application_id,contract_row_hash FROM msbf_m2.application_portfolio_performance_latest
UNION ALL SELECT module1_run_id,'ARCHIVE',scenario_id::text||'|'||merchant_application_id,archive_row_hash FROM msbf_m2.application_portfolio_performance_archive
UNION ALL SELECT module1_run_id,'REGISTRY',contract_code||'|v'||contract_version::text,row_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry;

CREATE OR REPLACE VIEW msbf_m2.v_m2_10_canonical_hash AS
SELECT module1_run_id,count(*)::bigint AS canonical_entities,
 md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'|' ORDER BY entity_type,entity_key)) AS combined_set_hash
FROM msbf_m2.v_m2_10_canonical_entity GROUP BY module1_run_id;

/* ============================================================================
Section 9 — Schema/policy checkpoint
============================================================================ */

DO $m2_10_schema_guard$
DECLARE v_run bigint; v_gate bigint; v_kpi bigint; v_tier bigint; v_queue bigint; v_reason bigint;
BEGIN
 SELECT module1_run_id INTO v_run FROM msbf_ctl.m2_10_policy_profile WHERE policy_code='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_POLICY_V1';
 PERFORM msbf_ctl.m2_10_assert_configuration(v_run);
 SELECT count(*) INTO v_gate FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND active_flag;
 SELECT count(*) INTO v_kpi FROM msbf_m2.portfolio_kpi_definition WHERE module1_run_id=v_run AND definition_status='APPROVED';
 SELECT count(*) INTO v_tier FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=v_run AND definition_status='APPROVED';
 SELECT count(*) INTO v_queue FROM msbf_m2.servicing_queue_definition WHERE module1_run_id=v_run AND definition_status='APPROVED';
 SELECT count(*) INTO v_reason FROM msbf_m2.portfolio_analytics_reason_definition WHERE module1_run_id=v_run AND definition_status='APPROVED';
 IF v_gate<>1 OR v_kpi<>24 OR v_tier<>3 OR v_queue<>3 OR v_reason<>24 THEN
  RAISE EXCEPTION 'M2.10 schema/policy extension failed: gate %, kpi %, tier %, queue %, reason %.',v_gate,v_kpi,v_tier,v_queue,v_reason;
 END IF;
END;
$m2_10_schema_guard$;

COMMIT;

SELECT policy.module1_run_id,policy.policy_code,policy.policy_version,
 policy.policy_status,policy.methodology_version,policy.contract_code,
 policy.contract_version,policy.schema_version,policy.source_contract_code,
 policy.source_schema_version,policy.source_acceptance_gate_id,
 policy.source_combined_set_hash,policy.configuration_hash,
 (SELECT count(*) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND active_flag) AS acceptance_gate_catalog_rows,
 (SELECT count(*) FROM msbf_m2.portfolio_kpi_definition WHERE module1_run_id=policy.module1_run_id) AS kpi_definition_rows,
 (SELECT count(*) FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=policy.module1_run_id) AS performance_tier_rows,
 (SELECT count(*) FROM msbf_m2.servicing_queue_definition WHERE module1_run_id=policy.module1_run_id) AS servicing_queue_rows,
 (SELECT count(*) FROM msbf_m2.portfolio_analytics_reason_definition WHERE module1_run_id=policy.module1_run_id) AS reason_rows,
 CASE WHEN policy.policy_status='APPROVED' AND policy.synthetic_data_only_flag
  AND policy.analytics_only_flag AND policy.preserve_m2_9_history_flag
  AND policy.no_production_decisioning_flag AND policy.no_real_funds_movement_flag
  AND policy.no_external_system_update_flag AND policy.no_merchant_contact_flag
  AND policy.no_write_off_collection_legal_flag THEN 'PASS' ELSE 'FAIL' END
 AS schema_policy_status
FROM msbf_ctl.m2_10_policy_profile AS policy
WHERE policy.policy_code='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_POLICY_V1';
