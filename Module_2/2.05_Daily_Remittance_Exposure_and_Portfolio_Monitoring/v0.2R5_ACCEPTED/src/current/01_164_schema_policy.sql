/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 164_msbf_m2_5_schema_policy_monitoring_contract_extension_v0_2.sql
Version     : v0.2

Business purpose
----------------
Establish the governed daily portfolio-intelligence layer that consumes:
- the accepted M2.4 synthetic portfolio-activation contract; and
- the accepted M1.6 matched POS/deposit scenario history.

M2.5 produces deterministic daily remittance, collection pace, receivable
exposure, liquidity context, monitoring status, alert, latest/archive, and
portfolio-summary evidence for the 59 activated scenario/application records.

Critical boundary
-----------------
M2.5 is monitoring only. It does not initiate a debit, collections action,
restructure, write-off, payment-network instruction, external notice, or
production adverse-action notice.

Engineering controls
--------------------
- Acceptance gate is registered before it can be written.
- Policy row hash is calculated from target-typed physical field names before
  insertion; no invalid placeholder hash is used.
- All policy flags, thresholds, source hashes, and expected counts reconcile to
  the configuration payload.
- Archive immutability is enforced by trigger.
- Consumption, comparison, lineage, Power BI, and canonical views use explicit
  projections and run-scoped identities.

Run order   : Execute once after M2.4 acceptance and before Program 165.
============================================================================ */

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '30min';
SET LOCAL jit = off;

CREATE SCHEMA IF NOT EXISTS msbf_ctl;
CREATE SCHEMA IF NOT EXISTS msbf_m2;

/* ============================================================================
Section 1 — Deterministic hash utilities
============================================================================ */

CREATE OR REPLACE FUNCTION msbf_ctl.m2_5_hash_jsonb(p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $function$
    SELECT md5(p_payload::text);
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_5_registry_row_hash(p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $function$
    SELECT msbf_ctl.m2_5_hash_jsonb
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

/* ============================================================================
Section 2 — Policy, status, alert, and reason dictionaries
============================================================================ */

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_5_policy_profile
(
    module1_run_id                              bigint PRIMARY KEY,
    policy_code                                 text NOT NULL,
    policy_version                              integer NOT NULL,
    policy_status                               text NOT NULL,
    methodology_version                         text NOT NULL,
    contract_code                               text NOT NULL,
    contract_version                            integer NOT NULL,
    schema_version                              text NOT NULL,

    source_m2_4_contract_code                   text NOT NULL,
    source_m2_4_contract_version                integer NOT NULL,
    source_m2_4_schema_version                  text NOT NULL,
    source_m2_4_combined_hash                   text NOT NULL,
    source_m2_4_acceptance_gate_id              text NOT NULL,

    source_m1_6_acceptance_gate_id              text NOT NULL,
    source_m1_6_combined_hash                   text NOT NULL,

    monitoring_horizon_days                    integer NOT NULL,
    source_replay_days                         integer NOT NULL,
    watch_start_day                            integer NOT NULL,
    underperforming_start_day                  integer NOT NULL,
    severe_start_day                           integer NOT NULL,
    watch_pace_ratio                           numeric(9,6) NOT NULL,
    underperforming_pace_ratio                 numeric(9,6) NOT NULL,
    severe_pace_ratio                          numeric(9,6) NOT NULL,
    watch_daily_coverage_ratio                 numeric(9,6) NOT NULL,
    underperforming_no_remittance_days         integer NOT NULL,
    dormant_no_remittance_days                 integer NOT NULL,
    severe_zero_sales_streak_days              integer NOT NULL,
    low_liquidity_available_balance            numeric(18,2) NOT NULL,

    retain_post_payoff_rows_flag               boolean NOT NULL,
    stress_status_nonimprovement_required_flag boolean NOT NULL,
    synthetic_data_only_flag                   boolean NOT NULL,
    no_real_debit_instruction_flag             boolean NOT NULL,
    no_external_notice_generation_flag         boolean NOT NULL,
    no_production_adverse_action_notice_flag   boolean NOT NULL,
    no_write_off_or_restructure_action_flag    boolean NOT NULL,
    monitoring_only_no_servicing_action_flag   boolean NOT NULL,

    expected_policy_rows                       bigint NOT NULL,
    expected_status_rows                       bigint NOT NULL,
    expected_alert_rows                        bigint NOT NULL,
    expected_reason_rows                       bigint NOT NULL,
    expected_source_rows                       bigint NOT NULL,
    expected_daily_rows                        bigint NOT NULL,
    expected_latest_rows                       bigint NOT NULL,
    expected_archive_rows                      bigint NOT NULL,
    expected_portfolio_daily_rows              bigint NOT NULL,
    expected_comparison_rows                   bigint NOT NULL,
    expected_registry_rows                     bigint NOT NULL,
    expected_canonical_entities                bigint NOT NULL,
    expected_positive_controls                 integer NOT NULL,
    expected_negative_controls                 integer NOT NULL,
    expected_detail_result_sets                integer NOT NULL,

    configuration_payload                      jsonb NOT NULL,
    configuration_hash                         text NOT NULL,
    row_hash                                   text NOT NULL,
    created_at                                 timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at                                 timestamptz NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT ck_m2_5_policy_identity CHECK
    (
        policy_code = 'M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_POLICY_V1'
        AND policy_version = 1
        AND methodology_version = 'M2_5_METHOD_V1'
        AND contract_code = 'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'
        AND contract_version = 1
        AND schema_version = 'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1'
    ),

    CONSTRAINT ck_m2_5_policy_status CHECK
    (
        policy_status IN ('APPROVED','RETIRED')
    ),

    CONSTRAINT ck_m2_5_policy_hashes CHECK
    (
        length(configuration_hash) = 32
        AND configuration_hash ~ '^[0-9a-f]+$'
        AND length(row_hash) = 32
        AND row_hash ~ '^[0-9a-f]+$'
        AND length(source_m2_4_combined_hash) = 32
        AND source_m2_4_combined_hash ~ '^[0-9a-f]+$'
        AND length(source_m1_6_combined_hash) = 32
        AND source_m1_6_combined_hash ~ '^[0-9a-f]+$'
    ),

    CONSTRAINT ck_m2_5_policy_thresholds CHECK
    (
        monitoring_horizon_days = 120
        AND source_replay_days = 120
        AND watch_start_day >= 1
        AND underperforming_start_day >= watch_start_day
        AND severe_start_day >= watch_start_day
        AND watch_pace_ratio BETWEEN 0 AND 1
        AND underperforming_pace_ratio BETWEEN 0 AND watch_pace_ratio
        AND severe_pace_ratio BETWEEN 0 AND underperforming_pace_ratio
        AND watch_daily_coverage_ratio BETWEEN 0 AND 1
        AND underperforming_no_remittance_days >= 1
        AND dormant_no_remittance_days > underperforming_no_remittance_days
        AND severe_zero_sales_streak_days >= 1
    ),

    CONSTRAINT ck_m2_5_policy_boundaries CHECK
    (
        retain_post_payoff_rows_flag
        AND stress_status_nonimprovement_required_flag
        AND synthetic_data_only_flag
        AND no_real_debit_instruction_flag
        AND no_external_notice_generation_flag
        AND no_production_adverse_action_notice_flag
        AND no_write_off_or_restructure_action_flag
        AND monitoring_only_no_servicing_action_flag
    )
);

COMMENT ON TABLE msbf_ctl.m2_5_policy_profile IS
'Governed M2.5 monitoring policy, thresholds, source identities, boundaries and expected cardinalities.';

CREATE TABLE IF NOT EXISTS msbf_m2.portfolio_monitoring_status_definition
(
    module1_run_id                     bigint NOT NULL,
    monitoring_status_code             text NOT NULL,
    monitoring_status_rank             integer NOT NULL,
    watch_flag                         boolean NOT NULL,
    underperforming_flag               boolean NOT NULL,
    severe_shortfall_flag              boolean NOT NULL,
    dormant_flag                       boolean NOT NULL,
    paid_off_flag                      boolean NOT NULL,
    status_active_flag                 boolean NOT NULL,
    description                        text NOT NULL,
    row_hash                           text NOT NULL,
    created_at                         timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id, monitoring_status_code),
    UNIQUE(module1_run_id, monitoring_status_rank),

    CONSTRAINT ck_m2_5_status_rank CHECK
    (
        monitoring_status_rank BETWEEN 0 AND 5
    ),

    CONSTRAINT ck_m2_5_status_flags CHECK
    (
        (
            monitoring_status_code = 'PAID_OFF'
            AND monitoring_status_rank = 0
            AND paid_off_flag
            AND NOT watch_flag
            AND NOT underperforming_flag
            AND NOT severe_shortfall_flag
            AND NOT dormant_flag
        )
        OR
        (
            monitoring_status_code = 'CURRENT'
            AND monitoring_status_rank = 1
            AND NOT paid_off_flag
            AND NOT watch_flag
            AND NOT underperforming_flag
            AND NOT severe_shortfall_flag
            AND NOT dormant_flag
        )
        OR
        (
            monitoring_status_code = 'WATCH'
            AND monitoring_status_rank = 2
            AND watch_flag
            AND NOT paid_off_flag
        )
        OR
        (
            monitoring_status_code = 'UNDERPERFORMING'
            AND monitoring_status_rank = 3
            AND watch_flag
            AND underperforming_flag
            AND NOT paid_off_flag
        )
        OR
        (
            monitoring_status_code = 'SEVERE_SHORTFALL'
            AND monitoring_status_rank = 4
            AND watch_flag
            AND underperforming_flag
            AND severe_shortfall_flag
            AND NOT paid_off_flag
        )
        OR
        (
            monitoring_status_code = 'DORMANT_NO_REMITTANCE'
            AND monitoring_status_rank = 5
            AND watch_flag
            AND underperforming_flag
            AND severe_shortfall_flag
            AND dormant_flag
            AND NOT paid_off_flag
        )
    )
);

COMMENT ON TABLE msbf_m2.portfolio_monitoring_status_definition IS
'Governed M2.5 monitoring statuses ordered from paid off/current through dormant no-remittance.';

CREATE TABLE IF NOT EXISTS msbf_m2.portfolio_monitoring_alert_definition
(
    module1_run_id                     bigint NOT NULL,
    monitoring_alert_code              text NOT NULL,
    alert_rank                         integer NOT NULL,
    severity_code                      text NOT NULL,
    alert_active_flag                  boolean NOT NULL,
    description                        text NOT NULL,
    row_hash                           text NOT NULL,
    created_at                         timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id, monitoring_alert_code),
    UNIQUE(module1_run_id, alert_rank),

    CONSTRAINT ck_m2_5_alert_rank CHECK
    (
        alert_rank BETWEEN 1 AND 7
    ),

    CONSTRAINT ck_m2_5_alert_severity CHECK
    (
        severity_code IN ('WATCH','HIGH','CRITICAL','GOVERNANCE')
    )
);

