/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.6 — Early Warning, Intervention & Servicing Strategy

Program     : 172_msbf_m2_6_schema_policy_strategy_contract_extension_v0_2.sql
Version     : v0.2

Purpose
-------
Create the M2.6 governed schema extension: policy, outcome/action/reason
reference dictionaries, source/strategy/latest/archive/summary structures,
contract registry, hash utilities, lifecycle assertions, archive immutability,
consumption views, acceptance-gate registration, and deterministic policy seed.

Boundary
--------
M2.6 is recommendation-only. It does not execute merchant contact, payment
change, workout, restructure, write-off, charge-off, collection-agency referral,
legal action, external notice, production adverse-action notice, or real bank
or ACH activity.

Required result
---------------
schema_policy_status = PASS.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='35min';
SET LOCAL jit=off;

CREATE SCHEMA IF NOT EXISTS msbf_ctl;
CREATE SCHEMA IF NOT EXISTS msbf_m2;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_6_hash_jsonb(p_payload jsonb)
RETURNS text LANGUAGE sql IMMUTABLE STRICT AS $function$
    SELECT md5(p_payload::text);
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_6_registry_row_hash(p_payload jsonb)
RETURNS text LANGUAGE sql IMMUTABLE STRICT AS $function$
    SELECT msbf_ctl.m2_6_hash_jsonb(
        p_payload - 'registry_id' - 'contract_status' - 'generated_at' - 'validated_at' - 'accepted_at' - 'row_hash' - 'created_at' - 'contract_set_hash' - 'combined_set_hash'
    );
$function$;

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_6_policy_profile (
    module1_run_id bigint PRIMARY KEY,
    policy_code text NOT NULL,
    policy_version integer NOT NULL,
    policy_status text NOT NULL,
    methodology_version text NOT NULL,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    source_m2_5_contract_code text NOT NULL,
    source_m2_5_contract_version integer NOT NULL,
    source_m2_5_schema_version text NOT NULL,
    source_m2_5_combined_hash text NOT NULL,
    source_m2_5_acceptance_gate_id text NOT NULL,
    recommendation_only_flag boolean NOT NULL,
    no_merchant_contact_execution_flag boolean NOT NULL,
    no_payment_change_execution_flag boolean NOT NULL,
    no_write_off_charge_off_execution_flag boolean NOT NULL,
    no_legal_or_collection_action_flag boolean NOT NULL,
    no_external_notice_generation_flag boolean NOT NULL,
    no_production_adverse_action_notice_flag boolean NOT NULL,
    preserve_m2_5_history_flag boolean NOT NULL,
    temporary_remittance_rate_factor numeric(9,6) NOT NULL,
    maximum_review_duration_days integer NOT NULL,
    reassessment_interval_days integer NOT NULL,
    expected_policy_rows bigint NOT NULL,
    expected_outcome_rows bigint NOT NULL,
    expected_action_rows bigint NOT NULL,
    expected_reason_rows bigint NOT NULL,
    expected_source_rows bigint NOT NULL,
    expected_strategy_rows bigint NOT NULL,
    expected_portfolio_summary_rows bigint NOT NULL,
    expected_latest_rows bigint NOT NULL,
    expected_archive_rows bigint NOT NULL,
    expected_comparison_rows bigint NOT NULL,
    expected_registry_rows bigint NOT NULL,
    expected_canonical_entities bigint NOT NULL,
    expected_positive_controls integer NOT NULL,
    expected_negative_controls integer NOT NULL,
    expected_detail_result_sets integer NOT NULL,
    configuration_payload jsonb NOT NULL,
    configuration_hash text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT ck_m2_6_policy_identity CHECK (policy_code='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_POLICY_V1' AND policy_version=1 AND methodology_version='M2_6_METHOD_V1' AND contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND contract_version=1 AND schema_version='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1'),
    CONSTRAINT ck_m2_6_policy_status CHECK (policy_status IN ('APPROVED','RETIRED')),
    CONSTRAINT ck_m2_6_policy_hashes CHECK (length(configuration_hash)=32 AND configuration_hash ~ '^[0-9a-f]+$' AND length(row_hash)=32 AND row_hash ~ '^[0-9a-f]+$'),
    CONSTRAINT ck_m2_6_policy_boundaries CHECK (recommendation_only_flag AND no_merchant_contact_execution_flag AND no_payment_change_execution_flag AND no_write_off_charge_off_execution_flag AND no_legal_or_collection_action_flag AND no_external_notice_generation_flag AND no_production_adverse_action_notice_flag AND preserve_m2_5_history_flag AND temporary_remittance_rate_factor > 0 AND temporary_remittance_rate_factor < 1 AND maximum_review_duration_days >= reassessment_interval_days AND reassessment_interval_days > 0)
);

CREATE TABLE IF NOT EXISTS msbf_m2.intervention_strategy_outcome_definition (
    module1_run_id bigint NOT NULL,
    strategy_outcome_code text NOT NULL,
    strategy_outcome_rank integer NOT NULL,
    recommended_action_flag boolean NOT NULL,
    review_required_flag boolean NOT NULL,
    temporary_adjustment_review_flag boolean NOT NULL,
    workout_review_flag boolean NOT NULL,
    recovery_review_flag boolean NOT NULL,
    executed_action_flag boolean NOT NULL,
    definition_status text NOT NULL,
    description text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,strategy_outcome_code),
    UNIQUE(module1_run_id,strategy_outcome_rank),
    CONSTRAINT ck_m2_6_outcome_status CHECK (definition_status IN ('APPROVED','RETIRED')),
    CONSTRAINT ck_m2_6_outcome_boundary CHECK (executed_action_flag IS FALSE)
);

CREATE TABLE IF NOT EXISTS msbf_m2.intervention_servicing_action_definition (
    module1_run_id bigint NOT NULL,
    servicing_action_code text NOT NULL,
    servicing_action_rank integer NOT NULL,
    merchant_contact_review_flag boolean NOT NULL,
    payment_change_review_flag boolean NOT NULL,
    workout_review_flag boolean NOT NULL,
    recovery_review_flag boolean NOT NULL,
    governance_review_flag boolean NOT NULL,
    executed_servicing_action_flag boolean NOT NULL,
    definition_status text NOT NULL,
    description text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,servicing_action_code),
    UNIQUE(module1_run_id,servicing_action_rank),
    CONSTRAINT ck_m2_6_action_status CHECK (definition_status IN ('APPROVED','RETIRED')),
    CONSTRAINT ck_m2_6_action_boundary CHECK (executed_servicing_action_flag IS FALSE)
);

