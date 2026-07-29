/* ============================================================================
MSBF M1.9 As-of Cash-Flow Feature Engineering — Acceptance Finalizer
Version : v0.2R5
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB'; SET LOCAL jit=off; SET LOCAL lock_timeout='10s'; SET LOCAL statement_timeout='10min';
CREATE TEMP TABLE _m1_9_accept_actual ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_9_actual_snapshot((SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1))
UNION ALL
SELECT * FROM msbf_m1.m1_9_actual_feature_value((SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE UNIQUE INDEX ON _m1_9_accept_actual(entity_key); ANALYZE _m1_9_accept_actual;
DO $accept$
DECLARE v_run bigint;v_status text;v_review integer;v_result text;v_finding text;
 v_pos integer;v_pos_pass integer;v_neg integer;v_neg_pass integer;v_failed integer;
 v_snap bigint;v_long bigint;v_apps bigint;v_scen integer;v_features integer;v_actual bigint;
 v_sh text;v_fh text;v_ch text;v_ssh text;v_sfh text;v_sch text;
 v_downstream bigint;v_errors bigint;v_identity bigint;v_basis text;v_days numeric;
BEGIN
 SELECT run_id,run_status INTO STRICT v_run,v_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 IF v_status<>'M1_9_VALIDATED' THEN RAISE EXCEPTION 'M1.9 acceptance requires M1_9_VALIDATED; observed %.',v_status; END IF;
 SELECT count(*),count(*) FILTER(WHERE status='PASS') INTO v_pos,v_pos_pass FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code LIKE 'M1_9_POS_%';
 SELECT count(*),count(*) FILTER(WHERE status='PASS') INTO v_neg,v_neg_pass FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code LIKE 'M1_9_NEG_%';
 SELECT count(*) INTO v_failed FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code LIKE 'M1_9_%' AND status='FAIL';
 SELECT count(*),count(DISTINCT merchant_application_id),count(DISTINCT scenario_id) INTO v_snap,v_apps,v_scen FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=v_run;
 SELECT count(*),count(DISTINCT feature_code) INTO v_long,v_features FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=v_run;
 SELECT count(*) INTO v_actual FROM _m1_9_accept_actual;
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER (WHERE entity_key LIKE 'SNAPSHOT|%')),
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER (WHERE entity_key LIKE 'FEATURE|%')),
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
 INTO v_sh,v_fh,v_ch FROM _m1_9_accept_actual;
 SELECT max(metric_value_text) FILTER(WHERE evidence_code='M1_9_SNAPSHOT_SET_HASH'),
        max(metric_value_text) FILTER(WHERE evidence_code='M1_9_FEATURE_VALUE_SET_HASH'),
        max(metric_value_text) FILTER(WHERE evidence_code='M1_9_COMBINED_SET_HASH')
 INTO v_ssh,v_sfh,v_sch FROM msbf_ctl.run_evidence WHERE run_id=v_run;
 SELECT
  (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=v_run)+
  (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=v_run)+
  (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=v_run)+
  (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=v_run)+
  (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=v_run)
 INTO v_downstream;
 SELECT count(*) INTO v_errors FROM msbf_ctl.profile_resolution_error WHERE run_id=v_run AND severity='BLOCKING';
 SELECT (profile_payload->>'annualization_days')::numeric,profile_payload->>'annualized_sales_basis' INTO v_days,v_basis FROM msbf_ctl.policy_profile WHERE profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING' AND profile_version=1 AND status='APPROVED';
 SELECT count(*) FILTER(WHERE (avg_daily_eligible_sales_90d IS NULL AND annualized_eligible_sales IS NOT NULL) OR (avg_daily_eligible_sales_90d IS NOT NULL AND annualized_eligible_sales IS DISTINCT FROM round(avg_daily_eligible_sales_90d*v_days,2)::numeric(18,2))) INTO v_identity FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=v_run;
 v_result:=CASE WHEN v_pos=66 AND v_pos_pass=66 AND v_neg=6 AND v_neg_pass=6 AND v_failed=0
   AND v_snap=1500 AND v_apps=750 AND v_scen=2 AND v_long=54000 AND v_features=36 AND v_actual=55500
   AND v_sh=v_ssh AND v_fh=v_sfh AND v_ch=v_sch AND v_downstream=0 AND v_errors=0
   AND v_identity=0 AND v_days=365 AND v_basis='PERSISTED_ROUNDED_90D_AVERAGE' THEN 'PASS' ELSE 'FAIL' END;
 v_finding:=format('positive=%s/%s; negative=%s/%s; snapshots=%s; feature_values=%s; features=%s; canonical=%s; failed=%s; downstream=%s; blocking=%s; annualized_identity=%s; annualization_days=%s; annualized_basis=%s',
  v_pos_pass,v_pos,v_neg_pass,v_neg,v_snap,v_long,v_features,v_actual,v_failed,v_downstream,v_errors,v_identity,v_days,v_basis);
 SELECT coalesce(max(review_version),0)+1 INTO v_review FROM msbf_ctl.acceptance_gate_result WHERE run_id=v_run AND gate_id='M1_9_ASOF_CASHFLOW_FEATURES';
 INSERT INTO msbf_ctl.acceptance_gate_result(run_id,gate_id,review_version,result_status,observed_value,threshold_value,finding,residual_limitation,reviewer_role)
 VALUES(v_run,'M1_9_ASOF_CASHFLOW_FEATURES',v_review,v_result,
  jsonb_build_object('positive',v_pos,'positive_pass',v_pos_pass,'negative',v_neg,'negative_pass',v_neg_pass,
  'snapshot_rows',v_snap,'feature_value_rows',v_long,'features',v_features,'canonical_rows',v_actual,
  'snapshot_hash',v_sh,'feature_hash',v_fh,'combined_hash',v_ch,'failed_evidence',v_failed,
  'downstream',v_downstream,'blocking_errors',v_errors,'annualized_identity_violations',v_identity,'annualization_days',v_days,'annualized_sales_basis',v_basis)::text,
  '66 positive PASS; 6 negative PASS; 1,500 wide snapshots; 54,000 long feature values; 55,500 canonical entities; exact hashes; annualized identity zero; zero downstream/blocking errors.',
  v_finding,
  'Synthetic scenario-aware cash-flow features; not production-calibrated capacity, credit risk, pricing, loss, accounting, capital or regulatory outputs.',
  'Independent Validation');
 INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
 VALUES(v_run,'M1_9_ACCEPTANCE_SUMMARY','PORTFOLIO','M1.9 acceptance summary',v_finding,'TEXT',v_result,'Formal M1.9 stage acceptance.')
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_value_numeric=NULL,metric_value_text=EXCLUDED.metric_value_text,
 unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();
 UPDATE msbf_ctl.run_registry SET run_status=CASE WHEN v_result='PASS' THEN 'M1_9_ACCEPTED' ELSE 'M1_9_FAILED' END,
  completed_at=CASE WHEN v_result='PASS' THEN clock_timestamp() ELSE NULL END,
  notes=coalesce(notes,'')||format(E'
M1.9 acceptance review %s: %s.',v_review,v_result)
 WHERE run_id=v_run;
END $accept$;
COMMIT;
SELECT r.run_id,r.run_status,a.gate_id,a.review_version,a.result_status,a.observed_value,a.threshold_value,a.finding,a.residual_limitation,a.reviewed_at
FROM msbf_ctl.run_registry r JOIN LATERAL(SELECT * FROM msbf_ctl.acceptance_gate_result x WHERE x.run_id=r.run_id AND x.gate_id='M1_9_ASOF_CASHFLOW_FEATURES' ORDER BY review_version DESC LIMIT 1)a ON true
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;
