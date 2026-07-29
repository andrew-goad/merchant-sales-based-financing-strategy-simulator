/**********************************************************************
MSBF M1.2 Deterministic Merchant Population — Preflight Validation
Version : v0.2R2
Purpose : Confirm that the accepted G1 configuration is unchanged and
          that no M1.2 or downstream analytical records exist before
          population generation.
**********************************************************************/

WITH ctx AS (
    SELECT r.*, p.population_version, p.population_status,
           p.deterministic_seed_version, p.merchant_count,
           p.history_start_date, p.history_end_date,
           p.population_hash
    FROM msbf_ctl.run_registry r
    JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
      AND r.run_version=1
), latest_g1 AS (
    SELECT result_status, review_version, reviewed_at
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM ctx)
      AND gate_id='G1_CONTROL_PLANE'
    ORDER BY review_version DESC
    LIMIT 1
), parameter_obs AS (
    SELECT COUNT(*) AS snapshot_rows,
           COUNT(DISTINCT parameter_name) AS parameter_names,
           md5(string_agg(parameter_name || '|' || scope_key || '|' || snapshot_hash,
                          '||' ORDER BY parameter_name, scope_key)) AS recomputed_hash
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=(SELECT run_id FROM ctx)
), profile_obs AS (
    SELECT COUNT(*) AS snapshot_rows,
           COUNT(DISTINCT profile_domain) AS profile_domains,
           md5(string_agg(profile_domain || '|' || profile_code || '|' ||
                          profile_version::text || '|' || profile_hash,
                          '||' ORDER BY profile_domain, profile_code)) AS recomputed_hash
    FROM msbf_ctl.run_profile_snapshot
    WHERE run_id=(SELECT run_id FROM ctx)
), source_obs AS (
    SELECT COUNT(*) AS snapshot_rows,
           COUNT(*) FILTER (WHERE quality_status='CONTRACT_READY_PRE_GENERATION') AS ready_rows,
           COUNT(*) FILTER (WHERE source_row_count=0) AS zero_row_sources,
           md5(string_agg(source_code || '|' ||
                          to_char(source_cutoff_timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US') || '|' ||
                          source_hash || '|' || quality_status,
                          '||' ORDER BY source_code)) AS recomputed_hash
    FROM msbf_ctl.run_source_snapshot
    WHERE run_id=(SELECT run_id FROM ctx)
), mix_obs AS (
    SELECT parameter_name,
           COUNT(*) AS category_count,
           SUM((NULLIF(resolved_value ->> 'value_numeric',''))::numeric) AS weight_sum
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=(SELECT run_id FROM ctx)
      AND parameter_name IN (
          'industry_mix_weight','region_mix_weight','merchant_size_mix_weight',
          'relationship_stage_mix_weight','legal_entity_mix_weight'
      )
    GROUP BY parameter_name
), mix_summary AS (
    SELECT COUNT(*) AS mix_parameter_count,
           COUNT(*) FILTER (WHERE abs(weight_sum-1.0)<=0.000000001) AS valid_weight_sum_count,
           MIN(category_count) AS minimum_category_count
    FROM mix_obs
), m12_rows AS (
    SELECT
        (SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE population_id=(SELECT population_id FROM ctx)) AS merchants,
        (SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor o
          JOIN msbf_m1.merchant_master m ON m.merchant_id=o.merchant_id
         WHERE m.population_id=(SELECT population_id FROM ctx)) AS owners,
        (SELECT COUNT(*) FROM msbf_m1.merchant_industry_assignment i
          JOIN msbf_m1.merchant_master m ON m.merchant_id=i.merchant_id
         WHERE m.population_id=(SELECT population_id FROM ctx)) AS industries,
        (SELECT COUNT(*) FROM msbf_m1.partner_channel WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS partner_channels,
        (SELECT COUNT(*) FROM msbf_m1.processor_account WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS processors,
        (SELECT COUNT(*) FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS relationships
), downstream_rows AS (
    SELECT
          (SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM ctx))
        + (SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM ctx)) AS row_count
), blocking_errors AS (
    SELECT COUNT(*) AS error_count
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=(SELECT run_id FROM ctx)
      AND severity='BLOCKING'
), ref_obs AS (
    SELECT
        (SELECT COUNT(*) FROM msbf_ref.industry WHERE active_flag) AS active_industries,
        (SELECT COUNT(*) FROM msbf_ref.geography_region WHERE active_flag) AS active_regions
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
    ctx.population_id,
    ctx.population_version,
    ctx.population_status,
    ctx.merchant_count AS planned_merchant_count,
    ctx.deterministic_seed_version,
    ctx.as_of_date,
    ctx.history_start_date,
    ctx.history_end_date,
    ctx.parameter_snapshot_hash,
    parameter_obs.recomputed_hash AS recomputed_parameter_hash,
    ctx.profile_snapshot_hash,
    profile_obs.recomputed_hash AS recomputed_profile_hash,
    ctx.source_snapshot_hash,
    source_obs.recomputed_hash AS recomputed_source_hash,
    latest_g1.result_status AS g1_gate_status,
    parameter_obs.snapshot_rows AS parameter_snapshot_rows,
    parameter_obs.parameter_names AS parameter_name_count,
    profile_obs.snapshot_rows AS profile_snapshot_rows,
    profile_obs.profile_domains AS profile_domain_count,
    source_obs.snapshot_rows AS source_snapshot_rows,
    source_obs.ready_rows AS source_ready_rows,
    source_obs.zero_row_sources,
    mix_summary.mix_parameter_count,
    mix_summary.valid_weight_sum_count,
    ref_obs.active_industries,
    ref_obs.active_regions,
    m12_rows.merchants,
    m12_rows.owners,
    m12_rows.industries AS merchant_industry_rows,
    m12_rows.partner_channels,
    m12_rows.processors,
    m12_rows.relationships,
    downstream_rows.row_count AS downstream_analytical_rows,
    blocking_errors.error_count AS blocking_resolution_errors,
    CASE WHEN
        current_database()='msbf_strategy'
        AND ctx.run_status='G1_READY'
        AND ctx.population_status='READY_FOR_GENERATION'
        AND ctx.population_id='MSBF_POP_0001'
        AND ctx.population_version=1
        AND ctx.merchant_count=750
        AND ctx.deterministic_seed_version='DET_HASH_V1'
        AND ctx.as_of_date=DATE '2026-07-23'
        AND latest_g1.result_status='PASS'
        AND ctx.parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
        AND ctx.profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
        AND ctx.source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3'
        AND ctx.parameter_snapshot_hash=parameter_obs.recomputed_hash
        AND ctx.profile_snapshot_hash=profile_obs.recomputed_hash
        AND ctx.source_snapshot_hash=source_obs.recomputed_hash
        AND parameter_obs.snapshot_rows=401
        AND parameter_obs.parameter_names=155
        AND profile_obs.snapshot_rows=18
        AND profile_obs.profile_domains=15
        AND source_obs.snapshot_rows=7
        AND source_obs.ready_rows=7
        AND source_obs.zero_row_sources=7
        AND mix_summary.mix_parameter_count=5
        AND mix_summary.valid_weight_sum_count=5
        AND ref_obs.active_industries=8
        AND ref_obs.active_regions=5
        AND m12_rows.merchants=0
        AND m12_rows.owners=0
        AND m12_rows.industries=0
        AND m12_rows.partner_channels=0
        AND m12_rows.processors=0
        AND m12_rows.relationships=0
        AND downstream_rows.row_count=0
        AND blocking_errors.error_count=0
    THEN 'PASS' ELSE 'FAIL' END AS preflight_status
FROM ctx
CROSS JOIN parameter_obs
CROSS JOIN profile_obs
CROSS JOIN source_obs
CROSS JOIN mix_summary
CROSS JOIN m12_rows
CROSS JOIN downstream_rows
CROSS JOIN blocking_errors
CROSS JOIN ref_obs
LEFT JOIN latest_g1 ON true;
