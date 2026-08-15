/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.7 — Operational Activation & Account Setup
============================================================================ */

/* ============================================================================
Program     : 182A_msbf_m2_7_failed_generation_recovery_check_v0_2.sql
Version     : v0.2

Purpose
-------
Read-only recovery check after failed or cancelled Program 182. Execute
ROLLBACK first. Programs 180 and 181 remain authoritative and all generated
M2.7 targets must remain empty.

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
targets AS
(
    SELECT
        (SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS source_rows,
        (SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS activation_rows,
        (SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS setup_rows,
        (SELECT count(*) FROM msbf_m2.operational_activation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS portfolio_rows,
        (SELECT count(*) FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS latest_rows,
        (SELECT count(*) FROM msbf_m2.application_operational_activation_archive WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS archive_rows,
        (SELECT count(*) FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS registry_rows,
        (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context) AND evidence_code LIKE 'M2_7_%')::bigint AS evidence_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP')::bigint AS acceptance_rows
)
SELECT
    run_context.run_status,targets.*,
    CASE
        WHEN run_context.run_status='M2_6_ACCEPTED'
         AND targets.source_rows=0
         AND targets.activation_rows=0
         AND targets.setup_rows=0
         AND targets.portfolio_rows=0
         AND targets.latest_rows=0
         AND targets.archive_rows=0
         AND targets.registry_rows=0
         AND targets.evidence_rows=0
         AND targets.acceptance_rows=0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status
FROM run_context
CROSS JOIN targets;
