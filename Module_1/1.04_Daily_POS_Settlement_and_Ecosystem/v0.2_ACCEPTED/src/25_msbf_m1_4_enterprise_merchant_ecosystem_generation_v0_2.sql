/* ============================================================================
MSBF M1.4 Enterprise Merchant Ecosystem — Daily POS & Settlement Generation
Version : v0.2
Purpose : Generate deterministic daily merchant operating history across the
          accepted 180-day baseline window, including POS sales, transaction
          quality, processor continuity, settlement timing, and bounded events.
============================================================================ */
BEGIN;

INSERT INTO msbf_ref.acceptance_gate_catalog(gate_id,gate_name,module_code,severity,description)
VALUES('M1_4_DAILY_POS_HISTORY','M1.4 Enterprise Merchant Ecosystem — Daily POS & Settlement History','M1','BLOCKING',
       'Deterministic 180-day POS and settlement history for every accepted merchant, with canonical row-level reproduction and strict stage boundaries.')
ON CONFLICT (gate_id) DO NOTHING;

CREATE OR REPLACE FUNCTION msbf_m1.m1_4_pos_row_hash(
 p_population_id text,p_merchant_id text,p_processor_account_id text,p_observation_date date,
 p_gross_pos_sales numeric,p_transaction_count integer,p_average_ticket_amount numeric,
 p_refund_amount numeric,p_chargeback_amount numeric,p_reversal_amount numeric,
 p_governed_exclusion_amount numeric,p_eligible_pos_sales numeric,p_processor_fee_amount numeric,
 p_settlement_amount numeric,p_net_merchant_proceeds numeric,p_zero_sales_day_flag boolean,
 p_processor_status text,p_data_connection_status text,p_source_contract_id bigint,p_generated_by_run_id bigint)
RETURNS text LANGUAGE sql IMMUTABLE STRICT AS $fn$
SELECT md5(concat_ws('|',
 p_population_id,p_merchant_id,p_processor_account_id,p_observation_date::text,
 to_char(p_gross_pos_sales::numeric(18,2),'FM9999999999999999999990.00'),
 p_transaction_count::text,
 to_char(p_average_ticket_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_refund_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_chargeback_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_reversal_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_governed_exclusion_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_eligible_pos_sales::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_processor_fee_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_settlement_amount::numeric(18,2),'FM9999999999999999999990.00'),
 to_char(p_net_merchant_proceeds::numeric(18,2),'FM9999999999999999999990.00'),
 p_zero_sales_day_flag::text,p_processor_status,p_data_connection_status,
 p_source_contract_id::text,p_generated_by_run_id::text));
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_4_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $fn$
DECLARE
 v_status text; v_population_status text; v_population_id text; v_merchant_count integer;
 v_history_start date; v_history_end date; v_history_days integer;
 v_parameter_hash text; v_profile_hash text; v_source_hash text; v_population_hash text; v_application_hash text;
 v_reparameter text; v_reprofile text; v_resource text; v_repopulation text; v_reapplication text;
 v_g1 text; v_m12 text; v_m13 text; v_merchants bigint; v_apps bigint; v_pos bigint; v_downstream bigint;
 v_required integer; v_resolved integer; v_pos_sources integer; v_errors integer;
