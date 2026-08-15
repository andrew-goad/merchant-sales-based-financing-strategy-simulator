/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 169A_msbf_m2_5_failed_acceptance_active_count_recovery_v0_2R5.sql
Version     : v0.2R5

Purpose
-------
Read-only recovery and root-cause proof after Program 169 v0.2 failed its
acceptance precondition guard.

The Program 166 portfolio summary defines:

    active_advance_count
    = count of advances with receivable_balance_before > 0

This is a start-of-day operational count. Program 169 v0.2 incorrectly
recomputed active advances with `NOT paid_off_flag`, an end-of-day state.
An advance that pays off during the day is active at day open and paid off at
day end. The two counts therefore differ on payoff-event days even though the
persisted portfolio summary is correct.

This program:
- verifies Programs 164–168 remain authoritative;
- proves 120 positive and 20 negative controls are committed and passing;
- compares the original and generation-aligned active-count definitions;
- proves all other Program 169 acceptance preconditions remain satisfied;
- writes no persistent data.

Required results
----------------
Result Set 01:
    recovery_status = PASS
    original_active_count_mismatches > 0
    corrected_active_count_mismatches = 0
    original_portfolio_summary_mismatches =
        original_active_count_mismatches
    corrected_portfolio_summary_mismatches = 0

Result Set 02:
    one or more payoff-event day rows showing:
    persisted_active_advance_count = generation_aligned_active_advance_count
    persisted_active_advance_count <> original_acceptance_active_advance_count

Result Set 03:
    headers retained and zero corrected acceptance exception rows.
============================================================================ */

SET statement_timeout = '30min';
SET jit = off;

