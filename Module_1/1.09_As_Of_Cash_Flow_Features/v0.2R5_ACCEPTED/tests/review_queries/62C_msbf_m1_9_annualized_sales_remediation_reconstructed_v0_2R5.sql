/* M1.9 v0.2R5 — read-only annualized-sales remediation reconstruction.
   Contingency only: use if 62B committed but its DBeaver result tab was lost. */
WITH r AS (
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), p AS (
 SELECT (profile_payload->>'annualization_days')::numeric annualization_days,
        profile_payload->>'annualized_sales_basis' annualized_sales_basis
 FROM msbf_ctl.policy_profile
 WHERE profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING' AND profile_version=1 AND status='APPROVED'
), actual AS (
 SELECT * FROM msbf_m1.m1_9_actual_snapshot((SELECT run_id FROM r))
 UNION ALL SELECT * FROM msbf_m1.m1_9_actual_feature_value((SELECT run_id FROM r))
), h AS (
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
            FILTER(WHERE entity_key LIKE 'SNAPSHOT|%')) snapshot_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
            FILTER(WHERE entity_key LIKE 'FEATURE|%')) feature_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) combined_hash,
        count(*) canonical_rows FROM actual
), e AS (
 SELECT max(metric_value_text) FILTER(WHERE evidence_code='M1_9_SNAPSHOT_SET_HASH') stored_snapshot_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_9_FEATURE_VALUE_SET_HASH') stored_feature_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_9_COMBINED_SET_HASH') stored_combined_hash,
        max(metric_value_numeric) FILTER(WHERE evidence_code='M1_9_R5_ANNUALIZED_IDENTITY_REMEDIATION') corrected_rows
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
), i AS (
 SELECT count(*) FILTER(WHERE (avg_daily_eligible_sales_90d IS NULL AND annualized_eligible_sales IS NOT NULL)
   OR (avg_daily_eligible_sales_90d IS NOT NULL AND annualized_eligible_sales IS DISTINCT FROM
       round(avg_daily_eligible_sales_90d*(SELECT annualization_days FROM p),2)::numeric(18,2))) violations
 FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r)
)
SELECT r.run_id,r.run_status,p.annualized_sales_basis,e.corrected_rows,h.canonical_rows,i.violations,
 h.snapshot_hash,e.stored_snapshot_hash,h.feature_hash,e.stored_feature_hash,h.combined_hash,e.stored_combined_hash,
 CASE WHEN r.run_status IN ('M1_9_GENERATED','M1_9_VALIDATED','M1_9_ACCEPTED')
       AND p.annualized_sales_basis='PERSISTED_ROUNDED_90D_AVERAGE'
       AND h.canonical_rows=55500 AND i.violations=0
       AND h.snapshot_hash=e.stored_snapshot_hash AND h.feature_hash=e.stored_feature_hash
       AND h.combined_hash=e.stored_combined_hash THEN 'PASS' ELSE 'FAIL' END remediation_reconciliation_status
FROM r CROSS JOIN p CROSS JOIN h CROSS JOIN e CROSS JOIN i;
