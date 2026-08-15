/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 166B_msbf_m2_5_generation_reconciliation_reconstructed_v0_2.sql
Version     : v0.2

Purpose
-------
Read-only reconstruction of the Program 166 checkpoint when the DBeaver result
tab was lost or suppressed after a successful commit.

Required result
---------------
generation_reconstruction_status = PASS.
============================================================================ */

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
        status_rows,
        alert_rows,
        reason_rows,
        source_rows,
        daily_rows,
        latest_rows,
        archive_rows,
        portfolio_daily_rows,
        comparison_rows,
        registry_rows,
        canonical_entities,
        paid_off_rows,
        open_monitoring_rows,
        stress_status_floor_rows,
        total_remittance_amount,
        ending_receivable_exposure_amount,
        policy_set_hash,
        status_set_hash,
        alert_set_hash,
        reason_set_hash,
        source_set_hash,
        daily_set_hash,
        latest_set_hash,
        archive_set_hash,
        portfolio_daily_set_hash,
        contract_set_hash,
        combined_set_hash
    FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
physical AS
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
            FROM msbf_m2.v_m2_5_matched_monitoring_comparison
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS comparison_rows,
        (
            SELECT count(*)
            FROM msbf_ctl.run_evidence
            WHERE run_id = (SELECT run_id FROM run_context)
              AND evidence_code LIKE 'M2_5_%'
              AND evidence_code NOT LIKE 'M2_5_POS_%'
              AND evidence_code NOT LIKE 'M2_5_NEG_%'
              AND evidence_code <> 'M2_5_ACCEPTANCE_SUMMARY'
        )::bigint AS generation_evidence_rows,
        (
            SELECT count(*)
            FROM msbf_m2.v_m2_5_matched_monitoring_comparison
            WHERE module1_run_id = (SELECT run_id FROM run_context)
              AND stress_status_improvement_flag
        )::bigint AS stress_status_improvements,
        (
            SELECT canonical_entities
            FROM msbf_m2.v_m2_5_canonical_hash
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS physical_canonical_entities,
        (
            SELECT combined_set_hash
            FROM msbf_m2.v_m2_5_canonical_hash
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        ) AS physical_combined_set_hash
)
SELECT
    run_context.run_status,
    registry.contract_status,
    physical.source_rows,
    physical.daily_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.portfolio_rows,
    physical.comparison_rows,
    registry.canonical_entities,
    physical.physical_canonical_entities,
    physical.generation_evidence_rows,
    registry.paid_off_rows,
    registry.open_monitoring_rows,
    registry.stress_status_floor_rows,
    registry.total_remittance_amount,
    registry.ending_receivable_exposure_amount,
    physical.stress_status_improvements,
    registry.policy_set_hash,
    registry.status_set_hash,
    registry.alert_set_hash,
    registry.reason_set_hash,
    registry.source_set_hash,
    registry.daily_set_hash,
    registry.latest_set_hash,
    registry.archive_set_hash,
    registry.portfolio_daily_set_hash,
    registry.contract_set_hash,
    registry.combined_set_hash,
    physical.physical_combined_set_hash,

    CASE
        WHEN run_context.run_status IN
             ('M2_5_GENERATED','M2_5_VALIDATED','M2_5_ACCEPTED')
         AND registry.contract_status IN
             ('GENERATED','VALIDATED','ACCEPTED')
         AND physical.source_rows = 59
         AND physical.daily_rows = 7080
         AND physical.latest_rows = 59
         AND physical.archive_rows = 59
         AND physical.portfolio_rows = 240
         AND physical.comparison_rows = 15
         AND registry.canonical_entities = 7536
         AND physical.physical_canonical_entities = 7536
         AND physical.generation_evidence_rows = 24
         AND registry.paid_off_rows + registry.open_monitoring_rows = 59
         AND registry.total_remittance_amount >= 0
         AND registry.ending_receivable_exposure_amount >= 0
         AND physical.stress_status_improvements = 0
         AND registry.combined_set_hash IS NOT DISTINCT FROM
             physical.physical_combined_set_hash
         AND registry.combined_set_hash IS NOT NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END AS generation_reconstruction_status

FROM run_context
CROSS JOIN registry
CROSS JOIN physical;
