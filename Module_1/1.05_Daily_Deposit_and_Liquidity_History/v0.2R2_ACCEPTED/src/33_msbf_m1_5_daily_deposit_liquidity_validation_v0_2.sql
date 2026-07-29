/* ============================================================================
MSBF M1.5 Daily Deposit & Liquidity History — Positive Validation
Version : v0.2
Purpose : Recompute the liquidity blueprint and validate exact grain, temporal
          integrity, balance roll-forward, deposit components, financing
          pressure, bounded liquidity behavior, deterministic reproduction,
          and strict stage boundaries.
============================================================================ */
BEGIN;

DO $do$
DECLARE v_run_id bigint; v_status text;
BEGIN
 SELECT run_id,run_status INTO STRICT v_run_id,v_status
 FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
 IF v_status='M1_5_ACCEPTED' THEN RAISE EXCEPTION 'M1.5 is already accepted; validation evidence is frozen.'; END IF;
 IF v_status NOT IN ('M1_5_GENERATED','M1_5_VALIDATED','M1_5_FAILED') THEN
  RAISE EXCEPTION 'M1.5 validation requires generated deposit history; observed run_status=%.',v_status;
 END IF;
 DELETE FROM msbf_ctl.run_evidence
 WHERE run_id=v_run_id AND evidence_code ~ '^M1_5_POS_[0-9]{2}_';
END $do$;

CREATE TEMP TABLE _m1_5_blueprint ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_5_daily_liquidity_blueprint(
 (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE INDEX ON _m1_5_blueprint(merchant_id,observation_date);
CREATE INDEX ON _m1_5_blueprint(industry_code,liquidity_risk_tier);

CREATE TEMP TABLE _m1_5_profile ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_5_merchant_liquidity_profile(
 (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE INDEX ON _m1_5_profile(merchant_id);

CREATE TEMP TABLE _m1_5_validation_context ON COMMIT DROP AS
SELECT r.run_id,
       (rps.resolved_value->>'value_numeric')::numeric AS currency_tolerance
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.run_parameter_snapshot rps
  ON rps.run_id=r.run_id
 AND rps.parameter_name='qa_reconciliation_tolerance_amount'
 AND rps.scope_key='GLOBAL'
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

CREATE TEMP TABLE _m1_5_checks(
 evidence_code text PRIMARY KEY,metric_name text NOT NULL,observed_value text NOT NULL,
 expected_value text NOT NULL,pass_flag boolean NOT NULL,interpretation text NOT NULL
) ON COMMIT DROP;

/* 01 — generated-stage status */
INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_01_RUN_STAGE_STATUS','Run stage status',run_status,
 'M1_5_GENERATED or M1_5_VALIDATED or M1_5_FAILED',
 run_status IN ('M1_5_GENERATED','M1_5_VALIDATED','M1_5_FAILED'),
 'Deposit and liquidity rows must exist before validation.'
FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

/* 02–05 — prerequisite gates */
INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_02_G1_GATE','Latest G1 gate status',COALESCE(result_status,'MISSING'),'PASS',COALESCE(result_status='PASS',false),
 'M1.5 remains dependent on accepted governed configuration.'
FROM (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m1_5_validation_context) AND gate_id='G1_CONTROL_PLANE' ORDER BY review_version DESC LIMIT 1) q;
INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_03_M1_2_GATE','Latest M1.2 gate status',COALESCE(result_status,'MISSING'),'PASS',COALESCE(result_status='PASS',false),
 'M1.5 uses the accepted deterministic merchant universe.'
FROM (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m1_5_validation_context) AND gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1) q;
INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_04_M1_3_GATE','Latest M1.3 gate status',COALESCE(result_status,'MISSING'),'PASS',COALESCE(result_status='PASS',false),
 'M1.5 preserves accepted application and requested-structure evidence.'
FROM (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m1_5_validation_context) AND gate_id='M1_3_APPLICATION_REQUEST' ORDER BY review_version DESC LIMIT 1) q;
INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_05_M1_4_GATE','Latest M1.4 gate status',COALESCE(result_status,'MISSING'),'PASS',COALESCE(result_status='PASS',false),
 'M1.5 is generated only from accepted baseline POS and settlement history.'
FROM (SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m1_5_validation_context) AND gate_id='M1_4_DAILY_POS_HISTORY' ORDER BY review_version DESC LIMIT 1) q;

/* 06 — accepted G1 hashes */
INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_06_ACCEPTED_G1_HASHES','Accepted G1 hashes',
 parameter_snapshot_hash||'|'||profile_snapshot_hash||'|'||source_snapshot_hash,
 'bd09e598c82db96e47459d77fd11e7c8|462cbd2ed92f68e5bdecf6b17537a973|93c3d1368fb2450ab4a08e2b721f92d3',
 parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
 AND profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
 AND source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3',
 'M1.5 must not change accepted parameter, profile, or source snapshots.'
FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

/* 07 — recomputed G1 hashes */
INSERT INTO _m1_5_checks
WITH ctx AS (SELECT * FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), h AS (
 SELECT
  (SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key)) FROM msbf_ctl.run_parameter_snapshot WHERE run_id=ctx.run_id) ph,
  (SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code)) FROM msbf_ctl.run_profile_snapshot WHERE run_id=ctx.run_id) prh,
  (SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code)) FROM msbf_ctl.run_source_snapshot WHERE run_id=ctx.run_id) sh
 FROM ctx)
SELECT 'M1_5_POS_07_RECOMPUTED_G1_HASHES','Recomputed G1 hash reconciliation',h.ph||'|'||h.prh||'|'||h.sh,
 ctx.parameter_snapshot_hash||'|'||ctx.profile_snapshot_hash||'|'||ctx.source_snapshot_hash,
 h.ph=ctx.parameter_snapshot_hash AND h.prh=ctx.profile_snapshot_hash AND h.sh=ctx.source_snapshot_hash,
 'Frozen G1 content independently reconciles.' FROM ctx CROSS JOIN h;

/* 08 — population hash */
INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id,population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT p.population_hash,(SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM r))) recomputed
 FROM msbf_m1.population_registry p WHERE p.population_id=(SELECT population_id FROM r))
SELECT 'M1_5_POS_08_POPULATION_HASH','Accepted M1.2 population hash',population_hash,'9b706c926260a3ef1ae8ac95eed5d0bf',
 population_hash='9b706c926260a3ef1ae8ac95eed5d0bf' AND population_hash=recomputed,
 'Deposit history remains anchored to the accepted merchant population.' FROM x;

/* 09 — application hash */
INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') stored,
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM r))) recomputed)
SELECT 'M1_5_POS_09_APPLICATION_HASH','Accepted M1.3 application hash',stored,'01485256b9b5748fb412743d35ced602',
 stored='01485256b9b5748fb412743d35ced602' AND stored=recomputed,
 'M1.5 does not modify accepted application/request evidence.' FROM x;

/* 10 — POS hash */
INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO') stored,
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_4_actual_pos_snapshot((SELECT run_id FROM r))) recomputed)
SELECT 'M1_5_POS_10_POS_HASH','Accepted M1.4 POS-history hash',stored,'d1971e8d319483c187ec0c0483a31e33',
 stored='d1971e8d319483c187ec0c0483a31e33' AND stored=recomputed,
 'Deposit history is anchored to the accepted POS and settlement history.' FROM x;

/* 11 — generation specification hash */
INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), s AS (
 SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_5_GENERATION_SPEC' AND segment_key='PORTFOLIO'), h AS (
 SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_5_GENERATION_SPEC_HASH' AND segment_key='PORTFOLIO')
SELECT 'M1_5_POS_11_GENERATION_SPEC','Generation specification hash',COALESCE(h.metric_value_text,'MISSING'),COALESCE(md5((s.metric_value_text::jsonb)::text),'MISSING'),
 h.metric_value_text=md5((s.metric_value_text::jsonb)::text),'Code-owned M1.5 assumptions are frozen and hash-reconciled.' FROM s FULL JOIN h ON true;

/* 12–21 — structural and lineage integrity */
INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_12_ROW_COUNT','Baseline deposit row count',COUNT(*)::text,'135000',COUNT(*)=135000,
 'The baseline contains 750 merchants across 180 calendar days.'
FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM _m1_5_validation_context);

INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_13_MERCHANT_COVERAGE','Merchant coverage',COUNT(DISTINCT merchant_id)::text,'750',COUNT(DISTINCT merchant_id)=750,
 'Every accepted merchant has a liquidity history.'
FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM _m1_5_validation_context);

INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_14_DATE_COVERAGE','Calendar-date coverage',COUNT(DISTINCT observation_date)::text,'180',COUNT(DISTINCT observation_date)=180,
 'The accepted 180-day observation window is complete.'
FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM _m1_5_validation_context);

INSERT INTO _m1_5_checks
WITH q AS (
 SELECT merchant_id,COUNT(*) rows FROM msbf_m1.merchant_deposit_daily_base
 WHERE generated_by_run_id=(SELECT run_id FROM _m1_5_validation_context) GROUP BY merchant_id), x AS (
 SELECT COUNT(*) merchants,MIN(rows) min_rows,MAX(rows) max_rows,COUNT(*) FILTER(WHERE rows<>180) violations FROM q)
