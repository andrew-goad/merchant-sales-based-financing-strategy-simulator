/* ============================================================================
M1.13 v0.2R1 BOOLEAN-PARAMETER AGGREGATION HOTFIX
Source  : 99_MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2.sql
Role    : Detailed report; executable logic unchanged from v0.2.
Revision: File name is version-aligned to v0.2R1. Except where explicitly
          documented in HOTFIX_NOTES_v0_2R1.md, executable logic is unchanged.
============================================================================ */

/* ============================================================================
MSBF M1.13 Exposure, Recovery & Expected Loss Foundations — Detail Report
Version : v0.2
Purpose : Produce the complete technical evidence package for daily exposure
          paths, recovery/LGD assumptions, comparative loss measures, matched
          stress migration, routing, lineage, deterministic reconciliation,
          and stage boundaries.
Mode    : Read-only after M1.13 acceptance.
Output  : Twenty labeled result sets. Working tables use ON COMMIT PRESERVE ROWS
          so DBeaver result grids remain filterable within the current session.
============================================================================ */

BEGIN;
SET LOCAL work_mem='128MB';
SET LOCAL jit=off;
SET LOCAL statement_timeout='20min';

DROP TABLE IF EXISTS _m1_13_detail_loss;
DROP TABLE IF EXISTS _m1_13_detail_path;
DROP TABLE IF EXISTS _m1_13_detail_actual;
DROP TABLE IF EXISTS _m1_13_detail_mismatch;

CREATE TEMP TABLE _m1_13_detail_loss
ON COMMIT PRESERVE ROWS AS
SELECT
    l.*,
    sr.scenario_code,
    a.partner_channel_id,
    r.relationship_stage,
    r.merchant_size_tier
FROM msbf_m1.application_exposure_recovery_loss_snapshot l
JOIN msbf_ctl.scenario_registry sr
  ON sr.scenario_id = l.scenario_id
JOIN msbf_m1.merchant_application a
  ON a.merchant_application_id = l.merchant_application_id
JOIN msbf_m1.application_integrated_risk_proxy_snapshot r
  ON r.module1_run_id = l.module1_run_id
 AND r.scenario_id = l.scenario_id
 AND r.merchant_application_id = l.merchant_application_id
WHERE l.module1_run_id=(
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
);
CREATE INDEX ON _m1_13_detail_loss(scenario_code,loss_evidence_status);
CREATE INDEX ON _m1_13_detail_loss(industry_code,integrated_risk_tier);
CREATE INDEX ON _m1_13_detail_loss(partner_channel_id,relationship_stage);

CREATE TEMP TABLE _m1_13_detail_path
ON COMMIT PRESERVE ROWS AS
SELECT p.*,sr.scenario_code,l.industry_code,l.integrated_risk_tier
FROM msbf_m1.application_ead_path_value p
JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
JOIN msbf_m1.application_exposure_recovery_loss_snapshot l
  USING(module1_run_id,scenario_id,merchant_application_id)
WHERE p.module1_run_id=(
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
);
CREATE INDEX ON _m1_13_detail_path(scenario_code,path_bucket);
CREATE INDEX ON _m1_13_detail_path(merchant_application_id,scenario_id,path_day);

CREATE TEMP TABLE _m1_13_detail_actual
ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.m1_13_actual_path_snapshot((
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
))
UNION ALL
SELECT * FROM msbf_m1.m1_13_actual_loss_snapshot((
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
));
CREATE UNIQUE INDEX ON _m1_13_detail_actual(entity_key);

CREATE TEMP TABLE _m1_13_detail_mismatch
ON COMMIT PRESERVE ROWS AS
WITH stored AS (
    SELECT
        'PATH|'||scenario_id||'|'||merchant_application_id||'|'||path_day AS entity_key,
        path_hash AS stored_hash
    FROM msbf_m1.application_ead_path_value
    WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_13_detail_loss)
    UNION ALL
    SELECT
        'LOSS|'||scenario_id||'|'||merchant_application_id AS entity_key,
        row_hash AS stored_hash
    FROM msbf_m1.application_exposure_recovery_loss_snapshot
    WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_13_detail_loss)
)
SELECT
    coalesce(s.entity_key,a.entity_key) AS entity_key,
    s.stored_hash,
    a.row_hash AS independently_recomputed_hash
