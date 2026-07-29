/* ============================================================================
MSBF M1.12 — Generation Reconciliation Reconstruction
Version : v0.2
Purpose : Reconstruct the committed program-86 checkpoint from persisted M1.12
          rows and governed run evidence when the original DBeaver result tab
          is lost or closed.
Mode    : Read-only contingency. Not part of the normal execution order.
Required: generation_reconciliation_status = PASS.
============================================================================ */

WITH r AS (
    SELECT run_id, run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
actual AS (
    SELECT *
    FROM msbf_m1.m1_12_actual_snapshot((SELECT run_id FROM r))

    UNION ALL

    SELECT *
    FROM msbf_m1.m1_12_actual_component((SELECT run_id FROM r))
),
hashes AS (
    SELECT
        count(*) AS canonical_entities,
        (
            SELECT md5(
                string_agg(entity_key || '|' || row_hash, '||' ORDER BY entity_key)
            )
            FROM actual
            WHERE entity_key LIKE 'RISK|%'
        ) AS snapshot_hash,
        (
            SELECT md5(
                string_agg(entity_key || '|' || row_hash, '||' ORDER BY entity_key)
            )
            FROM actual
            WHERE entity_key LIKE 'COMPONENT|%'
        ) AS component_hash,
        md5(
            string_agg(entity_key || '|' || row_hash, '||' ORDER BY entity_key)
        ) AS combined_hash
    FROM actual
),
stored AS (
    SELECT
        max(metric_value_numeric)
            FILTER (WHERE evidence_code = 'M1_12_CANONICAL_ENTITY_COUNT')
                AS stored_canonical_entities,
        max(metric_value_numeric)
            FILTER (WHERE evidence_code = 'M1_12_CANONICAL_MISMATCH_COUNT')
                AS stored_mismatches,
        max(metric_value_text)
            FILTER (WHERE evidence_code = 'M1_12_SNAPSHOT_SET_HASH')
                AS stored_snapshot_hash,
        max(metric_value_text)
            FILTER (WHERE evidence_code = 'M1_12_COMPONENT_SET_HASH')
                AS stored_component_hash,
        max(metric_value_text)
            FILTER (WHERE evidence_code = 'M1_12_COMBINED_SET_HASH')
                AS stored_combined_hash
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM r)
      AND evidence_code LIKE 'M1_12_%'
)
SELECT
    r.run_id,
    r.run_status,
    (SELECT count(*)
     FROM msbf_m1.application_integrated_risk_proxy_snapshot
     WHERE module1_run_id = r.run_id) AS snapshot_rows,
    (SELECT count(*)
     FROM msbf_m1.integrated_risk_component_value
     WHERE module1_run_id = r.run_id) AS component_rows,
    h.canonical_entities,
    s.stored_canonical_entities,
    s.stored_mismatches,
    h.snapshot_hash,
    s.stored_snapshot_hash,
    h.component_hash,
    s.stored_component_hash,
    h.combined_hash,
    s.stored_combined_hash,
    CASE
        WHEN r.run_status IN ('M1_12_GENERATED', 'M1_12_VALIDATED', 'M1_12_ACCEPTED')
         AND (SELECT count(*)
              FROM msbf_m1.application_integrated_risk_proxy_snapshot
              WHERE module1_run_id = r.run_id) = 1500
         AND (SELECT count(*)
              FROM msbf_m1.integrated_risk_component_value
              WHERE module1_run_id = r.run_id) = 10500
         AND h.canonical_entities = 12000
         AND s.stored_canonical_entities = 12000
         AND s.stored_mismatches = 0
         AND h.snapshot_hash = s.stored_snapshot_hash
         AND h.component_hash = s.stored_component_hash
         AND h.combined_hash = s.stored_combined_hash
        THEN 'PASS'
        ELSE 'FAIL'
    END AS generation_reconciliation_status
FROM r
CROSS JOIN hashes h
CROSS JOIN stored s;
