/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M2.1 — Eligibility, Policy Gates & Decision Routing Foundations

Program : 134_msbf_m2_1_eligibility_policy_routing_generation_v0_2R1.sql
Version : v0.2R1
Title   : Deterministic Eligibility, Policy-Gate and Routing Generation

Purpose
Consume the accepted 1,500-row G2 contract once, evaluate twelve transparent policy gates, aggregate independent routes, apply a matched stress non-improvement floor, persist scenario-aware routing snapshots and versioned latest/archive contracts, and reconcile every canonical entity before commit.

Inputs
Accepted msbf_m1.v_m1_17_g2_integrated_consumption, accepted G2 registry/gate and approved M2.1 policy/reference definitions.

Outputs
18,000 gate results, 1,500 analytical routing snapshots, 1,500 latest rows, 1,500 immutable archive rows, one contract registry row, 750 matched comparisons and 22,541 canonical entities.

Stage boundary
M2.1 creates eligibility and routing only. It does not create final price, factor, amount, remittance, duration, approval, adverse-action notice, funded outcome or M2.2 decision.

Execution standard
Run the complete file with DBeaver Execute SQL Script. Stop at the first
PostgreSQL error. Never use Retry, Skip or Skip All. Execute ROLLBACK after a
failed transactional program.
============================================================================ */

BEGIN;
SET LOCAL work_mem='128MB';
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='25min';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m2_1_ctx;
CREATE TEMP TABLE _m2_1_ctx ON COMMIT DROP AS
SELECT
    r.run_id,r.run_status,r.population_id,r.as_of_date,
    p.configuration_hash AS policy_configuration_hash,
    g.combined_g2_hash AS source_g2_combined_hash
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m1_17_g2_bundle_registry g ON g.module1_run_id=r.run_id
CROSS JOIN msbf_ctl.m2_1_policy_profile p
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
  AND p.policy_code='M2_1_ELIGIBILITY_POLICY_V1';

DO $m2_1_generation_readiness$
BEGIN
    PERFORM msbf_ctl.m2_1_assert_generation_ready((SELECT run_id FROM _m2_1_ctx));
END;
$m2_1_generation_readiness$;

/* Phase 1 — Materialize the accepted G2 contract exactly once. */
DROP TABLE IF EXISTS _m2_1_g2;
CREATE TEMP TABLE _m2_1_g2 ON COMMIT DROP AS
SELECT
    v.module1_run_id,v.scenario_id,v.scenario_code,v.merchant_application_id,
    v.population_id,v.merchant_id,v.as_of_date,v.industry_code,v.merchant_size_tier,
    v.relationship_stage,v.partner_channel_id,v.channel_type,v.source_confidence_score,
    v.data_confidence_tier,v.verification_disposition,v.fraud_risk_tier,
    v.processor_continuity_status,v.capacity_tier,v.affordability_status,v.archetype_code,
    v.operating_resilience_score,v.resilience_tier,v.integrated_risk_score,
    v.synthetic_merchant_risk_proxy,v.integrated_risk_tier,v.risk_adjusted_contribution_amount,
    v.annualized_risk_adjusted_return_rate,v.economic_tier,v.economic_status,
    v.hard_stop_recommended_flag,v.manual_review_recommended_flag,
    v.m1_15_contract_evidence_status,v.m1_15_contract_row_hash,
    v.primary_source_code,v.primary_campaign_id,v.attribution_confidence_tier,
    v.attribution_evidence_status,v.acquisition_contract_evidence_status,
    v.m1_16_contract_row_hash
FROM msbf_m1.v_m1_17_g2_integrated_consumption v
WHERE v.module1_run_id=(SELECT run_id FROM _m2_1_ctx);

CREATE UNIQUE INDEX ON _m2_1_g2(scenario_id,merchant_application_id);
CREATE INDEX ON _m2_1_g2(merchant_application_id,scenario_code);
ANALYZE _m2_1_g2;

DO $m2_1_input_guard$
DECLARE v_rows bigint; v_apps bigint; v_scenarios bigint; v_base bigint; v_stress bigint;
BEGIN
    SELECT count(*),count(DISTINCT merchant_application_id),count(DISTINCT scenario_id),
           count(*) FILTER(WHERE scenario_code='BASELINE'),
           count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY')
    INTO v_rows,v_apps,v_scenarios,v_base,v_stress FROM _m2_1_g2;
    IF v_rows<>1500 OR v_apps<>750 OR v_scenarios<>2 OR v_base<>750 OR v_stress<>750 THEN
        RAISE EXCEPTION 'M2.1 G2 input cardinality failed: rows %, apps %, scenarios %, baseline %, stress %.',
            v_rows,v_apps,v_scenarios,v_base,v_stress;
    END IF;
END;
$m2_1_input_guard$;

