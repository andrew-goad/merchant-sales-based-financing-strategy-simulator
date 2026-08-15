/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.4 — Booking, Funding & Portfolio Activation

Program     : 156_msbf_m2_4_schema_policy_activation_contract_extension_v0_2.sql
Version     : v0.2
Purpose     : Establish governed M2.4 policy, activation outcome, operational
              reason and notice-control dictionaries; source, booking/funding,
              account, advance, portfolio and contract tables; deterministic
              hash utilities; lifecycle assertions; immutable archive controls;
              acceptance-gate registration; and consumption views.

Predecessor : Accepted M2.3 final-offer/decision contract.
Boundary    : All booking, funding, account and portfolio outputs are synthetic.
              No real funds movement, bank/settlement identifier, external
              notice transmission, or production adverse-action notice occurs.

Run mode    : Execute once after M2.3 acceptance and before Program 157.
============================================================================ */

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '25min';
SET LOCAL jit = off;

CREATE SCHEMA IF NOT EXISTS msbf_ctl;
CREATE SCHEMA IF NOT EXISTS msbf_m2;

/* --------------------------------------------------------------------------
Deterministic hash utilities
-------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_ctl.m2_4_hash_jsonb(p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $function$
    SELECT md5(p_payload::text);
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_4_registry_row_hash(p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $function$
    SELECT msbf_ctl.m2_4_hash_jsonb
    (
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

/* --------------------------------------------------------------------------
Control-plane policy and dictionaries
-------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_ctl.m2_4_policy_profile
(
    module1_run_id                                bigint PRIMARY KEY,
    policy_code                                   text NOT NULL,
    policy_version                                integer NOT NULL,
    policy_status                                 text NOT NULL,
    methodology_version                           text NOT NULL,
    contract_code                                 text NOT NULL,
    contract_version                              integer NOT NULL,
    schema_version                                text NOT NULL,
    source_m2_3_contract_code                     text NOT NULL,
    source_m2_3_contract_version                  integer NOT NULL,
    source_m2_3_schema_version                    text NOT NULL,
    source_m2_3_combined_hash                     text NOT NULL,
    source_m2_3_acceptance_gate_id                text NOT NULL,
    synthetic_booking_enabled_flag                boolean NOT NULL,
    synthetic_funding_enabled_flag                boolean NOT NULL,
    portfolio_activation_enabled_flag             boolean NOT NULL,
    synthetic_offer_acceptance_assumed_flag       boolean NOT NULL,
    real_funds_movement_prohibited_flag           boolean NOT NULL,
    external_notice_transmission_prohibited_flag  boolean NOT NULL,
    production_adverse_action_notice_prohibited_flag boolean NOT NULL,
    review_routes_not_bookable_flag               boolean NOT NULL,
    decline_routes_not_bookable_flag              boolean NOT NULL,
    duplicate_activation_prohibited_flag          boolean NOT NULL,
    source_decision_immutable_flag                boolean NOT NULL,
    stress_nonimprovement_required_flag           boolean NOT NULL,
    booking_lag_days                              integer NOT NULL,
    funding_lag_days                              integer NOT NULL,
    first_remittance_lag_days                     integer NOT NULL,
    monitoring_start_lag_days                     integer NOT NULL,
    expected_policy_rows                          bigint NOT NULL,
    expected_outcome_rows                         bigint NOT NULL,
    expected_reason_rows                          bigint NOT NULL,
    expected_notice_control_rows                  bigint NOT NULL,
    expected_source_rows                          bigint NOT NULL,
    expected_activation_snapshot_rows             bigint NOT NULL,
    expected_activation_latest_rows               bigint NOT NULL,
    expected_activation_archive_rows              bigint NOT NULL,
    expected_account_rows                         bigint NOT NULL,
    expected_advance_rows                         bigint NOT NULL,
    expected_portfolio_rows                       bigint NOT NULL,
    expected_comparison_rows                      bigint NOT NULL,
    expected_registry_rows                        bigint NOT NULL,
    expected_canonical_entities                   bigint NOT NULL,
    expected_positive_controls                    integer NOT NULL,
    expected_negative_controls                    integer NOT NULL,
    expected_detail_result_sets                   integer NOT NULL,
    configuration_payload                         jsonb NOT NULL,
    configuration_hash                            text NOT NULL,
    row_hash                                      text NOT NULL,
    created_at                                    timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at                                    timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT ck_m2_4_policy_identity CHECK
    (
        policy_code = 'M2_4_BOOKING_FUNDING_ACTIVATION_POLICY_V1'
        AND policy_version = 1
        AND methodology_version = 'M2_4_METHOD_V1'
        AND contract_code = 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
        AND contract_version = 1
        AND schema_version = 'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
    ),
    CONSTRAINT ck_m2_4_policy_status CHECK
    (
        policy_status IN ('APPROVED','RETIRED')
    ),
    CONSTRAINT ck_m2_4_policy_hashes CHECK
    (
        length(configuration_hash)=32
        AND configuration_hash ~ '^[0-9a-f]+$'
        AND length(row_hash)=32
        AND row_hash ~ '^[0-9a-f]+$'
    ),
    CONSTRAINT ck_m2_4_policy_boundaries CHECK
    (
        synthetic_booking_enabled_flag
        AND synthetic_funding_enabled_flag
        AND portfolio_activation_enabled_flag
        AND synthetic_offer_acceptance_assumed_flag
        AND real_funds_movement_prohibited_flag
        AND external_notice_transmission_prohibited_flag
        AND production_adverse_action_notice_prohibited_flag
        AND review_routes_not_bookable_flag
        AND decline_routes_not_bookable_flag
        AND duplicate_activation_prohibited_flag
        AND source_decision_immutable_flag
        AND stress_nonimprovement_required_flag
        AND booking_lag_days >= 0
        AND funding_lag_days >= booking_lag_days
        AND first_remittance_lag_days >= funding_lag_days
        AND monitoring_start_lag_days >= funding_lag_days
    )
);

COMMENT ON TABLE msbf_ctl.m2_4_policy_profile IS
'Governed M2.4 synthetic booking, funding and portfolio activation policy.';

CREATE TABLE IF NOT EXISTS msbf_m2.booking_funding_activation_outcome_definition
(
    module1_run_id                        bigint NOT NULL,
    activation_outcome_code               text NOT NULL,
    activation_outcome_rank               integer NOT NULL,
    booking_authorized_flag               boolean NOT NULL,
    funding_authorized_flag               boolean NOT NULL,
    portfolio_activated_flag              boolean NOT NULL,
    operational_review_required_flag      boolean NOT NULL,
    external_notice_transmission_flag     boolean NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    real_funds_movement_flag              boolean NOT NULL,
    outcome_status                        text NOT NULL,
    description                           text NOT NULL,
    row_hash                              text NOT NULL,
    created_at                            timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,activation_outcome_code),
    CONSTRAINT ck_m2_4_outcome_status CHECK
    (
        outcome_status IN ('APPROVED','RETIRED')
    ),
    CONSTRAINT ck_m2_4_outcome_boundaries CHECK
    (
        external_notice_transmission_flag IS FALSE
        AND production_adverse_action_notice_flag IS FALSE
        AND real_funds_movement_flag IS FALSE
        AND booking_authorized_flag = funding_authorized_flag
        AND funding_authorized_flag = portfolio_activated_flag
    )
);

COMMENT ON TABLE msbf_m2.booking_funding_activation_outcome_definition IS
'Governed M2.4 booking/funding/activation outcomes; all operational movement is synthetic.';

CREATE TABLE IF NOT EXISTS msbf_m2.booking_funding_reason_definition
(
    module1_run_id                        bigint NOT NULL,
    activation_reason_code               text NOT NULL,
    mapped_activation_outcome_code        text NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    reason_status                         text NOT NULL,
    description                           text NOT NULL,
    row_hash                              text NOT NULL,
    created_at                            timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,activation_reason_code),
    CONSTRAINT fk_m2_4_reason_outcome FOREIGN KEY
        (module1_run_id,mapped_activation_outcome_code)
        REFERENCES msbf_m2.booking_funding_activation_outcome_definition
        (module1_run_id,activation_outcome_code),
    CONSTRAINT ck_m2_4_reason_status CHECK
    (
        reason_status IN ('APPROVED','RETIRED')
    ),
    CONSTRAINT ck_m2_4_reason_boundary CHECK
    (
        production_adverse_action_notice_flag IS FALSE
    )
);

COMMENT ON TABLE msbf_m2.booking_funding_reason_definition IS
'Internal synthetic operational reasons; none are production adverse-action notices.';

CREATE TABLE IF NOT EXISTS msbf_m2.external_notice_control_definition
(
    module1_run_id                        bigint NOT NULL,
    notice_control_code                   text NOT NULL,
    notice_audience_code                  text NOT NULL,
    external_transmission_authorized_flag boolean NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    control_status                        text NOT NULL,
    description                           text NOT NULL,
    row_hash                              text NOT NULL,
    created_at                            timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,notice_control_code),
    CONSTRAINT ck_m2_4_notice_status CHECK
    (
        control_status IN ('APPROVED','RETIRED')
    ),
    CONSTRAINT ck_m2_4_notice_boundary CHECK
    (
        external_transmission_authorized_flag IS FALSE
        AND production_adverse_action_notice_flag IS FALSE
    )
);

COMMENT ON TABLE msbf_m2.external_notice_control_definition IS
'Internal-only M2.4 notice controls; no external transmission is authorized.';

/* --------------------------------------------------------------------------
Business, contract and activation objects
-------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_m2.application_booking_funding_source_snapshot
(
    module1_run_id                    bigint NOT NULL,
    scenario_id                       bigint NOT NULL,
    scenario_code                     text NOT NULL,
    merchant_application_id           text NOT NULL,
    population_id                     text NOT NULL,
    merchant_id                       text NOT NULL,
    as_of_date                        date NOT NULL,
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
    primary_decision_reason_code      text NOT NULL,
    source_m2_3_contract_row_hash     text NOT NULL,
    source_m2_2_contract_row_hash     text NOT NULL,
    source_g2_combined_hash           text NOT NULL,
    source_payload                    jsonb NOT NULL,
    row_hash                          text NOT NULL,
    created_at                        timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_4_source_scenario CHECK
    (
        scenario_code IN ('BASELINE','RECESSION_ENERGY')
    )
);

COMMENT ON TABLE msbf_m2.application_booking_funding_source_snapshot IS
'Immutable-in-practice M2.4 materialization of the accepted M2.3 latest decision contract.';

CREATE TABLE IF NOT EXISTS msbf_m2.application_booking_funding_activation_snapshot
(
    module1_run_id                      bigint NOT NULL,
    scenario_id                         bigint NOT NULL,
    scenario_code                       text NOT NULL,
    merchant_application_id             text NOT NULL,
    population_id                       text NOT NULL,
    merchant_id                         text NOT NULL,
    as_of_date                          date NOT NULL,
    source_final_decision_outcome_code   text NOT NULL,
    activation_outcome_code              text NOT NULL,
    activation_outcome_rank              integer NOT NULL,
    booking_eligible_flag                boolean NOT NULL,
    booking_authorized_flag              boolean NOT NULL,
    funding_authorized_flag              boolean NOT NULL,
    funding_completed_flag               boolean NOT NULL,
    portfolio_activated_flag             boolean NOT NULL,
    operational_review_required_flag     boolean NOT NULL,
    synthetic_offer_acceptance_assumed_flag boolean NOT NULL,
    real_funds_movement_flag             boolean NOT NULL,
    external_notice_generation_authorized_flag boolean NOT NULL,
    external_notice_transmitted_flag     boolean NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    synthetic_account_id                 text,
    synthetic_advance_id                 text,
    booked_amount                        numeric(18,2),
    funded_amount                        numeric(18,2),
    activation_remittance_rate           numeric(9,6),
    activation_payback_multiple          numeric(9,6),
    activation_collection_horizon_days   integer,
    activation_total_repayment_amount    numeric(18,2),
    activation_finance_charge_amount     numeric(18,2),
    activation_implied_daily_collection_amount numeric(18,2),
    activation_implied_payoff_days       numeric(18,4),
    booking_date                         date,
    funding_date                         date,
    portfolio_activation_date            date,
    first_expected_remittance_date       date,
    monitoring_start_date                date,
    activation_evidence_status           text NOT NULL,
    notice_control_code                  text NOT NULL,
    primary_activation_reason_code       text NOT NULL,
    activation_reason_codes              jsonb NOT NULL,
    source_m2_3_contract_row_hash        text NOT NULL,
    source_m2_2_contract_row_hash        text NOT NULL,
    source_g2_combined_hash              text NOT NULL,
    source_snapshot_row_hash             text NOT NULL,
    policy_configuration_hash            text NOT NULL,
    row_hash                             text NOT NULL,
    created_at                           timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT fk_m2_4_snapshot_outcome FOREIGN KEY
        (module1_run_id,activation_outcome_code)
        REFERENCES msbf_m2.booking_funding_activation_outcome_definition
        (module1_run_id,activation_outcome_code),
    CONSTRAINT fk_m2_4_snapshot_reason FOREIGN KEY
        (module1_run_id,primary_activation_reason_code)
        REFERENCES msbf_m2.booking_funding_reason_definition
        (module1_run_id,activation_reason_code),
    CONSTRAINT fk_m2_4_snapshot_notice FOREIGN KEY
        (module1_run_id,notice_control_code)
        REFERENCES msbf_m2.external_notice_control_definition
        (module1_run_id,notice_control_code),
    CONSTRAINT ck_m2_4_activation_status CHECK
    (
        activation_evidence_status IN
        ('ACTIVATED','REVIEW_REQUIRED','NOT_ACTIVATED','BLOCKED')
    ),
    CONSTRAINT ck_m2_4_activation_boundaries CHECK
    (
        real_funds_movement_flag IS FALSE
        AND external_notice_generation_authorized_flag IS FALSE
        AND external_notice_transmitted_flag IS FALSE
        AND production_adverse_action_notice_flag IS FALSE
        AND
        (
            (
                portfolio_activated_flag
                AND booking_eligible_flag
                AND booking_authorized_flag
                AND funding_authorized_flag
                AND funding_completed_flag
                AND synthetic_offer_acceptance_assumed_flag
                AND synthetic_account_id IS NOT NULL
                AND synthetic_advance_id IS NOT NULL
                AND booked_amount IS NOT NULL
                AND funded_amount IS NOT NULL
                AND activation_remittance_rate IS NOT NULL
                AND activation_payback_multiple IS NOT NULL
                AND activation_collection_horizon_days IS NOT NULL
                AND booking_date IS NOT NULL
                AND funding_date IS NOT NULL
                AND portfolio_activation_date IS NOT NULL
                AND first_expected_remittance_date IS NOT NULL
                AND monitoring_start_date IS NOT NULL
                AND operational_review_required_flag IS FALSE
            )
            OR
            (
                portfolio_activated_flag IS FALSE
                AND booking_eligible_flag IS FALSE
                AND booking_authorized_flag IS FALSE
                AND funding_authorized_flag IS FALSE
                AND funding_completed_flag IS FALSE
                AND synthetic_offer_acceptance_assumed_flag IS FALSE
                AND synthetic_account_id IS NULL
                AND synthetic_advance_id IS NULL
                AND booked_amount IS NULL
                AND funded_amount IS NULL
                AND activation_remittance_rate IS NULL
                AND activation_payback_multiple IS NULL
                AND activation_collection_horizon_days IS NULL
                AND booking_date IS NULL
                AND funding_date IS NULL
                AND portfolio_activation_date IS NULL
                AND first_expected_remittance_date IS NULL
                AND monitoring_start_date IS NULL
            )
        )
    )
);

COMMENT ON TABLE msbf_m2.application_booking_funding_activation_snapshot IS
'Application/scenario-level synthetic booking, funding and portfolio activation outcome.';

CREATE TABLE IF NOT EXISTS msbf_m2.application_booking_funding_activation_latest
(
    module1_run_id                      bigint NOT NULL,
    contract_code                       text NOT NULL,
    contract_version                    integer NOT NULL,
    schema_version                      text NOT NULL,
    methodology_version                 text NOT NULL,
    scenario_id                         bigint NOT NULL,
    scenario_code                       text NOT NULL,
    merchant_application_id             text NOT NULL,
    population_id                       text NOT NULL,
    merchant_id                         text NOT NULL,
    as_of_date                          date NOT NULL,
    source_final_decision_outcome_code   text NOT NULL,
    activation_outcome_code              text NOT NULL,
    activation_outcome_rank              integer NOT NULL,
    booking_eligible_flag                boolean NOT NULL,
    booking_authorized_flag              boolean NOT NULL,
    funding_authorized_flag              boolean NOT NULL,
    funding_completed_flag               boolean NOT NULL,
    portfolio_activated_flag             boolean NOT NULL,
    operational_review_required_flag     boolean NOT NULL,
    synthetic_offer_acceptance_assumed_flag boolean NOT NULL,
    real_funds_movement_flag             boolean NOT NULL,
    external_notice_generation_authorized_flag boolean NOT NULL,
    external_notice_transmitted_flag     boolean NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    synthetic_account_id                 text,
    synthetic_advance_id                 text,
    booked_amount                        numeric(18,2),
    funded_amount                        numeric(18,2),
    activation_remittance_rate           numeric(9,6),
    activation_payback_multiple          numeric(9,6),
    activation_collection_horizon_days   integer,
    activation_total_repayment_amount    numeric(18,2),
    activation_finance_charge_amount     numeric(18,2),
    activation_implied_daily_collection_amount numeric(18,2),
    activation_implied_payoff_days       numeric(18,4),
    booking_date                         date,
    funding_date                         date,
    portfolio_activation_date            date,
    first_expected_remittance_date       date,
    monitoring_start_date                date,
    activation_evidence_status           text NOT NULL,
    notice_control_code                  text NOT NULL,
    primary_activation_reason_code       text NOT NULL,
    activation_reason_codes              jsonb NOT NULL,
    source_m2_3_contract_row_hash        text NOT NULL,
    source_m2_2_contract_row_hash        text NOT NULL,
    source_g2_combined_hash              text NOT NULL,
    source_snapshot_row_hash             text NOT NULL,
    snapshot_row_hash                    text NOT NULL,
    policy_configuration_hash            text NOT NULL,
    contract_row_hash                    text NOT NULL,
    created_at                           timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_4_latest_identity CHECK
    (
        contract_code = 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
        AND contract_version = 1
        AND schema_version = 'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
        AND methodology_version = 'M2_4_METHOD_V1'
    )
);

COMMENT ON TABLE msbf_m2.application_booking_funding_activation_latest IS
'Latest governed M2.4 booking, funding and portfolio activation consumption contract.';

CREATE TABLE IF NOT EXISTS msbf_m2.application_booking_funding_activation_archive
(
    archive_id                          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id                      bigint NOT NULL,
    contract_code                       text NOT NULL,
    contract_version                    integer NOT NULL,
    schema_version                      text NOT NULL,
    methodology_version                 text NOT NULL,
    scenario_id                         bigint NOT NULL,
    scenario_code                       text NOT NULL,
    merchant_application_id             text NOT NULL,
    population_id                       text NOT NULL,
    merchant_id                         text NOT NULL,
    as_of_date                          date NOT NULL,
    source_final_decision_outcome_code   text NOT NULL,
    activation_outcome_code              text NOT NULL,
    activation_outcome_rank              integer NOT NULL,
    booking_eligible_flag                boolean NOT NULL,
    booking_authorized_flag              boolean NOT NULL,
    funding_authorized_flag              boolean NOT NULL,
    funding_completed_flag               boolean NOT NULL,
    portfolio_activated_flag             boolean NOT NULL,
    operational_review_required_flag     boolean NOT NULL,
    synthetic_offer_acceptance_assumed_flag boolean NOT NULL,
    real_funds_movement_flag             boolean NOT NULL,
    external_notice_generation_authorized_flag boolean NOT NULL,
    external_notice_transmitted_flag     boolean NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    synthetic_account_id                 text,
    synthetic_advance_id                 text,
    booked_amount                        numeric(18,2),
    funded_amount                        numeric(18,2),
    activation_remittance_rate           numeric(9,6),
    activation_payback_multiple          numeric(9,6),
    activation_collection_horizon_days   integer,
    activation_total_repayment_amount    numeric(18,2),
    activation_finance_charge_amount     numeric(18,2),
    activation_implied_daily_collection_amount numeric(18,2),
    activation_implied_payoff_days       numeric(18,4),
    booking_date                         date,
    funding_date                         date,
    portfolio_activation_date            date,
    first_expected_remittance_date       date,
    monitoring_start_date                date,
    activation_evidence_status           text NOT NULL,
    notice_control_code                  text NOT NULL,
    primary_activation_reason_code       text NOT NULL,
    activation_reason_codes              jsonb NOT NULL,
    source_m2_3_contract_row_hash        text NOT NULL,
    source_m2_2_contract_row_hash        text NOT NULL,
    source_g2_combined_hash              text NOT NULL,
    source_snapshot_row_hash             text NOT NULL,
    snapshot_row_hash                    text NOT NULL,
    policy_configuration_hash            text NOT NULL,
    contract_row_hash                    text NOT NULL,
    contract_payload                     jsonb NOT NULL,
    archive_row_hash                     text NOT NULL,
    archived_at                          timestamptz NOT NULL DEFAULT clock_timestamp(),
    created_at                           timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE(module1_run_id,contract_version,scenario_id,merchant_application_id),
    CONSTRAINT ck_m2_4_archive_identity CHECK
    (
        contract_code = 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
        AND contract_version = 1
        AND schema_version = 'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
        AND methodology_version = 'M2_4_METHOD_V1'
    )
);

COMMENT ON TABLE msbf_m2.application_booking_funding_activation_archive IS
'Immutable M2.4 activation archive, including exact latest-contract payload.';

CREATE TABLE IF NOT EXISTS msbf_m2.synthetic_account_activation
(
    module1_run_id                 bigint NOT NULL,
    scenario_id                    bigint NOT NULL,
    scenario_code                  text NOT NULL,
    merchant_application_id        text NOT NULL,
    synthetic_account_id           text NOT NULL,
    account_status                 text NOT NULL,
    account_open_date              date NOT NULL,
    source_activation_row_hash     text NOT NULL,
    row_hash                       text NOT NULL,
    created_at                     timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    UNIQUE(module1_run_id,synthetic_account_id),
    CONSTRAINT ck_m2_4_account_status CHECK(account_status='ACTIVE'),
    CONSTRAINT ck_m2_4_account_prefix CHECK(synthetic_account_id LIKE 'MSBF_ACCT_%')
);

COMMENT ON TABLE msbf_m2.synthetic_account_activation IS
'Synthetic account activation records for M2.4 activated offers.';

CREATE TABLE IF NOT EXISTS msbf_m2.synthetic_advance_funding
(
    module1_run_id                    bigint NOT NULL,
    scenario_id                       bigint NOT NULL,
    scenario_code                     text NOT NULL,
    merchant_application_id           text NOT NULL,
    synthetic_account_id              text NOT NULL,
    synthetic_advance_id              text NOT NULL,
    booked_amount                     numeric(18,2) NOT NULL,
    funded_amount                     numeric(18,2) NOT NULL,
    remittance_rate                   numeric(9,6) NOT NULL,
    payback_multiple                  numeric(9,6) NOT NULL,
    collection_horizon_days           integer NOT NULL,
    total_repayment_amount            numeric(18,2) NOT NULL,
    finance_charge_amount             numeric(18,2) NOT NULL,
    implied_daily_collection_amount   numeric(18,2) NOT NULL,
    implied_payoff_days               numeric(18,4) NOT NULL,
    funding_date                      date NOT NULL,
    first_expected_remittance_date    date NOT NULL,
    funding_status                    text NOT NULL,
    real_funds_movement_flag          boolean NOT NULL,
    source_activation_row_hash        text NOT NULL,
    row_hash                          text NOT NULL,
    created_at                        timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    UNIQUE(module1_run_id,synthetic_advance_id),
    CONSTRAINT ck_m2_4_advance_status CHECK(funding_status='SYNTHETIC_FUNDED'),
    CONSTRAINT ck_m2_4_advance_prefix CHECK(synthetic_advance_id LIKE 'MSBF_ADV_%'),
    CONSTRAINT ck_m2_4_no_real_funds CHECK(real_funds_movement_flag IS FALSE),
    CONSTRAINT ck_m2_4_advance_amounts CHECK
    (
        booked_amount > 0
        AND funded_amount = booked_amount
        AND remittance_rate BETWEEN 0.05 AND 0.20
        AND payback_multiple BETWEEN 1.05 AND 1.40
        AND collection_horizon_days BETWEEN 1 AND 120
    )
);

COMMENT ON TABLE msbf_m2.synthetic_advance_funding IS
'Synthetic funded-advance records; no real funds movement occurs.';

CREATE TABLE IF NOT EXISTS msbf_m2.initial_portfolio_activation
(
    module1_run_id                    bigint NOT NULL,
    scenario_id                       bigint NOT NULL,
    scenario_code                     text NOT NULL,
    merchant_application_id           text NOT NULL,
    synthetic_account_id              text NOT NULL,
    synthetic_advance_id              text NOT NULL,
    portfolio_status                  text NOT NULL,
    portfolio_activation_date         date NOT NULL,
    monitoring_start_date             date NOT NULL,
    original_funded_amount            numeric(18,2) NOT NULL,
    current_outstanding_balance_proxy numeric(18,2) NOT NULL,
    initial_exposure_amount           numeric(18,2) NOT NULL,
    initial_expected_collection_amount numeric(18,2) NOT NULL,
    source_advance_row_hash           text NOT NULL,
    row_hash                          text NOT NULL,
    created_at                        timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    UNIQUE(module1_run_id,synthetic_advance_id),
    CONSTRAINT ck_m2_4_portfolio_status CHECK(portfolio_status='ACTIVE'),
    CONSTRAINT ck_m2_4_portfolio_amounts CHECK
    (
        original_funded_amount > 0
        AND current_outstanding_balance_proxy = original_funded_amount
        AND initial_exposure_amount = original_funded_amount
        AND initial_expected_collection_amount >= original_funded_amount
    )
);

COMMENT ON TABLE msbf_m2.initial_portfolio_activation IS
'Initial synthetic portfolio positions created from activated advances.';

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_4_portfolio_activation_contract_registry
(
    registry_id                         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id                      bigint NOT NULL UNIQUE,
    contract_code                       text NOT NULL,
    contract_version                    integer NOT NULL,
    schema_version                      text NOT NULL,
    methodology_version                 text NOT NULL,
    source_m2_3_contract_code           text NOT NULL,
    source_m2_3_contract_version        integer NOT NULL,
    source_m2_3_schema_version          text NOT NULL,
    source_m2_3_combined_hash           text NOT NULL,
    source_m2_3_acceptance_gate_id      text NOT NULL,
    policy_configuration_hash           text NOT NULL,
    policy_rows                         bigint NOT NULL,
    outcome_rows                        bigint NOT NULL,
    reason_rows                         bigint NOT NULL,
    notice_control_rows                 bigint NOT NULL,
    source_rows                         bigint NOT NULL,
    activation_snapshot_rows            bigint NOT NULL,
    activation_latest_rows              bigint NOT NULL,
    activation_archive_rows             bigint NOT NULL,
    account_rows                        bigint NOT NULL,
    advance_rows                        bigint NOT NULL,
    portfolio_rows                      bigint NOT NULL,
    comparison_rows                     bigint NOT NULL,
    registry_rows                       bigint NOT NULL,
    canonical_entities                  bigint NOT NULL,
    activated_rows                      bigint NOT NULL,
    review_required_rows                bigint NOT NULL,
    not_activated_insufficient_rows      bigint NOT NULL,
    not_activated_policy_rows            bigint NOT NULL,
    policy_set_hash                     text NOT NULL,
    outcome_set_hash                    text NOT NULL,
    reason_set_hash                     text NOT NULL,
    notice_control_set_hash             text NOT NULL,
    source_set_hash                     text NOT NULL,
    activation_snapshot_set_hash        text NOT NULL,
    activation_latest_set_hash          text NOT NULL,
    activation_archive_set_hash         text NOT NULL,
    account_set_hash                    text NOT NULL,
    advance_set_hash                    text NOT NULL,
    portfolio_set_hash                  text NOT NULL,
    contract_set_hash                   text NOT NULL,
    combined_set_hash                   text NOT NULL,
    contract_status                     text NOT NULL,
    generated_at                        timestamptz,
    validated_at                        timestamptz,
    accepted_at                         timestamptz,
    row_hash                            text NOT NULL,
    created_at                          timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT ck_m2_4_registry_status CHECK
    (
        contract_status IN ('GENERATED','VALIDATED','ACCEPTED')
    ),
    CONSTRAINT ck_m2_4_registry_identity CHECK
    (
        contract_code = 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
        AND contract_version = 1
        AND schema_version = 'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
        AND methodology_version = 'M2_4_METHOD_V1'
    )
);

COMMENT ON TABLE msbf_ctl.m2_4_portfolio_activation_contract_registry IS
'M2.4 contract lifecycle, counts and deterministic set hashes.';

/* --------------------------------------------------------------------------
Immutable archive and supporting indexes
-------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_ctl.m2_4_archive_immutable()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    RAISE EXCEPTION
        'M2.4 portfolio activation archive is immutable; % is not permitted.',
        TG_OP;
END;
$function$;

DROP TRIGGER IF EXISTS trg_m2_4_activation_archive_immutable
ON msbf_m2.application_booking_funding_activation_archive;

CREATE TRIGGER trg_m2_4_activation_archive_immutable
BEFORE UPDATE OR DELETE
ON msbf_m2.application_booking_funding_activation_archive
FOR EACH ROW
EXECUTE FUNCTION msbf_ctl.m2_4_archive_immutable();

CREATE INDEX IF NOT EXISTS ix_m2_4_source_application
ON msbf_m2.application_booking_funding_source_snapshot
(module1_run_id,merchant_application_id,scenario_id);

CREATE INDEX IF NOT EXISTS ix_m2_4_activation_latest_outcome
ON msbf_m2.application_booking_funding_activation_latest
(module1_run_id,activation_outcome_code,scenario_code);

CREATE INDEX IF NOT EXISTS ix_m2_4_activation_archive_application
ON msbf_m2.application_booking_funding_activation_archive
(module1_run_id,merchant_application_id,scenario_id);

CREATE INDEX IF NOT EXISTS ix_m2_4_account_id
ON msbf_m2.synthetic_account_activation
(module1_run_id,synthetic_account_id);

CREATE INDEX IF NOT EXISTS ix_m2_4_advance_id
ON msbf_m2.synthetic_advance_funding
(module1_run_id,synthetic_advance_id);

/* --------------------------------------------------------------------------
Lifecycle assertions and prohibited real-world payload guard
-------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_ctl.m2_4_assert_configuration(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v record;
BEGIN
    SELECT
        module1_run_id,
        policy_code,
        policy_version,
        policy_status,
        methodology_version,
        contract_code,
        contract_version,
        schema_version,
        source_m2_3_contract_code,
        source_m2_3_contract_version,
        source_m2_3_schema_version,
        source_m2_3_combined_hash,
        source_m2_3_acceptance_gate_id,
        synthetic_booking_enabled_flag,
        synthetic_funding_enabled_flag,
        portfolio_activation_enabled_flag,
        synthetic_offer_acceptance_assumed_flag,
        real_funds_movement_prohibited_flag,
        external_notice_transmission_prohibited_flag,
        production_adverse_action_notice_prohibited_flag,
        review_routes_not_bookable_flag,
        decline_routes_not_bookable_flag,
        duplicate_activation_prohibited_flag,
        source_decision_immutable_flag,
        stress_nonimprovement_required_flag,
        booking_lag_days,
        funding_lag_days,
        first_remittance_lag_days,
        monitoring_start_lag_days,
        expected_policy_rows,
        expected_outcome_rows,
        expected_reason_rows,
        expected_notice_control_rows,
        expected_source_rows,
        expected_activation_snapshot_rows,
        expected_activation_latest_rows,
        expected_activation_archive_rows,
        expected_account_rows,
        expected_advance_rows,
        expected_portfolio_rows,
        expected_comparison_rows,
        expected_registry_rows,
        expected_canonical_entities,
        expected_positive_controls,
        expected_negative_controls,
        expected_detail_result_sets,
        configuration_payload,
        configuration_hash,
        row_hash,
        created_at,
        updated_at
    INTO v
    FROM msbf_ctl.m2_4_policy_profile
    WHERE module1_run_id = p_run_id;

    IF v.module1_run_id IS NULL
       OR v.policy_status <> 'APPROVED'
       OR v.policy_code <> 'M2_4_BOOKING_FUNDING_ACTIVATION_POLICY_V1'
       OR v.policy_version <> 1
       OR v.methodology_version <> 'M2_4_METHOD_V1'
       OR v.contract_code <> 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
       OR v.contract_version <> 1
       OR v.schema_version <> 'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
       OR v.source_m2_3_contract_code <> 'M2_FINAL_OFFER_DECISION_CONSUMPTION'
       OR v.source_m2_3_contract_version <> 1
       OR v.source_m2_3_schema_version <> 'M2_3_FINAL_DECISION_SCHEMA_V1'
       OR v.source_m2_3_combined_hash <> 'bf09349b06ede7e5a2ec830c2f9ffe90'
       OR v.source_m2_3_acceptance_gate_id <> 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
       OR v.synthetic_booking_enabled_flag IS DISTINCT FROM TRUE
       OR v.synthetic_funding_enabled_flag IS DISTINCT FROM TRUE
       OR v.portfolio_activation_enabled_flag IS DISTINCT FROM TRUE
       OR v.synthetic_offer_acceptance_assumed_flag IS DISTINCT FROM TRUE
       OR v.real_funds_movement_prohibited_flag IS DISTINCT FROM TRUE
       OR v.external_notice_transmission_prohibited_flag IS DISTINCT FROM TRUE
       OR v.production_adverse_action_notice_prohibited_flag IS DISTINCT FROM TRUE
       OR v.review_routes_not_bookable_flag IS DISTINCT FROM TRUE
       OR v.decline_routes_not_bookable_flag IS DISTINCT FROM TRUE
       OR v.duplicate_activation_prohibited_flag IS DISTINCT FROM TRUE
       OR v.source_decision_immutable_flag IS DISTINCT FROM TRUE
       OR v.stress_nonimprovement_required_flag IS DISTINCT FROM TRUE
       OR v.configuration_payload->>'methodology' IS DISTINCT FROM
            v.methodology_version
       OR v.configuration_payload->>'policy_code' IS DISTINCT FROM
            v.policy_code
       OR v.configuration_payload->>'contract_code' IS DISTINCT FROM
            v.contract_code
       OR (v.configuration_payload->>'contract_version')::integer
            IS DISTINCT FROM v.contract_version
       OR v.configuration_payload->>'schema_version' IS DISTINCT FROM
            v.schema_version
       OR v.configuration_payload->>'source_contract_code' IS DISTINCT FROM
            v.source_m2_3_contract_code
       OR (v.configuration_payload->>'source_contract_version')::integer
            IS DISTINCT FROM v.source_m2_3_contract_version
       OR v.configuration_payload->>'source_schema_version' IS DISTINCT FROM
            v.source_m2_3_schema_version
       OR v.configuration_payload->>'source_combined_hash' IS DISTINCT FROM
            v.source_m2_3_combined_hash
       OR v.configuration_payload->>'source_acceptance_gate' IS DISTINCT FROM
            v.source_m2_3_acceptance_gate_id
       OR (v.configuration_payload->>'synthetic_booking_enabled')::boolean
            IS DISTINCT FROM v.synthetic_booking_enabled_flag
       OR (v.configuration_payload->>'synthetic_funding_enabled')::boolean
            IS DISTINCT FROM v.synthetic_funding_enabled_flag
       OR (v.configuration_payload->>'portfolio_activation_enabled')::boolean
            IS DISTINCT FROM v.portfolio_activation_enabled_flag
       OR (v.configuration_payload->>'synthetic_offer_acceptance_assumed')::boolean
            IS DISTINCT FROM v.synthetic_offer_acceptance_assumed_flag
       OR (v.configuration_payload->>'real_funds_movement_prohibited')::boolean
            IS DISTINCT FROM v.real_funds_movement_prohibited_flag
       OR (v.configuration_payload->>'external_notice_transmission_prohibited')::boolean
            IS DISTINCT FROM v.external_notice_transmission_prohibited_flag
       OR (v.configuration_payload->>'production_adverse_action_notice_prohibited')::boolean
            IS DISTINCT FROM v.production_adverse_action_notice_prohibited_flag
       OR (v.configuration_payload->>'review_routes_not_bookable')::boolean
            IS DISTINCT FROM v.review_routes_not_bookable_flag
       OR (v.configuration_payload->>'decline_routes_not_bookable')::boolean
            IS DISTINCT FROM v.decline_routes_not_bookable_flag
       OR (v.configuration_payload->>'duplicate_activation_prohibited')::boolean
            IS DISTINCT FROM v.duplicate_activation_prohibited_flag
       OR (v.configuration_payload->>'source_decision_immutable')::boolean
            IS DISTINCT FROM v.source_decision_immutable_flag
       OR (v.configuration_payload->>'stress_nonimprovement_required')::boolean
            IS DISTINCT FROM v.stress_nonimprovement_required_flag
       OR (v.configuration_payload->>'booking_lag_days')::integer
            IS DISTINCT FROM v.booking_lag_days
       OR (v.configuration_payload->>'funding_lag_days')::integer
            IS DISTINCT FROM v.funding_lag_days
       OR (v.configuration_payload->>'first_remittance_lag_days')::integer
            IS DISTINCT FROM v.first_remittance_lag_days
       OR (v.configuration_payload->>'monitoring_start_lag_days')::integer
            IS DISTINCT FROM v.monitoring_start_lag_days
       OR v.expected_policy_rows <> 1
       OR v.expected_outcome_rows <> 5
       OR v.expected_reason_rows <> 24
       OR v.expected_notice_control_rows <> 4
       OR v.expected_source_rows <> 1500
       OR v.expected_activation_snapshot_rows <> 1500
       OR v.expected_activation_latest_rows <> 1500
       OR v.expected_activation_archive_rows <> 1500
       OR v.expected_account_rows <> 59
       OR v.expected_advance_rows <> 59
       OR v.expected_portfolio_rows <> 59
       OR v.expected_comparison_rows <> 750
       OR v.expected_registry_rows <> 1
       OR v.expected_canonical_entities <> 6212
       OR v.expected_positive_controls <> 120
       OR v.expected_negative_controls <> 20
       OR (v.configuration_payload->'expected'->>'policy_rows')::bigint
            IS DISTINCT FROM v.expected_policy_rows
       OR (v.configuration_payload->'expected'->>'outcome_rows')::bigint
            IS DISTINCT FROM v.expected_outcome_rows
       OR (v.configuration_payload->'expected'->>'reason_rows')::bigint
            IS DISTINCT FROM v.expected_reason_rows
       OR (v.configuration_payload->'expected'->>'notice_control_rows')::bigint
            IS DISTINCT FROM v.expected_notice_control_rows
       OR (v.configuration_payload->'expected'->>'source_rows')::bigint
            IS DISTINCT FROM v.expected_source_rows
       OR (v.configuration_payload->'expected'->>'activation_snapshot_rows')::bigint
            IS DISTINCT FROM v.expected_activation_snapshot_rows
       OR (v.configuration_payload->'expected'->>'activation_latest_rows')::bigint
            IS DISTINCT FROM v.expected_activation_latest_rows
       OR (v.configuration_payload->'expected'->>'activation_archive_rows')::bigint
            IS DISTINCT FROM v.expected_activation_archive_rows
       OR (v.configuration_payload->'expected'->>'account_rows')::bigint
            IS DISTINCT FROM v.expected_account_rows
       OR (v.configuration_payload->'expected'->>'advance_rows')::bigint
            IS DISTINCT FROM v.expected_advance_rows
       OR (v.configuration_payload->'expected'->>'portfolio_rows')::bigint
            IS DISTINCT FROM v.expected_portfolio_rows
       OR (v.configuration_payload->'expected'->>'comparison_rows')::bigint
            IS DISTINCT FROM v.expected_comparison_rows
       OR (v.configuration_payload->'expected'->>'registry_rows')::bigint
            IS DISTINCT FROM v.expected_registry_rows
       OR (v.configuration_payload->'expected'->>'canonical_entities')::bigint
            IS DISTINCT FROM v.expected_canonical_entities
       OR (v.configuration_payload->'expected'->>'positive_controls')::integer
            IS DISTINCT FROM v.expected_positive_controls
       OR (v.configuration_payload->'expected'->>'negative_controls')::integer
            IS DISTINCT FROM v.expected_negative_controls
       OR (v.configuration_payload->'expected'->>'detail_result_sets')::integer
            IS DISTINCT FROM v.expected_detail_result_sets
       OR (v.configuration_payload->'expected'->>'generation_evidence_rows')::integer
            IS DISTINCT FROM 24
       OR (v.configuration_payload->'expected'->>'activated_rows')::bigint
            IS DISTINCT FROM 59
       OR (v.configuration_payload->'expected'->>'review_required_rows')::bigint
            IS DISTINCT FROM 190
       OR (v.configuration_payload->'expected'->>'not_activated_insufficient_rows')::bigint
            IS DISTINCT FROM 178
       OR (v.configuration_payload->'expected'->>'not_activated_policy_rows')::bigint
            IS DISTINCT FROM 1073
       OR v.configuration_hash IS DISTINCT FROM
            msbf_ctl.m2_4_hash_jsonb(v.configuration_payload)
       OR v.row_hash IS DISTINCT FROM
            msbf_ctl.m2_4_hash_jsonb
            (
                to_jsonb(v)
                - 'row_hash'
                - 'created_at'
                - 'updated_at'
            ) THEN
        RAISE EXCEPTION
            'M2.4 configuration assertion failed for run_id %.',
            p_run_id;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_4_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_status text;
    v_gate_catalog_rows bigint;
BEGIN
    PERFORM msbf_ctl.m2_4_assert_configuration(p_run_id);

    SELECT run_status
    INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    SELECT count(*)
    INTO v_gate_catalog_rows
    FROM msbf_ref.acceptance_gate_catalog
    WHERE gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
      AND active_flag;

    IF v_run_status <> 'M2_3_ACCEPTED'
       OR v_gate_catalog_rows <> 1 THEN
        RAISE EXCEPTION
            'M2.4 generation requires M2_3_ACCEPTED and one active gate catalog row; run %, gate rows %.',
            v_run_status, v_gate_catalog_rows;
    END IF;

    IF EXISTS
    (
        SELECT 1 FROM msbf_m2.application_booking_funding_source_snapshot
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.application_booking_funding_activation_snapshot
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.application_booking_funding_activation_latest
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.application_booking_funding_activation_archive
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.synthetic_account_activation
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.synthetic_advance_funding
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_m2.initial_portfolio_activation
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
        WHERE module1_run_id = p_run_id
        UNION ALL
        SELECT 1 FROM msbf_ctl.run_evidence
        WHERE run_id = p_run_id
          AND evidence_code LIKE 'M2_4_%'
        UNION ALL
        SELECT 1 FROM msbf_ctl.acceptance_gate_result
        WHERE run_id = p_run_id
          AND gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
    ) THEN
        RAISE EXCEPTION
            'M2.4 generation requires empty M2.4 targets for run_id %.',
            p_run_id;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_4_assert_validation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_status text;
    v_contract_status text;
BEGIN
    PERFORM msbf_ctl.m2_4_assert_configuration(p_run_id);

    SELECT run_status
    INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    SELECT contract_status
    INTO v_contract_status
    FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
    WHERE module1_run_id = p_run_id;

    IF v_run_status NOT IN ('M2_4_GENERATED','M2_4_VALIDATED')
       OR v_contract_status NOT IN ('GENERATED','VALIDATED') THEN
        RAISE EXCEPTION
            'M2.4 validation requires generated or validated state; run %, contract %.',
            v_run_status, v_contract_status;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_4_assert_acceptance_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_status text;
    v_contract_status text;
    v_positive_passes bigint;
    v_negative_passes bigint;
BEGIN
    PERFORM msbf_ctl.m2_4_assert_configuration(p_run_id);

    SELECT run_status
    INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    SELECT contract_status
    INTO v_contract_status
    FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
    WHERE module1_run_id = p_run_id;

    SELECT
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_4_POS_%'
              AND status = 'PASS'
        ),
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_4_NEG_%'
              AND status = 'PASS'
        )
    INTO v_positive_passes, v_negative_passes
    FROM msbf_ctl.run_evidence
    WHERE run_id = p_run_id;

    IF v_run_status <> 'M2_4_VALIDATED'
       OR v_contract_status <> 'VALIDATED'
       OR v_positive_passes <> 120
       OR v_negative_passes <> 20 THEN
        RAISE EXCEPTION
            'M2.4 acceptance not ready: run %, contract %, positive %, negative %.',
            v_run_status,
            v_contract_status,
            v_positive_passes,
            v_negative_passes;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_4_assert_no_real_world_payload(p_payload jsonb)
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
        'ach_trace_number',
        'bank_account_number',
        'settlement_account_number',
        'routing_number',
        'core_booking_id',
        'real_account_number',
        'real_funds_movement',
        'external_notice_payload',
        'external_notice_transmitted',
        'production_adverse_action_notice'
    )
    LIMIT 1;

    IF v_key IS NOT NULL THEN
        RAISE EXCEPTION
            'M2.4 boundary rejected prohibited real-world payload key %.',
            v_key;
    END IF;
END;
$function$;

/* --------------------------------------------------------------------------
Acceptance gate registration — required before preflight and finalization
-------------------------------------------------------------------------- */
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
    'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION',
    'M2.4 Booking, Funding & Portfolio Activation',
    'M2.4',
    'BLOCKING',
    TRUE,
    'Accepts synthetic booking, funding and portfolio activation; no real funds movement, external notice transmission, or production adverse-action notice.'
)
ON CONFLICT(gate_id)
DO UPDATE SET
    gate_name = EXCLUDED.gate_name,
    module_code = EXCLUDED.module_code,
    severity = EXCLUDED.severity,
    active_flag = EXCLUDED.active_flag,
    description = EXCLUDED.description;

