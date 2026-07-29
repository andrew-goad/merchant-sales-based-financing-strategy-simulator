/**********************************************************************
MSBF M1.6 Matched POS and Deposit Scenario Overlay Detail Report
Version : v0.2
Purpose : Produce detailed scenario, transmission, matched-comparison,
          deterministic, evidence, and stage-boundary outputs for review.
**********************************************************************/
BEGIN;

CREATE TEMP TABLE _m1_6_detail_ctx ON COMMIT DROP AS
SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.as_of_date,r.population_id,
       p.population_status,p.population_hash,p.history_start_date,p.history_end_date,
       (p.history_end_date-p.history_start_date+1)::integer AS history_days,
       r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash
FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

CREATE TEMP TABLE _m1_6_detail_profile ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_6_scenario_profile((SELECT run_id FROM _m1_6_detail_ctx));
CREATE INDEX ON _m1_6_detail_profile(scenario_id);

CREATE TEMP TABLE _m1_6_detail_pos ON COMMIT DROP AS
SELECT p.*,sr.scenario_code,sr.scenario_name,sr.scenario_type,
       (p.scenario_overlay_payload->>'industry_code') AS industry_code,
       COALESCE((p.scenario_overlay_payload->>'shock_active_flag')::boolean,false) AS shock_active_flag,
       COALESCE((p.scenario_overlay_payload->>'propagation_active_flag')::boolean,false) AS propagation_active_flag,
       COALESCE((p.scenario_overlay_payload->>'scenario_outage_flag')::boolean,false) AS scenario_outage_flag,
       COALESCE((p.scenario_overlay_payload->>'incremental_zero_sales_flag')::boolean,false) AS incremental_zero_sales_flag,
       p.scenario_overlay_payload->>'shock_channel' AS shock_channel
FROM msbf_m1.merchant_pos_daily_scenario p
JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=p.scenario_id
WHERE p.generated_by_run_id=(SELECT run_id FROM _m1_6_detail_ctx);
CREATE INDEX ON _m1_6_detail_pos(scenario_id,merchant_id,observation_date);

CREATE TEMP TABLE _m1_6_detail_deposit ON COMMIT DROP AS
SELECT d.*,sr.scenario_code,sr.scenario_name,sr.scenario_type,
       COALESCE((d.scenario_overlay_payload->>'shock_active_flag')::boolean,false) AS shock_active_flag,
       (d.scenario_overlay_payload->>'base_pos_deposit_amount')::numeric AS base_pos_deposit_amount,
       (d.scenario_overlay_payload->>'support_deposit_amount')::numeric AS support_deposit_amount,
       (d.scenario_overlay_payload->>'temporary_hold_amount')::numeric AS temporary_hold_amount,
       (d.scenario_overlay_payload->>'adjusted_nsf_probability')::numeric AS adjusted_nsf_probability,
       d.scenario_overlay_payload->>'liquidity_event_code' AS liquidity_event_code
FROM msbf_m1.merchant_deposit_daily_scenario d
JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=d.scenario_id
WHERE d.generated_by_run_id=(SELECT run_id FROM _m1_6_detail_ctx);
CREATE INDEX ON _m1_6_detail_deposit(scenario_id,merchant_id,observation_date);

/* Result set 1 — Run and acceptance state */
SELECT c.*,a.gate_id,a.review_version,a.result_status,a.observed_value,a.threshold_value,
       a.finding,a.residual_limitation,a.reviewer_role,a.reviewed_at
FROM _m1_6_detail_ctx c
LEFT JOIN LATERAL (
 SELECT * FROM msbf_ctl.acceptance_gate_result x
 WHERE x.run_id=c.run_id AND x.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS'
 ORDER BY review_version DESC LIMIT 1
) a ON true;

/* Result set 2 — Scenario registry and parameter profile */
SELECT p.scenario_id,p.scenario_set_id,p.scenario_code,p.scenario_version,p.scenario_name,p.scenario_type,
       p.sales_level_multiplier,p.sales_volatility_multiplier,p.zero_sales_probability_multiplier,
       p.refund_rate_multiplier,p.chargeback_rate_multiplier,p.deposit_capture_multiplier,
       p.obligation_multiplier,p.processor_outage_rate,p.direct_shock_cap,p.propagated_shock_cap,
       p.damping_factor,p.lag_days,p.matched_share_min,p.liquidity_shock_multiplier,
       p.history_start_date,p.history_end_date,p.shock_start_date,p.propagation_start_date,p.stress_window_days
FROM _m1_6_detail_profile p
ORDER BY CASE p.scenario_code WHEN 'BASELINE' THEN 1 ELSE 2 END;

