/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M2.1 — Eligibility, Policy Gates & Decision-Routing Foundations

Program
132H_msbf_m2_1_failed_acceptance_ambiguity_recovery_check_v0_2R7.sql

Purpose
Confirm that the failed Program 137 v0.2R6 transaction rolled back completely
and that the database remains at the governed pre-acceptance boundary:

    run_status       = M2_1_VALIDATED
    contract_status  = VALIDATED
    positive         = 112 / 112 PASS
    negative         = 20 / 20 PASS
    acceptance rows  = 0

Writes
None.

Required
recovery_status = PASS.
============================================================================ */

SET statement_timeout = '20min';
SET jit = off;

DO $m2_1_r7_acceptance_assertion$
DECLARE
    v_run_id bigint;
BEGIN
    SELECT run_id
    INTO v_run_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1;

    PERFORM msbf_ctl.m2_1_assert_acceptance_ready(v_run_id);
END;
$m2_1_r7_acceptance_assertion$;

WITH governed_run AS
(
    SELECT
        run_id,
        run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
contract_registry AS
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
controls AS
(
    SELECT
        count(*) FILTER (
            WHERE evidence_code LIKE 'M2_1_POS_%'
        )::bigint AS positive_checks,

        count(*) FILTER (
            WHERE evidence_code LIKE 'M2_1_POS_%'
              AND status = 'PASS'
        )::bigint AS positive_passes,

        count(*) FILTER (
            WHERE evidence_code LIKE 'M2_1_POS_%'
              AND status <> 'PASS'
        )::bigint AS positive_failures,

        count(*) FILTER (
            WHERE evidence_code LIKE 'M2_1_NEG_%'
        )::bigint AS negative_checks,

        count(*) FILTER (
            WHERE evidence_code LIKE 'M2_1_NEG_%'
              AND status = 'PASS'
        )::bigint AS negative_passes,

        count(*) FILTER (
            WHERE evidence_code LIKE 'M2_1_NEG_%'
              AND status <> 'PASS'
        )::bigint AS negative_failures,

        count(*) FILTER (
            WHERE evidence_code = 'M2_1_ACCEPTANCE_SUMMARY'
        )::bigint AS acceptance_summary_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM governed_run)
),
physical AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.strategy_campaign
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS campaign_rows,

        (
            SELECT count(*)
            FROM msbf_m2.policy_gate_definition
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS gate_definition_rows,

        (
            SELECT count(*)
            FROM msbf_m2.reason_code_definition
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS reason_rows,

        (
            SELECT count(*)
            FROM msbf_m2.routing_outcome_definition
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS outcome_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_policy_gate_result
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS gate_result_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_snapshot
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS snapshot_rows,

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
            FROM msbf_ctl.acceptance_gate_result
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND gate_id = 'M2_1_ELIGIBILITY_POLICY_ROUTING'
        )::bigint AS acceptance_gate_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.profile_resolution_error
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND severity = 'BLOCKING'
        )::bigint AS blocking_errors,

        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_latest AS l
            JOIN msbf_m2.application_eligibility_routing_archive AS a
              ON a.module1_run_id = l.module1_run_id
             AND a.strategy_campaign_code = l.strategy_campaign_code
             AND a.scenario_id = l.scenario_id
             AND a.merchant_application_id = l.merchant_application_id
            WHERE l.module1_run_id = (SELECT run_id FROM governed_run)
              AND
              (
                  a.contract_row_hash IS DISTINCT FROM l.contract_row_hash
                  OR a.source_latest_row_hash IS DISTINCT FROM
                     l.contract_row_hash
                  OR a.contract_payload IS DISTINCT FROM
                     (to_jsonb(l) - 'created_at')
              )
        )::bigint AS latest_archive_mismatches,

        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_snapshot AS s
            WHERE s.module1_run_id = (SELECT run_id FROM governed_run)
              AND s.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_1_hash_jsonb(
                      to_jsonb(s) - 'row_hash' - 'created_at'
                  )
        )::bigint AS snapshot_hash_mismatches,

        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_latest AS l
            WHERE l.module1_run_id = (SELECT run_id FROM governed_run)
              AND l.contract_row_hash IS DISTINCT FROM
                  msbf_ctl.m2_1_hash_jsonb(
                      to_jsonb(l) - 'contract_row_hash' - 'created_at'
                  )
        )::bigint AS latest_hash_mismatches,

        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_archive AS a
            WHERE a.module1_run_id = (SELECT run_id FROM governed_run)
              AND a.archive_row_hash IS DISTINCT FROM
                  msbf_ctl.m2_1_hash_jsonb(
                      to_jsonb(a)
                      - 'archive_id'
                      - 'archive_row_hash'
                      - 'archived_at'
                      - 'created_at'
                  )
        )::bigint AS archive_hash_mismatches
)
SELECT
    governed_run.run_status,
    contract_registry.contract_status,

    controls.positive_checks,
    controls.positive_passes,
    controls.positive_failures,
    controls.negative_checks,
    controls.negative_passes,
    controls.negative_failures,
    controls.acceptance_summary_rows,

    physical.campaign_rows,
    physical.gate_definition_rows,
    physical.reason_rows,
    physical.outcome_rows,
    physical.gate_result_rows,
    physical.snapshot_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.comparison_rows,
    physical.acceptance_gate_rows,
    physical.blocking_errors,
    physical.latest_archive_mismatches,
    physical.snapshot_hash_mismatches,
    physical.latest_hash_mismatches,
    physical.archive_hash_mismatches,

    contract_registry.canonical_entities,
    contract_registry.campaign_set_hash,
    contract_registry.gate_definition_set_hash,
    contract_registry.reason_code_set_hash,
    contract_registry.outcome_definition_set_hash,
    contract_registry.gate_result_set_hash,
    contract_registry.routing_snapshot_set_hash,
    contract_registry.latest_set_hash,
    contract_registry.archive_set_hash,
    contract_registry.contract_set_hash,
    contract_registry.combined_set_hash,

    CASE
        WHEN governed_run.run_status = 'M2_1_VALIDATED'
         AND contract_registry.contract_status = 'VALIDATED'

         AND controls.positive_checks = 112
         AND controls.positive_passes = 112
         AND controls.positive_failures = 0

         AND controls.negative_checks = 20
         AND controls.negative_passes = 20
         AND controls.negative_failures = 0

         AND controls.acceptance_summary_rows = 0

         AND physical.campaign_rows = 1
         AND physical.gate_definition_rows = 12
         AND physical.reason_rows = 23
         AND physical.outcome_rows = 4
         AND physical.gate_result_rows = 18000
         AND physical.snapshot_rows = 1500
         AND physical.latest_rows = 1500
         AND physical.archive_rows = 1500
         AND physical.comparison_rows = 750

         AND physical.acceptance_gate_rows = 0
         AND physical.blocking_errors = 0
         AND physical.latest_archive_mismatches = 0
         AND physical.snapshot_hash_mismatches = 0
         AND physical.latest_hash_mismatches = 0
         AND physical.archive_hash_mismatches = 0

         AND contract_registry.strategy_campaign_rows = 1
         AND contract_registry.gate_definition_rows = 12
         AND contract_registry.reason_code_rows = 23
         AND contract_registry.outcome_definition_rows = 4
         AND contract_registry.gate_result_rows = 18000
         AND contract_registry.routing_snapshot_rows = 1500
         AND contract_registry.latest_rows = 1500
         AND contract_registry.archive_rows = 1500
         AND contract_registry.comparison_rows = 750
         AND contract_registry.canonical_entities = 22541

         AND contract_registry.campaign_set_hash IS NOT NULL
         AND contract_registry.gate_definition_set_hash IS NOT NULL
         AND contract_registry.reason_code_set_hash IS NOT NULL
         AND contract_registry.outcome_definition_set_hash IS NOT NULL
         AND contract_registry.gate_result_set_hash IS NOT NULL
         AND contract_registry.routing_snapshot_set_hash IS NOT NULL
         AND contract_registry.latest_set_hash IS NOT NULL
         AND contract_registry.archive_set_hash IS NOT NULL
         AND contract_registry.contract_set_hash IS NOT NULL
         AND contract_registry.combined_set_hash IS NOT NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status

FROM governed_run
CROSS JOIN contract_registry
CROSS JOIN controls
CROSS JOIN physical;
