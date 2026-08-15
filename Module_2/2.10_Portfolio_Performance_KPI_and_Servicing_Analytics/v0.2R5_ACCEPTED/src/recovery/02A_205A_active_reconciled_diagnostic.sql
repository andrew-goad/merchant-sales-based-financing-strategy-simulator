/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 205A_msbf_m2_10_failed_active_reconciled_preflight_diagnostic_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Run only after stopping failed Program 205 and executing ROLLBACK. This
read-only diagnostic proves the exact accepted M2.9 active/reconciled source
state and distinguishes the governed literals from stale shorthand literals
that can incorrectly return zero rows.

Writes
------
None.

Required result
---------------
governed_active_reconciled_rows = 1
stale_reassessment_due_rows = 0
stale_active_after_retry_rows = 0
diagnostic_status = PASS
============================================================================ */

SET statement_timeout='15min';
SET jit=off;

WITH run_context AS
(
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
),
source_summary AS
(
    SELECT
        count(*)::bigint AS source_rows,

        count(*) FILTER
        (
            WHERE reconciliation_outcome_code=
                  'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
        )::bigint AS reconciled_after_retry_rows,

        count(*) FILTER
        (
            WHERE certified_state_code=
                  'CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
        )::bigint AS certified_reassessment_after_retry_rows,

        count(*) FILTER
        (
            WHERE reconciliation_outcome_code=
                  'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
              AND certified_state_code=
                  'CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
              AND state_certified_flag IS TRUE
              AND active_state_flag IS TRUE
              AND closed_state_flag IS FALSE
              AND review_hold_state_flag IS FALSE
              AND exception_resolved_flag IS TRUE
              AND unresolved_exception_count=0
              AND reconciliation_variance_amount=0
              AND exposure_variance_amount=0
        )::bigint AS governed_active_reconciled_rows,

        count(*) FILTER
        (
            WHERE certified_state_code='CERTIFIED_REASSESSMENT_DUE'
        )::bigint AS stale_reassessment_due_rows,

        count(*) FILTER
        (
            WHERE certified_state_code='CERTIFIED_ACTIVE_AFTER_RETRY'
        )::bigint AS stale_active_after_retry_rows,

        count(*) FILTER
        (
            WHERE reconciliation_outcome_code=
                  'PAYMENT_ACTIVITY_RECONCILED'
        )::bigint AS stale_payment_activity_reconciled_rows,

        max(reconciliation_outcome_code)
            FILTER(WHERE active_state_flag)
            AS observed_active_reconciliation_outcome_code,

        max(certified_state_code)
            FILTER(WHERE active_state_flag)
            AS observed_active_certified_state_code,

        count(*) FILTER
        (
            WHERE active_state_flag
        )::bigint AS active_state_rows,

        round
        (
            sum(certified_exposure_amount)
            FILTER(WHERE active_state_flag),
            2
        ) AS active_certified_exposure_amount

    FROM msbf_m2.application_payment_reconciliation_certification_latest
    WHERE module1_run_id=(SELECT run_id FROM run_context)
)
SELECT
    run_context.run_id,
    run_context.run_status,
    source_summary.source_rows,
    source_summary.reconciled_after_retry_rows,
    source_summary.certified_reassessment_after_retry_rows,
    source_summary.governed_active_reconciled_rows,
    source_summary.stale_reassessment_due_rows,
    source_summary.stale_active_after_retry_rows,
    source_summary.stale_payment_activity_reconciled_rows,
    source_summary.observed_active_reconciliation_outcome_code,
    source_summary.observed_active_certified_state_code,
    source_summary.active_state_rows,
    source_summary.active_certified_exposure_amount,

    CASE
        WHEN run_context.run_status='M2_9_ACCEPTED'
         AND source_summary.source_rows=59
         AND source_summary.reconciled_after_retry_rows=1
         AND source_summary.certified_reassessment_after_retry_rows=1
         AND source_summary.governed_active_reconciled_rows=1
         AND source_summary.stale_reassessment_due_rows=0
         AND source_summary.stale_active_after_retry_rows=0
         AND source_summary.stale_payment_activity_reconciled_rows=0
         AND source_summary.observed_active_reconciliation_outcome_code=
             'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
         AND source_summary.observed_active_certified_state_code=
             'CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
         AND source_summary.active_state_rows=1
         AND source_summary.active_certified_exposure_amount=323.79
        THEN 'PASS'
        ELSE 'FAIL'
    END AS diagnostic_status

FROM run_context
CROSS JOIN source_summary;