CREATE TABLE IF NOT EXISTS msbf_m2.intervention_reason_definition (
    module1_run_id bigint NOT NULL,
    intervention_reason_code text NOT NULL,
    mapped_strategy_outcome_code text NOT NULL,
    mapped_servicing_action_code text NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    executed_servicing_action_flag boolean NOT NULL,
    definition_status text NOT NULL,
    description text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,intervention_reason_code),
    CONSTRAINT fk_m2_6_reason_outcome FOREIGN KEY(module1_run_id,mapped_strategy_outcome_code) REFERENCES msbf_m2.intervention_strategy_outcome_definition(module1_run_id,strategy_outcome_code),
    CONSTRAINT fk_m2_6_reason_action FOREIGN KEY(module1_run_id,mapped_servicing_action_code) REFERENCES msbf_m2.intervention_servicing_action_definition(module1_run_id,servicing_action_code),
    CONSTRAINT ck_m2_6_reason_status CHECK (definition_status IN ('APPROVED','RETIRED')),
    CONSTRAINT ck_m2_6_reason_boundary CHECK (production_adverse_action_notice_flag IS FALSE AND executed_servicing_action_flag IS FALSE)
);

CREATE TABLE IF NOT EXISTS msbf_m2.advance_intervention_source_snapshot (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    merchant_id text NOT NULL,
    synthetic_account_id text NOT NULL,
    synthetic_advance_id text NOT NULL,
    latest_monitoring_status_code text NOT NULL,
    latest_monitoring_status_rank integer NOT NULL,
    paid_off_flag boolean NOT NULL,
    payoff_day_index integer,
    cumulative_remittance_amount numeric(18,2) NOT NULL,
    remaining_receivable_amount numeric(18,2) NOT NULL,
    principal_exposure_proxy numeric(18,2) NOT NULL,
    unearned_finance_charge_proxy numeric(18,2) NOT NULL,
    cumulative_expected_remittance_amount numeric(18,2) NOT NULL,
    cumulative_shortfall_amount numeric(18,2) NOT NULL,
    cumulative_pace_ratio numeric(12,8),
    trailing_7_day_remittance_amount numeric(18,2) NOT NULL,
    trailing_30_day_remittance_amount numeric(18,2) NOT NULL,
    days_since_last_positive_remittance integer NOT NULL,
    zero_sales_streak_days integer NOT NULL,
    current_available_balance numeric(18,2) NOT NULL,
    current_nsf_count smallint NOT NULL,
    active_alert_count integer NOT NULL,
    alert_payload jsonb NOT NULL,
    recent_30_day_remittance_amount numeric(18,2) NOT NULL,
    recent_30_day_shortfall_amount numeric(18,2) NOT NULL,
    recent_30_day_alert_days integer NOT NULL,
    recent_30_day_zero_sales_days integer NOT NULL,
    current_remittance_rate numeric(9,6) NOT NULL,
    source_m2_5_contract_row_hash text NOT NULL,
    source_daily_row_hash text NOT NULL,
    source_m2_4_contract_row_hash text NOT NULL,
    source_advance_row_hash text NOT NULL,
    source_portfolio_row_hash text NOT NULL,
    source_m2_5_combined_hash text NOT NULL,
    source_payload jsonb NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_6_source_amounts CHECK (remaining_receivable_amount >= 0 AND principal_exposure_proxy >= 0 AND unearned_finance_charge_proxy >= 0 AND cumulative_shortfall_amount >= 0 AND active_alert_count >= 0)
);

CREATE TABLE IF NOT EXISTS msbf_m2.advance_intervention_strategy_snapshot (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    merchant_id text NOT NULL,
    synthetic_account_id text NOT NULL,
    synthetic_advance_id text NOT NULL,
    strategy_outcome_code text NOT NULL,
    strategy_outcome_rank integer NOT NULL,
    servicing_action_code text NOT NULL,
    servicing_priority_rank integer NOT NULL,
    servicing_queue_code text NOT NULL,
    recommended_action_flag boolean NOT NULL,
    review_required_flag boolean NOT NULL,
    temporary_adjustment_review_flag boolean NOT NULL,
    workout_review_flag boolean NOT NULL,
    recovery_review_flag boolean NOT NULL,
    merchant_contact_executed_flag boolean NOT NULL,
    payment_change_executed_flag boolean NOT NULL,
    write_off_or_charge_off_executed_flag boolean NOT NULL,
    legal_or_collection_action_executed_flag boolean NOT NULL,
    external_notice_generated_flag boolean NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    recommended_action_exposure_amount numeric(18,2) NOT NULL,
    temporary_remittance_rate_factor numeric(9,6),
    review_remittance_rate numeric(9,6),
    recommended_review_duration_days integer,
    reassessment_interval_days integer,
    primary_intervention_reason_code text NOT NULL,
    intervention_reason_codes jsonb NOT NULL,
    source_m2_5_contract_row_hash text NOT NULL,
    source_snapshot_row_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT fk_m2_6_strategy_outcome FOREIGN KEY(module1_run_id,strategy_outcome_code) REFERENCES msbf_m2.intervention_strategy_outcome_definition(module1_run_id,strategy_outcome_code),
    CONSTRAINT fk_m2_6_strategy_action FOREIGN KEY(module1_run_id,servicing_action_code) REFERENCES msbf_m2.intervention_servicing_action_definition(module1_run_id,servicing_action_code),
    CONSTRAINT fk_m2_6_strategy_reason FOREIGN KEY(module1_run_id,primary_intervention_reason_code) REFERENCES msbf_m2.intervention_reason_definition(module1_run_id,intervention_reason_code),
    CONSTRAINT ck_m2_6_strategy_boundary CHECK (merchant_contact_executed_flag IS FALSE AND payment_change_executed_flag IS FALSE AND write_off_or_charge_off_executed_flag IS FALSE AND legal_or_collection_action_executed_flag IS FALSE AND external_notice_generated_flag IS FALSE AND production_adverse_action_notice_flag IS FALSE),
    CONSTRAINT ck_m2_6_strategy_terms CHECK ((temporary_adjustment_review_flag AND temporary_remittance_rate_factor IS NOT NULL AND review_remittance_rate IS NOT NULL AND recommended_review_duration_days IS NOT NULL AND reassessment_interval_days IS NOT NULL) OR (NOT temporary_adjustment_review_flag AND temporary_remittance_rate_factor IS NULL AND review_remittance_rate IS NULL AND recommended_review_duration_days IS NULL AND reassessment_interval_days IS NULL))
);

CREATE TABLE IF NOT EXISTS msbf_m2.portfolio_intervention_strategy_summary (
    module1_run_id bigint NOT NULL,
    scenario_code text NOT NULL,
    strategy_rows integer NOT NULL,
    closed_no_action_rows integer NOT NULL,
    continue_monitoring_rows integer NOT NULL,
    recommended_action_rows integer NOT NULL,
    outreach_review_rows integer NOT NULL,
    temporary_adjustment_review_rows integer NOT NULL,
    workout_review_rows integer NOT NULL,
    controlled_exit_recovery_rows integer NOT NULL,
    manual_review_rows integer NOT NULL,
    recommended_action_exposure_amount numeric(18,2) NOT NULL,
    maximum_servicing_priority_rank integer NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_code),
    CONSTRAINT ck_m2_6_portfolio_summary_counts CHECK (strategy_rows >= 0 AND recommended_action_rows >= 0 AND recommended_action_exposure_amount >= 0)
);

