/* ============================================================================
MSBF M1.6 Matched POS and Deposit Scenario Overlays — Positive Validation
Version : v0.2
Purpose : Validate scenario registration, exact matched grain, baseline-copy
          controls, direct/propagated shock behavior, accounting identities,
          deterministic reproduction, scenario deltas, and stage boundaries.
============================================================================ */
BEGIN;

DO $do$
DECLARE v_run_id bigint; v_status text;
BEGIN
 SELECT run_id,run_status INTO STRICT v_run_id,v_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 IF v_status='M1_6_ACCEPTED' THEN RAISE EXCEPTION 'M1.6 is already accepted; validation evidence is frozen.'; END IF;
 IF v_status NOT IN ('M1_6_GENERATED','M1_6_VALIDATED','M1_6_FAILED') THEN
  RAISE EXCEPTION 'M1.6 validation requires generated scenario histories; observed run_status=%.',v_status;
 END IF;
 DELETE FROM msbf_ctl.run_evidence WHERE run_id=v_run_id AND evidence_code ~ '^M1_6_POS_[0-9]{2}_';
END $do$;

CREATE TEMP TABLE _m1_6_ctx ON COMMIT DROP AS
SELECT r.run_id,r.run_status,r.population_id,r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,
       p.population_status,p.population_hash,p.history_start_date,p.history_end_date,(p.history_end_date-p.history_start_date+1)::integer AS history_days,
       (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot
        WHERE run_id=r.run_id AND parameter_name='qa_reconciliation_tolerance_amount' AND scope_key='GLOBAL') AS tolerance,
       (SELECT (resolved_value->>'value_numeric')::numeric FROM msbf_ctl.run_parameter_snapshot
        WHERE run_id=r.run_id AND parameter_name='qa_min_scenario_matched_share' AND scope_key='GLOBAL') AS matched_share_min
FROM msbf_ctl.run_registry r JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

CREATE TEMP TABLE _m1_6_profile ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_6_scenario_profile((SELECT run_id FROM _m1_6_ctx));
CREATE INDEX ON _m1_6_profile(scenario_id);

CREATE TEMP TABLE _m1_6_pos_expected ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_6_pos_scenario_blueprint((SELECT run_id FROM _m1_6_ctx));
CREATE INDEX ON _m1_6_pos_expected(scenario_id,merchant_id,observation_date);

CREATE TEMP TABLE _m1_6_deposit_expected ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_6_deposit_scenario_blueprint((SELECT run_id FROM _m1_6_ctx));
CREATE INDEX ON _m1_6_deposit_expected(scenario_id,merchant_id,observation_date);

CREATE TEMP TABLE _m1_6_checks(
 evidence_code text PRIMARY KEY,metric_name text NOT NULL,observed_value text NOT NULL,
 expected_value text NOT NULL,pass_flag boolean NOT NULL,interpretation text NOT NULL
) ON COMMIT DROP;

/* 01 — stage status */
INSERT INTO _m1_6_checks
SELECT 'M1_6_POS_01_RUN_STAGE_STATUS','Run stage status',run_status,
 'M1_6_GENERATED or M1_6_VALIDATED or M1_6_FAILED',run_status IN ('M1_6_GENERATED','M1_6_VALIDATED','M1_6_FAILED'),
 'Scenario rows must exist before validation.' FROM _m1_6_ctx;

/* 02–06 — prerequisite gates */
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_02_G1_GATE','Latest G1 gate status',COALESCE(result_status,'MISSING'),'PASS',COALESCE(result_status='PASS',false),'M1.6 remains dependent on accepted governed configuration.' FROM (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1) q;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_03_M1_2_GATE','Latest M1.2 gate status',COALESCE(result_status,'MISSING'),'PASS',COALESCE(result_status='PASS',false),'Scenario histories preserve the accepted merchant universe.' FROM (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1) q;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_04_M1_3_GATE','Latest M1.3 gate status',COALESCE(result_status,'MISSING'),'PASS',COALESCE(result_status='PASS',false),'Scenario histories preserve accepted applications.' FROM (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) q;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_05_M1_4_GATE','Latest M1.4 gate status',COALESCE(result_status,'MISSING'),'PASS',COALESCE(result_status='PASS',false),'Scenario overlays are anchored to accepted POS history.' FROM (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND gate_id='M1_4_DAILY_POS_HISTORY' ORDER BY review_version DESC LIMIT 1) q;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_06_M1_5_GATE','Latest M1.5 gate status',COALESCE(result_status,'MISSING'),'PASS',COALESCE(result_status='PASS',false),'Scenario overlays are anchored to accepted deposit history.' FROM (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY' ORDER BY review_version DESC LIMIT 1) q;

/* 07 — accepted G1 hashes */
INSERT INTO _m1_6_checks
SELECT 'M1_6_POS_07_ACCEPTED_G1_HASHES','Accepted G1 hashes',parameter_snapshot_hash||'|'||profile_snapshot_hash||'|'||source_snapshot_hash,
 'bd09e598c82db96e47459d77fd11e7c8|462cbd2ed92f68e5bdecf6b17537a973|93c3d1368fb2450ab4a08e2b721f92d3',
 parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8' AND profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973' AND source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3',
 'M1.6 must not alter accepted parameter, profile, or source snapshots.' FROM _m1_6_ctx;

/* 08 — recomputed G1 hashes */
INSERT INTO _m1_6_checks
WITH h AS (
 SELECT
  (SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key)) FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM _m1_6_ctx)) ph,
  (SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code)) FROM msbf_ctl.run_profile_snapshot WHERE run_id=(SELECT run_id FROM _m1_6_ctx)) prh,
  (SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code)) FROM msbf_ctl.run_source_snapshot WHERE run_id=(SELECT run_id FROM _m1_6_ctx)) sh)
