/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.3 — Failed Schema/Policy Hash Recovery Check

Program     : 148B_msbf_m2_3_failed_policy_hash_schema_recovery_check_v0_2R1.sql
Version     : v0.2R1
Purpose     : Confirm that the failed Program 148 transaction was rolled back,
              the accepted M2.2 boundary remains intact, no M2.3 objects or
              evidence committed, and corrected Program 148 may be executed.
Writes      : None.
Required    : recovery_status = PASS.
============================================================================ */

SET statement_timeout = '20min';
SET jit = off;

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
        max(pricing_contract_code) AS contract_code,
        max(pricing_contract_version) AS contract_version,
        max(pricing_schema_version) AS schema_version,
        max(combined_set_hash) AS combined_set_hash
    FROM msbf_ctl.m2_2_pricing_structure_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
source_gate AS
(
    SELECT
        count(*)::bigint AS gate_rows,
        max(result_status) AS gate_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id = (SELECT run_id FROM run_context)
      AND gate_id = 'M2_2_PRICING_STRUCTURE_COUNTEROFFER'
      AND review_version = 1
),
object_state AS
(
    SELECT
        (to_regclass('msbf_ctl.m2_3_policy_profile') IS NOT NULL)::integer
            AS policy_table_exists,
        (to_regclass('msbf_m2.final_decision_outcome_definition') IS NOT NULL)::integer
            AS outcome_table_exists,
        (to_regclass('msbf_m2.final_decision_reason_definition') IS NOT NULL)::integer
            AS reason_table_exists,
        (to_regclass('msbf_m2.application_final_decision_source_snapshot') IS NOT NULL)::integer
            AS source_table_exists,
        (to_regclass('msbf_m2.application_final_offer_decision_snapshot') IS NOT NULL)::integer
            AS decision_table_exists,
        (to_regclass('msbf_m2.application_final_offer_decision_latest') IS NOT NULL)::integer
            AS latest_table_exists,
        (to_regclass('msbf_m2.application_final_offer_decision_archive') IS NOT NULL)::integer
            AS archive_table_exists,
        (to_regclass('msbf_ctl.m2_3_final_decision_contract_registry') IS NOT NULL)::integer
            AS registry_table_exists,
        (to_regclass('msbf_m2.v_m2_3_final_decision_latest') IS NOT NULL)::integer
            AS latest_view_exists,
        (to_regclass('msbf_m2.v_m2_3_matched_scenario_comparison') IS NOT NULL)::integer
            AS comparison_view_exists
),
persistent_state AS
(
    SELECT
        (SELECT count(*) FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code LIKE 'M2_3_%')::bigint AS evidence_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
         WHERE run_id = (SELECT run_id FROM run_context)
           AND gate_id = 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION')::bigint
           AS acceptance_rows,
        (SELECT count(*) FROM msbf_ref.acceptance_gate_catalog
         WHERE gate_id = 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION')::bigint
           AS m2_3_gate_catalog_rows
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
    object_state.policy_table_exists,
    object_state.outcome_table_exists,
    object_state.reason_table_exists,
    object_state.source_table_exists,
    object_state.decision_table_exists,
    object_state.latest_table_exists,
    object_state.archive_table_exists,
    object_state.registry_table_exists,
    object_state.latest_view_exists,
    object_state.comparison_view_exists,
    persistent_state.evidence_rows,
    persistent_state.acceptance_rows,
    persistent_state.m2_3_gate_catalog_rows,
    CASE
        WHEN run_context.run_status = 'M2_2_ACCEPTED'
         AND source_registry.registry_rows = 1
         AND source_registry.contract_status = 'ACCEPTED'
         AND source_registry.contract_code = 'M2_PRICING_STRUCTURE_CONSUMPTION'
         AND source_registry.contract_version = 1
         AND source_registry.schema_version = 'M2_2_PRICING_STRUCTURE_SCHEMA_V1'
         AND source_registry.combined_set_hash = 'bbe83b187b31ea561789797322031fc6'
         AND source_gate.gate_rows = 1
         AND source_gate.gate_status = 'PASS'
         AND object_state.policy_table_exists = 0
         AND object_state.outcome_table_exists = 0
         AND object_state.reason_table_exists = 0
         AND object_state.source_table_exists = 0
         AND object_state.decision_table_exists = 0
         AND object_state.latest_table_exists = 0
         AND object_state.archive_table_exists = 0
         AND object_state.registry_table_exists = 0
         AND object_state.latest_view_exists = 0
         AND object_state.comparison_view_exists = 0
         AND persistent_state.evidence_rows = 0
         AND persistent_state.acceptance_rows = 0
         AND persistent_state.m2_3_gate_catalog_rows = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status
FROM run_context
CROSS JOIN source_registry
CROSS JOIN source_gate
CROSS JOIN object_state
CROSS JOIN persistent_state;
