/* ============================================================================
MSBF M1.6 Matched POS and Deposit Scenario Overlay Generation
Version : v0.2
Purpose : Create matched BASELINE and RECESSION_ENERGY scenario panels across
          accepted POS and deposit histories without modifying baseline rows.
============================================================================ */
BEGIN;

INSERT INTO msbf_ref.acceptance_gate_catalog(gate_id,gate_name,module_code,severity,description)
VALUES('M1_6_MATCHED_SCENARIO_OVERLAYS','M1.6 Matched POS and Deposit Scenario Overlays','M1','BLOCKING',
       'Matched baseline and recession/energy scenario histories with direct and propagated industry shocks, canonical row-level reproduction, and strict stage boundaries.')
ON CONFLICT (gate_id) DO NOTHING;

CREATE OR REPLACE FUNCTION msbf_m1.m1_6_pos_scenario_row_hash(
 p_scenario_id bigint,p_base_row_hash text,p_direct_shock_factor numeric,p_propagated_shock_factor numeric,
 p_scenario_overlay_payload jsonb,p_population_id text,p_merchant_id text,p_processor_account_id text,
 p_observation_date date,p_gross_pos_sales numeric,p_transaction_count integer,p_average_ticket_amount numeric,
 p_refund_amount numeric,p_chargeback_amount numeric,p_reversal_amount numeric,p_governed_exclusion_amount numeric,
 p_eligible_pos_sales numeric,p_processor_fee_amount numeric,p_settlement_amount numeric,p_net_merchant_proceeds numeric,
 p_zero_sales_day_flag boolean,p_processor_status text,p_data_connection_status text,p_source_contract_id bigint,
 p_generated_by_run_id bigint)
RETURNS text LANGUAGE sql IMMUTABLE STRICT AS $fn$
SELECT md5(concat_ws('|',
 p_scenario_id::text,p_base_row_hash,
 to_char(p_direct_shock_factor::numeric(12,8),'FM9999999999999990.00000000'),
 to_char(p_propagated_shock_factor::numeric(12,8),'FM9999999999999990.00000000'),
 p_scenario_overlay_payload::text,p_population_id,p_merchant_id,p_processor_account_id,p_observation_date::text,
 to_char(p_gross_pos_sales::numeric(18,2),'FM9999999999999999999990.00'),p_transaction_count::text,
 to_char(p_average_ticket_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_refund_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_chargeback_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_reversal_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_governed_exclusion_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_eligible_pos_sales::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_processor_fee_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_settlement_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_net_merchant_proceeds::numeric(18,2),'FM9999999999999999999990.00'),
 p_zero_sales_day_flag::text,p_processor_status,p_data_connection_status,p_source_contract_id::text,p_generated_by_run_id::text));
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_6_deposit_scenario_row_hash(
 p_scenario_id bigint,p_base_row_hash text,p_scenario_overlay_payload jsonb,p_population_id text,p_merchant_id text,
 p_observation_date date,p_opening_balance numeric,p_deposit_amount numeric,p_withdrawal_amount numeric,
 p_closing_balance numeric,p_available_balance numeric,p_minimum_balance numeric,p_nsf_count smallint,
 p_negative_balance_flag boolean,p_source_contract_id bigint,p_generated_by_run_id bigint)
RETURNS text LANGUAGE sql IMMUTABLE STRICT AS $fn$
SELECT md5(concat_ws('|',
 p_scenario_id::text,p_base_row_hash,p_scenario_overlay_payload::text,p_population_id,p_merchant_id,p_observation_date::text,
 to_char(p_opening_balance::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_deposit_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_withdrawal_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_closing_balance::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_available_balance::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_minimum_balance::numeric(18,2),'FM9999999999999999999990.00'),
 p_nsf_count::text,p_negative_balance_flag::text,p_source_contract_id::text,p_generated_by_run_id::text));
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_6_industry_shock_matrix()
RETURNS TABLE(industry_code text,direct_sensitivity numeric(12,8),energy_dependency_weight numeric(12,8),shock_channel text)
LANGUAGE sql IMMUTABLE AS $fn$
SELECT * FROM (VALUES
 ('ENERGY_SERVICES',          1.00000000::numeric,0.00000000::numeric,'DIRECT_ENERGY_DEMAND'),
 ('TRANSPORTATION_LOGISTICS', 0.35000000::numeric,0.70000000::numeric,'FUEL_AND_ENERGY_DEPENDENCY'),
 ('CONSTRUCTION_TRADES',      0.30000000::numeric,0.55000000::numeric,'CAPITAL_SPEND_AND_INPUT_DEPENDENCY'),
 ('RESTAURANT_FOOD_SERVICE',  0.22000000::numeric,0.35000000::numeric,'CONSUMER_AND_REGIONAL_EMPLOYMENT'),
 ('GENERAL_RETAIL',           0.20000000::numeric,0.30000000::numeric,'CONSUMER_AND_SUPPLY_CHAIN'),
 ('ECOMMERCE_DIGITAL',        0.15000000::numeric,0.22000000::numeric,'CONSUMER_AND_LOGISTICS'),
 ('PROFESSIONAL_SERVICES',    0.10000000::numeric,0.15000000::numeric,'BUSINESS_SPEND_DEPENDENCY'),
 ('HEALTHCARE_SERVICES',      0.05000000::numeric,0.10000000::numeric,'LOWER_CYCLICAL_DEPENDENCY')
) v(industry_code,direct_sensitivity,energy_dependency_weight,shock_channel);
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_6_scenario_profile(p_run_id bigint)
RETURNS TABLE(
 scenario_id bigint,scenario_set_id bigint,scenario_code text,scenario_version integer,scenario_name text,scenario_type text,
 parameter_set_id bigint,sales_level_multiplier numeric(12,8),sales_volatility_multiplier numeric(12,8),
 zero_sales_probability_multiplier numeric(12,8),refund_rate_multiplier numeric(12,8),chargeback_rate_multiplier numeric(12,8),
 deposit_capture_multiplier numeric(12,8),obligation_multiplier numeric(12,8),processor_outage_rate numeric(12,8),
 direct_shock_cap numeric(12,8),propagated_shock_cap numeric(12,8),damping_factor numeric(12,8),lag_days integer,
 matched_share_min numeric(12,8),liquidity_shock_multiplier numeric(12,8),history_start_date date,history_end_date date,
 shock_start_date date,propagation_start_date date,stress_window_days integer)
