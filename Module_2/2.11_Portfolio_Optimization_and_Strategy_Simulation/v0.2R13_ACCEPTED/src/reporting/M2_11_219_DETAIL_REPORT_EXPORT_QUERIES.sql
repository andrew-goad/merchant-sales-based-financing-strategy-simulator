/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.11 — Portfolio Optimization & Strategy Simulation

Utility     : M2_11_219_DETAIL_REPORT_EXPORT_QUERIES.sql
Correction  : M2_11_LIVE_EXECUTION_PROGRAM_219_CONTEXT_PROJECTION_CORRECTION_R1
Package     : R13

Purpose
-------
Provide exactly twenty-four independently re-executable, persistent-state,
SELECT-only export queries corresponding one-for-one to Program 219 Result
Sets 01–24. These queries preserve the governed result-set identities,
projections, counts, order, and zero-row headers without depending on
transaction-local report relations.

This file is unnumbered, is not Program 220, is excluded from the normal
212–219 execution chain, and performs no persistent DML or DDL.

Execution
---------
Execute only after the normal Program 219 script completes successfully.
The file may be run as a complete script or each labeled query may be run
individually. Export each grid with headers using the cataloged filename.
============================================================================ */

/* Result Set 01 — Lifecycle and acceptance */
/* EXPORT_RESULT_SET: M2_11_DETAIL_01_LIFECYCLE_AND_ACCEPTANCE */
WITH governed_context AS
(
SELECT
    r.run_id,r.run_code,r.run_version,r.module_code,r.run_type,r.as_of_date,
    r.run_status,r.row_count,r.source_snapshot_hash,
    p.policy_profile_id,
    p.module1_run_id,
    p.policy_code,
    p.policy_version,
    p.methodology_version,
    p.contract_code,
    p.contract_version,
    p.schema_version,
    p.acceptance_gate_id,
    p.strategy_profile_rows AS policy_expected_strategy_profile_rows,
    p.objective_definition_rows AS policy_expected_objective_definition_rows,
    p.constraint_definition_rows AS policy_expected_constraint_definition_rows,
    p.reason_definition_rows AS policy_expected_reason_definition_rows,
    p.reporting_scope_count,
    p.application_source_rows AS policy_expected_application_source_rows,
    p.candidate_source_rows AS policy_expected_candidate_source_rows,
    p.account_source_rows AS policy_expected_account_source_rows,
    p.kpi_source_rows AS policy_expected_kpi_source_rows,
    p.queue_source_rows AS policy_expected_queue_source_rows,
    p.candidate_evaluation_rows AS policy_expected_candidate_evaluation_rows,
    p.application_simulation_rows AS policy_expected_application_simulation_rows,
    p.account_simulation_rows AS policy_expected_account_simulation_rows,
    p.strategy_summary_rows AS policy_expected_strategy_summary_rows,
    p.frontier_rows AS policy_expected_frontier_rows,
    p.comparison_rows AS policy_expected_comparison_rows,
    p.latest_rows AS policy_expected_latest_rows,
    p.archive_rows AS policy_expected_archive_rows,
    p.registry_rows AS policy_expected_registry_rows,
    p.canonical_entities AS policy_expected_canonical_entities,
    p.positive_controls,
    p.negative_controls,
    p.generation_evidence_rows,
    p.acceptance_evidence_rows,
    p.detail_result_sets,
    p.score_precision_scale,
    p.normalized_precision_scale,
    p.candidate_score_tolerance,
    p.synthetic_data_only_flag,
    p.non_production_boundary_flag,
    p.no_external_system_update_flag,
    p.no_merchant_contact_flag,
    p.no_real_funds_movement_flag,
    p.no_production_decisioning_flag,
    p.servicing_burden_coverage_code,
    p.new_access_servicing_burden_estimated_flag,
    p.configuration_payload,
    p.configuration_hash,
    p.policy_status,
    p.created_at,
    p.updated_at,
    c.registry_id,c.contract_status,c.generated_at,c.validated_at,c.accepted_at,
    c.source_m1_17_contract_code,c.source_m1_17_contract_version,
    c.source_m1_17_schema_version,c.source_m1_17_methodology_version,
    c.source_m1_17_acceptance_gate_id,c.source_m1_17_combined_hash,
    c.source_m1_17_registry_row_hash,
    c.source_m2_2_contract_code,c.source_m2_2_contract_version,
    c.source_m2_2_schema_version,c.source_m2_2_methodology_version,
    c.source_m2_2_acceptance_gate_id,c.source_m2_2_combined_hash,
    c.source_m2_2_registry_row_hash,
    c.source_m2_4_contract_code,c.source_m2_4_contract_version,
    c.source_m2_4_schema_version,c.source_m2_4_methodology_version,
    c.source_m2_4_acceptance_gate_id,c.source_m2_4_combined_hash,
    c.source_m2_4_registry_row_hash,
    c.source_m2_7_contract_code,c.source_m2_7_contract_version,
    c.source_m2_7_schema_version,c.source_m2_7_methodology_version,
    c.source_m2_7_acceptance_gate_id,c.source_m2_7_combined_hash,
    c.source_m2_7_registry_row_hash,
    c.source_m2_10_contract_code,c.source_m2_10_contract_version,
    c.source_m2_10_schema_version,c.source_m2_10_methodology_version,
    c.source_m2_10_acceptance_gate_id,c.source_m2_10_combined_hash,
    c.source_m2_10_registry_row_hash,
    c.policy_rows,c.strategy_profile_rows,c.objective_definition_rows,
    c.constraint_definition_rows,c.reason_definition_rows,
    c.application_source_rows,c.candidate_source_rows,c.account_source_rows,
    c.kpi_source_rows,c.queue_source_rows,c.candidate_evaluation_rows,
    c.application_simulation_rows,c.account_simulation_rows,
    c.strategy_summary_rows,c.frontier_rows,c.comparison_rows,c.latest_rows,
    c.archive_rows,c.registry_rows,c.canonical_entities,
    c.policy_set_hash,c.strategy_profile_set_hash,c.objective_definition_set_hash,
    c.constraint_definition_set_hash,c.reason_definition_set_hash,
    c.application_source_set_hash,c.candidate_source_set_hash,
    c.account_source_set_hash,c.kpi_source_set_hash,c.queue_source_set_hash,
    c.candidate_evaluation_set_hash,c.application_simulation_set_hash,
    c.account_simulation_set_hash,c.strategy_summary_set_hash,
    c.frontier_set_hash,c.comparison_set_hash,c.latest_set_hash,
    c.archive_set_hash,c.contract_set_hash,c.combined_set_hash,
    c.row_hash AS registry_row_hash,c.created_at AS registry_created_at,
    g.result_status AS gate_status,g.observed_value AS gate_observed_value,
    g.threshold_value AS gate_threshold_value,g.finding AS gate_finding,
    g.residual_limitation AS gate_residual_limitation,
    g.reviewer_role,g.reviewed_at AS gate_reviewed_at
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m2_11_policy_profile p ON p.module1_run_id=r.run_id
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry c
  ON c.module1_run_id=r.run_id AND c.contract_version=1
JOIN msbf_ctl.acceptance_gate_result g
  ON g.run_id=r.run_id
 AND g.gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
 AND g.review_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
  AND r.run_version=1
  AND r.run_status='M2_11_ACCEPTED'
  AND c.contract_status='ACCEPTED'
  AND g.result_status='PASS' 
)
SELECT
    'M2_11_DETAIL_01_LIFECYCLE_AND_ACCEPTANCE'::text AS result_set_code,
    run_id,run_code,run_version,module_code,run_type,as_of_date,run_status,
    contract_status,gate_status,generated_at,validated_at,accepted_at,
    gate_reviewed_at,reviewer_role,gate_observed_value,gate_threshold_value,
    gate_finding,gate_residual_limitation,
    (SELECT count(*) FROM msbf_ctl.run_evidence e
      WHERE e.run_id=c.run_id AND e.evidence_code='M2_11_ACCEPTANCE_SUMMARY'
        AND e.status='PASS') AS acceptance_evidence_rows,
    'FORMAL_ACCEPTANCE_IS_NOT_DEPLOYMENT_AUTHORIZATION'::text AS acceptance_interpretation,
    'NOT_AUTHORIZED'::text AS deployment_authorization_status,
    'M2_12_REQUIRED'::text AS module2_closure_status,
    'NOT_AUTHORIZED'::text AS module3_authorization_status
FROM governed_context c
ORDER BY run_code,run_version;

