/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 171_MSBF_M2_5_Detail_Report_v0_2.sql
Version     : v0.2

Purpose
-------
Return twenty-four governed read-only evidence result sets covering lifecycle,
policy, dictionaries, source lineage, daily remittance/exposure behavior,
latest status, alerts, portfolio trends, stress comparisons, deterministic
identity, and monitoring-only stage boundaries.

Required result
---------------
Result Sets 23 and 24 retain headers and contain zero data rows.
============================================================================ */

SET statement_timeout='35min';
SET jit=off;

DROP TABLE IF EXISTS _m2_5_dctx;

CREATE TEMP TABLE _m2_5_dctx
ON COMMIT PRESERVE ROWS
AS
SELECT run_id
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD'
  AND run_version=1;

CREATE INDEX ON _m2_5_dctx(run_id);
ANALYZE _m2_5_dctx;

/* Result Set 01 — Run, Contract Lifecycle and Acceptance Gate */
SELECT
    run.run_id,run.run_code,run.run_version,run.run_status,
    registry.contract_code,registry.contract_version,registry.schema_version,
    registry.contract_status,gate.gate_id,gate.result_status AS gate_status,
    registry.generated_at,registry.validated_at,registry.accepted_at
FROM msbf_ctl.run_registry AS run
JOIN msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS registry
  ON registry.module1_run_id=run.run_id
LEFT JOIN msbf_ctl.acceptance_gate_result AS gate
  ON gate.run_id=run.run_id
 AND gate.gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
 AND gate.review_version=1
WHERE run.run_id=(SELECT run_id FROM _m2_5_dctx);

/* Result Set 02 — Policy, Source Boundary and Monitoring-Only Controls */
SELECT
    policy_code,policy_version,policy_status,methodology_version,
    contract_code,contract_version,schema_version,
    source_m2_4_contract_code,source_m2_4_contract_version,
    source_m2_4_schema_version,source_m2_4_combined_hash,
    source_m2_4_acceptance_gate_id,source_m1_6_acceptance_gate_id,
    source_m1_6_combined_hash,monitoring_horizon_days,source_replay_days,
    watch_start_day,underperforming_start_day,severe_start_day,
    watch_pace_ratio,underperforming_pace_ratio,severe_pace_ratio,
    watch_daily_coverage_ratio,underperforming_no_remittance_days,
    dormant_no_remittance_days,severe_zero_sales_streak_days,
    low_liquidity_available_balance,retain_post_payoff_rows_flag,
    stress_status_nonimprovement_required_flag,synthetic_data_only_flag,
    no_real_debit_instruction_flag,no_external_notice_generation_flag,
    no_production_adverse_action_notice_flag,
    no_write_off_or_restructure_action_flag,
    monitoring_only_no_servicing_action_flag,configuration_hash
FROM msbf_ctl.m2_5_policy_profile
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx);

/* Result Set 03 — Monitoring Status Definitions */
SELECT
    monitoring_status_code,monitoring_status_rank,watch_flag,
    underperforming_flag,severe_shortfall_flag,dormant_flag,paid_off_flag,
    status_active_flag,description,row_hash
FROM msbf_m2.portfolio_monitoring_status_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
ORDER BY monitoring_status_rank;

/* Result Set 04 — Monitoring Alert Definitions */
SELECT
    monitoring_alert_code,alert_rank,severity_code,alert_active_flag,
    description,row_hash
FROM msbf_m2.portfolio_monitoring_alert_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
ORDER BY alert_rank;

/* Result Set 05 — Monitoring Reason Definitions */
SELECT
    monitoring_reason_code,mapped_monitoring_status_code,
    production_adverse_action_notice_flag,
    servicing_action_authorized_flag,reason_active_flag,description,row_hash
FROM msbf_m2.portfolio_monitoring_reason_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
ORDER BY monitoring_reason_code;