LANGUAGE sql STABLE AS $fn$
WITH ctx AS (
 SELECT r.run_id,p.history_start_date,p.history_end_date
 FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_id=p_run_id
), global_params AS (
 SELECT
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='scenario_direct_shock_cap' AND scope_key='GLOBAL') AS direct_cap,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='scenario_propagated_shock_cap' AND scope_key='GLOBAL') AS propagated_cap,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='scenario_damping_factor' AND scope_key='GLOBAL') AS damping,
  max(((resolved_value->>'value_numeric')::numeric)::integer) FILTER(WHERE parameter_name='scenario_lag_days' AND scope_key='GLOBAL') AS lag_days,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='qa_min_scenario_matched_share' AND scope_key='GLOBAL') AS matched_share,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='liquidity_shock_multiplier' AND scope_key='GLOBAL') AS liquidity_multiplier
 FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id
), scenario_params AS (
 SELECT split_part(scope_key,':',2) AS scenario_code,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='scenario_sales_level_multiplier') AS sales_level,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='scenario_sales_volatility_multiplier') AS volatility_multiplier,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='scenario_zero_sales_probability_multiplier') AS zero_multiplier,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='scenario_refund_rate_multiplier') AS refund_multiplier,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='scenario_chargeback_rate_multiplier') AS chargeback_multiplier,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='scenario_deposit_capture_multiplier') AS deposit_multiplier,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='scenario_obligation_multiplier') AS obligation_multiplier,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='scenario_processor_outage_rate') AS outage_rate
 FROM msbf_ctl.run_parameter_snapshot
 WHERE run_id=p_run_id AND scope_key IN ('SCENARIO:BASELINE','SCENARIO:RECESSION_ENERGY')
 GROUP BY split_part(scope_key,':',2)
), approved AS (
 SELECT sr.* FROM msbf_ctl.scenario_registry sr
 JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
 WHERE ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS' AND ss.scenario_set_version=1
   AND ss.status='APPROVED' AND sr.status='APPROVED'
   AND ((sr.scenario_code='BASELINE' AND sr.scenario_version=1)
     OR (sr.scenario_code='RECESSION_ENERGY' AND sr.scenario_version=1))
)
SELECT a.scenario_id,a.scenario_set_id,a.scenario_code,a.scenario_version,a.scenario_name,a.scenario_type,a.parameter_set_id,
       sp.sales_level::numeric(12,8),sp.volatility_multiplier::numeric(12,8),sp.zero_multiplier::numeric(12,8),
       sp.refund_multiplier::numeric(12,8),sp.chargeback_multiplier::numeric(12,8),sp.deposit_multiplier::numeric(12,8),
       sp.obligation_multiplier::numeric(12,8),sp.outage_rate::numeric(12,8),
       gp.direct_cap::numeric(12,8),gp.propagated_cap::numeric(12,8),gp.damping::numeric(12,8),gp.lag_days,
       gp.matched_share::numeric(12,8),gp.liquidity_multiplier::numeric(12,8),ctx.history_start_date,ctx.history_end_date,
       CASE WHEN a.scenario_type='BASELINE' THEN ctx.history_start_date ELSE ctx.history_end_date-59 END AS shock_start_date,
       CASE WHEN a.scenario_type='BASELINE' THEN ctx.history_start_date ELSE (ctx.history_end_date-59)+gp.lag_days END AS propagation_start_date,
       CASE WHEN a.scenario_type='BASELINE' THEN (ctx.history_end_date-ctx.history_start_date+1)::integer ELSE 60 END AS stress_window_days
FROM approved a JOIN scenario_params sp ON sp.scenario_code=a.scenario_code CROSS JOIN ctx CROSS JOIN global_params gp
ORDER BY CASE a.scenario_type WHEN 'BASELINE' THEN 1 ELSE 2 END;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_6_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $fn$
DECLARE
 v_status text; v_population_status text; v_population_id text; v_history_days integer;
 v_g1 text; v_m12 text; v_m13 text; v_m14 text; v_m15 text;
 v_parameter_hash text; v_profile_hash text; v_source_hash text; v_population_hash text;
 v_reparameter text; v_reprofile text; v_resource text; v_repopulation text;
 v_application_hash text; v_pos_hash text; v_deposit_hash text;
 v_reapplication text; v_repos text; v_redeposit text;
 v_required integer; v_resolved integer; v_enabled boolean;
 v_scenarios integer; v_baseline integer; v_stress integer; v_pos_source integer; v_deposit_source integer;
 v_base_pos bigint; v_base_deposit bigint; v_scenario_pos bigint; v_scenario_deposit bigint; v_downstream bigint; v_errors bigint;
