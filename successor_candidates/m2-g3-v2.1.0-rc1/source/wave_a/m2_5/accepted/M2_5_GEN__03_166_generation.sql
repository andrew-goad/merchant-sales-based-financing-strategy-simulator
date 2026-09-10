/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 166_msbf_m2_5_daily_remittance_exposure_generation_v0_2.sql
Version     : v0.2

Purpose
-------
Generate the complete M2.5 monitoring population:
- 59 target-typed source snapshots from accepted M2.4 activated advances;
- a 120-day replay of accepted M1.6 scenario POS/deposit history;
- 7,080 daily remittance and exposure rows;
- transparent monitoring statuses, alerts and a matched stress-status floor;
- 59 latest and immutable archive contracts;
- 240 scenario/day portfolio summaries;
- 7,536 reconciled canonical entities; and
- 24 governed generation-evidence rows.

Methodology boundary
--------------------
The module replays the most recent 120 accepted historical scenario days as a
deterministic synthetic monitoring campaign. It is not a future-sales forecast
and does not issue debit, collections, restructure, write-off, external notice
or production adverse-action instructions.

Performance and error-prevention controls
-----------------------------------------
- Accepted M2.4 source is materialized once.
- M1.6 POS history is aggregated once; deposit history is joined once.
- Window functions replace recursive balance calculations and self-joins where
  possible.
- The only matched self-join is the explicit baseline/stress status floor.
- Every hashed staging table is target typed before hashing.
- All staging hash updates contain a WHERE predicate.
- Indexes and ANALYZE precede downstream joins and reconciliation.
- Generation commits only after count, status, stress and physical-hash guards.
============================================================================ */

BEGIN;

SET LOCAL work_mem = '192MB';
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '60min';
SET LOCAL jit = off;

/* ============================================================================
Section 1 — Session-preserved result and governed context
============================================================================ */

DROP TABLE IF EXISTS _m2_5_result;

CREATE TEMP TABLE _m2_5_result
(
    run_id                              bigint,
    run_status                          text,
    policy_rows                         bigint,
    status_rows                         bigint,
    alert_rows                          bigint,
    reason_rows                         bigint,
    source_rows                         bigint,
    daily_rows                          bigint,
    latest_rows                         bigint,
    archive_rows                        bigint,
    portfolio_daily_rows                bigint,
    comparison_rows                     bigint,
    registry_rows                       bigint,
    paid_off_rows                       bigint,
    open_monitoring_rows                bigint,
    stress_status_floor_rows             bigint,
    total_remittance_amount             numeric(24,2),
    ending_receivable_exposure_amount   numeric(24,2),
    expected_canonical_entities         bigint,
    actual_canonical_entities           bigint,
    row_level_mismatches                bigint,
    stress_status_improvements          bigint,
    policy_set_hash                     text,
    status_set_hash                     text,
    alert_set_hash                      text,
    reason_set_hash                     text,
    source_set_hash                     text,
    daily_set_hash                      text,
    latest_set_hash                     text,
    archive_set_hash                    text,
    portfolio_daily_set_hash             text,
    contract_set_hash                   text,
    combined_set_hash                   text,
    generation_status                   text
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_5_ctx;

CREATE TEMP TABLE _m2_5_ctx
ON COMMIT DROP
AS
SELECT
    run.run_id,
    policy.configuration_hash,
    policy.source_m1_6_combined_hash,
    policy.monitoring_horizon_days,
    policy.source_replay_days,
    policy.watch_start_day,
    policy.underperforming_start_day,
    policy.severe_start_day,
    policy.watch_pace_ratio,
    policy.underperforming_pace_ratio,
    policy.severe_pace_ratio,
    policy.watch_daily_coverage_ratio,
    policy.underperforming_no_remittance_days,
    policy.dormant_no_remittance_days,
    policy.severe_zero_sales_streak_days,
    policy.low_liquidity_available_balance,
    policy.expected_source_rows,
    policy.expected_daily_rows,
    policy.expected_latest_rows,
    policy.expected_archive_rows,
    policy.expected_portfolio_daily_rows,
    policy.expected_comparison_rows,
    policy.expected_canonical_entities
FROM msbf_ctl.run_registry AS run
JOIN msbf_ctl.m2_5_policy_profile AS policy
  ON policy.module1_run_id = run.run_id
WHERE run.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND run.run_version = 1;

DO $m2_5_generation_ready$
BEGIN
    PERFORM msbf_ctl.m2_5_assert_generation_ready
    (
        (SELECT run_id FROM _m2_5_ctx)
    );
END;
$m2_5_generation_ready$;

/* ============================================================================
Section 2 — Materialize accepted M2.4 activated advances once
============================================================================ */

DROP TABLE IF EXISTS _m2_5_active_source_input;

CREATE TEMP TABLE _m2_5_active_source_input
ON COMMIT DROP
AS
SELECT
    latest.module1_run_id,
    latest.scenario_id,
    latest.scenario_code,
    latest.merchant_application_id,
    latest.population_id,
    latest.merchant_id,
    latest.synthetic_account_id,
    latest.synthetic_advance_id,
    latest.as_of_date,
    advance.funding_date,
    portfolio.portfolio_activation_date,
    portfolio.monitoring_start_date,
    advance.first_expected_remittance_date,
    advance.funded_amount,
    advance.total_repayment_amount,
    advance.finance_charge_amount,
    advance.remittance_rate,
    advance.collection_horizon_days,
    advance.implied_daily_collection_amount,
    portfolio.initial_exposure_amount,
    latest.contract_row_hash AS source_m2_4_contract_row_hash,
    advance.row_hash AS source_advance_row_hash,
    portfolio.row_hash AS source_portfolio_row_hash,
    ctx.source_m1_6_combined_hash,
    to_jsonb(latest) - 'created_at' AS activation_payload,
    to_jsonb(advance) - 'created_at' AS advance_payload,
    to_jsonb(portfolio) - 'created_at' AS portfolio_payload
FROM msbf_m2.application_booking_funding_activation_latest AS latest
JOIN msbf_m2.synthetic_advance_funding AS advance
  ON advance.module1_run_id = latest.module1_run_id
 AND advance.scenario_id = latest.scenario_id
 AND advance.merchant_application_id = latest.merchant_application_id
JOIN msbf_m2.initial_portfolio_activation AS portfolio
  ON portfolio.module1_run_id = latest.module1_run_id
 AND portfolio.scenario_id = latest.scenario_id
 AND portfolio.merchant_application_id = latest.merchant_application_id
CROSS JOIN _m2_5_ctx AS ctx
WHERE latest.module1_run_id = ctx.run_id
  AND latest.portfolio_activated_flag
  AND latest.activation_outcome_code = 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED';

CREATE UNIQUE INDEX
ON _m2_5_active_source_input
(
    module1_run_id,
    scenario_id,
    merchant_application_id
);

CREATE UNIQUE INDEX
ON _m2_5_active_source_input
(
    module1_run_id,
    synthetic_advance_id
);

ANALYZE _m2_5_active_source_input;

/* ============================================================================
Section 3 — Target-typed M2.5 source snapshot
============================================================================ */

DROP TABLE IF EXISTS _m2_5_source_expected;

CREATE TEMP TABLE _m2_5_source_expected
(
    module1_run_id                         bigint NOT NULL,
    scenario_id                            bigint NOT NULL,
    scenario_code                          text NOT NULL,
    merchant_application_id                text NOT NULL,
    population_id                          text NOT NULL,
    merchant_id                            text NOT NULL,
    synthetic_account_id                   text NOT NULL,
    synthetic_advance_id                   text NOT NULL,
    as_of_date                             date NOT NULL,
    funding_date                           date NOT NULL,
    portfolio_activation_date              date NOT NULL,
    monitoring_start_date                  date NOT NULL,
    first_expected_remittance_date          date NOT NULL,
    funded_amount                          numeric(18,2) NOT NULL,
    total_repayment_amount                 numeric(18,2) NOT NULL,
    finance_charge_amount                  numeric(18,2) NOT NULL,
    remittance_rate                        numeric(9,6) NOT NULL,
    collection_horizon_days                integer NOT NULL,
    implied_daily_collection_amount        numeric(18,2) NOT NULL,
    initial_exposure_amount                numeric(18,2) NOT NULL,
    source_m2_4_contract_row_hash          text NOT NULL,
    source_advance_row_hash                text NOT NULL,
    source_portfolio_row_hash              text NOT NULL,
    source_m2_4_combined_hash              text NOT NULL,
    source_payload                         jsonb NOT NULL,
    row_hash                               text
)
ON COMMIT DROP;

INSERT INTO _m2_5_source_expected
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    synthetic_account_id,
    synthetic_advance_id,
    as_of_date,
    funding_date,
    portfolio_activation_date,
    monitoring_start_date,
    first_expected_remittance_date,
    funded_amount,
    total_repayment_amount,
    finance_charge_amount,
    remittance_rate,
    collection_horizon_days,
    implied_daily_collection_amount,
    initial_exposure_amount,
    source_m2_4_contract_row_hash,
    source_advance_row_hash,
    source_portfolio_row_hash,
    source_m2_4_combined_hash,
    source_payload,
    row_hash
)
SELECT
    source.module1_run_id::bigint,
    source.scenario_id::bigint,
    source.scenario_code::text,
    source.merchant_application_id::text,
    source.population_id::text,
    source.merchant_id::text,
    source.synthetic_account_id::text,
    source.synthetic_advance_id::text,
    source.as_of_date::date,
    source.funding_date::date,
    source.portfolio_activation_date::date,
    source.monitoring_start_date::date,
    source.first_expected_remittance_date::date,
    source.funded_amount::numeric(18,2),
    source.total_repayment_amount::numeric(18,2),
    source.finance_charge_amount::numeric(18,2),
    source.remittance_rate::numeric(9,6),
    source.collection_horizon_days::integer,
    source.implied_daily_collection_amount::numeric(18,2),
    source.initial_exposure_amount::numeric(18,2),
    source.source_m2_4_contract_row_hash::text,
    source.source_advance_row_hash::text,
    source.source_portfolio_row_hash::text,
    '117450a3eea7bb3d3c74d18cc3c8e96a'::text,
    jsonb_build_object
    (
        'activation', source.activation_payload,
        'advance', source.advance_payload,
        'portfolio', source.portfolio_payload,
        'source_m1_6_combined_hash', source.source_m1_6_combined_hash
    ),
    NULL::text
FROM _m2_5_active_source_input AS source;

UPDATE _m2_5_source_expected AS source
SET row_hash = msbf_ctl.m2_5_hash_jsonb
(
    to_jsonb(source) - 'row_hash'
)
WHERE source.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_5_source_expected
(
    module1_run_id,
    scenario_id,
    merchant_application_id
);

ANALYZE _m2_5_source_expected;

DO $m2_5_source_guard$
DECLARE
    v record;
BEGIN
    SELECT
        count(*) AS source_rows,
        count(*) FILTER(WHERE scenario_code = 'BASELINE') AS baseline_rows,
        count(*) FILTER(WHERE scenario_code = 'RECESSION_ENERGY') AS stress_rows,
        count(DISTINCT synthetic_account_id) AS account_ids,
        count(DISTINCT synthetic_advance_id) AS advance_ids,
        count(*) FILTER
        (
            WHERE row_hash IS NULL
               OR funded_amount <= 0
               OR total_repayment_amount < funded_amount
               OR initial_exposure_amount IS DISTINCT FROM funded_amount
               OR remittance_rate NOT BETWEEN 0.05 AND 0.20
               OR collection_horizon_days NOT BETWEEN 1 AND 120
               OR implied_daily_collection_amount <= 0
        ) AS invalid_rows
    INTO v
    FROM _m2_5_source_expected;

    IF v.source_rows <> 59
       OR v.baseline_rows <> 44
       OR v.stress_rows <> 15
       OR v.account_ids <> 59
       OR v.advance_ids <> 59
       OR v.invalid_rows <> 0 THEN
        RAISE EXCEPTION
            'M2.5 source generation failed: %',
            row_to_json(v);
    END IF;
END;
$m2_5_source_guard$;

INSERT INTO msbf_m2.advance_monitoring_source_snapshot
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    synthetic_account_id,
    synthetic_advance_id,
    as_of_date,
    funding_date,
    portfolio_activation_date,
    monitoring_start_date,
    first_expected_remittance_date,
    funded_amount,
    total_repayment_amount,
    finance_charge_amount,
    remittance_rate,
    collection_horizon_days,
    implied_daily_collection_amount,
    initial_exposure_amount,
    source_m2_4_contract_row_hash,
    source_advance_row_hash,
    source_portfolio_row_hash,
    source_m2_4_combined_hash,
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
    source.synthetic_account_id,
    source.synthetic_advance_id,
    source.as_of_date,
    source.funding_date,
    source.portfolio_activation_date,
    source.monitoring_start_date,
    source.first_expected_remittance_date,
    source.funded_amount,
    source.total_repayment_amount,
    source.finance_charge_amount,
    source.remittance_rate,
    source.collection_horizon_days,
    source.implied_daily_collection_amount,
    source.initial_exposure_amount,
    source.source_m2_4_contract_row_hash,
    source.source_advance_row_hash,
    source.source_portfolio_row_hash,
    source.source_m2_4_combined_hash,
    source.source_payload,
    source.row_hash
FROM _m2_5_source_expected AS source;

/* ============================================================================
Section 4 — Accepted M1.6 120-day source replay
============================================================================ */

DROP TABLE IF EXISTS _m2_5_pos_daily_aggregate;

CREATE TEMP TABLE _m2_5_pos_daily_aggregate
ON COMMIT DROP
AS
SELECT
    source.module1_run_id,
    source.scenario_id,
    source.scenario_code,
    source.merchant_application_id,
    source.population_id,
    source.merchant_id,
    source.synthetic_account_id,
    source.synthetic_advance_id,
    source.as_of_date,
    source.first_expected_remittance_date,
    source.funded_amount,
    source.total_repayment_amount,
    source.finance_charge_amount,
    source.remittance_rate,
    source.collection_horizon_days,
    source.implied_daily_collection_amount,
    source.source_m2_4_contract_row_hash,
    source.source_advance_row_hash,
    source.source_portfolio_row_hash,
    pos.observation_date,
    round(sum(pos.gross_pos_sales), 2)::numeric(18,2) AS gross_pos_sales,
    round(sum(pos.eligible_pos_sales), 2)::numeric(18,2) AS eligible_pos_sales,
    round(sum(pos.net_merchant_proceeds), 2)::numeric(18,2) AS net_merchant_proceeds,
    md5
    (
        string_agg
        (
            pos.processor_account_id || '|' || pos.row_hash,
            '|' ORDER BY pos.processor_account_id
        )
    ) AS source_pos_set_hash
