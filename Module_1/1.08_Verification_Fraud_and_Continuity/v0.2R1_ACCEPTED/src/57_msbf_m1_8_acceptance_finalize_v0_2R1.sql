/* ============================================================================
MSBF M1.8 — Acceptance Finalizer
Version : v0.2R1
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB'; SET LOCAL jit=off; SET LOCAL lock_timeout='10s'; SET LOCAL statement_timeout='10min';

CREATE TEMP TABLE _m1_8_accept_actual ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_8_actual_entity_snapshot((SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE UNIQUE INDEX ON _m1_8_accept_actual(entity_key); ANALYZE _m1_8_accept_actual;

DO $accept$
DECLARE
  v_run_id bigint;v_status text;v_review integer;v_result text;v_finding text;
  v_pos integer;v_pos_pass integer;v_neg integer;v_neg_pass integer;v_failed integer;
  v_verification bigint;v_summary bigint;v_apps bigint;v_checks bigint;v_actual bigint;
  v_ver_hash text;v_sum_hash text;v_combined_hash text;
  v_stored_ver text;v_stored_sum text;v_stored_combined text;
  v_downstream bigint;v_errors bigint;v_improvements bigint;v_floor_enabled boolean;
BEGIN
  SELECT run_id,run_status INTO STRICT v_run_id,v_status FROM msbf_ctl.run_registry
   WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
  IF v_status<>'M1_8_VALIDATED' THEN RAISE EXCEPTION 'M1.8 acceptance requires M1_8_VALIDATED; observed %.',v_status; END IF;

  SELECT count(*),count(*) FILTER(WHERE status='PASS') INTO v_pos,v_pos_pass
  FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code LIKE 'M1_8_POS_%';
  SELECT count(*),count(*) FILTER(WHERE status='PASS') INTO v_neg,v_neg_pass
  FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code LIKE 'M1_8_NEG_%';
  SELECT count(*) INTO v_failed FROM msbf_ctl.run_evidence
   WHERE run_id=v_run_id AND evidence_code LIKE 'M1_8_%' AND status='FAIL';
  SELECT count(*),count(DISTINCT merchant_application_id),count(DISTINCT check_code)
    INTO v_verification,v_apps,v_checks FROM msbf_m1.verification_result WHERE created_by_run_id=v_run_id;
  SELECT count(*) INTO v_summary FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=v_run_id;
  SELECT count(*) INTO v_actual FROM _m1_8_accept_actual;
  SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER (WHERE entity_key LIKE 'VERIFICATION|%')),
         md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER (WHERE entity_key LIKE 'SUMMARY|%')),
         md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
    INTO v_ver_hash,v_sum_hash,v_combined_hash FROM _m1_8_accept_actual;
  SELECT max(metric_value_text) FILTER(WHERE evidence_code='M1_8_VERIFICATION_SET_HASH'),
         max(metric_value_text) FILTER(WHERE evidence_code='M1_8_SUMMARY_SET_HASH'),
         max(metric_value_text) FILTER(WHERE evidence_code='M1_8_COMBINED_SET_HASH')
    INTO v_stored_ver,v_stored_sum,v_stored_combined FROM msbf_ctl.run_evidence WHERE run_id=v_run_id;
  SELECT
    (SELECT count(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=v_run_id)+
    (SELECT count(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=v_run_id)+
    (SELECT count(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=v_run_id)+
    (SELECT count(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=v_run_id)+
    (SELECT count(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=v_run_id)+
    (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=v_run_id)+
    (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=v_run_id)+
    (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=v_run_id)+
    (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=v_run_id)+
    (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=v_run_id)
  INTO v_downstream;
  SELECT count(*) INTO v_errors FROM msbf_ctl.profile_resolution_error WHERE run_id=v_run_id AND severity='BLOCKING';
  SELECT count(*) INTO v_improvements
  FROM msbf_m1.application_verification_fraud_snapshot
  WHERE module1_run_id=v_run_id
    AND stress_processor_continuity_risk_tier<processor_continuity_risk_tier;
  SELECT coalesce((profile_payload->>'stress_continuity_tier_floor_to_baseline')::boolean,false)
    INTO STRICT v_floor_enabled
  FROM msbf_ctl.policy_profile
  WHERE profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY' AND profile_version=1;

  v_result:=CASE WHEN v_pos=60 AND v_pos_pass=60 AND v_neg=6 AND v_neg_pass=6 AND v_failed=0
                       AND v_verification=4500 AND v_summary=750 AND v_apps=750 AND v_checks=6 AND v_actual=5250
                       AND v_ver_hash=v_stored_ver AND v_sum_hash=v_stored_sum AND v_combined_hash=v_stored_combined
                       AND v_downstream=0 AND v_errors=0 AND v_improvements=0 AND v_floor_enabled THEN 'PASS' ELSE 'FAIL' END;
  v_finding:=format('positive=%s/%s; negative=%s/%s; verification=%s; summary=%s; canonical=%s; failed=%s; downstream=%s; blocking=%s; stress_improvements=%s; floor_enabled=%s',
                    v_pos_pass,v_pos,v_neg_pass,v_neg,v_verification,v_summary,v_actual,v_failed,v_downstream,v_errors,v_improvements,v_floor_enabled);
  SELECT coalesce(max(review_version),0)+1 INTO v_review FROM msbf_ctl.acceptance_gate_result
   WHERE run_id=v_run_id AND gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY';
  INSERT INTO msbf_ctl.acceptance_gate_result(
    run_id,gate_id,review_version,result_status,observed_value,threshold_value,finding,residual_limitation,reviewer_role
  ) VALUES(
    v_run_id,'M1_8_VERIFICATION_FRAUD_CONTINUITY',v_review,v_result,
    jsonb_build_object('positive',v_pos,'positive_pass',v_pos_pass,'negative',v_neg,'negative_pass',v_neg_pass,
                       'verification_rows',v_verification,'summary_rows',v_summary,'canonical_rows',v_actual,
                       'verification_hash',v_ver_hash,'summary_hash',v_sum_hash,'combined_hash',v_combined_hash,
                       'failed_evidence',v_failed,'downstream',v_downstream,'blocking_errors',v_errors,
                       'stress_tier_improvements',v_improvements,'stress_floor_enabled',v_floor_enabled)::text,
    '60 positive PASS; 6 negative PASS; 4,500 verification rows; 750 summaries; 5,250 canonical entities; exact hashes; zero stress-tier improvements; governed floor enabled; zero downstream/blocking errors.',
    v_finding,
    'Synthetic verification, fraud and processor-continuity evidence; not production KYB/AML, sanctions, fraud-model, cybersecurity or regulatory certification.',
    'Independent Validation'
  );
  INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
  VALUES(v_run_id,'M1_8_ACCEPTANCE_SUMMARY','PORTFOLIO','M1.8 acceptance summary',v_finding,'TEXT',v_result,'Formal M1.8 stage acceptance.')
  ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_value_numeric=NULL,metric_value_text=EXCLUDED.metric_value_text,
    unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();
  UPDATE msbf_ctl.run_registry SET run_status=CASE WHEN v_result='PASS' THEN 'M1_8_ACCEPTED' ELSE 'M1_8_FAILED' END,
      completed_at=CASE WHEN v_result='PASS' THEN clock_timestamp() ELSE NULL END,
      notes=coalesce(notes,'')||format(E'\nM1.8 acceptance review %s: %s.',v_review,v_result)
   WHERE run_id=v_run_id;
END;
$accept$;
COMMIT;

SELECT r.run_id,r.run_status,a.gate_id,a.review_version,a.result_status,a.observed_value,
       a.threshold_value,a.finding,a.residual_limitation,a.reviewed_at
FROM msbf_ctl.run_registry r
JOIN LATERAL(SELECT * FROM msbf_ctl.acceptance_gate_result x WHERE x.run_id=r.run_id
 AND x.gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY' ORDER BY review_version DESC LIMIT 1) a ON true
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;
