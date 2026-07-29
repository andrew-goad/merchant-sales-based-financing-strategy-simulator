/* ============================================================================
MSBF M1.9 As-of Cash-Flow Feature Engineering — Generation
Version : v0.2R5
Purpose : Transform accepted M1.6 scenario histories into scenario-aware as-of
          cash-flow, transaction-quality, liquidity, confidence and matched
          stress-delta features without rebuilding accepted upstream blueprints.
Performance: Materialize accepted inputs once; aggregate each 270k-row scenario
             table once; use one bounded rolling window; persist/index/analyze;
             perform one generation-time canonical reconciliation.
============================================================================ */
BEGIN;
SET LOCAL work_mem='128MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='20min';

CREATE OR REPLACE FUNCTION msbf_m1.m1_9_hash_jsonb(p_payload jsonb)
RETURNS text LANGUAGE sql IMMUTABLE AS $fn$
SELECT md5(p_payload::text);
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_9_actual_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text)
LANGUAGE sql STABLE AS $fn$
SELECT
    'SNAPSHOT|' || s.scenario_id || '|' || s.merchant_application_id,
    msbf_m1.m1_9_hash_jsonb(to_jsonb(s)-'feature_snapshot_hash'-'created_at')
FROM msbf_m1.application_cashflow_feature_snapshot s
WHERE s.module1_run_id=p_run_id;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_9_actual_feature_value(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text)
LANGUAGE sql STABLE AS $fn$
SELECT
    'FEATURE|' || v.scenario_id || '|' || v.merchant_application_id || '|' ||
       v.feature_code || '|v' || v.feature_version,
    msbf_m1.m1_9_hash_jsonb(to_jsonb(v)-'calculation_hash'-'created_at')
FROM msbf_m1.cashflow_feature_value v
WHERE v.module1_run_id=p_run_id;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_9_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $fn$
DECLARE
    v_status text; v_policy jsonb; v_gate text; v_features integer;
    v_snapshots bigint; v_values bigint; v_scenarios integer;
    v_baseline_scenarios integer; v_stress_scenarios integer; v_errors integer;
BEGIN
    SELECT run_status INTO STRICT v_status
    FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    IF v_status<>'M1_8_ACCEPTED' THEN
        RAISE EXCEPTION 'M1.9 requires run status M1_8_ACCEPTED; observed %.',v_status;
    END IF;

    SELECT result_status INTO v_gate
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=p_run_id AND gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY'
    ORDER BY review_version DESC LIMIT 1;
    IF coalesce(v_gate,'<NULL>')<>'PASS' THEN
        RAISE EXCEPTION 'M1.8 acceptance gate must remain PASS; observed %.',v_gate;
    END IF;

    SELECT profile_payload INTO STRICT v_policy
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING' AND profile_version=1 AND status='APPROVED';
    IF NOT coalesce((v_policy->>'generation_enabled')::boolean,false)
       OR v_policy->>'methodology_version'<>'M1_9_METHOD_V1'
       OR v_policy->>'annualized_sales_basis'<>'PERSISTED_ROUNDED_90D_AVERAGE' THEN
        RAISE EXCEPTION 'M1.9 approved generation policy is missing or disabled.';
    END IF;

    SELECT count(*) INTO v_features
    FROM msbf_m1.feature_definition
    WHERE feature_code IN ('AVG_DAILY_ELIGIBLE_SALES_7D','AVG_DAILY_ELIGIBLE_SALES_30D','AVG_DAILY_ELIGIBLE_SALES_60D','AVG_DAILY_ELIGIBLE_SALES_90D','ANNUALIZED_ELIGIBLE_SALES','SALES_GROWTH_7D_VS_30D','SALES_GROWTH_30D_VS_90D','DAILY_SALES_CV_30D','DAILY_SALES_CV_90D','ZERO_SALES_DAY_RATE_30D','ACTIVE_SALES_DAY_RATE_30D','SEASONALITY_INDEX_180D','LARGEST_30D_SHARE_180D','REFUND_RATE_30D','CHARGEBACK_RATE_30D','REVERSAL_RATE_30D','DEPOSIT_TO_ELIGIBLE_SALES_RATE_30D','POS_DEPOSIT_RECONCILIATION_RATE_30D','NEGATIVE_BALANCE_DAY_RATE_30D','NSF_COUNT_30D','AVERAGE_AVAILABLE_BALANCE_30D','MINIMUM_BALANCE_30D','CASH_FLOW_BUFFER_DAYS','PROCESSOR_OUTAGE_DAY_RATE_30D','PROCESSOR_DEGRADED_DAY_RATE_30D','SOURCE_CONFIDENCE_SCORE','SCENARIO_ELIGIBLE_SALES_DELTA_RATE_30D','SCENARIO_ELIGIBLE_SALES_DELTA_RATE_90D','SCENARIO_DEPOSIT_DELTA_RATE_30D','SCENARIO_WITHDRAWAL_DELTA_RATE_30D','SCENARIO_AVAILABLE_BALANCE_DELTA_RATE_30D','SCENARIO_NEGATIVE_BALANCE_RATE_DELTA_30D','SCENARIO_NSF_COUNT_DELTA_30D','SCENARIO_PROCESSOR_OUTAGE_RATE_DELTA_30D','SCENARIO_REFUND_RATE_DELTA_30D','SCENARIO_CHARGEBACK_RATE_DELTA_30D')
      AND feature_version=1 AND active_flag;
    IF v_features<>36 THEN
        RAISE EXCEPTION 'M1.9 requires 36 active feature definitions; observed %.',v_features;
    END IF;

    /* Resolve scenarios from the accepted M1.6 physical panels, not from the
       global registry. The registry intentionally contains more than one
       approved scenario family, including the original foundation seed and
       the accepted M1.6 matched-scenario set. */
    WITH pos_used AS (
        SELECT scenario_id, count(*) AS row_count
        FROM msbf_m1.merchant_pos_daily_scenario
        WHERE generated_by_run_id=p_run_id
        GROUP BY scenario_id
    ), deposit_used AS (
        SELECT scenario_id, count(*) AS row_count
        FROM msbf_m1.merchant_deposit_daily_scenario
        WHERE generated_by_run_id=p_run_id
        GROUP BY scenario_id
    ), accepted_run_scenarios AS (
        SELECT sr.scenario_id,sr.scenario_code
        FROM pos_used p
        JOIN deposit_used d USING(scenario_id)
        JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=p.scenario_id
        JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
        WHERE p.row_count=135000
          AND d.row_count=135000
          AND ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS'
          AND ss.scenario_set_version=1
          AND ss.status='APPROVED'
          AND sr.status='APPROVED'
          AND sr.scenario_version=1
          AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY')
    )
    SELECT count(*),
           count(*) FILTER(WHERE scenario_code='BASELINE'),
           count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY')
    INTO v_scenarios,v_baseline_scenarios,v_stress_scenarios
    FROM accepted_run_scenarios;
    IF v_scenarios<>2 OR v_baseline_scenarios<>1 OR v_stress_scenarios<>1 THEN
        RAISE EXCEPTION
          'M1.9 requires the two approved scenarios used by accepted M1.6 (BASELINE and RECESSION_ENERGY); observed total %, baseline %, stress %.',
          v_scenarios,v_baseline_scenarios,v_stress_scenarios;
    END IF;

    SELECT count(*) INTO v_snapshots
    FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=p_run_id;
    SELECT count(*) INTO v_values
    FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=p_run_id;
    IF v_snapshots<>0 OR v_values<>0 THEN
        RAISE EXCEPTION 'M1.9 regeneration rejected: snapshots %, feature values %.',v_snapshots,v_values;
    END IF;

    SELECT count(*) INTO v_errors
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=p_run_id AND severity='BLOCKING';
    IF v_errors<>0 THEN
        RAISE EXCEPTION 'M1.9 cannot start with % blocking configuration errors.',v_errors;
    END IF;
END;
$fn$;

DO $n$ BEGIN RAISE NOTICE 'M1.9 Phase 1/6 — materialize accepted application, source, scenario and control inputs'; END $n$;

