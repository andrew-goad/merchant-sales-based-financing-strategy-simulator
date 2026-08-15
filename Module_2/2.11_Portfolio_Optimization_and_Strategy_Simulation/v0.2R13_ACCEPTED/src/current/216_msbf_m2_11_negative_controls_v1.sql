/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.11 — Portfolio Optimization & Strategy Simulation

Program     : 216_msbf_m2_11_negative_controls_v1.sql
Version     : v1
Revision    : LIVE_EXECUTION_NEGATIVE_CONTROL_011_CORRECTION_R1
Work package: M2.11 Work Package 3

Purpose
-------
Execute exactly twenty real, isolated negative controls against the fixed
Programs 212–215 state. Each persistent defect is injected inside a PL/pgSQL
exception subtransaction. The subtransaction is forced to abort even when the
expected rejection does not occur, so no test row mutation can persist. The
archive identity sequence is fingerprinted before and after the suite so a
nontransactional sequence side effect also blocks evidence persistence.

Mutation boundary
-----------------
The only committed persistent writes are twenty M2_11_NEG evidence rows after
20/20 expected rejections reconcile. Before and after all controls, the program
fingerprints all 19 canonical families and 19,298 canonical entities, the 19
stored registry set hashes, latest/archive identities, the archive identity
sequence state, the registry row hash, and the combined set hash. Canonical
M2.11 state, lifecycle values, and identity-sequence state must remain unchanged.
Program 216 leaves the run and contract at VALIDATED.

Required starting state
-----------------------
run_status       = M2_11_VALIDATED
contract_status  = VALIDATED
M2_11_POS PASS   = 120
M2_11_NEG rows   = 0
acceptance rows  = 0

Execution
---------
Execute as one SQL script. Stop on the first error. This source is statically
built and has not been submitted to a PostgreSQL parser or runtime.
============================================================================ */

BEGIN;
SET LOCAL work_mem='128MB';
SET LOCAL statement_timeout='45min';
SET LOCAL lock_timeout='15s';
SET LOCAL jit=off;

DROP TABLE IF EXISTS tmp_eval_m2_11_negative_context;
CREATE TEMP TABLE tmp_eval_m2_11_negative_context ON COMMIT DROP AS
SELECT r.run_id,r.run_status,c.contract_status,c.contract_version,c.row_hash AS registry_row_hash,
       c.combined_set_hash
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry c
  ON c.module1_run_id=r.run_id AND c.contract_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

DROP TABLE IF EXISTS tmp_eval_m2_11_negative_control;
CREATE TEMP TABLE tmp_eval_m2_11_negative_control
(
 control_sequence integer PRIMARY KEY,
 evidence_code text NOT NULL UNIQUE,
 control_title text NOT NULL,
 expected_sqlstate text NOT NULL,
 expected_message_prefix text NOT NULL,
 observed_sqlstate text,
 observed_message text,
 status text NOT NULL CHECK(status IN ('PASS','FAIL')),
 interpretation text NOT NULL
) ON COMMIT PRESERVE ROWS;

DO $m211_negative_context$
DECLARE
 v_rows bigint;
 v_pos_pass bigint;
 v_pos_total bigint;