/* Phase 2 — Evaluate every transparent gate at scenario/application grain. */
DROP TABLE IF EXISTS _m2_1_gate_eval;
CREATE TEMP TABLE _m2_1_gate_eval ON COMMIT DROP AS
SELECT
    g.module1_run_id,'M2_1_CONTROLLED_ENTRY_BASELINE'::text AS strategy_campaign_code,1::integer AS strategy_campaign_version,
    g.scenario_id,g.scenario_code,g.merchant_application_id,g.population_id,g.merchant_id,
    d.gate_code,d.gate_sequence,
    CASE d.gate_code
      WHEN 'GATE_01_G2_CONTRACT_EVIDENCE' THEN
        CASE WHEN g.m1_15_contract_evidence_status='BLOCKED' THEN 'BLOCKED' ELSE 'PASS' END
      WHEN 'GATE_02_DATA_CONFIDENCE' THEN
        CASE WHEN g.data_confidence_tier='HIGH' THEN 'PASS'
             WHEN g.data_confidence_tier='MEDIUM' THEN 'REVIEW'
             ELSE 'BLOCKED' END
      WHEN 'GATE_03_VERIFICATION' THEN
        CASE WHEN g.verification_disposition='CLEAR' THEN 'PASS'
             WHEN g.verification_disposition='REVIEW' THEN 'REVIEW'
             WHEN g.verification_disposition='STOP' THEN 'FAIL'
             ELSE 'BLOCKED' END
      WHEN 'GATE_04_FRAUD_RISK' THEN
        CASE WHEN g.fraud_risk_tier IS NULL THEN 'BLOCKED'
             WHEN g.fraud_risk_tier>=4 THEN 'FAIL'
             WHEN g.fraud_risk_tier=3 THEN 'REVIEW'
             ELSE 'PASS' END
      WHEN 'GATE_05_PROCESSOR_CONTINUITY' THEN
        CASE WHEN g.processor_continuity_status IS NULL THEN 'BLOCKED'
             WHEN g.processor_continuity_status IN ('WATCH','DISRUPTED','UNAVAILABLE') THEN 'REVIEW'
             ELSE 'PASS' END
      WHEN 'GATE_06_CAPACITY' THEN
        CASE WHEN g.capacity_tier IS NULL OR g.capacity_tier=5 THEN 'BLOCKED'
             WHEN g.capacity_tier=4 THEN 'FAIL'
             WHEN g.capacity_tier=3 THEN 'REVIEW'
             ELSE 'PASS' END
      WHEN 'GATE_07_AFFORDABILITY' THEN
        CASE WHEN g.affordability_status IS NULL OR g.affordability_status='INSUFFICIENT_EVIDENCE' THEN 'BLOCKED'
             WHEN g.affordability_status='UNAFFORDABLE' THEN 'FAIL'
             WHEN g.affordability_status='MARGINAL' THEN 'REVIEW'
             ELSE 'PASS' END
      WHEN 'GATE_08_RESILIENCE' THEN
        CASE WHEN g.resilience_tier IS NULL OR g.resilience_tier=5 THEN 'BLOCKED'
             WHEN g.resilience_tier=4 THEN 'FAIL'
             WHEN g.resilience_tier=3 THEN 'REVIEW'
             ELSE 'PASS' END
      WHEN 'GATE_09_INTEGRATED_RISK' THEN
        CASE WHEN g.integrated_risk_tier IS NULL OR g.integrated_risk_tier=5 THEN 'BLOCKED'
             WHEN g.integrated_risk_tier=4 THEN 'FAIL'
             WHEN g.integrated_risk_tier=3 THEN 'REVIEW'
             ELSE 'PASS' END
      WHEN 'GATE_10_UNIT_ECONOMICS' THEN
        CASE WHEN g.economic_tier IS NULL OR g.economic_tier=5 OR g.economic_status='INSUFFICIENT_EVIDENCE' THEN 'BLOCKED'
             WHEN g.economic_status='NEGATIVE_CONTRIBUTION' THEN 'FAIL'
             WHEN g.economic_status='BELOW_HURDLE' OR g.economic_tier IN (3,4) THEN 'REVIEW'
             ELSE 'PASS' END
      WHEN 'GATE_11_UPSTREAM_HARD_STOP' THEN
        CASE WHEN g.hard_stop_recommended_flag THEN 'FAIL' ELSE 'PASS' END
      WHEN 'GATE_12_ACQUISITION_EVIDENCE' THEN
        CASE WHEN g.acquisition_contract_evidence_status='BLOCKED'
                   OR g.attribution_evidence_status='BLOCKED' THEN 'REVIEW'
             ELSE 'PASS' END
      ELSE 'BLOCKED'
    END AS gate_outcome,
    CASE d.gate_code
      WHEN 'GATE_01_G2_CONTRACT_EVIDENCE' THEN g.m1_15_contract_evidence_status
      WHEN 'GATE_02_DATA_CONFIDENCE' THEN coalesce(g.data_confidence_tier,'<NULL>')
      WHEN 'GATE_03_VERIFICATION' THEN coalesce(g.verification_disposition,'<NULL>')
      WHEN 'GATE_04_FRAUD_RISK' THEN coalesce(g.fraud_risk_tier::text,'<NULL>')
      WHEN 'GATE_05_PROCESSOR_CONTINUITY' THEN coalesce(g.processor_continuity_status,'<NULL>')
      WHEN 'GATE_06_CAPACITY' THEN coalesce(g.capacity_tier::text,'<NULL>')
      WHEN 'GATE_07_AFFORDABILITY' THEN coalesce(g.affordability_status,'<NULL>')
      WHEN 'GATE_08_RESILIENCE' THEN coalesce(g.resilience_tier::text,'<NULL>')
      WHEN 'GATE_09_INTEGRATED_RISK' THEN coalesce(g.integrated_risk_tier::text,'<NULL>')
      WHEN 'GATE_10_UNIT_ECONOMICS' THEN concat_ws('|',coalesce(g.economic_tier::text,'<NULL>'),coalesce(g.economic_status,'<NULL>'))
      WHEN 'GATE_11_UPSTREAM_HARD_STOP' THEN g.hard_stop_recommended_flag::text
      WHEN 'GATE_12_ACQUISITION_EVIDENCE' THEN concat_ws('|',g.acquisition_contract_evidence_status,g.attribution_evidence_status)
      ELSE '<UNRESOLVED>' END AS observed_value_text,
    CASE d.gate_code
      WHEN 'GATE_01_G2_CONTRACT_EVIDENCE' THEN 'COMPLETE or PARTIAL; BLOCKED is insufficient'
      WHEN 'GATE_02_DATA_CONFIDENCE' THEN 'HIGH pass; MEDIUM review; LOW blocked'
      WHEN 'GATE_03_VERIFICATION' THEN 'CLEAR pass; REVIEW review; STOP fail'
      WHEN 'GATE_04_FRAUD_RISK' THEN '1-2 pass; 3 review; 4-5 fail'
      WHEN 'GATE_05_PROCESSOR_CONTINUITY' THEN 'STABLE/MONITORED pass; WATCH/DISRUPTED/UNAVAILABLE review'
      WHEN 'GATE_06_CAPACITY' THEN '1-2 pass; 3 review; 4 fail; 5 blocked'
      WHEN 'GATE_07_AFFORDABILITY' THEN 'AFFORDABLE pass; MARGINAL review; UNAFFORDABLE fail'
      WHEN 'GATE_08_RESILIENCE' THEN '1-2 pass; 3 review; 4 fail; 5 blocked'
      WHEN 'GATE_09_INTEGRATED_RISK' THEN '1-2 pass; 3 review; 4 fail; 5 blocked'
      WHEN 'GATE_10_UNIT_ECONOMICS' THEN 'ABOVE_HURDLE pass; BELOW_HURDLE review; NEGATIVE fail; tier 5 blocked'
      WHEN 'GATE_11_UPSTREAM_HARD_STOP' THEN 'false pass; true fail'
      WHEN 'GATE_12_ACQUISITION_EVIDENCE' THEN 'COMPLETE/PARTIAL pass; BLOCKED review only'
      ELSE '<UNRESOLVED>' END AS threshold_value_text,
    d.hard_stop_capable_flag,
    g.m1_15_contract_row_hash AS source_m1_15_contract_row_hash,
    g.m1_16_contract_row_hash AS source_m1_16_contract_row_hash,
    (SELECT source_g2_combined_hash FROM _m2_1_ctx) AS source_g2_combined_hash,
    (SELECT policy_configuration_hash FROM _m2_1_ctx) AS policy_configuration_hash
FROM _m2_1_g2 g
CROSS JOIN msbf_m2.policy_gate_definition d
WHERE d.module1_run_id=g.module1_run_id
  AND d.strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE'
  AND d.active_flag;

CREATE INDEX ON _m2_1_gate_eval(scenario_id,merchant_application_id,gate_sequence);
ANALYZE _m2_1_gate_eval;