BEGIN
 SELECT r.run_status,p.population_status,r.population_id,p.merchant_count,p.history_start_date,p.history_end_date,
        (p.history_end_date-p.history_start_date+1)::integer,
        r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,p.population_hash
 INTO STRICT v_status,v_population_status,v_population_id,v_merchant_count,v_history_start,v_history_end,v_history_days,
             v_parameter_hash,v_profile_hash,v_source_hash,v_population_hash
 FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_id=p_run_id;

 SELECT result_status INTO v_g1 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=p_run_id AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1;
 SELECT result_status INTO v_m12 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=p_run_id AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1;
 SELECT result_status INTO v_m13 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=p_run_id AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1;

 SELECT metric_value_text INTO v_application_hash FROM msbf_ctl.run_evidence
 WHERE run_id=p_run_id AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO';

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

 SELECT COUNT(*) INTO v_merchants FROM msbf_m1.merchant_master WHERE population_id=v_population_id;
 SELECT COUNT(*) INTO v_apps FROM msbf_m1.merchant_application WHERE created_by_run_id=p_run_id;
 SELECT COUNT(*) INTO v_pos FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=p_run_id;
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=p_run_id)
 +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=p_run_id)
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

 WITH required_parameters AS (
   SELECT p.parameter_name,'INDUSTRY:'||i.industry_code AS scope_key
   FROM (VALUES
     ('industry_daily_sales_center'),('industry_daily_sales_log_sigma'),
     ('industry_daily_sales_volatility'),('industry_zero_sales_day_probability'),
     ('industry_seasonality_amplitude'),('industry_weekend_sales_factor'),
     ('industry_average_ticket_center'),('industry_refund_rate_center'),
     ('industry_chargeback_rate_center')
   ) p(parameter_name) CROSS JOIN msbf_ref.industry i
   UNION ALL SELECT 'merchant_growth_rate_center','CASHFLOW_ARCHETYPE:'||archetype_code FROM msbf_ref.cashflow_archetype
   UNION ALL SELECT 'processor_fee_rate',scope_key FROM (VALUES
     ('PARTNER_CHANNEL:PROCESSOR_DIRECT'),('PARTNER_CHANNEL:BANK_RELATIONSHIP'),
     ('PARTNER_CHANNEL:BROKER_REFERRAL'),('PARTNER_CHANNEL:DIGITAL_DIRECT')) s(scope_key)
   UNION ALL SELECT 'reversal_rate_center','GLOBAL'
   UNION ALL SELECT 'merchant_growth_rate_sigma','GLOBAL'
   UNION ALL SELECT 'qa_reconciliation_tolerance_amount','GLOBAL'
 )
 SELECT COUNT(*),COUNT(rps.parameter_name) INTO v_required,v_resolved
 FROM required_parameters req LEFT JOIN msbf_ctl.run_parameter_snapshot rps
 ON rps.run_id=p_run_id AND rps.parameter_name=req.parameter_name AND rps.scope_key=req.scope_key;

 SELECT COUNT(*) INTO v_pos_sources
 FROM msbf_ctl.run_source_snapshot rss JOIN msbf_ctl.source_contract sc ON sc.source_contract_id=rss.source_contract_id
 WHERE rss.run_id=p_run_id AND rss.source_code='POS_DAILY' AND rss.quality_status='CONTRACT_READY_PRE_GENERATION'
   AND sc.source_code='POS_DAILY' AND sc.status='APPROVED';
 SELECT COUNT(*) INTO v_errors FROM msbf_ctl.profile_resolution_error WHERE run_id=p_run_id AND severity='BLOCKING';

 IF v_status<>'M1_3_ACCEPTED' THEN RAISE EXCEPTION 'M1.4 generation requires run_status=M1_3_ACCEPTED; observed %.',v_status; END IF;
 IF v_population_status<>'M1_2_ACCEPTED' THEN RAISE EXCEPTION 'M1.4 requires population_status=M1_2_ACCEPTED; observed %.',v_population_status; END IF;
 IF v_g1 IS DISTINCT FROM 'PASS' OR v_m12 IS DISTINCT FROM 'PASS' OR v_m13 IS DISTINCT FROM 'PASS' THEN
   RAISE EXCEPTION 'M1.4 requires accepted G1, M1.2, and M1.3 gates.';
 END IF;
 IF v_required<>86 OR v_resolved<>86 THEN RAISE EXCEPTION 'M1.4 requires 86 resolved parameter/scope pairs; observed % of %.',v_resolved,v_required; END IF;
 IF v_pos_sources<>1 THEN RAISE EXCEPTION 'M1.4 requires exactly one approved, contract-ready POS_DAILY source snapshot; observed %.',v_pos_sources; END IF;
 IF v_errors<>0 THEN RAISE EXCEPTION 'M1.4 blocking configuration errors exist (% rows).',v_errors; END IF;
 IF v_parameter_hash<>'bd09e598c82db96e47459d77fd11e7c8' OR v_profile_hash<>'462cbd2ed92f68e5bdecf6b17537a973'
    OR v_source_hash<>'93c3d1368fb2450ab4a08e2b721f92d3' OR v_population_hash<>'9b706c926260a3ef1ae8ac95eed5d0bf'
    OR v_application_hash<>'01485256b9b5748fb412743d35ced602' THEN
   RAISE EXCEPTION 'M1.4 accepted upstream hashes do not match the approved baseline.';
 END IF;
 IF v_parameter_hash IS DISTINCT FROM v_reparameter OR v_profile_hash IS DISTINCT FROM v_reprofile
    OR v_source_hash IS DISTINCT FROM v_resource OR v_population_hash IS DISTINCT FROM v_repopulation
    OR v_application_hash IS DISTINCT FROM v_reapplication THEN
   RAISE EXCEPTION 'M1.4 accepted upstream content does not reconcile to stored hashes.';
 END IF;
 IF v_merchant_count<>750 OR v_merchants<>750 OR v_apps<>750 OR v_history_days<>180 THEN
   RAISE EXCEPTION 'M1.4 requires 750 merchants, 750 applications, and 180 days; observed merchants %, applications %, days %.',v_merchants,v_apps,v_history_days;
 END IF;
 IF v_required<>86 OR v_resolved<>86 THEN RAISE EXCEPTION 'M1.4 requires 86 resolved parameter/scope pairs; observed % of %.',v_resolved,v_required; END IF;
 IF v_pos_sources<>1 THEN RAISE EXCEPTION 'M1.4 requires exactly one approved, contract-ready POS_DAILY source snapshot; observed %.',v_pos_sources; END IF;
 IF v_pos<>0 THEN RAISE EXCEPTION 'M1.4 baseline POS rows already exist (% rows); regeneration is prohibited.',v_pos; END IF;
 IF v_downstream<>0 THEN RAISE EXCEPTION 'M1.4 downstream or scenario rows already exist (% rows); generation is prohibited.',v_downstream; END IF;
 IF v_errors<>0 THEN RAISE EXCEPTION 'M1.4 blocking configuration errors exist (% rows).',v_errors; END IF;
END $fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_4_merchant_operating_profile(p_run_id bigint)
RETURNS TABLE(
 run_id bigint,population_id text,merchant_id text,processor_account_id text,partner_channel_id text,channel_type text,
 industry_code text,merchant_size_tier text,annual_sales_band text,relationship_stage text,processor_risk_tier smallint,
 settlement_delay_days smallint,processor_account_open_date date,history_start_date date,history_end_date date,history_days integer,
 cashflow_archetype_code text,industry_daily_sales_center numeric(18,6),merchant_sales_scale_factor numeric(18,8),
 baseline_daily_sales_center numeric(18,6),daily_sales_volatility numeric(12,8),zero_sales_probability numeric(12,8),
 seasonality_amplitude numeric(12,8),weekend_sales_factor numeric(12,8),average_ticket_center numeric(18,6),
 merchant_ticket_scale_factor numeric(12,8),refund_rate_center numeric(12,8),chargeback_rate_center numeric(12,8),
 reversal_rate_center numeric(12,8),refund_rate_multiplier numeric(12,8),chargeback_rate_multiplier numeric(12,8),
 reversal_rate_multiplier numeric(12,8),processor_fee_rate numeric(12,8),annual_growth_rate numeric(12,8),
 seasonality_phase_day integer,disruption_start_date date,disruption_end_date date,disruption_factor numeric(12,8),
 expansion_start_date date,expansion_factor numeric(12,8),general_shock_start_date date,general_shock_end_date date,
 general_shock_factor numeric(12,8))
