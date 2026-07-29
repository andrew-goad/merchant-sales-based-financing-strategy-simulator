/**********************************************************************
MSBF G1 Governed Run and Configuration Readiness Master Report
Version : v0.2
Purpose : One-row exportable acceptance evidence after sql/07 finalization
**********************************************************************/

WITH ctx AS (
    SELECT r.*, ps.parameter_set_code, ps.parameter_set_version, ps.parameter_set_hash,
           p.population_version, p.population_status, p.deterministic_seed_version,
           p.merchant_count, p.history_start_date, p.history_end_date,
           s.scenario_code, s.scenario_type, ss.scenario_set_code,
           c.contract_code, c.contract_version, c.status AS contract_status
    FROM msbf_ctl.run_registry r
    JOIN msbf_ctl.parameter_set ps ON ps.parameter_set_id=r.parameter_set_id
    JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
    LEFT JOIN msbf_ctl.scenario_registry s ON s.scenario_id=r.scenario_id
    LEFT JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=s.scenario_set_id
    LEFT JOIN msbf_ctl.contract_registry c ON c.contract_id=r.contract_id
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
), parameter_obs AS (
    SELECT
        COUNT(*) AS parameter_snapshot_rows,
        COUNT(DISTINCT parameter_name) AS parameter_name_count,
        COUNT(*) FILTER (WHERE parameter_name='funding_to_annualized_sales_center') AS funding_center_rows,
        md5(string_agg(parameter_name || '|' || scope_key || '|' || snapshot_hash,
                       '||' ORDER BY parameter_name, scope_key)) AS recomputed_parameter_hash
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=(SELECT run_id FROM ctx)
), profile_obs AS (
    SELECT
        COUNT(*) AS profile_snapshot_rows,
        COUNT(DISTINCT profile_domain) AS profile_domain_count,
        COUNT(*) FILTER (WHERE profile_domain='RISK_APPETITE_LIMIT') AS risk_limit_rows,
        COUNT(*) FILTER (WHERE profile_domain='FEATURE_DEFINITION_SET') AS feature_set_rows,
        md5(string_agg(profile_domain || '|' || profile_code || '|' ||
                       profile_version::text || '|' || profile_hash,
                       '||' ORDER BY profile_domain, profile_code)) AS recomputed_profile_hash
    FROM msbf_ctl.run_profile_snapshot
    WHERE run_id=(SELECT run_id FROM ctx)
), source_obs AS (
    SELECT
        COUNT(*) AS source_snapshot_rows,
        COUNT(DISTINCT source_code) AS source_code_count,
        COUNT(*) FILTER (WHERE quality_status='CONTRACT_READY_PRE_GENERATION') AS source_ready_rows,
        COUNT(*) FILTER (WHERE source_row_count=0) AS source_zero_row_count,
        md5(string_agg(source_code || '|' ||
                       to_char(source_cutoff_timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US') || '|' || source_hash || '|' || quality_status,
                       '||' ORDER BY source_code)) AS recomputed_source_hash
    FROM msbf_ctl.run_source_snapshot
    WHERE run_id=(SELECT run_id FROM ctx)
), evidence_obs AS (
    SELECT
        COUNT(*) FILTER (WHERE evidence_code LIKE 'G1_POS_%') AS positive_check_count,
        COUNT(*) FILTER (WHERE evidence_code LIKE 'G1_POS_%' AND status='PASS') AS positive_pass_count,
        COUNT(*) FILTER (WHERE evidence_code LIKE 'G1_NEG_%') AS negative_control_count,
        COUNT(*) FILTER (WHERE evidence_code LIKE 'G1_NEG_%' AND status='PASS') AS negative_pass_count,
        COUNT(*) FILTER (WHERE (evidence_code LIKE 'G1_POS_%' OR evidence_code LIKE 'G1_NEG_%') AND status='FAIL') AS failed_evidence_count
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM ctx)
), resolution_obs AS (
    SELECT COUNT(*) FILTER (WHERE severity='BLOCKING') AS blocking_resolution_errors
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=(SELECT run_id FROM ctx)
), feature_obs AS (
    SELECT COUNT(*) AS active_feature_definitions
    FROM msbf_m1.feature_definition WHERE active_flag
), scenario_obs AS (
    SELECT COUNT(*) AS approved_scenarios_in_set
    FROM msbf_ctl.scenario_registry
    WHERE scenario_set_id=(SELECT scenario_set_id
                           FROM msbf_ctl.scenario_registry
                           WHERE scenario_id=(SELECT scenario_id FROM ctx))
      AND status='APPROVED'
), analytical_obs AS (
    SELECT
          (SELECT COUNT(*) FROM msbf_m1.merchant_master) AS merchants,
          (SELECT COUNT(*) FROM msbf_m1.merchant_application) AS applications,
          (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base) AS pos_base_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario) AS pos_scenario_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base) AS deposit_base_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario) AS deposit_scenario_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot) AS feature_snapshot_rows,
          (SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot) AS risk_snapshot_rows,
          (SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot) AS ead_path_rows,
          (SELECT COUNT(*) FROM msbf_m1.module1_latest) AS latest_results,
          (SELECT COUNT(*) FROM msbf_m1.module1_archive) AS archive_results
), latest_gate AS (
    SELECT result_status AS g1_gate_status,
           review_version AS g1_gate_review_version,
           reviewed_at AS g1_gate_reviewed_at,
           finding AS g1_gate_finding
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM ctx)
      AND gate_id='G1_CONTROL_PLANE'
    ORDER BY review_version DESC
    LIMIT 1
)
SELECT
    clock_timestamp() AS report_timestamp,
    current_database() AS database_name,
    current_user AS database_user,
    current_setting('server_version') AS postgresql_version,

    ctx.run_id,
    ctx.run_code,
    ctx.run_version,
    ctx.run_status,
    ctx.code_version,
    ctx.as_of_date,

    ctx.population_id,
    ctx.population_version,
    ctx.population_status,
    ctx.deterministic_seed_version,
    ctx.merchant_count AS planned_merchant_count,
    ctx.history_start_date,
    ctx.history_end_date,
    (ctx.history_end_date-ctx.history_start_date+1) AS inclusive_history_days,

    ctx.parameter_set_code,
    ctx.parameter_set_version,
    parameter_obs.parameter_snapshot_rows,
    parameter_obs.parameter_name_count,
    parameter_obs.funding_center_rows,
    ctx.parameter_snapshot_hash,
    parameter_obs.recomputed_parameter_hash,
    ctx.parameter_set_hash,

    profile_obs.profile_snapshot_rows,
    profile_obs.profile_domain_count,
    profile_obs.risk_limit_rows,
    profile_obs.feature_set_rows,
    ctx.profile_snapshot_hash,
    profile_obs.recomputed_profile_hash,

    source_obs.source_snapshot_rows,
    source_obs.source_code_count,
    source_obs.source_ready_rows,
    source_obs.source_zero_row_count,
    ctx.source_snapshot_hash,
    source_obs.recomputed_source_hash,

    ctx.scenario_set_code,
    ctx.scenario_code,
    ctx.scenario_type,
    scenario_obs.approved_scenarios_in_set,

    ctx.contract_code,
    ctx.contract_version,
    ctx.contract_status,
    feature_obs.active_feature_definitions,

    evidence_obs.positive_check_count,
    evidence_obs.positive_pass_count,
    evidence_obs.negative_control_count,
    evidence_obs.negative_pass_count,
    evidence_obs.failed_evidence_count,
    resolution_obs.blocking_resolution_errors,

    analytical_obs.merchants,
    analytical_obs.applications,
    analytical_obs.pos_base_rows,
    analytical_obs.pos_scenario_rows,
    analytical_obs.deposit_base_rows,
    analytical_obs.deposit_scenario_rows,
    analytical_obs.feature_snapshot_rows,
    analytical_obs.risk_snapshot_rows,
    analytical_obs.ead_path_rows,
    analytical_obs.latest_results,
    analytical_obs.archive_results,

    latest_gate.g1_gate_status,
    latest_gate.g1_gate_review_version,
    latest_gate.g1_gate_reviewed_at,
    latest_gate.g1_gate_finding,

    CASE WHEN
        ctx.run_status='G1_READY'
        AND ctx.population_status='READY_FOR_GENERATION'
        AND ctx.merchant_count=750
        AND (ctx.history_end_date-ctx.history_start_date+1)=180
        AND parameter_obs.parameter_snapshot_rows=401
        AND parameter_obs.parameter_name_count=155
        AND parameter_obs.funding_center_rows=4
        AND ctx.parameter_snapshot_hash=parameter_obs.recomputed_parameter_hash
        AND ctx.parameter_snapshot_hash=ctx.parameter_set_hash
        AND profile_obs.profile_snapshot_rows=18
        AND profile_obs.profile_domain_count=15
        AND profile_obs.risk_limit_rows=4
        AND profile_obs.feature_set_rows=1
        AND ctx.profile_snapshot_hash=profile_obs.recomputed_profile_hash
        AND source_obs.source_snapshot_rows=7
        AND source_obs.source_code_count=7
        AND source_obs.source_ready_rows=7
        AND source_obs.source_zero_row_count=7
        AND ctx.source_snapshot_hash=source_obs.recomputed_source_hash
        AND scenario_obs.approved_scenarios_in_set=2
        AND ctx.contract_code='M1_APPLICATION_RISK_SNAPSHOT'
        AND ctx.contract_version=1
        AND ctx.contract_status='APPROVED'
        AND feature_obs.active_feature_definitions=32
        AND evidence_obs.positive_check_count=20
        AND evidence_obs.positive_pass_count=20
        AND evidence_obs.negative_control_count=3
        AND evidence_obs.negative_pass_count=3
        AND evidence_obs.failed_evidence_count=0
        AND resolution_obs.blocking_resolution_errors=0
        AND analytical_obs.merchants=0
        AND analytical_obs.applications=0
        AND analytical_obs.pos_base_rows=0
        AND analytical_obs.pos_scenario_rows=0
        AND analytical_obs.deposit_base_rows=0
        AND analytical_obs.deposit_scenario_rows=0
        AND analytical_obs.feature_snapshot_rows=0
        AND analytical_obs.risk_snapshot_rows=0
        AND analytical_obs.ead_path_rows=0
        AND analytical_obs.latest_results=0
        AND analytical_obs.archive_results=0
        AND latest_gate.g1_gate_status='PASS'
    THEN 'PASS' ELSE 'FAIL' END AS overall_g1_status
FROM ctx
CROSS JOIN parameter_obs
CROSS JOIN profile_obs
CROSS JOIN source_obs
CROSS JOIN evidence_obs
CROSS JOIN resolution_obs
CROSS JOIN feature_obs
CROSS JOIN scenario_obs
CROSS JOIN analytical_obs
LEFT JOIN latest_gate ON true;
