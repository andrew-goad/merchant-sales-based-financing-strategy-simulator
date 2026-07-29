/* M1.10 final clean-build package revision v0.2R2; schema logic accepted from v0.2. */
/* ============================================================================
MSBF M1.10 Obligations, Liquidity & Residual Cash Flow — Schema and Policy Extension
Version : v0.2
Purpose : Extend the existing obligation evidence table, register governed
          affordability/capacity features, and create the scenario-aware M1.10
          liquidity-capacity output contract.
Boundary: Metadata and schema only. No obligations or capacity outputs are
          generated and the accepted M1.9 run status is not changed.
============================================================================ */
BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='5min';

INSERT INTO msbf_ref.acceptance_gate_catalog(
    gate_id,gate_name,module_code,severity,description
) VALUES (
    'M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY',
    'M1.10 Obligations, Liquidity and Residual Cash Flow',
    'M1','BLOCKING',
    'Existing-obligation evidence, requested sales-linked burden, residual cash flow, post-financing liquidity and governed capacity acceptance.'
)
ON CONFLICT(gate_id) DO UPDATE SET
    gate_name=EXCLUDED.gate_name,module_code=EXCLUDED.module_code,
    severity=EXCLUDED.severity,active_flag=true,description=EXCLUDED.description;

INSERT INTO msbf_ref.feature_family(
    feature_family_code,feature_family_name,owner_role,description
) VALUES (
    'AFFORDABILITY_CAPACITY','Affordability and Capacity','Credit Risk',
    'Existing obligations, requested burden, residual operating cash flow, liquidity buffer, stacking and capacity evidence.'
)
ON CONFLICT(feature_family_code) DO UPDATE SET
    feature_family_name=EXCLUDED.feature_family_name,
    owner_role=EXCLUDED.owner_role,description=EXCLUDED.description;

INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,
    valid_min_numeric,valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES
