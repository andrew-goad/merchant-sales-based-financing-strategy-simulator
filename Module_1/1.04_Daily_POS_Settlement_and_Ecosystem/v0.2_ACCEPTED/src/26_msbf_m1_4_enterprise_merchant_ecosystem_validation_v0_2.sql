/* ============================================================================
MSBF M1.4 Enterprise Merchant Ecosystem — Positive Validation
Version : v0.2
Purpose : Recompute the daily ecosystem blueprint, validate exact grain and
          chronology, POS/settlement identities, deterministic reproduction,
          operating diversity, processor continuity, and stage boundaries.
============================================================================ */
BEGIN;

DO $do$
DECLARE v_run_id bigint; v_status text;
BEGIN
 SELECT run_id,run_status INTO STRICT v_run_id,v_status
 FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 IF v_status='M1_4_ACCEPTED' THEN RAISE EXCEPTION 'M1.4 is already accepted; validation evidence is frozen.'; END IF;
 IF v_status NOT IN ('M1_4_GENERATED','M1_4_VALIDATED','M1_4_FAILED') THEN
  RAISE EXCEPTION 'M1.4 validation requires generated daily history; observed run_status=%.',v_status;
 END IF;
 DELETE FROM msbf_ctl.run_evidence
 WHERE run_id=v_run_id AND evidence_code ~ '^M1_4_POS_[0-9]{2}_';
END $do$;

CREATE TEMP TABLE _m1_4_blueprint ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_4_daily_pos_blueprint(
 (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE INDEX ON _m1_4_blueprint(merchant_id,observation_date);
CREATE INDEX ON _m1_4_blueprint(industry_code,cashflow_archetype_code);

CREATE TEMP TABLE _m1_4_validation_context ON COMMIT DROP AS
SELECT r.run_id,
       (rps.resolved_value->>'value_numeric')::numeric AS currency_tolerance
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.run_parameter_snapshot rps
  ON rps.run_id=r.run_id
 AND rps.parameter_name='qa_reconciliation_tolerance_amount'
 AND rps.scope_key='GLOBAL'
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

CREATE TEMP TABLE _m1_4_checks(
 evidence_code text PRIMARY KEY,metric_name text NOT NULL,observed_value text NOT NULL,
 expected_value text NOT NULL,pass_flag boolean NOT NULL,interpretation text NOT NULL
) ON COMMIT DROP;

/* 01 — stage status */
INSERT INTO _m1_4_checks
SELECT 'M1_4_POS_01_RUN_STAGE_STATUS','Run stage status',run_status,
 'M1_4_GENERATED or M1_4_VALIDATED or M1_4_FAILED',
 run_status IN ('M1_4_GENERATED','M1_4_VALIDATED','M1_4_FAILED'),
 'Daily ecosystem rows must exist before validation.'
FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

/* 02–04 — prerequisite gates */
INSERT INTO _m1_4_checks
SELECT 'M1_4_POS_02_G1_GATE','Latest G1 gate status',COALESCE(result_status,'MISSING'),'PASS',COALESCE(result_status='PASS',false),
 'M1.4 remains dependent on accepted governed configuration.'
FROM (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1) AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1) q;
INSERT INTO _m1_4_checks
SELECT 'M1_4_POS_03_M1_2_GATE','Latest M1.2 gate status',COALESCE(result_status,'MISSING'),'PASS',COALESCE(result_status='PASS',false),
 'M1.4 uses the accepted deterministic merchant universe.'
FROM (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1) AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1) q;
INSERT INTO _m1_4_checks
SELECT 'M1_4_POS_04_M1_3_GATE','Latest M1.3 gate status',COALESCE(result_status,'MISSING'),'PASS',COALESCE(result_status='PASS',false),
 'M1.4 is authorized only from accepted application and requested-structure evidence.'
FROM (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1) AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) q;

