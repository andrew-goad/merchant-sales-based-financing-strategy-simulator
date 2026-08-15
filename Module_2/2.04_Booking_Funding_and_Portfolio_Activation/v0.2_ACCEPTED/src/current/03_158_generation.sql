/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.4 — Booking, Funding & Portfolio Activation

Program     : 158_msbf_m2_4_booking_funding_activation_generation_v0_2.sql
Version     : v0.2
Purpose     : Materialize the accepted M2.3 final-decision contract once;
              create deterministic synthetic booking, funding, account,
              advance and initial portfolio activation evidence; publish latest
              and immutable archive contracts; reconcile 6,212 canonical
              entities; and commit only after all physical identities pass.

Performance :
- Accepted M2.3 source is materialized once.
- Every hash-bearing staging table is target typed before hashing.
- Expensive intermediates are materialized once, indexed and ANALYZED.
- Explicit joins only; no USING joins or alias-star projections.
- Generation is separated from read-only validation and reporting.

Boundary    : All operational outputs are synthetic. No real funds movement,
              bank/settlement identifier, external transmission, or production
              adverse-action notice is created.
============================================================================ */

BEGIN;

SET LOCAL work_mem = '160MB';
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '50min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m2_4_result;

CREATE TEMP TABLE _m2_4_result
(
    run_id                              bigint,
    run_status                          text,
    policy_rows                         bigint,
    outcome_rows                        bigint,
    reason_rows                         bigint,
    notice_control_rows                 bigint,
    source_rows                         bigint,
    activation_snapshot_rows            bigint,
    activation_latest_rows              bigint,
    activation_archive_rows             bigint,
    account_rows                        bigint,
    advance_rows                        bigint,
    portfolio_rows                      bigint,
    comparison_rows                     bigint,
    registry_rows                       bigint,
    activated_rows                      bigint,
    review_required_rows                bigint,
    not_activated_insufficient_rows      bigint,
    not_activated_policy_rows            bigint,
    expected_canonical_entities          bigint,
    actual_canonical_entities            bigint,
    row_level_mismatches                 bigint,
    stress_activation_improvements       bigint,
    stress_funded_amount_improvements    bigint,
    policy_set_hash                      text,
    outcome_set_hash                     text,
    reason_set_hash                      text,
    notice_control_set_hash              text,
    source_set_hash                      text,
    activation_snapshot_set_hash         text,
    activation_latest_set_hash           text,
    activation_archive_set_hash          text,
    account_set_hash                     text,
    advance_set_hash                     text,
    portfolio_set_hash                   text,
    contract_set_hash                    text,
    combined_set_hash                    text,
    generation_status                    text
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_4_ctx;

CREATE TEMP TABLE _m2_4_ctx
ON COMMIT DROP
AS
SELECT
    run.run_id,
    policy.configuration_hash,
    policy.booking_lag_days,
    policy.funding_lag_days,
    policy.first_remittance_lag_days,
    policy.monitoring_start_lag_days,
    policy.expected_canonical_entities
FROM msbf_ctl.run_registry AS run
JOIN msbf_ctl.m2_4_policy_profile AS policy
  ON policy.module1_run_id = run.run_id
WHERE run.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND run.run_version = 1;

CREATE UNIQUE INDEX ON _m2_4_ctx(run_id);
ANALYZE _m2_4_ctx;

DO $m2_4_generation_ready$
BEGIN
    PERFORM msbf_ctl.m2_4_assert_generation_ready
    (
        (SELECT run_id FROM _m2_4_ctx)
    );
END;
$m2_4_generation_ready$;

/* --------------------------------------------------------------------------
Materialize the accepted M2.3 source exactly once.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_4_source_input;

CREATE TEMP TABLE _m2_4_source_input
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
    latest.primary_decision_reason_code,
    latest.contract_row_hash AS source_m2_3_contract_row_hash,
    latest.source_m2_2_contract_row_hash,
    latest.source_g2_combined_hash,
    to_jsonb(latest) AS source_payload
FROM msbf_m2.application_final_offer_decision_latest AS latest
WHERE latest.module1_run_id = (SELECT run_id FROM _m2_4_ctx);

CREATE UNIQUE INDEX
ON _m2_4_source_input(module1_run_id,scenario_id,merchant_application_id);

ANALYZE _m2_4_source_input;

/* --------------------------------------------------------------------------
Target-typed M2.4 source snapshot.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_4_source_expected;

CREATE TEMP TABLE _m2_4_source_expected
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
    row_hash                          text
)
ON COMMIT DROP;

INSERT INTO _m2_4_source_expected
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
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
    primary_decision_reason_code,
    source_m2_3_contract_row_hash,
    source_m2_2_contract_row_hash,
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
    source.final_decision_outcome_code,
    source.final_decision_rank,
    source.final_offer_authorized_flag,
    source.counteroffer_review_required_flag,
    source.decline_authorized_flag,
    source.manual_review_required_flag,
    source.final_offer_amount::numeric(18,2),
    source.final_remittance_rate::numeric(9,6),
    source.final_payback_multiple::numeric(9,6),
    source.final_collection_horizon_days::integer,
    source.final_total_repayment_amount::numeric(18,2),
    source.final_finance_charge_amount::numeric(18,2),
    source.final_implied_daily_collection_amount::numeric(18,2),
    source.final_implied_payoff_days::numeric(18,4),
    source.primary_decision_reason_code,
    source.source_m2_3_contract_row_hash,
    source.source_m2_2_contract_row_hash,
    source.source_g2_combined_hash,
    source.source_payload,
    NULL::text
FROM _m2_4_source_input AS source;

UPDATE _m2_4_source_expected AS source
SET row_hash = msbf_ctl.m2_4_hash_jsonb
(
    to_jsonb(source) - 'row_hash'
)
WHERE source.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_4_source_expected(module1_run_id,scenario_id,merchant_application_id);

ANALYZE _m2_4_source_expected;

DO $m2_4_source_guard$
DECLARE
    v record;
BEGIN
    SELECT
        count(*) AS rows,
        count(*) FILTER
        (
            WHERE final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
        ) AS final_offer_rows,
        count(*) FILTER
        (
            WHERE final_decision_outcome_code = 'COUNTEROFFER_REVIEW_REQUIRED'
        ) AS review_rows,
        count(*) FILTER
        (
            WHERE final_decision_outcome_code = 'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED'
        ) AS insufficient_rows,
        count(*) FILTER
        (
            WHERE final_decision_outcome_code = 'DECLINE_POLICY_AUTHORIZED'
        ) AS policy_rows,
        count(*) FILTER
        (
            WHERE row_hash IS NULL
        ) AS missing_hashes
    INTO v
    FROM _m2_4_source_expected;

    IF v.rows <> 1500
       OR v.final_offer_rows <> 59
       OR v.review_rows <> 190
       OR v.insufficient_rows <> 178
       OR v.policy_rows <> 1073
       OR v.missing_hashes <> 0 THEN
        RAISE EXCEPTION
            'M2.4 source materialization failed: %',
            row_to_json(v);
    END IF;
END;
$m2_4_source_guard$;

INSERT INTO msbf_m2.application_booking_funding_source_snapshot
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
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
    primary_decision_reason_code,
    source_m2_3_contract_row_hash,
    source_m2_2_contract_row_hash,
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
    primary_decision_reason_code,
    source_m2_3_contract_row_hash,
    source_m2_2_contract_row_hash,
    source_g2_combined_hash,
    source_payload,
    row_hash
FROM _m2_4_source_expected;

/* --------------------------------------------------------------------------
Target-typed activation outcome.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_4_activation_expected;

CREATE TEMP TABLE _m2_4_activation_expected
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
    row_hash                             text
)
ON COMMIT DROP;

INSERT INTO _m2_4_activation_expected
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_final_decision_outcome_code,
    activation_outcome_code,
    activation_outcome_rank,
    booking_eligible_flag,
    booking_authorized_flag,
    funding_authorized_flag,
    funding_completed_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    synthetic_offer_acceptance_assumed_flag,
    real_funds_movement_flag,
    external_notice_generation_authorized_flag,
    external_notice_transmitted_flag,
    production_adverse_action_notice_flag,
    synthetic_account_id,
    synthetic_advance_id,
    booked_amount,
    funded_amount,
    activation_remittance_rate,
    activation_payback_multiple,
    activation_collection_horizon_days,
    activation_total_repayment_amount,
    activation_finance_charge_amount,
    activation_implied_daily_collection_amount,
    activation_implied_payoff_days,
    booking_date,
    funding_date,
    portfolio_activation_date,
    first_expected_remittance_date,
    monitoring_start_date,
    activation_evidence_status,
    notice_control_code,
    primary_activation_reason_code,
    activation_reason_codes,
    source_m2_3_contract_row_hash,
    source_m2_2_contract_row_hash,
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
    source.final_decision_outcome_code,
    CASE source.final_decision_outcome_code
        WHEN 'FINAL_OFFER_AUTHORIZED'
            THEN 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED'
        WHEN 'COUNTEROFFER_REVIEW_REQUIRED'
            THEN 'ACTIVATION_REVIEW_REQUIRED'
        WHEN 'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED'
            THEN 'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE'
        WHEN 'DECLINE_POLICY_AUTHORIZED'
            THEN 'NOT_ACTIVATED_POLICY_DECLINE'
        ELSE 'NO_ACTIVATION_SOURCE_BOUNDARY'
    END,
    CASE source.final_decision_outcome_code
        WHEN 'FINAL_OFFER_AUTHORIZED' THEN 1
        WHEN 'COUNTEROFFER_REVIEW_REQUIRED' THEN 2
        WHEN 'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED' THEN 3
        WHEN 'DECLINE_POLICY_AUTHORIZED' THEN 4
        ELSE 9
    END,
    (source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'),
    (source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'),
    (source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'),
    (source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'),
    (source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'),
    (source.final_decision_outcome_code = 'COUNTEROFFER_REVIEW_REQUIRED'),
    (source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'),
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    CASE
        WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
        THEN 'MSBF_ACCT_' || upper(substr(md5(
            source.module1_run_id::text || '|' ||
            source.scenario_id::text || '|' ||
            source.merchant_application_id || '|ACCOUNT'
        ),1,20))
        ELSE NULL::text
    END,
    CASE
        WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
        THEN 'MSBF_ADV_' || upper(substr(md5(
            source.module1_run_id::text || '|' ||
            source.scenario_id::text || '|' ||
            source.merchant_application_id || '|ADVANCE'
        ),1,20))
        ELSE NULL::text
    END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.final_offer_amount ELSE NULL::numeric(18,2) END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.final_offer_amount ELSE NULL::numeric(18,2) END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.final_remittance_rate ELSE NULL::numeric(9,6) END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.final_payback_multiple ELSE NULL::numeric(9,6) END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.final_collection_horizon_days ELSE NULL::integer END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.final_total_repayment_amount ELSE NULL::numeric(18,2) END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.final_finance_charge_amount ELSE NULL::numeric(18,2) END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.final_implied_daily_collection_amount ELSE NULL::numeric(18,2) END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.final_implied_payoff_days ELSE NULL::numeric(18,4) END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.as_of_date + ctx.booking_lag_days ELSE NULL::date END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.as_of_date + ctx.funding_lag_days ELSE NULL::date END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.as_of_date + ctx.funding_lag_days ELSE NULL::date END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.as_of_date + ctx.first_remittance_lag_days ELSE NULL::date END,
    CASE WHEN source.final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED'
         THEN source.as_of_date + ctx.monitoring_start_lag_days ELSE NULL::date END,
    CASE source.final_decision_outcome_code
        WHEN 'FINAL_OFFER_AUTHORIZED' THEN 'ACTIVATED'
        WHEN 'COUNTEROFFER_REVIEW_REQUIRED' THEN 'REVIEW_REQUIRED'
        WHEN 'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED' THEN 'NOT_ACTIVATED'
        WHEN 'DECLINE_POLICY_AUTHORIZED' THEN 'NOT_ACTIVATED'
        ELSE 'BLOCKED'
    END,
    CASE source.final_decision_outcome_code
        WHEN 'FINAL_OFFER_AUTHORIZED'
            THEN 'FUNDING_CONFIRMATION_INTERNAL_ONLY'
        WHEN 'COUNTEROFFER_REVIEW_REQUIRED'
            THEN 'ACTIVATION_REVIEW_INTERNAL_ONLY'
        WHEN 'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED'
            THEN 'DECLINE_NOTICE_SUPPRESSED_SYNTHETIC'
        WHEN 'DECLINE_POLICY_AUTHORIZED'
            THEN 'DECLINE_NOTICE_SUPPRESSED_SYNTHETIC'
        ELSE 'NO_NOTICE_SOURCE_BOUNDARY'
    END,
    CASE source.final_decision_outcome_code
        WHEN 'FINAL_OFFER_AUTHORIZED' THEN 'M2_4_ADVANCE_ACTIVATED'
        WHEN 'COUNTEROFFER_REVIEW_REQUIRED' THEN 'M2_4_ACTIVATION_REVIEW_REQUIRED'
        WHEN 'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED' THEN 'M2_4_INSUFFICIENT_EVIDENCE_NOT_ACTIVATED'
        WHEN 'DECLINE_POLICY_AUTHORIZED' THEN 'M2_4_POLICY_DECLINE_NOT_ACTIVATED'
        ELSE 'M2_4_FALLBACK_REVIEW'
    END,
    CASE source.final_decision_outcome_code
        WHEN 'FINAL_OFFER_AUTHORIZED' THEN jsonb_build_array
        (
            'M2_4_ADVANCE_ACTIVATED',
            'M2_4_SOURCE_M2_3_ACCEPTED',
            'M2_4_SYNTHETIC_ACCEPTANCE_ASSUMED',
            'M2_4_BOOKING_CONTROL_PASS',
            'M2_4_FUNDING_CONTROL_PASS',
            'M2_4_ACCOUNT_ACTIVATED',
            'M2_4_ADVANCE_FUNDED',
            'M2_4_PORTFOLIO_ACTIVATED',
            'M2_4_FIRST_REMITTANCE_SCHEDULED',
            'M2_4_NOTICE_INTERNAL_ONLY',
            'M2_4_NO_REAL_FUNDS_MOVEMENT',
            'M2_4_NO_EXTERNAL_TRANSMISSION',
            'M2_4_SOURCE_LINEAGE',
            'M2_4_MATCHED_SCENARIO_GUARD'
        )
        WHEN 'COUNTEROFFER_REVIEW_REQUIRED' THEN jsonb_build_array
        (
            'M2_4_ACTIVATION_REVIEW_REQUIRED',
            'M2_4_REVIEW_EXCEPTION_ROUTE',
            'M2_4_REVIEW_NOTICE_INTERNAL_ONLY'
        )
        WHEN 'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED' THEN jsonb_build_array
        (
            'M2_4_INSUFFICIENT_EVIDENCE_NOT_ACTIVATED',
            'M2_4_INSUFFICIENT_NOTICE_SUPPRESSED',
            'M2_4_INSUFFICIENT_NO_PRODUCTION_ADVERSE_ACTION'
        )
        WHEN 'DECLINE_POLICY_AUTHORIZED' THEN jsonb_build_array
        (
            'M2_4_POLICY_DECLINE_NOT_ACTIVATED',
            'M2_4_DECLINE_NOTICE_SUPPRESSED',
            'M2_4_NO_PRODUCTION_ADVERSE_ACTION'
        )
        ELSE jsonb_build_array
        (
            'M2_4_FALLBACK_REVIEW'
        )
    END,
    source.source_m2_3_contract_row_hash,
    source.source_m2_2_contract_row_hash,
    source.source_g2_combined_hash,
    source.row_hash,
    ctx.configuration_hash,
    NULL::text
FROM _m2_4_source_expected AS source
CROSS JOIN _m2_4_ctx AS ctx;

UPDATE _m2_4_activation_expected AS activation
SET row_hash = msbf_ctl.m2_4_hash_jsonb
(
    to_jsonb(activation) - 'row_hash'
)
WHERE activation.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_4_activation_expected(module1_run_id,scenario_id,merchant_application_id);

CREATE INDEX
ON _m2_4_activation_expected(module1_run_id,activation_outcome_code,scenario_code);

ANALYZE _m2_4_activation_expected;

DO $m2_4_activation_guard$
DECLARE
    v record;
BEGIN
    SELECT
        count(*) AS rows,
        count(*) FILTER
        (
            WHERE activation_outcome_code = 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED'
        ) AS activated_rows,
        count(*) FILTER
        (
            WHERE activation_outcome_code = 'ACTIVATION_REVIEW_REQUIRED'
        ) AS review_rows,
        count(*) FILTER
        (
            WHERE activation_outcome_code = 'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE'
        ) AS insufficient_rows,
        count(*) FILTER
        (
            WHERE activation_outcome_code = 'NOT_ACTIVATED_POLICY_DECLINE'
        ) AS policy_rows,
        count(*) FILTER
        (
            WHERE portfolio_activated_flag
              AND
              (
                  synthetic_account_id IS NULL
                  OR synthetic_advance_id IS NULL
                  OR funded_amount IS NULL
                  OR booking_date IS NULL
                  OR funding_date IS NULL
                  OR portfolio_activation_date IS NULL
              )
        ) AS incomplete_activated_rows,
        count(*) FILTER
        (
            WHERE NOT portfolio_activated_flag
              AND
              (
                  synthetic_account_id IS NOT NULL
                  OR synthetic_advance_id IS NOT NULL
                  OR funded_amount IS NOT NULL
                  OR booking_date IS NOT NULL
                  OR funding_date IS NOT NULL
                  OR portfolio_activation_date IS NOT NULL
              )
        ) AS prohibited_nonactivated_values,
        count(*) FILTER
        (
            WHERE activation.real_funds_movement_flag
               OR activation.external_notice_generation_authorized_flag
               OR activation.external_notice_transmitted_flag
               OR activation.production_adverse_action_notice_flag
        ) AS boundary_violations,
        count(*) FILTER
        (
            WHERE EXISTS
            (
                SELECT 1
                FROM jsonb_array_elements_text
                     (activation.activation_reason_codes) AS reason_value
                WHERE NOT EXISTS
                (
                    SELECT 1
                    FROM msbf_m2.booking_funding_reason_definition AS reason
                    WHERE reason.module1_run_id = activation.module1_run_id
                      AND reason.activation_reason_code = reason_value.value
                      AND reason.mapped_activation_outcome_code =
                          activation.activation_outcome_code
                )
            )
        ) AS reason_mapping_violations,
        count(*) FILTER (WHERE activation.row_hash IS NULL) AS missing_hashes
    INTO v
    FROM _m2_4_activation_expected AS activation;

    IF v.rows <> 1500
       OR v.activated_rows <> 59
       OR v.review_rows <> 190
       OR v.insufficient_rows <> 178
       OR v.policy_rows <> 1073
       OR v.incomplete_activated_rows <> 0
       OR v.prohibited_nonactivated_values <> 0
       OR v.boundary_violations <> 0
       OR v.reason_mapping_violations <> 0
       OR v.missing_hashes <> 0 THEN
        RAISE EXCEPTION
            'M2.4 activation mapping failed: %',
            row_to_json(v);
    END IF;
END;
$m2_4_activation_guard$;

INSERT INTO msbf_m2.application_booking_funding_activation_snapshot
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_final_decision_outcome_code,
    activation_outcome_code,
    activation_outcome_rank,
    booking_eligible_flag,
    booking_authorized_flag,
    funding_authorized_flag,
    funding_completed_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    synthetic_offer_acceptance_assumed_flag,
    real_funds_movement_flag,
    external_notice_generation_authorized_flag,
    external_notice_transmitted_flag,
    production_adverse_action_notice_flag,
    synthetic_account_id,
    synthetic_advance_id,
    booked_amount,
    funded_amount,
    activation_remittance_rate,
    activation_payback_multiple,
    activation_collection_horizon_days,
    activation_total_repayment_amount,
    activation_finance_charge_amount,
    activation_implied_daily_collection_amount,
    activation_implied_payoff_days,
    booking_date,
    funding_date,
    portfolio_activation_date,
    first_expected_remittance_date,
    monitoring_start_date,
    activation_evidence_status,
    notice_control_code,
    primary_activation_reason_code,
    activation_reason_codes,
    source_m2_3_contract_row_hash,
    source_m2_2_contract_row_hash,
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
    source_final_decision_outcome_code,
    activation_outcome_code,
    activation_outcome_rank,
    booking_eligible_flag,
    booking_authorized_flag,
    funding_authorized_flag,
    funding_completed_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    synthetic_offer_acceptance_assumed_flag,
    real_funds_movement_flag,
    external_notice_generation_authorized_flag,
    external_notice_transmitted_flag,
    production_adverse_action_notice_flag,
    synthetic_account_id,
    synthetic_advance_id,
    booked_amount,
    funded_amount,
    activation_remittance_rate,
    activation_payback_multiple,
    activation_collection_horizon_days,
    activation_total_repayment_amount,
    activation_finance_charge_amount,
    activation_implied_daily_collection_amount,
    activation_implied_payoff_days,
    booking_date,
    funding_date,
    portfolio_activation_date,
    first_expected_remittance_date,
    monitoring_start_date,
    activation_evidence_status,
    notice_control_code,
    primary_activation_reason_code,
    activation_reason_codes,
    source_m2_3_contract_row_hash,
    source_m2_2_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    policy_configuration_hash,
    row_hash
FROM _m2_4_activation_expected;

/* --------------------------------------------------------------------------
Synthetic account, advance and portfolio objects — activated rows only.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_4_account_expected;

CREATE TEMP TABLE _m2_4_account_expected
(
    module1_run_id              bigint NOT NULL,
    scenario_id                 bigint NOT NULL,
    scenario_code               text NOT NULL,
    merchant_application_id      text NOT NULL,
    synthetic_account_id         text NOT NULL,
    account_status               text NOT NULL,
    account_open_date            date NOT NULL,
    source_activation_row_hash   text NOT NULL,
    row_hash                     text
)
ON COMMIT DROP;

INSERT INTO _m2_4_account_expected
SELECT
    activation.module1_run_id,
    activation.scenario_id,
    activation.scenario_code,
    activation.merchant_application_id,
    activation.synthetic_account_id,
    'ACTIVE',
    activation.portfolio_activation_date,
    activation.row_hash,
    NULL::text
FROM _m2_4_activation_expected AS activation
WHERE activation.portfolio_activated_flag;

UPDATE _m2_4_account_expected AS account
SET row_hash = msbf_ctl.m2_4_hash_jsonb
(
    to_jsonb(account) - 'row_hash'
)
WHERE account.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_4_account_expected(module1_run_id,scenario_id,merchant_application_id);

CREATE UNIQUE INDEX
ON _m2_4_account_expected(module1_run_id,synthetic_account_id);

ANALYZE _m2_4_account_expected;

INSERT INTO msbf_m2.synthetic_account_activation
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    synthetic_account_id,
    account_status,
    account_open_date,
    source_activation_row_hash,
    row_hash
)
SELECT
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    synthetic_account_id,
    account_status,
    account_open_date,
    source_activation_row_hash,
    row_hash
FROM _m2_4_account_expected;

DROP TABLE IF EXISTS _m2_4_advance_expected;

CREATE TEMP TABLE _m2_4_advance_expected
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
    row_hash                          text
)
ON COMMIT DROP;

INSERT INTO _m2_4_advance_expected
SELECT
    activation.module1_run_id,
    activation.scenario_id,
    activation.scenario_code,
    activation.merchant_application_id,
    activation.synthetic_account_id,
    activation.synthetic_advance_id,
    activation.booked_amount,
    activation.funded_amount,
    activation.activation_remittance_rate,
    activation.activation_payback_multiple,
    activation.activation_collection_horizon_days,
    activation.activation_total_repayment_amount,
    activation.activation_finance_charge_amount,
    activation.activation_implied_daily_collection_amount,
    activation.activation_implied_payoff_days,
    activation.funding_date,
    activation.first_expected_remittance_date,
    'SYNTHETIC_FUNDED',
    FALSE,
    activation.row_hash,
    NULL::text
FROM _m2_4_activation_expected AS activation
WHERE activation.portfolio_activated_flag;

UPDATE _m2_4_advance_expected AS advance
SET row_hash = msbf_ctl.m2_4_hash_jsonb
(
    to_jsonb(advance) - 'row_hash'
)
WHERE advance.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_4_advance_expected(module1_run_id,scenario_id,merchant_application_id);

CREATE UNIQUE INDEX
ON _m2_4_advance_expected(module1_run_id,synthetic_advance_id);

ANALYZE _m2_4_advance_expected;

INSERT INTO msbf_m2.synthetic_advance_funding
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    synthetic_account_id,
    synthetic_advance_id,
    booked_amount,
    funded_amount,
    remittance_rate,
    payback_multiple,
    collection_horizon_days,
    total_repayment_amount,
    finance_charge_amount,
    implied_daily_collection_amount,
    implied_payoff_days,
    funding_date,
    first_expected_remittance_date,
    funding_status,
    real_funds_movement_flag,
    source_activation_row_hash,
    row_hash
)
SELECT
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    synthetic_account_id,
    synthetic_advance_id,
    booked_amount,
    funded_amount,
    remittance_rate,
    payback_multiple,
    collection_horizon_days,
    total_repayment_amount,
    finance_charge_amount,
    implied_daily_collection_amount,
    implied_payoff_days,
    funding_date,
    first_expected_remittance_date,
    funding_status,
    real_funds_movement_flag,
    source_activation_row_hash,
    row_hash
FROM _m2_4_advance_expected;

DROP TABLE IF EXISTS _m2_4_portfolio_expected;

CREATE TEMP TABLE _m2_4_portfolio_expected
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
    row_hash                          text
)
ON COMMIT DROP;

INSERT INTO _m2_4_portfolio_expected
SELECT
    activation.module1_run_id,
    activation.scenario_id,
    activation.scenario_code,
    activation.merchant_application_id,
    activation.synthetic_account_id,
    activation.synthetic_advance_id,
    'ACTIVE',
    activation.portfolio_activation_date,
    activation.monitoring_start_date,
    activation.funded_amount,
    activation.funded_amount,
    activation.funded_amount,
    activation.activation_total_repayment_amount,
    advance.row_hash,
    NULL::text
FROM _m2_4_activation_expected AS activation
JOIN _m2_4_advance_expected AS advance
  ON advance.module1_run_id = activation.module1_run_id
 AND advance.scenario_id = activation.scenario_id
 AND advance.merchant_application_id = activation.merchant_application_id
WHERE activation.portfolio_activated_flag;

UPDATE _m2_4_portfolio_expected AS portfolio
SET row_hash = msbf_ctl.m2_4_hash_jsonb
(
    to_jsonb(portfolio) - 'row_hash'
)
WHERE portfolio.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_4_portfolio_expected(module1_run_id,scenario_id,merchant_application_id);

CREATE UNIQUE INDEX
ON _m2_4_portfolio_expected(module1_run_id,synthetic_advance_id);

ANALYZE _m2_4_portfolio_expected;

DO $m2_4_activation_object_guard$
DECLARE
    v record;
BEGIN
    SELECT
        (SELECT count(*) FROM _m2_4_account_expected) AS account_rows,
        (SELECT count(*) FROM _m2_4_advance_expected) AS advance_rows,
        (SELECT count(*) FROM _m2_4_portfolio_expected) AS portfolio_rows,
        (SELECT count(*) FROM _m2_4_account_expected WHERE row_hash IS NULL) AS account_missing_hashes,
        (SELECT count(*) FROM _m2_4_advance_expected WHERE row_hash IS NULL OR real_funds_movement_flag) AS advance_violations,
        (SELECT count(*) FROM _m2_4_portfolio_expected WHERE row_hash IS NULL) AS portfolio_missing_hashes
    INTO v;

    IF v.account_rows <> 59
       OR v.advance_rows <> 59
       OR v.portfolio_rows <> 59
       OR v.account_missing_hashes <> 0
       OR v.advance_violations <> 0
       OR v.portfolio_missing_hashes <> 0 THEN
        RAISE EXCEPTION
            'M2.4 account/advance/portfolio generation failed: %',
            row_to_json(v);
    END IF;
END;
$m2_4_activation_object_guard$;

INSERT INTO msbf_m2.initial_portfolio_activation
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    synthetic_account_id,
    synthetic_advance_id,
    portfolio_status,
    portfolio_activation_date,
    monitoring_start_date,
    original_funded_amount,
    current_outstanding_balance_proxy,
    initial_exposure_amount,
    initial_expected_collection_amount,
    source_advance_row_hash,
    row_hash
)
SELECT
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    synthetic_account_id,
    synthetic_advance_id,
    portfolio_status,
    portfolio_activation_date,
    monitoring_start_date,
    original_funded_amount,
    current_outstanding_balance_proxy,
    initial_exposure_amount,
    initial_expected_collection_amount,
    source_advance_row_hash,
    row_hash
FROM _m2_4_portfolio_expected;

/* --------------------------------------------------------------------------
Latest and immutable archive activation contracts.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_4_latest_expected;

CREATE TEMP TABLE _m2_4_latest_expected
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
    contract_row_hash                    text
)
ON COMMIT DROP;

INSERT INTO _m2_4_latest_expected
SELECT
    activation.module1_run_id,
    'M2_PORTFOLIO_ACTIVATION_CONSUMPTION',
    1,
    'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1',
    'M2_4_METHOD_V1',
    activation.scenario_id,
    activation.scenario_code,
    activation.merchant_application_id,
    activation.population_id,
    activation.merchant_id,
    activation.as_of_date,
    activation.source_final_decision_outcome_code,
    activation.activation_outcome_code,
    activation.activation_outcome_rank,
    activation.booking_eligible_flag,
    activation.booking_authorized_flag,
    activation.funding_authorized_flag,
    activation.funding_completed_flag,
    activation.portfolio_activated_flag,
    activation.operational_review_required_flag,
    activation.synthetic_offer_acceptance_assumed_flag,
    activation.real_funds_movement_flag,
    activation.external_notice_generation_authorized_flag,
    activation.external_notice_transmitted_flag,
    activation.production_adverse_action_notice_flag,
    activation.synthetic_account_id,
    activation.synthetic_advance_id,
    activation.booked_amount,
    activation.funded_amount,
    activation.activation_remittance_rate,
    activation.activation_payback_multiple,
    activation.activation_collection_horizon_days,
    activation.activation_total_repayment_amount,
    activation.activation_finance_charge_amount,
    activation.activation_implied_daily_collection_amount,
    activation.activation_implied_payoff_days,
    activation.booking_date,
    activation.funding_date,
    activation.portfolio_activation_date,
    activation.first_expected_remittance_date,
    activation.monitoring_start_date,
    activation.activation_evidence_status,
    activation.notice_control_code,
    activation.primary_activation_reason_code,
    activation.activation_reason_codes,
    activation.source_m2_3_contract_row_hash,
    activation.source_m2_2_contract_row_hash,
    activation.source_g2_combined_hash,
    activation.source_snapshot_row_hash,
    activation.row_hash,
    activation.policy_configuration_hash,
    NULL::text
FROM _m2_4_activation_expected AS activation;

UPDATE _m2_4_latest_expected AS latest
SET contract_row_hash = msbf_ctl.m2_4_hash_jsonb
(
    to_jsonb(latest) - 'contract_row_hash'
)
WHERE latest.contract_row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_4_latest_expected(module1_run_id,scenario_id,merchant_application_id);

ANALYZE _m2_4_latest_expected;

INSERT INTO msbf_m2.application_booking_funding_activation_latest
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
    source_final_decision_outcome_code,
    activation_outcome_code,
    activation_outcome_rank,
    booking_eligible_flag,
    booking_authorized_flag,
    funding_authorized_flag,
    funding_completed_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    synthetic_offer_acceptance_assumed_flag,
    real_funds_movement_flag,
    external_notice_generation_authorized_flag,
    external_notice_transmitted_flag,
    production_adverse_action_notice_flag,
    synthetic_account_id,
    synthetic_advance_id,
    booked_amount,
    funded_amount,
    activation_remittance_rate,
    activation_payback_multiple,
    activation_collection_horizon_days,
    activation_total_repayment_amount,
    activation_finance_charge_amount,
    activation_implied_daily_collection_amount,
    activation_implied_payoff_days,
    booking_date,
    funding_date,
    portfolio_activation_date,
    first_expected_remittance_date,
    monitoring_start_date,
    activation_evidence_status,
    notice_control_code,
    primary_activation_reason_code,
    activation_reason_codes,
    source_m2_3_contract_row_hash,
    source_m2_2_contract_row_hash,
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
    source_final_decision_outcome_code,
    activation_outcome_code,
    activation_outcome_rank,
    booking_eligible_flag,
    booking_authorized_flag,
    funding_authorized_flag,
    funding_completed_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    synthetic_offer_acceptance_assumed_flag,
    real_funds_movement_flag,
    external_notice_generation_authorized_flag,
    external_notice_transmitted_flag,
    production_adverse_action_notice_flag,
    synthetic_account_id,
    synthetic_advance_id,
    booked_amount,
    funded_amount,
    activation_remittance_rate,
    activation_payback_multiple,
    activation_collection_horizon_days,
    activation_total_repayment_amount,
    activation_finance_charge_amount,
    activation_implied_daily_collection_amount,
    activation_implied_payoff_days,
    booking_date,
    funding_date,
    portfolio_activation_date,
    first_expected_remittance_date,
    monitoring_start_date,
    activation_evidence_status,
    notice_control_code,
    primary_activation_reason_code,
    activation_reason_codes,
    source_m2_3_contract_row_hash,
    source_m2_2_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash
FROM _m2_4_latest_expected;

DROP TABLE IF EXISTS _m2_4_archive_expected;

CREATE TEMP TABLE _m2_4_archive_expected
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
    to_jsonb(latest) AS contract_payload,
    NULL::text AS archive_row_hash
FROM _m2_4_latest_expected AS latest;

UPDATE _m2_4_archive_expected AS archive
SET archive_row_hash = msbf_ctl.m2_4_hash_jsonb
(
    to_jsonb(archive) - 'archive_row_hash'
)
WHERE archive.archive_row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_4_archive_expected(module1_run_id,contract_version,scenario_id,merchant_application_id);

ANALYZE _m2_4_archive_expected;

INSERT INTO msbf_m2.application_booking_funding_activation_archive
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
    source_final_decision_outcome_code,
    activation_outcome_code,
    activation_outcome_rank,
    booking_eligible_flag,
    booking_authorized_flag,
    funding_authorized_flag,
    funding_completed_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    synthetic_offer_acceptance_assumed_flag,
    real_funds_movement_flag,
    external_notice_generation_authorized_flag,
    external_notice_transmitted_flag,
    production_adverse_action_notice_flag,
    synthetic_account_id,
    synthetic_advance_id,
    booked_amount,
    funded_amount,
    activation_remittance_rate,
    activation_payback_multiple,
    activation_collection_horizon_days,
    activation_total_repayment_amount,
    activation_finance_charge_amount,
    activation_implied_daily_collection_amount,
    activation_implied_payoff_days,
    booking_date,
    funding_date,
    portfolio_activation_date,
    first_expected_remittance_date,
    monitoring_start_date,
    activation_evidence_status,
    notice_control_code,
    primary_activation_reason_code,
    activation_reason_codes,
    source_m2_3_contract_row_hash,
    source_m2_2_contract_row_hash,
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
    source_final_decision_outcome_code,
    activation_outcome_code,
    activation_outcome_rank,
    booking_eligible_flag,
    booking_authorized_flag,
    funding_authorized_flag,
    funding_completed_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    synthetic_offer_acceptance_assumed_flag,
    real_funds_movement_flag,
    external_notice_generation_authorized_flag,
    external_notice_transmitted_flag,
    production_adverse_action_notice_flag,
    synthetic_account_id,
    synthetic_advance_id,
    booked_amount,
    funded_amount,
    activation_remittance_rate,
    activation_payback_multiple,
    activation_collection_horizon_days,
    activation_total_repayment_amount,
    activation_finance_charge_amount,
    activation_implied_daily_collection_amount,
    activation_implied_payoff_days,
    booking_date,
    funding_date,
    portfolio_activation_date,
    first_expected_remittance_date,
    monitoring_start_date,
    activation_evidence_status,
    notice_control_code,
    primary_activation_reason_code,
    activation_reason_codes,
    source_m2_3_contract_row_hash,
    source_m2_2_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash,
    contract_payload,
    archive_row_hash
FROM _m2_4_archive_expected;

ANALYZE msbf_m2.application_booking_funding_source_snapshot;
ANALYZE msbf_m2.application_booking_funding_activation_snapshot;
ANALYZE msbf_m2.application_booking_funding_activation_latest;
ANALYZE msbf_m2.application_booking_funding_activation_archive;
ANALYZE msbf_m2.synthetic_account_activation;
ANALYZE msbf_m2.synthetic_advance_funding;
ANALYZE msbf_m2.initial_portfolio_activation;

/* --------------------------------------------------------------------------
Matched-scenario guard — no favorable stress activation or funded amount.
-------------------------------------------------------------------------- */
DO $m2_4_stress_guard$
DECLARE
    v_comparisons bigint;
    v_activation_improvements bigint;
    v_amount_improvements bigint;
BEGIN
    SELECT
        count(*),
        count(*) FILTER (WHERE stress_activation_improvement_flag),
        count(*) FILTER (WHERE stress_funded_amount_improvement_flag)
    INTO
        v_comparisons,
        v_activation_improvements,
        v_amount_improvements
    FROM msbf_m2.v_m2_4_matched_scenario_comparison
    WHERE module1_run_id = (SELECT run_id FROM _m2_4_ctx);

    IF v_comparisons <> 750
       OR v_activation_improvements <> 0
       OR v_amount_improvements <> 0 THEN
        RAISE EXCEPTION
            'M2.4 stress non-improvement failed: comparisons %, activation improvements %, amount improvements %.',
            v_comparisons,
            v_activation_improvements,
            v_amount_improvements;
    END IF;
END;
$m2_4_stress_guard$;

/* --------------------------------------------------------------------------
Set hashes, registry and complete canonical reconciliation.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_4_set_hashes;

CREATE TEMP TABLE _m2_4_set_hashes
ON COMMIT DROP
AS
SELECT
    (SELECT md5(string_agg(policy.row_hash,'|' ORDER BY policy.module1_run_id))
     FROM msbf_ctl.m2_4_policy_profile AS policy
     WHERE policy.module1_run_id = (SELECT run_id FROM _m2_4_ctx)) AS policy_set_hash,
    (SELECT md5(string_agg(outcome.row_hash,'|' ORDER BY outcome.activation_outcome_rank,outcome.activation_outcome_code))
     FROM msbf_m2.booking_funding_activation_outcome_definition AS outcome
     WHERE outcome.module1_run_id = (SELECT run_id FROM _m2_4_ctx)) AS outcome_set_hash,
    (SELECT md5(string_agg(reason.row_hash,'|' ORDER BY reason.activation_reason_code))
     FROM msbf_m2.booking_funding_reason_definition AS reason
     WHERE reason.module1_run_id = (SELECT run_id FROM _m2_4_ctx)) AS reason_set_hash,
    (SELECT md5(string_agg(notice.row_hash,'|' ORDER BY notice.notice_control_code))
     FROM msbf_m2.external_notice_control_definition AS notice
     WHERE notice.module1_run_id = (SELECT run_id FROM _m2_4_ctx)) AS notice_control_set_hash,
    (SELECT md5(string_agg(source.scenario_id::text||'|'||source.merchant_application_id||'|'||source.row_hash,'|' ORDER BY source.scenario_id,source.merchant_application_id))
     FROM _m2_4_source_expected AS source) AS source_set_hash,
    (SELECT md5(string_agg(activation.scenario_id::text||'|'||activation.merchant_application_id||'|'||activation.row_hash,'|' ORDER BY activation.scenario_id,activation.merchant_application_id))
     FROM _m2_4_activation_expected AS activation) AS activation_snapshot_set_hash,
    (SELECT md5(string_agg(latest.scenario_id::text||'|'||latest.merchant_application_id||'|'||latest.contract_row_hash,'|' ORDER BY latest.scenario_id,latest.merchant_application_id))
     FROM _m2_4_latest_expected AS latest) AS activation_latest_set_hash,
    (SELECT md5(string_agg(archive.scenario_id::text||'|'||archive.merchant_application_id||'|'||archive.archive_row_hash,'|' ORDER BY archive.scenario_id,archive.merchant_application_id))
     FROM _m2_4_archive_expected AS archive) AS activation_archive_set_hash,
    (SELECT md5(string_agg(account.scenario_id::text||'|'||account.merchant_application_id||'|'||account.row_hash,'|' ORDER BY account.scenario_id,account.merchant_application_id))
     FROM _m2_4_account_expected AS account) AS account_set_hash,
    (SELECT md5(string_agg(advance.scenario_id::text||'|'||advance.merchant_application_id||'|'||advance.row_hash,'|' ORDER BY advance.scenario_id,advance.merchant_application_id))
     FROM _m2_4_advance_expected AS advance) AS advance_set_hash,
    (SELECT md5(string_agg(portfolio.scenario_id::text||'|'||portfolio.merchant_application_id||'|'||portfolio.row_hash,'|' ORDER BY portfolio.scenario_id,portfolio.merchant_application_id))
     FROM _m2_4_portfolio_expected AS portfolio) AS portfolio_set_hash;

DROP TABLE IF EXISTS _m2_4_registry_expected;

CREATE TEMP TABLE _m2_4_registry_expected
(
    module1_run_id                      bigint NOT NULL,
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
    contract_set_hash                   text,
    combined_set_hash                   text,
    contract_status                     text NOT NULL,
    generated_at                        timestamptz,
    validated_at                        timestamptz,
    accepted_at                         timestamptz,
    row_hash                            text
)
ON COMMIT DROP;

INSERT INTO _m2_4_registry_expected
SELECT
    ctx.run_id,
    'M2_PORTFOLIO_ACTIVATION_CONSUMPTION',
    1,
    'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1',
    'M2_4_METHOD_V1',
    'M2_FINAL_OFFER_DECISION_CONSUMPTION',
    1,
    'M2_3_FINAL_DECISION_SCHEMA_V1',
    'bf09349b06ede7e5a2ec830c2f9ffe90',
    'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION',
    ctx.configuration_hash,
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
    59,
    190,
    178,
    1073,
    hashes.policy_set_hash,
    hashes.outcome_set_hash,
    hashes.reason_set_hash,
    hashes.notice_control_set_hash,
    hashes.source_set_hash,
    hashes.activation_snapshot_set_hash,
    hashes.activation_latest_set_hash,
    hashes.activation_archive_set_hash,
    hashes.account_set_hash,
    hashes.advance_set_hash,
    hashes.portfolio_set_hash,
    NULL::text,
    NULL::text,
    'GENERATED',
    clock_timestamp(),
    NULL::timestamptz,
    NULL::timestamptz,
    NULL::text
FROM _m2_4_ctx AS ctx
CROSS JOIN _m2_4_set_hashes AS hashes;

UPDATE _m2_4_registry_expected AS registry
SET row_hash = msbf_ctl.m2_4_registry_row_hash(to_jsonb(registry))
WHERE registry.row_hash IS NULL;

UPDATE _m2_4_registry_expected AS registry
SET contract_set_hash = md5(registry.row_hash)
WHERE registry.contract_set_hash IS NULL;

DROP TABLE IF EXISTS _m2_4_canonical_expected;

CREATE TEMP TABLE _m2_4_canonical_expected
(
    entity_type text NOT NULL,
    entity_key  text NOT NULL,
    row_hash    text NOT NULL,
    PRIMARY KEY(entity_type,entity_key)
)
ON COMMIT DROP;

INSERT INTO _m2_4_canonical_expected
SELECT
    'POLICY',
    policy.policy_code || '|v' || policy.policy_version::text,
    policy.row_hash
FROM msbf_ctl.m2_4_policy_profile AS policy
WHERE policy.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'OUTCOME',
    outcome.activation_outcome_code,
    outcome.row_hash
FROM msbf_m2.booking_funding_activation_outcome_definition AS outcome
WHERE outcome.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'REASON',
    reason.activation_reason_code,
    reason.row_hash
FROM msbf_m2.booking_funding_reason_definition AS reason
WHERE reason.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'NOTICE',
    notice.notice_control_code,
    notice.row_hash
FROM msbf_m2.external_notice_control_definition AS notice
WHERE notice.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'SOURCE',
    source.scenario_id::text || '|' || source.merchant_application_id,
    source.row_hash
FROM _m2_4_source_expected AS source

UNION ALL

SELECT
    'ACTIVATION_SNAPSHOT',
    activation.scenario_id::text || '|' || activation.merchant_application_id,
    activation.row_hash
FROM _m2_4_activation_expected AS activation

UNION ALL

SELECT
    'LATEST',
    latest.scenario_id::text || '|' || latest.merchant_application_id,
    latest.contract_row_hash
FROM _m2_4_latest_expected AS latest

UNION ALL

SELECT
    'ARCHIVE',
    archive.scenario_id::text || '|' || archive.merchant_application_id,
    archive.archive_row_hash
FROM _m2_4_archive_expected AS archive

UNION ALL

SELECT
    'ACCOUNT',
    account.scenario_id::text || '|' || account.merchant_application_id,
    account.row_hash
FROM _m2_4_account_expected AS account

UNION ALL

SELECT
    'ADVANCE',
    advance.scenario_id::text || '|' || advance.merchant_application_id,
    advance.row_hash
FROM _m2_4_advance_expected AS advance

UNION ALL

SELECT
    'PORTFOLIO',
    portfolio.scenario_id::text || '|' || portfolio.merchant_application_id,
    portfolio.row_hash
FROM _m2_4_portfolio_expected AS portfolio

UNION ALL

SELECT
    'REGISTRY',
    registry.contract_code || '|v' || registry.contract_version::text,
    registry.row_hash
FROM _m2_4_registry_expected AS registry;

UPDATE _m2_4_registry_expected AS registry
SET combined_set_hash =
(
    SELECT md5
    (
        string_agg
        (
            canonical.entity_type || '|' ||
            canonical.entity_key || '|' ||
            canonical.row_hash,
            '|' ORDER BY canonical.entity_type,canonical.entity_key
        )
    )
    FROM _m2_4_canonical_expected AS canonical
)
WHERE registry.combined_set_hash IS NULL;

INSERT INTO msbf_ctl.m2_4_portfolio_activation_contract_registry
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    source_m2_3_contract_code,
    source_m2_3_contract_version,
    source_m2_3_schema_version,
    source_m2_3_combined_hash,
    source_m2_3_acceptance_gate_id,
    policy_configuration_hash,
    policy_rows,
    outcome_rows,
    reason_rows,
    notice_control_rows,
    source_rows,
    activation_snapshot_rows,
    activation_latest_rows,
    activation_archive_rows,
    account_rows,
    advance_rows,
    portfolio_rows,
    comparison_rows,
    registry_rows,
    canonical_entities,
    activated_rows,
    review_required_rows,
    not_activated_insufficient_rows,
    not_activated_policy_rows,
    policy_set_hash,
    outcome_set_hash,
    reason_set_hash,
    notice_control_set_hash,
    source_set_hash,
    activation_snapshot_set_hash,
    activation_latest_set_hash,
    activation_archive_set_hash,
    account_set_hash,
    advance_set_hash,
    portfolio_set_hash,
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
    source_m2_3_contract_code,
    source_m2_3_contract_version,
    source_m2_3_schema_version,
    source_m2_3_combined_hash,
    source_m2_3_acceptance_gate_id,
    policy_configuration_hash,
    policy_rows,
    outcome_rows,
    reason_rows,
    notice_control_rows,
    source_rows,
    activation_snapshot_rows,
    activation_latest_rows,
    activation_archive_rows,
    account_rows,
    advance_rows,
    portfolio_rows,
    comparison_rows,
    registry_rows,
    canonical_entities,
    activated_rows,
    review_required_rows,
    not_activated_insufficient_rows,
    not_activated_policy_rows,
    policy_set_hash,
    outcome_set_hash,
    reason_set_hash,
    notice_control_set_hash,
    source_set_hash,
    activation_snapshot_set_hash,
    activation_latest_set_hash,
    activation_archive_set_hash,
    account_set_hash,
    advance_set_hash,
    portfolio_set_hash,
    contract_set_hash,
    combined_set_hash,
    contract_status,
    generated_at,
    validated_at,
    accepted_at,
    row_hash
FROM _m2_4_registry_expected;

DROP TABLE IF EXISTS _m2_4_canonical_actual;

CREATE TEMP TABLE _m2_4_canonical_actual
(
    entity_type text NOT NULL,
    entity_key  text NOT NULL,
    row_hash    text NOT NULL,
    PRIMARY KEY(entity_type,entity_key)
)
ON COMMIT DROP;

INSERT INTO _m2_4_canonical_actual
SELECT
    'POLICY',
    policy.policy_code || '|v' || policy.policy_version::text,
    msbf_ctl.m2_4_hash_jsonb(to_jsonb(policy)-'row_hash'-'created_at'-'updated_at')
FROM msbf_ctl.m2_4_policy_profile AS policy
WHERE policy.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'OUTCOME',
    outcome.activation_outcome_code,
    msbf_ctl.m2_4_hash_jsonb(to_jsonb(outcome)-'row_hash'-'created_at')
FROM msbf_m2.booking_funding_activation_outcome_definition AS outcome
WHERE outcome.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'REASON',
    reason.activation_reason_code,
    msbf_ctl.m2_4_hash_jsonb(to_jsonb(reason)-'row_hash'-'created_at')
FROM msbf_m2.booking_funding_reason_definition AS reason
WHERE reason.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'NOTICE',
    notice.notice_control_code,
    msbf_ctl.m2_4_hash_jsonb(to_jsonb(notice)-'row_hash'-'created_at')
FROM msbf_m2.external_notice_control_definition AS notice
WHERE notice.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'SOURCE',
    source.scenario_id::text || '|' || source.merchant_application_id,
    msbf_ctl.m2_4_hash_jsonb(to_jsonb(source)-'row_hash'-'created_at')
FROM msbf_m2.application_booking_funding_source_snapshot AS source
WHERE source.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'ACTIVATION_SNAPSHOT',
    activation.scenario_id::text || '|' || activation.merchant_application_id,
    msbf_ctl.m2_4_hash_jsonb(to_jsonb(activation)-'row_hash'-'created_at')
FROM msbf_m2.application_booking_funding_activation_snapshot AS activation
WHERE activation.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'LATEST',
    latest.scenario_id::text || '|' || latest.merchant_application_id,
    msbf_ctl.m2_4_hash_jsonb(to_jsonb(latest)-'contract_row_hash'-'created_at')
FROM msbf_m2.application_booking_funding_activation_latest AS latest
WHERE latest.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'ARCHIVE',
    archive.scenario_id::text || '|' || archive.merchant_application_id,
    msbf_ctl.m2_4_hash_jsonb(to_jsonb(archive)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at')
FROM msbf_m2.application_booking_funding_activation_archive AS archive
WHERE archive.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'ACCOUNT',
    account.scenario_id::text || '|' || account.merchant_application_id,
    msbf_ctl.m2_4_hash_jsonb(to_jsonb(account)-'row_hash'-'created_at')
FROM msbf_m2.synthetic_account_activation AS account
WHERE account.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'ADVANCE',
    advance.scenario_id::text || '|' || advance.merchant_application_id,
    msbf_ctl.m2_4_hash_jsonb(to_jsonb(advance)-'row_hash'-'created_at')
FROM msbf_m2.synthetic_advance_funding AS advance
WHERE advance.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'PORTFOLIO',
    portfolio.scenario_id::text || '|' || portfolio.merchant_application_id,
    msbf_ctl.m2_4_hash_jsonb(to_jsonb(portfolio)-'row_hash'-'created_at')
FROM msbf_m2.initial_portfolio_activation AS portfolio
WHERE portfolio.module1_run_id = (SELECT run_id FROM _m2_4_ctx)

UNION ALL

SELECT
    'REGISTRY',
    registry.contract_code || '|v' || registry.contract_version::text,
    msbf_ctl.m2_4_registry_row_hash(to_jsonb(registry))
FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry
WHERE registry.module1_run_id = (SELECT run_id FROM _m2_4_ctx);

DROP TABLE IF EXISTS _m2_4_mismatch;

CREATE TEMP TABLE _m2_4_mismatch
ON COMMIT DROP
AS
SELECT
    coalesce(expected.entity_type,actual.entity_type) AS entity_type,
    coalesce(expected.entity_key,actual.entity_key) AS entity_key,
    expected.row_hash AS expected_row_hash,
    actual.row_hash AS actual_row_hash
FROM _m2_4_canonical_expected AS expected
FULL OUTER JOIN _m2_4_canonical_actual AS actual
  ON actual.entity_type = expected.entity_type
 AND actual.entity_key = expected.entity_key
WHERE expected.row_hash IS DISTINCT FROM actual.row_hash;

DO $m2_4_canonical_guard$
DECLARE
    v_expected bigint;
    v_actual bigint;
    v_mismatches bigint;
BEGIN
    SELECT count(*) INTO v_expected FROM _m2_4_canonical_expected;
    SELECT count(*) INTO v_actual FROM _m2_4_canonical_actual;
    SELECT count(*) INTO v_mismatches FROM _m2_4_mismatch;

    IF v_expected <> 6212
       OR v_actual <> 6212
       OR v_mismatches <> 0 THEN
        RAISE EXCEPTION
            'M2.4 canonical reconciliation failed: expected %, actual %, mismatches %.',
            v_expected,
            v_actual,
            v_mismatches;
    END IF;
END;
$m2_4_canonical_guard$;

/* --------------------------------------------------------------------------
Generation evidence — exactly one value representation per row.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_4_generation_evidence;

CREATE TEMP TABLE _m2_4_generation_evidence
(
    run_id               bigint NOT NULL,
    evidence_code        text NOT NULL,
    segment_key          text NOT NULL,
    metric_name          text NOT NULL,
    metric_value_numeric numeric(24,10),
    metric_value_text    text,
    unit_code            text NOT NULL,
    status               text NOT NULL,
    interpretation       text NOT NULL,
    CHECK(num_nonnulls(metric_value_numeric,metric_value_text)=1)
)
ON COMMIT DROP;

INSERT INTO _m2_4_generation_evidence
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
FROM _m2_4_registry_expected AS registry
CROSS JOIN LATERAL
(
    VALUES
    ('M2_4_POLICY_SET_HASH','POLICY_SET_HASH',NULL::numeric(24,10),registry.policy_set_hash,'HASH','M2.4 policy set hash.'),
    ('M2_4_OUTCOME_SET_HASH','OUTCOME_SET_HASH',NULL::numeric(24,10),registry.outcome_set_hash,'HASH','M2.4 activation outcome set hash.'),
    ('M2_4_REASON_SET_HASH','REASON_SET_HASH',NULL::numeric(24,10),registry.reason_set_hash,'HASH','M2.4 operational reason set hash.'),
    ('M2_4_NOTICE_SET_HASH','NOTICE_SET_HASH',NULL::numeric(24,10),registry.notice_control_set_hash,'HASH','M2.4 notice-control set hash.'),
    ('M2_4_SOURCE_SET_HASH','SOURCE_SET_HASH',NULL::numeric(24,10),registry.source_set_hash,'HASH','Accepted M2.3 source materialization set hash.'),
    ('M2_4_ACTIVATION_SNAPSHOT_SET_HASH','ACTIVATION_SNAPSHOT_SET_HASH',NULL::numeric(24,10),registry.activation_snapshot_set_hash,'HASH','M2.4 activation snapshot set hash.'),
    ('M2_4_LATEST_SET_HASH','ACTIVATION_LATEST_SET_HASH',NULL::numeric(24,10),registry.activation_latest_set_hash,'HASH','M2.4 latest contract set hash.'),
    ('M2_4_ARCHIVE_SET_HASH','ACTIVATION_ARCHIVE_SET_HASH',NULL::numeric(24,10),registry.activation_archive_set_hash,'HASH','M2.4 archive set hash.'),
    ('M2_4_ACCOUNT_SET_HASH','ACCOUNT_SET_HASH',NULL::numeric(24,10),registry.account_set_hash,'HASH','Synthetic account activation set hash.'),
    ('M2_4_ADVANCE_SET_HASH','ADVANCE_SET_HASH',NULL::numeric(24,10),registry.advance_set_hash,'HASH','Synthetic advance funding set hash.'),
    ('M2_4_PORTFOLIO_SET_HASH','PORTFOLIO_SET_HASH',NULL::numeric(24,10),registry.portfolio_set_hash,'HASH','Initial portfolio activation set hash.'),
    ('M2_4_CONTRACT_SET_HASH','CONTRACT_SET_HASH',NULL::numeric(24,10),registry.contract_set_hash,'HASH','M2.4 registry contract set hash.'),
    ('M2_4_COMBINED_SET_HASH','COMBINED_SET_HASH',NULL::numeric(24,10),registry.combined_set_hash,'HASH','Complete M2.4 canonical set hash.'),
    ('M2_4_SOURCE_ROW_COUNT','SOURCE_ROW_COUNT',registry.source_rows::numeric(24,10),NULL::text,'ROWS','M2.3 source rows consumed.'),
    ('M2_4_ACTIVATION_ROW_COUNT','ACTIVATION_ROW_COUNT',registry.activation_snapshot_rows::numeric(24,10),NULL::text,'ROWS','Activation rows generated.'),
    ('M2_4_LATEST_ROW_COUNT','LATEST_ROW_COUNT',registry.activation_latest_rows::numeric(24,10),NULL::text,'ROWS','Latest activation contract rows.'),
    ('M2_4_ARCHIVE_ROW_COUNT','ARCHIVE_ROW_COUNT',registry.activation_archive_rows::numeric(24,10),NULL::text,'ROWS','Immutable archive rows.'),
    ('M2_4_ACCOUNT_ROW_COUNT','ACCOUNT_ROW_COUNT',registry.account_rows::numeric(24,10),NULL::text,'ROWS','Synthetic account activation rows.'),
    ('M2_4_ADVANCE_ROW_COUNT','ADVANCE_ROW_COUNT',registry.advance_rows::numeric(24,10),NULL::text,'ROWS','Synthetic funded advance rows.'),
    ('M2_4_PORTFOLIO_ROW_COUNT','PORTFOLIO_ROW_COUNT',registry.portfolio_rows::numeric(24,10),NULL::text,'ROWS','Initial portfolio activation rows.'),
    ('M2_4_ACTIVATED_ROW_COUNT','ACTIVATED_ROW_COUNT',registry.activated_rows::numeric(24,10),NULL::text,'ROWS','Booked, funded and activated rows.'),
    ('M2_4_REVIEW_ROW_COUNT','REVIEW_ROW_COUNT',registry.review_required_rows::numeric(24,10),NULL::text,'ROWS','Operational review-required rows.'),
    ('M2_4_COMPARISON_ROW_COUNT','COMPARISON_ROW_COUNT',registry.comparison_rows::numeric(24,10),NULL::text,'ROWS','Matched baseline/stress comparison rows.'),
    ('M2_4_CANONICAL_ENTITY_COUNT','CANONICAL_ENTITY_COUNT',registry.canonical_entities::numeric(24,10),NULL::text,'ROWS','Canonical M2.4 entities.')
) AS evidence
(
    evidence_code,
    metric_name,
    metric_value_numeric,
    metric_value_text,
    unit_code,
    interpretation
);

DO $m2_4_generation_evidence_guard$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows
    FROM _m2_4_generation_evidence;

    IF v_rows <> 24 THEN
        RAISE EXCEPTION
            'M2.4 generation evidence inventory failed: rows %, expected %.',
            v_rows,
            24;
    END IF;
END;
$m2_4_generation_evidence_guard$;

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
    evidence.run_id,
    evidence.evidence_code,
    evidence.segment_key,
    evidence.metric_name,
    evidence.metric_value_numeric,
    evidence.metric_value_text,
    evidence.unit_code,
    evidence.status,
    evidence.interpretation
FROM _m2_4_generation_evidence AS evidence;

UPDATE msbf_ctl.run_registry AS run
SET
    run_status = 'M2_4_GENERATED',
    notes = coalesce(run.notes,'') ||
        ' | M2.4 synthetic booking, funding and portfolio activation generated.'
WHERE run.run_id = (SELECT run_id FROM _m2_4_ctx);

INSERT INTO _m2_4_result
SELECT
    registry.module1_run_id,
    'M2_4_GENERATED',
    registry.policy_rows,
    registry.outcome_rows,
    registry.reason_rows,
    registry.notice_control_rows,
    registry.source_rows,
    registry.activation_snapshot_rows,
    registry.activation_latest_rows,
    registry.activation_archive_rows,
    registry.account_rows,
    registry.advance_rows,
    registry.portfolio_rows,
    registry.comparison_rows,
    registry.registry_rows,
    registry.activated_rows,
    registry.review_required_rows,
    registry.not_activated_insufficient_rows,
    registry.not_activated_policy_rows,
    6212,
    (SELECT count(*) FROM _m2_4_canonical_actual),
    (SELECT count(*) FROM _m2_4_mismatch),
    (SELECT count(*) FROM msbf_m2.v_m2_4_matched_scenario_comparison
     WHERE module1_run_id = registry.module1_run_id
       AND stress_activation_improvement_flag),
    (SELECT count(*) FROM msbf_m2.v_m2_4_matched_scenario_comparison
     WHERE module1_run_id = registry.module1_run_id
       AND stress_funded_amount_improvement_flag),
    registry.policy_set_hash,
    registry.outcome_set_hash,
    registry.reason_set_hash,
    registry.notice_control_set_hash,
    registry.source_set_hash,
    registry.activation_snapshot_set_hash,
    registry.activation_latest_set_hash,
    registry.activation_archive_set_hash,
    registry.account_set_hash,
    registry.advance_set_hash,
    registry.portfolio_set_hash,
    registry.contract_set_hash,
    registry.combined_set_hash,
    'PASS'
FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry
WHERE registry.module1_run_id = (SELECT run_id FROM _m2_4_ctx);

COMMIT;

SELECT
    run_id,
    run_status,
    policy_rows,
    outcome_rows,
    reason_rows,
    notice_control_rows,
    source_rows,
    activation_snapshot_rows,
    activation_latest_rows,
    activation_archive_rows,
    account_rows,
    advance_rows,
    portfolio_rows,
    comparison_rows,
    registry_rows,
    activated_rows,
    review_required_rows,
    not_activated_insufficient_rows,
    not_activated_policy_rows,
    expected_canonical_entities,
    actual_canonical_entities,
    row_level_mismatches,
    stress_activation_improvements,
    stress_funded_amount_improvements,
    policy_set_hash,
    outcome_set_hash,
    reason_set_hash,
    notice_control_set_hash,
    source_set_hash,
    activation_snapshot_set_hash,
    activation_latest_set_hash,
    activation_archive_set_hash,
    account_set_hash,
    advance_set_hash,
    portfolio_set_hash,
    contract_set_hash,
    combined_set_hash,
    generation_status
FROM _m2_4_result;
