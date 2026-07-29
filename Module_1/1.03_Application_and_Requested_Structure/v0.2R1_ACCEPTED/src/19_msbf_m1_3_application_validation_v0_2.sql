/* ============================================================================
MSBF M1.3 Application and Requested Sales-Linked Structure — Validation
Version : v0.2R1
Purpose : Recompute the deterministic application blueprint, validate exact
          categorical mixes, financial identities, sales-linked feasibility,
          population/configuration preservation, and strict stage boundaries.
============================================================================ */

BEGIN;

DO $$
DECLARE
  v_run_id bigint;
  v_status text;
BEGIN
  SELECT run_id,run_status INTO STRICT v_run_id,v_status
  FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
  FOR UPDATE;

  IF v_status='M1_3_ACCEPTED' THEN
    RAISE EXCEPTION 'M1.3 is already accepted; validation evidence is frozen.';
  END IF;
  IF v_status NOT IN ('M1_3_GENERATED','M1_3_VALIDATED','M1_3_FAILED') THEN
    RAISE EXCEPTION 'M1.3 validation requires generated applications; observed run_status=%.',v_status;
  END IF;

  DELETE FROM msbf_ctl.run_evidence
  WHERE run_id=v_run_id AND evidence_code LIKE 'M1_3_POS_%';
END
$$;

CREATE TEMP TABLE _m1_3_checks (
  evidence_code text PRIMARY KEY,
  metric_name text NOT NULL,
  observed_value text NOT NULL,
  expected_value text NOT NULL,
  pass_flag boolean NOT NULL,
  interpretation text NOT NULL
) ON COMMIT DROP;

/* 01 — stage status */
INSERT INTO _m1_3_checks
SELECT 'M1_3_POS_01_RUN_STAGE_STATUS','Run stage status',run_status,
       'M1_3_GENERATED or M1_3_VALIDATED or M1_3_FAILED',
       run_status IN ('M1_3_GENERATED','M1_3_VALIDATED','M1_3_FAILED'),
       'Application rows must exist before validation.'
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

/* 02 — G1 gate */
INSERT INTO _m1_3_checks
SELECT 'M1_3_POS_02_G1_GATE','Latest G1 gate status',COALESCE(result_status,'MISSING'),'PASS',
       result_status='PASS','M1.3 remains dependent on accepted G1 configuration.'
FROM (
 SELECT result_status FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
   AND gate_id='G1_CONTROL_PLANE'
 ORDER BY review_version DESC LIMIT 1
) q;

/* 03 — M1.2 gate */
INSERT INTO _m1_3_checks
SELECT 'M1_3_POS_03_M1_2_GATE','Latest M1.2 gate status',COALESCE(result_status,'MISSING'),'PASS',
       result_status='PASS','M1.3 is authorized only from the accepted deterministic merchant population.'
FROM (
 SELECT result_status FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
   AND gate_id='M1_2_POPULATION'
 ORDER BY review_version DESC LIMIT 1
) q;

/* 04 — accepted G1 hashes */
INSERT INTO _m1_3_checks
SELECT 'M1_3_POS_04_ACCEPTED_G1_HASHES','Accepted G1 hashes',
       parameter_snapshot_hash||'|'||profile_snapshot_hash||'|'||source_snapshot_hash,
       'bd09e598c82db96e47459d77fd11e7c8|462cbd2ed92f68e5bdecf6b17537a973|93c3d1368fb2450ab4a08e2b721f92d3',
       parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
       AND profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
       AND source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3',
       'M1.3 must not alter the accepted G1 snapshots.'
FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

/* 05 — recomputed G1 hashes */
INSERT INTO _m1_3_checks
WITH ctx AS (SELECT * FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), h AS (
 SELECT
  (SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key)) FROM msbf_ctl.run_parameter_snapshot WHERE run_id=ctx.run_id) AS ph,
  (SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code)) FROM msbf_ctl.run_profile_snapshot WHERE run_id=ctx.run_id) AS prh,
  (SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code)) FROM msbf_ctl.run_source_snapshot WHERE run_id=ctx.run_id) AS sh
 FROM ctx
)
SELECT 'M1_3_POS_05_RECOMPUTED_G1_HASHES','Recomputed G1 hash reconciliation',h.ph||'|'||h.prh||'|'||h.sh,
       ctx.parameter_snapshot_hash||'|'||ctx.profile_snapshot_hash||'|'||ctx.source_snapshot_hash,
       h.ph=ctx.parameter_snapshot_hash AND h.prh=ctx.profile_snapshot_hash AND h.sh=ctx.source_snapshot_hash,
       'Frozen parameter, profile, and source content independently reconcile.'
