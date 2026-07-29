/* ============================================================================
MSBF M1.6 Matched POS and Deposit Scenario Overlays — Preflight Validation
Version : v0.2
Purpose : Confirm the accepted G0–M1.5 state, scenario configuration, required
          parameters, source readiness, empty scenario tables, and unchanged
          upstream hashes before scenario generation.
============================================================================ */
WITH ctx AS (
 SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.population_id,r.parameter_snapshot_hash,
        r.profile_snapshot_hash,r.source_snapshot_hash,p.population_status,p.merchant_count,
        p.history_start_date,p.history_end_date,(p.history_end_date-p.history_start_date+1)::integer AS history_days,
        p.population_hash,p.deterministic_seed_version
 FROM msbf_ctl.run_registry r
 JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
), gates AS (
 SELECT
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1) AS g1,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1) AS m12,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) AS m13,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_4_DAILY_POS_HISTORY' ORDER BY review_version DESC LIMIT 1) AS m14,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY' ORDER BY review_version DESC LIMIT 1) AS m15
), hashes AS (
 SELECT
  (SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key)) FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS parameter_hash,
  (SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code)) FROM msbf_ctl.run_profile_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS profile_hash,
  (SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code)) FROM msbf_ctl.run_source_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS source_hash,
  (SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM ctx))) AS population_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM ctx))) AS application_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_4_actual_pos_snapshot((SELECT run_id FROM ctx))) AS pos_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_5_actual_deposit_snapshot((SELECT run_id FROM ctx))) AS deposit_hash
), scenario_obs AS (
 SELECT ss.scenario_set_id,ss.scenario_set_code,ss.status AS scenario_set_status,
        COUNT(*) FILTER(WHERE sr.status='APPROVED') AS approved_scenarios,
        COUNT(*) FILTER(WHERE sr.status='APPROVED' AND sr.scenario_code='BASELINE' AND sr.scenario_version=1) AS baseline_scenarios,
        COUNT(*) FILTER(WHERE sr.status='APPROVED' AND sr.scenario_code='RECESSION_ENERGY' AND sr.scenario_version=1) AS stress_scenarios
 FROM msbf_ctl.scenario_set ss
 LEFT JOIN msbf_ctl.scenario_registry sr ON sr.scenario_set_id=ss.scenario_set_id
 WHERE ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS' AND ss.scenario_set_version=1
 GROUP BY ss.scenario_set_id,ss.scenario_set_code,ss.status
), required_parameters(parameter_name,scope_key) AS (
 VALUES
 ('enable_scenario_history_flag','GLOBAL'),
 ('scenario_direct_shock_cap','GLOBAL'),
 ('scenario_propagated_shock_cap','GLOBAL'),
 ('scenario_damping_factor','GLOBAL'),
 ('scenario_lag_days','GLOBAL'),
 ('qa_min_scenario_matched_share','GLOBAL'),
 ('liquidity_shock_multiplier','GLOBAL'),
 ('qa_reconciliation_tolerance_amount','GLOBAL'),
 ('scenario_sales_level_multiplier','SCENARIO:BASELINE'),
 ('scenario_sales_volatility_multiplier','SCENARIO:BASELINE'),
 ('scenario_zero_sales_probability_multiplier','SCENARIO:BASELINE'),
 ('scenario_refund_rate_multiplier','SCENARIO:BASELINE'),
 ('scenario_chargeback_rate_multiplier','SCENARIO:BASELINE'),
 ('scenario_deposit_capture_multiplier','SCENARIO:BASELINE'),
 ('scenario_obligation_multiplier','SCENARIO:BASELINE'),
 ('scenario_processor_outage_rate','SCENARIO:BASELINE'),
 ('scenario_sales_level_multiplier','SCENARIO:RECESSION_ENERGY'),
 ('scenario_sales_volatility_multiplier','SCENARIO:RECESSION_ENERGY'),
 ('scenario_zero_sales_probability_multiplier','SCENARIO:RECESSION_ENERGY'),
 ('scenario_refund_rate_multiplier','SCENARIO:RECESSION_ENERGY'),
 ('scenario_chargeback_rate_multiplier','SCENARIO:RECESSION_ENERGY'),
 ('scenario_deposit_capture_multiplier','SCENARIO:RECESSION_ENERGY'),
 ('scenario_obligation_multiplier','SCENARIO:RECESSION_ENERGY'),
 ('scenario_processor_outage_rate','SCENARIO:RECESSION_ENERGY'),
 ('industry_zero_sales_day_probability','INDUSTRY:RESTAURANT_FOOD_SERVICE'),
 ('industry_zero_sales_day_probability','INDUSTRY:GENERAL_RETAIL'),
 ('industry_zero_sales_day_probability','INDUSTRY:PROFESSIONAL_SERVICES'),
 ('industry_zero_sales_day_probability','INDUSTRY:CONSTRUCTION_TRADES'),
 ('industry_zero_sales_day_probability','INDUSTRY:TRANSPORTATION_LOGISTICS'),
 ('industry_zero_sales_day_probability','INDUSTRY:ENERGY_SERVICES'),
 ('industry_zero_sales_day_probability','INDUSTRY:HEALTHCARE_SERVICES'),
 ('industry_zero_sales_day_probability','INDUSTRY:ECOMMERCE_DIGITAL')
), parameter_obs AS (
 SELECT COUNT(*) AS required_pairs,COUNT(rps.parameter_name) AS resolved_pairs,
        bool_and(CASE WHEN req.parameter_name='enable_scenario_history_flag' THEN (rps.resolved_value->>'value_boolean')::boolean ELSE true END) AS scenario_enabled
 FROM required_parameters req
 LEFT JOIN msbf_ctl.run_parameter_snapshot rps
   ON rps.run_id=(SELECT run_id FROM ctx)
  AND rps.parameter_name=req.parameter_name
  AND rps.scope_key=req.scope_key
), source_obs AS (
 SELECT
  COUNT(*) FILTER(WHERE rss.source_code='POS_DAILY' AND rss.quality_status='CONTRACT_READY_PRE_GENERATION' AND sc.status='APPROVED') AS pos_sources,
  COUNT(*) FILTER(WHERE rss.source_code='DEPOSIT_DAILY' AND rss.quality_status='CONTRACT_READY_PRE_GENERATION' AND sc.status='APPROVED') AS deposit_sources
 FROM msbf_ctl.run_source_snapshot rss
 JOIN msbf_ctl.source_contract sc ON sc.source_contract_id=rss.source_contract_id
 WHERE rss.run_id=(SELECT run_id FROM ctx)
), row_obs AS (
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE population_id=(SELECT population_id FROM ctx)) AS merchants,
  (SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS applications,
  (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx)) AS base_pos_rows,
  (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx)) AS base_deposit_rows,
  (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx)) AS scenario_pos_rows,
  (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx)) AS scenario_deposit_rows,
  (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM ctx))
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
SELECT clock_timestamp() AS validation_timestamp,current_database() AS database_name,current_user AS database_user,
       current_setting('server_version') AS postgresql_version,
       ctx.*,gates.*,hashes.*,scenario_obs.*,parameter_obs.*,source_obs.*,row_obs.*,errors.blocking_errors,
       CASE WHEN ctx.run_status='M1_5_ACCEPTED' AND ctx.population_status='M1_2_ACCEPTED'
                  AND gates.g1='PASS' AND gates.m12='PASS' AND gates.m13='PASS' AND gates.m14='PASS' AND gates.m15='PASS'
                  AND ctx.parameter_snapshot_hash=hashes.parameter_hash AND ctx.profile_snapshot_hash=hashes.profile_hash
                  AND ctx.source_snapshot_hash=hashes.source_hash AND ctx.population_hash=hashes.population_hash
                  AND hashes.application_hash='01485256b9b5748fb412743d35ced602'
                  AND hashes.pos_hash='d1971e8d319483c187ec0c0483a31e33'
                  AND hashes.deposit_hash='bbe96dd24fbbba3af4a587dd475a88d0'
                  AND scenario_obs.scenario_set_status='APPROVED' AND scenario_obs.approved_scenarios=2
                  AND scenario_obs.baseline_scenarios=1 AND scenario_obs.stress_scenarios=1
                  AND parameter_obs.required_pairs=32 AND parameter_obs.resolved_pairs=32 AND parameter_obs.scenario_enabled
                  AND source_obs.pos_sources=1 AND source_obs.deposit_sources=1
                  AND row_obs.merchants=750 AND row_obs.applications=750
                  AND row_obs.base_pos_rows=135000 AND row_obs.base_deposit_rows=135000
                  AND row_obs.scenario_pos_rows=0 AND row_obs.scenario_deposit_rows=0
                  AND row_obs.downstream_rows=0 AND errors.blocking_errors=0
             THEN 'PASS' ELSE 'FAIL' END AS preflight_status
FROM ctx CROSS JOIN gates CROSS JOIN hashes CROSS JOIN scenario_obs CROSS JOIN parameter_obs CROSS JOIN source_obs CROSS JOIN row_obs CROSS JOIN errors;
