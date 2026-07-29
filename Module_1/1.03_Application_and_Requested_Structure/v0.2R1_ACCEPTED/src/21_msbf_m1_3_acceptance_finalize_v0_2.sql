/* ============================================================================
MSBF M1.3 Acceptance Finalizer
Version : v0.2
Purpose : Resolve the M1.3 gate from frozen positive/negative evidence,
          deterministic application reconciliation, and strict stage boundaries.
============================================================================ */
BEGIN;

DO $$
DECLARE
 v_run_id bigint; v_status text; v_positive_count integer; v_positive_pass integer;
 v_negative_count integer; v_negative_pass integer; v_failed integer; v_mismatches bigint;
 v_expected_hash text; v_actual_hash text; v_stored_hash text; v_downstream bigint;
 v_errors integer; v_result text; v_review_version integer; v_observed text;
BEGIN
 SELECT run_id,run_status INTO STRICT v_run_id,v_status
 FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;

 IF v_status='M1_3_ACCEPTED' THEN RAISE EXCEPTION 'M1.3 is already accepted; acceptance result is frozen.'; END IF;
 IF v_status NOT IN ('M1_3_VALIDATED','M1_3_FAILED') THEN
  RAISE EXCEPTION 'M1.3 finalization requires completed validation; observed run_status=%.',v_status;
 END IF;

 SELECT COUNT(*),COUNT(*) FILTER(WHERE status='PASS') INTO v_positive_count,v_positive_pass
 FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code LIKE 'M1_3_POS_%';
 SELECT COUNT(*),COUNT(*) FILTER(WHERE status='PASS') INTO v_negative_count,v_negative_pass
 FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code LIKE 'M1_3_NEG_%';
 SELECT COUNT(*) INTO v_failed FROM msbf_ctl.run_evidence
 WHERE run_id=v_run_id AND (evidence_code LIKE 'M1_3_POS_%' OR evidence_code LIKE 'M1_3_NEG_%') AND status='FAIL';

 SELECT COUNT(*) INTO v_mismatches
 FROM msbf_m1.m1_3_expected_application_snapshot(v_run_id) e
 FULL JOIN msbf_m1.m1_3_actual_application_snapshot(v_run_id) a USING(entity_key)
 WHERE e.row_hash IS DISTINCT FROM a.row_hash;
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) INTO v_expected_hash FROM msbf_m1.m1_3_expected_application_snapshot(v_run_id);
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) INTO v_actual_hash FROM msbf_m1.m1_3_actual_application_snapshot(v_run_id);
 SELECT metric_value_text INTO v_stored_hash FROM msbf_ctl.run_evidence
 WHERE run_id=v_run_id AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO';

 SELECT
  (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=v_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=v_run_id)
 INTO v_downstream;

 SELECT COUNT(*) INTO v_errors FROM msbf_ctl.profile_resolution_error WHERE run_id=v_run_id AND severity='BLOCKING';

 v_result:=CASE WHEN v_positive_count=42 AND v_positive_pass=42
                     AND v_negative_count=3 AND v_negative_pass=3
                     AND v_failed=0 AND v_mismatches=0
                     AND v_expected_hash IS NOT NULL AND v_expected_hash=v_actual_hash AND v_expected_hash=v_stored_hash
                     AND (SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=v_run_id)=750
                     AND v_downstream=0 AND v_errors=0
                THEN 'PASS' ELSE 'FAIL' END;

 v_observed:=jsonb_build_object(
  'positive_checks',v_positive_count,'positive_passes',v_positive_pass,
  'negative_controls',v_negative_count,'negative_passes',v_negative_pass,
  'failed_evidence',v_failed,'row_mismatches',v_mismatches,
  'application_set_hash',v_actual_hash,'downstream_rows',v_downstream,'blocking_errors',v_errors)::text;

 SELECT COALESCE(MAX(review_version),0)+1 INTO v_review_version
 FROM msbf_ctl.acceptance_gate_result WHERE run_id=v_run_id AND gate_id='M1_3_APPLICATION_REQUEST';

 INSERT INTO msbf_ctl.acceptance_gate_result(
  run_id,gate_id,review_version,result_status,observed_value,threshold_value,finding,residual_limitation,reviewer_role)
 VALUES(v_run_id,'M1_3_APPLICATION_REQUEST',v_review_version,v_result,v_observed,
  '{"positive_checks":42,"negative_controls":3,"row_mismatches":0,"downstream_rows":0,"blocking_errors":0}',
  CASE WHEN v_result='PASS' THEN 'M1.3 deterministic application and requested sales-linked structure generation passed all acceptance criteria.'
       ELSE 'M1.3 failed one or more application-generation acceptance criteria.' END,
  'Synthetic requested structures only. This gate does not approve credit, pricing, legal classification, disclosures, calibrated risk, profitability, accounting, capital, fair-lending, or production use.',
  'Project Owner / Validation');

 INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
 VALUES(v_run_id,'M1_3_ACCEPTANCE_SUMMARY','PORTFOLIO','M1.3 application-request acceptance',v_observed,'JSON_TEXT',v_result,
  CASE WHEN v_result='PASS' THEN 'M1.3 accepted; M1.4 daily POS and settlement history generation is authorized.'
       ELSE 'M1.3 failed; subsequent generation remains prohibited.' END)
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
  metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
  threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

 IF v_result='PASS' THEN
  UPDATE msbf_ctl.run_registry SET run_status='M1_3_ACCEPTED',notes='M1.3 deterministic application and requested sales-linked structures accepted. Authorized for M1.4 daily POS and settlement history generation.' WHERE run_id=v_run_id;
 ELSE
  UPDATE msbf_ctl.run_registry SET run_status='M1_3_FAILED',notes='M1.3 acceptance failed; subsequent analytical generation prohibited.' WHERE run_id=v_run_id;
 END IF;
END $$;

COMMIT;

SELECT r.run_id,r.run_code,r.run_version,r.run_status,p.population_id,p.population_status,p.population_hash,
       g.gate_id,g.review_version,g.result_status,g.reviewed_at,g.finding,g.residual_limitation,
       r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') AS application_set_hash
FROM msbf_ctl.run_registry r
JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
LEFT JOIN LATERAL(
 SELECT * FROM msbf_ctl.acceptance_gate_result x WHERE x.run_id=r.run_id AND x.gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1
) g ON true
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;
