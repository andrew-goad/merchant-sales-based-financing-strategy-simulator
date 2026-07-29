/**********************************************************************
MSBF M1.5 Daily Deposit & Liquidity History Master Report
Version : v0.2
Purpose : One-row live-execution and acceptance report for deterministic
          operating-account deposits, withdrawals, balances, NSF events,
          existing-financing pressure, and liquidity evidence.
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
), pos_hash AS (
 SELECT
  (SELECT metric_value_text FROM msbf_ctl.run_evidence
   WHERE run_id=(SELECT run_id FROM ctx) AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO') AS stored_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
   FROM msbf_m1.m1_4_actual_pos_snapshot((SELECT run_id FROM ctx))) AS recomputed_hash
), gates AS (
 SELECT
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1) AS g1_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1) AS m12_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) AS m13_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_4_DAILY_POS_HISTORY' ORDER BY review_version DESC LIMIT 1) AS m14_status,
  (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY' ORDER BY review_version DESC LIMIT 1) AS m15_status,
  (SELECT review_version FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY' ORDER BY review_version DESC LIMIT 1) AS m15_review_version,
  (SELECT reviewed_at FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY' ORDER BY review_version DESC LIMIT 1) AS m15_reviewed_at,
  (SELECT finding FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY' ORDER BY review_version DESC LIMIT 1) AS m15_finding
), deposit_obs AS (
 SELECT COUNT(*) AS deposit_rows,COUNT(DISTINCT merchant_id) AS merchants,COUNT(DISTINCT observation_date) AS dates,
        MIN(observation_date) AS minimum_date,MAX(observation_date) AS maximum_date,
        SUM(deposit_amount) AS deposits,SUM(withdrawal_amount) AS withdrawals,
        AVG(opening_balance) AS avg_opening_balance,AVG(closing_balance) AS avg_closing_balance,
        AVG(available_balance) AS avg_available_balance,MIN(minimum_balance) AS minimum_observed_balance,
        COUNT(*) FILTER(WHERE negative_balance_flag) AS negative_balance_rows,
        SUM(nsf_count) AS nsf_events,COUNT(*) FILTER(WHERE nsf_count>0) AS nsf_rows
 FROM msbf_m1.merchant_deposit_daily_base
 WHERE generated_by_run_id=(SELECT run_id FROM ctx)
), canonical AS (
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.m1_5_expected_deposit_snapshot((SELECT run_id FROM ctx))) AS expected_rows,
  (SELECT COUNT(*) FROM msbf_m1.m1_5_actual_deposit_snapshot((SELECT run_id FROM ctx))) AS actual_rows,
  (SELECT COUNT(*) FROM msbf_m1.m1_5_expected_deposit_snapshot((SELECT run_id FROM ctx)) e
    FULL JOIN msbf_m1.m1_5_actual_deposit_snapshot((SELECT run_id FROM ctx)) a USING(entity_key)
    WHERE e.row_hash IS DISTINCT FROM a.row_hash) AS mismatches,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
   FROM msbf_m1.m1_5_expected_deposit_snapshot((SELECT run_id FROM ctx))) AS expected_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
   FROM msbf_m1.m1_5_actual_deposit_snapshot((SELECT run_id FROM ctx))) AS actual_hash,
  (SELECT metric_value_text FROM msbf_ctl.run_evidence
   WHERE run_id=(SELECT run_id FROM ctx) AND evidence_code='M1_5_DEPOSIT_SET_HASH' AND segment_key='PORTFOLIO') AS stored_hash
), evidence_obs AS (
 SELECT
  COUNT(*) FILTER(WHERE evidence_code ~ '^M1_5_POS_[0-9]{2}_') AS positive_checks,
  COUNT(*) FILTER(WHERE evidence_code ~ '^M1_5_POS_[0-9]{2}_' AND status='PASS') AS positive_passes,
  COUNT(*) FILTER(WHERE evidence_code LIKE 'M1_5_NEG_%') AS negative_controls,
  COUNT(*) FILTER(WHERE evidence_code LIKE 'M1_5_NEG_%' AND status='PASS') AS negative_passes,
  COUNT(*) FILTER(WHERE (evidence_code ~ '^M1_5_POS_[0-9]{2}_' OR evidence_code LIKE 'M1_5_NEG_%') AND status='FAIL') AS failed_evidence
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM ctx)
), blueprint_diag AS (
 SELECT COUNT(DISTINCT industry_code) AS industries,COUNT(DISTINCT cashflow_archetype_code) AS archetypes,
        COUNT(DISTINCT liquidity_risk_tier) AS liquidity_tiers,
        COUNT(DISTINCT merchant_id) FILTER(WHERE NOT deposit_source_available_flag) AS source_missing_merchants,
        COUNT(DISTINCT merchant_id) FILTER(WHERE active_financing_flag) AS active_financing_merchants,
        COUNT(*) FILTER(WHERE existing_financing_remittance_amount>0) AS financing_remittance_rows,
        SUM(existing_financing_remittance_amount) AS financing_remittance_amount,
        COUNT(*) FILTER(WHERE non_pos_support_deposit_amount>0) AS support_deposit_rows,
        SUM(non_pos_support_deposit_amount) AS support_deposit_amount,
        COUNT(DISTINCT liquidity_event_code) AS liquidity_event_types
 FROM msbf_m1.m1_5_daily_liquidity_blueprint((SELECT run_id FROM ctx))
), downstream AS (
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx))
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
 gates.g1_status,gates.m12_status,gates.m13_status,gates.m14_status,gates.m15_status,
 gates.m15_review_version,gates.m15_reviewed_at,gates.m15_finding,
 ctx.parameter_snapshot_hash,g1_hashes.parameter_hash AS recomputed_parameter_hash,
 ctx.profile_snapshot_hash,g1_hashes.profile_hash AS recomputed_profile_hash,
 ctx.source_snapshot_hash,g1_hashes.source_hash AS recomputed_source_hash,
 ctx.population_hash,population_hash.recomputed_hash AS recomputed_population_hash,
 application_hash.stored_hash AS application_set_hash,application_hash.recomputed_hash AS recomputed_application_hash,
 pos_hash.stored_hash AS pos_history_set_hash,pos_hash.recomputed_hash AS recomputed_pos_hash,
 canonical.stored_hash AS deposit_history_set_hash,canonical.expected_hash,canonical.actual_hash,
 canonical.expected_rows,canonical.actual_rows,canonical.mismatches,
 deposit_obs.deposit_rows,deposit_obs.merchants,deposit_obs.dates,deposit_obs.minimum_date,deposit_obs.maximum_date,
 round(deposit_obs.deposits,2) AS total_deposits,round(deposit_obs.withdrawals,2) AS total_withdrawals,
 round(deposit_obs.withdrawals/NULLIF(deposit_obs.deposits,0),8) AS withdrawal_to_deposit_ratio,
 round(deposit_obs.avg_opening_balance,2) AS avg_opening_balance,
 round(deposit_obs.avg_closing_balance,2) AS avg_closing_balance,
 round(deposit_obs.avg_available_balance,2) AS avg_available_balance,
 deposit_obs.minimum_observed_balance,deposit_obs.negative_balance_rows,
 round(deposit_obs.negative_balance_rows::numeric/NULLIF(deposit_obs.deposit_rows,0),8) AS negative_balance_share,
 deposit_obs.nsf_events,deposit_obs.nsf_rows,
 round(deposit_obs.nsf_rows::numeric/NULLIF(deposit_obs.deposit_rows,0),8) AS nsf_row_share,
 blueprint_diag.industries,blueprint_diag.archetypes,blueprint_diag.liquidity_tiers,
 blueprint_diag.source_missing_merchants,blueprint_diag.active_financing_merchants,
 blueprint_diag.financing_remittance_rows,round(blueprint_diag.financing_remittance_amount,2) AS financing_remittance_amount,
 blueprint_diag.support_deposit_rows,round(blueprint_diag.support_deposit_amount,2) AS support_deposit_amount,
 blueprint_diag.liquidity_event_types,
 evidence_obs.positive_checks,evidence_obs.positive_passes,evidence_obs.negative_controls,evidence_obs.negative_passes,
 evidence_obs.failed_evidence,downstream.downstream_rows,errors.blocking_errors,
 CASE WHEN ctx.run_status='M1_5_ACCEPTED' AND ctx.population_status='M1_2_ACCEPTED'
           AND gates.g1_status='PASS' AND gates.m12_status='PASS' AND gates.m13_status='PASS'
           AND gates.m14_status='PASS' AND gates.m15_status='PASS'
           AND ctx.parameter_snapshot_hash=g1_hashes.parameter_hash
           AND ctx.profile_snapshot_hash=g1_hashes.profile_hash
           AND ctx.source_snapshot_hash=g1_hashes.source_hash
           AND ctx.population_hash=population_hash.recomputed_hash
           AND application_hash.stored_hash=application_hash.recomputed_hash
           AND pos_hash.stored_hash=pos_hash.recomputed_hash
           AND canonical.stored_hash=canonical.expected_hash AND canonical.stored_hash=canonical.actual_hash
           AND canonical.expected_rows=135000 AND canonical.actual_rows=135000 AND canonical.mismatches=0
           AND deposit_obs.deposit_rows=135000 AND deposit_obs.merchants=750 AND deposit_obs.dates=180
           AND evidence_obs.positive_checks=56 AND evidence_obs.positive_passes=56
           AND evidence_obs.negative_controls=4 AND evidence_obs.negative_passes=4
           AND evidence_obs.failed_evidence=0 AND downstream.downstream_rows=0 AND errors.blocking_errors=0
      THEN 'PASS' ELSE 'FAIL' END AS overall_m1_5_status
FROM ctx CROSS JOIN g1_hashes CROSS JOIN population_hash CROSS JOIN application_hash CROSS JOIN pos_hash
CROSS JOIN gates CROSS JOIN deposit_obs CROSS JOIN canonical CROSS JOIN evidence_obs CROSS JOIN blueprint_diag
CROSS JOIN downstream CROSS JOIN errors;
