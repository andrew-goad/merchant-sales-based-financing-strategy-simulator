/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.6 — Early Warning, Intervention & Servicing Strategy

Program     : 178A_msbf_m2_6_failed_master_report_boundary_source_recovery_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Provide a read-only proof of the Program 178 v0.2 report defect and confirm
that Programs 172 through 177 remain accepted and authoritative.

The executed-servicing boundary fields exist on:
    msbf_m2.advance_intervention_strategy_snapshot

They are intentionally absent from:
    msbf_m2.advance_intervention_strategy_latest

Writes
------
None.

Required results
----------------
Result Set 01: recovery_status = PASS.
Result Set 02: headers retained and zero executed-boundary rows.
============================================================================ */

SET statement_timeout = '15min';
SET jit = off;

WITH run_context AS
(
    SELECT
        run.run_id,
        run.run_status
    FROM msbf_ctl.run_registry AS run
    WHERE run.run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run.run_version = 1
),
registry AS
(
    SELECT
        registry.contract_status,
        registry.strategy_rows,
        registry.latest_rows,
        registry.archive_rows,
        registry.canonical_entities,
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
            WHERE evidence.evidence_code LIKE 'M2_6_NEG_%'
              AND evidence.status = 'PASS'
        ) AS negative_passes,

        count(*) FILTER
        (
            WHERE evidence.evidence_code LIKE 'M2_6_%'
              AND evidence.status = 'FAIL'
        ) AS failed_evidence_rows,

        count(*) FILTER
        (
            WHERE evidence.evidence_code = 'M2_6_ACCEPTANCE_SUMMARY'
              AND evidence.status = 'PASS'
        ) AS acceptance_evidence_rows

    FROM msbf_ctl.run_evidence AS evidence
    WHERE evidence.run_id =
          (SELECT run_id FROM run_context)
),
schema_inventory AS
(
    SELECT
        count(*) FILTER
        (
            WHERE column_info.table_name =
                  'advance_intervention_strategy_snapshot'
        ) AS snapshot_boundary_columns,

        count(*) FILTER
        (
            WHERE column_info.table_name =
                  'advance_intervention_strategy_latest'
        ) AS latest_boundary_columns

    FROM information_schema.columns AS column_info
    WHERE column_info.table_schema = 'msbf_m2'
      AND column_info.table_name IN
          (
              'advance_intervention_strategy_snapshot',
              'advance_intervention_strategy_latest'
          )
      AND column_info.column_name IN
          (
              'merchant_contact_executed_flag',
              'payment_change_executed_flag',
              'write_off_or_charge_off_executed_flag',
              'legal_or_collection_action_executed_flag',
              'external_notice_generated_flag',
              'production_adverse_action_notice_flag'
          )
),
physical AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.advance_intervention_strategy_snapshot AS snapshot
            WHERE snapshot.module1_run_id =
                  (SELECT run_id FROM run_context)
        ) AS strategy_snapshot_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_intervention_strategy_latest AS latest
            WHERE latest.module1_run_id =
                  (SELECT run_id FROM run_context)
        ) AS strategy_latest_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_intervention_strategy_archive AS archive
            WHERE archive.module1_run_id =
                  (SELECT run_id FROM run_context)
        ) AS strategy_archive_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_intervention_strategy_snapshot AS snapshot
            WHERE snapshot.module1_run_id =
                  (SELECT run_id FROM run_context)
              AND
              (
                  snapshot.merchant_contact_executed_flag
                  OR snapshot.payment_change_executed_flag
                  OR snapshot.write_off_or_charge_off_executed_flag
                  OR snapshot.legal_or_collection_action_executed_flag
                  OR snapshot.external_notice_generated_flag
                  OR snapshot.production_adverse_action_notice_flag
              )
        ) AS executed_boundary_rows,

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
        ) AS physical_combined_set_hash
)
SELECT
    run_context.run_status,
    registry.contract_status,
    gate.gate_status,

    registry.strategy_rows,
    registry.latest_rows,
    registry.archive_rows,
    registry.canonical_entities,

    physical.strategy_snapshot_rows,
    physical.strategy_latest_rows,
    physical.strategy_archive_rows,
    physical.physical_canonical_entities,

    evidence.positive_passes,
    evidence.negative_passes,
    evidence.failed_evidence_rows,
    evidence.acceptance_evidence_rows,

    schema_inventory.snapshot_boundary_columns,
    schema_inventory.latest_boundary_columns,
    physical.executed_boundary_rows,

    registry.combined_set_hash,
    physical.physical_combined_set_hash,

    CASE
        WHEN run_context.run_status = 'M2_6_ACCEPTED'
         AND registry.contract_status = 'ACCEPTED'
         AND gate.gate_status = 'PASS'

         AND registry.strategy_rows = 59
         AND registry.latest_rows = 59
         AND registry.archive_rows = 59
         AND registry.canonical_entities = 284

         AND physical.strategy_snapshot_rows = 59
         AND physical.strategy_latest_rows = 59
         AND physical.strategy_archive_rows = 59
         AND physical.physical_canonical_entities = 284

         AND evidence.positive_passes = 120
         AND evidence.negative_passes = 20
         AND evidence.failed_evidence_rows = 0
         AND evidence.acceptance_evidence_rows = 1

         AND schema_inventory.snapshot_boundary_columns = 6
         AND schema_inventory.latest_boundary_columns = 0
         AND physical.executed_boundary_rows = 0

         AND registry.combined_set_hash IS NOT DISTINCT FROM
             physical.physical_combined_set_hash
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status

FROM run_context
CROSS JOIN registry
CROSS JOIN gate
CROSS JOIN evidence
CROSS JOIN schema_inventory
CROSS JOIN physical;

/* Result Set 02 — Executed-boundary exceptions; zero rows required. */
SELECT
    snapshot.scenario_code,
    snapshot.merchant_application_id,
    snapshot.synthetic_account_id,
    snapshot.synthetic_advance_id,
    snapshot.merchant_contact_executed_flag,
    snapshot.payment_change_executed_flag,
    snapshot.write_off_or_charge_off_executed_flag,
    snapshot.legal_or_collection_action_executed_flag,
    snapshot.external_notice_generated_flag,
    snapshot.production_adverse_action_notice_flag
FROM msbf_m2.advance_intervention_strategy_snapshot AS snapshot
WHERE snapshot.module1_run_id =
      (
          SELECT run.run_id
          FROM msbf_ctl.run_registry AS run
          WHERE run.run_code = 'M1_V0_2_BASELINE_BUILD'
            AND run.run_version = 1
      )
  AND
  (
      snapshot.merchant_contact_executed_flag
      OR snapshot.payment_change_executed_flag
      OR snapshot.write_off_or_charge_off_executed_flag
      OR snapshot.legal_or_collection_action_executed_flag
      OR snapshot.external_notice_generated_flag
      OR snapshot.production_adverse_action_notice_flag
  )
ORDER BY
    snapshot.scenario_code,
    snapshot.merchant_application_id;
