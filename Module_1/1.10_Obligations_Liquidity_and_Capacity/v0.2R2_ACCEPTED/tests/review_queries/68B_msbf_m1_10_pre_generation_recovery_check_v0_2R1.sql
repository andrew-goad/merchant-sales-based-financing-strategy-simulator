/* ============================================================================
MSBF M1.10 Pre-Generation Recovery and Hash-Source Diagnosis
Version : v0.2R1
Purpose : Confirm that the cancelled v0.2 generation attempt committed no
          M1.10 business rows or evidence and that the original preflight FAIL
          arose solely from referencing a nonexistent M1.2 run-evidence code.
============================================================================ */
WITH r AS (
    SELECT run_id,run_status,population_id,as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), state AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)) AS obligation_rows,
      (SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS capacity_rows,
      (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_10_%') AS m1_10_evidence_rows,
      (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY') AS m1_10_gate_rows,
      (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors,
      (SELECT population_hash FROM msbf_m1.population_registry WHERE population_id=(SELECT population_id FROM r)) AS population_registry_hash,
      (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_2_POPULATION_SET_HASH') AS legacy_evidence_code_rows,
      to_regclass('msbf_m1.application_liquidity_capacity_snapshot') IS NOT NULL AS capacity_table_exists,
      to_regclass('msbf_m1.v_m1_10_capacity_lineage') IS NOT NULL AS lineage_view_exists
)
SELECT
    clock_timestamp() AS execution_timestamp,
    current_database() AS database_name,
    current_user AS database_user,
    r.run_id,r.run_status,r.population_id,r.as_of_date,
    state.obligation_rows,state.capacity_rows,state.m1_10_evidence_rows,state.m1_10_gate_rows,
    state.blocking_errors,state.population_registry_hash,state.legacy_evidence_code_rows,
    state.capacity_table_exists,state.lineage_view_exists,
    CASE WHEN current_database()='msbf_strategy'
          AND r.run_status='M1_9_ACCEPTED'
          AND state.obligation_rows=0
          AND state.capacity_rows=0
          AND state.m1_10_evidence_rows=0
          AND state.m1_10_gate_rows=0
          AND state.blocking_errors=0
          AND state.population_registry_hash='9b706c926260a3ef1ae8ac95eed5d0bf'
          AND state.legacy_evidence_code_rows=0
          AND state.capacity_table_exists
          AND state.lineage_view_exists
         THEN 'PASS' ELSE 'FAIL' END AS recovery_state_status
FROM r CROSS JOIN state;
