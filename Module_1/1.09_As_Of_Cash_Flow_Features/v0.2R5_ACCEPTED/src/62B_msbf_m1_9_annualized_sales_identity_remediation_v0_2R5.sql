/* ============================================================================
MSBF M1.9 — Annualized-Sales Identity Controlled Remediation
Version : v0.2R5
Purpose : Preserve committed M1.9 feature engineering while correcting the
          annualized-sales derivation to use the persisted rounded 90-day
          average, align wide/long availability, rebuild affected row hashes,
          rebuild set hashes, preserve audit evidence, and return the run to
          M1_9_GENERATED for revised validation.
Boundary: No upstream history, scenario, source-quality, fraud/continuity, or
          downstream credit-risk records are regenerated.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='15min';

DROP TABLE IF EXISTS _m1_9_r5_remediation_result;
CREATE TEMP TABLE _m1_9_r5_remediation_result(
    run_id bigint,run_status text,annualization_days numeric,
    original_pos38_violations bigint,full_identity_violations_before bigint,
    availability_mismatches_before bigint,changed_snapshot_rows bigint,
    changed_feature_rows bigint,remaining_identity_violations bigint,
    wide_long_mismatches bigint,row_hash_mismatches bigint,
    snapshot_hash text,feature_value_hash text,combined_hash text,
    remediation_status text
) ON COMMIT PRESERVE ROWS;

CREATE TEMP TABLE _m1_9_r5_ctx ON COMMIT DROP AS
SELECT r.run_id,r.run_status,
       (p.profile_payload->>'annualization_days')::numeric AS annualization_days
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.policy_profile p
  ON p.profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING'
 AND p.profile_version=1 AND p.status='APPROVED'
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

CREATE TEMP TABLE _m1_9_r5_pre_actual ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_9_actual_snapshot((SELECT run_id FROM _m1_9_r5_ctx))
UNION ALL
SELECT * FROM msbf_m1.m1_9_actual_feature_value((SELECT run_id FROM _m1_9_r5_ctx));
CREATE UNIQUE INDEX ON _m1_9_r5_pre_actual(entity_key);

CREATE TEMP TABLE _m1_9_r5_pre_hash ON COMMIT DROP AS
SELECT
 md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
     FILTER(WHERE entity_key LIKE 'SNAPSHOT|%')) AS snapshot_hash,
 md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
     FILTER(WHERE entity_key LIKE 'FEATURE|%')) AS feature_hash,
 md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash,
 count(*) AS canonical_rows
FROM _m1_9_r5_pre_actual;

CREATE TEMP TABLE _m1_9_r5_pre_state ON COMMIT DROP AS
WITH e AS (
 SELECT count(*) FILTER(WHERE evidence_code LIKE 'M1_9_POS_%') positive_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_9_POS_%' AND status='PASS') positive_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_9_POS_%' AND status='FAIL') positive_failures,
        string_agg(evidence_code,',' ORDER BY evidence_code)
          FILTER(WHERE evidence_code LIKE 'M1_9_POS_%' AND status='FAIL') failed_codes,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_9_POS_38_ANNUALIZED_SALES_IDENTITY') pos38,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_9_SNAPSHOT_SET_HASH') snapshot_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_9_FEATURE_VALUE_SET_HASH') feature_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_9_COMBINED_SET_HASH') combined_hash,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_9_NEG_%') negative_controls,
        count(*) FILTER(WHERE evidence_code='M1_9_ACCEPTANCE_SUMMARY') acceptance_rows
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_r5_ctx)
), i AS (
 SELECT
  count(*) FILTER(WHERE avg_daily_eligible_sales_90d IS NOT NULL
    AND abs(annualized_eligible_sales-round(avg_daily_eligible_sales_90d*(SELECT annualization_days FROM _m1_9_r5_ctx),2))>0.02) AS pos38,
  count(*) FILTER(WHERE (avg_daily_eligible_sales_90d IS NULL AND annualized_eligible_sales IS NOT NULL)
    OR (avg_daily_eligible_sales_90d IS NOT NULL AND annualized_eligible_sales IS DISTINCT FROM
        round(avg_daily_eligible_sales_90d*(SELECT annualization_days FROM _m1_9_r5_ctx),2)::numeric(18,2))) AS full_identity,
  count(*) FILTER(WHERE avg_daily_eligible_sales_90d IS NULL AND annualized_eligible_sales IS NOT NULL) AS availability_mismatches
 FROM msbf_m1.application_cashflow_feature_snapshot
 WHERE module1_run_id=(SELECT run_id FROM _m1_9_r5_ctx)
), rw AS (
 SELECT
  (SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_9_r5_ctx)) snapshots,
  (SELECT count(*) FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=(SELECT run_id FROM _m1_9_r5_ctx)) feature_values,
  (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m1_9_r5_ctx) AND gate_id='M1_9_ASOF_CASHFLOW_FEATURES') gate_rows,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_9_r5_ctx) AND severity='BLOCKING') blocking_errors
)
SELECT e.*,i.pos38 AS calculated_pos38,i.full_identity,i.availability_mismatches,rw.*
FROM e CROSS JOIN i CROSS JOIN rw;

DO $guard$
DECLARE s record;h record;c record;
BEGIN
 SELECT * INTO s FROM _m1_9_r5_pre_state;
 SELECT * INTO h FROM _m1_9_r5_pre_hash;
 SELECT * INTO c FROM _m1_9_r5_ctx;
 IF c.run_status<>'M1_9_FAILED'
    OR s.snapshots<>1500 OR s.feature_values<>54000 OR h.canonical_rows<>55500
    OR s.positive_checks<>66 OR s.positive_passes<>65 OR s.positive_failures<>1
    OR s.failed_codes<>'M1_9_POS_38_ANNUALIZED_SALES_IDENTITY'
    OR s.pos38::integer<>856 OR s.calculated_pos38<>856
    OR s.negative_controls<>0 OR s.acceptance_rows<>0 OR s.gate_rows<>0 OR s.blocking_errors<>0
    OR h.snapshot_hash<>s.snapshot_hash OR h.feature_hash<>s.feature_hash OR h.combined_hash<>s.combined_hash THEN
   RAISE EXCEPTION 'M1.9 R5 remediation guard failed; database state does not match the isolated POS_38 failure.';
 END IF;
END $guard$;

/* Preserve the original finding before replacing the positive-control set. */
INSERT INTO msbf_ctl.run_evidence(
 run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,
 unit_code,status,interpretation
)
SELECT (SELECT run_id FROM _m1_9_r5_ctx),
       'M1_9_R5_ORIGINAL_POS38_FINDING','PORTFOLIO',
       'Original annualized-sales identity finding',856,NULL,'COUNT','PASS',
       'Historical validation finding retained: 856 rows used an unrounded 90-day average before persistence; corrected under v0.2R5.'
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
 metric_value_numeric=EXCLUDED.metric_value_numeric,metric_value_text=EXCLUDED.metric_value_text,
 unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,
 created_at=clock_timestamp();