WITH run_context AS
(
    SELECT
        run_id,
        run_status
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
        contract_set_hash,
        combined_set_hash
    FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
controls AS
(
    SELECT
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_POS_%'
        )::bigint AS positive_checks,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_POS_%'
              AND status = 'PASS'
        )::bigint AS positive_passes,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_POS_%'
              AND status <> 'PASS'
        )::bigint AS positive_failures,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_NEG_%'
        )::bigint AS negative_checks,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_NEG_%'
              AND status = 'PASS'
        )::bigint AS negative_passes,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_NEG_%'
              AND status <> 'PASS'
        )::bigint AS negative_failures,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_%'
              AND evidence_code NOT LIKE 'M2_5_POS_%'
              AND evidence_code NOT LIKE 'M2_5_NEG_%'
              AND evidence_code <> 'M2_5_ACCEPTANCE_SUMMARY'
        )::bigint AS generation_evidence_rows,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_%'
              AND status = 'FAIL'
        )::bigint AS failed_evidence_rows

    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM run_context)
),
daily_reproduction AS
(
    SELECT
        daily.module1_run_id,
        daily.scenario_id,
        daily.monitoring_day_index,

        count(*)::integer AS opening_advance_count,

        count(*) FILTER
        (
            WHERE daily.receivable_balance_before > 0
        )::integer AS generation_aligned_active_advance_count,

        count(*) FILTER
        (
            WHERE NOT daily.paid_off_flag
        )::integer AS original_acceptance_active_advance_count,

        count(*) FILTER
        (
            WHERE daily.paid_off_flag
        )::integer AS paid_off_count,

        count(*) FILTER
        (
            WHERE daily.receivable_balance_before > 0
              AND daily.paid_off_flag
        )::integer AS payoff_event_advance_count,

        round(sum(daily.source_eligible_pos_sales), 2)::numeric(24,2)
            AS daily_eligible_pos_sales,

        round(sum(daily.actual_remittance_amount), 2)::numeric(24,2)
            AS daily_remittance_amount,

        round(sum(daily.cumulative_remittance_amount), 2)::numeric(24,2)
            AS cumulative_remittance_amount,

        round(sum(daily.receivable_balance_after), 2)::numeric(24,2)
            AS total_receivable_exposure_amount

    FROM msbf_m2.advance_daily_remittance_monitoring AS daily

    WHERE daily.module1_run_id =
          (SELECT run_id FROM run_context)

    GROUP BY
        daily.module1_run_id,
        daily.scenario_id,
        daily.monitoring_day_index
),
portfolio_comparison AS
(
    SELECT
        summary.module1_run_id,
        summary.scenario_id,
        summary.scenario_code,
        summary.monitoring_day_index,
        summary.monitoring_date,

        summary.opening_advance_count
            AS persisted_opening_advance_count,
        daily.opening_advance_count
            AS reproduced_opening_advance_count,

        summary.active_advance_count
            AS persisted_active_advance_count,
        daily.original_acceptance_active_advance_count,
        daily.generation_aligned_active_advance_count,

        summary.paid_off_count
            AS persisted_paid_off_count,
        daily.paid_off_count
            AS reproduced_paid_off_count,

        daily.payoff_event_advance_count,

        summary.daily_eligible_pos_sales
            AS persisted_daily_eligible_pos_sales,
        daily.daily_eligible_pos_sales
            AS reproduced_daily_eligible_pos_sales,

        summary.daily_remittance_amount
            AS persisted_daily_remittance_amount,
        daily.daily_remittance_amount
            AS reproduced_daily_remittance_amount,

        summary.cumulative_remittance_amount
            AS persisted_cumulative_remittance_amount,
        daily.cumulative_remittance_amount
            AS reproduced_cumulative_remittance_amount,

        summary.total_receivable_exposure_amount
            AS persisted_receivable_exposure_amount,
        daily.total_receivable_exposure_amount
            AS reproduced_receivable_exposure_amount,

        (
            summary.active_advance_count IS DISTINCT FROM
            daily.original_acceptance_active_advance_count
        ) AS original_active_count_mismatch_flag,

        (
            summary.active_advance_count IS DISTINCT FROM
            daily.generation_aligned_active_advance_count
        ) AS corrected_active_count_mismatch_flag,

        (
            summary.opening_advance_count IS DISTINCT FROM
                daily.opening_advance_count
            OR summary.active_advance_count IS DISTINCT FROM
                daily.original_acceptance_active_advance_count
            OR summary.paid_off_count IS DISTINCT FROM
                daily.paid_off_count
            OR summary.daily_eligible_pos_sales IS DISTINCT FROM
                daily.daily_eligible_pos_sales
            OR summary.daily_remittance_amount IS DISTINCT FROM
                daily.daily_remittance_amount
            OR summary.cumulative_remittance_amount IS DISTINCT FROM
                daily.cumulative_remittance_amount
            OR summary.total_receivable_exposure_amount IS DISTINCT FROM
                daily.total_receivable_exposure_amount
        ) AS original_portfolio_mismatch_flag,

        (
            summary.opening_advance_count IS DISTINCT FROM
                daily.opening_advance_count
            OR summary.active_advance_count IS DISTINCT FROM
                daily.generation_aligned_active_advance_count
            OR summary.paid_off_count IS DISTINCT FROM
                daily.paid_off_count
            OR summary.daily_eligible_pos_sales IS DISTINCT FROM
                daily.daily_eligible_pos_sales
            OR summary.daily_remittance_amount IS DISTINCT FROM
                daily.daily_remittance_amount
            OR summary.cumulative_remittance_amount IS DISTINCT FROM
                daily.cumulative_remittance_amount
            OR summary.total_receivable_exposure_amount IS DISTINCT FROM
                daily.total_receivable_exposure_amount
        ) AS corrected_portfolio_mismatch_flag

    FROM msbf_m2.portfolio_daily_monitoring_summary AS summary

    JOIN daily_reproduction AS daily
      ON daily.module1_run_id = summary.module1_run_id
     AND daily.scenario_id = summary.scenario_id
     AND daily.monitoring_day_index =
         summary.monitoring_day_index

    WHERE summary.module1_run_id =
          (SELECT run_id FROM run_context)
),
portfolio_diagnostics AS
(
    SELECT
        count(*)::bigint AS joined_portfolio_rows,

        count(*) FILTER
        (
            WHERE original_active_count_mismatch_flag
        )::bigint AS original_active_count_mismatches,

        count(*) FILTER
        (
            WHERE corrected_active_count_mismatch_flag
        )::bigint AS corrected_active_count_mismatches,

        count(*) FILTER
        (
            WHERE original_portfolio_mismatch_flag
        )::bigint AS original_portfolio_summary_mismatches,

        count(*) FILTER
        (
            WHERE corrected_portfolio_mismatch_flag
        )::bigint AS corrected_portfolio_summary_mismatches,

        count(*) FILTER
        (
            WHERE payoff_event_advance_count > 0
        )::bigint AS payoff_event_day_rows,

        coalesce
        (
            sum(payoff_event_advance_count),
            0
        )::bigint AS payoff_event_advance_rows

    FROM portfolio_comparison
),
physical AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_ctl.m2_5_policy_profile
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        )::bigint AS policy_rows,

        (
            SELECT count(*)
            FROM msbf_m2.portfolio_monitoring_status_definition
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        )::bigint AS status_rows,

        (
            SELECT count(*)
            FROM msbf_m2.portfolio_monitoring_alert_definition
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        )::bigint AS alert_rows,

        (
            SELECT count(*)
            FROM msbf_m2.portfolio_monitoring_reason_definition
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        )::bigint AS reason_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_monitoring_source_snapshot
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        )::bigint AS source_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_daily_remittance_monitoring
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        )::bigint AS daily_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_portfolio_monitoring_latest
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        )::bigint AS latest_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_portfolio_monitoring_archive
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        )::bigint AS archive_rows,

        (
            SELECT count(*)
            FROM msbf_m2.portfolio_daily_monitoring_summary
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        )::bigint AS portfolio_daily_rows,

        (
            SELECT count(*)
            FROM msbf_m2.v_m2_5_matched_monitoring_comparison
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        )::bigint AS comparison_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_portfolio_monitoring_latest
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
              AND paid_off_flag
        )::bigint AS paid_off_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_portfolio_monitoring_latest
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
              AND NOT paid_off_flag
        )::bigint AS open_monitoring_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_daily_remittance_monitoring
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
              AND stress_status_floor_applied_flag
        )::bigint AS stress_status_floor_rows,

        (
            SELECT round(sum(cumulative_remittance_amount), 2)
            FROM msbf_m2.advance_portfolio_monitoring_latest
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        ) AS total_remittance_amount,

        (
            SELECT round(sum(remaining_receivable_amount), 2)
            FROM msbf_m2.advance_portfolio_monitoring_latest
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        ) AS ending_receivable_exposure_amount,

        (
            SELECT count(*)
            FROM msbf_m2.v_m2_5_matched_monitoring_comparison
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
              AND stress_status_improvement_flag
        )::bigint AS stress_status_improvements,

        (
            SELECT count(*)
            FROM msbf_m2.advance_portfolio_monitoring_latest AS latest
            FULL OUTER JOIN
                 msbf_m2.advance_portfolio_monitoring_archive AS archive
              ON archive.module1_run_id = latest.module1_run_id
             AND archive.contract_version = latest.contract_version
             AND archive.scenario_id = latest.scenario_id
             AND archive.merchant_application_id =
                 latest.merchant_application_id
            WHERE coalesce
                  (
                      latest.module1_run_id,
                      archive.module1_run_id
                  ) = (SELECT run_id FROM run_context)
              AND
              (
                  latest.contract_row_hash IS DISTINCT FROM
                      archive.contract_row_hash
                  OR archive.contract_payload IS DISTINCT FROM
                     (to_jsonb(latest) - 'created_at')
              )
        )::bigint AS archive_mismatches,

        (
            SELECT count(*)
            FROM msbf_m2.portfolio_monitoring_reason_definition
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
              AND
              (
                  production_adverse_action_notice_flag
                  OR servicing_action_authorized_flag
              )
        )::bigint AS prohibited_reason_flags,

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
                  'real_debit_instruction',
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
        )::bigint AS prohibited_columns,

        (
            SELECT count(*)
            FROM msbf_ctl.acceptance_gate_result
            WHERE run_id =
                  (SELECT run_id FROM run_context)
              AND gate_id =
                  'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
        )::bigint AS acceptance_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.profile_resolution_error
            WHERE run_id =
                  (SELECT run_id FROM run_context)
              AND severity = 'BLOCKING'
        )::bigint AS blocking_errors,

        (
            SELECT canonical_entities
            FROM msbf_m2.v_m2_5_canonical_hash
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        )::bigint AS physical_canonical_entities,

        (
            SELECT combined_set_hash
            FROM msbf_m2.v_m2_5_canonical_hash
            WHERE module1_run_id =
                  (SELECT run_id FROM run_context)
        ) AS physical_combined_set_hash
)
SELECT
    run_context.run_id,
    run_context.run_status,
    registry.contract_status,

    controls.generation_evidence_rows,
    controls.positive_checks,
    controls.positive_passes,
    controls.positive_failures,
    controls.negative_checks,
    controls.negative_passes,
    controls.negative_failures,
    controls.failed_evidence_rows,

    physical.policy_rows,
    physical.status_rows,
    physical.alert_rows,
    physical.reason_rows,
    physical.source_rows,
    physical.daily_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.portfolio_daily_rows,
    physical.comparison_rows,
    physical.paid_off_rows,
    physical.open_monitoring_rows,
    physical.stress_status_floor_rows,
    physical.total_remittance_amount,
    physical.ending_receivable_exposure_amount,
    physical.stress_status_improvements,
    physical.archive_mismatches,
    physical.prohibited_reason_flags,
    physical.prohibited_columns,
    physical.acceptance_rows,
    physical.blocking_errors,
    physical.physical_canonical_entities,

    registry.canonical_entities AS registry_canonical_entities,
    registry.stress_status_floor_rows
        AS registry_stress_status_floor_rows,
    registry.total_remittance_amount
        AS registry_total_remittance_amount,
    registry.ending_receivable_exposure_amount
        AS registry_ending_receivable_exposure_amount,
    registry.contract_set_hash,
    registry.combined_set_hash,
    physical.physical_combined_set_hash,

    portfolio_diagnostics.joined_portfolio_rows,
    portfolio_diagnostics.original_active_count_mismatches,
    portfolio_diagnostics.corrected_active_count_mismatches,
    portfolio_diagnostics.original_portfolio_summary_mismatches,
    portfolio_diagnostics.corrected_portfolio_summary_mismatches,
    portfolio_diagnostics.payoff_event_day_rows,
    portfolio_diagnostics.payoff_event_advance_rows,

    CASE
        WHEN run_context.run_status = 'M2_5_VALIDATED'
         AND registry.contract_status = 'VALIDATED'

         AND controls.generation_evidence_rows = 24
         AND controls.positive_checks = 120
         AND controls.positive_passes = 120
         AND controls.positive_failures = 0
         AND controls.negative_checks = 20
         AND controls.negative_passes = 20
         AND controls.negative_failures = 0
         AND controls.failed_evidence_rows = 0

         AND physical.policy_rows = 1
         AND physical.status_rows = 6
         AND physical.alert_rows = 7
         AND physical.reason_rows = 24
         AND physical.source_rows = 59
         AND physical.daily_rows = 7080
         AND physical.latest_rows = 59
         AND physical.archive_rows = 59
         AND physical.portfolio_daily_rows = 240
         AND physical.comparison_rows = 15

         AND physical.paid_off_rows
             + physical.open_monitoring_rows = 59

         AND physical.stress_status_floor_rows IS NOT DISTINCT FROM
             registry.stress_status_floor_rows

         AND physical.total_remittance_amount IS NOT DISTINCT FROM
             registry.total_remittance_amount

         AND physical.ending_receivable_exposure_amount IS NOT DISTINCT FROM
             registry.ending_receivable_exposure_amount

         AND physical.stress_status_improvements = 0
         AND physical.archive_mismatches = 0
         AND physical.prohibited_reason_flags = 0
         AND physical.prohibited_columns = 0
         AND physical.acceptance_rows = 0
         AND physical.blocking_errors = 0

         AND registry.canonical_entities = 7536
         AND physical.physical_canonical_entities = 7536
         AND registry.combined_set_hash IS NOT DISTINCT FROM
             physical.physical_combined_set_hash
         AND registry.contract_set_hash IS NOT NULL
         AND registry.combined_set_hash IS NOT NULL

         AND portfolio_diagnostics.joined_portfolio_rows = 240
         AND portfolio_diagnostics.original_active_count_mismatches > 0
         AND portfolio_diagnostics.corrected_active_count_mismatches = 0
         AND portfolio_diagnostics.original_portfolio_summary_mismatches =
             portfolio_diagnostics.original_active_count_mismatches
         AND portfolio_diagnostics.corrected_portfolio_summary_mismatches = 0
         AND portfolio_diagnostics.payoff_event_day_rows =
             portfolio_diagnostics.original_active_count_mismatches
         AND portfolio_diagnostics.payoff_event_advance_rows > 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status

