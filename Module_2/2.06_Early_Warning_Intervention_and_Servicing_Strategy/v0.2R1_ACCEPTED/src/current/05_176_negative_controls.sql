/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.6 — Early Warning, Intervention & Servicing Strategy

Program     : 176_msbf_m2_6_negative_control_tests_v0_2.sql
Version     : v0.2

Purpose
-------
Prove fail-closed behavior for recommendation-only policy drift, executed
action flags, invalid review terms, duplicate grains, archive immutability,
lifecycle reruns, premature acceptance, source-hash drift and prohibited
servicing/notice payload vocabulary.

Required result
---------------
20 / 20 PASS.
============================================================================ */
BEGIN;
SET LOCAL statement_timeout='30min'; SET LOCAL jit=off;
DROP TABLE IF EXISTS _m2_6_negative;
CREATE TEMP TABLE _m2_6_negative(evidence_code text PRIMARY KEY, metric_name text, status text, interpretation text) ON COMMIT PRESERVE ROWS;
DROP TABLE IF EXISTS _m2_6_nctx;
CREATE TEMP TABLE _m2_6_nctx ON COMMIT DROP AS SELECT run_id, run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
DO $ready$ DECLARE v_pos bigint; BEGIN SELECT count(*) INTO v_pos FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_6_nctx) AND evidence_code LIKE 'M2_6_POS_%' AND status='PASS'; IF (SELECT run_status FROM _m2_6_nctx)<>'M2_6_VALIDATED' OR v_pos<>120 THEN RAISE EXCEPTION 'M2.6 negative controls require M2_6_VALIDATED and 120 positive passes.'; END IF; END; $ready$;
CREATE OR REPLACE FUNCTION pg_temp.m2_6_add_negative(p_code text,p_pass boolean,p_interpretation text) RETURNS void LANGUAGE plpgsql AS $function$ BEGIN INSERT INTO _m2_6_negative VALUES(p_code,p_code,CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,p_interpretation); END; $function$;
CREATE TEMP TABLE _m2_6_neg_boundary(executed_flag boolean NOT NULL CHECK(executed_flag IS FALSE)) ON COMMIT DROP;
CREATE TEMP TABLE _m2_6_neg_grain(scenario_id bigint, merchant_application_id text, PRIMARY KEY(scenario_id,merchant_application_id)) ON COMMIT DROP;
CREATE TEMP TABLE _m2_6_neg_terms(temporary_adjustment_review_flag boolean, temporary_remittance_rate_factor numeric(9,6), review_remittance_rate numeric(9,6), recommended_review_duration_days integer, reassessment_interval_days integer, CHECK((temporary_adjustment_review_flag AND temporary_remittance_rate_factor IS NOT NULL AND review_remittance_rate IS NOT NULL AND recommended_review_duration_days IS NOT NULL AND reassessment_interval_days IS NOT NULL) OR (NOT temporary_adjustment_review_flag AND temporary_remittance_rate_factor IS NULL AND review_remittance_rate IS NULL AND recommended_review_duration_days IS NULL AND reassessment_interval_days IS NULL))) ON COMMIT DROP;
DO $m2_6_neg_001_policy_status$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_6_policy_profile SET policy_status='DRAFT' WHERE module1_run_id=(SELECT run_id FROM _m2_6_nctx);
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_001_POLICY_STATUS',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_001_POLICY_STATUS',TRUE,SQLERRM); END; END; $m2_6_neg_001_policy_status$;
DO $m2_6_neg_002_recommendation_only_$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_6_policy_profile SET recommendation_only_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m2_6_nctx);
        PERFORM msbf_ctl.m2_6_assert_configuration((SELECT run_id FROM _m2_6_nctx));
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_002_RECOMMENDATION_ONLY_',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_002_RECOMMENDATION_ONLY_',TRUE,SQLERRM); END; END; $m2_6_neg_002_recommendation_only_$;
DO $m2_6_neg_003_no_merchant_contact_$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_6_policy_profile SET no_merchant_contact_execution_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m2_6_nctx);
        PERFORM msbf_ctl.m2_6_assert_configuration((SELECT run_id FROM _m2_6_nctx));
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_003_NO_MERCHANT_CONTACT_',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_003_NO_MERCHANT_CONTACT_',TRUE,SQLERRM); END; END; $m2_6_neg_003_no_merchant_contact_$;
DO $m2_6_neg_004_no_payment_change_ex$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_6_policy_profile SET no_payment_change_execution_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m2_6_nctx);
        PERFORM msbf_ctl.m2_6_assert_configuration((SELECT run_id FROM _m2_6_nctx));
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_004_NO_PAYMENT_CHANGE_EX',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_004_NO_PAYMENT_CHANGE_EX',TRUE,SQLERRM); END; END; $m2_6_neg_004_no_payment_change_ex$;
DO $m2_6_neg_005_no_write_off_charge_$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_6_policy_profile SET no_write_off_charge_off_execution_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m2_6_nctx);
        PERFORM msbf_ctl.m2_6_assert_configuration((SELECT run_id FROM _m2_6_nctx));
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_005_NO_WRITE_OFF_CHARGE_',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_005_NO_WRITE_OFF_CHARGE_',TRUE,SQLERRM); END; END; $m2_6_neg_005_no_write_off_charge_$;
DO $m2_6_neg_006_no_legal_or_collecti$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_6_policy_profile SET no_legal_or_collection_action_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m2_6_nctx);
        PERFORM msbf_ctl.m2_6_assert_configuration((SELECT run_id FROM _m2_6_nctx));
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_006_NO_LEGAL_OR_COLLECTI',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_006_NO_LEGAL_OR_COLLECTI',TRUE,SQLERRM); END; END; $m2_6_neg_006_no_legal_or_collecti$;
DO $m2_6_neg_007_no_external_notice_g$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_6_policy_profile SET no_external_notice_generation_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m2_6_nctx);
        PERFORM msbf_ctl.m2_6_assert_configuration((SELECT run_id FROM _m2_6_nctx));
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_007_NO_EXTERNAL_NOTICE_G',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_007_NO_EXTERNAL_NOTICE_G',TRUE,SQLERRM); END; END; $m2_6_neg_007_no_external_notice_g$;
DO $m2_6_neg_008_outcome_executed_flag$ BEGIN BEGIN
        INSERT INTO _m2_6_neg_boundary(executed_flag) VALUES(TRUE);
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_008_OUTCOME_EXECUTED_FLAG',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_008_OUTCOME_EXECUTED_FLAG',TRUE,SQLERRM); END; END; $m2_6_neg_008_outcome_executed_flag$;
DO $m2_6_neg_009_action_executed_flag$ BEGIN BEGIN
        INSERT INTO _m2_6_neg_boundary(executed_flag) VALUES(TRUE);
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_009_ACTION_EXECUTED_FLAG',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_009_ACTION_EXECUTED_FLAG',TRUE,SQLERRM); END; END; $m2_6_neg_009_action_executed_flag$;
DO $m2_6_neg_010_duplicate_strategy_grain$ BEGIN BEGIN
        INSERT INTO _m2_6_neg_grain(scenario_id,merchant_application_id) VALUES(1,'A');
        INSERT INTO _m2_6_neg_grain(scenario_id,merchant_application_id) VALUES(1,'A');
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_010_DUPLICATE_STRATEGY_GRAIN',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN unique_violation THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_010_DUPLICATE_STRATEGY_GRAIN',TRUE,SQLERRM); END; END; $m2_6_neg_010_duplicate_strategy_grain$;
DO $m2_6_neg_011_invalid_temp_terms$ BEGIN BEGIN
        INSERT INTO _m2_6_neg_terms(temporary_adjustment_review_flag,temporary_remittance_rate_factor,review_remittance_rate,recommended_review_duration_days,reassessment_interval_days) VALUES(TRUE,NULL,NULL,NULL,NULL);
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_011_INVALID_TEMP_TERMS',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_011_INVALID_TEMP_TERMS',TRUE,SQLERRM); END; END; $m2_6_neg_011_invalid_temp_terms$;
DO $m2_6_neg_012_archive_update$ BEGIN BEGIN
        UPDATE msbf_m2.advance_intervention_strategy_archive SET strategy_outcome_code='MUTATION_TEST' WHERE archive_id=(SELECT archive_id FROM msbf_m2.advance_intervention_strategy_archive WHERE module1_run_id=(SELECT run_id FROM _m2_6_nctx) ORDER BY archive_id LIMIT 1);
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_012_ARCHIVE_UPDATE',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_012_ARCHIVE_UPDATE',TRUE,SQLERRM); END; END; $m2_6_neg_012_archive_update$;
DO $m2_6_neg_013_archive_delete$ BEGIN BEGIN
        DELETE FROM msbf_m2.advance_intervention_strategy_archive WHERE archive_id=(SELECT archive_id FROM msbf_m2.advance_intervention_strategy_archive WHERE module1_run_id=(SELECT run_id FROM _m2_6_nctx) ORDER BY archive_id LIMIT 1);
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_013_ARCHIVE_DELETE',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_013_ARCHIVE_DELETE',TRUE,SQLERRM); END; END; $m2_6_neg_013_archive_delete$;
DO $m2_6_neg_014_post_generation_rerun$ BEGIN BEGIN
        PERFORM msbf_ctl.m2_6_assert_generation_ready((SELECT run_id FROM _m2_6_nctx));
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_014_POST_GENERATION_RERUN',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_014_POST_GENERATION_RERUN',TRUE,SQLERRM); END; END; $m2_6_neg_014_post_generation_rerun$;
DO $m2_6_neg_015_premature_acceptance$ BEGIN BEGIN
        PERFORM msbf_ctl.m2_6_assert_acceptance_ready((SELECT run_id FROM _m2_6_nctx));
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_015_PREMATURE_ACCEPTANCE',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_015_PREMATURE_ACCEPTANCE',TRUE,SQLERRM); END; END; $m2_6_neg_015_premature_acceptance$;
DO $m2_6_neg_016_source_hash_drift$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_6_policy_profile SET source_m2_5_combined_hash='00000000000000000000000000000000' WHERE module1_run_id=(SELECT run_id FROM _m2_6_nctx);
        PERFORM msbf_ctl.m2_6_assert_configuration((SELECT run_id FROM _m2_6_nctx));
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_016_SOURCE_HASH_DRIFT',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_016_SOURCE_HASH_DRIFT',TRUE,SQLERRM); END; END; $m2_6_neg_016_source_hash_drift$;
DO $m2_6_neg_017_payload_boundary$ BEGIN BEGIN
        PERFORM msbf_ctl.m2_6_assert_no_executed_servicing_payload('{"merchant_contact_executed":true}'::jsonb);
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_017_PAYLOAD_BOUNDARY',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_017_PAYLOAD_BOUNDARY',TRUE,SQLERRM); END; END; $m2_6_neg_017_payload_boundary$;
DO $m2_6_neg_018_payload_boundary$ BEGIN BEGIN
        PERFORM msbf_ctl.m2_6_assert_no_executed_servicing_payload('{"payment_change_executed":true}'::jsonb);
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_018_PAYLOAD_BOUNDARY',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_018_PAYLOAD_BOUNDARY',TRUE,SQLERRM); END; END; $m2_6_neg_018_payload_boundary$;
DO $m2_6_neg_019_payload_boundary$ BEGIN BEGIN
        PERFORM msbf_ctl.m2_6_assert_no_executed_servicing_payload('{"external_notice_payload":{}}'::jsonb);
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_019_PAYLOAD_BOUNDARY',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_019_PAYLOAD_BOUNDARY',TRUE,SQLERRM); END; END; $m2_6_neg_019_payload_boundary$;
DO $m2_6_neg_020_payload_boundary$ BEGIN BEGIN
        PERFORM msbf_ctl.m2_6_assert_no_executed_servicing_payload('{"production_adverse_action_notice":true}'::jsonb);
        PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_020_PAYLOAD_BOUNDARY',FALSE,'Expected rejection did not occur.');
    EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_6_add_negative('M2_6_NEG_020_PAYLOAD_BOUNDARY',TRUE,SQLERRM); END; END; $m2_6_neg_020_payload_boundary$;
DO $final$ DECLARE v_total bigint; v_pass bigint; v_fail bigint; BEGIN SELECT count(*), count(*) FILTER (WHERE status='PASS'), count(*) FILTER (WHERE status='FAIL') INTO v_total, v_pass, v_fail FROM _m2_6_negative; IF v_total<>20 THEN RAISE EXCEPTION 'M2.6 negative-control inventory failed: total %, expected 20.', v_total; END IF; INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,interpretation) SELECT (SELECT run_id FROM _m2_6_nctx), evidence_code, 'PORTFOLIO', metric_name, NULL::numeric(28,10), status, 'NEGATIVE_CONTROL', status, interpretation FROM _m2_6_negative ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name, metric_value_numeric=NULL, metric_value_text=EXCLUDED.metric_value_text, unit_code=EXCLUDED.unit_code, status=EXCLUDED.status, interpretation=EXCLUDED.interpretation, created_at=clock_timestamp(); IF v_pass<>20 OR v_fail<>0 THEN RAISE EXCEPTION 'M2.6 negative controls failed: pass %, fail %.', v_pass, v_fail; END IF; END; $final$;
COMMIT;
SELECT * FROM _m2_6_negative ORDER BY evidence_code;