COMMENT ON TABLE msbf_m2.portfolio_monitoring_alert_definition IS
'Governed M2.5 alert dictionary for remittance, pace, liquidity, horizon and stress-floor monitoring.';

CREATE TABLE IF NOT EXISTS msbf_m2.portfolio_monitoring_reason_definition
(
    module1_run_id                         bigint NOT NULL,
    monitoring_reason_code                 text NOT NULL,
    mapped_monitoring_status_code          text NOT NULL,
    production_adverse_action_notice_flag  boolean NOT NULL,
    servicing_action_authorized_flag       boolean NOT NULL,
    reason_active_flag                     boolean NOT NULL,
    description                            text NOT NULL,
    row_hash                               text NOT NULL,
    created_at                             timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id, monitoring_reason_code),

    CONSTRAINT fk_m2_5_reason_status FOREIGN KEY
    (
        module1_run_id,
        mapped_monitoring_status_code
    )
    REFERENCES msbf_m2.portfolio_monitoring_status_definition
    (
        module1_run_id,
        monitoring_status_code
    ),

    CONSTRAINT ck_m2_5_reason_boundaries CHECK
    (
        production_adverse_action_notice_flag IS FALSE
        AND servicing_action_authorized_flag IS FALSE
    )
);

COMMENT ON TABLE msbf_m2.portfolio_monitoring_reason_definition IS
'Internal M2.5 monitoring reasons; no servicing action or production notice is authorized.';

/* ============================================================================
Section 3 — Source, daily ledger, latest/archive, portfolio summary, registry
============================================================================ */

CREATE TABLE IF NOT EXISTS msbf_m2.advance_monitoring_source_snapshot
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
    row_hash                               text NOT NULL,
    created_at                             timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id, scenario_id, merchant_application_id),
    UNIQUE(module1_run_id, synthetic_advance_id),

    CONSTRAINT ck_m2_5_source_scenario CHECK
    (
        scenario_code IN ('BASELINE','RECESSION_ENERGY')
    ),

    CONSTRAINT ck_m2_5_source_amounts CHECK
    (
        funded_amount > 0
        AND total_repayment_amount >= funded_amount
        AND finance_charge_amount >= 0
        AND remittance_rate BETWEEN 0.05 AND 0.20
        AND collection_horizon_days BETWEEN 1 AND 120
        AND implied_daily_collection_amount > 0
        AND initial_exposure_amount = funded_amount
    )
);

COMMENT ON TABLE msbf_m2.advance_monitoring_source_snapshot IS
'Run-scoped M2.5 source snapshot for the 59 accepted M2.4 activated advances.';

CREATE TABLE IF NOT EXISTS msbf_m2.advance_daily_remittance_monitoring
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
    row_hash                               text NOT NULL,
    created_at                             timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY
    (
        module1_run_id,
        scenario_id,
        merchant_application_id,
        monitoring_day_index
    ),

    CONSTRAINT fk_m2_5_daily_status FOREIGN KEY
    (
        module1_run_id,
        monitoring_status_code
    )
    REFERENCES msbf_m2.portfolio_monitoring_status_definition
    (
        module1_run_id,
        monitoring_status_code
    ),

    CONSTRAINT fk_m2_5_daily_reason FOREIGN KEY
    (
        module1_run_id,
        primary_monitoring_reason_code
    )
    REFERENCES msbf_m2.portfolio_monitoring_reason_definition
    (
        module1_run_id,
        monitoring_reason_code
    ),

    CONSTRAINT ck_m2_5_daily_index CHECK
    (
        monitoring_day_index BETWEEN 1 AND 120
    ),

    CONSTRAINT ck_m2_5_daily_nonnegative CHECK
    (
        source_gross_pos_sales >= 0
        AND source_eligible_pos_sales >= 0
        AND source_nsf_count >= 0
        AND expected_daily_remittance_amount > 0
        AND expected_due_today_amount >= 0
        AND raw_remittance_amount >= 0
        AND actual_remittance_amount >= 0
        AND cumulative_remittance_amount >= 0
        AND cumulative_expected_remittance_amount >= 0
        AND daily_shortfall_amount >= 0
        AND cumulative_shortfall_amount >= 0
        AND receivable_balance_before >= 0
        AND receivable_balance_after >= 0
        AND principal_exposure_proxy >= 0
        AND unearned_finance_charge_proxy >= 0
        AND days_since_last_positive_remittance >= 0
        AND zero_sales_streak_days >= 0
        AND trailing_7_day_remittance_amount >= 0
        AND trailing_30_day_remittance_amount >= 0
    ),

    CONSTRAINT ck_m2_5_daily_reconcile CHECK
    (
        actual_remittance_amount <= raw_remittance_amount + 0.01
        AND actual_remittance_amount <= receivable_balance_before + 0.01
        AND abs
        (
            receivable_balance_after -
            greatest
            (
                receivable_balance_before - actual_remittance_amount,
                0
            )
        ) <= 0.01
        AND abs
        (
            principal_exposure_proxy +
            unearned_finance_charge_proxy -
            receivable_balance_after
        ) <= 0.02
        AND paid_off_flag = (receivable_balance_after = 0)
    ),

    CONSTRAINT ck_m2_5_daily_status_rank CHECK
    (
        raw_monitoring_status_rank BETWEEN 0 AND 5
        AND monitoring_status_rank BETWEEN 0 AND 5
        AND
        (
            scenario_code <> 'RECESSION_ENERGY'
            OR monitoring_status_rank >= raw_monitoring_status_rank
        )
    )
);

COMMENT ON TABLE msbf_m2.advance_daily_remittance_monitoring IS
'Deterministic 120-day remittance, exposure, liquidity and monitoring ledger for activated advances.';

