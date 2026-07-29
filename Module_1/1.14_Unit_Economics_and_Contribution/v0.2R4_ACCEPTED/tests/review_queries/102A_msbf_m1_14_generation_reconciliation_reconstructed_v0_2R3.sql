/* ============================================================================
MSBF M1.14 Unit Economics — Generation Evidence Reconstruction
Program : 102A_msbf_m1_14_generation_reconciliation_reconstructed_v0_2R3.sql
Version : v0.2R3
Purpose : Reconstruct the committed program-102 generation checkpoint when the
          DBeaver result tab was lost after a successful COMMIT.
Usage   : Contingency only. Do not execute in the normal build sequence and do
          not use it as a substitute for program 102 when generation has not
          committed successfully.
Boundary: Read-only. No business rows, evidence rows, hashes, or run state are
          changed.
============================================================================ */

WITH run_scope AS (
    SELECT run_id,run_status,population_id,as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
), actual AS (
    SELECT *
    FROM msbf_m1.m1_14_actual_snapshot((SELECT run_id FROM run_scope))
    UNION ALL
    SELECT *
    FROM msbf_m1.m1_14_actual_component_snapshot((SELECT run_id FROM run_scope))
), hash_scope AS (
    SELECT
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
            FILTER (WHERE entity_key LIKE 'ECON|%')) AS snapshot_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
            FILTER (WHERE entity_key LIKE 'COMP|%')) AS component_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash,
        count(*) FILTER (WHERE entity_key LIKE 'ECON|%') AS snapshot_rows,
        count(*) FILTER (WHERE entity_key LIKE 'COMP|%') AS component_rows,
        count(*) AS canonical_entities
    FROM actual
), evidence_scope AS (
    SELECT
        max(metric_value_text) FILTER (WHERE evidence_code='M1_14_SNAPSHOT_SET_HASH') AS stored_snapshot_hash,
        max(metric_value_text) FILTER (WHERE evidence_code='M1_14_COMPONENT_SET_HASH') AS stored_component_hash,
        max(metric_value_text) FILTER (WHERE evidence_code='M1_14_COMBINED_SET_HASH') AS stored_combined_hash,
        (max(metric_value_numeric) FILTER (WHERE evidence_code='M1_14_CANONICAL_MISMATCH_COUNT'))::bigint AS stored_mismatches,
        (max(metric_value_numeric) FILTER (WHERE evidence_code='M1_14_SNAPSHOT_ROW_COUNT'))::bigint AS stored_snapshot_rows,
        (max(metric_value_numeric) FILTER (WHERE evidence_code='M1_14_COMPONENT_ROW_COUNT'))::bigint AS stored_component_rows,
        (max(metric_value_numeric) FILTER (WHERE evidence_code='M1_14_CANONICAL_ENTITY_COUNT'))::bigint AS stored_canonical_entities
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM run_scope)
      AND evidence_code LIKE 'M1_14_%'
), physical_scope AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot
         WHERE module1_run_id=(SELECT run_id FROM run_scope)) AS physical_snapshot_rows,
        (SELECT count(*) FROM msbf_m1.unit_economics_component_value
         WHERE module1_run_id=(SELECT run_id FROM run_scope)) AS physical_component_rows,
        (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot e
         WHERE e.module1_run_id=(SELECT run_id FROM run_scope)
           AND e.row_hash IS DISTINCT FROM
               msbf_m1.m1_14_hash_jsonb(to_jsonb(e)-'row_hash'-'created_at'))
        +
        (SELECT count(*) FROM msbf_m1.unit_economics_component_value c
         WHERE c.module1_run_id=(SELECT run_id FROM run_scope)
           AND c.calculation_hash IS DISTINCT FROM
               msbf_m1.m1_14_hash_jsonb(to_jsonb(c)-'calculation_hash'-'created_at'))
        AS row_hash_mismatches
)
SELECT
    r.run_id,
    r.run_status,
    r.population_id,
    r.as_of_date,
    p.physical_snapshot_rows,
    p.physical_component_rows,
    h.snapshot_rows AS actual_snapshot_rows,
    h.component_rows AS actual_component_rows,
    h.canonical_entities AS actual_canonical_entities,
    p.row_hash_mismatches,
    e.stored_mismatches,
    e.stored_snapshot_rows,
    e.stored_component_rows,
    e.stored_canonical_entities,
    e.stored_snapshot_hash,
    h.snapshot_hash AS actual_snapshot_hash,
    e.stored_component_hash,
    h.component_hash AS actual_component_hash,
    e.stored_combined_hash,
    h.combined_hash AS actual_combined_hash,
    CASE
        WHEN r.run_status IN ('M1_14_GENERATED','M1_14_VALIDATED','M1_14_ACCEPTED')
         AND p.physical_snapshot_rows=1500
         AND p.physical_component_rows=21000
         AND h.snapshot_rows=1500
         AND h.component_rows=21000
         AND h.canonical_entities=22500
         AND p.row_hash_mismatches=0
         AND e.stored_mismatches=0
         AND e.stored_snapshot_rows=1500
         AND e.stored_component_rows=21000
         AND e.stored_canonical_entities=22500
         AND e.stored_snapshot_hash=h.snapshot_hash
         AND e.stored_component_hash=h.component_hash
         AND e.stored_combined_hash=h.combined_hash
        THEN 'PASS'
        ELSE 'FAIL'
    END AS generation_reconciliation_status
FROM run_scope r
CROSS JOIN hash_scope h
CROSS JOIN evidence_scope e
CROSS JOIN physical_scope p;
