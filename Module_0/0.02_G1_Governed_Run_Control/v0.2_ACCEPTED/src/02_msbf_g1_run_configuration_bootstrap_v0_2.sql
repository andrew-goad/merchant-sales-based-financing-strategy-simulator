/* ============================================================================
MSBF G1 Run and Configuration Bootstrap
Version : v0.2
Purpose : Create one governed baseline run context without generating merchants,
          applications, POS history, features, risk, EAD, or loss outputs.

Key governance choice:
- G0's accepted M1_BASELINE_DEMO v1 parameter set remains unchanged.
- G1 creates M1_G1_BASELINE_DEMO v1 as a complete, versioned derivative.
- The derivative adds the four merchant-size funding/sales center values that
  are required by the parameter definition catalog but absent from the G0 seed.
============================================================================ */

BEGIN;

DO $$
DECLARE
    v_effective_date date := DATE '2026-07-23';
    v_as_of_date date := DATE '2026-07-23';
    v_run_code text := 'M1_V0_2_BASELINE_BUILD';
    v_population_id text := 'MSBF_POP_0001';

    v_base_parameter_set_id bigint;
    v_parameter_set_id bigint;
    v_product_profile_id bigint;
    v_operating_profile_id bigint;
    v_policy_profile_id bigint;
    v_strategy_profile_id bigint;
    v_scenario_set_id bigint;
    v_scenario_id bigint;
    v_jurisdiction_profile_id bigint;
    v_contract_id bigint;
    v_run_id bigint;

    v_population_size integer;
    v_history_days integer;
    v_seed_version text;
    v_history_start_date date;
    v_parameter_value_count integer;
    v_parameter_name_count integer;
    v_analytical_rows bigint;

    v_existing_run msbf_ctl.run_registry%ROWTYPE;
    v_existing_population msbf_m1.population_registry%ROWTYPE;
