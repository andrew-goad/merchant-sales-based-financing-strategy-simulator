/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.11 — Portfolio Optimization & Strategy Simulation

Program     : 215_msbf_m2_11_positive_validation_v1.sql
Version     : v1
Revision    : WP3_VALIDATION_CORRECTION_R1
Work package: M2.11 Work Package 3

Purpose
-------
Execute exactly 120 substantive positive controls against the fixed Programs
212–214 generated-state baseline. Reconstruct source identities, target-typed
physical hashes, complete five-family source-snapshot payloads, candidate
scores and deterministic winners, application and account adversity, scope
aggregates, Pareto ranks, governance priorities,
latest/archive reproduction, nineteen ordered set hashes, and the 19,298-row
canonical identity without regenerating Program 214 business rows.

Mutation boundary
-----------------
Before all 120 controls reconcile, this program creates temporary validation
objects only. After 120/120 PASS, it inserts M2_11_POS evidence and updates only
mutable run/contract validation lifecycle fields. It never updates any M2.11
canonical business row, latest business value, or archive value.

Required starting state
-----------------------
run_status      = M2_11_GENERATED
contract_status = GENERATED
M2_11_POS rows  = 0
M2_11_NEG rows  = 0

Required ending state
---------------------
120 / 120 PASS
run_status      = M2_11_VALIDATED
contract_status = VALIDATED

Execution
---------
Execute as one SQL script. Stop on the first error. Do not execute Program 216
until this program commits successfully. This source is statically built and
has not been executed by the build environment.
============================================================================ */

BEGIN;
SET LOCAL work_mem='256MB';
SET LOCAL statement_timeout='90min';
SET LOCAL lock_timeout='15s';
SET LOCAL jit=off;

DROP TABLE IF EXISTS tmp_eval_m2_11_positive_control;
CREATE TEMP TABLE tmp_eval_m2_11_positive_control
(
    control_sequence integer PRIMARY KEY,
    evidence_code text NOT NULL UNIQUE,
    control_family text NOT NULL,
    metric_name text NOT NULL,
    observed_value text,
    threshold_value text NOT NULL,
    status text NOT NULL CHECK(status IN ('PASS','FAIL')),
    interpretation text NOT NULL,
    freeze_trace text NOT NULL
) ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS tmp_eval_m2_11_validation_context;
CREATE TEMP TABLE tmp_eval_m2_11_validation_context ON COMMIT DROP AS
SELECT
    r.run_id,
    r.run_code,
    r.run_version,
    r.run_status,
    r.as_of_date,
    c.registry_id,
    c.contract_status,
    c.contract_version,
    c.generated_at,
    c.validated_at,
    c.combined_set_hash,
    c.row_hash AS registry_row_hash
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry c
  ON c.module1_run_id=r.run_id AND c.contract_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
  AND r.run_version=1;

DO $m211_validation_context$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows FROM tmp_eval_m2_11_validation_context;
    IF v_rows<>1 THEN
        RAISE EXCEPTION 'Program 215 requires exactly one M2.11 generated context; found %',v_rows;
    END IF;
    IF (SELECT run_status FROM tmp_eval_m2_11_validation_context)<>'M2_11_GENERATED'
       OR (SELECT contract_status FROM tmp_eval_m2_11_validation_context)<>'GENERATED' THEN
        RAISE EXCEPTION 'Program 215 requires M2_11_GENERATED/GENERATED; found %/%',
          (SELECT run_status FROM tmp_eval_m2_11_validation_context),
          (SELECT contract_status FROM tmp_eval_m2_11_validation_context);
    END IF;
    IF EXISTS
    (
      SELECT 1 FROM msbf_ctl.run_evidence
      WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
        AND (evidence_code LIKE 'M2_11_POS_%' OR evidence_code LIKE 'M2_11_NEG_%'
             OR evidence_code='M2_11_ACCEPTANCE_SUMMARY')
    ) THEN
      RAISE EXCEPTION 'Program 215 requires pristine M2.11 validation evidence state';
    END IF;
    IF EXISTS
    (
      SELECT 1 FROM msbf_ctl.acceptance_gate_result
      WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
        AND gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
    ) THEN
      RAISE EXCEPTION 'Program 215 found premature M2.11 acceptance-gate evidence';
    END IF;
END;
$m211_validation_context$;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_add_positive
(
    p_sequence integer,
    p_code text,
    p_family text,
    p_metric text,
    p_observed text,
    p_threshold text,
    p_pass boolean,
    p_interpretation text,
    p_freeze_trace text
)
RETURNS void
LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO tmp_eval_m2_11_positive_control
    (
      control_sequence,evidence_code,control_family,metric_name,
      observed_value,threshold_value,status,interpretation,freeze_trace
    )
    VALUES
    (
      p_sequence,p_code,p_family,p_metric,p_observed,p_threshold,
      CASE WHEN coalesce(p_pass,FALSE) THEN 'PASS' ELSE 'FAIL' END,
      p_interpretation,p_freeze_trace
    );
END;
$function$;

/* ============================================================================
Section 1 — Independent frozen-definition expectations
============================================================================ */
CREATE TEMP TABLE tmp_eval_expected_strategy
(
  strategy_profile_code text PRIMARY KEY,
  strategy_sequence smallint NOT NULL,
  selection_mode text NOT NULL,
  selected_exposure_direction text NOT NULL,
  access_rate_weight numeric(9,6) NOT NULL,
  selected_exposure_weight numeric(9,6) NOT NULL,
  finance_charge_weight numeric(9,6) NOT NULL,
  expected_loss_density_weight numeric(9,6) NOT NULL,
  risk_adjusted_contribution_weight numeric(9,6) NOT NULL,
  annualized_return_weight numeric(9,6) NOT NULL,
  servicing_burden_weight numeric(9,6) NOT NULL,
  payment_burden_weight numeric(9,6) NOT NULL,
  candidate_domain_weight_total numeric(9,6) NOT NULL,
  scope_domain_weight_total numeric(9,6) NOT NULL,
  candidate_scoring_applicable_flag boolean NOT NULL,
  scope_scoring_applicable_flag boolean NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_eval_expected_strategy
(
 strategy_profile_code,strategy_sequence,selection_mode,selected_exposure_direction,
 access_rate_weight,selected_exposure_weight,finance_charge_weight,
 expected_loss_density_weight,risk_adjusted_contribution_weight,annualized_return_weight,
 servicing_burden_weight,payment_burden_weight,candidate_domain_weight_total,
 scope_domain_weight_total,candidate_scoring_applicable_flag,scope_scoring_applicable_flag
)
VALUES
('BASELINE_REPLAY',1,'SOURCE_REPLAY','NOT_APPLICABLE',0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,FALSE,FALSE),
('ACCESS_EXPANSION',2,'WEIGHTED_CANDIDATE','MAXIMIZE',0.450000,0.150000,0.050000,0.100000,0.100000,0.050000,0.000000,0.100000,1.000000,1.000000,TRUE,TRUE),
('PRICE_FOR_RISK',3,'WEIGHTED_CANDIDATE','MAXIMIZE',0.100000,0.050000,0.300000,0.150000,0.200000,0.100000,0.000000,0.100000,1.000000,1.000000,TRUE,TRUE),
('PAYMENT_BURDEN_RELIEF',4,'WEIGHTED_CANDIDATE','MINIMIZE',0.150000,0.100000,0.050000,0.100000,0.100000,0.050000,0.000000,0.450000,1.000000,1.000000,TRUE,TRUE),
('LOSS_CONTAINMENT',5,'WEIGHTED_CANDIDATE','MINIMIZE',0.050000,0.250000,0.000000,0.400000,0.100000,0.050000,0.000000,0.150000,1.000000,1.000000,TRUE,TRUE),
('PROFITABILITY_DISCIPLINE',6,'WEIGHTED_CANDIDATE','MAXIMIZE',0.050000,0.050000,0.150000,0.150000,0.350000,0.200000,0.000000,0.050000,1.000000,1.000000,TRUE,TRUE),
('EARLY_INTERVENTION',7,'RULE_BASED_ACCOUNT','NOT_APPLICABLE',0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.600000,0.400000,0.000000,1.000000,FALSE,TRUE),
('BALANCED_FRONTIER',8,'WEIGHTED_CANDIDATE','MAXIMIZE',0.200000,0.050000,0.100000,0.200000,0.200000,0.100000,0.100000,0.050000,0.900000,1.000000,TRUE,TRUE);

CREATE TEMP TABLE tmp_eval_expected_objective
(
 objective_code text PRIMARY KEY, objective_sequence smallint NOT NULL,
 default_direction_code text NOT NULL, scoring_domain_code text NOT NULL,
 scope_aggregation_method_code text NOT NULL, pareto_inclusion_flag boolean NOT NULL,
 equality_tolerance numeric(28,10) NOT NULL
) ON COMMIT DROP;
INSERT INTO tmp_eval_expected_objective
(objective_code,objective_sequence,default_direction_code,scoring_domain_code,scope_aggregation_method_code,pareto_inclusion_flag,equality_tolerance)
VALUES
('ACCESS_RATE',1,'MAXIMIZE','CANDIDATE_AND_SCOPE','RATIO_ALL_APPLICATIONS',TRUE,0.0000000100),
('SELECTED_EXPOSURE_AMOUNT',2,'STRATEGY_SPECIFIC','CANDIDATE_AND_SCOPE','SUM',FALSE,0.0100000000),
('FINANCE_CHARGE_AMOUNT',3,'MAXIMIZE','CANDIDATE_AND_SCOPE','SUM',TRUE,0.0100000000),
('EXPECTED_LOSS_DENSITY',4,'MINIMIZE','CANDIDATE_AND_SCOPE','RATIO_SELECTED_EXPOSURE',TRUE,0.0000000100),
('RISK_ADJUSTED_CONTRIBUTION',5,'MAXIMIZE','CANDIDATE_AND_SCOPE','SUM',TRUE,0.0100000000),
('ANNUALIZED_RISK_ADJUSTED_RETURN',6,'MAXIMIZE','CANDIDATE_AND_SCOPE','WEIGHTED_AVERAGE_EXPOSURE',TRUE,0.0000000100),
('SERVICING_BURDEN_UNITS',7,'MINIMIZE','SCOPE_ONLY','SUM_ACCEPTED_OPERATIONAL_ACCOUNTS',TRUE,0.0000010000),
('PAYMENT_BURDEN_RATE',8,'MINIMIZE','CANDIDATE_AND_SCOPE','WEIGHTED_AVERAGE_EXPOSURE',TRUE,0.0000000100);

CREATE TEMP TABLE tmp_eval_expected_constraint
(
 constraint_code text PRIMARY KEY,constraint_sequence smallint NOT NULL,
 constraint_family_code text NOT NULL,applicability_code text NOT NULL,
 severity_code text NOT NULL,evaluation_rule_code text NOT NULL
) ON COMMIT DROP;
INSERT INTO tmp_eval_expected_constraint
(constraint_code,constraint_sequence,constraint_family_code,applicability_code,severity_code,evaluation_rule_code)
VALUES
('ACCEPTED_SOURCE_IDENTITY',1,'SOURCE_INTEGRITY','ALL','SYSTEM_BLOCK','VERIFY_ACCEPTED_STATUS_GATE_COUNT_HASH_GRAIN'),
('ACCEPTED_CANDIDATE_RESTRICTION',2,'CANDIDATE_INTEGRITY','CANDIDATE_APPLICATION','SYSTEM_BLOCK','SELECT_ONLY_ACCEPTED_M2_2_CANDIDATES'),
('POLICY_DECLINE_PRESERVATION',3,'DECISION_PRESERVATION','APPLICATION','ACCESS_BLOCK','PRESERVE_POLICY_DECLINE'),
('INSUFFICIENT_EVIDENCE_PRESERVATION',4,'DECISION_PRESERVATION','APPLICATION','ACCESS_BLOCK','PRESERVE_INSUFFICIENT_EVIDENCE'),
('STRUCTURE_BOUNDS',5,'CANDIDATE_STRUCTURE','CANDIDATE','ACCESS_BLOCK','ENFORCE_ACCEPTED_REQUEST_AND_CANDIDATE_BOUNDS'),
('AFFORDABILITY_INTEGRITY',6,'AFFORDABILITY','CANDIDATE_APPLICATION','ACCESS_BLOCK','NO_PRICE_OR_CONTRIBUTION_CURE_OF_HARD_AFFORDABILITY'),
('ECONOMIC_EVIDENCE',7,'ECONOMICS','CANDIDATE_APPLICATION','ACCESS_BLOCK','REQUIRE_VALID_EXPECTED_LOSS_CONTRIBUTION_RETURN_AND_EVIDENCE'),
('EXCEPTION_CERTIFICATION_INTEGRITY',8,'ACCOUNT_CERTIFICATION','APPLICATION_ACCOUNT','ACCESS_BLOCK','REQUIRE_CERTIFIED_ZERO_UNRESOLVED_WHEN_ACCOUNT_PRESENT'),
('SERVICING_ELIGIBILITY',9,'ACCOUNT_SERVICING','ACCOUNT','ACCESS_BLOCK','SERVICING_ONLY_ACCEPTED_OPERATIONAL_ACCOUNTS'),
('CLOSED_STATE_PRESERVATION',10,'ACCOUNT_SERVICING','ACCOUNT','ACCESS_BLOCK','CLOSED_STABLE_REMAINS_NO_ACTION'),
('STRESS_NONIMPROVEMENT',11,'STRESS_COMPARISON','COMPARISON','SYSTEM_BLOCK','PROHIBIT_FAVORABLE_SOURCE_ACCESS_FEASIBILITY_OR_COMPARABLE_BURDEN_MOVEMENT'),
('NON_PRODUCTION_BOUNDARY',12,'STAGE_BOUNDARY','ALL','SYSTEM_BLOCK','PROHIBIT_REAL_DECISION_ACCOUNT_PAYMENT_FUNDS_CONTACT_COLLECTION_LEGAL_NOTICE_ACTION');

CREATE TEMP TABLE tmp_eval_expected_reason
(
 reason_code text PRIMARY KEY,reason_sequence smallint NOT NULL,
 reason_family text NOT NULL,severity_code text NOT NULL,
 severity_rank smallint NOT NULL,applicability_code text NOT NULL
) ON COMMIT DROP;
INSERT INTO tmp_eval_expected_reason
(reason_code,reason_sequence,reason_family,severity_code,severity_rank,applicability_code)
VALUES
('M2_11_REASON_SOURCE_CONTRACTS_VERIFIED',1,'SOURCE_EVIDENCE','INFO',1,'ALL'),
('M2_11_REASON_BASELINE_REPLAY_MATCH',2,'SOURCE_EVIDENCE','INFO',1,'APPLICATION_ACCOUNT'),
('M2_11_REASON_SOURCE_EVIDENCE_PARTIAL',3,'SOURCE_EVIDENCE','REVIEW',2,'CANDIDATE_APPLICATION'),
('M2_11_REASON_SOURCE_EVIDENCE_BLOCKED',4,'SOURCE_EVIDENCE','SYSTEM_BLOCK',4,'ALL'),
('M2_11_REASON_SOURCE_GRAIN_OR_LINEAGE_ERROR',5,'SOURCE_EVIDENCE','SYSTEM_BLOCK',4,'ALL'),
('M2_11_REASON_POLICY_DECLINE_PRESERVED',6,'CONSTRAINT_FEASIBILITY','ACCESS_BLOCK',3,'APPLICATION'),
('M2_11_REASON_INSUFFICIENT_EVIDENCE_PRESERVED',7,'CONSTRAINT_FEASIBILITY','ACCESS_BLOCK',3,'APPLICATION'),
('M2_11_REASON_CANDIDATE_NOT_ELIGIBLE',8,'CONSTRAINT_FEASIBILITY','ACCESS_BLOCK',3,'CANDIDATE'),
('M2_11_REASON_STRUCTURE_BOUND_VIOLATION',9,'CONSTRAINT_FEASIBILITY','ACCESS_BLOCK',3,'CANDIDATE'),
('M2_11_REASON_AFFORDABILITY_CONSTRAINT',10,'CONSTRAINT_FEASIBILITY','ACCESS_BLOCK',3,'CANDIDATE'),
('M2_11_REASON_ECONOMIC_EVIDENCE_BLOCKED',11,'CONSTRAINT_FEASIBILITY','ACCESS_BLOCK',3,'CANDIDATE'),
('M2_11_REASON_NEGATIVE_CONTRIBUTION',12,'CONSTRAINT_FEASIBILITY','ACCESS_BLOCK',3,'CANDIDATE'),
('M2_11_REASON_BELOW_HURDLE_REVIEW',13,'CONSTRAINT_FEASIBILITY','REVIEW',2,'CANDIDATE_APPLICATION'),
('M2_11_REASON_UNRESOLVED_EXCEPTION',14,'CONSTRAINT_FEASIBILITY','ACCESS_BLOCK',3,'APPLICATION_ACCOUNT'),
('M2_11_REASON_CLOSED_STATE_PRESERVED',15,'CONSTRAINT_FEASIBILITY','INFO',1,'ACCOUNT'),
('M2_11_REASON_ACCESS_EXPANSION_SELECTED',16,'STRATEGY_SELECTION','INFO',1,'APPLICATION'),
('M2_11_REASON_PRICE_FOR_RISK_SELECTED',17,'STRATEGY_SELECTION','INFO',1,'APPLICATION'),
('M2_11_REASON_PAYMENT_BURDEN_RELIEF_SELECTED',18,'STRATEGY_SELECTION','INFO',1,'APPLICATION'),
('M2_11_REASON_LOSS_CONTAINMENT_SELECTED',19,'STRATEGY_SELECTION','INFO',1,'APPLICATION'),
('M2_11_REASON_PROFITABILITY_DISCIPLINE_SELECTED',20,'STRATEGY_SELECTION','INFO',1,'APPLICATION'),
('M2_11_REASON_EARLY_INTERVENTION_SIMULATED',21,'STRATEGY_SELECTION','REVIEW',2,'ACCOUNT'),
('M2_11_REASON_BALANCED_FRONTIER_SELECTED',22,'STRATEGY_SELECTION','INFO',1,'APPLICATION'),
('M2_11_REASON_NO_ACCESS_STRATEGY_RESTRICTION',23,'STRATEGY_SELECTION','INFO',1,'APPLICATION'),
('M2_11_REASON_CONTROLLED_REVIEW_REQUIRED',24,'STRATEGY_SELECTION','REVIEW',2,'APPLICATION_ACCOUNT'),
('M2_11_REASON_DETERMINISTIC_TIE_BREAK_APPLIED',25,'STRATEGY_SELECTION','INFO',1,'CANDIDATE_APPLICATION'),
('M2_11_REASON_NO_FEASIBLE_CANDIDATE',26,'STRATEGY_SELECTION','ACCESS_BLOCK',3,'APPLICATION'),
('M2_11_REASON_STRESS_SOURCE_NONIMPROVEMENT_PASS',27,'STRESS_FRONTIER_GOVERNANCE','INFO',1,'COMPARISON'),
('M2_11_REASON_STRESS_STRATEGY_RESTRICTION',28,'STRESS_FRONTIER_GOVERNANCE','INFO',1,'COMPARISON'),
('M2_11_REASON_STRESS_IMPROVEMENT_VIOLATION',29,'STRESS_FRONTIER_GOVERNANCE','SYSTEM_BLOCK',4,'COMPARISON'),
('M2_11_REASON_NONDOMINATED_FRONTIER',30,'STRESS_FRONTIER_GOVERNANCE','INFO',1,'FRONTIER'),
('M2_11_REASON_DOMINATED_STRATEGY',31,'STRESS_FRONTIER_GOVERNANCE','INFO',1,'FRONTIER'),
('M2_11_REASON_GOVERNANCE_REVIEW_PRIORITY',32,'STRESS_FRONTIER_GOVERNANCE','REVIEW',2,'FRONTIER');

/* ============================================================================
Section 2 — Independent candidate feasibility, normalization, score, and winner
============================================================================ */
CREATE TEMP TABLE tmp_eval_candidate_base ON COMMIT DROP AS
WITH bounds AS
(
 SELECT
   (p.configuration_payload #>> '{inherited_m2_2_structure_bounds,minimum_candidate_amount}')::numeric(18,2) AS minimum_candidate_amount,
   (p.configuration_payload #>> '{inherited_m2_2_structure_bounds,minimum_remittance_rate}')::numeric(9,6) AS minimum_remittance_rate,
   (p.configuration_payload #>> '{inherited_m2_2_structure_bounds,maximum_remittance_rate}')::numeric(9,6) AS maximum_remittance_rate,
   (p.configuration_payload #>> '{inherited_m2_2_structure_bounds,minimum_payback_multiple}')::numeric(9,6) AS minimum_payback_multiple,
   (p.configuration_payload #>> '{inherited_m2_2_structure_bounds,maximum_payback_multiple}')::numeric(9,6) AS maximum_payback_multiple,
   (p.configuration_payload #>> '{inherited_m2_2_structure_bounds,minimum_collection_horizon_days}')::integer AS minimum_collection_horizon_days,
   (p.configuration_payload #>> '{inherited_m2_2_structure_bounds,maximum_collection_horizon_days}')::integer AS maximum_collection_horizon_days
 FROM msbf_ctl.m2_11_policy_profile p
 WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
), base AS
(
 SELECT
   c.module1_run_id,c.scenario_id,c.scenario_code,c.merchant_application_id,
   c.candidate_template_code,c.row_hash AS candidate_source_snapshot_row_hash,
   c.source_candidate_row_hash,c.candidate_rank,c.candidate_eligible_flag,
   c.source_route_code,c.source_route_rank,c.requested_funding_amount,
   c.candidate_funding_amount,c.candidate_remittance_rate,
   c.candidate_payback_multiple,c.candidate_collection_horizon_days,
   c.candidate_finance_charge_amount,c.expected_loss_amount,
   c.risk_adjusted_contribution_amount,c.annualized_return_rate,
   c.counteroffer_foundation_flag,c.source_g2_combined_hash,
   c.m2_2_contract_status,c.m2_2_combined_set_hash,
   a.structure_available_flag,a.review_required_flag,a.affordability_status,
   a.hard_stop_recommended_flag,a.economic_status,
   a.m1_15_contract_evidence_status,a.acquisition_contract_evidence_status,
   a.routing_evidence_status,a.source_join_status_code,
   acct.module1_run_id IS NOT NULL AS operational_account_present_flag,
   acct.unresolved_exception_count,acct.certification_blocked_flag,
   s.strategy_profile_code,s.selection_mode,s.selected_exposure_direction,
   s.access_rate_weight,s.selected_exposure_weight,s.finance_charge_weight,
   s.expected_loss_density_weight,s.risk_adjusted_contribution_weight,
   s.annualized_return_weight,s.payment_burden_weight,
   s.candidate_domain_weight_total,s.candidate_scoring_applicable_flag,
   CASE
     WHEN a.m1_15_contract_evidence_status='BLOCKED'
       OR a.acquisition_contract_evidence_status='BLOCKED'
       OR a.routing_evidence_status='BLOCKED' THEN 'BLOCKED'
     WHEN a.m1_15_contract_evidence_status='PARTIAL'
       OR a.acquisition_contract_evidence_status='PARTIAL'
       OR a.routing_evidence_status='PARTIAL' THEN 'PARTIAL'
     ELSE 'COMPLETE'
   END AS expected_source_evidence_status_code,
   (
     c.m2_2_contract_status='ACCEPTED'
     AND c.m2_2_combined_set_hash='bbe83b187b31ea561789797322031fc6'
     AND a.source_join_status_code='MATCHED_ONE_TO_ONE'
     AND c.source_candidate_row_hash~'^[0-9a-f]{32}$'
     AND c.row_hash~'^[0-9a-f]{32}$'
     AND c.source_g2_combined_hash='e5ace7f32060ffb191c7bd0f8dd0c863'
   ) AS expected_source_integrity_pass_flag,
   array_remove(ARRAY[
     CASE WHEN NOT(
       c.m2_2_contract_status='ACCEPTED'
       AND c.m2_2_combined_set_hash='bbe83b187b31ea561789797322031fc6'
       AND a.source_join_status_code='MATCHED_ONE_TO_ONE'
       AND c.source_candidate_row_hash~'^[0-9a-f]{32}$'
       AND c.row_hash~'^[0-9a-f]{32}$'
       AND c.source_g2_combined_hash='e5ace7f32060ffb191c7bd0f8dd0c863'
     ) THEN 'ACCEPTED_SOURCE_IDENTITY' END,
     CASE WHEN NOT c.candidate_eligible_flag OR a.hard_stop_recommended_flag
               OR a.affordability_status IN ('UNAFFORDABLE','INSUFFICIENT_EVIDENCE')
          THEN 'AFFORDABILITY_INTEGRITY' END,
     CASE WHEN c.candidate_funding_amount<b.minimum_candidate_amount
               OR c.candidate_funding_amount>c.requested_funding_amount
               OR c.candidate_remittance_rate NOT BETWEEN b.minimum_remittance_rate AND b.maximum_remittance_rate
               OR c.candidate_payback_multiple NOT BETWEEN b.minimum_payback_multiple AND b.maximum_payback_multiple
               OR c.candidate_collection_horizon_days NOT BETWEEN b.minimum_collection_horizon_days AND b.maximum_collection_horizon_days
          THEN 'STRUCTURE_BOUNDS' END,
     CASE WHEN a.economic_status='NEGATIVE_CONTRIBUTION'
               OR coalesce(c.risk_adjusted_contribution_amount,0)<0
               OR coalesce(c.annualized_return_rate,0)<0
          THEN 'ECONOMIC_EVIDENCE' END,
     CASE WHEN acct.module1_run_id IS NOT NULL AND acct.certification_blocked_flag
          THEN 'EXCEPTION_CERTIFICATION_INTEGRITY' END
   ]::text[],NULL) AS expected_hard_constraint_array,
   (
     c.candidate_eligible_flag
     AND c.expected_loss_amount IS NOT NULL
     AND c.risk_adjusted_contribution_amount IS NOT NULL
     AND c.annualized_return_rate IS NOT NULL
     AND c.candidate_finance_charge_amount IS NOT NULL
     AND a.m1_15_contract_evidence_status<>'BLOCKED'
     AND a.acquisition_contract_evidence_status<>'BLOCKED'
     AND a.routing_evidence_status<>'BLOCKED'
     AND a.economic_status<>'INSUFFICIENT_EVIDENCE'
   ) AS expected_objective_evidence_complete_flag
 FROM msbf_m2.portfolio_strategy_candidate_source_snapshot c
 JOIN msbf_m2.portfolio_strategy_application_source_snapshot a
   USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
 LEFT JOIN msbf_m2.portfolio_strategy_account_source_snapshot acct
   USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
 CROSS JOIN msbf_m2.portfolio_strategy_profile s
 CROSS JOIN bounds b
 WHERE c.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
)
SELECT
  b.*,
  cardinality(b.expected_hard_constraint_array)::integer AS expected_hard_constraint_violation_count,
  to_jsonb(b.expected_hard_constraint_array) AS expected_hard_constraint_codes,
  CASE
    WHEN NOT b.expected_source_integrity_pass_flag THEN 'BLOCKED_SOURCE_INTEGRITY'
    WHEN cardinality(b.expected_hard_constraint_array)>0 THEN 'INFEASIBLE_HARD_CONSTRAINT'
    WHEN b.candidate_scoring_applicable_flag AND NOT b.expected_objective_evidence_complete_flag THEN 'INFEASIBLE_OBJECTIVE_EVIDENCE'
    WHEN (b.source_route_code='MANUAL_REVIEW' OR b.review_required_flag)
      AND NOT(
        b.strategy_profile_code='ACCESS_EXPANSION' AND b.candidate_eligible_flag
        AND b.counteroffer_foundation_flag AND b.economic_status='ABOVE_HURDLE'
        AND b.risk_adjusted_contribution_amount>=0 AND b.annualized_return_rate>=0
        AND b.expected_source_evidence_status_code<>'BLOCKED'
        AND coalesce(b.unresolved_exception_count,0)=0
      ) THEN 'FEASIBLE_CONTROLLED_REVIEW'
    WHEN b.economic_status='BELOW_HURDLE' THEN 'FEASIBLE_CONTROLLED_REVIEW'
    ELSE 'FEASIBLE_ACCESS'
  END AS expected_feasibility_class,
  CASE
    WHEN NOT b.expected_source_integrity_pass_flag THEN 8
    WHEN cardinality(b.expected_hard_constraint_array)>0 THEN 5
    WHEN b.candidate_scoring_applicable_flag AND NOT b.expected_objective_evidence_complete_flag THEN 4
    WHEN (b.source_route_code='MANUAL_REVIEW' OR b.review_required_flag)
      AND NOT(
        b.strategy_profile_code='ACCESS_EXPANSION' AND b.candidate_eligible_flag
        AND b.counteroffer_foundation_flag AND b.economic_status='ABOVE_HURDLE'
        AND b.risk_adjusted_contribution_amount>=0 AND b.annualized_return_rate>=0
        AND b.expected_source_evidence_status_code<>'BLOCKED'
        AND coalesce(b.unresolved_exception_count,0)=0
      ) THEN 2
    WHEN b.economic_status='BELOW_HURDLE' THEN 2
    ELSE 1
  END::smallint AS expected_feasibility_rank
FROM base b;
CREATE UNIQUE INDEX tmp_eval_candidate_base_u1 ON tmp_eval_candidate_base
(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code);
ANALYZE tmp_eval_candidate_base;

CREATE TEMP TABLE tmp_score_candidate_alternative ON COMMIT DROP AS
SELECT
  b.module1_run_id,b.scenario_id,b.scenario_code,b.merchant_application_id,
  b.strategy_profile_code,b.candidate_template_code,FALSE AS implicit_no_access_flag,
  b.candidate_source_snapshot_row_hash,b.source_candidate_row_hash,b.candidate_rank,
  b.expected_feasibility_class AS feasibility_class,b.expected_feasibility_rank AS feasibility_rank,
  CASE WHEN b.expected_feasibility_class='FEASIBLE_ACCESS' THEN 1::numeric(28,10) ELSE 0::numeric(28,10) END AS access_raw,
  b.candidate_funding_amount::numeric(28,10) AS exposure_raw,
  b.candidate_finance_charge_amount::numeric(28,10) AS finance_raw,
  CASE WHEN b.candidate_funding_amount=0 THEN NULL ELSE round((b.expected_loss_amount/b.candidate_funding_amount)::numeric,10)::numeric(28,10) END AS loss_raw,
  b.risk_adjusted_contribution_amount::numeric(28,10) AS contribution_raw,
  b.annualized_return_rate::numeric(28,10) AS return_raw,
  b.candidate_remittance_rate::numeric(28,10) AS payment_raw,
  b.selected_exposure_direction,b.access_rate_weight,b.selected_exposure_weight,
  b.finance_charge_weight,b.expected_loss_density_weight,b.risk_adjusted_contribution_weight,
  b.annualized_return_weight,b.payment_burden_weight,b.candidate_domain_weight_total
FROM tmp_eval_candidate_base b
WHERE b.candidate_scoring_applicable_flag
  AND b.expected_feasibility_class IN ('FEASIBLE_ACCESS','FEASIBLE_CONTROLLED_REVIEW')
  AND b.expected_objective_evidence_complete_flag
UNION ALL
SELECT
  a.module1_run_id,a.scenario_id,a.scenario_code,a.merchant_application_id,
  s.strategy_profile_code,'IMPLICIT_NO_ACCESS',TRUE,
  md5(a.row_hash||'|IMPLICIT_NO_ACCESS'),md5(a.row_hash||'|IMPLICIT_NO_ACCESS_SOURCE'),2147483647,
  'FEASIBLE_NO_ACCESS',3,
  0::numeric(28,10),0::numeric(28,10),0::numeric(28,10),0::numeric(28,10),
  0::numeric(28,10),0::numeric(28,10),0::numeric(28,10),
  s.selected_exposure_direction,s.access_rate_weight,s.selected_exposure_weight,
  s.finance_charge_weight,s.expected_loss_density_weight,s.risk_adjusted_contribution_weight,
  s.annualized_return_weight,s.payment_burden_weight,s.candidate_domain_weight_total
FROM msbf_m2.portfolio_strategy_application_source_snapshot a
CROSS JOIN msbf_m2.portfolio_strategy_profile s
WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
  AND a.structure_available_flag AND s.candidate_scoring_applicable_flag;
CREATE INDEX tmp_score_candidate_alternative_i1 ON tmp_score_candidate_alternative
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,candidate_template_code);
ANALYZE tmp_score_candidate_alternative;

CREATE TEMP TABLE tmp_score_candidate_scored ON COMMIT DROP AS
WITH b AS
(
 SELECT a.*,
  min(access_raw) OVER w AS access_min,max(access_raw) OVER w AS access_max,
  min(exposure_raw) OVER w AS exposure_min,max(exposure_raw) OVER w AS exposure_max,
  min(finance_raw) OVER w AS finance_min,max(finance_raw) OVER w AS finance_max,
  min(loss_raw) OVER w AS loss_min,max(loss_raw) OVER w AS loss_max,
  min(contribution_raw) OVER w AS contribution_min,max(contribution_raw) OVER w AS contribution_max,
  min(return_raw) OVER w AS return_min,max(return_raw) OVER w AS return_max,
  min(payment_raw) OVER w AS payment_min,max(payment_raw) OVER w AS payment_max
 FROM tmp_score_candidate_alternative a
 WINDOW w AS(PARTITION BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)
), n AS
(
 SELECT b.*,
  round(CASE WHEN access_max=access_min THEN 1 ELSE (access_raw-access_min)/(access_max-access_min) END,10)::numeric(18,10) AS access_norm,
  round(CASE WHEN exposure_max=exposure_min THEN 1 WHEN selected_exposure_direction='MINIMIZE' THEN (exposure_max-exposure_raw)/(exposure_max-exposure_min) ELSE (exposure_raw-exposure_min)/(exposure_max-exposure_min) END,10)::numeric(18,10) AS exposure_norm,
  round(CASE WHEN finance_max=finance_min THEN 1 ELSE (finance_raw-finance_min)/(finance_max-finance_min) END,10)::numeric(18,10) AS finance_norm,
  round(CASE WHEN loss_max=loss_min THEN 1 ELSE (loss_max-loss_raw)/(loss_max-loss_min) END,10)::numeric(18,10) AS loss_norm,
  round(CASE WHEN contribution_max=contribution_min THEN 1 ELSE (contribution_raw-contribution_min)/(contribution_max-contribution_min) END,10)::numeric(18,10) AS contribution_norm,
  round(CASE WHEN return_max=return_min THEN 1 ELSE (return_raw-return_min)/(return_max-return_min) END,10)::numeric(18,10) AS return_norm,
  round(CASE WHEN payment_max=payment_min THEN 1 ELSE (payment_max-payment_raw)/(payment_max-payment_min) END,10)::numeric(18,10) AS payment_norm
 FROM b
)
SELECT n.*,
 round(access_norm*access_rate_weight,12)::numeric(22,12) AS access_component,
 round(exposure_norm*selected_exposure_weight,12)::numeric(22,12) AS exposure_component,
 round(finance_norm*finance_charge_weight,12)::numeric(22,12) AS finance_component,
 round(loss_norm*expected_loss_density_weight,12)::numeric(22,12) AS loss_component,
 round(contribution_norm*risk_adjusted_contribution_weight,12)::numeric(22,12) AS contribution_component,
 round(return_norm*annualized_return_weight,12)::numeric(22,12) AS return_component,
 round(payment_norm*payment_burden_weight,12)::numeric(22,12) AS payment_component,
 round((access_norm*access_rate_weight+exposure_norm*selected_exposure_weight+
        finance_norm*finance_charge_weight+loss_norm*expected_loss_density_weight+
        contribution_norm*risk_adjusted_contribution_weight+return_norm*annualized_return_weight+
        payment_norm*payment_burden_weight)/candidate_domain_weight_total,12)::numeric(22,12) AS objective_score
FROM n;
CREATE INDEX tmp_score_candidate_scored_i1 ON tmp_score_candidate_scored
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,objective_score DESC,feasibility_rank,candidate_rank,candidate_template_code);
ANALYZE tmp_score_candidate_scored;

CREATE TEMP TABLE tmp_score_candidate_winner ON COMMIT DROP AS
WITH mx AS
(
 SELECT module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,max(objective_score) AS max_score
 FROM tmp_score_candidate_scored GROUP BY 1,2,3,4
), feasible AS
(
 SELECT module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,
        count(*) FILTER(WHERE NOT implicit_no_access_flag) AS feasible_accepted_count
 FROM tmp_score_candidate_scored GROUP BY 1,2,3,4
), ranked AS
(
 SELECT s.*,f.feasible_accepted_count,
  count(*) OVER(PARTITION BY s.module1_run_id,s.scenario_id,s.merchant_application_id,s.strategy_profile_code) AS top_tolerance_count,
  row_number() OVER(PARTITION BY s.module1_run_id,s.scenario_id,s.merchant_application_id,s.strategy_profile_code
    ORDER BY s.feasibility_rank,s.candidate_rank,s.candidate_template_code,s.source_candidate_row_hash) AS tie_rank
 FROM tmp_score_candidate_scored s
 JOIN mx USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)
 JOIN feasible f USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)
 WHERE s.objective_score>=mx.max_score-0.000000000001::numeric(22,12)
)
SELECT * FROM ranked WHERE tie_rank=1;
CREATE UNIQUE INDEX tmp_score_candidate_winner_u1 ON tmp_score_candidate_winner
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_score_candidate_winner;

CREATE TEMP TABLE tmp_eval_candidate_expected ON COMMIT DROP AS
WITH tolerance AS
(
 SELECT s.module1_run_id,s.scenario_id,s.merchant_application_id,s.strategy_profile_code,
        max(s.objective_score) AS max_score
 FROM tmp_score_candidate_scored s GROUP BY 1,2,3,4
), tolerance_count AS
(
 SELECT s.module1_run_id,s.scenario_id,s.merchant_application_id,s.strategy_profile_code,
        count(*) FILTER(WHERE s.objective_score>=t.max_score-0.000000000001::numeric(22,12)) AS top_count,
        t.max_score
 FROM tmp_score_candidate_scored s JOIN tolerance t USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)
 GROUP BY 1,2,3,4,t.max_score
)
SELECT
 b.*,
 CASE WHEN b.expected_feasibility_class='FEASIBLE_ACCESS' THEN 1::numeric(28,10) ELSE 0::numeric(28,10) END AS expected_access_raw,
 b.candidate_funding_amount::numeric(28,10) AS expected_exposure_raw,
 b.candidate_finance_charge_amount::numeric(28,10) AS expected_finance_raw,
 CASE WHEN b.candidate_funding_amount=0 THEN NULL ELSE round((b.expected_loss_amount/b.candidate_funding_amount)::numeric,10)::numeric(28,10) END AS expected_loss_raw,
 b.risk_adjusted_contribution_amount::numeric(28,10) AS expected_contribution_raw,
 b.annualized_return_rate::numeric(28,10) AS expected_return_raw,
 b.candidate_remittance_rate::numeric(28,10) AS expected_payment_raw,
 s.access_min,s.access_max,s.access_norm,s.access_component,
 s.exposure_min,s.exposure_max,s.exposure_norm,s.exposure_component,
 s.finance_min,s.finance_max,s.finance_norm,s.finance_component,
 s.loss_min,s.loss_max,s.loss_norm,s.loss_component,
 s.contribution_min,s.contribution_max,s.contribution_norm,s.contribution_component,
 s.return_min,s.return_max,s.return_norm,s.return_component,
 s.payment_min,s.payment_max,s.payment_norm,s.payment_component,
 s.objective_score AS expected_objective_score,
 coalesce(tc.top_count,0)>1 AND s.objective_score>=coalesce(tc.max_score,s.objective_score)-0.000000000001::numeric(22,12) AS expected_tie_flag,
 CASE
  WHEN b.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
   THEN coalesce(b.candidate_template_code=a.selected_candidate_template_code AND b.source_candidate_row_hash=a.selected_candidate_row_hash,FALSE)
  WHEN b.candidate_scoring_applicable_flag
   THEN coalesce(w.candidate_template_code=b.candidate_template_code AND NOT w.implicit_no_access_flag,FALSE)
  ELSE FALSE
 END AS expected_selected_flag,
 CASE
  WHEN NOT b.expected_source_integrity_pass_flag THEN 'M2_11_REASON_SOURCE_EVIDENCE_BLOCKED'
  WHEN NOT b.candidate_eligible_flag THEN 'M2_11_REASON_CANDIDATE_NOT_ELIGIBLE'
  WHEN b.expected_hard_constraint_codes ? 'STRUCTURE_BOUNDS' THEN 'M2_11_REASON_STRUCTURE_BOUND_VIOLATION'
  WHEN b.expected_hard_constraint_codes ? 'AFFORDABILITY_INTEGRITY' THEN 'M2_11_REASON_AFFORDABILITY_CONSTRAINT'
  WHEN b.expected_hard_constraint_codes ? 'EXCEPTION_CERTIFICATION_INTEGRITY' THEN 'M2_11_REASON_UNRESOLVED_EXCEPTION'
  WHEN b.expected_hard_constraint_codes ? 'ECONOMIC_EVIDENCE' THEN 'M2_11_REASON_NEGATIVE_CONTRIBUTION'
  WHEN b.expected_feasibility_class='INFEASIBLE_OBJECTIVE_EVIDENCE' THEN 'M2_11_REASON_ECONOMIC_EVIDENCE_BLOCKED'
  WHEN b.expected_feasibility_class='FEASIBLE_CONTROLLED_REVIEW' THEN 'M2_11_REASON_BELOW_HURDLE_REVIEW'
  WHEN b.expected_source_evidence_status_code='PARTIAL' THEN 'M2_11_REASON_SOURCE_EVIDENCE_PARTIAL'
  ELSE 'M2_11_REASON_SOURCE_CONTRACTS_VERIFIED'
 END AS expected_primary_reason_code,
 to_jsonb(array_remove(ARRAY[
   CASE WHEN NOT b.expected_source_integrity_pass_flag THEN 'M2_11_REASON_SOURCE_EVIDENCE_BLOCKED' END,
   CASE WHEN b.expected_source_evidence_status_code='PARTIAL' THEN 'M2_11_REASON_SOURCE_EVIDENCE_PARTIAL' END,
   CASE WHEN NOT b.candidate_eligible_flag THEN 'M2_11_REASON_CANDIDATE_NOT_ELIGIBLE' END,
   CASE WHEN b.expected_hard_constraint_codes ? 'STRUCTURE_BOUNDS' THEN 'M2_11_REASON_STRUCTURE_BOUND_VIOLATION' END,
   CASE WHEN b.expected_hard_constraint_codes ? 'AFFORDABILITY_INTEGRITY' THEN 'M2_11_REASON_AFFORDABILITY_CONSTRAINT' END,
   CASE WHEN b.expected_hard_constraint_codes ? 'ECONOMIC_EVIDENCE' THEN 'M2_11_REASON_NEGATIVE_CONTRIBUTION' END,
   CASE WHEN b.expected_hard_constraint_codes ? 'EXCEPTION_CERTIFICATION_INTEGRITY' THEN 'M2_11_REASON_UNRESOLVED_EXCEPTION' END,
   CASE WHEN b.expected_feasibility_class='INFEASIBLE_OBJECTIVE_EVIDENCE' THEN 'M2_11_REASON_ECONOMIC_EVIDENCE_BLOCKED' END,
   CASE WHEN b.expected_feasibility_class='FEASIBLE_CONTROLLED_REVIEW' THEN 'M2_11_REASON_BELOW_HURDLE_REVIEW' END,
   CASE WHEN coalesce(tc.top_count,0)>1 AND s.objective_score>=coalesce(tc.max_score,s.objective_score)-0.000000000001::numeric(22,12)
        THEN 'M2_11_REASON_DETERMINISTIC_TIE_BREAK_APPLIED' END
 ]::text[],NULL)) AS expected_reason_codes
FROM tmp_eval_candidate_base b
JOIN msbf_m2.portfolio_strategy_application_source_snapshot a
 USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
LEFT JOIN tmp_score_candidate_scored s
 USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,strategy_profile_code,candidate_template_code)
LEFT JOIN tolerance_count tc
 USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)
LEFT JOIN tmp_score_candidate_winner w
 USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
CREATE UNIQUE INDEX tmp_eval_candidate_expected_u1 ON tmp_eval_candidate_expected
(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code);
ANALYZE tmp_eval_candidate_expected;

/* ============================================================================
Section 3 — Independent account-treatment and account-adversity reconstruction
============================================================================ */
CREATE TEMP TABLE tmp_eval_account_expected_base ON COMMIT DROP AS
SELECT
    a.module1_run_id,a.scenario_id,a.scenario_code,a.merchant_application_id,
    a.synthetic_account_id,s.strategy_profile_code,
    a.row_hash AS account_source_snapshot_row_hash,
    a.source_account_posture_code,a.source_account_posture_rank,
    a.operational_setup_outcome_code AS source_operational_setup_outcome_code,
    a.operational_setup_action_code AS source_operational_setup_action_code,
    a.operational_setup_queue_code AS source_operational_setup_queue_code,
    a.operational_activation_date AS source_operational_activation_date,
    a.next_reassessment_date AS source_next_reassessment_date,
    a.applied_temporary_payment_factor AS source_payment_factor,
    a.applied_setup_duration_days AS source_setup_duration_days,
    a.applied_reassessment_interval_days AS source_reassessment_interval_days,
    a.certified_state_code AS source_certified_state_code,
    a.servicing_queue_code AS source_servicing_queue_code,
    a.certified_exposure_amount AS source_certified_exposure_amount,
    a.servicing_burden_units AS source_servicing_burden_units,
    CASE
      WHEN s.strategy_profile_code<>'EARLY_INTERVENTION' THEN 'SOURCE_SERVICING_REPLAY'
      WHEN a.source_account_posture_code='CLOSED_STABLE' THEN 'NO_INTERVENTION_REPLAY'
      WHEN a.source_account_posture_code='ACTIVE_RECONCILED' THEN 'EARLY_REASSESSMENT_SIMULATION'
      WHEN a.source_account_posture_code='CONTROLLED_REVIEW' THEN 'ACCELERATED_GOVERNANCE_REVIEW_SIMULATION'
      ELSE 'SOURCE_SERVICING_REPLAY'
    END AS expected_servicing_treatment_code,
    (s.strategy_profile_code='EARLY_INTERVENTION'
      AND a.source_account_posture_code IN ('ACTIVE_RECONCILED','CONTROLLED_REVIEW')) AS expected_treatment_applicable_flag,
    CASE
      WHEN s.strategy_profile_code='EARLY_INTERVENTION' AND a.source_account_posture_code='ACTIVE_RECONCILED'
        THEN greatest(a.operational_activation_date+1,a.next_reassessment_date-4)
      WHEN s.strategy_profile_code='EARLY_INTERVENTION' AND a.source_account_posture_code='CONTROLLED_REVIEW'
        THEN coalesce(a.operational_activation_date,(SELECT as_of_date FROM tmp_eval_m2_11_validation_context))+1
      ELSE NULL::date
    END AS expected_simulated_action_date,
    a.applied_temporary_payment_factor AS expected_simulated_payment_factor,
    a.certified_exposure_amount AS expected_simulated_exposure_amount,
    CASE WHEN s.strategy_profile_code='EARLY_INTERVENTION'
              AND a.source_account_posture_code IN ('ACTIVE_RECONCILED','CONTROLLED_REVIEW')
         THEN 1.000000::numeric(12,6) ELSE 0.000000::numeric(12,6) END AS expected_incremental_servicing_burden_units,
    (a.servicing_burden_units+
      CASE WHEN s.strategy_profile_code='EARLY_INTERVENTION'
                 AND a.source_account_posture_code IN ('ACTIVE_RECONCILED','CONTROLLED_REVIEW')
           THEN 1.000000::numeric(12,6) ELSE 0.000000::numeric(12,6) END)::numeric(12,6)
      AS expected_strategy_servicing_burden_units,
    FALSE AS expected_risk_benefit_claimed_flag,
    FALSE AS expected_return_benefit_claimed_flag,
    FALSE AS expected_contribution_benefit_claimed_flag,
    FALSE AS expected_payment_performance_benefit_claimed_flag,
    TRUE AS expected_source_replay_match_flag,
    'COMPLETE'::text AS expected_strategy_evidence_status,
    CASE
      WHEN s.strategy_profile_code='EARLY_INTERVENTION'
       AND a.source_account_posture_code IN ('ACTIVE_RECONCILED','CONTROLLED_REVIEW')
        THEN 'M2_11_REASON_EARLY_INTERVENTION_SIMULATED'
      WHEN a.source_account_posture_code='CLOSED_STABLE'
        THEN 'M2_11_REASON_CLOSED_STATE_PRESERVED'
      ELSE 'M2_11_REASON_BASELINE_REPLAY_MATCH'
    END AS expected_primary_reason_code,
    to_jsonb(array_remove(ARRAY[
      'M2_11_REASON_BASELINE_REPLAY_MATCH',
      CASE WHEN a.source_account_posture_code='CLOSED_STABLE'
           THEN 'M2_11_REASON_CLOSED_STATE_PRESERVED' END,
      CASE WHEN s.strategy_profile_code='EARLY_INTERVENTION'
             AND a.source_account_posture_code IN ('ACTIVE_RECONCILED','CONTROLLED_REVIEW')
           THEN 'M2_11_REASON_EARLY_INTERVENTION_SIMULATED' END
    ]::text[],NULL)) AS expected_reason_codes
FROM msbf_m2.portfolio_strategy_account_source_snapshot a
CROSS JOIN msbf_m2.portfolio_strategy_profile s
WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
  AND s.module1_run_id=a.module1_run_id;

CREATE UNIQUE INDEX tmp_eval_account_expected_base_u1 ON tmp_eval_account_expected_base
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_account_expected_base;

/* The adversity tie-break is independently reconstructed from target-typed
   persisted physical fields after removing only the frozen adversity outputs,
   row hash, and audit timestamp. */
CREATE TEMP TABLE tmp_eval_account_adversity_expected ON COMMIT DROP AS
WITH h AS
(
 SELECT a.*,
   msbf_ctl.m2_11_hash_jsonb(
      to_jsonb(a)-'portfolio_adversity_order'-'portfolio_adverse_selected_flag'
                 -'row_hash'-'created_at'
   ) AS expected_adversity_tiebreak_hash
 FROM msbf_m2.account_servicing_strategy_simulation a
 WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
), r AS
(
 SELECT h.*,
   row_number() OVER
   (
     PARTITION BY module1_run_id,merchant_application_id,strategy_profile_code
     ORDER BY source_account_posture_rank DESC,
              strategy_servicing_burden_units DESC,
              source_certified_exposure_amount DESC,
              CASE scenario_code WHEN 'RECESSION_ENERGY' THEN 1 ELSE 2 END,
              expected_adversity_tiebreak_hash
   )::smallint AS expected_portfolio_adversity_order
 FROM h
)
SELECT module1_run_id,scenario_id,scenario_code,merchant_application_id,
       strategy_profile_code,expected_adversity_tiebreak_hash,
       expected_portfolio_adversity_order,
       (expected_portfolio_adversity_order=1) AS expected_portfolio_adverse_selected_flag
FROM r;

CREATE UNIQUE INDEX tmp_eval_account_adversity_expected_u1 ON tmp_eval_account_adversity_expected
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_account_adversity_expected;

/* ============================================================================
Section 4 — Independent application outcome, stress, and adversity reconstruction
============================================================================ */
CREATE TEMP TABLE tmp_eval_application_selection ON COMMIT DROP AS
SELECT
  a.*,
  s.selection_mode,s.candidate_scoring_applicable_flag,
  w.candidate_template_code AS weighted_candidate_template_code,
  w.implicit_no_access_flag AS weighted_implicit_no_access_flag,
  w.feasibility_class AS weighted_feasibility_class,
  w.feasibility_rank AS weighted_feasibility_rank,
  w.objective_score AS weighted_objective_score,
  w.feasible_accepted_count,
  cs.row_hash AS weighted_candidate_snapshot_row_hash,
  cs.source_candidate_row_hash AS weighted_candidate_source_row_hash,
  cs.candidate_funding_amount AS weighted_funding_amount,
  cs.candidate_remittance_rate AS weighted_remittance_rate,
  cs.candidate_payback_multiple AS weighted_payback_multiple,
  cs.candidate_collection_horizon_days AS weighted_collection_horizon_days,
  cs.candidate_total_repayment_amount AS weighted_total_repayment_amount,
  cs.candidate_finance_charge_amount AS weighted_finance_charge_amount,
  cs.implied_daily_collection_amount AS weighted_implied_daily_collection_amount,
  cs.implied_payoff_days AS weighted_implied_payoff_days,
  cs.amount_to_request_ratio AS weighted_amount_to_request_ratio,
  cs.acquisition_economics_amount AS weighted_acquisition_economics_amount,
  cs.expected_loss_amount AS weighted_expected_loss_amount,
  cs.risk_adjusted_contribution_amount AS weighted_contribution_amount,
  cs.annualized_return_rate AS weighted_annualized_return_rate,
  ce.row_hash AS weighted_candidate_evaluation_row_hash,
  ce.hard_constraint_violation_count AS weighted_hard_constraint_violation_count,
  ce.hard_constraint_codes AS weighted_hard_constraint_codes,
  ce.source_evidence_status_code AS weighted_candidate_evidence_status,
  cr.row_hash AS replay_candidate_snapshot_row_hash,
  cr.source_candidate_row_hash AS replay_candidate_source_row_hash,
  cr.expected_loss_amount AS replay_expected_loss_amount,
  cr.risk_adjusted_contribution_amount AS replay_contribution_amount,
  cr.annualized_return_rate AS replay_annualized_return_rate,
  cr.acquisition_economics_amount AS replay_acquisition_economics_amount,
  cer.row_hash AS replay_candidate_evaluation_row_hash,
  cer.hard_constraint_violation_count AS replay_hard_constraint_violation_count,
  cer.hard_constraint_codes AS replay_hard_constraint_codes,
  acct.row_hash AS account_source_snapshot_row_hash,
  acct.unresolved_exception_count AS account_unresolved_exception_count,
  acct.certified_state_code AS account_certified_state_code,
  acct.servicing_queue_code AS account_servicing_queue_code,
  acct.certified_exposure_amount AS account_certified_exposure_amount,
  acct.certification_blocked_flag AS account_certification_blocked_flag,
  acct.source_lineage_intact_flag AS account_source_lineage_intact_flag,
  asv.row_hash AS associated_account_servicing_simulation_row_hash,
  asv.servicing_treatment_code AS associated_servicing_treatment_code,
  asv.strategy_servicing_burden_units AS associated_servicing_burden_units
FROM msbf_m2.portfolio_strategy_application_source_snapshot a
CROSS JOIN msbf_m2.portfolio_strategy_profile s
LEFT JOIN tmp_score_candidate_winner w
  ON w.module1_run_id=a.module1_run_id AND w.scenario_id=a.scenario_id
 AND w.merchant_application_id=a.merchant_application_id
 AND w.strategy_profile_code=s.strategy_profile_code
LEFT JOIN msbf_m2.portfolio_strategy_candidate_source_snapshot cs
  ON cs.module1_run_id=a.module1_run_id AND cs.scenario_id=a.scenario_id
 AND cs.merchant_application_id=a.merchant_application_id
 AND cs.candidate_template_code=w.candidate_template_code
 AND NOT coalesce(w.implicit_no_access_flag,FALSE)
LEFT JOIN msbf_m2.application_strategy_candidate_evaluation ce
  ON ce.module1_run_id=a.module1_run_id AND ce.scenario_id=a.scenario_id
 AND ce.merchant_application_id=a.merchant_application_id
 AND ce.strategy_profile_code=s.strategy_profile_code
 AND ce.candidate_template_code=w.candidate_template_code
 AND NOT coalesce(w.implicit_no_access_flag,FALSE)
LEFT JOIN msbf_m2.portfolio_strategy_candidate_source_snapshot cr
  ON cr.module1_run_id=a.module1_run_id AND cr.scenario_id=a.scenario_id
 AND cr.merchant_application_id=a.merchant_application_id
 AND cr.candidate_template_code=a.selected_candidate_template_code
 AND cr.source_candidate_row_hash=a.selected_candidate_row_hash
LEFT JOIN msbf_m2.application_strategy_candidate_evaluation cer
  ON cer.module1_run_id=a.module1_run_id AND cer.scenario_id=a.scenario_id
 AND cer.merchant_application_id=a.merchant_application_id
 AND cer.strategy_profile_code=s.strategy_profile_code
 AND cer.candidate_template_code=a.selected_candidate_template_code
LEFT JOIN msbf_m2.portfolio_strategy_account_source_snapshot acct
  USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
LEFT JOIN msbf_m2.account_servicing_strategy_simulation asv
  ON asv.module1_run_id=a.module1_run_id AND asv.scenario_id=a.scenario_id
 AND asv.merchant_application_id=a.merchant_application_id
 AND asv.strategy_profile_code=s.strategy_profile_code
WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
  AND s.module1_run_id=a.module1_run_id;

CREATE UNIQUE INDEX tmp_eval_application_selection_u1 ON tmp_eval_application_selection
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_application_selection;

CREATE TEMP TABLE tmp_eval_application_expected ON COMMIT DROP AS
WITH d AS
(
 SELECT j.*,
   CASE
    WHEN j.source_join_status_code<>'MATCHED_ONE_TO_ONE'
      OR (j.structure_available_flag AND j.selected_candidate_template_code IS NOT NULL
          AND j.replay_candidate_snapshot_row_hash IS NULL)
      OR j.activation_outcome_code='NO_ACTIVATION_SOURCE_BOUNDARY'
      THEN 'BLOCKED_SOURCE_INTEGRITY'
    WHEN j.pricing_disposition_code='NO_STRUCTURE_POLICY_DECLINE'
      THEN 'NO_ACCESS_POLICY_DECLINE'
    WHEN j.pricing_disposition_code='NO_STRUCTURE_INSUFFICIENT_EVIDENCE'
      THEN 'NO_ACCESS_INSUFFICIENT_EVIDENCE'
    WHEN j.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN
      CASE j.activation_outcome_code
       WHEN 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED' THEN 'ACCESS_SELECTED'
       WHEN 'ACTIVATION_REVIEW_REQUIRED' THEN 'CONTROLLED_REVIEW'
       WHEN 'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE' THEN 'NO_ACCESS_INSUFFICIENT_EVIDENCE'
       WHEN 'NOT_ACTIVATED_POLICY_DECLINE' THEN 'NO_ACCESS_POLICY_DECLINE'
       ELSE 'BLOCKED_SOURCE_INTEGRITY'
      END
    WHEN coalesce(j.weighted_implicit_no_access_flag,FALSE) THEN
      CASE WHEN coalesce(j.feasible_accepted_count,0)>0
           THEN 'NO_ACCESS_STRATEGY_RESTRICTION'
           ELSE 'NO_ACCESS_NO_FEASIBLE_CANDIDATE' END
    WHEN j.weighted_feasibility_class='FEASIBLE_ACCESS' THEN 'ACCESS_SELECTED'
    WHEN j.weighted_feasibility_class='FEASIBLE_CONTROLLED_REVIEW' THEN 'CONTROLLED_REVIEW'
    WHEN j.weighted_candidate_template_code IS NULL THEN 'NO_ACCESS_NO_FEASIBLE_CANDIDATE'
    ELSE 'BLOCKED_SOURCE_INTEGRITY'
   END AS expected_strategy_outcome_code
 FROM tmp_eval_application_selection j
), e AS
(
 SELECT d.*,
   CASE d.expected_strategy_outcome_code
    WHEN 'ACCESS_SELECTED' THEN 1 WHEN 'CONTROLLED_REVIEW' THEN 2
    WHEN 'NO_ACCESS_STRATEGY_RESTRICTION' THEN 3
    WHEN 'NO_ACCESS_NO_FEASIBLE_CANDIDATE' THEN 4
    WHEN 'NO_ACCESS_INSUFFICIENT_EVIDENCE' THEN 5
    WHEN 'NO_ACCESS_POLICY_DECLINE' THEN 6
    WHEN 'BLOCKED_SOURCE_INTEGRITY' THEN 7 END::smallint AS expected_strategy_outcome_rank,
   CASE
    WHEN d.expected_strategy_outcome_code='ACCESS_SELECTED' THEN 'FEASIBLE_ACCESS'
    WHEN d.expected_strategy_outcome_code='CONTROLLED_REVIEW' THEN 'FEASIBLE_CONTROLLED_REVIEW'
    WHEN d.expected_strategy_outcome_code IN ('NO_ACCESS_STRATEGY_RESTRICTION','NO_ACCESS_NO_FEASIBLE_CANDIDATE') THEN 'FEASIBLE_NO_ACCESS'
    WHEN d.expected_strategy_outcome_code='NO_ACCESS_INSUFFICIENT_EVIDENCE' THEN 'PRESERVED_INSUFFICIENT_EVIDENCE'
    WHEN d.expected_strategy_outcome_code='NO_ACCESS_POLICY_DECLINE' THEN 'PRESERVED_POLICY_DECLINE'
    ELSE 'BLOCKED_SOURCE_INTEGRITY' END AS expected_feasibility_class,
   CASE
    WHEN d.expected_strategy_outcome_code='ACCESS_SELECTED' THEN 1
    WHEN d.expected_strategy_outcome_code='CONTROLLED_REVIEW' THEN 2
    WHEN d.expected_strategy_outcome_code IN ('NO_ACCESS_STRATEGY_RESTRICTION','NO_ACCESS_NO_FEASIBLE_CANDIDATE') THEN 3
    WHEN d.expected_strategy_outcome_code='NO_ACCESS_INSUFFICIENT_EVIDENCE' THEN 6
    WHEN d.expected_strategy_outcome_code='NO_ACCESS_POLICY_DECLINE' THEN 7
    ELSE 8 END::smallint AS expected_feasibility_rank,
   CASE
    WHEN d.expected_strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY' THEN 'BLOCKED'
    WHEN d.m1_15_contract_evidence_status='PARTIAL'
      OR d.acquisition_contract_evidence_status='PARTIAL'
      OR d.routing_evidence_status='PARTIAL'
      OR d.expected_strategy_outcome_code IN ('CONTROLLED_REVIEW','NO_ACCESS_INSUFFICIENT_EVIDENCE')
      THEN 'PARTIAL'
    ELSE 'COMPLETE' END AS expected_strategy_evidence_status
 FROM d
)
SELECT
 e.*,
 (e.expected_strategy_outcome_code='ACCESS_SELECTED') AS expected_access_selected_flag,
 (e.expected_strategy_outcome_code='CONTROLLED_REVIEW') AS expected_controlled_review_flag,
 (e.strategy_profile_code NOT IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
   AND coalesce(e.weighted_implicit_no_access_flag,FALSE)) AS expected_implicit_no_access_selected_flag,
 (e.expected_strategy_outcome_code='NO_ACCESS_POLICY_DECLINE') AS expected_policy_decline_preserved_flag,
 (e.expected_strategy_outcome_code='NO_ACCESS_INSUFFICIENT_EVIDENCE') AS expected_insufficient_evidence_preserved_flag,
 (e.expected_strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY') AS expected_source_integrity_blocked_flag,
 CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
      THEN e.selected_candidate_template_code
      WHEN NOT coalesce(e.weighted_implicit_no_access_flag,FALSE)
      THEN e.weighted_candidate_template_code END AS expected_selected_candidate_template_code,
 CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
      THEN e.selected_candidate_row_hash
      WHEN NOT coalesce(e.weighted_implicit_no_access_flag,FALSE)
      THEN e.weighted_candidate_source_row_hash END AS expected_selected_candidate_source_row_hash,
 CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
      THEN e.replay_candidate_evaluation_row_hash
      WHEN NOT coalesce(e.weighted_implicit_no_access_flag,FALSE)
      THEN e.weighted_candidate_evaluation_row_hash END AS expected_selected_candidate_evaluation_row_hash,
 CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
      THEN NULL::numeric(22,12) ELSE e.weighted_objective_score END AS expected_selection_objective_score,
 CASE WHEN e.expected_strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY' THEN 1
      WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
      THEN coalesce(e.replay_hard_constraint_violation_count,0)
      WHEN coalesce(e.weighted_implicit_no_access_flag,FALSE) THEN 0
      ELSE coalesce(e.weighted_hard_constraint_violation_count,0) END AS expected_hard_constraint_violation_count,
 CASE WHEN e.expected_strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY'
      THEN '["ACCEPTED_SOURCE_IDENTITY"]'::jsonb
      WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
      THEN coalesce(e.replay_hard_constraint_codes,'[]'::jsonb)
      WHEN coalesce(e.weighted_implicit_no_access_flag,FALSE) THEN '[]'::jsonb
      ELSE coalesce(e.weighted_hard_constraint_codes,'[]'::jsonb) END AS expected_hard_constraint_codes,
 (e.account_source_snapshot_row_hash IS NOT NULL) AS expected_operational_account_present_flag,
 CASE WHEN e.account_source_snapshot_row_hash IS NULL THEN 'NOT_APPLICABLE' ELSE 'APPLICABLE' END AS expected_account_applicability,
 CASE WHEN e.account_source_snapshot_row_hash IS NULL THEN 0 ELSE e.account_unresolved_exception_count END AS expected_constraint_unresolved_exception_count,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.selected_funding_amount ELSE e.weighted_funding_amount END
      ELSE 0.00::numeric(18,2) END AS expected_selected_exposure_amount,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.selected_remittance_rate ELSE e.weighted_remittance_rate END END AS expected_selected_remittance_rate,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.selected_payback_multiple ELSE e.weighted_payback_multiple END END AS expected_selected_payback_multiple,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.selected_collection_horizon_days ELSE e.weighted_collection_horizon_days END END AS expected_selected_collection_horizon_days,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.selected_total_repayment_amount ELSE e.weighted_total_repayment_amount END
      ELSE 0.00::numeric(18,2) END AS expected_selected_total_repayment_amount,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.selected_finance_charge_amount ELSE e.weighted_finance_charge_amount END
      ELSE 0.00::numeric(18,2) END AS expected_selected_finance_charge_amount,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.selected_implied_daily_collection_amount ELSE e.weighted_implied_daily_collection_amount END END AS expected_selected_implied_daily_collection_amount,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.selected_implied_payoff_days ELSE e.weighted_implied_payoff_days END END AS expected_selected_implied_payoff_days,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.selected_amount_to_request_ratio ELSE e.weighted_amount_to_request_ratio END END AS expected_selected_amount_to_request_ratio,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.replay_acquisition_economics_amount ELSE e.weighted_acquisition_economics_amount END END AS expected_selected_acquisition_economics_amount,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.replay_expected_loss_amount ELSE e.weighted_expected_loss_amount END
      ELSE 0.00::numeric(18,2) END AS expected_selected_expected_loss_amount,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN round((CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                       THEN e.replay_expected_loss_amount ELSE e.weighted_expected_loss_amount END)
                 /NULLIF((CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                               THEN e.selected_funding_amount ELSE e.weighted_funding_amount END),0),10)::numeric(28,10)
      ELSE NULL::numeric(28,10) END AS expected_selected_expected_loss_density,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.replay_contribution_amount ELSE e.weighted_contribution_amount END
      ELSE 0.00::numeric(18,2) END AS expected_selected_risk_adjusted_contribution,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.replay_annualized_return_rate ELSE e.weighted_annualized_return_rate END
      ELSE 0.00000000::numeric(12,8) END AS expected_selected_annualized_return,
 CASE WHEN e.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
      THEN CASE WHEN e.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
                THEN e.selected_remittance_rate ELSE e.weighted_remittance_rate END
      ELSE 0.000000::numeric(9,6) END AS expected_selected_payment_burden_rate
FROM e;

CREATE UNIQUE INDEX tmp_eval_application_expected_u1 ON tmp_eval_application_expected
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_application_expected;

CREATE TEMP TABLE tmp_eval_app_stress_flags ON COMMIT DROP AS
SELECT
 b.module1_run_id,b.merchant_application_id,b.strategy_profile_code,
 (
   (s_src.integrated_risk_score IS NOT NULL AND b_src.integrated_risk_score IS NOT NULL
    AND s_src.integrated_risk_score<b_src.integrated_risk_score-0.00000001)
   OR (s_src.synthetic_merchant_risk_proxy IS NOT NULL AND b_src.synthetic_merchant_risk_proxy IS NOT NULL
    AND s_src.synthetic_merchant_risk_proxy<b_src.synthetic_merchant_risk_proxy-0.00000001)
   OR (s_src.schedule_adjusted_comparative_expected_loss_amount IS NOT NULL AND s_src.path_weighted_ead_amount>0
    AND b_src.schedule_adjusted_comparative_expected_loss_amount IS NOT NULL AND b_src.path_weighted_ead_amount>0
    AND s_src.schedule_adjusted_comparative_expected_loss_amount/s_src.path_weighted_ead_amount
       <b_src.schedule_adjusted_comparative_expected_loss_amount/b_src.path_weighted_ead_amount-0.00000001)
 ) AS expected_source_risk_improvement_violation_flag,
 (s_src.annualized_risk_adjusted_return_rate IS NOT NULL
  AND b_src.annualized_risk_adjusted_return_rate IS NOT NULL
  AND s_src.annualized_risk_adjusted_return_rate>b_src.annualized_risk_adjusted_return_rate+0.00000001)
   AS expected_source_return_improvement_violation_flag,
 (s.expected_strategy_outcome_rank<b.expected_strategy_outcome_rank)
   AS expected_strategy_access_improvement_violation_flag,
 (s.expected_feasibility_rank<b.expected_feasibility_rank)
   AS expected_strategy_feasibility_improvement_violation_flag,
 (
   s.expected_strategy_outcome_code=b.expected_strategy_outcome_code
   AND s.expected_selected_candidate_template_code IS NOT DISTINCT FROM b.expected_selected_candidate_template_code
   AND abs(s.expected_selected_exposure_amount-b.expected_selected_exposure_amount)<=0.01
   AND s.associated_servicing_treatment_code IS NOT DISTINCT FROM b.associated_servicing_treatment_code
   AND s.expected_selected_payment_burden_rate IS NOT NULL AND b.expected_selected_payment_burden_rate IS NOT NULL
   AND s.expected_selected_payment_burden_rate<b.expected_selected_payment_burden_rate-0.00000001
 ) AS expected_comparable_payment_burden_improvement_violation_flag,
 (
   s.expected_strategy_outcome_code=b.expected_strategy_outcome_code
   AND s.expected_selected_candidate_template_code IS NOT DISTINCT FROM b.expected_selected_candidate_template_code
   AND abs(s.expected_selected_exposure_amount-b.expected_selected_exposure_amount)<=0.01
   AND s.associated_servicing_treatment_code IS NOT DISTINCT FROM b.associated_servicing_treatment_code
   AND s.associated_servicing_burden_units IS NOT NULL AND b.associated_servicing_burden_units IS NOT NULL
   AND s.associated_servicing_burden_units<b.associated_servicing_burden_units-0.000001
 ) AS expected_comparable_servicing_burden_improvement_violation_flag,
 (
   s.expected_strategy_outcome_rank>b.expected_strategy_outcome_rank
   OR s.expected_feasibility_rank>b.expected_feasibility_rank
   OR s.expected_selected_exposure_amount<b.expected_selected_exposure_amount-0.01
   OR (b.expected_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
       AND s.expected_strategy_outcome_code NOT IN ('ACCESS_SELECTED','CONTROLLED_REVIEW'))
 ) AS expected_strategy_restriction_flag,
 (coalesce(s.associated_servicing_burden_units,0.000000::numeric)
   <coalesce(b.associated_servicing_burden_units,0.000000::numeric)-0.000001)
   AS expected_absolute_workload_reduction_flag
FROM tmp_eval_application_expected b
JOIN tmp_eval_application_expected s
  ON s.module1_run_id=b.module1_run_id
 AND s.merchant_application_id=b.merchant_application_id
 AND s.strategy_profile_code=b.strategy_profile_code
 AND s.scenario_code='RECESSION_ENERGY'
JOIN msbf_m2.portfolio_strategy_application_source_snapshot b_src
  ON b_src.module1_run_id=b.module1_run_id AND b_src.scenario_id=b.scenario_id
 AND b_src.merchant_application_id=b.merchant_application_id
JOIN msbf_m2.portfolio_strategy_application_source_snapshot s_src
  ON s_src.module1_run_id=s.module1_run_id AND s_src.scenario_id=s.scenario_id
 AND s_src.merchant_application_id=s.merchant_application_id
WHERE b.scenario_code='BASELINE';

CREATE UNIQUE INDEX tmp_eval_app_stress_flags_u1 ON tmp_eval_app_stress_flags
(module1_run_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_app_stress_flags;

CREATE TEMP TABLE tmp_eval_application_reason_expected ON COMMIT DROP AS
WITH x AS
(
 SELECT
   a.module1_run_id,a.scenario_id,a.scenario_code,a.merchant_application_id,a.strategy_profile_code,
   a.expected_strategy_outcome_code,a.expected_strategy_evidence_status,
   CASE WHEN a.scenario_code='RECESSION_ENERGY'
        THEN f.expected_source_risk_improvement_violation_flag ELSE FALSE END
     AS expected_source_risk_improvement_violation_flag,
   CASE WHEN a.scenario_code='RECESSION_ENERGY'
        THEN f.expected_source_return_improvement_violation_flag ELSE FALSE END
     AS expected_source_return_improvement_violation_flag,
   CASE WHEN a.scenario_code='RECESSION_ENERGY'
        THEN f.expected_strategy_access_improvement_violation_flag ELSE FALSE END
     AS expected_strategy_access_improvement_violation_flag,
   CASE WHEN a.scenario_code='RECESSION_ENERGY'
        THEN f.expected_strategy_feasibility_improvement_violation_flag ELSE FALSE END
     AS expected_strategy_feasibility_improvement_violation_flag,
   CASE WHEN a.scenario_code='RECESSION_ENERGY'
        THEN f.expected_comparable_payment_burden_improvement_violation_flag ELSE FALSE END
     AS expected_comparable_payment_burden_improvement_violation_flag,
   CASE WHEN a.scenario_code='RECESSION_ENERGY'
        THEN f.expected_comparable_servicing_burden_improvement_violation_flag ELSE FALSE END
     AS expected_comparable_servicing_burden_improvement_violation_flag,
   CASE WHEN a.scenario_code='RECESSION_ENERGY'
        THEN f.expected_strategy_restriction_flag ELSE FALSE END
     AS expected_strategy_restriction_flag,
   CASE WHEN a.scenario_code='RECESSION_ENERGY'
        THEN f.expected_absolute_workload_reduction_flag ELSE FALSE END
     AS expected_absolute_workload_reduction_flag,
   CASE WHEN a.scenario_code='RECESSION_ENERGY' THEN NOT(
        f.expected_source_risk_improvement_violation_flag
     OR f.expected_source_return_improvement_violation_flag
     OR f.expected_strategy_access_improvement_violation_flag
     OR f.expected_strategy_feasibility_improvement_violation_flag
     OR f.expected_comparable_payment_burden_improvement_violation_flag
     OR f.expected_comparable_servicing_burden_improvement_violation_flag)
        ELSE TRUE END AS expected_stress_nonimprovement_pass_flag
 FROM tmp_eval_application_expected a
 JOIN tmp_eval_app_stress_flags f
   ON f.module1_run_id=a.module1_run_id
  AND f.merchant_application_id=a.merchant_application_id
  AND f.strategy_profile_code=a.strategy_profile_code
)
SELECT
 x.*,
 CASE
  WHEN x.expected_strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY'
    THEN 'M2_11_REASON_SOURCE_GRAIN_OR_LINEAGE_ERROR'
  WHEN x.expected_strategy_outcome_code='NO_ACCESS_POLICY_DECLINE'
    THEN 'M2_11_REASON_POLICY_DECLINE_PRESERVED'
  WHEN x.expected_strategy_outcome_code='NO_ACCESS_INSUFFICIENT_EVIDENCE'
    THEN 'M2_11_REASON_INSUFFICIENT_EVIDENCE_PRESERVED'
  WHEN x.expected_strategy_outcome_code='NO_ACCESS_NO_FEASIBLE_CANDIDATE'
    THEN 'M2_11_REASON_NO_FEASIBLE_CANDIDATE'
  WHEN x.expected_strategy_outcome_code='NO_ACCESS_STRATEGY_RESTRICTION'
    THEN 'M2_11_REASON_NO_ACCESS_STRATEGY_RESTRICTION'
  WHEN x.expected_strategy_outcome_code='CONTROLLED_REVIEW'
    THEN 'M2_11_REASON_CONTROLLED_REVIEW_REQUIRED'
  ELSE CASE x.strategy_profile_code
    WHEN 'ACCESS_EXPANSION' THEN 'M2_11_REASON_ACCESS_EXPANSION_SELECTED'
    WHEN 'PRICE_FOR_RISK' THEN 'M2_11_REASON_PRICE_FOR_RISK_SELECTED'
    WHEN 'PAYMENT_BURDEN_RELIEF' THEN 'M2_11_REASON_PAYMENT_BURDEN_RELIEF_SELECTED'
    WHEN 'LOSS_CONTAINMENT' THEN 'M2_11_REASON_LOSS_CONTAINMENT_SELECTED'
    WHEN 'PROFITABILITY_DISCIPLINE' THEN 'M2_11_REASON_PROFITABILITY_DISCIPLINE_SELECTED'
    WHEN 'BALANCED_FRONTIER' THEN 'M2_11_REASON_BALANCED_FRONTIER_SELECTED'
    ELSE 'M2_11_REASON_BASELINE_REPLAY_MATCH'
  END
 END AS expected_primary_reason_code,
 to_jsonb(array_remove(ARRAY[
   CASE WHEN x.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
        THEN 'M2_11_REASON_BASELINE_REPLAY_MATCH' END,
   CASE WHEN x.expected_strategy_evidence_status='PARTIAL'
        THEN 'M2_11_REASON_SOURCE_EVIDENCE_PARTIAL' END,
   CASE WHEN x.expected_strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY'
        THEN 'M2_11_REASON_SOURCE_GRAIN_OR_LINEAGE_ERROR' END,
   CASE WHEN x.expected_strategy_outcome_code='NO_ACCESS_POLICY_DECLINE'
        THEN 'M2_11_REASON_POLICY_DECLINE_PRESERVED' END,
   CASE WHEN x.expected_strategy_outcome_code='NO_ACCESS_INSUFFICIENT_EVIDENCE'
        THEN 'M2_11_REASON_INSUFFICIENT_EVIDENCE_PRESERVED' END,
   CASE WHEN x.expected_strategy_outcome_code='NO_ACCESS_NO_FEASIBLE_CANDIDATE'
        THEN 'M2_11_REASON_NO_FEASIBLE_CANDIDATE' END,
   CASE WHEN x.expected_strategy_outcome_code='NO_ACCESS_STRATEGY_RESTRICTION'
        THEN 'M2_11_REASON_NO_ACCESS_STRATEGY_RESTRICTION' END,
   CASE WHEN x.expected_strategy_outcome_code='CONTROLLED_REVIEW'
        THEN 'M2_11_REASON_CONTROLLED_REVIEW_REQUIRED' END,
   CASE WHEN x.expected_strategy_outcome_code='ACCESS_SELECTED' THEN CASE x.strategy_profile_code
     WHEN 'ACCESS_EXPANSION' THEN 'M2_11_REASON_ACCESS_EXPANSION_SELECTED'
     WHEN 'PRICE_FOR_RISK' THEN 'M2_11_REASON_PRICE_FOR_RISK_SELECTED'
     WHEN 'PAYMENT_BURDEN_RELIEF' THEN 'M2_11_REASON_PAYMENT_BURDEN_RELIEF_SELECTED'
     WHEN 'LOSS_CONTAINMENT' THEN 'M2_11_REASON_LOSS_CONTAINMENT_SELECTED'
     WHEN 'PROFITABILITY_DISCIPLINE' THEN 'M2_11_REASON_PROFITABILITY_DISCIPLINE_SELECTED'
     WHEN 'BALANCED_FRONTIER' THEN 'M2_11_REASON_BALANCED_FRONTIER_SELECTED'
     ELSE 'M2_11_REASON_BASELINE_REPLAY_MATCH' END END,
   CASE WHEN x.expected_strategy_restriction_flag
        THEN 'M2_11_REASON_STRESS_STRATEGY_RESTRICTION' END,
   CASE WHEN NOT x.expected_stress_nonimprovement_pass_flag
        THEN 'M2_11_REASON_STRESS_IMPROVEMENT_VIOLATION' END,
   CASE WHEN x.expected_stress_nonimprovement_pass_flag AND x.scenario_code='RECESSION_ENERGY'
        THEN 'M2_11_REASON_STRESS_SOURCE_NONIMPROVEMENT_PASS' END
 ]::text[],NULL)) AS expected_reason_codes
FROM x;

CREATE UNIQUE INDEX tmp_eval_application_reason_expected_u1
ON tmp_eval_application_reason_expected
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_application_reason_expected;

CREATE TEMP TABLE tmp_eval_application_adversity_expected ON COMMIT DROP AS
WITH h AS
(
 SELECT a.*,
   msbf_ctl.m2_11_hash_jsonb(
      to_jsonb(a)-'portfolio_adversity_order'-'portfolio_adverse_selected_flag'
                 -'primary_reason_code'-'reason_codes'-'row_hash'-'created_at'
   ) AS expected_adversity_tiebreak_hash
 FROM msbf_m2.application_portfolio_strategy_simulation a
 WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
), r AS
(
 SELECT h.*,
   row_number() OVER
   (
    PARTITION BY module1_run_id,merchant_application_id,strategy_profile_code
    ORDER BY hard_constraint_violation_count DESC,strategy_outcome_rank DESC,
      CASE strategy_evidence_status WHEN 'BLOCKED' THEN 3 WHEN 'PARTIAL' THEN 2 ELSE 1 END DESC,
      (selected_expected_loss_density IS NULL) DESC,selected_expected_loss_density DESC,
      (selected_risk_adjusted_contribution IS NULL) DESC,selected_risk_adjusted_contribution ASC,
      (selected_annualized_risk_adjusted_return IS NULL) DESC,selected_annualized_risk_adjusted_return ASC,
      (selected_payment_burden_rate IS NULL) DESC,selected_payment_burden_rate DESC,
      (associated_servicing_burden_units IS NULL) DESC,associated_servicing_burden_units DESC,
      CASE scenario_code WHEN 'RECESSION_ENERGY' THEN 1 ELSE 2 END,
      expected_adversity_tiebreak_hash
   )::smallint AS expected_portfolio_adversity_order
 FROM h
)
SELECT module1_run_id,scenario_id,scenario_code,merchant_application_id,strategy_profile_code,
       expected_adversity_tiebreak_hash,expected_portfolio_adversity_order,
       (expected_portfolio_adversity_order=1) AS expected_portfolio_adverse_selected_flag
FROM r;

CREATE UNIQUE INDEX tmp_eval_application_adversity_expected_u1 ON tmp_eval_application_adversity_expected
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_application_adversity_expected;

/* ============================================================================
Section 5 — Independent scope aggregation and scope-score reconstruction
============================================================================ */
CREATE TEMP TABLE tmp_scope_validation_application_rows ON COMMIT DROP AS
SELECT 'BASELINE'::text AS reporting_scope_code,a.*
FROM msbf_m2.application_portfolio_strategy_simulation a
WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
  AND a.scenario_code='BASELINE'
UNION ALL
SELECT 'RECESSION_ENERGY'::text,a.*
FROM msbf_m2.application_portfolio_strategy_simulation a
WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
  AND a.scenario_code='RECESSION_ENERGY'
UNION ALL
SELECT 'PORTFOLIO'::text,a.*
FROM msbf_m2.application_portfolio_strategy_simulation a
WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
  AND a.portfolio_adverse_selected_flag;
CREATE INDEX tmp_scope_validation_application_rows_i1 ON tmp_scope_validation_application_rows
(module1_run_id,reporting_scope_code,strategy_profile_code,merchant_application_id);
ANALYZE tmp_scope_validation_application_rows;

CREATE TEMP TABLE tmp_scope_validation_account_rows ON COMMIT DROP AS
SELECT 'BASELINE'::text AS reporting_scope_code,a.*
FROM msbf_m2.account_servicing_strategy_simulation a
WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
  AND a.scenario_code='BASELINE'
UNION ALL
SELECT 'RECESSION_ENERGY'::text,a.*
FROM msbf_m2.account_servicing_strategy_simulation a
WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
  AND a.scenario_code='RECESSION_ENERGY'
UNION ALL
SELECT 'PORTFOLIO'::text,a.*
FROM msbf_m2.account_servicing_strategy_simulation a
WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
  AND a.portfolio_adverse_selected_flag;
CREATE INDEX tmp_scope_validation_account_rows_i1 ON tmp_scope_validation_account_rows
(module1_run_id,reporting_scope_code,strategy_profile_code,merchant_application_id);
ANALYZE tmp_scope_validation_account_rows;

CREATE TEMP TABLE tmp_scope_validation_application_aggregate ON COMMIT DROP AS
SELECT
 module1_run_id,strategy_profile_code,reporting_scope_code,
 count(*)::bigint AS application_rows,
 count(*) FILTER(WHERE access_selected_flag)::bigint AS access_selected_rows,
 count(*) FILTER(WHERE controlled_review_flag)::bigint AS controlled_review_rows,
 count(*) FILTER(WHERE strategy_outcome_code='NO_ACCESS_STRATEGY_RESTRICTION')::bigint AS strategy_restriction_rows,
 count(*) FILTER(WHERE strategy_outcome_code='NO_ACCESS_NO_FEASIBLE_CANDIDATE')::bigint AS no_feasible_candidate_rows,
 count(*) FILTER(WHERE strategy_outcome_code='NO_ACCESS_INSUFFICIENT_EVIDENCE')::bigint AS insufficient_evidence_rows,
 count(*) FILTER(WHERE strategy_outcome_code='NO_ACCESS_POLICY_DECLINE')::bigint AS policy_decline_rows,
 count(*) FILTER(WHERE strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY')::bigint AS blocked_source_rows,
 sum(hard_constraint_violation_count)::bigint AS hard_constraint_violation_count,
 count(*) FILTER(WHERE strategy_evidence_status='COMPLETE')::bigint AS complete_evidence_rows,
 count(*) FILTER(WHERE strategy_evidence_status='PARTIAL')::bigint AS partial_evidence_rows,
 count(*) FILTER(WHERE strategy_evidence_status='BLOCKED')::bigint AS blocked_evidence_rows,
 count(*) FILTER(WHERE source_risk_improvement_violation_flag)::bigint AS source_risk_improvement_violation_count,
 count(*) FILTER(WHERE source_return_improvement_violation_flag)::bigint AS source_return_improvement_violation_count,
 count(*) FILTER(WHERE strategy_access_improvement_violation_flag)::bigint AS strategy_access_improvement_violation_count,
 count(*) FILTER(WHERE strategy_feasibility_improvement_violation_flag)::bigint AS strategy_feasibility_improvement_violation_count,
 count(*) FILTER(WHERE comparable_payment_burden_improvement_violation_flag)::bigint AS comparable_payment_burden_improvement_violation_count,
 count(*) FILTER(WHERE comparable_servicing_burden_improvement_violation_flag)::bigint AS comparable_servicing_burden_improvement_violation_count,
 count(*) FILTER(WHERE strategy_restriction_flag)::bigint AS stress_strategy_restriction_rows,
 count(*) FILTER(WHERE absolute_workload_reduction_flag)::bigint AS absolute_workload_reduction_rows,
 round(count(*) FILTER(WHERE access_selected_flag)::numeric/NULLIF(count(*),0),10)::numeric(18,10) AS access_rate,
 coalesce(sum(selected_exposure_amount),0)::numeric(24,2) AS selected_exposure_amount,
 coalesce(sum(selected_finance_charge_amount),0)::numeric(24,2) AS finance_charge_amount,
 coalesce(sum(selected_expected_loss_amount),0)::numeric(24,2) AS expected_loss_amount,
 CASE WHEN sum(selected_exposure_amount)=0 THEN NULL
      ELSE round(sum(selected_expected_loss_amount)/sum(selected_exposure_amount),10)::numeric(18,10) END AS expected_loss_density,
 coalesce(sum(selected_risk_adjusted_contribution),0)::numeric(24,2) AS risk_adjusted_contribution,
 CASE WHEN sum(selected_exposure_amount)=0 THEN NULL
      WHEN count(*) FILTER(WHERE selected_exposure_amount>0 AND selected_annualized_risk_adjusted_return IS NULL)>0 THEN NULL
      ELSE round(sum(selected_exposure_amount*selected_annualized_risk_adjusted_return)/sum(selected_exposure_amount),10)::numeric(18,10) END AS annualized_risk_adjusted_return,
 CASE WHEN sum(selected_exposure_amount)=0 THEN NULL
      WHEN count(*) FILTER(WHERE selected_exposure_amount>0 AND selected_payment_burden_rate IS NULL)>0 THEN NULL
      ELSE round(sum(selected_exposure_amount*selected_payment_burden_rate)/sum(selected_exposure_amount),10)::numeric(18,10) END AS payment_burden_rate,
 md5(string_agg(row_hash,'|' ORDER BY merchant_application_id,scenario_id,row_hash)) AS application_simulation_set_hash
FROM tmp_scope_validation_application_rows
GROUP BY module1_run_id,strategy_profile_code,reporting_scope_code;

/* PORTFOLIO comparison counters represent the complete matched 750-pair panel. */
UPDATE tmp_scope_validation_application_aggregate a
SET source_risk_improvement_violation_count=x.source_risk_improvement_violation_count,
    source_return_improvement_violation_count=x.source_return_improvement_violation_count,
    strategy_access_improvement_violation_count=x.strategy_access_improvement_violation_count,
    strategy_feasibility_improvement_violation_count=x.strategy_feasibility_improvement_violation_count,
    comparable_payment_burden_improvement_violation_count=x.comparable_payment_burden_improvement_violation_count,
    comparable_servicing_burden_improvement_violation_count=x.comparable_servicing_burden_improvement_violation_count,
    stress_strategy_restriction_rows=x.stress_strategy_restriction_rows,
    absolute_workload_reduction_rows=x.absolute_workload_reduction_rows
FROM
(
 SELECT module1_run_id,strategy_profile_code,
   count(*) FILTER(WHERE expected_source_risk_improvement_violation_flag)::bigint AS source_risk_improvement_violation_count,
   count(*) FILTER(WHERE expected_source_return_improvement_violation_flag)::bigint AS source_return_improvement_violation_count,
   count(*) FILTER(WHERE expected_strategy_access_improvement_violation_flag)::bigint AS strategy_access_improvement_violation_count,
   count(*) FILTER(WHERE expected_strategy_feasibility_improvement_violation_flag)::bigint AS strategy_feasibility_improvement_violation_count,
   count(*) FILTER(WHERE expected_comparable_payment_burden_improvement_violation_flag)::bigint AS comparable_payment_burden_improvement_violation_count,
   count(*) FILTER(WHERE expected_comparable_servicing_burden_improvement_violation_flag)::bigint AS comparable_servicing_burden_improvement_violation_count,
   count(*) FILTER(WHERE expected_strategy_restriction_flag)::bigint AS stress_strategy_restriction_rows,
   count(*) FILTER(WHERE expected_absolute_workload_reduction_flag)::bigint AS absolute_workload_reduction_rows
 FROM tmp_eval_app_stress_flags
 GROUP BY module1_run_id,strategy_profile_code
) x
WHERE a.module1_run_id=x.module1_run_id
  AND a.strategy_profile_code=x.strategy_profile_code
  AND a.reporting_scope_code='PORTFOLIO';
CREATE UNIQUE INDEX tmp_scope_validation_application_aggregate_u1 ON tmp_scope_validation_application_aggregate
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_validation_application_aggregate;

CREATE TEMP TABLE tmp_scope_validation_account_aggregate ON COMMIT DROP AS
SELECT module1_run_id,strategy_profile_code,reporting_scope_code,
 count(*)::bigint AS servicing_account_rows,
 count(DISTINCT merchant_application_id)::bigint AS servicing_distinct_application_rows,
 coalesce(sum(strategy_servicing_burden_units),0)::numeric(24,6) AS servicing_burden_units,
 md5(string_agg(row_hash,'|' ORDER BY merchant_application_id,scenario_id,row_hash)) AS account_simulation_set_hash
FROM tmp_scope_validation_account_rows
GROUP BY module1_run_id,strategy_profile_code,reporting_scope_code;
CREATE UNIQUE INDEX tmp_scope_validation_account_aggregate_u1 ON tmp_scope_validation_account_aggregate
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_validation_account_aggregate;

CREATE TEMP TABLE tmp_scope_validation_summary_raw ON COMMIT DROP AS
SELECT a.*,
 (a.source_risk_improvement_violation_count+a.source_return_improvement_violation_count
  +a.strategy_access_improvement_violation_count+a.strategy_feasibility_improvement_violation_count
  +a.comparable_payment_burden_improvement_violation_count
  +a.comparable_servicing_burden_improvement_violation_count)::bigint AS stress_improvement_violation_count,
 x.servicing_account_rows,x.servicing_distinct_application_rows,x.servicing_burden_units,x.account_simulation_set_hash,
 'ACCEPTED_OPERATIONAL_ACCOUNTS_ONLY'::text AS servicing_burden_coverage_code,
 FALSE AS new_access_servicing_burden_estimated_flag,
 CASE WHEN a.blocked_source_rows>0 THEN 'BLOCKED'
      WHEN a.partial_evidence_rows>0 OR a.insufficient_evidence_rows>0 OR a.controlled_review_rows>0 THEN 'PARTIAL'
      ELSE 'COMPLETE' END AS strategy_evidence_status
FROM tmp_scope_validation_application_aggregate a
JOIN tmp_scope_validation_account_aggregate x
 USING(module1_run_id,strategy_profile_code,reporting_scope_code);
CREATE UNIQUE INDEX tmp_scope_validation_summary_raw_u1 ON tmp_scope_validation_summary_raw
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_validation_summary_raw;

CREATE TEMP TABLE tmp_scope_validation_summary_normalized ON COMMIT DROP AS
WITH b AS
(
 SELECT r.*,p.selected_exposure_direction,
  p.access_rate_weight,p.selected_exposure_weight,p.finance_charge_weight,
  p.expected_loss_density_weight,p.risk_adjusted_contribution_weight,
  p.annualized_return_weight,p.servicing_burden_weight,p.payment_burden_weight,
  p.scope_domain_weight_total,p.scope_scoring_applicable_flag,
  min(access_rate) OVER w AS access_min,max(access_rate) OVER w AS access_max,
  min(selected_exposure_amount) OVER w AS exposure_min,max(selected_exposure_amount) OVER w AS exposure_max,
  min(finance_charge_amount) OVER w AS finance_min,max(finance_charge_amount) OVER w AS finance_max,
  min(expected_loss_density) OVER w AS loss_min,max(expected_loss_density) OVER w AS loss_max,
  min(risk_adjusted_contribution) OVER w AS contribution_min,max(risk_adjusted_contribution) OVER w AS contribution_max,
  min(annualized_risk_adjusted_return) OVER w AS return_min,max(annualized_risk_adjusted_return) OVER w AS return_max,
  min(servicing_burden_units) OVER w AS servicing_min,max(servicing_burden_units) OVER w AS servicing_max,
  min(payment_burden_rate) OVER w AS payment_min,max(payment_burden_rate) OVER w AS payment_max
 FROM tmp_scope_validation_summary_raw r
 JOIN msbf_m2.portfolio_strategy_profile p USING(module1_run_id,strategy_profile_code)
 WINDOW w AS(PARTITION BY r.module1_run_id,r.reporting_scope_code)
), n AS
(
 SELECT b.*,
  round(CASE WHEN access_max=access_min THEN 1 ELSE (access_rate-access_min)/(access_max-access_min) END,10)::numeric(18,10) AS access_norm,
  round(CASE WHEN exposure_max=exposure_min THEN 1
             WHEN selected_exposure_direction='MINIMIZE' THEN (exposure_max-selected_exposure_amount)/(exposure_max-exposure_min)
             ELSE (selected_exposure_amount-exposure_min)/(exposure_max-exposure_min) END,10)::numeric(18,10) AS exposure_norm,
  round(CASE WHEN finance_max=finance_min THEN 1 ELSE (finance_charge_amount-finance_min)/(finance_max-finance_min) END,10)::numeric(18,10) AS finance_norm,
  CASE WHEN expected_loss_density IS NULL THEN NULL WHEN loss_max=loss_min THEN 1
       ELSE round((loss_max-expected_loss_density)/(loss_max-loss_min),10)::numeric(18,10) END AS loss_norm,
  round(CASE WHEN contribution_max=contribution_min THEN 1 ELSE (risk_adjusted_contribution-contribution_min)/(contribution_max-contribution_min) END,10)::numeric(18,10) AS contribution_norm,
  CASE WHEN annualized_risk_adjusted_return IS NULL THEN NULL WHEN return_max=return_min THEN 1
       ELSE round((annualized_risk_adjusted_return-return_min)/(return_max-return_min),10)::numeric(18,10) END AS return_norm,
  round(CASE WHEN servicing_max=servicing_min THEN 1 ELSE (servicing_max-servicing_burden_units)/(servicing_max-servicing_min) END,10)::numeric(18,10) AS servicing_norm,
  CASE WHEN payment_burden_rate IS NULL THEN NULL WHEN payment_max=payment_min THEN 1
       ELSE round((payment_max-payment_burden_rate)/(payment_max-payment_min),10)::numeric(18,10) END AS payment_norm
 FROM b
)
SELECT n.*,
 round(access_norm*access_rate_weight,12)::numeric(22,12) AS access_weighted,
 round(exposure_norm*selected_exposure_weight,12)::numeric(22,12) AS exposure_weighted,
 round(finance_norm*finance_charge_weight,12)::numeric(22,12) AS finance_weighted,
 CASE WHEN expected_loss_density_weight=0 THEN 0::numeric(22,12)
      WHEN loss_norm IS NULL THEN NULL
      ELSE round(loss_norm*expected_loss_density_weight,12)::numeric(22,12) END AS loss_weighted,
 round(contribution_norm*risk_adjusted_contribution_weight,12)::numeric(22,12) AS contribution_weighted,
 CASE WHEN annualized_return_weight=0 THEN 0::numeric(22,12)
      WHEN return_norm IS NULL THEN NULL
      ELSE round(return_norm*annualized_return_weight,12)::numeric(22,12) END AS return_weighted,
 round(servicing_norm*servicing_burden_weight,12)::numeric(22,12) AS servicing_weighted,
 CASE WHEN payment_burden_weight=0 THEN 0::numeric(22,12)
      WHEN payment_norm IS NULL THEN NULL
      ELSE round(payment_norm*payment_burden_weight,12)::numeric(22,12) END AS payment_weighted
FROM n;
CREATE UNIQUE INDEX tmp_scope_validation_summary_normalized_u1 ON tmp_scope_validation_summary_normalized
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_validation_summary_normalized;

CREATE TEMP TABLE tmp_scope_validation_summary_expected ON COMMIT DROP AS
SELECT
 n.module1_run_id,n.strategy_profile_code,n.reporting_scope_code,
 n.application_rows,n.access_selected_rows,n.controlled_review_rows,n.strategy_restriction_rows,
 n.no_feasible_candidate_rows,n.insufficient_evidence_rows,n.policy_decline_rows,n.blocked_source_rows,
 n.hard_constraint_violation_count,n.complete_evidence_rows,n.partial_evidence_rows,n.blocked_evidence_rows,
 n.source_risk_improvement_violation_count,n.source_return_improvement_violation_count,
 n.strategy_access_improvement_violation_count,n.strategy_feasibility_improvement_violation_count,
 n.comparable_payment_burden_improvement_violation_count,n.comparable_servicing_burden_improvement_violation_count,
 n.stress_improvement_violation_count,n.stress_strategy_restriction_rows,n.absolute_workload_reduction_rows,
 n.servicing_account_rows,n.servicing_distinct_application_rows,
 (n.stress_improvement_violation_count=0) AS stress_nonimprovement_pass_flag,
 n.access_rate,n.selected_exposure_amount,n.finance_charge_amount,n.expected_loss_amount,n.expected_loss_density,
 n.risk_adjusted_contribution,n.annualized_risk_adjusted_return,n.payment_burden_rate,n.servicing_burden_units,
 n.servicing_burden_coverage_code,n.new_access_servicing_burden_estimated_flag,n.strategy_evidence_status,
 (n.access_rate IS NOT NULL AND n.finance_charge_amount IS NOT NULL AND n.expected_loss_density IS NOT NULL
  AND n.risk_adjusted_contribution IS NOT NULL AND n.annualized_risk_adjusted_return IS NOT NULL
  AND n.servicing_burden_units IS NOT NULL AND n.payment_burden_rate IS NOT NULL) AS frontier_metrics_complete_flag,
 n.access_norm AS access_rate_normalized_value,n.access_weighted AS access_rate_weighted_contribution,
 n.exposure_norm AS selected_exposure_amount_normalized_value,n.exposure_weighted AS selected_exposure_amount_weighted_contribution,
 n.finance_norm AS finance_charge_amount_normalized_value,n.finance_weighted AS finance_charge_amount_weighted_contribution,
 n.loss_norm AS expected_loss_density_normalized_value,n.loss_weighted AS expected_loss_density_weighted_contribution,
 n.contribution_norm AS risk_adjusted_contribution_normalized_value,n.contribution_weighted AS risk_adjusted_contribution_weighted_contribution,
 n.return_norm AS annualized_risk_adjusted_return_normalized_value,n.return_weighted AS annualized_risk_adjusted_return_weighted_contribution,
 n.servicing_norm AS servicing_burden_units_normalized_value,n.servicing_weighted AS servicing_burden_units_weighted_contribution,
 n.payment_norm AS payment_burden_rate_normalized_value,n.payment_weighted AS payment_burden_rate_weighted_contribution,
 CASE WHEN n.strategy_profile_code='BASELINE_REPLAY' OR NOT n.scope_scoring_applicable_flag THEN NULL::numeric(22,12)
      WHEN n.scope_domain_weight_total=0 THEN NULL::numeric(22,12)
      WHEN (n.expected_loss_density_weight>0 AND n.loss_weighted IS NULL)
        OR (n.annualized_return_weight>0 AND n.return_weighted IS NULL)
        OR (n.payment_burden_weight>0 AND n.payment_weighted IS NULL) THEN NULL::numeric(22,12)
      ELSE round((n.access_weighted+n.exposure_weighted+n.finance_weighted+n.loss_weighted
                  +n.contribution_weighted+n.return_weighted+n.servicing_weighted+n.payment_weighted)
                 /n.scope_domain_weight_total,12)::numeric(22,12) END AS scope_strategy_score,
 n.application_simulation_set_hash,n.account_simulation_set_hash
FROM tmp_scope_validation_summary_normalized n;
CREATE UNIQUE INDEX tmp_scope_validation_summary_expected_u1 ON tmp_scope_validation_summary_expected
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_validation_summary_expected;

/* Target-typed exact projection of all 59 immutable strategy-summary fields. */
CREATE TEMP TABLE tmp_scope_validation_summary_exact_expected ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_summary WITH NO DATA;

INSERT INTO tmp_scope_validation_summary_exact_expected
(
    module1_run_id,
    strategy_profile_code,
    reporting_scope_code,
    application_rows,
    access_selected_rows,
    controlled_review_rows,
    strategy_restriction_rows,
    no_feasible_candidate_rows,
    insufficient_evidence_rows,
    policy_decline_rows,
    blocked_source_rows,
    hard_constraint_violation_count,
    complete_evidence_rows,
    partial_evidence_rows,
    blocked_evidence_rows,
    source_risk_improvement_violation_count,
    source_return_improvement_violation_count,
    strategy_access_improvement_violation_count,
    strategy_feasibility_improvement_violation_count,
    comparable_payment_burden_improvement_violation_count,
    comparable_servicing_burden_improvement_violation_count,
    stress_improvement_violation_count,
    stress_strategy_restriction_rows,
    absolute_workload_reduction_rows,
    servicing_account_rows,
    servicing_distinct_application_rows,
    stress_nonimprovement_pass_flag,
    access_rate,
    selected_exposure_amount,
    finance_charge_amount,
    expected_loss_amount,
    expected_loss_density,
    risk_adjusted_contribution,
    annualized_risk_adjusted_return,
    payment_burden_rate,
    servicing_burden_units,
    servicing_burden_coverage_code,
    new_access_servicing_burden_estimated_flag,
    strategy_evidence_status,
    frontier_metrics_complete_flag,
    access_rate_normalized_value,
    access_rate_weighted_contribution,
    selected_exposure_amount_normalized_value,
    selected_exposure_amount_weighted_contribution,
    finance_charge_amount_normalized_value,
    finance_charge_amount_weighted_contribution,
    expected_loss_density_normalized_value,
    expected_loss_density_weighted_contribution,
    risk_adjusted_contribution_normalized_value,
    risk_adjusted_contribution_weighted_contribution,
    annualized_risk_adjusted_return_normalized_value,
    annualized_risk_adjusted_return_weighted_contribution,
    servicing_burden_units_normalized_value,
    servicing_burden_units_weighted_contribution,
    payment_burden_rate_normalized_value,
    payment_burden_rate_weighted_contribution,
    scope_strategy_score,
    application_simulation_set_hash,
    account_simulation_set_hash
)
SELECT
    module1_run_id,
    strategy_profile_code,
    reporting_scope_code,
    application_rows,
    access_selected_rows,
    controlled_review_rows,
    strategy_restriction_rows,
    no_feasible_candidate_rows,
    insufficient_evidence_rows,
    policy_decline_rows,
    blocked_source_rows,
    hard_constraint_violation_count,
    complete_evidence_rows,
    partial_evidence_rows,
    blocked_evidence_rows,
    source_risk_improvement_violation_count,
    source_return_improvement_violation_count,
    strategy_access_improvement_violation_count,
    strategy_feasibility_improvement_violation_count,
    comparable_payment_burden_improvement_violation_count,
    comparable_servicing_burden_improvement_violation_count,
    stress_improvement_violation_count,
    stress_strategy_restriction_rows,
    absolute_workload_reduction_rows,
    servicing_account_rows,
    servicing_distinct_application_rows,
    stress_nonimprovement_pass_flag,
    access_rate,
    selected_exposure_amount,
    finance_charge_amount,
    expected_loss_amount,
    expected_loss_density,
    risk_adjusted_contribution,
    annualized_risk_adjusted_return,
    payment_burden_rate,
    servicing_burden_units,
    servicing_burden_coverage_code,
    new_access_servicing_burden_estimated_flag,
    strategy_evidence_status,
    frontier_metrics_complete_flag,
    access_rate_normalized_value,
    access_rate_weighted_contribution,
    selected_exposure_amount_normalized_value,
    selected_exposure_amount_weighted_contribution,
    finance_charge_amount_normalized_value,
    finance_charge_amount_weighted_contribution,
    expected_loss_density_normalized_value,
    expected_loss_density_weighted_contribution,
    risk_adjusted_contribution_normalized_value,
    risk_adjusted_contribution_weighted_contribution,
    annualized_risk_adjusted_return_normalized_value,
    annualized_risk_adjusted_return_weighted_contribution,
    servicing_burden_units_normalized_value,
    servicing_burden_units_weighted_contribution,
    payment_burden_rate_normalized_value,
    payment_burden_rate_weighted_contribution,
    scope_strategy_score,
    application_simulation_set_hash,
    account_simulation_set_hash
FROM tmp_scope_validation_summary_expected
ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code;

CREATE UNIQUE INDEX tmp_scope_validation_summary_exact_expected_u1
ON tmp_scope_validation_summary_exact_expected
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_validation_summary_exact_expected;

/* ============================================================================
Section 6 — Independent Pareto, governance, comparison, and contract linkage
============================================================================ */
CREATE TEMP TABLE tmp_frontier_validation_eligible_base ON COMMIT DROP AS
SELECT s.*,
 (s.hard_constraint_violation_count=0 AND s.strategy_evidence_status<>'BLOCKED'
  AND s.frontier_metrics_complete_flag AND s.stress_improvement_violation_count=0) AS frontier_eligible_flag,
 CASE WHEN s.hard_constraint_violation_count<>0 THEN 'HARD_CONSTRAINT_VIOLATION'
      WHEN s.strategy_evidence_status='BLOCKED' THEN 'BLOCKED_EVIDENCE'
      WHEN NOT s.frontier_metrics_complete_flag THEN 'INCOMPLETE_FRONTIER_METRICS'
      WHEN s.stress_improvement_violation_count<>0 THEN 'STRESS_IMPROVEMENT_VIOLATION'
      ELSE NULL END AS frontier_ineligibility_code,
 CASE s.strategy_evidence_status WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END::smallint AS evidence_rank
FROM tmp_scope_validation_summary_expected s;
CREATE UNIQUE INDEX tmp_frontier_validation_eligible_base_u1 ON tmp_frontier_validation_eligible_base
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_frontier_validation_eligible_base;

CREATE TEMP TABLE tmp_frontier_validation_dominance_edge ON COMMIT DROP AS
SELECT a.module1_run_id,a.reporting_scope_code,
 a.strategy_profile_code AS dominator_strategy_profile_code,
 b.strategy_profile_code AS dominated_strategy_profile_code
FROM tmp_frontier_validation_eligible_base a
JOIN tmp_frontier_validation_eligible_base b
 ON b.module1_run_id=a.module1_run_id AND b.reporting_scope_code=a.reporting_scope_code
AND b.strategy_profile_code<>a.strategy_profile_code
WHERE a.frontier_eligible_flag AND b.frontier_eligible_flag
 AND a.access_rate>=b.access_rate-0.00000001
 AND a.finance_charge_amount>=b.finance_charge_amount-0.01
 AND a.expected_loss_density<=b.expected_loss_density+0.00000001
 AND a.risk_adjusted_contribution>=b.risk_adjusted_contribution-0.01
 AND a.annualized_risk_adjusted_return>=b.annualized_risk_adjusted_return-0.00000001
 AND a.servicing_burden_units<=b.servicing_burden_units+0.000001
 AND a.payment_burden_rate<=b.payment_burden_rate+0.00000001
 AND (a.access_rate>b.access_rate+0.00000001
   OR a.finance_charge_amount>b.finance_charge_amount+0.01
   OR a.expected_loss_density<b.expected_loss_density-0.00000001
   OR a.risk_adjusted_contribution>b.risk_adjusted_contribution+0.01
   OR a.annualized_risk_adjusted_return>b.annualized_risk_adjusted_return+0.00000001
   OR a.servicing_burden_units<b.servicing_burden_units-0.000001
   OR a.payment_burden_rate<b.payment_burden_rate-0.00000001);
CREATE UNIQUE INDEX tmp_frontier_validation_dominance_edge_u1 ON tmp_frontier_validation_dominance_edge
(module1_run_id,reporting_scope_code,dominator_strategy_profile_code,dominated_strategy_profile_code);
ANALYZE tmp_frontier_validation_dominance_edge;

CREATE TEMP TABLE tmp_frontier_validation_rank_work ON COMMIT DROP AS
SELECT module1_run_id,reporting_scope_code,strategy_profile_code,NULL::integer AS frontier_rank
FROM tmp_frontier_validation_eligible_base WHERE frontier_eligible_flag;
ALTER TABLE tmp_frontier_validation_rank_work ADD PRIMARY KEY(module1_run_id,reporting_scope_code,strategy_profile_code);
CREATE TEMP TABLE tmp_frontier_validation_rank_batch
(
 module1_run_id bigint NOT NULL,reporting_scope_code text NOT NULL,
 strategy_profile_code text NOT NULL,
 PRIMARY KEY(module1_run_id,reporting_scope_code,strategy_profile_code)
) ON COMMIT DROP;
DO $m211_frontier_rank$
DECLARE
    v_rank integer:=1;
    v_rows integer;
BEGIN
 LOOP
  TRUNCATE tmp_frontier_validation_rank_batch;
  INSERT INTO tmp_frontier_validation_rank_batch(module1_run_id,reporting_scope_code,strategy_profile_code)
  SELECT w.module1_run_id,w.reporting_scope_code,w.strategy_profile_code
  FROM tmp_frontier_validation_rank_work w
  WHERE w.frontier_rank IS NULL
    AND NOT EXISTS
    (
      SELECT 1 FROM tmp_frontier_validation_dominance_edge e
      JOIN tmp_frontier_validation_rank_work d
        ON d.module1_run_id=e.module1_run_id AND d.reporting_scope_code=e.reporting_scope_code
       AND d.strategy_profile_code=e.dominator_strategy_profile_code AND d.frontier_rank IS NULL
      WHERE e.module1_run_id=w.module1_run_id AND e.reporting_scope_code=w.reporting_scope_code
        AND e.dominated_strategy_profile_code=w.strategy_profile_code
    );
  GET DIAGNOSTICS v_rows=ROW_COUNT;
  EXIT WHEN v_rows=0;
  UPDATE tmp_frontier_validation_rank_work w SET frontier_rank=v_rank
  FROM tmp_frontier_validation_rank_batch b
  WHERE b.module1_run_id=w.module1_run_id AND b.reporting_scope_code=w.reporting_scope_code
    AND b.strategy_profile_code=w.strategy_profile_code;
  v_rank:=v_rank+1;
 END LOOP;
 IF EXISTS(SELECT 1 FROM tmp_frontier_validation_rank_work WHERE frontier_rank IS NULL) THEN
  RAISE EXCEPTION 'Program 215 independent Pareto ranking did not exhaust eligible strategies';
 END IF;
END;
$m211_frontier_rank$;

CREATE TEMP TABLE tmp_frontier_validation_governance ON COMMIT DROP AS
WITH b AS
(
 SELECT e.*,
  min(access_rate) FILTER(WHERE frontier_eligible_flag) OVER w AS access_min,
  max(access_rate) FILTER(WHERE frontier_eligible_flag) OVER w AS access_max,
  min(finance_charge_amount) FILTER(WHERE frontier_eligible_flag) OVER w AS finance_min,
  max(finance_charge_amount) FILTER(WHERE frontier_eligible_flag) OVER w AS finance_max,
  min(expected_loss_density) FILTER(WHERE frontier_eligible_flag) OVER w AS loss_min,
  max(expected_loss_density) FILTER(WHERE frontier_eligible_flag) OVER w AS loss_max,
  min(risk_adjusted_contribution) FILTER(WHERE frontier_eligible_flag) OVER w AS contribution_min,
  max(risk_adjusted_contribution) FILTER(WHERE frontier_eligible_flag) OVER w AS contribution_max,
  min(annualized_risk_adjusted_return) FILTER(WHERE frontier_eligible_flag) OVER w AS return_min,
  max(annualized_risk_adjusted_return) FILTER(WHERE frontier_eligible_flag) OVER w AS return_max,
  min(servicing_burden_units) FILTER(WHERE frontier_eligible_flag) OVER w AS servicing_min,
  max(servicing_burden_units) FILTER(WHERE frontier_eligible_flag) OVER w AS servicing_max,
  min(payment_burden_rate) FILTER(WHERE frontier_eligible_flag) OVER w AS payment_min,
  max(payment_burden_rate) FILTER(WHERE frontier_eligible_flag) OVER w AS payment_max
 FROM tmp_frontier_validation_eligible_base e
 WINDOW w AS(PARTITION BY e.module1_run_id,e.reporting_scope_code)
), n AS
(
 SELECT b.*,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN access_max=access_min THEN 1 ELSE round((access_rate-access_min)/(access_max-access_min),10)::numeric(18,10) END AS gov_access_norm,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN finance_max=finance_min THEN 1 ELSE round((finance_charge_amount-finance_min)/(finance_max-finance_min),10)::numeric(18,10) END AS gov_finance_norm,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN loss_max=loss_min THEN 1 ELSE round((loss_max-expected_loss_density)/(loss_max-loss_min),10)::numeric(18,10) END AS gov_loss_norm,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN contribution_max=contribution_min THEN 1 ELSE round((risk_adjusted_contribution-contribution_min)/(contribution_max-contribution_min),10)::numeric(18,10) END AS gov_contribution_norm,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN return_max=return_min THEN 1 ELSE round((annualized_risk_adjusted_return-return_min)/(return_max-return_min),10)::numeric(18,10) END AS gov_return_norm,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN servicing_max=servicing_min THEN 1 ELSE round((servicing_max-servicing_burden_units)/(servicing_max-servicing_min),10)::numeric(18,10) END AS gov_servicing_norm,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN payment_max=payment_min THEN 1 ELSE round((payment_max-payment_burden_rate)/(payment_max-payment_min),10)::numeric(18,10) END AS gov_payment_norm
 FROM b
)
SELECT n.*,
 CASE WHEN NOT frontier_eligible_flag THEN NULL
      ELSE round((gov_access_norm+gov_finance_norm+gov_loss_norm+gov_contribution_norm
                  +gov_return_norm+gov_servicing_norm+gov_payment_norm)/7.0,12)::numeric(22,12) END AS governance_balance_score
FROM n;
CREATE UNIQUE INDEX tmp_frontier_validation_governance_u1 ON tmp_frontier_validation_governance
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_frontier_validation_governance;

CREATE TEMP TABLE tmp_frontier_validation_priority ON COMMIT DROP AS
SELECT g.module1_run_id,g.reporting_scope_code,g.strategy_profile_code,
 row_number() OVER
 (
  PARTITION BY g.module1_run_id,g.reporting_scope_code
  ORDER BY g.evidence_rank,g.governance_balance_score DESC NULLS LAST,
   (g.risk_adjusted_contribution-b.risk_adjusted_contribution) DESC NULLS LAST,
   (g.expected_loss_density-b.expected_loss_density) ASC NULLS LAST,
   (g.access_rate-b.access_rate) DESC NULLS LAST,
   (g.payment_burden_rate-b.payment_burden_rate) ASC NULLS LAST,
   (g.servicing_burden_units-b.servicing_burden_units) ASC NULLS LAST,
   g.strategy_profile_code
 )::smallint AS governance_review_priority_rank
FROM tmp_frontier_validation_governance g
JOIN tmp_frontier_validation_rank_work r USING(module1_run_id,reporting_scope_code,strategy_profile_code)
JOIN tmp_frontier_validation_governance b
 ON b.module1_run_id=g.module1_run_id AND b.reporting_scope_code=g.reporting_scope_code
AND b.strategy_profile_code='BASELINE_REPLAY'
WHERE g.strategy_profile_code<>'BASELINE_REPLAY' AND r.frontier_rank=1
 AND g.hard_constraint_violation_count=0 AND g.strategy_evidence_status IN ('COMPLETE','PARTIAL')
 AND g.stress_improvement_violation_count=0 AND g.frontier_metrics_complete_flag;
CREATE UNIQUE INDEX tmp_frontier_validation_priority_u1 ON tmp_frontier_validation_priority
(module1_run_id,reporting_scope_code,strategy_profile_code);
ANALYZE tmp_frontier_validation_priority;

CREATE TEMP TABLE tmp_frontier_validation_expected ON COMMIT DROP AS
SELECT g.module1_run_id,g.strategy_profile_code,g.reporting_scope_code,
 g.frontier_eligible_flag,g.frontier_ineligibility_code,
 coalesce(db.dominated_by_count,0)::integer AS dominated_by_count,
 coalesce(dm.dominates_count,0)::integer AS dominates_count,
 (coalesce(r.frontier_rank,0)=1) AS non_dominated_flag,r.frontier_rank,
 g.evidence_rank,g.governance_balance_score,
 CASE WHEN g.strategy_profile_code='BASELINE_REPLAY' THEN 'CONTROL_REFERENCE'
      WHEN p.governance_review_priority_rank=1 THEN 'PRIMARY_GOVERNANCE_REVIEW'
      WHEN r.frontier_rank=1 THEN 'SECONDARY_FRONTIER_REVIEW'
      ELSE 'NO_FRONTIER_PRIORITY' END AS governance_review_priority_code,
 p.governance_review_priority_rank,
 coalesce(p.governance_review_priority_rank=1,FALSE) AS primary_governance_review_flag,
 g.gov_access_norm AS governance_access_rate_normalized_value,
 g.gov_finance_norm AS governance_finance_charge_amount_normalized_value,
 g.gov_loss_norm AS governance_expected_loss_density_normalized_value,
 g.gov_contribution_norm AS governance_risk_adjusted_contribution_normalized_value,
 g.gov_return_norm AS governance_annualized_risk_adjusted_return_normalized_value,
 g.gov_servicing_norm AS governance_servicing_burden_units_normalized_value,
 g.gov_payment_norm AS governance_payment_burden_rate_normalized_value,
 CASE
  WHEN g.stress_improvement_violation_count>0
    THEN 'M2_11_REASON_STRESS_IMPROVEMENT_VIOLATION'
  WHEN NOT g.frontier_eligible_flag AND g.strategy_evidence_status='BLOCKED'
    THEN 'M2_11_REASON_SOURCE_EVIDENCE_BLOCKED'
  WHEN NOT g.frontier_eligible_flag AND g.hard_constraint_violation_count>0
    THEN 'M2_11_REASON_NO_FEASIBLE_CANDIDATE'
  WHEN NOT g.frontier_eligible_flag
    THEN 'M2_11_REASON_ECONOMIC_EVIDENCE_BLOCKED'
  WHEN coalesce(r.frontier_rank,0)=1 THEN
    CASE WHEN p.governance_review_priority_rank=1
         THEN 'M2_11_REASON_GOVERNANCE_REVIEW_PRIORITY'
         ELSE 'M2_11_REASON_NONDOMINATED_FRONTIER' END
  ELSE 'M2_11_REASON_DOMINATED_STRATEGY'
 END AS expected_primary_reason_code,
 to_jsonb(array_remove(ARRAY[
   CASE WHEN g.stress_improvement_violation_count>0
        THEN 'M2_11_REASON_STRESS_IMPROVEMENT_VIOLATION' END,
   CASE WHEN NOT g.frontier_eligible_flag AND g.strategy_evidence_status='BLOCKED'
        THEN 'M2_11_REASON_SOURCE_EVIDENCE_BLOCKED' END,
   CASE WHEN NOT g.frontier_eligible_flag AND g.hard_constraint_violation_count>0
        THEN 'M2_11_REASON_NO_FEASIBLE_CANDIDATE' END,
   CASE WHEN NOT g.frontier_eligible_flag AND g.strategy_evidence_status<>'BLOCKED'
             AND g.hard_constraint_violation_count=0
        THEN 'M2_11_REASON_ECONOMIC_EVIDENCE_BLOCKED' END,
   CASE WHEN g.frontier_eligible_flag AND coalesce(r.frontier_rank,0)=1
        THEN 'M2_11_REASON_NONDOMINATED_FRONTIER' END,
   CASE WHEN g.frontier_eligible_flag AND coalesce(r.frontier_rank,0)>1
        THEN 'M2_11_REASON_DOMINATED_STRATEGY' END,
   CASE WHEN p.governance_review_priority_rank=1
        THEN 'M2_11_REASON_GOVERNANCE_REVIEW_PRIORITY' END
 ]::text[],NULL)) AS expected_reason_codes
FROM tmp_frontier_validation_governance g
LEFT JOIN tmp_frontier_validation_rank_work r USING(module1_run_id,reporting_scope_code,strategy_profile_code)
LEFT JOIN
 (SELECT module1_run_id,reporting_scope_code,dominated_strategy_profile_code AS strategy_profile_code,
   count(*)::integer AS dominated_by_count FROM tmp_frontier_validation_dominance_edge GROUP BY 1,2,3) db
 USING(module1_run_id,reporting_scope_code,strategy_profile_code)
LEFT JOIN
 (SELECT module1_run_id,reporting_scope_code,dominator_strategy_profile_code AS strategy_profile_code,
   count(*)::integer AS dominates_count FROM tmp_frontier_validation_dominance_edge GROUP BY 1,2,3) dm
 USING(module1_run_id,reporting_scope_code,strategy_profile_code)
LEFT JOIN tmp_frontier_validation_priority p USING(module1_run_id,reporting_scope_code,strategy_profile_code);
CREATE UNIQUE INDEX tmp_frontier_validation_expected_u1 ON tmp_frontier_validation_expected
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_frontier_validation_expected;

/* Target-typed exact projection of all 24 immutable frontier fields. */
CREATE TEMP TABLE tmp_frontier_validation_exact_expected ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_frontier WITH NO DATA;

INSERT INTO tmp_frontier_validation_exact_expected
(
    module1_run_id,
    strategy_profile_code,
    reporting_scope_code,
    strategy_summary_row_hash,
    frontier_eligible_flag,
    frontier_ineligibility_code,
    dominated_by_count,
    dominates_count,
    non_dominated_flag,
    frontier_rank,
    evidence_rank,
    governance_balance_score,
    governance_review_priority_code,
    governance_review_priority_rank,
    primary_governance_review_flag,
    governance_access_rate_normalized_value,
    governance_finance_charge_amount_normalized_value,
    governance_expected_loss_density_normalized_value,
    governance_risk_adjusted_contribution_normalized_value,
    governance_annualized_risk_adjusted_return_normalized_value,
    governance_servicing_burden_units_normalized_value,
    governance_payment_burden_rate_normalized_value,
    primary_reason_code,
    reason_codes
)
SELECT
    e.module1_run_id AS module1_run_id,
    e.strategy_profile_code AS strategy_profile_code,
    e.reporting_scope_code AS reporting_scope_code,
    s.row_hash AS strategy_summary_row_hash,
    e.frontier_eligible_flag AS frontier_eligible_flag,
    e.frontier_ineligibility_code AS frontier_ineligibility_code,
    e.dominated_by_count AS dominated_by_count,
    e.dominates_count AS dominates_count,
    e.non_dominated_flag AS non_dominated_flag,
    e.frontier_rank AS frontier_rank,
    e.evidence_rank AS evidence_rank,
    e.governance_balance_score AS governance_balance_score,
    e.governance_review_priority_code AS governance_review_priority_code,
    e.governance_review_priority_rank AS governance_review_priority_rank,
    e.primary_governance_review_flag AS primary_governance_review_flag,
    e.governance_access_rate_normalized_value AS governance_access_rate_normalized_value,
    e.governance_finance_charge_amount_normalized_value AS governance_finance_charge_amount_normalized_value,
    e.governance_expected_loss_density_normalized_value AS governance_expected_loss_density_normalized_value,
    e.governance_risk_adjusted_contribution_normalized_value AS governance_risk_adjusted_contribution_normalized_value,
    e.governance_annualized_risk_adjusted_return_normalized_value AS governance_annualized_risk_adjusted_return_normalized_value,
    e.governance_servicing_burden_units_normalized_value AS governance_servicing_burden_units_normalized_value,
    e.governance_payment_burden_rate_normalized_value AS governance_payment_burden_rate_normalized_value,
    e.expected_primary_reason_code AS primary_reason_code,
    e.expected_reason_codes AS reason_codes
FROM tmp_frontier_validation_expected e
JOIN msbf_m2.portfolio_strategy_summary s
  USING(module1_run_id,strategy_profile_code,reporting_scope_code)
ORDER BY e.module1_run_id,e.reporting_scope_code,e.strategy_profile_code;

CREATE UNIQUE INDEX tmp_frontier_validation_exact_expected_u1
ON tmp_frontier_validation_exact_expected
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_frontier_validation_exact_expected;

CREATE TEMP TABLE tmp_scope_validation_comparison_expected ON COMMIT DROP AS
SELECT
 c.module1_run_id,c.reporting_scope_code,'BASELINE_REPLAY'::text AS baseline_strategy_profile_code,
 c.strategy_profile_code AS challenger_strategy_profile_code,
 b.access_rate AS baseline_access_rate,c.access_rate AS challenger_access_rate,
 (c.access_rate-b.access_rate)::numeric(18,10) AS access_rate_delta,
 b.selected_exposure_amount AS baseline_selected_exposure_amount,
 c.selected_exposure_amount AS challenger_selected_exposure_amount,
 (c.selected_exposure_amount-b.selected_exposure_amount)::numeric(24,2) AS selected_exposure_amount_delta,
 b.finance_charge_amount AS baseline_finance_charge_amount,c.finance_charge_amount AS challenger_finance_charge_amount,
 (c.finance_charge_amount-b.finance_charge_amount)::numeric(24,2) AS finance_charge_amount_delta,
 b.expected_loss_density AS baseline_expected_loss_density,c.expected_loss_density AS challenger_expected_loss_density,
 (c.expected_loss_density-b.expected_loss_density)::numeric(18,10) AS expected_loss_density_delta,
 b.risk_adjusted_contribution AS baseline_risk_adjusted_contribution,
 c.risk_adjusted_contribution AS challenger_risk_adjusted_contribution,
 (c.risk_adjusted_contribution-b.risk_adjusted_contribution)::numeric(24,2) AS risk_adjusted_contribution_delta,
 b.annualized_risk_adjusted_return AS baseline_annualized_risk_adjusted_return,
 c.annualized_risk_adjusted_return AS challenger_annualized_risk_adjusted_return,
 (c.annualized_risk_adjusted_return-b.annualized_risk_adjusted_return)::numeric(18,10) AS annualized_risk_adjusted_return_delta,
 b.servicing_burden_units AS baseline_servicing_burden_units,c.servicing_burden_units AS challenger_servicing_burden_units,
 (c.servicing_burden_units-b.servicing_burden_units)::numeric(24,6) AS servicing_burden_units_delta,
 b.payment_burden_rate AS baseline_payment_burden_rate,c.payment_burden_rate AS challenger_payment_burden_rate,
 (c.payment_burden_rate-b.payment_burden_rate)::numeric(18,10) AS payment_burden_rate_delta,
 bf.frontier_rank AS baseline_frontier_rank,cf.frontier_rank AS challenger_frontier_rank,
 bf.frontier_eligible_flag AS baseline_frontier_eligible_flag,
 cf.frontier_eligible_flag AS challenger_frontier_eligible_flag,
 cf.governance_review_priority_code AS challenger_governance_review_priority_code,
 c.stress_improvement_violation_count AS challenger_stress_improvement_violation_count,
 (c.stress_improvement_violation_count=0) AS challenger_stress_nonimprovement_pass_flag,
 c.stress_strategy_restriction_rows AS challenger_stress_strategy_restriction_rows,
 c.absolute_workload_reduction_rows AS challenger_absolute_workload_reduction_rows,
 c.hard_constraint_violation_count AS challenger_hard_constraint_violation_count,
 c.servicing_burden_coverage_code,c.new_access_servicing_burden_estimated_flag
FROM tmp_scope_validation_summary_expected c
JOIN tmp_scope_validation_summary_expected b
 ON b.module1_run_id=c.module1_run_id AND b.reporting_scope_code=c.reporting_scope_code
AND b.strategy_profile_code='BASELINE_REPLAY'
JOIN tmp_frontier_validation_expected cf
 ON cf.module1_run_id=c.module1_run_id AND cf.reporting_scope_code=c.reporting_scope_code
AND cf.strategy_profile_code=c.strategy_profile_code
JOIN tmp_frontier_validation_expected bf
 ON bf.module1_run_id=b.module1_run_id AND bf.reporting_scope_code=b.reporting_scope_code
AND bf.strategy_profile_code='BASELINE_REPLAY'
WHERE c.strategy_profile_code<>'BASELINE_REPLAY';
CREATE UNIQUE INDEX tmp_scope_validation_comparison_expected_u1 ON tmp_scope_validation_comparison_expected
(module1_run_id,reporting_scope_code,challenger_strategy_profile_code);
ANALYZE tmp_scope_validation_comparison_expected;

/* Target-typed exact projection of all 44 immutable comparison fields. */
CREATE TEMP TABLE tmp_scope_validation_comparison_exact_expected ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_comparison WITH NO DATA;

INSERT INTO tmp_scope_validation_comparison_exact_expected
(
    module1_run_id,
    reporting_scope_code,
    baseline_strategy_profile_code,
    challenger_strategy_profile_code,
    baseline_summary_row_hash,
    challenger_summary_row_hash,
    baseline_frontier_row_hash,
    challenger_frontier_row_hash,
    baseline_access_rate,
    challenger_access_rate,
    access_rate_delta,
    baseline_selected_exposure_amount,
    challenger_selected_exposure_amount,
    selected_exposure_amount_delta,
    baseline_finance_charge_amount,
    challenger_finance_charge_amount,
    finance_charge_amount_delta,
    baseline_expected_loss_density,
    challenger_expected_loss_density,
    expected_loss_density_delta,
    baseline_risk_adjusted_contribution,
    challenger_risk_adjusted_contribution,
    risk_adjusted_contribution_delta,
    baseline_annualized_risk_adjusted_return,
    challenger_annualized_risk_adjusted_return,
    annualized_risk_adjusted_return_delta,
    baseline_servicing_burden_units,
    challenger_servicing_burden_units,
    servicing_burden_units_delta,
    baseline_payment_burden_rate,
    challenger_payment_burden_rate,
    payment_burden_rate_delta,
    baseline_frontier_rank,
    challenger_frontier_rank,
    baseline_frontier_eligible_flag,
    challenger_frontier_eligible_flag,
    challenger_governance_review_priority_code,
    challenger_stress_improvement_violation_count,
    challenger_stress_nonimprovement_pass_flag,
    challenger_stress_strategy_restriction_rows,
    challenger_absolute_workload_reduction_rows,
    challenger_hard_constraint_violation_count,
    servicing_burden_coverage_code,
    new_access_servicing_burden_estimated_flag
)
SELECT
    e.module1_run_id AS module1_run_id,
    e.reporting_scope_code AS reporting_scope_code,
    e.baseline_strategy_profile_code AS baseline_strategy_profile_code,
    e.challenger_strategy_profile_code AS challenger_strategy_profile_code,
    bs.row_hash AS baseline_summary_row_hash,
    cs.row_hash AS challenger_summary_row_hash,
    bf.row_hash AS baseline_frontier_row_hash,
    cf.row_hash AS challenger_frontier_row_hash,
    e.baseline_access_rate AS baseline_access_rate,
    e.challenger_access_rate AS challenger_access_rate,
    e.access_rate_delta AS access_rate_delta,
    e.baseline_selected_exposure_amount AS baseline_selected_exposure_amount,
    e.challenger_selected_exposure_amount AS challenger_selected_exposure_amount,
    e.selected_exposure_amount_delta AS selected_exposure_amount_delta,
    e.baseline_finance_charge_amount AS baseline_finance_charge_amount,
    e.challenger_finance_charge_amount AS challenger_finance_charge_amount,
    e.finance_charge_amount_delta AS finance_charge_amount_delta,
    e.baseline_expected_loss_density AS baseline_expected_loss_density,
    e.challenger_expected_loss_density AS challenger_expected_loss_density,
    e.expected_loss_density_delta AS expected_loss_density_delta,
    e.baseline_risk_adjusted_contribution AS baseline_risk_adjusted_contribution,
    e.challenger_risk_adjusted_contribution AS challenger_risk_adjusted_contribution,
    e.risk_adjusted_contribution_delta AS risk_adjusted_contribution_delta,
    e.baseline_annualized_risk_adjusted_return AS baseline_annualized_risk_adjusted_return,
    e.challenger_annualized_risk_adjusted_return AS challenger_annualized_risk_adjusted_return,
    e.annualized_risk_adjusted_return_delta AS annualized_risk_adjusted_return_delta,
    e.baseline_servicing_burden_units AS baseline_servicing_burden_units,
    e.challenger_servicing_burden_units AS challenger_servicing_burden_units,
    e.servicing_burden_units_delta AS servicing_burden_units_delta,
    e.baseline_payment_burden_rate AS baseline_payment_burden_rate,
    e.challenger_payment_burden_rate AS challenger_payment_burden_rate,
    e.payment_burden_rate_delta AS payment_burden_rate_delta,
    e.baseline_frontier_rank AS baseline_frontier_rank,
    e.challenger_frontier_rank AS challenger_frontier_rank,
    e.baseline_frontier_eligible_flag AS baseline_frontier_eligible_flag,
    e.challenger_frontier_eligible_flag AS challenger_frontier_eligible_flag,
    e.challenger_governance_review_priority_code AS challenger_governance_review_priority_code,
    e.challenger_stress_improvement_violation_count AS challenger_stress_improvement_violation_count,
    e.challenger_stress_nonimprovement_pass_flag AS challenger_stress_nonimprovement_pass_flag,
    e.challenger_stress_strategy_restriction_rows AS challenger_stress_strategy_restriction_rows,
    e.challenger_absolute_workload_reduction_rows AS challenger_absolute_workload_reduction_rows,
    e.challenger_hard_constraint_violation_count AS challenger_hard_constraint_violation_count,
    e.servicing_burden_coverage_code AS servicing_burden_coverage_code,
    e.new_access_servicing_burden_estimated_flag AS new_access_servicing_burden_estimated_flag
FROM tmp_scope_validation_comparison_expected e
JOIN msbf_m2.portfolio_strategy_summary bs
  ON bs.module1_run_id=e.module1_run_id
 AND bs.reporting_scope_code=e.reporting_scope_code
 AND bs.strategy_profile_code='BASELINE_REPLAY'
JOIN msbf_m2.portfolio_strategy_summary cs
  ON cs.module1_run_id=e.module1_run_id
 AND cs.reporting_scope_code=e.reporting_scope_code
 AND cs.strategy_profile_code=e.challenger_strategy_profile_code
JOIN msbf_m2.portfolio_strategy_frontier bf
  ON bf.module1_run_id=e.module1_run_id
 AND bf.reporting_scope_code=e.reporting_scope_code
 AND bf.strategy_profile_code='BASELINE_REPLAY'
JOIN msbf_m2.portfolio_strategy_frontier cf
  ON cf.module1_run_id=e.module1_run_id
 AND cf.reporting_scope_code=e.reporting_scope_code
 AND cf.strategy_profile_code=e.challenger_strategy_profile_code
ORDER BY e.module1_run_id,e.reporting_scope_code,e.challenger_strategy_profile_code;

CREATE UNIQUE INDEX tmp_scope_validation_comparison_exact_expected_u1
ON tmp_scope_validation_comparison_exact_expected
(module1_run_id,reporting_scope_code,challenger_strategy_profile_code);
ANALYZE tmp_scope_validation_comparison_exact_expected;

/* ============================================================================
Section 7 — Target-typed physical row hashes and nineteen ordered set hashes
============================================================================ */
CREATE TEMP TABLE tmp_registry_validation_physical_hash_mismatch
(
 object_sequence integer PRIMARY KEY,
 object_code text NOT NULL UNIQUE,
 mismatch_count bigint NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_registry_validation_physical_hash_mismatch(object_sequence,object_code,mismatch_count)
VALUES
(1,'msbf_ctl.m2_11_policy_profile',
 (SELECT count(*) FROM msbf_ctl.m2_11_policy_profile t
  WHERE t.configuration_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(t.configuration_payload))),
(2,'msbf_m2.portfolio_strategy_profile',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_profile t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(3,'msbf_m2.portfolio_strategy_objective_definition',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_objective_definition t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(4,'msbf_m2.portfolio_strategy_constraint_definition',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_constraint_definition t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(5,'msbf_m2.portfolio_strategy_reason_definition',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_reason_definition t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(6,'msbf_m2.portfolio_strategy_application_source_snapshot',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_application_source_snapshot t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(7,'msbf_m2.portfolio_strategy_candidate_source_snapshot',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_candidate_source_snapshot t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(8,'msbf_m2.portfolio_strategy_account_source_snapshot',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_account_source_snapshot t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(9,'msbf_m2.portfolio_strategy_kpi_source_snapshot',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(10,'msbf_m2.portfolio_strategy_queue_source_snapshot',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_queue_source_snapshot t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(11,'msbf_m2.application_strategy_candidate_evaluation',
 (SELECT count(*) FROM msbf_m2.application_strategy_candidate_evaluation t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(12,'msbf_m2.application_portfolio_strategy_simulation',
 (SELECT count(*) FROM msbf_m2.application_portfolio_strategy_simulation t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(13,'msbf_m2.account_servicing_strategy_simulation',
 (SELECT count(*) FROM msbf_m2.account_servicing_strategy_simulation t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(14,'msbf_m2.portfolio_strategy_summary',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_summary t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(15,'msbf_m2.portfolio_strategy_frontier',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_frontier t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(16,'msbf_m2.portfolio_strategy_comparison',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_comparison t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))),
(17,'msbf_m2.portfolio_strategy_simulation_latest',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_latest t
  WHERE t.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'contract_row_hash'-'created_at'))),
(18,'msbf_m2.portfolio_strategy_simulation_archive',
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_archive t
  WHERE t.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(
   jsonb_build_object('module1_run_id',t.module1_run_id,'contract_code',t.contract_code,
    'contract_version',t.contract_version,'strategy_profile_code',t.strategy_profile_code,
    'reporting_scope_code',t.reporting_scope_code,'contract_payload',t.contract_payload,
    'source_latest_row_hash',t.contract_row_hash)))),
(19,'msbf_ctl.m2_11_portfolio_strategy_contract_registry',
 (SELECT count(*) FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_registry_row_hash(to_jsonb(t))));

CREATE TEMP TABLE tmp_registry_validation_reconstructed_set_hash
(
 object_sequence integer PRIMARY KEY,
 object_code text NOT NULL UNIQUE,
 reconstructed_set_hash text NOT NULL,
 registry_field_name text
) ON COMMIT DROP;

INSERT INTO tmp_registry_validation_reconstructed_set_hash
(object_sequence,object_code,reconstructed_set_hash,registry_field_name)
VALUES
(1,'msbf_ctl.m2_11_policy_profile',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(configuration_payload),'|' ORDER BY module1_run_id)) FROM msbf_ctl.m2_11_policy_profile),'policy_set_hash'),
(2,'msbf_m2.portfolio_strategy_profile',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_profile t),'strategy_profile_set_hash'),
(3,'msbf_m2.portfolio_strategy_objective_definition',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,objective_code)) FROM msbf_m2.portfolio_strategy_objective_definition t),'objective_definition_set_hash'),
(4,'msbf_m2.portfolio_strategy_constraint_definition',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,constraint_code)) FROM msbf_m2.portfolio_strategy_constraint_definition t),'constraint_definition_set_hash'),
(5,'msbf_m2.portfolio_strategy_reason_definition',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,reason_code)) FROM msbf_m2.portfolio_strategy_reason_definition t),'reason_definition_set_hash'),
(6,'msbf_m2.portfolio_strategy_application_source_snapshot',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scenario_id,merchant_application_id)) FROM msbf_m2.portfolio_strategy_application_source_snapshot t),'application_source_set_hash'),
(7,'msbf_m2.portfolio_strategy_candidate_source_snapshot',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code)) FROM msbf_m2.portfolio_strategy_candidate_source_snapshot t),'candidate_source_set_hash'),
(8,'msbf_m2.portfolio_strategy_account_source_snapshot',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scenario_id,merchant_application_id)) FROM msbf_m2.portfolio_strategy_account_source_snapshot t),'account_source_set_hash'),
(9,'msbf_m2.portfolio_strategy_kpi_source_snapshot',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scope_code,kpi_code)) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot t),'kpi_source_set_hash'),
(10,'msbf_m2.portfolio_strategy_queue_source_snapshot',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,servicing_queue_code)) FROM msbf_m2.portfolio_strategy_queue_source_snapshot t),'queue_source_set_hash'),
(11,'msbf_m2.application_strategy_candidate_evaluation',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code)) FROM msbf_m2.application_strategy_candidate_evaluation t),'candidate_evaluation_set_hash'),
(12,'msbf_m2.application_portfolio_strategy_simulation',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)) FROM msbf_m2.application_portfolio_strategy_simulation t),'application_simulation_set_hash'),
(13,'msbf_m2.account_servicing_strategy_simulation',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)) FROM msbf_m2.account_servicing_strategy_simulation t),'account_simulation_set_hash'),
(14,'msbf_m2.portfolio_strategy_summary',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_summary t),'strategy_summary_set_hash'),
(15,'msbf_m2.portfolio_strategy_frontier',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_frontier t),'frontier_set_hash'),
(16,'msbf_m2.portfolio_strategy_comparison',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,reporting_scope_code,challenger_strategy_profile_code)) FROM msbf_m2.portfolio_strategy_comparison t),'comparison_set_hash'),
(17,'msbf_m2.portfolio_strategy_simulation_latest',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'contract_row_hash'-'created_at'),'|' ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_latest t),'latest_set_hash'),
(18,'msbf_m2.portfolio_strategy_simulation_archive',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(jsonb_build_object('module1_run_id',t.module1_run_id,'contract_code',t.contract_code,'contract_version',t.contract_version,'strategy_profile_code',t.strategy_profile_code,'reporting_scope_code',t.reporting_scope_code,'contract_payload',t.contract_payload,'source_latest_row_hash',t.contract_row_hash)),'|' ORDER BY module1_run_id,contract_version,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_archive t),'archive_set_hash'),
(19,'msbf_ctl.m2_11_portfolio_strategy_contract_registry',(SELECT md5(string_agg(msbf_ctl.m2_11_registry_row_hash(to_jsonb(t)),'|' ORDER BY module1_run_id,contract_version)) FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry t),NULL);

CREATE TEMP TABLE tmp_registry_validation_hash_summary ON COMMIT DROP AS
SELECT
 (SELECT sum(mismatch_count) FROM tmp_registry_validation_physical_hash_mismatch)::bigint AS physical_row_hash_mismatches,
 (SELECT count(*) FROM tmp_registry_validation_reconstructed_set_hash)::bigint AS reconstructed_set_hash_rows,
 (SELECT count(*) FROM tmp_registry_validation_reconstructed_set_hash h
   CROSS JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry r
   WHERE h.registry_field_name IS NOT NULL
     AND to_jsonb(r)->>h.registry_field_name IS DISTINCT FROM h.reconstructed_set_hash)::bigint AS registry_set_hash_mismatches,
 (SELECT md5((SELECT reconstructed_set_hash FROM tmp_registry_validation_reconstructed_set_hash WHERE object_sequence=17)
             ||'|'||(SELECT reconstructed_set_hash FROM tmp_registry_validation_reconstructed_set_hash WHERE object_sequence=18))) AS reconstructed_contract_set_hash,
 (SELECT md5(string_agg(object_code||'|'||reconstructed_set_hash,'|' ORDER BY object_sequence))
    FROM tmp_registry_validation_reconstructed_set_hash) AS reconstructed_combined_set_hash;

/* Exact target-typed reconstruction of all 85 immutable latest business fields. */
CREATE TEMP TABLE tmp_latest_validation_expected ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_simulation_latest WITH NO DATA;

INSERT INTO tmp_latest_validation_expected
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    strategy_profile_code,
    reporting_scope_code,
    source_m1_17_contract_code,
    source_m1_17_contract_version,
    source_m1_17_schema_version,
    source_m1_17_methodology_version,
    source_m1_17_combined_hash,
    source_m2_2_contract_code,
    source_m2_2_contract_version,
    source_m2_2_schema_version,
    source_m2_2_methodology_version,
    source_m2_2_combined_hash,
    source_m2_4_contract_code,
    source_m2_4_contract_version,
    source_m2_4_schema_version,
    source_m2_4_methodology_version,
    source_m2_4_combined_hash,
    source_m2_7_contract_code,
    source_m2_7_contract_version,
    source_m2_7_schema_version,
    source_m2_7_methodology_version,
    source_m2_7_combined_hash,
    source_m2_10_contract_code,
    source_m2_10_contract_version,
    source_m2_10_schema_version,
    source_m2_10_methodology_version,
    source_m2_10_combined_hash,
    application_rows,
    access_selected_rows,
    controlled_review_rows,
    strategy_restriction_rows,
    no_feasible_candidate_rows,
    insufficient_evidence_rows,
    policy_decline_rows,
    blocked_source_rows,
    servicing_account_rows,
    servicing_distinct_application_rows,
    hard_constraint_violation_count,
    source_risk_improvement_violation_count,
    source_return_improvement_violation_count,
    strategy_access_improvement_violation_count,
    strategy_feasibility_improvement_violation_count,
    comparable_payment_burden_improvement_violation_count,
    comparable_servicing_burden_improvement_violation_count,
    stress_improvement_violation_count,
    stress_strategy_restriction_rows,
    absolute_workload_reduction_rows,
    access_rate,
    selected_exposure_amount,
    finance_charge_amount,
    expected_loss_amount,
    expected_loss_density,
    risk_adjusted_contribution,
    annualized_risk_adjusted_return,
    servicing_burden_units,
    payment_burden_rate,
    scope_strategy_score,
    governance_balance_score,
    strategy_evidence_status,
    stress_nonimprovement_pass_flag,
    frontier_eligible_flag,
    non_dominated_flag,
    frontier_rank,
    governance_review_priority_code,
    primary_governance_review_flag,
    servicing_burden_coverage_code,
    new_access_servicing_burden_estimated_flag,
    baseline_access_rate_delta,
    baseline_selected_exposure_amount_delta,
    baseline_finance_charge_amount_delta,
    baseline_expected_loss_density_delta,
    baseline_risk_adjusted_contribution_delta,
    baseline_annualized_risk_adjusted_return_delta,
    baseline_servicing_burden_units_delta,
    baseline_payment_burden_rate_delta,
    primary_reason_code,
    reason_codes,
    strategy_summary_row_hash,
    frontier_row_hash,
    comparison_row_hash
)
SELECT
    s.module1_run_id AS module1_run_id,
    r.contract_code AS contract_code,
    r.contract_version AS contract_version,
    r.schema_version AS schema_version,
    r.methodology_version AS methodology_version,
    s.strategy_profile_code AS strategy_profile_code,
    s.reporting_scope_code AS reporting_scope_code,
    r.source_m1_17_contract_code AS source_m1_17_contract_code,
    r.source_m1_17_contract_version AS source_m1_17_contract_version,
    r.source_m1_17_schema_version AS source_m1_17_schema_version,
    r.source_m1_17_methodology_version AS source_m1_17_methodology_version,
    r.source_m1_17_combined_hash AS source_m1_17_combined_hash,
    r.source_m2_2_contract_code AS source_m2_2_contract_code,
    r.source_m2_2_contract_version AS source_m2_2_contract_version,
    r.source_m2_2_schema_version AS source_m2_2_schema_version,
    r.source_m2_2_methodology_version AS source_m2_2_methodology_version,
    r.source_m2_2_combined_hash AS source_m2_2_combined_hash,
    r.source_m2_4_contract_code AS source_m2_4_contract_code,
    r.source_m2_4_contract_version AS source_m2_4_contract_version,
    r.source_m2_4_schema_version AS source_m2_4_schema_version,
    r.source_m2_4_methodology_version AS source_m2_4_methodology_version,
    r.source_m2_4_combined_hash AS source_m2_4_combined_hash,
    r.source_m2_7_contract_code AS source_m2_7_contract_code,
    r.source_m2_7_contract_version AS source_m2_7_contract_version,
    r.source_m2_7_schema_version AS source_m2_7_schema_version,
    r.source_m2_7_methodology_version AS source_m2_7_methodology_version,
    r.source_m2_7_combined_hash AS source_m2_7_combined_hash,
    r.source_m2_10_contract_code AS source_m2_10_contract_code,
    r.source_m2_10_contract_version AS source_m2_10_contract_version,
    r.source_m2_10_schema_version AS source_m2_10_schema_version,
    r.source_m2_10_methodology_version AS source_m2_10_methodology_version,
    r.source_m2_10_combined_hash AS source_m2_10_combined_hash,
    s.application_rows AS application_rows,
    s.access_selected_rows AS access_selected_rows,
    s.controlled_review_rows AS controlled_review_rows,
    s.strategy_restriction_rows AS strategy_restriction_rows,
    s.no_feasible_candidate_rows AS no_feasible_candidate_rows,
    s.insufficient_evidence_rows AS insufficient_evidence_rows,
    s.policy_decline_rows AS policy_decline_rows,
    s.blocked_source_rows AS blocked_source_rows,
    s.servicing_account_rows AS servicing_account_rows,
    s.servicing_distinct_application_rows AS servicing_distinct_application_rows,
    s.hard_constraint_violation_count AS hard_constraint_violation_count,
    s.source_risk_improvement_violation_count AS source_risk_improvement_violation_count,
    s.source_return_improvement_violation_count AS source_return_improvement_violation_count,
    s.strategy_access_improvement_violation_count AS strategy_access_improvement_violation_count,
    s.strategy_feasibility_improvement_violation_count AS strategy_feasibility_improvement_violation_count,
    s.comparable_payment_burden_improvement_violation_count AS comparable_payment_burden_improvement_violation_count,
    s.comparable_servicing_burden_improvement_violation_count AS comparable_servicing_burden_improvement_violation_count,
    s.stress_improvement_violation_count AS stress_improvement_violation_count,
    s.stress_strategy_restriction_rows AS stress_strategy_restriction_rows,
    s.absolute_workload_reduction_rows AS absolute_workload_reduction_rows,
    s.access_rate AS access_rate,
    s.selected_exposure_amount AS selected_exposure_amount,
    s.finance_charge_amount AS finance_charge_amount,
    s.expected_loss_amount AS expected_loss_amount,
    s.expected_loss_density AS expected_loss_density,
    s.risk_adjusted_contribution AS risk_adjusted_contribution,
    s.annualized_risk_adjusted_return AS annualized_risk_adjusted_return,
    s.servicing_burden_units AS servicing_burden_units,
    s.payment_burden_rate AS payment_burden_rate,
    s.scope_strategy_score AS scope_strategy_score,
    f.governance_balance_score AS governance_balance_score,
    s.strategy_evidence_status AS strategy_evidence_status,
    s.stress_nonimprovement_pass_flag AS stress_nonimprovement_pass_flag,
    f.frontier_eligible_flag AS frontier_eligible_flag,
    f.non_dominated_flag AS non_dominated_flag,
    f.frontier_rank AS frontier_rank,
    f.governance_review_priority_code AS governance_review_priority_code,
    f.primary_governance_review_flag AS primary_governance_review_flag,
    s.servicing_burden_coverage_code AS servicing_burden_coverage_code,
    s.new_access_servicing_burden_estimated_flag AS new_access_servicing_burden_estimated_flag,
    CASE WHEN s.strategy_profile_code='BASELINE_REPLAY' THEN 0::numeric(18,10) ELSE c.access_rate_delta END AS baseline_access_rate_delta,
    CASE WHEN s.strategy_profile_code='BASELINE_REPLAY' THEN 0::numeric(24,2) ELSE c.selected_exposure_amount_delta END AS baseline_selected_exposure_amount_delta,
    CASE WHEN s.strategy_profile_code='BASELINE_REPLAY' THEN 0::numeric(24,2) ELSE c.finance_charge_amount_delta END AS baseline_finance_charge_amount_delta,
    CASE WHEN s.strategy_profile_code='BASELINE_REPLAY' THEN CASE WHEN s.expected_loss_density IS NULL THEN NULL ELSE 0::numeric(18,10) END ELSE c.expected_loss_density_delta END AS baseline_expected_loss_density_delta,
    CASE WHEN s.strategy_profile_code='BASELINE_REPLAY' THEN 0::numeric(24,2) ELSE c.risk_adjusted_contribution_delta END AS baseline_risk_adjusted_contribution_delta,
    CASE WHEN s.strategy_profile_code='BASELINE_REPLAY' THEN CASE WHEN s.annualized_risk_adjusted_return IS NULL THEN NULL ELSE 0::numeric(18,10) END ELSE c.annualized_risk_adjusted_return_delta END AS baseline_annualized_risk_adjusted_return_delta,
    CASE WHEN s.strategy_profile_code='BASELINE_REPLAY' THEN 0::numeric(24,6) ELSE c.servicing_burden_units_delta END AS baseline_servicing_burden_units_delta,
    CASE WHEN s.strategy_profile_code='BASELINE_REPLAY' THEN CASE WHEN s.payment_burden_rate IS NULL THEN NULL ELSE 0::numeric(18,10) END ELSE c.payment_burden_rate_delta END AS baseline_payment_burden_rate_delta,
    f.primary_reason_code AS primary_reason_code,
    f.reason_codes AS reason_codes,
    ps.row_hash AS strategy_summary_row_hash,
    pf.row_hash AS frontier_row_hash,
    pc.row_hash AS comparison_row_hash
FROM tmp_scope_validation_summary_exact_expected s
JOIN tmp_frontier_validation_exact_expected f
  USING(module1_run_id,strategy_profile_code,reporting_scope_code)
JOIN msbf_m2.portfolio_strategy_summary ps
  USING(module1_run_id,strategy_profile_code,reporting_scope_code)
JOIN msbf_m2.portfolio_strategy_frontier pf
  USING(module1_run_id,strategy_profile_code,reporting_scope_code)
LEFT JOIN tmp_scope_validation_comparison_exact_expected c
  ON c.module1_run_id=s.module1_run_id
 AND c.reporting_scope_code=s.reporting_scope_code
 AND c.challenger_strategy_profile_code=s.strategy_profile_code
LEFT JOIN msbf_m2.portfolio_strategy_comparison pc
  ON pc.module1_run_id=s.module1_run_id
 AND pc.reporting_scope_code=s.reporting_scope_code
 AND pc.challenger_strategy_profile_code=s.strategy_profile_code
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry r
  ON r.module1_run_id=s.module1_run_id AND r.contract_version=1
ORDER BY s.module1_run_id,s.reporting_scope_code,s.strategy_profile_code;

CREATE UNIQUE INDEX tmp_latest_validation_expected_u1
ON tmp_latest_validation_expected(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_latest_validation_expected;

CREATE TEMP TABLE tmp_latest_validation_link_mismatch ON COMMIT DROP AS
SELECT
 (SELECT count(*)
  FROM msbf_m2.portfolio_strategy_simulation_latest a
  FULL JOIN tmp_latest_validation_expected e
    USING(module1_run_id,strategy_profile_code,reporting_scope_code)
  WHERE a.module1_run_id IS NULL OR e.module1_run_id IS NULL
     OR (to_jsonb(a)-'contract_row_hash'-'created_at')
        IS DISTINCT FROM (to_jsonb(e)-'contract_row_hash'-'created_at'))::bigint
   AS latest_exact_mismatches,
 (SELECT count(*)
  FROM msbf_m2.portfolio_strategy_simulation_archive a
  JOIN msbf_m2.portfolio_strategy_simulation_latest l
    USING(module1_run_id,contract_version,strategy_profile_code,reporting_scope_code)
  WHERE a.contract_row_hash IS DISTINCT FROM l.contract_row_hash
     OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at'))::bigint
   AS archive_payload_mismatches,
 (SELECT count(*)
  FROM pg_trigger t
  WHERE t.tgrelid='msbf_m2.portfolio_strategy_simulation_archive'::regclass
    AND t.tgname='trg_m2_11_archive_immutable' AND NOT t.tgisinternal
    AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16)::bigint
   AS immutable_trigger_rows;

/* ============================================================================
Section 8 — Complete accepted-source-to-snapshot reconstruction

Controls 022–025 consume these expected target-typed relations. Every immutable
payload field is populated from the authorized accepted upstream objects using
the approved WP1 mapping. The actual persisted M2.11 snapshots are not inputs
to expected-row construction.
============================================================================ */
CREATE TEMP TABLE tmp_src_run_registry ON COMMIT DROP AS
SELECT run_id
FROM tmp_eval_m2_11_validation_context;

CREATE TEMP TABLE tmp_src_acceptance_gate_result ON COMMIT DROP AS
SELECT
    run_id,
    gate_id,
    review_version,
    result_status,
    observed_value,
    threshold_value,
    finding,
    residual_limitation,
    reviewer_role,
    reviewed_at
FROM msbf_ctl.acceptance_gate_result
WHERE run_id=(SELECT run_id FROM tmp_src_run_registry) AND gate_id IN ('G2_M1_CONTRACT','M2_2_PRICING_STRUCTURE_COUNTEROFFER','M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION','M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP','M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS');

CREATE TEMP TABLE tmp_src_m2_10_registry ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    kpi_snapshot_rows,
    queue_summary_rows,
    latest_rows,
    portfolio_account_rows,
    baseline_account_rows,
    stress_account_rows,
    closed_stable_rows,
    active_reconciled_rows,
    controlled_review_rows,
    certified_account_rows,
    certification_rate,
    certified_exposure_amount,
    active_exposure_amount,
    review_hold_exposure_amount,
    unresolved_exception_count,
    servicing_burden_units,
    kpi_snapshot_set_hash,
    queue_summary_set_hash,
    latest_set_hash,
    combined_set_hash,
    contract_status,
    row_hash
FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_10_latest ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    merchant_id,
    synthetic_account_id,
    synthetic_advance_id,
    source_final_lifecycle_state_code,
    certified_state_code,
    state_certified_flag,
    performance_tier_code,
    servicing_queue_code,
    payment_activity_flag,
    exception_incident_flag,
    exception_resolved_flag,
    payment_event_count,
    settled_event_count,
    returned_event_count,
    retry_event_count,
    exception_case_count,
    resolved_exception_count,
    unresolved_exception_count,
    source_exposure_amount,
    certified_exposure_amount,
    scheduled_payment_amount,
    processed_payment_amount,
    returned_payment_amount,
    retry_payment_amount,
    reconciliation_variance_amount,
    exposure_variance_amount,
    gross_collection_rate,
    return_rate,
    retry_cure_rate,
    exposure_retention_rate,
    servicing_burden_units,
    primary_portfolio_reason_code,
    portfolio_reason_codes,
    source_contract_row_hash,
    source_snapshot_row_hash,
    performance_snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash,
    created_at
FROM msbf_m2.application_portfolio_performance_latest
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_10_kpi ON COMMIT DROP AS
SELECT
    module1_run_id,
    scope_code,
    scope_type,
    scenario_code,
    kpi_code,
    kpi_rank,
    unit_code,
    applicable_flag,
    kpi_value_numeric,
    kpi_value_text,
    numerator_value,
    denominator_value,
    primary_portfolio_reason_code,
    source_scope_row_hash,
    row_hash,
    created_at
FROM msbf_m2.portfolio_kpi_snapshot
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_10_queue ON COMMIT DROP AS
SELECT
    module1_run_id,
    servicing_queue_code,
    account_count,
    scenario_count,
    certified_exposure_amount,
    payment_event_count,
    exception_case_count,
    resolved_exception_count,
    unresolved_exception_count,
    servicing_burden_units,
    maximum_tier_rank,
    row_hash,
    created_at
FROM msbf_m2.servicing_queue_analytics_snapshot
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m1_17_g2_registry ON COMMIT DROP AS
SELECT
    module1_run_id,
    bundle_code,
    bundle_version,
    schema_version,
    methodology_version,
    integrated_consumption_rows,
    bundle_latest_set_hash,
    combined_g2_hash,
    bundle_status,
    row_hash
FROM msbf_ctl.m1_17_g2_bundle_registry
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m1_17_integrated ON COMMIT DROP AS
SELECT
    accepted_m1_14_acquisition_cost_amount,
    acquisition_contract_evidence_status,
    affordability_status,
    annualized_risk_adjusted_return_rate,
    archetype_code,
    as_of_date,
    assisted_touch_count,
    attribution_confidence_score,
    attribution_confidence_tier,
    attribution_evidence_status,
    average_available_balance_30d,
    avg_daily_eligible_sales_30d,
    capacity_tier,
    channel_type,
    cost_evidence_status,
    data_confidence_tier,
    detailed_conditional_partner_broker_cost_amount,
    detailed_total_acquisition_cost_if_booked,
    direct_attributable_incurred_cost_amount,
    economic_status,
    economic_tier,
    enhanced_total_acquisition_cost_if_booked,
    fraud_risk_tier,
    hard_stop_recommended_flag,
    identified_legacy_overlap_amount,
    incremental_acquisition_cost_beyond_m1_14,
    industry_code,
    integrated_risk_score,
    integrated_risk_tier,
    internally_allocated_acquisition_cost_amount,
    lgd_input_rate,
    m1_15_contract_evidence_status,
    m1_15_contract_row_hash,
    m1_16_contract_row_hash,
    manual_review_recommended_flag,
    merchant_application_id,
    merchant_id,
    merchant_size_tier,
    module1_run_id,
    operating_resilience_score,
    overlap_evidence_status,
    partner_channel_id,
    path_weighted_ead_amount,
    population_id,
    primary_campaign_id,
    primary_source_code,
    processor_continuity_status,
    relationship_stage,
    resilience_tier,
    risk_adjusted_contribution_amount,
    scenario_code,
    scenario_id,
    schedule_adjusted_comparative_expected_loss_amount,
    source_confidence_score,
    synthetic_merchant_risk_proxy,
    total_incurred_pre_application_cost_amount,
    touchpoint_count,
    unmapped_legacy_proxy_amount,
    verification_disposition
FROM msbf_m1.v_m1_17_g2_integrated_consumption
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_2_registry ON COMMIT DROP AS
SELECT
    module1_run_id,
    pricing_contract_code,
    pricing_contract_version,
    pricing_schema_version,
    methodology_version,
    candidate_rows,
    pricing_latest_rows,
    candidate_set_hash,
    pricing_latest_set_hash,
    combined_set_hash,
    contract_status,
    row_hash
FROM msbf_ctl.m2_2_pricing_structure_contract_registry
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_2_latest ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_route_code,
    source_route_rank,
    pricing_disposition_code,
    structure_available_flag,
    review_required_flag,
    selected_candidate_template_code,
    selected_candidate_row_hash,
    requested_funding_amount,
    selected_funding_amount,
    selected_remittance_rate,
    selected_payback_multiple,
    selected_collection_horizon_days,
    selected_total_repayment_amount,
    selected_finance_charge_amount,
    selected_implied_daily_collection_amount,
    selected_implied_payoff_days,
    selected_amount_to_request_ratio,
    candidate_count,
    counteroffer_foundation_flag,
    stress_nonimprovement_applied_flag,
    primary_reason_code,
    reason_codes,
    routing_evidence_status,
    source_m2_1_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    policy_configuration_hash,
    source_snapshot_row_hash,
    contract_row_hash,
    created_at
FROM msbf_m2.application_pricing_structure_latest
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_2_candidate ON COMMIT DROP AS
SELECT
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    candidate_template_code,
    template_sequence,
    source_route_code,
    source_route_rank,
    requested_funding_amount,
    candidate_funding_amount,
    candidate_remittance_rate,
    candidate_payback_multiple,
    candidate_collection_horizon_days,
    candidate_total_repayment_amount,
    candidate_finance_charge_amount,
    implied_daily_collection_amount,
    implied_payoff_days,
    amount_to_request_ratio,
    capacity_alignment_ratio,
    risk_load_rate,
    resilience_load_rate,
    economic_load_rate,
    stress_load_rate,
    acquisition_economics_amount,
    expected_loss_amount,
    risk_adjusted_contribution_amount,
    annualized_return_rate,
    counteroffer_foundation_flag,
    candidate_eligible_flag,
    selected_foundation_flag,
    candidate_rank,
    primary_reason_code,
    secondary_reason_codes,
    source_m2_1_contract_row_hash,
    source_request_contract_row_hash,
    source_m1_15_contract_row_hash,
    source_m1_16_contract_row_hash,
    source_g2_combined_hash,
    policy_configuration_hash,
    row_hash,
    created_at
FROM msbf_m2.application_pricing_structure_candidate
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_4_registry ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    activation_latest_rows,
    activation_latest_set_hash,
    combined_set_hash,
    contract_status,
    row_hash
FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_4_latest ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_final_decision_outcome_code,
    activation_outcome_code,
    activation_outcome_rank,
    booking_eligible_flag,
    booking_authorized_flag,
    funding_authorized_flag,
    funding_completed_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    synthetic_offer_acceptance_assumed_flag,
    real_funds_movement_flag,
    external_notice_generation_authorized_flag,
    external_notice_transmitted_flag,
    production_adverse_action_notice_flag,
    synthetic_account_id,
    synthetic_advance_id,
    booked_amount,
    funded_amount,
    activation_remittance_rate,
    activation_payback_multiple,
    activation_collection_horizon_days,
    activation_total_repayment_amount,
    activation_finance_charge_amount,
    activation_implied_daily_collection_amount,
    activation_implied_payoff_days,
    booking_date,
    funding_date,
    portfolio_activation_date,
    first_expected_remittance_date,
    monitoring_start_date,
    activation_evidence_status,
    notice_control_code,
    primary_activation_reason_code,
    activation_reason_codes,
    source_m2_3_contract_row_hash,
    source_m2_2_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash,
    created_at
FROM msbf_m2.application_booking_funding_activation_latest
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_7_registry ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    latest_rows,
    latest_set_hash,
    combined_set_hash,
    contract_status,
    row_hash
FROM msbf_ctl.m2_7_operational_activation_contract_registry
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_7_latest ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    merchant_id,
    synthetic_account_id,
    synthetic_advance_id,
    source_strategy_outcome_code,
    source_servicing_action_code,
    source_recommended_action_exposure_amount,
    operational_setup_outcome_code,
    operational_setup_action_code,
    operational_setup_priority_rank,
    operational_setup_queue_code,
    account_setup_status_code,
    setup_authorized_flag,
    blueprint_created_flag,
    setup_review_required_flag,
    no_setup_required_flag,
    synthetic_operational_case_id,
    synthetic_account_setup_id,
    synthetic_servicing_plan_id,
    operational_activation_date,
    next_reassessment_date,
    applied_temporary_payment_factor,
    applied_setup_duration_days,
    applied_reassessment_interval_days,
    primary_setup_reason_code,
    setup_reason_codes,
    setup_parameter_payload,
    source_contract_row_hash,
    source_snapshot_row_hash,
    activation_snapshot_row_hash,
    account_setup_snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash,
    created_at
FROM msbf_m2.application_operational_activation_latest
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);


/* END_PROGRAM_215_EXPECTED_SNAPSHOT_UPSTREAM_SCANS */

/* ============================================================================
Upstream validation staging indexes and statistics
============================================================================ */
CREATE UNIQUE INDEX tmp_src_run_registry_u1 ON tmp_src_run_registry(run_id);
CREATE INDEX tmp_src_gate_i1 ON tmp_src_acceptance_gate_result(run_id,gate_id,review_version DESC);
CREATE UNIQUE INDEX tmp_src_m210_registry_u1 ON tmp_src_m2_10_registry(module1_run_id);
CREATE UNIQUE INDEX tmp_src_m210_latest_u1 ON tmp_src_m2_10_latest(module1_run_id,scenario_id,merchant_application_id);
CREATE INDEX tmp_src_m210_latest_i2 ON tmp_src_m2_10_latest(module1_run_id,merchant_application_id,scenario_code);
CREATE UNIQUE INDEX tmp_src_m210_kpi_u1 ON tmp_src_m2_10_kpi(module1_run_id,scope_code,kpi_code);
CREATE UNIQUE INDEX tmp_src_m210_queue_u1 ON tmp_src_m2_10_queue(module1_run_id,servicing_queue_code);
CREATE UNIQUE INDEX tmp_src_m117_registry_u1 ON tmp_src_m1_17_g2_registry(module1_run_id);
CREATE UNIQUE INDEX tmp_src_m117_integrated_u1 ON tmp_src_m1_17_integrated(module1_run_id,scenario_id,merchant_application_id);
CREATE INDEX tmp_src_m117_integrated_i2 ON tmp_src_m1_17_integrated(module1_run_id,merchant_application_id,scenario_code);
CREATE UNIQUE INDEX tmp_src_m22_registry_u1 ON tmp_src_m2_2_registry(module1_run_id);
CREATE UNIQUE INDEX tmp_src_m22_latest_u1 ON tmp_src_m2_2_latest(module1_run_id,scenario_id,merchant_application_id);
CREATE UNIQUE INDEX tmp_src_m22_candidate_u1 ON tmp_src_m2_2_candidate(module1_run_id,scenario_id,merchant_application_id,candidate_template_code);
CREATE INDEX tmp_src_m22_candidate_i2 ON tmp_src_m2_2_candidate(module1_run_id,scenario_id,merchant_application_id,candidate_rank,candidate_template_code);
CREATE UNIQUE INDEX tmp_src_m24_registry_u1 ON tmp_src_m2_4_registry(module1_run_id);
CREATE UNIQUE INDEX tmp_src_m24_latest_u1 ON tmp_src_m2_4_latest(module1_run_id,scenario_id,merchant_application_id);
CREATE UNIQUE INDEX tmp_src_m27_registry_u1 ON tmp_src_m2_7_registry(module1_run_id);
CREATE UNIQUE INDEX tmp_src_m27_latest_u1 ON tmp_src_m2_7_latest(module1_run_id,scenario_id,merchant_application_id);

ANALYZE tmp_src_run_registry;
ANALYZE tmp_src_acceptance_gate_result;
ANALYZE tmp_src_m2_10_registry;
ANALYZE tmp_src_m2_10_latest;
ANALYZE tmp_src_m2_10_kpi;
ANALYZE tmp_src_m2_10_queue;
ANALYZE tmp_src_m1_17_g2_registry;
ANALYZE tmp_src_m1_17_integrated;
ANALYZE tmp_src_m2_2_registry;
ANALYZE tmp_src_m2_2_latest;
ANALYZE tmp_src_m2_2_candidate;
ANALYZE tmp_src_m2_4_registry;
ANALYZE tmp_src_m2_4_latest;
ANALYZE tmp_src_m2_7_registry;
ANALYZE tmp_src_m2_7_latest;

CREATE TEMP TABLE tmp_eval_expected_application_source_projection ON COMMIT DROP AS
SELECT
    g.module1_run_id AS module1_run_id,
    g.scenario_id AS scenario_id,
    g.scenario_code AS scenario_code,
    g.merchant_application_id AS merchant_application_id,
    g.population_id AS population_id,
    g.merchant_id AS merchant_id,
    g.as_of_date AS as_of_date,
    g.industry_code AS industry_code,
    g.merchant_size_tier AS merchant_size_tier,
    g.relationship_stage AS relationship_stage,
    g.partner_channel_id AS partner_channel_id,
    g.channel_type AS channel_type,
    g.source_confidence_score AS source_confidence_score,
    g.data_confidence_tier AS data_confidence_tier,
    g.verification_disposition AS verification_disposition,
    g.fraud_risk_tier AS fraud_risk_tier,
    g.processor_continuity_status AS processor_continuity_status,
    g.avg_daily_eligible_sales_30d AS avg_daily_eligible_sales_30d,
    g.average_available_balance_30d AS average_available_balance_30d,
    g.capacity_tier AS capacity_tier,
    g.affordability_status AS affordability_status,
    g.archetype_code AS archetype_code,
    g.operating_resilience_score AS operating_resilience_score,
    g.resilience_tier AS resilience_tier,
    g.integrated_risk_score AS integrated_risk_score,
    g.synthetic_merchant_risk_proxy AS synthetic_merchant_risk_proxy,
    g.integrated_risk_tier AS integrated_risk_tier,
    g.path_weighted_ead_amount AS path_weighted_ead_amount,
    g.lgd_input_rate AS lgd_input_rate,
    g.schedule_adjusted_comparative_expected_loss_amount AS schedule_adjusted_comparative_expected_loss_amount,
    g.risk_adjusted_contribution_amount AS risk_adjusted_contribution_amount,
    g.annualized_risk_adjusted_return_rate AS annualized_risk_adjusted_return_rate,
    g.economic_tier AS economic_tier,
    g.economic_status AS economic_status,
    g.hard_stop_recommended_flag AS hard_stop_recommended_flag,
    g.manual_review_recommended_flag AS manual_review_recommended_flag,
    g.m1_15_contract_evidence_status AS m1_15_contract_evidence_status,
    g.m1_15_contract_row_hash AS m1_15_contract_row_hash,
    g.primary_source_code AS primary_source_code,
    g.primary_campaign_id AS primary_campaign_id,
    g.attribution_confidence_score AS attribution_confidence_score,
    g.attribution_confidence_tier AS attribution_confidence_tier,
    g.touchpoint_count AS touchpoint_count,
    g.assisted_touch_count AS assisted_touch_count,
    g.attribution_evidence_status AS attribution_evidence_status,
    g.direct_attributable_incurred_cost_amount AS direct_attributable_incurred_cost_amount,
    g.internally_allocated_acquisition_cost_amount AS internally_allocated_acquisition_cost_amount,
    g.total_incurred_pre_application_cost_amount AS total_incurred_pre_application_cost_amount,
    g.detailed_conditional_partner_broker_cost_amount AS detailed_conditional_partner_broker_cost_amount,
    g.detailed_total_acquisition_cost_if_booked AS detailed_total_acquisition_cost_if_booked,
    g.accepted_m1_14_acquisition_cost_amount AS accepted_m1_14_acquisition_cost_amount,
    g.identified_legacy_overlap_amount AS identified_legacy_overlap_amount,
    g.unmapped_legacy_proxy_amount AS unmapped_legacy_proxy_amount,
    g.incremental_acquisition_cost_beyond_m1_14 AS incremental_acquisition_cost_beyond_m1_14,
    g.enhanced_total_acquisition_cost_if_booked AS enhanced_total_acquisition_cost_if_booked,
    g.cost_evidence_status AS cost_evidence_status,
    g.overlap_evidence_status AS overlap_evidence_status,
    g.acquisition_contract_evidence_status AS acquisition_contract_evidence_status,
    g.m1_16_contract_row_hash AS m1_16_contract_row_hash,
    p.contract_code AS m2_2_contract_code,
    p.contract_version AS m2_2_contract_version,
    p.schema_version AS m2_2_schema_version,
    p.methodology_version AS m2_2_methodology_version,
    p.source_route_code AS source_route_code,
    p.source_route_rank AS source_route_rank,
    p.pricing_disposition_code AS pricing_disposition_code,
    p.structure_available_flag AS structure_available_flag,
    p.review_required_flag AS review_required_flag,
    p.selected_candidate_template_code AS selected_candidate_template_code,
    p.selected_candidate_row_hash AS selected_candidate_row_hash,
    p.requested_funding_amount AS requested_funding_amount,
    p.selected_funding_amount AS selected_funding_amount,
    p.selected_remittance_rate AS selected_remittance_rate,
    p.selected_payback_multiple AS selected_payback_multiple,
    p.selected_collection_horizon_days AS selected_collection_horizon_days,
    p.selected_total_repayment_amount AS selected_total_repayment_amount,
    p.selected_finance_charge_amount AS selected_finance_charge_amount,
    p.selected_implied_daily_collection_amount AS selected_implied_daily_collection_amount,
    p.selected_implied_payoff_days AS selected_implied_payoff_days,
    p.selected_amount_to_request_ratio AS selected_amount_to_request_ratio,
    p.candidate_count AS candidate_count,
    p.counteroffer_foundation_flag AS counteroffer_foundation_flag,
    p.stress_nonimprovement_applied_flag AS stress_nonimprovement_applied_flag,
    p.primary_reason_code AS primary_reason_code,
    p.reason_codes AS reason_codes,
    p.routing_evidence_status AS routing_evidence_status,
    p.source_m2_1_contract_row_hash AS m2_2_source_m2_1_contract_row_hash,
    p.source_request_contract_row_hash AS m2_2_source_request_contract_row_hash,
    p.source_g2_combined_hash AS m2_2_source_g2_combined_hash,
    p.policy_configuration_hash AS m2_2_policy_configuration_hash,
    p.source_snapshot_row_hash AS m2_2_source_snapshot_row_hash,
    p.contract_row_hash AS m2_2_contract_row_hash,
    p.created_at AS m2_2_source_created_at,
    a.contract_code AS m2_4_contract_code,
    a.contract_version AS m2_4_contract_version,
    a.schema_version AS m2_4_schema_version,
    a.methodology_version AS m2_4_methodology_version,
    a.source_final_decision_outcome_code AS source_final_decision_outcome_code,
    a.activation_outcome_code AS activation_outcome_code,
    a.activation_outcome_rank AS activation_outcome_rank,
    a.booking_eligible_flag AS booking_eligible_flag,
    a.booking_authorized_flag AS booking_authorized_flag,
    a.funding_authorized_flag AS funding_authorized_flag,
    a.funding_completed_flag AS funding_completed_flag,
    a.portfolio_activated_flag AS portfolio_activated_flag,
    a.operational_review_required_flag AS operational_review_required_flag,
    a.synthetic_offer_acceptance_assumed_flag AS synthetic_offer_acceptance_assumed_flag,
    a.real_funds_movement_flag AS real_funds_movement_flag,
    a.external_notice_generation_authorized_flag AS external_notice_generation_authorized_flag,
    a.external_notice_transmitted_flag AS external_notice_transmitted_flag,
    a.production_adverse_action_notice_flag AS production_adverse_action_notice_flag,
    a.synthetic_account_id AS synthetic_account_id,
    a.synthetic_advance_id AS synthetic_advance_id,
    a.booked_amount AS booked_amount,
    a.funded_amount AS funded_amount,
    a.activation_remittance_rate AS activation_remittance_rate,
    a.activation_payback_multiple AS activation_payback_multiple,
    a.activation_collection_horizon_days AS activation_collection_horizon_days,
    a.activation_total_repayment_amount AS activation_total_repayment_amount,
    a.activation_finance_charge_amount AS activation_finance_charge_amount,
    a.activation_implied_daily_collection_amount AS activation_implied_daily_collection_amount,
    a.activation_implied_payoff_days AS activation_implied_payoff_days,
    a.booking_date AS booking_date,
    a.funding_date AS funding_date,
    a.portfolio_activation_date AS portfolio_activation_date,
    a.first_expected_remittance_date AS first_expected_remittance_date,
    a.monitoring_start_date AS monitoring_start_date,
    a.activation_evidence_status AS activation_evidence_status,
    a.notice_control_code AS notice_control_code,
    a.primary_activation_reason_code AS primary_activation_reason_code,
    a.activation_reason_codes AS activation_reason_codes,
    a.source_m2_3_contract_row_hash AS m2_4_source_m2_3_contract_row_hash,
    a.source_m2_2_contract_row_hash AS m2_4_source_m2_2_contract_row_hash,
    a.source_g2_combined_hash AS m2_4_source_g2_combined_hash,
    a.source_snapshot_row_hash AS m2_4_source_snapshot_row_hash,
    a.snapshot_row_hash AS m2_4_activation_snapshot_row_hash,
    a.policy_configuration_hash AS m2_4_policy_configuration_hash,
    a.contract_row_hash AS m2_4_contract_row_hash,
    a.created_at AS m2_4_source_created_at,
    'M1_G2_CONSUMPTION_BUNDLE' AS m1_17_bundle_code,
    1 AS m1_17_bundle_version,
    'M1_G2_BUNDLE_SCHEMA_V1' AS m1_17_schema_version,
    'M1_17_METHOD_V1' AS m1_17_methodology_version,
    r17.bundle_status AS m1_17_bundle_status,
    r17.combined_g2_hash AS m1_17_combined_g2_hash,
    r17.row_hash AS m1_17_registry_row_hash,
    r22.contract_status AS m2_2_contract_status,
    r22.combined_set_hash AS m2_2_combined_set_hash,
    r22.row_hash AS m2_2_registry_row_hash,
    r24.contract_status AS m2_4_contract_status,
    r24.combined_set_hash AS m2_4_combined_set_hash,
    r24.row_hash AS m2_4_registry_row_hash,
    'MATCHED_ONE_TO_ONE'::text AS source_join_status_code
FROM tmp_src_m1_17_integrated g JOIN tmp_src_m2_2_latest p USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,population_id,merchant_id,as_of_date) JOIN tmp_src_m2_4_latest a USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,population_id,merchant_id,as_of_date) CROSS JOIN tmp_src_m1_17_g2_registry r17 CROSS JOIN tmp_src_m2_2_registry r22 CROSS JOIN tmp_src_m2_4_registry r24
ORDER BY module1_run_id,scenario_id,merchant_application_id;

CREATE UNIQUE INDEX tmp_eval_expected_application_source_projection_u1 ON tmp_eval_expected_application_source_projection (module1_run_id, scenario_id, merchant_application_id);
ANALYZE tmp_eval_expected_application_source_projection;

/* Independent target-type-before-hash expected projection for msbf_m2.portfolio_strategy_application_source_snapshot. */
CREATE TEMP TABLE tmp_eval_expected_application_source_snapshot ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_application_source_snapshot WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_eval_expected_application_source_snapshot') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_application_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_eval_expected_application_source_snapshot versus msbf_m2.portfolio_strategy_application_source_snapshot: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_eval_expected_application_source_snapshot
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    population_id, merchant_id, as_of_date, industry_code,
    merchant_size_tier, relationship_stage, partner_channel_id, channel_type,
    source_confidence_score, data_confidence_tier, verification_disposition, fraud_risk_tier,
    processor_continuity_status, avg_daily_eligible_sales_30d, average_available_balance_30d, capacity_tier,
    affordability_status, archetype_code, operating_resilience_score, resilience_tier,
    integrated_risk_score, synthetic_merchant_risk_proxy, integrated_risk_tier, path_weighted_ead_amount,
    lgd_input_rate, schedule_adjusted_comparative_expected_loss_amount, risk_adjusted_contribution_amount, annualized_risk_adjusted_return_rate,
    economic_tier, economic_status, hard_stop_recommended_flag, manual_review_recommended_flag,
    m1_15_contract_evidence_status, m1_15_contract_row_hash, primary_source_code, primary_campaign_id,
    attribution_confidence_score, attribution_confidence_tier, touchpoint_count, assisted_touch_count,
    attribution_evidence_status, direct_attributable_incurred_cost_amount, internally_allocated_acquisition_cost_amount, total_incurred_pre_application_cost_amount,
    detailed_conditional_partner_broker_cost_amount, detailed_total_acquisition_cost_if_booked, accepted_m1_14_acquisition_cost_amount, identified_legacy_overlap_amount,
    unmapped_legacy_proxy_amount, incremental_acquisition_cost_beyond_m1_14, enhanced_total_acquisition_cost_if_booked, cost_evidence_status,
    overlap_evidence_status, acquisition_contract_evidence_status, m1_16_contract_row_hash, m2_2_contract_code,
    m2_2_contract_version, m2_2_schema_version, m2_2_methodology_version, source_route_code,
    source_route_rank, pricing_disposition_code, structure_available_flag, review_required_flag,
    selected_candidate_template_code, selected_candidate_row_hash, requested_funding_amount, selected_funding_amount,
    selected_remittance_rate, selected_payback_multiple, selected_collection_horizon_days, selected_total_repayment_amount,
    selected_finance_charge_amount, selected_implied_daily_collection_amount, selected_implied_payoff_days, selected_amount_to_request_ratio,
    candidate_count, counteroffer_foundation_flag, stress_nonimprovement_applied_flag, primary_reason_code,
    reason_codes, routing_evidence_status, m2_2_source_m2_1_contract_row_hash, m2_2_source_request_contract_row_hash,
    m2_2_source_g2_combined_hash, m2_2_policy_configuration_hash, m2_2_source_snapshot_row_hash, m2_2_contract_row_hash,
    m2_2_source_created_at, m2_4_contract_code, m2_4_contract_version, m2_4_schema_version,
    m2_4_methodology_version, source_final_decision_outcome_code, activation_outcome_code, activation_outcome_rank,
    booking_eligible_flag, booking_authorized_flag, funding_authorized_flag, funding_completed_flag,
    portfolio_activated_flag, operational_review_required_flag, synthetic_offer_acceptance_assumed_flag, real_funds_movement_flag,
    external_notice_generation_authorized_flag, external_notice_transmitted_flag, production_adverse_action_notice_flag, synthetic_account_id,
    synthetic_advance_id, booked_amount, funded_amount, activation_remittance_rate,
    activation_payback_multiple, activation_collection_horizon_days, activation_total_repayment_amount, activation_finance_charge_amount,
    activation_implied_daily_collection_amount, activation_implied_payoff_days, booking_date, funding_date,
    portfolio_activation_date, first_expected_remittance_date, monitoring_start_date, activation_evidence_status,
    notice_control_code, primary_activation_reason_code, activation_reason_codes, m2_4_source_m2_3_contract_row_hash,
    m2_4_source_m2_2_contract_row_hash, m2_4_source_g2_combined_hash, m2_4_source_snapshot_row_hash, m2_4_activation_snapshot_row_hash,
    m2_4_policy_configuration_hash, m2_4_contract_row_hash, m2_4_source_created_at, m1_17_bundle_code,
    m1_17_bundle_version, m1_17_schema_version, m1_17_methodology_version, m1_17_bundle_status,
    m1_17_combined_g2_hash, m1_17_registry_row_hash, m2_2_contract_status, m2_2_combined_set_hash,
    m2_2_registry_row_hash, m2_4_contract_status, m2_4_combined_set_hash, m2_4_registry_row_hash,
    source_join_status_code, row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.scenario_id,
    p.scenario_code,
    p.merchant_application_id,
    p.population_id,
    p.merchant_id,
    p.as_of_date,
    p.industry_code,
    p.merchant_size_tier,
    p.relationship_stage,
    p.partner_channel_id,
    p.channel_type,
    p.source_confidence_score,
    p.data_confidence_tier,
    p.verification_disposition,
    p.fraud_risk_tier,
    p.processor_continuity_status,
    p.avg_daily_eligible_sales_30d,
    p.average_available_balance_30d,
    p.capacity_tier,
    p.affordability_status,
    p.archetype_code,
    p.operating_resilience_score,
    p.resilience_tier,
    p.integrated_risk_score,
    p.synthetic_merchant_risk_proxy,
    p.integrated_risk_tier,
    p.path_weighted_ead_amount,
    p.lgd_input_rate,
    p.schedule_adjusted_comparative_expected_loss_amount,
    p.risk_adjusted_contribution_amount,
    p.annualized_risk_adjusted_return_rate,
    p.economic_tier,
    p.economic_status,
    p.hard_stop_recommended_flag,
    p.manual_review_recommended_flag,
    p.m1_15_contract_evidence_status,
    p.m1_15_contract_row_hash,
    p.primary_source_code,
    p.primary_campaign_id,
    p.attribution_confidence_score,
    p.attribution_confidence_tier,
    p.touchpoint_count,
    p.assisted_touch_count,
    p.attribution_evidence_status,
    p.direct_attributable_incurred_cost_amount,
    p.internally_allocated_acquisition_cost_amount,
    p.total_incurred_pre_application_cost_amount,
    p.detailed_conditional_partner_broker_cost_amount,
    p.detailed_total_acquisition_cost_if_booked,
    p.accepted_m1_14_acquisition_cost_amount,
    p.identified_legacy_overlap_amount,
    p.unmapped_legacy_proxy_amount,
    p.incremental_acquisition_cost_beyond_m1_14,
    p.enhanced_total_acquisition_cost_if_booked,
    p.cost_evidence_status,
    p.overlap_evidence_status,
    p.acquisition_contract_evidence_status,
    p.m1_16_contract_row_hash,
    p.m2_2_contract_code,
    p.m2_2_contract_version,
    p.m2_2_schema_version,
    p.m2_2_methodology_version,
    p.source_route_code,
    p.source_route_rank,
    p.pricing_disposition_code,
    p.structure_available_flag,
    p.review_required_flag,
    p.selected_candidate_template_code,
    p.selected_candidate_row_hash,
    p.requested_funding_amount,
    p.selected_funding_amount,
    p.selected_remittance_rate,
    p.selected_payback_multiple,
    p.selected_collection_horizon_days,
    p.selected_total_repayment_amount,
    p.selected_finance_charge_amount,
    p.selected_implied_daily_collection_amount,
    p.selected_implied_payoff_days,
    p.selected_amount_to_request_ratio,
    p.candidate_count,
    p.counteroffer_foundation_flag,
    p.stress_nonimprovement_applied_flag,
    p.primary_reason_code,
    p.reason_codes,
    p.routing_evidence_status,
    p.m2_2_source_m2_1_contract_row_hash,
    p.m2_2_source_request_contract_row_hash,
    p.m2_2_source_g2_combined_hash,
    p.m2_2_policy_configuration_hash,
    p.m2_2_source_snapshot_row_hash,
    p.m2_2_contract_row_hash,
    p.m2_2_source_created_at,
    p.m2_4_contract_code,
    p.m2_4_contract_version,
    p.m2_4_schema_version,
    p.m2_4_methodology_version,
    p.source_final_decision_outcome_code,
    p.activation_outcome_code,
    p.activation_outcome_rank,
    p.booking_eligible_flag,
    p.booking_authorized_flag,
    p.funding_authorized_flag,
    p.funding_completed_flag,
    p.portfolio_activated_flag,
    p.operational_review_required_flag,
    p.synthetic_offer_acceptance_assumed_flag,
    p.real_funds_movement_flag,
    p.external_notice_generation_authorized_flag,
    p.external_notice_transmitted_flag,
    p.production_adverse_action_notice_flag,
    p.synthetic_account_id,
    p.synthetic_advance_id,
    p.booked_amount,
    p.funded_amount,
    p.activation_remittance_rate,
    p.activation_payback_multiple,
    p.activation_collection_horizon_days,
    p.activation_total_repayment_amount,
    p.activation_finance_charge_amount,
    p.activation_implied_daily_collection_amount,
    p.activation_implied_payoff_days,
    p.booking_date,
    p.funding_date,
    p.portfolio_activation_date,
    p.first_expected_remittance_date,
    p.monitoring_start_date,
    p.activation_evidence_status,
    p.notice_control_code,
    p.primary_activation_reason_code,
    p.activation_reason_codes,
    p.m2_4_source_m2_3_contract_row_hash,
    p.m2_4_source_m2_2_contract_row_hash,
    p.m2_4_source_g2_combined_hash,
    p.m2_4_source_snapshot_row_hash,
    p.m2_4_activation_snapshot_row_hash,
    p.m2_4_policy_configuration_hash,
    p.m2_4_contract_row_hash,
    p.m2_4_source_created_at,
    p.m1_17_bundle_code,
    p.m1_17_bundle_version,
    p.m1_17_schema_version,
    p.m1_17_methodology_version,
    p.m1_17_bundle_status,
    p.m1_17_combined_g2_hash,
    p.m1_17_registry_row_hash,
    p.m2_2_contract_status,
    p.m2_2_combined_set_hash,
    p.m2_2_registry_row_hash,
    p.m2_4_contract_status,
    p.m2_4_combined_set_hash,
    p.m2_4_registry_row_hash,
    p.source_join_status_code,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_expected_application_source_projection p
ORDER BY module1_run_id,scenario_id,merchant_application_id;

UPDATE tmp_eval_expected_application_source_snapshot AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

CREATE UNIQUE INDEX tmp_eval_expected_application_source_snapshot_u1 ON tmp_eval_expected_application_source_snapshot(module1_run_id,scenario_id,merchant_application_id);
CREATE INDEX tmp_eval_expected_application_source_snapshot_i1 ON tmp_eval_expected_application_source_snapshot(module1_run_id,merchant_application_id,scenario_code);
ANALYZE tmp_eval_expected_application_source_snapshot;

CREATE TEMP TABLE tmp_eval_expected_candidate_source_projection ON COMMIT DROP AS
SELECT
    c.module1_run_id AS module1_run_id,
    c.scenario_id AS scenario_id,
    c.scenario_code AS scenario_code,
    c.merchant_application_id AS merchant_application_id,
    c.candidate_template_code AS candidate_template_code,
    c.template_sequence AS template_sequence,
    c.source_route_code AS source_route_code,
    c.source_route_rank AS source_route_rank,
    c.requested_funding_amount AS requested_funding_amount,
    c.candidate_funding_amount AS candidate_funding_amount,
    c.candidate_remittance_rate AS candidate_remittance_rate,
    c.candidate_payback_multiple AS candidate_payback_multiple,
    c.candidate_collection_horizon_days AS candidate_collection_horizon_days,
    c.candidate_total_repayment_amount AS candidate_total_repayment_amount,
    c.candidate_finance_charge_amount AS candidate_finance_charge_amount,
    c.implied_daily_collection_amount AS implied_daily_collection_amount,
    c.implied_payoff_days AS implied_payoff_days,
    c.amount_to_request_ratio AS amount_to_request_ratio,
    c.capacity_alignment_ratio AS capacity_alignment_ratio,
    c.risk_load_rate AS risk_load_rate,
    c.resilience_load_rate AS resilience_load_rate,
    c.economic_load_rate AS economic_load_rate,
    c.stress_load_rate AS stress_load_rate,
    c.acquisition_economics_amount AS acquisition_economics_amount,
    c.expected_loss_amount AS expected_loss_amount,
    c.risk_adjusted_contribution_amount AS risk_adjusted_contribution_amount,
    c.annualized_return_rate AS annualized_return_rate,
    c.counteroffer_foundation_flag AS counteroffer_foundation_flag,
    c.candidate_eligible_flag AS candidate_eligible_flag,
    c.selected_foundation_flag AS selected_foundation_flag,
    c.candidate_rank AS candidate_rank,
    c.primary_reason_code AS primary_reason_code,
    c.secondary_reason_codes AS secondary_reason_codes,
    c.source_m2_1_contract_row_hash AS source_m2_1_contract_row_hash,
    c.source_request_contract_row_hash AS source_request_contract_row_hash,
    c.source_m1_15_contract_row_hash AS source_m1_15_contract_row_hash,
    c.source_m1_16_contract_row_hash AS source_m1_16_contract_row_hash,
    c.source_g2_combined_hash AS source_g2_combined_hash,
    c.policy_configuration_hash AS policy_configuration_hash,
    c.row_hash AS source_candidate_row_hash,
    c.created_at AS source_candidate_created_at,
    'M2_PRICING_STRUCTURE_CONSUMPTION' AS m2_2_contract_code,
    1 AS m2_2_contract_version,
    'M2_2_PRICING_STRUCTURE_SCHEMA_V1' AS m2_2_schema_version,
    'M2_2_METHOD_V1' AS m2_2_methodology_version,
    r22.contract_status AS m2_2_contract_status,
    r22.combined_set_hash AS m2_2_combined_set_hash,
    r22.row_hash AS m2_2_registry_row_hash
FROM tmp_src_m2_2_candidate c CROSS JOIN tmp_src_m2_2_registry r22
ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code;

CREATE UNIQUE INDEX tmp_eval_expected_candidate_source_projection_u1 ON tmp_eval_expected_candidate_source_projection (module1_run_id, scenario_id, merchant_application_id, candidate_template_code);
ANALYZE tmp_eval_expected_candidate_source_projection;

/* Independent target-type-before-hash expected projection for msbf_m2.portfolio_strategy_candidate_source_snapshot. */
CREATE TEMP TABLE tmp_eval_expected_candidate_source_snapshot ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_candidate_source_snapshot WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_eval_expected_candidate_source_snapshot') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_candidate_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_eval_expected_candidate_source_snapshot versus msbf_m2.portfolio_strategy_candidate_source_snapshot: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_eval_expected_candidate_source_snapshot
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    candidate_template_code, template_sequence, source_route_code, source_route_rank,
    requested_funding_amount, candidate_funding_amount, candidate_remittance_rate, candidate_payback_multiple,
    candidate_collection_horizon_days, candidate_total_repayment_amount, candidate_finance_charge_amount, implied_daily_collection_amount,
    implied_payoff_days, amount_to_request_ratio, capacity_alignment_ratio, risk_load_rate,
    resilience_load_rate, economic_load_rate, stress_load_rate, acquisition_economics_amount,
    expected_loss_amount, risk_adjusted_contribution_amount, annualized_return_rate, counteroffer_foundation_flag,
    candidate_eligible_flag, selected_foundation_flag, candidate_rank, primary_reason_code,
    secondary_reason_codes, source_m2_1_contract_row_hash, source_request_contract_row_hash, source_m1_15_contract_row_hash,
    source_m1_16_contract_row_hash, source_g2_combined_hash, policy_configuration_hash, source_candidate_row_hash,
    source_candidate_created_at, m2_2_contract_code, m2_2_contract_version, m2_2_schema_version,
    m2_2_methodology_version, m2_2_contract_status, m2_2_combined_set_hash, m2_2_registry_row_hash,
    row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.scenario_id,
    p.scenario_code,
    p.merchant_application_id,
    p.candidate_template_code,
    p.template_sequence,
    p.source_route_code,
    p.source_route_rank,
    p.requested_funding_amount,
    p.candidate_funding_amount,
    p.candidate_remittance_rate,
    p.candidate_payback_multiple,
    p.candidate_collection_horizon_days,
    p.candidate_total_repayment_amount,
    p.candidate_finance_charge_amount,
    p.implied_daily_collection_amount,
    p.implied_payoff_days,
    p.amount_to_request_ratio,
    p.capacity_alignment_ratio,
    p.risk_load_rate,
    p.resilience_load_rate,
    p.economic_load_rate,
    p.stress_load_rate,
    p.acquisition_economics_amount,
    p.expected_loss_amount,
    p.risk_adjusted_contribution_amount,
    p.annualized_return_rate,
    p.counteroffer_foundation_flag,
    p.candidate_eligible_flag,
    p.selected_foundation_flag,
    p.candidate_rank,
    p.primary_reason_code,
    p.secondary_reason_codes,
    p.source_m2_1_contract_row_hash,
    p.source_request_contract_row_hash,
    p.source_m1_15_contract_row_hash,
    p.source_m1_16_contract_row_hash,
    p.source_g2_combined_hash,
    p.policy_configuration_hash,
    p.source_candidate_row_hash,
    p.source_candidate_created_at,
    p.m2_2_contract_code,
    p.m2_2_contract_version,
    p.m2_2_schema_version,
    p.m2_2_methodology_version,
    p.m2_2_contract_status,
    p.m2_2_combined_set_hash,
    p.m2_2_registry_row_hash,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_expected_candidate_source_projection p
ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code;

UPDATE tmp_eval_expected_candidate_source_snapshot AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

CREATE UNIQUE INDEX tmp_eval_expected_candidate_source_snapshot_u1 ON tmp_eval_expected_candidate_source_snapshot(module1_run_id,scenario_id,merchant_application_id,candidate_template_code);
CREATE INDEX tmp_eval_expected_candidate_source_snapshot_i1 ON tmp_eval_expected_candidate_source_snapshot(module1_run_id,scenario_id,merchant_application_id,candidate_rank,candidate_template_code);
ANALYZE tmp_eval_expected_candidate_source_snapshot;

CREATE TEMP TABLE tmp_eval_expected_account_source_projection ON COMMIT DROP AS
SELECT
    o.module1_run_id AS module1_run_id,
    o.scenario_id AS scenario_id,
    o.scenario_code AS scenario_code,
    o.merchant_application_id AS merchant_application_id,
    o.merchant_id AS merchant_id,
    o.synthetic_account_id AS synthetic_account_id,
    o.synthetic_advance_id AS synthetic_advance_id,
    o.contract_code AS m2_7_contract_code,
    o.contract_version AS m2_7_contract_version,
    o.schema_version AS m2_7_schema_version,
    o.methodology_version AS m2_7_methodology_version,
    o.source_strategy_outcome_code AS source_strategy_outcome_code,
    o.source_servicing_action_code AS source_servicing_action_code,
    o.source_recommended_action_exposure_amount AS source_recommended_action_exposure_amount,
    o.operational_setup_outcome_code AS operational_setup_outcome_code,
    o.operational_setup_action_code AS operational_setup_action_code,
    o.operational_setup_priority_rank AS operational_setup_priority_rank,
    o.operational_setup_queue_code AS operational_setup_queue_code,
    o.account_setup_status_code AS account_setup_status_code,
    o.setup_authorized_flag AS setup_authorized_flag,
    o.blueprint_created_flag AS blueprint_created_flag,
    o.setup_review_required_flag AS setup_review_required_flag,
    o.no_setup_required_flag AS no_setup_required_flag,
    o.synthetic_operational_case_id AS synthetic_operational_case_id,
    o.synthetic_account_setup_id AS synthetic_account_setup_id,
    o.synthetic_servicing_plan_id AS synthetic_servicing_plan_id,
    o.operational_activation_date AS operational_activation_date,
    o.next_reassessment_date AS next_reassessment_date,
    o.applied_temporary_payment_factor AS applied_temporary_payment_factor,
    o.applied_setup_duration_days AS applied_setup_duration_days,
    o.applied_reassessment_interval_days AS applied_reassessment_interval_days,
    o.primary_setup_reason_code AS primary_setup_reason_code,
    o.setup_reason_codes AS setup_reason_codes,
    o.setup_parameter_payload AS setup_parameter_payload,
    o.source_contract_row_hash AS m2_7_source_contract_row_hash,
    o.source_snapshot_row_hash AS m2_7_source_snapshot_row_hash,
    o.activation_snapshot_row_hash AS m2_7_activation_snapshot_row_hash,
    o.account_setup_snapshot_row_hash AS m2_7_account_setup_snapshot_row_hash,
    o.policy_configuration_hash AS m2_7_policy_configuration_hash,
    o.contract_row_hash AS m2_7_contract_row_hash,
    o.created_at AS m2_7_source_created_at,
    m.contract_code AS m2_10_contract_code,
    m.contract_version AS m2_10_contract_version,
    m.schema_version AS m2_10_schema_version,
    m.methodology_version AS m2_10_methodology_version,
    m.source_final_lifecycle_state_code AS source_final_lifecycle_state_code,
    m.certified_state_code AS certified_state_code,
    m.state_certified_flag AS state_certified_flag,
    m.performance_tier_code AS performance_tier_code,
    m.servicing_queue_code AS servicing_queue_code,
    m.payment_activity_flag AS payment_activity_flag,
    m.exception_incident_flag AS exception_incident_flag,
    m.exception_resolved_flag AS exception_resolved_flag,
    m.payment_event_count AS payment_event_count,
    m.settled_event_count AS settled_event_count,
    m.returned_event_count AS returned_event_count,
    m.retry_event_count AS retry_event_count,
    m.exception_case_count AS exception_case_count,
    m.resolved_exception_count AS resolved_exception_count,
    m.unresolved_exception_count AS unresolved_exception_count,
    m.source_exposure_amount AS source_exposure_amount,
    m.certified_exposure_amount AS certified_exposure_amount,
    m.scheduled_payment_amount AS scheduled_payment_amount,
    m.processed_payment_amount AS processed_payment_amount,
    m.returned_payment_amount AS returned_payment_amount,
    m.retry_payment_amount AS retry_payment_amount,
    m.reconciliation_variance_amount AS reconciliation_variance_amount,
    m.exposure_variance_amount AS exposure_variance_amount,
    m.gross_collection_rate AS gross_collection_rate,
    m.return_rate AS return_rate,
    m.retry_cure_rate AS retry_cure_rate,
    m.exposure_retention_rate AS exposure_retention_rate,
    m.servicing_burden_units AS servicing_burden_units,
    m.primary_portfolio_reason_code AS primary_portfolio_reason_code,
    m.portfolio_reason_codes AS portfolio_reason_codes,
    m.source_contract_row_hash AS m2_10_source_contract_row_hash,
    m.source_snapshot_row_hash AS m2_10_source_snapshot_row_hash,
    m.performance_snapshot_row_hash AS m2_10_performance_snapshot_row_hash,
    m.policy_configuration_hash AS m2_10_policy_configuration_hash,
    m.contract_row_hash AS m2_10_contract_row_hash,
    m.created_at AS m2_10_source_created_at,
    r27.contract_status AS m2_7_contract_status,
    r27.combined_set_hash AS m2_7_combined_set_hash,
    r27.row_hash AS m2_7_registry_row_hash,
    r210.contract_status AS m2_10_contract_status,
    r210.combined_set_hash AS m2_10_combined_set_hash,
    r210.row_hash AS m2_10_registry_row_hash,
    TRUE AS operational_account_present_flag,
    m.performance_tier_code AS source_account_posture_code,
    CASE m.performance_tier_code WHEN 'CLOSED_STABLE' THEN 1 WHEN 'ACTIVE_RECONCILED' THEN 2 WHEN 'CONTROLLED_REVIEW' THEN 3 ELSE NULL END::smallint AS source_account_posture_rank,
    (
            r27.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
            AND r27.contract_version=1
            AND r27.schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
            AND r27.methodology_version='M2_7_METHOD_V1'
            AND r27.contract_status='ACCEPTED'
            AND r27.combined_set_hash='c8e3a472afd2a16b1183677324e9db98'
            AND r27.row_hash~'^[0-9a-f]{32}$'
            AND r210.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'
            AND r210.contract_version=1
            AND r210.schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'
            AND r210.methodology_version='M2_10_METHOD_V1'
            AND r210.contract_status='ACCEPTED'
            AND r210.combined_set_hash='24fca7263a04397ebf21d30639f9069b'
            AND r210.row_hash~'^[0-9a-f]{32}$'
            AND EXISTS
            (
              SELECT 1 FROM tmp_src_acceptance_gate_result g27
              WHERE g27.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
                AND g27.result_status='PASS'
                AND g27.review_version=(SELECT max(x.review_version) FROM tmp_src_acceptance_gate_result x WHERE x.gate_id=g27.gate_id)
            )
            AND EXISTS
            (
              SELECT 1 FROM tmp_src_acceptance_gate_result g210
              WHERE g210.gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
                AND g210.result_status='PASS'
                AND g210.review_version=(SELECT max(x.review_version) FROM tmp_src_acceptance_gate_result x WHERE x.gate_id=g210.gate_id)
            )
        ) AS source_contract_identity_valid_flag,
    (
            o.source_contract_row_hash~'^[0-9a-f]{32}$'
            AND o.source_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND o.activation_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND o.account_setup_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND o.contract_row_hash~'^[0-9a-f]{32}$'
            AND m.source_contract_row_hash~'^[0-9a-f]{32}$'
            AND m.source_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND m.performance_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND m.contract_row_hash~'^[0-9a-f]{32}$'
            AND r27.latest_set_hash=(
              SELECT md5(string_agg(x.scenario_id::text||'|'||x.merchant_application_id||'|'||x.contract_row_hash,'|' ORDER BY x.scenario_id,x.merchant_application_id))
              FROM tmp_src_m2_7_latest x
            )
            AND r210.latest_set_hash=(
              SELECT md5(string_agg(x.scenario_id::text||'|'||x.merchant_application_id||'|'||x.contract_row_hash,'|' ORDER BY x.scenario_id,x.merchant_application_id))
              FROM tmp_src_m2_10_latest x
            )
        ) AS source_lineage_intact_flag,
    (NOT m.state_certified_flag OR m.unresolved_exception_count>0 OR NOT (
            r27.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
            AND r27.contract_version=1
            AND r27.schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
            AND r27.methodology_version='M2_7_METHOD_V1'
            AND r27.contract_status='ACCEPTED'
            AND r27.combined_set_hash='c8e3a472afd2a16b1183677324e9db98'
            AND r27.row_hash~'^[0-9a-f]{32}$'
            AND r210.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'
            AND r210.contract_version=1
            AND r210.schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'
            AND r210.methodology_version='M2_10_METHOD_V1'
            AND r210.contract_status='ACCEPTED'
            AND r210.combined_set_hash='24fca7263a04397ebf21d30639f9069b'
            AND r210.row_hash~'^[0-9a-f]{32}$'
            AND EXISTS
            (
              SELECT 1 FROM tmp_src_acceptance_gate_result g27
              WHERE g27.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
                AND g27.result_status='PASS'
                AND g27.review_version=(SELECT max(x.review_version) FROM tmp_src_acceptance_gate_result x WHERE x.gate_id=g27.gate_id)
            )
            AND EXISTS
            (
              SELECT 1 FROM tmp_src_acceptance_gate_result g210
              WHERE g210.gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
                AND g210.result_status='PASS'
                AND g210.review_version=(SELECT max(x.review_version) FROM tmp_src_acceptance_gate_result x WHERE x.gate_id=g210.gate_id)
            )
        ) OR NOT (
            o.source_contract_row_hash~'^[0-9a-f]{32}$'
            AND o.source_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND o.activation_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND o.account_setup_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND o.contract_row_hash~'^[0-9a-f]{32}$'
            AND m.source_contract_row_hash~'^[0-9a-f]{32}$'
            AND m.source_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND m.performance_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND m.contract_row_hash~'^[0-9a-f]{32}$'
            AND r27.latest_set_hash=(
              SELECT md5(string_agg(x.scenario_id::text||'|'||x.merchant_application_id||'|'||x.contract_row_hash,'|' ORDER BY x.scenario_id,x.merchant_application_id))
              FROM tmp_src_m2_7_latest x
            )
            AND r210.latest_set_hash=(
              SELECT md5(string_agg(x.scenario_id::text||'|'||x.merchant_application_id||'|'||x.contract_row_hash,'|' ORDER BY x.scenario_id,x.merchant_application_id))
              FROM tmp_src_m2_10_latest x
            )
        )) AS certification_blocked_flag,
    'MATCHED_ONE_TO_ONE'::text AS source_join_status_code
FROM tmp_src_m2_7_latest o JOIN tmp_src_m2_10_latest m USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,merchant_id,synthetic_account_id,synthetic_advance_id) CROSS JOIN tmp_src_m2_7_registry r27 CROSS JOIN tmp_src_m2_10_registry r210
ORDER BY module1_run_id,scenario_id,merchant_application_id;

CREATE UNIQUE INDEX tmp_eval_expected_account_source_projection_u1 ON tmp_eval_expected_account_source_projection (module1_run_id, scenario_id, merchant_application_id);
ANALYZE tmp_eval_expected_account_source_projection;

/* Independent target-type-before-hash expected projection for msbf_m2.portfolio_strategy_account_source_snapshot. */
CREATE TEMP TABLE tmp_eval_expected_account_source_snapshot ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_account_source_snapshot WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_eval_expected_account_source_snapshot') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_account_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_eval_expected_account_source_snapshot versus msbf_m2.portfolio_strategy_account_source_snapshot: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_eval_expected_account_source_snapshot
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    merchant_id, synthetic_account_id, synthetic_advance_id, m2_7_contract_code,
    m2_7_contract_version, m2_7_schema_version, m2_7_methodology_version, source_strategy_outcome_code,
    source_servicing_action_code, source_recommended_action_exposure_amount, operational_setup_outcome_code, operational_setup_action_code,
    operational_setup_priority_rank, operational_setup_queue_code, account_setup_status_code, setup_authorized_flag,
    blueprint_created_flag, setup_review_required_flag, no_setup_required_flag, synthetic_operational_case_id,
    synthetic_account_setup_id, synthetic_servicing_plan_id, operational_activation_date, next_reassessment_date,
    applied_temporary_payment_factor, applied_setup_duration_days, applied_reassessment_interval_days, primary_setup_reason_code,
    setup_reason_codes, setup_parameter_payload, m2_7_source_contract_row_hash, m2_7_source_snapshot_row_hash,
    m2_7_activation_snapshot_row_hash, m2_7_account_setup_snapshot_row_hash, m2_7_policy_configuration_hash, m2_7_contract_row_hash,
    m2_7_source_created_at, m2_10_contract_code, m2_10_contract_version, m2_10_schema_version,
    m2_10_methodology_version, source_final_lifecycle_state_code, certified_state_code, state_certified_flag,
    performance_tier_code, servicing_queue_code, payment_activity_flag, exception_incident_flag,
    exception_resolved_flag, payment_event_count, settled_event_count, returned_event_count,
    retry_event_count, exception_case_count, resolved_exception_count, unresolved_exception_count,
    source_exposure_amount, certified_exposure_amount, scheduled_payment_amount, processed_payment_amount,
    returned_payment_amount, retry_payment_amount, reconciliation_variance_amount, exposure_variance_amount,
    gross_collection_rate, return_rate, retry_cure_rate, exposure_retention_rate,
    servicing_burden_units, primary_portfolio_reason_code, portfolio_reason_codes, m2_10_source_contract_row_hash,
    m2_10_source_snapshot_row_hash, m2_10_performance_snapshot_row_hash, m2_10_policy_configuration_hash, m2_10_contract_row_hash,
    m2_10_source_created_at, operational_account_present_flag, source_account_posture_code, source_account_posture_rank,
    source_contract_identity_valid_flag, source_lineage_intact_flag, certification_blocked_flag, m2_7_contract_status,
    m2_7_combined_set_hash, m2_7_registry_row_hash, m2_10_contract_status, m2_10_combined_set_hash,
    m2_10_registry_row_hash, source_join_status_code, row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.scenario_id,
    p.scenario_code,
    p.merchant_application_id,
    p.merchant_id,
    p.synthetic_account_id,
    p.synthetic_advance_id,
    p.m2_7_contract_code,
    p.m2_7_contract_version,
    p.m2_7_schema_version,
    p.m2_7_methodology_version,
    p.source_strategy_outcome_code,
    p.source_servicing_action_code,
    p.source_recommended_action_exposure_amount,
    p.operational_setup_outcome_code,
    p.operational_setup_action_code,
    p.operational_setup_priority_rank,
    p.operational_setup_queue_code,
    p.account_setup_status_code,
    p.setup_authorized_flag,
    p.blueprint_created_flag,
    p.setup_review_required_flag,
    p.no_setup_required_flag,
    p.synthetic_operational_case_id,
    p.synthetic_account_setup_id,
    p.synthetic_servicing_plan_id,
    p.operational_activation_date,
    p.next_reassessment_date,
    p.applied_temporary_payment_factor,
    p.applied_setup_duration_days,
    p.applied_reassessment_interval_days,
    p.primary_setup_reason_code,
    p.setup_reason_codes,
    p.setup_parameter_payload,
    p.m2_7_source_contract_row_hash,
    p.m2_7_source_snapshot_row_hash,
    p.m2_7_activation_snapshot_row_hash,
    p.m2_7_account_setup_snapshot_row_hash,
    p.m2_7_policy_configuration_hash,
    p.m2_7_contract_row_hash,
    p.m2_7_source_created_at,
    p.m2_10_contract_code,
    p.m2_10_contract_version,
    p.m2_10_schema_version,
    p.m2_10_methodology_version,
    p.source_final_lifecycle_state_code,
    p.certified_state_code,
    p.state_certified_flag,
    p.performance_tier_code,
    p.servicing_queue_code,
    p.payment_activity_flag,
    p.exception_incident_flag,
    p.exception_resolved_flag,
    p.payment_event_count,
    p.settled_event_count,
    p.returned_event_count,
    p.retry_event_count,
    p.exception_case_count,
    p.resolved_exception_count,
    p.unresolved_exception_count,
    p.source_exposure_amount,
    p.certified_exposure_amount,
    p.scheduled_payment_amount,
    p.processed_payment_amount,
    p.returned_payment_amount,
    p.retry_payment_amount,
    p.reconciliation_variance_amount,
    p.exposure_variance_amount,
    p.gross_collection_rate,
    p.return_rate,
    p.retry_cure_rate,
    p.exposure_retention_rate,
    p.servicing_burden_units,
    p.primary_portfolio_reason_code,
    p.portfolio_reason_codes,
    p.m2_10_source_contract_row_hash,
    p.m2_10_source_snapshot_row_hash,
    p.m2_10_performance_snapshot_row_hash,
    p.m2_10_policy_configuration_hash,
    p.m2_10_contract_row_hash,
    p.m2_10_source_created_at,
    p.operational_account_present_flag,
    p.source_account_posture_code,
    p.source_account_posture_rank,
    p.source_contract_identity_valid_flag,
    p.source_lineage_intact_flag,
    p.certification_blocked_flag,
    p.m2_7_contract_status,
    p.m2_7_combined_set_hash,
    p.m2_7_registry_row_hash,
    p.m2_10_contract_status,
    p.m2_10_combined_set_hash,
    p.m2_10_registry_row_hash,
    p.source_join_status_code,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_expected_account_source_projection p
ORDER BY module1_run_id,scenario_id,merchant_application_id;

UPDATE tmp_eval_expected_account_source_snapshot AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

CREATE UNIQUE INDEX tmp_eval_expected_account_source_snapshot_u1 ON tmp_eval_expected_account_source_snapshot(module1_run_id,scenario_id,merchant_application_id);
CREATE UNIQUE INDEX tmp_eval_expected_account_source_snapshot_u2 ON tmp_eval_expected_account_source_snapshot(module1_run_id,scenario_id,synthetic_account_id);
CREATE INDEX tmp_eval_expected_account_source_snapshot_i1 ON tmp_eval_expected_account_source_snapshot(module1_run_id,merchant_application_id,scenario_code);
ANALYZE tmp_eval_expected_account_source_snapshot;

CREATE TEMP TABLE tmp_eval_expected_kpi_source_projection ON COMMIT DROP AS
SELECT
    k.module1_run_id AS module1_run_id,
    k.scope_code AS scope_code,
    k.scope_type AS scope_type,
    k.scenario_code AS scenario_code,
    k.kpi_code AS kpi_code,
    k.kpi_rank AS kpi_rank,
    k.unit_code AS unit_code,
    k.applicable_flag AS applicable_flag,
    k.kpi_value_numeric AS kpi_value_numeric,
    k.kpi_value_text AS kpi_value_text,
    k.numerator_value AS numerator_value,
    k.denominator_value AS denominator_value,
    k.primary_portfolio_reason_code AS primary_portfolio_reason_code,
    k.source_scope_row_hash AS source_scope_row_hash,
    k.row_hash AS source_kpi_row_hash,
    k.created_at AS source_kpi_created_at,
    r210.contract_code AS m2_10_contract_code,
    r210.contract_version AS m2_10_contract_version,
    r210.schema_version AS m2_10_schema_version,
    r210.methodology_version AS m2_10_methodology_version,
    r210.contract_status AS m2_10_contract_status,
    r210.combined_set_hash AS m2_10_combined_set_hash,
    r210.row_hash AS m2_10_registry_row_hash
FROM tmp_src_m2_10_kpi k CROSS JOIN tmp_src_m2_10_registry r210
ORDER BY module1_run_id,scope_code,kpi_code;

CREATE UNIQUE INDEX tmp_eval_expected_kpi_source_projection_u1 ON tmp_eval_expected_kpi_source_projection (module1_run_id, scope_code, kpi_code);
ANALYZE tmp_eval_expected_kpi_source_projection;

/* Independent target-type-before-hash expected projection for msbf_m2.portfolio_strategy_kpi_source_snapshot. */
CREATE TEMP TABLE tmp_eval_expected_kpi_source_snapshot ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_eval_expected_kpi_source_snapshot') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_kpi_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_eval_expected_kpi_source_snapshot versus msbf_m2.portfolio_strategy_kpi_source_snapshot: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_eval_expected_kpi_source_snapshot
(
    module1_run_id, scope_code, scope_type, scenario_code,
    kpi_code, kpi_rank, unit_code, applicable_flag,
    kpi_value_numeric, kpi_value_text, numerator_value, denominator_value,
    primary_portfolio_reason_code, source_scope_row_hash, source_kpi_row_hash, source_kpi_created_at,
    m2_10_contract_code, m2_10_contract_version, m2_10_schema_version, m2_10_methodology_version,
    m2_10_contract_status, m2_10_combined_set_hash, m2_10_registry_row_hash, row_hash,
    created_at
)
SELECT
    p.module1_run_id,
    p.scope_code,
    p.scope_type,
    p.scenario_code,
    p.kpi_code,
    p.kpi_rank,
    p.unit_code,
    p.applicable_flag,
    p.kpi_value_numeric,
    p.kpi_value_text,
    p.numerator_value,
    p.denominator_value,
    p.primary_portfolio_reason_code,
    p.source_scope_row_hash,
    p.source_kpi_row_hash,
    p.source_kpi_created_at,
    p.m2_10_contract_code,
    p.m2_10_contract_version,
    p.m2_10_schema_version,
    p.m2_10_methodology_version,
    p.m2_10_contract_status,
    p.m2_10_combined_set_hash,
    p.m2_10_registry_row_hash,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_expected_kpi_source_projection p
ORDER BY module1_run_id,scope_code,kpi_code;

UPDATE tmp_eval_expected_kpi_source_snapshot AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

CREATE UNIQUE INDEX tmp_eval_expected_kpi_source_snapshot_u1 ON tmp_eval_expected_kpi_source_snapshot(module1_run_id,scope_code,kpi_code);
ANALYZE tmp_eval_expected_kpi_source_snapshot;

CREATE TEMP TABLE tmp_eval_expected_queue_source_projection ON COMMIT DROP AS
SELECT
    q.module1_run_id AS module1_run_id,
    q.servicing_queue_code AS servicing_queue_code,
    q.account_count AS account_count,
    q.scenario_count AS scenario_count,
    q.certified_exposure_amount AS certified_exposure_amount,
    q.payment_event_count AS payment_event_count,
    q.exception_case_count AS exception_case_count,
    q.resolved_exception_count AS resolved_exception_count,
    q.unresolved_exception_count AS unresolved_exception_count,
    q.servicing_burden_units AS servicing_burden_units,
    q.maximum_tier_rank AS maximum_tier_rank,
    q.row_hash AS source_queue_row_hash,
    q.created_at AS source_queue_created_at,
    r210.contract_code AS m2_10_contract_code,
    r210.contract_version AS m2_10_contract_version,
    r210.schema_version AS m2_10_schema_version,
    r210.methodology_version AS m2_10_methodology_version,
    r210.contract_status AS m2_10_contract_status,
    r210.combined_set_hash AS m2_10_combined_set_hash,
    r210.row_hash AS m2_10_registry_row_hash
FROM tmp_src_m2_10_queue q CROSS JOIN tmp_src_m2_10_registry r210
ORDER BY module1_run_id,servicing_queue_code;

CREATE UNIQUE INDEX tmp_eval_expected_queue_source_projection_u1 ON tmp_eval_expected_queue_source_projection (module1_run_id, servicing_queue_code);
ANALYZE tmp_eval_expected_queue_source_projection;

/* Independent target-type-before-hash expected projection for msbf_m2.portfolio_strategy_queue_source_snapshot. */
CREATE TEMP TABLE tmp_eval_expected_queue_source_snapshot ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_queue_source_snapshot WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_eval_expected_queue_source_snapshot') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_queue_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_eval_expected_queue_source_snapshot versus msbf_m2.portfolio_strategy_queue_source_snapshot: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_eval_expected_queue_source_snapshot
(
    module1_run_id, servicing_queue_code, account_count, scenario_count,
    certified_exposure_amount, payment_event_count, exception_case_count, resolved_exception_count,
    unresolved_exception_count, servicing_burden_units, maximum_tier_rank, source_queue_row_hash,
    source_queue_created_at, m2_10_contract_code, m2_10_contract_version, m2_10_schema_version,
    m2_10_methodology_version, m2_10_contract_status, m2_10_combined_set_hash, m2_10_registry_row_hash,
    row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.servicing_queue_code,
    p.account_count,
    p.scenario_count,
    p.certified_exposure_amount,
    p.payment_event_count,
    p.exception_case_count,
    p.resolved_exception_count,
    p.unresolved_exception_count,
    p.servicing_burden_units,
    p.maximum_tier_rank,
    p.source_queue_row_hash,
    p.source_queue_created_at,
    p.m2_10_contract_code,
    p.m2_10_contract_version,
    p.m2_10_schema_version,
    p.m2_10_methodology_version,
    p.m2_10_contract_status,
    p.m2_10_combined_set_hash,
    p.m2_10_registry_row_hash,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_expected_queue_source_projection p
ORDER BY module1_run_id,servicing_queue_code;

UPDATE tmp_eval_expected_queue_source_snapshot AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

CREATE UNIQUE INDEX tmp_eval_expected_queue_source_snapshot_u1 ON tmp_eval_expected_queue_source_snapshot(module1_run_id,servicing_queue_code);
ANALYZE tmp_eval_expected_queue_source_snapshot;


/* --------------------------------------------------------------------------
Full field-for-field reconciliation of the five expected snapshots to the
persisted M2.11 snapshots. Payload equality excludes only the M2.11-generated
row_hash and created_at fields. Copied upstream timestamps and every other
lineage/business field remain inside the comparison.
--------------------------------------------------------------------------- */
CREATE TEMP TABLE tmp_eval_application_source_snapshot_comparison ON COMMIT DROP AS
SELECT
  coalesce(e.module1_run_id,a.module1_run_id) AS module1_run_id,
  coalesce(e.scenario_id,a.scenario_id) AS scenario_id,
  coalesce(e.merchant_application_id,a.merchant_application_id) AS merchant_application_id,
  (e.module1_run_id IS NOT NULL) AS expected_present_flag,
  (a.module1_run_id IS NOT NULL) AS actual_present_flag,
  CASE WHEN e.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL
       THEN (to_jsonb(e)-'row_hash'-'created_at') IS DISTINCT FROM (to_jsonb(a)-'row_hash'-'created_at')
       ELSE FALSE END AS payload_mismatch_flag,
  CASE WHEN e.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL
       THEN e.row_hash IS DISTINCT FROM a.row_hash
       ELSE FALSE END AS row_hash_mismatch_flag
FROM tmp_eval_expected_application_source_snapshot e
FULL JOIN
(
  SELECT * FROM msbf_m2.portfolio_strategy_application_source_snapshot
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
) a USING(module1_run_id,scenario_id,merchant_application_id);
ANALYZE tmp_eval_application_source_snapshot_comparison;

CREATE TEMP TABLE tmp_eval_candidate_source_snapshot_comparison ON COMMIT DROP AS
SELECT
  coalesce(e.module1_run_id,a.module1_run_id) AS module1_run_id,
  coalesce(e.scenario_id,a.scenario_id) AS scenario_id,
  coalesce(e.merchant_application_id,a.merchant_application_id) AS merchant_application_id,
  coalesce(e.candidate_template_code,a.candidate_template_code) AS candidate_template_code,
  (e.module1_run_id IS NOT NULL) AS expected_present_flag,
  (a.module1_run_id IS NOT NULL) AS actual_present_flag,
  CASE WHEN e.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL
       THEN (to_jsonb(e)-'row_hash'-'created_at') IS DISTINCT FROM (to_jsonb(a)-'row_hash'-'created_at')
       ELSE FALSE END AS payload_mismatch_flag,
  CASE WHEN e.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL
       THEN e.row_hash IS DISTINCT FROM a.row_hash
       ELSE FALSE END AS row_hash_mismatch_flag
FROM tmp_eval_expected_candidate_source_snapshot e
FULL JOIN
(
  SELECT * FROM msbf_m2.portfolio_strategy_candidate_source_snapshot
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
) a USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code);
ANALYZE tmp_eval_candidate_source_snapshot_comparison;

CREATE TEMP TABLE tmp_eval_account_source_snapshot_comparison ON COMMIT DROP AS
SELECT
  coalesce(e.module1_run_id,a.module1_run_id) AS module1_run_id,
  coalesce(e.scenario_id,a.scenario_id) AS scenario_id,
  coalesce(e.merchant_application_id,a.merchant_application_id) AS merchant_application_id,
  (e.module1_run_id IS NOT NULL) AS expected_present_flag,
  (a.module1_run_id IS NOT NULL) AS actual_present_flag,
  CASE WHEN e.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL
       THEN (to_jsonb(e)-'row_hash'-'created_at') IS DISTINCT FROM (to_jsonb(a)-'row_hash'-'created_at')
       ELSE FALSE END AS payload_mismatch_flag,
  CASE WHEN e.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL
       THEN e.row_hash IS DISTINCT FROM a.row_hash
       ELSE FALSE END AS row_hash_mismatch_flag
FROM tmp_eval_expected_account_source_snapshot e
FULL JOIN
(
  SELECT * FROM msbf_m2.portfolio_strategy_account_source_snapshot
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
) a USING(module1_run_id,scenario_id,merchant_application_id);
ANALYZE tmp_eval_account_source_snapshot_comparison;

CREATE TEMP TABLE tmp_eval_kpi_source_snapshot_comparison ON COMMIT DROP AS
SELECT
  coalesce(e.module1_run_id,a.module1_run_id) AS module1_run_id,
  coalesce(e.scope_code,a.scope_code) AS scope_code,
  coalesce(e.kpi_code,a.kpi_code) AS kpi_code,
  (e.module1_run_id IS NOT NULL) AS expected_present_flag,
  (a.module1_run_id IS NOT NULL) AS actual_present_flag,
  CASE WHEN e.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL
       THEN (to_jsonb(e)-'row_hash'-'created_at') IS DISTINCT FROM (to_jsonb(a)-'row_hash'-'created_at')
       ELSE FALSE END AS payload_mismatch_flag,
  CASE WHEN e.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL
       THEN e.row_hash IS DISTINCT FROM a.row_hash
       ELSE FALSE END AS row_hash_mismatch_flag
FROM tmp_eval_expected_kpi_source_snapshot e
FULL JOIN
(
  SELECT * FROM msbf_m2.portfolio_strategy_kpi_source_snapshot
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
) a USING(module1_run_id,scope_code,kpi_code);
ANALYZE tmp_eval_kpi_source_snapshot_comparison;

CREATE TEMP TABLE tmp_eval_queue_source_snapshot_comparison ON COMMIT DROP AS
SELECT
  coalesce(e.module1_run_id,a.module1_run_id) AS module1_run_id,
  coalesce(e.servicing_queue_code,a.servicing_queue_code) AS servicing_queue_code,
  (e.module1_run_id IS NOT NULL) AS expected_present_flag,
  (a.module1_run_id IS NOT NULL) AS actual_present_flag,
  CASE WHEN e.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL
       THEN (to_jsonb(e)-'row_hash'-'created_at') IS DISTINCT FROM (to_jsonb(a)-'row_hash'-'created_at')
       ELSE FALSE END AS payload_mismatch_flag,
  CASE WHEN e.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL
       THEN e.row_hash IS DISTINCT FROM a.row_hash
       ELSE FALSE END AS row_hash_mismatch_flag
FROM tmp_eval_expected_queue_source_snapshot e
FULL JOIN
(
  SELECT * FROM msbf_m2.portfolio_strategy_queue_source_snapshot
  WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
) a USING(module1_run_id,servicing_queue_code);
ANALYZE tmp_eval_queue_source_snapshot_comparison;

CREATE TEMP TABLE tmp_eval_source_snapshot_reconciliation
(
  source_family_code text PRIMARY KEY,
  target_object_code text NOT NULL UNIQUE,
  expected_rows bigint NOT NULL,
  expected_payload_fields integer NOT NULL,
  actual_payload_fields integer NOT NULL,
  expected_row_count bigint NOT NULL,
  actual_row_count bigint NOT NULL,
  missing_rows bigint NOT NULL,
  extra_rows bigint NOT NULL,
  payload_mismatch_rows bigint NOT NULL,
  row_hash_mismatch_rows bigint NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_eval_source_snapshot_reconciliation
(source_family_code,target_object_code,expected_rows,expected_payload_fields,actual_payload_fields,
 expected_row_count,actual_row_count,missing_rows,extra_rows,payload_mismatch_rows,row_hash_mismatch_rows)
VALUES
('APPLICATION','msbf_m2.portfolio_strategy_application_source_snapshot',1500,153,
 (SELECT count(*) FROM pg_attribute WHERE attrelid='msbf_m2.portfolio_strategy_application_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped AND attname NOT IN('row_hash','created_at')),
 (SELECT count(*) FROM tmp_eval_expected_application_source_snapshot),
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)),
 (SELECT count(*) FROM tmp_eval_application_source_snapshot_comparison WHERE expected_present_flag AND NOT actual_present_flag),
 (SELECT count(*) FROM tmp_eval_application_source_snapshot_comparison WHERE NOT expected_present_flag AND actual_present_flag),
 (SELECT count(*) FROM tmp_eval_application_source_snapshot_comparison WHERE payload_mismatch_flag),
 (SELECT count(*) FROM tmp_eval_application_source_snapshot_comparison WHERE row_hash_mismatch_flag)),
('CANDIDATE','msbf_m2.portfolio_strategy_candidate_source_snapshot',557,48,
 (SELECT count(*) FROM pg_attribute WHERE attrelid='msbf_m2.portfolio_strategy_candidate_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped AND attname NOT IN('row_hash','created_at')),
 (SELECT count(*) FROM tmp_eval_expected_candidate_source_snapshot),
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_candidate_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)),
 (SELECT count(*) FROM tmp_eval_candidate_source_snapshot_comparison WHERE expected_present_flag AND NOT actual_present_flag),
 (SELECT count(*) FROM tmp_eval_candidate_source_snapshot_comparison WHERE NOT expected_present_flag AND actual_present_flag),
 (SELECT count(*) FROM tmp_eval_candidate_source_snapshot_comparison WHERE payload_mismatch_flag),
 (SELECT count(*) FROM tmp_eval_candidate_source_snapshot_comparison WHERE row_hash_mismatch_flag)),
('ACCOUNT','msbf_m2.portfolio_strategy_account_source_snapshot',59,94,
 (SELECT count(*) FROM pg_attribute WHERE attrelid='msbf_m2.portfolio_strategy_account_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped AND attname NOT IN('row_hash','created_at')),
 (SELECT count(*) FROM tmp_eval_expected_account_source_snapshot),
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_account_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)),
 (SELECT count(*) FROM tmp_eval_account_source_snapshot_comparison WHERE expected_present_flag AND NOT actual_present_flag),
 (SELECT count(*) FROM tmp_eval_account_source_snapshot_comparison WHERE NOT expected_present_flag AND actual_present_flag),
 (SELECT count(*) FROM tmp_eval_account_source_snapshot_comparison WHERE payload_mismatch_flag),
 (SELECT count(*) FROM tmp_eval_account_source_snapshot_comparison WHERE row_hash_mismatch_flag)),
('KPI','msbf_m2.portfolio_strategy_kpi_source_snapshot',72,23,
 (SELECT count(*) FROM pg_attribute WHERE attrelid='msbf_m2.portfolio_strategy_kpi_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped AND attname NOT IN('row_hash','created_at')),
 (SELECT count(*) FROM tmp_eval_expected_kpi_source_snapshot),
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)),
 (SELECT count(*) FROM tmp_eval_kpi_source_snapshot_comparison WHERE expected_present_flag AND NOT actual_present_flag),
 (SELECT count(*) FROM tmp_eval_kpi_source_snapshot_comparison WHERE NOT expected_present_flag AND actual_present_flag),
 (SELECT count(*) FROM tmp_eval_kpi_source_snapshot_comparison WHERE payload_mismatch_flag),
 (SELECT count(*) FROM tmp_eval_kpi_source_snapshot_comparison WHERE row_hash_mismatch_flag)),
('QUEUE','msbf_m2.portfolio_strategy_queue_source_snapshot',3,20,
 (SELECT count(*) FROM pg_attribute WHERE attrelid='msbf_m2.portfolio_strategy_queue_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped AND attname NOT IN('row_hash','created_at')),
 (SELECT count(*) FROM tmp_eval_expected_queue_source_snapshot),
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_queue_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)),
 (SELECT count(*) FROM tmp_eval_queue_source_snapshot_comparison WHERE expected_present_flag AND NOT actual_present_flag),
 (SELECT count(*) FROM tmp_eval_queue_source_snapshot_comparison WHERE NOT expected_present_flag AND actual_present_flag),
 (SELECT count(*) FROM tmp_eval_queue_source_snapshot_comparison WHERE payload_mismatch_flag),
 (SELECT count(*) FROM tmp_eval_queue_source_snapshot_comparison WHERE row_hash_mismatch_flag));
ANALYZE tmp_eval_source_snapshot_reconciliation;



/* ============================================================================
Section 9 — Exactly 120 positive controls
============================================================================ */

SELECT pg_temp.m2_11_add_positive(1,'M2_11_POS_001_RUN_GENERATED','LIFECYCLE','Generated run lifecycle is present',((SELECT run_status FROM tmp_eval_m2_11_validation_context))::text,'run_status=M2_11_GENERATED',((SELECT run_status='M2_11_GENERATED' FROM tmp_eval_m2_11_validation_context)),'Generated run lifecycle is present','Freeze lifecycle');

SELECT pg_temp.m2_11_add_positive(2,'M2_11_POS_002_CONTRACT_GENERATED','LIFECYCLE','Generated contract lifecycle is present',((SELECT contract_status||'|'||coalesce(generated_at::text,'<NULL>') FROM tmp_eval_m2_11_validation_context))::text,'contract_status=GENERATED and generated_at present',((SELECT contract_status='GENERATED' AND generated_at IS NOT NULL FROM tmp_eval_m2_11_validation_context)),'Generated contract lifecycle is present','Amendment A17/B6');

SELECT pg_temp.m2_11_add_positive(3,'M2_11_POS_003_NO_PRIOR_POSITIVE','LIFECYCLE','Positive-validation evidence is pristine',((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND evidence_code LIKE 'M2_11_POS_%'))::text,'0 rows',(((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND evidence_code LIKE 'M2_11_POS_%')=0)),'Positive-validation evidence is pristine','WP3 execution discipline');

SELECT pg_temp.m2_11_add_positive(4,'M2_11_POS_004_NO_PRIOR_NEGATIVE','LIFECYCLE','Negative-control evidence is pristine',((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND evidence_code LIKE 'M2_11_NEG_%'))::text,'0 rows',(((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND evidence_code LIKE 'M2_11_NEG_%')=0)),'Negative-control evidence is pristine','WP3 execution discipline');

SELECT pg_temp.m2_11_add_positive(5,'M2_11_POS_005_NO_ACCEPTANCE_STATE','LIFECYCLE','Acceptance artifacts are absent',((SELECT (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND evidence_code='M2_11_ACCEPTANCE_SUMMARY')::text||'|'||(SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION')::text))::text,'0 acceptance rows and 0 M2.11 gate rows',(((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND evidence_code='M2_11_ACCEPTANCE_SUMMARY')=0 AND (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION')=0)),'Acceptance artifacts are absent','Program 217 boundary');

SELECT pg_temp.m2_11_add_positive(6,'M2_11_POS_006_POLICY_IDENTITY','POLICY','Policy, methodology, contract, schema, and gate identities are exact',((SELECT count(*) FROM (SELECT 1 FROM msbf_ctl.m2_11_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.policy_code,p.policy_version,p.methodology_version,p.contract_code,p.contract_version,p.schema_version,p.acceptance_gate_id) IS DISTINCT FROM ('M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_POLICY_V1',1,'M2_11_METHOD_V1','M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION',1,'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1','M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION')) z))::text,'exact frozen v1 identity',(((SELECT count(*) FROM (SELECT 1 FROM msbf_ctl.m2_11_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.policy_code,p.policy_version,p.methodology_version,p.contract_code,p.contract_version,p.schema_version,p.acceptance_gate_id) IS DISTINCT FROM ('M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_POLICY_V1',1,'M2_11_METHOD_V1','M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION',1,'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1','M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION')) z)=0)),'Policy, methodology, contract, schema, and gate identities are exact','Final freeze identity');

SELECT pg_temp.m2_11_add_positive(7,'M2_11_POS_007_POLICY_COUNTS','POLICY','Policy expected counts and control inventory are exact',((SELECT count(*) FROM (SELECT 1 FROM msbf_ctl.m2_11_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.strategy_profile_rows,p.objective_definition_rows,p.constraint_definition_rows,p.reason_definition_rows,p.reporting_scope_count,p.application_source_rows,p.candidate_source_rows,p.account_source_rows,p.kpi_source_rows,p.queue_source_rows,p.candidate_evaluation_rows,p.application_simulation_rows,p.account_simulation_rows,p.strategy_summary_rows,p.frontier_rows,p.comparison_rows,p.latest_rows,p.archive_rows,p.registry_rows,p.canonical_entities,p.positive_controls,p.negative_controls) IS DISTINCT FROM (8::bigint,8::bigint,12::bigint,32::bigint,3::bigint,1500::bigint,557::bigint,59::bigint,72::bigint,3::bigint,4456::bigint,12000::bigint,472::bigint,24::bigint,24::bigint,21::bigint,24::bigint,24::bigint,1::bigint,19298::bigint,120::bigint,20::bigint)) z))::text,'19,298 canonical; 120 positive; 20 negative',(((SELECT count(*) FROM (SELECT 1 FROM msbf_ctl.m2_11_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.strategy_profile_rows,p.objective_definition_rows,p.constraint_definition_rows,p.reason_definition_rows,p.reporting_scope_count,p.application_source_rows,p.candidate_source_rows,p.account_source_rows,p.kpi_source_rows,p.queue_source_rows,p.candidate_evaluation_rows,p.application_simulation_rows,p.account_simulation_rows,p.strategy_summary_rows,p.frontier_rows,p.comparison_rows,p.latest_rows,p.archive_rows,p.registry_rows,p.canonical_entities,p.positive_controls,p.negative_controls) IS DISTINCT FROM (8::bigint,8::bigint,12::bigint,32::bigint,3::bigint,1500::bigint,557::bigint,59::bigint,72::bigint,3::bigint,4456::bigint,12000::bigint,472::bigint,24::bigint,24::bigint,21::bigint,24::bigint,24::bigint,1::bigint,19298::bigint,120::bigint,20::bigint)) z)=0)),'Policy expected counts and control inventory are exact','Final freeze counts');

SELECT pg_temp.m2_11_add_positive(8,'M2_11_POS_008_POLICY_PRECISION','POLICY','Numeric precision and score tolerance are exact',((SELECT count(*) FROM (SELECT 1 FROM msbf_ctl.m2_11_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.score_precision_scale,p.normalized_precision_scale,p.candidate_score_tolerance) IS DISTINCT FROM (12::smallint,10::smallint,0.000000000001::numeric(22,12))) z))::text,'score 12; normalized 10; tolerance 1e-12',(((SELECT count(*) FROM (SELECT 1 FROM msbf_ctl.m2_11_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.score_precision_scale,p.normalized_precision_scale,p.candidate_score_tolerance) IS DISTINCT FROM (12::smallint,10::smallint,0.000000000001::numeric(22,12))) z)=0)),'Numeric precision and score tolerance are exact','Amendment A4');

SELECT pg_temp.m2_11_add_positive(9,'M2_11_POS_009_POLICY_BOUNDARY','BOUNDARY','Synthetic non-production policy flags are all enforced',((SELECT count(*) FROM (SELECT 1 FROM msbf_ctl.m2_11_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND NOT(p.synthetic_data_only_flag AND p.non_production_boundary_flag AND p.no_external_system_update_flag AND p.no_merchant_contact_flag AND p.no_real_funds_movement_flag AND p.no_production_decisioning_flag AND p.servicing_burden_coverage_code='ACCEPTED_OPERATIONAL_ACCOUNTS_ONLY' AND NOT p.new_access_servicing_burden_estimated_flag)) z))::text,'all frozen boundary flags true; new-access burden estimate false',(((SELECT count(*) FROM (SELECT 1 FROM msbf_ctl.m2_11_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND NOT(p.synthetic_data_only_flag AND p.non_production_boundary_flag AND p.no_external_system_update_flag AND p.no_merchant_contact_flag AND p.no_real_funds_movement_flag AND p.no_production_decisioning_flag AND p.servicing_burden_coverage_code='ACCEPTED_OPERATIONAL_ACCOUNTS_ONLY' AND NOT p.new_access_servicing_burden_estimated_flag)) z)=0)),'Synthetic non-production policy flags are all enforced','Original freeze stage boundary; Amendment B4');

SELECT pg_temp.m2_11_add_positive(10,'M2_11_POS_010_POLICY_CONFIG_HASH','HASH','Policy configuration hash and inherited M2.2 bounds reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_ctl.m2_11_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.configuration_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(p.configuration_payload) OR p.configuration_payload#>>'{inherited_m2_2_structure_bounds,source_policy_code}' IS DISTINCT FROM 'M2_2_PRICING_STRUCTURE_POLICY_V1' OR p.configuration_payload#>>'{inherited_m2_2_structure_bounds,source_policy_configuration_hash}' IS DISTINCT FROM '9e03c9ee37880e3ed16e12fb0c0ce0d4' OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,minimum_candidate_amount}')::numeric(18,2) IS DISTINCT FROM 2500.00::numeric(18,2) OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,minimum_remittance_rate}')::numeric(9,6) IS DISTINCT FROM 0.050000::numeric(9,6) OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,maximum_remittance_rate}')::numeric(9,6) IS DISTINCT FROM 0.200000::numeric(9,6) OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,minimum_payback_multiple}')::numeric(9,6) IS DISTINCT FROM 1.050000::numeric(9,6) OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,maximum_payback_multiple}')::numeric(9,6) IS DISTINCT FROM 1.400000::numeric(9,6) OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,minimum_collection_horizon_days}')::integer IS DISTINCT FROM 1 OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,maximum_collection_horizon_days}')::integer IS DISTINCT FROM 120)) z))::text,'0 configuration mismatches; exact M2.2 provenance and bounds',(((SELECT count(*) FROM (SELECT 1 FROM msbf_ctl.m2_11_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.configuration_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(p.configuration_payload) OR p.configuration_payload#>>'{inherited_m2_2_structure_bounds,source_policy_code}' IS DISTINCT FROM 'M2_2_PRICING_STRUCTURE_POLICY_V1' OR p.configuration_payload#>>'{inherited_m2_2_structure_bounds,source_policy_configuration_hash}' IS DISTINCT FROM '9e03c9ee37880e3ed16e12fb0c0ce0d4' OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,minimum_candidate_amount}')::numeric(18,2) IS DISTINCT FROM 2500.00::numeric(18,2) OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,minimum_remittance_rate}')::numeric(9,6) IS DISTINCT FROM 0.050000::numeric(9,6) OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,maximum_remittance_rate}')::numeric(9,6) IS DISTINCT FROM 0.200000::numeric(9,6) OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,minimum_payback_multiple}')::numeric(9,6) IS DISTINCT FROM 1.050000::numeric(9,6) OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,maximum_payback_multiple}')::numeric(9,6) IS DISTINCT FROM 1.400000::numeric(9,6) OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,minimum_collection_horizon_days}')::integer IS DISTINCT FROM 1 OR (p.configuration_payload#>>'{inherited_m2_2_structure_bounds,maximum_collection_horizon_days}')::integer IS DISTINCT FROM 120)) z)=0)),'Policy configuration hash and inherited M2.2 bounds reconstruct','WP1/WP2 Erratum R2');

SELECT pg_temp.m2_11_add_positive(11,'M2_11_POS_011_M1_17_REGISTRY','SOURCE_IDENTITY','Accepted M1.17 registry identity',(SELECT count(*) FROM msbf_ctl.m1_17_g2_bundle_registry WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))::text,'one exact accepted identity; 1,500 rows; frozen hash',(SELECT count(*)=1 FROM msbf_ctl.m1_17_g2_bundle_registry r WHERE r.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (r.bundle_code,r.bundle_version,r.schema_version,r.methodology_version,r.integrated_consumption_rows,r.combined_g2_hash,r.bundle_status) IS NOT DISTINCT FROM ('M1_G2_CONSUMPTION_BUNDLE',1,'M1_G2_BUNDLE_SCHEMA_V1','M1_17_METHOD_V1',1500::bigint,'7d9e466da28cad2551aa99c4c40c912b','ACCEPTED')),'Accepted M1.17 registry identity','Source hierarchy family 2');

SELECT pg_temp.m2_11_add_positive(12,'M2_11_POS_012_M1_17_GATE','SOURCE_IDENTITY','Accepted M1.17 gate',(SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='G2_M1_CONTRACT')::text,'one G2_M1_CONTRACT PASS row',(SELECT count(*)=1 AND bool_and(result_status='PASS') FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='G2_M1_CONTRACT'),'Accepted M1.17 gate','Source hierarchy family 2');

SELECT pg_temp.m2_11_add_positive(13,'M2_11_POS_013_M2_2_REGISTRY','SOURCE_IDENTITY','Accepted M2.2 registry identity',(SELECT count(*) FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))::text,'one exact accepted identity; 1,500 latest; 557 candidates; frozen hash',(SELECT count(*)=1 FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (r.pricing_contract_code,r.pricing_contract_version,r.pricing_schema_version,r.methodology_version,r.pricing_latest_rows,r.candidate_rows,r.combined_set_hash,r.contract_status) IS NOT DISTINCT FROM ('M2_PRICING_STRUCTURE_CONSUMPTION',1,'M2_2_PRICING_STRUCTURE_SCHEMA_V1','M2_2_METHOD_V1',1500::bigint,557::bigint,'bbe83b187b31ea561789797322031fc6','ACCEPTED')),'Accepted M2.2 registry identity','Source hierarchy family 3');

SELECT pg_temp.m2_11_add_positive(14,'M2_11_POS_014_M2_2_GATE','SOURCE_IDENTITY','Accepted M2.2 gate',(SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER')::text,'one M2.2 PASS row',(SELECT count(*)=1 AND bool_and(result_status='PASS') FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER'),'Accepted M2.2 gate','Source hierarchy family 3');

SELECT pg_temp.m2_11_add_positive(15,'M2_11_POS_015_M2_4_REGISTRY','SOURCE_IDENTITY','Accepted M2.4 registry identity',(SELECT count(*) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))::text,'one exact accepted identity; 1,500 rows; frozen hash',(SELECT count(*)=1 FROM msbf_ctl.m2_4_portfolio_activation_contract_registry r WHERE r.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (r.contract_code,r.contract_version,r.schema_version,r.methodology_version,r.activation_latest_rows,r.combined_set_hash,r.contract_status) IS NOT DISTINCT FROM ('M2_PORTFOLIO_ACTIVATION_CONSUMPTION',1,'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1','M2_4_METHOD_V1',1500::bigint,'117450a3eea7bb3d3c74d18cc3c8e96a','ACCEPTED')),'Accepted M2.4 registry identity','Source hierarchy family 4');

SELECT pg_temp.m2_11_add_positive(16,'M2_11_POS_016_M2_4_GATE','SOURCE_IDENTITY','Accepted M2.4 gate',(SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION')::text,'one M2.4 PASS row',(SELECT count(*)=1 AND bool_and(result_status='PASS') FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'),'Accepted M2.4 gate','Source hierarchy family 4');

SELECT pg_temp.m2_11_add_positive(17,'M2_11_POS_017_M2_7_REGISTRY','SOURCE_IDENTITY','Accepted M2.7 registry identity',(SELECT count(*) FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))::text,'one exact accepted identity; 59 rows; frozen hash',(SELECT count(*)=1 FROM msbf_ctl.m2_7_operational_activation_contract_registry r WHERE r.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (r.contract_code,r.contract_version,r.schema_version,r.methodology_version,r.latest_rows,r.combined_set_hash,r.contract_status) IS NOT DISTINCT FROM ('M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION',1,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1','M2_7_METHOD_V1',59::bigint,'c8e3a472afd2a16b1183677324e9db98','ACCEPTED')),'Accepted M2.7 registry identity','Source hierarchy family 5');

SELECT pg_temp.m2_11_add_positive(18,'M2_11_POS_018_M2_7_GATE','SOURCE_IDENTITY','Accepted M2.7 gate',(SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP')::text,'one M2.7 PASS row',(SELECT count(*)=1 AND bool_and(result_status='PASS') FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'),'Accepted M2.7 gate','Source hierarchy family 5');

SELECT pg_temp.m2_11_add_positive(19,'M2_11_POS_019_M2_10_REGISTRY','SOURCE_IDENTITY','Accepted M2.10 registry identity',(SELECT count(*) FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))::text,'one exact accepted identity; 59 latest; 72 KPI; 3 queue; 59 total scenario-account rows; 44 BASELINE; 15 RECESSION_ENERGY; frozen hash',(SELECT count(*)=1 FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry r WHERE r.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (r.contract_code,r.contract_version,r.schema_version,r.methodology_version,r.latest_rows,r.kpi_snapshot_rows,r.queue_summary_rows,r.baseline_account_rows,r.stress_account_rows,r.portfolio_account_rows,r.combined_set_hash,r.contract_status) IS NOT DISTINCT FROM ('M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION',1,'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1','M2_10_METHOD_V1',59::bigint,72::bigint,3::bigint,44::bigint,15::bigint,59::bigint,'24fca7263a04397ebf21d30639f9069b','ACCEPTED')),'Accepted M2.10 registry identity','Source hierarchy family 1');

SELECT pg_temp.m2_11_add_positive(20,'M2_11_POS_020_M2_10_GATE','SOURCE_IDENTITY','Accepted M2.10 gate',(SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS')::text,'one M2.10 PASS row',(SELECT count(*)=1 AND bool_and(result_status='PASS') FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'),'Accepted M2.10 gate','Source hierarchy family 1');

SELECT pg_temp.m2_11_add_positive(21,'M2_11_POS_021_REGISTRY_SOURCE_LINEAGE','SOURCE_IDENTITY','M2.11 registry preserves all five accepted source identities',(SELECT count(*) FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND contract_version=1)::text,'one registry row with all five accepted source hashes and registry hashes',(SELECT count(*)=1 FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry r JOIN msbf_ctl.m1_17_g2_bundle_registry a ON a.module1_run_id=r.module1_run_id JOIN msbf_ctl.m2_2_pricing_structure_contract_registry b ON b.module1_run_id=r.module1_run_id JOIN msbf_ctl.m2_4_portfolio_activation_contract_registry c ON c.module1_run_id=r.module1_run_id JOIN msbf_ctl.m2_7_operational_activation_contract_registry d ON d.module1_run_id=r.module1_run_id JOIN msbf_ctl.m2_10_portfolio_analytics_contract_registry e ON e.module1_run_id=r.module1_run_id WHERE r.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND r.contract_version=1 AND (r.source_m1_17_combined_hash,r.source_m1_17_registry_row_hash,r.source_m2_2_combined_hash,r.source_m2_2_registry_row_hash,r.source_m2_4_combined_hash,r.source_m2_4_registry_row_hash,r.source_m2_7_combined_hash,r.source_m2_7_registry_row_hash,r.source_m2_10_combined_hash,r.source_m2_10_registry_row_hash) IS NOT DISTINCT FROM (a.combined_g2_hash,a.row_hash,b.combined_set_hash,b.row_hash,c.combined_set_hash,c.row_hash,d.combined_set_hash,d.row_hash,e.combined_set_hash,e.row_hash)),'M2.11 registry preserves all five accepted source identities','Five-source hierarchy');

SELECT pg_temp.m2_11_add_positive(22,'M2_11_POS_022_APP_SOURCE_LINEAGE','SOURCE_SNAPSHOT','Application snapshot fully reproduces all 153 immutable accepted-source fields',(SELECT format('expected=%s|actual=%s|fields=%s|missing=%s|extra=%s|payload=%s|hash=%s',expected_row_count,actual_row_count,actual_payload_fields,missing_rows,extra_rows,payload_mismatch_rows,row_hash_mismatch_rows) FROM tmp_eval_source_snapshot_reconciliation WHERE source_family_code='APPLICATION'),'1,500 exact rows x 153 immutable fields; 0 missing, extra, payload, and row-hash mismatches',(SELECT expected_row_count=1500 AND actual_row_count=1500 AND expected_payload_fields=153 AND actual_payload_fields=153 AND missing_rows=0 AND extra_rows=0 AND payload_mismatch_rows=0 AND row_hash_mismatch_rows=0 FROM tmp_eval_source_snapshot_reconciliation WHERE source_family_code='APPLICATION'),'Application snapshot is reconstructed from accepted M1.17, M2.2 latest, and M2.4 sources','Amendment B1; complete source-to-target mapping validation');

SELECT pg_temp.m2_11_add_positive(23,'M2_11_POS_023_CAND_SOURCE_LINEAGE','SOURCE_SNAPSHOT','Candidate snapshot fully reproduces all 48 immutable accepted-source fields',(SELECT format('expected=%s|actual=%s|fields=%s|missing=%s|extra=%s|payload=%s|hash=%s',expected_row_count,actual_row_count,actual_payload_fields,missing_rows,extra_rows,payload_mismatch_rows,row_hash_mismatch_rows) FROM tmp_eval_source_snapshot_reconciliation WHERE source_family_code='CANDIDATE'),'557 exact rows x 48 immutable fields; 0 missing, extra, payload, and row-hash mismatches',(SELECT expected_row_count=557 AND actual_row_count=557 AND expected_payload_fields=48 AND actual_payload_fields=48 AND missing_rows=0 AND extra_rows=0 AND payload_mismatch_rows=0 AND row_hash_mismatch_rows=0 FROM tmp_eval_source_snapshot_reconciliation WHERE source_family_code='CANDIDATE'),'Candidate snapshot is reconstructed from the accepted M2.2 candidate inventory','Accepted candidate restriction; complete source-to-target mapping validation');

SELECT pg_temp.m2_11_add_positive(24,'M2_11_POS_024_ACCOUNT_SOURCE_LINEAGE','SOURCE_SNAPSHOT','Account snapshot fully reproduces all 94 immutable accepted-source fields',(SELECT format('expected=%s|actual=%s|fields=%s|missing=%s|extra=%s|payload=%s|hash=%s',expected_row_count,actual_row_count,actual_payload_fields,missing_rows,extra_rows,payload_mismatch_rows,row_hash_mismatch_rows) FROM tmp_eval_source_snapshot_reconciliation WHERE source_family_code='ACCOUNT'),'59 exact rows x 94 immutable fields; 0 missing, extra, payload, and row-hash mismatches',(SELECT expected_row_count=59 AND actual_row_count=59 AND expected_payload_fields=94 AND actual_payload_fields=94 AND missing_rows=0 AND extra_rows=0 AND payload_mismatch_rows=0 AND row_hash_mismatch_rows=0 FROM tmp_eval_source_snapshot_reconciliation WHERE source_family_code='ACCOUNT'),'Account snapshot is reconstructed from accepted M2.7 and M2.10 sources','Amendment B4/B5; complete source-to-target mapping validation');

SELECT pg_temp.m2_11_add_positive(25,'M2_11_POS_025_KPI_QUEUE_LINEAGE','SOURCE_SNAPSHOT','KPI and queue snapshots fully reproduce all immutable accepted-source fields',(SELECT string_agg(source_family_code||'[expected='||expected_row_count||';actual='||actual_row_count||';fields='||actual_payload_fields||';missing='||missing_rows||';extra='||extra_rows||';payload='||payload_mismatch_rows||';hash='||row_hash_mismatch_rows||']','|' ORDER BY source_family_code) FROM tmp_eval_source_snapshot_reconciliation WHERE source_family_code IN('KPI','QUEUE')),'KPI: 72 exact rows x 23 fields; QUEUE: 3 exact rows x 20 fields; all mismatch counts 0',(SELECT count(*)=2 AND bool_and((source_family_code='KPI' AND expected_row_count=72 AND actual_row_count=72 AND expected_payload_fields=23 AND actual_payload_fields=23 OR source_family_code='QUEUE' AND expected_row_count=3 AND actual_row_count=3 AND expected_payload_fields=20 AND actual_payload_fields=20) AND missing_rows=0 AND extra_rows=0 AND payload_mismatch_rows=0 AND row_hash_mismatch_rows=0) FROM tmp_eval_source_snapshot_reconciliation WHERE source_family_code IN('KPI','QUEUE')),'KPI and queue snapshots are reconstructed from accepted M2.10 physical sources','Source hierarchy family 1; complete source-to-target mapping validation');

SELECT pg_temp.m2_11_add_positive(26,'M2_11_POS_026_STRATEGY_CODES','DEFINITION','Exactly eight frozen strategies exist in sequence',(SELECT count(*) FROM (SELECT p.strategy_profile_code FROM msbf_m2.portfolio_strategy_profile p FULL JOIN tmp_eval_expected_strategy e USING(strategy_profile_code,strategy_sequence) WHERE coalesce(p.module1_run_id,(SELECT run_id FROM tmp_eval_m2_11_validation_context))=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.strategy_profile_code IS NULL OR e.strategy_profile_code IS NULL)) z)::text,'8 exact strategy codes and sequence',(SELECT (SELECT count(*) FROM (SELECT p.strategy_profile_code FROM msbf_m2.portfolio_strategy_profile p FULL JOIN tmp_eval_expected_strategy e USING(strategy_profile_code,strategy_sequence) WHERE coalesce(p.module1_run_id,(SELECT run_id FROM tmp_eval_m2_11_validation_context))=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.strategy_profile_code IS NULL OR e.strategy_profile_code IS NULL)) z)=0),'Exactly eight frozen strategies exist in sequence','Amendment A3');

SELECT pg_temp.m2_11_add_positive(27,'M2_11_POS_027_WEIGHT_MATRIX','SCORING','Exact 8 x 8 strategy weight matrix is persisted',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_profile p JOIN tmp_eval_expected_strategy e USING(strategy_profile_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.access_rate_weight,p.selected_exposure_weight,p.finance_charge_weight,p.expected_loss_density_weight,p.risk_adjusted_contribution_weight,p.annualized_return_weight,p.servicing_burden_weight,p.payment_burden_weight) IS DISTINCT FROM (e.access_rate_weight,e.selected_exposure_weight,e.finance_charge_weight,e.expected_loss_density_weight,e.risk_adjusted_contribution_weight,e.annualized_return_weight,e.servicing_burden_weight,e.payment_burden_weight)) z))::text,'0 weight-cell mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_profile p JOIN tmp_eval_expected_strategy e USING(strategy_profile_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.access_rate_weight,p.selected_exposure_weight,p.finance_charge_weight,p.expected_loss_density_weight,p.risk_adjusted_contribution_weight,p.annualized_return_weight,p.servicing_burden_weight,p.payment_burden_weight) IS DISTINCT FROM (e.access_rate_weight,e.selected_exposure_weight,e.finance_charge_weight,e.expected_loss_density_weight,e.risk_adjusted_contribution_weight,e.annualized_return_weight,e.servicing_burden_weight,e.payment_burden_weight)) z)=0)),'Exact 8 x 8 strategy weight matrix is persisted','Amendment A3');

SELECT pg_temp.m2_11_add_positive(28,'M2_11_POS_028_CANDIDATE_WEIGHT_TOTALS','SCORING','Candidate-domain denominators are exact',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_profile p JOIN tmp_eval_expected_strategy e USING(strategy_profile_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.candidate_domain_weight_total IS DISTINCT FROM e.candidate_domain_weight_total OR p.candidate_domain_weight_total IS DISTINCT FROM round(p.access_rate_weight+p.selected_exposure_weight+p.finance_charge_weight+p.expected_loss_density_weight+p.risk_adjusted_contribution_weight+p.annualized_return_weight+p.payment_burden_weight,6))) z))::text,'six weighted strategies 1.0 except BALANCED 0.9; replay/EI 0',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_profile p JOIN tmp_eval_expected_strategy e USING(strategy_profile_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.candidate_domain_weight_total IS DISTINCT FROM e.candidate_domain_weight_total OR p.candidate_domain_weight_total IS DISTINCT FROM round(p.access_rate_weight+p.selected_exposure_weight+p.finance_charge_weight+p.expected_loss_density_weight+p.risk_adjusted_contribution_weight+p.annualized_return_weight+p.payment_burden_weight,6))) z)=0)),'Candidate-domain denominators are exact','Amendment A3/A4');

SELECT pg_temp.m2_11_add_positive(29,'M2_11_POS_029_SCOPE_WEIGHT_TOTALS','SCORING','Scope-domain denominators are exact',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_profile p JOIN tmp_eval_expected_strategy e USING(strategy_profile_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.scope_domain_weight_total IS DISTINCT FROM e.scope_domain_weight_total OR p.scope_domain_weight_total IS DISTINCT FROM round(p.access_rate_weight+p.selected_exposure_weight+p.finance_charge_weight+p.expected_loss_density_weight+p.risk_adjusted_contribution_weight+p.annualized_return_weight+p.servicing_burden_weight+p.payment_burden_weight,6))) z))::text,'seven scored strategies 1.0; baseline 0',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_profile p JOIN tmp_eval_expected_strategy e USING(strategy_profile_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.scope_domain_weight_total IS DISTINCT FROM e.scope_domain_weight_total OR p.scope_domain_weight_total IS DISTINCT FROM round(p.access_rate_weight+p.selected_exposure_weight+p.finance_charge_weight+p.expected_loss_density_weight+p.risk_adjusted_contribution_weight+p.annualized_return_weight+p.servicing_burden_weight+p.payment_burden_weight,6))) z)=0)),'Scope-domain denominators are exact','Amendment A3/A4');

SELECT pg_temp.m2_11_add_positive(30,'M2_11_POS_030_SELECTION_MODES','DEFINITION','Selection modes and exposure directions are exact',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_profile p JOIN tmp_eval_expected_strategy e USING(strategy_profile_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.selection_mode,p.selected_exposure_direction,p.candidate_scoring_applicable_flag,p.scope_scoring_applicable_flag) IS DISTINCT FROM (e.selection_mode,e.selected_exposure_direction,e.candidate_scoring_applicable_flag,e.scope_scoring_applicable_flag)) z))::text,'0 mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_profile p JOIN tmp_eval_expected_strategy e USING(strategy_profile_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.selection_mode,p.selected_exposure_direction,p.candidate_scoring_applicable_flag,p.scope_scoring_applicable_flag) IS DISTINCT FROM (e.selection_mode,e.selected_exposure_direction,e.candidate_scoring_applicable_flag,e.scope_scoring_applicable_flag)) z)=0)),'Selection modes and exposure directions are exact','Amendment A3');

SELECT pg_temp.m2_11_add_positive(31,'M2_11_POS_031_OBJECTIVE_CODES','DEFINITION','Exactly eight frozen objectives exist in sequence',(SELECT count(*) FROM (SELECT p.objective_code FROM msbf_m2.portfolio_strategy_objective_definition p FULL JOIN tmp_eval_expected_objective e USING(objective_code,objective_sequence) WHERE coalesce(p.module1_run_id,(SELECT run_id FROM tmp_eval_m2_11_validation_context))=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.objective_code IS NULL OR e.objective_code IS NULL)) z)::text,'8 exact objective codes and sequence',(SELECT (SELECT count(*) FROM (SELECT p.objective_code FROM msbf_m2.portfolio_strategy_objective_definition p FULL JOIN tmp_eval_expected_objective e USING(objective_code,objective_sequence) WHERE coalesce(p.module1_run_id,(SELECT run_id FROM tmp_eval_m2_11_validation_context))=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.objective_code IS NULL OR e.objective_code IS NULL)) z)=0),'Exactly eight frozen objectives exist in sequence','Amendment A2');

SELECT pg_temp.m2_11_add_positive(32,'M2_11_POS_032_OBJECTIVE_FORMULAS','DEFINITION','Candidate and scope objective formulas are exact',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_objective_definition p JOIN tmp_eval_expected_objective e USING(objective_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.default_direction_code,p.scoring_domain_code,p.scope_aggregation_method_code) IS DISTINCT FROM (e.default_direction_code,e.scoring_domain_code,e.scope_aggregation_method_code)) z))::text,'0 formula-semantic mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_objective_definition p JOIN tmp_eval_expected_objective e USING(objective_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.default_direction_code,p.scoring_domain_code,p.scope_aggregation_method_code) IS DISTINCT FROM (e.default_direction_code,e.scoring_domain_code,e.scope_aggregation_method_code)) z)=0)),'Candidate and scope objective formulas are exact','Amendment A2');

SELECT pg_temp.m2_11_add_positive(33,'M2_11_POS_033_PARETO_FLAGS','FRONTIER','Seven objectives are Pareto-included and exposure is excluded',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_objective_definition p JOIN tmp_eval_expected_objective e USING(objective_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND p.pareto_inclusion_flag IS DISTINCT FROM e.pareto_inclusion_flag) z))::text,'7 included; SELECTED_EXPOSURE_AMOUNT excluded',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_objective_definition p JOIN tmp_eval_expected_objective e USING(objective_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND p.pareto_inclusion_flag IS DISTINCT FROM e.pareto_inclusion_flag) z)=0)),'Seven objectives are Pareto-included and exposure is excluded','Amendment A5/A13');

SELECT pg_temp.m2_11_add_positive(34,'M2_11_POS_034_OBJECTIVE_TOLERANCES','FRONTIER','All objective equality tolerances are exact target numerics',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_objective_definition p JOIN tmp_eval_expected_objective e USING(objective_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND p.equality_tolerance IS DISTINCT FROM e.equality_tolerance) z))::text,'0 tolerance mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_objective_definition p JOIN tmp_eval_expected_objective e USING(objective_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND p.equality_tolerance IS DISTINCT FROM e.equality_tolerance) z)=0)),'All objective equality tolerances are exact target numerics','Amendment A13');

SELECT pg_temp.m2_11_add_positive(35,'M2_11_POS_035_CONSTRAINT_CODES','DEFINITION','Exactly twelve hard-constraint families exist',(SELECT count(*) FROM (SELECT p.constraint_code FROM msbf_m2.portfolio_strategy_constraint_definition p FULL JOIN tmp_eval_expected_constraint e USING(constraint_code,constraint_sequence) WHERE coalesce(p.module1_run_id,(SELECT run_id FROM tmp_eval_m2_11_validation_context))=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.constraint_code IS NULL OR e.constraint_code IS NULL)) z)::text,'12 exact codes and sequence',(SELECT (SELECT count(*) FROM (SELECT p.constraint_code FROM msbf_m2.portfolio_strategy_constraint_definition p FULL JOIN tmp_eval_expected_constraint e USING(constraint_code,constraint_sequence) WHERE coalesce(p.module1_run_id,(SELECT run_id FROM tmp_eval_m2_11_validation_context))=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.constraint_code IS NULL OR e.constraint_code IS NULL)) z)=0),'Exactly twelve hard-constraint families exist','Original freeze constraints');

SELECT pg_temp.m2_11_add_positive(36,'M2_11_POS_036_CONSTRAINT_BLOCKING','DEFINITION','All hard constraints are blocking with frozen applicability',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_constraint_definition p JOIN tmp_eval_expected_constraint e USING(constraint_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.constraint_family_code,p.applicability_code,p.severity_code,p.evaluation_rule_code,p.blocking_flag) IS DISTINCT FROM (e.constraint_family_code,e.applicability_code,e.severity_code,e.evaluation_rule_code,TRUE)) z))::text,'0 definition mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_constraint_definition p JOIN tmp_eval_expected_constraint e USING(constraint_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.constraint_family_code,p.applicability_code,p.severity_code,p.evaluation_rule_code,p.blocking_flag) IS DISTINCT FROM (e.constraint_family_code,e.applicability_code,e.severity_code,e.evaluation_rule_code,TRUE)) z)=0)),'All hard constraints are blocking with frozen applicability','Original freeze constraints');

SELECT pg_temp.m2_11_add_positive(37,'M2_11_POS_037_REASON_CODES','DEFINITION','Exactly thirty-two reason codes exist',(SELECT count(*) FROM (SELECT p.reason_code FROM msbf_m2.portfolio_strategy_reason_definition p FULL JOIN tmp_eval_expected_reason e USING(reason_code,reason_sequence) WHERE coalesce(p.module1_run_id,(SELECT run_id FROM tmp_eval_m2_11_validation_context))=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.reason_code IS NULL OR e.reason_code IS NULL)) z)::text,'32 exact codes and sequence',(SELECT (SELECT count(*) FROM (SELECT p.reason_code FROM msbf_m2.portfolio_strategy_reason_definition p FULL JOIN tmp_eval_expected_reason e USING(reason_code,reason_sequence) WHERE coalesce(p.module1_run_id,(SELECT run_id FROM tmp_eval_m2_11_validation_context))=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.reason_code IS NULL OR e.reason_code IS NULL)) z)=0),'Exactly thirty-two reason codes exist','Amendment A16');

SELECT pg_temp.m2_11_add_positive(38,'M2_11_POS_038_REASON_SEVERITY','DEFINITION','Reason severities and ranks are internally exact',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_reason_definition p JOIN tmp_eval_expected_reason e USING(reason_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.reason_family,p.severity_code,p.severity_rank,p.applicability_code) IS DISTINCT FROM (e.reason_family,e.severity_code,e.severity_rank,e.applicability_code)) z))::text,'0 severity/rank mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_reason_definition p JOIN tmp_eval_expected_reason e USING(reason_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.reason_family,p.severity_code,p.severity_rank,p.applicability_code) IS DISTINCT FROM (e.reason_family,e.severity_code,e.severity_rank,e.applicability_code)) z)=0)),'Reason severities and ranks are internally exact','Amendment A16');

SELECT pg_temp.m2_11_add_positive(39,'M2_11_POS_039_REASON_NONPRODUCTION','BOUNDARY','All reasons prohibit production and external action',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_reason_definition p WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.production_action_flag OR p.external_system_update_flag OR p.merchant_contact_flag OR p.production_adverse_action_flag)) z))::text,'all 32 rows false on all four flags',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_reason_definition p WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (p.production_action_flag OR p.external_system_update_flag OR p.merchant_contact_flag OR p.production_adverse_action_flag)) z)=0)),'All reasons prohibit production and external action','Amendment A16');

SELECT pg_temp.m2_11_add_positive(40,'M2_11_POS_040_DEFINITION_ROW_HASHES','HASH','Four physical definition dictionaries reconstruct from persisted fields',((SELECT sum(mismatch_count) FROM tmp_registry_validation_physical_hash_mismatch WHERE object_sequence BETWEEN 2 AND 5))::text,'0 physical row-hash mismatches',(((SELECT sum(mismatch_count) FROM tmp_registry_validation_physical_hash_mismatch WHERE object_sequence BETWEEN 2 AND 5)=0)),'Four physical definition dictionaries reconstruct from persisted fields','WP1/WP2 Erratum R2');

SELECT pg_temp.m2_11_add_positive(41,'M2_11_POS_041_POLICY_GRAIN','COUNT_GRAIN','Policy profile count and run grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,count(*) FROM msbf_ctl.m2_11_policy_profile WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id HAVING count(*)<>1) d)::text FROM msbf_ctl.m2_11_policy_profile WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'1 row; unique run',(((SELECT count(*) FROM msbf_ctl.m2_11_policy_profile WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=1 AND NOT EXISTS(SELECT 1 FROM msbf_ctl.m2_11_policy_profile WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id HAVING count(*)<>1))),'Policy profile count and run grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(42,'M2_11_POS_042_STRATEGY_GRAIN','COUNT_GRAIN','Strategy profile count and grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,strategy_profile_code,count(*) FROM msbf_m2.portfolio_strategy_profile WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,strategy_profile_code HAVING count(*)<>1) d)::text FROM msbf_m2.portfolio_strategy_profile WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'8 rows; unique run/strategy',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_profile WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=8 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_profile WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,strategy_profile_code HAVING count(*)<>1))),'Strategy profile count and grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(43,'M2_11_POS_043_OBJECTIVE_GRAIN','COUNT_GRAIN','Objective definition count and grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,objective_code,count(*) FROM msbf_m2.portfolio_strategy_objective_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,objective_code HAVING count(*)<>1) d)::text FROM msbf_m2.portfolio_strategy_objective_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'8 rows; unique run/objective',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_objective_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=8 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_objective_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,objective_code HAVING count(*)<>1))),'Objective definition count and grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(44,'M2_11_POS_044_CONSTRAINT_GRAIN','COUNT_GRAIN','Constraint definition count and grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,constraint_code,count(*) FROM msbf_m2.portfolio_strategy_constraint_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,constraint_code HAVING count(*)<>1) d)::text FROM msbf_m2.portfolio_strategy_constraint_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'12 rows; unique run/constraint',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_constraint_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=12 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_constraint_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,constraint_code HAVING count(*)<>1))),'Constraint definition count and grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(45,'M2_11_POS_045_REASON_GRAIN','COUNT_GRAIN','Reason definition count and grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,reason_code,count(*) FROM msbf_m2.portfolio_strategy_reason_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,reason_code HAVING count(*)<>1) d)::text FROM msbf_m2.portfolio_strategy_reason_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'32 rows; unique run/reason',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_reason_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=32 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_reason_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,reason_code HAVING count(*)<>1))),'Reason definition count and grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(46,'M2_11_POS_046_APP_SOURCE_GRAIN','COUNT_GRAIN','Application source count and grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)<>1) d)::text FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'1,500 rows; unique scenario/application',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=1500 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)<>1))),'Application source count and grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(47,'M2_11_POS_047_CAND_SOURCE_GRAIN','COUNT_GRAIN','Candidate source count and grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,scenario_id,merchant_application_id,candidate_template_code,count(*) FROM msbf_m2.portfolio_strategy_candidate_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code HAVING count(*)<>1) d)::text FROM msbf_m2.portfolio_strategy_candidate_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'557 rows; unique scenario/application/template',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_candidate_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=557 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_candidate_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code HAVING count(*)<>1))),'Candidate source count and grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(48,'M2_11_POS_048_ACCOUNT_SOURCE_GRAIN','COUNT_GRAIN','Account source count and grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) FROM msbf_m2.portfolio_strategy_account_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)<>1) d)::text FROM msbf_m2.portfolio_strategy_account_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'59 rows; unique scenario/application',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_account_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=59 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_account_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)<>1))),'Account source count and grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(49,'M2_11_POS_049_KPI_SOURCE_GRAIN','COUNT_GRAIN','KPI source count and grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,scope_code,kpi_code,count(*) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scope_code,kpi_code HAVING count(*)<>1) d)::text FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'72 rows; unique scope/KPI',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=72 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scope_code,kpi_code HAVING count(*)<>1))),'KPI source count and grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(50,'M2_11_POS_050_QUEUE_SOURCE_GRAIN','COUNT_GRAIN','Queue source count and grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,servicing_queue_code,count(*) FROM msbf_m2.portfolio_strategy_queue_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,servicing_queue_code HAVING count(*)<>1) d)::text FROM msbf_m2.portfolio_strategy_queue_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'3 rows; unique queue',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_queue_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=3 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_queue_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,servicing_queue_code HAVING count(*)<>1))),'Queue source count and grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(51,'M2_11_POS_051_CAND_EVAL_GRAIN','COUNT_GRAIN','Candidate evaluation count and grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code,count(*) FROM msbf_m2.application_strategy_candidate_evaluation WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code HAVING count(*)<>1) d)::text FROM msbf_m2.application_strategy_candidate_evaluation WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'4,456 rows; unique candidate/strategy',(((SELECT count(*) FROM msbf_m2.application_strategy_candidate_evaluation WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=4456 AND NOT EXISTS(SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code HAVING count(*)<>1))),'Candidate evaluation count and grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(52,'M2_11_POS_052_APP_SIM_GRAIN','COUNT_GRAIN','Application simulation count and grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,count(*) FROM msbf_m2.application_portfolio_strategy_simulation WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code HAVING count(*)<>1) d)::text FROM msbf_m2.application_portfolio_strategy_simulation WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'12,000 rows; unique scenario/application/strategy',(((SELECT count(*) FROM msbf_m2.application_portfolio_strategy_simulation WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=12000 AND NOT EXISTS(SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code HAVING count(*)<>1))),'Application simulation count and grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(53,'M2_11_POS_053_ACCOUNT_SIM_GRAIN','COUNT_GRAIN','Account simulation count and grain',((SELECT count(*)::text||'|'||(SELECT count(*) FROM (SELECT module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,count(*) FROM msbf_m2.account_servicing_strategy_simulation WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code HAVING count(*)<>1) d)::text FROM msbf_m2.account_servicing_strategy_simulation WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'472 rows; unique scenario/application/strategy',(((SELECT count(*) FROM msbf_m2.account_servicing_strategy_simulation WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=472 AND NOT EXISTS(SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code HAVING count(*)<>1))),'Account simulation count and grain','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(54,'M2_11_POS_054_SUMMARY_FRONTIER_COMPARISON_GRAIN','COUNT_GRAIN','Summary/frontier/comparison counts and grains',((SELECT (SELECT count(*) FROM msbf_m2.portfolio_strategy_summary)::text||'|'||(SELECT count(*) FROM msbf_m2.portfolio_strategy_frontier)::text||'|'||(SELECT count(*) FROM msbf_m2.portfolio_strategy_comparison)::text))::text,'24/24/21 exact grains',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_summary)=24 AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_frontier)=24 AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_comparison)=21 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_summary GROUP BY module1_run_id,strategy_profile_code,reporting_scope_code HAVING count(*)<>1) AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_frontier GROUP BY module1_run_id,strategy_profile_code,reporting_scope_code HAVING count(*)<>1) AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_comparison GROUP BY module1_run_id,reporting_scope_code,challenger_strategy_profile_code HAVING count(*)<>1))),'Summary/frontier/comparison counts and grains','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(55,'M2_11_POS_055_CONTRACT_GRAINS','COUNT_GRAIN','Latest/archive/registry counts and grains',((SELECT (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_latest)::text||'|'||(SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_archive)::text||'|'||(SELECT count(*) FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry)::text))::text,'24/24/1 exact grains',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_latest)=24 AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_archive)=24 AND (SELECT count(*) FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry)=1 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_simulation_latest GROUP BY module1_run_id,strategy_profile_code,reporting_scope_code HAVING count(*)<>1) AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_simulation_archive GROUP BY module1_run_id,contract_version,strategy_profile_code,reporting_scope_code HAVING count(*)<>1))),'Latest/archive/registry counts and grains','Final freeze physical counts');

SELECT pg_temp.m2_11_add_positive(56,'M2_11_POS_056_SCENARIO_PANELS','SOURCE_POPULATION','Application scenario panels are exactly balanced',((SELECT string_agg(scenario_code||'='||n,'|' ORDER BY scenario_code) FROM (SELECT scenario_code,count(*)::text n FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY scenario_code) q))::text,'750 BASELINE; 750 RECESSION_ENERGY',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scenario_code='BASELINE')=750 AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scenario_code='RECESSION_ENERGY')=750)),'Application scenario panels are exactly balanced','Original freeze scopes');

SELECT pg_temp.m2_11_add_positive(57,'M2_11_POS_057_MATCHED_APPLICATIONS','SOURCE_POPULATION','Every application has one row in each scenario',((SELECT count(*) FROM (SELECT merchant_application_id FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY merchant_application_id HAVING count(DISTINCT scenario_code)<>2 OR count(*)<>2) q))::text,'750 matched applications; 0 unpaired',((NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) GROUP BY merchant_application_id HAVING count(DISTINCT scenario_code)<>2 OR count(*)<>2) AND (SELECT count(DISTINCT merchant_application_id) FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=750)),'Every application has one row in each scenario','Amendment A12');

SELECT pg_temp.m2_11_add_positive(58,'M2_11_POS_058_ACCEPTED_CANDIDATES_ONLY','SOURCE_POPULATION','Candidate snapshot contains accepted candidates only and no implicit alternative',((SELECT count(*)::text||'|'||count(*) FILTER(WHERE candidate_template_code='IMPLICIT_NO_ACCESS')::text FROM msbf_m2.portfolio_strategy_candidate_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'557 accepted; 0 IMPLICIT_NO_ACCESS',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_candidate_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=557 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_candidate_source_snapshot WHERE candidate_template_code='IMPLICIT_NO_ACCESS'))),'Candidate snapshot contains accepted candidates only and no implicit alternative','Amendment B2');

SELECT pg_temp.m2_11_add_positive(59,'M2_11_POS_059_SOURCE_SELECTED_CANDIDATES','SOURCE_POPULATION','Every source-selected candidate resolves to accepted inventory',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_application_source_snapshot a LEFT JOIN msbf_m2.portfolio_strategy_candidate_source_snapshot c ON c.module1_run_id=a.module1_run_id AND c.scenario_id=a.scenario_id AND c.merchant_application_id=a.merchant_application_id AND c.candidate_template_code=a.selected_candidate_template_code AND c.source_candidate_row_hash=a.selected_candidate_row_hash WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND a.selected_candidate_template_code IS NOT NULL AND c.module1_run_id IS NULL) z))::text,'0 unresolved selected candidates',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_application_source_snapshot a LEFT JOIN msbf_m2.portfolio_strategy_candidate_source_snapshot c ON c.module1_run_id=a.module1_run_id AND c.scenario_id=a.scenario_id AND c.merchant_application_id=a.merchant_application_id AND c.candidate_template_code=a.selected_candidate_template_code AND c.source_candidate_row_hash=a.selected_candidate_row_hash WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND a.selected_candidate_template_code IS NOT NULL AND c.module1_run_id IS NULL) z)=0)),'Every source-selected candidate resolves to accepted inventory','Amendment A8/B1');

SELECT pg_temp.m2_11_add_positive(60,'M2_11_POS_060_NO_STRUCTURE_SELECTION','SOURCE_POPULATION','No-structure outcomes carry no selected candidate',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_application_source_snapshot a WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND NOT a.structure_available_flag AND (a.selected_candidate_template_code IS NOT NULL OR a.selected_candidate_row_hash IS NOT NULL OR a.selected_funding_amount IS NOT NULL)) z))::text,'0 inconsistent no-structure rows',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_application_source_snapshot a WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND NOT a.structure_available_flag AND (a.selected_candidate_template_code IS NOT NULL OR a.selected_candidate_row_hash IS NOT NULL OR a.selected_funding_amount IS NOT NULL)) z)=0)),'No-structure outcomes carry no selected candidate','Amendment A9');

SELECT pg_temp.m2_11_add_positive(61,'M2_11_POS_061_STRUCTURE_CANDIDATE_POP','SOURCE_POPULATION','Structure-available applications have candidate population',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_application_source_snapshot a LEFT JOIN (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) n FROM msbf_m2.portfolio_strategy_candidate_source_snapshot GROUP BY 1,2,3) c USING(module1_run_id,scenario_id,merchant_application_id) WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND a.structure_available_flag AND (coalesce(c.n,0)=0 OR coalesce(c.n,0)<>a.candidate_count)) z))::text,'0 missing or count-mismatched populations',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_application_source_snapshot a LEFT JOIN (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) n FROM msbf_m2.portfolio_strategy_candidate_source_snapshot GROUP BY 1,2,3) c USING(module1_run_id,scenario_id,merchant_application_id) WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND a.structure_available_flag AND (coalesce(c.n,0)=0 OR coalesce(c.n,0)<>a.candidate_count)) z)=0)),'Structure-available applications have candidate population','Amendment B1');

SELECT pg_temp.m2_11_add_positive(62,'M2_11_POS_062_SOURCE_JOIN_ONE_TO_ONE','SOURCE_POPULATION','M1.17, M2.2 latest, and M2.4 source join remains one-to-one',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_application_source_snapshot a WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND a.source_join_status_code<>'MATCHED_ONE_TO_ONE') z))::text,'1,500 MATCHED_ONE_TO_ONE',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_application_source_snapshot a WHERE a.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND a.source_join_status_code<>'MATCHED_ONE_TO_ONE') z)=0)),'M1.17, M2.2 latest, and M2.4 source join remains one-to-one','Source materialization rules');

SELECT pg_temp.m2_11_add_positive(63,'M2_11_POS_063_ACCOUNT_SCENARIO_COUNTS','ACCOUNT_POPULATION','Operational account scenario counts are exact',((SELECT count(*) FILTER(WHERE scenario_code='BASELINE')::text||'|'||count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY')::text||'|'||count(DISTINCT merchant_application_id)::text FROM msbf_m2.portfolio_strategy_account_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)))::text,'44 BASELINE; 15 stress; 44 distinct',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_account_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scenario_code='BASELINE')=44 AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_account_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scenario_code='RECESSION_ENERGY')=15 AND (SELECT count(DISTINCT merchant_application_id) FROM msbf_m2.portfolio_strategy_account_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=44)),'Operational account scenario counts are exact','Amendment B4');

SELECT pg_temp.m2_11_add_positive(64,'M2_11_POS_064_ACCOUNT_STRESS_MATCH','ACCOUNT_POPULATION','Every stress operational account has a baseline match',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_account_source_snapshot s LEFT JOIN msbf_m2.portfolio_strategy_account_source_snapshot b ON b.module1_run_id=s.module1_run_id AND b.merchant_application_id=s.merchant_application_id AND b.scenario_code='BASELINE' WHERE s.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND s.scenario_code='RECESSION_ENERGY' AND b.module1_run_id IS NULL) z))::text,'0 unmatched stress accounts',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_account_source_snapshot s LEFT JOIN msbf_m2.portfolio_strategy_account_source_snapshot b ON b.module1_run_id=s.module1_run_id AND b.merchant_application_id=s.merchant_application_id AND b.scenario_code='BASELINE' WHERE s.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND s.scenario_code='RECESSION_ENERGY' AND b.module1_run_id IS NULL) z)=0)),'Every stress operational account has a baseline match','Amendment B4');

SELECT pg_temp.m2_11_add_positive(65,'M2_11_POS_065_KPI_QUEUE_COVERAGE','SOURCE_POPULATION','M2.10 KPI source-scope identities and queue populations are exact',(SELECT concat_ws('|','kpi_rows='||(SELECT count(*) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))::text,'scope_codes='||(SELECT count(DISTINCT scope_code) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))::text,'global_kpi_codes='||(SELECT count(DISTINCT kpi_code) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))::text,'baseline='||(SELECT count(*) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scope_code='BASELINE' AND scope_type='SCENARIO' AND scenario_code='BASELINE')::text,'recession_energy='||(SELECT count(*) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scope_code='RECESSION_ENERGY' AND scope_type='SCENARIO' AND scenario_code='RECESSION_ENERGY')::text,'portfolio_all='||(SELECT count(*) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scope_code='PORTFOLIO_ALL' AND scope_type='PORTFOLIO' AND scenario_code IS NULL)::text,'queue_rows='||(SELECT count(*) FROM msbf_m2.portfolio_strategy_queue_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))::text))::text,'72 total KPI rows; exact source scopes BASELINE/SCENARIO/BASELINE, RECESSION_ENERGY/SCENARIO/RECESSION_ENERGY, PORTFOLIO_ALL/PORTFOLIO/NULL; 24 KPI codes each; 3 queues',((SELECT count(*) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=72 AND (SELECT count(DISTINCT scope_code) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=3 AND (SELECT count(DISTINCT kpi_code) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=24 AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scope_code='BASELINE' AND scope_type='SCENARIO' AND scenario_code='BASELINE')=24 AND (SELECT count(DISTINCT kpi_code) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scope_code='BASELINE' AND scope_type='SCENARIO' AND scenario_code='BASELINE')=24 AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scope_code='RECESSION_ENERGY' AND scope_type='SCENARIO' AND scenario_code='RECESSION_ENERGY')=24 AND (SELECT count(DISTINCT kpi_code) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scope_code='RECESSION_ENERGY' AND scope_type='SCENARIO' AND scenario_code='RECESSION_ENERGY')=24 AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scope_code='PORTFOLIO_ALL' AND scope_type='PORTFOLIO' AND scenario_code IS NULL)=24 AND (SELECT count(DISTINCT kpi_code) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND scope_code='PORTFOLIO_ALL' AND scope_type='PORTFOLIO' AND scenario_code IS NULL)=24 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (((scope_code='BASELINE' AND scope_type='SCENARIO' AND scenario_code='BASELINE') OR (scope_code='RECESSION_ENERGY' AND scope_type='SCENARIO' AND scenario_code='RECESSION_ENERGY') OR (scope_code='PORTFOLIO_ALL' AND scope_type='PORTFOLIO' AND scenario_code IS NULL)) IS NOT TRUE)) AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_queue_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context))=3),'M2.10 KPI source-scope identities and queue populations are exact','M2.10 source family; PORTFOLIO_ALL is a source key and is distinct from M2.11 PORTFOLIO reporting scope');

SELECT pg_temp.m2_11_add_positive(66,'M2_11_POS_066_BASELINE_APP_REPLAY','BASELINE_REPLAY','BASELINE_REPLAY exactly reproduces 1,500 accepted application outcomes',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation s JOIN msbf_m2.portfolio_strategy_application_source_snapshot a USING(module1_run_id,scenario_id,scenario_code,merchant_application_id) WHERE s.strategy_profile_code='BASELINE_REPLAY' AND (jsonb_build_object('pricing',s.replay_pricing_disposition_code,'structure',s.replay_structure_available_flag,'review',s.replay_review_required_flag,'candidate',s.replay_selected_candidate_template_code,'candidate_hash',s.replay_selected_candidate_row_hash,'requested',s.replay_requested_funding_amount,'funding',s.replay_selected_funding_amount,'remittance',s.replay_selected_remittance_rate,'payback',s.replay_selected_payback_multiple,'horizon',s.replay_selected_collection_horizon_days,'repayment',s.replay_selected_total_repayment_amount,'charge',s.replay_selected_finance_charge_amount,'daily',s.replay_selected_implied_daily_collection_amount,'payoff',s.replay_selected_implied_payoff_days,'ratio',s.replay_selected_amount_to_request_ratio,'candidate_count',s.replay_candidate_count,'counteroffer',s.replay_counteroffer_foundation_flag,'stress',s.replay_stress_nonimprovement_applied_flag,'routing',s.replay_routing_evidence_status,'decision',s.replay_source_final_decision_outcome_code,'activation',s.replay_activation_outcome_code,'activation_rank',s.replay_activation_outcome_rank,'book_eligible',s.replay_booking_eligible_flag,'book_auth',s.replay_booking_authorized_flag,'fund_auth',s.replay_funding_authorized_flag,'fund_done',s.replay_funding_completed_flag,'portfolio',s.replay_portfolio_activated_flag,'review_req',s.replay_operational_review_required_flag,'accept_assumed',s.replay_synthetic_offer_acceptance_assumed_flag,'account',s.replay_synthetic_account_id,'advance',s.replay_synthetic_advance_id,'booked',s.replay_booked_amount,'funded',s.replay_funded_amount,'act_remit',s.replay_activation_remittance_rate,'act_payback',s.replay_activation_payback_multiple,'act_horizon',s.replay_activation_collection_horizon_days,'act_repay',s.replay_activation_total_repayment_amount,'act_charge',s.replay_activation_finance_charge_amount,'act_daily',s.replay_activation_implied_daily_collection_amount,'act_payoff',s.replay_activation_implied_payoff_days,'act_evidence',s.replay_activation_evidence_status) IS DISTINCT FROM jsonb_build_object('pricing',a.pricing_disposition_code,'structure',a.structure_available_flag,'review',a.review_required_flag,'candidate',a.selected_candidate_template_code,'candidate_hash',a.selected_candidate_row_hash,'requested',a.requested_funding_amount,'funding',a.selected_funding_amount,'remittance',a.selected_remittance_rate,'payback',a.selected_payback_multiple,'horizon',a.selected_collection_horizon_days,'repayment',a.selected_total_repayment_amount,'charge',a.selected_finance_charge_amount,'daily',a.selected_implied_daily_collection_amount,'payoff',a.selected_implied_payoff_days,'ratio',a.selected_amount_to_request_ratio,'candidate_count',a.candidate_count,'counteroffer',a.counteroffer_foundation_flag,'stress',a.stress_nonimprovement_applied_flag,'routing',a.routing_evidence_status,'decision',a.source_final_decision_outcome_code,'activation',a.activation_outcome_code,'activation_rank',a.activation_outcome_rank,'book_eligible',a.booking_eligible_flag,'book_auth',a.booking_authorized_flag,'fund_auth',a.funding_authorized_flag,'fund_done',a.funding_completed_flag,'portfolio',a.portfolio_activated_flag,'review_req',a.operational_review_required_flag,'accept_assumed',a.synthetic_offer_acceptance_assumed_flag,'account',a.synthetic_account_id,'advance',a.synthetic_advance_id,'booked',a.booked_amount,'funded',a.funded_amount,'act_remit',a.activation_remittance_rate,'act_payback',a.activation_payback_multiple,'act_horizon',a.activation_collection_horizon_days,'act_repay',a.activation_total_repayment_amount,'act_charge',a.activation_finance_charge_amount,'act_daily',a.activation_implied_daily_collection_amount,'act_payoff',a.activation_implied_payoff_days,'act_evidence',a.activation_evidence_status) OR NOT coalesce(s.baseline_replay_match_flag,FALSE))) z))::text,'0 of 1,500 mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation s JOIN msbf_m2.portfolio_strategy_application_source_snapshot a USING(module1_run_id,scenario_id,scenario_code,merchant_application_id) WHERE s.strategy_profile_code='BASELINE_REPLAY' AND (jsonb_build_object('pricing',s.replay_pricing_disposition_code,'structure',s.replay_structure_available_flag,'review',s.replay_review_required_flag,'candidate',s.replay_selected_candidate_template_code,'candidate_hash',s.replay_selected_candidate_row_hash,'requested',s.replay_requested_funding_amount,'funding',s.replay_selected_funding_amount,'remittance',s.replay_selected_remittance_rate,'payback',s.replay_selected_payback_multiple,'horizon',s.replay_selected_collection_horizon_days,'repayment',s.replay_selected_total_repayment_amount,'charge',s.replay_selected_finance_charge_amount,'daily',s.replay_selected_implied_daily_collection_amount,'payoff',s.replay_selected_implied_payoff_days,'ratio',s.replay_selected_amount_to_request_ratio,'candidate_count',s.replay_candidate_count,'counteroffer',s.replay_counteroffer_foundation_flag,'stress',s.replay_stress_nonimprovement_applied_flag,'routing',s.replay_routing_evidence_status,'decision',s.replay_source_final_decision_outcome_code,'activation',s.replay_activation_outcome_code,'activation_rank',s.replay_activation_outcome_rank,'book_eligible',s.replay_booking_eligible_flag,'book_auth',s.replay_booking_authorized_flag,'fund_auth',s.replay_funding_authorized_flag,'fund_done',s.replay_funding_completed_flag,'portfolio',s.replay_portfolio_activated_flag,'review_req',s.replay_operational_review_required_flag,'accept_assumed',s.replay_synthetic_offer_acceptance_assumed_flag,'account',s.replay_synthetic_account_id,'advance',s.replay_synthetic_advance_id,'booked',s.replay_booked_amount,'funded',s.replay_funded_amount,'act_remit',s.replay_activation_remittance_rate,'act_payback',s.replay_activation_payback_multiple,'act_horizon',s.replay_activation_collection_horizon_days,'act_repay',s.replay_activation_total_repayment_amount,'act_charge',s.replay_activation_finance_charge_amount,'act_daily',s.replay_activation_implied_daily_collection_amount,'act_payoff',s.replay_activation_implied_payoff_days,'act_evidence',s.replay_activation_evidence_status) IS DISTINCT FROM jsonb_build_object('pricing',a.pricing_disposition_code,'structure',a.structure_available_flag,'review',a.review_required_flag,'candidate',a.selected_candidate_template_code,'candidate_hash',a.selected_candidate_row_hash,'requested',a.requested_funding_amount,'funding',a.selected_funding_amount,'remittance',a.selected_remittance_rate,'payback',a.selected_payback_multiple,'horizon',a.selected_collection_horizon_days,'repayment',a.selected_total_repayment_amount,'charge',a.selected_finance_charge_amount,'daily',a.selected_implied_daily_collection_amount,'payoff',a.selected_implied_payoff_days,'ratio',a.selected_amount_to_request_ratio,'candidate_count',a.candidate_count,'counteroffer',a.counteroffer_foundation_flag,'stress',a.stress_nonimprovement_applied_flag,'routing',a.routing_evidence_status,'decision',a.source_final_decision_outcome_code,'activation',a.activation_outcome_code,'activation_rank',a.activation_outcome_rank,'book_eligible',a.booking_eligible_flag,'book_auth',a.booking_authorized_flag,'fund_auth',a.funding_authorized_flag,'fund_done',a.funding_completed_flag,'portfolio',a.portfolio_activated_flag,'review_req',a.operational_review_required_flag,'accept_assumed',a.synthetic_offer_acceptance_assumed_flag,'account',a.synthetic_account_id,'advance',a.synthetic_advance_id,'booked',a.booked_amount,'funded',a.funded_amount,'act_remit',a.activation_remittance_rate,'act_payback',a.activation_payback_multiple,'act_horizon',a.activation_collection_horizon_days,'act_repay',a.activation_total_repayment_amount,'act_charge',a.activation_finance_charge_amount,'act_daily',a.activation_implied_daily_collection_amount,'act_payoff',a.activation_implied_payoff_days,'act_evidence',a.activation_evidence_status) OR NOT coalesce(s.baseline_replay_match_flag,FALSE))) z)=0)),'BASELINE_REPLAY exactly reproduces 1,500 accepted application outcomes','Amendment A8');

SELECT pg_temp.m2_11_add_positive(67,'M2_11_POS_067_EARLY_APP_REPLAY','BASELINE_REPLAY','EARLY_INTERVENTION application structure exactly replays baseline',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation e JOIN msbf_m2.application_portfolio_strategy_simulation b ON b.module1_run_id=e.module1_run_id AND b.scenario_id=e.scenario_id AND b.merchant_application_id=e.merchant_application_id AND b.strategy_profile_code='BASELINE_REPLAY' WHERE e.strategy_profile_code='EARLY_INTERVENTION' AND (e.strategy_outcome_code,e.feasibility_class,e.access_selected_flag,e.controlled_review_flag,e.selected_candidate_template_code,e.selected_candidate_source_row_hash,e.selected_exposure_amount,e.selected_finance_charge_amount,e.selected_expected_loss_amount,e.selected_risk_adjusted_contribution,e.selected_annualized_risk_adjusted_return,e.selected_payment_burden_rate) IS DISTINCT FROM (b.strategy_outcome_code,b.feasibility_class,b.access_selected_flag,b.controlled_review_flag,b.selected_candidate_template_code,b.selected_candidate_source_row_hash,b.selected_exposure_amount,b.selected_finance_charge_amount,b.selected_expected_loss_amount,b.selected_risk_adjusted_contribution,b.selected_annualized_risk_adjusted_return,b.selected_payment_burden_rate)) z))::text,'0 of 1,500 mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation e JOIN msbf_m2.application_portfolio_strategy_simulation b ON b.module1_run_id=e.module1_run_id AND b.scenario_id=e.scenario_id AND b.merchant_application_id=e.merchant_application_id AND b.strategy_profile_code='BASELINE_REPLAY' WHERE e.strategy_profile_code='EARLY_INTERVENTION' AND (e.strategy_outcome_code,e.feasibility_class,e.access_selected_flag,e.controlled_review_flag,e.selected_candidate_template_code,e.selected_candidate_source_row_hash,e.selected_exposure_amount,e.selected_finance_charge_amount,e.selected_expected_loss_amount,e.selected_risk_adjusted_contribution,e.selected_annualized_risk_adjusted_return,e.selected_payment_burden_rate) IS DISTINCT FROM (b.strategy_outcome_code,b.feasibility_class,b.access_selected_flag,b.controlled_review_flag,b.selected_candidate_template_code,b.selected_candidate_source_row_hash,b.selected_exposure_amount,b.selected_finance_charge_amount,b.selected_expected_loss_amount,b.selected_risk_adjusted_contribution,b.selected_annualized_risk_adjusted_return,b.selected_payment_burden_rate)) z)=0)),'EARLY_INTERVENTION application structure exactly replays baseline','Amendment A11');

SELECT pg_temp.m2_11_add_positive(68,'M2_11_POS_068_BASELINE_ACCOUNT_REPLAY','BASELINE_REPLAY','BASELINE_REPLAY exactly reproduces 59 account postures',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation s JOIN msbf_m2.portfolio_strategy_account_source_snapshot a USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,synthetic_account_id) WHERE s.strategy_profile_code='BASELINE_REPLAY' AND (s.account_source_snapshot_row_hash,s.source_account_posture_code,s.source_account_posture_rank,s.source_operational_setup_outcome_code,s.source_operational_setup_action_code,s.source_operational_setup_queue_code,s.source_operational_activation_date,s.source_next_reassessment_date,s.source_payment_factor,s.source_setup_duration_days,s.source_reassessment_interval_days,s.source_certified_state_code,s.source_servicing_queue_code,s.source_certified_exposure_amount,s.source_servicing_burden_units,s.source_replay_match_flag) IS DISTINCT FROM (a.row_hash,a.source_account_posture_code,a.source_account_posture_rank,a.operational_setup_outcome_code,a.operational_setup_action_code,a.operational_setup_queue_code,a.operational_activation_date,a.next_reassessment_date,a.applied_temporary_payment_factor,a.applied_setup_duration_days,a.applied_reassessment_interval_days,a.certified_state_code,a.servicing_queue_code,a.certified_exposure_amount,a.servicing_burden_units,TRUE)) z))::text,'0 of 59 mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation s JOIN msbf_m2.portfolio_strategy_account_source_snapshot a USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,synthetic_account_id) WHERE s.strategy_profile_code='BASELINE_REPLAY' AND (s.account_source_snapshot_row_hash,s.source_account_posture_code,s.source_account_posture_rank,s.source_operational_setup_outcome_code,s.source_operational_setup_action_code,s.source_operational_setup_queue_code,s.source_operational_activation_date,s.source_next_reassessment_date,s.source_payment_factor,s.source_setup_duration_days,s.source_reassessment_interval_days,s.source_certified_state_code,s.source_servicing_queue_code,s.source_certified_exposure_amount,s.source_servicing_burden_units,s.source_replay_match_flag) IS DISTINCT FROM (a.row_hash,a.source_account_posture_code,a.source_account_posture_rank,a.operational_setup_outcome_code,a.operational_setup_action_code,a.operational_setup_queue_code,a.operational_activation_date,a.next_reassessment_date,a.applied_temporary_payment_factor,a.applied_setup_duration_days,a.applied_reassessment_interval_days,a.certified_state_code,a.servicing_queue_code,a.certified_exposure_amount,a.servicing_burden_units,TRUE)) z)=0)),'BASELINE_REPLAY exactly reproduces 59 account postures','Amendment A8/B4');

SELECT pg_temp.m2_11_add_positive(69,'M2_11_POS_069_SEVEN_ACCOUNT_REPLAY','BASELINE_REPLAY','Seven non-EARLY strategies exactly replay account servicing',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation s WHERE s.strategy_profile_code<>'EARLY_INTERVENTION' AND (s.servicing_treatment_code<>'SOURCE_SERVICING_REPLAY' OR s.simulated_payment_factor IS DISTINCT FROM s.source_payment_factor OR s.simulated_exposure_amount IS DISTINCT FROM s.source_certified_exposure_amount OR s.incremental_servicing_burden_units<>0 OR s.strategy_servicing_burden_units IS DISTINCT FROM s.source_servicing_burden_units OR NOT s.source_replay_match_flag)) z))::text,'0 of 413 mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation s WHERE s.strategy_profile_code<>'EARLY_INTERVENTION' AND (s.servicing_treatment_code<>'SOURCE_SERVICING_REPLAY' OR s.simulated_payment_factor IS DISTINCT FROM s.source_payment_factor OR s.simulated_exposure_amount IS DISTINCT FROM s.source_certified_exposure_amount OR s.incremental_servicing_burden_units<>0 OR s.strategy_servicing_burden_units IS DISTINCT FROM s.source_servicing_burden_units OR NOT s.source_replay_match_flag)) z)=0)),'Seven non-EARLY strategies exactly replay account servicing','Amendment B4');

SELECT pg_temp.m2_11_add_positive(70,'M2_11_POS_070_EARLY_ACCOUNT_TREATMENT','EARLY_INTERVENTION','EARLY_INTERVENTION timing and burden treatment is exact',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation s JOIN tmp_eval_account_expected_base e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE s.strategy_profile_code='EARLY_INTERVENTION' AND (s.servicing_treatment_code,s.treatment_applicable_flag,s.simulated_action_date,s.simulated_payment_factor,s.simulated_exposure_amount,s.incremental_servicing_burden_units,s.strategy_servicing_burden_units) IS DISTINCT FROM (e.expected_servicing_treatment_code,e.expected_treatment_applicable_flag,e.expected_simulated_action_date,e.expected_simulated_payment_factor,e.expected_simulated_exposure_amount,e.expected_incremental_servicing_burden_units,e.expected_strategy_servicing_burden_units)) z))::text,'59 rows; +2.000000 total; 0 mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation s JOIN tmp_eval_account_expected_base e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE s.strategy_profile_code='EARLY_INTERVENTION' AND (s.servicing_treatment_code,s.treatment_applicable_flag,s.simulated_action_date,s.simulated_payment_factor,s.simulated_exposure_amount,s.incremental_servicing_burden_units,s.strategy_servicing_burden_units) IS DISTINCT FROM (e.expected_servicing_treatment_code,e.expected_treatment_applicable_flag,e.expected_simulated_action_date,e.expected_simulated_payment_factor,e.expected_simulated_exposure_amount,e.expected_incremental_servicing_burden_units,e.expected_strategy_servicing_burden_units)) z)=0)),'EARLY_INTERVENTION timing and burden treatment is exact','Amendment A11/B4');

SELECT pg_temp.m2_11_add_positive(71,'M2_11_POS_071_CAND_EVAL_ACCEPTED','CANDIDATE_VALIDATION','All candidate evaluations resolve to accepted candidates and exclude implicit no access',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p LEFT JOIN msbf_m2.portfolio_strategy_candidate_source_snapshot c USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (c.module1_run_id IS NULL OR p.candidate_template_code='IMPLICIT_NO_ACCESS' OR NOT p.accepted_candidate_flag)) z))::text,'accepted identity and absence of temporary alternative',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p LEFT JOIN msbf_m2.portfolio_strategy_candidate_source_snapshot c USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code) WHERE p.module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (c.module1_run_id IS NULL OR p.candidate_template_code='IMPLICIT_NO_ACCESS' OR NOT p.accepted_candidate_flag)) z)=0)),'All candidate evaluations resolve to accepted candidates and exclude implicit no access','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(72,'M2_11_POS_072_CAND_SOURCE_INTEGRITY','CANDIDATE_VALIDATION','Candidate source-integrity status independently reconstructs',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.source_integrity_pass_flag,p.source_evidence_status_code) IS DISTINCT FROM (e.expected_source_integrity_pass_flag,e.expected_source_evidence_status_code)) z))::text,'source identity predicate exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.source_integrity_pass_flag,p.source_evidence_status_code) IS DISTINCT FROM (e.expected_source_integrity_pass_flag,e.expected_source_evidence_status_code)) z)=0)),'Candidate source-integrity status independently reconstructs','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(73,'M2_11_POS_073_CAND_HARD_CONSTRAINTS','CANDIDATE_VALIDATION','Hard-constraint arrays and violation counts independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.hard_constraint_violation_count,p.hard_constraint_codes) IS DISTINCT FROM (e.expected_hard_constraint_violation_count,e.expected_hard_constraint_codes)) z))::text,'constraint array/count exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.hard_constraint_violation_count,p.hard_constraint_codes) IS DISTINCT FROM (e.expected_hard_constraint_violation_count,e.expected_hard_constraint_codes)) z)=0)),'Hard-constraint arrays and violation counts independently reconstruct','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(74,'M2_11_POS_074_CAND_FEASIBILITY','CANDIDATE_VALIDATION','Candidate feasibility class and rank independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.feasibility_class,p.feasibility_rank) IS DISTINCT FROM (e.expected_feasibility_class,e.expected_feasibility_rank)) z))::text,'class/rank exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.feasibility_class,p.feasibility_rank) IS DISTINCT FROM (e.expected_feasibility_class,e.expected_feasibility_rank)) z)=0)),'Candidate feasibility class and rank independently reconstruct','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(75,'M2_11_POS_075_CAND_OBJECTIVE_EVIDENCE','CANDIDATE_VALIDATION','Objective-evidence completeness independently reconstructs',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.objective_evidence_complete_flag IS DISTINCT FROM e.expected_objective_evidence_complete_flag) z))::text,'evidence flag exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.objective_evidence_complete_flag IS DISTINCT FROM e.expected_objective_evidence_complete_flag) z)=0)),'Objective-evidence completeness independently reconstructs','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(76,'M2_11_POS_076_CAND_ACCESS_RAW','CANDIDATE_VALIDATION','Candidate access raw value independently reconstructs',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.access_rate_raw_value IS DISTINCT FROM e.expected_access_raw) z))::text,'raw access indicator exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.access_rate_raw_value IS DISTINCT FROM e.expected_access_raw) z)=0)),'Candidate access raw value independently reconstructs','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(77,'M2_11_POS_077_CAND_OTHER_RAW','CANDIDATE_VALIDATION','Six non-access raw objective values independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.selected_exposure_amount_raw_value,p.finance_charge_amount_raw_value,p.expected_loss_density_raw_value,p.risk_adjusted_contribution_raw_value,p.annualized_risk_adjusted_return_raw_value,p.payment_burden_rate_raw_value) IS DISTINCT FROM (e.expected_exposure_raw,e.expected_finance_raw,e.expected_loss_raw,e.expected_contribution_raw,e.expected_return_raw,e.expected_payment_raw)) z))::text,'all raw values exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.selected_exposure_amount_raw_value,p.finance_charge_amount_raw_value,p.expected_loss_density_raw_value,p.risk_adjusted_contribution_raw_value,p.annualized_risk_adjusted_return_raw_value,p.payment_burden_rate_raw_value) IS DISTINCT FROM (e.expected_exposure_raw,e.expected_finance_raw,e.expected_loss_raw,e.expected_contribution_raw,e.expected_return_raw,e.expected_payment_raw)) z)=0)),'Six non-access raw objective values independently reconstruct','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(78,'M2_11_POS_078_CAND_BOUNDS','CANDIDATE_VALIDATION','Candidate scoring min/max bounds include implicit no-access alternative',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.access_rate_minimum_value,p.access_rate_maximum_value,p.selected_exposure_amount_minimum_value,p.selected_exposure_amount_maximum_value,p.finance_charge_amount_minimum_value,p.finance_charge_amount_maximum_value,p.expected_loss_density_minimum_value,p.expected_loss_density_maximum_value,p.risk_adjusted_contribution_minimum_value,p.risk_adjusted_contribution_maximum_value,p.annualized_risk_adjusted_return_minimum_value,p.annualized_risk_adjusted_return_maximum_value,p.payment_burden_rate_minimum_value,p.payment_burden_rate_maximum_value) IS DISTINCT FROM (e.access_min,e.access_max,e.exposure_min,e.exposure_max,e.finance_min,e.finance_max,e.loss_min,e.loss_max,e.contribution_min,e.contribution_max,e.return_min,e.return_max,e.payment_min,e.payment_max)) z))::text,'all persisted bounds exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.access_rate_minimum_value,p.access_rate_maximum_value,p.selected_exposure_amount_minimum_value,p.selected_exposure_amount_maximum_value,p.finance_charge_amount_minimum_value,p.finance_charge_amount_maximum_value,p.expected_loss_density_minimum_value,p.expected_loss_density_maximum_value,p.risk_adjusted_contribution_minimum_value,p.risk_adjusted_contribution_maximum_value,p.annualized_risk_adjusted_return_minimum_value,p.annualized_risk_adjusted_return_maximum_value,p.payment_burden_rate_minimum_value,p.payment_burden_rate_maximum_value) IS DISTINCT FROM (e.access_min,e.access_max,e.exposure_min,e.exposure_max,e.finance_min,e.finance_max,e.loss_min,e.loss_max,e.contribution_min,e.contribution_max,e.return_min,e.return_max,e.payment_min,e.payment_max)) z)=0)),'Candidate scoring min/max bounds include implicit no-access alternative','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(79,'M2_11_POS_079_CAND_ACCESS_NORM','CANDIDATE_VALIDATION','Access normalization independently reconstructs',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.access_rate_normalized_value IS DISTINCT FROM e.access_norm) z))::text,'access normalized value exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.access_rate_normalized_value IS DISTINCT FROM e.access_norm) z)=0)),'Access normalization independently reconstructs','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(80,'M2_11_POS_080_CAND_EXPOSURE_NORM','CANDIDATE_VALIDATION','Exposure normalization respects strategy direction',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.selected_exposure_amount_normalized_value IS DISTINCT FROM e.exposure_norm) z))::text,'exposure normalized value exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.selected_exposure_amount_normalized_value IS DISTINCT FROM e.exposure_norm) z)=0)),'Exposure normalization respects strategy direction','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(81,'M2_11_POS_081_CAND_FINANCE_NORM','CANDIDATE_VALIDATION','Finance-charge normalization independently reconstructs',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.finance_charge_amount_normalized_value IS DISTINCT FROM e.finance_norm) z))::text,'finance normalized value exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.finance_charge_amount_normalized_value IS DISTINCT FROM e.finance_norm) z)=0)),'Finance-charge normalization independently reconstructs','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(82,'M2_11_POS_082_CAND_LOSS_NORM','CANDIDATE_VALIDATION','Loss-density normalization independently reconstructs',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.expected_loss_density_normalized_value IS DISTINCT FROM e.loss_norm) z))::text,'loss normalized value exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.expected_loss_density_normalized_value IS DISTINCT FROM e.loss_norm) z)=0)),'Loss-density normalization independently reconstructs','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(83,'M2_11_POS_083_CAND_CONTRIBUTION_NORM','CANDIDATE_VALIDATION','Contribution normalization independently reconstructs',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.risk_adjusted_contribution_normalized_value IS DISTINCT FROM e.contribution_norm) z))::text,'contribution normalized value exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.risk_adjusted_contribution_normalized_value IS DISTINCT FROM e.contribution_norm) z)=0)),'Contribution normalization independently reconstructs','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(84,'M2_11_POS_084_CAND_RETURN_NORM','CANDIDATE_VALIDATION','Annualized-return normalization independently reconstructs',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.annualized_risk_adjusted_return_normalized_value IS DISTINCT FROM e.return_norm) z))::text,'return normalized value exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.annualized_risk_adjusted_return_normalized_value IS DISTINCT FROM e.return_norm) z)=0)),'Annualized-return normalization independently reconstructs','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(85,'M2_11_POS_085_CAND_PAYMENT_NORM','CANDIDATE_VALIDATION','Payment-burden normalization independently reconstructs',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.payment_burden_rate_normalized_value IS DISTINCT FROM e.payment_norm) z))::text,'payment normalized value exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE p.payment_burden_rate_normalized_value IS DISTINCT FROM e.payment_norm) z)=0)),'Payment-burden normalization independently reconstructs','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(86,'M2_11_POS_086_CAND_WEIGHTED_COMPONENTS','CANDIDATE_VALIDATION','All candidate weighted contributions independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.access_rate_weighted_contribution,p.selected_exposure_amount_weighted_contribution,p.finance_charge_amount_weighted_contribution,p.expected_loss_density_weighted_contribution,p.risk_adjusted_contribution_weighted_contribution,p.annualized_risk_adjusted_return_weighted_contribution,p.payment_burden_rate_weighted_contribution) IS DISTINCT FROM (e.access_component,e.exposure_component,e.finance_component,e.loss_component,e.contribution_component,e.return_component,e.payment_component)) z))::text,'seven weighted components exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.access_rate_weighted_contribution,p.selected_exposure_amount_weighted_contribution,p.finance_charge_amount_weighted_contribution,p.expected_loss_density_weighted_contribution,p.risk_adjusted_contribution_weighted_contribution,p.annualized_risk_adjusted_return_weighted_contribution,p.payment_burden_rate_weighted_contribution) IS DISTINCT FROM (e.access_component,e.exposure_component,e.finance_component,e.loss_component,e.contribution_component,e.return_component,e.payment_component)) z)=0)),'All candidate weighted contributions independently reconstruct','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(87,'M2_11_POS_087_CAND_OBJECTIVE_SCORE','CANDIDATE_VALIDATION','Candidate objective scores and null rules independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.applicable_candidate_weight_total,p.objective_score) IS DISTINCT FROM (e.candidate_domain_weight_total,e.expected_objective_score)) z))::text,'score and denominator exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.applicable_candidate_weight_total,p.objective_score) IS DISTINCT FROM (e.candidate_domain_weight_total,e.expected_objective_score)) z)=0)),'Candidate objective scores and null rules independently reconstruct','Amendment A2-A10 and B2-B3');

SELECT pg_temp.m2_11_add_positive(88,'M2_11_POS_088_CAND_SELECTION_TIEBREAK','CANDIDATE_VALIDATION','Candidate selection, tolerance tie-break, and reason evidence independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.objective_score_tie_flag,p.candidate_selected_flag,p.primary_reason_code,p.reason_codes) IS DISTINCT FROM (e.expected_tie_flag,e.expected_selected_flag,e.expected_primary_reason_code,e.expected_reason_codes)) z))::text,'selected flag, tie flag, and reasons exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_strategy_candidate_evaluation p JOIN tmp_eval_candidate_expected e USING(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code) WHERE (p.objective_score_tie_flag,p.candidate_selected_flag,p.primary_reason_code,p.reason_codes) IS DISTINCT FROM (e.expected_tie_flag,e.expected_selected_flag,e.expected_primary_reason_code,e.expected_reason_codes)) z)=0)),'Candidate selection, tolerance tie-break, and reason evidence independently reconstruct','Amendment A2-A10/A16 and B2-B3');

SELECT pg_temp.m2_11_add_positive(89,'M2_11_POS_089_APP_OUTCOME','APPLICATION_VALIDATION','Application strategy outcomes and severity ranks independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN tmp_eval_application_expected e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.strategy_outcome_code,p.strategy_outcome_rank,p.feasibility_class,p.feasibility_rank,p.access_selected_flag,p.controlled_review_flag,p.implicit_no_access_selected_flag,p.policy_decline_preserved_flag,p.insufficient_evidence_preserved_flag,p.source_integrity_blocked_flag) IS DISTINCT FROM (e.expected_strategy_outcome_code,e.expected_strategy_outcome_rank,e.expected_feasibility_class,e.expected_feasibility_rank,e.expected_access_selected_flag,e.expected_controlled_review_flag,e.expected_implicit_no_access_selected_flag,e.expected_policy_decline_preserved_flag,e.expected_insufficient_evidence_preserved_flag,e.expected_source_integrity_blocked_flag)) z))::text,'outcome/rank exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN tmp_eval_application_expected e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.strategy_outcome_code,p.strategy_outcome_rank,p.feasibility_class,p.feasibility_rank,p.access_selected_flag,p.controlled_review_flag,p.implicit_no_access_selected_flag,p.policy_decline_preserved_flag,p.insufficient_evidence_preserved_flag,p.source_integrity_blocked_flag) IS DISTINCT FROM (e.expected_strategy_outcome_code,e.expected_strategy_outcome_rank,e.expected_feasibility_class,e.expected_feasibility_rank,e.expected_access_selected_flag,e.expected_controlled_review_flag,e.expected_implicit_no_access_selected_flag,e.expected_policy_decline_preserved_flag,e.expected_insufficient_evidence_preserved_flag,e.expected_source_integrity_blocked_flag)) z)=0)),'Application strategy outcomes and severity ranks independently reconstruct','Amendment A7-A12; B2-B5');

SELECT pg_temp.m2_11_add_positive(90,'M2_11_POS_090_APP_CANDIDATE_INVENTORY','APPLICATION_VALIDATION','Every selected application candidate exists in accepted M2.2 inventory',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p LEFT JOIN msbf_m2.portfolio_strategy_candidate_source_snapshot c ON c.module1_run_id=p.module1_run_id AND c.scenario_id=p.scenario_id AND c.merchant_application_id=p.merchant_application_id AND c.candidate_template_code=p.selected_candidate_template_code AND c.source_candidate_row_hash=p.selected_candidate_source_row_hash WHERE p.selected_candidate_template_code IS NOT NULL AND c.module1_run_id IS NULL) z))::text,'0 unaccepted selections',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p LEFT JOIN msbf_m2.portfolio_strategy_candidate_source_snapshot c ON c.module1_run_id=p.module1_run_id AND c.scenario_id=p.scenario_id AND c.merchant_application_id=p.merchant_application_id AND c.candidate_template_code=p.selected_candidate_template_code AND c.source_candidate_row_hash=p.selected_candidate_source_row_hash WHERE p.selected_candidate_template_code IS NOT NULL AND c.module1_run_id IS NULL) z)=0)),'Every selected application candidate exists in accepted M2.2 inventory','Amendment A7-A12; B2-B5');

SELECT pg_temp.m2_11_add_positive(91,'M2_11_POS_091_APP_SELECTED_EVAL','APPLICATION_VALIDATION','Every selected candidate maps to the expected selected evaluation',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN tmp_eval_application_expected e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.selected_candidate_template_code,p.selected_candidate_source_row_hash,p.selected_candidate_evaluation_row_hash,p.selection_objective_score) IS DISTINCT FROM (e.expected_selected_candidate_template_code,e.expected_selected_candidate_source_row_hash,e.expected_selected_candidate_evaluation_row_hash,e.expected_selection_objective_score)) z))::text,'0 selection association mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN tmp_eval_application_expected e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.selected_candidate_template_code,p.selected_candidate_source_row_hash,p.selected_candidate_evaluation_row_hash,p.selection_objective_score) IS DISTINCT FROM (e.expected_selected_candidate_template_code,e.expected_selected_candidate_source_row_hash,e.expected_selected_candidate_evaluation_row_hash,e.expected_selection_objective_score)) z)=0)),'Every selected candidate maps to the expected selected evaluation','Amendment A7-A12; B2-B5');

SELECT pg_temp.m2_11_add_positive(92,'M2_11_POS_092_POLICY_DECLINE_PRESERVED','APPLICATION_VALIDATION','Policy-decline outcomes are preserved across all strategies',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN msbf_m2.portfolio_strategy_application_source_snapshot a USING(module1_run_id,scenario_id,scenario_code,merchant_application_id) WHERE a.pricing_disposition_code='NO_STRUCTURE_POLICY_DECLINE' AND p.strategy_outcome_code<>'NO_ACCESS_POLICY_DECLINE') z))::text,'0 favorable overrides',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN msbf_m2.portfolio_strategy_application_source_snapshot a USING(module1_run_id,scenario_id,scenario_code,merchant_application_id) WHERE a.pricing_disposition_code='NO_STRUCTURE_POLICY_DECLINE' AND p.strategy_outcome_code<>'NO_ACCESS_POLICY_DECLINE') z)=0)),'Policy-decline outcomes are preserved across all strategies','Amendment A7-A12; B2-B5');

SELECT pg_temp.m2_11_add_positive(93,'M2_11_POS_093_INSUFFICIENT_PRESERVED','APPLICATION_VALIDATION','Insufficient-evidence outcomes are preserved across all strategies',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN msbf_m2.portfolio_strategy_application_source_snapshot a USING(module1_run_id,scenario_id,scenario_code,merchant_application_id) WHERE a.pricing_disposition_code='NO_STRUCTURE_INSUFFICIENT_EVIDENCE' AND p.strategy_outcome_code<>'NO_ACCESS_INSUFFICIENT_EVIDENCE') z))::text,'0 favorable overrides',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN msbf_m2.portfolio_strategy_application_source_snapshot a USING(module1_run_id,scenario_id,scenario_code,merchant_application_id) WHERE a.pricing_disposition_code='NO_STRUCTURE_INSUFFICIENT_EVIDENCE' AND p.strategy_outcome_code<>'NO_ACCESS_INSUFFICIENT_EVIDENCE') z)=0)),'Insufficient-evidence outcomes are preserved across all strategies','Amendment A7-A12; B2-B5');

SELECT pg_temp.m2_11_add_positive(94,'M2_11_POS_094_NO_HARD_FAVORABLE_OVERRIDE','APPLICATION_VALIDATION','Blocked or hard-constrained candidates never produce favorable access',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p WHERE p.hard_constraint_violation_count>0 AND p.strategy_outcome_code='ACCESS_SELECTED') z))::text,'0 prohibited favorable outcomes',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p WHERE p.hard_constraint_violation_count>0 AND p.strategy_outcome_code='ACCESS_SELECTED') z)=0)),'Blocked or hard-constrained candidates never produce favorable access','Amendment A7-A12; B2-B5');

SELECT pg_temp.m2_11_add_positive(95,'M2_11_POS_095_NO_ACCESS_ECONOMICS','APPLICATION_VALIDATION','No-access economic fields follow zero/null convention',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p WHERE p.strategy_outcome_code NOT IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') AND (p.selected_exposure_amount<>0 OR p.selected_total_repayment_amount<>0 OR p.selected_finance_charge_amount<>0 OR p.selected_expected_loss_amount<>0 OR p.selected_expected_loss_density IS NOT NULL OR p.selected_risk_adjusted_contribution<>0 OR p.selected_annualized_risk_adjusted_return<>0 OR p.selected_payment_burden_rate<>0)) z))::text,'0 persistence mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p WHERE p.strategy_outcome_code NOT IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') AND (p.selected_exposure_amount<>0 OR p.selected_total_repayment_amount<>0 OR p.selected_finance_charge_amount<>0 OR p.selected_expected_loss_amount<>0 OR p.selected_expected_loss_density IS NOT NULL OR p.selected_risk_adjusted_contribution<>0 OR p.selected_annualized_risk_adjusted_return<>0 OR p.selected_payment_burden_rate<>0)) z)=0)),'No-access economic fields follow zero/null convention','Amendment A7-A12; B2-B5');

SELECT pg_temp.m2_11_add_positive(96,'M2_11_POS_096_ACCESS_ECONOMICS','APPLICATION_VALIDATION','Access/review economics reproduce selected accepted candidate or replay source',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN tmp_eval_application_expected e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.selected_exposure_amount,p.selected_remittance_rate,p.selected_payback_multiple,p.selected_collection_horizon_days,p.selected_total_repayment_amount,p.selected_finance_charge_amount,p.selected_implied_daily_collection_amount,p.selected_implied_payoff_days,p.selected_amount_to_request_ratio,p.selected_acquisition_economics_amount,p.selected_expected_loss_amount,p.selected_expected_loss_density,p.selected_risk_adjusted_contribution,p.selected_annualized_risk_adjusted_return,p.selected_payment_burden_rate) IS DISTINCT FROM (e.expected_selected_exposure_amount,e.expected_selected_remittance_rate,e.expected_selected_payback_multiple,e.expected_selected_collection_horizon_days,e.expected_selected_total_repayment_amount,e.expected_selected_finance_charge_amount,e.expected_selected_implied_daily_collection_amount,e.expected_selected_implied_payoff_days,e.expected_selected_amount_to_request_ratio,e.expected_selected_acquisition_economics_amount,e.expected_selected_expected_loss_amount,e.expected_selected_expected_loss_density,e.expected_selected_risk_adjusted_contribution,e.expected_selected_annualized_return,e.expected_selected_payment_burden_rate)) z))::text,'0 economics mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN tmp_eval_application_expected e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.selected_exposure_amount,p.selected_remittance_rate,p.selected_payback_multiple,p.selected_collection_horizon_days,p.selected_total_repayment_amount,p.selected_finance_charge_amount,p.selected_implied_daily_collection_amount,p.selected_implied_payoff_days,p.selected_amount_to_request_ratio,p.selected_acquisition_economics_amount,p.selected_expected_loss_amount,p.selected_expected_loss_density,p.selected_risk_adjusted_contribution,p.selected_annualized_risk_adjusted_return,p.selected_payment_burden_rate) IS DISTINCT FROM (e.expected_selected_exposure_amount,e.expected_selected_remittance_rate,e.expected_selected_payback_multiple,e.expected_selected_collection_horizon_days,e.expected_selected_total_repayment_amount,e.expected_selected_finance_charge_amount,e.expected_selected_implied_daily_collection_amount,e.expected_selected_implied_payoff_days,e.expected_selected_amount_to_request_ratio,e.expected_selected_acquisition_economics_amount,e.expected_selected_expected_loss_amount,e.expected_selected_expected_loss_density,e.expected_selected_risk_adjusted_contribution,e.expected_selected_annualized_return,e.expected_selected_payment_burden_rate)) z)=0)),'Access/review economics reproduce selected accepted candidate or replay source','Amendment A7-A12; B2-B5');

SELECT pg_temp.m2_11_add_positive(97,'M2_11_POS_097_ACCOUNT_APPLICABILITY','APPLICATION_VALIDATION','Operational-account applicability and NOT_APPLICABLE rules are exact',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN tmp_eval_application_expected e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.operational_account_present_flag,p.account_certification_constraint_applicability,p.constraint_unresolved_exception_count,p.source_unresolved_exception_count,p.source_certified_state_code,p.source_servicing_queue_code,p.source_certified_exposure_amount,p.certification_blocked_flag,p.source_lineage_intact_flag) IS DISTINCT FROM (e.expected_operational_account_present_flag,e.expected_account_applicability,e.expected_constraint_unresolved_exception_count,e.account_unresolved_exception_count,e.account_certified_state_code,e.account_servicing_queue_code,e.account_certified_exposure_amount,coalesce(e.account_certification_blocked_flag,FALSE),coalesce(e.account_source_lineage_intact_flag,TRUE))) z))::text,'0 applicability/source-value mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN tmp_eval_application_expected e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.operational_account_present_flag,p.account_certification_constraint_applicability,p.constraint_unresolved_exception_count,p.source_unresolved_exception_count,p.source_certified_state_code,p.source_servicing_queue_code,p.source_certified_exposure_amount,p.certification_blocked_flag,p.source_lineage_intact_flag) IS DISTINCT FROM (e.expected_operational_account_present_flag,e.expected_account_applicability,e.expected_constraint_unresolved_exception_count,e.account_unresolved_exception_count,e.account_certified_state_code,e.account_servicing_queue_code,e.account_certified_exposure_amount,coalesce(e.account_certification_blocked_flag,FALSE),coalesce(e.account_source_lineage_intact_flag,TRUE))) z)=0)),'Operational-account applicability and NOT_APPLICABLE rules are exact','Amendment A7-A12; B2-B5');

SELECT pg_temp.m2_11_add_positive(98,'M2_11_POS_098_STRESS_FLAGS','APPLICATION_VALIDATION','Stress flags and application reason evidence independently reconstruct for all 12,000 rows',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN tmp_eval_application_reason_expected e USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,strategy_profile_code) WHERE (p.source_risk_improvement_violation_flag,p.source_return_improvement_violation_flag,p.strategy_access_improvement_violation_flag,p.strategy_feasibility_improvement_violation_flag,p.comparable_payment_burden_improvement_violation_flag,p.comparable_servicing_burden_improvement_violation_flag,p.strategy_restriction_flag,p.absolute_workload_reduction_flag,p.stress_nonimprovement_pass_flag,p.primary_reason_code,p.reason_codes) IS DISTINCT FROM (e.expected_source_risk_improvement_violation_flag,e.expected_source_return_improvement_violation_flag,e.expected_strategy_access_improvement_violation_flag,e.expected_strategy_feasibility_improvement_violation_flag,e.expected_comparable_payment_burden_improvement_violation_flag,e.expected_comparable_servicing_burden_improvement_violation_flag,e.expected_strategy_restriction_flag,e.expected_absolute_workload_reduction_flag,e.expected_stress_nonimprovement_pass_flag,e.expected_primary_reason_code,e.expected_reason_codes)) z))::text,'0 stress/reason mismatches across 12,000 rows',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN tmp_eval_application_reason_expected e USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,strategy_profile_code) WHERE (p.source_risk_improvement_violation_flag,p.source_return_improvement_violation_flag,p.strategy_access_improvement_violation_flag,p.strategy_feasibility_improvement_violation_flag,p.comparable_payment_burden_improvement_violation_flag,p.comparable_servicing_burden_improvement_violation_flag,p.strategy_restriction_flag,p.absolute_workload_reduction_flag,p.stress_nonimprovement_pass_flag,p.primary_reason_code,p.reason_codes) IS DISTINCT FROM (e.expected_source_risk_improvement_violation_flag,e.expected_source_return_improvement_violation_flag,e.expected_strategy_access_improvement_violation_flag,e.expected_strategy_feasibility_improvement_violation_flag,e.expected_comparable_payment_burden_improvement_violation_flag,e.expected_comparable_servicing_burden_improvement_violation_flag,e.expected_strategy_restriction_flag,e.expected_absolute_workload_reduction_flag,e.expected_stress_nonimprovement_pass_flag,e.expected_primary_reason_code,e.expected_reason_codes)) z)=0)),'Stress flags and application reason evidence independently reconstruct for all 12,000 rows','Amendment A7-A16; B2-B5');

SELECT pg_temp.m2_11_add_positive(99,'M2_11_POS_099_APP_ADVERSITY','APPLICATION_VALIDATION','Application PORTFOLIO adversity order and tie-break independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN tmp_eval_application_adversity_expected e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.portfolio_adversity_order,p.portfolio_adverse_selected_flag) IS DISTINCT FROM (e.expected_portfolio_adversity_order,e.expected_portfolio_adverse_selected_flag)) z))::text,'0 adversity order/selection mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation p JOIN tmp_eval_application_adversity_expected e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.portfolio_adversity_order,p.portfolio_adverse_selected_flag) IS DISTINCT FROM (e.expected_portfolio_adversity_order,e.expected_portfolio_adverse_selected_flag)) z)=0)),'Application PORTFOLIO adversity order and tie-break independently reconstruct','Amendment A7-A12; B2-B5');

SELECT pg_temp.m2_11_add_positive(100,'M2_11_POS_100_APP_PORTFOLIO_COUNT','APPLICATION_VALIDATION','PORTFOLIO selects exactly one application row per application and strategy',((SELECT count(*) FROM msbf_m2.application_portfolio_strategy_simulation WHERE portfolio_adverse_selected_flag))::text,'6,000 selected rows; 750 per strategy',(((SELECT count(*) FROM msbf_m2.application_portfolio_strategy_simulation WHERE portfolio_adverse_selected_flag)=6000 AND NOT EXISTS(SELECT 1 FROM msbf_m2.application_portfolio_strategy_simulation WHERE portfolio_adverse_selected_flag GROUP BY module1_run_id,merchant_application_id,strategy_profile_code HAVING count(*)<>1))),'PORTFOLIO selects exactly one application row per application and strategy','Amendment A7-A12; B2-B5');

SELECT pg_temp.m2_11_add_positive(101,'M2_11_POS_101_ACCOUNT_TREATMENT','SCOPE_VALIDATION','Account servicing treatments and reason evidence independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation p JOIN tmp_eval_account_expected_base e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.servicing_treatment_code,p.treatment_applicable_flag,p.simulated_action_date,p.simulated_payment_factor,p.simulated_exposure_amount,p.incremental_servicing_burden_units,p.strategy_servicing_burden_units,p.source_replay_match_flag,p.strategy_evidence_status,p.primary_reason_code,p.reason_codes) IS DISTINCT FROM (e.expected_servicing_treatment_code,e.expected_treatment_applicable_flag,e.expected_simulated_action_date,e.expected_simulated_payment_factor,e.expected_simulated_exposure_amount,e.expected_incremental_servicing_burden_units,e.expected_strategy_servicing_burden_units,e.expected_source_replay_match_flag,e.expected_strategy_evidence_status,e.expected_primary_reason_code,e.expected_reason_codes)) z))::text,'all 472 treatment and reason fields exact',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation p JOIN tmp_eval_account_expected_base e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.servicing_treatment_code,p.treatment_applicable_flag,p.simulated_action_date,p.simulated_payment_factor,p.simulated_exposure_amount,p.incremental_servicing_burden_units,p.strategy_servicing_burden_units,p.source_replay_match_flag,p.strategy_evidence_status,p.primary_reason_code,p.reason_codes) IS DISTINCT FROM (e.expected_servicing_treatment_code,e.expected_treatment_applicable_flag,e.expected_simulated_action_date,e.expected_simulated_payment_factor,e.expected_simulated_exposure_amount,e.expected_incremental_servicing_burden_units,e.expected_strategy_servicing_burden_units,e.expected_source_replay_match_flag,e.expected_strategy_evidence_status,e.expected_primary_reason_code,e.expected_reason_codes)) z)=0)),'Account servicing treatments and reason evidence independently reconstruct','Amendment A2-A4/A11-A16/B4');

SELECT pg_temp.m2_11_add_positive(102,'M2_11_POS_102_ACCOUNT_NO_BENEFIT_CLAIMS','SCOPE_VALIDATION','No account treatment claims risk, return, contribution, or payment benefit',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation p WHERE p.risk_benefit_claimed_flag OR p.return_benefit_claimed_flag OR p.contribution_benefit_claimed_flag OR p.payment_performance_benefit_claimed_flag) z))::text,'0 claimed benefit flags',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation p WHERE p.risk_benefit_claimed_flag OR p.return_benefit_claimed_flag OR p.contribution_benefit_claimed_flag OR p.payment_performance_benefit_claimed_flag) z)=0)),'No account treatment claims risk, return, contribution, or payment benefit','Amendment A2-A4/A12/B4');

SELECT pg_temp.m2_11_add_positive(103,'M2_11_POS_103_ACCOUNT_ADVERSITY','SCOPE_VALIDATION','Account PORTFOLIO adversity order and tie-break independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation p JOIN tmp_eval_account_adversity_expected e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.portfolio_adversity_order,p.portfolio_adverse_selected_flag) IS DISTINCT FROM (e.expected_portfolio_adversity_order,e.expected_portfolio_adverse_selected_flag)) z))::text,'0 order/selection mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation p JOIN tmp_eval_account_adversity_expected e USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) WHERE (p.portfolio_adversity_order,p.portfolio_adverse_selected_flag) IS DISTINCT FROM (e.expected_portfolio_adversity_order,e.expected_portfolio_adverse_selected_flag)) z)=0)),'Account PORTFOLIO adversity order and tie-break independently reconstruct','Amendment A2-A4/A12/B4');

SELECT pg_temp.m2_11_add_positive(104,'M2_11_POS_104_ACCOUNT_PORTFOLIO_COUNT','SCOPE_VALIDATION','PORTFOLIO selects one accepted operational account row per application/strategy',((SELECT count(*) FROM msbf_m2.account_servicing_strategy_simulation WHERE portfolio_adverse_selected_flag))::text,'352 selected rows; 44 per strategy',(((SELECT count(*) FROM msbf_m2.account_servicing_strategy_simulation WHERE portfolio_adverse_selected_flag)=352 AND NOT EXISTS(SELECT 1 FROM msbf_m2.account_servicing_strategy_simulation WHERE portfolio_adverse_selected_flag GROUP BY module1_run_id,merchant_application_id,strategy_profile_code HAVING count(*)<>1))),'PORTFOLIO selects one accepted operational account row per application/strategy','Amendment A2-A4/A12/B4');

SELECT pg_temp.m2_11_add_positive(105,'M2_11_POS_105_SCOPE_APP_DENOMINATORS','SCOPE_VALIDATION','All three scope application denominators are exact',((SELECT count(*) FROM (SELECT 1 FROM tmp_scope_validation_summary_expected WHERE application_rows<>750) z))::text,'750 per strategy/scope',(((SELECT count(*) FROM (SELECT 1 FROM tmp_scope_validation_summary_expected WHERE application_rows<>750) z)=0)),'All three scope application denominators are exact','Amendment A2-A4/A12/B4');

SELECT pg_temp.m2_11_add_positive(106,'M2_11_POS_106_SCOPE_ACCOUNT_COUNTS','SCOPE_VALIDATION','Scope servicing account counts and coverage are exact',((SELECT count(*) FROM (SELECT 1 FROM tmp_scope_validation_summary_expected WHERE (reporting_scope_code='BASELINE' AND servicing_account_rows<>44) OR (reporting_scope_code='RECESSION_ENERGY' AND servicing_account_rows<>15) OR (reporting_scope_code='PORTFOLIO' AND servicing_account_rows<>44) OR servicing_burden_coverage_code<>'ACCEPTED_OPERATIONAL_ACCOUNTS_ONLY' OR new_access_servicing_burden_estimated_flag) z))::text,'44/15/44 by scope per strategy; accepted-only coverage',(((SELECT count(*) FROM (SELECT 1 FROM tmp_scope_validation_summary_expected WHERE (reporting_scope_code='BASELINE' AND servicing_account_rows<>44) OR (reporting_scope_code='RECESSION_ENERGY' AND servicing_account_rows<>15) OR (reporting_scope_code='PORTFOLIO' AND servicing_account_rows<>44) OR servicing_burden_coverage_code<>'ACCEPTED_OPERATIONAL_ACCOUNTS_ONLY' OR new_access_servicing_burden_estimated_flag) z)=0)),'Scope servicing account counts and coverage are exact','Amendment A2-A4/A12/B4');

SELECT pg_temp.m2_11_add_positive(107,'M2_11_POS_107_SCOPE_CATEGORY_IDENTITY','SCOPE_VALIDATION','Outcome category counts reconcile to every scope denominator',((SELECT count(*) FROM (SELECT 1 FROM tmp_scope_validation_summary_expected WHERE access_selected_rows+controlled_review_rows+strategy_restriction_rows+no_feasible_candidate_rows+insufficient_evidence_rows+policy_decline_rows+blocked_source_rows<>application_rows) z))::text,'sum categories equals application_rows',(((SELECT count(*) FROM (SELECT 1 FROM tmp_scope_validation_summary_expected WHERE access_selected_rows+controlled_review_rows+strategy_restriction_rows+no_feasible_candidate_rows+insufficient_evidence_rows+policy_decline_rows+blocked_source_rows<>application_rows) z)=0)),'Outcome category counts reconcile to every scope denominator','Amendment A2-A4/A12/B4');

SELECT pg_temp.m2_11_add_positive(108,'M2_11_POS_108_SCOPE_RAW_METRICS','SCOPE_VALIDATION','All 59 immutable strategy-summary fields independently reconstruct at exact target types',((SELECT count(*) FROM msbf_m2.portfolio_strategy_summary p FULL JOIN tmp_scope_validation_summary_exact_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE p.module1_run_id IS NULL OR e.module1_run_id IS NULL OR (to_jsonb(p)-'row_hash'-'created_at') IS DISTINCT FROM (to_jsonb(e)-'row_hash'-'created_at')))::text,'0 mismatches across 24 rows and 59 immutable fields',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_summary p FULL JOIN tmp_scope_validation_summary_exact_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE p.module1_run_id IS NULL OR e.module1_run_id IS NULL OR (to_jsonb(p)-'row_hash'-'created_at') IS DISTINCT FROM (to_jsonb(e)-'row_hash'-'created_at'))=0 AND (SELECT count(*) FROM tmp_scope_validation_summary_exact_expected)=24)),'All 59 immutable strategy-summary fields independently reconstruct at exact target types','Amendment A2-A4/A12-A15/B4');

SELECT pg_temp.m2_11_add_positive(109,'M2_11_POS_109_SCOPE_EVIDENCE_STRESS','SCOPE_VALIDATION','Scope evidence and stress counters independently aggregate',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_summary p JOIN tmp_scope_validation_summary_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE (p.hard_constraint_violation_count,p.complete_evidence_rows,p.partial_evidence_rows,p.blocked_evidence_rows,p.source_risk_improvement_violation_count,p.source_return_improvement_violation_count,p.strategy_access_improvement_violation_count,p.strategy_feasibility_improvement_violation_count,p.comparable_payment_burden_improvement_violation_count,p.comparable_servicing_burden_improvement_violation_count,p.stress_improvement_violation_count,p.stress_strategy_restriction_rows,p.absolute_workload_reduction_rows,p.strategy_evidence_status,p.stress_nonimprovement_pass_flag) IS DISTINCT FROM (e.hard_constraint_violation_count,e.complete_evidence_rows,e.partial_evidence_rows,e.blocked_evidence_rows,e.source_risk_improvement_violation_count,e.source_return_improvement_violation_count,e.strategy_access_improvement_violation_count,e.strategy_feasibility_improvement_violation_count,e.comparable_payment_burden_improvement_violation_count,e.comparable_servicing_burden_improvement_violation_count,e.stress_improvement_violation_count,e.stress_strategy_restriction_rows,e.absolute_workload_reduction_rows,e.strategy_evidence_status,e.stress_nonimprovement_pass_flag)) z))::text,'0 status/counter mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_summary p JOIN tmp_scope_validation_summary_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE (p.hard_constraint_violation_count,p.complete_evidence_rows,p.partial_evidence_rows,p.blocked_evidence_rows,p.source_risk_improvement_violation_count,p.source_return_improvement_violation_count,p.strategy_access_improvement_violation_count,p.strategy_feasibility_improvement_violation_count,p.comparable_payment_burden_improvement_violation_count,p.comparable_servicing_burden_improvement_violation_count,p.stress_improvement_violation_count,p.stress_strategy_restriction_rows,p.absolute_workload_reduction_rows,p.strategy_evidence_status,p.stress_nonimprovement_pass_flag) IS DISTINCT FROM (e.hard_constraint_violation_count,e.complete_evidence_rows,e.partial_evidence_rows,e.blocked_evidence_rows,e.source_risk_improvement_violation_count,e.source_return_improvement_violation_count,e.strategy_access_improvement_violation_count,e.strategy_feasibility_improvement_violation_count,e.comparable_payment_burden_improvement_violation_count,e.comparable_servicing_burden_improvement_violation_count,e.stress_improvement_violation_count,e.stress_strategy_restriction_rows,e.absolute_workload_reduction_rows,e.strategy_evidence_status,e.stress_nonimprovement_pass_flag)) z)=0)),'Scope evidence and stress counters independently aggregate','Amendment A2-A4/A12/B4');

SELECT pg_temp.m2_11_add_positive(110,'M2_11_POS_110_SCOPE_SCORE','SCOPE_VALIDATION','Scope normalization, weighted components, and strategy score independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_summary p JOIN tmp_scope_validation_summary_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE (p.access_rate_normalized_value,p.access_rate_weighted_contribution,p.selected_exposure_amount_normalized_value,p.selected_exposure_amount_weighted_contribution,p.finance_charge_amount_normalized_value,p.finance_charge_amount_weighted_contribution,p.expected_loss_density_normalized_value,p.expected_loss_density_weighted_contribution,p.risk_adjusted_contribution_normalized_value,p.risk_adjusted_contribution_weighted_contribution,p.annualized_risk_adjusted_return_normalized_value,p.annualized_risk_adjusted_return_weighted_contribution,p.servicing_burden_units_normalized_value,p.servicing_burden_units_weighted_contribution,p.payment_burden_rate_normalized_value,p.payment_burden_rate_weighted_contribution,p.scope_strategy_score) IS DISTINCT FROM (e.access_rate_normalized_value,e.access_rate_weighted_contribution,e.selected_exposure_amount_normalized_value,e.selected_exposure_amount_weighted_contribution,e.finance_charge_amount_normalized_value,e.finance_charge_amount_weighted_contribution,e.expected_loss_density_normalized_value,e.expected_loss_density_weighted_contribution,e.risk_adjusted_contribution_normalized_value,e.risk_adjusted_contribution_weighted_contribution,e.annualized_risk_adjusted_return_normalized_value,e.annualized_risk_adjusted_return_weighted_contribution,e.servicing_burden_units_normalized_value,e.servicing_burden_units_weighted_contribution,e.payment_burden_rate_normalized_value,e.payment_burden_rate_weighted_contribution,e.scope_strategy_score)) z))::text,'0 normalized/component/score mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_summary p JOIN tmp_scope_validation_summary_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE (p.access_rate_normalized_value,p.access_rate_weighted_contribution,p.selected_exposure_amount_normalized_value,p.selected_exposure_amount_weighted_contribution,p.finance_charge_amount_normalized_value,p.finance_charge_amount_weighted_contribution,p.expected_loss_density_normalized_value,p.expected_loss_density_weighted_contribution,p.risk_adjusted_contribution_normalized_value,p.risk_adjusted_contribution_weighted_contribution,p.annualized_risk_adjusted_return_normalized_value,p.annualized_risk_adjusted_return_weighted_contribution,p.servicing_burden_units_normalized_value,p.servicing_burden_units_weighted_contribution,p.payment_burden_rate_normalized_value,p.payment_burden_rate_weighted_contribution,p.scope_strategy_score) IS DISTINCT FROM (e.access_rate_normalized_value,e.access_rate_weighted_contribution,e.selected_exposure_amount_normalized_value,e.selected_exposure_amount_weighted_contribution,e.finance_charge_amount_normalized_value,e.finance_charge_amount_weighted_contribution,e.expected_loss_density_normalized_value,e.expected_loss_density_weighted_contribution,e.risk_adjusted_contribution_normalized_value,e.risk_adjusted_contribution_weighted_contribution,e.annualized_risk_adjusted_return_normalized_value,e.annualized_risk_adjusted_return_weighted_contribution,e.servicing_burden_units_normalized_value,e.servicing_burden_units_weighted_contribution,e.payment_burden_rate_normalized_value,e.payment_burden_rate_weighted_contribution,e.scope_strategy_score)) z)=0)),'Scope normalization, weighted components, and strategy score independently reconstruct','Amendment A2-A4/A12/B4');

SELECT pg_temp.m2_11_add_positive(111,'M2_11_POS_111_FRONTIER_ELIGIBILITY','FRONTIER','Frontier eligibility and ineligibility reasons independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_frontier p JOIN tmp_frontier_validation_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE (p.frontier_eligible_flag,p.frontier_ineligibility_code,p.evidence_rank) IS DISTINCT FROM (e.frontier_eligible_flag,e.frontier_ineligibility_code,e.evidence_rank)) z))::text,'0 eligibility mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_frontier p JOIN tmp_frontier_validation_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE (p.frontier_eligible_flag,p.frontier_ineligibility_code,p.evidence_rank) IS DISTINCT FROM (e.frontier_eligible_flag,e.frontier_ineligibility_code,e.evidence_rank)) z)=0)),'Frontier eligibility and ineligibility reasons independently reconstruct','Amendment A13-A17; B6; final canonical count');

SELECT pg_temp.m2_11_add_positive(112,'M2_11_POS_112_PARETO_EDGES','FRONTIER','Seven-objective dominance edges and dominated/dominates counts independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_frontier p JOIN tmp_frontier_validation_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE (p.dominated_by_count,p.dominates_count) IS DISTINCT FROM (e.dominated_by_count,e.dominates_count)) z))::text,'0 edge-count mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_frontier p JOIN tmp_frontier_validation_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE (p.dominated_by_count,p.dominates_count) IS DISTINCT FROM (e.dominated_by_count,e.dominates_count)) z)=0)),'Seven-objective dominance edges and dominated/dominates counts independently reconstruct','Amendment A13-A17; B6; final canonical count');

SELECT pg_temp.m2_11_add_positive(113,'M2_11_POS_113_FRONTIER_RANKS','FRONTIER','Iterative non-dominated frontier ranks independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_frontier p JOIN tmp_frontier_validation_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE (p.non_dominated_flag,p.frontier_rank) IS DISTINCT FROM (e.non_dominated_flag,e.frontier_rank)) z))::text,'0 rank/non-dominated mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_frontier p JOIN tmp_frontier_validation_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE (p.non_dominated_flag,p.frontier_rank) IS DISTINCT FROM (e.non_dominated_flag,e.frontier_rank)) z)=0)),'Iterative non-dominated frontier ranks independently reconstruct','Amendment A13-A17; B6; final canonical count');

SELECT pg_temp.m2_11_add_positive(114,'M2_11_POS_114_GOVERNANCE_SCORE','GOVERNANCE','Governance normalization and seven-objective balance score independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_frontier p JOIN tmp_frontier_validation_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE (p.governance_balance_score,p.governance_access_rate_normalized_value,p.governance_finance_charge_amount_normalized_value,p.governance_expected_loss_density_normalized_value,p.governance_risk_adjusted_contribution_normalized_value,p.governance_annualized_risk_adjusted_return_normalized_value,p.governance_servicing_burden_units_normalized_value,p.governance_payment_burden_rate_normalized_value) IS DISTINCT FROM (e.governance_balance_score,e.governance_access_rate_normalized_value,e.governance_finance_charge_amount_normalized_value,e.governance_expected_loss_density_normalized_value,e.governance_risk_adjusted_contribution_normalized_value,e.governance_annualized_risk_adjusted_return_normalized_value,e.governance_servicing_burden_units_normalized_value,e.governance_payment_burden_rate_normalized_value)) z))::text,'0 governance score/component mismatches',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_frontier p JOIN tmp_frontier_validation_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE (p.governance_balance_score,p.governance_access_rate_normalized_value,p.governance_finance_charge_amount_normalized_value,p.governance_expected_loss_density_normalized_value,p.governance_risk_adjusted_contribution_normalized_value,p.governance_annualized_risk_adjusted_return_normalized_value,p.governance_servicing_burden_units_normalized_value,p.governance_payment_burden_rate_normalized_value) IS DISTINCT FROM (e.governance_balance_score,e.governance_access_rate_normalized_value,e.governance_finance_charge_amount_normalized_value,e.governance_expected_loss_density_normalized_value,e.governance_risk_adjusted_contribution_normalized_value,e.governance_annualized_risk_adjusted_return_normalized_value,e.governance_servicing_burden_units_normalized_value,e.governance_payment_burden_rate_normalized_value)) z)=0)),'Governance normalization and seven-objective balance score independently reconstruct','Amendment A13-A17; B6; final canonical count');

SELECT pg_temp.m2_11_add_positive(115,'M2_11_POS_115_GOVERNANCE_PRIORITY','GOVERNANCE','All 24 immutable frontier fields, summary lineage, reason evidence, and governance priorities independently reconstruct',((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_frontier p FULL JOIN tmp_frontier_validation_exact_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE p.module1_run_id IS NULL OR e.module1_run_id IS NULL OR (to_jsonb(p)-'row_hash'-'created_at') IS DISTINCT FROM (to_jsonb(e)-'row_hash'-'created_at') UNION ALL SELECT 1 FROM msbf_m2.portfolio_strategy_frontier WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND primary_governance_review_flag GROUP BY module1_run_id,reporting_scope_code HAVING count(*)>1) z))::text,'0 field mismatches; at most one primary per scope',(((SELECT count(*) FROM (SELECT 1 FROM msbf_m2.portfolio_strategy_frontier p FULL JOIN tmp_frontier_validation_exact_expected e USING(module1_run_id,strategy_profile_code,reporting_scope_code) WHERE p.module1_run_id IS NULL OR e.module1_run_id IS NULL OR (to_jsonb(p)-'row_hash'-'created_at') IS DISTINCT FROM (to_jsonb(e)-'row_hash'-'created_at') UNION ALL SELECT 1 FROM msbf_m2.portfolio_strategy_frontier WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND primary_governance_review_flag GROUP BY module1_run_id,reporting_scope_code HAVING count(*)>1) z)=0 AND (SELECT count(*) FROM tmp_frontier_validation_exact_expected)=24)),'All 24 immutable frontier fields, summary lineage, reason evidence, and governance priorities independently reconstruct','Amendment A13-A17; B6; final canonical count');

SELECT pg_temp.m2_11_add_positive(116,'M2_11_POS_116_COMPARISON_DELTAS','COMPARISON','All 44 immutable fields for the 21 baseline/challenger comparisons independently reconstruct',((SELECT count(*) FROM msbf_m2.portfolio_strategy_comparison p FULL JOIN tmp_scope_validation_comparison_exact_expected e USING(module1_run_id,reporting_scope_code,challenger_strategy_profile_code) WHERE p.module1_run_id IS NULL OR e.module1_run_id IS NULL OR (to_jsonb(p)-'row_hash'-'created_at') IS DISTINCT FROM (to_jsonb(e)-'row_hash'-'created_at')))::text,'0 mismatches across 21 rows and 44 immutable fields',(((SELECT count(*) FROM msbf_m2.portfolio_strategy_comparison p FULL JOIN tmp_scope_validation_comparison_exact_expected e USING(module1_run_id,reporting_scope_code,challenger_strategy_profile_code) WHERE p.module1_run_id IS NULL OR e.module1_run_id IS NULL OR (to_jsonb(p)-'row_hash'-'created_at') IS DISTINCT FROM (to_jsonb(e)-'row_hash'-'created_at'))=0 AND (SELECT count(*) FROM tmp_scope_validation_comparison_exact_expected)=21)),'All 44 immutable fields for the 21 baseline/challenger comparisons independently reconstruct','Amendment A13-A17; B6; final canonical count');

SELECT pg_temp.m2_11_add_positive(117,'M2_11_POS_117_LATEST_REPRODUCTION','CONTRACT','All 24 latest contract rows reproduce all immutable fields, summary/frontier/comparison lineage, and accepted-source lineage',((SELECT latest_exact_mismatches FROM tmp_latest_validation_link_mismatch))::text,'0 mismatches across all 85 immutable latest fields',(((SELECT latest_exact_mismatches FROM tmp_latest_validation_link_mismatch)=0 AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_latest)=24 AND (SELECT count(*) FROM tmp_latest_validation_expected)=24)),'All 24 latest contract rows reproduce all immutable fields, summary/frontier/comparison lineage, and accepted-source lineage','Amendment A13-A17; B6; final canonical count');

SELECT pg_temp.m2_11_add_positive(118,'M2_11_POS_118_ARCHIVE_REPRODUCTION','ARCHIVE','All 24 archive rows exactly reproduce latest and archive immutability is installed',((SELECT archive_payload_mismatches::text||'|'||immutable_trigger_rows::text FROM tmp_latest_validation_link_mismatch))::text,'0 payload/hash mismatches; immutable trigger present',(((SELECT archive_payload_mismatches FROM tmp_latest_validation_link_mismatch)=0 AND (SELECT immutable_trigger_rows FROM tmp_latest_validation_link_mismatch)=1 AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_archive)=24)),'All 24 archive rows exactly reproduce latest and archive immutability is installed','Amendment A13-A17; B6; final canonical count');

SELECT pg_temp.m2_11_add_positive(119,'M2_11_POS_119_PHYSICAL_HASHES','HASH','All target-typed physical row hashes and all nineteen explicitly ordered set hashes reconstruct',((SELECT physical_row_hash_mismatches::text||'|'||registry_set_hash_mismatches::text||'|'||reconstructed_set_hash_rows::text FROM tmp_registry_validation_hash_summary))::text,'0 row-hash mismatches; 19/19 set hashes; contract and combined exact',(((SELECT physical_row_hash_mismatches FROM tmp_registry_validation_hash_summary)=0 AND (SELECT registry_set_hash_mismatches FROM tmp_registry_validation_hash_summary)=0 AND (SELECT reconstructed_set_hash_rows FROM tmp_registry_validation_hash_summary)=19 AND (SELECT reconstructed_contract_set_hash FROM tmp_registry_validation_hash_summary)=(SELECT contract_set_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry) AND (SELECT reconstructed_combined_set_hash FROM tmp_registry_validation_hash_summary)=(SELECT combined_set_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry))),'All target-typed physical row hashes and all nineteen explicitly ordered set hashes reconstruct','Amendment A13-A17; B6; final canonical count');

SELECT pg_temp.m2_11_add_positive(120,'M2_11_POS_120_CANONICAL_BOUNDARY','BOUNDARY','Current-run canonical count, generation evidence, and non-production/stage boundaries reconcile',((SELECT (SELECT count(*) FROM msbf_m2.v_m2_11_canonical_entity_hash_source v WHERE v.business_key=(SELECT run_id::text FROM tmp_eval_m2_11_validation_context) OR v.business_key LIKE (SELECT run_id::text||'|%' FROM tmp_eval_m2_11_validation_context))::text||'|'||(SELECT count(DISTINCT object_code) FROM msbf_m2.v_m2_11_canonical_entity_hash_source v WHERE v.business_key=(SELECT run_id::text FROM tmp_eval_m2_11_validation_context) OR v.business_key LIKE (SELECT run_id::text||'|%' FROM tmp_eval_m2_11_validation_context))::text||'|'||(SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND evidence_code LIKE 'M2_11_GENERATION_%')::text))::text,'19,298 current-run canonical; 19 families; 24 generation; 0 prohibited/acceptance artifacts',(((SELECT count(*) FROM msbf_m2.v_m2_11_canonical_entity_hash_source v WHERE v.business_key=(SELECT run_id::text FROM tmp_eval_m2_11_validation_context) OR v.business_key LIKE (SELECT run_id::text||'|%' FROM tmp_eval_m2_11_validation_context))=19298 AND (SELECT count(DISTINCT object_code) FROM msbf_m2.v_m2_11_canonical_entity_hash_source v WHERE v.business_key=(SELECT run_id::text FROM tmp_eval_m2_11_validation_context) OR v.business_key LIKE (SELECT run_id::text||'|%' FROM tmp_eval_m2_11_validation_context))=19 AND (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND evidence_code LIKE 'M2_11_GENERATION_%')=24 AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (real_funds_movement_flag OR external_notice_generation_authorized_flag OR external_notice_transmitted_flag OR production_adverse_action_notice_flag)) AND NOT EXISTS(SELECT 1 FROM msbf_m2.portfolio_strategy_reason_definition WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND (production_action_flag OR external_system_update_flag OR merchant_contact_flag OR production_adverse_action_flag)) AND NOT EXISTS(SELECT 1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'))),'Current-run canonical count, generation evidence, and non-production/stage boundaries reconcile','Amendment A13-A17; B6; final canonical count');

/* ============================================================================
Section 10 — Reconcile all controls, persist validation evidence, and advance
only the mutable validation lifecycle checkpoint
============================================================================ */
DO $m211_positive_finalize$
DECLARE
    v_total bigint;
    v_pass bigint;
    v_fail bigint;
    v_failed_detail text;
    v_rows bigint;
BEGIN
 SELECT count(*),count(*) FILTER(WHERE status='PASS'),count(*) FILTER(WHERE status='FAIL'),
        string_agg(evidence_code||'[observed='||coalesce(observed_value,'<NULL>')||
          '; threshold='||coalesce(threshold_value,'<NULL>')||']','; ' ORDER BY control_sequence)
          FILTER(WHERE status='FAIL')
 INTO v_total,v_pass,v_fail,v_failed_detail
 FROM tmp_eval_m2_11_positive_control;

 IF v_total<>120 OR (SELECT count(DISTINCT evidence_code) FROM tmp_eval_m2_11_positive_control)<>120
    OR (SELECT min(control_sequence) FROM tmp_eval_m2_11_positive_control)<>1
    OR (SELECT max(control_sequence) FROM tmp_eval_m2_11_positive_control)<>120 THEN
   RAISE EXCEPTION 'Program 215 positive-control inventory mismatch: total %, unique %, range %..%',
    v_total,(SELECT count(DISTINCT evidence_code) FROM tmp_eval_m2_11_positive_control),
    (SELECT min(control_sequence) FROM tmp_eval_m2_11_positive_control),
    (SELECT max(control_sequence) FROM tmp_eval_m2_11_positive_control);
 END IF;

 IF v_pass<>120 OR v_fail<>0 THEN
   RAISE EXCEPTION 'Program 215 positive validation failed: pass %, fail %. Failed controls: %',
     v_pass,v_fail,coalesce(v_failed_detail,'<NONE>');
 END IF;

 /* Evidence is written only after the complete 120-control set passes. */
 INSERT INTO msbf_ctl.run_evidence
 (
  run_id,evidence_code,segment_key,metric_name,
  metric_value_numeric,metric_value_text,unit_code,status,interpretation
 )
 SELECT
  (SELECT run_id FROM tmp_eval_m2_11_validation_context),evidence_code,'PORTFOLIO',metric_name,
  NULL::numeric(28,10),coalesce(observed_value,'<NULL>'),'POSITIVE_CONTROL',status,
  interpretation||' Threshold: '||coalesce(threshold_value,'<NULL>')||
  '. Freeze trace: '||freeze_trace
 FROM tmp_eval_m2_11_positive_control
 ORDER BY control_sequence;
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>120 THEN RAISE EXCEPTION 'Program 215 evidence insert expected 120; inserted %',v_rows; END IF;

 UPDATE msbf_ctl.m2_11_portfolio_strategy_contract_registry
 SET contract_status='VALIDATED',validated_at=clock_timestamp()
 WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
   AND contract_version=1 AND contract_status='GENERATED';
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>1 THEN RAISE EXCEPTION 'Program 215 registry lifecycle update expected 1 row; updated %',v_rows; END IF;

 UPDATE msbf_ctl.run_registry
 SET run_status='M2_11_VALIDATED'
 WHERE run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context)
   AND run_status='M2_11_GENERATED';
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>1 THEN RAISE EXCEPTION 'Program 215 run lifecycle update expected 1 row; updated %',v_rows; END IF;

 IF (SELECT row_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM tmp_eval_m2_11_validation_context) AND contract_version=1)
    IS DISTINCT FROM (SELECT registry_row_hash FROM tmp_eval_m2_11_validation_context) THEN
   RAISE EXCEPTION 'Program 215 mutable lifecycle update unexpectedly changed immutable registry row hash';
 END IF;
END;
$m211_positive_finalize$;

COMMIT;

SELECT control_sequence,evidence_code,control_family,metric_name,
       observed_value,threshold_value,status,interpretation,freeze_trace
FROM tmp_eval_m2_11_positive_control
ORDER BY control_sequence;