FROM _m2_5_source_expected AS source
JOIN msbf_m1.merchant_pos_daily_scenario AS pos
  ON pos.scenario_id = source.scenario_id
 AND pos.population_id = source.population_id
 AND pos.merchant_id = source.merchant_id
 AND pos.observation_date <= source.as_of_date
GROUP BY
    source.module1_run_id,
    source.scenario_id,
    source.scenario_code,
    source.merchant_application_id,
    source.population_id,
    source.merchant_id,
    source.synthetic_account_id,
    source.synthetic_advance_id,
    source.as_of_date,
    source.first_expected_remittance_date,
    source.funded_amount,
    source.total_repayment_amount,
    source.finance_charge_amount,
    source.remittance_rate,
    source.collection_horizon_days,
    source.implied_daily_collection_amount,
    source.source_m2_4_contract_row_hash,
    source.source_advance_row_hash,
    source.source_portfolio_row_hash,
    pos.observation_date;

CREATE INDEX
ON _m2_5_pos_daily_aggregate
(
    module1_run_id,
    scenario_id,
    merchant_application_id,
    observation_date
);

ANALYZE _m2_5_pos_daily_aggregate;

DROP TABLE IF EXISTS _m2_5_pos_ranked;

CREATE TEMP TABLE _m2_5_pos_ranked
ON COMMIT DROP
AS
SELECT
    aggregate.module1_run_id,
    aggregate.scenario_id,
    aggregate.scenario_code,
    aggregate.merchant_application_id,
    aggregate.population_id,
    aggregate.merchant_id,
    aggregate.synthetic_account_id,
    aggregate.synthetic_advance_id,
    aggregate.as_of_date,
    aggregate.first_expected_remittance_date,
    aggregate.funded_amount,
    aggregate.total_repayment_amount,
    aggregate.finance_charge_amount,
    aggregate.remittance_rate,
    aggregate.collection_horizon_days,
    aggregate.implied_daily_collection_amount,
    aggregate.source_m2_4_contract_row_hash,
    aggregate.source_advance_row_hash,
    aggregate.source_portfolio_row_hash,
    aggregate.observation_date,
    aggregate.gross_pos_sales,
    aggregate.eligible_pos_sales,
    aggregate.net_merchant_proceeds,
    aggregate.source_pos_set_hash,
    row_number() OVER
    (
        PARTITION BY
            aggregate.module1_run_id,
            aggregate.scenario_id,
            aggregate.merchant_application_id
        ORDER BY aggregate.observation_date DESC
    )::integer AS recency_rank
FROM _m2_5_pos_daily_aggregate AS aggregate;

CREATE INDEX
ON _m2_5_pos_ranked
(
    module1_run_id,
    scenario_id,
    merchant_application_id,
    recency_rank
);

ANALYZE _m2_5_pos_ranked;

DROP TABLE IF EXISTS _m2_5_replay_expected;

CREATE TEMP TABLE _m2_5_replay_expected
(
    module1_run_id                         bigint NOT NULL,
    scenario_id                            bigint NOT NULL,
    scenario_code                          text NOT NULL,
    merchant_application_id                text NOT NULL,
    population_id                          text NOT NULL,
    merchant_id                            text NOT NULL,
    synthetic_account_id                   text NOT NULL,
    synthetic_advance_id                   text NOT NULL,
    monitoring_day_index                   integer NOT NULL,
    monitoring_date                        date NOT NULL,
    source_observation_date                date NOT NULL,
    gross_pos_sales                        numeric(18,2) NOT NULL,
    eligible_pos_sales                     numeric(18,2) NOT NULL,
    net_merchant_proceeds                  numeric(18,2) NOT NULL,
    available_balance                      numeric(18,2) NOT NULL,
    nsf_count                              smallint NOT NULL,
    negative_balance_flag                  boolean NOT NULL,
    funded_amount                          numeric(18,2) NOT NULL,
    total_repayment_amount                 numeric(18,2) NOT NULL,
    finance_charge_amount                  numeric(18,2) NOT NULL,
    remittance_rate                        numeric(9,6) NOT NULL,
    collection_horizon_days                integer NOT NULL,
    implied_daily_collection_amount        numeric(18,2) NOT NULL,
    source_m2_4_contract_row_hash          text NOT NULL,
    source_advance_row_hash                text NOT NULL,
    source_portfolio_row_hash              text NOT NULL,
    source_pos_set_hash                    text NOT NULL,
    source_deposit_row_hash                text NOT NULL
)
ON COMMIT DROP;

INSERT INTO _m2_5_replay_expected
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    synthetic_account_id,
    synthetic_advance_id,
    monitoring_day_index,
    monitoring_date,
    source_observation_date,
    gross_pos_sales,
    eligible_pos_sales,
    net_merchant_proceeds,
    available_balance,
    nsf_count,
    negative_balance_flag,
    funded_amount,
    total_repayment_amount,
    finance_charge_amount,
    remittance_rate,
    collection_horizon_days,
    implied_daily_collection_amount,
    source_m2_4_contract_row_hash,
    source_advance_row_hash,
    source_portfolio_row_hash,
    source_pos_set_hash,
    source_deposit_row_hash
)
SELECT
    ranked.module1_run_id,
    ranked.scenario_id,
    ranked.scenario_code,
    ranked.merchant_application_id,
    ranked.population_id,
    ranked.merchant_id,
    ranked.synthetic_account_id,
    ranked.synthetic_advance_id,
    (121 - ranked.recency_rank)::integer AS monitoring_day_index,
    (
        ranked.first_expected_remittance_date +
        (120 - ranked.recency_rank)
    )::date AS monitoring_date,
    ranked.observation_date AS source_observation_date,
    ranked.gross_pos_sales,
    ranked.eligible_pos_sales,
    ranked.net_merchant_proceeds,
    deposit.available_balance::numeric(18,2),
    deposit.nsf_count::smallint,
    deposit.negative_balance_flag::boolean,
    ranked.funded_amount,
    ranked.total_repayment_amount,
    ranked.finance_charge_amount,
    ranked.remittance_rate,
    ranked.collection_horizon_days,
    ranked.implied_daily_collection_amount,
    ranked.source_m2_4_contract_row_hash,
    ranked.source_advance_row_hash,
    ranked.source_portfolio_row_hash,
    ranked.source_pos_set_hash,
    deposit.row_hash AS source_deposit_row_hash
FROM _m2_5_pos_ranked AS ranked
JOIN msbf_m1.merchant_deposit_daily_scenario AS deposit
  ON deposit.scenario_id = ranked.scenario_id
 AND deposit.population_id = ranked.population_id
 AND deposit.merchant_id = ranked.merchant_id
 AND deposit.observation_date = ranked.observation_date
WHERE ranked.recency_rank <= 120;

CREATE UNIQUE INDEX
ON _m2_5_replay_expected
(
    module1_run_id,
    scenario_id,
    merchant_application_id,
    monitoring_day_index
);

ANALYZE _m2_5_replay_expected;

DO $m2_5_replay_guard$
DECLARE
    v record;
BEGIN
    SELECT
        count(*) AS replay_rows,
        min(per_source.days) AS minimum_days,
        max(per_source.days) AS maximum_days,
        count(*) FILTER
        (
            WHERE per_source.days <> 120
        ) AS invalid_source_rows,
        count(*) FILTER
        (
            WHERE replay.source_pos_set_hash IS NULL
               OR replay.source_deposit_row_hash IS NULL
        ) AS missing_hash_rows
    INTO v
    FROM _m2_5_replay_expected AS replay
    CROSS JOIN LATERAL
    (
        SELECT count(*)::bigint AS days
        FROM _m2_5_replay_expected AS same_source
        WHERE same_source.module1_run_id = replay.module1_run_id
          AND same_source.scenario_id = replay.scenario_id
          AND same_source.merchant_application_id = replay.merchant_application_id
    ) AS per_source;

    IF v.replay_rows <> 7080
       OR v.minimum_days <> 120
       OR v.maximum_days <> 120
       OR v.invalid_source_rows <> 0
       OR v.missing_hash_rows <> 0 THEN
        RAISE EXCEPTION
            'M2.5 replay generation failed: %',
            row_to_json(v);
    END IF;
END;
$m2_5_replay_guard$;

/* ============================================================================
Section 5 — Window-based daily remittance, exposure and raw status metrics
============================================================================ */

DROP TABLE IF EXISTS _m2_5_daily_raw;

CREATE TEMP TABLE _m2_5_daily_raw
ON COMMIT DROP
AS
SELECT
    replay.module1_run_id,
    replay.scenario_id,
    replay.scenario_code,
    replay.merchant_application_id,
    replay.merchant_id,
    replay.synthetic_account_id,
    replay.synthetic_advance_id,
    replay.monitoring_day_index,
    replay.monitoring_date,
    replay.source_observation_date,
    replay.gross_pos_sales,
    replay.eligible_pos_sales,
    replay.net_merchant_proceeds,
    replay.available_balance,
    replay.nsf_count,
    replay.negative_balance_flag,
    replay.funded_amount,
    replay.total_repayment_amount,
    replay.finance_charge_amount,
    replay.remittance_rate,
    replay.collection_horizon_days,
    replay.implied_daily_collection_amount,
    replay.source_m2_4_contract_row_hash,
    replay.source_advance_row_hash,
    replay.source_portfolio_row_hash,
    replay.source_pos_set_hash,
    replay.source_deposit_row_hash,
    round
    (
        replay.eligible_pos_sales * replay.remittance_rate,
        2
    )::numeric(18,2) AS raw_remittance_amount
FROM _m2_5_replay_expected AS replay;

CREATE INDEX
ON _m2_5_daily_raw
(
    module1_run_id,
    scenario_id,
    merchant_application_id,
    monitoring_day_index
);

ANALYZE _m2_5_daily_raw;

DROP TABLE IF EXISTS _m2_5_daily_windows;

CREATE TEMP TABLE _m2_5_daily_windows
ON COMMIT DROP
AS
SELECT
    raw.module1_run_id,
    raw.scenario_id,
    raw.scenario_code,
    raw.merchant_application_id,
    raw.merchant_id,
    raw.synthetic_account_id,
    raw.synthetic_advance_id,
    raw.monitoring_day_index,
    raw.monitoring_date,
    raw.source_observation_date,
    raw.gross_pos_sales,
    raw.eligible_pos_sales,
    raw.net_merchant_proceeds,
    raw.available_balance,
    raw.nsf_count,
    raw.negative_balance_flag,
    raw.funded_amount,
    raw.total_repayment_amount,
    raw.finance_charge_amount,
    raw.remittance_rate,
    raw.collection_horizon_days,
    raw.implied_daily_collection_amount,
    raw.source_m2_4_contract_row_hash,
    raw.source_advance_row_hash,
    raw.source_portfolio_row_hash,
    raw.source_pos_set_hash,
    raw.source_deposit_row_hash,
    raw.raw_remittance_amount,

    coalesce
    (
        sum(raw.raw_remittance_amount) OVER
        (
            PARTITION BY
                raw.module1_run_id,
                raw.scenario_id,
                raw.merchant_application_id
            ORDER BY raw.monitoring_day_index
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ),
        0
    )::numeric(24,2) AS cumulative_raw_before,

    sum(raw.raw_remittance_amount) OVER
    (
        PARTITION BY
            raw.module1_run_id,
            raw.scenario_id,
            raw.merchant_application_id
        ORDER BY raw.monitoring_day_index
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )::numeric(24,2) AS cumulative_raw_through

FROM _m2_5_daily_raw AS raw;

CREATE INDEX
ON _m2_5_daily_windows
(
    module1_run_id,
    scenario_id,
    merchant_application_id,
    monitoring_day_index
);

ANALYZE _m2_5_daily_windows;

DROP TABLE IF EXISTS _m2_5_daily_actual;

CREATE TEMP TABLE _m2_5_daily_actual
ON COMMIT DROP
AS
SELECT
    windows.module1_run_id,
    windows.scenario_id,
    windows.scenario_code,
    windows.merchant_application_id,
    windows.merchant_id,
    windows.synthetic_account_id,
    windows.synthetic_advance_id,
    windows.monitoring_day_index,
    windows.monitoring_date,
    windows.source_observation_date,
    windows.gross_pos_sales,
    windows.eligible_pos_sales,
    windows.net_merchant_proceeds,
    windows.available_balance,
    windows.nsf_count,
    windows.negative_balance_flag,
    windows.funded_amount,
    windows.total_repayment_amount,
    windows.finance_charge_amount,
    windows.remittance_rate,
    windows.collection_horizon_days,
    windows.implied_daily_collection_amount,
    windows.source_m2_4_contract_row_hash,
    windows.source_advance_row_hash,
    windows.source_portfolio_row_hash,
    windows.source_pos_set_hash,
    windows.source_deposit_row_hash,
    windows.raw_remittance_amount,

    greatest
    (
        windows.total_repayment_amount - windows.cumulative_raw_before,
        0
    )::numeric(18,2) AS receivable_balance_before,

    least
    (
        windows.raw_remittance_amount,
        greatest
        (
            windows.total_repayment_amount - windows.cumulative_raw_before,
            0
        )
    )::numeric(18,2) AS actual_remittance_amount,

    least
    (
        windows.cumulative_raw_through,
        windows.total_repayment_amount
    )::numeric(18,2) AS cumulative_remittance_amount,

    greatest
    (
        windows.total_repayment_amount - windows.cumulative_raw_through,
        0
    )::numeric(18,2) AS receivable_balance_after,

    least
    (
        windows.implied_daily_collection_amount,
        greatest
        (
            windows.total_repayment_amount - windows.cumulative_raw_before,
            0
        )
    )::numeric(18,2) AS expected_due_today_amount,

    least
    (
        windows.implied_daily_collection_amount * windows.monitoring_day_index,
        windows.total_repayment_amount
    )::numeric(18,2) AS cumulative_expected_remittance_amount

FROM _m2_5_daily_windows AS windows;

CREATE INDEX
ON _m2_5_daily_actual
(
    module1_run_id,
    scenario_id,
    merchant_application_id,
    monitoring_day_index
);

ANALYZE _m2_5_daily_actual;

DROP TABLE IF EXISTS _m2_5_daily_activity_base;

