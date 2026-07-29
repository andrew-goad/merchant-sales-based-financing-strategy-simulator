/* ============================================================================
MSBF M1.12 Merchant Risk Components & Integrated Risk Proxy — Schema and Policy Extension
Version : v0.2
Purpose : Register the M1.12 acceptance gate, transparent risk-component
          catalog, integrated-risk feature family, scenario-aware risk proxy
          snapshot, long-form component evidence, lineage view, and approved
          methodology profile.
Boundary: Metadata and schema only. No M1.12 risk evidence is generated, no
          calibrated probability of default is created, and the accepted
          M1.11 run status is not changed.
============================================================================ */

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '5min';

/* ---------------------------------------------------------------------------
1. Acceptance-gate and feature-family registration
--------------------------------------------------------------------------- */
INSERT INTO msbf_ref.acceptance_gate_catalog (
    gate_id,
    gate_name,
    module_code,
    severity,
    description
)
VALUES (
    'M1_12_INTEGRATED_RISK_PROXY',
    'M1.12 Merchant Risk Components and Integrated Risk Proxy',
    'M1',
    'BLOCKING',
    'Transparent scenario-aware risk components, synthetic integrated merchant-risk proxy, stress migration, reason evidence, and controlled routing acceptance.'
)
ON CONFLICT (gate_id) DO UPDATE SET
    gate_name = EXCLUDED.gate_name,
    module_code = EXCLUDED.module_code,
    severity = EXCLUDED.severity,
    active_flag = true,
    description = EXCLUDED.description;

INSERT INTO msbf_ref.feature_family (
    feature_family_code,
    feature_family_name,
    owner_role,
    description
)
VALUES (
    'INTEGRATED_RISK_PROXY',
    'Integrated Merchant Risk Proxy',
    'Credit Risk',
    'Transparent scenario-aware risk components and a synthetic integrated merchant-risk proxy distinct from calibrated probability of default.'
)
ON CONFLICT (feature_family_code) DO UPDATE SET
    feature_family_name = EXCLUDED.feature_family_name,
    owner_role = EXCLUDED.owner_role,
    active_flag = true,
    description = EXCLUDED.description;

/* ---------------------------------------------------------------------------
2. Transparent risk-component catalog
--------------------------------------------------------------------------- */
INSERT INTO msbf_ref.risk_component_code (
    component_code,
    component_name,
    component_domain,
    expected_direction,
    active_flag,
    description
)
VALUES
('OPERATING_RESILIENCE_RISK','Operating Resilience Risk','OPERATING_RESILIENCE','INCREASES_RISK',true,'Accepted M1.11 operating-resilience evidence inverted to a risk-oriented score.'),
('CAPACITY_BURDEN_RISK','Capacity and Burden Risk','CAPACITY_BURDEN','INCREASES_RISK',true,'Accepted M1.11 burden-resilience evidence inverted to a risk-oriented score.'),
('LIQUIDITY_RISK','Liquidity Risk','LIQUIDITY','INCREASES_RISK',true,'Accepted M1.11 liquidity-resilience evidence inverted to a risk-oriented score.'),
('SOURCE_CONFIDENCE_RISK','Source Confidence Risk','DATA_CONFIDENCE','INCREASES_RISK',true,'Risk points from the accepted source-confidence score without treating missing evidence as favorable.'),
('VERIFICATION_FRAUD_RISK','Verification and Fraud Risk','VERIFICATION_FRAUD','INCREASES_RISK',true,'Transparent blend of accepted synthetic fraud score and verification disposition severity.'),
('PROCESSOR_CONTINUITY_RISK','Processor Continuity Risk','PROCESSOR_CONTINUITY','INCREASES_RISK',true,'Accepted processor-continuity resilience evidence inverted to a risk-oriented score.'),
('INDUSTRY_RELATIONSHIP_RISK','Industry and Relationship Context Risk','INDUSTRY_RELATIONSHIP','CONTEXTUAL',true,'Contextual risk points from governed industry risk tier and relationship stage.')
ON CONFLICT (component_code) DO UPDATE SET
    component_name = EXCLUDED.component_name,
    component_domain = EXCLUDED.component_domain,
    expected_direction = EXCLUDED.expected_direction,
    active_flag = true,
    description = EXCLUDED.description;

