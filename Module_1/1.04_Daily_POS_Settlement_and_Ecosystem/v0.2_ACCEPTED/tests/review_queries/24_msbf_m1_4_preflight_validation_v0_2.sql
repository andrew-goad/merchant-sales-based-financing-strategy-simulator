/* ============================================================================
MSBF M1.4 Enterprise Merchant Ecosystem — Preflight Validation
Version : v0.2
Purpose : Confirm that accepted G0/G1/M1.2/M1.3 state, frozen parameters,
          source contracts, temporal boundaries, and empty downstream tables
          are intact before deterministic daily POS and settlement generation.
============================================================================ */

WITH ctx AS (
    SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.population_id,r.as_of_date,
           r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,
           p.population_status,p.population_hash,p.merchant_count,p.history_start_date,
           p.history_end_date,p.deterministic_seed_version,
           (p.history_end_date-p.history_start_date+1)::integer AS history_days
    FROM msbf_ctl.run_registry r
    JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
), gates AS (
    SELECT
      (SELECT result_status FROM msbf_ctl.acceptance_gate_result g JOIN ctx ON g.run_id=ctx.run_id
        WHERE g.gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1) AS g1_status,
      (SELECT result_status FROM msbf_ctl.acceptance_gate_result g JOIN ctx ON g.run_id=ctx.run_id
        WHERE g.gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1) AS m12_status,
      (SELECT result_status FROM msbf_ctl.acceptance_gate_result g JOIN ctx ON g.run_id=ctx.run_id
        WHERE g.gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) AS m13_status
), recomputed AS (
    SELECT
      (SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key))
         FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS parameter_hash,
      (SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code))
         FROM msbf_ctl.run_profile_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS profile_hash,
      (SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code))
         FROM msbf_ctl.run_source_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS source_hash,
      (SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key))
         FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM ctx))) AS population_hash,
      (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
         FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM ctx))) AS application_hash
), required_parameters AS (
    SELECT p.parameter_name,'INDUSTRY:'||i.industry_code AS scope_key
    FROM (VALUES
      ('industry_daily_sales_center'),('industry_daily_sales_log_sigma'),
      ('industry_daily_sales_volatility'),('industry_zero_sales_day_probability'),
      ('industry_seasonality_amplitude'),('industry_weekend_sales_factor'),
      ('industry_average_ticket_center'),('industry_refund_rate_center'),
      ('industry_chargeback_rate_center')
    ) p(parameter_name)
    CROSS JOIN msbf_ref.industry i
    UNION ALL
    SELECT 'merchant_growth_rate_center','CASHFLOW_ARCHETYPE:'||archetype_code
    FROM msbf_ref.cashflow_archetype
    UNION ALL
    SELECT 'processor_fee_rate',scope_key
    FROM (VALUES
      ('PARTNER_CHANNEL:PROCESSOR_DIRECT'),('PARTNER_CHANNEL:BANK_RELATIONSHIP'),
      ('PARTNER_CHANNEL:BROKER_REFERRAL'),('PARTNER_CHANNEL:DIGITAL_DIRECT')
    ) s(scope_key)
    UNION ALL SELECT 'reversal_rate_center','GLOBAL'
    UNION ALL SELECT 'merchant_growth_rate_sigma','GLOBAL'
    UNION ALL SELECT 'qa_reconciliation_tolerance_amount','GLOBAL'
), parameter_readiness AS (
    SELECT COUNT(*)::integer AS required_count,
           COUNT(rps.parameter_name)::integer AS resolved_count
    FROM required_parameters req
    LEFT JOIN msbf_ctl.run_parameter_snapshot rps
      ON rps.run_id=(SELECT run_id FROM ctx)
     AND rps.parameter_name=req.parameter_name
     AND rps.scope_key=req.scope_key
), source_readiness AS (
    SELECT COUNT(*)::integer AS pos_source_rows,
           COUNT(*) FILTER (WHERE rss.quality_status='CONTRACT_READY_PRE_GENERATION')::integer AS contract_ready_rows,
           COUNT(*) FILTER (WHERE sc.status='APPROVED' AND sc.source_code='POS_DAILY')::integer AS approved_contract_rows
    FROM msbf_ctl.run_source_snapshot rss
    JOIN msbf_ctl.source_contract sc ON sc.source_contract_id=rss.source_contract_id
    WHERE rss.run_id=(SELECT run_id FROM ctx) AND rss.source_code='POS_DAILY'
), upstream_counts AS (
    SELECT
      (SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE population_id=(SELECT population_id FROM ctx)) AS merchants,
      (SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS applications
), existing_stage_rows AS (
    SELECT
      (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx)) AS base_pos_rows,
      (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx)) AS scenario_pos_rows
), downstream AS (
    SELECT
      (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM ctx)) AS downstream_rows
), errors AS (
    SELECT COUNT(*)::integer AS blocking_errors
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=(SELECT run_id FROM ctx) AND severity='BLOCKING'
), app_hash AS (
    SELECT metric_value_text AS stored_application_hash
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM ctx)
      AND evidence_code='M1_3_APPLICATION_SET_HASH'
      AND segment_key='PORTFOLIO'
)
SELECT
  ctx.run_id,ctx.run_status,ctx.population_id,ctx.population_status,ctx.merchant_count,
  ctx.history_start_date,ctx.history_end_date,ctx.history_days,
  (ctx.merchant_count*ctx.history_days)::bigint AS expected_pos_rows,
  upstream_counts.merchants,upstream_counts.applications,
  parameter_readiness.required_count AS required_parameter_pairs,
  parameter_readiness.resolved_count AS resolved_parameter_pairs,
  source_readiness.pos_source_rows,source_readiness.contract_ready_rows,source_readiness.approved_contract_rows,
  existing_stage_rows.base_pos_rows,existing_stage_rows.scenario_pos_rows,downstream.downstream_rows,
  errors.blocking_errors,gates.g1_status,gates.m12_status,gates.m13_status,
  ctx.parameter_snapshot_hash,ctx.profile_snapshot_hash,ctx.source_snapshot_hash,ctx.population_hash,
  app_hash.stored_application_hash,
  CASE WHEN
      ctx.run_status='M1_3_ACCEPTED'
      AND ctx.population_status='M1_2_ACCEPTED'
      AND gates.g1_status='PASS' AND gates.m12_status='PASS' AND gates.m13_status='PASS'
      AND ctx.parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
      AND ctx.profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
      AND ctx.source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3'
      AND ctx.population_hash='9b706c926260a3ef1ae8ac95eed5d0bf'
      AND app_hash.stored_application_hash='01485256b9b5748fb412743d35ced602'
      AND recomputed.parameter_hash=ctx.parameter_snapshot_hash
      AND recomputed.profile_hash=ctx.profile_snapshot_hash
      AND recomputed.source_hash=ctx.source_snapshot_hash
      AND recomputed.population_hash=ctx.population_hash
      AND recomputed.application_hash=app_hash.stored_application_hash
      AND ctx.merchant_count=750 AND ctx.history_days=180
      AND upstream_counts.merchants=750 AND upstream_counts.applications=750
      AND parameter_readiness.required_count=86 AND parameter_readiness.resolved_count=86
      AND source_readiness.pos_source_rows=1 AND source_readiness.contract_ready_rows=1 AND source_readiness.approved_contract_rows=1
      AND existing_stage_rows.base_pos_rows=0 AND existing_stage_rows.scenario_pos_rows=0
      AND downstream.downstream_rows=0 AND errors.blocking_errors=0
    THEN 'PASS' ELSE 'FAIL' END AS preflight_status
FROM ctx CROSS JOIN gates CROSS JOIN recomputed CROSS JOIN parameter_readiness
CROSS JOIN source_readiness CROSS JOIN upstream_counts CROSS JOIN existing_stage_rows
CROSS JOIN downstream CROSS JOIN errors LEFT JOIN app_hash ON true;
