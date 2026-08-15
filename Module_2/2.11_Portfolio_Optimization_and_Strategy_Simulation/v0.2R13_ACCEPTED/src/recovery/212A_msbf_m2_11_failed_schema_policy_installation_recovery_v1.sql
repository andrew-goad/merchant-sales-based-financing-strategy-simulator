/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.11 — Portfolio Optimization & Strategy Simulation

Program     : 212A_msbf_m2_11_failed_schema_policy_installation_recovery_v1.sql
Revision    : WP2_IMPLEMENTATION_CORRECTION_R2
Methodology : M2_11_METHOD_V1
Contract    : M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION v1
Schema      : M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1

Purpose
-------
Remove only a diagnosed incomplete Program 212 installation when no M2.11 generated business state exists, returning the database to the pristine M2_10_ACCEPTED boundary for a clean Program 212 rerun.

Stage boundary
--------------
RECOVERY ONLY. This program never appears in the normal chain. It does not alter accepted M2.10 or any predecessor object. It fails closed if any M2.11 generated business, latest, archive, registry, evidence, or acceptance state exists.

Required result
---------------
All M2.11 Program 212 structures/definitions removed; run remains M2_10_ACCEPTED; no accepted source mutation.

Execution control
-----------------
Execute as one PostgreSQL script. Stop at the first error. Do not execute any
recovery program unless the failed state has first been diagnosed. This source
is READY FOR LIVE EXECUTION, NOT EXECUTED, and NOT ACCEPTED.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='15min';

DO $m211$
DECLARE
    v_run_id bigint;
    v_status text;
    v_n bigint:=0;
    v_sql text;
    v_obj text;
BEGIN
  SELECT run_id,run_status INTO STRICT v_run_id,v_status
  FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
  FOR UPDATE;
  IF v_status<>'M2_10_ACCEPTED' THEN
    RAISE EXCEPTION '212A requires M2_10_ACCEPTED; found %',v_status;
  END IF;

  FOREACH v_obj IN ARRAY ARRAY[
    'msbf_m2.portfolio_strategy_application_source_snapshot',
    'msbf_m2.portfolio_strategy_candidate_source_snapshot',
    'msbf_m2.portfolio_strategy_account_source_snapshot',
    'msbf_m2.portfolio_strategy_kpi_source_snapshot',
    'msbf_m2.portfolio_strategy_queue_source_snapshot',
    'msbf_m2.application_strategy_candidate_evaluation',
    'msbf_m2.application_portfolio_strategy_simulation',
    'msbf_m2.account_servicing_strategy_simulation',
    'msbf_m2.portfolio_strategy_summary',
    'msbf_m2.portfolio_strategy_frontier',
    'msbf_m2.portfolio_strategy_comparison',
    'msbf_m2.portfolio_strategy_simulation_latest',
    'msbf_m2.portfolio_strategy_simulation_archive',
    'msbf_ctl.m2_11_portfolio_strategy_contract_registry'
  ] LOOP
    IF to_regclass(v_obj) IS NOT NULL THEN
      v_sql:=format('SELECT count(*) FROM %s',v_obj);
      EXECUTE v_sql INTO v_n;
      IF v_n<>0 THEN RAISE EXCEPTION '212A refuses recovery: generated object % contains % rows',v_obj,v_n; END IF;
    END IF;
  END LOOP;

  SELECT count(*) INTO v_n FROM msbf_ctl.run_evidence
  WHERE run_id=v_run_id AND evidence_code LIKE 'M2_11_%';
  IF v_n<>0 THEN RAISE EXCEPTION '212A refuses recovery: % M2.11 evidence rows exist',v_n; END IF;
  SELECT count(*) INTO v_n FROM msbf_ctl.acceptance_gate_result
  WHERE run_id=v_run_id AND gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION';
  IF v_n<>0 THEN RAISE EXCEPTION '212A refuses recovery: M2.11 gate evidence exists'; END IF;
END;
$m211$;

DROP VIEW IF EXISTS msbf_m2.v_m2_11_matched_application_stress_comparison;
DROP VIEW IF EXISTS msbf_ctl.v_m2_11_portfolio_strategy_lineage;
DROP VIEW IF EXISTS msbf_m2.v_m2_11_portfolio_strategy_simulation_latest;
DROP VIEW IF EXISTS msbf_m2.v_m2_11_canonical_entity_hash_source;

DROP TABLE IF EXISTS msbf_ctl.m2_11_portfolio_strategy_contract_registry;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_simulation_archive;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_simulation_latest;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_comparison;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_frontier;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_summary;
DROP TABLE IF EXISTS msbf_m2.account_servicing_strategy_simulation;
DROP TABLE IF EXISTS msbf_m2.application_portfolio_strategy_simulation;
DROP TABLE IF EXISTS msbf_m2.application_strategy_candidate_evaluation;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_queue_source_snapshot;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_kpi_source_snapshot;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_account_source_snapshot;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_candidate_source_snapshot;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_application_source_snapshot;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_reason_definition;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_constraint_definition;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_objective_definition;
DROP TABLE IF EXISTS msbf_m2.portfolio_strategy_profile;
DROP TABLE IF EXISTS msbf_ctl.m2_11_policy_profile;

DROP FUNCTION IF EXISTS msbf_ctl.m2_11_block_archive_mutation();
DROP FUNCTION IF EXISTS msbf_ctl.m2_11_registry_row_hash(jsonb);
DROP FUNCTION IF EXISTS msbf_ctl.m2_11_hash_jsonb(jsonb);

DELETE FROM msbf_ref.acceptance_gate_catalog g
WHERE g.gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
  AND NOT EXISTS(SELECT 1 FROM msbf_ctl.acceptance_gate_result a WHERE a.gate_id=g.gate_id);

COMMIT;
SELECT 'M2_11_212A_RECOVERY_COMPLETE'::text AS recovery_status,
       'RERUN_PROGRAM_212_ONLY_AFTER_ROOT_CAUSE_CORRECTION'::text AS next_action;