FROM stored s
FULL JOIN _m1_13_detail_actual a USING(entity_key)
WHERE s.stored_hash IS DISTINCT FROM a.row_hash;

COMMIT;

/* 01 — Run and Acceptance State */
SELECT
    r.run_id,r.run_status,r.population_id,r.as_of_date,
    g.gate_id,g.review_version,g.result_status,g.reviewed_at,
    p.status AS policy_status,
    p.profile_payload->>'methodology_version' AS methodology_version,
    p.profile_payload->>'exposure_basis_code' AS exposure_basis_code,
    p.profile_payload->>'ead_method_code' AS ead_method_code,
    p.profile_payload->>'risk_proxy_basis_code' AS risk_proxy_basis_code
FROM msbf_ctl.run_registry r
JOIN LATERAL (
    SELECT * FROM msbf_ctl.acceptance_gate_result x
    WHERE x.run_id=r.run_id
      AND x.gate_id='M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
    ORDER BY review_version DESC LIMIT 1
) g ON true
JOIN msbf_ctl.policy_profile p
  ON p.profile_code='M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
 AND p.profile_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

/* 02 — Entity and Stage-Boundary Row Counts */
SELECT 'ead_path_rows' AS entity,count(*) AS row_count FROM _m1_13_detail_path
UNION ALL SELECT 'loss_snapshots',count(*) FROM _m1_13_detail_loss
UNION ALL SELECT 'applications',count(DISTINCT merchant_application_id) FROM _m1_13_detail_loss
UNION ALL SELECT 'scenarios',count(DISTINCT scenario_id) FROM _m1_13_detail_loss
UNION ALL SELECT 'merchant_risk_snapshot_downstream',count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_13_detail_loss)
UNION ALL SELECT 'risk_component_detail_downstream',count(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_13_detail_loss)
UNION ALL SELECT 'ead_path_snapshot_downstream',count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_13_detail_loss)
UNION ALL SELECT 'module1_latest_downstream',count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_13_detail_loss)
UNION ALL SELECT 'module1_archive_downstream',count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_13_detail_loss);

/* 03 — Governed Methodology and Frozen Parameters */
SELECT
    p.profile_payload->>'methodology_version' AS methodology_version,
    p.profile_payload->>'exposure_basis_code' AS exposure_basis_code,
    p.profile_payload->>'ead_method_code' AS ead_method_code,
    p.profile_payload->>'default_timing_basis_code' AS default_timing_basis_code,
    p.profile_payload->>'risk_proxy_basis_code' AS risk_proxy_basis_code,
    p.profile_payload->>'stress_ead_floor_to_baseline' AS stress_ead_floor,
    p.profile_payload->>'stress_lgd_floor_to_baseline' AS stress_lgd_floor,
    p.profile_payload->>'stress_loss_floor_to_baseline' AS stress_loss_floor,
    ps.parameter_name,ps.scope_key,ps.resolved_value
FROM msbf_ctl.policy_profile p
CROSS JOIN msbf_ctl.run_parameter_snapshot ps
WHERE p.profile_code='M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
  AND p.profile_version=1
  AND ps.run_id=(SELECT min(module1_run_id) FROM _m1_13_detail_loss)
  AND ps.parameter_name IN (
      'ead_method_code','default_timing_weight','paydown_curve_shape',
      'industry_lgd_baseline','collateral_availability_lgd_haircut',
      'guarantee_availability_lgd_haircut','lgd_floor','lgd_cap',
      'expected_loss_tolerance_amount','ead_weight_tolerance',
      'simple_el_publish_flag','schedule_adjusted_el_publish_flag'
  )
ORDER BY ps.parameter_name,ps.scope_key;

