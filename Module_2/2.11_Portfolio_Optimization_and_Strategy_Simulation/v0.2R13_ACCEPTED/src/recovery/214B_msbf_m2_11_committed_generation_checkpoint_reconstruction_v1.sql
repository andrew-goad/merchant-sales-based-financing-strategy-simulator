/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.11 — Portfolio Optimization & Strategy Simulation

Program     : 214B_msbf_m2_11_committed_generation_checkpoint_reconstruction_v1.sql
Revision    : WP2_IMPLEMENTATION_CORRECTION_R2
Methodology : M2_11_METHOD_V1
Contract    : M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION v1
Schema      : M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1

Purpose
-------
Reconstruct only the missing or incomplete GENERATED checkpoint—contract registry, 24 generation-evidence rows, and lifecycle metadata—from an already committed, exact M2.11 business state.

Stage boundary
--------------
RECOVERY ONLY. This program does not insert, update, or delete source snapshots, candidate evaluations, application simulations, account simulations, summaries, frontier rows, comparisons, latest rows, or archive rows. It fails closed on any count, row-hash, latest/archive, lineage, or canonical inconsistency.

Required result
---------------
Exact 19,298-row canonical checkpoint; registry GENERATED; 24 generation evidence rows; run M2_11_GENERATED; all committed business rows unchanged.

Execution control
-----------------
Execute as one PostgreSQL script. Stop at the first error. Do not execute any
recovery program unless the failed state has first been diagnosed. This source
is READY FOR LIVE EXECUTION, NOT EXECUTED, and NOT ACCEPTED.
============================================================================ */


BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='30min';
SET LOCAL jit=off;

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
  IF v_status NOT IN ('M2_10_ACCEPTED','M2_11_GENERATED') THEN
    RAISE EXCEPTION '214B requires M2_10_ACCEPTED or M2_11_GENERATED checkpoint state; found %',v_status;
  END IF;

  SELECT count(*) INTO v_n FROM
  (
    SELECT count(*) n,1 e FROM msbf_ctl.m2_11_policy_profile WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),8 FROM msbf_m2.portfolio_strategy_profile WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),8 FROM msbf_m2.portfolio_strategy_objective_definition WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),12 FROM msbf_m2.portfolio_strategy_constraint_definition WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),32 FROM msbf_m2.portfolio_strategy_reason_definition WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),1500 FROM msbf_m2.portfolio_strategy_application_source_snapshot WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),557 FROM msbf_m2.portfolio_strategy_candidate_source_snapshot WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),59 FROM msbf_m2.portfolio_strategy_account_source_snapshot WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),72 FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),3 FROM msbf_m2.portfolio_strategy_queue_source_snapshot WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),4456 FROM msbf_m2.application_strategy_candidate_evaluation WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),12000 FROM msbf_m2.application_portfolio_strategy_simulation WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),472 FROM msbf_m2.account_servicing_strategy_simulation WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),24 FROM msbf_m2.portfolio_strategy_summary WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),24 FROM msbf_m2.portfolio_strategy_frontier WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),21 FROM msbf_m2.portfolio_strategy_comparison WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),24 FROM msbf_m2.portfolio_strategy_simulation_latest WHERE module1_run_id=v_run_id
    UNION ALL SELECT count(*),24 FROM msbf_m2.portfolio_strategy_simulation_archive WHERE module1_run_id=v_run_id AND contract_version=1
  ) d WHERE n<>e;
  IF v_n<>0 THEN RAISE EXCEPTION '214B committed business-state count mismatch groups %',v_n; END IF;

  SELECT count(*) INTO v_n
  FROM msbf_m2.portfolio_strategy_simulation_latest l
  FULL JOIN msbf_m2.portfolio_strategy_simulation_archive a
    ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version
   AND a.strategy_profile_code=l.strategy_profile_code AND a.reporting_scope_code=l.reporting_scope_code
  WHERE l.module1_run_id IS NULL OR a.module1_run_id IS NULL
     OR a.contract_row_hash<>l.contract_row_hash
     OR a.contract_payload<>(to_jsonb(l)-'created_at');
  IF v_n<>0 THEN RAISE EXCEPTION '214B latest/archive mismatch count %',v_n; END IF;
END;
$m211$;

/* Reconstruct every persisted row identity before restoring checkpoint metadata. */
DO $m211$
DECLARE
    v_obj text;
    v_n bigint;