FROM ctx CROSS JOIN h;

/* 06 — population status and hash */
INSERT INTO _m1_3_checks
WITH ctx AS (SELECT run_id,population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT p.population_status,p.population_hash,
        (SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM ctx))) AS recomputed_hash
 FROM msbf_m1.population_registry p WHERE p.population_id=(SELECT population_id FROM ctx)
)
SELECT 'M1_3_POS_06_M1_2_POPULATION','Accepted M1.2 population status and hash',population_status||'|'||population_hash,
       'M1_2_ACCEPTED|9b706c926260a3ef1ae8ac95eed5d0bf',
       population_status='M1_2_ACCEPTED' AND population_hash='9b706c926260a3ef1ae8ac95eed5d0bf' AND population_hash=recomputed_hash,
       'Application generation preserves the accepted merchant universe.' FROM x;

/* 07 — generation specification hash */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), s AS (
 SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_3_GENERATION_SPEC' AND segment_key='PORTFOLIO'
), h AS (
 SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_3_GENERATION_SPEC_HASH' AND segment_key='PORTFOLIO'
)
SELECT 'M1_3_POS_07_GENERATION_SPEC','Generation specification hash',COALESCE(h.metric_value_text,'MISSING'),
       COALESCE(md5((s.metric_value_text::jsonb)::text),'MISSING'),
       h.metric_value_text=md5((s.metric_value_text::jsonb)::text),
       'Code-owned request-generation assumptions are frozen and hash-reconciled.'
FROM s FULL JOIN h ON true;

/* 08 — application count */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT 'M1_3_POS_08_APPLICATION_COUNT','Application row count',COUNT(*)::text,'750',COUNT(*)=750,
       'Exactly one baseline application is generated per accepted merchant.'
FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r);

/* 09 — one application per merchant */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), q AS (
 SELECT merchant_id,COUNT(*) AS cnt
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
 GROUP BY merchant_id
), x AS (
 SELECT COALESCE(SUM(cnt),0)::bigint AS rows,COUNT(*)::bigint AS merchants,
        COUNT(*) FILTER (WHERE cnt<>1) AS merchant_count_violations
 FROM q
)
SELECT 'M1_3_POS_09_ONE_PER_MERCHANT','One application per merchant',format('rows=%s merchants=%s violations=%s',rows,merchants,merchant_count_violations),
       'rows=750 merchants=750 violations=0',rows=750 AND merchants=750 AND merchant_count_violations=0,
       'Application cardinality is exactly one per merchant.' FROM x;

/* 10 — application identity pattern */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) AS rows,COUNT(*) FILTER (WHERE merchant_application_id=merchant_id||'_A01') AS valid_ids,
        COUNT(DISTINCT merchant_application_id) AS distinct_ids
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_10_APPLICATION_IDENTITY','Application identity pattern',format('rows=%s valid=%s distinct=%s',rows,valid_ids,distinct_ids),
       'rows=750 valid=750 distinct=750',rows=750 AND valid_ids=750 AND distinct_ids=750,
       'Application keys are stable, synthetic, and unique.' FROM x;

/* 11 — run and population identity */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id,population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE created_by_run_id=(SELECT run_id FROM r) AND population_id=(SELECT population_id FROM r)) AS valid_rows,COUNT(*) AS total_rows
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_11_RUN_POPULATION_IDENTITY','Run and population identity',valid_rows::text,total_rows::text,
       valid_rows=total_rows AND total_rows=750,'Every application is anchored to the accepted run and population.' FROM x;

/* 12 — processor alignment */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE a.processor_account_id=p.processor_account_id AND a.merchant_id=p.merchant_id) AS aligned_rows,COUNT(*) AS total_rows
 FROM msbf_m1.merchant_application a JOIN msbf_m1.processor_account p ON p.processor_account_id=a.processor_account_id
 WHERE a.created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_12_PROCESSOR_ALIGNMENT','Processor-account alignment',aligned_rows::text,total_rows::text,
       aligned_rows=total_rows AND total_rows=750,'Applications use the accepted merchant processor account.' FROM x;

