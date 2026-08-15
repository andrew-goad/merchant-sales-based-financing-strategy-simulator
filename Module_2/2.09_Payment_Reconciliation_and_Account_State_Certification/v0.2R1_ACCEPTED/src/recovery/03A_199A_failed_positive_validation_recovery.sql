/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.9 — Payment Reconciliation, Exception Resolution
             & Account State Certification

Program     : 199A_msbf_m2_9_failed_positive_validation_recovery_check_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Run only after stopping failed Program 199 and executing ROLLBACK. Prove that
the failed positive-validation transaction left no partial M2.9 positive,
negative, or acceptance evidence; preserved the committed Program 198
population and generated lifecycle; and confirm the corrected semantics for
the three defective v0.2 controls.

Writes
------
None.

Required result
---------------
recovery_status = PASS.
============================================================================ */

SET statement_timeout='25min';
SET jit=off;

WITH run_context AS
(
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
),
registry AS
(
    SELECT
        contract_status,
        account_source_rows,
        payment_source_rows,
        transition_source_rows,
        payment_reconciliation_rows,
        exception_case_rows,
        account_reconciliation_rows,
        state_certification_rows,
        latest_rows,
        archive_rows,
        comparison_rows,
        canonical_entities,
        combined_set_hash
    FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
evidence_state AS
(
    SELECT
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_9_POS_%'
        )::bigint AS positive_evidence_rows,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_9_NEG_%'
        )::bigint AS negative_evidence_rows,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_9_%'
              AND evidence_code NOT LIKE 'M2_9_POS_%'
              AND evidence_code NOT LIKE 'M2_9_NEG_%'
              AND evidence_code<>'M2_9_ACCEPTANCE_SUMMARY'
        )::bigint AS generation_evidence_rows,

        count(*) FILTER
        (
            WHERE evidence_code='M2_9_ACCEPTANCE_SUMMARY'
        )::bigint AS acceptance_evidence_rows

    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM run_context)
),
gate_state AS
(
    SELECT count(*)::bigint AS acceptance_gate_rows
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM run_context)
      AND gate_id=
          'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'
),
corrected_controls AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.payment_event_reconciliation_snapshot
            WHERE module1_run_id=(SELECT run_id FROM run_context)
              AND payment_status_code='SIMULATED_RETURNED'
              AND exception_case_required_flag
              AND NOT exception_resolved_flag
        )::bigint AS returned_event_exception_open_rows,

        (
            SELECT count(*)
            FROM msbf_m2.payment_event_reconciliation_snapshot
            WHERE module1_run_id=(SELECT run_id FROM run_context)
              AND payment_status_code='SIMULATED_RETRY_SETTLED'
              AND exception_resolved_flag
        )::bigint AS retry_event_resolution_rows,

        (
            SELECT count(*)
            FROM msbf_m2.payment_exception_case_snapshot
            WHERE module1_run_id=(SELECT run_id FROM run_context)
              AND synthetic_exception_case_id NOT LIKE 'MSBF_EXC_%'
        )::bigint AS exception_identifier_shape_errors,

        (
            SELECT count(*)
            FROM msbf_m2.payment_event_reconciliation_snapshot AS reconciliation
            LEFT JOIN msbf_m2.payment_reconciliation_source_event AS source
              ON source.module1_run_id=reconciliation.module1_run_id
             AND source.scenario_id=reconciliation.scenario_id
             AND source.merchant_application_id=
                 reconciliation.merchant_application_id
             AND source.event_sequence=reconciliation.event_sequence
            WHERE reconciliation.module1_run_id=
                  (SELECT run_id FROM run_context)
              AND
              (
                  source.row_hash IS NULL
                  OR reconciliation.source_event_row_hash
                     IS DISTINCT FROM source.row_hash
              )
        )::bigint AS event_source_snapshot_lineage_errors
)
SELECT
    run_context.run_status,
    registry.contract_status,

    registry.account_source_rows,
    registry.payment_source_rows,
    registry.transition_source_rows,
    registry.payment_reconciliation_rows,
    registry.exception_case_rows,
    registry.account_reconciliation_rows,
    registry.state_certification_rows,
    registry.latest_rows,
    registry.archive_rows,
    registry.comparison_rows,
    registry.canonical_entities,
    registry.combined_set_hash,

    evidence_state.positive_evidence_rows,
    evidence_state.negative_evidence_rows,
    evidence_state.generation_evidence_rows,
    evidence_state.acceptance_evidence_rows,
    gate_state.acceptance_gate_rows,

    corrected_controls.returned_event_exception_open_rows,
    corrected_controls.retry_event_resolution_rows,
    corrected_controls.exception_identifier_shape_errors,
    corrected_controls.event_source_snapshot_lineage_errors,

    CASE
        WHEN run_context.run_status='M2_9_GENERATED'
         AND registry.contract_status='GENERATED'

         AND registry.account_source_rows=59
         AND registry.payment_source_rows=7
         AND registry.transition_source_rows=67
         AND registry.payment_reconciliation_rows=7
         AND registry.exception_case_rows=1
         AND registry.account_reconciliation_rows=59
         AND registry.state_certification_rows=59
         AND registry.latest_rows=59
         AND registry.archive_rows=59
         AND registry.comparison_rows=15
         AND registry.canonical_entities=438

         AND evidence_state.positive_evidence_rows=0
         AND evidence_state.negative_evidence_rows=0
         AND evidence_state.generation_evidence_rows=24
         AND evidence_state.acceptance_evidence_rows=0
         AND gate_state.acceptance_gate_rows=0

         AND corrected_controls.returned_event_exception_open_rows=1
         AND corrected_controls.retry_event_resolution_rows=1
         AND corrected_controls.exception_identifier_shape_errors=0
         AND corrected_controls.event_source_snapshot_lineage_errors=0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status

FROM run_context
CROSS JOIN registry
CROSS JOIN evidence_state
CROSS JOIN gate_state
CROSS JOIN corrected_controls;
