/* M1.11 generation reconciliation reconstruction v0.2 — read only */
WITH r AS (SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
actual AS (
 SELECT * FROM msbf_m1.m1_11_actual_resilience((SELECT run_id FROM r))
 UNION ALL SELECT * FROM msbf_m1.m1_11_actual_component((SELECT run_id FROM r))
), hashes AS (
 SELECT
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM actual WHERE entity_key LIKE 'RESILIENCE|%') snapshot_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM actual WHERE entity_key LIKE 'COMPONENT|%') component_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM actual) combined_hash,
  (SELECT count(*) FROM actual) canonical_entities
), stored AS (
 SELECT max(metric_value_text) FILTER(WHERE evidence_code='M1_11_SNAPSHOT_SET_HASH') stored_snapshot_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_11_COMPONENT_SET_HASH') stored_component_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_11_COMBINED_SET_HASH') stored_combined_hash,
        (max(metric_value_numeric) FILTER(WHERE evidence_code='M1_11_CANONICAL_MISMATCH_COUNT'))::bigint stored_mismatches
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
)
SELECT r.run_id,r.run_status,
 (SELECT count(*) FROM msbf_m1.application_operating_resilience_snapshot WHERE module1_run_id=r.run_id) snapshot_rows,
 (SELECT count(*) FROM msbf_m1.operating_resilience_component_value WHERE module1_run_id=r.run_id) component_rows,
 hashes.*,stored.*,
 CASE WHEN r.run_status IN ('M1_11_GENERATED','M1_11_VALIDATED','M1_11_ACCEPTED') AND hashes.canonical_entities=9000
       AND stored.stored_mismatches=0 AND hashes.snapshot_hash=stored.stored_snapshot_hash
       AND hashes.component_hash=stored.stored_component_hash AND hashes.combined_hash=stored.stored_combined_hash
      THEN 'PASS' ELSE 'FAIL' END generation_reconciliation_status
FROM r CROSS JOIN hashes CROSS JOIN stored;
