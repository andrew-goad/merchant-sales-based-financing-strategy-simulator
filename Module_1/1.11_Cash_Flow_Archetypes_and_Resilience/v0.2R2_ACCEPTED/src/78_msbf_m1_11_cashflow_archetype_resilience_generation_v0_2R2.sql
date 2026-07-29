/* ============================================================================
MSBF M1.11 Cash-Flow Archetypes & Operating Resilience — Generation
Version : v0.2R2
Purpose : Consume accepted M1.9 cash-flow features and M1.10 capacity evidence,
          create transparent matched-scenario operating archetypes, five
          component resilience scores, final stress-floored resilience tiers,
          long-form component evidence, and deterministic canonical hashes.
Performance: Accepted physical inputs are materialized once. No M1.4–M1.10
             blueprint is regenerated. Persistent outputs are indexed/analyzed
             before reconciliation.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='15min';

CREATE OR REPLACE FUNCTION msbf_m1.m1_11_hash_jsonb(p_payload jsonb)
RETURNS text LANGUAGE sql IMMUTABLE STRICT AS $$ SELECT md5(p_payload::text) $$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_11_actual_resilience(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text)
LANGUAGE sql STABLE AS $$
 SELECT 'RESILIENCE|'||r.scenario_id||'|'||r.merchant_application_id,
        msbf_m1.m1_11_hash_jsonb(to_jsonb(r)-'row_hash'-'created_at')
 FROM msbf_m1.application_operating_resilience_snapshot r
 WHERE r.module1_run_id=p_run_id
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_11_actual_component(p_run_id bigint)
RETURNS TABLE(entity_key text,row_hash text)
LANGUAGE sql STABLE AS $$
 SELECT 'COMPONENT|'||c.scenario_id||'|'||c.merchant_application_id||'|'||c.component_code||'|'||c.component_version,
        msbf_m1.m1_11_hash_jsonb(to_jsonb(c)-'calculation_hash'-'created_at')
 FROM msbf_m1.operating_resilience_component_value c
 WHERE c.module1_run_id=p_run_id
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_11_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_status text; v_features bigint; v_capacity bigint; v_scen bigint; v_targets bigint; v_weight numeric; v_policy jsonb;
BEGIN
 SELECT run_status INTO STRICT v_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
 IF v_status<>'M1_10_ACCEPTED' THEN RAISE EXCEPTION 'M1.11 requires M1_10_ACCEPTED; observed %.',v_status; END IF;
 SELECT count(*) INTO v_features FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=p_run_id;
 SELECT count(*) INTO v_capacity FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=p_run_id;
 SELECT count(DISTINCT scenario_id) INTO v_scen FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=p_run_id;
 SELECT (SELECT count(*) FROM msbf_m1.application_operating_resilience_snapshot WHERE module1_run_id=p_run_id)+
        (SELECT count(*) FROM msbf_m1.operating_resilience_component_value WHERE module1_run_id=p_run_id) INTO v_targets;
 SELECT profile_payload INTO STRICT v_policy FROM msbf_ctl.policy_profile
 WHERE profile_code='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE' AND profile_version=1 AND status='APPROVED';
 v_weight=(v_policy->>'component_weight_revenue')::numeric+(v_policy->>'component_weight_liquidity')::numeric+
          (v_policy->>'component_weight_burden')::numeric+(v_policy->>'component_weight_continuity')::numeric+
          (v_policy->>'component_weight_data_confidence')::numeric;
 IF v_features<>1500 OR v_capacity<>1500 OR v_scen<>2 THEN
   RAISE EXCEPTION 'M1.11 input cardinality mismatch: feature %, capacity %, scenarios %.',v_features,v_capacity,v_scen;
 END IF;
 IF v_targets<>0 THEN RAISE EXCEPTION 'M1.11 generation rejected because % target rows already exist.',v_targets; END IF;
 IF coalesce((v_policy->>'generation_enabled')::boolean,false)=false OR v_policy->>'methodology_version'<>'M1_11_METHOD_V1_1' OR v_policy->>'composite_score_basis'<>'SUM_PERSISTED_WEIGHTED_COMPONENTS' OR abs(v_weight-1)>0.0000001 THEN
   RAISE EXCEPTION 'M1.11 policy configuration is invalid.';
 END IF;
END; $$;

DROP TABLE IF EXISTS _m1_11_ctx;
DROP TABLE IF EXISTS _m1_11_input;
DROP TABLE IF EXISTS _m1_11_scored;
DROP TABLE IF EXISTS _m1_11_baseline;
DROP TABLE IF EXISTS _m1_11_final;
DROP TABLE IF EXISTS _m1_11_expected;
DROP TABLE IF EXISTS _m1_11_component_expected;
DROP TABLE IF EXISTS _m1_11_expected_canonical;
DROP TABLE IF EXISTS _m1_11_actual_canonical;
DROP TABLE IF EXISTS _m1_11_mismatch;
DROP TABLE IF EXISTS _m1_11_hashes;

CREATE TEMP TABLE _m1_11_ctx ON COMMIT DROP AS
SELECT r.run_id,r.population_id,r.as_of_date,p.policy_profile_id,p.profile_payload
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.policy_profile p ON p.profile_code='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE'
 AND p.profile_version=1 AND p.status='APPROVED'
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

SELECT msbf_m1.m1_11_assert_generation_ready((SELECT run_id FROM _m1_11_ctx));

DO $n$ BEGIN RAISE NOTICE 'M1.11 Phase 1/5 — materialize accepted M1.9 and M1.10 inputs once'; END $n$;

CREATE TEMP TABLE _m1_11_input ON COMMIT DROP AS
SELECT f.module1_run_id,f.scenario_id,s.scenario_code,f.merchant_application_id,f.population_id,f.merchant_id,f.as_of_date,
       m.merchant_size_tier,ia.industry_code,rs.relationship_stage,
       f.feature_snapshot_hash AS cashflow_feature_snapshot_hash,c.row_hash AS liquidity_capacity_snapshot_hash,
       f.source_confidence_score,f.data_confidence_tier,f.feature_completeness_status,c.capacity_evidence_status,
       f.downstream_routing_status,f.ready_for_downstream_flag,
       f.verification_disposition,f.fraud_risk_tier,f.processor_continuity_risk_tier,
       (f.manual_review_recommended_flag OR c.manual_review_recommended_flag) AS upstream_manual_review_flag,
       f.pos_history_days,f.deposit_history_days,f.avg_daily_eligible_sales_30d,
       f.sales_growth_30d_vs_90d,f.daily_sales_cv_90d,f.zero_sales_day_rate_30d,f.active_sales_day_rate_30d,
       f.seasonality_index_180d,f.largest_30d_share_180d,
       f.processor_outage_day_rate_30d,f.processor_degraded_day_rate_30d,
       f.negative_balance_day_rate_30d,f.nsf_count_30d,f.cash_flow_buffer_days,
       f.scenario_eligible_sales_delta_rate_90d,
       c.sales_linked_payment_coverage_ratio,c.total_obligation_to_sales_rate,
       c.residual_daily_operating_cash_flow,c.post_financing_buffer_days,c.stacking_depth,
       c.obligation_concentration_rate,c.capacity_tier
FROM msbf_m1.application_cashflow_feature_snapshot f
JOIN msbf_m1.application_liquidity_capacity_snapshot c
  ON c.module1_run_id=f.module1_run_id AND c.scenario_id=f.scenario_id
 AND c.merchant_application_id=f.merchant_application_id
JOIN msbf_ctl.scenario_registry s ON s.scenario_id=f.scenario_id
JOIN msbf_m1.merchant_master m ON m.merchant_id=f.merchant_id
JOIN msbf_m1.merchant_industry_assignment ia ON ia.merchant_id=f.merchant_id AND ia.assignment_type='PRIMARY'
JOIN msbf_m1.merchant_relationship_snapshot rs ON rs.merchant_id=f.merchant_id AND rs.as_of_date=f.as_of_date
WHERE f.module1_run_id=(SELECT run_id FROM _m1_11_ctx);
CREATE UNIQUE INDEX ON _m1_11_input(scenario_id,merchant_application_id);
ANALYZE _m1_11_input;

DO $n$ BEGIN RAISE NOTICE 'M1.11 Phase 2/5 — calculate transparent components and independent archetypes'; END $n$;

CREATE TEMP TABLE _m1_11_scored ON COMMIT DROP AS
WITH base AS (
 SELECT i.*,x.profile_payload,
   CASE WHEN i.feature_completeness_status='BLOCKED' OR i.capacity_evidence_status='BLOCKED'
             OR NOT i.ready_for_downstream_flag OR i.downstream_routing_status IN ('STOP','INSUFFICIENT_EVIDENCE')
             OR i.avg_daily_eligible_sales_30d IS NULL OR i.sales_growth_30d_vs_90d IS NULL
             OR i.daily_sales_cv_90d IS NULL OR i.zero_sales_day_rate_30d IS NULL
             OR i.largest_30d_share_180d IS NULL OR i.post_financing_buffer_days IS NULL
             OR i.negative_balance_day_rate_30d IS NULL OR i.nsf_count_30d IS NULL
             OR i.cash_flow_buffer_days IS NULL OR i.sales_linked_payment_coverage_ratio IS NULL
             OR i.total_obligation_to_sales_rate IS NULL OR i.residual_daily_operating_cash_flow IS NULL
             OR i.stacking_depth IS NULL OR i.processor_outage_day_rate_30d IS NULL
             OR i.processor_degraded_day_rate_30d IS NULL
        THEN 'BLOCKED'
        WHEN i.feature_completeness_status='PARTIAL' OR i.capacity_evidence_status='PARTIAL'
             OR i.downstream_routing_status='REVIEW' OR i.source_confidence_score<0.90 THEN 'PARTIAL'
        ELSE 'COMPLETE' END AS evidence_status,
   CASE WHEN i.avg_daily_eligible_sales_30d IS NULL OR i.sales_growth_30d_vs_90d IS NULL
             OR i.daily_sales_cv_90d IS NULL OR i.zero_sales_day_rate_30d IS NULL OR i.largest_30d_share_180d IS NULL THEN NULL
        ELSE round(100*(
          0.40*greatest(0::numeric,least(1::numeric,(i.sales_growth_30d_vs_90d-(x.profile_payload->>'revenue_growth_floor')::numeric)/(0.10-(x.profile_payload->>'revenue_growth_floor')::numeric)))+
          0.25*greatest(0::numeric,least(1::numeric,((x.profile_payload->>'revenue_cv_max')::numeric-i.daily_sales_cv_90d)/greatest((x.profile_payload->>'revenue_cv_max')::numeric-(x.profile_payload->>'revenue_cv_neutral')::numeric,0.000001)))+
          0.20*greatest(0::numeric,least(1::numeric,1-i.zero_sales_day_rate_30d/greatest((x.profile_payload->>'revenue_zero_sales_max')::numeric,0.000001)))+
          0.15*greatest(0::numeric,least(1::numeric,((x.profile_payload->>'revenue_concentration_max')::numeric-i.largest_30d_share_180d)/greatest((x.profile_payload->>'revenue_concentration_max')::numeric-(x.profile_payload->>'revenue_concentration_neutral')::numeric,0.000001)))
        ),6) END AS revenue_score,
   CASE WHEN i.post_financing_buffer_days IS NULL OR i.negative_balance_day_rate_30d IS NULL OR i.nsf_count_30d IS NULL OR i.cash_flow_buffer_days IS NULL THEN NULL
        ELSE round(100*(
          0.40*greatest(0::numeric,least(1::numeric,i.post_financing_buffer_days/greatest((x.profile_payload->>'liquidity_buffer_target_days')::numeric,0.000001)))+
          0.25*greatest(0::numeric,least(1::numeric,1-i.negative_balance_day_rate_30d/greatest((x.profile_payload->>'liquidity_negative_rate_max')::numeric,0.000001)))+
          0.15*greatest(0::numeric,least(1::numeric,1-i.nsf_count_30d::numeric/greatest((x.profile_payload->>'liquidity_nsf_count_max')::numeric,0.000001)))+
          0.20*greatest(0::numeric,least(1::numeric,i.cash_flow_buffer_days/greatest((x.profile_payload->>'liquidity_cashflow_buffer_target_days')::numeric,0.000001)))
        ),6) END AS liquidity_score,
   CASE WHEN i.sales_linked_payment_coverage_ratio IS NULL OR i.total_obligation_to_sales_rate IS NULL OR i.residual_daily_operating_cash_flow IS NULL OR i.stacking_depth IS NULL THEN NULL
        ELSE round(100*(
          0.45*greatest(0::numeric,least(1::numeric,i.sales_linked_payment_coverage_ratio/greatest((x.profile_payload->>'burden_coverage_target')::numeric,0.000001)))+
          0.30*greatest(0::numeric,least(1::numeric,1-i.total_obligation_to_sales_rate/greatest((x.profile_payload->>'burden_rate_max')::numeric,0.000001)))+
          0.15*CASE WHEN i.residual_daily_operating_cash_flow>=0 THEN 1 ELSE 0 END+
          0.10*greatest(0::numeric,least(1::numeric,1-(greatest(i.stacking_depth,1)-1)::numeric/greatest((x.profile_payload->>'burden_stacking_depth_max')::numeric-1,1)))
        ),6) END AS burden_score,
   CASE WHEN i.processor_outage_day_rate_30d IS NULL OR i.processor_degraded_day_rate_30d IS NULL OR i.processor_continuity_risk_tier IS NULL THEN NULL
        ELSE round(100*(
          0.50*greatest(0::numeric,least(1::numeric,1-i.processor_outage_day_rate_30d/greatest((x.profile_payload->>'continuity_outage_rate_max')::numeric,0.000001)))+
          0.30*greatest(0::numeric,least(1::numeric,1-i.processor_degraded_day_rate_30d/greatest((x.profile_payload->>'continuity_degraded_rate_max')::numeric,0.000001)))+
          0.20*greatest(0::numeric,least(1::numeric,(5-i.processor_continuity_risk_tier)::numeric/4))
        ),6) END AS continuity_score,
   round(greatest(0::numeric,least(100::numeric,80*i.source_confidence_score+
        20*CASE i.feature_completeness_status WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 0.70 ELSE 0.25 END)),6) AS data_score
 FROM _m1_11_input i CROSS JOIN _m1_11_ctx x
), composite AS (
 SELECT b.*,
   CASE WHEN b.evidence_status='BLOCKED' OR b.revenue_score IS NULL OR b.liquidity_score IS NULL OR b.burden_score IS NULL OR b.continuity_score IS NULL OR b.data_score IS NULL THEN NULL
        ELSE round(
                   round(b.revenue_score*(b.profile_payload->>'component_weight_revenue')::numeric,6)+
                   round(b.liquidity_score*(b.profile_payload->>'component_weight_liquidity')::numeric,6)+
                   round(b.burden_score*(b.profile_payload->>'component_weight_burden')::numeric,6)+
                   round(b.continuity_score*(b.profile_payload->>'component_weight_continuity')::numeric,6)+
                   round(b.data_score*(b.profile_payload->>'component_weight_data_confidence')::numeric,6),6) END AS composite_score
 FROM base b
), interpreted AS (
 SELECT c.*,
   CASE WHEN c.evidence_status='BLOCKED' THEN 'INSUFFICIENT_EVIDENCE'
        WHEN least(c.pos_history_days,c.deposit_history_days)<(c.profile_payload->>'minimum_history_days')::integer THEN 'THIN_HISTORY'
        WHEN coalesce(c.processor_outage_day_rate_30d,0)>=(c.profile_payload->>'disruption_outage_rate')::numeric
          OR coalesce(c.active_sales_day_rate_30d,1)<(c.profile_payload->>'disruption_active_sales_rate_min')::numeric
          OR coalesce(c.zero_sales_day_rate_30d,0)>=(c.profile_payload->>'disruption_zero_sales_rate')::numeric THEN 'DISRUPTED'
        WHEN coalesce(c.sales_growth_30d_vs_90d,0)<=(c.profile_payload->>'declining_growth_threshold')::numeric
          OR (c.scenario_code='RECESSION_ENERGY' AND coalesce(c.scenario_eligible_sales_delta_rate_90d,0)<=(c.profile_payload->>'declining_scenario_delta_threshold')::numeric) THEN 'DECLINING'
        WHEN coalesce(c.daily_sales_cv_90d,0)>=(c.profile_payload->>'volatile_cv_threshold')::numeric THEN 'VOLATILE'
        WHEN coalesce(c.seasonality_index_180d,0)>=(c.profile_payload->>'seasonal_index_threshold')::numeric
          OR coalesce(c.largest_30d_share_180d,0)>=(c.profile_payload->>'seasonal_concentration_threshold')::numeric THEN 'SEASONAL'
        WHEN coalesce(c.sales_growth_30d_vs_90d,0)>=(c.profile_payload->>'growing_growth_threshold')::numeric
          AND coalesce(c.active_sales_day_rate_30d,0)>=(c.profile_payload->>'growing_active_sales_rate_min')::numeric THEN 'GROWING'
        ELSE 'STABLE' END AS independent_archetype,
   CASE WHEN c.composite_score IS NULL THEN 5
        WHEN c.composite_score>=(c.profile_payload->>'tier_1_score_min')::numeric THEN 1
        WHEN c.composite_score>=(c.profile_payload->>'tier_2_score_min')::numeric THEN 2
        WHEN c.composite_score>=(c.profile_payload->>'tier_3_score_min')::numeric THEN 3
        WHEN c.composite_score>=(c.profile_payload->>'tier_4_score_min')::numeric THEN 4 ELSE 5 END::smallint AS independent_tier
 FROM composite c
)
SELECT i.*,
 CASE i.independent_archetype WHEN 'GROWING' THEN 1 WHEN 'STABLE' THEN 1 WHEN 'SEASONAL' THEN 2
   WHEN 'VOLATILE' THEN 3 WHEN 'DECLINING' THEN 4 WHEN 'DISRUPTED' THEN 4 ELSE 5 END::smallint AS independent_archetype_rank
FROM interpreted i;
CREATE UNIQUE INDEX ON _m1_11_scored(scenario_id,merchant_application_id);

CREATE TEMP TABLE _m1_11_baseline ON COMMIT DROP AS
SELECT merchant_application_id,independent_tier AS baseline_tier,independent_archetype AS baseline_archetype,
       independent_archetype_rank AS baseline_archetype_rank
FROM _m1_11_scored WHERE scenario_code='BASELINE';
CREATE UNIQUE INDEX ON _m1_11_baseline(merchant_application_id);

DO $n$ BEGIN RAISE NOTICE 'M1.11 Phase 3/5 — apply matched stress floors, routing and reason evidence'; END $n$;

CREATE TEMP TABLE _m1_11_final ON COMMIT DROP AS
WITH f AS (
 SELECT s.*,b.baseline_tier,b.baseline_archetype,b.baseline_archetype_rank,
   CASE WHEN s.scenario_code='RECESSION_ENERGY' AND (s.profile_payload->>'stress_resilience_tier_floor_to_baseline')::boolean
        THEN greatest(s.independent_tier,b.baseline_tier) ELSE s.independent_tier END::smallint AS final_tier,
   CASE WHEN s.scenario_code='RECESSION_ENERGY' AND (s.profile_payload->>'stress_archetype_rank_floor_to_baseline')::boolean
             AND s.independent_archetype_rank<b.baseline_archetype_rank THEN b.baseline_archetype ELSE s.independent_archetype END AS final_archetype,
   CASE WHEN s.scenario_code='RECESSION_ENERGY' AND (s.profile_payload->>'stress_archetype_rank_floor_to_baseline')::boolean
        THEN greatest(s.independent_archetype_rank,b.baseline_archetype_rank) ELSE s.independent_archetype_rank END::smallint AS final_archetype_rank
 FROM _m1_11_scored s JOIN _m1_11_baseline b USING(merchant_application_id)
)
SELECT f.*,
  (f.scenario_code='RECESSION_ENERGY' AND f.final_tier>f.baseline_tier) AS stress_tier_worsening,
  (f.scenario_code='RECESSION_ENERGY' AND f.final_archetype_rank>f.baseline_archetype_rank) AS stress_archetype_worsening,
  CASE WHEN f.evidence_status='BLOCKED' THEN 'INSUFFICIENT_EVIDENCE'
       WHEN f.final_tier=1 THEN 'RESILIENT' WHEN f.final_tier=2 THEN 'ADEQUATE'
       WHEN f.final_tier=3 THEN 'WATCH' WHEN f.final_tier=4 THEN 'VULNERABLE' ELSE 'FRAGILE' END AS final_status,
  (f.upstream_manual_review_flag OR f.final_tier>=(f.profile_payload->>'review_tier_threshold')::integer
    OR f.evidence_status<>'COMPLETE' OR f.fraud_risk_tier>=(f.profile_payload->>'review_fraud_tier_threshold')::integer
    OR f.verification_disposition<>'CLEAR') AS manual_review,
  CASE WHEN f.evidence_status='BLOCKED' THEN 'INSUFFICIENT_CASHFLOW_EVIDENCE'
       WHEN f.verification_disposition<>'CLEAR' THEN 'VERIFICATION_REVIEW'
       WHEN f.processor_continuity_risk_tier>=4 THEN 'PROCESSOR_CONTINUITY_REVIEW'
       WHEN f.capacity_tier>=4 THEN 'CAPACITY_STRUCTURE_REVIEW'
       WHEN f.evidence_status='PARTIAL' THEN 'DATA_REFRESH'
       WHEN f.upstream_manual_review_flag THEN 'MANUAL_RESILIENCE_REVIEW' ELSE 'NONE' END AS fallback,
  CASE WHEN f.evidence_status='BLOCKED' THEN 'INSUFFICIENT_EVIDENCE'
       WHEN f.final_archetype='DISRUPTED' THEN 'OPERATING_DISRUPTION'
       WHEN f.final_archetype='DECLINING' THEN 'DECLINING_CASH_FLOW'
       WHEN f.final_archetype='VOLATILE' THEN 'HIGH_CASH_FLOW_VOLATILITY'
       WHEN f.final_archetype='THIN_HISTORY' THEN 'THIN_OPERATING_HISTORY'
       WHEN f.final_tier>=4 THEN 'LOW_OPERATING_RESILIENCE'
       WHEN f.final_archetype='SEASONAL' THEN 'SEASONAL_OPERATING_PATTERN'
       WHEN f.final_archetype='GROWING' THEN 'GROWING_OPERATING_PATTERN' ELSE 'STABLE_OPERATING_PATTERN' END AS primary_reason
FROM f;

CREATE TEMP TABLE _m1_11_expected (LIKE msbf_m1.application_operating_resilience_snapshot INCLUDING DEFAULTS) ON COMMIT DROP;
INSERT INTO _m1_11_expected(module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,as_of_date,merchant_size_tier,industry_code,relationship_stage,cashflow_feature_snapshot_hash,liquidity_capacity_snapshot_hash,source_confidence_score,data_confidence_tier,feature_completeness_status,capacity_evidence_status,verification_disposition,fraud_risk_tier,processor_continuity_risk_tier,pos_history_days,deposit_history_days,avg_daily_eligible_sales_30d,sales_growth_30d_vs_90d,daily_sales_cv_90d,zero_sales_day_rate_30d,active_sales_day_rate_30d,seasonality_index_180d,largest_30d_share_180d,processor_outage_day_rate_30d,processor_degraded_day_rate_30d,negative_balance_day_rate_30d,nsf_count_30d,cash_flow_buffer_days,sales_linked_payment_coverage_ratio,total_obligation_to_sales_rate,residual_daily_operating_cash_flow,post_financing_buffer_days,stacking_depth,obligation_concentration_rate,revenue_resilience_score,liquidity_resilience_score,burden_resilience_score,continuity_resilience_score,data_confidence_resilience_score,operating_resilience_score,independent_resilience_tier,baseline_resilience_tier,resilience_tier,independent_archetype_code,baseline_archetype_code,archetype_code,archetype_risk_rank,stress_resilience_worsening_flag,stress_archetype_worsening_flag,resilience_status,operating_resilience_evidence_status,manual_review_recommended_flag,fallback_path_code,primary_resilience_reason_code,secondary_resilience_reason_codes,row_hash,created_by_run_id,created_at)
SELECT module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,as_of_date,
 merchant_size_tier,industry_code,relationship_stage,cashflow_feature_snapshot_hash,liquidity_capacity_snapshot_hash,
 source_confidence_score,data_confidence_tier,feature_completeness_status,capacity_evidence_status,verification_disposition,
 fraud_risk_tier,processor_continuity_risk_tier,pos_history_days,deposit_history_days,avg_daily_eligible_sales_30d,
 sales_growth_30d_vs_90d,daily_sales_cv_90d,zero_sales_day_rate_30d,active_sales_day_rate_30d,seasonality_index_180d,
 largest_30d_share_180d,processor_outage_day_rate_30d,processor_degraded_day_rate_30d,negative_balance_day_rate_30d,
 nsf_count_30d,cash_flow_buffer_days,sales_linked_payment_coverage_ratio,total_obligation_to_sales_rate,
 residual_daily_operating_cash_flow,post_financing_buffer_days,stacking_depth,obligation_concentration_rate,
 revenue_score::numeric(9,6),liquidity_score::numeric(9,6),burden_score::numeric(9,6),continuity_score::numeric(9,6),
 data_score::numeric(9,6),composite_score::numeric(9,6),independent_tier,baseline_tier,final_tier,
 independent_archetype,baseline_archetype,final_archetype,final_archetype_rank,stress_tier_worsening,
 stress_archetype_worsening,final_status,evidence_status,manual_review,fallback,primary_reason,
 array_remove(ARRAY[
   CASE WHEN sales_growth_30d_vs_90d<0 THEN 'NEGATIVE_GROWTH' END,
   CASE WHEN daily_sales_cv_90d>=0.70 THEN 'HIGH_VOLATILITY' END,
   CASE WHEN negative_balance_day_rate_30d>0 THEN 'NEGATIVE_BALANCE_EVIDENCE' END,
   CASE WHEN sales_linked_payment_coverage_ratio<1 THEN 'LOW_PAYMENT_COVERAGE' END,
   CASE WHEN processor_outage_day_rate_30d>0 THEN 'PROCESSOR_OUTAGE_EVIDENCE' END,
   CASE WHEN evidence_status<>'COMPLETE' THEN 'INCOMPLETE_EVIDENCE' END
 ],NULL)::text[], 'PENDING',module1_run_id,clock_timestamp()
FROM _m1_11_final;
UPDATE _m1_11_expected e SET row_hash=msbf_m1.m1_11_hash_jsonb(to_jsonb(e)-'row_hash'-'created_at') WHERE row_hash='PENDING';
CREATE UNIQUE INDEX ON _m1_11_expected(module1_run_id,scenario_id,merchant_application_id);

INSERT INTO msbf_m1.application_operating_resilience_snapshot(module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,as_of_date,merchant_size_tier,industry_code,relationship_stage,cashflow_feature_snapshot_hash,liquidity_capacity_snapshot_hash,source_confidence_score,data_confidence_tier,feature_completeness_status,capacity_evidence_status,verification_disposition,fraud_risk_tier,processor_continuity_risk_tier,pos_history_days,deposit_history_days,avg_daily_eligible_sales_30d,sales_growth_30d_vs_90d,daily_sales_cv_90d,zero_sales_day_rate_30d,active_sales_day_rate_30d,seasonality_index_180d,largest_30d_share_180d,processor_outage_day_rate_30d,processor_degraded_day_rate_30d,negative_balance_day_rate_30d,nsf_count_30d,cash_flow_buffer_days,sales_linked_payment_coverage_ratio,total_obligation_to_sales_rate,residual_daily_operating_cash_flow,post_financing_buffer_days,stacking_depth,obligation_concentration_rate,revenue_resilience_score,liquidity_resilience_score,burden_resilience_score,continuity_resilience_score,data_confidence_resilience_score,operating_resilience_score,independent_resilience_tier,baseline_resilience_tier,resilience_tier,independent_archetype_code,baseline_archetype_code,archetype_code,archetype_risk_rank,stress_resilience_worsening_flag,stress_archetype_worsening_flag,resilience_status,operating_resilience_evidence_status,manual_review_recommended_flag,fallback_path_code,primary_resilience_reason_code,secondary_resilience_reason_codes,row_hash,created_by_run_id)
SELECT module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,as_of_date,merchant_size_tier,industry_code,relationship_stage,cashflow_feature_snapshot_hash,liquidity_capacity_snapshot_hash,source_confidence_score,data_confidence_tier,feature_completeness_status,capacity_evidence_status,verification_disposition,fraud_risk_tier,processor_continuity_risk_tier,pos_history_days,deposit_history_days,avg_daily_eligible_sales_30d,sales_growth_30d_vs_90d,daily_sales_cv_90d,zero_sales_day_rate_30d,active_sales_day_rate_30d,seasonality_index_180d,largest_30d_share_180d,processor_outage_day_rate_30d,processor_degraded_day_rate_30d,negative_balance_day_rate_30d,nsf_count_30d,cash_flow_buffer_days,sales_linked_payment_coverage_ratio,total_obligation_to_sales_rate,residual_daily_operating_cash_flow,post_financing_buffer_days,stacking_depth,obligation_concentration_rate,revenue_resilience_score,liquidity_resilience_score,burden_resilience_score,continuity_resilience_score,data_confidence_resilience_score,operating_resilience_score,independent_resilience_tier,baseline_resilience_tier,resilience_tier,independent_archetype_code,baseline_archetype_code,archetype_code,archetype_risk_rank,stress_resilience_worsening_flag,stress_archetype_worsening_flag,resilience_status,operating_resilience_evidence_status,manual_review_recommended_flag,fallback_path_code,primary_resilience_reason_code,secondary_resilience_reason_codes,row_hash,created_by_run_id FROM _m1_11_expected;
CREATE INDEX IF NOT EXISTS ix_m1_11_resilience_run_scenario_app ON msbf_m1.application_operating_resilience_snapshot(module1_run_id,scenario_id,merchant_application_id);
ANALYZE msbf_m1.application_operating_resilience_snapshot;

CREATE TEMP TABLE _m1_11_component_expected (LIKE msbf_m1.operating_resilience_component_value INCLUDING DEFAULTS) ON COMMIT DROP;
INSERT INTO _m1_11_component_expected(module1_run_id,scenario_id,merchant_application_id,component_code,component_version,component_score,component_weight,weighted_score,component_status,component_reason_code,lineage_hash,calculation_hash,created_by_run_id,created_at)
SELECT e.module1_run_id,e.scenario_id,e.merchant_application_id,v.component_code,1,
       v.component_score,v.component_weight,
       CASE WHEN v.component_score IS NULL THEN NULL ELSE round(v.component_score*v.component_weight,6) END,
       CASE WHEN v.component_score IS NULL THEN 'NOT_AVAILABLE' ELSE 'AVAILABLE' END,
       CASE WHEN v.component_score IS NULL THEN 'INPUT_NOT_AVAILABLE' ELSE 'CALCULATED_FROM_ACCEPTED_EVIDENCE' END,
       md5(e.cashflow_feature_snapshot_hash||'|'||e.liquidity_capacity_snapshot_hash||'|'||v.component_code),
       'PENDING',e.module1_run_id,clock_timestamp()
FROM _m1_11_expected e CROSS JOIN LATERAL (VALUES
 ('REVENUE_RESILIENCE_SCORE',e.revenue_resilience_score,(SELECT (profile_payload->>'component_weight_revenue')::numeric(9,6) FROM _m1_11_ctx)),
 ('LIQUIDITY_RESILIENCE_SCORE',e.liquidity_resilience_score,(SELECT (profile_payload->>'component_weight_liquidity')::numeric(9,6) FROM _m1_11_ctx)),
 ('BURDEN_RESILIENCE_SCORE',e.burden_resilience_score,(SELECT (profile_payload->>'component_weight_burden')::numeric(9,6) FROM _m1_11_ctx)),
 ('CONTINUITY_RESILIENCE_SCORE',e.continuity_resilience_score,(SELECT (profile_payload->>'component_weight_continuity')::numeric(9,6) FROM _m1_11_ctx)),
 ('DATA_CONFIDENCE_RESILIENCE_SCORE',e.data_confidence_resilience_score,(SELECT (profile_payload->>'component_weight_data_confidence')::numeric(9,6) FROM _m1_11_ctx))
) v(component_code,component_score,component_weight);
UPDATE _m1_11_component_expected c SET calculation_hash=msbf_m1.m1_11_hash_jsonb(to_jsonb(c)-'calculation_hash'-'created_at') WHERE calculation_hash='PENDING';
CREATE UNIQUE INDEX ON _m1_11_component_expected(module1_run_id,scenario_id,merchant_application_id,component_code,component_version);

INSERT INTO msbf_m1.operating_resilience_component_value(module1_run_id,scenario_id,merchant_application_id,component_code,component_version,component_score,component_weight,weighted_score,component_status,component_reason_code,lineage_hash,calculation_hash,created_by_run_id)
SELECT module1_run_id,scenario_id,merchant_application_id,component_code,component_version,component_score,component_weight,weighted_score,component_status,component_reason_code,lineage_hash,calculation_hash,created_by_run_id FROM _m1_11_component_expected;
ANALYZE msbf_m1.operating_resilience_component_value;

DO $n$ BEGIN RAISE NOTICE 'M1.11 Phase 4/5 — reconcile 9,000 canonical entities and set hashes'; END $n$;

CREATE TEMP TABLE _m1_11_expected_canonical ON COMMIT DROP AS
SELECT 'RESILIENCE|'||scenario_id||'|'||merchant_application_id AS entity_key,row_hash FROM _m1_11_expected
UNION ALL
SELECT 'COMPONENT|'||scenario_id||'|'||merchant_application_id||'|'||component_code||'|'||component_version,calculation_hash FROM _m1_11_component_expected;
CREATE UNIQUE INDEX ON _m1_11_expected_canonical(entity_key);
CREATE TEMP TABLE _m1_11_actual_canonical ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_11_actual_resilience((SELECT run_id FROM _m1_11_ctx))
UNION ALL SELECT * FROM msbf_m1.m1_11_actual_component((SELECT run_id FROM _m1_11_ctx));
CREATE UNIQUE INDEX ON _m1_11_actual_canonical(entity_key);
CREATE TEMP TABLE _m1_11_mismatch ON COMMIT DROP AS
SELECT coalesce(e.entity_key,a.entity_key) entity_key,e.row_hash expected_hash,a.row_hash actual_hash
FROM _m1_11_expected_canonical e FULL JOIN _m1_11_actual_canonical a USING(entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash;
CREATE TEMP TABLE _m1_11_hashes ON COMMIT DROP AS
SELECT
 (SELECT count(*) FROM _m1_11_expected_canonical) expected_entities,
 (SELECT count(*) FROM _m1_11_actual_canonical) actual_entities,
 (SELECT count(*) FROM _m1_11_mismatch) mismatches,
 (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM _m1_11_expected_canonical WHERE entity_key LIKE 'RESILIENCE|%') snapshot_hash,
 (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM _m1_11_expected_canonical WHERE entity_key LIKE 'COMPONENT|%') component_hash,
 (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM _m1_11_expected_canonical) combined_hash;

DO $$ DECLARE h record; BEGIN
 SELECT * INTO h FROM _m1_11_hashes;
 IF h.expected_entities<>9000 OR h.actual_entities<>9000 OR h.mismatches<>0 THEN
  RAISE EXCEPTION 'M1.11 canonical reconciliation failed: expected %, actual %, mismatches %.',h.expected_entities,h.actual_entities,h.mismatches;
 END IF;
END $$;

INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,threshold_value_numeric,interpretation)
SELECT run_id,evidence_code,'PORTFOLIO',metric_name,metric_value_numeric,metric_value_text,unit_code,'PASS',threshold_value_numeric,interpretation
FROM _m1_11_ctx CROSS JOIN LATERAL (VALUES
 ('M1_11_GENERATION_SPEC','M1.11 generation specification',NULL::numeric,'M1_11_METHOD_V1_1','TEXT',NULL::numeric,'Five transparent components; composite is the sum of persisted weighted values; matched archetypes, stress floors and controlled routing.'),
 ('M1_11_SNAPSHOT_ENTITY_COUNT','M1.11 resilience snapshot rows',1500::numeric,NULL,'ROWS',1500::numeric,'Exactly two scenario rows per accepted application.'),
 ('M1_11_COMPONENT_ENTITY_COUNT','M1.11 component rows',7500::numeric,NULL,'ROWS',7500::numeric,'Five component rows per snapshot.'),
 ('M1_11_CANONICAL_ENTITY_COUNT','M1.11 canonical entities',9000::numeric,NULL,'ROWS',9000::numeric,'Snapshot and component canonical universe.'),
 ('M1_11_CANONICAL_MISMATCH_COUNT','M1.11 deterministic mismatches',0::numeric,NULL,'ROWS',0::numeric,'Expected and persisted physical hashes reconcile.'),
 ('M1_11_SNAPSHOT_SET_HASH','M1.11 resilience snapshot set hash',NULL,(SELECT snapshot_hash FROM _m1_11_hashes),'HASH',NULL,'Governed deterministic snapshot identity.'),
 ('M1_11_COMPONENT_SET_HASH','M1.11 component set hash',NULL,(SELECT component_hash FROM _m1_11_hashes),'HASH',NULL,'Governed deterministic component identity.'),
 ('M1_11_COMBINED_SET_HASH','M1.11 combined set hash',NULL,(SELECT combined_hash FROM _m1_11_hashes),'HASH',NULL,'Combined M1.11 canonical identity.'),
 ('M1_11_GENERATION_SUMMARY','M1.11 generation summary',NULL,format('snapshots=1500|components=7500|canonical=9000|mismatches=0|hash=%s',(SELECT combined_hash FROM _m1_11_hashes)),'TEXT',NULL,'Committed M1.11 generation checkpoint.')
) v(evidence_code,metric_name,metric_value_numeric,metric_value_text,unit_code,threshold_value_numeric,interpretation)
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,
 metric_value_numeric=EXCLUDED.metric_value_numeric,metric_value_text=EXCLUDED.metric_value_text,
 unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,threshold_value_numeric=EXCLUDED.threshold_value_numeric,
 interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry SET run_status='M1_11_GENERATED',completed_at=NULL,
 notes=coalesce(notes,'')||E'\nM1.11 generated: 1,500 resilience snapshots and 7,500 component rows.'
WHERE run_id=(SELECT run_id FROM _m1_11_ctx);

COMMIT;
DO $n$ BEGIN RAISE NOTICE 'M1.11 Phase 5/5 — committed generation checkpoint'; END $n$;
SELECT r.run_id,r.run_status,
 (SELECT count(*) FROM msbf_m1.application_operating_resilience_snapshot WHERE module1_run_id=r.run_id) snapshot_rows,
 (SELECT count(*) FROM msbf_m1.operating_resilience_component_value WHERE module1_run_id=r.run_id) component_rows,
 (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.application_operating_resilience_snapshot WHERE module1_run_id=r.run_id) applications,
 (SELECT count(DISTINCT scenario_id) FROM msbf_m1.application_operating_resilience_snapshot WHERE module1_run_id=r.run_id) scenarios,
 (SELECT metric_value_numeric::bigint FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_11_CANONICAL_MISMATCH_COUNT' AND segment_key='PORTFOLIO') row_level_mismatches,
 (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_11_SNAPSHOT_SET_HASH' AND segment_key='PORTFOLIO') snapshot_hash,
 (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_11_COMPONENT_SET_HASH' AND segment_key='PORTFOLIO') component_hash,
 (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_11_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') combined_hash,
 CASE WHEN r.run_status='M1_11_GENERATED' THEN 'PASS' ELSE 'FAIL' END generation_status
FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;
