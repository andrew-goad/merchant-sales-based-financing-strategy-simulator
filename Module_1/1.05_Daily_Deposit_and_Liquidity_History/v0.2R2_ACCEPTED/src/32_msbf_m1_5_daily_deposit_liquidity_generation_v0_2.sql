/* ============================================================================
MSBF M1.5 Daily Deposit & Liquidity History — Deterministic Generation
Version : v0.2
Purpose : Translate accepted M1.4 POS settlement history into deterministic
          daily operating-account deposits, withdrawals, balances, NSF events,
          bounded liquidity stress, existing-financing pressure, and exact
          canonical evidence.
============================================================================ */
BEGIN;

INSERT INTO msbf_ref.acceptance_gate_catalog(gate_id,gate_name,module_code,severity,description)
VALUES('M1_5_DAILY_DEPOSIT_LIQUIDITY','M1.5 Daily Deposit & Liquidity History','M1','BLOCKING',
       'Deterministic 180-day merchant operating-account history for every accepted merchant, with exact balance roll-forward, canonical row reproduction, and strict stage boundaries.')
ON CONFLICT (gate_id) DO NOTHING;

CREATE OR REPLACE FUNCTION msbf_m1.m1_5_deposit_row_hash(
 p_population_id text,p_merchant_id text,p_observation_date date,
 p_opening_balance numeric,p_deposit_amount numeric,p_withdrawal_amount numeric,
 p_closing_balance numeric,p_available_balance numeric,p_minimum_balance numeric,
 p_nsf_count smallint,p_negative_balance_flag boolean,p_source_contract_id bigint,
 p_generated_by_run_id bigint)
RETURNS text LANGUAGE sql IMMUTABLE STRICT AS $fn$
SELECT md5(concat_ws('|',
 p_population_id,p_merchant_id,p_observation_date::text,
 to_char(p_opening_balance::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_deposit_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_withdrawal_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_closing_balance::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_available_balance::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_minimum_balance::numeric(18,2),'FM9999999999999999999990.00'),
 p_nsf_count::text,p_negative_balance_flag::text,p_source_contract_id::text,p_generated_by_run_id::text));
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_5_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $fn$
DECLARE
 v_status text; v_population_status text; v_population_id text; v_merchant_count integer;
 v_history_start date; v_history_end date; v_history_days integer;
 v_parameter_hash text; v_profile_hash text; v_source_hash text; v_population_hash text;
 v_application_hash text; v_pos_hash text;
 v_reparameter text; v_reprofile text; v_resource text; v_repopulation text; v_reapplication text; v_repos text;
 v_g1 text; v_m12 text; v_m13 text; v_m14 text;
 v_merchants bigint; v_apps bigint; v_pos bigint; v_deposits bigint; v_downstream bigint;
 v_required integer; v_resolved integer; v_deposit_sources integer; v_errors integer; v_enabled boolean;
