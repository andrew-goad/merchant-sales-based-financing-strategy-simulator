/**********************************************************************
MSBF M1.4 Enterprise Merchant Ecosystem Master Report
Version : v0.2
Purpose : One-row live-execution and acceptance report for deterministic
          daily POS and processor-settlement history.
**********************************************************************/
WITH ctx AS (
 SELECT r.*,p.population_status,p.population_hash,p.population_version,p.merchant_count,
        p.deterministic_seed_version,p.history_start_date,p.history_end_date,
        (p.history_end_date-p.history_start_date+1)::integer AS history_days
 FROM msbf_ctl.run_registry r
 JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
 WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
), g1_hashes AS (
 SELECT
  (SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key))
   FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS parameter_hash,
  (SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code))
   FROM msbf_ctl.run_profile_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS profile_hash,
  (SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code))
   FROM msbf_ctl.run_source_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS source_hash
), population_hash AS (
 SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) AS recomputed_hash
 FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM ctx))
), application_hash AS (
 SELECT
  (SELECT metric_value_text FROM msbf_ctl.run_evidence
   WHERE run_id=(SELECT run_id FROM ctx) AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') AS stored_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
   FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM ctx))) AS recomputed_hash
), gates AS (
 SELECT
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1) AS g1_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1) AS m12_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) AS m13_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_4_DAILY_POS_HISTORY' ORDER BY review_version DESC LIMIT 1) AS m14_status,
  (SELECT review_version FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_4_DAILY_POS_HISTORY' ORDER BY review_version DESC LIMIT 1) AS m14_review_version,
  (SELECT reviewed_at FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_4_DAILY_POS_HISTORY' ORDER BY review_version DESC LIMIT 1) AS m14_reviewed_at,
  (SELECT finding FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_4_DAILY_POS_HISTORY' ORDER BY review_version DESC LIMIT 1) AS m14_finding
), pos_obs AS (
 SELECT COUNT(*) AS pos_rows,COUNT(DISTINCT merchant_id) AS merchants,COUNT(DISTINCT observation_date) AS dates,
        MIN(observation_date) AS minimum_date,MAX(observation_date) AS maximum_date,
        SUM(gross_pos_sales) AS gross_pos_sales,SUM(eligible_pos_sales) AS eligible_pos_sales,
        SUM(settlement_amount) AS settlement_amount,SUM(processor_fee_amount) AS processor_fees,
        SUM(net_merchant_proceeds) AS net_merchant_proceeds,
        COUNT(*) FILTER(WHERE zero_sales_day_flag) AS zero_sales_rows,
        COUNT(*) FILTER(WHERE processor_status='OUTAGE') AS outage_rows,
        COUNT(*) FILTER(WHERE processor_status='DEGRADED') AS degraded_rows,
        COUNT(*) FILTER(WHERE processor_status='NOT_YET_ACTIVE') AS pre_open_rows,
        COUNT(*) FILTER(WHERE processor_status='ACTIVE') AS active_rows,
        SUM(refund_amount)/NULLIF(SUM(gross_pos_sales),0) AS refund_rate,
        SUM(chargeback_amount)/NULLIF(SUM(gross_pos_sales),0) AS chargeback_rate,
        SUM(reversal_amount)/NULLIF(SUM(gross_pos_sales),0) AS reversal_rate
 FROM msbf_m1.merchant_pos_daily_base
 WHERE generated_by_run_id=(SELECT run_id FROM ctx)
), canonical AS (
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.m1_4_expected_pos_snapshot((SELECT run_id FROM ctx))) AS expected_rows,
  (SELECT COUNT(*) FROM msbf_m1.m1_4_actual_pos_snapshot((SELECT run_id FROM ctx))) AS actual_rows,
  (SELECT COUNT(*) FROM msbf_m1.m1_4_expected_pos_snapshot((SELECT run_id FROM ctx)) e
    FULL JOIN msbf_m1.m1_4_actual_pos_snapshot((SELECT run_id FROM ctx)) a USING(entity_key)
    WHERE e.row_hash IS DISTINCT FROM a.row_hash) AS mismatches,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
   FROM msbf_m1.m1_4_expected_pos_snapshot((SELECT run_id FROM ctx))) AS expected_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
   FROM msbf_m1.m1_4_actual_pos_snapshot((SELECT run_id FROM ctx))) AS actual_hash,
  (SELECT metric_value_text FROM msbf_ctl.run_evidence
   WHERE run_id=(SELECT run_id FROM ctx) AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO') AS stored_hash
), evidence_obs AS (
 SELECT
  COUNT(*) FILTER(WHERE evidence_code ~ '^M1_4_POS_[0-9]{2}_') AS positive_checks,
  COUNT(*) FILTER(WHERE evidence_code ~ '^M1_4_POS_[0-9]{2}_' AND status='PASS') AS positive_passes,
  COUNT(*) FILTER(WHERE evidence_code LIKE 'M1_4_NEG_%') AS negative_controls,
  COUNT(*) FILTER(WHERE evidence_code LIKE 'M1_4_NEG_%' AND status='PASS') AS negative_passes,
  COUNT(*) FILTER(WHERE (evidence_code ~ '^M1_4_POS_[0-9]{2}_' OR evidence_code LIKE 'M1_4_NEG_%') AND status='FAIL') AS failed_evidence
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM ctx)
), blueprint_diag AS (
 SELECT COUNT(DISTINCT industry_code) AS industries,COUNT(DISTINCT cashflow_archetype_code) AS archetypes,
        COUNT(DISTINCT merchant_id) FILTER(WHERE cashflow_archetype_code='STABLE') AS stable_merchants,
        COUNT(DISTINCT merchant_id) FILTER(WHERE cashflow_archetype_code='GROWING') AS growing_merchants,
        COUNT(DISTINCT merchant_id) FILTER(WHERE cashflow_archetype_code='DECLINING') AS declining_merchants,
        COUNT(DISTINCT merchant_id) FILTER(WHERE cashflow_archetype_code='SEASONAL') AS seasonal_merchants,
        COUNT(DISTINCT merchant_id) FILTER(WHERE cashflow_archetype_code='VOLATILE') AS volatile_merchants,
        COUNT(DISTINCT merchant_id) FILTER(WHERE cashflow_archetype_code='RECENT_DISRUPTION') AS disrupted_merchants,
        COUNT(DISTINCT merchant_id) FILTER(WHERE cashflow_archetype_code='THIN_HISTORY') AS thin_history_merchants,
        COUNT(*) FILTER(WHERE operating_event_code='CALENDAR_EFFECT') AS calendar_effect_rows,
        COUNT(*) FILTER(WHERE operating_event_code='RECENT_DISRUPTION') AS disruption_event_rows,
        COUNT(*) FILTER(WHERE operating_event_code='BOUNDED_DEMAND_SHOCK') AS demand_shock_rows,
        COUNT(*) FILTER(WHERE operating_event_code='EXPANSION_STEP_UP') AS expansion_rows
 FROM msbf_m1.m1_4_daily_pos_blueprint((SELECT run_id FROM ctx))
), downstream AS (
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM ctx))
 +(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM ctx)) AS downstream_rows
), errors AS (
 SELECT COUNT(*) AS blocking_errors FROM msbf_ctl.profile_resolution_error
 WHERE run_id=(SELECT run_id FROM ctx) AND severity='BLOCKING'
)
SELECT
 clock_timestamp() AS report_timestamp,current_database() AS database_name,current_user AS database_user,
 current_setting('server_version') AS postgresql_version,
 ctx.run_id,ctx.run_code,ctx.run_version,ctx.run_status,ctx.as_of_date,ctx.population_id,
 ctx.population_version,ctx.population_status,ctx.merchant_count AS planned_merchants,
 ctx.history_start_date,ctx.history_end_date,ctx.history_days,ctx.deterministic_seed_version,
 ctx.parameter_snapshot_hash,g1_hashes.parameter_hash AS recomputed_parameter_hash,
 ctx.profile_snapshot_hash,g1_hashes.profile_hash AS recomputed_profile_hash,
 ctx.source_snapshot_hash,g1_hashes.source_hash AS recomputed_source_hash,
 ctx.population_hash,population_hash.recomputed_hash AS recomputed_population_hash,
 application_hash.stored_hash AS application_set_hash,application_hash.recomputed_hash AS recomputed_application_hash,
 gates.g1_status,gates.m12_status,gates.m13_status,gates.m14_status,gates.m14_review_version,gates.m14_reviewed_at,gates.m14_finding,
 pos_obs.pos_rows,pos_obs.merchants,pos_obs.dates,pos_obs.minimum_date,pos_obs.maximum_date,
 pos_obs.gross_pos_sales,pos_obs.eligible_pos_sales,pos_obs.settlement_amount,pos_obs.processor_fees,pos_obs.net_merchant_proceeds,
 pos_obs.zero_sales_rows,pos_obs.outage_rows,pos_obs.degraded_rows,pos_obs.pre_open_rows,pos_obs.active_rows,
 round(pos_obs.zero_sales_rows::numeric/NULLIF(pos_obs.pos_rows,0),8) AS zero_sales_share,
 round(pos_obs.outage_rows::numeric/NULLIF(pos_obs.pos_rows,0),8) AS outage_share,
 round(pos_obs.degraded_rows::numeric/NULLIF(pos_obs.pos_rows,0),8) AS degraded_share,
 round(pos_obs.refund_rate,8) AS refund_rate,round(pos_obs.chargeback_rate,8) AS chargeback_rate,round(pos_obs.reversal_rate,8) AS reversal_rate,
 blueprint_diag.industries,blueprint_diag.archetypes,blueprint_diag.stable_merchants,blueprint_diag.growing_merchants,
 blueprint_diag.declining_merchants,blueprint_diag.seasonal_merchants,blueprint_diag.volatile_merchants,
 blueprint_diag.disrupted_merchants,blueprint_diag.thin_history_merchants,blueprint_diag.calendar_effect_rows,
 blueprint_diag.disruption_event_rows,blueprint_diag.demand_shock_rows,blueprint_diag.expansion_rows,
 canonical.expected_rows,canonical.actual_rows,canonical.mismatches,canonical.stored_hash AS stored_pos_set_hash,
 canonical.expected_hash AS expected_pos_set_hash,canonical.actual_hash AS actual_pos_set_hash,
 evidence_obs.positive_checks,evidence_obs.positive_passes,evidence_obs.negative_controls,evidence_obs.negative_passes,evidence_obs.failed_evidence,
 downstream.downstream_rows,errors.blocking_errors,
 CASE WHEN
   ctx.run_status='M1_4_ACCEPTED' AND gates.g1_status='PASS' AND gates.m12_status='PASS' AND gates.m13_status='PASS' AND gates.m14_status='PASS'
   AND ctx.parameter_snapshot_hash=g1_hashes.parameter_hash AND ctx.profile_snapshot_hash=g1_hashes.profile_hash
   AND ctx.source_snapshot_hash=g1_hashes.source_hash AND ctx.population_hash=population_hash.recomputed_hash
   AND application_hash.stored_hash=application_hash.recomputed_hash
   AND pos_obs.pos_rows=135000 AND pos_obs.merchants=750 AND pos_obs.dates=180
   AND pos_obs.minimum_date=ctx.history_start_date AND pos_obs.maximum_date=ctx.history_end_date
   AND canonical.expected_rows=135000 AND canonical.actual_rows=135000 AND canonical.mismatches=0
   AND canonical.stored_hash IS NOT NULL AND canonical.stored_hash=canonical.expected_hash AND canonical.stored_hash=canonical.actual_hash
   AND evidence_obs.positive_checks=52 AND evidence_obs.positive_passes=52
   AND evidence_obs.negative_controls=4 AND evidence_obs.negative_passes=4 AND evidence_obs.failed_evidence=0
   AND downstream.downstream_rows=0 AND errors.blocking_errors=0
 THEN 'PASS' ELSE 'FAIL' END AS overall_m1_4_status
FROM ctx CROSS JOIN g1_hashes CROSS JOIN population_hash CROSS JOIN application_hash CROSS JOIN gates
CROSS JOIN pos_obs CROSS JOIN canonical CROSS JOIN evidence_obs CROSS JOIN blueprint_diag CROSS JOIN downstream CROSS JOIN errors;