LANGUAGE sql STABLE AS $fn$
WITH ctx AS (
 SELECT r.run_id,r.population_id,p.history_start_date,p.history_end_date,
        (p.history_end_date-p.history_start_date+1)::integer AS history_days,p.deterministic_seed_version
 FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_id=p_run_id
), industry_params AS (
 SELECT split_part(scope_key,':',2) AS industry_code,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='industry_daily_sales_center') AS sales_center,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='industry_daily_sales_log_sigma') AS sales_log_sigma,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='industry_daily_sales_volatility') AS sales_volatility,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='industry_zero_sales_day_probability') AS zero_probability,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='industry_seasonality_amplitude') AS seasonality_amplitude,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='industry_weekend_sales_factor') AS weekend_factor,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='industry_average_ticket_center') AS ticket_center,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='industry_refund_rate_center') AS refund_center,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='industry_chargeback_rate_center') AS chargeback_center
 FROM msbf_ctl.run_parameter_snapshot
 WHERE run_id=p_run_id AND scope_key LIKE 'INDUSTRY:%'
 GROUP BY split_part(scope_key,':',2)
), growth_params AS (
 SELECT split_part(scope_key,':',2) AS archetype_code,
        max((resolved_value->>'value_numeric')::numeric) AS growth_center
 FROM msbf_ctl.run_parameter_snapshot
 WHERE run_id=p_run_id AND parameter_name='merchant_growth_rate_center' AND scope_key LIKE 'CASHFLOW_ARCHETYPE:%'
 GROUP BY split_part(scope_key,':',2)
), global_params AS (
 SELECT
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='reversal_rate_center' AND scope_key='GLOBAL') AS reversal_center,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='merchant_growth_rate_sigma' AND scope_key='GLOBAL') AS growth_sigma,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='processor_fee_rate' AND scope_key='PARTNER_CHANNEL:PROCESSOR_DIRECT') AS fee_processor,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='processor_fee_rate' AND scope_key='PARTNER_CHANNEL:BANK_RELATIONSHIP') AS fee_bank,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='processor_fee_rate' AND scope_key='PARTNER_CHANNEL:BROKER_REFERRAL') AS fee_broker,
  max((resolved_value->>'value_numeric')::numeric) FILTER(WHERE parameter_name='processor_fee_rate' AND scope_key='PARTNER_CHANNEL:DIGITAL_DIRECT') AS fee_digital
 FROM msbf_ctl.run_parameter_snapshot WHERE run_id=p_run_id
), base AS (
 SELECT ctx.*,m.merchant_id,m.merchant_size_tier,m.annual_sales_band,i.industry_code,
        pa.processor_account_id,pa.partner_channel_id,pc.channel_type,pa.processor_risk_tier,pa.settlement_delay_days,
        pa.processor_account_open_date,rel.relationship_stage,rel.prior_default_flag,rel.prior_payment_interruption_flag,
        ip.sales_center,ip.sales_log_sigma,ip.sales_volatility,ip.zero_probability,ip.seasonality_amplitude,
        ip.weekend_factor,ip.ticket_center,ip.refund_center,ip.chargeback_center,
        gp.reversal_center,gp.growth_sigma,gp.fee_processor,gp.fee_bank,gp.fee_broker,gp.fee_digital,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_4:ARCHETYPE') AS u_archetype,
        msbf_ctl.deterministic_normal(m.merchant_id,ctx.deterministic_seed_version||':M1_4:SALES_SCALE') AS z_sales_scale,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_4:SALES_SCALE_JITTER') AS u_scale_jitter,
        msbf_ctl.deterministic_normal(m.merchant_id,ctx.deterministic_seed_version||':M1_4:TICKET_SCALE') AS z_ticket_scale,
        msbf_ctl.deterministic_normal(m.merchant_id,ctx.deterministic_seed_version||':M1_4:GROWTH') AS z_growth,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_4:SEASON_PHASE') AS u_phase,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_4:REFUND_MULT') AS u_refund,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_4:CHARGEBACK_MULT') AS u_chargeback,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_4:REVERSAL_MULT') AS u_reversal,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_4:EVENT_TYPE') AS u_event_type,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_4:EVENT_START') AS u_event_start,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_4:EVENT_LENGTH') AS u_event_length,
        msbf_ctl.deterministic_uniform(m.merchant_id,ctx.deterministic_seed_version||':M1_4:EVENT_SEVERITY') AS u_event_severity
 FROM ctx
 JOIN msbf_m1.merchant_master m ON m.population_id=ctx.population_id
 JOIN msbf_m1.merchant_industry_assignment i ON i.merchant_id=m.merchant_id AND i.assignment_type='PRIMARY' AND i.created_by_run_id=ctx.run_id
 JOIN msbf_m1.processor_account pa ON pa.merchant_id=m.merchant_id AND pa.created_by_run_id=ctx.run_id
 JOIN msbf_m1.partner_channel pc ON pc.partner_channel_id=pa.partner_channel_id AND pc.created_by_run_id=ctx.run_id
 JOIN msbf_m1.merchant_relationship_snapshot rel ON rel.merchant_id=m.merchant_id AND rel.as_of_date=ctx.history_end_date AND rel.created_by_run_id=ctx.run_id
 JOIN industry_params ip ON ip.industry_code=i.industry_code
 CROSS JOIN global_params gp
), archetyped AS (
 SELECT b.*,
  CASE
   WHEN b.processor_account_open_date>b.history_start_date THEN 'THIN_HISTORY'
   WHEN b.prior_default_flag OR (b.prior_payment_interruption_flag AND b.u_archetype<0.82) THEN 'RECENT_DISRUPTION'
   WHEN b.relationship_stage='RETURNING_MIXED' AND b.u_archetype<0.48 THEN 'DECLINING'
   WHEN b.seasonality_amplitude>=0.18 AND b.u_archetype<0.40 THEN 'SEASONAL'
   WHEN b.sales_volatility>=0.50 AND b.u_archetype<0.55 THEN 'VOLATILE'
   WHEN b.relationship_stage='RETURNING_GOOD' AND b.u_archetype<0.50 THEN 'GROWING'
   WHEN b.u_archetype<0.14 THEN 'GROWING'
   WHEN b.u_archetype<0.22 THEN 'DECLINING'
   WHEN b.u_archetype<0.34 THEN 'SEASONAL'
   WHEN b.u_archetype<0.46 THEN 'VOLATILE'
   ELSE 'STABLE' END AS archetype_code
 FROM base b
), enriched AS (
 SELECT a.*,g.growth_center,
  CASE a.annual_sales_band WHEN 'UNDER_250K' THEN 0.35 WHEN '250K_TO_1M' THEN 0.75
       WHEN '1M_TO_5M' THEN 1.60 ELSE 3.20 END AS size_factor,
  CASE a.relationship_stage WHEN 'RETURNING_GOOD' THEN 1.08 WHEN 'RETURNING_MIXED' THEN 0.93
       WHEN 'LOW_AND_GROW' THEN 0.85 ELSE 1.00 END AS relationship_factor,
  CASE a.channel_type WHEN 'PROCESSOR_DIRECT' THEN a.fee_processor WHEN 'BANK_RELATIONSHIP' THEN a.fee_bank
       WHEN 'DIGITAL_DIRECT' THEN a.fee_digital WHEN 'STRATEGIC_PARTNER' THEN (a.fee_processor+a.fee_digital)/2
       ELSE a.fee_broker END AS fee_rate
 FROM archetyped a JOIN growth_params g ON g.archetype_code=a.archetype_code
), calc AS (
 SELECT e.*,
  least(8.00000000,greatest(0.10000000,
    e.size_factor*e.relationship_factor*exp(e.sales_log_sigma*e.z_sales_scale-0.5*power(e.sales_log_sigma,2))*(0.92+0.16*e.u_scale_jitter))) AS sales_scale,
  least(2.50000000,greatest(0.40000000,exp(0.28*e.z_ticket_scale-0.5*power(0.28,2)))) AS ticket_scale,
  least(0.75000000,greatest(-0.75000000,e.growth_center+e.growth_sigma*e.z_growth*0.35)) AS growth_rate,
  floor(e.u_phase*365)::integer AS phase_day,
  (e.history_end_date-(5+floor(e.u_event_start*35)::integer))::date AS recent_start,
  (e.history_start_date+floor((e.history_days-10)*e.u_event_start)::integer)::date AS shock_start,
  (e.history_start_date+floor(e.history_days*(0.45+0.30*e.u_event_start))::integer)::date AS expand_start
 FROM enriched e
)
SELECT
 c.run_id,c.population_id,c.merchant_id,c.processor_account_id,c.partner_channel_id,c.channel_type,c.industry_code,
 c.merchant_size_tier,c.annual_sales_band,c.relationship_stage,c.processor_risk_tier,c.settlement_delay_days,
 c.processor_account_open_date,c.history_start_date,c.history_end_date,c.history_days,c.archetype_code,
 c.sales_center::numeric(18,6),c.sales_scale::numeric(18,8),(c.sales_center*c.sales_scale)::numeric(18,6),
 c.sales_volatility::numeric(12,8),c.zero_probability::numeric(12,8),c.seasonality_amplitude::numeric(12,8),
 c.weekend_factor::numeric(12,8),c.ticket_center::numeric(18,6),c.ticket_scale::numeric(12,8),
 c.refund_center::numeric(12,8),c.chargeback_center::numeric(12,8),c.reversal_center::numeric(12,8),
 (0.70+0.60*c.u_refund)::numeric(12,8),(0.70+0.60*c.u_chargeback)::numeric(12,8),
 (0.75+0.50*c.u_reversal)::numeric(12,8),c.fee_rate::numeric(12,8),c.growth_rate::numeric(12,8),c.phase_day,
 CASE WHEN c.archetype_code='RECENT_DISRUPTION' THEN c.recent_start END,
 CASE WHEN c.archetype_code='RECENT_DISRUPTION' THEN least(c.history_end_date,(c.recent_start+4+floor(c.u_event_length*8)::integer)::date) END,
 CASE WHEN c.archetype_code='RECENT_DISRUPTION' THEN (0.15+0.40*c.u_event_severity)::numeric(12,8) ELSE 1.00000000::numeric(12,8) END,
 CASE WHEN c.archetype_code='GROWING' THEN c.expand_start END,
 CASE WHEN c.archetype_code='GROWING' THEN (1.10+0.20*c.u_event_severity)::numeric(12,8) ELSE 1.00000000::numeric(12,8) END,
 CASE WHEN c.archetype_code<>'RECENT_DISRUPTION' AND c.u_event_type<0.10 THEN c.shock_start END,
 CASE WHEN c.archetype_code<>'RECENT_DISRUPTION' AND c.u_event_type<0.10 THEN least(c.history_end_date,(c.shock_start+2+floor(c.u_event_length*5)::integer)::date) END,
 CASE WHEN c.archetype_code<>'RECENT_DISRUPTION' AND c.u_event_type<0.10 THEN (0.55+0.30*c.u_event_severity)::numeric(12,8) ELSE 1.00000000::numeric(12,8) END
