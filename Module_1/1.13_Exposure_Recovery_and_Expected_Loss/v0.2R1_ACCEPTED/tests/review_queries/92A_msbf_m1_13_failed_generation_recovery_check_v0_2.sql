/* ============================================================================
MSBF M1.13 — Failed-Generation Recovery Check
Version : v0.2
Purpose : Confirm a cancelled or failed program 94 transaction committed no
          M1.13 business rows, evidence, gate results, or run-state changes.
Use     : Execute only after program 94 fails/cancels and ROLLBACK has completed.
============================================================================ */

WITH r AS (
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), x AS (
    SELECT
        r.run_id,r.run_status,
        (SELECT count(*) FROM msbf_m1.application_ead_path_value WHERE module1_run_id=r.run_id) AS path_rows,
        (SELECT count(*) FROM msbf_m1.application_exposure_recovery_loss_snapshot WHERE module1_run_id=r.run_id) AS snapshot_rows,
        (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code LIKE 'M1_13_%') AS evidence_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=r.run_id AND gate_id='M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS') AS gate_rows,
        (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=r.run_id AND severity='BLOCKING') AS blocking_errors
    FROM r
)
SELECT x.*,
       CASE
         WHEN run_status='M1_12_ACCEPTED'
          AND path_rows=0
          AND snapshot_rows=0
          AND evidence_rows=0
          AND gate_rows=0
          AND blocking_errors=0
         THEN 'PASS' ELSE 'FAIL'
       END AS recovery_state_status
FROM x;
