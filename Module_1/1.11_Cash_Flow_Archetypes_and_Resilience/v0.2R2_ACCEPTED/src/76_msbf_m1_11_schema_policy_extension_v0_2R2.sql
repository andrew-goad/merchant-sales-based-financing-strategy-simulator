/* ============================================================================
MSBF M1.11 Cash-Flow Archetypes & Operating Resilience — Schema and Policy Extension
Version : v0.2R2
Purpose : Register the M1.11 gate, feature family, governed archetype/resilience
          definitions, scenario-aware resilience snapshot, component evidence,
          lineage view, and approved policy profile.
Boundary: Metadata and schema only. No M1.11 operating-resilience evidence is
          generated and the accepted M1.10 run status is not changed.
============================================================================ */
BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='5min';

INSERT INTO msbf_ref.acceptance_gate_catalog(
    gate_id,gate_name,module_code,severity,description
) VALUES (
    'M1_11_CASHFLOW_ARCHETYPE_RESILIENCE',
    'M1.11 Cash-Flow Archetypes and Operating Resilience',
    'M1','BLOCKING',
    'Transparent scenario-aware operating archetypes, component resilience scores, matched stress migration, and evidence routing acceptance.'
)
ON CONFLICT(gate_id) DO UPDATE SET
    gate_name=EXCLUDED.gate_name,module_code=EXCLUDED.module_code,
    severity=EXCLUDED.severity,active_flag=true,description=EXCLUDED.description;

INSERT INTO msbf_ref.feature_family(
    feature_family_code,feature_family_name,owner_role,description
) VALUES (
    'OPERATING_RESILIENCE','Operating Resilience','Credit Risk',
    'Revenue, liquidity, burden, processor-continuity, data-confidence, archetype and composite operating-resilience evidence.'
)
ON CONFLICT(feature_family_code) DO UPDATE SET
    feature_family_name=EXCLUDED.feature_family_name,
    owner_role=EXCLUDED.owner_role,description=EXCLUDED.description;

INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,
    valid_min_numeric,valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES
('REVENUE_RESILIENCE_SCORE',1,'Revenue Resilience Score','OPERATING_RESILIENCE','NUMERIC','SCORE',90,'Transparent score from growth, volatility, zero-sales frequency, and revenue concentration.','LOWER_RISK',0,100,'Credit Risk',true,'Synthetic operating-resilience evidence; not a calibrated credit-risk model.'),
('LIQUIDITY_RESILIENCE_SCORE',1,'Liquidity Resilience Score','OPERATING_RESILIENCE','NUMERIC','SCORE',30,'Transparent score from post-financing buffer days, negative-balance frequency, NSF events, and cash-flow buffer days.','LOWER_RISK',0,100,'Credit Risk',true,'Synthetic operating-resilience evidence; not a calibrated credit-risk model.'),
('BURDEN_RESILIENCE_SCORE',1,'Burden Resilience Score','OPERATING_RESILIENCE','NUMERIC','SCORE',NULL,'Transparent score from payment coverage, obligation-to-sales burden, residual cash flow, and stacking depth.','LOWER_RISK',0,100,'Credit Risk',true,'Synthetic operating-resilience evidence; not a calibrated credit-risk model.'),
('CONTINUITY_RESILIENCE_SCORE',1,'Processor Continuity Resilience Score','OPERATING_RESILIENCE','NUMERIC','SCORE',30,'Transparent score from processor outage, degradation, and accepted continuity tier evidence.','LOWER_RISK',0,100,'Credit Risk',true,'Synthetic operating-resilience evidence; not a calibrated credit-risk model.'),
('DATA_CONFIDENCE_RESILIENCE_SCORE',1,'Data Confidence Resilience Score','OPERATING_RESILIENCE','NUMERIC','SCORE',NULL,'Source-confidence score adjusted for accepted feature-completeness evidence.','LOWER_RISK',0,100,'Credit Risk',true,'Synthetic operating-resilience evidence; not a calibrated credit-risk model.'),
('OPERATING_RESILIENCE_SCORE',1,'Composite Operating Resilience Score','OPERATING_RESILIENCE','NUMERIC','SCORE',NULL,'Sum of five persisted six-decimal weighted operating-resilience component values.','LOWER_RISK',0,100,'Credit Risk',true,'Synthetic operating-resilience evidence; not a calibrated credit-risk model.'),
('OPERATING_RESILIENCE_TIER',1,'Operating Resilience Tier','OPERATING_RESILIENCE','NUMERIC','TIER',NULL,'Governed operating-resilience tier from one through five.','HIGHER_RISK',1,5,'Credit Risk',true,'Synthetic operating-resilience evidence; not a calibrated credit-risk model.'),
('OPERATING_ARCHETYPE_RISK_RANK',1,'Operating Archetype Risk Rank','OPERATING_RESILIENCE','NUMERIC','TIER',NULL,'Governed ordinal risk rank assigned to the transparent operating archetype.','HIGHER_RISK',1,5,'Credit Risk',true,'Synthetic operating-resilience evidence; not a calibrated credit-risk model.')
ON CONFLICT(feature_code,feature_version) DO UPDATE SET
    feature_name=EXCLUDED.feature_name,
    feature_family_code=EXCLUDED.feature_family_code,
    data_type=EXCLUDED.data_type,
    unit_code=EXCLUDED.unit_code,
    observation_window_days=EXCLUDED.observation_window_days,
    formula_description=EXCLUDED.formula_description,
    expected_direction=EXCLUDED.expected_direction,
    valid_min_numeric=EXCLUDED.valid_min_numeric,
    valid_max_numeric=EXCLUDED.valid_max_numeric,
    owner_role=EXCLUDED.owner_role,
    active_flag=true,
    production_boundary=EXCLUDED.production_boundary;