UPDATE msbf_ctl.policy_profile
SET profile_payload=jsonb_set(
      jsonb_set(profile_payload,'{annualized_sales_basis}',to_jsonb('PERSISTED_ROUNDED_90D_AVERAGE'::text),true),
      '{annualized_sales_scale}','2'::jsonb,true),
    change_reason='M1.9 v0.2R5 annualized-sales identity correction before acceptance.',
    last_review_date=(SELECT as_of_date FROM msbf_ctl.run_registry WHERE run_id=(SELECT run_id FROM _m1_9_r5_ctx))
WHERE profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING'
  AND profile_version=1 AND status='APPROVED';

UPDATE msbf_m1.feature_definition
SET formula_description='Persisted two-decimal trailing ninety-day average daily eligible sales multiplied by the governed annualization-day parameter and rounded to two decimals.',
    production_boundary='Synthetic as-of cash-flow feature; not production-calibrated. Annualization is derived from the persisted rounded 90-day average.'
WHERE feature_code='ANNUALIZED_ELIGIBLE_SALES' AND feature_version=1;

DO $policy_feature_guard$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM msbf_ctl.policy_profile WHERE profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING' AND profile_version=1 AND status='APPROVED' AND profile_payload->>'annualized_sales_basis'='PERSISTED_ROUNDED_90D_AVERAGE' AND (profile_payload->>'annualized_sales_scale')::integer=2) THEN
   RAISE EXCEPTION 'M1.9 R5 policy update did not persist the governed annualized-sales basis.';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM msbf_m1.feature_definition WHERE feature_code='ANNUALIZED_ELIGIBLE_SALES' AND feature_version=1 AND formula_description LIKE 'Persisted two-decimal trailing ninety-day average%') THEN
   RAISE EXCEPTION 'M1.9 R5 annualized-sales feature-definition update did not persist.';
 END IF;
