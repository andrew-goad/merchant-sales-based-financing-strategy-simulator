/* ============================================================================
MSBF M1.12 Merchant Risk Components & Integrated Risk Proxy — Detail Report
Version : v0.2R1
Purpose : Produce the complete technical evidence package for governance,
          component transparency, risk distribution, matched stress migration,
          routing, lineage, deterministic reconciliation, and stage boundaries.
Mode    : Read-only after M1.12 acceptance.
Output  : Twenty labeled result sets. Working tables use ON COMMIT PRESERVE ROWS
          so DBeaver result grids remain filterable within the current session.
============================================================================ */

BEGIN;
SET LOCAL work_mem='64MB'; SET LOCAL jit=off; SET LOCAL statement_timeout='15min';
DROP TABLE IF EXISTS _m1_12_detail_risk;
DROP TABLE IF EXISTS _m1_12_detail_component;
DROP TABLE IF EXISTS _m1_12_detail_actual;
DROP TABLE IF EXISTS _m1_12_detail_mismatch;

CREATE TEMP TABLE _m1_12_detail_risk ON COMMIT PRESERVE ROWS AS
SELECT r.*,sr.scenario_code,a.partner_channel_id
FROM msbf_m1.application_integrated_risk_proxy_snapshot r
JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
JOIN msbf_m1.merchant_application a USING(merchant_application_id)
WHERE r.module1_run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1);
CREATE INDEX ON _m1_12_detail_risk(scenario_code,integrated_risk_tier);
CREATE INDEX ON _m1_12_detail_risk(industry_code,relationship_stage);

CREATE TEMP TABLE _m1_12_detail_component ON COMMIT PRESERVE ROWS AS
SELECT c.*,sr.scenario_code
FROM msbf_m1.integrated_risk_component_value c
JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
WHERE c.module1_run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1);
CREATE INDEX ON _m1_12_detail_component(component_code,scenario_code);

CREATE TEMP TABLE _m1_12_detail_actual ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.m1_12_actual_snapshot((SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1))
UNION ALL
SELECT * FROM msbf_m1.m1_12_actual_component((SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1));
CREATE UNIQUE INDEX ON _m1_12_detail_actual(entity_key);

CREATE TEMP TABLE _m1_12_detail_mismatch ON COMMIT PRESERVE ROWS AS
WITH stored AS (
    SELECT
        'RISK|' || scenario_id || '|' || merchant_application_id AS entity_key,
        row_hash AS stored_hash
    FROM msbf_m1.application_integrated_risk_proxy_snapshot
    WHERE module1_run_id = (
        SELECT run_id
        FROM msbf_ctl.run_registry
        WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
          AND run_version = 1
    )

    UNION ALL

    SELECT
        'COMPONENT|' || scenario_id || '|' || merchant_application_id
            || '|' || component_code || '|' || component_version AS entity_key,
        calculation_hash AS stored_hash
    FROM msbf_m1.integrated_risk_component_value
    WHERE module1_run_id = (
        SELECT run_id
        FROM msbf_ctl.run_registry
        WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
          AND run_version = 1
    )
)
SELECT
    coalesce(s.entity_key, a.entity_key) AS entity_key,
    s.stored_hash,
    a.row_hash AS independently_recomputed_hash
FROM stored s
FULL JOIN _m1_12_detail_actual a USING (entity_key)
WHERE s.stored_hash IS DISTINCT FROM a.row_hash;

COMMIT;

/* 01 — Run and Acceptance State */
SELECT r.run_id,r.run_status,r.population_id,r.as_of_date,g.gate_id,g.review_version,g.result_status,g.reviewed_at,
       p.status AS policy_status,p.profile_payload->>'methodology_version' AS methodology_version,
       p.profile_payload->>'composite_score_basis' AS composite_score_basis
FROM msbf_ctl.run_registry r
JOIN LATERAL(SELECT * FROM msbf_ctl.acceptance_gate_result x WHERE x.run_id=r.run_id AND x.gate_id='M1_12_INTEGRATED_RISK_PROXY' ORDER BY review_version DESC LIMIT 1)g ON true
JOIN msbf_ctl.policy_profile p ON p.profile_code='M1_12_INTEGRATED_RISK_PROXY' AND p.profile_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

