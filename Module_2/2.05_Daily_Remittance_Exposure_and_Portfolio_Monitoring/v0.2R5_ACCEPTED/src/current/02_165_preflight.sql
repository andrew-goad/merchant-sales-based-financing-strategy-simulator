/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 165_msbf_m2_5_preflight_validation_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Fail closed unless the accepted M2.4 activation contract, accepted M1.6 daily
scenario history, M2.5 policy and dictionaries, replay-day availability,
empty M2.5 targets, and monitoring-only stage boundaries are ready.

Performance
-----------
The 59 active M2.4 source rows and replay-day availability are materialized
once into indexed session-temporary tables. No upstream blueprint is rebuilt.

Writes
------
Session-temporary preflight objects only.

Required result
---------------
preflight_status = PASS.

Revision v0.2R1
----------------
Corrects a CREATE TABLE AS projection collision in `_m2_5_preflight`.
Policy-source identity fields and observed source-registry identity fields now
use distinct output aliases. No preflight rule, expected count, methodology,
source contract, hash, stage boundary or downstream program changes.
============================================================================ */

SET statement_timeout = '30min';
SET jit = off;

DROP TABLE IF EXISTS _m2_5_preflight_active_source;

CREATE TEMP TABLE _m2_5_preflight_active_source
ON COMMIT PRESERVE ROWS
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
    advance.first_expected_remittance_date,
    advance.funded_amount,
    advance.total_repayment_amount,
    advance.finance_charge_amount,
    advance.remittance_rate,
    advance.collection_horizon_days,
    advance.implied_daily_collection_amount,
    portfolio.portfolio_activation_date,
    portfolio.monitoring_start_date,
    portfolio.initial_exposure_amount,
    latest.contract_row_hash AS source_m2_4_contract_row_hash,
    advance.row_hash AS source_advance_row_hash,
    portfolio.row_hash AS source_portfolio_row_hash
FROM msbf_m2.application_booking_funding_activation_latest AS latest
JOIN msbf_m2.synthetic_advance_funding AS advance
  ON advance.module1_run_id = latest.module1_run_id
 AND advance.scenario_id = latest.scenario_id
 AND advance.merchant_application_id = latest.merchant_application_id
JOIN msbf_m2.initial_portfolio_activation AS portfolio
  ON portfolio.module1_run_id = latest.module1_run_id
 AND portfolio.scenario_id = latest.scenario_id
 AND portfolio.merchant_application_id = latest.merchant_application_id
WHERE latest.module1_run_id =
      (
          SELECT run_id
          FROM msbf_ctl.run_registry
          WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
            AND run_version = 1
      )
  AND latest.portfolio_activated_flag
  AND latest.activation_outcome_code =
      'BOOKED_FUNDED_PORTFOLIO_ACTIVATED';

CREATE UNIQUE INDEX
ON _m2_5_preflight_active_source
(
    module1_run_id,
    scenario_id,
    merchant_application_id
);

CREATE UNIQUE INDEX
ON _m2_5_preflight_active_source
(
    module1_run_id,
    synthetic_advance_id
);

ANALYZE _m2_5_preflight_active_source;

DROP TABLE IF EXISTS _m2_5_preflight_replay_availability;

CREATE TEMP TABLE _m2_5_preflight_replay_availability
ON COMMIT PRESERVE ROWS
AS
WITH pos_days AS
(
    SELECT
        source.module1_run_id,
        source.scenario_id,
        source.merchant_application_id,
        count(DISTINCT pos.observation_date)::bigint AS available_pos_days
    FROM _m2_5_preflight_active_source AS source
    JOIN msbf_m1.merchant_pos_daily_scenario AS pos
      ON pos.scenario_id = source.scenario_id
     AND pos.population_id = source.population_id
     AND pos.merchant_id = source.merchant_id
     AND pos.observation_date <= source.as_of_date
    GROUP BY
        source.module1_run_id,
        source.scenario_id,
        source.merchant_application_id
),
deposit_days AS
(
    SELECT
        source.module1_run_id,
        source.scenario_id,
        source.merchant_application_id,
        count(DISTINCT deposit.observation_date)::bigint AS available_deposit_days
    FROM _m2_5_preflight_active_source AS source
    JOIN msbf_m1.merchant_deposit_daily_scenario AS deposit
      ON deposit.scenario_id = source.scenario_id
     AND deposit.population_id = source.population_id
     AND deposit.merchant_id = source.merchant_id
     AND deposit.observation_date <= source.as_of_date
    GROUP BY
        source.module1_run_id,
        source.scenario_id,
        source.merchant_application_id
)
SELECT
    source.module1_run_id,
    source.scenario_id,
    source.merchant_application_id,
    coalesce(pos.available_pos_days, 0)::bigint AS available_pos_days,
    coalesce(deposit.available_deposit_days, 0)::bigint AS available_deposit_days