BEGIN
  FOREACH v_obj IN ARRAY ARRAY[
    'msbf_m2.portfolio_strategy_profile',
    'msbf_m2.portfolio_strategy_objective_definition',
    'msbf_m2.portfolio_strategy_constraint_definition',
    'msbf_m2.portfolio_strategy_reason_definition',
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
    'msbf_m2.portfolio_strategy_comparison'
  ] LOOP
    EXECUTE format(
      'SELECT count(*) FROM %s t WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-''row_hash''-''created_at'')',
      v_obj
    ) INTO v_n;
    IF v_n<>0 THEN
      RAISE EXCEPTION '214B persisted row-hash mismatch in %: % rows',v_obj,v_n;
    END IF;
  END LOOP;

  SELECT count(*) INTO v_n FROM msbf_ctl.m2_11_policy_profile p
  WHERE p.configuration_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(p.configuration_payload);
  IF v_n<>0 THEN RAISE EXCEPTION '214B policy configuration hash mismatch count %',v_n; END IF;

  SELECT count(*) INTO v_n FROM msbf_m2.portfolio_strategy_simulation_latest l
  WHERE l.contract_row_hash IS DISTINCT FROM
    msbf_ctl.m2_11_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at');
  IF v_n<>0 THEN RAISE EXCEPTION '214B latest contract-row hash mismatch count %',v_n; END IF;

  SELECT count(*) INTO v_n FROM msbf_m2.portfolio_strategy_simulation_archive a
  WHERE a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb
  (
    jsonb_build_object(
      'module1_run_id',a.module1_run_id,'contract_code',a.contract_code,
      'contract_version',a.contract_version,'strategy_profile_code',a.strategy_profile_code,
      'reporting_scope_code',a.reporting_scope_code,'contract_payload',a.contract_payload,
      'source_latest_row_hash',a.contract_row_hash
    )
  );
  IF v_n<>0 THEN RAISE EXCEPTION '214B archive-row hash mismatch count %',v_n; END IF;
END;
$m211$;

CREATE TEMP TABLE tmp_registry_214b_application_lineage ON COMMIT DROP AS
SELECT DISTINCT
  m1_17_bundle_code,m1_17_bundle_version,m1_17_schema_version,m1_17_methodology_version,
  m1_17_bundle_status,m1_17_combined_g2_hash,m1_17_registry_row_hash,
  m2_2_contract_code,m2_2_contract_version,m2_2_schema_version,m2_2_methodology_version,
  m2_2_contract_status,m2_2_combined_set_hash,m2_2_registry_row_hash,
  m2_4_contract_code,m2_4_contract_version,m2_4_schema_version,m2_4_methodology_version,
  m2_4_contract_status,m2_4_combined_set_hash,m2_4_registry_row_hash
FROM msbf_m2.portfolio_strategy_application_source_snapshot;

CREATE TEMP TABLE tmp_registry_214b_account_lineage ON COMMIT DROP AS
SELECT DISTINCT
  m2_7_contract_code,m2_7_contract_version,m2_7_schema_version,m2_7_methodology_version,
  m2_7_contract_status,m2_7_combined_set_hash,m2_7_registry_row_hash,
  m2_10_contract_code,m2_10_contract_version,m2_10_schema_version,m2_10_methodology_version,
  m2_10_contract_status,m2_10_combined_set_hash,m2_10_registry_row_hash,
  source_contract_identity_valid_flag,source_lineage_intact_flag,certification_blocked_flag,
  source_join_status_code
FROM msbf_m2.portfolio_strategy_account_source_snapshot;

