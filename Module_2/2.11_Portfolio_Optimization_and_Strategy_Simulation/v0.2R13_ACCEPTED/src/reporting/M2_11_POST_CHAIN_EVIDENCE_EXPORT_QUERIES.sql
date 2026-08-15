/*
M2.11 post-chain evidence export queries
Correction: WP5_EVIDENCE_AND_LINEAGE_CORRECTION_R1

Execution boundary
------------------
- Execute only after Program 219 completes successfully.
- This file is not Program 220 and is not part of the normal 212–219 chain.
- It contains SELECT statements only. It performs no persistent DML or DDL.
- Run and export each labeled result separately using the governed filename in
  M2_11_EVIDENCE_EXPORT_CATALOG.csv.
- Required headers must be retained even when an expected-zero diagnostic is
  encountered elsewhere in the evidence chain.
*/

/* STATE_RUN_REGISTRY
Expected rows: 1
Output file: state_run_registry.csv
*/
WITH governed_run AS
(
    SELECT
        r.run_id,
        count(*) OVER ()::bigint AS governed_run_rows
    FROM msbf_ctl.run_registry r
    WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
      AND r.run_version = 1
)
SELECT
    r.run_id,
    r.run_code,
    r.run_version,
    r.module_code,
    r.run_type,
    r.population_id,
    r.scenario_id,
    r.parameter_set_id,
    r.policy_profile_id,
    r.strategy_profile_id,
    r.product_structure_profile_id,
    r.operating_model_profile_id,
    r.jurisdiction_profile_id,
    r.contract_id,
    r.as_of_date,
    r.run_status,
    r.started_at,
    r.completed_at,
    r.row_count,
    r.parameter_snapshot_hash,
    r.profile_snapshot_hash,
    r.source_snapshot_hash,
    r.code_version,
    r.notes,
    r.created_at
FROM msbf_ctl.run_registry r
JOIN governed_run g ON g.run_id = r.run_id
WHERE g.governed_run_rows = 1
  AND r.run_status = 'M2_11_ACCEPTED'
ORDER BY r.run_code, r.run_version;

/* STATE_M2_11_CONTRACT_REGISTRY
Expected rows: 1
Output file: state_m2_11_contract_registry.csv
*/
WITH governed_run AS
(
    SELECT
        r.run_id,
        count(*) OVER ()::bigint AS governed_run_rows
    FROM msbf_ctl.run_registry r
    WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
      AND r.run_version = 1
)
SELECT
    c.registry_id,
    c.module1_run_id,
    c.contract_code,
    c.contract_version,
    c.schema_version,
    c.methodology_version,
    c.acceptance_gate_id,
    c.policy_configuration_hash,
    c.source_m1_17_contract_code,
    c.source_m1_17_contract_version,
    c.source_m1_17_schema_version,
    c.source_m1_17_methodology_version,
    c.source_m1_17_acceptance_gate_id,
    c.source_m1_17_combined_hash,
    c.source_m1_17_registry_row_hash,
    c.source_m2_2_contract_code,
    c.source_m2_2_contract_version,
    c.source_m2_2_schema_version,
    c.source_m2_2_methodology_version,
    c.source_m2_2_acceptance_gate_id,
    c.source_m2_2_combined_hash,
    c.source_m2_2_registry_row_hash,
    c.source_m2_4_contract_code,
    c.source_m2_4_contract_version,
    c.source_m2_4_schema_version,
    c.source_m2_4_methodology_version,
    c.source_m2_4_acceptance_gate_id,
    c.source_m2_4_combined_hash,
    c.source_m2_4_registry_row_hash,
    c.source_m2_7_contract_code,
    c.source_m2_7_contract_version,
    c.source_m2_7_schema_version,
    c.source_m2_7_methodology_version,
    c.source_m2_7_acceptance_gate_id,
    c.source_m2_7_combined_hash,
    c.source_m2_7_registry_row_hash,
    c.source_m2_10_contract_code,
    c.source_m2_10_contract_version,
    c.source_m2_10_schema_version,
    c.source_m2_10_methodology_version,
    c.source_m2_10_acceptance_gate_id,
    c.source_m2_10_combined_hash,
    c.source_m2_10_registry_row_hash,
    c.policy_rows,
    c.strategy_profile_rows,
    c.objective_definition_rows,
    c.constraint_definition_rows,
    c.reason_definition_rows,
    c.application_source_rows,
    c.candidate_source_rows,
    c.account_source_rows,
    c.kpi_source_rows,
    c.queue_source_rows,
    c.candidate_evaluation_rows,
    c.application_simulation_rows,
    c.account_simulation_rows,
    c.strategy_summary_rows,
    c.frontier_rows,
    c.comparison_rows,
    c.latest_rows,
    c.archive_rows,
    c.registry_rows,
    c.canonical_entities,
    c.policy_set_hash,
    c.strategy_profile_set_hash,
    c.objective_definition_set_hash,
    c.constraint_definition_set_hash,
    c.reason_definition_set_hash,
    c.application_source_set_hash,
    c.candidate_source_set_hash,
    c.account_source_set_hash,
    c.kpi_source_set_hash,
    c.queue_source_set_hash,
    c.candidate_evaluation_set_hash,
    c.application_simulation_set_hash,
    c.account_simulation_set_hash,
    c.strategy_summary_set_hash,
    c.frontier_set_hash,
    c.comparison_set_hash,
    c.latest_set_hash,
    c.archive_set_hash,
    c.contract_set_hash,
    c.combined_set_hash,
    c.contract_status,
    c.generated_at,
    c.validated_at,
    c.accepted_at,
    c.row_hash,
    c.created_at
FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
JOIN governed_run g ON g.run_id = c.module1_run_id
WHERE g.governed_run_rows = 1
  AND c.contract_code = 'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
  AND c.contract_version = 1
  AND c.contract_status = 'ACCEPTED'
ORDER BY c.contract_code, c.contract_version;

/* STATE_RUN_EVIDENCE
Expected rows: 165 = 24 generation + 120 positive + 20 negative + 1 acceptance
Output file: state_run_evidence.csv
*/
WITH governed_run AS
(
    SELECT
        r.run_id,
        count(*) OVER ()::bigint AS governed_run_rows
    FROM msbf_ctl.run_registry r
    WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
      AND r.run_version = 1
)
SELECT
    e.run_id,
    e.evidence_code,
    e.segment_key,
    e.metric_name,
    e.metric_value_numeric,
    e.metric_value_text,
    e.unit_code,
    e.status,
    e.threshold_value_numeric,
    e.interpretation,
    e.created_at
FROM msbf_ctl.run_evidence e
JOIN governed_run g ON g.run_id = e.run_id
WHERE g.governed_run_rows = 1
  AND
  (
       e.evidence_code LIKE 'M2_11_GENERATION_%'
    OR e.evidence_code LIKE 'M2_11_POS_%'
    OR e.evidence_code LIKE 'M2_11_NEG_%'
    OR e.evidence_code = 'M2_11_ACCEPTANCE_SUMMARY'
  )
ORDER BY e.evidence_code, e.segment_key, e.metric_name, e.created_at;

/* STATE_ACCEPTANCE_GATE
Expected rows: 1
Output file: state_acceptance_gate.csv
*/
WITH governed_run AS
(
    SELECT
        r.run_id,
        count(*) OVER ()::bigint AS governed_run_rows
    FROM msbf_ctl.run_registry r
    WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
      AND r.run_version = 1
)
SELECT
    a.run_id,
    a.gate_id,
    a.review_version,
    a.result_status,
    a.observed_value,
    a.threshold_value,
    a.finding,
    a.residual_limitation,
    a.reviewer_role,
    a.reviewed_at
FROM msbf_ctl.acceptance_gate_result a
JOIN governed_run g ON g.run_id = a.run_id
WHERE g.governed_run_rows = 1
  AND a.gate_id = 'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
  AND a.review_version = 1
ORDER BY a.gate_id, a.review_version;

/* STATE_CANONICAL_HASH_SOURCE
Expected rows: 19,298
Output file: state_canonical_hash_source.csv
*/
WITH governed_run AS
(
    SELECT
        r.run_id,
        count(*) OVER ()::bigint AS governed_run_rows
    FROM msbf_ctl.run_registry r
    WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
      AND r.run_version = 1
)
SELECT
    h.catalog_sequence,
    h.object_code,
    h.business_key,
    h.row_hash
FROM msbf_m2.v_m2_11_canonical_entity_hash_source h
CROSS JOIN governed_run g
WHERE g.governed_run_rows = 1
  AND
  (
       h.business_key = g.run_id::text
    OR h.business_key LIKE g.run_id::text || '|%'
  )
ORDER BY h.catalog_sequence, h.object_code, h.business_key, h.row_hash;