FROM run_context
CROSS JOIN registry
CROSS JOIN controls
CROSS JOIN physical
CROSS JOIN portfolio_diagnostics;

/* Result Set 02 — Payoff-event active-count mismatches under Program 169 v0.2. */
WITH daily_reproduction AS
(
    SELECT
        daily.module1_run_id,
        daily.scenario_id,
        daily.monitoring_day_index,
        count(*) FILTER
        (
            WHERE daily.receivable_balance_before > 0
        )::integer AS generation_aligned_active_advance_count,
        count(*) FILTER
        (
            WHERE NOT daily.paid_off_flag
        )::integer AS original_acceptance_active_advance_count,
        count(*) FILTER
        (
            WHERE daily.paid_off_flag
        )::integer AS paid_off_count,
        count(*) FILTER
        (
            WHERE daily.receivable_balance_before > 0
              AND daily.paid_off_flag
        )::integer AS payoff_event_advance_count
    FROM msbf_m2.advance_daily_remittance_monitoring AS daily
    WHERE daily.module1_run_id =
          (
              SELECT run_id
              FROM msbf_ctl.run_registry
              WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
                AND run_version = 1
          )
    GROUP BY
        daily.module1_run_id,
        daily.scenario_id,
        daily.monitoring_day_index
)
SELECT
    summary.scenario_code,
    summary.monitoring_day_index,
    summary.monitoring_date,
    summary.active_advance_count
        AS persisted_active_advance_count,
    daily.generation_aligned_active_advance_count,
    daily.original_acceptance_active_advance_count,
    summary.paid_off_count AS persisted_paid_off_count,
    daily.paid_off_count AS reproduced_paid_off_count,
    daily.payoff_event_advance_count
