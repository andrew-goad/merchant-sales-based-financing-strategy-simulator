/* ============================================================================
MSBF M1.13 Exposure, Recovery & Expected Loss Foundations — Generation
Version : v0.2R1
Purpose : Create a scenario-aware daily contractual-receivable exposure path,
          path-weighted EAD, recovery/LGD foundations, and comparative loss
          evidence from accepted M1.10 and M1.12 physical outputs.
Inputs  : Accepted M1.3 applications, M1.7 recovery-source quality, M1.10
          capacity evidence, M1.12 integrated-risk evidence, and frozen G1
          parameter snapshots.
Outputs : application_ead_path_value and
          application_exposure_recovery_loss_snapshot.
Boundary: Synthetic comparative loss foundations only. The synthetic merchant
          risk proxy is not calibrated PD; loss outputs are not CECL, reserve,
          capital, pricing, or final credit decisions.
Performance: Accepted histories are not rebuilt. Inputs are materialized once,
             indexed, and ANALYZED before bounded path expansion.
Recovery: After a pre-commit failure, ROLLBACK and run program 92B. After a
          successful commit with lost output, run read-only program 94A v0.2R1.
============================================================================ */

/* v0.2R1 correction
   PostgreSQL does not implement max(boolean). The two governed publication
   flags are now resolved with bool_or(boolean), which is semantically exact
   because preflight and generation guards require one typed row per parameter.
   No exposure, recovery, LGD, EAD, or comparative-loss formula changed. */

BEGIN;
SET LOCAL work_mem = '128MB';
SET LOCAL jit = off;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '20min';

