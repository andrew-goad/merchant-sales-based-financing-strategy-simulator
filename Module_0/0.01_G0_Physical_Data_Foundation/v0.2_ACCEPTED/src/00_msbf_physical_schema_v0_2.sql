/*
================================================================================
MERCHANT SALES-BASED FINANCING STRATEGY SIMULATOR
PHYSICAL POSTGRESQL SCHEMA v0.2
Target: PostgreSQL 14+
================================================================================
This file creates the governed control plane and Module 1 physical foundation.
Schemas for Modules 2-4, evidence, and reporting are reserved for controlled
future releases. All data and assumptions are synthetic.
================================================================================
*/
BEGIN;
CREATE SCHEMA IF NOT EXISTS msbf_ref;
CREATE SCHEMA IF NOT EXISTS msbf_ctl;
CREATE SCHEMA IF NOT EXISTS msbf_m1;
CREATE SCHEMA IF NOT EXISTS msbf_m2;
CREATE SCHEMA IF NOT EXISTS msbf_m3;
CREATE SCHEMA IF NOT EXISTS msbf_m4;
CREATE SCHEMA IF NOT EXISTS msbf_evd;
CREATE SCHEMA IF NOT EXISTS msbf_rpt;
SET TIME ZONE 'UTC';

-- ---------------------------------------------------------------------------
-- msbf_ref.industry
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ref.industry (
    industry_code text NOT NULL,
    industry_name text NOT NULL,
    industry_group text NOT NULL,
    risk_tier smallint NOT NULL,
    dependency_node_code text NOT NULL,
    active_flag boolean DEFAULT true NOT NULL,
    effective_start_date date DEFAULT DATE '2026-01-01' NOT NULL,
    effective_end_date date,
    description text,
    CONSTRAINT pk_msbf_ref_industry PRIMARY KEY (industry_code),
    CONSTRAINT ck_industry_tier CHECK (risk_tier between 1 and 5),
    CONSTRAINT ck_industry_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date)
);
COMMENT ON TABLE msbf_ref.industry IS 'Industry taxonomy for merchant risk and network stress.';
COMMENT ON COLUMN msbf_ref.industry.industry_code IS 'Stable industry key.';

-- ---------------------------------------------------------------------------
-- msbf_ref.geography_region
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ref.geography_region (
    region_code text NOT NULL,
    region_name text NOT NULL,
    country_code char(2) DEFAULT 'US' NOT NULL,
    active_flag boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT pk_msbf_ref_geography_region PRIMARY KEY (region_code)
);
COMMENT ON TABLE msbf_ref.geography_region IS 'Synthetic region taxonomy; no address or protected-class data.';

-- ---------------------------------------------------------------------------
-- msbf_ref.source_code
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ref.source_code (
    source_code text NOT NULL,
    source_name text NOT NULL,
    source_domain text NOT NULL,
    expected_grain text NOT NULL,
    restricted_data_flag boolean DEFAULT false NOT NULL,
    active_flag boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT pk_msbf_ref_source_code PRIMARY KEY (source_code)
);
COMMENT ON TABLE msbf_ref.source_code IS 'Approved source-type catalog.';

-- ---------------------------------------------------------------------------
-- msbf_ref.verification_check_code
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ref.verification_check_code (
    check_code text NOT NULL,
    check_name text NOT NULL,
    check_domain text NOT NULL,
    hard_stop_eligible_flag boolean DEFAULT false NOT NULL,
    active_flag boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT pk_msbf_ref_verification_check_code PRIMARY KEY (check_code)
);
COMMENT ON TABLE msbf_ref.verification_check_code IS 'Synthetic verification and fraud check catalog.';

-- ---------------------------------------------------------------------------
-- msbf_ref.risk_component_code
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ref.risk_component_code (
    component_code text NOT NULL,
    component_name text NOT NULL,
    component_domain text NOT NULL,
    expected_direction text NOT NULL,
    active_flag boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT pk_msbf_ref_risk_component_code PRIMARY KEY (component_code),
    CONSTRAINT ck_component_direction CHECK (expected_direction in ('INCREASES_RISK','DECREASES_RISK','CONTEXTUAL'))
);
COMMENT ON TABLE msbf_ref.risk_component_code IS 'Transparent Module 1 risk-component catalog.';

-- ---------------------------------------------------------------------------
-- msbf_ref.feature_family
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ref.feature_family (
    feature_family_code text NOT NULL,
    feature_family_name text NOT NULL,
    owner_role text NOT NULL,
    active_flag boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT pk_msbf_ref_feature_family PRIMARY KEY (feature_family_code)
);
COMMENT ON TABLE msbf_ref.feature_family IS 'Feature-family taxonomy.';

-- ---------------------------------------------------------------------------
-- msbf_ref.cashflow_archetype
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ref.cashflow_archetype (
    archetype_code text NOT NULL,
    archetype_name text NOT NULL,
    ordinal_risk_rank smallint NOT NULL,
    active_flag boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT pk_msbf_ref_cashflow_archetype PRIMARY KEY (archetype_code),
    CONSTRAINT ck_archetype_rank CHECK (ordinal_risk_rank between 1 and 10)
);
COMMENT ON TABLE msbf_ref.cashflow_archetype IS 'Explainable merchant cash-flow archetypes.';

