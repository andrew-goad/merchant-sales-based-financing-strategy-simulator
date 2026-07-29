/* ============================================================================
MSBF M1.13 Exposure, Recovery & Expected Loss Foundations — Schema and Policy Extension
Version : v0.2
Purpose : Register the M1.13 acceptance gate, feature family, feature catalog,
          scenario-aware exposure/recovery/loss snapshot, daily EAD path,
          lineage view, and approved methodology profile.
Inputs  : Accepted G0–M1.12 database state.
Outputs : Metadata and schema only. No M1.13 business evidence is generated.
Boundary: Comparative synthetic loss foundations only. This program does not
          create calibrated PD, CECL/reserve estimates, pricing, or decisions.
Safety  : Idempotent DDL and metadata upserts inside one transaction.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '5min';

/* ---------------------------------------------------------------------------
1. Acceptance gate and feature-family registration
--------------------------------------------------------------------------- */
INSERT INTO msbf_ref.acceptance_gate_catalog (
    gate_id, gate_name, module_code, severity, description
)
VALUES (
    'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS',
    'M1.13 Exposure, Recovery and Expected Loss Foundations',
    'M1',
    'BLOCKING',
    'Scenario-aware daily EAD path, recovery/LGD foundation, and comparative expected-loss evidence acceptance.'
)
ON CONFLICT (gate_id) DO UPDATE SET
    gate_name = EXCLUDED.gate_name,
    module_code = EXCLUDED.module_code,
    severity = EXCLUDED.severity,
    active_flag = true,
    description = EXCLUDED.description;

INSERT INTO msbf_ref.feature_family (
    feature_family_code, feature_family_name, owner_role, description
)
VALUES (
    'EXPOSURE_RECOVERY_LOSS',
    'Exposure, Recovery and Comparative Loss Foundations',
    'Credit Risk / Finance',
    'Scenario-aware exposure path, recovery/LGD assumptions, and comparative expected-loss foundations distinct from CECL, reserve, capital, pricing, or final decisioning.'
)
ON CONFLICT (feature_family_code) DO UPDATE SET
    feature_family_name = EXCLUDED.feature_family_name,
    owner_role = EXCLUDED.owner_role,
    active_flag = true,
    description = EXCLUDED.description;