/* --------------------------------------------------------------------------
Target-typed policy and definition seeds — hash before persistent insert
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_4_policy_seed;

CREATE TEMP TABLE _m2_4_policy_seed
(
    module1_run_id                                bigint NOT NULL,
    policy_code                                   text NOT NULL,
    policy_version                                integer NOT NULL,
    policy_status                                 text NOT NULL,
    methodology_version                           text NOT NULL,
    contract_code                                 text NOT NULL,
    contract_version                              integer NOT NULL,
    schema_version                                text NOT NULL,
    source_m2_3_contract_code                     text NOT NULL,
    source_m2_3_contract_version                  integer NOT NULL,
    source_m2_3_schema_version                    text NOT NULL,
    source_m2_3_combined_hash                     text NOT NULL,
    source_m2_3_acceptance_gate_id                text NOT NULL,
    synthetic_booking_enabled_flag                boolean NOT NULL,
    synthetic_funding_enabled_flag                boolean NOT NULL,
    portfolio_activation_enabled_flag             boolean NOT NULL,
    synthetic_offer_acceptance_assumed_flag       boolean NOT NULL,
    real_funds_movement_prohibited_flag           boolean NOT NULL,
    external_notice_transmission_prohibited_flag  boolean NOT NULL,
    production_adverse_action_notice_prohibited_flag boolean NOT NULL,
    review_routes_not_bookable_flag               boolean NOT NULL,
    decline_routes_not_bookable_flag              boolean NOT NULL,
    duplicate_activation_prohibited_flag          boolean NOT NULL,
    source_decision_immutable_flag                boolean NOT NULL,
    stress_nonimprovement_required_flag           boolean NOT NULL,
    booking_lag_days                              integer NOT NULL,
    funding_lag_days                              integer NOT NULL,
    first_remittance_lag_days                     integer NOT NULL,
    monitoring_start_lag_days                     integer NOT NULL,
    expected_policy_rows                          bigint NOT NULL,
    expected_outcome_rows                         bigint NOT NULL,
    expected_reason_rows                          bigint NOT NULL,
    expected_notice_control_rows                  bigint NOT NULL,
    expected_source_rows                          bigint NOT NULL,
    expected_activation_snapshot_rows             bigint NOT NULL,
    expected_activation_latest_rows               bigint NOT NULL,
    expected_activation_archive_rows              bigint NOT NULL,
    expected_account_rows                         bigint NOT NULL,
    expected_advance_rows                         bigint NOT NULL,
    expected_portfolio_rows                       bigint NOT NULL,
    expected_comparison_rows                      bigint NOT NULL,
    expected_registry_rows                        bigint NOT NULL,
    expected_canonical_entities                   bigint NOT NULL,
    expected_positive_controls                    integer NOT NULL,
    expected_negative_controls                    integer NOT NULL,
    expected_detail_result_sets                   integer NOT NULL,
    configuration_payload                         jsonb NOT NULL,
    configuration_hash                            text NOT NULL,
    row_hash                                      text
)
ON COMMIT DROP;

INSERT INTO _m2_4_policy_seed
SELECT
    registry.module1_run_id,
    'M2_4_BOOKING_FUNDING_ACTIVATION_POLICY_V1',
    1,
    'APPROVED',
    'M2_4_METHOD_V1',
    'M2_PORTFOLIO_ACTIVATION_CONSUMPTION',
    1,
    'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1',
    'M2_FINAL_OFFER_DECISION_CONSUMPTION',
    1,
    'M2_3_FINAL_DECISION_SCHEMA_V1',
    'bf09349b06ede7e5a2ec830c2f9ffe90',
    'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION',
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    1,
    2,
    3,
    2,
    1,
    5,
    24,
    4,
    1500,
    1500,
    1500,
    1500,
    59,
    59,
    59,
    750,
    1,
    6212,
    120,
    20,
    24,
    '{"booking_lag_days":1,"contract_code":"M2_PORTFOLIO_ACTIVATION_CONSUMPTION","contract_version":1,"decline_routes_not_bookable":true,"duplicate_activation_prohibited":true,"expected":{"account_rows":59,"activated_rows":59,"activation_archive_rows":1500,"activation_latest_rows":1500,"activation_snapshot_rows":1500,"advance_rows":59,"canonical_entities":6212,"comparison_rows":750,"detail_result_sets":24,"generation_evidence_rows":24,"negative_controls":20,"not_activated_insufficient_rows":178,"not_activated_policy_rows":1073,"notice_control_rows":4,"outcome_rows":5,"policy_rows":1,"portfolio_rows":59,"positive_controls":120,"reason_rows":24,"registry_rows":1,"review_required_rows":190,"source_rows":1500},"external_notice_transmission_prohibited":true,"first_remittance_lag_days":3,"funding_lag_days":2,"methodology":"M2_4_METHOD_V1","monitoring_start_lag_days":2,"policy_code":"M2_4_BOOKING_FUNDING_ACTIVATION_POLICY_V1","portfolio_activation_enabled":true,"production_adverse_action_notice_prohibited":true,"real_funds_movement_prohibited":true,"review_routes_not_bookable":true,"schema_version":"M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1","source_acceptance_gate":"M2_3_FINAL_OFFER_DECISION_AUTHORIZATION","source_combined_hash":"bf09349b06ede7e5a2ec830c2f9ffe90","source_contract_code":"M2_FINAL_OFFER_DECISION_CONSUMPTION","source_contract_version":1,"source_decision_immutable":true,"source_schema_version":"M2_3_FINAL_DECISION_SCHEMA_V1","stress_nonimprovement_required":true,"synthetic_booking_enabled":true,"synthetic_funding_enabled":true,"synthetic_offer_acceptance_assumed":true}'::jsonb,
    msbf_ctl.m2_4_hash_jsonb('{"booking_lag_days":1,"contract_code":"M2_PORTFOLIO_ACTIVATION_CONSUMPTION","contract_version":1,"decline_routes_not_bookable":true,"duplicate_activation_prohibited":true,"expected":{"account_rows":59,"activated_rows":59,"activation_archive_rows":1500,"activation_latest_rows":1500,"activation_snapshot_rows":1500,"advance_rows":59,"canonical_entities":6212,"comparison_rows":750,"detail_result_sets":24,"generation_evidence_rows":24,"negative_controls":20,"not_activated_insufficient_rows":178,"not_activated_policy_rows":1073,"notice_control_rows":4,"outcome_rows":5,"policy_rows":1,"portfolio_rows":59,"positive_controls":120,"reason_rows":24,"registry_rows":1,"review_required_rows":190,"source_rows":1500},"external_notice_transmission_prohibited":true,"first_remittance_lag_days":3,"funding_lag_days":2,"methodology":"M2_4_METHOD_V1","monitoring_start_lag_days":2,"policy_code":"M2_4_BOOKING_FUNDING_ACTIVATION_POLICY_V1","portfolio_activation_enabled":true,"production_adverse_action_notice_prohibited":true,"real_funds_movement_prohibited":true,"review_routes_not_bookable":true,"schema_version":"M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1","source_acceptance_gate":"M2_3_FINAL_OFFER_DECISION_AUTHORIZATION","source_combined_hash":"bf09349b06ede7e5a2ec830c2f9ffe90","source_contract_code":"M2_FINAL_OFFER_DECISION_CONSUMPTION","source_contract_version":1,"source_decision_immutable":true,"source_schema_version":"M2_3_FINAL_DECISION_SCHEMA_V1","stress_nonimprovement_required":true,"synthetic_booking_enabled":true,"synthetic_funding_enabled":true,"synthetic_offer_acceptance_assumed":true}'::jsonb),
    NULL::text
FROM msbf_ctl.m2_3_final_decision_contract_registry AS registry
JOIN msbf_ctl.run_registry AS run
  ON run.run_id = registry.module1_run_id
WHERE run.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND run.run_version = 1
  AND run.run_status = 'M2_3_ACCEPTED'
  AND registry.contract_status = 'ACCEPTED'
  AND registry.contract_code = 'M2_FINAL_OFFER_DECISION_CONSUMPTION'
  AND registry.contract_version = 1
  AND registry.schema_version = 'M2_3_FINAL_DECISION_SCHEMA_V1'
  AND registry.combined_set_hash = 'bf09349b06ede7e5a2ec830c2f9ffe90';

UPDATE _m2_4_policy_seed AS policy
SET row_hash = msbf_ctl.m2_4_hash_jsonb
(
    to_jsonb(policy) - 'row_hash'
)
WHERE policy.row_hash IS NULL;

INSERT INTO msbf_ctl.m2_4_policy_profile
(
    module1_run_id,
    policy_code,
    policy_version,
    policy_status,
    methodology_version,
    contract_code,
    contract_version,
    schema_version,
    source_m2_3_contract_code,
    source_m2_3_contract_version,
    source_m2_3_schema_version,
    source_m2_3_combined_hash,
    source_m2_3_acceptance_gate_id,
    synthetic_booking_enabled_flag,
    synthetic_funding_enabled_flag,
    portfolio_activation_enabled_flag,
    synthetic_offer_acceptance_assumed_flag,
    real_funds_movement_prohibited_flag,
    external_notice_transmission_prohibited_flag,
    production_adverse_action_notice_prohibited_flag,
    review_routes_not_bookable_flag,
    decline_routes_not_bookable_flag,
    duplicate_activation_prohibited_flag,
    source_decision_immutable_flag,
    stress_nonimprovement_required_flag,
    booking_lag_days,
    funding_lag_days,
    first_remittance_lag_days,
    monitoring_start_lag_days,
    expected_policy_rows,
    expected_outcome_rows,
    expected_reason_rows,
    expected_notice_control_rows,
    expected_source_rows,
    expected_activation_snapshot_rows,
    expected_activation_latest_rows,
    expected_activation_archive_rows,
    expected_account_rows,
    expected_advance_rows,
    expected_portfolio_rows,
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
    source_m2_3_contract_code,
    source_m2_3_contract_version,
    source_m2_3_schema_version,
    source_m2_3_combined_hash,
    source_m2_3_acceptance_gate_id,
    synthetic_booking_enabled_flag,
    synthetic_funding_enabled_flag,
    portfolio_activation_enabled_flag,
    synthetic_offer_acceptance_assumed_flag,
    real_funds_movement_prohibited_flag,
    external_notice_transmission_prohibited_flag,
    production_adverse_action_notice_prohibited_flag,
    review_routes_not_bookable_flag,
    decline_routes_not_bookable_flag,
    duplicate_activation_prohibited_flag,
    source_decision_immutable_flag,
    stress_nonimprovement_required_flag,
    booking_lag_days,
    funding_lag_days,
    first_remittance_lag_days,
    monitoring_start_lag_days,
    expected_policy_rows,
    expected_outcome_rows,
    expected_reason_rows,
    expected_notice_control_rows,
    expected_source_rows,
    expected_activation_snapshot_rows,
    expected_activation_latest_rows,
    expected_activation_archive_rows,
    expected_account_rows,
    expected_advance_rows,
    expected_portfolio_rows,
    expected_comparison_rows,
    expected_registry_rows,
    expected_canonical_entities,
    expected_positive_controls,
    expected_negative_controls,
    expected_detail_result_sets,
    configuration_payload,
    configuration_hash,
    row_hash
FROM _m2_4_policy_seed
ON CONFLICT(module1_run_id)
DO NOTHING;

DROP TABLE IF EXISTS _m2_4_outcome_seed;

CREATE TEMP TABLE _m2_4_outcome_seed
(
    module1_run_id                        bigint NOT NULL,
    activation_outcome_code               text NOT NULL,
    activation_outcome_rank               integer NOT NULL,
    booking_authorized_flag               boolean NOT NULL,
    funding_authorized_flag               boolean NOT NULL,
    portfolio_activated_flag              boolean NOT NULL,
    operational_review_required_flag      boolean NOT NULL,
    external_notice_transmission_flag     boolean NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    real_funds_movement_flag              boolean NOT NULL,
    outcome_status                        text NOT NULL,
    description                           text NOT NULL,
    row_hash                              text
)
ON COMMIT DROP;

INSERT INTO _m2_4_outcome_seed
SELECT
    policy.module1_run_id,
    source.activation_outcome_code,
    source.activation_outcome_rank,
    source.booking_authorized_flag,
    source.funding_authorized_flag,
    source.portfolio_activated_flag,
    source.operational_review_required_flag,
    FALSE,
    FALSE,
    FALSE,
    'APPROVED',
    source.description,
    NULL::text
FROM msbf_ctl.m2_4_policy_profile AS policy
CROSS JOIN
(
    VALUES
        ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED', 1, TRUE, TRUE, TRUE, FALSE, 'Synthetic account, advance, funding and initial portfolio activation are authorized from an accepted final offer.'),
        ('ACTIVATION_REVIEW_REQUIRED', 2, FALSE, FALSE, FALSE, TRUE, 'Counteroffer review remains unresolved; booking, funding and activation are not authorized.'),
        ('NOT_ACTIVATED_INSUFFICIENT_EVIDENCE', 3, FALSE, FALSE, FALSE, FALSE, 'No activation is authorized because the accepted M2.3 outcome reflects insufficient evidence.'),
        ('NOT_ACTIVATED_POLICY_DECLINE', 4, FALSE, FALSE, FALSE, FALSE, 'No activation is authorized because the accepted M2.3 outcome reflects a policy decline.'),
        ('NO_ACTIVATION_SOURCE_BOUNDARY', 9, FALSE, FALSE, FALSE, TRUE, 'Fallback fail-closed activation state for an unexpected upstream decision outcome.')
) AS source
(
    activation_outcome_code,
    activation_outcome_rank,
    booking_authorized_flag,
    funding_authorized_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    description
)
WHERE policy.policy_code = 'M2_4_BOOKING_FUNDING_ACTIVATION_POLICY_V1';

UPDATE _m2_4_outcome_seed AS outcome
SET row_hash = msbf_ctl.m2_4_hash_jsonb
(
    to_jsonb(outcome) - 'row_hash'
)
WHERE outcome.row_hash IS NULL;

INSERT INTO msbf_m2.booking_funding_activation_outcome_definition
(
    module1_run_id,
    activation_outcome_code,
    activation_outcome_rank,
    booking_authorized_flag,
    funding_authorized_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    external_notice_transmission_flag,
    production_adverse_action_notice_flag,
    real_funds_movement_flag,
    outcome_status,
    description,
    row_hash
)
SELECT
    module1_run_id,
    activation_outcome_code,
    activation_outcome_rank,
    booking_authorized_flag,
    funding_authorized_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    external_notice_transmission_flag,
    production_adverse_action_notice_flag,
    real_funds_movement_flag,
    outcome_status,
    description,
    row_hash
FROM _m2_4_outcome_seed
ON CONFLICT(module1_run_id,activation_outcome_code)
DO NOTHING;

DROP TABLE IF EXISTS _m2_4_reason_seed;

CREATE TEMP TABLE _m2_4_reason_seed
(
    module1_run_id                        bigint NOT NULL,
    activation_reason_code               text NOT NULL,
    mapped_activation_outcome_code        text NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    reason_status                         text NOT NULL,
    description                           text NOT NULL,
    row_hash                              text
)
ON COMMIT DROP;

INSERT INTO _m2_4_reason_seed
SELECT
    policy.module1_run_id,
    source.activation_reason_code,
    source.mapped_activation_outcome_code,
    source.production_adverse_action_notice_flag,
    'APPROVED',
    source.description,
    NULL::text
FROM msbf_ctl.m2_4_policy_profile AS policy
CROSS JOIN
(
    VALUES
        ('M2_4_ADVANCE_ACTIVATED', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'Accepted final offer has been converted into a synthetic booked, funded and activated advance.'),
        ('M2_4_ACTIVATION_REVIEW_REQUIRED', 'ACTIVATION_REVIEW_REQUIRED', FALSE, 'Counteroffer review remains unresolved; operational activation is held.'),
        ('M2_4_INSUFFICIENT_EVIDENCE_NOT_ACTIVATED', 'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE', FALSE, 'Insufficient-evidence decision is preserved and not activated.'),
        ('M2_4_POLICY_DECLINE_NOT_ACTIVATED', 'NOT_ACTIVATED_POLICY_DECLINE', FALSE, 'Policy decline decision is preserved and not activated.'),
        ('M2_4_SOURCE_M2_3_ACCEPTED', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'Accepted M2.3 final-decision contract was consumed.'),
        ('M2_4_SYNTHETIC_ACCEPTANCE_ASSUMED', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'Synthetic acceptance is explicitly assumed for the final-offer population.'),
        ('M2_4_BOOKING_CONTROL_PASS', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'Booking eligibility and duplicate-booking controls passed.'),
        ('M2_4_FUNDING_CONTROL_PASS', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'Synthetic funding controls passed; no real funds moved.'),
        ('M2_4_ACCOUNT_ACTIVATED', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'Synthetic account identity and activation date were created.'),
        ('M2_4_ADVANCE_FUNDED', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'Synthetic advance funding record was created.'),
        ('M2_4_PORTFOLIO_ACTIVATED', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'Initial portfolio position was activated.'),
        ('M2_4_FIRST_REMITTANCE_SCHEDULED', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'First expected remittance date was scheduled.'),
        ('M2_4_NOTICE_INTERNAL_ONLY', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'Notice evidence is internal-only and no external transmission occurs.'),
        ('M2_4_REVIEW_NOTICE_INTERNAL_ONLY', 'ACTIVATION_REVIEW_REQUIRED', FALSE, 'Review notification evidence is internal-only.'),
        ('M2_4_DECLINE_NOTICE_SUPPRESSED', 'NOT_ACTIVATED_POLICY_DECLINE', FALSE, 'Synthetic decline notice is suppressed; no production notice is generated.'),
        ('M2_4_NO_REAL_FUNDS_MOVEMENT', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'No real funds movement, ACH trace or settlement account is created.'),
        ('M2_4_NO_PRODUCTION_ADVERSE_ACTION', 'NOT_ACTIVATED_POLICY_DECLINE', FALSE, 'Internal decision reason is not a production adverse-action notice.'),
        ('M2_4_NO_EXTERNAL_TRANSMISSION', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'External transmission is prohibited in this synthetic module.'),
        ('M2_4_SOURCE_LINEAGE', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'M2.3 decision, M2.2 pricing and G2 lineage hashes are preserved.'),
        ('M2_4_INSUFFICIENT_NOTICE_SUPPRESSED', 'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE', FALSE, 'Synthetic insufficient-evidence notice is suppressed; no production notice is generated.'),
        ('M2_4_INSUFFICIENT_NO_PRODUCTION_ADVERSE_ACTION', 'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE', FALSE, 'Insufficient-evidence route creates no production adverse-action notice.'),
        ('M2_4_MATCHED_SCENARIO_GUARD', 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED', FALSE, 'Stress activation and funded amount are not more favorable than baseline.'),
        ('M2_4_REVIEW_EXCEPTION_ROUTE', 'ACTIVATION_REVIEW_REQUIRED', FALSE, 'Operational exception routing preserves the manual-review outcome.'),
        ('M2_4_FALLBACK_REVIEW', 'NO_ACTIVATION_SOURCE_BOUNDARY', FALSE, 'Unexpected upstream outcome is routed to fail-closed operational review.')
) AS source
(
    activation_reason_code,
    mapped_activation_outcome_code,
    production_adverse_action_notice_flag,
    description
)
WHERE policy.policy_code = 'M2_4_BOOKING_FUNDING_ACTIVATION_POLICY_V1';

UPDATE _m2_4_reason_seed AS reason
SET row_hash = msbf_ctl.m2_4_hash_jsonb
(
    to_jsonb(reason) - 'row_hash'
)
WHERE reason.row_hash IS NULL;

INSERT INTO msbf_m2.booking_funding_reason_definition
(
    module1_run_id,
    activation_reason_code,
    mapped_activation_outcome_code,
    production_adverse_action_notice_flag,
    reason_status,
    description,
    row_hash
)
SELECT
    module1_run_id,
    activation_reason_code,
    mapped_activation_outcome_code,
    production_adverse_action_notice_flag,
    reason_status,
    description,
    row_hash
FROM _m2_4_reason_seed
ON CONFLICT(module1_run_id,activation_reason_code)
DO NOTHING;

DROP TABLE IF EXISTS _m2_4_notice_seed;

CREATE TEMP TABLE _m2_4_notice_seed
(
    module1_run_id                        bigint NOT NULL,
    notice_control_code                   text NOT NULL,
    notice_audience_code                  text NOT NULL,
    external_transmission_authorized_flag boolean NOT NULL,
    production_adverse_action_notice_flag boolean NOT NULL,
    control_status                        text NOT NULL,
    description                           text NOT NULL,
    row_hash                              text
)
ON COMMIT DROP;

INSERT INTO _m2_4_notice_seed
SELECT
    policy.module1_run_id,
    source.notice_control_code,
    source.notice_audience_code,
    source.external_transmission_authorized_flag,
    source.production_adverse_action_notice_flag,
    'APPROVED',
    source.description,
    NULL::text
FROM msbf_ctl.m2_4_policy_profile AS policy
CROSS JOIN
(
    VALUES
        ('FUNDING_CONFIRMATION_INTERNAL_ONLY', 'INTERNAL_OPERATIONS', FALSE, FALSE, 'Internal synthetic funding-confirmation evidence; no external transmission.'),
        ('ACTIVATION_REVIEW_INTERNAL_ONLY', 'INTERNAL_OPERATIONS', FALSE, FALSE, 'Internal review-routing evidence; no customer transmission.'),
        ('DECLINE_NOTICE_SUPPRESSED_SYNTHETIC', 'INTERNAL_GOVERNANCE', FALSE, FALSE, 'Synthetic decline notice is suppressed and is not production adverse action.'),
        ('NO_NOTICE_SOURCE_BOUNDARY', 'INTERNAL_GOVERNANCE', FALSE, FALSE, 'Fallback source-boundary state with no external notice authorization.')
) AS source
(
    notice_control_code,
    notice_audience_code,
    external_transmission_authorized_flag,
    production_adverse_action_notice_flag,
    description
)
WHERE policy.policy_code = 'M2_4_BOOKING_FUNDING_ACTIVATION_POLICY_V1';

UPDATE _m2_4_notice_seed AS notice
SET row_hash = msbf_ctl.m2_4_hash_jsonb
(
    to_jsonb(notice) - 'row_hash'
)
WHERE notice.row_hash IS NULL;

INSERT INTO msbf_m2.external_notice_control_definition
(
    module1_run_id,
    notice_control_code,
    notice_audience_code,
    external_transmission_authorized_flag,
    production_adverse_action_notice_flag,
    control_status,
    description,
    row_hash
)
SELECT
    module1_run_id,
    notice_control_code,
    notice_audience_code,
    external_transmission_authorized_flag,
    production_adverse_action_notice_flag,
    control_status,
    description,
    row_hash
FROM _m2_4_notice_seed
ON CONFLICT(module1_run_id,notice_control_code)
DO NOTHING;

/* --------------------------------------------------------------------------
Governed consumption and comparison views
-------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW msbf_m2.v_m2_4_activation_latest
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
    latest.source_final_decision_outcome_code,
    latest.activation_outcome_code,
    latest.activation_outcome_rank,
    latest.booking_eligible_flag,
    latest.booking_authorized_flag,
    latest.funding_authorized_flag,
    latest.funding_completed_flag,
    latest.portfolio_activated_flag,
    latest.operational_review_required_flag,
    latest.synthetic_offer_acceptance_assumed_flag,
    latest.real_funds_movement_flag,
    latest.external_notice_generation_authorized_flag,
    latest.external_notice_transmitted_flag,
    latest.production_adverse_action_notice_flag,
    latest.synthetic_account_id,
    latest.synthetic_advance_id,
    latest.booked_amount,
    latest.funded_amount,
    latest.activation_remittance_rate,
    latest.activation_payback_multiple,
    latest.activation_collection_horizon_days,
    latest.activation_total_repayment_amount,
    latest.activation_finance_charge_amount,
    latest.activation_implied_daily_collection_amount,
    latest.activation_implied_payoff_days,
    latest.booking_date,
    latest.funding_date,
    latest.portfolio_activation_date,
    latest.first_expected_remittance_date,
    latest.monitoring_start_date,
    latest.activation_evidence_status,
    latest.notice_control_code,
    latest.primary_activation_reason_code,
    latest.activation_reason_codes,
    latest.source_m2_3_contract_row_hash,
    latest.source_m2_2_contract_row_hash,
    latest.source_g2_combined_hash,
    latest.source_snapshot_row_hash,
    latest.snapshot_row_hash,
    latest.policy_configuration_hash,
    latest.contract_row_hash,
    latest.created_at,
    outcome.booking_authorized_flag AS outcome_booking_authorized_flag,
    outcome.funding_authorized_flag AS outcome_funding_authorized_flag,
    outcome.portfolio_activated_flag AS outcome_portfolio_activated_flag,
    reason.description AS primary_reason_description,
    notice.notice_audience_code,
    notice.external_transmission_authorized_flag
FROM msbf_m2.application_booking_funding_activation_latest AS latest
JOIN msbf_m2.booking_funding_activation_outcome_definition AS outcome
  ON outcome.module1_run_id = latest.module1_run_id
 AND outcome.activation_outcome_code = latest.activation_outcome_code
JOIN msbf_m2.booking_funding_reason_definition AS reason
  ON reason.module1_run_id = latest.module1_run_id
 AND reason.activation_reason_code = latest.primary_activation_reason_code
JOIN msbf_m2.external_notice_control_definition AS notice
  ON notice.module1_run_id = latest.module1_run_id
 AND notice.notice_control_code = latest.notice_control_code;

CREATE OR REPLACE VIEW msbf_m2.v_m2_4_matched_scenario_comparison
AS
SELECT
    baseline.module1_run_id,
    baseline.merchant_application_id,
    baseline.activation_outcome_code AS baseline_activation_outcome_code,
    stress.activation_outcome_code AS stress_activation_outcome_code,
    baseline.activation_outcome_rank AS baseline_activation_outcome_rank,
    stress.activation_outcome_rank AS stress_activation_outcome_rank,
    baseline.portfolio_activated_flag AS baseline_portfolio_activated_flag,
    stress.portfolio_activated_flag AS stress_portfolio_activated_flag,
    baseline.funded_amount AS baseline_funded_amount,
    stress.funded_amount AS stress_funded_amount,
    (
        stress.activation_outcome_rank < baseline.activation_outcome_rank
    ) AS stress_activation_improvement_flag,
    (
        stress.portfolio_activated_flag
        AND baseline.portfolio_activated_flag
        AND stress.funded_amount > baseline.funded_amount
    ) AS stress_funded_amount_improvement_flag
FROM msbf_m2.application_booking_funding_activation_latest AS baseline
JOIN msbf_m2.application_booking_funding_activation_latest AS stress
  ON stress.module1_run_id = baseline.module1_run_id
 AND stress.merchant_application_id = baseline.merchant_application_id
 AND stress.scenario_code = 'RECESSION_ENERGY'
WHERE baseline.scenario_code = 'BASELINE';

CREATE OR REPLACE VIEW msbf_m2.v_m2_4_power_bi_portfolio_activation
AS
SELECT
    latest.module1_run_id,
    latest.scenario_code,
    latest.merchant_application_id,
    latest.source_final_decision_outcome_code,
    latest.activation_outcome_code,
    latest.booking_authorized_flag,
    latest.funding_completed_flag,
    latest.portfolio_activated_flag,
    latest.operational_review_required_flag,
    latest.synthetic_account_id,
    latest.synthetic_advance_id,
    latest.funded_amount,
    latest.activation_remittance_rate,
    latest.activation_payback_multiple,
    latest.activation_collection_horizon_days,
    latest.booking_date,
    latest.funding_date,
    latest.portfolio_activation_date,
    latest.monitoring_start_date,
    latest.primary_activation_reason_code,
    latest.notice_control_code
FROM msbf_m2.application_booking_funding_activation_latest AS latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_4_portfolio_activation_lineage
AS
SELECT
    latest.module1_run_id,
    latest.scenario_id,
    latest.scenario_code,
    latest.merchant_application_id,
    latest.contract_code,
    latest.contract_version,
    latest.schema_version,
    latest.activation_outcome_code,
    latest.synthetic_account_id,
    latest.synthetic_advance_id,
    latest.source_m2_3_contract_row_hash,
    latest.source_m2_2_contract_row_hash,
    latest.source_g2_combined_hash,
    latest.source_snapshot_row_hash,
    latest.snapshot_row_hash,
    latest.contract_row_hash
FROM msbf_m2.application_booking_funding_activation_latest AS latest;

/* --------------------------------------------------------------------------
Final schema/policy checkpoint
-------------------------------------------------------------------------- */
DO $m2_4_schema_guard$
DECLARE
    v_run_id bigint;
    v_policy_rows bigint;
    v_outcome_rows bigint;
    v_reason_rows bigint;
    v_notice_rows bigint;
    v_gate_rows bigint;