BEGIN
 SELECT r.run_status,p.population_status,r.population_id,(p.history_end_date-p.history_start_date+1)::integer,
        r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,p.population_hash
 INTO STRICT v_status,v_population_status,v_population_id,v_history_days,v_parameter_hash,v_profile_hash,v_source_hash,v_population_hash
 FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_id=p_run_id;

 SELECT result_status INTO v_g1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1;
 SELECT result_status INTO v_m12 FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1;
 SELECT result_status INTO v_m13 FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1;
 SELECT result_status INTO v_m14 FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='M1_4_DAILY_POS_HISTORY' ORDER BY review_version DESC LIMIT 1;
 SELECT result_status INTO v_m15 FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY' ORDER BY review_version DESC LIMIT 1;

 SELECT metric_value_text INTO v_application_hash FROM msbf_ctl.run_evidence WHERE run_id=p_run_id AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO';
 SELECT metric_value_text INTO v_pos_hash FROM msbf_ctl.run_evidence WHERE run_id=p_run_id AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO';
 SELECT metric_value_text INTO v_deposit_hash FROM msbf_ctl.run_evidence WHERE run_id=p_run_id AND evidence_code='M1_5_DEPOSIT_SET_HASH' AND segment_key='PORTFOLIO';

 WITH required_parameters(parameter_name,scope_key) AS (
  VALUES
  ('enable_scenario_history_flag','GLOBAL'),('scenario_direct_shock_cap','GLOBAL'),('scenario_propagated_shock_cap','GLOBAL'),
  ('scenario_damping_factor','GLOBAL'),('scenario_lag_days','GLOBAL'),('qa_min_scenario_matched_share','GLOBAL'),
  ('liquidity_shock_multiplier','GLOBAL'),('qa_reconciliation_tolerance_amount','GLOBAL'),
  ('scenario_sales_level_multiplier','SCENARIO:BASELINE'),('scenario_sales_volatility_multiplier','SCENARIO:BASELINE'),
  ('scenario_zero_sales_probability_multiplier','SCENARIO:BASELINE'),('scenario_refund_rate_multiplier','SCENARIO:BASELINE'),
  ('scenario_chargeback_rate_multiplier','SCENARIO:BASELINE'),('scenario_deposit_capture_multiplier','SCENARIO:BASELINE'),
  ('scenario_obligation_multiplier','SCENARIO:BASELINE'),('scenario_processor_outage_rate','SCENARIO:BASELINE'),
  ('scenario_sales_level_multiplier','SCENARIO:RECESSION_ENERGY'),('scenario_sales_volatility_multiplier','SCENARIO:RECESSION_ENERGY'),
  ('scenario_zero_sales_probability_multiplier','SCENARIO:RECESSION_ENERGY'),('scenario_refund_rate_multiplier','SCENARIO:RECESSION_ENERGY'),
  ('scenario_chargeback_rate_multiplier','SCENARIO:RECESSION_ENERGY'),('scenario_deposit_capture_multiplier','SCENARIO:RECESSION_ENERGY'),
  ('scenario_obligation_multiplier','SCENARIO:RECESSION_ENERGY'),('scenario_processor_outage_rate','SCENARIO:RECESSION_ENERGY'),
  ('industry_zero_sales_day_probability','INDUSTRY:RESTAURANT_FOOD_SERVICE'),('industry_zero_sales_day_probability','INDUSTRY:GENERAL_RETAIL'),
  ('industry_zero_sales_day_probability','INDUSTRY:PROFESSIONAL_SERVICES'),('industry_zero_sales_day_probability','INDUSTRY:CONSTRUCTION_TRADES'),
  ('industry_zero_sales_day_probability','INDUSTRY:TRANSPORTATION_LOGISTICS'),('industry_zero_sales_day_probability','INDUSTRY:ENERGY_SERVICES'),
  ('industry_zero_sales_day_probability','INDUSTRY:HEALTHCARE_SERVICES'),('industry_zero_sales_day_probability','INDUSTRY:ECOMMERCE_DIGITAL')
 )
 SELECT COUNT(*),COUNT(rps.parameter_name) INTO v_required,v_resolved
 FROM required_parameters req LEFT JOIN msbf_ctl.run_parameter_snapshot rps
   ON rps.run_id=p_run_id AND rps.parameter_name=req.parameter_name AND rps.scope_key=req.scope_key;

 SELECT (resolved_value->>'value_boolean')::boolean INTO v_enabled FROM msbf_ctl.run_parameter_snapshot
 WHERE run_id=p_run_id AND parameter_name='enable_scenario_history_flag' AND scope_key='GLOBAL';

 SELECT COUNT(*),COUNT(*) FILTER(WHERE scenario_code='BASELINE'),COUNT(*) FILTER(WHERE scenario_code='RECESSION_ENERGY')
 INTO v_scenarios,v_baseline,v_stress FROM msbf_m1.m1_6_scenario_profile(p_run_id);

 SELECT COUNT(*) FILTER(WHERE source_code='POS_DAILY' AND quality_status='CONTRACT_READY_PRE_GENERATION'),
        COUNT(*) FILTER(WHERE source_code='DEPOSIT_DAILY' AND quality_status='CONTRACT_READY_PRE_GENERATION')
 INTO v_pos_source,v_deposit_source FROM msbf_ctl.run_source_snapshot WHERE run_id=p_run_id;

 SELECT COUNT(*) INTO v_base_pos FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=p_run_id;
 SELECT COUNT(*) INTO v_base_deposit FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=p_run_id;
 SELECT COUNT(*) INTO v_scenario_pos FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=p_run_id;
 SELECT COUNT(*) INTO v_scenario_deposit FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=p_run_id;
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=p_run_id)
 INTO v_downstream;
 SELECT COUNT(*) INTO v_errors FROM msbf_ctl.profile_resolution_error WHERE run_id=p_run_id AND severity='BLOCKING';

 IF v_status<>'M1_5_ACCEPTED' THEN RAISE EXCEPTION 'M1.6 generation requires run_status=M1_5_ACCEPTED; observed %.',v_status; END IF;
 IF v_population_status<>'M1_2_ACCEPTED' THEN RAISE EXCEPTION 'M1.6 requires population_status=M1_2_ACCEPTED; observed %.',v_population_status; END IF;
 IF v_g1 IS DISTINCT FROM 'PASS' OR v_m12 IS DISTINCT FROM 'PASS' OR v_m13 IS DISTINCT FROM 'PASS' OR v_m14 IS DISTINCT FROM 'PASS' OR v_m15 IS DISTINCT FROM 'PASS' THEN
  RAISE EXCEPTION 'M1.6 requires accepted G1, M1.2, M1.3, M1.4, and M1.5 gates.';
 END IF;
 IF v_required<>32 OR v_resolved<>32 THEN RAISE EXCEPTION 'M1.6 requires 32 resolved parameter/scope pairs; observed % of %.',v_resolved,v_required; END IF;
 IF NOT COALESCE(v_enabled,false) THEN RAISE EXCEPTION 'M1.6 scenario history is not enabled in the frozen run snapshot.'; END IF;
 IF v_scenarios<>2 OR v_baseline<>1 OR v_stress<>1 THEN RAISE EXCEPTION 'M1.6 requires exactly two approved scenarios (BASELINE and RECESSION_ENERGY); observed total %, baseline %, stress %.',v_scenarios,v_baseline,v_stress; END IF;
 IF v_pos_source<>1 OR v_deposit_source<>1 THEN RAISE EXCEPTION 'M1.6 requires one contract-ready POS_DAILY and one contract-ready DEPOSIT_DAILY source snapshot; observed POS %, deposit %.',v_pos_source,v_deposit_source; END IF;
 IF v_history_days<>180 OR v_base_pos<>135000 OR v_base_deposit<>135000 THEN RAISE EXCEPTION 'M1.6 requires accepted 180-day POS and deposit histories (135000 rows each); observed days %, POS %, deposit %.',v_history_days,v_base_pos,v_base_deposit; END IF;
 IF v_scenario_pos<>0 OR v_scenario_deposit<>0 THEN RAISE EXCEPTION 'M1.6 scenario rows already exist (POS %, deposit %); regeneration is prohibited.',v_scenario_pos,v_scenario_deposit; END IF;
 IF v_downstream<>0 THEN RAISE EXCEPTION 'M1.6 downstream analytical rows already exist (% rows); generation is prohibited.',v_downstream; END IF;
 IF v_errors<>0 THEN RAISE EXCEPTION 'M1.6 blocking configuration errors exist (% rows).',v_errors; END IF;

 SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key)) INTO v_reparameter FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id;
 SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code)) INTO v_reprofile FROM msbf_ctl.run_profile_snapshot WHERE run_id=p_run_id;
 SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code)) INTO v_resource FROM msbf_ctl.run_source_snapshot WHERE run_id=p_run_id;
 SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) INTO v_repopulation FROM msbf_m1.m1_2_actual_entity_snapshot(p_run_id);
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) INTO v_reapplication FROM msbf_m1.m1_3_actual_application_snapshot(p_run_id);
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) INTO v_repos FROM msbf_m1.m1_4_actual_pos_snapshot(p_run_id);
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) INTO v_redeposit FROM msbf_m1.m1_5_actual_deposit_snapshot(p_run_id);
 IF v_parameter_hash IS DISTINCT FROM v_reparameter OR v_profile_hash IS DISTINCT FROM v_reprofile OR v_source_hash IS DISTINCT FROM v_resource
    OR v_population_hash IS DISTINCT FROM v_repopulation OR v_application_hash IS DISTINCT FROM v_reapplication
    OR v_pos_hash IS DISTINCT FROM v_repos OR v_deposit_hash IS DISTINCT FROM v_redeposit THEN
  RAISE EXCEPTION 'M1.6 accepted upstream hashes do not reconcile.';
 END IF;
END $fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_6_pos_scenario_blueprint(p_run_id bigint)
RETURNS TABLE(
 scenario_id bigint,base_row_hash text,direct_shock_factor numeric(12,8),propagated_shock_factor numeric(12,8),scenario_overlay_payload jsonb,
 population_id text,merchant_id text,processor_account_id text,observation_date date,gross_pos_sales numeric(18,2),transaction_count integer,
 average_ticket_amount numeric(18,2),refund_amount numeric(18,2),chargeback_amount numeric(18,2),reversal_amount numeric(18,2),
 governed_exclusion_amount numeric(18,2),eligible_pos_sales numeric(18,2),processor_fee_amount numeric(18,2),settlement_amount numeric(18,2),
 net_merchant_proceeds numeric(18,2),zero_sales_day_flag boolean,processor_status text,data_connection_status text,source_contract_id bigint,
 generated_by_run_id bigint,row_hash text,scenario_code text,scenario_type text,industry_code text,shock_active_flag boolean,
 propagation_active_flag boolean,scenario_outage_flag boolean,incremental_zero_sales_flag boolean,volatility_overlay_factor numeric(12,8),
 total_sales_factor numeric(12,8),baseline_gross_pos_sales numeric(18,2),baseline_eligible_pos_sales numeric(18,2),shock_channel text)
