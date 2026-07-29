/* ============================================================================
MSBF M1.7 Source Quality & Data Confidence — Generation Evidence Reconstruction
Version : v0.2
Use only when script 46 committed successfully but the DBeaver result tab was
lost. This script is read-only and does not regenerate source snapshots.
============================================================================ */
WITH r AS (
    SELECT run_id, run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
),
actual AS (
    SELECT
        count(*) AS actual_rows,
        md5(
            string_agg(
                entity_key || '|' || row_hash,
                '||' ORDER BY entity_key
            )
        ) AS actual_hash
    FROM msbf_m1.m1_7_actual_source_snapshot((SELECT run_id FROM r))
),
stored AS (
    SELECT
        max(metric_value_text) FILTER (
            WHERE evidence_code='M1_7_SOURCE_SET_HASH'
        ) AS stored_hash,
        max(metric_value_text) FILTER (
            WHERE evidence_code='M1_7_GENERATION_CANONICAL_RECON'
        ) AS canonical_reconciliation,
        max(metric_value_text) FILTER (
            WHERE evidence_code='M1_7_GENERATION_SUMMARY'
        ) AS generation_summary
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
      AND evidence_code IN (
          'M1_7_SOURCE_SET_HASH',
          'M1_7_GENERATION_CANONICAL_RECON',
          'M1_7_GENERATION_SUMMARY'
      )
),
physical AS (
    SELECT
        count(*) AS source_snapshot_rows,
        count(DISTINCT merchant_application_id) AS applications,
        count(DISTINCT source_code) AS source_codes,
        count(*) FILTER (WHERE fallback_path_code<>'NONE') AS fallback_rows,
        count(*) FILTER (WHERE quality_status='PASS') AS pass_rows,
        count(*) FILTER (WHERE quality_status<>'PASS') AS nonpass_rows
    FROM msbf_m1.source_snapshot
    WHERE module1_run_id=(SELECT run_id FROM r)
),
mismatches AS (
    SELECT count(*) AS row_mismatches
    FROM msbf_m1.source_snapshot s
    JOIN msbf_m1.m1_7_actual_source_snapshot((SELECT run_id FROM r)) a
      ON a.entity_key=s.merchant_application_id || '|' || s.source_code
    WHERE s.module1_run_id=(SELECT run_id FROM r)
      AND s.source_hash IS DISTINCT FROM a.row_hash
)
SELECT
    r.run_id,
    r.run_status,
    p.source_snapshot_rows,
    p.applications,
    p.source_codes,
    p.fallback_rows,
    p.pass_rows,
    p.nonpass_rows,
    a.actual_rows,
    m.row_mismatches,
    s.stored_hash,
    a.actual_hash,
    s.canonical_reconciliation,
    s.generation_summary,
    CASE
        WHEN r.run_status IN ('M1_7_GENERATED','M1_7_VALIDATED','M1_7_ACCEPTED')
         AND p.source_snapshot_rows=5250
         AND p.applications=750
         AND p.source_codes=7
         AND a.actual_rows=5250
         AND m.row_mismatches=0
         AND s.stored_hash=a.actual_hash
         AND s.canonical_reconciliation='expected=5250 actual=5250 mismatches=0'
        THEN 'PASS'
        ELSE 'FAIL'
    END AS generation_reconciliation_status
FROM r
CROSS JOIN actual a
CROSS JOIN stored s
CROSS JOIN physical p
CROSS JOIN mismatches m;