SELECT 'M1_6_POS_08_RECOMPUTED_G1_HASHES','Recomputed G1 hashes',h.ph||'|'||h.prh||'|'||h.sh,
 c.parameter_snapshot_hash||'|'||c.profile_snapshot_hash||'|'||c.source_snapshot_hash,
 h.ph=c.parameter_snapshot_hash AND h.prh=c.profile_snapshot_hash AND h.sh=c.source_snapshot_hash,
 'Frozen G1 content independently reconciles.' FROM _m1_6_ctx c CROSS JOIN h;

/* 09–12 — upstream set hashes */
INSERT INTO _m1_6_checks
WITH x AS (SELECT population_hash,(SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM _m1_6_ctx))) recomputed FROM _m1_6_ctx)
SELECT 'M1_6_POS_09_POPULATION_HASH','Accepted population hash',population_hash,'9b706c926260a3ef1ae8ac95eed5d0bf',population_hash='9b706c926260a3ef1ae8ac95eed5d0bf' AND population_hash=recomputed,'Scenario histories retain the accepted population.' FROM x;
INSERT INTO _m1_6_checks
WITH x AS (SELECT (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') stored,(SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM _m1_6_ctx))) recomputed)
SELECT 'M1_6_POS_10_APPLICATION_HASH','Accepted application hash',stored,'01485256b9b5748fb412743d35ced602',stored='01485256b9b5748fb412743d35ced602' AND stored=recomputed,'Scenario generation does not modify applications.' FROM x;
INSERT INTO _m1_6_checks
WITH x AS (SELECT (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO') stored,(SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_4_actual_pos_snapshot((SELECT run_id FROM _m1_6_ctx))) recomputed)
SELECT 'M1_6_POS_11_BASE_POS_HASH','Accepted baseline POS hash',stored,'d1971e8d319483c187ec0c0483a31e33',stored='d1971e8d319483c187ec0c0483a31e33' AND stored=recomputed,'Scenario overlays retain the accepted baseline POS history.' FROM x;
INSERT INTO _m1_6_checks
WITH x AS (SELECT (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND evidence_code='M1_5_DEPOSIT_SET_HASH' AND segment_key='PORTFOLIO') stored,(SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_5_actual_deposit_snapshot((SELECT run_id FROM _m1_6_ctx))) recomputed)
SELECT 'M1_6_POS_12_BASE_DEPOSIT_HASH','Accepted baseline deposit hash',stored,'bbe96dd24fbbba3af4a587dd475a88d0',stored='bbe96dd24fbbba3af4a587dd475a88d0' AND stored=recomputed,'Scenario overlays retain the accepted baseline deposit history.' FROM x;

/* 13 — generation specification hash */
INSERT INTO _m1_6_checks
WITH s AS (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND evidence_code='M1_6_SCENARIO_SPEC' AND segment_key='PORTFOLIO'),
 h AS (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND evidence_code='M1_6_SCENARIO_SPEC_HASH' AND segment_key='PORTFOLIO')
SELECT 'M1_6_POS_13_SCENARIO_SPEC_HASH','Scenario specification hash',COALESCE(h.metric_value_text,'MISSING'),COALESCE(md5((s.metric_value_text::jsonb)::text),'MISSING'),h.metric_value_text=md5((s.metric_value_text::jsonb)::text),'Scenario assumptions and industry-network weights are frozen and hash-reconciled.' FROM s FULL JOIN h ON true;

/* 14–17 — scenario registration and parameter controls */
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_14_SCENARIO_COUNT','Approved scenario count',COUNT(*)::text,'2',COUNT(*)=2,'Exactly two matched scenarios are used.' FROM _m1_6_profile;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_15_SCENARIO_CODES','Scenario codes',string_agg(scenario_code,',' ORDER BY scenario_code),'BASELINE,RECESSION_ENERGY',string_agg(scenario_code,',' ORDER BY scenario_code)='BASELINE,RECESSION_ENERGY','The controlled scenario family contains the reference and recession/energy sensitivity.' FROM _m1_6_profile;
INSERT INTO _m1_6_checks
WITH req(parameter_name,scope_key) AS (VALUES
 ('enable_scenario_history_flag','GLOBAL'),('scenario_direct_shock_cap','GLOBAL'),('scenario_propagated_shock_cap','GLOBAL'),('scenario_damping_factor','GLOBAL'),('scenario_lag_days','GLOBAL'),('qa_min_scenario_matched_share','GLOBAL'),('liquidity_shock_multiplier','GLOBAL'),('qa_reconciliation_tolerance_amount','GLOBAL'),
 ('scenario_sales_level_multiplier','SCENARIO:BASELINE'),('scenario_sales_volatility_multiplier','SCENARIO:BASELINE'),('scenario_zero_sales_probability_multiplier','SCENARIO:BASELINE'),('scenario_refund_rate_multiplier','SCENARIO:BASELINE'),('scenario_chargeback_rate_multiplier','SCENARIO:BASELINE'),('scenario_deposit_capture_multiplier','SCENARIO:BASELINE'),('scenario_obligation_multiplier','SCENARIO:BASELINE'),('scenario_processor_outage_rate','SCENARIO:BASELINE'),
 ('scenario_sales_level_multiplier','SCENARIO:RECESSION_ENERGY'),('scenario_sales_volatility_multiplier','SCENARIO:RECESSION_ENERGY'),('scenario_zero_sales_probability_multiplier','SCENARIO:RECESSION_ENERGY'),('scenario_refund_rate_multiplier','SCENARIO:RECESSION_ENERGY'),('scenario_chargeback_rate_multiplier','SCENARIO:RECESSION_ENERGY'),('scenario_deposit_capture_multiplier','SCENARIO:RECESSION_ENERGY'),('scenario_obligation_multiplier','SCENARIO:RECESSION_ENERGY'),('scenario_processor_outage_rate','SCENARIO:RECESSION_ENERGY'),
 ('industry_zero_sales_day_probability','INDUSTRY:RESTAURANT_FOOD_SERVICE'),('industry_zero_sales_day_probability','INDUSTRY:GENERAL_RETAIL'),('industry_zero_sales_day_probability','INDUSTRY:PROFESSIONAL_SERVICES'),('industry_zero_sales_day_probability','INDUSTRY:CONSTRUCTION_TRADES'),('industry_zero_sales_day_probability','INDUSTRY:TRANSPORTATION_LOGISTICS'),('industry_zero_sales_day_probability','INDUSTRY:ENERGY_SERVICES'),('industry_zero_sales_day_probability','INDUSTRY:HEALTHCARE_SERVICES'),('industry_zero_sales_day_probability','INDUSTRY:ECOMMERCE_DIGITAL')),
 x AS (SELECT COUNT(*) req_count,COUNT(rps.parameter_name) resolved_count FROM req LEFT JOIN msbf_ctl.run_parameter_snapshot rps ON rps.run_id=(SELECT run_id FROM _m1_6_ctx) AND rps.parameter_name=req.parameter_name AND rps.scope_key=req.scope_key)
SELECT 'M1_6_POS_16_PARAMETER_COMPLETENESS','Required scenario parameters',resolved_count::text||' of '||req_count::text,'32 of 32',resolved_count=32 AND req_count=32,'All scenario and industry parameters resolve exactly once.' FROM x;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_17_SCENARIO_HISTORY_ENABLED','Scenario history enabled',COALESCE(resolved_value->>'value_boolean','MISSING'),'true',COALESCE((resolved_value->>'value_boolean')::boolean,false),'Scenario persistence is authorized in the frozen run snapshot.' FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND parameter_name='enable_scenario_history_flag' AND scope_key='GLOBAL';

/* 18–27 — structural grain and coverage */
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_18_POS_TOTAL_ROWS','POS scenario total rows',COUNT(*)::text,'270000',COUNT(*)=270000,'Two scenarios preserve 135000 merchant-day rows each.' FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_19_DEPOSIT_TOTAL_ROWS','Deposit scenario total rows',COUNT(*)::text,'270000',COUNT(*)=270000,'Two scenarios preserve 135000 merchant-day rows each.' FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_20_POS_ROWS_PER_SCENARIO','POS rows per scenario',string_agg(scenario_code||'='||row_count::text,',' ORDER BY scenario_code),'BASELINE=135000,RECESSION_ENERGY=135000',bool_and(row_count=135000),'Every scenario contains the complete matched POS panel.' FROM (SELECT sr.scenario_code,COUNT(*) row_count FROM msbf_m1.merchant_pos_daily_scenario p JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=p.scenario_id WHERE p.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code) q;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_21_DEPOSIT_ROWS_PER_SCENARIO','Deposit rows per scenario',string_agg(scenario_code||'='||row_count::text,',' ORDER BY scenario_code),'BASELINE=135000,RECESSION_ENERGY=135000',bool_and(row_count=135000),'Every scenario contains the complete matched deposit panel.' FROM (SELECT sr.scenario_code,COUNT(*) row_count FROM msbf_m1.merchant_deposit_daily_scenario d JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=d.scenario_id WHERE d.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code) q;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_22_POS_MERCHANT_COVERAGE','POS merchants per scenario',string_agg(scenario_code||'='||merchant_count::text,',' ORDER BY scenario_code),'BASELINE=750,RECESSION_ENERGY=750',bool_and(merchant_count=750),'Merchant identity is preserved across scenarios.' FROM (SELECT sr.scenario_code,COUNT(DISTINCT p.merchant_id) merchant_count FROM msbf_m1.merchant_pos_daily_scenario p JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=p.scenario_id WHERE p.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code) q;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_23_DEPOSIT_MERCHANT_COVERAGE','Deposit merchants per scenario',string_agg(scenario_code||'='||merchant_count::text,',' ORDER BY scenario_code),'BASELINE=750,RECESSION_ENERGY=750',bool_and(merchant_count=750),'Deposit identity is preserved across scenarios.' FROM (SELECT sr.scenario_code,COUNT(DISTINCT d.merchant_id) merchant_count FROM msbf_m1.merchant_deposit_daily_scenario d JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=d.scenario_id WHERE d.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code) q;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_24_POS_DATE_COVERAGE','POS dates per scenario',string_agg(scenario_code||'='||date_count::text,',' ORDER BY scenario_code),'BASELINE=180,RECESSION_ENERGY=180',bool_and(date_count=180),'The accepted 180-day history is preserved.' FROM (SELECT sr.scenario_code,COUNT(DISTINCT p.observation_date) date_count FROM msbf_m1.merchant_pos_daily_scenario p JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=p.scenario_id WHERE p.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code) q;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_25_DEPOSIT_DATE_COVERAGE','Deposit dates per scenario',string_agg(scenario_code||'='||date_count::text,',' ORDER BY scenario_code),'BASELINE=180,RECESSION_ENERGY=180',bool_and(date_count=180),'The accepted 180-day history is preserved.' FROM (SELECT sr.scenario_code,COUNT(DISTINCT d.observation_date) date_count FROM msbf_m1.merchant_deposit_daily_scenario d JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=d.scenario_id WHERE d.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code) q;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_26_POS_UNIQUE_GRAIN','POS unique scenario grain',COUNT(*)::text||'|'||COUNT(DISTINCT (scenario_id,population_id,merchant_id,processor_account_id,observation_date))::text,'270000|270000',COUNT(*)=270000 AND COUNT(DISTINCT (scenario_id,population_id,merchant_id,processor_account_id,observation_date))=270000,'Scenario/POS grain is unique.' FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_27_DEPOSIT_UNIQUE_GRAIN','Deposit unique scenario grain',COUNT(*)::text||'|'||COUNT(DISTINCT (scenario_id,population_id,merchant_id,observation_date))::text,'270000|270000',COUNT(*)=270000 AND COUNT(DISTINCT (scenario_id,population_id,merchant_id,observation_date))=270000,'Scenario/deposit grain is unique.' FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);

/* 28–31 — lineage */
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_28_POS_BASE_HASH_LINEAGE','POS base-row hash lineage',COUNT(*) FILTER(WHERE b.row_hash IS NULL)::text,'0',COUNT(*) FILTER(WHERE b.row_hash IS NULL)=0,'Every scenario POS row points to the accepted baseline row hash.' FROM msbf_m1.merchant_pos_daily_scenario s LEFT JOIN msbf_m1.merchant_pos_daily_base b ON b.population_id=s.population_id AND b.merchant_id=s.merchant_id AND b.processor_account_id=s.processor_account_id AND b.observation_date=s.observation_date AND b.row_hash=s.base_row_hash WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_29_DEPOSIT_BASE_HASH_LINEAGE','Deposit base-row hash lineage',COUNT(*) FILTER(WHERE b.row_hash IS NULL)::text,'0',COUNT(*) FILTER(WHERE b.row_hash IS NULL)=0,'Every scenario deposit row points to the accepted baseline row hash.' FROM msbf_m1.merchant_deposit_daily_scenario s LEFT JOIN msbf_m1.merchant_deposit_daily_base b ON b.population_id=s.population_id AND b.merchant_id=s.merchant_id AND b.observation_date=s.observation_date AND b.row_hash=s.base_row_hash WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_30_POS_SOURCE_RUN_LINEAGE','POS source and run lineage',COUNT(*) FILTER(WHERE s.source_contract_id<>b.source_contract_id OR s.generated_by_run_id<>(SELECT run_id FROM _m1_6_ctx))::text,'0',COUNT(*) FILTER(WHERE s.source_contract_id<>b.source_contract_id OR s.generated_by_run_id<>(SELECT run_id FROM _m1_6_ctx))=0,'Scenario POS rows retain approved source and run identity.' FROM msbf_m1.merchant_pos_daily_scenario s JOIN msbf_m1.merchant_pos_daily_base b ON b.population_id=s.population_id AND b.merchant_id=s.merchant_id AND b.processor_account_id=s.processor_account_id AND b.observation_date=s.observation_date WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_31_DEPOSIT_SOURCE_RUN_LINEAGE','Deposit source and run lineage',COUNT(*) FILTER(WHERE s.source_contract_id<>b.source_contract_id OR s.generated_by_run_id<>(SELECT run_id FROM _m1_6_ctx))::text,'0',COUNT(*) FILTER(WHERE s.source_contract_id<>b.source_contract_id OR s.generated_by_run_id<>(SELECT run_id FROM _m1_6_ctx))=0,'Scenario deposit rows retain approved source and run identity.' FROM msbf_m1.merchant_deposit_daily_scenario s JOIN msbf_m1.merchant_deposit_daily_base b ON b.population_id=s.population_id AND b.merchant_id=s.merchant_id AND b.observation_date=s.observation_date WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);

/* 32–35 — baseline and pre-shock copy controls */
INSERT INTO _m1_6_checks
SELECT 'M1_6_POS_32_BASELINE_POS_COPY','BASELINE POS exact-copy violations',COUNT(*) FILTER(WHERE ROW(s.gross_pos_sales,s.transaction_count,s.average_ticket_amount,s.refund_amount,s.chargeback_amount,s.reversal_amount,s.governed_exclusion_amount,s.eligible_pos_sales,s.processor_fee_amount,s.settlement_amount,s.net_merchant_proceeds,s.zero_sales_day_flag,s.processor_status,s.data_connection_status) IS DISTINCT FROM ROW(b.gross_pos_sales,b.transaction_count,b.average_ticket_amount,b.refund_amount,b.chargeback_amount,b.reversal_amount,b.governed_exclusion_amount,b.eligible_pos_sales,b.processor_fee_amount,b.settlement_amount,b.net_merchant_proceeds,b.zero_sales_day_flag,b.processor_status,b.data_connection_status))::text,'0',COUNT(*) FILTER(WHERE ROW(s.gross_pos_sales,s.transaction_count,s.average_ticket_amount,s.refund_amount,s.chargeback_amount,s.reversal_amount,s.governed_exclusion_amount,s.eligible_pos_sales,s.processor_fee_amount,s.settlement_amount,s.net_merchant_proceeds,s.zero_sales_day_flag,s.processor_status,s.data_connection_status) IS DISTINCT FROM ROW(b.gross_pos_sales,b.transaction_count,b.average_ticket_amount,b.refund_amount,b.chargeback_amount,b.reversal_amount,b.governed_exclusion_amount,b.eligible_pos_sales,b.processor_fee_amount,b.settlement_amount,b.net_merchant_proceeds,b.zero_sales_day_flag,b.processor_status,b.data_connection_status))=0,'The BASELINE scenario exactly reproduces accepted POS values.' FROM msbf_m1.merchant_pos_daily_scenario s JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id JOIN msbf_m1.merchant_pos_daily_base b ON b.population_id=s.population_id AND b.merchant_id=s.merchant_id AND b.processor_account_id=s.processor_account_id AND b.observation_date=s.observation_date WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) AND sr.scenario_code='BASELINE';
INSERT INTO _m1_6_checks
SELECT 'M1_6_POS_33_BASELINE_DEPOSIT_COPY','BASELINE deposit exact-copy violations',COUNT(*) FILTER(WHERE ROW(s.opening_balance,s.deposit_amount,s.withdrawal_amount,s.closing_balance,s.available_balance,s.minimum_balance,s.nsf_count,s.negative_balance_flag) IS DISTINCT FROM ROW(b.opening_balance,b.deposit_amount,b.withdrawal_amount,b.closing_balance,b.available_balance,b.minimum_balance,b.nsf_count,b.negative_balance_flag))::text,'0',COUNT(*) FILTER(WHERE ROW(s.opening_balance,s.deposit_amount,s.withdrawal_amount,s.closing_balance,s.available_balance,s.minimum_balance,s.nsf_count,s.negative_balance_flag) IS DISTINCT FROM ROW(b.opening_balance,b.deposit_amount,b.withdrawal_amount,b.closing_balance,b.available_balance,b.minimum_balance,b.nsf_count,b.negative_balance_flag))=0,'The BASELINE scenario exactly reproduces accepted deposit values.' FROM msbf_m1.merchant_deposit_daily_scenario s JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id JOIN msbf_m1.merchant_deposit_daily_base b ON b.population_id=s.population_id AND b.merchant_id=s.merchant_id AND b.observation_date=s.observation_date WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) AND sr.scenario_code='BASELINE';
INSERT INTO _m1_6_checks
SELECT 'M1_6_POS_34_STRESS_PRE_SHOCK_POS_COPY','Stress pre-shock POS copy violations',COUNT(*) FILTER(WHERE ROW(s.gross_pos_sales,s.transaction_count,s.average_ticket_amount,s.refund_amount,s.chargeback_amount,s.reversal_amount,s.governed_exclusion_amount,s.eligible_pos_sales,s.processor_fee_amount,s.settlement_amount,s.net_merchant_proceeds,s.zero_sales_day_flag,s.processor_status,s.data_connection_status) IS DISTINCT FROM ROW(b.gross_pos_sales,b.transaction_count,b.average_ticket_amount,b.refund_amount,b.chargeback_amount,b.reversal_amount,b.governed_exclusion_amount,b.eligible_pos_sales,b.processor_fee_amount,b.settlement_amount,b.net_merchant_proceeds,b.zero_sales_day_flag,b.processor_status,b.data_connection_status))::text,'0',COUNT(*) FILTER(WHERE ROW(s.gross_pos_sales,s.transaction_count,s.average_ticket_amount,s.refund_amount,s.chargeback_amount,s.reversal_amount,s.governed_exclusion_amount,s.eligible_pos_sales,s.processor_fee_amount,s.settlement_amount,s.net_merchant_proceeds,s.zero_sales_day_flag,s.processor_status,s.data_connection_status) IS DISTINCT FROM ROW(b.gross_pos_sales,b.transaction_count,b.average_ticket_amount,b.refund_amount,b.chargeback_amount,b.reversal_amount,b.governed_exclusion_amount,b.eligible_pos_sales,b.processor_fee_amount,b.settlement_amount,b.net_merchant_proceeds,b.zero_sales_day_flag,b.processor_status,b.data_connection_status))=0,'Stress rows before the governed shock date retain the accepted POS baseline.' FROM msbf_m1.merchant_pos_daily_scenario s JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id JOIN _m1_6_profile p ON p.scenario_id=s.scenario_id JOIN msbf_m1.merchant_pos_daily_base b ON b.population_id=s.population_id AND b.merchant_id=s.merchant_id AND b.processor_account_id=s.processor_account_id AND b.observation_date=s.observation_date WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) AND sr.scenario_code='RECESSION_ENERGY' AND s.observation_date<p.shock_start_date;
INSERT INTO _m1_6_checks
SELECT 'M1_6_POS_35_STRESS_PRE_SHOCK_DEPOSIT_COPY','Stress pre-shock deposit copy violations',COUNT(*) FILTER(WHERE ROW(s.opening_balance,s.deposit_amount,s.withdrawal_amount,s.closing_balance,s.available_balance,s.minimum_balance,s.nsf_count,s.negative_balance_flag) IS DISTINCT FROM ROW(b.opening_balance,b.deposit_amount,b.withdrawal_amount,b.closing_balance,b.available_balance,b.minimum_balance,b.nsf_count,b.negative_balance_flag))::text,'0',COUNT(*) FILTER(WHERE ROW(s.opening_balance,s.deposit_amount,s.withdrawal_amount,s.closing_balance,s.available_balance,s.minimum_balance,s.nsf_count,s.negative_balance_flag) IS DISTINCT FROM ROW(b.opening_balance,b.deposit_amount,b.withdrawal_amount,b.closing_balance,b.available_balance,b.minimum_balance,b.nsf_count,b.negative_balance_flag))=0,'Stress rows before the governed shock date retain the accepted deposit baseline.' FROM msbf_m1.merchant_deposit_daily_scenario s JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id JOIN _m1_6_profile p ON p.scenario_id=s.scenario_id JOIN msbf_m1.merchant_deposit_daily_base b ON b.population_id=s.population_id AND b.merchant_id=s.merchant_id AND b.observation_date=s.observation_date WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) AND sr.scenario_code='RECESSION_ENERGY' AND s.observation_date<p.shock_start_date;