/* Result Set 06 — Entity Cardinality and Governed Grains */
SELECT
    policy_rows,status_rows,alert_rows,reason_rows,source_rows,daily_rows,
    latest_rows,archive_rows,portfolio_daily_rows,comparison_rows,
    registry_rows,canonical_entities
FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx);

/* Result Set 07 — Activated Source Population */
SELECT
    scenario_code,
    count(*) AS monitored_advances,
    round(sum(funded_amount),2) AS funded_amount,
    round(sum(total_repayment_amount),2) AS opening_receivable_amount,
    round(avg(remittance_rate),6) AS average_remittance_rate,
    round(avg(collection_horizon_days),2) AS average_collection_horizon_days
FROM msbf_m2.advance_monitoring_source_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
GROUP BY scenario_code
ORDER BY scenario_code;

/* Result Set 08 — Accepted M1.6 Source Replay Coverage */
SELECT
    scenario_code,
    count(DISTINCT synthetic_advance_id) AS advances,
    count(*) AS daily_rows,
    min(source_observation_date) AS first_source_observation_date,
    max(source_observation_date) AS last_source_observation_date,
    count(DISTINCT source_observation_date) AS distinct_source_dates,
    count(DISTINCT source_pos_set_hash) AS distinct_pos_set_hashes,
    count(DISTINCT source_deposit_row_hash) AS distinct_deposit_row_hashes
FROM msbf_m2.advance_daily_remittance_monitoring
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
GROUP BY scenario_code
ORDER BY scenario_code;

/* Result Set 09 — Latest Monitoring Status Distribution by Scenario */
SELECT
    scenario_code,latest_monitoring_status_code,latest_monitoring_status_rank,
    paid_off_flag,count(*) AS advances,
    round(sum(cumulative_remittance_amount),2) AS cumulative_remittance_amount,
    round(sum(remaining_receivable_amount),2) AS remaining_receivable_amount
FROM msbf_m2.advance_portfolio_monitoring_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
GROUP BY scenario_code,latest_monitoring_status_code,
         latest_monitoring_status_rank,paid_off_flag
ORDER BY scenario_code,latest_monitoring_status_rank;

/* Result Set 10 — Daily Remittance Distribution */
SELECT
    scenario_code,
    count(*) AS daily_rows,
    round(sum(source_eligible_pos_sales),2) AS eligible_pos_sales,
    round(sum(expected_due_today_amount),2) AS expected_due_amount,
    round(sum(raw_remittance_amount),2) AS raw_remittance_amount,
    round(sum(actual_remittance_amount),2) AS actual_remittance_amount,
    round(avg(remittance_coverage_ratio),8) AS average_daily_coverage_ratio,
    count(*) FILTER(WHERE actual_remittance_amount=0) AS zero_remittance_rows
FROM msbf_m2.advance_daily_remittance_monitoring
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
GROUP BY scenario_code
ORDER BY scenario_code;

/* Result Set 11 — Daily Pace and Exposure Diagnostics */
SELECT
    scenario_code,monitoring_day_index,
    count(*) AS advances,
    round(sum(cumulative_remittance_amount),2) AS cumulative_remittance_amount,
    round(sum(cumulative_expected_remittance_amount),2)
        AS cumulative_expected_remittance_amount,
    round(sum(cumulative_shortfall_amount),2) AS cumulative_shortfall_amount,
    round(sum(receivable_balance_after),2) AS receivable_exposure_amount,
    round(sum(principal_exposure_proxy),2) AS principal_exposure_proxy,
    round(avg(cumulative_pace_ratio),8) AS average_pace_ratio
FROM msbf_m2.advance_daily_remittance_monitoring
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
  AND monitoring_day_index IN(1,7,14,30,60,90,120)
GROUP BY scenario_code,monitoring_day_index
ORDER BY scenario_code,monitoring_day_index;