FROM calc c;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_4_daily_pos_blueprint(p_run_id bigint)
RETURNS TABLE(
 population_id text,merchant_id text,processor_account_id text,observation_date date,
 gross_pos_sales numeric(18,2),transaction_count integer,average_ticket_amount numeric(18,2),
 refund_amount numeric(18,2),chargeback_amount numeric(18,2),reversal_amount numeric(18,2),
 governed_exclusion_amount numeric(18,2),eligible_pos_sales numeric(18,2),processor_fee_amount numeric(18,2),
 settlement_amount numeric(18,2),net_merchant_proceeds numeric(18,2),zero_sales_day_flag boolean,
 processor_status text,data_connection_status text,source_contract_id bigint,generated_by_run_id bigint,row_hash text,
 industry_code text,cashflow_archetype_code text,calendar_day_index integer,day_of_week integer,
 weekday_factor numeric(12,8),seasonality_factor numeric(12,8),trend_factor numeric(12,8),
 volatility_factor numeric(12,8),holiday_factor numeric(12,8),processor_factor numeric(12,8),
 operating_event_code text,operating_event_factor numeric(12,8),settlement_source_date date,
 processor_fee_rate numeric(12,8),active_history_flag boolean)
LANGUAGE sql STABLE AS $fn$
WITH ctx AS (
 SELECT r.run_id,r.population_id,p.history_start_date,p.history_end_date,
        (p.history_end_date-p.history_start_date+1)::integer AS history_days,p.deterministic_seed_version,
        (SELECT rss.source_contract_id FROM msbf_ctl.run_source_snapshot rss
          WHERE rss.run_id=r.run_id AND rss.source_code='POS_DAILY') AS source_contract_id,
        (SELECT max(pa.settlement_delay_days)::integer FROM msbf_m1.processor_account pa WHERE pa.created_by_run_id=r.run_id) AS max_delay
 FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_id=p_run_id
), profile AS (
 SELECT * FROM msbf_m1.m1_4_merchant_operating_profile(p_run_id)
), dates AS (
 SELECT gs::date AS observation_date
 FROM ctx,generate_series(ctx.history_start_date-ctx.max_delay,ctx.history_end_date,interval '1 day') gs
), grid AS (
 SELECT p.*,d.observation_date,
        (d.observation_date-p.history_start_date)::integer AS calendar_day_index,
        extract(dow from d.observation_date)::integer AS day_of_week,
        extract(doy from d.observation_date)::integer AS day_of_year,
        d.observation_date>=p.processor_account_open_date AS active_history_flag,
        msbf_ctl.deterministic_uniform(p.merchant_id||'|'||d.observation_date,pop.deterministic_seed_version||':M1_4:ZERO') AS u_zero,
        msbf_ctl.deterministic_uniform(p.merchant_id||'|'||d.observation_date,pop.deterministic_seed_version||':M1_4:PROCESSOR') AS u_processor,
        msbf_ctl.deterministic_normal(p.merchant_id||'|'||d.observation_date,pop.deterministic_seed_version||':M1_4:SALES_NOISE') AS z_sales,
        msbf_ctl.deterministic_normal(p.merchant_id||'|'||d.observation_date,pop.deterministic_seed_version||':M1_4:TICKET_NOISE') AS z_ticket,
        msbf_ctl.deterministic_uniform(p.merchant_id||'|'||d.observation_date,pop.deterministic_seed_version||':M1_4:REFUND_DAY') AS u_refund_day,
        msbf_ctl.deterministic_uniform(p.merchant_id||'|'||d.observation_date,pop.deterministic_seed_version||':M1_4:CHARGEBACK_DAY') AS u_chargeback_day,
        msbf_ctl.deterministic_uniform(p.merchant_id||'|'||d.observation_date,pop.deterministic_seed_version||':M1_4:REVERSAL_DAY') AS u_reversal_day
 FROM profile p CROSS JOIN dates d
 JOIN msbf_m1.population_registry pop ON pop.population_id=p.population_id
), factors AS (
 SELECT g.*,
  CASE WHEN g.day_of_week IN (0,6) THEN g.weekend_sales_factor
       WHEN g.day_of_week=1 THEN 0.90 WHEN g.day_of_week=2 THEN 0.96 WHEN g.day_of_week=3 THEN 1.00
       WHEN g.day_of_week=4 THEN 1.05 ELSE 1.10 END::numeric AS weekday_factor_raw,
  greatest(0.25,1+g.seasonality_amplitude*sin(2*pi()*mod(g.day_of_year+g.seasonality_phase_day,365)/365.0))::numeric AS seasonality_factor_raw,
  exp(g.annual_growth_rate*((g.observation_date-g.history_start_date)::numeric/365.0))::numeric AS trend_factor_raw,
  exp(sqrt(ln(1+power(g.daily_sales_volatility,2)))*g.z_sales
      -0.5*power(sqrt(ln(1+power(g.daily_sales_volatility,2))),2))::numeric AS volatility_factor_raw,
  CASE
   WHEN g.observation_date=DATE '2026-02-14' THEN CASE g.industry_code
      WHEN 'RESTAURANT_FOOD_SERVICE' THEN 1.35 WHEN 'GENERAL_RETAIL' THEN 1.15 WHEN 'ECOMMERCE_DIGITAL' THEN 1.12 ELSE 1.00 END
   WHEN g.observation_date=DATE '2026-05-25' THEN CASE g.industry_code
      WHEN 'RESTAURANT_FOOD_SERVICE' THEN 1.12 WHEN 'GENERAL_RETAIL' THEN 1.08
      WHEN 'PROFESSIONAL_SERVICES' THEN 0.40 WHEN 'CONSTRUCTION_TRADES' THEN 0.55
      WHEN 'HEALTHCARE_SERVICES' THEN 0.60 ELSE 0.90 END
   WHEN g.observation_date=DATE '2026-07-04' THEN CASE g.industry_code
      WHEN 'RESTAURANT_FOOD_SERVICE' THEN 1.20 WHEN 'GENERAL_RETAIL' THEN 1.10 WHEN 'ECOMMERCE_DIGITAL' THEN 1.08
      WHEN 'PROFESSIONAL_SERVICES' THEN 0.25 WHEN 'CONSTRUCTION_TRADES' THEN 0.25
      WHEN 'HEALTHCARE_SERVICES' THEN 0.45 ELSE 0.75 END
   ELSE 1.00 END::numeric AS holiday_factor_raw,
  CASE WHEN NOT g.active_history_flag THEN 0.00
       WHEN g.u_processor<(0.0005+0.0015*(g.processor_risk_tier-1)) THEN 0.00
       WHEN g.u_processor<(0.0040+0.0045*(g.processor_risk_tier-1)) THEN 0.70
       ELSE 1.00 END::numeric AS processor_factor_raw,
  least(0.98,greatest(0.00,g.zero_sales_probability
       *CASE g.cashflow_archetype_code WHEN 'STABLE' THEN 0.80 WHEN 'GROWING' THEN 0.70 WHEN 'VOLATILE' THEN 1.20
              WHEN 'DECLINING' THEN 1.30 WHEN 'RECENT_DISRUPTION' THEN 1.40 ELSE 1.00 END
       *CASE WHEN g.day_of_week IN (0,6) AND g.weekend_sales_factor<0.70 THEN 2.00
             WHEN g.day_of_week IN (0,6) AND g.weekend_sales_factor>1.05 THEN 0.70 ELSE 1.00 END))::numeric AS adjusted_zero_probability,
  CASE WHEN g.disruption_start_date IS NOT NULL AND g.observation_date BETWEEN g.disruption_start_date AND g.disruption_end_date
       THEN g.disruption_factor ELSE 1.00 END
  *CASE WHEN g.general_shock_start_date IS NOT NULL AND g.observation_date BETWEEN g.general_shock_start_date AND g.general_shock_end_date
       THEN g.general_shock_factor ELSE 1.00 END
  *CASE WHEN g.expansion_start_date IS NOT NULL AND g.observation_date>=g.expansion_start_date
       THEN g.expansion_factor ELSE 1.00 END AS event_factor_raw,
  CASE WHEN NOT g.active_history_flag THEN 'PRE_OPEN'
       WHEN g.u_processor<(0.0005+0.0015*(g.processor_risk_tier-1)) THEN 'PROCESSOR_OUTAGE'
       WHEN g.u_processor<(0.0040+0.0045*(g.processor_risk_tier-1)) THEN 'PROCESSOR_DEGRADED'
       WHEN g.disruption_start_date IS NOT NULL AND g.observation_date BETWEEN g.disruption_start_date AND g.disruption_end_date THEN 'RECENT_DISRUPTION'
       WHEN g.general_shock_start_date IS NOT NULL AND g.observation_date BETWEEN g.general_shock_start_date AND g.general_shock_end_date THEN 'BOUNDED_DEMAND_SHOCK'
       WHEN g.expansion_start_date IS NOT NULL AND g.observation_date>=g.expansion_start_date THEN 'EXPANSION_STEP_UP'
       WHEN g.observation_date IN (DATE '2026-02-14',DATE '2026-05-25',DATE '2026-07-04') THEN 'CALENDAR_EFFECT'
       ELSE 'NORMAL' END AS operating_event_code
 FROM grid g
), statused AS (
 SELECT f.*,
  CASE WHEN NOT f.active_history_flag THEN 'NOT_YET_ACTIVE'
       WHEN f.processor_factor_raw=0 THEN 'OUTAGE'
       WHEN f.processor_factor_raw<1 THEN 'DEGRADED' ELSE 'ACTIVE' END AS processor_status_calc,
  CASE WHEN NOT f.active_history_flag THEN 'NOT_CONNECTED'
       WHEN f.processor_factor_raw=0 THEN 'DISCONNECTED'
       WHEN f.processor_factor_raw<1 THEN 'DELAYED' ELSE 'CONNECTED' END AS connection_status_calc,
  CASE WHEN NOT f.active_history_flag OR f.processor_factor_raw=0 OR f.u_zero<f.adjusted_zero_probability THEN true ELSE false END AS zero_flag
 FROM factors f
), grossed AS (
 SELECT s.*,
  CASE WHEN s.zero_flag THEN 0.00::numeric
       ELSE round(least(2000000.00,greatest(0.00,
        s.baseline_daily_sales_center*s.weekday_factor_raw*s.seasonality_factor_raw*s.trend_factor_raw*
        s.volatility_factor_raw*s.holiday_factor_raw*s.processor_factor_raw*s.event_factor_raw))::numeric,2) END::numeric(18,2) AS gross_sales,
  least(50000.00,greatest(5.00,s.average_ticket_center*s.merchant_ticket_scale_factor*
       exp(0.18*s.z_ticket-0.5*power(0.18,2))))::numeric AS ticket_raw
 FROM statused s
), transacted AS (
 SELECT g.*,
  CASE WHEN g.gross_sales=0 THEN 0 ELSE greatest(1,round(g.gross_sales/g.ticket_raw)::integer) END AS txn_count
 FROM grossed g
), quality AS (
 SELECT t.*,
  CASE WHEN t.txn_count=0 THEN 0.00 ELSE round(t.gross_sales/t.txn_count,2) END::numeric(18,2) AS avg_ticket,
  least(0.25,greatest(0.00,t.refund_rate_center*t.refund_rate_multiplier*(0.75+0.50*t.u_refund_day)
       *CASE t.cashflow_archetype_code WHEN 'RECENT_DISRUPTION' THEN 1.15 WHEN 'VOLATILE' THEN 1.10 ELSE 1.00 END)) AS refund_rate,
  least(0.10,greatest(0.00,t.chargeback_rate_center*t.chargeback_rate_multiplier*(0.75+0.50*t.u_chargeback_day)
       *CASE t.cashflow_archetype_code WHEN 'RECENT_DISRUPTION' THEN 1.20 WHEN 'VOLATILE' THEN 1.10 ELSE 1.00 END)) AS chargeback_rate,
  least(0.05,greatest(0.00,t.reversal_rate_center*t.reversal_rate_multiplier*(0.75+0.50*t.u_reversal_day))) AS reversal_rate
 FROM transacted t
), amounts AS (
 SELECT q.*,
  round(q.gross_sales*q.refund_rate,2)::numeric(18,2) AS refund_amt,
  round(q.gross_sales*q.chargeback_rate,2)::numeric(18,2) AS chargeback_amt,
  round(q.gross_sales*q.reversal_rate,2)::numeric(18,2) AS reversal_amt
 FROM quality q
), eligible AS (
 SELECT a.*,
  greatest(a.gross_sales-a.refund_amt-a.chargeback_amt-a.reversal_amt,0.00)::numeric(18,2) AS eligible_sales
 FROM amounts a
), settled AS (
 SELECT curr.*,
        (curr.observation_date-curr.settlement_delay_days)::date AS settlement_source_date_calc,
        coalesce(prior.eligible_sales,0.00)::numeric(18,2) AS settlement_amt
 FROM eligible curr
 LEFT JOIN eligible prior
   ON prior.merchant_id=curr.merchant_id
  AND prior.processor_account_id=curr.processor_account_id
  AND prior.observation_date=(curr.observation_date-curr.settlement_delay_days)::date
), final_rows AS (
 SELECT s.population_id,s.merchant_id,s.processor_account_id,s.observation_date,
        s.gross_sales::numeric(18,2) AS gross_pos_sales,s.txn_count::integer AS transaction_count,s.avg_ticket::numeric(18,2) AS average_ticket_amount,
        s.refund_amt::numeric(18,2) AS refund_amount,s.chargeback_amt::numeric(18,2) AS chargeback_amount,
        s.reversal_amt::numeric(18,2) AS reversal_amount,0.00::numeric(18,2) AS governed_exclusion_amount,
        s.eligible_sales::numeric(18,2) AS eligible_pos_sales,
        round(s.settlement_amt*s.processor_fee_rate,2)::numeric(18,2) AS processor_fee_amount,
        s.settlement_amt::numeric(18,2) AS settlement_amount,
        (s.settlement_amt-round(s.settlement_amt*s.processor_fee_rate,2))::numeric(18,2) AS net_merchant_proceeds,
        s.zero_flag AS zero_sales_day_flag,s.processor_status_calc AS processor_status,s.connection_status_calc AS data_connection_status,
        ctx.source_contract_id,s.run_id AS generated_by_run_id,s.industry_code,s.cashflow_archetype_code,
        s.calendar_day_index,s.day_of_week,s.weekday_factor_raw::numeric(12,8) AS weekday_factor,
        s.seasonality_factor_raw::numeric(12,8) AS seasonality_factor,s.trend_factor_raw::numeric(12,8) AS trend_factor,
        s.volatility_factor_raw::numeric(12,8) AS volatility_factor,s.holiday_factor_raw::numeric(12,8) AS holiday_factor,
        s.processor_factor_raw::numeric(12,8) AS processor_factor,s.operating_event_code,
        s.event_factor_raw::numeric(12,8) AS operating_event_factor,s.settlement_source_date_calc AS settlement_source_date,
        s.processor_fee_rate::numeric(12,8),s.active_history_flag
 FROM settled s CROSS JOIN ctx
 WHERE s.observation_date BETWEEN ctx.history_start_date AND ctx.history_end_date
)
SELECT
 f.population_id,f.merchant_id,f.processor_account_id,f.observation_date,
 f.gross_pos_sales,f.transaction_count,f.average_ticket_amount,f.refund_amount,f.chargeback_amount,f.reversal_amount,
 f.governed_exclusion_amount,f.eligible_pos_sales,f.processor_fee_amount,f.settlement_amount,f.net_merchant_proceeds,
 f.zero_sales_day_flag,f.processor_status,f.data_connection_status,f.source_contract_id,f.generated_by_run_id,
 msbf_m1.m1_4_pos_row_hash(f.population_id,f.merchant_id,f.processor_account_id,f.observation_date,
  f.gross_pos_sales,f.transaction_count,f.average_ticket_amount,f.refund_amount,f.chargeback_amount,f.reversal_amount,
  f.governed_exclusion_amount,f.eligible_pos_sales,f.processor_fee_amount,f.settlement_amount,f.net_merchant_proceeds,
  f.zero_sales_day_flag,f.processor_status,f.data_connection_status,f.source_contract_id,f.generated_by_run_id) AS row_hash,
 f.industry_code,f.cashflow_archetype_code,f.calendar_day_index,f.day_of_week,f.weekday_factor,
 f.seasonality_factor,f.trend_factor,f.volatility_factor,f.holiday_factor,f.processor_factor,
 f.operating_event_code,f.operating_event_factor,f.settlement_source_date,f.processor_fee_rate,f.active_history_flag