CREATE TEMP TABLE _m1_9_ctx ON COMMIT DROP AS
SELECT
    r.run_id,r.population_id,r.as_of_date,p.history_start_date,p.history_end_date,
    pp.policy_profile_id,pp.profile_payload,
    (pp.profile_payload->>'annualization_days')::integer AS annualization_days,
    (pp.profile_payload->>'minimum_core_pos_days')::integer AS min_core_pos_days,
    (pp.profile_payload->>'minimum_full_pos_days')::integer AS min_full_pos_days,
    (pp.profile_payload->>'minimum_deposit_days')::integer AS min_deposit_days,
    (pp.profile_payload->>'minimum_seasonality_days')::integer AS min_seasonality_days,
    (pp.profile_payload->>'mean_sales_epsilon')::numeric AS mean_sales_epsilon,
    (pp.profile_payload->>'delta_denominator_floor')::numeric AS delta_floor,
    (pp.profile_payload->>'cv_cap')::numeric AS cv_cap,
    (pp.profile_payload->>'growth_floor')::numeric AS growth_floor,
    (pp.profile_payload->>'growth_cap')::numeric AS growth_cap,
    (pp.profile_payload->>'ratio_cap')::numeric AS ratio_cap,
    (pp.profile_payload->>'seasonality_cap')::numeric AS seasonality_cap,
    (pp.profile_payload->>'buffer_days_cap')::numeric AS buffer_days_cap,
    (pp.profile_payload->>'data_confidence_high_threshold')::numeric AS conf_high,
    (pp.profile_payload->>'data_confidence_medium_threshold')::numeric AS conf_medium,
    (pp.profile_payload->>'data_confidence_low_threshold')::numeric AS conf_low,
    max((rps.resolved_value->>'value_numeric')::numeric)
       FILTER(WHERE rps.parameter_name='missing_pos_source_confidence_penalty' AND rps.scope_key='GLOBAL') AS missing_pos_penalty,
    max((rps.resolved_value->>'value_numeric')::numeric)
       FILTER(WHERE rps.parameter_name='missing_deposit_source_confidence_penalty' AND rps.scope_key='GLOBAL') AS missing_deposit_penalty
FROM msbf_ctl.run_registry r
JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
JOIN msbf_ctl.policy_profile pp
  ON pp.profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING' AND pp.profile_version=1 AND pp.status='APPROVED'
JOIN msbf_ctl.run_parameter_snapshot rps ON rps.run_id=r.run_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
GROUP BY r.run_id,r.population_id,r.as_of_date,p.history_start_date,p.history_end_date,
         pp.policy_profile_id,pp.profile_payload;

SELECT msbf_m1.m1_9_assert_generation_ready(run_id) FROM _m1_9_ctx;

CREATE TEMP TABLE _m1_9_scenarios ON COMMIT DROP AS
WITH pos_used AS (
    SELECT scenario_id,count(*) AS row_count
    FROM msbf_m1.merchant_pos_daily_scenario
    WHERE generated_by_run_id=(SELECT run_id FROM _m1_9_ctx)
    GROUP BY scenario_id
), deposit_used AS (
    SELECT scenario_id,count(*) AS row_count
    FROM msbf_m1.merchant_deposit_daily_scenario
    WHERE generated_by_run_id=(SELECT run_id FROM _m1_9_ctx)
    GROUP BY scenario_id
)
SELECT sr.scenario_id,sr.scenario_code,sr.scenario_version,sr.scenario_type
FROM pos_used p
JOIN deposit_used d USING(scenario_id)
JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=p.scenario_id
JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
WHERE p.row_count=135000
  AND d.row_count=135000
  AND ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS'
  AND ss.scenario_set_version=1
  AND ss.status='APPROVED'
  AND sr.status='APPROVED'
  AND sr.scenario_version=1
  AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY');
CREATE UNIQUE INDEX ON _m1_9_scenarios(scenario_id);
CREATE UNIQUE INDEX ON _m1_9_scenarios(scenario_code);
ANALYZE _m1_9_scenarios;

CREATE TEMP TABLE _m1_9_source_app ON COMMIT DROP AS
SELECT
    s.merchant_application_id,
    max(s.source_snapshot_id) FILTER(WHERE s.source_code='POS_DAILY') AS pos_source_snapshot_id,
    max(s.source_snapshot_id) FILTER(WHERE s.source_code='DEPOSIT_DAILY') AS deposit_source_snapshot_id,
    max(s.history_start_date) FILTER(WHERE s.source_code='POS_DAILY') AS pos_history_start_date,
    max(s.history_end_date) FILTER(WHERE s.source_code='POS_DAILY') AS pos_history_end_date,
    max(s.history_start_date) FILTER(WHERE s.source_code='DEPOSIT_DAILY') AS deposit_history_start_date,
    max(s.history_end_date) FILTER(WHERE s.source_code='DEPOSIT_DAILY') AS deposit_history_end_date,
    max(s.availability_status) FILTER(WHERE s.source_code='POS_DAILY') AS pos_availability_status,
    max(s.availability_status) FILTER(WHERE s.source_code='DEPOSIT_DAILY') AS deposit_availability_status,
    max(s.quality_status) FILTER(WHERE s.source_code='POS_DAILY') AS pos_quality_status,
    max(s.quality_status) FILTER(WHERE s.source_code='DEPOSIT_DAILY') AS deposit_quality_status,
    count(*) FILTER(WHERE s.quality_status='CONFLICT') AS source_conflict_count,
    greatest(0,least(1,
      sum(s.data_confidence_score *
          coalesce((c.profile_payload->'source_weights'->>s.source_code)::numeric,0))
      - coalesce(max(c.missing_pos_penalty) FILTER(WHERE s.source_code='POS_DAILY' AND s.availability_status='UNAVAILABLE'),0)
      - coalesce(max(c.missing_deposit_penalty) FILTER(WHERE s.source_code='DEPOSIT_DAILY' AND s.availability_status='UNAVAILABLE'),0)
    ))::numeric AS source_confidence_score
FROM msbf_m1.source_snapshot s CROSS JOIN _m1_9_ctx c
WHERE s.module1_run_id=c.run_id
GROUP BY s.merchant_application_id;
CREATE UNIQUE INDEX ON _m1_9_source_app(merchant_application_id);

CREATE TEMP TABLE _m1_9_capture ON COMMIT DROP AS
SELECT merchant_id,merchant_capture_rate
FROM msbf_m1.m1_5_merchant_liquidity_profile((SELECT run_id FROM _m1_9_ctx));
CREATE UNIQUE INDEX ON _m1_9_capture(merchant_id);

CREATE TEMP TABLE _m1_9_apps ON COMMIT DROP AS
SELECT
    a.merchant_application_id,a.population_id,a.merchant_id,a.processor_account_id,
    a.partner_channel_id,a.as_of_date,ia.industry_code,pa.processor_account_open_date,
    sa.pos_source_snapshot_id,sa.deposit_source_snapshot_id,
    sa.pos_history_start_date,sa.pos_history_end_date,
    sa.deposit_history_start_date,sa.deposit_history_end_date,
    sa.pos_availability_status,sa.deposit_availability_status,
    sa.pos_quality_status,sa.deposit_quality_status,
    sa.source_conflict_count,sa.source_confidence_score,
    vf.verification_disposition,vf.fraud_risk_tier,
    vf.processor_continuity_status,vf.processor_continuity_risk_tier,
    vf.stress_processor_continuity_status,vf.stress_processor_continuity_risk_tier,
    vf.manual_review_recommended_flag AS m1_8_review_flag,
    vf.hard_stop_recommended_flag AS m1_8_stop_flag,
    cap.merchant_capture_rate,
    CASE WHEN sa.source_confidence_score>=c.conf_high THEN 'HIGH'
         WHEN sa.source_confidence_score>=c.conf_medium THEN 'MEDIUM'
         WHEN sa.source_confidence_score>=c.conf_low THEN 'LOW'
         ELSE 'REVIEW' END AS data_confidence_tier
FROM msbf_m1.merchant_application a
JOIN msbf_m1.merchant_industry_assignment ia
  ON ia.merchant_id=a.merchant_id AND ia.assignment_type='PRIMARY'
JOIN msbf_m1.processor_account pa ON pa.processor_account_id=a.processor_account_id
JOIN _m1_9_source_app sa ON sa.merchant_application_id=a.merchant_application_id
JOIN msbf_m1.application_verification_fraud_snapshot vf
  ON vf.module1_run_id=(SELECT run_id FROM _m1_9_ctx)
 AND vf.merchant_application_id=a.merchant_application_id
JOIN _m1_9_capture cap ON cap.merchant_id=a.merchant_id
CROSS JOIN _m1_9_ctx c
WHERE a.created_by_run_id=c.run_id;
CREATE UNIQUE INDEX ON _m1_9_apps(merchant_application_id);
CREATE INDEX ON _m1_9_apps(merchant_id);
ANALYZE _m1_9_apps;

DO $n$ BEGIN RAISE NOTICE 'M1.9 Phase 2/6 — materialize scenario POS history and bounded rolling statistics'; END $n$;