/* Result Set 12 — Alert Distribution */
SELECT
    scenario_code,
    sum(daily_shortfall_alert_flag::integer) AS daily_shortfall_alert_rows,
    sum(cumulative_pace_watch_alert_flag::integer) AS pace_watch_alert_rows,
    sum(cumulative_pace_high_alert_flag::integer) AS pace_high_alert_rows,
    sum(zero_sales_streak_alert_flag::integer) AS zero_sales_alert_rows,
    sum(liquidity_stress_alert_flag::integer) AS liquidity_alert_rows,
    sum(horizon_overrun_alert_flag::integer) AS horizon_overrun_alert_rows,
    sum(stress_status_floor_applied_flag::integer) AS stress_floor_rows
FROM msbf_m2.advance_daily_remittance_monitoring
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
GROUP BY scenario_code
ORDER BY scenario_code;

/* Result Set 13 — Payoff and Open Exposure */
SELECT
    scenario_code,
    count(*) FILTER(WHERE paid_off_flag) AS paid_off_advances,
    count(*) FILTER(WHERE NOT paid_off_flag) AS open_advances,
    min(payoff_day_index) FILTER(WHERE paid_off_flag) AS earliest_payoff_day,
    max(payoff_day_index) FILTER(WHERE paid_off_flag) AS latest_payoff_day,
    round(sum(cumulative_remittance_amount),2) AS cumulative_remittance_amount,
    round(sum(remaining_receivable_amount),2) AS remaining_receivable_amount,
    round(sum(principal_exposure_proxy),2) AS principal_exposure_proxy,
    round(sum(unearned_finance_charge_proxy),2)
        AS unearned_finance_charge_proxy
FROM msbf_m2.advance_portfolio_monitoring_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
GROUP BY scenario_code
ORDER BY scenario_code;

/* Result Set 14 — Zero-Sales and Liquidity Diagnostics */
SELECT
    scenario_code,
    max(zero_sales_streak_days) AS maximum_zero_sales_streak_days,
    max(days_since_last_positive_remittance)
        AS maximum_days_since_positive_remittance,
    min(current_available_balance) AS minimum_available_balance,
    max(current_nsf_count) AS maximum_nsf_count,
    count(*) FILTER(WHERE current_available_balance<0) AS negative_balance_advances,
    count(*) FILTER(WHERE current_nsf_count>0) AS nsf_advances
FROM msbf_m2.advance_portfolio_monitoring_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
GROUP BY scenario_code
ORDER BY scenario_code;

/* Result Set 15 — Portfolio Daily Trend */
SELECT
    scenario_code,monitoring_day_index,monitoring_date,
    opening_advance_count,active_advance_count,paid_off_count,
    current_count,watch_count,underperforming_count,
    severe_shortfall_count,dormant_no_remittance_count,
    daily_eligible_pos_sales,daily_remittance_amount,
    cumulative_remittance_amount,cumulative_expected_remittance_amount,
    cumulative_shortfall_amount,total_receivable_exposure_amount,
    total_principal_exposure_proxy,portfolio_pace_ratio,
    stress_status_floor_rows
FROM msbf_m2.portfolio_daily_monitoring_summary
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
ORDER BY scenario_code,monitoring_day_index;

/* Result Set 16 — Source-to-Monitoring Lineage */
SELECT
    latest.scenario_code,latest.merchant_application_id,
    latest.synthetic_account_id,latest.synthetic_advance_id,
    latest.latest_monitoring_status_code,latest.source_daily_row_hash,
    latest.source_m2_4_contract_row_hash,latest.source_advance_row_hash,
    latest.source_portfolio_row_hash,latest.contract_row_hash
FROM msbf_m2.advance_portfolio_monitoring_latest AS latest
WHERE latest.module1_run_id=(SELECT run_id FROM _m2_5_dctx)
ORDER BY latest.scenario_code,latest.merchant_application_id;

/* Result Set 17 — Latest / Archive Reproduction */
SELECT
    count(*) AS joined_rows,
    count(*) FILTER
    (
        WHERE latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash
           OR archive.contract_payload IS DISTINCT FROM
              (to_jsonb(latest)-'created_at')
    ) AS reproduction_mismatches
