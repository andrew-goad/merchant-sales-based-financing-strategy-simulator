/* M1.10 final clean-build package revision v0.2R2; bounded temporary row-hash updates. */
/* ============================================================================
MSBF M1.10 Obligations, Liquidity & Residual Cash Flow — Generation
Version : v0.2R1
Purpose : Generate deterministic application-level obligation evidence once,
          calculate matched scenario capacity/residual-cash-flow evidence, and
          perform one canonical expected-versus-actual reconciliation.
Performance: No upstream blueprint regeneration. Accepted M1.9 snapshots and
             compact source/relationship inputs are materialized once. The
             largest business population is 1,500 scenario/application rows.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='15min';

CREATE OR REPLACE FUNCTION msbf_m1.m1_10_hash_jsonb(p_payload jsonb)
RETURNS text LANGUAGE sql IMMUTABLE STRICT AS $fn$
SELECT md5(p_payload::text);
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_10_actual_obligation(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text)
LANGUAGE sql STABLE AS $fn$
SELECT 'OBLIGATION|'||o.merchant_application_id||'|'||o.obligation_id||'|'||o.as_of_date,
       msbf_m1.m1_10_hash_jsonb(to_jsonb(o)-'row_hash'-'created_at')
FROM msbf_m1.application_obligation_snapshot o
WHERE o.created_by_run_id=p_run_id;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_10_actual_capacity(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text)
LANGUAGE sql STABLE AS $fn$
SELECT 'CAPACITY|'||c.scenario_id||'|'||c.merchant_application_id,
       msbf_m1.m1_10_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at')
FROM msbf_m1.application_liquidity_capacity_snapshot c
WHERE c.module1_run_id=p_run_id;
$fn$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_10_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $fn$
DECLARE
    v_status text; v_gate text; v_policy jsonb; v_scenarios integer;
    v_apps bigint; v_features bigint; v_sources bigint; v_obligations bigint;
    v_capacity bigint; v_errors bigint;
BEGIN
    SELECT run_status INTO STRICT v_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    IF v_status<>'M1_9_ACCEPTED' THEN
        RAISE EXCEPTION 'M1.10 requires run status M1_9_ACCEPTED; observed %.',v_status;
    END IF;

    SELECT result_status INTO v_gate
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=p_run_id AND gate_id='M1_9_ASOF_CASHFLOW_FEATURES'
    ORDER BY review_version DESC LIMIT 1;
    IF coalesce(v_gate,'<NULL>')<>'PASS' THEN
        RAISE EXCEPTION 'M1.9 acceptance gate must remain PASS; observed %.',v_gate;
    END IF;

    SELECT profile_payload INTO STRICT v_policy
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY'
      AND profile_version=1 AND status='APPROVED';
    IF NOT coalesce((v_policy->>'generation_enabled')::boolean,false)
       OR v_policy->>'methodology_version'<>'M1_10_METHOD_V1'
       OR v_policy->>'requested_burden_basis'<>'MAX_RATE_OR_HORIZON' THEN
        RAISE EXCEPTION 'M1.10 approved generation policy is missing, disabled, or inconsistent.';
    END IF;

    SELECT count(DISTINCT f.scenario_id) INTO v_scenarios
    FROM msbf_m1.application_cashflow_feature_snapshot f
    JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=f.scenario_id
    JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
    WHERE f.module1_run_id=p_run_id
      AND ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS'
      AND ss.scenario_set_version=1 AND ss.status='APPROVED'
      AND sr.status='APPROVED' AND sr.scenario_version=1
      AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY');
    IF v_scenarios<>2 THEN
        RAISE EXCEPTION 'M1.10 requires the two accepted M1.9 scenarios; observed %.',v_scenarios;
    END IF;

    SELECT count(*) INTO v_apps FROM msbf_m1.merchant_application WHERE created_by_run_id=p_run_id;
    SELECT count(*) INTO v_features FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=p_run_id;
    SELECT count(*) INTO v_sources FROM msbf_m1.source_snapshot WHERE module1_run_id=p_run_id AND source_code='OBLIGATIONS';
    SELECT count(*) INTO v_obligations FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=p_run_id;
    SELECT count(*) INTO v_capacity FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=p_run_id;
    IF v_apps<>750 OR v_features<>1500 OR v_sources<>750 THEN
        RAISE EXCEPTION 'M1.10 input cardinality mismatch: applications %, features %, obligation sources %.',v_apps,v_features,v_sources;
    END IF;
    IF v_obligations<>0 OR v_capacity<>0 THEN
        RAISE EXCEPTION 'M1.10 regeneration rejected: obligations %, capacity rows %.',v_obligations,v_capacity;
    END IF;

    SELECT count(*) INTO v_errors FROM msbf_ctl.profile_resolution_error
    WHERE run_id=p_run_id AND severity='BLOCKING';
    IF v_errors<>0 THEN RAISE EXCEPTION 'M1.10 cannot start with % blocking configuration errors.',v_errors; END IF;
END;
$fn$;

DO $n$ BEGIN RAISE NOTICE 'M1.10 Phase 1/5 — materialize accepted application, source, relationship and feature inputs'; END $n$;

CREATE TEMP TABLE _m1_10_ctx ON COMMIT DROP AS
SELECT r.run_id,r.population_id,r.as_of_date,pp.policy_profile_id,pp.profile_payload,
       (pp.profile_payload->>'max_obligations_per_application')::integer AS max_obligations,
       (pp.profile_payload->>'obligation_count_none_threshold')::numeric AS count_none_threshold,
       (pp.profile_payload->>'obligation_count_one_threshold')::numeric AS count_one_threshold,
       (pp.profile_payload->>'obligation_count_two_threshold')::numeric AS count_two_threshold,
       (pp.profile_payload->>'minimum_obligation_count_with_prior_advance')::integer AS prior_min_count,
       (pp.profile_payload->>'monthly_days')::integer AS monthly_days,
       (pp.profile_payload->>'liquidity_projection_days')::integer AS liquidity_projection_days,
       (pp.profile_payload->>'daily_sales_denominator_floor')::numeric AS sales_floor,
       (pp.profile_payload->>'coverage_tier_1_threshold')::numeric AS coverage_t1,
       (pp.profile_payload->>'coverage_tier_2_threshold')::numeric AS coverage_t2,
       (pp.profile_payload->>'coverage_tier_3_threshold')::numeric AS coverage_t3,
       (pp.profile_payload->>'burden_rate_tier_1_max')::numeric AS burden_t1,
       (pp.profile_payload->>'burden_rate_tier_2_max')::numeric AS burden_t2,
       (pp.profile_payload->>'burden_rate_tier_3_max')::numeric AS burden_t3,
       (pp.profile_payload->>'buffer_days_tier_1_min')::numeric AS buffer_t1,
       (pp.profile_payload->>'buffer_days_tier_2_min')::numeric AS buffer_t2,
       (pp.profile_payload->>'buffer_days_tier_3_min')::numeric AS buffer_t3,
       (pp.profile_payload->>'stacking_review_threshold')::integer AS stacking_review_threshold,
       (pp.profile_payload->>'concentration_review_threshold')::numeric AS concentration_review_threshold
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.policy_profile pp
  ON pp.profile_code='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY'
 AND pp.profile_version=1 AND pp.status='APPROVED'
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

SELECT msbf_m1.m1_10_assert_generation_ready(run_id) FROM _m1_10_ctx;

CREATE TEMP TABLE _m1_10_scenarios ON COMMIT DROP AS
SELECT DISTINCT f.scenario_id,sr.scenario_code
FROM msbf_m1.application_cashflow_feature_snapshot f
JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=f.scenario_id
JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
WHERE f.module1_run_id=(SELECT run_id FROM _m1_10_ctx)
  AND ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS'
  AND ss.scenario_set_version=1 AND ss.status='APPROVED'
  AND sr.status='APPROVED' AND sr.scenario_version=1
  AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY');
CREATE UNIQUE INDEX ON _m1_10_scenarios(scenario_id);

CREATE TEMP TABLE _m1_10_apps ON COMMIT DROP AS
SELECT
    a.created_by_run_id AS run_id,a.merchant_application_id,a.population_id,a.merchant_id,
    a.partner_channel_id,a.as_of_date,a.requested_funding_amount,a.requested_remittance_rate,
    a.requested_expected_payoff_days,a.requested_total_repayment_amount,
    m.merchant_size_tier,ia.industry_code,
    rs.relationship_stage,rs.prior_advance_count,rs.completed_advance_count,
    rs.prior_default_flag,rs.prior_payment_interruption_flag,
    rs.total_prior_funded_amount,rs.total_prior_repaid_amount,
    src.source_snapshot_id AS obligation_source_snapshot_id,
    src.availability_status AS obligation_availability_status,
    src.quality_status AS obligation_quality_status,
    src.data_confidence_score AS obligation_confidence_score,
    src.fallback_path_code AS obligation_source_fallback,
    vf.verification_disposition,vf.fraud_risk_tier,
    bf.avg_daily_eligible_sales_30d AS baseline_avg_daily_sales_30d,
    bf.average_available_balance_30d AS baseline_average_available_balance_30d
FROM msbf_m1.merchant_application a
JOIN msbf_m1.merchant_master m ON m.merchant_id=a.merchant_id
JOIN msbf_m1.merchant_industry_assignment ia
  ON ia.merchant_id=a.merchant_id AND ia.assignment_type='PRIMARY'
JOIN msbf_m1.merchant_relationship_snapshot rs
  ON rs.merchant_id=a.merchant_id AND rs.as_of_date=a.as_of_date
JOIN msbf_m1.source_snapshot src
  ON src.module1_run_id=a.created_by_run_id
 AND src.merchant_application_id=a.merchant_application_id
 AND src.source_code='OBLIGATIONS'
JOIN msbf_m1.application_verification_fraud_snapshot vf
  ON vf.module1_run_id=a.created_by_run_id
 AND vf.merchant_application_id=a.merchant_application_id
JOIN msbf_m1.application_cashflow_feature_snapshot bf
  ON bf.module1_run_id=a.created_by_run_id
 AND bf.merchant_application_id=a.merchant_application_id
JOIN _m1_10_scenarios bs
  ON bs.scenario_id=bf.scenario_id AND bs.scenario_code='BASELINE'
WHERE a.created_by_run_id=(SELECT run_id FROM _m1_10_ctx);
CREATE UNIQUE INDEX ON _m1_10_apps(merchant_application_id);
ANALYZE _m1_10_apps;

DO $n$ BEGIN RAISE NOTICE 'M1.10 Phase 2/5 — generate bounded atomic obligation evidence once'; END $n$;

CREATE TEMP TABLE _m1_10_obligation_profile ON COMMIT DROP AS
WITH u AS (
    SELECT a.*,
           msbf_ctl.deterministic_uniform(a.merchant_application_id,'M1_10:OBLIGATION_COUNT') AS u_count
    FROM _m1_10_apps a
), raw AS (
    SELECT u.*,
           CASE WHEN u_count<(SELECT count_none_threshold FROM _m1_10_ctx) THEN 0
                WHEN u_count<(SELECT count_one_threshold FROM _m1_10_ctx) THEN 1
                WHEN u_count<(SELECT count_two_threshold FROM _m1_10_ctx) THEN 2
                ELSE (SELECT max_obligations FROM _m1_10_ctx) END AS raw_obligation_count
    FROM u
)
SELECT raw.*,
       CASE WHEN obligation_availability_status='UNAVAILABLE' THEN 0
            ELSE least((SELECT max_obligations FROM _m1_10_ctx),
                       greatest(raw_obligation_count,
                                CASE WHEN prior_advance_count>0
                                     THEN (SELECT prior_min_count FROM _m1_10_ctx) ELSE 0 END))
       END AS obligation_count
FROM raw;
CREATE UNIQUE INDEX ON _m1_10_obligation_profile(merchant_application_id);

CREATE TEMP TABLE _m1_10_obligation_seed ON COMMIT DROP AS
SELECT p.*,g.obligation_ordinal,
       msbf_ctl.deterministic_uniform(p.merchant_application_id||'|'||g.obligation_ordinal,'M1_10:TYPE') AS u_type,
       msbf_ctl.deterministic_uniform(p.merchant_application_id||'|'||g.obligation_ordinal,'M1_10:BALANCE') AS u_balance,
       msbf_ctl.deterministic_uniform(p.merchant_application_id||'|'||g.obligation_ordinal,'M1_10:RATE') AS u_rate,
       msbf_ctl.deterministic_uniform(p.merchant_application_id||'|'||g.obligation_ordinal,'M1_10:SECURED') AS u_secured
FROM _m1_10_obligation_profile p
CROSS JOIN LATERAL generate_series(1,p.obligation_count) AS g(obligation_ordinal);
CREATE INDEX ON _m1_10_obligation_seed(merchant_application_id,obligation_ordinal);

CREATE TEMP TABLE _m1_10_obligation_terms ON COMMIT DROP AS
WITH typed AS (
    SELECT s.*,
      CASE WHEN obligation_ordinal=1 AND prior_advance_count>0 THEN 'SALES_BASED_ADVANCE'
           WHEN u_type<0.20 THEN 'SALES_BASED_ADVANCE'
           WHEN u_type<0.38 THEN 'TERM_LOAN'
           WHEN u_type<0.56 THEN 'LINE_OF_CREDIT'
           WHEN u_type<0.72 THEN 'EQUIPMENT_FINANCE'
           WHEN u_type<0.88 THEN 'BUSINESS_CREDIT_CARD'
           ELSE 'LEASE' END AS obligation_type_calc
    FROM _m1_10_obligation_seed s
)
SELECT t.*,
       CASE WHEN obligation_type_calc='SALES_BASED_ADVANCE' THEN 'SALES_LINKED' ELSE 'MONTHLY' END AS payment_frequency_calc,
       obligation_type_calc IN ('SALES_BASED_ADVANCE','LINE_OF_CREDIT','BUSINESS_CREDIT_CARD') AS short_term_calc,
       CASE WHEN obligation_type_calc IN ('EQUIPMENT_FINANCE','LEASE') THEN true
            WHEN obligation_type_calc='TERM_LOAN' THEN u_secured<0.65
            WHEN obligation_type_calc='LINE_OF_CREDIT' THEN u_secured<0.25
            ELSE false END AS secured_calc,
       ((SELECT profile_payload->'type_term_days'->>obligation_type_calc FROM _m1_10_ctx))::integer AS term_days,
       ((SELECT profile_payload->'type_balance_multiplier'->>obligation_type_calc FROM _m1_10_ctx))::numeric AS balance_multiplier,
       ((SELECT profile_payload->'type_finance_factor'->>obligation_type_calc FROM _m1_10_ctx))::numeric AS finance_factor
FROM typed t;

CREATE TEMP TABLE _m1_10_obligation_amounts ON COMMIT DROP AS
WITH b AS (
    SELECT t.*,
      round(greatest(500::numeric,least(250000::numeric,
          requested_funding_amount*balance_multiplier*(0.65+0.70*u_balance)
          +CASE WHEN obligation_ordinal=1 AND prior_advance_count>0
                THEN least(total_prior_funded_amount*0.05,10000::numeric) ELSE 0 END)),2) AS outstanding_calc,
      CASE WHEN obligation_type_calc='SALES_BASED_ADVANCE'
           THEN round(0.06+0.12*u_rate,6) ELSE NULL END AS remittance_rate_calc
    FROM _m1_10_obligation_terms t
)
SELECT b.*,
       CASE WHEN obligation_type_calc='SALES_BASED_ADVANCE'
            THEN round(greatest(coalesce(baseline_avg_daily_sales_30d,
                                       requested_total_repayment_amount/greatest(requested_expected_payoff_days,1)),1)
                       *remittance_rate_calc,2)
            ELSE round(outstanding_calc*finance_factor/term_days,2) END AS daily_payment_calc
FROM b;

CREATE TEMP TABLE _m1_10_obligation_expected (
    merchant_application_id text NOT NULL,obligation_id text NOT NULL,as_of_date date NOT NULL,
    obligation_type text NOT NULL,outstanding_balance numeric(18,2) NOT NULL,
    daily_payment_amount numeric(18,2) NOT NULL,monthly_payment_amount numeric(18,2) NOT NULL,
    remittance_rate numeric(9,6),lien_position smallint,short_term_financing_flag boolean NOT NULL,
    stacking_sequence smallint,source_snapshot_id bigint,created_by_run_id bigint NOT NULL,
    obligation_status text NOT NULL,payment_frequency text NOT NULL,maturity_date date,
    secured_flag boolean NOT NULL,data_confidence_score numeric(9,6) NOT NULL,
    obligation_quality_status text NOT NULL,obligation_reason_code text NOT NULL,
    row_hash text,created_at timestamptz NOT NULL
) ON COMMIT DROP;

INSERT INTO _m1_10_obligation_expected(
    merchant_application_id,obligation_id,as_of_date,obligation_type,outstanding_balance,
    daily_payment_amount,monthly_payment_amount,remittance_rate,lien_position,
    short_term_financing_flag,stacking_sequence,source_snapshot_id,created_by_run_id,
    obligation_status,payment_frequency,maturity_date,secured_flag,data_confidence_score,
    obligation_quality_status,obligation_reason_code,row_hash,created_at
)
SELECT merchant_application_id,
       'OBL-'||merchant_application_id||'-'||lpad(obligation_ordinal::text,2,'0'),
       as_of_date,obligation_type_calc,outstanding_calc::numeric(18,2),
       daily_payment_calc::numeric(18,2),round(daily_payment_calc*(SELECT monthly_days FROM _m1_10_ctx),2)::numeric(18,2),
       remittance_rate_calc::numeric(9,6),
       CASE WHEN secured_calc THEN obligation_ordinal::smallint ELSE NULL END,
       short_term_calc,
       CASE WHEN short_term_calc THEN obligation_ordinal::smallint ELSE NULL END,
       obligation_source_snapshot_id,run_id,'ACTIVE',payment_frequency_calc,
       (as_of_date+term_days)::date,secured_calc,obligation_confidence_score::numeric(9,6),
       obligation_quality_status,
       'SYNTHETIC_OBSERVED_'||obligation_type_calc,NULL,clock_timestamp()
FROM _m1_10_obligation_amounts;

UPDATE _m1_10_obligation_expected o
SET row_hash=msbf_m1.m1_10_hash_jsonb(to_jsonb(o)-'row_hash'-'created_at')
WHERE o.row_hash IS NULL;

INSERT INTO msbf_m1.application_obligation_snapshot(
    merchant_application_id,obligation_id,as_of_date,obligation_type,outstanding_balance,
    daily_payment_amount,monthly_payment_amount,remittance_rate,lien_position,
    short_term_financing_flag,stacking_sequence,source_snapshot_id,created_by_run_id,
    obligation_status,payment_frequency,maturity_date,secured_flag,data_confidence_score,
    obligation_quality_status,obligation_reason_code,row_hash,created_at
)
SELECT merchant_application_id,obligation_id,as_of_date,obligation_type,outstanding_balance,
       daily_payment_amount,monthly_payment_amount,remittance_rate,lien_position,
       short_term_financing_flag,stacking_sequence,source_snapshot_id,created_by_run_id,
       obligation_status,payment_frequency,maturity_date,secured_flag,data_confidence_score,
       obligation_quality_status,obligation_reason_code,row_hash,created_at
FROM _m1_10_obligation_expected;
ANALYZE msbf_m1.application_obligation_snapshot;

DO $n$ BEGIN RAISE NOTICE 'M1.10 Phase 3/5 — calculate matched scenario burden, residual cash flow and capacity'; END $n$;

CREATE TEMP TABLE _m1_10_scenario_obligation_agg ON COMMIT DROP AS
SELECT f.module1_run_id,f.scenario_id,f.merchant_application_id,
       count(o.obligation_id)::integer AS obligation_count,
       count(*) FILTER(WHERE o.short_term_financing_flag)::integer AS short_term_obligation_count,
       count(*) FILTER(WHERE o.secured_flag)::integer AS secured_obligation_count,
       count(*) FILTER(WHERE o.short_term_financing_flag AND o.stacking_sequence>1)::integer AS stacked_obligation_count,
       coalesce(max(o.stacking_sequence),0)::smallint AS max_stacking_sequence,
       coalesce(sum(o.outstanding_balance),0)::numeric(18,2) AS existing_outstanding_balance,
       coalesce(sum(o.daily_payment_amount) FILTER(WHERE o.remittance_rate IS NULL),0)::numeric(18,2) AS fixed_existing_daily_payment_amount,
       coalesce(sum(o.remittance_rate),0)::numeric(12,8) AS existing_sales_linked_remittance_rate,
       coalesce(sum(CASE WHEN o.remittance_rate IS NOT NULL
                         THEN round(coalesce(f.avg_daily_eligible_sales_30d,0)*o.remittance_rate,2)
                         ELSE o.daily_payment_amount END),0)::numeric(18,2) AS existing_daily_payment_amount,
       coalesce(max(CASE WHEN o.remittance_rate IS NOT NULL
                         THEN round(coalesce(f.avg_daily_eligible_sales_30d,0)*o.remittance_rate,2)
                         ELSE o.daily_payment_amount END),0)::numeric(18,2) AS largest_existing_daily_payment_amount
FROM msbf_m1.application_cashflow_feature_snapshot f
LEFT JOIN _m1_10_obligation_expected o
  ON o.merchant_application_id=f.merchant_application_id
WHERE f.module1_run_id=(SELECT run_id FROM _m1_10_ctx)
GROUP BY f.module1_run_id,f.scenario_id,f.merchant_application_id;
CREATE UNIQUE INDEX ON _m1_10_scenario_obligation_agg(module1_run_id,scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_10_capacity_independent ON COMMIT DROP AS
WITH base AS (
    SELECT f.module1_run_id,f.scenario_id,s.scenario_code,f.merchant_application_id,
           f.population_id,f.merchant_id,f.as_of_date,
           a.obligation_source_snapshot_id,a.obligation_availability_status,
           a.obligation_quality_status,a.obligation_confidence_score,
           f.feature_completeness_status,f.verification_disposition,
           a.requested_remittance_rate,a.requested_expected_payoff_days,
           a.requested_total_repayment_amount,a.industry_code,
           f.avg_daily_eligible_sales_30d,f.average_available_balance_30d,
           oa.obligation_count,oa.short_term_obligation_count,oa.secured_obligation_count,
           oa.stacked_obligation_count,oa.max_stacking_sequence,oa.existing_outstanding_balance,
           oa.fixed_existing_daily_payment_amount,oa.existing_sales_linked_remittance_rate,
           oa.existing_daily_payment_amount,oa.largest_existing_daily_payment_amount,
           ((SELECT profile_payload->'industry_operating_cash_margin'->>a.industry_code FROM _m1_10_ctx))::numeric AS operating_margin,
           CASE WHEN f.avg_daily_eligible_sales_30d IS NULL THEN NULL
                ELSE round(f.avg_daily_eligible_sales_30d*a.requested_remittance_rate,2) END AS requested_rate_based,
           round(a.requested_total_repayment_amount/greatest(a.requested_expected_payoff_days,1),2) AS requested_horizon_daily
    FROM msbf_m1.application_cashflow_feature_snapshot f
    JOIN _m1_10_scenarios s ON s.scenario_id=f.scenario_id
    JOIN _m1_10_apps a ON a.merchant_application_id=f.merchant_application_id
    JOIN _m1_10_scenario_obligation_agg oa
      ON oa.module1_run_id=f.module1_run_id AND oa.scenario_id=f.scenario_id
     AND oa.merchant_application_id=f.merchant_application_id
    WHERE f.module1_run_id=(SELECT run_id FROM _m1_10_ctx)
), burden AS (
    SELECT b.*,
           greatest(coalesce(requested_rate_based,0),requested_horizon_daily) AS requested_daily,
           round(existing_daily_payment_amount*(SELECT monthly_days FROM _m1_10_ctx),2) AS existing_monthly,
           round(greatest(coalesce(requested_rate_based,0),requested_horizon_daily)*(SELECT monthly_days FROM _m1_10_ctx),2) AS requested_monthly,
           round(existing_daily_payment_amount+greatest(coalesce(requested_rate_based,0),requested_horizon_daily),2) AS total_daily,
           CASE WHEN avg_daily_eligible_sales_30d IS NULL THEN NULL
                ELSE round(avg_daily_eligible_sales_30d*operating_margin,2) END AS operating_cash,
           CASE WHEN feature_completeness_status='BLOCKED'
                     OR obligation_availability_status='UNAVAILABLE'
                     OR avg_daily_eligible_sales_30d IS NULL THEN 'BLOCKED'
                WHEN feature_completeness_status='PARTIAL'
                     OR obligation_quality_status IN ('WARNING','FAIL','CONFLICT')
                     OR verification_disposition<>'CLEAR' THEN 'PARTIAL'
                ELSE 'COMPLETE' END AS evidence_status
    FROM base b
), cash AS (
    SELECT burden.*,
           round(total_daily*(SELECT monthly_days FROM _m1_10_ctx),2) AS total_monthly,
           CASE WHEN avg_daily_eligible_sales_30d IS NULL THEN NULL
                ELSE round(existing_daily_payment_amount/greatest(avg_daily_eligible_sales_30d,(SELECT sales_floor FROM _m1_10_ctx)),8) END AS existing_burden_rate,
           CASE WHEN avg_daily_eligible_sales_30d IS NULL THEN NULL
                ELSE round(total_daily/greatest(avg_daily_eligible_sales_30d,(SELECT sales_floor FROM _m1_10_ctx)),8) END AS total_burden_rate,
           CASE WHEN operating_cash IS NULL THEN NULL
                ELSE round(operating_cash/greatest(total_daily,1),8) END AS coverage_ratio,
           CASE WHEN operating_cash IS NULL THEN NULL ELSE round(operating_cash-total_daily,2) END AS residual_daily,
           average_available_balance_30d AS current_buffer,
           CASE WHEN existing_daily_payment_amount>0
                THEN round(largest_existing_daily_payment_amount/existing_daily_payment_amount,8)
                ELSE 0::numeric END AS concentration_rate,
           (short_term_obligation_count+1)::smallint AS stacking_depth_calc
    FROM burden
), liquidity AS (
    SELECT cash.*,
           CASE WHEN residual_daily IS NULL THEN NULL
                ELSE round(residual_daily*(SELECT monthly_days FROM _m1_10_ctx),2) END AS residual_monthly,
           CASE WHEN current_buffer IS NULL OR residual_daily IS NULL THEN NULL
                ELSE round(current_buffer+residual_daily*(SELECT liquidity_projection_days FROM _m1_10_ctx),2) END AS post_buffer
    FROM cash
), ratios AS (
    SELECT liquidity.*,
           CASE WHEN post_buffer IS NULL THEN NULL
                ELSE round(post_buffer/greatest(total_daily,1),4) END AS post_buffer_days_calc
    FROM liquidity
)
SELECT ratios.*,
       CASE WHEN evidence_status='BLOCKED' THEN 5
            WHEN coverage_ratio>=(SELECT coverage_t1 FROM _m1_10_ctx)
             AND total_burden_rate<=(SELECT burden_t1 FROM _m1_10_ctx)
             AND residual_daily>=0 AND post_buffer_days_calc>=(SELECT buffer_t1 FROM _m1_10_ctx)
             AND stacking_depth_calc<(SELECT stacking_review_threshold FROM _m1_10_ctx) THEN 1
            WHEN coverage_ratio>=(SELECT coverage_t2 FROM _m1_10_ctx)
             AND total_burden_rate<=(SELECT burden_t2 FROM _m1_10_ctx)
             AND residual_daily>=0 AND post_buffer_days_calc>=(SELECT buffer_t2 FROM _m1_10_ctx) THEN 2
            WHEN coverage_ratio>=(SELECT coverage_t3 FROM _m1_10_ctx)
             AND total_burden_rate<=(SELECT burden_t3 FROM _m1_10_ctx)
             AND post_buffer_days_calc>=(SELECT buffer_t3 FROM _m1_10_ctx) THEN 3
            ELSE 4 END::smallint AS independent_tier
FROM ratios;
CREATE UNIQUE INDEX ON _m1_10_capacity_independent(scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_10_baseline_tier ON COMMIT DROP AS
SELECT merchant_application_id,independent_tier AS baseline_independent_tier
FROM _m1_10_capacity_independent WHERE scenario_code='BASELINE';
CREATE UNIQUE INDEX ON _m1_10_baseline_tier(merchant_application_id);

CREATE TEMP TABLE _m1_10_capacity_expected (
    module1_run_id bigint NOT NULL,scenario_id bigint NOT NULL,merchant_application_id text NOT NULL,
    population_id text NOT NULL,merchant_id text NOT NULL,as_of_date date NOT NULL,
    obligation_source_snapshot_id bigint NOT NULL,obligation_availability_status text NOT NULL,
    obligation_quality_status text NOT NULL,obligation_confidence_score numeric(9,6) NOT NULL,
    feature_completeness_status text NOT NULL,verification_disposition text NOT NULL,
    obligation_count integer NOT NULL,short_term_obligation_count integer NOT NULL,
    secured_obligation_count integer NOT NULL,stacked_obligation_count integer NOT NULL,
    max_stacking_sequence smallint NOT NULL,existing_outstanding_balance numeric(18,2) NOT NULL,
    fixed_existing_daily_payment_amount numeric(18,2) NOT NULL,
    existing_sales_linked_remittance_rate numeric(12,8) NOT NULL,
    existing_daily_payment_amount numeric(18,2) NOT NULL,existing_monthly_payment_amount numeric(18,2) NOT NULL,
    largest_existing_daily_payment_amount numeric(18,2) NOT NULL,
    requested_rate_based_daily_remittance numeric(18,2),requested_horizon_required_daily_repayment numeric(18,2) NOT NULL,
    requested_daily_remittance_amount numeric(18,2) NOT NULL,requested_monthly_remittance_amount numeric(18,2) NOT NULL,
    total_daily_obligation_burden numeric(18,2) NOT NULL,total_monthly_obligation_burden numeric(18,2) NOT NULL,
    estimated_daily_operating_cash_flow numeric(18,2),existing_obligation_to_sales_rate numeric(12,8),
    total_obligation_to_sales_rate numeric(12,8),sales_linked_payment_coverage_ratio numeric(12,8),
    residual_daily_operating_cash_flow numeric(18,2),residual_monthly_operating_cash_flow numeric(18,2),
    current_liquidity_buffer_amount numeric(18,2),post_financing_liquidity_buffer_amount numeric(18,2),
    post_financing_buffer_days numeric(12,4),obligation_concentration_rate numeric(12,8) NOT NULL,
    stacking_depth smallint NOT NULL,independent_capacity_tier smallint NOT NULL,
    baseline_capacity_tier smallint NOT NULL,capacity_tier smallint NOT NULL,
    stress_capacity_worsening_flag boolean NOT NULL,capacity_evidence_status text NOT NULL,
    affordability_status text NOT NULL,manual_review_recommended_flag boolean NOT NULL,
    fallback_path_code text NOT NULL,primary_capacity_reason_code text NOT NULL,
    secondary_capacity_reason_codes text[] NOT NULL,row_hash text,created_by_run_id bigint NOT NULL,
    created_at timestamptz NOT NULL
) ON COMMIT DROP;

INSERT INTO _m1_10_capacity_expected(
    module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,as_of_date,
    obligation_source_snapshot_id,obligation_availability_status,obligation_quality_status,
    obligation_confidence_score,feature_completeness_status,verification_disposition,
    obligation_count,short_term_obligation_count,secured_obligation_count,stacked_obligation_count,
    max_stacking_sequence,existing_outstanding_balance,fixed_existing_daily_payment_amount,
    existing_sales_linked_remittance_rate,existing_daily_payment_amount,existing_monthly_payment_amount,
    largest_existing_daily_payment_amount,requested_rate_based_daily_remittance,
    requested_horizon_required_daily_repayment,requested_daily_remittance_amount,
    requested_monthly_remittance_amount,total_daily_obligation_burden,total_monthly_obligation_burden,
    estimated_daily_operating_cash_flow,existing_obligation_to_sales_rate,total_obligation_to_sales_rate,
    sales_linked_payment_coverage_ratio,residual_daily_operating_cash_flow,
    residual_monthly_operating_cash_flow,current_liquidity_buffer_amount,
    post_financing_liquidity_buffer_amount,post_financing_buffer_days,obligation_concentration_rate,
    stacking_depth,independent_capacity_tier,baseline_capacity_tier,capacity_tier,
    stress_capacity_worsening_flag,capacity_evidence_status,affordability_status,
    manual_review_recommended_flag,fallback_path_code,primary_capacity_reason_code,
    secondary_capacity_reason_codes,row_hash,created_by_run_id,created_at
)
SELECT i.module1_run_id,i.scenario_id,i.merchant_application_id,i.population_id,i.merchant_id,i.as_of_date,
       i.obligation_source_snapshot_id,i.obligation_availability_status,i.obligation_quality_status,
       i.obligation_confidence_score::numeric(9,6),i.feature_completeness_status,i.verification_disposition,
       i.obligation_count,i.short_term_obligation_count,i.secured_obligation_count,i.stacked_obligation_count,
       i.max_stacking_sequence,i.existing_outstanding_balance,i.fixed_existing_daily_payment_amount,
       i.existing_sales_linked_remittance_rate,i.existing_daily_payment_amount,i.existing_monthly,
       i.largest_existing_daily_payment_amount,i.requested_rate_based::numeric(18,2),
       i.requested_horizon_daily::numeric(18,2),i.requested_daily::numeric(18,2),i.requested_monthly::numeric(18,2),
       i.total_daily::numeric(18,2),i.total_monthly::numeric(18,2),i.operating_cash::numeric(18,2),
       i.existing_burden_rate::numeric(12,8),i.total_burden_rate::numeric(12,8),i.coverage_ratio::numeric(12,8),
       i.residual_daily::numeric(18,2),i.residual_monthly::numeric(18,2),i.current_buffer::numeric(18,2),
       i.post_buffer::numeric(18,2),i.post_buffer_days_calc::numeric(12,4),i.concentration_rate::numeric(12,8),
       i.stacking_depth_calc,i.independent_tier,b.baseline_independent_tier,
       CASE WHEN i.scenario_code='RECESSION_ENERGY'
              AND coalesce((SELECT (profile_payload->>'stress_capacity_tier_floor_to_baseline')::boolean FROM _m1_10_ctx),true)
            THEN greatest(i.independent_tier,b.baseline_independent_tier)
            ELSE i.independent_tier END::smallint AS capacity_tier,
       (i.scenario_code='RECESSION_ENERGY' AND greatest(i.independent_tier,b.baseline_independent_tier)>b.baseline_independent_tier),
       i.evidence_status,
       CASE (CASE WHEN i.scenario_code='RECESSION_ENERGY' THEN greatest(i.independent_tier,b.baseline_independent_tier) ELSE i.independent_tier END)
         WHEN 1 THEN 'AFFORDABLE' WHEN 2 THEN 'AFFORDABLE' WHEN 3 THEN 'MARGINAL'
         WHEN 4 THEN 'UNAFFORDABLE' ELSE 'INSUFFICIENT_EVIDENCE' END,
       ((CASE WHEN i.scenario_code='RECESSION_ENERGY' THEN greatest(i.independent_tier,b.baseline_independent_tier) ELSE i.independent_tier END)>=3
         OR i.evidence_status<>'COMPLETE'
         OR i.stacking_depth_calc>=(SELECT stacking_review_threshold FROM _m1_10_ctx)
         OR i.concentration_rate>=(SELECT concentration_review_threshold FROM _m1_10_ctx)
         OR i.verification_disposition<>'CLEAR'),
       CASE WHEN i.obligation_availability_status='UNAVAILABLE' THEN 'MANUAL_OBLIGATION_REVIEW'
            WHEN i.obligation_quality_status='CONFLICT' THEN 'SOURCE_CONFLICT_REVIEW'
            WHEN i.feature_completeness_status='BLOCKED' THEN 'INSUFFICIENT_CASHFLOW_EVIDENCE'
            WHEN i.obligation_quality_status IN ('WARNING','FAIL') THEN 'SOURCE_REFRESH'
            WHEN (CASE WHEN i.scenario_code='RECESSION_ENERGY' THEN greatest(i.independent_tier,b.baseline_independent_tier) ELSE i.independent_tier END)=4 THEN 'STRUCTURE_REVIEW'
            WHEN (CASE WHEN i.scenario_code='RECESSION_ENERGY' THEN greatest(i.independent_tier,b.baseline_independent_tier) ELSE i.independent_tier END)=3 THEN 'MANUAL_CAPACITY_REVIEW'
            ELSE 'NONE' END,
       CASE WHEN i.evidence_status='BLOCKED' THEN 'INSUFFICIENT_EVIDENCE'
            WHEN (CASE WHEN i.scenario_code='RECESSION_ENERGY' THEN greatest(i.independent_tier,b.baseline_independent_tier) ELSE i.independent_tier END)=4
                 AND coalesce(i.residual_daily,0)<0 THEN 'NEGATIVE_RESIDUAL_CASH_FLOW'
            WHEN (CASE WHEN i.scenario_code='RECESSION_ENERGY' THEN greatest(i.independent_tier,b.baseline_independent_tier) ELSE i.independent_tier END)=4
                 AND coalesce(i.coverage_ratio,0)<(SELECT coverage_t3 FROM _m1_10_ctx) THEN 'LOW_PAYMENT_COVERAGE'
            WHEN (CASE WHEN i.scenario_code='RECESSION_ENERGY' THEN greatest(i.independent_tier,b.baseline_independent_tier) ELSE i.independent_tier END)=4 THEN 'HIGH_TOTAL_BURDEN'
            WHEN (CASE WHEN i.scenario_code='RECESSION_ENERGY' THEN greatest(i.independent_tier,b.baseline_independent_tier) ELSE i.independent_tier END)=3 THEN 'MARGINAL_CAPACITY'
            WHEN i.stacking_depth_calc>=(SELECT stacking_review_threshold FROM _m1_10_ctx) THEN 'STACKING_REVIEW'
            ELSE 'CAPACITY_WITHIN_GOVERNED_RANGE' END,
       array_remove(ARRAY[
          CASE WHEN i.stacking_depth_calc>=(SELECT stacking_review_threshold FROM _m1_10_ctx) THEN 'STACKING_DEPTH' END,
          CASE WHEN i.concentration_rate>=(SELECT concentration_review_threshold FROM _m1_10_ctx) THEN 'OBLIGATION_CONCENTRATION' END,
          CASE WHEN coalesce(i.residual_daily,0)<0 THEN 'NEGATIVE_RESIDUAL_CASH_FLOW' END,
          CASE WHEN i.verification_disposition<>'CLEAR' THEN 'VERIFICATION_ROUTE_'||i.verification_disposition END,
          CASE WHEN i.obligation_quality_status<>'PASS' THEN 'OBLIGATION_QUALITY_'||i.obligation_quality_status END
       ]::text[],NULL),NULL,i.module1_run_id,clock_timestamp()
FROM _m1_10_capacity_independent i
JOIN _m1_10_baseline_tier b USING(merchant_application_id);

UPDATE _m1_10_capacity_expected c
SET row_hash=msbf_m1.m1_10_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at')
WHERE c.row_hash IS NULL;

INSERT INTO msbf_m1.application_liquidity_capacity_snapshot(
    module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,as_of_date,
    obligation_source_snapshot_id,obligation_availability_status,obligation_quality_status,
    obligation_confidence_score,feature_completeness_status,verification_disposition,
    obligation_count,short_term_obligation_count,secured_obligation_count,stacked_obligation_count,
    max_stacking_sequence,existing_outstanding_balance,fixed_existing_daily_payment_amount,
    existing_sales_linked_remittance_rate,existing_daily_payment_amount,existing_monthly_payment_amount,
    largest_existing_daily_payment_amount,requested_rate_based_daily_remittance,
    requested_horizon_required_daily_repayment,requested_daily_remittance_amount,
    requested_monthly_remittance_amount,total_daily_obligation_burden,total_monthly_obligation_burden,
    estimated_daily_operating_cash_flow,existing_obligation_to_sales_rate,total_obligation_to_sales_rate,
    sales_linked_payment_coverage_ratio,residual_daily_operating_cash_flow,
    residual_monthly_operating_cash_flow,current_liquidity_buffer_amount,
    post_financing_liquidity_buffer_amount,post_financing_buffer_days,obligation_concentration_rate,
    stacking_depth,independent_capacity_tier,baseline_capacity_tier,capacity_tier,
    stress_capacity_worsening_flag,capacity_evidence_status,affordability_status,
    manual_review_recommended_flag,fallback_path_code,primary_capacity_reason_code,
    secondary_capacity_reason_codes,row_hash,created_by_run_id,created_at
)
SELECT module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,as_of_date,
       obligation_source_snapshot_id,obligation_availability_status,obligation_quality_status,
       obligation_confidence_score,feature_completeness_status,verification_disposition,
       obligation_count,short_term_obligation_count,secured_obligation_count,stacked_obligation_count,
       max_stacking_sequence,existing_outstanding_balance,fixed_existing_daily_payment_amount,
       existing_sales_linked_remittance_rate,existing_daily_payment_amount,existing_monthly_payment_amount,
       largest_existing_daily_payment_amount,requested_rate_based_daily_remittance,
       requested_horizon_required_daily_repayment,requested_daily_remittance_amount,
       requested_monthly_remittance_amount,total_daily_obligation_burden,total_monthly_obligation_burden,
       estimated_daily_operating_cash_flow,existing_obligation_to_sales_rate,total_obligation_to_sales_rate,
       sales_linked_payment_coverage_ratio,residual_daily_operating_cash_flow,
       residual_monthly_operating_cash_flow,current_liquidity_buffer_amount,
       post_financing_liquidity_buffer_amount,post_financing_buffer_days,obligation_concentration_rate,
       stacking_depth,independent_capacity_tier,baseline_capacity_tier,capacity_tier,
       stress_capacity_worsening_flag,capacity_evidence_status,affordability_status,
       manual_review_recommended_flag,fallback_path_code,primary_capacity_reason_code,
       secondary_capacity_reason_codes,row_hash,created_by_run_id,created_at
FROM _m1_10_capacity_expected;
ANALYZE msbf_m1.application_liquidity_capacity_snapshot;

DO $n$ BEGIN RAISE NOTICE 'M1.10 Phase 4/5 — materialize canonical expected and actual snapshots once'; END $n$;

CREATE TEMP TABLE _m1_10_expected ON COMMIT DROP AS
SELECT 'OBLIGATION|'||merchant_application_id||'|'||obligation_id||'|'||as_of_date AS entity_key,row_hash
FROM _m1_10_obligation_expected
UNION ALL
SELECT 'CAPACITY|'||scenario_id||'|'||merchant_application_id,row_hash
FROM _m1_10_capacity_expected;
CREATE UNIQUE INDEX ON _m1_10_expected(entity_key);

CREATE TEMP TABLE _m1_10_actual ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_10_actual_obligation((SELECT run_id FROM _m1_10_ctx))
UNION ALL
SELECT * FROM msbf_m1.m1_10_actual_capacity((SELECT run_id FROM _m1_10_ctx));
CREATE UNIQUE INDEX ON _m1_10_actual(entity_key);

CREATE TEMP TABLE _m1_10_mismatch ON COMMIT DROP AS
SELECT coalesce(e.entity_key,a.entity_key) AS entity_key,e.row_hash AS expected_hash,a.row_hash AS actual_hash
FROM _m1_10_expected e FULL JOIN _m1_10_actual a USING(entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash;

CREATE TEMP TABLE _m1_10_hashes ON COMMIT DROP AS
SELECT
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
      FILTER(WHERE entity_key LIKE 'OBLIGATION|%')) AS obligation_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
      FILTER(WHERE entity_key LIKE 'CAPACITY|%')) AS capacity_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash
FROM _m1_10_expected;

DO $recon$
DECLARE v_expected bigint; v_actual bigint; v_mismatch bigint; v_capacity bigint;
BEGIN
  SELECT count(*) INTO v_expected FROM _m1_10_expected;
  SELECT count(*) INTO v_actual FROM _m1_10_actual;
  SELECT count(*) INTO v_mismatch FROM _m1_10_mismatch;
  SELECT count(*) INTO v_capacity FROM _m1_10_capacity_expected;
  IF v_capacity<>1500 OR v_expected<>v_actual OR v_mismatch<>0 THEN
    RAISE EXCEPTION 'M1.10 canonical reconciliation failed: expected %, actual %, capacity %, mismatches %.',
      v_expected,v_actual,v_capacity,v_mismatch;
  END IF;
END;
$recon$;

DO $n$ BEGIN RAISE NOTICE 'M1.10 Phase 5/5 — persist generation evidence and commit'; END $n$;

INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
    metric_value_text,unit_code,status,interpretation
)
SELECT (SELECT run_id FROM _m1_10_ctx),x.evidence_code,'PORTFOLIO',x.metric_name,
       x.metric_value_numeric,x.metric_value_text,x.unit_code,'PASS',x.interpretation
FROM (
  VALUES
  ('M1_10_GENERATION_SPEC','M1.10 generation specification',NULL::numeric,
   'M1_10_METHOD_V1|obligations once|2 matched scenarios|MAX_RATE_OR_HORIZON|stress tier floor enabled','TEXT',
   'Governed synthetic obligations and scenario-aware residual cash-flow capacity methodology.'),
  ('M1_10_OBLIGATION_ENTITY_COUNT','M1.10 obligation entities',(SELECT count(*)::numeric FROM _m1_10_obligation_expected),NULL,'COUNT','Atomic observed obligation rows.'),
  ('M1_10_CAPACITY_ENTITY_COUNT','M1.10 capacity entities',(SELECT count(*)::numeric FROM _m1_10_capacity_expected),NULL,'COUNT','Scenario/application capacity rows.'),
  ('M1_10_CANONICAL_ENTITY_COUNT','M1.10 canonical entities',(SELECT count(*)::numeric FROM _m1_10_expected),NULL,'COUNT','Combined obligation and capacity entities.'),
  ('M1_10_CANONICAL_MISMATCH_COUNT','M1.10 canonical mismatches',(SELECT count(*)::numeric FROM _m1_10_mismatch),NULL,'COUNT','Expected-versus-actual row-hash mismatches.'),
  ('M1_10_OBLIGATION_SET_HASH','M1.10 obligation set hash',NULL,(SELECT obligation_hash FROM _m1_10_hashes),'HASH','Atomic obligation canonical set hash.'),
  ('M1_10_CAPACITY_SET_HASH','M1.10 capacity set hash',NULL,(SELECT capacity_hash FROM _m1_10_hashes),'HASH','Scenario-aware capacity canonical set hash.'),
  ('M1_10_COMBINED_SET_HASH','M1.10 combined set hash',NULL,(SELECT combined_hash FROM _m1_10_hashes),'HASH','Combined M1.10 canonical set hash.'),
  ('M1_10_GENERATION_SUMMARY','M1.10 generation summary',NULL,
   format('obligations=%s|capacity=1500|canonical=%s|mismatches=0|hash=%s',
      (SELECT count(*) FROM _m1_10_obligation_expected),(SELECT count(*) FROM _m1_10_expected),
      (SELECT combined_hash FROM _m1_10_hashes)),'TEXT','Committed M1.10 generation checkpoint.')
) AS x(evidence_code,metric_name,metric_value_numeric,metric_value_text,unit_code,interpretation)
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,metric_value_numeric=EXCLUDED.metric_value_numeric,
    metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,
    status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry
SET run_status='M1_10_GENERATED',row_count=(SELECT count(*) FROM _m1_10_capacity_expected),
    notes=coalesce(notes,'')||E'\nM1.10 generated deterministic obligation and scenario-aware capacity evidence.'
WHERE run_id=(SELECT run_id FROM _m1_10_ctx);

COMMIT;

SELECT
    r.run_id,r.run_status,
    (SELECT count(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=r.run_id) AS obligation_rows,
    (SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=r.run_id) AS capacity_rows,
    (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=r.run_id) AS applications,
    (SELECT count(DISTINCT scenario_id) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=r.run_id) AS scenarios,
    (SELECT metric_value_numeric::bigint FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_10_CANONICAL_ENTITY_COUNT' AND segment_key='PORTFOLIO') AS canonical_entities,
    (SELECT metric_value_numeric::bigint FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_10_CANONICAL_MISMATCH_COUNT' AND segment_key='PORTFOLIO') AS row_level_mismatches,
    (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_10_OBLIGATION_SET_HASH' AND segment_key='PORTFOLIO') AS obligation_set_hash,
    (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_10_CAPACITY_SET_HASH' AND segment_key='PORTFOLIO') AS capacity_set_hash,
    (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_10_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS combined_set_hash,
    CASE WHEN r.run_status='M1_10_GENERATED'
       AND (SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=r.run_id)=1500
       AND (SELECT metric_value_numeric FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_10_CANONICAL_MISMATCH_COUNT' AND segment_key='PORTFOLIO')=0
      THEN 'PASS' ELSE 'FAIL' END AS generation_status
FROM msbf_ctl.run_registry r
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;