-- ---------------------------------------------------------------------------
-- msbf_ref.acceptance_gate_catalog
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ref.acceptance_gate_catalog (
    gate_id text NOT NULL,
    gate_name text NOT NULL,
    module_code text NOT NULL,
    severity text NOT NULL,
    active_flag boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT pk_msbf_ref_acceptance_gate_catalog PRIMARY KEY (gate_id),
    CONSTRAINT ck_gate_severity CHECK (severity in ('BLOCKING','MATERIAL','ADVISORY'))
);
COMMENT ON TABLE msbf_ref.acceptance_gate_catalog IS 'Build and run acceptance-gate catalog.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.source_reference
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.source_reference (
    source_reference_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    source_type text NOT NULL,
    title text NOT NULL,
    publisher text,
    url text,
    jurisdiction_code text,
    publication_date date,
    effective_date date,
    accessed_date date DEFAULT current_date NOT NULL,
    source_status text DEFAULT 'CURRENT' NOT NULL,
    content_hash text,
    notes text,
    CONSTRAINT pk_msbf_ctl_source_reference PRIMARY KEY (source_reference_id),
    CONSTRAINT uq_msbf_ctl_source_reference_1 UNIQUE (title, publisher, publication_date)
);
COMMENT ON TABLE msbf_ctl.source_reference IS 'Official/approved source lineage.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.product_legal_structure_profile
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.product_legal_structure_profile (
    product_structure_profile_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    profile_code text NOT NULL,
    profile_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    approver_role text,
    approval_timestamp timestamptz,
    last_review_date date,
    next_review_date date,
    change_reason text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    created_by text DEFAULT current_user NOT NULL,
    legal_structure_code text NOT NULL,
    economic_mechanics_code text NOT NULL,
    repayment_contingency_code text NOT NULL,
    reconciliation_supported_flag boolean DEFAULT true NOT NULL,
    absolute_repayment_obligation_flag boolean,
    source_reference_id bigint,
    supersedes_profile_id bigint,
    profile_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_product_legal_structure_profile PRIMARY KEY (product_structure_profile_id),
    CONSTRAINT uq_msbf_ctl_product_legal_structure_profile_1 UNIQUE (profile_code, profile_version),
    CONSTRAINT ck_product_profile_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date),
    CONSTRAINT fk_msbf_ctl_product_legal_structure_profile_1 FOREIGN KEY (source_reference_id) REFERENCES msbf_ctl.source_reference (source_reference_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_ctl_product_legal_structure_profile_2 FOREIGN KEY (supersedes_profile_id) REFERENCES msbf_ctl.product_legal_structure_profile (product_structure_profile_id) ON DELETE SET NULL
);
COMMENT ON TABLE msbf_ctl.product_legal_structure_profile IS 'Effective-dated legal/economic profile; no legal conclusion inferred from label.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.operating_model_profile
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.operating_model_profile (
    operating_model_profile_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    profile_code text NOT NULL,
    profile_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    approver_role text,
    approval_timestamp timestamptz,
    last_review_date date,
    next_review_date date,
    change_reason text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    created_by text DEFAULT current_user NOT NULL,
    provider_entity_type text NOT NULL,
    bank_partner_model text NOT NULL,
    processor_control_model text NOT NULL,
    broker_model text NOT NULL,
    servicing_model text NOT NULL,
    funding_model text NOT NULL,
    collections_model text NOT NULL,
    supersedes_profile_id bigint,
    profile_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_operating_model_profile PRIMARY KEY (operating_model_profile_id),
    CONSTRAINT uq_msbf_ctl_operating_model_profile_1 UNIQUE (profile_code, profile_version),
    CONSTRAINT ck_operating_profile_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date),
    CONSTRAINT fk_msbf_ctl_operating_model_profile_1 FOREIGN KEY (supersedes_profile_id) REFERENCES msbf_ctl.operating_model_profile (operating_model_profile_id) ON DELETE SET NULL
);
COMMENT ON TABLE msbf_ctl.operating_model_profile IS 'Effective-dated entity-role and operating-model profile.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.third_party_relationship_profile
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.third_party_relationship_profile (
    third_party_relationship_profile_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    profile_code text NOT NULL,
    profile_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    approver_role text,
    approval_timestamp timestamptz,
    last_review_date date,
    next_review_date date,
    change_reason text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    created_by text DEFAULT current_user NOT NULL,
    operating_model_profile_id bigint NOT NULL,
    provider_code text NOT NULL,
    service_code text NOT NULL,
    accountable_owner_role text NOT NULL,
    due_diligence_status text NOT NULL,
    monitoring_status text NOT NULL,
    continuity_plan_status text NOT NULL,
    exit_plan_status text NOT NULL,
    incident_status text DEFAULT 'NONE' NOT NULL,
    subcontractor_flag boolean DEFAULT false NOT NULL,
    profile_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_third_party_relationship_profile PRIMARY KEY (third_party_relationship_profile_id),
    CONSTRAINT uq_msbf_ctl_third_party_relationship_profile_1 UNIQUE (profile_code, profile_version),
    CONSTRAINT fk_msbf_ctl_third_party_relationship_profile_1 FOREIGN KEY (operating_model_profile_id) REFERENCES msbf_ctl.operating_model_profile (operating_model_profile_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_ctl.third_party_relationship_profile IS 'Third-party role, oversight, continuity, and exit profile.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.source_contract
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.source_contract (
    source_contract_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    source_code text NOT NULL,
    contract_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    expected_grain text NOT NULL,
    required_history_days integer DEFAULT 0 NOT NULL,
    freshness_sla_hours integer,
    minimum_completeness_rate numeric(9,6) DEFAULT 1 NOT NULL,
    reconciliation_tolerance_rate numeric(9,6),
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    schema_definition jsonb DEFAULT '{}'::jsonb NOT NULL,
    quality_rules jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    created_by text DEFAULT current_user NOT NULL,
    CONSTRAINT pk_msbf_ctl_source_contract PRIMARY KEY (source_contract_id),
    CONSTRAINT uq_msbf_ctl_source_contract_1 UNIQUE (source_code, contract_version),
    CONSTRAINT ck_source_contract_rates CHECK (minimum_completeness_rate between 0 and 1 and (reconciliation_tolerance_rate is null or reconciliation_tolerance_rate between 0 and 1)),
    CONSTRAINT ck_source_contract_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date),
    CONSTRAINT fk_msbf_ctl_source_contract_1 FOREIGN KEY (source_code) REFERENCES msbf_ref.source_code (source_code) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_ctl.source_contract IS 'Versioned source data contract.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.parameter_definition
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.parameter_definition (
    parameter_name text NOT NULL,
    parameter_category text NOT NULL,
    parameter_subcategory text,
    module_code text NOT NULL,
    stage_code text,
    data_type text NOT NULL,
    unit_code text,
    scope_dimensions text[] DEFAULT ARRAY[]::text[] NOT NULL,
    description text NOT NULL,
    business_rationale text,
    calculation_usage text,
    default_value_text text,
    minimum_value_numeric numeric(24,10),
    maximum_value_numeric numeric(24,10),
    allowed_values jsonb,
    required_flag boolean DEFAULT true NOT NULL,
    scenario_override_allowed_flag boolean DEFAULT false NOT NULL,
    change_class text DEFAULT 'STANDARD' NOT NULL,
    owner_role text NOT NULL,
    validation_rule text,
    sensitivity_class text,
    production_boundary text,
    status text DEFAULT 'ACTIVE' NOT NULL,
    definition_version integer DEFAULT 1 NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_ctl_parameter_definition PRIMARY KEY (parameter_name),
    CONSTRAINT ck_parameter_type CHECK (data_type in ('INTEGER','NUMERIC','TEXT','BOOLEAN','DATE','JSON')),
    CONSTRAINT ck_parameter_change CHECK (change_class in ('STANDARD','MATERIAL','MODEL_LOGIC','REGULATORY','SECURITY'))
);
COMMENT ON TABLE msbf_ctl.parameter_definition IS 'Canonical parameter dictionary.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.parameter_set
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.parameter_set (
    parameter_set_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    parameter_set_code text NOT NULL,
    parameter_set_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    purpose text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    approver_role text,
    approval_timestamp timestamptz,
    supersedes_parameter_set_id bigint,
    parameter_set_hash text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_ctl_parameter_set PRIMARY KEY (parameter_set_id),
    CONSTRAINT uq_msbf_ctl_parameter_set_1 UNIQUE (parameter_set_code, parameter_set_version),
    CONSTRAINT ck_parameter_set_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date),
    CONSTRAINT fk_msbf_ctl_parameter_set_1 FOREIGN KEY (supersedes_parameter_set_id) REFERENCES msbf_ctl.parameter_set (parameter_set_id) ON DELETE SET NULL
);
COMMENT ON TABLE msbf_ctl.parameter_set IS 'Immutable versioned parameter set.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.parameter_value
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.parameter_value (
    parameter_value_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    parameter_set_id bigint NOT NULL,
    parameter_name text NOT NULL,
    scope_key text DEFAULT 'GLOBAL' NOT NULL,
    scope_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    value_numeric numeric(24,10),
    value_text text,
    value_boolean boolean,
    value_date date,
    value_json jsonb,
    unit_code text,
    effective_start_date date NOT NULL,
    effective_end_date date,
    source_reference_id bigint,
    change_reason text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_ctl_parameter_value PRIMARY KEY (parameter_value_id),
    CONSTRAINT uq_msbf_ctl_parameter_value_1 UNIQUE (parameter_set_id, parameter_name, scope_key, effective_start_date),
    CONSTRAINT ck_parameter_value_one_type CHECK (num_nonnulls(value_numeric,value_text,value_boolean,value_date,value_json)=1),
    CONSTRAINT ck_parameter_value_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date),
    CONSTRAINT fk_msbf_ctl_parameter_value_1 FOREIGN KEY (parameter_set_id) REFERENCES msbf_ctl.parameter_set (parameter_set_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_ctl_parameter_value_2 FOREIGN KEY (parameter_name) REFERENCES msbf_ctl.parameter_definition (parameter_name) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_ctl_parameter_value_3 FOREIGN KEY (source_reference_id) REFERENCES msbf_ctl.source_reference (source_reference_id) ON DELETE SET NULL
);
COMMENT ON TABLE msbf_ctl.parameter_value IS 'Typed and scoped parameter value.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.policy_profile
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.policy_profile (
    policy_profile_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    profile_code text NOT NULL,
    profile_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    approver_role text,
    approval_timestamp timestamptz,
    last_review_date date,
    next_review_date date,
    change_reason text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    created_by text DEFAULT current_user NOT NULL,
    policy_domain text NOT NULL,
    product_structure_profile_id bigint,
    operating_model_profile_id bigint,
    parameter_set_id bigint NOT NULL,
    profile_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_policy_profile PRIMARY KEY (policy_profile_id),
    CONSTRAINT uq_msbf_ctl_policy_profile_1 UNIQUE (profile_code, profile_version),
    CONSTRAINT fk_msbf_ctl_policy_profile_1 FOREIGN KEY (product_structure_profile_id) REFERENCES msbf_ctl.product_legal_structure_profile (product_structure_profile_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_ctl_policy_profile_2 FOREIGN KEY (operating_model_profile_id) REFERENCES msbf_ctl.operating_model_profile (operating_model_profile_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_ctl_policy_profile_3 FOREIGN KEY (parameter_set_id) REFERENCES msbf_ctl.parameter_set (parameter_set_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_ctl.policy_profile IS 'Governed policy profile.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.strategy_profile
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.strategy_profile (
    strategy_profile_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    profile_code text NOT NULL,
    profile_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    approver_role text,
    approval_timestamp timestamptz,
    last_review_date date,
    next_review_date date,
    change_reason text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    created_by text DEFAULT current_user NOT NULL,
    strategy_domain text NOT NULL,
    policy_profile_id bigint NOT NULL,
    objective_code text NOT NULL,
    strategy_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_strategy_profile PRIMARY KEY (strategy_profile_id),
    CONSTRAINT uq_msbf_ctl_strategy_profile_1 UNIQUE (profile_code, profile_version),
    CONSTRAINT fk_msbf_ctl_strategy_profile_1 FOREIGN KEY (policy_profile_id) REFERENCES msbf_ctl.policy_profile (policy_profile_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_ctl.strategy_profile IS 'Governed strategy profile.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.experiment_registry
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.experiment_registry (
    experiment_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    experiment_code text NOT NULL,
    experiment_version integer DEFAULT 1 NOT NULL,
    experiment_name text NOT NULL,
    objective text NOT NULL,
    eligibility_rule jsonb NOT NULL,
    assignment_seed text NOT NULL,
    holdout_rate numeric(9,6) DEFAULT 0 NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    acceptance_criteria jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_experiment_registry PRIMARY KEY (experiment_id),
    CONSTRAINT uq_msbf_ctl_experiment_registry_1 UNIQUE (experiment_code, experiment_version),
    CONSTRAINT ck_holdout_rate CHECK (holdout_rate between 0 and 1),
    CONSTRAINT ck_experiment_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date)
);
COMMENT ON TABLE msbf_ctl.experiment_registry IS 'Controlled randomized test registry.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.experiment_cell
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.experiment_cell (
    experiment_cell_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    experiment_id bigint NOT NULL,
    cell_code text NOT NULL,
    cell_name text NOT NULL,
    control_flag boolean DEFAULT false NOT NULL,
    allocation_rate numeric(9,6) NOT NULL,
    treatment_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_experiment_cell PRIMARY KEY (experiment_cell_id),
    CONSTRAINT uq_msbf_ctl_experiment_cell_1 UNIQUE (experiment_id, cell_code),
    CONSTRAINT ck_cell_allocation CHECK (allocation_rate between 0 and 1),
    CONSTRAINT fk_msbf_ctl_experiment_cell_1 FOREIGN KEY (experiment_id) REFERENCES msbf_ctl.experiment_registry (experiment_id) ON DELETE CASCADE
);
COMMENT ON TABLE msbf_ctl.experiment_cell IS 'Experiment control/treatment cell.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.scenario_set
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.scenario_set (
    scenario_set_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    scenario_set_code text NOT NULL,
    scenario_set_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    purpose text NOT NULL,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    created_by text DEFAULT current_user NOT NULL,
    CONSTRAINT pk_msbf_ctl_scenario_set PRIMARY KEY (scenario_set_id),
    CONSTRAINT uq_msbf_ctl_scenario_set_1 UNIQUE (scenario_set_code, scenario_set_version)
);
COMMENT ON TABLE msbf_ctl.scenario_set IS 'Scenario family registry.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.scenario_registry
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.scenario_registry (
    scenario_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    scenario_set_id bigint NOT NULL,
    scenario_code text NOT NULL,
    scenario_version integer DEFAULT 1 NOT NULL,
    scenario_name text NOT NULL,
    scenario_type text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    parameter_set_id bigint NOT NULL,
    assumption_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    interpretation_boundary text NOT NULL,
    CONSTRAINT pk_msbf_ctl_scenario_registry PRIMARY KEY (scenario_id),
    CONSTRAINT uq_msbf_ctl_scenario_registry_1 UNIQUE (scenario_set_id, scenario_code, scenario_version),
    CONSTRAINT ck_scenario_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date),
    CONSTRAINT fk_msbf_ctl_scenario_registry_1 FOREIGN KEY (scenario_set_id) REFERENCES msbf_ctl.scenario_set (scenario_set_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_ctl_scenario_registry_2 FOREIGN KEY (parameter_set_id) REFERENCES msbf_ctl.parameter_set (parameter_set_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_ctl.scenario_registry IS 'Versioned baseline or stress scenario.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.risk_appetite_limit
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.risk_appetite_limit (
    limit_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    limit_code text NOT NULL,
    limit_version integer DEFAULT 1 NOT NULL,
    policy_profile_id bigint NOT NULL,
    metric_code text NOT NULL,
    scope_key text DEFAULT 'PORTFOLIO' NOT NULL,
    scope_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    target_min_value numeric(24,10),
    target_max_value numeric(24,10),
    early_warning_value numeric(24,10),
    hard_limit_value numeric(24,10) NOT NULL,
    breach_direction text NOT NULL,
    required_action text NOT NULL,
    owner_role text NOT NULL,
    review_cadence text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    CONSTRAINT pk_msbf_ctl_risk_appetite_limit PRIMARY KEY (limit_id),
    CONSTRAINT uq_msbf_ctl_risk_appetite_limit_1 UNIQUE (limit_code, limit_version, scope_key),
    CONSTRAINT ck_limit_direction CHECK (breach_direction in ('ABOVE','BELOW','OUTSIDE_RANGE')),
    CONSTRAINT ck_limit_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date),
    CONSTRAINT fk_msbf_ctl_risk_appetite_limit_1 FOREIGN KEY (policy_profile_id) REFERENCES msbf_ctl.policy_profile (policy_profile_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_ctl.risk_appetite_limit IS 'Risk appetite target, warning, hard limit, action, and owner.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.jurisdiction_profile
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.jurisdiction_profile (
    jurisdiction_profile_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    profile_code text NOT NULL,
    profile_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    approver_role text,
    approval_timestamp timestamptz,
    last_review_date date,
    next_review_date date,
    change_reason text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    created_by text DEFAULT current_user NOT NULL,
    jurisdiction_code text NOT NULL,
    country_code char(2) DEFAULT 'US' NOT NULL,
    transaction_amount_floor numeric(18,2),
    transaction_amount_ceiling numeric(18,2),
    profile_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_jurisdiction_profile PRIMARY KEY (jurisdiction_profile_id),
    CONSTRAINT uq_msbf_ctl_jurisdiction_profile_1 UNIQUE (profile_code, profile_version)
);
COMMENT ON TABLE msbf_ctl.jurisdiction_profile IS 'Effective-dated jurisdiction scope.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.data_segregation_profile
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.data_segregation_profile (
    data_segregation_profile_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    profile_code text NOT NULL,
    profile_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    approver_role text,
    approval_timestamp timestamptz,
    last_review_date date,
    next_review_date date,
    change_reason text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    created_by text DEFAULT current_user NOT NULL,
    data_domain text NOT NULL,
    restricted_flag boolean DEFAULT true NOT NULL,
    permitted_roles text[] NOT NULL,
    prohibited_uses text[] NOT NULL,
    profile_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_data_segregation_profile PRIMARY KEY (data_segregation_profile_id),
    CONSTRAINT uq_msbf_ctl_data_segregation_profile_1 UNIQUE (profile_code, profile_version)
);
COMMENT ON TABLE msbf_ctl.data_segregation_profile IS 'Restricted data segregation and access profile.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.record_retention_profile
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.record_retention_profile (
    record_retention_profile_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    profile_code text NOT NULL,
    profile_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    approver_role text,
    approval_timestamp timestamptz,
    last_review_date date,
    next_review_date date,
    change_reason text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    created_by text DEFAULT current_user NOT NULL,
    record_domain text NOT NULL,
    retention_period_months integer NOT NULL,
    legal_hold_supported_flag boolean DEFAULT true NOT NULL,
    profile_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_record_retention_profile PRIMARY KEY (record_retention_profile_id),
    CONSTRAINT uq_msbf_ctl_record_retention_profile_1 UNIQUE (profile_code, profile_version)
);
COMMENT ON TABLE msbf_ctl.record_retention_profile IS 'Record retention profile.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.financial_crime_profile
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.financial_crime_profile (
    financial_crime_profile_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    profile_code text NOT NULL,
    profile_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    approver_role text,
    approval_timestamp timestamptz,
    last_review_date date,
    next_review_date date,
    change_reason text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    created_by text DEFAULT current_user NOT NULL,
    operating_model_profile_id bigint NOT NULL,
    kyb_owner_role text NOT NULL,
    beneficial_owner_owner_role text NOT NULL,
    sanctions_owner_role text NOT NULL,
    aml_monitoring_owner_role text NOT NULL,
    profile_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_financial_crime_profile PRIMARY KEY (financial_crime_profile_id),
    CONSTRAINT uq_msbf_ctl_financial_crime_profile_1 UNIQUE (profile_code, profile_version),
    CONSTRAINT fk_msbf_ctl_financial_crime_profile_1 FOREIGN KEY (operating_model_profile_id) REFERENCES msbf_ctl.operating_model_profile (operating_model_profile_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_ctl.financial_crime_profile IS 'Financial-crime responsibility profile.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.payment_data_scope_profile
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.payment_data_scope_profile (
    payment_data_scope_profile_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    profile_code text NOT NULL,
    profile_version integer DEFAULT 1 NOT NULL,
    business_name text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    approver_role text,
    approval_timestamp timestamptz,
    last_review_date date,
    next_review_date date,
    change_reason text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    created_by text DEFAULT current_user NOT NULL,
    stores_payment_account_data_flag boolean DEFAULT false NOT NULL,
    processes_payment_account_data_flag boolean DEFAULT false NOT NULL,
    transmits_payment_account_data_flag boolean DEFAULT false NOT NULL,
    can_affect_security_flag boolean DEFAULT false NOT NULL,
    scope_status text NOT NULL,
    profile_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_payment_data_scope_profile PRIMARY KEY (payment_data_scope_profile_id),
    CONSTRAINT uq_msbf_ctl_payment_data_scope_profile_1 UNIQUE (profile_code, profile_version)
);
COMMENT ON TABLE msbf_ctl.payment_data_scope_profile IS 'Payment-data scope profile; public simulator is synthetic/aggregate only.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.regulatory_requirement
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.regulatory_requirement (
    regulatory_requirement_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    requirement_code text NOT NULL,
    requirement_version integer DEFAULT 1 NOT NULL,
    requirement_name text NOT NULL,
    requirement_domain text NOT NULL,
    jurisdiction_profile_id bigint,
    product_structure_codes text[] DEFAULT ARRAY[]::text[] NOT NULL,
    operating_model_codes text[] DEFAULT ARRAY[]::text[] NOT NULL,
    applicability_rule jsonb NOT NULL,
    required_action text NOT NULL,
    source_reference_id bigint,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    implementation_mapping jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pk_msbf_ctl_regulatory_requirement PRIMARY KEY (regulatory_requirement_id),
    CONSTRAINT uq_msbf_ctl_regulatory_requirement_1 UNIQUE (requirement_code, requirement_version),
    CONSTRAINT fk_msbf_ctl_regulatory_requirement_1 FOREIGN KEY (jurisdiction_profile_id) REFERENCES msbf_ctl.jurisdiction_profile (jurisdiction_profile_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_ctl_regulatory_requirement_2 FOREIGN KEY (source_reference_id) REFERENCES msbf_ctl.source_reference (source_reference_id) ON DELETE SET NULL
);
COMMENT ON TABLE msbf_ctl.regulatory_requirement IS 'Effective-dated regulatory requirement and implementation mapping.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.disclosure_requirement
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.disclosure_requirement (
    disclosure_requirement_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    regulatory_requirement_id bigint NOT NULL,
    document_code text NOT NULL,
    calculation_method_code text,
    delivery_timing_code text NOT NULL,
    required_fields jsonb NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    CONSTRAINT pk_msbf_ctl_disclosure_requirement PRIMARY KEY (disclosure_requirement_id),
    CONSTRAINT fk_msbf_ctl_disclosure_requirement_1 FOREIGN KEY (regulatory_requirement_id) REFERENCES msbf_ctl.regulatory_requirement (regulatory_requirement_id) ON DELETE CASCADE
);
COMMENT ON TABLE msbf_ctl.disclosure_requirement IS 'Disclosure/package requirement.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.permission_requirement
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.permission_requirement (
    permission_requirement_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    regulatory_requirement_id bigint NOT NULL,
    permission_type text NOT NULL,
    entity_role text NOT NULL,
    jurisdiction_code text NOT NULL,
    required_status text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    CONSTRAINT pk_msbf_ctl_permission_requirement PRIMARY KEY (permission_requirement_id),
    CONSTRAINT fk_msbf_ctl_permission_requirement_1 FOREIGN KEY (regulatory_requirement_id) REFERENCES msbf_ctl.regulatory_requirement (regulatory_requirement_id) ON DELETE CASCADE
);
COMMENT ON TABLE msbf_ctl.permission_requirement IS 'License/registration/permission requirement.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.reporting_requirement
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.reporting_requirement (
    reporting_requirement_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    regulatory_requirement_id bigint NOT NULL,
    reporting_program_code text NOT NULL,
    institution_threshold_rule jsonb NOT NULL,
    transaction_coverage_rule jsonb NOT NULL,
    required_data_fields jsonb NOT NULL,
    compliance_date_rule jsonb NOT NULL,
    firewall_required_flag boolean DEFAULT false NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    CONSTRAINT pk_msbf_ctl_reporting_requirement PRIMARY KEY (reporting_requirement_id),
    CONSTRAINT fk_msbf_ctl_reporting_requirement_1 FOREIGN KEY (regulatory_requirement_id) REFERENCES msbf_ctl.regulatory_requirement (regulatory_requirement_id) ON DELETE CASCADE
);
COMMENT ON TABLE msbf_ctl.reporting_requirement IS 'Reporting-program requirement.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.unsupported_feature_catalog
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.unsupported_feature_catalog (
    feature_code text NOT NULL,
    feature_version integer DEFAULT 1 NOT NULL,
    feature_name text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'ACTIVE' NOT NULL,
    prohibition_reason text NOT NULL,
    owner_role text NOT NULL,
    source_reference_id bigint,
    CONSTRAINT pk_msbf_ctl_unsupported_feature_catalog PRIMARY KEY (feature_code, feature_version),
    CONSTRAINT fk_msbf_ctl_unsupported_feature_catalog_1 FOREIGN KEY (source_reference_id) REFERENCES msbf_ctl.source_reference (source_reference_id) ON DELETE SET NULL
);
COMMENT ON TABLE msbf_ctl.unsupported_feature_catalog IS 'Unsupported/prohibited strategy feature catalog.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.reason_code_catalog
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.reason_code_catalog (
    reason_code text NOT NULL,
    reason_version integer DEFAULT 1 NOT NULL,
    reason_name text NOT NULL,
    reason_domain text NOT NULL,
    severity_rank smallint NOT NULL,
    customer_communication_flag boolean DEFAULT false NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'ACTIVE' NOT NULL,
    policy_profile_id bigint,
    explanation_template text NOT NULL,
    CONSTRAINT pk_msbf_ctl_reason_code_catalog PRIMARY KEY (reason_code, reason_version),
    CONSTRAINT ck_reason_rank CHECK (severity_rank between 1 and 100),
    CONSTRAINT fk_msbf_ctl_reason_code_catalog_1 FOREIGN KEY (policy_profile_id) REFERENCES msbf_ctl.policy_profile (policy_profile_id) ON DELETE SET NULL
);
COMMENT ON TABLE msbf_ctl.reason_code_catalog IS 'Simulated explanation/action reason catalog; not regulatory notices.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.contract_registry
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.contract_registry (
    contract_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    contract_code text NOT NULL,
    contract_version integer DEFAULT 1 NOT NULL,
    provider_module_code text NOT NULL,
    consumer_module_code text NOT NULL,
    grain_description text NOT NULL,
    key_columns text[] NOT NULL,
    required_columns jsonb DEFAULT '[]'::jsonb NOT NULL,
    schema_hash text,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'DRAFT' NOT NULL,
    owner_role text NOT NULL,
    CONSTRAINT pk_msbf_ctl_contract_registry PRIMARY KEY (contract_id),
    CONSTRAINT uq_msbf_ctl_contract_registry_1 UNIQUE (contract_code, contract_version)
);
COMMENT ON TABLE msbf_ctl.contract_registry IS 'Versioned intermodule contract registry.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.run_registry
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.run_registry (
    run_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    run_code text NOT NULL,
    run_version integer DEFAULT 1 NOT NULL,
    module_code text NOT NULL,
    run_type text NOT NULL,
    population_id text,
    scenario_id bigint,
    parameter_set_id bigint NOT NULL,
    policy_profile_id bigint,
    strategy_profile_id bigint,
    product_structure_profile_id bigint,
    operating_model_profile_id bigint,
    jurisdiction_profile_id bigint,
    contract_id bigint,
    as_of_date date NOT NULL,
    run_status text DEFAULT 'PLANNED' NOT NULL,
    started_at timestamptz,
    completed_at timestamptz,
    row_count bigint,
    parameter_snapshot_hash text,
    profile_snapshot_hash text,
    source_snapshot_hash text,
    code_version text NOT NULL,
    notes text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_ctl_run_registry PRIMARY KEY (run_id),
    CONSTRAINT uq_msbf_ctl_run_registry_1 UNIQUE (run_code, run_version),
    CONSTRAINT ck_run_times CHECK (completed_at is null or started_at is null or completed_at >= started_at),
    CONSTRAINT fk_msbf_ctl_run_registry_1 FOREIGN KEY (scenario_id) REFERENCES msbf_ctl.scenario_registry (scenario_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_ctl_run_registry_2 FOREIGN KEY (parameter_set_id) REFERENCES msbf_ctl.parameter_set (parameter_set_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_ctl_run_registry_3 FOREIGN KEY (policy_profile_id) REFERENCES msbf_ctl.policy_profile (policy_profile_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_ctl_run_registry_4 FOREIGN KEY (strategy_profile_id) REFERENCES msbf_ctl.strategy_profile (strategy_profile_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_ctl_run_registry_5 FOREIGN KEY (product_structure_profile_id) REFERENCES msbf_ctl.product_legal_structure_profile (product_structure_profile_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_ctl_run_registry_6 FOREIGN KEY (operating_model_profile_id) REFERENCES msbf_ctl.operating_model_profile (operating_model_profile_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_ctl_run_registry_7 FOREIGN KEY (jurisdiction_profile_id) REFERENCES msbf_ctl.jurisdiction_profile (jurisdiction_profile_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_ctl_run_registry_8 FOREIGN KEY (contract_id) REFERENCES msbf_ctl.contract_registry (contract_id) ON DELETE SET NULL
);
COMMENT ON TABLE msbf_ctl.run_registry IS 'Technical run identity and frozen-governance references.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.run_profile_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.run_profile_snapshot (
    run_id bigint NOT NULL,
    profile_domain text NOT NULL,
    profile_code text NOT NULL,
    profile_version integer NOT NULL,
    resolved_profile_id bigint NOT NULL,
    profile_hash text NOT NULL,
    snapshot_payload jsonb NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_ctl_run_profile_snapshot PRIMARY KEY (run_id, profile_domain, profile_code),
    CONSTRAINT fk_msbf_ctl_run_profile_snapshot_1 FOREIGN KEY (run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE CASCADE
);
COMMENT ON TABLE msbf_ctl.run_profile_snapshot IS 'Frozen profile snapshot by run.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.run_parameter_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.run_parameter_snapshot (
    run_id bigint NOT NULL,
    parameter_name text NOT NULL,
    scope_key text NOT NULL,
    resolved_value jsonb NOT NULL,
    resolution_rank smallint NOT NULL,
    source_parameter_value_id bigint,
    snapshot_hash text NOT NULL,
    CONSTRAINT pk_msbf_ctl_run_parameter_snapshot PRIMARY KEY (run_id, parameter_name, scope_key),
    CONSTRAINT fk_msbf_ctl_run_parameter_snapshot_1 FOREIGN KEY (run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_ctl_run_parameter_snapshot_2 FOREIGN KEY (parameter_name) REFERENCES msbf_ctl.parameter_definition (parameter_name) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_ctl_run_parameter_snapshot_3 FOREIGN KEY (source_parameter_value_id) REFERENCES msbf_ctl.parameter_value (parameter_value_id) ON DELETE SET NULL
);
COMMENT ON TABLE msbf_ctl.run_parameter_snapshot IS 'Frozen resolved parameter snapshot.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.run_source_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.run_source_snapshot (
    run_id bigint NOT NULL,
    source_code text NOT NULL,
    source_contract_id bigint NOT NULL,
    source_cutoff_timestamp timestamptz NOT NULL,
    source_row_count bigint,
    source_hash text,
    quality_status text NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_ctl_run_source_snapshot PRIMARY KEY (run_id, source_code),
    CONSTRAINT fk_msbf_ctl_run_source_snapshot_1 FOREIGN KEY (run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_ctl_run_source_snapshot_2 FOREIGN KEY (source_code) REFERENCES msbf_ref.source_code (source_code) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_ctl_run_source_snapshot_3 FOREIGN KEY (source_contract_id) REFERENCES msbf_ctl.source_contract (source_contract_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_ctl.run_source_snapshot IS 'Frozen source-contract and cutoff evidence.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.comparison_registry
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.comparison_registry (
    comparison_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    comparison_code text NOT NULL,
    comparison_version integer DEFAULT 1 NOT NULL,
    comparison_name text NOT NULL,
    baseline_run_id bigint NOT NULL,
    challenger_run_id bigint NOT NULL,
    match_key_columns text[] NOT NULL,
    comparison_type text NOT NULL,
    status text DEFAULT 'PLANNED' NOT NULL,
    owner_role text NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_ctl_comparison_registry PRIMARY KEY (comparison_id),
    CONSTRAINT uq_msbf_ctl_comparison_registry_1 UNIQUE (comparison_code, comparison_version),
    CONSTRAINT fk_msbf_ctl_comparison_registry_1 FOREIGN KEY (baseline_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_ctl_comparison_registry_2 FOREIGN KEY (challenger_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_ctl.comparison_registry IS 'Governed matched comparison registry.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.run_evidence
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.run_evidence (
    run_id bigint NOT NULL,
    evidence_code text NOT NULL,
    segment_key text DEFAULT 'PORTFOLIO' NOT NULL,
    metric_name text NOT NULL,
    metric_value_numeric numeric(24,10),
    metric_value_text text,
    unit_code text,
    status text NOT NULL,
    threshold_value_numeric numeric(24,10),
    interpretation text,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_ctl_run_evidence PRIMARY KEY (run_id, evidence_code, segment_key),
    CONSTRAINT ck_evidence_value CHECK (num_nonnulls(metric_value_numeric,metric_value_text)=1),
    CONSTRAINT fk_msbf_ctl_run_evidence_1 FOREIGN KEY (run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE CASCADE
);
COMMENT ON TABLE msbf_ctl.run_evidence IS 'Technical, analytical, and governance evidence.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.acceptance_gate_result
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.acceptance_gate_result (
    run_id bigint NOT NULL,
    gate_id text NOT NULL,
    review_version integer DEFAULT 1 NOT NULL,
    result_status text NOT NULL,
    observed_value text,
    threshold_value text,
    finding text,
    residual_limitation text,
    reviewer_role text NOT NULL,
    reviewed_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_ctl_acceptance_gate_result PRIMARY KEY (run_id, gate_id, review_version),
    CONSTRAINT ck_gate_result CHECK (result_status in ('PASS','PASS_WITH_LIMITATION','FAIL','NOT_APPLICABLE')),
    CONSTRAINT fk_msbf_ctl_acceptance_gate_result_1 FOREIGN KEY (run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_ctl_acceptance_gate_result_2 FOREIGN KEY (gate_id) REFERENCES msbf_ref.acceptance_gate_catalog (gate_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_ctl.acceptance_gate_result IS 'Immutable acceptance-gate result.';

-- ---------------------------------------------------------------------------
-- msbf_ctl.profile_resolution_error
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_ctl.profile_resolution_error (
    resolution_error_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    run_id bigint,
    profile_domain text NOT NULL,
    scope_key text NOT NULL,
    error_code text NOT NULL,
    severity text NOT NULL,
    error_message text NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_ctl_profile_resolution_error PRIMARY KEY (resolution_error_id),
    CONSTRAINT ck_resolution_severity CHECK (severity in ('BLOCKING','MATERIAL','WARNING')),
    CONSTRAINT fk_msbf_ctl_profile_resolution_error_1 FOREIGN KEY (run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE CASCADE
);
COMMENT ON TABLE msbf_ctl.profile_resolution_error IS 'Fail-fast profile/parameter/source resolution errors.';

-- ---------------------------------------------------------------------------
-- msbf_m1.population_registry
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.population_registry (
    population_id text NOT NULL,
    population_version integer DEFAULT 1 NOT NULL,
    parameter_set_id bigint NOT NULL,
    deterministic_seed_version text NOT NULL,
    merchant_count integer NOT NULL,
    history_start_date date NOT NULL,
    history_end_date date NOT NULL,
    population_status text DEFAULT 'PLANNED' NOT NULL,
    population_hash text,
    created_by_run_id bigint,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_m1_population_registry PRIMARY KEY (population_id),
    CONSTRAINT ck_population_dates CHECK (history_end_date >= history_start_date),
    CONSTRAINT ck_population_count CHECK (merchant_count > 0),
    CONSTRAINT fk_msbf_m1_population_registry_1 FOREIGN KEY (parameter_set_id) REFERENCES msbf_ctl.parameter_set (parameter_set_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_population_registry_2 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE SET NULL
);
COMMENT ON TABLE msbf_m1.population_registry IS 'Deterministic synthetic population identity.';

-- ---------------------------------------------------------------------------
-- msbf_m1.merchant_master
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.merchant_master (
    merchant_id text NOT NULL,
    population_id text NOT NULL,
    synthetic_business_name text NOT NULL,
    legal_entity_type text NOT NULL,
    region_code text NOT NULL,
    incorporation_date date NOT NULL,
    merchant_size_tier text NOT NULL,
    annual_sales_band text NOT NULL,
    base_currency char(3) DEFAULT 'USD' NOT NULL,
    active_flag boolean DEFAULT true NOT NULL,
    synthetic_data_flag boolean DEFAULT true NOT NULL,
    created_date date NOT NULL,
    intrinsic_profile_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_merchant_master PRIMARY KEY (merchant_id),
    CONSTRAINT uq_msbf_m1_merchant_master_1 UNIQUE (population_id, merchant_id),
    CONSTRAINT ck_merchant_synthetic CHECK (synthetic_data_flag=true),
    CONSTRAINT fk_msbf_m1_merchant_master_1 FOREIGN KEY (population_id) REFERENCES msbf_m1.population_registry (population_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_master_2 FOREIGN KEY (region_code) REFERENCES msbf_ref.geography_region (region_code) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_master_3 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.merchant_master IS 'Stable synthetic merchant identity.';
CREATE INDEX ix_msbf_m1_merchant_master_1 ON msbf_m1.merchant_master (population_id, region_code, merchant_size_tier);

-- ---------------------------------------------------------------------------
-- msbf_m1.merchant_owner_guarantor
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.merchant_owner_guarantor (
    merchant_id text NOT NULL,
    party_id text NOT NULL,
    party_role text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    ownership_rate numeric(9,6),
    owner_credit_score smallint,
    owner_credit_band text,
    major_derogatory_flag boolean DEFAULT false NOT NULL,
    bankruptcy_flag boolean DEFAULT false NOT NULL,
    personal_guarantee_available_flag boolean DEFAULT false NOT NULL,
    guarantee_capacity_amount numeric(18,2),
    synthetic_data_flag boolean DEFAULT true NOT NULL,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_merchant_owner_guarantor PRIMARY KEY (merchant_id, party_id, party_role, effective_start_date),
    CONSTRAINT ck_owner_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date),
    CONSTRAINT ck_ownership CHECK (ownership_rate is null or ownership_rate between 0 and 1),
    CONSTRAINT ck_owner_score CHECK (owner_credit_score is null or owner_credit_score between 300 and 850),
    CONSTRAINT ck_owner_synthetic CHECK (synthetic_data_flag=true),
    CONSTRAINT fk_msbf_m1_merchant_owner_guarantor_1 FOREIGN KEY (merchant_id) REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_owner_guarantor_2 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.merchant_owner_guarantor IS 'Synthetic owner/guarantor risk evidence; no real PII.';

-- ---------------------------------------------------------------------------
-- msbf_m1.merchant_industry_assignment
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.merchant_industry_assignment (
    merchant_id text NOT NULL,
    industry_code text NOT NULL,
    assignment_type text DEFAULT 'PRIMARY' NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    revenue_share_rate numeric(9,6) DEFAULT 1 NOT NULL,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_merchant_industry_assignment PRIMARY KEY (merchant_id, industry_code, effective_start_date),
    CONSTRAINT ck_industry_assign_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date),
    CONSTRAINT ck_industry_share CHECK (revenue_share_rate between 0 and 1),
    CONSTRAINT fk_msbf_m1_merchant_industry_assignment_1 FOREIGN KEY (merchant_id) REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_industry_assignment_2 FOREIGN KEY (industry_code) REFERENCES msbf_ref.industry (industry_code) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_industry_assignment_3 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.merchant_industry_assignment IS 'Effective-dated merchant industry assignment.';

-- ---------------------------------------------------------------------------
-- msbf_m1.partner_channel
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.partner_channel (
    partner_channel_id text NOT NULL,
    partner_name_synthetic text NOT NULL,
    channel_type text NOT NULL,
    partner_risk_tier smallint NOT NULL,
    acquisition_cost_rate numeric(9,6) DEFAULT 0 NOT NULL,
    processor_affiliated_flag boolean DEFAULT false NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    status text DEFAULT 'ACTIVE' NOT NULL,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_partner_channel PRIMARY KEY (partner_channel_id),
    CONSTRAINT ck_partner_tier CHECK (partner_risk_tier between 1 and 5),
    CONSTRAINT ck_partner_cost CHECK (acquisition_cost_rate between 0 and 1),
    CONSTRAINT ck_partner_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date),
    CONSTRAINT fk_msbf_m1_partner_channel_1 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.partner_channel IS 'Synthetic acquisition/processor channel.';

-- ---------------------------------------------------------------------------
-- msbf_m1.processor_account
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.processor_account (
    processor_account_id text NOT NULL,
    merchant_id text NOT NULL,
    partner_channel_id text,
    processor_name_synthetic text NOT NULL,
    processor_account_open_date date NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    processor_status text NOT NULL,
    data_connection_status text NOT NULL,
    split_funding_capable_flag boolean DEFAULT true NOT NULL,
    settlement_delay_days smallint DEFAULT 1 NOT NULL,
    processor_risk_tier smallint DEFAULT 1 NOT NULL,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_processor_account PRIMARY KEY (processor_account_id),
    CONSTRAINT ck_processor_dates CHECK (effective_end_date is null or effective_end_date > effective_start_date),
    CONSTRAINT ck_settlement_delay CHECK (settlement_delay_days between 0 and 30),
    CONSTRAINT ck_processor_tier CHECK (processor_risk_tier between 1 and 5),
    CONSTRAINT fk_msbf_m1_processor_account_1 FOREIGN KEY (merchant_id) REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_processor_account_2 FOREIGN KEY (partner_channel_id) REFERENCES msbf_m1.partner_channel (partner_channel_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_m1_processor_account_3 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.processor_account IS 'Merchant-processor account and continuity metadata.';
CREATE INDEX ix_msbf_m1_processor_account_1 ON msbf_m1.processor_account (merchant_id, effective_start_date);

-- ---------------------------------------------------------------------------
-- msbf_m1.merchant_relationship_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.merchant_relationship_snapshot (
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    relationship_stage text NOT NULL,
    prior_advance_count integer DEFAULT 0 NOT NULL,
    completed_advance_count integer DEFAULT 0 NOT NULL,
    prior_default_flag boolean DEFAULT false NOT NULL,
    prior_payment_interruption_flag boolean DEFAULT false NOT NULL,
    total_prior_funded_amount numeric(18,2) DEFAULT 0 NOT NULL,
    total_prior_repaid_amount numeric(18,2) DEFAULT 0 NOT NULL,
    deposit_relationship_flag boolean DEFAULT false NOT NULL,
    merchant_services_relationship_flag boolean DEFAULT true NOT NULL,
    wallet_share_proxy numeric(9,6),
    relationship_quality_tier smallint,
    snapshot_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_merchant_relationship_snapshot PRIMARY KEY (merchant_id, as_of_date),
    CONSTRAINT ck_relationship_counts CHECK (prior_advance_count>=0 and completed_advance_count between 0 and prior_advance_count),
    CONSTRAINT ck_wallet_share CHECK (wallet_share_proxy is null or wallet_share_proxy between 0 and 1),
    CONSTRAINT fk_msbf_m1_merchant_relationship_snapshot_1 FOREIGN KEY (merchant_id) REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_relationship_snapshot_2 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.merchant_relationship_snapshot IS 'As-of relationship evidence for low-and-grow, renewal, and wallet strategy.';

-- ---------------------------------------------------------------------------
-- msbf_m1.merchant_application
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.merchant_application (
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    processor_account_id text NOT NULL,
    partner_channel_id text,
    application_date date NOT NULL,
    as_of_date date NOT NULL,
    requested_funding_amount numeric(18,2) NOT NULL,
    requested_remittance_rate numeric(9,6) NOT NULL,
    requested_expected_payoff_days smallint NOT NULL,
    requested_total_repayment_amount numeric(18,2) NOT NULL,
    requested_finance_charge_amount numeric(18,2) NOT NULL,
    requested_use_of_proceeds text NOT NULL,
    application_channel text NOT NULL,
    application_status text DEFAULT 'SUBMITTED' NOT NULL,
    request_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_merchant_application PRIMARY KEY (merchant_application_id),
    CONSTRAINT uq_msbf_m1_merchant_application_1 UNIQUE (population_id, merchant_application_id),
    CONSTRAINT ck_application_dates CHECK (as_of_date <= application_date),
    CONSTRAINT ck_request_amounts CHECK (requested_funding_amount>0 and requested_total_repayment_amount>=requested_funding_amount and requested_finance_charge_amount=requested_total_repayment_amount-requested_funding_amount),
    CONSTRAINT ck_request_rate CHECK (requested_remittance_rate>0 and requested_remittance_rate<=1),
    CONSTRAINT ck_request_horizon CHECK (requested_expected_payoff_days in (30,60,90)),
    CONSTRAINT fk_msbf_m1_merchant_application_1 FOREIGN KEY (population_id) REFERENCES msbf_m1.population_registry (population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_application_2 FOREIGN KEY (merchant_id) REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_application_3 FOREIGN KEY (processor_account_id) REFERENCES msbf_m1.processor_account (processor_account_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_application_4 FOREIGN KEY (partner_channel_id) REFERENCES msbf_m1.partner_channel (partner_channel_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_m1_merchant_application_5 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.merchant_application IS 'Application/request identity and sales-linked structure.';
CREATE INDEX ix_msbf_m1_merchant_application_1 ON msbf_m1.merchant_application (population_id, as_of_date);
CREATE INDEX ix_msbf_m1_merchant_application_2 ON msbf_m1.merchant_application (merchant_id, application_date);

-- ---------------------------------------------------------------------------
-- msbf_m1.source_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.source_snapshot (
    source_snapshot_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    source_code text NOT NULL,
    source_contract_id bigint NOT NULL,
    as_of_timestamp timestamptz NOT NULL,
    history_start_date date,
    history_end_date date,
    expected_observation_count integer,
    observed_observation_count integer,
    completeness_rate numeric(9,6),
    freshness_age_hours integer,
    reconciliation_rate numeric(9,6),
    availability_status text NOT NULL,
    quality_status text NOT NULL,
    data_confidence_score numeric(9,6) NOT NULL,
    fallback_path_code text,
    source_hash text NOT NULL,
    CONSTRAINT pk_msbf_m1_source_snapshot PRIMARY KEY (source_snapshot_id),
    CONSTRAINT uq_msbf_m1_source_snapshot_1 UNIQUE (source_snapshot_id, module1_run_id),
    CONSTRAINT uq_msbf_m1_source_snapshot_2 UNIQUE (module1_run_id, merchant_application_id, source_code),
    CONSTRAINT ck_source_rates CHECK ((completeness_rate is null or completeness_rate between 0 and 1) and (reconciliation_rate is null or reconciliation_rate between 0 and 1) and data_confidence_score between 0 and 1),
    CONSTRAINT ck_source_dates CHECK (history_end_date is null or history_start_date is null or history_end_date>=history_start_date),
    CONSTRAINT fk_msbf_m1_source_snapshot_1 FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_source_snapshot_2 FOREIGN KEY (merchant_application_id) REFERENCES msbf_m1.merchant_application (merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_source_snapshot_3 FOREIGN KEY (source_code) REFERENCES msbf_ref.source_code (source_code) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_source_snapshot_4 FOREIGN KEY (source_contract_id) REFERENCES msbf_ctl.source_contract (source_contract_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.source_snapshot IS 'Run-scoped application/source availability, depth, freshness, reconciliation, and confidence.';
CREATE INDEX ix_msbf_m1_source_snapshot_1 ON msbf_m1.source_snapshot (module1_run_id, merchant_application_id);

-- ---------------------------------------------------------------------------
-- msbf_m1.application_obligation_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.application_obligation_snapshot (
    merchant_application_id text NOT NULL,
    obligation_id text NOT NULL,
    as_of_date date NOT NULL,
    obligation_type text NOT NULL,
    outstanding_balance numeric(18,2) DEFAULT 0 NOT NULL,
    daily_payment_amount numeric(18,2) DEFAULT 0 NOT NULL,
    monthly_payment_amount numeric(18,2) DEFAULT 0 NOT NULL,
    remittance_rate numeric(9,6),
    lien_position smallint,
    short_term_financing_flag boolean DEFAULT false NOT NULL,
    stacking_sequence smallint,
    source_snapshot_id bigint,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_application_obligation_snapshot PRIMARY KEY (merchant_application_id, obligation_id, as_of_date),
    CONSTRAINT fk_msbf_m1_application_obligation_snapshot_1 FOREIGN KEY (merchant_application_id) REFERENCES msbf_m1.merchant_application (merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_application_obligation_snapshot_2 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_application_obligation_snapshot_3 FOREIGN KEY (source_snapshot_id, created_by_run_id) REFERENCES msbf_m1.source_snapshot (source_snapshot_id, module1_run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.application_obligation_snapshot IS 'As-of existing debt/remittance obligations and stacking evidence.';

-- ---------------------------------------------------------------------------
-- msbf_m1.collateral_availability_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.collateral_availability_snapshot (
    merchant_application_id text NOT NULL,
    collateral_type text NOT NULL,
    as_of_date date NOT NULL,
    gross_value numeric(18,2) NOT NULL,
    existing_lien_amount numeric(18,2) DEFAULT 0 NOT NULL,
    estimated_haircut_rate numeric(9,6) NOT NULL,
    available_value numeric(18,2) NOT NULL,
    ownership_verified_flag boolean DEFAULT false NOT NULL,
    valuation_confidence_tier smallint NOT NULL,
    source_snapshot_id bigint,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_collateral_availability_snapshot PRIMARY KEY (merchant_application_id, collateral_type, as_of_date),
    CONSTRAINT ck_collateral_rates CHECK (estimated_haircut_rate between 0 and 1),
    CONSTRAINT ck_collateral_values CHECK (gross_value>=0 and existing_lien_amount>=0 and available_value>=0),
    CONSTRAINT fk_msbf_m1_collateral_availability_snapshot_1 FOREIGN KEY (merchant_application_id) REFERENCES msbf_m1.merchant_application (merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_collateral_availability_snapshot_2 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_collateral_availability_snapshot_3 FOREIGN KEY (source_snapshot_id, created_by_run_id) REFERENCES msbf_m1.source_snapshot (source_snapshot_id, module1_run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.collateral_availability_snapshot IS 'Collateral availability only; not final lien/perfection or offer package.';

-- ---------------------------------------------------------------------------
-- msbf_m1.guarantee_availability_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.guarantee_availability_snapshot (
    merchant_application_id text NOT NULL,
    party_id text NOT NULL,
    as_of_date date NOT NULL,
    guarantee_type text NOT NULL,
    guarantee_available_flag boolean NOT NULL,
    guarantee_capacity_amount numeric(18,2),
    verification_status text NOT NULL,
    source_snapshot_id bigint,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_guarantee_availability_snapshot PRIMARY KEY (merchant_application_id, party_id, guarantee_type, as_of_date),
    CONSTRAINT fk_msbf_m1_guarantee_availability_snapshot_1 FOREIGN KEY (merchant_application_id) REFERENCES msbf_m1.merchant_application (merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_guarantee_availability_snapshot_2 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_guarantee_availability_snapshot_3 FOREIGN KEY (source_snapshot_id, created_by_run_id) REFERENCES msbf_m1.source_snapshot (source_snapshot_id, module1_run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.guarantee_availability_snapshot IS 'Guarantee availability evidence; not an executed guarantee.';

-- ---------------------------------------------------------------------------
-- msbf_m1.application_business_credit_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.application_business_credit_snapshot (
    merchant_application_id text NOT NULL,
    as_of_date date NOT NULL,
    business_bureau_score smallint,
    score_band text,
    delinquency_count_12m smallint DEFAULT 0 NOT NULL,
    tax_lien_flag boolean DEFAULT false NOT NULL,
    bankruptcy_flag boolean DEFAULT false NOT NULL,
    prior_business_default_flag boolean DEFAULT false NOT NULL,
    ucc_filing_count smallint DEFAULT 0 NOT NULL,
    source_snapshot_id bigint,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_application_business_credit_snapshot PRIMARY KEY (merchant_application_id, as_of_date),
    CONSTRAINT fk_msbf_m1_application_business_credit_snapshot_1 FOREIGN KEY (merchant_application_id) REFERENCES msbf_m1.merchant_application (merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_application_business_credit_snapshot_2 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_application_business_credit_snapshot_3 FOREIGN KEY (source_snapshot_id, created_by_run_id) REFERENCES msbf_m1.source_snapshot (source_snapshot_id, module1_run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.application_business_credit_snapshot IS 'As-of synthetic business credit evidence.';

-- ---------------------------------------------------------------------------
-- msbf_m1.application_owner_credit_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.application_owner_credit_snapshot (
    merchant_application_id text NOT NULL,
    party_id text NOT NULL,
    as_of_date date NOT NULL,
    owner_credit_score smallint,
    score_band text,
    delinquency_count_12m smallint DEFAULT 0 NOT NULL,
    major_derogatory_flag boolean DEFAULT false NOT NULL,
    bankruptcy_flag boolean DEFAULT false NOT NULL,
    source_snapshot_id bigint,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_application_owner_credit_snapshot PRIMARY KEY (merchant_application_id, party_id, as_of_date),
    CONSTRAINT fk_msbf_m1_application_owner_credit_snapshot_1 FOREIGN KEY (merchant_application_id) REFERENCES msbf_m1.merchant_application (merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_application_owner_credit_snapshot_2 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_application_owner_credit_snapshot_3 FOREIGN KEY (source_snapshot_id, created_by_run_id) REFERENCES msbf_m1.source_snapshot (source_snapshot_id, module1_run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.application_owner_credit_snapshot IS 'As-of synthetic owner/guarantor credit evidence.';

-- ---------------------------------------------------------------------------
-- msbf_m1.merchant_pos_daily_base
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.merchant_pos_daily_base (
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    processor_account_id text NOT NULL,
    observation_date date NOT NULL,
    gross_pos_sales numeric(18,2) NOT NULL,
    transaction_count integer NOT NULL,
    average_ticket_amount numeric(18,2) NOT NULL,
    refund_amount numeric(18,2) DEFAULT 0 NOT NULL,
    chargeback_amount numeric(18,2) DEFAULT 0 NOT NULL,
    reversal_amount numeric(18,2) DEFAULT 0 NOT NULL,
    governed_exclusion_amount numeric(18,2) DEFAULT 0 NOT NULL,
    eligible_pos_sales numeric(18,2) NOT NULL,
    processor_fee_amount numeric(18,2) DEFAULT 0 NOT NULL,
    settlement_amount numeric(18,2) NOT NULL,
    net_merchant_proceeds numeric(18,2) NOT NULL,
    zero_sales_day_flag boolean NOT NULL,
    processor_status text NOT NULL,
    data_connection_status text NOT NULL,
    source_contract_id bigint NOT NULL,
    generated_by_run_id bigint NOT NULL,
    row_hash text NOT NULL,
    CONSTRAINT pk_msbf_m1_merchant_pos_daily_base PRIMARY KEY (population_id, merchant_id, processor_account_id, observation_date),
    CONSTRAINT ck_pos_nonnegative CHECK (gross_pos_sales>=0 and transaction_count>=0 and refund_amount>=0 and chargeback_amount>=0 and reversal_amount>=0 and governed_exclusion_amount>=0 and eligible_pos_sales>=0 and processor_fee_amount>=0),
    CONSTRAINT ck_pos_reconcile CHECK (abs(eligible_pos_sales-greatest(gross_pos_sales-refund_amount-chargeback_amount-reversal_amount-governed_exclusion_amount,0))<=0.01),
    CONSTRAINT ck_pos_zero CHECK (zero_sales_day_flag=(gross_pos_sales=0)),
    CONSTRAINT fk_msbf_m1_merchant_pos_daily_base_1 FOREIGN KEY (population_id) REFERENCES msbf_m1.population_registry (population_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_pos_daily_base_2 FOREIGN KEY (merchant_id) REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_pos_daily_base_3 FOREIGN KEY (processor_account_id) REFERENCES msbf_m1.processor_account (processor_account_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_pos_daily_base_4 FOREIGN KEY (source_contract_id) REFERENCES msbf_ctl.source_contract (source_contract_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_pos_daily_base_5 FOREIGN KEY (generated_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
) PARTITION BY RANGE (observation_date);
COMMENT ON TABLE msbf_m1.merchant_pos_daily_base IS 'Immutable deterministic baseline daily POS and settlement history.';
CREATE INDEX ix_msbf_m1_merchant_pos_daily_base_1 ON msbf_m1.merchant_pos_daily_base (merchant_id, observation_date);

-- ---------------------------------------------------------------------------
-- msbf_m1.merchant_pos_daily_scenario
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.merchant_pos_daily_scenario (
    scenario_row_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    scenario_id bigint NOT NULL,
    base_row_hash text NOT NULL,
    direct_shock_factor numeric(12,8) DEFAULT 1 NOT NULL,
    propagated_shock_factor numeric(12,8) DEFAULT 1 NOT NULL,
    scenario_overlay_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    processor_account_id text NOT NULL,
    observation_date date NOT NULL,
    gross_pos_sales numeric(18,2) NOT NULL,
    transaction_count integer NOT NULL,
    average_ticket_amount numeric(18,2) NOT NULL,
    refund_amount numeric(18,2) DEFAULT 0 NOT NULL,
    chargeback_amount numeric(18,2) DEFAULT 0 NOT NULL,
    reversal_amount numeric(18,2) DEFAULT 0 NOT NULL,
    governed_exclusion_amount numeric(18,2) DEFAULT 0 NOT NULL,
    eligible_pos_sales numeric(18,2) NOT NULL,
    processor_fee_amount numeric(18,2) DEFAULT 0 NOT NULL,
    settlement_amount numeric(18,2) NOT NULL,
    net_merchant_proceeds numeric(18,2) NOT NULL,
    zero_sales_day_flag boolean NOT NULL,
    processor_status text NOT NULL,
    data_connection_status text NOT NULL,
    source_contract_id bigint NOT NULL,
    generated_by_run_id bigint NOT NULL,
    row_hash text NOT NULL,
    CONSTRAINT pk_msbf_m1_merchant_pos_daily_scenario PRIMARY KEY (scenario_row_id, observation_date),
    CONSTRAINT uq_msbf_m1_merchant_pos_daily_scenario_1 UNIQUE (scenario_id, population_id, merchant_id, processor_account_id, observation_date),
    CONSTRAINT ck_pos_nonnegative CHECK (gross_pos_sales>=0 and transaction_count>=0 and refund_amount>=0 and chargeback_amount>=0 and reversal_amount>=0 and governed_exclusion_amount>=0 and eligible_pos_sales>=0 and processor_fee_amount>=0),
    CONSTRAINT ck_pos_reconcile CHECK (abs(eligible_pos_sales-greatest(gross_pos_sales-refund_amount-chargeback_amount-reversal_amount-governed_exclusion_amount,0))<=0.01),
    CONSTRAINT ck_pos_zero CHECK (zero_sales_day_flag=(gross_pos_sales=0)),
    CONSTRAINT ck_shock_factors CHECK (direct_shock_factor>=0 and propagated_shock_factor>=0),
    CONSTRAINT fk_msbf_m1_merchant_pos_daily_scenario_1 FOREIGN KEY (scenario_id) REFERENCES msbf_ctl.scenario_registry (scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_pos_daily_scenario_2 FOREIGN KEY (population_id) REFERENCES msbf_m1.population_registry (population_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_pos_daily_scenario_3 FOREIGN KEY (merchant_id) REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_pos_daily_scenario_4 FOREIGN KEY (processor_account_id) REFERENCES msbf_m1.processor_account (processor_account_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_pos_daily_scenario_5 FOREIGN KEY (source_contract_id) REFERENCES msbf_ctl.source_contract (source_contract_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_pos_daily_scenario_6 FOREIGN KEY (generated_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
) PARTITION BY RANGE (observation_date);
COMMENT ON TABLE msbf_m1.merchant_pos_daily_scenario IS 'Scenario-adjusted daily POS history; baseline retained separately.';
CREATE INDEX ix_msbf_m1_merchant_pos_daily_scenario_1 ON msbf_m1.merchant_pos_daily_scenario (scenario_id, merchant_id, observation_date);

-- ---------------------------------------------------------------------------
-- msbf_m1.merchant_deposit_daily_base
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.merchant_deposit_daily_base (
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    observation_date date NOT NULL,
    opening_balance numeric(18,2) NOT NULL,
    deposit_amount numeric(18,2) DEFAULT 0 NOT NULL,
    withdrawal_amount numeric(18,2) DEFAULT 0 NOT NULL,
    closing_balance numeric(18,2) NOT NULL,
    available_balance numeric(18,2) NOT NULL,
    minimum_balance numeric(18,2) NOT NULL,
    nsf_count smallint DEFAULT 0 NOT NULL,
    negative_balance_flag boolean NOT NULL,
    source_contract_id bigint NOT NULL,
    generated_by_run_id bigint NOT NULL,
    row_hash text NOT NULL,
    CONSTRAINT pk_msbf_m1_merchant_deposit_daily_base PRIMARY KEY (population_id, merchant_id, observation_date),
    CONSTRAINT ck_deposit_reconcile CHECK (abs(closing_balance-(opening_balance+deposit_amount-withdrawal_amount))<=0.01),
    CONSTRAINT ck_nsf_nonnegative CHECK (nsf_count>=0),
    CONSTRAINT fk_msbf_m1_merchant_deposit_daily_base_1 FOREIGN KEY (population_id) REFERENCES msbf_m1.population_registry (population_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_deposit_daily_base_2 FOREIGN KEY (merchant_id) REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_deposit_daily_base_3 FOREIGN KEY (source_contract_id) REFERENCES msbf_ctl.source_contract (source_contract_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_deposit_daily_base_4 FOREIGN KEY (generated_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
) PARTITION BY RANGE (observation_date);
COMMENT ON TABLE msbf_m1.merchant_deposit_daily_base IS 'Optional baseline deposit/liquidity history.';
CREATE INDEX ix_msbf_m1_merchant_deposit_daily_base_1 ON msbf_m1.merchant_deposit_daily_base (merchant_id, observation_date);

-- ---------------------------------------------------------------------------
-- msbf_m1.merchant_deposit_daily_scenario
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.merchant_deposit_daily_scenario (
    scenario_row_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    scenario_id bigint NOT NULL,
    base_row_hash text NOT NULL,
    scenario_overlay_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    observation_date date NOT NULL,
    opening_balance numeric(18,2) NOT NULL,
    deposit_amount numeric(18,2) DEFAULT 0 NOT NULL,
    withdrawal_amount numeric(18,2) DEFAULT 0 NOT NULL,
    closing_balance numeric(18,2) NOT NULL,
    available_balance numeric(18,2) NOT NULL,
    minimum_balance numeric(18,2) NOT NULL,
    nsf_count smallint DEFAULT 0 NOT NULL,
    negative_balance_flag boolean NOT NULL,
    source_contract_id bigint NOT NULL,
    generated_by_run_id bigint NOT NULL,
    row_hash text NOT NULL,
    CONSTRAINT pk_msbf_m1_merchant_deposit_daily_scenario PRIMARY KEY (scenario_row_id, observation_date),
    CONSTRAINT uq_msbf_m1_merchant_deposit_daily_scenario_1 UNIQUE (scenario_id, population_id, merchant_id, observation_date),
    CONSTRAINT ck_deposit_reconcile CHECK (abs(closing_balance-(opening_balance+deposit_amount-withdrawal_amount))<=0.01),
    CONSTRAINT ck_nsf_nonnegative CHECK (nsf_count>=0),
    CONSTRAINT fk_msbf_m1_merchant_deposit_daily_scenario_1 FOREIGN KEY (scenario_id) REFERENCES msbf_ctl.scenario_registry (scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_deposit_daily_scenario_2 FOREIGN KEY (population_id) REFERENCES msbf_m1.population_registry (population_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_deposit_daily_scenario_3 FOREIGN KEY (merchant_id) REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_deposit_daily_scenario_4 FOREIGN KEY (source_contract_id) REFERENCES msbf_ctl.source_contract (source_contract_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_deposit_daily_scenario_5 FOREIGN KEY (generated_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT
) PARTITION BY RANGE (observation_date);
COMMENT ON TABLE msbf_m1.merchant_deposit_daily_scenario IS 'Scenario-adjusted deposit/liquidity history.';
CREATE INDEX ix_msbf_m1_merchant_deposit_daily_scenario_1 ON msbf_m1.merchant_deposit_daily_scenario (scenario_id, merchant_id, observation_date);

-- ---------------------------------------------------------------------------
-- msbf_m1.verification_result
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.verification_result (
    merchant_application_id text NOT NULL,
    check_code text NOT NULL,
    check_version integer DEFAULT 1 NOT NULL,
    as_of_timestamp timestamptz NOT NULL,
    result_status text NOT NULL,
    risk_tier smallint,
    hard_stop_recommended_flag boolean DEFAULT false NOT NULL,
    evidence_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    source_snapshot_id bigint,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_msbf_m1_verification_result PRIMARY KEY (merchant_application_id, check_code, check_version, as_of_timestamp),
    CONSTRAINT ck_verification_tier CHECK (risk_tier is null or risk_tier between 1 and 5),
    CONSTRAINT fk_msbf_m1_verification_result_1 FOREIGN KEY (merchant_application_id) REFERENCES msbf_m1.merchant_application (merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_verification_result_2 FOREIGN KEY (check_code) REFERENCES msbf_ref.verification_check_code (check_code) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_verification_result_3 FOREIGN KEY (created_by_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_verification_result_4 FOREIGN KEY (source_snapshot_id, created_by_run_id) REFERENCES msbf_m1.source_snapshot (source_snapshot_id, module1_run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.verification_result IS 'Synthetic verification, KYB, identity, sanctions, bank/processor match, and fraud evidence.';

-- ---------------------------------------------------------------------------
-- msbf_m1.feature_definition
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.feature_definition (
    feature_code text NOT NULL,
    feature_version integer DEFAULT 1 NOT NULL,
    feature_name text NOT NULL,
    feature_family_code text NOT NULL,
    data_type text NOT NULL,
    unit_code text,
    observation_window_days integer,
    formula_description text NOT NULL,
    expected_direction text NOT NULL,
    valid_min_numeric numeric(24,10),
    valid_max_numeric numeric(24,10),
    owner_role text NOT NULL,
    active_flag boolean DEFAULT true NOT NULL,
    production_boundary text NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_m1_feature_definition PRIMARY KEY (feature_code, feature_version),
    CONSTRAINT fk_msbf_m1_feature_definition_1 FOREIGN KEY (feature_family_code) REFERENCES msbf_ref.feature_family (feature_family_code) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.feature_definition IS 'Versioned Module 1 feature dictionary.';

-- ---------------------------------------------------------------------------
-- msbf_m1.merchant_feature_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.merchant_feature_snapshot (
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    scenario_id bigint NOT NULL,
    as_of_date date NOT NULL,
    merchant_id text NOT NULL,
    industry_code text NOT NULL,
    partner_channel_id text,
    processor_account_id text NOT NULL,
    history_start_date date NOT NULL,
    history_end_date date NOT NULL,
    pos_history_days integer NOT NULL,
    deposit_history_days integer NOT NULL,
    source_confidence_score numeric(9,6) NOT NULL,
    data_confidence_tier text NOT NULL,
    processor_continuity_status text NOT NULL,
    verification_status text NOT NULL,
    fraud_risk_tier smallint NOT NULL,
    avg_daily_eligible_sales_7d numeric(18,2),
    avg_daily_eligible_sales_30d numeric(18,2),
    avg_daily_eligible_sales_60d numeric(18,2),
    avg_daily_eligible_sales_90d numeric(18,2),
    annualized_eligible_sales numeric(18,2),
    sales_growth_7d_vs_30d numeric(12,8),
    sales_growth_30d_vs_90d numeric(12,8),
    daily_sales_cv_30d numeric(12,8),
    daily_sales_cv_90d numeric(12,8),
    zero_sales_day_rate_30d numeric(12,8),
    seasonality_index_180d numeric(12,8),
    largest_30d_share_180d numeric(12,8),
    refund_rate_30d numeric(12,8),
    chargeback_rate_30d numeric(12,8),
    reversal_rate_30d numeric(12,8),
    deposit_to_eligible_sales_rate_30d numeric(12,8),
    negative_balance_day_rate_30d numeric(12,8),
    nsf_count_30d integer,
    average_available_balance_30d numeric(18,2),
    cash_flow_buffer_days numeric(12,4),
    existing_monthly_debt_service numeric(18,2) DEFAULT 0 NOT NULL,
    existing_daily_remittance_amount numeric(18,2) DEFAULT 0 NOT NULL,
    active_short_term_advance_count smallint DEFAULT 0 NOT NULL,
    stacking_flag boolean DEFAULT false NOT NULL,
    months_in_business integer NOT NULL,
    processor_tenure_months integer NOT NULL,
    business_bureau_score smallint,
    owner_credit_score smallint,
    prior_default_flag boolean DEFAULT false NOT NULL,
    cashflow_archetype_code text NOT NULL,
    adjusted_eligible_daily_revenue numeric(18,2) NOT NULL,
    industry_cash_flow_conversion_margin numeric(12,8) NOT NULL,
    adjusted_daily_cash_flow_available numeric(18,2) NOT NULL,
    requested_expected_daily_remittance numeric(18,2) NOT NULL,
    new_remittance_to_sales_rate numeric(12,8) NOT NULL,
    total_remittance_to_sales_rate numeric(12,8) NOT NULL,
    post_financing_coverage_ratio numeric(12,6),
    residual_daily_cash_flow numeric(18,2) NOT NULL,
    funding_to_annualized_sales_rate numeric(12,8) NOT NULL,
    feature_snapshot_hash text NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_m1_merchant_feature_snapshot PRIMARY KEY (module1_run_id, merchant_application_id),
    CONSTRAINT ck_feature_history CHECK (history_end_date<=as_of_date and history_start_date<=history_end_date),
    CONSTRAINT ck_feature_rates CHECK (source_confidence_score between 0 and 1 and fraud_risk_tier between 1 and 5 and new_remittance_to_sales_rate>=0 and total_remittance_to_sales_rate>=0 and funding_to_annualized_sales_rate>=0),
    CONSTRAINT fk_msbf_m1_merchant_feature_snapshot_1 FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_merchant_feature_snapshot_2 FOREIGN KEY (merchant_application_id) REFERENCES msbf_m1.merchant_application (merchant_application_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_feature_snapshot_3 FOREIGN KEY (population_id) REFERENCES msbf_m1.population_registry (population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_feature_snapshot_4 FOREIGN KEY (scenario_id) REFERENCES msbf_ctl.scenario_registry (scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_feature_snapshot_5 FOREIGN KEY (merchant_id) REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_feature_snapshot_6 FOREIGN KEY (industry_code) REFERENCES msbf_ref.industry (industry_code) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_feature_snapshot_7 FOREIGN KEY (partner_channel_id) REFERENCES msbf_m1.partner_channel (partner_channel_id) ON DELETE SET NULL,
    CONSTRAINT fk_msbf_m1_merchant_feature_snapshot_8 FOREIGN KEY (processor_account_id) REFERENCES msbf_m1.processor_account (processor_account_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_merchant_feature_snapshot_9 FOREIGN KEY (cashflow_archetype_code) REFERENCES msbf_ref.cashflow_archetype (archetype_code) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.merchant_feature_snapshot IS 'Wide as-of Module 1 feature contract input.';
CREATE INDEX ix_msbf_m1_merchant_feature_snapshot_1 ON msbf_m1.merchant_feature_snapshot (population_id, scenario_id, industry_code);
CREATE INDEX ix_msbf_m1_merchant_feature_snapshot_2 ON msbf_m1.merchant_feature_snapshot (merchant_id, as_of_date);

-- ---------------------------------------------------------------------------
-- msbf_m1.feature_value
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.feature_value (
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    feature_code text NOT NULL,
    feature_version integer NOT NULL,
    value_numeric numeric(24,10),
    value_text text,
    value_boolean boolean,
    value_date date,
    source_snapshot_id bigint,
    observation_start_date date,
    observation_end_date date,
    calculation_hash text NOT NULL,
    CONSTRAINT pk_msbf_m1_feature_value PRIMARY KEY (module1_run_id, merchant_application_id, feature_code, feature_version),
    CONSTRAINT ck_feature_value_one CHECK (num_nonnulls(value_numeric,value_text,value_boolean,value_date)=1),
    CONSTRAINT ck_feature_window CHECK (observation_end_date is null or observation_start_date is null or observation_end_date>=observation_start_date),
    CONSTRAINT fk_msbf_m1_feature_value_1 FOREIGN KEY (module1_run_id, merchant_application_id) REFERENCES msbf_m1.merchant_feature_snapshot (module1_run_id, merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_feature_value_2 FOREIGN KEY (feature_code, feature_version) REFERENCES msbf_m1.feature_definition (feature_code, feature_version) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_feature_value_3 FOREIGN KEY (source_snapshot_id, module1_run_id) REFERENCES msbf_m1.source_snapshot (source_snapshot_id, module1_run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.feature_value IS 'Long feature values with source and observation-window lineage.';

-- ---------------------------------------------------------------------------
-- msbf_m1.merchant_risk_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.merchant_risk_snapshot (
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    as_of_date date NOT NULL,
    base_credit_risk_points numeric(18,6) NOT NULL,
    cash_flow_risk_points numeric(18,6) NOT NULL,
    transaction_quality_points numeric(18,6) NOT NULL,
    liquidity_risk_points numeric(18,6) NOT NULL,
    obligation_risk_points numeric(18,6) NOT NULL,
    business_stability_points numeric(18,6) NOT NULL,
    business_owner_credit_points numeric(18,6) NOT NULL,
    industry_channel_points numeric(18,6) NOT NULL,
    data_confidence_points numeric(18,6) NOT NULL,
    requested_structure_points numeric(18,6) NOT NULL,
    raw_base_risk_score numeric(18,6) NOT NULL,
    base_credit_risk_proxy numeric(12,8) NOT NULL,
    requested_structure_risk_proxy numeric(12,8) NOT NULL,
    credit_risk_tier smallint NOT NULL,
    fraud_risk_tier smallint NOT NULL,
    data_confidence_tier text NOT NULL,
    operational_continuity_status text NOT NULL,
    expected_ead_amount numeric(18,2) NOT NULL,
    expected_ead_rate numeric(12,8) NOT NULL,
    lgd_input_rate numeric(12,8) NOT NULL,
    simple_expected_loss_amount numeric(18,2) NOT NULL,
    schedule_adjusted_expected_loss_amount numeric(18,2) NOT NULL,
    expected_loss_rate numeric(12,8) NOT NULL,
    risk_floor_applied_flag boolean NOT NULL,
    risk_cap_applied_flag boolean NOT NULL,
    hard_stop_recommended_flag boolean NOT NULL,
    manual_review_recommended_flag boolean NOT NULL,
    primary_reason_code text,
    risk_snapshot_hash text NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_m1_merchant_risk_snapshot PRIMARY KEY (module1_run_id, merchant_application_id),
    CONSTRAINT ck_risk_rates CHECK (base_credit_risk_proxy between 0 and 1 and requested_structure_risk_proxy between 0 and 1 and expected_ead_rate between 0 and 1 and lgd_input_rate between 0 and 1 and expected_loss_rate between 0 and 1),
    CONSTRAINT ck_risk_tiers CHECK (credit_risk_tier between 1 and 5 and fraud_risk_tier between 1 and 5),
    CONSTRAINT ck_loss_nonnegative CHECK (simple_expected_loss_amount>=0 and schedule_adjusted_expected_loss_amount>=0),
    CONSTRAINT fk_msbf_m1_merchant_risk_snapshot_1 FOREIGN KEY (module1_run_id, merchant_application_id) REFERENCES msbf_m1.merchant_feature_snapshot (module1_run_id, merchant_application_id) ON DELETE CASCADE
);
COMMENT ON TABLE msbf_m1.merchant_risk_snapshot IS 'Transparent synthetic base/requested-structure risk and comparative loss output.';
CREATE INDEX ix_msbf_m1_merchant_risk_snapshot_1 ON msbf_m1.merchant_risk_snapshot (credit_risk_tier, data_confidence_tier);
CREATE INDEX ix_msbf_m1_merchant_risk_snapshot_2 ON msbf_m1.merchant_risk_snapshot (expected_loss_rate);

-- ---------------------------------------------------------------------------
-- msbf_m1.risk_component_detail
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.risk_component_detail (
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    component_code text NOT NULL,
    component_value numeric(24,10),
    component_points numeric(18,6) NOT NULL,
    component_zone text NOT NULL,
    directional_status text NOT NULL,
    diagnostic_text text,
    calculation_hash text NOT NULL,
    CONSTRAINT pk_msbf_m1_risk_component_detail PRIMARY KEY (module1_run_id, merchant_application_id, component_code),
    CONSTRAINT fk_msbf_m1_risk_component_detail_1 FOREIGN KEY (module1_run_id, merchant_application_id) REFERENCES msbf_m1.merchant_risk_snapshot (module1_run_id, merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_risk_component_detail_2 FOREIGN KEY (component_code) REFERENCES msbf_ref.risk_component_code (component_code) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.risk_component_detail IS 'Risk component contributions and diagnostics.';

-- ---------------------------------------------------------------------------
-- msbf_m1.ead_path_snapshot
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.ead_path_snapshot (
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    path_day smallint NOT NULL,
    expected_payment_amount numeric(18,2) NOT NULL,
    expected_principal_reduction numeric(18,2) NOT NULL,
    expected_outstanding_balance numeric(18,2) NOT NULL,
    default_timing_weight numeric(12,8) NOT NULL,
    weighted_ead_amount numeric(18,2) NOT NULL,
    path_hash text NOT NULL,
    CONSTRAINT pk_msbf_m1_ead_path_snapshot PRIMARY KEY (module1_run_id, merchant_application_id, path_day),
    CONSTRAINT ck_ead_path CHECK (path_day>=0 and expected_payment_amount>=0 and expected_principal_reduction>=0 and expected_outstanding_balance>=0 and default_timing_weight between 0 and 1 and weighted_ead_amount>=0),
    CONSTRAINT fk_msbf_m1_ead_path_snapshot_1 FOREIGN KEY (module1_run_id, merchant_application_id) REFERENCES msbf_m1.merchant_risk_snapshot (module1_run_id, merchant_application_id) ON DELETE CASCADE
);
COMMENT ON TABLE msbf_m1.ead_path_snapshot IS 'Declining expected exposure path for 30/60/90-day structures.';

-- ---------------------------------------------------------------------------
-- msbf_m1.module1_latest
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.module1_latest (
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    industry_code text NOT NULL,
    partner_channel_id text,
    data_confidence_tier text NOT NULL,
    fraud_risk_tier smallint NOT NULL,
    processor_continuity_status text NOT NULL,
    cashflow_archetype_code text NOT NULL,
    adjusted_eligible_daily_revenue numeric(18,2) NOT NULL,
    requested_funding_amount numeric(18,2) NOT NULL,
    requested_remittance_rate numeric(9,6) NOT NULL,
    requested_expected_payoff_days smallint NOT NULL,
    requested_expected_daily_remittance numeric(18,2) NOT NULL,
    post_financing_coverage_ratio numeric(12,6),
    base_credit_risk_proxy numeric(12,8) NOT NULL,
    requested_structure_risk_proxy numeric(12,8) NOT NULL,
    credit_risk_tier smallint NOT NULL,
    expected_ead_amount numeric(18,2) NOT NULL,
    lgd_input_rate numeric(12,8) NOT NULL,
    schedule_adjusted_expected_loss_amount numeric(18,2) NOT NULL,
    expected_loss_rate numeric(12,8) NOT NULL,
    hard_stop_recommended_flag boolean NOT NULL,
    manual_review_recommended_flag boolean NOT NULL,
    primary_reason_code text,
    contract_code text DEFAULT 'M1_APPLICATION_RISK_SNAPSHOT' NOT NULL,
    contract_version integer DEFAULT 1 NOT NULL,
    contract_row_hash text NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_m1_module1_latest PRIMARY KEY (merchant_application_id),
    CONSTRAINT fk_msbf_m1_module1_latest_1 FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_module1_latest_2 FOREIGN KEY (merchant_application_id) REFERENCES msbf_m1.merchant_application (merchant_application_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_module1_latest_3 FOREIGN KEY (population_id) REFERENCES msbf_m1.population_registry (population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_module1_latest_4 FOREIGN KEY (scenario_id) REFERENCES msbf_ctl.scenario_registry (scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_module1_latest_5 FOREIGN KEY (merchant_id) REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_module1_latest_6 FOREIGN KEY (industry_code) REFERENCES msbf_ref.industry (industry_code) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_module1_latest_7 FOREIGN KEY (partner_channel_id) REFERENCES msbf_m1.partner_channel (partner_channel_id) ON DELETE SET NULL
);
COMMENT ON TABLE msbf_m1.module1_latest IS 'Replaceable latest accepted Module 1 output.';

-- ---------------------------------------------------------------------------
-- msbf_m1.module1_archive
-- ---------------------------------------------------------------------------
CREATE TABLE msbf_m1.module1_archive (
    archive_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    industry_code text NOT NULL,
    partner_channel_id text,
    data_confidence_tier text NOT NULL,
    fraud_risk_tier smallint NOT NULL,
    processor_continuity_status text NOT NULL,
    cashflow_archetype_code text NOT NULL,
    adjusted_eligible_daily_revenue numeric(18,2) NOT NULL,
    requested_funding_amount numeric(18,2) NOT NULL,
    requested_remittance_rate numeric(9,6) NOT NULL,
    requested_expected_payoff_days smallint NOT NULL,
    requested_expected_daily_remittance numeric(18,2) NOT NULL,
    post_financing_coverage_ratio numeric(12,6),
    base_credit_risk_proxy numeric(12,8) NOT NULL,
    requested_structure_risk_proxy numeric(12,8) NOT NULL,
    credit_risk_tier smallint NOT NULL,
    expected_ead_amount numeric(18,2) NOT NULL,
    lgd_input_rate numeric(12,8) NOT NULL,
    schedule_adjusted_expected_loss_amount numeric(18,2) NOT NULL,
    expected_loss_rate numeric(12,8) NOT NULL,
    hard_stop_recommended_flag boolean NOT NULL,
    manual_review_recommended_flag boolean NOT NULL,
    primary_reason_code text,
    contract_code text DEFAULT 'M1_APPLICATION_RISK_SNAPSHOT' NOT NULL,
    contract_version integer DEFAULT 1 NOT NULL,
    contract_row_hash text NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    archived_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_m1_module1_archive PRIMARY KEY (archive_id),
    CONSTRAINT uq_msbf_m1_module1_archive_1 UNIQUE (module1_run_id, merchant_application_id),
    CONSTRAINT fk_msbf_m1_module1_archive_1 FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry (run_id) ON DELETE CASCADE,
    CONSTRAINT fk_msbf_m1_module1_archive_2 FOREIGN KEY (merchant_application_id) REFERENCES msbf_m1.merchant_application (merchant_application_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_module1_archive_3 FOREIGN KEY (population_id) REFERENCES msbf_m1.population_registry (population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_module1_archive_4 FOREIGN KEY (scenario_id) REFERENCES msbf_ctl.scenario_registry (scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_module1_archive_5 FOREIGN KEY (merchant_id) REFERENCES msbf_m1.merchant_master (merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_module1_archive_6 FOREIGN KEY (industry_code) REFERENCES msbf_ref.industry (industry_code) ON DELETE RESTRICT,
    CONSTRAINT fk_msbf_m1_module1_archive_7 FOREIGN KEY (partner_channel_id) REFERENCES msbf_m1.partner_channel (partner_channel_id) ON DELETE SET NULL
);
COMMENT ON TABLE msbf_m1.module1_archive IS 'Immutable Module 1 application-risk archive.';
CREATE TABLE msbf_m1.merchant_pos_daily_base_default PARTITION OF msbf_m1.merchant_pos_daily_base DEFAULT;
CREATE TABLE msbf_m1.merchant_pos_daily_scenario_default PARTITION OF msbf_m1.merchant_pos_daily_scenario DEFAULT;
CREATE TABLE msbf_m1.merchant_deposit_daily_base_default PARTITION OF msbf_m1.merchant_deposit_daily_base DEFAULT;
CREATE TABLE msbf_m1.merchant_deposit_daily_scenario_default PARTITION OF msbf_m1.merchant_deposit_daily_scenario DEFAULT;

CREATE OR REPLACE FUNCTION msbf_ctl.deterministic_uniform(p_key text, p_seed text)
RETURNS numeric LANGUAGE sql IMMUTABLE STRICT AS $$
SELECT (('x' || substr(md5(p_key || '|' || p_seed),1,15))::bit(60)::bigint)::numeric / 1152921504606846976::numeric;
$$;
COMMENT ON FUNCTION msbf_ctl.deterministic_uniform(text,text) IS 'Deterministic pseudo-uniform value in [0,1); no session randomness.';

CREATE OR REPLACE FUNCTION msbf_ctl.deterministic_normal(p_key text, p_seed text)
RETURNS numeric LANGUAGE sql IMMUTABLE STRICT AS $$
SELECT sqrt(-2*ln(greatest(msbf_ctl.deterministic_uniform(p_key,p_seed||':u1'),0.000000000001))) * cos(2*pi()*msbf_ctl.deterministic_uniform(p_key,p_seed||':u2'));
$$;

CREATE OR REPLACE VIEW msbf_ctl.v_active_parameter_values AS
SELECT ps.parameter_set_id, ps.parameter_set_code, ps.parameter_set_version,
       pv.parameter_name, pv.scope_key, pv.scope_payload,
       coalesce(to_jsonb(pv.value_numeric),to_jsonb(pv.value_text),to_jsonb(pv.value_boolean),to_jsonb(pv.value_date),pv.value_json) AS resolved_value,
       pv.unit_code, pv.effective_start_date, pv.effective_end_date
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.parameter_value pv ON pv.parameter_set_id=ps.parameter_set_id
WHERE ps.status='APPROVED' AND current_date>=ps.effective_start_date
  AND (ps.effective_end_date IS NULL OR current_date<ps.effective_end_date)
  AND current_date>=pv.effective_start_date
  AND (pv.effective_end_date IS NULL OR current_date<pv.effective_end_date);

CREATE OR REPLACE VIEW msbf_m1.v_module1_application_risk_contract_v1 AS
SELECT a.module1_run_id,a.merchant_application_id,a.population_id,a.scenario_id,a.merchant_id,a.as_of_date,
       a.industry_code,a.partner_channel_id,a.data_confidence_tier,a.fraud_risk_tier,a.processor_continuity_status,
       a.cashflow_archetype_code,a.adjusted_eligible_daily_revenue,a.requested_funding_amount,a.requested_remittance_rate,
       a.requested_expected_payoff_days,a.requested_expected_daily_remittance,a.post_financing_coverage_ratio,
       a.base_credit_risk_proxy,a.requested_structure_risk_proxy,a.credit_risk_tier,a.expected_ead_amount,a.lgd_input_rate,
       a.schedule_adjusted_expected_loss_amount,a.expected_loss_rate,a.hard_stop_recommended_flag,
       a.manual_review_recommended_flag,a.primary_reason_code,a.contract_code,a.contract_version,a.contract_row_hash
FROM msbf_m1.module1_archive a;

CREATE OR REPLACE VIEW msbf_m1.v_module1_latest_accepted AS
SELECT l.*
FROM msbf_m1.module1_latest l
JOIN LATERAL (
    SELECT g.result_status
    FROM msbf_ctl.acceptance_gate_result g
    WHERE g.run_id=l.module1_run_id
      AND g.gate_id='G2_M1_CONTRACT'
    ORDER BY g.review_version DESC
    LIMIT 1
) g ON g.result_status IN ('PASS','PASS_WITH_LIMITATION');

CREATE OR REPLACE VIEW msbf_m1.v_module1_feature_lineage AS
SELECT fv.module1_run_id,fv.merchant_application_id,fv.feature_code,fv.feature_version,
       fv.source_snapshot_id,ss.source_code,ss.as_of_timestamp,ss.history_start_date,ss.history_end_date,
       fv.observation_start_date,fv.observation_end_date,fv.calculation_hash
FROM msbf_m1.feature_value fv
LEFT JOIN msbf_m1.source_snapshot ss
  ON ss.source_snapshot_id=fv.source_snapshot_id
 AND ss.module1_run_id=fv.module1_run_id;

CREATE OR REPLACE VIEW msbf_m1.v_module1_run_reconciliation AS
WITH archive_counts AS (
    SELECT module1_run_id AS run_id, count(*) AS archive_rows
    FROM msbf_m1.module1_archive
    GROUP BY module1_run_id
), latest_counts AS (
    SELECT module1_run_id AS run_id, count(*) AS latest_rows
    FROM msbf_m1.module1_latest
    GROUP BY module1_run_id
)
SELECT r.run_id,r.run_code,r.run_status,r.row_count,
       coalesce(a.archive_rows,0) AS archive_rows,
       coalesce(l.latest_rows,0) AS latest_rows,
       coalesce(a.archive_rows,0)-coalesce(r.row_count,0) AS archive_row_delta
FROM msbf_ctl.run_registry r
LEFT JOIN archive_counts a ON a.run_id=r.run_id
LEFT JOIN latest_counts l ON l.run_id=r.run_id
WHERE r.module_code='M1';

CREATE OR REPLACE FUNCTION msbf_m1.validate_module1_contract(p_run_id bigint)
RETURNS TABLE(test_code text,result_status text,observed_value text,expected_value text,finding text)
LANGUAGE plpgsql AS $$
BEGIN
 RETURN QUERY
 SELECT 'RUN_EXISTS'::text,
        CASE WHEN r.run_id IS NOT NULL THEN 'PASS' ELSE 'FAIL' END::text,
        coalesce(r.run_id::text,'MISSING'),p_run_id::text,
        CASE WHEN r.run_id IS NOT NULL THEN 'Run registry row exists.' ELSE 'Run registry row is missing.' END::text
 FROM (SELECT p_run_id AS run_id) x
 LEFT JOIN msbf_ctl.run_registry r ON r.run_id=x.run_id AND r.module_code='M1';

 RETURN QUERY
 SELECT 'ROW_COUNT'::text,
        CASE WHEN r.run_id IS NULL OR r.row_count IS NULL THEN 'FAIL'
             WHEN coalesce(a.archive_rows,0)=r.row_count THEN 'PASS' ELSE 'FAIL' END::text,
        coalesce(a.archive_rows,0)::text,coalesce(r.row_count::text,'NULL'),
        CASE WHEN r.run_id IS NULL THEN 'Run registry row is missing.'
             WHEN r.row_count IS NULL THEN 'Expected run row_count is null.'
             WHEN coalesce(a.archive_rows,0)=r.row_count THEN 'Archive row count reconciles.'
             ELSE 'Archive row count mismatch.' END::text
 FROM (SELECT p_run_id AS run_id) x
 LEFT JOIN msbf_ctl.run_registry r ON r.run_id=x.run_id AND r.module_code='M1'
 LEFT JOIN LATERAL (
     SELECT count(*) AS archive_rows
     FROM msbf_m1.module1_archive a
     WHERE a.module1_run_id=x.run_id
 ) a ON true;

 RETURN QUERY
 SELECT 'NO_FUTURE_DATA'::text,
        CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END::text,count(*)::text,'0'::text,
        'Feature windows and run-scoped source timestamps/history must not exceed application as-of date.'::text
 FROM (
     SELECT f.merchant_application_id
     FROM msbf_m1.merchant_feature_snapshot f
     WHERE f.module1_run_id=p_run_id
       AND (f.history_end_date>f.as_of_date OR f.history_start_date>f.as_of_date)
     UNION ALL
     SELECT s.merchant_application_id
     FROM msbf_m1.source_snapshot s
     JOIN msbf_m1.merchant_application a ON a.merchant_application_id=s.merchant_application_id
     WHERE s.module1_run_id=p_run_id
       AND (s.as_of_timestamp::date>a.as_of_date OR s.history_end_date>a.as_of_date)
 ) q;

 RETURN QUERY
 SELECT 'CONTRACT_IDENTITY'::text,
        CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END::text,count(*)::text,'0'::text,
        'Archive rows must use the approved Module 1 contract code/version and nonblank row hash.'::text
 FROM msbf_m1.module1_archive a
 WHERE a.module1_run_id=p_run_id
   AND (a.contract_code<>'M1_APPLICATION_RISK_SNAPSHOT' OR a.contract_version<>1 OR nullif(btrim(a.contract_row_hash),'') IS NULL);

 RETURN QUERY
 SELECT 'RISK_PROXY_ORDERING'::text,
        CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END::text,count(*)::text,'0'::text,
        'Requested-structure risk proxy must not be lower than base risk proxy beyond tolerance.'::text
 FROM msbf_m1.merchant_risk_snapshot r
 WHERE r.module1_run_id=p_run_id
   AND r.requested_structure_risk_proxy+0.00000001<r.base_credit_risk_proxy;

 RETURN QUERY
 SELECT 'EXPECTED_LOSS_IDENTITY'::text,
        CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END::text,count(*)::text,'0'::text,
        'Schedule-adjusted EL must equal requested-structure risk proxy x LGD input x expected EAD within tolerance.'::text
 FROM msbf_m1.merchant_risk_snapshot r
 WHERE r.module1_run_id=p_run_id
   AND abs(r.schedule_adjusted_expected_loss_amount-(r.requested_structure_risk_proxy*r.lgd_input_rate*r.expected_ead_amount))>0.02;

 RETURN QUERY
 SELECT 'EAD_PATH_COMPLETENESS'::text,
        CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END::text,count(*)::text,'0'::text,
        'Each risk row must have day 0 through expected payoff day in the EAD path.'::text
 FROM (
     SELECT r.merchant_application_id,a.requested_expected_payoff_days,count(e.path_day) AS path_rows
     FROM msbf_m1.merchant_risk_snapshot r
     JOIN msbf_m1.merchant_application a ON a.merchant_application_id=r.merchant_application_id
     LEFT JOIN msbf_m1.ead_path_snapshot e
       ON e.module1_run_id=r.module1_run_id
      AND e.merchant_application_id=r.merchant_application_id
     WHERE r.module1_run_id=p_run_id
     GROUP BY r.merchant_application_id,a.requested_expected_payoff_days
     HAVING count(e.path_day)<>a.requested_expected_payoff_days+1
 ) q;

 RETURN QUERY
 SELECT 'EAD_PATH_WEIGHTS'::text,
        CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END::text,count(*)::text,'0'::text,
        'Default timing weights must sum to one by application.'::text
 FROM (
     SELECT merchant_application_id
     FROM msbf_m1.ead_path_snapshot
     WHERE module1_run_id=p_run_id
     GROUP BY merchant_application_id
     HAVING abs(sum(default_timing_weight)-1)>0.000001
 ) q;

 RETURN QUERY
 SELECT 'EAD_PATH_MONOTONICITY'::text,
        CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END::text,count(*)::text,'0'::text,
        'Expected outstanding balance must be nonincreasing by path day.'::text
 FROM (
     SELECT merchant_application_id,path_day,expected_outstanding_balance,
            lag(expected_outstanding_balance) OVER (PARTITION BY merchant_application_id ORDER BY path_day) AS prior_balance
     FROM msbf_m1.ead_path_snapshot
     WHERE module1_run_id=p_run_id
 ) q
 WHERE prior_balance IS NOT NULL AND expected_outstanding_balance>prior_balance+0.01;

 RETURN QUERY
 SELECT 'EAD_AMOUNT_RECONCILIATION'::text,
        CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END::text,count(*)::text,'0'::text,
        'Risk expected EAD must reconcile to the sum of daily weighted EAD.'::text
 FROM (
     SELECT r.merchant_application_id,r.expected_ead_amount,coalesce(sum(e.weighted_ead_amount),0) AS path_ead
     FROM msbf_m1.merchant_risk_snapshot r
     LEFT JOIN msbf_m1.ead_path_snapshot e
       ON e.module1_run_id=r.module1_run_id
      AND e.merchant_application_id=r.merchant_application_id
     WHERE r.module1_run_id=p_run_id
     GROUP BY r.merchant_application_id,r.expected_ead_amount
     HAVING abs(r.expected_ead_amount-coalesce(sum(e.weighted_ead_amount),0))>0.02
 ) q;
END $$;
COMMIT;