/* 05 — accepted G1 hashes */
INSERT INTO _m1_4_checks
SELECT 'M1_4_POS_05_ACCEPTED_G1_HASHES','Accepted G1 hashes',
 parameter_snapshot_hash||'|'||profile_snapshot_hash||'|'||source_snapshot_hash,
 'bd09e598c82db96e47459d77fd11e7c8|462cbd2ed92f68e5bdecf6b17537a973|93c3d1368fb2450ab4a08e2b721f92d3',
 parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
 AND profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
 AND source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3',
 'M1.4 must not change accepted parameter, profile, or source snapshots.'
FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

/* 06 — recomputed G1 hashes */
INSERT INTO _m1_4_checks
WITH ctx AS (SELECT * FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), h AS (
 SELECT
  (SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key)) FROM msbf_ctl.run_parameter_snapshot WHERE run_id=ctx.run_id) ph,
  (SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code)) FROM msbf_ctl.run_profile_snapshot WHERE run_id=ctx.run_id) prh,
  (SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code)) FROM msbf_ctl.run_source_snapshot WHERE run_id=ctx.run_id) sh
 FROM ctx)
SELECT 'M1_4_POS_06_RECOMPUTED_G1_HASHES','Recomputed G1 hash reconciliation',h.ph||'|'||h.prh||'|'||h.sh,
 ctx.parameter_snapshot_hash||'|'||ctx.profile_snapshot_hash||'|'||ctx.source_snapshot_hash,
 h.ph=ctx.parameter_snapshot_hash AND h.prh=ctx.profile_snapshot_hash AND h.sh=ctx.source_snapshot_hash,
 'Frozen G1 content independently reconciles.' FROM ctx CROSS JOIN h;

/* 07 — population hash */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id,population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT p.population_hash,(SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM r))) recomputed
 FROM msbf_m1.population_registry p WHERE p.population_id=(SELECT population_id FROM r))
SELECT 'M1_4_POS_07_POPULATION_HASH','Accepted M1.2 population hash',population_hash,'9b706c926260a3ef1ae8ac95eed5d0bf',
 population_hash='9b706c926260a3ef1ae8ac95eed5d0bf' AND population_hash=recomputed,
 'Daily history remains anchored to the accepted merchant population.' FROM x;

/* 08 — application hash */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') stored,
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM r))) recomputed)
SELECT 'M1_4_POS_08_APPLICATION_HASH','Accepted M1.3 application hash',stored,'01485256b9b5748fb412743d35ced602',
 stored='01485256b9b5748fb412743d35ced602' AND stored=recomputed,
 'M1.4 does not modify accepted application/request evidence.' FROM x;

/* 09 — generation specification hash */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), s AS (
 SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_4_GENERATION_SPEC' AND segment_key='PORTFOLIO'), h AS (
 SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_4_GENERATION_SPEC_HASH' AND segment_key='PORTFOLIO')
SELECT 'M1_4_POS_09_GENERATION_SPEC','Generation specification hash',COALESCE(h.metric_value_text,'MISSING'),COALESCE(md5((s.metric_value_text::jsonb)::text),'MISSING'),
 h.metric_value_text=md5((s.metric_value_text::jsonb)::text),'Code-owned M1.4 assumptions are frozen and hash-reconciled.' FROM s FULL JOIN h ON true;

/* 10 — row count */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT 'M1_4_POS_10_ROW_COUNT','Baseline POS row count',COUNT(*)::text,'135000',COUNT(*)=135000,
 'The baseline contains 750 merchants across 180 calendar days.'
FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r);

/* 11 — merchant coverage */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT 'M1_4_POS_11_MERCHANT_COVERAGE','Merchant coverage',COUNT(DISTINCT merchant_id)::text,'750',COUNT(DISTINCT merchant_id)=750,
 'Every accepted merchant has daily POS history.' FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r);

/* 12 — date coverage */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT 'M1_4_POS_12_DATE_COVERAGE','Calendar-date coverage',COUNT(DISTINCT observation_date)::text,'180',COUNT(DISTINCT observation_date)=180,
 'The complete governed history window is represented.' FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r);