CREATE TEMP TABLE _m2_5_daily_activity_base
ON COMMIT DROP
AS
SELECT
    actual.module1_run_id,
    actual.scenario_id,
    actual.scenario_code,
    actual.merchant_application_id,
    actual.merchant_id,
    actual.synthetic_account_id,
    actual.synthetic_advance_id,
    actual.monitoring_day_index,
    actual.monitoring_date,
    actual.source_observation_date,
    actual.gross_pos_sales,
    actual.eligible_pos_sales,
    actual.net_merchant_proceeds,
    actual.available_balance,
    actual.nsf_count,
    actual.negative_balance_flag,
    actual.funded_amount,
    actual.total_repayment_amount,
    actual.finance_charge_amount,
    actual.remittance_rate,
    actual.collection_horizon_days,
    actual.implied_daily_collection_amount,
    actual.source_m2_4_contract_row_hash,
    actual.source_advance_row_hash,
    actual.source_portfolio_row_hash,
    actual.source_pos_set_hash,
    actual.source_deposit_row_hash,
    actual.raw_remittance_amount,
    actual.receivable_balance_before,
    actual.actual_remittance_amount,
    actual.cumulative_remittance_amount,
    actual.receivable_balance_after,
    actual.expected_due_today_amount,
    actual.cumulative_expected_remittance_amount,

    greatest
    (
        actual.expected_due_today_amount - actual.actual_remittance_amount,
        0
    )::numeric(18,2) AS daily_shortfall_amount,

    greatest
    (
        actual.cumulative_expected_remittance_amount -
        actual.cumulative_remittance_amount,
        0
    )::numeric(18,2) AS cumulative_shortfall_amount,

    CASE
        WHEN actual.expected_due_today_amount > 0
        THEN round
        (
            actual.actual_remittance_amount /
            actual.expected_due_today_amount,
            8
        )::numeric(12,8)
        ELSE 1.00000000::numeric(12,8)
    END AS remittance_coverage_ratio,

    CASE
        WHEN actual.cumulative_expected_remittance_amount > 0
        THEN round
        (
            actual.cumulative_remittance_amount /
            actual.cumulative_expected_remittance_amount,
            8
        )::numeric(12,8)
        ELSE 1.00000000::numeric(12,8)
    END AS cumulative_pace_ratio,

    round
    (
        actual.funded_amount *
        actual.receivable_balance_after /
        nullif(actual.total_repayment_amount, 0),
        2
    )::numeric(18,2) AS principal_exposure_proxy,

    round
    (
        actual.receivable_balance_after -
        (
            actual.funded_amount *
            actual.receivable_balance_after /
            nullif(actual.total_repayment_amount, 0)
        ),
        2
    )::numeric(18,2) AS unearned_finance_charge_proxy,

    sum
    (
        CASE
            WHEN actual.eligible_pos_sales > 0 THEN 1
            ELSE 0
        END
    ) OVER
    (
        PARTITION BY
            actual.module1_run_id,
            actual.scenario_id,
            actual.merchant_application_id
        ORDER BY actual.monitoring_day_index
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )::integer AS zero_sales_group,

    max
    (
        CASE
            WHEN actual.actual_remittance_amount > 0
            THEN actual.monitoring_day_index
            ELSE NULL
        END
    ) OVER
    (
        PARTITION BY
            actual.module1_run_id,
            actual.scenario_id,
            actual.merchant_application_id
        ORDER BY actual.monitoring_day_index
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )::integer AS last_positive_remittance_day,

    sum(actual.actual_remittance_amount) OVER
    (
        PARTITION BY
            actual.module1_run_id,
            actual.scenario_id,
            actual.merchant_application_id
        ORDER BY actual.monitoring_day_index
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )::numeric(18,2) AS trailing_7_day_remittance_amount,

    sum(actual.actual_remittance_amount) OVER
    (
        PARTITION BY
            actual.module1_run_id,
            actual.scenario_id,
            actual.merchant_application_id
        ORDER BY actual.monitoring_day_index
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    )::numeric(18,2) AS trailing_30_day_remittance_amount

FROM _m2_5_daily_actual AS actual;

CREATE INDEX
ON _m2_5_daily_activity_base
(
    module1_run_id,
    scenario_id,
    merchant_application_id,
    monitoring_day_index
);

ANALYZE _m2_5_daily_activity_base;

DROP TABLE IF EXISTS _m2_5_daily_activity;

CREATE TEMP TABLE _m2_5_daily_activity
ON COMMIT DROP
AS
SELECT
    base.module1_run_id,
    base.scenario_id,
    base.scenario_code,
    base.merchant_application_id,
    base.merchant_id,
    base.synthetic_account_id,
    base.synthetic_advance_id,
    base.monitoring_day_index,
    base.monitoring_date,
    base.source_observation_date,
    base.gross_pos_sales,
    base.eligible_pos_sales,
    base.net_merchant_proceeds,
    base.available_balance,
    base.nsf_count,
    base.negative_balance_flag,
    base.funded_amount,
    base.total_repayment_amount,
    base.finance_charge_amount,
    base.remittance_rate,
    base.collection_horizon_days,
    base.implied_daily_collection_amount,
    base.source_m2_4_contract_row_hash,
    base.source_advance_row_hash,
    base.source_portfolio_row_hash,
    base.source_pos_set_hash,
    base.source_deposit_row_hash,
    base.raw_remittance_amount,
    base.receivable_balance_before,
    base.actual_remittance_amount,
    base.cumulative_remittance_amount,
    base.receivable_balance_after,
    base.expected_due_today_amount,
    base.cumulative_expected_remittance_amount,
    base.daily_shortfall_amount,
    base.cumulative_shortfall_amount,
    base.remittance_coverage_ratio,
    base.cumulative_pace_ratio,
    base.principal_exposure_proxy,
    base.unearned_finance_charge_proxy,
    base.trailing_7_day_remittance_amount,
    base.trailing_30_day_remittance_amount,

    (
        base.monitoring_day_index -
        coalesce(base.last_positive_remittance_day, 0)
    )::integer AS days_since_last_positive_remittance,

    CASE
        WHEN base.eligible_pos_sales = 0
        THEN row_number() OVER
        (
            PARTITION BY
                base.module1_run_id,
                base.scenario_id,
                base.merchant_application_id,
                base.zero_sales_group
            ORDER BY base.monitoring_day_index
        )::integer
        ELSE 0::integer
    END AS zero_sales_streak_days

FROM _m2_5_daily_activity_base AS base;

CREATE INDEX
ON _m2_5_daily_activity
(
    module1_run_id,
    scenario_id,
    merchant_application_id,
    monitoring_day_index
);

ANALYZE _m2_5_daily_activity;

DROP TABLE IF EXISTS _m2_5_daily_pre_floor;

CREATE TEMP TABLE _m2_5_daily_pre_floor
ON COMMIT DROP
AS
SELECT
    activity.module1_run_id,
    activity.scenario_id,
    activity.scenario_code,
    activity.merchant_application_id,
    activity.merchant_id,
    activity.synthetic_account_id,
    activity.synthetic_advance_id,
    activity.monitoring_day_index,
    activity.monitoring_date,
    activity.source_observation_date,
    activity.gross_pos_sales,
    activity.eligible_pos_sales,
    activity.net_merchant_proceeds,
    activity.available_balance,
    activity.nsf_count,
    activity.negative_balance_flag,
    activity.funded_amount,
    activity.total_repayment_amount,
    activity.finance_charge_amount,
    activity.remittance_rate,
    activity.collection_horizon_days,
    activity.implied_daily_collection_amount,
    activity.source_m2_4_contract_row_hash,
    activity.source_advance_row_hash,
    activity.source_portfolio_row_hash,
    activity.source_pos_set_hash,
    activity.source_deposit_row_hash,
    activity.raw_remittance_amount,
    activity.receivable_balance_before,
    activity.actual_remittance_amount,
    activity.cumulative_remittance_amount,
    activity.receivable_balance_after,
    activity.expected_due_today_amount,
    activity.cumulative_expected_remittance_amount,
    activity.daily_shortfall_amount,
    activity.cumulative_shortfall_amount,
    activity.remittance_coverage_ratio,
    activity.cumulative_pace_ratio,
    activity.principal_exposure_proxy,
    activity.unearned_finance_charge_proxy,
    activity.days_since_last_positive_remittance,
    activity.zero_sales_streak_days,
    activity.trailing_7_day_remittance_amount,
    activity.trailing_30_day_remittance_amount,

    (activity.daily_shortfall_amount > 0) AS daily_shortfall_alert_flag,
    (
        activity.monitoring_day_index >= 7
        AND activity.cumulative_pace_ratio < 0.90000000
    ) AS cumulative_pace_watch_alert_flag,
    (
        activity.monitoring_day_index >= 14
        AND activity.cumulative_pace_ratio < 0.75000000
    ) AS cumulative_pace_high_alert_flag,
    (
        activity.zero_sales_streak_days >= 10
    ) AS zero_sales_streak_alert_flag,
    (
        activity.available_balance < 0
        OR activity.nsf_count > 0
        OR activity.negative_balance_flag
    ) AS liquidity_stress_alert_flag,
    (
        activity.monitoring_day_index > activity.collection_horizon_days
        AND activity.receivable_balance_after > 0
    ) AS horizon_overrun_alert_flag,
    (activity.receivable_balance_after = 0) AS paid_off_flag,

    CASE
        WHEN activity.receivable_balance_after = 0 THEN 0
        WHEN activity.monitoring_day_index >= 14
         AND activity.days_since_last_positive_remittance >= 14 THEN 5
        WHEN activity.monitoring_day_index >= 14
         AND
         (
             activity.cumulative_pace_ratio < 0.50000000
             OR activity.zero_sales_streak_days >= 10
             OR
             (
                 activity.monitoring_day_index > activity.collection_horizon_days
                 AND activity.receivable_balance_after > 0
             )
         ) THEN 4
        WHEN activity.monitoring_day_index >= 14
         AND
         (
             activity.cumulative_pace_ratio < 0.75000000
             OR activity.days_since_last_positive_remittance >= 7
         ) THEN 3
        WHEN activity.monitoring_day_index >= 7
         AND
         (
             activity.cumulative_pace_ratio < 0.90000000
             OR activity.remittance_coverage_ratio < 0.75000000
             OR activity.available_balance < 0
             OR activity.nsf_count > 0
             OR activity.negative_balance_flag
         ) THEN 2
        ELSE 1
    END::integer AS raw_monitoring_status_rank

FROM _m2_5_daily_activity AS activity;

CREATE INDEX
ON _m2_5_daily_pre_floor
(
    module1_run_id,
    scenario_id,
    merchant_application_id,
    monitoring_day_index
);

ANALYZE _m2_5_daily_pre_floor;

/* ============================================================================
Section 6 — Matched baseline/stress monitoring-status floor
============================================================================ */

DROP TABLE IF EXISTS _m2_5_daily_floor;

CREATE TEMP TABLE _m2_5_daily_floor
ON COMMIT DROP
AS
SELECT
    stress_or_baseline.module1_run_id,
    stress_or_baseline.scenario_id,
    stress_or_baseline.scenario_code,
    stress_or_baseline.merchant_application_id,
    stress_or_baseline.merchant_id,
    stress_or_baseline.synthetic_account_id,
    stress_or_baseline.synthetic_advance_id,
    stress_or_baseline.monitoring_day_index,
    stress_or_baseline.monitoring_date,
    stress_or_baseline.source_observation_date,
    stress_or_baseline.gross_pos_sales,
    stress_or_baseline.eligible_pos_sales,
    stress_or_baseline.net_merchant_proceeds,
    stress_or_baseline.available_balance,
    stress_or_baseline.nsf_count,
    stress_or_baseline.negative_balance_flag,
    stress_or_baseline.funded_amount,
    stress_or_baseline.total_repayment_amount,
    stress_or_baseline.finance_charge_amount,
    stress_or_baseline.remittance_rate,
    stress_or_baseline.collection_horizon_days,
    stress_or_baseline.implied_daily_collection_amount,
    stress_or_baseline.source_m2_4_contract_row_hash,
    stress_or_baseline.source_advance_row_hash,
    stress_or_baseline.source_portfolio_row_hash,
    stress_or_baseline.source_pos_set_hash,
    stress_or_baseline.source_deposit_row_hash,
    stress_or_baseline.raw_remittance_amount,
    stress_or_baseline.receivable_balance_before,
    stress_or_baseline.actual_remittance_amount,
    stress_or_baseline.cumulative_remittance_amount,
    stress_or_baseline.receivable_balance_after,
    stress_or_baseline.expected_due_today_amount,
    stress_or_baseline.cumulative_expected_remittance_amount,
    stress_or_baseline.daily_shortfall_amount,
    stress_or_baseline.cumulative_shortfall_amount,
    stress_or_baseline.remittance_coverage_ratio,
    stress_or_baseline.cumulative_pace_ratio,
    stress_or_baseline.principal_exposure_proxy,
    stress_or_baseline.unearned_finance_charge_proxy,
    stress_or_baseline.days_since_last_positive_remittance,
    stress_or_baseline.zero_sales_streak_days,
    stress_or_baseline.trailing_7_day_remittance_amount,
    stress_or_baseline.trailing_30_day_remittance_amount,
    stress_or_baseline.daily_shortfall_alert_flag,
    stress_or_baseline.cumulative_pace_watch_alert_flag,
    stress_or_baseline.cumulative_pace_high_alert_flag,
    stress_or_baseline.zero_sales_streak_alert_flag,
    stress_or_baseline.liquidity_stress_alert_flag,
    stress_or_baseline.horizon_overrun_alert_flag,
    stress_or_baseline.paid_off_flag,
    stress_or_baseline.raw_monitoring_status_rank,

    CASE stress_or_baseline.raw_monitoring_status_rank
        WHEN 0 THEN 'PAID_OFF'
        WHEN 1 THEN 'CURRENT'
        WHEN 2 THEN 'WATCH'
        WHEN 3 THEN 'UNDERPERFORMING'
        WHEN 4 THEN 'SEVERE_SHORTFALL'
        WHEN 5 THEN 'DORMANT_NO_REMITTANCE'
        ELSE 'DORMANT_NO_REMITTANCE'
    END AS raw_monitoring_status_code,

    CASE
        WHEN stress_or_baseline.scenario_code = 'RECESSION_ENERGY'
         AND baseline.raw_monitoring_status_rank IS NOT NULL
         AND stress_or_baseline.receivable_balance_after > 0
         AND baseline.receivable_balance_after > 0
        THEN greatest
             (
                 stress_or_baseline.raw_monitoring_status_rank,
                 baseline.raw_monitoring_status_rank
             )
        ELSE stress_or_baseline.raw_monitoring_status_rank
    END::integer AS monitoring_status_rank,

    (
        stress_or_baseline.scenario_code = 'RECESSION_ENERGY'
        AND baseline.raw_monitoring_status_rank IS NOT NULL
        AND stress_or_baseline.receivable_balance_after > 0
        AND baseline.receivable_balance_after > 0
        AND stress_or_baseline.raw_monitoring_status_rank <
            baseline.raw_monitoring_status_rank
    ) AS stress_status_floor_applied_flag