/* 13 — partner alignment */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE a.partner_channel_id IS NOT DISTINCT FROM p.partner_channel_id) AS aligned_rows,COUNT(*) AS total_rows
 FROM msbf_m1.merchant_application a JOIN msbf_m1.processor_account p ON p.processor_account_id=a.processor_account_id
 WHERE a.created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_13_PARTNER_ALIGNMENT','Partner-channel alignment',aligned_rows::text,total_rows::text,
       aligned_rows=total_rows AND total_rows=750,'Application and processor channel evidence remain consistent.' FROM x;

/* 14 — application-channel mapping */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE a.application_channel=CASE a.partner_channel_id
      WHEN 'CH_PROCESSOR_DIRECT' THEN 'PROCESSOR_EMBEDDED'
      WHEN 'CH_BANK_RELATIONSHIP' THEN 'RELATIONSHIP_MANAGER'
      WHEN 'CH_DIGITAL_DIRECT' THEN 'DIGITAL_DIRECT'
      WHEN 'CH_STRATEGIC_PARTNER' THEN 'STRATEGIC_PARTNER'
      ELSE 'BROKER_REFERRAL' END) AS valid_rows,COUNT(*) AS total_rows
 FROM msbf_m1.merchant_application a WHERE a.created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_14_APPLICATION_CHANNEL','Application-channel mapping',valid_rows::text,total_rows::text,
       valid_rows=total_rows AND total_rows=750,'Application channel is deterministically inherited from the accepted partner channel.' FROM x;

/* 15 — temporal integrity */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id,as_of_date FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE application_date=(SELECT as_of_date FROM r) AND as_of_date=(SELECT as_of_date FROM r)) AS valid_rows,
        COUNT(*) FILTER (WHERE application_date>(SELECT as_of_date FROM r) OR as_of_date>(SELECT as_of_date FROM r)) AS future_rows,
        COUNT(*) AS total_rows
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_15_TEMPORAL_INTEGRITY','Application and as-of dates',format('valid=%s future=%s total=%s',valid_rows,future_rows,total_rows),
       'valid=750 future=0 total=750',valid_rows=750 AND future_rows=0 AND total_rows=750,
       'No future application or observation date enters M1.3.' FROM x;

/* 16 — status validity */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE application_status='SUBMITTED') AS valid_rows,COUNT(*) AS total_rows
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_16_APPLICATION_STATUS','Application status',valid_rows::text,total_rows::text,
       valid_rows=total_rows AND total_rows=750,'M1.3 creates submitted request evidence only; it does not make a decision.' FROM x;

/* 17 — funding bounds */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), b AS (
 SELECT max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='funding_amount_min' AND scope_key='GLOBAL') AS mn,
        max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='funding_amount_max' AND scope_key='GLOBAL') AS mx
 FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM r)
), x AS (
 SELECT MIN(requested_funding_amount) AS obs_min,MAX(requested_funding_amount) AS obs_max,
        COUNT(*) FILTER (WHERE requested_funding_amount<(SELECT mn FROM b) OR requested_funding_amount>(SELECT mx FROM b)) AS violations
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_17_FUNDING_BOUNDS','Requested funding bounds',format('min=%s max=%s violations=%s',obs_min,obs_max,violations),
       format('between %s and %s; violations=0',(SELECT mn FROM b),(SELECT mx FROM b)),violations=0,
       'Requested funding remains within the approved global demonstration bounds.' FROM x;

/* 18 — funding increment */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE mod(requested_funding_amount,100)=0) AS valid_rows,COUNT(*) AS total_rows
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_18_FUNDING_INCREMENT','Funding amount increment',valid_rows::text,total_rows::text,
       valid_rows=total_rows AND total_rows=750,'Requested amounts use the governed $100 demonstration increment.' FROM x;