BEGIN
 SELECT r.run_status,p.population_status,r.population_id,p.merchant_count,p.history_start_date,p.history_end_date,
        (p.history_end_date-p.history_start_date+1)::integer,
        r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,p.population_hash
 INTO STRICT v_status,v_population_status,v_population_id,v_merchant_count,v_history_start,v_history_end,v_history_days,
             v_parameter_hash,v_profile_hash,v_source_hash,v_population_hash
 FROM msbf_ctl.run_registry r
 JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_id=p_run_id;

 SELECT result_status INTO v_g1 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=p_run_id AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1;
 SELECT result_status INTO v_m12 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=p_run_id AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1;
 SELECT result_status INTO v_m13 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=p_run_id AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1;
 SELECT result_status INTO v_m14 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=p_run_id AND gate_id='M1_4_DAILY_POS_HISTORY' ORDER BY review_version DESC LIMIT 1;

 SELECT metric_value_text INTO v_application_hash FROM msbf_ctl.run_evidence
 WHERE run_id=p_run_id AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO';
 SELECT metric_value_text INTO v_pos_hash FROM msbf_ctl.run_evidence
 WHERE run_id=p_run_id AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO';

 SELECT COUNT(*) INTO v_merchants FROM msbf_m1.merchant_master WHERE population_id=v_population_id;
 SELECT COUNT(*) INTO v_apps FROM msbf_m1.merchant_application WHERE created_by_run_id=p_run_id;
 SELECT COUNT(*) INTO v_pos FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=p_run_id;
 SELECT COUNT(*) INTO v_deposits FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=p_run_id;

 WITH required_parameters AS (
   SELECT 'enable_deposit_history_flag'::text AS parameter_name,'GLOBAL'::text AS scope_key
   UNION ALL SELECT 'deposit_capture_rate_sigma','GLOBAL'
   UNION ALL SELECT 'withdrawal_to_deposit_rate_center','GLOBAL'
   UNION ALL SELECT 'liquidity_shock_multiplier','GLOBAL'
   UNION ALL SELECT 'deposit_history_missing_probability','GLOBAL'
   UNION ALL SELECT 'qa_reconciliation_tolerance_amount','GLOBAL'
   UNION ALL
   SELECT p.parameter_name,'INDUSTRY:'||i.industry_code
   FROM (VALUES ('deposit_capture_rate_center'),('balance_buffer_days_center')) p(parameter_name)
   CROSS JOIN msbf_ref.industry i
   UNION ALL
   SELECT p.parameter_name,'RISK_TIER:'||t.risk_tier::text
   FROM (VALUES ('nsf_daily_probability'),('negative_balance_daily_probability')) p(parameter_name)
   CROSS JOIN generate_series(1,5) t(risk_tier)
 )
 SELECT COUNT(*),COUNT(rps.parameter_name) INTO v_required,v_resolved
 FROM required_parameters req LEFT JOIN msbf_ctl.run_parameter_snapshot rps
 ON rps.run_id=p_run_id AND rps.parameter_name=req.parameter_name AND rps.scope_key=req.scope_key;

 SELECT COALESCE((resolved_value->>'value_boolean')::boolean,false) INTO v_enabled
 FROM msbf_ctl.run_parameter_snapshot
 WHERE run_id=p_run_id AND parameter_name='enable_deposit_history_flag' AND scope_key='GLOBAL';

 SELECT COUNT(*) INTO v_deposit_sources
 FROM msbf_ctl.run_source_snapshot rss
 JOIN msbf_ctl.source_contract sc ON sc.source_contract_id=rss.source_contract_id
 WHERE rss.run_id=p_run_id AND rss.source_code='DEPOSIT_DAILY'
   AND rss.quality_status='CONTRACT_READY_PRE_GENERATION'
   AND sc.source_code='DEPOSIT_DAILY' AND sc.status='APPROVED';

 SELECT
  (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=p_run_id)
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

 SELECT COUNT(*) INTO v_errors FROM msbf_ctl.profile_resolution_error
 WHERE run_id=p_run_id AND severity='BLOCKING';

 IF v_status<>'M1_4_ACCEPTED' THEN RAISE EXCEPTION 'M1.5 generation requires run_status=M1_4_ACCEPTED; observed %.',v_status; END IF;
 IF v_population_status<>'M1_2_ACCEPTED' THEN RAISE EXCEPTION 'M1.5 requires population_status=M1_2_ACCEPTED; observed %.',v_population_status; END IF;
 IF v_g1 IS DISTINCT FROM 'PASS' OR v_m12 IS DISTINCT FROM 'PASS' OR v_m13 IS DISTINCT FROM 'PASS' OR v_m14 IS DISTINCT FROM 'PASS' THEN
   RAISE EXCEPTION 'M1.5 requires accepted G1, M1.2, M1.3, and M1.4 gates.';
 END IF;
 IF v_parameter_hash<>'bd09e598c82db96e47459d77fd11e7c8'
    OR v_profile_hash<>'462cbd2ed92f68e5bdecf6b17537a973'
    OR v_source_hash<>'93c3d1368fb2450ab4a08e2b721f92d3'
    OR v_population_hash<>'9b706c926260a3ef1ae8ac95eed5d0bf'
    OR v_application_hash<>'01485256b9b5748fb412743d35ced602'
    OR v_pos_hash<>'d1971e8d319483c187ec0c0483a31e33' THEN
   RAISE EXCEPTION 'M1.5 accepted upstream identity differs from the approved baseline build.';
 END IF;
 IF v_merchant_count<>750 OR v_merchants<>750 OR v_apps<>750 OR v_history_days<>180 OR v_pos<>135000 THEN
   RAISE EXCEPTION 'M1.5 requires 750 merchants, 750 applications, 180 days, and 135000 accepted POS rows; observed merchants %, applications %, days %, POS rows %.',v_merchants,v_apps,v_history_days,v_pos;
 END IF;
 IF v_required<>32 OR v_resolved<>32 THEN RAISE EXCEPTION 'M1.5 requires 32 resolved parameter/scope pairs; observed % of %.',v_resolved,v_required; END IF;
 IF NOT COALESCE(v_enabled,false) THEN RAISE EXCEPTION 'M1.5 deposit history is not enabled in the frozen run snapshot.'; END IF;
 IF v_deposit_sources<>1 THEN RAISE EXCEPTION 'M1.5 requires exactly one approved, contract-ready DEPOSIT_DAILY source snapshot; observed %.',v_deposit_sources; END IF;
 IF v_deposits<>0 THEN RAISE EXCEPTION 'M1.5 baseline deposit rows already exist (% rows); regeneration is prohibited.',v_deposits; END IF;
 IF v_downstream<>0 THEN RAISE EXCEPTION 'M1.5 downstream or scenario rows already exist (% rows); generation is prohibited.',v_downstream; END IF;
 IF v_errors<>0 THEN RAISE EXCEPTION 'M1.5 blocking configuration errors exist (% rows).',v_errors; END IF;

 SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key))
 INTO v_reparameter FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id;
 SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code))
 INTO v_reprofile FROM msbf_ctl.run_profile_snapshot WHERE run_id=p_run_id;
 SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code))
 INTO v_resource FROM msbf_ctl.run_source_snapshot WHERE run_id=p_run_id;
 SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key))
 INTO v_repopulation FROM msbf_m1.m1_2_actual_entity_snapshot(p_run_id);
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
 INTO v_reapplication FROM msbf_m1.m1_3_actual_application_snapshot(p_run_id);
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
 INTO v_repos FROM msbf_m1.m1_4_actual_pos_snapshot(p_run_id);

 IF v_parameter_hash IS DISTINCT FROM v_reparameter OR v_profile_hash IS DISTINCT FROM v_reprofile OR v_source_hash IS DISTINCT FROM v_resource
    OR v_population_hash IS DISTINCT FROM v_repopulation OR v_application_hash IS DISTINCT FROM v_reapplication OR v_pos_hash IS DISTINCT FROM v_repos THEN
   RAISE EXCEPTION 'M1.5 accepted upstream hashes do not reconcile to stored hashes.';
 END IF;
