/* ============================================================================
MSBF M1.12 Merchant Risk Components & Integrated Risk Proxy — Generation
Version : v0.2
Purpose : Consume accepted M1.8 verification/fraud evidence, M1.10 capacity
          evidence, and M1.11 operating-resilience evidence; create seven
          transparent scenario-aware risk components, a synthetic integrated
          merchant-risk proxy, matched stress migration, reason evidence, and
          deterministic canonical hashes.
Performance: Accepted physical inputs are materialized once. No M1.4–M1.11
             blueprint is regenerated. Intermediate populations are bounded to
             1,500 snapshots and 10,500 component rows, indexed, and analyzed.
Boundary: This module does not create calibrated PD, EAD, LGD, Expected Loss,
          pricing, offers, or credit decisions.
============================================================================ */

BEGIN;

SET LOCAL work_mem = '64MB';
SET LOCAL jit = off;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '15min';

/* ---------------------------------------------------------------------------
1. Canonical hashing and read-only physical reconstruction helpers
--------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_m1.m1_12_hash_jsonb(p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT md5(p_payload::text)
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_12_actual_snapshot(p_run_id bigint)
RETURNS TABLE (entity_key text, row_hash text)
LANGUAGE sql
STABLE
AS $$
    SELECT
        'RISK|' || r.scenario_id || '|' || r.merchant_application_id,
        msbf_m1.m1_12_hash_jsonb(
            to_jsonb(r) - 'row_hash' - 'created_at'
        )
    FROM msbf_m1.application_integrated_risk_proxy_snapshot r
    WHERE r.module1_run_id = p_run_id
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_12_actual_component(p_run_id bigint)
RETURNS TABLE (entity_key text, row_hash text)
LANGUAGE sql
STABLE
AS $$
    SELECT
        'COMPONENT|' || c.scenario_id || '|' || c.merchant_application_id
            || '|' || c.component_code || '|' || c.component_version,
        msbf_m1.m1_12_hash_jsonb(
            to_jsonb(c) - 'calculation_hash' - 'created_at'
        )
    FROM msbf_m1.integrated_risk_component_value c
    WHERE c.module1_run_id = p_run_id
$$;

/* ---------------------------------------------------------------------------
2. Fail-closed configuration and generation-readiness guards
--------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_m1.m1_12_assert_configuration()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_status text;
    v_payload jsonb;
    v_weight_sum numeric;
    v_tier_1 numeric;
    v_tier_2 numeric;
    v_tier_3 numeric;
    v_tier_4 numeric;
BEGIN
    SELECT status, profile_payload
    INTO STRICT v_status, v_payload
    FROM msbf_ctl.policy_profile
    WHERE profile_code = 'M1_12_INTEGRATED_RISK_PROXY'
      AND profile_version = 1;

    v_weight_sum :=
        (v_payload ->> 'component_weight_operating_resilience')::numeric
      + (v_payload ->> 'component_weight_capacity_burden')::numeric
      + (v_payload ->> 'component_weight_liquidity')::numeric
      + (v_payload ->> 'component_weight_source_confidence')::numeric
      + (v_payload ->> 'component_weight_verification_fraud')::numeric
      + (v_payload ->> 'component_weight_processor_continuity')::numeric
      + (v_payload ->> 'component_weight_industry_relationship')::numeric;

    v_tier_1 := (v_payload ->> 'risk_tier_1_max')::numeric;
    v_tier_2 := (v_payload ->> 'risk_tier_2_max')::numeric;
    v_tier_3 := (v_payload ->> 'risk_tier_3_max')::numeric;
    v_tier_4 := (v_payload ->> 'risk_tier_4_max')::numeric;

    IF v_status <> 'APPROVED' THEN
        RAISE EXCEPTION 'M1.12 requires an APPROVED policy profile; observed %.', v_status;
    END IF;

    IF coalesce((v_payload ->> 'generation_enabled')::boolean, false) = false THEN
        RAISE EXCEPTION 'M1.12 generation is disabled by governed policy.';
    END IF;

    IF v_payload ->> 'methodology_version' <> 'M1_12_METHOD_V1' THEN
        RAISE EXCEPTION 'M1.12 methodology version is invalid: %.',
            v_payload ->> 'methodology_version';
    END IF;

    IF v_payload ->> 'composite_score_basis'
        <> 'SUM_PERSISTED_WEIGHTED_RISK_COMPONENTS' THEN
        RAISE EXCEPTION 'M1.12 composite-score basis is invalid: %.',
            v_payload ->> 'composite_score_basis';
    END IF;

    IF abs(v_weight_sum - 1.0) > 0.0000001 THEN
        RAISE EXCEPTION 'M1.12 component weights must sum to 1.0; observed %.',
            v_weight_sum;
    END IF;

    IF NOT (v_tier_1 < v_tier_2 AND v_tier_2 < v_tier_3 AND v_tier_3 < v_tier_4) THEN
        RAISE EXCEPTION 'M1.12 risk-tier thresholds are not strictly increasing.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_12_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_status text;
    v_resilience_rows bigint;
    v_capacity_rows bigint;
    v_verification_rows bigint;
    v_scenarios bigint;
    v_baseline_scenarios bigint;
    v_stress_scenarios bigint;
    v_scenario_rows bigint;
    v_target_rows bigint;
    v_downstream_rows bigint;
BEGIN
    PERFORM msbf_m1.m1_12_assert_configuration();

    SELECT run_status
    INTO STRICT v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    IF v_run_status <> 'M1_11_ACCEPTED' THEN
        RAISE EXCEPTION 'M1.12 requires M1_11_ACCEPTED; observed %.', v_run_status;
    END IF;

    SELECT
        count(*),
        count(DISTINCT r.scenario_id),
        count(DISTINCT r.scenario_id)
            FILTER (WHERE sr.scenario_code = 'BASELINE'),
        count(DISTINCT r.scenario_id)
            FILTER (WHERE sr.scenario_code = 'RECESSION_ENERGY')
    INTO
        v_resilience_rows,
        v_scenarios,
        v_baseline_scenarios,
        v_stress_scenarios
    FROM msbf_m1.application_operating_resilience_snapshot r
    JOIN msbf_ctl.scenario_registry sr
      ON sr.scenario_id = r.scenario_id
    JOIN msbf_ctl.scenario_set ss
      ON ss.scenario_set_id = sr.scenario_set_id
    WHERE r.module1_run_id = p_run_id
      AND ss.scenario_set_code = 'M1_V0_2_BASELINE_AND_STRESS'
      AND ss.scenario_set_version = 1
      AND ss.status = 'APPROVED'
      AND sr.status = 'APPROVED'
      AND sr.scenario_version = 1
      AND sr.scenario_code IN ('BASELINE', 'RECESSION_ENERGY');

    SELECT count(*)
    INTO v_scenario_rows
    FROM msbf_m1.application_operating_resilience_snapshot
    WHERE module1_run_id = p_run_id;

    SELECT count(*)
    INTO v_capacity_rows
    FROM msbf_m1.application_liquidity_capacity_snapshot
    WHERE module1_run_id = p_run_id;

    SELECT count(*)
    INTO v_verification_rows
    FROM msbf_m1.application_verification_fraud_snapshot
    WHERE module1_run_id = p_run_id;

    SELECT
        (SELECT count(*)
         FROM msbf_m1.application_integrated_risk_proxy_snapshot
         WHERE module1_run_id = p_run_id)
      + (SELECT count(*)
         FROM msbf_m1.integrated_risk_component_value
         WHERE module1_run_id = p_run_id)
    INTO v_target_rows;

    SELECT
        (SELECT count(*)
         FROM msbf_m1.merchant_risk_snapshot
         WHERE module1_run_id = p_run_id)
      + (SELECT count(*)
         FROM msbf_m1.risk_component_detail
         WHERE module1_run_id = p_run_id)
      + (SELECT count(*)
         FROM msbf_m1.ead_path_snapshot
         WHERE module1_run_id = p_run_id)
      + (SELECT count(*)
         FROM msbf_m1.module1_latest
         WHERE module1_run_id = p_run_id)
      + (SELECT count(*)
         FROM msbf_m1.module1_archive
         WHERE module1_run_id = p_run_id)
    INTO v_downstream_rows;

    IF v_resilience_rows <> 1500
       OR v_scenario_rows <> 1500
       OR v_capacity_rows <> 1500
       OR v_verification_rows <> 750
       OR v_scenarios <> 2
       OR v_baseline_scenarios <> 1
       OR v_stress_scenarios <> 1 THEN
        RAISE EXCEPTION
            'M1.12 input/scenario scope mismatch: scoped resilience %, total resilience %, capacity %, verification %, scenarios %, baseline %, stress %.',
            v_resilience_rows,
            v_scenario_rows,
            v_capacity_rows,
            v_verification_rows,
            v_scenarios,
            v_baseline_scenarios,
            v_stress_scenarios;
    END IF;

    IF v_target_rows <> 0 THEN
        RAISE EXCEPTION 'M1.12 generation rejected because % target rows already exist.',
            v_target_rows;
    END IF;

    IF v_downstream_rows <> 0 THEN
        RAISE EXCEPTION 'M1.12 generation rejected because % downstream risk/loss rows already exist.',
            v_downstream_rows;
    END IF;
END;
$$;

/* ---------------------------------------------------------------------------
3. Session-scoped generation workspace
--------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m1_12_context;
DROP TABLE IF EXISTS _m1_12_input;
DROP TABLE IF EXISTS _m1_12_scored_input;
DROP TABLE IF EXISTS _m1_12_component_expected;
DROP TABLE IF EXISTS _m1_12_component_aggregate;
DROP TABLE IF EXISTS _m1_12_independent;
DROP TABLE IF EXISTS _m1_12_baseline;
DROP TABLE IF EXISTS _m1_12_final;
DROP TABLE IF EXISTS _m1_12_snapshot_expected;
DROP TABLE IF EXISTS _m1_12_expected_canonical;
DROP TABLE IF EXISTS _m1_12_actual_canonical;
DROP TABLE IF EXISTS _m1_12_mismatch;
DROP TABLE IF EXISTS _m1_12_hashes;

CREATE TEMP TABLE _m1_12_context
ON COMMIT DROP AS
SELECT
    r.run_id,
    r.population_id,
    r.as_of_date,
    p.policy_profile_id,
    p.profile_payload
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.policy_profile p
  ON p.profile_code = 'M1_12_INTEGRATED_RISK_PROXY'
 AND p.profile_version = 1
 AND p.status = 'APPROVED'
WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND r.run_version = 1;

SELECT msbf_m1.m1_12_assert_generation_ready(
    (SELECT run_id FROM _m1_12_context)
);

DO $notice$
BEGIN
    RAISE NOTICE 'M1.12 Phase 1/6 — materialize accepted M1.8, M1.10 and M1.11 inputs once';
END;
$notice$;

CREATE TEMP TABLE _m1_12_input
ON COMMIT DROP AS
SELECT
    r.module1_run_id,
    r.scenario_id,
    sr.scenario_code,
    r.merchant_application_id,
    r.population_id,
    r.merchant_id,
    r.as_of_date,
    r.merchant_size_tier,
    r.industry_code,
    i.risk_tier AS industry_risk_tier,
    r.relationship_stage,
    r.row_hash AS operating_resilience_snapshot_hash,
    c.row_hash AS liquidity_capacity_snapshot_hash,
    v.row_hash AS verification_fraud_snapshot_hash,
    r.operating_resilience_evidence_status,
    r.capacity_evidence_status,
    r.data_confidence_tier,
    r.verification_disposition,
    v.fraud_score,
    v.fraud_risk_tier,
    r.processor_continuity_risk_tier,
    r.resilience_tier AS operating_resilience_tier,
    c.capacity_tier,
    r.archetype_code,
    r.archetype_risk_rank,
    r.operating_resilience_score,
    r.burden_resilience_score,
    r.liquidity_resilience_score,
    r.source_confidence_score,
    r.continuity_resilience_score,
    v.hard_stop_recommended_flag AS verification_hard_stop_flag,
    (
        r.manual_review_recommended_flag
        OR c.manual_review_recommended_flag
        OR v.manual_review_recommended_flag
    ) AS upstream_manual_review_flag,
    r.fallback_path_code AS resilience_fallback_path,
    c.fallback_path_code AS capacity_fallback_path,
    v.primary_reason_code AS verification_primary_reason_code
FROM msbf_m1.application_operating_resilience_snapshot r
JOIN msbf_m1.application_liquidity_capacity_snapshot c
  ON c.module1_run_id = r.module1_run_id
 AND c.scenario_id = r.scenario_id
 AND c.merchant_application_id = r.merchant_application_id
JOIN msbf_m1.application_verification_fraud_snapshot v
  ON v.module1_run_id = r.module1_run_id
 AND v.merchant_application_id = r.merchant_application_id
JOIN msbf_ctl.scenario_registry sr
  ON sr.scenario_id = r.scenario_id
JOIN msbf_ctl.scenario_set ss
  ON ss.scenario_set_id = sr.scenario_set_id
JOIN msbf_ref.industry i
  ON i.industry_code = r.industry_code
WHERE r.module1_run_id = (SELECT run_id FROM _m1_12_context)
  AND ss.scenario_set_code = 'M1_V0_2_BASELINE_AND_STRESS'
  AND ss.scenario_set_version = 1
  AND ss.status = 'APPROVED'
  AND sr.status = 'APPROVED'
  AND sr.scenario_version = 1
  AND sr.scenario_code IN ('BASELINE', 'RECESSION_ENERGY');

CREATE UNIQUE INDEX ON _m1_12_input (scenario_id, merchant_application_id);
ANALYZE _m1_12_input;

/* ---------------------------------------------------------------------------
4. Calculate component-level source values and risk scores
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.12 Phase 2/6 — calculate seven transparent risk components';
END;
$notice$;

CREATE TEMP TABLE _m1_12_scored_input
ON COMMIT DROP AS
SELECT
    i.*,
    p.profile_payload,
    CASE
        WHEN i.operating_resilience_evidence_status = 'BLOCKED'
          OR i.capacity_evidence_status = 'BLOCKED'
          OR i.verification_disposition = 'INSUFFICIENT_EVIDENCE'
            THEN 'BLOCKED'
        WHEN i.operating_resilience_evidence_status = 'PARTIAL'
          OR i.capacity_evidence_status = 'PARTIAL'
          OR i.verification_disposition = 'REVIEW'
          OR i.source_confidence_score
                < (p.profile_payload ->> 'source_confidence_partial_threshold')::numeric
            THEN 'PARTIAL'
        ELSE 'COMPLETE'
    END AS evidence_status,
    CASE
        WHEN i.operating_resilience_score IS NULL THEN NULL
        ELSE round(100.0 - i.operating_resilience_score, 6)::numeric(9,6)
    END AS operating_resilience_risk_score,
    CASE
        WHEN i.burden_resilience_score IS NULL THEN NULL
        ELSE round(100.0 - i.burden_resilience_score, 6)::numeric(9,6)
    END AS capacity_burden_risk_score,
    CASE
        WHEN i.liquidity_resilience_score IS NULL THEN NULL
        ELSE round(100.0 - i.liquidity_resilience_score, 6)::numeric(9,6)
    END AS liquidity_risk_score,
    round(100.0 * (1.0 - i.source_confidence_score), 6)::numeric(9,6)
        AS source_confidence_risk_score,
    round(
        (p.profile_payload ->> 'verification_fraud_weight_fraud_score')::numeric
            * i.fraud_score
      + (p.profile_payload ->> 'verification_fraud_weight_disposition')::numeric
            * CASE i.verification_disposition
                  WHEN 'CLEAR' THEN
                      (p.profile_payload ->> 'verification_clear_points')::numeric
                  WHEN 'REVIEW' THEN
                      (p.profile_payload ->> 'verification_review_points')::numeric
                  WHEN 'STOP' THEN
                      (p.profile_payload ->> 'verification_stop_points')::numeric
                  ELSE
                      (p.profile_payload ->> 'verification_insufficient_points')::numeric
              END,
        6
    )::numeric(9,6) AS verification_fraud_risk_score,
    CASE
        WHEN i.continuity_resilience_score IS NULL THEN NULL
        ELSE round(100.0 - i.continuity_resilience_score, 6)::numeric(9,6)
    END AS processor_continuity_risk_score,
    round(
        0.70 * (10.0 + (i.industry_risk_tier - 1) * 20.0)
      + 0.30 * CASE i.relationship_stage
                   WHEN 'NEW' THEN
                       (p.profile_payload ->> 'relationship_new_points')::numeric
                   WHEN 'RETURNING_GOOD' THEN
                       (p.profile_payload ->> 'relationship_returning_good_points')::numeric
                   WHEN 'RETURNING_MIXED' THEN
                       (p.profile_payload ->> 'relationship_returning_mixed_points')::numeric
                   WHEN 'LOW_AND_GROW' THEN
                       (p.profile_payload ->> 'relationship_low_and_grow_points')::numeric
                   ELSE 60.0
               END,
        6
    )::numeric(9,6) AS industry_relationship_risk_score
FROM _m1_12_input i
CROSS JOIN _m1_12_context p;

CREATE UNIQUE INDEX ON _m1_12_scored_input (scenario_id, merchant_application_id);
ANALYZE _m1_12_scored_input;

CREATE TEMP TABLE _m1_12_component_expected
(LIKE msbf_m1.integrated_risk_component_value INCLUDING DEFAULTS)
ON COMMIT DROP;

WITH component_source AS (
    SELECT
        s.module1_run_id,
        s.scenario_id,
        s.merchant_application_id,
        v.component_code,
        1::smallint AS component_version,
        v.component_source_value::numeric(24,10) AS component_source_value,
        v.component_risk_score::numeric(9,6) AS component_risk_score,
        v.component_weight::numeric(9,6) AS component_weight,
        CASE
            WHEN v.component_risk_score IS NULL THEN NULL
            ELSE round(v.component_risk_score * v.component_weight, 6)::numeric(9,6)
        END AS weighted_risk_points,
        CASE
            WHEN v.component_risk_score IS NULL THEN 'UNAVAILABLE'
            WHEN v.component_risk_score
                    < (s.profile_payload ->> 'component_zone_low_max')::numeric
                THEN 'LOW'
            WHEN v.component_risk_score
                    < (s.profile_payload ->> 'component_zone_moderate_max')::numeric
                THEN 'MODERATE'
            WHEN v.component_risk_score
                    < (s.profile_payload ->> 'component_zone_elevated_max')::numeric
                THEN 'ELEVATED'
            ELSE 'HIGH'
        END AS component_zone,
        CASE
            WHEN v.component_risk_score IS NULL THEN 'UNAVAILABLE'
            ELSE 'AVAILABLE'
        END AS component_status,
        CASE
            WHEN v.component_risk_score IS NULL THEN 'UNAVAILABLE'
            WHEN v.component_risk_score < 35 THEN 'FAVORABLE'
            WHEN v.component_risk_score < 65 THEN 'NEUTRAL'
            ELSE 'ADVERSE'
        END AS directional_status,
        CASE
            WHEN v.component_risk_score IS NULL THEN 'INPUT_NOT_AVAILABLE'
            ELSE v.component_reason_code
        END AS component_reason_code,
        v.source_lineage_hash
    FROM _m1_12_scored_input s
    CROSS JOIN LATERAL (
        VALUES
        (
            'OPERATING_RESILIENCE_RISK',
            s.operating_resilience_score,
            s.operating_resilience_risk_score,
            (s.profile_payload ->> 'component_weight_operating_resilience')::numeric,
            s.operating_resilience_snapshot_hash,
            'INVERTED_ACCEPTED_OPERATING_RESILIENCE'
        ),
        (
            'CAPACITY_BURDEN_RISK',
            s.burden_resilience_score,
            s.capacity_burden_risk_score,
            (s.profile_payload ->> 'component_weight_capacity_burden')::numeric,
            s.liquidity_capacity_snapshot_hash,
            'INVERTED_ACCEPTED_BURDEN_RESILIENCE'
        ),
        (
            'LIQUIDITY_RISK',
            s.liquidity_resilience_score,
            s.liquidity_risk_score,
            (s.profile_payload ->> 'component_weight_liquidity')::numeric,
            s.liquidity_capacity_snapshot_hash,
            'INVERTED_ACCEPTED_LIQUIDITY_RESILIENCE'
        ),
        (
            'SOURCE_CONFIDENCE_RISK',
            s.source_confidence_score,
            s.source_confidence_risk_score,
            (s.profile_payload ->> 'component_weight_source_confidence')::numeric,
            s.operating_resilience_snapshot_hash,
            'INVERTED_ACCEPTED_SOURCE_CONFIDENCE'
        ),
        (
            'VERIFICATION_FRAUD_RISK',
            s.fraud_score,
            s.verification_fraud_risk_score,
            (s.profile_payload ->> 'component_weight_verification_fraud')::numeric,
            s.verification_fraud_snapshot_hash,
            'BLENDED_FRAUD_AND_VERIFICATION_DISPOSITION'
        ),
        (
            'PROCESSOR_CONTINUITY_RISK',
            s.continuity_resilience_score,
            s.processor_continuity_risk_score,
            (s.profile_payload ->> 'component_weight_processor_continuity')::numeric,
            s.verification_fraud_snapshot_hash,
            'INVERTED_ACCEPTED_PROCESSOR_CONTINUITY_RESILIENCE'
        ),
        (
            'INDUSTRY_RELATIONSHIP_RISK',
            s.industry_risk_tier::numeric,
            s.industry_relationship_risk_score,
            (s.profile_payload ->> 'component_weight_industry_relationship')::numeric,
            md5(
                s.industry_code || '|' || s.industry_risk_tier::text
                || '|' || s.relationship_stage
            ),
            'GOVERNED_INDUSTRY_AND_RELATIONSHIP_CONTEXT'
        )
    ) AS v (
        component_code,
        component_source_value,
        component_risk_score,
        component_weight,
        source_lineage_hash,
        component_reason_code
    )
)
INSERT INTO _m1_12_component_expected (
    module1_run_id,
    scenario_id,
    merchant_application_id,
    component_code,
    component_version,
    component_source_value,
    component_risk_score,
    component_weight,
    weighted_risk_points,
    component_zone,
    component_status,
    directional_status,
    component_reason_code,
    source_lineage_hash,
    calculation_hash,
    created_by_run_id,
    created_at
)
SELECT
    module1_run_id,
    scenario_id,
    merchant_application_id,
    component_code,
    component_version,
    component_source_value,
    component_risk_score,
    component_weight,
    weighted_risk_points,
    component_zone,
    component_status,
    directional_status,
    component_reason_code,
    source_lineage_hash,
    'PENDING',
    module1_run_id,
    clock_timestamp()
FROM component_source;

UPDATE _m1_12_component_expected c
SET calculation_hash = msbf_m1.m1_12_hash_jsonb(
        to_jsonb(c) - 'calculation_hash' - 'created_at'
    )
WHERE c.calculation_hash = 'PENDING';

CREATE UNIQUE INDEX ON _m1_12_component_expected (
    module1_run_id,
    scenario_id,
    merchant_application_id,
    component_code,
    component_version
);
ANALYZE _m1_12_component_expected;

/* ---------------------------------------------------------------------------
5. Aggregate persisted weighted components and apply controlled risk floors
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.12 Phase 3/6 — aggregate persisted component points and apply matched stress interpretation';
END;
$notice$;

CREATE TEMP TABLE _m1_12_component_aggregate
ON COMMIT DROP AS
SELECT
    module1_run_id,
    scenario_id,
    merchant_application_id,
    count(*) AS component_count,
    count(weighted_risk_points) AS available_component_count,
    round(sum(weighted_risk_points), 6)::numeric(9,6) AS weighted_risk_sum,
    max(weighted_risk_points)
        FILTER (WHERE component_code = 'OPERATING_RESILIENCE_RISK')
            AS operating_weighted,
    max(weighted_risk_points)
        FILTER (WHERE component_code = 'CAPACITY_BURDEN_RISK')
            AS capacity_weighted,
    max(weighted_risk_points)
        FILTER (WHERE component_code = 'LIQUIDITY_RISK')
            AS liquidity_weighted,
    max(weighted_risk_points)
        FILTER (WHERE component_code = 'SOURCE_CONFIDENCE_RISK')
            AS source_weighted,
    max(weighted_risk_points)
        FILTER (WHERE component_code = 'VERIFICATION_FRAUD_RISK')
            AS verification_weighted,
    max(weighted_risk_points)
        FILTER (WHERE component_code = 'PROCESSOR_CONTINUITY_RISK')
            AS continuity_weighted,
    max(weighted_risk_points)
        FILTER (WHERE component_code = 'INDUSTRY_RELATIONSHIP_RISK')
            AS context_weighted
FROM _m1_12_component_expected
GROUP BY module1_run_id, scenario_id, merchant_application_id;

CREATE UNIQUE INDEX ON _m1_12_component_aggregate (
    scenario_id, merchant_application_id
);
ANALYZE _m1_12_component_aggregate;

CREATE TEMP TABLE _m1_12_independent
ON COMMIT DROP AS
WITH composite AS (
    SELECT
        s.*,
        a.component_count,
        a.available_component_count,
        a.weighted_risk_sum,
        a.operating_weighted,
        a.capacity_weighted,
        a.liquidity_weighted,
        a.source_weighted,
        a.verification_weighted,
        a.continuity_weighted,
        a.context_weighted,
        CASE
            WHEN s.evidence_status = 'BLOCKED'
              OR a.available_component_count <> 7
                THEN NULL
            ELSE a.weighted_risk_sum
        END AS independent_score
    FROM _m1_12_scored_input s
    JOIN _m1_12_component_aggregate a
      ON a.module1_run_id = s.module1_run_id
     AND a.scenario_id = s.scenario_id
     AND a.merchant_application_id = s.merchant_application_id
)
SELECT
    c.*,
    CASE
        WHEN c.evidence_status = 'BLOCKED'
          OR c.available_component_count <> 7
            THEN 'BLOCKED'
        ELSE c.evidence_status
    END AS effective_evidence_status,
    CASE
        WHEN c.independent_score IS NULL THEN NULL
        ELSE greatest(
            c.independent_score,
            CASE
                WHEN c.verification_hard_stop_flag
                  OR c.verification_disposition = 'STOP'
                    THEN (c.profile_payload ->> 'hard_stop_score_floor')::numeric
                WHEN c.fraud_risk_tier = 5
                    THEN (c.profile_payload ->> 'fraud_tier_5_score_floor')::numeric
                ELSE 0.0
            END
        )::numeric(9,6)
    END AS pre_stress_score,
    CASE
        WHEN c.independent_score IS NULL THEN 5
        WHEN c.independent_score < (c.profile_payload ->> 'risk_tier_1_max')::numeric THEN 1
        WHEN c.independent_score < (c.profile_payload ->> 'risk_tier_2_max')::numeric THEN 2
        WHEN c.independent_score < (c.profile_payload ->> 'risk_tier_3_max')::numeric THEN 3
        WHEN c.independent_score < (c.profile_payload ->> 'risk_tier_4_max')::numeric THEN 4
        ELSE 5
    END::smallint AS independent_tier
FROM composite c;

CREATE UNIQUE INDEX ON _m1_12_independent (scenario_id, merchant_application_id);
ANALYZE _m1_12_independent;

CREATE TEMP TABLE _m1_12_baseline
ON COMMIT DROP AS
SELECT
    merchant_application_id,
    pre_stress_score AS baseline_score,
    CASE
        WHEN pre_stress_score IS NULL THEN 5
        WHEN pre_stress_score < (profile_payload ->> 'risk_tier_1_max')::numeric THEN 1
        WHEN pre_stress_score < (profile_payload ->> 'risk_tier_2_max')::numeric THEN 2
        WHEN pre_stress_score < (profile_payload ->> 'risk_tier_3_max')::numeric THEN 3
        WHEN pre_stress_score < (profile_payload ->> 'risk_tier_4_max')::numeric THEN 4
        ELSE 5
    END::smallint AS baseline_tier
FROM _m1_12_independent
WHERE scenario_code = 'BASELINE';

CREATE UNIQUE INDEX ON _m1_12_baseline (merchant_application_id);

CREATE TEMP TABLE _m1_12_final
ON COMMIT DROP AS
WITH floored AS (
    SELECT
        i.*,
        b.baseline_score,
        b.baseline_tier,
        CASE
            WHEN i.effective_evidence_status = 'BLOCKED'
              OR i.pre_stress_score IS NULL
              OR b.baseline_score IS NULL
                THEN NULL
            WHEN i.scenario_code = 'RECESSION_ENERGY'
                THEN greatest(i.pre_stress_score, b.baseline_score)::numeric(9,6)
            ELSE i.pre_stress_score::numeric(9,6)
        END AS final_score
    FROM _m1_12_independent i
    JOIN _m1_12_baseline b USING (merchant_application_id)
),
classified AS (
    SELECT
        f.*,
        CASE
            WHEN f.final_score IS NULL THEN 5
            WHEN f.final_score < (f.profile_payload ->> 'risk_tier_1_max')::numeric THEN 1
            WHEN f.final_score < (f.profile_payload ->> 'risk_tier_2_max')::numeric THEN 2
            WHEN f.final_score < (f.profile_payload ->> 'risk_tier_3_max')::numeric THEN 3
            WHEN f.final_score < (f.profile_payload ->> 'risk_tier_4_max')::numeric THEN 4
            ELSE 5
        END::smallint AS final_tier
    FROM floored f
)
SELECT
    c.*,
    CASE
        WHEN c.effective_evidence_status = 'BLOCKED' THEN 'INSUFFICIENT_EVIDENCE'
        WHEN c.final_tier = 1 THEN 'LOW_RISK'
        WHEN c.final_tier = 2 THEN 'MODERATE_RISK'
        WHEN c.final_tier = 3 THEN 'ELEVATED_RISK'
        WHEN c.final_tier = 4 THEN 'HIGH_RISK'
        ELSE 'SEVERE_RISK'
    END AS final_status,
    (
        c.independent_score IS NOT NULL
        AND c.pre_stress_score IS DISTINCT FROM c.independent_score
    ) AS risk_floor_applied_flag,
    (
        c.scenario_code = 'RECESSION_ENERGY'
        AND c.final_score IS NOT NULL
        AND c.baseline_score IS NOT NULL
        AND (
            c.final_score > c.baseline_score + 0.000001
            OR c.final_tier > c.baseline_tier
        )
    ) AS stress_worsening_flag,
    (
        c.upstream_manual_review_flag
        OR c.verification_hard_stop_flag
        OR c.verification_disposition = 'STOP'
        OR c.effective_evidence_status <> 'COMPLETE'
        OR c.final_tier >= (c.profile_payload ->> 'manual_review_tier_min')::integer
    ) AS final_manual_review_flag,
    CASE
        WHEN c.effective_evidence_status = 'BLOCKED' THEN 'INSUFFICIENT_EVIDENCE'
        WHEN c.verification_hard_stop_flag OR c.verification_disposition = 'STOP'
            THEN 'VERIFICATION_STOP'
        WHEN c.verification_disposition = 'REVIEW' THEN 'VERIFICATION_REVIEW'
        WHEN c.fraud_risk_tier >= 4 THEN 'FRAUD_REVIEW'
        WHEN c.processor_continuity_risk_tier >= 4 THEN 'PROCESSOR_CONTINUITY_REVIEW'
        WHEN c.capacity_tier >= 4 THEN 'CAPACITY_REVIEW'
        WHEN c.data_confidence_tier IN ('LOW', 'REVIEW')
          OR c.source_confidence_score
                < (c.profile_payload ->> 'source_confidence_partial_threshold')::numeric
            THEN 'DATA_REFRESH'
        WHEN c.final_tier >= (c.profile_payload ->> 'manual_review_tier_min')::integer
            THEN 'MANUAL_RISK_REVIEW'
        ELSE 'NONE'
    END AS final_fallback_path,
    CASE
        WHEN c.effective_evidence_status = 'BLOCKED' THEN 'INSUFFICIENT_EVIDENCE'
        WHEN c.verification_hard_stop_flag OR c.verification_disposition = 'STOP'
            THEN 'VERIFICATION_HARD_STOP'
        WHEN coalesce(c.verification_weighted, -1) = greatest(
                coalesce(c.operating_weighted, -1),
                coalesce(c.capacity_weighted, -1),
                coalesce(c.liquidity_weighted, -1),
                coalesce(c.source_weighted, -1),
                coalesce(c.verification_weighted, -1),
                coalesce(c.continuity_weighted, -1),
                coalesce(c.context_weighted, -1)
            ) THEN 'VERIFICATION_FRAUD_RISK'
        WHEN coalesce(c.operating_weighted, -1) = greatest(
                coalesce(c.operating_weighted, -1),
                coalesce(c.capacity_weighted, -1),
                coalesce(c.liquidity_weighted, -1),
                coalesce(c.source_weighted, -1),
                coalesce(c.verification_weighted, -1),
                coalesce(c.continuity_weighted, -1),
                coalesce(c.context_weighted, -1)
            ) THEN 'OPERATING_RESILIENCE_RISK'
        WHEN coalesce(c.capacity_weighted, -1) = greatest(
                coalesce(c.operating_weighted, -1),
                coalesce(c.capacity_weighted, -1),
                coalesce(c.liquidity_weighted, -1),
                coalesce(c.source_weighted, -1),
                coalesce(c.verification_weighted, -1),
                coalesce(c.continuity_weighted, -1),
                coalesce(c.context_weighted, -1)
            ) THEN 'CAPACITY_BURDEN_RISK'
        WHEN coalesce(c.liquidity_weighted, -1) = greatest(
                coalesce(c.operating_weighted, -1),
                coalesce(c.capacity_weighted, -1),
                coalesce(c.liquidity_weighted, -1),
                coalesce(c.source_weighted, -1),
                coalesce(c.verification_weighted, -1),
                coalesce(c.continuity_weighted, -1),
                coalesce(c.context_weighted, -1)
            ) THEN 'LIQUIDITY_RISK'
        WHEN coalesce(c.source_weighted, -1) = greatest(
                coalesce(c.operating_weighted, -1),
                coalesce(c.capacity_weighted, -1),
                coalesce(c.liquidity_weighted, -1),
                coalesce(c.source_weighted, -1),
                coalesce(c.verification_weighted, -1),
                coalesce(c.continuity_weighted, -1),
                coalesce(c.context_weighted, -1)
            ) THEN 'SOURCE_CONFIDENCE_RISK'
        WHEN coalesce(c.continuity_weighted, -1) = greatest(
                coalesce(c.operating_weighted, -1),
                coalesce(c.capacity_weighted, -1),
                coalesce(c.liquidity_weighted, -1),
                coalesce(c.source_weighted, -1),
                coalesce(c.verification_weighted, -1),
                coalesce(c.continuity_weighted, -1),
                coalesce(c.context_weighted, -1)
            ) THEN 'PROCESSOR_CONTINUITY_RISK'
        ELSE 'INDUSTRY_RELATIONSHIP_RISK'
    END AS primary_reason,
    array_remove(
        ARRAY[
            CASE WHEN c.operating_resilience_risk_score >= 60
                THEN 'OPERATING_RESILIENCE_RISK' END,
            CASE WHEN c.capacity_burden_risk_score >= 60
                THEN 'CAPACITY_BURDEN_RISK' END,
            CASE WHEN c.liquidity_risk_score >= 60
                THEN 'LIQUIDITY_RISK' END,
            CASE WHEN c.source_confidence_risk_score >= 40
                THEN 'SOURCE_CONFIDENCE_RISK' END,
            CASE WHEN c.verification_fraud_risk_score >= 60
                THEN 'VERIFICATION_FRAUD_RISK' END,
            CASE WHEN c.processor_continuity_risk_score >= 60
                THEN 'PROCESSOR_CONTINUITY_RISK' END,
            CASE WHEN c.industry_relationship_risk_score >= 60
                THEN 'INDUSTRY_RELATIONSHIP_RISK' END,
            CASE WHEN c.verification_disposition = 'REVIEW'
                THEN 'VERIFICATION_REVIEW' END,
            CASE WHEN c.capacity_tier >= 4
                THEN 'CAPACITY_TIER_' || c.capacity_tier::text END,
            CASE WHEN c.archetype_risk_rank >= 4
                THEN 'ARCHETYPE_RISK_RANK_' || c.archetype_risk_rank::text END
        ]::text[],
        NULL
    ) AS secondary_reasons
FROM classified c;

CREATE UNIQUE INDEX ON _m1_12_final (scenario_id, merchant_application_id);
ANALYZE _m1_12_final;

/* ---------------------------------------------------------------------------
6. Persist typed snapshots and long-form components
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.12 Phase 4/6 — persist typed risk snapshots and component evidence';
END;
$notice$;

CREATE TEMP TABLE _m1_12_snapshot_expected
(LIKE msbf_m1.application_integrated_risk_proxy_snapshot INCLUDING DEFAULTS)
ON COMMIT DROP;

INSERT INTO _m1_12_snapshot_expected (
    module1_run_id,
    scenario_id,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    merchant_size_tier,
    industry_code,
    relationship_stage,
    operating_resilience_snapshot_hash,
    liquidity_capacity_snapshot_hash,
    verification_fraud_snapshot_hash,
    operating_resilience_evidence_status,
    capacity_evidence_status,
    data_confidence_tier,
    verification_disposition,
    fraud_risk_tier,
    processor_continuity_risk_tier,
    operating_resilience_tier,
    capacity_tier,
    archetype_code,
    archetype_risk_rank,
    operating_resilience_risk_score,
    capacity_burden_risk_score,
    liquidity_risk_score,
    source_confidence_risk_score,
    verification_fraud_risk_score,
    processor_continuity_risk_score,
    industry_relationship_risk_score,
    independent_integrated_risk_score,
    baseline_integrated_risk_score,
    integrated_risk_score,
    synthetic_merchant_risk_proxy,
    independent_risk_tier,
    baseline_risk_tier,
    integrated_risk_tier,
    stress_risk_worsening_flag,
    integrated_risk_status,
    integrated_risk_evidence_status,
    risk_floor_applied_flag,
    hard_stop_recommended_flag,
    manual_review_recommended_flag,
    fallback_path_code,
    primary_risk_reason_code,
    secondary_risk_reason_codes,
    row_hash,
    created_by_run_id,
    created_at
)
SELECT
    module1_run_id,
    scenario_id,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    merchant_size_tier,
    industry_code,
    relationship_stage,
    operating_resilience_snapshot_hash,
    liquidity_capacity_snapshot_hash,
    verification_fraud_snapshot_hash,
    operating_resilience_evidence_status,
    capacity_evidence_status,
    data_confidence_tier,
    verification_disposition,
    fraud_risk_tier,
    processor_continuity_risk_tier,
    operating_resilience_tier,
    capacity_tier,
    archetype_code,
    archetype_risk_rank,
    operating_resilience_risk_score,
    capacity_burden_risk_score,
    liquidity_risk_score,
    source_confidence_risk_score,
    verification_fraud_risk_score,
    processor_continuity_risk_score,
    industry_relationship_risk_score,
    independent_score::numeric(9,6),
    baseline_score::numeric(9,6),
    final_score::numeric(9,6),
    CASE
        WHEN final_score IS NULL THEN NULL
        ELSE round(final_score / 100.0, 8)::numeric(12,8)
    END,
    independent_tier,
    baseline_tier,
    final_tier,
    stress_worsening_flag,
    final_status,
    effective_evidence_status,
    risk_floor_applied_flag,
    (verification_hard_stop_flag OR verification_disposition = 'STOP'),
    final_manual_review_flag,
    final_fallback_path,
    primary_reason,
    secondary_reasons,
    'PENDING',
    module1_run_id,
    clock_timestamp()
FROM _m1_12_final;

UPDATE _m1_12_snapshot_expected s
SET row_hash = msbf_m1.m1_12_hash_jsonb(
        to_jsonb(s) - 'row_hash' - 'created_at'
    )
WHERE s.row_hash = 'PENDING';

CREATE UNIQUE INDEX ON _m1_12_snapshot_expected (
    module1_run_id, scenario_id, merchant_application_id
);

INSERT INTO msbf_m1.application_integrated_risk_proxy_snapshot (
    module1_run_id,
    scenario_id,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    merchant_size_tier,
    industry_code,
    relationship_stage,
    operating_resilience_snapshot_hash,
    liquidity_capacity_snapshot_hash,
    verification_fraud_snapshot_hash,
    operating_resilience_evidence_status,
    capacity_evidence_status,
    data_confidence_tier,
    verification_disposition,
    fraud_risk_tier,
    processor_continuity_risk_tier,
    operating_resilience_tier,
    capacity_tier,
    archetype_code,
    archetype_risk_rank,
    operating_resilience_risk_score,
    capacity_burden_risk_score,
    liquidity_risk_score,
    source_confidence_risk_score,
    verification_fraud_risk_score,
    processor_continuity_risk_score,
    industry_relationship_risk_score,
    independent_integrated_risk_score,
    baseline_integrated_risk_score,
    integrated_risk_score,
    synthetic_merchant_risk_proxy,
    independent_risk_tier,
    baseline_risk_tier,
    integrated_risk_tier,
    stress_risk_worsening_flag,
    integrated_risk_status,
    integrated_risk_evidence_status,
    risk_floor_applied_flag,
    hard_stop_recommended_flag,
    manual_review_recommended_flag,
    fallback_path_code,
    primary_risk_reason_code,
    secondary_risk_reason_codes,
    row_hash,
    created_by_run_id
)
SELECT
    module1_run_id,
    scenario_id,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    merchant_size_tier,
    industry_code,
    relationship_stage,
    operating_resilience_snapshot_hash,
    liquidity_capacity_snapshot_hash,
    verification_fraud_snapshot_hash,
    operating_resilience_evidence_status,
    capacity_evidence_status,
    data_confidence_tier,
    verification_disposition,
    fraud_risk_tier,
    processor_continuity_risk_tier,
    operating_resilience_tier,
    capacity_tier,
    archetype_code,
    archetype_risk_rank,
    operating_resilience_risk_score,
    capacity_burden_risk_score,
    liquidity_risk_score,
    source_confidence_risk_score,
    verification_fraud_risk_score,
    processor_continuity_risk_score,
    industry_relationship_risk_score,
    independent_integrated_risk_score,
    baseline_integrated_risk_score,
    integrated_risk_score,
    synthetic_merchant_risk_proxy,
    independent_risk_tier,
    baseline_risk_tier,
    integrated_risk_tier,
    stress_risk_worsening_flag,
    integrated_risk_status,
    integrated_risk_evidence_status,
    risk_floor_applied_flag,
    hard_stop_recommended_flag,
    manual_review_recommended_flag,
    fallback_path_code,
    primary_risk_reason_code,
    secondary_risk_reason_codes,
    row_hash,
    created_by_run_id
FROM _m1_12_snapshot_expected;

ANALYZE msbf_m1.application_integrated_risk_proxy_snapshot;

INSERT INTO msbf_m1.integrated_risk_component_value (
    module1_run_id,
    scenario_id,
    merchant_application_id,
    component_code,
    component_version,
    component_source_value,
    component_risk_score,
    component_weight,
    weighted_risk_points,
    component_zone,
    component_status,
    directional_status,
    component_reason_code,
    source_lineage_hash,
    calculation_hash,
    created_by_run_id
)
SELECT
    module1_run_id,
    scenario_id,
    merchant_application_id,
    component_code,
    component_version,
    component_source_value,
    component_risk_score,
    component_weight,
    weighted_risk_points,
    component_zone,
    component_status,
    directional_status,
    component_reason_code,
    source_lineage_hash,
    calculation_hash,
    created_by_run_id
FROM _m1_12_component_expected;

ANALYZE msbf_m1.integrated_risk_component_value;

/* ---------------------------------------------------------------------------
7. Reconcile the 12,000-entity canonical universe exactly once
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.12 Phase 5/6 — reconcile 12,000 canonical entities and set hashes';
END;
$notice$;

CREATE TEMP TABLE _m1_12_expected_canonical
ON COMMIT DROP AS
SELECT
    'RISK|' || scenario_id || '|' || merchant_application_id AS entity_key,
    row_hash
FROM _m1_12_snapshot_expected

UNION ALL

SELECT
    'COMPONENT|' || scenario_id || '|' || merchant_application_id
        || '|' || component_code || '|' || component_version,
    calculation_hash
FROM _m1_12_component_expected;

CREATE UNIQUE INDEX ON _m1_12_expected_canonical (entity_key);

CREATE TEMP TABLE _m1_12_actual_canonical
ON COMMIT DROP AS
SELECT *
FROM msbf_m1.m1_12_actual_snapshot((SELECT run_id FROM _m1_12_context))

UNION ALL

SELECT *
FROM msbf_m1.m1_12_actual_component((SELECT run_id FROM _m1_12_context));

CREATE UNIQUE INDEX ON _m1_12_actual_canonical (entity_key);

CREATE TEMP TABLE _m1_12_mismatch
ON COMMIT DROP AS
SELECT
    coalesce(e.entity_key, a.entity_key) AS entity_key,
    e.row_hash AS expected_hash,
    a.row_hash AS actual_hash
FROM _m1_12_expected_canonical e
FULL JOIN _m1_12_actual_canonical a USING (entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash;

CREATE TEMP TABLE _m1_12_hashes
ON COMMIT DROP AS
SELECT
    (SELECT count(*) FROM _m1_12_expected_canonical) AS expected_entities,
    (SELECT count(*) FROM _m1_12_actual_canonical) AS actual_entities,
    (SELECT count(*) FROM _m1_12_mismatch) AS mismatches,
    (
        SELECT md5(
            string_agg(entity_key || '|' || row_hash, '||' ORDER BY entity_key)
        )
        FROM _m1_12_expected_canonical
        WHERE entity_key LIKE 'RISK|%'
    ) AS snapshot_hash,
    (
        SELECT md5(
            string_agg(entity_key || '|' || row_hash, '||' ORDER BY entity_key)
        )
        FROM _m1_12_expected_canonical
        WHERE entity_key LIKE 'COMPONENT|%'
    ) AS component_hash,
    (
        SELECT md5(
            string_agg(entity_key || '|' || row_hash, '||' ORDER BY entity_key)
        )
        FROM _m1_12_expected_canonical
    ) AS combined_hash;

DO $reconcile$
DECLARE
    h record;
BEGIN
    SELECT * INTO h FROM _m1_12_hashes;

    IF h.expected_entities <> 12000
       OR h.actual_entities <> 12000
       OR h.mismatches <> 0 THEN
        RAISE EXCEPTION
            'M1.12 canonical reconciliation failed: expected %, actual %, mismatches %.',
            h.expected_entities, h.actual_entities, h.mismatches;
    END IF;
END;
$reconcile$;

/* ---------------------------------------------------------------------------
8. Persist governed generation evidence and advance run state
--------------------------------------------------------------------------- */
INSERT INTO msbf_ctl.run_evidence (
    run_id,
    evidence_code,
    segment_key,
    metric_name,
    metric_value_numeric,
    metric_value_text,
    unit_code,
    status,
    threshold_value_numeric,
    interpretation
)
SELECT
    c.run_id,
    v.evidence_code,
    'PORTFOLIO',
    v.metric_name,
    v.metric_value_numeric,
    v.metric_value_text,
    v.unit_code,
    'PASS',
    v.threshold_value_numeric,
    v.interpretation