/* 36–40 — overlay-window and factor controls */
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_36_DIRECT_WINDOW_ROWS','Stress direct-shock window rows',COUNT(*)::text,'45000',COUNT(*)=45000,'The governed direct shock spans the final 60 days for 750 merchants.' FROM _m1_6_pos_expected WHERE scenario_code='RECESSION_ENERGY' AND shock_active_flag;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_37_PROPAGATED_WINDOW_ROWS','Stress propagated-shock window rows',COUNT(*)::text,'39750',COUNT(*)=39750,'The seven-day propagation lag leaves 53 propagated days for 750 merchants.' FROM _m1_6_pos_expected WHERE scenario_code='RECESSION_ENERGY' AND propagation_active_flag;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_38_BASELINE_FACTORS','BASELINE shock-factor violations',COUNT(*) FILTER(WHERE direct_shock_factor<>1 OR propagated_shock_factor<>1)::text,'0',COUNT(*) FILTER(WHERE direct_shock_factor<>1 OR propagated_shock_factor<>1)=0,'The reference scenario contains no direct or propagated shock.' FROM msbf_m1.merchant_pos_daily_scenario s JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) AND sr.scenario_code='BASELINE';
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_39_STRESS_FACTOR_BOUNDS','Stress shock-factor bound violations',COUNT(*) FILTER(WHERE direct_shock_factor<0.40 OR direct_shock_factor>1 OR propagated_shock_factor<0.65 OR propagated_shock_factor>1)::text,'0',COUNT(*) FILTER(WHERE direct_shock_factor<0.40 OR direct_shock_factor>1 OR propagated_shock_factor<0.65 OR propagated_shock_factor>1)=0,'Direct and propagated factors remain inside governed caps.' FROM msbf_m1.merchant_pos_daily_scenario s JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) AND sr.scenario_code='RECESSION_ENERGY';
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_40_PAYLOAD_COMPLETENESS','Scenario payload-code violations',COUNT(*) FILTER(WHERE scenario_overlay_payload->>'scenario_code' IS DISTINCT FROM sr.scenario_code)::text,'0',COUNT(*) FILTER(WHERE scenario_overlay_payload->>'scenario_code' IS DISTINCT FROM sr.scenario_code)=0,'Every scenario row retains the correct scenario code in its overlay payload.' FROM msbf_m1.merchant_pos_daily_scenario s JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);

