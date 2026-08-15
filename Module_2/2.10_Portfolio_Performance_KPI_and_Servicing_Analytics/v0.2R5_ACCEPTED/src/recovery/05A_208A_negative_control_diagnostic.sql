/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 208A_msbf_m2_10_failed_negative_control_recovery_and_applicability_diagnostic_v0_2R2.sql
Version     : v0.2R2

Purpose
-------
Run only after stopping failed Program 208 and executing ROLLBACK. Prove that
its transaction left no partial negative-control or acceptance evidence,
preserve the validated M2.10 population, identify the legacy KPI-applicability
constraint's SQL three-valued-logic gap, and confirm that all existing KPI
rows satisfy the intended strict applicability/value contract.

Writes
------
None.

Required result
---------------
diagnostic_status = PASS. For the current pre-repair database,
repair_required_flag = true.
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
    SELECT contract_status,source_rows,account_performance_rows,
           scope_summary_rows,kpi_snapshot_rows,queue_summary_rows,
           latest_rows,archive_rows,comparison_rows,canonical_entities,
           combined_set_hash
    FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
evidence AS
(
    SELECT
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_10_POS_%' AND status='PASS'
        )::bigint AS positive_pass_rows,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_10_POS_%'
        )::bigint AS positive_rows,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_10_NEG_%'
        )::bigint AS negative_rows,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_10_%'
              AND evidence_code NOT LIKE 'M2_10_POS_%'
              AND evidence_code NOT LIKE 'M2_10_NEG_%'
              AND evidence_code<>'M2_10_ACCEPTANCE_SUMMARY'
        )::bigint AS generation_rows,
        count(*) FILTER
        (
            WHERE evidence_code='M2_10_ACCEPTANCE_SUMMARY'
        )::bigint AS acceptance_evidence_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM run_context)
),
gate_state AS
(
    SELECT count(*)::bigint AS acceptance_gate_rows
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM run_context)
      AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
),
constraint_state AS
(
    SELECT
        count(*)::bigint AS constraint_rows,
        bool_and(constraint_record.convalidated) AS constraint_validated_flag,
        max(pg_get_constraintdef(constraint_record.oid)) AS constraint_definition,
        bool_or
        (
            position
            (
                'kpi_value_numeric IS NULL'
                IN pg_get_constraintdef(constraint_record.oid)
            )>0
            AND position
            (
                'kpi_value_text IS NULL'
                IN pg_get_constraintdef(constraint_record.oid)
            )>0
            AND position
            (
                'kpi_value_text IS NOT NULL'
                IN pg_get_constraintdef(constraint_record.oid)
            )>0
        ) AS strict_constraint_installed_flag
    FROM pg_constraint AS constraint_record
    WHERE constraint_record.conrelid=
          'msbf_m2.portfolio_kpi_snapshot'::regclass
      AND constraint_record.conname='ck_m2_10_kpi_applicability'
),
physical_state AS
(
    SELECT
        count(*)::bigint AS kpi_rows,
        count(*) FILTER
        (
            WHERE NOT
            (
                (
                    applicable_flag IS TRUE
                    AND kpi_value_numeric IS NOT NULL
                    AND kpi_value_text IS NULL
                )
                OR
                (
                    applicable_flag IS FALSE
                    AND kpi_value_numeric IS NULL
                    AND kpi_value_text IS NOT NULL
                    AND kpi_value_text='NOT_APPLICABLE'
                )
            )
        )::bigint AS strict_applicability_violations
    FROM msbf_m2.portfolio_kpi_snapshot
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
logic_probe AS
(
    SELECT
        (
            (FALSE AND 1.000000::numeric IS NOT NULL)
            OR
            (NOT FALSE AND NULL::text='NOT_APPLICABLE')
        ) AS legacy_invalid_expression_result,

        (
            (
                FALSE IS TRUE
                AND 1.000000::numeric IS NOT NULL
                AND NULL::text IS NULL
            )
            OR
            (
                FALSE IS FALSE
                AND 1.000000::numeric IS NULL
                AND NULL::text IS NOT NULL
                AND NULL::text='NOT_APPLICABLE'
            )
        ) AS strict_invalid_expression_result
)
SELECT
    run_context.run_status,
    registry.contract_status,
    registry.source_rows,
    registry.account_performance_rows,
    registry.scope_summary_rows,
    registry.kpi_snapshot_rows,
    registry.queue_summary_rows,
    registry.latest_rows,
    registry.archive_rows,
    registry.comparison_rows,
    registry.canonical_entities,
    registry.combined_set_hash,

    evidence.positive_pass_rows,
    evidence.positive_rows,
    evidence.negative_rows,
    evidence.generation_rows,
    evidence.acceptance_evidence_rows,
    gate_state.acceptance_gate_rows,

    constraint_state.constraint_rows,
    constraint_state.constraint_validated_flag,
    constraint_state.constraint_definition,
    constraint_state.strict_constraint_installed_flag,
    NOT coalesce(constraint_state.strict_constraint_installed_flag,FALSE)
        AS repair_required_flag,

    physical_state.kpi_rows,
    physical_state.strict_applicability_violations,

    logic_probe.legacy_invalid_expression_result,
    logic_probe.legacy_invalid_expression_result IS NULL
        AS legacy_check_accepts_invalid_row_flag,
    logic_probe.strict_invalid_expression_result,
    logic_probe.strict_invalid_expression_result IS FALSE
        AS strict_check_rejects_invalid_row_flag,

    CASE
        WHEN run_context.run_status='M2_10_VALIDATED'
         AND registry.contract_status='VALIDATED'
         AND registry.source_rows=59
         AND registry.account_performance_rows=59
         AND registry.scope_summary_rows=3
         AND registry.kpi_snapshot_rows=72
         AND registry.queue_summary_rows=3
         AND registry.latest_rows=59
         AND registry.archive_rows=59
         AND registry.comparison_rows=15
         AND registry.canonical_entities=370
         AND evidence.positive_pass_rows=120
         AND evidence.positive_rows=120
         AND evidence.negative_rows=0
         AND evidence.generation_rows=24
         AND evidence.acceptance_evidence_rows=0
         AND gate_state.acceptance_gate_rows=0
         AND constraint_state.constraint_rows=1
         AND constraint_state.constraint_validated_flag
         AND physical_state.kpi_rows=72
         AND physical_state.strict_applicability_violations=0
         AND logic_probe.legacy_invalid_expression_result IS NULL
         AND logic_probe.strict_invalid_expression_result IS FALSE
        THEN 'PASS'
        ELSE 'FAIL'
    END AS diagnostic_status
FROM run_context
CROSS JOIN registry
CROSS JOIN evidence
CROSS JOIN gate_state
CROSS JOIN constraint_state
CROSS JOIN physical_state
CROSS JOIN logic_probe;
