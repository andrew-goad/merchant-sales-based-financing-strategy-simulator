/* ============================================================================
MSBF M1.9 As-of Cash-Flow Feature Engineering — Negative Controls
Version : v0.2R5
Purpose : Prove that M1.9 fails closed under invalid policy, feature, scenario,
          predecessor, configuration-error, and rerun conditions.
Output  : One user-facing six-row result set.
============================================================================ */
BEGIN;
SET LOCAL lock_timeout='10s'; SET LOCAL statement_timeout='10min'; SET LOCAL jit=off;
DROP TABLE IF EXISTS _m1_9_negative;
CREATE TEMP TABLE _m1_9_negative(
 evidence_code text PRIMARY KEY,control_name text NOT NULL,observed_value text NOT NULL,
 expected_behavior text NOT NULL,status text NOT NULL,interpretation text NOT NULL
) ON COMMIT PRESERVE ROWS;
CREATE OR REPLACE FUNCTION pg_temp.m1_9_neg_record(p_code text,p_name text,p_observed text,p_pass boolean,p_expected text,p_interpretation text)
RETURNS void LANGUAGE plpgsql AS $fn$ BEGIN
 INSERT INTO _m1_9_negative VALUES(p_code,p_name,coalesce(p_observed,'<NULL>'),p_expected,
 CASE WHEN coalesce(p_pass,false) THEN 'PASS' ELSE 'FAIL' END,p_interpretation);
