/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.6 — Early Warning, Intervention & Servicing Strategy

Program     : 173_msbf_m2_6_preflight_validation_v0_2.sql
Version     : v0.2

Purpose
-------
Fail closed unless accepted M2.5 monitoring evidence, M2.6 policy and
reference dictionaries, acceptance gate, empty M2.6 targets, and stage-boundary
conditions are ready for deterministic strategy generation.

Writes
------
None. The result table is session-scoped and preserved for review.

Required result
---------------
preflight_status = PASS.
============================================================================ */

SET statement_timeout='30min';
SET jit=off;
DROP TABLE IF EXISTS _m2_6_preflight;

CREATE TEMP TABLE _m2_6_preflight ON COMMIT PRESERVE ROWS AS
WITH run_context AS (
    SELECT run_id, run_status, population_id, as_of_date FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
),
policy AS (
    SELECT policy_status, methodology_version, contract_code, contract_version, schema_version, source_m2_5_contract_code AS policy_source_m2_5_contract_code, source_m2_5_contract_version AS policy_source_m2_5_contract_version, source_m2_5_schema_version AS policy_source_m2_5_schema_version, source_m2_5_combined_hash AS policy_source_m2_5_combined_hash, source_m2_5_acceptance_gate_id AS policy_source_m2_5_acceptance_gate_id, recommendation_only_flag, no_merchant_contact_execution_flag, no_payment_change_execution_flag, no_write_off_charge_off_execution_flag, no_legal_or_collection_action_flag, no_external_notice_generation_flag, no_production_adverse_action_notice_flag, preserve_m2_5_history_flag, configuration_hash FROM msbf_ctl.m2_6_policy_profile WHERE module1_run_id=(SELECT run_id FROM run_context) AND policy_code='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_POLICY_V1'
),
source_registry AS (
    SELECT count(*)::bigint AS registry_rows, max(contract_status) AS source_contract_status, max(contract_code) AS source_m2_5_contract_code, max(contract_version) AS source_m2_5_contract_version, max(schema_version) AS source_m2_5_schema_version, max(combined_set_hash) AS source_m2_5_combined_hash, max(source_rows) AS source_source_rows, max(daily_rows) AS source_daily_rows, max(latest_rows) AS source_latest_rows, max(archive_rows) AS source_archive_rows, max(portfolio_daily_rows) AS source_portfolio_daily_rows, max(comparison_rows) AS source_comparison_rows, max(canonical_entities) AS source_canonical_entities, max(paid_off_rows) AS source_paid_off_rows, max(open_monitoring_rows) AS source_open_rows, max(ending_receivable_exposure_amount) AS source_ending_exposure FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)
),
source_gate AS (
    SELECT count(*)::bigint AS source_gate_rows, max(result_status) AS source_gate_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING' AND review_version=1
),
latest_source AS (
    SELECT count(*)::bigint AS source_rows, count(*) FILTER (WHERE scenario_code='BASELINE')::bigint AS baseline_rows, count(*) FILTER (WHERE scenario_code='RECESSION_ENERGY')::bigint AS stress_rows, count(*) FILTER (WHERE paid_off_flag)::bigint AS paid_off_rows, count(*) FILTER (WHERE NOT paid_off_flag)::bigint AS open_rows, count(*) FILTER (WHERE latest_monitoring_status_code='SEVERE_SHORTFALL')::bigint AS severe_shortfall_rows, round(sum(remaining_receivable_amount) FILTER (WHERE NOT paid_off_flag),2) AS open_exposure, count(*) FILTER (WHERE contract_row_hash IS NULL OR source_daily_row_hash IS NULL) AS missing_hash_rows FROM msbf_m2.advance_portfolio_monitoring_latest WHERE module1_run_id=(SELECT run_id FROM run_context)
),
reproduction AS (
    SELECT count(*)::bigint AS joined_archive_rows, count(*) FILTER (WHERE latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at'))::bigint AS archive_mismatches FROM msbf_m2.advance_portfolio_monitoring_latest AS latest FULL OUTER JOIN msbf_m2.advance_portfolio_monitoring_archive AS archive ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=(SELECT run_id FROM run_context)
),
definitions AS (
    SELECT (SELECT count(*) FROM msbf_m2.intervention_strategy_outcome_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND definition_status='APPROVED')::bigint AS outcome_rows, (SELECT count(*) FROM msbf_m2.intervention_servicing_action_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND definition_status='APPROVED')::bigint AS action_rows, (SELECT count(*) FROM msbf_m2.intervention_reason_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND definition_status='APPROVED')::bigint AS reason_rows, (SELECT count(*) FROM msbf_m2.intervention_strategy_outcome_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND executed_action_flag)::bigint AS prohibited_outcome_flags, (SELECT count(*) FROM msbf_m2.intervention_servicing_action_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND executed_servicing_action_flag)::bigint AS prohibited_action_flags, (SELECT count(*) FROM msbf_m2.intervention_reason_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND (production_adverse_action_notice_flag OR executed_servicing_action_flag))::bigint AS prohibited_reason_flags
),
gate_catalog AS (SELECT count(*)::bigint AS gate_catalog_rows FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY' AND active_flag),
targets AS (
    SELECT (SELECT count(*) FROM msbf_m2.advance_intervention_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS target_source_rows, (SELECT count(*) FROM msbf_m2.advance_intervention_strategy_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS target_strategy_rows, (SELECT count(*) FROM msbf_m2.portfolio_intervention_strategy_summary WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS target_portfolio_rows, (SELECT count(*) FROM msbf_m2.advance_intervention_strategy_latest WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS target_latest_rows, (SELECT count(*) FROM msbf_m2.advance_intervention_strategy_archive WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS target_archive_rows, (SELECT count(*) FROM msbf_ctl.m2_6_intervention_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS target_registry_rows, (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context) AND evidence_code LIKE 'M2_6_%')::bigint AS target_evidence_rows, (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY')::bigint AS target_acceptance_rows, (SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_7%')::bigint AS m2_7_tables
)
SELECT run_context.run_id, run_context.run_status, run_context.population_id, run_context.as_of_date, policy.*, source_registry.*, source_gate.*, latest_source.*, reproduction.*, definitions.*, gate_catalog.gate_catalog_rows, targets.*, CASE WHEN run_context.run_status='M2_5_ACCEPTED' AND policy.policy_status='APPROVED' AND policy.methodology_version='M2_6_METHOD_V1' AND policy.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND policy.contract_version=1 AND policy.schema_version='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1' AND policy.policy_source_m2_5_combined_hash='18e1c444aa1b02ee5bd3539d7c477adc' AND policy.recommendation_only_flag AND policy.no_merchant_contact_execution_flag AND policy.no_payment_change_execution_flag AND policy.no_write_off_charge_off_execution_flag AND policy.no_legal_or_collection_action_flag AND policy.no_external_notice_generation_flag AND policy.no_production_adverse_action_notice_flag AND policy.preserve_m2_5_history_flag AND source_registry.registry_rows=1 AND source_registry.source_contract_status='ACCEPTED' AND source_registry.source_m2_5_contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND source_registry.source_m2_5_schema_version='M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1' AND source_registry.source_m2_5_combined_hash='18e1c444aa1b02ee5bd3539d7c477adc' AND source_registry.source_latest_rows=59 AND source_registry.source_archive_rows=59 AND source_registry.source_daily_rows=7080 AND source_registry.source_portfolio_daily_rows=240 AND source_registry.source_comparison_rows=15 AND source_registry.source_canonical_entities=7536 AND source_gate.source_gate_rows=1 AND source_gate.source_gate_status='PASS' AND latest_source.source_rows=59 AND latest_source.baseline_rows=44 AND latest_source.stress_rows=15 AND latest_source.paid_off_rows=57 AND latest_source.open_rows=2 AND latest_source.severe_shortfall_rows=2 AND latest_source.open_exposure=979.73 AND latest_source.missing_hash_rows=0 AND reproduction.joined_archive_rows=59 AND reproduction.archive_mismatches=0 AND definitions.outcome_rows=7 AND definitions.action_rows=7 AND definitions.reason_rows=30 AND definitions.prohibited_outcome_flags=0 AND definitions.prohibited_action_flags=0 AND definitions.prohibited_reason_flags=0 AND gate_catalog.gate_catalog_rows=1 AND targets.target_source_rows=0 AND targets.target_strategy_rows=0 AND targets.target_portfolio_rows=0 AND targets.target_latest_rows=0 AND targets.target_archive_rows=0 AND targets.target_registry_rows=0 AND targets.target_evidence_rows=0 AND targets.target_acceptance_rows=0 AND targets.m2_7_tables=0 THEN 'PASS' ELSE 'FAIL' END AS preflight_status FROM run_context CROSS JOIN policy CROSS JOIN source_registry CROSS JOIN source_gate CROSS JOIN latest_source CROSS JOIN reproduction CROSS JOIN definitions CROSS JOIN gate_catalog CROSS JOIN targets;

DO $guard$
DECLARE v record;
BEGIN
    SELECT run_id, preflight_status INTO v FROM _m2_6_preflight;
    IF v.preflight_status <> 'PASS' THEN RAISE EXCEPTION 'M2.6 preflight failed for run_id %.', v.run_id; END IF;
    PERFORM msbf_ctl.m2_6_assert_generation_ready(v.run_id);
END;
$guard$;

SELECT * FROM _m2_6_preflight;
