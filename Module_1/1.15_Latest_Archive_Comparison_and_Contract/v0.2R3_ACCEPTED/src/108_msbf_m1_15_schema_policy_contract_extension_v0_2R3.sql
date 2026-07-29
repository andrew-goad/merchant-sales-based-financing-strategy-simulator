/* ============================================================================
MSBF M1.15 Latest Output, Archive, Comparison & Consumption Contract
Program : 108_msbf_m1_15_schema_policy_contract_extension_v0_2R3.sql
Version : v0.2R3
Purpose : Register the M1.15 gate and policy, create the governed Module 1
          consumption contract, immutable archive, matched comparison, contract
          registry, lineage views, hashing functions, and readiness guard.
Inputs  : Accepted G0-M1.14 database state.
Outputs : Metadata and schema only; no M1.15 contract rows are generated.
Boundary: Consumption and lineage only. No pricing, approval, counteroffer,
          decline, adverse-action, or portfolio-allocation decisions.
Safety  : Idempotent DDL and metadata upserts inside one transaction.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='5min';

/* ---------------------------------------------------------------------------
1. Acceptance gate and governed policy
--------------------------------------------------------------------------- */
INSERT INTO msbf_ref.acceptance_gate_catalog(
    gate_id,gate_name,module_code,severity,description
)
VALUES(
    'M1_15_CONSUMPTION_CONTRACT',
    'M1.15 Latest Output, Archive, Comparison and Consumption Contract',
    'M1','BLOCKING',
    'Scenario-aware latest output, immutable archive, matched comparison, contract registry, lineage, and downstream-consumption acceptance.'
)
ON CONFLICT(gate_id) DO UPDATE SET
    gate_name=EXCLUDED.gate_name,
    module_code=EXCLUDED.module_code,
    severity=EXCLUDED.severity,
    active_flag=true,
    description=EXCLUDED.description;

INSERT INTO msbf_ctl.policy_profile(
    profile_code,profile_version,business_name,effective_start_date,status,
    owner_role,approver_role,approval_timestamp,last_review_date,next_review_date,
    change_reason,policy_domain,parameter_set_id,profile_payload
)
SELECT
    'M1_15_CONSUMPTION_CONTRACT',1,
    'M1.15 Latest Output, Archive, Comparison and Consumption Contract',
    r.as_of_date,'APPROVED',
    'Enterprise Data / Credit Risk / Finance',
    'Independent Validation',clock_timestamp(),r.as_of_date,r.as_of_date+365,
    'Initial governed Module 1 consumption-contract implementation.',
    'MODULE1_CONSUMPTION_CONTRACT',r.parameter_set_id,
    jsonb_build_object(
        'methodology_version','M1_15_METHOD_V1',
        'contract_code','M1_APPLICATION_CONSUMPTION',
        'contract_version',1,
        'schema_version','M1_CONTRACT_SCHEMA_V1',
        'latest_expected_rows',1500,
        'archive_expected_rows',1500,
        'comparison_expected_rows',750,
        'archive_immutable',true,
        'matched_scenario_required',true,
        'baseline_scenario_code','BASELINE',
        'stress_scenario_code','RECESSION_ENERGY',
        'power_bi_contract_enabled',true,
        'production_boundary','Synthetic governed consumption contract; not strategy decisioning.'
    )
FROM msbf_ctl.run_registry r
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
ON CONFLICT(profile_code,profile_version) DO UPDATE SET
    business_name=EXCLUDED.business_name,
    effective_start_date=EXCLUDED.effective_start_date,
    status='APPROVED',
    owner_role=EXCLUDED.owner_role,
    approver_role=EXCLUDED.approver_role,
    approval_timestamp=EXCLUDED.approval_timestamp,
    last_review_date=EXCLUDED.last_review_date,
    next_review_date=EXCLUDED.next_review_date,
    change_reason=EXCLUDED.change_reason,
    policy_domain=EXCLUDED.policy_domain,
    parameter_set_id=EXCLUDED.parameter_set_id,
    profile_payload=EXCLUDED.profile_payload;