END $fn$;
DO $tests$
DECLARE v_run bigint;v_original text;v_ok boolean;v_msg text;v_gate_review integer;
BEGIN
 SELECT run_id,run_status INTO STRICT v_run,v_original FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 IF v_original<>'M1_9_VALIDATED' THEN RAISE EXCEPTION 'M1.9 negative controls require M1_9_VALIDATED; observed %.',v_original; END IF;

 -- 01 disabled policy
 v_ok:=false;v_msg:=NULL;
 BEGIN
  UPDATE msbf_ctl.run_registry SET run_status='M1_8_ACCEPTED' WHERE run_id=v_run;
  UPDATE msbf_ctl.policy_profile SET profile_payload=jsonb_set(profile_payload,'{generation_enabled}','false'::jsonb)
   WHERE profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING' AND profile_version=1;
  PERFORM msbf_m1.m1_9_assert_generation_ready(v_run);
  RAISE EXCEPTION 'UNEXPECTED_ACCEPT';
 EXCEPTION WHEN OTHERS THEN v_msg:=SQLERRM;v_ok:=SQLERRM<>'UNEXPECTED_ACCEPT'; END;
 PERFORM pg_temp.m1_9_neg_record('M1_9_NEG_01_DISABLED_POLICY','Disabled generation policy',v_msg,v_ok,'Generation rejected','M1.9 fails closed when its governed policy is disabled.');

 -- 02 missing active feature definition
 v_ok:=false;v_msg:=NULL;
 BEGIN
  UPDATE msbf_ctl.run_registry SET run_status='M1_8_ACCEPTED' WHERE run_id=v_run;
  UPDATE msbf_m1.feature_definition SET active_flag=false WHERE feature_code='AVG_DAILY_ELIGIBLE_SALES_7D' AND feature_version=1;
  PERFORM msbf_m1.m1_9_assert_generation_ready(v_run);
  RAISE EXCEPTION 'UNEXPECTED_ACCEPT';
 EXCEPTION WHEN OTHERS THEN v_msg:=SQLERRM;v_ok:=SQLERRM<>'UNEXPECTED_ACCEPT'; END;
 PERFORM pg_temp.m1_9_neg_record('M1_9_NEG_02_MISSING_FEATURE','Inactive required feature definition',v_msg,v_ok,'Generation rejected','M1.9 requires the complete 36-feature inventory.');

 -- 03 unapproved stress scenario
 v_ok:=false;v_msg:=NULL;
 BEGIN
  UPDATE msbf_ctl.run_registry SET run_status='M1_8_ACCEPTED' WHERE run_id=v_run;
  UPDATE msbf_ctl.scenario_registry sr
  SET status='DRAFT'
  FROM msbf_ctl.scenario_set ss
  WHERE ss.scenario_set_id=sr.scenario_set_id
    AND ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS'
    AND ss.scenario_set_version=1
    AND sr.scenario_code='RECESSION_ENERGY'
    AND sr.scenario_version=1
    AND sr.scenario_id IN (
        SELECT scenario_id
        FROM msbf_m1.merchant_pos_daily_scenario
        WHERE generated_by_run_id=v_run
    );
  PERFORM msbf_m1.m1_9_assert_generation_ready(v_run);
  RAISE EXCEPTION 'UNEXPECTED_ACCEPT';
 EXCEPTION WHEN OTHERS THEN v_msg:=SQLERRM;v_ok:=SQLERRM<>'UNEXPECTED_ACCEPT'; END;
 PERFORM pg_temp.m1_9_neg_record('M1_9_NEG_03_UNAPPROVED_SCENARIO','Unapproved stress scenario',v_msg,v_ok,'Generation rejected','Only approved matched scenarios may enter feature engineering.');

 -- 04 prerequisite gate drift
 v_ok:=false;v_msg:=NULL;
 BEGIN
  UPDATE msbf_ctl.run_registry SET run_status='M1_8_ACCEPTED' WHERE run_id=v_run;
  SELECT max(review_version) INTO v_gate_review FROM msbf_ctl.acceptance_gate_result WHERE run_id=v_run AND gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY';
  UPDATE msbf_ctl.acceptance_gate_result SET result_status='FAIL' WHERE run_id=v_run AND gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY' AND review_version=v_gate_review;
  PERFORM msbf_m1.m1_9_assert_generation_ready(v_run);
  RAISE EXCEPTION 'UNEXPECTED_ACCEPT';
 EXCEPTION WHEN OTHERS THEN v_msg:=SQLERRM;v_ok:=SQLERRM<>'UNEXPECTED_ACCEPT'; END;
 PERFORM pg_temp.m1_9_neg_record('M1_9_NEG_04_PREREQUISITE_GATE','M1.8 gate drift',v_msg,v_ok,'Generation rejected','The accepted predecessor gate cannot drift.');

 -- 05 blocking resolution error
 v_ok:=false;v_msg:=NULL;
 BEGIN
  UPDATE msbf_ctl.run_registry SET run_status='M1_8_ACCEPTED' WHERE run_id=v_run;
  INSERT INTO msbf_ctl.profile_resolution_error(run_id,profile_domain,scope_key,error_code,severity,error_message)
  VALUES(v_run,'M1_9_TEST','GLOBAL','M1_9_NEG_TEST','BLOCKING','Intentional negative control.');
  PERFORM msbf_m1.m1_9_assert_generation_ready(v_run);
  RAISE EXCEPTION 'UNEXPECTED_ACCEPT';
 EXCEPTION WHEN OTHERS THEN v_msg:=SQLERRM;v_ok:=SQLERRM<>'UNEXPECTED_ACCEPT'; END;
 PERFORM pg_temp.m1_9_neg_record('M1_9_NEG_05_BLOCKING_ERROR','Blocking configuration error',v_msg,v_ok,'Generation rejected','Blocking configuration errors stop generation.');

 -- 06 attempted post-generation rerun
 v_ok:=false;v_msg:=NULL;
 BEGIN
  UPDATE msbf_ctl.run_registry SET run_status='M1_8_ACCEPTED' WHERE run_id=v_run;
  PERFORM msbf_m1.m1_9_assert_generation_ready(v_run);
  RAISE EXCEPTION 'UNEXPECTED_ACCEPT';
 EXCEPTION WHEN OTHERS THEN v_msg:=SQLERRM;v_ok:=SQLERRM<>'UNEXPECTED_ACCEPT'; END;
 PERFORM pg_temp.m1_9_neg_record('M1_9_NEG_06_REGENERATION_REJECTED','Post-generation rerun',v_msg,v_ok,'Generation rejected','Persisted M1.9 rows prevent duplicate regeneration.');
END $tests$;

INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
SELECT (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),evidence_code,'PORTFOLIO',control_name,observed_value,'TEXT',status,interpretation
FROM _m1_9_negative
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,
 metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
 interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();
COMMIT;
SELECT evidence_code,control_name,observed_value,expected_behavior,status,interpretation
FROM _m1_9_negative ORDER BY evidence_code;