/* 19 — funding-to-sales maximum */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), lim AS (
 SELECT (resolved_value->>'value_numeric')::numeric AS mx FROM msbf_ctl.run_parameter_snapshot
 WHERE run_id=(SELECT run_id FROM r) AND parameter_name='funding_to_annualized_sales_max' AND scope_key='GLOBAL'
), x AS (
 SELECT MAX(b.funding_to_annualized_sales_rate) AS observed_max,
        COUNT(*) FILTER (WHERE b.funding_to_annualized_sales_rate>(SELECT mx FROM lim)+0.000001) AS violations
 FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM r)) b
)
SELECT 'M1_3_POS_19_FUNDING_TO_SALES','Funding-to-annualized-sales maximum',format('max=%s violations=%s',observed_max,violations),(SELECT mx::text FROM lim),violations=0,
       'The synthetic request remains below the governed sales-relative cap.' FROM x;

/* 20 — remittance bounds */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), b AS (
 SELECT max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='requested_remittance_rate_min' AND scope_key='GLOBAL') AS mn,
        max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='requested_remittance_rate_max' AND scope_key='GLOBAL') AS mx
 FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM r)
), x AS (
 SELECT MIN(requested_remittance_rate) AS obs_min,MAX(requested_remittance_rate) AS obs_max,
        COUNT(*) FILTER (WHERE requested_remittance_rate<(SELECT mn FROM b) OR requested_remittance_rate>(SELECT mx FROM b)) AS violations
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_20_REMITTANCE_BOUNDS','Requested remittance-rate bounds',format('min=%s max=%s violations=%s',obs_min,obs_max,violations),
       format('between %s and %s; violations=0',(SELECT mn FROM b),(SELECT mx FROM b)),violations=0,
       'Requested remittance rates remain within governed demonstration bounds.' FROM x;

/* 21 — payback multiple bounds */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), b AS (
 SELECT max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='payback_multiple_min' AND scope_key='GLOBAL') AS mn,
        max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='payback_multiple_max' AND scope_key='GLOBAL') AS mx
 FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM r)
), x AS (
 SELECT MIN(requested_total_repayment_amount/requested_funding_amount) AS obs_min,
        MAX(requested_total_repayment_amount/requested_funding_amount) AS obs_max,
        COUNT(*) FILTER (WHERE requested_total_repayment_amount/requested_funding_amount<(SELECT mn FROM b)-0.000005 OR requested_total_repayment_amount/requested_funding_amount>(SELECT mx FROM b)+0.000005) AS violations
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_21_PAYBACK_BOUNDS','Derived payback-multiple bounds',format('min=%s max=%s violations=%s',obs_min,obs_max,violations),
       format('between %s and %s; violations=0',(SELECT mn FROM b),(SELECT mx FROM b)),violations=0,
       'Derived payback multiples remain within approved synthetic bounds.' FROM x;

/* 22 — finance-charge identity */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), t AS (
 SELECT (resolved_value->>'value_numeric')::numeric AS tol FROM msbf_ctl.run_parameter_snapshot
 WHERE run_id=(SELECT run_id FROM r) AND parameter_name='qa_reconciliation_tolerance_amount' AND scope_key='GLOBAL'
), x AS (
 SELECT MAX(abs(requested_total_repayment_amount-requested_funding_amount-requested_finance_charge_amount)) AS max_delta,
        COUNT(*) FILTER (WHERE abs(requested_total_repayment_amount-requested_funding_amount-requested_finance_charge_amount)>(SELECT tol FROM t)) AS violations
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_22_FINANCE_CHARGE_IDENTITY','Funding plus finance charge identity',format('max_delta=%s violations=%s',max_delta,violations),(SELECT tol::text FROM t),violations=0,
       'Funding plus finance charge reconciles to total requested repayment.' FROM x;

/* 23 — repayment ordering */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE requested_total_repayment_amount>=requested_funding_amount AND requested_finance_charge_amount>=0) AS valid_rows,COUNT(*) AS total_rows
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_23_REPAYMENT_ORDERING','Repayment amount ordering',valid_rows::text,total_rows::text,valid_rows=total_rows AND total_rows=750,
       'Total requested repayment is never below funding and finance charge is nonnegative.' FROM x;

/* 24 — horizon values */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE requested_expected_payoff_days IN (30,60,90)) AS valid_rows,COUNT(*) AS total_rows
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_24_HORIZON_VALUES','Expected payoff horizon values',valid_rows::text,total_rows::text,valid_rows=total_rows AND total_rows=750,
       'Only approved 30-, 60-, and 90-day expected payoff horizons are present.' FROM x;