/* 41–44 — POS accounting and settlement */
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_41_POS_NONNEGATIVE','Negative POS amounts or counts',COUNT(*) FILTER(WHERE gross_pos_sales<0 OR transaction_count<0 OR average_ticket_amount<0 OR refund_amount<0 OR chargeback_amount<0 OR reversal_amount<0 OR governed_exclusion_amount<0 OR eligible_pos_sales<0 OR processor_fee_amount<0 OR settlement_amount<0 OR net_merchant_proceeds<0)::text,'0',COUNT(*) FILTER(WHERE gross_pos_sales<0 OR transaction_count<0 OR average_ticket_amount<0 OR refund_amount<0 OR chargeback_amount<0 OR reversal_amount<0 OR governed_exclusion_amount<0 OR eligible_pos_sales<0 OR processor_fee_amount<0 OR settlement_amount<0 OR net_merchant_proceeds<0)=0,'Scenario POS values remain nonnegative.' FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_42_POS_RECONCILIATION','POS eligible-sales reconciliation violations',COUNT(*) FILTER(WHERE abs(eligible_pos_sales-greatest(gross_pos_sales-refund_amount-chargeback_amount-reversal_amount-governed_exclusion_amount,0))>(SELECT tolerance FROM _m1_6_ctx))::text,'0',COUNT(*) FILTER(WHERE abs(eligible_pos_sales-greatest(gross_pos_sales-refund_amount-chargeback_amount-reversal_amount-governed_exclusion_amount,0))>(SELECT tolerance FROM _m1_6_ctx))=0,'Gross-to-eligible-sales identity reconciles.' FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_43_ZERO_SALES_FLAG','Zero-sales flag violations',COUNT(*) FILTER(WHERE zero_sales_day_flag<>(gross_pos_sales=0))::text,'0',COUNT(*) FILTER(WHERE zero_sales_day_flag<>(gross_pos_sales=0))=0,'Zero-sales flags match scenario gross sales.' FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);
INSERT INTO _m1_6_checks
WITH x AS (SELECT COUNT(*) violations FROM msbf_m1.merchant_pos_daily_scenario curr JOIN msbf_m1.processor_account pa ON pa.processor_account_id=curr.processor_account_id LEFT JOIN msbf_m1.merchant_pos_daily_scenario prior ON prior.scenario_id=curr.scenario_id AND prior.merchant_id=curr.merchant_id AND prior.processor_account_id=curr.processor_account_id AND prior.observation_date=curr.observation_date-pa.settlement_delay_days WHERE curr.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) AND abs(curr.settlement_amount-coalesce(prior.eligible_pos_sales,0))>(SELECT tolerance FROM _m1_6_ctx))
SELECT 'M1_6_POS_44_SETTLEMENT_LAG_REPRODUCTION','Settlement lag violations',violations::text,'0',violations=0,'Scenario settlements reproduce each processor account lag.' FROM x;