SELECT 'M1_5_POS_15_PER_MERCHANT_DENSITY','Rows per merchant',format('merchants=%s min=%s max=%s violations=%s',merchants,min_rows,max_rows,violations),
 'merchants=750 min=180 max=180 violations=0',merchants=750 AND min_rows=180 AND max_rows=180 AND violations=0,
 'Every merchant has a complete rectangular daily panel.' FROM x;

INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id,population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), p AS (
 SELECT history_start_date,history_end_date FROM msbf_m1.population_registry WHERE population_id=(SELECT population_id FROM r)), x AS (
 SELECT MIN(observation_date) mn,MAX(observation_date) mx FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_5_POS_16_DATE_BOUNDS','History date bounds',x.mn::text||'|'||x.mx::text,p.history_start_date::text||'|'||p.history_end_date::text,
 x.mn=p.history_start_date AND x.mx=p.history_end_date,'Physical date bounds match the accepted population registry.' FROM x CROSS JOIN p;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(*) rows,COUNT(DISTINCT (population_id,merchant_id,observation_date)) keys
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM _m1_5_validation_context))
SELECT 'M1_5_POS_17_UNIQUE_GRAIN','Unique merchant-date grain',format('rows=%s keys=%s',rows,keys),'rows=135000 keys=135000',rows=135000 AND keys=135000,
 'The physical grain is unique by population, merchant, and observation date.' FROM x;

INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id,population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) total,COUNT(*) FILTER(WHERE population_id=(SELECT population_id FROM r)) valid
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_5_POS_18_POPULATION_IDENTITY','Population identity',format('valid=%s total=%s',valid,total),'valid=135000 total=135000',valid=total AND total=135000,
 'Every deposit row is anchored to the accepted population.' FROM x;

INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id FROM _m1_5_validation_context), s AS (
 SELECT source_contract_id FROM msbf_ctl.run_source_snapshot WHERE run_id=(SELECT run_id FROM r) AND source_code='DEPOSIT_DAILY'), x AS (
 SELECT COUNT(*) total,COUNT(*) FILTER(WHERE source_contract_id=(SELECT source_contract_id FROM s)) valid
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_5_POS_19_SOURCE_CONTRACT','Deposit source-contract identity',format('valid=%s total=%s',valid,total),'valid=135000 total=135000',valid=total AND total=135000,
 'Every row references the frozen DEPOSIT_DAILY source contract.' FROM x;

INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id FROM _m1_5_validation_context), x AS (
 SELECT COUNT(*) total,COUNT(*) FILTER(WHERE generated_by_run_id=(SELECT run_id FROM r)) valid
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_5_POS_20_RUN_IDENTITY','Generated-run identity',format('valid=%s total=%s',valid,total),'valid=135000 total=135000',valid=total AND total=135000,
 'All rows are attributable to the accepted run.' FROM x;

INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id,as_of_date FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER(WHERE observation_date>(SELECT as_of_date FROM r)) future_rows,MAX(observation_date) max_date
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_5_POS_21_NO_FUTURE_DATA','Future-data control',format('future=%s max=%s',future_rows,max_date),'future=0',future_rows=0,
 'No observation date exceeds the application as-of date.' FROM x;

/* 22 — POS/deposit row alignment */
INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id FROM _m1_5_validation_context), x AS (
 SELECT COUNT(*) total,COUNT(p.merchant_id) matched
 FROM msbf_m1.merchant_deposit_daily_base d
 LEFT JOIN msbf_m1.merchant_pos_daily_base p
   ON p.population_id=d.population_id AND p.merchant_id=d.merchant_id AND p.observation_date=d.observation_date
  AND p.generated_by_run_id=d.generated_by_run_id
 WHERE d.generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_5_POS_22_POS_ALIGNMENT','POS-to-deposit merchant-day alignment',format('matched=%s total=%s',matched,total),'matched=135000 total=135000',matched=total AND total=135000,
 'Every deposit row aligns to one accepted M1.4 merchant-day POS row.' FROM x;

/* 23–29 — amount, balance, and pre-open identities */
INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(*) FILTER(WHERE deposit_amount<0 OR withdrawal_amount<0 OR nsf_count<0) violations
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM _m1_5_validation_context))
SELECT 'M1_5_POS_23_NONNEGATIVE','Nonnegative deposits, withdrawals, and NSF counts',violations::text,'0',violations=0,
 'Deposits, posted withdrawals, and NSF counts are nonnegative.' FROM x;

INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id,currency_tolerance FROM _m1_5_validation_context), x AS (
 SELECT COUNT(*) FILTER(WHERE abs(closing_balance-(opening_balance+deposit_amount-withdrawal_amount))>(SELECT currency_tolerance FROM r)) violations
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_5_POS_24_BALANCE_IDENTITY','Daily balance identity',violations::text,'0',violations=0,
 'Closing balance reconciles to opening balance plus deposits less withdrawals.' FROM x;

INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id,currency_tolerance FROM _m1_5_validation_context), q AS (
 SELECT merchant_id,observation_date,opening_balance,
        lag(closing_balance) OVER(PARTITION BY merchant_id ORDER BY observation_date) AS prior_closing
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r)), x AS (
 SELECT COUNT(*) FILTER(WHERE prior_closing IS NOT NULL AND abs(opening_balance-prior_closing)>(SELECT currency_tolerance FROM r)) violations FROM q)
SELECT 'M1_5_POS_25_OPENING_ROLLFORWARD','Opening-balance roll-forward',violations::text,'0',violations=0,
 'Each opening balance equals the prior calendar-day closing balance.' FROM x;

INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id,currency_tolerance FROM _m1_5_validation_context), x AS (
 SELECT COUNT(*) FILTER(WHERE available_balance-closing_balance>(SELECT currency_tolerance FROM r)) violations
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_5_POS_26_AVAILABLE_BALANCE','Available-balance relationship',violations::text,'0',violations=0,
 'Temporary holds may reduce available balance; they never increase it above closing balance.' FROM x;

INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id,currency_tolerance FROM _m1_5_validation_context), x AS (
 SELECT COUNT(*) FILTER(WHERE abs(minimum_balance-least(opening_balance,closing_balance,available_balance))>(SELECT currency_tolerance FROM r)) violations
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
SELECT 'M1_5_POS_27_MINIMUM_BALANCE','Minimum-balance identity',violations::text,'0',violations=0,
 'Minimum balance preserves the lowest opening, closing, or available balance evidence for the day.' FROM x;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(*) FILTER(WHERE negative_balance_flag IS DISTINCT FROM (minimum_balance<0)) violations
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM _m1_5_validation_context))
SELECT 'M1_5_POS_28_NEGATIVE_FLAG','Negative-balance flag identity',violations::text,'0',violations=0,
 'Negative-balance status is determined from explicit balance evidence, not source missingness.' FROM x;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(*) FILTER(WHERE processor_status='NOT_YET_ACTIVE') pre_open,
        COUNT(*) FILTER(WHERE processor_status='NOT_YET_ACTIVE' AND
          (deposit_amount<>0 OR withdrawal_amount<>0 OR opening_balance<>closing_balance OR available_balance<>closing_balance OR minimum_balance<>closing_balance OR nsf_count<>0 OR negative_balance_flag)) violations
 FROM _m1_5_blueprint)
SELECT 'M1_5_POS_29_PRE_OPEN_BEHAVIOR','Pre-processor-open liquidity behavior',format('rows=%s violations=%s',pre_open,violations),'violations=0',violations=0,
 'Pre-open history is retained as a constant latent opening balance without fabricated account activity.' FROM x;

/* 30–50 — liquidity behavior and controlled differentiation */
INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_30_CAPTURE_RATE_BOUNDS','Daily capture-rate bounds',
 format('min=%s max=%s',MIN(daily_capture_rate),MAX(daily_capture_rate)),'0.25 <= rate <= 1.00',
 MIN(daily_capture_rate)>=0.25 AND MAX(daily_capture_rate)<=1.00,
 'Daily capture rates remain bounded around the governed industry center.' FROM _m1_5_blueprint;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT b.industry_code,
        SUM(b.base_pos_deposit_amount)/NULLIF(SUM(b.net_merchant_proceeds),0) AS actual_capture,
        MAX(p.deposit_capture_center) AS center
 FROM _m1_5_blueprint b JOIN _m1_5_profile p USING(merchant_id,industry_code)
 GROUP BY b.industry_code), y AS (
 SELECT COUNT(*) industries,COUNT(*) FILTER(WHERE abs(actual_capture-center)>0.15) violations,
        MIN(actual_capture) min_capture,MAX(actual_capture) max_capture FROM x)
SELECT 'M1_5_POS_31_INDUSTRY_CAPTURE','Industry deposit-capture reconciliation',
 format('industries=%s violations=%s min=%s max=%s',industries,violations,round(min_capture,6),round(max_capture,6)),
 'industries=8 violations=0',industries=8 AND violations=0,
 'Weighted POS deposits remain directionally aligned with governed industry capture centers.' FROM y;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT SUM(withdrawal_amount)/NULLIF(SUM(deposit_amount),0) AS ratio FROM msbf_m1.merchant_deposit_daily_base
 WHERE generated_by_run_id=(SELECT run_id FROM _m1_5_validation_context))
SELECT 'M1_5_POS_32_WITHDRAWAL_DEPOSIT_RATIO','Portfolio withdrawal-to-deposit ratio',round(ratio,8)::text,'0.60 to 1.35',
 ratio BETWEEN 0.60 AND 1.35,'Portfolio operating outflows remain bounded relative to deposits.' FROM x;

INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_33_RISK_TIER_COVERAGE','Provisional liquidity-risk tier coverage',
 format('tiers=%s min=%s max=%s',COUNT(DISTINCT liquidity_risk_tier),MIN(liquidity_risk_tier),MAX(liquidity_risk_tier)),
 'at least 4 distinct tiers within 1–5',COUNT(DISTINCT liquidity_risk_tier)>=4 AND MIN(liquidity_risk_tier)>=1 AND MAX(liquidity_risk_tier)<=5,
 'Liquidity behavior preserves differentiated synthetic risk profiles without claiming calibrated credit tiers.' FROM _m1_5_profile;

INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_34_NSF_PROBABILITY_BOUNDS','Adjusted NSF-probability bounds',
 format('min=%s max=%s',MIN(adjusted_nsf_probability),MAX(adjusted_nsf_probability)),'0 <= probability <= 0.25',
 MIN(adjusted_nsf_probability)>=0 AND MAX(adjusted_nsf_probability)<=0.25,
 'Daily NSF propensity remains bounded after available-balance pressure adjustments.' FROM _m1_5_blueprint;

INSERT INTO _m1_5_checks
WITH tiers AS (SELECT MIN(liquidity_risk_tier) lo,MAX(liquidity_risk_tier) hi FROM _m1_5_blueprint), x AS (
 SELECT AVG(adjusted_nsf_probability) FILTER(WHERE liquidity_risk_tier=(SELECT lo FROM tiers)) lo_prob,
        AVG(adjusted_nsf_probability) FILTER(WHERE liquidity_risk_tier=(SELECT hi FROM tiers)) hi_prob FROM _m1_5_blueprint)
SELECT 'M1_5_POS_35_NSF_TIER_GRADIENT','NSF propensity gradient by provisional liquidity tier',
 format('lowest_tier=%s highest_tier=%s',round(lo_prob,8),round(hi_prob,8)),'highest tier > lowest tier',
 hi_prob>lo_prob,'Governed NSF propensity rises across the available liquidity-risk range.' FROM x;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(*) FILTER(WHERE nsf_count>0) nsf_rows,COUNT(*) FILTER(WHERE nsf_count>0)::numeric/COUNT(*) rate,SUM(nsf_count) events
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM _m1_5_validation_context))
SELECT 'M1_5_POS_36_NSF_EVENT_RARITY','NSF event rarity',format('rows=%s events=%s row_rate=%s',nsf_rows,events,round(rate,8)),'0 < row rate < 0.05',
 rate>0 AND rate<0.05,'NSF events are present but remain rare at portfolio level.' FROM x;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(*) FILTER(WHERE negative_balance_flag) rows,COUNT(*) FILTER(WHERE negative_balance_flag)::numeric/COUNT(*) rate
 FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM _m1_5_validation_context))
SELECT 'M1_5_POS_37_NEGATIVE_BALANCE_SHARE','Negative-balance share',format('rows=%s rate=%s',rows,round(rate,8)),'0 < rate < 0.30',
 rate>0 AND rate<0.30,'Negative-balance evidence is present but bounded.' FROM x;

INSERT INTO _m1_5_checks
WITH tiers AS (SELECT MIN(liquidity_risk_tier) lo,MAX(liquidity_risk_tier) hi FROM _m1_5_profile), x AS (
 SELECT AVG(negative_balance_daily_probability) FILTER(WHERE liquidity_risk_tier=(SELECT lo FROM tiers)) lo_prob,
        AVG(negative_balance_daily_probability) FILTER(WHERE liquidity_risk_tier=(SELECT hi FROM tiers)) hi_prob FROM _m1_5_profile)
SELECT 'M1_5_POS_38_NEGATIVE_PROPENSITY_GRADIENT','Governed negative-balance propensity gradient',
 format('lowest_tier=%s highest_tier=%s',round(lo_prob,8),round(hi_prob,8)),'highest tier > lowest tier',
 hi_prob>lo_prob,'Frozen risk-tier parameters preserve increasing liquidity-stress propensity.' FROM x;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(*) FILTER(WHERE closing_balance<lower_balance_floor-(SELECT currency_tolerance FROM _m1_5_validation_context)) violations,
        MIN(closing_balance-lower_balance_floor) minimum_headroom
 FROM _m1_5_blueprint)
SELECT 'M1_5_POS_39_BOUNDED_CLOSING_FLOOR','Bounded closing-balance floor',format('violations=%s min_headroom=%s',violations,minimum_headroom),'violations=0',violations=0,
 'Non-POS support deposits prevent unbounded synthetic overdraft behavior.' FROM x;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(*) FILTER(WHERE NOT deposit_source_available_flag)::numeric/COUNT(*) AS missing_share,
        COUNT(*) FILTER(WHERE NOT deposit_source_available_flag) AS missing_merchants
 FROM _m1_5_profile)