CREATE TABLE IF NOT EXISTS msbf_m1.application_operating_resilience_snapshot (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    merchant_size_tier text NOT NULL,
    industry_code text NOT NULL,
    relationship_stage text NOT NULL,
    cashflow_feature_snapshot_hash text NOT NULL,
    liquidity_capacity_snapshot_hash text NOT NULL,
    source_confidence_score numeric(9,6) NOT NULL,
    data_confidence_tier text NOT NULL,
    feature_completeness_status text NOT NULL,
    capacity_evidence_status text NOT NULL,
    verification_disposition text NOT NULL,
    fraud_risk_tier smallint NOT NULL,
    processor_continuity_risk_tier smallint NOT NULL,
    pos_history_days integer NOT NULL,
    deposit_history_days integer NOT NULL,
    avg_daily_eligible_sales_30d numeric(18,2),
    sales_growth_30d_vs_90d numeric(12,8),
    daily_sales_cv_90d numeric(12,8),
    zero_sales_day_rate_30d numeric(12,8),
    active_sales_day_rate_30d numeric(12,8),
    seasonality_index_180d numeric(12,8),
    largest_30d_share_180d numeric(12,8),
    processor_outage_day_rate_30d numeric(12,8),
    processor_degraded_day_rate_30d numeric(12,8),
    negative_balance_day_rate_30d numeric(12,8),
    nsf_count_30d integer,
    cash_flow_buffer_days numeric(12,4),
    sales_linked_payment_coverage_ratio numeric(12,8),
    total_obligation_to_sales_rate numeric(12,8),
    residual_daily_operating_cash_flow numeric(18,2),
    post_financing_buffer_days numeric(12,4),
    stacking_depth smallint,
    obligation_concentration_rate numeric(12,8),
    revenue_resilience_score numeric(9,6),
    liquidity_resilience_score numeric(9,6),
    burden_resilience_score numeric(9,6),
    continuity_resilience_score numeric(9,6),
    data_confidence_resilience_score numeric(9,6),
    operating_resilience_score numeric(9,6),
    independent_resilience_tier smallint NOT NULL,
    baseline_resilience_tier smallint NOT NULL,
    resilience_tier smallint NOT NULL,
    independent_archetype_code text NOT NULL,
    baseline_archetype_code text NOT NULL,
    archetype_code text NOT NULL,
    archetype_risk_rank smallint NOT NULL,
    stress_resilience_worsening_flag boolean NOT NULL,
    stress_archetype_worsening_flag boolean NOT NULL,
    resilience_status text NOT NULL,
    operating_resilience_evidence_status text NOT NULL,
    manual_review_recommended_flag boolean NOT NULL,
    fallback_path_code text NOT NULL,
    primary_resilience_reason_code text NOT NULL,
    secondary_resilience_reason_codes text[] DEFAULT '{}'::text[] NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_m1_11_resilience PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m1_11_resilience_confidence CHECK(source_confidence_score BETWEEN 0 AND 1),
    CONSTRAINT ck_m1_11_resilience_scores CHECK(
        (revenue_resilience_score IS NULL OR revenue_resilience_score BETWEEN 0 AND 100) AND
        (liquidity_resilience_score IS NULL OR liquidity_resilience_score BETWEEN 0 AND 100) AND
        (burden_resilience_score IS NULL OR burden_resilience_score BETWEEN 0 AND 100) AND
        (continuity_resilience_score IS NULL OR continuity_resilience_score BETWEEN 0 AND 100) AND
        (data_confidence_resilience_score IS NULL OR data_confidence_resilience_score BETWEEN 0 AND 100) AND
        (operating_resilience_score IS NULL OR operating_resilience_score BETWEEN 0 AND 100)),
    CONSTRAINT ck_m1_11_resilience_history CHECK(pos_history_days>=0 AND deposit_history_days>=0),
    CONSTRAINT ck_m1_11_resilience_tiers CHECK(
        independent_resilience_tier BETWEEN 1 AND 5 AND
        baseline_resilience_tier BETWEEN 1 AND 5 AND
        resilience_tier BETWEEN 1 AND 5 AND archetype_risk_rank BETWEEN 1 AND 5),
    CONSTRAINT ck_m1_11_resilience_archetype CHECK(
        independent_archetype_code IN ('STABLE','GROWING','DECLINING','SEASONAL','VOLATILE','THIN_HISTORY','DISRUPTED','INSUFFICIENT_EVIDENCE') AND
        baseline_archetype_code IN ('STABLE','GROWING','DECLINING','SEASONAL','VOLATILE','THIN_HISTORY','DISRUPTED','INSUFFICIENT_EVIDENCE') AND
        archetype_code IN ('STABLE','GROWING','DECLINING','SEASONAL','VOLATILE','THIN_HISTORY','DISRUPTED','INSUFFICIENT_EVIDENCE')),
    CONSTRAINT ck_m1_11_resilience_status CHECK(
        resilience_status IN ('RESILIENT','ADEQUATE','WATCH','VULNERABLE','FRAGILE','INSUFFICIENT_EVIDENCE')),
    CONSTRAINT ck_m1_11_resilience_evidence CHECK(
        operating_resilience_evidence_status IN ('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_m1_11_resilience_fallback CHECK(
        fallback_path_code IN ('NONE','DATA_REFRESH','INSUFFICIENT_CASHFLOW_EVIDENCE','PROCESSOR_CONTINUITY_REVIEW','CAPACITY_STRUCTURE_REVIEW','MANUAL_RESILIENCE_REVIEW','VERIFICATION_REVIEW','SOURCE_CONFLICT_REVIEW')),
    CONSTRAINT ck_m1_11_resilience_run_lineage CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_m1_11_resilience_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_11_resilience_scenario FOREIGN KEY(scenario_id) REFERENCES msbf_ctl.scenario_registry(scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_11_resilience_application FOREIGN KEY(merchant_application_id) REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_11_resilience_population FOREIGN KEY(population_id) REFERENCES msbf_m1.population_registry(population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_11_resilience_merchant FOREIGN KEY(merchant_id) REFERENCES msbf_m1.merchant_master(merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_11_resilience_feature FOREIGN KEY(module1_run_id,scenario_id,merchant_application_id)
        REFERENCES msbf_m1.application_cashflow_feature_snapshot(module1_run_id,scenario_id,merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_11_resilience_capacity FOREIGN KEY(module1_run_id,scenario_id,merchant_application_id)
        REFERENCES msbf_m1.application_liquidity_capacity_snapshot(module1_run_id,scenario_id,merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_11_resilience_created_run FOREIGN KEY(created_by_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.application_operating_resilience_snapshot IS
'Scenario-aware M1.11 transparent operating archetype, component resilience, matched stress migration, and controlled routing evidence.';
CREATE INDEX IF NOT EXISTS ix_m1_11_resilience_status
    ON msbf_m1.application_operating_resilience_snapshot(module1_run_id,scenario_id,resilience_tier,resilience_status);
CREATE INDEX IF NOT EXISTS ix_m1_11_resilience_archetype
    ON msbf_m1.application_operating_resilience_snapshot(module1_run_id,scenario_id,archetype_code);
CREATE INDEX IF NOT EXISTS ix_m1_11_resilience_review
    ON msbf_m1.application_operating_resilience_snapshot(module1_run_id,manual_review_recommended_flag,fallback_path_code);

CREATE TABLE IF NOT EXISTS msbf_m1.operating_resilience_component_value (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    component_code text NOT NULL,
    component_version integer DEFAULT 1 NOT NULL,
    component_score numeric(9,6),
    component_weight numeric(9,6) NOT NULL,
    weighted_score numeric(12,6),
    component_status text NOT NULL,
    component_reason_code text NOT NULL,
    lineage_hash text NOT NULL,
    calculation_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_m1_11_component PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id,component_code,component_version),
    CONSTRAINT ck_m1_11_component_code CHECK(component_code IN ('REVENUE_RESILIENCE_SCORE','LIQUIDITY_RESILIENCE_SCORE','BURDEN_RESILIENCE_SCORE','CONTINUITY_RESILIENCE_SCORE','DATA_CONFIDENCE_RESILIENCE_SCORE')),
    CONSTRAINT ck_m1_11_component_score CHECK(component_score IS NULL OR component_score BETWEEN 0 AND 100),
    CONSTRAINT ck_m1_11_component_weight CHECK(component_weight BETWEEN 0 AND 1),
    CONSTRAINT ck_m1_11_component_weighted CHECK(weighted_score IS NULL OR weighted_score BETWEEN 0 AND 100),
    CONSTRAINT ck_m1_11_component_status CHECK(component_status IN ('AVAILABLE','NOT_AVAILABLE')),
    CONSTRAINT ck_m1_11_component_presence CHECK(
        (component_status='AVAILABLE' AND component_score IS NOT NULL AND weighted_score IS NOT NULL) OR
        (component_status='NOT_AVAILABLE' AND component_score IS NULL AND weighted_score IS NULL)),
    CONSTRAINT ck_m1_11_component_run_lineage CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_m1_11_component_snapshot FOREIGN KEY(module1_run_id,scenario_id,merchant_application_id)
        REFERENCES msbf_m1.application_operating_resilience_snapshot(module1_run_id,scenario_id,merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_11_component_definition FOREIGN KEY(component_code,component_version)
        REFERENCES msbf_m1.feature_definition(feature_code,feature_version) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_11_component_created_run FOREIGN KEY(created_by_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.operating_resilience_component_value IS
'Long-form M1.11 revenue, liquidity, burden, continuity, and data-confidence resilience component evidence.';
CREATE INDEX IF NOT EXISTS ix_m1_11_component_code
    ON msbf_m1.operating_resilience_component_value(component_code,scenario_id,component_status);
CREATE INDEX IF NOT EXISTS ix_m1_11_component_application
    ON msbf_m1.operating_resilience_component_value(module1_run_id,merchant_application_id,scenario_id);

CREATE OR REPLACE VIEW msbf_m1.v_m1_11_operating_resilience_lineage AS
SELECT r.module1_run_id,r.scenario_id,s.scenario_code,r.merchant_application_id,
       r.population_id,r.merchant_id,r.as_of_date,r.merchant_size_tier,r.industry_code,
       r.relationship_stage,r.cashflow_feature_snapshot_hash,r.liquidity_capacity_snapshot_hash,
       r.independent_archetype_code,r.baseline_archetype_code,r.archetype_code,
       r.operating_resilience_score,r.independent_resilience_tier,r.baseline_resilience_tier,
       r.resilience_tier,r.resilience_status,r.operating_resilience_evidence_status,
       r.manual_review_recommended_flag,r.fallback_path_code,r.primary_resilience_reason_code,
       r.row_hash
FROM msbf_m1.application_operating_resilience_snapshot r
JOIN msbf_ctl.scenario_registry s ON s.scenario_id=r.scenario_id;

INSERT INTO msbf_ctl.policy_profile(
    profile_code,profile_version,business_name,effective_start_date,effective_end_date,
    status,owner_role,approver_role,approval_timestamp,last_review_date,next_review_date,
    change_reason,policy_domain,product_structure_profile_id,operating_model_profile_id,
    parameter_set_id,profile_payload
)
SELECT
    'M1_11_CASHFLOW_ARCHETYPE_RESILIENCE',1,
    'M1.11 Cash-Flow Archetypes and Operating Resilience Policy',
    r.as_of_date,NULL,'APPROVED','Credit Risk','Credit Risk and Model Governance',
    coalesce(p.approval_timestamp,clock_timestamp()),r.as_of_date,r.as_of_date+365,
    'Corrected governed M1.11 archetype and operating-resilience methodology with visible persisted weighted-component composite identity.',
    'CASHFLOW_ARCHETYPE_OPERATING_RESILIENCE',r.product_structure_profile_id,
    r.operating_model_profile_id,r.parameter_set_id,
    '{
      "generation_enabled":true,
      "methodology_version":"M1_11_METHOD_V1_1",
      "composite_score_basis":"SUM_PERSISTED_WEIGHTED_COMPONENTS",
      "stress_resilience_tier_floor_to_baseline":true,
      "stress_archetype_rank_floor_to_baseline":true,
      "component_weight_revenue":0.30,
      "component_weight_liquidity":0.25,
      "component_weight_burden":0.25,
      "component_weight_continuity":0.10,
      "component_weight_data_confidence":0.10,
      "tier_1_score_min":80.0,
      "tier_2_score_min":65.0,
      "tier_3_score_min":50.0,
      "tier_4_score_min":35.0,
      "minimum_history_days":90,
      "disruption_outage_rate":0.03,
      "disruption_active_sales_rate_min":0.60,
      "disruption_zero_sales_rate":0.35,
      "declining_growth_threshold":-0.10,
      "declining_scenario_delta_threshold":-0.10,
      "volatile_cv_threshold":0.70,
      "seasonal_index_threshold":1.30,
      "seasonal_concentration_threshold":0.25,
      "growing_growth_threshold":0.10,
      "growing_active_sales_rate_min":0.70,
      "revenue_growth_floor":-0.30,
      "revenue_cv_neutral":0.30,
      "revenue_cv_max":1.00,
      "revenue_zero_sales_max":0.35,
      "revenue_concentration_neutral":0.20,
      "revenue_concentration_max":0.55,
      "liquidity_buffer_target_days":30.0,
      "liquidity_negative_rate_max":0.25,
      "liquidity_nsf_count_max":5.0,
      "liquidity_cashflow_buffer_target_days":30.0,
      "burden_coverage_target":1.50,
      "burden_rate_max":0.50,
      "burden_stacking_depth_max":4.0,
      "continuity_outage_rate_max":0.10,
      "continuity_degraded_rate_max":0.25,
      "review_tier_threshold":4,
      "review_fraud_tier_threshold":4
    }'::jsonb
FROM msbf_ctl.run_registry r
LEFT JOIN msbf_ctl.policy_profile p
  ON p.profile_code='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE' AND p.profile_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
ON CONFLICT(profile_code,profile_version) DO UPDATE SET
    business_name=EXCLUDED.business_name,effective_start_date=EXCLUDED.effective_start_date,
    effective_end_date=EXCLUDED.effective_end_date,status='APPROVED',owner_role=EXCLUDED.owner_role,
    approver_role=EXCLUDED.approver_role,
    approval_timestamp=coalesce(msbf_ctl.policy_profile.approval_timestamp,EXCLUDED.approval_timestamp),
    last_review_date=EXCLUDED.last_review_date,next_review_date=EXCLUDED.next_review_date,
    change_reason=EXCLUDED.change_reason,policy_domain=EXCLUDED.policy_domain,
    product_structure_profile_id=EXCLUDED.product_structure_profile_id,
    operating_model_profile_id=EXCLUDED.operating_model_profile_id,
    parameter_set_id=EXCLUDED.parameter_set_id,profile_payload=EXCLUDED.profile_payload;

COMMIT;

WITH p AS (
    SELECT policy_profile_id,status,profile_payload,md5(profile_payload::text) AS policy_hash
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE' AND profile_version=1
), f AS (
    SELECT count(*) AS active_features FROM msbf_m1.feature_definition
    WHERE feature_family_code='OPERATING_RESILIENCE' AND feature_version=1 AND active_flag
)
SELECT
    to_regclass('msbf_m1.application_operating_resilience_snapshot') IS NOT NULL AS resilience_table_exists,
    to_regclass('msbf_m1.operating_resilience_component_value') IS NOT NULL AS component_table_exists,
    to_regclass('msbf_m1.v_m1_11_operating_resilience_lineage') IS NOT NULL AS lineage_view_exists,
    (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m1' AND table_name='application_operating_resilience_snapshot') AS resilience_columns,
    (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m1' AND table_name='operating_resilience_component_value') AS component_columns,
    (SELECT active_features FROM f) AS active_resilience_features,
    p.policy_profile_id,p.status AS policy_status,p.policy_hash,
    p.profile_payload->>'methodology_version' AS methodology_version,
    CASE WHEN to_regclass('msbf_m1.application_operating_resilience_snapshot') IS NOT NULL
          AND to_regclass('msbf_m1.operating_resilience_component_value') IS NOT NULL
          AND to_regclass('msbf_m1.v_m1_11_operating_resilience_lineage') IS NOT NULL
          AND (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m1' AND table_name='application_operating_resilience_snapshot')=62
          AND (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m1' AND table_name='operating_resilience_component_value')=14
          AND (SELECT active_features FROM f)=8
          AND p.status='APPROVED'
          AND p.profile_payload->>'methodology_version'='M1_11_METHOD_V1_1'
          AND p.profile_payload->>'composite_score_basis'='SUM_PERSISTED_WEIGHTED_COMPONENTS'
         THEN 'PASS' ELSE 'FAIL' END AS schema_policy_extension_status
FROM p;
