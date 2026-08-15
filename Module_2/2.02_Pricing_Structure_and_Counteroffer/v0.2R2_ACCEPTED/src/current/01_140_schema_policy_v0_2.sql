/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M2.2 — Pricing, Structure & Counteroffer Foundations

Program : 140_msbf_m2_2_schema_policy_structure_contract_extension_v0_2.sql
Version : v0.2
Purpose : Create the governed policy, request companion, candidate ledger,
          pricing/structure contracts, immutable archives, assertions, views,
          reference dictionaries and acceptance-gate definition for M2.2.

Boundary
M2.2 creates governed pricing and structure foundations only. It does not
issue an approval, decline, final counteroffer, adverse-action notice, booking
or funding outcome.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='20min';
SET LOCAL jit=off;

CREATE SCHEMA IF NOT EXISTS msbf_m2;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_2_hash_jsonb(p_value jsonb)
RETURNS text LANGUAGE sql IMMUTABLE STRICT
AS $function$ SELECT md5(p_value::text); $function$;

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_2_policy_profile (
    policy_code text PRIMARY KEY,
    methodology_version text NOT NULL,
    request_contract_code text NOT NULL,
    request_contract_version integer NOT NULL,
    request_schema_version text NOT NULL,
    pricing_contract_code text NOT NULL,
    pricing_contract_version integer NOT NULL,
    pricing_schema_version text NOT NULL,
    acceptance_gate_id text NOT NULL,
    source_m2_1_contract_code text NOT NULL,
    source_m2_1_contract_version integer NOT NULL,
    source_m2_1_schema_version text NOT NULL,
    required_source_m2_1_hash text NOT NULL,
    source_m1_3_gate_id text NOT NULL,
    required_source_m1_3_hash text NOT NULL,
    expected_policy_rows integer NOT NULL,
    expected_template_rows integer NOT NULL,
    expected_reason_rows integer NOT NULL,
    expected_disposition_rows integer NOT NULL,
    expected_request_snapshot_rows integer NOT NULL,
    expected_request_latest_rows integer NOT NULL,
    expected_request_archive_rows integer NOT NULL,
    expected_candidate_rows integer NOT NULL,
    expected_pricing_snapshot_rows integer NOT NULL,
    expected_pricing_latest_rows integer NOT NULL,
    expected_pricing_archive_rows integer NOT NULL,
    expected_comparison_rows integer NOT NULL,
    expected_registry_rows integer NOT NULL,
    expected_canonical_entities integer NOT NULL,
    expected_positive_controls integer NOT NULL,
    expected_negative_controls integer NOT NULL,
    expected_detail_result_sets integer NOT NULL,
    expected_generation_evidence_rows integer NOT NULL,
    amount_rounding_increment numeric(18,2) NOT NULL,
    minimum_candidate_amount numeric(18,2) NOT NULL,
    minimum_remittance_rate numeric(9,6) NOT NULL,
    maximum_remittance_rate numeric(9,6) NOT NULL,
    minimum_payback_multiple numeric(9,6) NOT NULL,
    maximum_payback_multiple numeric(9,6) NOT NULL,
    maximum_collection_horizon_days integer NOT NULL,
    implied_payoff_tolerance numeric(9,6) NOT NULL,
    stress_expected_loss_multiplier numeric(9,6) NOT NULL,
    relationship_pricing_adjustment numeric(9,6) NOT NULL,
    synthetic_data_only_flag boolean NOT NULL,
    counteroffer_foundation_only_flag boolean NOT NULL,
    no_final_credit_decision_flag boolean NOT NULL,
    no_production_adverse_action_flag boolean NOT NULL,
    no_booking_funding_flag boolean NOT NULL,
    acquisition_source_noncredit_flag boolean NOT NULL,
    stress_nonimprovement_flag boolean NOT NULL,
    request_companion_required_flag boolean NOT NULL,
    policy_status text NOT NULL,
    configuration_payload jsonb NOT NULL,
    configuration_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT ck_m2_2_policy_status CHECK(policy_status IN('DRAFT','APPROVED','RETIRED')),
    CONSTRAINT ck_m2_2_policy_rates CHECK(minimum_remittance_rate>0 AND maximum_remittance_rate<=1 AND minimum_remittance_rate<=maximum_remittance_rate),
    CONSTRAINT ck_m2_2_policy_payback CHECK(minimum_payback_multiple>=1 AND minimum_payback_multiple<=maximum_payback_multiple),
    CONSTRAINT ck_m2_2_policy_hash CHECK(length(configuration_hash)=32 AND configuration_hash ~ '^[0-9a-f]+$')
);

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_2_pricing_structure_contract_registry (
    registry_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id bigint NOT NULL UNIQUE,
    request_contract_code text NOT NULL,
    request_contract_version integer NOT NULL,
    request_schema_version text NOT NULL,
    pricing_contract_code text NOT NULL,
    pricing_contract_version integer NOT NULL,
    pricing_schema_version text NOT NULL,
    methodology_version text NOT NULL,
    source_m2_1_contract_code text NOT NULL,
    source_m2_1_contract_version integer NOT NULL,
    source_m2_1_schema_version text NOT NULL,
    source_m2_1_combined_hash text NOT NULL,
    source_m1_3_gate_id text NOT NULL,
    source_m1_3_application_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    policy_rows bigint NOT NULL,
    template_rows bigint NOT NULL,
    reason_rows bigint NOT NULL,
    disposition_rows bigint NOT NULL,
    request_snapshot_rows bigint NOT NULL,
    request_latest_rows bigint NOT NULL,
    request_archive_rows bigint NOT NULL,
    candidate_rows bigint NOT NULL,
    pricing_snapshot_rows bigint NOT NULL,
    pricing_latest_rows bigint NOT NULL,
    pricing_archive_rows bigint NOT NULL,
    comparison_rows bigint NOT NULL,
    canonical_entities bigint NOT NULL,
    policy_set_hash text NOT NULL,
    template_set_hash text NOT NULL,
    reason_set_hash text NOT NULL,
    disposition_set_hash text NOT NULL,
    request_snapshot_set_hash text NOT NULL,
    request_latest_set_hash text NOT NULL,
    request_archive_set_hash text NOT NULL,
    candidate_set_hash text NOT NULL,
    pricing_snapshot_set_hash text NOT NULL,
    pricing_latest_set_hash text NOT NULL,
    pricing_archive_set_hash text NOT NULL,
    request_contract_set_hash text NOT NULL,
    pricing_contract_set_hash text NOT NULL,
    combined_set_hash text NOT NULL,
    contract_status text NOT NULL,
    generated_at timestamptz,
    validated_at timestamptz,
    accepted_at timestamptz,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT fk_m2_2_registry_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT ck_m2_2_registry_status CHECK(contract_status IN('GENERATED','VALIDATED','ACCEPTED')),
    CONSTRAINT ck_m2_2_registry_hash CHECK(length(row_hash)=32 AND row_hash ~ '^[0-9a-f]+$')
);