SELECT 'M1_5_POS_40_SOURCE_MISSINGNESS','Deposit-source missingness assignment',format('merchants=%s share=%s',missing_merchants,round(missing_share,8)),'0.03 to 0.13',
 missing_share BETWEEN 0.03 AND 0.13,'Source observability missingness is deterministic and reserved for M1.7 confidence treatment.' FROM x;

INSERT INTO _m1_5_checks
WITH missing AS (SELECT merchant_id FROM _m1_5_profile WHERE NOT deposit_source_available_flag), q AS (
 SELECT m.merchant_id,COUNT(b.observation_date) rows FROM missing m LEFT JOIN _m1_5_blueprint b USING(merchant_id) GROUP BY m.merchant_id), x AS (
 SELECT COUNT(*) merchants,COUNT(*) FILTER(WHERE rows<>180) violations,MIN(rows) min_rows,MAX(rows) max_rows FROM q)
SELECT 'M1_5_POS_41_SOURCE_MISSING_TRUTH_ROWS','Latent truth rows for source-missing merchants',
 format('merchants=%s violations=%s min=%s max=%s',merchants,violations,min_rows,max_rows),'violations=0 min=180 max=180',
 merchants>0 AND violations=0 AND min_rows=180 AND max_rows=180,
 'Missing observability does not manufacture liquidity distress or suppress latent synthetic truth history.' FROM x;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT deposit_relationship_flag,AVG(relationship_capture_adjustment) avg_adjustment FROM _m1_5_profile GROUP BY deposit_relationship_flag), y AS (
 SELECT MAX(avg_adjustment) FILTER(WHERE deposit_relationship_flag) with_relationship,
        MAX(avg_adjustment) FILTER(WHERE NOT deposit_relationship_flag) without_relationship FROM x)
SELECT 'M1_5_POS_42_RELATIONSHIP_CAPTURE','Direct deposit-relationship capture adjustment',
 format('with=%s without=%s',round(with_relationship,8),round(without_relationship,8)),'with=0.025 and without=-0.010',
 abs(with_relationship-0.025)<0.00000001 AND abs(without_relationship+0.010)<0.00000001,
 'The governed relationship adjustment is validated directly rather than through unmatched cohort averages.' FROM y;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT industry_code,SUM(base_pos_deposit_amount)/NULLIF(SUM(net_merchant_proceeds),0) rate
 FROM _m1_5_blueprint GROUP BY industry_code), y AS (SELECT MIN(rate) mn,MAX(rate) mx FROM x)
SELECT 'M1_5_POS_43_INDUSTRY_DIFFERENTIATION','Industry capture differentiation',format('min=%s max=%s spread=%s',round(mn,8),round(mx,8),round(mx-mn,8)),'spread >= 0.08',
 mx-mn>=0.08,'Industry-specific capture assumptions produce visible liquidity-source differentiation.' FROM y;

INSERT INTO _m1_5_checks
SELECT 'M1_5_POS_44_EVENT_DIVERSITY','Liquidity-event diversity',COUNT(DISTINCT liquidity_event_code)::text,'at least 5 event codes',
 COUNT(DISTINCT liquidity_event_code)>=5,'The ecosystem includes normal, pre-open, low-liquidity, stress, outage, and support behaviors.' FROM _m1_5_blueprint;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(*) FILTER(WHERE non_pos_support_deposit_amount>0) support_rows,SUM(non_pos_support_deposit_amount) support_amount
 FROM _m1_5_blueprint)
SELECT 'M1_5_POS_45_SUPPORT_DEPOSIT_PRESENCE','Bounded non-POS support deposits',format('rows=%s amount=%s',support_rows,support_amount),'rows > 0 and amount > 0',
 support_rows>0 AND support_amount>0,'Bounded support deposits represent synthetic owner/non-POS liquidity intervention rather than unbounded negative balances.' FROM x;

INSERT INTO _m1_5_checks
WITH x AS (SELECT MAX(nsf_count) max_nsf FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM _m1_5_validation_context))
SELECT 'M1_5_POS_46_NSF_COUNT_BOUND','Daily NSF-count bound',max_nsf::text,'0 to 2',max_nsf BETWEEN 0 AND 2,
 'Daily NSF counts remain small and bounded.' FROM x;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(*) FILTER(WHERE abs(deposit_amount-(base_pos_deposit_amount+non_pos_support_deposit_amount))>(SELECT currency_tolerance FROM _m1_5_validation_context)) violations
 FROM _m1_5_blueprint)