/* Result Set 02 — Policy and accepted-source lineage */
/* EXPORT_RESULT_SET: M2_11_DETAIL_02_POLICY_AND_SOURCE_LINEAGE */
WITH governed_context AS
(
SELECT
    r.run_id,r.run_code,r.run_version,r.module_code,r.run_type,r.as_of_date,
    r.run_status,r.row_count,r.source_snapshot_hash,
    p.policy_profile_id,
    p.module1_run_id,
    p.policy_code,
    p.policy_version,
    p.methodology_version,
    p.contract_code,
    p.contract_version,
    p.schema_version,
    p.acceptance_gate_id,
    p.strategy_profile_rows AS policy_expected_strategy_profile_rows,
    p.objective_definition_rows AS policy_expected_objective_definition_rows,
    p.constraint_definition_rows AS policy_expected_constraint_definition_rows,
    p.reason_definition_rows AS policy_expected_reason_definition_rows,
    p.reporting_scope_count,
    p.application_source_rows AS policy_expected_application_source_rows,
    p.candidate_source_rows AS policy_expected_candidate_source_rows,
    p.account_source_rows AS policy_expected_account_source_rows,
    p.kpi_source_rows AS policy_expected_kpi_source_rows,
    p.queue_source_rows AS policy_expected_queue_source_rows,
    p.candidate_evaluation_rows AS policy_expected_candidate_evaluation_rows,
    p.application_simulation_rows AS policy_expected_application_simulation_rows,
    p.account_simulation_rows AS policy_expected_account_simulation_rows,
    p.strategy_summary_rows AS policy_expected_strategy_summary_rows,
    p.frontier_rows AS policy_expected_frontier_rows,
    p.comparison_rows AS policy_expected_comparison_rows,
    p.latest_rows AS policy_expected_latest_rows,
    p.archive_rows AS policy_expected_archive_rows,
    p.registry_rows AS policy_expected_registry_rows,
    p.canonical_entities AS policy_expected_canonical_entities,
    p.positive_controls,
    p.negative_controls,
    p.generation_evidence_rows,
    p.acceptance_evidence_rows,
    p.detail_result_sets,
    p.score_precision_scale,
    p.normalized_precision_scale,
    p.candidate_score_tolerance,
    p.synthetic_data_only_flag,
    p.non_production_boundary_flag,
    p.no_external_system_update_flag,
    p.no_merchant_contact_flag,
    p.no_real_funds_movement_flag,
    p.no_production_decisioning_flag,
    p.servicing_burden_coverage_code,
    p.new_access_servicing_burden_estimated_flag,
    p.configuration_payload,
    p.configuration_hash,
    p.policy_status,
    p.created_at,
    p.updated_at,
    c.registry_id,c.contract_status,c.generated_at,c.validated_at,c.accepted_at,
    c.source_m1_17_contract_code,c.source_m1_17_contract_version,
    c.source_m1_17_schema_version,c.source_m1_17_methodology_version,
    c.source_m1_17_acceptance_gate_id,c.source_m1_17_combined_hash,
    c.source_m1_17_registry_row_hash,
    c.source_m2_2_contract_code,c.source_m2_2_contract_version,
    c.source_m2_2_schema_version,c.source_m2_2_methodology_version,
    c.source_m2_2_acceptance_gate_id,c.source_m2_2_combined_hash,
    c.source_m2_2_registry_row_hash,
    c.source_m2_4_contract_code,c.source_m2_4_contract_version,
    c.source_m2_4_schema_version,c.source_m2_4_methodology_version,
    c.source_m2_4_acceptance_gate_id,c.source_m2_4_combined_hash,
    c.source_m2_4_registry_row_hash,
    c.source_m2_7_contract_code,c.source_m2_7_contract_version,
    c.source_m2_7_schema_version,c.source_m2_7_methodology_version,
    c.source_m2_7_acceptance_gate_id,c.source_m2_7_combined_hash,
    c.source_m2_7_registry_row_hash,
    c.source_m2_10_contract_code,c.source_m2_10_contract_version,
    c.source_m2_10_schema_version,c.source_m2_10_methodology_version,
    c.source_m2_10_acceptance_gate_id,c.source_m2_10_combined_hash,
    c.source_m2_10_registry_row_hash,
    c.policy_rows,c.strategy_profile_rows,c.objective_definition_rows,
    c.constraint_definition_rows,c.reason_definition_rows,
    c.application_source_rows,c.candidate_source_rows,c.account_source_rows,
    c.kpi_source_rows,c.queue_source_rows,c.candidate_evaluation_rows,
    c.application_simulation_rows,c.account_simulation_rows,
    c.strategy_summary_rows,c.frontier_rows,c.comparison_rows,c.latest_rows,
    c.archive_rows,c.registry_rows,c.canonical_entities,
    c.policy_set_hash,c.strategy_profile_set_hash,c.objective_definition_set_hash,
    c.constraint_definition_set_hash,c.reason_definition_set_hash,
    c.application_source_set_hash,c.candidate_source_set_hash,
    c.account_source_set_hash,c.kpi_source_set_hash,c.queue_source_set_hash,
    c.candidate_evaluation_set_hash,c.application_simulation_set_hash,
    c.account_simulation_set_hash,c.strategy_summary_set_hash,
    c.frontier_set_hash,c.comparison_set_hash,c.latest_set_hash,
    c.archive_set_hash,c.contract_set_hash,c.combined_set_hash,
    c.row_hash AS registry_row_hash,c.created_at AS registry_created_at,
    g.result_status AS gate_status,g.observed_value AS gate_observed_value,
    g.threshold_value AS gate_threshold_value,g.finding AS gate_finding,
    g.residual_limitation AS gate_residual_limitation,
    g.reviewer_role,g.reviewed_at AS gate_reviewed_at
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m2_11_policy_profile p ON p.module1_run_id=r.run_id
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry c
  ON c.module1_run_id=r.run_id AND c.contract_version=1
JOIN msbf_ctl.acceptance_gate_result g
  ON g.run_id=r.run_id
 AND g.gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
 AND g.review_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
  AND r.run_version=1
  AND r.run_status='M2_11_ACCEPTED'
  AND c.contract_status='ACCEPTED'
  AND g.result_status='PASS' 
)
SELECT
    'M2_11_DETAIL_02_POLICY_AND_SOURCE_LINEAGE'::text AS result_set_code,
    run_id,policy_code,policy_version,policy_status,methodology_version,
    contract_code,contract_version,schema_version,acceptance_gate_id,
    configuration_hash,synthetic_data_only_flag,non_production_boundary_flag,
    no_external_system_update_flag,no_merchant_contact_flag,
    no_real_funds_movement_flag,no_production_decisioning_flag,
    servicing_burden_coverage_code,new_access_servicing_burden_estimated_flag,
    source_m1_17_contract_code,source_m1_17_contract_version,
    source_m1_17_schema_version,source_m1_17_methodology_version,
    source_m1_17_acceptance_gate_id,source_m1_17_combined_hash,
    source_m1_17_registry_row_hash,
    source_m2_2_contract_code,source_m2_2_contract_version,
    source_m2_2_schema_version,source_m2_2_methodology_version,
    source_m2_2_acceptance_gate_id,source_m2_2_combined_hash,
    source_m2_2_registry_row_hash,
    source_m2_4_contract_code,source_m2_4_contract_version,
    source_m2_4_schema_version,source_m2_4_methodology_version,
    source_m2_4_acceptance_gate_id,source_m2_4_combined_hash,
    source_m2_4_registry_row_hash,
    source_m2_7_contract_code,source_m2_7_contract_version,
    source_m2_7_schema_version,source_m2_7_methodology_version,
    source_m2_7_acceptance_gate_id,source_m2_7_combined_hash,
    source_m2_7_registry_row_hash,
    source_m2_10_contract_code,source_m2_10_contract_version,
    source_m2_10_schema_version,source_m2_10_methodology_version,
    source_m2_10_acceptance_gate_id,source_m2_10_combined_hash,
    source_m2_10_registry_row_hash,
    'FIVE_ACCEPTED_SOURCE_FAMILIES_ONLY'::text AS source_boundary,
    'NO_DIRECT_M2_3_M2_5_M2_6_M2_8_M2_9_BUSINESS_READS'::text AS prohibited_direct_source_boundary
FROM governed_context
ORDER BY run_id;

/* Result Set 03 — Strategy definitions */
/* EXPORT_RESULT_SET: M2_11_DETAIL_03_STRATEGY_DEFINITIONS */
SELECT
    'M2_11_DETAIL_03_STRATEGY_DEFINITIONS'::text AS result_set_code,
    s.module1_run_id,
    s.strategy_profile_code,
    s.strategy_sequence,
    s.strategy_name,
    s.selection_mode,
    s.selected_exposure_direction,
    s.access_rate_weight,
    s.selected_exposure_weight,
    s.finance_charge_weight,
    s.expected_loss_density_weight,
    s.risk_adjusted_contribution_weight,
    s.annualized_return_weight,
    s.servicing_burden_weight,
    s.payment_burden_weight,
    s.candidate_domain_weight_total,
    s.scope_domain_weight_total,
    s.candidate_scoring_applicable_flag,
    s.scope_scoring_applicable_flag,
    s.evidence_handling_code,
    s.score_precision_scale,
    s.active_flag,
    s.description,
    s.row_hash,
    s.created_at
FROM msbf_m2.portfolio_strategy_profile s
WHERE s.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY s.strategy_sequence,s.strategy_profile_code;

/* Result Set 04 — Objective definitions and strategy weights */
/* EXPORT_RESULT_SET: M2_11_DETAIL_04_OBJECTIVES_AND_WEIGHTS */
SELECT
    'M2_11_DETAIL_04_OBJECTIVES_AND_WEIGHTS'::text AS result_set_code,
    s.module1_run_id,s.strategy_sequence,s.strategy_profile_code,
    s.selection_mode,s.selected_exposure_direction,
    o.objective_sequence,o.objective_code,o.objective_name,
    o.candidate_formula_code,o.scope_formula_code,
    o.default_direction_code,o.normalization_method_code,
    o.missing_value_policy_code,o.scoring_domain_code,
    o.scope_aggregation_method_code,o.pareto_inclusion_flag,
    o.equality_tolerance,o.numeric_scale,
    w.objective_weight,
    CASE
      WHEN o.objective_code='SERVICING_BURDEN_UNITS'
        THEN s.scope_scoring_applicable_flag
      ELSE s.candidate_scoring_applicable_flag
    END AS objective_domain_applicable_flag,
    s.candidate_domain_weight_total,s.scope_domain_weight_total