('EXISTING_DAILY_OBLIGATION_BURDEN',1,'Existing Daily Obligation Burden','AFFORDABILITY_CAPACITY','NUMERIC','CURRENCY',NULL,'Existing fixed and sales-linked daily obligation burden.','HIGHER_RISK',NULL,NULL,'Credit Risk',true,'Synthetic capacity feature; not a production underwriting decision or calibrated risk estimate.'),
('REQUESTED_DAILY_REMITTANCE',1,'Requested Daily Remittance','AFFORDABILITY_CAPACITY','NUMERIC','CURRENCY',NULL,'Conservative requested daily remittance using the greater of rate-based and horizon-required burden.','HIGHER_RISK',NULL,NULL,'Credit Risk',true,'Synthetic capacity feature; not a production underwriting decision or calibrated risk estimate.'),
('TOTAL_DAILY_OBLIGATION_BURDEN',1,'Total Daily Obligation Burden','AFFORDABILITY_CAPACITY','NUMERIC','CURRENCY',NULL,'Existing plus requested daily obligation burden.','HIGHER_RISK',NULL,NULL,'Credit Risk',true,'Synthetic capacity feature; not a production underwriting decision or calibrated risk estimate.'),
('SALES_LINKED_PAYMENT_COVERAGE_RATIO',1,'Sales-Linked Payment Coverage Ratio','AFFORDABILITY_CAPACITY','NUMERIC','RATIO',NULL,'Estimated daily operating cash flow divided by total daily obligation burden.','LOWER_RISK',0,100,'Credit Risk',true,'Synthetic capacity feature; not a production underwriting decision or calibrated risk estimate.'),
('RESIDUAL_DAILY_OPERATING_CASH_FLOW',1,'Residual Daily Operating Cash Flow','AFFORDABILITY_CAPACITY','NUMERIC','CURRENCY',NULL,'Estimated daily operating cash flow after existing and requested obligation burden.','LOWER_RISK',NULL,NULL,'Credit Risk',true,'Synthetic capacity feature; not a production underwriting decision or calibrated risk estimate.'),
('POST_FINANCING_LIQUIDITY_BUFFER',1,'Post-Financing Liquidity Buffer','AFFORDABILITY_CAPACITY','NUMERIC','CURRENCY',NULL,'Current average available balance plus projected residual cash flow over the governed horizon.','LOWER_RISK',NULL,NULL,'Credit Risk',true,'Synthetic capacity feature; not a production underwriting decision or calibrated risk estimate.'),
('POST_FINANCING_BUFFER_DAYS',1,'Post-Financing Buffer Days','AFFORDABILITY_CAPACITY','NUMERIC','DAYS',NULL,'Projected post-financing liquidity buffer divided by total daily obligation burden.','LOWER_RISK',NULL,NULL,'Credit Risk',true,'Synthetic capacity feature; not a production underwriting decision or calibrated risk estimate.'),
('TOTAL_OBLIGATION_TO_SALES_RATE',1,'Total Obligation-to-Sales Rate','AFFORDABILITY_CAPACITY','NUMERIC','RATE',NULL,'Total daily obligation burden divided by trailing average daily eligible sales.','HIGHER_RISK',0,10,'Credit Risk',true,'Synthetic capacity feature; not a production underwriting decision or calibrated risk estimate.'),
('OBLIGATION_CONCENTRATION_RATE',1,'Obligation Concentration Rate','AFFORDABILITY_CAPACITY','NUMERIC','RATE',NULL,'Largest existing daily obligation divided by total existing daily obligation burden.','HIGHER_RISK',0,1,'Credit Risk',true,'Synthetic capacity feature; not a production underwriting decision or calibrated risk estimate.'),
('STACKING_DEPTH',1,'Stacking Depth','AFFORDABILITY_CAPACITY','NUMERIC','COUNT',NULL,'Existing short-term obligations plus the requested sales-linked structure.','HIGHER_RISK',0,10,'Credit Risk',true,'Synthetic capacity feature; not a production underwriting decision or calibrated risk estimate.'),
('CAPACITY_TIER',1,'Capacity Tier','AFFORDABILITY_CAPACITY','NUMERIC','TIER',NULL,'Governed affordability/capacity tier from one through five.','HIGHER_RISK',1,5,'Credit Risk',true,'Synthetic capacity feature; not a production underwriting decision or calibrated risk estimate.')
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

ALTER TABLE msbf_m1.application_obligation_snapshot
    ADD COLUMN IF NOT EXISTS obligation_status text DEFAULT 'ACTIVE' NOT NULL,
    ADD COLUMN IF NOT EXISTS payment_frequency text DEFAULT 'MONTHLY' NOT NULL,
    ADD COLUMN IF NOT EXISTS maturity_date date,
    ADD COLUMN IF NOT EXISTS secured_flag boolean DEFAULT false NOT NULL,
    ADD COLUMN IF NOT EXISTS data_confidence_score numeric(9,6) DEFAULT 1.0 NOT NULL,
    ADD COLUMN IF NOT EXISTS obligation_quality_status text DEFAULT 'PASS' NOT NULL,
    ADD COLUMN IF NOT EXISTS obligation_reason_code text DEFAULT 'SYNTHETIC_OBSERVED' NOT NULL,
    ADD COLUMN IF NOT EXISTS row_hash text,
    ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT clock_timestamp() NOT NULL;

