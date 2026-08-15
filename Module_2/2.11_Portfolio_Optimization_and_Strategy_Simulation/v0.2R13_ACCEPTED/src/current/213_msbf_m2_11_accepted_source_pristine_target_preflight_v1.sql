/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.11 — Portfolio Optimization & Strategy Simulation

Program     : 213_msbf_m2_11_accepted_source_pristine_target_preflight_v1.sql
Revision    : WP2_LIVE_EXECUTION_INDEX_STRUCTURE_CORRECTION_R1
Methodology : M2_11_METHOD_V1
Contract    : M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION v1
Schema      : M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1

Purpose
-------
Perform a read-only, fail-closed preflight over the accepted governed run, all five authorized source families, every required physical source field, source grains and one-to-one relationships, frozen M2.11 definitions, and pristine generation targets.

Stage boundary
--------------
Program 213 is SELECT-only. It does not persist target rows, generate strategy evidence, create latest/archive rows, write run evidence, or advance lifecycle state.

Required result
---------------
preflight_status = PASS; every accepted source identity/count/hash/grain/join and every frozen definition/pristine-target check reconciles.

Execution control
-----------------
Execute as one PostgreSQL script. Stop at the first error. Do not execute any
recovery program unless the failed state has first been diagnosed. This source
is READY FOR LIVE EXECUTION, NOT EXECUTED, and NOT ACCEPTED.
============================================================================ */

BEGIN;
SET TRANSACTION READ ONLY;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='40min';
SET LOCAL jit=off;

/* ============================================================================
Section 1 — Governed run, source registry, acceptance-gate, count, and hash checks
============================================================================ */
DO $m211$
DECLARE
    v_run_id bigint;
    v_status text;
    v_bad bigint;
BEGIN
    SELECT run_id,run_status INTO STRICT v_run_id,v_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
    IF v_status<>'M2_10_ACCEPTED' THEN
        RAISE EXCEPTION 'Program 213 requires M2_10_ACCEPTED; found %',v_status;
    END IF;

    /* Program 212 installation identity: exact M2.11 gate row and accepted G0 severity domain. */
    IF
    (
        SELECT count(*)
        FROM msbf_ref.acceptance_gate_catalog
        WHERE gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
          AND gate_name='M2.11 Portfolio Optimization & Strategy Simulation'
          AND module_code='M2.11'
          AND severity='BLOCKING'
          AND active_flag
    )<>1 THEN
        RAISE EXCEPTION 'M2.11 acceptance-gate catalog definition is absent or incompatible';
    END IF;

    IF (SELECT count(*) FROM msbf_ctl.m1_17_g2_bundle_registry WHERE module1_run_id=v_run_id)<>1
       OR (SELECT count(*) FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=v_run_id)<>1
       OR (SELECT count(*) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=v_run_id)<>1
       OR (SELECT count(*) FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=v_run_id)<>1
       OR (SELECT count(*) FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=v_run_id)<>1 THEN
        RAISE EXCEPTION 'Exactly one accepted registry row is required for each of the five source families';
    END IF;

    IF NOT EXISTS
    (
        SELECT 1 FROM msbf_ctl.m1_17_g2_bundle_registry
        WHERE module1_run_id=v_run_id
          AND bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND bundle_version=1
          AND schema_version='M1_G2_BUNDLE_SCHEMA_V1'
          AND methodology_version='M1_17_METHOD_V1'
          AND bundle_status='ACCEPTED'
          AND integrated_consumption_rows=1500
          AND combined_g2_hash='7d9e466da28cad2551aa99c4c40c912b'
          AND bundle_latest_set_hash~'^[0-9a-f]{32}$'
          AND row_hash~'^[0-9a-f]{32}$'
    ) THEN RAISE EXCEPTION 'M1.17 accepted registry identity/count/hash mismatch'; END IF;

    IF NOT EXISTS
    (
        SELECT 1 FROM msbf_ctl.m2_2_pricing_structure_contract_registry
        WHERE module1_run_id=v_run_id
          AND pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION'
          AND pricing_contract_version=1
          AND pricing_schema_version='M2_2_PRICING_STRUCTURE_SCHEMA_V1'
          AND methodology_version='M2_2_METHOD_V1'
          AND contract_status='ACCEPTED'
          AND pricing_latest_rows=1500 AND candidate_rows=557
          AND combined_set_hash='bbe83b187b31ea561789797322031fc6'
          AND candidate_set_hash~'^[0-9a-f]{32}$'
          AND pricing_latest_set_hash~'^[0-9a-f]{32}$'
          AND row_hash~'^[0-9a-f]{32}$'
    ) THEN RAISE EXCEPTION 'M2.2 accepted registry identity/count/hash mismatch'; END IF;

    IF NOT EXISTS
    (
        SELECT 1 FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
        WHERE module1_run_id=v_run_id
          AND contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND contract_version=1
          AND schema_version='M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
          AND methodology_version='M2_4_METHOD_V1'
          AND contract_status='ACCEPTED'
          AND activation_latest_rows=1500
          AND combined_set_hash='117450a3eea7bb3d3c74d18cc3c8e96a'
          AND activation_latest_set_hash~'^[0-9a-f]{32}$'
          AND row_hash~'^[0-9a-f]{32}$'
    ) THEN RAISE EXCEPTION 'M2.4 accepted registry identity/count/hash mismatch'; END IF;

    IF NOT EXISTS
    (
        SELECT 1 FROM msbf_ctl.m2_7_operational_activation_contract_registry
        WHERE module1_run_id=v_run_id
          AND contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND contract_version=1
          AND schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
          AND methodology_version='M2_7_METHOD_V1'
          AND contract_status='ACCEPTED'
          AND latest_rows=59
          AND combined_set_hash='c8e3a472afd2a16b1183677324e9db98'
          AND latest_set_hash~'^[0-9a-f]{32}$'
          AND row_hash~'^[0-9a-f]{32}$'
    ) THEN RAISE EXCEPTION 'M2.7 accepted registry identity/count/hash mismatch'; END IF;

    IF NOT EXISTS
    (
        SELECT 1 FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
        WHERE module1_run_id=v_run_id
          AND contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND contract_version=1
          AND schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'
          AND methodology_version='M2_10_METHOD_V1'
          AND contract_status='ACCEPTED'
          AND latest_rows=59 AND kpi_snapshot_rows=72 AND queue_summary_rows=3
          AND portfolio_account_rows=59 AND baseline_account_rows=44 AND stress_account_rows=15
          AND closed_stable_rows=57 AND active_reconciled_rows=1 AND controlled_review_rows=1
          AND certified_account_rows=59 AND certification_rate=1.000000::numeric
          AND certified_exposure_amount=785.48::numeric
          AND active_exposure_amount=323.79::numeric
          AND review_hold_exposure_amount=461.69::numeric
          AND unresolved_exception_count=0
          AND servicing_burden_units=7.000000::numeric
          AND combined_set_hash='24fca7263a04397ebf21d30639f9069b'
          AND kpi_snapshot_set_hash~'^[0-9a-f]{32}$'
          AND queue_summary_set_hash~'^[0-9a-f]{32}$'
          AND latest_set_hash~'^[0-9a-f]{32}$'
          AND row_hash~'^[0-9a-f]{32}$'
    ) THEN RAISE EXCEPTION 'M2.10 accepted registry identity/count/hash mismatch'; END IF;

    WITH required(gate_id) AS
    (
        VALUES
        ('G2_M1_CONTRACT'),
        ('M2_2_PRICING_STRUCTURE_COUNTEROFFER'),
        ('M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'),
        ('M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'),
        ('M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS')
    ), latest_gate AS
    (
        SELECT DISTINCT ON (gate_id) gate_id,result_status
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id=v_run_id AND gate_id IN (SELECT gate_id FROM required)
        ORDER BY gate_id,review_version DESC
    )
    SELECT count(*) INTO v_bad
    FROM required r LEFT JOIN latest_gate g USING(gate_id)
    WHERE g.gate_id IS NULL OR g.result_status<>'PASS';
    IF v_bad<>0 THEN RAISE EXCEPTION '% accepted predecessor gates are absent or non-PASS',v_bad; END IF;
END;
$m211$;

/* ============================================================================
Section 2 — Exact physical source row-count and grain checks
============================================================================ */
DO $m211$
DECLARE
    v_run_id bigint;
    v_n bigint;
BEGIN
    SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

    SELECT count(*) INTO v_n FROM msbf_m1.v_m1_17_g2_integrated_consumption WHERE module1_run_id=v_run_id; IF v_n<>1500 THEN RAISE EXCEPTION 'msbf_m1.v_m1_17_g2_integrated_consumption expected 1500 rows; found %',v_n; END IF;

    SELECT count(*) INTO v_n FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=v_run_id; IF v_n<>1500 THEN RAISE EXCEPTION 'msbf_m2.application_pricing_structure_latest expected 1500 rows; found %',v_n; END IF;

    SELECT count(*) INTO v_n FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=v_run_id; IF v_n<>557 THEN RAISE EXCEPTION 'msbf_m2.application_pricing_structure_candidate expected 557 rows; found %',v_n; END IF;

    SELECT count(*) INTO v_n FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=v_run_id; IF v_n<>1500 THEN RAISE EXCEPTION 'msbf_m2.application_booking_funding_activation_latest expected 1500 rows; found %',v_n; END IF;

    SELECT count(*) INTO v_n FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=v_run_id; IF v_n<>59 THEN RAISE EXCEPTION 'msbf_m2.application_operational_activation_latest expected 59 rows; found %',v_n; END IF;

    SELECT count(*) INTO v_n FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=v_run_id; IF v_n<>59 THEN RAISE EXCEPTION 'msbf_m2.application_portfolio_performance_latest expected 59 rows; found %',v_n; END IF;

    SELECT count(*) INTO v_n FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=v_run_id; IF v_n<>72 THEN RAISE EXCEPTION 'msbf_m2.portfolio_kpi_snapshot expected 72 rows; found %',v_n; END IF;

    SELECT count(*) INTO v_n FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=v_run_id; IF v_n<>3 THEN RAISE EXCEPTION 'msbf_m2.servicing_queue_analytics_snapshot expected 3 rows; found %',v_n; END IF;


    SELECT count(*)-count(DISTINCT (scenario_id,merchant_application_id)) INTO v_n
    FROM msbf_m1.v_m1_17_g2_integrated_consumption WHERE module1_run_id=v_run_id;
    IF v_n<>0 THEN RAISE EXCEPTION 'M1.17 source grain duplicates: %',v_n; END IF;

    SELECT count(*)-count(DISTINCT (scenario_id,merchant_application_id)) INTO v_n
    FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=v_run_id;
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.2 latest grain duplicates: %',v_n; END IF;

    SELECT count(*)-count(DISTINCT (scenario_id,merchant_application_id,candidate_template_code)) INTO v_n
    FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=v_run_id;
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.2 candidate grain duplicates: %',v_n; END IF;

    SELECT count(*)-count(DISTINCT (scenario_id,merchant_application_id)) INTO v_n
    FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=v_run_id;
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.4 latest grain duplicates: %',v_n; END IF;

    SELECT count(*)-count(DISTINCT (scenario_id,merchant_application_id)) INTO v_n
    FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=v_run_id;
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.7 latest grain duplicates: %',v_n; END IF;

    SELECT count(*)-count(DISTINCT (scenario_id,merchant_application_id)) INTO v_n
    FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=v_run_id;
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.10 latest grain duplicates: %',v_n; END IF;

    SELECT count(*)-count(DISTINCT (scope_code,kpi_code)) INTO v_n
    FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=v_run_id;
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.10 KPI grain duplicates: %',v_n; END IF;

    SELECT count(*)-count(DISTINCT servicing_queue_code) INTO v_n
    FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=v_run_id;
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.10 queue grain duplicates: %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM
    (
      SELECT
        scope_code,
        scope_type,
        scenario_code,
        count(*)::bigint AS kpi_rows,
        count(DISTINCT kpi_code)::bigint AS kpi_codes
      FROM msbf_m2.portfolio_kpi_snapshot
      WHERE module1_run_id=v_run_id
      GROUP BY scope_code,scope_type,scenario_code
    ) s
    FULL JOIN
    (
      VALUES
        ('BASELINE'::text,'SCENARIO'::text,'BASELINE'::text,24::bigint,24::bigint),
        ('RECESSION_ENERGY'::text,'SCENARIO'::text,'RECESSION_ENERGY'::text,24::bigint,24::bigint),
        ('PORTFOLIO_ALL'::text,'PORTFOLIO'::text,NULL::text,24::bigint,24::bigint)
    ) e(scope_code,scope_type,scenario_code,kpi_rows,kpi_codes)
      ON s.scope_code=e.scope_code
     AND s.scope_type=e.scope_type
     AND s.scenario_code IS NOT DISTINCT FROM e.scenario_code
    WHERE s.scope_code IS NULL
       OR e.scope_code IS NULL
       OR s.kpi_rows IS DISTINCT FROM e.kpi_rows
       OR s.kpi_codes IS DISTINCT FROM e.kpi_codes;
    IF v_n<>0
       OR (SELECT count(*) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=v_run_id)<>72
       OR (SELECT count(DISTINCT scope_code) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=v_run_id)<>3
       OR (SELECT count(DISTINCT kpi_code) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=v_run_id)<>24 THEN
        RAISE EXCEPTION 'M2.10 KPI source coverage must be BASELINE/SCENARIO/BASELINE, RECESSION_ENERGY/SCENARIO/RECESSION_ENERGY, and PORTFOLIO_ALL/PORTFOLIO/NULL with 24 KPI codes each';
    END IF;

    SELECT coalesce(sum(account_count),0) INTO v_n
    FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=v_run_id;
    IF v_n<>59 THEN RAISE EXCEPTION 'M2.10 queue account total expected 59; found %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m1.v_m1_17_g2_integrated_consumption
    WHERE module1_run_id=v_run_id
      AND (m1_15_contract_row_hash !~ '^[0-9a-f]{32}$' OR m1_16_contract_row_hash !~ '^[0-9a-f]{32}$');
    IF v_n<>0 THEN RAISE EXCEPTION 'M1.17 source row-hash shape failures: %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m2.application_pricing_structure_latest
    WHERE module1_run_id=v_run_id
      AND (contract_row_hash !~ '^[0-9a-f]{32}$'
           OR source_snapshot_row_hash !~ '^[0-9a-f]{32}$'
           OR source_g2_combined_hash !~ '^[0-9a-f]{32}$'
           OR source_g2_combined_hash <> 'e5ace7f32060ffb191c7bd0f8dd0c863'
           OR (selected_candidate_row_hash IS NOT NULL AND selected_candidate_row_hash !~ '^[0-9a-f]{32}$'));
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.2 latest row-hash shape failures: %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m2.application_pricing_structure_candidate
    WHERE module1_run_id=v_run_id
      AND (row_hash !~ '^[0-9a-f]{32}$'
           OR source_m1_15_contract_row_hash !~ '^[0-9a-f]{32}$'
           OR source_m1_16_contract_row_hash !~ '^[0-9a-f]{32}$'
           OR source_g2_combined_hash !~ '^[0-9a-f]{32}$'
           OR source_g2_combined_hash <> 'e5ace7f32060ffb191c7bd0f8dd0c863');
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.2 candidate row-hash shape failures: %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m2.application_booking_funding_activation_latest
    WHERE module1_run_id=v_run_id
      AND (contract_row_hash !~ '^[0-9a-f]{32}$'
           OR source_snapshot_row_hash !~ '^[0-9a-f]{32}$'
           OR source_g2_combined_hash !~ '^[0-9a-f]{32}$'
           OR source_g2_combined_hash <> 'e5ace7f32060ffb191c7bd0f8dd0c863');
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.4 latest row-hash shape failures: %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m2.application_booking_funding_activation_latest
    WHERE module1_run_id=v_run_id
      AND (real_funds_movement_flag OR external_notice_generation_authorized_flag
           OR external_notice_transmitted_flag OR production_adverse_action_notice_flag);
    IF v_n<>0 THEN RAISE EXCEPTION 'Accepted M2.4 source contains production-action authorization flags: %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m2.application_operational_activation_latest
    WHERE module1_run_id=v_run_id
      AND (contract_row_hash !~ '^[0-9a-f]{32}$'
           OR source_snapshot_row_hash !~ '^[0-9a-f]{32}$');
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.7 latest row-hash shape failures: %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m2.application_portfolio_performance_latest
    WHERE module1_run_id=v_run_id
      AND (contract_row_hash !~ '^[0-9a-f]{32}$'
           OR source_snapshot_row_hash !~ '^[0-9a-f]{32}$'
           OR performance_snapshot_row_hash !~ '^[0-9a-f]{32}$');
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.10 latest row-hash shape failures: %',v_n; END IF;

    SELECT count(*) INTO v_n FROM msbf_m2.portfolio_kpi_snapshot
    WHERE module1_run_id=v_run_id AND row_hash !~ '^[0-9a-f]{32}$';
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.10 KPI row-hash shape failures: %',v_n; END IF;

    SELECT count(*) INTO v_n FROM msbf_m2.servicing_queue_analytics_snapshot
    WHERE module1_run_id=v_run_id AND row_hash !~ '^[0-9a-f]{32}$';
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.10 queue row-hash shape failures: %',v_n; END IF;

    IF (SELECT candidate_set_hash FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=v_run_id)
       IS DISTINCT FROM
       (SELECT md5(string_agg(row_hash,'|' ORDER BY scenario_id,merchant_application_id,template_sequence))
        FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=v_run_id) THEN
        RAISE EXCEPTION 'M2.2 candidate set-hash reconstruction mismatch';
    END IF;

    IF (SELECT pricing_latest_set_hash FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=v_run_id)
       IS DISTINCT FROM
       (SELECT md5(string_agg(contract_row_hash,'|' ORDER BY scenario_id,merchant_application_id))
        FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=v_run_id) THEN
        RAISE EXCEPTION 'M2.2 latest set-hash reconstruction mismatch';
    END IF;

    IF (SELECT activation_latest_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=v_run_id)
       IS DISTINCT FROM
       (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||contract_row_hash,'|' ORDER BY scenario_id,merchant_application_id))
        FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=v_run_id) THEN
        RAISE EXCEPTION 'M2.4 latest set-hash reconstruction mismatch';
    END IF;

    IF (SELECT latest_set_hash FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=v_run_id)
       IS DISTINCT FROM
       (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||contract_row_hash,'|' ORDER BY scenario_id,merchant_application_id))
        FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=v_run_id) THEN
        RAISE EXCEPTION 'M2.7 latest set-hash reconstruction mismatch';
    END IF;

    IF (SELECT latest_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=v_run_id)
       IS DISTINCT FROM
       (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||contract_row_hash,'|' ORDER BY scenario_id,merchant_application_id))
        FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=v_run_id) THEN
        RAISE EXCEPTION 'M2.10 latest set-hash reconstruction mismatch';
    END IF;

    IF (SELECT kpi_snapshot_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=v_run_id)
       IS DISTINCT FROM
       (SELECT md5(string_agg(scope_code||'|'||kpi_code||'|'||row_hash,'|' ORDER BY scope_code,kpi_rank,kpi_code))
        FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=v_run_id) THEN
        RAISE EXCEPTION 'M2.10 KPI set-hash reconstruction mismatch';
    END IF;

    IF (SELECT queue_summary_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=v_run_id)
       IS DISTINCT FROM
       (SELECT md5(string_agg(servicing_queue_code||'|'||row_hash,'|' ORDER BY servicing_queue_code))
        FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=v_run_id) THEN
        RAISE EXCEPTION 'M2.10 queue set-hash reconstruction mismatch';
    END IF;