/* ---------------------------------------------------------------------------
2. Contract registry
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_ctl.m1_15_consumption_contract_registry(
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    module1_run_id bigint NOT NULL,
    schema_version text NOT NULL,
    scenario_set_id bigint NOT NULL,
    contract_status text NOT NULL,
    latest_row_count integer NOT NULL,
    archive_row_count integer NOT NULL,
    comparison_row_count integer NOT NULL,
    latest_set_hash text NOT NULL,
    archive_set_hash text NOT NULL,
    comparison_set_hash text NOT NULL,
    contract_set_hash text NOT NULL,
    combined_set_hash text NOT NULL,
    contract_row_hash text NOT NULL,
    generated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    validated_at timestamptz,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_m1_15_contract_registry
        PRIMARY KEY(contract_code,contract_version,module1_run_id),
    CONSTRAINT ck_m1_15_contract_status
        CHECK(contract_status IN ('GENERATED','VALIDATED','ACCEPTED','RETIRED')),
    CONSTRAINT ck_m1_15_contract_counts
        CHECK(latest_row_count>=0 AND archive_row_count>=0 AND comparison_row_count>=0),
    CONSTRAINT ck_m1_15_contract_run_lineage
        CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_m1_15_contract_run FOREIGN KEY(module1_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_15_contract_created_run FOREIGN KEY(created_by_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_15_contract_scenario_set FOREIGN KEY(scenario_set_id)
        REFERENCES msbf_ctl.scenario_set(scenario_set_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_ctl.m1_15_consumption_contract_registry IS
'Governed M1.15 contract identity, version, lifecycle, cardinalities, and canonical hashes.';

/* ---------------------------------------------------------------------------
3. Scenario-aware latest contract
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_m1.application_module1_latest(
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    scenario_code text NOT NULL,
    industry_code text NOT NULL,
    merchant_size_tier text NOT NULL,
    relationship_stage text NOT NULL,
    partner_channel_id text,
    channel_type text NOT NULL,

    source_confidence_score numeric(9,6) NOT NULL,
    data_confidence_tier text NOT NULL,
    verification_disposition text NOT NULL,
    fraud_risk_tier smallint NOT NULL,
    processor_continuity_status text NOT NULL,
    feature_completeness_status text NOT NULL,
    avg_daily_eligible_sales_30d numeric(18,2),
    annualized_eligible_sales numeric(18,2),
    average_available_balance_30d numeric(18,2),
    negative_balance_day_rate_30d numeric(12,8),
    nsf_count_30d integer,

    capacity_tier smallint NOT NULL,
    capacity_evidence_status text NOT NULL,
    affordability_status text NOT NULL,
    sales_linked_payment_coverage_ratio numeric(12,6),
    residual_daily_operating_cash_flow numeric(18,2),
    post_financing_liquidity_buffer_amount numeric(18,2),

    archetype_code text NOT NULL,
    operating_resilience_score numeric(12,6),
    resilience_tier smallint NOT NULL,
    resilience_status text NOT NULL,
    operating_resilience_evidence_status text NOT NULL,

    integrated_risk_score numeric(12,6),
    synthetic_merchant_risk_proxy numeric(12,8),
    integrated_risk_tier smallint NOT NULL,
    integrated_risk_status text NOT NULL,
    integrated_risk_evidence_status text NOT NULL,

    path_weighted_ead_amount numeric(18,2) NOT NULL,
    expected_ead_rate numeric(12,8) NOT NULL,
    recovery_rate_assumption numeric(12,8) NOT NULL,
    lgd_input_rate numeric(12,8) NOT NULL,
    schedule_adjusted_comparative_expected_loss_amount numeric(18,2),
    schedule_adjusted_comparative_loss_rate numeric(12,8),
    loss_evidence_status text NOT NULL,

    gross_finance_revenue_amount numeric(18,2) NOT NULL,
    total_non_loss_cost_amount numeric(18,2) NOT NULL,
    risk_adjusted_contribution_amount numeric(18,2),
    annualized_risk_adjusted_return_rate numeric(12,8),
    economic_surplus_amount numeric(18,2),
    economic_tier smallint NOT NULL,
    economic_status text NOT NULL,
    unit_economics_evidence_status text NOT NULL,

    hard_stop_recommended_flag boolean NOT NULL,
    manual_review_recommended_flag boolean NOT NULL,
    contract_evidence_status text NOT NULL,
    fallback_path_code text NOT NULL,
    primary_contract_reason_code text NOT NULL,
    secondary_contract_reason_codes text[] NOT NULL DEFAULT '{}'::text[],

    m1_8_row_hash text NOT NULL,
    m1_9_row_hash text NOT NULL,
    m1_10_row_hash text NOT NULL,
    m1_11_row_hash text NOT NULL,
    m1_12_row_hash text NOT NULL,
    m1_13_row_hash text NOT NULL,
    m1_14_row_hash text NOT NULL,
    source_payload jsonb NOT NULL,
    lineage_payload jsonb NOT NULL,

    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    contract_row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT pk_m1_15_latest
        PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m1_15_latest_confidence
        CHECK(source_confidence_score BETWEEN 0 AND 1),
    CONSTRAINT ck_m1_15_latest_tiers
        CHECK(fraud_risk_tier BETWEEN 1 AND 5
          AND capacity_tier BETWEEN 1 AND 5
          AND resilience_tier BETWEEN 1 AND 5
          AND integrated_risk_tier BETWEEN 1 AND 5
          AND economic_tier BETWEEN 1 AND 5),
    CONSTRAINT ck_m1_15_latest_evidence
        CHECK(contract_evidence_status IN ('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_m1_15_latest_run_lineage
        CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_m1_15_latest_run FOREIGN KEY(module1_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_15_latest_scenario FOREIGN KEY(scenario_id)
        REFERENCES msbf_ctl.scenario_registry(scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_15_latest_application FOREIGN KEY(merchant_application_id)
        REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_15_latest_population FOREIGN KEY(population_id)
        REFERENCES msbf_m1.population_registry(population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_15_latest_merchant FOREIGN KEY(merchant_id)
        REFERENCES msbf_m1.merchant_master(merchant_id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS ix_m1_15_latest_scenario
    ON msbf_m1.application_module1_latest(module1_run_id,scenario_code,merchant_application_id);
CREATE INDEX IF NOT EXISTS ix_m1_15_latest_risk_economics
    ON msbf_m1.application_module1_latest(module1_run_id,integrated_risk_tier,economic_tier);
CREATE INDEX IF NOT EXISTS ix_m1_15_latest_review
    ON msbf_m1.application_module1_latest(module1_run_id,hard_stop_recommended_flag,manual_review_recommended_flag);

/* ---------------------------------------------------------------------------
4. Immutable archive
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_m1.application_module1_archive(
    archive_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    contract_row_hash text NOT NULL,
    contract_payload jsonb NOT NULL,
    archived_by_run_id bigint NOT NULL,
    archived_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_m1_15_archive
        UNIQUE(module1_run_id,contract_code,contract_version,scenario_id,merchant_application_id),
    CONSTRAINT ck_m1_15_archive_run_lineage
        CHECK(archived_by_run_id=module1_run_id),
    CONSTRAINT fk_m1_15_archive_run FOREIGN KEY(module1_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_15_archive_scenario FOREIGN KEY(scenario_id)
        REFERENCES msbf_ctl.scenario_registry(scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_15_archive_application FOREIGN KEY(merchant_application_id)
        REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS ix_m1_15_archive_contract
    ON msbf_m1.application_module1_archive(module1_run_id,contract_version,scenario_id);

CREATE OR REPLACE FUNCTION msbf_m1.m1_15_reject_archive_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'M1.15 archive is immutable: % is not permitted on %.%',
        TG_OP,TG_TABLE_SCHEMA,TG_TABLE_NAME;
END;
$$;

DROP TRIGGER IF EXISTS trg_m1_15_archive_immutable
ON msbf_m1.application_module1_archive;
CREATE TRIGGER trg_m1_15_archive_immutable
BEFORE UPDATE OR DELETE ON msbf_m1.application_module1_archive
FOR EACH ROW EXECUTE FUNCTION msbf_m1.m1_15_reject_archive_mutation();

/* ---------------------------------------------------------------------------
5. Matched scenario comparison
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_m1.application_module1_scenario_comparison(
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    baseline_scenario_id bigint NOT NULL,
    stress_scenario_id bigint NOT NULL,

    baseline_source_confidence_score numeric(9,6) NOT NULL,
    stress_source_confidence_score numeric(9,6) NOT NULL,
    source_confidence_delta numeric(12,8) NOT NULL,

    baseline_avg_daily_eligible_sales_30d numeric(18,2),
    stress_avg_daily_eligible_sales_30d numeric(18,2),
    sales_delta_amount numeric(18,2),

    baseline_average_available_balance_30d numeric(18,2),
    stress_average_available_balance_30d numeric(18,2),
    available_balance_delta_amount numeric(18,2),

    baseline_capacity_tier smallint NOT NULL,
    stress_capacity_tier smallint NOT NULL,
    capacity_tier_delta smallint NOT NULL,

    baseline_operating_resilience_score numeric(12,6),
    stress_operating_resilience_score numeric(12,6),
    resilience_score_delta numeric(12,6),
    baseline_resilience_tier smallint NOT NULL,
    stress_resilience_tier smallint NOT NULL,
    resilience_tier_delta smallint NOT NULL,

    baseline_integrated_risk_score numeric(12,6),
    stress_integrated_risk_score numeric(12,6),
    integrated_risk_score_delta numeric(12,6),
    baseline_integrated_risk_tier smallint NOT NULL,
    stress_integrated_risk_tier smallint NOT NULL,
    integrated_risk_tier_delta smallint NOT NULL,

    baseline_path_weighted_ead_amount numeric(18,2) NOT NULL,
    stress_path_weighted_ead_amount numeric(18,2) NOT NULL,
    path_weighted_ead_delta_amount numeric(18,2) NOT NULL,

    baseline_lgd_input_rate numeric(12,8) NOT NULL,
    stress_lgd_input_rate numeric(12,8) NOT NULL,
    lgd_delta_rate numeric(12,8) NOT NULL,

    baseline_comparative_loss_amount numeric(18,2),
    stress_comparative_loss_amount numeric(18,2),
    comparative_loss_delta_amount numeric(18,2),

    baseline_risk_adjusted_contribution_amount numeric(18,2),
    stress_risk_adjusted_contribution_amount numeric(18,2),
    risk_adjusted_contribution_delta_amount numeric(18,2),

    baseline_annualized_return_rate numeric(12,8),
    stress_annualized_return_rate numeric(12,8),
    annualized_return_delta_rate numeric(12,8),

    baseline_economic_tier smallint NOT NULL,
    stress_economic_tier smallint NOT NULL,
    economic_tier_delta smallint NOT NULL,

    capacity_worsening_flag boolean NOT NULL,
    resilience_worsening_flag boolean NOT NULL,
    integrated_risk_worsening_flag boolean NOT NULL,
    comparative_loss_worsening_flag boolean NOT NULL,
    economic_worsening_flag boolean NOT NULL,
    manual_review_escalation_flag boolean NOT NULL,
    hard_stop_escalation_flag boolean NOT NULL,

    comparison_evidence_status text NOT NULL,
    baseline_contract_row_hash text NOT NULL,
    stress_contract_row_hash text NOT NULL,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    comparison_row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT pk_m1_15_comparison
        PRIMARY KEY(module1_run_id,merchant_application_id),
    CONSTRAINT ck_m1_15_comparison_status
        CHECK(comparison_evidence_status IN ('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_m1_15_comparison_run_lineage
        CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_m1_15_comparison_run FOREIGN KEY(module1_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_15_comparison_application FOREIGN KEY(merchant_application_id)
        REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_15_comparison_baseline FOREIGN KEY(baseline_scenario_id)
        REFERENCES msbf_ctl.scenario_registry(scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_15_comparison_stress FOREIGN KEY(stress_scenario_id)
        REFERENCES msbf_ctl.scenario_registry(scenario_id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS ix_m1_15_comparison_worsening
    ON msbf_m1.application_module1_scenario_comparison(
        module1_run_id,economic_worsening_flag,integrated_risk_worsening_flag
    );

/* ---------------------------------------------------------------------------
6. Hashing, readiness, and immutable canonical helpers
--------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_m1.m1_15_hash_jsonb(p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
SELECT md5(p_payload::text);
$$;


CREATE OR REPLACE FUNCTION msbf_m1.m1_15_assert_configuration(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_policy jsonb;
    v_scenarios bigint;
    v_baseline bigint;
    v_stress bigint;
    v_sets bigint;
    v_unapproved bigint;
    v_m1_8 bigint;
    v_m1_9 bigint;
    v_m1_10 bigint;
    v_m1_11 bigint;
    v_m1_12 bigint;
    v_m1_13 bigint;
    v_m1_14 bigint;
BEGIN
    SELECT profile_payload INTO STRICT v_policy
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_15_CONSUMPTION_CONTRACT'
      AND profile_version=1 AND status='APPROVED';

    SELECT count(DISTINCT e.scenario_id),
           count(DISTINCT e.scenario_id) FILTER(WHERE sr.scenario_code='BASELINE'),
           count(DISTINCT e.scenario_id) FILTER(WHERE sr.scenario_code='RECESSION_ENERGY'),
           count(DISTINCT sr.scenario_set_id),
           count(DISTINCT e.scenario_id) FILTER(WHERE sr.status<>'APPROVED')
    INTO v_scenarios,v_baseline,v_stress,v_sets,v_unapproved
    FROM msbf_m1.application_unit_economics_snapshot e
    JOIN msbf_ctl.scenario_registry sr
      ON sr.scenario_id=e.scenario_id
    WHERE e.module1_run_id=p_run_id;

    SELECT count(*) INTO v_m1_8 FROM msbf_m1.application_verification_fraud_snapshot
    WHERE module1_run_id=p_run_id;
    SELECT count(*) INTO v_m1_9 FROM msbf_m1.application_cashflow_feature_snapshot
    WHERE module1_run_id=p_run_id;
    SELECT count(*) INTO v_m1_10 FROM msbf_m1.application_liquidity_capacity_snapshot
    WHERE module1_run_id=p_run_id;
    SELECT count(*) INTO v_m1_11 FROM msbf_m1.application_operating_resilience_snapshot
    WHERE module1_run_id=p_run_id;
    SELECT count(*) INTO v_m1_12 FROM msbf_m1.application_integrated_risk_proxy_snapshot
    WHERE module1_run_id=p_run_id;
    SELECT count(*) INTO v_m1_13 FROM msbf_m1.application_exposure_recovery_loss_snapshot
    WHERE module1_run_id=p_run_id;
    SELECT count(*) INTO v_m1_14 FROM msbf_m1.application_unit_economics_snapshot
    WHERE module1_run_id=p_run_id;

    IF v_policy->>'methodology_version'<>'M1_15_METHOD_V1'
       OR v_policy->>'schema_version'<>'M1_CONTRACT_SCHEMA_V1'
       OR v_scenarios<>2 OR v_baseline<>1 OR v_stress<>1
       OR v_sets<>1 OR v_unapproved<>0
       OR v_m1_8<>750
       OR v_m1_9<>1500 OR v_m1_10<>1500 OR v_m1_11<>1500
       OR v_m1_12<>1500 OR v_m1_13<>1500 OR v_m1_14<>1500 THEN
        RAISE EXCEPTION
          'M1.15 configuration failed: scenarios %, baseline %, stress %, sets %, unapproved %, M1.8 %, M1.9 %, M1.10 %, M1.11 %, M1.12 %, M1.13 %, M1.14 %.',
          v_scenarios,v_baseline,v_stress,v_sets,v_unapproved,
          v_m1_8,v_m1_9,v_m1_10,v_m1_11,v_m1_12,v_m1_13,v_m1_14;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_15_assert_prerequisite_status(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE v_status text;
BEGIN
    PERFORM msbf_m1.m1_15_assert_configuration(p_run_id);

    SELECT run_status INTO STRICT v_status
    FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
    IF v_status<>'M1_14_ACCEPTED' THEN
        RAISE EXCEPTION 'M1.15 requires M1_14_ACCEPTED; observed %.',v_status;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_15_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_latest bigint;
    v_archive bigint;
    v_compare bigint;
    v_contract bigint;
    v_evidence bigint;
    v_gate bigint;
    v_blocking bigint;
BEGIN
    /* Centralize all upstream policy, scenario, count, and run-state checks. */
    PERFORM msbf_m1.m1_15_assert_prerequisite_status(p_run_id);

    SELECT count(*) INTO v_latest
    FROM msbf_m1.application_module1_latest
    WHERE module1_run_id=p_run_id;

    SELECT count(*) INTO v_archive
    FROM msbf_m1.application_module1_archive
    WHERE module1_run_id=p_run_id;

    SELECT count(*) INTO v_compare
    FROM msbf_m1.application_module1_scenario_comparison
    WHERE module1_run_id=p_run_id;

    SELECT count(*) INTO v_contract
    FROM msbf_ctl.m1_15_consumption_contract_registry
    WHERE module1_run_id=p_run_id;

    SELECT count(*) INTO v_evidence
    FROM msbf_ctl.run_evidence
    WHERE run_id=p_run_id
      AND evidence_code LIKE 'M1_15_%';

    SELECT count(*) INTO v_gate
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=p_run_id
      AND gate_id='M1_15_CONSUMPTION_CONTRACT';

    SELECT count(*) INTO v_blocking
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=p_run_id
      AND severity='BLOCKING';

    IF v_latest<>0
       OR v_archive<>0
       OR v_compare<>0
       OR v_contract<>0
       OR v_evidence<>0
       OR v_gate<>0
       OR v_blocking<>0 THEN
        RAISE EXCEPTION
            'M1.15 readiness failed: latest %, archive %, comparison %, contract %, evidence %, gate %, blocking %.',
            v_latest,v_archive,v_compare,v_contract,v_evidence,v_gate,v_blocking;
    END IF;