/* ---------------------------------------------------------------------------
2. Governed feature definitions
--------------------------------------------------------------------------- */
INSERT INTO msbf_m1.feature_definition (
    feature_code, feature_version, feature_name, feature_family_code,
    data_type, unit_code, observation_window_days, formula_description,
    expected_direction, valid_min_numeric, valid_max_numeric, owner_role,
    active_flag, production_boundary
)
VALUES
    ('INITIAL_RECEIVABLE_EXPOSURE_AMOUNT',1,'Initial Receivable Exposure Amount','EXPOSURE_RECOVERY_LOSS','NUMERIC','CURRENCY',NULL,'Requested total repayment amount used as the initial contractual-receivable exposure basis.','HIGHER_EXPOSURE',0,NULL,'Credit Risk / Finance',true,'Synthetic comparative exposure foundation; not accounting receivable, CECL, reserve, capital, or production EAD.'),
    ('PATH_WEIGHTED_EAD_AMOUNT',1,'Path-Weighted Exposure at Default','EXPOSURE_RECOVERY_LOSS','NUMERIC','CURRENCY',NULL,'Default-timing-weighted expected outstanding receivable across the governed daily exposure path.','HIGHER_EXPOSURE',0,NULL,'Credit Risk / Finance',true,'Synthetic comparative exposure foundation; not accounting receivable, CECL, reserve, capital, or production EAD.'),
    ('EXPECTED_EAD_RATE',1,'Expected EAD Rate','EXPOSURE_RECOVERY_LOSS','NUMERIC','RATE',NULL,'Path-weighted EAD divided by initial receivable exposure.','HIGHER_EXPOSURE',0,1,'Credit Risk / Finance',true,'Synthetic comparative exposure foundation; not calibrated EAD.'),
    ('INDUSTRY_LGD_BASELINE_RATE',1,'Industry LGD Baseline','EXPOSURE_RECOVERY_LOSS','NUMERIC','RATE',NULL,'Frozen industry-level loss-severity foundation.','HIGHER_LOSS',0,1,'Credit Risk / Finance',true,'Synthetic comparative recovery foundation; not production LGD.'),
    ('RECOVERY_RATE_ASSUMPTION',1,'Recovery Rate Assumption','EXPOSURE_RECOVERY_LOSS','NUMERIC','RATE',NULL,'One minus the governed LGD input rate.','HIGHER_RECOVERY',0,1,'Credit Risk / Finance',true,'Synthetic comparative recovery foundation; not a recovery forecast.'),
    ('LGD_INPUT_RATE',1,'LGD Input Rate','EXPOSURE_RECOVERY_LOSS','NUMERIC','RATE',NULL,'Industry baseline plus stress severity less supported recovery credits, bounded by governed floor and cap.','HIGHER_LOSS',0,1,'Credit Risk / Finance',true,'Synthetic comparative LGD input; not production LGD.'),
    ('SIMPLE_COMPARATIVE_EXPECTED_LOSS_AMOUNT',1,'Simple Comparative Expected Loss','EXPOSURE_RECOVERY_LOSS','NUMERIC','CURRENCY',NULL,'Synthetic risk proxy multiplied by LGD and initial receivable exposure.','HIGHER_LOSS',0,NULL,'Credit Risk / Finance',true,'Comparative synthetic loss measure; not CECL, reserve, capital, or forecast.'),
    ('SCHEDULE_ADJUSTED_COMPARATIVE_EXPECTED_LOSS_AMOUNT',1,'Schedule-Adjusted Comparative Expected Loss','EXPOSURE_RECOVERY_LOSS','NUMERIC','CURRENCY',NULL,'Synthetic risk proxy multiplied by LGD and path-weighted EAD.','HIGHER_LOSS',0,NULL,'Credit Risk / Finance',true,'Comparative synthetic loss measure; not CECL, reserve, capital, or forecast.'),
    ('SCHEDULE_ADJUSTED_COMPARATIVE_LOSS_RATE',1,'Schedule-Adjusted Comparative Loss Rate','EXPOSURE_RECOVERY_LOSS','NUMERIC','RATE',NULL,'Schedule-adjusted comparative loss divided by initial receivable exposure.','HIGHER_LOSS',0,1,'Credit Risk / Finance',true,'Comparative synthetic loss measure; not CECL, reserve, capital, or forecast.'),
    ('RECOVERY_EVIDENCE_STATUS',1,'Recovery Evidence Status','EXPOSURE_RECOVERY_LOSS','TEXT','STATUS',NULL,'Supported, parameter-only, or conflict state for recovery inputs.','CONTEXTUAL',NULL,NULL,'Credit Risk / Finance',true,'Evidence-state indicator; not a recovery outcome.')
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
3. Scenario-aware daily exposure path
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_m1.application_ead_path_value (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    path_day smallint NOT NULL,
    path_bucket text NOT NULL,
    path_bucket_day_count smallint NOT NULL,
    paydown_curve_shape numeric(12,8) NOT NULL,
    beginning_exposure_amount numeric(18,2) NOT NULL,
    scheduled_remittance_amount numeric(18,2) NOT NULL,
    expected_receivable_reduction_amount numeric(18,2) NOT NULL,
    ending_exposure_amount numeric(18,2) NOT NULL,
    default_timing_weight numeric(14,10) NOT NULL,
    weighted_ead_amount numeric(18,2) NOT NULL,
    exposure_basis_code text NOT NULL,
    payment_basis_code text NOT NULL,
    path_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_m1_13_ead_path PRIMARY KEY (
        module1_run_id, scenario_id, merchant_application_id, path_day
    ),
    CONSTRAINT ck_m1_13_path_day CHECK (path_day BETWEEN 0 AND 90),
    CONSTRAINT ck_m1_13_path_bucket CHECK (path_bucket IN ('EARLY','MIDDLE','LATE')),
    CONSTRAINT ck_m1_13_path_counts CHECK (path_bucket_day_count > 0),
    CONSTRAINT ck_m1_13_path_shape CHECK (paydown_curve_shape > 0),
    CONSTRAINT ck_m1_13_path_amounts CHECK (
        beginning_exposure_amount >= 0
        AND scheduled_remittance_amount >= 0
        AND expected_receivable_reduction_amount >= 0
        AND ending_exposure_amount >= 0
        AND weighted_ead_amount >= 0
    ),
    CONSTRAINT ck_m1_13_path_weight CHECK (default_timing_weight BETWEEN 0 AND 1),
    CONSTRAINT ck_m1_13_path_basis CHECK (
        exposure_basis_code = 'CONTRACTUAL_RECEIVABLE'
        AND payment_basis_code = 'MIN_SCENARIO_BASELINE_DAILY_REMITTANCE'
    ),
    CONSTRAINT ck_m1_13_path_lineage CHECK (created_by_run_id = module1_run_id),
    CONSTRAINT fk_m1_13_path_run FOREIGN KEY (module1_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_13_path_scenario FOREIGN KEY (scenario_id)
        REFERENCES msbf_ctl.scenario_registry(scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_13_path_application FOREIGN KEY (merchant_application_id)
        REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_13_path_risk FOREIGN KEY (
        module1_run_id, scenario_id, merchant_application_id
    ) REFERENCES msbf_m1.application_integrated_risk_proxy_snapshot (
        module1_run_id, scenario_id, merchant_application_id
    ) ON DELETE CASCADE
);

COMMENT ON TABLE msbf_m1.application_ead_path_value IS
'Scenario-aware daily contractual-receivable exposure path and default-timing-weight evidence for M1.13 comparative EAD foundations.';

CREATE INDEX IF NOT EXISTS ix_m1_13_path_application
    ON msbf_m1.application_ead_path_value (
        module1_run_id, merchant_application_id, scenario_id, path_day
    );

CREATE INDEX IF NOT EXISTS ix_m1_13_path_bucket
    ON msbf_m1.application_ead_path_value (
        module1_run_id, scenario_id, path_bucket
    );

/* ---------------------------------------------------------------------------
4. Exposure, recovery, and comparative loss snapshot
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_m1.application_exposure_recovery_loss_snapshot (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    industry_code text NOT NULL,
    integrated_risk_snapshot_hash text NOT NULL,
    liquidity_capacity_snapshot_hash text NOT NULL,
    application_request_hash text NOT NULL,
    integrated_risk_evidence_status text NOT NULL,
    recovery_evidence_status text NOT NULL,
    loss_evidence_status text NOT NULL,
    synthetic_merchant_risk_proxy numeric(12,8),
    integrated_risk_tier smallint NOT NULL,
    requested_funding_amount numeric(18,2) NOT NULL,
    requested_total_repayment_amount numeric(18,2) NOT NULL,
    requested_finance_charge_amount numeric(18,2) NOT NULL,
    requested_expected_payoff_days smallint NOT NULL,
    scenario_expected_daily_remittance numeric(18,2) NOT NULL,
    baseline_expected_daily_remittance numeric(18,2) NOT NULL,
    governed_path_daily_payment numeric(18,2) NOT NULL,
    paydown_curve_shape numeric(12,8) NOT NULL,
    initial_receivable_exposure_amount numeric(18,2) NOT NULL,
    path_weighted_ead_amount numeric(18,2) NOT NULL,
    expected_ead_rate numeric(12,8) NOT NULL,
    industry_lgd_baseline_rate numeric(12,8) NOT NULL,
    scenario_lgd_addon_rate numeric(12,8) NOT NULL,
    collateral_available_value numeric(18,2) NOT NULL,
    guarantee_capacity_amount numeric(18,2) NOT NULL,
    collateral_recovery_credit_rate numeric(12,8) NOT NULL,
    guarantee_recovery_credit_rate numeric(12,8) NOT NULL,
    total_recovery_credit_rate numeric(12,8) NOT NULL,
    recovery_basis_code text NOT NULL,
    recovery_rate_assumption numeric(12,8) NOT NULL,
    lgd_input_rate numeric(12,8) NOT NULL,
    simple_comparative_expected_loss_amount numeric(18,2),
    schedule_adjusted_comparative_expected_loss_amount numeric(18,2),
    simple_comparative_loss_rate numeric(12,8),
    schedule_adjusted_comparative_loss_rate numeric(12,8),
    stress_ead_worsening_flag boolean NOT NULL,
    stress_lgd_worsening_flag boolean NOT NULL,
    stress_loss_worsening_flag boolean NOT NULL,
    hard_stop_recommended_flag boolean NOT NULL,
    manual_review_recommended_flag boolean NOT NULL,
    fallback_path_code text NOT NULL,
    primary_loss_reason_code text NOT NULL,
    secondary_loss_reason_codes text[] DEFAULT '{}'::text[] NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_m1_13_loss_snapshot PRIMARY KEY (
        module1_run_id, scenario_id, merchant_application_id
    ),
    CONSTRAINT ck_m1_13_loss_risk_tier CHECK (integrated_risk_tier BETWEEN 1 AND 5),
    CONSTRAINT ck_m1_13_loss_payoff CHECK (requested_expected_payoff_days IN (30,60,90)),
    CONSTRAINT ck_m1_13_loss_amounts CHECK (
        requested_funding_amount > 0
        AND requested_total_repayment_amount >= requested_funding_amount
        AND requested_finance_charge_amount >= 0
        AND scenario_expected_daily_remittance >= 0
        AND baseline_expected_daily_remittance >= 0
        AND governed_path_daily_payment >= 0
        AND initial_receivable_exposure_amount > 0
        AND path_weighted_ead_amount >= 0
        AND collateral_available_value >= 0
        AND guarantee_capacity_amount >= 0
        AND (simple_comparative_expected_loss_amount IS NULL OR simple_comparative_expected_loss_amount >= 0)
        AND (schedule_adjusted_comparative_expected_loss_amount IS NULL OR schedule_adjusted_comparative_expected_loss_amount >= 0)
    ),
    CONSTRAINT ck_m1_13_loss_rates CHECK (
        expected_ead_rate BETWEEN 0 AND 1
        AND industry_lgd_baseline_rate BETWEEN 0 AND 1
        AND scenario_lgd_addon_rate BETWEEN 0 AND 1
        AND collateral_recovery_credit_rate BETWEEN 0 AND 1
        AND guarantee_recovery_credit_rate BETWEEN 0 AND 1
        AND total_recovery_credit_rate BETWEEN 0 AND 1
        AND recovery_rate_assumption BETWEEN 0 AND 1
        AND lgd_input_rate BETWEEN 0 AND 1
        AND (synthetic_merchant_risk_proxy IS NULL OR synthetic_merchant_risk_proxy BETWEEN 0 AND 1)
        AND (simple_comparative_loss_rate IS NULL OR simple_comparative_loss_rate BETWEEN 0 AND 1)
        AND (schedule_adjusted_comparative_loss_rate IS NULL OR schedule_adjusted_comparative_loss_rate BETWEEN 0 AND 1)
    ),
    CONSTRAINT ck_m1_13_recovery_status CHECK (
        recovery_evidence_status IN ('SUPPORTED','PARAMETER_ONLY','CONFLICT')
    ),
    CONSTRAINT ck_m1_13_loss_status CHECK (
        loss_evidence_status IN ('COMPLETE','PARTIAL','BLOCKED')
    ),
    CONSTRAINT ck_m1_13_recovery_basis CHECK (
        recovery_basis_code IN (
            'INDUSTRY_PARAMETER_ONLY',
            'COLLATERAL_SUPPORTED',
            'GUARANTEE_SUPPORTED',
            'COLLATERAL_AND_GUARANTEE_SUPPORTED',
            'SOURCE_CONFLICT'
        )
    ),
    CONSTRAINT ck_m1_13_fallback CHECK (
        fallback_path_code IN (
            'NONE', 'PARAMETER_ONLY_RECOVERY', 'RECOVERY_SOURCE_REVIEW',
            'INSUFFICIENT_RISK_EVIDENCE', 'VERIFICATION_STOP',
            'MANUAL_LOSS_REVIEW'
        )
    ),
    CONSTRAINT ck_m1_13_blocked_loss CHECK (
        loss_evidence_status <> 'BLOCKED'
        OR (
            synthetic_merchant_risk_proxy IS NULL
            AND simple_comparative_expected_loss_amount IS NULL
            AND schedule_adjusted_comparative_expected_loss_amount IS NULL
            AND simple_comparative_loss_rate IS NULL
            AND schedule_adjusted_comparative_loss_rate IS NULL
        )
    ),
    CONSTRAINT ck_m1_13_loss_lineage CHECK (created_by_run_id = module1_run_id),
    CONSTRAINT fk_m1_13_loss_run FOREIGN KEY (module1_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_13_loss_scenario FOREIGN KEY (scenario_id)
        REFERENCES msbf_ctl.scenario_registry(scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_13_loss_application FOREIGN KEY (merchant_application_id)
        REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_13_loss_population FOREIGN KEY (population_id)
        REFERENCES msbf_m1.population_registry(population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_13_loss_merchant FOREIGN KEY (merchant_id)
        REFERENCES msbf_m1.merchant_master(merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_13_loss_risk FOREIGN KEY (
        module1_run_id, scenario_id, merchant_application_id
    ) REFERENCES msbf_m1.application_integrated_risk_proxy_snapshot (
        module1_run_id, scenario_id, merchant_application_id
    ) ON DELETE CASCADE,
    CONSTRAINT fk_m1_13_loss_capacity FOREIGN KEY (
        module1_run_id, scenario_id, merchant_application_id
    ) REFERENCES msbf_m1.application_liquidity_capacity_snapshot (
        module1_run_id, scenario_id, merchant_application_id
    ) ON DELETE CASCADE,
    CONSTRAINT fk_m1_13_loss_created_run FOREIGN KEY (created_by_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT
);

COMMENT ON TABLE msbf_m1.application_exposure_recovery_loss_snapshot IS
'Scenario-aware M1.13 contractual exposure, path-weighted EAD, recovery/LGD, and comparative expected-loss foundation evidence.';

CREATE INDEX IF NOT EXISTS ix_m1_13_loss_tier
    ON msbf_m1.application_exposure_recovery_loss_snapshot (
        module1_run_id, scenario_id, integrated_risk_tier, loss_evidence_status
    );

CREATE INDEX IF NOT EXISTS ix_m1_13_loss_industry
    ON msbf_m1.application_exposure_recovery_loss_snapshot (
        industry_code, scenario_id, lgd_input_rate
    );

CREATE INDEX IF NOT EXISTS ix_m1_13_loss_review
    ON msbf_m1.application_exposure_recovery_loss_snapshot (
        module1_run_id, manual_review_recommended_flag, fallback_path_code
    );

/* ---------------------------------------------------------------------------
5. Governed lineage view
--------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW msbf_m1.v_m1_13_exposure_recovery_loss_lineage AS
SELECT
    l.module1_run_id,
    l.scenario_id,
    sr.scenario_code,
    l.merchant_application_id,
    l.population_id,
    l.merchant_id,
    l.as_of_date,
    l.industry_code,
    l.integrated_risk_evidence_status,
    l.recovery_evidence_status,
    l.loss_evidence_status,
    l.synthetic_merchant_risk_proxy,
    l.integrated_risk_tier,
    l.initial_receivable_exposure_amount,
    l.path_weighted_ead_amount,
    l.expected_ead_rate,
    l.lgd_input_rate,
    l.recovery_rate_assumption,
    l.simple_comparative_expected_loss_amount,
    l.schedule_adjusted_comparative_expected_loss_amount,
    l.schedule_adjusted_comparative_loss_rate,
    l.recovery_basis_code,
    l.fallback_path_code,
    l.primary_loss_reason_code,
    l.row_hash
FROM msbf_m1.application_exposure_recovery_loss_snapshot l
JOIN msbf_ctl.scenario_registry sr
  ON sr.scenario_id = l.scenario_id;

/* ---------------------------------------------------------------------------
6. Approved M1.13 policy profile
--------------------------------------------------------------------------- */
INSERT INTO msbf_ctl.policy_profile (
    profile_code, profile_version, business_name, effective_start_date,
    effective_end_date, status, owner_role, approver_role,
    approval_timestamp, last_review_date, next_review_date, change_reason,
    policy_domain, product_structure_profile_id, operating_model_profile_id,
    parameter_set_id, profile_payload
)
SELECT
    'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS',
    1,
    'M1.13 Exposure, Recovery and Expected Loss Foundations Policy',
    r.as_of_date,
    NULL,
    'APPROVED',
    'Credit Risk / Finance',
    'Credit Risk, Finance and Model Governance',
    coalesce(p.approval_timestamp, clock_timestamp()),
    r.as_of_date,
    r.as_of_date + 365,
    'Initial governed M1.13 exposure-path, recovery/LGD and comparative loss methodology.',
    'EXPOSURE_RECOVERY_EXPECTED_LOSS_FOUNDATIONS',
    r.product_structure_profile_id,
    r.operating_model_profile_id,
    r.parameter_set_id,
    '{"generation_enabled":true,"methodology_version":"M1_13_METHOD_V1","exposure_basis_code":"CONTRACTUAL_RECEIVABLE","ead_method_code":"WEIGHTED_DAILY_BALANCE","default_timing_basis_code":"EARLY_MIDDLE_LATE","risk_proxy_basis_code":"SYNTHETIC_MERCHANT_RISK_PROXY","stress_payment_cap_to_baseline":true,"stress_ead_floor_to_baseline":true,"stress_lgd_floor_to_baseline":true,"stress_loss_floor_to_baseline":true,"recovery_credit_cap_rate":0.25,"stress_lgd_addon_base_rate":0.08,"manual_review_lgd_threshold":0.85,"manual_review_loss_rate_threshold":0.15,"blocked_loss_behavior":"NULL_WITH_REVIEW","industry_stress_multiplier":{"RESTAURANT_FOOD_SERVICE":0.6,"GENERAL_RETAIL":0.5,"PROFESSIONAL_SERVICES":0.3,"CONSTRUCTION_TRADES":0.7,"TRANSPORTATION_LOGISTICS":0.8,"ENERGY_SERVICES":1.0,"HEALTHCARE_SERVICES":0.2,"ECOMMERCE_DIGITAL":0.4}}'::jsonb
FROM msbf_ctl.run_registry r
LEFT JOIN msbf_ctl.policy_profile p
  ON p.profile_code = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
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
    approval_timestamp = coalesce(msbf_ctl.policy_profile.approval_timestamp, EXCLUDED.approval_timestamp),
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
7. Extension checkpoint
--------------------------------------------------------------------------- */
SELECT
    to_regclass('msbf_m1.application_ead_path_value') IS NOT NULL
        AS ead_path_table_exists,
    to_regclass('msbf_m1.application_exposure_recovery_loss_snapshot') IS NOT NULL
        AS loss_snapshot_table_exists,
    to_regclass('msbf_m1.v_m1_13_exposure_recovery_loss_lineage') IS NOT NULL
        AS lineage_view_exists,
    (
        SELECT count(*)
        FROM msbf_m1.feature_definition
        WHERE feature_family_code = 'EXPOSURE_RECOVERY_LOSS'
          AND active_flag
    ) AS active_feature_definitions,
    (
        SELECT status
        FROM msbf_ctl.policy_profile
        WHERE profile_code = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
          AND profile_version = 1
    ) AS policy_status,
    CASE
        WHEN to_regclass('msbf_m1.application_ead_path_value') IS NOT NULL
         AND to_regclass('msbf_m1.application_exposure_recovery_loss_snapshot') IS NOT NULL
         AND to_regclass('msbf_m1.v_m1_13_exposure_recovery_loss_lineage') IS NOT NULL
         AND (
             SELECT count(*)
             FROM msbf_m1.feature_definition
             WHERE feature_family_code = 'EXPOSURE_RECOVERY_LOSS'
               AND active_flag
         ) = 10
         AND (
             SELECT status
             FROM msbf_ctl.policy_profile
             WHERE profile_code = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
               AND profile_version = 1
         ) = 'APPROVED'
        THEN 'PASS'
        ELSE 'FAIL'
    END AS schema_policy_extension_status;