FROM msbf_m2.advance_portfolio_monitoring_latest AS latest
FULL OUTER JOIN msbf_m2.advance_portfolio_monitoring_archive AS archive
  ON archive.module1_run_id=latest.module1_run_id
 AND archive.contract_version=latest.contract_version
 AND archive.scenario_id=latest.scenario_id
 AND archive.merchant_application_id=latest.merchant_application_id
WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=
      (SELECT run_id FROM _m2_5_dctx);

/* Result Set 18 — Matched Baseline / Stress Status Migration */
SELECT
    baseline_monitoring_status_code,stress_monitoring_status_code,
    count(*) AS matched_applications,
    count(*) FILTER(WHERE stress_status_improvement_flag)
        AS stress_status_improvements,
    count(*) FILTER(WHERE stress_floor_flag) AS stress_floor_latest_rows,
    count(*) FILTER(WHERE baseline_paid_off_flag) AS baseline_paid_off_rows,
    count(*) FILTER(WHERE stress_paid_off_flag) AS stress_paid_off_rows
FROM msbf_m2.v_m2_5_matched_monitoring_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
GROUP BY baseline_monitoring_status_code,stress_monitoring_status_code
ORDER BY baseline_monitoring_status_code,stress_monitoring_status_code;

/* Result Set 19 — Stress Floor Diagnostics */
SELECT
    count(*) AS matched_applications,
    count(*) FILTER(WHERE stress_status_improvement_flag)
        AS stress_status_improvements,
    count(*) FILTER(WHERE stress_floor_flag) AS latest_stress_floor_rows,
    count(*) FILTER
    (
        WHERE stress_monitoring_status_rank>=baseline_monitoring_status_rank
           OR baseline_paid_off_flag
           OR stress_paid_off_flag
    ) AS nonimprovement_rows,
    (SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring
     WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
       AND stress_status_floor_applied_flag) AS daily_stress_floor_rows
FROM msbf_m2.v_m2_5_matched_monitoring_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx);

/* Result Set 20 — Contract Registry and Hash Summary */
SELECT
    registry.registry_id,
    registry.module1_run_id,
    registry.contract_code,
    registry.contract_version,
    registry.schema_version,
    registry.methodology_version,
    registry.source_m2_4_contract_code,
    registry.source_m2_4_contract_version,
    registry.source_m2_4_schema_version,
    registry.source_m2_4_combined_hash,
    registry.source_m2_4_acceptance_gate_id,
    registry.source_m1_6_acceptance_gate_id,
    registry.source_m1_6_combined_hash,
    registry.policy_configuration_hash,
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
    registry.registry_rows,
    registry.canonical_entities,
    registry.paid_off_rows,
    registry.open_monitoring_rows,
    registry.stress_status_floor_rows,
    registry.total_remittance_amount,
    registry.ending_receivable_exposure_amount,
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
    registry.contract_status,
    registry.generated_at,
    registry.validated_at,
    registry.accepted_at,
    registry.row_hash,
    registry.created_at
FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS registry
WHERE registry.module1_run_id=(SELECT run_id FROM _m2_5_dctx);

/* Result Set 21 — Governed Evidence Summary */
SELECT
    CASE
        WHEN evidence_code LIKE 'M2_5_POS_%' THEN 'POSITIVE_VALIDATION'
        WHEN evidence_code LIKE 'M2_5_NEG_%' THEN 'NEGATIVE_CONTROL'
        WHEN evidence_code='M2_5_ACCEPTANCE_SUMMARY' THEN 'ACCEPTANCE'
        ELSE 'GENERATION'
    END AS evidence_family,
    status,
    count(*) AS evidence_rows
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m2_5_dctx)
  AND evidence_code LIKE 'M2_5_%'
GROUP BY evidence_family,status
ORDER BY evidence_family,status;

