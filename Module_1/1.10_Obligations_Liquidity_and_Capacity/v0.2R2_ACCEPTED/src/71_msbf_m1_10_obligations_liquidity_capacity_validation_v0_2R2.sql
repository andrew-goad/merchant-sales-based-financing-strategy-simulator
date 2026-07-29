/* ============================================================================
MSBF M1.10 Obligations, Liquidity & Residual Cash Flow — Positive Validation
Version : v0.2R2
Purpose : Execute 70 blocking controls against persisted M1.10 obligation and
          scenario-aware capacity evidence without regenerating business logic.
Output  : One filterable 70-row result set. The session-scoped validation table
          survives COMMIT until the DBeaver connection closes or the script is
          rerun and explicitly drops it.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='15min';

DROP TABLE IF EXISTS _m1_10_validation;
DROP TABLE IF EXISTS _m1_10_vctx;
DROP TABLE IF EXISTS _m1_10_vob;
DROP TABLE IF EXISTS _m1_10_vcap;
DROP TABLE IF EXISTS _m1_10_vscen;
DROP TABLE IF EXISTS _m1_10_vapps;
DROP TABLE IF EXISTS _m1_10_vobagg;
DROP TABLE IF EXISTS _m1_10_vmismatch;
DROP TABLE IF EXISTS _m1_10_vhash;
DROP TABLE IF EXISTS _m1_10_vboundary;

CREATE TEMP TABLE _m1_10_vctx ON COMMIT PRESERVE ROWS AS
SELECT r.run_id,r.run_status,r.population_id,r.as_of_date,
       r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,
       pp.policy_profile_id,pp.profile_payload
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.policy_profile pp
  ON pp.profile_code='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY'
 AND pp.profile_version=1 AND pp.status='APPROVED'
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

CREATE TEMP TABLE _m1_10_vob ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.application_obligation_snapshot
WHERE created_by_run_id=(SELECT run_id FROM _m1_10_vctx);
CREATE INDEX ON _m1_10_vob(merchant_application_id,obligation_id);

CREATE TEMP TABLE _m1_10_vcap ON COMMIT PRESERVE ROWS AS
SELECT c.*,sr.scenario_code
FROM msbf_m1.application_liquidity_capacity_snapshot c
JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=c.scenario_id
WHERE c.module1_run_id=(SELECT run_id FROM _m1_10_vctx);
CREATE UNIQUE INDEX ON _m1_10_vcap(scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_10_vscen ON COMMIT PRESERVE ROWS AS
SELECT scenario_id,scenario_code,COUNT(*) AS rows,COUNT(DISTINCT merchant_application_id) AS applications
FROM _m1_10_vcap GROUP BY scenario_id,scenario_code;

CREATE TEMP TABLE _m1_10_vapps ON COMMIT PRESERVE ROWS AS
SELECT a.merchant_application_id,a.merchant_id,a.population_id,a.as_of_date,
       a.requested_remittance_rate,a.requested_expected_payoff_days,
       a.requested_total_repayment_amount,ia.industry_code,
       src.source_snapshot_id,src.availability_status,src.quality_status,src.data_confidence_score
FROM msbf_m1.merchant_application a
JOIN msbf_m1.merchant_industry_assignment ia
  ON ia.merchant_id=a.merchant_id AND ia.assignment_type='PRIMARY'
JOIN msbf_m1.source_snapshot src
  ON src.module1_run_id=a.created_by_run_id AND src.merchant_application_id=a.merchant_application_id
 AND src.source_code='OBLIGATIONS'
WHERE a.created_by_run_id=(SELECT run_id FROM _m1_10_vctx);
CREATE UNIQUE INDEX ON _m1_10_vapps(merchant_application_id);

CREATE TEMP TABLE _m1_10_vobagg ON COMMIT PRESERVE ROWS AS
SELECT merchant_application_id,count(*)::integer AS obligation_count,
       count(*) FILTER(WHERE short_term_financing_flag)::integer AS short_count,
       count(*) FILTER(WHERE secured_flag)::integer AS secured_count,
       count(*) FILTER(WHERE short_term_financing_flag AND stacking_sequence>1)::integer AS stacked_count,
       coalesce(max(stacking_sequence),0)::smallint AS max_stacking,
       coalesce(sum(outstanding_balance),0)::numeric(18,2) AS outstanding_total
FROM _m1_10_vob GROUP BY merchant_application_id;
CREATE UNIQUE INDEX ON _m1_10_vobagg(merchant_application_id);

CREATE TEMP TABLE _m1_10_vmismatch ON COMMIT PRESERVE ROWS AS
SELECT 'OBLIGATION|'||o.merchant_application_id||'|'||o.obligation_id||'|'||o.as_of_date AS entity_key,
       o.row_hash AS stored_hash,
       msbf_m1.m1_10_hash_jsonb(to_jsonb(o)-'row_hash'-'created_at') AS recomputed_hash
FROM _m1_10_vob o
WHERE o.row_hash IS DISTINCT FROM msbf_m1.m1_10_hash_jsonb(to_jsonb(o)-'row_hash'-'created_at')
UNION ALL
SELECT 'CAPACITY|'||c.scenario_id||'|'||c.merchant_application_id,
       c.row_hash,
       msbf_m1.m1_10_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at'-'scenario_code')
FROM _m1_10_vcap c
WHERE c.row_hash IS DISTINCT FROM msbf_m1.m1_10_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at'-'scenario_code');

CREATE TEMP TABLE _m1_10_vhash ON COMMIT PRESERVE ROWS AS
WITH ob AS (
  SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS hash
  FROM msbf_m1.m1_10_actual_obligation((SELECT run_id FROM _m1_10_vctx))
), cap AS (
  SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS hash
  FROM msbf_m1.m1_10_actual_capacity((SELECT run_id FROM _m1_10_vctx))
), all_rows AS (
  SELECT * FROM msbf_m1.m1_10_actual_obligation((SELECT run_id FROM _m1_10_vctx))
  UNION ALL
  SELECT * FROM msbf_m1.m1_10_actual_capacity((SELECT run_id FROM _m1_10_vctx))
), combined AS (
  SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS hash FROM all_rows
), stored AS (
  SELECT max(metric_value_text) FILTER(WHERE evidence_code='M1_10_OBLIGATION_SET_HASH') AS obligation_hash,
         max(metric_value_text) FILTER(WHERE evidence_code='M1_10_CAPACITY_SET_HASH') AS capacity_hash,
         max(metric_value_text) FILTER(WHERE evidence_code='M1_10_COMBINED_SET_HASH') AS combined_hash
  FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_10_vctx)
)
SELECT ob.hash AS recomputed_obligation_hash,cap.hash AS recomputed_capacity_hash,
       combined.hash AS recomputed_combined_hash,stored.obligation_hash AS stored_obligation_hash,
       stored.capacity_hash AS stored_capacity_hash,stored.combined_hash AS stored_combined_hash,
       ob.hash=stored.obligation_hash AS obligation_ok,
       cap.hash=stored.capacity_hash AS capacity_ok,
       combined.hash=stored.combined_hash AS combined_ok
FROM ob CROSS JOIN cap CROSS JOIN combined CROSS JOIN stored;

CREATE TEMP TABLE _m1_10_vboundary ON COMMIT PRESERVE ROWS AS
SELECT
 (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_10_vctx)) AS risk_rows,
 (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_10_vctx)) AS ead_rows,
 (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM _m1_10_vctx)) AS latest_rows,
 (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM _m1_10_vctx)) AS archive_rows,
 (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_10_vctx) AND severity='BLOCKING') AS blocking_errors;

CREATE TEMP TABLE _m1_10_validation(
    evidence_code text PRIMARY KEY,metric_name text NOT NULL,observed_value text,
    threshold_value text,status text NOT NULL,interpretation text
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m1_10_add_check(
    p_code text,p_name text,p_observed text,p_pass boolean,p_threshold text,p_interpretation text
) RETURNS void LANGUAGE plpgsql AS $fn$
BEGIN
  INSERT INTO _m1_10_validation VALUES(p_code,p_name,p_observed,p_threshold,
    CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,p_interpretation);
END;
$fn$;

DO $checks$
DECLARE v_run bigint := (SELECT run_id FROM _m1_10_vctx);
BEGIN
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_01_RUN_STATUS','Generation run status',(SELECT run_status FROM _m1_10_vctx),(SELECT run_status='M1_10_GENERATED' FROM _m1_10_vctx),'M1_10_GENERATED','Generation completed before validation.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_02_PREREQUISITE_GATES','Accepted predecessor gates',(SELECT count(*)::text FROM (SELECT DISTINCT ON(gate_id) gate_id,result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=v_run AND gate_id IN ('G1_CONTROL_PLANE','M1_2_POPULATION','M1_3_APPLICATION_REQUEST','M1_4_DAILY_POS_HISTORY','M1_5_DAILY_DEPOSIT_LIQUIDITY','M1_6_MATCHED_SCENARIO_OVERLAYS','M1_7_SOURCE_QUALITY_CONFIDENCE','M1_8_VERIFICATION_FRAUD_CONTINUITY','M1_9_ASOF_CASHFLOW_FEATURES') ORDER BY gate_id,review_version DESC) g WHERE result_status='PASS'),(SELECT count(*)=9 FROM (SELECT DISTINCT ON(gate_id) gate_id,result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=v_run AND gate_id IN ('G1_CONTROL_PLANE','M1_2_POPULATION','M1_3_APPLICATION_REQUEST','M1_4_DAILY_POS_HISTORY','M1_5_DAILY_DEPOSIT_LIQUIDITY','M1_6_MATCHED_SCENARIO_OVERLAYS','M1_7_SOURCE_QUALITY_CONFIDENCE','M1_8_VERIFICATION_FRAUD_CONTINUITY','M1_9_ASOF_CASHFLOW_FEATURES') ORDER BY gate_id,review_version DESC) g WHERE result_status='PASS'),'9','All accepted predecessor gates remain PASS.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_03_PARAMETER_HASH','Parameter snapshot hash',(SELECT parameter_snapshot_hash FROM _m1_10_vctx),(SELECT parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8' FROM _m1_10_vctx),'bd09e598c82db96e47459d77fd11e7c8','Accepted parameter identity is unchanged.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_04_PROFILE_HASH','Profile snapshot hash',(SELECT profile_snapshot_hash FROM _m1_10_vctx),(SELECT profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973' FROM _m1_10_vctx),'462cbd2ed92f68e5bdecf6b17537a973','Accepted profile identity is unchanged.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_05_SOURCE_HASH','Source snapshot hash',(SELECT source_snapshot_hash FROM _m1_10_vctx),(SELECT source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3' FROM _m1_10_vctx),'93c3d1368fb2450ab4a08e2b721f92d3','Accepted source identity is unchanged.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_06_POPULATION_HASH','Population hash',(SELECT population_hash FROM msbf_m1.population_registry WHERE population_id=(SELECT population_id FROM _m1_10_vctx)),(SELECT population_hash='9b706c926260a3ef1ae8ac95eed5d0bf' FROM msbf_m1.population_registry WHERE population_id=(SELECT population_id FROM _m1_10_vctx)),'9b706c926260a3ef1ae8ac95eed5d0bf','Population identity is unchanged.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_07_APPLICATION_HASH','Application hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO'),(SELECT metric_value_text='01485256b9b5748fb412743d35ced602' FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO'),'01485256b9b5748fb412743d35ced602','Application identity is unchanged.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_08_POS_HASH','Baseline POS hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO'),(SELECT metric_value_text='d1971e8d319483c187ec0c0483a31e33' FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO'),'d1971e8d319483c187ec0c0483a31e33','POS identity is unchanged.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_09_DEPOSIT_HASH','Baseline deposit hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_5_DEPOSIT_SET_HASH' AND segment_key='PORTFOLIO'),(SELECT metric_value_text='bbe96dd24fbbba3af4a587dd475a88d0' FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_5_DEPOSIT_SET_HASH' AND segment_key='PORTFOLIO'),'bbe96dd24fbbba3af4a587dd475a88d0','Deposit identity is unchanged.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_10_SCENARIO_HASH','Scenario set hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_6_COMBINED_SET_HASH' AND segment_key='PORTFOLIO'),(SELECT metric_value_text='3f85921bf6fc30ddc6cee146085e58c5' FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_6_COMBINED_SET_HASH' AND segment_key='PORTFOLIO'),'3f85921bf6fc30ddc6cee146085e58c5','Scenario identity is unchanged.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_11_M17_HASH','M1.7 source-quality hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_7_SOURCE_SET_HASH' AND segment_key='PORTFOLIO'),(SELECT metric_value_text='de56a458d9ec0b344886850592c4e6c8' FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_7_SOURCE_SET_HASH' AND segment_key='PORTFOLIO'),'de56a458d9ec0b344886850592c4e6c8','M1.7 identity is unchanged.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_12_M18_HASH','M1.8 combined hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_8_COMBINED_SET_HASH' AND segment_key='PORTFOLIO'),(SELECT metric_value_text='604a5640a25da92a850840dbe13e3d56' FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_8_COMBINED_SET_HASH' AND segment_key='PORTFOLIO'),'604a5640a25da92a850840dbe13e3d56','M1.8 identity is unchanged.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_13_M19_HASH','M1.9 combined hash',(SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_9_COMBINED_SET_HASH' AND segment_key='PORTFOLIO'),(SELECT metric_value_text='7c25acac533179f42789a6daa79d0cc3' FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code='M1_9_COMBINED_SET_HASH' AND segment_key='PORTFOLIO'),'7c25acac533179f42789a6daa79d0cc3','M1.9 identity is unchanged.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_14_POLICY','Approved M1.10 policy',(SELECT profile_payload->>'methodology_version' FROM _m1_10_vctx),(SELECT profile_payload->>'methodology_version'='M1_10_METHOD_V1' AND (profile_payload->>'generation_enabled')::boolean FROM _m1_10_vctx),'M1_10_METHOD_V1 enabled','The governed M1.10 methodology is approved and enabled.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_15_SCENARIOS','Matched scenario coverage',(SELECT format('%s scenarios / %s rows',count(*),sum(rows)) FROM _m1_10_vscen),(SELECT count(*)=2 AND sum(rows)=1500 AND bool_and(applications=750) FROM _m1_10_vscen),'2 scenarios / 1500 rows','BASELINE and RECESSION_ENERGY each cover 750 applications.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_16_APPLICATIONS','Application coverage',(SELECT count(*)::text FROM _m1_10_vapps),(SELECT count(*)=750 FROM _m1_10_vapps),'750','All accepted applications are represented.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_17_OBLIGATION_SOURCES','Obligation-source coverage',(SELECT count(*)::text FROM _m1_10_vapps WHERE source_snapshot_id IS NOT NULL),(SELECT count(*)=750 FROM _m1_10_vapps WHERE source_snapshot_id IS NOT NULL),'750','Each application retains governed obligation-source evidence.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_18_CAPACITY_ROWS','Capacity row count',(SELECT count(*)::text FROM _m1_10_vcap),(SELECT count(*)=1500 FROM _m1_10_vcap),'1500','Two scenario-aware capacity rows exist per application.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_19_CAPACITY_GRAIN','Unique capacity grain',(SELECT count(DISTINCT (scenario_id,merchant_application_id))::text FROM _m1_10_vcap),(SELECT count(*)=count(DISTINCT (scenario_id,merchant_application_id)) FROM _m1_10_vcap),'1500 unique','No duplicate scenario/application capacity rows exist.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_20_TWO_ROWS_PER_APP','Two scenarios per application',(SELECT count(*) FILTER(WHERE n<>2)::text FROM (SELECT merchant_application_id,count(*) n FROM _m1_10_vcap GROUP BY merchant_application_id) x),(SELECT count(*) FILTER(WHERE n<>2)=0 FROM (SELECT merchant_application_id,count(*) n FROM _m1_10_vcap GROUP BY merchant_application_id) x),'0 violations','Each application has exactly two matched capacity rows.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_21_OBLIGATION_ROWS','Bounded obligation rows',(SELECT count(*)::text FROM _m1_10_vob),(SELECT count(*)>0 AND count(*)<=2250 FROM _m1_10_vob),'1 to 2250','Atomic obligation population is nonempty and bounded to three per application.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_22_OBLIGATION_GRAIN','Unique obligation grain',(SELECT count(DISTINCT (merchant_application_id,obligation_id,as_of_date))::text FROM _m1_10_vob),(SELECT count(*)=count(DISTINCT (merchant_application_id,obligation_id,as_of_date)) FROM _m1_10_vob),'All unique','No duplicate application/obligation/as-of rows exist.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_23_UNAVAILABLE_NO_ROWS','Unavailable obligation source does not imply zero obligations',(SELECT count(*)::text FROM _m1_10_vob o JOIN _m1_10_vapps a USING(merchant_application_id) WHERE a.availability_status='UNAVAILABLE'),(SELECT count(*)=0 FROM _m1_10_vob o JOIN _m1_10_vapps a USING(merchant_application_id) WHERE a.availability_status='UNAVAILABLE'),'0','Unavailable evidence creates no fabricated obligation rows.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_24_OBLIGATION_COUNT_RECON','Capacity obligation-count reconciliation',(SELECT count(*)::text FROM _m1_10_vcap c LEFT JOIN _m1_10_vobagg a USING(merchant_application_id) WHERE c.obligation_count<>coalesce(a.obligation_count,0)),(SELECT count(*)=0 FROM _m1_10_vcap c LEFT JOIN _m1_10_vobagg a USING(merchant_application_id) WHERE c.obligation_count<>coalesce(a.obligation_count,0)),'0','Capacity rows reconcile to atomic obligation counts.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_25_OBLIGATION_TYPE_DOMAIN','Obligation-type domain',(SELECT count(*)::text FROM _m1_10_vob WHERE obligation_type NOT IN ('SALES_BASED_ADVANCE','TERM_LOAN','LINE_OF_CREDIT','EQUIPMENT_FINANCE','BUSINESS_CREDIT_CARD','LEASE')),(SELECT count(*)=0 FROM _m1_10_vob WHERE obligation_type NOT IN ('SALES_BASED_ADVANCE','TERM_LOAN','LINE_OF_CREDIT','EQUIPMENT_FINANCE','BUSINESS_CREDIT_CARD','LEASE')),'0','All obligations use governed types.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_26_PAYMENT_FREQUENCY','Payment-frequency consistency',(SELECT count(*)::text FROM _m1_10_vob WHERE (obligation_type='SALES_BASED_ADVANCE' AND (payment_frequency<>'SALES_LINKED' OR remittance_rate IS NULL)) OR (obligation_type<>'SALES_BASED_ADVANCE' AND payment_frequency<>'MONTHLY')),(SELECT count(*)=0 FROM _m1_10_vob WHERE (obligation_type='SALES_BASED_ADVANCE' AND (payment_frequency<>'SALES_LINKED' OR remittance_rate IS NULL)) OR (obligation_type<>'SALES_BASED_ADVANCE' AND payment_frequency<>'MONTHLY')),'0','Sales-based advances are sales-linked; other obligations are monthly.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_27_OBLIGATION_AMOUNTS','Nonnegative obligation amounts',(SELECT count(*)::text FROM _m1_10_vob WHERE outstanding_balance<0 OR daily_payment_amount<0 OR monthly_payment_amount<0),(SELECT count(*)=0 FROM _m1_10_vob WHERE outstanding_balance<0 OR daily_payment_amount<0 OR monthly_payment_amount<0),'0','Obligation amounts are nonnegative.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_28_MONTHLY_PAYMENT_IDENTITY','Obligation daily/monthly identity',(SELECT count(*)::text FROM _m1_10_vob WHERE abs(monthly_payment_amount-round(daily_payment_amount*30,2))>0.01),(SELECT count(*)=0 FROM _m1_10_vob WHERE abs(monthly_payment_amount-round(daily_payment_amount*30,2))>0.01),'0','Monthly obligation payment equals governed daily payment times thirty.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_29_REMITTANCE_RATE','Sales-linked remittance bounds',(SELECT count(*)::text FROM _m1_10_vob WHERE remittance_rate IS NOT NULL AND remittance_rate NOT BETWEEN 0.06 AND 0.18),(SELECT count(*)=0 FROM _m1_10_vob WHERE remittance_rate IS NOT NULL AND remittance_rate NOT BETWEEN 0.06 AND 0.18),'0','Synthetic sales-linked remittance rates remain within governed bounds.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_30_MATURITY','Maturity after as-of date',(SELECT count(*)::text FROM _m1_10_vob WHERE maturity_date<=as_of_date),(SELECT count(*)=0 FROM _m1_10_vob WHERE maturity_date<=as_of_date),'0','Active obligations mature after the as-of date.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_31_SECURED_LIEN','Secured/lien consistency',(SELECT count(*)::text FROM _m1_10_vob WHERE secured_flag IS DISTINCT FROM (lien_position IS NOT NULL)),(SELECT count(*)=0 FROM _m1_10_vob WHERE secured_flag IS DISTINCT FROM (lien_position IS NOT NULL)),'0','Lien evidence is present exactly for secured obligations.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_32_STACKING_SEQUENCE','Stacking-sequence consistency',(SELECT count(*)::text FROM _m1_10_vob WHERE (short_term_financing_flag AND stacking_sequence IS NULL) OR (NOT short_term_financing_flag AND stacking_sequence IS NOT NULL)),(SELECT count(*)=0 FROM _m1_10_vob WHERE (short_term_financing_flag AND stacking_sequence IS NULL) OR (NOT short_term_financing_flag AND stacking_sequence IS NOT NULL)),'0','Only short-term obligations carry stacking sequence.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_33_SOURCE_CONFIDENCE','Obligation confidence/source alignment',(SELECT count(*)::text FROM _m1_10_vob o JOIN _m1_10_vapps a USING(merchant_application_id) WHERE o.data_confidence_score IS DISTINCT FROM a.data_confidence_score OR o.obligation_quality_status IS DISTINCT FROM a.quality_status),(SELECT count(*)=0 FROM _m1_10_vob o JOIN _m1_10_vapps a USING(merchant_application_id) WHERE o.data_confidence_score IS DISTINCT FROM a.data_confidence_score OR o.obligation_quality_status IS DISTINCT FROM a.quality_status),'0','Atomic obligation evidence preserves M1.7 source confidence and quality.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_34_OBLIGATION_ROW_HASH','Obligation row-hash reconstruction',(SELECT count(*)::text FROM _m1_10_vmismatch WHERE entity_key LIKE 'OBLIGATION|%'),(SELECT count(*)=0 FROM _m1_10_vmismatch WHERE entity_key LIKE 'OBLIGATION|%'),'0','All obligation row hashes independently recompute.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_35_CAPACITY_ROW_HASH','Capacity row-hash reconstruction',(SELECT count(*)::text FROM _m1_10_vmismatch WHERE entity_key LIKE 'CAPACITY|%'),(SELECT count(*)=0 FROM _m1_10_vmismatch WHERE entity_key LIKE 'CAPACITY|%'),'0','All capacity row hashes independently recompute.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_36_SET_HASHES','Canonical set-hash reconstruction',(SELECT format('%s/%s/%s',obligation_ok,capacity_ok,combined_ok) FROM _m1_10_vhash),(SELECT obligation_ok AND capacity_ok AND combined_ok FROM _m1_10_vhash),'true/true/true','Stored obligation, capacity and combined hashes independently reconcile.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_37_HORIZON_REQUIRED_IDENTITY','Requested horizon-required daily repayment',(SELECT count(*)::text FROM _m1_10_vcap c JOIN msbf_m1.merchant_application a USING(merchant_application_id) WHERE abs(c.requested_horizon_required_daily_repayment-round(a.requested_total_repayment_amount/greatest(a.requested_expected_payoff_days,1),2))>0.01),(SELECT count(*)=0 FROM _m1_10_vcap c JOIN msbf_m1.merchant_application a USING(merchant_application_id) WHERE abs(c.requested_horizon_required_daily_repayment-round(a.requested_total_repayment_amount/greatest(a.requested_expected_payoff_days,1),2))>0.01),'0','Horizon-required daily burden reconciles to requested repayment and duration.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_38_RATE_BASED_IDENTITY','Requested rate-based daily remittance',(SELECT count(*)::text FROM _m1_10_vcap c JOIN msbf_m1.merchant_application a USING(merchant_application_id) JOIN msbf_m1.application_cashflow_feature_snapshot f ON f.module1_run_id=c.module1_run_id AND f.scenario_id=c.scenario_id AND f.merchant_application_id=c.merchant_application_id WHERE c.requested_rate_based_daily_remittance IS DISTINCT FROM CASE WHEN f.avg_daily_eligible_sales_30d IS NULL THEN NULL ELSE round(f.avg_daily_eligible_sales_30d*a.requested_remittance_rate,2) END),(SELECT count(*)=0 FROM _m1_10_vcap c JOIN msbf_m1.merchant_application a USING(merchant_application_id) JOIN msbf_m1.application_cashflow_feature_snapshot f ON f.module1_run_id=c.module1_run_id AND f.scenario_id=c.scenario_id AND f.merchant_application_id=c.merchant_application_id WHERE c.requested_rate_based_daily_remittance IS DISTINCT FROM CASE WHEN f.avg_daily_eligible_sales_30d IS NULL THEN NULL ELSE round(f.avg_daily_eligible_sales_30d*a.requested_remittance_rate,2) END),'0','Rate-based requested remittance uses matched scenario sales.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_39_CONSERVATIVE_REQUESTED_BURDEN','Conservative requested burden identity',(SELECT count(*)::text FROM _m1_10_vcap WHERE requested_daily_remittance_amount IS DISTINCT FROM greatest(coalesce(requested_rate_based_daily_remittance,0),requested_horizon_required_daily_repayment)),(SELECT count(*)=0 FROM _m1_10_vcap WHERE requested_daily_remittance_amount IS DISTINCT FROM greatest(coalesce(requested_rate_based_daily_remittance,0),requested_horizon_required_daily_repayment)),'0','Requested burden is the greater of rate-based and horizon-required amounts.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_40_REQUESTED_MONTHLY_IDENTITY','Requested daily/monthly identity',(SELECT count(*)::text FROM _m1_10_vcap WHERE abs(requested_monthly_remittance_amount-round(requested_daily_remittance_amount*30,2))>0.01),(SELECT count(*)=0 FROM _m1_10_vcap WHERE abs(requested_monthly_remittance_amount-round(requested_daily_remittance_amount*30,2))>0.01),'0','Requested monthly burden equals daily burden times thirty.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_41_EXISTING_MONTHLY_IDENTITY','Existing daily/monthly identity',(SELECT count(*)::text FROM _m1_10_vcap WHERE abs(existing_monthly_payment_amount-round(existing_daily_payment_amount*30,2))>0.01),(SELECT count(*)=0 FROM _m1_10_vcap WHERE abs(existing_monthly_payment_amount-round(existing_daily_payment_amount*30,2))>0.01),'0','Existing monthly burden equals daily burden times thirty.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_42_TOTAL_DAILY_IDENTITY','Total daily burden identity',(SELECT count(*)::text FROM _m1_10_vcap WHERE abs(total_daily_obligation_burden-round(existing_daily_payment_amount+requested_daily_remittance_amount,2))>0.01),(SELECT count(*)=0 FROM _m1_10_vcap WHERE abs(total_daily_obligation_burden-round(existing_daily_payment_amount+requested_daily_remittance_amount,2))>0.01),'0','Total daily burden equals existing plus requested burden.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_43_TOTAL_MONTHLY_IDENTITY','Total monthly burden identity',(SELECT count(*)::text FROM _m1_10_vcap WHERE abs(total_monthly_obligation_burden-round(total_daily_obligation_burden*30,2))>0.01),(SELECT count(*)=0 FROM _m1_10_vcap WHERE abs(total_monthly_obligation_burden-round(total_daily_obligation_burden*30,2))>0.01),'0','Total monthly burden equals daily burden times thirty.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_44_OPERATING_CASH_IDENTITY','Estimated operating-cash identity',(SELECT count(*)::text FROM _m1_10_vcap c JOIN _m1_10_vapps a USING(merchant_application_id) JOIN msbf_m1.application_cashflow_feature_snapshot f ON f.module1_run_id=c.module1_run_id AND f.scenario_id=c.scenario_id AND f.merchant_application_id=c.merchant_application_id CROSS JOIN _m1_10_vctx x WHERE c.estimated_daily_operating_cash_flow IS DISTINCT FROM CASE WHEN f.avg_daily_eligible_sales_30d IS NULL THEN NULL ELSE round(f.avg_daily_eligible_sales_30d*((x.profile_payload->'industry_operating_cash_margin'->>a.industry_code)::numeric),2) END),(SELECT count(*)=0 FROM _m1_10_vcap c JOIN _m1_10_vapps a USING(merchant_application_id) JOIN msbf_m1.application_cashflow_feature_snapshot f ON f.module1_run_id=c.module1_run_id AND f.scenario_id=c.scenario_id AND f.merchant_application_id=c.merchant_application_id CROSS JOIN _m1_10_vctx x WHERE c.estimated_daily_operating_cash_flow IS DISTINCT FROM CASE WHEN f.avg_daily_eligible_sales_30d IS NULL THEN NULL ELSE round(f.avg_daily_eligible_sales_30d*((x.profile_payload->'industry_operating_cash_margin'->>a.industry_code)::numeric),2) END),'0','Operating cash flow uses matched sales and governed industry margin.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_45_EXISTING_BURDEN_RATE','Existing obligation-to-sales identity',(SELECT count(*)::text FROM _m1_10_vcap c JOIN msbf_m1.application_cashflow_feature_snapshot f ON f.module1_run_id=c.module1_run_id AND f.scenario_id=c.scenario_id AND f.merchant_application_id=c.merchant_application_id WHERE c.existing_obligation_to_sales_rate IS DISTINCT FROM CASE WHEN f.avg_daily_eligible_sales_30d IS NULL THEN NULL ELSE round(c.existing_daily_payment_amount/greatest(f.avg_daily_eligible_sales_30d,1),8) END),(SELECT count(*)=0 FROM _m1_10_vcap c JOIN msbf_m1.application_cashflow_feature_snapshot f ON f.module1_run_id=c.module1_run_id AND f.scenario_id=c.scenario_id AND f.merchant_application_id=c.merchant_application_id WHERE c.existing_obligation_to_sales_rate IS DISTINCT FROM CASE WHEN f.avg_daily_eligible_sales_30d IS NULL THEN NULL ELSE round(c.existing_daily_payment_amount/greatest(f.avg_daily_eligible_sales_30d,1),8) END),'0','Existing burden rate reconciles to scenario sales.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_46_TOTAL_BURDEN_RATE','Total obligation-to-sales identity',(SELECT count(*)::text FROM _m1_10_vcap c JOIN msbf_m1.application_cashflow_feature_snapshot f ON f.module1_run_id=c.module1_run_id AND f.scenario_id=c.scenario_id AND f.merchant_application_id=c.merchant_application_id WHERE c.total_obligation_to_sales_rate IS DISTINCT FROM CASE WHEN f.avg_daily_eligible_sales_30d IS NULL THEN NULL ELSE round(c.total_daily_obligation_burden/greatest(f.avg_daily_eligible_sales_30d,1),8) END),(SELECT count(*)=0 FROM _m1_10_vcap c JOIN msbf_m1.application_cashflow_feature_snapshot f ON f.module1_run_id=c.module1_run_id AND f.scenario_id=c.scenario_id AND f.merchant_application_id=c.merchant_application_id WHERE c.total_obligation_to_sales_rate IS DISTINCT FROM CASE WHEN f.avg_daily_eligible_sales_30d IS NULL THEN NULL ELSE round(c.total_daily_obligation_burden/greatest(f.avg_daily_eligible_sales_30d,1),8) END),'0','Total burden rate reconciles to scenario sales.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_47_COVERAGE_IDENTITY','Payment coverage identity',(SELECT count(*)::text FROM _m1_10_vcap WHERE sales_linked_payment_coverage_ratio IS DISTINCT FROM CASE WHEN estimated_daily_operating_cash_flow IS NULL THEN NULL ELSE round(estimated_daily_operating_cash_flow/greatest(total_daily_obligation_burden,1),8) END),(SELECT count(*)=0 FROM _m1_10_vcap WHERE sales_linked_payment_coverage_ratio IS DISTINCT FROM CASE WHEN estimated_daily_operating_cash_flow IS NULL THEN NULL ELSE round(estimated_daily_operating_cash_flow/greatest(total_daily_obligation_burden,1),8) END),'0','Coverage equals operating cash flow divided by total burden.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_48_RESIDUAL_DAILY_IDENTITY','Residual daily cash-flow identity',(SELECT count(*)::text FROM _m1_10_vcap WHERE residual_daily_operating_cash_flow IS DISTINCT FROM CASE WHEN estimated_daily_operating_cash_flow IS NULL THEN NULL ELSE round(estimated_daily_operating_cash_flow-total_daily_obligation_burden,2) END),(SELECT count(*)=0 FROM _m1_10_vcap WHERE residual_daily_operating_cash_flow IS DISTINCT FROM CASE WHEN estimated_daily_operating_cash_flow IS NULL THEN NULL ELSE round(estimated_daily_operating_cash_flow-total_daily_obligation_burden,2) END),'0','Residual daily cash flow reconciles.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_49_RESIDUAL_MONTHLY_IDENTITY','Residual daily/monthly identity',(SELECT count(*)::text FROM _m1_10_vcap WHERE residual_monthly_operating_cash_flow IS DISTINCT FROM CASE WHEN residual_daily_operating_cash_flow IS NULL THEN NULL ELSE round(residual_daily_operating_cash_flow*30,2) END),(SELECT count(*)=0 FROM _m1_10_vcap WHERE residual_monthly_operating_cash_flow IS DISTINCT FROM CASE WHEN residual_daily_operating_cash_flow IS NULL THEN NULL ELSE round(residual_daily_operating_cash_flow*30,2) END),'0','Residual monthly cash flow equals daily residual times thirty.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_50_POST_BUFFER_IDENTITY','Post-financing buffer identity',(SELECT count(*)::text FROM _m1_10_vcap c CROSS JOIN _m1_10_vctx x WHERE c.post_financing_liquidity_buffer_amount IS DISTINCT FROM CASE WHEN c.current_liquidity_buffer_amount IS NULL OR c.residual_daily_operating_cash_flow IS NULL THEN NULL ELSE round(c.current_liquidity_buffer_amount+c.residual_daily_operating_cash_flow*(x.profile_payload->>'liquidity_projection_days')::integer,2) END),(SELECT count(*)=0 FROM _m1_10_vcap c CROSS JOIN _m1_10_vctx x WHERE c.post_financing_liquidity_buffer_amount IS DISTINCT FROM CASE WHEN c.current_liquidity_buffer_amount IS NULL OR c.residual_daily_operating_cash_flow IS NULL THEN NULL ELSE round(c.current_liquidity_buffer_amount+c.residual_daily_operating_cash_flow*(x.profile_payload->>'liquidity_projection_days')::integer,2) END),'0','Post-financing buffer reconciles to current liquidity plus projected residual cash flow.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_51_BUFFER_DAYS_IDENTITY','Post-financing buffer-days identity',(SELECT count(*)::text FROM _m1_10_vcap WHERE post_financing_buffer_days IS DISTINCT FROM CASE WHEN post_financing_liquidity_buffer_amount IS NULL THEN NULL ELSE round(post_financing_liquidity_buffer_amount/greatest(total_daily_obligation_burden,1),4) END),(SELECT count(*)=0 FROM _m1_10_vcap WHERE post_financing_buffer_days IS DISTINCT FROM CASE WHEN post_financing_liquidity_buffer_amount IS NULL THEN NULL ELSE round(post_financing_liquidity_buffer_amount/greatest(total_daily_obligation_burden,1),4) END),'0','Buffer days reconcile to projected liquidity and daily burden.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_52_CONCENTRATION_IDENTITY','Obligation concentration identity',(SELECT count(*)::text FROM _m1_10_vcap WHERE obligation_concentration_rate NOT BETWEEN 0 AND 1 OR obligation_concentration_rate IS DISTINCT FROM CASE WHEN existing_daily_payment_amount>0 THEN round(largest_existing_daily_payment_amount/existing_daily_payment_amount,8) ELSE 0::numeric END),(SELECT count(*)=0 FROM _m1_10_vcap WHERE obligation_concentration_rate NOT BETWEEN 0 AND 1 OR obligation_concentration_rate IS DISTINCT FROM CASE WHEN existing_daily_payment_amount>0 THEN round(largest_existing_daily_payment_amount/existing_daily_payment_amount,8) ELSE 0::numeric END),'0','Concentration is bounded and reconciles to largest/total existing burden.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_53_STACKING_DEPTH','Stacking-depth identity',(SELECT count(*)::text FROM _m1_10_vcap WHERE stacking_depth<>short_term_obligation_count+1),(SELECT count(*)=0 FROM _m1_10_vcap WHERE stacking_depth<>short_term_obligation_count+1),'0','Stacking depth includes existing short-term obligations plus the requested structure.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_54_INDEPENDENT_TIER_DOMAIN','Independent capacity-tier domain',(SELECT count(*)::text FROM _m1_10_vcap WHERE independent_capacity_tier NOT BETWEEN 1 AND 5),(SELECT count(*)=0 FROM _m1_10_vcap WHERE independent_capacity_tier NOT BETWEEN 1 AND 5),'0','Independent capacity tiers are within the governed domain.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_55_BASELINE_TIER_ALIGNMENT','Baseline capacity-tier alignment',(SELECT count(*)::text FROM _m1_10_vcap WHERE scenario_code='BASELINE' AND (capacity_tier<>independent_capacity_tier OR baseline_capacity_tier<>independent_capacity_tier)),(SELECT count(*)=0 FROM _m1_10_vcap WHERE scenario_code='BASELINE' AND (capacity_tier<>independent_capacity_tier OR baseline_capacity_tier<>independent_capacity_tier)),'0','Baseline final and reference tiers equal independent baseline capacity.');
  PERFORM pg_temp.m1_10_add_check(
    'M1_10_POS_56_STRESS_NONIMPROVEMENT',
    'Stress capacity non-improvement',
    (SELECT count(*)::text
       FROM _m1_10_vcap c
      WHERE c.scenario_code='RECESSION_ENERGY'
        AND c.capacity_tier < c.baseline_capacity_tier),
    NOT EXISTS (
      SELECT 1
        FROM _m1_10_vcap c
       WHERE c.scenario_code='RECESSION_ENERGY'
         AND c.capacity_tier < c.baseline_capacity_tier
    ),
    '0',
    'Adverse stress cannot improve the interpreted capacity tier.'
  );
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_57_STRESS_WORSENING_FLAG','Stress-worsening flag identity',(SELECT count(*)::text FROM _m1_10_vcap WHERE stress_capacity_worsening_flag IS DISTINCT FROM (scenario_code='RECESSION_ENERGY' AND capacity_tier>baseline_capacity_tier)),(SELECT count(*)=0 FROM _m1_10_vcap WHERE stress_capacity_worsening_flag IS DISTINCT FROM (scenario_code='RECESSION_ENERGY' AND capacity_tier>baseline_capacity_tier)),'0','Stress-worsening flags reconcile to final and baseline tiers.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_58_AFFORDABILITY_MAPPING','Affordability-status mapping',(SELECT count(*)::text FROM _m1_10_vcap WHERE affordability_status IS DISTINCT FROM CASE WHEN capacity_tier IN (1,2) THEN 'AFFORDABLE' WHEN capacity_tier=3 THEN 'MARGINAL' WHEN capacity_tier=4 THEN 'UNAFFORDABLE' ELSE 'INSUFFICIENT_EVIDENCE' END),(SELECT count(*)=0 FROM _m1_10_vcap WHERE affordability_status IS DISTINCT FROM CASE WHEN capacity_tier IN (1,2) THEN 'AFFORDABLE' WHEN capacity_tier=3 THEN 'MARGINAL' WHEN capacity_tier=4 THEN 'UNAFFORDABLE' ELSE 'INSUFFICIENT_EVIDENCE' END),'0','Affordability status maps exactly from final capacity tier.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_59_EVIDENCE_STATUS','Capacity-evidence status logic',(SELECT count(*)::text FROM _m1_10_vcap WHERE (capacity_evidence_status='BLOCKED') IS DISTINCT FROM (feature_completeness_status='BLOCKED' OR obligation_availability_status='UNAVAILABLE' OR estimated_daily_operating_cash_flow IS NULL)),(SELECT count(*)=0 FROM _m1_10_vcap WHERE (capacity_evidence_status='BLOCKED') IS DISTINCT FROM (feature_completeness_status='BLOCKED' OR obligation_availability_status='UNAVAILABLE' OR estimated_daily_operating_cash_flow IS NULL)),'0','Blocked capacity evidence is explicit and not converted into weak merchant performance.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_60_FALLBACK_LOGIC','Controlled fallback-path logic',(SELECT count(*)::text FROM _m1_10_vcap WHERE (obligation_availability_status='UNAVAILABLE' AND fallback_path_code<>'MANUAL_OBLIGATION_REVIEW') OR (obligation_quality_status='CONFLICT' AND fallback_path_code<>'SOURCE_CONFLICT_REVIEW') OR (feature_completeness_status='BLOCKED' AND obligation_availability_status<>'UNAVAILABLE' AND obligation_quality_status<>'CONFLICT' AND fallback_path_code<>'INSUFFICIENT_CASHFLOW_EVIDENCE')),(SELECT count(*)=0 FROM _m1_10_vcap WHERE (obligation_availability_status='UNAVAILABLE' AND fallback_path_code<>'MANUAL_OBLIGATION_REVIEW') OR (obligation_quality_status='CONFLICT' AND fallback_path_code<>'SOURCE_CONFLICT_REVIEW') OR (feature_completeness_status='BLOCKED' AND obligation_availability_status<>'UNAVAILABLE' AND obligation_quality_status<>'CONFLICT' AND fallback_path_code<>'INSUFFICIENT_CASHFLOW_EVIDENCE')),'0','Missing, conflicting, and blocked evidence routes explicitly.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_61_MANUAL_REVIEW_LOGIC','Manual-review recommendation logic',(SELECT count(*)::text FROM _m1_10_vcap c CROSS JOIN _m1_10_vctx x WHERE manual_review_recommended_flag IS DISTINCT FROM (capacity_tier>=3 OR capacity_evidence_status<>'COMPLETE' OR stacking_depth>=(x.profile_payload->>'stacking_review_threshold')::integer OR obligation_concentration_rate>=(x.profile_payload->>'concentration_review_threshold')::numeric OR verification_disposition<>'CLEAR')),(SELECT count(*)=0 FROM _m1_10_vcap c CROSS JOIN _m1_10_vctx x WHERE manual_review_recommended_flag IS DISTINCT FROM (capacity_tier>=3 OR capacity_evidence_status<>'COMPLETE' OR stacking_depth>=(x.profile_payload->>'stacking_review_threshold')::integer OR obligation_concentration_rate>=(x.profile_payload->>'concentration_review_threshold')::numeric OR verification_disposition<>'CLEAR')),'0','Manual-review recommendations follow governed evidence, stacking, concentration, verification and capacity rules.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_62_UNAVAILABLE_INSUFFICIENT','Unavailable obligations remain insufficient evidence',(SELECT count(*)::text FROM _m1_10_vcap WHERE obligation_availability_status='UNAVAILABLE' AND (capacity_tier<>5 OR affordability_status<>'INSUFFICIENT_EVIDENCE')),(SELECT count(*)=0 FROM _m1_10_vcap WHERE obligation_availability_status='UNAVAILABLE' AND (capacity_tier<>5 OR affordability_status<>'INSUFFICIENT_EVIDENCE')),'0','Unavailable obligation evidence is not treated as no obligations.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_63_CONFLICT_REVIEW','Conflicting obligation evidence routes to review',(SELECT count(*)::text FROM _m1_10_vcap WHERE obligation_quality_status='CONFLICT' AND (fallback_path_code<>'SOURCE_CONFLICT_REVIEW' OR NOT manual_review_recommended_flag)),(SELECT count(*)=0 FROM _m1_10_vcap WHERE obligation_quality_status='CONFLICT' AND (fallback_path_code<>'SOURCE_CONFLICT_REVIEW' OR NOT manual_review_recommended_flag)),'0','Source conflicts remain explicit review conditions.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_64_MATCHED_COVERAGE','Matched baseline/stress application coverage',(SELECT count(*)::text FROM (SELECT merchant_application_id,count(DISTINCT scenario_code) n FROM _m1_10_vcap GROUP BY merchant_application_id) x WHERE n<>2),(SELECT count(*)=0 FROM (SELECT merchant_application_id,count(DISTINCT scenario_code) n FROM _m1_10_vcap GROUP BY merchant_application_id) x WHERE n<>2),'0','Every application has matched baseline and stress capacity evidence.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_65_SOURCE_LINEAGE','Capacity/source-snapshot lineage',(SELECT count(*)::text FROM _m1_10_vcap c JOIN _m1_10_vapps a USING(merchant_application_id) WHERE c.obligation_source_snapshot_id<>a.source_snapshot_id OR c.obligation_availability_status<>a.availability_status OR c.obligation_quality_status<>a.quality_status),(SELECT count(*)=0 FROM _m1_10_vcap c JOIN _m1_10_vapps a USING(merchant_application_id) WHERE c.obligation_source_snapshot_id<>a.source_snapshot_id OR c.obligation_availability_status<>a.availability_status OR c.obligation_quality_status<>a.quality_status),'0','Capacity rows preserve obligation-source lineage.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_66_FEATURE_LINEAGE','Capacity/M1.9 feature lineage',(SELECT count(*)::text FROM _m1_10_vcap c LEFT JOIN msbf_m1.application_cashflow_feature_snapshot f ON f.module1_run_id=c.module1_run_id AND f.scenario_id=c.scenario_id AND f.merchant_application_id=c.merchant_application_id WHERE f.merchant_application_id IS NULL),(SELECT count(*)=0 FROM _m1_10_vcap c LEFT JOIN msbf_m1.application_cashflow_feature_snapshot f ON f.module1_run_id=c.module1_run_id AND f.scenario_id=c.scenario_id AND f.merchant_application_id=c.merchant_application_id WHERE f.merchant_application_id IS NULL),'0','Every capacity row is tied to an accepted M1.9 feature snapshot.');
  PERFORM pg_temp.m1_10_add_check(
    'M1_10_POS_67_NO_FUTURE_DATA',
    'No future-dated obligation/capacity evidence',
    (
      SELECT (
        (SELECT count(*)
           FROM _m1_10_vob
          WHERE as_of_date > (SELECT as_of_date FROM _m1_10_vctx))
        +
        (SELECT count(*)
           FROM _m1_10_vcap
          WHERE as_of_date > (SELECT as_of_date FROM _m1_10_vctx))
      )::text
    ),
    NOT EXISTS (
      SELECT 1
        FROM _m1_10_vob
       WHERE as_of_date > (SELECT as_of_date FROM _m1_10_vctx)
    )
    AND NOT EXISTS (
      SELECT 1
        FROM _m1_10_vcap
       WHERE as_of_date > (SELECT as_of_date FROM _m1_10_vctx)
    ),
    '0',
    'All evidence is bounded by the governed as-of date.'
  );
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_68_GENERATION_EVIDENCE','Generation-evidence completeness',(SELECT count(*)::text FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code IN ('M1_10_GENERATION_SPEC','M1_10_OBLIGATION_ENTITY_COUNT','M1_10_CAPACITY_ENTITY_COUNT','M1_10_CANONICAL_ENTITY_COUNT','M1_10_CANONICAL_MISMATCH_COUNT','M1_10_OBLIGATION_SET_HASH','M1_10_CAPACITY_SET_HASH','M1_10_COMBINED_SET_HASH','M1_10_GENERATION_SUMMARY')),(SELECT count(*)=9 FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code IN ('M1_10_GENERATION_SPEC','M1_10_OBLIGATION_ENTITY_COUNT','M1_10_CAPACITY_ENTITY_COUNT','M1_10_CANONICAL_ENTITY_COUNT','M1_10_CANONICAL_MISMATCH_COUNT','M1_10_OBLIGATION_SET_HASH','M1_10_CAPACITY_SET_HASH','M1_10_COMBINED_SET_HASH','M1_10_GENERATION_SUMMARY')),'9','All governed generation evidence is persisted.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_69_STAGE_BOUNDARIES','Strict downstream stage boundary',(SELECT format('risk=%s ead=%s latest=%s archive=%s',risk_rows,ead_rows,latest_rows,archive_rows) FROM _m1_10_vboundary),(SELECT risk_rows=0 AND ead_rows=0 AND latest_rows=0 AND archive_rows=0 FROM _m1_10_vboundary),'All zero','M1.10 does not create downstream risk, exposure, decision or contract outputs.');
  PERFORM pg_temp.m1_10_add_check('M1_10_POS_70_BLOCKING_ERRORS','Blocking configuration errors',(SELECT blocking_errors::text FROM _m1_10_vboundary),(SELECT blocking_errors=0 FROM _m1_10_vboundary),'0','No blocking configuration errors remain.');
END;
$checks$;

INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation
)
SELECT (SELECT run_id FROM _m1_10_vctx),evidence_code,'PORTFOLIO',metric_name,observed_value,'TEXT',status,interpretation
FROM _m1_10_validation
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,
    unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,
    created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry
SET run_status=CASE WHEN (SELECT count(*) FILTER(WHERE status='FAIL') FROM _m1_10_validation)=0
                    THEN 'M1_10_VALIDATED' ELSE 'M1_10_FAILED' END,
    notes=coalesce(notes,'')||E'\nM1.10 positive validation executed: '
       ||(SELECT count(*) FILTER(WHERE status='PASS') FROM _m1_10_validation)||'/70 PASS.'
WHERE run_id=(SELECT run_id FROM _m1_10_vctx);

COMMIT;

SELECT evidence_code,metric_name,observed_value,threshold_value,status,interpretation
FROM _m1_10_validation ORDER BY evidence_code;