FROM msbf_m2.portfolio_strategy_profile s
CROSS JOIN LATERAL
(
 VALUES
 ('ACCESS_RATE',s.access_rate_weight),
 ('SELECTED_EXPOSURE_AMOUNT',s.selected_exposure_weight),
 ('FINANCE_CHARGE_AMOUNT',s.finance_charge_weight),
 ('EXPECTED_LOSS_DENSITY',s.expected_loss_density_weight),
 ('RISK_ADJUSTED_CONTRIBUTION',s.risk_adjusted_contribution_weight),
 ('ANNUALIZED_RISK_ADJUSTED_RETURN',s.annualized_return_weight),
 ('SERVICING_BURDEN_UNITS',s.servicing_burden_weight),
 ('PAYMENT_BURDEN_RATE',s.payment_burden_weight)
) w(objective_code,objective_weight)
JOIN msbf_m2.portfolio_strategy_objective_definition o
  ON o.module1_run_id=s.module1_run_id
 AND o.objective_code=w.objective_code
WHERE s.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY s.strategy_sequence,o.objective_sequence;

/* Result Set 05 — Hard-constraint definitions */
/* EXPORT_RESULT_SET: M2_11_DETAIL_05_CONSTRAINT_DEFINITIONS */
SELECT
    'M2_11_DETAIL_05_CONSTRAINT_DEFINITIONS'::text AS result_set_code,
    c.module1_run_id,
    c.constraint_code,
    c.constraint_sequence,
    c.constraint_name,
    c.constraint_family_code,
    c.applicability_code,
    c.severity_code,
    c.evaluation_rule_code,
    c.blocking_flag,
    c.description,
    c.row_hash,
    c.created_at
FROM msbf_m2.portfolio_strategy_constraint_definition c
WHERE c.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY c.constraint_sequence,c.constraint_code;

/* Result Set 06 — Reason definitions */
/* EXPORT_RESULT_SET: M2_11_DETAIL_06_REASON_DEFINITIONS */
SELECT
    'M2_11_DETAIL_06_REASON_DEFINITIONS'::text AS result_set_code,
    r.module1_run_id,
    r.reason_code,
    r.reason_sequence,
    r.reason_family,
    r.severity_code,
    r.severity_rank,
    r.applicability_code,
    r.description,
    r.production_action_flag,
    r.external_system_update_flag,
    r.merchant_contact_flag,
    r.production_adverse_action_flag,
    r.row_hash,
    r.created_at
FROM msbf_m2.portfolio_strategy_reason_definition r
WHERE r.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY r.reason_sequence,r.reason_code;

/* Result Set 07 — Canonical entity counts */
/* EXPORT_RESULT_SET: M2_11_DETAIL_07_CANONICAL_ENTITY_COUNTS */
WITH governed_run AS
(
    SELECT r.run_id
    FROM msbf_ctl.run_registry r
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
      AND r.run_version=1
      AND r.run_status='M2_11_ACCEPTED'
), physical AS
(
    SELECT
        h.catalog_sequence,h.object_code,count(*)::bigint AS physical_row_count,
        md5(string_agg(h.row_hash,'|' ORDER BY CASE h.object_code
        WHEN 'msbf_m2.portfolio_strategy_summary'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_frontier'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_comparison'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_simulation_latest'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_simulation_archive'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',2)||'|'||split_part(h.business_key,'|',4)||'|'||split_part(h.business_key,'|',3)
        ELSE h.business_key
      END)) AS reconstructed_set_hash
    FROM msbf_m2.v_m2_11_canonical_entity_hash_source h
    WHERE h.business_key=(SELECT run_id::text FROM governed_run)
       OR h.business_key LIKE (SELECT run_id::text||'|%' FROM governed_run)
    GROUP BY h.catalog_sequence,h.object_code
), expected AS
(
    SELECT x.*
    FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
    CROSS JOIN LATERAL
    (
      VALUES
      (1,'msbf_ctl.m2_11_policy_profile',c.policy_rows,c.policy_set_hash),
      (2,'msbf_m2.portfolio_strategy_profile',c.strategy_profile_rows,c.strategy_profile_set_hash),
      (3,'msbf_m2.portfolio_strategy_objective_definition',c.objective_definition_rows,c.objective_definition_set_hash),
      (4,'msbf_m2.portfolio_strategy_constraint_definition',c.constraint_definition_rows,c.constraint_definition_set_hash),
      (5,'msbf_m2.portfolio_strategy_reason_definition',c.reason_definition_rows,c.reason_definition_set_hash),
      (6,'msbf_m2.portfolio_strategy_application_source_snapshot',c.application_source_rows,c.application_source_set_hash),
      (7,'msbf_m2.portfolio_strategy_candidate_source_snapshot',c.candidate_source_rows,c.candidate_source_set_hash),
      (8,'msbf_m2.portfolio_strategy_account_source_snapshot',c.account_source_rows,c.account_source_set_hash),
      (9,'msbf_m2.portfolio_strategy_kpi_source_snapshot',c.kpi_source_rows,c.kpi_source_set_hash),
      (10,'msbf_m2.portfolio_strategy_queue_source_snapshot',c.queue_source_rows,c.queue_source_set_hash),
      (11,'msbf_m2.application_strategy_candidate_evaluation',c.candidate_evaluation_rows,c.candidate_evaluation_set_hash),
      (12,'msbf_m2.application_portfolio_strategy_simulation',c.application_simulation_rows,c.application_simulation_set_hash),
      (13,'msbf_m2.account_servicing_strategy_simulation',c.account_simulation_rows,c.account_simulation_set_hash),
      (14,'msbf_m2.portfolio_strategy_summary',c.strategy_summary_rows,c.strategy_summary_set_hash),
      (15,'msbf_m2.portfolio_strategy_frontier',c.frontier_rows,c.frontier_set_hash),
      (16,'msbf_m2.portfolio_strategy_comparison',c.comparison_rows,c.comparison_set_hash),
      (17,'msbf_m2.portfolio_strategy_simulation_latest',c.latest_rows,c.latest_set_hash),
      (18,'msbf_m2.portfolio_strategy_simulation_archive',c.archive_rows,c.archive_set_hash),
      (19,'msbf_ctl.m2_11_portfolio_strategy_contract_registry',c.registry_rows,md5(c.row_hash))
    ) x(catalog_sequence,object_code,expected_row_count,registry_set_hash)
    WHERE c.module1_run_id=(SELECT run_id FROM governed_run)
      AND c.contract_version=1
), canonical AS
(
    SELECT
        coalesce(e.catalog_sequence,p.catalog_sequence) AS catalog_sequence,
        coalesce(e.object_code,p.object_code) AS object_code,
        e.expected_row_count,p.physical_row_count,
        e.registry_set_hash,p.reconstructed_set_hash,
        (e.expected_row_count IS NOT DISTINCT FROM p.physical_row_count) AS row_count_match_flag,
        (e.registry_set_hash IS NOT DISTINCT FROM p.reconstructed_set_hash) AS set_hash_match_flag
    FROM expected e
    FULL JOIN physical p USING(object_code)
)
SELECT
    'M2_11_DETAIL_07_CANONICAL_ENTITY_COUNTS'::text AS result_set_code,
    catalog_sequence,object_code,expected_row_count,physical_row_count,
    row_count_match_flag,registry_set_hash,reconstructed_set_hash,
    set_hash_match_flag
FROM canonical
ORDER BY catalog_sequence,object_code;