END;
$m211$;

/* ============================================================================
Section 3 — Exact source relationships and accepted-candidate inventory
============================================================================ */
DO $m211$
DECLARE
    v_run_id bigint;
    v_n bigint;
BEGIN
    SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

    SELECT count(*) INTO v_n
    FROM
    (
      SELECT module1_run_id,merchant_application_id,count(*) AS total_rows,
             count(*) FILTER(WHERE scenario_code='BASELINE') AS baseline_rows,
             count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_rows
      FROM msbf_m1.v_m1_17_g2_integrated_consumption
      WHERE module1_run_id=v_run_id
      GROUP BY module1_run_id,merchant_application_id
    ) paired
    WHERE total_rows<>2 OR baseline_rows<>1 OR stress_rows<>1;
    IF v_n<>0
       OR (SELECT count(*) FROM msbf_m1.v_m1_17_g2_integrated_consumption WHERE module1_run_id=v_run_id AND scenario_code='BASELINE')<>750
       OR (SELECT count(*) FROM msbf_m1.v_m1_17_g2_integrated_consumption WHERE module1_run_id=v_run_id AND scenario_code='RECESSION_ENERGY')<>750
       OR (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.v_m1_17_g2_integrated_consumption WHERE module1_run_id=v_run_id)<>750 THEN
      RAISE EXCEPTION 'Application scenario pairing must equal 750 BASELINE + 750 RECESSION_ENERGY matched applications';
    END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m1.v_m1_17_g2_integrated_consumption g
    FULL JOIN msbf_m2.application_pricing_structure_latest p
      USING(module1_run_id,scenario_id,merchant_application_id)
    FULL JOIN msbf_m2.application_booking_funding_activation_latest a
      USING(module1_run_id,scenario_id,merchant_application_id)
    WHERE coalesce(g.module1_run_id,p.module1_run_id,a.module1_run_id)=v_run_id
      AND (g.module1_run_id IS NULL OR p.module1_run_id IS NULL OR a.module1_run_id IS NULL
           OR g.scenario_code<>p.scenario_code OR g.scenario_code<>a.scenario_code
           OR g.population_id<>p.population_id OR g.population_id<>a.population_id
           OR g.merchant_id<>p.merchant_id OR g.merchant_id<>a.merchant_id
           OR g.as_of_date<>p.as_of_date OR g.as_of_date<>a.as_of_date);
    IF v_n<>0 THEN RAISE EXCEPTION 'M1.17/M2.2/M2.4 one-to-one or identity mismatches: %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m2.application_operational_activation_latest o
    FULL JOIN msbf_m2.application_portfolio_performance_latest m
      USING(module1_run_id,scenario_id,merchant_application_id,merchant_id,synthetic_account_id,synthetic_advance_id)
    WHERE coalesce(o.module1_run_id,m.module1_run_id)=v_run_id
      AND (o.module1_run_id IS NULL OR m.module1_run_id IS NULL OR o.scenario_code<>m.scenario_code);
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.7/M2.10 account one-to-one mismatches: %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m2.application_pricing_structure_latest p
    LEFT JOIN msbf_m2.application_pricing_structure_candidate c
      ON c.module1_run_id=p.module1_run_id AND c.scenario_id=p.scenario_id
     AND c.merchant_application_id=p.merchant_application_id
     AND c.candidate_template_code=p.selected_candidate_template_code
     AND c.row_hash=p.selected_candidate_row_hash
    WHERE p.module1_run_id=v_run_id AND p.selected_candidate_template_code IS NOT NULL
      AND c.candidate_template_code IS NULL;
    IF v_n<>0 THEN RAISE EXCEPTION 'Selected M2.2 candidates absent from accepted inventory: %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m2.application_pricing_structure_latest p
    LEFT JOIN
    (
        SELECT module1_run_id,scenario_id,merchant_application_id,count(*) AS n
        FROM msbf_m2.application_pricing_structure_candidate
        WHERE module1_run_id=v_run_id
        GROUP BY module1_run_id,scenario_id,merchant_application_id
    ) c USING(module1_run_id,scenario_id,merchant_application_id)
    WHERE p.module1_run_id=v_run_id
      AND ((p.structure_available_flag AND coalesce(c.n,0)<>p.candidate_count)
        OR (NOT p.structure_available_flag AND coalesce(c.n,0)<>0));
    IF v_n<>0 THEN RAISE EXCEPTION 'M2.2 candidate population/count mismatches: %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m2.application_pricing_structure_latest
    WHERE module1_run_id=v_run_id AND NOT structure_available_flag
      AND (selected_candidate_template_code IS NOT NULL OR selected_candidate_row_hash IS NOT NULL OR candidate_count<>0);
    IF v_n<>0 THEN RAISE EXCEPTION 'No-structure M2.2 rows incorrectly carry selected candidates: %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM msbf_m2.application_portfolio_performance_latest s
    LEFT JOIN msbf_m2.application_portfolio_performance_latest b
      ON b.module1_run_id=s.module1_run_id AND b.merchant_application_id=s.merchant_application_id
     AND b.scenario_code='BASELINE'
    WHERE s.module1_run_id=v_run_id AND s.scenario_code='RECESSION_ENERGY'
      AND b.merchant_application_id IS NULL;
    IF v_n<>0 THEN RAISE EXCEPTION 'Stress operational accounts lacking baseline matches: %',v_n; END IF;

    SELECT count(*) INTO v_n FROM msbf_m2.application_portfolio_performance_latest
    WHERE module1_run_id=v_run_id AND scenario_code='BASELINE';
    IF v_n<>44 THEN RAISE EXCEPTION 'Expected 44 baseline operational rows; found %',v_n; END IF;
    SELECT count(*) INTO v_n FROM msbf_m2.application_portfolio_performance_latest
    WHERE module1_run_id=v_run_id AND scenario_code='RECESSION_ENERGY';
    IF v_n<>15 THEN RAISE EXCEPTION 'Expected 15 stress operational rows; found %',v_n; END IF;
    SELECT count(DISTINCT merchant_application_id) INTO v_n FROM msbf_m2.application_portfolio_performance_latest
    WHERE module1_run_id=v_run_id;
    IF v_n<>44 THEN RAISE EXCEPTION 'Expected 44 distinct operational applications; found %',v_n; END IF;
END;
$m211$;

/* ============================================================================
Section 4 — Required accepted-source field audit (404 physical fields)
============================================================================ */
DO $m211$
DECLARE
    v_missing bigint;
