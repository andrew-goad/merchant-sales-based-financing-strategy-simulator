/* ============================================================================
MSBF M1.3 Negative Control Tests
Version : v0.2
Purpose : Prove fail-closed behavior for missing mix inputs, invalid weights,
          and unauthorized regeneration after applications exist.
============================================================================ */
BEGIN;

DO $$
DECLARE v_run_id bigint; v_status text;
BEGIN
 SELECT run_id,run_status INTO STRICT v_run_id,v_status
 FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 IF v_status NOT IN ('M1_3_VALIDATED','M1_3_FAILED') THEN
  RAISE EXCEPTION 'M1.3 negative controls require positive validation first; observed run_status=%.',v_status;
 END IF;
 DELETE FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code LIKE 'M1_3_NEG_%';
END $$;

DO $$
DECLARE v_run_id bigint; v_pass boolean:=false; v_error text;
BEGIN
 SELECT run_id INTO v_run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 BEGIN
  PERFORM 1 FROM msbf_m1.m1_3_weighted_assignment(v_run_id,'MISSING_PARAMETER','EXPECTED_PAYOFF_DAYS','NEG_MISSING');
 EXCEPTION WHEN OTHERS THEN v_error:=SQLERRM; v_pass:=position('found no scoped values' in SQLERRM)>0; END;
 INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
 VALUES(v_run_id,'M1_3_NEG_01_MISSING_WEIGHT_PARAMETER','PORTFOLIO','Missing request-mix parameter rejected',COALESCE(v_error,'NO_EXCEPTION'),'TEXT',CASE WHEN v_pass THEN 'PASS' ELSE 'FAIL' END,'Missing governed request-mix inputs must fail before assignment.')
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();
END $$;

DO $$
DECLARE v_run_id bigint; v_pass boolean:=false; v_error text;
BEGIN
 SELECT run_id INTO v_run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 BEGIN
  PERFORM 1 FROM msbf_m1.m1_3_weighted_assignment_json(v_run_id,'{"A":0.70,"B":0.40}'::jsonb,'NEG_BAD_SUM');
 EXCEPTION WHEN OTHERS THEN v_error:=SQLERRM; v_pass:=position('weights summing to one' in SQLERRM)>0; END;
 INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
 VALUES(v_run_id,'M1_3_NEG_02_INVALID_WEIGHT_SUM','PORTFOLIO','Invalid request-mix weight sum rejected',COALESCE(v_error,'NO_EXCEPTION'),'TEXT',CASE WHEN v_pass THEN 'PASS' ELSE 'FAIL' END,'Non-reconciling request-mix weights must fail closed.')
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();
END $$;

DO $$
DECLARE v_run_id bigint; v_pass boolean:=false; v_error text;
BEGIN
 SELECT run_id INTO v_run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 BEGIN
  PERFORM msbf_m1.m1_3_assert_generation_ready(v_run_id);
 EXCEPTION WHEN OTHERS THEN v_error:=SQLERRM; v_pass:=position('requires run_status=M1_2_ACCEPTED' in SQLERRM)>0 OR position('already exist' in SQLERRM)>0; END;
 INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
 VALUES(v_run_id,'M1_3_NEG_03_REGENERATION_REJECTED','PORTFOLIO','Unauthorized application regeneration rejected',COALESCE(v_error,'NO_EXCEPTION'),'TEXT',CASE WHEN v_pass THEN 'PASS' ELSE 'FAIL' END,'Once M1.3 application rows exist, destructive regeneration is prohibited.')
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();
END $$;

COMMIT;

SELECT evidence_code,metric_name,status,metric_value_text,interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code LIKE 'M1_3_NEG_%'
ORDER BY evidence_code;