/* 13 — per-merchant density */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), q AS (
 SELECT merchant_id,COUNT(*) cnt FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r) GROUP BY merchant_id), x AS (
 SELECT COUNT(*) merchants,COUNT(*) FILTER(WHERE cnt<>180) violations,MIN(cnt) min_rows,MAX(cnt) max_rows FROM q)
SELECT 'M1_4_POS_13_PER_MERCHANT_DENSITY','Rows per merchant',format('merchants=%s min=%s max=%s violations=%s',merchants,min_rows,max_rows,violations),
 'merchants=750 min=180 max=180 violations=0',merchants=750 AND min_rows=180 AND max_rows=180 AND violations=0,
 'Every merchant receives exactly one row per governed calendar day.' FROM x;

/* 14 — date bounds */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id,population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), p AS (
 SELECT history_start_date,history_end_date FROM msbf_m1.population_registry WHERE population_id=(SELECT population_id FROM r)), x AS (
 SELECT MIN(observation_date) mn,MAX(observation_date) mx FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_14_DATE_BOUNDS','History date bounds',x.mn::text||'|'||x.mx::text,p.history_start_date::text||'|'||p.history_end_date::text,
 x.mn=p.history_start_date AND x.mx=p.history_end_date,'No row falls outside the frozen observation window.' FROM p CROSS JOIN x;

/* 15 — unique grain */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) rows,COUNT(DISTINCT population_id||'|'||merchant_id||'|'||processor_account_id||'|'||observation_date::text) keys
 FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_15_UNIQUE_GRAIN','Unique merchant-processor-date grain',format('rows=%s keys=%s',rows,keys),'rows=135000 keys=135000',rows=135000 AND keys=135000,
 'The physical fact grain is unique and complete.' FROM x;

/* 16 — population identity */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id,population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) total,COUNT(*) FILTER(WHERE population_id=(SELECT population_id FROM r)) valid FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_16_POPULATION_IDENTITY','Population identity',format('valid=%s total=%s',valid,total),'valid=135000 total=135000',valid=total AND total=135000,
 'Every POS row is anchored to the accepted population.' FROM x;

/* 17 — processor alignment */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) total,COUNT(*) FILTER(WHERE p.merchant_id=pa.merchant_id) valid
 FROM msbf_m1.merchant_pos_daily_base p JOIN msbf_m1.processor_account pa ON pa.processor_account_id=p.processor_account_id
 WHERE p.generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_17_PROCESSOR_ALIGNMENT','Merchant-processor alignment',format('valid=%s total=%s',valid,total),'valid=135000 total=135000',valid=total AND total=135000,
 'Daily rows use the accepted merchant processor account.' FROM x;

/* 18 — source contract identity */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), s AS (
 SELECT source_contract_id FROM msbf_ctl.run_source_snapshot WHERE run_id=(SELECT run_id FROM r) AND source_code='POS_DAILY'), x AS (
 SELECT COUNT(*) total,COUNT(*) FILTER(WHERE source_contract_id=(SELECT source_contract_id FROM s)) valid FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_18_SOURCE_CONTRACT','POS source-contract identity',format('valid=%s total=%s',valid,total),'valid=135000 total=135000',valid=total AND total=135000,
 'Every row references the frozen POS_DAILY source contract.' FROM x;

/* 19 — generated-run identity */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) total,COUNT(*) FILTER(WHERE generated_by_run_id=(SELECT run_id FROM r)) valid FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_19_RUN_IDENTITY','Generated-run identity',format('valid=%s total=%s',valid,total),'valid=135000 total=135000',valid=total AND total=135000,
 'All rows are attributable to the accepted run.' FROM x;

/* 20 — no future data */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id,as_of_date FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE observation_date>(SELECT as_of_date FROM r)) future_rows,MAX(observation_date) max_date
 FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_20_NO_FUTURE_DATA','Future-data control',format('future=%s max=%s',future_rows,max_date),'future=0',future_rows=0,
 'No observation date exceeds the application as-of date.' FROM x;

