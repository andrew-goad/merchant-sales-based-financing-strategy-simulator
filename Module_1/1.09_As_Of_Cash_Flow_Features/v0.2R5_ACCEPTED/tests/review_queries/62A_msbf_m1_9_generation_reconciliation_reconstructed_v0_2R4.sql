/* ============================================================================
MSBF M1.9 — Generation Evidence Reconstruction
Version : v0.2R4
Purpose : Reconstruct script-62 evidence after a successful commit when the
          DBeaver result tab was lost. Read-only; never generates or updates rows.
============================================================================ */
WITH r AS (
 SELECT run_id,run_status,population_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), actual AS (
 SELECT * FROM msbf_m1.m1_9_actual_snapshot((SELECT run_id FROM r))
 UNION ALL
 SELECT * FROM msbf_m1.m1_9_actual_feature_value((SELECT run_id FROM r))
), hashes AS (
 SELECT
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER (WHERE entity_key LIKE 'SNAPSHOT|%')) AS snapshot_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER (WHERE entity_key LIKE 'FEATURE|%')) AS feature_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) combined_hash,
  count(*) canonical_rows
 FROM actual
), stored AS (
 SELECT
  max(metric_value_text) FILTER(WHERE evidence_code='M1_9_SNAPSHOT_SET_HASH') snapshot_hash,
  max(metric_value_text) FILTER(WHERE evidence_code='M1_9_FEATURE_VALUE_SET_HASH') feature_hash,
  max(metric_value_text) FILTER(WHERE evidence_code='M1_9_COMBINED_SET_HASH') combined_hash
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
)
SELECT r.run_id,r.run_status,r.population_id,
 (SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=r.run_id) snapshot_rows,
 (SELECT count(*) FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=r.run_id) feature_value_rows,
 h.canonical_rows,s.snapshot_hash stored_snapshot_hash,h.snapshot_hash recomputed_snapshot_hash,
 s.feature_hash stored_feature_hash,h.feature_hash recomputed_feature_hash,
 s.combined_hash stored_combined_hash,h.combined_hash recomputed_combined_hash,
 CASE WHEN r.run_status IN ('M1_9_GENERATED','M1_9_VALIDATED','M1_9_ACCEPTED')
       AND (SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=r.run_id)=1500
       AND (SELECT count(*) FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=r.run_id)=54000
       AND h.canonical_rows=55500
       AND s.snapshot_hash=h.snapshot_hash AND s.feature_hash=h.feature_hash AND s.combined_hash=h.combined_hash
      THEN 'PASS' ELSE 'FAIL' END AS generation_reconciliation_status
FROM r CROSS JOIN hashes h CROSS JOIN stored s;