LANGUAGE sql STABLE AS $fn$
WITH ctx AS (
 SELECT r.run_id,r.population_id,p.deterministic_seed_version FROM msbf_ctl.run_registry r
 JOIN msbf_m1.population_registry p ON p.population_id=r.population_id WHERE r.run_id=p_run_id
), scenario_profile AS (
 SELECT * FROM msbf_m1.m1_6_scenario_profile(p_run_id)
), matrix AS (
 SELECT * FROM msbf_m1.m1_6_industry_shock_matrix()
), industry_zero AS (
 SELECT split_part(scope_key,':',2) AS industry_code,(resolved_value->>'value_numeric')::numeric AS zero_probability
 FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name='industry_zero_sales_day_probability' AND scope_key LIKE 'INDUSTRY:%'
), base AS (
 SELECT b.*,op.industry_code,op.settlement_delay_days,op.processor_fee_rate,iz.zero_probability,
        sp.*,mx.direct_sensitivity,mx.energy_dependency_weight,mx.shock_channel,ctx.deterministic_seed_version,
        msbf_ctl.deterministic_uniform(b.merchant_id||'|'||b.observation_date||'|'||sp.scenario_code,ctx.deterministic_seed_version||':M1_6:VOLATILITY') AS u_volatility,
        msbf_ctl.deterministic_uniform(b.merchant_id||'|'||b.observation_date||'|'||sp.scenario_code,ctx.deterministic_seed_version||':M1_6:ZERO') AS u_zero,
        msbf_ctl.deterministic_uniform(b.merchant_id||'|'||b.observation_date||'|'||sp.scenario_code,ctx.deterministic_seed_version||':M1_6:OUTAGE') AS u_outage
 FROM msbf_m1.merchant_pos_daily_base b
 JOIN msbf_m1.m1_4_merchant_operating_profile(p_run_id) op ON op.merchant_id=b.merchant_id AND op.processor_account_id=b.processor_account_id
 JOIN industry_zero iz ON iz.industry_code=op.industry_code
 JOIN matrix mx ON mx.industry_code=op.industry_code
 CROSS JOIN scenario_profile sp CROSS JOIN ctx
 WHERE b.generated_by_run_id=p_run_id
), factors AS (
 SELECT b.*,
  (b.scenario_type='STRESS' AND b.observation_date>=b.shock_start_date) AS shock_active,
  (b.scenario_type='STRESS' AND b.observation_date>=b.propagation_start_date) AS propagation_active,
  CASE WHEN b.scenario_type='STRESS' AND b.observation_date>=b.shock_start_date
       THEN greatest(1-b.direct_shock_cap,1-(1-b.sales_level_multiplier)*b.direct_sensitivity) ELSE 1 END::numeric AS direct_factor,
  CASE WHEN b.scenario_type='STRESS' AND b.observation_date>=b.propagation_start_date
       THEN greatest(1-b.propagated_shock_cap,1-(1-b.sales_level_multiplier)*b.energy_dependency_weight*b.damping_factor) ELSE 1 END::numeric AS propagated_factor,
  CASE WHEN b.scenario_type='STRESS' AND b.observation_date>=b.shock_start_date
       THEN greatest(0.65,least(1.35,1+(b.sales_volatility_multiplier-1)*(2*b.u_volatility-1))) ELSE 1 END::numeric AS volatility_factor,
  CASE WHEN b.scenario_type='STRESS' AND b.observation_date>=b.shock_start_date
       THEN least(0.20,greatest(0,b.zero_probability*(b.zero_sales_probability_multiplier-1))) ELSE 0 END::numeric AS incremental_zero_probability,
  CASE WHEN b.scenario_type='STRESS' AND b.observation_date>=b.shock_start_date AND b.processor_status<>'NOT_YET_ACTIVE' AND b.u_outage<b.processor_outage_rate
       THEN true ELSE false END AS scenario_outage,
  CASE WHEN b.scenario_type='STRESS' AND b.observation_date>=b.shock_start_date AND b.gross_pos_sales>0
             AND b.u_zero<least(0.20,greatest(0,b.zero_probability*(b.zero_sales_probability_multiplier-1)))
       THEN true ELSE false END AS incremental_zero
 FROM base b
), grossed AS (
 SELECT f.*,
  CASE WHEN f.scenario_type='BASELINE' THEN f.gross_pos_sales
       WHEN f.gross_pos_sales=0 OR f.processor_status='NOT_YET_ACTIVE' OR f.scenario_outage OR f.incremental_zero THEN 0.00::numeric
       ELSE round(least(2000000.00,f.gross_pos_sales*f.direct_factor*f.propagated_factor*f.volatility_factor),2)::numeric END AS scenario_gross,
  CASE WHEN f.gross_pos_sales>0 THEN f.refund_amount/f.gross_pos_sales ELSE 0 END::numeric AS base_refund_rate,
  CASE WHEN f.gross_pos_sales>0 THEN f.chargeback_amount/f.gross_pos_sales ELSE 0 END::numeric AS base_chargeback_rate,
  CASE WHEN f.gross_pos_sales>0 THEN f.reversal_amount/f.gross_pos_sales ELSE 0 END::numeric AS base_reversal_rate,
  CASE WHEN f.gross_pos_sales>0 THEN f.governed_exclusion_amount/f.gross_pos_sales ELSE 0 END::numeric AS base_exclusion_rate
 FROM factors f
), transacted AS (
 SELECT g.*,
  CASE WHEN g.scenario_type='BASELINE' THEN g.transaction_count
       WHEN g.scenario_gross=0 THEN 0
       ELSE greatest(1,round(g.transaction_count*(g.scenario_gross/NULLIF(g.gross_pos_sales,0)))::integer) END AS scenario_txn_count
 FROM grossed g
), quality AS (
 SELECT t.*,
  CASE WHEN t.scenario_type='BASELINE' OR NOT t.shock_active THEN t.average_ticket_amount
       WHEN t.scenario_txn_count=0 THEN 0.00::numeric ELSE round(t.scenario_gross/t.scenario_txn_count,2)::numeric END AS scenario_avg_ticket,
  CASE WHEN t.scenario_type='BASELINE' OR NOT t.shock_active THEN t.refund_amount
       ELSE round(t.scenario_gross*least(0.25,t.base_refund_rate*t.refund_rate_multiplier),2)::numeric END AS scenario_refund,
  CASE WHEN t.scenario_type='BASELINE' OR NOT t.shock_active THEN t.chargeback_amount
       ELSE round(t.scenario_gross*least(0.10,t.base_chargeback_rate*t.chargeback_rate_multiplier),2)::numeric END AS scenario_chargeback,
  CASE WHEN t.scenario_type='BASELINE' OR NOT t.shock_active THEN t.reversal_amount
       ELSE round(t.scenario_gross*least(0.05,t.base_reversal_rate),2)::numeric END AS scenario_reversal,
  CASE WHEN t.scenario_type='BASELINE' OR NOT t.shock_active THEN t.governed_exclusion_amount
       ELSE round(t.scenario_gross*least(0.05,t.base_exclusion_rate),2)::numeric END AS scenario_exclusion
 FROM transacted t
), eligible AS (
 SELECT q.*,
  CASE WHEN q.scenario_type='BASELINE' OR NOT q.shock_active THEN q.eligible_pos_sales
       ELSE greatest(q.scenario_gross-q.scenario_refund-q.scenario_chargeback-q.scenario_reversal-q.scenario_exclusion,0.00)::numeric END AS scenario_eligible,
  CASE WHEN q.scenario_type='BASELINE' OR NOT q.shock_active THEN q.processor_status
       WHEN q.processor_status='NOT_YET_ACTIVE' THEN 'NOT_YET_ACTIVE'
       WHEN q.scenario_outage THEN 'OUTAGE' ELSE q.processor_status END AS scenario_processor_status,
  CASE WHEN q.scenario_type='BASELINE' OR NOT q.shock_active THEN q.data_connection_status
       WHEN q.processor_status='NOT_YET_ACTIVE' THEN 'NOT_CONNECTED'
       WHEN q.scenario_outage THEN 'DISCONNECTED' ELSE q.data_connection_status END AS scenario_connection_status
 FROM quality q
), settled AS (
 SELECT curr.*,
  CASE WHEN curr.scenario_type='BASELINE' OR NOT curr.shock_active THEN curr.settlement_amount ELSE coalesce(prior.scenario_eligible,0.00) END::numeric AS scenario_settlement
 FROM eligible curr
 LEFT JOIN eligible prior ON prior.scenario_id=curr.scenario_id AND prior.merchant_id=curr.merchant_id
  AND prior.processor_account_id=curr.processor_account_id
  AND prior.observation_date=(curr.observation_date-curr.settlement_delay_days)::date
), final_rows AS (
 SELECT s.*,
  CASE WHEN s.scenario_type='BASELINE' OR NOT s.shock_active THEN s.processor_fee_amount ELSE round(s.scenario_settlement*s.processor_fee_rate,2)::numeric END AS scenario_fee,
  CASE WHEN s.scenario_type='BASELINE' OR NOT s.shock_active THEN s.net_merchant_proceeds ELSE (s.scenario_settlement-round(s.scenario_settlement*s.processor_fee_rate,2))::numeric END AS scenario_net,
  jsonb_build_object(
    'scenario_code',s.scenario_code,'scenario_version',s.scenario_version,'scenario_type',s.scenario_type,
    'overlay_applied',(s.scenario_type='STRESS' AND s.shock_active),'shock_start_date',s.shock_start_date,'propagation_start_date',s.propagation_start_date,
    'industry_code',s.industry_code,'shock_channel',s.shock_channel,'direct_sensitivity',s.direct_sensitivity,
    'energy_dependency_weight',s.energy_dependency_weight,'sales_level_multiplier',s.sales_level_multiplier,
    'sales_volatility_multiplier',s.sales_volatility_multiplier,'zero_sales_probability_multiplier',s.zero_sales_probability_multiplier,
    'refund_rate_multiplier',s.refund_rate_multiplier,'chargeback_rate_multiplier',s.chargeback_rate_multiplier,
    'processor_outage_rate',s.processor_outage_rate,'shock_active_flag',s.shock_active,
    'propagation_active_flag',s.propagation_active,'scenario_outage_flag',s.scenario_outage,
    'incremental_zero_sales_flag',s.incremental_zero,'volatility_overlay_factor',round(s.volatility_factor,8)
  ) AS payload
 FROM settled s
)
SELECT f.scenario_id,f.row_hash AS base_row_hash,f.direct_factor::numeric(12,8),f.propagated_factor::numeric(12,8),f.payload,
       f.population_id,f.merchant_id,f.processor_account_id,f.observation_date,f.scenario_gross::numeric(18,2),f.scenario_txn_count,
       f.scenario_avg_ticket::numeric(18,2),f.scenario_refund::numeric(18,2),f.scenario_chargeback::numeric(18,2),
       f.scenario_reversal::numeric(18,2),f.scenario_exclusion::numeric(18,2),f.scenario_eligible::numeric(18,2),
       f.scenario_fee::numeric(18,2),f.scenario_settlement::numeric(18,2),f.scenario_net::numeric(18,2),
       (f.scenario_gross=0),f.scenario_processor_status,f.scenario_connection_status,f.source_contract_id,f.generated_by_run_id,
       msbf_m1.m1_6_pos_scenario_row_hash(f.scenario_id,f.row_hash,f.direct_factor,f.propagated_factor,f.payload,
         f.population_id,f.merchant_id,f.processor_account_id,f.observation_date,f.scenario_gross,f.scenario_txn_count,
         f.scenario_avg_ticket,f.scenario_refund,f.scenario_chargeback,f.scenario_reversal,f.scenario_exclusion,
         f.scenario_eligible,f.scenario_fee,f.scenario_settlement,f.scenario_net,(f.scenario_gross=0),
         f.scenario_processor_status,f.scenario_connection_status,f.source_contract_id,f.generated_by_run_id) AS scenario_row_hash,
       f.scenario_code,f.scenario_type,f.industry_code,f.shock_active,f.propagation_active,f.scenario_outage,f.incremental_zero,
       f.volatility_factor::numeric(12,8),(f.direct_factor*f.propagated_factor*f.volatility_factor)::numeric(12,8),
       f.gross_pos_sales,f.eligible_pos_sales,f.shock_channel