/* ---------------------------------------------------------------------------
1. Durable helper functions and fail-closed guards
--------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_m1.m1_13_hash_jsonb(p_value jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT md5(p_value::text);
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_13_actual_path_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text, row_hash text)
LANGUAGE sql
STABLE
AS $$
    SELECT
        'PATH|' || p.scenario_id || '|' || p.merchant_application_id || '|' || p.path_day,
        msbf_m1.m1_13_hash_jsonb(to_jsonb(p) - 'path_hash' - 'created_at')
    FROM msbf_m1.application_ead_path_value p
    WHERE p.module1_run_id = p_run_id;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_13_actual_loss_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text, row_hash text)
LANGUAGE sql
STABLE
AS $$
    SELECT
        'LOSS|' || s.scenario_id || '|' || s.merchant_application_id,
        msbf_m1.m1_13_hash_jsonb(to_jsonb(s) - 'row_hash' - 'created_at')
    FROM msbf_m1.application_exposure_recovery_loss_snapshot s
    WHERE s.module1_run_id = p_run_id;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_13_assert_configuration(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_status text;
    v_payload jsonb;
    v_timing_sum numeric;
    v_timing_rows integer;
    v_shape_rows integer;
    v_industry_rows integer;
    v_ead_method text;
    v_lgd_floor numeric;
    v_lgd_cap numeric;
    v_scenario_count integer;
    v_baseline_count integer;
    v_stress_count integer;
BEGIN
    SELECT status, profile_payload
    INTO STRICT v_status, v_payload
    FROM msbf_ctl.policy_profile
    WHERE profile_code = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
      AND profile_version = 1;

    IF v_status <> 'APPROVED' THEN
        RAISE EXCEPTION 'M1.13 requires an APPROVED policy profile; observed %.', v_status;
    END IF;

    IF coalesce((v_payload ->> 'generation_enabled')::boolean, false) = false THEN
        RAISE EXCEPTION 'M1.13 generation is disabled by governed policy.';
    END IF;

    IF v_payload ->> 'methodology_version' <> 'M1_13_METHOD_V1' THEN
        RAISE EXCEPTION 'M1.13 methodology version is invalid: %.',
            v_payload ->> 'methodology_version';
    END IF;

    IF v_payload ->> 'exposure_basis_code' <> 'CONTRACTUAL_RECEIVABLE'
       OR v_payload ->> 'ead_method_code' <> 'WEIGHTED_DAILY_BALANCE'
       OR v_payload ->> 'default_timing_basis_code' <> 'EARLY_MIDDLE_LATE'
       OR v_payload ->> 'risk_proxy_basis_code' <> 'SYNTHETIC_MERCHANT_RISK_PROXY' THEN
        RAISE EXCEPTION 'M1.13 methodology basis is not the approved governed basis.';
    END IF;

    IF NOT coalesce((v_payload ->> 'stress_payment_cap_to_baseline')::boolean, false)
       OR NOT coalesce((v_payload ->> 'stress_ead_floor_to_baseline')::boolean, false)
       OR NOT coalesce((v_payload ->> 'stress_lgd_floor_to_baseline')::boolean, false)
       OR NOT coalesce((v_payload ->> 'stress_loss_floor_to_baseline')::boolean, false) THEN
        RAISE EXCEPTION 'M1.13 requires all governed adverse-scenario non-improvement controls.';
    END IF;

    SELECT
        count(*) FILTER (
            WHERE parameter_name = 'default_timing_weight'
              AND scope_key LIKE 'PATH_DAY_BUCKET:%'
        ),
        sum((resolved_value ->> 'value_numeric')::numeric) FILTER (
            WHERE parameter_name = 'default_timing_weight'
              AND scope_key LIKE 'PATH_DAY_BUCKET:%'
        ),
        count(*) FILTER (
            WHERE parameter_name = 'paydown_curve_shape'
              AND scope_key LIKE 'EXPECTED_PAYOFF_DAYS:%'
        ),
        count(*) FILTER (
            WHERE parameter_name = 'industry_lgd_baseline'
              AND scope_key LIKE 'INDUSTRY:%'
        ),
        max(resolved_value ->> 'value_text') FILTER (
            WHERE parameter_name = 'ead_method_code' AND scope_key = 'GLOBAL'
        ),
        max((resolved_value ->> 'value_numeric')::numeric) FILTER (
            WHERE parameter_name = 'lgd_floor' AND scope_key = 'GLOBAL'
        ),
        max((resolved_value ->> 'value_numeric')::numeric) FILTER (
            WHERE parameter_name = 'lgd_cap' AND scope_key = 'GLOBAL'
        )
    INTO
        v_timing_rows,
        v_timing_sum,
        v_shape_rows,
        v_industry_rows,
        v_ead_method,
        v_lgd_floor,
        v_lgd_cap
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id = p_run_id;

    IF v_timing_rows <> 3 OR abs(v_timing_sum - 1.0) > 0.000001 THEN
        RAISE EXCEPTION 'M1.13 default-timing weights must contain three rows and sum to 1.0; observed rows %, sum %.',
            v_timing_rows, v_timing_sum;
    END IF;

    IF v_shape_rows <> 3 OR v_industry_rows <> 8 THEN
        RAISE EXCEPTION 'M1.13 requires three paydown shapes and eight industry LGD rows; observed % and %.',
            v_shape_rows, v_industry_rows;
    END IF;

    IF v_ead_method <> 'WEIGHTED_DAILY_BALANCE' THEN
        RAISE EXCEPTION 'M1.13 frozen EAD method is invalid: %.', v_ead_method;
    END IF;

    IF v_lgd_floor IS NULL OR v_lgd_cap IS NULL
       OR v_lgd_floor < 0 OR v_lgd_cap > 1 OR v_lgd_floor >= v_lgd_cap THEN
        RAISE EXCEPTION 'M1.13 LGD floor/cap configuration is invalid: floor %, cap %.',
            v_lgd_floor, v_lgd_cap;
    END IF;

    SELECT
        count(DISTINCT r.scenario_id),
        count(DISTINCT r.scenario_id) FILTER (WHERE sr.scenario_code = 'BASELINE'),
        count(DISTINCT r.scenario_id) FILTER (WHERE sr.scenario_code = 'RECESSION_ENERGY')
    INTO v_scenario_count, v_baseline_count, v_stress_count
    FROM msbf_m1.application_integrated_risk_proxy_snapshot r
    JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id = r.scenario_id
    JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id = sr.scenario_set_id
    WHERE r.module1_run_id = p_run_id
      AND ss.scenario_set_code = 'M1_V0_2_BASELINE_AND_STRESS'
      AND ss.scenario_set_version = 1
      AND ss.status = 'APPROVED'
      AND sr.status = 'APPROVED'
      AND sr.scenario_version = 1
      AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY');

    IF v_scenario_count <> 2 OR v_baseline_count <> 1 OR v_stress_count <> 1 THEN
        RAISE EXCEPTION 'M1.13 requires exactly one accepted BASELINE and one RECESSION_ENERGY scenario; observed %, %, %.',
            v_scenario_count, v_baseline_count, v_stress_count;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_13_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_status text;
    v_risk_rows bigint;
    v_capacity_rows bigint;
    v_applications bigint;
    v_targets bigint;
    v_downstream bigint;
    v_blocking bigint;
BEGIN
    PERFORM msbf_m1.m1_13_assert_configuration(p_run_id);

    SELECT run_status
    INTO STRICT v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    IF v_run_status <> 'M1_12_ACCEPTED' THEN
        RAISE EXCEPTION 'M1.13 requires M1_12_ACCEPTED; observed %.', v_run_status;
    END IF;

    SELECT count(*), count(DISTINCT merchant_application_id)
    INTO v_risk_rows, v_applications
    FROM msbf_m1.application_integrated_risk_proxy_snapshot
    WHERE module1_run_id = p_run_id;

    SELECT count(*)
    INTO v_capacity_rows
    FROM msbf_m1.application_liquidity_capacity_snapshot
    WHERE module1_run_id = p_run_id;

    SELECT
        (SELECT count(*) FROM msbf_m1.application_ead_path_value
         WHERE module1_run_id = p_run_id)
      + (SELECT count(*) FROM msbf_m1.application_exposure_recovery_loss_snapshot
         WHERE module1_run_id = p_run_id)
    INTO v_targets;

    SELECT
        (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot
         WHERE module1_run_id = p_run_id)
      + (SELECT count(*) FROM msbf_m1.risk_component_detail
         WHERE module1_run_id = p_run_id)
      + (SELECT count(*) FROM msbf_m1.ead_path_snapshot
         WHERE module1_run_id = p_run_id)
      + (SELECT count(*) FROM msbf_m1.module1_latest
         WHERE module1_run_id = p_run_id)
      + (SELECT count(*) FROM msbf_m1.module1_archive
         WHERE module1_run_id = p_run_id)
    INTO v_downstream;

    SELECT count(*)
    INTO v_blocking
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id = p_run_id
      AND severity = 'BLOCKING';

    IF v_risk_rows <> 1500 OR v_capacity_rows <> 1500 OR v_applications <> 750 THEN
        RAISE EXCEPTION 'M1.13 input cardinality mismatch: risk %, capacity %, applications %.',
            v_risk_rows, v_capacity_rows, v_applications;
    END IF;

    IF v_targets <> 0 THEN
        RAISE EXCEPTION 'M1.13 generation rejected because % target rows already exist.', v_targets;
    END IF;

    IF v_downstream <> 0 THEN
        RAISE EXCEPTION 'M1.13 generation rejected because % downstream risk/loss/contract rows already exist.',
            v_downstream;
    END IF;

    IF v_blocking <> 0 THEN
        RAISE EXCEPTION 'M1.13 generation rejected because % blocking configuration errors exist.',
            v_blocking;
    END IF;
END;
$$;

/* ---------------------------------------------------------------------------
2. Session-scoped generation workspace
--------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m1_13_context;
DROP TABLE IF EXISTS _m1_13_policy;
DROP TABLE IF EXISTS _m1_13_global_params;
DROP TABLE IF EXISTS _m1_13_timing_params;
DROP TABLE IF EXISTS _m1_13_paydown_params;
DROP TABLE IF EXISTS _m1_13_industry_lgd;
DROP TABLE IF EXISTS _m1_13_collateral;
DROP TABLE IF EXISTS _m1_13_guarantee;
DROP TABLE IF EXISTS _m1_13_input;
DROP TABLE IF EXISTS _m1_13_path_expected;
DROP TABLE IF EXISTS _m1_13_path_aggregate;
DROP TABLE IF EXISTS _m1_13_loss_independent;
DROP TABLE IF EXISTS _m1_13_loss_expected;
DROP TABLE IF EXISTS _m1_13_expected_canonical;
DROP TABLE IF EXISTS _m1_13_actual_canonical;
DROP TABLE IF EXISTS _m1_13_mismatch;
DROP TABLE IF EXISTS _m1_13_hashes;
DROP TABLE IF EXISTS _m1_13_generation_result;

CREATE TEMP TABLE _m1_13_context
ON COMMIT DROP AS
SELECT
    r.run_id,
    r.population_id,
    r.as_of_date,
    r.parameter_snapshot_hash,
    r.profile_snapshot_hash,
    r.source_snapshot_hash
FROM msbf_ctl.run_registry r
WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND r.run_version = 1;

DO $generation_guard$
BEGIN
    PERFORM msbf_m1.m1_13_assert_generation_ready(
        (SELECT run_id FROM _m1_13_context)
    );
END;
$generation_guard$;

CREATE TEMP TABLE _m1_13_policy
ON COMMIT DROP AS
SELECT profile_payload
FROM msbf_ctl.policy_profile
WHERE profile_code = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
  AND profile_version = 1
  AND status = 'APPROVED';

CREATE TEMP TABLE _m1_13_global_params
ON COMMIT DROP AS
SELECT
    max(resolved_value ->> 'value_text') FILTER (
        WHERE parameter_name = 'ead_method_code' AND scope_key = 'GLOBAL'
    ) AS ead_method_code,
    max((resolved_value ->> 'value_numeric')::numeric) FILTER (
        WHERE parameter_name = 'collateral_availability_lgd_haircut' AND scope_key = 'GLOBAL'
    ) AS collateral_haircut,
    max((resolved_value ->> 'value_numeric')::numeric) FILTER (
        WHERE parameter_name = 'guarantee_availability_lgd_haircut' AND scope_key = 'GLOBAL'
    ) AS guarantee_haircut,
    max((resolved_value ->> 'value_numeric')::numeric) FILTER (
        WHERE parameter_name = 'lgd_floor' AND scope_key = 'GLOBAL'
    ) AS lgd_floor,
    max((resolved_value ->> 'value_numeric')::numeric) FILTER (
        WHERE parameter_name = 'lgd_cap' AND scope_key = 'GLOBAL'
    ) AS lgd_cap,
    max((resolved_value ->> 'value_numeric')::numeric) FILTER (
        WHERE parameter_name = 'expected_loss_tolerance_amount' AND scope_key = 'GLOBAL'
    ) AS loss_tolerance,
    max((resolved_value ->> 'value_numeric')::numeric) FILTER (
        WHERE parameter_name = 'ead_weight_tolerance' AND scope_key = 'GLOBAL'
    ) AS ead_weight_tolerance,
    bool_or((resolved_value ->> 'value_boolean')::boolean) FILTER (
        WHERE parameter_name = 'simple_el_publish_flag' AND scope_key = 'GLOBAL'
    ) AS simple_el_publish_flag,
    bool_or((resolved_value ->> 'value_boolean')::boolean) FILTER (
        WHERE parameter_name = 'schedule_adjusted_el_publish_flag' AND scope_key = 'GLOBAL'
    ) AS schedule_adjusted_el_publish_flag
FROM msbf_ctl.run_parameter_snapshot
WHERE run_id = (SELECT run_id FROM _m1_13_context);

CREATE TEMP TABLE _m1_13_timing_params
ON COMMIT DROP AS
SELECT
    max((resolved_value ->> 'value_numeric')::numeric)
        FILTER (WHERE scope_key = 'PATH_DAY_BUCKET:EARLY') AS early_weight,
    max((resolved_value ->> 'value_numeric')::numeric)
        FILTER (WHERE scope_key = 'PATH_DAY_BUCKET:MIDDLE') AS middle_weight,
    max((resolved_value ->> 'value_numeric')::numeric)
        FILTER (WHERE scope_key = 'PATH_DAY_BUCKET:LATE') AS late_weight
FROM msbf_ctl.run_parameter_snapshot
WHERE run_id = (SELECT run_id FROM _m1_13_context)
  AND parameter_name = 'default_timing_weight';

CREATE TEMP TABLE _m1_13_paydown_params
ON COMMIT DROP AS
SELECT
    split_part(scope_key, ':', 2)::smallint AS expected_payoff_days,
    (resolved_value ->> 'value_numeric')::numeric(12,8) AS paydown_curve_shape
FROM msbf_ctl.run_parameter_snapshot
WHERE run_id = (SELECT run_id FROM _m1_13_context)
  AND parameter_name = 'paydown_curve_shape'
  AND scope_key LIKE 'EXPECTED_PAYOFF_DAYS:%';
CREATE UNIQUE INDEX ON _m1_13_paydown_params(expected_payoff_days);

CREATE TEMP TABLE _m1_13_industry_lgd
ON COMMIT DROP AS
SELECT
    split_part(scope_key, ':', 2) AS industry_code,
    (resolved_value ->> 'value_numeric')::numeric(12,8) AS industry_lgd_baseline_rate
FROM msbf_ctl.run_parameter_snapshot
WHERE run_id = (SELECT run_id FROM _m1_13_context)
  AND parameter_name = 'industry_lgd_baseline'
  AND scope_key LIKE 'INDUSTRY:%';
CREATE UNIQUE INDEX ON _m1_13_industry_lgd(industry_code);

DO $notice$
BEGIN
    RAISE NOTICE 'M1.13 Phase 1/6 — materialize accepted M1.10/M1.12 inputs and recovery evidence once';
END;
$notice$;

CREATE TEMP TABLE _m1_13_collateral
ON COMMIT DROP AS
SELECT
    merchant_application_id,
    sum(available_value)::numeric(18,2) AS collateral_available_value,
    bool_or(ownership_verified_flag) AS ownership_verified_flag
FROM msbf_m1.collateral_availability_snapshot
WHERE created_by_run_id = (SELECT run_id FROM _m1_13_context)
GROUP BY merchant_application_id;
CREATE UNIQUE INDEX ON _m1_13_collateral(merchant_application_id);

CREATE TEMP TABLE _m1_13_guarantee
ON COMMIT DROP AS
SELECT
    merchant_application_id,
    (
        sum(coalesce(guarantee_capacity_amount, 0))
            FILTER (WHERE guarantee_available_flag)
    )::numeric(18,2) AS guarantee_capacity_amount,
    bool_or(guarantee_available_flag) AS guarantee_available_flag
FROM msbf_m1.guarantee_availability_snapshot
WHERE created_by_run_id = (SELECT run_id FROM _m1_13_context)
GROUP BY merchant_application_id;
CREATE UNIQUE INDEX ON _m1_13_guarantee(merchant_application_id);

CREATE TEMP TABLE _m1_13_input
ON COMMIT DROP AS
SELECT
    r.module1_run_id,
    r.scenario_id,
    sr.scenario_code,
    r.merchant_application_id,
    r.population_id,
    r.merchant_id,
    r.as_of_date,
    r.industry_code,
    r.row_hash AS integrated_risk_snapshot_hash,
    c.row_hash AS liquidity_capacity_snapshot_hash,
    a.request_hash AS application_request_hash,
    r.integrated_risk_evidence_status,
    r.synthetic_merchant_risk_proxy,
    r.integrated_risk_tier,
    r.hard_stop_recommended_flag,
    r.manual_review_recommended_flag AS risk_manual_review_flag,
    c.manual_review_recommended_flag AS capacity_manual_review_flag,
    a.requested_funding_amount,
    a.requested_total_repayment_amount,
    a.requested_finance_charge_amount,
    a.requested_expected_payoff_days,
    c.requested_daily_remittance_amount AS scenario_expected_daily_remittance,
    max(c.requested_daily_remittance_amount) FILTER (
        WHERE sr.scenario_code = 'BASELINE'
    ) OVER (PARTITION BY r.merchant_application_id) AS baseline_expected_daily_remittance,
    CASE
        WHEN sr.scenario_code = 'RECESSION_ENERGY' THEN least(
            c.requested_daily_remittance_amount,
            max(c.requested_daily_remittance_amount) FILTER (
                WHERE sr.scenario_code = 'BASELINE'
            ) OVER (PARTITION BY r.merchant_application_id)
        )
        ELSE c.requested_daily_remittance_amount
    END::numeric(18,2) AS governed_path_daily_payment,
    pp.paydown_curve_shape,
    il.industry_lgd_baseline_rate,
    coalesce(col.collateral_available_value, 0)::numeric(18,2) AS collateral_available_value,
    coalesce(gua.guarantee_capacity_amount, 0)::numeric(18,2) AS guarantee_capacity_amount,
    ss.availability_status AS collateral_source_availability_status,
    ss.quality_status AS collateral_source_quality_status,
    pol.profile_payload,
    gp.collateral_haircut,
    gp.guarantee_haircut,
    gp.lgd_floor,
    gp.lgd_cap,
    gp.loss_tolerance,
    gp.ead_weight_tolerance,
    gp.simple_el_publish_flag,
    gp.schedule_adjusted_el_publish_flag
FROM msbf_m1.application_integrated_risk_proxy_snapshot r
JOIN msbf_m1.application_liquidity_capacity_snapshot c
  ON c.module1_run_id = r.module1_run_id
 AND c.scenario_id = r.scenario_id
 AND c.merchant_application_id = r.merchant_application_id
JOIN msbf_m1.merchant_application a
  ON a.merchant_application_id = r.merchant_application_id
JOIN msbf_ctl.scenario_registry sr
  ON sr.scenario_id = r.scenario_id
JOIN msbf_ctl.scenario_set sset
  ON sset.scenario_set_id = sr.scenario_set_id
JOIN _m1_13_paydown_params pp
  ON pp.expected_payoff_days = a.requested_expected_payoff_days
JOIN _m1_13_industry_lgd il
  ON il.industry_code = r.industry_code
JOIN msbf_m1.source_snapshot ss
  ON ss.module1_run_id = r.module1_run_id
 AND ss.merchant_application_id = r.merchant_application_id
 AND ss.source_code = 'COLLATERAL_AVAILABILITY'
LEFT JOIN _m1_13_collateral col
  ON col.merchant_application_id = r.merchant_application_id
LEFT JOIN _m1_13_guarantee gua
  ON gua.merchant_application_id = r.merchant_application_id
CROSS JOIN _m1_13_policy pol
CROSS JOIN _m1_13_global_params gp
WHERE r.module1_run_id = (SELECT run_id FROM _m1_13_context)
  AND sset.scenario_set_code = 'M1_V0_2_BASELINE_AND_STRESS'
  AND sset.scenario_set_version = 1
  AND sset.status = 'APPROVED'
  AND sr.status = 'APPROVED'
  AND sr.scenario_version = 1
  AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY');

CREATE UNIQUE INDEX ON _m1_13_input(scenario_id, merchant_application_id);
CREATE INDEX ON _m1_13_input(merchant_application_id, scenario_code);
ANALYZE _m1_13_input;

/* ---------------------------------------------------------------------------
3. Build the bounded daily EAD path once
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.13 Phase 2/6 — generate the bounded daily contractual-receivable exposure path';
END;
$notice$;

CREATE TEMP TABLE _m1_13_path_expected
(LIKE msbf_m1.application_ead_path_value INCLUDING DEFAULTS)
ON COMMIT DROP;

WITH expanded AS (
    SELECT
        i.*,
        gs.path_day::smallint AS path_day,
        floor(i.requested_expected_payoff_days / 3.0)::integer AS first_cut,
        floor(2.0 * i.requested_expected_payoff_days / 3.0)::integer AS second_cut
    FROM _m1_13_input i
    CROSS JOIN LATERAL generate_series(
        0,
        i.requested_expected_payoff_days::integer
    ) AS gs(path_day)
),
bucketed AS (
    SELECT
        e.*,
        CASE
            WHEN e.path_day <= e.first_cut THEN 'EARLY'
            WHEN e.path_day <= e.second_cut THEN 'MIDDLE'
            ELSE 'LATE'
        END AS path_bucket,
        CASE
            WHEN e.path_day <= e.first_cut THEN e.first_cut + 1
            WHEN e.path_day <= e.second_cut THEN e.second_cut - e.first_cut
            ELSE e.requested_expected_payoff_days - e.second_cut
        END::smallint AS path_bucket_day_count
    FROM expanded e
),
ratios AS (
    SELECT
        b.*,
        greatest(
            1.0 - (
                b.governed_path_daily_payment
                * greatest(b.path_day - 1, 0)
            ) / b.requested_total_repayment_amount,
            0.0
        )::numeric AS beginning_ratio,
        CASE
            WHEN b.path_day >= b.requested_expected_payoff_days THEN 0.0::numeric
            ELSE greatest(
                1.0 - (
                    b.governed_path_daily_payment * b.path_day
                ) / b.requested_total_repayment_amount,
                0.0
            )::numeric
        END AS ending_ratio
    FROM bucketed b
),
exposure AS (
    SELECT
        r.*,
        round(
            r.requested_total_repayment_amount
            * power(r.beginning_ratio, 1.0 / r.paydown_curve_shape),
            2
        )::numeric(18,2) AS beginning_exposure_amount,
        round(
            r.requested_total_repayment_amount
            * power(r.ending_ratio, 1.0 / r.paydown_curve_shape),
            2
        )::numeric(18,2) AS ending_exposure_amount
    FROM ratios r
)
INSERT INTO _m1_13_path_expected (
    module1_run_id,
    scenario_id,
    merchant_application_id,
    path_day,
    path_bucket,
    path_bucket_day_count,
    paydown_curve_shape,
    beginning_exposure_amount,
    scheduled_remittance_amount,
    expected_receivable_reduction_amount,
    ending_exposure_amount,
    default_timing_weight,
    weighted_ead_amount,
    exposure_basis_code,
    payment_basis_code,
    path_hash,
    created_by_run_id
)
SELECT
    e.module1_run_id,
    e.scenario_id,
    e.merchant_application_id,
    e.path_day,
    e.path_bucket,
    e.path_bucket_day_count,
    e.paydown_curve_shape,
    e.beginning_exposure_amount,
    CASE
        WHEN e.path_day = 0 THEN 0
        ELSE least(e.governed_path_daily_payment, e.beginning_exposure_amount)
    END::numeric(18,2) AS scheduled_remittance_amount,
    greatest(
        e.beginning_exposure_amount - e.ending_exposure_amount,
        0
    )::numeric(18,2) AS expected_receivable_reduction_amount,
    e.ending_exposure_amount,
    round(
        CASE e.path_bucket
            WHEN 'EARLY' THEN tp.early_weight
            WHEN 'MIDDLE' THEN tp.middle_weight
            ELSE tp.late_weight
        END / e.path_bucket_day_count,
        10
    )::numeric(14,10) AS default_timing_weight,
    round(
        e.ending_exposure_amount
        * round(
            CASE e.path_bucket
                WHEN 'EARLY' THEN tp.early_weight
                WHEN 'MIDDLE' THEN tp.middle_weight
                ELSE tp.late_weight
            END / e.path_bucket_day_count,
            10
        ),
        2
    )::numeric(18,2) AS weighted_ead_amount,
    'CONTRACTUAL_RECEIVABLE',
    'MIN_SCENARIO_BASELINE_DAILY_REMITTANCE',
    ''::text,
    e.module1_run_id
FROM exposure e
CROSS JOIN _m1_13_timing_params tp;

UPDATE _m1_13_path_expected p
SET path_hash = msbf_m1.m1_13_hash_jsonb(
    to_jsonb(p) - 'path_hash' - 'created_at'
)
WHERE p.path_hash = '';

CREATE UNIQUE INDEX ON _m1_13_path_expected(
    scenario_id, merchant_application_id, path_day
);
ANALYZE _m1_13_path_expected;

CREATE TEMP TABLE _m1_13_path_aggregate
ON COMMIT DROP AS
SELECT
    module1_run_id,
    scenario_id,
    merchant_application_id,
    count(*) AS path_rows,
    round(sum(default_timing_weight), 10)::numeric(14,10) AS timing_weight_sum,
    round(sum(weighted_ead_amount), 2)::numeric(18,2) AS path_weighted_ead_amount,
    min(ending_exposure_amount) AS minimum_ending_exposure,
    max(ending_exposure_amount) FILTER (WHERE path_day = 0) AS day_zero_exposure,
    max(path_day) AS maximum_path_day
FROM _m1_13_path_expected
GROUP BY module1_run_id, scenario_id, merchant_application_id;
CREATE UNIQUE INDEX ON _m1_13_path_aggregate(scenario_id, merchant_application_id);
ANALYZE _m1_13_path_aggregate;

/* ---------------------------------------------------------------------------
4. Build recovery/LGD and comparative loss evidence
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.13 Phase 3/6 — calculate recovery/LGD foundations and comparative loss measures';
END;
$notice$;

CREATE TEMP TABLE _m1_13_loss_independent
ON COMMIT DROP AS
WITH base AS (
    SELECT
        i.*,
        pa.path_rows,
        pa.timing_weight_sum,
        pa.path_weighted_ead_amount,
        least(
            (i.profile_payload ->> 'recovery_credit_cap_rate')::numeric,
            CASE WHEN i.collateral_available_value > 0 THEN i.collateral_haircut ELSE 0 END
          + CASE WHEN i.guarantee_capacity_amount > 0 THEN i.guarantee_haircut ELSE 0 END
        )::numeric(12,8) AS total_recovery_credit_rate,
        CASE
            WHEN i.scenario_code = 'RECESSION_ENERGY' THEN round(
                (i.profile_payload ->> 'stress_lgd_addon_base_rate')::numeric
                * coalesce(
                    (i.profile_payload -> 'industry_stress_multiplier' ->> i.industry_code)::numeric,
                    0
                ),
                8
            )
            ELSE 0
        END::numeric(12,8) AS scenario_lgd_addon_rate
    FROM _m1_13_input i
    JOIN _m1_13_path_aggregate pa
      ON pa.scenario_id = i.scenario_id
     AND pa.merchant_application_id = i.merchant_application_id
),
recovery AS (
    SELECT
        b.*,
        CASE
            WHEN b.collateral_source_quality_status IN ('FAIL','CONFLICT') THEN 'CONFLICT'
            WHEN b.collateral_available_value > 0 OR b.guarantee_capacity_amount > 0 THEN 'SUPPORTED'
            ELSE 'PARAMETER_ONLY'
        END AS recovery_evidence_status,
        CASE
            WHEN b.collateral_source_quality_status IN ('FAIL','CONFLICT') THEN 'SOURCE_CONFLICT'
            WHEN b.collateral_available_value > 0 AND b.guarantee_capacity_amount > 0
                THEN 'COLLATERAL_AND_GUARANTEE_SUPPORTED'
            WHEN b.collateral_available_value > 0 THEN 'COLLATERAL_SUPPORTED'
            WHEN b.guarantee_capacity_amount > 0 THEN 'GUARANTEE_SUPPORTED'
            ELSE 'INDUSTRY_PARAMETER_ONLY'
        END AS recovery_basis_code,
        CASE WHEN b.collateral_available_value > 0 THEN b.collateral_haircut ELSE 0 END::numeric(12,8)
            AS collateral_recovery_credit_rate,
        CASE WHEN b.guarantee_capacity_amount > 0 THEN b.guarantee_haircut ELSE 0 END::numeric(12,8)
            AS guarantee_recovery_credit_rate,
        greatest(
            b.lgd_floor,
            least(
                b.lgd_cap,
                b.industry_lgd_baseline_rate
                + b.scenario_lgd_addon_rate
                - b.total_recovery_credit_rate
            )
        )::numeric(12,8) AS independent_lgd_input_rate
    FROM base b
)
SELECT
    r.*,
    max(r.independent_lgd_input_rate) FILTER (
        WHERE r.scenario_code = 'BASELINE'
    ) OVER (PARTITION BY r.merchant_application_id) AS baseline_independent_lgd_rate,
    max(r.path_weighted_ead_amount) FILTER (
        WHERE r.scenario_code = 'BASELINE'
    ) OVER (PARTITION BY r.merchant_application_id) AS baseline_path_weighted_ead_amount
FROM recovery r;

CREATE UNIQUE INDEX ON _m1_13_loss_independent(scenario_id, merchant_application_id);
ANALYZE _m1_13_loss_independent;

CREATE TEMP TABLE _m1_13_loss_expected
(LIKE msbf_m1.application_exposure_recovery_loss_snapshot INCLUDING DEFAULTS)
ON COMMIT DROP;

WITH finalized AS (
    SELECT
        x.*,
        CASE
            WHEN x.scenario_code = 'RECESSION_ENERGY' THEN greatest(
                x.independent_lgd_input_rate,
                x.baseline_independent_lgd_rate
            )
            ELSE x.independent_lgd_input_rate
        END::numeric(12,8) AS final_lgd_input_rate,
        CASE
            WHEN x.integrated_risk_evidence_status = 'BLOCKED'
              OR x.synthetic_merchant_risk_proxy IS NULL THEN 'BLOCKED'
            WHEN x.recovery_evidence_status = 'SUPPORTED'
              AND x.collateral_source_quality_status = 'PASS' THEN 'COMPLETE'
            ELSE 'PARTIAL'
        END AS loss_evidence_status
    FROM _m1_13_loss_independent x
),
losses AS (
    SELECT
        f.*,
        (1.0 - f.final_lgd_input_rate)::numeric(12,8) AS recovery_rate_assumption,
        CASE
            WHEN f.synthetic_merchant_risk_proxy IS NULL THEN NULL
            ELSE round(
                f.requested_total_repayment_amount
                * f.synthetic_merchant_risk_proxy
                * f.final_lgd_input_rate,
                2
            )
        END::numeric(18,2) AS simple_loss_amount,
        CASE
            WHEN f.synthetic_merchant_risk_proxy IS NULL THEN NULL
            ELSE round(
                f.path_weighted_ead_amount
                * f.synthetic_merchant_risk_proxy
                * f.final_lgd_input_rate,
                2
            )
        END::numeric(18,2) AS schedule_loss_amount
    FROM finalized f
),
with_baseline AS (
    SELECT
        l.*,
        max(l.simple_loss_amount) FILTER (
            WHERE l.scenario_code = 'BASELINE'
        ) OVER (PARTITION BY l.merchant_application_id) AS baseline_simple_loss_amount,
        max(l.schedule_loss_amount) FILTER (
            WHERE l.scenario_code = 'BASELINE'
        ) OVER (PARTITION BY l.merchant_application_id) AS baseline_schedule_loss_amount,
        max(l.final_lgd_input_rate) FILTER (
            WHERE l.scenario_code = 'BASELINE'
        ) OVER (PARTITION BY l.merchant_application_id) AS baseline_final_lgd_rate
    FROM losses l
)
INSERT INTO _m1_13_loss_expected (
    module1_run_id,
    scenario_id,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    industry_code,
    integrated_risk_snapshot_hash,
    liquidity_capacity_snapshot_hash,
    application_request_hash,
    integrated_risk_evidence_status,
    recovery_evidence_status,
    loss_evidence_status,
    synthetic_merchant_risk_proxy,
    integrated_risk_tier,
    requested_funding_amount,
    requested_total_repayment_amount,
    requested_finance_charge_amount,
    requested_expected_payoff_days,
    scenario_expected_daily_remittance,
    baseline_expected_daily_remittance,
    governed_path_daily_payment,
    paydown_curve_shape,
    initial_receivable_exposure_amount,
    path_weighted_ead_amount,
    expected_ead_rate,
    industry_lgd_baseline_rate,
    scenario_lgd_addon_rate,
    collateral_available_value,
    guarantee_capacity_amount,
    collateral_recovery_credit_rate,
    guarantee_recovery_credit_rate,
    total_recovery_credit_rate,
    recovery_basis_code,
    recovery_rate_assumption,
    lgd_input_rate,
    simple_comparative_expected_loss_amount,
    schedule_adjusted_comparative_expected_loss_amount,
    simple_comparative_loss_rate,
    schedule_adjusted_comparative_loss_rate,
    stress_ead_worsening_flag,
    stress_lgd_worsening_flag,
    stress_loss_worsening_flag,
    hard_stop_recommended_flag,
    manual_review_recommended_flag,
    fallback_path_code,
    primary_loss_reason_code,
    secondary_loss_reason_codes,
    row_hash,
    created_by_run_id
)
SELECT
    w.module1_run_id,
    w.scenario_id,
    w.merchant_application_id,
    w.population_id,
    w.merchant_id,
    w.as_of_date,
    w.industry_code,
    w.integrated_risk_snapshot_hash,
    w.liquidity_capacity_snapshot_hash,
    w.application_request_hash,
    w.integrated_risk_evidence_status,
    w.recovery_evidence_status,
    w.loss_evidence_status,
    w.synthetic_merchant_risk_proxy,
    w.integrated_risk_tier,
    w.requested_funding_amount,
    w.requested_total_repayment_amount,
    w.requested_finance_charge_amount,
    w.requested_expected_payoff_days,
    w.scenario_expected_daily_remittance,
    w.baseline_expected_daily_remittance,
    w.governed_path_daily_payment,
    w.paydown_curve_shape,
    w.requested_total_repayment_amount AS initial_receivable_exposure_amount,
    w.path_weighted_ead_amount,
    round(
        w.path_weighted_ead_amount / nullif(w.requested_total_repayment_amount, 0),
        8
    )::numeric(12,8) AS expected_ead_rate,
    w.industry_lgd_baseline_rate,
    w.scenario_lgd_addon_rate,
    w.collateral_available_value,
    w.guarantee_capacity_amount,
    w.collateral_recovery_credit_rate,
    w.guarantee_recovery_credit_rate,
    w.total_recovery_credit_rate,
    w.recovery_basis_code,
    w.recovery_rate_assumption,
    w.final_lgd_input_rate,
    CASE WHEN w.simple_el_publish_flag THEN w.simple_loss_amount ELSE NULL END,
    CASE WHEN w.schedule_adjusted_el_publish_flag THEN w.schedule_loss_amount ELSE NULL END,
    CASE
        WHEN w.simple_loss_amount IS NULL THEN NULL
        ELSE round(w.simple_loss_amount / w.requested_total_repayment_amount, 8)
    END::numeric(12,8),
    CASE
        WHEN w.schedule_loss_amount IS NULL THEN NULL
        ELSE round(w.schedule_loss_amount / w.requested_total_repayment_amount, 8)
    END::numeric(12,8),
    (
        w.scenario_code = 'RECESSION_ENERGY'
        AND w.path_weighted_ead_amount > w.baseline_path_weighted_ead_amount
    ),
    (
        w.scenario_code = 'RECESSION_ENERGY'
        AND w.final_lgd_input_rate > w.baseline_final_lgd_rate
    ),
    (
        w.scenario_code = 'RECESSION_ENERGY'
        AND w.schedule_loss_amount IS NOT NULL
        AND w.baseline_schedule_loss_amount IS NOT NULL
        AND w.schedule_loss_amount > w.baseline_schedule_loss_amount
    ),
    w.hard_stop_recommended_flag,
    (
        w.risk_manual_review_flag
        OR w.capacity_manual_review_flag
        OR w.hard_stop_recommended_flag
        OR w.loss_evidence_status = 'BLOCKED'
        OR w.recovery_evidence_status = 'CONFLICT'
        OR w.final_lgd_input_rate >= (w.profile_payload ->> 'manual_review_lgd_threshold')::numeric
        OR (
            w.schedule_loss_amount IS NOT NULL
            AND round(
                w.schedule_loss_amount / w.requested_total_repayment_amount,
                8
            )::numeric(12,8)
                >= (w.profile_payload ->> 'manual_review_loss_rate_threshold')::numeric
        )
    ),
    CASE
        WHEN w.hard_stop_recommended_flag THEN 'VERIFICATION_STOP'
        WHEN w.loss_evidence_status = 'BLOCKED' THEN 'INSUFFICIENT_RISK_EVIDENCE'
        WHEN w.recovery_evidence_status = 'CONFLICT' THEN 'RECOVERY_SOURCE_REVIEW'
        WHEN w.final_lgd_input_rate >= (w.profile_payload ->> 'manual_review_lgd_threshold')::numeric
          OR (
              w.schedule_loss_amount IS NOT NULL
              AND round(
                w.schedule_loss_amount / w.requested_total_repayment_amount,
                8
            )::numeric(12,8)
                  >= (w.profile_payload ->> 'manual_review_loss_rate_threshold')::numeric
          ) THEN 'MANUAL_LOSS_REVIEW'
        WHEN w.recovery_evidence_status = 'PARAMETER_ONLY' THEN 'PARAMETER_ONLY_RECOVERY'
        ELSE 'NONE'
    END,
    CASE
        WHEN w.hard_stop_recommended_flag THEN 'VERIFICATION_HARD_STOP'
        WHEN w.loss_evidence_status = 'BLOCKED' THEN 'INSUFFICIENT_RISK_EVIDENCE'
        WHEN w.recovery_evidence_status = 'CONFLICT' THEN 'RECOVERY_SOURCE_CONFLICT'
        WHEN w.final_lgd_input_rate >= (w.profile_payload ->> 'manual_review_lgd_threshold')::numeric
            THEN 'HIGH_LGD_FOUNDATION'
        WHEN w.schedule_loss_amount IS NOT NULL
         AND round(
                w.schedule_loss_amount / w.requested_total_repayment_amount,
                8
            )::numeric(12,8)
             >= (w.profile_payload ->> 'manual_review_loss_rate_threshold')::numeric
            THEN 'HIGH_COMPARATIVE_LOSS_RATE'
        WHEN w.recovery_evidence_status = 'PARAMETER_ONLY'
            THEN 'PARAMETER_ONLY_RECOVERY'
        WHEN w.path_weighted_ead_amount / w.requested_total_repayment_amount >= 0.70
            THEN 'ELEVATED_PATH_WEIGHTED_EAD'
        ELSE 'STANDARD_LOSS_FOUNDATION'
    END,
    array_remove(ARRAY[
        CASE WHEN w.recovery_evidence_status = 'PARAMETER_ONLY' THEN 'PARAMETER_ONLY_RECOVERY' END,
        CASE WHEN w.scenario_lgd_addon_rate > 0 THEN 'STRESS_LGD_ADDON' END,
        CASE WHEN w.collateral_recovery_credit_rate > 0 THEN 'COLLATERAL_RECOVERY_CREDIT' END,
        CASE WHEN w.guarantee_recovery_credit_rate > 0 THEN 'GUARANTEE_RECOVERY_CREDIT' END,
        CASE WHEN w.path_weighted_ead_amount / w.requested_total_repayment_amount >= 0.70 THEN 'ELEVATED_EAD_RATE' END,
        CASE WHEN w.integrated_risk_tier >= 4 THEN 'ELEVATED_INTEGRATED_RISK_TIER' END
    ]::text[], NULL),
    ''::text,
    w.module1_run_id
FROM with_baseline w;

UPDATE _m1_13_loss_expected s
SET row_hash = msbf_m1.m1_13_hash_jsonb(
    to_jsonb(s) - 'row_hash' - 'created_at'
)
WHERE s.row_hash = '';

CREATE UNIQUE INDEX ON _m1_13_loss_expected(scenario_id, merchant_application_id);
ANALYZE _m1_13_loss_expected;

/* ---------------------------------------------------------------------------
5. Persist once, index, ANALYZE, and reconcile canonical rows
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.13 Phase 4/6 — persist path and loss snapshots once, then ANALYZE';
END;
$notice$;

INSERT INTO msbf_m1.application_ead_path_value (
    module1_run_id, scenario_id, merchant_application_id, path_day,
    path_bucket, path_bucket_day_count, paydown_curve_shape,
    beginning_exposure_amount, scheduled_remittance_amount,
    expected_receivable_reduction_amount, ending_exposure_amount,
    default_timing_weight, weighted_ead_amount, exposure_basis_code,
    payment_basis_code, path_hash, created_by_run_id
)
SELECT
    module1_run_id, scenario_id, merchant_application_id, path_day,
    path_bucket, path_bucket_day_count, paydown_curve_shape,
    beginning_exposure_amount, scheduled_remittance_amount,
    expected_receivable_reduction_amount, ending_exposure_amount,
    default_timing_weight, weighted_ead_amount, exposure_basis_code,
    payment_basis_code, path_hash, created_by_run_id
FROM _m1_13_path_expected;

INSERT INTO msbf_m1.application_exposure_recovery_loss_snapshot (
    module1_run_id, scenario_id, merchant_application_id, population_id,
    merchant_id, as_of_date, industry_code, integrated_risk_snapshot_hash,
    liquidity_capacity_snapshot_hash, application_request_hash,
    integrated_risk_evidence_status, recovery_evidence_status,
    loss_evidence_status, synthetic_merchant_risk_proxy,
    integrated_risk_tier, requested_funding_amount,
    requested_total_repayment_amount, requested_finance_charge_amount,
    requested_expected_payoff_days, scenario_expected_daily_remittance,
    baseline_expected_daily_remittance, governed_path_daily_payment,
    paydown_curve_shape, initial_receivable_exposure_amount,
    path_weighted_ead_amount, expected_ead_rate,
    industry_lgd_baseline_rate, scenario_lgd_addon_rate,
    collateral_available_value, guarantee_capacity_amount,
    collateral_recovery_credit_rate, guarantee_recovery_credit_rate,
    total_recovery_credit_rate, recovery_basis_code,
    recovery_rate_assumption, lgd_input_rate,
    simple_comparative_expected_loss_amount,
    schedule_adjusted_comparative_expected_loss_amount,
    simple_comparative_loss_rate, schedule_adjusted_comparative_loss_rate,
    stress_ead_worsening_flag, stress_lgd_worsening_flag,
    stress_loss_worsening_flag, hard_stop_recommended_flag,
    manual_review_recommended_flag, fallback_path_code,
    primary_loss_reason_code, secondary_loss_reason_codes,
    row_hash, created_by_run_id
)
SELECT
    module1_run_id, scenario_id, merchant_application_id, population_id,
    merchant_id, as_of_date, industry_code, integrated_risk_snapshot_hash,
    liquidity_capacity_snapshot_hash, application_request_hash,
    integrated_risk_evidence_status, recovery_evidence_status,
    loss_evidence_status, synthetic_merchant_risk_proxy,
    integrated_risk_tier, requested_funding_amount,
    requested_total_repayment_amount, requested_finance_charge_amount,
    requested_expected_payoff_days, scenario_expected_daily_remittance,
    baseline_expected_daily_remittance, governed_path_daily_payment,
    paydown_curve_shape, initial_receivable_exposure_amount,
    path_weighted_ead_amount, expected_ead_rate,
    industry_lgd_baseline_rate, scenario_lgd_addon_rate,
    collateral_available_value, guarantee_capacity_amount,
    collateral_recovery_credit_rate, guarantee_recovery_credit_rate,
    total_recovery_credit_rate, recovery_basis_code,
    recovery_rate_assumption, lgd_input_rate,
    simple_comparative_expected_loss_amount,
    schedule_adjusted_comparative_expected_loss_amount,
    simple_comparative_loss_rate, schedule_adjusted_comparative_loss_rate,
    stress_ead_worsening_flag, stress_lgd_worsening_flag,
    stress_loss_worsening_flag, hard_stop_recommended_flag,
    manual_review_recommended_flag, fallback_path_code,
    primary_loss_reason_code, secondary_loss_reason_codes,
    row_hash, created_by_run_id
FROM _m1_13_loss_expected;

ANALYZE msbf_m1.application_ead_path_value;
ANALYZE msbf_m1.application_exposure_recovery_loss_snapshot;

DO $notice$
BEGIN
    RAISE NOTICE 'M1.13 Phase 5/6 — perform independent physical-field canonical reconciliation';
END;
$notice$;

CREATE TEMP TABLE _m1_13_expected_canonical
ON COMMIT DROP AS
SELECT
    'PATH|' || scenario_id || '|' || merchant_application_id || '|' || path_day AS entity_key,
    path_hash AS row_hash
FROM _m1_13_path_expected
UNION ALL
SELECT
    'LOSS|' || scenario_id || '|' || merchant_application_id AS entity_key,
    row_hash
FROM _m1_13_loss_expected;
CREATE UNIQUE INDEX ON _m1_13_expected_canonical(entity_key);

CREATE TEMP TABLE _m1_13_actual_canonical
ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_13_actual_path_snapshot(
    (SELECT run_id FROM _m1_13_context)
)
UNION ALL
SELECT * FROM msbf_m1.m1_13_actual_loss_snapshot(
    (SELECT run_id FROM _m1_13_context)
);
CREATE UNIQUE INDEX ON _m1_13_actual_canonical(entity_key);

CREATE TEMP TABLE _m1_13_mismatch
ON COMMIT DROP AS
SELECT
    coalesce(e.entity_key, a.entity_key) AS entity_key,
    e.row_hash AS expected_hash,
    a.row_hash AS actual_hash
FROM _m1_13_expected_canonical e
FULL JOIN _m1_13_actual_canonical a USING (entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash;

CREATE TEMP TABLE _m1_13_hashes
ON COMMIT DROP AS
SELECT
    (SELECT count(*) FROM _m1_13_expected_canonical) AS expected_canonical_entities,
    (SELECT count(*) FROM _m1_13_actual_canonical) AS actual_canonical_entities,
    (SELECT count(*) FROM _m1_13_mismatch) AS row_level_mismatches,
    (
        SELECT md5(string_agg(entity_key || '|' || row_hash, '||' ORDER BY entity_key))
        FROM _m1_13_actual_canonical
        WHERE entity_key LIKE 'PATH|%'
    ) AS path_set_hash,
    (
        SELECT md5(string_agg(entity_key || '|' || row_hash, '||' ORDER BY entity_key))
        FROM _m1_13_actual_canonical
        WHERE entity_key LIKE 'LOSS|%'
    ) AS snapshot_set_hash,
    (
        SELECT md5(string_agg(entity_key || '|' || row_hash, '||' ORDER BY entity_key))
        FROM _m1_13_actual_canonical
    ) AS combined_set_hash;

DO $reconcile$
DECLARE
    v_expected bigint;
    v_actual bigint;
    v_mismatches bigint;
BEGIN
    SELECT expected_canonical_entities, actual_canonical_entities, row_level_mismatches
    INTO v_expected, v_actual, v_mismatches
    FROM _m1_13_hashes;

    IF v_expected <> v_actual OR v_mismatches <> 0 THEN
        RAISE EXCEPTION 'M1.13 canonical reconciliation failed: expected %, actual %, mismatches %.',
            v_expected, v_actual, v_mismatches;
    END IF;
END;
$reconcile$;

/* ---------------------------------------------------------------------------
6. Persist governed generation evidence and advance run state
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.13 Phase 6/6 — persist governed generation evidence and commit';
END;
$notice$;

INSERT INTO msbf_ctl.run_evidence (
    run_id, evidence_code, segment_key, metric_name,
    metric_value_text, unit_code, status, interpretation
)
SELECT run_id, 'M1_13_GENERATION_SPEC', 'PORTFOLIO',
       'M1.13 generation specification',
       'M1_13_METHOD_V1|CONTRACTUAL_RECEIVABLE|WEIGHTED_DAILY_BALANCE|EARLY_MIDDLE_LATE',
       'TEXT', 'PASS',
       'Governed M1.13 methodology, exposure basis, EAD method, and timing basis.'
FROM _m1_13_context
ON CONFLICT (run_id, evidence_code, segment_key) DO UPDATE SET
    metric_name = EXCLUDED.metric_name,
    metric_value_text = EXCLUDED.metric_value_text,
    metric_value_numeric = NULL,
    unit_code = EXCLUDED.unit_code,
    status = EXCLUDED.status,
    interpretation = EXCLUDED.interpretation,
    created_at = clock_timestamp();

INSERT INTO msbf_ctl.run_evidence (
    run_id, evidence_code, segment_key, metric_name,
    metric_value_text, unit_code, status, interpretation
)
SELECT c.run_id, x.evidence_code, 'PORTFOLIO', x.metric_name,
       x.metric_value_text, 'HASH', 'PASS', x.interpretation
FROM _m1_13_context c
CROSS JOIN LATERAL (
    VALUES
        ('M1_13_PATH_SET_HASH', 'M1.13 EAD path set hash',
         (SELECT path_set_hash FROM _m1_13_hashes),
         'Deterministic hash over all persisted M1.13 daily EAD path rows.'),
        ('M1_13_SNAPSHOT_SET_HASH', 'M1.13 exposure/recovery/loss snapshot set hash',
         (SELECT snapshot_set_hash FROM _m1_13_hashes),
         'Deterministic hash over all persisted M1.13 exposure/recovery/loss snapshots.'),
        ('M1_13_COMBINED_SET_HASH', 'M1.13 combined set hash',
         (SELECT combined_set_hash FROM _m1_13_hashes),
         'Deterministic hash over the complete M1.13 canonical entity set.')
) AS x(evidence_code, metric_name, metric_value_text, interpretation)
ON CONFLICT (run_id, evidence_code, segment_key) DO UPDATE SET
    metric_name = EXCLUDED.metric_name,
    metric_value_text = EXCLUDED.metric_value_text,
    metric_value_numeric = NULL,
    unit_code = EXCLUDED.unit_code,
    status = EXCLUDED.status,
    interpretation = EXCLUDED.interpretation,
    created_at = clock_timestamp();

INSERT INTO msbf_ctl.run_evidence (
    run_id, evidence_code, segment_key, metric_name,
    metric_value_numeric, unit_code, status, interpretation
)
SELECT c.run_id, x.evidence_code, 'PORTFOLIO', x.metric_name,
       x.metric_value_numeric, x.unit_code, 'PASS', x.interpretation
FROM _m1_13_context c
CROSS JOIN LATERAL (
    VALUES
        ('M1_13_PATH_ROW_COUNT', 'M1.13 daily EAD path rows',
         (SELECT count(*)::numeric FROM msbf_m1.application_ead_path_value
          WHERE module1_run_id = c.run_id), 'ROWS',
         'Persisted scenario/application/day exposure-path row count.'),
        ('M1_13_SNAPSHOT_ROW_COUNT', 'M1.13 loss snapshot rows',
         (SELECT count(*)::numeric FROM msbf_m1.application_exposure_recovery_loss_snapshot
          WHERE module1_run_id = c.run_id), 'ROWS',
         'Persisted scenario/application exposure/recovery/loss row count.'),
        ('M1_13_CANONICAL_ENTITY_COUNT', 'M1.13 canonical entities',
         (SELECT actual_canonical_entities::numeric FROM _m1_13_hashes), 'ROWS',
         'Complete path plus snapshot canonical entity count.'),
        ('M1_13_CANONICAL_MISMATCH_COUNT', 'M1.13 canonical mismatches',
         (SELECT row_level_mismatches::numeric FROM _m1_13_hashes), 'ROWS',
         'Expected-versus-physical canonical row mismatches.'),
        ('M1_13_PORTFOLIO_SCHEDULE_LOSS_AMOUNT', 'M1.13 portfolio schedule-adjusted comparative loss',
         (SELECT coalesce(sum(schedule_adjusted_comparative_expected_loss_amount), 0)::numeric
          FROM msbf_m1.application_exposure_recovery_loss_snapshot
          WHERE module1_run_id = c.run_id), 'CURRENCY',
         'Synthetic comparative schedule-adjusted loss total; not CECL, reserve, capital, or forecast.')
) AS x(evidence_code, metric_name, metric_value_numeric, unit_code, interpretation)
ON CONFLICT (run_id, evidence_code, segment_key) DO UPDATE SET
    metric_name = EXCLUDED.metric_name,
    metric_value_numeric = EXCLUDED.metric_value_numeric,
    metric_value_text = NULL,
    unit_code = EXCLUDED.unit_code,
    status = EXCLUDED.status,
    interpretation = EXCLUDED.interpretation,
    created_at = clock_timestamp();

INSERT INTO msbf_ctl.run_evidence (
    run_id, evidence_code, segment_key, metric_name,
    metric_value_text, unit_code, status, interpretation
)
SELECT
    c.run_id,
    'M1_13_GENERATION_SUMMARY',
    'PORTFOLIO',
    'M1.13 generation summary',
    format(
        'paths=%s|snapshots=%s|canonical=%s|mismatches=%s|combined_hash=%s',
        (SELECT count(*) FROM msbf_m1.application_ead_path_value WHERE module1_run_id = c.run_id),
        (SELECT count(*) FROM msbf_m1.application_exposure_recovery_loss_snapshot WHERE module1_run_id = c.run_id),
        h.actual_canonical_entities,
        h.row_level_mismatches,
        h.combined_set_hash
    ),
    'TEXT',
    CASE WHEN h.row_level_mismatches = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Committed M1.13 generation checkpoint.'
FROM _m1_13_context c
CROSS JOIN _m1_13_hashes h
ON CONFLICT (run_id, evidence_code, segment_key) DO UPDATE SET
    metric_name = EXCLUDED.metric_name,
    metric_value_text = EXCLUDED.metric_value_text,
    metric_value_numeric = NULL,
    unit_code = EXCLUDED.unit_code,
    status = EXCLUDED.status,
    interpretation = EXCLUDED.interpretation,
    created_at = clock_timestamp();

UPDATE msbf_ctl.run_registry r
SET run_status = 'M1_13_GENERATED',
    notes = coalesce(r.notes, '') || E'\nM1.13 v0.2R1 generation completed with zero canonical mismatches.'
WHERE r.run_id = (SELECT run_id FROM _m1_13_context);

CREATE TEMP TABLE _m1_13_generation_result
ON COMMIT PRESERVE ROWS AS
SELECT
    r.run_id,
    r.run_status,
    (SELECT count(*) FROM msbf_m1.application_ead_path_value
     WHERE module1_run_id = r.run_id) AS path_rows,
    (SELECT count(*) FROM msbf_m1.application_exposure_recovery_loss_snapshot
     WHERE module1_run_id = r.run_id) AS snapshot_rows,
    (SELECT count(DISTINCT merchant_application_id)
     FROM msbf_m1.application_exposure_recovery_loss_snapshot
     WHERE module1_run_id = r.run_id) AS applications,
    (SELECT count(DISTINCT scenario_id)
     FROM msbf_m1.application_exposure_recovery_loss_snapshot
     WHERE module1_run_id = r.run_id) AS scenarios,
    h.expected_canonical_entities,
    h.actual_canonical_entities,
    h.row_level_mismatches,
    h.path_set_hash,
    h.snapshot_set_hash,
    h.combined_set_hash,
    CASE
        WHEN r.run_status = 'M1_13_GENERATED'
         AND (SELECT count(*) FROM msbf_m1.application_exposure_recovery_loss_snapshot
              WHERE module1_run_id = r.run_id) = 1500
         AND h.expected_canonical_entities = h.actual_canonical_entities
         AND h.row_level_mismatches = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS generation_status
FROM msbf_ctl.run_registry r
CROSS JOIN _m1_13_hashes h
WHERE r.run_id = (SELECT run_id FROM _m1_13_context);

COMMIT;

SELECT *
FROM _m1_13_generation_result;
