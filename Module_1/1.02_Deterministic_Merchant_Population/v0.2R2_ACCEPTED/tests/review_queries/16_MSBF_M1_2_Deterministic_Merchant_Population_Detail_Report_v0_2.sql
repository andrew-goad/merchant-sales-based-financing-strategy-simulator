/**********************************************************************
MSBF M1.2 Deterministic Merchant Population — Detail Report
Version : v0.2R2
Purpose : Multi-result-set evidence for audit, validation, and export.
**********************************************************************/

/* Result set 1 — Run and acceptance */
SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.as_of_date,r.population_id,
       p.population_version,p.population_status,p.merchant_count,p.deterministic_seed_version,
       p.history_start_date,p.history_end_date,p.population_hash,
       r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,
       g.gate_id,g.review_version,g.result_status,g.reviewed_at,g.finding,g.residual_limitation
FROM msbf_ctl.run_registry r
JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
LEFT JOIN LATERAL (
  SELECT * FROM msbf_ctl.acceptance_gate_result x
  WHERE x.run_id=r.run_id AND x.gate_id='M1_2_POPULATION'
  ORDER BY review_version DESC LIMIT 1
) g ON true
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

/* Result set 2 — Table counts */
WITH r AS (SELECT run_id,population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT * FROM (VALUES
 ('merchant_master',(SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE population_id=(SELECT population_id FROM r))),
 ('merchant_owner_guarantor',(SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor o JOIN msbf_m1.merchant_master m ON m.merchant_id=o.merchant_id WHERE m.population_id=(SELECT population_id FROM r))),
 ('merchant_industry_assignment',(SELECT COUNT(*) FROM msbf_m1.merchant_industry_assignment i JOIN msbf_m1.merchant_master m ON m.merchant_id=i.merchant_id WHERE m.population_id=(SELECT population_id FROM r))),
 ('partner_channel',(SELECT COUNT(*) FROM msbf_m1.partner_channel WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('processor_account',(SELECT COUNT(*) FROM msbf_m1.processor_account WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('merchant_relationship_snapshot',(SELECT COUNT(*) FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('merchant_application',(SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r))),
 ('merchant_pos_daily_base',(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))),
 ('merchant_deposit_daily_base',(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))),
 ('merchant_feature_snapshot',(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('merchant_risk_snapshot',(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('ead_path_snapshot',(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))),
 ('module1_latest',(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))),
 ('module1_archive',(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)))
) t(table_name,row_count)
ORDER BY table_name;

/* Result set 3 — Governed mix reconciliation */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
expected AS (
 SELECT 'INDUSTRY' AS dimension,category_code,target_count FROM msbf_m1.m1_2_weighted_assignment((SELECT run_id FROM r),'industry_mix_weight','INDUSTRY','INDUSTRY') GROUP BY category_code,target_count
 UNION ALL SELECT 'REGION',category_code,target_count FROM msbf_m1.m1_2_weighted_assignment((SELECT run_id FROM r),'region_mix_weight','REGION','REGION') GROUP BY category_code,target_count
 UNION ALL SELECT 'MERCHANT_SIZE',category_code,target_count FROM msbf_m1.m1_2_weighted_assignment((SELECT run_id FROM r),'merchant_size_mix_weight','MERCHANT_SIZE_TIER','MERCHANT_SIZE') GROUP BY category_code,target_count
 UNION ALL SELECT 'RELATIONSHIP_STAGE',category_code,target_count FROM msbf_m1.m1_2_weighted_assignment((SELECT run_id FROM r),'relationship_stage_mix_weight','RELATIONSHIP_STAGE','RELATIONSHIP') GROUP BY category_code,target_count
 UNION ALL SELECT 'LEGAL_ENTITY',category_code,target_count FROM msbf_m1.m1_2_weighted_assignment((SELECT run_id FROM r),'legal_entity_mix_weight','LEGAL_ENTITY_TYPE','LEGAL_ENTITY') GROUP BY category_code,target_count
 UNION ALL SELECT 'PARTNER_CHANNEL',category_code,target_count FROM msbf_m1.m1_2_weighted_assignment_json((SELECT run_id FROM r),'{"CH_PROCESSOR_DIRECT":0.34,"CH_BANK_RELATIONSHIP":0.18,"CH_DIGITAL_DIRECT":0.20,"CH_STRATEGIC_PARTNER":0.16,"CH_BROKER_NETWORK":0.12}'::jsonb,'CHANNEL') GROUP BY category_code,target_count
), actual AS (
 SELECT 'INDUSTRY' AS dimension,i.industry_code AS category_code,COUNT(*) AS actual_count FROM msbf_m1.merchant_industry_assignment i JOIN msbf_m1.merchant_master m ON m.merchant_id=i.merchant_id WHERE m.population_id='MSBF_POP_0001' GROUP BY i.industry_code
 UNION ALL SELECT 'REGION',region_code,COUNT(*) FROM msbf_m1.merchant_master WHERE population_id='MSBF_POP_0001' GROUP BY region_code
 UNION ALL SELECT 'MERCHANT_SIZE',merchant_size_tier,COUNT(*) FROM msbf_m1.merchant_master WHERE population_id='MSBF_POP_0001' GROUP BY merchant_size_tier
 UNION ALL SELECT 'RELATIONSHIP_STAGE',relationship_stage,COUNT(*) FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=(SELECT run_id FROM r) GROUP BY relationship_stage
 UNION ALL SELECT 'LEGAL_ENTITY',legal_entity_type,COUNT(*) FROM msbf_m1.merchant_master WHERE population_id='MSBF_POP_0001' GROUP BY legal_entity_type
 UNION ALL SELECT 'PARTNER_CHANNEL',partner_channel_id,COUNT(*) FROM msbf_m1.processor_account WHERE created_by_run_id=(SELECT run_id FROM r) GROUP BY partner_channel_id
)
SELECT COALESCE(e.dimension,a.dimension) AS dimension,COALESCE(e.category_code,a.category_code) AS category_code,
       e.target_count,a.actual_count,COALESCE(a.actual_count,0)-COALESCE(e.target_count,0) AS delta,
       CASE WHEN COALESCE(a.actual_count,0)=COALESCE(e.target_count,0) THEN 'PASS' ELSE 'FAIL' END AS status
FROM expected e FULL JOIN actual a USING(dimension,category_code)
ORDER BY dimension,category_code;

/* Result set 4 — Relationship-stage diagnostics */
SELECT relationship_stage,COUNT(*) AS merchants,
       COUNT(*) FILTER (WHERE prior_advance_count>0) AS prior_advance_merchants,
       COUNT(*) FILTER (WHERE prior_default_flag) AS prior_default_merchants,
       COUNT(*) FILTER (WHERE prior_payment_interruption_flag) AS prior_interruption_merchants,
       round(AVG(prior_advance_count),4) AS avg_prior_advances,
       round(AVG(wallet_share_proxy),6) AS avg_wallet_share,
       round(AVG(total_prior_funded_amount),2) AS avg_prior_funded,
       round(AVG(total_prior_repaid_amount),2) AS avg_prior_repaid
FROM msbf_m1.merchant_relationship_snapshot
WHERE created_by_run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
GROUP BY relationship_stage ORDER BY relationship_stage;

/* Result set 5 — Owner/guarantor summary */
SELECT owner_credit_band,COUNT(*) AS owner_rows,
       MIN(owner_credit_score) AS min_score,MAX(owner_credit_score) AS max_score,
       round(AVG(owner_credit_score),2) AS avg_score,
       COUNT(*) FILTER (WHERE major_derogatory_flag) AS major_derogatory_rows,
       COUNT(*) FILTER (WHERE bankruptcy_flag) AS bankruptcy_rows,
       COUNT(*) FILTER (WHERE personal_guarantee_available_flag) AS guarantee_available_rows,
       round(AVG(guarantee_capacity_amount),2) AS avg_guarantee_capacity
FROM msbf_m1.merchant_owner_guarantor
WHERE created_by_run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
GROUP BY owner_credit_band ORDER BY MIN(owner_credit_score) DESC;

/* Result set 6 — Processor and partner summary */
SELECT p.partner_channel_id,c.channel_type,c.partner_risk_tier,c.acquisition_cost_rate,
       COUNT(*) AS merchant_accounts,
       COUNT(*) FILTER (WHERE p.split_funding_capable_flag) AS split_funding_capable,
       round(AVG(p.settlement_delay_days),4) AS avg_settlement_delay,
       round(AVG(p.processor_risk_tier),4) AS avg_processor_risk_tier
FROM msbf_m1.processor_account p
JOIN msbf_m1.partner_channel c ON c.partner_channel_id=p.partner_channel_id
WHERE p.created_by_run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
GROUP BY p.partner_channel_id,c.channel_type,c.partner_risk_tier,c.acquisition_cost_rate
ORDER BY p.partner_channel_id;

/* Result set 7 — Mixed-signal examples */
SELECT m.merchant_id,m.merchant_size_tier,m.legal_entity_type,m.region_code,
       i.industry_code,s.relationship_stage,s.prior_advance_count,s.prior_default_flag,
       s.prior_payment_interruption_flag,s.wallet_share_proxy,
       o.owner_credit_score,o.owner_credit_band,
       ((extract(year from age(s.as_of_date,m.incorporation_date))*12)+extract(month from age(s.as_of_date,m.incorporation_date)))::integer AS months_in_business,
       CASE
        WHEN o.owner_credit_score>=700 AND (s.relationship_stage='RETURNING_MIXED' OR s.prior_payment_interruption_flag OR s.prior_default_flag) THEN 'STRONG_OWNER_ADVERSE_RELATIONSHIP'
        WHEN o.owner_credit_score<640 AND s.relationship_stage='RETURNING_GOOD' AND NOT s.prior_default_flag THEN 'WEAK_OWNER_POSITIVE_RELATIONSHIP'
        WHEN (((extract(year from age(s.as_of_date,m.incorporation_date))*12)+extract(month from age(s.as_of_date,m.incorporation_date)))::integer)<24 AND o.owner_credit_score>=720 THEN 'YOUNG_BUSINESS_STRONG_OWNER'
        WHEN m.merchant_size_tier IN ('LOWER_MIDDLE','MIDDLE') AND o.owner_credit_score<620 THEN 'LARGER_MERCHANT_WEAK_OWNER'
       END AS mixed_signal_type
FROM msbf_m1.merchant_master m
JOIN msbf_m1.merchant_industry_assignment i ON i.merchant_id=m.merchant_id
                                                AND i.assignment_type='PRIMARY'
                                                AND i.created_by_run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
JOIN msbf_m1.merchant_relationship_snapshot s ON s.merchant_id=m.merchant_id
                                                AND s.created_by_run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
JOIN msbf_m1.merchant_owner_guarantor o ON o.merchant_id=m.merchant_id
                                         AND o.party_role='PRIMARY_OWNER_GUARANTOR'
                                         AND o.created_by_run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
WHERE m.population_id='MSBF_POP_0001'
  AND (
        (o.owner_credit_score>=700 AND (s.relationship_stage='RETURNING_MIXED' OR s.prior_payment_interruption_flag OR s.prior_default_flag))
     OR (o.owner_credit_score<640 AND s.relationship_stage='RETURNING_GOOD' AND NOT s.prior_default_flag)
     OR ((((extract(year from age(s.as_of_date,m.incorporation_date))*12)+extract(month from age(s.as_of_date,m.incorporation_date)))::integer)<24 AND o.owner_credit_score>=720)
     OR (m.merchant_size_tier IN ('LOWER_MIDDLE','MIDDLE') AND o.owner_credit_score<620)
  )
ORDER BY mixed_signal_type,m.merchant_id
LIMIT 50;

/* Result set 8 — Row-level deterministic mismatches; expected zero rows */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT COALESCE(e.entity_type,a.entity_type) AS entity_type,COALESCE(e.entity_key,a.entity_key) AS entity_key,
       e.row_hash AS expected_hash,a.row_hash AS actual_hash
FROM msbf_m1.m1_2_expected_entity_snapshot((SELECT run_id FROM r)) e
FULL JOIN msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM r)) a USING(entity_type,entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash
ORDER BY entity_type,entity_key;

/* Result set 9 — M1.2 evidence */
SELECT evidence_code,metric_name,status,metric_value_text,interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND (evidence_code LIKE 'M1_2_%')
ORDER BY evidence_code;

/* Result set 10 — Blocking resolution errors; expected zero rows */
SELECT profile_domain,scope_key,error_code,severity,error_message,created_at
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND severity='BLOCKING'
ORDER BY profile_domain,scope_key,error_code;