SELECT 'M1_5_POS_47_DEPOSIT_COMPONENT_IDENTITY','Deposit-component identity',violations::text,'0',violations=0,
 'Total deposits reconcile to captured POS proceeds plus bounded non-POS support deposits.' FROM x;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(DISTINCT merchant_id) FILTER(WHERE active_financing_flag) active_merchants,
        COUNT(*) FILTER(WHERE existing_financing_remittance_amount>0) remittance_rows,
        COUNT(*) FILTER(WHERE existing_financing_remittance_amount>0 AND
          (NOT active_financing_flag OR observation_date<financing_start_date OR observation_date>financing_end_date OR processor_status='NOT_YET_ACTIVE')) violations,
        COUNT(*) FILTER(WHERE active_financing_flag AND observation_date BETWEEN financing_start_date AND financing_end_date
          AND processor_status<>'NOT_YET_ACTIVE' AND abs(existing_financing_remittance_amount-financing_daily_remittance)>(SELECT currency_tolerance FROM _m1_5_validation_context)) amount_violations
 FROM _m1_5_blueprint)
SELECT 'M1_5_POS_48_FINANCING_REMITTANCE_COHERENCE','Existing-financing remittance coherence',
 format('active_merchants=%s remittance_rows=%s timing_violations=%s amount_violations=%s',active_merchants,remittance_rows,violations,amount_violations),
 'active merchants > 0, remittance rows > 0, violations=0',
 active_merchants>0 AND remittance_rows>0 AND violations=0 AND amount_violations=0,
 'Existing financing pressure is bounded to deterministically assigned active windows and daily remittance amounts.' FROM x;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(*) FILTER(WHERE active_financing_flag) active_merchants,
        MIN(financing_start_date) FILTER(WHERE active_financing_flag) first_start,
        MAX(financing_end_date) FILTER(WHERE active_financing_flag) last_end,
        MIN(financing_daily_remittance) FILTER(WHERE active_financing_flag) min_remittance,
        MAX(financing_daily_remittance) FILTER(WHERE active_financing_flag) max_remittance
 FROM _m1_5_profile)
SELECT 'M1_5_POS_49_FINANCING_COHORT_PRESENCE','Existing-financing cohort presence',
 format('merchants=%s first=%s last=%s min=%s max=%s',active_merchants,first_start,last_end,min_remittance,max_remittance),
 'active merchants > 0; valid dates and positive amounts',
 active_merchants>0 AND first_start IS NOT NULL AND last_end IS NOT NULL AND min_remittance>0 AND max_remittance>=min_remittance,
 'The ecosystem includes a bounded cohort with observable pre-existing financing-remittance pressure.' FROM x;

INSERT INTO _m1_5_checks
WITH x AS (
 SELECT COUNT(*) FILTER(WHERE abs(available_balance-(closing_balance-temporary_hold_amount))>(SELECT currency_tolerance FROM _m1_5_validation_context)) violations,
        MIN(temporary_hold_amount) min_hold
 FROM _m1_5_blueprint)
SELECT 'M1_5_POS_50_TEMPORARY_HOLD_IDENTITY','Temporary-hold and available-balance identity',format('violations=%s min_hold=%s',violations,min_hold),'violations=0 and min_hold>=0',
 violations=0 AND min_hold>=0,'Available balance exactly reflects closing balance less deterministic temporary holds.' FROM x;

INSERT INTO _m1_5_checks
WITH first_rows AS (
 SELECT DISTINCT ON (merchant_id) merchant_id,opening_balance FROM _m1_5_blueprint ORDER BY merchant_id,observation_date), x AS (
 SELECT COUNT(*) FILTER(WHERE abs(f.opening_balance-p.initial_opening_balance)>(SELECT currency_tolerance FROM _m1_5_validation_context)) violations
 FROM first_rows f JOIN _m1_5_profile p USING(merchant_id))
SELECT 'M1_5_POS_51_INITIAL_OPENING_IDENTITY','Initial opening-balance identity',violations::text,'0',violations=0,
 'Each merchant history begins at the deterministic liquidity-profile opening balance.' FROM x;

/* 52–53 — deterministic reproduction */
INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id FROM _m1_5_validation_context), x AS (
 SELECT COUNT(*) mismatches FROM msbf_m1.m1_5_expected_deposit_snapshot((SELECT run_id FROM r)) e
 FULL JOIN msbf_m1.m1_5_actual_deposit_snapshot((SELECT run_id FROM r)) a USING(entity_key)
 WHERE e.row_hash IS DISTINCT FROM a.row_hash)
SELECT 'M1_5_POS_52_ROW_REPRODUCTION','Row-level deterministic reproduction',mismatches::text,'0',mismatches=0,
 'Every persisted merchant-day row matches the independently regenerated canonical blueprint.' FROM x;

INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id FROM _m1_5_validation_context), x AS (
 SELECT
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_5_expected_deposit_snapshot((SELECT run_id FROM r))) expected_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_5_actual_deposit_snapshot((SELECT run_id FROM r))) actual_hash,
  (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_5_DEPOSIT_SET_HASH' AND segment_key='PORTFOLIO') stored_hash)
SELECT 'M1_5_POS_53_SET_HASH','Deposit-history set hash',expected_hash||'|'||actual_hash||'|'||stored_hash,'all three hashes equal and non-null',
 expected_hash IS NOT NULL AND expected_hash=actual_hash AND expected_hash=stored_hash,
 'Expected, actual, and stored full-history hashes reconcile.' FROM x;

/* 54 — parameter completeness */
INSERT INTO _m1_5_checks
WITH required_parameters AS (
   SELECT 'enable_deposit_history_flag'::text AS parameter_name,'GLOBAL'::text AS scope_key
   UNION ALL SELECT 'deposit_capture_rate_sigma','GLOBAL'
   UNION ALL SELECT 'withdrawal_to_deposit_rate_center','GLOBAL'
   UNION ALL SELECT 'liquidity_shock_multiplier','GLOBAL'
   UNION ALL SELECT 'deposit_history_missing_probability','GLOBAL'
   UNION ALL SELECT 'qa_reconciliation_tolerance_amount','GLOBAL'
   UNION ALL SELECT p.parameter_name,'INDUSTRY:'||i.industry_code FROM (VALUES ('deposit_capture_rate_center'),('balance_buffer_days_center')) p(parameter_name) CROSS JOIN msbf_ref.industry i
   UNION ALL SELECT p.parameter_name,'RISK_TIER:'||t.risk_tier::text FROM (VALUES ('nsf_daily_probability'),('negative_balance_daily_probability')) p(parameter_name) CROSS JOIN generate_series(1,5) t(risk_tier)
), x AS (
 SELECT COUNT(*) required,COUNT(rps.parameter_name) resolved
 FROM required_parameters req LEFT JOIN msbf_ctl.run_parameter_snapshot rps
 ON rps.run_id=(SELECT run_id FROM _m1_5_validation_context) AND rps.parameter_name=req.parameter_name AND rps.scope_key=req.scope_key)
SELECT 'M1_5_POS_54_PARAMETER_COMPLETENESS','Required parameter/scope completeness',format('resolved=%s required=%s',resolved,required),'resolved=32 required=32',
 resolved=32 AND required=32,'All governed M1.5 parameter/scope pairs remain resolved in the frozen run snapshot.' FROM x;

/* 55 — strict stage boundary */
INSERT INTO _m1_5_checks
WITH r AS (SELECT run_id FROM _m1_5_validation_context), x AS (
 SELECT
  (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM r))
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
SELECT 'M1_5_POS_55_STAGE_BOUNDARY','Downstream and scenario stage boundary',downstream_rows::text,'0',downstream_rows=0,
 'M1.5 creates only baseline daily deposit/liquidity history.' FROM x;

/* 56 — no blocking errors */
INSERT INTO _m1_5_checks
WITH x AS (SELECT COUNT(*) errors FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_5_validation_context) AND severity='BLOCKING')
SELECT 'M1_5_POS_56_BLOCKING_ERRORS','Blocking resolution errors',errors::text,'0',errors=0,
 'No unresolved blocking profile, parameter, source, or contract issue remains.' FROM x;

INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
SELECT (SELECT run_id FROM _m1_5_validation_context),evidence_code,'PORTFOLIO',metric_name,observed_value,'TEXT',
       CASE WHEN pass_flag THEN 'PASS' ELSE 'FAIL' END,interpretation||' Expected: '||expected_value
FROM _m1_5_checks
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
 metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
 threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

DO $do$
DECLARE v_run_id bigint; v_count integer; v_pass integer;
BEGIN
 SELECT run_id INTO STRICT v_run_id FROM _m1_5_validation_context;
 SELECT COUNT(*),COUNT(*) FILTER(WHERE pass_flag) INTO v_count,v_pass FROM _m1_5_checks;
 IF v_count<>56 THEN RAISE EXCEPTION 'M1.5 validation specification requires 56 checks; observed %.',v_count; END IF;
 UPDATE msbf_ctl.run_registry SET run_status=CASE WHEN v_pass=56 THEN 'M1_5_VALIDATED' ELSE 'M1_5_FAILED' END,
  notes=CASE WHEN v_pass=56 THEN 'M1.5 positive validation passed 56 of 56 checks. Negative controls pending.'
             ELSE format('M1.5 positive validation failed: %s of 56 checks passed.',v_pass) END
 WHERE run_id=v_run_id;
END $do$;

COMMIT;

SELECT evidence_code,metric_name,metric_value_text,status,interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code ~ '^M1_5_POS_[0-9]{2}_'
ORDER BY evidence_code;