CREATE TABLE IF NOT EXISTS msbf_m2.advance_portfolio_monitoring_latest
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
    contract_row_hash                      text NOT NULL,
    created_at                             timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id, scenario_id, merchant_application_id),
    UNIQUE(module1_run_id, synthetic_advance_id),

    CONSTRAINT fk_m2_5_latest_status FOREIGN KEY
    (
        module1_run_id,
        latest_monitoring_status_code
    )
    REFERENCES msbf_m2.portfolio_monitoring_status_definition
    (
        module1_run_id,
        monitoring_status_code
    ),

    CONSTRAINT fk_m2_5_latest_reason FOREIGN KEY
    (
        module1_run_id,
        primary_monitoring_reason_code
    )
    REFERENCES msbf_m2.portfolio_monitoring_reason_definition
    (
        module1_run_id,
        monitoring_reason_code
    ),

    CONSTRAINT ck_m2_5_latest_identity CHECK
    (
        contract_code = 'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'
        AND contract_version = 1
        AND schema_version = 'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1'
        AND methodology_version = 'M2_5_METHOD_V1'
        AND monitoring_horizon_days = 120
        AND latest_monitoring_day_index = 120
    )
);

COMMENT ON TABLE msbf_m2.advance_portfolio_monitoring_latest IS
'Latest 120-day M2.5 monitoring contract for each activated scenario/application record.';

CREATE TABLE IF NOT EXISTS msbf_m2.advance_portfolio_monitoring_archive
(
    archive_id                              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    contract_row_hash                      text NOT NULL,
    contract_payload                       jsonb NOT NULL,
    archive_row_hash                       text NOT NULL,
    archived_at                            timestamptz NOT NULL DEFAULT clock_timestamp(),
    created_at                             timestamptz NOT NULL DEFAULT clock_timestamp(),

    UNIQUE
    (
        module1_run_id,
        contract_version,
        scenario_id,
        merchant_application_id
    ),

    CONSTRAINT ck_m2_5_archive_identity CHECK
    (
        contract_code = 'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'
        AND contract_version = 1
        AND schema_version = 'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1'
        AND methodology_version = 'M2_5_METHOD_V1'
        AND monitoring_horizon_days = 120
        AND latest_monitoring_day_index = 120
    )
);

COMMENT ON TABLE msbf_m2.advance_portfolio_monitoring_archive IS
'Immutable M2.5 monitoring archive including exact latest-contract payload.';

CREATE TABLE IF NOT EXISTS msbf_m2.portfolio_daily_monitoring_summary
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
    row_hash                               text NOT NULL,
    created_at                             timestamptz NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY(module1_run_id, scenario_id, monitoring_day_index),

    CONSTRAINT ck_m2_5_portfolio_day CHECK
    (
        monitoring_day_index BETWEEN 1 AND 120
        AND opening_advance_count >= 0
        AND active_advance_count >= 0
        AND paid_off_count >= 0
        AND current_count >= 0
        AND watch_count >= 0
        AND underperforming_count >= 0
        AND severe_shortfall_count >= 0
        AND dormant_no_remittance_count >= 0
        AND daily_eligible_pos_sales >= 0
        AND daily_remittance_amount >= 0
        AND cumulative_remittance_amount >= 0
        AND cumulative_expected_remittance_amount >= 0
        AND cumulative_shortfall_amount >= 0
        AND total_receivable_exposure_amount >= 0
        AND total_principal_exposure_proxy >= 0
        AND stress_status_floor_rows >= 0
    )
);

COMMENT ON TABLE msbf_m2.portfolio_daily_monitoring_summary IS
'Run/scenario/day M2.5 portfolio remittance, exposure and status aggregation.';

CREATE TABLE IF NOT EXISTS msbf_ctl.m2_5_portfolio_monitoring_contract_registry
(
    registry_id                              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id                          bigint NOT NULL UNIQUE,
    contract_code                            text NOT NULL,
    contract_version                         integer NOT NULL,
    schema_version                           text NOT NULL,
    methodology_version                      text NOT NULL,

    source_m2_4_contract_code                text NOT NULL,
    source_m2_4_contract_version             integer NOT NULL,
    source_m2_4_schema_version               text NOT NULL,
    source_m2_4_combined_hash                text NOT NULL,
    source_m2_4_acceptance_gate_id           text NOT NULL,
    source_m1_6_acceptance_gate_id           text NOT NULL,
    source_m1_6_combined_hash                text NOT NULL,
    policy_configuration_hash                text NOT NULL,

    policy_rows                              bigint NOT NULL,
    status_rows                              bigint NOT NULL,
    alert_rows                               bigint NOT NULL,
    reason_rows                              bigint NOT NULL,
    source_rows                              bigint NOT NULL,
    daily_rows                               bigint NOT NULL,
    latest_rows                              bigint NOT NULL,
    archive_rows                             bigint NOT NULL,
    portfolio_daily_rows                    bigint NOT NULL,
    comparison_rows                         bigint NOT NULL,
    registry_rows                           bigint NOT NULL,
    canonical_entities                      bigint NOT NULL,

    paid_off_rows                            bigint NOT NULL,
    open_monitoring_rows                     bigint NOT NULL,
    stress_status_floor_rows                 bigint NOT NULL,
    total_remittance_amount                 numeric(24,2) NOT NULL,
    ending_receivable_exposure_amount       numeric(24,2) NOT NULL,

    policy_set_hash                          text NOT NULL,
    status_set_hash                          text NOT NULL,
    alert_set_hash                           text NOT NULL,
    reason_set_hash                          text NOT NULL,
    source_set_hash                          text NOT NULL,
    daily_set_hash                           text NOT NULL,
    latest_set_hash                          text NOT NULL,
    archive_set_hash                         text NOT NULL,
    portfolio_daily_set_hash                 text NOT NULL,
    contract_set_hash                        text NOT NULL,
    combined_set_hash                        text NOT NULL,

    contract_status                          text NOT NULL,
    generated_at                             timestamptz,
    validated_at                             timestamptz,
    accepted_at                              timestamptz,
    row_hash                                 text NOT NULL,
    created_at                               timestamptz NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT ck_m2_5_registry_status CHECK
    (
        contract_status IN ('GENERATED','VALIDATED','ACCEPTED')
    ),

    CONSTRAINT ck_m2_5_registry_identity CHECK
    (
        contract_code = 'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'
        AND contract_version = 1
        AND schema_version = 'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1'
        AND methodology_version = 'M2_5_METHOD_V1'
    )
);

COMMENT ON TABLE msbf_ctl.m2_5_portfolio_monitoring_contract_registry IS
'M2.5 contract lifecycle, counts, monitoring metrics and deterministic set hashes.';

/* ============================================================================
Section 4 — Archive immutability and indexes
============================================================================ */

CREATE OR REPLACE FUNCTION msbf_ctl.m2_5_archive_immutable()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    RAISE EXCEPTION
        'M2.5 portfolio-monitoring archive is immutable; % is not permitted.',
        TG_OP;
END;
$function$;

DROP TRIGGER IF EXISTS trg_m2_5_monitoring_archive_immutable
ON msbf_m2.advance_portfolio_monitoring_archive;

CREATE TRIGGER trg_m2_5_monitoring_archive_immutable
BEFORE UPDATE OR DELETE
ON msbf_m2.advance_portfolio_monitoring_archive
FOR EACH ROW
EXECUTE FUNCTION msbf_ctl.m2_5_archive_immutable();

CREATE INDEX IF NOT EXISTS ix_m2_5_daily_advance_date
ON msbf_m2.advance_daily_remittance_monitoring
(module1_run_id, synthetic_advance_id, monitoring_day_index);

CREATE INDEX IF NOT EXISTS ix_m2_5_daily_status
ON msbf_m2.advance_daily_remittance_monitoring
(module1_run_id, scenario_code, monitoring_status_code, monitoring_day_index);

CREATE INDEX IF NOT EXISTS ix_m2_5_latest_status
ON msbf_m2.advance_portfolio_monitoring_latest
(module1_run_id, scenario_code, latest_monitoring_status_code);

CREATE INDEX IF NOT EXISTS ix_m2_5_portfolio_day
ON msbf_m2.portfolio_daily_monitoring_summary
(module1_run_id, scenario_code, monitoring_day_index);

/* ============================================================================
Section 5 — Configuration, lifecycle, and prohibited-payload assertions
============================================================================ */