CREATE TABLE IF NOT EXISTS msbf_m2.advance_intervention_strategy_latest (
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
    strategy_outcome_code text NOT NULL,
    strategy_outcome_rank integer NOT NULL,
    servicing_action_code text NOT NULL,
    servicing_priority_rank integer NOT NULL,
    servicing_queue_code text NOT NULL,
    recommended_action_flag boolean NOT NULL,
    review_required_flag boolean NOT NULL,
    temporary_adjustment_review_flag boolean NOT NULL,
    workout_review_flag boolean NOT NULL,
    recovery_review_flag boolean NOT NULL,
    recommended_action_exposure_amount numeric(18,2) NOT NULL,
    temporary_remittance_rate_factor numeric(9,6),
    review_remittance_rate numeric(9,6),
    recommended_review_duration_days integer,
    reassessment_interval_days integer,
    primary_intervention_reason_code text NOT NULL,
    intervention_reason_codes jsonb NOT NULL,
    source_m2_5_contract_row_hash text NOT NULL,
    source_snapshot_row_hash text NOT NULL,
    strategy_snapshot_row_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    contract_row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_6_latest_identity CHECK (contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND contract_version=1 AND schema_version='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1' AND methodology_version='M2_6_METHOD_V1')
);

CREATE TABLE IF NOT EXISTS msbf_m2.advance_intervention_strategy_archive (
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
    strategy_outcome_code text NOT NULL,
    strategy_outcome_rank integer NOT NULL,
    servicing_action_code text NOT NULL,
    servicing_priority_rank integer NOT NULL,
    servicing_queue_code text NOT NULL,
    recommended_action_flag boolean NOT NULL,
    review_required_flag boolean NOT NULL,
    temporary_adjustment_review_flag boolean NOT NULL,
    workout_review_flag boolean NOT NULL,
    recovery_review_flag boolean NOT NULL,
    recommended_action_exposure_amount numeric(18,2) NOT NULL,
    temporary_remittance_rate_factor numeric(9,6),
    review_remittance_rate numeric(9,6),
    recommended_review_duration_days integer,
    reassessment_interval_days integer,
    primary_intervention_reason_code text NOT NULL,
    intervention_reason_codes jsonb NOT NULL,
    source_m2_5_contract_row_hash text NOT NULL,
    source_snapshot_row_hash text NOT NULL,
    strategy_snapshot_row_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    contract_row_hash text NOT NULL,
    contract_payload jsonb NOT NULL,
    archive_row_hash text NOT NULL,
    archived_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE(module1_run_id,contract_version,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_6_archive_identity CHECK (contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND contract_version=1 AND schema_version='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1' AND methodology_version='M2_6_METHOD_V1')
);

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_6_intervention_strategy_contract_registry (
    registry_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id bigint NOT NULL UNIQUE,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    methodology_version text NOT NULL,
    source_m2_5_contract_code text NOT NULL,
    source_m2_5_contract_version integer NOT NULL,
    source_m2_5_schema_version text NOT NULL,
    source_m2_5_combined_hash text NOT NULL,
    source_m2_5_acceptance_gate_id text NOT NULL,
    policy_configuration_hash text NOT NULL,
    policy_rows bigint NOT NULL,
    outcome_rows bigint NOT NULL,
    action_rows bigint NOT NULL,
    reason_rows bigint NOT NULL,
    source_rows bigint NOT NULL,
    strategy_rows bigint NOT NULL,
    portfolio_summary_rows bigint NOT NULL,
    latest_rows bigint NOT NULL,
    archive_rows bigint NOT NULL,
    comparison_rows bigint NOT NULL,
    registry_rows bigint NOT NULL,
    canonical_entities bigint NOT NULL,
    closed_no_action_rows bigint NOT NULL,
    continue_monitoring_rows bigint NOT NULL,
    outreach_review_rows bigint NOT NULL,
    temporary_adjustment_review_rows bigint NOT NULL,
    workout_review_rows bigint NOT NULL,
    controlled_exit_recovery_rows bigint NOT NULL,
    manual_review_rows bigint NOT NULL,
    recommended_action_rows bigint NOT NULL,
    recommended_action_exposure_amount numeric(18,2) NOT NULL,
    policy_set_hash text NOT NULL,
    outcome_set_hash text NOT NULL,
    action_set_hash text NOT NULL,
    reason_set_hash text NOT NULL,
    source_set_hash text NOT NULL,
    strategy_set_hash text NOT NULL,
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
    CONSTRAINT ck_m2_6_registry_status CHECK (contract_status IN ('GENERATED','VALIDATED','ACCEPTED')),
    CONSTRAINT ck_m2_6_registry_identity CHECK (contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND contract_version=1 AND schema_version='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1' AND methodology_version='M2_6_METHOD_V1')
);

CREATE OR REPLACE FUNCTION msbf_ctl.m2_6_archive_immutable()
RETURNS trigger LANGUAGE plpgsql AS $function$
BEGIN
    RAISE EXCEPTION 'M2.6 intervention-strategy archive is immutable; % is not permitted.', TG_OP;
END;
$function$;
DROP TRIGGER IF EXISTS trg_m2_6_strategy_archive_immutable ON msbf_m2.advance_intervention_strategy_archive;
CREATE TRIGGER trg_m2_6_strategy_archive_immutable BEFORE UPDATE OR DELETE ON msbf_m2.advance_intervention_strategy_archive FOR EACH ROW EXECUTE FUNCTION msbf_ctl.m2_6_archive_immutable();

CREATE INDEX IF NOT EXISTS ix_m2_6_source_status ON msbf_m2.advance_intervention_source_snapshot(module1_run_id,scenario_code,latest_monitoring_status_code);
CREATE INDEX IF NOT EXISTS ix_m2_6_strategy_outcome ON msbf_m2.advance_intervention_strategy_snapshot(module1_run_id,scenario_code,strategy_outcome_code);
CREATE INDEX IF NOT EXISTS ix_m2_6_latest_outcome ON msbf_m2.advance_intervention_strategy_latest(module1_run_id,scenario_code,strategy_outcome_code);
CREATE INDEX IF NOT EXISTS ix_m2_6_archive_application ON msbf_m2.advance_intervention_strategy_archive(module1_run_id,scenario_id,merchant_application_id);

CREATE OR REPLACE FUNCTION msbf_ctl.m2_6_assert_configuration(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v record;
BEGIN
    SELECT policy.* INTO v FROM msbf_ctl.m2_6_policy_profile AS policy WHERE policy.module1_run_id=p_run_id;
    IF v.module1_run_id IS NULL OR v.policy_status <> 'APPROVED' OR v.policy_code <> 'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_POLICY_V1' OR v.methodology_version <> 'M2_6_METHOD_V1' OR v.contract_code <> 'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' OR v.schema_version <> 'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1' OR v.source_m2_5_combined_hash <> '18e1c444aa1b02ee5bd3539d7c477adc' OR v.source_m2_5_acceptance_gate_id <> 'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING' OR v.recommendation_only_flag IS DISTINCT FROM TRUE OR v.no_merchant_contact_execution_flag IS DISTINCT FROM TRUE OR v.no_payment_change_execution_flag IS DISTINCT FROM TRUE OR v.no_write_off_charge_off_execution_flag IS DISTINCT FROM TRUE OR v.no_legal_or_collection_action_flag IS DISTINCT FROM TRUE OR v.no_external_notice_generation_flag IS DISTINCT FROM TRUE OR v.no_production_adverse_action_notice_flag IS DISTINCT FROM TRUE OR v.preserve_m2_5_history_flag IS DISTINCT FROM TRUE OR v.configuration_hash IS DISTINCT FROM msbf_ctl.m2_6_hash_jsonb(v.configuration_payload) OR v.row_hash IS DISTINCT FROM msbf_ctl.m2_6_hash_jsonb(to_jsonb(v)-'row_hash'-'created_at'-'updated_at') THEN
        RAISE EXCEPTION 'M2.6 configuration assertion failed for run_id %.', p_run_id;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_6_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_run_status text;
BEGIN
    PERFORM msbf_ctl.m2_6_assert_configuration(p_run_id);
    SELECT run_status INTO v_run_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    IF v_run_status <> 'M2_5_ACCEPTED' THEN RAISE EXCEPTION 'M2.6 generation requires M2_5_ACCEPTED; observed %.', v_run_status; END IF;
    IF EXISTS (SELECT 1 FROM msbf_m2.advance_intervention_source_snapshot WHERE module1_run_id=p_run_id UNION ALL SELECT 1 FROM msbf_m2.advance_intervention_strategy_snapshot WHERE module1_run_id=p_run_id UNION ALL SELECT 1 FROM msbf_m2.advance_intervention_strategy_latest WHERE module1_run_id=p_run_id UNION ALL SELECT 1 FROM msbf_m2.advance_intervention_strategy_archive WHERE module1_run_id=p_run_id UNION ALL SELECT 1 FROM msbf_m2.portfolio_intervention_strategy_summary WHERE module1_run_id=p_run_id UNION ALL SELECT 1 FROM msbf_ctl.m2_6_intervention_strategy_contract_registry WHERE module1_run_id=p_run_id UNION ALL SELECT 1 FROM msbf_ctl.run_evidence WHERE run_id=p_run_id AND evidence_code LIKE 'M2_6_%' UNION ALL SELECT 1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY') THEN RAISE EXCEPTION 'M2.6 generation requires empty M2.6 targets for run_id %.', p_run_id; END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_6_assert_validation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_run_status text; v_contract_status text;
BEGIN
    PERFORM msbf_ctl.m2_6_assert_configuration(p_run_id);
    SELECT run_status INTO v_run_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    SELECT contract_status INTO v_contract_status FROM msbf_ctl.m2_6_intervention_strategy_contract_registry WHERE module1_run_id=p_run_id;
    IF NOT ((v_run_status='M2_6_GENERATED' AND v_contract_status='GENERATED') OR (v_run_status='M2_6_VALIDATED' AND v_contract_status='VALIDATED')) THEN RAISE EXCEPTION 'M2.6 validation requires aligned generated or validated state; run %, contract %.', v_run_status, v_contract_status; END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_6_assert_acceptance_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_run_status text; v_contract_status text; v_pos bigint; v_neg bigint;
BEGIN
    PERFORM msbf_ctl.m2_6_assert_configuration(p_run_id);
    SELECT run_status INTO v_run_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    SELECT contract_status INTO v_contract_status FROM msbf_ctl.m2_6_intervention_strategy_contract_registry WHERE module1_run_id=p_run_id;
    SELECT count(*) FILTER (WHERE evidence_code LIKE 'M2_6_POS_%' AND status='PASS'), count(*) FILTER (WHERE evidence_code LIKE 'M2_6_NEG_%' AND status='PASS') INTO v_pos, v_neg FROM msbf_ctl.run_evidence WHERE run_id=p_run_id;
    IF v_run_status <> 'M2_6_VALIDATED' OR v_contract_status <> 'VALIDATED' OR v_pos <> 120 OR v_neg <> 20 THEN RAISE EXCEPTION 'M2.6 acceptance not ready: run %, contract %, positive %, negative %.', v_run_status, v_contract_status, v_pos, v_neg; END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_6_assert_no_executed_servicing_payload(p_payload jsonb)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_key text;
BEGIN
    SELECT key INTO v_key FROM jsonb_object_keys(coalesce(p_payload,'{}'::jsonb)) AS key WHERE lower(key) IN ('merchant_contact_executed','payment_change_executed','remittance_rate_change_applied','workout_executed','restructure_executed','write_off_executed','charge_off_executed','collection_agency_referral','legal_action','external_notice','external_notice_payload','production_adverse_action_notice','production_adverse_action_notice_payload','bank_account_number','routing_number','ach_trace_number') LIMIT 1;
    IF v_key IS NOT NULL THEN RAISE EXCEPTION 'M2.6 boundary rejected prohibited executed-servicing payload key %.', v_key; END IF;
END;
$function$;

INSERT INTO msbf_ref.acceptance_gate_catalog(gate_id, gate_name, module_code, severity, active_flag, description)
VALUES ('M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY', 'M2.6 Early Warning, Intervention & Servicing Strategy', 'M2.6', 'BLOCKING', TRUE, 'Accepts recommendation-only intervention and servicing strategy outputs while prohibiting executed servicing actions and production notices.')
ON CONFLICT(gate_id) DO UPDATE SET gate_name=EXCLUDED.gate_name, module_code=EXCLUDED.module_code, severity=EXCLUDED.severity, active_flag=EXCLUDED.active_flag, description=EXCLUDED.description;

WITH seed AS (
    SELECT registry.module1_run_id::bigint AS module1_run_id, 'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_POLICY_V1'::text AS policy_code, 1::integer AS policy_version, 'APPROVED'::text AS policy_status, 'M2_6_METHOD_V1'::text AS methodology_version, 'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'::text AS contract_code, 1::integer AS contract_version, 'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1'::text AS schema_version, 'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'::text AS source_m2_5_contract_code, 1::integer AS source_m2_5_contract_version, 'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1'::text AS source_m2_5_schema_version, '18e1c444aa1b02ee5bd3539d7c477adc'::text AS source_m2_5_combined_hash, 'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'::text AS source_m2_5_acceptance_gate_id, TRUE::boolean AS recommendation_only_flag, TRUE::boolean AS no_merchant_contact_execution_flag, TRUE::boolean AS no_payment_change_execution_flag, TRUE::boolean AS no_write_off_charge_off_execution_flag, TRUE::boolean AS no_legal_or_collection_action_flag, TRUE::boolean AS no_external_notice_generation_flag, TRUE::boolean AS no_production_adverse_action_notice_flag, TRUE::boolean AS preserve_m2_5_history_flag, 0.750000::numeric(9,6) AS temporary_remittance_rate_factor, 14::integer AS maximum_review_duration_days, 7::integer AS reassessment_interval_days, 1::bigint AS expected_policy_rows, 7::bigint AS expected_outcome_rows, 7::bigint AS expected_action_rows, 30::bigint AS expected_reason_rows, 59::bigint AS expected_source_rows, 59::bigint AS expected_strategy_rows, 2::bigint AS expected_portfolio_summary_rows, 59::bigint AS expected_latest_rows, 59::bigint AS expected_archive_rows, 15::bigint AS expected_comparison_rows, 1::bigint AS expected_registry_rows, 284::bigint AS expected_canonical_entities, 120::integer AS expected_positive_controls, 20::integer AS expected_negative_controls, 24::integer AS expected_detail_result_sets, '{"contract_code":"M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION","contract_version":1,"expected":{"action_rows":7,"archive_rows":59,"canonical_entities":284,"closed_no_action_rows":57,"comparison_rows":15,"continue_monitoring_rows":0,"controlled_exit_recovery_rows":0,"detail_result_sets":24,"generation_evidence_rows":24,"latest_rows":59,"manual_review_rows":0,"negative_controls":20,"outcome_rows":7,"outreach_review_rows":1,"policy_rows":1,"portfolio_summary_rows":2,"positive_controls":120,"reason_rows":30,"recommended_action_exposure_amount":"979.73","recommended_action_rows":2,"registry_rows":1,"source_rows":59,"strategy_rows":59,"temporary_adjustment_review_rows":1,"workout_review_rows":0},"maximum_review_duration_days":14,"methodology":"M2_6_METHOD_V1","no_external_notice_generation":true,"no_legal_or_collection_action":true,"no_merchant_contact_execution":true,"no_payment_change_execution":true,"no_production_adverse_action_notice":true,"no_write_off_charge_off_execution":true,"policy_code":"M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_POLICY_V1","preserve_m2_5_history":true,"reassessment_interval_days":7,"recommendation_only":true,"schema_version":"M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1","source_contract":"M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION","source_gate":"M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING","source_hash":"18e1c444aa1b02ee5bd3539d7c477adc","source_schema":"M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1","temporary_remittance_rate_factor":0.75}'::jsonb AS configuration_payload, msbf_ctl.m2_6_hash_jsonb('{"contract_code":"M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION","contract_version":1,"expected":{"action_rows":7,"archive_rows":59,"canonical_entities":284,"closed_no_action_rows":57,"comparison_rows":15,"continue_monitoring_rows":0,"controlled_exit_recovery_rows":0,"detail_result_sets":24,"generation_evidence_rows":24,"latest_rows":59,"manual_review_rows":0,"negative_controls":20,"outcome_rows":7,"outreach_review_rows":1,"policy_rows":1,"portfolio_summary_rows":2,"positive_controls":120,"reason_rows":30,"recommended_action_exposure_amount":"979.73","recommended_action_rows":2,"registry_rows":1,"source_rows":59,"strategy_rows":59,"temporary_adjustment_review_rows":1,"workout_review_rows":0},"maximum_review_duration_days":14,"methodology":"M2_6_METHOD_V1","no_external_notice_generation":true,"no_legal_or_collection_action":true,"no_merchant_contact_execution":true,"no_payment_change_execution":true,"no_production_adverse_action_notice":true,"no_write_off_charge_off_execution":true,"policy_code":"M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_POLICY_V1","preserve_m2_5_history":true,"reassessment_interval_days":7,"recommendation_only":true,"schema_version":"M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1","source_contract":"M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION","source_gate":"M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING","source_hash":"18e1c444aa1b02ee5bd3539d7c477adc","source_schema":"M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1","temporary_remittance_rate_factor":0.75}'::jsonb) AS configuration_hash
    FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS registry JOIN msbf_ctl.run_registry AS run ON run.run_id=registry.module1_run_id
    WHERE run.run_code='M1_V0_2_BASELINE_BUILD' AND run.run_version=1 AND run.run_status='M2_5_ACCEPTED' AND registry.contract_status='ACCEPTED' AND registry.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND registry.schema_version='M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1' AND registry.combined_set_hash='18e1c444aa1b02ee5bd3539d7c477adc'
), hashed AS (SELECT seed.*, msbf_ctl.m2_6_hash_jsonb(to_jsonb(seed)) AS row_hash FROM seed)
INSERT INTO msbf_ctl.m2_6_policy_profile(module1_run_id,policy_code,policy_version,policy_status,methodology_version,contract_code,contract_version,schema_version,source_m2_5_contract_code,source_m2_5_contract_version,source_m2_5_schema_version,source_m2_5_combined_hash,source_m2_5_acceptance_gate_id,recommendation_only_flag,no_merchant_contact_execution_flag,no_payment_change_execution_flag,no_write_off_charge_off_execution_flag,no_legal_or_collection_action_flag,no_external_notice_generation_flag,no_production_adverse_action_notice_flag,preserve_m2_5_history_flag,temporary_remittance_rate_factor,maximum_review_duration_days,reassessment_interval_days,expected_policy_rows,expected_outcome_rows,expected_action_rows,expected_reason_rows,expected_source_rows,expected_strategy_rows,expected_portfolio_summary_rows,expected_latest_rows,expected_archive_rows,expected_comparison_rows,expected_registry_rows,expected_canonical_entities,expected_positive_controls,expected_negative_controls,expected_detail_result_sets,configuration_payload,configuration_hash,row_hash) SELECT module1_run_id,policy_code,policy_version,policy_status,methodology_version,contract_code,contract_version,schema_version,source_m2_5_contract_code,source_m2_5_contract_version,source_m2_5_schema_version,source_m2_5_combined_hash,source_m2_5_acceptance_gate_id,recommendation_only_flag,no_merchant_contact_execution_flag,no_payment_change_execution_flag,no_write_off_charge_off_execution_flag,no_legal_or_collection_action_flag,no_external_notice_generation_flag,no_production_adverse_action_notice_flag,preserve_m2_5_history_flag,temporary_remittance_rate_factor,maximum_review_duration_days,reassessment_interval_days,expected_policy_rows,expected_outcome_rows,expected_action_rows,expected_reason_rows,expected_source_rows,expected_strategy_rows,expected_portfolio_summary_rows,expected_latest_rows,expected_archive_rows,expected_comparison_rows,expected_registry_rows,expected_canonical_entities,expected_positive_controls,expected_negative_controls,expected_detail_result_sets,configuration_payload,configuration_hash,row_hash FROM hashed ON CONFLICT(module1_run_id) DO NOTHING;

WITH run_context AS (SELECT module1_run_id FROM msbf_ctl.m2_6_policy_profile WHERE policy_code='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_POLICY_V1'), outcome_seed AS (SELECT run_context.module1_run_id, v.* FROM run_context CROSS JOIN (VALUES ('CLOSED_NO_FURTHER_ACTION', 0, FALSE, FALSE, FALSE, FALSE, FALSE, 'Paid-off advance; no servicing intervention recommended.'),
        ('CONTINUE_STANDARD_MONITORING', 1, FALSE, FALSE, FALSE, FALSE, FALSE, 'Monitoring continues without intervention recommendation.'),
        ('TARGETED_MERCHANT_OUTREACH_REVIEW', 2, TRUE, TRUE, FALSE, FALSE, FALSE, 'Internal review recommends targeted merchant outreach evaluation.'),
        ('TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW', 3, TRUE, TRUE, TRUE, FALSE, FALSE, 'Internal review recommends temporary remittance-adjustment evaluation.'),
        ('WORKOUT_RESTRUCTURE_REVIEW', 4, TRUE, TRUE, FALSE, TRUE, FALSE, 'Internal review recommends workout/restructure evaluation.'),
        ('CONTROLLED_EXIT_RECOVERY_REVIEW', 5, TRUE, TRUE, FALSE, FALSE, TRUE, 'Internal review recommends controlled-exit/recovery evaluation.'),
        ('MANUAL_GOVERNANCE_REVIEW', 9, TRUE, TRUE, FALSE, FALSE, FALSE, 'Fail-closed manual governance review for unresolved conditions.')) AS v(strategy_outcome_code,strategy_outcome_rank,recommended_action_flag,review_required_flag,temporary_adjustment_review_flag,workout_review_flag,recovery_review_flag,description)), hashed AS (SELECT seed.*, FALSE::boolean AS executed_action_flag, 'APPROVED'::text AS definition_status, msbf_ctl.m2_6_hash_jsonb(to_jsonb(seed) || '{"executed_action_flag":false,"definition_status":"APPROVED"}'::jsonb) AS row_hash FROM outcome_seed AS seed)
INSERT INTO msbf_m2.intervention_strategy_outcome_definition(module1_run_id,strategy_outcome_code,strategy_outcome_rank,recommended_action_flag,review_required_flag,temporary_adjustment_review_flag,workout_review_flag,recovery_review_flag,executed_action_flag,definition_status,description,row_hash)
SELECT module1_run_id,strategy_outcome_code,strategy_outcome_rank,recommended_action_flag,review_required_flag,temporary_adjustment_review_flag,workout_review_flag,recovery_review_flag,executed_action_flag,definition_status,description,row_hash FROM hashed ON CONFLICT(module1_run_id,strategy_outcome_code) DO NOTHING;

WITH run_context AS (SELECT module1_run_id FROM msbf_ctl.m2_6_policy_profile WHERE policy_code='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_POLICY_V1'), action_seed AS (SELECT run_context.module1_run_id, v.* FROM run_context CROSS JOIN (VALUES ('NO_ACTION_CLOSED', 0, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, 'No action for paid-off advances.'),
        ('CONTINUE_STANDARD_MONITORING', 1, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, 'Continue standard synthetic monitoring.'),
        ('OUTREACH_REVIEW_QUEUE', 2, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, 'Queue for merchant-outreach review only.'),
        ('TEMPORARY_REMITTANCE_REVIEW', 3, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, 'Queue for temporary remittance-adjustment review only.'),
        ('WORKOUT_RESTRUCTURE_REVIEW', 4, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, 'Queue for workout/restructure review only.'),
        ('CONTROLLED_EXIT_RECOVERY_REVIEW', 5, TRUE, FALSE, FALSE, TRUE, FALSE, FALSE, 'Queue for controlled-exit/recovery review only.'),
        ('MANUAL_GOVERNANCE_ESCALATION', 9, TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, 'Queue for manual governance review only.')) AS v(servicing_action_code,servicing_action_rank,merchant_contact_review_flag,payment_change_review_flag,workout_review_flag,recovery_review_flag,governance_review_flag,executed_servicing_action_flag,description)), hashed AS (SELECT seed.*, 'APPROVED'::text AS definition_status, msbf_ctl.m2_6_hash_jsonb(to_jsonb(seed) || '{"definition_status":"APPROVED"}'::jsonb) AS row_hash FROM action_seed AS seed)
INSERT INTO msbf_m2.intervention_servicing_action_definition(module1_run_id,servicing_action_code,servicing_action_rank,merchant_contact_review_flag,payment_change_review_flag,workout_review_flag,recovery_review_flag,governance_review_flag,executed_servicing_action_flag,definition_status,description,row_hash)
SELECT module1_run_id,servicing_action_code,servicing_action_rank,merchant_contact_review_flag,payment_change_review_flag,workout_review_flag,recovery_review_flag,governance_review_flag,executed_servicing_action_flag,definition_status,description,row_hash FROM hashed ON CONFLICT(module1_run_id,servicing_action_code) DO NOTHING;

WITH run_context AS (SELECT module1_run_id FROM msbf_ctl.m2_6_policy_profile WHERE policy_code='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_POLICY_V1'), reason_seed AS (SELECT run_context.module1_run_id, v.* FROM run_context CROSS JOIN (VALUES ('M2_6_REASON_PAID_OFF_CLOSED', 'CLOSED_NO_FURTHER_ACTION', 'NO_ACTION_CLOSED', 'Paid-off monitoring record closes with no further action.'),
        ('M2_6_REASON_CURRENT_MONITORING_CONTINUES', 'CONTINUE_STANDARD_MONITORING', 'CONTINUE_STANDARD_MONITORING', 'Current monitoring can continue without intervention.'),
        ('M2_6_REASON_WATCH_OUTREACH_REVIEW', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'Watch status supports outreach review.'),
        ('M2_6_REASON_UNDERPERFORMING_OUTREACH_REVIEW', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'Underperforming status supports outreach review.'),
        ('M2_6_REASON_SEVERE_SHORTFALL_OUTREACH_REVIEW', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'Severe shortfall supports targeted outreach review.'),
        ('M2_6_REASON_SEVERE_SHORTFALL_TEMPORARY_REMITTANCE_REVIEW', 'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW', 'TEMPORARY_REMITTANCE_REVIEW', 'Severe shortfall supports temporary remittance-adjustment review.'),
        ('M2_6_REASON_DORMANT_WORKOUT_REVIEW', 'WORKOUT_RESTRUCTURE_REVIEW', 'WORKOUT_RESTRUCTURE_REVIEW', 'Dormant no-remittance condition supports workout review.'),
        ('M2_6_REASON_RECOVERY_EXIT_REVIEW', 'CONTROLLED_EXIT_RECOVERY_REVIEW', 'CONTROLLED_EXIT_RECOVERY_REVIEW', 'Persistent exposure and severe condition supports controlled exit review.'),
        ('M2_6_REASON_MANUAL_GOVERNANCE_FALLBACK', 'MANUAL_GOVERNANCE_REVIEW', 'MANUAL_GOVERNANCE_ESCALATION', 'Unexpected source pattern requires manual governance review.'),
        ('M2_6_REASON_RESIDUAL_EXPOSURE_PRESENT', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'Residual receivable exposure is present.'),
        ('M2_6_REASON_PRINCIPAL_EXPOSURE_PRESENT', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'Principal exposure proxy is positive.'),
        ('M2_6_REASON_UNEARNED_FINANCE_PRESENT', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'Unearned finance-charge exposure proxy is positive.'),
        ('M2_6_REASON_CUMULATIVE_SHORTFALL_PRESENT', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'Cumulative remittance shortfall is positive.'),
        ('M2_6_REASON_LOW_PACE_RATIO', 'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW', 'TEMPORARY_REMITTANCE_REVIEW', 'Cumulative pace ratio is below intervention threshold.'),
        ('M2_6_REASON_LOW_TRAILING_REMITTANCE', 'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW', 'TEMPORARY_REMITTANCE_REVIEW', 'Trailing remittance evidence supports remittance review.'),
        ('M2_6_REASON_ZERO_SALES_STREAK', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'Zero-sales streak is present.'),
        ('M2_6_REASON_NO_RECENT_REMITTANCE', 'WORKOUT_RESTRUCTURE_REVIEW', 'WORKOUT_RESTRUCTURE_REVIEW', 'No recent remittance supports workout review.'),
        ('M2_6_REASON_LIQUIDITY_STRESS', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'Low available balance or NSF evidence exists.'),
        ('M2_6_REASON_ACTIVE_ALERTS', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'Active monitoring alerts are present.'),
        ('M2_6_REASON_STRESS_SCENARIO_CONTEXT', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'Stress scenario context retained for monitoring governance.'),
        ('M2_6_REASON_STRESS_FLOOR_APPLIED', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'Stress-status floor applied in upstream monitoring.'),
        ('M2_6_REASON_PORTFOLIO_CONCENTRATION', 'MANUAL_GOVERNANCE_REVIEW', 'MANUAL_GOVERNANCE_ESCALATION', 'Portfolio concentration requires governance review.'),
        ('M2_6_REASON_HIGH_PRIORITY_EXPOSURE', 'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW', 'TEMPORARY_REMITTANCE_REVIEW', 'Exposure and severity combine into high priority.'),
        ('M2_6_REASON_REASSESSMENT_REQUIRED', 'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW', 'TEMPORARY_REMITTANCE_REVIEW', 'Recommendation requires controlled reassessment timing.'),
        ('M2_6_REASON_TEMPORARY_REVIEW_BOUNDARY', 'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW', 'TEMPORARY_REMITTANCE_REVIEW', 'Temporary review terms remain review-only and non-executed.'),
        ('M2_6_REASON_NO_MERCHANT_CONTACT_EXECUTED', 'TARGETED_MERCHANT_OUTREACH_REVIEW', 'OUTREACH_REVIEW_QUEUE', 'No merchant contact is executed by M2.6.'),
        ('M2_6_REASON_NO_PAYMENT_CHANGE_EXECUTED', 'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW', 'TEMPORARY_REMITTANCE_REVIEW', 'No payment or remittance change is executed by M2.6.'),
        ('M2_6_REASON_NO_WRITE_OFF_EXECUTED', 'CONTROLLED_EXIT_RECOVERY_REVIEW', 'CONTROLLED_EXIT_RECOVERY_REVIEW', 'No write-off or charge-off is executed by M2.6.'),
        ('M2_6_REASON_NO_EXTERNAL_NOTICE', 'MANUAL_GOVERNANCE_REVIEW', 'MANUAL_GOVERNANCE_ESCALATION', 'No external notice is generated by M2.6.'),
        ('M2_6_REASON_NO_PRODUCTION_ADVERSE_ACTION', 'MANUAL_GOVERNANCE_REVIEW', 'MANUAL_GOVERNANCE_ESCALATION', 'No production adverse-action notice is generated by M2.6.')) AS v(intervention_reason_code,mapped_strategy_outcome_code,mapped_servicing_action_code,description)), hashed AS (SELECT seed.*, FALSE::boolean AS production_adverse_action_notice_flag, FALSE::boolean AS executed_servicing_action_flag, 'APPROVED'::text AS definition_status, msbf_ctl.m2_6_hash_jsonb(to_jsonb(seed) || '{"production_adverse_action_notice_flag":false,"executed_servicing_action_flag":false,"definition_status":"APPROVED"}'::jsonb) AS row_hash FROM reason_seed AS seed)
INSERT INTO msbf_m2.intervention_reason_definition(module1_run_id,intervention_reason_code,mapped_strategy_outcome_code,mapped_servicing_action_code,production_adverse_action_notice_flag,executed_servicing_action_flag,definition_status,description,row_hash)
SELECT module1_run_id,intervention_reason_code,mapped_strategy_outcome_code,mapped_servicing_action_code,production_adverse_action_notice_flag,executed_servicing_action_flag,definition_status,description,row_hash FROM hashed ON CONFLICT(module1_run_id,intervention_reason_code) DO NOTHING;

CREATE OR REPLACE VIEW msbf_m2.v_m2_6_intervention_strategy_latest AS SELECT latest.*, outcome.description AS strategy_outcome_description, action.description AS servicing_action_description, reason.description AS primary_reason_description FROM msbf_m2.advance_intervention_strategy_latest AS latest JOIN msbf_m2.intervention_strategy_outcome_definition AS outcome ON outcome.module1_run_id=latest.module1_run_id AND outcome.strategy_outcome_code=latest.strategy_outcome_code JOIN msbf_m2.intervention_servicing_action_definition AS action ON action.module1_run_id=latest.module1_run_id AND action.servicing_action_code=latest.servicing_action_code JOIN msbf_m2.intervention_reason_definition AS reason ON reason.module1_run_id=latest.module1_run_id AND reason.intervention_reason_code=latest.primary_intervention_reason_code;

CREATE OR REPLACE VIEW msbf_m2.v_m2_6_matched_scenario_comparison AS SELECT baseline.module1_run_id, baseline.merchant_application_id, baseline.strategy_outcome_code AS baseline_strategy_outcome_code, stress.strategy_outcome_code AS stress_strategy_outcome_code, baseline.strategy_outcome_rank AS baseline_strategy_outcome_rank, stress.strategy_outcome_rank AS stress_strategy_outcome_rank, baseline.servicing_priority_rank AS baseline_servicing_priority_rank, stress.servicing_priority_rank AS stress_servicing_priority_rank, baseline.recommended_action_exposure_amount AS baseline_recommended_action_exposure_amount, stress.recommended_action_exposure_amount AS stress_recommended_action_exposure_amount, (stress.strategy_outcome_rank < baseline.strategy_outcome_rank) AS stress_strategy_improvement_flag, (stress.servicing_priority_rank < baseline.servicing_priority_rank) AS stress_action_improvement_flag FROM msbf_m2.advance_intervention_strategy_latest AS baseline JOIN msbf_m2.advance_intervention_strategy_latest AS stress ON stress.module1_run_id=baseline.module1_run_id AND stress.merchant_application_id=baseline.merchant_application_id AND stress.scenario_code='RECESSION_ENERGY' WHERE baseline.scenario_code='BASELINE';

CREATE OR REPLACE VIEW msbf_m2.v_m2_6_power_bi_intervention_strategy AS SELECT module1_run_id, scenario_code, merchant_application_id, synthetic_account_id, synthetic_advance_id, strategy_outcome_code, servicing_action_code, servicing_queue_code, servicing_priority_rank, recommended_action_flag, review_required_flag, recommended_action_exposure_amount, primary_intervention_reason_code FROM msbf_m2.advance_intervention_strategy_latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_6_intervention_lineage AS SELECT module1_run_id, scenario_id, scenario_code, merchant_application_id, contract_code, contract_version, schema_version, source_m2_5_contract_row_hash, source_snapshot_row_hash, strategy_snapshot_row_hash, contract_row_hash FROM msbf_m2.advance_intervention_strategy_latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_6_canonical_entity AS SELECT policy.module1_run_id,'POLICY'::text AS entity_type,policy.policy_code||'|v'||policy.policy_version::text AS entity_key,policy.row_hash FROM msbf_ctl.m2_6_policy_profile AS policy UNION ALL SELECT outcome.module1_run_id,'OUTCOME',outcome.strategy_outcome_code,outcome.row_hash FROM msbf_m2.intervention_strategy_outcome_definition AS outcome UNION ALL SELECT action.module1_run_id,'ACTION',action.servicing_action_code,action.row_hash FROM msbf_m2.intervention_servicing_action_definition AS action UNION ALL SELECT reason.module1_run_id,'REASON',reason.intervention_reason_code,reason.row_hash FROM msbf_m2.intervention_reason_definition AS reason UNION ALL SELECT source.module1_run_id,'SOURCE',source.scenario_id::text||'|'||source.merchant_application_id,source.row_hash FROM msbf_m2.advance_intervention_source_snapshot AS source UNION ALL SELECT strategy.module1_run_id,'STRATEGY',strategy.scenario_id::text||'|'||strategy.merchant_application_id,strategy.row_hash FROM msbf_m2.advance_intervention_strategy_snapshot AS strategy UNION ALL SELECT portfolio.module1_run_id,'PORTFOLIO_SUMMARY',portfolio.scenario_code,portfolio.row_hash FROM msbf_m2.portfolio_intervention_strategy_summary AS portfolio UNION ALL SELECT latest.module1_run_id,'LATEST',latest.scenario_id::text||'|'||latest.merchant_application_id,latest.contract_row_hash FROM msbf_m2.advance_intervention_strategy_latest AS latest UNION ALL SELECT archive.module1_run_id,'ARCHIVE',archive.scenario_id::text||'|'||archive.merchant_application_id,archive.archive_row_hash FROM msbf_m2.advance_intervention_strategy_archive AS archive UNION ALL SELECT registry.module1_run_id,'REGISTRY',registry.contract_code||'|v'||registry.contract_version::text,registry.row_hash FROM msbf_ctl.m2_6_intervention_strategy_contract_registry AS registry;
CREATE OR REPLACE VIEW msbf_m2.v_m2_6_canonical_hash AS SELECT canonical.module1_run_id, count(*)::bigint AS canonical_entities, md5(string_agg(canonical.entity_type||'|'||canonical.entity_key||'|'||canonical.row_hash,'|' ORDER BY canonical.entity_type, canonical.entity_key)) AS combined_set_hash FROM msbf_m2.v_m2_6_canonical_entity AS canonical GROUP BY canonical.module1_run_id;

DO $guard$
DECLARE v_run bigint; v_gate bigint; v_policy bigint; v_outcome bigint; v_action bigint; v_reason bigint;
BEGIN
    SELECT module1_run_id INTO v_run FROM msbf_ctl.m2_6_policy_profile WHERE policy_code='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_POLICY_V1';
    PERFORM msbf_ctl.m2_6_assert_configuration(v_run);
    SELECT count(*) INTO v_gate FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY' AND active_flag;
    SELECT count(*) INTO v_policy FROM msbf_ctl.m2_6_policy_profile WHERE module1_run_id=v_run;
    SELECT count(*) INTO v_outcome FROM msbf_m2.intervention_strategy_outcome_definition WHERE module1_run_id=v_run AND definition_status='APPROVED';
    SELECT count(*) INTO v_action FROM msbf_m2.intervention_servicing_action_definition WHERE module1_run_id=v_run AND definition_status='APPROVED';
    SELECT count(*) INTO v_reason FROM msbf_m2.intervention_reason_definition WHERE module1_run_id=v_run AND definition_status='APPROVED';
    IF v_gate<>1 OR v_policy<>1 OR v_outcome<>7 OR v_action<>7 OR v_reason<>30 THEN RAISE EXCEPTION 'M2.6 schema/policy extension failed: gate %, policy %, outcome %, action %, reason %.', v_gate, v_policy, v_outcome, v_action, v_reason; END IF;
END;
$guard$;

COMMIT;
SELECT policy.module1_run_id, policy.policy_code, policy.policy_status, policy.methodology_version, policy.contract_code, policy.contract_version, policy.schema_version, policy.source_m2_5_combined_hash, policy.configuration_hash, (SELECT count(*) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY' AND active_flag) AS acceptance_gate_catalog_rows, (SELECT count(*) FROM msbf_m2.intervention_strategy_outcome_definition WHERE module1_run_id=policy.module1_run_id) AS outcome_definition_rows, (SELECT count(*) FROM msbf_m2.intervention_servicing_action_definition WHERE module1_run_id=policy.module1_run_id) AS action_definition_rows, (SELECT count(*) FROM msbf_m2.intervention_reason_definition WHERE module1_run_id=policy.module1_run_id) AS reason_definition_rows, CASE WHEN policy.policy_status='APPROVED' AND policy.recommendation_only_flag AND policy.no_merchant_contact_execution_flag AND policy.no_payment_change_execution_flag AND policy.no_write_off_charge_off_execution_flag AND policy.no_legal_or_collection_action_flag AND policy.no_external_notice_generation_flag AND policy.no_production_adverse_action_notice_flag THEN 'PASS' ELSE 'FAIL' END AS schema_policy_status FROM msbf_ctl.m2_6_policy_profile AS policy WHERE policy.policy_code='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_POLICY_V1';