DROP TABLE IF EXISTS _m2_1_gate_typed;
CREATE TEMP TABLE _m2_1_gate_typed ON COMMIT DROP AS
SELECT
    e.module1_run_id::bigint,e.strategy_campaign_code::text,e.strategy_campaign_version::integer,
    e.scenario_id::bigint,e.scenario_code::text,e.merchant_application_id::text,e.population_id::text,
    e.merchant_id::text,e.gate_code::text,e.gate_sequence::integer,e.gate_outcome::text,
    CASE e.gate_outcome WHEN 'PASS' THEN 1 WHEN 'REVIEW' THEN 2 WHEN 'BLOCKED' THEN 3 WHEN 'FAIL' THEN 4 END::integer AS gate_outcome_rank,
    (e.hard_stop_capable_flag AND e.gate_outcome='FAIL')::boolean AS hard_stop_flag,
    CASE
      WHEN d.gate_code='GATE_01_G2_CONTRACT_EVIDENCE' AND e.gate_outcome='BLOCKED' THEN 'M2_1_G2_EVIDENCE_BLOCKED'
      WHEN d.gate_code='GATE_02_DATA_CONFIDENCE' AND e.gate_outcome='BLOCKED' THEN 'M2_1_DATA_CONFIDENCE_LOW'
      WHEN d.gate_code='GATE_02_DATA_CONFIDENCE' AND e.gate_outcome='REVIEW' THEN 'M2_1_DATA_CONFIDENCE_REVIEW'
      WHEN d.gate_code='GATE_03_VERIFICATION' AND e.gate_outcome='FAIL' THEN 'M2_1_VERIFICATION_STOP'
      WHEN d.gate_code='GATE_03_VERIFICATION' AND e.gate_outcome='BLOCKED' THEN 'M2_1_VERIFICATION_INSUFFICIENT'
      WHEN d.gate_code='GATE_03_VERIFICATION' AND e.gate_outcome='REVIEW' THEN 'M2_1_VERIFICATION_REVIEW'
      WHEN d.gate_code='GATE_04_FRAUD_RISK' AND e.gate_outcome='FAIL' THEN 'M2_1_FRAUD_POLICY_FAIL'
      WHEN d.gate_code='GATE_04_FRAUD_RISK' AND e.gate_outcome='REVIEW' THEN 'M2_1_FRAUD_REVIEW'
      WHEN d.gate_code='GATE_05_PROCESSOR_CONTINUITY' AND e.gate_outcome='REVIEW' THEN 'M2_1_PROCESSOR_CONTINUITY_REVIEW'
      WHEN d.gate_code='GATE_06_CAPACITY' AND e.gate_outcome='FAIL' THEN 'M2_1_CAPACITY_FAIL'
      WHEN d.gate_code='GATE_06_CAPACITY' AND e.gate_outcome='REVIEW' THEN 'M2_1_CAPACITY_REVIEW'
      WHEN d.gate_code='GATE_06_CAPACITY' AND e.gate_outcome='BLOCKED' THEN 'M2_1_CAPACITY_FAIL'
      WHEN d.gate_code='GATE_07_AFFORDABILITY' AND e.gate_outcome='FAIL' THEN 'M2_1_AFFORDABILITY_FAIL'
      WHEN d.gate_code='GATE_07_AFFORDABILITY' AND e.gate_outcome='REVIEW' THEN 'M2_1_AFFORDABILITY_REVIEW'
      WHEN d.gate_code='GATE_07_AFFORDABILITY' AND e.gate_outcome='BLOCKED' THEN 'M2_1_G2_EVIDENCE_BLOCKED'
      WHEN d.gate_code='GATE_08_RESILIENCE' AND e.gate_outcome='FAIL' THEN 'M2_1_RESILIENCE_FAIL'
      WHEN d.gate_code='GATE_08_RESILIENCE' AND e.gate_outcome='REVIEW' THEN 'M2_1_RESILIENCE_REVIEW'
      WHEN d.gate_code='GATE_08_RESILIENCE' AND e.gate_outcome='BLOCKED' THEN 'M2_1_G2_EVIDENCE_BLOCKED'
      WHEN d.gate_code='GATE_09_INTEGRATED_RISK' AND e.gate_outcome='FAIL' THEN 'M2_1_INTEGRATED_RISK_FAIL'
      WHEN d.gate_code='GATE_09_INTEGRATED_RISK' AND e.gate_outcome='REVIEW' THEN 'M2_1_INTEGRATED_RISK_REVIEW'
      WHEN d.gate_code='GATE_09_INTEGRATED_RISK' AND e.gate_outcome='BLOCKED' THEN 'M2_1_G2_EVIDENCE_BLOCKED'
      WHEN d.gate_code='GATE_10_UNIT_ECONOMICS' AND e.gate_outcome='FAIL' THEN 'M2_1_NEGATIVE_CONTRIBUTION'
      WHEN d.gate_code='GATE_10_UNIT_ECONOMICS' AND e.gate_outcome='REVIEW' THEN 'M2_1_ECONOMICS_REVIEW'
      WHEN d.gate_code='GATE_10_UNIT_ECONOMICS' AND e.gate_outcome='BLOCKED' THEN 'M2_1_G2_EVIDENCE_BLOCKED'
      WHEN d.gate_code='GATE_11_UPSTREAM_HARD_STOP' AND e.gate_outcome='FAIL' THEN 'M2_1_UPSTREAM_HARD_STOP'
      WHEN d.gate_code='GATE_12_ACQUISITION_EVIDENCE' AND e.gate_outcome='REVIEW' THEN 'M2_1_ACQUISITION_EVIDENCE_REVIEW'
      ELSE NULL END::text AS reason_code,
    e.observed_value_text::text,e.threshold_value_text::text,
    CASE e.gate_outcome WHEN 'PASS' THEN 'COMPLETE' WHEN 'REVIEW' THEN 'PARTIAL' ELSE 'BLOCKED' END::text AS gate_evidence_status,
    e.source_m1_15_contract_row_hash::text,e.source_m1_16_contract_row_hash::text,
    e.source_g2_combined_hash::text,e.policy_configuration_hash::text
FROM _m2_1_gate_eval e
JOIN msbf_m2.policy_gate_definition d
  ON d.module1_run_id=e.module1_run_id
 AND d.strategy_campaign_code=e.strategy_campaign_code
 AND d.gate_code=e.gate_code;

DROP TABLE IF EXISTS _m2_1_gate_expected;
CREATE TEMP TABLE _m2_1_gate_expected ON COMMIT DROP AS
SELECT t.*,msbf_ctl.m2_1_hash_jsonb(to_jsonb(t)) AS row_hash
FROM _m2_1_gate_typed t;
CREATE UNIQUE INDEX ON _m2_1_gate_expected(scenario_id,merchant_application_id,gate_code);
ANALYZE _m2_1_gate_expected;

DO $m2_1_gate_guard$
DECLARE v_rows bigint; v_grains bigint; v_invalid bigint; v_unavailable_mismatches bigint;
BEGIN
 SELECT count(*),count(DISTINCT (scenario_id,merchant_application_id,gate_code)),
        count(*) FILTER(WHERE gate_outcome NOT IN ('PASS','REVIEW','BLOCKED','FAIL') OR gate_outcome_rank NOT BETWEEN 1 AND 4),
        count(*) FILTER(WHERE gate_code='GATE_05_PROCESSOR_CONTINUITY'
                         AND observed_value_text='UNAVAILABLE'
                         AND gate_outcome<>'REVIEW')
 INTO v_rows,v_grains,v_invalid,v_unavailable_mismatches FROM _m2_1_gate_expected;
 IF v_rows<>18000 OR v_grains<>18000 OR v_invalid<>0 OR v_unavailable_mismatches<>0 THEN
  RAISE EXCEPTION 'M2.1 gate population failed: rows %, grains %, invalid %, unavailable continuity mismatches %.',
    v_rows,v_grains,v_invalid,v_unavailable_mismatches;
 END IF;
