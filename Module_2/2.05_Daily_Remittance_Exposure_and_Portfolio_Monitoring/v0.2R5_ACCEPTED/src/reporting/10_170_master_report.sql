/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 170_MSBF_M2_5_Master_Report_v0_2.sql
Version     : v0.2

Purpose
-------
Return one executive/governance summary row after formal M2.5 acceptance.

Writes      : None.
Required    : overall_m2_5_status = PASS.
============================================================================ */

WITH run_context AS
(
    SELECT run_id,run_code,run_version,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
),
policy AS
(
    SELECT
        policy_code,policy_version,policy_status,methodology_version,
        contract_code,contract_version,schema_version,
        source_m2_4_contract_code,source_m2_4_combined_hash,
        source_m1_6_acceptance_gate_id,source_m1_6_combined_hash,
        monitoring_horizon_days,source_replay_days,
        no_real_debit_instruction_flag,no_external_notice_generation_flag,
        no_production_adverse_action_notice_flag,
        no_write_off_or_restructure_action_flag,
        monitoring_only_no_servicing_action_flag,
        configuration_hash
    FROM msbf_ctl.m2_5_policy_profile
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
registry AS
(
    SELECT
        contract_status,
        policy_rows,
        status_rows,
        alert_rows,
        reason_rows,
        source_rows,
        daily_rows,
        latest_rows,
        archive_rows,
        portfolio_daily_rows,
        comparison_rows,
        canonical_entities,
        paid_off_rows,
        open_monitoring_rows,
        stress_status_floor_rows,
        total_remittance_amount,
        ending_receivable_exposure_amount,
        policy_set_hash,
        status_set_hash,
        alert_set_hash,
        reason_set_hash,
        source_set_hash,
        daily_set_hash,
        latest_set_hash,
        archive_set_hash,
        portfolio_daily_set_hash,
        contract_set_hash,
        combined_set_hash
    FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
controls AS
(
    SELECT
        count(*) FILTER(WHERE evidence_code LIKE 'M2_5_POS_%')::bigint
            AS positive_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_5_POS_%' AND status='PASS')::bigint
            AS positive_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_5_NEG_%')::bigint
            AS negative_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_5_NEG_%' AND status='PASS')::bigint
            AS negative_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_5_%' AND status='FAIL')::bigint
            AS failed_evidence
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM run_context)
),
acceptance AS
(
    SELECT result_status AS gate_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM run_context)
      AND gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
      AND review_version=1
),
latest_distribution AS
(
    SELECT
        count(*) FILTER(WHERE latest_monitoring_status_code='PAID_OFF')::bigint AS paid_off_rows,
        count(*) FILTER(WHERE latest_monitoring_status_code='CURRENT')::bigint AS current_rows,
        count(*) FILTER(WHERE latest_monitoring_status_code='WATCH')::bigint AS watch_rows,
        count(*) FILTER(WHERE latest_monitoring_status_code='UNDERPERFORMING')::bigint AS underperforming_rows,
        count(*) FILTER(WHERE latest_monitoring_status_code='SEVERE_SHORTFALL')::bigint AS severe_rows,
        count(*) FILTER(WHERE latest_monitoring_status_code='DORMANT_NO_REMITTANCE')::bigint AS dormant_rows
    FROM msbf_m2.advance_portfolio_monitoring_latest
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
diagnostics AS
(
    SELECT
        (SELECT count(*) FROM msbf_m2.v_m2_5_matched_monitoring_comparison
         WHERE module1_run_id=(SELECT run_id FROM run_context)
           AND stress_status_improvement_flag)::bigint
            AS stress_status_improvements,
        (SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest AS latest
         FULL OUTER JOIN msbf_m2.advance_portfolio_monitoring_archive AS archive
           ON archive.module1_run_id=latest.module1_run_id
          AND archive.contract_version=latest.contract_version
          AND archive.scenario_id=latest.scenario_id
          AND archive.merchant_application_id=latest.merchant_application_id
         WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=
               (SELECT run_id FROM run_context)
           AND
           (
               latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash
               OR archive.contract_payload IS DISTINCT FROM
                  (to_jsonb(latest)-'created_at')
           ))::bigint AS archive_mismatches,
        (SELECT count(*) FROM msbf_m2.portfolio_monitoring_reason_definition
         WHERE module1_run_id=(SELECT run_id FROM run_context)
           AND
           (
               production_adverse_action_notice_flag
               OR servicing_action_authorized_flag
           ))::bigint AS prohibited_reason_flags
)
SELECT
    run_context.run_code,
    run_context.run_version,
    run_context.run_status,
    policy.policy_code,
    policy.policy_version,
    policy.policy_status,
    policy.methodology_version,
    policy.contract_code,
    policy.contract_version,
    policy.schema_version,
    policy.source_m2_4_contract_code,
    policy.source_m2_4_combined_hash,
    policy.source_m1_6_acceptance_gate_id,
    policy.source_m1_6_combined_hash,
    policy.monitoring_horizon_days,
    policy.source_replay_days,
    registry.contract_status,
    acceptance.gate_status,
    registry.policy_rows,
    registry.status_rows,
    registry.alert_rows,
    registry.reason_rows,
    registry.source_rows,
    registry.daily_rows,
    registry.latest_rows,
    registry.archive_rows,
    registry.portfolio_daily_rows,
    registry.comparison_rows,
    registry.canonical_entities,
    registry.paid_off_rows,
    registry.open_monitoring_rows,
    latest_distribution.current_rows,
    latest_distribution.watch_rows,
    latest_distribution.underperforming_rows,
    latest_distribution.severe_rows,
    latest_distribution.dormant_rows,
    registry.stress_status_floor_rows,
    registry.total_remittance_amount,
    registry.ending_receivable_exposure_amount,
    controls.positive_passes,
    controls.positive_checks,
    controls.negative_passes,
    controls.negative_checks,
    controls.failed_evidence,
    diagnostics.stress_status_improvements,
    diagnostics.archive_mismatches,
    diagnostics.prohibited_reason_flags,
    registry.policy_set_hash,
    registry.status_set_hash,
    registry.alert_set_hash,
    registry.reason_set_hash,
    registry.source_set_hash,
    registry.daily_set_hash,
    registry.latest_set_hash,
    registry.archive_set_hash,
    registry.portfolio_daily_set_hash,
    registry.contract_set_hash,
    registry.combined_set_hash,
    CASE
        WHEN run_context.run_status='M2_5_ACCEPTED'
         AND registry.contract_status='ACCEPTED'
         AND acceptance.gate_status='PASS'
         AND registry.source_rows=59
         AND registry.daily_rows=7080
         AND registry.latest_rows=59
         AND registry.archive_rows=59
         AND registry.portfolio_daily_rows=240
         AND registry.comparison_rows=15
         AND registry.canonical_entities=7536
         AND registry.paid_off_rows+registry.open_monitoring_rows=59
         AND controls.positive_passes=120
         AND controls.positive_checks=120
         AND controls.negative_passes=20
         AND controls.negative_checks=20
         AND controls.failed_evidence=0
         AND diagnostics.stress_status_improvements=0
         AND diagnostics.archive_mismatches=0
         AND diagnostics.prohibited_reason_flags=0
         AND policy.no_real_debit_instruction_flag
         AND policy.no_external_notice_generation_flag
         AND policy.no_production_adverse_action_notice_flag
         AND policy.no_write_off_or_restructure_action_flag
         AND policy.monitoring_only_no_servicing_action_flag
        THEN 'PASS'
        ELSE 'FAIL'
    END AS overall_m2_5_status
FROM run_context
CROSS JOIN policy
CROSS JOIN registry
CROSS JOIN controls
CROSS JOIN acceptance
CROSS JOIN latest_distribution
CROSS JOIN diagnostics;
