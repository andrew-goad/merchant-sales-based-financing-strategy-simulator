/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.7 — Operational Activation & Account Setup
============================================================================ */

/* ============================================================================
Program     : 182B_msbf_m2_7_generation_reconciliation_reconstructed_v0_2.sql
Version     : v0.2

Purpose
-------
Read-only reconstruction of the Program 182 checkpoint if DBeaver loses or
suppresses the committed result tab.

Required result
---------------
generation_reconstruction_status = PASS.
============================================================================ */

WITH run_context AS
(
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
),
registry AS
(
    SELECT *
    FROM msbf_ctl.m2_7_operational_activation_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
physical AS
(
    SELECT
        (SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS source_rows,
        (SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS activation_rows,
        (SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS setup_rows,
        (SELECT count(*) FROM msbf_m2.operational_activation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS portfolio_rows,
        (SELECT count(*) FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS latest_rows,
        (SELECT count(*) FROM msbf_m2.application_operational_activation_archive WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS archive_rows,
        (SELECT count(*) FROM msbf_m2.v_m2_7_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS comparison_rows,
        (SELECT canonical_entities FROM msbf_m2.v_m2_7_canonical_hash WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS canonical_entities,
        (SELECT combined_set_hash FROM msbf_m2.v_m2_7_canonical_hash WHERE module1_run_id=(SELECT run_id FROM run_context)) AS physical_combined_set_hash,
        (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context) AND evidence_code LIKE 'M2_7_%' AND evidence_code NOT LIKE 'M2_7_POS_%' AND evidence_code NOT LIKE 'M2_7_NEG_%' AND evidence_code<>'M2_7_ACCEPTANCE_SUMMARY')::bigint AS generation_evidence_rows,
        (SELECT count(*) FROM msbf_m2.v_m2_7_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context) AND (stress_setup_permission_improvement_flag OR stress_priority_improvement_flag))::bigint AS stress_improvement_rows
)
SELECT
    run_context.run_status,registry.contract_status,physical.*,
    registry.no_setup_required_rows,registry.temporary_adjustment_setup_rows,
    registry.review_required_rows,registry.setup_authorized_rows,
    registry.setup_authorized_amount,registry.review_required_amount,
    registry.policy_set_hash,registry.outcome_set_hash,
    registry.action_set_hash,registry.reason_set_hash,
    registry.source_set_hash,registry.activation_set_hash,
    registry.account_setup_set_hash,registry.portfolio_summary_set_hash,
    registry.latest_set_hash,registry.archive_set_hash,
    registry.contract_set_hash,registry.combined_set_hash,
    CASE
        WHEN run_context.run_status IN
             ('M2_7_GENERATED','M2_7_VALIDATED','M2_7_ACCEPTED')
         AND registry.contract_status IN
             ('GENERATED','VALIDATED','ACCEPTED')
         AND physical.source_rows=59
         AND physical.activation_rows=59
         AND physical.setup_rows=59
         AND physical.portfolio_rows=2
         AND physical.latest_rows=59
         AND physical.archive_rows=59
         AND physical.comparison_rows=15
         AND physical.canonical_entities=341
         AND physical.generation_evidence_rows=24
         AND physical.stress_improvement_rows=0
         AND registry.no_setup_required_rows=57
         AND registry.temporary_adjustment_setup_rows=1
         AND registry.review_required_rows=1
         AND registry.setup_authorized_rows=1
         AND registry.setup_authorized_amount=518.04
         AND registry.review_required_amount=461.69
         AND registry.combined_set_hash IS NOT DISTINCT FROM
             physical.physical_combined_set_hash
        THEN 'PASS'
        ELSE 'FAIL'
    END AS generation_reconstruction_status
FROM run_context
CROSS JOIN registry
CROSS JOIN physical;