DO $m211$
BEGIN
  IF (SELECT count(*) FROM tmp_registry_214b_application_lineage)<>1
     OR (SELECT count(*) FROM tmp_registry_214b_account_lineage)<>1 THEN
    RAISE EXCEPTION '214B source lineage does not collapse to one accepted identity per source family';
  END IF;

  IF NOT EXISTS
  (
    SELECT 1 FROM tmp_registry_214b_application_lineage
    WHERE m1_17_bundle_code='M1_G2_CONSUMPTION_BUNDLE'
      AND m1_17_bundle_version=1
      AND m1_17_schema_version='M1_G2_BUNDLE_SCHEMA_V1'
      AND m1_17_methodology_version='M1_17_METHOD_V1'
      AND m1_17_bundle_status='ACCEPTED'
      AND m1_17_combined_g2_hash='7d9e466da28cad2551aa99c4c40c912b'
      AND m1_17_registry_row_hash~'^[0-9a-f]{32}$'
      AND m2_2_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION'
      AND m2_2_contract_version=1
      AND m2_2_schema_version='M2_2_PRICING_STRUCTURE_SCHEMA_V1'
      AND m2_2_methodology_version='M2_2_METHOD_V1'
      AND m2_2_contract_status='ACCEPTED'
      AND m2_2_combined_set_hash='bbe83b187b31ea561789797322031fc6'
      AND m2_2_registry_row_hash~'^[0-9a-f]{32}$'
      AND m2_4_contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
      AND m2_4_contract_version=1
      AND m2_4_schema_version='M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
      AND m2_4_methodology_version='M2_4_METHOD_V1'
      AND m2_4_contract_status='ACCEPTED'
      AND m2_4_combined_set_hash='117450a3eea7bb3d3c74d18cc3c8e96a'
      AND m2_4_registry_row_hash~'^[0-9a-f]{32}$'
  ) THEN RAISE EXCEPTION '214B application-source lineage identity/hash mismatch'; END IF;

  IF NOT EXISTS
  (
    SELECT 1 FROM tmp_registry_214b_account_lineage
    WHERE m2_7_contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
      AND m2_7_contract_version=1
      AND m2_7_schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
      AND m2_7_methodology_version='M2_7_METHOD_V1'
      AND m2_7_contract_status='ACCEPTED'
      AND m2_7_combined_set_hash='c8e3a472afd2a16b1183677324e9db98'
      AND m2_7_registry_row_hash~'^[0-9a-f]{32}$'
      AND m2_10_contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'
      AND m2_10_contract_version=1
      AND m2_10_schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'
      AND m2_10_methodology_version='M2_10_METHOD_V1'
      AND m2_10_contract_status='ACCEPTED'
      AND m2_10_combined_set_hash='24fca7263a04397ebf21d30639f9069b'
      AND m2_10_registry_row_hash~'^[0-9a-f]{32}$'
      AND source_contract_identity_valid_flag
      AND source_lineage_intact_flag
      AND NOT certification_blocked_flag
      AND source_join_status_code='MATCHED_ONE_TO_ONE'
  ) THEN RAISE EXCEPTION '214B account-source lineage/certification identity mismatch'; END IF;
END;
$m211$;

CREATE TEMP TABLE tmp_registry_214b_object_set_hash
(
  catalog_sequence integer NOT NULL,object_code text NOT NULL,set_hash text NOT NULL,
  PRIMARY KEY(object_code)
) ON COMMIT DROP;