/* 02 — Entity and Stage-Boundary Row Counts */
SELECT 'integrated_risk_snapshots' AS entity,count(*) AS row_count FROM _m1_12_detail_risk
UNION ALL SELECT 'integrated_risk_components',count(*) FROM _m1_12_detail_component
UNION ALL SELECT 'applications',count(DISTINCT merchant_application_id) FROM _m1_12_detail_risk
UNION ALL SELECT 'scenarios',count(DISTINCT scenario_id) FROM _m1_12_detail_risk
UNION ALL SELECT 'merchant_risk_snapshot_downstream',count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_12_detail_risk)
UNION ALL SELECT 'risk_component_detail_downstream',count(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_12_detail_risk)
UNION ALL SELECT 'ead_path_snapshot_downstream',count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_12_detail_risk)
UNION ALL SELECT 'module1_latest_downstream',count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_12_detail_risk)
UNION ALL SELECT 'module1_archive_downstream',count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT min(module1_run_id) FROM _m1_12_detail_risk);

/* 03 — Governed Methodology and Component Weights */
SELECT p.profile_payload->>'methodology_version' AS methodology_version,
       p.profile_payload->>'composite_score_basis' AS composite_score_basis,
       p.profile_payload->>'stress_risk_score_floor_to_baseline' AS stress_score_floor,
       p.profile_payload->>'stress_risk_tier_floor_to_baseline' AS stress_tier_floor,
       c.component_code,c.component_name,c.component_domain,
       CASE c.component_code
         WHEN 'OPERATING_RESILIENCE_RISK' THEN (p.profile_payload->>'component_weight_operating_resilience')::numeric
         WHEN 'CAPACITY_BURDEN_RISK' THEN (p.profile_payload->>'component_weight_capacity_burden')::numeric
         WHEN 'LIQUIDITY_RISK' THEN (p.profile_payload->>'component_weight_liquidity')::numeric
         WHEN 'SOURCE_CONFIDENCE_RISK' THEN (p.profile_payload->>'component_weight_source_confidence')::numeric
         WHEN 'VERIFICATION_FRAUD_RISK' THEN (p.profile_payload->>'component_weight_verification_fraud')::numeric
         WHEN 'PROCESSOR_CONTINUITY_RISK' THEN (p.profile_payload->>'component_weight_processor_continuity')::numeric
         WHEN 'INDUSTRY_RELATIONSHIP_RISK' THEN (p.profile_payload->>'component_weight_industry_relationship')::numeric END AS governed_weight
FROM msbf_ctl.policy_profile p CROSS JOIN msbf_ref.risk_component_code c
WHERE p.profile_code='M1_12_INTEGRATED_RISK_PROXY' AND p.profile_version=1
  AND c.component_code IN ('OPERATING_RESILIENCE_RISK','CAPACITY_BURDEN_RISK','LIQUIDITY_RISK','SOURCE_CONFIDENCE_RISK','VERIFICATION_FRAUD_RISK','PROCESSOR_CONTINUITY_RISK','INDUSTRY_RELATIONSHIP_RISK')
ORDER BY c.component_code;

/* 04 — Risk Tier and Status Distribution */
SELECT scenario_code,integrated_risk_tier,integrated_risk_status,count(*) AS applications,
       round(avg(integrated_risk_score),6) AS avg_score,
       round(avg(synthetic_merchant_risk_proxy),8) AS avg_proxy
FROM _m1_12_detail_risk GROUP BY scenario_code,integrated_risk_tier,integrated_risk_status
ORDER BY scenario_code,integrated_risk_tier;

/* 05 — Integrated Score and Proxy Diagnostics */
SELECT scenario_code,count(*) AS rows,count(integrated_risk_score) AS scored_rows,
       round(avg(integrated_risk_score),6) AS avg_score,min(integrated_risk_score) AS min_score,max(integrated_risk_score) AS max_score,
       round(avg(synthetic_merchant_risk_proxy),8) AS avg_proxy,min(synthetic_merchant_risk_proxy) AS min_proxy,max(synthetic_merchant_risk_proxy) AS max_proxy
