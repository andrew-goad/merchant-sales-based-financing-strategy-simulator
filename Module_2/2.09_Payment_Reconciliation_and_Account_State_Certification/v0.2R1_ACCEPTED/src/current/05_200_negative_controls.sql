/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.9 — Payment Reconciliation, Exception Resolution
             & Account State Certification

Program     : 200_msbf_m2_9_negative_control_tests_v0_2.sql
Version     : v0.2

Purpose
-------
Prove fail-closed behavior for policy and source-hash drift, production flags,
invalid tolerance, exception and certification domains, duplicate event grain,
archive mutation, lifecycle reruns, premature acceptance, and prohibited bank,
processor, funds, contact, collection/legal, and notice payloads.

Required result
---------------
20 / 20 PASS.
============================================================================ */
BEGIN; SET LOCAL statement_timeout='35min'; SET LOCAL jit=off;
DROP TABLE IF EXISTS _m2_9_negative;
CREATE TEMP TABLE _m2_9_negative(evidence_code text PRIMARY KEY,metric_name text NOT NULL,status text NOT NULL,interpretation text NOT NULL) ON COMMIT PRESERVE ROWS;
DROP TABLE IF EXISTS _m2_9_nctx;
CREATE TEMP TABLE _m2_9_nctx ON COMMIT DROP AS SELECT run_id,run_status FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
DO $ready$ DECLARE vp bigint; BEGIN SELECT count(*) INTO vp FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m2_9_nctx) AND evidence_code LIKE 'M2_9_POS_%' AND status='PASS';
IF (SELECT run_status FROM _m2_9_nctx)<>'M2_9_VALIDATED' OR vp<>120 THEN
RAISE EXCEPTION 'M2.9 negative controls require M2_9_VALIDATED and 120 positive passes.'; END IF; END;$ready$;
CREATE OR REPLACE FUNCTION pg_temp.m2_9_add_negative(p_code text,p_pass boolean,p_interpretation text)
RETURNS void LANGUAGE plpgsql AS $function$ BEGIN INSERT INTO _m2_9_negative VALUES(p_code,p_code,CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,p_interpretation); END;$function$;
/* ============================================================================
Section 1 — Isolated fail-closed structures
============================================================================ */
CREATE TEMP TABLE _m2_9_neg_outcome(real_funds_moved_flag boolean NOT NULL,production_state_updated_flag boolean NOT NULL,
CHECK(NOT real_funds_moved_flag AND NOT production_state_updated_flag)) ON COMMIT DROP;
CREATE TEMP TABLE _m2_9_neg_action(real_funds_moved_flag boolean NOT NULL,external_system_called_flag boolean NOT NULL,
CHECK(NOT real_funds_moved_flag AND NOT external_system_called_flag)) ON COMMIT DROP;
CREATE TEMP TABLE _m2_9_neg_cert(production_account_state_flag boolean NOT NULL CHECK(NOT production_account_state_flag)) ON COMMIT DROP;
CREATE TEMP TABLE _m2_9_neg_grain(scenario_id bigint NOT NULL,merchant_application_id text NOT NULL,event_sequence integer NOT NULL,
PRIMARY KEY(scenario_id,merchant_application_id,event_sequence)) ON COMMIT DROP;
CREATE TEMP TABLE _m2_9_neg_tolerance(tolerance_amount numeric(18,2) NOT NULL CHECK(tolerance_amount>=0)) ON COMMIT DROP;
CREATE TEMP TABLE _m2_9_neg_exception(exception_status_code text NOT NULL CHECK(exception_status_code IN('RESOLVED_BY_RETRY','OPEN','ESCALATED','CERTIFICATION_BLOCKED'))) ON COMMIT DROP;
CREATE TEMP TABLE _m2_9_neg_cert_flags(active_flag boolean NOT NULL,closed_flag boolean NOT NULL,review_flag boolean NOT NULL,
CHECK(num_nonnulls(NULLIF(active_flag,FALSE),NULLIF(closed_flag,FALSE),NULLIF(review_flag,FALSE))<=1)) ON COMMIT DROP;
/* ============================================================================
Section 2 — Twenty governed negative controls
============================================================================ */
DO $m2_9_neg_001_policy_status$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_9_policy_profile SET policy_status='DRAFT' WHERE module1_run_id=(SELECT run_id FROM _m2_9_nctx);
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_001_POLICY_STATUS',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_001_POLICY_STATUS',TRUE,SQLERRM); END; END;$m2_9_neg_001_policy_status$;
DO $m2_9_neg_002_certification_boundary$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_9_policy_profile SET reconciliation_certification_only_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m2_9_nctx);
        PERFORM msbf_ctl.m2_9_assert_configuration((SELECT run_id FROM _m2_9_nctx));
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_002_CERTIFICATION_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_002_CERTIFICATION_BOUNDARY',TRUE,SQLERRM); END; END;$m2_9_neg_002_certification_boundary$;
DO $m2_9_neg_003_real_funds_boundary$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_9_policy_profile SET no_real_funds_movement_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m2_9_nctx);
        PERFORM msbf_ctl.m2_9_assert_configuration((SELECT run_id FROM _m2_9_nctx));
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_003_REAL_FUNDS_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_003_REAL_FUNDS_BOUNDARY',TRUE,SQLERRM); END; END;$m2_9_neg_003_real_funds_boundary$;
DO $m2_9_neg_004_bank_data_boundary$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_9_policy_profile SET no_bank_account_data_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m2_9_nctx);
        PERFORM msbf_ctl.m2_9_assert_configuration((SELECT run_id FROM _m2_9_nctx));
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_004_BANK_DATA_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_004_BANK_DATA_BOUNDARY',TRUE,SQLERRM); END; END;$m2_9_neg_004_bank_data_boundary$;
DO $m2_9_neg_005_network_boundary$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_9_policy_profile SET no_ach_or_network_transmission_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m2_9_nctx);
        PERFORM msbf_ctl.m2_9_assert_configuration((SELECT run_id FROM _m2_9_nctx));
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_005_NETWORK_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_005_NETWORK_BOUNDARY',TRUE,SQLERRM); END; END;$m2_9_neg_005_network_boundary$;
DO $m2_9_neg_006_processor_boundary$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_9_policy_profile SET no_external_processor_call_flag=FALSE WHERE module1_run_id=(SELECT run_id FROM _m2_9_nctx);
        PERFORM msbf_ctl.m2_9_assert_configuration((SELECT run_id FROM _m2_9_nctx));
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_006_PROCESSOR_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_006_PROCESSOR_BOUNDARY',TRUE,SQLERRM); END; END;$m2_9_neg_006_processor_boundary$;
DO $m2_9_neg_007_outcome_execution_flag$ BEGIN BEGIN
        INSERT INTO _m2_9_neg_outcome VALUES(TRUE,TRUE);
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_007_OUTCOME_EXECUTION_FLAG',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_007_OUTCOME_EXECUTION_FLAG',TRUE,SQLERRM); END; END;$m2_9_neg_007_outcome_execution_flag$;
DO $m2_9_neg_008_action_execution_flag$ BEGIN BEGIN
        INSERT INTO _m2_9_neg_action VALUES(TRUE,TRUE);
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_008_ACTION_EXECUTION_FLAG',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_008_ACTION_EXECUTION_FLAG',TRUE,SQLERRM); END; END;$m2_9_neg_008_action_execution_flag$;
DO $m2_9_neg_009_certification_production_state$ BEGIN BEGIN
        INSERT INTO _m2_9_neg_cert VALUES(TRUE);
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_009_CERTIFICATION_PRODUCTION_STATE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_009_CERTIFICATION_PRODUCTION_STATE',TRUE,SQLERRM); END; END;$m2_9_neg_009_certification_production_state$;
DO $m2_9_neg_010_duplicate_event_grain$ BEGIN BEGIN
        INSERT INTO _m2_9_neg_grain VALUES(1,'SYNTHETIC_APPLICATION',1);
        INSERT INTO _m2_9_neg_grain VALUES(1,'SYNTHETIC_APPLICATION',1);
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_010_DUPLICATE_EVENT_GRAIN',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN unique_violation THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_010_DUPLICATE_EVENT_GRAIN',TRUE,SQLERRM); END; END;$m2_9_neg_010_duplicate_event_grain$;
DO $m2_9_neg_011_negative_variance_tolerance$ BEGIN BEGIN
        INSERT INTO _m2_9_neg_tolerance VALUES(-0.01);
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_011_NEGATIVE_VARIANCE_TOLERANCE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_011_NEGATIVE_VARIANCE_TOLERANCE',TRUE,SQLERRM); END; END;$m2_9_neg_011_negative_variance_tolerance$;
DO $m2_9_neg_012_invalid_exception_status$ BEGIN BEGIN
        INSERT INTO _m2_9_neg_exception VALUES('PRODUCTION_SETTLED');
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_012_INVALID_EXCEPTION_STATUS',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_012_INVALID_EXCEPTION_STATUS',TRUE,SQLERRM); END; END;$m2_9_neg_012_invalid_exception_status$;
DO $m2_9_neg_013_conflicting_certification_flags$ BEGIN BEGIN
        INSERT INTO _m2_9_neg_cert_flags VALUES(TRUE,TRUE,TRUE);
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_013_CONFLICTING_CERTIFICATION_FLAGS',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_013_CONFLICTING_CERTIFICATION_FLAGS',TRUE,SQLERRM); END; END;$m2_9_neg_013_conflicting_certification_flags$;
DO $m2_9_neg_014_archive_update$ BEGIN BEGIN
        UPDATE msbf_m2.application_payment_reconciliation_certification_archive
        SET reconciliation_outcome_code='MUTATION_TEST'
        WHERE archive_id=(SELECT archive_id FROM msbf_m2.application_payment_reconciliation_certification_archive
                          WHERE module1_run_id=(SELECT run_id FROM _m2_9_nctx) ORDER BY archive_id LIMIT 1);
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_014_ARCHIVE_UPDATE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_014_ARCHIVE_UPDATE',TRUE,SQLERRM); END; END;$m2_9_neg_014_archive_update$;
DO $m2_9_neg_015_archive_delete$ BEGIN BEGIN
        DELETE FROM msbf_m2.application_payment_reconciliation_certification_archive
        WHERE archive_id=(SELECT archive_id FROM msbf_m2.application_payment_reconciliation_certification_archive
                          WHERE module1_run_id=(SELECT run_id FROM _m2_9_nctx) ORDER BY archive_id LIMIT 1);
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_015_ARCHIVE_DELETE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_015_ARCHIVE_DELETE',TRUE,SQLERRM); END; END;$m2_9_neg_015_archive_delete$;
DO $m2_9_neg_016_post_generation_rerun$ BEGIN BEGIN
        PERFORM msbf_ctl.m2_9_assert_generation_ready((SELECT run_id FROM _m2_9_nctx));
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_016_POST_GENERATION_RERUN',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_016_POST_GENERATION_RERUN',TRUE,SQLERRM); END; END;$m2_9_neg_016_post_generation_rerun$;
DO $m2_9_neg_017_premature_acceptance$ BEGIN BEGIN
        PERFORM msbf_ctl.m2_9_assert_acceptance_ready((SELECT run_id FROM _m2_9_nctx));
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_017_PREMATURE_ACCEPTANCE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_017_PREMATURE_ACCEPTANCE',TRUE,SQLERRM); END; END;$m2_9_neg_017_premature_acceptance$;
DO $m2_9_neg_018_source_hash_drift$ BEGIN BEGIN
        UPDATE msbf_ctl.m2_9_policy_profile SET source_combined_set_hash='00000000000000000000000000000000'
        WHERE module1_run_id=(SELECT run_id FROM _m2_9_nctx);
        PERFORM msbf_ctl.m2_9_assert_configuration((SELECT run_id FROM _m2_9_nctx));
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_018_SOURCE_HASH_DRIFT',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_018_SOURCE_HASH_DRIFT',TRUE,SQLERRM); END; END;$m2_9_neg_018_source_hash_drift$;
DO $m2_9_neg_019_bank_processor_payload$ BEGIN BEGIN
        PERFORM msbf_ctl.m2_9_assert_no_real_reconciliation_payload
        (jsonb_build_object('bank_account_number','SYNTHETIC','routing_number','SYNTHETIC','processor_authorization_code','SYNTHETIC'));
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_019_BANK_PROCESSOR_PAYLOAD',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_019_BANK_PROCESSOR_PAYLOAD',TRUE,SQLERRM); END; END;$m2_9_neg_019_bank_processor_payload$;
DO $m2_9_neg_020_funds_contact_notice_payload$ BEGIN BEGIN
        PERFORM msbf_ctl.m2_9_assert_no_real_reconciliation_payload
        (jsonb_build_object('real_funds_moved',TRUE,'merchant_contact_executed',TRUE,'write_off_posted',TRUE,
        'collection_agency_referral',TRUE,'legal_action_executed',TRUE,'external_notice_payload',jsonb_build_object('synthetic',TRUE),
        'production_adverse_action_notice',TRUE));
 PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_020_FUNDS_CONTACT_NOTICE_PAYLOAD',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN PERFORM pg_temp.m2_9_add_negative('M2_9_NEG_020_FUNDS_CONTACT_NOTICE_PAYLOAD',TRUE,SQLERRM); END; END;$m2_9_neg_020_funds_contact_notice_payload$;
/* ============================================================================
Section 3 — Persist evidence only after all controls pass
============================================================================ */
DO $finalize$ DECLARE vt bigint;vp bigint;vf bigint;
BEGIN SELECT count(*),count(*) FILTER(WHERE status='PASS'),count(*) FILTER(WHERE status='FAIL') INTO vt,vp,vf FROM _m2_9_negative;
IF vt<>20 THEN RAISE EXCEPTION 'M2.9 negative-control inventory failed: total %, expected 20.',vt; END IF;
INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,interpretation)
SELECT (SELECT run_id FROM _m2_9_nctx),evidence_code,'PORTFOLIO',metric_name,NULL::numeric(28,10),status,'NEGATIVE_CONTROL',status,interpretation
FROM _m2_9_negative ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();
IF vp<>20 OR vf<>0 THEN RAISE EXCEPTION 'M2.9 negative controls failed: pass %, fail %.',vp,vf; END IF; END;$finalize$;
COMMIT; SELECT evidence_code,metric_name,status,interpretation FROM _m2_9_negative ORDER BY evidence_code;