/* 25 — exact horizon mix */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), exp AS (
 SELECT category_code::smallint AS horizon,target_count FROM msbf_m1.m1_3_weighted_assignment((SELECT run_id FROM r),'expected_payoff_day_weight','EXPECTED_PAYOFF_DAYS','HORIZON') GROUP BY category_code,target_count
), act AS (
 SELECT requested_expected_payoff_days AS horizon,COUNT(*) AS actual_count FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r) GROUP BY requested_expected_payoff_days
), d AS (
 SELECT COUNT(*) AS mismatches FROM exp FULL JOIN act USING(horizon) WHERE COALESCE(target_count,0)<>COALESCE(actual_count,0)
)
SELECT 'M1_3_POS_25_HORIZON_MIX','Expected payoff-horizon mix mismatch count',mismatches::text,'0',mismatches=0,
       'Largest-remainder horizon quotas reconcile exactly to frozen weights.' FROM d;

/* 26 — exact use-of-proceeds mix */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), exp AS (
 SELECT category_code AS use_code,target_count FROM msbf_m1.m1_3_weighted_assignment((SELECT run_id FROM r),'use_of_proceeds_mix_weight','USE_OF_PROCEEDS','USE_OF_PROCEEDS') GROUP BY category_code,target_count
), act AS (
 SELECT requested_use_of_proceeds AS use_code,COUNT(*) AS actual_count FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r) GROUP BY requested_use_of_proceeds
), d AS (
 SELECT COUNT(*) AS mismatches FROM exp FULL JOIN act USING(use_code) WHERE COALESCE(target_count,0)<>COALESCE(actual_count,0)
)
SELECT 'M1_3_POS_26_USE_MIX','Use-of-proceeds mix mismatch count',mismatches::text,'0',mismatches=0,
       'Requested use-of-proceeds quotas reconcile exactly to frozen weights.' FROM d;

/* 27 — use category validity */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE requested_use_of_proceeds IN ('WORKING_CAPITAL','INVENTORY','EQUIPMENT_REPAIR','SEASONAL_NEED','EXPANSION','EMERGENCY_EXPENSE')) AS valid_rows,COUNT(*) AS total_rows
 FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_27_USE_VALUES','Use-of-proceeds values',valid_rows::text,total_rows::text,valid_rows=total_rows AND total_rows=750,
       'All requested uses remain within the governed demonstration catalog.' FROM x;

/* 28 — expected daily remittance identity */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT MAX(abs(expected_daily_remittance*requested_expected_payoff_days-requested_total_repayment_amount)) AS max_rounding_delta,
        COUNT(*) FILTER (WHERE expected_daily_remittance<=0) AS nonpositive_rows
 FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM r))
)
SELECT 'M1_3_POS_28_DAILY_REMITTANCE_IDENTITY','Expected daily-remittance identity',format('max_rounding_delta=%s nonpositive=%s',max_rounding_delta,nonpositive_rows),
       'positive daily remittance; rounding delta <= 0.50',nonpositive_rows=0 AND max_rounding_delta<=0.50,
       'Total requested repayment divided by horizon produces a positive daily remittance proxy; only cent rounding creates a bounded aggregate delta.' FROM x;

/* 29 — implied payoff-path diversity */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT MIN(implied_payoff_days) AS min_days,MAX(implied_payoff_days) AS max_days,
        COUNT(*) FILTER (WHERE implied_payoff_days<=0) AS nonpositive_rows,
        COUNT(*) FILTER (WHERE implied_payoff_days<=requested_expected_payoff_days+0.01) AS on_or_below_path_rows,
        COUNT(*) FILTER (WHERE implied_payoff_days>requested_expected_payoff_days+0.01) AS above_path_rows
 FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM r))
)
SELECT 'M1_3_POS_29_PAYOFF_PATH_DIVERSITY','Sales-linked implied payoff-path diversity',
       format('min=%s max=%s nonpositive=%s on_or_below=%s above=%s',min_days,max_days,nonpositive_rows,on_or_below_path_rows,above_path_rows),
       'nonpositive=0; on_or_below>0; above>0',nonpositive_rows=0 AND on_or_below_path_rows>0 AND above_path_rows>0,
       'M1.3 preserves both requests supportable on the reference sales path and requests requiring downstream capacity review or restructuring.' FROM x;