/* 04 — Exposure Path Summary by Scenario */
SELECT
    scenario_code,
    count(*) AS path_rows,
    count(DISTINCT merchant_application_id) AS applications,
    round(avg(beginning_exposure_amount),2) AS avg_beginning_exposure,
    round(avg(ending_exposure_amount),2) AS avg_ending_exposure,
    round(sum(weighted_ead_amount),2) AS total_weighted_ead,
    round(avg(default_timing_weight),10) AS avg_timing_weight
FROM _m1_13_detail_path
GROUP BY scenario_code
ORDER BY scenario_code;

/* 05 — Default-Timing Bucket Diagnostics */
SELECT
    scenario_code,path_bucket,
    count(*) AS path_rows,
    count(DISTINCT merchant_application_id) AS applications,
    round(sum(default_timing_weight),10) AS total_timing_weight,
    round(sum(weighted_ead_amount),2) AS total_weighted_ead,
    round(avg(beginning_exposure_amount),2) AS avg_beginning_exposure
FROM _m1_13_detail_path
GROUP BY scenario_code,path_bucket
ORDER BY scenario_code,path_bucket;

/* 06 — Payoff-Horizon and Paydown-Curve Diagnostics */
SELECT
    scenario_code,requested_expected_payoff_days,paydown_curve_shape,
    count(*) AS applications,
    round(avg(initial_receivable_exposure_amount),2) AS avg_initial_exposure,
    round(avg(governed_path_daily_payment),2) AS avg_governed_daily_payment,
    round(avg(path_weighted_ead_amount),2) AS avg_path_weighted_ead,
    round(avg(expected_ead_rate),8) AS avg_ead_rate
FROM _m1_13_detail_loss
GROUP BY scenario_code,requested_expected_payoff_days,paydown_curve_shape
ORDER BY scenario_code,requested_expected_payoff_days;

/* 07 — Industry EAD, LGD, and Comparative Loss Diagnostics */
SELECT
    scenario_code,industry_code,
    count(*) AS applications,
    round(avg(expected_ead_rate),8) AS avg_ead_rate,
    round(avg(industry_lgd_baseline_rate),8) AS avg_industry_lgd,
    round(avg(scenario_lgd_addon_rate),8) AS avg_stress_addon,
    round(avg(lgd_input_rate),8) AS avg_lgd_input,
    round(avg(recovery_rate_assumption),8) AS avg_recovery_rate,
    round(sum(schedule_adjusted_comparative_expected_loss_amount),2) AS total_schedule_loss
FROM _m1_13_detail_loss
GROUP BY scenario_code,industry_code
ORDER BY scenario_code,total_schedule_loss DESC NULLS LAST,industry_code;

/* 08 — Recovery Evidence and Basis Distribution */
SELECT
    scenario_code,recovery_evidence_status,recovery_basis_code,
    count(*) AS applications,
    round(avg(total_recovery_credit_rate),8) AS avg_recovery_credit,
    round(avg(lgd_input_rate),8) AS avg_lgd,
    round(avg(recovery_rate_assumption),8) AS avg_recovery_rate
FROM _m1_13_detail_loss
GROUP BY scenario_code,recovery_evidence_status,recovery_basis_code
ORDER BY scenario_code,recovery_evidence_status,recovery_basis_code;

/* 09 — Collateral and Guarantee Diagnostics */
SELECT
    scenario_code,
    CASE
      WHEN collateral_available_value>0 AND guarantee_capacity_amount>0 THEN 'COLLATERAL_AND_GUARANTEE'
      WHEN collateral_available_value>0 THEN 'COLLATERAL_ONLY'
      WHEN guarantee_capacity_amount>0 THEN 'GUARANTEE_ONLY'
      ELSE 'NO_SUPPORTED_RECOVERY_ASSET'
    END AS recovery_support_type,
    count(*) AS applications,
    round(avg(collateral_available_value),2) AS avg_collateral_value,
    round(avg(guarantee_capacity_amount),2) AS avg_guarantee_capacity,
    round(avg(total_recovery_credit_rate),8) AS avg_total_credit,
    round(avg(lgd_input_rate),8) AS avg_lgd
