/* ============================================================================
MSBF M1.14 Unit Economics & Risk-Adjusted Contribution — Negative Controls
Program : 104_msbf_m1_14_negative_control_tests_v0_2R4.sql
Version : v0.2R4
Purpose : Prove that M1.14 fails closed when critical policy, scenario, run
          status, or rerun protections are violated.
Output  : One filterable seven-row result set preserved after COMMIT in the
          same DBeaver session.
Safety  : Every temporary mutation occurs inside a PL/pgSQL exception
          subtransaction and is automatically rolled back.
============================================================================ */

BEGIN;
SET LOCAL statement_timeout='10min';

DROP TABLE IF EXISTS _m1_14_negative;
CREATE TEMP TABLE _m1_14_negative (
    evidence_code text PRIMARY KEY,
    control_name text NOT NULL,
    expected_result text NOT NULL,
    observed_result text,
    status text NOT NULL,
    interpretation text
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m1_14_add_negative(
    p_code text,p_name text,p_expected text,p_observed text,p_pass boolean,p_interpretation text
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO _m1_14_negative VALUES(
        p_code,p_name,p_expected,p_observed,
        CASE WHEN coalesce(p_pass,false) THEN 'PASS' ELSE 'FAIL' END,
        p_interpretation
    );
END;
$$;

DO $controls$
DECLARE
    v_run_id bigint;
    v_stress_id bigint;
    v_message text;
BEGIN
    SELECT run_id INTO STRICT v_run_id
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

    SELECT e.scenario_id INTO STRICT v_stress_id
    FROM msbf_m1.application_unit_economics_snapshot e
    JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
    WHERE e.module1_run_id=v_run_id AND sr.scenario_code='RECESSION_ENERGY'
    LIMIT 1;

    /* 01 — disabled generation policy */
    v_message:=NULL;
    BEGIN
        UPDATE msbf_ctl.policy_profile
        SET profile_payload=jsonb_set(profile_payload,'{generation_enabled}','false'::jsonb)
        WHERE profile_code='M1_14_UNIT_ECONOMICS_CONTRIBUTION' AND profile_version=1;
        PERFORM msbf_m1.m1_14_assert_configuration(v_run_id);
        RAISE EXCEPTION 'CONTROL_DID_NOT_FAIL';
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; END;
    PERFORM pg_temp.m1_14_add_negative(
        'M1_14_NEG_01_DISABLED_GENERATION','Disabled generation policy',
        'Guard rejects disabled generation',v_message,
        v_message IS NOT NULL AND v_message<>'CONTROL_DID_NOT_FAIL',
        'Generation cannot proceed when the governed enablement flag is false.'
    );

    /* 02 — invalid processor-payment cost rate */
    v_message:=NULL;
    BEGIN
        UPDATE msbf_ctl.policy_profile
        SET profile_payload=jsonb_set(profile_payload,'{processor_payment_cost_rate}','1.5'::jsonb)
        WHERE profile_code='M1_14_UNIT_ECONOMICS_CONTRIBUTION' AND profile_version=1;
        PERFORM msbf_m1.m1_14_assert_configuration(v_run_id);
        RAISE EXCEPTION 'CONTROL_DID_NOT_FAIL';
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; END;
    PERFORM pg_temp.m1_14_add_negative(
        'M1_14_NEG_02_INVALID_PROCESSOR_RATE','Invalid processor-payment cost rate',
        'Guard rejects out-of-range cost rate',v_message,
        v_message IS NOT NULL AND v_message<>'CONTROL_DID_NOT_FAIL',
        'Processor cost assumptions fail closed outside the approved zero-to-one range.'
    );

    /* 03 — invalid economic-tier threshold order */
    v_message:=NULL;
    BEGIN
        UPDATE msbf_ctl.policy_profile
        SET profile_payload=jsonb_set(
            jsonb_set(profile_payload,'{economic_tier_1_return_threshold}','0.10'::jsonb),
            '{economic_tier_2_return_threshold}','0.20'::jsonb
        )
        WHERE profile_code='M1_14_UNIT_ECONOMICS_CONTRIBUTION' AND profile_version=1;
        PERFORM msbf_m1.m1_14_assert_configuration(v_run_id);
        RAISE EXCEPTION 'CONTROL_DID_NOT_FAIL';
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; END;
    PERFORM pg_temp.m1_14_add_negative(
        'M1_14_NEG_03_INVALID_TIER_ORDER','Invalid economic-tier threshold order',
        'Guard rejects non-monotonic thresholds',v_message,
        v_message IS NOT NULL AND v_message<>'CONTROL_DID_NOT_FAIL',
        'Economic tiers cannot be generated from unordered thresholds.'
    );

    /* 04 — unapproved policy */
    v_message:=NULL;
    BEGIN
        UPDATE msbf_ctl.policy_profile SET status='DRAFT'
        WHERE profile_code='M1_14_UNIT_ECONOMICS_CONTRIBUTION' AND profile_version=1;
        PERFORM msbf_m1.m1_14_assert_configuration(v_run_id);
        RAISE EXCEPTION 'CONTROL_DID_NOT_FAIL';
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; END;
    PERFORM pg_temp.m1_14_add_negative(
        'M1_14_NEG_04_UNAPPROVED_POLICY','Unapproved M1.14 policy',
        'Guard rejects non-approved policy',v_message,
        v_message IS NOT NULL AND v_message<>'CONTROL_DID_NOT_FAIL',
        'Only an approved methodology profile may govern unit economics.'
    );

    /* 05 — unapproved accepted stress scenario */
    v_message:=NULL;
    BEGIN
        UPDATE msbf_ctl.scenario_registry SET status='DRAFT'
        WHERE scenario_id=v_stress_id;
        PERFORM msbf_m1.m1_14_assert_configuration(v_run_id);
        RAISE EXCEPTION 'CONTROL_DID_NOT_FAIL';
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; END;
    PERFORM pg_temp.m1_14_add_negative(
        'M1_14_NEG_05_UNAPPROVED_STRESS_SCENARIO','Unapproved accepted stress scenario',
        'Guard rejects unapproved matched stress input',v_message,
        v_message IS NOT NULL AND v_message<>'CONTROL_DID_NOT_FAIL',
        'M1.14 requires the approved M1.6 matched stress scenario.'
    );

    /* 06 — prerequisite run-status drift */
    v_message:=NULL;
    BEGIN
        UPDATE msbf_ctl.run_registry SET run_status='M1_12_ACCEPTED' WHERE run_id=v_run_id;
        PERFORM msbf_m1.m1_14_assert_generation_ready(v_run_id);
        RAISE EXCEPTION 'CONTROL_DID_NOT_FAIL';
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; END;
    PERFORM pg_temp.m1_14_add_negative(
        'M1_14_NEG_06_RUN_STATUS_DRIFT','Prerequisite run-status drift',
        'Guard rejects any state other than M1_13_ACCEPTED for generation readiness',v_message,
        v_message IS NOT NULL AND v_message<>'CONTROL_DID_NOT_FAIL',
        'The generator is bound to the accepted predecessor state.'
    );

    /* 07 — attempted post-generation rerun */
    v_message:=NULL;
    BEGIN
        PERFORM msbf_m1.m1_14_assert_generation_ready(v_run_id);
        RAISE EXCEPTION 'CONTROL_DID_NOT_FAIL';
    EXCEPTION WHEN OTHERS THEN v_message:=SQLERRM; END;
    PERFORM pg_temp.m1_14_add_negative(
        'M1_14_NEG_07_POST_GENERATION_RERUN','Attempted post-generation rerun',
        'Guard rejects rerun after physical outputs exist',v_message,
        v_message IS NOT NULL AND v_message<>'CONTROL_DID_NOT_FAIL',
        'Committed M1.14 evidence cannot be regenerated in place.'
    );
END;
$controls$;

INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_text,
    unit_code,status,interpretation
)
SELECT
    (SELECT run_id FROM msbf_ctl.run_registry
     WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
    evidence_code,'PORTFOLIO',control_name,observed_result,
    'TEXT',status,interpretation||' | expected='||expected_result
FROM _m1_14_negative
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,
    metric_value_numeric=NULL,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
    interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

COMMIT;

SELECT evidence_code,control_name,expected_result,observed_result,status,interpretation
FROM _m1_14_negative ORDER BY evidence_code;