/* 30 — remittance-path ratio diversity */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT MIN(repayment_path_ratio) AS min_ratio,MAX(repayment_path_ratio) AS max_ratio,
        COUNT(*) FILTER (WHERE repayment_path_ratio<=0) AS nonpositive_rows,
        COUNT(*) FILTER (WHERE repayment_path_ratio<=1.0001) AS on_or_below_path_rows,
        COUNT(*) FILTER (WHERE repayment_path_ratio>1.0001) AS above_path_rows,
        COUNT(*) FILTER (WHERE minimum_amount_floor_override_flag) AS minimum_floor_rows
 FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM r))
)
SELECT 'M1_3_POS_30_REMITTANCE_PATH_DIVERSITY','Requested repayment-path ratio diversity',
       format('min=%s max=%s nonpositive=%s on_or_below=%s above=%s minimum_floor=%s',min_ratio,max_ratio,nonpositive_rows,on_or_below_path_rows,above_path_rows,minimum_floor_rows),
       'nonpositive=0; min<1; max>1; both path populations present',
       nonpositive_rows=0 AND min_ratio<1 AND max_ratio>1 AND on_or_below_path_rows>0 AND above_path_rows>0,
       'The request population includes conservative and aggressive sales-linked structures; downstream underwriting, not M1.3, resolves affordability.' FROM x;

/* 31 — stored request hash */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE a.request_hash=s.row_hash) AS valid_rows,COUNT(*) AS total_rows
 FROM msbf_m1.merchant_application a
 JOIN msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM r)) s ON s.entity_key=a.merchant_application_id
 WHERE a.created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_3_POS_31_REQUEST_HASH','Stored request-hash integrity',valid_rows::text,total_rows::text,valid_rows=total_rows AND total_rows=750,
       'Stored request hashes equal independent recomputation from physical columns.' FROM x;

/* 32 — canonical counts */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT (SELECT COUNT(*) FROM msbf_m1.m1_3_expected_application_snapshot((SELECT run_id FROM r))) AS expected_rows,
        (SELECT COUNT(*) FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM r))) AS actual_rows
)
SELECT 'M1_3_POS_32_CANONICAL_COUNTS','Canonical application row counts',format('expected=%s actual=%s',expected_rows,actual_rows),'expected=750 actual=750',
       expected_rows=750 AND actual_rows=750,'Expected and actual canonical application universes are complete.' FROM x;

/* 33 — row-level deterministic comparison */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), d AS (
 SELECT COUNT(*) AS mismatches
 FROM msbf_m1.m1_3_expected_application_snapshot((SELECT run_id FROM r)) e
 FULL JOIN msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM r)) a USING(entity_key)
 WHERE e.row_hash IS DISTINCT FROM a.row_hash
)
SELECT 'M1_3_POS_33_ROW_LEVEL_RERUN','Row-level deterministic rerun mismatches',mismatches::text,'0',mismatches=0,
       'A complete regenerated application blueprint exactly matches persisted rows.' FROM d;

/* 34 — application-set hash */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_expected_application_snapshot((SELECT run_id FROM r))) AS expected_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM r))) AS actual_hash,
  (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') AS stored_hash
)
SELECT 'M1_3_POS_34_APPLICATION_SET_HASH','Application-set hash reconciliation',stored_hash,expected_hash,
       stored_hash=expected_hash AND actual_hash=expected_hash,'Stored, regenerated, and actual application-set hashes are identical.' FROM x;

/* 35 — merchant-size differentiation */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), a AS (
 SELECT m.merchant_size_tier,AVG(x.requested_funding_amount) AS avg_amount
 FROM msbf_m1.merchant_master m JOIN msbf_m1.merchant_application x ON x.merchant_id=m.merchant_id
 WHERE x.created_by_run_id=(SELECT run_id FROM r)
 GROUP BY m.merchant_size_tier
), p AS (
 SELECT max(avg_amount) FILTER (WHERE merchant_size_tier='MICRO') AS micro,
        max(avg_amount) FILTER (WHERE merchant_size_tier='SMALL') AS small,
        max(avg_amount) FILTER (WHERE merchant_size_tier='LOWER_MIDDLE') AS lower_middle,
        max(avg_amount) FILTER (WHERE merchant_size_tier='MIDDLE') AS middle
 FROM a
)
SELECT 'M1_3_POS_35_SIZE_DIFFERENTIATION','Average request by merchant size',format('micro=%s small=%s lower_middle=%s middle=%s',round(micro,2),round(small,2),round(lower_middle,2),round(middle,2)),
       'MICRO < SMALL < LOWER_MIDDLE < MIDDLE',micro<small AND small<lower_middle AND lower_middle<middle,
       'Requested funding scales directionally with the accepted merchant-size architecture.' FROM p;

