/* ============================================================================
MSBF M1.12 Merchant Risk Components & Integrated Risk Proxy — Negative Controls
Version : v0.2
Purpose : Prove that material configuration, scenario-scope, prerequisite-state,
          and rerun defects fail closed without changing accepted business rows.
Mode    : Persists seven controlled negative-test results. Temporary mutations
          execute inside exception subtransactions and roll back automatically.
Output  : One filterable seven-row result set preserved after COMMIT.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='10min';

DROP TABLE IF EXISTS _m1_12_negative;
CREATE TEMP TABLE _m1_12_negative(
    evidence_code text PRIMARY KEY,
    test_name text NOT NULL,
    expected_failure text NOT NULL,
    observed_failure text,
    status text NOT NULL,
    interpretation text NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m1_12_record_negative(
    p_code text,p_name text,p_expected text,p_observed text,p_pass boolean,p_interpretation text
) RETURNS void LANGUAGE plpgsql AS $fn$
BEGIN
    INSERT INTO _m1_12_negative VALUES(
        p_code,p_name,p_expected,p_observed,
        CASE WHEN coalesce(p_pass,false) THEN 'PASS' ELSE 'FAIL' END,
        p_interpretation
    );
END;
$fn$;

DO $tests$
DECLARE
    v_run_id bigint;
    v_message text;
    v_pass boolean;
BEGIN
    SELECT run_id INTO STRICT v_run_id
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

    /* 1. Generation disabled */
    v_message:=NULL; v_pass:=false;
    BEGIN
        UPDATE msbf_ctl.policy_profile SET profile_payload=jsonb_set(profile_payload,'{generation_enabled}','false'::jsonb)
        WHERE profile_code='M1_12_INTEGRATED_RISK_PROXY' AND profile_version=1;
        PERFORM msbf_m1.m1_12_assert_configuration();
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; v_pass:=position('disabled' in lower(SQLERRM))>0;
    END;
    PERFORM pg_temp.m1_12_record_negative('M1_12_NEG_01_GENERATION_DISABLED','Generation-disabled policy','generation is disabled',v_message,v_pass,'The module must fail closed when generation is disabled.');

    /* 2. Invalid component-weight sum */
    v_message:=NULL; v_pass:=false;
    BEGIN
        UPDATE msbf_ctl.policy_profile SET profile_payload=jsonb_set(profile_payload,'{component_weight_operating_resilience}','0.26'::jsonb)
        WHERE profile_code='M1_12_INTEGRATED_RISK_PROXY' AND profile_version=1;
        PERFORM msbf_m1.m1_12_assert_configuration();
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; v_pass:=position('weights must sum' in lower(SQLERRM))>0;
    END;
    PERFORM pg_temp.m1_12_record_negative('M1_12_NEG_02_WEIGHT_SUM','Invalid component-weight sum','weights must sum',v_message,v_pass,'The component system must remain fully governed.');

    /* 3. Invalid tier ordering */
    v_message:=NULL; v_pass:=false;
    BEGIN
        UPDATE msbf_ctl.policy_profile SET profile_payload=jsonb_set(profile_payload,'{risk_tier_2_max}','10.0'::jsonb)
        WHERE profile_code='M1_12_INTEGRATED_RISK_PROXY' AND profile_version=1;
        PERFORM msbf_m1.m1_12_assert_configuration();
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; v_pass:=position('strictly increasing' in lower(SQLERRM))>0;
    END;
    PERFORM pg_temp.m1_12_record_negative('M1_12_NEG_03_TIER_ORDER','Invalid risk-tier threshold order','strictly increasing',v_message,v_pass,'Ordinal risk tiers must remain monotonic.');

    /* 4. Unapproved policy profile */
    v_message:=NULL; v_pass:=false;
    BEGIN
        UPDATE msbf_ctl.policy_profile SET status='DRAFT'
        WHERE profile_code='M1_12_INTEGRATED_RISK_PROXY' AND profile_version=1;
        PERFORM msbf_m1.m1_12_assert_configuration();
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; v_pass:=position('approved policy' in lower(SQLERRM))>0;
    END;
    PERFORM pg_temp.m1_12_record_negative('M1_12_NEG_04_POLICY_APPROVAL','Unapproved M1.12 policy','approved policy',v_message,v_pass,'Only an approved methodology may generate risk evidence.');

    /* 5. Unapproved accepted stress scenario */
    v_message:=NULL; v_pass:=false;
    BEGIN
        UPDATE msbf_ctl.run_registry SET run_status='M1_11_ACCEPTED' WHERE run_id=v_run_id;
        UPDATE msbf_ctl.scenario_registry SET status='DRAFT'
        WHERE scenario_id IN(
            SELECT sr.scenario_id FROM msbf_ctl.scenario_registry sr
            JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
            WHERE ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS' AND ss.scenario_set_version=1
              AND sr.scenario_code='RECESSION_ENERGY' AND sr.scenario_version=1
        );
        PERFORM msbf_m1.m1_12_assert_generation_ready(v_run_id);
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; v_pass:=position('input/scenario scope mismatch' in lower(SQLERRM))>0;
    END;
    PERFORM pg_temp.m1_12_record_negative('M1_12_NEG_05_UNAPPROVED_STRESS_SCENARIO','Unapproved accepted stress scenario','input/scenario scope mismatch',v_message,v_pass,'The module must use the approved matched M1.6 scenario set.');

    /* 6. Prerequisite run-status drift */
    v_message:=NULL; v_pass:=false;
    BEGIN
        UPDATE msbf_ctl.run_registry SET run_status='M1_10_ACCEPTED' WHERE run_id=v_run_id;
        PERFORM msbf_m1.m1_12_assert_generation_ready(v_run_id);
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; v_pass:=position('requires m1_11_accepted' in lower(SQLERRM))>0;
    END;
    PERFORM pg_temp.m1_12_record_negative('M1_12_NEG_06_PREREQUISITE_STATUS','Prerequisite run-status drift','requires M1_11_ACCEPTED',v_message,v_pass,'Generation must begin only from the accepted M1.11 milestone.');

    /* 7. Attempted post-generation rerun */
    v_message:=NULL; v_pass:=false;
    BEGIN
        UPDATE msbf_ctl.run_registry SET run_status='M1_11_ACCEPTED' WHERE run_id=v_run_id;
        PERFORM msbf_m1.m1_12_assert_generation_ready(v_run_id);
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; v_pass:=position('target rows already exist' in lower(SQLERRM))>0;
    END;
    PERFORM pg_temp.m1_12_record_negative('M1_12_NEG_07_RERUN_PROTECTION','Attempted post-generation rerun','target rows already exist',v_message,v_pass,'Committed M1.12 evidence must not be regenerated in place.');
END;
$tests$;

INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
SELECT (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
       evidence_code,'PORTFOLIO',test_name,coalesce(observed_failure,'NO ERROR'),'TEXT',status,
       'expected='||expected_failure||'|'||interpretation
FROM _m1_12_negative
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
 metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,
 metric_value_numeric=NULL,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
 interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

DO $assert$
DECLARE v_total integer; v_pass integer;
BEGIN
 SELECT count(*),count(*) FILTER(WHERE status='PASS') INTO v_total,v_pass FROM _m1_12_negative;
 IF v_total<>7 OR v_pass<>7 THEN
   RAISE EXCEPTION 'M1.12 negative controls failed: %/% PASS.',v_pass,v_total;
 END IF;
END;
$assert$;

COMMIT;
SELECT evidence_code,test_name,expected_failure,observed_failure,status,interpretation
FROM _m1_12_negative ORDER BY evidence_code;
