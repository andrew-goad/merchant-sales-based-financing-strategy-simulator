/* ============================================================================
MSBF M1.6 Matched Scenario Overlays — Negative Controls
Version : v0.2
Purpose : Demonstrate fail-closed behavior for missing scenario parameters,
          unapproved scenarios, disabled scenario history, temporal drift, and
          attempted post-generation reruns.
============================================================================ */
BEGIN;

DO $do$
DECLARE v_run_id bigint; v_status text;
BEGIN
 SELECT run_id,run_status INTO STRICT v_run_id,v_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 IF v_status NOT IN ('M1_6_VALIDATED','M1_6_FAILED') THEN
  RAISE EXCEPTION 'M1.6 negative controls require completed positive validation; observed run_status=%.',v_status;
 END IF;
 DELETE FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code LIKE 'M1_6_NEG_%';
END $do$;

CREATE TEMP TABLE _m1_6_negative_results(
 evidence_code text PRIMARY KEY,metric_name text NOT NULL,observed_value text NOT NULL,
 expected_value text NOT NULL,pass_flag boolean NOT NULL,interpretation text NOT NULL
) ON COMMIT DROP;

DO $do$
DECLARE v_run_id bigint; v_pass boolean:=false; v_msg text:='';
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 BEGIN
  UPDATE msbf_ctl.run_registry SET run_status='M1_5_ACCEPTED' WHERE run_id=v_run_id;
  DELETE FROM msbf_ctl.run_parameter_snapshot WHERE run_id=v_run_id AND parameter_name='scenario_sales_level_multiplier' AND scope_key='SCENARIO:RECESSION_ENERGY';
  PERFORM msbf_m1.m1_6_assert_generation_ready(v_run_id);
  RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
  v_msg:=SQLERRM; v_pass:=position('requires 32 resolved parameter/scope pairs' in SQLERRM)>0;
 END;
 INSERT INTO _m1_6_negative_results VALUES('M1_6_NEG_01_MISSING_PARAMETER_REJECTED','Missing scenario parameter',v_msg,
  'Generation rejected because fewer than 32 required parameter/scope pairs resolve',v_pass,
  'The scenario gate fails closed when a governed stress parameter is missing.');
END $do$;

DO $do$
DECLARE v_run_id bigint; v_scenario_id bigint; v_pass boolean:=false; v_msg text:='';
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 SELECT scenario_id INTO STRICT v_scenario_id FROM msbf_ctl.scenario_registry sr JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
 WHERE ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS' AND sr.scenario_code='RECESSION_ENERGY' AND sr.scenario_version=1;
 BEGIN
  UPDATE msbf_ctl.run_registry SET run_status='M1_5_ACCEPTED' WHERE run_id=v_run_id;
  UPDATE msbf_ctl.scenario_registry SET status='DRAFT' WHERE scenario_id=v_scenario_id;
  PERFORM msbf_m1.m1_6_assert_generation_ready(v_run_id);
  RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
  v_msg:=SQLERRM; v_pass:=position('requires exactly two approved scenarios' in SQLERRM)>0;
 END;
 INSERT INTO _m1_6_negative_results VALUES('M1_6_NEG_02_UNAPPROVED_SCENARIO_REJECTED','Unapproved stress scenario',v_msg,
  'Generation rejected unless BASELINE and RECESSION_ENERGY are both approved',v_pass,
  'The scenario registry fails closed when the stress scenario is not approved.');
END $do$;

DO $do$
DECLARE v_run_id bigint; v_pass boolean:=false; v_msg text:='';
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 BEGIN
  UPDATE msbf_ctl.run_registry SET run_status='M1_5_ACCEPTED' WHERE run_id=v_run_id;
  UPDATE msbf_ctl.run_parameter_snapshot SET resolved_value=jsonb_set(resolved_value,'{value_boolean}','false'::jsonb)
  WHERE run_id=v_run_id AND parameter_name='enable_scenario_history_flag' AND scope_key='GLOBAL';
  PERFORM msbf_m1.m1_6_assert_generation_ready(v_run_id);
  RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
  v_msg:=SQLERRM; v_pass:=position('scenario history is not enabled' in SQLERRM)>0;
 END;
 INSERT INTO _m1_6_negative_results VALUES('M1_6_NEG_03_SCENARIO_DISABLED_REJECTED','Scenario history disabled',v_msg,
  'Generation rejected when scenario persistence is disabled',v_pass,
  'The stage respects the frozen scenario-history enablement control.');
END $do$;

DO $do$
DECLARE v_run_id bigint; v_population_id text; v_pass boolean:=false; v_msg text:='';
BEGIN
 SELECT run_id,population_id INTO STRICT v_run_id,v_population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 BEGIN
  UPDATE msbf_ctl.run_registry SET run_status='M1_5_ACCEPTED' WHERE run_id=v_run_id;
  UPDATE msbf_m1.population_registry SET history_end_date=history_end_date-1 WHERE population_id=v_population_id;
  PERFORM msbf_m1.m1_6_assert_generation_ready(v_run_id);
  RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
  v_msg:=SQLERRM; v_pass:=position('requires accepted 180-day POS and deposit histories' in SQLERRM)>0;
 END;
 INSERT INTO _m1_6_negative_results VALUES('M1_6_NEG_04_HISTORY_DRIFT_REJECTED','Scenario history-window drift',v_msg,
  'Generation rejected when the accepted 180-day history changes',v_pass,
  'Matched comparison rejects temporal drift after baseline acceptance.');
END $do$;

DO $do$
DECLARE v_run_id bigint; v_pass boolean:=false; v_msg text:='';
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 BEGIN
  PERFORM msbf_m1.m1_6_assert_generation_ready(v_run_id);
  RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
  v_msg:=SQLERRM; v_pass:=position('requires run_status=M1_5_ACCEPTED' in SQLERRM)>0 OR position('regeneration is prohibited' in SQLERRM)>0;
 END;
 INSERT INTO _m1_6_negative_results VALUES('M1_6_NEG_05_REGENERATION_REJECTED','Post-generation rerun rejection',v_msg,
  'Generation rejected after scenario histories already exist',v_pass,
  'Persisted matched scenarios cannot be silently regenerated.');
END $do$;

INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
SELECT (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
       evidence_code,'PORTFOLIO',metric_name,observed_value,'TEXT',CASE WHEN pass_flag THEN 'PASS' ELSE 'FAIL' END,
       interpretation||' Expected: '||expected_value
FROM _m1_6_negative_results
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
 metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
 threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

COMMIT;

SELECT evidence_code,metric_name,metric_value_text,status,interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code LIKE 'M1_6_NEG_%'
ORDER BY evidence_code;