/* 45–50 — POS directional scenario deltas */
INSERT INTO _m1_6_checks
WITH a AS (SELECT sr.scenario_code,SUM(gross_pos_sales) total FROM msbf_m1.merchant_pos_daily_scenario s JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code)
SELECT 'M1_6_POS_45_STRESS_GROSS_DECLINE','Stress gross-sales direction',(SELECT total FROM a WHERE scenario_code='RECESSION_ENERGY')::text,(SELECT total FROM a WHERE scenario_code='BASELINE')::text,(SELECT total FROM a WHERE scenario_code='RECESSION_ENERGY')<(SELECT total FROM a WHERE scenario_code='BASELINE'),'The recession/energy scenario reduces aggregate gross sales.';
INSERT INTO _m1_6_checks
WITH a AS (SELECT sr.scenario_code,SUM(eligible_pos_sales) total FROM msbf_m1.merchant_pos_daily_scenario s JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code)
SELECT 'M1_6_POS_46_STRESS_ELIGIBLE_DECLINE','Stress eligible-sales direction',(SELECT total FROM a WHERE scenario_code='RECESSION_ENERGY')::text,(SELECT total FROM a WHERE scenario_code='BASELINE')::text,(SELECT total FROM a WHERE scenario_code='RECESSION_ENERGY')<(SELECT total FROM a WHERE scenario_code='BASELINE'),'The stress scenario reduces eligible merchant sales.';
INSERT INTO _m1_6_checks
WITH a AS (SELECT sr.scenario_code,SUM(refund_amount)/NULLIF(SUM(gross_pos_sales),0) rate FROM msbf_m1.merchant_pos_daily_scenario s JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code)
SELECT 'M1_6_POS_47_REFUND_RATE_DIRECTION','Scenario refund-rate direction',(SELECT rate FROM a WHERE scenario_code='RECESSION_ENERGY')::text,(SELECT rate FROM a WHERE scenario_code='BASELINE')::text,(SELECT rate FROM a WHERE scenario_code='RECESSION_ENERGY')>(SELECT rate FROM a WHERE scenario_code='BASELINE'),'Stress increases the aggregate refund-rate burden.';
INSERT INTO _m1_6_checks
WITH a AS (SELECT sr.scenario_code,SUM(chargeback_amount)/NULLIF(SUM(gross_pos_sales),0) rate FROM msbf_m1.merchant_pos_daily_scenario s JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code)
SELECT 'M1_6_POS_48_CHARGEBACK_RATE_DIRECTION','Scenario chargeback-rate direction',(SELECT rate FROM a WHERE scenario_code='RECESSION_ENERGY')::text,(SELECT rate FROM a WHERE scenario_code='BASELINE')::text,(SELECT rate FROM a WHERE scenario_code='RECESSION_ENERGY')>(SELECT rate FROM a WHERE scenario_code='BASELINE'),'Stress increases the aggregate chargeback-rate burden.';
INSERT INTO _m1_6_checks
WITH a AS (SELECT sr.scenario_code,COUNT(*) FILTER(WHERE processor_status='OUTAGE')::numeric/COUNT(*) rate FROM msbf_m1.merchant_pos_daily_scenario s JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id WHERE s.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code)
SELECT 'M1_6_POS_49_OUTAGE_SHARE_DIRECTION','Scenario outage-share direction',(SELECT rate FROM a WHERE scenario_code='RECESSION_ENERGY')::text,(SELECT rate FROM a WHERE scenario_code='BASELINE')::text,(SELECT rate FROM a WHERE scenario_code='RECESSION_ENERGY')>(SELECT rate FROM a WHERE scenario_code='BASELINE'),'The stress overlay increases processor-outage observations.';
INSERT INTO _m1_6_checks
WITH x AS (SELECT e.industry_code,1-SUM(e.gross_pos_sales)/NULLIF(SUM(b.gross_pos_sales),0) decline FROM _m1_6_pos_expected e JOIN msbf_m1.merchant_pos_daily_base b ON b.population_id=e.population_id AND b.merchant_id=e.merchant_id AND b.processor_account_id=e.processor_account_id AND b.observation_date=e.observation_date WHERE e.scenario_code='RECESSION_ENERGY' AND e.shock_active_flag GROUP BY e.industry_code)
SELECT 'M1_6_POS_50_INDUSTRY_SENSITIVITY_ORDER','Energy versus healthcare gross-sales decline',(SELECT decline FROM x WHERE industry_code='ENERGY_SERVICES')::text||'|'||(SELECT decline FROM x WHERE industry_code='HEALTHCARE_SERVICES')::text,'ENERGY decline > HEALTHCARE decline',(SELECT decline FROM x WHERE industry_code='ENERGY_SERVICES')>(SELECT decline FROM x WHERE industry_code='HEALTHCARE_SERVICES'),'The direct and propagated stress matrix preserves intended relative sensitivity.';