/* 21 — pre-open behavior */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE p.observation_date<pa.processor_account_open_date) pre_open,
        COUNT(*) FILTER(WHERE p.observation_date<pa.processor_account_open_date AND (p.gross_pos_sales<>0 OR p.transaction_count<>0 OR NOT p.zero_sales_day_flag OR p.processor_status<>'NOT_YET_ACTIVE' OR p.data_connection_status<>'NOT_CONNECTED')) violations
 FROM msbf_m1.merchant_pos_daily_base p JOIN msbf_m1.processor_account pa ON pa.processor_account_id=p.processor_account_id
 WHERE p.generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_21_PRE_OPEN_BEHAVIOR','Pre-processor-open behavior',format('rows=%s violations=%s',pre_open,violations),'violations=0',violations=0,
 'Rows before processor activation are retained as zero, explicitly unavailable history.' FROM x;

/* 22 — processor and connection mapping */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) total,COUNT(*) FILTER(WHERE (processor_status,data_connection_status) IN
  (('NOT_YET_ACTIVE','NOT_CONNECTED'),('ACTIVE','CONNECTED'),('DEGRADED','DELAYED'),('OUTAGE','DISCONNECTED'))) valid
 FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_22_STATUS_CONNECTION_MAPPING','Processor/data-connection mapping',format('valid=%s total=%s',valid,total),'valid=135000 total=135000',valid=total AND total=135000,
 'Processor continuity and source availability remain diagnostically distinct and coherent.' FROM x;

/* 23 — nonnegative amounts */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE gross_pos_sales<0 OR transaction_count<0 OR average_ticket_amount<0 OR refund_amount<0 OR chargeback_amount<0 OR reversal_amount<0 OR governed_exclusion_amount<0 OR eligible_pos_sales<0 OR processor_fee_amount<0 OR settlement_amount<0 OR net_merchant_proceeds<0) violations
 FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_23_NONNEGATIVE','Nonnegative amount and count controls',violations::text,'0',violations=0,
 'Baseline operating and settlement values are nonnegative.' FROM x;

/* 24 — zero-sales identity */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE zero_sales_day_flag IS DISTINCT FROM (gross_pos_sales=0)) violations
 FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_24_ZERO_SALES_IDENTITY','Zero-sales flag identity',violations::text,'0',violations=0,
 'The zero-sales indicator exactly matches gross POS sales.' FROM x;

/* 25 — transaction-count identity */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE (gross_pos_sales=0 AND transaction_count<>0) OR (gross_pos_sales>0 AND transaction_count<1)) violations
 FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_25_TRANSACTION_COUNT','Transaction-count identity',violations::text,'0',violations=0,
 'Sales days have positive transaction counts; zero-sales days have none.' FROM x;

/* 26 — average-ticket identity */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE (transaction_count=0 AND average_ticket_amount<>0) OR (transaction_count>0 AND abs(average_ticket_amount-round(gross_pos_sales/transaction_count,2))>(SELECT currency_tolerance FROM _m1_4_validation_context))) violations
 FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_26_AVERAGE_TICKET','Average-ticket identity',violations::text,'0',violations=0,
 'Average ticket reconciles to gross sales and transaction count.' FROM x;

/* 27 — eligible-sales identity */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE abs(eligible_pos_sales-greatest(gross_pos_sales-refund_amount-chargeback_amount-reversal_amount-governed_exclusion_amount,0))>(SELECT currency_tolerance FROM _m1_4_validation_context)) violations
 FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_27_ELIGIBLE_SALES','Eligible-sales reconciliation',violations::text,'0',violations=0,
 'Gross-to-eligible sales reconciliation is exact within the governed currency tolerance.' FROM x;

