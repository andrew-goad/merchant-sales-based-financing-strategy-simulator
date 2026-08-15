/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.7 — Operational Activation & Account Setup
============================================================================ */

/* ============================================================================
Program     : 181_msbf_m2_7_preflight_validation_v0_2.sql
Version     : v0.2

Purpose
-------
Fail closed unless accepted M2.6 lifecycle, contract, schema, gate, combined
hash, source grain, M2.7 policy, dictionaries, empty targets, and prohibited
object/column boundaries are exact.

Writes
------
None.

Required result
---------------
preflight_status = PASS.
============================================================================ */

SET statement_timeout='30min';
SET jit=off;

DROP TABLE IF EXISTS _m2_7_preflight;

CREATE TEMP TABLE _m2_7_preflight
ON COMMIT PRESERVE ROWS
AS
WITH run_context AS
(
    SELECT run_id,run_status,population_id,as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
),
policy AS
(
    SELECT *
    FROM msbf_ctl.m2_7_policy_profile
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
source_registry AS
(
    SELECT
        count(*)::bigint AS registry_rows,
        max(contract_status) AS contract_status,
        max(contract_code) AS contract_code,
        max(contract_version) AS contract_version,
        max(schema_version) AS schema_version,
        max(combined_set_hash) AS combined_set_hash,
        max(latest_rows)::bigint AS latest_rows,
        max(archive_rows)::bigint AS archive_rows,
        max(comparison_rows)::bigint AS comparison_rows,
        max(canonical_entities)::bigint AS canonical_entities,
        max(closed_no_action_rows)::bigint AS closed_no_action_rows,
        max(outreach_review_rows)::bigint AS outreach_review_rows,
        max(temporary_adjustment_review_rows)::bigint
            AS temporary_adjustment_review_rows,
        max(recommended_action_exposure_amount)::numeric(18,2)
            AS recommended_action_exposure_amount
    FROM msbf_ctl.m2_6_intervention_strategy_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
source_gate AS
(
    SELECT
        count(*)::bigint AS gate_rows,
        max(result_status) AS gate_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM run_context)
      AND gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'
      AND review_version=1
),
source_population AS
(
    SELECT
        count(*)::bigint AS source_rows,
        count
        (
            DISTINCT scenario_id::text||'|'||merchant_application_id
        )::bigint AS distinct_grain_rows,
        count(*) FILTER
        (
            WHERE contract_row_hash IS NULL
               OR strategy_outcome_code IS NULL
               OR servicing_action_code IS NULL
               OR merchant_application_id IS NULL
               OR scenario_id IS NULL
        )::bigint AS invalid_source_rows,
        count(*) FILTER
        (
            WHERE strategy_outcome_code='CLOSED_NO_FURTHER_ACTION'
              AND servicing_action_code='NO_ACTION_CLOSED'
        )::bigint AS closed_rows,
        count(*) FILTER
        (
            WHERE strategy_outcome_code=
                  'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW'
              AND servicing_action_code='TEMPORARY_REMITTANCE_REVIEW'
        )::bigint AS temporary_rows,
        count(*) FILTER
        (
            WHERE strategy_outcome_code=
                  'TARGETED_MERCHANT_OUTREACH_REVIEW'
              AND servicing_action_code='OUTREACH_REVIEW_QUEUE'
        )::bigint AS outreach_rows,
        round
        (
            sum
            (
                CASE
                    WHEN strategy_outcome_code=
                         'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW'
                    THEN recommended_action_exposure_amount
                    ELSE 0
                END
            ),
            2
        ) AS temporary_exposure,
        round
        (
            sum
            (
                CASE
                    WHEN strategy_outcome_code=
                         'TARGETED_MERCHANT_OUTREACH_REVIEW'
                    THEN recommended_action_exposure_amount
                    ELSE 0
                END
            ),
            2
        ) AS outreach_exposure
    FROM msbf_m2.advance_intervention_strategy_latest
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
definitions AS
(
    SELECT
        (
            SELECT count(*) FROM msbf_m2.operational_setup_outcome_definition
            WHERE module1_run_id=(SELECT run_id FROM run_context)
              AND definition_status='APPROVED'
        )::bigint AS outcome_rows,
        (
            SELECT count(*) FROM msbf_m2.operational_setup_action_definition
            WHERE module1_run_id=(SELECT run_id FROM run_context)
              AND definition_status='APPROVED'
        )::bigint AS action_rows,
        (
            SELECT count(*) FROM msbf_m2.operational_setup_reason_definition
            WHERE module1_run_id=(SELECT run_id FROM run_context)
              AND definition_status='APPROVED'
        )::bigint AS reason_rows
),
targets AS
(
    SELECT
        (
            SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot
            WHERE module1_run_id=(SELECT run_id FROM run_context)
        )::bigint AS target_source_rows,
        (
            SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot
            WHERE module1_run_id=(SELECT run_id FROM run_context)
        )::bigint AS target_activation_rows,
        (
            SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot
            WHERE module1_run_id=(SELECT run_id FROM run_context)
        )::bigint AS target_setup_rows,
        (
            SELECT count(*) FROM msbf_m2.operational_activation_portfolio_summary
            WHERE module1_run_id=(SELECT run_id FROM run_context)
        )::bigint AS target_portfolio_rows,
        (
            SELECT count(*) FROM msbf_m2.application_operational_activation_latest
            WHERE module1_run_id=(SELECT run_id FROM run_context)
        )::bigint AS target_latest_rows,
        (
            SELECT count(*) FROM msbf_m2.application_operational_activation_archive
            WHERE module1_run_id=(SELECT run_id FROM run_context)
        )::bigint AS target_archive_rows,
        (
            SELECT count(*) FROM msbf_ctl.m2_7_operational_activation_contract_registry
            WHERE module1_run_id=(SELECT run_id FROM run_context)
        )::bigint AS target_registry_rows,
        (
            SELECT count(*) FROM msbf_ctl.run_evidence
            WHERE run_id=(SELECT run_id FROM run_context)
              AND evidence_code LIKE 'M2_7_%'
        )::bigint AS target_evidence_rows,
        (
            SELECT count(*) FROM msbf_ctl.acceptance_gate_result
            WHERE run_id=(SELECT run_id FROM run_context)
              AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
        )::bigint AS target_acceptance_rows,
        (
            SELECT count(*) FROM information_schema.tables
            WHERE table_schema IN ('msbf_ctl','msbf_m2')
              AND lower(table_name) LIKE 'm2_8%'
        )::bigint AS premature_m2_8_tables,
        (
            SELECT count(*) FROM information_schema.columns
            WHERE table_schema='msbf_m2'
              AND table_name IN
              (
                  'application_operational_activation_snapshot',
                  'operational_account_setup_snapshot',
                  'application_operational_activation_latest',
                  'application_operational_activation_archive'
              )
              AND lower(column_name) IN
              (
                  'real_core_account_number',
                  'bank_account_number',
                  'routing_number',
                  'settlement_account_number',
                  'ach_trace_number',
                  'payment_network_confirmation',
                  'external_notice_payload',
                  'production_adverse_action_notice'
              )
        )::bigint AS prohibited_columns
)
SELECT
    run_context.run_id,run_context.run_status,run_context.population_id,
    run_context.as_of_date,
    policy.policy_status,policy.methodology_version,policy.contract_code,
    policy.contract_version,policy.schema_version,
    policy.source_contract_code AS policy_source_contract_code,
    policy.source_contract_version AS policy_source_contract_version,
    policy.source_schema_version AS policy_source_schema_version,
    policy.source_acceptance_gate_id AS policy_source_acceptance_gate_id,
    policy.source_combined_set_hash AS policy_source_combined_set_hash,
    policy.configuration_hash,

    source_registry.registry_rows AS source_registry_rows,
    source_registry.contract_status AS source_contract_status,
    source_registry.contract_code AS source_contract_code,
    source_registry.contract_version AS source_contract_version,
    source_registry.schema_version AS source_schema_version,
    source_registry.combined_set_hash AS source_combined_set_hash,
    source_registry.latest_rows AS source_latest_rows,
    source_registry.archive_rows AS source_archive_rows,
    source_registry.comparison_rows AS source_comparison_rows,
    source_registry.canonical_entities AS source_canonical_entities,
    source_registry.closed_no_action_rows AS source_closed_rows,
    source_registry.outreach_review_rows AS source_outreach_rows,
    source_registry.temporary_adjustment_review_rows AS source_temporary_rows,
    source_registry.recommended_action_exposure_amount AS source_action_exposure,

    source_gate.gate_rows AS source_gate_rows,
    source_gate.gate_status AS source_gate_status,

    source_population.source_rows,
    source_population.distinct_grain_rows,
    source_population.invalid_source_rows,
    source_population.closed_rows,
    source_population.temporary_rows,
    source_population.outreach_rows,
    source_population.temporary_exposure,
    source_population.outreach_exposure,

    definitions.outcome_rows,definitions.action_rows,definitions.reason_rows,

    targets.target_source_rows,targets.target_activation_rows,
    targets.target_setup_rows,targets.target_portfolio_rows,
    targets.target_latest_rows,targets.target_archive_rows,
    targets.target_registry_rows,targets.target_evidence_rows,
    targets.target_acceptance_rows,targets.premature_m2_8_tables,
    targets.prohibited_columns,

    CASE
        WHEN run_context.run_status='M2_6_ACCEPTED'
         AND policy.policy_status='APPROVED'
         AND policy.methodology_version='M2_7_METHOD_V1'
         AND policy.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
         AND policy.contract_version=1
         AND policy.schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
         AND policy.source_contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'
         AND policy.source_contract_version=1
         AND policy.source_schema_version='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1'
         AND policy.source_acceptance_gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'
         AND policy.source_combined_set_hash='868125bff29270490cab4d2e55cb1388'

         AND source_registry.registry_rows=1
         AND source_registry.contract_status='ACCEPTED'
         AND source_registry.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'
         AND source_registry.contract_version=1
         AND source_registry.schema_version='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1'
         AND source_registry.combined_set_hash='868125bff29270490cab4d2e55cb1388'
         AND source_registry.latest_rows=59
         AND source_registry.archive_rows=59
         AND source_registry.comparison_rows=15
         AND source_registry.canonical_entities=284
         AND source_registry.closed_no_action_rows=57
         AND source_registry.outreach_review_rows=1
         AND source_registry.temporary_adjustment_review_rows=1
         AND source_registry.recommended_action_exposure_amount=979.73

         AND source_gate.gate_rows=1
         AND source_gate.gate_status='PASS'

         AND source_population.source_rows=59
         AND source_population.distinct_grain_rows=59
         AND source_population.invalid_source_rows=0
         AND source_population.closed_rows=57
         AND source_population.temporary_rows=1
         AND source_population.outreach_rows=1
         AND source_population.temporary_exposure=518.04
         AND source_population.outreach_exposure=461.69

         AND definitions.outcome_rows=7
         AND definitions.action_rows=7
         AND definitions.reason_rows=28

         AND targets.target_source_rows=0
         AND targets.target_activation_rows=0
         AND targets.target_setup_rows=0
         AND targets.target_portfolio_rows=0
         AND targets.target_latest_rows=0
         AND targets.target_archive_rows=0
         AND targets.target_registry_rows=0
         AND targets.target_evidence_rows=0
         AND targets.target_acceptance_rows=0
         AND targets.premature_m2_8_tables=0
         AND targets.prohibited_columns=0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS preflight_status
FROM run_context
CROSS JOIN policy
CROSS JOIN source_registry
CROSS JOIN source_gate
CROSS JOIN source_population
CROSS JOIN definitions
CROSS JOIN targets;

DO $m2_7_preflight_guard$
DECLARE
    v record;
BEGIN
    SELECT run_id,preflight_status
    INTO v
    FROM _m2_7_preflight;

    IF v.preflight_status<>'PASS' THEN
        RAISE EXCEPTION
            'M2.7 preflight failed: %.',
            row_to_json(v);
    END IF;

    PERFORM msbf_ctl.m2_7_assert_generation_ready(v.run_id);
END;
$m2_7_preflight_guard$;

SELECT * FROM _m2_7_preflight;
