/* ============================================================================
MSBF M1.9 As-of Cash-Flow Feature Engineering — Positive Validation
Version : v0.2R5
Purpose : Validate persisted scenario-aware wide/long features without rebuilding
          accepted M1.4–M1.8 histories or M1.9 business transformations.
Output  : One user-facing 66-row result set.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='15min';

DO $guard$ DECLARE v text; BEGIN
 SELECT run_status INTO STRICT v FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 IF v<>'M1_9_GENERATED' THEN RAISE EXCEPTION 'M1.9 validation requires M1_9_GENERATED; observed %.',v; END IF;
END $guard$;

CREATE TEMP TABLE _m1_9_vctx ON COMMIT DROP AS
SELECT run_id,run_status,population_id,as_of_date,parameter_snapshot_hash,profile_snapshot_hash,source_snapshot_hash
FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
CREATE TEMP TABLE _m1_9_vpolicy ON COMMIT DROP AS
SELECT (profile_payload->>'annualization_days')::numeric AS annualization_days,
       profile_payload->>'annualized_sales_basis' AS annualized_sales_basis
FROM msbf_ctl.policy_profile
WHERE profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING'
  AND profile_version=1 AND status='APPROVED';
CREATE TEMP TABLE _m1_9_vgates ON COMMIT DROP AS
SELECT DISTINCT ON(gate_id) gate_id,result_status FROM msbf_ctl.acceptance_gate_result
WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND gate_id IN
('G1_CONTROL_PLANE','M1_2_POPULATION','M1_3_APPLICATION_REQUEST','M1_4_DAILY_POS_HISTORY','M1_5_DAILY_DEPOSIT_LIQUIDITY','M1_6_MATCHED_SCENARIO_OVERLAYS','M1_7_SOURCE_QUALITY_CONFIDENCE','M1_8_VERIFICATION_FRAUD_CONTINUITY')
ORDER BY gate_id,review_version DESC;
CREATE TEMP TABLE _m1_9_vs ON COMMIT DROP AS
SELECT * FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_9_vctx);
CREATE UNIQUE INDEX ON _m1_9_vs(scenario_id,merchant_application_id);
CREATE TEMP TABLE _m1_9_vf ON COMMIT DROP AS
SELECT * FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=(SELECT run_id FROM _m1_9_vctx);
CREATE UNIQUE INDEX ON _m1_9_vf(scenario_id,merchant_application_id,feature_code,feature_version);
CREATE INDEX ON _m1_9_vf(feature_code,value_status);
CREATE TEMP TABLE _m1_9_vstored ON COMMIT DROP AS
SELECT 'SNAPSHOT|'||scenario_id||'|'||merchant_application_id entity_key,feature_snapshot_hash row_hash FROM _m1_9_vs
UNION ALL
SELECT 'FEATURE|'||scenario_id||'|'||merchant_application_id||'|'||feature_code||'|v'||feature_version,calculation_hash FROM _m1_9_vf;
CREATE UNIQUE INDEX ON _m1_9_vstored(entity_key);
CREATE TEMP TABLE _m1_9_vactual ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_9_actual_snapshot((SELECT run_id FROM _m1_9_vctx))
UNION ALL SELECT * FROM msbf_m1.m1_9_actual_feature_value((SELECT run_id FROM _m1_9_vctx));
CREATE UNIQUE INDEX ON _m1_9_vactual(entity_key);
CREATE TEMP TABLE _m1_9_vmismatch ON COMMIT DROP AS
SELECT coalesce(s.entity_key,a.entity_key) entity_key,s.row_hash stored_hash,a.row_hash recomputed_hash
FROM _m1_9_vstored s FULL JOIN _m1_9_vactual a USING(entity_key)
WHERE s.row_hash IS DISTINCT FROM a.row_hash;
CREATE TEMP TABLE _m1_9_vhash ON COMMIT DROP AS
WITH h AS (
 SELECT
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER (WHERE entity_key LIKE 'SNAPSHOT|%')) AS snapshot_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER (WHERE entity_key LIKE 'FEATURE|%')) AS feature_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) combined_hash
 FROM _m1_9_vactual
), e AS (
 SELECT max(metric_value_text) FILTER(WHERE evidence_code='M1_9_SNAPSHOT_SET_HASH') snapshot_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_9_FEATURE_VALUE_SET_HASH') feature_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_9_COMBINED_SET_HASH') combined_hash
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx)
)
SELECT h.snapshot_hash=h2.snapshot_hash snapshot_ok,h.feature_hash=h2.feature_hash feature_ok,h.combined_hash=h2.combined_hash combined_ok,
       h.snapshot_hash,h.feature_hash,h.combined_hash FROM h CROSS JOIN e h2;
CREATE TEMP TABLE _m1_9_vboundary ON COMMIT DROP AS
SELECT
 (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_9_vctx)) final_feature_rows,
 (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_9_vctx)) risk_rows,
 (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_9_vctx)) ead_rows,
 (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM _m1_9_vctx)) latest_rows,
 (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM _m1_9_vctx)) archive_rows,
 (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND severity='BLOCKING') blocking_errors;
ANALYZE _m1_9_vs; ANALYZE _m1_9_vf; ANALYZE _m1_9_vactual;

DROP TABLE IF EXISTS _m1_9_validation;
CREATE TEMP TABLE _m1_9_validation(
 evidence_code text PRIMARY KEY,metric_name text NOT NULL,observed_value text NOT NULL,
 threshold_value text NOT NULL,status text NOT NULL,interpretation text NOT NULL
) ON COMMIT PRESERVE ROWS;
CREATE OR REPLACE FUNCTION pg_temp.m1_9_add_check(p_code text,p_name text,p_observed text,p_pass boolean,p_threshold text,p_interpretation text)
RETURNS void LANGUAGE plpgsql AS $fn$ BEGIN
 INSERT INTO _m1_9_validation VALUES(p_code,p_name,coalesce(p_observed,'<NULL>'),p_threshold,
 CASE WHEN coalesce(p_pass,false) THEN 'PASS' ELSE 'FAIL' END,p_interpretation);
END $fn$;
DO $checks$ BEGIN
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_01_RUN_STATUS','Generation run status',(SELECT run_status FROM _m1_9_vctx),(SELECT run_status='M1_9_GENERATED' FROM _m1_9_vctx),'M1_9_GENERATED','Generation completed before validation.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_02_PREREQUISITE_GATES','Accepted predecessor gates',(SELECT format('%s/%s',count(*) FILTER(WHERE result_status='PASS'),count(*)) FROM _m1_9_vgates),(SELECT count(*)=8 AND count(*) FILTER(WHERE result_status='PASS')=8 FROM _m1_9_vgates),'8/8 PASS','All governed predecessor gates remain accepted.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_03_PARAMETER_SNAPSHOT_HASH','Parameter snapshot hash',(SELECT parameter_snapshot_hash FROM _m1_9_vctx),(SELECT parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8' FROM _m1_9_vctx),'bd09e598c82db96e47459d77fd11e7c8','Accepted predecessor identity remains unchanged.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_04_PROFILE_SNAPSHOT_HASH','Profile snapshot hash',(SELECT profile_snapshot_hash FROM _m1_9_vctx),(SELECT profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973' FROM _m1_9_vctx),'462cbd2ed92f68e5bdecf6b17537a973','Accepted predecessor identity remains unchanged.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_05_SOURCE_SNAPSHOT_HASH','Source snapshot hash',(SELECT source_snapshot_hash FROM _m1_9_vctx),(SELECT source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3' FROM _m1_9_vctx),'93c3d1368fb2450ab4a08e2b721f92d3','Accepted predecessor identity remains unchanged.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_06_POPULATION_HASH','Population hash',(SELECT population_hash FROM msbf_m1.population_registry WHERE population_id=(SELECT population_id FROM _m1_9_vctx)),(SELECT population_hash='9b706c926260a3ef1ae8ac95eed5d0bf' FROM msbf_m1.population_registry WHERE population_id=(SELECT population_id FROM _m1_9_vctx)),'9b706c926260a3ef1ae8ac95eed5d0bf','Accepted predecessor identity remains unchanged.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_07_APPLICATION_SET_HASH','Application set hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND evidence_code='M1_3_APPLICATION_SET_HASH'),(SELECT metric_value_text='01485256b9b5748fb412743d35ced602' FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND evidence_code='M1_3_APPLICATION_SET_HASH'),'01485256b9b5748fb412743d35ced602','Accepted predecessor identity remains unchanged.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_08_BASELINE_POS_SET_HASH','Baseline POS set hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND evidence_code='M1_4_POS_SET_HASH'),(SELECT metric_value_text='d1971e8d319483c187ec0c0483a31e33' FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND evidence_code='M1_4_POS_SET_HASH'),'d1971e8d319483c187ec0c0483a31e33','Accepted predecessor identity remains unchanged.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_09_BASELINE_DEPOSIT_SET_HASH','Baseline deposit set hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND evidence_code='M1_5_DEPOSIT_SET_HASH'),(SELECT metric_value_text='bbe96dd24fbbba3af4a587dd475a88d0' FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND evidence_code='M1_5_DEPOSIT_SET_HASH'),'bbe96dd24fbbba3af4a587dd475a88d0','Accepted predecessor identity remains unchanged.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_10_SCENARIO_SET_HASH','Scenario set hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND evidence_code='M1_6_COMBINED_SET_HASH'),(SELECT metric_value_text='3f85921bf6fc30ddc6cee146085e58c5' FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND evidence_code='M1_6_COMBINED_SET_HASH'),'3f85921bf6fc30ddc6cee146085e58c5','Accepted predecessor identity remains unchanged.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_11_M17_SOURCE_QUALITY_SET_HASH','M1.7 source-quality set hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND evidence_code='M1_7_SOURCE_SET_HASH'),(SELECT metric_value_text='de56a458d9ec0b344886850592c4e6c8' FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND evidence_code='M1_7_SOURCE_SET_HASH'),'de56a458d9ec0b344886850592c4e6c8','Accepted predecessor identity remains unchanged.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_12_M18_COMBINED_SET_HASH','M1.8 combined set hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND evidence_code='M1_8_COMBINED_SET_HASH'),(SELECT metric_value_text='604a5640a25da92a850840dbe13e3d56' FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_9_vctx) AND evidence_code='M1_8_COMBINED_SET_HASH'),'604a5640a25da92a850840dbe13e3d56','Accepted predecessor identity remains unchanged.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_13_SNAPSHOT_ROWS','Wide snapshot rows',(SELECT count(*)::text FROM _m1_9_vs),(SELECT count(*)=1500 FROM _m1_9_vs),'1500','Two scenario-aware rows exist for every accepted application.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_14_SNAPSHOT_APPLICATIONS','Distinct applications in wide snapshots',(SELECT count(DISTINCT merchant_application_id)::text FROM _m1_9_vs),(SELECT count(DISTINCT merchant_application_id)=750 FROM _m1_9_vs),'750','Every accepted application is represented.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_15_SNAPSHOT_SCENARIOS','Distinct scenarios in wide snapshots',(SELECT count(DISTINCT scenario_id)::text FROM _m1_9_vs),(SELECT count(DISTINCT scenario_id)=2 FROM _m1_9_vs),'2','BASELINE and RECESSION_ENERGY are represented.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_16_SNAPSHOT_UNIQUE_GRAIN','Wide snapshot unique grain',(SELECT format('%s/%s',count(DISTINCT (scenario_id,merchant_application_id)),count(*)) FROM _m1_9_vs),(SELECT count(DISTINCT (scenario_id,merchant_application_id))=count(*) FROM _m1_9_vs),'1500/1500','The scenario/application grain is unique.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_17_FEATURE_VALUE_ROWS','Long feature-value rows',(SELECT count(*)::text FROM _m1_9_vf),(SELECT count(*)=54000 FROM _m1_9_vf),'54000','Thirty-six governed features exist for 1,500 snapshots.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_18_FEATURES_PER_SNAPSHOT','Features per snapshot',(SELECT format('%s-%s',min(c),max(c)) FROM (SELECT count(*) c FROM _m1_9_vf GROUP BY scenario_id,merchant_application_id) x),(SELECT min(c)=36 AND max(c)=36 FROM (SELECT count(*) c FROM _m1_9_vf GROUP BY scenario_id,merchant_application_id) x),'36-36','Every snapshot contains the complete governed feature inventory.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_19_FEATURE_VALUE_UNIQUE_GRAIN','Long feature-value unique grain',(SELECT format('%s/%s',count(DISTINCT (scenario_id,merchant_application_id,feature_code,feature_version)),count(*)) FROM _m1_9_vf),(SELECT count(DISTINCT (scenario_id,merchant_application_id,feature_code,feature_version))=count(*) FROM _m1_9_vf),'54000/54000','The long-form feature grain is unique.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_20_FEATURE_DEFINITIONS','Active governed feature definitions',(SELECT count(*)::text FROM msbf_m1.feature_definition WHERE feature_code IN ('AVG_DAILY_ELIGIBLE_SALES_7D','AVG_DAILY_ELIGIBLE_SALES_30D','AVG_DAILY_ELIGIBLE_SALES_60D','AVG_DAILY_ELIGIBLE_SALES_90D','ANNUALIZED_ELIGIBLE_SALES','SALES_GROWTH_7D_VS_30D','SALES_GROWTH_30D_VS_90D','DAILY_SALES_CV_30D','DAILY_SALES_CV_90D','ZERO_SALES_DAY_RATE_30D','ACTIVE_SALES_DAY_RATE_30D','SEASONALITY_INDEX_180D','LARGEST_30D_SHARE_180D','REFUND_RATE_30D','CHARGEBACK_RATE_30D','REVERSAL_RATE_30D','DEPOSIT_TO_ELIGIBLE_SALES_RATE_30D','POS_DEPOSIT_RECONCILIATION_RATE_30D','NEGATIVE_BALANCE_DAY_RATE_30D','NSF_COUNT_30D','AVERAGE_AVAILABLE_BALANCE_30D','MINIMUM_BALANCE_30D','CASH_FLOW_BUFFER_DAYS','PROCESSOR_OUTAGE_DAY_RATE_30D','PROCESSOR_DEGRADED_DAY_RATE_30D','SOURCE_CONFIDENCE_SCORE','SCENARIO_ELIGIBLE_SALES_DELTA_RATE_30D','SCENARIO_ELIGIBLE_SALES_DELTA_RATE_90D','SCENARIO_DEPOSIT_DELTA_RATE_30D','SCENARIO_WITHDRAWAL_DELTA_RATE_30D','SCENARIO_AVAILABLE_BALANCE_DELTA_RATE_30D','SCENARIO_NEGATIVE_BALANCE_RATE_DELTA_30D','SCENARIO_NSF_COUNT_DELTA_30D','SCENARIO_PROCESSOR_OUTAGE_RATE_DELTA_30D','SCENARIO_REFUND_RATE_DELTA_30D','SCENARIO_CHARGEBACK_RATE_DELTA_30D') AND feature_version=1 AND active_flag),(SELECT count(*)=36 FROM msbf_m1.feature_definition WHERE feature_code IN ('AVG_DAILY_ELIGIBLE_SALES_7D','AVG_DAILY_ELIGIBLE_SALES_30D','AVG_DAILY_ELIGIBLE_SALES_60D','AVG_DAILY_ELIGIBLE_SALES_90D','ANNUALIZED_ELIGIBLE_SALES','SALES_GROWTH_7D_VS_30D','SALES_GROWTH_30D_VS_90D','DAILY_SALES_CV_30D','DAILY_SALES_CV_90D','ZERO_SALES_DAY_RATE_30D','ACTIVE_SALES_DAY_RATE_30D','SEASONALITY_INDEX_180D','LARGEST_30D_SHARE_180D','REFUND_RATE_30D','CHARGEBACK_RATE_30D','REVERSAL_RATE_30D','DEPOSIT_TO_ELIGIBLE_SALES_RATE_30D','POS_DEPOSIT_RECONCILIATION_RATE_30D','NEGATIVE_BALANCE_DAY_RATE_30D','NSF_COUNT_30D','AVERAGE_AVAILABLE_BALANCE_30D','MINIMUM_BALANCE_30D','CASH_FLOW_BUFFER_DAYS','PROCESSOR_OUTAGE_DAY_RATE_30D','PROCESSOR_DEGRADED_DAY_RATE_30D','SOURCE_CONFIDENCE_SCORE','SCENARIO_ELIGIBLE_SALES_DELTA_RATE_30D','SCENARIO_ELIGIBLE_SALES_DELTA_RATE_90D','SCENARIO_DEPOSIT_DELTA_RATE_30D','SCENARIO_WITHDRAWAL_DELTA_RATE_30D','SCENARIO_AVAILABLE_BALANCE_DELTA_RATE_30D','SCENARIO_NEGATIVE_BALANCE_RATE_DELTA_30D','SCENARIO_NSF_COUNT_DELTA_30D','SCENARIO_PROCESSOR_OUTAGE_RATE_DELTA_30D','SCENARIO_REFUND_RATE_DELTA_30D','SCENARIO_CHARGEBACK_RATE_DELTA_30D') AND feature_version=1 AND active_flag),'36','All M1.9 feature definitions are active.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_21_SCENARIO_COVERAGE','Applications per scenario',(SELECT string_agg(scenario_code||'='||c,',' ORDER BY scenario_code) FROM (SELECT sc.scenario_code,count(*)::text c FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) GROUP BY sc.scenario_code) x),(SELECT count(*)=2 AND min(c)=750 AND max(c)=750 FROM (SELECT scenario_id,count(*) c FROM _m1_9_vs GROUP BY scenario_id) x),'BASELINE=750,RECESSION_ENERGY=750','Matched scenario coverage is complete.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_22_AS_OF_DATE','As-of date alignment',(SELECT count(*) FILTER(WHERE as_of_date<>(SELECT as_of_date FROM _m1_9_vctx))::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE as_of_date<>(SELECT as_of_date FROM _m1_9_vctx))=0 FROM _m1_9_vs),'0 mismatches','Every feature snapshot uses the accepted as-of date.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_23_HISTORY_BOUNDARY','History-date integrity',(SELECT count(*) FILTER(WHERE history_start_date>history_end_date OR history_end_date>as_of_date)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE history_start_date>history_end_date OR history_end_date>as_of_date)=0 FROM _m1_9_vs),'0 violations','No feature uses future evidence.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_24_SOURCE_LINEAGE','POS/deposit source lineage',(SELECT count(*) FILTER(WHERE pos_source_snapshot_id IS NULL OR deposit_source_snapshot_id IS NULL)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE pos_source_snapshot_id IS NULL OR deposit_source_snapshot_id IS NULL)=0 FROM _m1_9_vs),'0 missing','Every snapshot retains governed source lineage.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_25_CONFIDENCE_BOUNDS','Source-confidence bounds',(SELECT count(*) FILTER(WHERE source_confidence_score<0 OR source_confidence_score>1)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE source_confidence_score<0 OR source_confidence_score>1)=0 FROM _m1_9_vs),'0 violations','Confidence remains bounded.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_26_CONFIDENCE_TIER_DOMAIN','Data-confidence tier domain',(SELECT count(*) FILTER(WHERE data_confidence_tier NOT IN ('HIGH','MEDIUM','LOW','REVIEW'))::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE data_confidence_tier NOT IN ('HIGH','MEDIUM','LOW','REVIEW'))=0 FROM _m1_9_vs),'0 violations','Only governed confidence tiers are used.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_27_QUALITY_STATUS_DOMAIN','Source-quality status domain',(SELECT count(*) FILTER(WHERE pos_quality_status NOT IN ('PASS','WARNING','FAIL','CONFLICT','UNAVAILABLE') OR deposit_quality_status NOT IN ('PASS','WARNING','FAIL','CONFLICT','UNAVAILABLE'))::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE pos_quality_status NOT IN ('PASS','WARNING','FAIL','CONFLICT','UNAVAILABLE') OR deposit_quality_status NOT IN ('PASS','WARNING','FAIL','CONFLICT','UNAVAILABLE'))=0 FROM _m1_9_vs),'0 violations','Only governed source-quality statuses are used.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_28_COMPLETENESS_DOMAIN','Feature-completeness status domain',(SELECT count(*) FILTER(WHERE feature_completeness_status NOT IN ('COMPLETE','PARTIAL','BLOCKED'))::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE feature_completeness_status NOT IN ('COMPLETE','PARTIAL','BLOCKED'))=0 FROM _m1_9_vs),'0 violations','Completeness remains explicit and governed.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_29_ROUTING_DOMAIN','Downstream routing domain',(SELECT count(*) FILTER(WHERE downstream_routing_status NOT IN ('CLEAR','REVIEW','STOP','INSUFFICIENT_EVIDENCE'))::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE downstream_routing_status NOT IN ('CLEAR','REVIEW','STOP','INSUFFICIENT_EVIDENCE'))=0 FROM _m1_9_vs),'0 violations','Only governed downstream routes are used.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_30_FRAUD_TIER_BOUNDS','Fraud-tier bounds',(SELECT count(*) FILTER(WHERE fraud_risk_tier NOT BETWEEN 1 AND 5)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE fraud_risk_tier NOT BETWEEN 1 AND 5)=0 FROM _m1_9_vs),'0 violations','Fraud risk remains separate and bounded.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_31_CONTINUITY_TIER_BOUNDS','Processor-continuity tier bounds',(SELECT count(*) FILTER(WHERE processor_continuity_risk_tier NOT BETWEEN 1 AND 5)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE processor_continuity_risk_tier NOT BETWEEN 1 AND 5)=0 FROM _m1_9_vs),'0 violations','Processor continuity remains separate and bounded.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_32_HISTORY_DAY_BOUNDS','Source-history-day bounds',(SELECT count(*) FILTER(WHERE pos_history_days NOT BETWEEN 0 AND 180 OR deposit_history_days NOT BETWEEN 0 AND 180)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE pos_history_days NOT BETWEEN 0 AND 180 OR deposit_history_days NOT BETWEEN 0 AND 180)=0 FROM _m1_9_vs),'0 violations','History counts are bounded to the accepted panel.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_33_POS_UNAVAILABLE_MASK','Unavailable POS feature masking',(SELECT count(*) FILTER(WHERE pos_quality_status='UNAVAILABLE' AND (avg_daily_eligible_sales_30d IS NOT NULL OR annualized_eligible_sales IS NOT NULL))::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE pos_quality_status='UNAVAILABLE' AND (avg_daily_eligible_sales_30d IS NOT NULL OR annualized_eligible_sales IS NOT NULL))=0 FROM _m1_9_vs),'0 violations','Unavailable POS evidence is never converted to zero performance.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_34_DEPOSIT_UNAVAILABLE_MASK','Unavailable deposit feature masking',(SELECT count(*) FILTER(WHERE deposit_quality_status='UNAVAILABLE' AND (average_available_balance_30d IS NOT NULL OR negative_balance_day_rate_30d IS NOT NULL))::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE deposit_quality_status='UNAVAILABLE' AND (average_available_balance_30d IS NOT NULL OR negative_balance_day_rate_30d IS NOT NULL))=0 FROM _m1_9_vs),'0 violations','Unavailable deposit evidence is never converted to strong liquidity.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_35_READY_FLAG_LOGIC','Downstream readiness logic',(SELECT count(*) FILTER(WHERE ready_for_downstream_flag IS DISTINCT FROM (pos_quality_status<>'UNAVAILABLE' AND verification_disposition NOT IN ('STOP','INSUFFICIENT_EVIDENCE')))::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE ready_for_downstream_flag IS DISTINCT FROM (pos_quality_status<>'UNAVAILABLE' AND verification_disposition NOT IN ('STOP','INSUFFICIENT_EVIDENCE')))=0 FROM _m1_9_vs),'0 violations','Feature readiness follows governed evidence and verification boundaries.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_36_MANUAL_REVIEW_COHERENCE','Manual-review coherence',(SELECT count(*) FILTER(WHERE downstream_routing_status='REVIEW' AND NOT manual_review_recommended_flag)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE downstream_routing_status='REVIEW' AND NOT manual_review_recommended_flag)=0 FROM _m1_9_vs),'0 violations','Review-routed records preserve a manual-review indicator.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_37_ACTIVE_ZERO_IDENTITY','Active plus zero-sales identity',(SELECT count(*) FILTER(WHERE zero_sales_day_rate_30d IS NOT NULL AND active_sales_day_rate_30d IS NOT NULL AND abs(zero_sales_day_rate_30d+active_sales_day_rate_30d-1)>0.00000002)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE zero_sales_day_rate_30d IS NOT NULL AND active_sales_day_rate_30d IS NOT NULL AND abs(zero_sales_day_rate_30d+active_sales_day_rate_30d-1)>0.00000002)=0 FROM _m1_9_vs),'0 violations','Daily activity shares reconcile.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_38_ANNUALIZED_SALES_IDENTITY','Annualized-sales identity',(SELECT count(*) FILTER(WHERE (avg_daily_eligible_sales_90d IS NULL AND annualized_eligible_sales IS NOT NULL) OR (avg_daily_eligible_sales_90d IS NOT NULL AND annualized_eligible_sales IS DISTINCT FROM round(avg_daily_eligible_sales_90d*(SELECT annualization_days FROM _m1_9_vpolicy),2)::numeric(18,2)))::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE (avg_daily_eligible_sales_90d IS NULL AND annualized_eligible_sales IS NOT NULL) OR (avg_daily_eligible_sales_90d IS NOT NULL AND annualized_eligible_sales IS DISTINCT FROM round(avg_daily_eligible_sales_90d*(SELECT annualization_days FROM _m1_9_vpolicy),2)::numeric(18,2)))=0 FROM _m1_9_vs),'0 violations','Annualized sales equals the persisted two-decimal 90-day average multiplied by the governed 365-day factor; unavailable average evidence remains unavailable.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_39_GROWTH_7_30_BOUNDS','Seven-versus-thirty-day growth bounds',(SELECT count(*) FILTER(WHERE sales_growth_7d_vs_30d IS NOT NULL AND sales_growth_7d_vs_30d NOT BETWEEN -1 AND 5)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE sales_growth_7d_vs_30d IS NOT NULL AND sales_growth_7d_vs_30d NOT BETWEEN -1 AND 5)=0 FROM _m1_9_vs),'0 violations','Growth is bounded by governed policy.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_40_GROWTH_30_90_BOUNDS','Thirty-versus-ninety-day growth bounds',(SELECT count(*) FILTER(WHERE sales_growth_30d_vs_90d IS NOT NULL AND sales_growth_30d_vs_90d NOT BETWEEN -1 AND 5)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE sales_growth_30d_vs_90d IS NOT NULL AND sales_growth_30d_vs_90d NOT BETWEEN -1 AND 5)=0 FROM _m1_9_vs),'0 violations','Growth is bounded by governed policy.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_41_REFUND_RATE_BOUNDS','Refund-rate bounds',(SELECT count(*) FILTER(WHERE refund_rate_30d IS NOT NULL AND refund_rate_30d NOT BETWEEN 0 AND 1)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE refund_rate_30d IS NOT NULL AND refund_rate_30d NOT BETWEEN 0 AND 1)=0 FROM _m1_9_vs),'0 violations','Refund rates are bounded.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_42_CHARGEBACK_RATE_BOUNDS','Chargeback-rate bounds',(SELECT count(*) FILTER(WHERE chargeback_rate_30d IS NOT NULL AND chargeback_rate_30d NOT BETWEEN 0 AND 1)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE chargeback_rate_30d IS NOT NULL AND chargeback_rate_30d NOT BETWEEN 0 AND 1)=0 FROM _m1_9_vs),'0 violations','Chargeback rates are bounded.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_43_REVERSAL_RATE_BOUNDS','Reversal-rate bounds',(SELECT count(*) FILTER(WHERE reversal_rate_30d IS NOT NULL AND reversal_rate_30d NOT BETWEEN 0 AND 1)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE reversal_rate_30d IS NOT NULL AND reversal_rate_30d NOT BETWEEN 0 AND 1)=0 FROM _m1_9_vs),'0 violations','Reversal rates are bounded.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_44_CV_BOUNDS','Sales-volatility bounds',(SELECT count(*) FILTER(WHERE daily_sales_cv_30d IS NOT NULL AND daily_sales_cv_30d NOT BETWEEN 0 AND 10 OR daily_sales_cv_90d IS NOT NULL AND daily_sales_cv_90d NOT BETWEEN 0 AND 10)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE (daily_sales_cv_30d IS NOT NULL AND daily_sales_cv_30d NOT BETWEEN 0 AND 10) OR (daily_sales_cv_90d IS NOT NULL AND daily_sales_cv_90d NOT BETWEEN 0 AND 10))=0 FROM _m1_9_vs),'0 violations','Coefficients of variation remain nonnegative and capped.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_45_SEASONALITY_BOUNDS','Seasonality-index bounds',(SELECT count(*) FILTER(WHERE seasonality_index_180d IS NOT NULL AND seasonality_index_180d NOT BETWEEN 0 AND 5)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE seasonality_index_180d IS NOT NULL AND seasonality_index_180d NOT BETWEEN 0 AND 5)=0 FROM _m1_9_vs),'0 violations','Seasonality is bounded by policy.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_46_LARGEST_SHARE_BOUNDS','Largest-thirty-day share bounds',(SELECT count(*) FILTER(WHERE largest_30d_share_180d IS NOT NULL AND largest_30d_share_180d NOT BETWEEN 0 AND 1)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE largest_30d_share_180d IS NOT NULL AND largest_30d_share_180d NOT BETWEEN 0 AND 1)=0 FROM _m1_9_vs),'0 violations','Concentration shares are bounded.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_47_DEPOSIT_SALES_RATIO_BOUNDS','Deposit-to-sales ratio bounds',(SELECT count(*) FILTER(WHERE deposit_to_eligible_sales_rate_30d IS NOT NULL AND deposit_to_eligible_sales_rate_30d NOT BETWEEN 0 AND 5)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE deposit_to_eligible_sales_rate_30d IS NOT NULL AND deposit_to_eligible_sales_rate_30d NOT BETWEEN 0 AND 5)=0 FROM _m1_9_vs),'0 violations','Deposit capture ratio is bounded.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_48_RECONCILIATION_BOUNDS','POS/deposit reconciliation bounds',(SELECT count(*) FILTER(WHERE pos_deposit_reconciliation_rate_30d IS NOT NULL AND pos_deposit_reconciliation_rate_30d NOT BETWEEN 0 AND 1)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE pos_deposit_reconciliation_rate_30d IS NOT NULL AND pos_deposit_reconciliation_rate_30d NOT BETWEEN 0 AND 1)=0 FROM _m1_9_vs),'0 violations','Paired-source reconciliation is bounded.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_49_NEGATIVE_BALANCE_RATE_BOUNDS','Negative-balance-rate bounds',(SELECT count(*) FILTER(WHERE negative_balance_day_rate_30d IS NOT NULL AND negative_balance_day_rate_30d NOT BETWEEN 0 AND 1)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE negative_balance_day_rate_30d IS NOT NULL AND negative_balance_day_rate_30d NOT BETWEEN 0 AND 1)=0 FROM _m1_9_vs),'0 violations','Negative-balance frequency is bounded.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_50_PROCESSOR_RATE_BOUNDS','Processor-event-rate bounds',(SELECT count(*) FILTER(WHERE processor_outage_day_rate_30d IS NOT NULL AND processor_outage_day_rate_30d NOT BETWEEN 0 AND 1 OR processor_degraded_day_rate_30d IS NOT NULL AND processor_degraded_day_rate_30d NOT BETWEEN 0 AND 1)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE (processor_outage_day_rate_30d IS NOT NULL AND processor_outage_day_rate_30d NOT BETWEEN 0 AND 1) OR (processor_degraded_day_rate_30d IS NOT NULL AND processor_degraded_day_rate_30d NOT BETWEEN 0 AND 1))=0 FROM _m1_9_vs),'0 violations','Processor-event frequencies are bounded.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_51_BUFFER_BOUNDS','Cash-flow buffer bounds',(SELECT count(*) FILTER(WHERE cash_flow_buffer_days IS NOT NULL AND cash_flow_buffer_days NOT BETWEEN -365 AND 365)::text FROM _m1_9_vs),(SELECT count(*) FILTER(WHERE cash_flow_buffer_days IS NOT NULL AND cash_flow_buffer_days NOT BETWEEN -365 AND 365)=0 FROM _m1_9_vs),'0 violations','Liquidity buffer days remain bounded.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_52_BASELINE_DELTAS_ZERO','Baseline scenario deltas',(SELECT count(*) FILTER(WHERE sc.scenario_code='BASELINE' AND (coalesce(s.scenario_eligible_sales_delta_rate_30d,0)<>0 OR coalesce(s.scenario_eligible_sales_delta_rate_90d,0)<>0 OR coalesce(s.scenario_deposit_delta_rate_30d,0)<>0 OR coalesce(s.scenario_withdrawal_delta_rate_30d,0)<>0 OR coalesce(s.scenario_available_balance_delta_rate_30d,0)<>0 OR coalesce(s.scenario_negative_balance_rate_delta_30d,0)<>0 OR coalesce(s.scenario_nsf_count_delta_30d,0)<>0 OR coalesce(s.scenario_processor_outage_rate_delta_30d,0)<>0 OR coalesce(s.scenario_refund_rate_delta_30d,0)<>0 OR coalesce(s.scenario_chargeback_rate_delta_30d,0)<>0))::text FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id)),(SELECT count(*) FILTER(WHERE sc.scenario_code='BASELINE' AND (coalesce(s.scenario_eligible_sales_delta_rate_30d,0)<>0 OR coalesce(s.scenario_eligible_sales_delta_rate_90d,0)<>0 OR coalesce(s.scenario_deposit_delta_rate_30d,0)<>0 OR coalesce(s.scenario_withdrawal_delta_rate_30d,0)<>0 OR coalesce(s.scenario_available_balance_delta_rate_30d,0)<>0 OR coalesce(s.scenario_negative_balance_rate_delta_30d,0)<>0 OR coalesce(s.scenario_nsf_count_delta_30d,0)<>0 OR coalesce(s.scenario_processor_outage_rate_delta_30d,0)<>0 OR coalesce(s.scenario_refund_rate_delta_30d,0)<>0 OR coalesce(s.scenario_chargeback_rate_delta_30d,0)<>0))=0 FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id)),'0 violations','BASELINE deltas are exactly zero.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_53_STRESS_SALES_DIRECTION','Stress sales do not improve on average',(SELECT round(avg(s.scenario_eligible_sales_delta_rate_30d),8)::text FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),(SELECT coalesce(avg(s.scenario_eligible_sales_delta_rate_30d),0) <= 0 FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),'Average <= 0','Stress sales do not improve on average.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_54_STRESS_DEPOSIT_DIRECTION','Stress deposits do not improve on average',(SELECT round(avg(s.scenario_deposit_delta_rate_30d),8)::text FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),(SELECT coalesce(avg(s.scenario_deposit_delta_rate_30d),0) <= 0 FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),'Average <= 0','Stress deposits do not improve on average.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_55_STRESS_WITHDRAWAL_DIRECTION','Stress withdrawals do not decline on average',(SELECT round(avg(s.scenario_withdrawal_delta_rate_30d),8)::text FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),(SELECT coalesce(avg(s.scenario_withdrawal_delta_rate_30d),0) >= 0 FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),'Average >= 0','Stress withdrawals do not decline on average.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_56_STRESS_BALANCE_DIRECTION','Stress available balances do not improve on average',(SELECT round(avg(s.scenario_available_balance_delta_rate_30d),8)::text FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),(SELECT coalesce(avg(s.scenario_available_balance_delta_rate_30d),0) <= 0 FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),'Average <= 0','Stress available balances do not improve on average.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_57_STRESS_NEGATIVE_DIRECTION','Stress negative-balance frequency does not improve on average',(SELECT round(avg(s.scenario_negative_balance_rate_delta_30d),8)::text FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),(SELECT coalesce(avg(s.scenario_negative_balance_rate_delta_30d),0) >= 0 FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),'Average >= 0','Stress negative-balance frequency does not improve on average.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_58_STRESS_NSF_DIRECTION','Stress NSF behavior does not improve on average',(SELECT round(avg(s.scenario_nsf_count_delta_30d),8)::text FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),(SELECT coalesce(avg(s.scenario_nsf_count_delta_30d),0) >= 0 FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),'Average >= 0','Stress NSF behavior does not improve on average.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_59_STRESS_OUTAGE_DIRECTION','Stress processor outages do not improve on average',(SELECT round(avg(s.scenario_processor_outage_rate_delta_30d),8)::text FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),(SELECT coalesce(avg(s.scenario_processor_outage_rate_delta_30d),0) >= 0 FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),'Average >= 0','Stress processor outages do not improve on average.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_60_STRESS_TRANSACTION_QUALITY','Stress transaction-quality direction',(SELECT format('refund=%s chargeback=%s',round(avg(s.scenario_refund_rate_delta_30d),8),round(avg(s.scenario_chargeback_rate_delta_30d),8)) FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),(SELECT coalesce(avg(s.scenario_refund_rate_delta_30d),0)>=0 AND coalesce(avg(s.scenario_chargeback_rate_delta_30d),0)>=0 FROM _m1_9_vs s JOIN msbf_ctl.scenario_registry sc USING(scenario_id) WHERE sc.scenario_code='RECESSION_ENERGY'),'Both averages >= 0','Stress refund and chargeback rates do not improve on average.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_61_SOURCE_CONFIDENCE_LONG_RECON','Source-confidence long/wide reconciliation',(SELECT count(*) FILTER(WHERE abs(v.value_numeric-s.source_confidence_score)>0.000001)::text FROM _m1_9_vf v JOIN _m1_9_vs s USING(module1_run_id,scenario_id,merchant_application_id) WHERE v.feature_code='SOURCE_CONFIDENCE_SCORE'),(SELECT count(*) FILTER(WHERE abs(v.value_numeric-s.source_confidence_score)>0.000001)=0 FROM _m1_9_vf v JOIN _m1_9_vs s USING(module1_run_id,scenario_id,merchant_application_id) WHERE v.feature_code='SOURCE_CONFIDENCE_SCORE'),'0 mismatches','Source confidence reconciles between wide and long outputs.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_62_LONG_WIDE_VALUE_RECON','Long/wide feature-value reconciliation',(SELECT count(*) FILTER(WHERE (v.value_status='AVAILABLE' AND v.value_numeric IS DISTINCT FROM (CASE v.feature_code
    WHEN 'AVG_DAILY_ELIGIBLE_SALES_7D' THEN (to_jsonb(s)->>'avg_daily_eligible_sales_7d')::numeric
    WHEN 'AVG_DAILY_ELIGIBLE_SALES_30D' THEN (to_jsonb(s)->>'avg_daily_eligible_sales_30d')::numeric
    WHEN 'AVG_DAILY_ELIGIBLE_SALES_60D' THEN (to_jsonb(s)->>'avg_daily_eligible_sales_60d')::numeric
    WHEN 'AVG_DAILY_ELIGIBLE_SALES_90D' THEN (to_jsonb(s)->>'avg_daily_eligible_sales_90d')::numeric
    WHEN 'ANNUALIZED_ELIGIBLE_SALES' THEN (to_jsonb(s)->>'annualized_eligible_sales')::numeric
    WHEN 'SALES_GROWTH_7D_VS_30D' THEN (to_jsonb(s)->>'sales_growth_7d_vs_30d')::numeric
    WHEN 'SALES_GROWTH_30D_VS_90D' THEN (to_jsonb(s)->>'sales_growth_30d_vs_90d')::numeric
    WHEN 'DAILY_SALES_CV_30D' THEN (to_jsonb(s)->>'daily_sales_cv_30d')::numeric
    WHEN 'DAILY_SALES_CV_90D' THEN (to_jsonb(s)->>'daily_sales_cv_90d')::numeric
    WHEN 'ZERO_SALES_DAY_RATE_30D' THEN (to_jsonb(s)->>'zero_sales_day_rate_30d')::numeric
    WHEN 'ACTIVE_SALES_DAY_RATE_30D' THEN (to_jsonb(s)->>'active_sales_day_rate_30d')::numeric
    WHEN 'SEASONALITY_INDEX_180D' THEN (to_jsonb(s)->>'seasonality_index_180d')::numeric
    WHEN 'LARGEST_30D_SHARE_180D' THEN (to_jsonb(s)->>'largest_30d_share_180d')::numeric
    WHEN 'REFUND_RATE_30D' THEN (to_jsonb(s)->>'refund_rate_30d')::numeric
    WHEN 'CHARGEBACK_RATE_30D' THEN (to_jsonb(s)->>'chargeback_rate_30d')::numeric
    WHEN 'REVERSAL_RATE_30D' THEN (to_jsonb(s)->>'reversal_rate_30d')::numeric
    WHEN 'DEPOSIT_TO_ELIGIBLE_SALES_RATE_30D' THEN (to_jsonb(s)->>'deposit_to_eligible_sales_rate_30d')::numeric
    WHEN 'POS_DEPOSIT_RECONCILIATION_RATE_30D' THEN (to_jsonb(s)->>'pos_deposit_reconciliation_rate_30d')::numeric
    WHEN 'NEGATIVE_BALANCE_DAY_RATE_30D' THEN (to_jsonb(s)->>'negative_balance_day_rate_30d')::numeric
    WHEN 'NSF_COUNT_30D' THEN (to_jsonb(s)->>'nsf_count_30d')::numeric
    WHEN 'AVERAGE_AVAILABLE_BALANCE_30D' THEN (to_jsonb(s)->>'average_available_balance_30d')::numeric
    WHEN 'MINIMUM_BALANCE_30D' THEN (to_jsonb(s)->>'minimum_balance_30d')::numeric
    WHEN 'CASH_FLOW_BUFFER_DAYS' THEN (to_jsonb(s)->>'cash_flow_buffer_days')::numeric
    WHEN 'PROCESSOR_OUTAGE_DAY_RATE_30D' THEN (to_jsonb(s)->>'processor_outage_day_rate_30d')::numeric
    WHEN 'PROCESSOR_DEGRADED_DAY_RATE_30D' THEN (to_jsonb(s)->>'processor_degraded_day_rate_30d')::numeric
    WHEN 'SOURCE_CONFIDENCE_SCORE' THEN (to_jsonb(s)->>'source_confidence_score')::numeric
    WHEN 'SCENARIO_ELIGIBLE_SALES_DELTA_RATE_30D' THEN (to_jsonb(s)->>'scenario_eligible_sales_delta_rate_30d')::numeric
    WHEN 'SCENARIO_ELIGIBLE_SALES_DELTA_RATE_90D' THEN (to_jsonb(s)->>'scenario_eligible_sales_delta_rate_90d')::numeric
    WHEN 'SCENARIO_DEPOSIT_DELTA_RATE_30D' THEN (to_jsonb(s)->>'scenario_deposit_delta_rate_30d')::numeric
    WHEN 'SCENARIO_WITHDRAWAL_DELTA_RATE_30D' THEN (to_jsonb(s)->>'scenario_withdrawal_delta_rate_30d')::numeric
    WHEN 'SCENARIO_AVAILABLE_BALANCE_DELTA_RATE_30D' THEN (to_jsonb(s)->>'scenario_available_balance_delta_rate_30d')::numeric
    WHEN 'SCENARIO_NEGATIVE_BALANCE_RATE_DELTA_30D' THEN (to_jsonb(s)->>'scenario_negative_balance_rate_delta_30d')::numeric
    WHEN 'SCENARIO_NSF_COUNT_DELTA_30D' THEN (to_jsonb(s)->>'scenario_nsf_count_delta_30d')::numeric
    WHEN 'SCENARIO_PROCESSOR_OUTAGE_RATE_DELTA_30D' THEN (to_jsonb(s)->>'scenario_processor_outage_rate_delta_30d')::numeric
    WHEN 'SCENARIO_REFUND_RATE_DELTA_30D' THEN (to_jsonb(s)->>'scenario_refund_rate_delta_30d')::numeric
    WHEN 'SCENARIO_CHARGEBACK_RATE_DELTA_30D' THEN (to_jsonb(s)->>'scenario_chargeback_rate_delta_30d')::numeric
    ELSE NULL END)) OR (v.value_status<>'AVAILABLE' AND v.value_numeric IS NOT NULL))::text FROM _m1_9_vf v JOIN _m1_9_vs s USING(module1_run_id,scenario_id,merchant_application_id)),(SELECT count(*) FILTER(WHERE (v.value_status='AVAILABLE' AND v.value_numeric IS DISTINCT FROM (CASE v.feature_code
    WHEN 'AVG_DAILY_ELIGIBLE_SALES_7D' THEN (to_jsonb(s)->>'avg_daily_eligible_sales_7d')::numeric
    WHEN 'AVG_DAILY_ELIGIBLE_SALES_30D' THEN (to_jsonb(s)->>'avg_daily_eligible_sales_30d')::numeric
    WHEN 'AVG_DAILY_ELIGIBLE_SALES_60D' THEN (to_jsonb(s)->>'avg_daily_eligible_sales_60d')::numeric
    WHEN 'AVG_DAILY_ELIGIBLE_SALES_90D' THEN (to_jsonb(s)->>'avg_daily_eligible_sales_90d')::numeric
    WHEN 'ANNUALIZED_ELIGIBLE_SALES' THEN (to_jsonb(s)->>'annualized_eligible_sales')::numeric
    WHEN 'SALES_GROWTH_7D_VS_30D' THEN (to_jsonb(s)->>'sales_growth_7d_vs_30d')::numeric
    WHEN 'SALES_GROWTH_30D_VS_90D' THEN (to_jsonb(s)->>'sales_growth_30d_vs_90d')::numeric
    WHEN 'DAILY_SALES_CV_30D' THEN (to_jsonb(s)->>'daily_sales_cv_30d')::numeric
    WHEN 'DAILY_SALES_CV_90D' THEN (to_jsonb(s)->>'daily_sales_cv_90d')::numeric
    WHEN 'ZERO_SALES_DAY_RATE_30D' THEN (to_jsonb(s)->>'zero_sales_day_rate_30d')::numeric
    WHEN 'ACTIVE_SALES_DAY_RATE_30D' THEN (to_jsonb(s)->>'active_sales_day_rate_30d')::numeric
    WHEN 'SEASONALITY_INDEX_180D' THEN (to_jsonb(s)->>'seasonality_index_180d')::numeric
    WHEN 'LARGEST_30D_SHARE_180D' THEN (to_jsonb(s)->>'largest_30d_share_180d')::numeric
    WHEN 'REFUND_RATE_30D' THEN (to_jsonb(s)->>'refund_rate_30d')::numeric
    WHEN 'CHARGEBACK_RATE_30D' THEN (to_jsonb(s)->>'chargeback_rate_30d')::numeric
    WHEN 'REVERSAL_RATE_30D' THEN (to_jsonb(s)->>'reversal_rate_30d')::numeric
    WHEN 'DEPOSIT_TO_ELIGIBLE_SALES_RATE_30D' THEN (to_jsonb(s)->>'deposit_to_eligible_sales_rate_30d')::numeric
    WHEN 'POS_DEPOSIT_RECONCILIATION_RATE_30D' THEN (to_jsonb(s)->>'pos_deposit_reconciliation_rate_30d')::numeric
    WHEN 'NEGATIVE_BALANCE_DAY_RATE_30D' THEN (to_jsonb(s)->>'negative_balance_day_rate_30d')::numeric
    WHEN 'NSF_COUNT_30D' THEN (to_jsonb(s)->>'nsf_count_30d')::numeric
    WHEN 'AVERAGE_AVAILABLE_BALANCE_30D' THEN (to_jsonb(s)->>'average_available_balance_30d')::numeric
    WHEN 'MINIMUM_BALANCE_30D' THEN (to_jsonb(s)->>'minimum_balance_30d')::numeric
    WHEN 'CASH_FLOW_BUFFER_DAYS' THEN (to_jsonb(s)->>'cash_flow_buffer_days')::numeric
    WHEN 'PROCESSOR_OUTAGE_DAY_RATE_30D' THEN (to_jsonb(s)->>'processor_outage_day_rate_30d')::numeric
    WHEN 'PROCESSOR_DEGRADED_DAY_RATE_30D' THEN (to_jsonb(s)->>'processor_degraded_day_rate_30d')::numeric
    WHEN 'SOURCE_CONFIDENCE_SCORE' THEN (to_jsonb(s)->>'source_confidence_score')::numeric
    WHEN 'SCENARIO_ELIGIBLE_SALES_DELTA_RATE_30D' THEN (to_jsonb(s)->>'scenario_eligible_sales_delta_rate_30d')::numeric
    WHEN 'SCENARIO_ELIGIBLE_SALES_DELTA_RATE_90D' THEN (to_jsonb(s)->>'scenario_eligible_sales_delta_rate_90d')::numeric
    WHEN 'SCENARIO_DEPOSIT_DELTA_RATE_30D' THEN (to_jsonb(s)->>'scenario_deposit_delta_rate_30d')::numeric
    WHEN 'SCENARIO_WITHDRAWAL_DELTA_RATE_30D' THEN (to_jsonb(s)->>'scenario_withdrawal_delta_rate_30d')::numeric
    WHEN 'SCENARIO_AVAILABLE_BALANCE_DELTA_RATE_30D' THEN (to_jsonb(s)->>'scenario_available_balance_delta_rate_30d')::numeric
    WHEN 'SCENARIO_NEGATIVE_BALANCE_RATE_DELTA_30D' THEN (to_jsonb(s)->>'scenario_negative_balance_rate_delta_30d')::numeric
    WHEN 'SCENARIO_NSF_COUNT_DELTA_30D' THEN (to_jsonb(s)->>'scenario_nsf_count_delta_30d')::numeric
    WHEN 'SCENARIO_PROCESSOR_OUTAGE_RATE_DELTA_30D' THEN (to_jsonb(s)->>'scenario_processor_outage_rate_delta_30d')::numeric
    WHEN 'SCENARIO_REFUND_RATE_DELTA_30D' THEN (to_jsonb(s)->>'scenario_refund_rate_delta_30d')::numeric
    WHEN 'SCENARIO_CHARGEBACK_RATE_DELTA_30D' THEN (to_jsonb(s)->>'scenario_chargeback_rate_delta_30d')::numeric
    ELSE NULL END)) OR (v.value_status<>'AVAILABLE' AND v.value_numeric IS NOT NULL))=0 FROM _m1_9_vf v JOIN _m1_9_vs s USING(module1_run_id,scenario_id,merchant_application_id)),'0 mismatches','Every long feature value reconciles to its wide snapshot field.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_63_ROW_HASH_RECON','Canonical row-hash reconciliation',(SELECT count(*)::text FROM _m1_9_vmismatch),(SELECT count(*)=0 FROM _m1_9_vmismatch),'0 mismatches','Persisted row hashes independently recompute.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_64_SET_HASH_RECON','Canonical set-hash reconciliation',(SELECT format('%s/%s/%s',snapshot_ok,feature_ok,combined_ok) FROM _m1_9_vhash),(SELECT snapshot_ok AND feature_ok AND combined_ok FROM _m1_9_vhash),'true/true/true','Stored snapshot, long-feature, and combined set hashes independently reconcile.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_65_STAGE_BOUNDARIES','Strict downstream stage boundary',(SELECT format('final=%s risk=%s ead=%s latest=%s archive=%s',final_feature_rows,risk_rows,ead_rows,latest_rows,archive_rows) FROM _m1_9_vboundary),(SELECT final_feature_rows=0 AND risk_rows=0 AND ead_rows=0 AND latest_rows=0 AND archive_rows=0 FROM _m1_9_vboundary),'All zero','M1.9 does not create downstream credit-risk or contract outputs.');
  PERFORM pg_temp.m1_9_add_check('M1_9_POS_66_BLOCKING_ERRORS','Blocking configuration errors',(SELECT blocking_errors::text FROM _m1_9_vboundary),(SELECT blocking_errors=0 FROM _m1_9_vboundary),'0','No blocking configuration errors remain.');
END $checks$;

INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
SELECT (SELECT run_id FROM _m1_9_vctx),evidence_code,'PORTFOLIO',metric_name,observed_value,'TEXT',status,interpretation
FROM _m1_9_validation
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,
 metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
 interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry SET run_status=CASE WHEN (SELECT count(*) FILTER(WHERE status='FAIL') FROM _m1_9_validation)=0
 THEN 'M1_9_VALIDATED' ELSE 'M1_9_FAILED' END,
 notes=coalesce(notes,'')||E'
M1.9 positive validation executed: '||(SELECT count(*) FILTER(WHERE status='PASS') FROM _m1_9_validation)||'/66 PASS.'
WHERE run_id=(SELECT run_id FROM _m1_9_vctx);

COMMIT;
SELECT evidence_code,metric_name,observed_value,threshold_value,status,interpretation
FROM _m1_9_validation ORDER BY evidence_code;
