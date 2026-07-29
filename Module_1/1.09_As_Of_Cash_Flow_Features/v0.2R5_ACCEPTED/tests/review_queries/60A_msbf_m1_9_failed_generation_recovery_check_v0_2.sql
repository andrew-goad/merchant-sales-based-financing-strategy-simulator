/* ============================================================================
MSBF M1.9 As-of Cash-Flow Feature Engineering — Failed Generation Recovery Check
Version : v0.2
Purpose : Read-only proof that a cancelled/failed generation rolled back cleanly.
Run only after ROLLBACK; and only before a successful M1.9 generation.
============================================================================ */
WITH r AS (
 SELECT run_id,run_status,population_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), counts AS (
 SELECT
  (SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=r.run_id) snapshot_rows,
  (SELECT count(*) FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=r.run_id) feature_value_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code LIKE 'M1_9_%') evidence_rows,
  (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=r.run_id AND gate_id='M1_9_ASOF_CASHFLOW_FEATURES') gate_rows,
  (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=r.run_id) final_feature_rows,
  (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=r.run_id) risk_rows,
  (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=r.run_id) latest_rows,
  (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=r.run_id) archive_rows
 FROM r
)
SELECT current_database() database_name,current_user database_user,clock_timestamp() checked_at,
 r.run_id,r.run_status,r.population_id,c.*,
 CASE WHEN r.run_status='M1_8_ACCEPTED' AND c.snapshot_rows=0 AND c.feature_value_rows=0
       AND c.evidence_rows=0 AND c.gate_rows=0 AND c.final_feature_rows=0
       AND c.risk_rows=0 AND c.latest_rows=0 AND c.archive_rows=0
      THEN 'PASS' ELSE 'FAIL' END AS recovery_state_status
FROM r CROSS JOIN counts c;
