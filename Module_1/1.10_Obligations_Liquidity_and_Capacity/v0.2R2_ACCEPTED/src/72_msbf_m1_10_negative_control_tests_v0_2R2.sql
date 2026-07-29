/* ============================================================================
MSBF M1.10 Obligations, Liquidity & Residual Cash Flow — Negative Controls
Version : v0.2R2
Purpose : Prove fail-closed rejection of disabled or inconsistent policy,
          invalid scenario approval, prerequisite drift, and regeneration.
Output  : One filterable six-row result set. The session-scoped table survives
          COMMIT until the DBeaver connection closes or this script is rerun.
============================================================================ */
BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='10min';
DROP TABLE IF EXISTS _m1_10_negative;
CREATE TEMP TABLE _m1_10_negative(
    evidence_code text PRIMARY KEY,
    control_name text NOT NULL,
    expected_behavior text NOT NULL,
    observed_behavior text,
    status text NOT NULL,
    interpretation text
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m1_10_add_negative(
    p_code text,p_name text,p_expected text,p_observed text,p_status text,p_interpretation text
) RETURNS void LANGUAGE plpgsql AS $fn$
BEGIN
  INSERT INTO _m1_10_negative VALUES(p_code,p_name,p_expected,p_observed,p_status,p_interpretation)
  ON CONFLICT(evidence_code) DO UPDATE SET control_name=EXCLUDED.control_name,
    expected_behavior=EXCLUDED.expected_behavior,observed_behavior=EXCLUDED.observed_behavior,
    status=EXCLUDED.status,interpretation=EXCLUDED.interpretation;
END;
$fn$;

DO $tests$
DECLARE v_run bigint; v_stress bigint; v_err text;
BEGIN
 SELECT run_id INTO STRICT v_run FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

 -- 01 Disabled generation policy.
 BEGIN
   UPDATE msbf_ctl.run_registry SET run_status='M1_9_ACCEPTED' WHERE run_id=v_run;
   UPDATE msbf_ctl.policy_profile SET profile_payload=jsonb_set(profile_payload,'{generation_enabled}','false'::jsonb)
   WHERE profile_code='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY' AND profile_version=1;
   PERFORM msbf_m1.m1_10_assert_generation_ready(v_run);
   RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
   v_err=SQLERRM;
   PERFORM pg_temp.m1_10_add_negative('M1_10_NEG_01_DISABLED_GENERATION','Disabled M1.10 generation policy',
     'Generation must fail closed','Rejected: '||v_err,
     CASE WHEN v_err ILIKE '%policy%' OR v_err ILIKE '%disabled%' THEN 'PASS' ELSE 'FAIL' END,
     'The approved generation flag cannot be disabled without rejection.');
 END;

 -- 02 Invalid methodology version.
 BEGIN
   UPDATE msbf_ctl.run_registry SET run_status='M1_9_ACCEPTED' WHERE run_id=v_run;
   UPDATE msbf_ctl.policy_profile SET profile_payload=jsonb_set(profile_payload,'{methodology_version}',to_jsonb('INVALID_METHOD'::text))
   WHERE profile_code='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY' AND profile_version=1;
   PERFORM msbf_m1.m1_10_assert_generation_ready(v_run);
   RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
   v_err=SQLERRM;
   PERFORM pg_temp.m1_10_add_negative('M1_10_NEG_02_INVALID_METHOD','Invalid M1.10 methodology version',
     'Generation must fail closed','Rejected: '||v_err,
     CASE WHEN v_err ILIKE '%policy%' OR v_err ILIKE '%inconsistent%' THEN 'PASS' ELSE 'FAIL' END,
     'Only the approved M1.10 methodology may generate evidence.');
 END;

 -- 03 Invalid requested-burden basis.
 BEGIN
   UPDATE msbf_ctl.run_registry SET run_status='M1_9_ACCEPTED' WHERE run_id=v_run;
   UPDATE msbf_ctl.policy_profile SET profile_payload=jsonb_set(profile_payload,'{requested_burden_basis}',to_jsonb('RATE_ONLY'::text))
   WHERE profile_code='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY' AND profile_version=1;
   PERFORM msbf_m1.m1_10_assert_generation_ready(v_run);
   RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
   v_err=SQLERRM;
   PERFORM pg_temp.m1_10_add_negative('M1_10_NEG_03_INVALID_BURDEN_BASIS','Invalid requested-burden basis',
     'Generation must fail closed','Rejected: '||v_err,
     CASE WHEN v_err ILIKE '%policy%' OR v_err ILIKE '%inconsistent%' THEN 'PASS' ELSE 'FAIL' END,
     'The conservative maximum-of-rate-or-horizon basis is governed.');
 END;

 -- 04 Unapproved accepted stress scenario.
 BEGIN
   SELECT sr.scenario_id INTO STRICT v_stress
   FROM msbf_ctl.scenario_registry sr JOIN msbf_ctl.scenario_set ss USING(scenario_set_id)
   WHERE ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS' AND ss.scenario_set_version=1
     AND sr.scenario_code='RECESSION_ENERGY' AND sr.scenario_version=1;
   UPDATE msbf_ctl.run_registry SET run_status='M1_9_ACCEPTED' WHERE run_id=v_run;
   UPDATE msbf_ctl.scenario_registry SET status='DRAFT' WHERE scenario_id=v_stress;
   PERFORM msbf_m1.m1_10_assert_generation_ready(v_run);
   RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
   v_err=SQLERRM;
   PERFORM pg_temp.m1_10_add_negative('M1_10_NEG_04_UNAPPROVED_SCENARIO','Unapproved matched stress scenario',
     'Generation must fail closed','Rejected: '||v_err,
     CASE WHEN v_err ILIKE '%scenarios%' OR v_err ILIKE '%observed%' THEN 'PASS' ELSE 'FAIL' END,
     'M1.10 requires the approved M1.6 scenario pair represented in accepted M1.9 features.');
 END;

 -- 05 Prerequisite status drift.
 BEGIN
   UPDATE msbf_ctl.run_registry SET run_status='M1_8_ACCEPTED' WHERE run_id=v_run;
   PERFORM msbf_m1.m1_10_assert_generation_ready(v_run);
   RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
   v_err=SQLERRM;
   PERFORM pg_temp.m1_10_add_negative('M1_10_NEG_05_PREREQUISITE_DRIFT','Prerequisite run-status drift',
     'Generation must fail closed','Rejected: '||v_err,
     CASE WHEN v_err ILIKE '%M1_9_ACCEPTED%' THEN 'PASS' ELSE 'FAIL' END,
     'M1.10 cannot execute without accepted M1.9 feature evidence.');
 END;

 -- 06 Post-generation rerun rejection.
 BEGIN
   UPDATE msbf_ctl.run_registry SET run_status='M1_9_ACCEPTED' WHERE run_id=v_run;
   PERFORM msbf_m1.m1_10_assert_generation_ready(v_run);
   RAISE EXCEPTION 'CONTROL_NOT_REJECTED';
 EXCEPTION WHEN OTHERS THEN
   v_err=SQLERRM;
   PERFORM pg_temp.m1_10_add_negative('M1_10_NEG_06_REGENERATION_REJECTED','Attempted post-generation rerun',
     'Existing M1.10 rows must block regeneration','Rejected: '||v_err,
     CASE WHEN v_err ILIKE '%regeneration rejected%' OR v_err ILIKE '%obligations%' OR v_err ILIKE '%capacity rows%' THEN 'PASS' ELSE 'FAIL' END,
     'Committed M1.10 evidence is immutable for the accepted run.');
 END;
END;
$tests$;

INSERT INTO msbf_ctl.run_evidence(
 run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation
)
SELECT r.run_id,n.evidence_code,'PORTFOLIO',n.control_name,n.observed_behavior,'TEXT',n.status,n.interpretation
FROM _m1_10_negative n CROSS JOIN msbf_ctl.run_registry r
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
 metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,
 unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,
 created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry
SET run_status=CASE WHEN (SELECT count(*) FILTER(WHERE status='FAIL') FROM _m1_10_negative)=0
                    THEN 'M1_10_VALIDATED' ELSE 'M1_10_FAILED' END,
    notes=coalesce(notes,'')||E'\nM1.10 negative controls executed: '
      ||(SELECT count(*) FILTER(WHERE status='PASS') FROM _m1_10_negative)||'/6 PASS.'
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

COMMIT;
SELECT evidence_code,control_name,expected_behavior,observed_behavior,status,interpretation
FROM _m1_10_negative ORDER BY evidence_code;