CREATE TEMP TABLE _m1_9_pos_base ON COMMIT DROP AS
SELECT
    p.scenario_id,sc.scenario_code,a.merchant_application_id,p.merchant_id,
    p.processor_account_id,p.observation_date,a.as_of_date,a.processor_account_open_date,
    p.gross_pos_sales,p.eligible_pos_sales,p.refund_amount,p.chargeback_amount,
    p.reversal_amount,p.net_merchant_proceeds,p.zero_sales_day_flag,
    p.processor_status,p.data_connection_status,
    (a.pos_availability_status<>'UNAVAILABLE'
      AND p.observation_date BETWEEN coalesce(a.pos_history_start_date,c.history_start_date)
                                 AND coalesce(a.pos_history_end_date,c.history_end_date)
      AND p.observation_date<=a.as_of_date
      AND p.data_connection_status IN ('CONNECTED','DELAYED')) AS usable_pos_flag,
    (a.pos_availability_status<>'UNAVAILABLE'
      AND p.observation_date>=a.processor_account_open_date
      AND p.observation_date<=a.as_of_date) AS active_calendar_flag,
    floor((p.observation_date-c.history_start_date)/30.0)::integer AS period_index,
    extract(isodow FROM p.observation_date)::integer AS iso_dow
FROM msbf_m1.merchant_pos_daily_scenario p
JOIN _m1_9_scenarios sc ON sc.scenario_id=p.scenario_id
JOIN _m1_9_apps a ON a.merchant_id=p.merchant_id AND a.processor_account_id=p.processor_account_id
CROSS JOIN _m1_9_ctx c
WHERE p.generated_by_run_id=c.run_id;
CREATE INDEX ON _m1_9_pos_base(scenario_id,merchant_id,observation_date);
ANALYZE _m1_9_pos_base;

CREATE TEMP TABLE _m1_9_pos_roll ON COMMIT DROP AS
SELECT
    b.*,
    sum(CASE WHEN usable_pos_flag THEN eligible_pos_sales ELSE 0 END)
      OVER(PARTITION BY scenario_id,merchant_id ORDER BY observation_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
      AS rolling_30_eligible_sales
FROM _m1_9_pos_base b;
CREATE INDEX ON _m1_9_pos_roll(scenario_id,merchant_id,observation_date);
ANALYZE _m1_9_pos_roll;

CREATE TEMP TABLE _m1_9_pos_dow ON COMMIT DROP AS
SELECT scenario_id,merchant_id,iso_dow,
       avg(eligible_pos_sales) FILTER(WHERE usable_pos_flag) AS dow_avg_sales
FROM _m1_9_pos_base
GROUP BY scenario_id,merchant_id,iso_dow;
CREATE UNIQUE INDEX ON _m1_9_pos_dow(scenario_id,merchant_id,iso_dow);

CREATE TEMP TABLE _m1_9_pos_overall ON COMMIT DROP AS
SELECT scenario_id,merchant_id,
       avg(eligible_pos_sales) FILTER(WHERE usable_pos_flag) AS overall_avg_sales,
       count(*) FILTER(WHERE usable_pos_flag)::integer AS usable_days
FROM _m1_9_pos_base
GROUP BY scenario_id,merchant_id;
CREATE UNIQUE INDEX ON _m1_9_pos_overall(scenario_id,merchant_id);

CREATE TEMP TABLE _m1_9_period_sales ON COMMIT DROP AS
SELECT b.scenario_id,b.merchant_id,b.period_index,
       avg(CASE WHEN b.usable_pos_flag AND d.dow_avg_sales>0 AND o.overall_avg_sales>0
                THEN b.eligible_pos_sales/d.dow_avg_sales*o.overall_avg_sales END) AS adjusted_period_avg
FROM _m1_9_pos_base b
JOIN _m1_9_pos_dow d USING(scenario_id,merchant_id,iso_dow)
JOIN _m1_9_pos_overall o USING(scenario_id,merchant_id)
GROUP BY b.scenario_id,b.merchant_id,b.period_index;
CREATE INDEX ON _m1_9_period_sales(scenario_id,merchant_id);

CREATE TEMP TABLE _m1_9_seasonality ON COMMIT DROP AS
SELECT p.scenario_id,p.merchant_id,
       CASE WHEN max(o.usable_days)>=c.min_seasonality_days AND avg(o.overall_avg_sales)>c.mean_sales_epsilon
            THEN greatest(0,least(c.seasonality_cap,
                 (max(p.adjusted_period_avg)-min(p.adjusted_period_avg))/nullif(avg(o.overall_avg_sales),0)))
            ELSE NULL END AS seasonality_index_180d
FROM _m1_9_period_sales p
JOIN _m1_9_pos_overall o USING(scenario_id,merchant_id)
CROSS JOIN _m1_9_ctx c
WHERE p.adjusted_period_avg IS NOT NULL
GROUP BY p.scenario_id,p.merchant_id,c.min_seasonality_days,c.mean_sales_epsilon,c.seasonality_cap;
CREATE UNIQUE INDEX ON _m1_9_seasonality(scenario_id,merchant_id);

CREATE TEMP TABLE _m1_9_pos_features_raw ON COMMIT DROP AS
SELECT
    r.scenario_id,r.scenario_code,r.merchant_application_id,r.merchant_id,
    count(*) FILTER(WHERE r.usable_pos_flag)::integer AS pos_history_days,
    count(*) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-6)::integer AS pos_days_7,
    count(*) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-29)::integer AS pos_days_30,
    count(*) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-59)::integer AS pos_days_60,
    count(*) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-89)::integer AS pos_days_90,
    avg(r.eligible_pos_sales) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-6) AS avg_sales_7,
    avg(r.eligible_pos_sales) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-29) AS avg_sales_30,
    avg(r.eligible_pos_sales) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-59) AS avg_sales_60,
    avg(r.eligible_pos_sales) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-89) AS avg_sales_90,
    stddev_pop(r.eligible_pos_sales) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-29) AS sd_sales_30,
    stddev_pop(r.eligible_pos_sales) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-89) AS sd_sales_90,
    count(*) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-29 AND r.zero_sales_day_flag)::numeric AS zero_days_30,
    count(*) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-29 AND r.eligible_pos_sales>0)::numeric AS active_days_30,
    sum(r.gross_pos_sales) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-29) AS gross_sales_30,
    sum(r.eligible_pos_sales) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-29) AS eligible_sales_30,
    sum(r.eligible_pos_sales) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-89) AS eligible_sales_90,
    sum(r.eligible_pos_sales) FILTER(WHERE r.usable_pos_flag) AS eligible_sales_180,
    sum(r.refund_amount) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-29) AS refund_30,
    sum(r.chargeback_amount) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-29) AS chargeback_30,
    sum(r.reversal_amount) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-29) AS reversal_30,
    sum(r.net_merchant_proceeds) FILTER(WHERE r.usable_pos_flag AND r.observation_date>=r.as_of_date-29) AS net_proceeds_30,
    max(r.rolling_30_eligible_sales) AS largest_rolling_30_sales,
    count(*) FILTER(WHERE r.active_calendar_flag AND r.observation_date>=r.as_of_date-29)::numeric AS active_calendar_days_30,
    count(*) FILTER(WHERE r.active_calendar_flag AND r.observation_date>=r.as_of_date-29 AND r.processor_status='OUTAGE')::numeric AS outage_days_30,
    count(*) FILTER(WHERE r.active_calendar_flag AND r.observation_date>=r.as_of_date-29 AND r.processor_status='DEGRADED')::numeric AS degraded_days_30
FROM _m1_9_pos_roll r
GROUP BY r.scenario_id,r.scenario_code,r.merchant_application_id,r.merchant_id;
CREATE UNIQUE INDEX ON _m1_9_pos_features_raw(scenario_id,merchant_application_id);

DO $n$ BEGIN RAISE NOTICE 'M1.9 Phase 3/6 — aggregate scenario deposit/liquidity history once'; END $n$;

CREATE TEMP TABLE _m1_9_deposit_base ON COMMIT DROP AS
SELECT
    d.scenario_id,sc.scenario_code,a.merchant_application_id,d.merchant_id,
    d.observation_date,a.as_of_date,d.deposit_amount,d.withdrawal_amount,
    d.available_balance,d.minimum_balance,d.nsf_count,d.negative_balance_flag,
    (a.deposit_availability_status<>'UNAVAILABLE'
      AND d.observation_date BETWEEN coalesce(a.deposit_history_start_date,c.history_start_date)
                                 AND coalesce(a.deposit_history_end_date,c.history_end_date)
      AND d.observation_date<=a.as_of_date) AS usable_deposit_flag