/* Result Set 08 — Accepted-source snapshot reconciliation */
/* EXPORT_RESULT_SET: M2_11_DETAIL_08_SOURCE_SNAPSHOT_RECONCILIATION */
WITH governed_run AS
(
    SELECT r.run_id
    FROM msbf_ctl.run_registry r
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
      AND r.run_version=1
      AND r.run_status='M2_11_ACCEPTED'
), physical AS
(
    SELECT
        h.catalog_sequence,h.object_code,count(*)::bigint AS physical_row_count,
        md5(string_agg(h.row_hash,'|' ORDER BY CASE h.object_code
        WHEN 'msbf_m2.portfolio_strategy_summary'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_frontier'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_comparison'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_simulation_latest'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_simulation_archive'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',2)||'|'||split_part(h.business_key,'|',4)||'|'||split_part(h.business_key,'|',3)
        ELSE h.business_key
      END)) AS reconstructed_set_hash
    FROM msbf_m2.v_m2_11_canonical_entity_hash_source h
    WHERE h.business_key=(SELECT run_id::text FROM governed_run)
       OR h.business_key LIKE (SELECT run_id::text||'|%' FROM governed_run)
    GROUP BY h.catalog_sequence,h.object_code
), expected AS
(
    SELECT x.*
    FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
    CROSS JOIN LATERAL
    (
      VALUES
      (1,'msbf_ctl.m2_11_policy_profile',c.policy_rows,c.policy_set_hash),
      (2,'msbf_m2.portfolio_strategy_profile',c.strategy_profile_rows,c.strategy_profile_set_hash),
      (3,'msbf_m2.portfolio_strategy_objective_definition',c.objective_definition_rows,c.objective_definition_set_hash),
      (4,'msbf_m2.portfolio_strategy_constraint_definition',c.constraint_definition_rows,c.constraint_definition_set_hash),
      (5,'msbf_m2.portfolio_strategy_reason_definition',c.reason_definition_rows,c.reason_definition_set_hash),
      (6,'msbf_m2.portfolio_strategy_application_source_snapshot',c.application_source_rows,c.application_source_set_hash),
      (7,'msbf_m2.portfolio_strategy_candidate_source_snapshot',c.candidate_source_rows,c.candidate_source_set_hash),
      (8,'msbf_m2.portfolio_strategy_account_source_snapshot',c.account_source_rows,c.account_source_set_hash),
      (9,'msbf_m2.portfolio_strategy_kpi_source_snapshot',c.kpi_source_rows,c.kpi_source_set_hash),
      (10,'msbf_m2.portfolio_strategy_queue_source_snapshot',c.queue_source_rows,c.queue_source_set_hash),
      (11,'msbf_m2.application_strategy_candidate_evaluation',c.candidate_evaluation_rows,c.candidate_evaluation_set_hash),
      (12,'msbf_m2.application_portfolio_strategy_simulation',c.application_simulation_rows,c.application_simulation_set_hash),
      (13,'msbf_m2.account_servicing_strategy_simulation',c.account_simulation_rows,c.account_simulation_set_hash),
      (14,'msbf_m2.portfolio_strategy_summary',c.strategy_summary_rows,c.strategy_summary_set_hash),
      (15,'msbf_m2.portfolio_strategy_frontier',c.frontier_rows,c.frontier_set_hash),
      (16,'msbf_m2.portfolio_strategy_comparison',c.comparison_rows,c.comparison_set_hash),
      (17,'msbf_m2.portfolio_strategy_simulation_latest',c.latest_rows,c.latest_set_hash),
      (18,'msbf_m2.portfolio_strategy_simulation_archive',c.archive_rows,c.archive_set_hash),
      (19,'msbf_ctl.m2_11_portfolio_strategy_contract_registry',c.registry_rows,md5(c.row_hash))
    ) x(catalog_sequence,object_code,expected_row_count,registry_set_hash)
    WHERE c.module1_run_id=(SELECT run_id FROM governed_run)
      AND c.contract_version=1
), canonical AS
(
    SELECT
        coalesce(e.catalog_sequence,p.catalog_sequence) AS catalog_sequence,
        coalesce(e.object_code,p.object_code) AS object_code,
        e.expected_row_count,p.physical_row_count,
        e.registry_set_hash,p.reconstructed_set_hash,
        (e.expected_row_count IS NOT DISTINCT FROM p.physical_row_count) AS row_count_match_flag,
        (e.registry_set_hash IS NOT DISTINCT FROM p.reconstructed_set_hash) AS set_hash_match_flag
    FROM expected e
    FULL JOIN physical p USING(object_code)
)
SELECT
    'M2_11_DETAIL_08_SOURCE_SNAPSHOT_RECONCILIATION'::text AS result_set_code,
    catalog_sequence,object_code,expected_row_count,physical_row_count,
    row_count_match_flag,registry_set_hash,reconstructed_set_hash,
    set_hash_match_flag
FROM canonical
WHERE catalog_sequence BETWEEN 6 AND 10
ORDER BY catalog_sequence,object_code;

/* Result Set 09 — Candidate evaluation */
/* EXPORT_RESULT_SET: M2_11_DETAIL_09_CANDIDATE_EVALUATION */
SELECT
    'M2_11_DETAIL_09_CANDIDATE_EVALUATION'::text AS result_set_code,
    e.module1_run_id,
    e.scenario_id,
    e.scenario_code,
    e.merchant_application_id,
    e.candidate_template_code,
    e.strategy_profile_code,
    e.candidate_source_snapshot_row_hash,
    e.source_candidate_row_hash,
    e.candidate_rank,
    e.candidate_eligible_flag,
    e.source_route_code,
    e.source_route_rank,
    e.source_evidence_status_code,
    e.source_integrity_pass_flag,
    e.accepted_candidate_flag,
    e.hard_constraint_violation_count,
    e.hard_constraint_codes,
    e.feasibility_class,
    e.feasibility_rank,
    e.candidate_scoring_applicable_flag,
    e.objective_evidence_complete_flag,
    e.access_rate_raw_value,
    e.access_rate_minimum_value,
    e.access_rate_maximum_value,
    e.access_rate_normalized_value,
    e.access_rate_strategy_weight,
    e.access_rate_weighted_contribution,
    e.selected_exposure_amount_raw_value,
    e.selected_exposure_amount_minimum_value,
    e.selected_exposure_amount_maximum_value,
    e.selected_exposure_amount_normalized_value,
    e.selected_exposure_amount_strategy_weight,
    e.selected_exposure_amount_weighted_contribution,
    e.finance_charge_amount_raw_value,
    e.finance_charge_amount_minimum_value,
    e.finance_charge_amount_maximum_value,
    e.finance_charge_amount_normalized_value,
    e.finance_charge_amount_strategy_weight,
    e.finance_charge_amount_weighted_contribution,
    e.expected_loss_density_raw_value,
    e.expected_loss_density_minimum_value,
    e.expected_loss_density_maximum_value,
    e.expected_loss_density_normalized_value,
    e.expected_loss_density_strategy_weight,
    e.expected_loss_density_weighted_contribution,
    e.risk_adjusted_contribution_raw_value,
    e.risk_adjusted_contribution_minimum_value,
    e.risk_adjusted_contribution_maximum_value,
    e.risk_adjusted_contribution_normalized_value,
    e.risk_adjusted_contribution_strategy_weight,
    e.risk_adjusted_contribution_weighted_contribution,
    e.annualized_risk_adjusted_return_raw_value,
    e.annualized_risk_adjusted_return_minimum_value,
    e.annualized_risk_adjusted_return_maximum_value,
    e.annualized_risk_adjusted_return_normalized_value,
    e.annualized_risk_adjusted_return_strategy_weight,
    e.annualized_risk_adjusted_return_weighted_contribution,
    e.payment_burden_rate_raw_value,
    e.payment_burden_rate_minimum_value,
    e.payment_burden_rate_maximum_value,
    e.payment_burden_rate_normalized_value,
    e.payment_burden_rate_strategy_weight,
    e.payment_burden_rate_weighted_contribution,
    e.servicing_burden_applicability_code,
    e.applicable_candidate_weight_total,
    e.objective_score,
    e.objective_score_tie_flag,
    e.candidate_selected_flag,
    e.primary_reason_code,
    e.reason_codes,
    e.row_hash,
    e.created_at
FROM msbf_m2.application_strategy_candidate_evaluation e
WHERE e.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY e.scenario_id,e.merchant_application_id,e.strategy_profile_code,
         e.candidate_rank,e.candidate_template_code;

/* Result Set 10 — Application strategy simulations */
/* EXPORT_RESULT_SET: M2_11_DETAIL_10_APPLICATION_SIMULATIONS */
SELECT
    'M2_11_DETAIL_10_APPLICATION_SIMULATIONS'::text AS result_set_code,
    s.module1_run_id,
    s.scenario_id,
    s.scenario_code,
    s.merchant_application_id,
    s.strategy_profile_code,
    s.application_source_snapshot_row_hash,
    s.selection_mode,
    s.source_pricing_disposition_code,
    s.source_structure_available_flag,
    s.source_review_required_flag,
    s.source_activation_outcome_code,
    s.strategy_outcome_code,
    s.strategy_outcome_rank,
    s.feasibility_class,
    s.feasibility_rank,
    s.access_selected_flag,
    s.controlled_review_flag,
    s.implicit_no_access_selected_flag,
    s.policy_decline_preserved_flag,
    s.insufficient_evidence_preserved_flag,
    s.source_integrity_blocked_flag,
    s.selected_candidate_template_code,
    s.selected_candidate_source_row_hash,
    s.selected_candidate_evaluation_row_hash,
    s.selection_objective_score,
    s.hard_constraint_violation_count,
    s.hard_constraint_codes,
    s.strategy_evidence_status,
    s.operational_account_present_flag,
    s.account_certification_constraint_applicability,
    s.constraint_unresolved_exception_count,
    s.source_unresolved_exception_count,
    s.source_certified_state_code,
    s.source_servicing_queue_code,
    s.source_certified_exposure_amount,
    s.certification_blocked_flag,
    s.source_lineage_intact_flag,
    s.associated_account_servicing_simulation_row_hash,
    s.associated_servicing_treatment_code,
    s.associated_servicing_burden_units,
    s.requested_funding_amount,
    s.selected_exposure_amount,
    s.selected_remittance_rate,
    s.selected_payback_multiple,
    s.selected_collection_horizon_days,
    s.selected_total_repayment_amount,
    s.selected_finance_charge_amount,
    s.selected_implied_daily_collection_amount,
    s.selected_implied_payoff_days,
    s.selected_amount_to_request_ratio,
    s.selected_acquisition_economics_amount,
    s.selected_expected_loss_amount,
    s.selected_expected_loss_density,
    s.selected_risk_adjusted_contribution,
    s.selected_annualized_risk_adjusted_return,
    s.selected_payment_burden_rate,
    s.replay_pricing_disposition_code,
    s.replay_structure_available_flag,
    s.replay_review_required_flag,
    s.replay_selected_candidate_template_code,
    s.replay_selected_candidate_row_hash,
    s.replay_requested_funding_amount,
    s.replay_selected_funding_amount,
    s.replay_selected_remittance_rate,
    s.replay_selected_payback_multiple,
    s.replay_selected_collection_horizon_days,
    s.replay_selected_total_repayment_amount,
    s.replay_selected_finance_charge_amount,
    s.replay_selected_implied_daily_collection_amount,
    s.replay_selected_implied_payoff_days,
    s.replay_selected_amount_to_request_ratio,
    s.replay_candidate_count,
    s.replay_counteroffer_foundation_flag,
    s.replay_stress_nonimprovement_applied_flag,
    s.replay_routing_evidence_status,
    s.replay_source_final_decision_outcome_code,
    s.replay_activation_outcome_code,
    s.replay_activation_outcome_rank,
    s.replay_booking_eligible_flag,
    s.replay_booking_authorized_flag,
    s.replay_funding_authorized_flag,
    s.replay_funding_completed_flag,
    s.replay_portfolio_activated_flag,
    s.replay_operational_review_required_flag,
    s.replay_synthetic_offer_acceptance_assumed_flag,
    s.replay_synthetic_account_id,
    s.replay_synthetic_advance_id,
    s.replay_booked_amount,
    s.replay_funded_amount,
    s.replay_activation_remittance_rate,
    s.replay_activation_payback_multiple,
    s.replay_activation_collection_horizon_days,
    s.replay_activation_total_repayment_amount,
    s.replay_activation_finance_charge_amount,
    s.replay_activation_implied_daily_collection_amount,
    s.replay_activation_implied_payoff_days,
    s.replay_activation_evidence_status,
    s.replay_applicability_code,
    s.baseline_replay_match_flag,
    s.source_risk_improvement_violation_flag,
    s.source_return_improvement_violation_flag,
    s.strategy_access_improvement_violation_flag,
    s.strategy_feasibility_improvement_violation_flag,
    s.comparable_payment_burden_improvement_violation_flag,
    s.comparable_servicing_burden_improvement_violation_flag,
    s.strategy_restriction_flag,
    s.absolute_workload_reduction_flag,
    s.stress_nonimprovement_pass_flag,
    s.portfolio_adverse_selected_flag,
    s.portfolio_adversity_order,
    s.primary_reason_code,
    s.reason_codes,
    s.row_hash,
    s.created_at
