/* ============================================================================
MSBF M1.3 Application and Requested Sales-Linked Structure Generation
Version : v0.2
Purpose : Create one deterministic baseline application and requested sales-
          linked financing structure for each accepted M1.2 merchant.
============================================================================ */
BEGIN;

INSERT INTO msbf_ref.acceptance_gate_catalog(gate_id,gate_name,module_code,severity,description)
VALUES('M1_3_APPLICATION_REQUEST','M1.3 Application and Requested Sales-Linked Structure','M1','BLOCKING',
       'One deterministic application and internally coherent requested sales-linked financing structure per accepted merchant.')
ON CONFLICT (gate_id) DO NOTHING;

CREATE OR REPLACE FUNCTION msbf_m1.m1_3_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
 v_run_status text; v_population_status text; v_population_id text;
 v_parameter_hash text; v_profile_hash text; v_source_hash text; v_population_hash text;
 v_r_parameter text; v_r_profile text; v_r_source text; v_r_population text;
 v_g1 text; v_m12 text; v_population_rows bigint; v_application_rows bigint; v_downstream_rows bigint;
 v_required integer; v_resolved integer;
BEGIN
 SELECT r.run_status,p.population_status,r.population_id,r.parameter_snapshot_hash,r.profile_snapshot_hash,
        r.source_snapshot_hash,p.population_hash
 INTO STRICT v_run_status,v_population_status,v_population_id,v_parameter_hash,v_profile_hash,v_source_hash,v_population_hash
 FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_id=p_run_id;

 SELECT result_status INTO v_g1 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=p_run_id AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1;
 SELECT result_status INTO v_m12 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=p_run_id AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1;

 SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key))
 INTO v_r_parameter FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id;
 SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code))
 INTO v_r_profile FROM msbf_ctl.run_profile_snapshot WHERE run_id=p_run_id;
 SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code))
 INTO v_r_source FROM msbf_ctl.run_source_snapshot WHERE run_id=p_run_id;
 SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key))
 INTO v_r_population FROM msbf_m1.m1_2_actual_entity_snapshot(p_run_id);

 SELECT
  (SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE population_id=v_population_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_industry_assignment WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.partner_channel WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.processor_account WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=p_run_id)
 INTO v_population_rows;

 SELECT COUNT(*) INTO v_application_rows FROM msbf_m1.merchant_application WHERE created_by_run_id=p_run_id;
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=p_run_id)
 INTO v_downstream_rows;

 WITH req(parameter_name,scope_key) AS (VALUES
  ('application_count_per_merchant','GLOBAL'),('funding_amount_min','GLOBAL'),('funding_amount_max','GLOBAL'),
  ('funding_to_annualized_sales_max','GLOBAL'),('payback_multiple_min','GLOBAL'),('payback_multiple_max','GLOBAL'),
  ('requested_remittance_rate_min','GLOBAL'),('requested_remittance_rate_max','GLOBAL'),('qa_reconciliation_tolerance_amount','GLOBAL'),
  ('funding_to_annualized_sales_center','MERCHANT_SIZE_TIER:MICRO'),('funding_to_annualized_sales_center','MERCHANT_SIZE_TIER:SMALL'),
  ('funding_to_annualized_sales_center','MERCHANT_SIZE_TIER:LOWER_MIDDLE'),('funding_to_annualized_sales_center','MERCHANT_SIZE_TIER:MIDDLE'),
  ('payback_multiple_center','RISK_TIER:1'),('payback_multiple_center','RISK_TIER:2'),('payback_multiple_center','RISK_TIER:3'),
  ('payback_multiple_center','RISK_TIER:4'),('payback_multiple_center','RISK_TIER:5'),
  ('expected_payoff_day_weight','EXPECTED_PAYOFF_DAYS:30'),('expected_payoff_day_weight','EXPECTED_PAYOFF_DAYS:60'),
  ('expected_payoff_day_weight','EXPECTED_PAYOFF_DAYS:90'),
  ('requested_remittance_rate_center','EXPECTED_PAYOFF_DAYS:30'),('requested_remittance_rate_center','EXPECTED_PAYOFF_DAYS:60'),
  ('requested_remittance_rate_center','EXPECTED_PAYOFF_DAYS:90'),
  ('use_of_proceeds_mix_weight','USE_OF_PROCEEDS:WORKING_CAPITAL'),('use_of_proceeds_mix_weight','USE_OF_PROCEEDS:INVENTORY'),
  ('use_of_proceeds_mix_weight','USE_OF_PROCEEDS:EQUIPMENT_REPAIR'),('use_of_proceeds_mix_weight','USE_OF_PROCEEDS:SEASONAL_NEED'),
  ('use_of_proceeds_mix_weight','USE_OF_PROCEEDS:EXPANSION'),('use_of_proceeds_mix_weight','USE_OF_PROCEEDS:EMERGENCY_EXPENSE')
 )
 SELECT COUNT(*),COUNT(rps.parameter_name) INTO v_required,v_resolved
 FROM req LEFT JOIN msbf_ctl.run_parameter_snapshot rps
 ON rps.run_id=p_run_id AND rps.parameter_name=req.parameter_name AND rps.scope_key=req.scope_key;

 IF v_run_status<>'M1_2_ACCEPTED' THEN RAISE EXCEPTION 'M1.3 generation requires run_status=M1_2_ACCEPTED; observed %.',v_run_status; END IF;
 IF v_population_status<>'M1_2_ACCEPTED' THEN RAISE EXCEPTION 'M1.3 generation requires population_status=M1_2_ACCEPTED; observed %.',v_population_status; END IF;
 IF v_g1 IS DISTINCT FROM 'PASS' OR v_m12 IS DISTINCT FROM 'PASS' THEN RAISE EXCEPTION 'M1.3 generation requires accepted G1 and M1.2 gates.'; END IF;
 IF v_parameter_hash<>'bd09e598c82db96e47459d77fd11e7c8' OR v_profile_hash<>'462cbd2ed92f68e5bdecf6b17537a973'
    OR v_source_hash<>'93c3d1368fb2450ab4a08e2b721f92d3' OR v_population_hash<>'9b706c926260a3ef1ae8ac95eed5d0bf'
 THEN RAISE EXCEPTION 'Accepted G1 or M1.2 hashes do not match the approved M1.3 baseline.'; END IF;
 IF v_parameter_hash IS DISTINCT FROM v_r_parameter OR v_profile_hash IS DISTINCT FROM v_r_profile
    OR v_source_hash IS DISTINCT FROM v_r_source OR v_population_hash IS DISTINCT FROM v_r_population
 THEN RAISE EXCEPTION 'Accepted G1 or M1.2 content does not reconcile to stored hashes.'; END IF;
 IF v_population_rows<>4352 THEN RAISE EXCEPTION 'M1.3 requires the accepted 4,352-row M1.2 entity universe; observed %.',v_population_rows; END IF;
 IF v_required<>30 OR v_resolved<>30 THEN RAISE EXCEPTION 'M1.3 requires 30 resolved parameter/scope pairs; observed % of %.',v_resolved,v_required; END IF;
 IF v_application_rows<>0 THEN RAISE EXCEPTION 'M1.3 application rows already exist (% rows); regeneration is prohibited.',v_application_rows; END IF;
 IF v_downstream_rows<>0 THEN RAISE EXCEPTION 'Downstream analytical rows already exist (% rows); M1.3 generation is prohibited.',v_downstream_rows; END IF;