/* 28 — settlement-fee and proceeds identity */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE processor_fee_amount>settlement_amount OR abs(net_merchant_proceeds-(settlement_amount-processor_fee_amount))>(SELECT currency_tolerance FROM _m1_4_validation_context)) violations
 FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_28_SETTLEMENT_PROCEEDS','Settlement, fee, and net-proceeds identity',violations::text,'0',violations=0,
 'Net merchant proceeds equal settlement less processor fees.' FROM x;

/* 29 — settlement-delay identity */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) violations FROM msbf_m1.merchant_pos_daily_base a
 JOIN _m1_4_blueprint b USING(population_id,merchant_id,processor_account_id,observation_date)
 WHERE a.generated_by_run_id=(SELECT run_id FROM r) AND abs(a.settlement_amount-b.settlement_amount)>(SELECT currency_tolerance FROM _m1_4_validation_context))
SELECT 'M1_4_POS_29_SETTLEMENT_DELAY','Settlement-delay reproduction',violations::text,'0',violations=0,
 'Persisted settlement amounts reproduce eligible sales at the governed processor delay.' FROM x;

/* 30 — stored row hash */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE row_hash<>msbf_m1.m1_4_pos_row_hash(population_id,merchant_id,processor_account_id,observation_date,
  gross_pos_sales,transaction_count,average_ticket_amount,refund_amount,chargeback_amount,reversal_amount,governed_exclusion_amount,
  eligible_pos_sales,processor_fee_amount,settlement_amount,net_merchant_proceeds,zero_sales_day_flag,processor_status,
  data_connection_status,source_contract_id,generated_by_run_id)) violations
 FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_30_STORED_ROW_HASH','Stored row-hash reconciliation',violations::text,'0',violations=0,
 'Every persisted row hash is independently reproducible from physical columns.' FROM x;

/* 31 — expected/actual mismatch */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) mismatches FROM msbf_m1.m1_4_expected_pos_snapshot((SELECT run_id FROM r)) e
 FULL JOIN msbf_m1.m1_4_actual_pos_snapshot((SELECT run_id FROM r)) a USING(entity_key)
 WHERE e.row_hash IS DISTINCT FROM a.row_hash)
SELECT 'M1_4_POS_31_ROW_REPRODUCTION','Row-level deterministic reproduction',mismatches::text,'0',mismatches=0,
 'Persisted POS history exactly matches the regenerated deterministic blueprint.' FROM x;

/* 32 — set hash */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO') stored,
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_4_expected_pos_snapshot((SELECT run_id FROM r))) expected,
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_4_actual_pos_snapshot((SELECT run_id FROM r))) actual)
SELECT 'M1_4_POS_32_SET_HASH','Population-level POS-history hash',stored||'|'||expected||'|'||actual,'stored=expected=actual',
 stored IS NOT NULL AND stored=expected AND stored=actual,'The full daily-history set reconciles under three independent paths.' FROM x;

/* 33 — industry coverage */
INSERT INTO _m1_4_checks
SELECT 'M1_4_POS_33_INDUSTRY_COVERAGE','Industry coverage',COUNT(DISTINCT industry_code)::text,'8',COUNT(DISTINCT industry_code)=8,
 'All governed merchant industries are represented in daily history.' FROM _m1_4_blueprint;

/* 34 — archetype coverage */
INSERT INTO _m1_4_checks
SELECT 'M1_4_POS_34_ARCHETYPE_COVERAGE','Cash-flow archetype coverage',COUNT(DISTINCT cashflow_archetype_code)::text,'at least 6',COUNT(DISTINCT cashflow_archetype_code)>=6,
 'Daily history includes multiple stable, growth, seasonal, volatile, declining, disrupted, and thin-history patterns.' FROM _m1_4_blueprint;

/* 35 — core archetype presence */
INSERT INTO _m1_4_checks
WITH x AS (SELECT COUNT(DISTINCT merchant_id) FILTER(WHERE cashflow_archetype_code='STABLE') stable,
                  COUNT(DISTINCT merchant_id) FILTER(WHERE cashflow_archetype_code='GROWING') growing,
                  COUNT(DISTINCT merchant_id) FILTER(WHERE cashflow_archetype_code='DECLINING') declining FROM _m1_4_blueprint)