BEGIN
    SELECT module1_run_id
    INTO v_run_id
    FROM msbf_ctl.m2_4_policy_profile
    WHERE policy_code = 'M2_4_BOOKING_FUNDING_ACTIVATION_POLICY_V1';

    PERFORM msbf_ctl.m2_4_assert_configuration(v_run_id);

    SELECT count(*) INTO v_policy_rows
    FROM msbf_ctl.m2_4_policy_profile
    WHERE module1_run_id = v_run_id;

    SELECT count(*) INTO v_outcome_rows
    FROM msbf_m2.booking_funding_activation_outcome_definition
    WHERE module1_run_id = v_run_id
      AND outcome_status = 'APPROVED';

    SELECT count(*) INTO v_reason_rows
    FROM msbf_m2.booking_funding_reason_definition
    WHERE module1_run_id = v_run_id
      AND reason_status = 'APPROVED';

    SELECT count(*) INTO v_notice_rows
    FROM msbf_m2.external_notice_control_definition
    WHERE module1_run_id = v_run_id
      AND control_status = 'APPROVED';

    SELECT count(*) INTO v_gate_rows
    FROM msbf_ref.acceptance_gate_catalog
    WHERE gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
      AND active_flag;

    IF v_policy_rows <> 1
       OR v_outcome_rows <> 5
       OR v_reason_rows <> 24
       OR v_notice_rows <> 4
       OR v_gate_rows <> 1 THEN
        RAISE EXCEPTION
            'M2.4 schema/policy extension failed: policy %, outcomes %, reasons %, notices %, gate %.',
            v_policy_rows,
            v_outcome_rows,
            v_reason_rows,
            v_notice_rows,
            v_gate_rows;
    END IF;