FROM final_rows f;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_4_expected_pos_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text) LANGUAGE sql STABLE AS $fn$
SELECT merchant_id||'|'||processor_account_id||'|'||observation_date::text,row_hash
FROM msbf_m1.m1_4_daily_pos_blueprint(p_run_id)
ORDER BY merchant_id,processor_account_id,observation_date;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_4_actual_pos_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text) LANGUAGE sql STABLE AS $fn$
SELECT p.merchant_id||'|'||p.processor_account_id||'|'||p.observation_date::text,
 msbf_m1.m1_4_pos_row_hash(p.population_id,p.merchant_id,p.processor_account_id,p.observation_date,
  p.gross_pos_sales,p.transaction_count,p.average_ticket_amount,p.refund_amount,p.chargeback_amount,p.reversal_amount,
  p.governed_exclusion_amount,p.eligible_pos_sales,p.processor_fee_amount,p.settlement_amount,p.net_merchant_proceeds,
  p.zero_sales_day_flag,p.processor_status,p.data_connection_status,p.source_contract_id,p.generated_by_run_id)
FROM msbf_m1.merchant_pos_daily_base p
WHERE p.generated_by_run_id=p_run_id
ORDER BY p.merchant_id,p.processor_account_id,p.observation_date;
$fn$;

DO $do$
DECLARE v_run_id bigint;
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 PERFORM msbf_m1.m1_4_assert_generation_ready(v_run_id);
END $do$;