BEGIN
 SELECT count(*) INTO v_rows FROM tmp_eval_m2_11_negative_context;
 IF v_rows<>1 THEN RAISE EXCEPTION 'Program 216 requires one validated M2.11 context; found %',v_rows; END IF;
 IF (SELECT run_status FROM tmp_eval_m2_11_negative_context)<>'M2_11_VALIDATED'
    OR (SELECT contract_status FROM tmp_eval_m2_11_negative_context)<>'VALIDATED' THEN
  RAISE EXCEPTION 'Program 216 requires M2_11_VALIDATED/VALIDATED; found %/%',
   (SELECT run_status FROM tmp_eval_m2_11_negative_context),(SELECT contract_status FROM tmp_eval_m2_11_negative_context);
 END IF;
 SELECT count(*),count(*) FILTER(WHERE status='PASS') INTO v_pos_total,v_pos_pass
 FROM msbf_ctl.run_evidence
 WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND evidence_code LIKE 'M2_11_POS_%';
 IF v_pos_total<>120 OR v_pos_pass<>120 THEN
  RAISE EXCEPTION 'Program 216 requires 120/120 positive controls; found total %, pass %',v_pos_total,v_pos_pass;
 END IF;
 IF EXISTS(SELECT 1 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND evidence_code LIKE 'M2_11_NEG_%') THEN
  RAISE EXCEPTION 'Program 216 requires pristine M2.11 negative-control evidence';
 END IF;
 IF EXISTS(SELECT 1 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND evidence_code='M2_11_ACCEPTANCE_SUMMARY')
    OR EXISTS(SELECT 1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION') THEN
  RAISE EXCEPTION 'Program 216 found premature M2.11 acceptance evidence';
 END IF;
END;
$m211_negative_context$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_record_negative
(
 p_sequence integer,p_code text,p_title text,p_expected_state text,p_expected_prefix text,
 p_observed_state text,p_observed_message text
)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE
 v_pass boolean;
BEGIN
 v_pass := p_observed_state=p_expected_state
           AND left(coalesce(p_observed_message,''),length(p_expected_prefix))=p_expected_prefix;
 INSERT INTO tmp_eval_m2_11_negative_control
 (control_sequence,evidence_code,control_title,expected_sqlstate,expected_message_prefix,
  observed_sqlstate,observed_message,status,interpretation)
 VALUES
 (p_sequence,p_code,p_title,p_expected_state,p_expected_prefix,p_observed_state,p_observed_message,
  CASE WHEN v_pass THEN 'PASS' ELSE 'FAIL' END,
  CASE WHEN v_pass THEN 'Expected rejection occurred and the isolated mutation rolled back.'
       WHEN p_observed_state='P2199' THEN 'Expected rejection did not occur; the forced sentinel rollback prevented persistence.'
       ELSE 'An unexpected rejection occurred; the isolated mutation still rolled back.' END);
END;
$function$;

/* Sentinel P2199 is raised after an unexpectedly successful mutation. Because
   every injection runs in an exception subtransaction, both expected and
   sentinel exceptions roll back the injected persistent change. */

CREATE TEMP TABLE tmp_eval_negative_expected_strategy
(
 strategy_profile_code text PRIMARY KEY,
 access_rate_weight numeric(9,6),selected_exposure_weight numeric(9,6),
 finance_charge_weight numeric(9,6),expected_loss_density_weight numeric(9,6),
 risk_adjusted_contribution_weight numeric(9,6),annualized_return_weight numeric(9,6),
 servicing_burden_weight numeric(9,6),payment_burden_weight numeric(9,6),
 candidate_domain_weight_total numeric(9,6),scope_domain_weight_total numeric(9,6)
) ON COMMIT DROP;
INSERT INTO tmp_eval_negative_expected_strategy
(strategy_profile_code,access_rate_weight,selected_exposure_weight,finance_charge_weight,
 expected_loss_density_weight,risk_adjusted_contribution_weight,annualized_return_weight,
 servicing_burden_weight,payment_burden_weight,candidate_domain_weight_total,scope_domain_weight_total)
VALUES
('BASELINE_REPLAY',0,0,0,0,0,0,0,0,0,0),
('ACCESS_EXPANSION',.45,.15,.05,.10,.10,.05,0,.10,1,1),
('PRICE_FOR_RISK',.10,.05,.30,.15,.20,.10,0,.10,1,1),
('PAYMENT_BURDEN_RELIEF',.15,.10,.05,.10,.10,.05,0,.45,1,1),
('LOSS_CONTAINMENT',.05,.25,0,.40,.10,.05,0,.15,1,1),
('PROFITABILITY_DISCIPLINE',.05,.05,.15,.15,.35,.20,0,.05,1,1),
('EARLY_INTERVENTION',0,0,0,0,0,0,.60,.40,0,1),
('BALANCED_FRONTIER',.20,.05,.10,.20,.20,.10,.10,.05,.90,1);

CREATE TEMP TABLE tmp_eval_negative_selected_checkpoint ON COMMIT DROP AS
SELECT module1_run_id,scenario_id,merchant_application_id,candidate_template_code,
       strategy_profile_code,candidate_selected_flag
FROM msbf_m2.application_strategy_candidate_evaluation
WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context);
CREATE UNIQUE INDEX tmp_eval_negative_selected_checkpoint_u1 ON tmp_eval_negative_selected_checkpoint
(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code);
ANALYZE tmp_eval_negative_selected_checkpoint;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_source_identity()
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 IF EXISTS
 (
  SELECT 1
  FROM msbf_m2.portfolio_strategy_application_source_snapshot a
  JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry r
    ON r.module1_run_id=a.module1_run_id AND r.contract_version=1
  WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND (a.m1_17_combined_g2_hash IS DISTINCT FROM r.source_m1_17_combined_hash
      OR a.m2_2_combined_set_hash IS DISTINCT FROM r.source_m2_2_combined_hash
      OR a.m2_4_combined_set_hash IS DISTINCT FROM r.source_m2_4_combined_hash)
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG SOURCE_IDENTITY: accepted source identity drift detected';
 END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_selected_candidates()
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 IF EXISTS
 (
  SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation s
  WHERE s.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND s.selected_candidate_template_code IS NOT NULL
    AND NOT EXISTS
    (
      SELECT 1 FROM msbf_m2.portfolio_strategy_candidate_source_snapshot c
      WHERE c.module1_run_id=s.module1_run_id AND c.scenario_id=s.scenario_id
        AND c.merchant_application_id=s.merchant_application_id
        AND c.candidate_template_code=s.selected_candidate_template_code
        AND c.source_candidate_row_hash=s.selected_candidate_source_row_hash
    )
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG UNACCEPTED_CANDIDATE: selected candidate is outside accepted M2.2 inventory';
 END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_preserved_outcomes(p_mode text)
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 IF p_mode='POLICY' AND EXISTS
 (
  SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND source_pricing_disposition_code='NO_STRUCTURE_POLICY_DECLINE'
    AND strategy_outcome_code<>'NO_ACCESS_POLICY_DECLINE'
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG POLICY_DECLINE_OVERRIDE: favorable policy-decline override detected';
 ELSIF p_mode='INSUFFICIENT' AND EXISTS
 (
  SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND source_pricing_disposition_code='NO_STRUCTURE_INSUFFICIENT_EVIDENCE'
    AND strategy_outcome_code<>'NO_ACCESS_INSUFFICIENT_EVIDENCE'
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG INSUFFICIENT_OVERRIDE: favorable insufficient-evidence override detected';
 END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_hard_constraint_selection()
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 IF EXISTS
 (
  SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND candidate_selected_flag AND hard_constraint_violation_count>0
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG HARD_CONSTRAINT_BYPASS: constrained candidate was selected';
 END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_objective_evidence()
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 IF EXISTS
 (
  SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND candidate_selected_flag AND candidate_scoring_applicable_flag
    AND (NOT objective_evidence_complete_flag OR objective_score IS NULL)
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG MISSING_OBJECTIVE_EVIDENCE: weighted selected candidate lacks objective evidence';
 END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_weight_matrix()
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 IF EXISTS
 (
  SELECT 1
  FROM msbf_m2.portfolio_strategy_profile p
  FULL JOIN tmp_eval_negative_expected_strategy e USING(strategy_profile_code)
  WHERE coalesce(p.module1_run_id,(SELECT run_id FROM tmp_eval_m2_11_negative_context))=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND (p.strategy_profile_code IS NULL OR e.strategy_profile_code IS NULL
      OR (p.access_rate_weight,p.selected_exposure_weight,p.finance_charge_weight,
          p.expected_loss_density_weight,p.risk_adjusted_contribution_weight,p.annualized_return_weight,
          p.servicing_burden_weight,p.payment_burden_weight,p.candidate_domain_weight_total,p.scope_domain_weight_total)
         IS DISTINCT FROM
         (e.access_rate_weight,e.selected_exposure_weight,e.finance_charge_weight,
          e.expected_loss_density_weight,e.risk_adjusted_contribution_weight,e.annualized_return_weight,
          e.servicing_burden_weight,e.payment_burden_weight,e.candidate_domain_weight_total,e.scope_domain_weight_total))
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG WEIGHT_CORRUPTION: frozen strategy weight matrix drift detected';
 END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_candidate_selection()
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 IF EXISTS
 (
  SELECT 1
  FROM msbf_m2.application_strategy_candidate_evaluation p
  FULL JOIN tmp_eval_negative_selected_checkpoint e
    USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code)
  WHERE coalesce(p.module1_run_id,e.module1_run_id)=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND (p.module1_run_id IS NULL OR e.module1_run_id IS NULL
         OR p.candidate_selected_flag IS DISTINCT FROM e.candidate_selected_flag)
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG TIEBREAK_CORRUPTION: deterministic selected-candidate identity changed';
 END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_portfolio_application_grain()
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 IF EXISTS
 (
  SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
  GROUP BY module1_run_id,merchant_application_id,strategy_profile_code
  HAVING count(*) FILTER(WHERE portfolio_adverse_selected_flag)<>1
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG PORTFOLIO_DOUBLE_COUNT: PORTFOLIO application grain selects other than one adverse row';
 END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_source_stress()
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 IF EXISTS
 (
  SELECT 1
  FROM msbf_m2.portfolio_strategy_application_source_snapshot b
  JOIN msbf_m2.portfolio_strategy_application_source_snapshot s
    ON s.module1_run_id=b.module1_run_id AND s.merchant_application_id=b.merchant_application_id
   AND s.scenario_code='RECESSION_ENERGY'
  WHERE b.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND b.scenario_code='BASELINE'
    AND (s.integrated_risk_score < b.integrated_risk_score-0.00000001::numeric
      OR s.synthetic_merchant_risk_proxy < b.synthetic_merchant_risk_proxy-0.00000001::numeric
      OR (s.path_weighted_ead_amount<>0 AND b.path_weighted_ead_amount<>0
          AND s.schedule_adjusted_comparative_expected_loss_amount/s.path_weighted_ead_amount
              < b.schedule_adjusted_comparative_expected_loss_amount/b.path_weighted_ead_amount-0.00000001::numeric)
      OR s.annualized_risk_adjusted_return_rate > b.annualized_risk_adjusted_return_rate+0.00000001::numeric)
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG FAVORABLE_SOURCE_STRESS: favorable accepted-source movement under stress detected';
 END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_strategy_stress()
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 IF EXISTS
 (
  SELECT 1
  FROM msbf_m2.application_portfolio_strategy_simulation b
  JOIN msbf_m2.application_portfolio_strategy_simulation s
    ON s.module1_run_id=b.module1_run_id AND s.merchant_application_id=b.merchant_application_id
   AND s.strategy_profile_code=b.strategy_profile_code AND s.scenario_code='RECESSION_ENERGY'
  WHERE b.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND b.scenario_code='BASELINE'
    AND (s.strategy_outcome_rank<b.strategy_outcome_rank OR s.feasibility_rank<b.feasibility_rank)
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG FAVORABLE_STRATEGY_STRESS: favorable strategy access or feasibility movement under stress detected';
 END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_latest_archive()
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 IF EXISTS
 (
  SELECT 1 FROM msbf_m2.portfolio_strategy_simulation_latest l
  FULL JOIN msbf_m2.portfolio_strategy_simulation_archive a
    USING(module1_run_id,contract_version,strategy_profile_code,reporting_scope_code)
  WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND (l.module1_run_id IS NULL OR a.module1_run_id IS NULL
      OR a.contract_row_hash IS DISTINCT FROM l.contract_row_hash
      OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at'))
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG LATEST_ARCHIVE_MISMATCH: latest/archive reproduction mismatch detected';
 END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_canonical_identity()
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE v_count bigint; v_objects bigint;
BEGIN
 SELECT count(*),count(DISTINCT object_code) INTO v_count,v_objects
 FROM msbf_m2.v_m2_11_canonical_entity_hash_source
 WHERE split_part(business_key,'|',1)=(SELECT run_id::text FROM tmp_eval_m2_11_negative_context);
 IF v_count<>19298 OR v_objects<>19 THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG CANONICAL_COUNT: canonical count or family count differs from 19,298/19';
 END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_assert_authorized_wp3_target(p_operation text,p_object text)
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 IF p_operation NOT IN ('READ_VALIDATION_SOURCE','WRITE_VALIDATION_EVIDENCE','UPDATE_VALIDATION_LIFECYCLE')
    OR p_object NOT IN
    (
     'msbf_ctl.run_registry','msbf_ctl.run_evidence','msbf_ctl.acceptance_gate_result',
     'msbf_ctl.m2_11_policy_profile','msbf_ctl.m2_11_portfolio_strategy_contract_registry',
     'msbf_m2.portfolio_strategy_profile','msbf_m2.portfolio_strategy_objective_definition',
     'msbf_m2.portfolio_strategy_constraint_definition','msbf_m2.portfolio_strategy_reason_definition',
     'msbf_m2.portfolio_strategy_application_source_snapshot','msbf_m2.portfolio_strategy_candidate_source_snapshot',
     'msbf_m2.portfolio_strategy_account_source_snapshot','msbf_m2.portfolio_strategy_kpi_source_snapshot',
     'msbf_m2.portfolio_strategy_queue_source_snapshot','msbf_m2.application_strategy_candidate_evaluation',
     'msbf_m2.application_portfolio_strategy_simulation','msbf_m2.account_servicing_strategy_simulation',
     'msbf_m2.portfolio_strategy_summary','msbf_m2.portfolio_strategy_frontier',
     'msbf_m2.portfolio_strategy_comparison','msbf_m2.portfolio_strategy_simulation_latest',
     'msbf_m2.portfolio_strategy_simulation_archive','msbf_m2.v_m2_11_canonical_entity_hash_source',
     'msbf_m2.v_m2_11_matched_application_stress_comparison','msbf_ctl.v_m2_11_portfolio_strategy_lineage',
     'msbf_m1.v_m1_17_g2_integrated_consumption','msbf_m2.application_pricing_structure_latest',
     'msbf_m2.application_pricing_structure_candidate','msbf_m2.application_booking_funding_activation_latest',
     'msbf_m2.application_operational_activation_latest','msbf_m2.application_portfolio_performance_latest',
     'msbf_m2.portfolio_kpi_snapshot','msbf_m2.servicing_queue_analytics_snapshot'
    ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.11 NEG UNAUTHORIZED_STAGE_SOURCE: object or operation is outside the governed WP3 boundary';
 END IF;
END;
$function$;


/* --------------------------------------------------------------------------
Row-level physical canonical identity used to prove that no individual entity
survives a negative-control subtransaction with a changed payload, key, or
presence state. Stored row-hash columns are not trusted for this postflight.
--------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION pg_temp.m2_11_canonical_physical_rows()
RETURNS TABLE(object_sequence integer,object_code text,business_key text,physical_row_hash text)
LANGUAGE sql STABLE AS $function$
SELECT 1,'msbf_ctl.m2_11_policy_profile',t.module1_run_id::text,msbf_ctl.m2_11_hash_jsonb(t.configuration_payload) FROM msbf_ctl.m2_11_policy_profile t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 2,'msbf_m2.portfolio_strategy_profile',t.module1_run_id::text||'|'||t.strategy_profile_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_profile t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 3,'msbf_m2.portfolio_strategy_objective_definition',t.module1_run_id::text||'|'||t.objective_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_objective_definition t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 4,'msbf_m2.portfolio_strategy_constraint_definition',t.module1_run_id::text||'|'||t.constraint_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_constraint_definition t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 5,'msbf_m2.portfolio_strategy_reason_definition',t.module1_run_id::text||'|'||t.reason_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_reason_definition t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 6,'msbf_m2.portfolio_strategy_application_source_snapshot',t.module1_run_id::text||'|'||t.scenario_id::text||'|'||t.merchant_application_id,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_application_source_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 7,'msbf_m2.portfolio_strategy_candidate_source_snapshot',t.module1_run_id::text||'|'||t.scenario_id::text||'|'||t.merchant_application_id||'|'||t.candidate_template_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_candidate_source_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 8,'msbf_m2.portfolio_strategy_account_source_snapshot',t.module1_run_id::text||'|'||t.scenario_id::text||'|'||t.merchant_application_id,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_account_source_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 9,'msbf_m2.portfolio_strategy_kpi_source_snapshot',t.module1_run_id::text||'|'||t.scope_code||'|'||t.kpi_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_kpi_source_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 10,'msbf_m2.portfolio_strategy_queue_source_snapshot',t.module1_run_id::text||'|'||t.servicing_queue_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_queue_source_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 11,'msbf_m2.application_strategy_candidate_evaluation',t.module1_run_id::text||'|'||t.scenario_id::text||'|'||t.merchant_application_id||'|'||t.candidate_template_code||'|'||t.strategy_profile_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.application_strategy_candidate_evaluation t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 12,'msbf_m2.application_portfolio_strategy_simulation',t.module1_run_id::text||'|'||t.scenario_id::text||'|'||t.merchant_application_id||'|'||t.strategy_profile_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.application_portfolio_strategy_simulation t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 13,'msbf_m2.account_servicing_strategy_simulation',t.module1_run_id::text||'|'||t.scenario_id::text||'|'||t.merchant_application_id||'|'||t.strategy_profile_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.account_servicing_strategy_simulation t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 14,'msbf_m2.portfolio_strategy_summary',t.module1_run_id::text||'|'||t.strategy_profile_code||'|'||t.reporting_scope_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_summary t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 15,'msbf_m2.portfolio_strategy_frontier',t.module1_run_id::text||'|'||t.strategy_profile_code||'|'||t.reporting_scope_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_frontier t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 16,'msbf_m2.portfolio_strategy_comparison',t.module1_run_id::text||'|'||t.challenger_strategy_profile_code||'|'||t.reporting_scope_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_comparison t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 17,'msbf_m2.portfolio_strategy_simulation_latest',t.module1_run_id::text||'|'||t.strategy_profile_code||'|'||t.reporting_scope_code,msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'contract_row_hash'-'created_at') FROM msbf_m2.portfolio_strategy_simulation_latest t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 18,'msbf_m2.portfolio_strategy_simulation_archive',t.module1_run_id::text||'|'||t.contract_version::text||'|'||t.strategy_profile_code||'|'||t.reporting_scope_code,msbf_ctl.m2_11_hash_jsonb(jsonb_build_object('module1_run_id',t.module1_run_id,'contract_code',t.contract_code,'contract_version',t.contract_version,'strategy_profile_code',t.strategy_profile_code,'reporting_scope_code',t.reporting_scope_code,'contract_payload',t.contract_payload,'source_latest_row_hash',t.contract_row_hash)) FROM msbf_m2.portfolio_strategy_simulation_archive t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 19,'msbf_ctl.m2_11_portfolio_strategy_contract_registry',t.module1_run_id::text||'|'||t.contract_version::text,msbf_ctl.m2_11_registry_row_hash(to_jsonb(t)) FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context);
$function$;

/* --------------------------------------------------------------------------
Canonical rollback fingerprint. Each family hash is reconstructed from physical
immutable fields using the governed target-typed hash preimage and frozen
business-key ordering. It therefore detects a surviving field mutation even if
the stored row-hash column itself was not updated by an injected defect.
--------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION pg_temp.m2_11_canonical_physical_fingerprint()
RETURNS TABLE(object_sequence integer,object_code text,row_count bigint,ordered_set_hash text)
LANGUAGE sql STABLE AS $function$
SELECT 1,'msbf_ctl.m2_11_policy_profile',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(t.configuration_payload),'|' ORDER BY t.module1_run_id)) FROM msbf_ctl.m2_11_policy_profile t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 2,'msbf_m2.portfolio_strategy_profile',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.strategy_profile_code)) FROM msbf_m2.portfolio_strategy_profile t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 3,'msbf_m2.portfolio_strategy_objective_definition',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.objective_code)) FROM msbf_m2.portfolio_strategy_objective_definition t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 4,'msbf_m2.portfolio_strategy_constraint_definition',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.constraint_code)) FROM msbf_m2.portfolio_strategy_constraint_definition t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 5,'msbf_m2.portfolio_strategy_reason_definition',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.reason_code)) FROM msbf_m2.portfolio_strategy_reason_definition t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 6,'msbf_m2.portfolio_strategy_application_source_snapshot',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.scenario_id,t.merchant_application_id)) FROM msbf_m2.portfolio_strategy_application_source_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 7,'msbf_m2.portfolio_strategy_candidate_source_snapshot',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.scenario_id,t.merchant_application_id,t.candidate_template_code)) FROM msbf_m2.portfolio_strategy_candidate_source_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 8,'msbf_m2.portfolio_strategy_account_source_snapshot',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.scenario_id,t.merchant_application_id)) FROM msbf_m2.portfolio_strategy_account_source_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 9,'msbf_m2.portfolio_strategy_kpi_source_snapshot',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.scope_code,t.kpi_code)) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 10,'msbf_m2.portfolio_strategy_queue_source_snapshot',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.servicing_queue_code)) FROM msbf_m2.portfolio_strategy_queue_source_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 11,'msbf_m2.application_strategy_candidate_evaluation',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.scenario_id,t.merchant_application_id,t.candidate_template_code,t.strategy_profile_code)) FROM msbf_m2.application_strategy_candidate_evaluation t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 12,'msbf_m2.application_portfolio_strategy_simulation',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.scenario_id,t.merchant_application_id,t.strategy_profile_code)) FROM msbf_m2.application_portfolio_strategy_simulation t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 13,'msbf_m2.account_servicing_strategy_simulation',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.scenario_id,t.merchant_application_id,t.strategy_profile_code)) FROM msbf_m2.account_servicing_strategy_simulation t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 14,'msbf_m2.portfolio_strategy_summary',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.reporting_scope_code,t.strategy_profile_code)) FROM msbf_m2.portfolio_strategy_summary t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 15,'msbf_m2.portfolio_strategy_frontier',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.reporting_scope_code,t.strategy_profile_code)) FROM msbf_m2.portfolio_strategy_frontier t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 16,'msbf_m2.portfolio_strategy_comparison',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.reporting_scope_code,t.challenger_strategy_profile_code)) FROM msbf_m2.portfolio_strategy_comparison t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 17,'msbf_m2.portfolio_strategy_simulation_latest',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'contract_row_hash'-'created_at'),'|' ORDER BY t.module1_run_id,t.reporting_scope_code,t.strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_latest t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 18,'msbf_m2.portfolio_strategy_simulation_archive',count(*),md5(string_agg(msbf_ctl.m2_11_hash_jsonb(jsonb_build_object('module1_run_id',t.module1_run_id,'contract_code',t.contract_code,'contract_version',t.contract_version,'strategy_profile_code',t.strategy_profile_code,'reporting_scope_code',t.reporting_scope_code,'contract_payload',t.contract_payload,'source_latest_row_hash',t.contract_row_hash)),'|' ORDER BY t.module1_run_id,t.contract_version,t.reporting_scope_code,t.strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_archive t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
UNION ALL SELECT 19,'msbf_ctl.m2_11_portfolio_strategy_contract_registry',count(*),md5(string_agg(msbf_ctl.m2_11_registry_row_hash(to_jsonb(t)),'|' ORDER BY t.module1_run_id,t.contract_version)) FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry t WHERE t.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context);
$function$;

CREATE TEMP TABLE tmp_eval_m2_11_canonical_rows_before ON COMMIT DROP AS
SELECT * FROM pg_temp.m2_11_canonical_physical_rows();
CREATE UNIQUE INDEX tmp_eval_m2_11_canonical_rows_before_u1
ON tmp_eval_m2_11_canonical_rows_before(object_code,business_key);
ANALYZE tmp_eval_m2_11_canonical_rows_before;

CREATE TEMP TABLE tmp_eval_m2_11_canonical_fingerprint_before ON COMMIT DROP AS
SELECT * FROM pg_temp.m2_11_canonical_physical_fingerprint();
CREATE UNIQUE INDEX tmp_eval_m2_11_canonical_fingerprint_before_u1
ON tmp_eval_m2_11_canonical_fingerprint_before(object_sequence,object_code);
ANALYZE tmp_eval_m2_11_canonical_fingerprint_before;

CREATE TEMP TABLE tmp_eval_m2_11_latest_archive_fingerprint_before ON COMMIT DROP AS
SELECT
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_latest WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context))::bigint AS latest_rows,
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_archive WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND contract_version=1)::bigint AS archive_rows,
 (SELECT md5(string_agg(strategy_profile_code||'|'||reporting_scope_code||'|'||contract_version||'|'||contract_row_hash,'|' ORDER BY reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_latest WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)) AS latest_identity_hash,
 (SELECT md5(string_agg(contract_version||'|'||strategy_profile_code||'|'||reporting_scope_code||'|'||contract_row_hash||'|'||archive_row_hash,'|' ORDER BY contract_version,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_archive WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND contract_version=1) AS archive_identity_hash,
 (SELECT row_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND contract_version=1) AS registry_row_hash,
 (SELECT md5(concat_ws('|',
     policy_set_hash,strategy_profile_set_hash,objective_definition_set_hash,
     constraint_definition_set_hash,reason_definition_set_hash,application_source_set_hash,
     candidate_source_set_hash,account_source_set_hash,kpi_source_set_hash,queue_source_set_hash,
     candidate_evaluation_set_hash,application_simulation_set_hash,account_simulation_set_hash,
     strategy_summary_set_hash,frontier_set_hash,comparison_set_hash,latest_set_hash,
     archive_set_hash,contract_set_hash))
  FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND contract_version=1) AS registry_set_hash_vector_hash,
 (SELECT combined_set_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND contract_version=1) AS combined_set_hash;

/* --------------------------------------------------------------------------
Archive identity-sequence fingerprint. Control 016 supplies an explicit identity
value, but the owned sequence is also captured before any negative control so
zero sequence-state movement is affirmative runtime evidence.
--------------------------------------------------------------------------- */
CREATE TEMP TABLE tmp_eval_m2_11_archive_identity_sequence_before
(
 sequence_relation text PRIMARY KEY,
 last_value bigint NOT NULL,
 is_called boolean NOT NULL
) ON COMMIT DROP;

DO $m211_archive_sequence_before$
DECLARE
 v_sequence_relation text;
 v_last_value bigint;
 v_is_called boolean;
BEGIN
 v_sequence_relation := pg_get_serial_sequence(
   'msbf_m2.portfolio_strategy_simulation_archive','archive_id');
 IF v_sequence_relation IS NULL THEN
  RAISE EXCEPTION 'Program 216 could not resolve the archive identity sequence before negative controls';
 END IF;
 EXECUTE format('SELECT last_value::bigint,is_called FROM %s',
                v_sequence_relation::regclass)
 INTO v_last_value,v_is_called;
 INSERT INTO tmp_eval_m2_11_archive_identity_sequence_before
 (sequence_relation,last_value,is_called)
 VALUES(v_sequence_relation,v_last_value,v_is_called);
END;
$m211_archive_sequence_before$;


/* ============================================================================
Section 1 — Twenty isolated negative controls
============================================================================ */
DO $m211_neg_001$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  UPDATE msbf_m2.portfolio_strategy_application_source_snapshot
  SET m1_17_combined_g2_hash='00000000000000000000000000000000'
  WHERE ctid=(SELECT ctid FROM msbf_m2.portfolio_strategy_application_source_snapshot
              WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
              ORDER BY scenario_id,merchant_application_id LIMIT 1);
  PERFORM pg_temp.m2_11_assert_source_identity();
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(1,'M2_11_NEG_001_SOURCE_IDENTITY_TAMPER','Reject accepted-source identity tampering','P0001','M2.11 NEG SOURCE_IDENTITY',v_state,v_message);
END;
$m211_neg_001$;

DO $m211_neg_002$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  WITH q AS
  (
   SELECT ctid,row_number() OVER(ORDER BY scenario_id,merchant_application_id) AS rn
   FROM msbf_m2.portfolio_strategy_application_source_snapshot
   WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
  ), target_row AS (SELECT ctid FROM q WHERE rn=1), source_key AS
  (
   SELECT scenario_id,merchant_application_id
   FROM msbf_m2.portfolio_strategy_application_source_snapshot
   WHERE ctid=(SELECT ctid FROM q WHERE rn=2)
  )
  UPDATE msbf_m2.portfolio_strategy_application_source_snapshot t
  SET scenario_id=s.scenario_id,merchant_application_id=s.merchant_application_id
  FROM target_row x,source_key s WHERE t.ctid=x.ctid;
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(2,'M2_11_NEG_002_SOURCE_GRAIN_DUPLICATE','Reject duplicate source grain','23505','duplicate key value',v_state,v_message);
END;
$m211_neg_002$;

DO $m211_neg_003$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  UPDATE msbf_m2.application_portfolio_strategy_simulation
  SET selected_candidate_template_code='M2_11_NEG_UNACCEPTED',
      selected_candidate_source_row_hash='00000000000000000000000000000000'
  WHERE ctid=(SELECT ctid FROM msbf_m2.application_portfolio_strategy_simulation
              WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
                AND selected_candidate_template_code IS NOT NULL
              ORDER BY scenario_id,merchant_application_id,strategy_profile_code LIMIT 1);
  PERFORM pg_temp.m2_11_assert_selected_candidates();
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(3,'M2_11_NEG_003_UNACCEPTED_CANDIDATE','Reject application selection outside accepted candidate inventory','P0001','M2.11 NEG UNACCEPTED_CANDIDATE',v_state,v_message);
END;
$m211_neg_003$;

DO $m211_neg_004$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  UPDATE msbf_m2.application_portfolio_strategy_simulation
  SET strategy_outcome_code='ACCESS_SELECTED',strategy_outcome_rank=1,access_selected_flag=TRUE
  WHERE ctid=(SELECT ctid FROM msbf_m2.application_portfolio_strategy_simulation
              WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
                AND source_pricing_disposition_code='NO_STRUCTURE_POLICY_DECLINE'
              ORDER BY scenario_id,merchant_application_id,strategy_profile_code LIMIT 1);
  PERFORM pg_temp.m2_11_assert_preserved_outcomes('POLICY');
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(4,'M2_11_NEG_004_POLICY_DECLINE_OVERRIDE','Reject favorable override of policy decline','P0001','M2.11 NEG POLICY_DECLINE_OVERRIDE',v_state,v_message);
END;
$m211_neg_004$;

DO $m211_neg_005$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  UPDATE msbf_m2.application_portfolio_strategy_simulation
  SET strategy_outcome_code='ACCESS_SELECTED',strategy_outcome_rank=1,access_selected_flag=TRUE
  WHERE ctid=(SELECT ctid FROM msbf_m2.application_portfolio_strategy_simulation
              WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
                AND source_pricing_disposition_code='NO_STRUCTURE_INSUFFICIENT_EVIDENCE'
              ORDER BY scenario_id,merchant_application_id,strategy_profile_code LIMIT 1);
  PERFORM pg_temp.m2_11_assert_preserved_outcomes('INSUFFICIENT');
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(5,'M2_11_NEG_005_INSUFFICIENT_OVERRIDE','Reject favorable override of insufficient evidence','P0001','M2.11 NEG INSUFFICIENT_OVERRIDE',v_state,v_message);
END;
$m211_neg_005$;

DO $m211_neg_006$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  UPDATE msbf_m2.application_strategy_candidate_evaluation
  SET hard_constraint_violation_count=1,
      hard_constraint_codes='["M2_11_NEGATIVE_TEST_CONSTRAINT"]'::jsonb
  WHERE ctid=(SELECT ctid FROM msbf_m2.application_strategy_candidate_evaluation
              WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
                AND candidate_selected_flag
              ORDER BY scenario_id,merchant_application_id,strategy_profile_code,candidate_rank LIMIT 1);
  PERFORM pg_temp.m2_11_assert_hard_constraint_selection();
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(6,'M2_11_NEG_006_HARD_CONSTRAINT_BYPASS','Reject favorable selection with hard-constraint violation','P0001','M2.11 NEG HARD_CONSTRAINT_BYPASS',v_state,v_message);
END;
$m211_neg_006$;

DO $m211_neg_007$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  UPDATE msbf_m2.application_strategy_candidate_evaluation
  SET objective_evidence_complete_flag=FALSE
  WHERE ctid=(SELECT ctid FROM msbf_m2.application_strategy_candidate_evaluation
              WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
                AND candidate_selected_flag AND candidate_scoring_applicable_flag
              ORDER BY scenario_id,merchant_application_id,strategy_profile_code,candidate_rank LIMIT 1);
  PERFORM pg_temp.m2_11_assert_objective_evidence();
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(7,'M2_11_NEG_007_MISSING_OBJECTIVE_EVIDENCE','Reject score with missing required objective evidence','P0001','M2.11 NEG MISSING_OBJECTIVE_EVIDENCE',v_state,v_message);
END;
$m211_neg_007$;

DO $m211_neg_008$
DECLARE
 v_state text;
 v_message text;
 v_rows bigint;
 v_physical_valid boolean;
BEGIN
 BEGIN
  UPDATE msbf_m2.portfolio_strategy_profile
  SET access_rate_weight=access_rate_weight+0.010000::numeric(9,6),
      selected_exposure_weight=selected_exposure_weight-0.010000::numeric(9,6)
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND strategy_profile_code='ACCESS_EXPANSION';
  GET DIAGNOSTICS v_rows=ROW_COUNT;
  IF v_rows<>1 THEN
   RAISE EXCEPTION USING ERRCODE='P2198',MESSAGE='M2.11 NEG CONTROL 008 PRECONDITION: expected exactly one ACCESS_EXPANSION row';
  END IF;

  SELECT
    access_rate_weight BETWEEN 0::numeric AND 1::numeric
    AND selected_exposure_weight BETWEEN 0::numeric AND 1::numeric
    AND finance_charge_weight BETWEEN 0::numeric AND 1::numeric
    AND expected_loss_density_weight BETWEEN 0::numeric AND 1::numeric
    AND risk_adjusted_contribution_weight BETWEEN 0::numeric AND 1::numeric
    AND annualized_return_weight BETWEEN 0::numeric AND 1::numeric
    AND servicing_burden_weight BETWEEN 0::numeric AND 1::numeric
    AND payment_burden_weight BETWEEN 0::numeric AND 1::numeric
    AND candidate_domain_weight_total =
        access_rate_weight+selected_exposure_weight+finance_charge_weight+
        expected_loss_density_weight+risk_adjusted_contribution_weight+
        annualized_return_weight+payment_burden_weight
    AND scope_domain_weight_total =
        access_rate_weight+selected_exposure_weight+finance_charge_weight+
        expected_loss_density_weight+risk_adjusted_contribution_weight+
        annualized_return_weight+servicing_burden_weight+payment_burden_weight
    AND candidate_domain_weight_total=1.000000::numeric(9,6)
    AND scope_domain_weight_total=1.000000::numeric(9,6)
  INTO v_physical_valid
  FROM msbf_m2.portfolio_strategy_profile
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND strategy_profile_code='ACCESS_EXPANSION';

  IF NOT coalesce(v_physical_valid,FALSE) THEN
   RAISE EXCEPTION USING ERRCODE='P2198',MESSAGE='M2.11 NEG CONTROL 008 PRECONDITION: balanced mutation violated a physical strategy-profile constraint';
  END IF;

  PERFORM pg_temp.m2_11_assert_weight_matrix();
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(8,'M2_11_NEG_008_WEIGHT_CORRUPTION','Reject strategy weight-matrix corruption','P0001','M2.11 NEG WEIGHT_CORRUPTION',v_state,v_message);
END;
$m211_neg_008$;

DO $m211_neg_009$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  UPDATE msbf_m2.application_strategy_candidate_evaluation
  SET candidate_selected_flag=FALSE
  WHERE ctid=(SELECT ctid FROM msbf_m2.application_strategy_candidate_evaluation
              WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
                AND candidate_selected_flag
              ORDER BY scenario_id,merchant_application_id,strategy_profile_code,candidate_rank LIMIT 1);
  PERFORM pg_temp.m2_11_assert_candidate_selection();
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(9,'M2_11_NEG_009_TIEBREAK_CORRUPTION','Reject deterministic winner/tie corruption','P0001','M2.11 NEG TIEBREAK_CORRUPTION',v_state,v_message);
END;
$m211_neg_009$;

DO $m211_neg_010$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  UPDATE msbf_m2.application_portfolio_strategy_simulation
  SET portfolio_adverse_selected_flag=TRUE
  WHERE ctid=(SELECT ctid FROM msbf_m2.application_portfolio_strategy_simulation
              WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
                AND NOT portfolio_adverse_selected_flag
              ORDER BY merchant_application_id,strategy_profile_code,scenario_code LIMIT 1);
  PERFORM pg_temp.m2_11_assert_portfolio_application_grain();
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(10,'M2_11_NEG_010_PORTFOLIO_DOUBLE_COUNT','Reject PORTFOLIO application double counting','P0001','M2.11 NEG PORTFOLIO_DOUBLE_COUNT',v_state,v_message);
END;
$m211_neg_010$;

DO $m211_neg_011$
DECLARE
 v_state text;
 v_message text;
 v_application_id text;
 v_updated_rows bigint;
 v_mutated_pair_rows bigint;
BEGIN
 BEGIN
  /* Select one deterministic matched source pair without depending on whether
     either accepted risk value is NULL. The superseded injection selected the
     first stress row and calculated baseline - 1; a NULL baseline therefore
     remained NULL and could not trigger the governed comparison. */
  SELECT min(b.merchant_application_id)
  INTO v_application_id
  FROM msbf_m2.portfolio_strategy_application_source_snapshot b
  JOIN msbf_m2.portfolio_strategy_application_source_snapshot s
    ON s.module1_run_id=b.module1_run_id
   AND s.merchant_application_id=b.merchant_application_id
   AND s.scenario_code='RECESSION_ENERGY'
  WHERE b.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND b.scenario_code='BASELINE';

  IF v_application_id IS NULL THEN
   RAISE EXCEPTION USING
    ERRCODE='P2161',
    MESSAGE='M2.11 NEG 011 PRECONDITION: no matched BASELINE/RECESSION_ENERGY application source pair';
  END IF;

  /* Force a target-typed favorable stress relation that is independent of the
     accepted pair's original values: stress 0.000000 is below baseline 1.000000
     by substantially more than the 0.00000001 tolerance. Both mutations remain
     inside this exception subtransaction and must roll back. */
  UPDATE msbf_m2.portfolio_strategy_application_source_snapshot
  SET integrated_risk_score =
      CASE scenario_code
       WHEN 'BASELINE' THEN 1.000000::numeric(12,6)
       WHEN 'RECESSION_ENERGY' THEN 0.000000::numeric(12,6)
      END
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND merchant_application_id=v_application_id
    AND scenario_code IN ('BASELINE','RECESSION_ENERGY');
  GET DIAGNOSTICS v_updated_rows=ROW_COUNT;

  SELECT count(*)
  INTO v_mutated_pair_rows
  FROM msbf_m2.portfolio_strategy_application_source_snapshot
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND merchant_application_id=v_application_id
    AND
    (
      (scenario_code='BASELINE' AND integrated_risk_score=1.000000::numeric(12,6))
      OR
      (scenario_code='RECESSION_ENERGY' AND integrated_risk_score=0.000000::numeric(12,6))
    );

  IF v_updated_rows<>2 OR v_mutated_pair_rows<>2 THEN
   RAISE EXCEPTION USING
    ERRCODE='P2161',
    MESSAGE=format(
      'M2.11 NEG 011 PRECONDITION: expected exactly two target-typed matched rows; updated %s, verified %s',
      v_updated_rows,
      v_mutated_pair_rows
    );
  END IF;

  PERFORM pg_temp.m2_11_assert_source_stress();
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(11,'M2_11_NEG_011_FAVORABLE_SOURCE_STRESS','Reject favorable accepted source movement under stress','P0001','M2.11 NEG FAVORABLE_SOURCE_STRESS',v_state,v_message);
END;
$m211_neg_011$;

DO $m211_neg_012$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  UPDATE msbf_m2.application_portfolio_strategy_simulation
  SET strategy_outcome_rank=0
  WHERE ctid=(SELECT ctid FROM msbf_m2.application_portfolio_strategy_simulation
              WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
                AND scenario_code='RECESSION_ENERGY'
              ORDER BY merchant_application_id,strategy_profile_code LIMIT 1);
  PERFORM pg_temp.m2_11_assert_strategy_stress();
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(12,'M2_11_NEG_012_FAVORABLE_STRATEGY_STRESS','Reject favorable strategy access/feasibility under stress','P0001','M2.11 NEG FAVORABLE_STRATEGY_STRESS',v_state,v_message);
END;
$m211_neg_012$;

DO $m211_neg_013$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  UPDATE msbf_m2.portfolio_strategy_simulation_archive
  SET contract_payload=contract_payload||jsonb_build_object('m2_11_negative_test',TRUE)
  WHERE archive_id=(SELECT archive_id FROM msbf_m2.portfolio_strategy_simulation_archive
                    WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
                    ORDER BY archive_id LIMIT 1);
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(13,'M2_11_NEG_013_ARCHIVE_UPDATE','Reject immutable archive update','P0001','M2.11 immutable archive rejects',v_state,v_message);
END;
$m211_neg_013$;

DO $m211_neg_014$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  DELETE FROM msbf_m2.portfolio_strategy_simulation_archive
  WHERE archive_id=(SELECT archive_id FROM msbf_m2.portfolio_strategy_simulation_archive
                    WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
                    ORDER BY archive_id LIMIT 1);
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(14,'M2_11_NEG_014_ARCHIVE_DELETE','Reject immutable archive delete','P0001','M2.11 immutable archive rejects',v_state,v_message);
END;
$m211_neg_014$;

DO $m211_neg_015$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  UPDATE msbf_m2.portfolio_strategy_simulation_latest
  SET contract_row_hash='00000000000000000000000000000000'
  WHERE ctid=(SELECT ctid FROM msbf_m2.portfolio_strategy_simulation_latest
              WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
              ORDER BY reporting_scope_code,strategy_profile_code LIMIT 1);
  PERFORM pg_temp.m2_11_assert_latest_archive();
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(15,'M2_11_NEG_015_LATEST_ARCHIVE_MISMATCH','Reject latest/archive divergence','P0001','M2.11 NEG LATEST_ARCHIVE_MISMATCH',v_state,v_message);
END;
$m211_neg_015$;

DO $m211_neg_016$
DECLARE
 v_state text;
 v_message text;
 v_test_archive_id bigint := -216016000001::bigint;
 v_source_rows bigint;
BEGIN
 BEGIN
  IF EXISTS
  (
   SELECT 1
   FROM msbf_m2.portfolio_strategy_simulation_archive
   WHERE archive_id=v_test_archive_id
  ) THEN
   RAISE EXCEPTION USING ERRCODE='P2198',
     MESSAGE='M2.11 NEG CONTROL 016 PRECONDITION: explicit archive_id is already used';
  END IF;

  SELECT count(*) INTO v_source_rows
  FROM
  (
   SELECT 1
   FROM msbf_m2.portfolio_strategy_simulation_archive
   WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
     AND contract_version=1
   ORDER BY reporting_scope_code,strategy_profile_code
   LIMIT 1
  ) q;
  IF v_source_rows<>1 THEN
   RAISE EXCEPTION USING ERRCODE='P2198',
     MESSAGE='M2.11 NEG CONTROL 016 PRECONDITION: expected exactly one source archive row';
  END IF;

  INSERT INTO msbf_m2.portfolio_strategy_simulation_archive
  (archive_id,module1_run_id,contract_code,contract_version,schema_version,methodology_version,
   strategy_profile_code,reporting_scope_code,contract_payload,contract_row_hash,archive_row_hash)
  OVERRIDING SYSTEM VALUE
  SELECT v_test_archive_id,module1_run_id,contract_code,contract_version,schema_version,methodology_version,
         strategy_profile_code,reporting_scope_code,contract_payload,contract_row_hash,archive_row_hash
  FROM msbf_m2.portfolio_strategy_simulation_archive
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)
    AND contract_version=1
  ORDER BY reporting_scope_code,strategy_profile_code
  LIMIT 1;
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(16,'M2_11_NEG_016_CONTRACT_V1_RERUN','Reject committed contract-version-1 rerun','23505','duplicate key value',v_state,v_message);
END;
$m211_neg_016$;

DO $m211_neg_017$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  INSERT INTO msbf_m2.portfolio_strategy_reason_definition
  (module1_run_id,reason_code,reason_sequence,reason_family,severity_code,severity_rank,
   applicability_code,description,production_action_flag,external_system_update_flag,
   merchant_contact_flag,production_adverse_action_flag,row_hash)
  VALUES((SELECT run_id FROM tmp_eval_m2_11_negative_context),'M2_11_NEG_REASON_PRODUCTION',99,
   'NEGATIVE_TEST','SYSTEM_BLOCK',4,'ALL','Rollback-safe production-action test',TRUE,FALSE,FALSE,FALSE,
   '00000000000000000000000000000000');
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(17,'M2_11_NEG_017_PRODUCTION_ACTION','Reject production-action reason flag','23514','new row for relation',v_state,v_message);
END;
$m211_neg_017$;

DO $m211_neg_018$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  INSERT INTO msbf_m2.portfolio_strategy_reason_definition
  (module1_run_id,reason_code,reason_sequence,reason_family,severity_code,severity_rank,
   applicability_code,description,production_action_flag,external_system_update_flag,
   merchant_contact_flag,production_adverse_action_flag,row_hash)
  VALUES((SELECT run_id FROM tmp_eval_m2_11_negative_context),'M2_11_NEG_REASON_EXTERNAL',100,
   'NEGATIVE_TEST','SYSTEM_BLOCK',4,'ALL','Rollback-safe external-behavior test',FALSE,TRUE,FALSE,FALSE,
   '00000000000000000000000000000000');
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(18,'M2_11_NEG_018_EXTERNAL_BEHAVIOR','Reject external-system boundary violation','23514','new row for relation',v_state,v_message);
END;
$m211_neg_018$;

DO $m211_neg_019$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  INSERT INTO msbf_m2.portfolio_strategy_reason_definition
  (module1_run_id,reason_code,reason_sequence,reason_family,severity_code,severity_rank,
   applicability_code,description,production_action_flag,external_system_update_flag,
   merchant_contact_flag,production_adverse_action_flag,row_hash)
  VALUES((SELECT run_id FROM tmp_eval_m2_11_negative_context),'M2_11_NEG_REASON_COUNT',101,
   'NEGATIVE_TEST','INFO',1,'ALL','Rollback-safe canonical-count test',FALSE,FALSE,FALSE,FALSE,
   '00000000000000000000000000000000');
  PERFORM pg_temp.m2_11_assert_canonical_identity();
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(19,'M2_11_NEG_019_CANONICAL_COUNT','Reject canonical entity-count mismatch','P0001','M2.11 NEG CANONICAL_COUNT',v_state,v_message);
END;
$m211_neg_019$;

DO $m211_neg_020$
DECLARE
 v_state text;
 v_message text;
BEGIN
 BEGIN
  PERFORM pg_temp.m2_11_assert_authorized_wp3_target
   ('READ_VALIDATION_SOURCE','msbf_m2.application_portfolio_performance_archive');
  RAISE EXCEPTION USING ERRCODE='P2199',MESSAGE='M2.11 NEG TEST DID NOT REJECT';
 EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_state=RETURNED_SQLSTATE,v_message=MESSAGE_TEXT;
 END;
 PERFORM pg_temp.m2_11_record_negative(20,'M2_11_NEG_020_UNAUTHORIZED_STAGE_SOURCE','Reject unauthorized source family or WP3 business mutation','P0001','M2.11 NEG UNAUTHORIZED_STAGE_SOURCE',v_state,v_message);
END;
$m211_neg_020$;

/* --------------------------------------------------------------------------
Capture the archive identity sequence after Control 020 and before any negative
evidence write. The sequence relation, last_value, and is_called state must
exactly equal the pre-suite fingerprint.
--------------------------------------------------------------------------- */
CREATE TEMP TABLE tmp_eval_m2_11_archive_identity_sequence_after
(
 sequence_relation text PRIMARY KEY,
 last_value bigint NOT NULL,
 is_called boolean NOT NULL
) ON COMMIT DROP;

DO $m211_archive_sequence_after$
DECLARE
 v_sequence_relation text;
 v_last_value bigint;
 v_is_called boolean;
BEGIN
 v_sequence_relation := pg_get_serial_sequence(
   'msbf_m2.portfolio_strategy_simulation_archive','archive_id');
 IF v_sequence_relation IS NULL THEN
  RAISE EXCEPTION 'Program 216 could not resolve the archive identity sequence after negative controls';
 END IF;
 EXECUTE format('SELECT last_value::bigint,is_called FROM %s',
                v_sequence_relation::regclass)
 INTO v_last_value,v_is_called;
 INSERT INTO tmp_eval_m2_11_archive_identity_sequence_after
 (sequence_relation,last_value,is_called)
 VALUES(v_sequence_relation,v_last_value,v_is_called);
END;
$m211_archive_sequence_after$;

/* --------------------------------------------------------------------------
Post-control rollback reconciliation. This occurs before any negative evidence
is inserted. The expected result is zero changed families, entities, ordered
physical hashes, latest/archive identities, archive identity-sequence state,
registry row hash, all nineteen stored registry set hashes, or combined hash.
--------------------------------------------------------------------------- */
CREATE TEMP TABLE tmp_eval_m2_11_canonical_rows_after ON COMMIT DROP AS
SELECT * FROM pg_temp.m2_11_canonical_physical_rows();
CREATE UNIQUE INDEX tmp_eval_m2_11_canonical_rows_after_u1
ON tmp_eval_m2_11_canonical_rows_after(object_code,business_key);
ANALYZE tmp_eval_m2_11_canonical_rows_after;

CREATE TEMP TABLE tmp_eval_m2_11_canonical_fingerprint_after ON COMMIT DROP AS
SELECT * FROM pg_temp.m2_11_canonical_physical_fingerprint();
CREATE UNIQUE INDEX tmp_eval_m2_11_canonical_fingerprint_after_u1
ON tmp_eval_m2_11_canonical_fingerprint_after(object_sequence,object_code);
ANALYZE tmp_eval_m2_11_canonical_fingerprint_after;

CREATE TEMP TABLE tmp_eval_m2_11_latest_archive_fingerprint_after ON COMMIT DROP AS
SELECT
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_latest WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context))::bigint AS latest_rows,
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_archive WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND contract_version=1)::bigint AS archive_rows,
 (SELECT md5(string_agg(strategy_profile_code||'|'||reporting_scope_code||'|'||contract_version||'|'||contract_row_hash,'|' ORDER BY reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_latest WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context)) AS latest_identity_hash,
 (SELECT md5(string_agg(contract_version||'|'||strategy_profile_code||'|'||reporting_scope_code||'|'||contract_row_hash||'|'||archive_row_hash,'|' ORDER BY contract_version,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_archive WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND contract_version=1) AS archive_identity_hash,
 (SELECT row_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND contract_version=1) AS registry_row_hash,
 (SELECT md5(concat_ws('|',
     policy_set_hash,strategy_profile_set_hash,objective_definition_set_hash,
     constraint_definition_set_hash,reason_definition_set_hash,application_source_set_hash,
     candidate_source_set_hash,account_source_set_hash,kpi_source_set_hash,queue_source_set_hash,
     candidate_evaluation_set_hash,application_simulation_set_hash,account_simulation_set_hash,
     strategy_summary_set_hash,frontier_set_hash,comparison_set_hash,latest_set_hash,
     archive_set_hash,contract_set_hash))
  FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND contract_version=1) AS registry_set_hash_vector_hash,
 (SELECT combined_set_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND contract_version=1) AS combined_set_hash;

CREATE TEMP TABLE tmp_eval_m2_11_negative_postflight ON COMMIT DROP AS
SELECT
 (SELECT count(*) FROM tmp_eval_m2_11_canonical_fingerprint_before b
   FULL JOIN tmp_eval_m2_11_canonical_fingerprint_after a USING(object_sequence,object_code)
   WHERE b.object_sequence IS NULL OR a.object_sequence IS NULL
      OR b.row_count IS DISTINCT FROM a.row_count
      OR b.ordered_set_hash IS DISTINCT FROM a.ordered_set_hash)::bigint AS changed_canonical_families,
 (SELECT count(*)
  FROM tmp_eval_m2_11_canonical_rows_before b
  FULL JOIN tmp_eval_m2_11_canonical_rows_after a USING(object_code,business_key)
  WHERE b.object_code IS NULL OR a.object_code IS NULL
     OR b.physical_row_hash IS DISTINCT FROM a.physical_row_hash)::bigint AS changed_canonical_entities,
 (SELECT count(*) FROM tmp_eval_m2_11_canonical_fingerprint_before b
   FULL JOIN tmp_eval_m2_11_canonical_fingerprint_after a USING(object_sequence,object_code)
   WHERE b.object_sequence IS NULL OR a.object_sequence IS NULL
      OR b.ordered_set_hash IS DISTINCT FROM a.ordered_set_hash)::bigint AS changed_ordered_set_hashes,
 (SELECT count(*) FROM tmp_eval_m2_11_latest_archive_fingerprint_before b
   CROSS JOIN tmp_eval_m2_11_latest_archive_fingerprint_after a
   WHERE (b.latest_rows,b.archive_rows,b.latest_identity_hash,b.archive_identity_hash)
      IS DISTINCT FROM
         (a.latest_rows,a.archive_rows,a.latest_identity_hash,a.archive_identity_hash))::bigint AS changed_latest_archive_rows,
 (SELECT count(*) FROM tmp_eval_m2_11_latest_archive_fingerprint_before b
   CROSS JOIN tmp_eval_m2_11_latest_archive_fingerprint_after a
   WHERE (b.registry_row_hash,b.registry_set_hash_vector_hash,b.combined_set_hash)
      IS DISTINCT FROM (a.registry_row_hash,a.registry_set_hash_vector_hash,a.combined_set_hash))::bigint AS changed_registry_identities,
 (SELECT count(*)
  FROM tmp_eval_m2_11_archive_identity_sequence_before b
  FULL JOIN tmp_eval_m2_11_archive_identity_sequence_after a USING(sequence_relation)
  WHERE b.sequence_relation IS NULL OR a.sequence_relation IS NULL
     OR b.last_value IS DISTINCT FROM a.last_value
     OR b.is_called IS DISTINCT FROM a.is_called)::bigint AS changed_archive_identity_sequence;


/* ============================================================================
Section 2 — Persist evidence only after 20/20 expected rejections
============================================================================ */
DO $m211_negative_finalize$
DECLARE
 v_total bigint;
 v_pass bigint;
 v_fail bigint;
 v_failed text;
 v_rows bigint;
BEGIN
 SELECT count(*),count(*) FILTER(WHERE status='PASS'),count(*) FILTER(WHERE status='FAIL'),
        string_agg(evidence_code||'[state='||coalesce(observed_sqlstate,'<NULL>')||
          '; message='||coalesce(observed_message,'<NULL>')||']','; ' ORDER BY control_sequence)
          FILTER(WHERE status='FAIL')
 INTO v_total,v_pass,v_fail,v_failed FROM tmp_eval_m2_11_negative_control;
 IF v_total<>20 OR (SELECT count(DISTINCT evidence_code) FROM tmp_eval_m2_11_negative_control)<>20
    OR (SELECT min(control_sequence) FROM tmp_eval_m2_11_negative_control)<>1
    OR (SELECT max(control_sequence) FROM tmp_eval_m2_11_negative_control)<>20 THEN
  RAISE EXCEPTION 'Program 216 negative-control inventory mismatch: total %, unique %, range %..%',
   v_total,(SELECT count(DISTINCT evidence_code) FROM tmp_eval_m2_11_negative_control),
   (SELECT min(control_sequence) FROM tmp_eval_m2_11_negative_control),(SELECT max(control_sequence) FROM tmp_eval_m2_11_negative_control);
 END IF;
 IF v_pass<>20 OR v_fail<>0 THEN
  RAISE EXCEPTION 'Program 216 negative controls failed: pass %, fail %. Details: %',v_pass,v_fail,coalesce(v_failed,'<NONE>');
 END IF;

 IF (SELECT count(*) FROM tmp_eval_m2_11_canonical_fingerprint_before)<>19
    OR (SELECT count(*) FROM tmp_eval_m2_11_canonical_fingerprint_after)<>19
    OR (SELECT count(*) FROM tmp_eval_m2_11_canonical_rows_before)<>19298
    OR (SELECT count(*) FROM tmp_eval_m2_11_canonical_rows_after)<>19298
    OR (SELECT coalesce(sum(row_count),0) FROM tmp_eval_m2_11_canonical_fingerprint_before)<>19298
    OR (SELECT coalesce(sum(row_count),0) FROM tmp_eval_m2_11_canonical_fingerprint_after)<>19298
    OR (SELECT count(*) FROM tmp_eval_m2_11_archive_identity_sequence_before)<>1
    OR (SELECT count(*) FROM tmp_eval_m2_11_archive_identity_sequence_after)<>1 THEN
  RAISE EXCEPTION 'Program 216 rollback fingerprint requires 19 families, 19,298 entities, and one archive identity-sequence state before and after';
 END IF;
 IF EXISTS
 (
  SELECT 1 FROM tmp_eval_m2_11_negative_postflight
  WHERE changed_canonical_families<>0 OR changed_canonical_entities<>0
     OR changed_ordered_set_hashes<>0 OR changed_latest_archive_rows<>0
     OR changed_registry_identities<>0 OR changed_archive_identity_sequence<>0
 ) THEN
  RAISE EXCEPTION 'Program 216 rollback postflight failed: changed families %, entities %, hashes %, latest/archive %, registry %, archive sequence %',
   (SELECT changed_canonical_families FROM tmp_eval_m2_11_negative_postflight),
   (SELECT changed_canonical_entities FROM tmp_eval_m2_11_negative_postflight),
   (SELECT changed_ordered_set_hashes FROM tmp_eval_m2_11_negative_postflight),
   (SELECT changed_latest_archive_rows FROM tmp_eval_m2_11_negative_postflight),
   (SELECT changed_registry_identities FROM tmp_eval_m2_11_negative_postflight),
   (SELECT changed_archive_identity_sequence FROM tmp_eval_m2_11_negative_postflight);
 END IF;

 INSERT INTO msbf_ctl.run_evidence
 (run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,
  unit_code,status,interpretation)
 SELECT (SELECT run_id FROM tmp_eval_m2_11_negative_context),evidence_code,'PORTFOLIO',control_title,
        NULL::numeric(24,10),observed_sqlstate||'|'||observed_message,
        'NEGATIVE_CONTROL',status,
        interpretation||' Expected SQLSTATE '||expected_sqlstate||
        ' and message prefix "'||expected_message_prefix||'".'
 FROM tmp_eval_m2_11_negative_control ORDER BY control_sequence;
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>20 THEN RAISE EXCEPTION 'Program 216 evidence insert expected 20 rows; inserted %',v_rows; END IF;

 IF (SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context))<>'M2_11_VALIDATED'
    OR (SELECT contract_status FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
        WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND contract_version=1)<>'VALIDATED' THEN
  RAISE EXCEPTION 'Program 216 unexpectedly changed validation lifecycle';
 END IF;
 IF (SELECT row_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
     WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_negative_context) AND contract_version=1)
    IS DISTINCT FROM (SELECT registry_row_hash FROM tmp_eval_m2_11_negative_context) THEN
  RAISE EXCEPTION 'Program 216 unexpectedly changed immutable registry identity';
 END IF;
END;
$m211_negative_finalize$;

COMMIT;

SELECT control_sequence,evidence_code,control_title,expected_sqlstate,
       expected_message_prefix,observed_sqlstate,observed_message,status,interpretation
FROM tmp_eval_m2_11_negative_control ORDER BY control_sequence;
