/**********************************************************************
MSBF M1.3 Application and Requested Sales-Linked Structure Master Report
Version : v0.2
Purpose : One-row acceptance report for M1.3.
**********************************************************************/
WITH ctx AS (
 SELECT r.*,p.population_status,p.population_hash,p.population_version,p.merchant_count,p.deterministic_seed_version
 FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
), g1_hashes AS (
 SELECT
  (SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key)) FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS parameter_hash,
  (SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code)) FROM msbf_ctl.run_profile_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS profile_hash,
  (SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code)) FROM msbf_ctl.run_source_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS source_hash
), pop_hash AS (
 SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) AS population_hash
 FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM ctx))
), gates AS (
 SELECT
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1) AS g1_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1) AS m12_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) AS m13_status,
  (SELECT review_version FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) AS m13_review_version,
  (SELECT reviewed_at FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) AS m13_reviewed_at,
  (SELECT finding FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) AS m13_finding
), app_obs AS (
 SELECT COUNT(*) AS applications,COUNT(DISTINCT merchant_id) AS merchants,
        MIN(requested_funding_amount) AS min_funding,MAX(requested_funding_amount) AS max_funding,
        round(AVG(requested_funding_amount),2) AS avg_funding,
        round(AVG(requested_remittance_rate),6) AS avg_remittance_rate,
        round(AVG(requested_total_repayment_amount/requested_funding_amount),6) AS avg_payback_multiple,
        round(AVG(requested_total_repayment_amount),2) AS avg_total_repayment,
        round(SUM(requested_funding_amount),2) AS total_requested_funding,
        COUNT(*) FILTER (WHERE requested_expected_payoff_days=30) AS horizon_30,
        COUNT(*) FILTER (WHERE requested_expected_payoff_days=60) AS horizon_60,
        COUNT(*) FILTER (WHERE requested_expected_payoff_days=90) AS horizon_90,
        COUNT(*) FILTER (WHERE requested_use_of_proceeds='WORKING_CAPITAL') AS use_working_capital,
        COUNT(*) FILTER (WHERE requested_use_of_proceeds='INVENTORY') AS use_inventory,
        COUNT(*) FILTER (WHERE requested_use_of_proceeds='EQUIPMENT_REPAIR') AS use_equipment_repair,
        COUNT(*) FILTER (WHERE requested_use_of_proceeds='SEASONAL_NEED') AS use_seasonal_need,
        COUNT(*) FILTER (WHERE requested_use_of_proceeds='EXPANSION') AS use_expansion,
        COUNT(*) FILTER (WHERE requested_use_of_proceeds='EMERGENCY_EXPENSE') AS use_emergency
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM ctx)
), canonical AS (
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.m1_3_expected_application_snapshot((SELECT run_id FROM ctx))) AS expected_rows,
  (SELECT COUNT(*) FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM ctx))) AS actual_rows,
  (SELECT COUNT(*) FROM msbf_m1.m1_3_expected_application_snapshot((SELECT run_id FROM ctx)) e FULL JOIN msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM ctx)) a USING(entity_key) WHERE e.row_hash IS DISTINCT FROM a.row_hash) AS mismatches,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_expected_application_snapshot((SELECT run_id FROM ctx))) AS expected_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM ctx))) AS actual_hash,
  (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM ctx) AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') AS stored_hash
), evidence_obs AS (
 SELECT COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_3_POS_%') AS positive_checks,
        COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_3_POS_%' AND status='PASS') AS positive_passes,
        COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_3_NEG_%') AS negative_controls,
        COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_3_NEG_%' AND status='PASS') AS negative_passes,
        COUNT(*) FILTER (WHERE (evidence_code LIKE 'M1_3_POS_%' OR evidence_code LIKE 'M1_3_NEG_%') AND status='FAIL') AS failed_evidence
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM ctx)
), diagnostics AS (
 SELECT MIN(implied_payoff_days) AS min_implied_payoff_days,MAX(implied_payoff_days) AS max_implied_payoff_days,
        MIN(funding_to_annualized_sales_rate) AS min_funding_to_sales,MAX(funding_to_annualized_sales_rate) AS max_funding_to_sales,
        MIN(repayment_path_ratio) AS min_repayment_path_ratio,MAX(repayment_path_ratio) AS max_repayment_path_ratio,
        COUNT(*) FILTER (WHERE repayment_path_ratio<=1.0001) AS on_or_below_path_rows,
        COUNT(*) FILTER (WHERE repayment_path_ratio>1.0001) AS above_path_rows,
        COUNT(*) FILTER (WHERE minimum_amount_floor_override_flag) AS minimum_floor_rows,
        COUNT(DISTINCT binding_constraint_code) AS binding_constraint_types,
        COUNT(*) FILTER (WHERE
          (owner_credit_score>=700 AND (relationship_stage='RETURNING_MIXED' OR prior_payment_interruption_flag OR prior_default_flag) AND funding_to_annualized_sales_rate<0.04)
          OR (owner_credit_score<640 AND requested_funding_amount<=25000 AND implied_payoff_days<=requested_expected_payoff_days)
          OR (months_in_business<24 AND owner_credit_score>=720 AND requested_expected_payoff_days IN (60,90))) AS mixed_signal_rows
 FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM ctx))
), downstream AS (
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM ctx)) AS rows
), errors AS (
 SELECT COUNT(*) AS blocking_errors FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM ctx) AND severity='BLOCKING'
)
SELECT clock_timestamp() AS report_timestamp,current_database() AS database_name,current_user AS database_user,
       current_setting('server_version') AS postgresql_version,
       ctx.run_id,ctx.run_code,ctx.run_version,ctx.run_status,ctx.as_of_date,
       ctx.population_id,ctx.population_version,ctx.population_status,ctx.merchant_count AS planned_merchant_count,
       ctx.deterministic_seed_version,ctx.parameter_snapshot_hash,g1_hashes.parameter_hash AS recomputed_parameter_hash,
       ctx.profile_snapshot_hash,g1_hashes.profile_hash AS recomputed_profile_hash,
       ctx.source_snapshot_hash,g1_hashes.source_hash AS recomputed_source_hash,
       ctx.population_hash,pop_hash.population_hash AS recomputed_population_hash,
       gates.g1_status,gates.m12_status,gates.m13_status,gates.m13_review_version,gates.m13_reviewed_at,gates.m13_finding,
       app_obs.*,canonical.expected_rows,canonical.actual_rows,canonical.mismatches,
       canonical.stored_hash AS stored_application_set_hash,canonical.expected_hash AS expected_application_set_hash,
       canonical.actual_hash AS actual_application_set_hash,
       diagnostics.min_implied_payoff_days,diagnostics.max_implied_payoff_days,
       diagnostics.min_funding_to_sales,diagnostics.max_funding_to_sales,
       diagnostics.min_repayment_path_ratio,diagnostics.max_repayment_path_ratio,
       diagnostics.on_or_below_path_rows,diagnostics.above_path_rows,diagnostics.minimum_floor_rows,
       diagnostics.binding_constraint_types,diagnostics.mixed_signal_rows,
       evidence_obs.positive_checks,evidence_obs.positive_passes,evidence_obs.negative_controls,evidence_obs.negative_passes,
       evidence_obs.failed_evidence,downstream.rows AS downstream_rows,errors.blocking_errors,
       CASE WHEN ctx.run_status='M1_3_ACCEPTED' AND ctx.population_status='M1_2_ACCEPTED'
        AND gates.g1_status='PASS' AND gates.m12_status='PASS' AND gates.m13_status='PASS'
        AND ctx.parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
        AND ctx.profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
        AND ctx.source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3'
        AND ctx.population_hash='9b706c926260a3ef1ae8ac95eed5d0bf'
        AND ctx.parameter_snapshot_hash=g1_hashes.parameter_hash AND ctx.profile_snapshot_hash=g1_hashes.profile_hash
        AND ctx.source_snapshot_hash=g1_hashes.source_hash AND ctx.population_hash=pop_hash.population_hash
        AND app_obs.applications=750 AND app_obs.merchants=750
        AND canonical.expected_rows=750 AND canonical.actual_rows=750 AND canonical.mismatches=0
        AND canonical.stored_hash=canonical.expected_hash AND canonical.actual_hash=canonical.expected_hash
        AND evidence_obs.positive_checks=42 AND evidence_obs.positive_passes=42
        AND evidence_obs.negative_controls=3 AND evidence_obs.negative_passes=3 AND evidence_obs.failed_evidence=0
        AND diagnostics.on_or_below_path_rows>0 AND diagnostics.above_path_rows>0
        AND downstream.rows=0 AND errors.blocking_errors=0
       THEN 'PASS' ELSE 'FAIL' END AS overall_m1_3_status
FROM ctx CROSS JOIN g1_hashes CROSS JOIN pop_hash CROSS JOIN gates CROSS JOIN app_obs CROSS JOIN canonical
CROSS JOIN evidence_obs CROSS JOIN diagnostics CROSS JOIN downstream CROSS JOIN errors;
