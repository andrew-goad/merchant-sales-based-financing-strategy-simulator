/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M2.1 — Eligibility, Policy Gates & Decision Routing Foundations

Program : 132_msbf_m2_1_eligibility_policy_routing_schema_extension_v0_2.sql
Version : v0.2
Title   : Schema, Policy, Contract and Reference Extension

Purpose
Create the bounded M2.1 control plane, reference definitions, scenario-aware routing tables, immutable archive, functions, trigger and consumption views.

Inputs
Accepted M1.17 G2 contract boundary and existing control schemas.

Outputs
Approved M2.1 policy, one baseline strategy campaign, twelve gates, twenty-three reason codes, four routing outcomes, empty application-level targets and governed views.

Stage boundary
This program does not generate application decisions, prices, offer amounts, remittance rates, terms, adverse-action notices or Module 2.2 outputs. It does not change run status.

Execution standard
Run the complete file with DBeaver Execute SQL Script. Stop at the first
PostgreSQL error. Never use Retry, Skip or Skip All. Execute ROLLBACK after a
failed transactional program.
============================================================================ */

BEGIN;

SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='15min';
SET LOCAL jit=off;

CREATE SCHEMA IF NOT EXISTS msbf_m2;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_1_hash_jsonb(p_value jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$ SELECT md5(p_value::text); $$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_1_route_rank(p_route_code text)
RETURNS integer
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
SELECT CASE p_route_code
    WHEN 'ELIGIBLE_FOR_OFFER_DESIGN' THEN 1
    WHEN 'MANUAL_REVIEW' THEN 2
    WHEN 'INSUFFICIENT_EVIDENCE' THEN 3
    WHEN 'DECLINE_POLICY' THEN 4
    ELSE NULL
END;
$$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_1_route_code(p_route_rank integer)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
SELECT CASE p_route_rank
    WHEN 1 THEN 'ELIGIBLE_FOR_OFFER_DESIGN'
    WHEN 2 THEN 'MANUAL_REVIEW'
    WHEN 3 THEN 'INSUFFICIENT_EVIDENCE'
    WHEN 4 THEN 'DECLINE_POLICY'
    ELSE NULL
END;
$$;

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_1_policy_profile (
    policy_code                         text PRIMARY KEY,
    methodology_version                 text NOT NULL,
    contract_code                       text NOT NULL,
    contract_version                    integer NOT NULL,
    schema_version                      text NOT NULL,
    source_g2_bundle_code               text NOT NULL,
    source_g2_bundle_version            integer NOT NULL,
    source_g2_schema_version            text NOT NULL,
    required_source_g2_hash             text NOT NULL,
    strategy_campaign_code              text NOT NULL,
    strategy_campaign_version           integer NOT NULL,
    expected_gate_count                 integer NOT NULL,
    expected_reason_count               integer NOT NULL,
    expected_outcome_count              integer NOT NULL,
    expected_input_rows                 integer NOT NULL,
    expected_gate_result_rows           integer NOT NULL,
    expected_snapshot_rows              integer NOT NULL,
    expected_latest_rows                integer NOT NULL,
    expected_archive_rows               integer NOT NULL,
    expected_comparison_rows            integer NOT NULL,
    expected_canonical_entities         integer NOT NULL,
    expected_positive_controls          integer NOT NULL,
    expected_negative_controls          integer NOT NULL,
    expected_detail_result_sets         integer NOT NULL,
    route_rank_order                    jsonb NOT NULL,
    threshold_payload                   jsonb NOT NULL,
    synthetic_data_only_flag            boolean NOT NULL,
    no_final_offer_terms_flag            boolean NOT NULL,
    no_production_adverse_action_flag    boolean NOT NULL,
    acquisition_source_review_only_flag  boolean NOT NULL,
    policy_status                       text NOT NULL,
    configuration_payload               jsonb NOT NULL,
    configuration_hash                  text NOT NULL,
    created_at                          timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at                          timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT ck_m2_1_policy_status CHECK (policy_status IN ('DRAFT','APPROVED','RETIRED')),
    CONSTRAINT ck_m2_1_policy_hash CHECK (
        length(configuration_hash)=32 AND configuration_hash ~ '^[0-9a-f]+$'
    )
);

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_1_strategy_contract_registry (
    registry_id                         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id                      bigint NOT NULL UNIQUE,
    contract_code                       text NOT NULL,
    contract_version                    integer NOT NULL,
    schema_version                      text NOT NULL,
    methodology_version                 text NOT NULL,
    source_g2_bundle_code               text NOT NULL,
    source_g2_bundle_version            integer NOT NULL,
    source_g2_schema_version            text NOT NULL,
    source_g2_combined_hash             text NOT NULL,
    policy_configuration_hash           text NOT NULL,
    strategy_campaign_rows              bigint NOT NULL,
    gate_definition_rows                bigint NOT NULL,
    reason_code_rows                    bigint NOT NULL,
    outcome_definition_rows             bigint NOT NULL,
    gate_result_rows                    bigint NOT NULL,
    routing_snapshot_rows               bigint NOT NULL,
    latest_rows                         bigint NOT NULL,
    archive_rows                        bigint NOT NULL,
    comparison_rows                     bigint NOT NULL,
    canonical_entities                 bigint NOT NULL,
    campaign_set_hash                   text,
    gate_definition_set_hash            text,
    reason_code_set_hash                text,
    outcome_definition_set_hash         text,
    gate_result_set_hash                text,
    routing_snapshot_set_hash           text,
    latest_set_hash                     text,
    archive_set_hash                    text,
    contract_set_hash                   text,
    combined_set_hash                   text,
    contract_status                     text NOT NULL,
    generated_at                        timestamptz,
    validated_at                        timestamptz,
    accepted_at                         timestamptz,
    row_hash                            text NOT NULL,
    created_at                          timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_m2_1_contract_identity UNIQUE(contract_code,contract_version),
    CONSTRAINT fk_m2_1_contract_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT ck_m2_1_contract_status CHECK(contract_status IN ('GENERATED','VALIDATED','ACCEPTED')),
    CONSTRAINT ck_m2_1_contract_hashes CHECK(
        length(source_g2_combined_hash)=32 AND source_g2_combined_hash ~ '^[0-9a-f]+$'
        AND length(policy_configuration_hash)=32 AND policy_configuration_hash ~ '^[0-9a-f]+$'
        AND length(row_hash)=32 AND row_hash ~ '^[0-9a-f]+$'
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.strategy_campaign (
    module1_run_id             bigint NOT NULL,
    strategy_campaign_code     text NOT NULL,
    strategy_campaign_version  integer NOT NULL,
    strategy_campaign_name     text NOT NULL,
    strategy_type              text NOT NULL,
    policy_code                text NOT NULL,
    baseline_flag              boolean NOT NULL,
    campaign_status            text NOT NULL,
    effective_start_date       date NOT NULL,
    effective_end_date         date,
    description                text NOT NULL,
    source_g2_combined_hash     text NOT NULL,
    policy_configuration_hash  text NOT NULL,
    row_hash                   text NOT NULL,
    created_at                 timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,strategy_campaign_code,strategy_campaign_version),
    CONSTRAINT fk_m2_1_campaign_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT ck_m2_1_campaign_status CHECK(campaign_status IN ('APPROVED','RETIRED')),
    CONSTRAINT ck_m2_1_campaign_hash CHECK(length(row_hash)=32 AND row_hash ~ '^[0-9a-f]+$')
);

CREATE TABLE IF NOT EXISTS msbf_m2.policy_gate_definition (
    module1_run_id             bigint NOT NULL,
    strategy_campaign_code     text NOT NULL,
    gate_code                  text NOT NULL,
    gate_sequence              integer NOT NULL,
    gate_name                  text NOT NULL,
    gate_category              text NOT NULL,
    decision_influence_code    text NOT NULL,
    source_field_code          text NOT NULL,
    pass_rule                  text NOT NULL,
    review_rule                text NOT NULL,
    fail_rule                  text NOT NULL,
    blocked_rule               text NOT NULL,
    hard_stop_capable_flag     boolean NOT NULL,
    active_flag                boolean NOT NULL,
    row_hash                   text NOT NULL,
    created_at                 timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,strategy_campaign_code,gate_code),
    UNIQUE(module1_run_id,strategy_campaign_code,gate_sequence),
    CONSTRAINT fk_m2_1_gate_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT ck_m2_1_gate_sequence CHECK(gate_sequence BETWEEN 1 AND 12),
    CONSTRAINT ck_m2_1_gate_influence CHECK(decision_influence_code IN ('EVIDENCE','REVIEW','REVIEW_ONLY','DECLINE','HARD_STOP')),
    CONSTRAINT ck_m2_1_gate_hash CHECK(length(row_hash)=32 AND row_hash ~ '^[0-9a-f]+$')
);

CREATE TABLE IF NOT EXISTS msbf_m2.reason_code_definition (
    module1_run_id             bigint NOT NULL,
    strategy_campaign_code     text NOT NULL,
    reason_code                text NOT NULL,
    reason_category            text NOT NULL,
    reason_priority            integer NOT NULL,
    source_gate_code           text,
    associated_route_code      text NOT NULL,
    display_text               text NOT NULL,
    production_adverse_action_flag boolean NOT NULL,
    active_flag                boolean NOT NULL,
    row_hash                   text NOT NULL,
    created_at                 timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,strategy_campaign_code,reason_code),
    CONSTRAINT fk_m2_1_reason_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT ck_m2_1_reason_priority CHECK(reason_priority BETWEEN 1 AND 10),
    CONSTRAINT ck_m2_1_reason_no_adverse CHECK(production_adverse_action_flag IS FALSE),
    CONSTRAINT ck_m2_1_reason_hash CHECK(length(row_hash)=32 AND row_hash ~ '^[0-9a-f]+$')
);