END;
$m2_4_schema_guard$;

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
    policy.source_m2_3_contract_code,
    policy.source_m2_3_contract_version,
    policy.source_m2_3_schema_version,
    policy.source_m2_3_combined_hash,
    policy.configuration_hash,
    (
        SELECT count(*)
        FROM msbf_ref.acceptance_gate_catalog AS gate
        WHERE gate.gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
          AND gate.active_flag
    ) AS acceptance_gate_catalog_rows,
    (
        SELECT count(*)
        FROM msbf_m2.booking_funding_activation_outcome_definition AS outcome
        WHERE outcome.module1_run_id = policy.module1_run_id
    ) AS outcome_definition_rows,
    (
        SELECT count(*)
        FROM msbf_m2.booking_funding_reason_definition AS reason
        WHERE reason.module1_run_id = policy.module1_run_id
    ) AS reason_definition_rows,
    (
        SELECT count(*)
        FROM msbf_m2.external_notice_control_definition AS notice
        WHERE notice.module1_run_id = policy.module1_run_id
    ) AS notice_control_rows,
    CASE
        WHEN policy.policy_status = 'APPROVED'
         AND policy.synthetic_booking_enabled_flag
         AND policy.synthetic_funding_enabled_flag
         AND policy.portfolio_activation_enabled_flag
         AND policy.real_funds_movement_prohibited_flag
         AND policy.external_notice_transmission_prohibited_flag
         AND policy.production_adverse_action_notice_prohibited_flag
        THEN 'PASS'
        ELSE 'FAIL'
    END AS schema_policy_status
FROM msbf_ctl.m2_4_policy_profile AS policy
WHERE policy.policy_code = 'M2_4_BOOKING_FUNDING_ACTIVATION_POLICY_V1';
