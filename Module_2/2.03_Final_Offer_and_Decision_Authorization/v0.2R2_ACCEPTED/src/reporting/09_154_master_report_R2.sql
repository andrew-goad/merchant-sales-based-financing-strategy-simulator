/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.3 — Final Offer & Decision Authorization

Program     : 154_MSBF_M2_3_Master_Report_v0_2R2.sql
Version     : v0.2R2
Purpose     : One-row executive and governance summary after M2.3 acceptance.
Writes      : None.
Required    : overall_m2_3_status = PASS.
============================================================================ */

WITH run_context AS
(
    SELECT run_id, run_code, run_version, run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
),
policy AS
(
    SELECT *
    FROM msbf_ctl.m2_3_policy_profile
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
registry AS
(
    SELECT *
    FROM msbf_ctl.m2_3_final_decision_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
controls AS
(
    SELECT
        count(*) FILTER(WHERE evidence_code LIKE 'M2_3_POS_%') AS positive_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_3_POS_%' AND status='PASS') AS positive_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_3_NEG_%') AS negative_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_3_NEG_%' AND status='PASS') AS negative_passes,
        count(*) FILTER(WHERE status='FAIL' AND evidence_code LIKE 'M2_3_%') AS failed_evidence
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM run_context)
),
acceptance AS
(
    SELECT result_status AS gate_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM run_context)
      AND gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
      AND review_version=1
),
physical AS
(
    SELECT
        count(*) FILTER(WHERE final_decision_outcome_code='FINAL_OFFER_AUTHORIZED') AS final_offer_authorized_rows,
        count(*) FILTER(WHERE final_decision_outcome_code='COUNTEROFFER_REVIEW_REQUIRED') AS manual_review_required_rows,
        count(*) FILTER(WHERE final_decision_outcome_code='DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED') AS decline_insufficient_evidence_rows,
        count(*) FILTER(WHERE final_decision_outcome_code='DECLINE_POLICY_AUTHORIZED') AS decline_policy_rows,
        count(*) FILTER(WHERE scenario_code='BASELINE') AS baseline_rows,
        count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_rows
    FROM msbf_m2.application_final_offer_decision_latest
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
diagnostics AS
(
    SELECT
        (SELECT count(*) FROM msbf_m2.v_m2_3_matched_scenario_comparison
         WHERE module1_run_id=(SELECT run_id FROM run_context)
           AND (stress_decision_improvement_flag OR stress_offer_term_improvement_flag))
         AS stress_improvements,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest
         WHERE module1_run_id=(SELECT run_id FROM run_context)
           AND NOT final_offer_authorized_flag
           AND final_offer_amount IS NOT NULL)
         AS nonoffer_term_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest AS latest
         JOIN msbf_m2.application_final_offer_decision_archive AS archive
           ON archive.module1_run_id=latest.module1_run_id
          AND archive.contract_version=latest.contract_version
          AND archive.scenario_id=latest.scenario_id
          AND archive.merchant_application_id=latest.merchant_application_id
         WHERE latest.module1_run_id=(SELECT run_id FROM run_context)
           AND (archive.contract_row_hash IS DISTINCT FROM latest.contract_row_hash
                OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at')))
         AS archive_mismatches
)
SELECT
    run_context.run_code,
    run_context.run_version,
    run_context.run_status,
    policy.policy_code,
    policy.policy_version,
    policy.methodology_version,
    policy.contract_code,
    policy.contract_version,
    policy.schema_version,
    policy.source_m2_2_contract_code,
    policy.source_m2_2_contract_version,
    policy.source_m2_2_schema_version,
    policy.source_m2_2_combined_hash,
    registry.contract_status,
    acceptance.gate_status,
    registry.policy_rows,
    registry.outcome_rows,
    registry.reason_rows,
    registry.source_rows,
    registry.decision_snapshot_rows,
    registry.decision_latest_rows,
    registry.decision_archive_rows,
    registry.comparison_rows,
    registry.canonical_entities,
    physical.final_offer_authorized_rows,
    physical.manual_review_required_rows,
    physical.decline_insufficient_evidence_rows,
    physical.decline_policy_rows,
    physical.baseline_rows,
    physical.stress_rows,
    controls.positive_passes,
    controls.positive_checks,
    controls.negative_passes,
    controls.negative_checks,
    controls.failed_evidence,
    diagnostics.stress_improvements,
    diagnostics.nonoffer_term_rows,
    diagnostics.archive_mismatches,
    registry.policy_set_hash,
    registry.outcome_set_hash,
    registry.reason_set_hash,
    registry.source_set_hash,
    registry.decision_snapshot_set_hash,
    registry.decision_latest_set_hash,
    registry.decision_archive_set_hash,
    registry.contract_set_hash,
    registry.combined_set_hash,
    CASE
        WHEN run_context.run_status='M2_3_ACCEPTED'
         AND registry.contract_status='ACCEPTED'
         AND acceptance.gate_status='PASS'
         AND registry.source_rows=1500
         AND registry.decision_latest_rows=1500
         AND registry.decision_archive_rows=1500
         AND registry.comparison_rows=750
         AND registry.canonical_entities=6029
         AND physical.final_offer_authorized_rows=59
         AND physical.manual_review_required_rows=190
         AND physical.decline_insufficient_evidence_rows=178
         AND physical.decline_policy_rows=1073
         AND controls.positive_passes=120
         AND controls.positive_checks=120
         AND controls.negative_passes=20
         AND controls.negative_checks=20
         AND controls.failed_evidence=0
         AND diagnostics.stress_improvements=0
         AND diagnostics.nonoffer_term_rows=0
         AND diagnostics.archive_mismatches=0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS overall_m2_3_status
FROM run_context
CROSS JOIN policy
CROSS JOIN registry
CROSS JOIN controls
CROSS JOIN acceptance
CROSS JOIN physical
CROSS JOIN diagnostics;