/* STATE_LATEST
Expected rows: 24
Output file: state_latest.csv
*/
WITH governed_run AS
(
    SELECT
        r.run_id,
        count(*) OVER ()::bigint AS governed_run_rows
    FROM msbf_ctl.run_registry r
    WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
      AND r.run_version = 1
)
SELECT
    l.module1_run_id,
    l.contract_code,
    l.contract_version,
    l.schema_version,
    l.methodology_version,
    l.strategy_profile_code,
    l.reporting_scope_code,
    l.source_m1_17_contract_code,
    l.source_m1_17_contract_version,
    l.source_m1_17_schema_version,
    l.source_m1_17_methodology_version,
    l.source_m1_17_combined_hash,
    l.source_m2_2_contract_code,
    l.source_m2_2_contract_version,
    l.source_m2_2_schema_version,
    l.source_m2_2_methodology_version,
    l.source_m2_2_combined_hash,
    l.source_m2_4_contract_code,
    l.source_m2_4_contract_version,
    l.source_m2_4_schema_version,
    l.source_m2_4_methodology_version,
    l.source_m2_4_combined_hash,
    l.source_m2_7_contract_code,
    l.source_m2_7_contract_version,
    l.source_m2_7_schema_version,
    l.source_m2_7_methodology_version,
    l.source_m2_7_combined_hash,
    l.source_m2_10_contract_code,
    l.source_m2_10_contract_version,
    l.source_m2_10_schema_version,
    l.source_m2_10_methodology_version,
    l.source_m2_10_combined_hash,
    l.application_rows,
    l.access_selected_rows,
    l.controlled_review_rows,
    l.strategy_restriction_rows,
    l.no_feasible_candidate_rows,
    l.insufficient_evidence_rows,
    l.policy_decline_rows,
    l.blocked_source_rows,
    l.servicing_account_rows,
    l.servicing_distinct_application_rows,
    l.hard_constraint_violation_count,
    l.source_risk_improvement_violation_count,
    l.source_return_improvement_violation_count,
    l.strategy_access_improvement_violation_count,
    l.strategy_feasibility_improvement_violation_count,
    l.comparable_payment_burden_improvement_violation_count,
    l.comparable_servicing_burden_improvement_violation_count,
    l.stress_improvement_violation_count,
    l.stress_strategy_restriction_rows,
    l.absolute_workload_reduction_rows,
    l.access_rate,
    l.selected_exposure_amount,
    l.finance_charge_amount,
    l.expected_loss_amount,
    l.expected_loss_density,
    l.risk_adjusted_contribution,
    l.annualized_risk_adjusted_return,
    l.servicing_burden_units,
    l.payment_burden_rate,
    l.scope_strategy_score,
    l.governance_balance_score,
    l.strategy_evidence_status,
    l.stress_nonimprovement_pass_flag,
    l.frontier_eligible_flag,
    l.non_dominated_flag,
    l.frontier_rank,
    l.governance_review_priority_code,
    l.primary_governance_review_flag,
    l.servicing_burden_coverage_code,
    l.new_access_servicing_burden_estimated_flag,
    l.baseline_access_rate_delta,
    l.baseline_selected_exposure_amount_delta,
    l.baseline_finance_charge_amount_delta,
    l.baseline_expected_loss_density_delta,
    l.baseline_risk_adjusted_contribution_delta,
    l.baseline_annualized_risk_adjusted_return_delta,
    l.baseline_servicing_burden_units_delta,
    l.baseline_payment_burden_rate_delta,
    l.primary_reason_code,
    l.reason_codes,
    l.strategy_summary_row_hash,
    l.frontier_row_hash,
    l.comparison_row_hash,
    l.contract_row_hash,
    l.created_at
FROM msbf_m2.portfolio_strategy_simulation_latest l
JOIN governed_run g ON g.run_id = l.module1_run_id
WHERE g.governed_run_rows = 1
  AND l.contract_code = 'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
  AND l.contract_version = 1
ORDER BY
    CASE l.reporting_scope_code
        WHEN 'BASELINE' THEN 1
        WHEN 'RECESSION_ENERGY' THEN 2
        WHEN 'PORTFOLIO' THEN 3
        ELSE 99
    END,
    l.strategy_profile_code;

/* STATE_ARCHIVE
Expected rows: 24
Output file: state_archive.csv
*/
WITH governed_run AS
(
    SELECT
        r.run_id,
        count(*) OVER ()::bigint AS governed_run_rows
    FROM msbf_ctl.run_registry r
    WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
      AND r.run_version = 1
)
SELECT
    a.archive_id,
    a.module1_run_id,
    a.contract_code,
    a.contract_version,
    a.schema_version,
    a.methodology_version,
    a.strategy_profile_code,
    a.reporting_scope_code,
    a.contract_payload,
    a.contract_row_hash,
    a.archive_row_hash,
    a.archived_at,
    a.created_at
FROM msbf_m2.portfolio_strategy_simulation_archive a
JOIN governed_run g ON g.run_id = a.module1_run_id
WHERE g.governed_run_rows = 1
  AND a.contract_code = 'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
  AND a.contract_version = 1
ORDER BY
    CASE a.reporting_scope_code
        WHEN 'BASELINE' THEN 1
        WHEN 'RECESSION_ENERGY' THEN 2
        WHEN 'PORTFOLIO' THEN 3
        ELSE 99
    END,
    a.strategy_profile_code,
    a.archive_id;