FROM _m1_12_detail_risk GROUP BY scenario_code ORDER BY scenario_code;

/* 06 — Component Risk and Weighted-Point Summary */
SELECT scenario_code,component_code,component_zone,component_status,count(*) AS rows,
       round(avg(component_risk_score),6) AS avg_component_score,
       round(avg(weighted_risk_points),6) AS avg_weighted_points,
       min(component_risk_score) AS min_score,max(component_risk_score) AS max_score
FROM _m1_12_detail_component GROUP BY scenario_code,component_code,component_zone,component_status
ORDER BY scenario_code,component_code,component_zone;

/* 07 — Primary and Secondary Risk-Reason Diagnostics */
SELECT scenario_code,primary_risk_reason_code,count(*) AS applications,
       count(*) FILTER(WHERE manual_review_recommended_flag) AS manual_review_rows,
       count(*) FILTER(WHERE hard_stop_recommended_flag) AS hard_stop_rows,
       round(avg(integrated_risk_score),6) AS avg_score
FROM _m1_12_detail_risk GROUP BY scenario_code,primary_risk_reason_code
ORDER BY scenario_code,applications DESC,primary_risk_reason_code;

/* 08 — Fallback, Review, and Hard-Stop Diagnostics */
SELECT scenario_code,fallback_path_code,integrated_risk_evidence_status,
       manual_review_recommended_flag,hard_stop_recommended_flag,count(*) AS applications,
       round(avg(integrated_risk_score),6) AS avg_score
FROM _m1_12_detail_risk GROUP BY scenario_code,fallback_path_code,integrated_risk_evidence_status,manual_review_recommended_flag,hard_stop_recommended_flag
ORDER BY scenario_code,applications DESC;

/* 09 — Matched Stress Migration */
SELECT baseline_risk_tier,integrated_risk_tier AS stress_risk_tier,
       integrated_risk_tier-baseline_risk_tier AS tier_delta,count(*) AS applications,
       count(*) FILTER(WHERE stress_risk_worsening_flag) AS worsening_rows,
       round(avg(integrated_risk_score-baseline_integrated_risk_score),6) AS avg_score_delta
FROM _m1_12_detail_risk WHERE scenario_code='RECESSION_ENERGY'
GROUP BY baseline_risk_tier,integrated_risk_tier ORDER BY baseline_risk_tier,integrated_risk_tier;

/* 10 — Evidence Status and Data-Confidence Diagnostics */
SELECT scenario_code,integrated_risk_evidence_status,data_confidence_tier,count(*) AS applications,
       round(avg(source_confidence_risk_score),6) AS avg_source_confidence_risk,
       count(*) FILTER(WHERE integrated_risk_score IS NULL) AS unscored_rows
FROM _m1_12_detail_risk GROUP BY scenario_code,integrated_risk_evidence_status,data_confidence_tier
ORDER BY scenario_code,integrated_risk_evidence_status,data_confidence_tier;

/* 11 — Verification and Fraud Diagnostics */
SELECT scenario_code,verification_disposition,fraud_risk_tier,hard_stop_recommended_flag,count(*) AS applications,
       round(avg(verification_fraud_risk_score),6) AS avg_verification_fraud_risk,
       round(avg(integrated_risk_score),6) AS avg_integrated_score
FROM _m1_12_detail_risk GROUP BY scenario_code,verification_disposition,fraud_risk_tier,hard_stop_recommended_flag
ORDER BY scenario_code,verification_disposition,fraud_risk_tier;

/* 12 — Capacity and Operating-Resilience Diagnostics */
SELECT scenario_code,operating_resilience_tier,capacity_tier,archetype_code,count(*) AS applications,
       round(avg(operating_resilience_risk_score),6) AS avg_operating_risk,
       round(avg(capacity_burden_risk_score),6) AS avg_capacity_risk,
       round(avg(liquidity_risk_score),6) AS avg_liquidity_risk,
       round(avg(integrated_risk_score),6) AS avg_integrated_score