CREATE TABLE IF NOT EXISTS msbf_m2.pricing_structure_candidate_template (
    module1_run_id bigint NOT NULL,
    candidate_template_code text NOT NULL,
    template_sequence integer NOT NULL,
    applicable_route_code text NOT NULL,
    amount_multiplier numeric(9,6) NOT NULL,
    remittance_multiplier numeric(9,6) NOT NULL,
    payback_multiplier numeric(9,6) NOT NULL,
    horizon_multiplier numeric(9,6) NOT NULL,
    counteroffer_foundation_flag boolean NOT NULL,
    active_flag boolean NOT NULL,
    description text NOT NULL,
    policy_configuration_hash text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,candidate_template_code),
    UNIQUE(module1_run_id,applicable_route_code,template_sequence),
    CONSTRAINT ck_m2_2_template_route CHECK(applicable_route_code IN('ELIGIBLE_FOR_OFFER_DESIGN','MANUAL_REVIEW')),
    CONSTRAINT ck_m2_2_template_multiplier CHECK(amount_multiplier>0 AND remittance_multiplier>0 AND payback_multiplier>0 AND horizon_multiplier>0)
);

CREATE TABLE IF NOT EXISTS msbf_m2.pricing_structure_reason_definition (
    module1_run_id bigint NOT NULL,
    reason_code text NOT NULL,
    reason_category text NOT NULL,
    associated_disposition_code text NOT NULL,
    reason_priority integer NOT NULL,
    display_text text NOT NULL,
    production_adverse_action_flag boolean NOT NULL,
    active_flag boolean NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,reason_code)
);