END $fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_5_merchant_liquidity_profile(p_run_id bigint)
RETURNS TABLE(
 run_id bigint,population_id text,merchant_id text,industry_code text,cashflow_archetype_code text,
 merchant_size_tier text,annual_sales_band text,relationship_stage text,relationship_quality_tier smallint,
 deposit_relationship_flag boolean,prior_advance_count integer,prior_payment_interruption_flag boolean,
 liquidity_risk_tier smallint,history_start_date date,history_end_date date,history_days integer,
 source_contract_id bigint,deposit_capture_center numeric(12,8),deposit_capture_sigma numeric(12,8),
 merchant_capture_rate numeric(12,8),relationship_capture_adjustment numeric(12,8),
 balance_buffer_days_center numeric(12,8),merchant_buffer_days numeric(12,8),
 withdrawal_to_deposit_center numeric(12,8),merchant_withdrawal_rate numeric(12,8),
 nsf_daily_probability numeric(12,8),negative_balance_daily_probability numeric(12,8),
 liquidity_shock_multiplier numeric(12,8),deposit_history_missing_probability numeric(12,8),
 deposit_source_available_flag boolean,avg_daily_eligible_sales numeric(18,6),
 avg_daily_net_merchant_proceeds numeric(18,6),target_buffer_amount numeric(18,2),
 initial_opening_balance numeric(18,2),lower_balance_floor numeric(18,2),avg_owner_score numeric(12,4),
 any_major_derogatory_flag boolean,any_bankruptcy_flag boolean,active_financing_flag boolean,
 financing_start_date date,financing_end_date date,financing_expected_days smallint,
 financing_daily_remittance numeric(18,2))