FROM _m2_5_daily_pre_floor AS stress_or_baseline
LEFT JOIN _m2_5_daily_pre_floor AS baseline
  ON baseline.module1_run_id = stress_or_baseline.module1_run_id
 AND baseline.merchant_application_id = stress_or_baseline.merchant_application_id
 AND baseline.monitoring_day_index = stress_or_baseline.monitoring_day_index
 AND baseline.scenario_code = 'BASELINE';

CREATE INDEX
ON _m2_5_daily_floor
(
    module1_run_id,
    scenario_id,
    merchant_application_id,
    monitoring_day_index
);

ANALYZE _m2_5_daily_floor;

/* ============================================================================
Section 7 — Target-typed daily contract and physical row hash
============================================================================ */

DROP TABLE IF EXISTS _m2_5_daily_expected;

CREATE TEMP TABLE _m2_5_daily_expected
(
    module1_run_id                         bigint NOT NULL,
    scenario_id                            bigint NOT NULL,
    scenario_code                          text NOT NULL,
    merchant_application_id                text NOT NULL,
    merchant_id                            text NOT NULL,
    synthetic_account_id                   text NOT NULL,
    synthetic_advance_id                   text NOT NULL,
    monitoring_day_index                   integer NOT NULL,
    monitoring_date                        date NOT NULL,
    source_observation_date                date NOT NULL,
    source_gross_pos_sales                 numeric(18,2) NOT NULL,
    source_eligible_pos_sales              numeric(18,2) NOT NULL,
    source_net_merchant_proceeds           numeric(18,2) NOT NULL,
    source_available_balance               numeric(18,2) NOT NULL,
    source_nsf_count                       smallint NOT NULL,
    source_negative_balance_flag           boolean NOT NULL,
    contracted_remittance_rate             numeric(9,6) NOT NULL,
    expected_daily_remittance_amount       numeric(18,2) NOT NULL,
    expected_due_today_amount              numeric(18,2) NOT NULL,
    raw_remittance_amount                  numeric(18,2) NOT NULL,
    actual_remittance_amount               numeric(18,2) NOT NULL,
    cumulative_remittance_amount           numeric(18,2) NOT NULL,
    cumulative_expected_remittance_amount  numeric(18,2) NOT NULL,
    daily_shortfall_amount                 numeric(18,2) NOT NULL,
    cumulative_shortfall_amount            numeric(18,2) NOT NULL,
    remittance_coverage_ratio              numeric(12,8),
    cumulative_pace_ratio                  numeric(12,8),
    receivable_balance_before              numeric(18,2) NOT NULL,
    receivable_balance_after               numeric(18,2) NOT NULL,
    principal_exposure_proxy               numeric(18,2) NOT NULL,
    unearned_finance_charge_proxy          numeric(18,2) NOT NULL,
    days_since_last_positive_remittance    integer NOT NULL,
    zero_sales_streak_days                 integer NOT NULL,
    trailing_7_day_remittance_amount       numeric(18,2) NOT NULL,
    trailing_30_day_remittance_amount      numeric(18,2) NOT NULL,
    raw_monitoring_status_code             text NOT NULL,
    raw_monitoring_status_rank             integer NOT NULL,
    monitoring_status_code                 text NOT NULL,
    monitoring_status_rank                 integer NOT NULL,
    stress_status_floor_applied_flag       boolean NOT NULL,
    daily_shortfall_alert_flag             boolean NOT NULL,
    cumulative_pace_watch_alert_flag       boolean NOT NULL,
    cumulative_pace_high_alert_flag        boolean NOT NULL,
    zero_sales_streak_alert_flag           boolean NOT NULL,
    liquidity_stress_alert_flag            boolean NOT NULL,
    horizon_overrun_alert_flag             boolean NOT NULL,
    paid_off_flag                          boolean NOT NULL,
    primary_monitoring_reason_code         text NOT NULL,
    monitoring_reason_codes               jsonb NOT NULL,
    alert_payload                          jsonb NOT NULL,
    source_m2_4_contract_row_hash          text NOT NULL,
    source_advance_row_hash                text NOT NULL,
    source_portfolio_row_hash              text NOT NULL,
    source_pos_set_hash                    text NOT NULL,
    source_deposit_row_hash                text NOT NULL,
    policy_configuration_hash              text NOT NULL,
    row_hash                               text
)
ON COMMIT DROP;

INSERT INTO _m2_5_daily_expected
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    merchant_id,
    synthetic_account_id,
    synthetic_advance_id,
    monitoring_day_index,
    monitoring_date,
    source_observation_date,
    source_gross_pos_sales,
    source_eligible_pos_sales,
    source_net_merchant_proceeds,
    source_available_balance,
    source_nsf_count,
    source_negative_balance_flag,
    contracted_remittance_rate,
    expected_daily_remittance_amount,
    expected_due_today_amount,
    raw_remittance_amount,
    actual_remittance_amount,
    cumulative_remittance_amount,
    cumulative_expected_remittance_amount,
    daily_shortfall_amount,
    cumulative_shortfall_amount,
    remittance_coverage_ratio,
    cumulative_pace_ratio,
    receivable_balance_before,
    receivable_balance_after,
    principal_exposure_proxy,
    unearned_finance_charge_proxy,
    days_since_last_positive_remittance,
    zero_sales_streak_days,
    trailing_7_day_remittance_amount,
    trailing_30_day_remittance_amount,
    raw_monitoring_status_code,
    raw_monitoring_status_rank,
    monitoring_status_code,
    monitoring_status_rank,
    stress_status_floor_applied_flag,
    daily_shortfall_alert_flag,
    cumulative_pace_watch_alert_flag,
    cumulative_pace_high_alert_flag,
    zero_sales_streak_alert_flag,
    liquidity_stress_alert_flag,
    horizon_overrun_alert_flag,
    paid_off_flag,
    primary_monitoring_reason_code,
    monitoring_reason_codes,
    alert_payload,
    source_m2_4_contract_row_hash,
    source_advance_row_hash,
    source_portfolio_row_hash,
    source_pos_set_hash,
    source_deposit_row_hash,
    policy_configuration_hash,
    row_hash
)
SELECT
    floor.module1_run_id,
    floor.scenario_id,
    floor.scenario_code,
    floor.merchant_application_id,
    floor.merchant_id,
    floor.synthetic_account_id,
    floor.synthetic_advance_id,
    floor.monitoring_day_index,
    floor.monitoring_date,
    floor.source_observation_date,
    floor.gross_pos_sales,
    floor.eligible_pos_sales,
    floor.net_merchant_proceeds,
    floor.available_balance,
    floor.nsf_count,
    floor.negative_balance_flag,
    floor.remittance_rate,
    floor.implied_daily_collection_amount,
    floor.expected_due_today_amount,
    floor.raw_remittance_amount,
    floor.actual_remittance_amount,
    floor.cumulative_remittance_amount,
    floor.cumulative_expected_remittance_amount,
    floor.daily_shortfall_amount,
    floor.cumulative_shortfall_amount,
    floor.remittance_coverage_ratio,
    floor.cumulative_pace_ratio,
    floor.receivable_balance_before,
    floor.receivable_balance_after,
    floor.principal_exposure_proxy,
    floor.unearned_finance_charge_proxy,
    floor.days_since_last_positive_remittance,
    floor.zero_sales_streak_days,
    floor.trailing_7_day_remittance_amount,
    floor.trailing_30_day_remittance_amount,
    floor.raw_monitoring_status_code,
    floor.raw_monitoring_status_rank,

    CASE floor.monitoring_status_rank
        WHEN 0 THEN 'PAID_OFF'
        WHEN 1 THEN 'CURRENT'
        WHEN 2 THEN 'WATCH'
        WHEN 3 THEN 'UNDERPERFORMING'
        WHEN 4 THEN 'SEVERE_SHORTFALL'
        WHEN 5 THEN 'DORMANT_NO_REMITTANCE'
        ELSE 'DORMANT_NO_REMITTANCE'
    END,

    floor.monitoring_status_rank,
    floor.stress_status_floor_applied_flag,
    floor.daily_shortfall_alert_flag,
    floor.cumulative_pace_watch_alert_flag,
    floor.cumulative_pace_high_alert_flag,
    floor.zero_sales_streak_alert_flag,
    floor.liquidity_stress_alert_flag,
    floor.horizon_overrun_alert_flag,
    floor.paid_off_flag,

    CASE
        WHEN floor.stress_status_floor_applied_flag
            THEN 'M2_5_STRESS_STATUS_FLOOR'
        WHEN floor.monitoring_status_rank = 0
            THEN 'M2_5_STATUS_PAID_OFF'
        WHEN floor.monitoring_status_rank = 1
            THEN 'M2_5_STATUS_CURRENT'
        WHEN floor.monitoring_status_rank = 2
            THEN 'M2_5_STATUS_WATCH'
        WHEN floor.monitoring_status_rank = 3
            THEN 'M2_5_STATUS_UNDERPERFORMING'
        WHEN floor.monitoring_status_rank = 4
            THEN 'M2_5_STATUS_SEVERE_SHORTFALL'
        WHEN floor.monitoring_status_rank = 5
            THEN 'M2_5_STATUS_DORMANT_NO_REMITTANCE'
        ELSE 'M2_5_FALLBACK_MONITORING_GUARD'
    END,

    to_jsonb
    (
        array_remove
        (
            ARRAY
            [
                CASE
                    WHEN floor.stress_status_floor_applied_flag
                        THEN 'M2_5_STRESS_STATUS_FLOOR'
                    WHEN floor.monitoring_status_rank = 0
                        THEN 'M2_5_STATUS_PAID_OFF'
                    WHEN floor.monitoring_status_rank = 1
                        THEN 'M2_5_STATUS_CURRENT'
                    WHEN floor.monitoring_status_rank = 2
                        THEN 'M2_5_STATUS_WATCH'
                    WHEN floor.monitoring_status_rank = 3
                        THEN 'M2_5_STATUS_UNDERPERFORMING'
                    WHEN floor.monitoring_status_rank = 4
                        THEN 'M2_5_STATUS_SEVERE_SHORTFALL'
                    WHEN floor.monitoring_status_rank = 5
                        THEN 'M2_5_STATUS_DORMANT_NO_REMITTANCE'
                    ELSE 'M2_5_FALLBACK_MONITORING_GUARD'
                END,
                CASE WHEN floor.daily_shortfall_alert_flag
                     THEN 'M2_5_DAILY_COLLECTION_SHORTFALL' END,
                CASE WHEN floor.cumulative_pace_watch_alert_flag
                     THEN 'M2_5_CUMULATIVE_PACE_BELOW_90' END,
                CASE WHEN floor.cumulative_pace_high_alert_flag
                     THEN 'M2_5_CUMULATIVE_PACE_BELOW_75' END,
                CASE WHEN floor.cumulative_pace_ratio < 0.50000000
                     THEN 'M2_5_CUMULATIVE_PACE_BELOW_50' END,
                CASE WHEN floor.zero_sales_streak_alert_flag
                     THEN 'M2_5_ZERO_SALES_STREAK' END,
                CASE WHEN floor.liquidity_stress_alert_flag
                     THEN 'M2_5_LIQUIDITY_STRESS' END,
                CASE WHEN floor.horizon_overrun_alert_flag
                     THEN 'M2_5_HORIZON_OVERRUN' END,
                'M2_5_SOURCE_M2_4_ACCEPTED',
                'M2_5_SOURCE_M1_6_ACCEPTED',
                'M2_5_MONITORING_ONLY'
            ]::text[],
            NULL
        )
    ),

    jsonb_build_object
    (
        'daily_collection_shortfall', floor.daily_shortfall_alert_flag,
        'cumulative_pace_below_90', floor.cumulative_pace_watch_alert_flag,
        'cumulative_pace_below_75', floor.cumulative_pace_high_alert_flag,
        'zero_sales_streak', floor.zero_sales_streak_alert_flag,
        'liquidity_stress', floor.liquidity_stress_alert_flag,
        'contract_horizon_overrun', floor.horizon_overrun_alert_flag,
        'stress_status_floor', floor.stress_status_floor_applied_flag,
        'paid_off', floor.paid_off_flag
    ),

    floor.source_m2_4_contract_row_hash,
    floor.source_advance_row_hash,
    floor.source_portfolio_row_hash,
    floor.source_pos_set_hash,
    floor.source_deposit_row_hash,
    ctx.configuration_hash,
    NULL::text

FROM _m2_5_daily_floor AS floor
CROSS JOIN _m2_5_ctx AS ctx;

UPDATE _m2_5_daily_expected AS daily
SET row_hash = msbf_ctl.m2_5_hash_jsonb
(
    to_jsonb(daily) - 'row_hash'
)
WHERE daily.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_5_daily_expected
(
    module1_run_id,
    scenario_id,
    merchant_application_id,
    monitoring_day_index
);

ANALYZE _m2_5_daily_expected;

DO $m2_5_daily_guard$
DECLARE
    v record;
BEGIN
    SELECT
        count(*) AS daily_rows,
        count(*) FILTER(WHERE scenario_code = 'BASELINE') AS baseline_rows,
        count(*) FILTER(WHERE scenario_code = 'RECESSION_ENERGY') AS stress_rows,
        min(per_source.days) AS minimum_days,
        max(per_source.days) AS maximum_days,
        count(*) FILTER
        (
            WHERE actual_remittance_amount > raw_remittance_amount + 0.01
               OR actual_remittance_amount > receivable_balance_before + 0.01
               OR receivable_balance_after < 0
               OR row_hash IS NULL
               OR monitoring_status_rank NOT BETWEEN 0 AND 5
        ) AS invalid_rows,
        count(*) FILTER
        (
            WHERE scenario_code = 'RECESSION_ENERGY'
              AND monitoring_status_rank < raw_monitoring_status_rank
        ) AS invalid_stress_floor_rows
    INTO v
    FROM _m2_5_daily_expected AS daily
    CROSS JOIN LATERAL
    (
        SELECT count(*)::bigint AS days
        FROM _m2_5_daily_expected AS same_source
        WHERE same_source.module1_run_id = daily.module1_run_id
          AND same_source.scenario_id = daily.scenario_id
          AND same_source.merchant_application_id = daily.merchant_application_id
    ) AS per_source;

    IF v.daily_rows <> 7080
       OR v.baseline_rows <> 5280
       OR v.stress_rows <> 1800
       OR v.minimum_days <> 120
       OR v.maximum_days <> 120
       OR v.invalid_rows <> 0
       OR v.invalid_stress_floor_rows <> 0 THEN
        RAISE EXCEPTION
            'M2.5 daily generation failed: %',
            row_to_json(v);
    END IF;