/* Result Set 22 — Sample Monitoring Profiles */
SELECT
    scenario_code,merchant_application_id,synthetic_advance_id,
    latest_monitoring_status_code,paid_off_flag,payoff_day_index,
    cumulative_remittance_amount,remaining_receivable_amount,
    cumulative_expected_remittance_amount,cumulative_shortfall_amount,
    cumulative_pace_ratio,trailing_7_day_remittance_amount,
    trailing_30_day_remittance_amount,days_since_last_positive_remittance,
    zero_sales_streak_days,current_available_balance,current_nsf_count,
    active_alert_count,primary_monitoring_reason_code
FROM msbf_m2.advance_portfolio_monitoring_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
ORDER BY scenario_code,latest_monitoring_status_rank DESC,
         remaining_receivable_amount DESC,merchant_application_id
LIMIT 100;

/* Result Set 23 — Deterministic Mismatches */
WITH mismatches AS
(
    SELECT
        'POLICY'::text AS entity_type,
        policy.policy_code || '|v' || policy.policy_version::text AS entity_key,
        policy.row_hash AS stored_hash,
        msbf_ctl.m2_5_hash_jsonb
        (
            to_jsonb(policy)-'row_hash'-'created_at'-'updated_at'
        ) AS reconstructed_hash
    FROM msbf_ctl.m2_5_policy_profile AS policy
    WHERE policy.module1_run_id=(SELECT run_id FROM _m2_5_dctx)

    UNION ALL

    SELECT
        'STATUS',status.monitoring_status_code,status.row_hash,
        msbf_ctl.m2_5_hash_jsonb(to_jsonb(status)-'row_hash'-'created_at')
    FROM msbf_m2.portfolio_monitoring_status_definition AS status
    WHERE status.module1_run_id=(SELECT run_id FROM _m2_5_dctx)

    UNION ALL

    SELECT
        'ALERT',alert.monitoring_alert_code,alert.row_hash,
        msbf_ctl.m2_5_hash_jsonb(to_jsonb(alert)-'row_hash'-'created_at')
    FROM msbf_m2.portfolio_monitoring_alert_definition AS alert
    WHERE alert.module1_run_id=(SELECT run_id FROM _m2_5_dctx)

    UNION ALL

    SELECT
        'REASON',reason.monitoring_reason_code,reason.row_hash,
        msbf_ctl.m2_5_hash_jsonb(to_jsonb(reason)-'row_hash'-'created_at')
    FROM msbf_m2.portfolio_monitoring_reason_definition AS reason
    WHERE reason.module1_run_id=(SELECT run_id FROM _m2_5_dctx)

    UNION ALL

    SELECT
        'SOURCE',source.scenario_id::text || '|' || source.merchant_application_id,
        source.row_hash,
        msbf_ctl.m2_5_hash_jsonb(to_jsonb(source)-'row_hash'-'created_at')
    FROM msbf_m2.advance_monitoring_source_snapshot AS source
    WHERE source.module1_run_id=(SELECT run_id FROM _m2_5_dctx)

    UNION ALL

    SELECT
        'DAILY',daily.scenario_id::text || '|' || daily.merchant_application_id || '|' || daily.monitoring_day_index::text,
        daily.row_hash,
        msbf_ctl.m2_5_hash_jsonb(to_jsonb(daily)-'row_hash'-'created_at')
    FROM msbf_m2.advance_daily_remittance_monitoring AS daily
    WHERE daily.module1_run_id=(SELECT run_id FROM _m2_5_dctx)

    UNION ALL

    SELECT
        'LATEST',latest.scenario_id::text || '|' || latest.merchant_application_id,
        latest.contract_row_hash,
        msbf_ctl.m2_5_hash_jsonb
        (
            to_jsonb(latest)-'contract_row_hash'-'created_at'
        )
    FROM msbf_m2.advance_portfolio_monitoring_latest AS latest
    WHERE latest.module1_run_id=(SELECT run_id FROM _m2_5_dctx)

    UNION ALL

    SELECT
        'ARCHIVE',archive.scenario_id::text || '|' || archive.merchant_application_id,
        archive.archive_row_hash,
        msbf_ctl.m2_5_hash_jsonb
        (
            to_jsonb(archive)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'
        )
    FROM msbf_m2.advance_portfolio_monitoring_archive AS archive
    WHERE archive.module1_run_id=(SELECT run_id FROM _m2_5_dctx)

    UNION ALL

    SELECT
        'PORTFOLIO_DAILY',summary.scenario_id::text || '|' || summary.monitoring_day_index::text,
        summary.row_hash,
        msbf_ctl.m2_5_hash_jsonb(to_jsonb(summary)-'row_hash'-'created_at')
    FROM msbf_m2.portfolio_daily_monitoring_summary AS summary
    WHERE summary.module1_run_id=(SELECT run_id FROM _m2_5_dctx)

    UNION ALL

    SELECT
        'REGISTRY',registry.contract_code || '|v' || registry.contract_version::text,
        registry.row_hash,
        msbf_ctl.m2_5_registry_row_hash(to_jsonb(registry))
    FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS registry
    WHERE registry.module1_run_id=(SELECT run_id FROM _m2_5_dctx)
)
SELECT entity_type,entity_key,stored_hash,reconstructed_hash
FROM mismatches
WHERE stored_hash IS DISTINCT FROM reconstructed_hash
ORDER BY entity_type,entity_key;