END $policy_feature_guard$;

CREATE TEMP TABLE _m1_9_r5_targets ON COMMIT DROP AS
SELECT s.module1_run_id,s.scenario_id,s.merchant_application_id,
       s.annualized_eligible_sales AS old_annualized,
       CASE WHEN s.avg_daily_eligible_sales_90d IS NULL THEN NULL::numeric(18,2)
            ELSE round(s.avg_daily_eligible_sales_90d*(SELECT annualization_days FROM _m1_9_r5_ctx),2)::numeric(18,2)
       END AS new_annualized
FROM msbf_m1.application_cashflow_feature_snapshot s
WHERE s.module1_run_id=(SELECT run_id FROM _m1_9_r5_ctx);
CREATE UNIQUE INDEX ON _m1_9_r5_targets(scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_9_r5_changed ON COMMIT DROP AS
SELECT * FROM _m1_9_r5_targets WHERE old_annualized IS DISTINCT FROM new_annualized;
CREATE UNIQUE INDEX ON _m1_9_r5_changed(scenario_id,merchant_application_id);

UPDATE msbf_m1.application_cashflow_feature_snapshot s
SET annualized_eligible_sales=t.new_annualized
FROM _m1_9_r5_changed t
WHERE s.module1_run_id=t.module1_run_id
  AND s.scenario_id=t.scenario_id
  AND s.merchant_application_id=t.merchant_application_id;

UPDATE msbf_m1.application_cashflow_feature_snapshot s
SET feature_snapshot_hash=msbf_m1.m1_9_hash_jsonb(to_jsonb(s)-'feature_snapshot_hash'-'created_at')
WHERE s.module1_run_id=(SELECT run_id FROM _m1_9_r5_ctx)
  AND EXISTS(SELECT 1 FROM _m1_9_r5_changed t
             WHERE t.scenario_id=s.scenario_id
               AND t.merchant_application_id=s.merchant_application_id);

UPDATE msbf_m1.cashflow_feature_value v
SET value_numeric=CASE WHEN t.new_annualized IS NULL THEN NULL::numeric(24,10)
                       ELSE t.new_annualized::numeric(24,10) END,
    value_status=CASE WHEN t.new_annualized IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END
FROM _m1_9_r5_changed t
WHERE v.module1_run_id=t.module1_run_id
  AND v.scenario_id=t.scenario_id
  AND v.merchant_application_id=t.merchant_application_id
  AND v.feature_code='ANNUALIZED_ELIGIBLE_SALES'
  AND v.feature_version=1;

UPDATE msbf_m1.cashflow_feature_value v
SET calculation_hash=msbf_m1.m1_9_hash_jsonb(to_jsonb(v)-'calculation_hash'-'created_at')
WHERE v.module1_run_id=(SELECT run_id FROM _m1_9_r5_ctx)
  AND v.feature_code='ANNUALIZED_ELIGIBLE_SALES'
  AND v.feature_version=1
  AND EXISTS(SELECT 1 FROM _m1_9_r5_changed t
             WHERE t.scenario_id=v.scenario_id
               AND t.merchant_application_id=v.merchant_application_id);

ANALYZE msbf_m1.application_cashflow_feature_snapshot;
ANALYZE msbf_m1.cashflow_feature_value;

CREATE TEMP TABLE _m1_9_r5_actual_after ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_9_actual_snapshot((SELECT run_id FROM _m1_9_r5_ctx))
UNION ALL
SELECT * FROM msbf_m1.m1_9_actual_feature_value((SELECT run_id FROM _m1_9_r5_ctx));
CREATE UNIQUE INDEX ON _m1_9_r5_actual_after(entity_key);
ANALYZE _m1_9_r5_actual_after;

CREATE TEMP TABLE _m1_9_r5_stored_after ON COMMIT DROP AS
SELECT 'SNAPSHOT|'||scenario_id||'|'||merchant_application_id AS entity_key,feature_snapshot_hash AS row_hash
FROM msbf_m1.application_cashflow_feature_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m1_9_r5_ctx)
UNION ALL
SELECT 'FEATURE|'||scenario_id||'|'||merchant_application_id||'|'||feature_code||'|v'||feature_version,
       calculation_hash