CREATE TEMP TABLE _m1_4_blueprint ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_4_daily_pos_blueprint(
 (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE INDEX ON _m1_4_blueprint(merchant_id,processor_account_id,observation_date);

DO $do$
DECLARE v_rows bigint; v_merchants bigint; v_dates bigint;
BEGIN
 SELECT COUNT(*),COUNT(DISTINCT merchant_id),COUNT(DISTINCT observation_date)
 INTO v_rows,v_merchants,v_dates FROM _m1_4_blueprint;
 IF v_rows<>135000 OR v_merchants<>750 OR v_dates<>180 THEN
   RAISE EXCEPTION 'M1.4 blueprint cardinality mismatch: rows %, merchants %, dates %.',v_rows,v_merchants,v_dates;
 END IF;
END $do$;

INSERT INTO msbf_m1.merchant_pos_daily_base(
 population_id,merchant_id,processor_account_id,observation_date,gross_pos_sales,transaction_count,
 average_ticket_amount,refund_amount,chargeback_amount,reversal_amount,governed_exclusion_amount,
 eligible_pos_sales,processor_fee_amount,settlement_amount,net_merchant_proceeds,zero_sales_day_flag,
 processor_status,data_connection_status,source_contract_id,generated_by_run_id,row_hash)
SELECT population_id,merchant_id,processor_account_id,observation_date,gross_pos_sales,transaction_count,
 average_ticket_amount,refund_amount,chargeback_amount,reversal_amount,governed_exclusion_amount,
 eligible_pos_sales,processor_fee_amount,settlement_amount,net_merchant_proceeds,zero_sales_day_flag,
 processor_status,data_connection_status,source_contract_id,generated_by_run_id,row_hash
FROM _m1_4_blueprint
ORDER BY merchant_id,observation_date;

DO $do$
DECLARE v_run_id bigint; v_expected_rows bigint; v_actual_rows bigint; v_mismatches bigint;
        v_expected_hash text; v_actual_hash text; v_spec jsonb; v_summary jsonb;
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;

 SELECT COUNT(*),md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
 INTO v_expected_rows,v_expected_hash FROM msbf_m1.m1_4_expected_pos_snapshot(v_run_id);
 SELECT COUNT(*),md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
 INTO v_actual_rows,v_actual_hash FROM msbf_m1.m1_4_actual_pos_snapshot(v_run_id);
 SELECT COUNT(*) INTO v_mismatches
 FROM msbf_m1.m1_4_expected_pos_snapshot(v_run_id) e
 FULL JOIN msbf_m1.m1_4_actual_pos_snapshot(v_run_id) a USING(entity_key)
 WHERE e.row_hash IS DISTINCT FROM a.row_hash;

 IF v_expected_rows<>135000 OR v_actual_rows<>135000 OR v_mismatches<>0 OR v_expected_hash IS DISTINCT FROM v_actual_hash THEN
   RAISE EXCEPTION 'M1.4 persisted POS history does not match regenerated blueprint: expected rows %, actual %, mismatches %, expected hash %, actual hash %.',
     v_expected_rows,v_actual_rows,v_mismatches,v_expected_hash,v_actual_hash;
 END IF;

 v_spec:=jsonb_build_object(
  'stage','M1.4','stage_name','Enterprise Merchant Ecosystem — Daily POS & Settlement History',
  'code_version','M1_4_ECOSYSTEM_V1','history_days',180,'expected_rows',135000,
  'generation_grain','merchant|processor_account|calendar_date',
  'sales_method','industry center x merchant scale x weekday x seasonality x trend x volatility x bounded events x processor continuity',
  'settlement_method','eligible sales shifted by processor settlement-delay days',
  'quality_method','industry refund and chargeback centers plus deterministic merchant and daily variation',
  'holiday_dates',jsonb_build_array('2026-02-14','2026-05-25','2026-07-04'),
  'processor_statuses',jsonb_build_array('NOT_YET_ACTIVE','ACTIVE','DEGRADED','OUTAGE'),
  'data_connection_statuses',jsonb_build_array('NOT_CONNECTED','CONNECTED','DELAYED','DISCONNECTED'),
  'baseline_governed_exclusion_amount','0.00','scenario_rows_generated',false,'deposit_rows_generated',false,
  'production_boundary','Synthetic demonstration history; not merchant data, forecast, calibrated risk evidence, or production servicing data.');

 SELECT jsonb_build_object(
  'rows',COUNT(*),'merchants',COUNT(DISTINCT merchant_id),'dates',COUNT(DISTINCT observation_date),
  'gross_sales',SUM(gross_pos_sales),'eligible_sales',SUM(eligible_pos_sales),'settlements',SUM(settlement_amount),
  'zero_sales_rows',COUNT(*) FILTER(WHERE zero_sales_day_flag),
  'outage_rows',COUNT(*) FILTER(WHERE processor_status='OUTAGE'),
  'degraded_rows',COUNT(*) FILTER(WHERE processor_status='DEGRADED'),
  'pre_open_rows',COUNT(*) FILTER(WHERE processor_status='NOT_YET_ACTIVE'),
  'population_hash',v_actual_hash)
 INTO v_summary FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=v_run_id;

 INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
 VALUES
  (v_run_id,'M1_4_GENERATION_SPEC','PORTFOLIO','M1.4 generation specification',v_spec::text,'JSON_TEXT','PASS','Code-owned deterministic ecosystem assumptions and stage boundaries.'),
  (v_run_id,'M1_4_GENERATION_SPEC_HASH','PORTFOLIO','M1.4 generation specification hash',md5(v_spec::text),'MD5','PASS','Hash of the canonical M1.4 generation specification.'),
  (v_run_id,'M1_4_POS_SET_HASH','PORTFOLIO','M1.4 POS-history set hash',v_actual_hash,'MD5','PASS','Expected, actual, and persisted canonical history reconcile.'),
  (v_run_id,'M1_4_GENERATION_SUMMARY','PORTFOLIO','M1.4 generation summary',v_summary::text,'JSON_TEXT','PASS','Baseline daily POS and settlement history generated at the accepted grain.')
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
  metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
  threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

 UPDATE msbf_ctl.run_registry SET run_status='M1_4_GENERATED',
  notes='M1.4 deterministic enterprise merchant ecosystem history generated. Validation pending.'
 WHERE run_id=v_run_id;
END $do$;

COMMIT;

WITH r AS (
 SELECT run_id,run_status,population_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), h AS (
 SELECT metric_value_text AS stored_hash FROM msbf_ctl.run_evidence
 WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO'
)
SELECT r.run_id,r.run_status,r.population_id,
       COUNT(*) AS pos_rows,COUNT(DISTINCT p.merchant_id) AS merchants,COUNT(DISTINCT p.observation_date) AS dates,
       MIN(p.observation_date) AS minimum_date,MAX(p.observation_date) AS maximum_date,
       SUM(p.gross_pos_sales) AS gross_pos_sales,SUM(p.eligible_pos_sales) AS eligible_pos_sales,
       SUM(p.settlement_amount) AS settlement_amount,
       COUNT(*) FILTER(WHERE p.zero_sales_day_flag) AS zero_sales_rows,
       COUNT(*) FILTER(WHERE p.processor_status='OUTAGE') AS outage_rows,
       COUNT(*) FILTER(WHERE p.processor_status='DEGRADED') AS degraded_rows,
       COUNT(*) FILTER(WHERE p.processor_status='NOT_YET_ACTIVE') AS pre_open_rows,
       h.stored_hash
FROM r JOIN msbf_m1.merchant_pos_daily_base p ON p.generated_by_run_id=r.run_id CROSS JOIN h
GROUP BY r.run_id,r.run_status,r.population_id,h.stored_hash;