INSERT INTO tmp_registry_214b_object_set_hash(catalog_sequence,object_code,set_hash) VALUES
(1,'msbf_ctl.m2_11_policy_profile',(SELECT md5(string_agg(configuration_hash,'|' ORDER BY module1_run_id)) FROM msbf_ctl.m2_11_policy_profile)),
(2,'msbf_m2.portfolio_strategy_profile',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_profile)),
(3,'msbf_m2.portfolio_strategy_objective_definition',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,objective_code)) FROM msbf_m2.portfolio_strategy_objective_definition)),
(4,'msbf_m2.portfolio_strategy_constraint_definition',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,constraint_code)) FROM msbf_m2.portfolio_strategy_constraint_definition)),
(5,'msbf_m2.portfolio_strategy_reason_definition',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,reason_code)) FROM msbf_m2.portfolio_strategy_reason_definition)),
(6,'msbf_m2.portfolio_strategy_application_source_snapshot',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scenario_id,merchant_application_id)) FROM msbf_m2.portfolio_strategy_application_source_snapshot)),
(7,'msbf_m2.portfolio_strategy_candidate_source_snapshot',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code)) FROM msbf_m2.portfolio_strategy_candidate_source_snapshot)),
(8,'msbf_m2.portfolio_strategy_account_source_snapshot',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scenario_id,merchant_application_id)) FROM msbf_m2.portfolio_strategy_account_source_snapshot)),
(9,'msbf_m2.portfolio_strategy_kpi_source_snapshot',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scope_code,kpi_code)) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot)),
(10,'msbf_m2.portfolio_strategy_queue_source_snapshot',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,servicing_queue_code)) FROM msbf_m2.portfolio_strategy_queue_source_snapshot)),
(11,'msbf_m2.application_strategy_candidate_evaluation',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code)) FROM msbf_m2.application_strategy_candidate_evaluation)),
(12,'msbf_m2.application_portfolio_strategy_simulation',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)) FROM msbf_m2.application_portfolio_strategy_simulation)),
(13,'msbf_m2.account_servicing_strategy_simulation',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)) FROM msbf_m2.account_servicing_strategy_simulation)),
(14,'msbf_m2.portfolio_strategy_summary',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_summary)),
(15,'msbf_m2.portfolio_strategy_frontier',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_frontier)),
(16,'msbf_m2.portfolio_strategy_comparison',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,reporting_scope_code,challenger_strategy_profile_code)) FROM msbf_m2.portfolio_strategy_comparison)),
(17,'msbf_m2.portfolio_strategy_simulation_latest',(SELECT md5(string_agg(contract_row_hash,'|' ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_latest)),
(18,'msbf_m2.portfolio_strategy_simulation_archive',(SELECT md5(string_agg(archive_row_hash,'|' ORDER BY module1_run_id,contract_version,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_archive));

CREATE TEMP TABLE tmp_registry_214b_registry_core ON COMMIT DROP AS
SELECT
    rr.run_id AS module1_run_id,
    'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AS contract_code,
    1 AS contract_version,
    'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1' AS schema_version,
    'M2_11_METHOD_V1' AS methodology_version,
    'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION' AS acceptance_gate_id,
    p.configuration_hash AS policy_configuration_hash,
    al.m1_17_bundle_code AS source_m1_17_contract_code,
    al.m1_17_bundle_version AS source_m1_17_contract_version,
    al.m1_17_schema_version AS source_m1_17_schema_version,
    al.m1_17_methodology_version AS source_m1_17_methodology_version,
    'G2_M1_CONTRACT' AS source_m1_17_acceptance_gate_id,
    al.m1_17_combined_g2_hash AS source_m1_17_combined_hash,
    al.m1_17_registry_row_hash AS source_m1_17_registry_row_hash,
    al.m2_2_contract_code AS source_m2_2_contract_code,
    al.m2_2_contract_version AS source_m2_2_contract_version,
    al.m2_2_schema_version AS source_m2_2_schema_version,
    al.m2_2_methodology_version AS source_m2_2_methodology_version,
    'M2_2_PRICING_STRUCTURE_COUNTEROFFER' AS source_m2_2_acceptance_gate_id,
    al.m2_2_combined_set_hash AS source_m2_2_combined_hash,
    al.m2_2_registry_row_hash AS source_m2_2_registry_row_hash,
    al.m2_4_contract_code AS source_m2_4_contract_code,
    al.m2_4_contract_version AS source_m2_4_contract_version,
    al.m2_4_schema_version AS source_m2_4_schema_version,
    al.m2_4_methodology_version AS source_m2_4_methodology_version,
    'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AS source_m2_4_acceptance_gate_id,
    al.m2_4_combined_set_hash AS source_m2_4_combined_hash,
    al.m2_4_registry_row_hash AS source_m2_4_registry_row_hash,
    xl.m2_7_contract_code AS source_m2_7_contract_code,
    xl.m2_7_contract_version AS source_m2_7_contract_version,
    xl.m2_7_schema_version AS source_m2_7_schema_version,
    xl.m2_7_methodology_version AS source_m2_7_methodology_version,
    'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AS source_m2_7_acceptance_gate_id,
    xl.m2_7_combined_set_hash AS source_m2_7_combined_hash,
    xl.m2_7_registry_row_hash AS source_m2_7_registry_row_hash,
    xl.m2_10_contract_code AS source_m2_10_contract_code,
    xl.m2_10_contract_version AS source_m2_10_contract_version,
    xl.m2_10_schema_version AS source_m2_10_schema_version,
    xl.m2_10_methodology_version AS source_m2_10_methodology_version,
    'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AS source_m2_10_acceptance_gate_id,
    xl.m2_10_combined_set_hash AS source_m2_10_combined_hash,
    xl.m2_10_registry_row_hash AS source_m2_10_registry_row_hash,
    1::bigint AS policy_rows,
    8::bigint AS strategy_profile_rows,
    8::bigint AS objective_definition_rows,
    12::bigint AS constraint_definition_rows,
    32::bigint AS reason_definition_rows,
    1500::bigint AS application_source_rows,
    557::bigint AS candidate_source_rows,
    59::bigint AS account_source_rows,
    72::bigint AS kpi_source_rows,
    3::bigint AS queue_source_rows,
    4456::bigint AS candidate_evaluation_rows,
    12000::bigint AS application_simulation_rows,
    472::bigint AS account_simulation_rows,
    24::bigint AS strategy_summary_rows,
    24::bigint AS frontier_rows,
    21::bigint AS comparison_rows,
    24::bigint AS latest_rows,
    24::bigint AS archive_rows,
    1::bigint AS registry_rows,
    19298::bigint AS canonical_entities,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_ctl.m2_11_policy_profile') AS policy_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_profile') AS strategy_profile_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_objective_definition') AS objective_definition_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_constraint_definition') AS constraint_definition_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_reason_definition') AS reason_definition_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_application_source_snapshot') AS application_source_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_candidate_source_snapshot') AS candidate_source_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_account_source_snapshot') AS account_source_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_kpi_source_snapshot') AS kpi_source_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_queue_source_snapshot') AS queue_source_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.application_strategy_candidate_evaluation') AS candidate_evaluation_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.application_portfolio_strategy_simulation') AS application_simulation_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.account_servicing_strategy_simulation') AS account_simulation_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_summary') AS strategy_summary_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_frontier') AS frontier_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_comparison') AS comparison_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_simulation_latest') AS latest_set_hash,
    (SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_simulation_archive') AS archive_set_hash,
    md5((SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_simulation_latest')||'|'||(SELECT set_hash FROM tmp_registry_214b_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_simulation_archive')) AS contract_set_hash,
    'GENERATED'::text AS contract_status
FROM msbf_ctl.run_registry rr
CROSS JOIN msbf_ctl.m2_11_policy_profile p
CROSS JOIN tmp_registry_214b_application_lineage al
CROSS JOIN tmp_registry_214b_account_lineage xl
WHERE rr.run_code='M1_V0_2_BASELINE_BUILD' AND rr.run_version=1;

CREATE TEMP TABLE tmp_registry_214b_registry_typed ON COMMIT DROP AS
SELECT * FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry WITH NO DATA;

INSERT INTO tmp_registry_214b_registry_typed
(
    registry_id,
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    acceptance_gate_id,
    policy_configuration_hash,
    source_m1_17_contract_code,
    source_m1_17_contract_version,
    source_m1_17_schema_version,
    source_m1_17_methodology_version,
    source_m1_17_acceptance_gate_id,
    source_m1_17_combined_hash,
    source_m1_17_registry_row_hash,
    source_m2_2_contract_code,
    source_m2_2_contract_version,
    source_m2_2_schema_version,
    source_m2_2_methodology_version,
    source_m2_2_acceptance_gate_id,
    source_m2_2_combined_hash,
    source_m2_2_registry_row_hash,
    source_m2_4_contract_code,
    source_m2_4_contract_version,
    source_m2_4_schema_version,
    source_m2_4_methodology_version,
    source_m2_4_acceptance_gate_id,
    source_m2_4_combined_hash,
    source_m2_4_registry_row_hash,
    source_m2_7_contract_code,
    source_m2_7_contract_version,
    source_m2_7_schema_version,
    source_m2_7_methodology_version,
    source_m2_7_acceptance_gate_id,
    source_m2_7_combined_hash,
    source_m2_7_registry_row_hash,
    source_m2_10_contract_code,
    source_m2_10_contract_version,
    source_m2_10_schema_version,
    source_m2_10_methodology_version,
    source_m2_10_acceptance_gate_id,
    source_m2_10_combined_hash,
    source_m2_10_registry_row_hash,
    policy_rows,
    strategy_profile_rows,
    objective_definition_rows,
    constraint_definition_rows,
    reason_definition_rows,
    application_source_rows,
    candidate_source_rows,
    account_source_rows,
    kpi_source_rows,
    queue_source_rows,
    candidate_evaluation_rows,
    application_simulation_rows,
    account_simulation_rows,
    strategy_summary_rows,
    frontier_rows,
    comparison_rows,
    latest_rows,
    archive_rows,
    registry_rows,
    canonical_entities,
    policy_set_hash,
    strategy_profile_set_hash,
    objective_definition_set_hash,
    constraint_definition_set_hash,
    reason_definition_set_hash,
    application_source_set_hash,
    candidate_source_set_hash,
    account_source_set_hash,
    kpi_source_set_hash,
    queue_source_set_hash,
    candidate_evaluation_set_hash,
    application_simulation_set_hash,
    account_simulation_set_hash,
    strategy_summary_set_hash,
    frontier_set_hash,
    comparison_set_hash,
    latest_set_hash,
    archive_set_hash,
    contract_set_hash,
    combined_set_hash,
    contract_status,
    generated_at,
    validated_at,
    accepted_at,
    row_hash,
    created_at
)
SELECT (jsonb_populate_record(
  NULL::msbf_ctl.m2_11_portfolio_strategy_contract_registry,
  to_jsonb(c)
)).*
FROM tmp_registry_214b_registry_core c;

UPDATE tmp_registry_214b_registry_typed AS t
SET row_hash=msbf_ctl.m2_11_registry_row_hash(to_jsonb(t));

CREATE TEMP TABLE tmp_registry_214b_all_set_hash ON COMMIT DROP AS
SELECT * FROM tmp_registry_214b_object_set_hash
UNION ALL SELECT 19,'msbf_ctl.m2_11_portfolio_strategy_contract_registry',
       md5(string_agg(row_hash,'|' ORDER BY module1_run_id,contract_version))
FROM tmp_registry_214b_registry_typed;

UPDATE tmp_registry_214b_registry_typed AS t
SET combined_set_hash=x.combined_set_hash
FROM
(
  SELECT md5(string_agg(object_code||'|'||set_hash,'|' ORDER BY catalog_sequence)) AS combined_set_hash
  FROM tmp_registry_214b_all_set_hash
) x;

CREATE TEMP TABLE tmp_registry_214b_registry_final ON COMMIT DROP AS
SELECT t.*,t.row_hash AS registry_row_hash
FROM tmp_registry_214b_registry_typed t;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n
  FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry e
  CROSS JOIN tmp_registry_214b_registry_final d
  WHERE e.row_hash IS DISTINCT FROM d.registry_row_hash
     OR e.combined_set_hash IS DISTINCT FROM d.combined_set_hash
     OR e.contract_set_hash IS DISTINCT FROM d.contract_set_hash
     OR EXISTS
     (
       SELECT 1 FROM jsonb_each_text(to_jsonb(d)) j
       WHERE j.key LIKE '%_set_hash'
         AND (to_jsonb(e)->>j.key) IS DISTINCT FROM j.value
     );
  IF v_n<>0 THEN RAISE EXCEPTION '214B existing registry conflicts with reconstructed checkpoint'; END IF;
END;
$m211$;

INSERT INTO msbf_ctl.m2_11_portfolio_strategy_contract_registry
(
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    acceptance_gate_id,
    policy_configuration_hash,
    source_m1_17_contract_code,
    source_m1_17_contract_version,
    source_m1_17_schema_version,
    source_m1_17_methodology_version,
    source_m1_17_acceptance_gate_id,
    source_m1_17_combined_hash,
    source_m1_17_registry_row_hash,
    source_m2_2_contract_code,
    source_m2_2_contract_version,
    source_m2_2_schema_version,
    source_m2_2_methodology_version,
    source_m2_2_acceptance_gate_id,
    source_m2_2_combined_hash,
    source_m2_2_registry_row_hash,
    source_m2_4_contract_code,
    source_m2_4_contract_version,
    source_m2_4_schema_version,
    source_m2_4_methodology_version,
    source_m2_4_acceptance_gate_id,
    source_m2_4_combined_hash,
    source_m2_4_registry_row_hash,
    source_m2_7_contract_code,
    source_m2_7_contract_version,
    source_m2_7_schema_version,
    source_m2_7_methodology_version,
    source_m2_7_acceptance_gate_id,
    source_m2_7_combined_hash,
    source_m2_7_registry_row_hash,
    source_m2_10_contract_code,
    source_m2_10_contract_version,
    source_m2_10_schema_version,
    source_m2_10_methodology_version,
    source_m2_10_acceptance_gate_id,
    source_m2_10_combined_hash,
    source_m2_10_registry_row_hash,
    policy_rows,
    strategy_profile_rows,
    objective_definition_rows,
    constraint_definition_rows,
    reason_definition_rows,
    application_source_rows,
    candidate_source_rows,
    account_source_rows,
    kpi_source_rows,
    queue_source_rows,
    candidate_evaluation_rows,
    application_simulation_rows,
    account_simulation_rows,
    strategy_summary_rows,
    frontier_rows,
    comparison_rows,
    latest_rows,
    archive_rows,
    registry_rows,
    canonical_entities,
    policy_set_hash,
    strategy_profile_set_hash,
    objective_definition_set_hash,
    constraint_definition_set_hash,
    reason_definition_set_hash,
    application_source_set_hash,
    candidate_source_set_hash,
    account_source_set_hash,
    kpi_source_set_hash,
    queue_source_set_hash,
    candidate_evaluation_set_hash,
    application_simulation_set_hash,
    account_simulation_set_hash,
    strategy_summary_set_hash,
    frontier_set_hash,
    comparison_set_hash,
    latest_set_hash,
    archive_set_hash,
    contract_set_hash,
    combined_set_hash,
    contract_status,
    generated_at,
    validated_at,
    accepted_at,
    row_hash,
    created_at
)
SELECT
    d.module1_run_id,
    d.contract_code,
    d.contract_version,
    d.schema_version,
    d.methodology_version,
    d.acceptance_gate_id,
    d.policy_configuration_hash,
    d.source_m1_17_contract_code,
    d.source_m1_17_contract_version,
    d.source_m1_17_schema_version,
    d.source_m1_17_methodology_version,
    d.source_m1_17_acceptance_gate_id,
    d.source_m1_17_combined_hash,
    d.source_m1_17_registry_row_hash,
    d.source_m2_2_contract_code,
    d.source_m2_2_contract_version,
    d.source_m2_2_schema_version,
    d.source_m2_2_methodology_version,
    d.source_m2_2_acceptance_gate_id,
    d.source_m2_2_combined_hash,
    d.source_m2_2_registry_row_hash,
    d.source_m2_4_contract_code,
    d.source_m2_4_contract_version,
    d.source_m2_4_schema_version,
    d.source_m2_4_methodology_version,
    d.source_m2_4_acceptance_gate_id,
    d.source_m2_4_combined_hash,
    d.source_m2_4_registry_row_hash,
    d.source_m2_7_contract_code,
    d.source_m2_7_contract_version,
    d.source_m2_7_schema_version,
    d.source_m2_7_methodology_version,
    d.source_m2_7_acceptance_gate_id,
    d.source_m2_7_combined_hash,
    d.source_m2_7_registry_row_hash,
    d.source_m2_10_contract_code,
    d.source_m2_10_contract_version,
    d.source_m2_10_schema_version,
    d.source_m2_10_methodology_version,
    d.source_m2_10_acceptance_gate_id,
    d.source_m2_10_combined_hash,
    d.source_m2_10_registry_row_hash,
    d.policy_rows,
    d.strategy_profile_rows,
    d.objective_definition_rows,
    d.constraint_definition_rows,
    d.reason_definition_rows,
    d.application_source_rows,
    d.candidate_source_rows,
    d.account_source_rows,
    d.kpi_source_rows,
    d.queue_source_rows,
    d.candidate_evaluation_rows,
    d.application_simulation_rows,
    d.account_simulation_rows,
    d.strategy_summary_rows,
    d.frontier_rows,
    d.comparison_rows,
    d.latest_rows,
    d.archive_rows,
    d.registry_rows,
    d.canonical_entities,
    d.policy_set_hash,
    d.strategy_profile_set_hash,
    d.objective_definition_set_hash,
    d.constraint_definition_set_hash,
    d.reason_definition_set_hash,
    d.application_source_set_hash,
    d.candidate_source_set_hash,
    d.account_source_set_hash,
    d.kpi_source_set_hash,
    d.queue_source_set_hash,
    d.candidate_evaluation_set_hash,
    d.application_simulation_set_hash,
    d.account_simulation_set_hash,
    d.strategy_summary_set_hash,
    d.frontier_set_hash,
    d.comparison_set_hash,
    d.latest_set_hash,
    d.archive_set_hash,
    d.contract_set_hash,
    d.combined_set_hash,
    d.contract_status,
    clock_timestamp(),NULL::timestamptz,NULL::timestamptz,d.registry_row_hash,clock_timestamp()
FROM tmp_registry_214b_registry_final d
WHERE NOT EXISTS
(
  SELECT 1 FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry e
  WHERE e.module1_run_id=d.module1_run_id AND e.contract_version=d.contract_version
);

UPDATE msbf_ctl.m2_11_portfolio_strategy_contract_registry e
SET contract_status='GENERATED',generated_at=coalesce(e.generated_at,clock_timestamp()),
    validated_at=NULL,accepted_at=NULL
WHERE e.module1_run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND e.contract_version=1;

DO $m211$
DECLARE
    v_n bigint;
    v_hash text;
BEGIN
  SELECT count(*) INTO v_n FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry;
  IF v_n<>1 THEN RAISE EXCEPTION '214B registry count expected 1; found %',v_n; END IF;
  SELECT count(*) INTO v_n FROM msbf_m2.v_m2_11_canonical_entity_hash_source;
  IF v_n<>19298 THEN RAISE EXCEPTION '214B canonical count expected 19298; found %',v_n; END IF;
  SELECT md5(string_agg(object_code||'|'||set_hash,'|' ORDER BY catalog_sequence)) INTO v_hash
  FROM
  (
    SELECT catalog_sequence,object_code,md5(string_agg(row_hash,'|' ORDER BY business_key)) AS set_hash
    FROM msbf_m2.v_m2_11_canonical_entity_hash_source GROUP BY catalog_sequence,object_code
  ) s;
  IF v_hash<>(SELECT combined_set_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry) THEN
    RAISE EXCEPTION '214B reconstructed combined hash mismatch';
  END IF;
END;
$m211$;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n
  FROM msbf_ctl.run_evidence e
  JOIN msbf_m2.portfolio_strategy_simulation_latest l
    ON e.run_id=l.module1_run_id
   AND e.evidence_code='M2_11_GENERATION_'||l.reporting_scope_code||'_'||l.strategy_profile_code
  WHERE e.metric_value_text<>l.contract_row_hash OR e.status<>'PASS';
  IF v_n<>0 THEN RAISE EXCEPTION '214B existing generation evidence conflicts with latest contract'; END IF;
END;
$m211$;

INSERT INTO msbf_ctl.run_evidence
(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,interpretation)
SELECT l.module1_run_id,
  'M2_11_GENERATION_'||l.reporting_scope_code||'_'||l.strategy_profile_code,
  l.reporting_scope_code||'|'||l.strategy_profile_code,
  'M2.11 generated strategy-and-scope contract row hash',NULL::numeric(24,10),
  l.contract_row_hash,'HASH','PASS',
  'Recovered GENERATED checkpoint evidence from unchanged committed M2.11 business rows; not validation or acceptance.'
FROM msbf_m2.portfolio_strategy_simulation_latest l
WHERE NOT EXISTS
(
  SELECT 1 FROM msbf_ctl.run_evidence e
  WHERE e.run_id=l.module1_run_id
    AND e.evidence_code='M2_11_GENERATION_'||l.reporting_scope_code||'_'||l.strategy_profile_code
    AND e.segment_key=l.reporting_scope_code||'|'||l.strategy_profile_code
)
ORDER BY l.reporting_scope_code,l.strategy_profile_code;

DO $m211$
BEGIN
  IF (SELECT count(*) FROM msbf_ctl.run_evidence
      WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
        AND evidence_code LIKE 'M2_11_GENERATION_%')<>24 THEN
    RAISE EXCEPTION '214B generation evidence did not reconcile to 24';
  END IF;
END;
$m211$;

UPDATE msbf_ctl.run_registry r
SET run_status='M2_11_GENERATED',row_count=19298,
    source_snapshot_hash=c.combined_set_hash,completed_at=NULL,
    notes=concat_ws(E'\n',r.notes,'M2.11 GENERATED checkpoint reconstructed from unchanged committed business rows by recovery Program 214B.')
FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
WHERE c.module1_run_id=r.run_id
  AND r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

COMMIT;
SELECT r.run_id,r.run_status,c.contract_status,c.canonical_entities,c.combined_set_hash,
       'CHECKPOINT_RECONSTRUCTED_FROM_UNCHANGED_COMMITTED_ROWS'::text AS recovery_status,
       'NOT_VALIDATED'::text AS validation_status,'NOT_ACCEPTED'::text AS acceptance_status
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry c ON c.module1_run_id=r.run_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;