FROM final_rows f
ORDER BY f.scenario_id,f.merchant_id,f.observation_date;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_6_deposit_scenario_blueprint(p_run_id bigint)
RETURNS TABLE(
 scenario_id bigint,base_row_hash text,scenario_overlay_payload jsonb,population_id text,merchant_id text,observation_date date,
 opening_balance numeric(18,2),deposit_amount numeric(18,2),withdrawal_amount numeric(18,2),closing_balance numeric(18,2),
 available_balance numeric(18,2),minimum_balance numeric(18,2),nsf_count smallint,negative_balance_flag boolean,
 source_contract_id bigint,generated_by_run_id bigint,row_hash text,scenario_code text,scenario_type text,industry_code text,
 liquidity_risk_tier smallint,shock_active_flag boolean,base_pos_deposit_amount numeric(18,2),support_deposit_amount numeric(18,2),
 temporary_hold_amount numeric(18,2),adjusted_nsf_probability numeric(12,8),liquidity_event_code text,
 baseline_deposit_amount numeric(18,2),baseline_withdrawal_amount numeric(18,2))
LANGUAGE sql STABLE AS $fn$
WITH ctx AS (
 SELECT r.run_id,r.population_id,p.deterministic_seed_version FROM msbf_ctl.run_registry r
 JOIN msbf_m1.population_registry p ON p.population_id=r.population_id WHERE r.run_id=p_run_id
), sp AS (
 SELECT * FROM msbf_m1.m1_6_scenario_profile(p_run_id)
), profile AS (
 SELECT * FROM msbf_m1.m1_5_merchant_liquidity_profile(p_run_id)
), base_blueprint AS (
 SELECT * FROM msbf_m1.m1_5_daily_liquidity_blueprint(p_run_id)
), grid AS (
 SELECT d.*,bb.industry_code,bb.liquidity_risk_tier,bb.daily_capture_rate,bb.base_pos_deposit_amount,
        bb.temporary_hold_amount,bb.target_buffer_amount,bb.lower_balance_floor,bb.adjusted_nsf_probability AS baseline_adjusted_nsf_probability,
        pr.nsf_daily_probability,pr.negative_balance_daily_probability,pr.initial_opening_balance,
        ps.scenario_id,ps.scenario_code,ps.scenario_type,ps.scenario_version,ps.shock_start_date,
        ps.deposit_capture_multiplier,ps.obligation_multiplier,ps.liquidity_shock_multiplier,
        ppos.net_merchant_proceeds AS scenario_net_merchant_proceeds,ppos.refund_amount AS scenario_refund_amount,
        ppos.chargeback_amount AS scenario_chargeback_amount,ppos.reversal_amount AS scenario_reversal_amount,
        ppos.processor_status AS scenario_processor_status,ppos.row_hash AS scenario_pos_row_hash,
        ctx.deterministic_seed_version,
        msbf_ctl.deterministic_uniform(d.merchant_id||'|'||d.observation_date||'|'||ps.scenario_code,ctx.deterministic_seed_version||':M1_6:HOLD') AS u_hold,
        msbf_ctl.deterministic_uniform(d.merchant_id||'|'||d.observation_date||'|'||ps.scenario_code,ctx.deterministic_seed_version||':M1_6:NSF') AS u_nsf,
        msbf_ctl.deterministic_uniform(d.merchant_id||'|'||d.observation_date||'|'||ps.scenario_code,ctx.deterministic_seed_version||':M1_6:NSF_COUNT') AS u_nsf_count
 FROM msbf_m1.merchant_deposit_daily_base d
 JOIN base_blueprint bb ON bb.merchant_id=d.merchant_id AND bb.observation_date=d.observation_date
 JOIN profile pr ON pr.merchant_id=d.merchant_id
 CROSS JOIN sp ps
 JOIN msbf_m1.merchant_pos_daily_scenario ppos ON ppos.scenario_id=ps.scenario_id AND ppos.population_id=d.population_id
  AND ppos.merchant_id=d.merchant_id AND ppos.observation_date=d.observation_date AND ppos.generated_by_run_id=p_run_id
 CROSS JOIN ctx
 WHERE d.generated_by_run_id=p_run_id
), planned AS (
 SELECT g.*,(g.scenario_type='STRESS' AND g.observation_date>=g.shock_start_date) AS shock_active,
  CASE WHEN g.scenario_type='BASELINE' OR g.observation_date<g.shock_start_date THEN g.base_pos_deposit_amount
       WHEN g.scenario_processor_status='NOT_YET_ACTIVE' THEN 0.00::numeric
       ELSE round(g.scenario_net_merchant_proceeds*g.daily_capture_rate*g.deposit_capture_multiplier,2)::numeric END AS scenario_pos_deposit,
  CASE WHEN g.scenario_type='BASELINE' OR g.observation_date<g.shock_start_date THEN g.withdrawal_amount
       ELSE round(g.withdrawal_amount*g.obligation_multiplier,2)::numeric END AS scenario_withdrawal,
  CASE WHEN g.scenario_type='BASELINE' OR g.observation_date<g.shock_start_date THEN g.temporary_hold_amount
       WHEN g.scenario_processor_status='NOT_YET_ACTIVE' THEN 0.00::numeric
       ELSE round((g.scenario_chargeback_amount+g.scenario_reversal_amount+0.20*g.scenario_refund_amount)*(0.50+0.50*g.u_hold),2)::numeric END AS scenario_hold
 FROM grid g
), raw_flows AS (
 SELECT p.*,(p.scenario_pos_deposit-p.scenario_withdrawal)::numeric(18,2) AS raw_net_flow
 FROM planned p
), raw_balances AS (
 SELECT r.*,(r.initial_opening_balance+
   SUM(r.raw_net_flow) OVER(PARTITION BY r.scenario_id,r.merchant_id ORDER BY r.observation_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW))::numeric(18,2) AS raw_closing_balance
 FROM raw_flows r
), support_cumulative AS (
 SELECT r.*,greatest(0.00,(r.lower_balance_floor*r.liquidity_shock_multiplier)-
   MIN(r.raw_closing_balance) OVER(PARTITION BY r.scenario_id,r.merchant_id ORDER BY r.observation_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW))::numeric(18,2) AS cumulative_support_deposit
 FROM raw_balances r
), support_increment AS (
 SELECT s.*,(s.cumulative_support_deposit-
   lag(s.cumulative_support_deposit,1,0.00::numeric) OVER(PARTITION BY s.scenario_id,s.merchant_id ORDER BY s.observation_date))::numeric(18,2) AS support_deposit_increment
 FROM support_cumulative s
), balanced AS (
 SELECT s.*,
  CASE WHEN s.scenario_type='BASELINE' OR NOT s.shock_active THEN s.deposit_amount ELSE (s.scenario_pos_deposit+s.support_deposit_increment)::numeric(18,2) END AS final_deposit,
  CASE WHEN s.scenario_type='BASELINE' OR NOT s.shock_active THEN s.withdrawal_amount ELSE s.scenario_withdrawal::numeric(18,2) END AS final_withdrawal,
  CASE WHEN s.scenario_type='BASELINE' OR NOT s.shock_active THEN s.opening_balance ELSE
   (s.initial_opening_balance+COALESCE(SUM(s.raw_net_flow+s.support_deposit_increment) OVER(PARTITION BY s.scenario_id,s.merchant_id ORDER BY s.observation_date ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0.00))::numeric(18,2) END AS scenario_opening,
  CASE WHEN s.scenario_type='BASELINE' OR NOT s.shock_active THEN s.closing_balance ELSE
   (s.initial_opening_balance+SUM(s.raw_net_flow+s.support_deposit_increment) OVER(PARTITION BY s.scenario_id,s.merchant_id ORDER BY s.observation_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW))::numeric(18,2) END AS scenario_closing
 FROM support_increment s
), available AS (
 SELECT b.*,
  CASE WHEN b.scenario_type='BASELINE' OR NOT b.shock_active THEN b.available_balance ELSE (b.scenario_closing-b.scenario_hold)::numeric(18,2) END AS scenario_available,
  CASE WHEN b.scenario_type='BASELINE' OR NOT b.shock_active THEN b.minimum_balance ELSE least(b.scenario_opening,b.scenario_closing,b.scenario_closing-b.scenario_hold)::numeric(18,2) END AS scenario_minimum
 FROM balanced b
), nsf AS (
 SELECT a.*,
  CASE WHEN a.scenario_type='BASELINE' OR NOT a.shock_active THEN a.baseline_adjusted_nsf_probability
       WHEN a.scenario_processor_status='NOT_YET_ACTIVE' THEN 0.00::numeric
       ELSE least(0.35,a.nsf_daily_probability*
         CASE WHEN a.scenario_available<0 THEN 1.75 WHEN a.scenario_available<a.target_buffer_amount*0.25 THEN 1.25 ELSE 0.35 END*
         CASE WHEN a.shock_active THEN a.obligation_multiplier ELSE 1 END)::numeric END AS scenario_nsf_probability
 FROM available a
), final_rows AS (
 SELECT n.*,
  CASE WHEN n.scenario_type='BASELINE' OR NOT n.shock_active THEN n.nsf_count
       WHEN n.scenario_processor_status='NOT_YET_ACTIVE' THEN 0::smallint
       ELSE greatest(n.nsf_count,(CASE WHEN n.u_nsf<n.scenario_nsf_probability THEN 1+CASE WHEN n.u_nsf_count<0.05 THEN 1 ELSE 0 END ELSE 0 END)::smallint) END AS scenario_nsf_count,
  CASE WHEN n.scenario_type='BASELINE' OR NOT n.shock_active THEN n.negative_balance_flag
       WHEN n.scenario_processor_status='NOT_YET_ACTIVE' THEN false ELSE (n.negative_balance_flag OR n.scenario_minimum<0) END AS scenario_negative_flag,
  CASE WHEN n.scenario_processor_status='NOT_YET_ACTIVE' THEN 'PRE_OPEN'
       WHEN n.support_deposit_increment>0 THEN 'NON_POS_SUPPORT_DEPOSIT'
       WHEN n.scenario_processor_status='OUTAGE' THEN 'PROCESSOR_OUTAGE'
       WHEN n.scenario_available<n.target_buffer_amount*0.25 THEN 'LOW_LIQUIDITY'
       WHEN n.shock_active THEN 'SCENARIO_STRESS' ELSE 'NORMAL' END AS scenario_liquidity_event,
  jsonb_build_object(
   'scenario_code',n.scenario_code,'scenario_version',n.scenario_version,'scenario_type',n.scenario_type,
   'overlay_applied',(n.scenario_type='STRESS' AND n.shock_active),'shock_start_date',n.shock_start_date,'shock_active_flag',n.shock_active,
   'deposit_capture_multiplier',n.deposit_capture_multiplier,'obligation_multiplier',n.obligation_multiplier,
   'liquidity_shock_multiplier',n.liquidity_shock_multiplier,'scenario_pos_row_hash',n.scenario_pos_row_hash,
   'base_pos_deposit_amount',round(n.scenario_pos_deposit,2),'support_deposit_amount',round(n.support_deposit_increment,2),
   'temporary_hold_amount',round(n.scenario_hold,2),'adjusted_nsf_probability',round(n.scenario_nsf_probability,8),
   'liquidity_event_code',CASE WHEN n.scenario_processor_status='NOT_YET_ACTIVE' THEN 'PRE_OPEN'
       WHEN n.support_deposit_increment>0 THEN 'NON_POS_SUPPORT_DEPOSIT'
       WHEN n.scenario_processor_status='OUTAGE' THEN 'PROCESSOR_OUTAGE'
       WHEN n.scenario_available<n.target_buffer_amount*0.25 THEN 'LOW_LIQUIDITY'
       WHEN n.shock_active THEN 'SCENARIO_STRESS' ELSE 'NORMAL' END
  ) AS payload
 FROM nsf n
)
SELECT f.scenario_id,f.row_hash AS base_row_hash,f.payload,f.population_id,f.merchant_id,f.observation_date,
       f.scenario_opening::numeric(18,2),f.final_deposit::numeric(18,2),f.final_withdrawal::numeric(18,2),
       f.scenario_closing::numeric(18,2),f.scenario_available::numeric(18,2),f.scenario_minimum::numeric(18,2),
       f.scenario_nsf_count,f.scenario_negative_flag,f.source_contract_id,f.generated_by_run_id,
       msbf_m1.m1_6_deposit_scenario_row_hash(f.scenario_id,f.row_hash,f.payload,f.population_id,f.merchant_id,f.observation_date,
         f.scenario_opening,f.final_deposit,f.final_withdrawal,f.scenario_closing,f.scenario_available,f.scenario_minimum,
         f.scenario_nsf_count,f.scenario_negative_flag,f.source_contract_id,f.generated_by_run_id) AS scenario_row_hash,
       f.scenario_code,f.scenario_type,f.industry_code,f.liquidity_risk_tier,f.shock_active,
       f.scenario_pos_deposit::numeric(18,2),f.support_deposit_increment::numeric(18,2),f.scenario_hold::numeric(18,2),
       f.scenario_nsf_probability::numeric(12,8),f.scenario_liquidity_event,f.deposit_amount,f.withdrawal_amount
FROM final_rows f
ORDER BY f.scenario_id,f.merchant_id,f.observation_date;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_6_expected_scenario_snapshot(p_run_id bigint)
RETURNS TABLE(entity_type text,entity_key text,row_hash text) LANGUAGE sql STABLE AS $fn$
SELECT 'POS_SCENARIO',scenario_code||'|'||merchant_id||'|'||observation_date::text,row_hash
FROM msbf_m1.m1_6_pos_scenario_blueprint(p_run_id)
UNION ALL
SELECT 'DEPOSIT_SCENARIO',scenario_code||'|'||merchant_id||'|'||observation_date::text,row_hash
FROM msbf_m1.m1_6_deposit_scenario_blueprint(p_run_id)
ORDER BY 1,2;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_6_actual_scenario_snapshot(p_run_id bigint)
RETURNS TABLE(entity_type text,entity_key text,row_hash text) LANGUAGE sql STABLE AS $fn$
SELECT 'POS_SCENARIO',sr.scenario_code||'|'||p.merchant_id||'|'||p.observation_date::text,
 msbf_m1.m1_6_pos_scenario_row_hash(p.scenario_id,p.base_row_hash,p.direct_shock_factor,p.propagated_shock_factor,
  p.scenario_overlay_payload,p.population_id,p.merchant_id,p.processor_account_id,p.observation_date,p.gross_pos_sales,
  p.transaction_count,p.average_ticket_amount,p.refund_amount,p.chargeback_amount,p.reversal_amount,p.governed_exclusion_amount,
  p.eligible_pos_sales,p.processor_fee_amount,p.settlement_amount,p.net_merchant_proceeds,p.zero_sales_day_flag,
  p.processor_status,p.data_connection_status,p.source_contract_id,p.generated_by_run_id)
FROM msbf_m1.merchant_pos_daily_scenario p JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=p.scenario_id
WHERE p.generated_by_run_id=p_run_id
UNION ALL
SELECT 'DEPOSIT_SCENARIO',sr.scenario_code||'|'||d.merchant_id||'|'||d.observation_date::text,
 msbf_m1.m1_6_deposit_scenario_row_hash(d.scenario_id,d.base_row_hash,d.scenario_overlay_payload,d.population_id,d.merchant_id,
  d.observation_date,d.opening_balance,d.deposit_amount,d.withdrawal_amount,d.closing_balance,d.available_balance,
  d.minimum_balance,d.nsf_count,d.negative_balance_flag,d.source_contract_id,d.generated_by_run_id)
FROM msbf_m1.merchant_deposit_daily_scenario d JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=d.scenario_id
WHERE d.generated_by_run_id=p_run_id
ORDER BY 1,2;
$fn$;

DO $do$
DECLARE v_run_id bigint;
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 PERFORM msbf_m1.m1_6_assert_generation_ready(v_run_id);
END $do$;

CREATE TEMP TABLE _m1_6_pos_blueprint ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_6_pos_scenario_blueprint(
 (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE INDEX ON _m1_6_pos_blueprint(scenario_id,merchant_id,observation_date);

DO $do$
DECLARE v_rows bigint;
BEGIN
 SELECT COUNT(*) INTO v_rows FROM _m1_6_pos_blueprint;
 IF v_rows<>270000 THEN RAISE EXCEPTION 'M1.6 POS blueprint expected 270000 rows; observed %.',v_rows; END IF;
END $do$;

INSERT INTO msbf_m1.merchant_pos_daily_scenario(
 scenario_id,base_row_hash,direct_shock_factor,propagated_shock_factor,scenario_overlay_payload,
 population_id,merchant_id,processor_account_id,observation_date,gross_pos_sales,transaction_count,average_ticket_amount,
 refund_amount,chargeback_amount,reversal_amount,governed_exclusion_amount,eligible_pos_sales,processor_fee_amount,
 settlement_amount,net_merchant_proceeds,zero_sales_day_flag,processor_status,data_connection_status,source_contract_id,
 generated_by_run_id,row_hash)
SELECT scenario_id,base_row_hash,direct_shock_factor,propagated_shock_factor,scenario_overlay_payload,
       population_id,merchant_id,processor_account_id,observation_date,gross_pos_sales,transaction_count,average_ticket_amount,
       refund_amount,chargeback_amount,reversal_amount,governed_exclusion_amount,eligible_pos_sales,processor_fee_amount,
       settlement_amount,net_merchant_proceeds,zero_sales_day_flag,processor_status,data_connection_status,source_contract_id,
       generated_by_run_id,row_hash
FROM _m1_6_pos_blueprint;

CREATE TEMP TABLE _m1_6_deposit_blueprint ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_6_deposit_scenario_blueprint(
 (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE INDEX ON _m1_6_deposit_blueprint(scenario_id,merchant_id,observation_date);

DO $do$
DECLARE v_rows bigint;
BEGIN
 SELECT COUNT(*) INTO v_rows FROM _m1_6_deposit_blueprint;
 IF v_rows<>270000 THEN RAISE EXCEPTION 'M1.6 deposit blueprint expected 270000 rows; observed %.',v_rows; END IF;
END $do$;

INSERT INTO msbf_m1.merchant_deposit_daily_scenario(
 scenario_id,base_row_hash,scenario_overlay_payload,population_id,merchant_id,observation_date,opening_balance,
 deposit_amount,withdrawal_amount,closing_balance,available_balance,minimum_balance,nsf_count,negative_balance_flag,
 source_contract_id,generated_by_run_id,row_hash)
SELECT scenario_id,base_row_hash,scenario_overlay_payload,population_id,merchant_id,observation_date,opening_balance,
       deposit_amount,withdrawal_amount,closing_balance,available_balance,minimum_balance,nsf_count,negative_balance_flag,
       source_contract_id,generated_by_run_id,row_hash
FROM _m1_6_deposit_blueprint;

DO $do$
DECLARE v_run_id bigint; v_expected bigint; v_actual bigint; v_mismatch bigint;
 v_pos_hash text; v_deposit_hash text; v_combined_hash text; v_spec jsonb; v_spec_hash text;
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;

 SELECT COUNT(*) INTO v_expected FROM msbf_m1.m1_6_expected_scenario_snapshot(v_run_id);
 SELECT COUNT(*) INTO v_actual FROM msbf_m1.m1_6_actual_scenario_snapshot(v_run_id);
 SELECT COUNT(*) INTO v_mismatch
 FROM msbf_m1.m1_6_expected_scenario_snapshot(v_run_id) e
 FULL JOIN msbf_m1.m1_6_actual_scenario_snapshot(v_run_id) a USING(entity_type,entity_key)
 WHERE e.row_hash IS DISTINCT FROM a.row_hash;
 IF v_expected<>540000 OR v_actual<>540000 OR v_mismatch<>0 THEN
  RAISE EXCEPTION 'M1.6 persisted scenarios do not match deterministic blueprints: expected %, actual %, mismatches %.',v_expected,v_actual,v_mismatch;
 END IF;

 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) INTO v_pos_hash
 FROM msbf_m1.m1_6_actual_scenario_snapshot(v_run_id) WHERE entity_type='POS_SCENARIO';
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) INTO v_deposit_hash
 FROM msbf_m1.m1_6_actual_scenario_snapshot(v_run_id) WHERE entity_type='DEPOSIT_SCENARIO';
 SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) INTO v_combined_hash
 FROM msbf_m1.m1_6_actual_scenario_snapshot(v_run_id);

 SELECT jsonb_build_object(
  'stage','M1.6','revision','v0.2','scenario_set_code','M1_V0_2_BASELINE_AND_STRESS',
  'scenarios',(SELECT jsonb_agg(to_jsonb(x) ORDER BY x.scenario_code) FROM msbf_m1.m1_6_scenario_profile(v_run_id) x),
  'industry_shock_matrix',(SELECT jsonb_agg(to_jsonb(x) ORDER BY x.industry_code) FROM msbf_m1.m1_6_industry_shock_matrix() x),
  'stress_window_days',60,'direct_shock_start','history_end_date_minus_59_days','propagation_lag_source','scenario_lag_days',
  'baseline_copy_required',true,'matched_population_required',true,'deterministic_seed_family','M1_6',
  'interpretation_boundary','Controlled synthetic sensitivity; not an economic forecast or calibrated stress model.'
 ) INTO v_spec;
 v_spec_hash:=md5(v_spec::text);

 INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
 VALUES
 (v_run_id,'M1_6_SCENARIO_SPEC','PORTFOLIO','M1.6 scenario specification',v_spec::text,'JSON','PASS','Code-owned scenario assumptions and industry-network overlay matrix.'),
 (v_run_id,'M1_6_SCENARIO_SPEC_HASH','PORTFOLIO','M1.6 scenario specification hash',v_spec_hash,'HASH','PASS','MD5 of canonical JSONB scenario specification.'),
 (v_run_id,'M1_6_POS_SCENARIO_SET_HASH','PORTFOLIO','M1.6 POS scenario set hash',v_pos_hash,'HASH','PASS','Canonical hash across BASELINE and RECESSION_ENERGY POS scenario rows.'),
 (v_run_id,'M1_6_DEPOSIT_SCENARIO_SET_HASH','PORTFOLIO','M1.6 deposit scenario set hash',v_deposit_hash,'HASH','PASS','Canonical hash across BASELINE and RECESSION_ENERGY deposit scenario rows.'),
 (v_run_id,'M1_6_COMBINED_SET_HASH','PORTFOLIO','M1.6 combined scenario set hash',v_combined_hash,'HASH','PASS','Canonical hash across all POS and deposit scenario rows.'),
 (v_run_id,'M1_6_GENERATION_SUMMARY','PORTFOLIO','M1.6 generation summary',
  jsonb_build_object('scenarios',2,'pos_rows',270000,'deposit_rows',270000,'canonical_entities',540000,
    'merchants',750,'dates',180,'stress_window_rows_per_entity',45000,'propagated_window_rows_per_entity',39750,
    'row_mismatches',0,'pos_hash',v_pos_hash,'deposit_hash',v_deposit_hash,'combined_hash',v_combined_hash)::text,
  'JSON','PASS','Matched baseline and stress histories generated without modifying accepted baseline rows.')
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
  metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
  threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

 UPDATE msbf_ctl.run_registry SET run_status='M1_6_GENERATED',completed_at=NULL,
  notes=COALESCE(notes,'')||E'\nM1.6 matched BASELINE and RECESSION_ENERGY POS/deposit scenario overlays generated.'
 WHERE run_id=v_run_id;
END $do$;

COMMIT;

WITH r AS (
 SELECT run_id,run_status,population_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), scenario_counts AS (
 SELECT sr.scenario_code,
  (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario p WHERE p.generated_by_run_id=(SELECT run_id FROM r) AND p.scenario_id=sr.scenario_id) AS pos_rows,
  (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario d WHERE d.generated_by_run_id=(SELECT run_id FROM r) AND d.scenario_id=sr.scenario_id) AS deposit_rows
 FROM msbf_ctl.scenario_registry sr JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
 WHERE ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS' AND sr.status='APPROVED'
   AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY')
), hashes AS (
 SELECT
  (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_6_POS_SCENARIO_SET_HASH' AND segment_key='PORTFOLIO') AS pos_hash,
  (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_6_DEPOSIT_SCENARIO_SET_HASH' AND segment_key='PORTFOLIO') AS deposit_hash,
  (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_6_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS combined_hash
)
SELECT r.run_id,r.run_status,r.population_id,
       SUM(scenario_counts.pos_rows) AS pos_scenario_rows,SUM(scenario_counts.deposit_rows) AS deposit_scenario_rows,
       jsonb_object_agg(scenario_counts.scenario_code,jsonb_build_object('pos_rows',scenario_counts.pos_rows,'deposit_rows',scenario_counts.deposit_rows)) AS scenario_counts,
       hashes.pos_hash,hashes.deposit_hash,hashes.combined_hash,
       CASE WHEN r.run_status='M1_6_GENERATED' AND SUM(scenario_counts.pos_rows)=270000 AND SUM(scenario_counts.deposit_rows)=270000
                  AND bool_and(scenario_counts.pos_rows=135000 AND scenario_counts.deposit_rows=135000)
                  AND hashes.pos_hash IS NOT NULL AND hashes.deposit_hash IS NOT NULL AND hashes.combined_hash IS NOT NULL
            THEN 'PASS' ELSE 'FAIL' END AS generation_status
FROM r CROSS JOIN hashes CROSS JOIN scenario_counts
GROUP BY r.run_id,r.run_status,r.population_id,hashes.pos_hash,hashes.deposit_hash,hashes.combined_hash;