/* ---------------------------------------------------------------------------
3. Governed feature definitions
--------------------------------------------------------------------------- */
INSERT INTO msbf_m1.feature_definition (
    feature_code,
    feature_version,
    feature_name,
    feature_family_code,
    data_type,
    unit_code,
    observation_window_days,
    formula_description,
    expected_direction,
    valid_min_numeric,
    valid_max_numeric,
    owner_role,
    active_flag,
    production_boundary
)
VALUES
('OPERATING_RESILIENCE_RISK_SCORE',1,'Operating Resilience Risk Score','INTEGRATED_RISK_PROXY','NUMERIC','SCORE',NULL,'Transparent risk-oriented inversion of accepted operating resilience.','HIGHER_RISK',0,100,'Credit Risk',true,'Synthetic integrated risk proxy; not calibrated PD, EAD, LGD, EL, pricing, or a credit decision.'),
('CAPACITY_BURDEN_RISK_SCORE',1,'Capacity and Burden Risk Score','INTEGRATED_RISK_PROXY','NUMERIC','SCORE',NULL,'Transparent risk-oriented inversion of accepted burden resilience.','HIGHER_RISK',0,100,'Credit Risk',true,'Synthetic integrated risk proxy; not calibrated PD, EAD, LGD, EL, pricing, or a credit decision.'),
('LIQUIDITY_RISK_SCORE',1,'Liquidity Risk Score','INTEGRATED_RISK_PROXY','NUMERIC','SCORE',NULL,'Transparent risk-oriented inversion of accepted liquidity resilience.','HIGHER_RISK',0,100,'Credit Risk',true,'Synthetic integrated risk proxy; not calibrated PD, EAD, LGD, EL, pricing, or a credit decision.'),
('SOURCE_CONFIDENCE_RISK_SCORE',1,'Source Confidence Risk Score','INTEGRATED_RISK_PROXY','NUMERIC','SCORE',NULL,'Transparent risk points from accepted source confidence.','HIGHER_RISK',0,100,'Credit Risk',true,'Synthetic integrated risk proxy; not calibrated PD, EAD, LGD, EL, pricing, or a credit decision.'),
('VERIFICATION_FRAUD_RISK_SCORE',1,'Verification and Fraud Risk Score','INTEGRATED_RISK_PROXY','NUMERIC','SCORE',NULL,'Transparent blend of synthetic fraud score and verification disposition.','HIGHER_RISK',0,100,'Credit Risk',true,'Synthetic integrated risk proxy; not calibrated PD, EAD, LGD, EL, pricing, or a credit decision.'),
('PROCESSOR_CONTINUITY_RISK_SCORE',1,'Processor Continuity Risk Score','INTEGRATED_RISK_PROXY','NUMERIC','SCORE',NULL,'Transparent risk-oriented inversion of processor continuity resilience.','HIGHER_RISK',0,100,'Credit Risk',true,'Synthetic integrated risk proxy; not calibrated PD, EAD, LGD, EL, pricing, or a credit decision.'),
('INDUSTRY_RELATIONSHIP_RISK_SCORE',1,'Industry and Relationship Context Risk Score','INTEGRATED_RISK_PROXY','NUMERIC','SCORE',NULL,'Contextual points from industry risk tier and relationship stage.','HIGHER_RISK',0,100,'Credit Risk',true,'Synthetic integrated risk proxy; not calibrated PD, EAD, LGD, EL, pricing, or a credit decision.'),
('INTEGRATED_MERCHANT_RISK_SCORE',1,'Integrated Merchant Risk Score','INTEGRATED_RISK_PROXY','NUMERIC','SCORE',NULL,'Sum of seven persisted weighted risk-component values.','HIGHER_RISK',0,100,'Credit Risk',true,'Synthetic integrated risk proxy; not calibrated PD, EAD, LGD, EL, pricing, or a credit decision.'),
('SYNTHETIC_MERCHANT_RISK_PROXY',1,'Synthetic Merchant Risk Proxy','INTEGRATED_RISK_PROXY','NUMERIC','RATE',NULL,'Integrated risk score divided by 100; not a calibrated probability of default.','HIGHER_RISK',0,1,'Credit Risk',true,'Synthetic integrated risk proxy; not calibrated PD, EAD, LGD, EL, pricing, or a credit decision.'),
('INTEGRATED_MERCHANT_RISK_TIER',1,'Integrated Merchant Risk Tier','INTEGRATED_RISK_PROXY','NUMERIC','TIER',NULL,'Governed ordinal integrated risk tier from one through five.','HIGHER_RISK',1,5,'Credit Risk',true,'Synthetic integrated risk proxy; not calibrated PD, EAD, LGD, EL, pricing, or a credit decision.')
ON CONFLICT (feature_code, feature_version) DO UPDATE SET
    feature_name = EXCLUDED.feature_name,
    feature_family_code = EXCLUDED.feature_family_code,
    data_type = EXCLUDED.data_type,
    unit_code = EXCLUDED.unit_code,
    observation_window_days = EXCLUDED.observation_window_days,
    formula_description = EXCLUDED.formula_description,
    expected_direction = EXCLUDED.expected_direction,
    valid_min_numeric = EXCLUDED.valid_min_numeric,
    valid_max_numeric = EXCLUDED.valid_max_numeric,
    owner_role = EXCLUDED.owner_role,
    active_flag = true,
    production_boundary = EXCLUDED.production_boundary;

