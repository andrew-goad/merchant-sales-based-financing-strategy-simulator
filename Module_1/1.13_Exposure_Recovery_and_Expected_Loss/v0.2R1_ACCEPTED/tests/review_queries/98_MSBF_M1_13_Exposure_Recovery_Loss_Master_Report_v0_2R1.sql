/* ============================================================================
M1.13 v0.2R1 BOOLEAN-PARAMETER AGGREGATION HOTFIX
Source  : 98_MSBF_M1_13_Exposure_Recovery_Loss_Master_Report_v0_2.sql
Role    : Master report; executable logic unchanged from v0.2.
Revision: File name is version-aligned to v0.2R1. Except where explicitly
          documented in HOTFIX_NOTES_v0_2R1.md, executable logic is unchanged.
============================================================================ */

/* ============================================================================
MSBF M1.13 Exposure, Recovery & Expected Loss Foundations — Master Report
Version : v0.2
Purpose : Provide one executive/technical acceptance record covering run state,
          row populations, evidence status, EAD/recovery/LGD statistics,
          comparative loss totals, matched stress direction, validation counts,
          deterministic hashes, and final acceptance status.
Mode    : Read-only after M1.13 acceptance.
Output  : One filterable master-report row.
============================================================================ */

WITH r AS (
    SELECT run_id,run_status,population_id,as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), gate AS (
    SELECT *
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM r)
      AND gate_id='M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
    ORDER BY review_version DESC
    LIMIT 1
), pos AS (
    SELECT count(*) AS checks,
           count(*) FILTER(WHERE status='PASS') AS passes,
           count(*) FILTER(WHERE status='FAIL') AS failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
      AND evidence_code LIKE 'M1_13_POS_%'
), neg AS (
    SELECT count(*) AS controls,
           count(*) FILTER(WHERE status='PASS') AS passes,
           count(*) FILTER(WHERE status='FAIL') AS failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
      AND evidence_code LIKE 'M1_13_NEG_%'
), summary AS (
    SELECT
        count(*) AS snapshots,
        count(DISTINCT merchant_application_id) AS applications,
        count(DISTINCT scenario_id) AS scenarios,
        count(*) FILTER(WHERE loss_evidence_status='COMPLETE') AS complete_rows,
        count(*) FILTER(WHERE loss_evidence_status='PARTIAL') AS partial_rows,
        count(*) FILTER(WHERE loss_evidence_status='BLOCKED') AS blocked_rows,
        count(*) FILTER(WHERE recovery_evidence_status='SUPPORTED') AS supported_recovery_rows,
        count(*) FILTER(WHERE recovery_evidence_status='PARAMETER_ONLY') AS parameter_only_recovery_rows,
        count(*) FILTER(WHERE recovery_evidence_status='CONFLICT') AS recovery_conflict_rows,
        count(*) FILTER(WHERE manual_review_recommended_flag) AS manual_review_rows,
        count(*) FILTER(WHERE hard_stop_recommended_flag) AS hard_stop_rows,
        round(avg(initial_receivable_exposure_amount),2) AS avg_initial_exposure,
        round(avg(path_weighted_ead_amount),2) AS avg_path_weighted_ead,
        round(avg(expected_ead_rate),8) AS avg_ead_rate,
        round(avg(recovery_rate_assumption),8) AS avg_recovery_rate,
        round(avg(lgd_input_rate),8) AS avg_lgd_rate,
        round(sum(simple_comparative_expected_loss_amount),2) AS simple_loss_total,
        round(sum(schedule_adjusted_comparative_expected_loss_amount),2) AS schedule_loss_total,
        round(avg(schedule_adjusted_comparative_loss_rate),8) AS avg_schedule_loss_rate
    FROM msbf_m1.application_exposure_recovery_loss_snapshot
    WHERE module1_run_id=(SELECT run_id FROM r)
), scenario AS (
    SELECT
        round(sum(l.schedule_adjusted_comparative_expected_loss_amount)
              FILTER(WHERE sr.scenario_code='BASELINE'),2) AS baseline_schedule_loss,
        round(sum(l.schedule_adjusted_comparative_expected_loss_amount)
              FILTER(WHERE sr.scenario_code='RECESSION_ENERGY'),2) AS stress_schedule_loss,
        count(*) FILTER(WHERE sr.scenario_code='RECESSION_ENERGY' AND l.stress_ead_worsening_flag) AS ead_worsening_rows,
        count(*) FILTER(WHERE sr.scenario_code='RECESSION_ENERGY' AND l.stress_lgd_worsening_flag) AS lgd_worsening_rows,
        count(*) FILTER(WHERE sr.scenario_code='RECESSION_ENERGY' AND l.stress_loss_worsening_flag) AS loss_worsening_rows
    FROM msbf_m1.application_exposure_recovery_loss_snapshot l
    JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
    WHERE l.module1_run_id=(SELECT run_id FROM r)
), hashes AS (
    SELECT
        max(metric_value_text) FILTER(WHERE evidence_code='M1_13_PATH_SET_HASH') AS path_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_13_SNAPSHOT_SET_HASH') AS snapshot_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_13_COMBINED_SET_HASH') AS combined_hash,
        (max(metric_value_numeric) FILTER(WHERE evidence_code='M1_13_CANONICAL_MISMATCH_COUNT'))::bigint AS mismatch_count
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
), path AS (
    SELECT count(*) AS path_rows
    FROM msbf_m1.application_ead_path_value
    WHERE module1_run_id=(SELECT run_id FROM r)
), policy AS (
    SELECT profile_payload
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
      AND profile_version=1
)
SELECT
    r.run_id,
    r.run_status,
    r.population_id,
    r.as_of_date,
    gate.gate_id,
    gate.review_version,
    gate.result_status AS gate_status,
    gate.reviewed_at,
    policy.profile_payload->>'methodology_version' AS methodology_version,
    policy.profile_payload->>'exposure_basis_code' AS exposure_basis_code,
    policy.profile_payload->>'ead_method_code' AS ead_method_code,
    path.path_rows,
    summary.*,
    scenario.*,
    pos.checks AS positive_checks,
    pos.passes AS positive_passes,
    pos.failures AS positive_failures,
    neg.controls AS negative_controls,
    neg.passes AS negative_passes,
    neg.failures AS negative_failures,
    hashes.*,
    CASE
        WHEN r.run_status='M1_13_ACCEPTED'
         AND gate.result_status='PASS'
         AND pos.checks=82 AND pos.passes=82 AND pos.failures=0
         AND neg.controls=7 AND neg.passes=7 AND neg.failures=0
         AND summary.snapshots=1500
         AND summary.applications=750
         AND summary.scenarios=2
         AND hashes.mismatch_count=0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS overall_m1_13_status
FROM r
CROSS JOIN gate
CROSS JOIN pos
CROSS JOIN neg
CROSS JOIN summary
CROSS JOIN scenario
CROSS JOIN hashes
CROSS JOIN path
CROSS JOIN policy;