/* Result Set 24 — Blocking Errors and Stage-Boundary Violations */
SELECT
    'FAILED_EVIDENCE' AS violation_type,
    'msbf_ctl.run_evidence' AS object_name,
    evidence_code AS violation_detail
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m2_5_dctx)
  AND evidence_code LIKE 'M2_5_%'
  AND status='FAIL'

UNION ALL

SELECT
    'ACCEPTANCE_NOT_PASS',
    'msbf_ctl.acceptance_gate_result',
    coalesce(result_status,'<NULL>')
FROM msbf_ctl.acceptance_gate_result
WHERE run_id=(SELECT run_id FROM _m2_5_dctx)
  AND gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
  AND result_status<>'PASS'

UNION ALL

SELECT
    'PROHIBITED_SERVICING_COLUMN',
    table_schema || '.' || table_name,
    column_name
FROM information_schema.columns
WHERE table_schema='msbf_m2'
  AND table_name IN
  (
      'advance_daily_remittance_monitoring',
      'advance_portfolio_monitoring_latest',
      'advance_portfolio_monitoring_archive',
      'portfolio_daily_monitoring_summary'
  )
  AND lower(column_name) IN
  (
      'debit_instruction','real_debit_instruction','ach_trace_number',
      'payment_network_confirmation','bank_account_number','routing_number',
      'account_number','collection_action','servicing_action','write_off',
      'charge_off','restructure_offer','workout_offer',
      'external_notice_payload','production_adverse_action_notice'
  )

UNION ALL

SELECT
    'PROHIBITED_REASON_FLAG',
    'msbf_m2.portfolio_monitoring_reason_definition',
    monitoring_reason_code
FROM msbf_m2.portfolio_monitoring_reason_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
  AND
  (
      production_adverse_action_notice_flag
      OR servicing_action_authorized_flag
  )

UNION ALL

SELECT
    'STRESS_STATUS_IMPROVEMENT',
    'msbf_m2.v_m2_5_matched_monitoring_comparison',
    merchant_application_id
FROM msbf_m2.v_m2_5_matched_monitoring_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_5_dctx)
  AND stress_status_improvement_flag

UNION ALL

SELECT
    'PREMATURE_M2_6_OBJECT',
    table_schema || '.' || table_name,
    table_name
FROM information_schema.tables
WHERE table_schema IN('msbf_ctl','msbf_m2')
  AND lower(table_name) LIKE 'm2_6%';
