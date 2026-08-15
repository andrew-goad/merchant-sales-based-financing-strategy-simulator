/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.11 — Portfolio Optimization & Strategy Simulation

Program     : 218_msbf_m2_11_master_report_v1.sql
Version     : v1
Work package: M2.11 Work Package 4

Purpose
-------
Produce one concise governed master-report row from the accepted M2.11
database state. The report explicitly separates generated strategy evidence,
Pareto/frontier status, governance-review priority, formal M2.11 acceptance,
and deployment authorization.

Writes
------
No persistent writes. Temporary report intermediates only.

Required starting state
-----------------------
run_status       = M2_11_ACCEPTED
contract_status  = ACCEPTED
M2.11 gate       = PASS

Interpretation boundary
-----------------------
A non-dominated frontier position or PRIMARY_GOVERNANCE_REVIEW status is
analytical governance evidence only. It is not a production-optimal strategy,
deployment authority, Module 2 closure, or Module 3 authorization.

Execution
---------
Execute after Program 217. This source is statically built and has not been
parsed or executed by PostgreSQL in the build environment.
============================================================================ */

BEGIN;
-- PostgreSQL prohibits temporary-object DDL and ANALYZE in a READ ONLY
-- transaction. This report is therefore persistently read-only: it writes
-- only transaction-local temporary reporting objects and performs no
-- INSERT, UPDATE, DELETE, MERGE, TRUNCATE, or DDL against persistent objects.
SET LOCAL work_mem='128MB';
SET LOCAL statement_timeout='45min';
SET LOCAL lock_timeout='15s';
SET LOCAL jit=off;

/* ============================================================================
Section 1 — Materialize accepted context and reusable report intermediates
============================================================================ */
CREATE TEMP TABLE tmp_report_m2_11_master_context ON COMMIT DROP AS
SELECT
    r.run_id,r.run_code,r.run_version,r.run_status,r.as_of_date,
    p.policy_code,p.policy_version,p.policy_status,
    p.synthetic_data_only_flag,p.non_production_boundary_flag,
    p.servicing_burden_coverage_code,
    p.new_access_servicing_burden_estimated_flag,
    c.contract_code,c.contract_version,c.schema_version,c.methodology_version,
    c.acceptance_gate_id,c.contract_status,c.generated_at,c.validated_at,
    c.accepted_at,c.source_m1_17_combined_hash,c.source_m2_2_combined_hash,
    c.source_m2_4_combined_hash,c.source_m2_7_combined_hash,
    c.source_m2_10_combined_hash,c.canonical_entities,c.contract_set_hash,
    c.combined_set_hash,c.row_hash AS registry_row_hash,
    g.result_status AS gate_status,g.reviewed_at AS gate_reviewed_at,
    g.residual_limitation AS gate_residual_limitation
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m2_11_policy_profile p ON p.module1_run_id=r.run_id
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry c
  ON c.module1_run_id=r.run_id AND c.contract_version=1
JOIN msbf_ctl.acceptance_gate_result g
  ON g.run_id=r.run_id
 AND g.gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
 AND g.review_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

DO $m211_master_context$
DECLARE
    v_rows bigint;
    v_run_status text;
    v_contract_status text;
    v_gate_status text;
BEGIN
    SELECT count(*),max(run_status),max(contract_status),max(gate_status)
    INTO v_rows,v_run_status,v_contract_status,v_gate_status
    FROM tmp_report_m2_11_master_context;
    IF v_rows<>1 OR v_run_status<>'M2_11_ACCEPTED'
       OR v_contract_status<>'ACCEPTED' OR v_gate_status<>'PASS' THEN
      RAISE EXCEPTION
        'Program 218 requires one accepted M2.11 context; rows %, run %, contract %, gate %',
        v_rows,v_run_status,v_contract_status,v_gate_status;
    END IF;
END;
$m211_master_context$;

CREATE TEMP TABLE tmp_report_m2_11_master_evidence ON COMMIT DROP AS
SELECT
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_GENERATION_%')::bigint AS generation_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_GENERATION_%' AND status='PASS')::bigint AS generation_pass_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_POS_%')::bigint AS positive_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_POS_%' AND status='PASS')::bigint AS positive_pass_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_NEG_%')::bigint AS negative_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_NEG_%' AND status='PASS')::bigint AS negative_pass_rows,
    count(*) FILTER(WHERE evidence_code='M2_11_ACCEPTANCE_SUMMARY' AND status='PASS')::bigint AS acceptance_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_%' AND status<>'PASS')::bigint AS failed_rows
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM tmp_report_m2_11_master_context);