BEGIN
    WITH required(schema_name,object_name,column_name) AS
    (
        VALUES
        ('msbf_ctl','acceptance_gate_result','finding'),
        ('msbf_ctl','acceptance_gate_result','gate_id'),
        ('msbf_ctl','acceptance_gate_result','observed_value'),
        ('msbf_ctl','acceptance_gate_result','residual_limitation'),
        ('msbf_ctl','acceptance_gate_result','result_status'),
        ('msbf_ctl','acceptance_gate_result','review_version'),
        ('msbf_ctl','acceptance_gate_result','reviewed_at'),
        ('msbf_ctl','acceptance_gate_result','reviewer_role'),
        ('msbf_ctl','acceptance_gate_result','run_id'),
        ('msbf_ctl','acceptance_gate_result','threshold_value'),
        ('msbf_ctl','m1_17_g2_bundle_registry','bundle_code'),
        ('msbf_ctl','m1_17_g2_bundle_registry','bundle_latest_set_hash'),
        ('msbf_ctl','m1_17_g2_bundle_registry','bundle_status'),
        ('msbf_ctl','m1_17_g2_bundle_registry','bundle_version'),
        ('msbf_ctl','m1_17_g2_bundle_registry','combined_g2_hash'),
        ('msbf_ctl','m1_17_g2_bundle_registry','integrated_consumption_rows'),
        ('msbf_ctl','m1_17_g2_bundle_registry','methodology_version'),
        ('msbf_ctl','m1_17_g2_bundle_registry','module1_run_id'),
        ('msbf_ctl','m1_17_g2_bundle_registry','row_hash'),
        ('msbf_ctl','m1_17_g2_bundle_registry','schema_version'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','active_exposure_amount'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','active_reconciled_rows'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','baseline_account_rows'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','certification_rate'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','certified_account_rows'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','certified_exposure_amount'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','closed_stable_rows'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','combined_set_hash'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','contract_code'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','contract_status'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','contract_version'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','controlled_review_rows'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','kpi_snapshot_rows'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','kpi_snapshot_set_hash'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','latest_rows'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','latest_set_hash'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','methodology_version'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','module1_run_id'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','portfolio_account_rows'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','queue_summary_rows'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','queue_summary_set_hash'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','review_hold_exposure_amount'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','row_hash'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','schema_version'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','servicing_burden_units'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','stress_account_rows'),
        ('msbf_ctl','m2_10_portfolio_analytics_contract_registry','unresolved_exception_count'),
        ('msbf_ctl','m2_2_pricing_structure_contract_registry','candidate_rows'),
        ('msbf_ctl','m2_2_pricing_structure_contract_registry','candidate_set_hash'),
        ('msbf_ctl','m2_2_pricing_structure_contract_registry','combined_set_hash'),
        ('msbf_ctl','m2_2_pricing_structure_contract_registry','contract_status'),
        ('msbf_ctl','m2_2_pricing_structure_contract_registry','methodology_version'),
        ('msbf_ctl','m2_2_pricing_structure_contract_registry','module1_run_id'),
        ('msbf_ctl','m2_2_pricing_structure_contract_registry','pricing_contract_code'),
        ('msbf_ctl','m2_2_pricing_structure_contract_registry','pricing_contract_version'),
        ('msbf_ctl','m2_2_pricing_structure_contract_registry','pricing_latest_rows'),
        ('msbf_ctl','m2_2_pricing_structure_contract_registry','pricing_latest_set_hash'),
        ('msbf_ctl','m2_2_pricing_structure_contract_registry','pricing_schema_version'),
        ('msbf_ctl','m2_2_pricing_structure_contract_registry','row_hash'),
        ('msbf_ctl','m2_4_portfolio_activation_contract_registry','activation_latest_rows'),
        ('msbf_ctl','m2_4_portfolio_activation_contract_registry','activation_latest_set_hash'),
        ('msbf_ctl','m2_4_portfolio_activation_contract_registry','combined_set_hash'),
        ('msbf_ctl','m2_4_portfolio_activation_contract_registry','contract_code'),
        ('msbf_ctl','m2_4_portfolio_activation_contract_registry','contract_status'),
        ('msbf_ctl','m2_4_portfolio_activation_contract_registry','contract_version'),
        ('msbf_ctl','m2_4_portfolio_activation_contract_registry','methodology_version'),
        ('msbf_ctl','m2_4_portfolio_activation_contract_registry','module1_run_id'),
        ('msbf_ctl','m2_4_portfolio_activation_contract_registry','row_hash'),
        ('msbf_ctl','m2_4_portfolio_activation_contract_registry','schema_version'),
        ('msbf_ctl','m2_7_operational_activation_contract_registry','combined_set_hash'),
        ('msbf_ctl','m2_7_operational_activation_contract_registry','contract_code'),
        ('msbf_ctl','m2_7_operational_activation_contract_registry','contract_status'),
        ('msbf_ctl','m2_7_operational_activation_contract_registry','contract_version'),
        ('msbf_ctl','m2_7_operational_activation_contract_registry','latest_rows'),
        ('msbf_ctl','m2_7_operational_activation_contract_registry','latest_set_hash'),
        ('msbf_ctl','m2_7_operational_activation_contract_registry','methodology_version'),
        ('msbf_ctl','m2_7_operational_activation_contract_registry','module1_run_id'),
        ('msbf_ctl','m2_7_operational_activation_contract_registry','row_hash'),
        ('msbf_ctl','m2_7_operational_activation_contract_registry','schema_version'),
        ('msbf_ctl','run_registry','as_of_date'),
        ('msbf_ctl','run_registry','code_version'),
        ('msbf_ctl','run_registry','completed_at'),
        ('msbf_ctl','run_registry','created_at'),
        ('msbf_ctl','run_registry','module_code'),
        ('msbf_ctl','run_registry','notes'),
        ('msbf_ctl','run_registry','row_count'),
        ('msbf_ctl','run_registry','run_code'),
        ('msbf_ctl','run_registry','run_id'),
        ('msbf_ctl','run_registry','run_status'),
        ('msbf_ctl','run_registry','run_type'),
        ('msbf_ctl','run_registry','run_version'),
        ('msbf_ctl','run_registry','source_snapshot_hash'),
        ('msbf_ctl','run_registry','started_at'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','accepted_m1_14_acquisition_cost_amount'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','acquisition_contract_evidence_status'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','affordability_status'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','annualized_risk_adjusted_return_rate'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','archetype_code'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','as_of_date'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','assisted_touch_count'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','attribution_confidence_score'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','attribution_confidence_tier'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','attribution_evidence_status'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','average_available_balance_30d'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','avg_daily_eligible_sales_30d'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','capacity_tier'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','channel_type'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','cost_evidence_status'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','data_confidence_tier'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','detailed_conditional_partner_broker_cost_amount'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','detailed_total_acquisition_cost_if_booked'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','direct_attributable_incurred_cost_amount'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','economic_status'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','economic_tier'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','enhanced_total_acquisition_cost_if_booked'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','fraud_risk_tier'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','hard_stop_recommended_flag'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','identified_legacy_overlap_amount'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','incremental_acquisition_cost_beyond_m1_14'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','industry_code'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','integrated_risk_score'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','integrated_risk_tier'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','internally_allocated_acquisition_cost_amount'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','lgd_input_rate'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','m1_15_contract_evidence_status'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','m1_15_contract_row_hash'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','m1_16_contract_row_hash'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','manual_review_recommended_flag'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','merchant_application_id'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','merchant_id'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','merchant_size_tier'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','module1_run_id'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','operating_resilience_score'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','overlap_evidence_status'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','partner_channel_id'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','path_weighted_ead_amount'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','population_id'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','primary_campaign_id'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','primary_source_code'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','processor_continuity_status'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','relationship_stage'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','resilience_tier'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','risk_adjusted_contribution_amount'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','scenario_code'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','scenario_id'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','schedule_adjusted_comparative_expected_loss_amount'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','source_confidence_score'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','synthetic_merchant_risk_proxy'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','total_incurred_pre_application_cost_amount'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','touchpoint_count'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','unmapped_legacy_proxy_amount'),
        ('msbf_m1','v_m1_17_g2_integrated_consumption','verification_disposition'),
        ('msbf_m2','application_booking_funding_activation_latest','activation_collection_horizon_days'),
        ('msbf_m2','application_booking_funding_activation_latest','activation_evidence_status'),
        ('msbf_m2','application_booking_funding_activation_latest','activation_finance_charge_amount'),
        ('msbf_m2','application_booking_funding_activation_latest','activation_implied_daily_collection_amount'),
        ('msbf_m2','application_booking_funding_activation_latest','activation_implied_payoff_days'),
        ('msbf_m2','application_booking_funding_activation_latest','activation_outcome_code'),
        ('msbf_m2','application_booking_funding_activation_latest','activation_outcome_rank'),
        ('msbf_m2','application_booking_funding_activation_latest','activation_payback_multiple'),
        ('msbf_m2','application_booking_funding_activation_latest','activation_reason_codes'),
        ('msbf_m2','application_booking_funding_activation_latest','activation_remittance_rate'),
        ('msbf_m2','application_booking_funding_activation_latest','activation_total_repayment_amount'),
        ('msbf_m2','application_booking_funding_activation_latest','as_of_date'),
        ('msbf_m2','application_booking_funding_activation_latest','booked_amount'),
        ('msbf_m2','application_booking_funding_activation_latest','booking_authorized_flag'),
        ('msbf_m2','application_booking_funding_activation_latest','booking_date'),
        ('msbf_m2','application_booking_funding_activation_latest','booking_eligible_flag'),
        ('msbf_m2','application_booking_funding_activation_latest','contract_code'),
        ('msbf_m2','application_booking_funding_activation_latest','contract_row_hash'),
        ('msbf_m2','application_booking_funding_activation_latest','contract_version'),
        ('msbf_m2','application_booking_funding_activation_latest','created_at'),
        ('msbf_m2','application_booking_funding_activation_latest','external_notice_generation_authorized_flag'),
        ('msbf_m2','application_booking_funding_activation_latest','external_notice_transmitted_flag'),
        ('msbf_m2','application_booking_funding_activation_latest','first_expected_remittance_date'),
        ('msbf_m2','application_booking_funding_activation_latest','funded_amount'),
        ('msbf_m2','application_booking_funding_activation_latest','funding_authorized_flag'),
        ('msbf_m2','application_booking_funding_activation_latest','funding_completed_flag'),
        ('msbf_m2','application_booking_funding_activation_latest','funding_date'),
        ('msbf_m2','application_booking_funding_activation_latest','merchant_application_id'),
        ('msbf_m2','application_booking_funding_activation_latest','merchant_id'),
        ('msbf_m2','application_booking_funding_activation_latest','methodology_version'),
        ('msbf_m2','application_booking_funding_activation_latest','module1_run_id'),
        ('msbf_m2','application_booking_funding_activation_latest','monitoring_start_date'),
        ('msbf_m2','application_booking_funding_activation_latest','notice_control_code'),
        ('msbf_m2','application_booking_funding_activation_latest','operational_review_required_flag'),
        ('msbf_m2','application_booking_funding_activation_latest','policy_configuration_hash'),
        ('msbf_m2','application_booking_funding_activation_latest','population_id'),
        ('msbf_m2','application_booking_funding_activation_latest','portfolio_activated_flag'),
        ('msbf_m2','application_booking_funding_activation_latest','portfolio_activation_date'),
        ('msbf_m2','application_booking_funding_activation_latest','primary_activation_reason_code'),
        ('msbf_m2','application_booking_funding_activation_latest','production_adverse_action_notice_flag'),
        ('msbf_m2','application_booking_funding_activation_latest','real_funds_movement_flag'),
        ('msbf_m2','application_booking_funding_activation_latest','scenario_code'),
        ('msbf_m2','application_booking_funding_activation_latest','scenario_id'),
        ('msbf_m2','application_booking_funding_activation_latest','schema_version'),
        ('msbf_m2','application_booking_funding_activation_latest','snapshot_row_hash'),
        ('msbf_m2','application_booking_funding_activation_latest','source_final_decision_outcome_code'),
        ('msbf_m2','application_booking_funding_activation_latest','source_g2_combined_hash'),
        ('msbf_m2','application_booking_funding_activation_latest','source_m2_2_contract_row_hash'),
        ('msbf_m2','application_booking_funding_activation_latest','source_m2_3_contract_row_hash'),
        ('msbf_m2','application_booking_funding_activation_latest','source_snapshot_row_hash'),
        ('msbf_m2','application_booking_funding_activation_latest','synthetic_account_id'),
        ('msbf_m2','application_booking_funding_activation_latest','synthetic_advance_id'),
        ('msbf_m2','application_booking_funding_activation_latest','synthetic_offer_acceptance_assumed_flag'),
        ('msbf_m2','application_operational_activation_latest','account_setup_snapshot_row_hash'),
        ('msbf_m2','application_operational_activation_latest','account_setup_status_code'),
        ('msbf_m2','application_operational_activation_latest','activation_snapshot_row_hash'),
        ('msbf_m2','application_operational_activation_latest','applied_reassessment_interval_days'),
        ('msbf_m2','application_operational_activation_latest','applied_setup_duration_days'),
        ('msbf_m2','application_operational_activation_latest','applied_temporary_payment_factor'),
        ('msbf_m2','application_operational_activation_latest','blueprint_created_flag'),
        ('msbf_m2','application_operational_activation_latest','contract_code'),
        ('msbf_m2','application_operational_activation_latest','contract_row_hash'),
        ('msbf_m2','application_operational_activation_latest','contract_version'),
        ('msbf_m2','application_operational_activation_latest','created_at'),
        ('msbf_m2','application_operational_activation_latest','merchant_application_id'),
        ('msbf_m2','application_operational_activation_latest','merchant_id'),
        ('msbf_m2','application_operational_activation_latest','methodology_version'),
        ('msbf_m2','application_operational_activation_latest','module1_run_id'),
        ('msbf_m2','application_operational_activation_latest','next_reassessment_date'),
        ('msbf_m2','application_operational_activation_latest','no_setup_required_flag'),
        ('msbf_m2','application_operational_activation_latest','operational_activation_date'),
        ('msbf_m2','application_operational_activation_latest','operational_setup_action_code'),
        ('msbf_m2','application_operational_activation_latest','operational_setup_outcome_code'),
        ('msbf_m2','application_operational_activation_latest','operational_setup_priority_rank'),
        ('msbf_m2','application_operational_activation_latest','operational_setup_queue_code'),
        ('msbf_m2','application_operational_activation_latest','policy_configuration_hash'),
        ('msbf_m2','application_operational_activation_latest','primary_setup_reason_code'),
        ('msbf_m2','application_operational_activation_latest','scenario_code'),
        ('msbf_m2','application_operational_activation_latest','scenario_id'),
        ('msbf_m2','application_operational_activation_latest','schema_version'),
        ('msbf_m2','application_operational_activation_latest','setup_authorized_flag'),
        ('msbf_m2','application_operational_activation_latest','setup_parameter_payload'),
        ('msbf_m2','application_operational_activation_latest','setup_reason_codes'),
        ('msbf_m2','application_operational_activation_latest','setup_review_required_flag'),
        ('msbf_m2','application_operational_activation_latest','source_contract_row_hash'),
        ('msbf_m2','application_operational_activation_latest','source_recommended_action_exposure_amount'),
        ('msbf_m2','application_operational_activation_latest','source_servicing_action_code'),
        ('msbf_m2','application_operational_activation_latest','source_snapshot_row_hash'),
        ('msbf_m2','application_operational_activation_latest','source_strategy_outcome_code'),
        ('msbf_m2','application_operational_activation_latest','synthetic_account_id'),
        ('msbf_m2','application_operational_activation_latest','synthetic_account_setup_id'),
        ('msbf_m2','application_operational_activation_latest','synthetic_advance_id'),
        ('msbf_m2','application_operational_activation_latest','synthetic_operational_case_id'),
        ('msbf_m2','application_operational_activation_latest','synthetic_servicing_plan_id'),
        ('msbf_m2','application_portfolio_performance_latest','certified_exposure_amount'),
        ('msbf_m2','application_portfolio_performance_latest','certified_state_code'),
        ('msbf_m2','application_portfolio_performance_latest','contract_code'),
        ('msbf_m2','application_portfolio_performance_latest','contract_row_hash'),
        ('msbf_m2','application_portfolio_performance_latest','contract_version'),
        ('msbf_m2','application_portfolio_performance_latest','created_at'),
        ('msbf_m2','application_portfolio_performance_latest','exception_case_count'),
        ('msbf_m2','application_portfolio_performance_latest','exception_incident_flag'),
        ('msbf_m2','application_portfolio_performance_latest','exception_resolved_flag'),
        ('msbf_m2','application_portfolio_performance_latest','exposure_retention_rate'),
        ('msbf_m2','application_portfolio_performance_latest','exposure_variance_amount'),
        ('msbf_m2','application_portfolio_performance_latest','gross_collection_rate'),
        ('msbf_m2','application_portfolio_performance_latest','merchant_application_id'),
        ('msbf_m2','application_portfolio_performance_latest','merchant_id'),
        ('msbf_m2','application_portfolio_performance_latest','methodology_version'),
        ('msbf_m2','application_portfolio_performance_latest','module1_run_id'),
        ('msbf_m2','application_portfolio_performance_latest','payment_activity_flag'),
        ('msbf_m2','application_portfolio_performance_latest','payment_event_count'),
        ('msbf_m2','application_portfolio_performance_latest','performance_snapshot_row_hash'),
        ('msbf_m2','application_portfolio_performance_latest','performance_tier_code'),
        ('msbf_m2','application_portfolio_performance_latest','policy_configuration_hash'),
        ('msbf_m2','application_portfolio_performance_latest','portfolio_reason_codes'),
        ('msbf_m2','application_portfolio_performance_latest','primary_portfolio_reason_code'),
        ('msbf_m2','application_portfolio_performance_latest','processed_payment_amount'),
        ('msbf_m2','application_portfolio_performance_latest','reconciliation_variance_amount'),
        ('msbf_m2','application_portfolio_performance_latest','resolved_exception_count'),
        ('msbf_m2','application_portfolio_performance_latest','retry_cure_rate'),
        ('msbf_m2','application_portfolio_performance_latest','retry_event_count'),
        ('msbf_m2','application_portfolio_performance_latest','retry_payment_amount'),
        ('msbf_m2','application_portfolio_performance_latest','return_rate'),
        ('msbf_m2','application_portfolio_performance_latest','returned_event_count'),
        ('msbf_m2','application_portfolio_performance_latest','returned_payment_amount'),
        ('msbf_m2','application_portfolio_performance_latest','scenario_code'),
        ('msbf_m2','application_portfolio_performance_latest','scenario_id'),
        ('msbf_m2','application_portfolio_performance_latest','scheduled_payment_amount'),
        ('msbf_m2','application_portfolio_performance_latest','schema_version'),
        ('msbf_m2','application_portfolio_performance_latest','servicing_burden_units'),
        ('msbf_m2','application_portfolio_performance_latest','servicing_queue_code'),
        ('msbf_m2','application_portfolio_performance_latest','settled_event_count'),
        ('msbf_m2','application_portfolio_performance_latest','source_contract_row_hash'),
        ('msbf_m2','application_portfolio_performance_latest','source_exposure_amount'),
        ('msbf_m2','application_portfolio_performance_latest','source_final_lifecycle_state_code'),
        ('msbf_m2','application_portfolio_performance_latest','source_snapshot_row_hash'),
        ('msbf_m2','application_portfolio_performance_latest','state_certified_flag'),
        ('msbf_m2','application_portfolio_performance_latest','synthetic_account_id'),
        ('msbf_m2','application_portfolio_performance_latest','synthetic_advance_id'),
        ('msbf_m2','application_portfolio_performance_latest','unresolved_exception_count'),
        ('msbf_m2','application_pricing_structure_candidate','acquisition_economics_amount'),
        ('msbf_m2','application_pricing_structure_candidate','amount_to_request_ratio'),
        ('msbf_m2','application_pricing_structure_candidate','annualized_return_rate'),
        ('msbf_m2','application_pricing_structure_candidate','candidate_collection_horizon_days'),
        ('msbf_m2','application_pricing_structure_candidate','candidate_eligible_flag'),
        ('msbf_m2','application_pricing_structure_candidate','candidate_finance_charge_amount'),
        ('msbf_m2','application_pricing_structure_candidate','candidate_funding_amount'),
        ('msbf_m2','application_pricing_structure_candidate','candidate_payback_multiple'),
        ('msbf_m2','application_pricing_structure_candidate','candidate_rank'),
        ('msbf_m2','application_pricing_structure_candidate','candidate_remittance_rate'),
        ('msbf_m2','application_pricing_structure_candidate','candidate_template_code'),
        ('msbf_m2','application_pricing_structure_candidate','candidate_total_repayment_amount'),
        ('msbf_m2','application_pricing_structure_candidate','capacity_alignment_ratio'),
        ('msbf_m2','application_pricing_structure_candidate','counteroffer_foundation_flag'),
        ('msbf_m2','application_pricing_structure_candidate','created_at'),
        ('msbf_m2','application_pricing_structure_candidate','economic_load_rate'),
        ('msbf_m2','application_pricing_structure_candidate','expected_loss_amount'),
        ('msbf_m2','application_pricing_structure_candidate','implied_daily_collection_amount'),
        ('msbf_m2','application_pricing_structure_candidate','implied_payoff_days'),
        ('msbf_m2','application_pricing_structure_candidate','merchant_application_id'),
        ('msbf_m2','application_pricing_structure_candidate','module1_run_id'),
        ('msbf_m2','application_pricing_structure_candidate','policy_configuration_hash'),
        ('msbf_m2','application_pricing_structure_candidate','primary_reason_code'),
        ('msbf_m2','application_pricing_structure_candidate','requested_funding_amount'),
        ('msbf_m2','application_pricing_structure_candidate','resilience_load_rate'),
        ('msbf_m2','application_pricing_structure_candidate','risk_adjusted_contribution_amount'),
        ('msbf_m2','application_pricing_structure_candidate','risk_load_rate'),
        ('msbf_m2','application_pricing_structure_candidate','row_hash'),
        ('msbf_m2','application_pricing_structure_candidate','scenario_code'),
        ('msbf_m2','application_pricing_structure_candidate','scenario_id'),
        ('msbf_m2','application_pricing_structure_candidate','secondary_reason_codes'),
        ('msbf_m2','application_pricing_structure_candidate','selected_foundation_flag'),
        ('msbf_m2','application_pricing_structure_candidate','source_g2_combined_hash'),
        ('msbf_m2','application_pricing_structure_candidate','source_m1_15_contract_row_hash'),
        ('msbf_m2','application_pricing_structure_candidate','source_m1_16_contract_row_hash'),
        ('msbf_m2','application_pricing_structure_candidate','source_m2_1_contract_row_hash'),
        ('msbf_m2','application_pricing_structure_candidate','source_request_contract_row_hash'),
        ('msbf_m2','application_pricing_structure_candidate','source_route_code'),
        ('msbf_m2','application_pricing_structure_candidate','source_route_rank'),
        ('msbf_m2','application_pricing_structure_candidate','stress_load_rate'),
        ('msbf_m2','application_pricing_structure_candidate','template_sequence'),
        ('msbf_m2','application_pricing_structure_latest','as_of_date'),
        ('msbf_m2','application_pricing_structure_latest','candidate_count'),
        ('msbf_m2','application_pricing_structure_latest','contract_code'),
        ('msbf_m2','application_pricing_structure_latest','contract_row_hash'),
        ('msbf_m2','application_pricing_structure_latest','contract_version'),
        ('msbf_m2','application_pricing_structure_latest','counteroffer_foundation_flag'),
        ('msbf_m2','application_pricing_structure_latest','created_at'),
        ('msbf_m2','application_pricing_structure_latest','merchant_application_id'),
        ('msbf_m2','application_pricing_structure_latest','merchant_id'),
        ('msbf_m2','application_pricing_structure_latest','methodology_version'),
        ('msbf_m2','application_pricing_structure_latest','module1_run_id'),
        ('msbf_m2','application_pricing_structure_latest','policy_configuration_hash'),
        ('msbf_m2','application_pricing_structure_latest','population_id'),
        ('msbf_m2','application_pricing_structure_latest','pricing_disposition_code'),
        ('msbf_m2','application_pricing_structure_latest','primary_reason_code'),
        ('msbf_m2','application_pricing_structure_latest','reason_codes'),
        ('msbf_m2','application_pricing_structure_latest','requested_funding_amount'),
        ('msbf_m2','application_pricing_structure_latest','review_required_flag'),
        ('msbf_m2','application_pricing_structure_latest','routing_evidence_status'),
        ('msbf_m2','application_pricing_structure_latest','scenario_code'),
        ('msbf_m2','application_pricing_structure_latest','scenario_id'),
        ('msbf_m2','application_pricing_structure_latest','schema_version'),
        ('msbf_m2','application_pricing_structure_latest','selected_amount_to_request_ratio'),
        ('msbf_m2','application_pricing_structure_latest','selected_candidate_row_hash'),
        ('msbf_m2','application_pricing_structure_latest','selected_candidate_template_code'),
        ('msbf_m2','application_pricing_structure_latest','selected_collection_horizon_days'),
        ('msbf_m2','application_pricing_structure_latest','selected_finance_charge_amount'),
        ('msbf_m2','application_pricing_structure_latest','selected_funding_amount'),
        ('msbf_m2','application_pricing_structure_latest','selected_implied_daily_collection_amount'),
        ('msbf_m2','application_pricing_structure_latest','selected_implied_payoff_days'),
        ('msbf_m2','application_pricing_structure_latest','selected_payback_multiple'),
        ('msbf_m2','application_pricing_structure_latest','selected_remittance_rate'),
        ('msbf_m2','application_pricing_structure_latest','selected_total_repayment_amount'),
        ('msbf_m2','application_pricing_structure_latest','source_g2_combined_hash'),
        ('msbf_m2','application_pricing_structure_latest','source_m2_1_contract_row_hash'),
        ('msbf_m2','application_pricing_structure_latest','source_request_contract_row_hash'),
        ('msbf_m2','application_pricing_structure_latest','source_route_code'),
        ('msbf_m2','application_pricing_structure_latest','source_route_rank'),
        ('msbf_m2','application_pricing_structure_latest','source_snapshot_row_hash'),
        ('msbf_m2','application_pricing_structure_latest','stress_nonimprovement_applied_flag'),
        ('msbf_m2','application_pricing_structure_latest','structure_available_flag'),
        ('msbf_m2','portfolio_kpi_snapshot','applicable_flag'),
        ('msbf_m2','portfolio_kpi_snapshot','created_at'),
        ('msbf_m2','portfolio_kpi_snapshot','denominator_value'),
        ('msbf_m2','portfolio_kpi_snapshot','kpi_code'),
        ('msbf_m2','portfolio_kpi_snapshot','kpi_rank'),
        ('msbf_m2','portfolio_kpi_snapshot','kpi_value_numeric'),
        ('msbf_m2','portfolio_kpi_snapshot','kpi_value_text'),
        ('msbf_m2','portfolio_kpi_snapshot','module1_run_id'),
        ('msbf_m2','portfolio_kpi_snapshot','numerator_value'),
        ('msbf_m2','portfolio_kpi_snapshot','primary_portfolio_reason_code'),
        ('msbf_m2','portfolio_kpi_snapshot','row_hash'),
        ('msbf_m2','portfolio_kpi_snapshot','scenario_code'),
        ('msbf_m2','portfolio_kpi_snapshot','scope_code'),
        ('msbf_m2','portfolio_kpi_snapshot','scope_type'),
        ('msbf_m2','portfolio_kpi_snapshot','source_scope_row_hash'),
        ('msbf_m2','portfolio_kpi_snapshot','unit_code'),
        ('msbf_m2','servicing_queue_analytics_snapshot','account_count'),
        ('msbf_m2','servicing_queue_analytics_snapshot','certified_exposure_amount'),
        ('msbf_m2','servicing_queue_analytics_snapshot','created_at'),
        ('msbf_m2','servicing_queue_analytics_snapshot','exception_case_count'),
        ('msbf_m2','servicing_queue_analytics_snapshot','maximum_tier_rank'),
        ('msbf_m2','servicing_queue_analytics_snapshot','module1_run_id'),
        ('msbf_m2','servicing_queue_analytics_snapshot','payment_event_count'),
        ('msbf_m2','servicing_queue_analytics_snapshot','resolved_exception_count'),
        ('msbf_m2','servicing_queue_analytics_snapshot','row_hash'),
        ('msbf_m2','servicing_queue_analytics_snapshot','scenario_count'),
        ('msbf_m2','servicing_queue_analytics_snapshot','servicing_burden_units'),
        ('msbf_m2','servicing_queue_analytics_snapshot','servicing_queue_code'),
        ('msbf_m2','servicing_queue_analytics_snapshot','unresolved_exception_count')
    )
    SELECT count(*) INTO v_missing
    FROM required r
    LEFT JOIN pg_attribute a
      ON a.attrelid=to_regclass(r.schema_name||'.'||r.object_name)
     AND a.attname=r.column_name AND a.attnum>0 AND NOT a.attisdropped
    WHERE a.attname IS NULL;
    IF v_missing<>0 THEN
        RAISE EXCEPTION 'Required accepted-source field audit found % missing fields',v_missing;
    END IF;
