/* ============================================================================
Revision v0.2R1 correction
- Replaces the invalid `TEMP_HASH` policy-row placeholder with a deterministic
  row hash calculated before insertion from an exact target-typed physical
  policy seed.
- Registers `M2_3_FINAL_OFFER_DECISION_AUTHORIZATION` in the governed
  acceptance-gate catalog so Program 153 cannot later fail its foreign key.
- Adds gate-catalog verification to the schema checkpoint and preflight.
- No policy value, outcome mapping, reason definition, expected count,
  contract boundary, or downstream business methodology is changed.
============================================================================ */

/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.3 — Final Offer & Decision Authorization

Program     : 148_msbf_m2_3_schema_policy_decision_contract_extension_v0_2R1.sql
Version     : v0.2R1
Purpose     : Establish governed M2.3 policy, outcome and reason dictionaries,
              final-offer decision contracts, immutable archive enforcement,
              deterministic hash utilities, validation assertions, and
              consumption views.

Predecessor : Accepted M2.2 pricing/structure contract.
Boundary    : M2.3 authorizes synthetic final offer/decision outcomes only.
              It does not book, fund, transmit notices, or create production
              adverse action.

Run mode    : Execute once after M2.2 acceptance and before Program 149.
============================================================================ */

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '20min';
SET LOCAL jit = off;