CREATE TEMP TABLE tmp_report_m2_11_master_scope ON COMMIT DROP AS
SELECT
    s.module1_run_id,s.strategy_profile_code,s.reporting_scope_code,
    s.application_rows,s.access_selected_rows,s.access_rate,
    s.selected_exposure_amount,s.finance_charge_amount,s.expected_loss_amount,
    s.expected_loss_density,s.risk_adjusted_contribution,
    s.annualized_risk_adjusted_return,s.payment_burden_rate,
    s.servicing_account_rows,s.servicing_distinct_application_rows,
    s.servicing_burden_units,s.strategy_evidence_status,
    s.stress_improvement_violation_count,s.stress_nonimprovement_pass_flag,
    f.frontier_eligible_flag,f.non_dominated_flag,f.frontier_rank,
    f.governance_balance_score,f.governance_review_priority_code,
    f.primary_governance_review_flag
FROM msbf_m2.portfolio_strategy_summary s
JOIN msbf_m2.portfolio_strategy_frontier f
  USING(module1_run_id,strategy_profile_code,reporting_scope_code)
WHERE s.module1_run_id=(SELECT run_id FROM tmp_report_m2_11_master_context);

CREATE UNIQUE INDEX tmp_report_m2_11_master_scope_u1
ON tmp_report_m2_11_master_scope(strategy_profile_code,reporting_scope_code);
CREATE INDEX tmp_report_m2_11_master_scope_i1
ON tmp_report_m2_11_master_scope(reporting_scope_code,frontier_rank,strategy_profile_code);
ANALYZE tmp_report_m2_11_master_scope;

CREATE TEMP TABLE tmp_report_m2_11_master_canonical ON COMMIT DROP AS
SELECT
    count(DISTINCT object_code)::bigint AS canonical_families,
    count(*)::bigint AS canonical_entities
FROM msbf_m2.v_m2_11_canonical_entity_hash_source
WHERE business_key=(SELECT run_id::text FROM tmp_report_m2_11_master_context)
   OR business_key LIKE (SELECT run_id::text||'|%' FROM tmp_report_m2_11_master_context);

CREATE TEMP TABLE tmp_report_m2_11_master_archive ON COMMIT DROP AS
SELECT count(*)::bigint AS latest_archive_mismatches
FROM msbf_m2.portfolio_strategy_simulation_latest l
FULL JOIN msbf_m2.portfolio_strategy_simulation_archive a
  ON a.module1_run_id=l.module1_run_id
 AND a.contract_version=l.contract_version
 AND a.strategy_profile_code=l.strategy_profile_code
 AND a.reporting_scope_code=l.reporting_scope_code
WHERE coalesce(l.module1_run_id,a.module1_run_id)
      =(SELECT run_id FROM tmp_report_m2_11_master_context)
  AND
  (
    l.module1_run_id IS NULL OR a.module1_run_id IS NULL
    OR l.contract_row_hash IS DISTINCT FROM a.contract_row_hash
    OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')
  );

CREATE TEMP TABLE tmp_report_m2_11_master_priority ON COMMIT DROP AS
SELECT
    reporting_scope_code,strategy_profile_code,frontier_rank,
    governance_balance_score,governance_review_priority_code
FROM tmp_report_m2_11_master_scope
WHERE primary_governance_review_flag
ORDER BY
  CASE reporting_scope_code
    WHEN 'BASELINE' THEN 1 WHEN 'RECESSION_ENERGY' THEN 2 WHEN 'PORTFOLIO' THEN 3
    ELSE 99 END,
  strategy_profile_code;

ANALYZE tmp_report_m2_11_master_priority;