/* 36 — relationship-stage request discipline
   Validation note:
   The direct relationship-stage control is request_path_utilization_factor.
   Unadjusted final funding-to-sales averages are retained as diagnostics because
   minimum product floors and unmatched cohort composition can reverse aggregate
   ratios even when the intended control is operating correctly. */
INSERT INTO _m1_3_checks
WITH r AS (
 SELECT run_id
 FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), a AS (
 SELECT relationship_stage,
        AVG(request_path_utilization_factor) AS avg_utilization_factor,
        AVG(funding_to_annualized_sales_rate) AS avg_funding_to_sales,
        COUNT(*) FILTER (WHERE minimum_amount_floor_override_flag) AS minimum_floor_rows,
        COUNT(*) AS applications
 FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM r))
 GROUP BY relationship_stage
), p AS (
 SELECT
   max(avg_utilization_factor) FILTER (WHERE relationship_stage='RETURNING_GOOD') AS returning_good_utilization,
   max(avg_utilization_factor) FILTER (WHERE relationship_stage='LOW_AND_GROW') AS low_and_grow_utilization,
   max(avg_funding_to_sales) FILTER (WHERE relationship_stage='RETURNING_GOOD') AS returning_good_funding_to_sales,
   max(avg_funding_to_sales) FILTER (WHERE relationship_stage='LOW_AND_GROW') AS low_and_grow_funding_to_sales,
   max(minimum_floor_rows) FILTER (WHERE relationship_stage='RETURNING_GOOD') AS returning_good_floor_rows,
   max(minimum_floor_rows) FILTER (WHERE relationship_stage='LOW_AND_GROW') AS low_and_grow_floor_rows,
   max(applications) FILTER (WHERE relationship_stage='RETURNING_GOOD') AS returning_good_applications,
   max(applications) FILTER (WHERE relationship_stage='LOW_AND_GROW') AS low_and_grow_applications
 FROM a
)
SELECT
 'M1_3_POS_36_RELATIONSHIP_DIFFERENTIATION',
 'Relationship-stage request-discipline factor',
 format(
   'utilization:returning_good=%s low_and_grow=%s; raw_funding_to_sales:returning_good=%s low_and_grow=%s; minimum_floor:returning_good=%s/%s low_and_grow=%s/%s',
   round(returning_good_utilization,6),round(low_and_grow_utilization,6),
   round(returning_good_funding_to_sales,6),round(low_and_grow_funding_to_sales,6),
   returning_good_floor_rows,returning_good_applications,
   low_and_grow_floor_rows,low_and_grow_applications
 ),
 'RETURNING_GOOD average request_path_utilization_factor > LOW_AND_GROW; raw funding-to-sales retained as diagnostic',
 returning_good_utilization>low_and_grow_utilization,
 'M1.3 validates the direct relationship-stage request control. Final funding-to-sales averages are non-blocking diagnostics because minimum product floors and unmatched cohort composition can invert unadjusted aggregate ratios. Lender offer and exposure discipline is tested downstream.'
FROM p;

/* 37 — horizon differentiation */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), a AS (
 SELECT requested_expected_payoff_days,AVG(funding_to_annualized_sales_rate) AS avg_rate
 FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM r)) GROUP BY requested_expected_payoff_days
), p AS (
 SELECT max(avg_rate) FILTER (WHERE requested_expected_payoff_days=30) AS d30,
        max(avg_rate) FILTER (WHERE requested_expected_payoff_days=60) AS d60,
        max(avg_rate) FILTER (WHERE requested_expected_payoff_days=90) AS d90
 FROM a
)
SELECT 'M1_3_POS_37_HORIZON_DIFFERENTIATION','Average funding-to-sales by expected horizon',format('d30=%s d60=%s d90=%s',round(d30,6),round(d60,6),round(d90,6)),
       '30-day < 60-day < 90-day',d30<d60 AND d60<d90,
       'Longer requested horizons support larger sales-relative requests, all else equal.' FROM p;