END $$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_3_weighted_assignment(
 p_run_id bigint,p_parameter_name text,p_scope_prefix text,p_seed_label text)
RETURNS TABLE(merchant_id text,category_code text,target_count integer)
LANGUAGE plpgsql STABLE AS $$
DECLARE v_population_id text; v_seed text; v_count integer; v_n integer; v_sum numeric;
BEGIN
 SELECT r.population_id,p.deterministic_seed_version,p.merchant_count INTO STRICT v_population_id,v_seed,v_count
 FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id WHERE r.run_id=p_run_id;
 SELECT COUNT(*),COALESCE(SUM((resolved_value->>'value_numeric')::numeric),0) INTO v_n,v_sum
 FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name=p_parameter_name AND scope_key LIKE p_scope_prefix||':%';
 IF v_n=0 THEN RAISE EXCEPTION 'M1.3 weighted assignment found no scoped values for parameter % and prefix %.',p_parameter_name,p_scope_prefix; END IF;
 IF abs(v_sum-1)>0.000000001 THEN RAISE EXCEPTION 'M1.3 weighted assignment requires weights summing to one; parameter % sums to %.',p_parameter_name,v_sum; END IF;
 RETURN QUERY
 WITH w AS (
  SELECT split_part(scope_key,':',2) cat_code,(resolved_value->>'value_numeric')::numeric weight,
   CASE WHEN p_parameter_name='expected_payoff_day_weight' THEN lpad(split_part(scope_key,':',2),3,'0')
        WHEN p_parameter_name='use_of_proceeds_mix_weight' THEN CASE split_part(scope_key,':',2)
          WHEN 'WORKING_CAPITAL' THEN '01' WHEN 'INVENTORY' THEN '02' WHEN 'EQUIPMENT_REPAIR' THEN '03'
          WHEN 'SEASONAL_NEED' THEN '04' WHEN 'EXPANSION' THEN '05' WHEN 'EMERGENCY_EXPENSE' THEN '06' ELSE '99' END
        ELSE split_part(scope_key,':',2) END tie_order
  FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name=p_parameter_name AND scope_key LIKE p_scope_prefix||':%'
 ), b AS (
  SELECT *,floor(weight*v_count)::integer base_count,(weight*v_count)-floor(weight*v_count) remainder FROM w
 ), rq AS (
  SELECT *,row_number() OVER(ORDER BY remainder DESC,tie_order,cat_code) remainder_rank,
         v_count-sum(base_count) OVER() residual FROM b
 ), q AS (
  SELECT cat_code,tie_order,base_count+CASE WHEN remainder_rank<=residual THEN 1 ELSE 0 END category_target_count FROM rq
 ), ranges AS (
  SELECT cat_code,category_target_count,
   1+COALESCE(sum(category_target_count) OVER(ORDER BY tie_order,cat_code ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0) start_rank,
   sum(category_target_count) OVER(ORDER BY tie_order,cat_code) end_rank FROM q
 ), m AS (
  SELECT mm.merchant_id,row_number() OVER(ORDER BY msbf_ctl.deterministic_uniform(mm.merchant_id,v_seed||':M1_3:'||p_seed_label),mm.merchant_id) assignment_rank
  FROM msbf_m1.merchant_master mm WHERE mm.population_id=v_population_id
 )
 SELECT m.merchant_id,r.cat_code,r.category_target_count::integer FROM m JOIN ranges r ON m.assignment_rank BETWEEN r.start_rank AND r.end_rank ORDER BY m.merchant_id;
END $$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_3_weighted_assignment_json(p_run_id bigint,p_weights jsonb,p_seed_label text)
RETURNS TABLE(merchant_id text,category_code text,target_count integer)
LANGUAGE plpgsql STABLE AS $$
DECLARE v_population_id text; v_seed text; v_count integer; v_n integer; v_sum numeric;
BEGIN
 SELECT r.population_id,p.deterministic_seed_version,p.merchant_count INTO STRICT v_population_id,v_seed,v_count
 FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id WHERE r.run_id=p_run_id;
 SELECT COUNT(*),COALESCE(SUM(value::numeric),0) INTO v_n,v_sum FROM jsonb_each_text(p_weights);
 IF v_n=0 THEN RAISE EXCEPTION 'M1.3 JSON weighted assignment requires at least one category.'; END IF;
 IF abs(v_sum-1)>0.000000001 THEN RAISE EXCEPTION 'M1.3 JSON weighted assignment requires weights summing to one; observed %.',v_sum; END IF;
 RETURN QUERY
 WITH w AS (SELECT key cat_code,value::numeric weight FROM jsonb_each_text(p_weights)),
 b AS (SELECT *,floor(weight*v_count)::integer base_count,(weight*v_count)-floor(weight*v_count) remainder FROM w),
 rq AS (SELECT *,row_number() OVER(ORDER BY remainder DESC,cat_code) remainder_rank,v_count-sum(base_count) OVER() residual FROM b),
 q AS (SELECT cat_code,base_count+CASE WHEN remainder_rank<=residual THEN 1 ELSE 0 END category_target_count FROM rq),
 ranges AS (SELECT cat_code,category_target_count,1+COALESCE(sum(category_target_count) OVER(ORDER BY cat_code ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0) start_rank,sum(category_target_count) OVER(ORDER BY cat_code) end_rank FROM q),
 m AS (SELECT mm.merchant_id,row_number() OVER(ORDER BY msbf_ctl.deterministic_uniform(mm.merchant_id,v_seed||':M1_3:'||p_seed_label),mm.merchant_id) assignment_rank FROM msbf_m1.merchant_master mm WHERE mm.population_id=v_population_id)
 SELECT m.merchant_id,r.cat_code,r.category_target_count::integer FROM m JOIN ranges r ON m.assignment_rank BETWEEN r.start_rank AND r.end_rank ORDER BY m.merchant_id;
END $$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_3_application_blueprint(p_run_id bigint)
RETURNS TABLE(
 merchant_application_id text,population_id text,merchant_id text,processor_account_id text,partner_channel_id text,
 application_date date,as_of_date date,requested_funding_amount numeric(18,2),requested_remittance_rate numeric(9,6),
 requested_expected_payoff_days smallint,requested_total_repayment_amount numeric(18,2),requested_finance_charge_amount numeric(18,2),
 requested_use_of_proceeds text,application_channel text,application_status text,request_hash text,created_by_run_id bigint,
 merchant_size_tier text,relationship_stage text,owner_credit_score smallint,prior_default_flag boolean,
 prior_payment_interruption_flag boolean,months_in_business integer,annual_sales_proxy numeric(18,2),
 request_reference_tier smallint,requested_payback_multiple numeric(9,6),expected_daily_sales_proxy numeric(18,2),
 expected_daily_remittance numeric(18,2),implied_payoff_days numeric(18,6),funding_to_annualized_sales_rate numeric(9,6),
 sales_linked_reference_amount numeric(18,2),request_path_utilization_factor numeric(9,6),repayment_path_ratio numeric(9,6),
 minimum_amount_floor_override_flag boolean,binding_constraint_code text)
LANGUAGE sql STABLE AS $$
WITH ctx AS (
 SELECT r.run_id,r.population_id,r.as_of_date,p.deterministic_seed_version,
  (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name='funding_amount_min' AND scope_key='GLOBAL') funding_min,
  (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name='funding_amount_max' AND scope_key='GLOBAL') funding_max,
  (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name='funding_to_annualized_sales_max' AND scope_key='GLOBAL') funding_ratio_max,
  (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name='payback_multiple_min' AND scope_key='GLOBAL') payback_min,
  (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name='payback_multiple_max' AND scope_key='GLOBAL') payback_max,
  (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name='requested_remittance_rate_min' AND scope_key='GLOBAL') remittance_min,
  (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name='requested_remittance_rate_max' AND scope_key='GLOBAL') remittance_max
 FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id WHERE r.run_id=p_run_id
), horizon_a AS (
 SELECT * FROM msbf_m1.m1_3_weighted_assignment(p_run_id,'expected_payoff_day_weight','EXPECTED_PAYOFF_DAYS','HORIZON')
), use_a AS (
 SELECT * FROM msbf_m1.m1_3_weighted_assignment(p_run_id,'use_of_proceeds_mix_weight','USE_OF_PROCEEDS','USE_OF_PROCEEDS')
), primary_owner AS (
 SELECT * FROM msbf_m1.merchant_owner_guarantor WHERE created_by_run_id=p_run_id AND party_role='PRIMARY_OWNER_GUARANTOR'
), base AS (
 SELECT m.*,ctx.run_id,ctx.as_of_date,ctx.deterministic_seed_version,ctx.funding_min,ctx.funding_max,ctx.funding_ratio_max,
        ctx.payback_min,ctx.payback_max,ctx.remittance_min,ctx.remittance_max,
        i.industry_code,s.relationship_stage,s.prior_default_flag,s.prior_payment_interruption_flag,s.relationship_quality_tier,
        o.owner_credit_score,o.major_derogatory_flag,o.bankruptcy_flag,
        p.processor_account_id,p.partner_channel_id,p.processor_risk_tier,
        h.category_code::smallint payoff_days,u.category_code use_of_proceeds,
        ((extract(year from age(ctx.as_of_date,m.incorporation_date))*12)+extract(month from age(ctx.as_of_date,m.incorporation_date)))::integer months_in_business,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_3:ANNUAL_SALES_PROXY') u_sales,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_3:REMITTANCE') u_remittance,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_3:PAYBACK') u_payback,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_3:REQUEST_APPETITE') u_appetite
 FROM msbf_m1.merchant_master m CROSS JOIN ctx
 JOIN msbf_m1.merchant_industry_assignment i ON i.merchant_id=m.merchant_id AND i.assignment_type='PRIMARY' AND i.created_by_run_id=p_run_id
 JOIN msbf_m1.merchant_relationship_snapshot s ON s.merchant_id=m.merchant_id AND s.as_of_date=ctx.as_of_date AND s.created_by_run_id=p_run_id
 JOIN primary_owner o ON o.merchant_id=m.merchant_id
 JOIN msbf_m1.processor_account p ON p.merchant_id=m.merchant_id AND p.created_by_run_id=p_run_id
 JOIN horizon_a h ON h.merchant_id=m.merchant_id JOIN use_a u ON u.merchant_id=m.merchant_id
 WHERE m.population_id=ctx.population_id
), tiered AS (
 SELECT b.*,
  CASE WHEN b.prior_default_flag OR b.bankruptcy_flag OR b.owner_credit_score<560 THEN 5
       WHEN b.major_derogatory_flag OR b.owner_credit_score<620 OR b.relationship_quality_tier>=4 OR b.prior_payment_interruption_flag THEN 4
       WHEN b.owner_credit_score<680 OR b.relationship_quality_tier=3 OR b.processor_risk_tier>=3 THEN 3
       WHEN b.owner_credit_score<740 OR b.relationship_quality_tier=2 OR b.processor_risk_tier=2 THEN 2 ELSE 1 END::smallint request_reference_tier,
  CASE b.annual_sales_band
   WHEN 'UNDER_250K' THEN round((150000.0*power(250000.0/150000.0,b.u_sales))::numeric,2)
   WHEN '250K_TO_1M' THEN round((300000.0*power(1000000.0/300000.0,b.u_sales))::numeric,2)
   WHEN '1M_TO_5M' THEN round((1200000.0*power(5000000.0/1200000.0,b.u_sales))::numeric,2)
   ELSE round((5500000.0*power(20000000.0/5500000.0,b.u_sales))::numeric,2) END::numeric(18,2) annual_sales_proxy
 FROM base b
), centers AS (
 SELECT t.*,
  (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name='funding_to_annualized_sales_center' AND scope_key='MERCHANT_SIZE_TIER:'||t.merchant_size_tier) funding_center,
  (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name='payback_multiple_center' AND scope_key='RISK_TIER:'||t.request_reference_tier::text) payback_center,
  (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id AND parameter_name='requested_remittance_rate_center' AND scope_key='EXPECTED_PAYOFF_DAYS:'||t.payoff_days::text) remittance_center
 FROM tiered t
), rates AS (
 SELECT c.*,
  round(least(c.remittance_max,greatest(c.remittance_min,c.remittance_center
   +CASE c.merchant_size_tier WHEN 'MICRO' THEN 0.005 WHEN 'SMALL' THEN 0 WHEN 'LOWER_MIDDLE' THEN -0.003 ELSE -0.005 END
   +CASE c.relationship_stage WHEN 'RETURNING_GOOD' THEN -0.005 WHEN 'RETURNING_MIXED' THEN 0.005 WHEN 'LOW_AND_GROW' THEN 0.008 ELSE 0.003 END
   +CASE c.partner_channel_id WHEN 'CH_BANK_RELATIONSHIP' THEN -0.003 WHEN 'CH_BROKER_NETWORK' THEN 0.005 ELSE 0 END
   +(c.u_remittance-0.5)*0.016)),6)::numeric(9,6) remittance_rate,
  round(least(c.payback_max,greatest(c.payback_min,c.payback_center
   +CASE c.payoff_days WHEN 30 THEN -0.010 WHEN 90 THEN 0.015 ELSE 0 END
   +CASE c.partner_channel_id WHEN 'CH_BANK_RELATIONSHIP' THEN -0.005 WHEN 'CH_BROKER_NETWORK' THEN 0.010 ELSE 0 END
   +CASE c.relationship_stage WHEN 'RETURNING_GOOD' THEN -0.010 WHEN 'RETURNING_MIXED' THEN 0.010 WHEN 'LOW_AND_GROW' THEN 0.008 ELSE 0 END
   +CASE WHEN c.prior_default_flag THEN 0.020 ELSE 0 END +(c.u_payback-0.5)*0.020)),6)::numeric(9,6) payback_multiple,
  round(least(1.350000,greatest(0.650000,
   CASE c.relationship_stage WHEN 'RETURNING_GOOD' THEN 0.900 WHEN 'RETURNING_MIXED' THEN 1.180 WHEN 'LOW_AND_GROW' THEN 0.780 ELSE 1.050 END
   *CASE WHEN c.owner_credit_score>=760 THEN 0.950 WHEN c.owner_credit_score>=700 THEN 0.980 WHEN c.owner_credit_score>=640 THEN 1.000 WHEN c.owner_credit_score>=580 THEN 1.080 ELSE 1.150 END
   *CASE c.use_of_proceeds WHEN 'EMERGENCY_EXPENSE' THEN 1.180 WHEN 'EXPANSION' THEN 1.100 WHEN 'SEASONAL_NEED' THEN 1.080 WHEN 'EQUIPMENT_REPAIR' THEN 1.020 WHEN 'INVENTORY' THEN 1.000 ELSE 0.950 END
   *(0.920+0.160*c.u_appetite))),6)::numeric(9,6) request_path_utilization_factor
 FROM centers c
), candidates AS (
 SELECT r.*,round(r.annual_sales_proxy/365.0,2)::numeric(18,2) daily_sales_proxy,
  (r.annual_sales_proxy*r.funding_center
   *CASE r.relationship_stage WHEN 'RETURNING_GOOD' THEN 1.10 WHEN 'RETURNING_MIXED' THEN 0.82 WHEN 'LOW_AND_GROW' THEN 0.68 ELSE 0.95 END
   *CASE WHEN r.owner_credit_score>=760 THEN 1.08 WHEN r.owner_credit_score>=700 THEN 1.03 WHEN r.owner_credit_score>=640 THEN 1.00 WHEN r.owner_credit_score>=580 THEN 0.90 ELSE 0.80 END
   *(0.85+0.30*r.u_appetite))::numeric request_appetite_amount,
  ((r.annual_sales_proxy/365.0)*r.remittance_rate*r.payoff_days/r.payback_multiple)::numeric sales_linked_reference_amount,
  ((r.annual_sales_proxy/365.0)*r.remittance_rate*r.payoff_days/r.payback_multiple*r.request_path_utilization_factor)::numeric sales_linked_request_amount,
  (r.annual_sales_proxy*r.funding_ratio_max)::numeric sales_ratio_cap_amount
 FROM rates r
), bounded AS (
 SELECT a.*,least(a.request_appetite_amount,a.sales_linked_request_amount,a.sales_ratio_cap_amount,a.funding_max) binding_amount,
  CASE WHEN least(a.request_appetite_amount,a.sales_linked_request_amount,a.sales_ratio_cap_amount,a.funding_max)<a.funding_min THEN 'MINIMUM_PRODUCT_AMOUNT_FLOOR'
       WHEN least(a.request_appetite_amount,a.sales_linked_request_amount,a.sales_ratio_cap_amount,a.funding_max)=a.sales_linked_request_amount THEN 'SALES_LINKED_REQUEST_REFERENCE'
       WHEN least(a.request_appetite_amount,a.sales_linked_request_amount,a.sales_ratio_cap_amount,a.funding_max)=a.request_appetite_amount THEN 'MERCHANT_REQUEST_APPETITE'
       WHEN least(a.request_appetite_amount,a.sales_linked_request_amount,a.sales_ratio_cap_amount,a.funding_max)=a.sales_ratio_cap_amount THEN 'FUNDING_TO_SALES_CAP'
       ELSE 'GLOBAL_FUNDING_MAX' END binding_constraint_code
 FROM candidates a
), amounts AS (
 SELECT b.*,greatest(b.funding_min,floor(b.binding_amount/100.0)*100.0)::numeric(18,2) funding_amount FROM bounded b
), repayment AS (
 SELECT a.*,round((a.funding_amount*a.payback_multiple)::numeric,2)::numeric(18,2) total_repayment_amount FROM amounts a
), final AS (
 SELECT r.*,(r.total_repayment_amount-r.funding_amount)::numeric(18,2) finance_charge_amount,
  round(r.total_repayment_amount/r.payoff_days,2)::numeric(18,2) expected_daily_remittance,
  round(r.total_repayment_amount/NULLIF((r.annual_sales_proxy/365.0)*r.remittance_rate,0),6)::numeric(18,6) implied_payoff_days,
  round(r.funding_amount/r.annual_sales_proxy,6)::numeric(9,6) funding_to_sales_rate,
  round(r.total_repayment_amount/NULLIF((r.annual_sales_proxy/365.0)*r.remittance_rate*r.payoff_days,0),6)::numeric(9,6) repayment_path_ratio,
  (r.binding_amount<r.funding_min) AS minimum_amount_floor_override_flag,
  CASE r.partner_channel_id WHEN 'CH_PROCESSOR_DIRECT' THEN 'PROCESSOR_EMBEDDED' WHEN 'CH_BANK_RELATIONSHIP' THEN 'RELATIONSHIP_MANAGER'
       WHEN 'CH_DIGITAL_DIRECT' THEN 'DIGITAL_DIRECT' WHEN 'CH_STRATEGIC_PARTNER' THEN 'STRATEGIC_PARTNER' ELSE 'BROKER_REFERRAL' END application_channel,
  r.merchant_id||'_A01' merchant_application_id
 FROM repayment r
), hashed AS (
 SELECT f.*,md5(jsonb_build_object(
  'merchant_application_id',f.merchant_application_id,'population_id',f.population_id,'merchant_id',f.merchant_id,
  'processor_account_id',f.processor_account_id,'partner_channel_id',f.partner_channel_id,'application_date',f.as_of_date,'as_of_date',f.as_of_date,
  'requested_funding_amount',f.funding_amount::numeric(18,2),'requested_remittance_rate',f.remittance_rate::numeric(9,6),
  'requested_expected_payoff_days',f.payoff_days::smallint,'requested_total_repayment_amount',f.total_repayment_amount::numeric(18,2),
  'requested_finance_charge_amount',f.finance_charge_amount::numeric(18,2),'requested_use_of_proceeds',f.use_of_proceeds,
  'application_channel',f.application_channel,'application_status','SUBMITTED','created_by_run_id',f.run_id)::text) request_hash
 FROM final f
)
SELECT merchant_application_id,population_id,merchant_id,processor_account_id,partner_channel_id,as_of_date,as_of_date,
 funding_amount::numeric(18,2),remittance_rate::numeric(9,6),payoff_days::smallint,total_repayment_amount::numeric(18,2),
 finance_charge_amount::numeric(18,2),use_of_proceeds,application_channel,'SUBMITTED'::text,request_hash,run_id,
 merchant_size_tier,relationship_stage,owner_credit_score,prior_default_flag,prior_payment_interruption_flag,months_in_business,
 annual_sales_proxy::numeric(18,2),request_reference_tier::smallint,payback_multiple::numeric(9,6),daily_sales_proxy::numeric(18,2),
 expected_daily_remittance::numeric(18,2),implied_payoff_days::numeric(18,6),funding_to_sales_rate::numeric(9,6),
 sales_linked_reference_amount::numeric(18,2),request_path_utilization_factor::numeric(9,6),repayment_path_ratio::numeric(9,6),
 minimum_amount_floor_override_flag,binding_constraint_code
