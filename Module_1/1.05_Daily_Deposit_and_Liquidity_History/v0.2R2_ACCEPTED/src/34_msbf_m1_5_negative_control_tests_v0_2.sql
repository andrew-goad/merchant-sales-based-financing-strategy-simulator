/* ============================================================================
MSBF M1.5 Daily Deposit & Liquidity History — Negative Controls
Version : v0.2
Purpose : Demonstrate fail-closed behavior for missing liquidity parameters,
          invalid DEPOSIT_DAILY source readiness, history-window drift, and
          prohibited post-generation regeneration.
============================================================================ */
BEGIN;

DO $do$
DECLARE v_run_id bigint; v_status text;
BEGIN
 SELECT run_id,run_status INTO STRICT v_run_id,v_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 IF v_status NOT IN ('M1_5_VALIDATED','M1_5_FAILED') THEN
   RAISE EXCEPTION 'M1.5 negative controls require completed positive validation; observed run_status=%.',v_status;
 END IF;
 DELETE FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code LIKE 'M1_5_NEG_%';
END $do$;

CREATE TEMP TABLE _m1_5_negative_results(
 evidence_code text PRIMARY KEY,metric_name text NOT NULL,observed_value text NOT NULL,
 expected_value text NOT NULL,pass_flag boolean NOT NULL,interpretation text NOT NULL
) ON COMMIT DROP;

DO $do$
DECLARE v_run_id bigint; v_pass boolean:=false; v_msg text:='';
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 BEGIN
   UPDATE msbf_ctl.run_registry SET run_status='M1_4_ACCEPTED' WHERE run_id=v_run_id;
   DELETE FROM msbf_ctl.run_parameter_snapshot
   WHERE run_id=v_run_id AND parameter_name='deposit_capture_rate_center' AND scope_key='INDUSTRY:GENERAL_RETAIL';
   PERFORM msbf_m1.m1_5_assert_generation_ready(v_run_id);
   RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
   v_msg:=SQLERRM;
   v_pass:=position('requires 32 resolved parameter/scope pairs' in SQLERRM)>0;
 END;
 INSERT INTO _m1_5_negative_results VALUES(
  'M1_5_NEG_01_MISSING_PARAMETER_REJECTED','Missing required deposit parameter',v_msg,
  'Generation rejected because fewer than 32 required parameter/scope pairs resolve',v_pass,
  'The generation gate fails closed when one governed industry liquidity parameter is missing.');
END $do$;

DO $do$
DECLARE v_run_id bigint; v_pass boolean:=false; v_msg text:='';
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 BEGIN
   UPDATE msbf_ctl.run_registry SET run_status='M1_4_ACCEPTED' WHERE run_id=v_run_id;
   UPDATE msbf_ctl.run_source_snapshot SET quality_status='NOT_READY'
   WHERE run_id=v_run_id AND source_code='DEPOSIT_DAILY';
   PERFORM msbf_m1.m1_5_assert_generation_ready(v_run_id);
   RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
   v_msg:=SQLERRM;
   v_pass:=position('requires exactly one approved, contract-ready DEPOSIT_DAILY source snapshot' in SQLERRM)>0;
 END;
 INSERT INTO _m1_5_negative_results VALUES(
  'M1_5_NEG_02_SOURCE_NOT_READY_REJECTED','Invalid deposit source readiness',v_msg,
  'Generation rejected because DEPOSIT_DAILY is not contract-ready',v_pass,
  'The source gate fails closed when the deposit/liquidity source is not ready.');
END $do$;

DO $do$
DECLARE v_run_id bigint; v_population_id text; v_pass boolean:=false; v_msg text:='';
BEGIN
 SELECT run_id,population_id INTO STRICT v_run_id,v_population_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 BEGIN
   UPDATE msbf_ctl.run_registry SET run_status='M1_4_ACCEPTED' WHERE run_id=v_run_id;
   UPDATE msbf_m1.population_registry SET history_end_date=history_end_date-1 WHERE population_id=v_population_id;
   PERFORM msbf_m1.m1_5_assert_generation_ready(v_run_id);
   RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
   v_msg:=SQLERRM;
   v_pass:=position('requires 750 merchants, 750 applications, 180 days, and 135000 accepted POS rows' in SQLERRM)>0;
 END;
 INSERT INTO _m1_5_negative_results VALUES(
  'M1_5_NEG_03_HISTORY_DRIFT_REJECTED','History-window drift',v_msg,
  'Generation rejected when the accepted 180-day window changes',v_pass,
  'The stage rejects temporal drift after upstream acceptance.');
END $do$;

DO $do$
DECLARE v_run_id bigint; v_pass boolean:=false; v_msg text:='';
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 BEGIN
   PERFORM msbf_m1.m1_5_assert_generation_ready(v_run_id);
   RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
   v_msg:=SQLERRM;
   v_pass:=position('requires run_status=M1_4_ACCEPTED' in SQLERRM)>0
           OR position('regeneration is prohibited' in SQLERRM)>0;
 END;
 INSERT INTO _m1_5_negative_results VALUES(
  'M1_5_NEG_04_REGENERATION_REJECTED','Post-generation rerun rejection',v_msg,
  'Generation rejected after baseline deposit history already exists',v_pass,
  'Accepted upstream state and persisted M1.5 rows cannot be silently regenerated.');
END $do$;

INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
SELECT (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
       evidence_code,'PORTFOLIO',metric_name,observed_value,'TEXT',CASE WHEN pass_flag THEN 'PASS' ELSE 'FAIL' END,
       interpretation||' Expected: '||expected_value
FROM _m1_5_negative_results
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
 metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
 threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

COMMIT;

SELECT evidence_code,metric_name,metric_value_text,status,interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code LIKE 'M1_5_NEG_%'
ORDER BY evidence_code;