END;
$m2_1_gate_guard$;

/* Phase 3 — Aggregate independent routes and reason priority. */
DROP TABLE IF EXISTS _m2_1_route_independent;
CREATE TEMP TABLE _m2_1_route_independent ON COMMIT DROP AS
WITH aggregated AS (
 SELECT
  g.module1_run_id,g.strategy_campaign_code,g.strategy_campaign_version,g.scenario_id,g.scenario_code,
  g.merchant_application_id,g.population_id,g.merchant_id,
  count(*) FILTER(WHERE g.gate_outcome='PASS')::integer AS pass_gate_count,
  count(*) FILTER(WHERE g.gate_outcome='REVIEW')::integer AS review_gate_count,
  count(*) FILTER(WHERE g.gate_outcome='BLOCKED')::integer AS blocked_gate_count,
  count(*) FILTER(WHERE g.gate_outcome='FAIL')::integer AS fail_gate_count,
  count(*) FILTER(WHERE g.hard_stop_flag)::integer AS hard_stop_gate_count,
  coalesce(array_agg(g.reason_code ORDER BY g.hard_stop_flag DESC,g.gate_outcome_rank DESC,r.reason_priority DESC,g.gate_sequence)
           FILTER(WHERE g.reason_code IS NOT NULL),ARRAY[]::text[]) AS ordered_reason_codes
 FROM _m2_1_gate_expected g
 LEFT JOIN msbf_m2.reason_code_definition r
   ON r.module1_run_id=g.module1_run_id AND r.strategy_campaign_code=g.strategy_campaign_code
  AND r.reason_code=g.reason_code
 GROUP BY g.module1_run_id,g.strategy_campaign_code,g.strategy_campaign_version,g.scenario_id,g.scenario_code,
          g.merchant_application_id,g.population_id,g.merchant_id
), routed AS (
 SELECT a.*,
  CASE WHEN fail_gate_count>0 THEN 4 WHEN blocked_gate_count>0 THEN 3
       WHEN review_gate_count>0 THEN 2 ELSE 1 END::integer AS independent_route_rank
 FROM aggregated a
)
SELECT r.*,
       msbf_ctl.m2_1_route_code(r.independent_route_rank) AS independent_route_code,
       coalesce(r.ordered_reason_codes[1],'M2_1_ELIGIBLE_ALL_GATES_PASS') AS primary_reason_code,
       r.ordered_reason_codes[2] AS secondary_reason_code,
       r.ordered_reason_codes[3] AS tertiary_reason_code,
       to_jsonb(CASE WHEN cardinality(r.ordered_reason_codes)=0
                     THEN ARRAY['M2_1_ELIGIBLE_ALL_GATES_PASS']::text[]
                     ELSE r.ordered_reason_codes END) AS reason_codes,
       (r.hard_stop_gate_count>0) AS hard_stop_flag
FROM routed r;
CREATE UNIQUE INDEX ON _m2_1_route_independent(scenario_id,merchant_application_id);
ANALYZE _m2_1_route_independent;

DROP TABLE IF EXISTS _m2_1_baseline_route;
CREATE TEMP TABLE _m2_1_baseline_route ON COMMIT DROP AS
SELECT merchant_application_id,independent_route_code AS baseline_route_code,
       independent_route_rank AS baseline_route_rank,primary_reason_code AS baseline_primary_reason_code,
       hard_stop_flag AS baseline_hard_stop_flag
FROM _m2_1_route_independent WHERE scenario_code='BASELINE';
CREATE UNIQUE INDEX ON _m2_1_baseline_route(merchant_application_id);
ANALYZE _m2_1_baseline_route;

/* Phase 4 — Apply matched stress non-improvement and build target-typed snapshots. */
DROP TABLE IF EXISTS _m2_1_snapshot_typed;
CREATE TEMP TABLE _m2_1_snapshot_typed ON COMMIT DROP AS
WITH joined AS (
 SELECT
        g.module1_run_id,g.scenario_id,g.scenario_code,g.merchant_application_id,
        g.population_id,g.merchant_id,g.as_of_date,g.industry_code,g.merchant_size_tier,
        g.relationship_stage,g.data_confidence_tier,g.verification_disposition,
        g.fraud_risk_tier,g.processor_continuity_status,g.capacity_tier,
        g.affordability_status,g.resilience_tier,g.integrated_risk_tier,
        g.economic_tier,g.economic_status,g.m1_15_contract_evidence_status,
        g.acquisition_contract_evidence_status,g.m1_15_contract_row_hash,
        g.m1_16_contract_row_hash,
        i.pass_gate_count,i.review_gate_count,i.blocked_gate_count,i.fail_gate_count,
        i.hard_stop_gate_count,i.independent_route_code,i.independent_route_rank,
        i.primary_reason_code AS independent_primary_reason_code,
        i.secondary_reason_code AS independent_secondary_reason_code,
        i.tertiary_reason_code AS independent_tertiary_reason_code,
        i.reason_codes AS independent_reason_codes,i.hard_stop_flag AS independent_hard_stop_flag,
        b.baseline_route_code,b.baseline_route_rank,b.baseline_primary_reason_code,b.baseline_hard_stop_flag
 FROM _m2_1_g2 g
 JOIN _m2_1_route_independent i
   ON i.scenario_id=g.scenario_id AND i.merchant_application_id=g.merchant_application_id
 JOIN _m2_1_baseline_route b ON b.merchant_application_id=g.merchant_application_id
), finalised AS (
 SELECT j.*,
   CASE WHEN j.scenario_code='RECESSION_ENERGY'
        THEN greatest(j.independent_route_rank,j.baseline_route_rank)
        ELSE j.independent_route_rank END::integer AS final_route_rank,
   (j.scenario_code='RECESSION_ENERGY' AND j.independent_route_rank<j.baseline_route_rank) AS stress_floor_applied_flag
 FROM joined j
)
SELECT
 f.module1_run_id::bigint,'M2_1_CONTROLLED_ENTRY_BASELINE'::text AS strategy_campaign_code,1::integer AS strategy_campaign_version,
 f.scenario_id::bigint,f.scenario_code::text,f.merchant_application_id::text,f.population_id::text,f.merchant_id::text,
 f.as_of_date::date,f.industry_code::text,f.merchant_size_tier::text,f.relationship_stage::text,
 f.data_confidence_tier::text,f.verification_disposition::text,f.fraud_risk_tier::integer,
 f.processor_continuity_status::text,f.capacity_tier::integer,f.affordability_status::text,
 f.resilience_tier::integer,f.integrated_risk_tier::integer,f.economic_tier::integer,f.economic_status::text,
 f.m1_15_contract_evidence_status::text,f.acquisition_contract_evidence_status::text,
 f.independent_route_code::text,f.independent_route_rank::integer,
 f.baseline_route_code::text,f.baseline_route_rank::integer,
 msbf_ctl.m2_1_route_code(f.final_route_rank)::text AS final_route_code,f.final_route_rank::integer,
 f.pass_gate_count::integer,f.review_gate_count::integer,f.blocked_gate_count::integer,f.fail_gate_count::integer,
 f.hard_stop_gate_count::integer,
 (f.independent_hard_stop_flag OR (f.stress_floor_applied_flag AND f.baseline_hard_stop_flag))::boolean AS hard_stop_flag,
 (f.final_route_rank=1)::boolean AS eligible_for_offer_design_flag,
 f.stress_floor_applied_flag::boolean,
 (f.scenario_code='RECESSION_ENERGY' AND f.final_route_rank>f.baseline_route_rank)::boolean AS stress_worsening_flag,
 CASE WHEN f.stress_floor_applied_flag THEN f.baseline_primary_reason_code ELSE f.independent_primary_reason_code END::text AS primary_reason_code,
 CASE WHEN f.stress_floor_applied_flag THEN 'M2_1_STRESS_NONIMPROVEMENT_FLOOR' ELSE f.independent_secondary_reason_code END::text AS secondary_reason_code,
 CASE WHEN f.stress_floor_applied_flag THEN f.independent_primary_reason_code ELSE f.independent_tertiary_reason_code END::text AS tertiary_reason_code,
 CASE WHEN f.stress_floor_applied_flag THEN
      to_jsonb(array_remove(ARRAY[f.baseline_primary_reason_code,'M2_1_STRESS_NONIMPROVEMENT_FLOOR',
                                 f.independent_primary_reason_code,f.independent_secondary_reason_code,
                                 f.independent_tertiary_reason_code]::text[],NULL))
      ELSE f.independent_reason_codes END AS reason_codes,
 CASE WHEN f.final_route_rank=3 THEN 'BLOCKED'
      WHEN f.m1_15_contract_evidence_status='PARTIAL'
        OR f.acquisition_contract_evidence_status='PARTIAL'
        OR f.final_route_rank IN (2,4) THEN 'PARTIAL'
      ELSE 'COMPLETE' END::text AS routing_evidence_status,
 f.m1_15_contract_row_hash::text AS source_m1_15_contract_row_hash,
 f.m1_16_contract_row_hash::text AS source_m1_16_contract_row_hash,
 (SELECT source_g2_combined_hash FROM _m2_1_ctx)::text AS source_g2_combined_hash,
 (SELECT policy_configuration_hash FROM _m2_1_ctx)::text AS policy_configuration_hash