END;
$m2_5_daily_guard$;

INSERT INTO msbf_m2.advance_daily_remittance_monitoring
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    merchant_id,
    synthetic_account_id,
    synthetic_advance_id,
    monitoring_day_index,
    monitoring_date,
    source_observation_date,
    source_gross_pos_sales,
    source_eligible_pos_sales,
    source_net_merchant_proceeds,
    source_available_balance,
    source_nsf_count,
    source_negative_balance_flag,
    contracted_remittance_rate,
    expected_daily_remittance_amount,
    expected_due_today_amount,
    raw_remittance_amount,
    actual_remittance_amount,
    cumulative_remittance_amount,
    cumulative_expected_remittance_amount,
    daily_shortfall_amount,
    cumulative_shortfall_amount,
    remittance_coverage_ratio,
    cumulative_pace_ratio,
    receivable_balance_before,
    receivable_balance_after,
    principal_exposure_proxy,
    unearned_finance_charge_proxy,
    days_since_last_positive_remittance,
    zero_sales_streak_days,
    trailing_7_day_remittance_amount,
    trailing_30_day_remittance_amount,
    raw_monitoring_status_code,
    raw_monitoring_status_rank,
    monitoring_status_code,
    monitoring_status_rank,
    stress_status_floor_applied_flag,
    daily_shortfall_alert_flag,
    cumulative_pace_watch_alert_flag,
    cumulative_pace_high_alert_flag,
    zero_sales_streak_alert_flag,
    liquidity_stress_alert_flag,
    horizon_overrun_alert_flag,
    paid_off_flag,
    primary_monitoring_reason_code,
    monitoring_reason_codes,
    alert_payload,
    source_m2_4_contract_row_hash,
    source_advance_row_hash,
    source_portfolio_row_hash,
    source_pos_set_hash,
    source_deposit_row_hash,
    policy_configuration_hash,
    row_hash
)
SELECT
    daily.module1_run_id,
    daily.scenario_id,
    daily.scenario_code,
    daily.merchant_application_id,
    daily.merchant_id,
    daily.synthetic_account_id,
    daily.synthetic_advance_id,
    daily.monitoring_day_index,
    daily.monitoring_date,
    daily.source_observation_date,
    daily.source_gross_pos_sales,
    daily.source_eligible_pos_sales,
    daily.source_net_merchant_proceeds,
    daily.source_available_balance,
    daily.source_nsf_count,
    daily.source_negative_balance_flag,
    daily.contracted_remittance_rate,
    daily.expected_daily_remittance_amount,
    daily.expected_due_today_amount,
    daily.raw_remittance_amount,
    daily.actual_remittance_amount,
    daily.cumulative_remittance_amount,
    daily.cumulative_expected_remittance_amount,
    daily.daily_shortfall_amount,
    daily.cumulative_shortfall_amount,
    daily.remittance_coverage_ratio,
    daily.cumulative_pace_ratio,
    daily.receivable_balance_before,
    daily.receivable_balance_after,
    daily.principal_exposure_proxy,
    daily.unearned_finance_charge_proxy,
    daily.days_since_last_positive_remittance,
    daily.zero_sales_streak_days,
    daily.trailing_7_day_remittance_amount,
    daily.trailing_30_day_remittance_amount,
    daily.raw_monitoring_status_code,
    daily.raw_monitoring_status_rank,
    daily.monitoring_status_code,
    daily.monitoring_status_rank,
    daily.stress_status_floor_applied_flag,
    daily.daily_shortfall_alert_flag,
    daily.cumulative_pace_watch_alert_flag,
    daily.cumulative_pace_high_alert_flag,
    daily.zero_sales_streak_alert_flag,
    daily.liquidity_stress_alert_flag,
    daily.horizon_overrun_alert_flag,
    daily.paid_off_flag,
    daily.primary_monitoring_reason_code,
    daily.monitoring_reason_codes,
    daily.alert_payload,
    daily.source_m2_4_contract_row_hash,
    daily.source_advance_row_hash,
    daily.source_portfolio_row_hash,
    daily.source_pos_set_hash,
    daily.source_deposit_row_hash,
    daily.policy_configuration_hash,
    daily.row_hash
FROM _m2_5_daily_expected AS daily;

/* ============================================================================
Section 8 — Latest monitoring contract and immutable archive
============================================================================ */

DROP TABLE IF EXISTS _m2_5_payoff_summary;

CREATE TEMP TABLE _m2_5_payoff_summary
ON COMMIT DROP
AS
SELECT
    daily.module1_run_id,
    daily.scenario_id,
    daily.merchant_application_id,
    min(daily.monitoring_day_index) FILTER
    (
        WHERE daily.paid_off_flag
    )::integer AS payoff_day_index
FROM _m2_5_daily_expected AS daily
GROUP BY
    daily.module1_run_id,
    daily.scenario_id,
    daily.merchant_application_id;

CREATE UNIQUE INDEX
ON _m2_5_payoff_summary
(
    module1_run_id,
    scenario_id,
    merchant_application_id
);

ANALYZE _m2_5_payoff_summary;

DROP TABLE IF EXISTS _m2_5_latest_expected;

CREATE TEMP TABLE _m2_5_latest_expected
(
    module1_run_id                         bigint NOT NULL,
    contract_code                          text NOT NULL,
    contract_version                       integer NOT NULL,
    schema_version                         text NOT NULL,
    methodology_version                    text NOT NULL,
    scenario_id                            bigint NOT NULL,
    scenario_code                          text NOT NULL,
    merchant_application_id                text NOT NULL,
    merchant_id                            text NOT NULL,
    synthetic_account_id                   text NOT NULL,
    synthetic_advance_id                   text NOT NULL,
    monitoring_horizon_days                integer NOT NULL,
    latest_monitoring_day_index            integer NOT NULL,
    latest_monitoring_date                 date NOT NULL,
    latest_monitoring_status_code          text NOT NULL,
    latest_monitoring_status_rank          integer NOT NULL,
    latest_raw_monitoring_status_code      text NOT NULL,
    latest_raw_monitoring_status_rank      integer NOT NULL,
    stress_status_floor_applied_flag       boolean NOT NULL,
    paid_off_flag                          boolean NOT NULL,
    payoff_day_index                       integer,
    cumulative_remittance_amount           numeric(18,2) NOT NULL,
    remaining_receivable_amount            numeric(18,2) NOT NULL,
    principal_exposure_proxy               numeric(18,2) NOT NULL,
    unearned_finance_charge_proxy          numeric(18,2) NOT NULL,
    cumulative_expected_remittance_amount  numeric(18,2) NOT NULL,
    cumulative_shortfall_amount            numeric(18,2) NOT NULL,
    cumulative_pace_ratio                  numeric(12,8),
    trailing_7_day_remittance_amount       numeric(18,2) NOT NULL,
    trailing_30_day_remittance_amount      numeric(18,2) NOT NULL,
    days_since_last_positive_remittance    integer NOT NULL,
    zero_sales_streak_days                 integer NOT NULL,
    current_available_balance              numeric(18,2) NOT NULL,
    current_nsf_count                      smallint NOT NULL,
    active_alert_count                     integer NOT NULL,
    primary_monitoring_reason_code         text NOT NULL,
    alert_payload                          jsonb NOT NULL,
    source_daily_row_hash                  text NOT NULL,
    source_m2_4_contract_row_hash          text NOT NULL,
    source_advance_row_hash                text NOT NULL,
    source_portfolio_row_hash              text NOT NULL,
    policy_configuration_hash              text NOT NULL,
    contract_row_hash                      text
)
ON COMMIT DROP;

INSERT INTO _m2_5_latest_expected
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    merchant_id,
    synthetic_account_id,
    synthetic_advance_id,
    monitoring_horizon_days,
    latest_monitoring_day_index,
    latest_monitoring_date,
    latest_monitoring_status_code,
    latest_monitoring_status_rank,
    latest_raw_monitoring_status_code,
    latest_raw_monitoring_status_rank,
    stress_status_floor_applied_flag,
    paid_off_flag,
    payoff_day_index,
    cumulative_remittance_amount,
    remaining_receivable_amount,
    principal_exposure_proxy,
    unearned_finance_charge_proxy,
    cumulative_expected_remittance_amount,
    cumulative_shortfall_amount,
    cumulative_pace_ratio,
    trailing_7_day_remittance_amount,
    trailing_30_day_remittance_amount,
    days_since_last_positive_remittance,
    zero_sales_streak_days,
    current_available_balance,
    current_nsf_count,
    active_alert_count,
    primary_monitoring_reason_code,
    alert_payload,
    source_daily_row_hash,
    source_m2_4_contract_row_hash,
    source_advance_row_hash,
    source_portfolio_row_hash,
    policy_configuration_hash,
    contract_row_hash
)
SELECT
    daily.module1_run_id,
    'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION',
    1,
    'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1',
    'M2_5_METHOD_V1',
    daily.scenario_id,
    daily.scenario_code,
    daily.merchant_application_id,
    daily.merchant_id,
    daily.synthetic_account_id,
    daily.synthetic_advance_id,
    120,
    daily.monitoring_day_index,
    daily.monitoring_date,
    daily.monitoring_status_code,
    daily.monitoring_status_rank,
    daily.raw_monitoring_status_code,
    daily.raw_monitoring_status_rank,
    daily.stress_status_floor_applied_flag,
    daily.paid_off_flag,
    payoff.payoff_day_index,
    daily.cumulative_remittance_amount,
    daily.receivable_balance_after,
    daily.principal_exposure_proxy,
    daily.unearned_finance_charge_proxy,
    daily.cumulative_expected_remittance_amount,
    daily.cumulative_shortfall_amount,
    daily.cumulative_pace_ratio,
    daily.trailing_7_day_remittance_amount,
    daily.trailing_30_day_remittance_amount,
    daily.days_since_last_positive_remittance,
    daily.zero_sales_streak_days,
    daily.source_available_balance,
    daily.source_nsf_count,
    (
        daily.daily_shortfall_alert_flag::integer +
        daily.cumulative_pace_watch_alert_flag::integer +
        daily.cumulative_pace_high_alert_flag::integer +
        daily.zero_sales_streak_alert_flag::integer +
        daily.liquidity_stress_alert_flag::integer +
        daily.horizon_overrun_alert_flag::integer +
        daily.stress_status_floor_applied_flag::integer
    )::integer,
    daily.primary_monitoring_reason_code,
    daily.alert_payload,
    daily.row_hash,
    daily.source_m2_4_contract_row_hash,
    daily.source_advance_row_hash,
    daily.source_portfolio_row_hash,
    daily.policy_configuration_hash,
    NULL::text
FROM _m2_5_daily_expected AS daily
JOIN _m2_5_payoff_summary AS payoff
  ON payoff.module1_run_id = daily.module1_run_id
 AND payoff.scenario_id = daily.scenario_id
 AND payoff.merchant_application_id = daily.merchant_application_id
WHERE daily.monitoring_day_index = 120;

UPDATE _m2_5_latest_expected AS latest
SET contract_row_hash = msbf_ctl.m2_5_hash_jsonb
(
    to_jsonb(latest) - 'contract_row_hash'
)
WHERE latest.contract_row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_5_latest_expected
(
    module1_run_id,
    scenario_id,
    merchant_application_id
);

ANALYZE _m2_5_latest_expected;

INSERT INTO msbf_m2.advance_portfolio_monitoring_latest
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    merchant_id,
    synthetic_account_id,
    synthetic_advance_id,
    monitoring_horizon_days,
    latest_monitoring_day_index,
    latest_monitoring_date,
    latest_monitoring_status_code,
    latest_monitoring_status_rank,
    latest_raw_monitoring_status_code,
    latest_raw_monitoring_status_rank,
    stress_status_floor_applied_flag,
    paid_off_flag,
    payoff_day_index,
    cumulative_remittance_amount,
    remaining_receivable_amount,
    principal_exposure_proxy,
    unearned_finance_charge_proxy,
    cumulative_expected_remittance_amount,
    cumulative_shortfall_amount,
    cumulative_pace_ratio,
    trailing_7_day_remittance_amount,
    trailing_30_day_remittance_amount,
    days_since_last_positive_remittance,
    zero_sales_streak_days,
    current_available_balance,
    current_nsf_count,
    active_alert_count,
    primary_monitoring_reason_code,
    alert_payload,
    source_daily_row_hash,
    source_m2_4_contract_row_hash,
    source_advance_row_hash,
    source_portfolio_row_hash,
    policy_configuration_hash,
    contract_row_hash
)
SELECT
    latest.module1_run_id,
    latest.contract_code,
    latest.contract_version,
    latest.schema_version,
    latest.methodology_version,
    latest.scenario_id,
    latest.scenario_code,
    latest.merchant_application_id,
    latest.merchant_id,
    latest.synthetic_account_id,
    latest.synthetic_advance_id,
    latest.monitoring_horizon_days,
    latest.latest_monitoring_day_index,
    latest.latest_monitoring_date,
    latest.latest_monitoring_status_code,
    latest.latest_monitoring_status_rank,
    latest.latest_raw_monitoring_status_code,
    latest.latest_raw_monitoring_status_rank,
    latest.stress_status_floor_applied_flag,
    latest.paid_off_flag,
    latest.payoff_day_index,
    latest.cumulative_remittance_amount,
    latest.remaining_receivable_amount,
    latest.principal_exposure_proxy,
    latest.unearned_finance_charge_proxy,
    latest.cumulative_expected_remittance_amount,
    latest.cumulative_shortfall_amount,
    latest.cumulative_pace_ratio,
    latest.trailing_7_day_remittance_amount,
    latest.trailing_30_day_remittance_amount,
    latest.days_since_last_positive_remittance,
    latest.zero_sales_streak_days,
    latest.current_available_balance,
    latest.current_nsf_count,
    latest.active_alert_count,
    latest.primary_monitoring_reason_code,
    latest.alert_payload,
    latest.source_daily_row_hash,
    latest.source_m2_4_contract_row_hash,
    latest.source_advance_row_hash,
    latest.source_portfolio_row_hash,
    latest.policy_configuration_hash,
    latest.contract_row_hash