FROM msbf_m2.application_portfolio_strategy_simulation s
WHERE s.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY s.scenario_id,s.merchant_application_id,s.strategy_profile_code;

/* Result Set 11 — Account servicing simulations */
/* EXPORT_RESULT_SET: M2_11_DETAIL_11_ACCOUNT_SERVICING_SIMULATIONS */
SELECT
    'M2_11_DETAIL_11_ACCOUNT_SERVICING_SIMULATIONS'::text AS result_set_code,
    s.module1_run_id,
    s.scenario_id,
    s.scenario_code,
    s.merchant_application_id,
    s.synthetic_account_id,
    s.strategy_profile_code,
    s.account_source_snapshot_row_hash,
    s.source_account_posture_code,
    s.source_account_posture_rank,
    s.source_operational_setup_outcome_code,
    s.source_operational_setup_action_code,
    s.source_operational_setup_queue_code,
    s.source_operational_activation_date,
    s.source_next_reassessment_date,
    s.source_payment_factor,
    s.source_setup_duration_days,
    s.source_reassessment_interval_days,
    s.source_certified_state_code,
    s.source_servicing_queue_code,
    s.source_certified_exposure_amount,
    s.source_servicing_burden_units,
    s.servicing_treatment_code,
    s.treatment_applicable_flag,
    s.simulated_action_date,
    s.simulated_payment_factor,
    s.simulated_exposure_amount,
    s.incremental_servicing_burden_units,
    s.strategy_servicing_burden_units,
    s.risk_benefit_claimed_flag,
    s.return_benefit_claimed_flag,
    s.contribution_benefit_claimed_flag,
    s.payment_performance_benefit_claimed_flag,
    s.source_replay_match_flag,
    s.strategy_evidence_status,
    s.portfolio_adverse_selected_flag,
    s.portfolio_adversity_order,
    s.primary_reason_code,
    s.reason_codes,
    s.row_hash,
    s.created_at
FROM msbf_m2.account_servicing_strategy_simulation s
WHERE s.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY s.scenario_id,s.merchant_application_id,s.strategy_profile_code;

/* Result Set 12 — Scope strategy summaries */
/* EXPORT_RESULT_SET: M2_11_DETAIL_12_SCOPE_STRATEGY_SUMMARIES */
SELECT
    'M2_11_DETAIL_12_SCOPE_STRATEGY_SUMMARIES'::text AS result_set_code,
    s.module1_run_id,
    s.strategy_profile_code,
    s.reporting_scope_code,
    s.application_rows,
    s.access_selected_rows,
    s.controlled_review_rows,
    s.strategy_restriction_rows,
    s.no_feasible_candidate_rows,
    s.insufficient_evidence_rows,
    s.policy_decline_rows,
    s.blocked_source_rows,
    s.hard_constraint_violation_count,
    s.complete_evidence_rows,
    s.partial_evidence_rows,
    s.blocked_evidence_rows,
    s.source_risk_improvement_violation_count,
    s.source_return_improvement_violation_count,
    s.strategy_access_improvement_violation_count,
    s.strategy_feasibility_improvement_violation_count,
    s.comparable_payment_burden_improvement_violation_count,
    s.comparable_servicing_burden_improvement_violation_count,
    s.stress_improvement_violation_count,
    s.stress_strategy_restriction_rows,
    s.absolute_workload_reduction_rows,
    s.servicing_account_rows,
    s.servicing_distinct_application_rows,
    s.stress_nonimprovement_pass_flag,
    s.access_rate,
    s.selected_exposure_amount,
    s.finance_charge_amount,
    s.expected_loss_amount,
    s.expected_loss_density,
    s.risk_adjusted_contribution,
    s.annualized_risk_adjusted_return,
    s.payment_burden_rate,
    s.servicing_burden_units,
    s.servicing_burden_coverage_code,
    s.new_access_servicing_burden_estimated_flag,
    s.strategy_evidence_status,
    s.frontier_metrics_complete_flag,
    s.access_rate_normalized_value,
    s.access_rate_weighted_contribution,
    s.selected_exposure_amount_normalized_value,
    s.selected_exposure_amount_weighted_contribution,
    s.finance_charge_amount_normalized_value,
    s.finance_charge_amount_weighted_contribution,
    s.expected_loss_density_normalized_value,
    s.expected_loss_density_weighted_contribution,
    s.risk_adjusted_contribution_normalized_value,
    s.risk_adjusted_contribution_weighted_contribution,
    s.annualized_risk_adjusted_return_normalized_value,
    s.annualized_risk_adjusted_return_weighted_contribution,
    s.servicing_burden_units_normalized_value,
    s.servicing_burden_units_weighted_contribution,
    s.payment_burden_rate_normalized_value,
    s.payment_burden_rate_weighted_contribution,
    s.scope_strategy_score,
    s.application_simulation_set_hash,
    s.account_simulation_set_hash,
    s.row_hash,
    s.created_at
FROM msbf_m2.portfolio_strategy_summary s
WHERE s.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY
  CASE s.reporting_scope_code
    WHEN 'BASELINE' THEN 1 WHEN 'RECESSION_ENERGY' THEN 2
    WHEN 'PORTFOLIO' THEN 3 ELSE 99 END,
  s.strategy_profile_code;

/* Result Set 13 — Baseline/challenger comparisons */
/* EXPORT_RESULT_SET: M2_11_DETAIL_13_BASELINE_CHALLENGER_COMPARISONS */
SELECT
    'M2_11_DETAIL_13_BASELINE_CHALLENGER_COMPARISONS'::text AS result_set_code,
    c.module1_run_id,
    c.reporting_scope_code,
    c.baseline_strategy_profile_code,
    c.challenger_strategy_profile_code,
    c.baseline_summary_row_hash,
    c.challenger_summary_row_hash,
    c.baseline_frontier_row_hash,
    c.challenger_frontier_row_hash,
    c.baseline_access_rate,
    c.challenger_access_rate,
    c.access_rate_delta,
    c.baseline_selected_exposure_amount,
    c.challenger_selected_exposure_amount,
    c.selected_exposure_amount_delta,
    c.baseline_finance_charge_amount,
    c.challenger_finance_charge_amount,
    c.finance_charge_amount_delta,
    c.baseline_expected_loss_density,
    c.challenger_expected_loss_density,
    c.expected_loss_density_delta,
    c.baseline_risk_adjusted_contribution,
    c.challenger_risk_adjusted_contribution,
    c.risk_adjusted_contribution_delta,
    c.baseline_annualized_risk_adjusted_return,
    c.challenger_annualized_risk_adjusted_return,
    c.annualized_risk_adjusted_return_delta,
    c.baseline_servicing_burden_units,
    c.challenger_servicing_burden_units,
    c.servicing_burden_units_delta,
    c.baseline_payment_burden_rate,
    c.challenger_payment_burden_rate,
    c.payment_burden_rate_delta,
    c.baseline_frontier_rank,
    c.challenger_frontier_rank,
    c.baseline_frontier_eligible_flag,
    c.challenger_frontier_eligible_flag,
    c.challenger_governance_review_priority_code,
    c.challenger_stress_improvement_violation_count,
    c.challenger_stress_nonimprovement_pass_flag,
    c.challenger_stress_strategy_restriction_rows,
    c.challenger_absolute_workload_reduction_rows,
    c.challenger_hard_constraint_violation_count,
    c.servicing_burden_coverage_code,
    c.new_access_servicing_burden_estimated_flag,
    c.row_hash,
    c.created_at