FROM hashed ORDER BY merchant_id;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_3_expected_application_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text)
LANGUAGE sql STABLE AS $$
SELECT merchant_application_id,request_hash FROM msbf_m1.m1_3_application_blueprint(p_run_id) ORDER BY merchant_application_id;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_3_actual_application_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text)
LANGUAGE sql STABLE AS $$
SELECT a.merchant_application_id,
 md5(jsonb_build_object(
  'merchant_application_id',a.merchant_application_id,'population_id',a.population_id,'merchant_id',a.merchant_id,
  'processor_account_id',a.processor_account_id,'partner_channel_id',a.partner_channel_id,
  'application_date',a.application_date,'as_of_date',a.as_of_date,
  'requested_funding_amount',a.requested_funding_amount::numeric(18,2),
  'requested_remittance_rate',a.requested_remittance_rate::numeric(9,6),
  'requested_expected_payoff_days',a.requested_expected_payoff_days::smallint,
  'requested_total_repayment_amount',a.requested_total_repayment_amount::numeric(18,2),
  'requested_finance_charge_amount',a.requested_finance_charge_amount::numeric(18,2),
  'requested_use_of_proceeds',a.requested_use_of_proceeds,'application_channel',a.application_channel,
  'application_status',a.application_status,'created_by_run_id',a.created_by_run_id)::text)
