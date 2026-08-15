/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 166A_msbf_m2_5_failed_generation_recovery_check_v0_2.sql
Version     : v0.2

Purpose
-------
Read-only recovery check after a failed or cancelled Program 166 generation
attempt. Execute `ROLLBACK;` first. Programs 164 and 165 remain authoritative;
all generated M2.5 rows, evidence, registry and acceptance rows must be zero.

Required result
---------------
recovery_status = PASS.
============================================================================ */

WITH run_context AS
(
    SELECT run_id, run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
policy AS
(
    SELECT
        policy_status,
        configuration_hash,
        source_m2_4_combined_hash,
        source_m1_6_combined_hash
    FROM msbf_ctl.m2_5_policy_profile
    WHERE module1_run_id = (SELECT run_id FROM run_context)
      AND policy_code = 'M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_POLICY_V1'
),
definitions AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_monitoring_status_definition
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS status_rows,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_monitoring_alert_definition
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS alert_rows,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_monitoring_reason_definition
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS reason_rows
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
            FROM msbf_ctl.profile_resolution_error
            WHERE run_id = (SELECT run_id FROM run_context)
              AND severity = 'BLOCKING'
        )::bigint AS blocking_errors
)
SELECT
    run_context.run_status,
    policy.policy_status,
    policy.configuration_hash,
    policy.source_m2_4_combined_hash,
    policy.source_m1_6_combined_hash,
    definitions.status_rows,
    definitions.alert_rows,
    definitions.reason_rows,
    targets.source_rows,
    targets.daily_rows,
    targets.latest_rows,
    targets.archive_rows,
    targets.portfolio_rows,
    targets.registry_rows,
    targets.evidence_rows,
    targets.acceptance_rows,
    targets.blocking_errors,

    CASE
        WHEN run_context.run_status = 'M2_4_ACCEPTED'
         AND policy.policy_status = 'APPROVED'
         AND length(policy.configuration_hash) = 32
         AND policy.configuration_hash ~ '^[0-9a-f]+$'
         AND policy.source_m2_4_combined_hash = '117450a3eea7bb3d3c74d18cc3c8e96a'
         AND length(policy.source_m1_6_combined_hash) = 32
         AND policy.source_m1_6_combined_hash ~ '^[0-9a-f]+$'
         AND definitions.status_rows = 6
         AND definitions.alert_rows = 7
         AND definitions.reason_rows = 24
         AND targets.source_rows = 0
         AND targets.daily_rows = 0
         AND targets.latest_rows = 0
         AND targets.archive_rows = 0
         AND targets.portfolio_rows = 0
         AND targets.registry_rows = 0
         AND targets.evidence_rows = 0
         AND targets.acceptance_rows = 0
         AND targets.blocking_errors = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status

FROM run_context
CROSS JOIN policy
CROSS JOIN definitions
CROSS JOIN targets;
