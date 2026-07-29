/* ============================================================================
MSBF M1.14 Unit Economics & Risk-Adjusted Contribution Foundations
Program : 100_msbf_m1_14_schema_policy_extension_v0_2R3.sql
Version : v0.2R3
Purpose : Register the M1.14 acceptance gate, feature family, feature catalog,
          scenario-aware unit-economics snapshot, transparent economics
          component table, lineage view, and approved methodology profile.
Inputs  : Accepted G0-M1.13 database state.
Outputs : Metadata and schema only; no M1.14 business evidence is generated.
Boundary: Conditional-if-booked unit-economics foundations only. This program
          does not create price recommendations, offer structures, acceptance
          probabilities, approval decisions, CECL, reserves, or capital.
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
    'M1_14_UNIT_ECONOMICS_CONTRIBUTION',
    'M1.14 Unit Economics and Risk-Adjusted Contribution Foundations',
    'M1',
    'BLOCKING',
    'Scenario-aware revenue, cost, comparative-loss burden, risk-capital charge, contribution, return, and hurdle evidence acceptance.'
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
    'UNIT_ECONOMICS_CONTRIBUTION',
    'Unit Economics and Risk-Adjusted Contribution',
    'Finance / Credit Risk / Treasury',
    'Conditional-if-booked revenue, cost, comparative-loss burden, capital-charge, contribution, return, and economic-hurdle foundations.'
)
ON CONFLICT (feature_family_code) DO UPDATE SET
    feature_family_name = EXCLUDED.feature_family_name,
    owner_role = EXCLUDED.owner_role,
    active_flag = true,
    description = EXCLUDED.description;

/* ---------------------------------------------------------------------------
2. Governed economics feature definitions
--------------------------------------------------------------------------- */
INSERT INTO msbf_m1.feature_definition (
    feature_code, feature_version, feature_name, feature_family_code,
    data_type, unit_code, observation_window_days, formula_description,
    expected_direction, valid_min_numeric, valid_max_numeric, owner_role,
    active_flag, production_boundary
)
VALUES
    ('GROSS_FINANCE_REVENUE_AMOUNT',1,'Gross Finance Revenue','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Requested finance charge amount under the conditional-if-booked economics basis.','HIGHER_REVENUE',0,NULL,'Finance',true,'Synthetic economics foundation; not recognized accounting revenue or pricing.'),
    ('PROCESSOR_PAYMENT_COST_AMOUNT',1,'Processor Payment Cost','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Requested total repayment multiplied by the governed processor-payment cost rate.','HIGHER_COST',0,NULL,'Finance / Operations',true,'Synthetic cost assumption; not a processor invoice or contract rate.'),
    ('PARTNER_ACQUISITION_COST_AMOUNT',1,'Partner Acquisition Cost','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Requested funding multiplied by the supported or governed-default partner acquisition cost rate.','HIGHER_COST',0,NULL,'Finance / Partnerships',true,'Synthetic acquisition-cost foundation; not contractual settlement.'),
    ('FUNDING_COST_AMOUNT',1,'Funding Cost','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Path-weighted EAD multiplied by annual funding cost and expected payoff fraction.','HIGHER_COST',0,NULL,'Treasury / Finance',true,'Synthetic funding-cost foundation; not treasury transfer pricing.'),
    ('SERVICING_COST_AMOUNT',1,'Servicing Cost','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Daily servicing cost over expected payoff horizon plus governed variable servicing cost.','HIGHER_COST',0,NULL,'Operations / Finance',true,'Synthetic servicing-cost foundation; not a vendor invoice.'),
    ('OPERATING_COST_AMOUNT',1,'Operating Cost','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Governed fixed operating cost plus requested-funding variable operating cost.','HIGHER_COST',0,NULL,'Operations / Finance',true,'Synthetic operating-cost foundation.'),
    ('TOTAL_NON_LOSS_COST_AMOUNT',1,'Total Non-Loss Cost','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Processor, partner, funding, servicing, and operating costs summed.','HIGHER_COST',0,NULL,'Finance',true,'Synthetic economics foundation.'),
    ('CONTRIBUTION_BEFORE_COMPARATIVE_LOSS_AMOUNT',1,'Contribution Before Comparative Loss','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Gross finance revenue less total non-loss costs.','HIGHER_CONTRIBUTION',NULL,NULL,'Finance',true,'Conditional-if-booked synthetic contribution; not GAAP income.'),
    ('COMPARATIVE_EXPECTED_LOSS_BURDEN_AMOUNT',1,'Comparative Expected Loss Burden','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Accepted M1.13 schedule-adjusted comparative expected-loss foundation.','HIGHER_LOSS',0,NULL,'Credit Risk / Finance',true,'Synthetic comparative loss; not CECL, reserve, or forecast.'),
    ('CONTRIBUTION_AFTER_COMPARATIVE_LOSS_AMOUNT',1,'Contribution After Comparative Loss','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Contribution before comparative loss less accepted comparative loss burden.','HIGHER_CONTRIBUTION',NULL,NULL,'Finance / Credit Risk',true,'Synthetic conditional contribution; not recognized profit.'),
    ('RISK_CAPITAL_CHARGE_AMOUNT',1,'Risk Capital Charge','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Path-weighted EAD multiplied by governed capital allocation, cost of capital, and payoff fraction.','HIGHER_COST',0,NULL,'Finance / Treasury / Risk',true,'Synthetic risk-capital charge; not regulatory capital.'),
    ('RISK_ADJUSTED_CONTRIBUTION_AMOUNT',1,'Risk-Adjusted Contribution','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Contribution after comparative loss less synthetic risk-capital charge.','HIGHER_CONTRIBUTION',NULL,NULL,'Finance / Credit Risk',true,'Synthetic economics foundation; not final pricing or booked contribution.'),
    ('HURDLE_REQUIRED_CONTRIBUTION_AMOUNT',1,'Hurdle Required Contribution','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Requested funding multiplied by governed annual hurdle and payoff fraction.','HIGHER_REQUIREMENT',0,NULL,'Finance',true,'Synthetic hurdle foundation; not approved pricing policy.'),
    ('ECONOMIC_SURPLUS_AMOUNT',1,'Economic Surplus','UNIT_ECONOMICS_CONTRIBUTION','NUMERIC','CURRENCY',NULL,'Risk-adjusted contribution less hurdle-required contribution.','HIGHER_SURPLUS',NULL,NULL,'Finance / Credit Risk',true,'Synthetic comparative economic surplus; not recognized profit.')
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
3. Scenario-aware unit-economics snapshot
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_m1.application_unit_economics_snapshot (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    industry_code text NOT NULL,
    merchant_size_tier text NOT NULL,
    relationship_stage text NOT NULL,
    partner_channel_id text,
    channel_type text NOT NULL,
    exposure_recovery_loss_snapshot_hash text NOT NULL,
    liquidity_capacity_snapshot_hash text NOT NULL,
    application_request_hash text NOT NULL,
    loss_evidence_status text NOT NULL,
    channel_cost_evidence_status text NOT NULL,
    unit_economics_evidence_status text NOT NULL,
    integrated_risk_tier smallint NOT NULL,
    path_weighted_ead_amount numeric(18,2) NOT NULL,
    schedule_adjusted_comparative_loss_rate numeric(12,8),
    requested_funding_amount numeric(18,2) NOT NULL,
    requested_total_repayment_amount numeric(18,2) NOT NULL,
    requested_finance_charge_amount numeric(18,2) NOT NULL,
    requested_expected_payoff_days smallint NOT NULL,
    payback_multiple numeric(12,8) NOT NULL,
    gross_finance_revenue_amount numeric(18,2) NOT NULL,
    gross_finance_charge_rate numeric(12,8) NOT NULL,
    annualized_gross_yield_rate numeric(12,8) NOT NULL,
    processor_payment_cost_rate numeric(12,8) NOT NULL,
    processor_payment_cost_amount numeric(18,2) NOT NULL,
    partner_acquisition_cost_rate numeric(12,8) NOT NULL,
    partner_acquisition_cost_amount numeric(18,2) NOT NULL,
    funding_cost_annual_rate numeric(12,8) NOT NULL,
    funding_cost_amount numeric(18,2) NOT NULL,
    servicing_daily_cost_amount numeric(18,2) NOT NULL,
    servicing_variable_cost_rate numeric(12,8) NOT NULL,
    servicing_cost_amount numeric(18,2) NOT NULL,
    operating_cost_fixed_amount numeric(18,2) NOT NULL,
    operating_cost_variable_rate numeric(12,8) NOT NULL,
    operating_cost_amount numeric(18,2) NOT NULL,
    total_non_loss_cost_amount numeric(18,2) NOT NULL,
    contribution_before_comparative_loss_amount numeric(18,2) NOT NULL,
    comparative_expected_loss_amount numeric(18,2),
    contribution_after_comparative_loss_amount numeric(18,2),
    risk_capital_allocation_rate numeric(12,8) NOT NULL,
    risk_capital_cost_annual_rate numeric(12,8) NOT NULL,
    risk_capital_charge_amount numeric(18,2) NOT NULL,
    independent_risk_adjusted_contribution_amount numeric(18,2),
    baseline_risk_adjusted_contribution_amount numeric(18,2),
    risk_adjusted_contribution_amount numeric(18,2),
    contribution_before_loss_margin_rate numeric(12,8) NOT NULL,
    contribution_after_loss_margin_rate numeric(12,8),
    independent_risk_adjusted_contribution_margin_rate numeric(12,8),
    risk_adjusted_contribution_margin_rate numeric(12,8),
    independent_annualized_risk_adjusted_return_rate numeric(12,8),
    baseline_annualized_risk_adjusted_return_rate numeric(12,8),
    annualized_risk_adjusted_return_rate numeric(12,8),
    hurdle_annual_return_rate numeric(12,8) NOT NULL,
    hurdle_required_contribution_amount numeric(18,2) NOT NULL,
    economic_surplus_amount numeric(18,2),
    independent_economic_tier smallint NOT NULL,
    baseline_economic_tier smallint NOT NULL,
    economic_tier smallint NOT NULL,
    stress_economic_worsening_flag boolean NOT NULL,
    hurdle_pass_flag boolean NOT NULL,
    economic_status text NOT NULL,
    hard_stop_recommended_flag boolean NOT NULL,
    manual_review_recommended_flag boolean NOT NULL,
    fallback_path_code text NOT NULL,
    primary_economic_reason_code text NOT NULL,
    secondary_economic_reason_codes text[] DEFAULT '{}'::text[] NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_m1_14_unit_economics PRIMARY KEY (
        module1_run_id, scenario_id, merchant_application_id
    ),
    CONSTRAINT ck_m1_14_request_amounts CHECK (
        requested_funding_amount > 0
        AND requested_total_repayment_amount >= requested_funding_amount
        AND requested_finance_charge_amount = requested_total_repayment_amount - requested_funding_amount
    ),
    CONSTRAINT ck_m1_14_payoff CHECK (requested_expected_payoff_days IN (30,60,90)),
    CONSTRAINT ck_m1_14_nonnegative_costs CHECK (
        path_weighted_ead_amount >= 0
        AND processor_payment_cost_amount >= 0
        AND partner_acquisition_cost_amount >= 0
        AND funding_cost_amount >= 0
        AND servicing_cost_amount >= 0
        AND operating_cost_amount >= 0
        AND total_non_loss_cost_amount >= 0
        AND risk_capital_charge_amount >= 0
        AND hurdle_required_contribution_amount >= 0
        AND (comparative_expected_loss_amount IS NULL OR comparative_expected_loss_amount >= 0)
    ),
    CONSTRAINT ck_m1_14_rates CHECK (
        payback_multiple >= 1
        AND gross_finance_charge_rate >= 0
        AND annualized_gross_yield_rate >= 0
        AND processor_payment_cost_rate BETWEEN 0 AND 1
        AND partner_acquisition_cost_rate BETWEEN 0 AND 1
        AND funding_cost_annual_rate BETWEEN 0 AND 1
        AND servicing_variable_cost_rate BETWEEN 0 AND 1
        AND operating_cost_variable_rate BETWEEN 0 AND 1
        AND risk_capital_allocation_rate BETWEEN 0 AND 1
        AND risk_capital_cost_annual_rate BETWEEN 0 AND 1
        AND hurdle_annual_return_rate BETWEEN 0 AND 1
        AND (schedule_adjusted_comparative_loss_rate IS NULL OR schedule_adjusted_comparative_loss_rate BETWEEN 0 AND 1)
    ),
    CONSTRAINT ck_m1_14_tiers CHECK (
        integrated_risk_tier BETWEEN 1 AND 5
        AND independent_economic_tier BETWEEN 1 AND 5
        AND baseline_economic_tier BETWEEN 1 AND 5
        AND economic_tier BETWEEN 1 AND 5
    ),
    CONSTRAINT ck_m1_14_evidence CHECK (
        loss_evidence_status IN ('COMPLETE','PARTIAL','BLOCKED')
        AND channel_cost_evidence_status IN ('SUPPORTED','DEFAULT_PARAMETER')
        AND unit_economics_evidence_status IN ('COMPLETE','PARTIAL','BLOCKED')
    ),
    CONSTRAINT ck_m1_14_status CHECK (
        economic_status IN ('ABOVE_HURDLE','BELOW_HURDLE','NEGATIVE_CONTRIBUTION','INSUFFICIENT_EVIDENCE')
    ),
    CONSTRAINT ck_m1_14_fallback CHECK (
        fallback_path_code IN (
            'NONE','DEFAULT_CHANNEL_COST','PARAMETER_ONLY_COSTS',
            'INSUFFICIENT_LOSS_EVIDENCE','ECONOMIC_HURDLE_REVIEW',
            'NEGATIVE_CONTRIBUTION_REVIEW','MANUAL_UNIT_ECONOMICS_REVIEW'
        )
    ),
    CONSTRAINT ck_m1_14_blocked CHECK (
        unit_economics_evidence_status <> 'BLOCKED'
        OR (
            comparative_expected_loss_amount IS NULL
            AND contribution_after_comparative_loss_amount IS NULL
            AND independent_risk_adjusted_contribution_amount IS NULL
            AND risk_adjusted_contribution_amount IS NULL
            AND contribution_after_loss_margin_rate IS NULL
            AND independent_risk_adjusted_contribution_margin_rate IS NULL
            AND risk_adjusted_contribution_margin_rate IS NULL
            AND independent_annualized_risk_adjusted_return_rate IS NULL
            AND annualized_risk_adjusted_return_rate IS NULL
            AND economic_surplus_amount IS NULL
        )
    ),
    CONSTRAINT ck_m1_14_run_lineage CHECK (created_by_run_id = module1_run_id),
    CONSTRAINT fk_m1_14_run FOREIGN KEY (module1_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_14_scenario FOREIGN KEY (scenario_id)
        REFERENCES msbf_ctl.scenario_registry(scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_14_application FOREIGN KEY (merchant_application_id)
        REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_14_population FOREIGN KEY (population_id)
        REFERENCES msbf_m1.population_registry(population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_14_merchant FOREIGN KEY (merchant_id)
        REFERENCES msbf_m1.merchant_master(merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_14_partner FOREIGN KEY (partner_channel_id)
        REFERENCES msbf_m1.partner_channel(partner_channel_id) ON DELETE SET NULL,
    CONSTRAINT fk_m1_14_loss FOREIGN KEY (
        module1_run_id, scenario_id, merchant_application_id
    ) REFERENCES msbf_m1.application_exposure_recovery_loss_snapshot (
        module1_run_id, scenario_id, merchant_application_id
    ) ON DELETE CASCADE,
    CONSTRAINT fk_m1_14_capacity FOREIGN KEY (
        module1_run_id, scenario_id, merchant_application_id
    ) REFERENCES msbf_m1.application_liquidity_capacity_snapshot (
        module1_run_id, scenario_id, merchant_application_id
    ) ON DELETE CASCADE,
    CONSTRAINT fk_m1_14_created_run FOREIGN KEY (created_by_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT
);


/* Idempotently upgrade an existing legacy blocked-evidence contract. */
DO $upgrade_blocked_contract$
DECLARE
    v_def text;
    v_validated boolean;
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows
    FROM msbf_m1.application_unit_economics_snapshot;

    SELECT pg_get_constraintdef(c.oid),c.convalidated
    INTO STRICT v_def,v_validated
    FROM pg_constraint c
    JOIN pg_class t ON t.oid=c.conrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='msbf_m1'
      AND t.relname='application_unit_economics_snapshot'
      AND c.conname='ck_m1_14_blocked';

    IF position('(baseline_risk_adjusted_contribution_amount is null)' in lower(v_def))>0
       OR position('(baseline_annualized_risk_adjusted_return_rate is null)' in lower(v_def))>0 THEN
        IF v_rows<>0 THEN
            RAISE EXCEPTION 'Cannot upgrade legacy M1.14 blocked contract after business rows exist; rows %.',v_rows;
        END IF;
        EXECUTE 'ALTER TABLE msbf_m1.application_unit_economics_snapshot DROP CONSTRAINT ck_m1_14_blocked';
        EXECUTE $ddl$
            ALTER TABLE msbf_m1.application_unit_economics_snapshot
            ADD CONSTRAINT ck_m1_14_blocked CHECK (
        unit_economics_evidence_status <> 'BLOCKED'
        OR (
            comparative_expected_loss_amount IS NULL
            AND contribution_after_comparative_loss_amount IS NULL
            AND independent_risk_adjusted_contribution_amount IS NULL
            AND risk_adjusted_contribution_amount IS NULL
            AND contribution_after_loss_margin_rate IS NULL
            AND independent_risk_adjusted_contribution_margin_rate IS NULL
            AND risk_adjusted_contribution_margin_rate IS NULL
            AND independent_annualized_risk_adjusted_return_rate IS NULL
            AND annualized_risk_adjusted_return_rate IS NULL
            AND economic_surplus_amount IS NULL
        )
    ) NOT VALID
        $ddl$;
        EXECUTE 'ALTER TABLE msbf_m1.application_unit_economics_snapshot VALIDATE CONSTRAINT ck_m1_14_blocked';
    ELSIF NOT v_validated THEN
        EXECUTE 'ALTER TABLE msbf_m1.application_unit_economics_snapshot VALIDATE CONSTRAINT ck_m1_14_blocked';
    END IF;
END;
$upgrade_blocked_contract$;

COMMENT ON CONSTRAINT ck_m1_14_blocked
    ON msbf_m1.application_unit_economics_snapshot IS
'MSBF_M1_14_BLOCKED_CONTRACT_V2 | Blocked current-scenario loss-dependent economics remain NULL. Matched-baseline contribution and return references may remain populated for comparison, lineage, and adverse-scenario non-improvement controls.';

COMMENT ON TABLE msbf_m1.application_unit_economics_snapshot IS
'Scenario-aware M1.14 conditional-if-booked revenue, non-loss cost, comparative-loss burden, synthetic capital charge, risk-adjusted contribution, return, hurdle, and economic-review evidence.';

CREATE INDEX IF NOT EXISTS ix_m1_14_economics_status
    ON msbf_m1.application_unit_economics_snapshot (
        module1_run_id, scenario_id, economic_tier, economic_status
    );
CREATE INDEX IF NOT EXISTS ix_m1_14_economics_review
    ON msbf_m1.application_unit_economics_snapshot (
        module1_run_id, manual_review_recommended_flag, hard_stop_recommended_flag
    );
CREATE INDEX IF NOT EXISTS ix_m1_14_economics_channel
    ON msbf_m1.application_unit_economics_snapshot (
        partner_channel_id, scenario_id, annualized_risk_adjusted_return_rate
    );

/* ---------------------------------------------------------------------------
4. Long-form economics component evidence
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_m1.unit_economics_component_value (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    component_code text NOT NULL,
    component_version smallint DEFAULT 1 NOT NULL,
    component_amount numeric(18,2),
    component_rate numeric(12,8),
    component_sign smallint NOT NULL,
    component_status text NOT NULL,
    component_reason_code text NOT NULL,
    source_lineage_hash text NOT NULL,
    calculation_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_m1_14_component PRIMARY KEY (
        module1_run_id, scenario_id, merchant_application_id,
        component_code, component_version
    ),
    CONSTRAINT ck_m1_14_component_sign CHECK (component_sign IN (-1,1)),
    CONSTRAINT ck_m1_14_component_status CHECK (
        component_status IN ('AVAILABLE','UNAVAILABLE')
    ),
    CONSTRAINT ck_m1_14_component_code CHECK (
        component_code IN (
            'GROSS_FINANCE_REVENUE','PROCESSOR_PAYMENT_COST',
            'PARTNER_ACQUISITION_COST','FUNDING_COST','SERVICING_COST',
            'OPERATING_COST','TOTAL_NON_LOSS_COST',
            'CONTRIBUTION_BEFORE_COMPARATIVE_LOSS',
            'COMPARATIVE_EXPECTED_LOSS_BURDEN',
            'CONTRIBUTION_AFTER_COMPARATIVE_LOSS',
            'RISK_CAPITAL_CHARGE','RISK_ADJUSTED_CONTRIBUTION',
            'HURDLE_REQUIREMENT','ECONOMIC_SURPLUS'
        )
    ),
    CONSTRAINT ck_m1_14_component_lineage CHECK (created_by_run_id = module1_run_id),
    CONSTRAINT fk_m1_14_component_snapshot FOREIGN KEY (
        module1_run_id, scenario_id, merchant_application_id
    ) REFERENCES msbf_m1.application_unit_economics_snapshot (
        module1_run_id, scenario_id, merchant_application_id
    ) ON DELETE CASCADE,
    CONSTRAINT fk_m1_14_component_run FOREIGN KEY (created_by_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT
);

COMMENT ON TABLE msbf_m1.unit_economics_component_value IS
'Long-form M1.14 revenue, cost, loss, contribution, capital-charge, hurdle, and surplus evidence used to reconcile the wide unit-economics snapshot.';

CREATE INDEX IF NOT EXISTS ix_m1_14_component_code
    ON msbf_m1.unit_economics_component_value (
        module1_run_id, scenario_id, component_code, component_status
    );

/* ---------------------------------------------------------------------------
5. Governed lineage view
--------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW msbf_m1.v_m1_14_unit_economics_lineage AS
SELECT
    e.module1_run_id,
    e.scenario_id,
    sr.scenario_code,
    e.merchant_application_id,
    e.population_id,
    e.merchant_id,
    e.as_of_date,
    e.industry_code,
    e.merchant_size_tier,
    e.relationship_stage,
    e.partner_channel_id,
    e.channel_type,
    e.unit_economics_evidence_status,
    e.gross_finance_revenue_amount,
    e.total_non_loss_cost_amount,
    e.comparative_expected_loss_amount,
    e.risk_capital_charge_amount,
    e.risk_adjusted_contribution_amount,
    e.annualized_risk_adjusted_return_rate,
    e.hurdle_required_contribution_amount,
    e.economic_surplus_amount,
    e.economic_tier,
    e.economic_status,
    e.fallback_path_code,
    e.primary_economic_reason_code,
    e.row_hash
FROM msbf_m1.application_unit_economics_snapshot e
JOIN msbf_ctl.scenario_registry sr
  ON sr.scenario_id = e.scenario_id;

/* ---------------------------------------------------------------------------
6. Approved M1.14 methodology profile
--------------------------------------------------------------------------- */
INSERT INTO msbf_ctl.policy_profile (
    profile_code, profile_version, business_name, effective_start_date,
    effective_end_date, status, owner_role, approver_role,
    approval_timestamp, last_review_date, next_review_date, change_reason,
    policy_domain, product_structure_profile_id, operating_model_profile_id,
    parameter_set_id, profile_payload
)
SELECT
    'M1_14_UNIT_ECONOMICS_CONTRIBUTION',
    1,
    'M1.14 Unit Economics and Risk-Adjusted Contribution Policy',
    r.as_of_date,
    NULL,
    'APPROVED',
    'Finance / Credit Risk / Treasury',
    'Finance, Credit Risk and Model Governance',
    coalesce(p.approval_timestamp, clock_timestamp()),
    r.as_of_date,
    r.as_of_date + 365,
    'Initial governed M1.14 conditional-if-booked unit economics and risk-adjusted contribution methodology.',
    'UNIT_ECONOMICS_RISK_ADJUSTED_CONTRIBUTION',
    r.product_structure_profile_id,
    r.operating_model_profile_id,
    r.parameter_set_id,
    '{
      "generation_enabled":true,
      "methodology_version":"M1_14_METHOD_V1",
      "contribution_basis_code":"CONDITIONAL_IF_BOOKED",
      "comparative_loss_basis_code":"M1_13_SCHEDULE_ADJUSTED_COMPARATIVE_LOSS",
      "funding_cost_basis_code":"PATH_WEIGHTED_EAD_X_ANNUAL_RATE_X_TERM",
      "risk_capital_charge_basis_code":"PATH_WEIGHTED_EAD_X_CAPITAL_X_COST_OF_CAPITAL_X_TERM",
      "hurdle_basis_code":"FUNDED_AMOUNT_X_ANNUAL_HURDLE_X_TERM",
      "stress_contribution_cap_to_baseline":true,
      "stress_return_cap_to_baseline":true,
      "stress_economic_tier_floor_to_baseline":true,
      "processor_payment_cost_rate":0.006,
      "default_partner_acquisition_cost_rate":0.03,
      "partner_acquisition_cost_rate_cap":0.08,
      "funding_cost_annual_rate":0.09,
      "servicing_daily_cost_amount":1.50,
      "servicing_variable_cost_rate":0.0015,
      "operating_cost_fixed_amount":125.00,
      "operating_cost_variable_rate":0.0025,
      "risk_capital_allocation_rate":0.12,
      "risk_capital_cost_annual_rate":0.15,
      "hurdle_annual_return_rate":0.18,
      "economic_tier_1_return_threshold":0.25,
      "economic_tier_2_return_threshold":0.18,
      "economic_tier_3_return_threshold":0.10,
      "annualization_days":365,
      "currency_tolerance_amount":0.01,
      "rate_tolerance":0.00000001
    }'::jsonb
FROM msbf_ctl.run_registry r
LEFT JOIN msbf_ctl.policy_profile p
  ON p.profile_code = 'M1_14_UNIT_ECONOMICS_CONTRIBUTION'
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
WITH p AS (
    SELECT policy_profile_id, status, profile_payload,
           md5(profile_payload::text) AS policy_hash
    FROM msbf_ctl.policy_profile
    WHERE profile_code = 'M1_14_UNIT_ECONOMICS_CONTRIBUTION'
      AND profile_version = 1
), f AS (
    SELECT count(*) AS active_features
    FROM msbf_m1.feature_definition
    WHERE feature_family_code = 'UNIT_ECONOMICS_CONTRIBUTION'
      AND feature_version = 1
      AND active_flag
)
SELECT
    to_regclass('msbf_m1.application_unit_economics_snapshot') IS NOT NULL
        AS unit_economics_table_exists,
    to_regclass('msbf_m1.unit_economics_component_value') IS NOT NULL
        AS component_table_exists,
    to_regclass('msbf_m1.v_m1_14_unit_economics_lineage') IS NOT NULL
        AS lineage_view_exists,
    (SELECT count(*) FROM information_schema.columns
     WHERE table_schema='msbf_m1'
       AND table_name='application_unit_economics_snapshot') AS snapshot_columns,
    (SELECT count(*) FROM information_schema.columns
     WHERE table_schema='msbf_m1'
       AND table_name='unit_economics_component_value') AS component_columns,
    f.active_features,
    p.policy_profile_id,
    p.status AS policy_status,
    p.policy_hash,
    p.profile_payload ->> 'methodology_version' AS methodology_version,
    CASE
        WHEN to_regclass('msbf_m1.application_unit_economics_snapshot') IS NOT NULL
         AND to_regclass('msbf_m1.unit_economics_component_value') IS NOT NULL
         AND to_regclass('msbf_m1.v_m1_14_unit_economics_lineage') IS NOT NULL
         AND (SELECT count(*) FROM information_schema.columns
              WHERE table_schema='msbf_m1'
                AND table_name='application_unit_economics_snapshot') = 74
         AND (SELECT count(*) FROM information_schema.columns
              WHERE table_schema='msbf_m1'
                AND table_name='unit_economics_component_value') = 14
         AND f.active_features = 14
         AND p.status = 'APPROVED'
         AND p.profile_payload ->> 'methodology_version' = 'M1_14_METHOD_V1'
        THEN 'PASS'
        ELSE 'FAIL'
    END AS schema_policy_extension_status
FROM p CROSS JOIN f;