FROM _m2_5_latest_expected AS latest;

DROP TABLE IF EXISTS _m2_5_archive_expected;

CREATE TEMP TABLE _m2_5_archive_expected
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
    latest.merchant_id,
    latest.synthetic_account_id,
    latest.synthetic_advance_id,
    latest.monitoring_horizon_days,
    latest.latest_monitoring_day_index,
    latest.latest_monitoring_date,
    latest.latest_monitoring_status_code,
    latest.latest_monitoring_status_rank,
    latest.latest_raw_monitoring_status_code,
    latest.latest_raw_monitoring_status_rank,
    latest.stress_status_floor_applied_flag,
    latest.paid_off_flag,
    latest.payoff_day_index,
    latest.cumulative_remittance_amount,
    latest.remaining_receivable_amount,
    latest.principal_exposure_proxy,
    latest.unearned_finance_charge_proxy,
    latest.cumulative_expected_remittance_amount,
    latest.cumulative_shortfall_amount,
    latest.cumulative_pace_ratio,
    latest.trailing_7_day_remittance_amount,
    latest.trailing_30_day_remittance_amount,
    latest.days_since_last_positive_remittance,
    latest.zero_sales_streak_days,
    latest.current_available_balance,
    latest.current_nsf_count,
    latest.active_alert_count,
    latest.primary_monitoring_reason_code,
    latest.alert_payload,
    latest.source_daily_row_hash,
    latest.source_m2_4_contract_row_hash,
    latest.source_advance_row_hash,
    latest.source_portfolio_row_hash,
    latest.policy_configuration_hash,
    latest.contract_row_hash,
    to_jsonb(latest) AS contract_payload,
    NULL::text AS archive_row_hash
FROM _m2_5_latest_expected AS latest;

UPDATE _m2_5_archive_expected AS archive
SET archive_row_hash = msbf_ctl.m2_5_hash_jsonb
(
    to_jsonb(archive) - 'archive_row_hash'
)
WHERE archive.archive_row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_5_archive_expected
(
    module1_run_id,
    contract_version,
    scenario_id,
    merchant_application_id
);

ANALYZE _m2_5_archive_expected;

INSERT INTO msbf_m2.advance_portfolio_monitoring_archive
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    merchant_id,
    synthetic_account_id,
    synthetic_advance_id,
    monitoring_horizon_days,
    latest_monitoring_day_index,
    latest_monitoring_date,
    latest_monitoring_status_code,
    latest_monitoring_status_rank,
    latest_raw_monitoring_status_code,
    latest_raw_monitoring_status_rank,
    stress_status_floor_applied_flag,
    paid_off_flag,
    payoff_day_index,
    cumulative_remittance_amount,
    remaining_receivable_amount,
    principal_exposure_proxy,
    unearned_finance_charge_proxy,
    cumulative_expected_remittance_amount,
    cumulative_shortfall_amount,
    cumulative_pace_ratio,
    trailing_7_day_remittance_amount,
    trailing_30_day_remittance_amount,
    days_since_last_positive_remittance,
    zero_sales_streak_days,
    current_available_balance,
    current_nsf_count,
    active_alert_count,
    primary_monitoring_reason_code,
    alert_payload,
    source_daily_row_hash,
    source_m2_4_contract_row_hash,
    source_advance_row_hash,
    source_portfolio_row_hash,
    policy_configuration_hash,
    contract_row_hash,
    contract_payload,
    archive_row_hash
)
SELECT
    archive.module1_run_id,
    archive.contract_code,
    archive.contract_version,
    archive.schema_version,
    archive.methodology_version,
    archive.scenario_id,
    archive.scenario_code,
    archive.merchant_application_id,
    archive.merchant_id,
    archive.synthetic_account_id,
    archive.synthetic_advance_id,
    archive.monitoring_horizon_days,
    archive.latest_monitoring_day_index,
    archive.latest_monitoring_date,
    archive.latest_monitoring_status_code,
    archive.latest_monitoring_status_rank,
    archive.latest_raw_monitoring_status_code,
    archive.latest_raw_monitoring_status_rank,
    archive.stress_status_floor_applied_flag,
    archive.paid_off_flag,
    archive.payoff_day_index,
    archive.cumulative_remittance_amount,
    archive.remaining_receivable_amount,
    archive.principal_exposure_proxy,
    archive.unearned_finance_charge_proxy,
    archive.cumulative_expected_remittance_amount,
    archive.cumulative_shortfall_amount,
    archive.cumulative_pace_ratio,
    archive.trailing_7_day_remittance_amount,
    archive.trailing_30_day_remittance_amount,
    archive.days_since_last_positive_remittance,
    archive.zero_sales_streak_days,
    archive.current_available_balance,
    archive.current_nsf_count,
    archive.active_alert_count,
    archive.primary_monitoring_reason_code,
    archive.alert_payload,
    archive.source_daily_row_hash,
    archive.source_m2_4_contract_row_hash,
    archive.source_advance_row_hash,
    archive.source_portfolio_row_hash,
    archive.policy_configuration_hash,
    archive.contract_row_hash,
    archive.contract_payload,
    archive.archive_row_hash
FROM _m2_5_archive_expected AS archive;

/* ============================================================================
Section 9 — Portfolio daily summary
============================================================================ */

DROP TABLE IF EXISTS _m2_5_portfolio_expected;

CREATE TEMP TABLE _m2_5_portfolio_expected
(
    module1_run_id                         bigint NOT NULL,
    scenario_id                            bigint NOT NULL,
    scenario_code                          text NOT NULL,
    monitoring_day_index                   integer NOT NULL,
    monitoring_date                        date NOT NULL,
    opening_advance_count                  integer NOT NULL,
    active_advance_count                   integer NOT NULL,
    paid_off_count                         integer NOT NULL,
    current_count                          integer NOT NULL,
    watch_count                            integer NOT NULL,
    underperforming_count                  integer NOT NULL,
    severe_shortfall_count                 integer NOT NULL,
    dormant_no_remittance_count            integer NOT NULL,
    daily_eligible_pos_sales               numeric(24,2) NOT NULL,
    daily_remittance_amount                numeric(24,2) NOT NULL,
    cumulative_remittance_amount           numeric(24,2) NOT NULL,
    cumulative_expected_remittance_amount  numeric(24,2) NOT NULL,
    cumulative_shortfall_amount            numeric(24,2) NOT NULL,
    total_receivable_exposure_amount       numeric(24,2) NOT NULL,
    total_principal_exposure_proxy         numeric(24,2) NOT NULL,
    portfolio_pace_ratio                   numeric(12,8),
    stress_status_floor_rows               integer NOT NULL,
    row_hash                               text
)
ON COMMIT DROP;

INSERT INTO _m2_5_portfolio_expected
(
    module1_run_id,
    scenario_id,
    scenario_code,
    monitoring_day_index,
    monitoring_date,
    opening_advance_count,
    active_advance_count,
    paid_off_count,
    current_count,
    watch_count,
    underperforming_count,
    severe_shortfall_count,
    dormant_no_remittance_count,
    daily_eligible_pos_sales,
    daily_remittance_amount,
    cumulative_remittance_amount,
    cumulative_expected_remittance_amount,
    cumulative_shortfall_amount,
    total_receivable_exposure_amount,
    total_principal_exposure_proxy,
    portfolio_pace_ratio,
    stress_status_floor_rows,
    row_hash
)
SELECT
    daily.module1_run_id,
    daily.scenario_id,
    daily.scenario_code,
    daily.monitoring_day_index,
    min(daily.monitoring_date),
    count(*)::integer,
    count(*) FILTER
    (
        WHERE daily.receivable_balance_before > 0
    )::integer,
    count(*) FILTER
    (
        WHERE daily.paid_off_flag
    )::integer,
    count(*) FILTER
    (
        WHERE daily.monitoring_status_code = 'CURRENT'
    )::integer,
    count(*) FILTER
    (
        WHERE daily.monitoring_status_code = 'WATCH'
    )::integer,
    count(*) FILTER
    (
        WHERE daily.monitoring_status_code = 'UNDERPERFORMING'
    )::integer,
    count(*) FILTER
    (
        WHERE daily.monitoring_status_code = 'SEVERE_SHORTFALL'
    )::integer,
    count(*) FILTER
    (
        WHERE daily.monitoring_status_code = 'DORMANT_NO_REMITTANCE'
    )::integer,
    round(sum(daily.source_eligible_pos_sales), 2)::numeric(24,2),
    round(sum(daily.actual_remittance_amount), 2)::numeric(24,2),
    round(sum(daily.cumulative_remittance_amount), 2)::numeric(24,2),
    round(sum(daily.cumulative_expected_remittance_amount), 2)::numeric(24,2),
    round(sum(daily.cumulative_shortfall_amount), 2)::numeric(24,2),
    round(sum(daily.receivable_balance_after), 2)::numeric(24,2),
    round(sum(daily.principal_exposure_proxy), 2)::numeric(24,2),
    CASE
        WHEN sum(daily.cumulative_expected_remittance_amount) > 0
        THEN round
        (
            sum(daily.cumulative_remittance_amount) /
            sum(daily.cumulative_expected_remittance_amount),
            8
        )::numeric(12,8)
        ELSE 1.00000000::numeric(12,8)
    END,
    count(*) FILTER
    (
        WHERE daily.stress_status_floor_applied_flag
    )::integer,
    NULL::text
FROM _m2_5_daily_expected AS daily
GROUP BY
    daily.module1_run_id,
    daily.scenario_id,
    daily.scenario_code,
    daily.monitoring_day_index;

UPDATE _m2_5_portfolio_expected AS summary
SET row_hash = msbf_ctl.m2_5_hash_jsonb
(
    to_jsonb(summary) - 'row_hash'
)
WHERE summary.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_5_portfolio_expected
(
    module1_run_id,
    scenario_id,
    monitoring_day_index
);

ANALYZE _m2_5_portfolio_expected;

DO $m2_5_portfolio_guard$
DECLARE
    v record;
BEGIN
    SELECT
        count(*) AS portfolio_rows,
        count(*) FILTER(WHERE scenario_code = 'BASELINE') AS baseline_rows,
        count(*) FILTER(WHERE scenario_code = 'RECESSION_ENERGY') AS stress_rows,
        count(*) FILTER
        (
            WHERE row_hash IS NULL
               OR opening_advance_count <= 0
               OR active_advance_count < 0
               OR paid_off_count < 0
               OR daily_remittance_amount < 0
               OR total_receivable_exposure_amount < 0
        ) AS invalid_rows
    INTO v
    FROM _m2_5_portfolio_expected;

    IF v.portfolio_rows <> 240
       OR v.baseline_rows <> 120
       OR v.stress_rows <> 120
       OR v.invalid_rows <> 0 THEN
        RAISE EXCEPTION
            'M2.5 portfolio summary failed: %',
            row_to_json(v);
    END IF;
END;
$m2_5_portfolio_guard$;

INSERT INTO msbf_m2.portfolio_daily_monitoring_summary
(
    module1_run_id,
    scenario_id,
    scenario_code,
    monitoring_day_index,
    monitoring_date,
    opening_advance_count,
    active_advance_count,
    paid_off_count,
    current_count,
    watch_count,
    underperforming_count,
    severe_shortfall_count,
    dormant_no_remittance_count,
    daily_eligible_pos_sales,
    daily_remittance_amount,
    cumulative_remittance_amount,
    cumulative_expected_remittance_amount,
    cumulative_shortfall_amount,
    total_receivable_exposure_amount,
    total_principal_exposure_proxy,
    portfolio_pace_ratio,
    stress_status_floor_rows,
    row_hash
)
SELECT
    summary.module1_run_id,
    summary.scenario_id,
    summary.scenario_code,
    summary.monitoring_day_index,
    summary.monitoring_date,
    summary.opening_advance_count,
    summary.active_advance_count,
    summary.paid_off_count,
    summary.current_count,
    summary.watch_count,
    summary.underperforming_count,
    summary.severe_shortfall_count,
    summary.dormant_no_remittance_count,
    summary.daily_eligible_pos_sales,
    summary.daily_remittance_amount,
    summary.cumulative_remittance_amount,
    summary.cumulative_expected_remittance_amount,
    summary.cumulative_shortfall_amount,
    summary.total_receivable_exposure_amount,
    summary.total_principal_exposure_proxy,
    summary.portfolio_pace_ratio,
    summary.stress_status_floor_rows,
    summary.row_hash
FROM _m2_5_portfolio_expected AS summary;

ANALYZE msbf_m2.advance_monitoring_source_snapshot;
ANALYZE msbf_m2.advance_daily_remittance_monitoring;
ANALYZE msbf_m2.advance_portfolio_monitoring_latest;
ANALYZE msbf_m2.advance_portfolio_monitoring_archive;
ANALYZE msbf_m2.portfolio_daily_monitoring_summary;

/* ============================================================================
Section 10 — Set hashes, target-typed registry and combined canonical identity
============================================================================ */

DROP TABLE IF EXISTS _m2_5_set_hashes;