FROM _m1_12_detail_risk GROUP BY scenario_code,operating_resilience_tier,capacity_tier,archetype_code
ORDER BY scenario_code,operating_resilience_tier,capacity_tier,archetype_code;

/* 13 — Industry Diagnostics */
SELECT scenario_code,industry_code,count(*) AS applications,
       round(avg(industry_relationship_risk_score),6) AS avg_context_risk,
       round(avg(integrated_risk_score),6) AS avg_integrated_score,
       count(*) FILTER(WHERE integrated_risk_tier>=4) AS high_or_severe_rows
FROM _m1_12_detail_risk GROUP BY scenario_code,industry_code
ORDER BY scenario_code,avg_integrated_score DESC NULLS LAST,industry_code;

/* 14 — Relationship Stage and Merchant Size Diagnostics */
SELECT scenario_code,merchant_size_tier,relationship_stage,count(*) AS applications,
       round(avg(industry_relationship_risk_score),6) AS avg_context_risk,
       round(avg(integrated_risk_score),6) AS avg_integrated_score
FROM _m1_12_detail_risk GROUP BY scenario_code,merchant_size_tier,relationship_stage
ORDER BY scenario_code,merchant_size_tier,relationship_stage;

/* 15 — Partner-Channel Diagnostics */
SELECT scenario_code,coalesce(partner_channel_id,'DIRECT_OR_UNASSIGNED') AS partner_channel_id,count(*) AS applications,
       round(avg(integrated_risk_score),6) AS avg_score,
       count(*) FILTER(WHERE manual_review_recommended_flag) AS manual_review_rows,
       count(*) FILTER(WHERE hard_stop_recommended_flag) AS hard_stop_rows
FROM _m1_12_detail_risk GROUP BY scenario_code,coalesce(partner_channel_id,'DIRECT_OR_UNASSIGNED')
ORDER BY scenario_code,applications DESC,partner_channel_id;

/* 16 — Sample Matched Application Profiles */
WITH ranked AS(
 SELECT r.*,row_number() OVER(PARTITION BY scenario_code ORDER BY integrated_risk_score DESC NULLS LAST,merchant_application_id) AS rn
 FROM _m1_12_detail_risk r)
SELECT scenario_code,merchant_application_id,merchant_id,industry_code,relationship_stage,archetype_code,
       integrated_risk_evidence_status,integrated_risk_score,synthetic_merchant_risk_proxy,integrated_risk_tier,
       primary_risk_reason_code,secondary_risk_reason_codes,fallback_path_code,manual_review_recommended_flag,hard_stop_recommended_flag
FROM ranked WHERE rn<=20 ORDER BY scenario_code,rn;

/* 17 — Component Zone Distribution */
SELECT component_code,scenario_code,component_zone,directional_status,count(*) AS rows,
       round(avg(component_risk_score),6) AS avg_score,round(avg(weighted_risk_points),6) AS avg_weighted_points
FROM _m1_12_detail_component GROUP BY component_code,scenario_code,component_zone,directional_status
ORDER BY component_code,scenario_code,component_zone;

/* 18 — M1.12 Governed Evidence */
SELECT evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,threshold_value_numeric,interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT min(module1_run_id) FROM _m1_12_detail_risk) AND evidence_code LIKE 'M1_12_%'
ORDER BY evidence_code,segment_key;

/* 19 — Row-Level Deterministic Mismatches (must return zero rows) */
SELECT * FROM _m1_12_detail_mismatch ORDER BY entity_key;

/* 20 — Blocking Resolution Errors (must return zero rows)
   Note: profile_resolution_error uses resolution_error_id as its primary key.
   The explicit projection prevents future report drift if table column order changes. */
SELECT
    resolution_error_id,
    run_id,
    profile_domain,
    scope_key,
    error_code,
    severity,
    error_message,
    created_at
FROM msbf_ctl.profile_resolution_error
WHERE run_id = (
        SELECT min(module1_run_id)
        FROM _m1_12_detail_risk
    )
  AND severity = 'BLOCKING'
ORDER BY resolution_error_id;
