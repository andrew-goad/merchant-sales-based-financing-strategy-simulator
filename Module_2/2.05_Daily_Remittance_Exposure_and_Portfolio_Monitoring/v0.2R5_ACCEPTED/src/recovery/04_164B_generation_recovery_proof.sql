/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 164B_msbf_m2_5_failed_latest_archive_reproduction_validation_recovery_v0_2R2.sql
Version     : v0.2R3

Purpose
-------
Read-only recovery and root-cause proof after Program 167 v0.2 returned
119 PASS / 1 FAIL.

The failed control was:

    M2_5_POS_082_LATEST_ARCHIVE_REPRODUCTION

The immutable archive payload was created from target-typed staging latest
rows, which do not contain the system-managed persistent `created_at` column.
Program 167 v0.2 incorrectly compared that payload to `to_jsonb(latest)`,
which includes `created_at`. Programs 169, 170 and 171 already use the correct
comparison `(to_jsonb(latest)-'created_at')`.

This program proves:
- Program 166 remains committed and authoritative;
- the failed Program 167 transaction left no positive evidence or lifecycle
  transition;
- latest and archive contract-row hashes match;
- the old payload comparison produces 59 false mismatches;
- the corrected payload comparison produces zero mismatches.

Writes
------
None. Temporary diagnostics only.

Required results
----------------
Result Set 01: exactly one recovery-summary row with recovery_status = PASS.
Result Set 02: headers retained and zero corrected-reproduction exception rows.
============================================================================ */

BEGIN;

SET LOCAL statement_timeout = '20min';
SET LOCAL jit = off;
SET LOCAL client_min_messages = warning;

DROP TABLE IF EXISTS _m2_5_r3_validation_recovery;

CREATE TEMP TABLE _m2_5_r3_validation_recovery
ON COMMIT PRESERVE ROWS
AS
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
        source_rows,
        daily_rows,
        latest_rows,
        archive_rows,
        portfolio_daily_rows,
        comparison_rows,
        canonical_entities,
        combined_set_hash
    FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