/* Result set 3 — Entity and stage-boundary row counts */
WITH r AS (SELECT run_id FROM _m1_6_detail_ctx)
SELECT table_name,row_count FROM (VALUES
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
 ('feature_value',(SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=(SELECT run_id FROM r))),
 ('merchant_risk_snapshot',(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('risk_component_detail',(SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM r))),
 ('ead_path_snapshot',(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('module1_latest',(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))),
 ('module1_archive',(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)))
) q(table_name,row_count) ORDER BY table_name;

/* Result set 4 — Scenario-level POS operating diagnostics */
SELECT p.scenario_code,COUNT(*) AS rows,COUNT(DISTINCT p.merchant_id) AS merchants,COUNT(DISTINCT p.observation_date) AS dates,
       round(SUM(p.gross_pos_sales),2) AS gross_pos_sales,round(SUM(p.eligible_pos_sales),2) AS eligible_pos_sales,
       round(SUM(p.refund_amount),2) AS refund_amount,round(SUM(p.chargeback_amount),2) AS chargeback_amount,
       round(SUM(p.settlement_amount),2) AS settlement_amount,round(SUM(p.processor_fee_amount),2) AS processor_fees,
       round(SUM(p.net_merchant_proceeds),2) AS net_merchant_proceeds,
       round(SUM(p.refund_amount)/NULLIF(SUM(p.gross_pos_sales),0),8) AS refund_rate,
       round(SUM(p.chargeback_amount)/NULLIF(SUM(p.gross_pos_sales),0),8) AS chargeback_rate,
       round(COUNT(*) FILTER(WHERE p.zero_sales_day_flag)::numeric/COUNT(*),8) AS zero_sales_share,
       round(COUNT(*) FILTER(WHERE p.processor_status='OUTAGE')::numeric/COUNT(*),8) AS outage_share
FROM _m1_6_detail_pos p GROUP BY p.scenario_code ORDER BY p.scenario_code;

/* Result set 5 — Scenario-level deposit and liquidity diagnostics */
SELECT d.scenario_code,COUNT(*) AS rows,COUNT(DISTINCT d.merchant_id) AS merchants,COUNT(DISTINCT d.observation_date) AS dates,
       round(SUM(d.deposit_amount),2) AS deposit_amount,round(SUM(d.withdrawal_amount),2) AS withdrawal_amount,
       round(SUM(d.withdrawal_amount)/NULLIF(SUM(d.deposit_amount),0),8) AS withdrawal_to_deposit_ratio,
       round(AVG(d.closing_balance),2) AS avg_closing_balance,round(MIN(d.minimum_balance),2) AS minimum_balance,
       COUNT(*) FILTER(WHERE d.negative_balance_flag) AS negative_balance_rows,
       round(COUNT(*) FILTER(WHERE d.negative_balance_flag)::numeric/COUNT(*),8) AS negative_balance_share,
       SUM(d.nsf_count) AS nsf_events,COUNT(*) FILTER(WHERE d.nsf_count>0) AS nsf_rows,
       round(SUM(d.support_deposit_amount),2) AS support_deposit_amount,
       COUNT(*) FILTER(WHERE d.support_deposit_amount>0) AS support_deposit_rows
FROM _m1_6_detail_deposit d GROUP BY d.scenario_code ORDER BY d.scenario_code;

/* Result set 6 — Industry stress-transmission diagnostics */
WITH paired AS (
 SELECT s.industry_code,s.shock_channel,
        SUM(b.gross_pos_sales) AS baseline_gross,SUM(s.gross_pos_sales) AS stress_gross,
        SUM(b.eligible_pos_sales) AS baseline_eligible,SUM(s.eligible_pos_sales) AS stress_eligible,
        AVG(s.direct_shock_factor) AS avg_direct_factor,AVG(s.propagated_shock_factor) AS avg_propagated_factor,
        COUNT(*) FILTER(WHERE s.scenario_outage_flag) AS incremental_outage_rows,
        COUNT(*) FILTER(WHERE s.incremental_zero_sales_flag) AS incremental_zero_rows
 FROM _m1_6_detail_pos s
 JOIN _m1_6_detail_pos b ON b.scenario_code='BASELINE' AND b.merchant_id=s.merchant_id
  AND b.processor_account_id=s.processor_account_id AND b.observation_date=s.observation_date
 WHERE s.scenario_code='RECESSION_ENERGY' AND s.shock_active_flag
 GROUP BY s.industry_code,s.shock_channel
)
SELECT industry_code,shock_channel,round(baseline_gross,2) AS baseline_gross,
       round(stress_gross,2) AS stress_gross,round(1-stress_gross/NULLIF(baseline_gross,0),8) AS gross_decline_rate,
       round(baseline_eligible,2) AS baseline_eligible,round(stress_eligible,2) AS stress_eligible,
       round(1-stress_eligible/NULLIF(baseline_eligible,0),8) AS eligible_decline_rate,
       round(avg_direct_factor,8) AS avg_direct_factor,round(avg_propagated_factor,8) AS avg_propagated_factor,
       incremental_outage_rows,incremental_zero_rows
FROM paired ORDER BY gross_decline_rate DESC,industry_code;

/* Result set 7 — Stress-window phase diagnostics */
WITH phase AS (
 SELECT CASE WHEN NOT p.shock_active_flag THEN 'PRE_SHOCK'
             WHEN p.shock_active_flag AND NOT p.propagation_active_flag THEN 'DIRECT_ONLY'
             ELSE 'DIRECT_AND_PROPAGATED' END AS stress_phase,
        COUNT(*) AS rows,COUNT(DISTINCT p.merchant_id) AS merchants,
        MIN(p.observation_date) AS minimum_date,MAX(p.observation_date) AS maximum_date,
        round(AVG(p.direct_shock_factor),8) AS avg_direct_factor,
        round(AVG(p.propagated_shock_factor),8) AS avg_propagated_factor,
        round(SUM(p.gross_pos_sales),2) AS gross_pos_sales,
        round(COUNT(*) FILTER(WHERE p.scenario_outage_flag)::numeric/COUNT(*),8) AS scenario_outage_share,
        round(COUNT(*) FILTER(WHERE p.incremental_zero_sales_flag)::numeric/COUNT(*),8) AS incremental_zero_share
 FROM _m1_6_detail_pos p WHERE p.scenario_code='RECESSION_ENERGY'
 GROUP BY 1
)
SELECT * FROM phase
ORDER BY CASE stress_phase WHEN 'PRE_SHOCK' THEN 1 WHEN 'DIRECT_ONLY' THEN 2 ELSE 3 END;

/* Result set 8 — Processor and connection diagnostics */
SELECT p.scenario_code,p.processor_status,p.data_connection_status,COUNT(*) AS rows,
       COUNT(DISTINCT p.merchant_id) AS merchants,round(SUM(p.gross_pos_sales),2) AS gross_pos_sales,
       round(SUM(p.net_merchant_proceeds),2) AS net_merchant_proceeds
FROM _m1_6_detail_pos p
GROUP BY p.scenario_code,p.processor_status,p.data_connection_status
ORDER BY p.scenario_code,p.processor_status,p.data_connection_status;

/* Result set 9 — Transaction-quality diagnostics */
SELECT p.scenario_code,p.industry_code,COUNT(*) AS rows,
       round(SUM(p.refund_amount)/NULLIF(SUM(p.gross_pos_sales),0),8) AS refund_rate,
       round(SUM(p.chargeback_amount)/NULLIF(SUM(p.gross_pos_sales),0),8) AS chargeback_rate,
       round(SUM(p.reversal_amount)/NULLIF(SUM(p.gross_pos_sales),0),8) AS reversal_rate,
       round(COUNT(*) FILTER(WHERE p.zero_sales_day_flag)::numeric/COUNT(*),8) AS zero_sales_share,
       round(COUNT(*) FILTER(WHERE p.processor_status='OUTAGE')::numeric/COUNT(*),8) AS outage_share
FROM _m1_6_detail_pos p GROUP BY p.scenario_code,p.industry_code
ORDER BY p.industry_code,p.scenario_code;

/* Result set 10 — Liquidity-event and stress diagnostics */
SELECT d.scenario_code,d.liquidity_event_code,COUNT(*) AS rows,COUNT(DISTINCT d.merchant_id) AS merchants,
       round(SUM(d.deposit_amount),2) AS deposit_amount,round(SUM(d.withdrawal_amount),2) AS withdrawal_amount,
       round(AVG(d.closing_balance),2) AS avg_closing_balance,round(MIN(d.minimum_balance),2) AS minimum_balance,
       COUNT(*) FILTER(WHERE d.negative_balance_flag) AS negative_balance_rows,SUM(d.nsf_count) AS nsf_events,
       round(SUM(d.support_deposit_amount),2) AS support_deposit_amount
FROM _m1_6_detail_deposit d
GROUP BY d.scenario_code,d.liquidity_event_code
ORDER BY d.scenario_code,d.liquidity_event_code;

/* Result set 11 — Merchant matched-scenario examples */
WITH merchant_delta AS (
 SELECT s.merchant_id,s.industry_code,
        SUM(b.gross_pos_sales) AS baseline_gross,SUM(s.gross_pos_sales) AS stress_gross,
        SUM(bd.deposit_amount) AS baseline_deposits,SUM(sd.deposit_amount) AS stress_deposits,
        SUM(bd.nsf_count) AS baseline_nsf,SUM(sd.nsf_count) AS stress_nsf,
        COUNT(*) FILTER(WHERE bd.negative_balance_flag) AS baseline_negative_days,
        COUNT(*) FILTER(WHERE sd.negative_balance_flag) AS stress_negative_days
 FROM _m1_6_detail_pos s
 JOIN _m1_6_detail_pos b ON b.scenario_code='BASELINE' AND b.merchant_id=s.merchant_id AND b.observation_date=s.observation_date
 JOIN _m1_6_detail_deposit sd ON sd.scenario_code='RECESSION_ENERGY' AND sd.merchant_id=s.merchant_id AND sd.observation_date=s.observation_date
 JOIN _m1_6_detail_deposit bd ON bd.scenario_code='BASELINE' AND bd.merchant_id=s.merchant_id AND bd.observation_date=s.observation_date
 WHERE s.scenario_code='RECESSION_ENERGY'
 GROUP BY s.merchant_id,s.industry_code
), ranked AS (
 SELECT *,1-stress_gross/NULLIF(baseline_gross,0) AS sales_decline,
        row_number() OVER(PARTITION BY industry_code ORDER BY 1-stress_gross/NULLIF(baseline_gross,0) DESC,merchant_id) AS industry_sequence
 FROM merchant_delta
)
SELECT merchant_id,industry_code,round(baseline_gross,2) AS baseline_gross,round(stress_gross,2) AS stress_gross,
       round(sales_decline,8) AS sales_decline_rate,round(baseline_deposits,2) AS baseline_deposits,
       round(stress_deposits,2) AS stress_deposits,baseline_nsf,stress_nsf,
       baseline_negative_days,stress_negative_days
FROM ranked WHERE industry_sequence<=6
ORDER BY industry_code,industry_sequence;

/* Result set 12 — Daily portfolio scenario deltas */
WITH pos_daily AS (
 SELECT p.scenario_code,p.observation_date,SUM(p.gross_pos_sales) AS gross_sales,SUM(p.eligible_pos_sales) AS eligible_sales
 FROM _m1_6_detail_pos p GROUP BY p.scenario_code,p.observation_date
), dep_daily AS (
 SELECT d.scenario_code,d.observation_date,SUM(d.deposit_amount) AS deposits,SUM(d.withdrawal_amount) AS withdrawals,
        SUM(d.nsf_count) AS nsf_events,COUNT(*) FILTER(WHERE d.negative_balance_flag) AS negative_rows
 FROM _m1_6_detail_deposit d GROUP BY d.scenario_code,d.observation_date
)
SELECT b.observation_date,round(b.gross_sales,2) AS baseline_gross,round(s.gross_sales,2) AS stress_gross,
       round(s.gross_sales-b.gross_sales,2) AS gross_delta,
       round(b.eligible_sales,2) AS baseline_eligible,round(s.eligible_sales,2) AS stress_eligible,
       round(sd.deposits-bd.deposits,2) AS deposit_delta,round(sd.withdrawals-bd.withdrawals,2) AS withdrawal_delta,
       sd.nsf_events-bd.nsf_events AS nsf_delta,sd.negative_rows-bd.negative_rows AS negative_row_delta
FROM pos_daily b JOIN pos_daily s ON s.observation_date=b.observation_date AND s.scenario_code='RECESSION_ENERGY'
JOIN dep_daily bd ON bd.observation_date=b.observation_date AND bd.scenario_code='BASELINE'
JOIN dep_daily sd ON sd.observation_date=b.observation_date AND sd.scenario_code='RECESSION_ENERGY'
WHERE b.scenario_code='BASELINE'
ORDER BY b.observation_date;

/* Result set 13 — Industry shock matrix */
SELECT * FROM msbf_m1.m1_6_industry_shock_matrix() ORDER BY direct_sensitivity DESC,energy_dependency_weight DESC,industry_code;

/* Result set 14 — Row-level deterministic mismatches; expected zero rows */
WITH r AS (SELECT run_id FROM _m1_6_detail_ctx)
SELECT COALESCE(e.entity_type,a.entity_type) AS entity_type,
       COALESCE(e.entity_key,a.entity_key) AS entity_key,e.row_hash AS expected_hash,a.row_hash AS actual_hash
FROM msbf_m1.m1_6_expected_scenario_snapshot((SELECT run_id FROM r)) e
FULL JOIN msbf_m1.m1_6_actual_scenario_snapshot((SELECT run_id FROM r)) a USING(entity_type,entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash
ORDER BY entity_type,entity_key;

/* Result set 15 — M1.6 evidence */
SELECT evidence_code,metric_name,status,metric_value_text,interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m1_6_detail_ctx) AND evidence_code LIKE 'M1_6_%'
ORDER BY evidence_code;

/* Result set 16 — Blocking resolution errors; expected zero rows */
SELECT profile_domain,scope_key,error_code,severity,error_message,created_at
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM _m1_6_detail_ctx) AND severity='BLOCKING'
ORDER BY profile_domain,scope_key,error_code;

COMMIT;
