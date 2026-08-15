/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.3 — Final Offer & Decision Authorization

Program     : 150_msbf_m2_3_final_offer_decision_generation_v0_2R1.sql
Version     : v0.2R1
Purpose     : Materialize accepted M2.2 pricing structures once, authorize
              synthetic final offer/decision outcomes, publish latest and
              immutable archive contracts, reconcile 6,029 canonical entities,
              and commit only after deterministic validation passes.

Performance :
- Accepted M2.2 input is materialized once.
- Target-typed staging precedes row hashing.
- Explicit joins; no USING joins or alias-star projections.
- Index and ANALYZE before downstream reconciliation.
- Generation is separate from validation and reporting.

Boundary    : No booking, funding, external notice, account creation, or
              production adverse-action notice.
============================================================================ */

BEGIN;

SET LOCAL work_mem = '128MB';
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '45min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m2_3_result;

CREATE TEMP TABLE _m2_3_result
(
    run_id                                  bigint,
    run_status                              text,
    policy_rows                             bigint,
    outcome_rows                            bigint,
    reason_rows                             bigint,
    source_rows                             bigint,
    decision_snapshot_rows                  bigint,
    decision_latest_rows                    bigint,
    decision_archive_rows                   bigint,
    comparison_rows                         bigint,
    registry_rows                           bigint,
    final_offer_authorized_rows             bigint,
    manual_review_required_rows             bigint,
    decline_insufficient_evidence_rows      bigint,
    decline_policy_rows                     bigint,
    expected_canonical_entities             bigint,
    actual_canonical_entities               bigint,
    row_level_mismatches                    bigint,
    policy_set_hash                         text,
    outcome_set_hash                        text,
    reason_set_hash                         text,
    source_set_hash                         text,
    decision_snapshot_set_hash              text,
    decision_latest_set_hash                text,
    decision_archive_set_hash               text,
    contract_set_hash                       text,
    combined_set_hash                       text,
    generation_status                       text
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_3_ctx;

CREATE TEMP TABLE _m2_3_ctx
ON COMMIT DROP
AS
SELECT
    run.run_id,
    policy.configuration_hash,
    policy.expected_source_rows,
    policy.expected_decision_snapshot_rows,
    policy.expected_decision_latest_rows,
    policy.expected_decision_archive_rows,
    policy.expected_comparison_rows,
    policy.expected_canonical_entities
FROM msbf_ctl.run_registry AS run
JOIN msbf_ctl.m2_3_policy_profile AS policy
  ON policy.module1_run_id = run.run_id
WHERE run.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND run.run_version = 1;

DO $m2_3_generation_ready$
BEGIN
    PERFORM msbf_ctl.m2_3_assert_generation_ready
    (
        (SELECT run_id FROM _m2_3_ctx)
    );
END;
$m2_3_generation_ready$;

/* --------------------------------------------------------------------------
Materialize the accepted M2.2 source once.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_3_source_input;

CREATE TEMP TABLE _m2_3_source_input
ON COMMIT DROP
AS
SELECT
    latest.module1_run_id,
    latest.scenario_id,
    latest.scenario_code,
    latest.merchant_application_id,
    latest.population_id,
    latest.merchant_id,
    latest.as_of_date,
    latest.pricing_disposition_code,
    latest.structure_available_flag,
    latest.review_required_flag,
    latest.selected_candidate_template_code,
    latest.selected_funding_amount,
    latest.selected_remittance_rate,
    latest.selected_payback_multiple,
    latest.selected_collection_horizon_days,
    latest.selected_total_repayment_amount,
    latest.selected_finance_charge_amount,
    latest.selected_implied_daily_collection_amount,
    latest.selected_implied_payoff_days,
    latest.source_request_contract_row_hash,
    latest.source_g2_combined_hash,
    latest.contract_row_hash AS source_m2_2_contract_row_hash,
    latest.contract_row_hash AS source_pricing_contract_row_hash,
    to_jsonb(latest) AS source_payload
FROM msbf_m2.application_pricing_structure_latest AS latest
WHERE latest.module1_run_id = (SELECT run_id FROM _m2_3_ctx);

CREATE UNIQUE INDEX
ON _m2_3_source_input(module1_run_id,scenario_id,merchant_application_id);

ANALYZE _m2_3_source_input;

/* --------------------------------------------------------------------------
Target-typed source snapshot.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_3_source_expected;

CREATE TEMP TABLE _m2_3_source_expected
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
    row_hash                          text
)
ON COMMIT DROP;

INSERT INTO _m2_3_source_expected
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    pricing_disposition_code,
    structure_available_flag,
    review_required_flag,
    selected_candidate_template_code,
    selected_funding_amount,
    selected_remittance_rate,
    selected_payback_multiple,
    selected_collection_horizon_days,
    selected_total_repayment_amount,
    selected_finance_charge_amount,
    selected_implied_daily_collection_amount,
    selected_implied_payoff_days,
    source_m2_2_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    source_payload,
    row_hash
)
SELECT
    source.module1_run_id,
    source.scenario_id,
    source.scenario_code,
    source.merchant_application_id,
    source.population_id,
    source.merchant_id,
    source.as_of_date,
    source.pricing_disposition_code,
    source.structure_available_flag,
    source.review_required_flag,
    source.selected_candidate_template_code,
    source.selected_funding_amount::numeric(18,2),
    source.selected_remittance_rate::numeric(9,6),
    source.selected_payback_multiple::numeric(9,6),
    source.selected_collection_horizon_days::integer,
    source.selected_total_repayment_amount::numeric(18,2),
    source.selected_finance_charge_amount::numeric(18,2),
    source.selected_implied_daily_collection_amount::numeric(18,2),
    source.selected_implied_payoff_days::numeric(18,4),
    source.source_m2_2_contract_row_hash,
    source.source_request_contract_row_hash,
    source.source_g2_combined_hash,
    source.source_payload,
    NULL::text
FROM _m2_3_source_input AS source;

UPDATE _m2_3_source_expected AS source
SET row_hash = msbf_ctl.m2_3_hash_jsonb
(
    to_jsonb(source) - 'row_hash'
)
WHERE source.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_3_source_expected(module1_run_id,scenario_id,merchant_application_id);

ANALYZE _m2_3_source_expected;

DO $m2_3_source_guard$
DECLARE
    v_rows bigint;
    v_invalid bigint;
BEGIN
    SELECT
        count(*),
        count(*) FILTER
        (
            WHERE row_hash IS NULL
               OR pricing_disposition_code NOT IN
               (
                   'STRUCTURE_READY',
                   'COUNTEROFFER_FOUNDATION_REVIEW',
                   'NO_STRUCTURE_INSUFFICIENT_EVIDENCE',
                   'NO_STRUCTURE_POLICY_DECLINE'
               )
        )
    INTO v_rows, v_invalid
    FROM _m2_3_source_expected;

    IF v_rows <> 1500
       OR v_invalid <> 0 THEN
        RAISE EXCEPTION
            'M2.3 source materialization failed: rows %, invalid %.',
            v_rows, v_invalid;
    END IF;
END;
$m2_3_source_guard$;

INSERT INTO msbf_m2.application_final_decision_source_snapshot
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    pricing_disposition_code,
    structure_available_flag,
    review_required_flag,
    selected_candidate_template_code,
    selected_funding_amount,
    selected_remittance_rate,
    selected_payback_multiple,
    selected_collection_horizon_days,
    selected_total_repayment_amount,
    selected_finance_charge_amount,
    selected_implied_daily_collection_amount,
    selected_implied_payoff_days,
    source_m2_2_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    source_payload,
    row_hash
)
SELECT
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    pricing_disposition_code,
    structure_available_flag,
    review_required_flag,
    selected_candidate_template_code,
    selected_funding_amount,
    selected_remittance_rate,
    selected_payback_multiple,
    selected_collection_horizon_days,
    selected_total_repayment_amount,
    selected_finance_charge_amount,
    selected_implied_daily_collection_amount,
    selected_implied_payoff_days,
    source_m2_2_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    source_payload,
    row_hash
FROM _m2_3_source_expected;

/* --------------------------------------------------------------------------
Target-typed decision snapshot.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_3_decision_expected;

CREATE TEMP TABLE _m2_3_decision_expected
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
    row_hash                          text
)
ON COMMIT DROP;

INSERT INTO _m2_3_decision_expected
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_pricing_disposition_code,
    final_decision_outcome_code,
    final_decision_rank,
    final_offer_authorized_flag,
    counteroffer_review_required_flag,
    decline_authorized_flag,
    manual_review_required_flag,
    final_offer_amount,
    final_remittance_rate,
    final_payback_multiple,
    final_collection_horizon_days,
    final_total_repayment_amount,
    final_finance_charge_amount,
    final_implied_daily_collection_amount,
    final_implied_payoff_days,
    final_offer_expiration_days,
    final_authorization_evidence_status,
    primary_decision_reason_code,
    decision_reason_codes,
    source_m2_2_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    policy_configuration_hash,
    row_hash
)
SELECT
    source.module1_run_id,
    source.scenario_id,
    source.scenario_code,
    source.merchant_application_id,
    source.population_id,
    source.merchant_id,
    source.as_of_date,
    source.pricing_disposition_code,

    CASE source.pricing_disposition_code
        WHEN 'STRUCTURE_READY'
            THEN 'FINAL_OFFER_AUTHORIZED'
        WHEN 'COUNTEROFFER_FOUNDATION_REVIEW'
            THEN 'COUNTEROFFER_REVIEW_REQUIRED'
        WHEN 'NO_STRUCTURE_INSUFFICIENT_EVIDENCE'
            THEN 'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED'
        WHEN 'NO_STRUCTURE_POLICY_DECLINE'
            THEN 'DECLINE_POLICY_AUTHORIZED'
        ELSE 'NO_DECISION_SOURCE_BOUNDARY'
    END AS final_decision_outcome_code,

    CASE source.pricing_disposition_code
        WHEN 'STRUCTURE_READY' THEN 1
        WHEN 'COUNTEROFFER_FOUNDATION_REVIEW' THEN 2
        WHEN 'NO_STRUCTURE_INSUFFICIENT_EVIDENCE' THEN 3
        WHEN 'NO_STRUCTURE_POLICY_DECLINE' THEN 4
        ELSE 9
    END AS final_decision_rank,

    (source.pricing_disposition_code = 'STRUCTURE_READY')
        AS final_offer_authorized_flag,

    (source.pricing_disposition_code = 'COUNTEROFFER_FOUNDATION_REVIEW')
        AS counteroffer_review_required_flag,

    (source.pricing_disposition_code IN
        (
            'NO_STRUCTURE_INSUFFICIENT_EVIDENCE',
            'NO_STRUCTURE_POLICY_DECLINE'
        )
    ) AS decline_authorized_flag,

    (source.pricing_disposition_code = 'COUNTEROFFER_FOUNDATION_REVIEW'
     OR source.pricing_disposition_code = 'NO_DECISION_SOURCE_BOUNDARY')
        AS manual_review_required_flag,

    CASE WHEN source.pricing_disposition_code = 'STRUCTURE_READY'
         THEN source.selected_funding_amount
         ELSE NULL::numeric(18,2) END AS final_offer_amount,

    CASE WHEN source.pricing_disposition_code = 'STRUCTURE_READY'
         THEN source.selected_remittance_rate
         ELSE NULL::numeric(9,6) END AS final_remittance_rate,

    CASE WHEN source.pricing_disposition_code = 'STRUCTURE_READY'
         THEN source.selected_payback_multiple
         ELSE NULL::numeric(9,6) END AS final_payback_multiple,

    CASE WHEN source.pricing_disposition_code = 'STRUCTURE_READY'
         THEN source.selected_collection_horizon_days
         ELSE NULL::integer END AS final_collection_horizon_days,

    CASE WHEN source.pricing_disposition_code = 'STRUCTURE_READY'
         THEN source.selected_total_repayment_amount
         ELSE NULL::numeric(18,2) END AS final_total_repayment_amount,

    CASE WHEN source.pricing_disposition_code = 'STRUCTURE_READY'
         THEN source.selected_finance_charge_amount
         ELSE NULL::numeric(18,2) END AS final_finance_charge_amount,

    CASE WHEN source.pricing_disposition_code = 'STRUCTURE_READY'
         THEN source.selected_implied_daily_collection_amount
         ELSE NULL::numeric(18,2) END AS final_implied_daily_collection_amount,

    CASE WHEN source.pricing_disposition_code = 'STRUCTURE_READY'
         THEN source.selected_implied_payoff_days
         ELSE NULL::numeric(18,4) END AS final_implied_payoff_days,

    CASE WHEN source.pricing_disposition_code = 'STRUCTURE_READY'
         THEN 14::integer
         ELSE NULL::integer END AS final_offer_expiration_days,

    CASE source.pricing_disposition_code
        WHEN 'STRUCTURE_READY' THEN 'AUTHORIZED'
        WHEN 'COUNTEROFFER_FOUNDATION_REVIEW' THEN 'REVIEW_REQUIRED'
        ELSE 'DECLINE_AUTHORIZED'
    END AS final_authorization_evidence_status,

    CASE source.pricing_disposition_code
        WHEN 'STRUCTURE_READY'
            THEN 'M2_3_FINAL_OFFER_READY'
        WHEN 'COUNTEROFFER_FOUNDATION_REVIEW'
            THEN 'M2_3_COUNTEROFFER_REVIEW_REQUIRED'
        WHEN 'NO_STRUCTURE_INSUFFICIENT_EVIDENCE'
            THEN 'M2_3_INSUFFICIENT_EVIDENCE'
        WHEN 'NO_STRUCTURE_POLICY_DECLINE'
            THEN 'M2_3_POLICY_DECLINE'
        ELSE 'M2_3_FALLBACK_REVIEW'
    END AS primary_decision_reason_code,

    jsonb_build_array
    (
        CASE source.pricing_disposition_code
            WHEN 'STRUCTURE_READY'
                THEN 'M2_3_FINAL_OFFER_READY'
            WHEN 'COUNTEROFFER_FOUNDATION_REVIEW'
                THEN 'M2_3_COUNTEROFFER_REVIEW_REQUIRED'
            WHEN 'NO_STRUCTURE_INSUFFICIENT_EVIDENCE'
                THEN 'M2_3_INSUFFICIENT_EVIDENCE'
            WHEN 'NO_STRUCTURE_POLICY_DECLINE'
                THEN 'M2_3_POLICY_DECLINE'
            ELSE 'M2_3_FALLBACK_REVIEW'
        END,
        'M2_3_SOURCE_M2_2_ACCEPTED',
        'M2_3_POLICY_BOUNDARY',
        'M2_3_NO_BOOKING'
    ) AS decision_reason_codes,

    source.source_m2_2_contract_row_hash,
    source.source_request_contract_row_hash,
    source.source_g2_combined_hash,
    source.row_hash,
    ctx.configuration_hash,
    NULL::text AS row_hash

FROM _m2_3_source_expected AS source
CROSS JOIN _m2_3_ctx AS ctx;

UPDATE _m2_3_decision_expected AS decision
SET row_hash = msbf_ctl.m2_3_hash_jsonb
(
    to_jsonb(decision) - 'row_hash'
)
WHERE decision.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_3_decision_expected(module1_run_id,scenario_id,merchant_application_id);

ANALYZE _m2_3_decision_expected;

DO $m2_3_decision_guard$
DECLARE
    v record;
BEGIN
    SELECT
        count(*) AS rows,
        count(*) FILTER(WHERE final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED') AS offer_rows,
        count(*) FILTER(WHERE final_decision_outcome_code = 'COUNTEROFFER_REVIEW_REQUIRED') AS review_rows,
        count(*) FILTER(WHERE final_decision_outcome_code = 'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED') AS insufficient_rows,
        count(*) FILTER(WHERE final_decision_outcome_code = 'DECLINE_POLICY_AUTHORIZED') AS policy_rows,
        count(*) FILTER(WHERE final_offer_authorized_flag AND final_offer_amount IS NULL) AS missing_offer_terms,
        count(*) FILTER(WHERE NOT final_offer_authorized_flag AND final_offer_amount IS NOT NULL) AS prohibited_offer_terms,
        count(*) FILTER(WHERE row_hash IS NULL) AS missing_hashes
    INTO v
    FROM _m2_3_decision_expected;

    IF v.rows <> 1500
       OR v.offer_rows <> 59
       OR v.review_rows <> 190
       OR v.insufficient_rows <> 178
       OR v.policy_rows <> 1073
       OR v.missing_offer_terms <> 0
       OR v.prohibited_offer_terms <> 0
       OR v.missing_hashes <> 0 THEN
        RAISE EXCEPTION
            'M2.3 decision mapping failed: %',
            row_to_json(v);
    END IF;
END;
$m2_3_decision_guard$;

INSERT INTO msbf_m2.application_final_offer_decision_snapshot
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_pricing_disposition_code,
    final_decision_outcome_code,
    final_decision_rank,
    final_offer_authorized_flag,
    counteroffer_review_required_flag,
    decline_authorized_flag,
    manual_review_required_flag,
    final_offer_amount,
    final_remittance_rate,
    final_payback_multiple,
    final_collection_horizon_days,
    final_total_repayment_amount,
    final_finance_charge_amount,
    final_implied_daily_collection_amount,
    final_implied_payoff_days,
    final_offer_expiration_days,
    final_authorization_evidence_status,
    primary_decision_reason_code,
    decision_reason_codes,
    source_m2_2_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    policy_configuration_hash,
    row_hash
)
SELECT
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_pricing_disposition_code,
    final_decision_outcome_code,
    final_decision_rank,
    final_offer_authorized_flag,
    counteroffer_review_required_flag,
    decline_authorized_flag,
    manual_review_required_flag,
    final_offer_amount,
    final_remittance_rate,
    final_payback_multiple,
    final_collection_horizon_days,
    final_total_repayment_amount,
    final_finance_charge_amount,
    final_implied_daily_collection_amount,
    final_implied_payoff_days,
    final_offer_expiration_days,
    final_authorization_evidence_status,
    primary_decision_reason_code,
    decision_reason_codes,
    source_m2_2_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    policy_configuration_hash,
    row_hash
FROM _m2_3_decision_expected;

/* --------------------------------------------------------------------------
Latest and archive contracts.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_3_latest_expected;

CREATE TEMP TABLE _m2_3_latest_expected
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
    contract_row_hash                 text
)
ON COMMIT DROP;

INSERT INTO _m2_3_latest_expected
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_pricing_disposition_code,
    final_decision_outcome_code,
    final_decision_rank,
    final_offer_authorized_flag,
    counteroffer_review_required_flag,
    decline_authorized_flag,
    manual_review_required_flag,
    final_offer_amount,
    final_remittance_rate,
    final_payback_multiple,
    final_collection_horizon_days,
    final_total_repayment_amount,
    final_finance_charge_amount,
    final_implied_daily_collection_amount,
    final_implied_payoff_days,
    final_offer_expiration_days,
    final_authorization_evidence_status,
    primary_decision_reason_code,
    decision_reason_codes,
    source_m2_2_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash
)
SELECT
    decision.module1_run_id,
    'M2_FINAL_OFFER_DECISION_CONSUMPTION',
    1,
    'M2_3_FINAL_DECISION_SCHEMA_V1',
    'M2_3_METHOD_V1',
    decision.scenario_id,
    decision.scenario_code,
    decision.merchant_application_id,
    decision.population_id,
    decision.merchant_id,
    decision.as_of_date,
    decision.source_pricing_disposition_code,
    decision.final_decision_outcome_code,
    decision.final_decision_rank,
    decision.final_offer_authorized_flag,
    decision.counteroffer_review_required_flag,
    decision.decline_authorized_flag,
    decision.manual_review_required_flag,
    decision.final_offer_amount,
    decision.final_remittance_rate,
    decision.final_payback_multiple,
    decision.final_collection_horizon_days,
    decision.final_total_repayment_amount,
    decision.final_finance_charge_amount,
    decision.final_implied_daily_collection_amount,
    decision.final_implied_payoff_days,
    decision.final_offer_expiration_days,
    decision.final_authorization_evidence_status,
    decision.primary_decision_reason_code,
    decision.decision_reason_codes,
    decision.source_m2_2_contract_row_hash,
    decision.source_request_contract_row_hash,
    decision.source_g2_combined_hash,
    decision.source_snapshot_row_hash,
    decision.row_hash,
    decision.policy_configuration_hash,
    NULL::text
FROM _m2_3_decision_expected AS decision;

UPDATE _m2_3_latest_expected AS latest
SET contract_row_hash = msbf_ctl.m2_3_hash_jsonb
(
    to_jsonb(latest) - 'contract_row_hash'
)
WHERE latest.contract_row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_3_latest_expected(module1_run_id,scenario_id,merchant_application_id);

ANALYZE _m2_3_latest_expected;

INSERT INTO msbf_m2.application_final_offer_decision_latest
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_pricing_disposition_code,
    final_decision_outcome_code,
    final_decision_rank,
    final_offer_authorized_flag,
    counteroffer_review_required_flag,
    decline_authorized_flag,
    manual_review_required_flag,
    final_offer_amount,
    final_remittance_rate,
    final_payback_multiple,
    final_collection_horizon_days,
    final_total_repayment_amount,
    final_finance_charge_amount,
    final_implied_daily_collection_amount,
    final_implied_payoff_days,
    final_offer_expiration_days,
    final_authorization_evidence_status,
    primary_decision_reason_code,
    decision_reason_codes,
    source_m2_2_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash
)
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_pricing_disposition_code,
    final_decision_outcome_code,
    final_decision_rank,
    final_offer_authorized_flag,
    counteroffer_review_required_flag,
    decline_authorized_flag,
    manual_review_required_flag,
    final_offer_amount,
    final_remittance_rate,
    final_payback_multiple,
    final_collection_horizon_days,
    final_total_repayment_amount,
    final_finance_charge_amount,
    final_implied_daily_collection_amount,
    final_implied_payoff_days,
    final_offer_expiration_days,
    final_authorization_evidence_status,
    primary_decision_reason_code,
    decision_reason_codes,
    source_m2_2_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash
FROM _m2_3_latest_expected;

DROP TABLE IF EXISTS _m2_3_archive_expected;

CREATE TEMP TABLE _m2_3_archive_expected
ON COMMIT DROP
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
    to_jsonb(latest) AS contract_payload,
    NULL::text AS archive_row_hash
FROM _m2_3_latest_expected AS latest;

UPDATE _m2_3_archive_expected AS archive
SET archive_row_hash = msbf_ctl.m2_3_hash_jsonb
(
    to_jsonb(archive) - 'archive_row_hash'
)
WHERE archive.archive_row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_3_archive_expected(module1_run_id,contract_version,scenario_id,merchant_application_id);

ANALYZE _m2_3_archive_expected;

INSERT INTO msbf_m2.application_final_offer_decision_archive
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_pricing_disposition_code,
    final_decision_outcome_code,
    final_decision_rank,
    final_offer_authorized_flag,
    counteroffer_review_required_flag,
    decline_authorized_flag,
    manual_review_required_flag,
    final_offer_amount,
    final_remittance_rate,
    final_payback_multiple,
    final_collection_horizon_days,
    final_total_repayment_amount,
    final_finance_charge_amount,
    final_implied_daily_collection_amount,
    final_implied_payoff_days,
    final_offer_expiration_days,
    final_authorization_evidence_status,
    primary_decision_reason_code,
    decision_reason_codes,
    source_m2_2_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash,
    contract_payload,
    archive_row_hash
)
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_pricing_disposition_code,
    final_decision_outcome_code,
    final_decision_rank,
    final_offer_authorized_flag,
    counteroffer_review_required_flag,
    decline_authorized_flag,
    manual_review_required_flag,
    final_offer_amount,
    final_remittance_rate,
    final_payback_multiple,
    final_collection_horizon_days,
    final_total_repayment_amount,
    final_finance_charge_amount,
    final_implied_daily_collection_amount,
    final_implied_payoff_days,
    final_offer_expiration_days,
    final_authorization_evidence_status,
    primary_decision_reason_code,
    decision_reason_codes,
    source_m2_2_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash,
    contract_payload,
    archive_row_hash
FROM _m2_3_archive_expected;

ANALYZE msbf_m2.application_final_decision_source_snapshot;
ANALYZE msbf_m2.application_final_offer_decision_snapshot;
ANALYZE msbf_m2.application_final_offer_decision_latest;
ANALYZE msbf_m2.application_final_offer_decision_archive;

/* --------------------------------------------------------------------------
Set hashes and registry.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_3_set_hashes;

CREATE TEMP TABLE _m2_3_set_hashes
ON COMMIT DROP
AS
SELECT
    (
        SELECT md5(string_agg(policy.row_hash,'|' ORDER BY policy.module1_run_id))
        FROM msbf_ctl.m2_3_policy_profile AS policy
        WHERE policy.module1_run_id = (SELECT run_id FROM _m2_3_ctx)
    ) AS policy_set_hash,
    (
        SELECT md5(string_agg(outcome.row_hash,'|' ORDER BY outcome.decision_outcome_rank,outcome.decision_outcome_code))
        FROM msbf_m2.final_decision_outcome_definition AS outcome
        WHERE outcome.module1_run_id = (SELECT run_id FROM _m2_3_ctx)
    ) AS outcome_set_hash,
    (
        SELECT md5(string_agg(reason.row_hash,'|' ORDER BY reason.decision_reason_code))
        FROM msbf_m2.final_decision_reason_definition AS reason
        WHERE reason.module1_run_id = (SELECT run_id FROM _m2_3_ctx)
    ) AS reason_set_hash,
    (
        SELECT md5(string_agg(source.scenario_id::text||'|'||source.merchant_application_id||'|'||source.row_hash,'|' ORDER BY source.scenario_id,source.merchant_application_id))
        FROM _m2_3_source_expected AS source
    ) AS source_set_hash,
    (
        SELECT md5(string_agg(decision.scenario_id::text||'|'||decision.merchant_application_id||'|'||decision.row_hash,'|' ORDER BY decision.scenario_id,decision.merchant_application_id))
        FROM _m2_3_decision_expected AS decision
    ) AS decision_snapshot_set_hash,
    (
        SELECT md5(string_agg(latest.scenario_id::text||'|'||latest.merchant_application_id||'|'||latest.contract_row_hash,'|' ORDER BY latest.scenario_id,latest.merchant_application_id))
        FROM _m2_3_latest_expected AS latest
    ) AS decision_latest_set_hash,
    (
        SELECT md5(string_agg(archive.scenario_id::text||'|'||archive.merchant_application_id||'|'||archive.archive_row_hash,'|' ORDER BY archive.scenario_id,archive.merchant_application_id))
        FROM _m2_3_archive_expected AS archive
    ) AS decision_archive_set_hash;

DROP TABLE IF EXISTS _m2_3_registry_expected;

CREATE TEMP TABLE _m2_3_registry_expected
(
    module1_run_id              bigint NOT NULL,
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
    contract_set_hash           text,
    combined_set_hash           text,
    contract_status             text NOT NULL,
    generated_at                timestamptz,
    validated_at                timestamptz,
    accepted_at                 timestamptz,
    row_hash                    text
)
ON COMMIT DROP;

INSERT INTO _m2_3_registry_expected
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    source_m2_2_contract_code,
    source_m2_2_contract_version,
    source_m2_2_schema_version,
    source_m2_2_combined_hash,
    source_m2_2_acceptance_gate_id,
    policy_configuration_hash,
    policy_rows,
    outcome_rows,
    reason_rows,
    source_rows,
    decision_snapshot_rows,
    decision_latest_rows,
    decision_archive_rows,
    comparison_rows,
    registry_rows,
    canonical_entities,
    final_offer_authorized_rows,
    manual_review_required_rows,
    decline_insufficient_evidence_rows,
    decline_policy_rows,
    policy_set_hash,
    outcome_set_hash,
    reason_set_hash,
    source_set_hash,
    decision_snapshot_set_hash,
    decision_latest_set_hash,
    decision_archive_set_hash,
    contract_set_hash,
    combined_set_hash,
    contract_status,
    generated_at,
    validated_at,
    accepted_at,
    row_hash
)
SELECT
    ctx.run_id,
    'M2_FINAL_OFFER_DECISION_CONSUMPTION',
    1,
    'M2_3_FINAL_DECISION_SCHEMA_V1',
    'M2_3_METHOD_V1',
    'M2_PRICING_STRUCTURE_CONSUMPTION',
    1,
    'M2_2_PRICING_STRUCTURE_SCHEMA_V1',
    'bbe83b187b31ea561789797322031fc6',
    'M2_2_PRICING_STRUCTURE_COUNTEROFFER',
    ctx.configuration_hash,
    1,
    5,
    22,
    1500,
    1500,
    1500,
    1500,
    750,
    1,
    6029,
    59,
    190,
    178,
    1073,
    hashes.policy_set_hash,
    hashes.outcome_set_hash,
    hashes.reason_set_hash,
    hashes.source_set_hash,
    hashes.decision_snapshot_set_hash,
    hashes.decision_latest_set_hash,
    hashes.decision_archive_set_hash,
    NULL::text,
    NULL::text,
    'GENERATED',
    clock_timestamp(),
    NULL::timestamptz,
    NULL::timestamptz,
    NULL::text
FROM _m2_3_ctx AS ctx
CROSS JOIN _m2_3_set_hashes AS hashes;

UPDATE _m2_3_registry_expected AS registry
SET row_hash = msbf_ctl.m2_3_registry_row_hash(to_jsonb(registry))
WHERE registry.row_hash IS NULL;

UPDATE _m2_3_registry_expected AS registry
SET contract_set_hash = md5(registry.row_hash)
WHERE registry.contract_set_hash IS NULL;

DROP TABLE IF EXISTS _m2_3_canonical_expected;

CREATE TEMP TABLE _m2_3_canonical_expected
(
    entity_type text NOT NULL,
    entity_key  text NOT NULL,
    row_hash    text NOT NULL,
    PRIMARY KEY(entity_type,entity_key)
)
ON COMMIT DROP;

INSERT INTO _m2_3_canonical_expected
SELECT
    'POLICY',
    policy.policy_code || '|v' || policy.policy_version::text,
    policy.row_hash
FROM msbf_ctl.m2_3_policy_profile AS policy
WHERE policy.module1_run_id = (SELECT run_id FROM _m2_3_ctx)

UNION ALL

SELECT
    'OUTCOME',
    outcome.decision_outcome_code,
    outcome.row_hash
FROM msbf_m2.final_decision_outcome_definition AS outcome
WHERE outcome.module1_run_id = (SELECT run_id FROM _m2_3_ctx)

UNION ALL

SELECT
    'REASON',
    reason.decision_reason_code,
    reason.row_hash
FROM msbf_m2.final_decision_reason_definition AS reason
WHERE reason.module1_run_id = (SELECT run_id FROM _m2_3_ctx)

UNION ALL

SELECT
    'SOURCE',
    source.scenario_id::text || '|' || source.merchant_application_id,
    source.row_hash
FROM _m2_3_source_expected AS source

UNION ALL

SELECT
    'DECISION_SNAPSHOT',
    decision.scenario_id::text || '|' || decision.merchant_application_id,
    decision.row_hash
FROM _m2_3_decision_expected AS decision

UNION ALL

SELECT
    'LATEST',
    latest.scenario_id::text || '|' || latest.merchant_application_id,
    latest.contract_row_hash
FROM _m2_3_latest_expected AS latest

UNION ALL

SELECT
    'ARCHIVE',
    archive.scenario_id::text || '|' || archive.merchant_application_id,
    archive.archive_row_hash
FROM _m2_3_archive_expected AS archive

UNION ALL

SELECT
    'REGISTRY',
    registry.contract_code || '|v' || registry.contract_version::text,
    registry.row_hash
FROM _m2_3_registry_expected AS registry;

UPDATE _m2_3_registry_expected AS registry
SET combined_set_hash =
(
    SELECT md5(
        string_agg(
            canonical.entity_type || '|' ||
            canonical.entity_key || '|' ||
            canonical.row_hash,
            '|' ORDER BY
            canonical.entity_type,
            canonical.entity_key
        )
    )
    FROM _m2_3_canonical_expected AS canonical
)
WHERE registry.combined_set_hash IS NULL;

INSERT INTO msbf_ctl.m2_3_final_decision_contract_registry
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    source_m2_2_contract_code,
    source_m2_2_contract_version,
    source_m2_2_schema_version,
    source_m2_2_combined_hash,
    source_m2_2_acceptance_gate_id,
    policy_configuration_hash,
    policy_rows,
    outcome_rows,
    reason_rows,
    source_rows,
    decision_snapshot_rows,
    decision_latest_rows,
    decision_archive_rows,
    comparison_rows,
    registry_rows,
    canonical_entities,
    final_offer_authorized_rows,
    manual_review_required_rows,
    decline_insufficient_evidence_rows,
    decline_policy_rows,
    policy_set_hash,
    outcome_set_hash,
    reason_set_hash,
    source_set_hash,
    decision_snapshot_set_hash,
    decision_latest_set_hash,
    decision_archive_set_hash,
    contract_set_hash,
    combined_set_hash,
    contract_status,
    generated_at,
    validated_at,
    accepted_at,
    row_hash
)
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    source_m2_2_contract_code,
    source_m2_2_contract_version,
    source_m2_2_schema_version,
    source_m2_2_combined_hash,
    source_m2_2_acceptance_gate_id,
    policy_configuration_hash,
    policy_rows,
    outcome_rows,
    reason_rows,
    source_rows,
    decision_snapshot_rows,
    decision_latest_rows,
    decision_archive_rows,
    comparison_rows,
    registry_rows,
    canonical_entities,
    final_offer_authorized_rows,
    manual_review_required_rows,
    decline_insufficient_evidence_rows,
    decline_policy_rows,
    policy_set_hash,
    outcome_set_hash,
    reason_set_hash,
    source_set_hash,
    decision_snapshot_set_hash,
    decision_latest_set_hash,
    decision_archive_set_hash,
    contract_set_hash,
    combined_set_hash,
    contract_status,
    generated_at,
    validated_at,
    accepted_at,
    row_hash
FROM _m2_3_registry_expected;

/* --------------------------------------------------------------------------
Canonical actual reconstruction.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_3_canonical_actual;

CREATE TEMP TABLE _m2_3_canonical_actual
(
    entity_type text NOT NULL,
    entity_key  text NOT NULL,
    row_hash    text NOT NULL,
    PRIMARY KEY(entity_type,entity_key)
)
ON COMMIT DROP;

INSERT INTO _m2_3_canonical_actual
SELECT
    'POLICY',
    policy.policy_code || '|v' || policy.policy_version::text,
    msbf_ctl.m2_3_hash_jsonb(to_jsonb(policy)-'row_hash'-'created_at'-'updated_at')
FROM msbf_ctl.m2_3_policy_profile AS policy
WHERE policy.module1_run_id = (SELECT run_id FROM _m2_3_ctx)

UNION ALL

SELECT
    'OUTCOME',
    outcome.decision_outcome_code,
    msbf_ctl.m2_3_hash_jsonb(to_jsonb(outcome)-'row_hash'-'created_at')
FROM msbf_m2.final_decision_outcome_definition AS outcome
WHERE outcome.module1_run_id = (SELECT run_id FROM _m2_3_ctx)

UNION ALL

SELECT
    'REASON',
    reason.decision_reason_code,
    msbf_ctl.m2_3_hash_jsonb(to_jsonb(reason)-'row_hash'-'created_at')
FROM msbf_m2.final_decision_reason_definition AS reason
WHERE reason.module1_run_id = (SELECT run_id FROM _m2_3_ctx)

UNION ALL

SELECT
    'SOURCE',
    source.scenario_id::text || '|' || source.merchant_application_id,
    msbf_ctl.m2_3_hash_jsonb(to_jsonb(source)-'row_hash'-'created_at')
FROM msbf_m2.application_final_decision_source_snapshot AS source
WHERE source.module1_run_id = (SELECT run_id FROM _m2_3_ctx)

UNION ALL

SELECT
    'DECISION_SNAPSHOT',
    decision.scenario_id::text || '|' || decision.merchant_application_id,
    msbf_ctl.m2_3_hash_jsonb(to_jsonb(decision)-'row_hash'-'created_at')
FROM msbf_m2.application_final_offer_decision_snapshot AS decision
WHERE decision.module1_run_id = (SELECT run_id FROM _m2_3_ctx)

UNION ALL

SELECT
    'LATEST',
    latest.scenario_id::text || '|' || latest.merchant_application_id,
    msbf_ctl.m2_3_hash_jsonb(to_jsonb(latest)-'contract_row_hash'-'created_at')
FROM msbf_m2.application_final_offer_decision_latest AS latest
WHERE latest.module1_run_id = (SELECT run_id FROM _m2_3_ctx)

UNION ALL

SELECT
    'ARCHIVE',
    archive.scenario_id::text || '|' || archive.merchant_application_id,
    msbf_ctl.m2_3_hash_jsonb(to_jsonb(archive)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at')
FROM msbf_m2.application_final_offer_decision_archive AS archive
WHERE archive.module1_run_id = (SELECT run_id FROM _m2_3_ctx)

UNION ALL

SELECT
    'REGISTRY',
    registry.contract_code || '|v' || registry.contract_version::text,
    msbf_ctl.m2_3_registry_row_hash(to_jsonb(registry))
FROM msbf_ctl.m2_3_final_decision_contract_registry AS registry
WHERE registry.module1_run_id = (SELECT run_id FROM _m2_3_ctx);

DROP TABLE IF EXISTS _m2_3_mismatch;

CREATE TEMP TABLE _m2_3_mismatch
ON COMMIT DROP
AS
SELECT
    coalesce(expected.entity_type, actual.entity_type) AS entity_type,
    coalesce(expected.entity_key, actual.entity_key) AS entity_key,
    expected.row_hash AS expected_row_hash,
    actual.row_hash AS actual_row_hash
FROM _m2_3_canonical_expected AS expected
FULL OUTER JOIN _m2_3_canonical_actual AS actual
  ON actual.entity_type = expected.entity_type
 AND actual.entity_key = expected.entity_key
WHERE expected.row_hash IS DISTINCT FROM actual.row_hash;

DO $m2_3_canonical_guard$
DECLARE
    v_expected bigint;
    v_actual bigint;
    v_mismatch bigint;
BEGIN
    SELECT count(*) INTO v_expected FROM _m2_3_canonical_expected;
    SELECT count(*) INTO v_actual FROM _m2_3_canonical_actual;
    SELECT count(*) INTO v_mismatch FROM _m2_3_mismatch;

    IF v_expected <> 6029
       OR v_actual <> 6029
       OR v_mismatch <> 0 THEN
        RAISE EXCEPTION
            'M2.3 canonical reconciliation failed: expected %, actual %, mismatches %.',
            v_expected, v_actual, v_mismatch;
    END IF;
END;
$m2_3_canonical_guard$;

/* --------------------------------------------------------------------------
Generation evidence.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_3_generation_evidence;

CREATE TEMP TABLE _m2_3_generation_evidence
(
    run_id                  bigint NOT NULL,
    evidence_code           text NOT NULL,
    segment_key             text NOT NULL,
    metric_name             text NOT NULL,
    metric_value_numeric    numeric(28,10),
    metric_value_text       text,
    unit_code               text NOT NULL,
    status                  text NOT NULL,
    interpretation          text NOT NULL,
    CHECK(num_nonnulls(metric_value_numeric,metric_value_text)=1)
)
ON COMMIT DROP;

INSERT INTO _m2_3_generation_evidence
SELECT
    registry.module1_run_id,
    evidence.evidence_code,
    'PORTFOLIO',
    evidence.metric_name,
    evidence.metric_value_numeric,
    evidence.metric_value_text,
    evidence.unit_code,
    'PASS',
    evidence.interpretation
FROM _m2_3_registry_expected AS registry
CROSS JOIN LATERAL
(
    VALUES
    ('M2_3_POLICY_SET_HASH','POLICY_SET_HASH',NULL::numeric(28,10),registry.policy_set_hash,'HASH','M2.3 policy set hash.'),
    ('M2_3_OUTCOME_SET_HASH','OUTCOME_SET_HASH',NULL::numeric(28,10),registry.outcome_set_hash,'HASH','Decision outcome definition set hash.'),
    ('M2_3_REASON_SET_HASH','REASON_SET_HASH',NULL::numeric(28,10),registry.reason_set_hash,'HASH','Final decision reason set hash.'),
    ('M2_3_SOURCE_SET_HASH','SOURCE_SET_HASH',NULL::numeric(28,10),registry.source_set_hash,'HASH','M2.2 source snapshot set hash.'),
    ('M2_3_DECISION_SNAPSHOT_SET_HASH','DECISION_SNAPSHOT_SET_HASH',NULL::numeric(28,10),registry.decision_snapshot_set_hash,'HASH','Final-decision snapshot set hash.'),
    ('M2_3_LATEST_SET_HASH','DECISION_LATEST_SET_HASH',NULL::numeric(28,10),registry.decision_latest_set_hash,'HASH','Final-decision latest contract set hash.'),
    ('M2_3_ARCHIVE_SET_HASH','DECISION_ARCHIVE_SET_HASH',NULL::numeric(28,10),registry.decision_archive_set_hash,'HASH','Final-decision archive set hash.'),
    ('M2_3_CONTRACT_SET_HASH','CONTRACT_SET_HASH',NULL::numeric(28,10),registry.contract_set_hash,'HASH','Final-decision registry contract set hash.'),
    ('M2_3_COMBINED_SET_HASH','COMBINED_SET_HASH',NULL::numeric(28,10),registry.combined_set_hash,'HASH','Complete M2.3 combined canonical set hash.'),
    ('M2_3_SOURCE_ROW_COUNT','SOURCE_ROW_COUNT',registry.source_rows::numeric(28,10),NULL::text,'ROWS','M2.2 source rows consumed.'),
    ('M2_3_DECISION_ROW_COUNT','DECISION_ROW_COUNT',registry.decision_snapshot_rows::numeric(28,10),NULL::text,'ROWS','Final-decision rows generated.'),
    ('M2_3_LATEST_ROW_COUNT','LATEST_ROW_COUNT',registry.decision_latest_rows::numeric(28,10),NULL::text,'ROWS','Latest contract rows generated.'),
    ('M2_3_ARCHIVE_ROW_COUNT','ARCHIVE_ROW_COUNT',registry.decision_archive_rows::numeric(28,10),NULL::text,'ROWS','Immutable archive rows generated.'),
    ('M2_3_FINAL_OFFER_ROW_COUNT','FINAL_OFFER_ROW_COUNT',registry.final_offer_authorized_rows::numeric(28,10),NULL::text,'ROWS','Final offer authorization rows.'),
    ('M2_3_MANUAL_REVIEW_ROW_COUNT','MANUAL_REVIEW_ROW_COUNT',registry.manual_review_required_rows::numeric(28,10),NULL::text,'ROWS','Manual-review authorization rows.'),
    ('M2_3_INSUFFICIENT_DECLINE_ROW_COUNT','INSUFFICIENT_DECLINE_ROW_COUNT',registry.decline_insufficient_evidence_rows::numeric(28,10),NULL::text,'ROWS','Insufficient evidence decline rows.'),
    ('M2_3_POLICY_DECLINE_ROW_COUNT','POLICY_DECLINE_ROW_COUNT',registry.decline_policy_rows::numeric(28,10),NULL::text,'ROWS','Policy decline rows.'),
    ('M2_3_COMPARISON_ROW_COUNT','COMPARISON_ROW_COUNT',registry.comparison_rows::numeric(28,10),NULL::text,'ROWS','Matched baseline/stress comparison rows.'),
    ('M2_3_CANONICAL_ENTITY_COUNT','CANONICAL_ENTITY_COUNT',registry.canonical_entities::numeric(28,10),NULL::text,'ROWS','Canonical entities generated.'),
    ('M2_3_SOURCE_M2_2_HASH','SOURCE_M2_2_COMBINED_HASH',NULL::numeric(28,10),registry.source_m2_2_combined_hash,'HASH','Accepted M2.2 source hash preserved.')
) AS evidence
(
    evidence_code,
    metric_name,
    metric_value_numeric,
    metric_value_text,
    unit_code,
    interpretation
);

INSERT INTO msbf_ctl.run_evidence
(
    run_id,
    evidence_code,
    segment_key,
    metric_name,
    metric_value_numeric,
    metric_value_text,
    unit_code,
    status,
    interpretation
)
SELECT
    run_id,
    evidence_code,
    segment_key,
    metric_name,
    metric_value_numeric,
    metric_value_text,
    unit_code,
    status,
    interpretation
FROM _m2_3_generation_evidence;

UPDATE msbf_ctl.run_registry AS run
SET
    run_status = 'M2_3_GENERATED',
    notes = coalesce(run.notes,'') ||
        ' | M2.3 final offer and decision authorization generated.'
WHERE run.run_id = (SELECT run_id FROM _m2_3_ctx);

INSERT INTO _m2_3_result
SELECT
    registry.module1_run_id,
    'M2_3_GENERATED',
    registry.policy_rows,
    registry.outcome_rows,
    registry.reason_rows,
    registry.source_rows,
    registry.decision_snapshot_rows,
    registry.decision_latest_rows,
    registry.decision_archive_rows,
    registry.comparison_rows,
    registry.registry_rows,
    registry.final_offer_authorized_rows,
    registry.manual_review_required_rows,
    registry.decline_insufficient_evidence_rows,
    registry.decline_policy_rows,
    6029,
    (SELECT count(*) FROM _m2_3_canonical_actual),
    (SELECT count(*) FROM _m2_3_mismatch),
    registry.policy_set_hash,
    registry.outcome_set_hash,
    registry.reason_set_hash,
    registry.source_set_hash,
    registry.decision_snapshot_set_hash,
    registry.decision_latest_set_hash,
    registry.decision_archive_set_hash,
    registry.contract_set_hash,
    registry.combined_set_hash,
    'PASS'
FROM msbf_ctl.m2_3_final_decision_contract_registry AS registry
WHERE registry.module1_run_id = (SELECT run_id FROM _m2_3_ctx);

COMMIT;

SELECT
    run_id,
    run_status,
    policy_rows,
    outcome_rows,
    reason_rows,
    source_rows,
    decision_snapshot_rows,
    decision_latest_rows,
    decision_archive_rows,
    comparison_rows,
    registry_rows,
    final_offer_authorized_rows,
    manual_review_required_rows,
    decline_insufficient_evidence_rows,
    decline_policy_rows,
    expected_canonical_entities,
    actual_canonical_entities,
    row_level_mismatches,
    policy_set_hash,
    outcome_set_hash,
    reason_set_hash,
    source_set_hash,
    decision_snapshot_set_hash,
    decision_latest_set_hash,
    decision_archive_set_hash,
    contract_set_hash,
    combined_set_hash,
    generation_status
FROM _m2_3_result;