FROM msbf_m2.portfolio_daily_monitoring_summary AS summary
JOIN daily_reproduction AS daily
  ON daily.module1_run_id = summary.module1_run_id
 AND daily.scenario_id = summary.scenario_id
 AND daily.monitoring_day_index =
     summary.monitoring_day_index
WHERE summary.module1_run_id =
      (
          SELECT run_id
          FROM msbf_ctl.run_registry
          WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
            AND run_version = 1
      )
  AND summary.active_advance_count IS DISTINCT FROM
      daily.original_acceptance_active_advance_count
ORDER BY
    summary.scenario_code,
    summary.monitoring_day_index;

/* Result Set 03 — Corrected acceptance exceptions: zero rows required. */
WITH daily_reproduction AS
(
    SELECT
        daily.module1_run_id,
        daily.scenario_id,
        daily.monitoring_day_index,
        count(*)::integer AS opening_advance_count,
        count(*) FILTER
        (
            WHERE daily.receivable_balance_before > 0
        )::integer AS active_advance_count,
        count(*) FILTER
        (
            WHERE daily.paid_off_flag
        )::integer AS paid_off_count,
        round(sum(daily.source_eligible_pos_sales), 2)::numeric(24,2)
            AS daily_eligible_pos_sales,
        round(sum(daily.actual_remittance_amount), 2)::numeric(24,2)
            AS daily_remittance_amount,
        round(sum(daily.cumulative_remittance_amount), 2)::numeric(24,2)
            AS cumulative_remittance_amount,
        round(sum(daily.receivable_balance_after), 2)::numeric(24,2)
            AS total_receivable_exposure_amount
    FROM msbf_m2.advance_daily_remittance_monitoring AS daily
    WHERE daily.module1_run_id =
          (
              SELECT run_id
              FROM msbf_ctl.run_registry
              WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
                AND run_version = 1
          )
    GROUP BY
        daily.module1_run_id,
        daily.scenario_id,
        daily.monitoring_day_index
)
SELECT
    summary.scenario_code,
    summary.monitoring_day_index,
    summary.monitoring_date,
    summary.opening_advance_count,
    daily.opening_advance_count
        AS reproduced_opening_advance_count,
    summary.active_advance_count,
    daily.active_advance_count
        AS reproduced_active_advance_count,
    summary.paid_off_count,
    daily.paid_off_count
        AS reproduced_paid_off_count,
    summary.daily_eligible_pos_sales,
    daily.daily_eligible_pos_sales
        AS reproduced_daily_eligible_pos_sales,
    summary.daily_remittance_amount,
    daily.daily_remittance_amount
        AS reproduced_daily_remittance_amount,
    summary.cumulative_remittance_amount,
    daily.cumulative_remittance_amount
        AS reproduced_cumulative_remittance_amount,
    summary.total_receivable_exposure_amount,
    daily.total_receivable_exposure_amount
        AS reproduced_receivable_exposure_amount
FROM msbf_m2.portfolio_daily_monitoring_summary AS summary
JOIN daily_reproduction AS daily
  ON daily.module1_run_id = summary.module1_run_id
 AND daily.scenario_id = summary.scenario_id
 AND daily.monitoring_day_index =
     summary.monitoring_day_index
WHERE summary.module1_run_id =
      (
          SELECT run_id
          FROM msbf_ctl.run_registry
          WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
            AND run_version = 1
      )
  AND
  (
      summary.opening_advance_count IS DISTINCT FROM
          daily.opening_advance_count
      OR summary.active_advance_count IS DISTINCT FROM
          daily.active_advance_count
      OR summary.paid_off_count IS DISTINCT FROM
          daily.paid_off_count
      OR summary.daily_eligible_pos_sales IS DISTINCT FROM
          daily.daily_eligible_pos_sales
      OR summary.daily_remittance_amount IS DISTINCT FROM
          daily.daily_remittance_amount
      OR summary.cumulative_remittance_amount IS DISTINCT FROM
          daily.cumulative_remittance_amount
      OR summary.total_receivable_exposure_amount IS DISTINCT FROM
          daily.total_receivable_exposure_amount
  )
ORDER BY
    summary.scenario_code,
    summary.monitoring_day_index;
