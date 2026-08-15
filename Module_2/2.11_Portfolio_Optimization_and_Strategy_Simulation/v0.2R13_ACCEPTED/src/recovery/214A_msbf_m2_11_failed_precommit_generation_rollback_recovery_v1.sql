/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.11 — Portfolio Optimization & Strategy Simulation

Program     : 214A_msbf_m2_11_failed_precommit_generation_rollback_recovery_v1.sql
Revision    : WP2_IMPLEMENTATION_CORRECTION_R2
Methodology : M2_11_METHOD_V1
Contract    : M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION v1
Schema      : M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1

Purpose
-------
Confirm that a failed pre-commit Program 214 transaction rolled back atomically and remove only stale M2.11 generation evidence that is proven to exist outside canonical generated state.

Stage boundary
--------------
RECOVERY ONLY. No business row is regenerated or deleted. The program requires the 61 approved definitions, zero generated canonical rows, no M2.11 registry/latest/archive state, and M2_10_ACCEPTED lifecycle.

Required result
---------------
Pristine Program 214 targets and zero M2.11 generation evidence, suitable for a diagnosed Program 214 rerun.

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
    v_n bigint;
BEGIN
  SELECT run_id,run_status INTO STRICT v_run_id,v_status
  FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
  FOR UPDATE;
  IF v_status<>'M2_10_ACCEPTED' THEN
    RAISE EXCEPTION '214A requires M2_10_ACCEPTED; found %. Do not infer a rollback state.',v_status;
  END IF;

  SELECT count(*) INTO v_n FROM
  (
    SELECT count(*) n,1 e FROM msbf_ctl.m2_11_policy_profile WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),8 FROM msbf_m2.portfolio_strategy_profile WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),8 FROM msbf_m2.portfolio_strategy_objective_definition WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),12 FROM msbf_m2.portfolio_strategy_constraint_definition WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),32 FROM msbf_m2.portfolio_strategy_reason_definition WHERE module1_run_id=v_run_id
  ) d WHERE n<>e;
  IF v_n<>0 THEN RAISE EXCEPTION '214A definition prerequisite mismatch'; END IF;

  SELECT count(*) INTO v_n FROM
  (
    SELECT module1_run_id FROM msbf_m2.portfolio_strategy_application_source_snapshot
    UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_candidate_source_snapshot
    UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_account_source_snapshot
    UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_kpi_source_snapshot
    UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_queue_source_snapshot
    UNION ALL SELECT module1_run_id FROM msbf_m2.application_strategy_candidate_evaluation
    UNION ALL SELECT module1_run_id FROM msbf_m2.application_portfolio_strategy_simulation
    UNION ALL SELECT module1_run_id FROM msbf_m2.account_servicing_strategy_simulation
    UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_summary
    UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_frontier
    UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_comparison
    UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_simulation_latest
    UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_simulation_archive
    UNION ALL SELECT module1_run_id FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
  ) x;
  IF v_n<>0 THEN RAISE EXCEPTION '214A refuses recovery: % committed generated rows exist',v_n; END IF;
END;
$m211$;

DELETE FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code LIKE 'M2_11_GENERATION_%';

DO $m211$
BEGIN
  IF EXISTS
  (
    SELECT 1 FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
      AND evidence_code LIKE 'M2_11_GENERATION_%'
  ) THEN RAISE EXCEPTION '214A stale evidence cleanup did not reconcile'; END IF;
END;
$m211$;

COMMIT;
SELECT 'M2_11_214A_ATOMIC_ROLLBACK_CONFIRMED'::text AS recovery_status,
       'RERUN_PROGRAM_214_ONLY_AFTER_ROOT_CAUSE_CORRECTION'::text AS next_action;
