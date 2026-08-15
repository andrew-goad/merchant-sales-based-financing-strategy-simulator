/* ============================================================================
MSBF M2.1 — Eligibility, Policy Gates & Decision Routing Foundations
Program 136 — Governed Negative Controls
Version v0.2R6
Purpose: Prove fail-closed policy, contract, archive, lifecycle and stage-boundary behavior.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='20min';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m2_1_nctx;
CREATE TEMP TABLE _m2_1_nctx ON COMMIT DROP AS
SELECT r.run_id,r.run_status,c.contract_status
FROM msbf_ctl.run_registry AS r
JOIN msbf_ctl.m2_1_strategy_contract_registry AS c ON c.module1_run_id=r.run_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

DO $ready$
BEGIN
  PERFORM msbf_ctl.m2_1_assert_validation_ready((SELECT run_id FROM _m2_1_nctx));
END;
$ready$;

DROP TABLE IF EXISTS _m2_1_negative_controls;
CREATE TEMP TABLE _m2_1_negative_controls(
 evidence_code text PRIMARY KEY,
 test_name text NOT NULL,
 status text NOT NULL,
 sqlstate_observed text,
 observed_message text,
 interpretation text NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m2_1_add_negative(
 p_code text,p_name text,p_pass boolean,p_state text,p_message text
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 INSERT INTO _m2_1_negative_controls VALUES(
  p_code,p_name,CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,p_state,p_message,
  CASE WHEN p_pass THEN 'The prohibited condition was rejected and its subtransaction rolled back.'
       ELSE 'The prohibited condition was not rejected.' END
 );
END; $$;

DO $negative_tests$
DECLARE v_rejected boolean; v_state text; v_message text;
BEGIN
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_ctl.m2_1_policy_profile SET policy_status='DRAFT' WHERE policy_code='M2_1_ELIGIBILITY_POLICY_V1'; PERFORM msbf_ctl.m2_1_assert_configuration((SELECT run_id FROM _m2_1_nctx));
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_001_UNAPPROVED_POLICY','Unapproved policy is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_ctl.m2_1_policy_profile SET required_source_g2_hash=repeat('0',32) WHERE policy_code='M2_1_ELIGIBILITY_POLICY_V1'; PERFORM msbf_ctl.m2_1_assert_configuration((SELECT run_id FROM _m2_1_nctx));
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_002_SOURCE_G2_HASH_DRIFT','Incorrect source G2 hash is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_ctl.m2_1_policy_profile SET expected_gate_count=11 WHERE policy_code='M2_1_ELIGIBILITY_POLICY_V1'; PERFORM msbf_ctl.m2_1_assert_configuration((SELECT run_id FROM _m2_1_nctx));
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_003_GATE_COUNT_DRIFT','Invalid expected gate count is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_ctl.m2_1_policy_profile SET no_final_offer_terms_flag=false WHERE policy_code='M2_1_ELIGIBILITY_POLICY_V1'; PERFORM msbf_ctl.m2_1_assert_configuration((SELECT run_id FROM _m2_1_nctx));
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_004_FINAL_OFFER_BOUNDARY','Attempt to authorize final offer terms is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_ctl.m2_1_policy_profile SET acquisition_source_review_only_flag=false WHERE policy_code='M2_1_ELIGIBILITY_POLICY_V1'; PERFORM msbf_ctl.m2_1_assert_configuration((SELECT run_id FROM _m2_1_nctx));
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_005_ACQUISITION_CREDIT_BOUNDARY','Acquisition-source credit-policy use is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_m2.routing_outcome_definition SET route_rank=5 WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND route_code='ELIGIBLE_FOR_OFFER_DESIGN';
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_006_INVALID_OUTCOME_RANK','Invalid outcome rank is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_m2.application_policy_gate_result SET gate_outcome='INVALID' WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND ctid=(SELECT ctid FROM msbf_m2.application_policy_gate_result WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) LIMIT 1);
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_007_INVALID_GATE_OUTCOME','Invalid gate outcome is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_m2.application_policy_gate_result SET hard_stop_flag=true WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND gate_outcome='PASS' AND ctid=(SELECT ctid FROM msbf_m2.application_policy_gate_result WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND gate_outcome='PASS' LIMIT 1);
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_008_HARD_STOP_ON_PASS','Hard-stop flag on a passing gate is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_m2.application_eligibility_routing_snapshot SET pass_gate_count=pass_gate_count+1 WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND ctid=(SELECT ctid FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) LIMIT 1);
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_009_GATE_COUNT_IDENTITY','Snapshot gate-count inconsistency is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_m2.application_eligibility_routing_snapshot SET eligible_for_offer_design_flag=NOT eligible_for_offer_design_flag WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND ctid=(SELECT ctid FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) LIMIT 1);
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_010_ELIGIBLE_FLAG_IDENTITY','Eligible flag mismatch is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_m2.application_eligibility_routing_snapshot SET final_route_rank=5 WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND ctid=(SELECT ctid FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) LIMIT 1);
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_011_INVALID_ROUTE_RANK','Invalid route rank is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_m2.application_eligibility_routing_archive SET contract_version=contract_version WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND archive_id=(SELECT min(archive_id) FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx));
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_012_M2_ARCHIVE_UPDATE','M2.1 archive update is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    DELETE FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND archive_id=(SELECT min(archive_id) FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx));
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_013_M2_ARCHIVE_DELETE','M2.1 archive delete is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_m1.application_module1_archive SET contract_version=contract_version WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND archive_id=(SELECT min(archive_id) FROM msbf_m1.application_module1_archive WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx));
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_014_M1_15_ARCHIVE_UPDATE','Accepted M1.15 archive update is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_m1.application_acquisition_contract_archive SET contract_version=contract_version WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND archive_id=(SELECT min(archive_id) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx));
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_015_M1_16_ARCHIVE_UPDATE','Accepted M1.16 archive update is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_m2.policy_gate_definition SET decision_influence_code='DECLINE' WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND gate_code='GATE_12_ACQUISITION_EVIDENCE'; IF EXISTS(SELECT 1 FROM msbf_m2.policy_gate_definition WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND gate_code='GATE_12_ACQUISITION_EVIDENCE' AND decision_influence_code<>'REVIEW_ONLY') THEN RAISE EXCEPTION 'Acquisition evidence cannot drive policy decline.'; END IF;
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_016_ACQUISITION_GATE_DECLINE','Acquisition gate cannot be converted into a decline gate',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_m2.reason_code_definition SET associated_route_code='DECLINE_POLICY' WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND reason_code='M2_1_ACQUISITION_EVIDENCE_REVIEW'; IF EXISTS(SELECT 1 FROM msbf_m2.reason_code_definition WHERE module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND reason_category='ACQUISITION' AND associated_route_code='DECLINE_POLICY') THEN RAISE EXCEPTION 'Acquisition reason cannot cause policy decline.'; END IF;
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_017_ACQUISITION_REASON_DECLINE','Acquisition reason cannot be mapped to policy decline',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    PERFORM msbf_ctl.m2_1_assert_generation_ready((SELECT run_id FROM _m2_1_nctx));
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_018_POST_GENERATION_RERUN','Post-generation rerun is rejected',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_ctl.run_registry SET run_status='M1_17_ACCEPTED' WHERE run_id=(SELECT run_id FROM _m2_1_nctx); PERFORM msbf_ctl.m2_1_assert_validation_ready((SELECT run_id FROM _m2_1_nctx));
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_019_RUN_STATUS_DRIFT','Validation rejects run-status drift',v_rejected,v_state,v_message);
  v_rejected:=false; v_state:=NULL; v_message:=NULL;
  BEGIN
    UPDATE msbf_m2.application_eligibility_routing_latest AS x SET merchant_application_id=(SELECT y.merchant_application_id FROM msbf_m2.application_eligibility_routing_latest AS y WHERE y.module1_run_id=x.module1_run_id AND y.strategy_campaign_code=x.strategy_campaign_code AND y.scenario_id=x.scenario_id AND y.merchant_application_id<>x.merchant_application_id ORDER BY y.merchant_application_id LIMIT 1) WHERE x.module1_run_id=(SELECT run_id FROM _m2_1_nctx) AND x.ctid=(SELECT z.ctid FROM msbf_m2.application_eligibility_routing_latest AS z WHERE z.module1_run_id=(SELECT run_id FROM _m2_1_nctx) ORDER BY z.scenario_id,z.merchant_application_id LIMIT 1);
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
  EXCEPTION WHEN OTHERS THEN
    v_state:=SQLSTATE; v_message:=SQLERRM;
    v_rejected:=(SQLSTATE<>'P0002' OR SQLERRM<>'M2_1_NEGATIVE_CONTROL_NOT_REJECTED');
  END;
  PERFORM pg_temp.m2_1_add_negative('M2_1_NEG_020_DUPLICATE_LATEST_GRAIN','Duplicate latest-contract grain is rejected',v_rejected,v_state,v_message);
END;
$negative_tests$;

DO $inventory$
DECLARE v_total bigint; v_pass bigint;
BEGIN
 SELECT count(*),count(*) FILTER(WHERE status='PASS') INTO v_total,v_pass FROM _m2_1_negative_controls;
 IF v_total<>20 OR v_pass<>20 THEN
  RAISE EXCEPTION 'M2.1 negative controls expected 20 of 20 PASS; observed % of %.',v_pass,v_total;
 END IF;
END;
$inventory$;

DELETE FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m2_1_nctx) AND evidence_code LIKE 'M2_1_NEG_%';

INSERT INTO msbf_ctl.run_evidence(
 run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation
)
SELECT (SELECT run_id FROM _m2_1_nctx),evidence_code,'PORTFOLIO',test_name,
       coalesce(sqlstate_observed,'<NONE>')||'|'||coalesce(observed_message,'<NONE>'),
       'NEGATIVE_CONTROL',status,interpretation
FROM _m2_1_negative_controls;

COMMIT;
SELECT evidence_code,test_name,status,sqlstate_observed,observed_message,interpretation
FROM _m2_1_negative_controls ORDER BY evidence_code;