SELECT 'M1_4_POS_35_CORE_ARCHETYPES','Stable/growing/declining merchant presence',format('stable=%s growing=%s declining=%s',stable,growing,declining),
 'each > 0',stable>0 AND growing>0 AND declining>0,'The operating ecosystem supports differentiated trend behavior.' FROM x;

/* 36 — zero-sales share */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE zero_sales_day_flag)::numeric/COUNT(*) AS share FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_36_ZERO_SALES_SHARE','Zero-sales-day share',COALESCE(round(share,6)::text,'NULL'),'between 0.03 and 0.50',COALESCE(share BETWEEN 0.03 AND 0.50,false),
 'Zero-sales behavior is material but bounded across business models and pre-open histories.' FROM x;

/* 37 — outage share */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE processor_status='OUTAGE')::numeric/COUNT(*) AS share FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_37_OUTAGE_SHARE','Processor-outage share',COALESCE(round(share,6)::text,'NULL'),'greater than 0 and below 0.02',COALESCE(share>0 AND share<0.02,false),
 'Processor outages exist as bounded continuity events rather than dominating the baseline.' FROM x;

/* 38 — degraded share */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE processor_status='DEGRADED')::numeric/COUNT(*) AS share FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_38_DEGRADED_SHARE','Processor-degradation share',COALESCE(round(share,6)::text,'NULL'),'greater than 0 and below 0.04',COALESCE(share>0 AND share<0.04,false),
 'Degraded connection events create observable but bounded operating friction.' FROM x;

/* 39–41 — transaction-quality rates */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT SUM(refund_amount)/NULLIF(SUM(gross_pos_sales),0) rate FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_39_REFUND_RATE','Portfolio refund rate',COALESCE(round(rate,6)::text,'NULL'),'greater than 0 and below 0.12',COALESCE(rate>0 AND rate<0.12,false),
 'Refund activity is present and bounded at portfolio level.' FROM x;
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT SUM(chargeback_amount)/NULLIF(SUM(gross_pos_sales),0) rate FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_40_CHARGEBACK_RATE','Portfolio chargeback rate',COALESCE(round(rate,6)::text,'NULL'),'greater than 0 and below 0.03',COALESCE(rate>0 AND rate<0.03,false),
 'Chargeback activity is present and bounded at portfolio level.' FROM x;
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT SUM(reversal_amount)/NULLIF(SUM(gross_pos_sales),0) rate FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_41_REVERSAL_RATE','Portfolio reversal rate',COALESCE(round(rate,6)::text,'NULL'),'greater than 0 and below 0.02',COALESCE(rate>0 AND rate<0.02,false),
 'Sales reversals are present and bounded at portfolio level.' FROM x;

/* 42 — sales-day transactions */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE gross_pos_sales>0 AND transaction_count<=0) violations FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_42_SALES_DAY_TRANSACTIONS','Sales-day transaction positivity',violations::text,'0',violations=0,
 'Every positive-sales day has a positive transaction count.' FROM x;

/* 43 — zero-day ticket/count */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE zero_sales_day_flag AND (transaction_count<>0 OR average_ticket_amount<>0)) violations FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_4_POS_43_ZERO_DAY_DETAILS','Zero-day transaction and ticket values',violations::text,'0',violations=0,
 'Zero-sales days carry zero transactions and zero average ticket.' FROM x;

/* 44 — minimum active positive-sales days */
INSERT INTO _m1_4_checks
WITH q AS (
 SELECT merchant_id,COUNT(*) FILTER(WHERE active_history_flag AND gross_pos_sales>0) positive_days FROM _m1_4_blueprint GROUP BY merchant_id), x AS (
 SELECT MIN(positive_days) min_days,COUNT(*) FILTER(WHERE positive_days<10) violations FROM q)