/* 51–57 — deposit accounting and directional deltas */
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_51_DEPOSIT_RECONCILIATION','Deposit accounting violations',COUNT(*) FILTER(WHERE abs(closing_balance-(opening_balance+deposit_amount-withdrawal_amount))>(SELECT tolerance FROM _m1_6_ctx))::text,'0',COUNT(*) FILTER(WHERE abs(closing_balance-(opening_balance+deposit_amount-withdrawal_amount))>(SELECT tolerance FROM _m1_6_ctx))=0,'Scenario deposit accounting reconciles.' FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM _m1_6_ctx);
INSERT INTO _m1_6_checks
WITH x AS (SELECT COUNT(*) violations FROM msbf_m1.merchant_deposit_daily_scenario curr LEFT JOIN msbf_m1.merchant_deposit_daily_scenario prev ON prev.scenario_id=curr.scenario_id AND prev.merchant_id=curr.merchant_id AND prev.observation_date=curr.observation_date-1 WHERE curr.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) AND prev.scenario_row_id IS NOT NULL AND abs(curr.opening_balance-prev.closing_balance)>(SELECT tolerance FROM _m1_6_ctx))
SELECT 'M1_6_POS_52_DEPOSIT_ROLL_FORWARD','Deposit opening-balance roll-forward violations',violations::text,'0',violations=0,'Every scenario opening balance equals the preceding scenario closing balance.' FROM x;
INSERT INTO _m1_6_checks
WITH a AS (SELECT sr.scenario_code,SUM((d.scenario_overlay_payload->>'base_pos_deposit_amount')::numeric) total FROM msbf_m1.merchant_deposit_daily_scenario d JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=d.scenario_id WHERE d.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code)
SELECT 'M1_6_POS_53_STRESS_POS_DEPOSIT_DECLINE','Stress POS-linked deposit direction',(SELECT total FROM a WHERE scenario_code='RECESSION_ENERGY')::text,(SELECT total FROM a WHERE scenario_code='BASELINE')::text,(SELECT total FROM a WHERE scenario_code='RECESSION_ENERGY')<(SELECT total FROM a WHERE scenario_code='BASELINE'),'Lower stressed proceeds and capture reduce POS-linked deposits.';
INSERT INTO _m1_6_checks
WITH a AS (SELECT sr.scenario_code,SUM(withdrawal_amount) total FROM msbf_m1.merchant_deposit_daily_scenario d JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=d.scenario_id WHERE d.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code)
SELECT 'M1_6_POS_54_STRESS_WITHDRAWAL_INCREASE','Stress withdrawal direction',(SELECT total FROM a WHERE scenario_code='RECESSION_ENERGY')::text,(SELECT total FROM a WHERE scenario_code='BASELINE')::text,(SELECT total FROM a WHERE scenario_code='RECESSION_ENERGY')>(SELECT total FROM a WHERE scenario_code='BASELINE'),'The stress scenario increases operating and financing pressure.';
INSERT INTO _m1_6_checks
WITH a AS (SELECT sr.scenario_code,COUNT(*) FILTER(WHERE negative_balance_flag)::numeric/COUNT(*) rate FROM msbf_m1.merchant_deposit_daily_scenario d JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=d.scenario_id WHERE d.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code)
SELECT 'M1_6_POS_55_NEGATIVE_BALANCE_DIRECTION','Negative-balance-share direction',(SELECT rate FROM a WHERE scenario_code='RECESSION_ENERGY')::text,(SELECT rate FROM a WHERE scenario_code='BASELINE')::text,(SELECT rate FROM a WHERE scenario_code='RECESSION_ENERGY')>=(SELECT rate FROM a WHERE scenario_code='BASELINE'),'Stress does not improve the negative-balance share.';
INSERT INTO _m1_6_checks
WITH a AS (SELECT sr.scenario_code,SUM(nsf_count) events FROM msbf_m1.merchant_deposit_daily_scenario d JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=d.scenario_id WHERE d.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) GROUP BY sr.scenario_code)
SELECT 'M1_6_POS_56_NSF_DIRECTION','NSF-event direction',(SELECT events FROM a WHERE scenario_code='RECESSION_ENERGY')::text,(SELECT events FROM a WHERE scenario_code='BASELINE')::text,(SELECT events FROM a WHERE scenario_code='RECESSION_ENERGY')>=(SELECT events FROM a WHERE scenario_code='BASELINE'),'Stress does not reduce NSF-event incidence.';
INSERT INTO _m1_6_checks
SELECT 'M1_6_POS_57_STRESS_SUPPORT_DEPOSITS','Stress support-deposit rows',COUNT(*) FILTER(WHERE (scenario_overlay_payload->>'support_deposit_amount')::numeric>0)::text,'>0',COUNT(*) FILTER(WHERE (scenario_overlay_payload->>'support_deposit_amount')::numeric>0)>0,'Bounded non-POS support preserves interpretable liquidity stress.' FROM msbf_m1.merchant_deposit_daily_scenario d JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=d.scenario_id WHERE d.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) AND sr.scenario_code='RECESSION_ENERGY';