CREATE TEMP TABLE _m2_5_set_hashes
ON COMMIT DROP
AS
SELECT
    (
        SELECT md5(string_agg(policy.row_hash, '|' ORDER BY policy.module1_run_id))
        FROM msbf_ctl.m2_5_policy_profile AS policy
        WHERE policy.module1_run_id = (SELECT run_id FROM _m2_5_ctx)
    ) AS policy_set_hash,
    (
        SELECT md5(string_agg(status.row_hash, '|' ORDER BY status.monitoring_status_rank))
        FROM msbf_m2.portfolio_monitoring_status_definition AS status
        WHERE status.module1_run_id = (SELECT run_id FROM _m2_5_ctx)
    ) AS status_set_hash,
    (
        SELECT md5(string_agg(alert.row_hash, '|' ORDER BY alert.alert_rank))
        FROM msbf_m2.portfolio_monitoring_alert_definition AS alert
        WHERE alert.module1_run_id = (SELECT run_id FROM _m2_5_ctx)
    ) AS alert_set_hash,
    (
        SELECT md5(string_agg(reason.row_hash, '|' ORDER BY reason.monitoring_reason_code))
        FROM msbf_m2.portfolio_monitoring_reason_definition AS reason
        WHERE reason.module1_run_id = (SELECT run_id FROM _m2_5_ctx)
    ) AS reason_set_hash,
    (
        SELECT md5
        (
            string_agg
            (
                source.scenario_id::text || '|' || source.merchant_application_id || '|' || source.row_hash,
                '|' ORDER BY source.scenario_id, source.merchant_application_id
            )
        )
        FROM _m2_5_source_expected AS source
    ) AS source_set_hash,
    (
        SELECT md5
        (
            string_agg
            (
                daily.scenario_id::text || '|' || daily.merchant_application_id || '|' || daily.monitoring_day_index::text || '|' || daily.row_hash,
                '|' ORDER BY daily.scenario_id, daily.merchant_application_id, daily.monitoring_day_index
            )
        )
        FROM _m2_5_daily_expected AS daily
    ) AS daily_set_hash,
    (
        SELECT md5
        (
            string_agg
            (
                latest.scenario_id::text || '|' || latest.merchant_application_id || '|' || latest.contract_row_hash,
                '|' ORDER BY latest.scenario_id, latest.merchant_application_id
            )
        )
        FROM _m2_5_latest_expected AS latest
    ) AS latest_set_hash,
    (
        SELECT md5
        (
            string_agg
            (
                archive.scenario_id::text || '|' || archive.merchant_application_id || '|' || archive.archive_row_hash,
                '|' ORDER BY archive.scenario_id, archive.merchant_application_id
            )
        )
        FROM _m2_5_archive_expected AS archive
    ) AS archive_set_hash,
    (
        SELECT md5
        (
            string_agg
            (
                summary.scenario_id::text || '|' || summary.monitoring_day_index::text || '|' || summary.row_hash,
                '|' ORDER BY summary.scenario_id, summary.monitoring_day_index
            )
        )
        FROM _m2_5_portfolio_expected AS summary
    ) AS portfolio_daily_set_hash;

DROP TABLE IF EXISTS _m2_5_registry_expected;

CREATE TEMP TABLE _m2_5_registry_expected
(
    module1_run_id                          bigint NOT NULL,
    contract_code                           text NOT NULL,
    contract_version                        integer NOT NULL,
    schema_version                          text NOT NULL,
    methodology_version                     text NOT NULL,
    source_m2_4_contract_code               text NOT NULL,
    source_m2_4_contract_version            integer NOT NULL,
    source_m2_4_schema_version              text NOT NULL,
    source_m2_4_combined_hash               text NOT NULL,
    source_m2_4_acceptance_gate_id          text NOT NULL,
    source_m1_6_acceptance_gate_id          text NOT NULL,
    source_m1_6_combined_hash               text NOT NULL,
    policy_configuration_hash               text NOT NULL,
    policy_rows                             bigint NOT NULL,
    status_rows                             bigint NOT NULL,
    alert_rows                              bigint NOT NULL,
    reason_rows                             bigint NOT NULL,
    source_rows                             bigint NOT NULL,
    daily_rows                              bigint NOT NULL,
    latest_rows                             bigint NOT NULL,
    archive_rows                            bigint NOT NULL,
    portfolio_daily_rows                   bigint NOT NULL,
    comparison_rows                         bigint NOT NULL,
    registry_rows                           bigint NOT NULL,
    canonical_entities                      bigint NOT NULL,
    paid_off_rows                           bigint NOT NULL,
    open_monitoring_rows                    bigint NOT NULL,
    stress_status_floor_rows                 bigint NOT NULL,
    total_remittance_amount                 numeric(24,2) NOT NULL,
    ending_receivable_exposure_amount       numeric(24,2) NOT NULL,
    policy_set_hash                         text NOT NULL,
    status_set_hash                         text NOT NULL,
    alert_set_hash                          text NOT NULL,
    reason_set_hash                         text NOT NULL,
    source_set_hash                         text NOT NULL,
    daily_set_hash                          text NOT NULL,
    latest_set_hash                         text NOT NULL,
    archive_set_hash                        text NOT NULL,
    portfolio_daily_set_hash                text NOT NULL,
    contract_set_hash                       text,
    combined_set_hash                       text,
    contract_status                         text NOT NULL,
    generated_at                            timestamptz,
    validated_at                            timestamptz,
    accepted_at                             timestamptz,
    row_hash                                text
)
ON COMMIT DROP;

INSERT INTO _m2_5_registry_expected
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    source_m2_4_contract_code,
    source_m2_4_contract_version,
    source_m2_4_schema_version,
    source_m2_4_combined_hash,
    source_m2_4_acceptance_gate_id,
    source_m1_6_acceptance_gate_id,
    source_m1_6_combined_hash,
    policy_configuration_hash,
    policy_rows,
    status_rows,
    alert_rows,
    reason_rows,
    source_rows,
    daily_rows,
    latest_rows,
    archive_rows,
    portfolio_daily_rows,
    comparison_rows,
    registry_rows,
    canonical_entities,
    paid_off_rows,
    open_monitoring_rows,
    stress_status_floor_rows,
    total_remittance_amount,
    ending_receivable_exposure_amount,
    policy_set_hash,
    status_set_hash,
    alert_set_hash,
    reason_set_hash,
    source_set_hash,
    daily_set_hash,
    latest_set_hash,
    archive_set_hash,
    portfolio_daily_set_hash,
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
    'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION',
    1,
    'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1',
    'M2_5_METHOD_V1',
    'M2_PORTFOLIO_ACTIVATION_CONSUMPTION',
    1,
    'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1',
    '117450a3eea7bb3d3c74d18cc3c8e96a',
    'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION',
    'M1_6_MATCHED_SCENARIO_OVERLAYS',
    ctx.source_m1_6_combined_hash,
    ctx.configuration_hash,
    1,
    6,
    7,
    24,
    59,
    7080,
    59,
    59,
    240,
    15,
    1,
    7536,
    (
        SELECT count(*)
        FROM _m2_5_latest_expected
        WHERE paid_off_flag
    ),
    (
        SELECT count(*)
        FROM _m2_5_latest_expected
        WHERE NOT paid_off_flag
    ),
    (
        SELECT count(*)
        FROM _m2_5_daily_expected
        WHERE stress_status_floor_applied_flag
    ),
    (
        SELECT round(sum(cumulative_remittance_amount), 2)
        FROM _m2_5_latest_expected
    ),
    (
        SELECT round(sum(remaining_receivable_amount), 2)
        FROM _m2_5_latest_expected
    ),
    hashes.policy_set_hash,
    hashes.status_set_hash,
    hashes.alert_set_hash,
    hashes.reason_set_hash,
    hashes.source_set_hash,
    hashes.daily_set_hash,
    hashes.latest_set_hash,
    hashes.archive_set_hash,
    hashes.portfolio_daily_set_hash,
    NULL::text,
    NULL::text,
    'GENERATED',
    clock_timestamp(),
    NULL::timestamptz,
    NULL::timestamptz,
    NULL::text
FROM _m2_5_ctx AS ctx
CROSS JOIN _m2_5_set_hashes AS hashes;

UPDATE _m2_5_registry_expected AS registry
SET row_hash = msbf_ctl.m2_5_registry_row_hash
(
    to_jsonb(registry)
)
WHERE registry.row_hash IS NULL;

UPDATE _m2_5_registry_expected AS registry
SET contract_set_hash = md5(registry.row_hash)
WHERE registry.contract_set_hash IS NULL;

DROP TABLE IF EXISTS _m2_5_canonical_expected;

CREATE TEMP TABLE _m2_5_canonical_expected
(
    entity_type text NOT NULL,
    entity_key text NOT NULL,
    row_hash text NOT NULL,
    PRIMARY KEY(entity_type, entity_key)
)
ON COMMIT DROP;

INSERT INTO _m2_5_canonical_expected
(
    entity_type,
    entity_key,
    row_hash
)
SELECT
    'POLICY',
    policy.policy_code || '|v' || policy.policy_version::text,
    policy.row_hash
FROM msbf_ctl.m2_5_policy_profile AS policy
WHERE policy.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT 'STATUS', status.monitoring_status_code, status.row_hash
FROM msbf_m2.portfolio_monitoring_status_definition AS status
WHERE status.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT 'ALERT', alert.monitoring_alert_code, alert.row_hash
FROM msbf_m2.portfolio_monitoring_alert_definition AS alert
WHERE alert.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT 'REASON', reason.monitoring_reason_code, reason.row_hash
FROM msbf_m2.portfolio_monitoring_reason_definition AS reason
WHERE reason.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT
    'SOURCE',
    source.scenario_id::text || '|' || source.merchant_application_id,
    source.row_hash
FROM _m2_5_source_expected AS source

UNION ALL

SELECT
    'DAILY',
    daily.scenario_id::text || '|' || daily.merchant_application_id || '|' || daily.monitoring_day_index::text,
    daily.row_hash
FROM _m2_5_daily_expected AS daily

UNION ALL

SELECT
    'LATEST',
    latest.scenario_id::text || '|' || latest.merchant_application_id,
    latest.contract_row_hash
FROM _m2_5_latest_expected AS latest

UNION ALL

SELECT
    'ARCHIVE',
    archive.scenario_id::text || '|' || archive.merchant_application_id,
    archive.archive_row_hash
FROM _m2_5_archive_expected AS archive

UNION ALL

SELECT
    'PORTFOLIO_DAILY',
    summary.scenario_id::text || '|' || summary.monitoring_day_index::text,
    summary.row_hash
FROM _m2_5_portfolio_expected AS summary

UNION ALL

SELECT
    'REGISTRY',
    registry.contract_code || '|v' || registry.contract_version::text,
    registry.row_hash
FROM _m2_5_registry_expected AS registry;

UPDATE _m2_5_registry_expected AS registry
SET combined_set_hash =
(
    SELECT md5
    (
        string_agg
        (
            canonical.entity_type || '|' || canonical.entity_key || '|' || canonical.row_hash,
            '|' ORDER BY canonical.entity_type, canonical.entity_key
        )
    )
    FROM _m2_5_canonical_expected AS canonical
)
WHERE registry.combined_set_hash IS NULL;

INSERT INTO msbf_ctl.m2_5_portfolio_monitoring_contract_registry
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    source_m2_4_contract_code,
    source_m2_4_contract_version,
    source_m2_4_schema_version,
    source_m2_4_combined_hash,
    source_m2_4_acceptance_gate_id,
    source_m1_6_acceptance_gate_id,
    source_m1_6_combined_hash,
    policy_configuration_hash,
    policy_rows,
    status_rows,
    alert_rows,
    reason_rows,
    source_rows,
    daily_rows,
    latest_rows,
    archive_rows,
    portfolio_daily_rows,
    comparison_rows,
    registry_rows,
    canonical_entities,
    paid_off_rows,
    open_monitoring_rows,
    stress_status_floor_rows,
    total_remittance_amount,
    ending_receivable_exposure_amount,
    policy_set_hash,
    status_set_hash,
    alert_set_hash,
    reason_set_hash,
    source_set_hash,
    daily_set_hash,
    latest_set_hash,
    archive_set_hash,
    portfolio_daily_set_hash,
    contract_set_hash,
    combined_set_hash,
    contract_status,
    generated_at,
    validated_at,
    accepted_at,
    row_hash
)
SELECT
    registry.module1_run_id,
    registry.contract_code,
    registry.contract_version,
    registry.schema_version,
    registry.methodology_version,
    registry.source_m2_4_contract_code,
    registry.source_m2_4_contract_version,
    registry.source_m2_4_schema_version,
    registry.source_m2_4_combined_hash,
    registry.source_m2_4_acceptance_gate_id,
    registry.source_m1_6_acceptance_gate_id,
    registry.source_m1_6_combined_hash,
    registry.policy_configuration_hash,
    registry.policy_rows,
    registry.status_rows,
    registry.alert_rows,
    registry.reason_rows,
    registry.source_rows,
    registry.daily_rows,
    registry.latest_rows,
    registry.archive_rows,
    registry.portfolio_daily_rows,
    registry.comparison_rows,
    registry.registry_rows,
    registry.canonical_entities,
    registry.paid_off_rows,
    registry.open_monitoring_rows,
    registry.stress_status_floor_rows,
    registry.total_remittance_amount,
    registry.ending_receivable_exposure_amount,
    registry.policy_set_hash,
    registry.status_set_hash,
    registry.alert_set_hash,
    registry.reason_set_hash,
    registry.source_set_hash,
    registry.daily_set_hash,
    registry.latest_set_hash,
    registry.archive_set_hash,
    registry.portfolio_daily_set_hash,
    registry.contract_set_hash,
    registry.combined_set_hash,
    registry.contract_status,
    registry.generated_at,
    registry.validated_at,
    registry.accepted_at,
    registry.row_hash
FROM _m2_5_registry_expected AS registry;

/* ============================================================================
Section 11 — Physical canonical reconstruction and mismatch diagnostics
============================================================================ */

DROP TABLE IF EXISTS _m2_5_canonical_actual;

CREATE TEMP TABLE _m2_5_canonical_actual
(
    entity_type text NOT NULL,
    entity_key text NOT NULL,
    row_hash text NOT NULL,
    PRIMARY KEY(entity_type, entity_key)
)
ON COMMIT DROP;

INSERT INTO _m2_5_canonical_actual
(
    entity_type,
    entity_key,
    row_hash
)
SELECT
    'POLICY',
    policy.policy_code || '|v' || policy.policy_version::text,
    msbf_ctl.m2_5_hash_jsonb
    (
        to_jsonb(policy) - 'row_hash' - 'created_at' - 'updated_at'
    )
FROM msbf_ctl.m2_5_policy_profile AS policy
WHERE policy.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT
    'STATUS',
    status.monitoring_status_code,
    msbf_ctl.m2_5_hash_jsonb(to_jsonb(status) - 'row_hash' - 'created_at')
FROM msbf_m2.portfolio_monitoring_status_definition AS status
WHERE status.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT
    'ALERT',
    alert.monitoring_alert_code,
    msbf_ctl.m2_5_hash_jsonb(to_jsonb(alert) - 'row_hash' - 'created_at')
FROM msbf_m2.portfolio_monitoring_alert_definition AS alert
WHERE alert.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT
    'REASON',
    reason.monitoring_reason_code,
    msbf_ctl.m2_5_hash_jsonb(to_jsonb(reason) - 'row_hash' - 'created_at')