FROM finalised f;

DROP TABLE IF EXISTS _m2_1_snapshot_expected;
CREATE TEMP TABLE _m2_1_snapshot_expected ON COMMIT DROP AS
SELECT t.*,msbf_ctl.m2_1_hash_jsonb(to_jsonb(t)) AS row_hash FROM _m2_1_snapshot_typed t;
CREATE UNIQUE INDEX ON _m2_1_snapshot_expected(scenario_id,merchant_application_id);
ANALYZE _m2_1_snapshot_expected;

DO $m2_1_snapshot_guard$
DECLARE v_rows bigint; v_apps bigint; v_invalid bigint; v_improvements bigint;
BEGIN
 SELECT count(*),count(DISTINCT merchant_application_id),
        count(*) FILTER(WHERE final_route_rank NOT BETWEEN 1 AND 4 OR final_route_code IS NULL
                         OR pass_gate_count+review_gate_count+blocked_gate_count+fail_gate_count<>12),
        count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY' AND final_route_rank<baseline_route_rank)
 INTO v_rows,v_apps,v_invalid,v_improvements FROM _m2_1_snapshot_expected;
 IF v_rows<>1500 OR v_apps<>750 OR v_invalid<>0 OR v_improvements<>0 THEN
  RAISE EXCEPTION 'M2.1 snapshot guard failed: rows %, apps %, invalid %, stress improvements %.',
    v_rows,v_apps,v_invalid,v_improvements;
 END IF;
END;
$m2_1_snapshot_guard$;

DROP TABLE IF EXISTS _m2_1_latest_typed;
CREATE TEMP TABLE _m2_1_latest_typed ON COMMIT DROP AS
SELECT
 s.module1_run_id,'M2_ELIGIBILITY_ROUTING_CONSUMPTION'::text AS contract_code,1::integer AS contract_version,
 'M2_1_ROUTING_SCHEMA_V1'::text AS schema_version,'M2_1_METHOD_V1'::text AS methodology_version,
 s.strategy_campaign_code,s.strategy_campaign_version,s.scenario_id,s.scenario_code,
 s.merchant_application_id,s.population_id,s.merchant_id,s.as_of_date,
 s.final_route_code,s.final_route_rank,s.independent_route_code,s.independent_route_rank,
 s.baseline_route_code,s.baseline_route_rank,s.eligible_for_offer_design_flag,s.hard_stop_flag,
 s.stress_floor_applied_flag,s.stress_worsening_flag,s.pass_gate_count,s.review_gate_count,
 s.blocked_gate_count,s.fail_gate_count,s.primary_reason_code,s.secondary_reason_code,
 s.tertiary_reason_code,s.reason_codes,s.routing_evidence_status,s.source_m1_15_contract_row_hash,
 s.source_m1_16_contract_row_hash,s.source_g2_combined_hash,s.policy_configuration_hash
FROM _m2_1_snapshot_expected s;

DROP TABLE IF EXISTS _m2_1_latest_expected;
CREATE TEMP TABLE _m2_1_latest_expected ON COMMIT DROP AS
SELECT t.*,msbf_ctl.m2_1_hash_jsonb(to_jsonb(t)) AS contract_row_hash FROM _m2_1_latest_typed t;
CREATE UNIQUE INDEX ON _m2_1_latest_expected(scenario_id,merchant_application_id);
ANALYZE _m2_1_latest_expected;

DROP TABLE IF EXISTS _m2_1_archive_expected;
CREATE TEMP TABLE _m2_1_archive_expected ON COMMIT DROP AS
WITH payload AS (
 SELECT l.module1_run_id,l.contract_code,l.contract_version,l.schema_version,l.strategy_campaign_code,
        l.scenario_id,l.merchant_application_id,to_jsonb(l) AS contract_payload,
        l.contract_row_hash,l.contract_row_hash AS source_latest_row_hash
 FROM _m2_1_latest_expected l
)
SELECT p.*,msbf_ctl.m2_1_hash_jsonb(to_jsonb(p)) AS archive_row_hash FROM payload p;
CREATE UNIQUE INDEX ON _m2_1_archive_expected(scenario_id,merchant_application_id);
ANALYZE _m2_1_archive_expected;

/* Phase 5 — Persist expected records with explicit projections. */
INSERT INTO msbf_m2.application_policy_gate_result(
 module1_run_id,strategy_campaign_code,strategy_campaign_version,scenario_id,scenario_code,
 merchant_application_id,population_id,merchant_id,gate_code,gate_sequence,gate_outcome,
 gate_outcome_rank,hard_stop_flag,reason_code,observed_value_text,threshold_value_text,
 gate_evidence_status,source_m1_15_contract_row_hash,source_m1_16_contract_row_hash,
 source_g2_combined_hash,policy_configuration_hash,row_hash
)
SELECT module1_run_id,strategy_campaign_code,strategy_campaign_version,scenario_id,scenario_code,
 merchant_application_id,population_id,merchant_id,gate_code,gate_sequence,gate_outcome,
 gate_outcome_rank,hard_stop_flag,reason_code,observed_value_text,threshold_value_text,
 gate_evidence_status,source_m1_15_contract_row_hash,source_m1_16_contract_row_hash,
 source_g2_combined_hash,policy_configuration_hash,row_hash