FROM _m1_12_context c
CROSS JOIN LATERAL (
    VALUES
    (
        'M1_12_GENERATION_SPEC',
        'M1.12 generation specification',
        NULL::numeric,
        'M1_12_METHOD_V1',
        'TEXT',
        NULL::numeric,
        'Seven transparent risk components; composite is the sum of persisted weighted values; matched stress floors and explicit evidence routing.'
    ),
    (
        'M1_12_SNAPSHOT_ENTITY_COUNT',
        'M1.12 integrated risk snapshot rows',
        1500::numeric,
        NULL,
        'ROWS',
        1500::numeric,
        'Exactly two scenario-aware risk snapshots per accepted application.'
    ),
    (
        'M1_12_COMPONENT_ENTITY_COUNT',
        'M1.12 component rows',
        10500::numeric,
        NULL,
        'ROWS',
        10500::numeric,
        'Exactly seven component rows per snapshot.'
    ),
    (
        'M1_12_CANONICAL_ENTITY_COUNT',
        'M1.12 canonical entities',
        12000::numeric,
        NULL,
        'ROWS',
        12000::numeric,
        'Snapshot and component canonical universe.'
    ),
    (
        'M1_12_CANONICAL_MISMATCH_COUNT',
        'M1.12 deterministic mismatches',
        0::numeric,
        NULL,
        'ROWS',
        0::numeric,
        'Expected and persisted physical hashes reconcile.'
    ),
    (
        'M1_12_SNAPSHOT_SET_HASH',
        'M1.12 integrated risk snapshot set hash',
        NULL,
        (SELECT snapshot_hash FROM _m1_12_hashes),
        'HASH',
        NULL,
        'Governed deterministic snapshot identity.'
    ),
    (
        'M1_12_COMPONENT_SET_HASH',
        'M1.12 component set hash',
        NULL,
        (SELECT component_hash FROM _m1_12_hashes),
        'HASH',
        NULL,
        'Governed deterministic component identity.'
    ),
    (
        'M1_12_COMBINED_SET_HASH',
        'M1.12 combined set hash',
        NULL,
        (SELECT combined_hash FROM _m1_12_hashes),
        'HASH',
        NULL,
        'Combined M1.12 canonical identity.'
    ),
    (
        'M1_12_GENERATION_SUMMARY',
        'M1.12 generation summary',
        NULL,
        format(
            'snapshots=1500|components=10500|canonical=12000|mismatches=0|hash=%s',
            (SELECT combined_hash FROM _m1_12_hashes)
        ),
        'TEXT',
        NULL,
        'Committed M1.12 generation checkpoint.'
    )
) AS v (
    evidence_code,
    metric_name,
    metric_value_numeric,
    metric_value_text,
    unit_code,
    threshold_value_numeric,
    interpretation
)
ON CONFLICT (run_id, evidence_code, segment_key) DO UPDATE SET
    metric_name = EXCLUDED.metric_name,
    metric_value_numeric = EXCLUDED.metric_value_numeric,
    metric_value_text = EXCLUDED.metric_value_text,
    unit_code = EXCLUDED.unit_code,
    status = EXCLUDED.status,
    threshold_value_numeric = EXCLUDED.threshold_value_numeric,
    interpretation = EXCLUDED.interpretation,
    created_at = clock_timestamp();