LANGUAGE sql STABLE AS $fn$
WITH ctx AS (
 SELECT r.run_id,r.population_id,p.history_start_date,p.history_end_date,
        (p.history_end_date-p.history_start_date+1)::integer AS history_days,p.deterministic_seed_version,
        (SELECT rss.source_contract_id FROM msbf_ctl.run_source_snapshot rss
          WHERE rss.run_id=r.run_id AND rss.source_code='DEPOSIT_DAILY') AS source_contract_id,
        (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot
          WHERE run_id=r.run_id AND parameter_name='deposit_capture_rate_sigma' AND scope_key='GLOBAL') AS capture_sigma,
        (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot
          WHERE run_id=r.run_id AND parameter_name='withdrawal_to_deposit_rate_center' AND scope_key='GLOBAL') AS withdrawal_center,
        (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot
          WHERE run_id=r.run_id AND parameter_name='liquidity_shock_multiplier' AND scope_key='GLOBAL') AS shock_multiplier,
        (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot
          WHERE run_id=r.run_id AND parameter_name='deposit_history_missing_probability' AND scope_key='GLOBAL') AS missing_probability
 FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_id=p_run_id
), industry_params AS (
 SELECT split_part(scope_key,':',2) AS industry_code,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='deposit_capture_rate_center') AS capture_center,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='balance_buffer_days_center') AS buffer_days_center
 FROM msbf_ctl.run_parameter_snapshot
 WHERE run_id=p_run_id AND scope_key LIKE 'INDUSTRY:%'
   AND parameter_name IN ('deposit_capture_rate_center','balance_buffer_days_center')
 GROUP BY split_part(scope_key,':',2)
), risk_params AS (
 SELECT split_part(scope_key,':',2)::smallint AS risk_tier,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='nsf_daily_probability') AS nsf_probability,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='negative_balance_daily_probability') AS negative_probability
 FROM msbf_ctl.run_parameter_snapshot
 WHERE run_id=p_run_id AND scope_key LIKE 'RISK_TIER:%'
   AND parameter_name IN ('nsf_daily_probability','negative_balance_daily_probability')
 GROUP BY split_part(scope_key,':',2)::smallint
), owners AS (
 SELECT o.merchant_id,avg(o.owner_credit_score)::numeric AS avg_owner_score,
        bool_or(o.major_derogatory_flag) AS any_major_derogatory_flag,
        bool_or(o.bankruptcy_flag) AS any_bankruptcy_flag
 FROM msbf_m1.merchant_owner_guarantor o
 WHERE o.created_by_run_id=p_run_id
 GROUP BY o.merchant_id
), pos AS (
 SELECT p.merchant_id,
        avg(p.eligible_pos_sales) FILTER(WHERE p.processor_status<>'NOT_YET_ACTIVE')::numeric AS avg_daily_eligible_sales,
        avg(p.net_merchant_proceeds) FILTER(WHERE p.processor_status<>'NOT_YET_ACTIVE')::numeric AS avg_daily_net_merchant_proceeds
 FROM msbf_m1.merchant_pos_daily_base p
 WHERE p.generated_by_run_id=p_run_id
 GROUP BY p.merchant_id
), base AS (
 SELECT ctx.*,m.merchant_id,m.merchant_size_tier,m.annual_sales_band,i.industry_code,
        rel.relationship_stage,coalesce(rel.relationship_quality_tier,3)::smallint AS relationship_quality_tier,
        rel.deposit_relationship_flag,rel.prior_advance_count,rel.prior_payment_interruption_flag,
        op.cashflow_archetype_code,ip.capture_center,ip.buffer_days_center,
        own.avg_owner_score,own.any_major_derogatory_flag,own.any_bankruptcy_flag,
        coalesce(pos.avg_daily_eligible_sales,0)::numeric AS avg_daily_eligible_sales,
        coalesce(pos.avg_daily_net_merchant_proceeds,0)::numeric AS avg_daily_net_merchant_proceeds,
        CASE WHEN rel.deposit_relationship_flag THEN 0.025 ELSE -0.010 END::numeric AS relationship_capture_adjustment,
        msbf_ctl.deterministic_normal(m.merchant_id,ctx.deterministic_seed_version||':M1_5:CAPTURE') AS z_capture,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_5:BUFFER') AS u_buffer,
        msbf_ctl.deterministic_normal(m.merchant_id,ctx.deterministic_seed_version||':M1_5:WITHDRAWAL') AS z_withdrawal,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_5:OPENING') AS u_opening,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_5:SOURCE_MISSING') AS u_source_missing,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_5:FINANCING') AS u_financing,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_5:FINANCING_START') AS u_financing_start,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_5:FINANCING_DURATION') AS u_financing_duration
 FROM ctx
 JOIN msbf_m1.merchant_master m ON m.population_id=ctx.population_id
 JOIN msbf_m1.merchant_industry_assignment i ON i.merchant_id=m.merchant_id
  AND i.assignment_type='PRIMARY' AND i.created_by_run_id=ctx.run_id
 JOIN msbf_m1.merchant_relationship_snapshot rel ON rel.merchant_id=m.merchant_id
  AND rel.as_of_date=ctx.history_end_date AND rel.created_by_run_id=ctx.run_id
 JOIN msbf_m1.m1_4_merchant_operating_profile(p_run_id) op ON op.merchant_id=m.merchant_id
 JOIN industry_params ip ON ip.industry_code=i.industry_code
 JOIN owners own ON own.merchant_id=m.merchant_id
 JOIN pos ON pos.merchant_id=m.merchant_id
), tiered AS (
 SELECT b.*,
  greatest(1,least(5,
    b.relationship_quality_tier
    +CASE WHEN b.any_bankruptcy_flag THEN 1 WHEN b.any_major_derogatory_flag AND b.avg_owner_score<650 THEN 1 ELSE 0 END
    +CASE WHEN b.prior_payment_interruption_flag THEN 1 ELSE 0 END
    -CASE WHEN b.relationship_stage='RETURNING_GOOD' AND b.avg_owner_score>=740 AND NOT b.any_major_derogatory_flag THEN 1 ELSE 0 END
  ))::smallint AS liquidity_risk_tier
 FROM base b
), enriched AS (
 SELECT t.*,rp.nsf_probability,rp.negative_probability,
  least(1.00,greatest(0.45,
    t.capture_center+t.capture_sigma*t.z_capture+t.relationship_capture_adjustment))::numeric AS merchant_capture_rate_calc,
  least(30.00,greatest(1.50,
    t.buffer_days_center*(0.85+0.30*t.u_buffer)
    *(1.20-0.11*(t.liquidity_risk_tier-1))
    *CASE t.relationship_stage WHEN 'RETURNING_GOOD' THEN 1.10 WHEN 'RETURNING_MIXED' THEN 0.85
                               WHEN 'LOW_AND_GROW' THEN 0.78 ELSE 0.92 END))::numeric AS merchant_buffer_days_calc,
  least(1.15,greatest(0.65,
    t.withdrawal_center+0.06*(t.liquidity_risk_tier-3)+0.05*t.z_withdrawal
    +CASE t.relationship_stage WHEN 'RETURNING_MIXED' THEN 0.03 WHEN 'LOW_AND_GROW' THEN 0.02
                               WHEN 'RETURNING_GOOD' THEN -0.02 ELSE 0 END))::numeric AS merchant_withdrawal_rate_calc,
  (t.prior_advance_count>0 AND t.u_financing<CASE t.relationship_stage
      WHEN 'RETURNING_MIXED' THEN 0.55 WHEN 'RETURNING_GOOD' THEN 0.30 WHEN 'LOW_AND_GROW' THEN 0.20 ELSE 0.12 END) AS active_financing_flag_calc,
  (CASE WHEN t.u_financing_duration<0.25 THEN 30 WHEN t.u_financing_duration<0.70 THEN 60 ELSE 90 END)::smallint AS financing_expected_days_calc
 FROM tiered t JOIN risk_params rp ON rp.risk_tier=t.liquidity_risk_tier
), buffered AS (
 SELECT e.*,
  greatest(1000.00,round(e.avg_daily_eligible_sales*e.merchant_buffer_days_calc,2))::numeric(18,2) AS target_buffer_amount_calc,
  (e.history_start_date+(15+floor(45*e.u_financing_start)::integer))::date AS financing_start_calc
 FROM enriched e
), final_profile AS (
 SELECT b.*,
  least(b.history_end_date,b.financing_start_calc+b.financing_expected_days_calc-1)::date AS financing_end_calc
 FROM buffered b
)
SELECT
 b.run_id,b.population_id,b.merchant_id,b.industry_code,b.cashflow_archetype_code,b.merchant_size_tier,b.annual_sales_band,
 b.relationship_stage,b.relationship_quality_tier,b.deposit_relationship_flag,b.prior_advance_count,b.prior_payment_interruption_flag,
 b.liquidity_risk_tier,b.history_start_date,b.history_end_date,b.history_days,b.source_contract_id,
 b.capture_center::numeric(12,8),b.capture_sigma::numeric(12,8),b.merchant_capture_rate_calc::numeric(12,8),
 b.relationship_capture_adjustment::numeric(12,8),b.buffer_days_center::numeric(12,8),b.merchant_buffer_days_calc::numeric(12,8),
 b.withdrawal_center::numeric(12,8),b.merchant_withdrawal_rate_calc::numeric(12,8),
 b.nsf_probability::numeric(12,8),b.negative_probability::numeric(12,8),
 b.shock_multiplier::numeric(12,8),b.missing_probability::numeric(12,8),
 (b.u_source_missing>=b.missing_probability) AS deposit_source_available_flag,
 b.avg_daily_eligible_sales::numeric(18,6),b.avg_daily_net_merchant_proceeds::numeric(18,6),b.target_buffer_amount_calc,
 round(b.target_buffer_amount_calc*(0.85+0.30*b.u_opening),2)::numeric(18,2) AS initial_opening_balance,
 round(-b.target_buffer_amount_calc*(0.05+0.05*(b.liquidity_risk_tier-1)),2)::numeric(18,2) AS lower_balance_floor,
 b.avg_owner_score::numeric(12,4),b.any_major_derogatory_flag,b.any_bankruptcy_flag,b.active_financing_flag_calc,
 CASE WHEN b.active_financing_flag_calc THEN b.financing_start_calc END AS financing_start_date,
 CASE WHEN b.active_financing_flag_calc THEN b.financing_end_calc END AS financing_end_date,
 CASE WHEN b.active_financing_flag_calc THEN b.financing_expected_days_calc ELSE 0::smallint END AS financing_expected_days,
 CASE WHEN b.active_financing_flag_calc
      THEN round(b.avg_daily_net_merchant_proceeds*(0.025+0.035*b.u_financing),2)::numeric(18,2)
      ELSE 0.00::numeric(18,2) END AS financing_daily_remittance