CREATE TABLE IF NOT EXISTS msbf_m2.routing_outcome_definition (
    module1_run_id             bigint NOT NULL,
    strategy_campaign_code     text NOT NULL,
    route_code                 text NOT NULL,
    route_rank                 integer NOT NULL,
    route_name                 text NOT NULL,
    eligible_for_offer_design_flag boolean NOT NULL,
    terminal_flag              boolean NOT NULL,
    description                text NOT NULL,
    active_flag                boolean NOT NULL,
    row_hash                   text NOT NULL,
    created_at                 timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,strategy_campaign_code,route_code),
    UNIQUE(module1_run_id,strategy_campaign_code,route_rank),
    CONSTRAINT fk_m2_1_outcome_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT ck_m2_1_outcome_rank CHECK(route_rank BETWEEN 1 AND 4),
    CONSTRAINT ck_m2_1_outcome_hash CHECK(length(row_hash)=32 AND row_hash ~ '^[0-9a-f]+$')
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_policy_gate_result (
    module1_run_id             bigint NOT NULL,
    strategy_campaign_code     text NOT NULL,
    strategy_campaign_version  integer NOT NULL,
    scenario_id                bigint NOT NULL,
    scenario_code              text NOT NULL,
    merchant_application_id    text NOT NULL,
    population_id              text NOT NULL,
    merchant_id                text NOT NULL,
    gate_code                  text NOT NULL,
    gate_sequence              integer NOT NULL,
    gate_outcome               text NOT NULL,
    gate_outcome_rank          integer NOT NULL,
    hard_stop_flag             boolean NOT NULL,
    reason_code                text,
    observed_value_text        text,
    threshold_value_text       text NOT NULL,
    gate_evidence_status       text NOT NULL,
    source_m1_15_contract_row_hash text NOT NULL,
    source_m1_16_contract_row_hash text NOT NULL,
    source_g2_combined_hash     text NOT NULL,
    policy_configuration_hash  text NOT NULL,
    row_hash                   text NOT NULL,
    created_at                 timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,strategy_campaign_code,scenario_id,merchant_application_id,gate_code),
    CONSTRAINT fk_m2_1_gate_result_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT ck_m2_1_gate_outcome CHECK(gate_outcome IN ('PASS','REVIEW','BLOCKED','FAIL')),
    CONSTRAINT ck_m2_1_gate_outcome_rank CHECK(gate_outcome_rank BETWEEN 1 AND 4),
    CONSTRAINT ck_m2_1_gate_result_evidence CHECK(gate_evidence_status IN ('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_m2_1_gate_hard_stop CHECK(NOT hard_stop_flag OR gate_outcome='FAIL'),
    CONSTRAINT ck_m2_1_gate_result_hash CHECK(length(row_hash)=32 AND row_hash ~ '^[0-9a-f]+$')
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_eligibility_routing_snapshot (
    module1_run_id             bigint NOT NULL,
    strategy_campaign_code     text NOT NULL,
    strategy_campaign_version  integer NOT NULL,
    scenario_id                bigint NOT NULL,
    scenario_code              text NOT NULL,
    merchant_application_id    text NOT NULL,
    population_id              text NOT NULL,
    merchant_id                text NOT NULL,
    as_of_date                 date NOT NULL,
    industry_code              text NOT NULL,
    merchant_size_tier         text NOT NULL,
    relationship_stage        text NOT NULL,
    data_confidence_tier       text,
    verification_disposition   text,
    fraud_risk_tier            integer,
    processor_continuity_status text,
    capacity_tier              integer,
    affordability_status       text,
    resilience_tier            integer,
    integrated_risk_tier       integer,
    economic_tier              integer,
    economic_status            text,
    m1_15_contract_evidence_status text NOT NULL,
    acquisition_contract_evidence_status text NOT NULL,
    independent_route_code     text NOT NULL,
    independent_route_rank     integer NOT NULL,
    baseline_route_code        text NOT NULL,
    baseline_route_rank        integer NOT NULL,
    final_route_code           text NOT NULL,
    final_route_rank           integer NOT NULL,
    pass_gate_count            integer NOT NULL,
    review_gate_count          integer NOT NULL,
    blocked_gate_count         integer NOT NULL,
    fail_gate_count            integer NOT NULL,
    hard_stop_gate_count       integer NOT NULL,
    hard_stop_flag             boolean NOT NULL,
    eligible_for_offer_design_flag boolean NOT NULL,
    stress_floor_applied_flag  boolean NOT NULL,
    stress_worsening_flag      boolean NOT NULL,
    primary_reason_code        text NOT NULL,
    secondary_reason_code      text,
    tertiary_reason_code       text,
    reason_codes               jsonb NOT NULL,
    routing_evidence_status    text NOT NULL,
    source_m1_15_contract_row_hash text NOT NULL,
    source_m1_16_contract_row_hash text NOT NULL,
    source_g2_combined_hash     text NOT NULL,
    policy_configuration_hash  text NOT NULL,
    row_hash                   text NOT NULL,
    created_at                 timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,strategy_campaign_code,scenario_id,merchant_application_id),
    CONSTRAINT fk_m2_1_snapshot_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT ck_m2_1_snapshot_route CHECK(final_route_code IN ('ELIGIBLE_FOR_OFFER_DESIGN','MANUAL_REVIEW','INSUFFICIENT_EVIDENCE','DECLINE_POLICY')),
    CONSTRAINT ck_m2_1_snapshot_route_rank CHECK(final_route_rank BETWEEN 1 AND 4 AND independent_route_rank BETWEEN 1 AND 4 AND baseline_route_rank BETWEEN 1 AND 4),
    CONSTRAINT ck_m2_1_snapshot_gate_counts CHECK(pass_gate_count+review_gate_count+blocked_gate_count+fail_gate_count=12),
    CONSTRAINT ck_m2_1_snapshot_evidence CHECK(routing_evidence_status IN ('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_m2_1_snapshot_eligible CHECK(eligible_for_offer_design_flag=(final_route_code='ELIGIBLE_FOR_OFFER_DESIGN')),
    CONSTRAINT ck_m2_1_snapshot_hash CHECK(length(row_hash)=32 AND row_hash ~ '^[0-9a-f]+$')
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_eligibility_routing_latest (
    module1_run_id             bigint NOT NULL,
    contract_code              text NOT NULL,
    contract_version           integer NOT NULL,
    schema_version             text NOT NULL,
    methodology_version        text NOT NULL,
    strategy_campaign_code     text NOT NULL,
    strategy_campaign_version  integer NOT NULL,
    scenario_id                bigint NOT NULL,
    scenario_code              text NOT NULL,
    merchant_application_id    text NOT NULL,
    population_id              text NOT NULL,
    merchant_id                text NOT NULL,
    as_of_date                 date NOT NULL,
    final_route_code           text NOT NULL,
    final_route_rank           integer NOT NULL,
    independent_route_code     text NOT NULL,
    independent_route_rank     integer NOT NULL,
    baseline_route_code        text NOT NULL,
    baseline_route_rank        integer NOT NULL,
    eligible_for_offer_design_flag boolean NOT NULL,
    hard_stop_flag             boolean NOT NULL,
    stress_floor_applied_flag  boolean NOT NULL,
    stress_worsening_flag      boolean NOT NULL,
    pass_gate_count            integer NOT NULL,
    review_gate_count          integer NOT NULL,
    blocked_gate_count         integer NOT NULL,
    fail_gate_count            integer NOT NULL,
    primary_reason_code        text NOT NULL,
    secondary_reason_code      text,
    tertiary_reason_code       text,
    reason_codes               jsonb NOT NULL,
    routing_evidence_status    text NOT NULL,
    source_m1_15_contract_row_hash text NOT NULL,
    source_m1_16_contract_row_hash text NOT NULL,
    source_g2_combined_hash     text NOT NULL,
    policy_configuration_hash  text NOT NULL,
    contract_row_hash          text NOT NULL,
    created_at                 timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,strategy_campaign_code,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_1_latest_hash CHECK(length(contract_row_hash)=32 AND contract_row_hash ~ '^[0-9a-f]+$')
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_eligibility_routing_archive (
    archive_id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id             bigint NOT NULL,
    contract_code              text NOT NULL,
    contract_version           integer NOT NULL,
    schema_version             text NOT NULL,
    strategy_campaign_code     text NOT NULL,
    scenario_id                bigint NOT NULL,
    merchant_application_id    text NOT NULL,
    contract_payload           jsonb NOT NULL,
    contract_row_hash          text NOT NULL,
    source_latest_row_hash     text NOT NULL,
    archive_row_hash           text NOT NULL,
    archived_at                timestamptz NOT NULL DEFAULT clock_timestamp(),
    created_at                 timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE(module1_run_id,contract_code,contract_version,strategy_campaign_code,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_1_archive_hash CHECK(
        length(contract_row_hash)=32 AND contract_row_hash ~ '^[0-9a-f]+$'
        AND length(source_latest_row_hash)=32 AND source_latest_row_hash ~ '^[0-9a-f]+$'
        AND length(archive_row_hash)=32 AND archive_row_hash ~ '^[0-9a-f]+$'
    )
);

CREATE INDEX IF NOT EXISTS ix_m2_1_gate_result_route ON msbf_m2.application_policy_gate_result(module1_run_id,scenario_id,gate_outcome,gate_code);
CREATE INDEX IF NOT EXISTS ix_m2_1_snapshot_route ON msbf_m2.application_eligibility_routing_snapshot(module1_run_id,scenario_id,final_route_code);
CREATE INDEX IF NOT EXISTS ix_m2_1_latest_route ON msbf_m2.application_eligibility_routing_latest(module1_run_id,scenario_id,final_route_code);
CREATE INDEX IF NOT EXISTS ix_m2_1_archive_run ON msbf_m2.application_eligibility_routing_archive(module1_run_id,contract_version);

CREATE OR REPLACE FUNCTION msbf_m2.m2_1_reject_archive_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'M2.1 routing archive is immutable: % is not permitted.',TG_OP;
END;
$$;

DROP TRIGGER IF EXISTS trg_m2_1_archive_immutable ON msbf_m2.application_eligibility_routing_archive;
CREATE TRIGGER trg_m2_1_archive_immutable
BEFORE UPDATE OR DELETE ON msbf_m2.application_eligibility_routing_archive
FOR EACH ROW EXECUTE FUNCTION msbf_m2.m2_1_reject_archive_mutation();

CREATE OR REPLACE FUNCTION msbf_ctl.m2_1_assert_configuration(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE v msbf_ctl.m2_1_policy_profile%ROWTYPE;
BEGIN
    SELECT * INTO v FROM msbf_ctl.m2_1_policy_profile WHERE policy_code='M2_1_ELIGIBILITY_POLICY_V1';
    IF NOT FOUND OR v.policy_status<>'APPROVED'
       OR v.methodology_version<>'M2_1_METHOD_V1'
       OR v.contract_code<>'M2_ELIGIBILITY_ROUTING_CONSUMPTION'
       OR v.contract_version<>1
       OR v.schema_version<>'M2_1_ROUTING_SCHEMA_V1'
       OR v.required_source_g2_hash<>'7d9e466da28cad2551aa99c4c40c912b'
       OR v.expected_gate_count<>12
       OR v.expected_reason_count<>23
       OR v.expected_outcome_count<>4
       OR v.expected_input_rows<>1500
       OR v.expected_gate_result_rows<>18000
       OR v.expected_snapshot_rows<>1500
       OR v.expected_latest_rows<>1500
       OR v.expected_archive_rows<>1500
       OR v.expected_comparison_rows<>750
       OR v.expected_canonical_entities<>22541
       OR v.expected_positive_controls<>112
       OR v.expected_negative_controls<>20
       OR v.expected_detail_result_sets<>24
       OR v.configuration_hash IS DISTINCT FROM msbf_ctl.m2_1_hash_jsonb(v.configuration_payload) THEN
        RAISE EXCEPTION 'M2.1 policy configuration is absent, unapproved, malformed or hash-inconsistent.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_1_assert_prerequisite_status(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE v_status text; v_g2_status text; v_g2_hash text; v_gate text;
BEGIN
    SELECT run_status INTO v_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    IF v_status NOT IN ('M1_17_ACCEPTED','M2_1_GENERATED','M2_1_VALIDATED','M2_1_ACCEPTED') THEN
        RAISE EXCEPTION 'M2.1 requires accepted G2 or controlled M2.1 lifecycle state; observed %.',v_status;
    END IF;
    SELECT bundle_status,combined_g2_hash INTO v_g2_status,v_g2_hash
    FROM msbf_ctl.m1_17_g2_bundle_registry WHERE module1_run_id=p_run_id;
    IF v_g2_status<>'ACCEPTED' OR v_g2_hash<>'7d9e466da28cad2551aa99c4c40c912b' THEN
        RAISE EXCEPTION 'M2.1 requires accepted M1.17 G2 bundle and exact combined hash.';
    END IF;
    SELECT result_status INTO v_gate
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=p_run_id AND gate_id='G2_M1_CONTRACT'
    ORDER BY review_version DESC LIMIT 1;
    IF v_gate<>'PASS' THEN
        RAISE EXCEPTION 'M2.1 requires G2_M1_CONTRACT PASS; observed %.',v_gate;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_1_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE v_status text;
BEGIN
    SELECT run_status INTO v_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    IF v_status<>'M1_17_ACCEPTED' THEN
        RAISE EXCEPTION 'M2.1 generation requires exact prerequisite status M1_17_ACCEPTED; observed %.',v_status;
    END IF;
    PERFORM msbf_ctl.m2_1_assert_configuration(p_run_id);
    PERFORM msbf_ctl.m2_1_assert_prerequisite_status(p_run_id);
    IF EXISTS(SELECT 1 FROM msbf_m2.application_policy_gate_result WHERE module1_run_id=p_run_id)
       OR EXISTS(SELECT 1 FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=p_run_id)
       OR EXISTS(SELECT 1 FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=p_run_id)
       OR EXISTS(SELECT 1 FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=p_run_id)
       OR EXISTS(SELECT 1 FROM msbf_ctl.m2_1_strategy_contract_registry WHERE module1_run_id=p_run_id)
       OR EXISTS(SELECT 1 FROM msbf_ctl.run_evidence WHERE run_id=p_run_id AND evidence_code LIKE 'M2_1_%')
       OR EXISTS(SELECT 1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING') THEN
        RAISE EXCEPTION 'M2.1 generation targets are not pristine.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_1_assert_validation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE v_status text;
BEGIN
    SELECT run_status INTO v_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    IF v_status NOT IN ('M2_1_GENERATED','M2_1_VALIDATED') THEN
        RAISE EXCEPTION 'M2.1 validation requires GENERATED or VALIDATED state; observed %.',v_status;
    END IF;
    PERFORM msbf_ctl.m2_1_assert_configuration(p_run_id);
    PERFORM msbf_ctl.m2_1_assert_prerequisite_status(p_run_id);
    IF (SELECT count(*) FROM msbf_m2.application_policy_gate_result WHERE module1_run_id=p_run_id)<>18000
       OR (SELECT count(*) FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=p_run_id)<>1500
       OR (SELECT count(*) FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=p_run_id)<>1500
       OR (SELECT count(*) FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=p_run_id)<>1500
       OR (SELECT count(*) FROM msbf_ctl.m2_1_strategy_contract_registry WHERE module1_run_id=p_run_id)<>1 THEN
        RAISE EXCEPTION 'M2.1 generated population is incomplete.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_1_assert_acceptance_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE v_status text; v_pos bigint; v_neg bigint;
BEGIN
    SELECT run_status INTO v_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    IF v_status<>'M2_1_VALIDATED' THEN
        RAISE EXCEPTION 'M2.1 acceptance requires M2_1_VALIDATED; observed %.',v_status;
    END IF;
    SELECT count(*) FILTER(WHERE status='PASS') INTO v_pos
    FROM msbf_ctl.run_evidence WHERE run_id=p_run_id AND evidence_code LIKE 'M2_1_POS_%';
    SELECT count(*) FILTER(WHERE status='PASS') INTO v_neg
    FROM msbf_ctl.run_evidence WHERE run_id=p_run_id AND evidence_code LIKE 'M2_1_NEG_%';
    IF v_pos<>112 OR v_neg<>20 THEN
        RAISE EXCEPTION 'M2.1 acceptance requires 112 positive and 20 negative PASS records; observed % and %.',v_pos,v_neg;
    END IF;
END;
$$;

WITH configuration AS (
    SELECT jsonb_build_object(
        'policy_code','M2_1_ELIGIBILITY_POLICY_V1',
        'methodology_version','M2_1_METHOD_V1',
        'contract_code','M2_ELIGIBILITY_ROUTING_CONSUMPTION',
        'contract_version',1,
        'schema_version','M2_1_ROUTING_SCHEMA_V1',
        'source_g2_bundle_code','M1_G2_CONSUMPTION_BUNDLE',
        'source_g2_bundle_version',1,
        'source_g2_schema_version','M1_G2_BUNDLE_SCHEMA_V1',
        'required_source_g2_hash','7d9e466da28cad2551aa99c4c40c912b',
        'strategy_campaign_code','M2_1_CONTROLLED_ENTRY_BASELINE',
        'strategy_campaign_version',1,
        'expected_gate_count',12,
        'expected_reason_count',23,
        'expected_outcome_count',4,
        'expected_input_rows',1500,
        'expected_gate_result_rows',18000,
        'expected_snapshot_rows',1500,
        'expected_latest_rows',1500,
        'expected_archive_rows',1500,
        'expected_comparison_rows',750,
        'expected_canonical_entities',22541,
        'expected_positive_controls',112,
        'expected_negative_controls',20,
        'expected_detail_result_sets',24,
        'route_rank_order',jsonb_build_object('ELIGIBLE_FOR_OFFER_DESIGN',1,'MANUAL_REVIEW',2,'INSUFFICIENT_EVIDENCE',3,'DECLINE_POLICY',4),
        'thresholds',jsonb_build_object(
            'capacity_pass_max',2,'capacity_review',3,'capacity_fail',4,'capacity_blocked',5,
            'risk_pass_max',2,'risk_review',3,'risk_fail',4,'risk_blocked',5,
            'resilience_pass_max',2,'resilience_review',3,'resilience_fail',4,'resilience_blocked',5,
            'fraud_pass_max',2,'fraud_review',3,'fraud_fail_min',4,
            'acquisition_source_credit_boundary','REVIEW_ONLY'
        ),
        'synthetic_data_only',true,
        'no_final_offer_terms',true,
        'no_production_adverse_action',true,
        'acquisition_source_review_only',true
    ) AS payload
)
INSERT INTO msbf_ctl.m2_1_policy_profile(
    policy_code,methodology_version,contract_code,contract_version,schema_version,
    source_g2_bundle_code,source_g2_bundle_version,source_g2_schema_version,required_source_g2_hash,
    strategy_campaign_code,strategy_campaign_version,expected_gate_count,expected_reason_count,
    expected_outcome_count,expected_input_rows,expected_gate_result_rows,expected_snapshot_rows,
    expected_latest_rows,expected_archive_rows,expected_comparison_rows,expected_canonical_entities,
    expected_positive_controls,expected_negative_controls,expected_detail_result_sets,route_rank_order,
    threshold_payload,synthetic_data_only_flag,no_final_offer_terms_flag,
    no_production_adverse_action_flag,acquisition_source_review_only_flag,policy_status,
    configuration_payload,configuration_hash
)
SELECT
    'M2_1_ELIGIBILITY_POLICY_V1','M2_1_METHOD_V1','M2_ELIGIBILITY_ROUTING_CONSUMPTION',1,'M2_1_ROUTING_SCHEMA_V1',
    'M1_G2_CONSUMPTION_BUNDLE',1,'M1_G2_BUNDLE_SCHEMA_V1','7d9e466da28cad2551aa99c4c40c912b',
    'M2_1_CONTROLLED_ENTRY_BASELINE',1,12,23,4,1500,18000,1500,1500,1500,750,22541,112,20,24,
    payload->'route_rank_order',payload->'thresholds',true,true,true,true,'APPROVED',payload,
    msbf_ctl.m2_1_hash_jsonb(payload)
FROM configuration
ON CONFLICT(policy_code) DO UPDATE SET
    methodology_version=EXCLUDED.methodology_version,contract_code=EXCLUDED.contract_code,
    contract_version=EXCLUDED.contract_version,schema_version=EXCLUDED.schema_version,
    source_g2_bundle_code=EXCLUDED.source_g2_bundle_code,
    source_g2_bundle_version=EXCLUDED.source_g2_bundle_version,
    source_g2_schema_version=EXCLUDED.source_g2_schema_version,
    required_source_g2_hash=EXCLUDED.required_source_g2_hash,
    strategy_campaign_code=EXCLUDED.strategy_campaign_code,
    strategy_campaign_version=EXCLUDED.strategy_campaign_version,
    expected_gate_count=EXCLUDED.expected_gate_count,expected_reason_count=EXCLUDED.expected_reason_count,
    expected_outcome_count=EXCLUDED.expected_outcome_count,expected_input_rows=EXCLUDED.expected_input_rows,
    expected_gate_result_rows=EXCLUDED.expected_gate_result_rows,expected_snapshot_rows=EXCLUDED.expected_snapshot_rows,
    expected_latest_rows=EXCLUDED.expected_latest_rows,expected_archive_rows=EXCLUDED.expected_archive_rows,
    expected_comparison_rows=EXCLUDED.expected_comparison_rows,
    expected_canonical_entities=EXCLUDED.expected_canonical_entities,
    expected_positive_controls=EXCLUDED.expected_positive_controls,
    expected_negative_controls=EXCLUDED.expected_negative_controls,
    expected_detail_result_sets=EXCLUDED.expected_detail_result_sets,
    route_rank_order=EXCLUDED.route_rank_order,threshold_payload=EXCLUDED.threshold_payload,
    synthetic_data_only_flag=EXCLUDED.synthetic_data_only_flag,
    no_final_offer_terms_flag=EXCLUDED.no_final_offer_terms_flag,
    no_production_adverse_action_flag=EXCLUDED.no_production_adverse_action_flag,
    acquisition_source_review_only_flag=EXCLUDED.acquisition_source_review_only_flag,
    policy_status=EXCLUDED.policy_status,configuration_payload=EXCLUDED.configuration_payload,
    configuration_hash=EXCLUDED.configuration_hash,updated_at=clock_timestamp();

WITH run_context AS (
    SELECT r.run_id,r.as_of_date,p.configuration_hash
    FROM msbf_ctl.run_registry r CROSS JOIN msbf_ctl.m2_1_policy_profile p
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND p.policy_code='M2_1_ELIGIBILITY_POLICY_V1'
), seed AS (
    SELECT run_id,'M2_1_CONTROLLED_ENTRY_BASELINE'::text AS strategy_campaign_code,1::integer AS strategy_campaign_version,
           'Controlled Entry Baseline'::text AS strategy_campaign_name,'BASELINE_POLICY'::text AS strategy_type,
           'M2_1_ELIGIBILITY_POLICY_V1'::text AS policy_code,true AS baseline_flag,'APPROVED'::text AS campaign_status,
           as_of_date AS effective_start_date,NULL::date AS effective_end_date,
           'First governed Module 2 strategy posture: eligibility, policy gates, and routing only.'::text AS description,
           '7d9e466da28cad2551aa99c4c40c912b'::text AS source_g2_combined_hash,configuration_hash AS policy_configuration_hash
    FROM run_context
)
INSERT INTO msbf_m2.strategy_campaign(
    module1_run_id,strategy_campaign_code,strategy_campaign_version,strategy_campaign_name,
    strategy_type,policy_code,baseline_flag,campaign_status,effective_start_date,effective_end_date,
    description,source_g2_combined_hash,policy_configuration_hash,row_hash
)
SELECT s.*,msbf_ctl.m2_1_hash_jsonb(to_jsonb(s)) FROM seed s
ON CONFLICT(module1_run_id,strategy_campaign_code,strategy_campaign_version) DO UPDATE SET
    strategy_campaign_name=EXCLUDED.strategy_campaign_name,strategy_type=EXCLUDED.strategy_type,
    policy_code=EXCLUDED.policy_code,baseline_flag=EXCLUDED.baseline_flag,campaign_status=EXCLUDED.campaign_status,
    effective_start_date=EXCLUDED.effective_start_date,effective_end_date=EXCLUDED.effective_end_date,
    description=EXCLUDED.description,source_g2_combined_hash=EXCLUDED.source_g2_combined_hash,
    policy_configuration_hash=EXCLUDED.policy_configuration_hash,row_hash=EXCLUDED.row_hash;

WITH run_context AS (
    SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), seed(gate_code,gate_sequence,gate_name,gate_category,decision_influence_code,source_field_code,
        pass_rule,review_rule,fail_rule,blocked_rule,hard_stop_capable_flag,active_flag) AS (
    VALUES
        ('GATE_01_G2_CONTRACT_EVIDENCE', 1, 'G2 Contract Evidence', 'EVIDENCE', 'EVIDENCE', 'm1_15_contract_evidence_status', 'COMPLETE or PARTIAL contract evidence', 'Not applicable', 'Not applicable', 'BLOCKED contract evidence', FALSE, TRUE),
        ('GATE_02_DATA_CONFIDENCE', 2, 'Data Confidence', 'EVIDENCE', 'EVIDENCE', 'data_confidence_tier', 'HIGH', 'MEDIUM', 'Not applicable', 'LOW or missing', FALSE, TRUE),
        ('GATE_03_VERIFICATION', 3, 'Verification Disposition', 'VERIFICATION', 'HARD_STOP', 'verification_disposition', 'CLEAR', 'REVIEW', 'STOP', 'INSUFFICIENT_EVIDENCE or missing', TRUE, TRUE),
        ('GATE_04_FRAUD_RISK', 4, 'Fraud Risk', 'FRAUD', 'HARD_STOP', 'fraud_risk_tier', 'Tier 1-2', 'Tier 3', 'Tier 4-5', 'Missing', TRUE, TRUE),
        ('GATE_05_PROCESSOR_CONTINUITY', 5, 'Processor Continuity', 'OPERATIONS', 'REVIEW', 'processor_continuity_status', 'STABLE or MONITORED', 'WATCH or DISRUPTED', 'Not applicable', 'Missing', FALSE, TRUE),
        ('GATE_06_CAPACITY', 6, 'Capacity', 'CAPACITY', 'DECLINE', 'capacity_tier', 'Tier 1-2', 'Tier 3', 'Tier 4', 'Tier 5 or missing', FALSE, TRUE),
        ('GATE_07_AFFORDABILITY', 7, 'Affordability', 'CAPACITY', 'DECLINE', 'affordability_status', 'AFFORDABLE', 'MARGINAL', 'UNAFFORDABLE', 'INSUFFICIENT_EVIDENCE or missing', FALSE, TRUE),
        ('GATE_08_RESILIENCE', 8, 'Operating Resilience', 'RESILIENCE', 'DECLINE', 'resilience_tier', 'Tier 1-2', 'Tier 3', 'Tier 4', 'Tier 5 or missing', FALSE, TRUE),
        ('GATE_09_INTEGRATED_RISK', 9, 'Integrated Risk', 'RISK', 'DECLINE', 'integrated_risk_tier', 'Tier 1-2', 'Tier 3', 'Tier 4', 'Tier 5 or missing', FALSE, TRUE),
        ('GATE_10_UNIT_ECONOMICS', 10, 'Unit Economics', 'ECONOMICS', 'DECLINE', 'economic_tier/economic_status', 'Tier 1-2 and ABOVE_HURDLE', 'Tier 3-4 and nonnegative contribution', 'NEGATIVE_CONTRIBUTION', 'Tier 5 or INSUFFICIENT_EVIDENCE', FALSE, TRUE),
        ('GATE_11_UPSTREAM_HARD_STOP', 11, 'Upstream Hard Stop', 'GOVERNANCE', 'HARD_STOP', 'hard_stop_recommended_flag', 'false', 'Not applicable', 'true', 'Not applicable', TRUE, TRUE),
        ('GATE_12_ACQUISITION_EVIDENCE', 12, 'Acquisition Evidence Readiness', 'ACQUISITION', 'REVIEW_ONLY', 'acquisition_contract_evidence_status/attribution_evidence_status', 'COMPLETE or PARTIAL', 'BLOCKED', 'Not permitted', 'Not permitted', FALSE, TRUE)
), typed AS (
    SELECT r.run_id AS module1_run_id,'M2_1_CONTROLLED_ENTRY_BASELINE'::text AS strategy_campaign_code,s.*
    FROM run_context r CROSS JOIN seed s
)
INSERT INTO msbf_m2.policy_gate_definition(
    module1_run_id,strategy_campaign_code,gate_code,gate_sequence,gate_name,gate_category,
    decision_influence_code,source_field_code,pass_rule,review_rule,fail_rule,blocked_rule,
    hard_stop_capable_flag,active_flag,row_hash
)
SELECT t.*,msbf_ctl.m2_1_hash_jsonb(to_jsonb(t)) FROM typed t
ON CONFLICT(module1_run_id,strategy_campaign_code,gate_code) DO UPDATE SET
    gate_sequence=EXCLUDED.gate_sequence,gate_name=EXCLUDED.gate_name,gate_category=EXCLUDED.gate_category,
    decision_influence_code=EXCLUDED.decision_influence_code,source_field_code=EXCLUDED.source_field_code,
    pass_rule=EXCLUDED.pass_rule,review_rule=EXCLUDED.review_rule,fail_rule=EXCLUDED.fail_rule,
    blocked_rule=EXCLUDED.blocked_rule,hard_stop_capable_flag=EXCLUDED.hard_stop_capable_flag,
    active_flag=EXCLUDED.active_flag,row_hash=EXCLUDED.row_hash;

WITH run_context AS (
    SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), seed(reason_code,reason_category,reason_priority,source_gate_code,associated_route_code,display_text,
        production_adverse_action_flag,active_flag) AS (
    VALUES
        ('M2_1_G2_EVIDENCE_BLOCKED', 'EVIDENCE', 3, 'GATE_01_G2_CONTRACT_EVIDENCE', 'INSUFFICIENT_EVIDENCE', 'G2 contract evidence is blocked.', FALSE, TRUE),
        ('M2_1_DATA_CONFIDENCE_LOW', 'EVIDENCE', 3, 'GATE_02_DATA_CONFIDENCE', 'INSUFFICIENT_EVIDENCE', 'Data confidence is low or unavailable.', FALSE, TRUE),
        ('M2_1_DATA_CONFIDENCE_REVIEW', 'EVIDENCE', 2, 'GATE_02_DATA_CONFIDENCE', 'MANUAL_REVIEW', 'Data confidence requires review.', FALSE, TRUE),
        ('M2_1_VERIFICATION_STOP', 'VERIFICATION', 4, 'GATE_03_VERIFICATION', 'DECLINE_POLICY', 'Verification produced a governed stop.', FALSE, TRUE),
        ('M2_1_VERIFICATION_INSUFFICIENT', 'VERIFICATION', 3, 'GATE_03_VERIFICATION', 'INSUFFICIENT_EVIDENCE', 'Verification evidence is insufficient.', FALSE, TRUE),
        ('M2_1_VERIFICATION_REVIEW', 'VERIFICATION', 2, 'GATE_03_VERIFICATION', 'MANUAL_REVIEW', 'Verification requires manual review.', FALSE, TRUE),
        ('M2_1_FRAUD_POLICY_FAIL', 'FRAUD', 4, 'GATE_04_FRAUD_RISK', 'DECLINE_POLICY', 'Fraud risk exceeds policy.', FALSE, TRUE),
        ('M2_1_FRAUD_REVIEW', 'FRAUD', 2, 'GATE_04_FRAUD_RISK', 'MANUAL_REVIEW', 'Fraud risk requires review.', FALSE, TRUE),
        ('M2_1_PROCESSOR_CONTINUITY_REVIEW', 'OPERATIONS', 2, 'GATE_05_PROCESSOR_CONTINUITY', 'MANUAL_REVIEW', 'Processor continuity requires operational review.', FALSE, TRUE),
        ('M2_1_CAPACITY_FAIL', 'CAPACITY', 4, 'GATE_06_CAPACITY', 'DECLINE_POLICY', 'Capacity is outside policy.', FALSE, TRUE),
        ('M2_1_CAPACITY_REVIEW', 'CAPACITY', 2, 'GATE_06_CAPACITY', 'MANUAL_REVIEW', 'Capacity is marginal and requires review.', FALSE, TRUE),
        ('M2_1_AFFORDABILITY_FAIL', 'CAPACITY', 4, 'GATE_07_AFFORDABILITY', 'DECLINE_POLICY', 'Requested structure is unaffordable.', FALSE, TRUE),
        ('M2_1_AFFORDABILITY_REVIEW', 'CAPACITY', 2, 'GATE_07_AFFORDABILITY', 'MANUAL_REVIEW', 'Affordability is marginal.', FALSE, TRUE),
        ('M2_1_RESILIENCE_FAIL', 'RESILIENCE', 4, 'GATE_08_RESILIENCE', 'DECLINE_POLICY', 'Operating resilience is outside policy.', FALSE, TRUE),
        ('M2_1_RESILIENCE_REVIEW', 'RESILIENCE', 2, 'GATE_08_RESILIENCE', 'MANUAL_REVIEW', 'Operating resilience requires review.', FALSE, TRUE),
        ('M2_1_INTEGRATED_RISK_FAIL', 'RISK', 4, 'GATE_09_INTEGRATED_RISK', 'DECLINE_POLICY', 'Integrated risk exceeds policy.', FALSE, TRUE),
        ('M2_1_INTEGRATED_RISK_REVIEW', 'RISK', 2, 'GATE_09_INTEGRATED_RISK', 'MANUAL_REVIEW', 'Integrated risk requires review.', FALSE, TRUE),
        ('M2_1_NEGATIVE_CONTRIBUTION', 'ECONOMICS', 4, 'GATE_10_UNIT_ECONOMICS', 'DECLINE_POLICY', 'Risk-adjusted contribution is negative.', FALSE, TRUE),
        ('M2_1_ECONOMICS_REVIEW', 'ECONOMICS', 2, 'GATE_10_UNIT_ECONOMICS', 'MANUAL_REVIEW', 'Economics are below the preferred hurdle or require review.', FALSE, TRUE),
        ('M2_1_UPSTREAM_HARD_STOP', 'GOVERNANCE', 5, 'GATE_11_UPSTREAM_HARD_STOP', 'DECLINE_POLICY', 'Accepted upstream evidence recommends a hard stop.', FALSE, TRUE),
        ('M2_1_ACQUISITION_EVIDENCE_REVIEW', 'ACQUISITION', 2, 'GATE_12_ACQUISITION_EVIDENCE', 'MANUAL_REVIEW', 'Acquisition evidence requires operational review and is not a creditworthiness factor.', FALSE, TRUE),
        ('M2_1_ELIGIBLE_ALL_GATES_PASS', 'ELIGIBILITY', 1, NULL, 'ELIGIBLE_FOR_OFFER_DESIGN', 'All governed M2.1 policy gates pass.', FALSE, TRUE),
        ('M2_1_STRESS_NONIMPROVEMENT_FLOOR', 'SCENARIO', 2, NULL, 'MANUAL_REVIEW', 'Stress routing was floored to the matched baseline severity.', FALSE, TRUE)
), typed AS (
    SELECT r.run_id AS module1_run_id,'M2_1_CONTROLLED_ENTRY_BASELINE'::text AS strategy_campaign_code,s.*
    FROM run_context r CROSS JOIN seed s
)
INSERT INTO msbf_m2.reason_code_definition(
    module1_run_id,strategy_campaign_code,reason_code,reason_category,reason_priority,
    source_gate_code,associated_route_code,display_text,production_adverse_action_flag,active_flag,row_hash
)
SELECT t.*,msbf_ctl.m2_1_hash_jsonb(to_jsonb(t)) FROM typed t
ON CONFLICT(module1_run_id,strategy_campaign_code,reason_code) DO UPDATE SET
    reason_category=EXCLUDED.reason_category,reason_priority=EXCLUDED.reason_priority,
    source_gate_code=EXCLUDED.source_gate_code,associated_route_code=EXCLUDED.associated_route_code,
    display_text=EXCLUDED.display_text,production_adverse_action_flag=EXCLUDED.production_adverse_action_flag,
    active_flag=EXCLUDED.active_flag,row_hash=EXCLUDED.row_hash;

WITH run_context AS (
    SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), seed(route_code,route_rank,route_name,eligible_for_offer_design_flag,terminal_flag,description,active_flag) AS (
    VALUES
        ('ELIGIBLE_FOR_OFFER_DESIGN', 1, 'Eligible for Offer Design', TRUE, FALSE, 'Application may proceed to governed offer design; this is not an approval.', TRUE),
        ('MANUAL_REVIEW', 2, 'Manual Review', FALSE, FALSE, 'Application requires governed human review before offer design.', TRUE),
        ('INSUFFICIENT_EVIDENCE', 3, 'Insufficient Evidence', FALSE, FALSE, 'Evidence is insufficient for an automated policy route.', TRUE),
        ('DECLINE_POLICY', 4, 'Policy Decline', FALSE, TRUE, 'Application fails a governed policy gate; this is a synthetic strategy outcome, not a production adverse-action notice.', TRUE)
), typed AS (
    SELECT r.run_id AS module1_run_id,'M2_1_CONTROLLED_ENTRY_BASELINE'::text AS strategy_campaign_code,s.*
    FROM run_context r CROSS JOIN seed s
)
INSERT INTO msbf_m2.routing_outcome_definition(
    module1_run_id,strategy_campaign_code,route_code,route_rank,route_name,
    eligible_for_offer_design_flag,terminal_flag,description,active_flag,row_hash
)
SELECT t.*,msbf_ctl.m2_1_hash_jsonb(to_jsonb(t)) FROM typed t
ON CONFLICT(module1_run_id,strategy_campaign_code,route_code) DO UPDATE SET
    route_rank=EXCLUDED.route_rank,route_name=EXCLUDED.route_name,
    eligible_for_offer_design_flag=EXCLUDED.eligible_for_offer_design_flag,
    terminal_flag=EXCLUDED.terminal_flag,description=EXCLUDED.description,
    active_flag=EXCLUDED.active_flag,row_hash=EXCLUDED.row_hash;

INSERT INTO msbf_ref.acceptance_gate_catalog(gate_id,gate_name,module_code,severity,active_flag,description)
VALUES('M2_1_ELIGIBILITY_POLICY_ROUTING','M2.1 Eligibility, Policy Gates and Routing','M2','BLOCKING',true,
       'Governed first-stage Module 2 eligibility, policy-gate and decision-routing contract accepted.')
ON CONFLICT(gate_id) DO UPDATE SET gate_name=EXCLUDED.gate_name,module_code=EXCLUDED.module_code,
    severity=EXCLUDED.severity,active_flag=true,description=EXCLUDED.description;

CREATE OR REPLACE VIEW msbf_m2.v_m2_1_eligibility_latest AS
SELECT * FROM msbf_m2.application_eligibility_routing_latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_1_gate_results AS
SELECT
    g.module1_run_id,g.strategy_campaign_code,g.strategy_campaign_version,g.scenario_id,g.scenario_code,
    g.merchant_application_id,g.population_id,g.merchant_id,g.gate_code,d.gate_name,d.gate_category,
    d.decision_influence_code,g.gate_sequence,g.gate_outcome,g.gate_outcome_rank,g.hard_stop_flag,
    g.reason_code,g.observed_value_text,g.threshold_value_text,g.gate_evidence_status,g.row_hash
FROM msbf_m2.application_policy_gate_result g
JOIN msbf_m2.policy_gate_definition d
  ON d.module1_run_id=g.module1_run_id
 AND d.strategy_campaign_code=g.strategy_campaign_code
 AND d.gate_code=g.gate_code;

CREATE OR REPLACE VIEW msbf_m2.v_m2_1_matched_scenario_comparison AS
SELECT
    b.module1_run_id,b.strategy_campaign_code,b.merchant_application_id,b.population_id,b.merchant_id,
    b.scenario_id AS baseline_scenario_id,b.final_route_code AS baseline_route_code,
    b.final_route_rank AS baseline_route_rank,b.primary_reason_code AS baseline_primary_reason_code,
    s.scenario_id AS stress_scenario_id,s.final_route_code AS stress_route_code,
    s.final_route_rank AS stress_route_rank,s.primary_reason_code AS stress_primary_reason_code,
    s.final_route_rank-b.final_route_rank AS route_rank_delta,
    s.stress_floor_applied_flag,s.stress_worsening_flag,
    b.contract_row_hash AS baseline_contract_row_hash,s.contract_row_hash AS stress_contract_row_hash
FROM msbf_m2.application_eligibility_routing_latest b
JOIN msbf_m2.application_eligibility_routing_latest s
  ON s.module1_run_id=b.module1_run_id
 AND s.strategy_campaign_code=b.strategy_campaign_code
 AND s.merchant_application_id=b.merchant_application_id
WHERE b.scenario_code='BASELINE' AND s.scenario_code='RECESSION_ENERGY';

CREATE OR REPLACE VIEW msbf_ctl.v_m2_1_strategy_lineage AS
SELECT
    r.module1_run_id,r.contract_code,r.contract_version,r.schema_version,r.methodology_version,
    r.source_g2_bundle_code,r.source_g2_bundle_version,r.source_g2_schema_version,r.source_g2_combined_hash,
    r.policy_configuration_hash,r.strategy_campaign_rows,r.gate_definition_rows,r.reason_code_rows,
    r.outcome_definition_rows,r.gate_result_rows,r.routing_snapshot_rows,r.latest_rows,r.archive_rows,
    r.comparison_rows,r.canonical_entities,r.campaign_set_hash,r.gate_definition_set_hash,
    r.reason_code_set_hash,r.outcome_definition_set_hash,r.gate_result_set_hash,
    r.routing_snapshot_set_hash,r.latest_set_hash,r.archive_set_hash,r.contract_set_hash,
    r.combined_set_hash,r.contract_status,r.generated_at,r.validated_at,r.accepted_at,r.row_hash
FROM msbf_ctl.m2_1_strategy_contract_registry r;

CREATE OR REPLACE VIEW msbf_m2.v_m2_1_power_bi_routing AS
SELECT
    l.module1_run_id,l.strategy_campaign_code,l.scenario_id,l.scenario_code,
    l.merchant_application_id,l.population_id,l.merchant_id,l.as_of_date,
    l.final_route_code,l.final_route_rank,l.eligible_for_offer_design_flag,l.hard_stop_flag,
    l.stress_floor_applied_flag,l.stress_worsening_flag,l.pass_gate_count,l.review_gate_count,
    l.blocked_gate_count,l.fail_gate_count,l.primary_reason_code,l.secondary_reason_code,
    l.tertiary_reason_code,l.routing_evidence_status,l.contract_row_hash
FROM msbf_m2.application_eligibility_routing_latest l;

COMMIT;

SELECT
    'M2_1_SCHEMA_POLICY_REFERENCE_EXTENSION' AS checkpoint,
    to_regclass('msbf_m2.application_policy_gate_result') IS NOT NULL AS gate_result_table_exists,
    to_regclass('msbf_m2.application_eligibility_routing_snapshot') IS NOT NULL AS snapshot_table_exists,
    to_regclass('msbf_m2.application_eligibility_routing_latest') IS NOT NULL AS latest_table_exists,
    to_regclass('msbf_m2.application_eligibility_routing_archive') IS NOT NULL AS archive_table_exists,
    (SELECT policy_status FROM msbf_ctl.m2_1_policy_profile WHERE policy_code='M2_1_ELIGIBILITY_POLICY_V1') AS policy_status,
    (SELECT count(*) FROM msbf_m2.strategy_campaign WHERE strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE') AS strategy_campaign_rows,
    (SELECT count(*) FROM msbf_m2.policy_gate_definition WHERE strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE') AS gate_definition_rows,
    (SELECT count(*) FROM msbf_m2.reason_code_definition WHERE strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE') AS reason_code_rows,
    (SELECT count(*) FROM msbf_m2.routing_outcome_definition WHERE strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE') AS outcome_definition_rows,
    'PASS'::text AS schema_policy_extension_status;