FROM msbf_m2.portfolio_strategy_comparison c
WHERE c.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY
  CASE c.reporting_scope_code
    WHEN 'BASELINE' THEN 1 WHEN 'RECESSION_ENERGY' THEN 2
    WHEN 'PORTFOLIO' THEN 3 ELSE 99 END,
  c.challenger_strategy_profile_code;

/* Result Set 14 — Stress non-improvement */
/* EXPORT_RESULT_SET: M2_11_DETAIL_14_STRESS_NONIMPROVEMENT */
SELECT
    'M2_11_DETAIL_14_STRESS_NONIMPROVEMENT'::text AS result_set_code,
    v.module1_run_id,
    v.merchant_application_id,
    v.strategy_profile_code,
    v.baseline_strategy_outcome_code,
    v.stress_strategy_outcome_code,
    v.baseline_feasibility_class,
    v.stress_feasibility_class,
    v.baseline_selected_exposure_amount,
    v.stress_selected_exposure_amount,
    v.baseline_payment_burden_rate,
    v.stress_payment_burden_rate,
    v.baseline_servicing_burden_units,
    v.stress_servicing_burden_units,
    v.source_risk_improvement_violation_flag,
    v.source_return_improvement_violation_flag,
    v.strategy_access_improvement_violation_flag,
    v.strategy_feasibility_improvement_violation_flag,
    v.comparable_payment_burden_improvement_violation_flag,
    v.comparable_servicing_burden_improvement_violation_flag,
    v.strategy_restriction_flag,
    v.absolute_workload_reduction_flag,
    v.stress_nonimprovement_pass_flag,
    v.baseline_row_hash,
    v.stress_row_hash
FROM msbf_m2.v_m2_11_matched_application_stress_comparison v
WHERE v.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY v.merchant_application_id,v.strategy_profile_code;

/* Result Set 15 — Pareto frontier */
/* EXPORT_RESULT_SET: M2_11_DETAIL_15_PARETO_FRONTIER */
SELECT
    'M2_11_DETAIL_15_PARETO_FRONTIER'::text AS result_set_code,
    f.module1_run_id,
    f.strategy_profile_code,
    f.reporting_scope_code,
    f.strategy_summary_row_hash,
    f.frontier_eligible_flag,
    f.frontier_ineligibility_code,
    f.dominated_by_count,
    f.dominates_count,
    f.non_dominated_flag,
    f.frontier_rank,
    f.evidence_rank,
    f.governance_balance_score,
    f.governance_review_priority_code,
    f.governance_review_priority_rank,
    f.primary_governance_review_flag,
    f.governance_access_rate_normalized_value,
    f.governance_finance_charge_amount_normalized_value,
    f.governance_expected_loss_density_normalized_value,
    f.governance_risk_adjusted_contribution_normalized_value,
    f.governance_annualized_risk_adjusted_return_normalized_value,
    f.governance_servicing_burden_units_normalized_value,
    f.governance_payment_burden_rate_normalized_value,
    f.primary_reason_code,
    f.reason_codes,
    f.row_hash,
    f.created_at
FROM msbf_m2.portfolio_strategy_frontier f
WHERE f.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY
  CASE f.reporting_scope_code
    WHEN 'BASELINE' THEN 1 WHEN 'RECESSION_ENERGY' THEN 2
    WHEN 'PORTFOLIO' THEN 3 ELSE 99 END,
  f.frontier_rank NULLS LAST,f.strategy_profile_code;

/* Result Set 16 — Governance-review priorities */
/* EXPORT_RESULT_SET: M2_11_DETAIL_16_GOVERNANCE_PRIORITIES */
SELECT
    'M2_11_DETAIL_16_GOVERNANCE_PRIORITIES'::text AS result_set_code,
    f.module1_run_id,f.reporting_scope_code,f.strategy_profile_code,
    f.frontier_eligible_flag,f.frontier_ineligibility_code,
    f.non_dominated_flag,f.frontier_rank,f.evidence_rank,
    f.governance_balance_score,f.governance_review_priority_code,
    f.governance_review_priority_rank,f.primary_governance_review_flag,
    f.primary_reason_code,f.reason_codes,
    s.strategy_evidence_status,s.hard_constraint_violation_count,
    s.stress_improvement_violation_count,s.stress_nonimprovement_pass_flag,
    s.access_rate,s.finance_charge_amount,s.expected_loss_density,
    s.risk_adjusted_contribution,s.annualized_risk_adjusted_return,
    s.servicing_burden_units,s.payment_burden_rate,
    'GOVERNANCE_REVIEW_ONLY_NOT_DEPLOYMENT_AUTHORIZATION'::text
      AS priority_interpretation
FROM msbf_m2.portfolio_strategy_frontier f
JOIN msbf_m2.portfolio_strategy_summary s
  USING(module1_run_id,strategy_profile_code,reporting_scope_code)
WHERE f.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY
  CASE f.reporting_scope_code
    WHEN 'BASELINE' THEN 1 WHEN 'RECESSION_ENERGY' THEN 2
    WHEN 'PORTFOLIO' THEN 3 ELSE 99 END,
  f.governance_review_priority_rank NULLS LAST,
  f.frontier_rank NULLS LAST,f.strategy_profile_code;

/* Result Set 17 — Latest strategy contract */
/* EXPORT_RESULT_SET: M2_11_DETAIL_17_LATEST_CONTRACT */
SELECT
    'M2_11_DETAIL_17_LATEST_CONTRACT'::text AS result_set_code,
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
WHERE l.module1_run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
ORDER BY
  CASE l.reporting_scope_code
    WHEN 'BASELINE' THEN 1 WHEN 'RECESSION_ENERGY' THEN 2
    WHEN 'PORTFOLIO' THEN 3 ELSE 99 END,
  l.strategy_profile_code;

/* Result Set 18 — Latest/archive reproduction */
/* EXPORT_RESULT_SET: M2_11_DETAIL_18_LATEST_ARCHIVE_REPRODUCTION */
WITH governed_run AS
(
    SELECT r.run_id
    FROM msbf_ctl.run_registry r
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
      AND r.run_version=1
      AND r.run_status='M2_11_ACCEPTED'
), latest_archive AS
(
    SELECT
        coalesce(l.module1_run_id,a.module1_run_id) AS module1_run_id,
        coalesce(l.strategy_profile_code,a.strategy_profile_code) AS strategy_profile_code,
        coalesce(l.reporting_scope_code,a.reporting_scope_code) AS reporting_scope_code,
        l.contract_version AS latest_contract_version,
        a.contract_version AS archive_contract_version,
        l.contract_row_hash AS latest_contract_row_hash,
        a.contract_row_hash AS archive_source_latest_row_hash,
        a.archive_row_hash,
        (a.contract_payload IS NOT DISTINCT FROM (to_jsonb(l)-'created_at')) AS payload_match_flag,
        (a.contract_row_hash IS NOT DISTINCT FROM l.contract_row_hash) AS contract_row_hash_match_flag,
        (l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL) AS row_pair_present_flag,
        CASE
          WHEN l.module1_run_id IS NULL THEN 'MISSING_LATEST'
          WHEN a.module1_run_id IS NULL THEN 'MISSING_ARCHIVE'
          WHEN a.contract_row_hash IS DISTINCT FROM l.contract_row_hash THEN 'CONTRACT_ROW_HASH_MISMATCH'
          WHEN a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at') THEN 'ARCHIVE_PAYLOAD_MISMATCH'
          ELSE 'MATCH'
        END AS reproduction_status
    FROM msbf_m2.portfolio_strategy_simulation_latest l
    FULL JOIN msbf_m2.portfolio_strategy_simulation_archive a
      ON a.module1_run_id=l.module1_run_id
     AND a.contract_version=l.contract_version
     AND a.strategy_profile_code=l.strategy_profile_code
     AND a.reporting_scope_code=l.reporting_scope_code
    WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM governed_run)
)
SELECT
    'M2_11_DETAIL_18_LATEST_ARCHIVE_REPRODUCTION'::text AS result_set_code,
    module1_run_id,strategy_profile_code,reporting_scope_code,
    latest_contract_version,archive_contract_version,
    latest_contract_row_hash,archive_source_latest_row_hash,archive_row_hash,
    payload_match_flag,contract_row_hash_match_flag,row_pair_present_flag,
    reproduction_status
FROM latest_archive
ORDER BY
  CASE reporting_scope_code
    WHEN 'BASELINE' THEN 1 WHEN 'RECESSION_ENERGY' THEN 2
    WHEN 'PORTFOLIO' THEN 3 ELSE 99 END,
  strategy_profile_code;

