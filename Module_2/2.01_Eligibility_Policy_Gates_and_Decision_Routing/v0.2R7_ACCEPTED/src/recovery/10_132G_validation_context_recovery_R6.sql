/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M2.1 — Eligibility, Policy Gates & Decision-Routing Foundations

Program
132G_msbf_m2_1_failed_validation_context_projection_recovery_check_v0_2R6.sql

Purpose
Confirm that:
- Program 132F completed successfully;
- the failed Program 135 v0.2R5 transaction did not alter persistent state;
- all four governed policy-boundary columns physically exist;
- all four columns are true and match the approved configuration payload;
- the repaired configuration and validation-ready assertions pass;
- generated routing data, hashes, positive evidence, and accepted predecessors
  remain intact.

Writes
None.

Required
recovery_status = PASS.
============================================================================ */

SET statement_timeout = '20min';
SET jit = off;

DO $m2_1_r6_assertion_check$
DECLARE
    v_run_id bigint;
BEGIN
    SELECT run_id
    INTO v_run_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1;

    PERFORM msbf_ctl.m2_1_assert_configuration(v_run_id);
    PERFORM msbf_ctl.m2_1_assert_validation_ready(v_run_id);
END;
$m2_1_r6_assertion_check$;

WITH governed_run AS
(
    SELECT
        run_id,
        run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
policy AS
(
    SELECT
        policy_code,
        policy_status,
        synthetic_data_only_flag,
        no_final_offer_terms_flag,
        no_production_adverse_action_flag,
        acquisition_source_review_only_flag,
        configuration_payload,
        configuration_hash,
        (
            (configuration_payload->>'synthetic_data_only')::boolean
                IS NOT DISTINCT FROM synthetic_data_only_flag
            AND
            (configuration_payload->>'no_final_offer_terms')::boolean
                IS NOT DISTINCT FROM no_final_offer_terms_flag
            AND
            (configuration_payload->>'no_production_adverse_action')::boolean
                IS NOT DISTINCT FROM no_production_adverse_action_flag
            AND
            (configuration_payload->>'acquisition_source_review_only')::boolean
                IS NOT DISTINCT FROM acquisition_source_review_only_flag
        ) AS payload_boundary_match
    FROM msbf_ctl.m2_1_policy_profile
    WHERE policy_code = 'M2_1_ELIGIBILITY_POLICY_V1'
),
contract_registry AS
(
    SELECT
        contract_status,
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
            FROM information_schema.columns
            WHERE table_schema = 'msbf_ctl'
              AND table_name = 'm2_1_policy_profile'
              AND column_name IN
              (
                  'synthetic_data_only_flag',
                  'no_final_offer_terms_flag',
                  'no_production_adverse_action_flag',
                  'acquisition_source_review_only_flag'
              )
        )::bigint AS policy_boundary_column_count,

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
        )::bigint AS positive_checks,

        (
            SELECT count(*)
            FROM msbf_ctl.run_evidence
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND evidence_code LIKE 'M2_1_POS_%'
              AND status = 'PASS'
        )::bigint AS positive_passes,

        (
            SELECT count(*)
            FROM msbf_ctl.run_evidence
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND evidence_code LIKE 'M2_1_POS_%'
              AND status = 'FAIL'
        )::bigint AS positive_failures,

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
              AND gate_id = 'M2_1_ELIGIBILITY_POLICY_ROUTING'
        )::bigint AS acceptance_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.profile_resolution_error
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND severity = 'BLOCKING'
        )::bigint AS blocking_errors,

        (
            SELECT count(*)
            FROM msbf_m2.strategy_campaign AS c
            WHERE c.module1_run_id = (SELECT run_id FROM governed_run)
              AND c.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_1_hash_jsonb(
                      to_jsonb(c) - 'row_hash' - 'created_at'
                  )
        )::bigint AS campaign_hash_mismatches,

        (
            SELECT count(*)
            FROM msbf_ctl.m2_1_strategy_contract_registry AS r
            WHERE r.module1_run_id = (SELECT run_id FROM governed_run)
              AND
              (
                  r.contract_set_hash IS DISTINCT FROM md5(r.row_hash)
                  OR r.combined_set_hash IS NULL
              )
        )::bigint AS registry_hash_mismatches
)
SELECT
    governed_run.run_status,
    contract_registry.contract_status,
    policy.policy_code,
    policy.policy_status,
    policy.synthetic_data_only_flag,
    policy.no_final_offer_terms_flag,
    policy.no_production_adverse_action_flag,
    policy.acquisition_source_review_only_flag,
    policy.payload_boundary_match,
    policy.configuration_hash,
    physical.policy_boundary_column_count,
    physical.gate_result_rows,
    physical.routing_snapshot_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.comparison_rows,
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
    physical.positive_checks,
    physical.positive_passes,
    physical.positive_failures,
    physical.negative_evidence_rows,
    physical.acceptance_rows,
    physical.blocking_errors,
    physical.campaign_hash_mismatches,
    physical.registry_hash_mismatches,
    CASE
        WHEN governed_run.run_status = 'M2_1_VALIDATED'
         AND contract_registry.contract_status = 'VALIDATED'
         AND policy.policy_status = 'APPROVED'
         AND policy.synthetic_data_only_flag
         AND policy.no_final_offer_terms_flag
         AND policy.no_production_adverse_action_flag
         AND policy.acquisition_source_review_only_flag
         AND policy.payload_boundary_match
         AND length(policy.configuration_hash) = 32
         AND policy.configuration_hash ~ '^[0-9a-f]+$'
         AND physical.policy_boundary_column_count = 4
         AND physical.gate_result_rows = 18000
         AND physical.routing_snapshot_rows = 1500
         AND physical.latest_rows = 1500
         AND physical.archive_rows = 1500
         AND physical.comparison_rows = 750
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
         AND physical.positive_checks = 112
         AND physical.positive_passes = 112
         AND physical.positive_failures = 0
         AND physical.negative_evidence_rows = 0
         AND physical.acceptance_rows = 0
         AND physical.blocking_errors = 0
         AND physical.campaign_hash_mismatches = 0
         AND physical.registry_hash_mismatches = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status
FROM governed_run
CROSS JOIN policy
CROSS JOIN contract_registry
CROSS JOIN physical;