/* 58–62 — deterministic, matched, and boundary controls */
INSERT INTO _m1_6_checks
WITH c AS (SELECT (SELECT COUNT(*) FROM msbf_m1.m1_6_expected_scenario_snapshot((SELECT run_id FROM _m1_6_ctx))) expected_rows,(SELECT COUNT(*) FROM msbf_m1.m1_6_actual_scenario_snapshot((SELECT run_id FROM _m1_6_ctx))) actual_rows,(SELECT COUNT(*) FROM msbf_m1.m1_6_expected_scenario_snapshot((SELECT run_id FROM _m1_6_ctx)) e FULL JOIN msbf_m1.m1_6_actual_scenario_snapshot((SELECT run_id FROM _m1_6_ctx)) a USING(entity_type,entity_key) WHERE e.row_hash IS DISTINCT FROM a.row_hash) mismatches)
SELECT 'M1_6_POS_58_CANONICAL_REPRODUCTION','Canonical scenario reproduction',expected_rows::text||'|'||actual_rows::text||'|'||mismatches::text,'540000|540000|0',expected_rows=540000 AND actual_rows=540000 AND mismatches=0,'Every scenario row independently reproduces.' FROM c;
INSERT INTO _m1_6_checks
WITH h AS (SELECT
 (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND evidence_code='M1_6_POS_SCENARIO_SET_HASH' AND segment_key='PORTFOLIO') pos_stored,
 (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND evidence_code='M1_6_DEPOSIT_SCENARIO_SET_HASH' AND segment_key='PORTFOLIO') dep_stored,
 (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND evidence_code='M1_6_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') combined_stored,
 (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_6_actual_scenario_snapshot((SELECT run_id FROM _m1_6_ctx)) WHERE entity_type='POS_SCENARIO') pos_actual,
 (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_6_actual_scenario_snapshot((SELECT run_id FROM _m1_6_ctx)) WHERE entity_type='DEPOSIT_SCENARIO') dep_actual,
 (SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_6_actual_scenario_snapshot((SELECT run_id FROM _m1_6_ctx))) combined_actual)