/* ---------------------------------------------------------------------------
4. Scenario-aware integrated-risk snapshot
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_m1.application_integrated_risk_proxy_snapshot (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    merchant_size_tier text NOT NULL,
    industry_code text NOT NULL,
    relationship_stage text NOT NULL,
    operating_resilience_snapshot_hash text NOT NULL,
    liquidity_capacity_snapshot_hash text NOT NULL,
    verification_fraud_snapshot_hash text NOT NULL,
    operating_resilience_evidence_status text NOT NULL,
    capacity_evidence_status text NOT NULL,
    data_confidence_tier text NOT NULL,
    verification_disposition text NOT NULL,
    fraud_risk_tier smallint NOT NULL,
    processor_continuity_risk_tier smallint NOT NULL,
    operating_resilience_tier smallint NOT NULL,
    capacity_tier smallint NOT NULL,
    archetype_code text NOT NULL,
    archetype_risk_rank smallint NOT NULL,
    operating_resilience_risk_score numeric(9,6),
    capacity_burden_risk_score numeric(9,6),
    liquidity_risk_score numeric(9,6),
    source_confidence_risk_score numeric(9,6),
    verification_fraud_risk_score numeric(9,6),
    processor_continuity_risk_score numeric(9,6),
    industry_relationship_risk_score numeric(9,6),
    independent_integrated_risk_score numeric(9,6),
    baseline_integrated_risk_score numeric(9,6),
    integrated_risk_score numeric(9,6),
    synthetic_merchant_risk_proxy numeric(12,8),
    independent_risk_tier smallint NOT NULL,
    baseline_risk_tier smallint NOT NULL,
    integrated_risk_tier smallint NOT NULL,
    stress_risk_worsening_flag boolean NOT NULL,
    integrated_risk_status text NOT NULL,
    integrated_risk_evidence_status text NOT NULL,
    risk_floor_applied_flag boolean NOT NULL,
    hard_stop_recommended_flag boolean NOT NULL,
    manual_review_recommended_flag boolean NOT NULL,
    fallback_path_code text NOT NULL,
    primary_risk_reason_code text NOT NULL,
    secondary_risk_reason_codes text[] DEFAULT '{}'::text[] NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_m1_12_integrated_risk
        PRIMARY KEY (module1_run_id, scenario_id, merchant_application_id),
    CONSTRAINT ck_m1_12_component_scores CHECK (
        (operating_resilience_risk_score IS NULL OR operating_resilience_risk_score BETWEEN 0 AND 100)
        AND (capacity_burden_risk_score IS NULL OR capacity_burden_risk_score BETWEEN 0 AND 100)
        AND (liquidity_risk_score IS NULL OR liquidity_risk_score BETWEEN 0 AND 100)
        AND (source_confidence_risk_score IS NULL OR source_confidence_risk_score BETWEEN 0 AND 100)
        AND (verification_fraud_risk_score IS NULL OR verification_fraud_risk_score BETWEEN 0 AND 100)
        AND (processor_continuity_risk_score IS NULL OR processor_continuity_risk_score BETWEEN 0 AND 100)
        AND (industry_relationship_risk_score IS NULL OR industry_relationship_risk_score BETWEEN 0 AND 100)
    ),
    CONSTRAINT ck_m1_12_composite_scores CHECK (
        (independent_integrated_risk_score IS NULL OR independent_integrated_risk_score BETWEEN 0 AND 100)
        AND (baseline_integrated_risk_score IS NULL OR baseline_integrated_risk_score BETWEEN 0 AND 100)
        AND (integrated_risk_score IS NULL OR integrated_risk_score BETWEEN 0 AND 100)
        AND (synthetic_merchant_risk_proxy IS NULL OR synthetic_merchant_risk_proxy BETWEEN 0 AND 1)
    ),
    CONSTRAINT ck_m1_12_tiers CHECK (
        fraud_risk_tier BETWEEN 1 AND 5
        AND processor_continuity_risk_tier BETWEEN 1 AND 5
        AND operating_resilience_tier BETWEEN 1 AND 5
        AND capacity_tier BETWEEN 1 AND 5
        AND archetype_risk_rank BETWEEN 1 AND 5
        AND independent_risk_tier BETWEEN 1 AND 5
        AND baseline_risk_tier BETWEEN 1 AND 5
        AND integrated_risk_tier BETWEEN 1 AND 5
    ),
    CONSTRAINT ck_m1_12_status CHECK (
        integrated_risk_status IN (
            'LOW_RISK', 'MODERATE_RISK', 'ELEVATED_RISK',
            'HIGH_RISK', 'SEVERE_RISK', 'INSUFFICIENT_EVIDENCE'
        )
    ),
    CONSTRAINT ck_m1_12_evidence_status CHECK (
        integrated_risk_evidence_status IN ('COMPLETE', 'PARTIAL', 'BLOCKED')
    ),
    CONSTRAINT ck_m1_12_fallback CHECK (
        fallback_path_code IN (
            'NONE', 'DATA_REFRESH', 'VERIFICATION_REVIEW', 'VERIFICATION_STOP',
            'FRAUD_REVIEW', 'PROCESSOR_CONTINUITY_REVIEW', 'CAPACITY_REVIEW',
            'SOURCE_CONFLICT_REVIEW', 'INSUFFICIENT_EVIDENCE', 'MANUAL_RISK_REVIEW'
        )
    ),
    CONSTRAINT ck_m1_12_blocked_proxy CHECK (
        integrated_risk_evidence_status <> 'BLOCKED'
        OR (integrated_risk_score IS NULL AND synthetic_merchant_risk_proxy IS NULL)
    ),
    CONSTRAINT ck_m1_12_proxy_identity CHECK (
        integrated_risk_score IS NULL
        OR abs(synthetic_merchant_risk_proxy - integrated_risk_score / 100.0) <= 0.00000001
    ),
    CONSTRAINT ck_m1_12_run_lineage CHECK (created_by_run_id = module1_run_id),
    CONSTRAINT fk_m1_12_run FOREIGN KEY (module1_run_id)
        REFERENCES msbf_ctl.run_registry (run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_12_scenario FOREIGN KEY (scenario_id)
        REFERENCES msbf_ctl.scenario_registry (scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_12_application FOREIGN KEY (merchant_application_id)
        REFERENCES msbf_m1.merchant_application (merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_12_population FOREIGN KEY (population_id)
        REFERENCES msbf_m1.population_registry (population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_12_merchant FOREIGN KEY (merchant_id)
        REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_12_resilience FOREIGN KEY (
        module1_run_id, scenario_id, merchant_application_id
    ) REFERENCES msbf_m1.application_operating_resilience_snapshot (
        module1_run_id, scenario_id, merchant_application_id
    ) ON DELETE CASCADE,
    CONSTRAINT fk_m1_12_capacity FOREIGN KEY (
        module1_run_id, scenario_id, merchant_application_id
    ) REFERENCES msbf_m1.application_liquidity_capacity_snapshot (
        module1_run_id, scenario_id, merchant_application_id
    ) ON DELETE CASCADE,
    CONSTRAINT fk_m1_12_verification FOREIGN KEY (
        module1_run_id, merchant_application_id
    ) REFERENCES msbf_m1.application_verification_fraud_snapshot (
        module1_run_id, merchant_application_id
    ) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_12_created_run FOREIGN KEY (created_by_run_id)
        REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
);

COMMENT ON TABLE msbf_m1.application_integrated_risk_proxy_snapshot IS
'Scenario-aware M1.12 transparent risk components, synthetic integrated merchant-risk proxy, stress migration, evidence status, and controlled routing. This is not a calibrated probability of default.';

CREATE INDEX IF NOT EXISTS ix_m1_12_risk_status
    ON msbf_m1.application_integrated_risk_proxy_snapshot (
        module1_run_id, scenario_id, integrated_risk_tier, integrated_risk_status
    );

CREATE INDEX IF NOT EXISTS ix_m1_12_risk_review
    ON msbf_m1.application_integrated_risk_proxy_snapshot (
        module1_run_id, manual_review_recommended_flag, hard_stop_recommended_flag
    );

CREATE INDEX IF NOT EXISTS ix_m1_12_risk_merchant
    ON msbf_m1.application_integrated_risk_proxy_snapshot (
        merchant_id, scenario_id, as_of_date
    );

/* ---------------------------------------------------------------------------
5. Long-form integrated-risk component evidence
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_m1.integrated_risk_component_value (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    component_code text NOT NULL,
    component_version smallint DEFAULT 1 NOT NULL,
    component_source_value numeric(24,10),
    component_risk_score numeric(9,6),
    component_weight numeric(9,6) NOT NULL,
    weighted_risk_points numeric(9,6),
    component_zone text NOT NULL,
    component_status text NOT NULL,
    directional_status text NOT NULL,
    component_reason_code text NOT NULL,
    source_lineage_hash text NOT NULL,
    calculation_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_m1_12_component PRIMARY KEY (
        module1_run_id,
        scenario_id,
        merchant_application_id,
        component_code,
        component_version
    ),
    CONSTRAINT ck_m1_12_component_score CHECK (
        component_risk_score IS NULL OR component_risk_score BETWEEN 0 AND 100
    ),
    CONSTRAINT ck_m1_12_component_weight CHECK (component_weight BETWEEN 0 AND 1),
    CONSTRAINT ck_m1_12_weighted_points CHECK (
        weighted_risk_points IS NULL OR weighted_risk_points BETWEEN 0 AND 100
    ),
    CONSTRAINT ck_m1_12_component_zone CHECK (
        component_zone IN ('LOW', 'MODERATE', 'ELEVATED', 'HIGH', 'UNAVAILABLE')
    ),
    CONSTRAINT ck_m1_12_component_status CHECK (
        component_status IN ('AVAILABLE', 'UNAVAILABLE')
    ),
    CONSTRAINT ck_m1_12_directional_status CHECK (
        directional_status IN ('FAVORABLE', 'NEUTRAL', 'ADVERSE', 'UNAVAILABLE')
    ),
    CONSTRAINT ck_m1_12_component_availability CHECK (
        (component_status = 'UNAVAILABLE'
            AND component_risk_score IS NULL
            AND weighted_risk_points IS NULL
            AND component_zone = 'UNAVAILABLE'
            AND directional_status = 'UNAVAILABLE')
        OR
        (component_status = 'AVAILABLE'
            AND component_risk_score IS NOT NULL
            AND weighted_risk_points IS NOT NULL
            AND component_zone <> 'UNAVAILABLE'
            AND directional_status <> 'UNAVAILABLE')
    ),
    CONSTRAINT ck_m1_12_component_run_lineage CHECK (created_by_run_id = module1_run_id),
    CONSTRAINT fk_m1_12_component_snapshot FOREIGN KEY (
        module1_run_id, scenario_id, merchant_application_id
    ) REFERENCES msbf_m1.application_integrated_risk_proxy_snapshot (
        module1_run_id, scenario_id, merchant_application_id
    ) ON DELETE CASCADE,
    CONSTRAINT fk_m1_12_component_code FOREIGN KEY (component_code)
        REFERENCES msbf_ref.risk_component_code (component_code) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_12_component_created_run FOREIGN KEY (created_by_run_id)
        REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
);

COMMENT ON TABLE msbf_m1.integrated_risk_component_value IS
'Long-form M1.12 component source values, transparent risk scores, weights, weighted points, zones, reasons, lineage, and deterministic hashes.';

CREATE INDEX IF NOT EXISTS ix_m1_12_component_code
    ON msbf_m1.integrated_risk_component_value (
        module1_run_id, scenario_id, component_code, component_zone
    );

CREATE INDEX IF NOT EXISTS ix_m1_12_component_application
    ON msbf_m1.integrated_risk_component_value (
        merchant_application_id, scenario_id
    );

/* ---------------------------------------------------------------------------
6. Governed lineage view
--------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW msbf_m1.v_m1_12_integrated_risk_lineage AS
SELECT
    r.module1_run_id,
    r.scenario_id,
    s.scenario_code,
    r.merchant_application_id,
    r.population_id,
    r.merchant_id,
    r.as_of_date,
    r.industry_code,
    r.relationship_stage,
    r.operating_resilience_snapshot_hash,
    r.liquidity_capacity_snapshot_hash,
    r.verification_fraud_snapshot_hash,
    r.operating_resilience_risk_score,
    r.capacity_burden_risk_score,
    r.liquidity_risk_score,
    r.source_confidence_risk_score,
    r.verification_fraud_risk_score,
    r.processor_continuity_risk_score,
    r.industry_relationship_risk_score,
    r.integrated_risk_score,
    r.synthetic_merchant_risk_proxy,
    r.integrated_risk_tier,
    r.integrated_risk_status,
    r.integrated_risk_evidence_status,
    r.hard_stop_recommended_flag,
    r.manual_review_recommended_flag,
    r.fallback_path_code,
    r.primary_risk_reason_code,
    r.row_hash
FROM msbf_m1.application_integrated_risk_proxy_snapshot r
JOIN msbf_ctl.scenario_registry s
  ON s.scenario_id = r.scenario_id;

/* ---------------------------------------------------------------------------
7. Approved M1.12 methodology profile
--------------------------------------------------------------------------- */
INSERT INTO msbf_ctl.policy_profile (
    profile_code,
    profile_version,
    business_name,
    effective_start_date,
    effective_end_date,
    status,
    owner_role,
    approver_role,
    approval_timestamp,
    last_review_date,
    next_review_date,
    change_reason,
    policy_domain,
    product_structure_profile_id,
    operating_model_profile_id,
    parameter_set_id,
    profile_payload
)
SELECT
    'M1_12_INTEGRATED_RISK_PROXY',
    1,
    'M1.12 Merchant Risk Components and Integrated Risk Proxy Policy',
    r.as_of_date,
    NULL,
    'APPROVED',
    'Credit Risk',
    'Credit Risk and Model Governance',
    coalesce(p.approval_timestamp, clock_timestamp()),
    r.as_of_date,
    r.as_of_date + 365,
    'Initial governed M1.12 transparent risk-component and synthetic integrated-risk methodology.',
    'MERCHANT_RISK_COMPONENTS_INTEGRATED_PROXY',
    r.product_structure_profile_id,
    r.operating_model_profile_id,
    r.parameter_set_id,
    '{"generation_enabled":true,"methodology_version":"M1_12_METHOD_V1","composite_score_basis":"SUM_PERSISTED_WEIGHTED_RISK_COMPONENTS","stress_risk_score_floor_to_baseline":true,"stress_risk_tier_floor_to_baseline":true,"component_weight_operating_resilience":0.25,"component_weight_capacity_burden":0.2,"component_weight_liquidity":0.15,"component_weight_source_confidence":0.1,"component_weight_verification_fraud":0.15,"component_weight_processor_continuity":0.05,"component_weight_industry_relationship":0.1,"risk_tier_1_max":20.0,"risk_tier_2_max":40.0,"risk_tier_3_max":60.0,"risk_tier_4_max":80.0,"hard_stop_score_floor":90.0,"fraud_tier_5_score_floor":80.0,"verification_fraud_weight_fraud_score":0.7,"verification_fraud_weight_disposition":0.3,"verification_clear_points":0.0,"verification_review_points":40.0,"verification_stop_points":100.0,"verification_insufficient_points":70.0,"relationship_new_points":45.0,"relationship_returning_good_points":10.0,"relationship_returning_mixed_points":75.0,"relationship_low_and_grow_points":50.0,"component_zone_low_max":25.0,"component_zone_moderate_max":50.0,"component_zone_elevated_max":75.0,"manual_review_tier_min":4,"source_confidence_partial_threshold":0.9}'::jsonb