/* Result Set 19 — Contract registry and canonical hashes */
/* EXPORT_RESULT_SET: M2_11_DETAIL_19_REGISTRY_AND_CANONICAL_HASHES */
WITH governed_run AS
(
    SELECT r.run_id
    FROM msbf_ctl.run_registry r
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
      AND r.run_version=1
      AND r.run_status='M2_11_ACCEPTED'
), physical AS
(
    SELECT
        h.catalog_sequence,h.object_code,count(*)::bigint AS physical_row_count,
        md5(string_agg(h.row_hash,'|' ORDER BY CASE h.object_code
        WHEN 'msbf_m2.portfolio_strategy_summary'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_frontier'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_comparison'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_simulation_latest'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_simulation_archive'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',2)||'|'||split_part(h.business_key,'|',4)||'|'||split_part(h.business_key,'|',3)
        ELSE h.business_key
      END)) AS reconstructed_set_hash
    FROM msbf_m2.v_m2_11_canonical_entity_hash_source h
    WHERE h.business_key=(SELECT run_id::text FROM governed_run)
       OR h.business_key LIKE (SELECT run_id::text||'|%' FROM governed_run)
    GROUP BY h.catalog_sequence,h.object_code
), expected AS
(
    SELECT x.*
    FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
    CROSS JOIN LATERAL
    (
      VALUES
      (1,'msbf_ctl.m2_11_policy_profile',c.policy_rows,c.policy_set_hash),
      (2,'msbf_m2.portfolio_strategy_profile',c.strategy_profile_rows,c.strategy_profile_set_hash),
      (3,'msbf_m2.portfolio_strategy_objective_definition',c.objective_definition_rows,c.objective_definition_set_hash),
      (4,'msbf_m2.portfolio_strategy_constraint_definition',c.constraint_definition_rows,c.constraint_definition_set_hash),
      (5,'msbf_m2.portfolio_strategy_reason_definition',c.reason_definition_rows,c.reason_definition_set_hash),
      (6,'msbf_m2.portfolio_strategy_application_source_snapshot',c.application_source_rows,c.application_source_set_hash),
      (7,'msbf_m2.portfolio_strategy_candidate_source_snapshot',c.candidate_source_rows,c.candidate_source_set_hash),
      (8,'msbf_m2.portfolio_strategy_account_source_snapshot',c.account_source_rows,c.account_source_set_hash),
      (9,'msbf_m2.portfolio_strategy_kpi_source_snapshot',c.kpi_source_rows,c.kpi_source_set_hash),
      (10,'msbf_m2.portfolio_strategy_queue_source_snapshot',c.queue_source_rows,c.queue_source_set_hash),
      (11,'msbf_m2.application_strategy_candidate_evaluation',c.candidate_evaluation_rows,c.candidate_evaluation_set_hash),
      (12,'msbf_m2.application_portfolio_strategy_simulation',c.application_simulation_rows,c.application_simulation_set_hash),
      (13,'msbf_m2.account_servicing_strategy_simulation',c.account_simulation_rows,c.account_simulation_set_hash),
      (14,'msbf_m2.portfolio_strategy_summary',c.strategy_summary_rows,c.strategy_summary_set_hash),
      (15,'msbf_m2.portfolio_strategy_frontier',c.frontier_rows,c.frontier_set_hash),
      (16,'msbf_m2.portfolio_strategy_comparison',c.comparison_rows,c.comparison_set_hash),
      (17,'msbf_m2.portfolio_strategy_simulation_latest',c.latest_rows,c.latest_set_hash),
      (18,'msbf_m2.portfolio_strategy_simulation_archive',c.archive_rows,c.archive_set_hash),
      (19,'msbf_ctl.m2_11_portfolio_strategy_contract_registry',c.registry_rows,md5(c.row_hash))
    ) x(catalog_sequence,object_code,expected_row_count,registry_set_hash)
    WHERE c.module1_run_id=(SELECT run_id FROM governed_run)
      AND c.contract_version=1
), canonical AS
(
    SELECT
        coalesce(e.catalog_sequence,p.catalog_sequence) AS catalog_sequence,
        coalesce(e.object_code,p.object_code) AS object_code,
        e.expected_row_count,p.physical_row_count,
        e.registry_set_hash,p.reconstructed_set_hash,
        (e.expected_row_count IS NOT DISTINCT FROM p.physical_row_count) AS row_count_match_flag,
        (e.registry_set_hash IS NOT DISTINCT FROM p.reconstructed_set_hash) AS set_hash_match_flag
    FROM expected e
    FULL JOIN physical p USING(object_code)
), registry_context AS
(
    SELECT
        c.contract_set_hash,c.combined_set_hash,c.row_hash AS registry_row_hash,
        c.canonical_entities,c.contract_status,c.accepted_at
    FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
    WHERE c.module1_run_id=(SELECT run_id FROM governed_run)
      AND c.contract_version=1
      AND c.contract_status='ACCEPTED'
)
SELECT
    'M2_11_DETAIL_19_REGISTRY_AND_CANONICAL_HASHES'::text AS result_set_code,
    x.catalog_sequence,x.object_code,x.expected_row_count,x.physical_row_count,
    x.row_count_match_flag,x.registry_set_hash,x.reconstructed_set_hash,
    x.set_hash_match_flag,
    c.contract_set_hash,c.combined_set_hash,c.registry_row_hash,
    c.canonical_entities,c.contract_status,c.accepted_at
FROM canonical x
CROSS JOIN registry_context c
ORDER BY x.catalog_sequence,x.object_code;

/* Result Set 20 — Positive-control evidence */
/* EXPORT_RESULT_SET: M2_11_DETAIL_20_POSITIVE_CONTROL_SUMMARY */
SELECT
    'M2_11_DETAIL_20_POSITIVE_CONTROL_SUMMARY'::text AS result_set_code,
    run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
    metric_value_text,unit_code,status,threshold_value_numeric,
    interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
  AND evidence_code LIKE 'M2_11_POS_%'
ORDER BY evidence_code,segment_key;

/* Result Set 21 — Negative-control evidence */
/* EXPORT_RESULT_SET: M2_11_DETAIL_21_NEGATIVE_CONTROL_SUMMARY */
SELECT
    'M2_11_DETAIL_21_NEGATIVE_CONTROL_SUMMARY'::text AS result_set_code,
    run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
    metric_value_text,unit_code,status,threshold_value_numeric,
    interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
  AND evidence_code LIKE 'M2_11_NEG_%'
ORDER BY evidence_code,segment_key;

/* Result Set 22 — Generation and acceptance evidence */
/* EXPORT_RESULT_SET: M2_11_DETAIL_22_GENERATION_AND_ACCEPTANCE_EVIDENCE */
SELECT
    'M2_11_DETAIL_22_GENERATION_AND_ACCEPTANCE_EVIDENCE'::text AS result_set_code,
    run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
    metric_value_text,unit_code,status,threshold_value_numeric,
    interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT r.run_id FROM msbf_ctl.run_registry r WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND r.run_status='M2_11_ACCEPTED')
  AND (evidence_code LIKE 'M2_11_GENERATION_%'
       OR evidence_code='M2_11_ACCEPTANCE_SUMMARY')
ORDER BY evidence_code,segment_key;

