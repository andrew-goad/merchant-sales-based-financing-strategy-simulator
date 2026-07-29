/**********************************************************************
MSBF M1.4 Enterprise Merchant Ecosystem Detail Report
Version : v0.2
Purpose : Multi-result-set evidence for daily POS, settlement, operating
          diversity, deterministic reproduction, and stage acceptance.
**********************************************************************/
BEGIN;

CREATE TEMP TABLE _m1_4_detail_blueprint ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_4_daily_pos_blueprint(
 (SELECT run_id FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE INDEX ON _m1_4_detail_blueprint(merchant_id,observation_date);
CREATE INDEX ON _m1_4_detail_blueprint(industry_code,cashflow_archetype_code);
CREATE INDEX ON _m1_4_detail_blueprint(operating_event_code,processor_status);

/* Result set 1 — Run and acceptance state */
WITH r AS (
 SELECT r.*,p.population_status,p.population_hash,p.history_start_date,p.history_end_date,
        (p.history_end_date-p.history_start_date+1)::integer AS history_days
 FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
)
SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.population_id,r.population_status,
       r.as_of_date,r.history_start_date,r.history_end_date,r.history_days,
       r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,r.population_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') AS application_set_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO') AS pos_history_set_hash,
       g.gate_id,g.review_version,g.result_status,g.reviewed_at,g.finding,g.residual_limitation
FROM r
LEFT JOIN LATERAL (
 SELECT * FROM msbf_ctl.acceptance_gate_result x
 WHERE x.run_id=r.run_id AND x.gate_id='M1_4_DAILY_POS_HISTORY'
 ORDER BY x.review_version DESC LIMIT 1
) g ON true;

/* Result set 2 — Entity and stage-boundary row counts */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT * FROM (VALUES
 ('merchant_master',(SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('merchant_application',(SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('merchant_pos_daily_base',(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))),
 ('merchant_pos_daily_scenario',(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM r))),
 ('merchant_deposit_daily_base',(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))),
 ('merchant_deposit_daily_scenario',(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM r))),
 ('source_snapshot',(SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('application_obligation_snapshot',(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('collateral_availability_snapshot',(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('guarantee_availability_snapshot',(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('application_business_credit_snapshot',(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('application_owner_credit_snapshot',(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('verification_result',(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('merchant_feature_snapshot',(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('merchant_risk_snapshot',(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('ead_path_snapshot',(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('module1_latest',(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))),
 ('module1_archive',(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)))
) q(table_name,row_count) ORDER BY table_name;

/* Result set 3 — Industry operating diagnostics */
SELECT industry_code,COUNT(DISTINCT merchant_id) AS merchants,COUNT(*) AS observation_rows,
       round(SUM(gross_pos_sales),2) AS gross_pos_sales,round(SUM(eligible_pos_sales),2) AS eligible_pos_sales,
       round(AVG(gross_pos_sales),2) AS avg_daily_sales,
       round(percentile_cont(0.5) WITHIN GROUP(ORDER BY gross_pos_sales)::numeric,2) AS median_daily_sales,
       round(AVG(transaction_count),2) AS avg_transactions,
       round(AVG(average_ticket_amount) FILTER(WHERE transaction_count>0),2) AS avg_ticket_on_sales_days,
       round(COUNT(*) FILTER(WHERE zero_sales_day_flag)::numeric/COUNT(*),6) AS zero_sales_share,
       round(SUM(refund_amount)/NULLIF(SUM(gross_pos_sales),0),6) AS refund_rate,
       round(SUM(chargeback_amount)/NULLIF(SUM(gross_pos_sales),0),6) AS chargeback_rate,
       round(SUM(reversal_amount)/NULLIF(SUM(gross_pos_sales),0),6) AS reversal_rate,
       round(SUM(net_merchant_proceeds),2) AS net_merchant_proceeds
FROM _m1_4_detail_blueprint
GROUP BY industry_code ORDER BY industry_code;

/* Result set 4 — Cash-flow archetype diagnostics */
SELECT cashflow_archetype_code,COUNT(DISTINCT merchant_id) AS merchants,COUNT(*) AS observation_rows,
       round(AVG(gross_pos_sales),2) AS avg_daily_sales,
       round(COUNT(*) FILTER(WHERE zero_sales_day_flag)::numeric/COUNT(*),6) AS zero_sales_share,
       round(AVG(trend_factor),6) AS avg_trend_factor,
       round(AVG(volatility_factor),6) AS avg_volatility_factor,
       round(AVG(operating_event_factor),6) AS avg_event_factor,
       COUNT(*) FILTER(WHERE operating_event_code='RECENT_DISRUPTION') AS disruption_rows,
       COUNT(*) FILTER(WHERE operating_event_code='BOUNDED_DEMAND_SHOCK') AS demand_shock_rows,
       COUNT(*) FILTER(WHERE operating_event_code='EXPANSION_STEP_UP') AS expansion_rows
FROM _m1_4_detail_blueprint
GROUP BY cashflow_archetype_code ORDER BY cashflow_archetype_code;

/* Result set 5 — Processor and connection status diagnostics */
SELECT processor_status,data_connection_status,COUNT(*) AS rows,
       COUNT(DISTINCT merchant_id) AS merchants,
       round(COUNT(*)::numeric/(SELECT COUNT(*) FROM _m1_4_detail_blueprint),8) AS portfolio_share,
       round(AVG(gross_pos_sales),2) AS avg_gross_sales,
       round(AVG(settlement_amount),2) AS avg_settlement
FROM _m1_4_detail_blueprint
GROUP BY processor_status,data_connection_status
ORDER BY CASE processor_status WHEN 'ACTIVE' THEN 1 WHEN 'DEGRADED' THEN 2 WHEN 'OUTAGE' THEN 3 ELSE 4 END;

/* Result set 6 — Partner/channel settlement and fee diagnostics */
SELECT p.partner_channel_id,p.channel_type,COUNT(DISTINCT p.merchant_id) AS merchants,
       MIN(p.settlement_delay_days) AS min_settlement_delay,
       MAX(p.settlement_delay_days) AS max_settlement_delay,
       round(AVG(p.processor_fee_rate),6) AS avg_processor_fee_rate,
       round(SUM(b.eligible_pos_sales),2) AS eligible_pos_sales,
       round(SUM(b.settlement_amount),2) AS settlement_amount,
       round(SUM(b.processor_fee_amount),2) AS processor_fee_amount,
       round(SUM(b.net_merchant_proceeds),2) AS net_merchant_proceeds
FROM msbf_m1.m1_4_merchant_operating_profile(
 (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)) p
JOIN _m1_4_detail_blueprint b ON b.merchant_id=p.merchant_id
GROUP BY p.partner_channel_id,p.channel_type
ORDER BY p.partner_channel_id;

/* Result set 7 — Day-of-week and industry pattern */
SELECT industry_code,day_of_week,
       CASE day_of_week WHEN 0 THEN 'SUNDAY' WHEN 1 THEN 'MONDAY' WHEN 2 THEN 'TUESDAY'
            WHEN 3 THEN 'WEDNESDAY' WHEN 4 THEN 'THURSDAY' WHEN 5 THEN 'FRIDAY' ELSE 'SATURDAY' END AS day_name,
       COUNT(*) AS rows,round(AVG(gross_pos_sales),2) AS avg_gross_sales,
       round(COUNT(*) FILTER(WHERE zero_sales_day_flag)::numeric/COUNT(*),6) AS zero_sales_share,
       round(AVG(weekday_factor),6) AS avg_weekday_factor
FROM _m1_4_detail_blueprint
WHERE active_history_flag
GROUP BY industry_code,day_of_week
ORDER BY industry_code,day_of_week;

/* Result set 8 — Calendar and bounded operating-event diagnostics */
SELECT operating_event_code,COUNT(*) AS rows,COUNT(DISTINCT merchant_id) AS merchants,
       MIN(observation_date) AS first_date,MAX(observation_date) AS last_date,
       round(AVG(gross_pos_sales),2) AS avg_gross_sales,
       round(AVG(operating_event_factor),6) AS avg_event_factor,
       round(AVG(holiday_factor),6) AS avg_holiday_factor,
       round(AVG(processor_factor),6) AS avg_processor_factor
FROM _m1_4_detail_blueprint
GROUP BY operating_event_code
ORDER BY CASE operating_event_code WHEN 'NORMAL' THEN 1 WHEN 'CALENDAR_EFFECT' THEN 2
         WHEN 'EXPANSION_STEP_UP' THEN 3 WHEN 'BOUNDED_DEMAND_SHOCK' THEN 4
         WHEN 'RECENT_DISRUPTION' THEN 5 WHEN 'PROCESSOR_DEGRADED' THEN 6
         WHEN 'PROCESSOR_OUTAGE' THEN 7 ELSE 8 END;

/* Result set 9 — Merchant operating-pattern examples */
WITH merchant_rollup AS (
 SELECT merchant_id,industry_code,cashflow_archetype_code,
        round(AVG(gross_pos_sales) FILTER(WHERE calendar_day_index BETWEEN 0 AND 29),2) AS first_30d_avg_sales,
        round(AVG(gross_pos_sales) FILTER(WHERE calendar_day_index BETWEEN 150 AND 179),2) AS last_30d_avg_sales,
        round(AVG(gross_pos_sales),2) AS full_period_avg_sales,
        round(stddev_samp(gross_pos_sales),2) AS daily_sales_stddev,
        round(COUNT(*) FILTER(WHERE zero_sales_day_flag)::numeric/COUNT(*),6) AS zero_sales_share,
        COUNT(*) FILTER(WHERE processor_status='OUTAGE') AS outage_days,
        COUNT(*) FILTER(WHERE operating_event_code IN ('RECENT_DISRUPTION','BOUNDED_DEMAND_SHOCK')) AS stress_event_days,
        COUNT(*) FILTER(WHERE operating_event_code='EXPANSION_STEP_UP') AS expansion_days
 FROM _m1_4_detail_blueprint GROUP BY merchant_id,industry_code,cashflow_archetype_code
), ranked AS (
 SELECT *,row_number() OVER(PARTITION BY cashflow_archetype_code ORDER BY merchant_id) AS archetype_sequence
 FROM merchant_rollup
)
SELECT merchant_id,industry_code,cashflow_archetype_code,first_30d_avg_sales,last_30d_avg_sales,
       full_period_avg_sales,daily_sales_stddev,zero_sales_share,outage_days,stress_event_days,expansion_days
FROM ranked WHERE archetype_sequence<=8
ORDER BY cashflow_archetype_code,merchant_id;

/* Result set 10 — Transaction-quality diagnostics by industry */
SELECT industry_code,
       round(SUM(gross_pos_sales),2) AS gross_pos_sales,
       round(SUM(refund_amount),2) AS refunds,
       round(SUM(chargeback_amount),2) AS chargebacks,
       round(SUM(reversal_amount),2) AS reversals,
       round(SUM(refund_amount)/NULLIF(SUM(gross_pos_sales),0),6) AS refund_rate,
       round(SUM(chargeback_amount)/NULLIF(SUM(gross_pos_sales),0),6) AS chargeback_rate,
       round(SUM(reversal_amount)/NULLIF(SUM(gross_pos_sales),0),6) AS reversal_rate,
       round(SUM(eligible_pos_sales)/NULLIF(SUM(gross_pos_sales),0),6) AS eligible_sales_rate
FROM _m1_4_detail_blueprint
GROUP BY industry_code ORDER BY industry_code;

/* Result set 11 — Settlement-delay reproduction by governed delay */
SELECT p.settlement_delay_days,COUNT(DISTINCT p.merchant_id) AS merchants,COUNT(*) AS observation_rows,
       round(SUM(b.eligible_pos_sales),2) AS eligible_sales_on_observation_dates,
       round(SUM(b.settlement_amount),2) AS settled_from_lagged_dates,
       COUNT(*) FILTER(WHERE b.settlement_source_date=b.observation_date-p.settlement_delay_days) AS correctly_lagged_rows,
       COUNT(*) FILTER(WHERE b.settlement_source_date IS DISTINCT FROM b.observation_date-p.settlement_delay_days) AS lag_violations
FROM msbf_m1.m1_4_merchant_operating_profile(
 (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)) p
JOIN _m1_4_detail_blueprint b ON b.merchant_id=p.merchant_id
GROUP BY p.settlement_delay_days ORDER BY p.settlement_delay_days;

/* Result set 12 — Row-level deterministic mismatches; expected zero rows */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT COALESCE(e.entity_key,a.entity_key) AS entity_key,e.row_hash AS expected_hash,a.row_hash AS actual_hash
FROM msbf_m1.m1_4_expected_pos_snapshot((SELECT run_id FROM r)) e
FULL JOIN msbf_m1.m1_4_actual_pos_snapshot((SELECT run_id FROM r)) a USING(entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash
ORDER BY entity_key;

/* Result set 13 — M1.4 evidence */
SELECT evidence_code,metric_name,status,metric_value_text,interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code LIKE 'M1_4_%'
ORDER BY evidence_code;

/* Result set 14 — Blocking resolution errors; expected zero rows */
SELECT profile_domain,scope_key,error_code,severity,error_message,created_at
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND severity='BLOCKING'
ORDER BY profile_domain,scope_key,error_code;

COMMIT;