FROM msbf_m1.merchant_deposit_daily_scenario d
JOIN _m1_9_scenarios sc ON sc.scenario_id=d.scenario_id
JOIN _m1_9_apps a ON a.merchant_id=d.merchant_id
CROSS JOIN _m1_9_ctx c
WHERE d.generated_by_run_id=c.run_id;
CREATE INDEX ON _m1_9_deposit_base(scenario_id,merchant_id,observation_date);
ANALYZE _m1_9_deposit_base;

CREATE TEMP TABLE _m1_9_deposit_features_raw ON COMMIT DROP AS
SELECT
    d.scenario_id,d.scenario_code,d.merchant_application_id,d.merchant_id,
    count(*) FILTER(WHERE d.usable_deposit_flag)::integer AS deposit_history_days,
    count(*) FILTER(WHERE d.usable_deposit_flag AND d.observation_date>=d.as_of_date-29)::integer AS deposit_days_30,
    sum(d.deposit_amount) FILTER(WHERE d.usable_deposit_flag AND d.observation_date>=d.as_of_date-29) AS deposits_30,
    sum(d.withdrawal_amount) FILTER(WHERE d.usable_deposit_flag AND d.observation_date>=d.as_of_date-29) AS withdrawals_30,
    avg(d.available_balance) FILTER(WHERE d.usable_deposit_flag AND d.observation_date>=d.as_of_date-29) AS avg_available_30,
    min(d.minimum_balance) FILTER(WHERE d.usable_deposit_flag AND d.observation_date>=d.as_of_date-29) AS min_balance_30,
    count(*) FILTER(WHERE d.usable_deposit_flag AND d.observation_date>=d.as_of_date-29 AND d.negative_balance_flag)::numeric AS negative_days_30,
    sum(d.nsf_count) FILTER(WHERE d.usable_deposit_flag AND d.observation_date>=d.as_of_date-29)::integer AS nsf_30
FROM _m1_9_deposit_base d
GROUP BY d.scenario_id,d.scenario_code,d.merchant_application_id,d.merchant_id;
CREATE UNIQUE INDEX ON _m1_9_deposit_features_raw(scenario_id,merchant_application_id);

DO $n$ BEGIN RAISE NOTICE 'M1.9 Phase 4/6 — calculate bounded scenario-aware feature snapshots and matched deltas'; END $n$;

CREATE TEMP TABLE _m1_9_scenario_features ON COMMIT DROP AS
SELECT
    p.scenario_id,p.scenario_code,p.merchant_application_id,p.merchant_id,
    p.pos_history_days,coalesce(d.deposit_history_days,0) AS deposit_history_days,
    CASE WHEN p.pos_days_7>=least(7,p.pos_history_days) AND p.pos_days_7>0 THEN round(p.avg_sales_7,2) END AS avg_daily_eligible_sales_7d,
    CASE WHEN p.pos_days_30>=least(c.min_core_pos_days,p.pos_history_days) AND p.pos_days_30>0 THEN round(p.avg_sales_30,2) END AS avg_daily_eligible_sales_30d,
    CASE WHEN p.pos_days_60>=least(60,p.pos_history_days) AND p.pos_days_60>0 THEN round(p.avg_sales_60,2) END AS avg_daily_eligible_sales_60d,
    CASE WHEN p.pos_days_90>=least(c.min_full_pos_days,p.pos_history_days) AND p.pos_days_90>0 THEN round(p.avg_sales_90,2) END AS avg_daily_eligible_sales_90d,
    CASE WHEN p.pos_days_90>=least(c.min_full_pos_days,p.pos_history_days) AND p.pos_days_90>0
         THEN round(round(p.avg_sales_90,2)*c.annualization_days,2) END AS annualized_eligible_sales,
    CASE WHEN p.avg_sales_30>c.mean_sales_epsilon THEN round(greatest(c.growth_floor,least(c.growth_cap,p.avg_sales_7/p.avg_sales_30-1)),8) END AS sales_growth_7d_vs_30d,
    CASE WHEN p.avg_sales_90>c.mean_sales_epsilon THEN round(greatest(c.growth_floor,least(c.growth_cap,p.avg_sales_30/p.avg_sales_90-1)),8) END AS sales_growth_30d_vs_90d,
    CASE WHEN p.avg_sales_30>c.mean_sales_epsilon THEN round(least(c.cv_cap,p.sd_sales_30/p.avg_sales_30),8) END AS daily_sales_cv_30d,
    CASE WHEN p.avg_sales_90>c.mean_sales_epsilon THEN round(least(c.cv_cap,p.sd_sales_90/p.avg_sales_90),8) END AS daily_sales_cv_90d,
    CASE WHEN p.pos_days_30>0 THEN round(p.zero_days_30/p.pos_days_30,8) END AS zero_sales_day_rate_30d,
    CASE WHEN p.pos_days_30>0 THEN round(p.active_days_30/p.pos_days_30,8) END AS active_sales_day_rate_30d,
    round(se.seasonality_index_180d,8) AS seasonality_index_180d,
    CASE WHEN p.eligible_sales_180>0 THEN round(least(1,p.largest_rolling_30_sales/p.eligible_sales_180),8) END AS largest_30d_share_180d,
    CASE WHEN p.gross_sales_30>0 THEN round(p.refund_30/p.gross_sales_30,8) END AS refund_rate_30d,
    CASE WHEN p.gross_sales_30>0 THEN round(p.chargeback_30/p.gross_sales_30,8) END AS chargeback_rate_30d,
    CASE WHEN p.gross_sales_30>0 THEN round(p.reversal_30/p.gross_sales_30,8) END AS reversal_rate_30d,
    CASE WHEN p.eligible_sales_30>0 AND d.deposits_30 IS NOT NULL THEN round(least(c.ratio_cap,d.deposits_30/p.eligible_sales_30),8) END AS deposit_to_eligible_sales_rate_30d,
    CASE WHEN d.deposits_30 IS NOT NULL AND p.net_proceeds_30>0 AND a.merchant_capture_rate>0 THEN
        round(greatest(0,least(1,
            least(d.deposits_30/nullif(p.net_proceeds_30*a.merchant_capture_rate,0),
                  (p.net_proceeds_30*a.merchant_capture_rate)/nullif(d.deposits_30,0))
        )),8) END AS pos_deposit_reconciliation_rate_30d,
    CASE WHEN d.deposit_days_30>0 THEN round(d.negative_days_30/d.deposit_days_30,8) END AS negative_balance_day_rate_30d,
    d.nsf_30 AS nsf_count_30d,
    round(d.avg_available_30,2) AS average_available_balance_30d,
    round(d.min_balance_30,2) AS minimum_balance_30d,
    CASE WHEN p.avg_sales_30>c.mean_sales_epsilon AND d.avg_available_30 IS NOT NULL THEN
        round(greatest(-c.buffer_days_cap,least(c.buffer_days_cap,d.avg_available_30/p.avg_sales_30)),4) END AS cash_flow_buffer_days,
    CASE WHEN p.active_calendar_days_30>0 THEN round(p.outage_days_30/p.active_calendar_days_30,8) END AS processor_outage_day_rate_30d,
    CASE WHEN p.active_calendar_days_30>0 THEN round(p.degraded_days_30/p.active_calendar_days_30,8) END AS processor_degraded_day_rate_30d,
    p.eligible_sales_30,p.eligible_sales_90,d.deposits_30,d.withdrawals_30,d.avg_available_30,
    d.negative_days_30,d.deposit_days_30,d.nsf_30,p.refund_30,p.chargeback_30,p.gross_sales_30
FROM _m1_9_pos_features_raw p
LEFT JOIN _m1_9_deposit_features_raw d
  ON d.scenario_id=p.scenario_id AND d.merchant_application_id=p.merchant_application_id
