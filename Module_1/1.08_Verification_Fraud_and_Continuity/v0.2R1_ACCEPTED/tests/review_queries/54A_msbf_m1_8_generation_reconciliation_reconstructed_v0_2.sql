/* ============================================================================
MSBF M1.8 — Read-Only Generation Evidence Reconstruction
Version : v0.2
Use only if script 54 committed but the DBeaver result tab was lost.
============================================================================ */
WITH r AS (
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), actual AS MATERIALIZED (
    SELECT * FROM msbf_m1.m1_8_actual_entity_snapshot((SELECT run_id FROM r))
), hashes AS (
    SELECT
      count(*) AS canonical_rows,
      md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER (WHERE entity_key LIKE 'VERIFICATION|%')) AS verification_hash,
      md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER (WHERE entity_key LIKE 'SUMMARY|%')) AS summary_hash,
      md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash
    FROM actual
), stored AS (
    SELECT
      max(metric_value_text) FILTER (WHERE evidence_code='M1_8_VERIFICATION_SET_HASH') AS verification_hash,
      max(metric_value_text) FILTER (WHERE evidence_code='M1_8_SUMMARY_SET_HASH') AS summary_hash,
      max(metric_value_text) FILTER (WHERE evidence_code='M1_8_COMBINED_SET_HASH') AS combined_hash
    FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
)
SELECT r.run_id,r.run_status,
       (SELECT count(*) FROM msbf_m1.verification_result WHERE created_by_run_id=r.run_id) AS verification_rows,
       (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=r.run_id) AS summary_rows,
       h.canonical_rows,h.verification_hash AS actual_verification_hash,
       s.verification_hash AS stored_verification_hash,
       h.summary_hash AS actual_summary_hash,s.summary_hash AS stored_summary_hash,
       h.combined_hash AS actual_combined_hash,s.combined_hash AS stored_combined_hash,
       CASE WHEN r.run_status IN ('M1_8_GENERATED','M1_8_VALIDATED','M1_8_ACCEPTED')
                  AND (SELECT count(*) FROM msbf_m1.verification_result WHERE created_by_run_id=r.run_id)=4500
                  AND (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=r.run_id)=750
                  AND h.canonical_rows=5250
                  AND h.verification_hash=s.verification_hash
                  AND h.summary_hash=s.summary_hash
                  AND h.combined_hash=s.combined_hash
             THEN 'PASS' ELSE 'FAIL' END AS generation_reconciliation_status
FROM r CROSS JOIN hashes h CROSS JOIN stored s;
