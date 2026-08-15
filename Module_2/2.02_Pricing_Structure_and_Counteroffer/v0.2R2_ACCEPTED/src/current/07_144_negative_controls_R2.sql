/* M2.2 Program 144 v0.2R2 — Negative Controls. 20 isolated fail-closed mutations. */
BEGIN; SET LOCAL statement_timeout='30min'; SET LOCAL jit=off;
DROP TABLE IF EXISTS _m2_2_negative; CREATE TEMP TABLE _m2_2_negative(evidence_code text PRIMARY KEY,metric_name text,status text,interpretation text) ON COMMIT PRESERVE ROWS;
DROP TABLE IF EXISTS _m2_2_nctx; CREATE TEMP TABLE _m2_2_nctx ON COMMIT DROP AS SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
DO $$ DECLARE v_pos bigint; BEGIN SELECT count(*) INTO v_pos FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_2_nctx) AND evidence_code LIKE 'M2_2_POS_%' AND status='PASS'; IF (SELECT run_status FROM _m2_2_nctx)<>'M2_2_VALIDATED' OR v_pos<>120 THEN RAISE EXCEPTION 'M2.2 negative controls require validated state and 120 positive passes.'; END IF; END $$;
CREATE OR REPLACE FUNCTION pg_temp.m2_2_add_negative(p_code text,p_pass boolean,p_note text) RETURNS void LANGUAGE plpgsql AS $function$ BEGIN INSERT INTO _m2_2_negative VALUES(p_code,p_code,CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,p_note); END; $function$;
CREATE TEMP TABLE _neg_template(code text PRIMARY KEY,mult numeric CHECK(mult>0)) ON COMMIT DROP; CREATE TEMP TABLE _neg_candidate(scenario_id bigint,app text,template text,requested numeric,candidate numeric,rate numeric,payback numeric,horizon integer,PRIMARY KEY(scenario_id,app,template),CHECK(candidate>=0 AND candidate<=requested),CHECK(rate BETWEEN 0.05 AND 0.20),CHECK(payback BETWEEN 1.05 AND 1.40),CHECK(horizon BETWEEN 1 AND 120)) ON COMMIT DROP;
DO $$ BEGIN BEGIN
    UPDATE msbf_ctl.m2_2_policy_profile SET policy_status='DRAFT' WHERE policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1';
    PERFORM msbf_ctl.m2_2_assert_configuration((SELECT run_id FROM _m2_2_nctx));
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_001_POLICY_STATUS',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_001_POLICY_STATUS',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    UPDATE msbf_ctl.m2_2_policy_profile SET no_final_credit_decision_flag=FALSE WHERE policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1';
    PERFORM msbf_ctl.m2_2_assert_configuration((SELECT run_id FROM _m2_2_nctx));
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_002_FINAL_DECISION_BOUNDARY',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_002_FINAL_DECISION_BOUNDARY',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    UPDATE msbf_ctl.m2_2_policy_profile SET acquisition_source_noncredit_flag=FALSE WHERE policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1';
    PERFORM msbf_ctl.m2_2_assert_configuration((SELECT run_id FROM _m2_2_nctx));
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_003_ACQUISITION_NONCREDIT_BOUNDARY',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_003_ACQUISITION_NONCREDIT_BOUNDARY',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    INSERT INTO _neg_template VALUES('DUP',1); INSERT INTO _neg_template VALUES('DUP',1);
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_004_DUPLICATE_TEMPLATE',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN unique_violation THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_004_DUPLICATE_TEMPLATE',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    INSERT INTO _neg_template VALUES('BAD',0);
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_005_TEMPLATE_MULTIPLIER',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_005_TEMPLATE_MULTIPLIER',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    INSERT INTO _neg_candidate VALUES(1,'A','T',1000,1200,0.10,1.20,60);
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_006_CANDIDATE_AMOUNT',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_006_CANDIDATE_AMOUNT',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    INSERT INTO _neg_candidate VALUES(1,'B','T',1000,900,0.30,1.20,60);
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_007_CANDIDATE_RATE',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_007_CANDIDATE_RATE',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    INSERT INTO _neg_candidate VALUES(1,'C','T',1000,900,0.10,1.80,60);
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_008_CANDIDATE_PAYBACK',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_008_CANDIDATE_PAYBACK',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    INSERT INTO _neg_candidate VALUES(1,'D','T',1000,900,0.10,1.20,150);
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_009_CANDIDATE_HORIZON',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_009_CANDIDATE_HORIZON',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    INSERT INTO _neg_candidate VALUES(1,'E','T',1000,900,0.10,1.20,60); INSERT INTO _neg_candidate VALUES(1,'E','T',1000,900,0.10,1.20,60);
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_010_DUPLICATE_CANDIDATE',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN unique_violation THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_010_DUPLICATE_CANDIDATE',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    UPDATE msbf_m2.application_request_structure_archive SET contract_row_hash='00000000000000000000000000000000' WHERE archive_id=(SELECT min(archive_id) FROM msbf_m2.application_request_structure_archive WHERE module1_run_id=(SELECT run_id FROM _m2_2_nctx));
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_011_REQUEST_ARCHIVE_UPDATE',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_011_REQUEST_ARCHIVE_UPDATE',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    DELETE FROM msbf_m2.application_request_structure_archive WHERE archive_id=(SELECT min(archive_id) FROM msbf_m2.application_request_structure_archive WHERE module1_run_id=(SELECT run_id FROM _m2_2_nctx));
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_012_REQUEST_ARCHIVE_DELETE',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_012_REQUEST_ARCHIVE_DELETE',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    UPDATE msbf_m2.application_pricing_structure_archive SET contract_row_hash='00000000000000000000000000000000' WHERE archive_id=(SELECT min(archive_id) FROM msbf_m2.application_pricing_structure_archive WHERE module1_run_id=(SELECT run_id FROM _m2_2_nctx));
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_013_PRICING_ARCHIVE_UPDATE',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_013_PRICING_ARCHIVE_UPDATE',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    DELETE FROM msbf_m2.application_pricing_structure_archive WHERE archive_id=(SELECT min(archive_id) FROM msbf_m2.application_pricing_structure_archive WHERE module1_run_id=(SELECT run_id FROM _m2_2_nctx));
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_014_PRICING_ARCHIVE_DELETE',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_014_PRICING_ARCHIVE_DELETE',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    PERFORM msbf_ctl.m2_2_assert_generation_ready((SELECT run_id FROM _m2_2_nctx));
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_015_POST_GENERATION_RERUN',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_015_POST_GENERATION_RERUN',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    PERFORM msbf_ctl.m2_2_assert_acceptance_ready((SELECT run_id FROM _m2_2_nctx));
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_016_PREMATURE_ACCEPTANCE',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_016_PREMATURE_ACCEPTANCE',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    UPDATE msbf_ctl.m2_2_policy_profile SET required_source_m2_1_hash='00000000000000000000000000000000' WHERE policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1'; PERFORM msbf_ctl.m2_2_assert_configuration((SELECT run_id FROM _m2_2_nctx));
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_017_SOURCE_HASH_DRIFT',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_017_SOURCE_HASH_DRIFT',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    PERFORM msbf_ctl.m2_2_assert_no_final_decision_payload('{"final_decision":"APPROVE"}'::jsonb);
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_018_FINAL_DECISION_PAYLOAD',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_018_FINAL_DECISION_PAYLOAD',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    PERFORM msbf_ctl.m2_2_assert_no_final_decision_payload('{"adverse_action":true}'::jsonb);
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_019_ADVERSE_ACTION_PAYLOAD',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_019_ADVERSE_ACTION_PAYLOAD',TRUE,SQLERRM); END; END $$;
DO $$ BEGIN BEGIN
    UPDATE msbf_m2.application_pricing_structure_latest s SET selected_funding_amount=b.selected_funding_amount+1000 FROM msbf_m2.application_pricing_structure_latest b WHERE s.module1_run_id=(SELECT run_id FROM _m2_2_nctx) AND b.module1_run_id=s.module1_run_id AND b.merchant_application_id=s.merchant_application_id AND b.scenario_code='BASELINE' AND s.scenario_code='RECESSION_ENERGY' AND s.structure_available_flag AND b.structure_available_flag; PERFORM msbf_ctl.m2_2_assert_stress_nonimprovement((SELECT run_id FROM _m2_2_nctx));
    PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_020_STRESS_IMPROVEMENT',FALSE,'Expected rejection did not occur.'); EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_2_add_negative('M2_2_NEG_020_STRESS_IMPROVEMENT',TRUE,SQLERRM); END; END $$;
DO $$ DECLARE v_total bigint; v_pass bigint; v_fail bigint; BEGIN SELECT count(*),count(*) FILTER(WHERE status='PASS'),count(*) FILTER(WHERE status='FAIL') INTO v_total,v_pass,v_fail FROM _m2_2_negative; IF v_total<>20 OR v_pass<>20 OR v_fail<>0 THEN RAISE EXCEPTION 'M2.2 negative controls expected 20 of 20 PASS; observed % of %.',v_pass,v_total; END IF; DELETE FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_2_nctx) AND evidence_code LIKE 'M2_2_NEG_%'; INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation) SELECT (SELECT run_id FROM _m2_2_nctx),evidence_code,'PORTFOLIO',metric_name,status,'NEGATIVE_CONTROL',status,interpretation FROM _m2_2_negative; END $$;
COMMIT; SELECT evidence_code,metric_name,status,interpretation FROM _m2_2_negative ORDER BY evidence_code;
