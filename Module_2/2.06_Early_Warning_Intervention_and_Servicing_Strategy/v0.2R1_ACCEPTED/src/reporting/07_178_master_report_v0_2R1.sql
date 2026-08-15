/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.6 — Early Warning, Intervention & Servicing Strategy

Program     : 178_MSBF_M2_6_Master_Report_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Produce one executive/governance master-report row after formal M2.6
acceptance.

Revision v0.2R1
---------------
The v0.2 master report attempted to evaluate execution-boundary flags from
`msbf_m2.advance_intervention_strategy_latest`. Those six flags are governed
physical fields of `msbf_m2.advance_intervention_strategy_snapshot` and are
intentionally not part of the latest consumption contract.

v0.2R1 therefore:
- preserves strategy distribution and exposure metrics from the accepted
  latest contract;
- evaluates all six executed-servicing and notice flags from the governed
  strategy snapshot, matching Programs 175, 177, and Result Set 24 of
  Program 179;
- changes no persistent data, lifecycle state, decision, hash, count,
  methodology, or report output column.

Writes
------
None.

Required result
---------------
overall_m2_6_status = PASS.
============================================================================ */

SET statement_timeout = '30min';
SET jit = off;

WITH run_context AS
(
    SELECT
        run.run_id,
        run.run_code,
        run.run_version,
        run.run_status
    FROM msbf_ctl.run_registry AS run
    WHERE run.run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run.run_version = 1
),
policy AS
(
    SELECT
        policy.policy_code,
        policy.policy_status,
        policy.methodology_version,
        policy.contract_code,
        policy.contract_version,
        policy.schema_version,
        policy.source_m2_5_combined_hash
    FROM msbf_ctl.m2_6_policy_profile AS policy
    WHERE policy.module1_run_id =
          (SELECT run_id FROM run_context)
),
registry AS
(
    SELECT
        registry.contract_status,
        registry.policy_rows,
        registry.outcome_rows,
        registry.action_rows,
        registry.reason_rows,
        registry.source_rows,
        registry.strategy_rows,
        registry.portfolio_summary_rows,
        registry.latest_rows,
        registry.archive_rows,
        registry.comparison_rows,
        registry.canonical_entities,
        registry.policy_set_hash,
        registry.outcome_set_hash,
        registry.action_set_hash,
        registry.reason_set_hash,
        registry.source_set_hash,
        registry.strategy_set_hash,
        registry.portfolio_summary_set_hash,
        registry.latest_set_hash,
        registry.archive_set_hash,
        registry.contract_set_hash,
        registry.combined_set_hash
    FROM msbf_ctl.m2_6_intervention_strategy_contract_registry AS registry
    WHERE registry.module1_run_id =
          (SELECT run_id FROM run_context)
),
gate AS
(
    SELECT
        gate.result_status AS gate_status
    FROM msbf_ctl.acceptance_gate_result AS gate
    WHERE gate.run_id = (SELECT run_id FROM run_context)
      AND gate.gate_id =
          'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'
      AND gate.review_version = 1
),
evidence AS
(
    SELECT
        count(*) FILTER
        (
            WHERE evidence.evidence_code LIKE 'M2_6_POS_%'
              AND evidence.status = 'PASS'
        ) AS positive_passes,

        count(*) FILTER
        (
            WHERE evidence.evidence_code LIKE 'M2_6_POS_%'
        ) AS positive_checks,

        count(*) FILTER
        (
            WHERE evidence.evidence_code LIKE 'M2_6_NEG_%'
              AND evidence.status = 'PASS'
        ) AS negative_passes,

        count(*) FILTER
        (
            WHERE evidence.evidence_code LIKE 'M2_6_NEG_%'
        ) AS negative_checks,

        count(*) FILTER
        (
            WHERE evidence.evidence_code LIKE 'M2_6_%'
              AND evidence.evidence_code NOT LIKE 'M2_6_POS_%'
              AND evidence.evidence_code NOT LIKE 'M2_6_NEG_%'
              AND evidence.evidence_code <> 'M2_6_ACCEPTANCE_SUMMARY'
        ) AS generation_evidence_rows,

        count(*) FILTER
        (
            WHERE evidence.evidence_code = 'M2_6_ACCEPTANCE_SUMMARY'
              AND evidence.status = 'PASS'
        ) AS acceptance_evidence_rows,

        count(*) FILTER
        (
            WHERE evidence.evidence_code LIKE 'M2_6_%'
              AND evidence.status = 'FAIL'
        ) AS failed_evidence_rows

    FROM msbf_ctl.run_evidence AS evidence
    WHERE evidence.run_id =
          (SELECT run_id FROM run_context)
),
strategy AS
(
    SELECT
        count(*) AS strategy_rows,

        count(*) FILTER
        (
            WHERE latest.strategy_outcome_code =
                  'CLOSED_NO_FURTHER_ACTION'
        ) AS closed_no_action_rows,

        count(*) FILTER
        (
            WHERE latest.strategy_outcome_code =
                  'TARGETED_MERCHANT_OUTREACH_REVIEW'
        ) AS outreach_review_rows,

        count(*) FILTER
        (
            WHERE latest.strategy_outcome_code =
                  'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW'
        ) AS temporary_adjustment_review_rows,

        count(*) FILTER
        (
            WHERE latest.recommended_action_flag
        ) AS recommended_action_rows,

        round
        (
            coalesce
            (
                sum(latest.recommended_action_exposure_amount),
                0
            ),
            2
        ) AS recommended_action_exposure_amount

    FROM msbf_m2.advance_intervention_strategy_latest AS latest
    WHERE latest.module1_run_id =
          (SELECT run_id FROM run_context)
),
boundary AS
(
    /*
    Execution-boundary fields are intentionally retained on the governed
    strategy snapshot rather than the latest consumption contract.
    */
    SELECT
        count(*) FILTER
        (
            WHERE snapshot.merchant_contact_executed_flag
               OR snapshot.payment_change_executed_flag
               OR snapshot.write_off_or_charge_off_executed_flag
               OR snapshot.legal_or_collection_action_executed_flag
               OR snapshot.external_notice_generated_flag
               OR snapshot.production_adverse_action_notice_flag
        ) AS executed_boundary_rows

    FROM msbf_m2.advance_intervention_strategy_snapshot AS snapshot
    WHERE snapshot.module1_run_id =
          (SELECT run_id FROM run_context)
),
diagnostics AS
(
    SELECT
        (
            SELECT canonical.canonical_entities
            FROM msbf_m2.v_m2_6_canonical_hash AS canonical
            WHERE canonical.module1_run_id =
                  (SELECT run_id FROM run_context)
        ) AS physical_canonical_entities,

        (
            SELECT canonical.combined_set_hash
            FROM msbf_m2.v_m2_6_canonical_hash AS canonical
            WHERE canonical.module1_run_id =
                  (SELECT run_id FROM run_context)
        ) AS physical_combined_set_hash,

        (
            SELECT count(*)
            FROM msbf_m2.v_m2_6_matched_scenario_comparison AS comparison
            WHERE comparison.module1_run_id =
                  (SELECT run_id FROM run_context)
              AND
              (
                  comparison.stress_strategy_improvement_flag
                  OR comparison.stress_action_improvement_flag
              )
        ) AS stress_improvement_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_intervention_strategy_latest AS latest

            FULL OUTER JOIN
                 msbf_m2.advance_intervention_strategy_archive AS archive
              ON archive.module1_run_id = latest.module1_run_id
             AND archive.contract_version = latest.contract_version
             AND archive.scenario_id = latest.scenario_id
             AND archive.merchant_application_id =
                 latest.merchant_application_id

            WHERE coalesce
                  (
                      latest.module1_run_id,
                      archive.module1_run_id
                  ) =
                  (SELECT run_id FROM run_context)
              AND
              (
                  latest.contract_row_hash IS DISTINCT FROM
                      archive.contract_row_hash
                  OR archive.contract_payload IS DISTINCT FROM
                     (to_jsonb(latest) - 'created_at')
              )
        ) AS archive_mismatches,

        (
            SELECT count(*)
            FROM information_schema.tables AS table_info
            WHERE table_info.table_schema IN ('msbf_ctl','msbf_m2')
              AND lower(table_info.table_name) LIKE 'm2_7%'
        ) AS premature_m2_7_tables
)
SELECT
    run_context.run_code,
    run_context.run_version,
    run_context.run_status,

    policy.policy_code,
    policy.policy_status,
    policy.methodology_version,
    policy.contract_code,
    policy.contract_version,
    policy.schema_version,
    policy.source_m2_5_combined_hash,

    registry.contract_status,
    gate.gate_status,

    registry.policy_rows,
    registry.outcome_rows,
    registry.action_rows,
    registry.reason_rows,
    registry.source_rows,
    registry.strategy_rows,
    registry.portfolio_summary_rows,
    registry.latest_rows,
    registry.archive_rows,
    registry.comparison_rows,
    registry.canonical_entities,

    strategy.closed_no_action_rows,
    strategy.outreach_review_rows,
    strategy.temporary_adjustment_review_rows,
    strategy.recommended_action_rows,
    strategy.recommended_action_exposure_amount,

    evidence.positive_passes,
    evidence.positive_checks,
    evidence.negative_passes,
    evidence.negative_checks,
    evidence.generation_evidence_rows,
    evidence.acceptance_evidence_rows,
    evidence.failed_evidence_rows,

    diagnostics.physical_canonical_entities,
    diagnostics.stress_improvement_rows,
    diagnostics.archive_mismatches,
    diagnostics.premature_m2_7_tables,

    registry.policy_set_hash,
    registry.outcome_set_hash,
    registry.action_set_hash,
    registry.reason_set_hash,
    registry.source_set_hash,
    registry.strategy_set_hash,
    registry.portfolio_summary_set_hash,
    registry.latest_set_hash,
    registry.archive_set_hash,
    registry.contract_set_hash,
    registry.combined_set_hash,

    CASE
        WHEN run_context.run_status = 'M2_6_ACCEPTED'
         AND policy.policy_status = 'APPROVED'
         AND registry.contract_status = 'ACCEPTED'
         AND gate.gate_status = 'PASS'

         AND registry.canonical_entities = 284
         AND diagnostics.physical_canonical_entities = 284
         AND registry.combined_set_hash IS NOT DISTINCT FROM
             diagnostics.physical_combined_set_hash

         AND evidence.positive_passes = 120
         AND evidence.positive_checks = 120
         AND evidence.negative_passes = 20
         AND evidence.negative_checks = 20
         AND evidence.generation_evidence_rows = 24
         AND evidence.acceptance_evidence_rows = 1
         AND evidence.failed_evidence_rows = 0

         AND boundary.executed_boundary_rows = 0
         AND diagnostics.stress_improvement_rows = 0
         AND diagnostics.archive_mismatches = 0
         AND diagnostics.premature_m2_7_tables = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS overall_m2_6_status

FROM run_context
CROSS JOIN policy
CROSS JOIN registry
CROSS JOIN gate
CROSS JOIN evidence
CROSS JOIN strategy
CROSS JOIN boundary
CROSS JOIN diagnostics;
