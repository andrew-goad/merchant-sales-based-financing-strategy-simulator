/* ============================================================================
MSBF M1.9 — Failed Validation Syntax Recovery Check
Version : v0.2R4
Purpose : Confirm that the v0.2R3 FILTER-placement error changed no persisted
          M1.9 business rows, generation evidence, validation evidence, or gates.
Output  : One read-only recovery-state result row.
============================================================================ */
WITH r AS (
    SELECT run_id, run_status, population_id, as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), actual AS (
    SELECT * FROM msbf_m1.m1_9_actual_snapshot((SELECT run_id FROM r))
    UNION ALL
    SELECT * FROM msbf_m1.m1_9_actual_feature_value((SELECT run_id FROM r))
), hashes AS (
    SELECT
        count(*) AS canonical_rows,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
            FILTER (WHERE entity_key LIKE 'SNAPSHOT|%')) AS snapshot_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
            FILTER (WHERE entity_key LIKE 'FEATURE|%')) AS feature_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash
    FROM actual
), stored AS (
    SELECT
        max(metric_value_text) FILTER (WHERE evidence_code='M1_9_SNAPSHOT_SET_HASH') AS snapshot_hash,
        max(metric_value_text) FILTER (WHERE evidence_code='M1_9_FEATURE_VALUE_SET_HASH') AS feature_hash,
        max(metric_value_text) FILTER (WHERE evidence_code='M1_9_COMBINED_SET_HASH') AS combined_hash,
        count(*) FILTER (WHERE evidence_code LIKE 'M1_9_POS_%') AS positive_evidence_rows,
        count(*) FILTER (WHERE evidence_code LIKE 'M1_9_NEG_%') AS negative_evidence_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
), counts AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS snapshot_rows,
        (SELECT count(*) FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=(SELECT run_id FROM r)) AS feature_value_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_9_ASOF_CASHFLOW_FEATURES') AS gate_rows,
        (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors
)
SELECT
    r.run_id,
    r.run_status,
    r.population_id,
    r.as_of_date,
    c.snapshot_rows,
    c.feature_value_rows,
    h.canonical_rows,
    s.positive_evidence_rows,
    s.negative_evidence_rows,
    c.gate_rows,
    c.blocking_errors,
    s.snapshot_hash AS stored_snapshot_hash,
    h.snapshot_hash AS recomputed_snapshot_hash,
    s.feature_hash AS stored_feature_hash,
    h.feature_hash AS recomputed_feature_hash,
    s.combined_hash AS stored_combined_hash,
    h.combined_hash AS recomputed_combined_hash,
    CASE
        WHEN r.run_status='M1_9_GENERATED'
         AND c.snapshot_rows=1500
         AND c.feature_value_rows=54000
         AND h.canonical_rows=55500
         AND s.positive_evidence_rows=0
         AND s.negative_evidence_rows=0
         AND c.gate_rows=0
         AND c.blocking_errors=0
         AND s.snapshot_hash=h.snapshot_hash
         AND s.feature_hash=h.feature_hash
         AND s.combined_hash=h.combined_hash
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_state_status
FROM r CROSS JOIN hashes h CROSS JOIN stored s CROSS JOIN counts c;
