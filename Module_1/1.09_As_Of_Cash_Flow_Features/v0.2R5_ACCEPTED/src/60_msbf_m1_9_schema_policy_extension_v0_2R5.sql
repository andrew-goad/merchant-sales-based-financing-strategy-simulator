/* ============================================================================
MSBF M1.9 As-of Cash-Flow Feature Engineering — Schema and Policy Extension
Version : v0.2R5
Purpose : Register the M1.9 gate and policy, add scenario-sensitivity feature
          definitions, and create scenario-aware wide/long feature tables.
Boundary:  Metadata and schema only. No cash-flow features are generated and
          the accepted M1.8 run status is not changed.
============================================================================ */
BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='5min';

INSERT INTO msbf_ref.acceptance_gate_catalog(
    gate_id,gate_name,module_code,severity,description
) VALUES (
    'M1_9_ASOF_CASHFLOW_FEATURES',
    'M1.9 As-of Cash-Flow Feature Engineering',
    'M1','BLOCKING',
    'Scenario-aware as-of revenue, trend, stability, transaction-quality, liquidity, source-confidence and matched scenario-delta feature acceptance.'
)
ON CONFLICT(gate_id) DO UPDATE SET
    gate_name=EXCLUDED.gate_name,
    module_code=EXCLUDED.module_code,
    severity=EXCLUDED.severity,
    active_flag=true,
    description=EXCLUDED.description;

INSERT INTO msbf_ref.feature_family(
    feature_family_code,feature_family_name,owner_role,description
) VALUES (
    'SCENARIO_SENSITIVITY','Scenario Sensitivity','Credit Risk',
    'Matched baseline-versus-stress cash-flow feature deltas.'
)
ON CONFLICT(feature_family_code) DO UPDATE SET
    feature_family_name=EXCLUDED.feature_family_name,
    owner_role=EXCLUDED.owner_role,
    description=EXCLUDED.description;

INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'ACTIVE_SALES_DAY_RATE_30D',1,'Active-Sales-Day Rate — 30 Day','REVENUE_STABILITY','NUMERIC','RATE',
    30,'Observed positive-sales days divided by observed POS days in the trailing thirty-day window.','LOWER_RISK',0,1,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'POS_DEPOSIT_RECONCILIATION_RATE_30D',1,'POS/Deposit Reconciliation Rate — 30 Day','LIQUIDITY','NUMERIC','RATE',
    30,'Symmetric agreement between operating deposits and expected captured net merchant proceeds.','LOWER_RISK',0,1,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'MINIMUM_BALANCE_30D',1,'Minimum Balance — 30 Day','LIQUIDITY','NUMERIC','CURRENCY',
    30,'Minimum observed daily balance in the trailing thirty-day window.','LOWER_RISK',NULL,NULL,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'PROCESSOR_OUTAGE_DAY_RATE_30D',1,'Processor Outage-Day Rate — 30 Day','BUSINESS_STABILITY','NUMERIC','RATE',
    30,'Processor outage days divided by post-open calendar days in the trailing thirty-day window.','HIGHER_RISK',0,1,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'PROCESSOR_DEGRADED_DAY_RATE_30D',1,'Processor Degraded-Day Rate — 30 Day','BUSINESS_STABILITY','NUMERIC','RATE',
    30,'Processor degraded days divided by post-open calendar days in the trailing thirty-day window.','HIGHER_RISK',0,1,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'SCENARIO_ELIGIBLE_SALES_DELTA_RATE_30D',1,'Scenario Eligible-Sales Delta Rate — 30 Day','SCENARIO_SENSITIVITY','NUMERIC','RATE',
    30,'Scenario average eligible sales relative to the matched baseline over thirty days.','CONTEXTUAL',-10,10,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'SCENARIO_ELIGIBLE_SALES_DELTA_RATE_90D',1,'Scenario Eligible-Sales Delta Rate — 90 Day','SCENARIO_SENSITIVITY','NUMERIC','RATE',
    90,'Scenario average eligible sales relative to the matched baseline over ninety days.','CONTEXTUAL',-10,10,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'SCENARIO_DEPOSIT_DELTA_RATE_30D',1,'Scenario Deposit Delta Rate — 30 Day','SCENARIO_SENSITIVITY','NUMERIC','RATE',
    30,'Scenario deposit amount relative to the matched baseline over thirty days.','CONTEXTUAL',-10,10,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'SCENARIO_WITHDRAWAL_DELTA_RATE_30D',1,'Scenario Withdrawal Delta Rate — 30 Day','SCENARIO_SENSITIVITY','NUMERIC','RATE',
    30,'Scenario withdrawal amount relative to the matched baseline over thirty days.','CONTEXTUAL',-10,10,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'SCENARIO_AVAILABLE_BALANCE_DELTA_RATE_30D',1,'Scenario Available-Balance Delta Rate — 30 Day','SCENARIO_SENSITIVITY','NUMERIC','RATE',
    30,'Scenario average available balance relative to the matched baseline over thirty days.','CONTEXTUAL',-10,10,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'SCENARIO_NEGATIVE_BALANCE_RATE_DELTA_30D',1,'Scenario Negative-Balance Rate Delta — 30 Day','SCENARIO_SENSITIVITY','NUMERIC','RATE',
    30,'Scenario negative-balance-day rate minus the matched baseline rate.','CONTEXTUAL',-10,10,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'SCENARIO_NSF_COUNT_DELTA_30D',1,'Scenario NSF Count Delta — 30 Day','SCENARIO_SENSITIVITY','INTEGER','COUNT',
    30,'Scenario NSF-event count minus the matched baseline count.','CONTEXTUAL',NULL,NULL,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'SCENARIO_PROCESSOR_OUTAGE_RATE_DELTA_30D',1,'Scenario Processor-Outage Rate Delta — 30 Day','SCENARIO_SENSITIVITY','NUMERIC','RATE',
    30,'Scenario processor-outage-day rate minus the matched baseline rate.','CONTEXTUAL',-10,10,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'SCENARIO_REFUND_RATE_DELTA_30D',1,'Scenario Refund-Rate Delta — 30 Day','SCENARIO_SENSITIVITY','NUMERIC','RATE',
    30,'Scenario refund rate minus the matched baseline rate.','CONTEXTUAL',-10,10,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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
INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
) VALUES (
    'SCENARIO_CHARGEBACK_RATE_DELTA_30D',1,'Scenario Chargeback-Rate Delta — 30 Day','SCENARIO_SENSITIVITY','NUMERIC','RATE',
    30,'Scenario chargeback rate minus the matched baseline rate.','CONTEXTUAL',-10,10,
    'Credit Risk',true,'Synthetic as-of cash-flow feature; not production-calibrated.'
)
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

CREATE TABLE IF NOT EXISTS msbf_m1.application_cashflow_feature_snapshot (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    history_start_date date NOT NULL,
    history_end_date date NOT NULL,
    pos_source_snapshot_id bigint NOT NULL,
    deposit_source_snapshot_id bigint NOT NULL,
    source_confidence_score numeric(9,6) NOT NULL,
    data_confidence_tier text NOT NULL,
    pos_quality_status text NOT NULL,
    deposit_quality_status text NOT NULL,
    feature_completeness_status text NOT NULL,
    downstream_routing_status text NOT NULL,
    ready_for_downstream_flag boolean NOT NULL,
    manual_review_recommended_flag boolean NOT NULL,
    verification_disposition text NOT NULL,
    fraud_risk_tier smallint NOT NULL,
    processor_continuity_status text NOT NULL,
    processor_continuity_risk_tier smallint NOT NULL,
    pos_history_days integer NOT NULL,
    deposit_history_days integer NOT NULL,
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
    active_sales_day_rate_30d numeric(12,8),
    seasonality_index_180d numeric(12,8),
    largest_30d_share_180d numeric(12,8),
    refund_rate_30d numeric(12,8),
    chargeback_rate_30d numeric(12,8),
    reversal_rate_30d numeric(12,8),
    deposit_to_eligible_sales_rate_30d numeric(12,8),
    pos_deposit_reconciliation_rate_30d numeric(12,8),
    negative_balance_day_rate_30d numeric(12,8),
    nsf_count_30d integer,
    average_available_balance_30d numeric(18,2),
    minimum_balance_30d numeric(18,2),
    cash_flow_buffer_days numeric(12,4),
    processor_outage_day_rate_30d numeric(12,8),
    processor_degraded_day_rate_30d numeric(12,8),
    scenario_eligible_sales_delta_rate_30d numeric(12,8),
    scenario_eligible_sales_delta_rate_90d numeric(12,8),
    scenario_deposit_delta_rate_30d numeric(12,8),
    scenario_withdrawal_delta_rate_30d numeric(12,8),
    scenario_available_balance_delta_rate_30d numeric(12,8),
    scenario_negative_balance_rate_delta_30d numeric(12,8),
    scenario_nsf_count_delta_30d integer,
    scenario_processor_outage_rate_delta_30d numeric(12,8),
    scenario_refund_rate_delta_30d numeric(12,8),
    scenario_chargeback_rate_delta_30d numeric(12,8),
    feature_snapshot_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_m1_9_cashflow_snapshot
        PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id),
    CONSTRAINT ck_m1_9_snapshot_history
        CHECK(history_start_date<=history_end_date AND history_end_date<=as_of_date),
    CONSTRAINT ck_m1_9_snapshot_confidence
        CHECK(source_confidence_score BETWEEN 0 AND 1
          AND data_confidence_tier IN ('HIGH','MEDIUM','LOW','REVIEW')),
    CONSTRAINT ck_m1_9_snapshot_quality
        CHECK(pos_quality_status IN ('PASS','WARNING','FAIL','CONFLICT','UNAVAILABLE')
          AND deposit_quality_status IN ('PASS','WARNING','FAIL','CONFLICT','UNAVAILABLE')),
    CONSTRAINT ck_m1_9_snapshot_completeness
        CHECK(feature_completeness_status IN ('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_m1_9_snapshot_routing
        CHECK(downstream_routing_status IN ('CLEAR','REVIEW','STOP','INSUFFICIENT_EVIDENCE')
          AND verification_disposition IN ('CLEAR','REVIEW','STOP','INSUFFICIENT_EVIDENCE')),
    CONSTRAINT ck_m1_9_snapshot_tiers
        CHECK(fraud_risk_tier BETWEEN 1 AND 5
          AND processor_continuity_risk_tier BETWEEN 1 AND 5),
    CONSTRAINT ck_m1_9_snapshot_history_counts
        CHECK(pos_history_days>=0 AND deposit_history_days>=0),
    CONSTRAINT ck_m1_9_snapshot_run_lineage
        CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_m1_9_snapshot_run FOREIGN KEY(module1_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_9_snapshot_scenario FOREIGN KEY(scenario_id)
        REFERENCES msbf_ctl.scenario_registry(scenario_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_9_snapshot_application FOREIGN KEY(merchant_application_id)
        REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_9_snapshot_population FOREIGN KEY(population_id)
        REFERENCES msbf_m1.population_registry(population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_9_snapshot_merchant FOREIGN KEY(merchant_id)
        REFERENCES msbf_m1.merchant_master(merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_9_snapshot_pos_source FOREIGN KEY(pos_source_snapshot_id,module1_run_id)
        REFERENCES msbf_m1.source_snapshot(source_snapshot_id,module1_run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_9_snapshot_deposit_source FOREIGN KEY(deposit_source_snapshot_id,module1_run_id)
        REFERENCES msbf_m1.source_snapshot(source_snapshot_id,module1_run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_9_snapshot_created_run FOREIGN KEY(created_by_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.application_cashflow_feature_snapshot IS
'Scenario-aware M1.9 as-of merchant revenue, stability, transaction-quality, liquidity, confidence and stress-delta feature snapshot.';
CREATE INDEX IF NOT EXISTS ix_m1_9_cashflow_snapshot_scenario
    ON msbf_m1.application_cashflow_feature_snapshot(module1_run_id,scenario_id,feature_completeness_status);
CREATE INDEX IF NOT EXISTS ix_m1_9_cashflow_snapshot_merchant
    ON msbf_m1.application_cashflow_feature_snapshot(merchant_id,scenario_id,as_of_date);

CREATE TABLE IF NOT EXISTS msbf_m1.cashflow_feature_value (
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    feature_code text NOT NULL,
    feature_version integer DEFAULT 1 NOT NULL,
    value_numeric numeric(24,10),
    value_status text NOT NULL,
    primary_source_snapshot_id bigint,
    secondary_source_snapshot_id bigint,
    observation_start_date date,
    observation_end_date date,
    calculation_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_m1_9_cashflow_feature_value
        PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id,feature_code,feature_version),
    CONSTRAINT ck_m1_9_feature_value_status
        CHECK(value_status IN ('AVAILABLE','NOT_AVAILABLE','NOT_APPLICABLE')),
    CONSTRAINT ck_m1_9_feature_value_presence
        CHECK((value_status='AVAILABLE' AND value_numeric IS NOT NULL)
           OR (value_status<>'AVAILABLE' AND value_numeric IS NULL)),
    CONSTRAINT ck_m1_9_feature_value_window
        CHECK(observation_end_date IS NULL OR observation_start_date IS NULL
           OR observation_end_date>=observation_start_date),
    CONSTRAINT ck_m1_9_feature_value_run_lineage
        CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_m1_9_feature_value_snapshot
        FOREIGN KEY(module1_run_id,scenario_id,merchant_application_id)
        REFERENCES msbf_m1.application_cashflow_feature_snapshot(module1_run_id,scenario_id,merchant_application_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_m1_9_feature_value_definition
        FOREIGN KEY(feature_code,feature_version)
        REFERENCES msbf_m1.feature_definition(feature_code,feature_version) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_9_feature_value_primary_source
        FOREIGN KEY(primary_source_snapshot_id,module1_run_id)
        REFERENCES msbf_m1.source_snapshot(source_snapshot_id,module1_run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_9_feature_value_secondary_source
        FOREIGN KEY(secondary_source_snapshot_id,module1_run_id)
        REFERENCES msbf_m1.source_snapshot(source_snapshot_id,module1_run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_9_feature_value_created_run
        FOREIGN KEY(created_by_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT
);
COMMENT ON TABLE msbf_m1.cashflow_feature_value IS
'Long-form M1.9 cash-flow feature values with scenario, source, observation-window and calculation-hash lineage.';
CREATE INDEX IF NOT EXISTS ix_m1_9_feature_value_code
    ON msbf_m1.cashflow_feature_value(feature_code,scenario_id,value_status);
CREATE INDEX IF NOT EXISTS ix_m1_9_feature_value_application
    ON msbf_m1.cashflow_feature_value(module1_run_id,merchant_application_id,scenario_id);

CREATE OR REPLACE VIEW msbf_m1.v_m1_9_feature_lineage AS
SELECT
    v.module1_run_id,v.scenario_id,s.scenario_code,v.merchant_application_id,
    v.feature_code,v.feature_version,d.feature_name,d.feature_family_code,
    v.value_numeric,v.value_status,v.primary_source_snapshot_id,
    ps.source_code AS primary_source_code,v.secondary_source_snapshot_id,
    ss.source_code AS secondary_source_code,v.observation_start_date,
    v.observation_end_date,v.calculation_hash
FROM msbf_m1.cashflow_feature_value v
JOIN msbf_ctl.scenario_registry s ON s.scenario_id=v.scenario_id
JOIN msbf_m1.feature_definition d
  ON d.feature_code=v.feature_code AND d.feature_version=v.feature_version
LEFT JOIN msbf_m1.source_snapshot ps
  ON ps.source_snapshot_id=v.primary_source_snapshot_id AND ps.module1_run_id=v.module1_run_id
LEFT JOIN msbf_m1.source_snapshot ss
  ON ss.source_snapshot_id=v.secondary_source_snapshot_id AND ss.module1_run_id=v.module1_run_id;

INSERT INTO msbf_ctl.policy_profile(
    profile_code,profile_version,business_name,effective_start_date,effective_end_date,
    status,owner_role,approver_role,approval_timestamp,last_review_date,next_review_date,
    change_reason,policy_domain,product_structure_profile_id,operating_model_profile_id,
    parameter_set_id,profile_payload
)
SELECT
    'M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING',1,
    'M1.9 As-of Cash-Flow Feature Engineering Policy',
    r.as_of_date,NULL,'APPROVED','Credit Risk','Credit Risk and Model Governance',
    clock_timestamp(),r.as_of_date,r.as_of_date+365,
    'Initial governed M1.9 as-of feature methodology.',
    'ASOF_CASHFLOW_FEATURE_ENGINEERING',
    r.product_structure_profile_id,r.operating_model_profile_id,r.parameter_set_id,
    '{"annualization_days":365,"annualized_sales_basis":"PERSISTED_ROUNDED_90D_AVERAGE","annualized_sales_scale":2,"baseline_scenario_code":"BASELINE","buffer_days_cap":365.0,"cv_cap":10.0,"data_confidence_high_threshold":0.9,"data_confidence_low_threshold":0.6,"data_confidence_medium_threshold":0.75,"delta_denominator_floor":1.0,"feature_count_per_snapshot":36,"generation_enabled":true,"growth_cap":5.0,"growth_floor":-1.0,"mean_sales_epsilon":0.01,"methodology_version":"M1_9_METHOD_V1","minimum_core_pos_days":30,"minimum_deposit_days":30,"minimum_full_pos_days":90,"minimum_seasonality_days":120,"ratio_cap":10.0,"seasonality_cap":5.0,"source_weights":{"BUSINESS_CREDIT":0.1,"COLLATERAL_AVAILABILITY":0.05,"DEPOSIT_DAILY":0.2,"OBLIGATIONS":0.07,"OWNER_CREDIT":0.08,"POS_DAILY":0.35,"VERIFICATION":0.15},"stress_scenario_code":"RECESSION_ENERGY","window_days":[7,30,60,90,180]}'::jsonb
FROM msbf_ctl.run_registry r
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
ON CONFLICT(profile_code,profile_version) DO UPDATE SET
    business_name=EXCLUDED.business_name,
    effective_start_date=EXCLUDED.effective_start_date,
    effective_end_date=EXCLUDED.effective_end_date,
    status='APPROVED',owner_role=EXCLUDED.owner_role,
    approver_role=EXCLUDED.approver_role,
    approval_timestamp=coalesce(msbf_ctl.policy_profile.approval_timestamp,EXCLUDED.approval_timestamp),
    last_review_date=EXCLUDED.last_review_date,
    next_review_date=EXCLUDED.next_review_date,
    change_reason=EXCLUDED.change_reason,
    policy_domain=EXCLUDED.policy_domain,
    product_structure_profile_id=EXCLUDED.product_structure_profile_id,
    operating_model_profile_id=EXCLUDED.operating_model_profile_id,
    parameter_set_id=EXCLUDED.parameter_set_id,
    profile_payload=EXCLUDED.profile_payload;

COMMIT;

UPDATE msbf_m1.feature_definition
SET formula_description='Persisted two-decimal trailing ninety-day average daily eligible sales multiplied by the governed annualization-day parameter and rounded to two decimals.',
    production_boundary='Synthetic as-of cash-flow feature; not production-calibrated. Annualization is derived from the persisted rounded 90-day average.'
WHERE feature_code='ANNUALIZED_ELIGIBLE_SALES' AND feature_version=1;

WITH p AS (
    SELECT policy_profile_id,status,profile_payload
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_9_ASOF_CASHFLOW_FEATURE_ENGINEERING' AND profile_version=1
), f AS (
    SELECT count(*) AS active_features
    FROM msbf_m1.feature_definition
    WHERE feature_code IN ('AVG_DAILY_ELIGIBLE_SALES_7D','AVG_DAILY_ELIGIBLE_SALES_30D','AVG_DAILY_ELIGIBLE_SALES_60D','AVG_DAILY_ELIGIBLE_SALES_90D','ANNUALIZED_ELIGIBLE_SALES','SALES_GROWTH_7D_VS_30D','SALES_GROWTH_30D_VS_90D','DAILY_SALES_CV_30D','DAILY_SALES_CV_90D','ZERO_SALES_DAY_RATE_30D','ACTIVE_SALES_DAY_RATE_30D','SEASONALITY_INDEX_180D','LARGEST_30D_SHARE_180D','REFUND_RATE_30D','CHARGEBACK_RATE_30D','REVERSAL_RATE_30D','DEPOSIT_TO_ELIGIBLE_SALES_RATE_30D','POS_DEPOSIT_RECONCILIATION_RATE_30D','NEGATIVE_BALANCE_DAY_RATE_30D','NSF_COUNT_30D','AVERAGE_AVAILABLE_BALANCE_30D','MINIMUM_BALANCE_30D','CASH_FLOW_BUFFER_DAYS','PROCESSOR_OUTAGE_DAY_RATE_30D','PROCESSOR_DEGRADED_DAY_RATE_30D','SOURCE_CONFIDENCE_SCORE','SCENARIO_ELIGIBLE_SALES_DELTA_RATE_30D','SCENARIO_ELIGIBLE_SALES_DELTA_RATE_90D','SCENARIO_DEPOSIT_DELTA_RATE_30D','SCENARIO_WITHDRAWAL_DELTA_RATE_30D','SCENARIO_AVAILABLE_BALANCE_DELTA_RATE_30D','SCENARIO_NEGATIVE_BALANCE_RATE_DELTA_30D','SCENARIO_NSF_COUNT_DELTA_30D','SCENARIO_PROCESSOR_OUTAGE_RATE_DELTA_30D','SCENARIO_REFUND_RATE_DELTA_30D','SCENARIO_CHARGEBACK_RATE_DELTA_30D')
      AND feature_version=1 AND active_flag
)
SELECT
    to_regclass('msbf_m1.application_cashflow_feature_snapshot') IS NOT NULL AS snapshot_table_exists,
    to_regclass('msbf_m1.cashflow_feature_value') IS NOT NULL AS feature_value_table_exists,
    (SELECT active_features FROM f) AS active_m1_9_feature_definitions,
    p.policy_profile_id,p.status AS policy_status,
    p.profile_payload->>'methodology_version' AS methodology_version,
    CASE WHEN to_regclass('msbf_m1.application_cashflow_feature_snapshot') IS NOT NULL
           AND to_regclass('msbf_m1.cashflow_feature_value') IS NOT NULL
           AND (SELECT active_features FROM f)=36
           AND p.status='APPROVED'
         THEN 'PASS' ELSE 'FAIL' END AS extension_status
FROM p;