FROM msbf_ctl.run_registry r
LEFT JOIN msbf_ctl.policy_profile p
  ON p.profile_code = 'M1_11_CASHFLOW_ARCHETYPE_RESILIENCE'
 AND p.profile_version = 1
WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND r.run_version = 1
ON CONFLICT (profile_code, profile_version) DO UPDATE SET
    business_name = EXCLUDED.business_name,
    effective_start_date = EXCLUDED.effective_start_date,
    effective_end_date = EXCLUDED.effective_end_date,
    status = 'APPROVED',
    owner_role = EXCLUDED.owner_role,
    approver_role = EXCLUDED.approver_role,
    approval_timestamp = EXCLUDED.approval_timestamp,
    last_review_date = EXCLUDED.last_review_date,
    next_review_date = EXCLUDED.next_review_date,
    change_reason = EXCLUDED.change_reason,
    policy_domain = EXCLUDED.policy_domain,
    product_structure_profile_id = EXCLUDED.product_structure_profile_id,
    operating_model_profile_id = EXCLUDED.operating_model_profile_id,
    parameter_set_id = EXCLUDED.parameter_set_id,
    profile_payload = EXCLUDED.profile_payload;

COMMIT;

/* ---------------------------------------------------------------------------
8. Extension checkpoint
--------------------------------------------------------------------------- */
SELECT
    to_regclass('msbf_m1.application_integrated_risk_proxy_snapshot') IS NOT NULL
        AS risk_snapshot_table_exists,
    to_regclass('msbf_m1.integrated_risk_component_value') IS NOT NULL
        AS component_table_exists,
    to_regclass('msbf_m1.v_m1_12_integrated_risk_lineage') IS NOT NULL
        AS lineage_view_exists,
    (
        SELECT count(*)
        FROM msbf_ref.risk_component_code
        WHERE component_code IN (
            'OPERATING_RESILIENCE_RISK',
            'CAPACITY_BURDEN_RISK',
            'LIQUIDITY_RISK',
            'SOURCE_CONFIDENCE_RISK',
            'VERIFICATION_FRAUD_RISK',
            'PROCESSOR_CONTINUITY_RISK',
            'INDUSTRY_RELATIONSHIP_RISK'
        )
          AND active_flag
    ) AS active_component_codes,
    (
        SELECT profile_payload ->> 'methodology_version'
        FROM msbf_ctl.policy_profile
        WHERE profile_code = 'M1_12_INTEGRATED_RISK_PROXY'
          AND profile_version = 1
          AND status = 'APPROVED'
    ) AS methodology_version,
    CASE
        WHEN to_regclass('msbf_m1.application_integrated_risk_proxy_snapshot') IS NOT NULL
         AND to_regclass('msbf_m1.integrated_risk_component_value') IS NOT NULL
         AND to_regclass('msbf_m1.v_m1_12_integrated_risk_lineage') IS NOT NULL
         AND (
             SELECT count(*)
             FROM msbf_ref.risk_component_code
             WHERE component_code LIKE '%_RISK'
               AND component_code IN (
                   'OPERATING_RESILIENCE_RISK',
                   'CAPACITY_BURDEN_RISK',
                   'LIQUIDITY_RISK',
                   'SOURCE_CONFIDENCE_RISK',
                   'VERIFICATION_FRAUD_RISK',
                   'PROCESSOR_CONTINUITY_RISK',
                   'INDUSTRY_RELATIONSHIP_RISK'
               )
               AND active_flag
         ) = 7
         AND (
             SELECT profile_payload ->> 'methodology_version'
             FROM msbf_ctl.policy_profile
             WHERE profile_code = 'M1_12_INTEGRATED_RISK_PROXY'
               AND profile_version = 1
               AND status = 'APPROVED'
         ) = 'M1_12_METHOD_V1'
        THEN 'PASS'
        ELSE 'FAIL'
    END AS schema_policy_extension_status;