/* Result Set 23 — Deterministic mismatches */
/* EXPORT_RESULT_SET: M2_11_DETAIL_23_DETERMINISTIC_MISMATCHES */
WITH governed_run AS
(
    SELECT r.run_id
    FROM msbf_ctl.run_registry r
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
      AND r.run_version=1
      AND r.run_status='M2_11_ACCEPTED'
), physical AS
(
    SELECT
        h.catalog_sequence,h.object_code,count(*)::bigint AS physical_row_count,
        md5(string_agg(h.row_hash,'|' ORDER BY CASE h.object_code
        WHEN 'msbf_m2.portfolio_strategy_summary'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_frontier'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_comparison'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_simulation_latest'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',3)||'|'||split_part(h.business_key,'|',2)
        WHEN 'msbf_m2.portfolio_strategy_simulation_archive'
          THEN split_part(h.business_key,'|',1)||'|'||split_part(h.business_key,'|',2)||'|'||split_part(h.business_key,'|',4)||'|'||split_part(h.business_key,'|',3)
        ELSE h.business_key
      END)) AS reconstructed_set_hash
    FROM msbf_m2.v_m2_11_canonical_entity_hash_source h
    WHERE h.business_key=(SELECT run_id::text FROM governed_run)
       OR h.business_key LIKE (SELECT run_id::text||'|%' FROM governed_run)
    GROUP BY h.catalog_sequence,h.object_code
), expected AS
(
    SELECT x.*
    FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
    CROSS JOIN LATERAL
    (
      VALUES
      (1,'msbf_ctl.m2_11_policy_profile',c.policy_rows,c.policy_set_hash),
      (2,'msbf_m2.portfolio_strategy_profile',c.strategy_profile_rows,c.strategy_profile_set_hash),
      (3,'msbf_m2.portfolio_strategy_objective_definition',c.objective_definition_rows,c.objective_definition_set_hash),
      (4,'msbf_m2.portfolio_strategy_constraint_definition',c.constraint_definition_rows,c.constraint_definition_set_hash),
      (5,'msbf_m2.portfolio_strategy_reason_definition',c.reason_definition_rows,c.reason_definition_set_hash),
      (6,'msbf_m2.portfolio_strategy_application_source_snapshot',c.application_source_rows,c.application_source_set_hash),
      (7,'msbf_m2.portfolio_strategy_candidate_source_snapshot',c.candidate_source_rows,c.candidate_source_set_hash),
      (8,'msbf_m2.portfolio_strategy_account_source_snapshot',c.account_source_rows,c.account_source_set_hash),
      (9,'msbf_m2.portfolio_strategy_kpi_source_snapshot',c.kpi_source_rows,c.kpi_source_set_hash),
      (10,'msbf_m2.portfolio_strategy_queue_source_snapshot',c.queue_source_rows,c.queue_source_set_hash),
      (11,'msbf_m2.application_strategy_candidate_evaluation',c.candidate_evaluation_rows,c.candidate_evaluation_set_hash),
      (12,'msbf_m2.application_portfolio_strategy_simulation',c.application_simulation_rows,c.application_simulation_set_hash),
      (13,'msbf_m2.account_servicing_strategy_simulation',c.account_simulation_rows,c.account_simulation_set_hash),
      (14,'msbf_m2.portfolio_strategy_summary',c.strategy_summary_rows,c.strategy_summary_set_hash),
      (15,'msbf_m2.portfolio_strategy_frontier',c.frontier_rows,c.frontier_set_hash),
      (16,'msbf_m2.portfolio_strategy_comparison',c.comparison_rows,c.comparison_set_hash),
      (17,'msbf_m2.portfolio_strategy_simulation_latest',c.latest_rows,c.latest_set_hash),
      (18,'msbf_m2.portfolio_strategy_simulation_archive',c.archive_rows,c.archive_set_hash),
      (19,'msbf_ctl.m2_11_portfolio_strategy_contract_registry',c.registry_rows,md5(c.row_hash))
    ) x(catalog_sequence,object_code,expected_row_count,registry_set_hash)
    WHERE c.module1_run_id=(SELECT run_id FROM governed_run)
      AND c.contract_version=1
), canonical AS
(
    SELECT
        coalesce(e.catalog_sequence,p.catalog_sequence) AS catalog_sequence,
        coalesce(e.object_code,p.object_code) AS object_code,
        e.expected_row_count,p.physical_row_count,
        e.registry_set_hash,p.reconstructed_set_hash,
        (e.expected_row_count IS NOT DISTINCT FROM p.physical_row_count) AS row_count_match_flag,
        (e.registry_set_hash IS NOT DISTINCT FROM p.reconstructed_set_hash) AS set_hash_match_flag
    FROM expected e
    FULL JOIN physical p USING(object_code)
), latest_archive AS
(
    SELECT
        coalesce(l.module1_run_id,a.module1_run_id) AS module1_run_id,
        coalesce(l.strategy_profile_code,a.strategy_profile_code) AS strategy_profile_code,
        coalesce(l.reporting_scope_code,a.reporting_scope_code) AS reporting_scope_code,
        CASE
          WHEN l.module1_run_id IS NULL THEN 'MISSING_LATEST'
          WHEN a.module1_run_id IS NULL THEN 'MISSING_ARCHIVE'
          WHEN a.contract_row_hash IS DISTINCT FROM l.contract_row_hash THEN 'CONTRACT_ROW_HASH_MISMATCH'
          WHEN a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at') THEN 'ARCHIVE_PAYLOAD_MISMATCH'
          ELSE 'MATCH'
        END AS reproduction_status
    FROM msbf_m2.portfolio_strategy_simulation_latest l
    FULL JOIN msbf_m2.portfolio_strategy_simulation_archive a
      ON a.module1_run_id=l.module1_run_id
     AND a.contract_version=l.contract_version
     AND a.strategy_profile_code=l.strategy_profile_code
     AND a.reporting_scope_code=l.reporting_scope_code
    WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM governed_run)
), mismatches AS
(
    SELECT
        'CANONICAL_COUNT_OR_HASH'::text AS mismatch_family,
        object_code,
        object_code AS business_key,
        coalesce(physical_row_count::text,'<MISSING>')||'|'||coalesce(reconstructed_set_hash,'<MISSING>') AS observed_value,
        coalesce(expected_row_count::text,'<MISSING>')||'|'||coalesce(registry_set_hash,'<MISSING>') AS expected_value,
        'Physical count or explicitly ordered set hash differs from the contract registry.'::text AS mismatch_detail
    FROM canonical
    WHERE NOT coalesce(row_count_match_flag,FALSE)
       OR NOT coalesce(set_hash_match_flag,FALSE)
    UNION ALL
    SELECT
        'LATEST_ARCHIVE','msbf_m2.portfolio_strategy_simulation_archive',
        coalesce(strategy_profile_code,'<NULL>')||'|'||coalesce(reporting_scope_code,'<NULL>'),
        reproduction_status,'MATCH',
        'Latest/archive payload or contract-row-hash reproduction differs.'
    FROM latest_archive
    WHERE reproduction_status<>'MATCH'
    UNION ALL
    SELECT
        'VALIDATION_EVIDENCE','msbf_ctl.run_evidence',e.evidence_code,
        e.status,'PASS','Persisted M2.11 evidence is not PASS.'
    FROM msbf_ctl.run_evidence e
    WHERE e.run_id=(SELECT run_id FROM governed_run)
      AND e.evidence_code LIKE 'M2_11_%'
      AND e.status<>'PASS'
    UNION ALL
    SELECT
        'STRESS_NONIMPROVEMENT','msbf_m2.application_portfolio_strategy_simulation',
        s.merchant_application_id||'|'||s.strategy_profile_code,
        'VIOLATION','NO_VIOLATION',
        'One or more stress-improvement violation flags are true.'
    FROM msbf_m2.application_portfolio_strategy_simulation s
    WHERE s.module1_run_id=(SELECT run_id FROM governed_run)
      AND
      (
        s.source_risk_improvement_violation_flag
        OR s.source_return_improvement_violation_flag
        OR s.strategy_access_improvement_violation_flag
        OR s.strategy_feasibility_improvement_violation_flag
        OR s.comparable_payment_burden_improvement_violation_flag
        OR s.comparable_servicing_burden_improvement_violation_flag
      )
    UNION ALL
    SELECT
        'COMBINED_HASH','msbf_ctl.m2_11_portfolio_strategy_contract_registry',
        c.module1_run_id::text||'|1',
        c.combined_set_hash,
        (SELECT md5(string_agg(object_code||'|'||reconstructed_set_hash,
                               '|' ORDER BY catalog_sequence)) FROM canonical),
        'Registry combined-set hash differs from the ordered nineteen-family reconstruction.'
    FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
    WHERE c.module1_run_id=(SELECT run_id FROM governed_run)
      AND c.contract_version=1
      AND c.combined_set_hash IS DISTINCT FROM
          (SELECT md5(string_agg(object_code||'|'||reconstructed_set_hash,
                                 '|' ORDER BY catalog_sequence)) FROM canonical)
)
SELECT
    'M2_11_DETAIL_23_DETERMINISTIC_MISMATCHES'::text AS result_set_code,
    mismatch_family,object_code,business_key,observed_value,expected_value,
    mismatch_detail
FROM mismatches
ORDER BY mismatch_family,object_code,business_key;

/* Result Set 24 — Blocking and stage-boundary violations */
/* EXPORT_RESULT_SET: M2_11_DETAIL_24_BLOCKING_AND_STAGE_BOUNDARY_VIOLATIONS */
WITH governed_run AS
(
    SELECT r.run_id
    FROM msbf_ctl.run_registry r
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
      AND r.run_version=1
      AND r.run_status='M2_11_ACCEPTED'
), violations AS
(
    SELECT
        'BLOCKING_ERROR'::text AS violation_family,
        'msbf_ctl.profile_resolution_error'::text AS object_name,
        e.resolution_error_id::text AS business_key,
        e.error_code AS violation_code,
        e.error_message AS violation_detail
    FROM msbf_ctl.profile_resolution_error e
    WHERE e.run_id=(SELECT run_id FROM governed_run)
      AND e.severity='BLOCKING'
    UNION ALL
    SELECT
        'NON_PRODUCTION','msbf_m2.portfolio_strategy_application_source_snapshot',
        s.scenario_id||'|'||s.merchant_application_id,
        'PROHIBITED_SOURCE_ACTION_FLAG',
        'A source snapshot contains a prohibited funds-movement, notice, or adverse-action flag.'
    FROM msbf_m2.portfolio_strategy_application_source_snapshot s
    WHERE s.module1_run_id=(SELECT run_id FROM governed_run)
      AND (s.real_funds_movement_flag OR s.external_notice_generation_authorized_flag
           OR s.external_notice_transmitted_flag OR s.production_adverse_action_notice_flag)
    UNION ALL
    SELECT
        'NON_PRODUCTION','msbf_m2.portfolio_strategy_reason_definition',
        d.reason_code,'PROHIBITED_REASON_ACTION_FLAG',
        'A reason definition authorizes a production action, external update, merchant contact, or adverse action.'
    FROM msbf_m2.portfolio_strategy_reason_definition d
    WHERE d.module1_run_id=(SELECT run_id FROM governed_run)
      AND (d.production_action_flag OR d.external_system_update_flag
           OR d.merchant_contact_flag OR d.production_adverse_action_flag)
    UNION ALL
    SELECT
        'GOVERNANCE_PRIORITY','msbf_m2.portfolio_strategy_frontier',
        f.reporting_scope_code,'MULTIPLE_PRIMARY_GOVERNANCE_PRIORITIES',
        'More than one primary governance-review priority exists in a reporting scope.'
    FROM msbf_m2.portfolio_strategy_frontier f
    WHERE f.module1_run_id=(SELECT run_id FROM governed_run)
      AND f.primary_governance_review_flag
    GROUP BY f.reporting_scope_code
    HAVING count(*)>1
    UNION ALL
    SELECT
        'STAGE_BOUNDARY',t.table_schema||'.'||t.table_name,
        t.table_schema||'.'||t.table_name,'PREMATURE_M2_12_OBJECT',
        'M2.12 physical state exists before independent M2.12 certification.'
    FROM information_schema.tables t
    WHERE t.table_schema IN ('msbf_ctl','msbf_m1','msbf_m2','msbf_ref')
      AND lower(t.table_name) LIKE '%m2_12%'
)
SELECT
    'M2_11_DETAIL_24_BLOCKING_AND_STAGE_BOUNDARY_VIOLATIONS'::text AS result_set_code,
    violation_family,object_name,business_key,violation_code,violation_detail
FROM violations
ORDER BY violation_family,object_name,business_key,violation_code;
