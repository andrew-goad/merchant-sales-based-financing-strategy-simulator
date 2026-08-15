/* ============================================================================
M2.4 Program 158B — Generation Result Reconstruction
Version     : v0.2
Purpose     : Read-only reconstruction when Program 158 committed successfully
              but its final DBeaver result tab was lost or suppressed.
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
registry AS
(
    SELECT
        contract_status,
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
        combined_set_hash
    FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
physical AS
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
        (SELECT count(*) FROM msbf_m2.v_m2_4_matched_scenario_comparison
         WHERE module1_run_id = (SELECT run_id FROM run_context)) AS comparison_rows,
        (SELECT count(*) FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code LIKE 'M2_4_%') AS evidence_rows,
        (SELECT count(*) FROM msbf_m2.v_m2_4_matched_scenario_comparison
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND stress_activation_improvement_flag) AS stress_activation_improvements,
        (SELECT count(*) FROM msbf_m2.v_m2_4_matched_scenario_comparison
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND stress_funded_amount_improvement_flag) AS stress_amount_improvements
)
SELECT
    run_context.run_status,
    registry.contract_status,
    physical.source_rows,
    physical.snapshot_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.account_rows,
    physical.advance_rows,
    physical.portfolio_rows,
    physical.comparison_rows,
    registry.canonical_entities,
    physical.evidence_rows,
    physical.stress_activation_improvements,
    physical.stress_amount_improvements,
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
    CASE
        WHEN run_context.run_status IN ('M2_4_GENERATED','M2_4_VALIDATED','M2_4_ACCEPTED')
         AND registry.contract_status IN ('GENERATED','VALIDATED','ACCEPTED')
         AND physical.source_rows = 1500
         AND physical.snapshot_rows = 1500
         AND physical.latest_rows = 1500
         AND physical.archive_rows = 1500
         AND physical.account_rows = 59
         AND physical.advance_rows = 59
         AND physical.portfolio_rows = 59
         AND physical.comparison_rows = 750
         AND registry.canonical_entities = 6212
         AND physical.evidence_rows >= 24
         AND physical.stress_activation_improvements = 0
         AND physical.stress_amount_improvements = 0
         AND registry.combined_set_hash IS NOT NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END AS generation_reconstruction_status
FROM run_context
CROSS JOIN registry
CROSS JOIN physical;
