/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.7 — Operational Activation & Account Setup
============================================================================ */

/* ============================================================================
Program     : 180A_msbf_m2_7_failed_schema_policy_recovery_check_v0_2.sql
Version     : v0.2

Purpose
-------
Read-only recovery proof after a failed Program 180. Execute ROLLBACK first.
Accepted M2.6 must remain accepted and all M2.7 objects, evidence, and gate
records must be absent.

Required result
---------------
recovery_status = PASS.
============================================================================ */

WITH run_context AS
(
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
),
source_state AS
(
    SELECT
        count(*)::bigint AS registry_rows,
        max(contract_status) AS contract_status,
        max(contract_code) AS contract_code,
        max(contract_version) AS contract_version,
        max(schema_version) AS schema_version,
        max(combined_set_hash) AS combined_set_hash
    FROM msbf_ctl.m2_6_intervention_strategy_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
source_gate AS
(
    SELECT
        count(*)::bigint AS gate_rows,
        max(result_status) AS gate_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM run_context)
      AND gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'
      AND review_version=1
),
objects AS
(
    SELECT
        count(*) FILTER
        (
            WHERE table_schema='msbf_ctl'
              AND table_name IN
              (
                  'm2_7_policy_profile',
                  'm2_7_operational_activation_contract_registry'
              )
        )::bigint AS control_tables,
        count(*) FILTER
        (
            WHERE table_schema='msbf_m2'
              AND table_name IN
              (
                  'operational_setup_outcome_definition',
                  'operational_setup_action_definition',
                  'operational_setup_reason_definition',
                  'operational_activation_source_snapshot',
                  'application_operational_activation_snapshot',
                  'operational_account_setup_snapshot',
                  'operational_activation_portfolio_summary',
                  'application_operational_activation_latest',
                  'application_operational_activation_archive'
              )
        )::bigint AS business_tables
    FROM information_schema.tables
),
state AS
(
    SELECT
        (
            SELECT count(*) FROM msbf_ctl.run_evidence
            WHERE run_id=(SELECT run_id FROM run_context)
              AND evidence_code LIKE 'M2_7_%'
        )::bigint AS evidence_rows,
        (
            SELECT count(*) FROM msbf_ctl.acceptance_gate_result
            WHERE run_id=(SELECT run_id FROM run_context)
              AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
        )::bigint AS acceptance_rows,
        (
            SELECT count(*) FROM msbf_ref.acceptance_gate_catalog
            WHERE gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
        )::bigint AS gate_catalog_rows
)
SELECT
    run_context.run_status,
    source_state.registry_rows AS source_registry_rows,
    source_state.contract_status AS source_contract_status,
    source_state.contract_code AS source_contract_code,
    source_state.contract_version AS source_contract_version,
    source_state.schema_version AS source_schema_version,
    source_state.combined_set_hash AS source_combined_set_hash,
    source_gate.gate_rows AS source_gate_rows,
    source_gate.gate_status AS source_gate_status,
    objects.control_tables,objects.business_tables,
    state.evidence_rows,state.acceptance_rows,state.gate_catalog_rows,
    CASE
        WHEN run_context.run_status='M2_6_ACCEPTED'
         AND source_state.registry_rows=1
         AND source_state.contract_status='ACCEPTED'
         AND source_state.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'
         AND source_state.contract_version=1
         AND source_state.schema_version='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1'
         AND source_state.combined_set_hash='868125bff29270490cab4d2e55cb1388'
         AND source_gate.gate_rows=1
         AND source_gate.gate_status='PASS'
         AND objects.control_tables=0
         AND objects.business_tables=0
         AND state.evidence_rows=0
         AND state.acceptance_rows=0
         AND state.gate_catalog_rows=0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status
FROM run_context
CROSS JOIN source_state
CROSS JOIN source_gate
CROSS JOIN objects
CROSS JOIN state;