SELECT 'M1_4_POS_44_ACTIVE_POSITIVE_DAYS','Minimum positive-sales days after activation',format('min=%s violations=%s',COALESCE(min_days::text,'NULL'),violations),
 'minimum >= 10; violations=0',COALESCE(min_days>=10 AND violations=0,false),'Every merchant has sufficient observed operating activity after processor activation.' FROM x;

/* 45 — growing trend */
INSERT INTO _m1_4_checks
WITH x AS (
 SELECT AVG(gross_pos_sales) FILTER(WHERE calendar_day_index BETWEEN 0 AND 29) first_avg,
        AVG(gross_pos_sales) FILTER(WHERE calendar_day_index BETWEEN 150 AND 179) last_avg
 FROM _m1_4_blueprint WHERE cashflow_archetype_code='GROWING' AND active_history_flag)
SELECT 'M1_4_POS_45_GROWING_TREND','Growing-archetype first/last 30-day sales',format('first=%s last=%s',COALESCE(round(first_avg,2)::text,'NULL'),COALESCE(round(last_avg,2)::text,'NULL')),
 'last > first',COALESCE(last_avg>first_avg,false),'Growing merchants exhibit higher aggregate sales near the as-of date.' FROM x;

/* 46 — declining trend */
INSERT INTO _m1_4_checks
WITH x AS (
 SELECT AVG(gross_pos_sales) FILTER(WHERE calendar_day_index BETWEEN 0 AND 29) first_avg,
        AVG(gross_pos_sales) FILTER(WHERE calendar_day_index BETWEEN 150 AND 179) last_avg
 FROM _m1_4_blueprint WHERE cashflow_archetype_code='DECLINING' AND active_history_flag)
SELECT 'M1_4_POS_46_DECLINING_TREND','Declining-archetype first/last 30-day sales',format('first=%s last=%s',COALESCE(round(first_avg,2)::text,'NULL'),COALESCE(round(last_avg,2)::text,'NULL')),
 'last < first',COALESCE(last_avg<first_avg,false),'Declining merchants exhibit lower aggregate sales near the as-of date.' FROM x;

/* 47 — disruption effect */
INSERT INTO _m1_4_checks
WITH x AS (
 SELECT AVG(gross_pos_sales) FILTER(WHERE operating_event_code='RECENT_DISRUPTION') event_avg,
        AVG(gross_pos_sales) FILTER(WHERE cashflow_archetype_code='RECENT_DISRUPTION' AND operating_event_code='NORMAL') normal_avg
 FROM _m1_4_blueprint)
SELECT 'M1_4_POS_47_DISRUPTION_EFFECT','Recent-disruption event versus normal sales',format('event=%s normal=%s',COALESCE(round(event_avg,2)::text,'NULL'),COALESCE(round(normal_avg,2)::text,'NULL')),
 'event < normal',COALESCE(event_avg<normal_avg,false),'Bounded recent disruptions materially reduce observed sales.' FROM x;

/* 48 — weekend pattern differentiation */
INSERT INTO _m1_4_checks
WITH x AS (
 SELECT
  AVG(gross_pos_sales) FILTER(WHERE industry_code='RESTAURANT_FOOD_SERVICE' AND day_of_week IN (0,6) AND active_history_flag)
   /NULLIF(AVG(gross_pos_sales) FILTER(WHERE industry_code='RESTAURANT_FOOD_SERVICE' AND day_of_week NOT IN (0,6) AND active_history_flag),0) restaurant_ratio,
  AVG(gross_pos_sales) FILTER(WHERE industry_code='PROFESSIONAL_SERVICES' AND day_of_week IN (0,6) AND active_history_flag)
   /NULLIF(AVG(gross_pos_sales) FILTER(WHERE industry_code='PROFESSIONAL_SERVICES' AND day_of_week NOT IN (0,6) AND active_history_flag),0) professional_ratio
 FROM _m1_4_blueprint)