UPDATE msbf_ctl.run_registry
SET run_status = 'M1_12_GENERATED',
    completed_at = NULL,
    notes = coalesce(notes, '')
        || E'\nM1.12 generated: 1,500 integrated risk snapshots and 10,500 component rows.'
WHERE run_id = (SELECT run_id FROM _m1_12_context);

COMMIT;

DO $notice$
BEGIN
    RAISE NOTICE 'M1.12 Phase 6/6 — committed generation checkpoint';
END;
$notice$;

SELECT
    r.run_id,
    r.run_status,
    (SELECT count(*)
     FROM msbf_m1.application_integrated_risk_proxy_snapshot
     WHERE module1_run_id = r.run_id) AS snapshot_rows,
    (SELECT count(*)
     FROM msbf_m1.integrated_risk_component_value
     WHERE module1_run_id = r.run_id) AS component_rows,
    (SELECT count(DISTINCT merchant_application_id)
     FROM msbf_m1.application_integrated_risk_proxy_snapshot
     WHERE module1_run_id = r.run_id) AS applications,
    (SELECT count(DISTINCT scenario_id)
     FROM msbf_m1.application_integrated_risk_proxy_snapshot
     WHERE module1_run_id = r.run_id) AS scenarios,
    (SELECT metric_value_numeric::bigint
     FROM msbf_ctl.run_evidence
     WHERE run_id = r.run_id
       AND evidence_code = 'M1_12_CANONICAL_MISMATCH_COUNT'
       AND segment_key = 'PORTFOLIO') AS row_level_mismatches,
    (SELECT metric_value_text
     FROM msbf_ctl.run_evidence
     WHERE run_id = r.run_id
       AND evidence_code = 'M1_12_SNAPSHOT_SET_HASH'
       AND segment_key = 'PORTFOLIO') AS snapshot_hash,
    (SELECT metric_value_text
     FROM msbf_ctl.run_evidence
     WHERE run_id = r.run_id
       AND evidence_code = 'M1_12_COMPONENT_SET_HASH'
       AND segment_key = 'PORTFOLIO') AS component_hash,
    (SELECT metric_value_text
     FROM msbf_ctl.run_evidence
     WHERE run_id = r.run_id
       AND evidence_code = 'M1_12_COMBINED_SET_HASH'
       AND segment_key = 'PORTFOLIO') AS combined_hash,
    CASE
        WHEN r.run_status = 'M1_12_GENERATED'
         AND (SELECT count(*)
              FROM msbf_m1.application_integrated_risk_proxy_snapshot
              WHERE module1_run_id = r.run_id) = 1500
         AND (SELECT count(*)
              FROM msbf_m1.integrated_risk_component_value
              WHERE module1_run_id = r.run_id) = 10500
         AND (SELECT metric_value_numeric
              FROM msbf_ctl.run_evidence
              WHERE run_id = r.run_id
                AND evidence_code = 'M1_12_CANONICAL_MISMATCH_COUNT'
                AND segment_key = 'PORTFOLIO') = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS generation_status
FROM msbf_ctl.run_registry r
WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND r.run_version = 1;
