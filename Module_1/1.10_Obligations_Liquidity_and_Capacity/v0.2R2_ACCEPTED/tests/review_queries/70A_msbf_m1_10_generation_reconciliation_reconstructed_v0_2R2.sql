/* M1.10 v0.2R2 corrected contingency reconstruction. */
/* M1.10 read-only generation reconciliation — contingency only. */
WITH r AS (
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), a AS (
 SELECT * FROM msbf_m1.m1_10_actual_obligation((SELECT run_id FROM r))
 UNION ALL SELECT * FROM msbf_m1.m1_10_actual_capacity((SELECT run_id FROM r))
), h AS (
 SELECT
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER(WHERE entity_key LIKE 'OBLIGATION|%')) obligation_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER(WHERE entity_key LIKE 'CAPACITY|%')) capacity_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) combined_hash,count(*) canonical_entities
 FROM a
), s AS (
 SELECT max(metric_value_text) FILTER(WHERE evidence_code='M1_10_OBLIGATION_SET_HASH') stored_obligation_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_10_CAPACITY_SET_HASH') stored_capacity_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_10_COMBINED_SET_HASH') stored_combined_hash,
        (max(metric_value_numeric) FILTER(WHERE evidence_code='M1_10_CANONICAL_ENTITY_COUNT'))::bigint stored_canonical_entities,
        (max(metric_value_numeric) FILTER(WHERE evidence_code='M1_10_CANONICAL_MISMATCH_COUNT'))::bigint stored_mismatches
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
)
SELECT r.run_id,r.run_status,
 (SELECT count(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=r.run_id) obligation_rows,
 (SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=r.run_id) capacity_rows,
 h.canonical_entities,s.stored_canonical_entities,s.stored_mismatches,
 s.stored_obligation_hash,h.obligation_hash,s.stored_capacity_hash,h.capacity_hash,
 s.stored_combined_hash,h.combined_hash,
 CASE WHEN r.run_status='M1_10_GENERATED'
       AND h.canonical_entities=s.stored_canonical_entities AND s.stored_mismatches=0
       AND h.obligation_hash=s.stored_obligation_hash AND h.capacity_hash=s.stored_capacity_hash
       AND h.combined_hash=s.stored_combined_hash THEN 'PASS' ELSE 'FAIL' END generation_reconciliation_status
FROM r CROSS JOIN h CROSS JOIN s;
