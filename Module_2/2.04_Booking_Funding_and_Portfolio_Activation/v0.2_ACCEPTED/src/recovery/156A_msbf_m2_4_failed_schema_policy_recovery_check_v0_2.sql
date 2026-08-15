/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M2.4 — Booking, Funding & Portfolio Activation

Program     : 156A_msbf_m2_4_failed_schema_policy_recovery_check_v0_2.sql
Version     : v0.2
Purpose     : Read-only verification after a failed Program 156 transaction.
              Run after ROLLBACK. It confirms accepted M2.3 source state and
              verifies that no persistent M2.4 schema, policy, gate, evidence,
              or acceptance state survived the failed transaction.

Required    : recovery_status = PASS.
============================================================================ */

/* --------------------------------------------------------------------------
Recovery reconstruction — read-only physical state and lifecycle verification
-------------------------------------------------------------------------- */
WITH run_context AS
(
    SELECT run_id, run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
source_registry AS
(
    SELECT
        count(*)::bigint AS registry_rows,
        max(contract_status) AS contract_status,
        max(contract_code) AS contract_code,
        max(contract_version) AS contract_version,
        max(schema_version) AS schema_version,
        max(combined_set_hash) AS combined_set_hash
    FROM msbf_ctl.m2_3_final_decision_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
source_gate AS
(
    SELECT
        count(*)::bigint AS gate_rows,
        max(result_status) AS gate_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id = (SELECT run_id FROM run_context)
      AND gate_id = 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
      AND review_version = 1
),
objects AS
(
    SELECT
        (to_regclass('msbf_ctl.m2_4_policy_profile') IS NOT NULL)::integer
            AS policy_table_exists,
        (to_regclass('msbf_m2.booking_funding_activation_outcome_definition') IS NOT NULL)::integer
            AS outcome_table_exists,
        (to_regclass('msbf_m2.booking_funding_reason_definition') IS NOT NULL)::integer
            AS reason_table_exists,
        (to_regclass('msbf_m2.external_notice_control_definition') IS NOT NULL)::integer
            AS notice_table_exists,
        (to_regclass('msbf_m2.application_booking_funding_source_snapshot') IS NOT NULL)::integer
            AS source_table_exists,
        (to_regclass('msbf_m2.application_booking_funding_activation_snapshot') IS NOT NULL)::integer
            AS activation_table_exists,
        (to_regclass('msbf_m2.application_booking_funding_activation_latest') IS NOT NULL)::integer
            AS latest_table_exists,
        (to_regclass('msbf_m2.application_booking_funding_activation_archive') IS NOT NULL)::integer
            AS archive_table_exists,
        (to_regclass('msbf_m2.synthetic_account_activation') IS NOT NULL)::integer
            AS account_table_exists,
        (to_regclass('msbf_m2.synthetic_advance_funding') IS NOT NULL)::integer
            AS advance_table_exists,
        (to_regclass('msbf_m2.initial_portfolio_activation') IS NOT NULL)::integer
            AS portfolio_table_exists,
        (to_regclass('msbf_ctl.m2_4_portfolio_activation_contract_registry') IS NOT NULL)::integer
            AS registry_table_exists,
        (to_regclass('msbf_m2.v_m2_4_activation_latest') IS NOT NULL)::integer
            AS latest_view_exists,
        (to_regclass('msbf_m2.v_m2_4_matched_scenario_comparison') IS NOT NULL)::integer
            AS comparison_view_exists
),
state AS
(
    SELECT
        (SELECT count(*) FROM msbf_ref.acceptance_gate_catalog
         WHERE gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION')::bigint AS gate_catalog_rows,
        (SELECT count(*) FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code LIKE 'M2_4_%')::bigint AS evidence_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
         WHERE run_id = (SELECT run_id FROM run_context)
           AND gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION')::bigint AS acceptance_rows
)
SELECT
    run_context.run_status,
    source_registry.registry_rows AS source_registry_rows,
    source_registry.contract_status AS source_contract_status,
    source_registry.contract_code AS source_contract_code,
    source_registry.contract_version AS source_contract_version,
    source_registry.schema_version AS source_schema_version,
    source_registry.combined_set_hash AS source_combined_hash,
    source_gate.gate_rows AS source_gate_rows,
    source_gate.gate_status AS source_gate_status,
    objects.policy_table_exists,
    objects.outcome_table_exists,
    objects.reason_table_exists,
    objects.notice_table_exists,
    objects.source_table_exists,
    objects.activation_table_exists,
    objects.latest_table_exists,
    objects.archive_table_exists,
    objects.account_table_exists,
    objects.advance_table_exists,
    objects.portfolio_table_exists,
    objects.registry_table_exists,
    objects.latest_view_exists,
    objects.comparison_view_exists,
    state.gate_catalog_rows,
    state.evidence_rows,
    state.acceptance_rows,
    CASE
        WHEN run_context.run_status = 'M2_3_ACCEPTED'
         AND source_registry.registry_rows = 1
         AND source_registry.contract_status = 'ACCEPTED'
         AND source_registry.contract_code = 'M2_FINAL_OFFER_DECISION_CONSUMPTION'
         AND source_registry.contract_version = 1
         AND source_registry.schema_version = 'M2_3_FINAL_DECISION_SCHEMA_V1'
         AND source_registry.combined_set_hash = 'bf09349b06ede7e5a2ec830c2f9ffe90'
         AND source_gate.gate_rows = 1
         AND source_gate.gate_status = 'PASS'
         AND objects.policy_table_exists = 0
         AND objects.outcome_table_exists = 0
         AND objects.reason_table_exists = 0
         AND objects.notice_table_exists = 0
         AND objects.source_table_exists = 0
         AND objects.activation_table_exists = 0
         AND objects.latest_table_exists = 0
         AND objects.archive_table_exists = 0
         AND objects.account_table_exists = 0
         AND objects.advance_table_exists = 0
         AND objects.portfolio_table_exists = 0
         AND objects.registry_table_exists = 0
         AND objects.latest_view_exists = 0
         AND objects.comparison_view_exists = 0
         AND state.gate_catalog_rows = 0
         AND state.evidence_rows = 0
         AND state.acceptance_rows = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status
FROM run_context
CROSS JOIN source_registry
CROSS JOIN source_gate
CROSS JOIN objects
CROSS JOIN state;
