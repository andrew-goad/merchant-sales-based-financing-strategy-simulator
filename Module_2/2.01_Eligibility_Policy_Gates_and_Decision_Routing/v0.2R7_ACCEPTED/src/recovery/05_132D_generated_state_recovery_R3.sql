/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M2.1 — Eligibility, Policy Gates & Decision-Routing Foundations

Program
132D_msbf_m2_1_generated_state_recovery_and_comparison_view_check_v0_2R3.sql

Purpose
Confirm that Program 134 v0.2R1 committed successfully and that failed
recovery/validation scripts did not alter the generated M2.1 population.

Important physical design point
M2.1 does not persist an
`application_eligibility_routing_comparison` table. Its 750 matched
baseline/stress comparisons are exposed through the governed read-only view:

    msbf_m2.v_m2_1_matched_scenario_comparison

Writes
None.

Required
recovery_status = PASS.
============================================================================ */

SET statement_timeout = '20min';
SET jit = off;

WITH governed_run AS
(
    SELECT
        run_id,
        run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
strategy_registry AS
(
    SELECT
        contract_status,
        strategy_campaign_rows,
        gate_definition_rows,
        reason_code_rows,
        outcome_definition_rows,
        gate_result_rows,
        routing_snapshot_rows,
        latest_rows,
        archive_rows,
        comparison_rows,
        canonical_entities,
        campaign_set_hash,
        gate_definition_set_hash,
        reason_code_set_hash,
        outcome_definition_set_hash,
        gate_result_set_hash,
        routing_snapshot_set_hash,
        latest_set_hash,
        archive_set_hash,
        contract_set_hash,
        combined_set_hash
    FROM msbf_ctl.m2_1_strategy_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM governed_run)
),
physical AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.application_policy_gate_result
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS gate_result_rows,
        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_snapshot
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS routing_snapshot_rows,
        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_latest
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS latest_rows,
        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_archive
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS archive_rows,
        (
            SELECT count(*)
            FROM msbf_m2.v_m2_1_matched_scenario_comparison
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS comparison_rows,
        (
            SELECT count(*)
            FROM msbf_ctl.run_evidence
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND evidence_code LIKE 'M2_1_POS_%'
        )::bigint AS positive_evidence_rows,
        (
            SELECT count(*)
            FROM msbf_ctl.run_evidence
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND evidence_code LIKE 'M2_1_NEG_%'
        )::bigint AS negative_evidence_rows,
        (
            SELECT count(*)
            FROM msbf_ctl.acceptance_gate_result
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND gate_id = 'M2_1_PROFILE_SOURCE_GATEKEEPER'
        )::bigint AS acceptance_rows,
        (
            SELECT count(*)
            FROM msbf_ctl.profile_resolution_error
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND severity = 'BLOCKING'
        )::bigint AS blocking_errors,
        (
            SELECT count(*)
            FROM information_schema.columns
            WHERE table_schema = 'msbf_m2'
              AND table_name IN
              (
                  'application_policy_gate_result',
                  'application_eligibility_routing_snapshot',
                  'application_eligibility_routing_latest',
                  'application_eligibility_routing_archive'
              )
              AND lower(column_name) IN
              (
                  'apr',
                  'factor_rate',
                  'approved_amount',
                  'offer_amount',
                  'remittance_rate',
                  'offer_term',
                  'approved_term',
                  'final_price',
                  'approval_flag',
                  'counteroffer_flag',
                  'decline_flag',
                  'adverse_action_code',
                  'booking_status',
                  'funding_status'
              )
        )::bigint AS prohibited_application_columns,
        (
            SELECT count(*)
            FROM msbf_m2.application_policy_gate_result
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
              AND gate_code = 'GATE_05_PROCESSOR_CONTINUITY'
              AND observed_value_text = 'UNAVAILABLE'
              AND gate_outcome <> 'REVIEW'
        )::bigint AS unavailable_continuity_mismatches
)
SELECT
    governed_run.run_status,
    strategy_registry.contract_status,
    strategy_registry.strategy_campaign_rows,
    strategy_registry.gate_definition_rows,
    strategy_registry.reason_code_rows,
    strategy_registry.outcome_definition_rows,
    physical.gate_result_rows,
    physical.routing_snapshot_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.comparison_rows,
    strategy_registry.canonical_entities,
    strategy_registry.campaign_set_hash,
    strategy_registry.gate_definition_set_hash,
    strategy_registry.reason_code_set_hash,
    strategy_registry.outcome_definition_set_hash,
    strategy_registry.gate_result_set_hash,
    strategy_registry.routing_snapshot_set_hash,
    strategy_registry.latest_set_hash,
    strategy_registry.archive_set_hash,
    strategy_registry.contract_set_hash,
    strategy_registry.combined_set_hash,
    physical.positive_evidence_rows,
    physical.negative_evidence_rows,
    physical.acceptance_rows,
    physical.blocking_errors,
    physical.prohibited_application_columns,
    physical.unavailable_continuity_mismatches,
    CASE
        WHEN governed_run.run_status = 'M2_1_GENERATED'
         AND strategy_registry.contract_status = 'GENERATED'
         AND strategy_registry.strategy_campaign_rows = 1
         AND strategy_registry.gate_definition_rows = 12
         AND strategy_registry.reason_code_rows = 23
         AND strategy_registry.outcome_definition_rows = 4
         AND physical.gate_result_rows = 18000
         AND physical.routing_snapshot_rows = 1500
         AND physical.latest_rows = 1500
         AND physical.archive_rows = 1500
         AND physical.comparison_rows = 750
         AND strategy_registry.comparison_rows = 750
         AND strategy_registry.canonical_entities = 22541
         AND strategy_registry.campaign_set_hash IS NOT NULL
         AND strategy_registry.gate_definition_set_hash IS NOT NULL
         AND strategy_registry.reason_code_set_hash IS NOT NULL
         AND strategy_registry.outcome_definition_set_hash IS NOT NULL
         AND strategy_registry.gate_result_set_hash IS NOT NULL
         AND strategy_registry.routing_snapshot_set_hash IS NOT NULL
         AND strategy_registry.latest_set_hash IS NOT NULL
         AND strategy_registry.archive_set_hash IS NOT NULL
         AND strategy_registry.contract_set_hash IS NOT NULL
         AND strategy_registry.combined_set_hash IS NOT NULL
         AND physical.positive_evidence_rows = 0
         AND physical.negative_evidence_rows = 0
         AND physical.acceptance_rows = 0
         AND physical.blocking_errors = 0
         AND physical.prohibited_application_columns = 0
         AND physical.unavailable_continuity_mismatches = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status
FROM governed_run
CROSS JOIN strategy_registry
CROSS JOIN physical;