FROM _m2_5_preflight_active_source AS source
LEFT JOIN pos_days AS pos
  ON pos.module1_run_id = source.module1_run_id
 AND pos.scenario_id = source.scenario_id
 AND pos.merchant_application_id = source.merchant_application_id
LEFT JOIN deposit_days AS deposit
  ON deposit.module1_run_id = source.module1_run_id
 AND deposit.scenario_id = source.scenario_id
 AND deposit.merchant_application_id = source.merchant_application_id;

CREATE UNIQUE INDEX
ON _m2_5_preflight_replay_availability
(
    module1_run_id,
    scenario_id,
    merchant_application_id
);

ANALYZE _m2_5_preflight_replay_availability;

DROP TABLE IF EXISTS _m2_5_preflight;

CREATE TEMP TABLE _m2_5_preflight
ON COMMIT PRESERVE ROWS
AS
WITH run_context AS
(
    SELECT
        run_id,
        run_status,
        population_id,
        as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
policy AS
(
    SELECT
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
        retain_post_payoff_rows_flag,
        stress_status_nonimprovement_required_flag,
        synthetic_data_only_flag,
        no_real_debit_instruction_flag,
        no_external_notice_generation_flag,
        no_production_adverse_action_notice_flag,
        no_write_off_or_restructure_action_flag,
        monitoring_only_no_servicing_action_flag,
        configuration_hash
    FROM msbf_ctl.m2_5_policy_profile
    WHERE module1_run_id = (SELECT run_id FROM run_context)
      AND policy_code = 'M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_POLICY_V1'
),
source_m2_4 AS
(
    SELECT
        count(*)::bigint AS registry_rows,
        max(contract_status) AS contract_status,
        max(contract_code) AS contract_code,
        max(contract_version) AS contract_version,
        max(schema_version) AS schema_version,
        max(combined_set_hash) AS combined_set_hash,
        max(account_rows) AS account_rows,
        max(advance_rows) AS advance_rows,
        max(portfolio_rows) AS portfolio_rows
    FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
source_gates AS
(
    SELECT
        count(*) FILTER
        (
            WHERE gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
              AND result_status = 'PASS'
        )::bigint AS m2_4_gate_rows,
        count(*) FILTER
        (
            WHERE gate_id = 'M1_6_MATCHED_SCENARIO_OVERLAYS'
              AND result_status = 'PASS'
        )::bigint AS m1_6_gate_rows
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id = (SELECT run_id FROM run_context)
),
source_m1_6 AS
(
    SELECT
        count(*) FILTER
        (
            WHERE evidence_code = 'M1_6_COMBINED_SET_HASH'
              AND segment_key = 'PORTFOLIO'
              AND status = 'PASS'
        )::bigint AS evidence_rows,
        max(metric_value_text) FILTER
        (
            WHERE evidence_code = 'M1_6_COMBINED_SET_HASH'
              AND segment_key = 'PORTFOLIO'
              AND status = 'PASS'
        ) AS combined_set_hash,
        (
            SELECT count(*)
            FROM msbf_m1.merchant_pos_daily_scenario
            WHERE generated_by_run_id = (SELECT run_id FROM run_context)
        )::bigint AS pos_rows,
        (
            SELECT count(*)
            FROM msbf_m1.merchant_deposit_daily_scenario
            WHERE generated_by_run_id = (SELECT run_id FROM run_context)
        )::bigint AS deposit_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM run_context)
),
source_active AS
(
    SELECT
        count(*)::bigint AS source_rows,
        count(*) FILTER
        (
            WHERE scenario_code = 'BASELINE'
        )::bigint AS baseline_rows,
        count(*) FILTER
        (
            WHERE scenario_code = 'RECESSION_ENERGY'
        )::bigint AS stress_rows,
        count(DISTINCT merchant_application_id)::bigint AS applications,
        count(DISTINCT synthetic_account_id)::bigint AS account_ids,
        count(DISTINCT synthetic_advance_id)::bigint AS advance_ids,
        count(*) FILTER
        (
            WHERE funded_amount <= 0
               OR total_repayment_amount < funded_amount
               OR initial_exposure_amount IS DISTINCT FROM funded_amount
               OR remittance_rate NOT BETWEEN 0.05 AND 0.20
               OR collection_horizon_days NOT BETWEEN 1 AND 120
               OR implied_daily_collection_amount <= 0
        )::bigint AS invalid_source_rows
    FROM _m2_5_preflight_active_source
),
replay AS
(
    SELECT
        count(*)::bigint AS replay_source_rows,
        min(available_pos_days)::bigint AS minimum_pos_days,
        max(available_pos_days)::bigint AS maximum_pos_days,
        min(available_deposit_days)::bigint AS minimum_deposit_days,
        max(available_deposit_days)::bigint AS maximum_deposit_days,
        count(*) FILTER
        (
            WHERE available_pos_days < 120
               OR available_deposit_days < 120
        )::bigint AS insufficient_replay_rows
    FROM _m2_5_preflight_replay_availability
),
definitions AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_monitoring_status_definition
            WHERE module1_run_id = (SELECT run_id FROM run_context)
              AND status_active_flag
        )::bigint AS status_rows,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_monitoring_alert_definition
            WHERE module1_run_id = (SELECT run_id FROM run_context)
              AND alert_active_flag
        )::bigint AS alert_rows,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_monitoring_reason_definition
            WHERE module1_run_id = (SELECT run_id FROM run_context)
              AND reason_active_flag
        )::bigint AS reason_rows,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_monitoring_reason_definition
            WHERE module1_run_id = (SELECT run_id FROM run_context)
              AND
              (
                  production_adverse_action_notice_flag
                  OR servicing_action_authorized_flag
              )
        )::bigint AS prohibited_reason_flags
),
gate_catalog AS
(
    SELECT count(*)::bigint AS gate_catalog_rows
    FROM msbf_ref.acceptance_gate_catalog
    WHERE gate_id = 'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
      AND active_flag
),
targets AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.advance_monitoring_source_snapshot
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS source_rows,
        (
            SELECT count(*)
            FROM msbf_m2.advance_daily_remittance_monitoring
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS daily_rows,
        (
            SELECT count(*)
            FROM msbf_m2.advance_portfolio_monitoring_latest
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS latest_rows,
        (
            SELECT count(*)
            FROM msbf_m2.advance_portfolio_monitoring_archive
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS archive_rows,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_daily_monitoring_summary
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS portfolio_rows,
        (
            SELECT count(*)
            FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS registry_rows,
        (
            SELECT count(*)
            FROM msbf_ctl.run_evidence
            WHERE run_id = (SELECT run_id FROM run_context)
              AND evidence_code LIKE 'M2_5_%'
        )::bigint AS evidence_rows,
        (
            SELECT count(*)
            FROM msbf_ctl.acceptance_gate_result
            WHERE run_id = (SELECT run_id FROM run_context)
              AND gate_id = 'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
        )::bigint AS acceptance_rows,
        (
            SELECT count(*)
            FROM information_schema.tables
            WHERE table_schema IN ('msbf_ctl','msbf_m2')
              AND lower(table_name) LIKE 'm2_6%'
        )::bigint AS m2_6_tables,
        (
            SELECT count(*)
            FROM information_schema.columns
            WHERE table_schema = 'msbf_m2'
              AND table_name IN
              (
                  'advance_daily_remittance_monitoring',
                  'advance_portfolio_monitoring_latest',
                  'advance_portfolio_monitoring_archive',
                  'portfolio_daily_monitoring_summary'
              )
              AND lower(column_name) IN
              (
                  'debit_instruction',
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
                  'external_notice_payload',
                  'production_adverse_action_notice'
              )
        )::bigint AS prohibited_columns
)
SELECT
    run_context.run_id,
    run_context.run_status,
    run_context.population_id,
    run_context.as_of_date,
    policy.policy_status,
    policy.methodology_version,
    policy.contract_code,
    policy.contract_version,
    policy.schema_version,
    policy.source_m2_4_contract_code AS policy_source_m2_4_contract_code,
    policy.source_m2_4_contract_version AS policy_source_m2_4_contract_version,
    policy.source_m2_4_schema_version AS policy_source_m2_4_schema_version,
    policy.source_m2_4_combined_hash AS policy_source_m2_4_combined_hash,
    policy.source_m1_6_acceptance_gate_id,
    policy.source_m1_6_combined_hash AS policy_source_m1_6_combined_hash,
    policy.monitoring_horizon_days,
    policy.source_replay_days,
    policy.configuration_hash,
    source_m2_4.registry_rows AS source_m2_4_registry_rows,
    source_m2_4.contract_status AS source_m2_4_contract_status,
    source_m2_4.contract_code AS source_m2_4_contract_code,
    source_m2_4.contract_version AS source_m2_4_contract_version,
    source_m2_4.schema_version AS source_m2_4_schema_version,
    source_m2_4.combined_set_hash AS source_m2_4_combined_hash,
    source_m2_4.account_rows AS source_m2_4_account_rows,
    source_m2_4.advance_rows AS source_m2_4_advance_rows,
    source_m2_4.portfolio_rows AS source_m2_4_portfolio_rows,
    source_gates.m2_4_gate_rows,
    source_gates.m1_6_gate_rows,
    source_m1_6.evidence_rows AS source_m1_6_evidence_rows,
    source_m1_6.combined_set_hash AS source_m1_6_combined_hash,
    source_m1_6.pos_rows AS source_m1_6_pos_rows,
    source_m1_6.deposit_rows AS source_m1_6_deposit_rows,
    source_active.source_rows,
    source_active.baseline_rows,
    source_active.stress_rows,
    source_active.applications,
    source_active.account_ids,
    source_active.advance_ids,
    source_active.invalid_source_rows,
    replay.replay_source_rows,
    replay.minimum_pos_days,
    replay.maximum_pos_days,
    replay.minimum_deposit_days,
    replay.maximum_deposit_days,
    replay.insufficient_replay_rows,
    definitions.status_rows,
    definitions.alert_rows,
    definitions.reason_rows,
    definitions.prohibited_reason_flags,
    gate_catalog.gate_catalog_rows,
    targets.source_rows AS target_source_rows,
    targets.daily_rows AS target_daily_rows,
    targets.latest_rows AS target_latest_rows,
    targets.archive_rows AS target_archive_rows,
    targets.portfolio_rows AS target_portfolio_rows,
    targets.registry_rows AS target_registry_rows,
    targets.evidence_rows AS target_evidence_rows,
    targets.acceptance_rows AS target_acceptance_rows,
    targets.m2_6_tables,
    targets.prohibited_columns,

    CASE
        WHEN run_context.run_status = 'M2_4_ACCEPTED'
         AND policy.policy_status = 'APPROVED'
         AND policy.methodology_version = 'M2_5_METHOD_V1'
         AND policy.contract_code = 'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'
         AND policy.contract_version = 1
         AND policy.schema_version = 'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1'
         AND policy.source_m2_4_contract_code = 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
         AND policy.source_m2_4_contract_version = 1
         AND policy.source_m2_4_schema_version = 'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
         AND policy.source_m2_4_combined_hash = '117450a3eea7bb3d3c74d18cc3c8e96a'
         AND policy.source_m1_6_acceptance_gate_id = 'M1_6_MATCHED_SCENARIO_OVERLAYS'
         AND policy.source_m1_6_combined_hash IS NOT DISTINCT FROM source_m1_6.combined_set_hash
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
         AND length(policy.configuration_hash) = 32
         AND policy.configuration_hash ~ '^[0-9a-f]+$'

         AND source_m2_4.registry_rows = 1
         AND source_m2_4.contract_status = 'ACCEPTED'
         AND source_m2_4.contract_code = 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
         AND source_m2_4.contract_version = 1
         AND source_m2_4.schema_version = 'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
         AND source_m2_4.combined_set_hash = '117450a3eea7bb3d3c74d18cc3c8e96a'
         AND source_m2_4.account_rows = 59
         AND source_m2_4.advance_rows = 59
         AND source_m2_4.portfolio_rows = 59
         AND source_gates.m2_4_gate_rows = 1

         AND source_gates.m1_6_gate_rows = 1
         AND source_m1_6.evidence_rows = 1
         AND length(source_m1_6.combined_set_hash) = 32
         AND source_m1_6.combined_set_hash ~ '^[0-9a-f]+$'
         AND source_m1_6.pos_rows = 270000
         AND source_m1_6.deposit_rows = 270000

         AND source_active.source_rows = 59
         AND source_active.baseline_rows = 44
         AND source_active.stress_rows = 15
         AND source_active.applications = 44
         AND source_active.account_ids = 59
         AND source_active.advance_ids = 59
         AND source_active.invalid_source_rows = 0

         AND replay.replay_source_rows = 59
         AND replay.minimum_pos_days >= 120
         AND replay.minimum_deposit_days >= 120
         AND replay.insufficient_replay_rows = 0

         AND definitions.status_rows = 6
         AND definitions.alert_rows = 7
         AND definitions.reason_rows = 24
         AND definitions.prohibited_reason_flags = 0
         AND gate_catalog.gate_catalog_rows = 1

         AND targets.source_rows = 0
         AND targets.daily_rows = 0
         AND targets.latest_rows = 0
         AND targets.archive_rows = 0
         AND targets.portfolio_rows = 0
         AND targets.registry_rows = 0
         AND targets.evidence_rows = 0
         AND targets.acceptance_rows = 0
         AND targets.m2_6_tables = 0
         AND targets.prohibited_columns = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS preflight_status

FROM run_context
CROSS JOIN policy
CROSS JOIN source_m2_4
CROSS JOIN source_gates
CROSS JOIN source_m1_6
CROSS JOIN source_active
CROSS JOIN replay
CROSS JOIN definitions
CROSS JOIN gate_catalog
CROSS JOIN targets;

DO $m2_5_preflight_guard$
DECLARE
    v record;
BEGIN
    SELECT
        preflight.run_id,
        preflight.preflight_status
    INTO v
    FROM _m2_5_preflight AS preflight;

    IF v.preflight_status <> 'PASS' THEN
        RAISE EXCEPTION
            'M2.5 preflight failed for run_id %.',
            v.run_id;
    END IF;

    PERFORM msbf_ctl.m2_5_assert_generation_ready(v.run_id);
END;
$m2_5_preflight_guard$;

SELECT
    preflight.run_id,
    preflight.run_status,
    preflight.population_id,
    preflight.as_of_date,
    preflight.policy_status,
    preflight.methodology_version,
    preflight.contract_code,
    preflight.contract_version,
    preflight.schema_version,
    preflight.source_m2_4_contract_status,
    preflight.source_m2_4_contract_code,
    preflight.source_m2_4_contract_version,
    preflight.source_m2_4_schema_version,
    preflight.source_m2_4_combined_hash,
    preflight.source_m1_6_combined_hash,
    preflight.source_m1_6_pos_rows,
    preflight.source_m1_6_deposit_rows,
    preflight.source_rows,
    preflight.baseline_rows,
    preflight.stress_rows,
    preflight.applications,
    preflight.minimum_pos_days,
    preflight.minimum_deposit_days,
    preflight.status_rows,
    preflight.alert_rows,
    preflight.reason_rows,
    preflight.gate_catalog_rows,
    preflight.target_source_rows,
    preflight.target_daily_rows,
    preflight.target_latest_rows,
    preflight.target_archive_rows,
    preflight.target_portfolio_rows,
    preflight.target_registry_rows,
    preflight.target_evidence_rows,
    preflight.target_acceptance_rows,
    preflight.m2_6_tables,
    preflight.prohibited_columns,
    preflight.preflight_status
FROM _m2_5_preflight AS preflight;
