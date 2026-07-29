/* ============================================================================
MSBF M1.8 — Negative Controls
Version : v0.2R1
============================================================================ */
BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='10min';

DO $controls$
DECLARE v_run_id bigint;v_status text;v_pass integer:=0;v_message text;
BEGIN
  SELECT run_id,run_status INTO STRICT v_run_id,v_status
  FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
  IF v_status<>'M1_8_VALIDATED' THEN
    RAISE EXCEPTION 'M1.8 negative controls require M1_8_VALIDATED; observed %.',v_status;
  END IF;
  DELETE FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code LIKE 'M1_8_NEG_%';

  -- 01: disabled stage policy.
  BEGIN
    UPDATE msbf_ctl.policy_profile SET profile_payload=jsonb_set(profile_payload,'{generation_enabled}','false'::jsonb,true)
     WHERE profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY' AND profile_version=1;
    PERFORM msbf_m1.m1_8_assert_configuration(v_run_id);
    RAISE EXCEPTION 'M1_8_NEG_CONTROL_DID_NOT_REJECT';
  EXCEPTION WHEN OTHERS THEN
    v_message:=SQLERRM;
    IF v_message='M1.8 requires one approved, effective, enabled methodology policy profile.' THEN v_pass:=v_pass+1; ELSE RAISE; END IF;
  END;
  INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
    metric_value_text,unit_code,status,threshold_value_numeric,interpretation,created_at
  ) VALUES(v_run_id,'M1_8_NEG_01_DISABLED_POLICY','PORTFOLIO','Disabled M1.8 policy rejected',NULL,'PASS','TEXT','PASS',NULL,'The production configuration guard rejected a temporarily disabled stage policy.',clock_timestamp());

  -- 02: non-monotonic fraud thresholds.
  BEGIN
    UPDATE msbf_ctl.run_parameter_snapshot
       SET resolved_value=jsonb_set(resolved_value,'{value_numeric}',to_jsonb(5::numeric),true)
     WHERE run_id=v_run_id AND parameter_name='fraud_tier_3_threshold' AND scope_key='GLOBAL';
    PERFORM msbf_m1.m1_8_assert_configuration(v_run_id);
    RAISE EXCEPTION 'M1_8_NEG_CONTROL_DID_NOT_REJECT';
  EXCEPTION WHEN OTHERS THEN
    v_message:=SQLERRM;
    IF v_message='M1.8 fraud thresholds must be strictly increasing within [0,100].' THEN v_pass:=v_pass+1; ELSE RAISE; END IF;
  END;
  INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
    metric_value_text,unit_code,status,threshold_value_numeric,interpretation,created_at
  ) VALUES(v_run_id,'M1_8_NEG_02_FRAUD_THRESHOLDS','PORTFOLIO','Non-monotonic fraud thresholds rejected',NULL,'PASS','TEXT','PASS',NULL,'The configuration guard rejected a temporarily invalid fraud-tier ladder.',clock_timestamp());

  -- 03: unapproved methodology policy.
  BEGIN
    UPDATE msbf_ctl.policy_profile SET status='DRAFT'
     WHERE profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY' AND profile_version=1;
    PERFORM msbf_m1.m1_8_assert_configuration(v_run_id);
    RAISE EXCEPTION 'M1_8_NEG_CONTROL_DID_NOT_REJECT';
  EXCEPTION WHEN OTHERS THEN
    v_message:=SQLERRM;
    IF v_message='M1.8 requires one approved, effective, enabled methodology policy profile.' THEN v_pass:=v_pass+1; ELSE RAISE; END IF;
  END;
  INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
    metric_value_text,unit_code,status,threshold_value_numeric,interpretation,created_at
  ) VALUES(v_run_id,'M1_8_NEG_03_UNAPPROVED_POLICY','PORTFOLIO','Unapproved methodology policy rejected',NULL,'PASS','TEXT','PASS',NULL,'The configuration guard rejected a temporarily unapproved methodology profile.',clock_timestamp());

  -- 04: inactive required verification check.
  BEGIN
    UPDATE msbf_ref.verification_check_code SET active_flag=false WHERE check_code='PROCESSOR_MATCH';
    PERFORM msbf_m1.m1_8_assert_configuration(v_run_id);
    RAISE EXCEPTION 'M1_8_NEG_CONTROL_DID_NOT_REJECT';
  EXCEPTION WHEN OTHERS THEN
    v_message:=SQLERRM;
    IF v_message LIKE 'M1.8 requires six active verification checks;%' THEN v_pass:=v_pass+1; ELSE RAISE; END IF;
  END;
  INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
    metric_value_text,unit_code,status,threshold_value_numeric,interpretation,created_at
  ) VALUES(v_run_id,'M1_8_NEG_04_INACTIVE_CHECK','PORTFOLIO','Inactive required check rejected',NULL,'PASS','TEXT','PASS',NULL,'The configuration guard rejected a temporarily inactive processor-match check.',clock_timestamp());

  -- 05: prerequisite status drift.
  BEGIN
    UPDATE msbf_ctl.run_registry SET run_status='M1_7_FAILED' WHERE run_id=v_run_id;
    PERFORM msbf_m1.m1_8_assert_generation_ready(v_run_id);
    RAISE EXCEPTION 'M1_8_NEG_CONTROL_DID_NOT_REJECT';
  EXCEPTION WHEN OTHERS THEN
    v_message:=SQLERRM;
    IF v_message LIKE 'M1.8 generation requires M1_7_ACCEPTED; observed M1_7_FAILED.%' THEN v_pass:=v_pass+1; ELSE RAISE; END IF;
  END;
  INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
    metric_value_text,unit_code,status,threshold_value_numeric,interpretation,created_at
  ) VALUES(v_run_id,'M1_8_NEG_05_STATUS_DRIFT','PORTFOLIO','Prerequisite run-status drift rejected',NULL,'PASS','TEXT','PASS',NULL,'The generation guard rejected a temporary prerequisite-status drift.',clock_timestamp());

  -- 06: post-generation rerun.
  BEGIN
    UPDATE msbf_ctl.run_registry SET run_status='M1_7_ACCEPTED' WHERE run_id=v_run_id;
    PERFORM msbf_m1.m1_8_assert_generation_ready(v_run_id);
    RAISE EXCEPTION 'M1_8_NEG_CONTROL_DID_NOT_REJECT';
  EXCEPTION WHEN OTHERS THEN
    v_message:=SQLERRM;
    IF v_message LIKE 'M1.8 generation is one-time; existing verification rows %' THEN v_pass:=v_pass+1; ELSE RAISE; END IF;
  END;
  INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
    metric_value_text,unit_code,status,threshold_value_numeric,interpretation,created_at
  ) VALUES(v_run_id,'M1_8_NEG_06_REGENERATION','PORTFOLIO','Post-generation rerun rejected',NULL,'PASS','TEXT','PASS',NULL,'The generation guard rejected an attempted rerun over persisted evidence.',clock_timestamp());

  IF v_pass<>6 THEN RAISE EXCEPTION 'M1.8 negative controls did not all reject: %/6.',v_pass; END IF;
  IF (SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=v_run_id)<>'M1_8_VALIDATED' THEN
    RAISE EXCEPTION 'M1.8 negative controls did not restore M1_8_VALIDATED.';
  END IF;
  IF (SELECT count(*) FROM msbf_m1.verification_result WHERE created_by_run_id=v_run_id)<>4500
     OR (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=v_run_id)<>750 THEN
    RAISE EXCEPTION 'M1.8 negative controls changed persisted row counts.';
  END IF;
  IF NOT (SELECT coalesce((profile_payload->>'stress_continuity_tier_floor_to_baseline')::boolean,false)
          FROM msbf_ctl.policy_profile
          WHERE profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY' AND profile_version=1) THEN
    RAISE EXCEPTION 'M1.8 negative controls did not preserve the governed stress-continuity floor.';
  END IF;
END;
$controls$;

COMMIT;

SELECT evidence_code,metric_name,status,interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code LIKE 'M1_8_NEG_%'
ORDER BY evidence_code;
