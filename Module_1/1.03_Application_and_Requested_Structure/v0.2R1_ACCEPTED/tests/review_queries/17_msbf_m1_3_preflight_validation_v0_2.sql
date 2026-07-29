/**********************************************************************
MSBF M1.3 Application and Requested Sales-Linked Structure — Preflight
Version : v0.2
**********************************************************************/
WITH ctx AS (
  SELECT r.*,p.population_version,p.population_status,p.deterministic_seed_version,
         p.merchant_count,p.population_hash
  FROM msbf_ctl.run_registry r
  JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
  WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
), gates AS (
  SELECT
   (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1) AS g1_status,
   (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1) AS m12_status
), hashes AS (
  SELECT
   (SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key)) FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS parameter_hash,
   (SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code)) FROM msbf_ctl.run_profile_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS profile_hash,
   (SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code)) FROM msbf_ctl.run_source_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS source_hash,
   (SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM ctx))) AS population_hash
), population_obs AS (
  SELECT
   (SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE population_id=(SELECT population_id FROM ctx)) AS merchants,
   (SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS owners,
   (SELECT COUNT(*) FROM msbf_m1.merchant_industry_assignment WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS industry_rows,
   (SELECT COUNT(*) FROM msbf_m1.partner_channel WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS channels,
   (SELECT COUNT(*) FROM msbf_m1.processor_account WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS processors,
   (SELECT COUNT(*) FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS relationships
), required_params(parameter_name,scope_key) AS (
  VALUES
   ('application_count_per_merchant','GLOBAL'),
   ('funding_amount_min','GLOBAL'),('funding_amount_max','GLOBAL'),
   ('funding_to_annualized_sales_max','GLOBAL'),
   ('payback_multiple_min','GLOBAL'),('payback_multiple_max','GLOBAL'),
   ('requested_remittance_rate_min','GLOBAL'),('requested_remittance_rate_max','GLOBAL'),
   ('qa_reconciliation_tolerance_amount','GLOBAL'),
   ('funding_to_annualized_sales_center','MERCHANT_SIZE_TIER:MICRO'),
   ('funding_to_annualized_sales_center','MERCHANT_SIZE_TIER:SMALL'),
   ('funding_to_annualized_sales_center','MERCHANT_SIZE_TIER:LOWER_MIDDLE'),
   ('funding_to_annualized_sales_center','MERCHANT_SIZE_TIER:MIDDLE'),
   ('payback_multiple_center','RISK_TIER:1'),('payback_multiple_center','RISK_TIER:2'),
   ('payback_multiple_center','RISK_TIER:3'),('payback_multiple_center','RISK_TIER:4'),
   ('payback_multiple_center','RISK_TIER:5'),
   ('expected_payoff_day_weight','EXPECTED_PAYOFF_DAYS:30'),
   ('expected_payoff_day_weight','EXPECTED_PAYOFF_DAYS:60'),
   ('expected_payoff_day_weight','EXPECTED_PAYOFF_DAYS:90'),
   ('requested_remittance_rate_center','EXPECTED_PAYOFF_DAYS:30'),
   ('requested_remittance_rate_center','EXPECTED_PAYOFF_DAYS:60'),
   ('requested_remittance_rate_center','EXPECTED_PAYOFF_DAYS:90'),
   ('use_of_proceeds_mix_weight','USE_OF_PROCEEDS:WORKING_CAPITAL'),
   ('use_of_proceeds_mix_weight','USE_OF_PROCEEDS:INVENTORY'),
   ('use_of_proceeds_mix_weight','USE_OF_PROCEEDS:EQUIPMENT_REPAIR'),
   ('use_of_proceeds_mix_weight','USE_OF_PROCEEDS:SEASONAL_NEED'),
   ('use_of_proceeds_mix_weight','USE_OF_PROCEEDS:EXPANSION'),
   ('use_of_proceeds_mix_weight','USE_OF_PROCEEDS:EMERGENCY_EXPENSE')
), parameter_obs AS (
  SELECT COUNT(*) AS required_pairs,COUNT(rps.parameter_name) AS resolved_pairs,
         COUNT(*) FILTER (WHERE rps.resolved_value->>'data_type' IN ('NUMERIC','INTEGER')) AS typed_pairs
  FROM required_params rp
  LEFT JOIN msbf_ctl.run_parameter_snapshot rps
    ON rps.run_id=(SELECT run_id FROM ctx)
   AND rps.parameter_name=rp.parameter_name AND rps.scope_key=rp.scope_key
), weights AS (
  SELECT parameter_name,COUNT(*) AS categories,
         SUM((resolved_value->>'value_numeric')::numeric) AS weight_sum
  FROM msbf_ctl.run_parameter_snapshot
  WHERE run_id=(SELECT run_id FROM ctx)
    AND parameter_name IN ('expected_payoff_day_weight','use_of_proceeds_mix_weight')
  GROUP BY parameter_name
), weight_obs AS (
  SELECT COUNT(*) AS weight_sets,
         COUNT(*) FILTER (WHERE abs(weight_sum-1)<=0.000000001) AS valid_sets,
         MIN(categories) AS min_categories,MAX(categories) AS max_categories
  FROM weights
), bounds AS (
  SELECT
   max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='application_count_per_merchant' AND scope_key='GLOBAL') AS apps_per_merchant,
   max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='funding_amount_min' AND scope_key='GLOBAL') AS funding_min,
   max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='funding_amount_max' AND scope_key='GLOBAL') AS funding_max,
   max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='funding_to_annualized_sales_max' AND scope_key='GLOBAL') AS funding_ratio_max,
   max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='payback_multiple_min' AND scope_key='GLOBAL') AS payback_min,
   max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='payback_multiple_max' AND scope_key='GLOBAL') AS payback_max,
   max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='requested_remittance_rate_min' AND scope_key='GLOBAL') AS remittance_min,
   max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='requested_remittance_rate_max' AND scope_key='GLOBAL') AS remittance_max
  FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM ctx)
), stage_rows AS (
  SELECT
   (SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS applications,
   (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
  +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
  +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
  +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
  +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
  +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
  +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM ctx))
  +(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx))
  +(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx))
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
  SELECT COUNT(*) AS blocking_errors FROM msbf_ctl.profile_resolution_error
  WHERE run_id=(SELECT run_id FROM ctx) AND severity='BLOCKING'
)
SELECT clock_timestamp() AS report_timestamp,current_database() AS database_name,current_user AS database_user,
       current_setting('server_version') AS postgresql_version,
       ctx.run_id,ctx.run_code,ctx.run_version,ctx.run_status,ctx.population_id,ctx.population_status,
       ctx.as_of_date,ctx.merchant_count,ctx.population_hash,
       ctx.parameter_snapshot_hash,hashes.parameter_hash AS recomputed_parameter_hash,
       ctx.profile_snapshot_hash,hashes.profile_hash AS recomputed_profile_hash,
       ctx.source_snapshot_hash,hashes.source_hash AS recomputed_source_hash,
       hashes.population_hash AS recomputed_population_hash,gates.g1_status,gates.m12_status,
       population_obs.*,parameter_obs.*,weight_obs.*,bounds.*,stage_rows.*,errors.blocking_errors,
       CASE WHEN current_database()='msbf_strategy'
        AND ctx.run_status='M1_2_ACCEPTED' AND ctx.population_status='M1_2_ACCEPTED'
        AND gates.g1_status='PASS' AND gates.m12_status='PASS'
        AND ctx.population_id='MSBF_POP_0001' AND ctx.population_version=1
        AND ctx.merchant_count=750 AND ctx.as_of_date=DATE '2026-07-23'
        AND ctx.parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
        AND ctx.profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
        AND ctx.source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3'
        AND ctx.population_hash='9b706c926260a3ef1ae8ac95eed5d0bf'
        AND ctx.parameter_snapshot_hash=hashes.parameter_hash
        AND ctx.profile_snapshot_hash=hashes.profile_hash
        AND ctx.source_snapshot_hash=hashes.source_hash
        AND ctx.population_hash=hashes.population_hash
        AND population_obs.merchants=750 AND population_obs.owners=1347
        AND population_obs.industry_rows=750 AND population_obs.channels=5
        AND population_obs.processors=750 AND population_obs.relationships=750
        AND parameter_obs.required_pairs=30 AND parameter_obs.resolved_pairs=30 AND parameter_obs.typed_pairs=30
        AND weight_obs.weight_sets=2 AND weight_obs.valid_sets=2 AND weight_obs.min_categories=3 AND weight_obs.max_categories=6
        AND bounds.apps_per_merchant=1 AND bounds.funding_min>0 AND bounds.funding_max>bounds.funding_min
        AND bounds.funding_ratio_max>0 AND bounds.funding_ratio_max<=1
        AND bounds.payback_min>=1 AND bounds.payback_max>bounds.payback_min
        AND bounds.remittance_min>0 AND bounds.remittance_max>bounds.remittance_min
        AND stage_rows.applications=0 AND stage_rows.downstream_rows=0 AND errors.blocking_errors=0
       THEN 'PASS' ELSE 'FAIL' END AS preflight_status
FROM ctx CROSS JOIN gates CROSS JOIN hashes CROSS JOIN population_obs CROSS JOIN parameter_obs
CROSS JOIN weight_obs CROSS JOIN bounds CROSS JOIN stage_rows CROSS JOIN errors;