FROM msbf_m2.portfolio_monitoring_reason_definition AS reason
WHERE reason.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT
    'SOURCE',
    source.scenario_id::text || '|' || source.merchant_application_id,
    msbf_ctl.m2_5_hash_jsonb(to_jsonb(source) - 'row_hash' - 'created_at')
FROM msbf_m2.advance_monitoring_source_snapshot AS source
WHERE source.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT
    'DAILY',
    daily.scenario_id::text || '|' || daily.merchant_application_id || '|' || daily.monitoring_day_index::text,
    msbf_ctl.m2_5_hash_jsonb(to_jsonb(daily) - 'row_hash' - 'created_at')
FROM msbf_m2.advance_daily_remittance_monitoring AS daily
WHERE daily.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT
    'LATEST',
    latest.scenario_id::text || '|' || latest.merchant_application_id,
    msbf_ctl.m2_5_hash_jsonb(to_jsonb(latest) - 'contract_row_hash' - 'created_at')
FROM msbf_m2.advance_portfolio_monitoring_latest AS latest
WHERE latest.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT
    'ARCHIVE',
    archive.scenario_id::text || '|' || archive.merchant_application_id,
    msbf_ctl.m2_5_hash_jsonb
    (
        to_jsonb(archive) - 'archive_id' - 'archive_row_hash' - 'archived_at' - 'created_at'
    )
FROM msbf_m2.advance_portfolio_monitoring_archive AS archive
WHERE archive.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT
    'PORTFOLIO_DAILY',
    summary.scenario_id::text || '|' || summary.monitoring_day_index::text,
    msbf_ctl.m2_5_hash_jsonb(to_jsonb(summary) - 'row_hash' - 'created_at')
FROM msbf_m2.portfolio_daily_monitoring_summary AS summary
WHERE summary.module1_run_id = (SELECT run_id FROM _m2_5_ctx)

UNION ALL

SELECT
    'REGISTRY',
    registry.contract_code || '|v' || registry.contract_version::text,
    msbf_ctl.m2_5_registry_row_hash(to_jsonb(registry))
FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS registry
WHERE registry.module1_run_id = (SELECT run_id FROM _m2_5_ctx);

DROP TABLE IF EXISTS _m2_5_mismatch;

CREATE TEMP TABLE _m2_5_mismatch
ON COMMIT DROP
AS
SELECT
    coalesce(expected.entity_type, actual.entity_type) AS entity_type,
    coalesce(expected.entity_key, actual.entity_key) AS entity_key,
    expected.row_hash AS expected_row_hash,
    actual.row_hash AS actual_row_hash
FROM _m2_5_canonical_expected AS expected
FULL OUTER JOIN _m2_5_canonical_actual AS actual
  ON actual.entity_type = expected.entity_type
 AND actual.entity_key = expected.entity_key
WHERE expected.row_hash IS DISTINCT FROM actual.row_hash;

DROP TABLE IF EXISTS _m2_5_generation_diagnostics;

CREATE TEMP TABLE _m2_5_generation_diagnostics
ON COMMIT PRESERVE ROWS
AS
SELECT
    (SELECT count(*) FROM _m2_5_canonical_expected)::bigint AS expected_canonical_entities,
    (SELECT count(*) FROM _m2_5_canonical_actual)::bigint AS actual_canonical_entities,
    (SELECT count(*) FROM _m2_5_mismatch)::bigint AS row_level_mismatches,
    (
        SELECT count(*)
        FROM msbf_m2.v_m2_5_matched_monitoring_comparison
        WHERE module1_run_id = (SELECT run_id FROM _m2_5_ctx)
    )::bigint AS comparison_rows,
    (
        SELECT count(*)
        FROM msbf_m2.v_m2_5_matched_monitoring_comparison
        WHERE module1_run_id = (SELECT run_id FROM _m2_5_ctx)
          AND stress_status_improvement_flag
    )::bigint AS stress_status_improvements;

DO $m2_5_canonical_guard$
DECLARE
    v record;
BEGIN
    SELECT
        expected_canonical_entities,
        actual_canonical_entities,
        row_level_mismatches,
        comparison_rows,
        stress_status_improvements
    INTO v
    FROM _m2_5_generation_diagnostics;

    IF v.expected_canonical_entities <> 7536
       OR v.actual_canonical_entities <> 7536
       OR v.row_level_mismatches <> 0
       OR v.comparison_rows <> 15
       OR v.stress_status_improvements <> 0 THEN
        RAISE EXCEPTION
            'M2.5 canonical reconciliation failed: %',
            row_to_json(v);
    END IF;
END;
$m2_5_canonical_guard$;

/* ============================================================================
Section 12 — Governed generation evidence
============================================================================ */

DROP TABLE IF EXISTS _m2_5_generation_evidence;

CREATE TEMP TABLE _m2_5_generation_evidence
(
    run_id                  bigint NOT NULL,
    evidence_code           text NOT NULL,
    segment_key             text NOT NULL,
    metric_name             text NOT NULL,
    metric_value_numeric    numeric(24,10),
    metric_value_text       text,
    unit_code               text NOT NULL,
    status                  text NOT NULL,
    interpretation          text NOT NULL,
    CHECK(num_nonnulls(metric_value_numeric, metric_value_text) = 1)
)
ON COMMIT DROP;

INSERT INTO _m2_5_generation_evidence
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
    registry.module1_run_id,
    evidence.evidence_code,
    'PORTFOLIO',
    evidence.metric_name,
    evidence.metric_value_numeric,
    evidence.metric_value_text,
    evidence.unit_code,
    'PASS',
    evidence.interpretation
FROM _m2_5_registry_expected AS registry
CROSS JOIN LATERAL
(
    VALUES
    ('M2_5_POLICY_SET_HASH','POLICY_SET_HASH',NULL::numeric(24,10),registry.policy_set_hash,'HASH','M2.5 policy set hash.'),
    ('M2_5_STATUS_SET_HASH','STATUS_SET_HASH',NULL::numeric(24,10),registry.status_set_hash,'HASH','Monitoring-status definition set hash.'),
    ('M2_5_ALERT_SET_HASH','ALERT_SET_HASH',NULL::numeric(24,10),registry.alert_set_hash,'HASH','Monitoring-alert definition set hash.'),
    ('M2_5_REASON_SET_HASH','REASON_SET_HASH',NULL::numeric(24,10),registry.reason_set_hash,'HASH','Monitoring-reason definition set hash.'),
    ('M2_5_SOURCE_SET_HASH','SOURCE_SET_HASH',NULL::numeric(24,10),registry.source_set_hash,'HASH','Activated-advance source set hash.'),
    ('M2_5_DAILY_SET_HASH','DAILY_SET_HASH',NULL::numeric(24,10),registry.daily_set_hash,'HASH','Daily remittance/exposure ledger set hash.'),
    ('M2_5_LATEST_SET_HASH','LATEST_SET_HASH',NULL::numeric(24,10),registry.latest_set_hash,'HASH','Latest monitoring contract set hash.'),
    ('M2_5_ARCHIVE_SET_HASH','ARCHIVE_SET_HASH',NULL::numeric(24,10),registry.archive_set_hash,'HASH','Immutable monitoring archive set hash.'),
    ('M2_5_PORTFOLIO_DAILY_SET_HASH','PORTFOLIO_DAILY_SET_HASH',NULL::numeric(24,10),registry.portfolio_daily_set_hash,'HASH','Portfolio daily summary set hash.'),
    ('M2_5_CONTRACT_SET_HASH','CONTRACT_SET_HASH',NULL::numeric(24,10),registry.contract_set_hash,'HASH','M2.5 contract-registry set hash.'),
    ('M2_5_COMBINED_SET_HASH','COMBINED_SET_HASH',NULL::numeric(24,10),registry.combined_set_hash,'HASH','Complete M2.5 canonical set hash.'),
    ('M2_5_SOURCE_ROW_COUNT','SOURCE_ROW_COUNT',registry.source_rows::numeric(24,10),NULL::text,'ROWS','Activated source rows consumed.'),
    ('M2_5_DAILY_ROW_COUNT','DAILY_ROW_COUNT',registry.daily_rows::numeric(24,10),NULL::text,'ROWS','Daily monitoring rows generated.'),
    ('M2_5_LATEST_ROW_COUNT','LATEST_ROW_COUNT',registry.latest_rows::numeric(24,10),NULL::text,'ROWS','Latest monitoring contract rows generated.'),
    ('M2_5_ARCHIVE_ROW_COUNT','ARCHIVE_ROW_COUNT',registry.archive_rows::numeric(24,10),NULL::text,'ROWS','Immutable archive rows generated.'),
    ('M2_5_PORTFOLIO_DAILY_ROW_COUNT','PORTFOLIO_DAILY_ROW_COUNT',registry.portfolio_daily_rows::numeric(24,10),NULL::text,'ROWS','Portfolio daily summary rows generated.'),
    ('M2_5_COMPARISON_ROW_COUNT','COMPARISON_ROW_COUNT',registry.comparison_rows::numeric(24,10),NULL::text,'ROWS','Matched both-active comparison rows.'),
    ('M2_5_CANONICAL_ENTITY_COUNT','CANONICAL_ENTITY_COUNT',registry.canonical_entities::numeric(24,10),NULL::text,'ROWS','Canonical entities generated.'),
    ('M2_5_TOTAL_REMITTANCE_AMOUNT','TOTAL_REMITTANCE_AMOUNT',registry.total_remittance_amount::numeric(24,10),NULL::text,'CURRENCY','Total synthetic remittance through day 120.'),
    ('M2_5_ENDING_RECEIVABLE_EXPOSURE','ENDING_RECEIVABLE_EXPOSURE',registry.ending_receivable_exposure_amount::numeric(24,10),NULL::text,'CURRENCY','Ending receivable exposure after day 120.'),
    ('M2_5_PAID_OFF_ROW_COUNT','PAID_OFF_ROW_COUNT',registry.paid_off_rows::numeric(24,10),NULL::text,'ROWS','Advances paid off by day 120.'),
    ('M2_5_OPEN_MONITORING_ROW_COUNT','OPEN_MONITORING_ROW_COUNT',registry.open_monitoring_rows::numeric(24,10),NULL::text,'ROWS','Advances still open at day 120.'),
    ('M2_5_STRESS_STATUS_FLOOR_ROW_COUNT','STRESS_STATUS_FLOOR_ROW_COUNT',registry.stress_status_floor_rows::numeric(24,10),NULL::text,'ROWS','Daily stress-status floor applications.'),
    ('M2_5_SOURCE_M2_4_HASH','SOURCE_M2_4_COMBINED_HASH',NULL::numeric(24,10),registry.source_m2_4_combined_hash,'HASH','Accepted M2.4 combined source hash preserved.')
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
    evidence.run_id,
    evidence.evidence_code,
    evidence.segment_key,
    evidence.metric_name,
    evidence.metric_value_numeric,
    evidence.metric_value_text,
    evidence.unit_code,
    evidence.status,
    evidence.interpretation
FROM _m2_5_generation_evidence AS evidence;

/* ============================================================================
Section 13 — Lifecycle transition and final checkpoint
============================================================================ */

UPDATE msbf_ctl.run_registry AS run
SET
    run_status = 'M2_5_GENERATED',
    notes = coalesce(run.notes, '') ||
        ' | M2.5 daily remittance, exposure and portfolio monitoring generated.'
WHERE run.run_id = (SELECT run_id FROM _m2_5_ctx);

INSERT INTO _m2_5_result
(
    run_id,
    run_status,
    policy_rows,
    status_rows,
    alert_rows,
    reason_rows,
    source_rows,
    daily_rows,
    latest_rows,
    archive_rows,
    portfolio_daily_rows,
    comparison_rows,
    registry_rows,
    paid_off_rows,
    open_monitoring_rows,
    stress_status_floor_rows,
    total_remittance_amount,
    ending_receivable_exposure_amount,
    expected_canonical_entities,
    actual_canonical_entities,
    row_level_mismatches,
    stress_status_improvements,
    policy_set_hash,
    status_set_hash,
    alert_set_hash,
    reason_set_hash,
    source_set_hash,
    daily_set_hash,
    latest_set_hash,
    archive_set_hash,
    portfolio_daily_set_hash,
    contract_set_hash,
    combined_set_hash,
    generation_status
)
SELECT
    registry.module1_run_id,
    'M2_5_GENERATED',
    registry.policy_rows,
    registry.status_rows,
    registry.alert_rows,
    registry.reason_rows,
    registry.source_rows,
    registry.daily_rows,
    registry.latest_rows,
    registry.archive_rows,
    registry.portfolio_daily_rows,
    registry.comparison_rows,
    registry.registry_rows,
    registry.paid_off_rows,
    registry.open_monitoring_rows,
    registry.stress_status_floor_rows,
    registry.total_remittance_amount,
    registry.ending_receivable_exposure_amount,
    7536,
    diagnostics.actual_canonical_entities,
    diagnostics.row_level_mismatches,
    diagnostics.stress_status_improvements,
    registry.policy_set_hash,
    registry.status_set_hash,
    registry.alert_set_hash,
    registry.reason_set_hash,
    registry.source_set_hash,
    registry.daily_set_hash,
    registry.latest_set_hash,
    registry.archive_set_hash,
    registry.portfolio_daily_set_hash,
    registry.contract_set_hash,
    registry.combined_set_hash,
    'PASS'
FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS registry
CROSS JOIN _m2_5_generation_diagnostics AS diagnostics
WHERE registry.module1_run_id = (SELECT run_id FROM _m2_5_ctx);

COMMIT;

SELECT
    result.run_id,
    result.run_status,
    result.policy_rows,
    result.status_rows,
    result.alert_rows,
    result.reason_rows,
    result.source_rows,
    result.daily_rows,
    result.latest_rows,
    result.archive_rows,
    result.portfolio_daily_rows,
    result.comparison_rows,
    result.registry_rows,
    result.paid_off_rows,
    result.open_monitoring_rows,
    result.stress_status_floor_rows,
    result.total_remittance_amount,
    result.ending_receivable_exposure_amount,
    result.expected_canonical_entities,
    result.actual_canonical_entities,
    result.row_level_mismatches,
    result.stress_status_improvements,
    result.policy_set_hash,
    result.status_set_hash,
    result.alert_set_hash,
    result.reason_set_hash,
    result.source_set_hash,
    result.daily_set_hash,
    result.latest_set_hash,
    result.archive_set_hash,
    result.portfolio_daily_set_hash,
    result.contract_set_hash,
    result.combined_set_hash,
    result.generation_status
FROM _m2_5_result AS result;