CREATE TABLE IF NOT EXISTS msbf_m2.pricing_structure_disposition_definition (
    module1_run_id bigint NOT NULL,
    disposition_code text NOT NULL,
    disposition_rank integer NOT NULL,
    structure_available_flag boolean NOT NULL,
    review_required_flag boolean NOT NULL,
    final_decision_flag boolean NOT NULL,
    booking_funding_flag boolean NOT NULL,
    active_flag boolean NOT NULL,
    description text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,disposition_code),
    CONSTRAINT ck_m2_2_disposition_boundary CHECK(final_decision_flag=FALSE AND booking_funding_flag=FALSE)
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_request_structure_snapshot (
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    application_date date NOT NULL,
    requested_funding_amount numeric(18,2) NOT NULL,
    requested_remittance_rate numeric(9,6) NOT NULL,
    requested_expected_payoff_days integer NOT NULL,
    requested_total_repayment_amount numeric(18,2) NOT NULL,
    requested_finance_charge_amount numeric(18,2) NOT NULL,
    requested_payback_multiple numeric(9,6) NOT NULL,
    requested_use_of_proceeds text NOT NULL,
    application_channel text NOT NULL,
    source_request_hash text NOT NULL,
    source_m1_3_application_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,merchant_application_id)
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_request_structure_latest (
    module1_run_id bigint NOT NULL,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    methodology_version text NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    requested_funding_amount numeric(18,2) NOT NULL,
    requested_remittance_rate numeric(9,6) NOT NULL,
    requested_expected_payoff_days integer NOT NULL,
    requested_total_repayment_amount numeric(18,2) NOT NULL,
    requested_finance_charge_amount numeric(18,2) NOT NULL,
    requested_payback_multiple numeric(9,6) NOT NULL,
    requested_use_of_proceeds text NOT NULL,
    application_channel text NOT NULL,
    source_request_hash text NOT NULL,
    source_snapshot_row_hash text NOT NULL,
    source_m1_3_application_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    contract_row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,merchant_application_id)
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_request_structure_archive (
    archive_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id bigint NOT NULL,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    merchant_application_id text NOT NULL,
    contract_payload jsonb NOT NULL,
    contract_row_hash text NOT NULL,
    source_latest_row_hash text NOT NULL,
    archive_row_hash text NOT NULL,
    archived_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE(module1_run_id,contract_code,contract_version,merchant_application_id)
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_pricing_structure_candidate (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    candidate_template_code text NOT NULL,
    template_sequence integer NOT NULL,
    source_route_code text NOT NULL,
    source_route_rank integer NOT NULL,
    requested_funding_amount numeric(18,2) NOT NULL,
    candidate_funding_amount numeric(18,2) NOT NULL,
    candidate_remittance_rate numeric(9,6) NOT NULL,
    candidate_payback_multiple numeric(9,6) NOT NULL,
    candidate_collection_horizon_days integer NOT NULL,
    candidate_total_repayment_amount numeric(18,2) NOT NULL,
    candidate_finance_charge_amount numeric(18,2) NOT NULL,
    implied_daily_collection_amount numeric(18,2) NOT NULL,
    implied_payoff_days numeric(18,4) NOT NULL,
    amount_to_request_ratio numeric(12,8) NOT NULL,
    capacity_alignment_ratio numeric(12,8),
    risk_load_rate numeric(9,6) NOT NULL,
    resilience_load_rate numeric(9,6) NOT NULL,
    economic_load_rate numeric(9,6) NOT NULL,
    stress_load_rate numeric(9,6) NOT NULL,
    acquisition_economics_amount numeric(18,2),
    expected_loss_amount numeric(18,2),
    risk_adjusted_contribution_amount numeric(18,2),
    annualized_return_rate numeric(12,8),
    counteroffer_foundation_flag boolean NOT NULL,
    candidate_eligible_flag boolean NOT NULL,
    selected_foundation_flag boolean NOT NULL,
    candidate_rank integer NOT NULL,
    primary_reason_code text NOT NULL,
    secondary_reason_codes jsonb NOT NULL,
    source_m2_1_contract_row_hash text NOT NULL,
    source_request_contract_row_hash text NOT NULL,
    source_m1_15_contract_row_hash text NOT NULL,
    source_m1_16_contract_row_hash text NOT NULL,
    source_g2_combined_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id,candidate_template_code),
    CONSTRAINT ck_m2_2_candidate_amount CHECK(candidate_funding_amount>=0 AND candidate_funding_amount<=requested_funding_amount),
    CONSTRAINT ck_m2_2_candidate_rate CHECK(candidate_remittance_rate BETWEEN 0.05 AND 0.20),
    CONSTRAINT ck_m2_2_candidate_payback CHECK(candidate_payback_multiple BETWEEN 1.05 AND 1.40),
    CONSTRAINT ck_m2_2_candidate_horizon CHECK(candidate_collection_horizon_days BETWEEN 1 AND 120)
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_pricing_structure_snapshot (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    source_route_code text NOT NULL,
    source_route_rank integer NOT NULL,
    pricing_disposition_code text NOT NULL,
    structure_available_flag boolean NOT NULL,
    review_required_flag boolean NOT NULL,
    selected_candidate_template_code text,
    selected_candidate_row_hash text,
    requested_funding_amount numeric(18,2) NOT NULL,
    selected_funding_amount numeric(18,2),
    selected_remittance_rate numeric(9,6),
    selected_payback_multiple numeric(9,6),
    selected_collection_horizon_days integer,
    selected_total_repayment_amount numeric(18,2),
    selected_finance_charge_amount numeric(18,2),
    selected_implied_daily_collection_amount numeric(18,2),
    selected_implied_payoff_days numeric(18,4),
    selected_amount_to_request_ratio numeric(12,8),
    candidate_count integer NOT NULL,
    counteroffer_foundation_flag boolean NOT NULL,
    stress_nonimprovement_applied_flag boolean NOT NULL,
    primary_reason_code text NOT NULL,
    reason_codes jsonb NOT NULL,
    routing_evidence_status text NOT NULL,
    source_m2_1_contract_row_hash text NOT NULL,
    source_request_contract_row_hash text NOT NULL,
    source_g2_combined_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_2_snapshot_disposition CHECK(pricing_disposition_code IN('STRUCTURE_READY','COUNTEROFFER_FOUNDATION_REVIEW','NO_STRUCTURE_INSUFFICIENT_EVIDENCE','NO_STRUCTURE_POLICY_DECLINE')),
    CONSTRAINT ck_m2_2_snapshot_structure CHECK(structure_available_flag=(selected_candidate_template_code IS NOT NULL))
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_pricing_structure_latest (
    module1_run_id bigint NOT NULL,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    methodology_version text NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    source_route_code text NOT NULL,
    source_route_rank integer NOT NULL,
    pricing_disposition_code text NOT NULL,
    structure_available_flag boolean NOT NULL,
    review_required_flag boolean NOT NULL,
    selected_candidate_template_code text,
    selected_candidate_row_hash text,
    requested_funding_amount numeric(18,2) NOT NULL,
    selected_funding_amount numeric(18,2),
    selected_remittance_rate numeric(9,6),
    selected_payback_multiple numeric(9,6),
    selected_collection_horizon_days integer,
    selected_total_repayment_amount numeric(18,2),
    selected_finance_charge_amount numeric(18,2),
    selected_implied_daily_collection_amount numeric(18,2),
    selected_implied_payoff_days numeric(18,4),
    selected_amount_to_request_ratio numeric(12,8),
    candidate_count integer NOT NULL,
    counteroffer_foundation_flag boolean NOT NULL,
    stress_nonimprovement_applied_flag boolean NOT NULL,
    primary_reason_code text NOT NULL,
    reason_codes jsonb NOT NULL,
    routing_evidence_status text NOT NULL,
    source_m2_1_contract_row_hash text NOT NULL,
    source_request_contract_row_hash text NOT NULL,
    source_g2_combined_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    source_snapshot_row_hash text NOT NULL,
    contract_row_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id)
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_pricing_structure_archive (
    archive_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id bigint NOT NULL,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    contract_payload jsonb NOT NULL,
    contract_row_hash text NOT NULL,
    source_latest_row_hash text NOT NULL,
    archive_row_hash text NOT NULL,
    archived_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE(module1_run_id,contract_code,contract_version,scenario_id,merchant_application_id)
);

CREATE INDEX IF NOT EXISTS ix_m2_2_candidate_selection ON msbf_m2.application_pricing_structure_candidate(module1_run_id,scenario_id,merchant_application_id,selected_foundation_flag,candidate_rank);
CREATE INDEX IF NOT EXISTS ix_m2_2_candidate_template ON msbf_m2.application_pricing_structure_candidate(module1_run_id,candidate_template_code,scenario_code);
CREATE INDEX IF NOT EXISTS ix_m2_2_snapshot_disposition ON msbf_m2.application_pricing_structure_snapshot(module1_run_id,scenario_code,pricing_disposition_code);
CREATE INDEX IF NOT EXISTS ix_m2_2_latest_disposition ON msbf_m2.application_pricing_structure_latest(module1_run_id,scenario_code,pricing_disposition_code);
CREATE INDEX IF NOT EXISTS ix_m2_2_request_latest ON msbf_m2.application_request_structure_latest(module1_run_id,merchant_application_id);

CREATE OR REPLACE FUNCTION msbf_m2.m2_2_reject_request_archive_mutation()
RETURNS trigger LANGUAGE plpgsql AS $function$
BEGIN
    RAISE EXCEPTION 'M2.2 request archive is immutable: % is not permitted.',TG_OP;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_m2.m2_2_reject_pricing_archive_mutation()
RETURNS trigger LANGUAGE plpgsql AS $function$
BEGIN
    RAISE EXCEPTION 'M2.2 pricing archive is immutable: % is not permitted.',TG_OP;
END;
$function$;

DROP TRIGGER IF EXISTS trg_m2_2_request_archive_immutable ON msbf_m2.application_request_structure_archive;
CREATE TRIGGER trg_m2_2_request_archive_immutable BEFORE UPDATE OR DELETE ON msbf_m2.application_request_structure_archive FOR EACH ROW EXECUTE FUNCTION msbf_m2.m2_2_reject_request_archive_mutation();
DROP TRIGGER IF EXISTS trg_m2_2_pricing_archive_immutable ON msbf_m2.application_pricing_structure_archive;
CREATE TRIGGER trg_m2_2_pricing_archive_immutable BEFORE UPDATE OR DELETE ON msbf_m2.application_pricing_structure_archive FOR EACH ROW EXECUTE FUNCTION msbf_m2.m2_2_reject_pricing_archive_mutation();

CREATE OR REPLACE FUNCTION msbf_ctl.m2_2_assert_configuration(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v msbf_ctl.m2_2_policy_profile%ROWTYPE;
BEGIN
    SELECT * INTO v FROM msbf_ctl.m2_2_policy_profile WHERE policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1';
    IF NOT FOUND
       OR v.policy_status<>'APPROVED'
       OR v.methodology_version<>'M2_2_METHOD_V1'
       OR v.request_contract_code<>'M2_REQUEST_STRUCTURE_CONSUMPTION'
       OR v.request_contract_version<>1
       OR v.request_schema_version<>'M2_2_REQUEST_STRUCTURE_SCHEMA_V1'
       OR v.pricing_contract_code<>'M2_PRICING_STRUCTURE_CONSUMPTION'
       OR v.pricing_contract_version<>1
       OR v.pricing_schema_version<>'M2_2_PRICING_STRUCTURE_SCHEMA_V1'
       OR v.acceptance_gate_id<>'M2_2_PRICING_STRUCTURE_COUNTEROFFER'
       OR v.source_m2_1_contract_code<>'M2_ELIGIBILITY_ROUTING_CONSUMPTION'
       OR v.source_m2_1_contract_version<>1
       OR v.source_m2_1_schema_version<>'M2_1_ROUTING_SCHEMA_V1'
       OR v.required_source_m2_1_hash<>'e5ace7f32060ffb191c7bd0f8dd0c863'
       OR v.source_m1_3_gate_id<>'M1_3_APPLICATION_REQUEST'
       OR v.required_source_m1_3_hash<>'01485256b9b5748fb412743d35ced602'
       OR v.expected_candidate_rows<>557
       OR v.expected_canonical_entities<>7336
       OR v.expected_positive_controls<>120
       OR v.expected_negative_controls<>20
       OR v.synthetic_data_only_flag IS DISTINCT FROM TRUE
       OR v.counteroffer_foundation_only_flag IS DISTINCT FROM TRUE
       OR v.no_final_credit_decision_flag IS DISTINCT FROM TRUE
       OR v.no_production_adverse_action_flag IS DISTINCT FROM TRUE
       OR v.no_booking_funding_flag IS DISTINCT FROM TRUE
       OR v.acquisition_source_noncredit_flag IS DISTINCT FROM TRUE
       OR v.stress_nonimprovement_flag IS DISTINCT FROM TRUE
       OR v.request_companion_required_flag IS DISTINCT FROM TRUE
       OR (v.configuration_payload->'boundaries'->>'synthetic_data_only')::boolean IS DISTINCT FROM v.synthetic_data_only_flag
       OR (v.configuration_payload->'boundaries'->>'counteroffer_foundation_only')::boolean IS DISTINCT FROM v.counteroffer_foundation_only_flag
       OR (v.configuration_payload->'boundaries'->>'no_final_credit_decision')::boolean IS DISTINCT FROM v.no_final_credit_decision_flag
       OR (v.configuration_payload->'boundaries'->>'no_production_adverse_action')::boolean IS DISTINCT FROM v.no_production_adverse_action_flag
       OR (v.configuration_payload->'boundaries'->>'no_booking_funding')::boolean IS DISTINCT FROM v.no_booking_funding_flag
       OR (v.configuration_payload->'boundaries'->>'acquisition_source_noncredit')::boolean IS DISTINCT FROM v.acquisition_source_noncredit_flag
       OR (v.configuration_payload->'boundaries'->>'stress_nonimprovement')::boolean IS DISTINCT FROM v.stress_nonimprovement_flag
       OR (v.configuration_payload->'boundaries'->>'request_companion_required')::boolean IS DISTINCT FROM v.request_companion_required_flag
       OR v.configuration_hash IS DISTINCT FROM msbf_ctl.m2_2_hash_jsonb(v.configuration_payload)
    THEN RAISE EXCEPTION 'M2.2 configuration assertion failed for run %.',p_run_id;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_2_assert_prerequisite_status(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_run text; v_contract text; v_gate text; v_hash text; v_m13 text;
BEGIN
    SELECT run_status INTO v_run FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    SELECT contract_status,combined_set_hash INTO v_contract,v_hash FROM msbf_ctl.m2_1_strategy_contract_registry WHERE module1_run_id=p_run_id;
    SELECT result_status INTO v_gate FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING' ORDER BY review_version DESC LIMIT 1;
    SELECT result_status INTO v_m13 FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1;
    IF v_run<>'M2_1_ACCEPTED' OR v_contract<>'ACCEPTED' OR v_gate<>'PASS' OR v_hash<>'e5ace7f32060ffb191c7bd0f8dd0c863' OR v_m13<>'PASS' THEN
        RAISE EXCEPTION 'M2.2 prerequisite assertion failed: run %, contract %, M2.1 gate %, hash %, M1.3 gate %.',v_run,v_contract,v_gate,v_hash,v_m13;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_2_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_targets bigint;
BEGIN
    PERFORM msbf_ctl.m2_2_assert_configuration(p_run_id);
    PERFORM msbf_ctl.m2_2_assert_prerequisite_status(p_run_id);
    SELECT
      (SELECT count(*) FROM msbf_m2.application_request_structure_snapshot WHERE module1_run_id=p_run_id)+
      (SELECT count(*) FROM msbf_m2.application_request_structure_latest WHERE module1_run_id=p_run_id)+
      (SELECT count(*) FROM msbf_m2.application_request_structure_archive WHERE module1_run_id=p_run_id)+
      (SELECT count(*) FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=p_run_id)+
      (SELECT count(*) FROM msbf_m2.application_pricing_structure_snapshot WHERE module1_run_id=p_run_id)+
      (SELECT count(*) FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=p_run_id)+
      (SELECT count(*) FROM msbf_m2.application_pricing_structure_archive WHERE module1_run_id=p_run_id)+
      (SELECT count(*) FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=p_run_id)+
      (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=p_run_id AND evidence_code LIKE 'M2_2_%')
    INTO v_targets;
    IF v_targets<>0 THEN RAISE EXCEPTION 'M2.2 generation requires pristine targets; observed % rows.',v_targets; END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_2_assert_validation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_run text; v_contract text;
BEGIN
    PERFORM msbf_ctl.m2_2_assert_configuration(p_run_id);
    SELECT run_status INTO v_run FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    SELECT contract_status INTO v_contract FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=p_run_id;
    IF v_run NOT IN('M2_2_GENERATED','M2_2_VALIDATED') OR v_contract NOT IN('GENERATED','VALIDATED') THEN
      RAISE EXCEPTION 'M2.2 validation requires generated or validated state; observed %, %.',v_run,v_contract;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_2_assert_acceptance_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_run text; v_contract text; v_pos bigint; v_neg bigint;
BEGIN
    PERFORM msbf_ctl.m2_2_assert_configuration(p_run_id);
    SELECT run_status INTO v_run FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    SELECT contract_status INTO v_contract FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=p_run_id;
    SELECT count(*) FILTER(WHERE evidence_code LIKE 'M2_2_POS_%' AND status='PASS'),count(*) FILTER(WHERE evidence_code LIKE 'M2_2_NEG_%' AND status='PASS')
      INTO v_pos,v_neg FROM msbf_ctl.run_evidence WHERE run_id=p_run_id;
    IF v_run<>'M2_2_VALIDATED' OR v_contract<>'VALIDATED' OR v_pos<>120 OR v_neg<>20 THEN
      RAISE EXCEPTION 'M2.2 acceptance not ready: run %, contract %, positive %, negative %.',v_run,v_contract,v_pos,v_neg;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_2_assert_no_final_decision_payload(p_payload jsonb)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_key text;
BEGIN
 SELECT key INTO v_key FROM jsonb_object_keys(coalesce(p_payload,'{}'::jsonb)) AS key
 WHERE lower(key) IN('approval','approval_flag','decline','decline_flag','final_decision','final_counteroffer','adverse_action','booking','funding','funding_status') LIMIT 1;
 IF v_key IS NOT NULL THEN RAISE EXCEPTION 'M2.2 boundary rejected prohibited key %.',v_key; END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_2_assert_stress_nonimprovement(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_count bigint;
BEGIN
 SELECT count(*) INTO v_count FROM msbf_m2.v_m2_2_matched_scenario_comparison
 WHERE module1_run_id=p_run_id AND stress_structure_improvement_flag;
 IF v_count<>0 THEN RAISE EXCEPTION 'M2.2 stress non-improvement failed: % improvements.',v_count; END IF;
END;
$function$;

INSERT INTO msbf_ref.acceptance_gate_catalog(gate_id,gate_name,module_code,severity,active_flag,description)
VALUES('M2_2_PRICING_STRUCTURE_COUNTEROFFER','M2.2 Pricing, Structure & Counteroffer Foundations','M2.2','BLOCKING',TRUE,'Accepts bounded pricing and structure foundations; no final offer or decision.')
ON CONFLICT(gate_id) DO UPDATE SET gate_name=EXCLUDED.gate_name,module_code=EXCLUDED.module_code,severity=EXCLUDED.severity,active_flag=EXCLUDED.active_flag,description=EXCLUDED.description;

INSERT INTO msbf_ctl.m2_2_policy_profile(
 policy_code,methodology_version,request_contract_code,request_contract_version,request_schema_version,
 pricing_contract_code,pricing_contract_version,pricing_schema_version,acceptance_gate_id,
 source_m2_1_contract_code,source_m2_1_contract_version,source_m2_1_schema_version,required_source_m2_1_hash,
 source_m1_3_gate_id,required_source_m1_3_hash,
 expected_policy_rows,expected_template_rows,expected_reason_rows,expected_disposition_rows,
 expected_request_snapshot_rows,expected_request_latest_rows,expected_request_archive_rows,expected_candidate_rows,
 expected_pricing_snapshot_rows,expected_pricing_latest_rows,expected_pricing_archive_rows,expected_comparison_rows,
 expected_registry_rows,expected_canonical_entities,expected_positive_controls,expected_negative_controls,
 expected_detail_result_sets,expected_generation_evidence_rows,
 amount_rounding_increment,minimum_candidate_amount,minimum_remittance_rate,maximum_remittance_rate,
 minimum_payback_multiple,maximum_payback_multiple,maximum_collection_horizon_days,implied_payoff_tolerance,
 stress_expected_loss_multiplier,relationship_pricing_adjustment,
 synthetic_data_only_flag,counteroffer_foundation_only_flag,no_final_credit_decision_flag,
 no_production_adverse_action_flag,no_booking_funding_flag,acquisition_source_noncredit_flag,
 stress_nonimprovement_flag,request_companion_required_flag,policy_status,configuration_payload,configuration_hash)
VALUES(
 'M2_2_PRICING_STRUCTURE_POLICY_V1','M2_2_METHOD_V1','M2_REQUEST_STRUCTURE_CONSUMPTION',1,'M2_2_REQUEST_STRUCTURE_SCHEMA_V1','M2_PRICING_STRUCTURE_CONSUMPTION',1,'M2_2_PRICING_STRUCTURE_SCHEMA_V1','M2_2_PRICING_STRUCTURE_COUNTEROFFER',
 'M2_ELIGIBILITY_ROUTING_CONSUMPTION',1,'M2_1_ROUTING_SCHEMA_V1','e5ace7f32060ffb191c7bd0f8dd0c863','M1_3_APPLICATION_REQUEST','01485256b9b5748fb412743d35ced602',
 1,5,18,4,750,750,750,557,1500,1500,1500,750,1,7336,120,20,24,20,
 100.00,2500.00,0.05,0.20,1.05,1.40,120,1.35,1.15,-0.005,
 TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,'APPROVED','{"acceptance_gate":"M2_2_PRICING_STRUCTURE_COUNTEROFFER","boundaries":{"acquisition_source_noncredit":true,"counteroffer_foundation_only":true,"no_booking_funding":true,"no_final_credit_decision":true,"no_production_adverse_action":true,"request_companion_required":true,"stress_nonimprovement":true,"synthetic_data_only":true},"bounds":{"amount_rounding_increment":100,"implied_payoff_tolerance":1.35,"maximum_collection_horizon_days":120,"maximum_payback_multiple":1.4,"maximum_remittance_rate":0.2,"minimum_candidate_amount":2500,"minimum_payback_multiple":1.05,"minimum_remittance_rate":0.05,"relationship_pricing_adjustment":-0.005,"stress_expected_loss_multiplier":1.15},"expected":{"candidate_rows":557,"canonical_entities":7336,"comparison_rows":750,"detail_result_sets":24,"disposition_rows":4,"generation_evidence_rows":20,"negative_controls":20,"policy_rows":1,"positive_controls":120,"pricing_archive_rows":1500,"pricing_latest_rows":1500,"pricing_snapshot_rows":1500,"reason_rows":18,"registry_rows":1,"request_archive_rows":750,"request_latest_rows":750,"request_snapshot_rows":750,"template_rows":5},"methodology_version":"M2_2_METHOD_V1","pricing_contract":"M2_PRICING_STRUCTURE_CONSUMPTION","pricing_schema":"M2_2_PRICING_STRUCTURE_SCHEMA_V1","request_contract":"M2_REQUEST_STRUCTURE_CONSUMPTION","request_schema":"M2_2_REQUEST_STRUCTURE_SCHEMA_V1","source_m1_3_gate":"M1_3_APPLICATION_REQUEST","source_m1_3_hash":"01485256b9b5748fb412743d35ced602","source_m2_1_contract":"M2_ELIGIBILITY_ROUTING_CONSUMPTION","source_m2_1_hash":"e5ace7f32060ffb191c7bd0f8dd0c863","source_m2_1_schema":"M2_1_ROUTING_SCHEMA_V1"}'::jsonb,msbf_ctl.m2_2_hash_jsonb('{"acceptance_gate":"M2_2_PRICING_STRUCTURE_COUNTEROFFER","boundaries":{"acquisition_source_noncredit":true,"counteroffer_foundation_only":true,"no_booking_funding":true,"no_final_credit_decision":true,"no_production_adverse_action":true,"request_companion_required":true,"stress_nonimprovement":true,"synthetic_data_only":true},"bounds":{"amount_rounding_increment":100,"implied_payoff_tolerance":1.35,"maximum_collection_horizon_days":120,"maximum_payback_multiple":1.4,"maximum_remittance_rate":0.2,"minimum_candidate_amount":2500,"minimum_payback_multiple":1.05,"minimum_remittance_rate":0.05,"relationship_pricing_adjustment":-0.005,"stress_expected_loss_multiplier":1.15},"expected":{"candidate_rows":557,"canonical_entities":7336,"comparison_rows":750,"detail_result_sets":24,"disposition_rows":4,"generation_evidence_rows":20,"negative_controls":20,"policy_rows":1,"positive_controls":120,"pricing_archive_rows":1500,"pricing_latest_rows":1500,"pricing_snapshot_rows":1500,"reason_rows":18,"registry_rows":1,"request_archive_rows":750,"request_latest_rows":750,"request_snapshot_rows":750,"template_rows":5},"methodology_version":"M2_2_METHOD_V1","pricing_contract":"M2_PRICING_STRUCTURE_CONSUMPTION","pricing_schema":"M2_2_PRICING_STRUCTURE_SCHEMA_V1","request_contract":"M2_REQUEST_STRUCTURE_CONSUMPTION","request_schema":"M2_2_REQUEST_STRUCTURE_SCHEMA_V1","source_m1_3_gate":"M1_3_APPLICATION_REQUEST","source_m1_3_hash":"01485256b9b5748fb412743d35ced602","source_m2_1_contract":"M2_ELIGIBILITY_ROUTING_CONSUMPTION","source_m2_1_hash":"e5ace7f32060ffb191c7bd0f8dd0c863","source_m2_1_schema":"M2_1_ROUTING_SCHEMA_V1"}'::jsonb))
ON CONFLICT(policy_code) DO UPDATE SET
 methodology_version=EXCLUDED.methodology_version,request_contract_code=EXCLUDED.request_contract_code,
 request_contract_version=EXCLUDED.request_contract_version,request_schema_version=EXCLUDED.request_schema_version,
 pricing_contract_code=EXCLUDED.pricing_contract_code,pricing_contract_version=EXCLUDED.pricing_contract_version,
 pricing_schema_version=EXCLUDED.pricing_schema_version,acceptance_gate_id=EXCLUDED.acceptance_gate_id,
 source_m2_1_contract_code=EXCLUDED.source_m2_1_contract_code,source_m2_1_contract_version=EXCLUDED.source_m2_1_contract_version,
 source_m2_1_schema_version=EXCLUDED.source_m2_1_schema_version,required_source_m2_1_hash=EXCLUDED.required_source_m2_1_hash,
 source_m1_3_gate_id=EXCLUDED.source_m1_3_gate_id,required_source_m1_3_hash=EXCLUDED.required_source_m1_3_hash,
 configuration_payload=EXCLUDED.configuration_payload,configuration_hash=EXCLUDED.configuration_hash,policy_status='APPROVED',updated_at=clock_timestamp();

WITH ctx AS(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
seed(candidate_template_code,template_sequence,applicable_route_code,amount_multiplier,remittance_multiplier,payback_multiplier,horizon_multiplier,counteroffer_foundation_flag,description) AS(VALUES
        ('ELIGIBLE_REQUEST_REFERENCE',1,'ELIGIBLE_FOR_OFFER_DESIGN',1.0,1.0,1.0,1.0,FALSE,'Requested reference candidate for eligible records.'),
        ('ELIGIBLE_CAPACITY_ALIGNED',2,'ELIGIBLE_FOR_OFFER_DESIGN',0.92,0.98,1.02,1.0,FALSE,'Capacity-aligned eligible structure.'),
        ('ELIGIBLE_COUNTEROFFER_RESERVE',3,'ELIGIBLE_FOR_OFFER_DESIGN',0.8,0.95,1.03,1.05,TRUE,'Conservative counteroffer foundation for eligible records.'),
        ('REVIEW_CAPACITY_ALIGNED',1,'MANUAL_REVIEW',0.75,0.9,1.04,1.1,FALSE,'Capacity-aligned review candidate.'),
        ('REVIEW_COUNTEROFFER_FOUNDATION',2,'MANUAL_REVIEW',0.6,0.85,1.06,1.15,TRUE,'Conservative counteroffer foundation for manual review.'))
INSERT INTO msbf_m2.pricing_structure_candidate_template(module1_run_id,candidate_template_code,template_sequence,applicable_route_code,amount_multiplier,remittance_multiplier,payback_multiplier,horizon_multiplier,counteroffer_foundation_flag,active_flag,description,policy_configuration_hash,row_hash)
SELECT ctx.run_id,s.candidate_template_code,s.template_sequence,s.applicable_route_code,s.amount_multiplier,s.remittance_multiplier,s.payback_multiplier,s.horizon_multiplier,s.counteroffer_foundation_flag,TRUE,s.description,p.configuration_hash,
 msbf_ctl.m2_2_hash_jsonb(jsonb_build_object('module1_run_id',ctx.run_id,'candidate_template_code',s.candidate_template_code,'template_sequence',s.template_sequence,'applicable_route_code',s.applicable_route_code,'amount_multiplier',s.amount_multiplier,'remittance_multiplier',s.remittance_multiplier,'payback_multiplier',s.payback_multiplier,'horizon_multiplier',s.horizon_multiplier,'counteroffer_foundation_flag',s.counteroffer_foundation_flag,'active_flag',TRUE,'description',s.description,'policy_configuration_hash',p.configuration_hash))
FROM ctx CROSS JOIN seed s CROSS JOIN msbf_ctl.m2_2_policy_profile p WHERE p.policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1'
ON CONFLICT(module1_run_id,candidate_template_code) DO UPDATE SET template_sequence=EXCLUDED.template_sequence,applicable_route_code=EXCLUDED.applicable_route_code,amount_multiplier=EXCLUDED.amount_multiplier,remittance_multiplier=EXCLUDED.remittance_multiplier,payback_multiplier=EXCLUDED.payback_multiplier,horizon_multiplier=EXCLUDED.horizon_multiplier,counteroffer_foundation_flag=EXCLUDED.counteroffer_foundation_flag,active_flag=TRUE,description=EXCLUDED.description,policy_configuration_hash=EXCLUDED.policy_configuration_hash,row_hash=EXCLUDED.row_hash;

WITH ctx AS(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
seed(reason_code,reason_category,associated_disposition_code,reason_priority,display_text) AS(VALUES
        ('M2_2_REQUEST_REFERENCE','REQUEST','STRUCTURE_READY',1,'Requested structure retained as governed reference.'),
        ('M2_2_CAPACITY_ALIGNED','CAPACITY','STRUCTURE_READY',2,'Amount aligned to observed sales capacity.'),
        ('M2_2_COUNTEROFFER_RESERVE','COUNTEROFFER','COUNTEROFFER_FOUNDATION_REVIEW',3,'Conservative reserve structure for later authorization.'),
        ('M2_2_REVIEW_CAPACITY','REVIEW','COUNTEROFFER_FOUNDATION_REVIEW',4,'Manual-review capacity candidate.'),
        ('M2_2_REVIEW_COUNTEROFFER','REVIEW','COUNTEROFFER_FOUNDATION_REVIEW',5,'Manual-review counteroffer foundation.'),
        ('M2_2_NO_STRUCTURE_INSUFFICIENT','EVIDENCE','NO_STRUCTURE_INSUFFICIENT_EVIDENCE',6,'No structure generated because evidence is insufficient.'),
        ('M2_2_NO_STRUCTURE_POLICY','POLICY','NO_STRUCTURE_POLICY_DECLINE',7,'No structure generated because M2.1 route is policy decline.'),
        ('M2_2_AMOUNT_FLOOR','AMOUNT','COUNTEROFFER_FOUNDATION_REVIEW',8,'Amount constrained by governed minimum.'),
        ('M2_2_AMOUNT_REQUEST_CAP','AMOUNT','STRUCTURE_READY',9,'Amount does not exceed request.'),
        ('M2_2_REMITTANCE_FLOOR','REMITTANCE','COUNTEROFFER_FOUNDATION_REVIEW',10,'Remittance constrained by governed minimum.'),
        ('M2_2_REMITTANCE_CAP','REMITTANCE','COUNTEROFFER_FOUNDATION_REVIEW',11,'Remittance constrained by governed maximum.'),
        ('M2_2_PAYBACK_BOUND','PAYBACK','COUNTEROFFER_FOUNDATION_REVIEW',12,'Payback multiple constrained by governed range.'),
        ('M2_2_HORIZON_BOUND','HORIZON','COUNTEROFFER_FOUNDATION_REVIEW',13,'Collection horizon constrained by governed maximum.'),
        ('M2_2_RISK_LOAD','RISK','COUNTEROFFER_FOUNDATION_REVIEW',14,'Structure reflects integrated risk tier.'),
        ('M2_2_RESILIENCE_LOAD','RESILIENCE','COUNTEROFFER_FOUNDATION_REVIEW',15,'Structure reflects resilience tier.'),
        ('M2_2_ECONOMIC_LOAD','ECONOMICS','COUNTEROFFER_FOUNDATION_REVIEW',16,'Structure reflects economic evidence.'),
        ('M2_2_STRESS_FLOOR','STRESS','COUNTEROFFER_FOUNDATION_REVIEW',17,'Stress candidate is no more favorable than baseline.'),
        ('M2_2_ACQUISITION_NONCREDIT','ACQUISITION','STRUCTURE_READY',18,'Acquisition evidence retained for economics only, not credit treatment.'))
INSERT INTO msbf_m2.pricing_structure_reason_definition(module1_run_id,reason_code,reason_category,associated_disposition_code,reason_priority,display_text,production_adverse_action_flag,active_flag,row_hash)
SELECT ctx.run_id,s.reason_code,s.reason_category,s.associated_disposition_code,s.reason_priority,s.display_text,FALSE,TRUE,
 msbf_ctl.m2_2_hash_jsonb(jsonb_build_object('module1_run_id',ctx.run_id,'reason_code',s.reason_code,'reason_category',s.reason_category,'associated_disposition_code',s.associated_disposition_code,'reason_priority',s.reason_priority,'display_text',s.display_text,'production_adverse_action_flag',FALSE,'active_flag',TRUE))
FROM ctx CROSS JOIN seed s ON CONFLICT(module1_run_id,reason_code) DO UPDATE SET reason_category=EXCLUDED.reason_category,associated_disposition_code=EXCLUDED.associated_disposition_code,reason_priority=EXCLUDED.reason_priority,display_text=EXCLUDED.display_text,production_adverse_action_flag=FALSE,active_flag=TRUE,row_hash=EXCLUDED.row_hash;

WITH ctx AS(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
seed(disposition_code,disposition_rank,structure_available_flag,review_required_flag,description) AS(VALUES
        ('STRUCTURE_READY',1,TRUE,FALSE,'Candidate structure ready for later final-offer authorization.'),
        ('COUNTEROFFER_FOUNDATION_REVIEW',2,TRUE,TRUE,'Counteroffer foundation requires later review and authorization.'),
        ('NO_STRUCTURE_INSUFFICIENT_EVIDENCE',3,FALSE,FALSE,'No structure due to insufficient evidence.'),
        ('NO_STRUCTURE_POLICY_DECLINE',4,FALSE,FALSE,'No structure due to accepted M2.1 policy decline.'))
INSERT INTO msbf_m2.pricing_structure_disposition_definition(module1_run_id,disposition_code,disposition_rank,structure_available_flag,review_required_flag,final_decision_flag,booking_funding_flag,active_flag,description,row_hash)
SELECT ctx.run_id,s.disposition_code,s.disposition_rank,s.structure_available_flag,s.review_required_flag,FALSE,FALSE,TRUE,s.description,
 msbf_ctl.m2_2_hash_jsonb(jsonb_build_object('module1_run_id',ctx.run_id,'disposition_code',s.disposition_code,'disposition_rank',s.disposition_rank,'structure_available_flag',s.structure_available_flag,'review_required_flag',s.review_required_flag,'final_decision_flag',FALSE,'booking_funding_flag',FALSE,'active_flag',TRUE,'description',s.description))
FROM ctx CROSS JOIN seed s ON CONFLICT(module1_run_id,disposition_code) DO UPDATE SET disposition_rank=EXCLUDED.disposition_rank,structure_available_flag=EXCLUDED.structure_available_flag,review_required_flag=EXCLUDED.review_required_flag,final_decision_flag=FALSE,booking_funding_flag=FALSE,active_flag=TRUE,description=EXCLUDED.description,row_hash=EXCLUDED.row_hash;

CREATE OR REPLACE VIEW msbf_m2.v_m2_2_request_structure_latest AS SELECT * FROM msbf_m2.application_request_structure_latest;
CREATE OR REPLACE VIEW msbf_m2.v_m2_2_pricing_structure_latest AS SELECT * FROM msbf_m2.application_pricing_structure_latest;
CREATE OR REPLACE VIEW msbf_m2.v_m2_2_candidate_detail AS
SELECT c.*,t.applicable_route_code,t.description AS template_description FROM msbf_m2.application_pricing_structure_candidate c JOIN msbf_m2.pricing_structure_candidate_template t ON t.module1_run_id=c.module1_run_id AND t.candidate_template_code=c.candidate_template_code;
CREATE OR REPLACE VIEW msbf_m2.v_m2_2_matched_scenario_comparison AS
SELECT b.module1_run_id,b.merchant_application_id,b.pricing_disposition_code AS baseline_disposition_code,s.pricing_disposition_code AS stress_disposition_code,
 b.selected_funding_amount AS baseline_selected_funding_amount,s.selected_funding_amount AS stress_selected_funding_amount,
 b.selected_remittance_rate AS baseline_selected_remittance_rate,s.selected_remittance_rate AS stress_selected_remittance_rate,
 b.selected_payback_multiple AS baseline_selected_payback_multiple,s.selected_payback_multiple AS stress_selected_payback_multiple,
 b.selected_collection_horizon_days AS baseline_collection_horizon_days,s.selected_collection_horizon_days AS stress_collection_horizon_days,
 ((s.selected_funding_amount>b.selected_funding_amount) OR (s.selected_remittance_rate<b.selected_remittance_rate) OR (s.selected_payback_multiple<b.selected_payback_multiple) OR (s.selected_collection_horizon_days<b.selected_collection_horizon_days)) AS stress_structure_improvement_flag
FROM msbf_m2.application_pricing_structure_latest b JOIN msbf_m2.application_pricing_structure_latest s ON s.module1_run_id=b.module1_run_id AND s.merchant_application_id=b.merchant_application_id AND s.scenario_code='RECESSION_ENERGY'
WHERE b.scenario_code='BASELINE';
CREATE OR REPLACE VIEW msbf_ctl.v_m2_2_lineage AS SELECT r.* FROM msbf_ctl.m2_2_pricing_structure_contract_registry r;
CREATE OR REPLACE VIEW msbf_m2.v_m2_2_power_bi_pricing_structure AS
SELECT l.module1_run_id,l.scenario_code,l.merchant_application_id,l.source_route_code,l.pricing_disposition_code,l.structure_available_flag,l.review_required_flag,l.selected_candidate_template_code,l.requested_funding_amount,l.selected_funding_amount,l.selected_remittance_rate,l.selected_payback_multiple,l.selected_collection_horizon_days,l.selected_amount_to_request_ratio,l.candidate_count,l.counteroffer_foundation_flag,l.primary_reason_code,l.routing_evidence_status
FROM msbf_m2.application_pricing_structure_latest l;

DO $guard$
DECLARE v_run bigint; v_policy bigint; v_templates bigint; v_reasons bigint; v_dispositions bigint;
BEGIN
 SELECT run_id INTO v_run FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 PERFORM msbf_ctl.m2_2_assert_configuration(v_run);
 SELECT count(*) INTO v_policy FROM msbf_ctl.m2_2_policy_profile WHERE policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1';
 SELECT count(*) INTO v_templates FROM msbf_m2.pricing_structure_candidate_template WHERE module1_run_id=v_run;
 SELECT count(*) INTO v_reasons FROM msbf_m2.pricing_structure_reason_definition WHERE module1_run_id=v_run;
 SELECT count(*) INTO v_dispositions FROM msbf_m2.pricing_structure_disposition_definition WHERE module1_run_id=v_run;
 IF v_policy<>1 OR v_templates<>5 OR v_reasons<>18 OR v_dispositions<>4 THEN RAISE EXCEPTION 'M2.2 schema/reference extension failed: %, %, %, %.',v_policy,v_templates,v_reasons,v_dispositions; END IF;
END;
$guard$;

COMMIT;

SELECT p.policy_code,p.policy_status,p.methodology_version,p.request_contract_code,p.pricing_contract_code,p.acceptance_gate_id,p.configuration_hash,
 (SELECT count(*) FROM msbf_m2.pricing_structure_candidate_template t JOIN msbf_ctl.run_registry r ON r.run_id=t.module1_run_id WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1) AS template_rows,
 (SELECT count(*) FROM msbf_m2.pricing_structure_reason_definition d JOIN msbf_ctl.run_registry r ON r.run_id=d.module1_run_id WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1) AS reason_rows,
 (SELECT count(*) FROM msbf_m2.pricing_structure_disposition_definition d JOIN msbf_ctl.run_registry r ON r.run_id=d.module1_run_id WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1) AS disposition_rows,
 CASE WHEN p.policy_status='APPROVED' THEN 'PASS' ELSE 'FAIL' END AS schema_policy_extension_status
FROM msbf_ctl.m2_2_policy_profile p WHERE p.policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1';