SELECT 'M1_6_POS_59_SET_HASH_RECONCILIATION','Scenario set hashes',pos_stored||'|'||dep_stored||'|'||combined_stored,pos_actual||'|'||dep_actual||'|'||combined_actual,pos_stored=pos_actual AND dep_stored=dep_actual AND combined_stored=combined_actual,'Stored POS, deposit, and combined scenario hashes reconcile.' FROM h;
INSERT INTO _m1_6_checks
WITH x AS (SELECT COUNT(*)::numeric matched FROM msbf_m1.merchant_pos_daily_scenario p JOIN msbf_m1.merchant_deposit_daily_scenario d ON d.scenario_id=p.scenario_id AND d.population_id=p.population_id AND d.merchant_id=p.merchant_id AND d.observation_date=p.observation_date WHERE p.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx) AND d.generated_by_run_id=(SELECT run_id FROM _m1_6_ctx))
SELECT 'M1_6_POS_60_MATCHED_SHARE','Matched POS/deposit scenario share',(matched/270000)::text,(SELECT matched_share_min::text FROM _m1_6_ctx),matched/270000>=(SELECT matched_share_min FROM _m1_6_ctx),'Every scenario merchant-day has both POS and deposit evidence.' FROM x;
INSERT INTO _m1_6_checks
WITH x AS (SELECT
 (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM _m1_6_ctx))
 +(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM _m1_6_ctx)) downstream_rows)
SELECT 'M1_6_POS_61_STAGE_BOUNDARY','Downstream analytical rows',downstream_rows::text,'0',downstream_rows=0,'M1.6 creates scenario histories only.' FROM x;
INSERT INTO _m1_6_checks SELECT 'M1_6_POS_62_BLOCKING_ERRORS','Blocking configuration errors',COUNT(*)::text,'0',COUNT(*)=0,'No unresolved blocking configuration errors remain.' FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_6_ctx) AND severity='BLOCKING';

INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
SELECT (SELECT run_id FROM _m1_6_ctx),evidence_code,'PORTFOLIO',metric_name,observed_value,'TEXT',CASE WHEN pass_flag THEN 'PASS' ELSE 'FAIL' END,interpretation||' Expected: '||expected_value
FROM _m1_6_checks
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
 metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
 threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry
SET run_status=CASE WHEN (SELECT COUNT(*) FROM _m1_6_checks WHERE NOT pass_flag)=0 THEN 'M1_6_VALIDATED' ELSE 'M1_6_FAILED' END
WHERE run_id=(SELECT run_id FROM _m1_6_ctx);

COMMIT;

SELECT evidence_code,metric_name,metric_value_text,status,interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code ~ '^M1_6_POS_[0-9]{2}_'
ORDER BY evidence_code;