FROM msbf_m1.cashflow_feature_value
WHERE module1_run_id=(SELECT run_id FROM _m1_9_r5_ctx);
CREATE UNIQUE INDEX ON _m1_9_r5_stored_after(entity_key);

CREATE TEMP TABLE _m1_9_r5_after ON COMMIT DROP AS
WITH h AS (
 SELECT
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
      FILTER(WHERE entity_key LIKE 'SNAPSHOT|%')) AS snapshot_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
      FILTER(WHERE entity_key LIKE 'FEATURE|%')) AS feature_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash,
  count(*) AS canonical_rows
 FROM _m1_9_r5_actual_after
), mm AS (
 SELECT count(*) AS mismatches
 FROM _m1_9_r5_stored_after s FULL JOIN _m1_9_r5_actual_after a USING(entity_key)
 WHERE s.row_hash IS DISTINCT FROM a.row_hash
), identity AS (
 SELECT count(*) FILTER(
   WHERE (avg_daily_eligible_sales_90d IS NULL AND annualized_eligible_sales IS NOT NULL)
      OR (avg_daily_eligible_sales_90d IS NOT NULL AND annualized_eligible_sales IS DISTINCT FROM
          round(avg_daily_eligible_sales_90d*(SELECT annualization_days FROM _m1_9_r5_ctx),2)::numeric(18,2))
 ) AS violations
 FROM msbf_m1.application_cashflow_feature_snapshot
 WHERE module1_run_id=(SELECT run_id FROM _m1_9_r5_ctx)
), wl AS (
 SELECT count(*) AS mismatches
 FROM msbf_m1.application_cashflow_feature_snapshot s
 JOIN msbf_m1.cashflow_feature_value v
   ON v.module1_run_id=s.module1_run_id
  AND v.scenario_id=s.scenario_id
  AND v.merchant_application_id=s.merchant_application_id
  AND v.feature_code='ANNUALIZED_ELIGIBLE_SALES' AND v.feature_version=1
 WHERE s.module1_run_id=(SELECT run_id FROM _m1_9_r5_ctx)
   AND ((s.annualized_eligible_sales IS NULL AND (v.value_status<>'NOT_AVAILABLE' OR v.value_numeric IS NOT NULL))
     OR (s.annualized_eligible_sales IS NOT NULL AND
         (v.value_status<>'AVAILABLE' OR v.value_numeric IS DISTINCT FROM s.annualized_eligible_sales::numeric(24,10))))
)
SELECT h.*,mm.mismatches AS row_hash_mismatches,identity.violations AS identity_violations,
       wl.mismatches AS wide_long_mismatches
FROM h CROSS JOIN mm CROSS JOIN identity CROSS JOIN wl;

