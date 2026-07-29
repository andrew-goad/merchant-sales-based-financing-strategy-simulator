/* ============================================================================
M1.13 v0.2R1 BOOLEAN-PARAMETER AGGREGATION HOTFIX
Source  : 94A_msbf_m1_13_generation_reconciliation_reconstructed_v0_2.sql
Role    : Contingency-only read-only generation reconstruction; executable logic unchanged from v0.2.
Revision: File name is version-aligned to v0.2R1. Except where explicitly
          documented in HOTFIX_NOTES_v0_2R1.md, executable logic is unchanged.
============================================================================ */

/* ============================================================================
MSBF M1.13 — Generation Evidence Reconstruction
Version : v0.2
Purpose : Reconstruct the committed program-94 generation checkpoint when the
          DBeaver result tab is lost. This program is read-only.
Use     : Contingency only after a successful program-94 COMMIT.
============================================================================ */

WITH r AS (
    SELECT run_id,run_status,population_id
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), actual AS (
    SELECT * FROM msbf_m1.m1_13_actual_path_snapshot((SELECT run_id FROM r))
    UNION ALL
    SELECT * FROM msbf_m1.m1_13_actual_loss_snapshot((SELECT run_id FROM r))
), hashes AS (
    SELECT
        count(*) AS actual_canonical_entities,
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM actual WHERE entity_key LIKE 'PATH|%') AS actual_path_hash,
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM actual WHERE entity_key LIKE 'LOSS|%') AS actual_snapshot_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS actual_combined_hash
    FROM actual
), stored AS (
    SELECT
        max(metric_value_text) FILTER(WHERE evidence_code='M1_13_PATH_SET_HASH') AS stored_path_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_13_SNAPSHOT_SET_HASH') AS stored_snapshot_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_13_COMBINED_SET_HASH') AS stored_combined_hash,
        (max(metric_value_numeric) FILTER(WHERE evidence_code='M1_13_CANONICAL_ENTITY_COUNT'))::bigint AS stored_canonical_entities,
        (max(metric_value_numeric) FILTER(WHERE evidence_code='M1_13_CANONICAL_MISMATCH_COUNT'))::bigint AS stored_mismatches
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
), counts AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.application_ead_path_value WHERE module1_run_id=(SELECT run_id FROM r)) AS path_rows,
        (SELECT count(*) FROM msbf_m1.application_exposure_recovery_loss_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS snapshot_rows,
        (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.application_exposure_recovery_loss_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS applications,
        (SELECT count(DISTINCT scenario_id) FROM msbf_m1.application_exposure_recovery_loss_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS scenarios
)
SELECT
    r.run_id,r.run_status,r.population_id,
    counts.*,
    stored.stored_canonical_entities,
    hashes.actual_canonical_entities,
    stored.stored_mismatches,
    stored.stored_path_hash,hashes.actual_path_hash,
    stored.stored_snapshot_hash,hashes.actual_snapshot_hash,
    stored.stored_combined_hash,hashes.actual_combined_hash,
    CASE
      WHEN r.run_status='M1_13_GENERATED'
       AND counts.snapshot_rows=1500
       AND counts.applications=750
       AND counts.scenarios=2
       AND stored.stored_canonical_entities=hashes.actual_canonical_entities
       AND stored.stored_mismatches=0
       AND stored.stored_path_hash=hashes.actual_path_hash
       AND stored.stored_snapshot_hash=hashes.actual_snapshot_hash
       AND stored.stored_combined_hash=hashes.actual_combined_hash
      THEN 'PASS' ELSE 'FAIL'
    END AS generation_reconciliation_status
FROM r CROSS JOIN counts CROSS JOIN hashes CROSS JOIN stored;
