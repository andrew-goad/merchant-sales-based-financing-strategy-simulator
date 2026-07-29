/* ============================================================================
MSBF M1.15 Failed-Generation Recovery Check
Program : 108A_msbf_m1_15_failed_generation_recovery_check_v0_2R3.sql
Use     : Only after program 110 fails or is cancelled before COMMIT, followed
          by ROLLBACK. Confirms the accepted M1.14 boundary is intact.
============================================================================ */

WITH r AS (
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), x AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.application_module1_latest
       WHERE module1_run_id=(SELECT run_id FROM r)) AS latest_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_archive
       WHERE module1_run_id=(SELECT run_id FROM r)) AS archive_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_scenario_comparison
       WHERE module1_run_id=(SELECT run_id FROM r)) AS comparison_rows,
      (SELECT count(*) FROM msbf_ctl.m1_15_consumption_contract_registry
       WHERE module1_run_id=(SELECT run_id FROM r)) AS contract_rows,
      (SELECT count(*) FROM msbf_ctl.run_evidence
       WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_15_%') AS evidence_rows,
      (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
       WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_15_CONSUMPTION_CONTRACT') AS gate_rows,
      (SELECT count(*) FROM msbf_ctl.profile_resolution_error
       WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors
)
SELECT
       r.run_id,
       r.run_status,
       x.latest_rows,
       x.archive_rows,
       x.comparison_rows,
       x.contract_rows,
       x.evidence_rows,
       x.gate_rows,
       x.blocking_errors,
       CASE WHEN r.run_status='M1_14_ACCEPTED'
              AND x.latest_rows=0 AND x.archive_rows=0
              AND x.comparison_rows=0 AND x.contract_rows=0
              AND x.evidence_rows=0 AND x.gate_rows=0
              AND x.blocking_errors=0
            THEN 'PASS' ELSE 'FAIL' END AS recovery_state_status
FROM r CROSS JOIN x;
