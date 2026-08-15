/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M2.2 — Pricing, Structure & Counteroffer Foundations

Program
140B_msbf_m2_2_failed_numeric_typmod_hash_recovery_check_v0_2R1.sql

Purpose
Confirm that the failed Program 142 transaction rolled back completely and
that Programs 140 and 141 remain the authoritative successful checkpoints.

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
policy AS
(
    SELECT
        policy_status,
        configuration_hash,
        expected_candidate_rows,
        expected_canonical_entities
    FROM msbf_ctl.m2_2_policy_profile
    WHERE policy_code = 'M2_2_PRICING_STRUCTURE_POLICY_V1'
),
source_inventory AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_latest
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS routing_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_latest
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
              AND final_route_code = 'ELIGIBLE_FOR_OFFER_DESIGN'
        )::bigint AS eligible_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_latest
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
              AND final_route_code = 'MANUAL_REVIEW'
        )::bigint AS manual_review_rows
),
targets AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.application_request_structure_snapshot
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS request_snapshot_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_request_structure_latest
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS request_latest_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_request_structure_archive
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS request_archive_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_pricing_structure_candidate
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS candidate_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_pricing_structure_snapshot
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS pricing_snapshot_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_pricing_structure_latest
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS pricing_latest_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_pricing_structure_archive
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS pricing_archive_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.m2_2_pricing_structure_contract_registry
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS registry_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.run_evidence
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND evidence_code LIKE 'M2_2_%'
        )::bigint AS evidence_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.acceptance_gate_result
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND gate_id = 'M2_2_PRICING_STRUCTURE_COUNTEROFFER'
        )::bigint AS acceptance_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.profile_resolution_error
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND severity = 'BLOCKING'
        )::bigint AS blocking_errors
)
SELECT
    governed_run.run_status,
    policy.policy_status,
    policy.configuration_hash,
    policy.expected_candidate_rows,
    policy.expected_canonical_entities,

    source_inventory.routing_rows,
    source_inventory.eligible_rows,
    source_inventory.manual_review_rows,
    source_inventory.eligible_rows +
        source_inventory.manual_review_rows AS candidate_bearing_rows,

    targets.request_snapshot_rows,
    targets.request_latest_rows,
    targets.request_archive_rows,
    targets.candidate_rows,
    targets.pricing_snapshot_rows,
    targets.pricing_latest_rows,
    targets.pricing_archive_rows,
    targets.registry_rows,
    targets.evidence_rows,
    targets.acceptance_rows,
    targets.blocking_errors,

    CASE
        WHEN governed_run.run_status = 'M2_1_ACCEPTED'
         AND policy.policy_status = 'APPROVED'
         AND length(policy.configuration_hash) = 32
         AND policy.configuration_hash ~ '^[0-9a-f]+$'
         AND policy.expected_candidate_rows = 557
         AND policy.expected_canonical_entities = 7336
         AND source_inventory.routing_rows = 1500
         AND source_inventory.eligible_rows = 59
         AND source_inventory.manual_review_rows = 190
         AND source_inventory.eligible_rows +
             source_inventory.manual_review_rows = 249
         AND targets.request_snapshot_rows = 0
         AND targets.request_latest_rows = 0
         AND targets.request_archive_rows = 0
         AND targets.candidate_rows = 0
         AND targets.pricing_snapshot_rows = 0
         AND targets.pricing_latest_rows = 0
         AND targets.pricing_archive_rows = 0
         AND targets.registry_rows = 0
         AND targets.evidence_rows = 0
         AND targets.acceptance_rows = 0
         AND targets.blocking_errors = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status
FROM governed_run
CROSS JOIN policy
CROSS JOIN source_inventory
CROSS JOIN targets;