FROM final_profile b;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_5_daily_liquidity_blueprint(p_run_id bigint)
RETURNS TABLE(
 population_id text,merchant_id text,observation_date date,opening_balance numeric(18,2),
 deposit_amount numeric(18,2),withdrawal_amount numeric(18,2),closing_balance numeric(18,2),
 available_balance numeric(18,2),minimum_balance numeric(18,2),nsf_count smallint,
 negative_balance_flag boolean,source_contract_id bigint,generated_by_run_id bigint,row_hash text,
 industry_code text,cashflow_archetype_code text,relationship_stage text,liquidity_risk_tier smallint,
 deposit_relationship_flag boolean,deposit_source_available_flag boolean,daily_capture_rate numeric(12,8),
 base_pos_deposit_amount numeric(18,2),non_pos_support_deposit_amount numeric(18,2),
 existing_financing_remittance_amount numeric(18,2),daily_withdrawal_rate numeric(12,8),temporary_hold_amount numeric(18,2),
 target_buffer_amount numeric(18,2),lower_balance_floor numeric(18,2),liquidity_event_code text,
 processor_status text,data_connection_status text,eligible_pos_sales numeric(18,2),net_merchant_proceeds numeric(18,2),
 adjusted_nsf_probability numeric(12,8),negative_balance_daily_probability numeric(12,8),
 active_financing_flag boolean,financing_start_date date,financing_end_date date,financing_daily_remittance numeric(18,2))