END;
$m211$;

/* ============================================================================
Section 5 — Frozen 1,014-field M2.11 physical shape and definition audit
============================================================================ */
DO $m211$
DECLARE
    v_run_id bigint;
    v_bad bigint;
BEGIN
    SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

    WITH expected(schema_name,table_name,column_name,expected_type,expected_not_null) AS
    (
        VALUES
        ('msbf_ctl','m2_11_policy_profile','policy_profile_id','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','module1_run_id','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','policy_code','text',TRUE),
        ('msbf_ctl','m2_11_policy_profile','policy_version','integer',TRUE),
        ('msbf_ctl','m2_11_policy_profile','methodology_version','text',TRUE),
        ('msbf_ctl','m2_11_policy_profile','contract_code','text',TRUE),
        ('msbf_ctl','m2_11_policy_profile','contract_version','integer',TRUE),
        ('msbf_ctl','m2_11_policy_profile','schema_version','text',TRUE),
        ('msbf_ctl','m2_11_policy_profile','acceptance_gate_id','text',TRUE),
        ('msbf_ctl','m2_11_policy_profile','strategy_profile_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','objective_definition_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','constraint_definition_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','reason_definition_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','reporting_scope_count','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','application_source_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','candidate_source_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','account_source_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','kpi_source_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','queue_source_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','candidate_evaluation_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','application_simulation_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','account_simulation_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','strategy_summary_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','frontier_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','comparison_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','latest_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','archive_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','registry_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','canonical_entities','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','positive_controls','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','negative_controls','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','generation_evidence_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','acceptance_evidence_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','detail_result_sets','bigint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','score_precision_scale','smallint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','normalized_precision_scale','smallint',TRUE),
        ('msbf_ctl','m2_11_policy_profile','candidate_score_tolerance','numeric(22,12)',TRUE),
        ('msbf_ctl','m2_11_policy_profile','synthetic_data_only_flag','boolean',TRUE),
        ('msbf_ctl','m2_11_policy_profile','non_production_boundary_flag','boolean',TRUE),
        ('msbf_ctl','m2_11_policy_profile','no_external_system_update_flag','boolean',TRUE),
        ('msbf_ctl','m2_11_policy_profile','no_merchant_contact_flag','boolean',TRUE),
        ('msbf_ctl','m2_11_policy_profile','no_real_funds_movement_flag','boolean',TRUE),
        ('msbf_ctl','m2_11_policy_profile','no_production_decisioning_flag','boolean',TRUE),
        ('msbf_ctl','m2_11_policy_profile','servicing_burden_coverage_code','text',TRUE),
        ('msbf_ctl','m2_11_policy_profile','new_access_servicing_burden_estimated_flag','boolean',TRUE),
        ('msbf_ctl','m2_11_policy_profile','configuration_payload','jsonb',TRUE),
        ('msbf_ctl','m2_11_policy_profile','configuration_hash','text',TRUE),
        ('msbf_ctl','m2_11_policy_profile','policy_status','text',TRUE),
        ('msbf_ctl','m2_11_policy_profile','created_at','timestamptz',TRUE),
        ('msbf_ctl','m2_11_policy_profile','updated_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_profile','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_profile','strategy_profile_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_profile','strategy_sequence','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_profile','strategy_name','text',TRUE),
        ('msbf_m2','portfolio_strategy_profile','selection_mode','text',TRUE),
        ('msbf_m2','portfolio_strategy_profile','selected_exposure_direction','text',TRUE),
        ('msbf_m2','portfolio_strategy_profile','access_rate_weight','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_profile','selected_exposure_weight','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_profile','finance_charge_weight','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_profile','expected_loss_density_weight','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_profile','risk_adjusted_contribution_weight','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_profile','annualized_return_weight','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_profile','servicing_burden_weight','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_profile','payment_burden_weight','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_profile','candidate_domain_weight_total','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_profile','scope_domain_weight_total','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_profile','candidate_scoring_applicable_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_profile','scope_scoring_applicable_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_profile','evidence_handling_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_profile','score_precision_scale','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_profile','active_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_profile','description','text',TRUE),
        ('msbf_m2','portfolio_strategy_profile','row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_profile','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','objective_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','objective_sequence','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','objective_name','text',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','candidate_formula_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','scope_formula_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','default_direction_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','normalization_method_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','missing_value_policy_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','scoring_domain_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','scope_aggregation_method_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','unit_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','pareto_inclusion_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','equality_tolerance','numeric(28,10)',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','numeric_scale','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','description','text',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_objective_definition','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_constraint_definition','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_constraint_definition','constraint_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_constraint_definition','constraint_sequence','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_constraint_definition','constraint_name','text',TRUE),
        ('msbf_m2','portfolio_strategy_constraint_definition','constraint_family_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_constraint_definition','applicability_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_constraint_definition','severity_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_constraint_definition','evaluation_rule_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_constraint_definition','blocking_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_constraint_definition','description','text',TRUE),
        ('msbf_m2','portfolio_strategy_constraint_definition','row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_constraint_definition','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','reason_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','reason_sequence','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','reason_family','text',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','severity_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','severity_rank','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','applicability_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','description','text',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','production_action_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','external_system_update_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','merchant_contact_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','production_adverse_action_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_reason_definition','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','scenario_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','scenario_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','merchant_application_id','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','population_id','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','merchant_id','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','as_of_date','date',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','industry_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','merchant_size_tier','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','relationship_stage','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','partner_channel_id','text',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','channel_type','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','source_confidence_score','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','data_confidence_tier','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','verification_disposition','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','fraud_risk_tier','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','processor_continuity_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','avg_daily_eligible_sales_30d','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','average_available_balance_30d','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','capacity_tier','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','affordability_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','archetype_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','operating_resilience_score','numeric(12,6)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','resilience_tier','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','integrated_risk_score','numeric(12,6)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','synthetic_merchant_risk_proxy','numeric(12,8)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','integrated_risk_tier','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','path_weighted_ead_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','lgd_input_rate','numeric(12,8)',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','schedule_adjusted_comparative_expected_loss_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','risk_adjusted_contribution_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','annualized_risk_adjusted_return_rate','numeric(12,8)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','economic_tier','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','economic_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','hard_stop_recommended_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','manual_review_recommended_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m1_15_contract_evidence_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m1_15_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','primary_source_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','primary_campaign_id','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','attribution_confidence_score','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','attribution_confidence_tier','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','touchpoint_count','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','assisted_touch_count','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','attribution_evidence_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','direct_attributable_incurred_cost_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','internally_allocated_acquisition_cost_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','total_incurred_pre_application_cost_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','detailed_conditional_partner_broker_cost_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','detailed_total_acquisition_cost_if_booked','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','accepted_m1_14_acquisition_cost_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','identified_legacy_overlap_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','unmapped_legacy_proxy_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','incremental_acquisition_cost_beyond_m1_14','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','enhanced_total_acquisition_cost_if_booked','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','cost_evidence_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','overlap_evidence_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','acquisition_contract_evidence_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m1_16_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','source_route_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','source_route_rank','integer',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','pricing_disposition_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','structure_available_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','review_required_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','selected_candidate_template_code','text',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','selected_candidate_row_hash','text',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','requested_funding_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','selected_funding_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','selected_remittance_rate','numeric(9,6)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','selected_payback_multiple','numeric(9,6)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','selected_collection_horizon_days','integer',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','selected_total_repayment_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','selected_finance_charge_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','selected_implied_daily_collection_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','selected_implied_payoff_days','numeric(18,4)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','selected_amount_to_request_ratio','numeric(12,8)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','candidate_count','integer',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','counteroffer_foundation_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','stress_nonimprovement_applied_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','primary_reason_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','reason_codes','jsonb',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','routing_evidence_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_source_m2_1_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_source_request_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_source_g2_combined_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_policy_configuration_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_source_snapshot_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_source_created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','source_final_decision_outcome_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','activation_outcome_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','activation_outcome_rank','integer',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','booking_eligible_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','booking_authorized_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','funding_authorized_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','funding_completed_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','portfolio_activated_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','operational_review_required_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','synthetic_offer_acceptance_assumed_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','real_funds_movement_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','external_notice_generation_authorized_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','external_notice_transmitted_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','production_adverse_action_notice_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','synthetic_account_id','text',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','synthetic_advance_id','text',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','booked_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','funded_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','activation_remittance_rate','numeric(9,6)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','activation_payback_multiple','numeric(9,6)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','activation_collection_horizon_days','integer',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','activation_total_repayment_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','activation_finance_charge_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','activation_implied_daily_collection_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','activation_implied_payoff_days','numeric(18,4)',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','booking_date','date',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','funding_date','date',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','portfolio_activation_date','date',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','first_expected_remittance_date','date',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','monitoring_start_date','date',FALSE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','activation_evidence_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','notice_control_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','primary_activation_reason_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','activation_reason_codes','jsonb',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_source_m2_3_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_source_m2_2_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_source_g2_combined_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_source_snapshot_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_activation_snapshot_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_policy_configuration_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_source_created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m1_17_bundle_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m1_17_bundle_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m1_17_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m1_17_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m1_17_bundle_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m1_17_combined_g2_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m1_17_registry_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_contract_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_combined_set_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_2_registry_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_contract_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_combined_set_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','m2_4_registry_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','source_join_status_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_application_source_snapshot','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','scenario_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','scenario_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','merchant_application_id','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','candidate_template_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','template_sequence','integer',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','source_route_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','source_route_rank','integer',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','requested_funding_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','candidate_funding_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','candidate_remittance_rate','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','candidate_payback_multiple','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','candidate_collection_horizon_days','integer',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','candidate_total_repayment_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','candidate_finance_charge_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','implied_daily_collection_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','implied_payoff_days','numeric(18,4)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','amount_to_request_ratio','numeric(12,8)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','capacity_alignment_ratio','numeric(12,8)',FALSE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','risk_load_rate','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','resilience_load_rate','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','economic_load_rate','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','stress_load_rate','numeric(9,6)',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','acquisition_economics_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','expected_loss_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','risk_adjusted_contribution_amount','numeric(18,2)',FALSE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','annualized_return_rate','numeric(12,8)',FALSE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','counteroffer_foundation_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','candidate_eligible_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','selected_foundation_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','candidate_rank','integer',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','primary_reason_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','secondary_reason_codes','jsonb',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','source_m2_1_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','source_request_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','source_m1_15_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','source_m1_16_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','source_g2_combined_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','policy_configuration_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','source_candidate_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','source_candidate_created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','m2_2_contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','m2_2_contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','m2_2_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','m2_2_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','m2_2_contract_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','m2_2_combined_set_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','m2_2_registry_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','scenario_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','scenario_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','merchant_application_id','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','merchant_id','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','synthetic_account_id','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','synthetic_advance_id','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','source_strategy_outcome_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','source_servicing_action_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','source_recommended_action_exposure_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','operational_setup_outcome_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','operational_setup_action_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','operational_setup_priority_rank','integer',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','operational_setup_queue_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','account_setup_status_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','setup_authorized_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','blueprint_created_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','setup_review_required_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','no_setup_required_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','synthetic_operational_case_id','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','synthetic_account_setup_id','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','synthetic_servicing_plan_id','text',FALSE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','operational_activation_date','date',FALSE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','next_reassessment_date','date',FALSE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','applied_temporary_payment_factor','numeric(9,6)',FALSE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','applied_setup_duration_days','integer',FALSE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','applied_reassessment_interval_days','integer',FALSE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','primary_setup_reason_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','setup_reason_codes','jsonb',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','setup_parameter_payload','jsonb',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_source_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_source_snapshot_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_activation_snapshot_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_account_setup_snapshot_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_policy_configuration_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_source_created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','source_final_lifecycle_state_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','certified_state_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','state_certified_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','performance_tier_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','servicing_queue_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','payment_activity_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','exception_incident_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','exception_resolved_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','payment_event_count','integer',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','settled_event_count','integer',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','returned_event_count','integer',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','retry_event_count','integer',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','exception_case_count','integer',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','resolved_exception_count','integer',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','unresolved_exception_count','integer',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','source_exposure_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','certified_exposure_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','scheduled_payment_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','processed_payment_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','returned_payment_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','retry_payment_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','reconciliation_variance_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','exposure_variance_amount','numeric(18,2)',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','gross_collection_rate','numeric(18,6)',FALSE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','return_rate','numeric(18,6)',FALSE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','retry_cure_rate','numeric(18,6)',FALSE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','exposure_retention_rate','numeric(18,6)',FALSE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','servicing_burden_units','numeric(12,6)',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','primary_portfolio_reason_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','portfolio_reason_codes','jsonb',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_source_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_source_snapshot_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_performance_snapshot_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_policy_configuration_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_source_created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','operational_account_present_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','source_account_posture_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','source_account_posture_rank','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','source_contract_identity_valid_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','source_lineage_intact_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','certification_blocked_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_contract_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_combined_set_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_7_registry_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_contract_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_combined_set_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','m2_10_registry_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','source_join_status_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_account_source_snapshot','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','scope_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','scope_type','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','scenario_code','text',FALSE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','kpi_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','kpi_rank','integer',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','unit_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','applicable_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','kpi_value_numeric','numeric(28,10)',FALSE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','kpi_value_text','text',FALSE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','numerator_value','numeric(28,10)',FALSE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','denominator_value','numeric(28,10)',FALSE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','primary_portfolio_reason_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','source_scope_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','source_kpi_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','source_kpi_created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','m2_10_contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','m2_10_contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','m2_10_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','m2_10_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','m2_10_contract_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','m2_10_combined_set_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','m2_10_registry_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','servicing_queue_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','account_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','scenario_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','certified_exposure_amount','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','payment_event_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','exception_case_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','resolved_exception_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','unresolved_exception_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','servicing_burden_units','numeric(24,6)',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','maximum_tier_rank','integer',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','source_queue_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','source_queue_created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','m2_10_contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','m2_10_contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','m2_10_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','m2_10_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','m2_10_contract_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','m2_10_combined_set_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','m2_10_registry_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot','created_at','timestamptz',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','module1_run_id','bigint',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','scenario_id','bigint',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','scenario_code','text',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','merchant_application_id','text',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','candidate_template_code','text',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','strategy_profile_code','text',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','candidate_source_snapshot_row_hash','text',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','source_candidate_row_hash','text',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','candidate_rank','integer',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','candidate_eligible_flag','boolean',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','source_route_code','text',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','source_route_rank','integer',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','source_evidence_status_code','text',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','source_integrity_pass_flag','boolean',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','accepted_candidate_flag','boolean',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','hard_constraint_violation_count','integer',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','hard_constraint_codes','jsonb',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','feasibility_class','text',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','feasibility_rank','smallint',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','candidate_scoring_applicable_flag','boolean',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','objective_evidence_complete_flag','boolean',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','access_rate_raw_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','access_rate_minimum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','access_rate_maximum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','access_rate_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','access_rate_strategy_weight','numeric(9,6)',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','access_rate_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','selected_exposure_amount_raw_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','selected_exposure_amount_minimum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','selected_exposure_amount_maximum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','selected_exposure_amount_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','selected_exposure_amount_strategy_weight','numeric(9,6)',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','selected_exposure_amount_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','finance_charge_amount_raw_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','finance_charge_amount_minimum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','finance_charge_amount_maximum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','finance_charge_amount_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','finance_charge_amount_strategy_weight','numeric(9,6)',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','finance_charge_amount_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','expected_loss_density_raw_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','expected_loss_density_minimum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','expected_loss_density_maximum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','expected_loss_density_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','expected_loss_density_strategy_weight','numeric(9,6)',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','expected_loss_density_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','risk_adjusted_contribution_raw_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','risk_adjusted_contribution_minimum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','risk_adjusted_contribution_maximum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','risk_adjusted_contribution_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','risk_adjusted_contribution_strategy_weight','numeric(9,6)',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','risk_adjusted_contribution_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','annualized_risk_adjusted_return_raw_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','annualized_risk_adjusted_return_minimum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','annualized_risk_adjusted_return_maximum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','annualized_risk_adjusted_return_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','annualized_risk_adjusted_return_strategy_weight','numeric(9,6)',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','annualized_risk_adjusted_return_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','payment_burden_rate_raw_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','payment_burden_rate_minimum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','payment_burden_rate_maximum_value','numeric(28,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','payment_burden_rate_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','payment_burden_rate_strategy_weight','numeric(9,6)',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','payment_burden_rate_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','servicing_burden_applicability_code','text',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','applicable_candidate_weight_total','numeric(9,6)',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','objective_score','numeric(22,12)',FALSE),
        ('msbf_m2','application_strategy_candidate_evaluation','objective_score_tie_flag','boolean',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','candidate_selected_flag','boolean',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','primary_reason_code','text',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','reason_codes','jsonb',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','row_hash','text',TRUE),
        ('msbf_m2','application_strategy_candidate_evaluation','created_at','timestamptz',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','module1_run_id','bigint',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','scenario_id','bigint',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','scenario_code','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','merchant_application_id','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','strategy_profile_code','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','application_source_snapshot_row_hash','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','selection_mode','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','source_pricing_disposition_code','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','source_structure_available_flag','boolean',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','source_review_required_flag','boolean',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','source_activation_outcome_code','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','strategy_outcome_code','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','strategy_outcome_rank','smallint',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','feasibility_class','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','feasibility_rank','smallint',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','access_selected_flag','boolean',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','controlled_review_flag','boolean',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','implicit_no_access_selected_flag','boolean',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','policy_decline_preserved_flag','boolean',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','insufficient_evidence_preserved_flag','boolean',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','source_integrity_blocked_flag','boolean',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_candidate_template_code','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_candidate_source_row_hash','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_candidate_evaluation_row_hash','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','selection_objective_score','numeric(22,12)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','hard_constraint_violation_count','integer',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','hard_constraint_codes','jsonb',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','strategy_evidence_status','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','operational_account_present_flag','boolean',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','account_certification_constraint_applicability','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','constraint_unresolved_exception_count','integer',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','source_unresolved_exception_count','integer',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','source_certified_state_code','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','source_servicing_queue_code','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','source_certified_exposure_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','certification_blocked_flag','boolean',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','source_lineage_intact_flag','boolean',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','associated_account_servicing_simulation_row_hash','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','associated_servicing_treatment_code','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','associated_servicing_burden_units','numeric(12,6)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','requested_funding_amount','numeric(18,2)',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_exposure_amount','numeric(18,2)',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_remittance_rate','numeric(9,6)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_payback_multiple','numeric(9,6)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_collection_horizon_days','integer',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_total_repayment_amount','numeric(18,2)',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_finance_charge_amount','numeric(18,2)',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_implied_daily_collection_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_implied_payoff_days','numeric(18,4)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_amount_to_request_ratio','numeric(12,8)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_acquisition_economics_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_expected_loss_amount','numeric(18,2)',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_expected_loss_density','numeric(28,10)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_risk_adjusted_contribution','numeric(18,2)',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_annualized_risk_adjusted_return','numeric(12,8)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','selected_payment_burden_rate','numeric(9,6)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_pricing_disposition_code','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_structure_available_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_review_required_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_selected_candidate_template_code','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_selected_candidate_row_hash','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_requested_funding_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_selected_funding_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_selected_remittance_rate','numeric(9,6)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_selected_payback_multiple','numeric(9,6)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_selected_collection_horizon_days','integer',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_selected_total_repayment_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_selected_finance_charge_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_selected_implied_daily_collection_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_selected_implied_payoff_days','numeric(18,4)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_selected_amount_to_request_ratio','numeric(12,8)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_candidate_count','integer',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_counteroffer_foundation_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_stress_nonimprovement_applied_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_routing_evidence_status','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_source_final_decision_outcome_code','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_activation_outcome_code','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_activation_outcome_rank','integer',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_booking_eligible_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_booking_authorized_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_funding_authorized_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_funding_completed_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_portfolio_activated_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_operational_review_required_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_synthetic_offer_acceptance_assumed_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_synthetic_account_id','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_synthetic_advance_id','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_booked_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_funded_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_activation_remittance_rate','numeric(9,6)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_activation_payback_multiple','numeric(9,6)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_activation_collection_horizon_days','integer',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_activation_total_repayment_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_activation_finance_charge_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_activation_implied_daily_collection_amount','numeric(18,2)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_activation_implied_payoff_days','numeric(18,4)',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_activation_evidence_status','text',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','replay_applicability_code','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','baseline_replay_match_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','source_risk_improvement_violation_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','source_return_improvement_violation_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','strategy_access_improvement_violation_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','strategy_feasibility_improvement_violation_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','comparable_payment_burden_improvement_violation_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','comparable_servicing_burden_improvement_violation_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','strategy_restriction_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','absolute_workload_reduction_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','stress_nonimprovement_pass_flag','boolean',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','portfolio_adverse_selected_flag','boolean',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','portfolio_adversity_order','smallint',FALSE),
        ('msbf_m2','application_portfolio_strategy_simulation','primary_reason_code','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','reason_codes','jsonb',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','row_hash','text',TRUE),
        ('msbf_m2','application_portfolio_strategy_simulation','created_at','timestamptz',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','module1_run_id','bigint',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','scenario_id','bigint',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','scenario_code','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','merchant_application_id','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','synthetic_account_id','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','strategy_profile_code','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','account_source_snapshot_row_hash','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','source_account_posture_code','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','source_account_posture_rank','smallint',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','source_operational_setup_outcome_code','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','source_operational_setup_action_code','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','source_operational_setup_queue_code','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','source_operational_activation_date','date',FALSE),
        ('msbf_m2','account_servicing_strategy_simulation','source_next_reassessment_date','date',FALSE),
        ('msbf_m2','account_servicing_strategy_simulation','source_payment_factor','numeric(9,6)',FALSE),
        ('msbf_m2','account_servicing_strategy_simulation','source_setup_duration_days','integer',FALSE),
        ('msbf_m2','account_servicing_strategy_simulation','source_reassessment_interval_days','integer',FALSE),
        ('msbf_m2','account_servicing_strategy_simulation','source_certified_state_code','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','source_servicing_queue_code','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','source_certified_exposure_amount','numeric(18,2)',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','source_servicing_burden_units','numeric(12,6)',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','servicing_treatment_code','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','treatment_applicable_flag','boolean',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','simulated_action_date','date',FALSE),
        ('msbf_m2','account_servicing_strategy_simulation','simulated_payment_factor','numeric(9,6)',FALSE),
        ('msbf_m2','account_servicing_strategy_simulation','simulated_exposure_amount','numeric(18,2)',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','incremental_servicing_burden_units','numeric(12,6)',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','strategy_servicing_burden_units','numeric(12,6)',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','risk_benefit_claimed_flag','boolean',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','return_benefit_claimed_flag','boolean',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','contribution_benefit_claimed_flag','boolean',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','payment_performance_benefit_claimed_flag','boolean',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','source_replay_match_flag','boolean',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','strategy_evidence_status','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','portfolio_adverse_selected_flag','boolean',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','portfolio_adversity_order','smallint',FALSE),
        ('msbf_m2','account_servicing_strategy_simulation','primary_reason_code','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','reason_codes','jsonb',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','row_hash','text',TRUE),
        ('msbf_m2','account_servicing_strategy_simulation','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_summary','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','strategy_profile_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_summary','reporting_scope_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_summary','application_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','access_selected_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','controlled_review_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','strategy_restriction_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','no_feasible_candidate_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','insufficient_evidence_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','policy_decline_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','blocked_source_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','hard_constraint_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','complete_evidence_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','partial_evidence_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','blocked_evidence_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','source_risk_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','source_return_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','strategy_access_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','strategy_feasibility_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','comparable_payment_burden_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','comparable_servicing_burden_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','stress_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','stress_strategy_restriction_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','absolute_workload_reduction_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','servicing_account_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','servicing_distinct_application_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_summary','stress_nonimprovement_pass_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_summary','access_rate','numeric(18,10)',TRUE),
        ('msbf_m2','portfolio_strategy_summary','selected_exposure_amount','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_summary','finance_charge_amount','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_summary','expected_loss_amount','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_summary','expected_loss_density','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','risk_adjusted_contribution','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_summary','annualized_risk_adjusted_return','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','payment_burden_rate','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','servicing_burden_units','numeric(24,6)',TRUE),
        ('msbf_m2','portfolio_strategy_summary','servicing_burden_coverage_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_summary','new_access_servicing_burden_estimated_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_summary','strategy_evidence_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_summary','frontier_metrics_complete_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_summary','access_rate_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','access_rate_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','selected_exposure_amount_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','selected_exposure_amount_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','finance_charge_amount_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','finance_charge_amount_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','expected_loss_density_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','expected_loss_density_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','risk_adjusted_contribution_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','risk_adjusted_contribution_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','annualized_risk_adjusted_return_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','annualized_risk_adjusted_return_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','servicing_burden_units_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','servicing_burden_units_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','payment_burden_rate_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','payment_burden_rate_weighted_contribution','numeric(22,12)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','scope_strategy_score','numeric(22,12)',FALSE),
        ('msbf_m2','portfolio_strategy_summary','application_simulation_set_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_summary','account_simulation_set_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_summary','row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_summary','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','strategy_profile_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','reporting_scope_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','strategy_summary_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','frontier_eligible_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','frontier_ineligibility_code','text',FALSE),
        ('msbf_m2','portfolio_strategy_frontier','dominated_by_count','integer',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','dominates_count','integer',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','non_dominated_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','frontier_rank','integer',FALSE),
        ('msbf_m2','portfolio_strategy_frontier','evidence_rank','smallint',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','governance_balance_score','numeric(22,12)',FALSE),
        ('msbf_m2','portfolio_strategy_frontier','governance_review_priority_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','governance_review_priority_rank','smallint',FALSE),
        ('msbf_m2','portfolio_strategy_frontier','primary_governance_review_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','governance_access_rate_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_frontier','governance_finance_charge_amount_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_frontier','governance_expected_loss_density_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_frontier','governance_risk_adjusted_contribution_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_frontier','governance_annualized_risk_adjusted_return_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_frontier','governance_servicing_burden_units_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_frontier','governance_payment_burden_rate_normalized_value','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_frontier','primary_reason_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','reason_codes','jsonb',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_frontier','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','reporting_scope_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_strategy_profile_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_strategy_profile_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_summary_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_summary_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_frontier_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_frontier_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_access_rate','numeric(18,10)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_access_rate','numeric(18,10)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','access_rate_delta','numeric(18,10)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_selected_exposure_amount','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_selected_exposure_amount','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','selected_exposure_amount_delta','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_finance_charge_amount','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_finance_charge_amount','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','finance_charge_amount_delta','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_expected_loss_density','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_expected_loss_density','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_comparison','expected_loss_density_delta','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_risk_adjusted_contribution','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_risk_adjusted_contribution','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','risk_adjusted_contribution_delta','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_annualized_risk_adjusted_return','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_annualized_risk_adjusted_return','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_comparison','annualized_risk_adjusted_return_delta','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_servicing_burden_units','numeric(24,6)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_servicing_burden_units','numeric(24,6)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','servicing_burden_units_delta','numeric(24,6)',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_payment_burden_rate','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_payment_burden_rate','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_comparison','payment_burden_rate_delta','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_frontier_rank','integer',FALSE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_frontier_rank','integer',FALSE),
        ('msbf_m2','portfolio_strategy_comparison','baseline_frontier_eligible_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_frontier_eligible_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_governance_review_priority_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_stress_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_stress_nonimprovement_pass_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_stress_strategy_restriction_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_absolute_workload_reduction_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','challenger_hard_constraint_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','servicing_burden_coverage_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','new_access_servicing_burden_estimated_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_comparison','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','strategy_profile_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','reporting_scope_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m1_17_contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m1_17_contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m1_17_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m1_17_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m1_17_combined_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_2_contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_2_contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_2_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_2_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_2_combined_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_4_contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_4_contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_4_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_4_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_4_combined_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_7_contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_7_contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_7_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_7_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_7_combined_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_10_contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_10_contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_10_schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_10_methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_m2_10_combined_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','application_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','access_selected_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','controlled_review_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','strategy_restriction_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','no_feasible_candidate_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','insufficient_evidence_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','policy_decline_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','blocked_source_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','servicing_account_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','servicing_distinct_application_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','hard_constraint_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_risk_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','source_return_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','strategy_access_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','strategy_feasibility_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','comparable_payment_burden_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','comparable_servicing_burden_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','stress_improvement_violation_count','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','stress_strategy_restriction_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','absolute_workload_reduction_rows','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','access_rate','numeric(18,10)',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','selected_exposure_amount','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','finance_charge_amount','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','expected_loss_amount','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','expected_loss_density','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_simulation_latest','risk_adjusted_contribution','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','annualized_risk_adjusted_return','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_simulation_latest','servicing_burden_units','numeric(24,6)',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','payment_burden_rate','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_simulation_latest','scope_strategy_score','numeric(22,12)',FALSE),
        ('msbf_m2','portfolio_strategy_simulation_latest','governance_balance_score','numeric(22,12)',FALSE),
        ('msbf_m2','portfolio_strategy_simulation_latest','strategy_evidence_status','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','stress_nonimprovement_pass_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','frontier_eligible_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','non_dominated_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','frontier_rank','integer',FALSE),
        ('msbf_m2','portfolio_strategy_simulation_latest','governance_review_priority_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','primary_governance_review_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','servicing_burden_coverage_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','new_access_servicing_burden_estimated_flag','boolean',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','baseline_access_rate_delta','numeric(18,10)',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','baseline_selected_exposure_amount_delta','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','baseline_finance_charge_amount_delta','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','baseline_expected_loss_density_delta','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_simulation_latest','baseline_risk_adjusted_contribution_delta','numeric(24,2)',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','baseline_annualized_risk_adjusted_return_delta','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_simulation_latest','baseline_servicing_burden_units_delta','numeric(24,6)',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','baseline_payment_burden_rate_delta','numeric(18,10)',FALSE),
        ('msbf_m2','portfolio_strategy_simulation_latest','primary_reason_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','reason_codes','jsonb',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','strategy_summary_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','frontier_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','comparison_row_hash','text',FALSE),
        ('msbf_m2','portfolio_strategy_simulation_latest','contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_latest','created_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','archive_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','module1_run_id','bigint',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','contract_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','contract_version','integer',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','schema_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','methodology_version','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','strategy_profile_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','reporting_scope_code','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','contract_payload','jsonb',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','contract_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','archive_row_hash','text',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','archived_at','timestamptz',TRUE),
        ('msbf_m2','portfolio_strategy_simulation_archive','created_at','timestamptz',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','registry_id','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','module1_run_id','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','contract_code','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','contract_version','integer',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','schema_version','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','methodology_version','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','acceptance_gate_id','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','policy_configuration_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m1_17_contract_code','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m1_17_contract_version','integer',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m1_17_schema_version','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m1_17_methodology_version','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m1_17_acceptance_gate_id','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m1_17_combined_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m1_17_registry_row_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_2_contract_code','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_2_contract_version','integer',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_2_schema_version','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_2_methodology_version','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_2_acceptance_gate_id','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_2_combined_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_2_registry_row_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_4_contract_code','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_4_contract_version','integer',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_4_schema_version','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_4_methodology_version','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_4_acceptance_gate_id','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_4_combined_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_4_registry_row_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_7_contract_code','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_7_contract_version','integer',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_7_schema_version','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_7_methodology_version','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_7_acceptance_gate_id','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_7_combined_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_7_registry_row_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_10_contract_code','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_10_contract_version','integer',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_10_schema_version','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_10_methodology_version','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_10_acceptance_gate_id','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_10_combined_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','source_m2_10_registry_row_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','policy_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','strategy_profile_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','objective_definition_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','constraint_definition_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','reason_definition_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','application_source_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','candidate_source_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','account_source_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','kpi_source_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','queue_source_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','candidate_evaluation_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','application_simulation_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','account_simulation_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','strategy_summary_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','frontier_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','comparison_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','latest_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','archive_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','registry_rows','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','canonical_entities','bigint',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','policy_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','strategy_profile_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','objective_definition_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','constraint_definition_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','reason_definition_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','application_source_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','candidate_source_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','account_source_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','kpi_source_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','queue_source_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','candidate_evaluation_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','application_simulation_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','account_simulation_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','strategy_summary_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','frontier_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','comparison_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','latest_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','archive_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','contract_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','combined_set_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','contract_status','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','generated_at','timestamptz',FALSE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','validated_at','timestamptz',FALSE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','accepted_at','timestamptz',FALSE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','row_hash','text',TRUE),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','created_at','timestamptz',TRUE)
    ), expected_tables(schema_name,table_name) AS
    (
        VALUES
        ('msbf_ctl','m2_11_policy_profile'),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry'),
        ('msbf_m2','account_servicing_strategy_simulation'),
        ('msbf_m2','application_portfolio_strategy_simulation'),
        ('msbf_m2','application_strategy_candidate_evaluation'),
        ('msbf_m2','portfolio_strategy_account_source_snapshot'),
        ('msbf_m2','portfolio_strategy_application_source_snapshot'),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot'),
        ('msbf_m2','portfolio_strategy_comparison'),
        ('msbf_m2','portfolio_strategy_constraint_definition'),
        ('msbf_m2','portfolio_strategy_frontier'),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot'),
        ('msbf_m2','portfolio_strategy_objective_definition'),
        ('msbf_m2','portfolio_strategy_profile'),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot'),
        ('msbf_m2','portfolio_strategy_reason_definition'),
        ('msbf_m2','portfolio_strategy_simulation_archive'),
        ('msbf_m2','portfolio_strategy_simulation_latest'),
        ('msbf_m2','portfolio_strategy_summary')
    ), actual AS
    (
        SELECT n.nspname AS schema_name,c.relname AS table_name,a.attname AS column_name,
               replace(format_type(a.atttypid,a.atttypmod),'timestamp with time zone','timestamptz') AS actual_type,a.attnotnull AS actual_not_null
        FROM pg_attribute a
        JOIN pg_class c ON c.oid=a.attrelid
        JOIN pg_namespace n ON n.oid=c.relnamespace
        JOIN expected_tables t ON t.schema_name=n.nspname AND t.table_name=c.relname
        WHERE a.attnum>0 AND NOT a.attisdropped
    )
    SELECT count(*) INTO v_bad
    FROM expected e
    FULL JOIN actual a USING(schema_name,table_name,column_name)
    WHERE e.column_name IS NULL OR a.column_name IS NULL
       OR lower(a.actual_type)<>lower(e.expected_type)
       OR a.actual_not_null<>e.expected_not_null;
    IF v_bad<>0 THEN RAISE EXCEPTION 'M2.11 physical shape mismatches, including missing or extra columns: %',v_bad; END IF;

    WITH expected_tables(schema_name,table_name) AS
    (
        VALUES
        ('msbf_ctl','m2_11_policy_profile'),
        ('msbf_ctl','m2_11_portfolio_strategy_contract_registry'),
        ('msbf_m2','account_servicing_strategy_simulation'),
        ('msbf_m2','application_portfolio_strategy_simulation'),
        ('msbf_m2','application_strategy_candidate_evaluation'),
        ('msbf_m2','portfolio_strategy_account_source_snapshot'),
        ('msbf_m2','portfolio_strategy_application_source_snapshot'),
        ('msbf_m2','portfolio_strategy_candidate_source_snapshot'),
        ('msbf_m2','portfolio_strategy_comparison'),
        ('msbf_m2','portfolio_strategy_constraint_definition'),
        ('msbf_m2','portfolio_strategy_frontier'),
        ('msbf_m2','portfolio_strategy_kpi_source_snapshot'),
        ('msbf_m2','portfolio_strategy_objective_definition'),
        ('msbf_m2','portfolio_strategy_profile'),
        ('msbf_m2','portfolio_strategy_queue_source_snapshot'),
        ('msbf_m2','portfolio_strategy_reason_definition'),
        ('msbf_m2','portfolio_strategy_simulation_archive'),
        ('msbf_m2','portfolio_strategy_simulation_latest'),
        ('msbf_m2','portfolio_strategy_summary')
    )
    SELECT count(*) INTO v_bad
    FROM pg_attribute a
    JOIN pg_class c ON c.oid=a.attrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    JOIN expected_tables t ON t.schema_name=n.nspname AND t.table_name=c.relname
    WHERE a.attnum>0 AND NOT a.attisdropped;
    IF v_bad<>1014 THEN RAISE EXCEPTION 'M2.11 target field count expected 1014; found %',v_bad; END IF;

    SELECT count(*) INTO v_bad FROM
    (
      SELECT count(*) n,1 e FROM msbf_ctl.m2_11_policy_profile WHERE module1_run_id=v_run_id
      UNION ALL SELECT count(*),8 FROM msbf_m2.portfolio_strategy_profile WHERE module1_run_id=v_run_id
      UNION ALL SELECT count(*),8 FROM msbf_m2.portfolio_strategy_objective_definition WHERE module1_run_id=v_run_id
      UNION ALL SELECT count(*),12 FROM msbf_m2.portfolio_strategy_constraint_definition WHERE module1_run_id=v_run_id
      UNION ALL SELECT count(*),32 FROM msbf_m2.portfolio_strategy_reason_definition WHERE module1_run_id=v_run_id
    ) q WHERE n<>e;
    IF v_bad<>0 THEN RAISE EXCEPTION 'Frozen definition count mismatch'; END IF;

    SELECT count(*) INTO v_bad FROM msbf_m2.portfolio_strategy_profile
    WHERE module1_run_id=v_run_id AND
      ((candidate_scoring_applicable_flag AND round(access_rate_weight+selected_exposure_weight+finance_charge_weight+expected_loss_density_weight+risk_adjusted_contribution_weight+annualized_return_weight+payment_burden_weight,6)<>candidate_domain_weight_total)
       OR (NOT candidate_scoring_applicable_flag AND candidate_domain_weight_total<>0.000000::numeric)
       OR (scope_scoring_applicable_flag AND round(access_rate_weight+selected_exposure_weight+finance_charge_weight+expected_loss_density_weight+risk_adjusted_contribution_weight+annualized_return_weight+servicing_burden_weight+payment_burden_weight,6)<>scope_domain_weight_total)
       OR (NOT scope_scoring_applicable_flag AND scope_domain_weight_total<>0.000000::numeric));
    IF v_bad<>0 THEN RAISE EXCEPTION 'Strategy weight-total mismatches: %',v_bad; END IF;

    SELECT count(*) INTO v_bad FROM msbf_m2.portfolio_strategy_profile t
    WHERE t.module1_run_id=v_run_id
      AND t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at');
    IF v_bad<>0 THEN RAISE EXCEPTION 'Strategy definition physical row-hash mismatches: %',v_bad; END IF;

    SELECT count(*) INTO v_bad FROM msbf_m2.portfolio_strategy_objective_definition t
    WHERE t.module1_run_id=v_run_id
      AND t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at');
    IF v_bad<>0 THEN RAISE EXCEPTION 'Objective definition physical row-hash mismatches: %',v_bad; END IF;

    SELECT count(*) INTO v_bad FROM msbf_m2.portfolio_strategy_constraint_definition t
    WHERE t.module1_run_id=v_run_id
      AND t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at');
    IF v_bad<>0 THEN RAISE EXCEPTION 'Constraint definition physical row-hash mismatches: %',v_bad; END IF;

    SELECT count(*) INTO v_bad FROM msbf_m2.portfolio_strategy_reason_definition t
    WHERE t.module1_run_id=v_run_id
      AND t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at');
    IF v_bad<>0 THEN RAISE EXCEPTION 'Reason definition physical row-hash mismatches: %',v_bad; END IF;

    IF NOT EXISTS
    (
      SELECT 1 FROM msbf_ctl.m2_11_policy_profile
      WHERE module1_run_id=v_run_id AND policy_code='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_POLICY_V1'
        AND methodology_version='M2_11_METHOD_V1'
        AND contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
        AND contract_version=1 AND schema_version='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1'
        AND acceptance_gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
        AND canonical_entities=19298 AND policy_status='APPROVED'
        AND configuration_hash=msbf_ctl.m2_11_hash_jsonb(configuration_payload)
        AND configuration_payload #>> '{inherited_m2_2_structure_bounds,source_policy_code}'='M2_2_PRICING_STRUCTURE_POLICY_V1'
        AND configuration_payload #>> '{inherited_m2_2_structure_bounds,source_policy_configuration_hash}'='9e03c9ee37880e3ed16e12fb0c0ce0d4'
        AND (configuration_payload #>> '{inherited_m2_2_structure_bounds,minimum_candidate_amount}')::numeric(18,2)=2500.00::numeric(18,2)
        AND (configuration_payload #>> '{inherited_m2_2_structure_bounds,minimum_remittance_rate}')::numeric(9,6)=0.050000::numeric(9,6)
        AND (configuration_payload #>> '{inherited_m2_2_structure_bounds,maximum_remittance_rate}')::numeric(9,6)=0.200000::numeric(9,6)
        AND (configuration_payload #>> '{inherited_m2_2_structure_bounds,minimum_payback_multiple}')::numeric(9,6)=1.050000::numeric(9,6)
        AND (configuration_payload #>> '{inherited_m2_2_structure_bounds,maximum_payback_multiple}')::numeric(9,6)=1.400000::numeric(9,6)
        AND (configuration_payload #>> '{inherited_m2_2_structure_bounds,minimum_collection_horizon_days}')::integer=1
        AND (configuration_payload #>> '{inherited_m2_2_structure_bounds,maximum_collection_horizon_days}')::integer=120
    ) THEN RAISE EXCEPTION 'M2.11 policy identity/hash/inherited-bound mismatch'; END IF;

    IF EXISTS(SELECT 1 FROM msbf_m2.application_pricing_structure_latest
              WHERE module1_run_id=v_run_id AND policy_configuration_hash IS DISTINCT FROM '9e03c9ee37880e3ed16e12fb0c0ce0d4')
       OR EXISTS(SELECT 1 FROM msbf_m2.application_pricing_structure_candidate
                 WHERE module1_run_id=v_run_id AND policy_configuration_hash IS DISTINCT FROM '9e03c9ee37880e3ed16e12fb0c0ce0d4') THEN
      RAISE EXCEPTION 'Accepted M2.2 rows do not carry the governed inherited-bound policy hash';
    END IF;
END;
$m211$;

/* ============================================================================
Section 5A — Installed function, trigger, view, key, constraint and index integrity
============================================================================ */
DO $m211$
DECLARE
    v_bad bigint;
    v_base jsonb;
    v_with_exclusions jsonb;
    v_function_body text;
    v_index_mismatch_detail text;
BEGIN
  SELECT count(*),max(pg_get_functiondef(p.oid)) INTO v_bad,v_function_body
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  JOIN pg_language l ON l.oid=p.prolang
  WHERE n.nspname='msbf_ctl' AND p.proname='m2_11_hash_jsonb'
    AND p.pronargs=1 AND oidvectortypes(p.proargtypes)='jsonb'
    AND p.prorettype='text'::regtype AND p.provolatile='i' AND p.proisstrict
    AND p.prokind='f' AND NOT p.prosecdef AND l.lanname='sql';
  IF v_bad<>1
     OR position('md5' in lower(v_function_body))=0
     OR msbf_ctl.m2_11_hash_jsonb('{"b":2,"a":1}'::jsonb)
        <>md5('{"a":1,"b":2}'::jsonb::text)
     OR msbf_ctl.m2_11_hash_jsonb('{"b":2,"a":1}'::jsonb)
        <>msbf_ctl.m2_11_hash_jsonb('{"a":1,"b":2}'::jsonb) THEN
    RAISE EXCEPTION 'M2.11 canonical JSONB hash helper is absent or behaviorally incompatible';
  END IF;

  SELECT count(*),max(pg_get_functiondef(p.oid)) INTO v_bad,v_function_body
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  JOIN pg_language l ON l.oid=p.prolang
  WHERE n.nspname='msbf_ctl' AND p.proname='m2_11_registry_row_hash'
    AND p.pronargs=1 AND oidvectortypes(p.proargtypes)='jsonb'
    AND p.prorettype='text'::regtype AND p.provolatile='i' AND p.proisstrict
    AND p.prokind='f' AND NOT p.prosecdef AND l.lanname='sql';

  v_base:=jsonb_build_object('module1_run_id',1,'contract_code','CONTROL');
  v_with_exclusions:=v_base||jsonb_build_object(
    'registry_id',99,'contract_status','ACCEPTED','generated_at','2026-08-05T00:00:00Z',
    'validated_at','2026-08-05T00:00:01Z','accepted_at','2026-08-05T00:00:02Z',
    'row_hash','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa','created_at','2026-08-05T00:00:03Z',
    'policy_set_hash','01','strategy_profile_set_hash','02','objective_definition_set_hash','03',
    'constraint_definition_set_hash','04','reason_definition_set_hash','05',
    'application_source_set_hash','06','candidate_source_set_hash','07','account_source_set_hash','08',
    'kpi_source_set_hash','09','queue_source_set_hash','10','candidate_evaluation_set_hash','11',
    'application_simulation_set_hash','12','account_simulation_set_hash','13','strategy_summary_set_hash','14',
    'frontier_set_hash','15','comparison_set_hash','16','latest_set_hash','17','archive_set_hash','18',
    'contract_set_hash','19','combined_set_hash','20'
  );

  IF v_bad<>1
     OR position('registry_id' in lower(v_function_body))=0
     OR position('combined_set_hash' in lower(v_function_body))=0
     OR msbf_ctl.m2_11_registry_row_hash(v_with_exclusions)
        <>msbf_ctl.m2_11_hash_jsonb(v_base)
     OR msbf_ctl.m2_11_registry_row_hash(v_base)
        =msbf_ctl.m2_11_registry_row_hash(v_base||jsonb_build_object('contract_code','CHANGED')) THEN
    RAISE EXCEPTION 'M2.11 registry hash helper is absent or exclusion/inclusion behavior is incompatible';
  END IF;

  SELECT count(*),max(pg_get_functiondef(p.oid)) INTO v_bad,v_function_body
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  JOIN pg_language l ON l.oid=p.prolang
  WHERE n.nspname='msbf_ctl' AND p.proname='m2_11_block_archive_mutation'
    AND p.pronargs=0 AND p.prorettype='trigger'::regtype AND p.prokind='f'
    AND l.lanname='plpgsql';
  IF v_bad<>1
     OR position('raise exception' in lower(v_function_body))=0
     OR position('tg_op' in lower(v_function_body))=0
     OR position('tg_table_schema' in lower(v_function_body))=0
     OR position('tg_table_name' in lower(v_function_body))=0 THEN
    RAISE EXCEPTION 'M2.11 archive mutation blocker function is absent or behaviorally incompatible';
  END IF;

  SELECT count(*) INTO v_bad
  FROM pg_trigger t
  WHERE t.tgname='trg_m2_11_archive_immutable'
    AND t.tgrelid='msbf_m2.portfolio_strategy_simulation_archive'::regclass
    AND t.tgfoid='msbf_ctl.m2_11_block_archive_mutation()'::regprocedure
    AND NOT t.tgisinternal AND t.tgenabled='O' AND t.tgtype=27
    AND position('before' in lower(pg_get_triggerdef(t.oid,true)))>0
    AND position('update' in lower(pg_get_triggerdef(t.oid,true)))>0
    AND position('delete' in lower(pg_get_triggerdef(t.oid,true)))>0;
  IF v_bad<>1 THEN RAISE EXCEPTION 'M2.11 immutable archive trigger or table binding is incompatible'; END IF;
END;
$m211$;

DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  WITH expected(schema_name,table_name,constraint_name,constraint_kind,expected_columns) AS
  (
    VALUES
    ('msbf_ctl','m2_11_policy_profile','pk_m2_11_policy_profile','PRIMARY KEY','policy_profile_id'),
    ('msbf_ctl','m2_11_policy_profile','uq_m2_11_policy_profile_1','UNIQUE','module1_run_id'),
    ('msbf_m2','portfolio_strategy_profile','pk_portfolio_strategy_profile','PRIMARY KEY','module1_run_id,strategy_profile_code'),
    ('msbf_m2','portfolio_strategy_objective_definition','pk_portfolio_strategy_objective_definition','PRIMARY KEY','module1_run_id,objective_code'),
    ('msbf_m2','portfolio_strategy_constraint_definition','pk_portfolio_strategy_constraint_definition','PRIMARY KEY','module1_run_id,constraint_code'),
    ('msbf_m2','portfolio_strategy_reason_definition','pk_portfolio_strategy_reason_definition','PRIMARY KEY','module1_run_id,reason_code'),
    ('msbf_m2','portfolio_strategy_application_source_snapshot','pk_portfolio_strategy_application_source_snapsho','PRIMARY KEY','module1_run_id,scenario_id,merchant_application_id'),
    ('msbf_m2','portfolio_strategy_candidate_source_snapshot','pk_portfolio_strategy_candidate_source_snapshot','PRIMARY KEY','module1_run_id,scenario_id,merchant_application_id,candidate_template_code'),
    ('msbf_m2','portfolio_strategy_account_source_snapshot','pk_portfolio_strategy_account_source_snapshot','PRIMARY KEY','module1_run_id,scenario_id,merchant_application_id'),
    ('msbf_m2','portfolio_strategy_account_source_snapshot','uq_portfolio_strategy_account_source_snapsho_1','UNIQUE','module1_run_id,scenario_id,synthetic_account_id'),
    ('msbf_m2','portfolio_strategy_kpi_source_snapshot','pk_portfolio_strategy_kpi_source_snapshot','PRIMARY KEY','module1_run_id,scope_code,kpi_code'),
    ('msbf_m2','portfolio_strategy_queue_source_snapshot','pk_portfolio_strategy_queue_source_snapshot','PRIMARY KEY','module1_run_id,servicing_queue_code'),
    ('msbf_m2','application_strategy_candidate_evaluation','pk_application_strategy_candidate_evaluation','PRIMARY KEY','module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code'),
    ('msbf_m2','application_portfolio_strategy_simulation','pk_application_portfolio_strategy_simulation','PRIMARY KEY','module1_run_id,scenario_id,merchant_application_id,strategy_profile_code'),
    ('msbf_m2','account_servicing_strategy_simulation','pk_account_servicing_strategy_simulation','PRIMARY KEY','module1_run_id,scenario_id,merchant_application_id,strategy_profile_code'),
    ('msbf_m2','account_servicing_strategy_simulation','uq_account_servicing_strategy_simulation_1','UNIQUE','module1_run_id,scenario_id,synthetic_account_id,strategy_profile_code'),
    ('msbf_m2','portfolio_strategy_summary','pk_portfolio_strategy_summary','PRIMARY KEY','module1_run_id,strategy_profile_code,reporting_scope_code'),
    ('msbf_m2','portfolio_strategy_frontier','pk_portfolio_strategy_frontier','PRIMARY KEY','module1_run_id,strategy_profile_code,reporting_scope_code'),
    ('msbf_m2','portfolio_strategy_comparison','pk_portfolio_strategy_comparison','PRIMARY KEY','module1_run_id,challenger_strategy_profile_code,reporting_scope_code'),
    ('msbf_m2','portfolio_strategy_simulation_latest','pk_portfolio_strategy_simulation_latest','PRIMARY KEY','module1_run_id,strategy_profile_code,reporting_scope_code'),
    ('msbf_m2','portfolio_strategy_simulation_archive','pk_portfolio_strategy_simulation_archive','PRIMARY KEY','archive_id'),
    ('msbf_m2','portfolio_strategy_simulation_archive','uq_portfolio_strategy_simulation_archive_1','UNIQUE','module1_run_id,contract_version,strategy_profile_code,reporting_scope_code'),
    ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','pk_m2_11_portfolio_strategy_contract_registry','PRIMARY KEY','registry_id'),
    ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','uq_m2_11_portfolio_strategy_contract_registr_1','UNIQUE','module1_run_id,contract_version')
  ), actual AS
  (
    SELECT n.nspname AS schema_name,c.relname AS table_name,con.conname AS constraint_name,
           CASE con.contype WHEN 'p' THEN 'PRIMARY KEY' WHEN 'u' THEN 'UNIQUE' END AS constraint_kind,
           string_agg(a.attname,',' ORDER BY k.ord) AS actual_columns,
           con.convalidated
    FROM pg_constraint con
    JOIN pg_class c ON c.oid=con.conrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    CROSS JOIN LATERAL unnest(con.conkey) WITH ORDINALITY AS k(attnum,ord)
    JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum=k.attnum
    WHERE con.contype IN ('p','u')
    GROUP BY n.nspname,c.relname,con.conname,con.contype,con.convalidated
  )
  SELECT count(*) INTO v_bad
  FROM expected e LEFT JOIN actual a USING(schema_name,table_name,constraint_name,constraint_kind)
  WHERE a.constraint_name IS NULL OR NOT a.convalidated OR a.actual_columns<>e.expected_columns;
  IF v_bad<>0 THEN RAISE EXCEPTION 'M2.11 primary/unique-key structural mismatches: %',v_bad; END IF;

  WITH expected(schema_name,table_name,constraint_name,required_tokens) AS
  (
    VALUES
    ('msbf_ctl','m2_11_policy_profile','ck_m211_m2_11_policy_profile_canonical_entities',ARRAY['canonical_entities','19298']::text[]),
    ('msbf_ctl','m2_11_policy_profile','ck_m211_m2_11_policy_profile_candidate_score_toleranc',ARRAY['candidate_score_tolerance','0.000000000001']::text[]),
    ('msbf_ctl','m2_11_policy_profile','ck_m211_m2_11_policy_profile_non_production_boundary_',ARRAY['non_production_boundary_flag','true']::text[]),
    ('msbf_ctl','m2_11_policy_profile','ck_m211_m2_11_policy_profile_no_external_system_updat',ARRAY['no_external_system_update_flag','true']::text[]),
    ('msbf_ctl','m2_11_policy_profile','ck_m211_m2_11_policy_profile_no_merchant_contact_flag',ARRAY['no_merchant_contact_flag','true']::text[]),
    ('msbf_ctl','m2_11_policy_profile','ck_m211_m2_11_policy_profile_no_real_funds_movement_f',ARRAY['no_real_funds_movement_flag','true']::text[]),
    ('msbf_ctl','m2_11_policy_profile','ck_m211_m2_11_policy_profile_no_production_decisionin',ARRAY['no_production_decisioning_flag','true']::text[]),
    ('msbf_m2','portfolio_strategy_profile','ck_m211_strategy_candidate_total',ARRAY['candidate_domain_weight_total','candidate_scoring_applicable_flag','access_rate_weight','selected_exposure_weight','finance_charge_weight','expected_loss_density_weight','risk_adjusted_contribution_weight','annualized_return_weight','payment_burden_weight','round','6']::text[]),
    ('msbf_m2','portfolio_strategy_profile','ck_m211_strategy_scope_total',ARRAY['scope_domain_weight_total','access_rate_weight','selected_exposure_weight','finance_charge_weight','expected_loss_density_weight','risk_adjusted_contribution_weight','annualized_return_weight','servicing_burden_weight','payment_burden_weight','round','6']::text[]),
    ('msbf_m2','application_portfolio_strategy_simulation','ck_m211_app_access_indicator',ARRAY['access_selected_flag','strategy_outcome_code','access_selected']::text[]),
    ('msbf_m2','application_portfolio_strategy_simulation','ck_m211_app_no_access_density',ARRAY['selected_exposure_amount','selected_expected_loss_density','isnull']::text[]),
    ('msbf_m2','application_portfolio_strategy_simulation','ck_m211_app_account_applicability',ARRAY['operational_account_present_flag','account_certification_constraint_applicability','applicable','not_applicable','source_unresolved_exception_count','constraint_unresolved_exception_count']::text[]),
    ('msbf_m2','account_servicing_strategy_simulation','ck_m211_account_no_benefit_claims',ARRAY['risk_benefit_claimed_flag','return_benefit_claimed_flag','contribution_benefit_claimed_flag','payment_performance_benefit_claimed_flag']::text[]),
    ('msbf_m2','portfolio_strategy_summary','ck_m211_portfolio_strategy_s_servicing_burden_coverag',ARRAY['servicing_burden_coverage_code','accepted_operational_accounts_only']::text[]),
    ('msbf_m2','portfolio_strategy_summary','ck_m211_portfolio_strategy_s_new_access_servicing_bur',ARRAY['new_access_servicing_burden_estimated_flag','false']::text[]),
    ('msbf_m2','portfolio_strategy_simulation_latest','ck_m211_portfolio_strategy_s_servicing_burden_coverag',ARRAY['servicing_burden_coverage_code','accepted_operational_accounts_only']::text[]),
    ('msbf_m2','portfolio_strategy_simulation_latest','ck_m211_portfolio_strategy_s_contract_row_hash',ARRAY['contract_row_hash','^[0-9a-f]{32}$']::text[]),
    ('msbf_m2','portfolio_strategy_simulation_archive','ck_m211_portfolio_strategy_s_contract_row_hash',ARRAY['contract_row_hash','^[0-9a-f]{32}$']::text[]),
    ('msbf_m2','portfolio_strategy_simulation_archive','ck_m211_portfolio_strategy_s_archive_row_hash',ARRAY['archive_row_hash','^[0-9a-f]{32}$']::text[]),
    ('msbf_ctl','m2_11_portfolio_strategy_contract_registry','ck_m211_m2_11_portfolio_stra_contract_status',ARRAY['contract_status','generated','validated','accepted']::text[])
  ), actual AS
  (
    SELECT n.nspname AS schema_name,c.relname AS table_name,con.conname AS constraint_name,
           con.convalidated,
           lower(regexp_replace(replace(pg_get_constraintdef(con.oid,true),'"',''),'\s+','','g')) AS normalized_definition
    FROM pg_constraint con
    JOIN pg_class c ON c.oid=con.conrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE con.contype='c'
  )
  SELECT count(*) INTO v_bad
  FROM expected e
  LEFT JOIN actual a USING(schema_name,table_name,constraint_name)
  WHERE a.constraint_name IS NULL OR NOT a.convalidated
     OR EXISTS
        (
          SELECT 1 FROM unnest(e.required_tokens) tok
          WHERE a.normalized_definition NOT LIKE '%'||lower(regexp_replace(replace(tok,'"',''),'\s+','','g'))||'%'
        );
  IF v_bad<>0 THEN RAISE EXCEPTION 'M2.11 critical CHECK-constraint definition mismatches: %',v_bad; END IF;

  /* Catalog-native required-index certification. Deparsed SQL text is diagnostic only. */
  WITH expected
    (
      schema_name,table_name,index_name,unique_flag,access_method,
      expected_columns,expected_desc_flags,expected_nulls_first_flags
    ) AS
    (
      VALUES
      ('msbf_m2','portfolio_strategy_application_source_snapshot','idx_m211_app_src_app',FALSE,'btree',ARRAY['module1_run_id','merchant_application_id','scenario_code']::text[],ARRAY[FALSE,FALSE,FALSE]::boolean[],ARRAY[FALSE,FALSE,FALSE]::boolean[]),
      ('msbf_m2','portfolio_strategy_candidate_source_snapshot','idx_m211_candidate_src_app',FALSE,'btree',ARRAY['module1_run_id','scenario_id','merchant_application_id','candidate_rank','candidate_template_code']::text[],ARRAY[FALSE,FALSE,FALSE,FALSE,FALSE]::boolean[],ARRAY[FALSE,FALSE,FALSE,FALSE,FALSE]::boolean[]),
      ('msbf_m2','portfolio_strategy_account_source_snapshot','idx_m211_account_src_app',FALSE,'btree',ARRAY['module1_run_id','merchant_application_id','scenario_code']::text[],ARRAY[FALSE,FALSE,FALSE]::boolean[],ARRAY[FALSE,FALSE,FALSE]::boolean[]),
      ('msbf_m2','application_strategy_candidate_evaluation','idx_m211_eval_select',FALSE,'btree',ARRAY['module1_run_id','scenario_id','merchant_application_id','strategy_profile_code','objective_score','feasibility_rank','candidate_rank','candidate_template_code']::text[],ARRAY[FALSE,FALSE,FALSE,FALSE,TRUE,FALSE,FALSE,FALSE]::boolean[],ARRAY[FALSE,FALSE,FALSE,FALSE,TRUE,FALSE,FALSE,FALSE]::boolean[]),
      ('msbf_m2','application_portfolio_strategy_simulation','idx_m211_app_sim_scope',FALSE,'btree',ARRAY['module1_run_id','strategy_profile_code','scenario_code','portfolio_adverse_selected_flag','merchant_application_id']::text[],ARRAY[FALSE,FALSE,FALSE,FALSE,FALSE]::boolean[],ARRAY[FALSE,FALSE,FALSE,FALSE,FALSE]::boolean[]),
      ('msbf_m2','application_portfolio_strategy_simulation','idx_m211_app_sim_stress',FALSE,'btree',ARRAY['module1_run_id','merchant_application_id','strategy_profile_code','scenario_code']::text[],ARRAY[FALSE,FALSE,FALSE,FALSE]::boolean[],ARRAY[FALSE,FALSE,FALSE,FALSE]::boolean[]),
      ('msbf_m2','account_servicing_strategy_simulation','idx_m211_account_sim_scope',FALSE,'btree',ARRAY['module1_run_id','strategy_profile_code','scenario_code','portfolio_adverse_selected_flag','merchant_application_id']::text[],ARRAY[FALSE,FALSE,FALSE,FALSE,FALSE]::boolean[],ARRAY[FALSE,FALSE,FALSE,FALSE,FALSE]::boolean[]),
      ('msbf_m2','portfolio_strategy_summary','idx_m211_summary_scope',FALSE,'btree',ARRAY['module1_run_id','reporting_scope_code','strategy_profile_code']::text[],ARRAY[FALSE,FALSE,FALSE]::boolean[],ARRAY[FALSE,FALSE,FALSE]::boolean[]),
      ('msbf_m2','portfolio_strategy_frontier','idx_m211_frontier_scope',FALSE,'btree',ARRAY['module1_run_id','reporting_scope_code','frontier_rank','strategy_profile_code']::text[],ARRAY[FALSE,FALSE,FALSE,FALSE]::boolean[],ARRAY[FALSE,FALSE,FALSE,FALSE]::boolean[]),
      ('msbf_m2','portfolio_strategy_comparison','idx_m211_comparison_scope',FALSE,'btree',ARRAY['module1_run_id','reporting_scope_code','challenger_strategy_profile_code']::text[],ARRAY[FALSE,FALSE,FALSE]::boolean[],ARRAY[FALSE,FALSE,FALSE]::boolean[]),
      ('msbf_m2','portfolio_strategy_simulation_archive','idx_m211_archive_version',FALSE,'btree',ARRAY['module1_run_id','contract_version','reporting_scope_code','strategy_profile_code']::text[],ARRAY[FALSE,FALSE,FALSE,FALSE]::boolean[],ARRAY[FALSE,FALSE,FALSE,FALSE]::boolean[])
    ), actual AS
    (
      SELECT
        n.nspname AS schema_name,
        t.relname AS table_name,
        i.relname AS index_name,
        ix.indisunique AS unique_flag,
        am.amname AS access_method,
        ix.indisvalid,
        ix.indisready,
        ix.indislive,
        ix.indnkeyatts::integer AS key_attribute_count,
        ix.indnatts::integer AS total_attribute_count,
        (ix.indexprs IS NOT NULL) AS has_expressions,
        (ix.indpred IS NOT NULL) AS has_predicate,
        pg_get_expr(ix.indexprs,ix.indrelid,true) AS expression_definition,
        pg_get_expr(ix.indpred,ix.indrelid,true) AS predicate_definition,
        ARRAY
        (
          SELECT a.attname::text
          FROM generate_series(0,ix.indnkeyatts::integer-1) AS g(key_position)
          LEFT JOIN pg_attribute a
            ON a.attrelid=ix.indrelid
           AND a.attnum=ix.indkey[g.key_position]
          ORDER BY g.key_position
        ) AS actual_columns,
        ARRAY
        (
          SELECT ((ix.indoption[g.key_position]::integer & 1)=1)
          FROM generate_series(0,ix.indnkeyatts::integer-1) AS g(key_position)
          ORDER BY g.key_position
        ) AS actual_desc_flags,
        ARRAY
        (
          SELECT ((ix.indoption[g.key_position]::integer & 2)=2)
          FROM generate_series(0,ix.indnkeyatts::integer-1) AS g(key_position)
          ORDER BY g.key_position
        ) AS actual_nulls_first_flags,
        pg_get_indexdef(ix.indexrelid) AS actual_definition
      FROM pg_index ix
      JOIN pg_class i ON i.oid=ix.indexrelid AND i.relkind='i'
      JOIN pg_class t ON t.oid=ix.indrelid AND t.relkind IN ('r','p')
      JOIN pg_namespace n ON n.oid=i.relnamespace
      JOIN pg_am am ON am.oid=i.relam
      WHERE n.nspname='msbf_m2'
        AND i.relname IN
        (
          SELECT e.index_name FROM expected e
        )
    ), mismatch AS
    (
      SELECT
        e.*,
        a.table_name AS actual_table_name,
        a.unique_flag AS actual_unique_flag,
        a.access_method AS actual_access_method,
        a.indisvalid,
        a.indisready,
        a.indislive,
        a.key_attribute_count,
        a.total_attribute_count,
        a.has_expressions,
        a.has_predicate,
        a.expression_definition,
        a.predicate_definition,
        a.actual_columns,
        a.actual_desc_flags,
        a.actual_nulls_first_flags,
        a.actual_definition
      FROM expected e
      LEFT JOIN actual a
        ON a.schema_name=e.schema_name
       AND a.index_name=e.index_name
      WHERE a.index_name IS NULL
         OR a.table_name IS DISTINCT FROM e.table_name
         OR a.unique_flag IS DISTINCT FROM e.unique_flag
         OR a.access_method IS DISTINCT FROM e.access_method
         OR a.indisvalid IS DISTINCT FROM TRUE
         OR a.indisready IS DISTINCT FROM TRUE
         OR a.indislive IS DISTINCT FROM TRUE
         OR a.key_attribute_count IS DISTINCT FROM cardinality(e.expected_columns)
         OR a.total_attribute_count IS DISTINCT FROM cardinality(e.expected_columns)
         OR a.has_expressions IS DISTINCT FROM FALSE
         OR a.has_predicate IS DISTINCT FROM FALSE
         OR a.actual_columns IS DISTINCT FROM e.expected_columns
         OR a.actual_desc_flags IS DISTINCT FROM e.expected_desc_flags
         OR a.actual_nulls_first_flags IS DISTINCT FROM e.expected_nulls_first_flags
    )
  SELECT
    count(*)::bigint,
    string_agg
    (
      format
      (
        '%I.%I index %I | expected access=%s unique=%s columns=%s desc=%s nulls_first=%s | actual table=%s access=%s unique=%s valid=%s ready=%s live=%s key_count=%s total_count=%s expressions=%s predicate=%s columns=%s desc=%s nulls_first=%s definition=%s',
        schema_name,table_name,index_name,
        access_method,unique_flag,expected_columns::text,expected_desc_flags::text,expected_nulls_first_flags::text,
        coalesce(actual_table_name,'MISSING'),coalesce(actual_access_method,'MISSING'),coalesce(actual_unique_flag::text,'MISSING'),
        coalesce(indisvalid::text,'MISSING'),coalesce(indisready::text,'MISSING'),coalesce(indislive::text,'MISSING'),
        coalesce(key_attribute_count::text,'MISSING'),coalesce(total_attribute_count::text,'MISSING'),
        coalesce(expression_definition,'NONE'),coalesce(predicate_definition,'NONE'),
        coalesce(actual_columns::text,'MISSING'),coalesce(actual_desc_flags::text,'MISSING'),coalesce(actual_nulls_first_flags::text,'MISSING'),
        coalesce(actual_definition,'MISSING')
      ),
      E'\n' ORDER BY schema_name,table_name,index_name
    )
  INTO v_bad,v_index_mismatch_detail
  FROM mismatch;

  IF v_bad<>0 THEN
    RAISE EXCEPTION USING
      ERRCODE='P0001',
      MESSAGE=format('M2.11 required-index structural mismatches: %s',v_bad),
      DETAIL=coalesce(v_index_mismatch_detail,'No mismatch detail was generated.'),
      HINT='Run the unnumbered SELECT-only 213_required_index_structure_diagnostic.sql utility; do not execute Program 214.';
  END IF;
END;
$m211$;

DO $m211$
DECLARE
    v_bad bigint;
    v_columns text[];
    v_definition text;
BEGIN
  WITH expected_views(schema_name,view_name) AS
  (
    VALUES ('msbf_m2','v_m2_11_portfolio_strategy_simulation_latest'),
           ('msbf_ctl','v_m2_11_portfolio_strategy_lineage'),
           ('msbf_m2','v_m2_11_matched_application_stress_comparison'),
           ('msbf_m2','v_m2_11_canonical_entity_hash_source')
  )
  SELECT count(*) INTO v_bad
  FROM expected_views e
  LEFT JOIN pg_namespace n ON n.nspname=e.schema_name
  LEFT JOIN pg_class c ON c.relnamespace=n.oid AND c.relname=e.view_name AND c.relkind='v'
  WHERE c.oid IS NULL;
  IF v_bad<>0 THEN RAISE EXCEPTION 'M2.11 governed view existence mismatches: %',v_bad; END IF;

  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(v.attnum,t.attnum) AS attnum,v.attname AS view_name,t.attname AS table_name,
           v.atttypid AS view_type,t.atttypid AS table_type,v.atttypmod AS view_typmod,t.atttypmod AS table_typmod
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod FROM pg_attribute
      WHERE attrelid='msbf_m2.v_m2_11_portfolio_strategy_simulation_latest'::regclass
        AND attnum>0 AND NOT attisdropped
    ) v
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_simulation_latest'::regclass
        AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE view_name IS DISTINCT FROM table_name OR view_type IS DISTINCT FROM table_type OR view_typmod IS DISTINCT FROM table_typmod;
  IF v_bad<>0 THEN RAISE EXCEPTION 'M2.11 latest-view exact table-surface mismatch count %',v_bad; END IF;

  SELECT array_agg(attname ORDER BY attnum) INTO v_columns FROM pg_attribute
  WHERE attrelid='msbf_ctl.v_m2_11_portfolio_strategy_lineage'::regclass AND attnum>0 AND NOT attisdropped;
  IF v_columns IS DISTINCT FROM ARRAY[
    'module1_run_id','contract_code','contract_version','schema_version','methodology_version','acceptance_gate_id','contract_status',
    'source_m1_17_contract_code','source_m1_17_contract_version','source_m1_17_combined_hash',
    'source_m2_2_contract_code','source_m2_2_contract_version','source_m2_2_combined_hash',
    'source_m2_4_contract_code','source_m2_4_contract_version','source_m2_4_combined_hash',
    'source_m2_7_contract_code','source_m2_7_contract_version','source_m2_7_combined_hash',
    'source_m2_10_contract_code','source_m2_10_contract_version','source_m2_10_combined_hash',
    'policy_configuration_hash','canonical_entities','contract_set_hash','combined_set_hash',
    'generated_at','validated_at','accepted_at','row_hash'
  ]::text[] THEN RAISE EXCEPTION 'M2.11 lineage-view exact column order mismatch'; END IF;

  SELECT count(*) INTO v_bad
  FROM pg_attribute v
  LEFT JOIN pg_attribute t
    ON t.attrelid='msbf_ctl.m2_11_portfolio_strategy_contract_registry'::regclass
   AND t.attname=v.attname AND t.attnum>0 AND NOT t.attisdropped
  WHERE v.attrelid='msbf_ctl.v_m2_11_portfolio_strategy_lineage'::regclass
    AND v.attnum>0 AND NOT v.attisdropped
    AND (t.attname IS NULL OR v.atttypid<>t.atttypid OR v.atttypmod<>t.atttypmod);
  IF v_bad<>0 THEN RAISE EXCEPTION 'M2.11 lineage-view type mismatch count %',v_bad; END IF;

  SELECT array_agg(attname ORDER BY attnum) INTO v_columns FROM pg_attribute
  WHERE attrelid='msbf_m2.v_m2_11_matched_application_stress_comparison'::regclass AND attnum>0 AND NOT attisdropped;
  IF v_columns IS DISTINCT FROM ARRAY[
    'module1_run_id','merchant_application_id','strategy_profile_code','baseline_strategy_outcome_code','stress_strategy_outcome_code',
    'baseline_feasibility_class','stress_feasibility_class','baseline_selected_exposure_amount','stress_selected_exposure_amount',
    'baseline_payment_burden_rate','stress_payment_burden_rate','baseline_servicing_burden_units','stress_servicing_burden_units',
    'source_risk_improvement_violation_flag','source_return_improvement_violation_flag','strategy_access_improvement_violation_flag',
    'strategy_feasibility_improvement_violation_flag','comparable_payment_burden_improvement_violation_flag',
    'comparable_servicing_burden_improvement_violation_flag','strategy_restriction_flag','absolute_workload_reduction_flag',
    'stress_nonimprovement_pass_flag','baseline_row_hash','stress_row_hash'
  ]::text[] THEN RAISE EXCEPTION 'M2.11 matched-stress-view exact column order mismatch'; END IF;

  WITH mapping(view_column,source_column) AS
  (
    VALUES
    ('module1_run_id','module1_run_id'),('merchant_application_id','merchant_application_id'),('strategy_profile_code','strategy_profile_code'),
    ('baseline_strategy_outcome_code','strategy_outcome_code'),('stress_strategy_outcome_code','strategy_outcome_code'),
    ('baseline_feasibility_class','feasibility_class'),('stress_feasibility_class','feasibility_class'),
    ('baseline_selected_exposure_amount','selected_exposure_amount'),('stress_selected_exposure_amount','selected_exposure_amount'),
    ('baseline_payment_burden_rate','selected_payment_burden_rate'),('stress_payment_burden_rate','selected_payment_burden_rate'),
    ('baseline_servicing_burden_units','associated_servicing_burden_units'),('stress_servicing_burden_units','associated_servicing_burden_units'),
    ('source_risk_improvement_violation_flag','source_risk_improvement_violation_flag'),
    ('source_return_improvement_violation_flag','source_return_improvement_violation_flag'),
    ('strategy_access_improvement_violation_flag','strategy_access_improvement_violation_flag'),
    ('strategy_feasibility_improvement_violation_flag','strategy_feasibility_improvement_violation_flag'),
    ('comparable_payment_burden_improvement_violation_flag','comparable_payment_burden_improvement_violation_flag'),
    ('comparable_servicing_burden_improvement_violation_flag','comparable_servicing_burden_improvement_violation_flag'),
    ('strategy_restriction_flag','strategy_restriction_flag'),('absolute_workload_reduction_flag','absolute_workload_reduction_flag'),
    ('stress_nonimprovement_pass_flag','stress_nonimprovement_pass_flag'),('baseline_row_hash','row_hash'),('stress_row_hash','row_hash')
  )
  SELECT count(*) INTO v_bad
  FROM mapping m
  LEFT JOIN pg_attribute v ON v.attrelid='msbf_m2.v_m2_11_matched_application_stress_comparison'::regclass
                           AND v.attname=m.view_column AND v.attnum>0 AND NOT v.attisdropped
  LEFT JOIN pg_attribute t ON t.attrelid='msbf_m2.application_portfolio_strategy_simulation'::regclass
                           AND t.attname=m.source_column AND t.attnum>0 AND NOT t.attisdropped
  WHERE v.attname IS NULL OR t.attname IS NULL OR v.atttypid<>t.atttypid OR v.atttypmod<>t.atttypmod;
  IF v_bad<>0 THEN RAISE EXCEPTION 'M2.11 matched-stress-view type mismatch count %',v_bad; END IF;

  SELECT array_agg(attname ORDER BY attnum) INTO v_columns FROM pg_attribute
  WHERE attrelid='msbf_m2.v_m2_11_canonical_entity_hash_source'::regclass AND attnum>0 AND NOT attisdropped;
  IF v_columns IS DISTINCT FROM ARRAY['catalog_sequence','object_code','business_key','row_hash']::text[] THEN
    RAISE EXCEPTION 'M2.11 canonical-hash-view exact column order mismatch';
  END IF;
  IF (SELECT array_agg(format_type(atttypid,atttypmod) ORDER BY attnum) FROM pg_attribute
      WHERE attrelid='msbf_m2.v_m2_11_canonical_entity_hash_source'::regclass AND attnum>0 AND NOT attisdropped)
     IS DISTINCT FROM ARRAY['integer','text','text','text']::text[] THEN
    RAISE EXCEPTION 'M2.11 canonical-hash-view exact type mismatch';
  END IF;

  v_definition:=lower(regexp_replace(pg_get_viewdef('msbf_m2.v_m2_11_portfolio_strategy_simulation_latest'::regclass,true),'\s+','','g'));
  IF position('portfolio_strategy_simulation_latest' in v_definition)=0 THEN RAISE EXCEPTION 'M2.11 latest-view dependency mismatch'; END IF;

  v_definition:=lower(regexp_replace(pg_get_viewdef('msbf_ctl.v_m2_11_portfolio_strategy_lineage'::regclass,true),'\s+','','g'));
  IF position('m2_11_portfolio_strategy_contract_registry' in v_definition)=0 THEN RAISE EXCEPTION 'M2.11 lineage-view dependency mismatch'; END IF;

  v_definition:=lower(regexp_replace(pg_get_viewdef('msbf_m2.v_m2_11_matched_application_stress_comparison'::regclass,true),'\s+','','g'));
  IF position('application_portfolio_strategy_simulation' in v_definition)=0
     OR position('recession_energy' in v_definition)=0 OR position('baseline' in v_definition)=0
     OR position('merchant_application_id' in v_definition)=0 OR position('strategy_profile_code' in v_definition)=0 THEN
    RAISE EXCEPTION 'M2.11 matched-stress-view dependency or predicate mismatch';
  END IF;

  v_definition:=lower(regexp_replace(pg_get_viewdef('msbf_m2.v_m2_11_canonical_entity_hash_source'::regclass,true),'\s+','','g'));
  IF EXISTS
  (
    SELECT 1 FROM unnest(ARRAY[
      'm2_11_policy_profile','portfolio_strategy_profile','portfolio_strategy_objective_definition',
      'portfolio_strategy_constraint_definition','portfolio_strategy_reason_definition',
      'portfolio_strategy_application_source_snapshot','portfolio_strategy_candidate_source_snapshot',
      'portfolio_strategy_account_source_snapshot','portfolio_strategy_kpi_source_snapshot',
      'portfolio_strategy_queue_source_snapshot','application_strategy_candidate_evaluation',
      'application_portfolio_strategy_simulation','account_servicing_strategy_simulation',
      'portfolio_strategy_summary','portfolio_strategy_frontier','portfolio_strategy_comparison',
      'portfolio_strategy_simulation_latest','portfolio_strategy_simulation_archive',
      'm2_11_portfolio_strategy_contract_registry'
    ]::text[]) token
    WHERE position(token in v_definition)=0
  ) THEN RAISE EXCEPTION 'M2.11 canonical-hash-view family dependency mismatch'; END IF;
END;
$m211$;

/* ============================================================================
Section 6 — Pristine generation targets, evidence boundary, and lifecycle guard
============================================================================ */
DO $m211$
DECLARE
    v_run_id bigint;
    v_n bigint;
BEGIN
    SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

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
    IF v_n<>0 THEN RAISE EXCEPTION 'Program 213 requires pristine M2.11 generation targets; found % rows',v_n; END IF;

    SELECT count(*) INTO v_n FROM msbf_ctl.run_evidence
    WHERE run_id=v_run_id AND evidence_code LIKE 'M2_11_GENERATION_%';
    IF v_n<>0 THEN RAISE EXCEPTION 'Program 213 found % preexisting M2.11 generation evidence rows',v_n; END IF;

    IF EXISTS
    (
        SELECT 1 FROM msbf_ctl.acceptance_gate_result
        WHERE run_id=v_run_id AND gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
    ) THEN RAISE EXCEPTION 'M2.11 acceptance row exists before generation'; END IF;
END;
$m211$;

/* ============================================================================
Section 7 — Read-only preflight result
============================================================================ */
SELECT
    'PASS'::text AS preflight_status,
    r.run_id AS module1_run_id,
    r.run_code,r.run_version,r.run_status,
    5::integer AS accepted_source_families,
    15::integer AS physical_source_objects_scanned_by_program_214,
    1500::bigint AS application_rows,
    557::bigint AS candidate_rows,
    59::bigint AS account_rows,
    72::bigint AS kpi_rows,
    3::bigint AS queue_rows,
    61::bigint AS definition_rows,
    0::bigint AS generation_target_rows,
    'AUTHORIZED_TO_EXECUTE_PROGRAM_214'::text AS disposition
FROM msbf_ctl.run_registry r
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

COMMIT;