FROM _m2_1_gate_expected;

INSERT INTO msbf_m2.application_eligibility_routing_snapshot(
 module1_run_id,strategy_campaign_code,strategy_campaign_version,scenario_id,scenario_code,
 merchant_application_id,population_id,merchant_id,as_of_date,industry_code,merchant_size_tier,
 relationship_stage,data_confidence_tier,verification_disposition,fraud_risk_tier,
 processor_continuity_status,capacity_tier,affordability_status,resilience_tier,
 integrated_risk_tier,economic_tier,economic_status,m1_15_contract_evidence_status,
 acquisition_contract_evidence_status,independent_route_code,independent_route_rank,
 baseline_route_code,baseline_route_rank,final_route_code,final_route_rank,pass_gate_count,
 review_gate_count,blocked_gate_count,fail_gate_count,hard_stop_gate_count,hard_stop_flag,
 eligible_for_offer_design_flag,stress_floor_applied_flag,stress_worsening_flag,
 primary_reason_code,secondary_reason_code,tertiary_reason_code,reason_codes,
 routing_evidence_status,source_m1_15_contract_row_hash,source_m1_16_contract_row_hash,
 source_g2_combined_hash,policy_configuration_hash,row_hash
)
SELECT module1_run_id,strategy_campaign_code,strategy_campaign_version,scenario_id,scenario_code,
 merchant_application_id,population_id,merchant_id,as_of_date,industry_code,merchant_size_tier,
 relationship_stage,data_confidence_tier,verification_disposition,fraud_risk_tier,
 processor_continuity_status,capacity_tier,affordability_status,resilience_tier,
 integrated_risk_tier,economic_tier,economic_status,m1_15_contract_evidence_status,
 acquisition_contract_evidence_status,independent_route_code,independent_route_rank,
 baseline_route_code,baseline_route_rank,final_route_code,final_route_rank,pass_gate_count,
 review_gate_count,blocked_gate_count,fail_gate_count,hard_stop_gate_count,hard_stop_flag,
 eligible_for_offer_design_flag,stress_floor_applied_flag,stress_worsening_flag,
 primary_reason_code,secondary_reason_code,tertiary_reason_code,reason_codes,
 routing_evidence_status,source_m1_15_contract_row_hash,source_m1_16_contract_row_hash,
 source_g2_combined_hash,policy_configuration_hash,row_hash
FROM _m2_1_snapshot_expected;

INSERT INTO msbf_m2.application_eligibility_routing_latest(
 module1_run_id,contract_code,contract_version,schema_version,methodology_version,
 strategy_campaign_code,strategy_campaign_version,scenario_id,scenario_code,
 merchant_application_id,population_id,merchant_id,as_of_date,final_route_code,final_route_rank,
 independent_route_code,independent_route_rank,baseline_route_code,baseline_route_rank,
 eligible_for_offer_design_flag,hard_stop_flag,stress_floor_applied_flag,stress_worsening_flag,
 pass_gate_count,review_gate_count,blocked_gate_count,fail_gate_count,primary_reason_code,
 secondary_reason_code,tertiary_reason_code,reason_codes,routing_evidence_status,
 source_m1_15_contract_row_hash,source_m1_16_contract_row_hash,source_g2_combined_hash,
 policy_configuration_hash,contract_row_hash
)
SELECT module1_run_id,contract_code,contract_version,schema_version,methodology_version,
 strategy_campaign_code,strategy_campaign_version,scenario_id,scenario_code,
 merchant_application_id,population_id,merchant_id,as_of_date,final_route_code,final_route_rank,
 independent_route_code,independent_route_rank,baseline_route_code,baseline_route_rank,
 eligible_for_offer_design_flag,hard_stop_flag,stress_floor_applied_flag,stress_worsening_flag,
 pass_gate_count,review_gate_count,blocked_gate_count,fail_gate_count,primary_reason_code,
 secondary_reason_code,tertiary_reason_code,reason_codes,routing_evidence_status,
 source_m1_15_contract_row_hash,source_m1_16_contract_row_hash,source_g2_combined_hash,
 policy_configuration_hash,contract_row_hash
FROM _m2_1_latest_expected;

INSERT INTO msbf_m2.application_eligibility_routing_archive(
 module1_run_id,contract_code,contract_version,schema_version,strategy_campaign_code,
 scenario_id,merchant_application_id,contract_payload,contract_row_hash,source_latest_row_hash,
 archive_row_hash
)
SELECT module1_run_id,contract_code,contract_version,schema_version,strategy_campaign_code,
 scenario_id,merchant_application_id,contract_payload,contract_row_hash,source_latest_row_hash,
 archive_row_hash
FROM _m2_1_archive_expected;

ANALYZE msbf_m2.application_policy_gate_result;
ANALYZE msbf_m2.application_eligibility_routing_snapshot;
ANALYZE msbf_m2.application_eligibility_routing_latest;
ANALYZE msbf_m2.application_eligibility_routing_archive;