CREATE SCHEMA IF NOT EXISTS msbf_ctl;
CREATE SCHEMA IF NOT EXISTS msbf_m2;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_3_hash_jsonb(p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $function$
    SELECT md5(p_payload::text);
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_3_registry_row_hash(p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $function$
    SELECT msbf_ctl.m2_3_hash_jsonb(
        p_payload
        - 'registry_id'
        - 'contract_status'
        - 'generated_at'
        - 'validated_at'
        - 'accepted_at'
        - 'row_hash'
        - 'created_at'
        - 'contract_set_hash'
        - 'combined_set_hash'
    );
$function$;

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_3_policy_profile
(
    module1_run_id                         bigint PRIMARY KEY,
    policy_code                            text NOT NULL,
    policy_version                         integer NOT NULL,
    policy_status                          text NOT NULL,
    methodology_version                    text NOT NULL,
    contract_code                          text NOT NULL,
    contract_version                       integer NOT NULL,
    schema_version                         text NOT NULL,
    source_m2_2_contract_code              text NOT NULL,
    source_m2_2_contract_version           integer NOT NULL,
    source_m2_2_schema_version             text NOT NULL,
    source_m2_2_combined_hash              text NOT NULL,
    source_m2_2_acceptance_gate_id         text NOT NULL,
    final_offer_authorization_enabled_flag boolean NOT NULL,
    decline_authorization_enabled_flag     boolean NOT NULL,
    manual_review_authorization_enabled_flag boolean NOT NULL,
    synthetic_data_only_flag               boolean NOT NULL,
    no_booking_funding_flag                boolean NOT NULL,
    no_external_notice_generation_flag     boolean NOT NULL,
    no_production_adverse_action_notice_flag boolean NOT NULL,
    expected_policy_rows                   bigint NOT NULL,
    expected_outcome_rows                  bigint NOT NULL,
    expected_reason_rows                   bigint NOT NULL,
    expected_source_rows                   bigint NOT NULL,
    expected_decision_snapshot_rows        bigint NOT NULL,
    expected_decision_latest_rows          bigint NOT NULL,
    expected_decision_archive_rows         bigint NOT NULL,
    expected_comparison_rows               bigint NOT NULL,
    expected_registry_rows                 bigint NOT NULL,
    expected_canonical_entities            bigint NOT NULL,
    expected_positive_controls             integer NOT NULL,
    expected_negative_controls             integer NOT NULL,
    expected_detail_result_sets            integer NOT NULL,
    configuration_payload                  jsonb NOT NULL,
    configuration_hash                     text NOT NULL,
    row_hash                               text NOT NULL,
    created_at                             timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at                             timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT ck_m2_3_policy_identity CHECK
    (
        policy_code = 'M2_3_FINAL_OFFER_DECISION_POLICY_V1'
        AND policy_version = 1
        AND methodology_version = 'M2_3_METHOD_V1'
        AND contract_code = 'M2_FINAL_OFFER_DECISION_CONSUMPTION'
        AND contract_version = 1
        AND schema_version = 'M2_3_FINAL_DECISION_SCHEMA_V1'
    ),
    CONSTRAINT ck_m2_3_policy_status CHECK(policy_status IN('APPROVED','RETIRED')),
    CONSTRAINT ck_m2_3_policy_hashes CHECK
    (
        length(configuration_hash)=32
        AND configuration_hash ~ '^[0-9a-f]+$'
        AND length(row_hash)=32
        AND row_hash ~ '^[0-9a-f]+$'
    ),
    CONSTRAINT ck_m2_3_policy_boundaries CHECK
    (
        final_offer_authorization_enabled_flag
        AND decline_authorization_enabled_flag
        AND manual_review_authorization_enabled_flag
        AND synthetic_data_only_flag
        AND no_booking_funding_flag
        AND no_external_notice_generation_flag
        AND no_production_adverse_action_notice_flag
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.final_decision_outcome_definition
(
    module1_run_id               bigint NOT NULL,
    decision_outcome_code        text NOT NULL,
    decision_outcome_rank        integer NOT NULL,
    customer_offer_flag          boolean NOT NULL,
    decline_flag                 boolean NOT NULL,
    manual_review_flag           boolean NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    booking_funding_flag         boolean NOT NULL,
    outcome_status               text NOT NULL,
    description                  text NOT NULL,
    row_hash                     text NOT NULL,
    created_at                   timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,decision_outcome_code),
    CONSTRAINT ck_m2_3_outcome_status CHECK(outcome_status IN('APPROVED','RETIRED')),
    CONSTRAINT ck_m2_3_outcome_boundaries CHECK
    (
        production_adverse_action_notice_flag IS FALSE
        AND booking_funding_flag IS FALSE
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.final_decision_reason_definition
(
    module1_run_id               bigint NOT NULL,
    decision_reason_code         text NOT NULL,
    mapped_decision_outcome_code text NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    reason_status                text NOT NULL,
    description                  text NOT NULL,
    row_hash                     text NOT NULL,
    created_at                   timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,decision_reason_code),
    CONSTRAINT fk_m2_3_reason_outcome FOREIGN KEY
        (module1_run_id,mapped_decision_outcome_code)
        REFERENCES msbf_m2.final_decision_outcome_definition
        (module1_run_id,decision_outcome_code),
    CONSTRAINT ck_m2_3_reason_status CHECK(reason_status IN('APPROVED','RETIRED')),
    CONSTRAINT ck_m2_3_reason_no_adverse_action CHECK
    (
        production_adverse_action_notice_flag IS FALSE
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_final_decision_source_snapshot
(
    module1_run_id                    bigint NOT NULL,
    scenario_id                       bigint NOT NULL,
    scenario_code                     text NOT NULL,
    merchant_application_id           text NOT NULL,
    population_id                     text NOT NULL,
    merchant_id                       text NOT NULL,
    as_of_date                        date NOT NULL,
    pricing_disposition_code          text NOT NULL,
    structure_available_flag          boolean NOT NULL,
    review_required_flag              boolean NOT NULL,
    selected_candidate_template_code  text,
    selected_funding_amount           numeric(18,2),
    selected_remittance_rate          numeric(9,6),
    selected_payback_multiple         numeric(9,6),
    selected_collection_horizon_days  integer,
    selected_total_repayment_amount   numeric(18,2),
    selected_finance_charge_amount    numeric(18,2),
    selected_implied_daily_collection_amount numeric(18,2),
    selected_implied_payoff_days      numeric(18,4),
    source_m2_2_contract_row_hash     text NOT NULL,
    source_request_contract_row_hash  text NOT NULL,
    source_g2_combined_hash           text NOT NULL,
    source_payload                    jsonb NOT NULL,
    row_hash                          text NOT NULL,
    created_at                        timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_3_source_scenario CHECK(scenario_code IN('BASELINE','RECESSION_ENERGY'))
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_final_offer_decision_snapshot
(
    module1_run_id                    bigint NOT NULL,
    scenario_id                       bigint NOT NULL,
    scenario_code                     text NOT NULL,
    merchant_application_id           text NOT NULL,
    population_id                     text NOT NULL,
    merchant_id                       text NOT NULL,
    as_of_date                        date NOT NULL,
    source_pricing_disposition_code   text NOT NULL,
    final_decision_outcome_code       text NOT NULL,
    final_decision_rank               integer NOT NULL,
    final_offer_authorized_flag       boolean NOT NULL,
    counteroffer_review_required_flag boolean NOT NULL,
    decline_authorized_flag           boolean NOT NULL,
    manual_review_required_flag       boolean NOT NULL,
    final_offer_amount                numeric(18,2),
    final_remittance_rate             numeric(9,6),
    final_payback_multiple            numeric(9,6),
    final_collection_horizon_days     integer,
    final_total_repayment_amount      numeric(18,2),
    final_finance_charge_amount       numeric(18,2),
    final_implied_daily_collection_amount numeric(18,2),
    final_implied_payoff_days         numeric(18,4),
    final_offer_expiration_days       integer,
    final_authorization_evidence_status text NOT NULL,
    primary_decision_reason_code      text NOT NULL,
    decision_reason_codes             jsonb NOT NULL,
    source_m2_2_contract_row_hash     text NOT NULL,
    source_request_contract_row_hash  text NOT NULL,
    source_g2_combined_hash           text NOT NULL,
    source_snapshot_row_hash          text NOT NULL,
    policy_configuration_hash         text NOT NULL,
    row_hash                          text NOT NULL,
    created_at                        timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT fk_m2_3_snapshot_outcome FOREIGN KEY
        (module1_run_id,final_decision_outcome_code)
        REFERENCES msbf_m2.final_decision_outcome_definition
        (module1_run_id,decision_outcome_code),
    CONSTRAINT fk_m2_3_snapshot_reason FOREIGN KEY
        (module1_run_id,primary_decision_reason_code)
        REFERENCES msbf_m2.final_decision_reason_definition
        (module1_run_id,decision_reason_code),
    CONSTRAINT ck_m2_3_snapshot_status CHECK
    (
        final_authorization_evidence_status IN
        ('AUTHORIZED','REVIEW_REQUIRED','DECLINE_AUTHORIZED','BLOCKED')
    ),
    CONSTRAINT ck_m2_3_offer_terms CHECK
    (
        (
            final_offer_authorized_flag
            AND final_offer_amount IS NOT NULL
            AND final_remittance_rate IS NOT NULL
            AND final_payback_multiple IS NOT NULL
            AND final_collection_horizon_days IS NOT NULL
            AND final_total_repayment_amount IS NOT NULL
            AND final_finance_charge_amount IS NOT NULL
            AND final_offer_expiration_days IS NOT NULL
            AND decline_authorized_flag IS FALSE
        )
        OR
        (
            final_offer_authorized_flag IS FALSE
            AND final_offer_amount IS NULL
            AND final_remittance_rate IS NULL
            AND final_payback_multiple IS NULL
            AND final_collection_horizon_days IS NULL
            AND final_total_repayment_amount IS NULL
            AND final_finance_charge_amount IS NULL
            AND final_offer_expiration_days IS NULL
        )
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_final_offer_decision_latest
(
    module1_run_id                    bigint NOT NULL,
    contract_code                     text NOT NULL,
    contract_version                  integer NOT NULL,
    schema_version                    text NOT NULL,
    methodology_version               text NOT NULL,
    scenario_id                       bigint NOT NULL,
    scenario_code                     text NOT NULL,
    merchant_application_id           text NOT NULL,
    population_id                     text NOT NULL,
    merchant_id                       text NOT NULL,
    as_of_date                        date NOT NULL,
    source_pricing_disposition_code   text NOT NULL,
    final_decision_outcome_code       text NOT NULL,
    final_decision_rank               integer NOT NULL,
    final_offer_authorized_flag       boolean NOT NULL,
    counteroffer_review_required_flag boolean NOT NULL,
    decline_authorized_flag           boolean NOT NULL,
    manual_review_required_flag       boolean NOT NULL,
    final_offer_amount                numeric(18,2),
    final_remittance_rate             numeric(9,6),
    final_payback_multiple            numeric(9,6),
    final_collection_horizon_days     integer,
    final_total_repayment_amount      numeric(18,2),
    final_finance_charge_amount       numeric(18,2),
    final_implied_daily_collection_amount numeric(18,2),
    final_implied_payoff_days         numeric(18,4),
    final_offer_expiration_days       integer,
    final_authorization_evidence_status text NOT NULL,
    primary_decision_reason_code      text NOT NULL,
    decision_reason_codes             jsonb NOT NULL,
    source_m2_2_contract_row_hash     text NOT NULL,
    source_request_contract_row_hash  text NOT NULL,
    source_g2_combined_hash           text NOT NULL,
    source_snapshot_row_hash          text NOT NULL,
    snapshot_row_hash                 text NOT NULL,
    policy_configuration_hash         text NOT NULL,
    contract_row_hash                 text NOT NULL,
    created_at                        timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_3_latest_identity CHECK
    (
        contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
        AND contract_version=1
        AND schema_version='M2_3_FINAL_DECISION_SCHEMA_V1'
        AND methodology_version='M2_3_METHOD_V1'
    )
);

CREATE TABLE IF NOT EXISTS msbf_m2.application_final_offer_decision_archive
(
    archive_id                        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id                    bigint NOT NULL,
    contract_code                     text NOT NULL,
    contract_version                  integer NOT NULL,
    schema_version                    text NOT NULL,
    methodology_version               text NOT NULL,
    scenario_id                       bigint NOT NULL,
    scenario_code                     text NOT NULL,
    merchant_application_id           text NOT NULL,
    population_id                     text NOT NULL,
    merchant_id                       text NOT NULL,
    as_of_date                        date NOT NULL,
    source_pricing_disposition_code   text NOT NULL,
    final_decision_outcome_code       text NOT NULL,
    final_decision_rank               integer NOT NULL,
    final_offer_authorized_flag       boolean NOT NULL,
    counteroffer_review_required_flag boolean NOT NULL,
    decline_authorized_flag           boolean NOT NULL,
    manual_review_required_flag       boolean NOT NULL,
    final_offer_amount                numeric(18,2),
    final_remittance_rate             numeric(9,6),
    final_payback_multiple            numeric(9,6),
    final_collection_horizon_days     integer,
    final_total_repayment_amount      numeric(18,2),
    final_finance_charge_amount       numeric(18,2),
    final_implied_daily_collection_amount numeric(18,2),
    final_implied_payoff_days         numeric(18,4),
    final_offer_expiration_days       integer,
    final_authorization_evidence_status text NOT NULL,
    primary_decision_reason_code      text NOT NULL,
    decision_reason_codes             jsonb NOT NULL,
    source_m2_2_contract_row_hash     text NOT NULL,
    source_request_contract_row_hash  text NOT NULL,
    source_g2_combined_hash           text NOT NULL,
    source_snapshot_row_hash          text NOT NULL,
    snapshot_row_hash                 text NOT NULL,
    policy_configuration_hash         text NOT NULL,
    contract_row_hash                 text NOT NULL,
    contract_payload                  jsonb NOT NULL,
    archive_row_hash                  text NOT NULL,
    archived_at                       timestamptz NOT NULL DEFAULT clock_timestamp(),
    created_at                        timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE(module1_run_id,contract_version,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_3_archive_identity CHECK
    (
        contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
        AND contract_version=1
        AND schema_version='M2_3_FINAL_DECISION_SCHEMA_V1'
        AND methodology_version='M2_3_METHOD_V1'
    )
);

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_3_final_decision_contract_registry
(
    registry_id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id              bigint NOT NULL UNIQUE,
    contract_code               text NOT NULL,
    contract_version            integer NOT NULL,
    schema_version              text NOT NULL,
    methodology_version         text NOT NULL,
    source_m2_2_contract_code   text NOT NULL,
    source_m2_2_contract_version integer NOT NULL,
    source_m2_2_schema_version  text NOT NULL,
    source_m2_2_combined_hash   text NOT NULL,
    source_m2_2_acceptance_gate_id text NOT NULL,
    policy_configuration_hash   text NOT NULL,
    policy_rows                 bigint NOT NULL,
    outcome_rows                bigint NOT NULL,
    reason_rows                 bigint NOT NULL,
    source_rows                 bigint NOT NULL,
    decision_snapshot_rows      bigint NOT NULL,
    decision_latest_rows        bigint NOT NULL,
    decision_archive_rows       bigint NOT NULL,
    comparison_rows             bigint NOT NULL,
    registry_rows               bigint NOT NULL,
    canonical_entities          bigint NOT NULL,
    final_offer_authorized_rows bigint NOT NULL,
    manual_review_required_rows bigint NOT NULL,
    decline_insufficient_evidence_rows bigint NOT NULL,
    decline_policy_rows         bigint NOT NULL,
    policy_set_hash             text NOT NULL,
    outcome_set_hash            text NOT NULL,
    reason_set_hash             text NOT NULL,
    source_set_hash             text NOT NULL,
    decision_snapshot_set_hash  text NOT NULL,
    decision_latest_set_hash    text NOT NULL,
    decision_archive_set_hash   text NOT NULL,
    contract_set_hash           text NOT NULL,
    combined_set_hash           text NOT NULL,
    contract_status             text NOT NULL,
    generated_at                timestamptz,
    validated_at                timestamptz,
    accepted_at                 timestamptz,
    row_hash                    text NOT NULL,
    created_at                  timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT ck_m2_3_registry_status CHECK(contract_status IN('GENERATED','VALIDATED','ACCEPTED')),
    CONSTRAINT ck_m2_3_registry_identity CHECK
    (
        contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
        AND contract_version=1
        AND schema_version='M2_3_FINAL_DECISION_SCHEMA_V1'
        AND methodology_version='M2_3_METHOD_V1'
    )
);

CREATE OR REPLACE FUNCTION msbf_ctl.m2_3_archive_immutable()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    RAISE EXCEPTION
        'M2.3 final-decision archive is immutable; % is not permitted.',
        TG_OP;
END;
$function$;

DROP TRIGGER IF EXISTS trg_m2_3_decision_archive_immutable
ON msbf_m2.application_final_offer_decision_archive;

CREATE TRIGGER trg_m2_3_decision_archive_immutable
BEFORE UPDATE OR DELETE
ON msbf_m2.application_final_offer_decision_archive
FOR EACH ROW
EXECUTE FUNCTION msbf_ctl.m2_3_archive_immutable();

CREATE INDEX IF NOT EXISTS ix_m2_3_source_application
ON msbf_m2.application_final_decision_source_snapshot
(module1_run_id,merchant_application_id,scenario_id);

CREATE INDEX IF NOT EXISTS ix_m2_3_decision_latest_outcome
ON msbf_m2.application_final_offer_decision_latest
(module1_run_id,final_decision_outcome_code,scenario_code);

CREATE INDEX IF NOT EXISTS ix_m2_3_decision_archive_application
ON msbf_m2.application_final_offer_decision_archive
(module1_run_id,merchant_application_id,scenario_id);

CREATE OR REPLACE FUNCTION msbf_ctl.m2_3_assert_configuration(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v record;
BEGIN
    SELECT *
    INTO v
    FROM msbf_ctl.m2_3_policy_profile
    WHERE module1_run_id = p_run_id;

    IF v.module1_run_id IS NULL
       OR v.policy_status <> 'APPROVED'
       OR v.policy_code <> 'M2_3_FINAL_OFFER_DECISION_POLICY_V1'
       OR v.methodology_version <> 'M2_3_METHOD_V1'
       OR v.contract_code <> 'M2_FINAL_OFFER_DECISION_CONSUMPTION'
       OR v.contract_version <> 1
       OR v.schema_version <> 'M2_3_FINAL_DECISION_SCHEMA_V1'
       OR v.source_m2_2_contract_code <> 'M2_PRICING_STRUCTURE_CONSUMPTION'
       OR v.source_m2_2_contract_version <> 1
       OR v.source_m2_2_schema_version <> 'M2_2_PRICING_STRUCTURE_SCHEMA_V1'
       OR v.source_m2_2_combined_hash <> 'bbe83b187b31ea561789797322031fc6'
       OR v.source_m2_2_acceptance_gate_id <> 'M2_2_PRICING_STRUCTURE_COUNTEROFFER'
       OR v.final_offer_authorization_enabled_flag IS DISTINCT FROM TRUE
       OR v.decline_authorization_enabled_flag IS DISTINCT FROM TRUE
       OR v.manual_review_authorization_enabled_flag IS DISTINCT FROM TRUE
       OR v.synthetic_data_only_flag IS DISTINCT FROM TRUE
       OR v.no_booking_funding_flag IS DISTINCT FROM TRUE
       OR v.no_external_notice_generation_flag IS DISTINCT FROM TRUE
       OR v.no_production_adverse_action_notice_flag IS DISTINCT FROM TRUE
       OR (v.configuration_payload->>'synthetic_data_only')::boolean
            IS DISTINCT FROM v.synthetic_data_only_flag
       OR (v.configuration_payload->>'no_booking_or_funding')::boolean
            IS DISTINCT FROM v.no_booking_funding_flag
       OR (v.configuration_payload->>'no_external_notice_generation')::boolean
            IS DISTINCT FROM v.no_external_notice_generation_flag
       OR (v.configuration_payload->>'no_production_adverse_action_notice')::boolean
            IS DISTINCT FROM v.no_production_adverse_action_notice_flag
       OR v.configuration_hash IS DISTINCT FROM
          msbf_ctl.m2_3_hash_jsonb(v.configuration_payload)
       OR v.row_hash IS DISTINCT FROM
          msbf_ctl.m2_3_hash_jsonb(
              to_jsonb(v)
              - 'row_hash'
              - 'created_at'
              - 'updated_at'
          ) THEN
        RAISE EXCEPTION
            'M2.3 configuration assertion failed for run_id %.',
            p_run_id;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_3_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_status text;
BEGIN
    PERFORM msbf_ctl.m2_3_assert_configuration(p_run_id);

    SELECT run_status
    INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    IF v_run_status <> 'M2_2_ACCEPTED' THEN
        RAISE EXCEPTION
            'M2.3 generation requires M2_2_ACCEPTED; observed %.',
            v_run_status;
    END IF;

    IF EXISTS
    (
        SELECT 1 FROM msbf_m2.application_final_decision_source_snapshot
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.application_final_offer_decision_snapshot
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.application_final_offer_decision_latest
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.application_final_offer_decision_archive
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_ctl.m2_3_final_decision_contract_registry
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_ctl.run_evidence
        WHERE run_id = p_run_id
          AND evidence_code LIKE 'M2_3_%'
        UNION ALL
        SELECT 1 FROM msbf_ctl.acceptance_gate_result
        WHERE run_id = p_run_id
          AND gate_id = 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
    ) THEN
        RAISE EXCEPTION
            'M2.3 generation requires empty M2.3 targets for run_id %.',
            p_run_id;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_3_assert_validation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_status text;
    v_contract_status text;
BEGIN
    PERFORM msbf_ctl.m2_3_assert_configuration(p_run_id);

    SELECT run_status
    INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    SELECT contract_status
    INTO v_contract_status
    FROM msbf_ctl.m2_3_final_decision_contract_registry
    WHERE module1_run_id = p_run_id;

    IF v_run_status <> 'M2_3_GENERATED'
       OR v_contract_status <> 'GENERATED' THEN
        RAISE EXCEPTION
            'M2.3 validation requires generated state; run %, contract %.',
            v_run_status, v_contract_status;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_3_assert_acceptance_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_status text;
    v_contract_status text;
    v_pos bigint;
    v_neg bigint;
BEGIN
    PERFORM msbf_ctl.m2_3_assert_configuration(p_run_id);

    SELECT run_status
    INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    SELECT contract_status
    INTO v_contract_status
    FROM msbf_ctl.m2_3_final_decision_contract_registry
    WHERE module1_run_id = p_run_id;

    SELECT
        count(*) FILTER(WHERE evidence_code LIKE 'M2_3_POS_%' AND status='PASS'),
        count(*) FILTER(WHERE evidence_code LIKE 'M2_3_NEG_%' AND status='PASS')
    INTO v_pos, v_neg
    FROM msbf_ctl.run_evidence
    WHERE run_id = p_run_id;

    IF v_run_status <> 'M2_3_VALIDATED'
       OR v_contract_status <> 'VALIDATED'
       OR v_pos <> 120
       OR v_neg <> 20 THEN
        RAISE EXCEPTION
            'M2.3 acceptance not ready: run %, contract %, positive %, negative %.',
            v_run_status, v_contract_status, v_pos, v_neg;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_3_assert_no_booking_payload(p_payload jsonb)
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
        'booking',
        'booking_status',
        'funding',
        'funding_status',
        'funded_amount',
        'production_adverse_action_notice',
        'external_notice',
        'account_opened',
        'loan_number'
    )
    LIMIT 1;

    IF v_key IS NOT NULL THEN
        RAISE EXCEPTION
            'M2.3 boundary rejected prohibited payload key %.',
            v_key;
    END IF;
END;
$function$;

INSERT INTO msbf_ref.acceptance_gate_catalog
(
    gate_id,
    gate_name,
    module_code,
    severity,
    active_flag,
    description
)
VALUES
(
    'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION',
    'M2.3 Final Offer & Decision Authorization',
    'M2.3',
    'BLOCKING',
    TRUE,
    'Accepts bounded synthetic final-offer and decision authorization; no booking, funding, external notice, or production adverse-action notice.'
)
ON CONFLICT(gate_id)
DO UPDATE SET
    gate_name = EXCLUDED.gate_name,
    module_code = EXCLUDED.module_code,
    severity = EXCLUDED.severity,
    active_flag = EXCLUDED.active_flag,
    description = EXCLUDED.description;

WITH policy_seed AS
(
    SELECT
        registry.module1_run_id::bigint
            AS module1_run_id,
        'M2_3_FINAL_OFFER_DECISION_POLICY_V1'::text
            AS policy_code,
        1::integer
            AS policy_version,
        'APPROVED'::text
            AS policy_status,
        'M2_3_METHOD_V1'::text
            AS methodology_version,
        'M2_FINAL_OFFER_DECISION_CONSUMPTION'::text
            AS contract_code,
        1::integer
            AS contract_version,
        'M2_3_FINAL_DECISION_SCHEMA_V1'::text
            AS schema_version,
        'M2_PRICING_STRUCTURE_CONSUMPTION'::text
            AS source_m2_2_contract_code,
        1::integer
            AS source_m2_2_contract_version,
        'M2_2_PRICING_STRUCTURE_SCHEMA_V1'::text
            AS source_m2_2_schema_version,
        'bbe83b187b31ea561789797322031fc6'::text
            AS source_m2_2_combined_hash,
        'M2_2_PRICING_STRUCTURE_COUNTEROFFER'::text
            AS source_m2_2_acceptance_gate_id,
        TRUE::boolean AS final_offer_authorization_enabled_flag,
        TRUE::boolean AS decline_authorization_enabled_flag,
        TRUE::boolean AS manual_review_authorization_enabled_flag,
        TRUE::boolean AS synthetic_data_only_flag,
        TRUE::boolean AS no_booking_funding_flag,
        TRUE::boolean AS no_external_notice_generation_flag,
        TRUE::boolean AS no_production_adverse_action_notice_flag,
        1::bigint AS expected_policy_rows,
        5::bigint AS expected_outcome_rows,
        22::bigint AS expected_reason_rows,
        1500::bigint AS expected_source_rows,
        1500::bigint AS expected_decision_snapshot_rows,
        1500::bigint AS expected_decision_latest_rows,
        1500::bigint AS expected_decision_archive_rows,
        750::bigint AS expected_comparison_rows,
        1::bigint AS expected_registry_rows,
        6029::bigint AS expected_canonical_entities,
        120::integer AS expected_positive_controls,
        20::integer AS expected_negative_controls,
        24::integer AS expected_detail_result_sets,
        '{"acceptance_gate":"M2_3_FINAL_OFFER_DECISION_AUTHORIZATION","contract_code":"M2_FINAL_OFFER_DECISION_CONSUMPTION","contract_version":1,"decline_authorization_enabled":true,"expected":{"canonical_entities":6029,"comparison_rows":750,"decision_archive_rows":1500,"decision_latest_rows":1500,"decision_snapshot_rows":1500,"decline_insufficient_evidence_rows":178,"decline_policy_rows":1073,"detail_result_sets":24,"final_offer_authorized_rows":59,"generation_evidence_rows":20,"manual_review_required_rows":190,"negative_controls":20,"outcome_rows":5,"policy_rows":1,"positive_controls":120,"reason_rows":22,"registry_rows":1,"source_rows":1500},"final_offer_authorization_enabled":true,"manual_review_authorization_enabled":true,"methodology":"M2_3_METHOD_V1","no_booking_or_funding":true,"no_external_notice_generation":true,"no_production_adverse_action_notice":true,"policy_code":"M2_3_FINAL_OFFER_DECISION_POLICY_V1","schema_version":"M2_3_FINAL_DECISION_SCHEMA_V1","source_m2_2_combined_hash":"bbe83b187b31ea561789797322031fc6","source_m2_2_contract_code":"M2_PRICING_STRUCTURE_CONSUMPTION","source_m2_2_contract_version":1,"source_m2_2_schema_version":"M2_2_PRICING_STRUCTURE_SCHEMA_V1","synthetic_data_only":true}'::jsonb
            AS configuration_payload,
        msbf_ctl.m2_3_hash_jsonb('{"acceptance_gate":"M2_3_FINAL_OFFER_DECISION_AUTHORIZATION","contract_code":"M2_FINAL_OFFER_DECISION_CONSUMPTION","contract_version":1,"decline_authorization_enabled":true,"expected":{"canonical_entities":6029,"comparison_rows":750,"decision_archive_rows":1500,"decision_latest_rows":1500,"decision_snapshot_rows":1500,"decline_insufficient_evidence_rows":178,"decline_policy_rows":1073,"detail_result_sets":24,"final_offer_authorized_rows":59,"generation_evidence_rows":20,"manual_review_required_rows":190,"negative_controls":20,"outcome_rows":5,"policy_rows":1,"positive_controls":120,"reason_rows":22,"registry_rows":1,"source_rows":1500},"final_offer_authorization_enabled":true,"manual_review_authorization_enabled":true,"methodology":"M2_3_METHOD_V1","no_booking_or_funding":true,"no_external_notice_generation":true,"no_production_adverse_action_notice":true,"policy_code":"M2_3_FINAL_OFFER_DECISION_POLICY_V1","schema_version":"M2_3_FINAL_DECISION_SCHEMA_V1","source_m2_2_combined_hash":"bbe83b187b31ea561789797322031fc6","source_m2_2_contract_code":"M2_PRICING_STRUCTURE_CONSUMPTION","source_m2_2_contract_version":1,"source_m2_2_schema_version":"M2_2_PRICING_STRUCTURE_SCHEMA_V1","synthetic_data_only":true}'::jsonb)
            AS configuration_hash
    FROM msbf_ctl.m2_2_pricing_structure_contract_registry AS registry
    JOIN msbf_ctl.run_registry AS run
      ON run.run_id = registry.module1_run_id
    WHERE run.run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run.run_version = 1
      AND run.run_status = 'M2_2_ACCEPTED'
      AND registry.contract_status = 'ACCEPTED'
      AND registry.pricing_contract_code = 'M2_PRICING_STRUCTURE_CONSUMPTION'
      AND registry.pricing_contract_version = 1
      AND registry.pricing_schema_version = 'M2_2_PRICING_STRUCTURE_SCHEMA_V1'
      AND registry.combined_set_hash = 'bbe83b187b31ea561789797322031fc6'
),
policy_hashed AS
(
    SELECT
        seed.*,
        msbf_ctl.m2_3_hash_jsonb(to_jsonb(seed))
            AS row_hash
    FROM policy_seed AS seed
)
INSERT INTO msbf_ctl.m2_3_policy_profile
(
    module1_run_id,
    policy_code,
    policy_version,
    policy_status,
    methodology_version,
    contract_code,
    contract_version,
    schema_version,
    source_m2_2_contract_code,
    source_m2_2_contract_version,
    source_m2_2_schema_version,
    source_m2_2_combined_hash,
    source_m2_2_acceptance_gate_id,
    final_offer_authorization_enabled_flag,
    decline_authorization_enabled_flag,
    manual_review_authorization_enabled_flag,
    synthetic_data_only_flag,
    no_booking_funding_flag,
    no_external_notice_generation_flag,
    no_production_adverse_action_notice_flag,
    expected_policy_rows,
    expected_outcome_rows,
    expected_reason_rows,
    expected_source_rows,
    expected_decision_snapshot_rows,
    expected_decision_latest_rows,
    expected_decision_archive_rows,
    expected_comparison_rows,
    expected_registry_rows,
    expected_canonical_entities,
    expected_positive_controls,
    expected_negative_controls,
    expected_detail_result_sets,
    configuration_payload,
    configuration_hash,
    row_hash
)
SELECT
    module1_run_id,
    policy_code,
    policy_version,
    policy_status,
    methodology_version,
    contract_code,
    contract_version,
    schema_version,
    source_m2_2_contract_code,
    source_m2_2_contract_version,
    source_m2_2_schema_version,
    source_m2_2_combined_hash,
    source_m2_2_acceptance_gate_id,
    final_offer_authorization_enabled_flag,
    decline_authorization_enabled_flag,
    manual_review_authorization_enabled_flag,
    synthetic_data_only_flag,
    no_booking_funding_flag,
    no_external_notice_generation_flag,
    no_production_adverse_action_notice_flag,
    expected_policy_rows,
    expected_outcome_rows,
    expected_reason_rows,
    expected_source_rows,
    expected_decision_snapshot_rows,
    expected_decision_latest_rows,
    expected_decision_archive_rows,
    expected_comparison_rows,
    expected_registry_rows,
    expected_canonical_entities,
    expected_positive_controls,
    expected_negative_controls,
    expected_detail_result_sets,
    configuration_payload,
    configuration_hash,
    row_hash
FROM policy_hashed
ON CONFLICT(module1_run_id)
DO NOTHING;

WITH run_context AS
(
    SELECT module1_run_id
    FROM msbf_ctl.m2_3_policy_profile
    WHERE policy_code = 'M2_3_FINAL_OFFER_DECISION_POLICY_V1'
)
INSERT INTO msbf_m2.final_decision_outcome_definition
(
    module1_run_id,
    decision_outcome_code,
    decision_outcome_rank,
    customer_offer_flag,
    decline_flag,
    manual_review_flag,
    production_adverse_action_notice_flag,
    booking_funding_flag,
    outcome_status,
    description,
    row_hash
)
SELECT
    run_context.module1_run_id,
    source.decision_outcome_code,
    source.decision_outcome_rank,
    source.customer_offer_flag,
    source.decline_flag,
    source.manual_review_flag,
    FALSE,
    FALSE,
    'APPROVED',
    source.description,
    msbf_ctl.m2_3_hash_jsonb(
        jsonb_build_object(
            'module1_run_id', run_context.module1_run_id,
            'decision_outcome_code', source.decision_outcome_code,
            'decision_outcome_rank', source.decision_outcome_rank,
            'customer_offer_flag', source.customer_offer_flag,
            'decline_flag', source.decline_flag,
            'manual_review_flag', source.manual_review_flag,
            'production_adverse_action_notice_flag', FALSE,
            'booking_funding_flag', FALSE,
            'outcome_status', 'APPROVED',
            'description', source.description
        )
    )
FROM run_context
CROSS JOIN
(
    VALUES
        ('FINAL_OFFER_AUTHORIZED', 1, TRUE, FALSE, FALSE, 'Structure is ready and a synthetic final offer is authorized for downstream presentation controls.'),
        ('COUNTEROFFER_REVIEW_REQUIRED', 2, FALSE, FALSE, TRUE, 'A counteroffer foundation exists, but manual decision authorization remains required.'),
        ('DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED', 3, FALSE, TRUE, FALSE, 'No final offer is authorized because governed evidence is insufficient.'),
        ('DECLINE_POLICY_AUTHORIZED', 4, FALSE, TRUE, FALSE, 'No final offer is authorized because governed policy constraints prohibit structure.'),
        ('NO_DECISION_SOURCE_BOUNDARY', 9, FALSE, FALSE, TRUE, 'Fallback guard state for unexpected upstream disposition; should not appear in accepted outputs.')
) AS source
(
    decision_outcome_code,
    decision_outcome_rank,
    customer_offer_flag,
    decline_flag,
    manual_review_flag,
    description
)
ON CONFLICT(module1_run_id,decision_outcome_code)
DO NOTHING;

WITH run_context AS
(
    SELECT module1_run_id
    FROM msbf_ctl.m2_3_policy_profile
    WHERE policy_code = 'M2_3_FINAL_OFFER_DECISION_POLICY_V1'
)
INSERT INTO msbf_m2.final_decision_reason_definition
(
    module1_run_id,
    decision_reason_code,
    mapped_decision_outcome_code,
    production_adverse_action_notice_flag,
    reason_status,
    description,
    row_hash
)
SELECT
    run_context.module1_run_id,
    reason.decision_reason_code,
    reason.mapped_decision_outcome_code,
    reason.production_adverse_action_notice_flag,
    'APPROVED',
    reason.description,
    msbf_ctl.m2_3_hash_jsonb(
        jsonb_build_object(
            'module1_run_id', run_context.module1_run_id,
            'decision_reason_code', reason.decision_reason_code,
            'mapped_decision_outcome_code', reason.mapped_decision_outcome_code,
            'production_adverse_action_notice_flag',
            reason.production_adverse_action_notice_flag,
            'reason_status', 'APPROVED',
            'description', reason.description
        )
    )
FROM run_context
CROSS JOIN
(
    VALUES
        ('M2_3_FINAL_OFFER_READY', 'FINAL_OFFER_AUTHORIZED', FALSE, 'Structure-ready record authorized for synthetic final offer.'),
        ('M2_3_COUNTEROFFER_REVIEW_REQUIRED', 'COUNTEROFFER_REVIEW_REQUIRED', FALSE, 'Counteroffer foundation requires manual authorization.'),
        ('M2_3_POLICY_DECLINE', 'DECLINE_POLICY_AUTHORIZED', FALSE, 'Policy decline from accepted M2.2 disposition.'),
        ('M2_3_INSUFFICIENT_EVIDENCE', 'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED', FALSE, 'Insufficient-evidence disposition from accepted M2.2.'),
        ('M2_3_NO_SELECTED_STRUCTURE', 'NO_DECISION_SOURCE_BOUNDARY', FALSE, 'No selected structure available.'),
        ('M2_3_FINAL_TERMS_PRESENT', 'FINAL_OFFER_AUTHORIZED', FALSE, 'Authorized offer terms are populated.'),
        ('M2_3_FINAL_TERMS_ABSENT_FOR_DECLINE', 'DECLINE_POLICY_AUTHORIZED', FALSE, 'Decline route carries no final offer terms.'),
        ('M2_3_FINAL_TERMS_ABSENT_FOR_REVIEW', 'COUNTEROFFER_REVIEW_REQUIRED', FALSE, 'Manual-review route carries no final offer terms.'),
        ('M2_3_STRESS_NONIMPROVEMENT', 'FINAL_OFFER_AUTHORIZED', FALSE, 'Stress final offer is not more favorable than matched baseline.'),
        ('M2_3_SOURCE_M2_2_ACCEPTED', 'FINAL_OFFER_AUTHORIZED', FALSE, 'Accepted M2.2 pricing structure contract was consumed.'),
        ('M2_3_SOURCE_M2_2_POLICY_DECLINE', 'DECLINE_POLICY_AUTHORIZED', FALSE, 'M2.2 supplied policy decline disposition.'),
        ('M2_3_SOURCE_M2_2_INSUFFICIENT', 'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED', FALSE, 'M2.2 supplied insufficient evidence disposition.'),
        ('M2_3_REVIEW_NOT_CUSTOMER_COUNTEROFFER', 'COUNTEROFFER_REVIEW_REQUIRED', FALSE, 'Counteroffer review is not an issued customer counteroffer.'),
        ('M2_3_SYNTHETIC_ONLY', 'FINAL_OFFER_AUTHORIZED', FALSE, 'Synthetic evidence only; no production submission.'),
        ('M2_3_NO_BOOKING', 'FINAL_OFFER_AUTHORIZED', FALSE, 'No booking or funding action is authorized.'),
        ('M2_3_NO_PRODUCTION_ADVERSE_ACTION', 'DECLINE_POLICY_AUTHORIZED', FALSE, 'Internal reason is not a production adverse-action notice.'),
        ('M2_3_ARCHIVE_REPRODUCED', 'FINAL_OFFER_AUTHORIZED', FALSE, 'Latest and immutable archive reproduce.'),
        ('M2_3_HASH_RECONCILED', 'FINAL_OFFER_AUTHORIZED', FALSE, 'Deterministic physical row hash reconciles.'),
        ('M2_3_POLICY_BOUNDARY', 'FINAL_OFFER_AUTHORIZED', FALSE, 'All final-decision policy boundary flags hold.'),
        ('M2_3_MATCHED_SCENARIO_GUARD', 'FINAL_OFFER_AUTHORIZED', FALSE, 'Matched baseline/stress final-offer comparison is governed.'),
        ('M2_3_NO_EXTERNAL_NOTICE', 'DECLINE_POLICY_AUTHORIZED', FALSE, 'No external notice was generated by this module.'),
        ('M2_3_FALLBACK_REVIEW', 'NO_DECISION_SOURCE_BOUNDARY', FALSE, 'Fallback review guard for unexpected upstream disposition.')
) AS reason
(
    decision_reason_code,
    mapped_decision_outcome_code,
    production_adverse_action_notice_flag,
    description
)
ON CONFLICT(module1_run_id,decision_reason_code)
DO NOTHING;

CREATE OR REPLACE VIEW msbf_m2.v_m2_3_final_decision_latest
AS
SELECT
    latest.module1_run_id,
    latest.contract_code,
    latest.contract_version,
    latest.schema_version,
    latest.methodology_version,
    latest.scenario_id,
    latest.scenario_code,
    latest.merchant_application_id,
    latest.population_id,
    latest.merchant_id,
    latest.as_of_date,
    latest.source_pricing_disposition_code,
    latest.final_decision_outcome_code,
    latest.final_decision_rank,
    latest.final_offer_authorized_flag,
    latest.counteroffer_review_required_flag,
    latest.decline_authorized_flag,
    latest.manual_review_required_flag,
    latest.final_offer_amount,
    latest.final_remittance_rate,
    latest.final_payback_multiple,
    latest.final_collection_horizon_days,
    latest.final_total_repayment_amount,
    latest.final_finance_charge_amount,
    latest.final_implied_daily_collection_amount,
    latest.final_implied_payoff_days,
    latest.final_offer_expiration_days,
    latest.final_authorization_evidence_status,
    latest.primary_decision_reason_code,
    latest.decision_reason_codes,
    latest.source_m2_2_contract_row_hash,
    latest.source_request_contract_row_hash,
    latest.source_g2_combined_hash,
    latest.source_snapshot_row_hash,
    latest.snapshot_row_hash,
    latest.policy_configuration_hash,
    latest.contract_row_hash,
    latest.created_at,
    outcome.customer_offer_flag,
    outcome.decline_flag,
    outcome.manual_review_flag,
    reason.description AS primary_reason_description
FROM msbf_m2.application_final_offer_decision_latest AS latest
JOIN msbf_m2.final_decision_outcome_definition AS outcome
  ON outcome.module1_run_id = latest.module1_run_id
 AND outcome.decision_outcome_code = latest.final_decision_outcome_code
JOIN msbf_m2.final_decision_reason_definition AS reason
  ON reason.module1_run_id = latest.module1_run_id
 AND reason.decision_reason_code = latest.primary_decision_reason_code;

CREATE OR REPLACE VIEW msbf_m2.v_m2_3_matched_scenario_comparison
AS
SELECT
    baseline.module1_run_id,
    baseline.merchant_application_id,
    baseline.final_decision_outcome_code
        AS baseline_decision_outcome_code,
    stress.final_decision_outcome_code
        AS stress_decision_outcome_code,
    baseline.final_decision_rank AS baseline_decision_rank,
    stress.final_decision_rank AS stress_decision_rank,
    baseline.final_offer_authorized_flag
        AS baseline_offer_authorized_flag,
    stress.final_offer_authorized_flag
        AS stress_offer_authorized_flag,
    baseline.final_offer_amount AS baseline_final_offer_amount,
    stress.final_offer_amount AS stress_final_offer_amount,
    baseline.final_remittance_rate AS baseline_final_remittance_rate,
    stress.final_remittance_rate AS stress_final_remittance_rate,
    baseline.final_payback_multiple AS baseline_final_payback_multiple,
    stress.final_payback_multiple AS stress_final_payback_multiple,
    baseline.final_collection_horizon_days
        AS baseline_final_collection_horizon_days,
    stress.final_collection_horizon_days
        AS stress_final_collection_horizon_days,
    (
        stress.final_decision_rank < baseline.final_decision_rank
    ) AS stress_decision_improvement_flag,
    (
        stress.final_offer_authorized_flag
        AND baseline.final_offer_authorized_flag
        AND
        (
            stress.final_offer_amount >
                baseline.final_offer_amount
            OR stress.final_remittance_rate <
                baseline.final_remittance_rate
            OR stress.final_payback_multiple <
                baseline.final_payback_multiple
            OR stress.final_collection_horizon_days <
                baseline.final_collection_horizon_days
        )
    ) AS stress_offer_term_improvement_flag
FROM msbf_m2.application_final_offer_decision_latest AS baseline
JOIN msbf_m2.application_final_offer_decision_latest AS stress
  ON stress.module1_run_id = baseline.module1_run_id
 AND stress.merchant_application_id = baseline.merchant_application_id
 AND stress.scenario_code = 'RECESSION_ENERGY'
WHERE baseline.scenario_code = 'BASELINE';

CREATE OR REPLACE VIEW msbf_m2.v_m2_3_power_bi_final_decision
AS
SELECT
    latest.module1_run_id,
    latest.scenario_code,
    latest.merchant_application_id,
    latest.source_pricing_disposition_code,
    latest.final_decision_outcome_code,
    latest.final_offer_authorized_flag,
    latest.counteroffer_review_required_flag,
    latest.decline_authorized_flag,
    latest.manual_review_required_flag,
    latest.final_offer_amount,
    latest.final_remittance_rate,
    latest.final_payback_multiple,
    latest.final_collection_horizon_days,
    latest.final_authorization_evidence_status,
    latest.primary_decision_reason_code
FROM msbf_m2.application_final_offer_decision_latest AS latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_3_final_decision_lineage
AS
SELECT
    latest.module1_run_id,
    latest.scenario_id,
    latest.scenario_code,
    latest.merchant_application_id,
    latest.contract_code,
    latest.contract_version,
    latest.schema_version,
    latest.final_decision_outcome_code,
    latest.source_m2_2_contract_row_hash,
    latest.source_request_contract_row_hash,
    latest.source_snapshot_row_hash,
    latest.snapshot_row_hash,
    latest.contract_row_hash
FROM msbf_m2.application_final_offer_decision_latest AS latest;

DO $m2_3_schema_guard$
DECLARE
    v_run_id bigint;
    v_gate_catalog bigint;
    v_policy bigint;
    v_outcomes bigint;
    v_reasons bigint;
BEGIN
    SELECT module1_run_id
    INTO v_run_id
    FROM msbf_ctl.m2_3_policy_profile
    WHERE policy_code = 'M2_3_FINAL_OFFER_DECISION_POLICY_V1';

    PERFORM msbf_ctl.m2_3_assert_configuration(v_run_id);

    SELECT count(*)
    INTO v_gate_catalog
    FROM msbf_ref.acceptance_gate_catalog
    WHERE gate_id = 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
      AND active_flag;

    SELECT count(*) INTO v_policy
    FROM msbf_ctl.m2_3_policy_profile
    WHERE module1_run_id = v_run_id;

    SELECT count(*) INTO v_outcomes
    FROM msbf_m2.final_decision_outcome_definition
    WHERE module1_run_id = v_run_id
      AND outcome_status = 'APPROVED';

    SELECT count(*) INTO v_reasons
    FROM msbf_m2.final_decision_reason_definition
    WHERE module1_run_id = v_run_id
      AND reason_status = 'APPROVED';

    IF v_gate_catalog <> 1
       OR v_policy <> 1
       OR v_outcomes <> 5
       OR v_reasons <> 22 THEN
        RAISE EXCEPTION
            'M2.3 schema/policy extension failed: gate catalog %, policy %, outcomes %, reasons %.',
            v_gate_catalog, v_policy, v_outcomes, v_reasons;
    END IF;
END;
$m2_3_schema_guard$;

COMMIT;

SELECT
    policy.module1_run_id,
    policy.policy_code,
    policy.policy_version,
    policy.policy_status,
    policy.methodology_version,
    policy.contract_code,
    policy.contract_version,
    policy.schema_version,
    policy.source_m2_2_contract_code,
    policy.source_m2_2_contract_version,
    policy.source_m2_2_schema_version,
    policy.source_m2_2_combined_hash,
    policy.configuration_hash,
    (
        SELECT count(*)
        FROM msbf_ref.acceptance_gate_catalog AS gate
        WHERE gate.gate_id = 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
          AND gate.active_flag
    ) AS acceptance_gate_catalog_rows,
    (
        SELECT count(*)
        FROM msbf_m2.final_decision_outcome_definition AS outcome
        WHERE outcome.module1_run_id = policy.module1_run_id
    ) AS outcome_definition_rows,
    (
        SELECT count(*)
        FROM msbf_m2.final_decision_reason_definition AS reason
        WHERE reason.module1_run_id = policy.module1_run_id
    ) AS reason_definition_rows,
    CASE
        WHEN policy.policy_status = 'APPROVED'
         AND policy.final_offer_authorization_enabled_flag
         AND policy.decline_authorization_enabled_flag
         AND policy.no_booking_funding_flag
         AND policy.no_external_notice_generation_flag
         AND policy.no_production_adverse_action_notice_flag
        THEN 'PASS'
        ELSE 'FAIL'
    END AS schema_policy_status
FROM msbf_ctl.m2_3_policy_profile AS policy
WHERE policy.policy_code = 'M2_3_FINAL_OFFER_DECISION_POLICY_V1';