LANGUAGE sql STABLE AS $fn$
WITH profile AS (
 SELECT * FROM msbf_m1.m1_5_merchant_liquidity_profile(p_run_id)
), grid AS (
 SELECT pr.*,p.observation_date,p.eligible_pos_sales,p.net_merchant_proceeds,p.refund_amount,p.chargeback_amount,
        p.reversal_amount,p.processor_status,p.data_connection_status,
        extract(dow from p.observation_date)::integer AS day_of_week,
        extract(day from p.observation_date)::integer AS day_of_month,
        msbf_ctl.deterministic_normal(pr.merchant_id||'|'||p.observation_date,
          pop.deterministic_seed_version||':M1_5:CAPTURE_DAY') AS z_capture_day,
        msbf_ctl.deterministic_normal(pr.merchant_id||'|'||p.observation_date,
          pop.deterministic_seed_version||':M1_5:WITHDRAWAL_DAY') AS z_withdrawal_day,
        msbf_ctl.deterministic_uniform(pr.merchant_id||'|'||p.observation_date,
          pop.deterministic_seed_version||':M1_5:NEGATIVE_EVENT') AS u_negative,
        msbf_ctl.deterministic_uniform(pr.merchant_id||'|'||p.observation_date,
          pop.deterministic_seed_version||':M1_5:STRESS_SIZE') AS u_stress_size,
        msbf_ctl.deterministic_uniform(pr.merchant_id||'|'||p.observation_date,
          pop.deterministic_seed_version||':M1_5:HOLD') AS u_hold,
        msbf_ctl.deterministic_uniform(pr.merchant_id||'|'||p.observation_date,
          pop.deterministic_seed_version||':M1_5:NSF') AS u_nsf,
        msbf_ctl.deterministic_uniform(pr.merchant_id||'|'||p.observation_date,
          pop.deterministic_seed_version||':M1_5:NSF_COUNT') AS u_nsf_count
 FROM profile pr
 JOIN msbf_m1.merchant_pos_daily_base p ON p.merchant_id=pr.merchant_id
  AND p.population_id=pr.population_id AND p.generated_by_run_id=pr.run_id
 JOIN msbf_m1.population_registry pop ON pop.population_id=pr.population_id
), planned AS (
 SELECT g.*,
  least(1.00,greatest(0.25,g.merchant_capture_rate+g.deposit_capture_sigma*0.20*g.z_capture_day))::numeric AS daily_capture_rate_calc,
  CASE g.day_of_week WHEN 1 THEN 1.08 WHEN 2 THEN 0.98 WHEN 3 THEN 0.94
                     WHEN 4 THEN 0.98 WHEN 5 THEN 1.12 WHEN 6 THEN 0.88 ELSE 0.82 END::numeric AS weekday_withdrawal_factor,
  CASE WHEN g.day_of_month<=3 THEN 1.12 WHEN g.day_of_month BETWEEN 14 AND 16 THEN 1.08
       WHEN g.day_of_month>=27 THEN 1.06 ELSE 1.00 END::numeric AS calendar_withdrawal_factor,
  exp(0.08*g.z_withdrawal_day-0.5*power(0.08,2))::numeric AS withdrawal_noise_factor,
  CASE WHEN g.processor_status='NOT_YET_ACTIVE' THEN 0.00
       WHEN g.processor_status='OUTAGE' THEN 1.10
       WHEN g.processor_status='DEGRADED' THEN 1.05
       WHEN g.cashflow_archetype_code='RECENT_DISRUPTION' THEN 1.08
       ELSE 1.00 END::numeric AS operating_withdrawal_factor,
  round((g.chargeback_amount+g.reversal_amount+0.20*g.refund_amount)*(0.50+0.50*g.u_hold),2)::numeric(18,2) AS hold_amount_calc
 FROM grid g
), daily_amounts AS (
 SELECT p.*,
  CASE WHEN p.processor_status='NOT_YET_ACTIVE' THEN 0.00::numeric
       ELSE round(p.net_merchant_proceeds*p.daily_capture_rate_calc,2)::numeric END AS base_deposit_calc,
  CASE WHEN p.processor_status='NOT_YET_ACTIVE' THEN 0.00::numeric
       ELSE round(p.net_merchant_proceeds*p.daily_capture_rate_calc*p.merchant_withdrawal_rate*
         p.weekday_withdrawal_factor*p.calendar_withdrawal_factor*p.withdrawal_noise_factor*
         p.operating_withdrawal_factor,2)::numeric END AS base_withdrawal_calc,
  CASE WHEN p.processor_status='NOT_YET_ACTIVE' THEN 0.00::numeric
       WHEN p.u_negative<p.negative_balance_daily_probability THEN
         round(p.target_buffer_amount*(0.10+0.20*p.u_stress_size)*p.liquidity_shock_multiplier,2)::numeric
       ELSE 0.00::numeric END AS stress_withdrawal_calc,
  CASE WHEN p.processor_status<>'NOT_YET_ACTIVE' AND p.active_financing_flag
             AND p.observation_date BETWEEN p.financing_start_date AND p.financing_end_date
       THEN p.financing_daily_remittance ELSE 0.00::numeric END AS financing_remittance_calc
 FROM planned p
), raw_flows AS (
 SELECT d.*,
  d.base_deposit_calc::numeric(18,2) AS base_pos_deposit_amount_calc,
  (d.base_withdrawal_calc+d.stress_withdrawal_calc+d.financing_remittance_calc)::numeric(18,2) AS total_withdrawal_calc,
  (d.base_deposit_calc-d.base_withdrawal_calc-d.stress_withdrawal_calc-d.financing_remittance_calc)::numeric(18,2) AS raw_net_flow
 FROM daily_amounts d
), raw_balances AS (
 SELECT r.*,
  (r.initial_opening_balance+
   SUM(r.raw_net_flow) OVER(PARTITION BY r.merchant_id ORDER BY r.observation_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW))::numeric(18,2) AS raw_closing_balance
 FROM raw_flows r
), support_cumulative AS (
 SELECT r.*,
  greatest(0.00,
    r.lower_balance_floor-
    MIN(r.raw_closing_balance) OVER(PARTITION BY r.merchant_id ORDER BY r.observation_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
  )::numeric(18,2) AS cumulative_support_deposit
 FROM raw_balances r
), support_increment AS (
 SELECT s.*,
  (s.cumulative_support_deposit-
   lag(s.cumulative_support_deposit,1,0.00::numeric) OVER(PARTITION BY s.merchant_id ORDER BY s.observation_date))::numeric(18,2) AS support_deposit_increment
 FROM support_cumulative s
), balanced AS (
 SELECT s.*,
  (s.base_pos_deposit_amount_calc+s.support_deposit_increment)::numeric(18,2) AS final_deposit_amount,
  s.total_withdrawal_calc::numeric(18,2) AS final_withdrawal_amount,
  (s.initial_opening_balance+
   COALESCE(SUM(s.raw_net_flow+s.support_deposit_increment) OVER(PARTITION BY s.merchant_id ORDER BY s.observation_date ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0.00))::numeric(18,2) AS opening_balance_calc,
  (s.initial_opening_balance+
   SUM(s.raw_net_flow+s.support_deposit_increment) OVER(PARTITION BY s.merchant_id ORDER BY s.observation_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW))::numeric(18,2) AS closing_balance_calc
 FROM support_increment s
), available AS (
 SELECT b.*,
  (b.closing_balance_calc-b.hold_amount_calc)::numeric(18,2) AS available_balance_calc,
  least(b.opening_balance_calc,b.closing_balance_calc,(b.closing_balance_calc-b.hold_amount_calc))::numeric(18,2) AS minimum_balance_calc
 FROM balanced b
), nsf AS (
 SELECT a.*,
  least(0.25,a.nsf_daily_probability*
    CASE WHEN a.available_balance_calc<0 THEN 1.75
         WHEN a.available_balance_calc<a.target_buffer_amount*0.25 THEN 1.25
         ELSE 0.35 END)::numeric AS adjusted_nsf_probability_calc
 FROM available a
), final_rows AS (
 SELECT n.*,
  CASE WHEN n.u_nsf<n.adjusted_nsf_probability_calc
       THEN (1+CASE WHEN n.u_nsf_count<0.05 THEN 1 ELSE 0 END)::smallint ELSE 0::smallint END AS nsf_count_calc,
  (n.minimum_balance_calc<0) AS negative_balance_flag_calc,
  CASE WHEN n.processor_status='NOT_YET_ACTIVE' THEN 'PRE_OPEN'
       WHEN n.support_deposit_increment>0 THEN 'NON_POS_SUPPORT_DEPOSIT'
       WHEN n.stress_withdrawal_calc>0 THEN 'NEGATIVE_BALANCE_PRESSURE'
       WHEN n.processor_status='OUTAGE' THEN 'PROCESSOR_OUTAGE'
       WHEN n.cashflow_archetype_code='RECENT_DISRUPTION' THEN 'RECENT_DISRUPTION'
       WHEN n.available_balance_calc<n.target_buffer_amount*0.25 THEN 'LOW_LIQUIDITY'
       ELSE 'NORMAL' END AS liquidity_event_code_calc
 FROM nsf n
)
SELECT
 f.population_id,f.merchant_id,f.observation_date,f.opening_balance_calc,f.final_deposit_amount,
 f.final_withdrawal_amount,f.closing_balance_calc,f.available_balance_calc,f.minimum_balance_calc,
 f.nsf_count_calc,f.negative_balance_flag_calc,f.source_contract_id,f.run_id AS generated_by_run_id,
 msbf_m1.m1_5_deposit_row_hash(f.population_id,f.merchant_id,f.observation_date,
  f.opening_balance_calc,f.final_deposit_amount,f.final_withdrawal_amount,f.closing_balance_calc,
  f.available_balance_calc,f.minimum_balance_calc,f.nsf_count_calc,f.negative_balance_flag_calc,
  f.source_contract_id,f.run_id) AS row_hash,
 f.industry_code,f.cashflow_archetype_code,f.relationship_stage,f.liquidity_risk_tier,
 f.deposit_relationship_flag,f.deposit_source_available_flag,f.daily_capture_rate_calc::numeric(12,8),
 f.base_pos_deposit_amount_calc,f.support_deposit_increment::numeric(18,2),f.financing_remittance_calc::numeric(18,2),
 CASE WHEN f.base_pos_deposit_amount_calc=0 THEN 0.00
      ELSE (f.final_withdrawal_amount/f.base_pos_deposit_amount_calc) END::numeric(12,8) AS daily_withdrawal_rate,
 f.hold_amount_calc,f.target_buffer_amount,f.lower_balance_floor,f.liquidity_event_code_calc,
 f.processor_status,f.data_connection_status,f.eligible_pos_sales,f.net_merchant_proceeds,
 f.adjusted_nsf_probability_calc::numeric(12,8),f.negative_balance_daily_probability,
 f.active_financing_flag,f.financing_start_date,f.financing_end_date,f.financing_daily_remittance
FROM final_rows f
ORDER BY f.merchant_id,f.observation_date;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_5_expected_deposit_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text) LANGUAGE sql STABLE AS $fn$
SELECT merchant_id||'|'||observation_date::text,row_hash
FROM msbf_m1.m1_5_daily_liquidity_blueprint(p_run_id)
ORDER BY merchant_id,observation_date;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_5_actual_deposit_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text) LANGUAGE sql STABLE AS $fn$
SELECT d.merchant_id||'|'||d.observation_date::text,
 msbf_m1.m1_5_deposit_row_hash(d.population_id,d.merchant_id,d.observation_date,
  d.opening_balance,d.deposit_amount,d.withdrawal_amount,d.closing_balance,
  d.available_balance,d.minimum_balance,d.nsf_count,d.negative_balance_flag,
  d.source_contract_id,d.generated_by_run_id)