/* Phase 6 — Set hashes, registry, and canonical reconciliation. */
DROP TABLE IF EXISTS _m2_1_hashes;
CREATE TEMP TABLE _m2_1_hashes ON COMMIT DROP AS
SELECT
 (SELECT md5(string_agg(row_hash,'|' ORDER BY strategy_campaign_code,strategy_campaign_version)) FROM msbf_m2.strategy_campaign WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx)) AS campaign_set_hash,
 (SELECT md5(string_agg(row_hash,'|' ORDER BY gate_sequence)) FROM msbf_m2.policy_gate_definition WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx)) AS gate_definition_set_hash,
 (SELECT md5(string_agg(row_hash,'|' ORDER BY reason_code)) FROM msbf_m2.reason_code_definition WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx)) AS reason_code_set_hash,
 (SELECT md5(string_agg(row_hash,'|' ORDER BY route_rank)) FROM msbf_m2.routing_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx)) AS outcome_definition_set_hash,
 (SELECT md5(string_agg(row_hash,'|' ORDER BY scenario_id,merchant_application_id,gate_sequence)) FROM msbf_m2.application_policy_gate_result WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx)) AS gate_result_set_hash,
 (SELECT md5(string_agg(row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx)) AS routing_snapshot_set_hash,
 (SELECT md5(string_agg(contract_row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx)) AS latest_set_hash,
 (SELECT md5(string_agg(archive_row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx)) AS archive_set_hash;

DROP TABLE IF EXISTS _m2_1_registry_expected;
CREATE TEMP TABLE _m2_1_registry_expected ON COMMIT DROP AS
WITH base AS (
 SELECT
  (SELECT run_id FROM _m2_1_ctx)::bigint AS module1_run_id,'M2_ELIGIBILITY_ROUTING_CONSUMPTION'::text AS contract_code,
  1::integer AS contract_version,'M2_1_ROUTING_SCHEMA_V1'::text AS schema_version,'M2_1_METHOD_V1'::text AS methodology_version,
  'M1_G2_CONSUMPTION_BUNDLE'::text AS source_g2_bundle_code,1::integer AS source_g2_bundle_version,
  'M1_G2_BUNDLE_SCHEMA_V1'::text AS source_g2_schema_version,'7d9e466da28cad2551aa99c4c40c912b'::text AS source_g2_combined_hash,
  (SELECT policy_configuration_hash FROM _m2_1_ctx)::text AS policy_configuration_hash,
  1::bigint AS strategy_campaign_rows,12::bigint AS gate_definition_rows,23::bigint AS reason_code_rows,
  4::bigint AS outcome_definition_rows,18000::bigint AS gate_result_rows,1500::bigint AS routing_snapshot_rows,
  1500::bigint AS latest_rows,1500::bigint AS archive_rows,750::bigint AS comparison_rows,
  22541::bigint AS canonical_entities,h.*
 FROM _m2_1_hashes h
), hashed AS (
 SELECT b.*,msbf_ctl.m2_1_hash_jsonb(to_jsonb(b)) AS row_hash FROM base b
)
SELECT h.*,md5(h.row_hash) AS contract_set_hash FROM hashed h;

DROP TABLE IF EXISTS _m2_1_expected_canonical;
CREATE TEMP TABLE _m2_1_expected_canonical(entity_type text,entity_key text,row_hash text) ON COMMIT DROP;
INSERT INTO _m2_1_expected_canonical SELECT 'CAMPAIGN',strategy_campaign_code||'|v'||strategy_campaign_version,row_hash FROM msbf_m2.strategy_campaign WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
INSERT INTO _m2_1_expected_canonical SELECT 'GATE_DEFINITION',gate_code,row_hash FROM msbf_m2.policy_gate_definition WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
INSERT INTO _m2_1_expected_canonical SELECT 'REASON_CODE',reason_code,row_hash FROM msbf_m2.reason_code_definition WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
INSERT INTO _m2_1_expected_canonical SELECT 'OUTCOME',route_code,row_hash FROM msbf_m2.routing_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
INSERT INTO _m2_1_expected_canonical SELECT 'GATE_RESULT',scenario_id||'|'||merchant_application_id||'|'||gate_code,row_hash FROM _m2_1_gate_expected;
INSERT INTO _m2_1_expected_canonical SELECT 'ROUTING_SNAPSHOT',scenario_id||'|'||merchant_application_id,row_hash FROM _m2_1_snapshot_expected;
INSERT INTO _m2_1_expected_canonical SELECT 'LATEST',scenario_id||'|'||merchant_application_id,contract_row_hash FROM _m2_1_latest_expected;
INSERT INTO _m2_1_expected_canonical SELECT 'ARCHIVE',scenario_id||'|'||merchant_application_id,archive_row_hash FROM _m2_1_archive_expected;
INSERT INTO _m2_1_expected_canonical SELECT 'REGISTRY',contract_code||'|v'||contract_version,row_hash FROM _m2_1_registry_expected;
CREATE UNIQUE INDEX ON _m2_1_expected_canonical(entity_type,entity_key);

DROP TABLE IF EXISTS _m2_1_combined_hash;
CREATE TEMP TABLE _m2_1_combined_hash ON COMMIT DROP AS
SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'|' ORDER BY entity_type,entity_key)) AS combined_set_hash
FROM _m2_1_expected_canonical;

INSERT INTO msbf_ctl.m2_1_strategy_contract_registry(
 module1_run_id,contract_code,contract_version,schema_version,methodology_version,
 source_g2_bundle_code,source_g2_bundle_version,source_g2_schema_version,source_g2_combined_hash,
 policy_configuration_hash,strategy_campaign_rows,gate_definition_rows,reason_code_rows,
 outcome_definition_rows,gate_result_rows,routing_snapshot_rows,latest_rows,archive_rows,
 comparison_rows,canonical_entities,campaign_set_hash,gate_definition_set_hash,reason_code_set_hash,
 outcome_definition_set_hash,gate_result_set_hash,routing_snapshot_set_hash,latest_set_hash,
 archive_set_hash,contract_set_hash,combined_set_hash,contract_status,generated_at,row_hash
)
SELECT r.module1_run_id,r.contract_code,r.contract_version,r.schema_version,r.methodology_version,
 r.source_g2_bundle_code,r.source_g2_bundle_version,r.source_g2_schema_version,r.source_g2_combined_hash,
 r.policy_configuration_hash,r.strategy_campaign_rows,r.gate_definition_rows,r.reason_code_rows,
 r.outcome_definition_rows,r.gate_result_rows,r.routing_snapshot_rows,r.latest_rows,r.archive_rows,
 r.comparison_rows,r.canonical_entities,r.campaign_set_hash,r.gate_definition_set_hash,r.reason_code_set_hash,
 r.outcome_definition_set_hash,r.gate_result_set_hash,r.routing_snapshot_set_hash,r.latest_set_hash,
 r.archive_set_hash,r.contract_set_hash,c.combined_set_hash,'GENERATED',clock_timestamp(),r.row_hash
FROM _m2_1_registry_expected r CROSS JOIN _m2_1_combined_hash c;

DROP TABLE IF EXISTS _m2_1_actual_canonical;
CREATE TEMP TABLE _m2_1_actual_canonical(entity_type text,entity_key text,row_hash text) ON COMMIT DROP;
INSERT INTO _m2_1_actual_canonical SELECT 'CAMPAIGN',strategy_campaign_code||'|v'||strategy_campaign_version,row_hash FROM msbf_m2.strategy_campaign WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
INSERT INTO _m2_1_actual_canonical SELECT 'GATE_DEFINITION',gate_code,row_hash FROM msbf_m2.policy_gate_definition WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
INSERT INTO _m2_1_actual_canonical SELECT 'REASON_CODE',reason_code,row_hash FROM msbf_m2.reason_code_definition WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
INSERT INTO _m2_1_actual_canonical SELECT 'OUTCOME',route_code,row_hash FROM msbf_m2.routing_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
INSERT INTO _m2_1_actual_canonical SELECT 'GATE_RESULT',scenario_id||'|'||merchant_application_id||'|'||gate_code,row_hash FROM msbf_m2.application_policy_gate_result WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
INSERT INTO _m2_1_actual_canonical SELECT 'ROUTING_SNAPSHOT',scenario_id||'|'||merchant_application_id,row_hash FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
INSERT INTO _m2_1_actual_canonical SELECT 'LATEST',scenario_id||'|'||merchant_application_id,contract_row_hash FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
INSERT INTO _m2_1_actual_canonical SELECT 'ARCHIVE',scenario_id||'|'||merchant_application_id,archive_row_hash FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
INSERT INTO _m2_1_actual_canonical SELECT 'REGISTRY',contract_code||'|v'||contract_version,row_hash FROM msbf_ctl.m2_1_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
CREATE UNIQUE INDEX ON _m2_1_actual_canonical(entity_type,entity_key);

DROP TABLE IF EXISTS _m2_1_mismatch;
CREATE TEMP TABLE _m2_1_mismatch ON COMMIT DROP AS
SELECT coalesce(e.entity_type,a.entity_type) AS entity_type,coalesce(e.entity_key,a.entity_key) AS entity_key,
       e.row_hash AS expected_hash,a.row_hash AS actual_hash
FROM _m2_1_expected_canonical e
FULL JOIN _m2_1_actual_canonical a
  ON a.entity_type=e.entity_type AND a.entity_key=e.entity_key
WHERE e.row_hash IS DISTINCT FROM a.row_hash;

DO $m2_1_reconciliation_guard$
DECLARE v_expected bigint; v_actual bigint; v_mismatch bigint; v_combined text; v_stored text;
BEGIN
 SELECT count(*) INTO v_expected FROM _m2_1_expected_canonical;
 SELECT count(*) INTO v_actual FROM _m2_1_actual_canonical;
 SELECT count(*) INTO v_mismatch FROM _m2_1_mismatch;
 SELECT combined_set_hash INTO v_combined FROM _m2_1_combined_hash;
 SELECT combined_set_hash INTO v_stored FROM msbf_ctl.m2_1_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_1_ctx);
 IF v_expected<>22541 OR v_actual<>22541 OR v_mismatch<>0 OR v_combined IS DISTINCT FROM v_stored THEN
  RAISE EXCEPTION 'M2.1 canonical reconciliation failed: expected %, actual %, mismatches %, hashes %/%',
    v_expected,v_actual,v_mismatch,v_combined,v_stored;
 END IF;