/* 38 — mixed-signal request diversity */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE
       (owner_credit_score>=700 AND (relationship_stage='RETURNING_MIXED' OR prior_payment_interruption_flag OR prior_default_flag) AND funding_to_annualized_sales_rate<0.04)
    OR (owner_credit_score<640 AND requested_funding_amount<=25000 AND implied_payoff_days<=requested_expected_payoff_days)
    OR (months_in_business<24 AND owner_credit_score>=720 AND requested_expected_payoff_days IN (60,90))
 ) AS mixed_rows,COUNT(*) AS total_rows
 FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM r))
)
SELECT 'M1_3_POS_38_MIXED_SIGNAL_REQUESTS','Mixed-signal request share',round(mixed_rows::numeric/NULLIF(total_rows,0),6)::text,'>=0.010000',
       mixed_rows::numeric/NULLIF(total_rows,0)>=0.01,
       'Request structures preserve realistic overlap between owner quality, relationship history, age, amount, and horizon.' FROM x;

/* 39 — binding-constraint diversity */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(DISTINCT binding_constraint_code) AS constraint_types,
        string_agg(DISTINCT binding_constraint_code,',' ORDER BY binding_constraint_code) AS codes
 FROM msbf_m1.m1_3_application_blueprint((SELECT run_id FROM r))
)
SELECT 'M1_3_POS_39_BINDING_DIVERSITY','Request binding-constraint diversity',format('types=%s codes=%s',constraint_types,codes),'>=2 types',constraint_types>=2,
       'The portfolio is not mechanically governed by one request-sizing constraint.' FROM x;

/* 40 — no source or application-evidence adjuncts */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT
      (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM r)) AS rows
)
SELECT 'M1_3_POS_40_NO_APPLICATION_EVIDENCE','Source, obligation, collateral, guarantee, credit, and verification rows',rows::text,'0',rows=0,
       'M1.3 creates request structure only; evidence collection begins later.' FROM x;

/* 41 — no transaction or downstream analytical rows */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT
      (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS rows
)
SELECT 'M1_3_POS_41_NO_DOWNSTREAM_ANALYTICS','POS, deposit, feature, risk, EAD, latest, and archive rows',rows::text,'0',rows=0,
       'M1.3 does not cross into transaction history or analytical-risk stages.' FROM x;

/* 42 — no blocking resolution errors */
INSERT INTO _m1_3_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) AS errors FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING'
)
SELECT 'M1_3_POS_42_NO_BLOCKING_ERRORS','Blocking configuration errors',errors::text,'0',errors=0,
       'No unresolved blocking configuration issue exists at M1.3 validation.' FROM x;

DO $$
DECLARE
  v_run_id bigint;
  v_count integer;
  v_passes integer;
BEGIN
  SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
  SELECT COUNT(*),COUNT(*) FILTER (WHERE pass_flag) INTO v_count,v_passes FROM _m1_3_checks;

  IF v_count<>42 THEN
    RAISE EXCEPTION 'M1.3 validation expected 42 checks; observed %.',v_count;
  END IF;

  INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
  SELECT v_run_id,evidence_code,'PORTFOLIO',metric_name,observed_value,'TEXT',
         CASE WHEN pass_flag THEN 'PASS' ELSE 'FAIL' END,
         interpretation||' Expected: '||expected_value
  FROM _m1_3_checks
  ON CONFLICT (run_id,evidence_code,segment_key) DO UPDATE
    SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
        metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,
        status=EXCLUDED.status,threshold_value_numeric=NULL,
        interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

  UPDATE msbf_ctl.run_registry
     SET run_status=CASE WHEN v_passes=v_count THEN 'M1_3_VALIDATED' ELSE 'M1_3_FAILED' END,
         notes=CASE WHEN v_passes=v_count
                    THEN 'M1.3 requested sales-linked application structures validated; pending negative controls and acceptance.'
                    ELSE 'M1.3 positive validation failed; subsequent stages prohibited.' END
   WHERE run_id=v_run_id;
END
$$;

COMMIT;

SELECT evidence_code,metric_name,status,metric_value_text,interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code LIKE 'M1_3_POS_%'
ORDER BY evidence_code;
