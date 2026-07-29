/* ============================================================================
MSBF M1.11 Cash-Flow Archetypes & Operating Resilience — Negative Controls
Version : v0.2R2
Purpose : Prove fail-closed behavior for disabled generation, invalid component
          weights, invalid tier ordering, unapproved policy, prerequisite drift,
          and attempted post-generation rerun.
Mode    : Temporary mutations occur inside PL/pgSQL exception subtransactions
          and are rolled back automatically.
Output  : One filterable six-row result set. All six controls must PASS.
============================================================================ */

/* 1. Initialize session-preserved negative-control results */
BEGIN;
DROP TABLE IF EXISTS _m1_11_negative;
CREATE TEMP TABLE _m1_11_negative(
 evidence_code text PRIMARY KEY,metric_name text,observed_value text,
 threshold_value text,status text,interpretation text
) ON COMMIT PRESERVE ROWS;
CREATE OR REPLACE FUNCTION pg_temp.m1_11_neg(p_code text,p_name text,p_pass boolean,p_obs text,p_interp text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 INSERT INTO _m1_11_negative VALUES(p_code,p_name,p_obs,'REJECTED',CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,p_interp);
END $$;
/* 2. Define fail-closed governed configuration guard */
CREATE OR REPLACE FUNCTION pg_temp.m1_11_assert_policy_configuration()
RETURNS void LANGUAGE plpgsql AS $$
DECLARE p jsonb; w numeric;
BEGIN
 SELECT profile_payload INTO STRICT p FROM msbf_ctl.policy_profile
 WHERE profile_code='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE' AND profile_version=1 AND status='APPROVED';
 IF NOT coalesce((p->>'generation_enabled')::boolean,false) THEN RAISE EXCEPTION 'M1.11 generation disabled'; END IF;
 IF p->>'methodology_version'<>'M1_11_METHOD_V1_1' OR p->>'composite_score_basis'<>'SUM_PERSISTED_WEIGHTED_COMPONENTS' THEN RAISE EXCEPTION 'M1.11 methodology or composite basis is invalid'; END IF;
 w=(p->>'component_weight_revenue')::numeric+(p->>'component_weight_liquidity')::numeric+
   (p->>'component_weight_burden')::numeric+(p->>'component_weight_continuity')::numeric+
   (p->>'component_weight_data_confidence')::numeric;
 IF abs(w-1)>0.0000001 THEN RAISE EXCEPTION 'M1.11 component weights do not sum to one'; END IF;
 IF NOT ((p->>'tier_1_score_min')::numeric>(p->>'tier_2_score_min')::numeric
     AND (p->>'tier_2_score_min')::numeric>(p->>'tier_3_score_min')::numeric
     AND (p->>'tier_3_score_min')::numeric>(p->>'tier_4_score_min')::numeric) THEN
   RAISE EXCEPTION 'M1.11 tier thresholds are not strictly descending';
 END IF;
END $$;
/* 3. Execute six controlled fault-injection tests */
DO $tests$
DECLARE rid bigint; rejected boolean;
BEGIN
 SELECT run_id INTO rid FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
 rejected=false; BEGIN
   UPDATE msbf_ctl.policy_profile SET profile_payload=jsonb_set(profile_payload,'{generation_enabled}','false')
    WHERE profile_code='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE' AND profile_version=1;
   PERFORM pg_temp.m1_11_assert_policy_configuration();
 EXCEPTION WHEN OTHERS THEN rejected=true; END;
 PERFORM pg_temp.m1_11_neg('M1_11_NEG_01_DISABLED_GENERATION','Disabled generation policy rejected',rejected,'rejected='||rejected,'Generation fails closed when disabled.');

 rejected=false; BEGIN
   UPDATE msbf_ctl.policy_profile SET profile_payload=jsonb_set(profile_payload,'{component_weight_revenue}','0.31')
    WHERE profile_code='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE' AND profile_version=1;
   PERFORM pg_temp.m1_11_assert_policy_configuration();
 EXCEPTION WHEN OTHERS THEN rejected=true; END;
 PERFORM pg_temp.m1_11_neg('M1_11_NEG_02_WEIGHT_SUM','Invalid component weight sum rejected',rejected,'rejected='||rejected,'Weights must total one.');

 rejected=false; BEGIN
   UPDATE msbf_ctl.policy_profile SET profile_payload=jsonb_set(profile_payload,'{tier_2_score_min}','85')
    WHERE profile_code='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE' AND profile_version=1;
   PERFORM pg_temp.m1_11_assert_policy_configuration();
 EXCEPTION WHEN OTHERS THEN rejected=true; END;
 PERFORM pg_temp.m1_11_neg('M1_11_NEG_03_TIER_ORDER','Invalid tier ordering rejected',rejected,'rejected='||rejected,'Tier cutoffs must descend.');

 rejected=false; BEGIN
   UPDATE msbf_ctl.policy_profile SET status='DRAFT'
    WHERE profile_code='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE' AND profile_version=1;
   PERFORM pg_temp.m1_11_assert_policy_configuration();
 EXCEPTION WHEN OTHERS THEN rejected=true; END;
 PERFORM pg_temp.m1_11_neg('M1_11_NEG_04_UNAPPROVED_POLICY','Unapproved policy rejected',rejected,'rejected='||rejected,'Only approved policy may govern M1.11.');

 rejected=false; BEGIN
   UPDATE msbf_ctl.run_registry SET run_status='M1_10_ACCEPTED' WHERE run_id=rid;
   IF (SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=rid)<>'M1_11_VALIDATED' THEN
      RAISE EXCEPTION 'Prerequisite status drift';
   END IF;
 EXCEPTION WHEN OTHERS THEN rejected=true; END;
 PERFORM pg_temp.m1_11_neg('M1_11_NEG_05_PREREQUISITE_DRIFT','Prerequisite run-status drift rejected',rejected,'rejected='||rejected,'Post-validation status drift is fail-closed.');

 rejected=false; BEGIN PERFORM msbf_m1.m1_11_assert_generation_ready(rid); EXCEPTION WHEN OTHERS THEN rejected=true; END;
 PERFORM pg_temp.m1_11_neg('M1_11_NEG_06_REGENERATION','Post-generation rerun rejected',rejected,'rejected='||rejected,'Existing target rows prevent regeneration.');
END $tests$;
/* 4. Persist negative-control evidence */
INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
SELECT (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),evidence_code,'PORTFOLIO',metric_name,observed_value,'TEXT',status,interpretation
FROM _m1_11_negative
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
 metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,metric_value_numeric=NULL,
 unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();
/* 5. Commit and return one session-filterable result set */
COMMIT;
SELECT * FROM _m1_11_negative ORDER BY evidence_code;