END;
$m2_1_reconciliation_guard$;

/* Phase 7 — Persist target-typed generation evidence and advance lifecycle. */
DROP TABLE IF EXISTS _m2_1_generation_evidence;
CREATE TEMP TABLE _m2_1_generation_evidence(
 run_id bigint NOT NULL,evidence_code text NOT NULL,segment_key text NOT NULL,metric_name text NOT NULL,
 metric_value_numeric numeric(24,10),metric_value_text text,unit_code text NOT NULL,status text NOT NULL,
 interpretation text NOT NULL,CONSTRAINT ck_m2_1_generation_evidence CHECK(num_nonnulls(metric_value_numeric,metric_value_text)=1)
) ON COMMIT DROP;

INSERT INTO _m2_1_generation_evidence VALUES
((SELECT run_id FROM _m2_1_ctx),'M2_1_CAMPAIGN_ROW_COUNT','PORTFOLIO','STRATEGY_CAMPAIGN_ROWS',1,NULL,'ROWS','PASS','One approved baseline strategy campaign.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_GATE_DEFINITION_ROW_COUNT','PORTFOLIO','GATE_DEFINITION_ROWS',12,NULL,'ROWS','PASS','Twelve governed policy gates.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_REASON_CODE_ROW_COUNT','PORTFOLIO','REASON_CODE_ROWS',23,NULL,'ROWS','PASS','Twenty-three transparent reason codes.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_OUTCOME_DEFINITION_ROW_COUNT','PORTFOLIO','OUTCOME_DEFINITION_ROWS',4,NULL,'ROWS','PASS','Four governed routing outcomes.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_GATE_RESULT_ROW_COUNT','PORTFOLIO','GATE_RESULT_ROWS',18000,NULL,'ROWS','PASS','Twelve gate results for each G2 row.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_ROUTING_SNAPSHOT_ROW_COUNT','PORTFOLIO','ROUTING_SNAPSHOT_ROWS',1500,NULL,'ROWS','PASS','One scenario-aware snapshot per accepted G2 row.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_LATEST_ROW_COUNT','PORTFOLIO','LATEST_ROWS',1500,NULL,'ROWS','PASS','One latest routing contract per scenario/application.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_ARCHIVE_ROW_COUNT','PORTFOLIO','ARCHIVE_ROWS',1500,NULL,'ROWS','PASS','One immutable archive copy per latest row.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_COMPARISON_ROW_COUNT','PORTFOLIO','MATCHED_COMPARISON_ROWS',750,NULL,'ROWS','PASS','One matched baseline/stress comparison per application.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_CANONICAL_ENTITY_COUNT','PORTFOLIO','CANONICAL_ENTITIES',22541,NULL,'ROWS','PASS','Complete deterministic canonical universe.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_CANONICAL_MISMATCH_COUNT','PORTFOLIO','CANONICAL_MISMATCHES',0,NULL,'ROWS','PASS','Expected and actual canonical records reconcile.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_CAMPAIGN_SET_HASH','PORTFOLIO','CAMPAIGN_SET_HASH',NULL,(SELECT campaign_set_hash FROM _m2_1_hashes),'HASH','PASS','Campaign set hash.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_GATE_DEFINITION_SET_HASH','PORTFOLIO','GATE_DEFINITION_SET_HASH',NULL,(SELECT gate_definition_set_hash FROM _m2_1_hashes),'HASH','PASS','Gate-definition set hash.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_REASON_CODE_SET_HASH','PORTFOLIO','REASON_CODE_SET_HASH',NULL,(SELECT reason_code_set_hash FROM _m2_1_hashes),'HASH','PASS','Reason-code set hash.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_OUTCOME_DEFINITION_SET_HASH','PORTFOLIO','OUTCOME_DEFINITION_SET_HASH',NULL,(SELECT outcome_definition_set_hash FROM _m2_1_hashes),'HASH','PASS','Outcome-definition set hash.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_GATE_RESULT_SET_HASH','PORTFOLIO','GATE_RESULT_SET_HASH',NULL,(SELECT gate_result_set_hash FROM _m2_1_hashes),'HASH','PASS','Gate-result set hash.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_ROUTING_SNAPSHOT_SET_HASH','PORTFOLIO','ROUTING_SNAPSHOT_SET_HASH',NULL,(SELECT routing_snapshot_set_hash FROM _m2_1_hashes),'HASH','PASS','Routing-snapshot set hash.'),
((SELECT run_id FROM _m2_1_ctx),'M2_1_COMBINED_SET_HASH','PORTFOLIO','COMBINED_SET_HASH',NULL,(SELECT combined_set_hash FROM _m2_1_combined_hash),'HASH','PASS','Complete M2.1 combined canonical hash.');

INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
 metric_value_text,unit_code,status,interpretation)
SELECT run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,
 unit_code,status,interpretation FROM _m2_1_generation_evidence;

UPDATE msbf_ctl.run_registry
SET run_status='M2_1_GENERATED',notes=coalesce(notes,'')||' | M2.1 generated: eligibility, policy gates, and routing contract.'
WHERE run_id=(SELECT run_id FROM _m2_1_ctx);

COMMIT;

SELECT
 r.run_status,1::bigint AS strategy_campaign_rows,12::bigint AS gate_definition_rows,
 23::bigint AS reason_code_rows,4::bigint AS outcome_definition_rows,
 18000::bigint AS gate_result_rows,1500::bigint AS routing_snapshot_rows,
 1500::bigint AS latest_rows,1500::bigint AS archive_rows,750::bigint AS comparison_rows,
 22541::bigint AS canonical_entities,0::bigint AS row_level_mismatches,
 c.campaign_set_hash,c.gate_definition_set_hash,c.reason_code_set_hash,c.outcome_definition_set_hash,
 c.gate_result_set_hash,c.routing_snapshot_set_hash,c.latest_set_hash,c.archive_set_hash,
 c.contract_set_hash,c.combined_set_hash,'PASS'::text AS generation_status
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m2_1_strategy_contract_registry c ON c.module1_run_id=r.run_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;
