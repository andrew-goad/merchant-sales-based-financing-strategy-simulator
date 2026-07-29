/**********************************************************************
MSBF M1.3 Application and Requested Sales-Linked Structure Detail Report
Version : v0.2
**********************************************************************/

/* Result set 1 — Run and acceptance state */
SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.as_of_date,r.population_id,
       p.population_version,p.population_status,p.population_hash,
       r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,
       g.gate_id,g.review_version,g.result_status,g.reviewed_at,g.finding,g.residual_limitation,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') AS application_set_hash
FROM msbf_ctl.run_registry r
JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
LEFT JOIN LATERAL(
 SELECT * FROM msbf_ctl.acceptance_gate_result x WHERE x.run_id=r.run_id AND x.gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1
) g ON true
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

/* Result set 2 — Stage row counts */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT * FROM (VALUES
 ('merchant_application',(SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('source_snapshot',(SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('application_obligation_snapshot',(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('collateral_availability_snapshot',(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('guarantee_availability_snapshot',(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('application_business_credit_snapshot',(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('application_owner_credit_snapshot',(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('verification_result',(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('merchant_pos_daily_base',(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))),
 ('merchant_deposit_daily_base',(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))),
 ('merchant_feature_snapshot',(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('merchant_risk_snapshot',(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('ead_path_snapshot',(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('module1_latest',(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))),
 ('module1_archive',(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)))
) q(table_name,row_count) ORDER BY table_name;

/* Result set 3 — Expected payoff-horizon mix */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), exp AS (
 SELECT category_code::smallint AS horizon,target_count FROM msbf_m1.m1_3_weighted_assignment((SELECT run_id FROM r),'expected_payoff_day_weight','EXPECTED_PAYOFF_DAYS','HORIZON') GROUP BY category_code,target_count
), act AS (
 SELECT requested_expected_payoff_days AS horizon,COUNT(*) AS actual_count,
        round(AVG(requested_funding_amount),2) AS avg_funding,
        round(AVG(requested_remittance_rate),6) AS avg_remittance_rate,
        round(AVG(requested_total_repayment_amount/requested_funding_amount),6) AS avg_payback_multiple
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r) GROUP BY requested_expected_payoff_days
)
SELECT COALESCE(exp.horizon,act.horizon) AS horizon,exp.target_count,act.actual_count,
       COALESCE(act.actual_count,0)-COALESCE(exp.target_count,0) AS delta,
       act.avg_funding,act.avg_remittance_rate,act.avg_payback_multiple,
       CASE WHEN COALESCE(act.actual_count,0)=COALESCE(exp.target_count,0) THEN 'PASS' ELSE 'FAIL' END AS status
FROM exp FULL JOIN act USING(horizon) ORDER BY horizon;

/* Result set 4 — Use-of-proceeds mix */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), exp AS (
 SELECT category_code AS use_code,target_count FROM msbf_m1.m1_3_weighted_assignment((SELECT run_id FROM r),'use_of_proceeds_mix_weight','USE_OF_PROCEEDS','USE_OF_PROCEEDS') GROUP BY category_code,target_count
), act AS (
 SELECT requested_use_of_proceeds AS use_code,COUNT(*) AS actual_count,
        round(AVG(requested_funding_amount),2) AS avg_funding,
        round(AVG(requested_expected_payoff_days),2) AS avg_horizon
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r) GROUP BY requested_use_of_proceeds
)
SELECT COALESCE(exp.use_code,act.use_code) AS use_code,exp.target_count,act.actual_count,
       COALESCE(act.actual_count,0)-COALESCE(exp.target_count,0) AS delta,
       act.avg_funding,act.avg_horizon,
       CASE WHEN COALESCE(act.actual_count,0)=COALESCE(exp.target_count,0) THEN 'PASS' ELSE 'FAIL' END AS status
FROM exp FULL JOIN act USING(use_code) ORDER BY use_code;

/* Result set 5 — Merchant-size request diagnostics */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT merchant_size_tier,COUNT(*) AS applications,
       round(AVG(annual_sales_proxy),2) AS avg_annual_sales_proxy,
       round(AVG(requested_funding_amount),2) AS avg_funding,
       MIN(requested_funding_amount) AS min_funding,MAX(requested_funding_amount) AS max_funding,
       round(AVG(funding_to_annualized_sales_rate),6) AS avg_funding_to_sales,
       round(AVG(requested_remittance_rate),6) AS avg_remittance_rate,
       round(AVG(requested_payback_multiple),6) AS avg_payback_multiple
FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM r))
GROUP BY merchant_size_tier
ORDER BY CASE merchant_size_tier WHEN 'MICRO' THEN 1 WHEN 'SMALL' THEN 2 WHEN 'LOWER_MIDDLE' THEN 3 ELSE 4 END;

/* Result set 6 — Relationship-stage request diagnostics */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT relationship_stage,COUNT(*) AS applications,
       round(AVG(requested_funding_amount),2) AS avg_funding,
       round(AVG(funding_to_annualized_sales_rate),6) AS avg_funding_to_sales,
       round(AVG(request_path_utilization_factor),6) AS avg_utilization_factor,
       round(AVG(requested_remittance_rate),6) AS avg_remittance_rate,
       round(AVG(requested_payback_multiple),6) AS avg_payback_multiple,
       round(AVG(implied_payoff_days),4) AS avg_implied_payoff_days,
       round(AVG(repayment_path_ratio),6) AS avg_repayment_path_ratio,
       COUNT(*) FILTER (WHERE minimum_amount_floor_override_flag) AS minimum_floor_rows
FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM r))
GROUP BY relationship_stage ORDER BY relationship_stage;

/* Result set 7 — Channel and processor diagnostics */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT a.partner_channel_id,a.application_channel,COUNT(*) AS applications,
       round(AVG(a.requested_funding_amount),2) AS avg_funding,
       round(AVG(a.requested_remittance_rate),6) AS avg_remittance_rate,
       round(AVG(a.requested_total_repayment_amount/a.requested_funding_amount),6) AS avg_payback_multiple,
       COUNT(*) FILTER (WHERE p.split_funding_capable_flag) AS split_funding_capable
FROM msbf_m1.merchant_application a
JOIN msbf_m1.processor_account p ON p.processor_account_id=a.processor_account_id
WHERE a.created_by_run_id=(SELECT run_id FROM r)
GROUP BY a.partner_channel_id,a.application_channel
ORDER BY a.partner_channel_id;

/* Result set 8 — Binding constraints */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT binding_constraint_code,COUNT(*) AS applications,
       round(AVG(requested_funding_amount),2) AS avg_funding,
       round(AVG(funding_to_annualized_sales_rate),6) AS avg_funding_to_sales,
       round(AVG(implied_payoff_days),4) AS avg_implied_payoff_days,
       round(AVG(repayment_path_ratio),6) AS avg_repayment_path_ratio,
       COUNT(*) FILTER (WHERE minimum_amount_floor_override_flag) AS minimum_floor_rows
FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM r))
GROUP BY binding_constraint_code ORDER BY applications DESC,binding_constraint_code;

/* Result set 9 — Mixed-signal request examples */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT merchant_application_id,merchant_id,merchant_size_tier,relationship_stage,owner_credit_score,
       prior_default_flag,prior_payment_interruption_flag,months_in_business,
       requested_funding_amount,funding_to_annualized_sales_rate,requested_remittance_rate,
       requested_expected_payoff_days,requested_payback_multiple,implied_payoff_days,requested_use_of_proceeds,
       CASE
        WHEN owner_credit_score>=700 AND (relationship_stage='RETURNING_MIXED' OR prior_payment_interruption_flag OR prior_default_flag) AND funding_to_annualized_sales_rate<0.04 THEN 'STRONG_OWNER_CONSERVATIVE_ADVERSE_RELATIONSHIP'
        WHEN owner_credit_score<640 AND requested_funding_amount<=25000 AND implied_payoff_days<=requested_expected_payoff_days THEN 'WEAKER_OWNER_SMALL_FEASIBLE_REQUEST'
        WHEN months_in_business<24 AND owner_credit_score>=720 AND requested_expected_payoff_days IN (60,90) THEN 'YOUNG_BUSINESS_STRONG_OWNER_LONGER_HORIZON'
       END AS mixed_signal_type
FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM r))
WHERE (owner_credit_score>=700 AND (relationship_stage='RETURNING_MIXED' OR prior_payment_interruption_flag OR prior_default_flag) AND funding_to_annualized_sales_rate<0.04)
   OR (owner_credit_score<640 AND requested_funding_amount<=25000 AND implied_payoff_days<=requested_expected_payoff_days)
   OR (months_in_business<24 AND owner_credit_score>=720 AND requested_expected_payoff_days IN (60,90))
ORDER BY mixed_signal_type,merchant_application_id LIMIT 75;

/* Result set 10 — Row-level deterministic mismatches; expected zero rows */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT COALESCE(e.entity_key,a.entity_key) AS entity_key,e.row_hash AS expected_hash,a.row_hash AS actual_hash
FROM msbf_m1.m1_3_expected_application_snapshot((SELECT run_id FROM r)) e
FULL JOIN msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM r)) a USING(entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash
ORDER BY entity_key;

/* Result set 11 — M1.3 evidence */
SELECT evidence_code,metric_name,status,metric_value_text,interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code LIKE 'M1_3_%'
ORDER BY evidence_code;

/* Result set 12 — Blocking resolution errors; expected zero rows */
SELECT profile_domain,scope_key,error_code,severity,error_message,created_at
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND severity='BLOCKING'
ORDER BY profile_domain,scope_key,error_code;
