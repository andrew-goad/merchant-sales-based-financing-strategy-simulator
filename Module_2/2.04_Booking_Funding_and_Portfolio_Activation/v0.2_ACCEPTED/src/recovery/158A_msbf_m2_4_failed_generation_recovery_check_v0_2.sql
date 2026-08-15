/* ============================================================================
M2.4 Program 158A — Failed-Generation Recovery Check
Version     : v0.2
Purpose     : Read-only verification after a failed/cancelled Program 158.
              Run after ROLLBACK. Requires accepted M2.3 source, approved M2.4
              policy/dictionaries and empty M2.4 generated targets.
Required    : recovery_status = PASS.
============================================================================ */

/* --------------------------------------------------------------------------
Recovery reconstruction — read-only physical state and lifecycle verification
-------------------------------------------------------------------------- */
WITH run_context AS
(
    SELECT run_id, run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
policy AS
(
    SELECT policy_status, configuration_hash
    FROM msbf_ctl.m2_4_policy_profile
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
definitions AS
(
    SELECT
        (SELECT count(*) FROM msbf_m2.booking_funding_activation_outcome_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS outcome_rows,
        (SELECT count(*) FROM msbf_m2.booking_funding_reason_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS reason_rows,
        (SELECT count(*) FROM msbf_m2.external_notice_control_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS notice_rows,
        (SELECT count(*) FROM msbf_ref.acceptance_gate_catalog
         WHERE gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND active_flag) AS gate_catalog_rows
),
targets AS
(
    SELECT
        (SELECT count(*) FROM msbf_m2.application_booking_funding_source_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS source_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS snapshot_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS latest_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_archive
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS archive_rows,
        (SELECT count(*) FROM msbf_m2.synthetic_account_activation
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS account_rows,
        (SELECT count(*) FROM msbf_m2.synthetic_advance_funding
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS advance_rows,
        (SELECT count(*) FROM msbf_m2.initial_portfolio_activation
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS portfolio_rows,
        (SELECT count(*) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS registry_rows,
        (SELECT count(*) FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code LIKE 'M2_4_%') AS evidence_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
         WHERE run_id = (SELECT run_id FROM run_context)
           AND gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION') AS acceptance_rows
)
SELECT
    run_context.run_status,
    policy.policy_status,
    policy.configuration_hash,
    definitions.outcome_rows,
    definitions.reason_rows,
    definitions.notice_rows,
    definitions.gate_catalog_rows,
    targets.source_rows,
    targets.snapshot_rows,
    targets.latest_rows,
    targets.archive_rows,
    targets.account_rows,
    targets.advance_rows,
    targets.portfolio_rows,
    targets.registry_rows,
    targets.evidence_rows,
    targets.acceptance_rows,
    CASE
        WHEN run_context.run_status = 'M2_3_ACCEPTED'
         AND policy.policy_status = 'APPROVED'
         AND length(policy.configuration_hash)=32
         AND policy.configuration_hash ~ '^[0-9a-f]+$'
         AND definitions.outcome_rows = 5
         AND definitions.reason_rows = 24
         AND definitions.notice_rows = 4
         AND definitions.gate_catalog_rows = 1
         AND targets.source_rows = 0
         AND targets.snapshot_rows = 0
         AND targets.latest_rows = 0
         AND targets.archive_rows = 0
         AND targets.account_rows = 0
         AND targets.advance_rows = 0
         AND targets.portfolio_rows = 0
         AND targets.registry_rows = 0
         AND targets.evidence_rows = 0
         AND targets.acceptance_rows = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status
FROM run_context
CROSS JOIN policy
CROSS JOIN definitions
CROSS JOIN targets;
