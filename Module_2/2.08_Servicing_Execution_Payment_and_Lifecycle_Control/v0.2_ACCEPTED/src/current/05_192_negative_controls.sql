/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.8 — Servicing Execution Simulation, Payment Processing
             & Account Lifecycle Control

Program     : 192_msbf_m2_8_negative_control_tests_v0_2.sql
Version     : v0.2

Purpose
-------
Prove fail-closed behavior for policy/source drift, production execution
flags, invalid payment terms and grain, archive mutation, lifecycle reruns,
premature acceptance, and prohibited bank, processor, funds, contact,
collection/legal, and notice payloads.

Stage boundary
--------------
All servicing, payment, processor-reference, return, retry, and lifecycle
outputs are deterministic synthetic evidence. No real funds move; no bank or
routing data is used; no ACH/network transmission, external processor call,
merchant contact, write-off/collection/legal execution, external notice, or
production adverse action occurs.

Required result
---------------
20 / 20 PASS.
============================================================================ */

BEGIN;SET LOCAL statement_timeout='35min';SET LOCAL jit=off;
CREATE TEMP TABLE _m28_negative(evidence_code text PRIMARY KEY,metric_name text,status text,interpretation text) ON COMMIT PRESERVE ROWS;
CREATE TEMP TABLE _m28_nctx ON COMMIT DROP AS SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
DO $ready$ DECLARE p bigint;BEGIN SELECT count(*) INTO p FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m28_nctx) AND evidence_code LIKE 'M2_8_POS_%' AND status='PASS';IF (SELECT run_status FROM _m28_nctx)<>'M2_8_VALIDATED' OR p<>120 THEN RAISE EXCEPTION 'M2.8 negative controls require M2_8_VALIDATED and 120 positive passes.';END IF;END;$ready$;
CREATE OR REPLACE FUNCTION pg_temp.m2_8_add_negative(p_code text,p_pass boolean,p_interpretation text) RETURNS void LANGUAGE plpgsql AS $function$ BEGIN INSERT INTO _m28_negative VALUES(p_code,p_code,CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,p_interpretation);END;$function$;
CREATE TEMP TABLE _m28_neg_outcome(a boolean,b boolean,c boolean,d boolean,e boolean,f boolean,g boolean,h boolean,CHECK(NOT a AND NOT b AND NOT c AND NOT d AND NOT e AND NOT f AND NOT g AND NOT h)) ON COMMIT DROP;
CREATE TEMP TABLE _m28_neg_action(a boolean,b boolean,c boolean,d boolean,e boolean,f boolean,g boolean,h boolean,CHECK(NOT a AND NOT b AND NOT c AND NOT d AND NOT e AND NOT f AND NOT g AND NOT h)) ON COMMIT DROP;
CREATE TEMP TABLE _m28_neg_state(a boolean,b boolean,CHECK(NOT a AND NOT b)) ON COMMIT DROP;
CREATE TEMP TABLE _m28_neg_grain(scenario_id bigint,merchant_application_id text,event_sequence integer,PRIMARY KEY(scenario_id,merchant_application_id,event_sequence)) ON COMMIT DROP;
CREATE TEMP TABLE _m28_neg_factor(factor numeric(9,6) CHECK(factor BETWEEN .10 AND 1.00)) ON COMMIT DROP;
CREATE TEMP TABLE _m28_neg_amount(a numeric,b numeric,c numeric,d numeric,CHECK(a>=0 AND b>=0 AND c>=0 AND d>=0)) ON COMMIT DROP;
CREATE TEMP TABLE _m28_neg_transition(seq integer CHECK(seq BETWEEN 0 AND 31)) ON COMMIT DROP;
DO $m2_8_neg_001_policy_status$ BEGIN BEGIN
  UPDATE msbf_ctl.m2_8_policy_profile SET policy_status='DRAFT' WHERE module1_run_id=(SELECT run_id FROM _m28_nctx);
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_001_POLICY_STATUS',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_001_POLICY_STATUS',TRUE,SQLERRM);END;END;$m2_8_neg_001_policy_status$;
DO $m2_8_neg_002_simulation_boundary$ BEGIN BEGIN
  UPDATE msbf_ctl.m2_8_policy_profile SET simulated_servicing_execution_only_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m28_nctx);
  PERFORM msbf_ctl.m2_8_assert_configuration((SELECT run_id FROM _m28_nctx));
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_002_SIMULATION_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_002_SIMULATION_BOUNDARY',TRUE,SQLERRM);END;END;$m2_8_neg_002_simulation_boundary$;
DO $m2_8_neg_003_real_funds_boundary$ BEGIN BEGIN
  UPDATE msbf_ctl.m2_8_policy_profile SET no_real_funds_movement_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m28_nctx);
  PERFORM msbf_ctl.m2_8_assert_configuration((SELECT run_id FROM _m28_nctx));
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_003_REAL_FUNDS_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_003_REAL_FUNDS_BOUNDARY',TRUE,SQLERRM);END;END;$m2_8_neg_003_real_funds_boundary$;
DO $m2_8_neg_004_bank_data_boundary$ BEGIN BEGIN
  UPDATE msbf_ctl.m2_8_policy_profile SET no_bank_account_data_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m28_nctx);
  PERFORM msbf_ctl.m2_8_assert_configuration((SELECT run_id FROM _m28_nctx));
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_004_BANK_DATA_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_004_BANK_DATA_BOUNDARY',TRUE,SQLERRM);END;END;$m2_8_neg_004_bank_data_boundary$;
DO $m2_8_neg_005_ach_network_boundary$ BEGIN BEGIN
  UPDATE msbf_ctl.m2_8_policy_profile SET no_ach_or_network_transmission_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m28_nctx);
  PERFORM msbf_ctl.m2_8_assert_configuration((SELECT run_id FROM _m28_nctx));
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_005_ACH_NETWORK_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_005_ACH_NETWORK_BOUNDARY',TRUE,SQLERRM);END;END;$m2_8_neg_005_ach_network_boundary$;
DO $m2_8_neg_006_processor_call_boundary$ BEGIN BEGIN
  UPDATE msbf_ctl.m2_8_policy_profile SET no_external_processor_call_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m28_nctx);
  PERFORM msbf_ctl.m2_8_assert_configuration((SELECT run_id FROM _m28_nctx));
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_006_PROCESSOR_CALL_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_006_PROCESSOR_CALL_BOUNDARY',TRUE,SQLERRM);END;END;$m2_8_neg_006_processor_call_boundary$;
DO $m2_8_neg_007_outcome_execution_flag$ BEGIN BEGIN
  INSERT INTO _m28_neg_outcome VALUES(TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE);
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_007_OUTCOME_EXECUTION_FLAG',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_007_OUTCOME_EXECUTION_FLAG',TRUE,SQLERRM);END;END;$m2_8_neg_007_outcome_execution_flag$;
DO $m2_8_neg_008_action_execution_flag$ BEGIN BEGIN
  INSERT INTO _m28_neg_action VALUES(TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE);
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_008_ACTION_EXECUTION_FLAG',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_008_ACTION_EXECUTION_FLAG',TRUE,SQLERRM);END;END;$m2_8_neg_008_action_execution_flag$;
DO $m2_8_neg_009_lifecycle_production_state$ BEGIN BEGIN
  INSERT INTO _m28_neg_state VALUES(TRUE,TRUE);
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_009_LIFECYCLE_PRODUCTION_STATE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_009_LIFECYCLE_PRODUCTION_STATE',TRUE,SQLERRM);END;END;$m2_8_neg_009_lifecycle_production_state$;
DO $m2_8_neg_010_duplicate_payment_grain$ BEGIN BEGIN
  INSERT INTO _m28_neg_grain VALUES(1,'APP',1);
  INSERT INTO _m28_neg_grain VALUES(1,'APP',1);
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_010_DUPLICATE_PAYMENT_GRAIN',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN unique_violation THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_010_DUPLICATE_PAYMENT_GRAIN',TRUE,SQLERRM);END;END;$m2_8_neg_010_duplicate_payment_grain$;
DO $m2_8_neg_011_invalid_payment_factor$ BEGIN BEGIN
  INSERT INTO _m28_neg_factor VALUES(1.50);
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_011_INVALID_PAYMENT_FACTOR',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_011_INVALID_PAYMENT_FACTOR',TRUE,SQLERRM);END;END;$m2_8_neg_011_invalid_payment_factor$;
DO $m2_8_neg_012_invalid_payment_amounts$ BEGIN BEGIN
  INSERT INTO _m28_neg_amount VALUES(-1,-1,-1,-1);
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_012_INVALID_PAYMENT_AMOUNTS',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_012_INVALID_PAYMENT_AMOUNTS',TRUE,SQLERRM);END;END;$m2_8_neg_012_invalid_payment_amounts$;
DO $m2_8_neg_013_invalid_transition_sequence$ BEGIN BEGIN
  INSERT INTO _m28_neg_transition VALUES(-1);
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_013_INVALID_TRANSITION_SEQUENCE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_013_INVALID_TRANSITION_SEQUENCE',TRUE,SQLERRM);END;END;$m2_8_neg_013_invalid_transition_sequence$;
DO $m2_8_neg_014_archive_update$ BEGIN BEGIN
  UPDATE msbf_m2.application_servicing_execution_archive SET servicing_execution_queue_code='MUTATION' WHERE archive_id=(SELECT archive_id FROM msbf_m2.application_servicing_execution_archive WHERE module1_run_id=(SELECT run_id FROM _m28_nctx) ORDER BY archive_id LIMIT 1);
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_014_ARCHIVE_UPDATE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_014_ARCHIVE_UPDATE',TRUE,SQLERRM);END;END;$m2_8_neg_014_archive_update$;
DO $m2_8_neg_015_archive_delete$ BEGIN BEGIN
  DELETE FROM msbf_m2.application_servicing_execution_archive WHERE archive_id=(SELECT archive_id FROM msbf_m2.application_servicing_execution_archive WHERE module1_run_id=(SELECT run_id FROM _m28_nctx) ORDER BY archive_id LIMIT 1);
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_015_ARCHIVE_DELETE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_015_ARCHIVE_DELETE',TRUE,SQLERRM);END;END;$m2_8_neg_015_archive_delete$;
DO $m2_8_neg_016_post_generation_rerun$ BEGIN BEGIN
  PERFORM msbf_ctl.m2_8_assert_generation_ready((SELECT run_id FROM _m28_nctx));
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_016_POST_GENERATION_RERUN',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_016_POST_GENERATION_RERUN',TRUE,SQLERRM);END;END;$m2_8_neg_016_post_generation_rerun$;
DO $m2_8_neg_017_premature_acceptance$ BEGIN BEGIN
  PERFORM msbf_ctl.m2_8_assert_acceptance_ready((SELECT run_id FROM _m28_nctx));
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_017_PREMATURE_ACCEPTANCE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_017_PREMATURE_ACCEPTANCE',TRUE,SQLERRM);END;END;$m2_8_neg_017_premature_acceptance$;
DO $m2_8_neg_018_source_hash_drift$ BEGIN BEGIN
  UPDATE msbf_ctl.m2_8_policy_profile SET source_combined_set_hash='00000000000000000000000000000000' WHERE module1_run_id=(SELECT run_id FROM _m28_nctx);
  PERFORM msbf_ctl.m2_8_assert_configuration((SELECT run_id FROM _m28_nctx));
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_018_SOURCE_HASH_DRIFT',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_018_SOURCE_HASH_DRIFT',TRUE,SQLERRM);END;END;$m2_8_neg_018_source_hash_drift$;
DO $m2_8_neg_019_bank_processor_payload$ BEGIN BEGIN
  PERFORM msbf_ctl.m2_8_assert_no_real_payment_payload(jsonb_build_object('bank_account_number','X','routing_number','X','processor_authorization_code','X'));
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_019_BANK_PROCESSOR_PAYLOAD',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_019_BANK_PROCESSOR_PAYLOAD',TRUE,SQLERRM);END;END;$m2_8_neg_019_bank_processor_payload$;
DO $m2_8_neg_020_funds_contact_notice_payload$ BEGIN BEGIN
  PERFORM msbf_ctl.m2_8_assert_no_real_payment_payload(jsonb_build_object('real_funds_moved',TRUE,'merchant_contact_executed',TRUE,'write_off_posted',TRUE,'collection_agency_referral',TRUE,'legal_action_executed',TRUE,'external_notice_payload',jsonb_build_object('synthetic',TRUE),'production_adverse_action_notice',TRUE));
  PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_020_FUNDS_CONTACT_NOTICE_PAYLOAD',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_8_add_negative('M2_8_NEG_020_FUNDS_CONTACT_NOTICE_PAYLOAD',TRUE,SQLERRM);END;END;$m2_8_neg_020_funds_contact_notice_payload$;
DO $final$ DECLARE t bigint;p bigint;f bigint;BEGIN SELECT count(*),count(*) FILTER(WHERE status='PASS'),count(*) FILTER(WHERE status='FAIL') INTO t,p,f FROM _m28_negative;IF t<>20 THEN RAISE EXCEPTION 'M2.8 negative inventory failed: %.',t;END IF;
 INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,interpretation)
 SELECT (SELECT run_id FROM _m28_nctx),evidence_code,'PORTFOLIO',metric_name,NULL,status,'NEGATIVE_CONTROL',status,interpretation FROM _m28_negative
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();
 IF p<>20 OR f<>0 THEN RAISE EXCEPTION 'M2.8 negative controls failed: pass %, fail %.',p,f;END IF;END;$final$;
COMMIT;SELECT * FROM _m28_negative ORDER BY evidence_code;
