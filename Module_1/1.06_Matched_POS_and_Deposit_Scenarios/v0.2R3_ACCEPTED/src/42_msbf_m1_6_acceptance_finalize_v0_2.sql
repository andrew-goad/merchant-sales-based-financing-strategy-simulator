/* ============================================================================
MSBF M1.6 Matched Scenario Overlays — Acceptance Finalizer
Version : v0.2
Purpose : Finalize M1.6 only when all positive validations, negative controls,
          deterministic hashes, matched-row controls, and stage boundaries pass.
============================================================================ */
BEGIN;

DO $do$
DECLARE
 v_run_id bigint; v_status text; v_positive integer; v_positive_pass integer; v_negative integer; v_negative_pass integer;
 v_failed integer; v_pos_rows bigint; v_dep_rows bigint; v_scenarios integer; v_merchants integer; v_dates integer;
 v_expected bigint; v_actual bigint; v_mismatch bigint; v_pos_stored text; v_dep_stored text; v_combined_stored text;
 v_pos_actual text; v_dep_actual text; v_combined_actual text; v_downstream bigint; v_errors bigint; v_review integer;
 v_result text; v_finding text;
BEGIN
 SELECT run_id,run_status INTO STRICT v_run_id,v_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 IF v_status='M1_6_ACCEPTED' THEN RAISE EXCEPTION 'M1.6 is already accepted.'; END IF;
 IF v_status NOT IN ('M1_6_VALIDATED','M1_6_FAILED') THEN RAISE EXCEPTION 'M1.6 acceptance requires completed validation; observed run_status=%.',v_status; END IF;

 SELECT COUNT(*),COUNT(*) FILTER(WHERE status='PASS') INTO v_positive,v_positive_pass
 FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code ~ '^M1_6_POS_[0-9]{2}_';
 SELECT COUNT(*),COUNT(*) FILTER(WHERE status='PASS') INTO v_negative,v_negative_pass
 FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code LIKE 'M1_6_NEG_%';
 SELECT COUNT(*) INTO v_failed FROM msbf_ctl.run_evidence
 WHERE run_id=v_run_id AND (evidence_code ~ '^M1_6_POS_[0-9]{2}_' OR evidence_code LIKE 'M1_6_NEG_%') AND status='FAIL';

 SELECT COUNT(*) INTO v_pos_rows FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=v_run_id;
 SELECT COUNT(*) INTO v_dep_rows FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=v_run_id;
 SELECT COUNT(DISTINCT scenario_id),COUNT(DISTINCT merchant_id),COUNT(DISTINCT observation_date)
 INTO v_scenarios,v_merchants,v_dates FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=v_run_id;
 SELECT COUNT(*) INTO v_expected FROM msbf_m1.m1_6_expected_scenario_snapshot(v_run_id);
 SELECT COUNT(*) INTO v_actual FROM msbf_m1.m1_6_actual_scenario_snapshot(v_run_id);
 SELECT COUNT(*) INTO v_mismatch FROM msbf_m1.m1_6_expected_scenario_snapshot(v_run_id) e
 FULL JOIN msbf_m1.m1_6_actual_scenario_snapshot(v_run_id) a USING(entity_type,entity_key)
 WHERE e.row_hash IS DISTINCT FROM a.row_hash;
 SELECT metric_value_text INTO v_pos_stored FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code='M1_6_POS_SCENARIO_SET_HASH' AND segment_key='PORTFOLIO';
 SELECT metric_value_text INTO v_dep_stored FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code='M1_6_DEPOSIT_SCENARIO_SET_HASH' AND segment_key='PORTFOLIO';
 SELECT metric_value_text INTO v_combined_stored FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code='M1_6_COMBINED_SET_HASH' AND segment_key='PORTFOLIO';
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) INTO v_pos_actual FROM msbf_m1.m1_6_actual_scenario_snapshot(v_run_id) WHERE entity_type='POS_SCENARIO';
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) INTO v_dep_actual FROM msbf_m1.m1_6_actual_scenario_snapshot(v_run_id) WHERE entity_type='DEPOSIT_SCENARIO';
 SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) INTO v_combined_actual FROM msbf_m1.m1_6_actual_scenario_snapshot(v_run_id);
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=v_run_id)
 INTO v_downstream;
 SELECT COUNT(*) INTO v_errors FROM msbf_ctl.profile_resolution_error WHERE run_id=v_run_id AND severity='BLOCKING';

 v_result:=CASE WHEN v_positive=62 AND v_positive_pass=62 AND v_negative=5 AND v_negative_pass=5 AND v_failed=0
                       AND v_pos_rows=270000 AND v_dep_rows=270000 AND v_scenarios=2 AND v_merchants=750 AND v_dates=180
                       AND v_expected=540000 AND v_actual=540000 AND v_mismatch=0
                       AND v_pos_stored=v_pos_actual AND v_dep_stored=v_dep_actual AND v_combined_stored=v_combined_actual
                       AND v_downstream=0 AND v_errors=0 THEN 'PASS' ELSE 'FAIL' END;
 v_finding:=format('Positive %s/%s; negative %s/%s; POS rows %s; deposit rows %s; scenarios %s; merchants %s; dates %s; canonical %s/%s; mismatches %s; downstream %s; blocking errors %s.',
  v_positive_pass,v_positive,v_negative_pass,v_negative,v_pos_rows,v_dep_rows,v_scenarios,v_merchants,v_dates,v_expected,v_actual,v_mismatch,v_downstream,v_errors);
 SELECT COALESCE(MAX(review_version),0)+1 INTO v_review FROM msbf_ctl.acceptance_gate_result WHERE run_id=v_run_id AND gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS';
 INSERT INTO msbf_ctl.acceptance_gate_result(run_id,gate_id,review_version,result_status,observed_value,threshold_value,finding,residual_limitation,reviewer_role)
 VALUES(v_run_id,'M1_6_MATCHED_SCENARIO_OVERLAYS',v_review,v_result,
  jsonb_build_object('positive_checks',v_positive,'positive_passes',v_positive_pass,'negative_controls',v_negative,'negative_passes',v_negative_pass,
   'pos_rows',v_pos_rows,'deposit_rows',v_dep_rows,'scenarios',v_scenarios,'merchants',v_merchants,'dates',v_dates,
   'expected_rows',v_expected,'actual_rows',v_actual,'mismatches',v_mismatch,'pos_hash',v_pos_actual,'deposit_hash',v_dep_actual,'combined_hash',v_combined_actual)::text,
  '62 positive PASS; 5 negative PASS; 270000 POS rows; 270000 deposit rows; 540000 canonical entities; 0 mismatches; 0 downstream rows; 0 blocking errors.',
  v_finding,'Synthetic controlled sensitivities; not economic forecasts or calibrated stress models.','Independent Validation');

 INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
 VALUES(v_run_id,'M1_6_ACCEPTANCE_SUMMARY','PORTFOLIO','M1.6 acceptance summary',v_finding,'TEXT',v_result,
  'Formal stage acceptance based on matched-row, deterministic, directional, negative-control, and boundary evidence.')
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
  metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
  threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

 UPDATE msbf_ctl.run_registry SET run_status=CASE WHEN v_result='PASS' THEN 'M1_6_ACCEPTED' ELSE 'M1_6_FAILED' END,
  completed_at=CASE WHEN v_result='PASS' THEN clock_timestamp() ELSE NULL END,
  notes=COALESCE(notes,'')||E'\nM1.6 acceptance review '||v_review||': '||v_result||'.'
 WHERE run_id=v_run_id;
END $do$;

COMMIT;

SELECT r.run_id,r.run_status,a.gate_id,a.review_version,a.result_status,a.observed_value,a.threshold_value,a.finding,a.residual_limitation,a.reviewed_at
FROM msbf_ctl.run_registry r JOIN LATERAL (
 SELECT * FROM msbf_ctl.acceptance_gate_result x WHERE x.run_id=r.run_id AND x.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' ORDER BY review_version DESC LIMIT 1
) a ON true
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;