SELECT 'M1_4_POS_48_WEEKEND_PATTERN','Industry weekend pattern differentiation',format('restaurant=%s professional=%s',COALESCE(round(restaurant_ratio,4)::text,'NULL'),COALESCE(round(professional_ratio,4)::text,'NULL')),
 'restaurant > professional',COALESCE(restaurant_ratio>professional_ratio,false),'Industry-specific weekend behavior is visible in the generated history.' FROM x;

/* 49 — calendar effects */
INSERT INTO _m1_4_checks
WITH x AS (SELECT COUNT(*) rows,COUNT(DISTINCT observation_date) dates FROM _m1_4_blueprint WHERE holiday_factor<>1)
SELECT 'M1_4_POS_49_CALENDAR_EFFECTS','Governed calendar-effect coverage',format('rows=%s dates=%s',rows,dates),'rows > 0; dates=3',COALESCE(rows>0 AND dates=3,false),
 'The three governed calendar dates create differentiated industry effects.' FROM x;

/* 50 — processor-fee mapping */
INSERT INTO _m1_4_checks
WITH p AS (SELECT DISTINCT merchant_id,partner_channel_id,processor_fee_rate FROM msbf_m1.m1_4_merchant_operating_profile((SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1))), x AS (
 SELECT COUNT(DISTINCT partner_channel_id) channels,MIN(processor_fee_rate) min_rate,MAX(processor_fee_rate) max_rate,COUNT(*) FILTER(WHERE processor_fee_rate<=0) violations FROM p)
SELECT 'M1_4_POS_50_FEE_MAPPING','Processor-fee mapping coverage',format('channels=%s min=%s max=%s violations=%s',channels,min_rate,max_rate,violations),
 'channels=5; min>0; violations=0',COALESCE(channels=5 AND min_rate>0 AND violations=0,false),'All accepted acquisition channels map to a positive processor-fee assumption.' FROM x;

/* 51 — strict stage boundary */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))
 +(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) downstream_rows)
SELECT 'M1_4_POS_51_STAGE_BOUNDARY','Excluded downstream and scenario rows',downstream_rows::text,'0',downstream_rows=0,
 'M1.4 creates baseline POS and settlement history only.' FROM x;

/* 52 — blocking configuration errors */
INSERT INTO _m1_4_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) errors FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING')
SELECT 'M1_4_POS_52_BLOCKING_ERRORS','Blocking configuration errors',errors::text,'0',errors=0,
 'No unresolved blocking configuration issue exists.' FROM x;

INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
SELECT (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
       evidence_code,'PORTFOLIO',metric_name,observed_value,'TEXT',CASE WHEN pass_flag THEN 'PASS' ELSE 'FAIL' END,
       interpretation||' Expected: '||expected_value
FROM _m1_4_checks
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
 metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
 threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

DO $do$
DECLARE v_run_id bigint; v_count integer; v_pass integer;
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 SELECT COUNT(*),COUNT(*) FILTER(WHERE pass_flag) INTO v_count,v_pass FROM _m1_4_checks;
 IF v_count<>52 THEN RAISE EXCEPTION 'M1.4 validation expected 52 checks; observed %.',v_count; END IF;
 IF v_pass=52 THEN
  UPDATE msbf_ctl.run_registry SET run_status='M1_4_VALIDATED',notes='M1.4 daily POS and settlement history passed all positive validation checks. Negative controls pending.' WHERE run_id=v_run_id;
 ELSE
  UPDATE msbf_ctl.run_registry SET run_status='M1_4_FAILED',notes=format('M1.4 positive validation failed: % of 52 checks passed.',v_pass) WHERE run_id=v_run_id;
 END IF;
END $do$;

COMMIT;

SELECT evidence_code,metric_name,metric_value_text,status,interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code ~ '^M1_4_POS_[0-9]{2}_'
ORDER BY evidence_code;