FROM msbf_m1.merchant_application a WHERE a.created_by_run_id=p_run_id ORDER BY a.merchant_application_id;
$$;

DO $$
DECLARE
 v_run_id bigint; v_spec jsonb; v_spec_hash text; v_expected bigint; v_actual bigint; v_mismatches bigint;
 v_expected_hash text; v_actual_hash text; v_examples text;
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 PERFORM msbf_m1.m1_3_assert_generation_ready(v_run_id);

 v_spec:=jsonb_build_object(
  'stage_code','M1.3','stage_version','v0.2','application_count_per_merchant',1,
  'application_date_rule','APPLICATION_DATE_EQUALS_AS_OF_DATE',
  'annual_sales_proxy_ranges',jsonb_build_object('UNDER_250K',jsonb_build_array(150000,250000),'250K_TO_1M',jsonb_build_array(300000,1000000),'1M_TO_5M',jsonb_build_array(1200000,5000000),'5M_TO_20M',jsonb_build_array(5500000,20000000)),
  'request_amount_rounding_increment',100,
  'request_amount_rule','MIN_APPETITE_SALES_LINKED_REQUEST_REFERENCE_SALES_RATIO_GLOBAL_MAX_WITH_PRODUCT_MINIMUM_FLOOR',
  'horizon_values',jsonb_build_array(30,60,90),
  'horizon_residual_tie_order',jsonb_build_array(30,60,90),
  'use_of_proceeds_residual_tie_order',jsonb_build_array('WORKING_CAPITAL','INVENTORY','EQUIPMENT_REPAIR','SEASONAL_NEED','EXPANSION','EMERGENCY_EXPENSE'),
  'request_path_factor_range',jsonb_build_array(0.65,1.35),
  'request_path_interpretation','VALUES_BELOW_ONE_REQUEST_BELOW_EXPECTED_SALES_PATH_VALUES_ABOVE_ONE_REQUEST_ABOVE_PATH',
  'request_hash_version','M1_3_REQUEST_HASH_V1',
  'production_boundary','SYNTHETIC_REQUEST_STRUCTURE_NOT_A_CREDIT_DECISION_OR_CUSTOMER_OFFER');
 v_spec_hash:=md5(v_spec::text);

 INSERT INTO msbf_m1.merchant_application(
  merchant_application_id,population_id,merchant_id,processor_account_id,partner_channel_id,application_date,as_of_date,
  requested_funding_amount,requested_remittance_rate,requested_expected_payoff_days,requested_total_repayment_amount,
  requested_finance_charge_amount,requested_use_of_proceeds,application_channel,application_status,request_hash,created_by_run_id)
 SELECT merchant_application_id,population_id,merchant_id,processor_account_id,partner_channel_id,application_date,as_of_date,
  requested_funding_amount,requested_remittance_rate,requested_expected_payoff_days,requested_total_repayment_amount,
  requested_finance_charge_amount,requested_use_of_proceeds,application_channel,application_status,request_hash,created_by_run_id
 FROM msbf_m1.m1_3_application_blueprint(v_run_id);

 SELECT COUNT(*) INTO v_expected FROM msbf_m1.m1_3_expected_application_snapshot(v_run_id);
 SELECT COUNT(*) INTO v_actual FROM msbf_m1.m1_3_actual_application_snapshot(v_run_id);
 SELECT COUNT(*) INTO v_mismatches FROM msbf_m1.m1_3_expected_application_snapshot(v_run_id) e
 FULL JOIN msbf_m1.m1_3_actual_application_snapshot(v_run_id) a USING(entity_key) WHERE e.row_hash IS DISTINCT FROM a.row_hash;
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) INTO v_expected_hash FROM msbf_m1.m1_3_expected_application_snapshot(v_run_id);
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) INTO v_actual_hash FROM msbf_m1.m1_3_actual_application_snapshot(v_run_id);

 IF v_expected<>750 OR v_actual<>750 OR v_mismatches<>0 OR v_expected_hash IS DISTINCT FROM v_actual_hash THEN
  SELECT string_agg(entity_key,', ' ORDER BY entity_key) INTO v_examples FROM (
   SELECT COALESCE(e.entity_key,a.entity_key) entity_key FROM msbf_m1.m1_3_expected_application_snapshot(v_run_id) e
   FULL JOIN msbf_m1.m1_3_actual_application_snapshot(v_run_id) a USING(entity_key)
   WHERE e.row_hash IS DISTINCT FROM a.row_hash ORDER BY entity_key LIMIT 10) q;
  RAISE EXCEPTION 'M1.3 persisted applications do not match regenerated blueprint: expected %, actual %, mismatches %, expected hash %, actual hash %, examples %.',
   v_expected,v_actual,v_mismatches,v_expected_hash,v_actual_hash,COALESCE(v_examples,'NONE');
 END IF;

 INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
 VALUES
  (v_run_id,'M1_3_GENERATION_SPEC','PORTFOLIO','M1.3 generation specification',v_spec::text,'JSON_TEXT','PASS','Code-owned application-generation assumptions are frozen for the run.'),
  (v_run_id,'M1_3_GENERATION_SPEC_HASH','PORTFOLIO','M1.3 generation specification hash',v_spec_hash,'MD5','PASS','Generation specification hash reconciles to the stored JSON specification.'),
  (v_run_id,'M1_3_APPLICATION_SET_HASH','PORTFOLIO','M1.3 application set hash',v_actual_hash,'MD5','PASS','Persisted and regenerated application rows reconcile exactly.'),
  (v_run_id,'M1_3_GENERATION_CHECKPOINT','PORTFOLIO','M1.3 generation checkpoint',jsonb_build_object('applications',v_actual,'expected_rows',v_expected,'row_mismatches',v_mismatches,'application_set_hash',v_actual_hash)::text,'JSON_TEXT','PASS','One deterministic requested-structure application was generated per accepted merchant.')
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
  metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
  threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

 UPDATE msbf_ctl.run_registry SET run_status='M1_3_GENERATED',notes='M1.3 deterministic application and requested sales-linked structures generated; pending validation.' WHERE run_id=v_run_id;
END $$;

COMMIT;

WITH ctx AS (SELECT run_id,run_code,run_version,run_status,population_id,as_of_date FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
counts AS (SELECT COUNT(*) applications,COUNT(DISTINCT merchant_id) merchants,MIN(requested_funding_amount) min_funding,MAX(requested_funding_amount) max_funding,round(AVG(requested_funding_amount),2) avg_funding FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM ctx)),
hashes AS (SELECT
 (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_expected_application_snapshot((SELECT run_id FROM ctx))) expected_hash,
 (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM ctx))) actual_hash,
 (SELECT COUNT(*) FROM msbf_m1.m1_3_expected_application_snapshot((SELECT run_id FROM ctx)) e FULL JOIN msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM ctx)) a USING(entity_key) WHERE e.row_hash IS DISTINCT FROM a.row_hash) mismatches)
SELECT ctx.*,counts.*,hashes.expected_hash,hashes.actual_hash,hashes.mismatches,
 (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=ctx.run_id AND evidence_code='M1_3_GENERATION_SPEC_HASH' AND segment_key='PORTFOLIO') generation_spec_hash
FROM ctx CROSS JOIN counts CROSS JOIN hashes;
