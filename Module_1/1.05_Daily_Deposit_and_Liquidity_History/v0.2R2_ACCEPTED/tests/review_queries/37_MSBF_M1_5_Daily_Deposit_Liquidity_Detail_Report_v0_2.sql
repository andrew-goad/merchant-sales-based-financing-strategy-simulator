/**********************************************************************
MSBF M1.5 Daily Deposit & Liquidity History Detail Report
Version : v0.2
Purpose : Multi-result-set evidence for accepted baseline liquidity history.
**********************************************************************/
BEGIN;

CREATE TEMP TABLE _m1_5_detail_blueprint ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_5_daily_liquidity_blueprint(
 (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE INDEX ON _m1_5_detail_blueprint(merchant_id,observation_date);
CREATE INDEX ON _m1_5_detail_blueprint(industry_code,liquidity_risk_tier);

CREATE TEMP TABLE _m1_5_detail_profile ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_5_merchant_liquidity_profile(
 (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE INDEX ON _m1_5_detail_profile(merchant_id);

/* Result set 1 — Run and acceptance state */
SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.as_of_date,r.population_id,
       p.population_status,p.population_hash,p.merchant_count,p.history_start_date,p.history_end_date,
       r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') AS application_set_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO') AS pos_history_set_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_5_DEPOSIT_SET_HASH' AND segment_key='PORTFOLIO') AS deposit_history_set_hash,
       g.gate_id,g.review_version,g.result_status,g.reviewed_at,g.finding,g.residual_limitation
FROM msbf_ctl.run_registry r
JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
LEFT JOIN LATERAL(
 SELECT * FROM msbf_ctl.acceptance_gate_result x
 WHERE x.run_id=r.run_id AND x.gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY'
 ORDER BY review_version DESC LIMIT 1
) g ON true
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

/* Result set 2 — Entity and stage-boundary row counts */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT * FROM (VALUES
 ('merchant_master',(SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE population_id=(SELECT population_id FROM msbf_ctl.run_registry WHERE run_id=(SELECT run_id FROM r)))),
 ('merchant_application',(SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('merchant_pos_daily_base',(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))),
 ('merchant_deposit_daily_base',(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))),
 ('merchant_pos_daily_scenario',(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM r))),
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

/* Result set 3 — Industry liquidity diagnostics */
SELECT industry_code,COUNT(DISTINCT merchant_id) AS merchants,COUNT(*) AS observation_rows,
       round(SUM(base_pos_deposit_amount),2) AS captured_pos_deposits,
       round(SUM(non_pos_support_deposit_amount),2) AS non_pos_support_deposits,
       round(SUM(deposit_amount),2) AS total_deposits,round(SUM(withdrawal_amount),2) AS total_withdrawals,
       round(SUM(withdrawal_amount)/NULLIF(SUM(deposit_amount),0),6) AS withdrawal_to_deposit_ratio,
       round(AVG(daily_capture_rate),6) AS avg_capture_rate,
       round(AVG(closing_balance),2) AS avg_closing_balance,
       round(AVG(available_balance),2) AS avg_available_balance,
       round(COUNT(*) FILTER(WHERE negative_balance_flag)::numeric/COUNT(*),6) AS negative_balance_share,
       round(COUNT(*) FILTER(WHERE nsf_count>0)::numeric/COUNT(*),6) AS nsf_row_share
FROM _m1_5_detail_blueprint
GROUP BY industry_code ORDER BY industry_code;

/* Result set 4 — Provisional liquidity-risk tier diagnostics */
SELECT liquidity_risk_tier,COUNT(DISTINCT merchant_id) AS merchants,COUNT(*) AS observation_rows,
       round(AVG(merchant_capture_rate),6) AS avg_merchant_capture_rate,
       round(AVG(merchant_buffer_days),4) AS avg_buffer_days,
       round(AVG(merchant_withdrawal_rate),6) AS avg_withdrawal_rate,
       round(AVG(nsf_daily_probability),8) AS governed_nsf_probability,
       round(AVG(negative_balance_daily_probability),8) AS governed_negative_probability,
       round(AVG(b.adjusted_nsf_probability),8) AS avg_adjusted_nsf_probability,
       round(COUNT(*) FILTER(WHERE b.nsf_count>0)::numeric/COUNT(*),8) AS observed_nsf_row_share,
       round(COUNT(*) FILTER(WHERE b.negative_balance_flag)::numeric/COUNT(*),8) AS observed_negative_share,
       round(AVG(b.minimum_balance),2) AS avg_minimum_balance
FROM _m1_5_detail_profile p JOIN _m1_5_detail_blueprint b USING(merchant_id,liquidity_risk_tier)
GROUP BY liquidity_risk_tier ORDER BY liquidity_risk_tier;

/* Result set 5 — Relationship-stage diagnostics */
SELECT relationship_stage,COUNT(DISTINCT merchant_id) AS merchants,
       round(AVG(merchant_capture_rate),6) AS avg_capture_rate,
       round(AVG(merchant_buffer_days),4) AS avg_buffer_days,
       round(AVG(merchant_withdrawal_rate),6) AS avg_withdrawal_rate,
       round(AVG(target_buffer_amount),2) AS avg_target_buffer,
       COUNT(*) FILTER(WHERE deposit_relationship_flag) AS deposit_relationship_merchants,
       COUNT(*) FILTER(WHERE active_financing_flag) AS active_financing_merchants,
       round(AVG(liquidity_risk_tier),4) AS avg_liquidity_risk_tier
FROM _m1_5_detail_profile
GROUP BY relationship_stage ORDER BY relationship_stage;

/* Result set 6 — Deposit relationship and source availability */
SELECT deposit_relationship_flag,deposit_source_available_flag,
       COUNT(DISTINCT merchant_id) AS merchants,
       round(AVG(merchant_capture_rate),6) AS avg_capture_rate,
       round(AVG(relationship_capture_adjustment),6) AS avg_relationship_adjustment,
       round(AVG(target_buffer_amount),2) AS avg_target_buffer,
       round(AVG(liquidity_risk_tier),4) AS avg_liquidity_risk_tier
FROM _m1_5_detail_profile
GROUP BY deposit_relationship_flag,deposit_source_available_flag
ORDER BY deposit_relationship_flag DESC,deposit_source_available_flag DESC;

/* Result set 7 — Cash-flow archetype diagnostics */
SELECT cashflow_archetype_code,COUNT(DISTINCT merchant_id) AS merchants,COUNT(*) AS observation_rows,
       round(AVG(deposit_amount),2) AS avg_daily_deposit,
       round(AVG(withdrawal_amount),2) AS avg_daily_withdrawal,
       round(AVG(closing_balance),2) AS avg_closing_balance,
       round(COUNT(*) FILTER(WHERE negative_balance_flag)::numeric/COUNT(*),6) AS negative_balance_share,
       round(COUNT(*) FILTER(WHERE nsf_count>0)::numeric/COUNT(*),6) AS nsf_row_share,
       COUNT(*) FILTER(WHERE liquidity_event_code='RECENT_DISRUPTION') AS recent_disruption_rows,
       COUNT(*) FILTER(WHERE liquidity_event_code='LOW_LIQUIDITY') AS low_liquidity_rows,
       COUNT(*) FILTER(WHERE liquidity_event_code='NON_POS_SUPPORT_DEPOSIT') AS support_rows
FROM _m1_5_detail_blueprint
GROUP BY cashflow_archetype_code ORDER BY cashflow_archetype_code;

/* Result set 8 — Balance and NSF diagnostics */
SELECT
       round(MIN(opening_balance),2) AS minimum_opening_balance,
       round(MAX(opening_balance),2) AS maximum_opening_balance,
       round(MIN(closing_balance),2) AS minimum_closing_balance,
       round(MAX(closing_balance),2) AS maximum_closing_balance,
       round(MIN(available_balance),2) AS minimum_available_balance,
       round(MIN(minimum_balance),2) AS minimum_daily_balance,
       COUNT(*) FILTER(WHERE negative_balance_flag) AS negative_balance_rows,
       COUNT(DISTINCT merchant_id) FILTER(WHERE negative_balance_flag) AS negative_balance_merchants,
       COUNT(*) FILTER(WHERE nsf_count>0) AS nsf_rows,SUM(nsf_count) AS nsf_events,
       MAX(nsf_count) AS maximum_daily_nsf_count,
       round(AVG(temporary_hold_amount),2) AS avg_temporary_hold,
       round(MAX(temporary_hold_amount),2) AS max_temporary_hold
FROM _m1_5_detail_blueprint;

/* Result set 9 — Support-deposit and liquidity-event diagnostics */
SELECT liquidity_event_code,COUNT(*) AS rows,COUNT(DISTINCT merchant_id) AS merchants,
       round(SUM(non_pos_support_deposit_amount),2) AS support_deposit_amount,
       round(AVG(deposit_amount),2) AS avg_deposit,
       round(AVG(withdrawal_amount),2) AS avg_withdrawal,
       round(AVG(closing_balance),2) AS avg_closing_balance,
       round(AVG(available_balance),2) AS avg_available_balance,
       round(COUNT(*) FILTER(WHERE negative_balance_flag)::numeric/COUNT(*),6) AS negative_balance_share,
       SUM(nsf_count) AS nsf_events
FROM _m1_5_detail_blueprint
GROUP BY liquidity_event_code
ORDER BY CASE liquidity_event_code WHEN 'NORMAL' THEN 1 WHEN 'LOW_LIQUIDITY' THEN 2
         WHEN 'NEGATIVE_BALANCE_PRESSURE' THEN 3 WHEN 'NON_POS_SUPPORT_DEPOSIT' THEN 4
         WHEN 'RECENT_DISRUPTION' THEN 5 WHEN 'PROCESSOR_OUTAGE' THEN 6 WHEN 'PRE_OPEN' THEN 7 ELSE 8 END;

/* Result set 10 — Existing-financing remittance diagnostics */
SELECT relationship_stage,COUNT(DISTINCT merchant_id) FILTER(WHERE active_financing_flag) AS active_financing_merchants,
       COUNT(*) FILTER(WHERE existing_financing_remittance_amount>0) AS remittance_rows,
       round(SUM(existing_financing_remittance_amount),2) AS total_existing_financing_remittance,
       round(AVG(existing_financing_remittance_amount) FILTER(WHERE existing_financing_remittance_amount>0),2) AS avg_positive_daily_remittance,
       MIN(financing_start_date) FILTER(WHERE active_financing_flag) AS earliest_start,
       MAX(financing_end_date) FILTER(WHERE active_financing_flag) AS latest_end,
       round(AVG(financing_daily_remittance) FILTER(WHERE active_financing_flag),2) AS avg_assigned_daily_remittance
FROM _m1_5_detail_blueprint
GROUP BY relationship_stage ORDER BY relationship_stage;

/* Result set 11 — Merchant liquidity-trajectory examples */
WITH merchant_rollup AS (
 SELECT b.merchant_id,b.industry_code,b.cashflow_archetype_code,b.relationship_stage,b.liquidity_risk_tier,
        round(AVG(b.deposit_amount),2) AS avg_daily_deposit,
        round(AVG(b.withdrawal_amount),2) AS avg_daily_withdrawal,
        round(MIN(b.minimum_balance),2) AS minimum_balance,
        round(MAX(b.closing_balance),2) AS maximum_closing_balance,
        COUNT(*) FILTER(WHERE b.negative_balance_flag) AS negative_days,
        SUM(b.nsf_count) AS nsf_events,
        COUNT(*) FILTER(WHERE b.non_pos_support_deposit_amount>0) AS support_days,
        COUNT(*) FILTER(WHERE b.existing_financing_remittance_amount>0) AS financing_days
 FROM _m1_5_detail_blueprint b
 GROUP BY b.merchant_id,b.industry_code,b.cashflow_archetype_code,b.relationship_stage,b.liquidity_risk_tier
), ranked AS (
 SELECT *,row_number() OVER(PARTITION BY cashflow_archetype_code ORDER BY negative_days DESC,nsf_events DESC,merchant_id) AS archetype_sequence
 FROM merchant_rollup
)
SELECT merchant_id,industry_code,cashflow_archetype_code,relationship_stage,liquidity_risk_tier,
       avg_daily_deposit,avg_daily_withdrawal,minimum_balance,maximum_closing_balance,
       negative_days,nsf_events,support_days,financing_days
FROM ranked WHERE archetype_sequence<=8
ORDER BY cashflow_archetype_code,archetype_sequence;

/* Result set 12 — Row-level deterministic mismatches; expected zero rows */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT COALESCE(e.entity_key,a.entity_key) AS entity_key,e.row_hash AS expected_hash,a.row_hash AS actual_hash
FROM msbf_m1.m1_5_expected_deposit_snapshot((SELECT run_id FROM r)) e
FULL JOIN msbf_m1.m1_5_actual_deposit_snapshot((SELECT run_id FROM r)) a USING(entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash
ORDER BY entity_key;

/* Result set 13 — M1.5 evidence */
SELECT evidence_code,metric_name,status,metric_value_text,interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code LIKE 'M1_5_%'
ORDER BY evidence_code;

/* Result set 14 — Blocking resolution errors; expected zero rows */
SELECT profile_domain,scope_key,error_code,severity,error_message,created_at
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND severity='BLOCKING'
ORDER BY profile_domain,scope_key,error_code;

COMMIT;
