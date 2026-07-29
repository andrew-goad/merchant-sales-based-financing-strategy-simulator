/* ============================================================================
MSBF M1.12 Merchant Risk Components & Integrated Risk Proxy — Positive Validation
Version : v0.2
Purpose : Validate predecessor acceptance, scenario scope, transparent component
          identities, evidence gating, score/tier/routing logic, matched stress
          floors, deterministic hashes, and strict stage boundaries.
Mode    : Persists exactly 80 governed positive-control records and advances the
          run to M1_12_VALIDATED only when every control passes.
Output  : One filterable 80-row result set. The session-scoped result table is
          preserved after COMMIT for sorting and filtering in DBeaver.
============================================================================ */

BEGIN;

SET LOCAL work_mem = '64MB';
SET LOCAL jit = off;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '15min';

/* ---------------------------------------------------------------------------
1. Session-scoped validation inputs
--------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m1_12_vrun;
DROP TABLE IF EXISTS _m1_12_vgates;
DROP TABLE IF EXISTS _m1_12_vpolicy;
DROP TABLE IF EXISTS _m1_12_vscope;
DROP TABLE IF EXISTS _m1_12_vlineage;
DROP TABLE IF EXISTS _m1_12_vr;
DROP TABLE IF EXISTS _m1_12_vc;
DROP TABLE IF EXISTS _m1_12_vca;
DROP TABLE IF EXISTS _m1_12_vwide_long;
DROP TABLE IF EXISTS _m1_12_vupstream;
DROP TABLE IF EXISTS _m1_12_vmatched;
DROP TABLE IF EXISTS _m1_12_vcomposite;
DROP TABLE IF EXISTS _m1_12_vfloor;
DROP TABLE IF EXISTS _m1_12_vactual;
DROP TABLE IF EXISTS _m1_12_vhash;
DROP TABLE IF EXISTS _m1_12_vboundary;
DROP TABLE IF EXISTS _m1_12_validation;

CREATE TEMP TABLE _m1_12_vrun ON COMMIT DROP AS
SELECT run_id,run_status,population_id,as_of_date,
       parameter_snapshot_hash,profile_snapshot_hash,source_snapshot_hash
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

CREATE TEMP TABLE _m1_12_vgates ON COMMIT DROP AS
SELECT DISTINCT ON (gate_id) gate_id,result_status,review_version
FROM msbf_ctl.acceptance_gate_result
WHERE run_id=(SELECT run_id FROM _m1_12_vrun)
ORDER BY gate_id,review_version DESC;

CREATE TEMP TABLE _m1_12_vpolicy ON COMMIT DROP AS
SELECT status,
       profile_payload,
       profile_payload->>'methodology_version' AS methodology_version,
       profile_payload->>'composite_score_basis' AS composite_score_basis,
       (profile_payload->>'component_weight_operating_resilience')::numeric
       +(profile_payload->>'component_weight_capacity_burden')::numeric
       +(profile_payload->>'component_weight_liquidity')::numeric
       +(profile_payload->>'component_weight_source_confidence')::numeric
       +(profile_payload->>'component_weight_verification_fraud')::numeric
       +(profile_payload->>'component_weight_processor_continuity')::numeric
       +(profile_payload->>'component_weight_industry_relationship')::numeric AS component_weight_sum,
       (profile_payload->>'risk_tier_1_max')::numeric AS tier_1_max,
       (profile_payload->>'risk_tier_2_max')::numeric AS tier_2_max,
       (profile_payload->>'risk_tier_3_max')::numeric AS tier_3_max,
       (profile_payload->>'risk_tier_4_max')::numeric AS tier_4_max,
       (profile_payload->>'component_zone_low_max')::numeric AS zone_low_max,
       (profile_payload->>'component_zone_moderate_max')::numeric AS zone_moderate_max,
       (profile_payload->>'component_zone_elevated_max')::numeric AS zone_elevated_max,
       (profile_payload->>'hard_stop_score_floor')::numeric AS hard_stop_score_floor,
       (profile_payload->>'fraud_tier_5_score_floor')::numeric AS fraud_tier_5_score_floor,
       (profile_payload->>'manual_review_tier_min')::integer AS manual_review_tier_min,
       (profile_payload->>'source_confidence_partial_threshold')::numeric AS source_confidence_partial_threshold,
       (profile_payload->>'stress_risk_score_floor_to_baseline')::boolean AS score_floor_enabled,
       (profile_payload->>'stress_risk_tier_floor_to_baseline')::boolean AS tier_floor_enabled
FROM msbf_ctl.policy_profile
WHERE profile_code='M1_12_INTEGRATED_RISK_PROXY' AND profile_version=1;

CREATE TEMP TABLE _m1_12_vscope ON COMMIT DROP AS
SELECT count(DISTINCT r.scenario_id) AS scenario_count,
       count(DISTINCT r.scenario_id) FILTER(WHERE sr.scenario_code='BASELINE') AS baseline_count,
       count(DISTINCT r.scenario_id) FILTER(WHERE sr.scenario_code='RECESSION_ENERGY') AS stress_count
FROM msbf_m1.application_integrated_risk_proxy_snapshot r
JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
WHERE r.module1_run_id=(SELECT run_id FROM _m1_12_vrun)
  AND ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS'
  AND ss.scenario_set_version=1 AND ss.status='APPROVED'
  AND sr.status='APPROVED' AND sr.scenario_version=1
  AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY');

CREATE TEMP TABLE _m1_12_vlineage ON COMMIT DROP AS
SELECT r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,
       (SELECT population_hash FROM msbf_m1.population_registry WHERE population_id=r.population_id) AS population_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') AS application_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_4_POS_SET_HASH' AND segment_key='PORTFOLIO') AS pos_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_5_DEPOSIT_SET_HASH' AND segment_key='PORTFOLIO') AS deposit_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_6_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS scenario_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_7_SOURCE_SET_HASH' AND segment_key='PORTFOLIO') AS source_quality_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_8_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS verification_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_9_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS cashflow_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_10_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS capacity_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_11_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS resilience_hash
FROM _m1_12_vrun r;

CREATE TEMP TABLE _m1_12_vr ON COMMIT DROP AS
SELECT r.*,sr.scenario_code
FROM msbf_m1.application_integrated_risk_proxy_snapshot r
JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
WHERE r.module1_run_id=(SELECT run_id FROM _m1_12_vrun);
CREATE UNIQUE INDEX ON _m1_12_vr(scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_12_vc ON COMMIT DROP AS
SELECT * FROM msbf_m1.integrated_risk_component_value
WHERE module1_run_id=(SELECT run_id FROM _m1_12_vrun);
CREATE UNIQUE INDEX ON _m1_12_vc(scenario_id,merchant_application_id,component_code,component_version);

CREATE TEMP TABLE _m1_12_vca ON COMMIT DROP AS
SELECT module1_run_id,scenario_id,merchant_application_id,
       count(*) AS component_count,
       count(weighted_risk_points) AS available_component_count,
       round(sum(component_weight),6) AS weight_sum,
       round(sum(weighted_risk_points),6)::numeric(9,6) AS weighted_sum,
       max(component_risk_score) FILTER(WHERE component_code='OPERATING_RESILIENCE_RISK') AS operating_score,
       max(component_risk_score) FILTER(WHERE component_code='CAPACITY_BURDEN_RISK') AS capacity_score,
       max(component_risk_score) FILTER(WHERE component_code='LIQUIDITY_RISK') AS liquidity_score,
       max(component_risk_score) FILTER(WHERE component_code='SOURCE_CONFIDENCE_RISK') AS source_score,
       max(component_risk_score) FILTER(WHERE component_code='VERIFICATION_FRAUD_RISK') AS verification_score,
       max(component_risk_score) FILTER(WHERE component_code='PROCESSOR_CONTINUITY_RISK') AS continuity_score,
       max(component_risk_score) FILTER(WHERE component_code='INDUSTRY_RELATIONSHIP_RISK') AS context_score
FROM _m1_12_vc
GROUP BY module1_run_id,scenario_id,merchant_application_id;
CREATE UNIQUE INDEX ON _m1_12_vca(scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_12_vwide_long ON COMMIT DROP AS
SELECT r.scenario_id,r.merchant_application_id,
       ((r.operating_resilience_risk_score IS DISTINCT FROM a.operating_score)::integer
       +(r.capacity_burden_risk_score IS DISTINCT FROM a.capacity_score)::integer
       +(r.liquidity_risk_score IS DISTINCT FROM a.liquidity_score)::integer
       +(r.source_confidence_risk_score IS DISTINCT FROM a.source_score)::integer
       +(r.verification_fraud_risk_score IS DISTINCT FROM a.verification_score)::integer
       +(r.processor_continuity_risk_score IS DISTINCT FROM a.continuity_score)::integer
       +(r.industry_relationship_risk_score IS DISTINCT FROM a.context_score)::integer) AS wide_long_mismatch_count
FROM _m1_12_vr r JOIN _m1_12_vca a USING(module1_run_id,scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_12_vupstream ON COMMIT DROP AS
SELECT r.*,
       o.operating_resilience_evidence_status AS up_operating_evidence,
       o.source_confidence_score AS up_source_confidence_score,
       o.manual_review_recommended_flag AS up_resilience_manual_review,
       o.row_hash AS up_resilience_hash,
       c.capacity_evidence_status AS up_capacity_evidence,
       c.manual_review_recommended_flag AS up_capacity_manual_review,
       c.row_hash AS up_capacity_hash,
       v.verification_disposition AS up_verification_disposition,
       v.hard_stop_recommended_flag AS up_verification_hard_stop,
       v.manual_review_recommended_flag AS up_verification_manual_review,
       v.row_hash AS up_verification_hash,
       a.available_component_count
FROM _m1_12_vr r
JOIN msbf_m1.application_operating_resilience_snapshot o USING(module1_run_id,scenario_id,merchant_application_id)
JOIN msbf_m1.application_liquidity_capacity_snapshot c USING(module1_run_id,scenario_id,merchant_application_id)
JOIN msbf_m1.application_verification_fraud_snapshot v USING(module1_run_id,merchant_application_id)
JOIN _m1_12_vca a USING(module1_run_id,scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_12_vmatched ON COMMIT DROP AS
SELECT r.*,b.integrated_risk_score AS matched_baseline_score,b.integrated_risk_tier AS matched_baseline_tier
FROM _m1_12_vr r
JOIN _m1_12_vr b ON b.merchant_application_id=r.merchant_application_id AND b.scenario_code='BASELINE';

CREATE TEMP TABLE _m1_12_vcomposite ON COMMIT DROP AS
SELECT r.scenario_id,r.merchant_application_id,r.integrated_risk_evidence_status,
       r.independent_integrated_risk_score,r.baseline_integrated_risk_score,r.integrated_risk_score,
       a.weighted_sum,
       CASE WHEN r.integrated_risk_evidence_status='BLOCKED' THEN NULL
            WHEN r.scenario_code='RECESSION_ENERGY' THEN greatest(
                 greatest(a.weighted_sum,CASE WHEN r.hard_stop_recommended_flag THEN p.hard_stop_score_floor WHEN r.fraud_risk_tier=5 THEN p.fraud_tier_5_score_floor ELSE 0 END),
                 r.baseline_integrated_risk_score)
            ELSE greatest(a.weighted_sum,CASE WHEN r.hard_stop_recommended_flag THEN p.hard_stop_score_floor WHEN r.fraud_risk_tier=5 THEN p.fraud_tier_5_score_floor ELSE 0 END)
       END::numeric(9,6) AS expected_final_score,
       r.integrated_risk_score IS DISTINCT FROM CASE WHEN r.integrated_risk_evidence_status='BLOCKED' THEN NULL
            WHEN r.scenario_code='RECESSION_ENERGY' THEN greatest(
                 greatest(a.weighted_sum,CASE WHEN r.hard_stop_recommended_flag THEN p.hard_stop_score_floor WHEN r.fraud_risk_tier=5 THEN p.fraud_tier_5_score_floor ELSE 0 END),
                 r.baseline_integrated_risk_score)
            ELSE greatest(a.weighted_sum,CASE WHEN r.hard_stop_recommended_flag THEN p.hard_stop_score_floor WHEN r.fraud_risk_tier=5 THEN p.fraud_tier_5_score_floor ELSE 0 END)
       END::numeric(9,6) AS final_score_mismatch
FROM _m1_12_vr r JOIN _m1_12_vca a USING(module1_run_id,scenario_id,merchant_application_id)
CROSS JOIN _m1_12_vpolicy p;

CREATE TEMP TABLE _m1_12_vfloor ON COMMIT DROP AS
SELECT r.scenario_id,r.merchant_application_id,r.risk_floor_applied_flag,
       (r.independent_integrated_risk_score IS NOT NULL AND
        greatest(r.independent_integrated_risk_score,CASE WHEN r.hard_stop_recommended_flag THEN p.hard_stop_score_floor WHEN r.fraud_risk_tier=5 THEN p.fraud_tier_5_score_floor ELSE 0 END)
        IS DISTINCT FROM r.independent_integrated_risk_score) AS expected_floor_flag
FROM _m1_12_vr r CROSS JOIN _m1_12_vpolicy p;

CREATE TEMP TABLE _m1_12_vactual ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_12_actual_snapshot((SELECT run_id FROM _m1_12_vrun))
UNION ALL
SELECT * FROM msbf_m1.m1_12_actual_component((SELECT run_id FROM _m1_12_vrun));
CREATE UNIQUE INDEX ON _m1_12_vactual(entity_key);

CREATE TEMP TABLE _m1_12_vhash ON COMMIT DROP AS
WITH stored AS (
 SELECT max(metric_value_numeric) FILTER(WHERE evidence_code='M1_12_CANONICAL_ENTITY_COUNT') AS stored_canonical_entities,
        max(metric_value_numeric) FILTER(WHERE evidence_code='M1_12_CANONICAL_MISMATCH_COUNT') AS stored_mismatches,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_12_SNAPSHOT_SET_HASH') AS stored_snapshot_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_12_COMPONENT_SET_HASH') AS stored_component_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_12_COMBINED_SET_HASH') AS stored_combined_hash,
        count(*) FILTER(WHERE evidence_code IN ('M1_12_GENERATION_SPEC','M1_12_SNAPSHOT_ENTITY_COUNT','M1_12_COMPONENT_ENTITY_COUNT','M1_12_CANONICAL_ENTITY_COUNT','M1_12_CANONICAL_MISMATCH_COUNT','M1_12_SNAPSHOT_SET_HASH','M1_12_COMPONENT_SET_HASH','M1_12_COMBINED_SET_HASH','M1_12_GENERATION_SUMMARY')) AS generation_evidence_rows
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_12_vrun)
), actual AS (
 SELECT count(*) AS canonical_entities,
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM _m1_12_vactual WHERE entity_key LIKE 'RISK|%') AS snapshot_hash,
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM _m1_12_vactual WHERE entity_key LIKE 'COMPONENT|%') AS component_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash
 FROM _m1_12_vactual)
SELECT a.*,s.* FROM actual a CROSS JOIN stored s;

CREATE TEMP TABLE _m1_12_vboundary ON COMMIT DROP AS
SELECT (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_12_vrun))
      +(SELECT count(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM _m1_12_vrun))
      +(SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_12_vrun))
      +(SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM _m1_12_vrun))
      +(SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM _m1_12_vrun)) AS downstream_rows,
       (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_12_vrun) AND severity='BLOCKING') AS blocking_errors;

ANALYZE _m1_12_vr; ANALYZE _m1_12_vc; ANALYZE _m1_12_vca;
ANALYZE _m1_12_vupstream; ANALYZE _m1_12_vactual;

/* ---------------------------------------------------------------------------
2. Execute the 80 governed positive controls
--------------------------------------------------------------------------- */
CREATE TEMP TABLE _m1_12_validation (
    evidence_code text PRIMARY KEY,
    metric_name text NOT NULL,
    observed_value text,
    threshold_value text,
    status text NOT NULL,
    interpretation text NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m1_12_add_check(
    p_code text,
    p_name text,
    p_pass boolean,
    p_observed text,
    p_threshold text,
    p_interpretation text
)
RETURNS void LANGUAGE plpgsql AS $fn$
BEGIN
    INSERT INTO _m1_12_validation(
        evidence_code,metric_name,observed_value,threshold_value,status,interpretation
    ) VALUES (
        p_code,p_name,p_observed,p_threshold,
        CASE WHEN coalesce(p_pass,false) THEN 'PASS' ELSE 'FAIL' END,
        p_interpretation
    );
END;
$fn$;

DO $checks$
BEGIN
    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_01_RUN_STATUS',
        'Run status is M1_12_GENERATED',
        ((SELECT run_status='M1_12_GENERATED' FROM _m1_12_vrun)),
        ((SELECT run_status FROM _m1_12_vrun)),
        'M1_12_GENERATED',
        'Validation begins only from the committed M1.12 generation checkpoint.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_02_G1_CONTROL_PLANE',
        'Accepted predecessor gate G1_CONTROL_PLANE',
        (coalesce((SELECT result_status='PASS' FROM _m1_12_vgates WHERE gate_id='G1_CONTROL_PLANE'),false)),
        (coalesce((SELECT result_status FROM _m1_12_vgates WHERE gate_id='G1_CONTROL_PLANE'),'MISSING')),
        'PASS',
        'The latest governed predecessor gate must remain accepted.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_03_M1_2_POPULATION',
        'Accepted predecessor gate M1_2_POPULATION',
        (coalesce((SELECT result_status='PASS' FROM _m1_12_vgates WHERE gate_id='M1_2_POPULATION'),false)),
        (coalesce((SELECT result_status FROM _m1_12_vgates WHERE gate_id='M1_2_POPULATION'),'MISSING')),
        'PASS',
        'The latest governed predecessor gate must remain accepted.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_04_M1_3_APPLICATION_REQUEST',
        'Accepted predecessor gate M1_3_APPLICATION_REQUEST',
        (coalesce((SELECT result_status='PASS' FROM _m1_12_vgates WHERE gate_id='M1_3_APPLICATION_REQUEST'),false)),
        (coalesce((SELECT result_status FROM _m1_12_vgates WHERE gate_id='M1_3_APPLICATION_REQUEST'),'MISSING')),
        'PASS',
        'The latest governed predecessor gate must remain accepted.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_05_M1_4_DAILY_POS_HISTORY',
        'Accepted predecessor gate M1_4_DAILY_POS_HISTORY',
        (coalesce((SELECT result_status='PASS' FROM _m1_12_vgates WHERE gate_id='M1_4_DAILY_POS_HISTORY'),false)),
        (coalesce((SELECT result_status FROM _m1_12_vgates WHERE gate_id='M1_4_DAILY_POS_HISTORY'),'MISSING')),
        'PASS',
        'The latest governed predecessor gate must remain accepted.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_06_M1_5_DAILY_DEPOSIT_LIQUIDITY',
        'Accepted predecessor gate M1_5_DAILY_DEPOSIT_LIQUIDITY',
        (coalesce((SELECT result_status='PASS' FROM _m1_12_vgates WHERE gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY'),false)),
        (coalesce((SELECT result_status FROM _m1_12_vgates WHERE gate_id='M1_5_DAILY_DEPOSIT_LIQUIDITY'),'MISSING')),
        'PASS',
        'The latest governed predecessor gate must remain accepted.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_07_M1_6_MATCHED_SCENARIO_OVERLAYS',
        'Accepted predecessor gate M1_6_MATCHED_SCENARIO_OVERLAYS',
        (coalesce((SELECT result_status='PASS' FROM _m1_12_vgates WHERE gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS'),false)),
        (coalesce((SELECT result_status FROM _m1_12_vgates WHERE gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS'),'MISSING')),
        'PASS',
        'The latest governed predecessor gate must remain accepted.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_08_M1_7_SOURCE_QUALITY_CONFIDENCE',
        'Accepted predecessor gate M1_7_SOURCE_QUALITY_CONFIDENCE',
        (coalesce((SELECT result_status='PASS' FROM _m1_12_vgates WHERE gate_id='M1_7_SOURCE_QUALITY_CONFIDENCE'),false)),
        (coalesce((SELECT result_status FROM _m1_12_vgates WHERE gate_id='M1_7_SOURCE_QUALITY_CONFIDENCE'),'MISSING')),
        'PASS',
        'The latest governed predecessor gate must remain accepted.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_09_M1_8_VERIFICATION_FRAUD_CONTINUITY',
        'Accepted predecessor gate M1_8_VERIFICATION_FRAUD_CONTINUITY',
        (coalesce((SELECT result_status='PASS' FROM _m1_12_vgates WHERE gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY'),false)),
        (coalesce((SELECT result_status FROM _m1_12_vgates WHERE gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY'),'MISSING')),
        'PASS',
        'The latest governed predecessor gate must remain accepted.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_10_M1_9_ASOF_CASHFLOW_FEATURES',
        'Accepted predecessor gate M1_9_ASOF_CASHFLOW_FEATURES',
        (coalesce((SELECT result_status='PASS' FROM _m1_12_vgates WHERE gate_id='M1_9_ASOF_CASHFLOW_FEATURES'),false)),
        (coalesce((SELECT result_status FROM _m1_12_vgates WHERE gate_id='M1_9_ASOF_CASHFLOW_FEATURES'),'MISSING')),
        'PASS',
        'The latest governed predecessor gate must remain accepted.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_11_M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY',
        'Accepted predecessor gate M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY',
        (coalesce((SELECT result_status='PASS' FROM _m1_12_vgates WHERE gate_id='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY'),false)),
        (coalesce((SELECT result_status FROM _m1_12_vgates WHERE gate_id='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY'),'MISSING')),
        'PASS',
        'The latest governed predecessor gate must remain accepted.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_12_M1_11_CASHFLOW_ARCHETYPE_RESILIENCE',
        'Accepted predecessor gate M1_11_CASHFLOW_ARCHETYPE_RESILIENCE',
        (coalesce((SELECT result_status='PASS' FROM _m1_12_vgates WHERE gate_id='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE'),false)),
        (coalesce((SELECT result_status FROM _m1_12_vgates WHERE gate_id='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE'),'MISSING')),
        'PASS',
        'The latest governed predecessor gate must remain accepted.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_13_PARAMETER_HASH',
        'Accepted parameter hash',
        ((SELECT parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8' FROM _m1_12_vlineage)),
        (coalesce((SELECT parameter_snapshot_hash FROM _m1_12_vlineage),'NULL')),
        'bd09e598c82db96e47459d77fd11e7c8',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_14_PROFILE_HASH',
        'Accepted profile hash',
        ((SELECT profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973' FROM _m1_12_vlineage)),
        (coalesce((SELECT profile_snapshot_hash FROM _m1_12_vlineage),'NULL')),
        '462cbd2ed92f68e5bdecf6b17537a973',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_15_SOURCE_HASH',
        'Accepted source hash',
        ((SELECT source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3' FROM _m1_12_vlineage)),
        (coalesce((SELECT source_snapshot_hash FROM _m1_12_vlineage),'NULL')),
        '93c3d1368fb2450ab4a08e2b721f92d3',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_16_POPULATION_HASH',
        'Accepted population hash',
        ((SELECT population_hash='9b706c926260a3ef1ae8ac95eed5d0bf' FROM _m1_12_vlineage)),
        (coalesce((SELECT population_hash FROM _m1_12_vlineage),'NULL')),
        '9b706c926260a3ef1ae8ac95eed5d0bf',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_17_APPLICATION_HASH',
        'Accepted application hash',
        ((SELECT application_hash='01485256b9b5748fb412743d35ced602' FROM _m1_12_vlineage)),
        (coalesce((SELECT application_hash FROM _m1_12_vlineage),'NULL')),
        '01485256b9b5748fb412743d35ced602',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_18_POS_HISTORY_HASH',
        'Accepted pos history hash',
        ((SELECT pos_hash='d1971e8d319483c187ec0c0483a31e33' FROM _m1_12_vlineage)),
        (coalesce((SELECT pos_hash FROM _m1_12_vlineage),'NULL')),
        'd1971e8d319483c187ec0c0483a31e33',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_19_DEPOSIT_HISTORY_HASH',
        'Accepted deposit history hash',
        ((SELECT deposit_hash='bbe96dd24fbbba3af4a587dd475a88d0' FROM _m1_12_vlineage)),
        (coalesce((SELECT deposit_hash FROM _m1_12_vlineage),'NULL')),
        'bbe96dd24fbbba3af4a587dd475a88d0',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_20_SCENARIO_SET_HASH',
        'Accepted scenario set hash',
        ((SELECT scenario_hash='3f85921bf6fc30ddc6cee146085e58c5' FROM _m1_12_vlineage)),
        (coalesce((SELECT scenario_hash FROM _m1_12_vlineage),'NULL')),
        '3f85921bf6fc30ddc6cee146085e58c5',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_21_SOURCE_QUALITY_HASH',
        'Accepted source quality hash',
        ((SELECT source_quality_hash='de56a458d9ec0b344886850592c4e6c8' FROM _m1_12_vlineage)),
        (coalesce((SELECT source_quality_hash FROM _m1_12_vlineage),'NULL')),
        'de56a458d9ec0b344886850592c4e6c8',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_22_VERIFICATION_HASH',
        'Accepted verification hash',
        ((SELECT verification_hash='604a5640a25da92a850840dbe13e3d56' FROM _m1_12_vlineage)),
        (coalesce((SELECT verification_hash FROM _m1_12_vlineage),'NULL')),
        '604a5640a25da92a850840dbe13e3d56',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_23_CASHFLOW_HASH',
        'Accepted cashflow hash',
        ((SELECT cashflow_hash='7c25acac533179f42789a6daa79d0cc3' FROM _m1_12_vlineage)),
        (coalesce((SELECT cashflow_hash FROM _m1_12_vlineage),'NULL')),
        '7c25acac533179f42789a6daa79d0cc3',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_24_CAPACITY_HASH',
        'Accepted capacity hash',
        ((SELECT capacity_hash='a91e82a315305a98953d013043a17d9a' FROM _m1_12_vlineage)),
        (coalesce((SELECT capacity_hash FROM _m1_12_vlineage),'NULL')),
        'a91e82a315305a98953d013043a17d9a',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_25_RESILIENCE_HASH',
        'Accepted resilience hash',
        ((SELECT resilience_hash='d219b2a0cb6d32f400b1ab71be6521fb' FROM _m1_12_vlineage)),
        (coalesce((SELECT resilience_hash FROM _m1_12_vlineage),'NULL')),
        'd219b2a0cb6d32f400b1ab71be6521fb',
        'Accepted upstream identity must remain unchanged.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_26_POLICY_APPROVED',
        'M1.12 policy profile is approved',
        ((SELECT status='APPROVED' FROM _m1_12_vpolicy)),
        ((SELECT status FROM _m1_12_vpolicy)),
        'APPROVED',
        'The active methodology must be formally approved.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_27_METHODOLOGY_VERSION',
        'M1.12 methodology version',
        ((SELECT methodology_version='M1_12_METHOD_V1' FROM _m1_12_vpolicy)),
        ((SELECT methodology_version FROM _m1_12_vpolicy)),
        'M1_12_METHOD_V1',
        'The accepted transparent proxy methodology is version controlled.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_28_COMPOSITE_BASIS',
        'Composite uses persisted weighted risk points',
        ((SELECT composite_score_basis='SUM_PERSISTED_WEIGHTED_RISK_COMPONENTS' FROM _m1_12_vpolicy)),
        ((SELECT composite_score_basis FROM _m1_12_vpolicy)),
        'SUM_PERSISTED_WEIGHTED_RISK_COMPONENTS',
        'Visible wide and long component evidence must reconcile exactly.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_29_COMPONENT_WEIGHT_SUM',
        'Component weights sum to one',
        ((SELECT abs(component_weight_sum-1.0)<=0.0000001 FROM _m1_12_vpolicy)),
        ((SELECT component_weight_sum::text FROM _m1_12_vpolicy)),
        '1.000000',
        'Governed component weights must exhaust the composite score.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_30_TIER_THRESHOLD_ORDER',
        'Risk-tier thresholds are strictly increasing',
        ((SELECT tier_1_max<tier_2_max AND tier_2_max<tier_3_max AND tier_3_max<tier_4_max FROM _m1_12_vpolicy)),
        ((SELECT concat_ws('|',tier_1_max,tier_2_max,tier_3_max,tier_4_max) FROM _m1_12_vpolicy)),
        'strictly increasing',
        'Tier thresholds must preserve ordinal risk ordering.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_31_STRESS_FLOORS_ENABLED',
        'Matched stress non-improvement floors are enabled',
        ((SELECT score_floor_enabled AND tier_floor_enabled FROM _m1_12_vpolicy)),
        ((SELECT format('score=%s|tier=%s',score_floor_enabled,tier_floor_enabled) FROM _m1_12_vpolicy)),
        'score=true|tier=true',
        'Adverse stress interpretation may not improve score or tier.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_32_SCENARIO_SCOPE',
        'Exactly one approved baseline and one approved stress scenario',
        ((SELECT scenario_count=2 AND baseline_count=1 AND stress_count=1 FROM _m1_12_vscope)),
        ((SELECT format('scenarios=%s|baseline=%s|stress=%s',scenario_count,baseline_count,stress_count) FROM _m1_12_vscope)),
        '2|1|1',
        'M1.12 must use the accepted M1.6 matched scenario set only.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_33_SNAPSHOT_COUNT',
        'Integrated risk snapshot row count',
        ((SELECT count(*)=1500 FROM _m1_12_vr)),
        ((SELECT count(*)::text FROM _m1_12_vr)),
        '1500',
        'Two scenario-aware snapshots per accepted application are required.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_34_COMPONENT_COUNT',
        'Integrated risk component row count',
        ((SELECT count(*)=10500 FROM _m1_12_vc)),
        ((SELECT count(*)::text FROM _m1_12_vc)),
        '10500',
        'Seven components per 1,500 snapshots are required.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_35_APPLICATION_COUNT',
        'Application coverage',
        ((SELECT count(DISTINCT merchant_application_id)=750 FROM _m1_12_vr)),
        ((SELECT count(DISTINCT merchant_application_id)::text FROM _m1_12_vr)),
        '750',
        'All accepted applications must be represented.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_36_SCENARIO_COUNT',
        'Scenario coverage',
        ((SELECT count(DISTINCT scenario_id)=2 FROM _m1_12_vr)),
        ((SELECT count(DISTINCT scenario_id)::text FROM _m1_12_vr)),
        '2',
        'Both matched scenarios must be represented.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_37_UNIQUE_SNAPSHOT_GRAIN',
        'Unique scenario/application snapshot grain',
        ((SELECT count(*)=count(DISTINCT (scenario_id,merchant_application_id)) FROM _m1_12_vr)),
        ((SELECT format('rows=%s|unique=%s',count(*),count(DISTINCT (scenario_id,merchant_application_id))) FROM _m1_12_vr)),
        'rows=unique',
        'No duplicate risk snapshot may exist at the governed grain.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_38_UNIQUE_COMPONENT_GRAIN',
        'Unique scenario/application/component grain',
        ((SELECT count(*)=count(DISTINCT (scenario_id,merchant_application_id,component_code,component_version)) FROM _m1_12_vc)),
        ((SELECT format('rows=%s|unique=%s',count(*),count(DISTINCT (scenario_id,merchant_application_id,component_code,component_version))) FROM _m1_12_vc)),
        'rows=unique',
        'No duplicate long-form component may exist.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_39_SEVEN_COMPONENTS_PER_SNAPSHOT',
        'Exactly seven components per snapshot',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vca WHERE component_count<>7)),
        ((SELECT count(*)::text FROM _m1_12_vca WHERE component_count<>7)),
        '0 violations',
        'Each scenario/application snapshot requires seven governed components.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_40_COMPONENT_CODE_COVERAGE',
        'All governed component codes are present',
        ((SELECT count(DISTINCT component_code)=7 FROM _m1_12_vc)),
        ((SELECT count(DISTINCT component_code)::text FROM _m1_12_vc)),
        '7',
        'The complete transparent component inventory must be represented.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_41_COMPONENT_WEIGHT_IDENTITY',
        'Component weights sum to one per snapshot',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vca WHERE abs(weight_sum-1.0)>0.0000001)),
        ((SELECT count(*)::text FROM _m1_12_vca WHERE abs(weight_sum-1.0)>0.0000001)),
        '0 violations',
        'Persisted component weights must exhaust the composite score.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_42_COMPONENT_SCORE_BOUNDS',
        'Component scores and weighted points are bounded',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vc WHERE component_risk_score IS NOT NULL AND (component_risk_score<0 OR component_risk_score>100 OR weighted_risk_points<0 OR weighted_risk_points>100))),
        ((SELECT count(*)::text FROM _m1_12_vc WHERE component_risk_score IS NOT NULL AND (component_risk_score<0 OR component_risk_score>100 OR weighted_risk_points<0 OR weighted_risk_points>100))),
        '0 violations',
        'Risk scores and weighted points must remain within governed bounds.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_43_WEIGHTED_COMPONENT_IDENTITY',
        'Weighted points equal rounded score times weight',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vc WHERE weighted_risk_points IS DISTINCT FROM CASE WHEN component_risk_score IS NULL THEN NULL ELSE round(component_risk_score*component_weight,6)::numeric(9,6) END)),
        ((SELECT count(*)::text FROM _m1_12_vc WHERE weighted_risk_points IS DISTINCT FROM CASE WHEN component_risk_score IS NULL THEN NULL ELSE round(component_risk_score*component_weight,6)::numeric(9,6) END)),
        '0 violations',
        'Visible weighted points must reconcile to visible component scores and weights.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_44_COMPONENT_AVAILABILITY_IDENTITY',
        'Component availability fields are internally consistent',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vc WHERE NOT ((component_status='AVAILABLE' AND component_risk_score IS NOT NULL AND weighted_risk_points IS NOT NULL AND component_zone<>'UNAVAILABLE' AND directional_status<>'UNAVAILABLE') OR (component_status='UNAVAILABLE' AND component_risk_score IS NULL AND weighted_risk_points IS NULL AND component_zone='UNAVAILABLE' AND directional_status='UNAVAILABLE')))),
        ((SELECT count(*)::text FROM _m1_12_vc WHERE NOT ((component_status='AVAILABLE' AND component_risk_score IS NOT NULL AND weighted_risk_points IS NOT NULL AND component_zone<>'UNAVAILABLE' AND directional_status<>'UNAVAILABLE') OR (component_status='UNAVAILABLE' AND component_risk_score IS NULL AND weighted_risk_points IS NULL AND component_zone='UNAVAILABLE' AND directional_status='UNAVAILABLE')))),
        '0 violations',
        'Unavailable evidence must remain distinct from observed adverse evidence.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_45_COMPONENT_ZONE_MAPPING',
        'Component-zone mapping follows governed thresholds',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vc c CROSS JOIN _m1_12_vpolicy p WHERE c.component_zone IS DISTINCT FROM CASE WHEN c.component_risk_score IS NULL THEN 'UNAVAILABLE' WHEN c.component_risk_score<p.zone_low_max THEN 'LOW' WHEN c.component_risk_score<p.zone_moderate_max THEN 'MODERATE' WHEN c.component_risk_score<p.zone_elevated_max THEN 'ELEVATED' ELSE 'HIGH' END)),
        ((SELECT count(*)::text FROM _m1_12_vc c CROSS JOIN _m1_12_vpolicy p WHERE c.component_zone IS DISTINCT FROM CASE WHEN c.component_risk_score IS NULL THEN 'UNAVAILABLE' WHEN c.component_risk_score<p.zone_low_max THEN 'LOW' WHEN c.component_risk_score<p.zone_moderate_max THEN 'MODERATE' WHEN c.component_risk_score<p.zone_elevated_max THEN 'ELEVATED' ELSE 'HIGH' END)),
        '0 violations',
        'Risk zones must follow the approved component thresholds.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_46_DIRECTIONAL_STATUS_MAPPING',
        'Directional-status mapping follows governed cutoffs',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vc WHERE directional_status IS DISTINCT FROM CASE WHEN component_risk_score IS NULL THEN 'UNAVAILABLE' WHEN component_risk_score<35 THEN 'FAVORABLE' WHEN component_risk_score<65 THEN 'NEUTRAL' ELSE 'ADVERSE' END)),
        ((SELECT count(*)::text FROM _m1_12_vc WHERE directional_status IS DISTINCT FROM CASE WHEN component_risk_score IS NULL THEN 'UNAVAILABLE' WHEN component_risk_score<35 THEN 'FAVORABLE' WHEN component_risk_score<65 THEN 'NEUTRAL' ELSE 'ADVERSE' END)),
        '0 violations',
        'Directional labels must remain explainable and deterministic.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_47_COMPONENT_LINEAGE_PRESENT',
        'Every component retains source lineage',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vc WHERE source_lineage_hash IS NULL OR source_lineage_hash='')),
        ((SELECT count(*)::text FROM _m1_12_vc WHERE source_lineage_hash IS NULL OR source_lineage_hash='')),
        '0 violations',
        'Every component must retain auditable source lineage.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_48_COMPONENT_ROW_HASH',
        'Component calculation hashes reconstruct from physical fields',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vc c WHERE c.calculation_hash<>msbf_m1.m1_12_hash_jsonb(to_jsonb(c)-'calculation_hash'-'created_at'))),
        ((SELECT count(*)::text FROM _m1_12_vc c WHERE c.calculation_hash<>msbf_m1.m1_12_hash_jsonb(to_jsonb(c)-'calculation_hash'-'created_at'))),
        '0 violations',
        'Long-form component rows must reproduce their deterministic hashes.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_49_WIDE_LONG_COMPONENT_RECONCILIATION',
        'Wide component scores equal long-form evidence',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vwide_long WHERE wide_long_mismatch_count<>0)),
        ((SELECT coalesce(sum(wide_long_mismatch_count),0)::text FROM _m1_12_vwide_long)),
        '0 violations',
        'The executive snapshot must reconcile to the auditable long-form component evidence.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_50_EVIDENCE_STATUS_IDENTITY',
        'Integrated evidence status reflects upstream and component availability',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vupstream u CROSS JOIN _m1_12_vpolicy p WHERE u.integrated_risk_evidence_status IS DISTINCT FROM CASE WHEN u.up_operating_evidence='BLOCKED' OR u.up_capacity_evidence='BLOCKED' OR u.up_verification_disposition='INSUFFICIENT_EVIDENCE' OR u.available_component_count<>7 THEN 'BLOCKED' WHEN u.up_operating_evidence='PARTIAL' OR u.up_capacity_evidence='PARTIAL' OR u.up_verification_disposition='REVIEW' OR u.up_source_confidence_score<p.source_confidence_partial_threshold THEN 'PARTIAL' ELSE 'COMPLETE' END)),
        ((SELECT count(*)::text FROM _m1_12_vupstream u CROSS JOIN _m1_12_vpolicy p WHERE u.integrated_risk_evidence_status IS DISTINCT FROM CASE WHEN u.up_operating_evidence='BLOCKED' OR u.up_capacity_evidence='BLOCKED' OR u.up_verification_disposition='INSUFFICIENT_EVIDENCE' OR u.available_component_count<>7 THEN 'BLOCKED' WHEN u.up_operating_evidence='PARTIAL' OR u.up_capacity_evidence='PARTIAL' OR u.up_verification_disposition='REVIEW' OR u.up_source_confidence_score<p.source_confidence_partial_threshold THEN 'PARTIAL' ELSE 'COMPLETE' END)),
        '0 violations',
        'Missing or blocked evidence must never become a low-risk observation.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_51_COMPOSITE_IDENTITY',
        'Non-blocked integrated score equals persisted weighted component sum after governed floors',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vcomposite WHERE final_score_mismatch)),
        ((SELECT count(*)::text FROM _m1_12_vcomposite WHERE final_score_mismatch)),
        '0 violations',
        'The visible integrated score must reconcile to visible weighted components and governed floors.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_52_BLOCKED_PROXY_SUPPRESSION',
        'Blocked evidence suppresses score and proxy',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr WHERE integrated_risk_evidence_status='BLOCKED' AND (integrated_risk_score IS NOT NULL OR synthetic_merchant_risk_proxy IS NOT NULL OR integrated_risk_status<>'INSUFFICIENT_EVIDENCE'))),
        ((SELECT count(*)::text FROM _m1_12_vr WHERE integrated_risk_evidence_status='BLOCKED' AND (integrated_risk_score IS NOT NULL OR synthetic_merchant_risk_proxy IS NOT NULL OR integrated_risk_status<>'INSUFFICIENT_EVIDENCE'))),
        '0 violations',
        'Blocked evidence must remain insufficient rather than producing a numeric proxy.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_53_PROXY_IDENTITY',
        'Synthetic risk proxy equals integrated score divided by 100',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr WHERE synthetic_merchant_risk_proxy IS DISTINCT FROM CASE WHEN integrated_risk_score IS NULL THEN NULL ELSE round(integrated_risk_score/100.0,8)::numeric(12,8) END)),
        ((SELECT count(*)::text FROM _m1_12_vr WHERE synthetic_merchant_risk_proxy IS DISTINCT FROM CASE WHEN integrated_risk_score IS NULL THEN NULL ELSE round(integrated_risk_score/100.0,8)::numeric(12,8) END)),
        '0 violations',
        'The proxy is a normalized synthetic score and is not a calibrated PD.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_54_INDEPENDENT_TIER_MAPPING',
        'Independent risk tier follows independent score',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr r CROSS JOIN _m1_12_vpolicy p WHERE r.independent_risk_tier IS DISTINCT FROM CASE WHEN r.independent_integrated_risk_score IS NULL THEN 5 WHEN r.independent_integrated_risk_score<p.tier_1_max THEN 1 WHEN r.independent_integrated_risk_score<p.tier_2_max THEN 2 WHEN r.independent_integrated_risk_score<p.tier_3_max THEN 3 WHEN r.independent_integrated_risk_score<p.tier_4_max THEN 4 ELSE 5 END)),
        ((SELECT count(*)::text FROM _m1_12_vr r CROSS JOIN _m1_12_vpolicy p WHERE r.independent_risk_tier IS DISTINCT FROM CASE WHEN r.independent_integrated_risk_score IS NULL THEN 5 WHEN r.independent_integrated_risk_score<p.tier_1_max THEN 1 WHEN r.independent_integrated_risk_score<p.tier_2_max THEN 2 WHEN r.independent_integrated_risk_score<p.tier_3_max THEN 3 WHEN r.independent_integrated_risk_score<p.tier_4_max THEN 4 ELSE 5 END)),
        '0 violations',
        'Independent tiering must follow governed score thresholds.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_55_BASELINE_IDENTITY',
        'Baseline score and tier reproduce matched baseline rows',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vmatched WHERE baseline_integrated_risk_score IS DISTINCT FROM matched_baseline_score OR baseline_risk_tier IS DISTINCT FROM matched_baseline_tier)),
        ((SELECT count(*)::text FROM _m1_12_vmatched WHERE baseline_integrated_risk_score IS DISTINCT FROM matched_baseline_score OR baseline_risk_tier IS DISTINCT FROM matched_baseline_tier)),
        '0 violations',
        'Both scenarios must retain the exact matched baseline interpretation.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_56_FINAL_TIER_MAPPING',
        'Final integrated risk tier follows final score',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr r CROSS JOIN _m1_12_vpolicy p WHERE r.integrated_risk_tier IS DISTINCT FROM CASE WHEN r.integrated_risk_score IS NULL THEN 5 WHEN r.integrated_risk_score<p.tier_1_max THEN 1 WHEN r.integrated_risk_score<p.tier_2_max THEN 2 WHEN r.integrated_risk_score<p.tier_3_max THEN 3 WHEN r.integrated_risk_score<p.tier_4_max THEN 4 ELSE 5 END)),
        ((SELECT count(*)::text FROM _m1_12_vr r CROSS JOIN _m1_12_vpolicy p WHERE r.integrated_risk_tier IS DISTINCT FROM CASE WHEN r.integrated_risk_score IS NULL THEN 5 WHEN r.integrated_risk_score<p.tier_1_max THEN 1 WHEN r.integrated_risk_score<p.tier_2_max THEN 2 WHEN r.integrated_risk_score<p.tier_3_max THEN 3 WHEN r.integrated_risk_score<p.tier_4_max THEN 4 ELSE 5 END)),
        '0 violations',
        'Final tiering must remain transparent and deterministic.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_57_STATUS_MAPPING',
        'Risk status follows evidence status and final tier',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr WHERE integrated_risk_status IS DISTINCT FROM CASE WHEN integrated_risk_evidence_status='BLOCKED' THEN 'INSUFFICIENT_EVIDENCE' WHEN integrated_risk_tier=1 THEN 'LOW_RISK' WHEN integrated_risk_tier=2 THEN 'MODERATE_RISK' WHEN integrated_risk_tier=3 THEN 'ELEVATED_RISK' WHEN integrated_risk_tier=4 THEN 'HIGH_RISK' ELSE 'SEVERE_RISK' END)),
        ((SELECT count(*)::text FROM _m1_12_vr WHERE integrated_risk_status IS DISTINCT FROM CASE WHEN integrated_risk_evidence_status='BLOCKED' THEN 'INSUFFICIENT_EVIDENCE' WHEN integrated_risk_tier=1 THEN 'LOW_RISK' WHEN integrated_risk_tier=2 THEN 'MODERATE_RISK' WHEN integrated_risk_tier=3 THEN 'ELEVATED_RISK' WHEN integrated_risk_tier=4 THEN 'HIGH_RISK' ELSE 'SEVERE_RISK' END)),
        '0 violations',
        'Risk labels must be traceable to evidence status and tier.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_58_STRESS_SCORE_NONIMPROVEMENT',
        'Stress integrated score does not improve relative to baseline',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr WHERE scenario_code='RECESSION_ENERGY' AND integrated_risk_score IS NOT NULL AND baseline_integrated_risk_score IS NOT NULL AND integrated_risk_score<baseline_integrated_risk_score)),
        ((SELECT count(*)::text FROM _m1_12_vr WHERE scenario_code='RECESSION_ENERGY' AND integrated_risk_score IS NOT NULL AND baseline_integrated_risk_score IS NOT NULL AND integrated_risk_score<baseline_integrated_risk_score)),
        '0 improvements',
        'The adverse scenario cannot improve the interpreted risk score.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_59_STRESS_TIER_NONIMPROVEMENT',
        'Stress risk tier does not improve relative to baseline',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr WHERE scenario_code='RECESSION_ENERGY' AND integrated_risk_tier<baseline_risk_tier)),
        ((SELECT count(*)::text FROM _m1_12_vr WHERE scenario_code='RECESSION_ENERGY' AND integrated_risk_tier<baseline_risk_tier)),
        '0 improvements',
        'The adverse scenario cannot improve the interpreted risk tier.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_60_STRESS_WORSENING_FLAG',
        'Stress worsening flag reflects score or tier deterioration',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr WHERE stress_risk_worsening_flag IS DISTINCT FROM (scenario_code='RECESSION_ENERGY' AND integrated_risk_score IS NOT NULL AND baseline_integrated_risk_score IS NOT NULL AND (integrated_risk_score>baseline_integrated_risk_score+0.000001 OR integrated_risk_tier>baseline_risk_tier)))),
        ((SELECT count(*)::text FROM _m1_12_vr WHERE stress_risk_worsening_flag IS DISTINCT FROM (scenario_code='RECESSION_ENERGY' AND integrated_risk_score IS NOT NULL AND baseline_integrated_risk_score IS NOT NULL AND (integrated_risk_score>baseline_integrated_risk_score+0.000001 OR integrated_risk_tier>baseline_risk_tier)))),
        '0 violations',
        'Stress migration flags must reconcile to the matched score and tier movement.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_61_HARD_STOP_SCORE_FLOOR',
        'Verification hard stops receive the governed score floor when evidence is usable',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr r CROSS JOIN _m1_12_vpolicy p WHERE r.integrated_risk_evidence_status<>'BLOCKED' AND r.hard_stop_recommended_flag AND r.integrated_risk_score<p.hard_stop_score_floor)),
        ((SELECT count(*)::text FROM _m1_12_vr r CROSS JOIN _m1_12_vpolicy p WHERE r.integrated_risk_evidence_status<>'BLOCKED' AND r.hard_stop_recommended_flag AND r.integrated_risk_score<p.hard_stop_score_floor)),
        '0 violations',
        'A hard verification stop cannot be diluted by favorable operating components.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_62_FRAUD_TIER_FLOOR',
        'Fraud tier five receives the governed score floor when evidence is usable',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr r CROSS JOIN _m1_12_vpolicy p WHERE r.integrated_risk_evidence_status<>'BLOCKED' AND r.fraud_risk_tier=5 AND r.integrated_risk_score<p.fraud_tier_5_score_floor)),
        ((SELECT count(*)::text FROM _m1_12_vr r CROSS JOIN _m1_12_vpolicy p WHERE r.integrated_risk_evidence_status<>'BLOCKED' AND r.fraud_risk_tier=5 AND r.integrated_risk_score<p.fraud_tier_5_score_floor)),
        '0 violations',
        'Severe fraud evidence cannot be diluted by other components.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_63_RISK_FLOOR_FLAG',
        'Risk-floor flag reflects hard-stop or severe-fraud adjustment',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vfloor WHERE risk_floor_applied_flag IS DISTINCT FROM expected_floor_flag)),
        ((SELECT count(*)::text FROM _m1_12_vfloor WHERE risk_floor_applied_flag IS DISTINCT FROM expected_floor_flag)),
        '0 violations',
        'The floor-applied flag must be independently reproducible.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_64_MANUAL_REVIEW_IDENTITY',
        'Manual-review recommendation follows governed routing conditions',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vupstream u CROSS JOIN _m1_12_vpolicy p WHERE u.manual_review_recommended_flag IS DISTINCT FROM (u.up_resilience_manual_review OR u.up_capacity_manual_review OR u.up_verification_manual_review OR u.up_verification_hard_stop OR u.up_verification_disposition='STOP' OR u.integrated_risk_evidence_status<>'COMPLETE' OR u.integrated_risk_tier>=p.manual_review_tier_min))),
        ((SELECT count(*)::text FROM _m1_12_vupstream u CROSS JOIN _m1_12_vpolicy p WHERE u.manual_review_recommended_flag IS DISTINCT FROM (u.up_resilience_manual_review OR u.up_capacity_manual_review OR u.up_verification_manual_review OR u.up_verification_hard_stop OR u.up_verification_disposition='STOP' OR u.integrated_risk_evidence_status<>'COMPLETE' OR u.integrated_risk_tier>=p.manual_review_tier_min))),
        '0 violations',
        'Review routing must preserve upstream controls and final risk interpretation.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_65_FALLBACK_MAPPING',
        'Fallback path follows governed precedence',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vupstream u CROSS JOIN _m1_12_vpolicy p WHERE u.fallback_path_code IS DISTINCT FROM CASE WHEN u.integrated_risk_evidence_status='BLOCKED' THEN 'INSUFFICIENT_EVIDENCE' WHEN u.up_verification_hard_stop OR u.up_verification_disposition='STOP' THEN 'VERIFICATION_STOP' WHEN u.up_verification_disposition='REVIEW' THEN 'VERIFICATION_REVIEW' WHEN u.fraud_risk_tier>=4 THEN 'FRAUD_REVIEW' WHEN u.processor_continuity_risk_tier>=4 THEN 'PROCESSOR_CONTINUITY_REVIEW' WHEN u.capacity_tier>=4 THEN 'CAPACITY_REVIEW' WHEN u.data_confidence_tier IN ('LOW','REVIEW') OR u.up_source_confidence_score<p.source_confidence_partial_threshold THEN 'DATA_REFRESH' WHEN u.integrated_risk_tier>=p.manual_review_tier_min THEN 'MANUAL_RISK_REVIEW' ELSE 'NONE' END)),
        ((SELECT count(*)::text FROM _m1_12_vupstream u CROSS JOIN _m1_12_vpolicy p WHERE u.fallback_path_code IS DISTINCT FROM CASE WHEN u.integrated_risk_evidence_status='BLOCKED' THEN 'INSUFFICIENT_EVIDENCE' WHEN u.up_verification_hard_stop OR u.up_verification_disposition='STOP' THEN 'VERIFICATION_STOP' WHEN u.up_verification_disposition='REVIEW' THEN 'VERIFICATION_REVIEW' WHEN u.fraud_risk_tier>=4 THEN 'FRAUD_REVIEW' WHEN u.processor_continuity_risk_tier>=4 THEN 'PROCESSOR_CONTINUITY_REVIEW' WHEN u.capacity_tier>=4 THEN 'CAPACITY_REVIEW' WHEN u.data_confidence_tier IN ('LOW','REVIEW') OR u.up_source_confidence_score<p.source_confidence_partial_threshold THEN 'DATA_REFRESH' WHEN u.integrated_risk_tier>=p.manual_review_tier_min THEN 'MANUAL_RISK_REVIEW' ELSE 'NONE' END)),
        '0 violations',
        'Fallback routing must remain transparent and precedence controlled.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_66_PRIMARY_REASON_DOMAIN',
        'Primary risk reason belongs to the governed domain',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr WHERE primary_risk_reason_code NOT IN ('INSUFFICIENT_EVIDENCE','VERIFICATION_HARD_STOP','OPERATING_RESILIENCE_RISK','CAPACITY_BURDEN_RISK','LIQUIDITY_RISK','SOURCE_CONFIDENCE_RISK','VERIFICATION_FRAUD_RISK','PROCESSOR_CONTINUITY_RISK','INDUSTRY_RELATIONSHIP_RISK'))),
        ((SELECT count(*)::text FROM _m1_12_vr WHERE primary_risk_reason_code NOT IN ('INSUFFICIENT_EVIDENCE','VERIFICATION_HARD_STOP','OPERATING_RESILIENCE_RISK','CAPACITY_BURDEN_RISK','LIQUIDITY_RISK','SOURCE_CONFIDENCE_RISK','VERIFICATION_FRAUD_RISK','PROCESSOR_CONTINUITY_RISK','INDUSTRY_RELATIONSHIP_RISK'))),
        '0 violations',
        'Primary reasons must remain explainable and catalog controlled.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_67_SECONDARY_REASON_ARRAY',
        'Secondary reason arrays contain no null elements',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr WHERE array_position(secondary_risk_reason_codes,NULL::text) IS NOT NULL)),
        ((SELECT count(*)::text FROM _m1_12_vr WHERE array_position(secondary_risk_reason_codes,NULL::text) IS NOT NULL)),
        '0 violations',
        'Secondary reasons must be clean, filterable evidence.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_68_SCORE_BOUNDS',
        'Snapshot component and integrated scores are bounded',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr WHERE (integrated_risk_score IS NOT NULL AND integrated_risk_score NOT BETWEEN 0 AND 100) OR (synthetic_merchant_risk_proxy IS NOT NULL AND synthetic_merchant_risk_proxy NOT BETWEEN 0 AND 1))),
        ((SELECT count(*)::text FROM _m1_12_vr WHERE (integrated_risk_score IS NOT NULL AND integrated_risk_score NOT BETWEEN 0 AND 100) OR (synthetic_merchant_risk_proxy IS NOT NULL AND synthetic_merchant_risk_proxy NOT BETWEEN 0 AND 1))),
        '0 violations',
        'Scores and normalized proxy values must remain within governed bounds.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_69_TIER_BOUNDS',
        'All risk tiers remain between one and five',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr WHERE independent_risk_tier NOT BETWEEN 1 AND 5 OR baseline_risk_tier NOT BETWEEN 1 AND 5 OR integrated_risk_tier NOT BETWEEN 1 AND 5)),
        ((SELECT count(*)::text FROM _m1_12_vr WHERE independent_risk_tier NOT BETWEEN 1 AND 5 OR baseline_risk_tier NOT BETWEEN 1 AND 5 OR integrated_risk_tier NOT BETWEEN 1 AND 5)),
        '0 violations',
        'All integrated risk tiers must remain in the governed ordinal range.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_70_MATCHED_SCENARIO_COVERAGE',
        'Every application has one baseline and one stress snapshot',
        (NOT EXISTS (SELECT 1 FROM (SELECT merchant_application_id,count(*) n,count(*) FILTER(WHERE scenario_code='BASELINE') b,count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') s FROM _m1_12_vr GROUP BY merchant_application_id)x WHERE n<>2 OR b<>1 OR s<>1)),
        ((SELECT count(*)::text FROM (SELECT merchant_application_id,count(*) n,count(*) FILTER(WHERE scenario_code='BASELINE') b,count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') s FROM _m1_12_vr GROUP BY merchant_application_id)x WHERE n<>2 OR b<>1 OR s<>1)),
        '0 violations',
        'Matched comparison requires the same application under both scenarios.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_71_UPSTREAM_ROW_HASH_LINEAGE',
        'Snapshot lineage hashes reproduce accepted upstream rows',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vupstream WHERE operating_resilience_snapshot_hash<>up_resilience_hash OR liquidity_capacity_snapshot_hash<>up_capacity_hash OR verification_fraud_snapshot_hash<>up_verification_hash)),
        ((SELECT count(*)::text FROM _m1_12_vupstream WHERE operating_resilience_snapshot_hash<>up_resilience_hash OR liquidity_capacity_snapshot_hash<>up_capacity_hash OR verification_fraud_snapshot_hash<>up_verification_hash)),
        '0 violations',
        'Each integrated snapshot must retain exact accepted upstream row lineage.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_72_SNAPSHOT_ROW_HASH',
        'Integrated snapshot row hashes reconstruct from physical fields',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr r WHERE r.row_hash<>msbf_m1.m1_12_hash_jsonb(to_jsonb(r)-'row_hash'-'created_at'-'scenario_code'))),
        ((SELECT count(*)::text FROM _m1_12_vr r WHERE r.row_hash<>msbf_m1.m1_12_hash_jsonb(to_jsonb(r)-'row_hash'-'created_at'-'scenario_code'))),
        '0 violations',
        'Persisted wide snapshots must reproduce deterministic hashes.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_73_SNAPSHOT_SET_HASH',
        'Snapshot set hash reconciles',
        ((SELECT snapshot_hash=stored_snapshot_hash FROM _m1_12_vhash)),
        ((SELECT format('actual=%s|stored=%s',snapshot_hash,stored_snapshot_hash) FROM _m1_12_vhash)),
        'actual=stored',
        'Portfolio-level snapshot identity must reconcile.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_74_COMPONENT_SET_HASH',
        'Component set hash reconciles',
        ((SELECT component_hash=stored_component_hash FROM _m1_12_vhash)),
        ((SELECT format('actual=%s|stored=%s',component_hash,stored_component_hash) FROM _m1_12_vhash)),
        'actual=stored',
        'Portfolio-level component identity must reconcile.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_75_COMBINED_SET_HASH',
        'Combined canonical set hash reconciles',
        ((SELECT combined_hash=stored_combined_hash FROM _m1_12_vhash)),
        ((SELECT format('actual=%s|stored=%s',combined_hash,stored_combined_hash) FROM _m1_12_vhash)),
        'actual=stored',
        'The complete M1.12 canonical universe must reconcile.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_76_GENERATION_EVIDENCE',
        'Generation evidence inventory is complete',
        ((SELECT generation_evidence_rows=9 FROM _m1_12_vhash)),
        ((SELECT generation_evidence_rows::text FROM _m1_12_vhash)),
        '9',
        'All generation counts and hashes must be durably recorded.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_77_CANONICAL_COUNTS',
        'Canonical counts and stored mismatch evidence reconcile',
        ((SELECT canonical_entities=12000 AND stored_canonical_entities=12000 AND stored_mismatches=0 FROM _m1_12_vhash)),
        ((SELECT format('actual=%s|stored=%s|mismatches=%s',canonical_entities,stored_canonical_entities,stored_mismatches) FROM _m1_12_vhash)),
        '12000|12000|0',
        'The full canonical population must reconcile with zero mismatches.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_78_ASOF_LINEAGE',
        'As-of dates do not exceed the governed run date',
        (NOT EXISTS (SELECT 1 FROM _m1_12_vr r CROSS JOIN _m1_12_vrun x WHERE r.as_of_date>x.as_of_date)),
        ((SELECT count(*)::text FROM _m1_12_vr r CROSS JOIN _m1_12_vrun x WHERE r.as_of_date>x.as_of_date)),
        '0 future rows',
        'M1.12 must not consume future information.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_79_STAGE_BOUNDARY',
        'No downstream calibrated risk, exposure, loss, latest, or archive rows exist',
        ((SELECT downstream_rows=0 FROM _m1_12_vboundary)),
        ((SELECT downstream_rows::text FROM _m1_12_vboundary)),
        '0',
        'M1.12 must stop at transparent synthetic risk proxy evidence.'
    );

    PERFORM pg_temp.m1_12_add_check(
        'M1_12_POS_80_BLOCKING_ERRORS',
        'No blocking configuration errors exist',
        ((SELECT blocking_errors=0 FROM _m1_12_vboundary)),
        ((SELECT blocking_errors::text FROM _m1_12_vboundary)),
        '0',
        'No unresolved blocking configuration error may remain.'
    );
END;
$checks$;

/* ---------------------------------------------------------------------------
3. Persist evidence, advance run state, and return one filterable result set
--------------------------------------------------------------------------- */
INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_text,
    unit_code,status,interpretation
)
SELECT (SELECT run_id FROM _m1_12_vrun),evidence_code,'PORTFOLIO',metric_name,
       observed_value,'TEXT',status,
       'threshold='||coalesce(threshold_value,'')||'|'||interpretation
FROM _m1_12_validation
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,
    metric_value_text=EXCLUDED.metric_value_text,
    metric_value_numeric=NULL,
    unit_code=EXCLUDED.unit_code,
    status=EXCLUDED.status,
    interpretation=EXCLUDED.interpretation,
    created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry r
SET run_status=CASE WHEN v.failures=0 AND v.checks=80 THEN 'M1_12_VALIDATED' ELSE 'M1_12_FAILED' END,
    notes=coalesce(r.notes,'')||E'
M1.12 positive validation: '||v.passes||'/'||v.checks||' PASS.'
FROM (SELECT count(*) AS checks,count(*) FILTER(WHERE status='PASS') AS passes,count(*) FILTER(WHERE status='FAIL') AS failures FROM _m1_12_validation) v
WHERE r.run_id=(SELECT run_id FROM _m1_12_vrun);

COMMIT;

SELECT evidence_code,metric_name,observed_value,threshold_value,status,interpretation
FROM _m1_12_validation
ORDER BY evidence_code;
