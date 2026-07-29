/* ============================================================================
MSBF M1.8 — Failed/Cancelled Generation Recovery Check
Version : v0.2
Use only after a failed or cancelled script 54 followed by ROLLBACK.
============================================================================ */
WITH r AS (
    SELECT run_id,run_status,population_id,parameter_snapshot_hash,
           profile_snapshot_hash,source_snapshot_hash
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), latest_gate AS (
    SELECT result_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM r)
      AND gate_id='M1_7_SOURCE_QUALITY_CONFIDENCE'
    ORDER BY review_version DESC LIMIT 1
), rows AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM r)) AS verification_rows,
      (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS summary_rows,
      (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_8_%') AS evidence_rows,
      (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY') AS gate_rows,
      (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors
)
SELECT r.run_id,r.run_status,latest_gate.result_status AS m1_7_gate_status,
       rows.*,
       CASE WHEN r.run_status='M1_7_ACCEPTED'
                  AND latest_gate.result_status='PASS'
                  AND verification_rows=0 AND summary_rows=0
                  AND evidence_rows=0 AND gate_rows=0 AND blocking_errors=0
             THEN 'PASS' ELSE 'FAIL' END AS recovery_state_status
FROM r CROSS JOIN latest_gate CROSS JOIN rows;
