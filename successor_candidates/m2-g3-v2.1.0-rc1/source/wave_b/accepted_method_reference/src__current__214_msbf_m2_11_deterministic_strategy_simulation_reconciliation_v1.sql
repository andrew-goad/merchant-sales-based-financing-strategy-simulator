/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.11 — Portfolio Optimization & Strategy Simulation

Program     : 214_msbf_m2_11_deterministic_strategy_simulation_reconciliation_v1.sql
Revision    : WP2_IMPLEMENTATION_CORRECTION_R3
Methodology : M2_11_METHOD_V1
Contract    : M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION v1
Schema      : M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1

Purpose
-------
Materialize every authorized accepted source object once; persist immutable accepted-source snapshots; evaluate the frozen candidate inventory across eight strategies; create application and account counterfactual simulations; aggregate three scopes; calculate stress, Pareto, and governance evidence; populate latest/archive/registry; reconcile exact counts and ordered hashes; and advance only to M2_11_GENERATED.

Stage boundary
--------------
Program 214 is the sole normal M2.11 writer of simulation business rows. It runs as one atomic transaction, consumes target-typed temporary construction relations throughout the business graph, preserves the non-production boundary, inserts 24 generation evidence rows, and fails closed on any committed version-1 state or deterministic reconciliation defect.

Required result
---------------
Exactly 19,237 non-definition canonical rows plus the existing 61 definition rows = 19,298 canonical entities; 24 generation evidence rows; lifecycle M2_11_GENERATED.

Execution control
-----------------
Execute as one PostgreSQL script. Stop at the first error. Do not execute any
recovery program unless the failed state has first been diagnosed. This source
is STATICALLY BUILT, NOT EXECUTED, NOT VALIDATED, NOT ACCEPTED, and
NOT AUTHORIZED FOR EXECUTION pending explicit WP2 approval.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='120min';
SET LOCAL idle_in_transaction_session_timeout='125min';
SET LOCAL jit=off;

/* ============================================================================
Section 1 — One-time governed-run materialization, lock, and fail-closed guard
The governed run is read exactly once into staging and locked in the same
statement. Later run_registry access is limited to the authorized lifecycle
UPDATE; downstream evaluation reads tmp_src_run_registry only.
============================================================================ */
CREATE TEMP TABLE tmp_src_run_registry
(
    run_id bigint NOT NULL,
    run_code text NOT NULL,
    run_version integer NOT NULL,
    module_code text NOT NULL,
    run_type text NOT NULL,
    as_of_date date NOT NULL,
    run_status text NOT NULL,
    started_at timestamptz,
    completed_at timestamptz,
    row_count bigint,
    source_snapshot_hash text,
    code_version text NOT NULL,
    notes text,
    created_at timestamptz NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_src_run_registry
(
    run_id,run_code,run_version,module_code,run_type,as_of_date,run_status,
    started_at,completed_at,row_count,source_snapshot_hash,code_version,notes,created_at
)
SELECT
    run_id,run_code,run_version,module_code,run_type,as_of_date,run_status,
    started_at,completed_at,row_count,source_snapshot_hash,code_version,notes,created_at
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
FOR UPDATE;

DO $m211$
DECLARE
    v_run_id bigint;
    v_status text;
    v_n bigint;
BEGIN
    SELECT run_id,run_status INTO STRICT v_run_id,v_status
    FROM tmp_src_run_registry;
    IF v_status<>'M2_10_ACCEPTED' THEN
        RAISE EXCEPTION 'Program 214 requires M2_10_ACCEPTED; found %',v_status;
    END IF;

    IF EXISTS
    (
        SELECT 1 FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
        WHERE module1_run_id=v_run_id AND contract_version=1
    ) OR EXISTS
    (
        SELECT 1 FROM msbf_m2.portfolio_strategy_simulation_latest
        WHERE module1_run_id=v_run_id
    ) OR EXISTS
    (
        SELECT 1 FROM msbf_m2.portfolio_strategy_simulation_archive
        WHERE module1_run_id=v_run_id AND contract_version=1
    ) THEN
        RAISE EXCEPTION 'Committed M2.11 contract version 1 state exists; rerun prohibited';
    END IF;

    SELECT count(*) INTO v_n FROM
    (
      SELECT count(*) n,1 e FROM msbf_ctl.m2_11_policy_profile WHERE module1_run_id=v_run_id
      UNION ALL SELECT count(*),8 FROM msbf_m2.portfolio_strategy_profile WHERE module1_run_id=v_run_id
      UNION ALL SELECT count(*),8 FROM msbf_m2.portfolio_strategy_objective_definition WHERE module1_run_id=v_run_id
      UNION ALL SELECT count(*),12 FROM msbf_m2.portfolio_strategy_constraint_definition WHERE module1_run_id=v_run_id
      UNION ALL SELECT count(*),32 FROM msbf_m2.portfolio_strategy_reason_definition WHERE module1_run_id=v_run_id
    ) d WHERE n<>e;
    IF v_n<>0 THEN RAISE EXCEPTION 'Program 214 definition prerequisite mismatch'; END IF;

    SELECT count(*) INTO v_n FROM
    (
      SELECT module1_run_id FROM msbf_m2.portfolio_strategy_application_source_snapshot
      UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_candidate_source_snapshot
      UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_account_source_snapshot
      UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_kpi_source_snapshot
      UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_queue_source_snapshot
      UNION ALL SELECT module1_run_id FROM msbf_m2.application_strategy_candidate_evaluation
      UNION ALL SELECT module1_run_id FROM msbf_m2.application_portfolio_strategy_simulation
      UNION ALL SELECT module1_run_id FROM msbf_m2.account_servicing_strategy_simulation
      UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_summary
      UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_frontier
      UNION ALL SELECT module1_run_id FROM msbf_m2.portfolio_strategy_comparison
    ) b;
    IF v_n<>0 THEN RAISE EXCEPTION 'Program 214 requires pristine generation targets; found % rows',v_n; END IF;

    IF EXISTS
    (
      SELECT 1 FROM msbf_ctl.run_evidence
      WHERE run_id=v_run_id AND evidence_code LIKE 'M2_11_GENERATION_%'
    ) THEN RAISE EXCEPTION 'M2.11 generation evidence already exists'; END IF;
END;
$m211$;

/* ============================================================================
Section 2 — Remaining one-time physical accepted-source materialization
The governed run was staged and locked in Section 1. Every other authorized
physical source object is scanned exactly once here. After the
END_ACCEPTED_SOURCE_SCANS marker, no accepted physical source object is read as
a business source; run_registry is referenced only by the authorized final
lifecycle UPDATE.
============================================================================ */

CREATE TEMP TABLE tmp_src_acceptance_gate_result ON COMMIT DROP AS
SELECT
    run_id,
    gate_id,
    review_version,
    result_status,
    observed_value,
    threshold_value,
    finding,
    residual_limitation,
    reviewer_role,
    reviewed_at
FROM msbf_ctl.acceptance_gate_result
WHERE run_id=(SELECT run_id FROM tmp_src_run_registry) AND gate_id IN ('G2_M1_CONTRACT','M2_2_PRICING_STRUCTURE_COUNTEROFFER','M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION','M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP','M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS');

CREATE TEMP TABLE tmp_src_m2_10_registry ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    kpi_snapshot_rows,
    queue_summary_rows,
    latest_rows,
    portfolio_account_rows,
    baseline_account_rows,
    stress_account_rows,
    closed_stable_rows,
    active_reconciled_rows,
    controlled_review_rows,
    certified_account_rows,
    certification_rate,
    certified_exposure_amount,
    active_exposure_amount,
    review_hold_exposure_amount,
    unresolved_exception_count,
    servicing_burden_units,
    kpi_snapshot_set_hash,
    queue_summary_set_hash,
    latest_set_hash,
    combined_set_hash,
    contract_status,
    row_hash
FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_10_latest ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    merchant_id,
    synthetic_account_id,
    synthetic_advance_id,
    source_final_lifecycle_state_code,
    certified_state_code,
    state_certified_flag,
    performance_tier_code,
    servicing_queue_code,
    payment_activity_flag,
    exception_incident_flag,
    exception_resolved_flag,
    payment_event_count,
    settled_event_count,
    returned_event_count,
    retry_event_count,
    exception_case_count,
    resolved_exception_count,
    unresolved_exception_count,
    source_exposure_amount,
    certified_exposure_amount,
    scheduled_payment_amount,
    processed_payment_amount,
    returned_payment_amount,
    retry_payment_amount,
    reconciliation_variance_amount,
    exposure_variance_amount,
    gross_collection_rate,
    return_rate,
    retry_cure_rate,
    exposure_retention_rate,
    servicing_burden_units,
    primary_portfolio_reason_code,
    portfolio_reason_codes,
    source_contract_row_hash,
    source_snapshot_row_hash,
    performance_snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash,
    created_at
FROM msbf_m2.application_portfolio_performance_latest
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_10_kpi ON COMMIT DROP AS
SELECT
    module1_run_id,
    scope_code,
    scope_type,
    scenario_code,
    kpi_code,
    kpi_rank,
    unit_code,
    applicable_flag,
    kpi_value_numeric,
    kpi_value_text,
    numerator_value,
    denominator_value,
    primary_portfolio_reason_code,
    source_scope_row_hash,
    row_hash,
    created_at
FROM msbf_m2.portfolio_kpi_snapshot
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_10_queue ON COMMIT DROP AS
SELECT
    module1_run_id,
    servicing_queue_code,
    account_count,
    scenario_count,
    certified_exposure_amount,
    payment_event_count,
    exception_case_count,
    resolved_exception_count,
    unresolved_exception_count,
    servicing_burden_units,
    maximum_tier_rank,
    row_hash,
    created_at
FROM msbf_m2.servicing_queue_analytics_snapshot
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m1_17_g2_registry ON COMMIT DROP AS
SELECT
    module1_run_id,
    bundle_code,
    bundle_version,
    schema_version,
    methodology_version,
    integrated_consumption_rows,
    bundle_latest_set_hash,
    combined_g2_hash,
    bundle_status,
    row_hash
FROM msbf_ctl.m1_17_g2_bundle_registry
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m1_17_integrated ON COMMIT DROP AS
SELECT
    accepted_m1_14_acquisition_cost_amount,
    acquisition_contract_evidence_status,
    affordability_status,
    annualized_risk_adjusted_return_rate,
    archetype_code,
    as_of_date,
    assisted_touch_count,
    attribution_confidence_score,
    attribution_confidence_tier,
    attribution_evidence_status,
    average_available_balance_30d,
    avg_daily_eligible_sales_30d,
    capacity_tier,
    channel_type,
    cost_evidence_status,
    data_confidence_tier,
    detailed_conditional_partner_broker_cost_amount,
    detailed_total_acquisition_cost_if_booked,
    direct_attributable_incurred_cost_amount,
    economic_status,
    economic_tier,
    enhanced_total_acquisition_cost_if_booked,
    fraud_risk_tier,
    hard_stop_recommended_flag,
    identified_legacy_overlap_amount,
    incremental_acquisition_cost_beyond_m1_14,
    industry_code,
    integrated_risk_score,
    integrated_risk_tier,
    internally_allocated_acquisition_cost_amount,
    lgd_input_rate,
    m1_15_contract_evidence_status,
    m1_15_contract_row_hash,
    m1_16_contract_row_hash,
    manual_review_recommended_flag,
    merchant_application_id,
    merchant_id,
    merchant_size_tier,
    module1_run_id,
    operating_resilience_score,
    overlap_evidence_status,
    partner_channel_id,
    path_weighted_ead_amount,
    population_id,
    primary_campaign_id,
    primary_source_code,
    processor_continuity_status,
    relationship_stage,
    resilience_tier,
    risk_adjusted_contribution_amount,
    scenario_code,
    scenario_id,
    schedule_adjusted_comparative_expected_loss_amount,
    source_confidence_score,
    synthetic_merchant_risk_proxy,
    total_incurred_pre_application_cost_amount,
    touchpoint_count,
    unmapped_legacy_proxy_amount,
    verification_disposition
FROM msbf_m1.v_m1_17_g2_integrated_consumption
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_2_registry ON COMMIT DROP AS
SELECT
    module1_run_id,
    pricing_contract_code,
    pricing_contract_version,
    pricing_schema_version,
    methodology_version,
    candidate_rows,
    pricing_latest_rows,
    candidate_set_hash,
    pricing_latest_set_hash,
    combined_set_hash,
    contract_status,
    row_hash
FROM msbf_ctl.m2_2_pricing_structure_contract_registry
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_2_latest ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_route_code,
    source_route_rank,
    pricing_disposition_code,
    structure_available_flag,
    review_required_flag,
    selected_candidate_template_code,
    selected_candidate_row_hash,
    requested_funding_amount,
    selected_funding_amount,
    selected_remittance_rate,
    selected_payback_multiple,
    selected_collection_horizon_days,
    selected_total_repayment_amount,
    selected_finance_charge_amount,
    selected_implied_daily_collection_amount,
    selected_implied_payoff_days,
    selected_amount_to_request_ratio,
    candidate_count,
    counteroffer_foundation_flag,
    stress_nonimprovement_applied_flag,
    primary_reason_code,
    reason_codes,
    routing_evidence_status,
    source_m2_1_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    policy_configuration_hash,
    source_snapshot_row_hash,
    contract_row_hash,
    created_at
FROM msbf_m2.application_pricing_structure_latest
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_2_candidate ON COMMIT DROP AS
SELECT
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    candidate_template_code,
    template_sequence,
    source_route_code,
    source_route_rank,
    requested_funding_amount,
    candidate_funding_amount,
    candidate_remittance_rate,
    candidate_payback_multiple,
    candidate_collection_horizon_days,
    candidate_total_repayment_amount,
    candidate_finance_charge_amount,
    implied_daily_collection_amount,
    implied_payoff_days,
    amount_to_request_ratio,
    capacity_alignment_ratio,
    risk_load_rate,
    resilience_load_rate,
    economic_load_rate,
    stress_load_rate,
    acquisition_economics_amount,
    expected_loss_amount,
    risk_adjusted_contribution_amount,
    annualized_return_rate,
    counteroffer_foundation_flag,
    candidate_eligible_flag,
    selected_foundation_flag,
    candidate_rank,
    primary_reason_code,
    secondary_reason_codes,
    source_m2_1_contract_row_hash,
    source_request_contract_row_hash,
    source_m1_15_contract_row_hash,
    source_m1_16_contract_row_hash,
    source_g2_combined_hash,
    policy_configuration_hash,
    row_hash,
    created_at
FROM msbf_m2.application_pricing_structure_candidate
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_4_registry ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    activation_latest_rows,
    activation_latest_set_hash,
    combined_set_hash,
    contract_status,
    row_hash
FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_4_latest ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_final_decision_outcome_code,
    activation_outcome_code,
    activation_outcome_rank,
    booking_eligible_flag,
    booking_authorized_flag,
    funding_authorized_flag,
    funding_completed_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    synthetic_offer_acceptance_assumed_flag,
    real_funds_movement_flag,
    external_notice_generation_authorized_flag,
    external_notice_transmitted_flag,
    production_adverse_action_notice_flag,
    synthetic_account_id,
    synthetic_advance_id,
    booked_amount,
    funded_amount,
    activation_remittance_rate,
    activation_payback_multiple,
    activation_collection_horizon_days,
    activation_total_repayment_amount,
    activation_finance_charge_amount,
    activation_implied_daily_collection_amount,
    activation_implied_payoff_days,
    booking_date,
    funding_date,
    portfolio_activation_date,
    first_expected_remittance_date,
    monitoring_start_date,
    activation_evidence_status,
    notice_control_code,
    primary_activation_reason_code,
    activation_reason_codes,
    source_m2_3_contract_row_hash,
    source_m2_2_contract_row_hash,
    source_g2_combined_hash,
    source_snapshot_row_hash,
    snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash,
    created_at
FROM msbf_m2.application_booking_funding_activation_latest
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_7_registry ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    latest_rows,
    latest_set_hash,
    combined_set_hash,
    contract_status,
    row_hash
FROM msbf_ctl.m2_7_operational_activation_contract_registry
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

CREATE TEMP TABLE tmp_src_m2_7_latest ON COMMIT DROP AS
SELECT
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    scenario_id,
    scenario_code,
    merchant_application_id,
    merchant_id,
    synthetic_account_id,
    synthetic_advance_id,
    source_strategy_outcome_code,
    source_servicing_action_code,
    source_recommended_action_exposure_amount,
    operational_setup_outcome_code,
    operational_setup_action_code,
    operational_setup_priority_rank,
    operational_setup_queue_code,
    account_setup_status_code,
    setup_authorized_flag,
    blueprint_created_flag,
    setup_review_required_flag,
    no_setup_required_flag,
    synthetic_operational_case_id,
    synthetic_account_setup_id,
    synthetic_servicing_plan_id,
    operational_activation_date,
    next_reassessment_date,
    applied_temporary_payment_factor,
    applied_setup_duration_days,
    applied_reassessment_interval_days,
    primary_setup_reason_code,
    setup_reason_codes,
    setup_parameter_payload,
    source_contract_row_hash,
    source_snapshot_row_hash,
    activation_snapshot_row_hash,
    account_setup_snapshot_row_hash,
    policy_configuration_hash,
    contract_row_hash,
    created_at
FROM msbf_m2.application_operational_activation_latest
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);


/* END_ACCEPTED_SOURCE_SCANS */

/* ============================================================================
Section 3 — Staging indexes and statistics
============================================================================ */
CREATE UNIQUE INDEX tmp_src_run_registry_u1 ON tmp_src_run_registry(run_id);
CREATE INDEX tmp_src_gate_i1 ON tmp_src_acceptance_gate_result(run_id,gate_id,review_version DESC);
CREATE UNIQUE INDEX tmp_src_m210_registry_u1 ON tmp_src_m2_10_registry(module1_run_id);
CREATE UNIQUE INDEX tmp_src_m210_latest_u1 ON tmp_src_m2_10_latest(module1_run_id,scenario_id,merchant_application_id);
CREATE INDEX tmp_src_m210_latest_i2 ON tmp_src_m2_10_latest(module1_run_id,merchant_application_id,scenario_code);
CREATE UNIQUE INDEX tmp_src_m210_kpi_u1 ON tmp_src_m2_10_kpi(module1_run_id,scope_code,kpi_code);
CREATE UNIQUE INDEX tmp_src_m210_queue_u1 ON tmp_src_m2_10_queue(module1_run_id,servicing_queue_code);
CREATE UNIQUE INDEX tmp_src_m117_registry_u1 ON tmp_src_m1_17_g2_registry(module1_run_id);
CREATE UNIQUE INDEX tmp_src_m117_integrated_u1 ON tmp_src_m1_17_integrated(module1_run_id,scenario_id,merchant_application_id);
CREATE INDEX tmp_src_m117_integrated_i2 ON tmp_src_m1_17_integrated(module1_run_id,merchant_application_id,scenario_code);
CREATE UNIQUE INDEX tmp_src_m22_registry_u1 ON tmp_src_m2_2_registry(module1_run_id);
CREATE UNIQUE INDEX tmp_src_m22_latest_u1 ON tmp_src_m2_2_latest(module1_run_id,scenario_id,merchant_application_id);
CREATE UNIQUE INDEX tmp_src_m22_candidate_u1 ON tmp_src_m2_2_candidate(module1_run_id,scenario_id,merchant_application_id,candidate_template_code);
CREATE INDEX tmp_src_m22_candidate_i2 ON tmp_src_m2_2_candidate(module1_run_id,scenario_id,merchant_application_id,candidate_rank,candidate_template_code);
CREATE UNIQUE INDEX tmp_src_m24_registry_u1 ON tmp_src_m2_4_registry(module1_run_id);
CREATE UNIQUE INDEX tmp_src_m24_latest_u1 ON tmp_src_m2_4_latest(module1_run_id,scenario_id,merchant_application_id);
CREATE UNIQUE INDEX tmp_src_m27_registry_u1 ON tmp_src_m2_7_registry(module1_run_id);
CREATE UNIQUE INDEX tmp_src_m27_latest_u1 ON tmp_src_m2_7_latest(module1_run_id,scenario_id,merchant_application_id);

ANALYZE tmp_src_run_registry;
ANALYZE tmp_src_acceptance_gate_result;
ANALYZE tmp_src_m2_10_registry;
ANALYZE tmp_src_m2_10_latest;
ANALYZE tmp_src_m2_10_kpi;
ANALYZE tmp_src_m2_10_queue;
ANALYZE tmp_src_m1_17_g2_registry;
ANALYZE tmp_src_m1_17_integrated;
ANALYZE tmp_src_m2_2_registry;
ANALYZE tmp_src_m2_2_latest;
ANALYZE tmp_src_m2_2_candidate;
ANALYZE tmp_src_m2_4_registry;
ANALYZE tmp_src_m2_4_latest;
ANALYZE tmp_src_m2_7_registry;
ANALYZE tmp_src_m2_7_latest;

/* ============================================================================
Section 4 — Staged accepted-source identity, gate, count, grain, hash, and join guard
============================================================================ */
DO $m211$
DECLARE
    v_run_id bigint;
    v_n bigint;
BEGIN
    IF (SELECT count(*) FROM tmp_src_run_registry)<>1 THEN
      RAISE EXCEPTION 'Exactly one governed run row must be staged';
    END IF;
    SELECT run_id INTO STRICT v_run_id FROM tmp_src_run_registry;
    IF (SELECT run_status FROM tmp_src_run_registry)<>'M2_10_ACCEPTED' THEN RAISE EXCEPTION 'Staged run status mismatch'; END IF;

    IF (SELECT count(*) FROM tmp_src_m1_17_g2_registry)<>1
       OR (SELECT count(*) FROM tmp_src_m2_2_registry)<>1
       OR (SELECT count(*) FROM tmp_src_m2_4_registry)<>1
       OR (SELECT count(*) FROM tmp_src_m2_7_registry)<>1
       OR (SELECT count(*) FROM tmp_src_m2_10_registry)<>1 THEN
      RAISE EXCEPTION 'Exactly one accepted registry row is required for each staged source family';
    END IF;

    IF NOT EXISTS
    (
      SELECT 1 FROM tmp_src_m1_17_g2_registry
      WHERE bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND bundle_version=1
        AND schema_version='M1_G2_BUNDLE_SCHEMA_V1' AND methodology_version='M1_17_METHOD_V1'
        AND bundle_status='ACCEPTED' AND integrated_consumption_rows=1500
        AND combined_g2_hash='7d9e466da28cad2551aa99c4c40c912b'
        AND bundle_latest_set_hash~'^[0-9a-f]{32}$' AND row_hash~'^[0-9a-f]{32}$'
    ) THEN RAISE EXCEPTION 'Staged M1.17 identity mismatch'; END IF;

    IF NOT EXISTS
    (
      SELECT 1 FROM tmp_src_m2_2_registry
      WHERE pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND pricing_contract_version=1
        AND pricing_schema_version='M2_2_PRICING_STRUCTURE_SCHEMA_V1' AND methodology_version='M2_2_METHOD_V1'
        AND contract_status='ACCEPTED' AND pricing_latest_rows=1500 AND candidate_rows=557
        AND combined_set_hash='bbe83b187b31ea561789797322031fc6'
        AND candidate_set_hash~'^[0-9a-f]{32}$' AND pricing_latest_set_hash~'^[0-9a-f]{32}$'
        AND row_hash~'^[0-9a-f]{32}$'
    ) THEN RAISE EXCEPTION 'Staged M2.2 identity mismatch'; END IF;

    IF NOT EXISTS
    (
      SELECT 1 FROM tmp_src_m2_4_registry
      WHERE contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND contract_version=1
        AND schema_version='M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1' AND methodology_version='M2_4_METHOD_V1'
        AND contract_status='ACCEPTED' AND activation_latest_rows=1500
        AND combined_set_hash='117450a3eea7bb3d3c74d18cc3c8e96a'
        AND activation_latest_set_hash~'^[0-9a-f]{32}$' AND row_hash~'^[0-9a-f]{32}$'
    ) THEN RAISE EXCEPTION 'Staged M2.4 identity mismatch'; END IF;

    IF NOT EXISTS
    (
      SELECT 1 FROM tmp_src_m2_7_registry
      WHERE contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND contract_version=1
        AND schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1' AND methodology_version='M2_7_METHOD_V1'
        AND contract_status='ACCEPTED' AND latest_rows=59
        AND combined_set_hash='c8e3a472afd2a16b1183677324e9db98'
        AND latest_set_hash~'^[0-9a-f]{32}$' AND row_hash~'^[0-9a-f]{32}$'
    ) THEN RAISE EXCEPTION 'Staged M2.7 identity mismatch'; END IF;

    IF NOT EXISTS
    (
      SELECT 1 FROM tmp_src_m2_10_registry
      WHERE contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND contract_version=1
        AND schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'
        AND methodology_version='M2_10_METHOD_V1' AND contract_status='ACCEPTED'
        AND latest_rows=59 AND kpi_snapshot_rows=72 AND queue_summary_rows=3
        AND portfolio_account_rows=59 AND baseline_account_rows=44 AND stress_account_rows=15
        AND closed_stable_rows=57 AND active_reconciled_rows=1 AND controlled_review_rows=1
        AND certified_account_rows=59 AND certification_rate=1.000000::numeric
        AND certified_exposure_amount=785.48::numeric AND active_exposure_amount=323.79::numeric
        AND review_hold_exposure_amount=461.69::numeric AND unresolved_exception_count=0
        AND servicing_burden_units=7.000000::numeric
        AND combined_set_hash='24fca7263a04397ebf21d30639f9069b'
        AND kpi_snapshot_set_hash~'^[0-9a-f]{32}$'
        AND queue_summary_set_hash~'^[0-9a-f]{32}$'
        AND latest_set_hash~'^[0-9a-f]{32}$' AND row_hash~'^[0-9a-f]{32}$'
    ) THEN RAISE EXCEPTION 'Staged M2.10 identity or frozen posture mismatch'; END IF;

    WITH required(gate_id) AS
    (
      VALUES ('G2_M1_CONTRACT'),('M2_2_PRICING_STRUCTURE_COUNTEROFFER'),
             ('M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'),
             ('M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'),
             ('M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS')
    ), latest_gate AS
    (
      SELECT DISTINCT ON(gate_id) gate_id,result_status
      FROM tmp_src_acceptance_gate_result
      ORDER BY gate_id,review_version DESC
    )
    SELECT count(*) INTO v_n
    FROM required r LEFT JOIN latest_gate g USING(gate_id)
    WHERE g.gate_id IS NULL OR g.result_status<>'PASS';
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged predecessor gate mismatch count %',v_n; END IF;

    IF (SELECT count(*) FROM tmp_src_m1_17_integrated)<>1500
       OR (SELECT count(*) FROM tmp_src_m2_2_latest)<>1500
       OR (SELECT count(*) FROM tmp_src_m2_2_candidate)<>557
       OR (SELECT count(*) FROM tmp_src_m2_4_latest)<>1500
       OR (SELECT count(*) FROM tmp_src_m2_7_latest)<>59
       OR (SELECT count(*) FROM tmp_src_m2_10_latest)<>59
       OR (SELECT count(*) FROM tmp_src_m2_10_kpi)<>72
       OR (SELECT count(*) FROM tmp_src_m2_10_queue)<>3 THEN
      RAISE EXCEPTION 'Staged source count mismatch';
    END IF;

    SELECT count(*) INTO v_n
    FROM
    (
      SELECT module1_run_id,merchant_application_id,count(*) AS total_rows,
             count(*) FILTER(WHERE scenario_code='BASELINE') AS baseline_rows,
             count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_rows
      FROM tmp_src_m1_17_integrated
      GROUP BY module1_run_id,merchant_application_id
    ) paired
    WHERE total_rows<>2 OR baseline_rows<>1 OR stress_rows<>1;
    IF v_n<>0
       OR (SELECT count(*) FROM tmp_src_m1_17_integrated WHERE scenario_code='BASELINE')<>750
       OR (SELECT count(*) FROM tmp_src_m1_17_integrated WHERE scenario_code='RECESSION_ENERGY')<>750
       OR (SELECT count(DISTINCT merchant_application_id) FROM tmp_src_m1_17_integrated)<>750 THEN
      RAISE EXCEPTION 'Staged application scenario pairing must equal 750 BASELINE + 750 RECESSION_ENERGY matched applications';
    END IF;

    SELECT count(*) INTO v_n
    FROM tmp_src_m1_17_integrated g
    FULL JOIN tmp_src_m2_2_latest p USING(module1_run_id,scenario_id,merchant_application_id)
    FULL JOIN tmp_src_m2_4_latest a USING(module1_run_id,scenario_id,merchant_application_id)
    WHERE g.module1_run_id IS NULL OR p.module1_run_id IS NULL OR a.module1_run_id IS NULL
       OR g.scenario_code<>p.scenario_code OR g.scenario_code<>a.scenario_code
       OR g.population_id<>p.population_id OR g.population_id<>a.population_id
       OR g.merchant_id<>p.merchant_id OR g.merchant_id<>a.merchant_id
       OR g.as_of_date<>p.as_of_date OR g.as_of_date<>a.as_of_date;
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged application one-to-one mismatch count %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM tmp_src_m2_7_latest o
    FULL JOIN tmp_src_m2_10_latest m
      USING(module1_run_id,scenario_id,merchant_application_id,merchant_id,synthetic_account_id,synthetic_advance_id)
    WHERE o.module1_run_id IS NULL OR m.module1_run_id IS NULL OR o.scenario_code<>m.scenario_code;
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged account one-to-one mismatch count %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM tmp_src_m2_2_latest p
    LEFT JOIN tmp_src_m2_2_candidate c
      ON c.module1_run_id=p.module1_run_id AND c.scenario_id=p.scenario_id
     AND c.merchant_application_id=p.merchant_application_id
     AND c.candidate_template_code=p.selected_candidate_template_code
     AND c.row_hash=p.selected_candidate_row_hash
    WHERE p.selected_candidate_template_code IS NOT NULL AND c.candidate_template_code IS NULL;
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged selected-candidate inventory mismatch count %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM tmp_src_m2_2_latest p
    LEFT JOIN
    (
      SELECT module1_run_id,scenario_id,merchant_application_id,count(*) AS candidate_rows
      FROM tmp_src_m2_2_candidate
      GROUP BY module1_run_id,scenario_id,merchant_application_id
    ) c USING(module1_run_id,scenario_id,merchant_application_id)
    WHERE (p.structure_available_flag AND coalesce(c.candidate_rows,0)<>p.candidate_count)
       OR (NOT p.structure_available_flag AND coalesce(c.candidate_rows,0)<>0)
       OR (NOT p.structure_available_flag AND
           (p.selected_candidate_template_code IS NOT NULL OR p.selected_candidate_row_hash IS NOT NULL OR p.candidate_count<>0));
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged M2.2 candidate population/count mismatch count %',v_n; END IF;

    SELECT count(*) INTO v_n
    FROM tmp_src_m2_10_latest s
    LEFT JOIN tmp_src_m2_10_latest b
      ON b.module1_run_id=s.module1_run_id AND b.merchant_application_id=s.merchant_application_id
     AND b.scenario_code='BASELINE'
    WHERE s.scenario_code='RECESSION_ENERGY' AND b.merchant_application_id IS NULL;
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged stress accounts lacking baseline account matches %',v_n; END IF;

    IF (SELECT count(*) FROM tmp_src_m2_10_latest WHERE scenario_code='BASELINE')<>44
       OR (SELECT count(*) FROM tmp_src_m2_10_latest WHERE scenario_code='RECESSION_ENERGY')<>15
       OR (SELECT count(DISTINCT merchant_application_id) FROM tmp_src_m2_10_latest)<>44 THEN
      RAISE EXCEPTION 'Staged operational-account scope coverage mismatch';
    END IF;

    SELECT count(*) INTO v_n
    FROM
    (
      SELECT
        scope_code,
        scope_type,
        scenario_code,
        count(*)::bigint AS kpi_rows,
        count(DISTINCT kpi_code)::bigint AS kpi_codes
      FROM tmp_src_m2_10_kpi
      GROUP BY scope_code,scope_type,scenario_code
    ) s
    FULL JOIN
    (
      VALUES
        ('BASELINE'::text,'SCENARIO'::text,'BASELINE'::text,24::bigint,24::bigint),
        ('RECESSION_ENERGY'::text,'SCENARIO'::text,'RECESSION_ENERGY'::text,24::bigint,24::bigint),
        ('PORTFOLIO_ALL'::text,'PORTFOLIO'::text,NULL::text,24::bigint,24::bigint)
    ) e(scope_code,scope_type,scenario_code,kpi_rows,kpi_codes)
      ON s.scope_code=e.scope_code
     AND s.scope_type=e.scope_type
     AND s.scenario_code IS NOT DISTINCT FROM e.scenario_code
    WHERE s.scope_code IS NULL
       OR e.scope_code IS NULL
       OR s.kpi_rows IS DISTINCT FROM e.kpi_rows
       OR s.kpi_codes IS DISTINCT FROM e.kpi_codes;
    IF v_n<>0
       OR (SELECT count(*) FROM tmp_src_m2_10_kpi)<>72
       OR (SELECT count(DISTINCT scope_code) FROM tmp_src_m2_10_kpi)<>3
       OR (SELECT count(DISTINCT kpi_code) FROM tmp_src_m2_10_kpi)<>24 THEN
      RAISE EXCEPTION 'Staged M2.10 KPI source coverage must be BASELINE/SCENARIO/BASELINE, RECESSION_ENERGY/SCENARIO/RECESSION_ENERGY, and PORTFOLIO_ALL/PORTFOLIO/NULL with 24 KPI codes each';
    END IF;

    IF (SELECT coalesce(sum(account_count),0) FROM tmp_src_m2_10_queue)<>59 THEN
      RAISE EXCEPTION 'Staged M2.10 queue account total must equal 59';
    END IF;

    SELECT count(*) INTO v_n FROM tmp_src_m1_17_integrated
    WHERE m1_15_contract_row_hash!~'^[0-9a-f]{32}$' OR m1_16_contract_row_hash!~'^[0-9a-f]{32}$';
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged M1.17 source row-hash shape failures %',v_n; END IF;

    SELECT count(*) INTO v_n FROM tmp_src_m2_2_latest
    WHERE contract_row_hash!~'^[0-9a-f]{32}$' OR source_snapshot_row_hash!~'^[0-9a-f]{32}$'
       OR source_g2_combined_hash!~'^[0-9a-f]{32}$'
       OR source_g2_combined_hash<>'e5ace7f32060ffb191c7bd0f8dd0c863'
       OR (selected_candidate_row_hash IS NOT NULL AND selected_candidate_row_hash!~'^[0-9a-f]{32}$');
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged M2.2 latest row-hash shape failures %',v_n; END IF;

    SELECT count(*) INTO v_n FROM tmp_src_m2_2_candidate
    WHERE row_hash!~'^[0-9a-f]{32}$' OR source_m1_15_contract_row_hash!~'^[0-9a-f]{32}$'
       OR source_m1_16_contract_row_hash!~'^[0-9a-f]{32}$'
       OR source_g2_combined_hash!~'^[0-9a-f]{32}$'
       OR source_g2_combined_hash<>'e5ace7f32060ffb191c7bd0f8dd0c863';
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged M2.2 candidate row-hash shape failures %',v_n; END IF;

    SELECT count(*) INTO v_n FROM tmp_src_m2_4_latest
    WHERE contract_row_hash!~'^[0-9a-f]{32}$' OR source_snapshot_row_hash!~'^[0-9a-f]{32}$'
       OR source_g2_combined_hash!~'^[0-9a-f]{32}$'
       OR source_g2_combined_hash<>'e5ace7f32060ffb191c7bd0f8dd0c863';
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged M2.4 latest row-hash shape failures %',v_n; END IF;

    SELECT count(*) INTO v_n FROM tmp_src_m2_4_latest
    WHERE real_funds_movement_flag OR external_notice_generation_authorized_flag
       OR external_notice_transmitted_flag OR production_adverse_action_notice_flag;
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged M2.4 production-action authorization flags found %',v_n; END IF;

    SELECT count(*) INTO v_n FROM tmp_src_m2_7_latest
    WHERE contract_row_hash!~'^[0-9a-f]{32}$' OR source_snapshot_row_hash!~'^[0-9a-f]{32}$';
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged M2.7 latest row-hash shape failures %',v_n; END IF;

    SELECT count(*) INTO v_n FROM tmp_src_m2_10_latest
    WHERE contract_row_hash!~'^[0-9a-f]{32}$' OR source_snapshot_row_hash!~'^[0-9a-f]{32}$'
       OR performance_snapshot_row_hash!~'^[0-9a-f]{32}$';
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged M2.10 latest row-hash shape failures %',v_n; END IF;

    SELECT count(*) INTO v_n FROM tmp_src_m2_10_kpi WHERE row_hash!~'^[0-9a-f]{32}$';
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged M2.10 KPI row-hash shape failures %',v_n; END IF;
    SELECT count(*) INTO v_n FROM tmp_src_m2_10_queue WHERE row_hash!~'^[0-9a-f]{32}$';
    IF v_n<>0 THEN RAISE EXCEPTION 'Staged M2.10 queue row-hash shape failures %',v_n; END IF;

    IF (SELECT candidate_set_hash FROM tmp_src_m2_2_registry)
       IS DISTINCT FROM
       (SELECT md5(string_agg(row_hash,'|' ORDER BY scenario_id,merchant_application_id,template_sequence)) FROM tmp_src_m2_2_candidate) THEN
      RAISE EXCEPTION 'Staged M2.2 candidate set-hash reconstruction mismatch';
    END IF;
    IF (SELECT pricing_latest_set_hash FROM tmp_src_m2_2_registry)
       IS DISTINCT FROM
       (SELECT md5(string_agg(contract_row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM tmp_src_m2_2_latest) THEN
      RAISE EXCEPTION 'Staged M2.2 latest set-hash reconstruction mismatch';
    END IF;
    IF (SELECT activation_latest_set_hash FROM tmp_src_m2_4_registry)
       IS DISTINCT FROM
       (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||contract_row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM tmp_src_m2_4_latest) THEN
      RAISE EXCEPTION 'Staged M2.4 latest set-hash reconstruction mismatch';
    END IF;
    IF (SELECT latest_set_hash FROM tmp_src_m2_7_registry)
       IS DISTINCT FROM
       (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||contract_row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM tmp_src_m2_7_latest) THEN
      RAISE EXCEPTION 'Staged M2.7 latest set-hash reconstruction mismatch';
    END IF;
    IF (SELECT latest_set_hash FROM tmp_src_m2_10_registry)
       IS DISTINCT FROM
       (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||contract_row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM tmp_src_m2_10_latest) THEN
      RAISE EXCEPTION 'Staged M2.10 latest set-hash reconstruction mismatch';
    END IF;
    IF (SELECT kpi_snapshot_set_hash FROM tmp_src_m2_10_registry)
       IS DISTINCT FROM
       (SELECT md5(string_agg(scope_code||'|'||kpi_code||'|'||row_hash,'|' ORDER BY scope_code,kpi_rank,kpi_code)) FROM tmp_src_m2_10_kpi) THEN
      RAISE EXCEPTION 'Staged M2.10 KPI set-hash reconstruction mismatch';
    END IF;
    IF (SELECT queue_summary_set_hash FROM tmp_src_m2_10_registry)
       IS DISTINCT FROM
       (SELECT md5(string_agg(servicing_queue_code||'|'||row_hash,'|' ORDER BY servicing_queue_code)) FROM tmp_src_m2_10_queue) THEN
      RAISE EXCEPTION 'Staged M2.10 queue set-hash reconstruction mismatch';
    END IF;
END;
$m211$;

/* AUDIT_MARKER: BEGIN_M2_11_CANONICAL_BUSINESS_CONSTRUCTION
The staging-only audit begins here. Through the matching END marker, newly
persisted canonical targets may be INSERT destinations or target-shape sources
using WITH NO DATA, but may not be FROM/JOIN inputs to another business object.
============================================================================ */

/* ============================================================================
Section 5 — Immutable accepted-source snapshots
============================================================================ */

CREATE TEMP TABLE tmp_eval_application_source_projection ON COMMIT DROP AS
SELECT
    g.module1_run_id AS module1_run_id,
    g.scenario_id AS scenario_id,
    g.scenario_code AS scenario_code,
    g.merchant_application_id AS merchant_application_id,
    g.population_id AS population_id,
    g.merchant_id AS merchant_id,
    g.as_of_date AS as_of_date,
    g.industry_code AS industry_code,
    g.merchant_size_tier AS merchant_size_tier,
    g.relationship_stage AS relationship_stage,
    g.partner_channel_id AS partner_channel_id,
    g.channel_type AS channel_type,
    g.source_confidence_score AS source_confidence_score,
    g.data_confidence_tier AS data_confidence_tier,
    g.verification_disposition AS verification_disposition,
    g.fraud_risk_tier AS fraud_risk_tier,
    g.processor_continuity_status AS processor_continuity_status,
    g.avg_daily_eligible_sales_30d AS avg_daily_eligible_sales_30d,
    g.average_available_balance_30d AS average_available_balance_30d,
    g.capacity_tier AS capacity_tier,
    g.affordability_status AS affordability_status,
    g.archetype_code AS archetype_code,
    g.operating_resilience_score AS operating_resilience_score,
    g.resilience_tier AS resilience_tier,
    g.integrated_risk_score AS integrated_risk_score,
    g.synthetic_merchant_risk_proxy AS synthetic_merchant_risk_proxy,
    g.integrated_risk_tier AS integrated_risk_tier,
    g.path_weighted_ead_amount AS path_weighted_ead_amount,
    g.lgd_input_rate AS lgd_input_rate,
    g.schedule_adjusted_comparative_expected_loss_amount AS schedule_adjusted_comparative_expected_loss_amount,
    g.risk_adjusted_contribution_amount AS risk_adjusted_contribution_amount,
    g.annualized_risk_adjusted_return_rate AS annualized_risk_adjusted_return_rate,
    g.economic_tier AS economic_tier,
    g.economic_status AS economic_status,
    g.hard_stop_recommended_flag AS hard_stop_recommended_flag,
    g.manual_review_recommended_flag AS manual_review_recommended_flag,
    g.m1_15_contract_evidence_status AS m1_15_contract_evidence_status,
    g.m1_15_contract_row_hash AS m1_15_contract_row_hash,
    g.primary_source_code AS primary_source_code,
    g.primary_campaign_id AS primary_campaign_id,
    g.attribution_confidence_score AS attribution_confidence_score,
    g.attribution_confidence_tier AS attribution_confidence_tier,
    g.touchpoint_count AS touchpoint_count,
    g.assisted_touch_count AS assisted_touch_count,
    g.attribution_evidence_status AS attribution_evidence_status,
    g.direct_attributable_incurred_cost_amount AS direct_attributable_incurred_cost_amount,
    g.internally_allocated_acquisition_cost_amount AS internally_allocated_acquisition_cost_amount,
    g.total_incurred_pre_application_cost_amount AS total_incurred_pre_application_cost_amount,
    g.detailed_conditional_partner_broker_cost_amount AS detailed_conditional_partner_broker_cost_amount,
    g.detailed_total_acquisition_cost_if_booked AS detailed_total_acquisition_cost_if_booked,
    g.accepted_m1_14_acquisition_cost_amount AS accepted_m1_14_acquisition_cost_amount,
    g.identified_legacy_overlap_amount AS identified_legacy_overlap_amount,
    g.unmapped_legacy_proxy_amount AS unmapped_legacy_proxy_amount,
    g.incremental_acquisition_cost_beyond_m1_14 AS incremental_acquisition_cost_beyond_m1_14,
    g.enhanced_total_acquisition_cost_if_booked AS enhanced_total_acquisition_cost_if_booked,
    g.cost_evidence_status AS cost_evidence_status,
    g.overlap_evidence_status AS overlap_evidence_status,
    g.acquisition_contract_evidence_status AS acquisition_contract_evidence_status,
    g.m1_16_contract_row_hash AS m1_16_contract_row_hash,
    p.contract_code AS m2_2_contract_code,
    p.contract_version AS m2_2_contract_version,
    p.schema_version AS m2_2_schema_version,
    p.methodology_version AS m2_2_methodology_version,
    p.source_route_code AS source_route_code,
    p.source_route_rank AS source_route_rank,
    p.pricing_disposition_code AS pricing_disposition_code,
    p.structure_available_flag AS structure_available_flag,
    p.review_required_flag AS review_required_flag,
    p.selected_candidate_template_code AS selected_candidate_template_code,
    p.selected_candidate_row_hash AS selected_candidate_row_hash,
    p.requested_funding_amount AS requested_funding_amount,
    p.selected_funding_amount AS selected_funding_amount,
    p.selected_remittance_rate AS selected_remittance_rate,
    p.selected_payback_multiple AS selected_payback_multiple,
    p.selected_collection_horizon_days AS selected_collection_horizon_days,
    p.selected_total_repayment_amount AS selected_total_repayment_amount,
    p.selected_finance_charge_amount AS selected_finance_charge_amount,
    p.selected_implied_daily_collection_amount AS selected_implied_daily_collection_amount,
    p.selected_implied_payoff_days AS selected_implied_payoff_days,
    p.selected_amount_to_request_ratio AS selected_amount_to_request_ratio,
    p.candidate_count AS candidate_count,
    p.counteroffer_foundation_flag AS counteroffer_foundation_flag,
    p.stress_nonimprovement_applied_flag AS stress_nonimprovement_applied_flag,
    p.primary_reason_code AS primary_reason_code,
    p.reason_codes AS reason_codes,
    p.routing_evidence_status AS routing_evidence_status,
    p.source_m2_1_contract_row_hash AS m2_2_source_m2_1_contract_row_hash,
    p.source_request_contract_row_hash AS m2_2_source_request_contract_row_hash,
    p.source_g2_combined_hash AS m2_2_source_g2_combined_hash,
    p.policy_configuration_hash AS m2_2_policy_configuration_hash,
    p.source_snapshot_row_hash AS m2_2_source_snapshot_row_hash,
    p.contract_row_hash AS m2_2_contract_row_hash,
    p.created_at AS m2_2_source_created_at,
    a.contract_code AS m2_4_contract_code,
    a.contract_version AS m2_4_contract_version,
    a.schema_version AS m2_4_schema_version,
    a.methodology_version AS m2_4_methodology_version,
    a.source_final_decision_outcome_code AS source_final_decision_outcome_code,
    a.activation_outcome_code AS activation_outcome_code,
    a.activation_outcome_rank AS activation_outcome_rank,
    a.booking_eligible_flag AS booking_eligible_flag,
    a.booking_authorized_flag AS booking_authorized_flag,
    a.funding_authorized_flag AS funding_authorized_flag,
    a.funding_completed_flag AS funding_completed_flag,
    a.portfolio_activated_flag AS portfolio_activated_flag,
    a.operational_review_required_flag AS operational_review_required_flag,
    a.synthetic_offer_acceptance_assumed_flag AS synthetic_offer_acceptance_assumed_flag,
    a.real_funds_movement_flag AS real_funds_movement_flag,
    a.external_notice_generation_authorized_flag AS external_notice_generation_authorized_flag,
    a.external_notice_transmitted_flag AS external_notice_transmitted_flag,
    a.production_adverse_action_notice_flag AS production_adverse_action_notice_flag,
    a.synthetic_account_id AS synthetic_account_id,
    a.synthetic_advance_id AS synthetic_advance_id,
    a.booked_amount AS booked_amount,
    a.funded_amount AS funded_amount,
    a.activation_remittance_rate AS activation_remittance_rate,
    a.activation_payback_multiple AS activation_payback_multiple,
    a.activation_collection_horizon_days AS activation_collection_horizon_days,
    a.activation_total_repayment_amount AS activation_total_repayment_amount,
    a.activation_finance_charge_amount AS activation_finance_charge_amount,
    a.activation_implied_daily_collection_amount AS activation_implied_daily_collection_amount,
    a.activation_implied_payoff_days AS activation_implied_payoff_days,
    a.booking_date AS booking_date,
    a.funding_date AS funding_date,
    a.portfolio_activation_date AS portfolio_activation_date,
    a.first_expected_remittance_date AS first_expected_remittance_date,
    a.monitoring_start_date AS monitoring_start_date,
    a.activation_evidence_status AS activation_evidence_status,
    a.notice_control_code AS notice_control_code,
    a.primary_activation_reason_code AS primary_activation_reason_code,
    a.activation_reason_codes AS activation_reason_codes,
    a.source_m2_3_contract_row_hash AS m2_4_source_m2_3_contract_row_hash,
    a.source_m2_2_contract_row_hash AS m2_4_source_m2_2_contract_row_hash,
    a.source_g2_combined_hash AS m2_4_source_g2_combined_hash,
    a.source_snapshot_row_hash AS m2_4_source_snapshot_row_hash,
    a.snapshot_row_hash AS m2_4_activation_snapshot_row_hash,
    a.policy_configuration_hash AS m2_4_policy_configuration_hash,
    a.contract_row_hash AS m2_4_contract_row_hash,
    a.created_at AS m2_4_source_created_at,
    'M1_G2_CONSUMPTION_BUNDLE' AS m1_17_bundle_code,
    1 AS m1_17_bundle_version,
    'M1_G2_BUNDLE_SCHEMA_V1' AS m1_17_schema_version,
    'M1_17_METHOD_V1' AS m1_17_methodology_version,
    r17.bundle_status AS m1_17_bundle_status,
    r17.combined_g2_hash AS m1_17_combined_g2_hash,
    r17.row_hash AS m1_17_registry_row_hash,
    r22.contract_status AS m2_2_contract_status,
    r22.combined_set_hash AS m2_2_combined_set_hash,
    r22.row_hash AS m2_2_registry_row_hash,
    r24.contract_status AS m2_4_contract_status,
    r24.combined_set_hash AS m2_4_combined_set_hash,
    r24.row_hash AS m2_4_registry_row_hash,
    'MATCHED_ONE_TO_ONE'::text AS source_join_status_code
FROM tmp_src_m1_17_integrated g JOIN tmp_src_m2_2_latest p USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,population_id,merchant_id,as_of_date) JOIN tmp_src_m2_4_latest a USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,population_id,merchant_id,as_of_date) CROSS JOIN tmp_src_m1_17_g2_registry r17 CROSS JOIN tmp_src_m2_2_registry r22 CROSS JOIN tmp_src_m2_4_registry r24
ORDER BY module1_run_id,scenario_id,merchant_application_id;

CREATE UNIQUE INDEX tmp_eval_application_source_projection_u1 ON tmp_eval_application_source_projection (module1_run_id, scenario_id, merchant_application_id);
ANALYZE tmp_eval_application_source_projection;

/* Target-type-before-hash projection for msbf_m2.portfolio_strategy_application_source_snapshot. */
CREATE TEMP TABLE tmp_src_m2_11_application_snapshot ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_application_source_snapshot WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_src_m2_11_application_snapshot') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_application_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_src_m2_11_application_snapshot versus msbf_m2.portfolio_strategy_application_source_snapshot: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_src_m2_11_application_snapshot
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    population_id, merchant_id, as_of_date, industry_code,
    merchant_size_tier, relationship_stage, partner_channel_id, channel_type,
    source_confidence_score, data_confidence_tier, verification_disposition, fraud_risk_tier,
    processor_continuity_status, avg_daily_eligible_sales_30d, average_available_balance_30d, capacity_tier,
    affordability_status, archetype_code, operating_resilience_score, resilience_tier,
    integrated_risk_score, synthetic_merchant_risk_proxy, integrated_risk_tier, path_weighted_ead_amount,
    lgd_input_rate, schedule_adjusted_comparative_expected_loss_amount, risk_adjusted_contribution_amount, annualized_risk_adjusted_return_rate,
    economic_tier, economic_status, hard_stop_recommended_flag, manual_review_recommended_flag,
    m1_15_contract_evidence_status, m1_15_contract_row_hash, primary_source_code, primary_campaign_id,
    attribution_confidence_score, attribution_confidence_tier, touchpoint_count, assisted_touch_count,
    attribution_evidence_status, direct_attributable_incurred_cost_amount, internally_allocated_acquisition_cost_amount, total_incurred_pre_application_cost_amount,
    detailed_conditional_partner_broker_cost_amount, detailed_total_acquisition_cost_if_booked, accepted_m1_14_acquisition_cost_amount, identified_legacy_overlap_amount,
    unmapped_legacy_proxy_amount, incremental_acquisition_cost_beyond_m1_14, enhanced_total_acquisition_cost_if_booked, cost_evidence_status,
    overlap_evidence_status, acquisition_contract_evidence_status, m1_16_contract_row_hash, m2_2_contract_code,
    m2_2_contract_version, m2_2_schema_version, m2_2_methodology_version, source_route_code,
    source_route_rank, pricing_disposition_code, structure_available_flag, review_required_flag,
    selected_candidate_template_code, selected_candidate_row_hash, requested_funding_amount, selected_funding_amount,
    selected_remittance_rate, selected_payback_multiple, selected_collection_horizon_days, selected_total_repayment_amount,
    selected_finance_charge_amount, selected_implied_daily_collection_amount, selected_implied_payoff_days, selected_amount_to_request_ratio,
    candidate_count, counteroffer_foundation_flag, stress_nonimprovement_applied_flag, primary_reason_code,
    reason_codes, routing_evidence_status, m2_2_source_m2_1_contract_row_hash, m2_2_source_request_contract_row_hash,
    m2_2_source_g2_combined_hash, m2_2_policy_configuration_hash, m2_2_source_snapshot_row_hash, m2_2_contract_row_hash,
    m2_2_source_created_at, m2_4_contract_code, m2_4_contract_version, m2_4_schema_version,
    m2_4_methodology_version, source_final_decision_outcome_code, activation_outcome_code, activation_outcome_rank,
    booking_eligible_flag, booking_authorized_flag, funding_authorized_flag, funding_completed_flag,
    portfolio_activated_flag, operational_review_required_flag, synthetic_offer_acceptance_assumed_flag, real_funds_movement_flag,
    external_notice_generation_authorized_flag, external_notice_transmitted_flag, production_adverse_action_notice_flag, synthetic_account_id,
    synthetic_advance_id, booked_amount, funded_amount, activation_remittance_rate,
    activation_payback_multiple, activation_collection_horizon_days, activation_total_repayment_amount, activation_finance_charge_amount,
    activation_implied_daily_collection_amount, activation_implied_payoff_days, booking_date, funding_date,
    portfolio_activation_date, first_expected_remittance_date, monitoring_start_date, activation_evidence_status,
    notice_control_code, primary_activation_reason_code, activation_reason_codes, m2_4_source_m2_3_contract_row_hash,
    m2_4_source_m2_2_contract_row_hash, m2_4_source_g2_combined_hash, m2_4_source_snapshot_row_hash, m2_4_activation_snapshot_row_hash,
    m2_4_policy_configuration_hash, m2_4_contract_row_hash, m2_4_source_created_at, m1_17_bundle_code,
    m1_17_bundle_version, m1_17_schema_version, m1_17_methodology_version, m1_17_bundle_status,
    m1_17_combined_g2_hash, m1_17_registry_row_hash, m2_2_contract_status, m2_2_combined_set_hash,
    m2_2_registry_row_hash, m2_4_contract_status, m2_4_combined_set_hash, m2_4_registry_row_hash,
    source_join_status_code, row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.scenario_id,
    p.scenario_code,
    p.merchant_application_id,
    p.population_id,
    p.merchant_id,
    p.as_of_date,
    p.industry_code,
    p.merchant_size_tier,
    p.relationship_stage,
    p.partner_channel_id,
    p.channel_type,
    p.source_confidence_score,
    p.data_confidence_tier,
    p.verification_disposition,
    p.fraud_risk_tier,
    p.processor_continuity_status,
    p.avg_daily_eligible_sales_30d,
    p.average_available_balance_30d,
    p.capacity_tier,
    p.affordability_status,
    p.archetype_code,
    p.operating_resilience_score,
    p.resilience_tier,
    p.integrated_risk_score,
    p.synthetic_merchant_risk_proxy,
    p.integrated_risk_tier,
    p.path_weighted_ead_amount,
    p.lgd_input_rate,
    p.schedule_adjusted_comparative_expected_loss_amount,
    p.risk_adjusted_contribution_amount,
    p.annualized_risk_adjusted_return_rate,
    p.economic_tier,
    p.economic_status,
    p.hard_stop_recommended_flag,
    p.manual_review_recommended_flag,
    p.m1_15_contract_evidence_status,
    p.m1_15_contract_row_hash,
    p.primary_source_code,
    p.primary_campaign_id,
    p.attribution_confidence_score,
    p.attribution_confidence_tier,
    p.touchpoint_count,
    p.assisted_touch_count,
    p.attribution_evidence_status,
    p.direct_attributable_incurred_cost_amount,
    p.internally_allocated_acquisition_cost_amount,
    p.total_incurred_pre_application_cost_amount,
    p.detailed_conditional_partner_broker_cost_amount,
    p.detailed_total_acquisition_cost_if_booked,
    p.accepted_m1_14_acquisition_cost_amount,
    p.identified_legacy_overlap_amount,
    p.unmapped_legacy_proxy_amount,
    p.incremental_acquisition_cost_beyond_m1_14,
    p.enhanced_total_acquisition_cost_if_booked,
    p.cost_evidence_status,
    p.overlap_evidence_status,
    p.acquisition_contract_evidence_status,
    p.m1_16_contract_row_hash,
    p.m2_2_contract_code,
    p.m2_2_contract_version,
    p.m2_2_schema_version,
    p.m2_2_methodology_version,
    p.source_route_code,
    p.source_route_rank,
    p.pricing_disposition_code,
    p.structure_available_flag,
    p.review_required_flag,
    p.selected_candidate_template_code,
    p.selected_candidate_row_hash,
    p.requested_funding_amount,
    p.selected_funding_amount,
    p.selected_remittance_rate,
    p.selected_payback_multiple,
    p.selected_collection_horizon_days,
    p.selected_total_repayment_amount,
    p.selected_finance_charge_amount,
    p.selected_implied_daily_collection_amount,
    p.selected_implied_payoff_days,
    p.selected_amount_to_request_ratio,
    p.candidate_count,
    p.counteroffer_foundation_flag,
    p.stress_nonimprovement_applied_flag,
    p.primary_reason_code,
    p.reason_codes,
    p.routing_evidence_status,
    p.m2_2_source_m2_1_contract_row_hash,
    p.m2_2_source_request_contract_row_hash,
    p.m2_2_source_g2_combined_hash,
    p.m2_2_policy_configuration_hash,
    p.m2_2_source_snapshot_row_hash,
    p.m2_2_contract_row_hash,
    p.m2_2_source_created_at,
    p.m2_4_contract_code,
    p.m2_4_contract_version,
    p.m2_4_schema_version,
    p.m2_4_methodology_version,
    p.source_final_decision_outcome_code,
    p.activation_outcome_code,
    p.activation_outcome_rank,
    p.booking_eligible_flag,
    p.booking_authorized_flag,
    p.funding_authorized_flag,
    p.funding_completed_flag,
    p.portfolio_activated_flag,
    p.operational_review_required_flag,
    p.synthetic_offer_acceptance_assumed_flag,
    p.real_funds_movement_flag,
    p.external_notice_generation_authorized_flag,
    p.external_notice_transmitted_flag,
    p.production_adverse_action_notice_flag,
    p.synthetic_account_id,
    p.synthetic_advance_id,
    p.booked_amount,
    p.funded_amount,
    p.activation_remittance_rate,
    p.activation_payback_multiple,
    p.activation_collection_horizon_days,
    p.activation_total_repayment_amount,
    p.activation_finance_charge_amount,
    p.activation_implied_daily_collection_amount,
    p.activation_implied_payoff_days,
    p.booking_date,
    p.funding_date,
    p.portfolio_activation_date,
    p.first_expected_remittance_date,
    p.monitoring_start_date,
    p.activation_evidence_status,
    p.notice_control_code,
    p.primary_activation_reason_code,
    p.activation_reason_codes,
    p.m2_4_source_m2_3_contract_row_hash,
    p.m2_4_source_m2_2_contract_row_hash,
    p.m2_4_source_g2_combined_hash,
    p.m2_4_source_snapshot_row_hash,
    p.m2_4_activation_snapshot_row_hash,
    p.m2_4_policy_configuration_hash,
    p.m2_4_contract_row_hash,
    p.m2_4_source_created_at,
    p.m1_17_bundle_code,
    p.m1_17_bundle_version,
    p.m1_17_schema_version,
    p.m1_17_methodology_version,
    p.m1_17_bundle_status,
    p.m1_17_combined_g2_hash,
    p.m1_17_registry_row_hash,
    p.m2_2_contract_status,
    p.m2_2_combined_set_hash,
    p.m2_2_registry_row_hash,
    p.m2_4_contract_status,
    p.m2_4_combined_set_hash,
    p.m2_4_registry_row_hash,
    p.source_join_status_code,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_application_source_projection p
ORDER BY module1_run_id,scenario_id,merchant_application_id;

UPDATE tmp_src_m2_11_application_snapshot AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

CREATE UNIQUE INDEX tmp_src_m2_11_application_snapshot_u1 ON tmp_src_m2_11_application_snapshot(module1_run_id,scenario_id,merchant_application_id);
CREATE INDEX tmp_src_m2_11_application_snapshot_i1 ON tmp_src_m2_11_application_snapshot(module1_run_id,merchant_application_id,scenario_code);
ANALYZE tmp_src_m2_11_application_snapshot;

INSERT INTO msbf_m2.portfolio_strategy_application_source_snapshot
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    population_id, merchant_id, as_of_date, industry_code,
    merchant_size_tier, relationship_stage, partner_channel_id, channel_type,
    source_confidence_score, data_confidence_tier, verification_disposition, fraud_risk_tier,
    processor_continuity_status, avg_daily_eligible_sales_30d, average_available_balance_30d, capacity_tier,
    affordability_status, archetype_code, operating_resilience_score, resilience_tier,
    integrated_risk_score, synthetic_merchant_risk_proxy, integrated_risk_tier, path_weighted_ead_amount,
    lgd_input_rate, schedule_adjusted_comparative_expected_loss_amount, risk_adjusted_contribution_amount, annualized_risk_adjusted_return_rate,
    economic_tier, economic_status, hard_stop_recommended_flag, manual_review_recommended_flag,
    m1_15_contract_evidence_status, m1_15_contract_row_hash, primary_source_code, primary_campaign_id,
    attribution_confidence_score, attribution_confidence_tier, touchpoint_count, assisted_touch_count,
    attribution_evidence_status, direct_attributable_incurred_cost_amount, internally_allocated_acquisition_cost_amount, total_incurred_pre_application_cost_amount,
    detailed_conditional_partner_broker_cost_amount, detailed_total_acquisition_cost_if_booked, accepted_m1_14_acquisition_cost_amount, identified_legacy_overlap_amount,
    unmapped_legacy_proxy_amount, incremental_acquisition_cost_beyond_m1_14, enhanced_total_acquisition_cost_if_booked, cost_evidence_status,
    overlap_evidence_status, acquisition_contract_evidence_status, m1_16_contract_row_hash, m2_2_contract_code,
    m2_2_contract_version, m2_2_schema_version, m2_2_methodology_version, source_route_code,
    source_route_rank, pricing_disposition_code, structure_available_flag, review_required_flag,
    selected_candidate_template_code, selected_candidate_row_hash, requested_funding_amount, selected_funding_amount,
    selected_remittance_rate, selected_payback_multiple, selected_collection_horizon_days, selected_total_repayment_amount,
    selected_finance_charge_amount, selected_implied_daily_collection_amount, selected_implied_payoff_days, selected_amount_to_request_ratio,
    candidate_count, counteroffer_foundation_flag, stress_nonimprovement_applied_flag, primary_reason_code,
    reason_codes, routing_evidence_status, m2_2_source_m2_1_contract_row_hash, m2_2_source_request_contract_row_hash,
    m2_2_source_g2_combined_hash, m2_2_policy_configuration_hash, m2_2_source_snapshot_row_hash, m2_2_contract_row_hash,
    m2_2_source_created_at, m2_4_contract_code, m2_4_contract_version, m2_4_schema_version,
    m2_4_methodology_version, source_final_decision_outcome_code, activation_outcome_code, activation_outcome_rank,
    booking_eligible_flag, booking_authorized_flag, funding_authorized_flag, funding_completed_flag,
    portfolio_activated_flag, operational_review_required_flag, synthetic_offer_acceptance_assumed_flag, real_funds_movement_flag,
    external_notice_generation_authorized_flag, external_notice_transmitted_flag, production_adverse_action_notice_flag, synthetic_account_id,
    synthetic_advance_id, booked_amount, funded_amount, activation_remittance_rate,
    activation_payback_multiple, activation_collection_horizon_days, activation_total_repayment_amount, activation_finance_charge_amount,
    activation_implied_daily_collection_amount, activation_implied_payoff_days, booking_date, funding_date,
    portfolio_activation_date, first_expected_remittance_date, monitoring_start_date, activation_evidence_status,
    notice_control_code, primary_activation_reason_code, activation_reason_codes, m2_4_source_m2_3_contract_row_hash,
    m2_4_source_m2_2_contract_row_hash, m2_4_source_g2_combined_hash, m2_4_source_snapshot_row_hash, m2_4_activation_snapshot_row_hash,
    m2_4_policy_configuration_hash, m2_4_contract_row_hash, m2_4_source_created_at, m1_17_bundle_code,
    m1_17_bundle_version, m1_17_schema_version, m1_17_methodology_version, m1_17_bundle_status,
    m1_17_combined_g2_hash, m1_17_registry_row_hash, m2_2_contract_status, m2_2_combined_set_hash,
    m2_2_registry_row_hash, m2_4_contract_status, m2_4_combined_set_hash, m2_4_registry_row_hash,
    source_join_status_code, row_hash, created_at
)
SELECT
    t.module1_run_id,
    t.scenario_id,
    t.scenario_code,
    t.merchant_application_id,
    t.population_id,
    t.merchant_id,
    t.as_of_date,
    t.industry_code,
    t.merchant_size_tier,
    t.relationship_stage,
    t.partner_channel_id,
    t.channel_type,
    t.source_confidence_score,
    t.data_confidence_tier,
    t.verification_disposition,
    t.fraud_risk_tier,
    t.processor_continuity_status,
    t.avg_daily_eligible_sales_30d,
    t.average_available_balance_30d,
    t.capacity_tier,
    t.affordability_status,
    t.archetype_code,
    t.operating_resilience_score,
    t.resilience_tier,
    t.integrated_risk_score,
    t.synthetic_merchant_risk_proxy,
    t.integrated_risk_tier,
    t.path_weighted_ead_amount,
    t.lgd_input_rate,
    t.schedule_adjusted_comparative_expected_loss_amount,
    t.risk_adjusted_contribution_amount,
    t.annualized_risk_adjusted_return_rate,
    t.economic_tier,
    t.economic_status,
    t.hard_stop_recommended_flag,
    t.manual_review_recommended_flag,
    t.m1_15_contract_evidence_status,
    t.m1_15_contract_row_hash,
    t.primary_source_code,
    t.primary_campaign_id,
    t.attribution_confidence_score,
    t.attribution_confidence_tier,
    t.touchpoint_count,
    t.assisted_touch_count,
    t.attribution_evidence_status,
    t.direct_attributable_incurred_cost_amount,
    t.internally_allocated_acquisition_cost_amount,
    t.total_incurred_pre_application_cost_amount,
    t.detailed_conditional_partner_broker_cost_amount,
    t.detailed_total_acquisition_cost_if_booked,
    t.accepted_m1_14_acquisition_cost_amount,
    t.identified_legacy_overlap_amount,
    t.unmapped_legacy_proxy_amount,
    t.incremental_acquisition_cost_beyond_m1_14,
    t.enhanced_total_acquisition_cost_if_booked,
    t.cost_evidence_status,
    t.overlap_evidence_status,
    t.acquisition_contract_evidence_status,
    t.m1_16_contract_row_hash,
    t.m2_2_contract_code,
    t.m2_2_contract_version,
    t.m2_2_schema_version,
    t.m2_2_methodology_version,
    t.source_route_code,
    t.source_route_rank,
    t.pricing_disposition_code,
    t.structure_available_flag,
    t.review_required_flag,
    t.selected_candidate_template_code,
    t.selected_candidate_row_hash,
    t.requested_funding_amount,
    t.selected_funding_amount,
    t.selected_remittance_rate,
    t.selected_payback_multiple,
    t.selected_collection_horizon_days,
    t.selected_total_repayment_amount,
    t.selected_finance_charge_amount,
    t.selected_implied_daily_collection_amount,
    t.selected_implied_payoff_days,
    t.selected_amount_to_request_ratio,
    t.candidate_count,
    t.counteroffer_foundation_flag,
    t.stress_nonimprovement_applied_flag,
    t.primary_reason_code,
    t.reason_codes,
    t.routing_evidence_status,
    t.m2_2_source_m2_1_contract_row_hash,
    t.m2_2_source_request_contract_row_hash,
    t.m2_2_source_g2_combined_hash,
    t.m2_2_policy_configuration_hash,
    t.m2_2_source_snapshot_row_hash,
    t.m2_2_contract_row_hash,
    t.m2_2_source_created_at,
    t.m2_4_contract_code,
    t.m2_4_contract_version,
    t.m2_4_schema_version,
    t.m2_4_methodology_version,
    t.source_final_decision_outcome_code,
    t.activation_outcome_code,
    t.activation_outcome_rank,
    t.booking_eligible_flag,
    t.booking_authorized_flag,
    t.funding_authorized_flag,
    t.funding_completed_flag,
    t.portfolio_activated_flag,
    t.operational_review_required_flag,
    t.synthetic_offer_acceptance_assumed_flag,
    t.real_funds_movement_flag,
    t.external_notice_generation_authorized_flag,
    t.external_notice_transmitted_flag,
    t.production_adverse_action_notice_flag,
    t.synthetic_account_id,
    t.synthetic_advance_id,
    t.booked_amount,
    t.funded_amount,
    t.activation_remittance_rate,
    t.activation_payback_multiple,
    t.activation_collection_horizon_days,
    t.activation_total_repayment_amount,
    t.activation_finance_charge_amount,
    t.activation_implied_daily_collection_amount,
    t.activation_implied_payoff_days,
    t.booking_date,
    t.funding_date,
    t.portfolio_activation_date,
    t.first_expected_remittance_date,
    t.monitoring_start_date,
    t.activation_evidence_status,
    t.notice_control_code,
    t.primary_activation_reason_code,
    t.activation_reason_codes,
    t.m2_4_source_m2_3_contract_row_hash,
    t.m2_4_source_m2_2_contract_row_hash,
    t.m2_4_source_g2_combined_hash,
    t.m2_4_source_snapshot_row_hash,
    t.m2_4_activation_snapshot_row_hash,
    t.m2_4_policy_configuration_hash,
    t.m2_4_contract_row_hash,
    t.m2_4_source_created_at,
    t.m1_17_bundle_code,
    t.m1_17_bundle_version,
    t.m1_17_schema_version,
    t.m1_17_methodology_version,
    t.m1_17_bundle_status,
    t.m1_17_combined_g2_hash,
    t.m1_17_registry_row_hash,
    t.m2_2_contract_status,
    t.m2_2_combined_set_hash,
    t.m2_2_registry_row_hash,
    t.m2_4_contract_status,
    t.m2_4_combined_set_hash,
    t.m2_4_registry_row_hash,
    t.source_join_status_code,
    t.row_hash,
    t.created_at
FROM tmp_src_m2_11_application_snapshot t
ORDER BY module1_run_id,scenario_id,merchant_application_id;

CREATE TEMP TABLE tmp_eval_candidate_source_projection ON COMMIT DROP AS
SELECT
    c.module1_run_id AS module1_run_id,
    c.scenario_id AS scenario_id,
    c.scenario_code AS scenario_code,
    c.merchant_application_id AS merchant_application_id,
    c.candidate_template_code AS candidate_template_code,
    c.template_sequence AS template_sequence,
    c.source_route_code AS source_route_code,
    c.source_route_rank AS source_route_rank,
    c.requested_funding_amount AS requested_funding_amount,
    c.candidate_funding_amount AS candidate_funding_amount,
    c.candidate_remittance_rate AS candidate_remittance_rate,
    c.candidate_payback_multiple AS candidate_payback_multiple,
    c.candidate_collection_horizon_days AS candidate_collection_horizon_days,
    c.candidate_total_repayment_amount AS candidate_total_repayment_amount,
    c.candidate_finance_charge_amount AS candidate_finance_charge_amount,
    c.implied_daily_collection_amount AS implied_daily_collection_amount,
    c.implied_payoff_days AS implied_payoff_days,
    c.amount_to_request_ratio AS amount_to_request_ratio,
    c.capacity_alignment_ratio AS capacity_alignment_ratio,
    c.risk_load_rate AS risk_load_rate,
    c.resilience_load_rate AS resilience_load_rate,
    c.economic_load_rate AS economic_load_rate,
    c.stress_load_rate AS stress_load_rate,
    c.acquisition_economics_amount AS acquisition_economics_amount,
    c.expected_loss_amount AS expected_loss_amount,
    c.risk_adjusted_contribution_amount AS risk_adjusted_contribution_amount,
    c.annualized_return_rate AS annualized_return_rate,
    c.counteroffer_foundation_flag AS counteroffer_foundation_flag,
    c.candidate_eligible_flag AS candidate_eligible_flag,
    c.selected_foundation_flag AS selected_foundation_flag,
    c.candidate_rank AS candidate_rank,
    c.primary_reason_code AS primary_reason_code,
    c.secondary_reason_codes AS secondary_reason_codes,
    c.source_m2_1_contract_row_hash AS source_m2_1_contract_row_hash,
    c.source_request_contract_row_hash AS source_request_contract_row_hash,
    c.source_m1_15_contract_row_hash AS source_m1_15_contract_row_hash,
    c.source_m1_16_contract_row_hash AS source_m1_16_contract_row_hash,
    c.source_g2_combined_hash AS source_g2_combined_hash,
    c.policy_configuration_hash AS policy_configuration_hash,
    c.row_hash AS source_candidate_row_hash,
    c.created_at AS source_candidate_created_at,
    'M2_PRICING_STRUCTURE_CONSUMPTION' AS m2_2_contract_code,
    1 AS m2_2_contract_version,
    'M2_2_PRICING_STRUCTURE_SCHEMA_V1' AS m2_2_schema_version,
    'M2_2_METHOD_V1' AS m2_2_methodology_version,
    r22.contract_status AS m2_2_contract_status,
    r22.combined_set_hash AS m2_2_combined_set_hash,
    r22.row_hash AS m2_2_registry_row_hash
FROM tmp_src_m2_2_candidate c CROSS JOIN tmp_src_m2_2_registry r22
ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code;

CREATE UNIQUE INDEX tmp_eval_candidate_source_projection_u1 ON tmp_eval_candidate_source_projection (module1_run_id, scenario_id, merchant_application_id, candidate_template_code);
ANALYZE tmp_eval_candidate_source_projection;

/* Target-type-before-hash projection for msbf_m2.portfolio_strategy_candidate_source_snapshot. */
CREATE TEMP TABLE tmp_src_m2_11_candidate_snapshot ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_candidate_source_snapshot WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_src_m2_11_candidate_snapshot') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_candidate_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_src_m2_11_candidate_snapshot versus msbf_m2.portfolio_strategy_candidate_source_snapshot: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_src_m2_11_candidate_snapshot
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    candidate_template_code, template_sequence, source_route_code, source_route_rank,
    requested_funding_amount, candidate_funding_amount, candidate_remittance_rate, candidate_payback_multiple,
    candidate_collection_horizon_days, candidate_total_repayment_amount, candidate_finance_charge_amount, implied_daily_collection_amount,
    implied_payoff_days, amount_to_request_ratio, capacity_alignment_ratio, risk_load_rate,
    resilience_load_rate, economic_load_rate, stress_load_rate, acquisition_economics_amount,
    expected_loss_amount, risk_adjusted_contribution_amount, annualized_return_rate, counteroffer_foundation_flag,
    candidate_eligible_flag, selected_foundation_flag, candidate_rank, primary_reason_code,
    secondary_reason_codes, source_m2_1_contract_row_hash, source_request_contract_row_hash, source_m1_15_contract_row_hash,
    source_m1_16_contract_row_hash, source_g2_combined_hash, policy_configuration_hash, source_candidate_row_hash,
    source_candidate_created_at, m2_2_contract_code, m2_2_contract_version, m2_2_schema_version,
    m2_2_methodology_version, m2_2_contract_status, m2_2_combined_set_hash, m2_2_registry_row_hash,
    row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.scenario_id,
    p.scenario_code,
    p.merchant_application_id,
    p.candidate_template_code,
    p.template_sequence,
    p.source_route_code,
    p.source_route_rank,
    p.requested_funding_amount,
    p.candidate_funding_amount,
    p.candidate_remittance_rate,
    p.candidate_payback_multiple,
    p.candidate_collection_horizon_days,
    p.candidate_total_repayment_amount,
    p.candidate_finance_charge_amount,
    p.implied_daily_collection_amount,
    p.implied_payoff_days,
    p.amount_to_request_ratio,
    p.capacity_alignment_ratio,
    p.risk_load_rate,
    p.resilience_load_rate,
    p.economic_load_rate,
    p.stress_load_rate,
    p.acquisition_economics_amount,
    p.expected_loss_amount,
    p.risk_adjusted_contribution_amount,
    p.annualized_return_rate,
    p.counteroffer_foundation_flag,
    p.candidate_eligible_flag,
    p.selected_foundation_flag,
    p.candidate_rank,
    p.primary_reason_code,
    p.secondary_reason_codes,
    p.source_m2_1_contract_row_hash,
    p.source_request_contract_row_hash,
    p.source_m1_15_contract_row_hash,
    p.source_m1_16_contract_row_hash,
    p.source_g2_combined_hash,
    p.policy_configuration_hash,
    p.source_candidate_row_hash,
    p.source_candidate_created_at,
    p.m2_2_contract_code,
    p.m2_2_contract_version,
    p.m2_2_schema_version,
    p.m2_2_methodology_version,
    p.m2_2_contract_status,
    p.m2_2_combined_set_hash,
    p.m2_2_registry_row_hash,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_candidate_source_projection p
ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code;

UPDATE tmp_src_m2_11_candidate_snapshot AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

CREATE UNIQUE INDEX tmp_src_m2_11_candidate_snapshot_u1 ON tmp_src_m2_11_candidate_snapshot(module1_run_id,scenario_id,merchant_application_id,candidate_template_code);
CREATE INDEX tmp_src_m2_11_candidate_snapshot_i1 ON tmp_src_m2_11_candidate_snapshot(module1_run_id,scenario_id,merchant_application_id,candidate_rank,candidate_template_code);
ANALYZE tmp_src_m2_11_candidate_snapshot;

INSERT INTO msbf_m2.portfolio_strategy_candidate_source_snapshot
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    candidate_template_code, template_sequence, source_route_code, source_route_rank,
    requested_funding_amount, candidate_funding_amount, candidate_remittance_rate, candidate_payback_multiple,
    candidate_collection_horizon_days, candidate_total_repayment_amount, candidate_finance_charge_amount, implied_daily_collection_amount,
    implied_payoff_days, amount_to_request_ratio, capacity_alignment_ratio, risk_load_rate,
    resilience_load_rate, economic_load_rate, stress_load_rate, acquisition_economics_amount,
    expected_loss_amount, risk_adjusted_contribution_amount, annualized_return_rate, counteroffer_foundation_flag,
    candidate_eligible_flag, selected_foundation_flag, candidate_rank, primary_reason_code,
    secondary_reason_codes, source_m2_1_contract_row_hash, source_request_contract_row_hash, source_m1_15_contract_row_hash,
    source_m1_16_contract_row_hash, source_g2_combined_hash, policy_configuration_hash, source_candidate_row_hash,
    source_candidate_created_at, m2_2_contract_code, m2_2_contract_version, m2_2_schema_version,
    m2_2_methodology_version, m2_2_contract_status, m2_2_combined_set_hash, m2_2_registry_row_hash,
    row_hash, created_at
)
SELECT
    t.module1_run_id,
    t.scenario_id,
    t.scenario_code,
    t.merchant_application_id,
    t.candidate_template_code,
    t.template_sequence,
    t.source_route_code,
    t.source_route_rank,
    t.requested_funding_amount,
    t.candidate_funding_amount,
    t.candidate_remittance_rate,
    t.candidate_payback_multiple,
    t.candidate_collection_horizon_days,
    t.candidate_total_repayment_amount,
    t.candidate_finance_charge_amount,
    t.implied_daily_collection_amount,
    t.implied_payoff_days,
    t.amount_to_request_ratio,
    t.capacity_alignment_ratio,
    t.risk_load_rate,
    t.resilience_load_rate,
    t.economic_load_rate,
    t.stress_load_rate,
    t.acquisition_economics_amount,
    t.expected_loss_amount,
    t.risk_adjusted_contribution_amount,
    t.annualized_return_rate,
    t.counteroffer_foundation_flag,
    t.candidate_eligible_flag,
    t.selected_foundation_flag,
    t.candidate_rank,
    t.primary_reason_code,
    t.secondary_reason_codes,
    t.source_m2_1_contract_row_hash,
    t.source_request_contract_row_hash,
    t.source_m1_15_contract_row_hash,
    t.source_m1_16_contract_row_hash,
    t.source_g2_combined_hash,
    t.policy_configuration_hash,
    t.source_candidate_row_hash,
    t.source_candidate_created_at,
    t.m2_2_contract_code,
    t.m2_2_contract_version,
    t.m2_2_schema_version,
    t.m2_2_methodology_version,
    t.m2_2_contract_status,
    t.m2_2_combined_set_hash,
    t.m2_2_registry_row_hash,
    t.row_hash,
    t.created_at
FROM tmp_src_m2_11_candidate_snapshot t
ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code;

CREATE TEMP TABLE tmp_eval_account_source_projection ON COMMIT DROP AS
SELECT
    o.module1_run_id AS module1_run_id,
    o.scenario_id AS scenario_id,
    o.scenario_code AS scenario_code,
    o.merchant_application_id AS merchant_application_id,
    o.merchant_id AS merchant_id,
    o.synthetic_account_id AS synthetic_account_id,
    o.synthetic_advance_id AS synthetic_advance_id,
    o.contract_code AS m2_7_contract_code,
    o.contract_version AS m2_7_contract_version,
    o.schema_version AS m2_7_schema_version,
    o.methodology_version AS m2_7_methodology_version,
    o.source_strategy_outcome_code AS source_strategy_outcome_code,
    o.source_servicing_action_code AS source_servicing_action_code,
    o.source_recommended_action_exposure_amount AS source_recommended_action_exposure_amount,
    o.operational_setup_outcome_code AS operational_setup_outcome_code,
    o.operational_setup_action_code AS operational_setup_action_code,
    o.operational_setup_priority_rank AS operational_setup_priority_rank,
    o.operational_setup_queue_code AS operational_setup_queue_code,
    o.account_setup_status_code AS account_setup_status_code,
    o.setup_authorized_flag AS setup_authorized_flag,
    o.blueprint_created_flag AS blueprint_created_flag,
    o.setup_review_required_flag AS setup_review_required_flag,
    o.no_setup_required_flag AS no_setup_required_flag,
    o.synthetic_operational_case_id AS synthetic_operational_case_id,
    o.synthetic_account_setup_id AS synthetic_account_setup_id,
    o.synthetic_servicing_plan_id AS synthetic_servicing_plan_id,
    o.operational_activation_date AS operational_activation_date,
    o.next_reassessment_date AS next_reassessment_date,
    o.applied_temporary_payment_factor AS applied_temporary_payment_factor,
    o.applied_setup_duration_days AS applied_setup_duration_days,
    o.applied_reassessment_interval_days AS applied_reassessment_interval_days,
    o.primary_setup_reason_code AS primary_setup_reason_code,
    o.setup_reason_codes AS setup_reason_codes,
    o.setup_parameter_payload AS setup_parameter_payload,
    o.source_contract_row_hash AS m2_7_source_contract_row_hash,
    o.source_snapshot_row_hash AS m2_7_source_snapshot_row_hash,
    o.activation_snapshot_row_hash AS m2_7_activation_snapshot_row_hash,
    o.account_setup_snapshot_row_hash AS m2_7_account_setup_snapshot_row_hash,
    o.policy_configuration_hash AS m2_7_policy_configuration_hash,
    o.contract_row_hash AS m2_7_contract_row_hash,
    o.created_at AS m2_7_source_created_at,
    m.contract_code AS m2_10_contract_code,
    m.contract_version AS m2_10_contract_version,
    m.schema_version AS m2_10_schema_version,
    m.methodology_version AS m2_10_methodology_version,
    m.source_final_lifecycle_state_code AS source_final_lifecycle_state_code,
    m.certified_state_code AS certified_state_code,
    m.state_certified_flag AS state_certified_flag,
    m.performance_tier_code AS performance_tier_code,
    m.servicing_queue_code AS servicing_queue_code,
    m.payment_activity_flag AS payment_activity_flag,
    m.exception_incident_flag AS exception_incident_flag,
    m.exception_resolved_flag AS exception_resolved_flag,
    m.payment_event_count AS payment_event_count,
    m.settled_event_count AS settled_event_count,
    m.returned_event_count AS returned_event_count,
    m.retry_event_count AS retry_event_count,
    m.exception_case_count AS exception_case_count,
    m.resolved_exception_count AS resolved_exception_count,
    m.unresolved_exception_count AS unresolved_exception_count,
    m.source_exposure_amount AS source_exposure_amount,
    m.certified_exposure_amount AS certified_exposure_amount,
    m.scheduled_payment_amount AS scheduled_payment_amount,
    m.processed_payment_amount AS processed_payment_amount,
    m.returned_payment_amount AS returned_payment_amount,
    m.retry_payment_amount AS retry_payment_amount,
    m.reconciliation_variance_amount AS reconciliation_variance_amount,
    m.exposure_variance_amount AS exposure_variance_amount,
    m.gross_collection_rate AS gross_collection_rate,
    m.return_rate AS return_rate,
    m.retry_cure_rate AS retry_cure_rate,
    m.exposure_retention_rate AS exposure_retention_rate,
    m.servicing_burden_units AS servicing_burden_units,
    m.primary_portfolio_reason_code AS primary_portfolio_reason_code,
    m.portfolio_reason_codes AS portfolio_reason_codes,
    m.source_contract_row_hash AS m2_10_source_contract_row_hash,
    m.source_snapshot_row_hash AS m2_10_source_snapshot_row_hash,
    m.performance_snapshot_row_hash AS m2_10_performance_snapshot_row_hash,
    m.policy_configuration_hash AS m2_10_policy_configuration_hash,
    m.contract_row_hash AS m2_10_contract_row_hash,
    m.created_at AS m2_10_source_created_at,
    r27.contract_status AS m2_7_contract_status,
    r27.combined_set_hash AS m2_7_combined_set_hash,
    r27.row_hash AS m2_7_registry_row_hash,
    r210.contract_status AS m2_10_contract_status,
    r210.combined_set_hash AS m2_10_combined_set_hash,
    r210.row_hash AS m2_10_registry_row_hash,
    TRUE AS operational_account_present_flag,
    m.performance_tier_code AS source_account_posture_code,
    CASE m.performance_tier_code WHEN 'CLOSED_STABLE' THEN 1 WHEN 'ACTIVE_RECONCILED' THEN 2 WHEN 'CONTROLLED_REVIEW' THEN 3 ELSE NULL END::smallint AS source_account_posture_rank,
    (
            r27.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
            AND r27.contract_version=1
            AND r27.schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
            AND r27.methodology_version='M2_7_METHOD_V1'
            AND r27.contract_status='ACCEPTED'
            AND r27.combined_set_hash='c8e3a472afd2a16b1183677324e9db98'
            AND r27.row_hash~'^[0-9a-f]{32}$'
            AND r210.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'
            AND r210.contract_version=1
            AND r210.schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'
            AND r210.methodology_version='M2_10_METHOD_V1'
            AND r210.contract_status='ACCEPTED'
            AND r210.combined_set_hash='24fca7263a04397ebf21d30639f9069b'
            AND r210.row_hash~'^[0-9a-f]{32}$'
            AND EXISTS
            (
              SELECT 1 FROM tmp_src_acceptance_gate_result g27
              WHERE g27.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
                AND g27.result_status='PASS'
                AND g27.review_version=(SELECT max(x.review_version) FROM tmp_src_acceptance_gate_result x WHERE x.gate_id=g27.gate_id)
            )
            AND EXISTS
            (
              SELECT 1 FROM tmp_src_acceptance_gate_result g210
              WHERE g210.gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
                AND g210.result_status='PASS'
                AND g210.review_version=(SELECT max(x.review_version) FROM tmp_src_acceptance_gate_result x WHERE x.gate_id=g210.gate_id)
            )
        ) AS source_contract_identity_valid_flag,
    (
            o.source_contract_row_hash~'^[0-9a-f]{32}$'
            AND o.source_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND o.activation_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND o.account_setup_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND o.contract_row_hash~'^[0-9a-f]{32}$'
            AND m.source_contract_row_hash~'^[0-9a-f]{32}$'
            AND m.source_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND m.performance_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND m.contract_row_hash~'^[0-9a-f]{32}$'
            AND r27.latest_set_hash=(
              SELECT md5(string_agg(x.scenario_id::text||'|'||x.merchant_application_id||'|'||x.contract_row_hash,'|' ORDER BY x.scenario_id,x.merchant_application_id))
              FROM tmp_src_m2_7_latest x
            )
            AND r210.latest_set_hash=(
              SELECT md5(string_agg(x.scenario_id::text||'|'||x.merchant_application_id||'|'||x.contract_row_hash,'|' ORDER BY x.scenario_id,x.merchant_application_id))
              FROM tmp_src_m2_10_latest x
            )
        ) AS source_lineage_intact_flag,
    (NOT m.state_certified_flag OR m.unresolved_exception_count>0 OR NOT (
            r27.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
            AND r27.contract_version=1
            AND r27.schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'
            AND r27.methodology_version='M2_7_METHOD_V1'
            AND r27.contract_status='ACCEPTED'
            AND r27.combined_set_hash='c8e3a472afd2a16b1183677324e9db98'
            AND r27.row_hash~'^[0-9a-f]{32}$'
            AND r210.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'
            AND r210.contract_version=1
            AND r210.schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'
            AND r210.methodology_version='M2_10_METHOD_V1'
            AND r210.contract_status='ACCEPTED'
            AND r210.combined_set_hash='24fca7263a04397ebf21d30639f9069b'
            AND r210.row_hash~'^[0-9a-f]{32}$'
            AND EXISTS
            (
              SELECT 1 FROM tmp_src_acceptance_gate_result g27
              WHERE g27.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
                AND g27.result_status='PASS'
                AND g27.review_version=(SELECT max(x.review_version) FROM tmp_src_acceptance_gate_result x WHERE x.gate_id=g27.gate_id)
            )
            AND EXISTS
            (
              SELECT 1 FROM tmp_src_acceptance_gate_result g210
              WHERE g210.gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
                AND g210.result_status='PASS'
                AND g210.review_version=(SELECT max(x.review_version) FROM tmp_src_acceptance_gate_result x WHERE x.gate_id=g210.gate_id)
            )
        ) OR NOT (
            o.source_contract_row_hash~'^[0-9a-f]{32}$'
            AND o.source_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND o.activation_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND o.account_setup_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND o.contract_row_hash~'^[0-9a-f]{32}$'
            AND m.source_contract_row_hash~'^[0-9a-f]{32}$'
            AND m.source_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND m.performance_snapshot_row_hash~'^[0-9a-f]{32}$'
            AND m.contract_row_hash~'^[0-9a-f]{32}$'
            AND r27.latest_set_hash=(
              SELECT md5(string_agg(x.scenario_id::text||'|'||x.merchant_application_id||'|'||x.contract_row_hash,'|' ORDER BY x.scenario_id,x.merchant_application_id))
              FROM tmp_src_m2_7_latest x
            )
            AND r210.latest_set_hash=(
              SELECT md5(string_agg(x.scenario_id::text||'|'||x.merchant_application_id||'|'||x.contract_row_hash,'|' ORDER BY x.scenario_id,x.merchant_application_id))
              FROM tmp_src_m2_10_latest x
            )
        )) AS certification_blocked_flag,
    'MATCHED_ONE_TO_ONE'::text AS source_join_status_code
FROM tmp_src_m2_7_latest o JOIN tmp_src_m2_10_latest m USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,merchant_id,synthetic_account_id,synthetic_advance_id) CROSS JOIN tmp_src_m2_7_registry r27 CROSS JOIN tmp_src_m2_10_registry r210
ORDER BY module1_run_id,scenario_id,merchant_application_id;

CREATE UNIQUE INDEX tmp_eval_account_source_projection_u1 ON tmp_eval_account_source_projection (module1_run_id, scenario_id, merchant_application_id);
ANALYZE tmp_eval_account_source_projection;

/* Target-type-before-hash projection for msbf_m2.portfolio_strategy_account_source_snapshot. */
CREATE TEMP TABLE tmp_src_m2_11_account_snapshot ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_account_source_snapshot WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_src_m2_11_account_snapshot') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_account_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_src_m2_11_account_snapshot versus msbf_m2.portfolio_strategy_account_source_snapshot: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_src_m2_11_account_snapshot
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    merchant_id, synthetic_account_id, synthetic_advance_id, m2_7_contract_code,
    m2_7_contract_version, m2_7_schema_version, m2_7_methodology_version, source_strategy_outcome_code,
    source_servicing_action_code, source_recommended_action_exposure_amount, operational_setup_outcome_code, operational_setup_action_code,
    operational_setup_priority_rank, operational_setup_queue_code, account_setup_status_code, setup_authorized_flag,
    blueprint_created_flag, setup_review_required_flag, no_setup_required_flag, synthetic_operational_case_id,
    synthetic_account_setup_id, synthetic_servicing_plan_id, operational_activation_date, next_reassessment_date,
    applied_temporary_payment_factor, applied_setup_duration_days, applied_reassessment_interval_days, primary_setup_reason_code,
    setup_reason_codes, setup_parameter_payload, m2_7_source_contract_row_hash, m2_7_source_snapshot_row_hash,
    m2_7_activation_snapshot_row_hash, m2_7_account_setup_snapshot_row_hash, m2_7_policy_configuration_hash, m2_7_contract_row_hash,
    m2_7_source_created_at, m2_10_contract_code, m2_10_contract_version, m2_10_schema_version,
    m2_10_methodology_version, source_final_lifecycle_state_code, certified_state_code, state_certified_flag,
    performance_tier_code, servicing_queue_code, payment_activity_flag, exception_incident_flag,
    exception_resolved_flag, payment_event_count, settled_event_count, returned_event_count,
    retry_event_count, exception_case_count, resolved_exception_count, unresolved_exception_count,
    source_exposure_amount, certified_exposure_amount, scheduled_payment_amount, processed_payment_amount,
    returned_payment_amount, retry_payment_amount, reconciliation_variance_amount, exposure_variance_amount,
    gross_collection_rate, return_rate, retry_cure_rate, exposure_retention_rate,
    servicing_burden_units, primary_portfolio_reason_code, portfolio_reason_codes, m2_10_source_contract_row_hash,
    m2_10_source_snapshot_row_hash, m2_10_performance_snapshot_row_hash, m2_10_policy_configuration_hash, m2_10_contract_row_hash,
    m2_10_source_created_at, operational_account_present_flag, source_account_posture_code, source_account_posture_rank,
    source_contract_identity_valid_flag, source_lineage_intact_flag, certification_blocked_flag, m2_7_contract_status,
    m2_7_combined_set_hash, m2_7_registry_row_hash, m2_10_contract_status, m2_10_combined_set_hash,
    m2_10_registry_row_hash, source_join_status_code, row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.scenario_id,
    p.scenario_code,
    p.merchant_application_id,
    p.merchant_id,
    p.synthetic_account_id,
    p.synthetic_advance_id,
    p.m2_7_contract_code,
    p.m2_7_contract_version,
    p.m2_7_schema_version,
    p.m2_7_methodology_version,
    p.source_strategy_outcome_code,
    p.source_servicing_action_code,
    p.source_recommended_action_exposure_amount,
    p.operational_setup_outcome_code,
    p.operational_setup_action_code,
    p.operational_setup_priority_rank,
    p.operational_setup_queue_code,
    p.account_setup_status_code,
    p.setup_authorized_flag,
    p.blueprint_created_flag,
    p.setup_review_required_flag,
    p.no_setup_required_flag,
    p.synthetic_operational_case_id,
    p.synthetic_account_setup_id,
    p.synthetic_servicing_plan_id,
    p.operational_activation_date,
    p.next_reassessment_date,
    p.applied_temporary_payment_factor,
    p.applied_setup_duration_days,
    p.applied_reassessment_interval_days,
    p.primary_setup_reason_code,
    p.setup_reason_codes,
    p.setup_parameter_payload,
    p.m2_7_source_contract_row_hash,
    p.m2_7_source_snapshot_row_hash,
    p.m2_7_activation_snapshot_row_hash,
    p.m2_7_account_setup_snapshot_row_hash,
    p.m2_7_policy_configuration_hash,
    p.m2_7_contract_row_hash,
    p.m2_7_source_created_at,
    p.m2_10_contract_code,
    p.m2_10_contract_version,
    p.m2_10_schema_version,
    p.m2_10_methodology_version,
    p.source_final_lifecycle_state_code,
    p.certified_state_code,
    p.state_certified_flag,
    p.performance_tier_code,
    p.servicing_queue_code,
    p.payment_activity_flag,
    p.exception_incident_flag,
    p.exception_resolved_flag,
    p.payment_event_count,
    p.settled_event_count,
    p.returned_event_count,
    p.retry_event_count,
    p.exception_case_count,
    p.resolved_exception_count,
    p.unresolved_exception_count,
    p.source_exposure_amount,
    p.certified_exposure_amount,
    p.scheduled_payment_amount,
    p.processed_payment_amount,
    p.returned_payment_amount,
    p.retry_payment_amount,
    p.reconciliation_variance_amount,
    p.exposure_variance_amount,
    p.gross_collection_rate,
    p.return_rate,
    p.retry_cure_rate,
    p.exposure_retention_rate,
    p.servicing_burden_units,
    p.primary_portfolio_reason_code,
    p.portfolio_reason_codes,
    p.m2_10_source_contract_row_hash,
    p.m2_10_source_snapshot_row_hash,
    p.m2_10_performance_snapshot_row_hash,
    p.m2_10_policy_configuration_hash,
    p.m2_10_contract_row_hash,
    p.m2_10_source_created_at,
    p.operational_account_present_flag,
    p.source_account_posture_code,
    p.source_account_posture_rank,
    p.source_contract_identity_valid_flag,
    p.source_lineage_intact_flag,
    p.certification_blocked_flag,
    p.m2_7_contract_status,
    p.m2_7_combined_set_hash,
    p.m2_7_registry_row_hash,
    p.m2_10_contract_status,
    p.m2_10_combined_set_hash,
    p.m2_10_registry_row_hash,
    p.source_join_status_code,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_account_source_projection p
ORDER BY module1_run_id,scenario_id,merchant_application_id;

UPDATE tmp_src_m2_11_account_snapshot AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

CREATE UNIQUE INDEX tmp_src_m2_11_account_snapshot_u1 ON tmp_src_m2_11_account_snapshot(module1_run_id,scenario_id,merchant_application_id);
CREATE UNIQUE INDEX tmp_src_m2_11_account_snapshot_u2 ON tmp_src_m2_11_account_snapshot(module1_run_id,scenario_id,synthetic_account_id);
CREATE INDEX tmp_src_m2_11_account_snapshot_i1 ON tmp_src_m2_11_account_snapshot(module1_run_id,merchant_application_id,scenario_code);
ANALYZE tmp_src_m2_11_account_snapshot;

INSERT INTO msbf_m2.portfolio_strategy_account_source_snapshot
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    merchant_id, synthetic_account_id, synthetic_advance_id, m2_7_contract_code,
    m2_7_contract_version, m2_7_schema_version, m2_7_methodology_version, source_strategy_outcome_code,
    source_servicing_action_code, source_recommended_action_exposure_amount, operational_setup_outcome_code, operational_setup_action_code,
    operational_setup_priority_rank, operational_setup_queue_code, account_setup_status_code, setup_authorized_flag,
    blueprint_created_flag, setup_review_required_flag, no_setup_required_flag, synthetic_operational_case_id,
    synthetic_account_setup_id, synthetic_servicing_plan_id, operational_activation_date, next_reassessment_date,
    applied_temporary_payment_factor, applied_setup_duration_days, applied_reassessment_interval_days, primary_setup_reason_code,
    setup_reason_codes, setup_parameter_payload, m2_7_source_contract_row_hash, m2_7_source_snapshot_row_hash,
    m2_7_activation_snapshot_row_hash, m2_7_account_setup_snapshot_row_hash, m2_7_policy_configuration_hash, m2_7_contract_row_hash,
    m2_7_source_created_at, m2_10_contract_code, m2_10_contract_version, m2_10_schema_version,
    m2_10_methodology_version, source_final_lifecycle_state_code, certified_state_code, state_certified_flag,
    performance_tier_code, servicing_queue_code, payment_activity_flag, exception_incident_flag,
    exception_resolved_flag, payment_event_count, settled_event_count, returned_event_count,
    retry_event_count, exception_case_count, resolved_exception_count, unresolved_exception_count,
    source_exposure_amount, certified_exposure_amount, scheduled_payment_amount, processed_payment_amount,
    returned_payment_amount, retry_payment_amount, reconciliation_variance_amount, exposure_variance_amount,
    gross_collection_rate, return_rate, retry_cure_rate, exposure_retention_rate,
    servicing_burden_units, primary_portfolio_reason_code, portfolio_reason_codes, m2_10_source_contract_row_hash,
    m2_10_source_snapshot_row_hash, m2_10_performance_snapshot_row_hash, m2_10_policy_configuration_hash, m2_10_contract_row_hash,
    m2_10_source_created_at, operational_account_present_flag, source_account_posture_code, source_account_posture_rank,
    source_contract_identity_valid_flag, source_lineage_intact_flag, certification_blocked_flag, m2_7_contract_status,
    m2_7_combined_set_hash, m2_7_registry_row_hash, m2_10_contract_status, m2_10_combined_set_hash,
    m2_10_registry_row_hash, source_join_status_code, row_hash, created_at
)
SELECT
    t.module1_run_id,
    t.scenario_id,
    t.scenario_code,
    t.merchant_application_id,
    t.merchant_id,
    t.synthetic_account_id,
    t.synthetic_advance_id,
    t.m2_7_contract_code,
    t.m2_7_contract_version,
    t.m2_7_schema_version,
    t.m2_7_methodology_version,
    t.source_strategy_outcome_code,
    t.source_servicing_action_code,
    t.source_recommended_action_exposure_amount,
    t.operational_setup_outcome_code,
    t.operational_setup_action_code,
    t.operational_setup_priority_rank,
    t.operational_setup_queue_code,
    t.account_setup_status_code,
    t.setup_authorized_flag,
    t.blueprint_created_flag,
    t.setup_review_required_flag,
    t.no_setup_required_flag,
    t.synthetic_operational_case_id,
    t.synthetic_account_setup_id,
    t.synthetic_servicing_plan_id,
    t.operational_activation_date,
    t.next_reassessment_date,
    t.applied_temporary_payment_factor,
    t.applied_setup_duration_days,
    t.applied_reassessment_interval_days,
    t.primary_setup_reason_code,
    t.setup_reason_codes,
    t.setup_parameter_payload,
    t.m2_7_source_contract_row_hash,
    t.m2_7_source_snapshot_row_hash,
    t.m2_7_activation_snapshot_row_hash,
    t.m2_7_account_setup_snapshot_row_hash,
    t.m2_7_policy_configuration_hash,
    t.m2_7_contract_row_hash,
    t.m2_7_source_created_at,
    t.m2_10_contract_code,
    t.m2_10_contract_version,
    t.m2_10_schema_version,
    t.m2_10_methodology_version,
    t.source_final_lifecycle_state_code,
    t.certified_state_code,
    t.state_certified_flag,
    t.performance_tier_code,
    t.servicing_queue_code,
    t.payment_activity_flag,
    t.exception_incident_flag,
    t.exception_resolved_flag,
    t.payment_event_count,
    t.settled_event_count,
    t.returned_event_count,
    t.retry_event_count,
    t.exception_case_count,
    t.resolved_exception_count,
    t.unresolved_exception_count,
    t.source_exposure_amount,
    t.certified_exposure_amount,
    t.scheduled_payment_amount,
    t.processed_payment_amount,
    t.returned_payment_amount,
    t.retry_payment_amount,
    t.reconciliation_variance_amount,
    t.exposure_variance_amount,
    t.gross_collection_rate,
    t.return_rate,
    t.retry_cure_rate,
    t.exposure_retention_rate,
    t.servicing_burden_units,
    t.primary_portfolio_reason_code,
    t.portfolio_reason_codes,
    t.m2_10_source_contract_row_hash,
    t.m2_10_source_snapshot_row_hash,
    t.m2_10_performance_snapshot_row_hash,
    t.m2_10_policy_configuration_hash,
    t.m2_10_contract_row_hash,
    t.m2_10_source_created_at,
    t.operational_account_present_flag,
    t.source_account_posture_code,
    t.source_account_posture_rank,
    t.source_contract_identity_valid_flag,
    t.source_lineage_intact_flag,
    t.certification_blocked_flag,
    t.m2_7_contract_status,
    t.m2_7_combined_set_hash,
    t.m2_7_registry_row_hash,
    t.m2_10_contract_status,
    t.m2_10_combined_set_hash,
    t.m2_10_registry_row_hash,
    t.source_join_status_code,
    t.row_hash,
    t.created_at
FROM tmp_src_m2_11_account_snapshot t
ORDER BY module1_run_id,scenario_id,merchant_application_id;

CREATE TEMP TABLE tmp_eval_kpi_source_projection ON COMMIT DROP AS
SELECT
    k.module1_run_id AS module1_run_id,
    k.scope_code AS scope_code,
    k.scope_type AS scope_type,
    k.scenario_code AS scenario_code,
    k.kpi_code AS kpi_code,
    k.kpi_rank AS kpi_rank,
    k.unit_code AS unit_code,
    k.applicable_flag AS applicable_flag,
    k.kpi_value_numeric AS kpi_value_numeric,
    k.kpi_value_text AS kpi_value_text,
    k.numerator_value AS numerator_value,
    k.denominator_value AS denominator_value,
    k.primary_portfolio_reason_code AS primary_portfolio_reason_code,
    k.source_scope_row_hash AS source_scope_row_hash,
    k.row_hash AS source_kpi_row_hash,
    k.created_at AS source_kpi_created_at,
    r210.contract_code AS m2_10_contract_code,
    r210.contract_version AS m2_10_contract_version,
    r210.schema_version AS m2_10_schema_version,
    r210.methodology_version AS m2_10_methodology_version,
    r210.contract_status AS m2_10_contract_status,
    r210.combined_set_hash AS m2_10_combined_set_hash,
    r210.row_hash AS m2_10_registry_row_hash
FROM tmp_src_m2_10_kpi k CROSS JOIN tmp_src_m2_10_registry r210
ORDER BY module1_run_id,scope_code,kpi_code;

CREATE UNIQUE INDEX tmp_eval_kpi_source_projection_u1 ON tmp_eval_kpi_source_projection (module1_run_id, scope_code, kpi_code);
ANALYZE tmp_eval_kpi_source_projection;

/* Target-type-before-hash projection for msbf_m2.portfolio_strategy_kpi_source_snapshot. */
CREATE TEMP TABLE tmp_src_m2_11_kpi_snapshot ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_kpi_source_snapshot WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_src_m2_11_kpi_snapshot') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_kpi_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_src_m2_11_kpi_snapshot versus msbf_m2.portfolio_strategy_kpi_source_snapshot: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_src_m2_11_kpi_snapshot
(
    module1_run_id, scope_code, scope_type, scenario_code,
    kpi_code, kpi_rank, unit_code, applicable_flag,
    kpi_value_numeric, kpi_value_text, numerator_value, denominator_value,
    primary_portfolio_reason_code, source_scope_row_hash, source_kpi_row_hash, source_kpi_created_at,
    m2_10_contract_code, m2_10_contract_version, m2_10_schema_version, m2_10_methodology_version,
    m2_10_contract_status, m2_10_combined_set_hash, m2_10_registry_row_hash, row_hash,
    created_at
)
SELECT
    p.module1_run_id,
    p.scope_code,
    p.scope_type,
    p.scenario_code,
    p.kpi_code,
    p.kpi_rank,
    p.unit_code,
    p.applicable_flag,
    p.kpi_value_numeric,
    p.kpi_value_text,
    p.numerator_value,
    p.denominator_value,
    p.primary_portfolio_reason_code,
    p.source_scope_row_hash,
    p.source_kpi_row_hash,
    p.source_kpi_created_at,
    p.m2_10_contract_code,
    p.m2_10_contract_version,
    p.m2_10_schema_version,
    p.m2_10_methodology_version,
    p.m2_10_contract_status,
    p.m2_10_combined_set_hash,
    p.m2_10_registry_row_hash,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_kpi_source_projection p
ORDER BY module1_run_id,scope_code,kpi_code;

UPDATE tmp_src_m2_11_kpi_snapshot AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

CREATE UNIQUE INDEX tmp_src_m2_11_kpi_snapshot_u1 ON tmp_src_m2_11_kpi_snapshot(module1_run_id,scope_code,kpi_code);
ANALYZE tmp_src_m2_11_kpi_snapshot;

INSERT INTO msbf_m2.portfolio_strategy_kpi_source_snapshot
(
    module1_run_id, scope_code, scope_type, scenario_code,
    kpi_code, kpi_rank, unit_code, applicable_flag,
    kpi_value_numeric, kpi_value_text, numerator_value, denominator_value,
    primary_portfolio_reason_code, source_scope_row_hash, source_kpi_row_hash, source_kpi_created_at,
    m2_10_contract_code, m2_10_contract_version, m2_10_schema_version, m2_10_methodology_version,
    m2_10_contract_status, m2_10_combined_set_hash, m2_10_registry_row_hash, row_hash,
    created_at
)
SELECT
    t.module1_run_id,
    t.scope_code,
    t.scope_type,
    t.scenario_code,
    t.kpi_code,
    t.kpi_rank,
    t.unit_code,
    t.applicable_flag,
    t.kpi_value_numeric,
    t.kpi_value_text,
    t.numerator_value,
    t.denominator_value,
    t.primary_portfolio_reason_code,
    t.source_scope_row_hash,
    t.source_kpi_row_hash,
    t.source_kpi_created_at,
    t.m2_10_contract_code,
    t.m2_10_contract_version,
    t.m2_10_schema_version,
    t.m2_10_methodology_version,
    t.m2_10_contract_status,
    t.m2_10_combined_set_hash,
    t.m2_10_registry_row_hash,
    t.row_hash,
    t.created_at
FROM tmp_src_m2_11_kpi_snapshot t
ORDER BY module1_run_id,scope_code,kpi_code;

CREATE TEMP TABLE tmp_eval_queue_source_projection ON COMMIT DROP AS
SELECT
    q.module1_run_id AS module1_run_id,
    q.servicing_queue_code AS servicing_queue_code,
    q.account_count AS account_count,
    q.scenario_count AS scenario_count,
    q.certified_exposure_amount AS certified_exposure_amount,
    q.payment_event_count AS payment_event_count,
    q.exception_case_count AS exception_case_count,
    q.resolved_exception_count AS resolved_exception_count,
    q.unresolved_exception_count AS unresolved_exception_count,
    q.servicing_burden_units AS servicing_burden_units,
    q.maximum_tier_rank AS maximum_tier_rank,
    q.row_hash AS source_queue_row_hash,
    q.created_at AS source_queue_created_at,
    r210.contract_code AS m2_10_contract_code,
    r210.contract_version AS m2_10_contract_version,
    r210.schema_version AS m2_10_schema_version,
    r210.methodology_version AS m2_10_methodology_version,
    r210.contract_status AS m2_10_contract_status,
    r210.combined_set_hash AS m2_10_combined_set_hash,
    r210.row_hash AS m2_10_registry_row_hash
FROM tmp_src_m2_10_queue q CROSS JOIN tmp_src_m2_10_registry r210
ORDER BY module1_run_id,servicing_queue_code;

CREATE UNIQUE INDEX tmp_eval_queue_source_projection_u1 ON tmp_eval_queue_source_projection (module1_run_id, servicing_queue_code);
ANALYZE tmp_eval_queue_source_projection;

/* Target-type-before-hash projection for msbf_m2.portfolio_strategy_queue_source_snapshot. */
CREATE TEMP TABLE tmp_src_m2_11_queue_snapshot ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_queue_source_snapshot WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_src_m2_11_queue_snapshot') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_queue_source_snapshot'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_src_m2_11_queue_snapshot versus msbf_m2.portfolio_strategy_queue_source_snapshot: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_src_m2_11_queue_snapshot
(
    module1_run_id, servicing_queue_code, account_count, scenario_count,
    certified_exposure_amount, payment_event_count, exception_case_count, resolved_exception_count,
    unresolved_exception_count, servicing_burden_units, maximum_tier_rank, source_queue_row_hash,
    source_queue_created_at, m2_10_contract_code, m2_10_contract_version, m2_10_schema_version,
    m2_10_methodology_version, m2_10_contract_status, m2_10_combined_set_hash, m2_10_registry_row_hash,
    row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.servicing_queue_code,
    p.account_count,
    p.scenario_count,
    p.certified_exposure_amount,
    p.payment_event_count,
    p.exception_case_count,
    p.resolved_exception_count,
    p.unresolved_exception_count,
    p.servicing_burden_units,
    p.maximum_tier_rank,
    p.source_queue_row_hash,
    p.source_queue_created_at,
    p.m2_10_contract_code,
    p.m2_10_contract_version,
    p.m2_10_schema_version,
    p.m2_10_methodology_version,
    p.m2_10_contract_status,
    p.m2_10_combined_set_hash,
    p.m2_10_registry_row_hash,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_queue_source_projection p
ORDER BY module1_run_id,servicing_queue_code;

UPDATE tmp_src_m2_11_queue_snapshot AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

CREATE UNIQUE INDEX tmp_src_m2_11_queue_snapshot_u1 ON tmp_src_m2_11_queue_snapshot(module1_run_id,servicing_queue_code);
ANALYZE tmp_src_m2_11_queue_snapshot;

INSERT INTO msbf_m2.portfolio_strategy_queue_source_snapshot
(
    module1_run_id, servicing_queue_code, account_count, scenario_count,
    certified_exposure_amount, payment_event_count, exception_case_count, resolved_exception_count,
    unresolved_exception_count, servicing_burden_units, maximum_tier_rank, source_queue_row_hash,
    source_queue_created_at, m2_10_contract_code, m2_10_contract_version, m2_10_schema_version,
    m2_10_methodology_version, m2_10_contract_status, m2_10_combined_set_hash, m2_10_registry_row_hash,
    row_hash, created_at
)
SELECT
    t.module1_run_id,
    t.servicing_queue_code,
    t.account_count,
    t.scenario_count,
    t.certified_exposure_amount,
    t.payment_event_count,
    t.exception_case_count,
    t.resolved_exception_count,
    t.unresolved_exception_count,
    t.servicing_burden_units,
    t.maximum_tier_rank,
    t.source_queue_row_hash,
    t.source_queue_created_at,
    t.m2_10_contract_code,
    t.m2_10_contract_version,
    t.m2_10_schema_version,
    t.m2_10_methodology_version,
    t.m2_10_contract_status,
    t.m2_10_combined_set_hash,
    t.m2_10_registry_row_hash,
    t.row_hash,
    t.created_at
FROM tmp_src_m2_11_queue_snapshot t
ORDER BY module1_run_id,servicing_queue_code;

/* END_CANONICAL_SOURCE_SNAPSHOT_INSERTS
Downstream generation continues from the target-typed temporary source-snapshot
projections. Persistent source-snapshot tables are not read again until the
final physical reconstruction and ordered set-hash sections. */

/* Governed inherited M2.2 structure bounds. Values are read from the
M2.11 policy payload whose provenance is anchored to accepted M2.2 policy hash
9e03c9ee37880e3ed16e12fb0c0ce0d4. */
CREATE TEMP TABLE tmp_eval_m2_2_inherited_bounds ON COMMIT DROP AS
SELECT
  (configuration_payload #>> '{inherited_m2_2_structure_bounds,minimum_candidate_amount}')::numeric(18,2) AS minimum_candidate_amount,
  (configuration_payload #>> '{inherited_m2_2_structure_bounds,minimum_remittance_rate}')::numeric(9,6) AS minimum_remittance_rate,
  (configuration_payload #>> '{inherited_m2_2_structure_bounds,maximum_remittance_rate}')::numeric(9,6) AS maximum_remittance_rate,
  (configuration_payload #>> '{inherited_m2_2_structure_bounds,minimum_payback_multiple}')::numeric(9,6) AS minimum_payback_multiple,
  (configuration_payload #>> '{inherited_m2_2_structure_bounds,maximum_payback_multiple}')::numeric(9,6) AS maximum_payback_multiple,
  (configuration_payload #>> '{inherited_m2_2_structure_bounds,minimum_collection_horizon_days}')::integer AS minimum_collection_horizon_days,
  (configuration_payload #>> '{inherited_m2_2_structure_bounds,maximum_collection_horizon_days}')::integer AS maximum_collection_horizon_days,
  configuration_payload #>> '{inherited_m2_2_structure_bounds,source_policy_code}' AS source_policy_code,
  configuration_payload #>> '{inherited_m2_2_structure_bounds,source_policy_configuration_hash}' AS source_policy_configuration_hash
FROM msbf_ctl.m2_11_policy_profile
WHERE module1_run_id=(SELECT run_id FROM tmp_src_run_registry);

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n FROM tmp_eval_m2_2_inherited_bounds
  WHERE source_policy_code<>'M2_2_PRICING_STRUCTURE_POLICY_V1'
     OR source_policy_configuration_hash<>'9e03c9ee37880e3ed16e12fb0c0ce0d4'
     OR minimum_candidate_amount<>2500.00::numeric(18,2)
     OR minimum_remittance_rate<>0.050000::numeric(9,6)
     OR maximum_remittance_rate<>0.200000::numeric(9,6)
     OR minimum_payback_multiple<>1.050000::numeric(9,6)
     OR maximum_payback_multiple<>1.400000::numeric(9,6)
     OR minimum_collection_horizon_days<>1
     OR maximum_collection_horizon_days<>120;
  IF v_n<>0 OR (SELECT count(*) FROM tmp_eval_m2_2_inherited_bounds)<>1 THEN
    RAISE EXCEPTION 'Governed inherited M2.2 structure bounds failed reconciliation';
  END IF;
  IF EXISTS(SELECT 1 FROM tmp_src_m2_2_latest WHERE policy_configuration_hash<>'9e03c9ee37880e3ed16e12fb0c0ce0d4')
     OR EXISTS(SELECT 1 FROM tmp_src_m2_2_candidate WHERE policy_configuration_hash<>'9e03c9ee37880e3ed16e12fb0c0ce0d4') THEN
    RAISE EXCEPTION 'Accepted M2.2 source rows do not carry the frozen policy configuration hash';
  END IF;
END;
$m211$;
ANALYZE tmp_eval_m2_2_inherited_bounds;

/* ============================================================================
Section 6 — Candidate constraints, feasibility, finite alternative population,
normalization, scoring, and deterministic selection
============================================================================ */
CREATE TEMP TABLE tmp_eval_candidate_rule_base ON COMMIT DROP AS
SELECT
    c.module1_run_id,c.scenario_id,c.scenario_code,c.merchant_application_id,
    c.candidate_template_code,c.row_hash AS candidate_source_snapshot_row_hash,
    c.source_candidate_row_hash,c.candidate_rank,c.candidate_eligible_flag,
    c.source_route_code,c.source_route_rank,c.requested_funding_amount,
    c.candidate_funding_amount,c.candidate_remittance_rate,
    c.candidate_payback_multiple,c.candidate_collection_horizon_days,
    c.candidate_total_repayment_amount,c.candidate_finance_charge_amount,
    c.implied_daily_collection_amount,c.implied_payoff_days,
    c.amount_to_request_ratio,c.acquisition_economics_amount,
    c.expected_loss_amount,c.risk_adjusted_contribution_amount,
    c.annualized_return_rate,c.counteroffer_foundation_flag,
    c.source_m1_15_contract_row_hash,c.source_m1_16_contract_row_hash,
    c.source_g2_combined_hash,c.m2_2_contract_status,c.m2_2_combined_set_hash,
    a.structure_available_flag,a.review_required_flag,a.pricing_disposition_code,
    a.affordability_status,a.hard_stop_recommended_flag,a.economic_status,
    a.m1_15_contract_evidence_status,a.acquisition_contract_evidence_status,
    a.routing_evidence_status,a.source_join_status_code,
    (acct.module1_run_id IS NOT NULL) AS operational_account_present_flag,
    acct.state_certified_flag,acct.unresolved_exception_count,
    acct.certification_blocked_flag,acct.source_lineage_intact_flag,
    s.strategy_profile_code,s.selection_mode,s.selected_exposure_direction,
    s.access_rate_weight,s.selected_exposure_weight,s.finance_charge_weight,
    s.expected_loss_density_weight,s.risk_adjusted_contribution_weight,
    s.annualized_return_weight,s.payment_burden_weight,
    s.candidate_domain_weight_total,s.candidate_scoring_applicable_flag,
    CASE
      WHEN a.m1_15_contract_evidence_status='BLOCKED'
        OR a.acquisition_contract_evidence_status='BLOCKED'
        OR a.routing_evidence_status='BLOCKED' THEN 'BLOCKED'
      WHEN a.m1_15_contract_evidence_status='PARTIAL'
        OR a.acquisition_contract_evidence_status='PARTIAL'
        OR a.routing_evidence_status='PARTIAL' THEN 'PARTIAL'
      ELSE 'COMPLETE'
    END AS source_evidence_status_code,
    (
      c.m2_2_contract_status='ACCEPTED'
      AND c.m2_2_combined_set_hash='bbe83b187b31ea561789797322031fc6'
      AND a.source_join_status_code='MATCHED_ONE_TO_ONE'
      AND c.source_candidate_row_hash~'^[0-9a-f]{32}$'
      AND c.row_hash~'^[0-9a-f]{32}$'
      AND c.source_g2_combined_hash='e5ace7f32060ffb191c7bd0f8dd0c863'
    ) AS source_integrity_pass_flag,
    TRUE AS accepted_candidate_flag,
    array_remove(ARRAY[
      CASE WHEN NOT (
        c.m2_2_contract_status='ACCEPTED'
        AND c.m2_2_combined_set_hash='bbe83b187b31ea561789797322031fc6'
        AND a.source_join_status_code='MATCHED_ONE_TO_ONE'
        AND c.source_candidate_row_hash~'^[0-9a-f]{32}$'
        AND c.row_hash~'^[0-9a-f]{32}$'
        AND c.source_g2_combined_hash='e5ace7f32060ffb191c7bd0f8dd0c863'
      ) THEN 'ACCEPTED_SOURCE_IDENTITY' END,
      CASE WHEN NOT c.candidate_eligible_flag
              OR a.hard_stop_recommended_flag
              OR a.affordability_status IN ('UNAFFORDABLE','INSUFFICIENT_EVIDENCE')
           THEN 'AFFORDABILITY_INTEGRITY' END,
      CASE WHEN c.candidate_funding_amount<bnd.minimum_candidate_amount
              OR c.candidate_funding_amount>c.requested_funding_amount
              OR c.candidate_remittance_rate NOT BETWEEN bnd.minimum_remittance_rate AND bnd.maximum_remittance_rate
              OR c.candidate_payback_multiple NOT BETWEEN bnd.minimum_payback_multiple AND bnd.maximum_payback_multiple
              OR c.candidate_collection_horizon_days NOT BETWEEN bnd.minimum_collection_horizon_days AND bnd.maximum_collection_horizon_days
           THEN 'STRUCTURE_BOUNDS' END,
      CASE WHEN a.economic_status='NEGATIVE_CONTRIBUTION'
              OR coalesce(c.risk_adjusted_contribution_amount,0)<0
              OR coalesce(c.annualized_return_rate,0)<0
           THEN 'ECONOMIC_EVIDENCE' END,
      CASE WHEN acct.module1_run_id IS NOT NULL AND acct.certification_blocked_flag
           THEN 'EXCEPTION_CERTIFICATION_INTEGRITY' END
    ]::text[],NULL) AS hard_constraint_code_array,
    (
      c.candidate_eligible_flag
      AND c.expected_loss_amount IS NOT NULL
      AND c.risk_adjusted_contribution_amount IS NOT NULL
      AND c.annualized_return_rate IS NOT NULL
      AND c.candidate_finance_charge_amount IS NOT NULL
      AND a.m1_15_contract_evidence_status<>'BLOCKED'
      AND a.acquisition_contract_evidence_status<>'BLOCKED'
      AND a.routing_evidence_status<>'BLOCKED'
      AND a.economic_status<>'INSUFFICIENT_EVIDENCE'
    ) AS economics_supported_flag
FROM tmp_src_m2_11_candidate_snapshot c
JOIN tmp_src_m2_11_application_snapshot a
  USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
LEFT JOIN tmp_src_m2_11_account_snapshot acct
  USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
CROSS JOIN msbf_m2.portfolio_strategy_profile s
CROSS JOIN tmp_eval_m2_2_inherited_bounds bnd;

CREATE UNIQUE INDEX tmp_eval_candidate_rule_base_u1
ON tmp_eval_candidate_rule_base(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code);
ANALYZE tmp_eval_candidate_rule_base;

CREATE TEMP TABLE tmp_eval_candidate_classified ON COMMIT DROP AS
SELECT
    b.*,
    cardinality(b.hard_constraint_code_array)::integer AS hard_constraint_violation_count,
    to_jsonb(b.hard_constraint_code_array) AS hard_constraint_codes,
    CASE
      WHEN NOT b.source_integrity_pass_flag THEN 'BLOCKED_SOURCE_INTEGRITY'
      WHEN cardinality(b.hard_constraint_code_array)>0 THEN 'INFEASIBLE_HARD_CONSTRAINT'
      WHEN b.candidate_scoring_applicable_flag AND NOT b.economics_supported_flag THEN 'INFEASIBLE_OBJECTIVE_EVIDENCE'
      WHEN (b.source_route_code='MANUAL_REVIEW' OR b.review_required_flag)
        AND NOT
        (
          b.strategy_profile_code='ACCESS_EXPANSION'
          AND b.candidate_eligible_flag
          AND b.counteroffer_foundation_flag
          AND b.economic_status='ABOVE_HURDLE'
          AND b.risk_adjusted_contribution_amount>=0
          AND b.annualized_return_rate>=0
          AND b.source_evidence_status_code<>'BLOCKED'
          AND coalesce(b.unresolved_exception_count,0)=0
        ) THEN 'FEASIBLE_CONTROLLED_REVIEW'
      WHEN b.economic_status='BELOW_HURDLE' THEN 'FEASIBLE_CONTROLLED_REVIEW'
      ELSE 'FEASIBLE_ACCESS'
    END AS feasibility_class,
    CASE
      WHEN NOT b.source_integrity_pass_flag THEN 8
      WHEN cardinality(b.hard_constraint_code_array)>0 THEN 5
      WHEN b.candidate_scoring_applicable_flag AND NOT b.economics_supported_flag THEN 4
      WHEN (b.source_route_code='MANUAL_REVIEW' OR b.review_required_flag)
        AND NOT
        (
          b.strategy_profile_code='ACCESS_EXPANSION'
          AND b.candidate_eligible_flag
          AND b.counteroffer_foundation_flag
          AND b.economic_status='ABOVE_HURDLE'
          AND b.risk_adjusted_contribution_amount>=0
          AND b.annualized_return_rate>=0
          AND b.source_evidence_status_code<>'BLOCKED'
          AND coalesce(b.unresolved_exception_count,0)=0
        ) THEN 2
      WHEN b.economic_status='BELOW_HURDLE' THEN 2
      ELSE 1
    END::smallint AS feasibility_rank,
    b.economics_supported_flag AS objective_evidence_complete_flag,
    CASE WHEN
      CASE
        WHEN NOT b.source_integrity_pass_flag THEN 'BLOCKED_SOURCE_INTEGRITY'
        WHEN cardinality(b.hard_constraint_code_array)>0 THEN 'INFEASIBLE_HARD_CONSTRAINT'
        WHEN b.candidate_scoring_applicable_flag AND NOT b.economics_supported_flag THEN 'INFEASIBLE_OBJECTIVE_EVIDENCE'
        WHEN (b.source_route_code='MANUAL_REVIEW' OR b.review_required_flag)
          AND NOT
          (
            b.strategy_profile_code='ACCESS_EXPANSION' AND b.candidate_eligible_flag
            AND b.counteroffer_foundation_flag AND b.economic_status='ABOVE_HURDLE'
            AND b.risk_adjusted_contribution_amount>=0 AND b.annualized_return_rate>=0
            AND b.source_evidence_status_code<>'BLOCKED' AND coalesce(b.unresolved_exception_count,0)=0
          ) THEN 'FEASIBLE_CONTROLLED_REVIEW'
        WHEN b.economic_status='BELOW_HURDLE' THEN 'FEASIBLE_CONTROLLED_REVIEW'
        ELSE 'FEASIBLE_ACCESS'
      END='FEASIBLE_ACCESS' THEN 1::numeric(28,10) ELSE 0::numeric(28,10) END AS access_rate_raw_value,
    b.candidate_funding_amount::numeric(28,10) AS selected_exposure_amount_raw_value,
    b.candidate_finance_charge_amount::numeric(28,10) AS finance_charge_amount_raw_value,
    CASE WHEN b.candidate_funding_amount=0 THEN NULL ELSE round((b.expected_loss_amount/b.candidate_funding_amount)::numeric,10)::numeric(28,10) END AS expected_loss_density_raw_value,
    b.risk_adjusted_contribution_amount::numeric(28,10) AS risk_adjusted_contribution_raw_value,
    b.annualized_return_rate::numeric(28,10) AS annualized_risk_adjusted_return_raw_value,
    b.candidate_remittance_rate::numeric(28,10) AS payment_burden_rate_raw_value
FROM tmp_eval_candidate_rule_base b;

CREATE UNIQUE INDEX tmp_eval_candidate_classified_u1
ON tmp_eval_candidate_classified(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code);
ANALYZE tmp_eval_candidate_classified;

CREATE TEMP TABLE tmp_score_candidate_alternative_raw ON COMMIT DROP AS
SELECT
    c.module1_run_id,c.scenario_id,c.scenario_code,c.merchant_application_id,
    c.strategy_profile_code,c.candidate_template_code,FALSE AS implicit_no_access_flag,
    c.candidate_source_snapshot_row_hash,c.source_candidate_row_hash,c.candidate_rank,
    c.feasibility_class,c.feasibility_rank,
    c.access_rate_raw_value,c.selected_exposure_amount_raw_value,
    c.finance_charge_amount_raw_value,c.expected_loss_density_raw_value,
    c.risk_adjusted_contribution_raw_value,c.annualized_risk_adjusted_return_raw_value,
    c.payment_burden_rate_raw_value,c.selected_exposure_direction,
    c.access_rate_weight,c.selected_exposure_weight,c.finance_charge_weight,
    c.expected_loss_density_weight,c.risk_adjusted_contribution_weight,
    c.annualized_return_weight,c.payment_burden_weight,c.candidate_domain_weight_total
FROM tmp_eval_candidate_classified c
WHERE c.candidate_scoring_applicable_flag
  AND c.feasibility_class IN ('FEASIBLE_ACCESS','FEASIBLE_CONTROLLED_REVIEW')
  AND c.objective_evidence_complete_flag
UNION ALL
SELECT
    a.module1_run_id,a.scenario_id,a.scenario_code,a.merchant_application_id,
    s.strategy_profile_code,'IMPLICIT_NO_ACCESS'::text,TRUE,
    md5(a.row_hash||'|IMPLICIT_NO_ACCESS') AS candidate_source_snapshot_row_hash,
    md5(a.row_hash||'|IMPLICIT_NO_ACCESS_SOURCE') AS source_candidate_row_hash,
    2147483647::integer AS candidate_rank,
    'FEASIBLE_NO_ACCESS'::text AS feasibility_class,3::smallint AS feasibility_rank,
    0::numeric(28,10),0::numeric(28,10),0::numeric(28,10),0::numeric(28,10),
    0::numeric(28,10),0::numeric(28,10),0::numeric(28,10),
    s.selected_exposure_direction,
    s.access_rate_weight,s.selected_exposure_weight,s.finance_charge_weight,
    s.expected_loss_density_weight,s.risk_adjusted_contribution_weight,
    s.annualized_return_weight,s.payment_burden_weight,s.candidate_domain_weight_total
FROM tmp_src_m2_11_application_snapshot a
CROSS JOIN msbf_m2.portfolio_strategy_profile s
WHERE a.structure_available_flag AND s.candidate_scoring_applicable_flag;

CREATE INDEX tmp_score_candidate_alt_i1 ON tmp_score_candidate_alternative_raw
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,candidate_template_code);
ANALYZE tmp_score_candidate_alternative_raw;

CREATE TEMP TABLE tmp_score_candidate_normalized ON COMMIT DROP AS
WITH bounds AS
(
  SELECT r.*,
    min(access_rate_raw_value) OVER w AS access_min,max(access_rate_raw_value) OVER w AS access_max,
    min(selected_exposure_amount_raw_value) OVER w AS exposure_min,max(selected_exposure_amount_raw_value) OVER w AS exposure_max,
    min(finance_charge_amount_raw_value) OVER w AS finance_min,max(finance_charge_amount_raw_value) OVER w AS finance_max,
    min(expected_loss_density_raw_value) OVER w AS loss_min,max(expected_loss_density_raw_value) OVER w AS loss_max,
    min(risk_adjusted_contribution_raw_value) OVER w AS contribution_min,max(risk_adjusted_contribution_raw_value) OVER w AS contribution_max,
    min(annualized_risk_adjusted_return_raw_value) OVER w AS return_min,max(annualized_risk_adjusted_return_raw_value) OVER w AS return_max,
    min(payment_burden_rate_raw_value) OVER w AS payment_min,max(payment_burden_rate_raw_value) OVER w AS payment_max
  FROM tmp_score_candidate_alternative_raw r
  WINDOW w AS (PARTITION BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)
), norm AS
(
  SELECT b.*,
    round(CASE WHEN access_max=access_min THEN 1 ELSE (access_rate_raw_value-access_min)/(access_max-access_min) END,10)::numeric(18,10) AS access_norm,
    round(CASE WHEN exposure_max=exposure_min THEN 1 WHEN selected_exposure_direction='MINIMIZE' THEN (exposure_max-selected_exposure_amount_raw_value)/(exposure_max-exposure_min) ELSE (selected_exposure_amount_raw_value-exposure_min)/(exposure_max-exposure_min) END,10)::numeric(18,10) AS exposure_norm,
    round(CASE WHEN finance_max=finance_min THEN 1 ELSE (finance_charge_amount_raw_value-finance_min)/(finance_max-finance_min) END,10)::numeric(18,10) AS finance_norm,
    round(CASE WHEN loss_max=loss_min THEN 1 ELSE (loss_max-expected_loss_density_raw_value)/(loss_max-loss_min) END,10)::numeric(18,10) AS loss_norm,
    round(CASE WHEN contribution_max=contribution_min THEN 1 ELSE (risk_adjusted_contribution_raw_value-contribution_min)/(contribution_max-contribution_min) END,10)::numeric(18,10) AS contribution_norm,
    round(CASE WHEN return_max=return_min THEN 1 ELSE (annualized_risk_adjusted_return_raw_value-return_min)/(return_max-return_min) END,10)::numeric(18,10) AS return_norm,
    round(CASE WHEN payment_max=payment_min THEN 1 ELSE (payment_max-payment_burden_rate_raw_value)/(payment_max-payment_min) END,10)::numeric(18,10) AS payment_norm
  FROM bounds b
)
SELECT n.*,
  round(n.access_norm*n.access_rate_weight,12)::numeric(22,12) AS access_contribution,
  round(n.exposure_norm*n.selected_exposure_weight,12)::numeric(22,12) AS exposure_contribution,
  round(n.finance_norm*n.finance_charge_weight,12)::numeric(22,12) AS finance_contribution,
  round(n.loss_norm*n.expected_loss_density_weight,12)::numeric(22,12) AS loss_contribution,
  round(n.contribution_norm*n.risk_adjusted_contribution_weight,12)::numeric(22,12) AS contribution_contribution,
  round(n.return_norm*n.annualized_return_weight,12)::numeric(22,12) AS return_contribution,
  round(n.payment_norm*n.payment_burden_weight,12)::numeric(22,12) AS payment_contribution,
  round((n.access_norm*n.access_rate_weight+n.exposure_norm*n.selected_exposure_weight+n.finance_norm*n.finance_charge_weight+n.loss_norm*n.expected_loss_density_weight+n.contribution_norm*n.risk_adjusted_contribution_weight+n.return_norm*n.annualized_return_weight+n.payment_norm*n.payment_burden_weight)/NULLIF(n.candidate_domain_weight_total,0),12)::numeric(22,12) AS objective_score
FROM norm n;

CREATE INDEX tmp_score_candidate_norm_i1 ON tmp_score_candidate_normalized
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,objective_score DESC,feasibility_rank,candidate_rank,candidate_template_code);
ANALYZE tmp_score_candidate_normalized;

CREATE TEMP TABLE tmp_score_weighted_selected ON COMMIT DROP AS
WITH max_score AS
(
  SELECT module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,max(objective_score) AS max_objective_score
  FROM tmp_score_candidate_normalized
  GROUP BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code
), feasible_count AS
(
  SELECT module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,
         count(*) FILTER(WHERE NOT implicit_no_access_flag) AS feasible_accepted_count
  FROM tmp_score_candidate_normalized
  GROUP BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code
), top_tolerance AS
(
  SELECT n.*,
    count(*) OVER(PARTITION BY n.module1_run_id,n.scenario_id,n.merchant_application_id,n.strategy_profile_code) AS top_tolerance_count,
    f.feasible_accepted_count,
    row_number() OVER
    (
      PARTITION BY n.module1_run_id,n.scenario_id,n.merchant_application_id,n.strategy_profile_code
      ORDER BY n.feasibility_rank,n.candidate_rank,n.candidate_template_code,n.source_candidate_row_hash
    ) AS tolerance_rank
  FROM tmp_score_candidate_normalized n
  JOIN max_score m USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)
  JOIN feasible_count f USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)
  WHERE n.objective_score>=m.max_objective_score-0.000000000001::numeric(22,12)
)
SELECT * FROM top_tolerance WHERE tolerance_rank=1;

CREATE UNIQUE INDEX tmp_score_weighted_selected_u1 ON tmp_score_weighted_selected
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_score_weighted_selected;

CREATE TEMP TABLE tmp_score_candidate_tie ON COMMIT DROP AS
WITH mx AS
(
  SELECT module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,max(objective_score) AS max_score
  FROM tmp_score_candidate_normalized
  GROUP BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code
), tolerance_count AS
(
  SELECT n.module1_run_id,n.scenario_id,n.merchant_application_id,n.strategy_profile_code,
         m.max_score,
         count(*) FILTER(WHERE n.objective_score>=m.max_score-0.000000000001::numeric(22,12)) AS top_tolerance_count
  FROM tmp_score_candidate_normalized n
  JOIN mx m USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)
  GROUP BY n.module1_run_id,n.scenario_id,n.merchant_application_id,n.strategy_profile_code,m.max_score
)
SELECT n.module1_run_id,n.scenario_id,n.merchant_application_id,n.strategy_profile_code,n.candidate_template_code,
       t.max_score,t.top_tolerance_count
FROM tmp_score_candidate_normalized n
JOIN tolerance_count t USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);

CREATE UNIQUE INDEX tmp_score_candidate_tie_u1 ON tmp_score_candidate_tie
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,candidate_template_code);
ANALYZE tmp_score_candidate_tie;

CREATE TEMP TABLE tmp_eval_candidate_final_projection ON COMMIT DROP AS
SELECT
    c.module1_run_id AS module1_run_id,
    c.scenario_id AS scenario_id,
    c.scenario_code AS scenario_code,
    c.merchant_application_id AS merchant_application_id,
    c.candidate_template_code AS candidate_template_code,
    c.strategy_profile_code AS strategy_profile_code,
    c.candidate_source_snapshot_row_hash AS candidate_source_snapshot_row_hash,
    c.source_candidate_row_hash AS source_candidate_row_hash,
    c.candidate_rank AS candidate_rank,
    c.candidate_eligible_flag AS candidate_eligible_flag,
    c.source_route_code AS source_route_code,
    c.source_route_rank AS source_route_rank,
    c.source_evidence_status_code AS source_evidence_status_code,
    c.source_integrity_pass_flag AS source_integrity_pass_flag,
    c.accepted_candidate_flag AS accepted_candidate_flag,
    c.hard_constraint_violation_count AS hard_constraint_violation_count,
    c.hard_constraint_codes AS hard_constraint_codes,
    c.feasibility_class AS feasibility_class,
    c.feasibility_rank AS feasibility_rank,
    c.candidate_scoring_applicable_flag AS candidate_scoring_applicable_flag,
    c.objective_evidence_complete_flag AS objective_evidence_complete_flag,
    c.access_rate_raw_value AS access_rate_raw_value,
    n.access_min AS access_rate_minimum_value,
    n.access_max AS access_rate_maximum_value,
    n.access_norm AS access_rate_normalized_value,
    c.access_rate_weight AS access_rate_strategy_weight,
    n.access_contribution AS access_rate_weighted_contribution,
    c.selected_exposure_amount_raw_value AS selected_exposure_amount_raw_value,
    n.exposure_min AS selected_exposure_amount_minimum_value,
    n.exposure_max AS selected_exposure_amount_maximum_value,
    n.exposure_norm AS selected_exposure_amount_normalized_value,
    c.selected_exposure_weight AS selected_exposure_amount_strategy_weight,
    n.exposure_contribution AS selected_exposure_amount_weighted_contribution,
    c.finance_charge_amount_raw_value AS finance_charge_amount_raw_value,
    n.finance_min AS finance_charge_amount_minimum_value,
    n.finance_max AS finance_charge_amount_maximum_value,
    n.finance_norm AS finance_charge_amount_normalized_value,
    c.finance_charge_weight AS finance_charge_amount_strategy_weight,
    n.finance_contribution AS finance_charge_amount_weighted_contribution,
    c.expected_loss_density_raw_value AS expected_loss_density_raw_value,
    n.loss_min AS expected_loss_density_minimum_value,
    n.loss_max AS expected_loss_density_maximum_value,
    n.loss_norm AS expected_loss_density_normalized_value,
    c.expected_loss_density_weight AS expected_loss_density_strategy_weight,
    n.loss_contribution AS expected_loss_density_weighted_contribution,
    c.risk_adjusted_contribution_raw_value AS risk_adjusted_contribution_raw_value,
    n.contribution_min AS risk_adjusted_contribution_minimum_value,
    n.contribution_max AS risk_adjusted_contribution_maximum_value,
    n.contribution_norm AS risk_adjusted_contribution_normalized_value,
    c.risk_adjusted_contribution_weight AS risk_adjusted_contribution_strategy_weight,
    n.contribution_contribution AS risk_adjusted_contribution_weighted_contribution,
    c.annualized_risk_adjusted_return_raw_value AS annualized_risk_adjusted_return_raw_value,
    n.return_min AS annualized_risk_adjusted_return_minimum_value,
    n.return_max AS annualized_risk_adjusted_return_maximum_value,
    n.return_norm AS annualized_risk_adjusted_return_normalized_value,
    c.annualized_return_weight AS annualized_risk_adjusted_return_strategy_weight,
    n.return_contribution AS annualized_risk_adjusted_return_weighted_contribution,
    c.payment_burden_rate_raw_value AS payment_burden_rate_raw_value,
    n.payment_min AS payment_burden_rate_minimum_value,
    n.payment_max AS payment_burden_rate_maximum_value,
    n.payment_norm AS payment_burden_rate_normalized_value,
    c.payment_burden_weight AS payment_burden_rate_strategy_weight,
    n.payment_contribution AS payment_burden_rate_weighted_contribution,
    'NOT_APPLICABLE_CANDIDATE_GRAIN'::text AS servicing_burden_applicability_code,
    c.candidate_domain_weight_total AS applicable_candidate_weight_total,
    n.objective_score AS objective_score,
    coalesce(t.top_tolerance_count,0)>1 AND n.objective_score>=coalesce(t.max_score,n.objective_score)-0.000000000001::numeric(22,12) AS objective_score_tie_flag,
    CASE WHEN c.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN coalesce(c.candidate_template_code=a.selected_candidate_template_code AND c.source_candidate_row_hash=a.selected_candidate_row_hash,FALSE) WHEN c.candidate_scoring_applicable_flag THEN coalesce(w.candidate_template_code=c.candidate_template_code AND NOT w.implicit_no_access_flag,FALSE) ELSE FALSE END AS candidate_selected_flag,
    CASE WHEN NOT c.source_integrity_pass_flag THEN 'M2_11_REASON_SOURCE_EVIDENCE_BLOCKED' WHEN NOT c.candidate_eligible_flag THEN 'M2_11_REASON_CANDIDATE_NOT_ELIGIBLE' WHEN c.hard_constraint_codes ? 'STRUCTURE_BOUNDS' THEN 'M2_11_REASON_STRUCTURE_BOUND_VIOLATION' WHEN c.hard_constraint_codes ? 'AFFORDABILITY_INTEGRITY' THEN 'M2_11_REASON_AFFORDABILITY_CONSTRAINT' WHEN c.hard_constraint_codes ? 'EXCEPTION_CERTIFICATION_INTEGRITY' THEN 'M2_11_REASON_UNRESOLVED_EXCEPTION' WHEN c.hard_constraint_codes ? 'ECONOMIC_EVIDENCE' THEN 'M2_11_REASON_NEGATIVE_CONTRIBUTION' WHEN c.feasibility_class='INFEASIBLE_OBJECTIVE_EVIDENCE' THEN 'M2_11_REASON_ECONOMIC_EVIDENCE_BLOCKED' WHEN c.feasibility_class='FEASIBLE_CONTROLLED_REVIEW' THEN 'M2_11_REASON_BELOW_HURDLE_REVIEW' WHEN c.source_evidence_status_code='PARTIAL' THEN 'M2_11_REASON_SOURCE_EVIDENCE_PARTIAL' ELSE 'M2_11_REASON_SOURCE_CONTRACTS_VERIFIED' END AS primary_reason_code,
    to_jsonb(array_remove(ARRAY[CASE WHEN NOT c.source_integrity_pass_flag THEN 'M2_11_REASON_SOURCE_EVIDENCE_BLOCKED' END,CASE WHEN c.source_evidence_status_code='PARTIAL' THEN 'M2_11_REASON_SOURCE_EVIDENCE_PARTIAL' END,CASE WHEN NOT c.candidate_eligible_flag THEN 'M2_11_REASON_CANDIDATE_NOT_ELIGIBLE' END,CASE WHEN c.hard_constraint_codes ? 'STRUCTURE_BOUNDS' THEN 'M2_11_REASON_STRUCTURE_BOUND_VIOLATION' END,CASE WHEN c.hard_constraint_codes ? 'AFFORDABILITY_INTEGRITY' THEN 'M2_11_REASON_AFFORDABILITY_CONSTRAINT' END,CASE WHEN c.hard_constraint_codes ? 'ECONOMIC_EVIDENCE' THEN 'M2_11_REASON_NEGATIVE_CONTRIBUTION' END,CASE WHEN c.hard_constraint_codes ? 'EXCEPTION_CERTIFICATION_INTEGRITY' THEN 'M2_11_REASON_UNRESOLVED_EXCEPTION' END,CASE WHEN c.feasibility_class='INFEASIBLE_OBJECTIVE_EVIDENCE' THEN 'M2_11_REASON_ECONOMIC_EVIDENCE_BLOCKED' END,CASE WHEN c.feasibility_class='FEASIBLE_CONTROLLED_REVIEW' THEN 'M2_11_REASON_BELOW_HURDLE_REVIEW' END,CASE WHEN coalesce(t.top_tolerance_count,0)>1 AND n.objective_score>=coalesce(t.max_score,n.objective_score)-0.000000000001::numeric(22,12) THEN 'M2_11_REASON_DETERMINISTIC_TIE_BREAK_APPLIED' END]::text[],NULL)) AS reason_codes
FROM tmp_eval_candidate_classified c LEFT JOIN tmp_score_candidate_normalized n USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,strategy_profile_code,candidate_template_code) LEFT JOIN tmp_score_candidate_tie t USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code,candidate_template_code) LEFT JOIN tmp_score_weighted_selected w USING(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code) JOIN tmp_src_m2_11_application_snapshot a USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
ORDER BY c.module1_run_id,c.scenario_id,c.merchant_application_id,c.candidate_template_code,c.strategy_profile_code;

CREATE UNIQUE INDEX tmp_eval_candidate_final_u1 ON tmp_eval_candidate_final_projection(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code);
ANALYZE tmp_eval_candidate_final_projection;

/* Target-type-before-hash projection for msbf_m2.application_strategy_candidate_evaluation. */
CREATE TEMP TABLE tmp_eval_m2_11_candidate_evaluation ON COMMIT DROP AS
SELECT * FROM msbf_m2.application_strategy_candidate_evaluation WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_eval_m2_11_candidate_evaluation') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.application_strategy_candidate_evaluation'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_eval_m2_11_candidate_evaluation versus msbf_m2.application_strategy_candidate_evaluation: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_eval_m2_11_candidate_evaluation
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    candidate_template_code, strategy_profile_code, candidate_source_snapshot_row_hash, source_candidate_row_hash,
    candidate_rank, candidate_eligible_flag, source_route_code, source_route_rank,
    source_evidence_status_code, source_integrity_pass_flag, accepted_candidate_flag, hard_constraint_violation_count,
    hard_constraint_codes, feasibility_class, feasibility_rank, candidate_scoring_applicable_flag,
    objective_evidence_complete_flag, access_rate_raw_value, access_rate_minimum_value, access_rate_maximum_value,
    access_rate_normalized_value, access_rate_strategy_weight, access_rate_weighted_contribution, selected_exposure_amount_raw_value,
    selected_exposure_amount_minimum_value, selected_exposure_amount_maximum_value, selected_exposure_amount_normalized_value, selected_exposure_amount_strategy_weight,
    selected_exposure_amount_weighted_contribution, finance_charge_amount_raw_value, finance_charge_amount_minimum_value, finance_charge_amount_maximum_value,
    finance_charge_amount_normalized_value, finance_charge_amount_strategy_weight, finance_charge_amount_weighted_contribution, expected_loss_density_raw_value,
    expected_loss_density_minimum_value, expected_loss_density_maximum_value, expected_loss_density_normalized_value, expected_loss_density_strategy_weight,
    expected_loss_density_weighted_contribution, risk_adjusted_contribution_raw_value, risk_adjusted_contribution_minimum_value, risk_adjusted_contribution_maximum_value,
    risk_adjusted_contribution_normalized_value, risk_adjusted_contribution_strategy_weight, risk_adjusted_contribution_weighted_contribution, annualized_risk_adjusted_return_raw_value,
    annualized_risk_adjusted_return_minimum_value, annualized_risk_adjusted_return_maximum_value, annualized_risk_adjusted_return_normalized_value, annualized_risk_adjusted_return_strategy_weight,
    annualized_risk_adjusted_return_weighted_contribution, payment_burden_rate_raw_value, payment_burden_rate_minimum_value, payment_burden_rate_maximum_value,
    payment_burden_rate_normalized_value, payment_burden_rate_strategy_weight, payment_burden_rate_weighted_contribution, servicing_burden_applicability_code,
    applicable_candidate_weight_total, objective_score, objective_score_tie_flag, candidate_selected_flag,
    primary_reason_code, reason_codes, row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.scenario_id,
    p.scenario_code,
    p.merchant_application_id,
    p.candidate_template_code,
    p.strategy_profile_code,
    p.candidate_source_snapshot_row_hash,
    p.source_candidate_row_hash,
    p.candidate_rank,
    p.candidate_eligible_flag,
    p.source_route_code,
    p.source_route_rank,
    p.source_evidence_status_code,
    p.source_integrity_pass_flag,
    p.accepted_candidate_flag,
    p.hard_constraint_violation_count,
    p.hard_constraint_codes,
    p.feasibility_class,
    p.feasibility_rank,
    p.candidate_scoring_applicable_flag,
    p.objective_evidence_complete_flag,
    p.access_rate_raw_value,
    p.access_rate_minimum_value,
    p.access_rate_maximum_value,
    p.access_rate_normalized_value,
    p.access_rate_strategy_weight,
    p.access_rate_weighted_contribution,
    p.selected_exposure_amount_raw_value,
    p.selected_exposure_amount_minimum_value,
    p.selected_exposure_amount_maximum_value,
    p.selected_exposure_amount_normalized_value,
    p.selected_exposure_amount_strategy_weight,
    p.selected_exposure_amount_weighted_contribution,
    p.finance_charge_amount_raw_value,
    p.finance_charge_amount_minimum_value,
    p.finance_charge_amount_maximum_value,
    p.finance_charge_amount_normalized_value,
    p.finance_charge_amount_strategy_weight,
    p.finance_charge_amount_weighted_contribution,
    p.expected_loss_density_raw_value,
    p.expected_loss_density_minimum_value,
    p.expected_loss_density_maximum_value,
    p.expected_loss_density_normalized_value,
    p.expected_loss_density_strategy_weight,
    p.expected_loss_density_weighted_contribution,
    p.risk_adjusted_contribution_raw_value,
    p.risk_adjusted_contribution_minimum_value,
    p.risk_adjusted_contribution_maximum_value,
    p.risk_adjusted_contribution_normalized_value,
    p.risk_adjusted_contribution_strategy_weight,
    p.risk_adjusted_contribution_weighted_contribution,
    p.annualized_risk_adjusted_return_raw_value,
    p.annualized_risk_adjusted_return_minimum_value,
    p.annualized_risk_adjusted_return_maximum_value,
    p.annualized_risk_adjusted_return_normalized_value,
    p.annualized_risk_adjusted_return_strategy_weight,
    p.annualized_risk_adjusted_return_weighted_contribution,
    p.payment_burden_rate_raw_value,
    p.payment_burden_rate_minimum_value,
    p.payment_burden_rate_maximum_value,
    p.payment_burden_rate_normalized_value,
    p.payment_burden_rate_strategy_weight,
    p.payment_burden_rate_weighted_contribution,
    p.servicing_burden_applicability_code,
    p.applicable_candidate_weight_total,
    p.objective_score,
    p.objective_score_tie_flag,
    p.candidate_selected_flag,
    p.primary_reason_code,
    p.reason_codes,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_candidate_final_projection p
ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code;

UPDATE tmp_eval_m2_11_candidate_evaluation AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

-- Enforce the frozen candidate-evaluation grain and index the target-typed
-- construction authority before any downstream application-selection join.
CREATE UNIQUE INDEX tmp_eval_m2_11_candidate_evaluation_u1
ON tmp_eval_m2_11_candidate_evaluation
(module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code);
ANALYZE tmp_eval_m2_11_candidate_evaluation;

INSERT INTO msbf_m2.application_strategy_candidate_evaluation
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    candidate_template_code, strategy_profile_code, candidate_source_snapshot_row_hash, source_candidate_row_hash,
    candidate_rank, candidate_eligible_flag, source_route_code, source_route_rank,
    source_evidence_status_code, source_integrity_pass_flag, accepted_candidate_flag, hard_constraint_violation_count,
    hard_constraint_codes, feasibility_class, feasibility_rank, candidate_scoring_applicable_flag,
    objective_evidence_complete_flag, access_rate_raw_value, access_rate_minimum_value, access_rate_maximum_value,
    access_rate_normalized_value, access_rate_strategy_weight, access_rate_weighted_contribution, selected_exposure_amount_raw_value,
    selected_exposure_amount_minimum_value, selected_exposure_amount_maximum_value, selected_exposure_amount_normalized_value, selected_exposure_amount_strategy_weight,
    selected_exposure_amount_weighted_contribution, finance_charge_amount_raw_value, finance_charge_amount_minimum_value, finance_charge_amount_maximum_value,
    finance_charge_amount_normalized_value, finance_charge_amount_strategy_weight, finance_charge_amount_weighted_contribution, expected_loss_density_raw_value,
    expected_loss_density_minimum_value, expected_loss_density_maximum_value, expected_loss_density_normalized_value, expected_loss_density_strategy_weight,
    expected_loss_density_weighted_contribution, risk_adjusted_contribution_raw_value, risk_adjusted_contribution_minimum_value, risk_adjusted_contribution_maximum_value,
    risk_adjusted_contribution_normalized_value, risk_adjusted_contribution_strategy_weight, risk_adjusted_contribution_weighted_contribution, annualized_risk_adjusted_return_raw_value,
    annualized_risk_adjusted_return_minimum_value, annualized_risk_adjusted_return_maximum_value, annualized_risk_adjusted_return_normalized_value, annualized_risk_adjusted_return_strategy_weight,
    annualized_risk_adjusted_return_weighted_contribution, payment_burden_rate_raw_value, payment_burden_rate_minimum_value, payment_burden_rate_maximum_value,
    payment_burden_rate_normalized_value, payment_burden_rate_strategy_weight, payment_burden_rate_weighted_contribution, servicing_burden_applicability_code,
    applicable_candidate_weight_total, objective_score, objective_score_tie_flag, candidate_selected_flag,
    primary_reason_code, reason_codes, row_hash, created_at
)
SELECT
    t.module1_run_id,
    t.scenario_id,
    t.scenario_code,
    t.merchant_application_id,
    t.candidate_template_code,
    t.strategy_profile_code,
    t.candidate_source_snapshot_row_hash,
    t.source_candidate_row_hash,
    t.candidate_rank,
    t.candidate_eligible_flag,
    t.source_route_code,
    t.source_route_rank,
    t.source_evidence_status_code,
    t.source_integrity_pass_flag,
    t.accepted_candidate_flag,
    t.hard_constraint_violation_count,
    t.hard_constraint_codes,
    t.feasibility_class,
    t.feasibility_rank,
    t.candidate_scoring_applicable_flag,
    t.objective_evidence_complete_flag,
    t.access_rate_raw_value,
    t.access_rate_minimum_value,
    t.access_rate_maximum_value,
    t.access_rate_normalized_value,
    t.access_rate_strategy_weight,
    t.access_rate_weighted_contribution,
    t.selected_exposure_amount_raw_value,
    t.selected_exposure_amount_minimum_value,
    t.selected_exposure_amount_maximum_value,
    t.selected_exposure_amount_normalized_value,
    t.selected_exposure_amount_strategy_weight,
    t.selected_exposure_amount_weighted_contribution,
    t.finance_charge_amount_raw_value,
    t.finance_charge_amount_minimum_value,
    t.finance_charge_amount_maximum_value,
    t.finance_charge_amount_normalized_value,
    t.finance_charge_amount_strategy_weight,
    t.finance_charge_amount_weighted_contribution,
    t.expected_loss_density_raw_value,
    t.expected_loss_density_minimum_value,
    t.expected_loss_density_maximum_value,
    t.expected_loss_density_normalized_value,
    t.expected_loss_density_strategy_weight,
    t.expected_loss_density_weighted_contribution,
    t.risk_adjusted_contribution_raw_value,
    t.risk_adjusted_contribution_minimum_value,
    t.risk_adjusted_contribution_maximum_value,
    t.risk_adjusted_contribution_normalized_value,
    t.risk_adjusted_contribution_strategy_weight,
    t.risk_adjusted_contribution_weighted_contribution,
    t.annualized_risk_adjusted_return_raw_value,
    t.annualized_risk_adjusted_return_minimum_value,
    t.annualized_risk_adjusted_return_maximum_value,
    t.annualized_risk_adjusted_return_normalized_value,
    t.annualized_risk_adjusted_return_strategy_weight,
    t.annualized_risk_adjusted_return_weighted_contribution,
    t.payment_burden_rate_raw_value,
    t.payment_burden_rate_minimum_value,
    t.payment_burden_rate_maximum_value,
    t.payment_burden_rate_normalized_value,
    t.payment_burden_rate_strategy_weight,
    t.payment_burden_rate_weighted_contribution,
    t.servicing_burden_applicability_code,
    t.applicable_candidate_weight_total,
    t.objective_score,
    t.objective_score_tie_flag,
    t.candidate_selected_flag,
    t.primary_reason_code,
    t.reason_codes,
    t.row_hash,
    t.created_at
FROM tmp_eval_m2_11_candidate_evaluation t
ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n FROM tmp_eval_m2_11_candidate_evaluation;
  IF v_n<>4456 THEN RAISE EXCEPTION 'Candidate evaluation count expected 4456; found %',v_n; END IF;
  SELECT count(*) INTO v_n FROM tmp_eval_m2_11_candidate_evaluation WHERE candidate_template_code='IMPLICIT_NO_ACCESS';
  IF v_n<>0 THEN RAISE EXCEPTION 'Implicit no-access must not persist in candidate evaluation'; END IF;
END;
$m211$;

/* ============================================================================
Section 7 — Account-servicing strategy simulation and PORTFOLIO account rollup
============================================================================ */
CREATE TEMP TABLE tmp_eval_account_strategy_base ON COMMIT DROP AS
SELECT
    a.module1_run_id,a.scenario_id,a.scenario_code,a.merchant_application_id,
    a.synthetic_account_id,s.strategy_profile_code,
    a.row_hash AS account_source_snapshot_row_hash,
    a.source_account_posture_code,a.source_account_posture_rank,
    a.operational_setup_outcome_code AS source_operational_setup_outcome_code,
    a.operational_setup_action_code AS source_operational_setup_action_code,
    a.operational_setup_queue_code AS source_operational_setup_queue_code,
    a.operational_activation_date AS source_operational_activation_date,
    a.next_reassessment_date AS source_next_reassessment_date,
    a.applied_temporary_payment_factor AS source_payment_factor,
    a.applied_setup_duration_days AS source_setup_duration_days,
    a.applied_reassessment_interval_days AS source_reassessment_interval_days,
    a.certified_state_code AS source_certified_state_code,
    a.servicing_queue_code AS source_servicing_queue_code,
    a.certified_exposure_amount AS source_certified_exposure_amount,
    a.servicing_burden_units AS source_servicing_burden_units,
    CASE
      WHEN s.strategy_profile_code<>'EARLY_INTERVENTION' THEN 'SOURCE_SERVICING_REPLAY'
      WHEN a.source_account_posture_code='CLOSED_STABLE' THEN 'NO_INTERVENTION_REPLAY'
      WHEN a.source_account_posture_code='ACTIVE_RECONCILED' THEN 'EARLY_REASSESSMENT_SIMULATION'
      WHEN a.source_account_posture_code='CONTROLLED_REVIEW' THEN 'ACCELERATED_GOVERNANCE_REVIEW_SIMULATION'
      ELSE 'SOURCE_SERVICING_REPLAY'
    END AS servicing_treatment_code,
    (s.strategy_profile_code='EARLY_INTERVENTION' AND a.source_account_posture_code IN ('ACTIVE_RECONCILED','CONTROLLED_REVIEW')) AS treatment_applicable_flag,
    CASE
      WHEN s.strategy_profile_code='EARLY_INTERVENTION' AND a.source_account_posture_code='ACTIVE_RECONCILED'
        THEN greatest(a.operational_activation_date+1,a.next_reassessment_date-4)
      WHEN s.strategy_profile_code='EARLY_INTERVENTION' AND a.source_account_posture_code='CONTROLLED_REVIEW'
        THEN coalesce(a.operational_activation_date,(SELECT as_of_date FROM tmp_src_run_registry))+1
      ELSE NULL::date
    END AS simulated_action_date,
    a.applied_temporary_payment_factor AS simulated_payment_factor,
    a.certified_exposure_amount AS simulated_exposure_amount,
    CASE WHEN s.strategy_profile_code='EARLY_INTERVENTION' AND a.source_account_posture_code IN ('ACTIVE_RECONCILED','CONTROLLED_REVIEW') THEN 1.000000::numeric(12,6) ELSE 0.000000::numeric(12,6) END AS incremental_servicing_burden_units,
    (a.servicing_burden_units+CASE WHEN s.strategy_profile_code='EARLY_INTERVENTION' AND a.source_account_posture_code IN ('ACTIVE_RECONCILED','CONTROLLED_REVIEW') THEN 1.000000::numeric(12,6) ELSE 0.000000::numeric(12,6) END)::numeric(12,6) AS strategy_servicing_burden_units,
    FALSE AS risk_benefit_claimed_flag,FALSE AS return_benefit_claimed_flag,
    FALSE AS contribution_benefit_claimed_flag,FALSE AS payment_performance_benefit_claimed_flag,
    TRUE AS source_replay_match_flag,'COMPLETE'::text AS strategy_evidence_status,
    CASE WHEN s.strategy_profile_code='EARLY_INTERVENTION' AND a.source_account_posture_code IN ('ACTIVE_RECONCILED','CONTROLLED_REVIEW') THEN 'M2_11_REASON_EARLY_INTERVENTION_SIMULATED' WHEN a.source_account_posture_code='CLOSED_STABLE' THEN 'M2_11_REASON_CLOSED_STATE_PRESERVED' ELSE 'M2_11_REASON_BASELINE_REPLAY_MATCH' END AS primary_reason_code,
    to_jsonb(array_remove(ARRAY[
      'M2_11_REASON_BASELINE_REPLAY_MATCH',
      CASE WHEN a.source_account_posture_code='CLOSED_STABLE' THEN 'M2_11_REASON_CLOSED_STATE_PRESERVED' END,
      CASE WHEN s.strategy_profile_code='EARLY_INTERVENTION' AND a.source_account_posture_code IN ('ACTIVE_RECONCILED','CONTROLLED_REVIEW') THEN 'M2_11_REASON_EARLY_INTERVENTION_SIMULATED' END
    ]::text[],NULL)) AS reason_codes
FROM tmp_src_m2_11_account_snapshot a
CROSS JOIN msbf_m2.portfolio_strategy_profile s;

CREATE UNIQUE INDEX tmp_eval_account_strategy_base_u1 ON tmp_eval_account_strategy_base
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_account_strategy_base;

CREATE TEMP TABLE tmp_eval_account_strategy_prehashed ON COMMIT DROP AS
SELECT b.*,
  msbf_ctl.m2_11_hash_jsonb(
    to_jsonb(jsonb_populate_record(NULL::msbf_m2.account_servicing_strategy_simulation,to_jsonb(b)))
    - 'portfolio_adversity_order' - 'portfolio_adverse_selected_flag'
    - 'row_hash' - 'created_at'
  ) AS adversity_tiebreak_hash
FROM tmp_eval_account_strategy_base b;

CREATE TEMP TABLE tmp_eval_account_strategy_ranked ON COMMIT DROP AS
SELECT p.*,
       row_number() OVER
       (
         PARTITION BY module1_run_id,merchant_application_id,strategy_profile_code
         ORDER BY source_account_posture_rank DESC,strategy_servicing_burden_units DESC,
                  source_certified_exposure_amount DESC,
                  CASE scenario_code WHEN 'RECESSION_ENERGY' THEN 1 ELSE 2 END,
                  adversity_tiebreak_hash
       )::smallint AS portfolio_adversity_order
FROM tmp_eval_account_strategy_prehashed p;

CREATE INDEX tmp_eval_account_strategy_ranked_i1 ON tmp_eval_account_strategy_ranked
(module1_run_id,merchant_application_id,strategy_profile_code,portfolio_adversity_order);
ANALYZE tmp_eval_account_strategy_ranked;

CREATE TEMP TABLE tmp_eval_account_strategy_final ON COMMIT DROP AS
SELECT
    r.module1_run_id AS module1_run_id,
    r.scenario_id AS scenario_id,
    r.scenario_code AS scenario_code,
    r.merchant_application_id AS merchant_application_id,
    r.synthetic_account_id AS synthetic_account_id,
    r.strategy_profile_code AS strategy_profile_code,
    r.account_source_snapshot_row_hash AS account_source_snapshot_row_hash,
    r.source_account_posture_code AS source_account_posture_code,
    r.source_account_posture_rank AS source_account_posture_rank,
    r.source_operational_setup_outcome_code AS source_operational_setup_outcome_code,
    r.source_operational_setup_action_code AS source_operational_setup_action_code,
    r.source_operational_setup_queue_code AS source_operational_setup_queue_code,
    r.source_operational_activation_date AS source_operational_activation_date,
    r.source_next_reassessment_date AS source_next_reassessment_date,
    r.source_payment_factor AS source_payment_factor,
    r.source_setup_duration_days AS source_setup_duration_days,
    r.source_reassessment_interval_days AS source_reassessment_interval_days,
    r.source_certified_state_code AS source_certified_state_code,
    r.source_servicing_queue_code AS source_servicing_queue_code,
    r.source_certified_exposure_amount AS source_certified_exposure_amount,
    r.source_servicing_burden_units AS source_servicing_burden_units,
    r.servicing_treatment_code AS servicing_treatment_code,
    r.treatment_applicable_flag AS treatment_applicable_flag,
    r.simulated_action_date AS simulated_action_date,
    r.simulated_payment_factor AS simulated_payment_factor,
    r.simulated_exposure_amount AS simulated_exposure_amount,
    r.incremental_servicing_burden_units AS incremental_servicing_burden_units,
    r.strategy_servicing_burden_units AS strategy_servicing_burden_units,
    r.risk_benefit_claimed_flag AS risk_benefit_claimed_flag,
    r.return_benefit_claimed_flag AS return_benefit_claimed_flag,
    r.contribution_benefit_claimed_flag AS contribution_benefit_claimed_flag,
    r.payment_performance_benefit_claimed_flag AS payment_performance_benefit_claimed_flag,
    r.source_replay_match_flag AS source_replay_match_flag,
    r.strategy_evidence_status AS strategy_evidence_status,
    r.primary_reason_code AS primary_reason_code,
    r.reason_codes AS reason_codes,
    (r.portfolio_adversity_order=1) AS portfolio_adverse_selected_flag,
    r.portfolio_adversity_order AS portfolio_adversity_order
FROM tmp_eval_account_strategy_ranked r
ORDER BY r.module1_run_id,r.scenario_id,r.merchant_application_id,r.strategy_profile_code;

CREATE UNIQUE INDEX tmp_eval_account_strategy_final_u1 ON tmp_eval_account_strategy_final(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_account_strategy_final;

/* Target-type-before-hash projection for msbf_m2.account_servicing_strategy_simulation. */
CREATE TEMP TABLE tmp_eval_m2_11_account_simulation ON COMMIT DROP AS
SELECT * FROM msbf_m2.account_servicing_strategy_simulation WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_eval_m2_11_account_simulation') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.account_servicing_strategy_simulation'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_eval_m2_11_account_simulation versus msbf_m2.account_servicing_strategy_simulation: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_eval_m2_11_account_simulation
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    synthetic_account_id, strategy_profile_code, account_source_snapshot_row_hash, source_account_posture_code,
    source_account_posture_rank, source_operational_setup_outcome_code, source_operational_setup_action_code, source_operational_setup_queue_code,
    source_operational_activation_date, source_next_reassessment_date, source_payment_factor, source_setup_duration_days,
    source_reassessment_interval_days, source_certified_state_code, source_servicing_queue_code, source_certified_exposure_amount,
    source_servicing_burden_units, servicing_treatment_code, treatment_applicable_flag, simulated_action_date,
    simulated_payment_factor, simulated_exposure_amount, incremental_servicing_burden_units, strategy_servicing_burden_units,
    risk_benefit_claimed_flag, return_benefit_claimed_flag, contribution_benefit_claimed_flag, payment_performance_benefit_claimed_flag,
    source_replay_match_flag, strategy_evidence_status, portfolio_adverse_selected_flag, portfolio_adversity_order,
    primary_reason_code, reason_codes, row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.scenario_id,
    p.scenario_code,
    p.merchant_application_id,
    p.synthetic_account_id,
    p.strategy_profile_code,
    p.account_source_snapshot_row_hash,
    p.source_account_posture_code,
    p.source_account_posture_rank,
    p.source_operational_setup_outcome_code,
    p.source_operational_setup_action_code,
    p.source_operational_setup_queue_code,
    p.source_operational_activation_date,
    p.source_next_reassessment_date,
    p.source_payment_factor,
    p.source_setup_duration_days,
    p.source_reassessment_interval_days,
    p.source_certified_state_code,
    p.source_servicing_queue_code,
    p.source_certified_exposure_amount,
    p.source_servicing_burden_units,
    p.servicing_treatment_code,
    p.treatment_applicable_flag,
    p.simulated_action_date,
    p.simulated_payment_factor,
    p.simulated_exposure_amount,
    p.incremental_servicing_burden_units,
    p.strategy_servicing_burden_units,
    p.risk_benefit_claimed_flag,
    p.return_benefit_claimed_flag,
    p.contribution_benefit_claimed_flag,
    p.payment_performance_benefit_claimed_flag,
    p.source_replay_match_flag,
    p.strategy_evidence_status,
    p.portfolio_adverse_selected_flag,
    p.portfolio_adversity_order,
    p.primary_reason_code,
    p.reason_codes,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_account_strategy_final p
ORDER BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code;

UPDATE tmp_eval_m2_11_account_simulation AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

-- Enforce the frozen account-simulation grain and index the target-typed
-- construction authority before application association and scope rollup.
CREATE UNIQUE INDEX tmp_eval_m2_11_account_simulation_u1
ON tmp_eval_m2_11_account_simulation
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_m2_11_account_simulation;

INSERT INTO msbf_m2.account_servicing_strategy_simulation
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    synthetic_account_id, strategy_profile_code, account_source_snapshot_row_hash, source_account_posture_code,
    source_account_posture_rank, source_operational_setup_outcome_code, source_operational_setup_action_code, source_operational_setup_queue_code,
    source_operational_activation_date, source_next_reassessment_date, source_payment_factor, source_setup_duration_days,
    source_reassessment_interval_days, source_certified_state_code, source_servicing_queue_code, source_certified_exposure_amount,
    source_servicing_burden_units, servicing_treatment_code, treatment_applicable_flag, simulated_action_date,
    simulated_payment_factor, simulated_exposure_amount, incremental_servicing_burden_units, strategy_servicing_burden_units,
    risk_benefit_claimed_flag, return_benefit_claimed_flag, contribution_benefit_claimed_flag, payment_performance_benefit_claimed_flag,
    source_replay_match_flag, strategy_evidence_status, portfolio_adverse_selected_flag, portfolio_adversity_order,
    primary_reason_code, reason_codes, row_hash, created_at
)
SELECT
    t.module1_run_id,
    t.scenario_id,
    t.scenario_code,
    t.merchant_application_id,
    t.synthetic_account_id,
    t.strategy_profile_code,
    t.account_source_snapshot_row_hash,
    t.source_account_posture_code,
    t.source_account_posture_rank,
    t.source_operational_setup_outcome_code,
    t.source_operational_setup_action_code,
    t.source_operational_setup_queue_code,
    t.source_operational_activation_date,
    t.source_next_reassessment_date,
    t.source_payment_factor,
    t.source_setup_duration_days,
    t.source_reassessment_interval_days,
    t.source_certified_state_code,
    t.source_servicing_queue_code,
    t.source_certified_exposure_amount,
    t.source_servicing_burden_units,
    t.servicing_treatment_code,
    t.treatment_applicable_flag,
    t.simulated_action_date,
    t.simulated_payment_factor,
    t.simulated_exposure_amount,
    t.incremental_servicing_burden_units,
    t.strategy_servicing_burden_units,
    t.risk_benefit_claimed_flag,
    t.return_benefit_claimed_flag,
    t.contribution_benefit_claimed_flag,
    t.payment_performance_benefit_claimed_flag,
    t.source_replay_match_flag,
    t.strategy_evidence_status,
    t.portfolio_adverse_selected_flag,
    t.portfolio_adversity_order,
    t.primary_reason_code,
    t.reason_codes,
    t.row_hash,
    t.created_at
FROM tmp_eval_m2_11_account_simulation t
ORDER BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n FROM tmp_eval_m2_11_account_simulation;
  IF v_n<>472 THEN RAISE EXCEPTION 'Account servicing simulation expected 472; found %',v_n; END IF;
  SELECT count(*) INTO v_n FROM tmp_eval_m2_11_account_simulation WHERE portfolio_adverse_selected_flag;
  IF v_n<>352 THEN RAISE EXCEPTION 'PORTFOLIO account rollup expected 44 x 8 = 352 adverse selections; found %',v_n; END IF;
  SELECT sum(incremental_servicing_burden_units)::bigint INTO v_n
  FROM tmp_eval_m2_11_account_simulation WHERE strategy_profile_code='EARLY_INTERVENTION';
  IF v_n<>2 THEN RAISE EXCEPTION 'EARLY_INTERVENTION expected +2 burden units; found %',v_n; END IF;
  SELECT count(*) INTO v_n FROM tmp_eval_m2_11_account_simulation
  WHERE risk_benefit_claimed_flag OR return_benefit_claimed_flag OR contribution_benefit_claimed_flag OR payment_performance_benefit_claimed_flag;
  IF v_n<>0 THEN RAISE EXCEPTION 'Account strategy benefit-claim boundary violation count %',v_n; END IF;

  SELECT count(*) INTO v_n
  FROM tmp_eval_m2_11_account_simulation s
  JOIN tmp_src_m2_11_account_snapshot a
    USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,synthetic_account_id)
  WHERE s.account_source_snapshot_row_hash IS DISTINCT FROM a.row_hash
     OR s.source_account_posture_code IS DISTINCT FROM a.source_account_posture_code
     OR s.source_account_posture_rank IS DISTINCT FROM a.source_account_posture_rank
     OR s.source_operational_setup_outcome_code IS DISTINCT FROM a.operational_setup_outcome_code
     OR s.source_operational_setup_action_code IS DISTINCT FROM a.operational_setup_action_code
     OR s.source_operational_setup_queue_code IS DISTINCT FROM a.operational_setup_queue_code
     OR s.source_operational_activation_date IS DISTINCT FROM a.operational_activation_date
     OR s.source_next_reassessment_date IS DISTINCT FROM a.next_reassessment_date
     OR s.source_payment_factor IS DISTINCT FROM a.applied_temporary_payment_factor
     OR s.source_setup_duration_days IS DISTINCT FROM a.applied_setup_duration_days
     OR s.source_reassessment_interval_days IS DISTINCT FROM a.applied_reassessment_interval_days
     OR s.source_certified_state_code IS DISTINCT FROM a.certified_state_code
     OR s.source_servicing_queue_code IS DISTINCT FROM a.servicing_queue_code
     OR s.source_certified_exposure_amount IS DISTINCT FROM a.certified_exposure_amount
     OR s.source_servicing_burden_units IS DISTINCT FROM a.servicing_burden_units
     OR NOT s.source_replay_match_flag;
  IF v_n<>0 THEN RAISE EXCEPTION 'Account source replay mismatch count %',v_n; END IF;

  SELECT count(*) INTO v_n
  FROM tmp_eval_m2_11_account_simulation s
  JOIN tmp_src_m2_11_account_snapshot a
    USING(module1_run_id,scenario_id,scenario_code,merchant_application_id,synthetic_account_id)
  WHERE s.strategy_profile_code='EARLY_INTERVENTION'
    AND (
      (a.source_account_posture_code='CLOSED_STABLE' AND
        (s.servicing_treatment_code<>'NO_INTERVENTION_REPLAY' OR s.treatment_applicable_flag
         OR s.simulated_action_date IS NOT NULL OR s.incremental_servicing_burden_units<>0))
      OR
      (a.source_account_posture_code='ACTIVE_RECONCILED' AND
        (s.servicing_treatment_code<>'EARLY_REASSESSMENT_SIMULATION' OR NOT s.treatment_applicable_flag
         OR s.simulated_action_date IS DISTINCT FROM greatest(a.operational_activation_date+1,a.next_reassessment_date-4)
         OR s.incremental_servicing_burden_units<>1.000000::numeric(12,6)))
      OR
      (a.source_account_posture_code='CONTROLLED_REVIEW' AND
        (s.servicing_treatment_code<>'ACCELERATED_GOVERNANCE_REVIEW_SIMULATION' OR NOT s.treatment_applicable_flag
         OR s.simulated_action_date IS DISTINCT FROM coalesce(a.operational_activation_date,(SELECT as_of_date FROM tmp_src_run_registry))+1
         OR s.incremental_servicing_burden_units<>1.000000::numeric(12,6)))
    );
  IF v_n<>0 THEN RAISE EXCEPTION 'EARLY_INTERVENTION timing-treatment mismatch count %',v_n; END IF;
END;
$m211$;

/* ============================================================================
Section 8 — Application strategy outcome selection and account association
============================================================================ */
CREATE TEMP TABLE tmp_eval_app_selection_joined ON COMMIT DROP AS
SELECT
    a.*,
    s.selection_mode,s.candidate_scoring_applicable_flag,
    w.candidate_template_code AS weighted_candidate_template_code,
    w.implicit_no_access_flag AS weighted_implicit_no_access_flag,
    w.feasibility_class AS weighted_feasibility_class,
    w.feasibility_rank AS weighted_feasibility_rank,
    w.objective_score AS weighted_objective_score,
    w.feasible_accepted_count,
    w.top_tolerance_count,
    cs.row_hash AS weighted_candidate_snapshot_row_hash,
    cs.source_candidate_row_hash AS weighted_candidate_source_row_hash,
    cs.candidate_funding_amount AS weighted_funding_amount,
    cs.candidate_remittance_rate AS weighted_remittance_rate,
    cs.candidate_payback_multiple AS weighted_payback_multiple,
    cs.candidate_collection_horizon_days AS weighted_collection_horizon_days,
    cs.candidate_total_repayment_amount AS weighted_total_repayment_amount,
    cs.candidate_finance_charge_amount AS weighted_finance_charge_amount,
    cs.implied_daily_collection_amount AS weighted_implied_daily_collection_amount,
    cs.implied_payoff_days AS weighted_implied_payoff_days,
    cs.amount_to_request_ratio AS weighted_amount_to_request_ratio,
    cs.acquisition_economics_amount AS weighted_acquisition_economics_amount,
    cs.expected_loss_amount AS weighted_expected_loss_amount,
    cs.risk_adjusted_contribution_amount AS weighted_contribution_amount,
    cs.annualized_return_rate AS weighted_annualized_return_rate,
    ce.row_hash AS weighted_candidate_evaluation_row_hash,
    ce.hard_constraint_violation_count AS weighted_hard_constraint_violation_count,
    ce.hard_constraint_codes AS weighted_hard_constraint_codes,
    ce.source_evidence_status_code AS weighted_candidate_evidence_status,
    cr.row_hash AS replay_candidate_snapshot_row_hash,
    cr.source_candidate_row_hash AS replay_candidate_source_row_hash,
    cr.expected_loss_amount AS replay_expected_loss_amount,
    cr.risk_adjusted_contribution_amount AS replay_contribution_amount,
    cr.annualized_return_rate AS replay_annualized_return_rate,
    cr.acquisition_economics_amount AS replay_acquisition_economics_amount,
    cer.row_hash AS replay_candidate_evaluation_row_hash,
    cer.hard_constraint_violation_count AS replay_hard_constraint_violation_count,
    cer.hard_constraint_codes AS replay_hard_constraint_codes,
    acct.row_hash AS account_source_snapshot_row_hash,
    acct.unresolved_exception_count AS account_unresolved_exception_count,
    acct.certified_state_code AS account_certified_state_code,
    acct.servicing_queue_code AS account_servicing_queue_code,
    acct.certified_exposure_amount AS account_certified_exposure_amount,
    acct.certification_blocked_flag AS account_certification_blocked_flag,
    acct.source_lineage_intact_flag AS account_source_lineage_intact_flag,
    asv.row_hash AS associated_account_servicing_simulation_row_hash,
    asv.servicing_treatment_code AS associated_servicing_treatment_code,
    asv.strategy_servicing_burden_units AS associated_servicing_burden_units
FROM tmp_src_m2_11_application_snapshot a
CROSS JOIN msbf_m2.portfolio_strategy_profile s
LEFT JOIN tmp_score_weighted_selected w
  ON w.module1_run_id=a.module1_run_id
 AND w.scenario_id=a.scenario_id
 AND w.merchant_application_id=a.merchant_application_id
 AND w.strategy_profile_code=s.strategy_profile_code
LEFT JOIN tmp_src_m2_11_candidate_snapshot cs
  ON cs.module1_run_id=a.module1_run_id
 AND cs.scenario_id=a.scenario_id
 AND cs.merchant_application_id=a.merchant_application_id
 AND cs.candidate_template_code=w.candidate_template_code
 AND NOT coalesce(w.implicit_no_access_flag,FALSE)
LEFT JOIN tmp_eval_m2_11_candidate_evaluation ce
  ON ce.module1_run_id=a.module1_run_id
 AND ce.scenario_id=a.scenario_id
 AND ce.merchant_application_id=a.merchant_application_id
 AND ce.strategy_profile_code=s.strategy_profile_code
 AND ce.candidate_template_code=w.candidate_template_code
 AND NOT coalesce(w.implicit_no_access_flag,FALSE)
LEFT JOIN tmp_src_m2_11_candidate_snapshot cr
  ON cr.module1_run_id=a.module1_run_id
 AND cr.scenario_id=a.scenario_id
 AND cr.merchant_application_id=a.merchant_application_id
 AND cr.candidate_template_code=a.selected_candidate_template_code
 AND cr.source_candidate_row_hash=a.selected_candidate_row_hash
LEFT JOIN tmp_eval_m2_11_candidate_evaluation cer
  ON cer.module1_run_id=a.module1_run_id
 AND cer.scenario_id=a.scenario_id
 AND cer.merchant_application_id=a.merchant_application_id
 AND cer.strategy_profile_code=s.strategy_profile_code
 AND cer.candidate_template_code=a.selected_candidate_template_code
LEFT JOIN tmp_src_m2_11_account_snapshot acct
  USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
LEFT JOIN tmp_eval_m2_11_account_simulation asv
  ON asv.module1_run_id=a.module1_run_id
 AND asv.scenario_id=a.scenario_id
 AND asv.merchant_application_id=a.merchant_application_id
 AND asv.strategy_profile_code=s.strategy_profile_code;

CREATE UNIQUE INDEX tmp_eval_app_selection_joined_u1
ON tmp_eval_app_selection_joined(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_app_selection_joined;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n
  FROM tmp_eval_app_selection_joined
  WHERE candidate_scoring_applicable_flag AND structure_available_flag
    AND (weighted_candidate_template_code IS NULL OR weighted_implicit_no_access_flag IS NULL);
  IF v_n<>0 THEN RAISE EXCEPTION 'Weighted strategy selection missing for structure-available application rows %',v_n; END IF;

  SELECT count(*) INTO v_n
  FROM tmp_eval_app_selection_joined
  WHERE candidate_scoring_applicable_flag AND structure_available_flag
    AND NOT weighted_implicit_no_access_flag
    AND (weighted_candidate_snapshot_row_hash IS NULL OR weighted_candidate_evaluation_row_hash IS NULL);
  IF v_n<>0 THEN RAISE EXCEPTION 'Weighted accepted-candidate association mismatch rows %',v_n; END IF;

  SELECT count(*) INTO v_n
  FROM tmp_eval_app_selection_joined
  WHERE strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
    AND structure_available_flag
    AND (replay_candidate_snapshot_row_hash IS NULL OR replay_candidate_evaluation_row_hash IS NULL);
  IF v_n<>0 THEN RAISE EXCEPTION 'Replay selected-candidate association mismatch rows %',v_n; END IF;

  SELECT count(*) INTO v_n
  FROM tmp_eval_app_selection_joined
  WHERE (account_source_snapshot_row_hash IS NULL)<>(associated_account_servicing_simulation_row_hash IS NULL);
  IF v_n<>0 THEN RAISE EXCEPTION 'Application/account servicing association mismatch rows %',v_n; END IF;
END;
$m211$;

CREATE TEMP TABLE tmp_eval_app_decision ON COMMIT DROP AS
WITH d AS
(
  SELECT j.*,
    CASE
      WHEN j.source_join_status_code<>'MATCHED_ONE_TO_ONE'
        OR (j.structure_available_flag AND j.selected_candidate_template_code IS NOT NULL AND j.replay_candidate_snapshot_row_hash IS NULL)
        OR j.activation_outcome_code='NO_ACTIVATION_SOURCE_BOUNDARY'
        THEN 'BLOCKED_SOURCE_INTEGRITY'
      WHEN j.pricing_disposition_code='NO_STRUCTURE_POLICY_DECLINE'
        THEN 'NO_ACCESS_POLICY_DECLINE'
      WHEN j.pricing_disposition_code='NO_STRUCTURE_INSUFFICIENT_EVIDENCE'
        THEN 'NO_ACCESS_INSUFFICIENT_EVIDENCE'
      WHEN j.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN
        CASE j.activation_outcome_code
          WHEN 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED' THEN 'ACCESS_SELECTED'
          WHEN 'ACTIVATION_REVIEW_REQUIRED' THEN 'CONTROLLED_REVIEW'
          WHEN 'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE' THEN 'NO_ACCESS_INSUFFICIENT_EVIDENCE'
          WHEN 'NOT_ACTIVATED_POLICY_DECLINE' THEN 'NO_ACCESS_POLICY_DECLINE'
          ELSE 'BLOCKED_SOURCE_INTEGRITY'
        END
      WHEN coalesce(j.weighted_implicit_no_access_flag,FALSE) THEN
        CASE WHEN coalesce(j.feasible_accepted_count,0)>0
             THEN 'NO_ACCESS_STRATEGY_RESTRICTION'
             ELSE 'NO_ACCESS_NO_FEASIBLE_CANDIDATE' END
      WHEN j.weighted_feasibility_class='FEASIBLE_ACCESS' THEN 'ACCESS_SELECTED'
      WHEN j.weighted_feasibility_class='FEASIBLE_CONTROLLED_REVIEW' THEN 'CONTROLLED_REVIEW'
      WHEN j.weighted_candidate_template_code IS NULL THEN 'NO_ACCESS_NO_FEASIBLE_CANDIDATE'
      ELSE 'BLOCKED_SOURCE_INTEGRITY'
    END AS derived_strategy_outcome_code
  FROM tmp_eval_app_selection_joined j
)
SELECT d.*,
  CASE d.derived_strategy_outcome_code
    WHEN 'ACCESS_SELECTED' THEN 1 WHEN 'CONTROLLED_REVIEW' THEN 2
    WHEN 'NO_ACCESS_STRATEGY_RESTRICTION' THEN 3
    WHEN 'NO_ACCESS_NO_FEASIBLE_CANDIDATE' THEN 4
    WHEN 'NO_ACCESS_INSUFFICIENT_EVIDENCE' THEN 5
    WHEN 'NO_ACCESS_POLICY_DECLINE' THEN 6
    WHEN 'BLOCKED_SOURCE_INTEGRITY' THEN 7 END::smallint AS derived_strategy_outcome_rank,
  CASE
    WHEN d.derived_strategy_outcome_code='ACCESS_SELECTED' THEN 'FEASIBLE_ACCESS'
    WHEN d.derived_strategy_outcome_code='CONTROLLED_REVIEW' THEN 'FEASIBLE_CONTROLLED_REVIEW'
    WHEN d.derived_strategy_outcome_code IN ('NO_ACCESS_STRATEGY_RESTRICTION','NO_ACCESS_NO_FEASIBLE_CANDIDATE') THEN 'FEASIBLE_NO_ACCESS'
    WHEN d.derived_strategy_outcome_code='NO_ACCESS_INSUFFICIENT_EVIDENCE' THEN 'PRESERVED_INSUFFICIENT_EVIDENCE'
    WHEN d.derived_strategy_outcome_code='NO_ACCESS_POLICY_DECLINE' THEN 'PRESERVED_POLICY_DECLINE'
    ELSE 'BLOCKED_SOURCE_INTEGRITY' END AS derived_feasibility_class,
  CASE
    WHEN d.derived_strategy_outcome_code='ACCESS_SELECTED' THEN 1
    WHEN d.derived_strategy_outcome_code='CONTROLLED_REVIEW' THEN 2
    WHEN d.derived_strategy_outcome_code IN ('NO_ACCESS_STRATEGY_RESTRICTION','NO_ACCESS_NO_FEASIBLE_CANDIDATE') THEN 3
    WHEN d.derived_strategy_outcome_code='NO_ACCESS_INSUFFICIENT_EVIDENCE' THEN 6
    WHEN d.derived_strategy_outcome_code='NO_ACCESS_POLICY_DECLINE' THEN 7
    ELSE 8 END::smallint AS derived_feasibility_rank,
  CASE
    WHEN d.derived_strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY' THEN 'BLOCKED'
    WHEN d.m1_15_contract_evidence_status='PARTIAL'
      OR d.acquisition_contract_evidence_status='PARTIAL'
      OR d.routing_evidence_status='PARTIAL'
      OR d.derived_strategy_outcome_code IN ('CONTROLLED_REVIEW','NO_ACCESS_INSUFFICIENT_EVIDENCE')
      THEN 'PARTIAL'
    ELSE 'COMPLETE' END AS derived_strategy_evidence_status
FROM d;

CREATE UNIQUE INDEX tmp_eval_app_decision_u1
ON tmp_eval_app_decision(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_app_decision;

CREATE TEMP TABLE tmp_eval_app_pre_stress ON COMMIT DROP AS
SELECT
    d.module1_run_id AS module1_run_id,
    d.scenario_id AS scenario_id,
    d.scenario_code AS scenario_code,
    d.merchant_application_id AS merchant_application_id,
    d.strategy_profile_code AS strategy_profile_code,
    d.row_hash AS application_source_snapshot_row_hash,
    d.selection_mode AS selection_mode,
    d.pricing_disposition_code AS source_pricing_disposition_code,
    d.structure_available_flag AS source_structure_available_flag,
    d.review_required_flag AS source_review_required_flag,
    d.activation_outcome_code AS source_activation_outcome_code,
    d.derived_strategy_outcome_code AS strategy_outcome_code,
    d.derived_strategy_outcome_rank AS strategy_outcome_rank,
    d.derived_feasibility_class AS feasibility_class,
    d.derived_feasibility_rank AS feasibility_rank,
    (d.derived_strategy_outcome_code='ACCESS_SELECTED') AS access_selected_flag,
    (d.derived_strategy_outcome_code='CONTROLLED_REVIEW') AS controlled_review_flag,
    (d.strategy_profile_code NOT IN ('BASELINE_REPLAY','EARLY_INTERVENTION') AND coalesce(d.weighted_implicit_no_access_flag,FALSE)) AS implicit_no_access_selected_flag,
    (d.derived_strategy_outcome_code='NO_ACCESS_POLICY_DECLINE') AS policy_decline_preserved_flag,
    (d.derived_strategy_outcome_code='NO_ACCESS_INSUFFICIENT_EVIDENCE') AS insufficient_evidence_preserved_flag,
    (d.derived_strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY') AS source_integrity_blocked_flag,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_candidate_template_code WHEN NOT coalesce(d.weighted_implicit_no_access_flag,FALSE) THEN d.weighted_candidate_template_code END AS selected_candidate_template_code,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_candidate_row_hash WHEN NOT coalesce(d.weighted_implicit_no_access_flag,FALSE) THEN d.weighted_candidate_source_row_hash END AS selected_candidate_source_row_hash,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.replay_candidate_evaluation_row_hash WHEN NOT coalesce(d.weighted_implicit_no_access_flag,FALSE) THEN d.weighted_candidate_evaluation_row_hash END AS selected_candidate_evaluation_row_hash,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN NULL::numeric(22,12) ELSE d.weighted_objective_score END AS selection_objective_score,
    CASE WHEN d.derived_strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY' THEN 1 WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN coalesce(d.replay_hard_constraint_violation_count,0) WHEN coalesce(d.weighted_implicit_no_access_flag,FALSE) THEN 0 ELSE coalesce(d.weighted_hard_constraint_violation_count,0) END AS hard_constraint_violation_count,
    CASE WHEN d.derived_strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY' THEN '["ACCEPTED_SOURCE_IDENTITY"]'::jsonb WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN coalesce(d.replay_hard_constraint_codes,'[]'::jsonb) WHEN coalesce(d.weighted_implicit_no_access_flag,FALSE) THEN '[]'::jsonb ELSE coalesce(d.weighted_hard_constraint_codes,'[]'::jsonb) END AS hard_constraint_codes,
    d.derived_strategy_evidence_status AS strategy_evidence_status,
    (d.account_source_snapshot_row_hash IS NOT NULL) AS operational_account_present_flag,
    CASE WHEN d.account_source_snapshot_row_hash IS NULL THEN 'NOT_APPLICABLE' ELSE 'APPLICABLE' END AS account_certification_constraint_applicability,
    CASE WHEN d.account_source_snapshot_row_hash IS NULL THEN 0 ELSE d.account_unresolved_exception_count END AS constraint_unresolved_exception_count,
    d.account_unresolved_exception_count AS source_unresolved_exception_count,
    d.account_certified_state_code AS source_certified_state_code,
    d.account_servicing_queue_code AS source_servicing_queue_code,
    d.account_certified_exposure_amount AS source_certified_exposure_amount,
    coalesce(d.account_certification_blocked_flag,FALSE) AS certification_blocked_flag,
    coalesce(d.account_source_lineage_intact_flag,TRUE) AS source_lineage_intact_flag,
    d.associated_account_servicing_simulation_row_hash AS associated_account_servicing_simulation_row_hash,
    d.associated_servicing_treatment_code AS associated_servicing_treatment_code,
    d.associated_servicing_burden_units AS associated_servicing_burden_units,
    d.requested_funding_amount AS requested_funding_amount,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_funding_amount ELSE d.weighted_funding_amount END ELSE 0.00::numeric(18,2) END AS selected_exposure_amount,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_remittance_rate ELSE d.weighted_remittance_rate END END AS selected_remittance_rate,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_payback_multiple ELSE d.weighted_payback_multiple END END AS selected_payback_multiple,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_collection_horizon_days ELSE d.weighted_collection_horizon_days END END AS selected_collection_horizon_days,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_total_repayment_amount ELSE d.weighted_total_repayment_amount END ELSE 0.00::numeric(18,2) END AS selected_total_repayment_amount,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_finance_charge_amount ELSE d.weighted_finance_charge_amount END ELSE 0.00::numeric(18,2) END AS selected_finance_charge_amount,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_implied_daily_collection_amount ELSE d.weighted_implied_daily_collection_amount END END AS selected_implied_daily_collection_amount,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_implied_payoff_days ELSE d.weighted_implied_payoff_days END END AS selected_implied_payoff_days,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_amount_to_request_ratio ELSE d.weighted_amount_to_request_ratio END END AS selected_amount_to_request_ratio,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.replay_acquisition_economics_amount ELSE d.weighted_acquisition_economics_amount END END AS selected_acquisition_economics_amount,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.replay_expected_loss_amount ELSE d.weighted_expected_loss_amount END ELSE 0.00::numeric(18,2) END AS selected_expected_loss_amount,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN round((CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.replay_expected_loss_amount ELSE d.weighted_expected_loss_amount END)/NULLIF((CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_funding_amount ELSE d.weighted_funding_amount END),0),10)::numeric(28,10) ELSE NULL::numeric(28,10) END AS selected_expected_loss_density,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.replay_contribution_amount ELSE d.weighted_contribution_amount END ELSE 0.00::numeric(18,2) END AS selected_risk_adjusted_contribution,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.replay_annualized_return_rate ELSE d.weighted_annualized_return_rate END ELSE 0.00000000::numeric(12,8) END AS selected_annualized_risk_adjusted_return,
    CASE WHEN d.derived_strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') THEN CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_remittance_rate ELSE d.weighted_remittance_rate END ELSE 0.000000::numeric(9,6) END AS selected_payment_burden_rate,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.pricing_disposition_code END AS replay_pricing_disposition_code,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.structure_available_flag END AS replay_structure_available_flag,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.review_required_flag END AS replay_review_required_flag,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_candidate_template_code END AS replay_selected_candidate_template_code,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_candidate_row_hash END AS replay_selected_candidate_row_hash,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.requested_funding_amount END AS replay_requested_funding_amount,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_funding_amount END AS replay_selected_funding_amount,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_remittance_rate END AS replay_selected_remittance_rate,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_payback_multiple END AS replay_selected_payback_multiple,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_collection_horizon_days END AS replay_selected_collection_horizon_days,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_total_repayment_amount END AS replay_selected_total_repayment_amount,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_finance_charge_amount END AS replay_selected_finance_charge_amount,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_implied_daily_collection_amount END AS replay_selected_implied_daily_collection_amount,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_implied_payoff_days END AS replay_selected_implied_payoff_days,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.selected_amount_to_request_ratio END AS replay_selected_amount_to_request_ratio,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.candidate_count END AS replay_candidate_count,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.counteroffer_foundation_flag END AS replay_counteroffer_foundation_flag,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.stress_nonimprovement_applied_flag END AS replay_stress_nonimprovement_applied_flag,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.routing_evidence_status END AS replay_routing_evidence_status,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.source_final_decision_outcome_code END AS replay_source_final_decision_outcome_code,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.activation_outcome_code END AS replay_activation_outcome_code,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.activation_outcome_rank END AS replay_activation_outcome_rank,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.booking_eligible_flag END AS replay_booking_eligible_flag,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.booking_authorized_flag END AS replay_booking_authorized_flag,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.funding_authorized_flag END AS replay_funding_authorized_flag,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.funding_completed_flag END AS replay_funding_completed_flag,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.portfolio_activated_flag END AS replay_portfolio_activated_flag,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.operational_review_required_flag END AS replay_operational_review_required_flag,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.synthetic_offer_acceptance_assumed_flag END AS replay_synthetic_offer_acceptance_assumed_flag,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.synthetic_account_id END AS replay_synthetic_account_id,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.synthetic_advance_id END AS replay_synthetic_advance_id,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.booked_amount END AS replay_booked_amount,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.funded_amount END AS replay_funded_amount,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.activation_remittance_rate END AS replay_activation_remittance_rate,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.activation_payback_multiple END AS replay_activation_payback_multiple,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.activation_collection_horizon_days END AS replay_activation_collection_horizon_days,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.activation_total_repayment_amount END AS replay_activation_total_repayment_amount,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.activation_finance_charge_amount END AS replay_activation_finance_charge_amount,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.activation_implied_daily_collection_amount END AS replay_activation_implied_daily_collection_amount,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.activation_implied_payoff_days END AS replay_activation_implied_payoff_days,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.activation_evidence_status END AS replay_activation_evidence_status,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN 'SOURCE_REPLAY' ELSE 'NOT_APPLICABLE' END AS replay_applicability_code,
    CASE WHEN d.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN d.derived_strategy_outcome_code<>'BLOCKED_SOURCE_INTEGRITY' ELSE NULL END AS baseline_replay_match_flag
FROM tmp_eval_app_decision d
ORDER BY d.module1_run_id,d.scenario_id,d.merchant_application_id,d.strategy_profile_code;

CREATE UNIQUE INDEX tmp_eval_app_pre_stress_u1 ON tmp_eval_app_pre_stress(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_app_pre_stress;

/* ============================================================================
Section 9 — Matched stress non-improvement flags
============================================================================ */
CREATE TEMP TABLE tmp_eval_app_stress_flags ON COMMIT DROP AS
SELECT
    b.module1_run_id,b.merchant_application_id,b.strategy_profile_code,
    (
      (s_src.integrated_risk_score IS NOT NULL AND b_src.integrated_risk_score IS NOT NULL AND s_src.integrated_risk_score < b_src.integrated_risk_score-0.00000001)
      OR (s_src.synthetic_merchant_risk_proxy IS NOT NULL AND b_src.synthetic_merchant_risk_proxy IS NOT NULL AND s_src.synthetic_merchant_risk_proxy < b_src.synthetic_merchant_risk_proxy-0.00000001)
      OR (
        s_src.schedule_adjusted_comparative_expected_loss_amount IS NOT NULL AND s_src.path_weighted_ead_amount>0
        AND b_src.schedule_adjusted_comparative_expected_loss_amount IS NOT NULL AND b_src.path_weighted_ead_amount>0
        AND (s_src.schedule_adjusted_comparative_expected_loss_amount/s_src.path_weighted_ead_amount)
            < (b_src.schedule_adjusted_comparative_expected_loss_amount/b_src.path_weighted_ead_amount)-0.00000001
      )
    ) AS source_risk_improvement_violation_flag,
    (s_src.annualized_risk_adjusted_return_rate IS NOT NULL AND b_src.annualized_risk_adjusted_return_rate IS NOT NULL
      AND s_src.annualized_risk_adjusted_return_rate>b_src.annualized_risk_adjusted_return_rate+0.00000001) AS source_return_improvement_violation_flag,
    (s.strategy_outcome_rank<b.strategy_outcome_rank) AS strategy_access_improvement_violation_flag,
    (s.feasibility_rank<b.feasibility_rank) AS strategy_feasibility_improvement_violation_flag,
    (
      s.strategy_outcome_code=b.strategy_outcome_code
      AND s.selected_candidate_template_code IS NOT DISTINCT FROM b.selected_candidate_template_code
      AND abs(s.selected_exposure_amount-b.selected_exposure_amount)<=0.01
      AND s.associated_servicing_treatment_code IS NOT DISTINCT FROM b.associated_servicing_treatment_code
      AND s.selected_payment_burden_rate IS NOT NULL AND b.selected_payment_burden_rate IS NOT NULL
      AND s.selected_payment_burden_rate<b.selected_payment_burden_rate-0.00000001
    ) AS comparable_payment_burden_improvement_violation_flag,
    (
      s.strategy_outcome_code=b.strategy_outcome_code
      AND s.selected_candidate_template_code IS NOT DISTINCT FROM b.selected_candidate_template_code
      AND abs(s.selected_exposure_amount-b.selected_exposure_amount)<=0.01
      AND s.associated_servicing_treatment_code IS NOT DISTINCT FROM b.associated_servicing_treatment_code
      AND s.associated_servicing_burden_units IS NOT NULL AND b.associated_servicing_burden_units IS NOT NULL
      AND s.associated_servicing_burden_units<b.associated_servicing_burden_units-0.000001
    ) AS comparable_servicing_burden_improvement_violation_flag,
    (
      s.strategy_outcome_rank>b.strategy_outcome_rank
      OR s.feasibility_rank>b.feasibility_rank
      OR s.selected_exposure_amount<b.selected_exposure_amount-0.01
      OR (b.strategy_outcome_code IN ('ACCESS_SELECTED','CONTROLLED_REVIEW') AND s.strategy_outcome_code NOT IN ('ACCESS_SELECTED','CONTROLLED_REVIEW'))
    ) AS strategy_restriction_flag,
    (coalesce(s.associated_servicing_burden_units,0.000000::numeric)
      < coalesce(b.associated_servicing_burden_units,0.000000::numeric)-0.000001) AS absolute_workload_reduction_flag
FROM tmp_eval_app_pre_stress b
JOIN tmp_eval_app_pre_stress s
  ON s.module1_run_id=b.module1_run_id
 AND s.merchant_application_id=b.merchant_application_id
 AND s.strategy_profile_code=b.strategy_profile_code
 AND s.scenario_code='RECESSION_ENERGY'
JOIN tmp_src_m2_11_application_snapshot b_src
  ON b_src.module1_run_id=b.module1_run_id AND b_src.scenario_id=b.scenario_id
 AND b_src.merchant_application_id=b.merchant_application_id
JOIN tmp_src_m2_11_application_snapshot s_src
  ON s_src.module1_run_id=s.module1_run_id AND s_src.scenario_id=s.scenario_id
 AND s_src.merchant_application_id=s.merchant_application_id
WHERE b.scenario_code='BASELINE';

CREATE UNIQUE INDEX tmp_eval_app_stress_flags_u1
ON tmp_eval_app_stress_flags(module1_run_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_app_stress_flags;

CREATE TEMP TABLE tmp_eval_app_with_stress ON COMMIT DROP AS
SELECT p.*,
  CASE WHEN p.scenario_code='RECESSION_ENERGY' THEN f.source_risk_improvement_violation_flag ELSE FALSE END AS source_risk_improvement_violation_flag,
  CASE WHEN p.scenario_code='RECESSION_ENERGY' THEN f.source_return_improvement_violation_flag ELSE FALSE END AS source_return_improvement_violation_flag,
  CASE WHEN p.scenario_code='RECESSION_ENERGY' THEN f.strategy_access_improvement_violation_flag ELSE FALSE END AS strategy_access_improvement_violation_flag,
  CASE WHEN p.scenario_code='RECESSION_ENERGY' THEN f.strategy_feasibility_improvement_violation_flag ELSE FALSE END AS strategy_feasibility_improvement_violation_flag,
  CASE WHEN p.scenario_code='RECESSION_ENERGY' THEN f.comparable_payment_burden_improvement_violation_flag ELSE FALSE END AS comparable_payment_burden_improvement_violation_flag,
  CASE WHEN p.scenario_code='RECESSION_ENERGY' THEN f.comparable_servicing_burden_improvement_violation_flag ELSE FALSE END AS comparable_servicing_burden_improvement_violation_flag,
  CASE WHEN p.scenario_code='RECESSION_ENERGY' THEN f.strategy_restriction_flag ELSE FALSE END AS strategy_restriction_flag,
  CASE WHEN p.scenario_code='RECESSION_ENERGY' THEN f.absolute_workload_reduction_flag ELSE FALSE END AS absolute_workload_reduction_flag,
  CASE WHEN p.scenario_code='RECESSION_ENERGY' THEN NOT(
    f.source_risk_improvement_violation_flag OR f.source_return_improvement_violation_flag
    OR f.strategy_access_improvement_violation_flag OR f.strategy_feasibility_improvement_violation_flag
    OR f.comparable_payment_burden_improvement_violation_flag OR f.comparable_servicing_burden_improvement_violation_flag
  ) ELSE TRUE END AS stress_nonimprovement_pass_flag
FROM tmp_eval_app_pre_stress p
JOIN tmp_eval_app_stress_flags f
  ON f.module1_run_id=p.module1_run_id
 AND f.merchant_application_id=p.merchant_application_id
 AND f.strategy_profile_code=p.strategy_profile_code;

CREATE TEMP TABLE tmp_eval_app_prehashed ON COMMIT DROP AS
SELECT s.*,
  msbf_ctl.m2_11_hash_jsonb(
    to_jsonb(jsonb_populate_record(NULL::msbf_m2.application_portfolio_strategy_simulation,to_jsonb(s)))
    - 'portfolio_adversity_order' - 'portfolio_adverse_selected_flag'
    - 'primary_reason_code' - 'reason_codes' - 'row_hash' - 'created_at'
  ) AS adversity_tiebreak_hash
FROM tmp_eval_app_with_stress s;

CREATE TEMP TABLE tmp_eval_app_ranked ON COMMIT DROP AS
SELECT p.*,
  row_number() OVER
  (
    PARTITION BY module1_run_id,merchant_application_id,strategy_profile_code
    ORDER BY hard_constraint_violation_count DESC,strategy_outcome_rank DESC,
      CASE strategy_evidence_status WHEN 'BLOCKED' THEN 3 WHEN 'PARTIAL' THEN 2 ELSE 1 END DESC,
      (selected_expected_loss_density IS NULL) DESC,selected_expected_loss_density DESC,
      (selected_risk_adjusted_contribution IS NULL) DESC,selected_risk_adjusted_contribution ASC,
      (selected_annualized_risk_adjusted_return IS NULL) DESC,selected_annualized_risk_adjusted_return ASC,
      (selected_payment_burden_rate IS NULL) DESC,selected_payment_burden_rate DESC,
      (associated_servicing_burden_units IS NULL) DESC,associated_servicing_burden_units DESC,
      CASE scenario_code WHEN 'RECESSION_ENERGY' THEN 1 ELSE 2 END,
      adversity_tiebreak_hash
  )::smallint AS derived_portfolio_adversity_order
FROM tmp_eval_app_prehashed p;

CREATE UNIQUE INDEX tmp_eval_app_ranked_u1
ON tmp_eval_app_ranked(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
CREATE INDEX tmp_eval_app_ranked_i1
ON tmp_eval_app_ranked(module1_run_id,merchant_application_id,strategy_profile_code,derived_portfolio_adversity_order);
ANALYZE tmp_eval_app_ranked;

CREATE TEMP TABLE tmp_eval_app_final_projection ON COMMIT DROP AS
SELECT
    r.module1_run_id AS module1_run_id,
    r.scenario_id AS scenario_id,
    r.scenario_code AS scenario_code,
    r.merchant_application_id AS merchant_application_id,
    r.strategy_profile_code AS strategy_profile_code,
    r.application_source_snapshot_row_hash AS application_source_snapshot_row_hash,
    r.selection_mode AS selection_mode,
    r.source_pricing_disposition_code AS source_pricing_disposition_code,
    r.source_structure_available_flag AS source_structure_available_flag,
    r.source_review_required_flag AS source_review_required_flag,
    r.source_activation_outcome_code AS source_activation_outcome_code,
    r.strategy_outcome_code AS strategy_outcome_code,
    r.strategy_outcome_rank AS strategy_outcome_rank,
    r.feasibility_class AS feasibility_class,
    r.feasibility_rank AS feasibility_rank,
    r.access_selected_flag AS access_selected_flag,
    r.controlled_review_flag AS controlled_review_flag,
    r.implicit_no_access_selected_flag AS implicit_no_access_selected_flag,
    r.policy_decline_preserved_flag AS policy_decline_preserved_flag,
    r.insufficient_evidence_preserved_flag AS insufficient_evidence_preserved_flag,
    r.source_integrity_blocked_flag AS source_integrity_blocked_flag,
    r.selected_candidate_template_code AS selected_candidate_template_code,
    r.selected_candidate_source_row_hash AS selected_candidate_source_row_hash,
    r.selected_candidate_evaluation_row_hash AS selected_candidate_evaluation_row_hash,
    r.selection_objective_score AS selection_objective_score,
    r.hard_constraint_violation_count AS hard_constraint_violation_count,
    r.hard_constraint_codes AS hard_constraint_codes,
    r.strategy_evidence_status AS strategy_evidence_status,
    r.operational_account_present_flag AS operational_account_present_flag,
    r.account_certification_constraint_applicability AS account_certification_constraint_applicability,
    r.constraint_unresolved_exception_count AS constraint_unresolved_exception_count,
    r.source_unresolved_exception_count AS source_unresolved_exception_count,
    r.source_certified_state_code AS source_certified_state_code,
    r.source_servicing_queue_code AS source_servicing_queue_code,
    r.source_certified_exposure_amount AS source_certified_exposure_amount,
    r.certification_blocked_flag AS certification_blocked_flag,
    r.source_lineage_intact_flag AS source_lineage_intact_flag,
    r.associated_account_servicing_simulation_row_hash AS associated_account_servicing_simulation_row_hash,
    r.associated_servicing_treatment_code AS associated_servicing_treatment_code,
    r.associated_servicing_burden_units AS associated_servicing_burden_units,
    r.requested_funding_amount AS requested_funding_amount,
    r.selected_exposure_amount AS selected_exposure_amount,
    r.selected_remittance_rate AS selected_remittance_rate,
    r.selected_payback_multiple AS selected_payback_multiple,
    r.selected_collection_horizon_days AS selected_collection_horizon_days,
    r.selected_total_repayment_amount AS selected_total_repayment_amount,
    r.selected_finance_charge_amount AS selected_finance_charge_amount,
    r.selected_implied_daily_collection_amount AS selected_implied_daily_collection_amount,
    r.selected_implied_payoff_days AS selected_implied_payoff_days,
    r.selected_amount_to_request_ratio AS selected_amount_to_request_ratio,
    r.selected_acquisition_economics_amount AS selected_acquisition_economics_amount,
    r.selected_expected_loss_amount AS selected_expected_loss_amount,
    r.selected_expected_loss_density AS selected_expected_loss_density,
    r.selected_risk_adjusted_contribution AS selected_risk_adjusted_contribution,
    r.selected_annualized_risk_adjusted_return AS selected_annualized_risk_adjusted_return,
    r.selected_payment_burden_rate AS selected_payment_burden_rate,
    r.replay_pricing_disposition_code AS replay_pricing_disposition_code,
    r.replay_structure_available_flag AS replay_structure_available_flag,
    r.replay_review_required_flag AS replay_review_required_flag,
    r.replay_selected_candidate_template_code AS replay_selected_candidate_template_code,
    r.replay_selected_candidate_row_hash AS replay_selected_candidate_row_hash,
    r.replay_requested_funding_amount AS replay_requested_funding_amount,
    r.replay_selected_funding_amount AS replay_selected_funding_amount,
    r.replay_selected_remittance_rate AS replay_selected_remittance_rate,
    r.replay_selected_payback_multiple AS replay_selected_payback_multiple,
    r.replay_selected_collection_horizon_days AS replay_selected_collection_horizon_days,
    r.replay_selected_total_repayment_amount AS replay_selected_total_repayment_amount,
    r.replay_selected_finance_charge_amount AS replay_selected_finance_charge_amount,
    r.replay_selected_implied_daily_collection_amount AS replay_selected_implied_daily_collection_amount,
    r.replay_selected_implied_payoff_days AS replay_selected_implied_payoff_days,
    r.replay_selected_amount_to_request_ratio AS replay_selected_amount_to_request_ratio,
    r.replay_candidate_count AS replay_candidate_count,
    r.replay_counteroffer_foundation_flag AS replay_counteroffer_foundation_flag,
    r.replay_stress_nonimprovement_applied_flag AS replay_stress_nonimprovement_applied_flag,
    r.replay_routing_evidence_status AS replay_routing_evidence_status,
    r.replay_source_final_decision_outcome_code AS replay_source_final_decision_outcome_code,
    r.replay_activation_outcome_code AS replay_activation_outcome_code,
    r.replay_activation_outcome_rank AS replay_activation_outcome_rank,
    r.replay_booking_eligible_flag AS replay_booking_eligible_flag,
    r.replay_booking_authorized_flag AS replay_booking_authorized_flag,
    r.replay_funding_authorized_flag AS replay_funding_authorized_flag,
    r.replay_funding_completed_flag AS replay_funding_completed_flag,
    r.replay_portfolio_activated_flag AS replay_portfolio_activated_flag,
    r.replay_operational_review_required_flag AS replay_operational_review_required_flag,
    r.replay_synthetic_offer_acceptance_assumed_flag AS replay_synthetic_offer_acceptance_assumed_flag,
    r.replay_synthetic_account_id AS replay_synthetic_account_id,
    r.replay_synthetic_advance_id AS replay_synthetic_advance_id,
    r.replay_booked_amount AS replay_booked_amount,
    r.replay_funded_amount AS replay_funded_amount,
    r.replay_activation_remittance_rate AS replay_activation_remittance_rate,
    r.replay_activation_payback_multiple AS replay_activation_payback_multiple,
    r.replay_activation_collection_horizon_days AS replay_activation_collection_horizon_days,
    r.replay_activation_total_repayment_amount AS replay_activation_total_repayment_amount,
    r.replay_activation_finance_charge_amount AS replay_activation_finance_charge_amount,
    r.replay_activation_implied_daily_collection_amount AS replay_activation_implied_daily_collection_amount,
    r.replay_activation_implied_payoff_days AS replay_activation_implied_payoff_days,
    r.replay_activation_evidence_status AS replay_activation_evidence_status,
    r.replay_applicability_code AS replay_applicability_code,
    r.baseline_replay_match_flag AS baseline_replay_match_flag,
    r.source_risk_improvement_violation_flag AS source_risk_improvement_violation_flag,
    r.source_return_improvement_violation_flag AS source_return_improvement_violation_flag,
    r.strategy_access_improvement_violation_flag AS strategy_access_improvement_violation_flag,
    r.strategy_feasibility_improvement_violation_flag AS strategy_feasibility_improvement_violation_flag,
    r.comparable_payment_burden_improvement_violation_flag AS comparable_payment_burden_improvement_violation_flag,
    r.comparable_servicing_burden_improvement_violation_flag AS comparable_servicing_burden_improvement_violation_flag,
    r.strategy_restriction_flag AS strategy_restriction_flag,
    r.absolute_workload_reduction_flag AS absolute_workload_reduction_flag,
    r.stress_nonimprovement_pass_flag AS stress_nonimprovement_pass_flag,
    (r.derived_portfolio_adversity_order=1) AS portfolio_adverse_selected_flag,
    r.derived_portfolio_adversity_order AS portfolio_adversity_order,
    CASE WHEN r.strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY' THEN 'M2_11_REASON_SOURCE_GRAIN_OR_LINEAGE_ERROR' WHEN r.strategy_outcome_code='NO_ACCESS_POLICY_DECLINE' THEN 'M2_11_REASON_POLICY_DECLINE_PRESERVED' WHEN r.strategy_outcome_code='NO_ACCESS_INSUFFICIENT_EVIDENCE' THEN 'M2_11_REASON_INSUFFICIENT_EVIDENCE_PRESERVED' WHEN r.strategy_outcome_code='NO_ACCESS_NO_FEASIBLE_CANDIDATE' THEN 'M2_11_REASON_NO_FEASIBLE_CANDIDATE' WHEN r.strategy_outcome_code='NO_ACCESS_STRATEGY_RESTRICTION' THEN 'M2_11_REASON_NO_ACCESS_STRATEGY_RESTRICTION' WHEN r.strategy_outcome_code='CONTROLLED_REVIEW' THEN 'M2_11_REASON_CONTROLLED_REVIEW_REQUIRED' ELSE CASE r.strategy_profile_code WHEN 'ACCESS_EXPANSION' THEN 'M2_11_REASON_ACCESS_EXPANSION_SELECTED' WHEN 'PRICE_FOR_RISK' THEN 'M2_11_REASON_PRICE_FOR_RISK_SELECTED' WHEN 'PAYMENT_BURDEN_RELIEF' THEN 'M2_11_REASON_PAYMENT_BURDEN_RELIEF_SELECTED' WHEN 'LOSS_CONTAINMENT' THEN 'M2_11_REASON_LOSS_CONTAINMENT_SELECTED' WHEN 'PROFITABILITY_DISCIPLINE' THEN 'M2_11_REASON_PROFITABILITY_DISCIPLINE_SELECTED' WHEN 'BALANCED_FRONTIER' THEN 'M2_11_REASON_BALANCED_FRONTIER_SELECTED' ELSE 'M2_11_REASON_BASELINE_REPLAY_MATCH' END END AS primary_reason_code,
    to_jsonb(array_remove(ARRAY[CASE WHEN r.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') THEN 'M2_11_REASON_BASELINE_REPLAY_MATCH' END,CASE WHEN r.strategy_evidence_status='PARTIAL' THEN 'M2_11_REASON_SOURCE_EVIDENCE_PARTIAL' END,CASE WHEN r.strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY' THEN 'M2_11_REASON_SOURCE_GRAIN_OR_LINEAGE_ERROR' END,CASE WHEN r.strategy_outcome_code='NO_ACCESS_POLICY_DECLINE' THEN 'M2_11_REASON_POLICY_DECLINE_PRESERVED' END,CASE WHEN r.strategy_outcome_code='NO_ACCESS_INSUFFICIENT_EVIDENCE' THEN 'M2_11_REASON_INSUFFICIENT_EVIDENCE_PRESERVED' END,CASE WHEN r.strategy_outcome_code='NO_ACCESS_NO_FEASIBLE_CANDIDATE' THEN 'M2_11_REASON_NO_FEASIBLE_CANDIDATE' END,CASE WHEN r.strategy_outcome_code='NO_ACCESS_STRATEGY_RESTRICTION' THEN 'M2_11_REASON_NO_ACCESS_STRATEGY_RESTRICTION' END,CASE WHEN r.strategy_outcome_code='CONTROLLED_REVIEW' THEN 'M2_11_REASON_CONTROLLED_REVIEW_REQUIRED' END,CASE WHEN r.strategy_outcome_code='ACCESS_SELECTED' THEN CASE r.strategy_profile_code WHEN 'ACCESS_EXPANSION' THEN 'M2_11_REASON_ACCESS_EXPANSION_SELECTED' WHEN 'PRICE_FOR_RISK' THEN 'M2_11_REASON_PRICE_FOR_RISK_SELECTED' WHEN 'PAYMENT_BURDEN_RELIEF' THEN 'M2_11_REASON_PAYMENT_BURDEN_RELIEF_SELECTED' WHEN 'LOSS_CONTAINMENT' THEN 'M2_11_REASON_LOSS_CONTAINMENT_SELECTED' WHEN 'PROFITABILITY_DISCIPLINE' THEN 'M2_11_REASON_PROFITABILITY_DISCIPLINE_SELECTED' WHEN 'BALANCED_FRONTIER' THEN 'M2_11_REASON_BALANCED_FRONTIER_SELECTED' ELSE 'M2_11_REASON_BASELINE_REPLAY_MATCH' END END,CASE WHEN r.strategy_restriction_flag THEN 'M2_11_REASON_STRESS_STRATEGY_RESTRICTION' END,CASE WHEN NOT r.stress_nonimprovement_pass_flag THEN 'M2_11_REASON_STRESS_IMPROVEMENT_VIOLATION' END,CASE WHEN r.stress_nonimprovement_pass_flag AND r.scenario_code='RECESSION_ENERGY' THEN 'M2_11_REASON_STRESS_SOURCE_NONIMPROVEMENT_PASS' END]::text[],NULL)) AS reason_codes
FROM tmp_eval_app_ranked r
ORDER BY r.module1_run_id,r.scenario_id,r.merchant_application_id,r.strategy_profile_code;

CREATE UNIQUE INDEX tmp_eval_app_final_u1 ON tmp_eval_app_final_projection(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
ANALYZE tmp_eval_app_final_projection;

/* Target-type-before-hash projection for msbf_m2.application_portfolio_strategy_simulation. */
CREATE TEMP TABLE tmp_eval_m2_11_application_simulation ON COMMIT DROP AS
SELECT * FROM msbf_m2.application_portfolio_strategy_simulation WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_eval_m2_11_application_simulation') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.application_portfolio_strategy_simulation'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_eval_m2_11_application_simulation versus msbf_m2.application_portfolio_strategy_simulation: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_eval_m2_11_application_simulation
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    strategy_profile_code, application_source_snapshot_row_hash, selection_mode, source_pricing_disposition_code,
    source_structure_available_flag, source_review_required_flag, source_activation_outcome_code, strategy_outcome_code,
    strategy_outcome_rank, feasibility_class, feasibility_rank, access_selected_flag,
    controlled_review_flag, implicit_no_access_selected_flag, policy_decline_preserved_flag, insufficient_evidence_preserved_flag,
    source_integrity_blocked_flag, selected_candidate_template_code, selected_candidate_source_row_hash, selected_candidate_evaluation_row_hash,
    selection_objective_score, hard_constraint_violation_count, hard_constraint_codes, strategy_evidence_status,
    operational_account_present_flag, account_certification_constraint_applicability, constraint_unresolved_exception_count, source_unresolved_exception_count,
    source_certified_state_code, source_servicing_queue_code, source_certified_exposure_amount, certification_blocked_flag,
    source_lineage_intact_flag, associated_account_servicing_simulation_row_hash, associated_servicing_treatment_code, associated_servicing_burden_units,
    requested_funding_amount, selected_exposure_amount, selected_remittance_rate, selected_payback_multiple,
    selected_collection_horizon_days, selected_total_repayment_amount, selected_finance_charge_amount, selected_implied_daily_collection_amount,
    selected_implied_payoff_days, selected_amount_to_request_ratio, selected_acquisition_economics_amount, selected_expected_loss_amount,
    selected_expected_loss_density, selected_risk_adjusted_contribution, selected_annualized_risk_adjusted_return, selected_payment_burden_rate,
    replay_pricing_disposition_code, replay_structure_available_flag, replay_review_required_flag, replay_selected_candidate_template_code,
    replay_selected_candidate_row_hash, replay_requested_funding_amount, replay_selected_funding_amount, replay_selected_remittance_rate,
    replay_selected_payback_multiple, replay_selected_collection_horizon_days, replay_selected_total_repayment_amount, replay_selected_finance_charge_amount,
    replay_selected_implied_daily_collection_amount, replay_selected_implied_payoff_days, replay_selected_amount_to_request_ratio, replay_candidate_count,
    replay_counteroffer_foundation_flag, replay_stress_nonimprovement_applied_flag, replay_routing_evidence_status, replay_source_final_decision_outcome_code,
    replay_activation_outcome_code, replay_activation_outcome_rank, replay_booking_eligible_flag, replay_booking_authorized_flag,
    replay_funding_authorized_flag, replay_funding_completed_flag, replay_portfolio_activated_flag, replay_operational_review_required_flag,
    replay_synthetic_offer_acceptance_assumed_flag, replay_synthetic_account_id, replay_synthetic_advance_id, replay_booked_amount,
    replay_funded_amount, replay_activation_remittance_rate, replay_activation_payback_multiple, replay_activation_collection_horizon_days,
    replay_activation_total_repayment_amount, replay_activation_finance_charge_amount, replay_activation_implied_daily_collection_amount, replay_activation_implied_payoff_days,
    replay_activation_evidence_status, replay_applicability_code, baseline_replay_match_flag, source_risk_improvement_violation_flag,
    source_return_improvement_violation_flag, strategy_access_improvement_violation_flag, strategy_feasibility_improvement_violation_flag, comparable_payment_burden_improvement_violation_flag,
    comparable_servicing_burden_improvement_violation_flag, strategy_restriction_flag, absolute_workload_reduction_flag, stress_nonimprovement_pass_flag,
    portfolio_adverse_selected_flag, portfolio_adversity_order, primary_reason_code, reason_codes,
    row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.scenario_id,
    p.scenario_code,
    p.merchant_application_id,
    p.strategy_profile_code,
    p.application_source_snapshot_row_hash,
    p.selection_mode,
    p.source_pricing_disposition_code,
    p.source_structure_available_flag,
    p.source_review_required_flag,
    p.source_activation_outcome_code,
    p.strategy_outcome_code,
    p.strategy_outcome_rank,
    p.feasibility_class,
    p.feasibility_rank,
    p.access_selected_flag,
    p.controlled_review_flag,
    p.implicit_no_access_selected_flag,
    p.policy_decline_preserved_flag,
    p.insufficient_evidence_preserved_flag,
    p.source_integrity_blocked_flag,
    p.selected_candidate_template_code,
    p.selected_candidate_source_row_hash,
    p.selected_candidate_evaluation_row_hash,
    p.selection_objective_score,
    p.hard_constraint_violation_count,
    p.hard_constraint_codes,
    p.strategy_evidence_status,
    p.operational_account_present_flag,
    p.account_certification_constraint_applicability,
    p.constraint_unresolved_exception_count,
    p.source_unresolved_exception_count,
    p.source_certified_state_code,
    p.source_servicing_queue_code,
    p.source_certified_exposure_amount,
    p.certification_blocked_flag,
    p.source_lineage_intact_flag,
    p.associated_account_servicing_simulation_row_hash,
    p.associated_servicing_treatment_code,
    p.associated_servicing_burden_units,
    p.requested_funding_amount,
    p.selected_exposure_amount,
    p.selected_remittance_rate,
    p.selected_payback_multiple,
    p.selected_collection_horizon_days,
    p.selected_total_repayment_amount,
    p.selected_finance_charge_amount,
    p.selected_implied_daily_collection_amount,
    p.selected_implied_payoff_days,
    p.selected_amount_to_request_ratio,
    p.selected_acquisition_economics_amount,
    p.selected_expected_loss_amount,
    p.selected_expected_loss_density,
    p.selected_risk_adjusted_contribution,
    p.selected_annualized_risk_adjusted_return,
    p.selected_payment_burden_rate,
    p.replay_pricing_disposition_code,
    p.replay_structure_available_flag,
    p.replay_review_required_flag,
    p.replay_selected_candidate_template_code,
    p.replay_selected_candidate_row_hash,
    p.replay_requested_funding_amount,
    p.replay_selected_funding_amount,
    p.replay_selected_remittance_rate,
    p.replay_selected_payback_multiple,
    p.replay_selected_collection_horizon_days,
    p.replay_selected_total_repayment_amount,
    p.replay_selected_finance_charge_amount,
    p.replay_selected_implied_daily_collection_amount,
    p.replay_selected_implied_payoff_days,
    p.replay_selected_amount_to_request_ratio,
    p.replay_candidate_count,
    p.replay_counteroffer_foundation_flag,
    p.replay_stress_nonimprovement_applied_flag,
    p.replay_routing_evidence_status,
    p.replay_source_final_decision_outcome_code,
    p.replay_activation_outcome_code,
    p.replay_activation_outcome_rank,
    p.replay_booking_eligible_flag,
    p.replay_booking_authorized_flag,
    p.replay_funding_authorized_flag,
    p.replay_funding_completed_flag,
    p.replay_portfolio_activated_flag,
    p.replay_operational_review_required_flag,
    p.replay_synthetic_offer_acceptance_assumed_flag,
    p.replay_synthetic_account_id,
    p.replay_synthetic_advance_id,
    p.replay_booked_amount,
    p.replay_funded_amount,
    p.replay_activation_remittance_rate,
    p.replay_activation_payback_multiple,
    p.replay_activation_collection_horizon_days,
    p.replay_activation_total_repayment_amount,
    p.replay_activation_finance_charge_amount,
    p.replay_activation_implied_daily_collection_amount,
    p.replay_activation_implied_payoff_days,
    p.replay_activation_evidence_status,
    p.replay_applicability_code,
    p.baseline_replay_match_flag,
    p.source_risk_improvement_violation_flag,
    p.source_return_improvement_violation_flag,
    p.strategy_access_improvement_violation_flag,
    p.strategy_feasibility_improvement_violation_flag,
    p.comparable_payment_burden_improvement_violation_flag,
    p.comparable_servicing_burden_improvement_violation_flag,
    p.strategy_restriction_flag,
    p.absolute_workload_reduction_flag,
    p.stress_nonimprovement_pass_flag,
    p.portfolio_adverse_selected_flag,
    p.portfolio_adversity_order,
    p.primary_reason_code,
    p.reason_codes,
    NULL::text,
    NULL::timestamptz
FROM tmp_eval_app_final_projection p
ORDER BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code;

UPDATE tmp_eval_m2_11_application_simulation AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

-- Enforce the frozen application-simulation grain and support both scenario
-- panels and the one-row-per-application PORTFOLIO adversity rollup.
CREATE UNIQUE INDEX tmp_eval_m2_11_application_simulation_u1
ON tmp_eval_m2_11_application_simulation
(module1_run_id,scenario_id,merchant_application_id,strategy_profile_code);
CREATE INDEX tmp_eval_m2_11_application_simulation_i1
ON tmp_eval_m2_11_application_simulation
(module1_run_id,scenario_code,strategy_profile_code,merchant_application_id);
CREATE INDEX tmp_eval_m2_11_application_simulation_i2
ON tmp_eval_m2_11_application_simulation
(module1_run_id,portfolio_adverse_selected_flag,strategy_profile_code,merchant_application_id);
ANALYZE tmp_eval_m2_11_application_simulation;

INSERT INTO msbf_m2.application_portfolio_strategy_simulation
(
    module1_run_id, scenario_id, scenario_code, merchant_application_id,
    strategy_profile_code, application_source_snapshot_row_hash, selection_mode, source_pricing_disposition_code,
    source_structure_available_flag, source_review_required_flag, source_activation_outcome_code, strategy_outcome_code,
    strategy_outcome_rank, feasibility_class, feasibility_rank, access_selected_flag,
    controlled_review_flag, implicit_no_access_selected_flag, policy_decline_preserved_flag, insufficient_evidence_preserved_flag,
    source_integrity_blocked_flag, selected_candidate_template_code, selected_candidate_source_row_hash, selected_candidate_evaluation_row_hash,
    selection_objective_score, hard_constraint_violation_count, hard_constraint_codes, strategy_evidence_status,
    operational_account_present_flag, account_certification_constraint_applicability, constraint_unresolved_exception_count, source_unresolved_exception_count,
    source_certified_state_code, source_servicing_queue_code, source_certified_exposure_amount, certification_blocked_flag,
    source_lineage_intact_flag, associated_account_servicing_simulation_row_hash, associated_servicing_treatment_code, associated_servicing_burden_units,
    requested_funding_amount, selected_exposure_amount, selected_remittance_rate, selected_payback_multiple,
    selected_collection_horizon_days, selected_total_repayment_amount, selected_finance_charge_amount, selected_implied_daily_collection_amount,
    selected_implied_payoff_days, selected_amount_to_request_ratio, selected_acquisition_economics_amount, selected_expected_loss_amount,
    selected_expected_loss_density, selected_risk_adjusted_contribution, selected_annualized_risk_adjusted_return, selected_payment_burden_rate,
    replay_pricing_disposition_code, replay_structure_available_flag, replay_review_required_flag, replay_selected_candidate_template_code,
    replay_selected_candidate_row_hash, replay_requested_funding_amount, replay_selected_funding_amount, replay_selected_remittance_rate,
    replay_selected_payback_multiple, replay_selected_collection_horizon_days, replay_selected_total_repayment_amount, replay_selected_finance_charge_amount,
    replay_selected_implied_daily_collection_amount, replay_selected_implied_payoff_days, replay_selected_amount_to_request_ratio, replay_candidate_count,
    replay_counteroffer_foundation_flag, replay_stress_nonimprovement_applied_flag, replay_routing_evidence_status, replay_source_final_decision_outcome_code,
    replay_activation_outcome_code, replay_activation_outcome_rank, replay_booking_eligible_flag, replay_booking_authorized_flag,
    replay_funding_authorized_flag, replay_funding_completed_flag, replay_portfolio_activated_flag, replay_operational_review_required_flag,
    replay_synthetic_offer_acceptance_assumed_flag, replay_synthetic_account_id, replay_synthetic_advance_id, replay_booked_amount,
    replay_funded_amount, replay_activation_remittance_rate, replay_activation_payback_multiple, replay_activation_collection_horizon_days,
    replay_activation_total_repayment_amount, replay_activation_finance_charge_amount, replay_activation_implied_daily_collection_amount, replay_activation_implied_payoff_days,
    replay_activation_evidence_status, replay_applicability_code, baseline_replay_match_flag, source_risk_improvement_violation_flag,
    source_return_improvement_violation_flag, strategy_access_improvement_violation_flag, strategy_feasibility_improvement_violation_flag, comparable_payment_burden_improvement_violation_flag,
    comparable_servicing_burden_improvement_violation_flag, strategy_restriction_flag, absolute_workload_reduction_flag, stress_nonimprovement_pass_flag,
    portfolio_adverse_selected_flag, portfolio_adversity_order, primary_reason_code, reason_codes,
    row_hash, created_at
)
SELECT
    t.module1_run_id,
    t.scenario_id,
    t.scenario_code,
    t.merchant_application_id,
    t.strategy_profile_code,
    t.application_source_snapshot_row_hash,
    t.selection_mode,
    t.source_pricing_disposition_code,
    t.source_structure_available_flag,
    t.source_review_required_flag,
    t.source_activation_outcome_code,
    t.strategy_outcome_code,
    t.strategy_outcome_rank,
    t.feasibility_class,
    t.feasibility_rank,
    t.access_selected_flag,
    t.controlled_review_flag,
    t.implicit_no_access_selected_flag,
    t.policy_decline_preserved_flag,
    t.insufficient_evidence_preserved_flag,
    t.source_integrity_blocked_flag,
    t.selected_candidate_template_code,
    t.selected_candidate_source_row_hash,
    t.selected_candidate_evaluation_row_hash,
    t.selection_objective_score,
    t.hard_constraint_violation_count,
    t.hard_constraint_codes,
    t.strategy_evidence_status,
    t.operational_account_present_flag,
    t.account_certification_constraint_applicability,
    t.constraint_unresolved_exception_count,
    t.source_unresolved_exception_count,
    t.source_certified_state_code,
    t.source_servicing_queue_code,
    t.source_certified_exposure_amount,
    t.certification_blocked_flag,
    t.source_lineage_intact_flag,
    t.associated_account_servicing_simulation_row_hash,
    t.associated_servicing_treatment_code,
    t.associated_servicing_burden_units,
    t.requested_funding_amount,
    t.selected_exposure_amount,
    t.selected_remittance_rate,
    t.selected_payback_multiple,
    t.selected_collection_horizon_days,
    t.selected_total_repayment_amount,
    t.selected_finance_charge_amount,
    t.selected_implied_daily_collection_amount,
    t.selected_implied_payoff_days,
    t.selected_amount_to_request_ratio,
    t.selected_acquisition_economics_amount,
    t.selected_expected_loss_amount,
    t.selected_expected_loss_density,
    t.selected_risk_adjusted_contribution,
    t.selected_annualized_risk_adjusted_return,
    t.selected_payment_burden_rate,
    t.replay_pricing_disposition_code,
    t.replay_structure_available_flag,
    t.replay_review_required_flag,
    t.replay_selected_candidate_template_code,
    t.replay_selected_candidate_row_hash,
    t.replay_requested_funding_amount,
    t.replay_selected_funding_amount,
    t.replay_selected_remittance_rate,
    t.replay_selected_payback_multiple,
    t.replay_selected_collection_horizon_days,
    t.replay_selected_total_repayment_amount,
    t.replay_selected_finance_charge_amount,
    t.replay_selected_implied_daily_collection_amount,
    t.replay_selected_implied_payoff_days,
    t.replay_selected_amount_to_request_ratio,
    t.replay_candidate_count,
    t.replay_counteroffer_foundation_flag,
    t.replay_stress_nonimprovement_applied_flag,
    t.replay_routing_evidence_status,
    t.replay_source_final_decision_outcome_code,
    t.replay_activation_outcome_code,
    t.replay_activation_outcome_rank,
    t.replay_booking_eligible_flag,
    t.replay_booking_authorized_flag,
    t.replay_funding_authorized_flag,
    t.replay_funding_completed_flag,
    t.replay_portfolio_activated_flag,
    t.replay_operational_review_required_flag,
    t.replay_synthetic_offer_acceptance_assumed_flag,
    t.replay_synthetic_account_id,
    t.replay_synthetic_advance_id,
    t.replay_booked_amount,
    t.replay_funded_amount,
    t.replay_activation_remittance_rate,
    t.replay_activation_payback_multiple,
    t.replay_activation_collection_horizon_days,
    t.replay_activation_total_repayment_amount,
    t.replay_activation_finance_charge_amount,
    t.replay_activation_implied_daily_collection_amount,
    t.replay_activation_implied_payoff_days,
    t.replay_activation_evidence_status,
    t.replay_applicability_code,
    t.baseline_replay_match_flag,
    t.source_risk_improvement_violation_flag,
    t.source_return_improvement_violation_flag,
    t.strategy_access_improvement_violation_flag,
    t.strategy_feasibility_improvement_violation_flag,
    t.comparable_payment_burden_improvement_violation_flag,
    t.comparable_servicing_burden_improvement_violation_flag,
    t.strategy_restriction_flag,
    t.absolute_workload_reduction_flag,
    t.stress_nonimprovement_pass_flag,
    t.portfolio_adverse_selected_flag,
    t.portfolio_adversity_order,
    t.primary_reason_code,
    t.reason_codes,
    t.row_hash,
    t.created_at
FROM tmp_eval_m2_11_application_simulation t
ORDER BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n FROM tmp_eval_m2_11_application_simulation;
  IF v_n<>12000 THEN RAISE EXCEPTION 'Application strategy simulation expected 12000; found %',v_n; END IF;
  SELECT count(*) INTO v_n FROM tmp_eval_m2_11_application_simulation WHERE portfolio_adverse_selected_flag;
  IF v_n<>6000 THEN RAISE EXCEPTION 'PORTFOLIO application selection expected 750 x 8 = 6000; found %',v_n; END IF;
  SELECT count(*) INTO v_n FROM tmp_eval_m2_11_application_simulation
  WHERE access_selected_flag<>(strategy_outcome_code='ACCESS_SELECTED');
  IF v_n<>0 THEN RAISE EXCEPTION 'Application access-indicator mismatch count %',v_n; END IF;
  SELECT count(*) INTO v_n FROM tmp_eval_m2_11_application_simulation
  WHERE strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION') AND NOT coalesce(baseline_replay_match_flag,FALSE);
  IF v_n<>0 THEN RAISE EXCEPTION 'Application baseline replay mismatch count %',v_n; END IF;
  SELECT count(*) INTO v_n FROM tmp_eval_m2_11_application_simulation s
  LEFT JOIN tmp_src_m2_11_candidate_snapshot c
    ON c.module1_run_id=s.module1_run_id AND c.scenario_id=s.scenario_id
   AND c.merchant_application_id=s.merchant_application_id
   AND c.candidate_template_code=s.selected_candidate_template_code
   AND c.source_candidate_row_hash=s.selected_candidate_source_row_hash
  WHERE s.selected_candidate_template_code IS NOT NULL AND c.candidate_template_code IS NULL;
  IF v_n<>0 THEN RAISE EXCEPTION 'Selected candidate outside accepted inventory count %',v_n; END IF;
  SELECT count(*) INTO v_n FROM tmp_eval_m2_11_application_simulation
  WHERE source_pricing_disposition_code='NO_STRUCTURE_POLICY_DECLINE' AND strategy_outcome_code<>'NO_ACCESS_POLICY_DECLINE';
  IF v_n<>0 THEN RAISE EXCEPTION 'Policy-decline preservation mismatch count %',v_n; END IF;
  SELECT count(*) INTO v_n FROM tmp_eval_m2_11_application_simulation
  WHERE source_pricing_disposition_code='NO_STRUCTURE_INSUFFICIENT_EVIDENCE' AND strategy_outcome_code<>'NO_ACCESS_INSUFFICIENT_EVIDENCE';
  IF v_n<>0 THEN RAISE EXCEPTION 'Insufficient-evidence preservation mismatch count %',v_n; END IF;
END;
$m211$;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n
  FROM tmp_eval_m2_11_application_simulation s
  JOIN tmp_src_m2_11_application_snapshot a
    USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
  WHERE s.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
    AND (
      s.replay_pricing_disposition_code IS DISTINCT FROM a.pricing_disposition_code
     OR s.replay_structure_available_flag IS DISTINCT FROM a.structure_available_flag
     OR s.replay_review_required_flag IS DISTINCT FROM a.review_required_flag
     OR s.replay_selected_candidate_template_code IS DISTINCT FROM a.selected_candidate_template_code
     OR s.replay_selected_candidate_row_hash IS DISTINCT FROM a.selected_candidate_row_hash
     OR s.replay_requested_funding_amount IS DISTINCT FROM a.requested_funding_amount
     OR s.replay_selected_funding_amount IS DISTINCT FROM a.selected_funding_amount
     OR s.replay_selected_remittance_rate IS DISTINCT FROM a.selected_remittance_rate
     OR s.replay_selected_payback_multiple IS DISTINCT FROM a.selected_payback_multiple
     OR s.replay_selected_collection_horizon_days IS DISTINCT FROM a.selected_collection_horizon_days
     OR s.replay_selected_total_repayment_amount IS DISTINCT FROM a.selected_total_repayment_amount
     OR s.replay_selected_finance_charge_amount IS DISTINCT FROM a.selected_finance_charge_amount
     OR s.replay_selected_implied_daily_collection_amount IS DISTINCT FROM a.selected_implied_daily_collection_amount
     OR s.replay_selected_implied_payoff_days IS DISTINCT FROM a.selected_implied_payoff_days
     OR s.replay_selected_amount_to_request_ratio IS DISTINCT FROM a.selected_amount_to_request_ratio
     OR s.replay_candidate_count IS DISTINCT FROM a.candidate_count
     OR s.replay_counteroffer_foundation_flag IS DISTINCT FROM a.counteroffer_foundation_flag
     OR s.replay_stress_nonimprovement_applied_flag IS DISTINCT FROM a.stress_nonimprovement_applied_flag
     OR s.replay_routing_evidence_status IS DISTINCT FROM a.routing_evidence_status
     OR s.replay_source_final_decision_outcome_code IS DISTINCT FROM a.source_final_decision_outcome_code
     OR s.replay_activation_outcome_code IS DISTINCT FROM a.activation_outcome_code
     OR s.replay_activation_outcome_rank IS DISTINCT FROM a.activation_outcome_rank
     OR s.replay_booking_eligible_flag IS DISTINCT FROM a.booking_eligible_flag
     OR s.replay_booking_authorized_flag IS DISTINCT FROM a.booking_authorized_flag
     OR s.replay_funding_authorized_flag IS DISTINCT FROM a.funding_authorized_flag
     OR s.replay_funding_completed_flag IS DISTINCT FROM a.funding_completed_flag
     OR s.replay_portfolio_activated_flag IS DISTINCT FROM a.portfolio_activated_flag
     OR s.replay_operational_review_required_flag IS DISTINCT FROM a.operational_review_required_flag
     OR s.replay_synthetic_offer_acceptance_assumed_flag IS DISTINCT FROM a.synthetic_offer_acceptance_assumed_flag
     OR s.replay_synthetic_account_id IS DISTINCT FROM a.synthetic_account_id
     OR s.replay_synthetic_advance_id IS DISTINCT FROM a.synthetic_advance_id
     OR s.replay_booked_amount IS DISTINCT FROM a.booked_amount
     OR s.replay_funded_amount IS DISTINCT FROM a.funded_amount
     OR s.replay_activation_remittance_rate IS DISTINCT FROM a.activation_remittance_rate
     OR s.replay_activation_payback_multiple IS DISTINCT FROM a.activation_payback_multiple
     OR s.replay_activation_collection_horizon_days IS DISTINCT FROM a.activation_collection_horizon_days
     OR s.replay_activation_total_repayment_amount IS DISTINCT FROM a.activation_total_repayment_amount
     OR s.replay_activation_finance_charge_amount IS DISTINCT FROM a.activation_finance_charge_amount
     OR s.replay_activation_implied_daily_collection_amount IS DISTINCT FROM a.activation_implied_daily_collection_amount
     OR s.replay_activation_implied_payoff_days IS DISTINCT FROM a.activation_implied_payoff_days
     OR s.replay_activation_evidence_status IS DISTINCT FROM a.activation_evidence_status
    );
  IF v_n<>0 THEN RAISE EXCEPTION 'Application source replay field mismatch count %',v_n; END IF;

  SELECT count(*) INTO v_n
  FROM tmp_eval_m2_11_application_simulation s
  JOIN tmp_src_m2_11_application_snapshot a
    USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
  WHERE s.strategy_profile_code='BASELINE_REPLAY'
    AND (s.source_pricing_disposition_code IS DISTINCT FROM a.pricing_disposition_code
      OR s.source_structure_available_flag IS DISTINCT FROM a.structure_available_flag
      OR s.source_review_required_flag IS DISTINCT FROM a.review_required_flag
      OR s.source_activation_outcome_code IS DISTINCT FROM a.activation_outcome_code
      OR NOT coalesce(s.baseline_replay_match_flag,FALSE));
  IF v_n<>0 THEN RAISE EXCEPTION 'BASELINE_REPLAY source-outcome mismatch count %',v_n; END IF;
END;
$m211$;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  /* Exact selected-outcome replay: M2.2 structure plus M2.4 disposition. */
  SELECT count(*) INTO v_n
  FROM tmp_eval_m2_11_application_simulation s
  JOIN tmp_src_m2_11_application_snapshot a
    USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
  LEFT JOIN tmp_src_m2_11_candidate_snapshot c
    ON c.module1_run_id=a.module1_run_id AND c.scenario_id=a.scenario_id
   AND c.merchant_application_id=a.merchant_application_id
   AND c.candidate_template_code=a.selected_candidate_template_code
   AND c.source_candidate_row_hash=a.selected_candidate_row_hash
  WHERE s.strategy_profile_code IN ('BASELINE_REPLAY','EARLY_INTERVENTION')
    AND
    (
      s.strategy_outcome_code IS DISTINCT FROM
        CASE a.activation_outcome_code
          WHEN 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED' THEN 'ACCESS_SELECTED'
          WHEN 'ACTIVATION_REVIEW_REQUIRED' THEN 'CONTROLLED_REVIEW'
          WHEN 'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE' THEN 'NO_ACCESS_INSUFFICIENT_EVIDENCE'
          WHEN 'NOT_ACTIVATED_POLICY_DECLINE' THEN 'NO_ACCESS_POLICY_DECLINE'
          ELSE 'BLOCKED_SOURCE_INTEGRITY'
        END
      OR s.selected_candidate_template_code IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN a.selected_candidate_template_code END
      OR s.selected_candidate_source_row_hash IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN a.selected_candidate_row_hash END
      OR s.selected_exposure_amount IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN a.selected_funding_amount ELSE 0.00::numeric END
      OR s.selected_remittance_rate IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN a.selected_remittance_rate END
      OR s.selected_payback_multiple IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN a.selected_payback_multiple END
      OR s.selected_collection_horizon_days IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN a.selected_collection_horizon_days END
      OR s.selected_total_repayment_amount IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN a.selected_total_repayment_amount ELSE 0.00::numeric END
      OR s.selected_finance_charge_amount IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN a.selected_finance_charge_amount ELSE 0.00::numeric END
      OR s.selected_implied_daily_collection_amount IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN a.selected_implied_daily_collection_amount END
      OR s.selected_implied_payoff_days IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN a.selected_implied_payoff_days END
      OR s.selected_amount_to_request_ratio IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN a.selected_amount_to_request_ratio END
      OR s.selected_acquisition_economics_amount IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN c.acquisition_economics_amount END
      OR s.selected_expected_loss_amount IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN c.expected_loss_amount ELSE 0.00::numeric END
      OR s.selected_expected_loss_density IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED')
             THEN round(c.expected_loss_amount/NULLIF(a.selected_funding_amount,0),10)::numeric(28,10) END
      OR s.selected_risk_adjusted_contribution IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN c.risk_adjusted_contribution_amount ELSE 0.00::numeric END
      OR s.selected_annualized_risk_adjusted_return IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN c.annualized_return_rate ELSE 0.00000000::numeric END
      OR s.selected_payment_burden_rate IS DISTINCT FROM
        CASE WHEN a.activation_outcome_code IN ('BOOKED_FUNDED_PORTFOLIO_ACTIVATED','ACTIVATION_REVIEW_REQUIRED') THEN a.selected_remittance_rate ELSE 0.000000::numeric END
    );
  IF v_n<>0 THEN RAISE EXCEPTION 'BASELINE_REPLAY/EARLY_INTERVENTION selected economics mismatch count %',v_n; END IF;

  /* Amendment B no-access persistence convention. */
  SELECT count(*) INTO v_n
  FROM tmp_eval_m2_11_application_simulation
  WHERE strategy_outcome_code NOT IN ('ACCESS_SELECTED','CONTROLLED_REVIEW')
    AND
    (
      selected_exposure_amount<>0.00::numeric
      OR selected_expected_loss_amount<>0.00::numeric
      OR selected_finance_charge_amount<>0.00::numeric
      OR selected_risk_adjusted_contribution<>0.00::numeric
      OR selected_annualized_risk_adjusted_return<>0.00000000::numeric
      OR selected_payment_burden_rate<>0.000000::numeric
      OR selected_expected_loss_density IS NOT NULL
    );
  IF v_n<>0 THEN RAISE EXCEPTION 'No-access persisted-economics convention mismatch count %',v_n; END IF;
END;
$m211$;

/* ============================================================================
Section 10 — Scope populations, aggregation, and scope strategy scores
============================================================================ */
CREATE TEMP TABLE tmp_scope_application_rows ON COMMIT DROP AS
SELECT 'BASELINE'::text AS reporting_scope_code,a.*
FROM tmp_eval_m2_11_application_simulation a WHERE a.scenario_code='BASELINE'
UNION ALL
SELECT 'RECESSION_ENERGY'::text,a.*
FROM tmp_eval_m2_11_application_simulation a WHERE a.scenario_code='RECESSION_ENERGY'
UNION ALL
SELECT 'PORTFOLIO'::text,a.*
FROM tmp_eval_m2_11_application_simulation a WHERE a.portfolio_adverse_selected_flag;

CREATE INDEX tmp_scope_application_rows_i1
ON tmp_scope_application_rows(module1_run_id,reporting_scope_code,strategy_profile_code,merchant_application_id);
ANALYZE tmp_scope_application_rows;

CREATE TEMP TABLE tmp_scope_account_rows ON COMMIT DROP AS
SELECT 'BASELINE'::text AS reporting_scope_code,a.*
FROM tmp_eval_m2_11_account_simulation a WHERE a.scenario_code='BASELINE'
UNION ALL
SELECT 'RECESSION_ENERGY'::text,a.*
FROM tmp_eval_m2_11_account_simulation a WHERE a.scenario_code='RECESSION_ENERGY'
UNION ALL
SELECT 'PORTFOLIO'::text,a.*
FROM tmp_eval_m2_11_account_simulation a WHERE a.portfolio_adverse_selected_flag;

CREATE INDEX tmp_scope_account_rows_i1
ON tmp_scope_account_rows(module1_run_id,reporting_scope_code,strategy_profile_code,merchant_application_id);
ANALYZE tmp_scope_account_rows;

CREATE TEMP TABLE tmp_scope_application_aggregate ON COMMIT DROP AS
SELECT
  module1_run_id,strategy_profile_code,reporting_scope_code,
  count(*)::bigint AS application_rows,
  count(*) FILTER(WHERE access_selected_flag)::bigint AS access_selected_rows,
  count(*) FILTER(WHERE controlled_review_flag)::bigint AS controlled_review_rows,
  count(*) FILTER(WHERE strategy_outcome_code='NO_ACCESS_STRATEGY_RESTRICTION')::bigint AS strategy_restriction_rows,
  count(*) FILTER(WHERE strategy_outcome_code='NO_ACCESS_NO_FEASIBLE_CANDIDATE')::bigint AS no_feasible_candidate_rows,
  count(*) FILTER(WHERE strategy_outcome_code='NO_ACCESS_INSUFFICIENT_EVIDENCE')::bigint AS insufficient_evidence_rows,
  count(*) FILTER(WHERE strategy_outcome_code='NO_ACCESS_POLICY_DECLINE')::bigint AS policy_decline_rows,
  count(*) FILTER(WHERE strategy_outcome_code='BLOCKED_SOURCE_INTEGRITY')::bigint AS blocked_source_rows,
  sum(hard_constraint_violation_count)::bigint AS hard_constraint_violation_count,
  count(*) FILTER(WHERE strategy_evidence_status='COMPLETE')::bigint AS complete_evidence_rows,
  count(*) FILTER(WHERE strategy_evidence_status='PARTIAL')::bigint AS partial_evidence_rows,
  count(*) FILTER(WHERE strategy_evidence_status='BLOCKED')::bigint AS blocked_evidence_rows,
  count(*) FILTER(WHERE source_risk_improvement_violation_flag)::bigint AS source_risk_improvement_violation_count,
  count(*) FILTER(WHERE source_return_improvement_violation_flag)::bigint AS source_return_improvement_violation_count,
  count(*) FILTER(WHERE strategy_access_improvement_violation_flag)::bigint AS strategy_access_improvement_violation_count,
  count(*) FILTER(WHERE strategy_feasibility_improvement_violation_flag)::bigint AS strategy_feasibility_improvement_violation_count,
  count(*) FILTER(WHERE comparable_payment_burden_improvement_violation_flag)::bigint AS comparable_payment_burden_improvement_violation_count,
  count(*) FILTER(WHERE comparable_servicing_burden_improvement_violation_flag)::bigint AS comparable_servicing_burden_improvement_violation_count,
  count(*) FILTER(WHERE strategy_restriction_flag)::bigint AS stress_strategy_restriction_rows,
  count(*) FILTER(WHERE absolute_workload_reduction_flag)::bigint AS absolute_workload_reduction_rows,
  round(count(*) FILTER(WHERE access_selected_flag)::numeric/NULLIF(count(*),0),10)::numeric(18,10) AS access_rate,
  coalesce(sum(selected_exposure_amount),0)::numeric(24,2) AS selected_exposure_amount,
  coalesce(sum(selected_finance_charge_amount),0)::numeric(24,2) AS finance_charge_amount,
  coalesce(sum(selected_expected_loss_amount),0)::numeric(24,2) AS expected_loss_amount,
  CASE WHEN sum(selected_exposure_amount)=0 THEN NULL
       ELSE round(sum(selected_expected_loss_amount)/sum(selected_exposure_amount),10)::numeric(18,10) END AS expected_loss_density,
  coalesce(sum(selected_risk_adjusted_contribution),0)::numeric(24,2) AS risk_adjusted_contribution,
  CASE WHEN sum(selected_exposure_amount)=0 THEN NULL
       WHEN count(*) FILTER(WHERE selected_exposure_amount>0 AND selected_annualized_risk_adjusted_return IS NULL)>0 THEN NULL
       ELSE round(sum(selected_exposure_amount*selected_annualized_risk_adjusted_return)/sum(selected_exposure_amount),10)::numeric(18,10) END AS annualized_risk_adjusted_return,
  CASE WHEN sum(selected_exposure_amount)=0 THEN NULL
       WHEN count(*) FILTER(WHERE selected_exposure_amount>0 AND selected_payment_burden_rate IS NULL)>0 THEN NULL
       ELSE round(sum(selected_exposure_amount*selected_payment_burden_rate)/sum(selected_exposure_amount),10)::numeric(18,10) END AS payment_burden_rate,
  md5(string_agg(row_hash,'|' ORDER BY merchant_application_id,scenario_id,row_hash)) AS application_simulation_set_hash
FROM tmp_scope_application_rows
GROUP BY module1_run_id,strategy_profile_code,reporting_scope_code;

/* PORTFOLIO is an adverse application rollup, but its stress-comparison fields
   must still represent the matched baseline-versus-stress comparison for all
   750 applications rather than only the scenario row selected by adversity. */
UPDATE tmp_scope_application_aggregate a
SET source_risk_improvement_violation_count=x.source_risk_improvement_violation_count,
    source_return_improvement_violation_count=x.source_return_improvement_violation_count,
    strategy_access_improvement_violation_count=x.strategy_access_improvement_violation_count,
    strategy_feasibility_improvement_violation_count=x.strategy_feasibility_improvement_violation_count,
    comparable_payment_burden_improvement_violation_count=x.comparable_payment_burden_improvement_violation_count,
    comparable_servicing_burden_improvement_violation_count=x.comparable_servicing_burden_improvement_violation_count,
    stress_strategy_restriction_rows=x.stress_strategy_restriction_rows,
    absolute_workload_reduction_rows=x.absolute_workload_reduction_rows
FROM
(
  SELECT module1_run_id,strategy_profile_code,
    count(*) FILTER(WHERE source_risk_improvement_violation_flag)::bigint AS source_risk_improvement_violation_count,
    count(*) FILTER(WHERE source_return_improvement_violation_flag)::bigint AS source_return_improvement_violation_count,
    count(*) FILTER(WHERE strategy_access_improvement_violation_flag)::bigint AS strategy_access_improvement_violation_count,
    count(*) FILTER(WHERE strategy_feasibility_improvement_violation_flag)::bigint AS strategy_feasibility_improvement_violation_count,
    count(*) FILTER(WHERE comparable_payment_burden_improvement_violation_flag)::bigint AS comparable_payment_burden_improvement_violation_count,
    count(*) FILTER(WHERE comparable_servicing_burden_improvement_violation_flag)::bigint AS comparable_servicing_burden_improvement_violation_count,
    count(*) FILTER(WHERE strategy_restriction_flag)::bigint AS stress_strategy_restriction_rows,
    count(*) FILTER(WHERE absolute_workload_reduction_flag)::bigint AS absolute_workload_reduction_rows
  FROM tmp_eval_app_stress_flags
  GROUP BY module1_run_id,strategy_profile_code
) x
WHERE a.module1_run_id=x.module1_run_id
  AND a.strategy_profile_code=x.strategy_profile_code
  AND a.reporting_scope_code='PORTFOLIO';

CREATE UNIQUE INDEX tmp_scope_application_aggregate_u1
ON tmp_scope_application_aggregate(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_application_aggregate;

CREATE TEMP TABLE tmp_scope_account_aggregate ON COMMIT DROP AS
SELECT
  module1_run_id,strategy_profile_code,reporting_scope_code,
  count(*)::bigint AS servicing_account_rows,
  count(DISTINCT merchant_application_id)::bigint AS servicing_distinct_application_rows,
  coalesce(sum(strategy_servicing_burden_units),0)::numeric(24,6) AS servicing_burden_units,
  md5(string_agg(row_hash,'|' ORDER BY merchant_application_id,scenario_id,row_hash)) AS account_simulation_set_hash
FROM tmp_scope_account_rows
GROUP BY module1_run_id,strategy_profile_code,reporting_scope_code;

CREATE UNIQUE INDEX tmp_scope_account_aggregate_u1
ON tmp_scope_account_aggregate(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_account_aggregate;

CREATE TEMP TABLE tmp_scope_summary_raw ON COMMIT DROP AS
SELECT
  a.*,
  (a.source_risk_improvement_violation_count+a.source_return_improvement_violation_count
   +a.strategy_access_improvement_violation_count+a.strategy_feasibility_improvement_violation_count
   +a.comparable_payment_burden_improvement_violation_count+a.comparable_servicing_burden_improvement_violation_count)::bigint AS stress_improvement_violation_count,
  x.servicing_account_rows,x.servicing_distinct_application_rows,
  x.servicing_burden_units,x.account_simulation_set_hash,
  'ACCEPTED_OPERATIONAL_ACCOUNTS_ONLY'::text AS servicing_burden_coverage_code,
  FALSE AS new_access_servicing_burden_estimated_flag,
  CASE WHEN a.blocked_source_rows>0 THEN 'BLOCKED'
       WHEN a.partial_evidence_rows>0 OR a.insufficient_evidence_rows>0 OR a.controlled_review_rows>0 THEN 'PARTIAL'
       ELSE 'COMPLETE' END AS strategy_evidence_status
FROM tmp_scope_application_aggregate a
JOIN tmp_scope_account_aggregate x
  USING(module1_run_id,strategy_profile_code,reporting_scope_code);

CREATE UNIQUE INDEX tmp_scope_summary_raw_u1
ON tmp_scope_summary_raw(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_summary_raw;

CREATE TEMP TABLE tmp_scope_summary_normalized ON COMMIT DROP AS
WITH b AS
(
 SELECT r.*,p.selected_exposure_direction,
   p.access_rate_weight,p.selected_exposure_weight,p.finance_charge_weight,
   p.expected_loss_density_weight,p.risk_adjusted_contribution_weight,
   p.annualized_return_weight,p.servicing_burden_weight,p.payment_burden_weight,
   p.scope_domain_weight_total,p.scope_scoring_applicable_flag,
   min(access_rate) OVER w AS access_min,max(access_rate) OVER w AS access_max,
   min(selected_exposure_amount) OVER w AS exposure_min,max(selected_exposure_amount) OVER w AS exposure_max,
   min(finance_charge_amount) OVER w AS finance_min,max(finance_charge_amount) OVER w AS finance_max,
   min(expected_loss_density) OVER w AS loss_min,max(expected_loss_density) OVER w AS loss_max,
   min(risk_adjusted_contribution) OVER w AS contribution_min,max(risk_adjusted_contribution) OVER w AS contribution_max,
   min(annualized_risk_adjusted_return) OVER w AS return_min,max(annualized_risk_adjusted_return) OVER w AS return_max,
   min(servicing_burden_units) OVER w AS servicing_min,max(servicing_burden_units) OVER w AS servicing_max,
   min(payment_burden_rate) OVER w AS payment_min,max(payment_burden_rate) OVER w AS payment_max
 FROM tmp_scope_summary_raw r
 JOIN msbf_m2.portfolio_strategy_profile p USING(module1_run_id,strategy_profile_code)
 WINDOW w AS (PARTITION BY r.module1_run_id,r.reporting_scope_code)
), n AS
(
 SELECT b.*,
  round(CASE WHEN access_max=access_min THEN 1 ELSE (access_rate-access_min)/(access_max-access_min) END,10)::numeric(18,10) AS access_norm,
  round(CASE WHEN exposure_max=exposure_min THEN 1 WHEN selected_exposure_direction='MINIMIZE' THEN (exposure_max-selected_exposure_amount)/(exposure_max-exposure_min) ELSE (selected_exposure_amount-exposure_min)/(exposure_max-exposure_min) END,10)::numeric(18,10) AS exposure_norm,
  round(CASE WHEN finance_max=finance_min THEN 1 ELSE (finance_charge_amount-finance_min)/(finance_max-finance_min) END,10)::numeric(18,10) AS finance_norm,
  CASE WHEN expected_loss_density IS NULL THEN NULL WHEN loss_max=loss_min THEN 1 ELSE round((loss_max-expected_loss_density)/(loss_max-loss_min),10)::numeric(18,10) END AS loss_norm,
  round(CASE WHEN contribution_max=contribution_min THEN 1 ELSE (risk_adjusted_contribution-contribution_min)/(contribution_max-contribution_min) END,10)::numeric(18,10) AS contribution_norm,
  CASE WHEN annualized_risk_adjusted_return IS NULL THEN NULL WHEN return_max=return_min THEN 1 ELSE round((annualized_risk_adjusted_return-return_min)/(return_max-return_min),10)::numeric(18,10) END AS return_norm,
  round(CASE WHEN servicing_max=servicing_min THEN 1 ELSE (servicing_max-servicing_burden_units)/(servicing_max-servicing_min) END,10)::numeric(18,10) AS servicing_norm,
  CASE WHEN payment_burden_rate IS NULL THEN NULL WHEN payment_max=payment_min THEN 1 ELSE round((payment_max-payment_burden_rate)/(payment_max-payment_min),10)::numeric(18,10) END AS payment_norm
 FROM b
)
SELECT n.*,
  round(access_norm*access_rate_weight,12)::numeric(22,12) AS access_weighted,
  round(exposure_norm*selected_exposure_weight,12)::numeric(22,12) AS exposure_weighted,
  round(finance_norm*finance_charge_weight,12)::numeric(22,12) AS finance_weighted,
  CASE WHEN expected_loss_density_weight=0 THEN 0::numeric(22,12) WHEN loss_norm IS NULL THEN NULL ELSE round(loss_norm*expected_loss_density_weight,12)::numeric(22,12) END AS loss_weighted,
  round(contribution_norm*risk_adjusted_contribution_weight,12)::numeric(22,12) AS contribution_weighted,
  CASE WHEN annualized_return_weight=0 THEN 0::numeric(22,12) WHEN return_norm IS NULL THEN NULL ELSE round(return_norm*annualized_return_weight,12)::numeric(22,12) END AS return_weighted,
  round(servicing_norm*servicing_burden_weight,12)::numeric(22,12) AS servicing_weighted,
  CASE WHEN payment_burden_weight=0 THEN 0::numeric(22,12) WHEN payment_norm IS NULL THEN NULL ELSE round(payment_norm*payment_burden_weight,12)::numeric(22,12) END AS payment_weighted
FROM n;

CREATE UNIQUE INDEX tmp_scope_summary_normalized_u1
ON tmp_scope_summary_normalized(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_summary_normalized;

CREATE TEMP TABLE tmp_scope_summary_final_projection ON COMMIT DROP AS
SELECT
    n.module1_run_id AS module1_run_id,
    n.strategy_profile_code AS strategy_profile_code,
    n.reporting_scope_code AS reporting_scope_code,
    n.application_rows AS application_rows,
    n.access_selected_rows AS access_selected_rows,
    n.controlled_review_rows AS controlled_review_rows,
    n.strategy_restriction_rows AS strategy_restriction_rows,
    n.no_feasible_candidate_rows AS no_feasible_candidate_rows,
    n.insufficient_evidence_rows AS insufficient_evidence_rows,
    n.policy_decline_rows AS policy_decline_rows,
    n.blocked_source_rows AS blocked_source_rows,
    n.hard_constraint_violation_count AS hard_constraint_violation_count,
    n.complete_evidence_rows AS complete_evidence_rows,
    n.partial_evidence_rows AS partial_evidence_rows,
    n.blocked_evidence_rows AS blocked_evidence_rows,
    n.source_risk_improvement_violation_count AS source_risk_improvement_violation_count,
    n.source_return_improvement_violation_count AS source_return_improvement_violation_count,
    n.strategy_access_improvement_violation_count AS strategy_access_improvement_violation_count,
    n.strategy_feasibility_improvement_violation_count AS strategy_feasibility_improvement_violation_count,
    n.comparable_payment_burden_improvement_violation_count AS comparable_payment_burden_improvement_violation_count,
    n.comparable_servicing_burden_improvement_violation_count AS comparable_servicing_burden_improvement_violation_count,
    n.stress_improvement_violation_count AS stress_improvement_violation_count,
    n.stress_strategy_restriction_rows AS stress_strategy_restriction_rows,
    n.absolute_workload_reduction_rows AS absolute_workload_reduction_rows,
    n.servicing_account_rows AS servicing_account_rows,
    n.servicing_distinct_application_rows AS servicing_distinct_application_rows,
    n.access_rate AS access_rate,
    n.selected_exposure_amount AS selected_exposure_amount,
    n.finance_charge_amount AS finance_charge_amount,
    n.expected_loss_amount AS expected_loss_amount,
    n.expected_loss_density AS expected_loss_density,
    n.risk_adjusted_contribution AS risk_adjusted_contribution,
    n.annualized_risk_adjusted_return AS annualized_risk_adjusted_return,
    n.payment_burden_rate AS payment_burden_rate,
    n.servicing_burden_units AS servicing_burden_units,
    n.servicing_burden_coverage_code AS servicing_burden_coverage_code,
    n.new_access_servicing_burden_estimated_flag AS new_access_servicing_burden_estimated_flag,
    n.strategy_evidence_status AS strategy_evidence_status,
    n.application_simulation_set_hash AS application_simulation_set_hash,
    n.account_simulation_set_hash AS account_simulation_set_hash,
    (n.stress_improvement_violation_count=0) AS stress_nonimprovement_pass_flag,
    (n.access_rate IS NOT NULL AND n.finance_charge_amount IS NOT NULL AND n.expected_loss_density IS NOT NULL AND n.risk_adjusted_contribution IS NOT NULL AND n.annualized_risk_adjusted_return IS NOT NULL AND n.servicing_burden_units IS NOT NULL AND n.payment_burden_rate IS NOT NULL) AS frontier_metrics_complete_flag,
    n.access_norm AS access_rate_normalized_value,
    n.access_weighted AS access_rate_weighted_contribution,
    n.exposure_norm AS selected_exposure_amount_normalized_value,
    n.exposure_weighted AS selected_exposure_amount_weighted_contribution,
    n.finance_norm AS finance_charge_amount_normalized_value,
    n.finance_weighted AS finance_charge_amount_weighted_contribution,
    n.loss_norm AS expected_loss_density_normalized_value,
    n.loss_weighted AS expected_loss_density_weighted_contribution,
    n.contribution_norm AS risk_adjusted_contribution_normalized_value,
    n.contribution_weighted AS risk_adjusted_contribution_weighted_contribution,
    n.return_norm AS annualized_risk_adjusted_return_normalized_value,
    n.return_weighted AS annualized_risk_adjusted_return_weighted_contribution,
    n.servicing_norm AS servicing_burden_units_normalized_value,
    n.servicing_weighted AS servicing_burden_units_weighted_contribution,
    n.payment_norm AS payment_burden_rate_normalized_value,
    n.payment_weighted AS payment_burden_rate_weighted_contribution,
    CASE WHEN n.strategy_profile_code='BASELINE_REPLAY' THEN NULL::numeric(22,12) WHEN (n.expected_loss_density_weight>0 AND n.loss_norm IS NULL) OR (n.annualized_return_weight>0 AND n.return_norm IS NULL) OR (n.payment_burden_weight>0 AND n.payment_norm IS NULL) THEN NULL::numeric(22,12) ELSE round((n.access_weighted+n.exposure_weighted+n.finance_weighted+n.loss_weighted+n.contribution_weighted+n.return_weighted+n.servicing_weighted+n.payment_weighted)/NULLIF(n.scope_domain_weight_total,0),12)::numeric(22,12) END AS scope_strategy_score
FROM tmp_scope_summary_normalized n
ORDER BY n.module1_run_id,n.reporting_scope_code,n.strategy_profile_code;

CREATE UNIQUE INDEX tmp_scope_summary_final_u1 ON tmp_scope_summary_final_projection(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_summary_final_projection;

/* Target-type-before-hash projection for msbf_m2.portfolio_strategy_summary. */
CREATE TEMP TABLE tmp_scope_m2_11_strategy_summary ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_summary WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_scope_m2_11_strategy_summary') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_summary'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_scope_m2_11_strategy_summary versus msbf_m2.portfolio_strategy_summary: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_scope_m2_11_strategy_summary
(
    module1_run_id, strategy_profile_code, reporting_scope_code, application_rows,
    access_selected_rows, controlled_review_rows, strategy_restriction_rows, no_feasible_candidate_rows,
    insufficient_evidence_rows, policy_decline_rows, blocked_source_rows, hard_constraint_violation_count,
    complete_evidence_rows, partial_evidence_rows, blocked_evidence_rows, source_risk_improvement_violation_count,
    source_return_improvement_violation_count, strategy_access_improvement_violation_count, strategy_feasibility_improvement_violation_count, comparable_payment_burden_improvement_violation_count,
    comparable_servicing_burden_improvement_violation_count, stress_improvement_violation_count, stress_strategy_restriction_rows, absolute_workload_reduction_rows,
    servicing_account_rows, servicing_distinct_application_rows, stress_nonimprovement_pass_flag, access_rate,
    selected_exposure_amount, finance_charge_amount, expected_loss_amount, expected_loss_density,
    risk_adjusted_contribution, annualized_risk_adjusted_return, payment_burden_rate, servicing_burden_units,
    servicing_burden_coverage_code, new_access_servicing_burden_estimated_flag, strategy_evidence_status, frontier_metrics_complete_flag,
    access_rate_normalized_value, access_rate_weighted_contribution, selected_exposure_amount_normalized_value, selected_exposure_amount_weighted_contribution,
    finance_charge_amount_normalized_value, finance_charge_amount_weighted_contribution, expected_loss_density_normalized_value, expected_loss_density_weighted_contribution,
    risk_adjusted_contribution_normalized_value, risk_adjusted_contribution_weighted_contribution, annualized_risk_adjusted_return_normalized_value, annualized_risk_adjusted_return_weighted_contribution,
    servicing_burden_units_normalized_value, servicing_burden_units_weighted_contribution, payment_burden_rate_normalized_value, payment_burden_rate_weighted_contribution,
    scope_strategy_score, application_simulation_set_hash, account_simulation_set_hash, row_hash,
    created_at
)
SELECT
    p.module1_run_id,
    p.strategy_profile_code,
    p.reporting_scope_code,
    p.application_rows,
    p.access_selected_rows,
    p.controlled_review_rows,
    p.strategy_restriction_rows,
    p.no_feasible_candidate_rows,
    p.insufficient_evidence_rows,
    p.policy_decline_rows,
    p.blocked_source_rows,
    p.hard_constraint_violation_count,
    p.complete_evidence_rows,
    p.partial_evidence_rows,
    p.blocked_evidence_rows,
    p.source_risk_improvement_violation_count,
    p.source_return_improvement_violation_count,
    p.strategy_access_improvement_violation_count,
    p.strategy_feasibility_improvement_violation_count,
    p.comparable_payment_burden_improvement_violation_count,
    p.comparable_servicing_burden_improvement_violation_count,
    p.stress_improvement_violation_count,
    p.stress_strategy_restriction_rows,
    p.absolute_workload_reduction_rows,
    p.servicing_account_rows,
    p.servicing_distinct_application_rows,
    p.stress_nonimprovement_pass_flag,
    p.access_rate,
    p.selected_exposure_amount,
    p.finance_charge_amount,
    p.expected_loss_amount,
    p.expected_loss_density,
    p.risk_adjusted_contribution,
    p.annualized_risk_adjusted_return,
    p.payment_burden_rate,
    p.servicing_burden_units,
    p.servicing_burden_coverage_code,
    p.new_access_servicing_burden_estimated_flag,
    p.strategy_evidence_status,
    p.frontier_metrics_complete_flag,
    p.access_rate_normalized_value,
    p.access_rate_weighted_contribution,
    p.selected_exposure_amount_normalized_value,
    p.selected_exposure_amount_weighted_contribution,
    p.finance_charge_amount_normalized_value,
    p.finance_charge_amount_weighted_contribution,
    p.expected_loss_density_normalized_value,
    p.expected_loss_density_weighted_contribution,
    p.risk_adjusted_contribution_normalized_value,
    p.risk_adjusted_contribution_weighted_contribution,
    p.annualized_risk_adjusted_return_normalized_value,
    p.annualized_risk_adjusted_return_weighted_contribution,
    p.servicing_burden_units_normalized_value,
    p.servicing_burden_units_weighted_contribution,
    p.payment_burden_rate_normalized_value,
    p.payment_burden_rate_weighted_contribution,
    p.scope_strategy_score,
    p.application_simulation_set_hash,
    p.account_simulation_set_hash,
    NULL::text,
    NULL::timestamptz
FROM tmp_scope_summary_final_projection p
ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code;

UPDATE tmp_scope_m2_11_strategy_summary AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

-- Enforce one summary per strategy and reporting scope before frontier,
-- comparison, and contract construction consume this temporary authority.
CREATE UNIQUE INDEX tmp_scope_m2_11_strategy_summary_u1
ON tmp_scope_m2_11_strategy_summary
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_m2_11_strategy_summary;

INSERT INTO msbf_m2.portfolio_strategy_summary
(
    module1_run_id, strategy_profile_code, reporting_scope_code, application_rows,
    access_selected_rows, controlled_review_rows, strategy_restriction_rows, no_feasible_candidate_rows,
    insufficient_evidence_rows, policy_decline_rows, blocked_source_rows, hard_constraint_violation_count,
    complete_evidence_rows, partial_evidence_rows, blocked_evidence_rows, source_risk_improvement_violation_count,
    source_return_improvement_violation_count, strategy_access_improvement_violation_count, strategy_feasibility_improvement_violation_count, comparable_payment_burden_improvement_violation_count,
    comparable_servicing_burden_improvement_violation_count, stress_improvement_violation_count, stress_strategy_restriction_rows, absolute_workload_reduction_rows,
    servicing_account_rows, servicing_distinct_application_rows, stress_nonimprovement_pass_flag, access_rate,
    selected_exposure_amount, finance_charge_amount, expected_loss_amount, expected_loss_density,
    risk_adjusted_contribution, annualized_risk_adjusted_return, payment_burden_rate, servicing_burden_units,
    servicing_burden_coverage_code, new_access_servicing_burden_estimated_flag, strategy_evidence_status, frontier_metrics_complete_flag,
    access_rate_normalized_value, access_rate_weighted_contribution, selected_exposure_amount_normalized_value, selected_exposure_amount_weighted_contribution,
    finance_charge_amount_normalized_value, finance_charge_amount_weighted_contribution, expected_loss_density_normalized_value, expected_loss_density_weighted_contribution,
    risk_adjusted_contribution_normalized_value, risk_adjusted_contribution_weighted_contribution, annualized_risk_adjusted_return_normalized_value, annualized_risk_adjusted_return_weighted_contribution,
    servicing_burden_units_normalized_value, servicing_burden_units_weighted_contribution, payment_burden_rate_normalized_value, payment_burden_rate_weighted_contribution,
    scope_strategy_score, application_simulation_set_hash, account_simulation_set_hash, row_hash,
    created_at
)
SELECT
    t.module1_run_id,
    t.strategy_profile_code,
    t.reporting_scope_code,
    t.application_rows,
    t.access_selected_rows,
    t.controlled_review_rows,
    t.strategy_restriction_rows,
    t.no_feasible_candidate_rows,
    t.insufficient_evidence_rows,
    t.policy_decline_rows,
    t.blocked_source_rows,
    t.hard_constraint_violation_count,
    t.complete_evidence_rows,
    t.partial_evidence_rows,
    t.blocked_evidence_rows,
    t.source_risk_improvement_violation_count,
    t.source_return_improvement_violation_count,
    t.strategy_access_improvement_violation_count,
    t.strategy_feasibility_improvement_violation_count,
    t.comparable_payment_burden_improvement_violation_count,
    t.comparable_servicing_burden_improvement_violation_count,
    t.stress_improvement_violation_count,
    t.stress_strategy_restriction_rows,
    t.absolute_workload_reduction_rows,
    t.servicing_account_rows,
    t.servicing_distinct_application_rows,
    t.stress_nonimprovement_pass_flag,
    t.access_rate,
    t.selected_exposure_amount,
    t.finance_charge_amount,
    t.expected_loss_amount,
    t.expected_loss_density,
    t.risk_adjusted_contribution,
    t.annualized_risk_adjusted_return,
    t.payment_burden_rate,
    t.servicing_burden_units,
    t.servicing_burden_coverage_code,
    t.new_access_servicing_burden_estimated_flag,
    t.strategy_evidence_status,
    t.frontier_metrics_complete_flag,
    t.access_rate_normalized_value,
    t.access_rate_weighted_contribution,
    t.selected_exposure_amount_normalized_value,
    t.selected_exposure_amount_weighted_contribution,
    t.finance_charge_amount_normalized_value,
    t.finance_charge_amount_weighted_contribution,
    t.expected_loss_density_normalized_value,
    t.expected_loss_density_weighted_contribution,
    t.risk_adjusted_contribution_normalized_value,
    t.risk_adjusted_contribution_weighted_contribution,
    t.annualized_risk_adjusted_return_normalized_value,
    t.annualized_risk_adjusted_return_weighted_contribution,
    t.servicing_burden_units_normalized_value,
    t.servicing_burden_units_weighted_contribution,
    t.payment_burden_rate_normalized_value,
    t.payment_burden_rate_weighted_contribution,
    t.scope_strategy_score,
    t.application_simulation_set_hash,
    t.account_simulation_set_hash,
    t.row_hash,
    t.created_at
FROM tmp_scope_m2_11_strategy_summary t
ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n FROM tmp_scope_m2_11_strategy_summary;
  IF v_n<>24 THEN RAISE EXCEPTION 'Strategy summary expected 24; found %',v_n; END IF;
  SELECT count(*) INTO v_n FROM tmp_scope_m2_11_strategy_summary WHERE application_rows<>750;
  IF v_n<>0 THEN RAISE EXCEPTION 'Scope denominator mismatch count %',v_n; END IF;
  SELECT count(*) INTO v_n FROM tmp_scope_m2_11_strategy_summary
  WHERE (reporting_scope_code='BASELINE' AND servicing_account_rows<>44)
     OR (reporting_scope_code='RECESSION_ENERGY' AND servicing_account_rows<>15)
     OR (reporting_scope_code='PORTFOLIO' AND servicing_account_rows<>44);
  IF v_n<>0 THEN RAISE EXCEPTION 'Scope account coverage mismatch count %',v_n; END IF;
  SELECT count(*) INTO v_n FROM tmp_scope_m2_11_strategy_summary
  WHERE servicing_burden_coverage_code<>'ACCEPTED_OPERATIONAL_ACCOUNTS_ONLY'
     OR new_access_servicing_burden_estimated_flag;
  IF v_n<>0 THEN RAISE EXCEPTION 'Servicing coverage boundary mismatch count %',v_n; END IF;
END;
$m211$;

/* ============================================================================
Section 11 — Seven-objective Pareto frontier and governance-review priority
============================================================================ */
CREATE TEMP TABLE tmp_frontier_eligible_base ON COMMIT DROP AS
SELECT s.*,
  (
    s.hard_constraint_violation_count=0
    AND s.strategy_evidence_status<>'BLOCKED'
    AND s.frontier_metrics_complete_flag
    AND s.stress_improvement_violation_count=0
  ) AS frontier_eligible_flag,
  CASE
    WHEN s.hard_constraint_violation_count<>0 THEN 'HARD_CONSTRAINT_VIOLATION'
    WHEN s.strategy_evidence_status='BLOCKED' THEN 'BLOCKED_EVIDENCE'
    WHEN NOT s.frontier_metrics_complete_flag THEN 'INCOMPLETE_FRONTIER_METRICS'
    WHEN s.stress_improvement_violation_count<>0 THEN 'STRESS_IMPROVEMENT_VIOLATION'
    ELSE NULL END AS frontier_ineligibility_code,
  CASE s.strategy_evidence_status WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END::smallint AS evidence_rank
FROM tmp_scope_m2_11_strategy_summary s;

CREATE UNIQUE INDEX tmp_frontier_eligible_base_u1
ON tmp_frontier_eligible_base(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_frontier_eligible_base;

CREATE TEMP TABLE tmp_frontier_dominance_edge ON COMMIT DROP AS
SELECT
  a.module1_run_id,a.reporting_scope_code,
  a.strategy_profile_code AS dominator_strategy_profile_code,
  b.strategy_profile_code AS dominated_strategy_profile_code
FROM tmp_frontier_eligible_base a
JOIN tmp_frontier_eligible_base b
  ON b.module1_run_id=a.module1_run_id
 AND b.reporting_scope_code=a.reporting_scope_code
 AND b.strategy_profile_code<>a.strategy_profile_code
WHERE a.frontier_eligible_flag AND b.frontier_eligible_flag
  AND a.access_rate >= b.access_rate-0.00000001
  AND a.finance_charge_amount >= b.finance_charge_amount-0.01
  AND a.expected_loss_density <= b.expected_loss_density+0.00000001
  AND a.risk_adjusted_contribution >= b.risk_adjusted_contribution-0.01
  AND a.annualized_risk_adjusted_return >= b.annualized_risk_adjusted_return-0.00000001
  AND a.servicing_burden_units <= b.servicing_burden_units+0.000001
  AND a.payment_burden_rate <= b.payment_burden_rate+0.00000001
  AND (
    a.access_rate > b.access_rate+0.00000001
    OR a.finance_charge_amount > b.finance_charge_amount+0.01
    OR a.expected_loss_density < b.expected_loss_density-0.00000001
    OR a.risk_adjusted_contribution > b.risk_adjusted_contribution+0.01
    OR a.annualized_risk_adjusted_return > b.annualized_risk_adjusted_return+0.00000001
    OR a.servicing_burden_units < b.servicing_burden_units-0.000001
    OR a.payment_burden_rate < b.payment_burden_rate-0.00000001
  );

CREATE UNIQUE INDEX tmp_frontier_dominance_edge_u1
ON tmp_frontier_dominance_edge(module1_run_id,reporting_scope_code,dominator_strategy_profile_code,dominated_strategy_profile_code);
ANALYZE tmp_frontier_dominance_edge;

CREATE TEMP TABLE tmp_frontier_rank_work ON COMMIT DROP AS
SELECT module1_run_id,reporting_scope_code,strategy_profile_code,NULL::integer AS frontier_rank
FROM tmp_frontier_eligible_base WHERE frontier_eligible_flag;
ALTER TABLE tmp_frontier_rank_work ADD PRIMARY KEY(module1_run_id,reporting_scope_code,strategy_profile_code);

CREATE TEMP TABLE tmp_frontier_rank_batch
(
  module1_run_id bigint NOT NULL,
  reporting_scope_code text NOT NULL,
  strategy_profile_code text NOT NULL,
  PRIMARY KEY(module1_run_id,reporting_scope_code,strategy_profile_code)
) ON COMMIT DROP;

DO $m211$
DECLARE
    v_rank integer:=1;
    v_rows integer;
BEGIN
  LOOP
    TRUNCATE tmp_frontier_rank_batch;
    INSERT INTO tmp_frontier_rank_batch(module1_run_id,reporting_scope_code,strategy_profile_code)
    SELECT w.module1_run_id,w.reporting_scope_code,w.strategy_profile_code
    FROM tmp_frontier_rank_work w
    WHERE w.frontier_rank IS NULL
      AND NOT EXISTS
      (
        SELECT 1
        FROM tmp_frontier_dominance_edge e
        JOIN tmp_frontier_rank_work d
          ON d.module1_run_id=e.module1_run_id
         AND d.reporting_scope_code=e.reporting_scope_code
         AND d.strategy_profile_code=e.dominator_strategy_profile_code
         AND d.frontier_rank IS NULL
        WHERE e.module1_run_id=w.module1_run_id
          AND e.reporting_scope_code=w.reporting_scope_code
          AND e.dominated_strategy_profile_code=w.strategy_profile_code
      );
    GET DIAGNOSTICS v_rows=ROW_COUNT;
    EXIT WHEN v_rows=0;
    UPDATE tmp_frontier_rank_work w SET frontier_rank=v_rank
    FROM tmp_frontier_rank_batch b
    WHERE b.module1_run_id=w.module1_run_id
      AND b.reporting_scope_code=w.reporting_scope_code
      AND b.strategy_profile_code=w.strategy_profile_code;
    v_rank:=v_rank+1;
  END LOOP;
  IF EXISTS(SELECT 1 FROM tmp_frontier_rank_work WHERE frontier_rank IS NULL) THEN
    RAISE EXCEPTION 'Pareto ranking failed to exhaust eligible strategies';
  END IF;
END;
$m211$;

CREATE TEMP TABLE tmp_frontier_governance_normalized ON COMMIT DROP AS
WITH b AS
(
 SELECT e.*,
  min(access_rate) FILTER(WHERE frontier_eligible_flag) OVER w AS access_min,
  max(access_rate) FILTER(WHERE frontier_eligible_flag) OVER w AS access_max,
  min(finance_charge_amount) FILTER(WHERE frontier_eligible_flag) OVER w AS finance_min,
  max(finance_charge_amount) FILTER(WHERE frontier_eligible_flag) OVER w AS finance_max,
  min(expected_loss_density) FILTER(WHERE frontier_eligible_flag) OVER w AS loss_min,
  max(expected_loss_density) FILTER(WHERE frontier_eligible_flag) OVER w AS loss_max,
  min(risk_adjusted_contribution) FILTER(WHERE frontier_eligible_flag) OVER w AS contribution_min,
  max(risk_adjusted_contribution) FILTER(WHERE frontier_eligible_flag) OVER w AS contribution_max,
  min(annualized_risk_adjusted_return) FILTER(WHERE frontier_eligible_flag) OVER w AS return_min,
  max(annualized_risk_adjusted_return) FILTER(WHERE frontier_eligible_flag) OVER w AS return_max,
  min(servicing_burden_units) FILTER(WHERE frontier_eligible_flag) OVER w AS servicing_min,
  max(servicing_burden_units) FILTER(WHERE frontier_eligible_flag) OVER w AS servicing_max,
  min(payment_burden_rate) FILTER(WHERE frontier_eligible_flag) OVER w AS payment_min,
  max(payment_burden_rate) FILTER(WHERE frontier_eligible_flag) OVER w AS payment_max
 FROM tmp_frontier_eligible_base e
 WINDOW w AS(PARTITION BY e.module1_run_id,e.reporting_scope_code)
), n AS
(
 SELECT b.*,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN access_max=access_min THEN 1 ELSE round((access_rate-access_min)/(access_max-access_min),10)::numeric(18,10) END AS gov_access_norm,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN finance_max=finance_min THEN 1 ELSE round((finance_charge_amount-finance_min)/(finance_max-finance_min),10)::numeric(18,10) END AS gov_finance_norm,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN loss_max=loss_min THEN 1 ELSE round((loss_max-expected_loss_density)/(loss_max-loss_min),10)::numeric(18,10) END AS gov_loss_norm,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN contribution_max=contribution_min THEN 1 ELSE round((risk_adjusted_contribution-contribution_min)/(contribution_max-contribution_min),10)::numeric(18,10) END AS gov_contribution_norm,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN return_max=return_min THEN 1 ELSE round((annualized_risk_adjusted_return-return_min)/(return_max-return_min),10)::numeric(18,10) END AS gov_return_norm,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN servicing_max=servicing_min THEN 1 ELSE round((servicing_max-servicing_burden_units)/(servicing_max-servicing_min),10)::numeric(18,10) END AS gov_servicing_norm,
  CASE WHEN NOT frontier_eligible_flag THEN NULL WHEN payment_max=payment_min THEN 1 ELSE round((payment_max-payment_burden_rate)/(payment_max-payment_min),10)::numeric(18,10) END AS gov_payment_norm
 FROM b
)
SELECT n.*,
 CASE WHEN NOT frontier_eligible_flag THEN NULL
      ELSE round((gov_access_norm+gov_finance_norm+gov_loss_norm+gov_contribution_norm+gov_return_norm+gov_servicing_norm+gov_payment_norm)/7.0,12)::numeric(22,12) END AS governance_balance_score
FROM n;

CREATE UNIQUE INDEX tmp_frontier_governance_normalized_u1
ON tmp_frontier_governance_normalized(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_frontier_governance_normalized;

CREATE TEMP TABLE tmp_frontier_priority_rank ON COMMIT DROP AS
SELECT
  g.module1_run_id,g.reporting_scope_code,g.strategy_profile_code,
  row_number() OVER
  (
    PARTITION BY g.module1_run_id,g.reporting_scope_code
    ORDER BY g.evidence_rank,g.governance_balance_score DESC NULLS LAST,
      (g.risk_adjusted_contribution-b.risk_adjusted_contribution) DESC NULLS LAST,
      (g.expected_loss_density-b.expected_loss_density) ASC NULLS LAST,
      (g.access_rate-b.access_rate) DESC NULLS LAST,
      (g.payment_burden_rate-b.payment_burden_rate) ASC NULLS LAST,
      (g.servicing_burden_units-b.servicing_burden_units) ASC NULLS LAST,
      g.strategy_profile_code
  )::smallint AS governance_review_priority_rank
FROM tmp_frontier_governance_normalized g
JOIN tmp_frontier_rank_work r USING(module1_run_id,reporting_scope_code,strategy_profile_code)
JOIN tmp_frontier_governance_normalized b
  ON b.module1_run_id=g.module1_run_id
 AND b.reporting_scope_code=g.reporting_scope_code
 AND b.strategy_profile_code='BASELINE_REPLAY'
WHERE g.strategy_profile_code<>'BASELINE_REPLAY'
  AND r.frontier_rank=1
  AND g.hard_constraint_violation_count=0
  AND g.strategy_evidence_status IN ('COMPLETE','PARTIAL')
  AND g.stress_improvement_violation_count=0
  AND g.frontier_metrics_complete_flag;

CREATE UNIQUE INDEX tmp_frontier_priority_rank_u1
ON tmp_frontier_priority_rank(module1_run_id,reporting_scope_code,strategy_profile_code);
ANALYZE tmp_frontier_priority_rank;

CREATE TEMP TABLE tmp_frontier_final_projection ON COMMIT DROP AS
SELECT
    g.module1_run_id AS module1_run_id,
    g.strategy_profile_code AS strategy_profile_code,
    g.reporting_scope_code AS reporting_scope_code,
    g.row_hash AS strategy_summary_row_hash,
    g.frontier_eligible_flag AS frontier_eligible_flag,
    g.frontier_ineligibility_code AS frontier_ineligibility_code,
    coalesce(db.dominated_by_count,0)::integer AS dominated_by_count,
    coalesce(dm.dominates_count,0)::integer AS dominates_count,
    (coalesce(r.frontier_rank,0)=1) AS non_dominated_flag,
    r.frontier_rank AS frontier_rank,
    g.evidence_rank AS evidence_rank,
    g.governance_balance_score AS governance_balance_score,
    CASE WHEN g.strategy_profile_code='BASELINE_REPLAY' THEN 'CONTROL_REFERENCE' WHEN p.governance_review_priority_rank=1 THEN 'PRIMARY_GOVERNANCE_REVIEW' WHEN r.frontier_rank=1 THEN 'SECONDARY_FRONTIER_REVIEW' ELSE 'NO_FRONTIER_PRIORITY' END AS governance_review_priority_code,
    p.governance_review_priority_rank AS governance_review_priority_rank,
    coalesce(p.governance_review_priority_rank=1,false) AS primary_governance_review_flag,
    g.gov_access_norm AS governance_access_rate_normalized_value,
    g.gov_finance_norm AS governance_finance_charge_amount_normalized_value,
    g.gov_loss_norm AS governance_expected_loss_density_normalized_value,
    g.gov_contribution_norm AS governance_risk_adjusted_contribution_normalized_value,
    g.gov_return_norm AS governance_annualized_risk_adjusted_return_normalized_value,
    g.gov_servicing_norm AS governance_servicing_burden_units_normalized_value,
    g.gov_payment_norm AS governance_payment_burden_rate_normalized_value,
    CASE WHEN g.stress_improvement_violation_count>0 THEN 'M2_11_REASON_STRESS_IMPROVEMENT_VIOLATION' WHEN NOT g.frontier_eligible_flag AND g.strategy_evidence_status='BLOCKED' THEN 'M2_11_REASON_SOURCE_EVIDENCE_BLOCKED' WHEN NOT g.frontier_eligible_flag AND g.hard_constraint_violation_count>0 THEN 'M2_11_REASON_NO_FEASIBLE_CANDIDATE' WHEN NOT g.frontier_eligible_flag THEN 'M2_11_REASON_ECONOMIC_EVIDENCE_BLOCKED' WHEN coalesce(r.frontier_rank,0)=1 THEN CASE WHEN p.governance_review_priority_rank=1 THEN 'M2_11_REASON_GOVERNANCE_REVIEW_PRIORITY' ELSE 'M2_11_REASON_NONDOMINATED_FRONTIER' END ELSE 'M2_11_REASON_DOMINATED_STRATEGY' END AS primary_reason_code,
    to_jsonb(array_remove(ARRAY[CASE WHEN g.stress_improvement_violation_count>0 THEN 'M2_11_REASON_STRESS_IMPROVEMENT_VIOLATION' END,CASE WHEN NOT g.frontier_eligible_flag AND g.strategy_evidence_status='BLOCKED' THEN 'M2_11_REASON_SOURCE_EVIDENCE_BLOCKED' END,CASE WHEN NOT g.frontier_eligible_flag AND g.hard_constraint_violation_count>0 THEN 'M2_11_REASON_NO_FEASIBLE_CANDIDATE' END,CASE WHEN NOT g.frontier_eligible_flag AND g.strategy_evidence_status<>'BLOCKED' AND g.hard_constraint_violation_count=0 THEN 'M2_11_REASON_ECONOMIC_EVIDENCE_BLOCKED' END,CASE WHEN g.frontier_eligible_flag AND coalesce(r.frontier_rank,0)=1 THEN 'M2_11_REASON_NONDOMINATED_FRONTIER' END,CASE WHEN g.frontier_eligible_flag AND coalesce(r.frontier_rank,0)>1 THEN 'M2_11_REASON_DOMINATED_STRATEGY' END,CASE WHEN p.governance_review_priority_rank=1 THEN 'M2_11_REASON_GOVERNANCE_REVIEW_PRIORITY' END]::text[],NULL)) AS reason_codes
FROM tmp_frontier_governance_normalized g
LEFT JOIN tmp_frontier_rank_work r USING(module1_run_id,reporting_scope_code,strategy_profile_code)
LEFT JOIN (SELECT module1_run_id,reporting_scope_code,dominated_strategy_profile_code AS strategy_profile_code,count(*)::integer AS dominated_by_count FROM tmp_frontier_dominance_edge GROUP BY 1,2,3) db USING(module1_run_id,reporting_scope_code,strategy_profile_code)
LEFT JOIN (SELECT module1_run_id,reporting_scope_code,dominator_strategy_profile_code AS strategy_profile_code,count(*)::integer AS dominates_count FROM tmp_frontier_dominance_edge GROUP BY 1,2,3) dm USING(module1_run_id,reporting_scope_code,strategy_profile_code)
LEFT JOIN tmp_frontier_priority_rank p USING(module1_run_id,reporting_scope_code,strategy_profile_code)
ORDER BY g.module1_run_id,g.reporting_scope_code,g.strategy_profile_code;

CREATE UNIQUE INDEX tmp_frontier_final_u1 ON tmp_frontier_final_projection(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_frontier_final_projection;

/* Target-type-before-hash projection for msbf_m2.portfolio_strategy_frontier. */
CREATE TEMP TABLE tmp_frontier_m2_11_strategy_frontier ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_frontier WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_frontier_m2_11_strategy_frontier') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_frontier'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_frontier_m2_11_strategy_frontier versus msbf_m2.portfolio_strategy_frontier: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_frontier_m2_11_strategy_frontier
(
    module1_run_id, strategy_profile_code, reporting_scope_code, strategy_summary_row_hash,
    frontier_eligible_flag, frontier_ineligibility_code, dominated_by_count, dominates_count,
    non_dominated_flag, frontier_rank, evidence_rank, governance_balance_score,
    governance_review_priority_code, governance_review_priority_rank, primary_governance_review_flag, governance_access_rate_normalized_value,
    governance_finance_charge_amount_normalized_value, governance_expected_loss_density_normalized_value, governance_risk_adjusted_contribution_normalized_value, governance_annualized_risk_adjusted_return_normalized_value,
    governance_servicing_burden_units_normalized_value, governance_payment_burden_rate_normalized_value, primary_reason_code, reason_codes,
    row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.strategy_profile_code,
    p.reporting_scope_code,
    p.strategy_summary_row_hash,
    p.frontier_eligible_flag,
    p.frontier_ineligibility_code,
    p.dominated_by_count,
    p.dominates_count,
    p.non_dominated_flag,
    p.frontier_rank,
    p.evidence_rank,
    p.governance_balance_score,
    p.governance_review_priority_code,
    p.governance_review_priority_rank,
    p.primary_governance_review_flag,
    p.governance_access_rate_normalized_value,
    p.governance_finance_charge_amount_normalized_value,
    p.governance_expected_loss_density_normalized_value,
    p.governance_risk_adjusted_contribution_normalized_value,
    p.governance_annualized_risk_adjusted_return_normalized_value,
    p.governance_servicing_burden_units_normalized_value,
    p.governance_payment_burden_rate_normalized_value,
    p.primary_reason_code,
    p.reason_codes,
    NULL::text,
    NULL::timestamptz
FROM tmp_frontier_final_projection p
ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code;

UPDATE tmp_frontier_m2_11_strategy_frontier AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

-- Enforce one frontier result per strategy and reporting scope before
-- challenger comparison and latest-contract construction.
CREATE UNIQUE INDEX tmp_frontier_m2_11_strategy_frontier_u1
ON tmp_frontier_m2_11_strategy_frontier
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_frontier_m2_11_strategy_frontier;

INSERT INTO msbf_m2.portfolio_strategy_frontier
(
    module1_run_id, strategy_profile_code, reporting_scope_code, strategy_summary_row_hash,
    frontier_eligible_flag, frontier_ineligibility_code, dominated_by_count, dominates_count,
    non_dominated_flag, frontier_rank, evidence_rank, governance_balance_score,
    governance_review_priority_code, governance_review_priority_rank, primary_governance_review_flag, governance_access_rate_normalized_value,
    governance_finance_charge_amount_normalized_value, governance_expected_loss_density_normalized_value, governance_risk_adjusted_contribution_normalized_value, governance_annualized_risk_adjusted_return_normalized_value,
    governance_servicing_burden_units_normalized_value, governance_payment_burden_rate_normalized_value, primary_reason_code, reason_codes,
    row_hash, created_at
)
SELECT
    t.module1_run_id,
    t.strategy_profile_code,
    t.reporting_scope_code,
    t.strategy_summary_row_hash,
    t.frontier_eligible_flag,
    t.frontier_ineligibility_code,
    t.dominated_by_count,
    t.dominates_count,
    t.non_dominated_flag,
    t.frontier_rank,
    t.evidence_rank,
    t.governance_balance_score,
    t.governance_review_priority_code,
    t.governance_review_priority_rank,
    t.primary_governance_review_flag,
    t.governance_access_rate_normalized_value,
    t.governance_finance_charge_amount_normalized_value,
    t.governance_expected_loss_density_normalized_value,
    t.governance_risk_adjusted_contribution_normalized_value,
    t.governance_annualized_risk_adjusted_return_normalized_value,
    t.governance_servicing_burden_units_normalized_value,
    t.governance_payment_burden_rate_normalized_value,
    t.primary_reason_code,
    t.reason_codes,
    t.row_hash,
    t.created_at
FROM tmp_frontier_m2_11_strategy_frontier t
ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n FROM tmp_frontier_m2_11_strategy_frontier;
  IF v_n<>24 THEN RAISE EXCEPTION 'Frontier expected 24; found %',v_n; END IF;
  SELECT count(*) INTO v_n FROM
  (
    SELECT reporting_scope_code FROM tmp_frontier_m2_11_strategy_frontier
    WHERE primary_governance_review_flag GROUP BY reporting_scope_code HAVING count(*)>1
  ) x;
  IF v_n<>0 THEN RAISE EXCEPTION 'More than one primary governance review strategy in a scope'; END IF;
  SELECT count(*) INTO v_n FROM tmp_frontier_m2_11_strategy_frontier
  WHERE strategy_profile_code='BASELINE_REPLAY' AND governance_review_priority_code<>'CONTROL_REFERENCE';
  IF v_n<>0 THEN RAISE EXCEPTION 'Baseline frontier control-reference mismatch count %',v_n; END IF;
END;
$m211$;

/* ============================================================================
Section 12 — Baseline/challenger strategy comparisons
============================================================================ */
CREATE TEMP TABLE tmp_scope_comparison_joined ON COMMIT DROP AS
SELECT
  c.module1_run_id,c.reporting_scope_code,
  'BASELINE_REPLAY'::text AS baseline_strategy_profile_code,
  c.strategy_profile_code AS challenger_strategy_profile_code,
  b.row_hash AS baseline_summary_row_hash,c.row_hash AS challenger_summary_row_hash,
  bf.row_hash AS baseline_frontier_row_hash,cf.row_hash AS challenger_frontier_row_hash,
  b.access_rate AS baseline_access_rate,c.access_rate AS challenger_access_rate,
  b.selected_exposure_amount AS baseline_selected_exposure_amount,c.selected_exposure_amount AS challenger_selected_exposure_amount,
  b.finance_charge_amount AS baseline_finance_charge_amount,c.finance_charge_amount AS challenger_finance_charge_amount,
  b.expected_loss_density AS baseline_expected_loss_density,c.expected_loss_density AS challenger_expected_loss_density,
  b.risk_adjusted_contribution AS baseline_risk_adjusted_contribution,c.risk_adjusted_contribution AS challenger_risk_adjusted_contribution,
  b.annualized_risk_adjusted_return AS baseline_annualized_risk_adjusted_return,c.annualized_risk_adjusted_return AS challenger_annualized_risk_adjusted_return,
  b.servicing_burden_units AS baseline_servicing_burden_units,c.servicing_burden_units AS challenger_servicing_burden_units,
  b.payment_burden_rate AS baseline_payment_burden_rate,c.payment_burden_rate AS challenger_payment_burden_rate,
  bf.frontier_rank AS baseline_frontier_rank,cf.frontier_rank AS challenger_frontier_rank,
  bf.frontier_eligible_flag AS baseline_frontier_eligible_flag,cf.frontier_eligible_flag AS challenger_frontier_eligible_flag,
  cf.governance_review_priority_code AS challenger_governance_review_priority_code,
  c.stress_improvement_violation_count AS challenger_stress_improvement_violation_count,
  c.stress_nonimprovement_pass_flag AS challenger_stress_nonimprovement_pass_flag,
  c.stress_strategy_restriction_rows AS challenger_stress_strategy_restriction_rows,
  c.absolute_workload_reduction_rows AS challenger_absolute_workload_reduction_rows,
  c.hard_constraint_violation_count AS challenger_hard_constraint_violation_count,
  c.servicing_burden_coverage_code,c.new_access_servicing_burden_estimated_flag
FROM tmp_scope_m2_11_strategy_summary c
JOIN tmp_scope_m2_11_strategy_summary b
  ON b.module1_run_id=c.module1_run_id
 AND b.reporting_scope_code=c.reporting_scope_code
 AND b.strategy_profile_code='BASELINE_REPLAY'
JOIN tmp_frontier_m2_11_strategy_frontier cf
  ON cf.module1_run_id=c.module1_run_id
 AND cf.reporting_scope_code=c.reporting_scope_code
 AND cf.strategy_profile_code=c.strategy_profile_code
JOIN tmp_frontier_m2_11_strategy_frontier bf
  ON bf.module1_run_id=b.module1_run_id
 AND bf.reporting_scope_code=b.reporting_scope_code
 AND bf.strategy_profile_code=b.strategy_profile_code
WHERE c.strategy_profile_code<>'BASELINE_REPLAY';

CREATE UNIQUE INDEX tmp_scope_comparison_joined_u1
ON tmp_scope_comparison_joined(module1_run_id,challenger_strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_comparison_joined;

CREATE TEMP TABLE tmp_scope_comparison_final_projection ON COMMIT DROP AS
SELECT
    j.module1_run_id AS module1_run_id,
    j.reporting_scope_code AS reporting_scope_code,
    j.baseline_strategy_profile_code AS baseline_strategy_profile_code,
    j.challenger_strategy_profile_code AS challenger_strategy_profile_code,
    j.baseline_summary_row_hash AS baseline_summary_row_hash,
    j.challenger_summary_row_hash AS challenger_summary_row_hash,
    j.baseline_frontier_row_hash AS baseline_frontier_row_hash,
    j.challenger_frontier_row_hash AS challenger_frontier_row_hash,
    j.baseline_access_rate AS baseline_access_rate,
    j.challenger_access_rate AS challenger_access_rate,
    j.baseline_selected_exposure_amount AS baseline_selected_exposure_amount,
    j.challenger_selected_exposure_amount AS challenger_selected_exposure_amount,
    j.baseline_finance_charge_amount AS baseline_finance_charge_amount,
    j.challenger_finance_charge_amount AS challenger_finance_charge_amount,
    j.baseline_expected_loss_density AS baseline_expected_loss_density,
    j.challenger_expected_loss_density AS challenger_expected_loss_density,
    j.baseline_risk_adjusted_contribution AS baseline_risk_adjusted_contribution,
    j.challenger_risk_adjusted_contribution AS challenger_risk_adjusted_contribution,
    j.baseline_annualized_risk_adjusted_return AS baseline_annualized_risk_adjusted_return,
    j.challenger_annualized_risk_adjusted_return AS challenger_annualized_risk_adjusted_return,
    j.baseline_servicing_burden_units AS baseline_servicing_burden_units,
    j.challenger_servicing_burden_units AS challenger_servicing_burden_units,
    j.baseline_payment_burden_rate AS baseline_payment_burden_rate,
    j.challenger_payment_burden_rate AS challenger_payment_burden_rate,
    j.baseline_frontier_rank AS baseline_frontier_rank,
    j.challenger_frontier_rank AS challenger_frontier_rank,
    j.baseline_frontier_eligible_flag AS baseline_frontier_eligible_flag,
    j.challenger_frontier_eligible_flag AS challenger_frontier_eligible_flag,
    j.challenger_governance_review_priority_code AS challenger_governance_review_priority_code,
    j.challenger_stress_improvement_violation_count AS challenger_stress_improvement_violation_count,
    j.challenger_stress_nonimprovement_pass_flag AS challenger_stress_nonimprovement_pass_flag,
    j.challenger_stress_strategy_restriction_rows AS challenger_stress_strategy_restriction_rows,
    j.challenger_absolute_workload_reduction_rows AS challenger_absolute_workload_reduction_rows,
    j.challenger_hard_constraint_violation_count AS challenger_hard_constraint_violation_count,
    j.servicing_burden_coverage_code AS servicing_burden_coverage_code,
    j.new_access_servicing_burden_estimated_flag AS new_access_servicing_burden_estimated_flag,
    (j.challenger_access_rate-j.baseline_access_rate)::numeric(18,10) AS access_rate_delta,
    (j.challenger_selected_exposure_amount-j.baseline_selected_exposure_amount)::numeric(24,2) AS selected_exposure_amount_delta,
    (j.challenger_finance_charge_amount-j.baseline_finance_charge_amount)::numeric(24,2) AS finance_charge_amount_delta,
    CASE WHEN j.challenger_expected_loss_density IS NULL OR j.baseline_expected_loss_density IS NULL THEN NULL ELSE (j.challenger_expected_loss_density-j.baseline_expected_loss_density)::numeric(18,10) END AS expected_loss_density_delta,
    (j.challenger_risk_adjusted_contribution-j.baseline_risk_adjusted_contribution)::numeric(24,2) AS risk_adjusted_contribution_delta,
    CASE WHEN j.challenger_annualized_risk_adjusted_return IS NULL OR j.baseline_annualized_risk_adjusted_return IS NULL THEN NULL ELSE (j.challenger_annualized_risk_adjusted_return-j.baseline_annualized_risk_adjusted_return)::numeric(18,10) END AS annualized_risk_adjusted_return_delta,
    (j.challenger_servicing_burden_units-j.baseline_servicing_burden_units)::numeric(24,6) AS servicing_burden_units_delta,
    CASE WHEN j.challenger_payment_burden_rate IS NULL OR j.baseline_payment_burden_rate IS NULL THEN NULL ELSE (j.challenger_payment_burden_rate-j.baseline_payment_burden_rate)::numeric(18,10) END AS payment_burden_rate_delta
FROM tmp_scope_comparison_joined j
ORDER BY j.module1_run_id,j.reporting_scope_code,j.challenger_strategy_profile_code;

CREATE UNIQUE INDEX tmp_scope_comparison_final_u1 ON tmp_scope_comparison_final_projection(module1_run_id,challenger_strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_comparison_final_projection;

/* Target-type-before-hash projection for msbf_m2.portfolio_strategy_comparison. */
CREATE TEMP TABLE tmp_scope_m2_11_strategy_comparison ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_comparison WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_scope_m2_11_strategy_comparison') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_comparison'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_scope_m2_11_strategy_comparison versus msbf_m2.portfolio_strategy_comparison: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_scope_m2_11_strategy_comparison
(
    module1_run_id, reporting_scope_code, baseline_strategy_profile_code, challenger_strategy_profile_code,
    baseline_summary_row_hash, challenger_summary_row_hash, baseline_frontier_row_hash, challenger_frontier_row_hash,
    baseline_access_rate, challenger_access_rate, access_rate_delta, baseline_selected_exposure_amount,
    challenger_selected_exposure_amount, selected_exposure_amount_delta, baseline_finance_charge_amount, challenger_finance_charge_amount,
    finance_charge_amount_delta, baseline_expected_loss_density, challenger_expected_loss_density, expected_loss_density_delta,
    baseline_risk_adjusted_contribution, challenger_risk_adjusted_contribution, risk_adjusted_contribution_delta, baseline_annualized_risk_adjusted_return,
    challenger_annualized_risk_adjusted_return, annualized_risk_adjusted_return_delta, baseline_servicing_burden_units, challenger_servicing_burden_units,
    servicing_burden_units_delta, baseline_payment_burden_rate, challenger_payment_burden_rate, payment_burden_rate_delta,
    baseline_frontier_rank, challenger_frontier_rank, baseline_frontier_eligible_flag, challenger_frontier_eligible_flag,
    challenger_governance_review_priority_code, challenger_stress_improvement_violation_count, challenger_stress_nonimprovement_pass_flag, challenger_stress_strategy_restriction_rows,
    challenger_absolute_workload_reduction_rows, challenger_hard_constraint_violation_count, servicing_burden_coverage_code, new_access_servicing_burden_estimated_flag,
    row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.reporting_scope_code,
    p.baseline_strategy_profile_code,
    p.challenger_strategy_profile_code,
    p.baseline_summary_row_hash,
    p.challenger_summary_row_hash,
    p.baseline_frontier_row_hash,
    p.challenger_frontier_row_hash,
    p.baseline_access_rate,
    p.challenger_access_rate,
    p.access_rate_delta,
    p.baseline_selected_exposure_amount,
    p.challenger_selected_exposure_amount,
    p.selected_exposure_amount_delta,
    p.baseline_finance_charge_amount,
    p.challenger_finance_charge_amount,
    p.finance_charge_amount_delta,
    p.baseline_expected_loss_density,
    p.challenger_expected_loss_density,
    p.expected_loss_density_delta,
    p.baseline_risk_adjusted_contribution,
    p.challenger_risk_adjusted_contribution,
    p.risk_adjusted_contribution_delta,
    p.baseline_annualized_risk_adjusted_return,
    p.challenger_annualized_risk_adjusted_return,
    p.annualized_risk_adjusted_return_delta,
    p.baseline_servicing_burden_units,
    p.challenger_servicing_burden_units,
    p.servicing_burden_units_delta,
    p.baseline_payment_burden_rate,
    p.challenger_payment_burden_rate,
    p.payment_burden_rate_delta,
    p.baseline_frontier_rank,
    p.challenger_frontier_rank,
    p.baseline_frontier_eligible_flag,
    p.challenger_frontier_eligible_flag,
    p.challenger_governance_review_priority_code,
    p.challenger_stress_improvement_violation_count,
    p.challenger_stress_nonimprovement_pass_flag,
    p.challenger_stress_strategy_restriction_rows,
    p.challenger_absolute_workload_reduction_rows,
    p.challenger_hard_constraint_violation_count,
    p.servicing_burden_coverage_code,
    p.new_access_servicing_burden_estimated_flag,
    NULL::text,
    NULL::timestamptz
FROM tmp_scope_comparison_final_projection p
ORDER BY module1_run_id,reporting_scope_code,challenger_strategy_profile_code;

UPDATE tmp_scope_m2_11_strategy_comparison AS t
SET row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
    created_at=clock_timestamp();

-- Enforce the seven-challenger-by-three-scope comparison grain before the
-- comparison evidence is projected into the latest strategy contract.
CREATE UNIQUE INDEX tmp_scope_m2_11_strategy_comparison_u1
ON tmp_scope_m2_11_strategy_comparison
(module1_run_id,challenger_strategy_profile_code,reporting_scope_code);
ANALYZE tmp_scope_m2_11_strategy_comparison;

INSERT INTO msbf_m2.portfolio_strategy_comparison
(
    module1_run_id, reporting_scope_code, baseline_strategy_profile_code, challenger_strategy_profile_code,
    baseline_summary_row_hash, challenger_summary_row_hash, baseline_frontier_row_hash, challenger_frontier_row_hash,
    baseline_access_rate, challenger_access_rate, access_rate_delta, baseline_selected_exposure_amount,
    challenger_selected_exposure_amount, selected_exposure_amount_delta, baseline_finance_charge_amount, challenger_finance_charge_amount,
    finance_charge_amount_delta, baseline_expected_loss_density, challenger_expected_loss_density, expected_loss_density_delta,
    baseline_risk_adjusted_contribution, challenger_risk_adjusted_contribution, risk_adjusted_contribution_delta, baseline_annualized_risk_adjusted_return,
    challenger_annualized_risk_adjusted_return, annualized_risk_adjusted_return_delta, baseline_servicing_burden_units, challenger_servicing_burden_units,
    servicing_burden_units_delta, baseline_payment_burden_rate, challenger_payment_burden_rate, payment_burden_rate_delta,
    baseline_frontier_rank, challenger_frontier_rank, baseline_frontier_eligible_flag, challenger_frontier_eligible_flag,
    challenger_governance_review_priority_code, challenger_stress_improvement_violation_count, challenger_stress_nonimprovement_pass_flag, challenger_stress_strategy_restriction_rows,
    challenger_absolute_workload_reduction_rows, challenger_hard_constraint_violation_count, servicing_burden_coverage_code, new_access_servicing_burden_estimated_flag,
    row_hash, created_at
)
SELECT
    t.module1_run_id,
    t.reporting_scope_code,
    t.baseline_strategy_profile_code,
    t.challenger_strategy_profile_code,
    t.baseline_summary_row_hash,
    t.challenger_summary_row_hash,
    t.baseline_frontier_row_hash,
    t.challenger_frontier_row_hash,
    t.baseline_access_rate,
    t.challenger_access_rate,
    t.access_rate_delta,
    t.baseline_selected_exposure_amount,
    t.challenger_selected_exposure_amount,
    t.selected_exposure_amount_delta,
    t.baseline_finance_charge_amount,
    t.challenger_finance_charge_amount,
    t.finance_charge_amount_delta,
    t.baseline_expected_loss_density,
    t.challenger_expected_loss_density,
    t.expected_loss_density_delta,
    t.baseline_risk_adjusted_contribution,
    t.challenger_risk_adjusted_contribution,
    t.risk_adjusted_contribution_delta,
    t.baseline_annualized_risk_adjusted_return,
    t.challenger_annualized_risk_adjusted_return,
    t.annualized_risk_adjusted_return_delta,
    t.baseline_servicing_burden_units,
    t.challenger_servicing_burden_units,
    t.servicing_burden_units_delta,
    t.baseline_payment_burden_rate,
    t.challenger_payment_burden_rate,
    t.payment_burden_rate_delta,
    t.baseline_frontier_rank,
    t.challenger_frontier_rank,
    t.baseline_frontier_eligible_flag,
    t.challenger_frontier_eligible_flag,
    t.challenger_governance_review_priority_code,
    t.challenger_stress_improvement_violation_count,
    t.challenger_stress_nonimprovement_pass_flag,
    t.challenger_stress_strategy_restriction_rows,
    t.challenger_absolute_workload_reduction_rows,
    t.challenger_hard_constraint_violation_count,
    t.servicing_burden_coverage_code,
    t.new_access_servicing_burden_estimated_flag,
    t.row_hash,
    t.created_at
FROM tmp_scope_m2_11_strategy_comparison t
ORDER BY module1_run_id,reporting_scope_code,challenger_strategy_profile_code;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n FROM tmp_scope_m2_11_strategy_comparison;
  IF v_n<>21 THEN RAISE EXCEPTION 'Baseline/challenger comparison expected 21; found %',v_n; END IF;
END;
$m211$;

/* ============================================================================
Section 13 — Version-1 latest strategy-and-scope contract
============================================================================ */
CREATE TEMP TABLE tmp_latest_contract_joined ON COMMIT DROP AS
SELECT s.*,f.governance_balance_score,f.frontier_eligible_flag,
       f.non_dominated_flag,f.frontier_rank,f.governance_review_priority_code,
       f.primary_governance_review_flag,f.primary_reason_code AS frontier_primary_reason_code,
       f.reason_codes AS frontier_reason_codes,f.row_hash AS frontier_row_hash,
       c.access_rate_delta,c.selected_exposure_amount_delta,c.finance_charge_amount_delta,
       c.expected_loss_density_delta,c.risk_adjusted_contribution_delta,
       c.annualized_risk_adjusted_return_delta,c.servicing_burden_units_delta,
       c.payment_burden_rate_delta,c.row_hash AS comparison_row_hash
FROM tmp_scope_m2_11_strategy_summary s
JOIN tmp_frontier_m2_11_strategy_frontier f
  USING(module1_run_id,strategy_profile_code,reporting_scope_code)
LEFT JOIN tmp_scope_m2_11_strategy_comparison c
  ON c.module1_run_id=s.module1_run_id
 AND c.reporting_scope_code=s.reporting_scope_code
 AND c.challenger_strategy_profile_code=s.strategy_profile_code;

CREATE UNIQUE INDEX tmp_latest_contract_joined_u1
ON tmp_latest_contract_joined(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_latest_contract_joined;

CREATE TEMP TABLE tmp_latest_contract_projection ON COMMIT DROP AS
SELECT
    j.module1_run_id AS module1_run_id,
    'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AS contract_code,
    1 AS contract_version,
    'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1' AS schema_version,
    'M2_11_METHOD_V1' AS methodology_version,
    j.strategy_profile_code AS strategy_profile_code,
    j.reporting_scope_code AS reporting_scope_code,
    'M1_G2_CONSUMPTION_BUNDLE' AS source_m1_17_contract_code,
    1 AS source_m1_17_contract_version,
    'M1_G2_BUNDLE_SCHEMA_V1' AS source_m1_17_schema_version,
    'M1_17_METHOD_V1' AS source_m1_17_methodology_version,
    '7d9e466da28cad2551aa99c4c40c912b' AS source_m1_17_combined_hash,
    'M2_PRICING_STRUCTURE_CONSUMPTION' AS source_m2_2_contract_code,
    1 AS source_m2_2_contract_version,
    'M2_2_PRICING_STRUCTURE_SCHEMA_V1' AS source_m2_2_schema_version,
    'M2_2_METHOD_V1' AS source_m2_2_methodology_version,
    'bbe83b187b31ea561789797322031fc6' AS source_m2_2_combined_hash,
    'M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AS source_m2_4_contract_code,
    1 AS source_m2_4_contract_version,
    'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1' AS source_m2_4_schema_version,
    'M2_4_METHOD_V1' AS source_m2_4_methodology_version,
    '117450a3eea7bb3d3c74d18cc3c8e96a' AS source_m2_4_combined_hash,
    'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AS source_m2_7_contract_code,
    1 AS source_m2_7_contract_version,
    'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1' AS source_m2_7_schema_version,
    'M2_7_METHOD_V1' AS source_m2_7_methodology_version,
    'c8e3a472afd2a16b1183677324e9db98' AS source_m2_7_combined_hash,
    'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AS source_m2_10_contract_code,
    1 AS source_m2_10_contract_version,
    'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1' AS source_m2_10_schema_version,
    'M2_10_METHOD_V1' AS source_m2_10_methodology_version,
    '24fca7263a04397ebf21d30639f9069b' AS source_m2_10_combined_hash,
    j.application_rows AS application_rows,
    j.access_selected_rows AS access_selected_rows,
    j.controlled_review_rows AS controlled_review_rows,
    j.strategy_restriction_rows AS strategy_restriction_rows,
    j.no_feasible_candidate_rows AS no_feasible_candidate_rows,
    j.insufficient_evidence_rows AS insufficient_evidence_rows,
    j.policy_decline_rows AS policy_decline_rows,
    j.blocked_source_rows AS blocked_source_rows,
    j.servicing_account_rows AS servicing_account_rows,
    j.servicing_distinct_application_rows AS servicing_distinct_application_rows,
    j.hard_constraint_violation_count AS hard_constraint_violation_count,
    j.source_risk_improvement_violation_count AS source_risk_improvement_violation_count,
    j.source_return_improvement_violation_count AS source_return_improvement_violation_count,
    j.strategy_access_improvement_violation_count AS strategy_access_improvement_violation_count,
    j.strategy_feasibility_improvement_violation_count AS strategy_feasibility_improvement_violation_count,
    j.comparable_payment_burden_improvement_violation_count AS comparable_payment_burden_improvement_violation_count,
    j.comparable_servicing_burden_improvement_violation_count AS comparable_servicing_burden_improvement_violation_count,
    j.stress_improvement_violation_count AS stress_improvement_violation_count,
    j.stress_strategy_restriction_rows AS stress_strategy_restriction_rows,
    j.absolute_workload_reduction_rows AS absolute_workload_reduction_rows,
    j.access_rate AS access_rate,
    j.selected_exposure_amount AS selected_exposure_amount,
    j.finance_charge_amount AS finance_charge_amount,
    j.expected_loss_amount AS expected_loss_amount,
    j.expected_loss_density AS expected_loss_density,
    j.risk_adjusted_contribution AS risk_adjusted_contribution,
    j.annualized_risk_adjusted_return AS annualized_risk_adjusted_return,
    j.servicing_burden_units AS servicing_burden_units,
    j.payment_burden_rate AS payment_burden_rate,
    j.scope_strategy_score AS scope_strategy_score,
    j.strategy_evidence_status AS strategy_evidence_status,
    j.stress_nonimprovement_pass_flag AS stress_nonimprovement_pass_flag,
    j.servicing_burden_coverage_code AS servicing_burden_coverage_code,
    j.new_access_servicing_burden_estimated_flag AS new_access_servicing_burden_estimated_flag,
    j.governance_balance_score AS governance_balance_score,
    j.frontier_eligible_flag AS frontier_eligible_flag,
    j.non_dominated_flag AS non_dominated_flag,
    j.frontier_rank AS frontier_rank,
    j.governance_review_priority_code AS governance_review_priority_code,
    j.primary_governance_review_flag AS primary_governance_review_flag,
    CASE WHEN j.strategy_profile_code='BASELINE_REPLAY' THEN 0::numeric(18,10) ELSE j.access_rate_delta END AS baseline_access_rate_delta,
    CASE WHEN j.strategy_profile_code='BASELINE_REPLAY' THEN 0::numeric(24,2) ELSE j.selected_exposure_amount_delta END AS baseline_selected_exposure_amount_delta,
    CASE WHEN j.strategy_profile_code='BASELINE_REPLAY' THEN 0::numeric(24,2) ELSE j.finance_charge_amount_delta END AS baseline_finance_charge_amount_delta,
    CASE WHEN j.strategy_profile_code='BASELINE_REPLAY' THEN CASE WHEN j.expected_loss_density IS NULL THEN NULL ELSE 0::numeric(18,10) END ELSE j.expected_loss_density_delta END AS baseline_expected_loss_density_delta,
    CASE WHEN j.strategy_profile_code='BASELINE_REPLAY' THEN 0::numeric(24,2) ELSE j.risk_adjusted_contribution_delta END AS baseline_risk_adjusted_contribution_delta,
    CASE WHEN j.strategy_profile_code='BASELINE_REPLAY' THEN CASE WHEN j.annualized_risk_adjusted_return IS NULL THEN NULL ELSE 0::numeric(18,10) END ELSE j.annualized_risk_adjusted_return_delta END AS baseline_annualized_risk_adjusted_return_delta,
    CASE WHEN j.strategy_profile_code='BASELINE_REPLAY' THEN 0::numeric(24,6) ELSE j.servicing_burden_units_delta END AS baseline_servicing_burden_units_delta,
    CASE WHEN j.strategy_profile_code='BASELINE_REPLAY' THEN CASE WHEN j.payment_burden_rate IS NULL THEN NULL ELSE 0::numeric(18,10) END ELSE j.payment_burden_rate_delta END AS baseline_payment_burden_rate_delta,
    j.frontier_primary_reason_code AS primary_reason_code,
    j.frontier_reason_codes AS reason_codes,
    j.row_hash AS strategy_summary_row_hash,
    j.frontier_row_hash AS frontier_row_hash,
    j.comparison_row_hash AS comparison_row_hash
FROM tmp_latest_contract_joined j
ORDER BY j.module1_run_id,j.reporting_scope_code,j.strategy_profile_code;

CREATE UNIQUE INDEX tmp_latest_contract_projection_u1 ON tmp_latest_contract_projection(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_latest_contract_projection;

/* Target-type-before-hash projection for msbf_m2.portfolio_strategy_simulation_latest. */
CREATE TEMP TABLE tmp_latest_m2_11_contract ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_simulation_latest WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_latest_m2_11_contract') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_simulation_latest'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_latest_m2_11_contract versus msbf_m2.portfolio_strategy_simulation_latest: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_latest_m2_11_contract
(
    module1_run_id, contract_code, contract_version, schema_version,
    methodology_version, strategy_profile_code, reporting_scope_code, source_m1_17_contract_code,
    source_m1_17_contract_version, source_m1_17_schema_version, source_m1_17_methodology_version, source_m1_17_combined_hash,
    source_m2_2_contract_code, source_m2_2_contract_version, source_m2_2_schema_version, source_m2_2_methodology_version,
    source_m2_2_combined_hash, source_m2_4_contract_code, source_m2_4_contract_version, source_m2_4_schema_version,
    source_m2_4_methodology_version, source_m2_4_combined_hash, source_m2_7_contract_code, source_m2_7_contract_version,
    source_m2_7_schema_version, source_m2_7_methodology_version, source_m2_7_combined_hash, source_m2_10_contract_code,
    source_m2_10_contract_version, source_m2_10_schema_version, source_m2_10_methodology_version, source_m2_10_combined_hash,
    application_rows, access_selected_rows, controlled_review_rows, strategy_restriction_rows,
    no_feasible_candidate_rows, insufficient_evidence_rows, policy_decline_rows, blocked_source_rows,
    servicing_account_rows, servicing_distinct_application_rows, hard_constraint_violation_count, source_risk_improvement_violation_count,
    source_return_improvement_violation_count, strategy_access_improvement_violation_count, strategy_feasibility_improvement_violation_count, comparable_payment_burden_improvement_violation_count,
    comparable_servicing_burden_improvement_violation_count, stress_improvement_violation_count, stress_strategy_restriction_rows, absolute_workload_reduction_rows,
    access_rate, selected_exposure_amount, finance_charge_amount, expected_loss_amount,
    expected_loss_density, risk_adjusted_contribution, annualized_risk_adjusted_return, servicing_burden_units,
    payment_burden_rate, scope_strategy_score, governance_balance_score, strategy_evidence_status,
    stress_nonimprovement_pass_flag, frontier_eligible_flag, non_dominated_flag, frontier_rank,
    governance_review_priority_code, primary_governance_review_flag, servicing_burden_coverage_code, new_access_servicing_burden_estimated_flag,
    baseline_access_rate_delta, baseline_selected_exposure_amount_delta, baseline_finance_charge_amount_delta, baseline_expected_loss_density_delta,
    baseline_risk_adjusted_contribution_delta, baseline_annualized_risk_adjusted_return_delta, baseline_servicing_burden_units_delta, baseline_payment_burden_rate_delta,
    primary_reason_code, reason_codes, strategy_summary_row_hash, frontier_row_hash,
    comparison_row_hash, contract_row_hash, created_at
)
SELECT
    p.module1_run_id,
    p.contract_code,
    p.contract_version,
    p.schema_version,
    p.methodology_version,
    p.strategy_profile_code,
    p.reporting_scope_code,
    p.source_m1_17_contract_code,
    p.source_m1_17_contract_version,
    p.source_m1_17_schema_version,
    p.source_m1_17_methodology_version,
    p.source_m1_17_combined_hash,
    p.source_m2_2_contract_code,
    p.source_m2_2_contract_version,
    p.source_m2_2_schema_version,
    p.source_m2_2_methodology_version,
    p.source_m2_2_combined_hash,
    p.source_m2_4_contract_code,
    p.source_m2_4_contract_version,
    p.source_m2_4_schema_version,
    p.source_m2_4_methodology_version,
    p.source_m2_4_combined_hash,
    p.source_m2_7_contract_code,
    p.source_m2_7_contract_version,
    p.source_m2_7_schema_version,
    p.source_m2_7_methodology_version,
    p.source_m2_7_combined_hash,
    p.source_m2_10_contract_code,
    p.source_m2_10_contract_version,
    p.source_m2_10_schema_version,
    p.source_m2_10_methodology_version,
    p.source_m2_10_combined_hash,
    p.application_rows,
    p.access_selected_rows,
    p.controlled_review_rows,
    p.strategy_restriction_rows,
    p.no_feasible_candidate_rows,
    p.insufficient_evidence_rows,
    p.policy_decline_rows,
    p.blocked_source_rows,
    p.servicing_account_rows,
    p.servicing_distinct_application_rows,
    p.hard_constraint_violation_count,
    p.source_risk_improvement_violation_count,
    p.source_return_improvement_violation_count,
    p.strategy_access_improvement_violation_count,
    p.strategy_feasibility_improvement_violation_count,
    p.comparable_payment_burden_improvement_violation_count,
    p.comparable_servicing_burden_improvement_violation_count,
    p.stress_improvement_violation_count,
    p.stress_strategy_restriction_rows,
    p.absolute_workload_reduction_rows,
    p.access_rate,
    p.selected_exposure_amount,
    p.finance_charge_amount,
    p.expected_loss_amount,
    p.expected_loss_density,
    p.risk_adjusted_contribution,
    p.annualized_risk_adjusted_return,
    p.servicing_burden_units,
    p.payment_burden_rate,
    p.scope_strategy_score,
    p.governance_balance_score,
    p.strategy_evidence_status,
    p.stress_nonimprovement_pass_flag,
    p.frontier_eligible_flag,
    p.non_dominated_flag,
    p.frontier_rank,
    p.governance_review_priority_code,
    p.primary_governance_review_flag,
    p.servicing_burden_coverage_code,
    p.new_access_servicing_burden_estimated_flag,
    p.baseline_access_rate_delta,
    p.baseline_selected_exposure_amount_delta,
    p.baseline_finance_charge_amount_delta,
    p.baseline_expected_loss_density_delta,
    p.baseline_risk_adjusted_contribution_delta,
    p.baseline_annualized_risk_adjusted_return_delta,
    p.baseline_servicing_burden_units_delta,
    p.baseline_payment_burden_rate_delta,
    p.primary_reason_code,
    p.reason_codes,
    p.strategy_summary_row_hash,
    p.frontier_row_hash,
    p.comparison_row_hash,
    NULL::text,
    NULL::timestamptz
FROM tmp_latest_contract_projection p
ORDER BY p.module1_run_id,p.reporting_scope_code,p.strategy_profile_code;

UPDATE tmp_latest_m2_11_contract AS t
SET contract_row_hash=msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'contract_row_hash'-'created_at'),
    created_at=clock_timestamp();

-- Enforce the frozen latest-contract grain before archive construction.
CREATE UNIQUE INDEX tmp_latest_m2_11_contract_u1
ON tmp_latest_m2_11_contract
(module1_run_id,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_latest_m2_11_contract;

INSERT INTO msbf_m2.portfolio_strategy_simulation_latest
(
    module1_run_id, contract_code, contract_version, schema_version,
    methodology_version, strategy_profile_code, reporting_scope_code, source_m1_17_contract_code,
    source_m1_17_contract_version, source_m1_17_schema_version, source_m1_17_methodology_version, source_m1_17_combined_hash,
    source_m2_2_contract_code, source_m2_2_contract_version, source_m2_2_schema_version, source_m2_2_methodology_version,
    source_m2_2_combined_hash, source_m2_4_contract_code, source_m2_4_contract_version, source_m2_4_schema_version,
    source_m2_4_methodology_version, source_m2_4_combined_hash, source_m2_7_contract_code, source_m2_7_contract_version,
    source_m2_7_schema_version, source_m2_7_methodology_version, source_m2_7_combined_hash, source_m2_10_contract_code,
    source_m2_10_contract_version, source_m2_10_schema_version, source_m2_10_methodology_version, source_m2_10_combined_hash,
    application_rows, access_selected_rows, controlled_review_rows, strategy_restriction_rows,
    no_feasible_candidate_rows, insufficient_evidence_rows, policy_decline_rows, blocked_source_rows,
    servicing_account_rows, servicing_distinct_application_rows, hard_constraint_violation_count, source_risk_improvement_violation_count,
    source_return_improvement_violation_count, strategy_access_improvement_violation_count, strategy_feasibility_improvement_violation_count, comparable_payment_burden_improvement_violation_count,
    comparable_servicing_burden_improvement_violation_count, stress_improvement_violation_count, stress_strategy_restriction_rows, absolute_workload_reduction_rows,
    access_rate, selected_exposure_amount, finance_charge_amount, expected_loss_amount,
    expected_loss_density, risk_adjusted_contribution, annualized_risk_adjusted_return, servicing_burden_units,
    payment_burden_rate, scope_strategy_score, governance_balance_score, strategy_evidence_status,
    stress_nonimprovement_pass_flag, frontier_eligible_flag, non_dominated_flag, frontier_rank,
    governance_review_priority_code, primary_governance_review_flag, servicing_burden_coverage_code, new_access_servicing_burden_estimated_flag,
    baseline_access_rate_delta, baseline_selected_exposure_amount_delta, baseline_finance_charge_amount_delta, baseline_expected_loss_density_delta,
    baseline_risk_adjusted_contribution_delta, baseline_annualized_risk_adjusted_return_delta, baseline_servicing_burden_units_delta, baseline_payment_burden_rate_delta,
    primary_reason_code, reason_codes, strategy_summary_row_hash, frontier_row_hash,
    comparison_row_hash, contract_row_hash, created_at
)
SELECT
    t.module1_run_id,
    t.contract_code,
    t.contract_version,
    t.schema_version,
    t.methodology_version,
    t.strategy_profile_code,
    t.reporting_scope_code,
    t.source_m1_17_contract_code,
    t.source_m1_17_contract_version,
    t.source_m1_17_schema_version,
    t.source_m1_17_methodology_version,
    t.source_m1_17_combined_hash,
    t.source_m2_2_contract_code,
    t.source_m2_2_contract_version,
    t.source_m2_2_schema_version,
    t.source_m2_2_methodology_version,
    t.source_m2_2_combined_hash,
    t.source_m2_4_contract_code,
    t.source_m2_4_contract_version,
    t.source_m2_4_schema_version,
    t.source_m2_4_methodology_version,
    t.source_m2_4_combined_hash,
    t.source_m2_7_contract_code,
    t.source_m2_7_contract_version,
    t.source_m2_7_schema_version,
    t.source_m2_7_methodology_version,
    t.source_m2_7_combined_hash,
    t.source_m2_10_contract_code,
    t.source_m2_10_contract_version,
    t.source_m2_10_schema_version,
    t.source_m2_10_methodology_version,
    t.source_m2_10_combined_hash,
    t.application_rows,
    t.access_selected_rows,
    t.controlled_review_rows,
    t.strategy_restriction_rows,
    t.no_feasible_candidate_rows,
    t.insufficient_evidence_rows,
    t.policy_decline_rows,
    t.blocked_source_rows,
    t.servicing_account_rows,
    t.servicing_distinct_application_rows,
    t.hard_constraint_violation_count,
    t.source_risk_improvement_violation_count,
    t.source_return_improvement_violation_count,
    t.strategy_access_improvement_violation_count,
    t.strategy_feasibility_improvement_violation_count,
    t.comparable_payment_burden_improvement_violation_count,
    t.comparable_servicing_burden_improvement_violation_count,
    t.stress_improvement_violation_count,
    t.stress_strategy_restriction_rows,
    t.absolute_workload_reduction_rows,
    t.access_rate,
    t.selected_exposure_amount,
    t.finance_charge_amount,
    t.expected_loss_amount,
    t.expected_loss_density,
    t.risk_adjusted_contribution,
    t.annualized_risk_adjusted_return,
    t.servicing_burden_units,
    t.payment_burden_rate,
    t.scope_strategy_score,
    t.governance_balance_score,
    t.strategy_evidence_status,
    t.stress_nonimprovement_pass_flag,
    t.frontier_eligible_flag,
    t.non_dominated_flag,
    t.frontier_rank,
    t.governance_review_priority_code,
    t.primary_governance_review_flag,
    t.servicing_burden_coverage_code,
    t.new_access_servicing_burden_estimated_flag,
    t.baseline_access_rate_delta,
    t.baseline_selected_exposure_amount_delta,
    t.baseline_finance_charge_amount_delta,
    t.baseline_expected_loss_density_delta,
    t.baseline_risk_adjusted_contribution_delta,
    t.baseline_annualized_risk_adjusted_return_delta,
    t.baseline_servicing_burden_units_delta,
    t.baseline_payment_burden_rate_delta,
    t.primary_reason_code,
    t.reason_codes,
    t.strategy_summary_row_hash,
    t.frontier_row_hash,
    t.comparison_row_hash,
    t.contract_row_hash,
    t.created_at
FROM tmp_latest_m2_11_contract t
ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n FROM tmp_latest_m2_11_contract;
  IF v_n<>24 THEN RAISE EXCEPTION 'Latest contract expected 24; found %',v_n; END IF;
END;
$m211$;

/* ============================================================================
Section 14 — Immutable archive, exact latest payload reproduction
============================================================================ */
/* Target-type archive payload and identity before archive hashing. */
CREATE TEMP TABLE tmp_archive_m2_11_contract ON COMMIT DROP AS
SELECT * FROM msbf_m2.portfolio_strategy_simulation_archive WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_archive_m2_11_contract') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_m2.portfolio_strategy_simulation_archive'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_archive_m2_11_contract versus msbf_m2.portfolio_strategy_simulation_archive: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_archive_m2_11_contract
(
    module1_run_id, contract_code, contract_version, schema_version,
    methodology_version, strategy_profile_code, reporting_scope_code, contract_payload,
    contract_row_hash, archive_row_hash, archived_at, created_at
)
SELECT
    l.module1_run_id,
    l.contract_code,
    l.contract_version,
    l.schema_version,
    l.methodology_version,
    l.strategy_profile_code,
    l.reporting_scope_code,
    to_jsonb(l)-'created_at' AS contract_payload,
    l.contract_row_hash,
    NULL::text,
    clock_timestamp(),
    NULL::timestamptz
FROM tmp_latest_m2_11_contract l
ORDER BY l.module1_run_id,l.reporting_scope_code,l.strategy_profile_code;

UPDATE tmp_archive_m2_11_contract AS t
SET archive_row_hash=msbf_ctl.m2_11_hash_jsonb
(
  jsonb_build_object(
    'module1_run_id',t.module1_run_id,
    'contract_code',t.contract_code,
    'contract_version',t.contract_version,
    'strategy_profile_code',t.strategy_profile_code,
    'reporting_scope_code',t.reporting_scope_code,
    'contract_payload',t.contract_payload,
    'source_latest_row_hash',t.contract_row_hash
  )
),
    created_at=clock_timestamp();

-- Enforce immutable-version grain in the temporary archive construction
-- authority before the version-1 archive is persisted.
CREATE UNIQUE INDEX tmp_archive_m2_11_contract_u1
ON tmp_archive_m2_11_contract
(module1_run_id,contract_version,strategy_profile_code,reporting_scope_code);
ANALYZE tmp_archive_m2_11_contract;

INSERT INTO msbf_m2.portfolio_strategy_simulation_archive
(
    module1_run_id, contract_code, contract_version, schema_version,
    methodology_version, strategy_profile_code, reporting_scope_code, contract_payload,
    contract_row_hash, archive_row_hash, archived_at, created_at
)
SELECT
    t.module1_run_id,
    t.contract_code,
    t.contract_version,
    t.schema_version,
    t.methodology_version,
    t.strategy_profile_code,
    t.reporting_scope_code,
    t.contract_payload,
    t.contract_row_hash,
    t.archive_row_hash,
    t.archived_at,
    t.created_at
FROM tmp_archive_m2_11_contract t
ORDER BY module1_run_id,contract_version,reporting_scope_code,strategy_profile_code;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n FROM tmp_archive_m2_11_contract;
  IF v_n<>24 THEN RAISE EXCEPTION 'Archive contract expected 24; found %',v_n; END IF;
  SELECT count(*) INTO v_n
  FROM tmp_latest_m2_11_contract l
  FULL JOIN tmp_archive_m2_11_contract a
    ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version
   AND a.strategy_profile_code=l.strategy_profile_code AND a.reporting_scope_code=l.reporting_scope_code
  WHERE l.module1_run_id IS NULL OR a.module1_run_id IS NULL
     OR a.contract_row_hash<>l.contract_row_hash
     OR a.contract_payload<>(to_jsonb(l)-'created_at');
  IF v_n<>0 THEN RAISE EXCEPTION 'Latest/archive exact reproduction mismatch count %',v_n; END IF;
END;
$m211$;

/* AUDIT_MARKER: END_M2_11_CANONICAL_BUSINESS_CONSTRUCTION */
/* AUDIT_MARKER: BEGIN_M2_11_PERSISTED_RECONCILIATION
All business objects through latest and archive now exist. Persisted canonical
reads are permitted from this boundary only for ordered set hashes, independent
physical reconstruction, canonical counts, and final boundary checks.
============================================================================ */

/* ============================================================================
Section 15 — Explicitly ordered canonical object-set hashes
============================================================================ */
CREATE TEMP TABLE tmp_registry_object_set_hash
(
  catalog_sequence integer NOT NULL,
  object_code text NOT NULL,
  set_hash text NOT NULL,
  PRIMARY KEY(object_code)
) ON COMMIT DROP;

INSERT INTO tmp_registry_object_set_hash(catalog_sequence,object_code,set_hash) VALUES
(1,'msbf_ctl.m2_11_policy_profile',(SELECT md5(string_agg(configuration_hash,'|' ORDER BY module1_run_id)) FROM msbf_ctl.m2_11_policy_profile)),
(2,'msbf_m2.portfolio_strategy_profile',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_profile)),
(3,'msbf_m2.portfolio_strategy_objective_definition',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,objective_code)) FROM msbf_m2.portfolio_strategy_objective_definition)),
(4,'msbf_m2.portfolio_strategy_constraint_definition',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,constraint_code)) FROM msbf_m2.portfolio_strategy_constraint_definition)),
(5,'msbf_m2.portfolio_strategy_reason_definition',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,reason_code)) FROM msbf_m2.portfolio_strategy_reason_definition)),
(6,'msbf_m2.portfolio_strategy_application_source_snapshot',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scenario_id,merchant_application_id)) FROM msbf_m2.portfolio_strategy_application_source_snapshot)),
(7,'msbf_m2.portfolio_strategy_candidate_source_snapshot',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code)) FROM msbf_m2.portfolio_strategy_candidate_source_snapshot)),
(8,'msbf_m2.portfolio_strategy_account_source_snapshot',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scenario_id,merchant_application_id)) FROM msbf_m2.portfolio_strategy_account_source_snapshot)),
(9,'msbf_m2.portfolio_strategy_kpi_source_snapshot',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scope_code,kpi_code)) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot)),
(10,'msbf_m2.portfolio_strategy_queue_source_snapshot',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,servicing_queue_code)) FROM msbf_m2.portfolio_strategy_queue_source_snapshot)),
(11,'msbf_m2.application_strategy_candidate_evaluation',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code)) FROM msbf_m2.application_strategy_candidate_evaluation)),
(12,'msbf_m2.application_portfolio_strategy_simulation',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)) FROM msbf_m2.application_portfolio_strategy_simulation)),
(13,'msbf_m2.account_servicing_strategy_simulation',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)) FROM msbf_m2.account_servicing_strategy_simulation)),
(14,'msbf_m2.portfolio_strategy_summary',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_summary)),
(15,'msbf_m2.portfolio_strategy_frontier',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_frontier)),
(16,'msbf_m2.portfolio_strategy_comparison',(SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id,reporting_scope_code,challenger_strategy_profile_code)) FROM msbf_m2.portfolio_strategy_comparison)),
(17,'msbf_m2.portfolio_strategy_simulation_latest',(SELECT md5(string_agg(contract_row_hash,'|' ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_latest)),
(18,'msbf_m2.portfolio_strategy_simulation_archive',(SELECT md5(string_agg(archive_row_hash,'|' ORDER BY module1_run_id,contract_version,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_archive));

DO $m211$
BEGIN
  IF (SELECT count(*) FROM tmp_registry_object_set_hash)<>18
     OR EXISTS(SELECT 1 FROM tmp_registry_object_set_hash WHERE set_hash IS NULL OR set_hash!~'^[0-9a-f]{32}$') THEN
    RAISE EXCEPTION 'Pre-registry ordered set-hash construction failed';
  END IF;
END;
$m211$;

CREATE TEMP TABLE tmp_registry_core_projection ON COMMIT DROP AS
SELECT
    rr.run_id AS module1_run_id,
    'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AS contract_code,
    1 AS contract_version,
    'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1' AS schema_version,
    'M2_11_METHOD_V1' AS methodology_version,
    'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION' AS acceptance_gate_id,
    p.configuration_hash AS policy_configuration_hash,
    r17.bundle_code AS source_m1_17_contract_code,
    r17.bundle_version AS source_m1_17_contract_version,
    r17.schema_version AS source_m1_17_schema_version,
    r17.methodology_version AS source_m1_17_methodology_version,
    'G2_M1_CONTRACT' AS source_m1_17_acceptance_gate_id,
    r17.combined_g2_hash AS source_m1_17_combined_hash,
    r17.row_hash AS source_m1_17_registry_row_hash,
    r22.pricing_contract_code AS source_m2_2_contract_code,
    r22.pricing_contract_version AS source_m2_2_contract_version,
    r22.pricing_schema_version AS source_m2_2_schema_version,
    r22.methodology_version AS source_m2_2_methodology_version,
    'M2_2_PRICING_STRUCTURE_COUNTEROFFER' AS source_m2_2_acceptance_gate_id,
    r22.combined_set_hash AS source_m2_2_combined_hash,
    r22.row_hash AS source_m2_2_registry_row_hash,
    r24.contract_code AS source_m2_4_contract_code,
    r24.contract_version AS source_m2_4_contract_version,
    r24.schema_version AS source_m2_4_schema_version,
    r24.methodology_version AS source_m2_4_methodology_version,
    'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AS source_m2_4_acceptance_gate_id,
    r24.combined_set_hash AS source_m2_4_combined_hash,
    r24.row_hash AS source_m2_4_registry_row_hash,
    r27.contract_code AS source_m2_7_contract_code,
    r27.contract_version AS source_m2_7_contract_version,
    r27.schema_version AS source_m2_7_schema_version,
    r27.methodology_version AS source_m2_7_methodology_version,
    'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AS source_m2_7_acceptance_gate_id,
    r27.combined_set_hash AS source_m2_7_combined_hash,
    r27.row_hash AS source_m2_7_registry_row_hash,
    r210.contract_code AS source_m2_10_contract_code,
    r210.contract_version AS source_m2_10_contract_version,
    r210.schema_version AS source_m2_10_schema_version,
    r210.methodology_version AS source_m2_10_methodology_version,
    'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AS source_m2_10_acceptance_gate_id,
    r210.combined_set_hash AS source_m2_10_combined_hash,
    r210.row_hash AS source_m2_10_registry_row_hash,
    1::bigint AS policy_rows,
    8::bigint AS strategy_profile_rows,
    8::bigint AS objective_definition_rows,
    12::bigint AS constraint_definition_rows,
    32::bigint AS reason_definition_rows,
    1500::bigint AS application_source_rows,
    557::bigint AS candidate_source_rows,
    59::bigint AS account_source_rows,
    72::bigint AS kpi_source_rows,
    3::bigint AS queue_source_rows,
    4456::bigint AS candidate_evaluation_rows,
    12000::bigint AS application_simulation_rows,
    472::bigint AS account_simulation_rows,
    24::bigint AS strategy_summary_rows,
    24::bigint AS frontier_rows,
    21::bigint AS comparison_rows,
    24::bigint AS latest_rows,
    24::bigint AS archive_rows,
    1::bigint AS registry_rows,
    19298::bigint AS canonical_entities,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_ctl.m2_11_policy_profile') AS policy_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_profile') AS strategy_profile_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_objective_definition') AS objective_definition_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_constraint_definition') AS constraint_definition_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_reason_definition') AS reason_definition_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_application_source_snapshot') AS application_source_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_candidate_source_snapshot') AS candidate_source_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_account_source_snapshot') AS account_source_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_kpi_source_snapshot') AS kpi_source_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_queue_source_snapshot') AS queue_source_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.application_strategy_candidate_evaluation') AS candidate_evaluation_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.application_portfolio_strategy_simulation') AS application_simulation_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.account_servicing_strategy_simulation') AS account_simulation_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_summary') AS strategy_summary_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_frontier') AS frontier_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_comparison') AS comparison_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_simulation_latest') AS latest_set_hash,
    (SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_simulation_archive') AS archive_set_hash,
    md5((SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_simulation_latest')||'|'||(SELECT set_hash FROM tmp_registry_object_set_hash WHERE object_code='msbf_m2.portfolio_strategy_simulation_archive')) AS contract_set_hash,
    'GENERATED'::text AS contract_status
FROM tmp_src_run_registry rr
CROSS JOIN msbf_ctl.m2_11_policy_profile p
CROSS JOIN tmp_src_m1_17_g2_registry r17
CROSS JOIN tmp_src_m2_2_registry r22
CROSS JOIN tmp_src_m2_4_registry r24
CROSS JOIN tmp_src_m2_7_registry r27
CROSS JOIN tmp_src_m2_10_registry r210;

ANALYZE tmp_registry_core_projection;

CREATE TEMP TABLE tmp_registry_m2_11_contract ON COMMIT DROP AS
SELECT * FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry WITH NO DATA;

/* Fail closed unless the temporary projection exactly preserves target names, types, typmods and collations. */
DO $m211$
DECLARE
    v_bad bigint;
BEGIN
  SELECT count(*) INTO v_bad
  FROM
  (
    SELECT coalesce(x.attnum,t.attnum) AS attnum,x.attname AS temp_name,t.attname AS target_name,
           x.atttypid AS temp_type,t.atttypid AS target_type,x.atttypmod AS temp_typmod,t.atttypmod AS target_typmod,
           x.attcollation AS temp_collation,t.attcollation AS target_collation
    FROM
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid=to_regclass('pg_temp.tmp_registry_m2_11_contract') AND attnum>0 AND NOT attisdropped
    ) x
    FULL JOIN
    (
      SELECT attnum,attname,atttypid,atttypmod,attcollation FROM pg_attribute
      WHERE attrelid='msbf_ctl.m2_11_portfolio_strategy_contract_registry'::regclass AND attnum>0 AND NOT attisdropped
    ) t USING(attnum)
  ) d
  WHERE temp_name IS DISTINCT FROM target_name OR temp_type IS DISTINCT FROM target_type
     OR temp_typmod IS DISTINCT FROM target_typmod OR temp_collation IS DISTINCT FROM target_collation;
  IF v_bad<>0 THEN RAISE EXCEPTION 'Target-shape mismatch for pg_temp.tmp_registry_m2_11_contract versus msbf_ctl.m2_11_portfolio_strategy_contract_registry: % columns',v_bad; END IF;
END;
$m211$;

INSERT INTO tmp_registry_m2_11_contract
(
    registry_id,
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    acceptance_gate_id,
    policy_configuration_hash,
    source_m1_17_contract_code,
    source_m1_17_contract_version,
    source_m1_17_schema_version,
    source_m1_17_methodology_version,
    source_m1_17_acceptance_gate_id,
    source_m1_17_combined_hash,
    source_m1_17_registry_row_hash,
    source_m2_2_contract_code,
    source_m2_2_contract_version,
    source_m2_2_schema_version,
    source_m2_2_methodology_version,
    source_m2_2_acceptance_gate_id,
    source_m2_2_combined_hash,
    source_m2_2_registry_row_hash,
    source_m2_4_contract_code,
    source_m2_4_contract_version,
    source_m2_4_schema_version,
    source_m2_4_methodology_version,
    source_m2_4_acceptance_gate_id,
    source_m2_4_combined_hash,
    source_m2_4_registry_row_hash,
    source_m2_7_contract_code,
    source_m2_7_contract_version,
    source_m2_7_schema_version,
    source_m2_7_methodology_version,
    source_m2_7_acceptance_gate_id,
    source_m2_7_combined_hash,
    source_m2_7_registry_row_hash,
    source_m2_10_contract_code,
    source_m2_10_contract_version,
    source_m2_10_schema_version,
    source_m2_10_methodology_version,
    source_m2_10_acceptance_gate_id,
    source_m2_10_combined_hash,
    source_m2_10_registry_row_hash,
    policy_rows,
    strategy_profile_rows,
    objective_definition_rows,
    constraint_definition_rows,
    reason_definition_rows,
    application_source_rows,
    candidate_source_rows,
    account_source_rows,
    kpi_source_rows,
    queue_source_rows,
    candidate_evaluation_rows,
    application_simulation_rows,
    account_simulation_rows,
    strategy_summary_rows,
    frontier_rows,
    comparison_rows,
    latest_rows,
    archive_rows,
    registry_rows,
    canonical_entities,
    policy_set_hash,
    strategy_profile_set_hash,
    objective_definition_set_hash,
    constraint_definition_set_hash,
    reason_definition_set_hash,
    application_source_set_hash,
    candidate_source_set_hash,
    account_source_set_hash,
    kpi_source_set_hash,
    queue_source_set_hash,
    candidate_evaluation_set_hash,
    application_simulation_set_hash,
    account_simulation_set_hash,
    strategy_summary_set_hash,
    frontier_set_hash,
    comparison_set_hash,
    latest_set_hash,
    archive_set_hash,
    contract_set_hash,
    combined_set_hash,
    contract_status,
    generated_at,
    validated_at,
    accepted_at,
    row_hash,
    created_at
)
SELECT (jsonb_populate_record(
  NULL::msbf_ctl.m2_11_portfolio_strategy_contract_registry,
  to_jsonb(c)
)).*
FROM tmp_registry_core_projection c;

UPDATE tmp_registry_m2_11_contract AS t
SET row_hash=msbf_ctl.m2_11_registry_row_hash(to_jsonb(t));

CREATE TEMP TABLE tmp_registry_all_object_set_hash ON COMMIT DROP AS
SELECT * FROM tmp_registry_object_set_hash
UNION ALL
SELECT 19,'msbf_ctl.m2_11_portfolio_strategy_contract_registry',
       md5(string_agg(row_hash,'|' ORDER BY module1_run_id,contract_version))
FROM tmp_registry_m2_11_contract;

CREATE UNIQUE INDEX tmp_registry_all_object_set_hash_u1
ON tmp_registry_all_object_set_hash(object_code);
ANALYZE tmp_registry_all_object_set_hash;

UPDATE tmp_registry_m2_11_contract AS t
SET combined_set_hash=x.combined_set_hash,
    generated_at=clock_timestamp(),
    validated_at=NULL::timestamptz,
    accepted_at=NULL::timestamptz,
    created_at=clock_timestamp()
FROM
(
  SELECT md5(string_agg(object_code||'|'||set_hash,'|' ORDER BY catalog_sequence)) AS combined_set_hash
  FROM tmp_registry_all_object_set_hash
) x;
ANALYZE tmp_registry_m2_11_contract;

INSERT INTO msbf_ctl.m2_11_portfolio_strategy_contract_registry
(
    module1_run_id, contract_code, contract_version, schema_version,
    methodology_version, acceptance_gate_id, policy_configuration_hash, source_m1_17_contract_code,
    source_m1_17_contract_version, source_m1_17_schema_version, source_m1_17_methodology_version, source_m1_17_acceptance_gate_id,
    source_m1_17_combined_hash, source_m1_17_registry_row_hash, source_m2_2_contract_code, source_m2_2_contract_version,
    source_m2_2_schema_version, source_m2_2_methodology_version, source_m2_2_acceptance_gate_id, source_m2_2_combined_hash,
    source_m2_2_registry_row_hash, source_m2_4_contract_code, source_m2_4_contract_version, source_m2_4_schema_version,
    source_m2_4_methodology_version, source_m2_4_acceptance_gate_id, source_m2_4_combined_hash, source_m2_4_registry_row_hash,
    source_m2_7_contract_code, source_m2_7_contract_version, source_m2_7_schema_version, source_m2_7_methodology_version,
    source_m2_7_acceptance_gate_id, source_m2_7_combined_hash, source_m2_7_registry_row_hash, source_m2_10_contract_code,
    source_m2_10_contract_version, source_m2_10_schema_version, source_m2_10_methodology_version, source_m2_10_acceptance_gate_id,
    source_m2_10_combined_hash, source_m2_10_registry_row_hash, policy_rows, strategy_profile_rows,
    objective_definition_rows, constraint_definition_rows, reason_definition_rows, application_source_rows,
    candidate_source_rows, account_source_rows, kpi_source_rows, queue_source_rows,
    candidate_evaluation_rows, application_simulation_rows, account_simulation_rows, strategy_summary_rows,
    frontier_rows, comparison_rows, latest_rows, archive_rows,
    registry_rows, canonical_entities, policy_set_hash, strategy_profile_set_hash,
    objective_definition_set_hash, constraint_definition_set_hash, reason_definition_set_hash, application_source_set_hash,
    candidate_source_set_hash, account_source_set_hash, kpi_source_set_hash, queue_source_set_hash,
    candidate_evaluation_set_hash, application_simulation_set_hash, account_simulation_set_hash, strategy_summary_set_hash,
    frontier_set_hash, comparison_set_hash, latest_set_hash, archive_set_hash,
    contract_set_hash, combined_set_hash, contract_status, generated_at,
    validated_at, accepted_at, row_hash, created_at
)
SELECT
    t.module1_run_id,
    t.contract_code,
    t.contract_version,
    t.schema_version,
    t.methodology_version,
    t.acceptance_gate_id,
    t.policy_configuration_hash,
    t.source_m1_17_contract_code,
    t.source_m1_17_contract_version,
    t.source_m1_17_schema_version,
    t.source_m1_17_methodology_version,
    t.source_m1_17_acceptance_gate_id,
    t.source_m1_17_combined_hash,
    t.source_m1_17_registry_row_hash,
    t.source_m2_2_contract_code,
    t.source_m2_2_contract_version,
    t.source_m2_2_schema_version,
    t.source_m2_2_methodology_version,
    t.source_m2_2_acceptance_gate_id,
    t.source_m2_2_combined_hash,
    t.source_m2_2_registry_row_hash,
    t.source_m2_4_contract_code,
    t.source_m2_4_contract_version,
    t.source_m2_4_schema_version,
    t.source_m2_4_methodology_version,
    t.source_m2_4_acceptance_gate_id,
    t.source_m2_4_combined_hash,
    t.source_m2_4_registry_row_hash,
    t.source_m2_7_contract_code,
    t.source_m2_7_contract_version,
    t.source_m2_7_schema_version,
    t.source_m2_7_methodology_version,
    t.source_m2_7_acceptance_gate_id,
    t.source_m2_7_combined_hash,
    t.source_m2_7_registry_row_hash,
    t.source_m2_10_contract_code,
    t.source_m2_10_contract_version,
    t.source_m2_10_schema_version,
    t.source_m2_10_methodology_version,
    t.source_m2_10_acceptance_gate_id,
    t.source_m2_10_combined_hash,
    t.source_m2_10_registry_row_hash,
    t.policy_rows,
    t.strategy_profile_rows,
    t.objective_definition_rows,
    t.constraint_definition_rows,
    t.reason_definition_rows,
    t.application_source_rows,
    t.candidate_source_rows,
    t.account_source_rows,
    t.kpi_source_rows,
    t.queue_source_rows,
    t.candidate_evaluation_rows,
    t.application_simulation_rows,
    t.account_simulation_rows,
    t.strategy_summary_rows,
    t.frontier_rows,
    t.comparison_rows,
    t.latest_rows,
    t.archive_rows,
    t.registry_rows,
    t.canonical_entities,
    t.policy_set_hash,
    t.strategy_profile_set_hash,
    t.objective_definition_set_hash,
    t.constraint_definition_set_hash,
    t.reason_definition_set_hash,
    t.application_source_set_hash,
    t.candidate_source_set_hash,
    t.account_source_set_hash,
    t.kpi_source_set_hash,
    t.queue_source_set_hash,
    t.candidate_evaluation_set_hash,
    t.application_simulation_set_hash,
    t.account_simulation_set_hash,
    t.strategy_summary_set_hash,
    t.frontier_set_hash,
    t.comparison_set_hash,
    t.latest_set_hash,
    t.archive_set_hash,
    t.contract_set_hash,
    t.combined_set_hash,
    t.contract_status,
    t.generated_at,
    t.validated_at,
    t.accepted_at,
    t.row_hash,
    t.created_at
FROM tmp_registry_m2_11_contract t;

/* ============================================================================
Section 15A — Independent persisted-physical hash reconstruction before commit
This is the first physical reconstruction checkpoint. Stored row hashes are not
trusted as inputs to their own validation.
============================================================================ */
DO $m211$
DECLARE
    v_obj text;
    v_n bigint;
BEGIN
  FOREACH v_obj IN ARRAY ARRAY[
    'msbf_m2.portfolio_strategy_profile',
    'msbf_m2.portfolio_strategy_objective_definition',
    'msbf_m2.portfolio_strategy_constraint_definition',
    'msbf_m2.portfolio_strategy_reason_definition',
    'msbf_m2.portfolio_strategy_application_source_snapshot',
    'msbf_m2.portfolio_strategy_candidate_source_snapshot',
    'msbf_m2.portfolio_strategy_account_source_snapshot',
    'msbf_m2.portfolio_strategy_kpi_source_snapshot',
    'msbf_m2.portfolio_strategy_queue_source_snapshot',
    'msbf_m2.application_strategy_candidate_evaluation',
    'msbf_m2.application_portfolio_strategy_simulation',
    'msbf_m2.account_servicing_strategy_simulation',
    'msbf_m2.portfolio_strategy_summary',
    'msbf_m2.portfolio_strategy_frontier',
    'msbf_m2.portfolio_strategy_comparison'
  ] LOOP
    EXECUTE format(
      'SELECT count(*) FROM %s t WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-''row_hash''-''created_at'')',
      v_obj
    ) INTO v_n;
    IF v_n<>0 THEN
      RAISE EXCEPTION 'Program 214 persisted physical row-hash mismatch in %: % rows',v_obj,v_n;
    END IF;
  END LOOP;

  SELECT count(*) INTO v_n FROM msbf_ctl.m2_11_policy_profile t
  WHERE t.configuration_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(t.configuration_payload);
  IF v_n<>0 THEN RAISE EXCEPTION 'Program 214 policy configuration-hash mismatch count %',v_n; END IF;

  SELECT count(*) INTO v_n FROM msbf_m2.portfolio_strategy_simulation_latest t
  WHERE t.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'contract_row_hash'-'created_at');
  IF v_n<>0 THEN RAISE EXCEPTION 'Program 214 latest contract-row-hash mismatch count %',v_n; END IF;

  SELECT count(*) INTO v_n FROM msbf_m2.portfolio_strategy_simulation_archive t
  WHERE t.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(
    jsonb_build_object(
      'module1_run_id',t.module1_run_id,'contract_code',t.contract_code,
      'contract_version',t.contract_version,'strategy_profile_code',t.strategy_profile_code,
      'reporting_scope_code',t.reporting_scope_code,'contract_payload',t.contract_payload,
      'source_latest_row_hash',t.contract_row_hash
    )
  );
  IF v_n<>0 THEN RAISE EXCEPTION 'Program 214 archive-row-hash mismatch count %',v_n; END IF;

  SELECT count(*) INTO v_n FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry t
  WHERE t.row_hash IS DISTINCT FROM msbf_ctl.m2_11_registry_row_hash(to_jsonb(t));
  IF v_n<>0 THEN RAISE EXCEPTION 'Program 214 registry-row-hash mismatch count %',v_n; END IF;
END;
$m211$;

CREATE TEMP TABLE tmp_registry_reconstructed_set_hash
(
  catalog_sequence integer NOT NULL,
  object_code text NOT NULL,
  reconstructed_set_hash text NOT NULL,
  registry_field_name text,
  PRIMARY KEY(object_code)
) ON COMMIT DROP;

INSERT INTO tmp_registry_reconstructed_set_hash
(catalog_sequence,object_code,reconstructed_set_hash,registry_field_name)
VALUES
(1,'msbf_ctl.m2_11_policy_profile',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(configuration_payload),'|' ORDER BY module1_run_id)) FROM msbf_ctl.m2_11_policy_profile),'policy_set_hash'::text),
(2,'msbf_m2.portfolio_strategy_profile',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_profile t),'strategy_profile_set_hash'::text),
(3,'msbf_m2.portfolio_strategy_objective_definition',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,objective_code)) FROM msbf_m2.portfolio_strategy_objective_definition t),'objective_definition_set_hash'::text),
(4,'msbf_m2.portfolio_strategy_constraint_definition',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,constraint_code)) FROM msbf_m2.portfolio_strategy_constraint_definition t),'constraint_definition_set_hash'::text),
(5,'msbf_m2.portfolio_strategy_reason_definition',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,reason_code)) FROM msbf_m2.portfolio_strategy_reason_definition t),'reason_definition_set_hash'::text),
(6,'msbf_m2.portfolio_strategy_application_source_snapshot',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scenario_id,merchant_application_id)) FROM msbf_m2.portfolio_strategy_application_source_snapshot t),'application_source_set_hash'::text),
(7,'msbf_m2.portfolio_strategy_candidate_source_snapshot',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code)) FROM msbf_m2.portfolio_strategy_candidate_source_snapshot t),'candidate_source_set_hash'::text),
(8,'msbf_m2.portfolio_strategy_account_source_snapshot',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scenario_id,merchant_application_id)) FROM msbf_m2.portfolio_strategy_account_source_snapshot t),'account_source_set_hash'::text),
(9,'msbf_m2.portfolio_strategy_kpi_source_snapshot',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scope_code,kpi_code)) FROM msbf_m2.portfolio_strategy_kpi_source_snapshot t),'kpi_source_set_hash'::text),
(10,'msbf_m2.portfolio_strategy_queue_source_snapshot',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,servicing_queue_code)) FROM msbf_m2.portfolio_strategy_queue_source_snapshot t),'queue_source_set_hash'::text),
(11,'msbf_m2.application_strategy_candidate_evaluation',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,candidate_template_code,strategy_profile_code)) FROM msbf_m2.application_strategy_candidate_evaluation t),'candidate_evaluation_set_hash'::text),
(12,'msbf_m2.application_portfolio_strategy_simulation',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)) FROM msbf_m2.application_portfolio_strategy_simulation t),'application_simulation_set_hash'::text),
(13,'msbf_m2.account_servicing_strategy_simulation',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,scenario_id,merchant_application_id,strategy_profile_code)) FROM msbf_m2.account_servicing_strategy_simulation t),'account_simulation_set_hash'::text),
(14,'msbf_m2.portfolio_strategy_summary',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_summary t),'strategy_summary_set_hash'::text),
(15,'msbf_m2.portfolio_strategy_frontier',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_frontier t),'frontier_set_hash'::text),
(16,'msbf_m2.portfolio_strategy_comparison',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),'|' ORDER BY module1_run_id,reporting_scope_code,challenger_strategy_profile_code)) FROM msbf_m2.portfolio_strategy_comparison t),'comparison_set_hash'::text),
(17,'msbf_m2.portfolio_strategy_simulation_latest',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'contract_row_hash'-'created_at'),'|' ORDER BY module1_run_id,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_latest t),'latest_set_hash'::text),
(18,'msbf_m2.portfolio_strategy_simulation_archive',(SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(jsonb_build_object('module1_run_id',t.module1_run_id,'contract_code',t.contract_code,'contract_version',t.contract_version,'strategy_profile_code',t.strategy_profile_code,'reporting_scope_code',t.reporting_scope_code,'contract_payload',t.contract_payload,'source_latest_row_hash',t.contract_row_hash)),'|' ORDER BY module1_run_id,contract_version,reporting_scope_code,strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_archive t),'archive_set_hash'::text),
(19,'msbf_ctl.m2_11_portfolio_strategy_contract_registry',(SELECT md5(string_agg(msbf_ctl.m2_11_registry_row_hash(to_jsonb(t)),'|' ORDER BY module1_run_id,contract_version)) FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry t),NULL::text);

DO $m211$
DECLARE
    v_n bigint;
    v_contract_hash text;
    v_combined_hash text;
BEGIN
  IF (SELECT count(*) FROM tmp_registry_reconstructed_set_hash)<>19
     OR EXISTS(SELECT 1 FROM tmp_registry_reconstructed_set_hash WHERE reconstructed_set_hash!~'^[0-9a-f]{32}$') THEN
    RAISE EXCEPTION 'Program 214 reconstructed set-hash inventory is incomplete or malformed';
  END IF;

  SELECT count(*) INTO v_n
  FROM tmp_registry_reconstructed_set_hash h
  CROSS JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry r
  WHERE h.registry_field_name IS NOT NULL
    AND (to_jsonb(r)->>h.registry_field_name) IS DISTINCT FROM h.reconstructed_set_hash;
  IF v_n<>0 THEN RAISE EXCEPTION 'Program 214 persisted registry set-hash mismatch count %',v_n; END IF;

  SELECT md5(
    (SELECT reconstructed_set_hash FROM tmp_registry_reconstructed_set_hash WHERE object_code='msbf_m2.portfolio_strategy_simulation_latest')
    ||'|'||
    (SELECT reconstructed_set_hash FROM tmp_registry_reconstructed_set_hash WHERE object_code='msbf_m2.portfolio_strategy_simulation_archive')
  ) INTO v_contract_hash;
  IF v_contract_hash IS DISTINCT FROM (SELECT contract_set_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry) THEN
    RAISE EXCEPTION 'Program 214 reconstructed contract-set hash mismatch';
  END IF;

  SELECT md5(string_agg(object_code||'|'||reconstructed_set_hash,'|' ORDER BY catalog_sequence))
  INTO v_combined_hash
  FROM tmp_registry_reconstructed_set_hash;
  IF v_combined_hash IS DISTINCT FROM (SELECT combined_set_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry) THEN
    RAISE EXCEPTION 'Program 214 reconstructed final combined hash mismatch';
  END IF;
END;
$m211$;

/* ============================================================================
Section 16 — Final physical, hash, boundary, and lifecycle reconciliation
============================================================================ */
DO $m211$
DECLARE
    v_n bigint;
    v_hash text;
BEGIN
  SELECT count(*) INTO v_n FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry;
  IF v_n<>1 THEN RAISE EXCEPTION 'M2.11 registry expected 1; found %',v_n; END IF;

  SELECT count(*) INTO v_n FROM msbf_m2.v_m2_11_canonical_entity_hash_source;
  IF v_n<>19298 THEN RAISE EXCEPTION 'M2.11 canonical count expected 19298; found %',v_n; END IF;

  SELECT count(*) INTO v_n
  FROM msbf_m2.v_m2_11_canonical_entity_hash_source
  WHERE row_hash!~'^[0-9a-f]{32}$';
  IF v_n<>0 THEN RAISE EXCEPTION 'Canonical row-hash shape failure count %',v_n; END IF;

  SELECT count(*) INTO v_n
  FROM msbf_m2.portfolio_strategy_application_source_snapshot
  WHERE real_funds_movement_flag OR external_notice_generation_authorized_flag
     OR external_notice_transmitted_flag OR production_adverse_action_notice_flag;
  IF v_n<>0 THEN RAISE EXCEPTION 'Persisted accepted-source snapshot violates non-production boundary: %',v_n; END IF;

  SELECT md5(string_agg(object_code||'|'||reconstructed_set_hash,'|' ORDER BY catalog_sequence))
  INTO v_hash
  FROM tmp_registry_reconstructed_set_hash;
  IF v_hash IS DISTINCT FROM (SELECT combined_set_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry) THEN
    RAISE EXCEPTION 'Canonical combined hash mismatch from exact typed business-key reconstruction: reconstructed %, registry %',v_hash,(SELECT combined_set_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry);
  END IF;

  SELECT count(*) INTO v_n FROM msbf_m2.portfolio_strategy_reason_definition
  WHERE production_action_flag OR external_system_update_flag OR merchant_contact_flag OR production_adverse_action_flag;
  IF v_n<>0 THEN RAISE EXCEPTION 'Non-production reason boundary violation count %',v_n; END IF;

  SELECT count(*) INTO v_n FROM msbf_m2.application_portfolio_strategy_simulation
  WHERE source_risk_improvement_violation_flag OR source_return_improvement_violation_flag
     OR strategy_access_improvement_violation_flag OR strategy_feasibility_improvement_violation_flag
     OR comparable_payment_burden_improvement_violation_flag OR comparable_servicing_burden_improvement_violation_flag;
  IF v_n<>0 THEN RAISE EXCEPTION 'Stress non-improvement violation count %',v_n; END IF;

  SELECT count(*) INTO v_n FROM msbf_m2.account_servicing_strategy_simulation
  WHERE strategy_profile_code<>'EARLY_INTERVENTION'
    AND (servicing_treatment_code<>'SOURCE_SERVICING_REPLAY'
      OR simulated_payment_factor IS DISTINCT FROM source_payment_factor
      OR simulated_exposure_amount IS DISTINCT FROM source_certified_exposure_amount
      OR incremental_servicing_burden_units<>0);
  IF v_n<>0 THEN RAISE EXCEPTION 'Seven-strategy servicing replay mismatch count %',v_n; END IF;
END;
$m211$;

INSERT INTO msbf_ctl.run_evidence
(
  run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
  metric_value_text,unit_code,status,interpretation
)
SELECT
  l.module1_run_id,
  'M2_11_GENERATION_'||l.reporting_scope_code||'_'||l.strategy_profile_code,
  l.reporting_scope_code||'|'||l.strategy_profile_code,
  'M2.11 generated strategy-and-scope contract row hash',
  NULL::numeric(24,10),l.contract_row_hash,'HASH','PASS',
  'Program 214 generated the governed strategy-and-scope row; this is generation evidence, not validation or acceptance.'
FROM msbf_m2.portfolio_strategy_simulation_latest l
ORDER BY l.reporting_scope_code,l.strategy_profile_code;

DO $m211$
DECLARE
    v_n bigint;
BEGIN
  SELECT count(*) INTO v_n FROM msbf_ctl.run_evidence
  WHERE run_id=(SELECT run_id FROM tmp_src_run_registry)
    AND evidence_code LIKE 'M2_11_GENERATION_%';
  IF v_n<>24 THEN RAISE EXCEPTION 'Generation evidence expected 24; found %',v_n; END IF;
END;
$m211$;

DO $m211$
DECLARE
    v_rows bigint;
    v_status text;
BEGIN
  UPDATE msbf_ctl.run_registry r
  SET run_status='M2_11_GENERATED',
      row_count=19298,
      source_snapshot_hash=c.combined_set_hash,
      started_at=coalesce(r.started_at,clock_timestamp()),
      completed_at=NULL,
      notes=concat_ws(E'\n',r.notes,'M2.11 finite governed strategy simulation generated; validation and acceptance remain pending.')
  FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
  WHERE r.run_id=c.module1_run_id
    AND r.run_id=(SELECT run_id FROM tmp_src_run_registry)
  RETURNING r.run_status INTO v_status;

  GET DIAGNOSTICS v_rows=ROW_COUNT;
  IF v_rows<>1 OR v_status<>'M2_11_GENERATED' THEN
    RAISE EXCEPTION 'Run lifecycle update expected one M2_11_GENERATED row; rows %, status %',v_rows,v_status;
  END IF;
END;
$m211$;

COMMIT;

SELECT
  c.module1_run_id AS run_id,
  'M2_11_GENERATED'::text AS run_status,
  c.contract_code,c.contract_version,c.schema_version,
  c.contract_status,c.canonical_entities,c.application_simulation_rows,
  c.candidate_evaluation_rows,c.account_simulation_rows,c.strategy_summary_rows,
  c.frontier_rows,c.comparison_rows,c.latest_rows,c.archive_rows,
  24::bigint AS generation_evidence_rows,c.combined_set_hash,
  'READY_FOR_POSITIVE_VALIDATION'::text AS next_governed_state,
  'NOT_VALIDATED'::text AS validation_status,
  'NOT_ACCEPTED'::text AS acceptance_status
FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
WHERE c.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
  AND c.contract_version=1
  AND c.contract_status='GENERATED'
ORDER BY c.generated_at DESC,c.module1_run_id DESC
LIMIT 1;