evidence AS
(
    SELECT
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_POS_%'
        )::bigint AS positive_evidence_rows,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_NEG_%'
        )::bigint AS negative_evidence_rows,

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
        )::bigint AS portfolio_daily_rows,

        (
            SELECT count(*)
            FROM msbf_m2.v_m2_5_matched_monitoring_comparison
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS comparison_rows,

        (
            SELECT canonical_entities
            FROM msbf_m2.v_m2_5_canonical_hash
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS canonical_entities,

        (
            SELECT combined_set_hash
            FROM msbf_m2.v_m2_5_canonical_hash
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        ) AS physical_combined_set_hash,

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
),
reproduction AS
(
    SELECT
        count(*)::bigint AS joined_rows,

        count(*) FILTER
        (
            WHERE latest.contract_row_hash IS DISTINCT FROM
                  archive.contract_row_hash
        )::bigint AS contract_row_hash_mismatches,

        count(*) FILTER
        (
            WHERE archive.contract_payload IS DISTINCT FROM
                  to_jsonb(latest)
        )::bigint AS original_v0_2_payload_mismatches,

        count(*) FILTER
        (
            WHERE archive.contract_payload IS DISTINCT FROM
                  (to_jsonb(latest)-'created_at')
        )::bigint AS corrected_payload_mismatches,

        count(*) FILTER
        (
            WHERE to_jsonb(latest) ? 'created_at'
        )::bigint AS latest_created_at_key_rows,

        count(*) FILTER
        (
            WHERE archive.contract_payload ? 'created_at'
        )::bigint AS archive_payload_created_at_key_rows

    FROM msbf_m2.advance_portfolio_monitoring_latest AS latest

    FULL OUTER JOIN msbf_m2.advance_portfolio_monitoring_archive AS archive
      ON archive.module1_run_id = latest.module1_run_id
     AND archive.contract_version = latest.contract_version
     AND archive.scenario_id = latest.scenario_id
     AND archive.merchant_application_id = latest.merchant_application_id

    WHERE coalesce(latest.module1_run_id, archive.module1_run_id) =
          (SELECT run_id FROM run_context)
)
SELECT
    run_context.run_id,
    run_context.run_status,
    registry.contract_status,

    registry.source_rows AS registry_source_rows,
    registry.daily_rows AS registry_daily_rows,
    registry.latest_rows AS registry_latest_rows,
    registry.archive_rows AS registry_archive_rows,
    registry.portfolio_daily_rows AS registry_portfolio_daily_rows,
    registry.comparison_rows AS registry_comparison_rows,
    registry.canonical_entities AS registry_canonical_entities,

    physical.source_rows,
    physical.daily_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.portfolio_daily_rows,
    physical.comparison_rows,
    physical.canonical_entities,

    evidence.generation_evidence_rows,
    evidence.positive_evidence_rows,
    evidence.negative_evidence_rows,
    evidence.failed_evidence_rows,
    physical.acceptance_rows,
    physical.blocking_errors,

    reproduction.joined_rows,
    reproduction.contract_row_hash_mismatches,
    reproduction.original_v0_2_payload_mismatches,
    reproduction.corrected_payload_mismatches,
    reproduction.latest_created_at_key_rows,
    reproduction.archive_payload_created_at_key_rows,

    registry.combined_set_hash,
    physical.physical_combined_set_hash,

    CASE
        WHEN run_context.run_status = 'M2_5_GENERATED'
         AND registry.contract_status = 'GENERATED'

         AND registry.source_rows = 59
         AND registry.daily_rows = 7080
         AND registry.latest_rows = 59
         AND registry.archive_rows = 59
         AND registry.portfolio_daily_rows = 240
         AND registry.comparison_rows = 15
         AND registry.canonical_entities = 7536

         AND physical.source_rows = 59
         AND physical.daily_rows = 7080
         AND physical.latest_rows = 59
         AND physical.archive_rows = 59
         AND physical.portfolio_daily_rows = 240
         AND physical.comparison_rows = 15
         AND physical.canonical_entities = 7536

         AND evidence.generation_evidence_rows = 24
         AND evidence.positive_evidence_rows = 0
         AND evidence.negative_evidence_rows = 0
         AND evidence.failed_evidence_rows = 0
         AND physical.acceptance_rows = 0
         AND physical.blocking_errors = 0

         AND reproduction.joined_rows = 59
         AND reproduction.contract_row_hash_mismatches = 0
         AND reproduction.original_v0_2_payload_mismatches = 59
         AND reproduction.corrected_payload_mismatches = 0
         AND reproduction.latest_created_at_key_rows = 59
         AND reproduction.archive_payload_created_at_key_rows = 0

         AND registry.combined_set_hash IS NOT DISTINCT FROM
             physical.physical_combined_set_hash
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status

FROM run_context
CROSS JOIN registry
CROSS JOIN evidence
CROSS JOIN physical
CROSS JOIN reproduction;

COMMIT;

/* Result Set 01 — Recovery summary: exactly one row required. */
SELECT
    recovery.run_id,
    recovery.run_status,
    recovery.contract_status,
    recovery.registry_source_rows,
    recovery.registry_daily_rows,
    recovery.registry_latest_rows,
    recovery.registry_archive_rows,
    recovery.registry_portfolio_daily_rows,
    recovery.registry_comparison_rows,
    recovery.registry_canonical_entities,
    recovery.source_rows,
    recovery.daily_rows,
    recovery.latest_rows,
    recovery.archive_rows,
    recovery.portfolio_daily_rows,
    recovery.comparison_rows,
    recovery.canonical_entities,
    recovery.generation_evidence_rows,
    recovery.positive_evidence_rows,
    recovery.negative_evidence_rows,
    recovery.failed_evidence_rows,
    recovery.acceptance_rows,
    recovery.blocking_errors,
    recovery.joined_rows,
    recovery.contract_row_hash_mismatches,
    recovery.original_v0_2_payload_mismatches,
    recovery.corrected_payload_mismatches,
    recovery.latest_created_at_key_rows,
    recovery.archive_payload_created_at_key_rows,
    recovery.combined_set_hash,
    recovery.physical_combined_set_hash,
    recovery.recovery_status
FROM _m2_5_r3_validation_recovery AS recovery;

/* Result Set 02 — Corrected reproduction exceptions: headers retained, zero rows required. */
SELECT
    latest.scenario_code,
    latest.merchant_application_id,
    latest.contract_row_hash AS latest_contract_row_hash,
    archive.contract_row_hash AS archive_contract_row_hash,
    archive.contract_payload,
    to_jsonb(latest)-'created_at' AS expected_contract_payload
FROM msbf_m2.advance_portfolio_monitoring_latest AS latest
FULL OUTER JOIN msbf_m2.advance_portfolio_monitoring_archive AS archive
  ON archive.module1_run_id = latest.module1_run_id
 AND archive.contract_version = latest.contract_version
 AND archive.scenario_id = latest.scenario_id
 AND archive.merchant_application_id = latest.merchant_application_id
WHERE coalesce(latest.module1_run_id, archive.module1_run_id) =
      (
          SELECT run_id
          FROM msbf_ctl.run_registry
          WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
            AND run_version = 1
      )
  AND
  (
      latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash
      OR archive.contract_payload IS DISTINCT FROM
         (to_jsonb(latest)-'created_at')
  )
ORDER BY
    latest.scenario_code,
    latest.merchant_application_id;