/* ============================================================================
Section 2 — One governed executive checkpoint
============================================================================ */
SELECT
    'M2_11_MASTER_REPORT'::text AS result_set_code,
    c.run_code,c.run_version,c.run_status,c.as_of_date,
    c.policy_code,c.policy_version,c.policy_status,
    c.contract_code,c.contract_version,c.schema_version,c.methodology_version,
    c.contract_status,c.acceptance_gate_id,c.gate_status,c.gate_reviewed_at,
    c.generated_at,c.validated_at,c.accepted_at,
    c.source_m1_17_combined_hash,c.source_m2_2_combined_hash,
    c.source_m2_4_combined_hash,c.source_m2_7_combined_hash,
    c.source_m2_10_combined_hash,
    e.generation_pass_rows,e.generation_rows,
    e.positive_pass_rows,e.positive_rows,
    e.negative_pass_rows,e.negative_rows,
    e.acceptance_rows,e.failed_rows,
    x.canonical_families,x.canonical_entities,
    c.contract_set_hash,c.combined_set_hash,c.registry_row_hash,
    (SELECT count(*) FROM tmp_report_m2_11_master_scope) AS strategy_scope_rows,
    (SELECT count(*) FROM tmp_report_m2_11_master_scope
      WHERE frontier_eligible_flag) AS frontier_eligible_rows,
    (SELECT count(*) FROM tmp_report_m2_11_master_scope
      WHERE non_dominated_flag) AS non_dominated_rows,
    (SELECT count(*) FROM tmp_report_m2_11_master_scope
      WHERE frontier_rank=1) AS frontier_rank_1_rows,
    (SELECT count(*) FROM tmp_report_m2_11_master_priority) AS primary_governance_review_assignments,
    (SELECT jsonb_agg(
       jsonb_build_object(
         'reporting_scope_code',reporting_scope_code,
         'strategy_profile_code',strategy_profile_code,
         'frontier_rank',frontier_rank,
         'governance_balance_score',governance_balance_score,
         'priority_code',governance_review_priority_code
       )
       ORDER BY
         CASE reporting_scope_code
           WHEN 'BASELINE' THEN 1 WHEN 'RECESSION_ENERGY' THEN 2
           WHEN 'PORTFOLIO' THEN 3 ELSE 99 END,
         strategy_profile_code
     ) FROM tmp_report_m2_11_master_priority) AS governance_review_assignments,
    (SELECT coalesce(sum(stress_improvement_violation_count),0)
     FROM tmp_report_m2_11_master_scope) AS stress_improvement_violations,
    a.latest_archive_mismatches,
    c.synthetic_data_only_flag,c.non_production_boundary_flag,
    c.servicing_burden_coverage_code,
    c.new_access_servicing_burden_estimated_flag,
    'GENERATED_STRATEGY_EVIDENCE_ACCEPTED'::text AS generated_strategy_evidence_status,
    'PARETO_FRONTIER_IS_COMPARATIVE_ANALYTICAL_EVIDENCE'::text AS frontier_status_interpretation,
    'GOVERNANCE_REVIEW_PRIORITY_IS_NOT_A_CHAMPION_OR_DEPLOYMENT_DECISION'::text
      AS governance_priority_interpretation,
    'FORMALLY_ACCEPTED_FOR_SYNTHETIC_GOVERNANCE_CONSUMPTION'::text
      AS formal_acceptance_status,
    'NOT_AUTHORIZED'::text AS deployment_authorization_status,
    '59 accepted scenario-account rows: 44 BASELINE and 15 RECESSION_ENERGY. This synthetic population supports deterministic comparative evidence only; it does not support empirical optimization, causal uplift, calibrated treatment effectiveness, or statistical generalization.'::text
      AS data_sufficiency_limitation,
    'M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_REQUIRED'::text AS module2_closure_status,
    'NOT_AUTHORIZED'::text AS module3_authorization_status,
    c.gate_residual_limitation,
    CASE
      WHEN c.run_status='M2_11_ACCEPTED'
       AND c.contract_status='ACCEPTED'
       AND c.gate_status='PASS'
       AND e.generation_rows=24 AND e.generation_pass_rows=24
       AND e.positive_rows=120 AND e.positive_pass_rows=120
       AND e.negative_rows=20 AND e.negative_pass_rows=20
       AND e.acceptance_rows=1 AND e.failed_rows=0
       AND x.canonical_families=19 AND x.canonical_entities=19298
       AND (SELECT count(*) FROM tmp_report_m2_11_master_scope)=24
       AND (SELECT coalesce(sum(stress_improvement_violation_count),0)
            FROM tmp_report_m2_11_master_scope)=0
       AND a.latest_archive_mismatches=0
       AND c.synthetic_data_only_flag
       AND c.non_production_boundary_flag
       AND c.servicing_burden_coverage_code='ACCEPTED_OPERATIONAL_ACCOUNTS_ONLY'
       AND NOT c.new_access_servicing_burden_estimated_flag
      THEN 'PASS' ELSE 'FAIL'
    END AS overall_m2_11_status
FROM tmp_report_m2_11_master_context c
CROSS JOIN tmp_report_m2_11_master_evidence e
CROSS JOIN tmp_report_m2_11_master_canonical x
CROSS JOIN tmp_report_m2_11_master_archive a;

COMMIT;