FROM _m1_13_detail_loss
GROUP BY scenario_code,recovery_support_type
ORDER BY scenario_code,recovery_support_type;

/* 10 — Integrated Risk Tier and Loss Diagnostics */
SELECT
    scenario_code,integrated_risk_tier,
    count(*) AS applications,
    round(avg(synthetic_merchant_risk_proxy),8) AS avg_synthetic_proxy,
    round(avg(expected_ead_rate),8) AS avg_ead_rate,
    round(avg(lgd_input_rate),8) AS avg_lgd,
    round(avg(schedule_adjusted_comparative_loss_rate),8) AS avg_schedule_loss_rate,
    round(sum(schedule_adjusted_comparative_expected_loss_amount),2) AS total_schedule_loss
FROM _m1_13_detail_loss
GROUP BY scenario_code,integrated_risk_tier
ORDER BY scenario_code,integrated_risk_tier;

/* 11 — Loss Evidence Status Distribution */
SELECT
    scenario_code,loss_evidence_status,
    count(*) AS applications,
    count(*) FILTER(WHERE manual_review_recommended_flag) AS manual_review_rows,
    count(*) FILTER(WHERE hard_stop_recommended_flag) AS hard_stop_rows,
    round(avg(expected_ead_rate),8) AS avg_ead_rate,
    round(avg(lgd_input_rate),8) AS avg_lgd
FROM _m1_13_detail_loss
GROUP BY scenario_code,loss_evidence_status
ORDER BY scenario_code,loss_evidence_status;

/* 12 — Comparative Loss Summary */
SELECT
    scenario_code,
    count(*) FILTER(WHERE simple_comparative_expected_loss_amount IS NOT NULL) AS scored_rows,
    round(sum(initial_receivable_exposure_amount),2) AS total_initial_exposure,
    round(sum(path_weighted_ead_amount),2) AS total_path_weighted_ead,
    round(sum(simple_comparative_expected_loss_amount),2) AS total_simple_loss,
    round(sum(schedule_adjusted_comparative_expected_loss_amount),2) AS total_schedule_loss,
    round(avg(simple_comparative_loss_rate),8) AS avg_simple_loss_rate,
    round(avg(schedule_adjusted_comparative_loss_rate),8) AS avg_schedule_loss_rate
FROM _m1_13_detail_loss
GROUP BY scenario_code
ORDER BY scenario_code;

/* 13 — Matched Stress Migration */
SELECT
    b.integrated_risk_tier,
    b.loss_evidence_status AS baseline_evidence_status,
    s.loss_evidence_status AS stress_evidence_status,
    count(*) AS applications,
    count(*) FILTER(WHERE s.path_weighted_ead_amount>b.path_weighted_ead_amount) AS ead_worsening_apps,
    count(*) FILTER(WHERE s.lgd_input_rate>b.lgd_input_rate) AS lgd_worsening_apps,
    count(*) FILTER(WHERE s.schedule_adjusted_comparative_expected_loss_amount>b.schedule_adjusted_comparative_expected_loss_amount) AS loss_worsening_apps,
    round(avg(s.path_weighted_ead_amount-b.path_weighted_ead_amount),2) AS avg_ead_delta,
    round(avg(s.lgd_input_rate-b.lgd_input_rate),8) AS avg_lgd_delta,
    round(avg(s.schedule_adjusted_comparative_expected_loss_amount-b.schedule_adjusted_comparative_expected_loss_amount),2) AS avg_loss_delta
FROM _m1_13_detail_loss b
JOIN _m1_13_detail_loss s
  ON s.merchant_application_id=b.merchant_application_id
 AND s.scenario_code='RECESSION_ENERGY'
WHERE b.scenario_code='BASELINE'
GROUP BY b.integrated_risk_tier,b.loss_evidence_status,s.loss_evidence_status
ORDER BY b.integrated_risk_tier,b.loss_evidence_status,s.loss_evidence_status;