CREATE OR REPLACE FUNCTION msbf_ctl.m2_5_assert_configuration(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v record;
BEGIN
    SELECT policy.*
    INTO v
    FROM msbf_ctl.m2_5_policy_profile AS policy
    WHERE policy.module1_run_id = p_run_id;

    IF v.module1_run_id IS NULL
       OR v.policy_status <> 'APPROVED'
       OR v.policy_code <> 'M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_POLICY_V1'
       OR v.policy_version <> 1
       OR v.methodology_version <> 'M2_5_METHOD_V1'
       OR v.contract_code <> 'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'
       OR v.contract_version <> 1
       OR v.schema_version <> 'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1'
       OR v.source_m2_4_contract_code <> 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
       OR v.source_m2_4_contract_version <> 1
       OR v.source_m2_4_schema_version <> 'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
       OR v.source_m2_4_combined_hash <> '117450a3eea7bb3d3c74d18cc3c8e96a'
       OR v.source_m2_4_acceptance_gate_id <> 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
       OR v.source_m1_6_acceptance_gate_id <> 'M1_6_MATCHED_SCENARIO_OVERLAYS'

       OR v.monitoring_horizon_days <> 120
       OR v.source_replay_days <> 120
       OR v.watch_start_day <> 7
       OR v.underperforming_start_day <> 14
       OR v.severe_start_day <> 14
       OR v.watch_pace_ratio <> 0.900000
       OR v.underperforming_pace_ratio <> 0.750000
       OR v.severe_pace_ratio <> 0.500000
       OR v.watch_daily_coverage_ratio <> 0.750000
       OR v.underperforming_no_remittance_days <> 7
       OR v.dormant_no_remittance_days <> 14
       OR v.severe_zero_sales_streak_days <> 10
       OR v.low_liquidity_available_balance <> 0.00

       OR v.retain_post_payoff_rows_flag IS DISTINCT FROM TRUE
       OR v.stress_status_nonimprovement_required_flag IS DISTINCT FROM TRUE
       OR v.synthetic_data_only_flag IS DISTINCT FROM TRUE
       OR v.no_real_debit_instruction_flag IS DISTINCT FROM TRUE
       OR v.no_external_notice_generation_flag IS DISTINCT FROM TRUE
       OR v.no_production_adverse_action_notice_flag IS DISTINCT FROM TRUE
       OR v.no_write_off_or_restructure_action_flag IS DISTINCT FROM TRUE
       OR v.monitoring_only_no_servicing_action_flag IS DISTINCT FROM TRUE

       OR (v.configuration_payload->>'monitoring_horizon_days')::integer
          IS DISTINCT FROM v.monitoring_horizon_days
       OR (v.configuration_payload->>'source_replay_days')::integer
          IS DISTINCT FROM v.source_replay_days
       OR (v.configuration_payload->>'watch_start_day')::integer
          IS DISTINCT FROM v.watch_start_day
       OR (v.configuration_payload->>'underperforming_start_day')::integer
          IS DISTINCT FROM v.underperforming_start_day
       OR (v.configuration_payload->>'severe_start_day')::integer
          IS DISTINCT FROM v.severe_start_day
       OR (v.configuration_payload->>'watch_pace_ratio')::numeric
          IS DISTINCT FROM v.watch_pace_ratio
       OR (v.configuration_payload->>'underperforming_pace_ratio')::numeric
          IS DISTINCT FROM v.underperforming_pace_ratio
       OR (v.configuration_payload->>'severe_pace_ratio')::numeric
          IS DISTINCT FROM v.severe_pace_ratio
       OR (v.configuration_payload->>'watch_daily_coverage_ratio')::numeric
          IS DISTINCT FROM v.watch_daily_coverage_ratio
       OR (v.configuration_payload->>'underperforming_no_remittance_days')::integer
          IS DISTINCT FROM v.underperforming_no_remittance_days
       OR (v.configuration_payload->>'dormant_no_remittance_days')::integer
          IS DISTINCT FROM v.dormant_no_remittance_days
       OR (v.configuration_payload->>'severe_zero_sales_streak_days')::integer
          IS DISTINCT FROM v.severe_zero_sales_streak_days
       OR (v.configuration_payload->>'low_liquidity_available_balance')::numeric
          IS DISTINCT FROM v.low_liquidity_available_balance

       OR (v.configuration_payload->>'retain_post_payoff_rows')::boolean
          IS DISTINCT FROM v.retain_post_payoff_rows_flag
       OR (v.configuration_payload->>'stress_status_nonimprovement_required')::boolean
          IS DISTINCT FROM v.stress_status_nonimprovement_required_flag
       OR (v.configuration_payload->>'synthetic_data_only')::boolean
          IS DISTINCT FROM v.synthetic_data_only_flag
       OR (v.configuration_payload->>'no_real_debit_instruction')::boolean
          IS DISTINCT FROM v.no_real_debit_instruction_flag
       OR (v.configuration_payload->>'no_external_notice_generation')::boolean
          IS DISTINCT FROM v.no_external_notice_generation_flag
       OR (v.configuration_payload->>'no_production_adverse_action_notice')::boolean
          IS DISTINCT FROM v.no_production_adverse_action_notice_flag
       OR (v.configuration_payload->>'no_write_off_or_restructure_action')::boolean
          IS DISTINCT FROM v.no_write_off_or_restructure_action_flag
       OR (v.configuration_payload->>'monitoring_only_no_servicing_action')::boolean
          IS DISTINCT FROM v.monitoring_only_no_servicing_action_flag

       OR v.configuration_hash IS DISTINCT FROM
          msbf_ctl.m2_5_hash_jsonb(v.configuration_payload)

       OR v.row_hash IS DISTINCT FROM
          msbf_ctl.m2_5_hash_jsonb
          (
              to_jsonb(v)
              - 'row_hash'
              - 'created_at'
              - 'updated_at'
          ) THEN
        RAISE EXCEPTION
            'M2.5 configuration assertion failed for run_id %.',
            p_run_id;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_5_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_status text;
BEGIN
    PERFORM msbf_ctl.m2_5_assert_configuration(p_run_id);

    SELECT run_status
    INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    IF v_run_status <> 'M2_4_ACCEPTED' THEN
        RAISE EXCEPTION
            'M2.5 generation requires M2_4_ACCEPTED; observed %.',
            v_run_status;
    END IF;

    IF EXISTS
    (
        SELECT 1
        FROM msbf_m2.advance_monitoring_source_snapshot
        WHERE module1_run_id = p_run_id

        UNION ALL

        SELECT 1
        FROM msbf_m2.advance_daily_remittance_monitoring
        WHERE module1_run_id = p_run_id

        UNION ALL

        SELECT 1
        FROM msbf_m2.advance_portfolio_monitoring_latest
        WHERE module1_run_id = p_run_id

        UNION ALL

        SELECT 1
        FROM msbf_m2.advance_portfolio_monitoring_archive
        WHERE module1_run_id = p_run_id

        UNION ALL

        SELECT 1
        FROM msbf_m2.portfolio_daily_monitoring_summary
        WHERE module1_run_id = p_run_id

        UNION ALL

        SELECT 1
        FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
        WHERE module1_run_id = p_run_id

        UNION ALL

        SELECT 1
        FROM msbf_ctl.run_evidence
        WHERE run_id = p_run_id
          AND evidence_code LIKE 'M2_5_%'

        UNION ALL

        SELECT 1
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id = p_run_id
          AND gate_id = 'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
    ) THEN
        RAISE EXCEPTION
            'M2.5 generation requires empty M2.5 targets for run_id %.',
            p_run_id;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_5_assert_validation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_status text;
    v_contract_status text;
BEGIN
    PERFORM msbf_ctl.m2_5_assert_configuration(p_run_id);

    SELECT run_status
    INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    SELECT contract_status
    INTO v_contract_status
    FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
    WHERE module1_run_id = p_run_id;

    IF v_run_status <> 'M2_5_GENERATED'
       OR v_contract_status <> 'GENERATED' THEN
        RAISE EXCEPTION
            'M2.5 validation requires generated state; run %, contract %.',
            v_run_status,
            v_contract_status;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_5_assert_acceptance_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_status text;
    v_contract_status text;
    v_positive_passes bigint;
    v_negative_passes bigint;
BEGIN
    PERFORM msbf_ctl.m2_5_assert_configuration(p_run_id);

    SELECT run_status
    INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    SELECT contract_status
    INTO v_contract_status
    FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
    WHERE module1_run_id = p_run_id;

    SELECT
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_POS_%'
              AND status = 'PASS'
        ),
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_NEG_%'
              AND status = 'PASS'
        )
    INTO
        v_positive_passes,
        v_negative_passes
    FROM msbf_ctl.run_evidence
    WHERE run_id = p_run_id;

    IF v_run_status <> 'M2_5_VALIDATED'
       OR v_contract_status <> 'VALIDATED'
       OR v_positive_passes <> 120
       OR v_negative_passes <> 20 THEN
        RAISE EXCEPTION
            'M2.5 acceptance not ready: run %, contract %, positive %, negative %.',
            v_run_status,
            v_contract_status,
            v_positive_passes,
            v_negative_passes;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_5_assert_no_servicing_action_payload
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
    FROM jsonb_object_keys(coalesce(p_payload, '{}'::jsonb)) AS key
    WHERE lower(key) IN
    (
        'debit_instruction',
        'real_debit_instruction',
        'ach_trace_number',
        'payment_network_confirmation',
        'bank_account_number',
        'routing_number',
        'account_number',
        'collection_action',
        'servicing_action',
        'write_off',
        'charge_off',
        'restructure_offer',
        'workout_offer',
        'external_notice',
        'external_notice_payload',
        'production_adverse_action_notice',
        'production_adverse_action_notice_payload'
    )
    LIMIT 1;

    IF v_key IS NOT NULL THEN
        RAISE EXCEPTION
            'M2.5 boundary rejected prohibited servicing payload key %.',
            v_key;
    END IF;