DO $ddl$
BEGIN
    IF EXISTS (SELECT 1 FROM msbf_m1.application_obligation_snapshot WHERE row_hash IS NULL) THEN
        RAISE EXCEPTION 'M1.10 cannot enforce obligation row hashes while legacy rows with NULL row_hash exist.';
    END IF;
    ALTER TABLE msbf_m1.application_obligation_snapshot ALTER COLUMN row_hash SET NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='msbf_m1.application_obligation_snapshot'::regclass AND conname='ck_m1_10_obligation_type') THEN
        ALTER TABLE msbf_m1.application_obligation_snapshot ADD CONSTRAINT ck_m1_10_obligation_type
        CHECK(obligation_type IN ('SALES_BASED_ADVANCE','TERM_LOAN','LINE_OF_CREDIT','EQUIPMENT_FINANCE','BUSINESS_CREDIT_CARD','LEASE'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='msbf_m1.application_obligation_snapshot'::regclass AND conname='ck_m1_10_obligation_status') THEN
        ALTER TABLE msbf_m1.application_obligation_snapshot ADD CONSTRAINT ck_m1_10_obligation_status
        CHECK(obligation_status IN ('ACTIVE','CLOSED'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='msbf_m1.application_obligation_snapshot'::regclass AND conname='ck_m1_10_payment_frequency') THEN
        ALTER TABLE msbf_m1.application_obligation_snapshot ADD CONSTRAINT ck_m1_10_payment_frequency
        CHECK(payment_frequency IN ('SALES_LINKED','DAILY','WEEKLY','MONTHLY'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='msbf_m1.application_obligation_snapshot'::regclass AND conname='ck_m1_10_obligation_confidence') THEN
        ALTER TABLE msbf_m1.application_obligation_snapshot ADD CONSTRAINT ck_m1_10_obligation_confidence
        CHECK(data_confidence_score BETWEEN 0 AND 1);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='msbf_m1.application_obligation_snapshot'::regclass AND conname='ck_m1_10_obligation_quality') THEN
        ALTER TABLE msbf_m1.application_obligation_snapshot ADD CONSTRAINT ck_m1_10_obligation_quality
        CHECK(obligation_quality_status IN ('PASS','WARNING','FAIL','CONFLICT'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='msbf_m1.application_obligation_snapshot'::regclass AND conname='ck_m1_10_obligation_amounts') THEN
        ALTER TABLE msbf_m1.application_obligation_snapshot ADD CONSTRAINT ck_m1_10_obligation_amounts
        CHECK(outstanding_balance>=0 AND daily_payment_amount>=0 AND monthly_payment_amount>=0
              AND (remittance_rate IS NULL OR remittance_rate BETWEEN 0 AND 1));
    END IF;
END;
$ddl$;

CREATE INDEX IF NOT EXISTS ix_m1_10_obligation_application
    ON msbf_m1.application_obligation_snapshot(created_by_run_id,merchant_application_id,obligation_type);
CREATE INDEX IF NOT EXISTS ix_m1_10_obligation_stacking
    ON msbf_m1.application_obligation_snapshot(created_by_run_id,short_term_financing_flag,stacking_sequence);

CREATE TABLE IF NOT EXISTS msbf_m1.application_liquidity_capacity_snapshot (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    obligation_source_snapshot_id bigint NOT NULL,
    obligation_availability_status text NOT NULL,
    obligation_quality_status text NOT NULL,
    obligation_confidence_score numeric(9,6) NOT NULL,
    feature_completeness_status text NOT NULL,
    verification_disposition text NOT NULL,
    obligation_count integer NOT NULL,
    short_term_obligation_count integer NOT NULL,
    secured_obligation_count integer NOT NULL,
    stacked_obligation_count integer NOT NULL,
    max_stacking_sequence smallint NOT NULL,
    existing_outstanding_balance numeric(18,2) NOT NULL,
    fixed_existing_daily_payment_amount numeric(18,2) NOT NULL,
    existing_sales_linked_remittance_rate numeric(12,8) NOT NULL,
    existing_daily_payment_amount numeric(18,2) NOT NULL,
    existing_monthly_payment_amount numeric(18,2) NOT NULL,
    largest_existing_daily_payment_amount numeric(18,2) NOT NULL,
    requested_rate_based_daily_remittance numeric(18,2),
    requested_horizon_required_daily_repayment numeric(18,2) NOT NULL,
    requested_daily_remittance_amount numeric(18,2) NOT NULL,
    requested_monthly_remittance_amount numeric(18,2) NOT NULL,
    total_daily_obligation_burden numeric(18,2) NOT NULL,
    total_monthly_obligation_burden numeric(18,2) NOT NULL,
    estimated_daily_operating_cash_flow numeric(18,2),
    existing_obligation_to_sales_rate numeric(12,8),
    total_obligation_to_sales_rate numeric(12,8),
    sales_linked_payment_coverage_ratio numeric(12,8),
    residual_daily_operating_cash_flow numeric(18,2),
    residual_monthly_operating_cash_flow numeric(18,2),
    current_liquidity_buffer_amount numeric(18,2),
    post_financing_liquidity_buffer_amount numeric(18,2),
    post_financing_buffer_days numeric(12,4),
    obligation_concentration_rate numeric(12,8) NOT NULL,
    stacking_depth smallint NOT NULL,
    independent_capacity_tier smallint NOT NULL,
    baseline_capacity_tier smallint NOT NULL,
    capacity_tier smallint NOT NULL,
    stress_capacity_worsening_flag boolean NOT NULL,
    capacity_evidence_status text NOT NULL,
    affordability_status text NOT NULL,
    manual_review_recommended_flag boolean NOT NULL,
    fallback_path_code text NOT NULL,
    primary_capacity_reason_code text NOT NULL,
    secondary_capacity_reason_codes text[] DEFAULT '{}'::text[] NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_m1_10_capacity PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m1_10_capacity_confidence CHECK(obligation_confidence_score BETWEEN 0 AND 1),
    CONSTRAINT ck_m1_10_capacity_counts CHECK(obligation_count>=0 AND short_term_obligation_count>=0
        AND secured_obligation_count>=0 AND stacked_obligation_count>=0 AND max_stacking_sequence>=0
        AND stacking_depth>=1),
    CONSTRAINT ck_m1_10_capacity_amounts CHECK(existing_outstanding_balance>=0
        AND fixed_existing_daily_payment_amount>=0 AND existing_sales_linked_remittance_rate>=0
        AND existing_daily_payment_amount>=0 AND existing_monthly_payment_amount>=0
        AND largest_existing_daily_payment_amount>=0 AND requested_horizon_required_daily_repayment>=0
        AND requested_daily_remittance_amount>=0 AND requested_monthly_remittance_amount>=0
        AND total_daily_obligation_burden>=0 AND total_monthly_obligation_burden>=0),
    CONSTRAINT ck_m1_10_capacity_rates CHECK((existing_obligation_to_sales_rate IS NULL OR existing_obligation_to_sales_rate>=0)
        AND (total_obligation_to_sales_rate IS NULL OR total_obligation_to_sales_rate>=0)
        AND (sales_linked_payment_coverage_ratio IS NULL OR sales_linked_payment_coverage_ratio>=0)
        AND obligation_concentration_rate BETWEEN 0 AND 1),
    CONSTRAINT ck_m1_10_capacity_tiers CHECK(independent_capacity_tier BETWEEN 1 AND 5
        AND baseline_capacity_tier BETWEEN 1 AND 5 AND capacity_tier BETWEEN 1 AND 5),
    CONSTRAINT ck_m1_10_capacity_source CHECK(obligation_availability_status IN ('AVAILABLE','PARTIAL','UNAVAILABLE')
        AND obligation_quality_status IN ('PASS','WARNING','FAIL','CONFLICT','UNAVAILABLE')),
    CONSTRAINT ck_m1_10_capacity_evidence CHECK(capacity_evidence_status IN ('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_m1_10_affordability CHECK(affordability_status IN ('AFFORDABLE','MARGINAL','UNAFFORDABLE','INSUFFICIENT_EVIDENCE')),
    CONSTRAINT ck_m1_10_fallback CHECK(fallback_path_code IN ('NONE','MANUAL_OBLIGATION_REVIEW','SOURCE_CONFLICT_REVIEW','SOURCE_REFRESH','INSUFFICIENT_CASHFLOW_EVIDENCE','MANUAL_CAPACITY_REVIEW','STRUCTURE_REVIEW')),
    CONSTRAINT ck_m1_10_capacity_run_lineage CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_m1_10_capacity_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_10_capacity_scenario FOREIGN KEY(scenario_id) REFERENCES msbf_ctl.scenario_registry(scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_10_capacity_application FOREIGN KEY(merchant_application_id) REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_10_capacity_population FOREIGN KEY(population_id) REFERENCES msbf_m1.population_registry(population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_10_capacity_merchant FOREIGN KEY(merchant_id) REFERENCES msbf_m1.merchant_master(merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_10_capacity_obligation_source FOREIGN KEY(obligation_source_snapshot_id,module1_run_id) REFERENCES msbf_m1.source_snapshot(source_snapshot_id,module1_run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_10_capacity_feature_snapshot FOREIGN KEY(module1_run_id,scenario_id,merchant_application_id)
        REFERENCES msbf_m1.application_cashflow_feature_snapshot(module1_run_id,scenario_id,merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_10_capacity_created_run FOREIGN KEY(created_by_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.application_liquidity_capacity_snapshot IS
'Scenario-aware M1.10 existing-obligation, requested-burden, residual-cash-flow, post-financing-liquidity and governed capacity evidence.';
CREATE INDEX IF NOT EXISTS ix_m1_10_capacity_status
    ON msbf_m1.application_liquidity_capacity_snapshot(module1_run_id,scenario_id,capacity_tier,affordability_status);
CREATE INDEX IF NOT EXISTS ix_m1_10_capacity_merchant
    ON msbf_m1.application_liquidity_capacity_snapshot(merchant_id,scenario_id,as_of_date);
CREATE INDEX IF NOT EXISTS ix_m1_10_capacity_review
    ON msbf_m1.application_liquidity_capacity_snapshot(module1_run_id,manual_review_recommended_flag,fallback_path_code);

CREATE OR REPLACE VIEW msbf_m1.v_m1_10_capacity_lineage AS
SELECT c.module1_run_id,c.scenario_id,s.scenario_code,c.merchant_application_id,
       c.population_id,c.merchant_id,c.as_of_date,c.obligation_source_snapshot_id,
       src.availability_status AS source_availability_status,
       src.quality_status AS source_quality_status,
       c.obligation_count,c.existing_daily_payment_amount,c.requested_daily_remittance_amount,
       c.total_daily_obligation_burden,c.estimated_daily_operating_cash_flow,
       c.sales_linked_payment_coverage_ratio,c.residual_daily_operating_cash_flow,
       c.post_financing_liquidity_buffer_amount,c.post_financing_buffer_days,
       c.capacity_tier,c.affordability_status,c.manual_review_recommended_flag,
       c.fallback_path_code,c.primary_capacity_reason_code,c.row_hash
FROM msbf_m1.application_liquidity_capacity_snapshot c
JOIN msbf_ctl.scenario_registry s ON s.scenario_id=c.scenario_id
JOIN msbf_m1.source_snapshot src
  ON src.source_snapshot_id=c.obligation_source_snapshot_id
 AND src.module1_run_id=c.module1_run_id;

INSERT INTO msbf_ctl.policy_profile(
    profile_code,profile_version,business_name,effective_start_date,effective_end_date,
    status,owner_role,approver_role,approval_timestamp,last_review_date,next_review_date,
    change_reason,policy_domain,product_structure_profile_id,operating_model_profile_id,
    parameter_set_id,profile_payload
)
SELECT
    'M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY',1,
    'M1.10 Obligations, Liquidity and Residual Cash Flow Policy',
    r.as_of_date,NULL,'APPROVED','Credit Risk','Credit Risk and Model Governance',
    coalesce(p.approval_timestamp,clock_timestamp()),r.as_of_date,r.as_of_date+365,
    'Initial governed M1.10 obligations, residual cash flow and capacity methodology.',
    'OBLIGATIONS_LIQUIDITY_CAPACITY',r.product_structure_profile_id,
    r.operating_model_profile_id,r.parameter_set_id,'{"generation_enabled":true,"methodology_version":"M1_10_METHOD_V1","requested_burden_basis":"MAX_RATE_OR_HORIZON","stress_capacity_tier_floor_to_baseline":true,"max_obligations_per_application":3,"obligation_count_none_threshold":0.3,"obligation_count_one_threshold":0.7,"obligation_count_two_threshold":0.92,"minimum_obligation_count_with_prior_advance":1,"monthly_days":30,"annualization_days":365,"liquidity_projection_days":30,"daily_sales_denominator_floor":1.0,"coverage_tier_1_threshold":1.5,"coverage_tier_2_threshold":1.25,"coverage_tier_3_threshold":1.0,"burden_rate_tier_1_max":0.15,"burden_rate_tier_2_max":0.22,"burden_rate_tier_3_max":0.3,"buffer_days_tier_1_min":30.0,"buffer_days_tier_2_min":15.0,"buffer_days_tier_3_min":5.0,"stacking_review_threshold":3,"concentration_review_threshold":0.75,"obligation_confidence_complete_threshold":0.9,"obligation_confidence_review_threshold":0.75,"industry_operating_cash_margin":{"RESTAURANT_FOOD_SERVICE":0.15,"GENERAL_RETAIL":0.16,"PROFESSIONAL_SERVICES":0.3,"CONSTRUCTION_TRADES":0.18,"TRANSPORTATION_LOGISTICS":0.17,"ENERGY_SERVICES":0.2,"HEALTHCARE_SERVICES":0.24,"ECOMMERCE_DIGITAL":0.22},"type_balance_multiplier":{"SALES_BASED_ADVANCE":0.65,"TERM_LOAN":0.85,"LINE_OF_CREDIT":0.45,"EQUIPMENT_FINANCE":0.75,"BUSINESS_CREDIT_CARD":0.25,"LEASE":0.35},"type_finance_factor":{"SALES_BASED_ADVANCE":1.2,"TERM_LOAN":1.12,"LINE_OF_CREDIT":1.15,"EQUIPMENT_FINANCE":1.1,"BUSINESS_CREDIT_CARD":1.18,"LEASE":1.08},"type_term_days":{"SALES_BASED_ADVANCE":90,"TERM_LOAN":365,"LINE_OF_CREDIT":180,"EQUIPMENT_FINANCE":720,"BUSINESS_CREDIT_CARD":365,"LEASE":540}}'::jsonb
FROM msbf_ctl.run_registry r
LEFT JOIN msbf_ctl.policy_profile p
  ON p.profile_code='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY' AND p.profile_version=1
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
    WHERE profile_code='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY' AND profile_version=1
), f AS (
    SELECT count(*) AS active_features FROM msbf_m1.feature_definition
    WHERE feature_family_code='AFFORDABILITY_CAPACITY' AND feature_version=1 AND active_flag
)
SELECT
    (SELECT count(*) FROM information_schema.columns
      WHERE table_schema='msbf_m1' AND table_name='application_obligation_snapshot'
        AND column_name IN ('obligation_status','payment_frequency','maturity_date','secured_flag','data_confidence_score','obligation_quality_status','obligation_reason_code','row_hash','created_at')) AS obligation_columns_added,
    to_regclass('msbf_m1.application_liquidity_capacity_snapshot') IS NOT NULL AS capacity_table_exists,
    to_regclass('msbf_m1.v_m1_10_capacity_lineage') IS NOT NULL AS lineage_view_exists,
    (SELECT active_features FROM f) AS active_capacity_features,
    p.policy_profile_id,p.status AS policy_status,p.policy_hash,
    p.profile_payload->>'methodology_version' AS methodology_version,
    CASE WHEN (SELECT count(*) FROM information_schema.columns
               WHERE table_schema='msbf_m1' AND table_name='application_obligation_snapshot'
                 AND column_name IN ('obligation_status','payment_frequency','maturity_date','secured_flag','data_confidence_score','obligation_quality_status','obligation_reason_code','row_hash','created_at'))=9
           AND to_regclass('msbf_m1.application_liquidity_capacity_snapshot') IS NOT NULL
           AND to_regclass('msbf_m1.v_m1_10_capacity_lineage') IS NOT NULL
           AND (SELECT active_features FROM f)=11
           AND p.status='APPROVED'
         THEN 'PASS' ELSE 'FAIL' END AS schema_policy_extension_status
FROM p;