DO $finalize$
DECLARE a record;pre record;v_changed bigint;v_run bigint;
BEGIN
 SELECT * INTO a FROM _m1_9_r5_after;
 SELECT * INTO pre FROM _m1_9_r5_pre_state;
 SELECT run_id INTO v_run FROM _m1_9_r5_ctx;
 SELECT count(*) INTO v_changed FROM _m1_9_r5_changed;
 IF a.canonical_rows<>55500 OR a.row_hash_mismatches<>0 OR a.identity_violations<>0
    OR a.wide_long_mismatches<>0 OR v_changed<1 THEN
   RAISE EXCEPTION 'M1.9 R5 remediation reconciliation failed: canonical %, hash mismatches %, identity %, wide/long %, changed %.',
     a.canonical_rows,a.row_hash_mismatches,a.identity_violations,a.wide_long_mismatches,v_changed;
 END IF;

 DELETE FROM msbf_ctl.run_evidence
 WHERE run_id=v_run AND (evidence_code LIKE 'M1_9_POS_%' OR evidence_code LIKE 'M1_9_NEG_%'
                         OR evidence_code='M1_9_ACCEPTANCE_SUMMARY');

 INSERT INTO msbf_ctl.run_evidence(
  run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,
  unit_code,status,interpretation
 ) VALUES
 (v_run,'M1_9_SNAPSHOT_SET_HASH','PORTFOLIO','M1.9 wide-snapshot set hash',NULL,a.snapshot_hash,'HASH','PASS','Canonical hash across 1,500 scenario-aware feature snapshots after v0.2R5 annualized-sales identity remediation.'),
 (v_run,'M1_9_FEATURE_VALUE_SET_HASH','PORTFOLIO','M1.9 long-feature-value set hash',NULL,a.feature_hash,'HASH','PASS','Canonical hash across 54,000 long feature values after v0.2R5 annualized-sales identity remediation.'),
 (v_run,'M1_9_COMBINED_SET_HASH','PORTFOLIO','M1.9 combined canonical set hash',NULL,a.combined_hash,'HASH','PASS','Canonical hash across 55,500 M1.9 entities after v0.2R5 remediation.'),
 (v_run,'M1_9_CANONICAL_ENTITY_COUNT','PORTFOLIO','M1.9 canonical entities',55500,NULL,'COUNT','PASS','1,500 wide snapshots plus 54,000 long feature values.'),
 (v_run,'M1_9_CANONICAL_MISMATCH_COUNT','PORTFOLIO','M1.9 canonical mismatches',0,NULL,'COUNT','PASS','Persisted hashes independently recompute after remediation.'),
 (v_run,'M1_9_GENERATION_SPEC','PORTFOLIO','M1.9 generation specification',NULL,
  'M1_9_METHOD_V1|2 scenarios|750 applications|36 features|annualized=PERSISTED_ROUNDED_90D_AVERAGE*365|as-of and no-leakage controls',
  'TEXT','PASS','Governed M1.9 feature-engineering specification with explicit annualized-sales identity.'),
 (v_run,'M1_9_GENERATION_SUMMARY','PORTFOLIO','M1.9 generation summary',NULL,
  format('snapshots=1500|feature_values=54000|canonical=55500|mismatches=0|annualized_rows_corrected=%s|hash=%s',v_changed,a.combined_hash),
  'TEXT','PASS','M1.9 generation remains complete after controlled annualized-sales remediation.'),
 (v_run,'M1_9_R5_ANNUALIZED_IDENTITY_REMEDIATION','PORTFOLIO','M1.9 annualized-sales identity remediation',v_changed,NULL,'COUNT','PASS',
  format('Corrected %s wide snapshots and matching long feature values; original POS_38 violations=%s; remaining identity violations=0.',v_changed,pre.calculated_pos38))
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
  metric_name=EXCLUDED.metric_name,metric_value_numeric=EXCLUDED.metric_value_numeric,
  metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,
  status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

 UPDATE msbf_ctl.run_registry
 SET run_status='M1_9_GENERATED',completed_at=NULL,
     notes=coalesce(notes,'')||format(E'\nM1.9 v0.2R5 annualized-sales identity remediation applied to %s snapshots; positive validation reset for rerun.',v_changed)
 WHERE run_id=v_run;

 INSERT INTO _m1_9_r5_remediation_result
 SELECT v_run,'M1_9_GENERATED',(SELECT annualization_days FROM _m1_9_r5_ctx),
        pre.calculated_pos38,pre.full_identity,pre.availability_mismatches,
        v_changed,v_changed,a.identity_violations,a.wide_long_mismatches,
        a.row_hash_mismatches,a.snapshot_hash,a.feature_hash,a.combined_hash,'PASS';
END $finalize$;
COMMIT;
SELECT * FROM _m1_9_r5_remediation_result;