JOIN _m1_9_apps a ON a.merchant_application_id=p.merchant_application_id
LEFT JOIN _m1_9_seasonality se ON se.scenario_id=p.scenario_id AND se.merchant_id=p.merchant_id
CROSS JOIN _m1_9_ctx c;
CREATE UNIQUE INDEX ON _m1_9_scenario_features(scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_9_baseline ON COMMIT DROP AS
SELECT sf.* FROM _m1_9_scenario_features sf WHERE sf.scenario_code='BASELINE';
CREATE UNIQUE INDEX ON _m1_9_baseline(merchant_application_id);

CREATE TEMP TABLE _m1_9_wide ON COMMIT DROP AS
SELECT
    sf.*,
    a.population_id,a.as_of_date,
    a.pos_source_snapshot_id,a.deposit_source_snapshot_id,
    a.source_confidence_score,a.data_confidence_tier,
    a.pos_quality_status,a.deposit_quality_status,
    a.pos_availability_status,a.deposit_availability_status,
    a.verification_disposition,a.fraud_risk_tier,
    a.processor_continuity_status,a.processor_continuity_risk_tier,
    a.stress_processor_continuity_status,a.stress_processor_continuity_risk_tier,
    a.m1_8_review_flag,a.m1_8_stop_flag,a.source_conflict_count,
    CASE WHEN sf.scenario_code='BASELINE' THEN 0::numeric
         WHEN sf.avg_daily_eligible_sales_30d IS NOT NULL AND b.avg_daily_eligible_sales_30d IS NOT NULL
         THEN round(greatest(-c.ratio_cap,least(c.ratio_cap,(sf.avg_daily_eligible_sales_30d-b.avg_daily_eligible_sales_30d)/greatest(abs(b.avg_daily_eligible_sales_30d),c.delta_floor))),8) END AS scenario_eligible_sales_delta_rate_30d,
    CASE WHEN sf.scenario_code='BASELINE' THEN 0::numeric
         WHEN sf.avg_daily_eligible_sales_90d IS NOT NULL AND b.avg_daily_eligible_sales_90d IS NOT NULL
         THEN round(greatest(-c.ratio_cap,least(c.ratio_cap,(sf.avg_daily_eligible_sales_90d-b.avg_daily_eligible_sales_90d)/greatest(abs(b.avg_daily_eligible_sales_90d),c.delta_floor))),8) END AS scenario_eligible_sales_delta_rate_90d,
    CASE WHEN sf.scenario_code='BASELINE' THEN 0::numeric
         WHEN sf.deposits_30 IS NOT NULL AND b.deposits_30 IS NOT NULL
         THEN round(greatest(-c.ratio_cap,least(c.ratio_cap,(sf.deposits_30-b.deposits_30)/greatest(abs(b.deposits_30),c.delta_floor))),8) END AS scenario_deposit_delta_rate_30d,
    CASE WHEN sf.scenario_code='BASELINE' THEN 0::numeric
         WHEN sf.withdrawals_30 IS NOT NULL AND b.withdrawals_30 IS NOT NULL
         THEN round(greatest(-c.ratio_cap,least(c.ratio_cap,(sf.withdrawals_30-b.withdrawals_30)/greatest(abs(b.withdrawals_30),c.delta_floor))),8) END AS scenario_withdrawal_delta_rate_30d,
    CASE WHEN sf.scenario_code='BASELINE' THEN 0::numeric
         WHEN sf.average_available_balance_30d IS NOT NULL AND b.average_available_balance_30d IS NOT NULL
         THEN round(greatest(-c.ratio_cap,least(c.ratio_cap,(sf.average_available_balance_30d-b.average_available_balance_30d)/greatest(abs(b.average_available_balance_30d),c.delta_floor))),8) END AS scenario_available_balance_delta_rate_30d,
    CASE WHEN sf.scenario_code='BASELINE' THEN 0::numeric
         WHEN sf.negative_balance_day_rate_30d IS NOT NULL AND b.negative_balance_day_rate_30d IS NOT NULL
         THEN round(sf.negative_balance_day_rate_30d-b.negative_balance_day_rate_30d,8) END AS scenario_negative_balance_rate_delta_30d,
    CASE WHEN sf.scenario_code='BASELINE' THEN 0
         WHEN sf.nsf_count_30d IS NOT NULL AND b.nsf_count_30d IS NOT NULL THEN sf.nsf_count_30d-b.nsf_count_30d END AS scenario_nsf_count_delta_30d,
    CASE WHEN sf.scenario_code='BASELINE' THEN 0::numeric
         WHEN sf.processor_outage_day_rate_30d IS NOT NULL AND b.processor_outage_day_rate_30d IS NOT NULL
         THEN round(sf.processor_outage_day_rate_30d-b.processor_outage_day_rate_30d,8) END AS scenario_processor_outage_rate_delta_30d,
    CASE WHEN sf.scenario_code='BASELINE' THEN 0::numeric
         WHEN sf.refund_rate_30d IS NOT NULL AND b.refund_rate_30d IS NOT NULL
         THEN round(sf.refund_rate_30d-b.refund_rate_30d,8) END AS scenario_refund_rate_delta_30d,
    CASE WHEN sf.scenario_code='BASELINE' THEN 0::numeric
         WHEN sf.chargeback_rate_30d IS NOT NULL AND b.chargeback_rate_30d IS NOT NULL
         THEN round(sf.chargeback_rate_30d-b.chargeback_rate_30d,8) END AS scenario_chargeback_rate_delta_30d
FROM _m1_9_scenario_features sf
JOIN _m1_9_baseline b
  ON b.merchant_application_id=sf.merchant_application_id
 AND b.merchant_id=sf.merchant_id
JOIN _m1_9_apps a
  ON a.merchant_application_id=sf.merchant_application_id
 AND a.merchant_id=sf.merchant_id
CROSS JOIN _m1_9_ctx c;
CREATE UNIQUE INDEX ON _m1_9_wide(scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_9_snapshot_pre ON COMMIT DROP AS
SELECT
    c.run_id::bigint AS module1_run_id,
    w.scenario_id::bigint,
    w.merchant_application_id::text,
    w.population_id::text,
    w.merchant_id::text,
    w.as_of_date::date,
    c.history_start_date::date,
    c.history_end_date::date,
    w.pos_source_snapshot_id::bigint,
    w.deposit_source_snapshot_id::bigint,
    round(w.source_confidence_score,6)::numeric(9,6) AS source_confidence_score,
    w.data_confidence_tier::text,
    w.pos_quality_status::text,
    w.deposit_quality_status::text,
    CASE WHEN w.pos_availability_status='UNAVAILABLE'
              OR w.verification_disposition IN ('STOP','INSUFFICIENT_EVIDENCE') THEN 'BLOCKED'
         WHEN w.deposit_availability_status='UNAVAILABLE'
              OR w.pos_quality_status<>'PASS' OR w.deposit_quality_status<>'PASS'
              OR w.pos_history_days<c.min_full_pos_days OR w.deposit_history_days<c.min_deposit_days THEN 'PARTIAL'
         ELSE 'COMPLETE' END::text AS feature_completeness_status,
    w.verification_disposition::text AS downstream_routing_status,
    (w.pos_availability_status<>'UNAVAILABLE'
       AND w.verification_disposition NOT IN ('STOP','INSUFFICIENT_EVIDENCE'))::boolean AS ready_for_downstream_flag,
    (w.m1_8_review_flag OR w.data_confidence_tier IN ('LOW','REVIEW')
       OR w.source_conflict_count>0 OR w.deposit_availability_status='UNAVAILABLE'
       OR w.pos_quality_status<>'PASS' OR w.deposit_quality_status<>'PASS')::boolean AS manual_review_recommended_flag,
    w.verification_disposition::text,
    w.fraud_risk_tier::smallint,
    CASE WHEN w.scenario_code='BASELINE' THEN w.processor_continuity_status ELSE w.stress_processor_continuity_status END::text AS processor_continuity_status,
    CASE WHEN w.scenario_code='BASELINE' THEN w.processor_continuity_risk_tier ELSE w.stress_processor_continuity_risk_tier END::smallint AS processor_continuity_risk_tier,
    w.pos_history_days::integer,
    w.deposit_history_days::integer,
    w.avg_daily_eligible_sales_7d::numeric(18,2) AS avg_daily_eligible_sales_7d,
    w.avg_daily_eligible_sales_30d::numeric(18,2) AS avg_daily_eligible_sales_30d,
    w.avg_daily_eligible_sales_60d::numeric(18,2) AS avg_daily_eligible_sales_60d,
    w.avg_daily_eligible_sales_90d::numeric(18,2) AS avg_daily_eligible_sales_90d,
    w.annualized_eligible_sales::numeric(18,2) AS annualized_eligible_sales,
    w.sales_growth_7d_vs_30d::numeric(12,8) AS sales_growth_7d_vs_30d,
    w.sales_growth_30d_vs_90d::numeric(12,8) AS sales_growth_30d_vs_90d,
    w.daily_sales_cv_30d::numeric(12,8) AS daily_sales_cv_30d,
    w.daily_sales_cv_90d::numeric(12,8) AS daily_sales_cv_90d,
    w.zero_sales_day_rate_30d::numeric(12,8) AS zero_sales_day_rate_30d,
    w.active_sales_day_rate_30d::numeric(12,8) AS active_sales_day_rate_30d,
    w.seasonality_index_180d::numeric(12,8) AS seasonality_index_180d,
    w.largest_30d_share_180d::numeric(12,8) AS largest_30d_share_180d,
    w.refund_rate_30d::numeric(12,8) AS refund_rate_30d,
    w.chargeback_rate_30d::numeric(12,8) AS chargeback_rate_30d,
    w.reversal_rate_30d::numeric(12,8) AS reversal_rate_30d,
    w.deposit_to_eligible_sales_rate_30d::numeric(12,8) AS deposit_to_eligible_sales_rate_30d,
    w.pos_deposit_reconciliation_rate_30d::numeric(12,8) AS pos_deposit_reconciliation_rate_30d,
    w.negative_balance_day_rate_30d::numeric(12,8) AS negative_balance_day_rate_30d,
    w.nsf_count_30d::integer AS nsf_count_30d,
    w.average_available_balance_30d::numeric(18,2) AS average_available_balance_30d,
    w.minimum_balance_30d::numeric(18,2) AS minimum_balance_30d,
    w.cash_flow_buffer_days::numeric(12,4) AS cash_flow_buffer_days,
    w.processor_outage_day_rate_30d::numeric(12,8) AS processor_outage_day_rate_30d,
    w.processor_degraded_day_rate_30d::numeric(12,8) AS processor_degraded_day_rate_30d,
    w.scenario_eligible_sales_delta_rate_30d::numeric(12,8) AS scenario_eligible_sales_delta_rate_30d,
    w.scenario_eligible_sales_delta_rate_90d::numeric(12,8) AS scenario_eligible_sales_delta_rate_90d,
    w.scenario_deposit_delta_rate_30d::numeric(12,8) AS scenario_deposit_delta_rate_30d,
    w.scenario_withdrawal_delta_rate_30d::numeric(12,8) AS scenario_withdrawal_delta_rate_30d,
    w.scenario_available_balance_delta_rate_30d::numeric(12,8) AS scenario_available_balance_delta_rate_30d,
    w.scenario_negative_balance_rate_delta_30d::numeric(12,8) AS scenario_negative_balance_rate_delta_30d,
    w.scenario_nsf_count_delta_30d::integer AS scenario_nsf_count_delta_30d,
    w.scenario_processor_outage_rate_delta_30d::numeric(12,8) AS scenario_processor_outage_rate_delta_30d,
    w.scenario_refund_rate_delta_30d::numeric(12,8) AS scenario_refund_rate_delta_30d,
    w.scenario_chargeback_rate_delta_30d::numeric(12,8) AS scenario_chargeback_rate_delta_30d,
    c.run_id::bigint AS created_by_run_id
FROM _m1_9_wide w CROSS JOIN _m1_9_ctx c;
CREATE UNIQUE INDEX ON _m1_9_snapshot_pre(scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_9_snapshot_blueprint ON COMMIT DROP AS
SELECT p.*,msbf_m1.m1_9_hash_jsonb(to_jsonb(p)) AS feature_snapshot_hash
FROM _m1_9_snapshot_pre p;
CREATE UNIQUE INDEX ON _m1_9_snapshot_blueprint(scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_9_feature_value_pre ON COMMIT DROP AS
SELECT
    s.module1_run_id::bigint AS module1_run_id,
    s.scenario_id::bigint AS scenario_id,
    s.merchant_application_id::text AS merchant_application_id,
    x.feature_code::text AS feature_code,
    x.feature_version::integer AS feature_version,
    x.value_numeric::numeric(24,10) AS value_numeric,
    x.value_status::text AS value_status,
    x.primary_source_snapshot_id::bigint AS primary_source_snapshot_id,
    x.secondary_source_snapshot_id::bigint AS secondary_source_snapshot_id,
    x.observation_start_date::date AS observation_start_date,
    x.observation_end_date::date AS observation_end_date,
    s.created_by_run_id::bigint AS created_by_run_id
FROM _m1_9_snapshot_blueprint s
CROSS JOIN LATERAL (VALUES
        ('AVG_DAILY_ELIGIBLE_SALES_7D',1,(s.avg_daily_eligible_sales_7d)::numeric,CASE WHEN s.avg_daily_eligible_sales_7d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-6)::date,s.as_of_date),
        ('AVG_DAILY_ELIGIBLE_SALES_30D',1,(s.avg_daily_eligible_sales_30d)::numeric,CASE WHEN s.avg_daily_eligible_sales_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('AVG_DAILY_ELIGIBLE_SALES_60D',1,(s.avg_daily_eligible_sales_60d)::numeric,CASE WHEN s.avg_daily_eligible_sales_60d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-59)::date,s.as_of_date),
        ('AVG_DAILY_ELIGIBLE_SALES_90D',1,(s.avg_daily_eligible_sales_90d)::numeric,CASE WHEN s.avg_daily_eligible_sales_90d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-89)::date,s.as_of_date),
        ('ANNUALIZED_ELIGIBLE_SALES',1,(s.annualized_eligible_sales)::numeric,CASE WHEN s.annualized_eligible_sales IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-89)::date,s.as_of_date),
        ('SALES_GROWTH_7D_VS_30D',1,(s.sales_growth_7d_vs_30d)::numeric,CASE WHEN s.sales_growth_7d_vs_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('SALES_GROWTH_30D_VS_90D',1,(s.sales_growth_30d_vs_90d)::numeric,CASE WHEN s.sales_growth_30d_vs_90d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-89)::date,s.as_of_date),
        ('DAILY_SALES_CV_30D',1,(s.daily_sales_cv_30d)::numeric,CASE WHEN s.daily_sales_cv_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('DAILY_SALES_CV_90D',1,(s.daily_sales_cv_90d)::numeric,CASE WHEN s.daily_sales_cv_90d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-89)::date,s.as_of_date),
        ('ZERO_SALES_DAY_RATE_30D',1,(s.zero_sales_day_rate_30d)::numeric,CASE WHEN s.zero_sales_day_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('ACTIVE_SALES_DAY_RATE_30D',1,(s.active_sales_day_rate_30d)::numeric,CASE WHEN s.active_sales_day_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('SEASONALITY_INDEX_180D',1,(s.seasonality_index_180d)::numeric,CASE WHEN s.seasonality_index_180d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-179)::date,s.as_of_date),
        ('LARGEST_30D_SHARE_180D',1,(s.largest_30d_share_180d)::numeric,CASE WHEN s.largest_30d_share_180d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-179)::date,s.as_of_date),
        ('REFUND_RATE_30D',1,(s.refund_rate_30d)::numeric,CASE WHEN s.refund_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('CHARGEBACK_RATE_30D',1,(s.chargeback_rate_30d)::numeric,CASE WHEN s.chargeback_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('REVERSAL_RATE_30D',1,(s.reversal_rate_30d)::numeric,CASE WHEN s.reversal_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('DEPOSIT_TO_ELIGIBLE_SALES_RATE_30D',1,(s.deposit_to_eligible_sales_rate_30d)::numeric,CASE WHEN s.deposit_to_eligible_sales_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,s.deposit_source_snapshot_id,(s.as_of_date-29)::date,s.as_of_date),
        ('POS_DEPOSIT_RECONCILIATION_RATE_30D',1,(s.pos_deposit_reconciliation_rate_30d)::numeric,CASE WHEN s.pos_deposit_reconciliation_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,s.deposit_source_snapshot_id,(s.as_of_date-29)::date,s.as_of_date),
        ('NEGATIVE_BALANCE_DAY_RATE_30D',1,(s.negative_balance_day_rate_30d)::numeric,CASE WHEN s.negative_balance_day_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.deposit_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('NSF_COUNT_30D',1,(s.nsf_count_30d)::numeric,CASE WHEN s.nsf_count_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.deposit_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('AVERAGE_AVAILABLE_BALANCE_30D',1,(s.average_available_balance_30d)::numeric,CASE WHEN s.average_available_balance_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.deposit_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('MINIMUM_BALANCE_30D',1,(s.minimum_balance_30d)::numeric,CASE WHEN s.minimum_balance_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.deposit_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('CASH_FLOW_BUFFER_DAYS',1,(s.cash_flow_buffer_days)::numeric,CASE WHEN s.cash_flow_buffer_days IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,s.deposit_source_snapshot_id,(s.as_of_date-29)::date,s.as_of_date),
        ('PROCESSOR_OUTAGE_DAY_RATE_30D',1,(s.processor_outage_day_rate_30d)::numeric,CASE WHEN s.processor_outage_day_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('PROCESSOR_DEGRADED_DAY_RATE_30D',1,(s.processor_degraded_day_rate_30d)::numeric,CASE WHEN s.processor_degraded_day_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('SOURCE_CONFIDENCE_SCORE',1,(s.source_confidence_score)::numeric,CASE WHEN s.source_confidence_score IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,NULL::bigint,NULL::bigint,NULL::date,NULL::date),
        ('SCENARIO_ELIGIBLE_SALES_DELTA_RATE_30D',1,(s.scenario_eligible_sales_delta_rate_30d)::numeric,CASE WHEN s.scenario_eligible_sales_delta_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('SCENARIO_ELIGIBLE_SALES_DELTA_RATE_90D',1,(s.scenario_eligible_sales_delta_rate_90d)::numeric,CASE WHEN s.scenario_eligible_sales_delta_rate_90d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-89)::date,s.as_of_date),
        ('SCENARIO_DEPOSIT_DELTA_RATE_30D',1,(s.scenario_deposit_delta_rate_30d)::numeric,CASE WHEN s.scenario_deposit_delta_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.deposit_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('SCENARIO_WITHDRAWAL_DELTA_RATE_30D',1,(s.scenario_withdrawal_delta_rate_30d)::numeric,CASE WHEN s.scenario_withdrawal_delta_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.deposit_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('SCENARIO_AVAILABLE_BALANCE_DELTA_RATE_30D',1,(s.scenario_available_balance_delta_rate_30d)::numeric,CASE WHEN s.scenario_available_balance_delta_rate_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.deposit_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('SCENARIO_NEGATIVE_BALANCE_RATE_DELTA_30D',1,(s.scenario_negative_balance_rate_delta_30d)::numeric,CASE WHEN s.scenario_negative_balance_rate_delta_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.deposit_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('SCENARIO_NSF_COUNT_DELTA_30D',1,(s.scenario_nsf_count_delta_30d)::numeric,CASE WHEN s.scenario_nsf_count_delta_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.deposit_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('SCENARIO_PROCESSOR_OUTAGE_RATE_DELTA_30D',1,(s.scenario_processor_outage_rate_delta_30d)::numeric,CASE WHEN s.scenario_processor_outage_rate_delta_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('SCENARIO_REFUND_RATE_DELTA_30D',1,(s.scenario_refund_rate_delta_30d)::numeric,CASE WHEN s.scenario_refund_rate_delta_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date),
        ('SCENARIO_CHARGEBACK_RATE_DELTA_30D',1,(s.scenario_chargeback_rate_delta_30d)::numeric,CASE WHEN s.scenario_chargeback_rate_delta_30d IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,s.pos_source_snapshot_id,NULL::bigint,(s.as_of_date-29)::date,s.as_of_date)
) AS x(feature_code,feature_version,value_numeric,value_status,
       primary_source_snapshot_id,secondary_source_snapshot_id,
       observation_start_date,observation_end_date);
CREATE UNIQUE INDEX ON _m1_9_feature_value_pre(scenario_id,merchant_application_id,feature_code,feature_version);

/* Canonical hashes must be calculated from the same physical representation
   used by msbf_m1.cashflow_feature_value. PostgreSQL JSONB preserves numeric
   display scale, so unconstrained numeric values (for example 12.34) do not
   hash the same as numeric(24,10) values (12.3400000000). */
DO $canonical_type_check$
DECLARE
    v_value_type text;
    v_available_rows bigint;
BEGIN
    SELECT format_type(a.atttypid,a.atttypmod)
      INTO v_value_type
    FROM pg_attribute a
    WHERE a.attrelid='_m1_9_feature_value_pre'::regclass
      AND a.attname='value_numeric'
      AND a.attnum>0
      AND NOT a.attisdropped;

    SELECT count(*) FILTER(WHERE value_status='AVAILABLE')
      INTO v_available_rows
    FROM _m1_9_feature_value_pre;

    IF v_value_type<>'numeric(24,10)' THEN
        RAISE EXCEPTION 'M1.9 canonical value_numeric type mismatch: expected numeric(24,10), observed %.',v_value_type;
    END IF;

    RAISE NOTICE 'M1.9 canonical numeric normalization active for % AVAILABLE feature rows (%).',v_available_rows,v_value_type;
END $canonical_type_check$;

CREATE TEMP TABLE _m1_9_feature_value_blueprint ON COMMIT DROP AS
SELECT p.*,msbf_m1.m1_9_hash_jsonb(to_jsonb(p)) AS calculation_hash
FROM _m1_9_feature_value_pre p;
CREATE UNIQUE INDEX ON _m1_9_feature_value_blueprint(scenario_id,merchant_application_id,feature_code,feature_version);

DO $cardinality$
DECLARE v_snap bigint;v_values bigint;v_apps bigint;v_scen integer;
        v_groups bigint;v_min_features integer;v_max_features integer;
BEGIN
  SELECT count(*),count(DISTINCT merchant_application_id),count(DISTINCT scenario_id)
    INTO v_snap,v_apps,v_scen FROM _m1_9_snapshot_blueprint;
  SELECT count(*) INTO v_values FROM _m1_9_feature_value_blueprint;
  SELECT count(*),min(c),max(c) INTO v_groups,v_min_features,v_max_features
  FROM (SELECT scenario_id,merchant_application_id,count(*) c
        FROM _m1_9_feature_value_blueprint GROUP BY scenario_id,merchant_application_id) q;
  IF v_snap<>1500 OR v_apps<>750 OR v_scen<>2 OR v_values<>54000
     OR v_groups<>1500 OR v_min_features<>36 OR v_max_features<>36 THEN
    RAISE EXCEPTION 'M1.9 blueprint cardinality failed: snapshots %, apps %, scenarios %, feature values %, grouped snapshots %, feature range %-% .',
      v_snap,v_apps,v_scen,v_values,v_groups,v_min_features,v_max_features;
  END IF;
END $cardinality$;

DO $n$ BEGIN RAISE NOTICE 'M1.9 Phase 5/6 — persist, index, analyze and perform canonical reconciliation'; END $n$;

INSERT INTO msbf_m1.application_cashflow_feature_snapshot(
    module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,as_of_date,history_start_date,history_end_date,pos_source_snapshot_id,deposit_source_snapshot_id,source_confidence_score,data_confidence_tier,pos_quality_status,deposit_quality_status,feature_completeness_status,downstream_routing_status,ready_for_downstream_flag,manual_review_recommended_flag,verification_disposition,fraud_risk_tier,processor_continuity_status,processor_continuity_risk_tier,pos_history_days,deposit_history_days,avg_daily_eligible_sales_7d,avg_daily_eligible_sales_30d,avg_daily_eligible_sales_60d,avg_daily_eligible_sales_90d,annualized_eligible_sales,sales_growth_7d_vs_30d,sales_growth_30d_vs_90d,daily_sales_cv_30d,daily_sales_cv_90d,zero_sales_day_rate_30d,active_sales_day_rate_30d,seasonality_index_180d,largest_30d_share_180d,refund_rate_30d,chargeback_rate_30d,reversal_rate_30d,deposit_to_eligible_sales_rate_30d,pos_deposit_reconciliation_rate_30d,negative_balance_day_rate_30d,nsf_count_30d,average_available_balance_30d,minimum_balance_30d,cash_flow_buffer_days,processor_outage_day_rate_30d,processor_degraded_day_rate_30d,scenario_eligible_sales_delta_rate_30d,scenario_eligible_sales_delta_rate_90d,scenario_deposit_delta_rate_30d,scenario_withdrawal_delta_rate_30d,scenario_available_balance_delta_rate_30d,scenario_negative_balance_rate_delta_30d,scenario_nsf_count_delta_30d,scenario_processor_outage_rate_delta_30d,scenario_refund_rate_delta_30d,scenario_chargeback_rate_delta_30d,feature_snapshot_hash,created_by_run_id
)
SELECT module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,as_of_date,history_start_date,history_end_date,pos_source_snapshot_id,deposit_source_snapshot_id,source_confidence_score,data_confidence_tier,pos_quality_status,deposit_quality_status,feature_completeness_status,downstream_routing_status,ready_for_downstream_flag,manual_review_recommended_flag,verification_disposition,fraud_risk_tier,processor_continuity_status,processor_continuity_risk_tier,pos_history_days,deposit_history_days,avg_daily_eligible_sales_7d,avg_daily_eligible_sales_30d,avg_daily_eligible_sales_60d,avg_daily_eligible_sales_90d,annualized_eligible_sales,sales_growth_7d_vs_30d,sales_growth_30d_vs_90d,daily_sales_cv_30d,daily_sales_cv_90d,zero_sales_day_rate_30d,active_sales_day_rate_30d,seasonality_index_180d,largest_30d_share_180d,refund_rate_30d,chargeback_rate_30d,reversal_rate_30d,deposit_to_eligible_sales_rate_30d,pos_deposit_reconciliation_rate_30d,negative_balance_day_rate_30d,nsf_count_30d,average_available_balance_30d,minimum_balance_30d,cash_flow_buffer_days,processor_outage_day_rate_30d,processor_degraded_day_rate_30d,scenario_eligible_sales_delta_rate_30d,scenario_eligible_sales_delta_rate_90d,scenario_deposit_delta_rate_30d,scenario_withdrawal_delta_rate_30d,scenario_available_balance_delta_rate_30d,scenario_negative_balance_rate_delta_30d,scenario_nsf_count_delta_30d,scenario_processor_outage_rate_delta_30d,scenario_refund_rate_delta_30d,scenario_chargeback_rate_delta_30d,feature_snapshot_hash,created_by_run_id FROM _m1_9_snapshot_blueprint;

INSERT INTO msbf_m1.cashflow_feature_value(
    module1_run_id,scenario_id,merchant_application_id,feature_code,feature_version,
    value_numeric,value_status,primary_source_snapshot_id,secondary_source_snapshot_id,
    observation_start_date,observation_end_date,calculation_hash,created_by_run_id
)
SELECT module1_run_id,scenario_id,merchant_application_id,feature_code,feature_version,
       value_numeric,value_status,primary_source_snapshot_id,secondary_source_snapshot_id,
       observation_start_date,observation_end_date,calculation_hash,created_by_run_id
FROM _m1_9_feature_value_blueprint;

ANALYZE msbf_m1.application_cashflow_feature_snapshot;
ANALYZE msbf_m1.cashflow_feature_value;

CREATE TEMP TABLE _m1_9_expected_entities ON COMMIT DROP AS
SELECT 'SNAPSHOT|'||scenario_id||'|'||merchant_application_id AS entity_key,feature_snapshot_hash AS row_hash
FROM _m1_9_snapshot_blueprint
UNION ALL
SELECT 'FEATURE|'||scenario_id||'|'||merchant_application_id||'|'||feature_code||'|v'||feature_version,calculation_hash
FROM _m1_9_feature_value_blueprint;
CREATE UNIQUE INDEX ON _m1_9_expected_entities(entity_key);

CREATE TEMP TABLE _m1_9_actual_entities ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_9_actual_snapshot((SELECT run_id FROM _m1_9_ctx))
UNION ALL
SELECT * FROM msbf_m1.m1_9_actual_feature_value((SELECT run_id FROM _m1_9_ctx));
CREATE UNIQUE INDEX ON _m1_9_actual_entities(entity_key);
ANALYZE _m1_9_expected_entities; ANALYZE _m1_9_actual_entities;

DO $evidence$
DECLARE
 v_run bigint;v_er bigint;v_ar bigint;v_mm bigint;v_eh text;v_ah text;
 v_sh text;v_fh text;v_complete bigint;v_partial bigint;v_blocked bigint;
BEGIN
 SELECT run_id INTO v_run FROM _m1_9_ctx;
 SELECT count(*),md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
   INTO v_er,v_eh FROM _m1_9_expected_entities;
 SELECT count(*),md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
   INTO v_ar,v_ah FROM _m1_9_actual_entities;
 SELECT count(*) INTO v_mm FROM _m1_9_expected_entities e FULL JOIN _m1_9_actual_entities a USING(entity_key)
   WHERE e.row_hash IS DISTINCT FROM a.row_hash;
 SELECT md5(string_agg('SNAPSHOT|'||scenario_id||'|'||merchant_application_id||'|'||feature_snapshot_hash,'||' ORDER BY scenario_id,merchant_application_id))
   INTO v_sh FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=v_run;
 SELECT md5(string_agg('FEATURE|'||scenario_id||'|'||merchant_application_id||'|'||feature_code||'|v'||feature_version||'|'||calculation_hash,'||' ORDER BY scenario_id,merchant_application_id,feature_code,feature_version))
   INTO v_fh FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=v_run;
 SELECT count(*) FILTER(WHERE feature_completeness_status='COMPLETE'),
        count(*) FILTER(WHERE feature_completeness_status='PARTIAL'),
        count(*) FILTER(WHERE feature_completeness_status='BLOCKED')
   INTO v_complete,v_partial,v_blocked
   FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=v_run;
 IF v_er<>55500 OR v_ar<>55500 OR v_mm<>0 OR v_eh<>v_ah THEN
   RAISE EXCEPTION 'M1.9 canonical reconciliation failed: expected %, actual %, mismatches %, hashes %/%',v_er,v_ar,v_mm,v_eh,v_ah;
 END IF;
 DELETE FROM msbf_ctl.run_evidence WHERE run_id=v_run AND evidence_code LIKE 'M1_9_%';
 INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,interpretation)
 VALUES
 (v_run,'M1_9_SNAPSHOT_SET_HASH','PORTFOLIO','M1.9 wide-snapshot set hash',NULL,v_sh,'HASH','PASS','Canonical hash across 1,500 scenario-aware feature snapshots.'),
 (v_run,'M1_9_FEATURE_VALUE_SET_HASH','PORTFOLIO','M1.9 long-feature-value set hash',NULL,v_fh,'HASH','PASS','Canonical hash across 54,000 long feature values.'),
 (v_run,'M1_9_COMBINED_SET_HASH','PORTFOLIO','M1.9 combined canonical set hash',NULL,v_ah,'HASH','PASS','Canonical hash across 55,500 M1.9 entities.'),
 (v_run,'M1_9_CANONICAL_ENTITY_COUNT','PORTFOLIO','M1.9 canonical entities',55500,NULL,'COUNT','PASS','1,500 wide snapshots plus 54,000 long feature values.'),
 (v_run,'M1_9_CANONICAL_MISMATCH_COUNT','PORTFOLIO','M1.9 canonical mismatches',0,NULL,'COUNT','PASS','Expected and physical canonical rows reconcile exactly.'),
 (v_run,'M1_9_FEATURE_COMPLETENESS','PORTFOLIO','M1.9 feature-completeness distribution',NULL,format('COMPLETE=%s|PARTIAL=%s|BLOCKED=%s',v_complete,v_partial,v_blocked),'TEXT','PASS','Scenario-aware feature completeness remains explicit.'),
 (v_run,'M1_9_GENERATION_SPEC','PORTFOLIO','M1.9 generation specification',NULL,'M1_9_METHOD_V1|2 scenarios|750 applications|36 features|annualized=PERSISTED_ROUNDED_90D_AVERAGE*365|as-of and no-leakage controls','TEXT','PASS','Governed M1.9 feature-engineering specification.'),
 (v_run,'M1_9_GENERATION_SUMMARY','PORTFOLIO','M1.9 generation summary',NULL,format('snapshots=1500|feature_values=54000|canonical=55500|mismatches=0|hash=%s',v_ah),'TEXT','PASS','M1.9 generation completed and reconciled.');
 UPDATE msbf_ctl.run_registry
 SET run_status='M1_9_GENERATED',row_count=1500,
     notes=coalesce(notes,'')||E'
M1.9 scenario-aware as-of cash-flow features generated.'
 WHERE run_id=v_run;
END $evidence$;

DO $n$ BEGIN RAISE NOTICE 'M1.9 Phase 6/6 — committed generation checkpoint'; END $n$;
COMMIT;

WITH r AS (
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), h AS (
 SELECT
  max(metric_value_text) FILTER(WHERE evidence_code='M1_9_SNAPSHOT_SET_HASH') AS snapshot_hash,
  max(metric_value_text) FILTER(WHERE evidence_code='M1_9_FEATURE_VALUE_SET_HASH') AS feature_value_hash,
  max(metric_value_text) FILTER(WHERE evidence_code='M1_9_COMBINED_SET_HASH') AS combined_hash
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
)
SELECT r.run_id,r.run_status,
 (SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=r.run_id) AS snapshot_rows,
 (SELECT count(*) FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=r.run_id) AS feature_value_rows,
 (SELECT count(*) FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=r.run_id AND value_status='AVAILABLE') AS available_feature_values,
 h.snapshot_hash,h.feature_value_hash,h.combined_hash,
 CASE WHEN r.run_status='M1_9_GENERATED'
       AND (SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=r.run_id)=1500
       AND (SELECT count(*) FROM msbf_m1.cashflow_feature_value WHERE module1_run_id=r.run_id)=54000
       AND h.combined_hash IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS generation_status
FROM r CROSS JOIN h;