/* 14 — Review, Fallback, and Reason Diagnostics */
SELECT
    scenario_code,fallback_path_code,primary_loss_reason_code,
    count(*) AS applications,
    count(*) FILTER(WHERE manual_review_recommended_flag) AS manual_review_rows,
    count(*) FILTER(WHERE hard_stop_recommended_flag) AS hard_stop_rows,
    round(avg(lgd_input_rate),8) AS avg_lgd,
    round(avg(schedule_adjusted_comparative_loss_rate),8) AS avg_schedule_loss_rate
FROM _m1_13_detail_loss
GROUP BY scenario_code,fallback_path_code,primary_loss_reason_code
ORDER BY scenario_code,applications DESC,fallback_path_code,primary_loss_reason_code;

/* 15 — Partner-Channel Diagnostics */
SELECT
    scenario_code,coalesce(partner_channel_id,'DIRECT_OR_UNASSIGNED') AS partner_channel_id,
    count(*) AS applications,
    round(avg(expected_ead_rate),8) AS avg_ead_rate,
    round(avg(lgd_input_rate),8) AS avg_lgd,
    round(sum(schedule_adjusted_comparative_expected_loss_amount),2) AS total_schedule_loss,
    count(*) FILTER(WHERE manual_review_recommended_flag) AS manual_review_rows
FROM _m1_13_detail_loss
GROUP BY scenario_code,coalesce(partner_channel_id,'DIRECT_OR_UNASSIGNED')
ORDER BY scenario_code,applications DESC,partner_channel_id;

/* 16 — Relationship Stage and Merchant Size Diagnostics */
SELECT
    scenario_code,merchant_size_tier,relationship_stage,
    count(*) AS applications,
    round(avg(initial_receivable_exposure_amount),2) AS avg_initial_exposure,
    round(avg(expected_ead_rate),8) AS avg_ead_rate,
    round(avg(lgd_input_rate),8) AS avg_lgd,
    round(avg(schedule_adjusted_comparative_loss_rate),8) AS avg_schedule_loss_rate
FROM _m1_13_detail_loss
GROUP BY scenario_code,merchant_size_tier,relationship_stage
ORDER BY scenario_code,merchant_size_tier,relationship_stage;

/* 17 — Sample Matched Application Profiles */
WITH ranked AS (
    SELECT l.*,
           row_number() OVER(
               PARTITION BY scenario_code
               ORDER BY schedule_adjusted_comparative_expected_loss_amount DESC NULLS LAST,
                        merchant_application_id
           ) AS rn
    FROM _m1_13_detail_loss l
)
SELECT
    scenario_code,merchant_application_id,merchant_id,industry_code,
    integrated_risk_tier,loss_evidence_status,recovery_evidence_status,
    initial_receivable_exposure_amount,path_weighted_ead_amount,expected_ead_rate,
    lgd_input_rate,recovery_rate_assumption,
    simple_comparative_expected_loss_amount,
    schedule_adjusted_comparative_expected_loss_amount,
    fallback_path_code,primary_loss_reason_code,
    manual_review_recommended_flag,hard_stop_recommended_flag
FROM ranked
WHERE rn<=20
ORDER BY scenario_code,rn;

/* 18 — M1.13 Governed Evidence */
SELECT
    evidence_code,segment_key,metric_name,
    metric_value_numeric,metric_value_text,unit_code,status,
    threshold_value_numeric,interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT min(module1_run_id) FROM _m1_13_detail_loss)
  AND evidence_code LIKE 'M1_13_%'
ORDER BY evidence_code,segment_key;

/* 19 — Row-Level Deterministic Mismatches (must return zero rows) */
SELECT * FROM _m1_13_detail_mismatch ORDER BY entity_key;

/* 20 — Blocking Resolution Errors (must return zero rows) */
SELECT
    resolution_error_id,run_id,profile_domain,scope_key,error_code,
    severity,error_message,created_at
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT min(module1_run_id) FROM _m1_13_detail_loss)
  AND severity='BLOCKING'
ORDER BY resolution_error_id;