END;
$$;

/* ---------------------------------------------------------------------------
7. Governed consumption views
--------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW msbf_m1.v_m1_15_latest_consumption AS
SELECT * FROM msbf_m1.application_module1_latest;

CREATE OR REPLACE VIEW msbf_m1.v_m1_15_scenario_comparison AS
SELECT * FROM msbf_m1.application_module1_scenario_comparison;

CREATE OR REPLACE VIEW msbf_m1.v_m1_15_contract_lineage AS
SELECT
    c.contract_code,c.contract_version,c.schema_version,c.module1_run_id,
    r.run_code,r.run_version,r.run_status,r.population_id,r.as_of_date,
    ss.scenario_set_code,ss.scenario_set_version,c.contract_status,
    c.latest_row_count,c.archive_row_count,c.comparison_row_count,
    c.latest_set_hash,c.archive_set_hash,c.comparison_set_hash,
    c.contract_set_hash,c.combined_set_hash,c.contract_row_hash,
    c.generated_at,c.validated_at
FROM msbf_ctl.m1_15_consumption_contract_registry c
JOIN msbf_ctl.run_registry r ON r.run_id=c.module1_run_id
JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=c.scenario_set_id;

CREATE OR REPLACE VIEW msbf_m1.v_m1_15_power_bi_contract AS
SELECT
    l.module1_run_id,l.scenario_id,l.scenario_code,l.merchant_application_id,
    l.population_id,l.merchant_id,l.as_of_date,l.industry_code,
    l.merchant_size_tier,l.relationship_stage,l.partner_channel_id,l.channel_type,
    l.data_confidence_tier,l.verification_disposition,l.fraud_risk_tier,
    l.processor_continuity_status,l.feature_completeness_status,
    l.avg_daily_eligible_sales_30d,l.average_available_balance_30d,
    l.capacity_tier,l.affordability_status,l.archetype_code,
    l.operating_resilience_score,l.resilience_tier,l.integrated_risk_score,
    l.synthetic_merchant_risk_proxy,l.integrated_risk_tier,
    l.path_weighted_ead_amount,l.lgd_input_rate,
    l.schedule_adjusted_comparative_expected_loss_amount,
    l.risk_adjusted_contribution_amount,l.annualized_risk_adjusted_return_rate,
    l.economic_tier,l.economic_status,l.hard_stop_recommended_flag,
    l.manual_review_recommended_flag,l.contract_evidence_status,
    l.contract_code,l.contract_version,l.schema_version,l.contract_row_hash
FROM msbf_m1.application_module1_latest l;

COMMIT;

SELECT
    'M1_15_SCHEMA_POLICY_CONTRACT_EXTENSION' AS checkpoint,
    to_regclass('msbf_ctl.m1_15_consumption_contract_registry') IS NOT NULL AS contract_registry_exists,
    to_regclass('msbf_m1.application_module1_latest') IS NOT NULL AS latest_exists,
    to_regclass('msbf_m1.application_module1_archive') IS NOT NULL AS archive_exists,
    to_regclass('msbf_m1.application_module1_scenario_comparison') IS NOT NULL AS comparison_exists,
    (SELECT status FROM msbf_ctl.policy_profile
     WHERE profile_code='M1_15_CONSUMPTION_CONTRACT' AND profile_version=1) AS policy_status,
    'PASS' AS schema_policy_extension_status;
