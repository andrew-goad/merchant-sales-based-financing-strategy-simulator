/* ============================================================================
MSBF M1.8 v0.2R1 — Failed Continuity Validation Recovery Check
Purpose : Confirm the committed M1.8 generation is intact and the only positive
          validation failure is M1_8_POS_48_STRESS_NONIMPROVEMENT.
Behavior: Read-only. Does not change M1.8 business rows, evidence, or status.
============================================================================ */
WITH r AS (
    SELECT run_id,run_status,population_id,as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), pos AS (
    SELECT count(*) AS checks,
           count(*) FILTER (WHERE status='PASS') AS passes,
           count(*) FILTER (WHERE status='FAIL') AS failures,
           string_agg(evidence_code,',' ORDER BY evidence_code)
             FILTER (WHERE status='FAIL') AS failed_codes
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_8_POS_%'
), actual AS MATERIALIZED (
    SELECT * FROM msbf_m1.m1_8_actual_entity_snapshot((SELECT run_id FROM r))
), hashes AS (
    SELECT count(*) AS canonical_rows,
           md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
             FILTER (WHERE entity_key LIKE 'VERIFICATION|%')) AS verification_hash,
           md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
             FILTER (WHERE entity_key LIKE 'SUMMARY|%')) AS summary_hash,
           md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash
    FROM actual
), stored AS (
    SELECT max(metric_value_text) FILTER (WHERE evidence_code='M1_8_VERIFICATION_SET_HASH') AS verification_hash,
           max(metric_value_text) FILTER (WHERE evidence_code='M1_8_SUMMARY_SET_HASH') AS summary_hash,
           max(metric_value_text) FILTER (WHERE evidence_code='M1_8_COMBINED_SET_HASH') AS combined_hash
    FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
), counts AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM r)) AS verification_rows,
      (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS summary_rows,
      (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot
        WHERE module1_run_id=(SELECT run_id FROM r)
          AND stress_processor_continuity_risk_tier<processor_continuity_risk_tier) AS stress_tier_improvements,
      (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
        WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY') AS gate_rows,
      (SELECT count(*) FROM msbf_ctl.profile_resolution_error
        WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors
)
SELECT r.run_id,r.run_status,r.population_id,r.as_of_date,
       pos.checks AS positive_checks,pos.passes AS positive_passes,pos.failures AS positive_failures,
       pos.failed_codes,counts.verification_rows,counts.summary_rows,counts.stress_tier_improvements,
       hashes.canonical_rows,stored.verification_hash AS stored_verification_hash,
       hashes.verification_hash AS actual_verification_hash,
       stored.summary_hash AS stored_summary_hash,hashes.summary_hash AS actual_summary_hash,
       stored.combined_hash AS stored_combined_hash,hashes.combined_hash AS actual_combined_hash,
       counts.gate_rows,counts.blocking_errors,
       CASE WHEN r.run_status='M1_8_FAILED'
                  AND pos.checks=60 AND pos.passes=59 AND pos.failures=1
                  AND pos.failed_codes='M1_8_POS_48_STRESS_NONIMPROVEMENT'
                  AND counts.verification_rows=4500 AND counts.summary_rows=750
                  AND counts.stress_tier_improvements=18
                  AND hashes.canonical_rows=5250
                  AND stored.verification_hash=hashes.verification_hash
                  AND stored.summary_hash=hashes.summary_hash
                  AND stored.combined_hash=hashes.combined_hash
                  AND counts.gate_rows=0 AND counts.blocking_errors=0
             THEN 'PASS' ELSE 'FAIL' END AS recovery_state_status
FROM r CROSS JOIN pos CROSS JOIN hashes CROSS JOIN stored CROSS JOIN counts;
