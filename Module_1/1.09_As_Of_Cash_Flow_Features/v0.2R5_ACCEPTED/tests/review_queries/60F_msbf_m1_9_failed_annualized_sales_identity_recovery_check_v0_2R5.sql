/* ============================================================================
MSBF M1.9 — Failed Annualized-Sales Identity Validation Recovery Check
Version : v0.2R5
Purpose : Fail-closed confirmation that the only M1.9 positive-validation
          failure is the annualized-sales identity and that committed M1.9
          generation remains structurally and canonically intact.
Output  : One session-filterable diagnostic result set.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='10min';

DROP TABLE IF EXISTS _m1_9_r5_recovery;
CREATE TEMP TABLE _m1_9_r5_recovery ON COMMIT PRESERVE ROWS AS
WITH r AS (
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), policy AS (
    SELECT (profile_payload->>'annualization_days')::numeric AS annualization_days
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING'
      AND profile_version=1
      AND status='APPROVED'
), actual AS (
    SELECT * FROM msbf_m1.m1_9_actual_snapshot((SELECT run_id FROM r))
    UNION ALL
    SELECT * FROM msbf_m1.m1_9_actual_feature_value((SELECT run_id FROM r))
), hashes AS (
    SELECT
      md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
          FILTER (WHERE entity_key LIKE 'SNAPSHOT|%')) AS snapshot_hash,
      md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
          FILTER (WHERE entity_key LIKE 'FEATURE|%')) AS feature_hash,
      md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash,
      count(*) AS canonical_rows
    FROM actual
), evidence_hashes AS (
    SELECT
      max(metric_value_text) FILTER(WHERE evidence_code='M1_9_SNAPSHOT_SET_HASH') AS snapshot_hash,
      max(metric_value_text) FILTER(WHERE evidence_code='M1_9_FEATURE_VALUE_SET_HASH') AS feature_hash,
      max(metric_value_text) FILTER(WHERE evidence_code='M1_9_COMBINED_SET_HASH') AS combined_hash,
      count(*) FILTER(WHERE evidence_code LIKE 'M1_9_POS_%') AS positive_checks,
      count(*) FILTER(WHERE evidence_code LIKE 'M1_9_POS_%' AND status='PASS') AS positive_passes,
      count(*) FILTER(WHERE evidence_code LIKE 'M1_9_POS_%' AND status='FAIL') AS positive_failures,
      string_agg(evidence_code,',' ORDER BY evidence_code)
        FILTER(WHERE evidence_code LIKE 'M1_9_POS_%' AND status='FAIL') AS failed_codes,
      max(metric_value_text)
        FILTER(WHERE evidence_code='M1_9_POS_38_ANNUALIZED_SALES_IDENTITY') AS reported_pos38_violations,
      count(*) FILTER(WHERE evidence_code LIKE 'M1_9_NEG_%') AS negative_controls,
      count(*) FILTER(WHERE evidence_code='M1_9_ACCEPTANCE_SUMMARY') AS acceptance_summary_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
), identity AS (
    SELECT
      count(*) FILTER(
        WHERE avg_daily_eligible_sales_90d IS NOT NULL
          AND abs(annualized_eligible_sales-
                  round(avg_daily_eligible_sales_90d*(SELECT annualization_days FROM policy),2))>0.02
      ) AS original_pos38_violations,
      count(*) FILTER(
        WHERE (avg_daily_eligible_sales_90d IS NULL AND annualized_eligible_sales IS NOT NULL)
           OR (avg_daily_eligible_sales_90d IS NOT NULL AND annualized_eligible_sales IS DISTINCT FROM
               round(avg_daily_eligible_sales_90d*(SELECT annualization_days FROM policy),2)::numeric(18,2))
      ) AS full_identity_violations,
      count(*) FILTER(
        WHERE avg_daily_eligible_sales_90d IS NULL AND annualized_eligible_sales IS NOT NULL
      ) AS availability_mismatches
    FROM msbf_m1.application_cashflow_feature_snapshot
    WHERE module1_run_id=(SELECT run_id FROM r)
), rows AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot
       WHERE module1_run_id=(SELECT run_id FROM r)) AS snapshot_rows,
      (SELECT count(*) FROM msbf_m1.cashflow_feature_value
       WHERE module1_run_id=(SELECT run_id FROM r)) AS feature_value_rows,
      (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
       WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_9_ASOF_CASHFLOW_FEATURES') AS gate_rows,
      (SELECT count(*) FROM msbf_ctl.profile_resolution_error
       WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors
)
SELECT
  r.run_id,r.run_status,p.annualization_days,
  rw.snapshot_rows,rw.feature_value_rows,h.canonical_rows,
  e.positive_checks,e.positive_passes,e.positive_failures,e.failed_codes,
  e.reported_pos38_violations,i.original_pos38_violations,
  i.full_identity_violations,i.availability_mismatches,
  e.negative_controls,e.acceptance_summary_rows,rw.gate_rows,rw.blocking_errors,
  h.snapshot_hash AS recomputed_snapshot_hash,e.snapshot_hash AS stored_snapshot_hash,
  h.feature_hash AS recomputed_feature_hash,e.feature_hash AS stored_feature_hash,
  h.combined_hash AS recomputed_combined_hash,e.combined_hash AS stored_combined_hash,
  CASE WHEN r.run_status='M1_9_FAILED'
         AND rw.snapshot_rows=1500 AND rw.feature_value_rows=54000 AND h.canonical_rows=55500
         AND e.positive_checks=66 AND e.positive_passes=65 AND e.positive_failures=1
         AND e.failed_codes='M1_9_POS_38_ANNUALIZED_SALES_IDENTITY'
         AND e.reported_pos38_violations::integer=856
         AND i.original_pos38_violations=856
         AND e.negative_controls=0 AND e.acceptance_summary_rows=0 AND rw.gate_rows=0
         AND rw.blocking_errors=0
         AND h.snapshot_hash=e.snapshot_hash
         AND h.feature_hash=e.feature_hash
         AND h.combined_hash=e.combined_hash
       THEN 'PASS' ELSE 'FAIL' END AS recovery_state_status
FROM r CROSS JOIN policy p CROSS JOIN hashes h CROSS JOIN evidence_hashes e
CROSS JOIN identity i CROSS JOIN rows rw;

DO $guard$
BEGIN
  IF (SELECT recovery_state_status FROM _m1_9_r5_recovery)<>'PASS' THEN
    RAISE EXCEPTION 'M1.9 R5 recovery-state diagnosis did not pass. Review the diagnostic row before remediation.';
  END IF;
END $guard$;
COMMIT;
SELECT * FROM _m1_9_r5_recovery;