BEGIN
    /* ---------------------------------------------------------------------
       Confirm accepted G0 dependencies.
       ------------------------------------------------------------------ */
    SELECT parameter_set_id
      INTO STRICT v_base_parameter_set_id
      FROM msbf_ctl.parameter_set
     WHERE parameter_set_code = 'M1_BASELINE_DEMO'
       AND parameter_set_version = 1
       AND status = 'APPROVED'
       AND effective_start_date <= v_as_of_date
       AND (effective_end_date IS NULL OR effective_end_date > v_as_of_date);

    SELECT product_structure_profile_id
      INTO STRICT v_product_profile_id
      FROM msbf_ctl.product_legal_structure_profile
     WHERE profile_code = 'PDR_001'
       AND profile_version = 1
       AND status = 'APPROVED'
       AND effective_start_date <= v_as_of_date
       AND (effective_end_date IS NULL OR effective_end_date > v_as_of_date);

    SELECT operating_model_profile_id
      INTO STRICT v_operating_profile_id
      FROM msbf_ctl.operating_model_profile
     WHERE profile_code = 'DEMO_PROCESSOR_LINKED'
       AND profile_version = 1
       AND status = 'APPROVED'
       AND effective_start_date <= v_as_of_date
       AND (effective_end_date IS NULL OR effective_end_date > v_as_of_date);

    SELECT contract_id
      INTO STRICT v_contract_id
      FROM msbf_ctl.contract_registry
     WHERE contract_code = 'M1_APPLICATION_RISK_SNAPSHOT'
       AND contract_version = 1
       AND status = 'APPROVED'
       AND effective_start_date <= v_as_of_date
       AND (effective_end_date IS NULL OR effective_end_date > v_as_of_date);

    /* Complete approval metadata for the accepted demonstration profiles. */
    UPDATE msbf_ctl.product_legal_structure_profile
       SET approver_role = COALESCE(approver_role, 'Project Sponsor'),
           approval_timestamp = COALESCE(approval_timestamp, clock_timestamp()),
           last_review_date = COALESCE(last_review_date, v_effective_date),
           next_review_date = COALESCE(next_review_date, v_effective_date + 365),
           change_reason = COALESCE(change_reason, 'G1 governed configuration readiness')
     WHERE product_structure_profile_id = v_product_profile_id;

    UPDATE msbf_ctl.operating_model_profile
       SET approver_role = COALESCE(approver_role, 'Project Sponsor'),
           approval_timestamp = COALESCE(approval_timestamp, clock_timestamp()),
           last_review_date = COALESCE(last_review_date, v_effective_date),
           next_review_date = COALESCE(next_review_date, v_effective_date + 365),
           change_reason = COALESCE(change_reason, 'G1 governed configuration readiness')
     WHERE operating_model_profile_id = v_operating_profile_id;

    /* ---------------------------------------------------------------------
       Create a complete G1 parameter set without rewriting G0 evidence.
       ------------------------------------------------------------------ */
    INSERT INTO msbf_ctl.parameter_set (
        parameter_set_code,
        parameter_set_version,
        business_name,
        purpose,
        effective_start_date,
        status,
        owner_role,
        approver_role,
        approval_timestamp,
        supersedes_parameter_set_id,
        parameter_set_hash
    )
    VALUES (
        'M1_G1_BASELINE_DEMO',
        1,
        'Module 1 G1 Complete Baseline Demonstration Parameters',
        'Complete governed baseline derived from M1_BASELINE_DEMO v1; adds merchant-size funding-to-sales centers required for M1.3.',
        v_effective_date,
        'APPROVED',
        'Credit Risk/Analytics',
        'Project Sponsor',
        clock_timestamp(),
        v_base_parameter_set_id,
        'PENDING_G1_RESOLUTION'
    )
    ON CONFLICT (parameter_set_code, parameter_set_version) DO NOTHING;

    SELECT parameter_set_id
      INTO STRICT v_parameter_set_id
      FROM msbf_ctl.parameter_set
     WHERE parameter_set_code = 'M1_G1_BASELINE_DEMO'
       AND parameter_set_version = 1;

    INSERT INTO msbf_ctl.parameter_value (
        parameter_set_id,
        parameter_name,
        scope_key,
        scope_payload,
        value_numeric,
        value_text,
        value_boolean,
        value_date,
        value_json,
        unit_code,
        effective_start_date,
        effective_end_date,
        source_reference_id,
        change_reason
    )
    SELECT
        v_parameter_set_id,
        parameter_name,
        scope_key,
        scope_payload,
        value_numeric,
        value_text,
        value_boolean,
        value_date,
        value_json,
        unit_code,
        effective_start_date,
        effective_end_date,
        source_reference_id,
        'G1 controlled clone from M1_BASELINE_DEMO v1'
    FROM msbf_ctl.parameter_value
    WHERE parameter_set_id = v_base_parameter_set_id
    ON CONFLICT (parameter_set_id, parameter_name, scope_key, effective_start_date) DO NOTHING;

    INSERT INTO msbf_ctl.parameter_value (
        parameter_set_id,
        parameter_name,
        scope_key,
        scope_payload,
        value_numeric,
        unit_code,
        effective_start_date,
        change_reason
    )
    VALUES
        (v_parameter_set_id, 'funding_to_annualized_sales_center', 'MERCHANT_SIZE_TIER:MICRO',
         '{"merchant_size_tier":"MICRO"}'::jsonb, 0.0600000000, 'RATE', v_effective_date,
         'G1 configuration-completeness remediation; synthetic demonstration assumption.'),
        (v_parameter_set_id, 'funding_to_annualized_sales_center', 'MERCHANT_SIZE_TIER:SMALL',
         '{"merchant_size_tier":"SMALL"}'::jsonb, 0.0800000000, 'RATE', v_effective_date,
         'G1 configuration-completeness remediation; synthetic demonstration assumption.'),
        (v_parameter_set_id, 'funding_to_annualized_sales_center', 'MERCHANT_SIZE_TIER:LOWER_MIDDLE',
         '{"merchant_size_tier":"LOWER_MIDDLE"}'::jsonb, 0.1000000000, 'RATE', v_effective_date,
         'G1 configuration-completeness remediation; synthetic demonstration assumption.'),
        (v_parameter_set_id, 'funding_to_annualized_sales_center', 'MERCHANT_SIZE_TIER:MIDDLE',
         '{"merchant_size_tier":"MIDDLE"}'::jsonb, 0.1200000000, 'RATE', v_effective_date,
         'G1 configuration-completeness remediation; synthetic demonstration assumption.')
    ON CONFLICT (parameter_set_id, parameter_name, scope_key, effective_start_date) DO NOTHING;

    SELECT COUNT(*), COUNT(DISTINCT parameter_name)
      INTO v_parameter_value_count, v_parameter_name_count
      FROM msbf_ctl.parameter_value
     WHERE parameter_set_id = v_parameter_set_id
       AND effective_start_date <= v_as_of_date
       AND (effective_end_date IS NULL OR effective_end_date > v_as_of_date);

    IF v_parameter_value_count <> 401 OR v_parameter_name_count <> 155 THEN
        RAISE EXCEPTION 'G1 parameter set must contain 401 active scoped values across 155 parameter names; observed values=%, names=%',
            v_parameter_value_count, v_parameter_name_count;
    END IF;

    /* ---------------------------------------------------------------------
       G1 policy and strategy profiles.
       ------------------------------------------------------------------ */
    INSERT INTO msbf_ctl.policy_profile (
        profile_code, profile_version, business_name,
        effective_start_date, status, owner_role, approver_role,
        approval_timestamp, last_review_date, next_review_date, change_reason,
        policy_domain, product_structure_profile_id, operating_model_profile_id,
        parameter_set_id, profile_payload
    )
    VALUES (
        'M1_G1_BASELINE_POLICY', 1,
        'Module 1 G1 Baseline Synthetic Risk Policy',
        v_effective_date, 'APPROVED', 'Credit Risk', 'Project Sponsor',
        clock_timestamp(), v_effective_date, v_effective_date + 365,
        'Initial G1 governed baseline',
        'M1_RISK_FOUNDATION', v_product_profile_id, v_operating_profile_id,
        v_parameter_set_id,
        '{"production_use":false,"synthetic_only":true,"legal_classification_unresolved":true}'::jsonb
    )
    ON CONFLICT (profile_code, profile_version) DO NOTHING;

    SELECT policy_profile_id
      INTO STRICT v_policy_profile_id
      FROM msbf_ctl.policy_profile
     WHERE profile_code = 'M1_G1_BASELINE_POLICY'
       AND profile_version = 1;

    INSERT INTO msbf_ctl.strategy_profile (
        profile_code, profile_version, business_name,
        effective_start_date, status, owner_role, approver_role,
        approval_timestamp, last_review_date, next_review_date, change_reason,
        strategy_domain, policy_profile_id, objective_code, strategy_payload
    )
    VALUES (
        'M1_G1_BASELINE_STRATEGY', 1,
        'Module 1 G1 Baseline Reference Strategy',
        v_effective_date, 'APPROVED', 'Credit Strategy', 'Project Sponsor',
        clock_timestamp(), v_effective_date, v_effective_date + 365,
        'Initial G1 governed baseline',
        'M1_RISK_FOUNDATION', v_policy_profile_id, 'BASELINE_REFERENCE',
        '{"objective":"controlled synthetic reference","growth_optimization":false,"production_use":false}'::jsonb
    )
    ON CONFLICT (profile_code, profile_version) DO NOTHING;

    SELECT strategy_profile_id
      INTO STRICT v_strategy_profile_id
      FROM msbf_ctl.strategy_profile
     WHERE profile_code = 'M1_G1_BASELINE_STRATEGY'
       AND profile_version = 1;

    /* ---------------------------------------------------------------------
       Cross-cutting governance profiles.
       ------------------------------------------------------------------ */
    INSERT INTO msbf_ctl.jurisdiction_profile (
        profile_code, profile_version, business_name,
        effective_start_date, status, owner_role, approver_role,
        approval_timestamp, last_review_date, next_review_date, change_reason,
        jurisdiction_code, country_code, profile_payload
    )
    VALUES (
        'DEMO_US_PUBLIC_SIM', 1,
        'United States Public Demonstration Jurisdiction Profile',
        v_effective_date, 'APPROVED', 'Legal/Compliance', 'Project Sponsor',
        clock_timestamp(), v_effective_date, v_effective_date + 180,
        'Configuration-aware demonstration profile; no legal conclusion.',
        'US_DEMO', 'US',
        '{"production_use":false,"state_applicability_unresolved":true,"legal_advice":false,"fail_closed_for_real_transactions":true}'::jsonb
    )
    ON CONFLICT (profile_code, profile_version) DO NOTHING;

    SELECT jurisdiction_profile_id
      INTO STRICT v_jurisdiction_profile_id
      FROM msbf_ctl.jurisdiction_profile
     WHERE profile_code = 'DEMO_US_PUBLIC_SIM'
       AND profile_version = 1;

    INSERT INTO msbf_ctl.data_segregation_profile (
        profile_code, profile_version, business_name,
        effective_start_date, status, owner_role, approver_role,
        approval_timestamp, last_review_date, next_review_date, change_reason,
        data_domain, restricted_flag, permitted_roles, prohibited_uses, profile_payload
    )
    VALUES (
        'DEMO_SYNTHETIC_DATA_ONLY', 1,
        'Synthetic Public Demonstration Data Segregation',
        v_effective_date, 'APPROVED', 'Information Security', 'Project Sponsor',
        clock_timestamp(), v_effective_date, v_effective_date + 365,
        'Initial G1 data-boundary profile',
        'MSBF_PUBLIC_SIMULATION', false,
        ARRAY['PROJECT_ANALYTICS','VALIDATION','REVIEWER'],
        ARRAY['REAL_MERCHANT_PII','REAL_CARDHOLDER_DATA','PRODUCTION_DECISIONING','REGULATORY_CERTIFICATION'],
        '{"synthetic_only":true,"public_repository_compatible":true}'::jsonb
    )
    ON CONFLICT (profile_code, profile_version) DO NOTHING;

    INSERT INTO msbf_ctl.record_retention_profile (
        profile_code, profile_version, business_name,
        effective_start_date, status, owner_role, approver_role,
        approval_timestamp, last_review_date, next_review_date, change_reason,
        record_domain, retention_period_months, legal_hold_supported_flag, profile_payload
    )
    VALUES (
        'DEMO_PROJECT_EVIDENCE_60M', 1,
        'Demonstration Project Evidence Retention',
        v_effective_date, 'APPROVED', 'Records Governance', 'Project Sponsor',
        clock_timestamp(), v_effective_date, v_effective_date + 365,
        'Synthetic project-governance assumption; not a legal retention conclusion.',
        'PROJECT_EVIDENCE', 60, true,
        '{"production_rule":false,"legal_review_required_for_real_use":true}'::jsonb
    )
    ON CONFLICT (profile_code, profile_version) DO NOTHING;

    INSERT INTO msbf_ctl.financial_crime_profile (
        profile_code, profile_version, business_name,
        effective_start_date, status, owner_role, approver_role,
        approval_timestamp, last_review_date, next_review_date, change_reason,
        operating_model_profile_id, kyb_owner_role, beneficial_owner_owner_role,
        sanctions_owner_role, aml_monitoring_owner_role, profile_payload
    )
    VALUES (
        'DEMO_FINCRIME_RESPONSIBILITY', 1,
        'Synthetic Financial-Crime Responsibility Profile',
        v_effective_date, 'APPROVED', 'Financial Crime Compliance', 'Project Sponsor',
        clock_timestamp(), v_effective_date, v_effective_date + 180,
        'Responsibility mapping only; no real KYC/AML conclusion.',
        v_operating_profile_id,
        'DEMO_KYB_CONTROL_OWNER', 'DEMO_BENEFICIAL_OWNER_CONTROL_OWNER',
        'DEMO_SANCTIONS_CONTROL_OWNER', 'DEMO_AML_MONITORING_CONTROL_OWNER',
        '{"synthetic_only":true,"real_customer_screening":false,"production_certification":false}'::jsonb
    )
    ON CONFLICT (profile_code, profile_version) DO NOTHING;

    INSERT INTO msbf_ctl.payment_data_scope_profile (
        profile_code, profile_version, business_name,
        effective_start_date, status, owner_role, approver_role,
        approval_timestamp, last_review_date, next_review_date, change_reason,
        stores_payment_account_data_flag, processes_payment_account_data_flag,
        transmits_payment_account_data_flag, can_affect_security_flag,
        scope_status, profile_payload
    )
    VALUES (
        'DEMO_NO_PAYMENT_ACCOUNT_DATA', 1,
        'Public Simulation Payment-Data Scope',
        v_effective_date, 'APPROVED', 'Information Security', 'Project Sponsor',
        clock_timestamp(), v_effective_date, v_effective_date + 365,
        'Public simulator excludes real payment account data.',
        false, false, false, false,
        'OUT_OF_SCOPE_PUBLIC_SIMULATION',
        '{"aggregated_synthetic_pos_only":true,"real_pan_or_sensitive_authentication_data":false}'::jsonb
    )
    ON CONFLICT (profile_code, profile_version) DO NOTHING;

    INSERT INTO msbf_ctl.third_party_relationship_profile (
        profile_code, profile_version, business_name,
        effective_start_date, status, owner_role, approver_role,
        approval_timestamp, last_review_date, next_review_date, change_reason,
        operating_model_profile_id, provider_code, service_code,
        accountable_owner_role, due_diligence_status, monitoring_status,
        continuity_plan_status, exit_plan_status, incident_status,
        subcontractor_flag, profile_payload
    )
    VALUES (
        'DEMO_PROCESSOR_RELATIONSHIP', 1,
        'Synthetic POS Processor Relationship',
        v_effective_date, 'APPROVED', 'Third-Party Risk', 'Project Sponsor',
        clock_timestamp(), v_effective_date, v_effective_date + 180,
        'Synthetic relationship used only to prove governed role resolution.',
        v_operating_profile_id, 'SYNTHETIC_PROCESSOR', 'POS_DATA_AND_SPLIT_REMITTANCE',
        'DEMO_THIRD_PARTY_OWNER', 'SIMULATED_COMPLETE', 'SIMULATED_ACTIVE',
        'DOCUMENTED', 'DOCUMENTED', 'NONE', false,
        '{"real_provider":false,"production_due_diligence":false}'::jsonb
    )
    ON CONFLICT (profile_code, profile_version) DO NOTHING;

    /* ---------------------------------------------------------------------
       Risk-appetite controls used by Module 1 QA and future G2 acceptance.
       ------------------------------------------------------------------ */
    INSERT INTO msbf_ctl.risk_appetite_limit (
        limit_code, limit_version, policy_profile_id, metric_code,
        scope_key, scope_payload, target_min_value, target_max_value,
        early_warning_value, hard_limit_value, breach_direction,
        required_action, owner_role, review_cadence,
        effective_start_date, status
    )
    VALUES
        ('M1_MAX_RISK_CAP_SHARE', 1, v_policy_profile_id, 'RISK_CAP_SHARE',
         'PORTFOLIO', '{}'::jsonb, NULL, 0.1000000000, 0.1200000000, 0.1500000000, 'ABOVE',
         'Review risk mapping and upper-tail compression before acceptance.', 'Credit Risk', 'EACH_RUN', v_effective_date, 'APPROVED'),
        ('M1_MAX_SOURCE_CONFLICT_SHARE', 1, v_policy_profile_id, 'SOURCE_CONFLICT_SHARE',
         'PORTFOLIO', '{}'::jsonb, NULL, 0.0750000000, 0.0900000000, 0.1000000000, 'ABOVE',
         'Review source generation, reconciliation, and confidence treatment.', 'Data Risk', 'EACH_RUN', v_effective_date, 'APPROVED'),
        ('M1_MIN_MIXED_SIGNAL_SHARE', 1, v_policy_profile_id, 'MIXED_SIGNAL_SHARE',
         'PORTFOLIO', '{}'::jsonb, 0.0200000000, NULL, 0.0150000000, 0.0100000000, 'BELOW',
         'Review synthetic correlation design for excessive determinism.', 'Model Development', 'EACH_RUN', v_effective_date, 'APPROVED'),
        ('M1_MIN_MATCHED_SCENARIO_SHARE', 1, v_policy_profile_id, 'SCENARIO_MATCHED_SHARE',
         'PORTFOLIO', '{}'::jsonb, 1.0000000000, NULL, 0.9990000000, 1.0000000000, 'BELOW',
         'Do not accept scenario evidence until all intended applications match.', 'Validation', 'EACH_SCENARIO_SET', v_effective_date, 'APPROVED')
    ON CONFLICT (limit_code, limit_version, scope_key) DO NOTHING;

    /* ---------------------------------------------------------------------
       Baseline and stress comparison family.
       ------------------------------------------------------------------ */
    INSERT INTO msbf_ctl.scenario_set (
        scenario_set_code, scenario_set_version, business_name,
        purpose, status, owner_role
    )
    VALUES (
        'M1_V0_2_BASELINE_AND_STRESS', 1,
        'Module 1 v0.2 Baseline and Stress Comparison Family',
        'Matched baseline and controlled recession/energy sensitivity using one deterministic population.',
        'APPROVED', 'Portfolio Stress'
    )
    ON CONFLICT (scenario_set_code, scenario_set_version) DO NOTHING;

    SELECT scenario_set_id
      INTO STRICT v_scenario_set_id
      FROM msbf_ctl.scenario_set
     WHERE scenario_set_code = 'M1_V0_2_BASELINE_AND_STRESS'
       AND scenario_set_version = 1;

    INSERT INTO msbf_ctl.scenario_registry (
        scenario_set_id, scenario_code, scenario_version, scenario_name,
        scenario_type, effective_start_date, status, owner_role,
        parameter_set_id, assumption_payload, interpretation_boundary
    )
    VALUES
        (v_scenario_set_id, 'BASELINE', 1, 'Baseline Merchant Environment',
         'BASELINE', v_effective_date, 'APPROVED', 'Portfolio Stress',
         v_parameter_set_id, '{}'::jsonb,
         'Controlled synthetic reference; not a forecast.'),
        (v_scenario_set_id, 'RECESSION_ENERGY', 1,
         'Recession with Energy and Dependent-Industry Stress',
         'STRESS', v_effective_date, 'APPROVED', 'Portfolio Stress',
         v_parameter_set_id,
         '{"direct_and_indirect_shocks":true,"implementation_stage":"M1.6"}'::jsonb,
         'Controlled sensitivity; not an economic forecast.')
    ON CONFLICT (scenario_set_id, scenario_code, scenario_version) DO NOTHING;

    SELECT scenario_id
      INTO STRICT v_scenario_id
      FROM msbf_ctl.scenario_registry
     WHERE scenario_set_id = v_scenario_set_id
       AND scenario_code = 'BASELINE'
       AND scenario_version = 1;

    /* ---------------------------------------------------------------------
       Read population controls from the G1 parameter set.
       ------------------------------------------------------------------ */
    SELECT value_numeric::integer
      INTO STRICT v_population_size
      FROM msbf_ctl.parameter_value
     WHERE parameter_set_id = v_parameter_set_id
       AND parameter_name = 'population_size'
       AND scope_key = 'GLOBAL'
       AND effective_start_date <= v_as_of_date
       AND (effective_end_date IS NULL OR effective_end_date > v_as_of_date);

    SELECT value_numeric::integer
      INTO STRICT v_history_days
      FROM msbf_ctl.parameter_value
     WHERE parameter_set_id = v_parameter_set_id
       AND parameter_name = 'history_days'
       AND scope_key = 'GLOBAL'
       AND effective_start_date <= v_as_of_date
       AND (effective_end_date IS NULL OR effective_end_date > v_as_of_date);

    SELECT value_text
      INTO STRICT v_seed_version
      FROM msbf_ctl.parameter_value
     WHERE parameter_set_id = v_parameter_set_id
       AND parameter_name = 'deterministic_seed_version'
       AND scope_key = 'GLOBAL'
       AND effective_start_date <= v_as_of_date
       AND (effective_end_date IS NULL OR effective_end_date > v_as_of_date);

    v_history_start_date := v_as_of_date - (v_history_days - 1);

    /* ---------------------------------------------------------------------
       Create the baseline run and deterministic population identity.
       ------------------------------------------------------------------ */
    INSERT INTO msbf_ctl.run_registry (
        run_code, run_version, module_code, run_type,
        population_id, scenario_id, parameter_set_id, policy_profile_id,
        strategy_profile_id, product_structure_profile_id,
        operating_model_profile_id, jurisdiction_profile_id, contract_id,
        as_of_date, run_status, row_count, code_version, notes
    )
    VALUES (
        v_run_code, 1, 'M1', 'BASELINE_CONFIGURATION',
        v_population_id, v_scenario_id, v_parameter_set_id, v_policy_profile_id,
        v_strategy_profile_id, v_product_profile_id,
        v_operating_profile_id, v_jurisdiction_profile_id, v_contract_id,
        v_as_of_date, 'READY_FOR_G1_VALIDATION', 0,
        'MSBF_M1_V0_2_G1',
        'G1 governed baseline configuration. Analytical generation is not authorized until G1 acceptance.'
    )
    ON CONFLICT (run_code, run_version) DO NOTHING;

    SELECT *
      INTO STRICT v_existing_run
      FROM msbf_ctl.run_registry
     WHERE run_code = v_run_code
       AND run_version = 1;

    v_run_id := v_existing_run.run_id;

    IF v_existing_run.module_code IS DISTINCT FROM 'M1'
       OR v_existing_run.population_id IS DISTINCT FROM v_population_id
       OR v_existing_run.scenario_id IS DISTINCT FROM v_scenario_id
       OR v_existing_run.parameter_set_id IS DISTINCT FROM v_parameter_set_id
       OR v_existing_run.policy_profile_id IS DISTINCT FROM v_policy_profile_id
       OR v_existing_run.strategy_profile_id IS DISTINCT FROM v_strategy_profile_id
       OR v_existing_run.product_structure_profile_id IS DISTINCT FROM v_product_profile_id
       OR v_existing_run.operating_model_profile_id IS DISTINCT FROM v_operating_profile_id
       OR v_existing_run.jurisdiction_profile_id IS DISTINCT FROM v_jurisdiction_profile_id
       OR v_existing_run.contract_id IS DISTINCT FROM v_contract_id
       OR v_existing_run.as_of_date IS DISTINCT FROM v_as_of_date THEN
        RAISE EXCEPTION 'Existing run % version 1 conflicts with the governed G1 baseline configuration.', v_run_code;
    END IF;

    IF v_existing_run.run_status = 'G1_READY' THEN
        RAISE EXCEPTION 'Run % is already G1_READY; snapshots are frozen. Use validation reports rather than rebuilding.', v_run_code;
    END IF;

    INSERT INTO msbf_m1.population_registry (
        population_id, population_version, parameter_set_id,
        deterministic_seed_version, merchant_count,
        history_start_date, history_end_date, population_status,
        population_hash, created_by_run_id
    )
    VALUES (
        v_population_id, 1, v_parameter_set_id,
        v_seed_version, v_population_size,
        v_history_start_date, v_as_of_date,
        'PLANNED_G1', NULL, v_run_id
    )
    ON CONFLICT (population_id) DO NOTHING;

    SELECT *
      INTO STRICT v_existing_population
      FROM msbf_m1.population_registry
     WHERE population_id = v_population_id;

    IF v_existing_population.parameter_set_id IS DISTINCT FROM v_parameter_set_id
       OR v_existing_population.deterministic_seed_version IS DISTINCT FROM v_seed_version
       OR v_existing_population.merchant_count IS DISTINCT FROM v_population_size
       OR v_existing_population.history_start_date IS DISTINCT FROM v_history_start_date
       OR v_existing_population.history_end_date IS DISTINCT FROM v_as_of_date THEN
        RAISE EXCEPTION 'Existing population % conflicts with the governed G1 baseline population definition.', v_population_id;
    END IF;

    SELECT
          (SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE created_by_run_id = v_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id = v_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id = v_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id = v_run_id)
    INTO v_analytical_rows;

    IF v_analytical_rows <> 0 THEN
        RAISE EXCEPTION 'G1 bootstrap requires an empty analytical run; observed % rows for run_id %', v_analytical_rows, v_run_id;
    END IF;
END
$$;

COMMIT;

SELECT
    r.run_id,
    r.run_code,
    r.run_version,
    r.run_status,
    r.population_id,
    r.as_of_date,
    ps.parameter_set_code,
    ps.parameter_set_version,
    p.merchant_count AS planned_merchant_count,
    p.history_start_date,
    p.history_end_date,
    s.scenario_code,
    c.contract_code,
    c.contract_version
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.parameter_set ps ON ps.parameter_set_id = r.parameter_set_id
JOIN msbf_m1.population_registry p ON p.population_id = r.population_id
LEFT JOIN msbf_ctl.scenario_registry s ON s.scenario_id = r.scenario_id
LEFT JOIN msbf_ctl.contract_registry c ON c.contract_id = r.contract_id
WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND r.run_version = 1;