FROM msbf_m1.merchant_deposit_daily_base d
WHERE d.generated_by_run_id=p_run_id
ORDER BY d.merchant_id,d.observation_date;
$fn$;

DO $do$
DECLARE v_run_id bigint;
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 PERFORM msbf_m1.m1_5_assert_generation_ready(v_run_id);
END $do$;

CREATE TEMP TABLE _m1_5_blueprint ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_5_daily_liquidity_blueprint(
 (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE INDEX ON _m1_5_blueprint(merchant_id,observation_date);
CREATE INDEX ON _m1_5_blueprint(industry_code,liquidity_risk_tier);

DO $do$
DECLARE v_rows bigint; v_merchants bigint; v_dates bigint;
BEGIN
 SELECT COUNT(*),COUNT(DISTINCT merchant_id),COUNT(DISTINCT observation_date)
 INTO v_rows,v_merchants,v_dates FROM _m1_5_blueprint;
 IF v_rows<>135000 OR v_merchants<>750 OR v_dates<>180 THEN
   RAISE EXCEPTION 'M1.5 blueprint cardinality mismatch: rows %, merchants %, dates %.',v_rows,v_merchants,v_dates;
 END IF;
END $do$;

INSERT INTO msbf_m1.merchant_deposit_daily_base(
 population_id,merchant_id,observation_date,opening_balance,deposit_amount,withdrawal_amount,
 closing_balance,available_balance,minimum_balance,nsf_count,negative_balance_flag,
 source_contract_id,generated_by_run_id,row_hash)
SELECT population_id,merchant_id,observation_date,opening_balance,deposit_amount,withdrawal_amount,
 closing_balance,available_balance,minimum_balance,nsf_count,negative_balance_flag,
 source_contract_id,generated_by_run_id,row_hash
FROM _m1_5_blueprint
ORDER BY merchant_id,observation_date;

DO $do$
DECLARE v_run_id bigint; v_expected_rows bigint; v_actual_rows bigint; v_mismatches bigint;
        v_expected_hash text; v_actual_hash text; v_spec jsonb; v_summary jsonb;
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;

 SELECT COUNT(*),md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
 INTO v_expected_rows,v_expected_hash FROM msbf_m1.m1_5_expected_deposit_snapshot(v_run_id);
 SELECT COUNT(*),md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
 INTO v_actual_rows,v_actual_hash FROM msbf_m1.m1_5_actual_deposit_snapshot(v_run_id);
 SELECT COUNT(*) INTO v_mismatches
 FROM msbf_m1.m1_5_expected_deposit_snapshot(v_run_id) e
 FULL JOIN msbf_m1.m1_5_actual_deposit_snapshot(v_run_id) a USING(entity_key)
 WHERE e.row_hash IS DISTINCT FROM a.row_hash;

 IF v_expected_rows<>135000 OR v_actual_rows<>135000 OR v_mismatches<>0 OR v_expected_hash IS DISTINCT FROM v_actual_hash THEN
   RAISE EXCEPTION 'M1.5 persisted deposit history does not match regenerated blueprint: expected rows %, actual %, mismatches %, expected hash %, actual hash %.',
     v_expected_rows,v_actual_rows,v_mismatches,v_expected_hash,v_actual_hash;
 END IF;

 v_spec:=jsonb_build_object(
  'stage','M1.5','stage_name','Daily Deposit & Liquidity History',
  'code_version','M1_5_LIQUIDITY_V1','history_days',180,'expected_rows',135000,
  'generation_grain','merchant|calendar_date',
  'deposit_method','accepted net merchant proceeds x governed industry capture rate x deterministic daily variation plus bounded non-POS support deposits',
  'withdrawal_method','governed withdrawal-to-deposit center x provisional liquidity risk tier x weekday/calendar pattern x deterministic daily variation x bounded stress draws plus bounded existing-financing remittance pressure',
  'balance_method','exact opening-to-closing roll-forward with cumulative lower-floor support and temporary holds',
  'risk_tier_method','relationship quality adjusted by synthetic owner derogatory and prior-interruption evidence; not a calibrated credit-risk tier',
  'source_missingness_method','merchant-level deterministic observability flag retained for M1.7; physical rows represent latent synthetic truth and are not suppressed',
  'nsf_method','rare deterministic event probability rising by provisional liquidity risk tier and current available-balance pressure',
  'scenario_rows_generated',false,'source_snapshot_rows_generated',false,'feature_rows_generated',false,
  'production_boundary','Synthetic operating-account history; not bank-statement data, transaction categorization, calibrated liquidity behavior, or production servicing evidence.');

 SELECT jsonb_build_object(
  'rows',COUNT(*),'merchants',COUNT(DISTINCT merchant_id),'dates',COUNT(DISTINCT observation_date),
  'deposits',SUM(deposit_amount),'withdrawals',SUM(withdrawal_amount),
  'ending_balance',SUM(closing_balance) FILTER(WHERE observation_date=(SELECT MAX(observation_date) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=v_run_id)),
  'negative_balance_rows',COUNT(*) FILTER(WHERE negative_balance_flag),
  'nsf_events',SUM(nsf_count),'deposit_set_hash',v_actual_hash)
 INTO v_summary FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=v_run_id;

 INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
 VALUES
  (v_run_id,'M1_5_GENERATION_SPEC','PORTFOLIO','M1.5 generation specification',v_spec::text,'JSON_TEXT','PASS','Code-owned deterministic deposit/liquidity assumptions and stage boundaries.'),
  (v_run_id,'M1_5_GENERATION_SPEC_HASH','PORTFOLIO','M1.5 generation specification hash',md5(v_spec::text),'MD5','PASS','Hash of the canonical M1.5 generation specification.'),
  (v_run_id,'M1_5_DEPOSIT_SET_HASH','PORTFOLIO','M1.5 deposit-history set hash',v_actual_hash,'MD5','PASS','Expected, actual, and persisted canonical deposit history reconcile.'),
  (v_run_id,'M1_5_GENERATION_SUMMARY','PORTFOLIO','M1.5 generation summary',v_summary::text,'JSON_TEXT','PASS','Baseline daily deposit and liquidity history generated at the accepted grain.')
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
  metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
  threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

 UPDATE msbf_ctl.run_registry SET run_status='M1_5_GENERATED',
  notes='M1.5 deterministic daily deposit and liquidity history generated. Validation pending.'
 WHERE run_id=v_run_id;
END $do$;

COMMIT;

WITH r AS (
 SELECT run_id,run_status,population_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), h AS (
 SELECT metric_value_text AS stored_hash FROM msbf_ctl.run_evidence
 WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_5_DEPOSIT_SET_HASH' AND segment_key='PORTFOLIO'
)
SELECT r.run_id,r.run_status,r.population_id,
       COUNT(*) AS deposit_rows,COUNT(DISTINCT d.merchant_id) AS merchants,COUNT(DISTINCT d.observation_date) AS dates,
       MIN(d.observation_date) AS minimum_date,MAX(d.observation_date) AS maximum_date,
       SUM(d.deposit_amount) AS deposit_amount,SUM(d.withdrawal_amount) AS withdrawal_amount,
       COUNT(*) FILTER(WHERE d.negative_balance_flag) AS negative_balance_rows,
       SUM(d.nsf_count) AS nsf_events,h.stored_hash
FROM r JOIN msbf_m1.merchant_deposit_daily_base d ON d.generated_by_run_id=r.run_id CROSS JOIN h
GROUP BY r.run_id,r.run_status,r.population_id,h.stored_hash;