END;
$function$;

/* ============================================================================
Section 6 — Acceptance-gate registration
============================================================================ */

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
    'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING',
    'M2.5 Daily Remittance, Exposure & Portfolio Monitoring',
    'M2.5',
    'BLOCKING',
    TRUE,
    'Accepts deterministic daily remittance, exposure, liquidity and monitoring evidence while prohibiting real debit instructions, servicing actions, write-off/restructure actions, external notices and production adverse-action notices.'
)
ON CONFLICT(gate_id)
DO UPDATE SET
    gate_name = EXCLUDED.gate_name,
    module_code = EXCLUDED.module_code,
    severity = EXCLUDED.severity,
    active_flag = EXCLUDED.active_flag,
    description = EXCLUDED.description;

/* ============================================================================
Section 7 — Target-typed policy seed with dynamic accepted M1.6 hash
============================================================================ */

WITH source_context AS
(
    SELECT
        registry.module1_run_id,
        registry.combined_set_hash AS source_m2_4_combined_hash,
        evidence.metric_value_text AS source_m1_6_combined_hash
    FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry
    JOIN msbf_ctl.run_registry AS run
      ON run.run_id = registry.module1_run_id
    JOIN msbf_ctl.acceptance_gate_result AS source_gate
      ON source_gate.run_id = registry.module1_run_id
     AND source_gate.gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
     AND source_gate.review_version = 1
    JOIN msbf_ctl.run_evidence AS evidence
      ON evidence.run_id = registry.module1_run_id
     AND evidence.evidence_code = 'M1_6_COMBINED_SET_HASH'
     AND evidence.segment_key = 'PORTFOLIO'
     AND evidence.status = 'PASS'
    JOIN msbf_ctl.acceptance_gate_result AS m1_6_gate
      ON m1_6_gate.run_id = registry.module1_run_id
     AND m1_6_gate.gate_id = 'M1_6_MATCHED_SCENARIO_OVERLAYS'
     AND m1_6_gate.result_status = 'PASS'
    WHERE run.run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run.run_version = 1
      AND run.run_status = 'M2_4_ACCEPTED'
      AND registry.contract_status = 'ACCEPTED'
      AND registry.contract_code = 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
      AND registry.contract_version = 1
      AND registry.schema_version = 'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
      AND registry.combined_set_hash = '117450a3eea7bb3d3c74d18cc3c8e96a'
      AND source_gate.result_status = 'PASS'
      AND length(evidence.metric_value_text) = 32
      AND evidence.metric_value_text ~ '^[0-9a-f]+$'
),
policy_seed AS
(
    SELECT
        source.module1_run_id::bigint AS module1_run_id,
        'M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_POLICY_V1'::text AS policy_code,
        1::integer AS policy_version,
        'APPROVED'::text AS policy_status,
        'M2_5_METHOD_V1'::text AS methodology_version,
        'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'::text AS contract_code,
        1::integer AS contract_version,
        'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1'::text AS schema_version,

        'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'::text AS source_m2_4_contract_code,
        1::integer AS source_m2_4_contract_version,
        'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'::text AS source_m2_4_schema_version,
        source.source_m2_4_combined_hash::text AS source_m2_4_combined_hash,
        'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'::text AS source_m2_4_acceptance_gate_id,

        'M1_6_MATCHED_SCENARIO_OVERLAYS'::text AS source_m1_6_acceptance_gate_id,
        source.source_m1_6_combined_hash::text AS source_m1_6_combined_hash,

        120::integer AS monitoring_horizon_days,
        120::integer AS source_replay_days,
        7::integer AS watch_start_day,
        14::integer AS underperforming_start_day,
        14::integer AS severe_start_day,
        0.900000::numeric(9,6) AS watch_pace_ratio,
        0.750000::numeric(9,6) AS underperforming_pace_ratio,
        0.500000::numeric(9,6) AS severe_pace_ratio,
        0.750000::numeric(9,6) AS watch_daily_coverage_ratio,
        7::integer AS underperforming_no_remittance_days,
        14::integer AS dormant_no_remittance_days,
        10::integer AS severe_zero_sales_streak_days,
        0.00::numeric(18,2) AS low_liquidity_available_balance,

        TRUE::boolean AS retain_post_payoff_rows_flag,
        TRUE::boolean AS stress_status_nonimprovement_required_flag,
        TRUE::boolean AS synthetic_data_only_flag,
        TRUE::boolean AS no_real_debit_instruction_flag,
        TRUE::boolean AS no_external_notice_generation_flag,
        TRUE::boolean AS no_production_adverse_action_notice_flag,
        TRUE::boolean AS no_write_off_or_restructure_action_flag,
        TRUE::boolean AS monitoring_only_no_servicing_action_flag,

        1::bigint AS expected_policy_rows,
        6::bigint AS expected_status_rows,
        7::bigint AS expected_alert_rows,
        24::bigint AS expected_reason_rows,
        59::bigint AS expected_source_rows,
        7080::bigint AS expected_daily_rows,
        59::bigint AS expected_latest_rows,
        59::bigint AS expected_archive_rows,
        240::bigint AS expected_portfolio_daily_rows,
        15::bigint AS expected_comparison_rows,
        1::bigint AS expected_registry_rows,
        7536::bigint AS expected_canonical_entities,
        120::integer AS expected_positive_controls,
        20::integer AS expected_negative_controls,
        24::integer AS expected_detail_result_sets,

        jsonb_build_object
        (
            'methodology', 'M2_5_METHOD_V1',
            'policy_code', 'M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_POLICY_V1',
            'contract_code', 'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION',
            'contract_version', 1,
            'schema_version', 'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1',
            'source_m2_4_contract_code', 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION',
            'source_m2_4_contract_version', 1,
            'source_m2_4_schema_version', 'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1',
            'source_m2_4_combined_hash', source.source_m2_4_combined_hash,
            'source_m2_4_acceptance_gate_id', 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION',
            'source_m1_6_acceptance_gate_id', 'M1_6_MATCHED_SCENARIO_OVERLAYS',
            'source_m1_6_combined_hash', source.source_m1_6_combined_hash,
            'monitoring_horizon_days', 120,
            'source_replay_days', 120,
            'watch_start_day', 7,
            'underperforming_start_day', 14,
            'severe_start_day', 14,
            'watch_pace_ratio', 0.900000,
            'underperforming_pace_ratio', 0.750000,
            'severe_pace_ratio', 0.500000,
            'watch_daily_coverage_ratio', 0.750000,
            'underperforming_no_remittance_days', 7,
            'dormant_no_remittance_days', 14,
            'severe_zero_sales_streak_days', 10,
            'low_liquidity_available_balance', 0.00,
            'retain_post_payoff_rows', TRUE,
            'stress_status_nonimprovement_required', TRUE,
            'synthetic_data_only', TRUE,
            'no_real_debit_instruction', TRUE,
            'no_external_notice_generation', TRUE,
            'no_production_adverse_action_notice', TRUE,
            'no_write_off_or_restructure_action', TRUE,
            'monitoring_only_no_servicing_action', TRUE,
            'expected', '{"alert_rows":7,"archive_rows":59,"baseline_source_rows":44,"canonical_entities":7536,"comparison_rows":15,"daily_rows":7080,"detail_result_sets":24,"generation_evidence_rows":24,"latest_rows":59,"m1_6_deposit_rows":270000,"m1_6_pos_rows":270000,"monitoring_horizon_days":120,"negative_controls":20,"policy_rows":1,"portfolio_daily_rows":240,"positive_controls":120,"reason_rows":24,"registry_rows":1,"replay_days":120,"source_rows":59,"status_rows":6,"stress_source_rows":15}'::jsonb
        ) AS configuration_payload

    FROM source_context AS source
),
policy_with_configuration_hash AS
(
    SELECT
        seed.*,
        msbf_ctl.m2_5_hash_jsonb(seed.configuration_payload)
            AS configuration_hash
    FROM policy_seed AS seed
),
policy_hashed AS
(
    SELECT
        policy.*,
        msbf_ctl.m2_5_hash_jsonb(to_jsonb(policy)) AS row_hash
    FROM policy_with_configuration_hash AS policy
)
INSERT INTO msbf_ctl.m2_5_policy_profile
(
    module1_run_id,
    policy_code,
    policy_version,
    policy_status,
    methodology_version,
    contract_code,
    contract_version,
    schema_version,
    source_m2_4_contract_code,
    source_m2_4_contract_version,
    source_m2_4_schema_version,
    source_m2_4_combined_hash,
    source_m2_4_acceptance_gate_id,
    source_m1_6_acceptance_gate_id,
    source_m1_6_combined_hash,
    monitoring_horizon_days,
    source_replay_days,
    watch_start_day,
    underperforming_start_day,
    severe_start_day,
    watch_pace_ratio,
    underperforming_pace_ratio,
    severe_pace_ratio,
    watch_daily_coverage_ratio,
    underperforming_no_remittance_days,
    dormant_no_remittance_days,
    severe_zero_sales_streak_days,
    low_liquidity_available_balance,
    retain_post_payoff_rows_flag,
    stress_status_nonimprovement_required_flag,
    synthetic_data_only_flag,
    no_real_debit_instruction_flag,
    no_external_notice_generation_flag,
    no_production_adverse_action_notice_flag,
    no_write_off_or_restructure_action_flag,
    monitoring_only_no_servicing_action_flag,
    expected_policy_rows,
    expected_status_rows,
    expected_alert_rows,
    expected_reason_rows,
    expected_source_rows,
    expected_daily_rows,
    expected_latest_rows,
    expected_archive_rows,
    expected_portfolio_daily_rows,
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
    policy.module1_run_id,
    policy.policy_code,
    policy.policy_version,
    policy.policy_status,
    policy.methodology_version,
    policy.contract_code,
    policy.contract_version,
    policy.schema_version,
    policy.source_m2_4_contract_code,
    policy.source_m2_4_contract_version,
    policy.source_m2_4_schema_version,
    policy.source_m2_4_combined_hash,
    policy.source_m2_4_acceptance_gate_id,
    policy.source_m1_6_acceptance_gate_id,
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
    policy.retain_post_payoff_rows_flag,
    policy.stress_status_nonimprovement_required_flag,
    policy.synthetic_data_only_flag,
    policy.no_real_debit_instruction_flag,
    policy.no_external_notice_generation_flag,
    policy.no_production_adverse_action_notice_flag,
    policy.no_write_off_or_restructure_action_flag,
    policy.monitoring_only_no_servicing_action_flag,
    policy.expected_policy_rows,
    policy.expected_status_rows,
    policy.expected_alert_rows,
    policy.expected_reason_rows,
    policy.expected_source_rows,
    policy.expected_daily_rows,
    policy.expected_latest_rows,
    policy.expected_archive_rows,
    policy.expected_portfolio_daily_rows,
    policy.expected_comparison_rows,
    policy.expected_registry_rows,
    policy.expected_canonical_entities,
    policy.expected_positive_controls,
    policy.expected_negative_controls,
    policy.expected_detail_result_sets,
    policy.configuration_payload,
    policy.configuration_hash,
    policy.row_hash
FROM policy_hashed AS policy
ON CONFLICT(module1_run_id)
DO NOTHING;

/* ============================================================================
Section 8 — Status, alert, and reason dictionary population
============================================================================ */

WITH run_context AS
(
    SELECT module1_run_id
    FROM msbf_ctl.m2_5_policy_profile
    WHERE policy_code = 'M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_POLICY_V1'
)
INSERT INTO msbf_m2.portfolio_monitoring_status_definition
(
    module1_run_id,
    monitoring_status_code,
    monitoring_status_rank,
    watch_flag,
    underperforming_flag,
    severe_shortfall_flag,
    dormant_flag,
    paid_off_flag,
    status_active_flag,
    description,
    row_hash
)
SELECT
    run_context.module1_run_id,
    source.monitoring_status_code,
    source.monitoring_status_rank,
    source.watch_flag,
    source.underperforming_flag,
    source.severe_shortfall_flag,
    source.dormant_flag,
    source.paid_off_flag,
    TRUE,
    source.description,
    msbf_ctl.m2_5_hash_jsonb
    (
        jsonb_build_object
        (
            'module1_run_id', run_context.module1_run_id,
            'monitoring_status_code', source.monitoring_status_code,
            'monitoring_status_rank', source.monitoring_status_rank,
            'watch_flag', source.watch_flag,
            'underperforming_flag', source.underperforming_flag,
            'severe_shortfall_flag', source.severe_shortfall_flag,
            'dormant_flag', source.dormant_flag,
            'paid_off_flag', source.paid_off_flag,
            'status_active_flag', TRUE,
            'description', source.description
        )
    )
FROM run_context
CROSS JOIN
(
    VALUES
        ('PAID_OFF', 0, FALSE, FALSE, FALSE, FALSE, TRUE, 'Receivable balance is fully remitted within the synthetic monitoring horizon.'),
        ('CURRENT', 1, FALSE, FALSE, FALSE, FALSE, FALSE, 'Cumulative remittance pace remains within the governed current band.'),
        ('WATCH', 2, TRUE, FALSE, FALSE, FALSE, FALSE, 'Early or moderate remittance, pace, or liquidity deterioration requires watch monitoring.'),
        ('UNDERPERFORMING', 3, TRUE, TRUE, FALSE, FALSE, FALSE, 'Material cumulative shortfall or remittance interruption requires elevated monitoring.'),
        ('SEVERE_SHORTFALL', 4, TRUE, TRUE, TRUE, FALSE, FALSE, 'Severe cumulative shortfall, extended zero-sales streak, or horizon overrun is present.'),
        ('DORMANT_NO_REMITTANCE', 5, TRUE, TRUE, TRUE, TRUE, FALSE, 'No positive remittance has been observed for the governed dormant interval.')
) AS source
(
    monitoring_status_code,
    monitoring_status_rank,
    watch_flag,
    underperforming_flag,
    severe_shortfall_flag,
    dormant_flag,
    paid_off_flag,
    description
)
ON CONFLICT(module1_run_id, monitoring_status_code)
DO NOTHING;

WITH run_context AS
(
    SELECT module1_run_id
    FROM msbf_ctl.m2_5_policy_profile
    WHERE policy_code = 'M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_POLICY_V1'
)
INSERT INTO msbf_m2.portfolio_monitoring_alert_definition
(
    module1_run_id,
    monitoring_alert_code,
    alert_rank,
    severity_code,
    alert_active_flag,
    description,
    row_hash
)
SELECT
    run_context.module1_run_id,
    source.monitoring_alert_code,
    source.alert_rank,
    source.severity_code,
    TRUE,
    source.description,
    msbf_ctl.m2_5_hash_jsonb
    (
        jsonb_build_object
        (
            'module1_run_id', run_context.module1_run_id,
            'monitoring_alert_code', source.monitoring_alert_code,
            'alert_rank', source.alert_rank,
            'severity_code', source.severity_code,
            'alert_active_flag', TRUE,
            'description', source.description
        )
    )
FROM run_context
CROSS JOIN
(
    VALUES
        ('DAILY_COLLECTION_SHORTFALL', 1, 'WATCH', 'Daily remittance is below the governed expected-due amount.'),
        ('CUMULATIVE_PACE_BELOW_90', 2, 'WATCH', 'Cumulative collection pace is below 90 percent of expected pace.'),
        ('CUMULATIVE_PACE_BELOW_75', 3, 'HIGH', 'Cumulative collection pace is below 75 percent of expected pace.'),
        ('ZERO_SALES_STREAK', 4, 'HIGH', 'Eligible POS sales are zero for the governed consecutive-day threshold.'),
        ('LIQUIDITY_STRESS', 5, 'HIGH', 'Negative available balance or NSF activity is observed in the accepted liquidity replay.'),
        ('CONTRACT_HORIZON_OVERRUN', 6, 'CRITICAL', 'Receivable remains outstanding after the contracted collection horizon.'),
        ('STRESS_STATUS_FLOOR', 7, 'GOVERNANCE', 'Stress monitoring status was floored to the matched baseline status to prevent favorable stress classification.')
) AS source
(
    monitoring_alert_code,
    alert_rank,
    severity_code,
    description
)
ON CONFLICT(module1_run_id, monitoring_alert_code)
DO NOTHING;

WITH run_context AS
(
    SELECT module1_run_id
    FROM msbf_ctl.m2_5_policy_profile
    WHERE policy_code = 'M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_POLICY_V1'
)
INSERT INTO msbf_m2.portfolio_monitoring_reason_definition
(
    module1_run_id,
    monitoring_reason_code,
    mapped_monitoring_status_code,
    production_adverse_action_notice_flag,
    servicing_action_authorized_flag,
    reason_active_flag,
    description,
    row_hash
)
SELECT
    run_context.module1_run_id,
    source.monitoring_reason_code,
    source.mapped_monitoring_status_code,
    FALSE,
    FALSE,
    TRUE,
    source.description,
    msbf_ctl.m2_5_hash_jsonb
    (
        jsonb_build_object
        (
            'module1_run_id', run_context.module1_run_id,
            'monitoring_reason_code', source.monitoring_reason_code,
            'mapped_monitoring_status_code', source.mapped_monitoring_status_code,
            'production_adverse_action_notice_flag', FALSE,
            'servicing_action_authorized_flag', FALSE,
            'reason_active_flag', TRUE,
            'description', source.description
        )
    )
FROM run_context
CROSS JOIN
(
    VALUES
        ('M2_5_STATUS_PAID_OFF', 'PAID_OFF', FALSE, 'Receivable balance reached zero.'),
        ('M2_5_STATUS_CURRENT', 'CURRENT', FALSE, 'Remittance pace and activity remain within current thresholds.'),
        ('M2_5_STATUS_WATCH', 'WATCH', FALSE, 'Watch-level remittance or liquidity deterioration is present.'),
        ('M2_5_STATUS_UNDERPERFORMING', 'UNDERPERFORMING', FALSE, 'Material cumulative underperformance is present.'),
        ('M2_5_STATUS_SEVERE_SHORTFALL', 'SEVERE_SHORTFALL', FALSE, 'Severe shortfall, zero-sales streak, or horizon overrun is present.'),
        ('M2_5_STATUS_DORMANT_NO_REMITTANCE', 'DORMANT_NO_REMITTANCE', FALSE, 'No positive remittance has been observed for the dormant threshold.'),
        ('M2_5_DAILY_COLLECTION_SHORTFALL', 'WATCH', FALSE, 'Daily remittance is below expected due.'),
        ('M2_5_CUMULATIVE_PACE_BELOW_90', 'WATCH', FALSE, 'Cumulative pace is below 90 percent.'),
        ('M2_5_CUMULATIVE_PACE_BELOW_75', 'UNDERPERFORMING', FALSE, 'Cumulative pace is below 75 percent.'),
        ('M2_5_CUMULATIVE_PACE_BELOW_50', 'SEVERE_SHORTFALL', FALSE, 'Cumulative pace is below 50 percent.'),
        ('M2_5_ZERO_SALES_STREAK', 'SEVERE_SHORTFALL', FALSE, 'Consecutive zero-sales threshold is reached.'),
        ('M2_5_LIQUIDITY_STRESS', 'WATCH', FALSE, 'Accepted liquidity replay indicates negative balance or NSF activity.'),
        ('M2_5_HORIZON_OVERRUN', 'SEVERE_SHORTFALL', FALSE, 'Outstanding receivable remains after the contracted horizon.'),
        ('M2_5_STRESS_STATUS_FLOOR', 'WATCH', FALSE, 'Stress status was floored to the matched baseline status.'),
        ('M2_5_SOURCE_M2_4_ACCEPTED', 'CURRENT', FALSE, 'Accepted M2.4 portfolio activation contract is the source.'),
        ('M2_5_SOURCE_M1_6_ACCEPTED', 'CURRENT', FALSE, 'Accepted M1.6 matched daily scenario history is the replay source.'),
        ('M2_5_SOURCE_REPLAY_COMPLETE', 'CURRENT', FALSE, 'One hundred twenty accepted source days were replayed.'),
        ('M2_5_DAILY_HASH_RECONCILED', 'CURRENT', FALSE, 'Daily monitoring physical row hash reconciles.'),
        ('M2_5_ARCHIVE_REPRODUCED', 'CURRENT', FALSE, 'Latest and immutable archive contracts reproduce exactly.'),
        ('M2_5_PORTFOLIO_SUMMARY_RECONCILED', 'CURRENT', FALSE, 'Portfolio daily aggregation reconciles to the daily ledger.'),
        ('M2_5_MONITORING_ONLY', 'CURRENT', FALSE, 'M2.5 records monitoring evidence and does not issue servicing actions.'),
        ('M2_5_NO_REAL_DEBIT_INSTRUCTION', 'CURRENT', FALSE, 'No real debit or payment-network instruction is produced.'),
        ('M2_5_NO_EXTERNAL_NOTICE', 'CURRENT', FALSE, 'No external notice or production adverse-action notice is produced.'),
        ('M2_5_FALLBACK_MONITORING_GUARD', 'DORMANT_NO_REMITTANCE', FALSE, 'Unexpected monitoring state fails closed to the most conservative internal status.')
) AS source
(
    monitoring_reason_code,
    mapped_monitoring_status_code,
    production_adverse_action_notice_flag,
    description
)
ON CONFLICT(module1_run_id, monitoring_reason_code)
DO NOTHING;

/* ============================================================================
Section 9 — Consumption, comparison, lineage, Power BI, and canonical views
============================================================================ */

CREATE OR REPLACE VIEW msbf_m2.v_m2_5_portfolio_monitoring_latest
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
    latest.created_at,
    status.description AS monitoring_status_description,
    reason.description AS primary_reason_description
FROM msbf_m2.advance_portfolio_monitoring_latest AS latest
JOIN msbf_m2.portfolio_monitoring_status_definition AS status
  ON status.module1_run_id = latest.module1_run_id
 AND status.monitoring_status_code = latest.latest_monitoring_status_code
JOIN msbf_m2.portfolio_monitoring_reason_definition AS reason
  ON reason.module1_run_id = latest.module1_run_id
 AND reason.monitoring_reason_code = latest.primary_monitoring_reason_code;

CREATE OR REPLACE VIEW msbf_m2.v_m2_5_matched_monitoring_comparison
AS
SELECT
    baseline.module1_run_id,
    baseline.merchant_application_id,
    baseline.synthetic_advance_id AS baseline_synthetic_advance_id,
    stress.synthetic_advance_id AS stress_synthetic_advance_id,
    baseline.latest_monitoring_status_code AS baseline_monitoring_status_code,
    stress.latest_monitoring_status_code AS stress_monitoring_status_code,
    baseline.latest_monitoring_status_rank AS baseline_monitoring_status_rank,
    stress.latest_monitoring_status_rank AS stress_monitoring_status_rank,
    baseline.paid_off_flag AS baseline_paid_off_flag,
    stress.paid_off_flag AS stress_paid_off_flag,
    baseline.cumulative_remittance_amount AS baseline_cumulative_remittance_amount,
    stress.cumulative_remittance_amount AS stress_cumulative_remittance_amount,
    baseline.remaining_receivable_amount AS baseline_remaining_receivable_amount,
    stress.remaining_receivable_amount AS stress_remaining_receivable_amount,
    baseline.cumulative_pace_ratio AS baseline_cumulative_pace_ratio,
    stress.cumulative_pace_ratio AS stress_cumulative_pace_ratio,
    baseline.stress_status_floor_applied_flag AS baseline_floor_flag,
    stress.stress_status_floor_applied_flag AS stress_floor_flag,
    (
        NOT stress.paid_off_flag
        AND NOT baseline.paid_off_flag
        AND stress.latest_monitoring_status_rank <
            baseline.latest_monitoring_status_rank
    ) AS stress_status_improvement_flag
FROM msbf_m2.advance_portfolio_monitoring_latest AS baseline
JOIN msbf_m2.advance_portfolio_monitoring_latest AS stress
  ON stress.module1_run_id = baseline.module1_run_id
 AND stress.merchant_application_id = baseline.merchant_application_id
 AND stress.scenario_code = 'RECESSION_ENERGY'
WHERE baseline.scenario_code = 'BASELINE';

CREATE OR REPLACE VIEW msbf_m2.v_m2_5_power_bi_daily_monitoring
AS
SELECT
    daily.module1_run_id,
    daily.scenario_code,
    daily.merchant_application_id,
    daily.synthetic_advance_id,
    daily.monitoring_day_index,
    daily.monitoring_date,
    daily.source_eligible_pos_sales,
    daily.actual_remittance_amount,
    daily.cumulative_remittance_amount,
    daily.receivable_balance_after,
    daily.principal_exposure_proxy,
    daily.cumulative_shortfall_amount,
    daily.cumulative_pace_ratio,
    daily.monitoring_status_code,
    daily.stress_status_floor_applied_flag,
    daily.daily_shortfall_alert_flag,
    daily.cumulative_pace_watch_alert_flag,
    daily.cumulative_pace_high_alert_flag,
    daily.zero_sales_streak_alert_flag,
    daily.liquidity_stress_alert_flag,
    daily.horizon_overrun_alert_flag,
    daily.paid_off_flag
FROM msbf_m2.advance_daily_remittance_monitoring AS daily;

CREATE OR REPLACE VIEW msbf_m2.v_m2_5_power_bi_portfolio_summary
AS
SELECT
    summary.module1_run_id,
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
    summary.stress_status_floor_rows
FROM msbf_m2.portfolio_daily_monitoring_summary AS summary;

CREATE OR REPLACE VIEW msbf_m2.v_m2_5_monitoring_lineage
AS
SELECT
    latest.module1_run_id,
    latest.scenario_id,
    latest.scenario_code,
    latest.merchant_application_id,
    latest.synthetic_account_id,
    latest.synthetic_advance_id,
    latest.contract_code,
    latest.contract_version,
    latest.schema_version,
    latest.latest_monitoring_status_code,
    latest.source_daily_row_hash,
    latest.source_m2_4_contract_row_hash,
    latest.source_advance_row_hash,
    latest.source_portfolio_row_hash,
    latest.contract_row_hash
FROM msbf_m2.advance_portfolio_monitoring_latest AS latest;

CREATE OR REPLACE VIEW msbf_m2.v_m2_5_canonical_entity
AS
SELECT
    policy.module1_run_id,
    'POLICY'::text AS entity_type,
    policy.policy_code || '|v' || policy.policy_version::text AS entity_key,
    policy.row_hash
FROM msbf_ctl.m2_5_policy_profile AS policy

UNION ALL

SELECT
    status.module1_run_id,
    'STATUS',
    status.monitoring_status_code,
    status.row_hash
FROM msbf_m2.portfolio_monitoring_status_definition AS status

UNION ALL

SELECT
    alert.module1_run_id,
    'ALERT',
    alert.monitoring_alert_code,
    alert.row_hash
FROM msbf_m2.portfolio_monitoring_alert_definition AS alert

UNION ALL

SELECT
    reason.module1_run_id,
    'REASON',
    reason.monitoring_reason_code,
    reason.row_hash
FROM msbf_m2.portfolio_monitoring_reason_definition AS reason

UNION ALL

SELECT
    source.module1_run_id,
    'SOURCE',
    source.scenario_id::text || '|' || source.merchant_application_id,
    source.row_hash
FROM msbf_m2.advance_monitoring_source_snapshot AS source

UNION ALL

SELECT
    daily.module1_run_id,
    'DAILY',
    daily.scenario_id::text || '|' || daily.merchant_application_id || '|' || daily.monitoring_day_index::text,
    daily.row_hash
FROM msbf_m2.advance_daily_remittance_monitoring AS daily

UNION ALL

SELECT
    latest.module1_run_id,
    'LATEST',
    latest.scenario_id::text || '|' || latest.merchant_application_id,
    latest.contract_row_hash
FROM msbf_m2.advance_portfolio_monitoring_latest AS latest

UNION ALL

SELECT
    archive.module1_run_id,
    'ARCHIVE',
    archive.scenario_id::text || '|' || archive.merchant_application_id,
    archive.archive_row_hash
FROM msbf_m2.advance_portfolio_monitoring_archive AS archive

UNION ALL

SELECT
    summary.module1_run_id,
    'PORTFOLIO_DAILY',
    summary.scenario_id::text || '|' || summary.monitoring_day_index::text,
    summary.row_hash
FROM msbf_m2.portfolio_daily_monitoring_summary AS summary

UNION ALL

SELECT
    registry.module1_run_id,
    'REGISTRY',
    registry.contract_code || '|v' || registry.contract_version::text,
    registry.row_hash
FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS registry;

CREATE OR REPLACE VIEW msbf_m2.v_m2_5_canonical_hash
AS
SELECT
    canonical.module1_run_id,
    count(*)::bigint AS canonical_entities,
    md5
    (
        string_agg
        (
            canonical.entity_type || '|' ||
            canonical.entity_key || '|' ||
            canonical.row_hash,
            '|' ORDER BY
                canonical.entity_type,
                canonical.entity_key
        )
    ) AS combined_set_hash
FROM msbf_m2.v_m2_5_canonical_entity AS canonical
GROUP BY canonical.module1_run_id;

/* ============================================================================
Section 10 — Schema and policy checkpoint
============================================================================ */

DO $m2_5_schema_guard$
DECLARE
    v_run_id bigint;
    v_gate_catalog_rows bigint;
    v_policy_rows bigint;
    v_status_rows bigint;
    v_alert_rows bigint;
    v_reason_rows bigint;
BEGIN
    SELECT policy.module1_run_id
    INTO v_run_id
    FROM msbf_ctl.m2_5_policy_profile AS policy
    WHERE policy.policy_code = 'M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_POLICY_V1';

    PERFORM msbf_ctl.m2_5_assert_configuration(v_run_id);

    SELECT count(*)
    INTO v_gate_catalog_rows
    FROM msbf_ref.acceptance_gate_catalog
    WHERE gate_id = 'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
      AND active_flag;

    SELECT count(*)
    INTO v_policy_rows
    FROM msbf_ctl.m2_5_policy_profile
    WHERE module1_run_id = v_run_id;

    SELECT count(*)
    INTO v_status_rows
    FROM msbf_m2.portfolio_monitoring_status_definition
    WHERE module1_run_id = v_run_id
      AND status_active_flag;

    SELECT count(*)
    INTO v_alert_rows
    FROM msbf_m2.portfolio_monitoring_alert_definition
    WHERE module1_run_id = v_run_id
      AND alert_active_flag;

    SELECT count(*)
    INTO v_reason_rows
    FROM msbf_m2.portfolio_monitoring_reason_definition
    WHERE module1_run_id = v_run_id
      AND reason_active_flag;

    IF v_gate_catalog_rows <> 1
       OR v_policy_rows <> 1
       OR v_status_rows <> 6
       OR v_alert_rows <> 7
       OR v_reason_rows <> 24 THEN
        RAISE EXCEPTION
            'M2.5 schema/policy extension failed: gate %, policy %, status %, alert %, reason %.',
            v_gate_catalog_rows,
            v_policy_rows,
            v_status_rows,
            v_alert_rows,
            v_reason_rows;
    END IF;
END;
$m2_5_schema_guard$;

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
    policy.source_m2_4_contract_code,
    policy.source_m2_4_contract_version,
    policy.source_m2_4_schema_version,
    policy.source_m2_4_combined_hash,
    policy.source_m1_6_acceptance_gate_id,
    policy.source_m1_6_combined_hash,
    policy.configuration_hash,
    policy.monitoring_horizon_days,
    policy.source_replay_days,

    (
        SELECT count(*)
        FROM msbf_ref.acceptance_gate_catalog AS gate
        WHERE gate.gate_id = 'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
          AND gate.active_flag
    ) AS acceptance_gate_catalog_rows,

    (
        SELECT count(*)
        FROM msbf_m2.portfolio_monitoring_status_definition AS status
        WHERE status.module1_run_id = policy.module1_run_id
    ) AS status_definition_rows,

    (
        SELECT count(*)
        FROM msbf_m2.portfolio_monitoring_alert_definition AS alert
        WHERE alert.module1_run_id = policy.module1_run_id
    ) AS alert_definition_rows,

    (
        SELECT count(*)
        FROM msbf_m2.portfolio_monitoring_reason_definition AS reason
        WHERE reason.module1_run_id = policy.module1_run_id
    ) AS reason_definition_rows,

    CASE
        WHEN policy.policy_status = 'APPROVED'
         AND policy.monitoring_horizon_days = 120
         AND policy.source_replay_days = 120
         AND policy.retain_post_payoff_rows_flag
         AND policy.stress_status_nonimprovement_required_flag
         AND policy.synthetic_data_only_flag
         AND policy.no_real_debit_instruction_flag
         AND policy.no_external_notice_generation_flag
         AND policy.no_production_adverse_action_notice_flag
         AND policy.no_write_off_or_restructure_action_flag
         AND policy.monitoring_only_no_servicing_action_flag
        THEN 'PASS'
        ELSE 'FAIL'
    END AS schema_policy_status

FROM msbf_ctl.m2_5_policy_profile AS policy
WHERE policy.policy_code = 'M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_POLICY_V1';
