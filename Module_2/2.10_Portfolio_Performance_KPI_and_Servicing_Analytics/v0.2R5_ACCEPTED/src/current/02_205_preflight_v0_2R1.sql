/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 205_msbf_m2_10_preflight_validation_v0_2.sql
Version     : v0.2

Purpose
-------
Fail closed unless accepted M2.9 lifecycle, contract, schema, gate, combined
hash, exact account-state and payment posture, M2.10 definitions, and empty
M2.10 targets are exact.

Writes
------
None. The result is session-preserved and filterable.

Required result
---------------
preflight_status = PASS.
============================================================================ */

SET statement_timeout='35min';
SET jit=off;
DROP TABLE IF EXISTS _m2_10_preflight;

CREATE TEMP TABLE _m2_10_preflight ON COMMIT PRESERVE ROWS AS
WITH run_context AS
(
 SELECT run_id,run_status,population_id,as_of_date
 FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), policy AS
(
 SELECT * FROM msbf_ctl.m2_10_policy_profile
 WHERE module1_run_id=(SELECT run_id FROM run_context)
), source_registry AS
(
 SELECT count(*)::bigint AS registry_rows,max(contract_status) AS contract_status,
  max(contract_code) AS contract_code,max(contract_version) AS contract_version,
  max(schema_version) AS schema_version,max(methodology_version) AS methodology_version,
  max(combined_set_hash) AS combined_set_hash,max(latest_rows)::bigint AS latest_rows,
  max(archive_rows)::bigint AS archive_rows,max(comparison_rows)::bigint AS comparison_rows,
  max(canonical_entities)::bigint AS canonical_entities,
  max(no_payment_activity_rows)::bigint AS no_payment_activity_rows,
  max(reconciled_after_retry_rows)::bigint AS reconciled_after_retry_rows,
  max(review_hold_rows)::bigint AS review_hold_rows,
  max(certified_closed_rows)::bigint AS certified_closed_rows,
  max(certified_reassessment_rows)::bigint AS certified_reassessment_rows,
  max(certified_review_hold_rows)::bigint AS certified_review_hold_rows,
  max(scheduled_payment_amount)::numeric(24,2) AS scheduled_payment_amount,
  max(processed_payment_amount)::numeric(24,2) AS processed_payment_amount,
  max(returned_payment_amount)::numeric(24,2) AS returned_payment_amount,
  max(retry_payment_amount)::numeric(24,2) AS retry_payment_amount,
  max(exception_amount)::numeric(24,2) AS exception_amount,
  max(reconciliation_variance_amount)::numeric(24,2) AS reconciliation_variance_amount,
  max(exposure_variance_amount)::numeric(24,2) AS exposure_variance_amount,
  max(active_certified_exposure_amount)::numeric(24,2) AS active_certified_exposure_amount,
  max(review_hold_exposure_amount)::numeric(24,2) AS review_hold_exposure_amount,
  max(portfolio_certified_exposure_amount)::numeric(24,2) AS portfolio_certified_exposure_amount,
  max(exception_opened_rows)::bigint AS exception_opened_rows,
  max(exception_resolved_rows)::bigint AS exception_resolved_rows,
  max(unresolved_exception_rows)::bigint AS unresolved_exception_rows
 FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)
), source_gate AS
(
 SELECT count(*)::bigint AS gate_rows,max(result_status) AS gate_status
 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM run_context)
   AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND review_version=1
), source_population AS
(
 SELECT count(*)::bigint AS source_rows,
  count(DISTINCT source.scenario_id::text||'|'||source.merchant_application_id)::bigint AS distinct_grain_rows,
  count(DISTINCT source.merchant_application_id)::bigint AS distinct_applications,
  count(*) FILTER(WHERE source.scenario_id IS NULL OR source.scenario_code=''
      OR source.merchant_application_id='' OR source.merchant_id=''
      OR source.synthetic_account_id='' OR source.synthetic_advance_id=''
      OR source.certified_state_code='' OR source.primary_reconciliation_reason_code=''
      OR source.contract_row_hash IS NULL
      OR jsonb_typeof(source.reconciliation_reason_codes)<>'array')::bigint AS invalid_source_rows,
  count(*) FILTER(WHERE source.scenario_code='BASELINE')::bigint AS baseline_rows,
  count(*) FILTER(WHERE source.scenario_code='RECESSION_ENERGY')::bigint AS stress_rows,
  count(*) FILTER(WHERE source.closed_state_flag AND source.state_certified_flag
      AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING')::bigint AS closed_stable_rows,
 count(*) FILTER
	(
    	WHERE source.reconciliation_outcome_code=
       	   'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
      	AND source.certified_state_code=
       	   'CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
      	AND source.state_certified_flag IS TRUE
      	AND source.active_state_flag IS TRUE
      	AND source.closed_state_flag IS FALSE
      	AND source.review_hold_state_flag IS FALSE
      	AND source.exception_resolved_flag IS TRUE
      	AND source.unresolved_exception_count=0
      	AND source.reconciliation_variance_amount=0
      	AND source.exposure_variance_amount=0
	)::bigint AS active_reconciled_rows,
  count(*) FILTER(WHERE source.review_hold_state_flag AND source.state_certified_flag
      AND source.certified_state_code='CERTIFIED_REVIEW_HOLD')::bigint AS controlled_review_rows,
  count(*) FILTER(WHERE source.state_certified_flag)::bigint AS certified_account_rows,
  round(sum(source.certified_exposure_amount),2) AS certified_exposure_amount,
  round(sum(CASE WHEN source.active_state_flag THEN source.certified_exposure_amount ELSE 0 END),2) AS active_exposure_amount,
  round(sum(CASE WHEN source.review_hold_state_flag THEN source.certified_exposure_amount ELSE 0 END),2) AS review_hold_exposure_amount,
  round(sum(source.scheduled_payment_amount),2) AS scheduled_payment_amount,
  round(sum(source.processed_payment_amount),2) AS processed_payment_amount,
  round(sum(source.returned_payment_amount),2) AS returned_payment_amount,
  round(sum(source.retry_payment_amount),2) AS retry_payment_amount,
  round(sum(abs(source.reconciliation_variance_amount)),2) AS reconciliation_variance_amount,
  round(sum(abs(source.exposure_variance_amount)),2) AS exposure_variance_amount,
  sum(source.exception_case_count)::bigint AS exception_case_count,
  sum(source.resolved_exception_count)::bigint AS resolved_exception_count,
  sum(source.unresolved_exception_count)::bigint AS unresolved_exception_count
 FROM msbf_m2.application_payment_reconciliation_certification_latest AS source
 WHERE source.module1_run_id=(SELECT run_id FROM run_context)
), definitions AS
(
 SELECT (SELECT count(*) FROM msbf_m2.portfolio_kpi_definition
          WHERE module1_run_id=(SELECT run_id FROM run_context) AND definition_status='APPROVED')::bigint AS kpi_definition_rows,
        (SELECT count(*) FROM msbf_m2.portfolio_performance_tier_definition
          WHERE module1_run_id=(SELECT run_id FROM run_context) AND definition_status='APPROVED')::bigint AS performance_tier_rows,
        (SELECT count(*) FROM msbf_m2.servicing_queue_definition
          WHERE module1_run_id=(SELECT run_id FROM run_context) AND definition_status='APPROVED')::bigint AS servicing_queue_rows,
        (SELECT count(*) FROM msbf_m2.portfolio_analytics_reason_definition
          WHERE module1_run_id=(SELECT run_id FROM run_context) AND definition_status='APPROVED')::bigint AS reason_rows,
        (SELECT count(*) FROM msbf_m2.portfolio_analytics_reason_definition
          WHERE module1_run_id=(SELECT run_id FROM run_context) AND production_action_flag)::bigint AS prohibited_definition_flags
), targets AS
(
 SELECT (SELECT count(*) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS target_source_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS target_account_performance_rows,
  (SELECT count(*) FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM run_context)) AS target_scope_summary_rows,
  (SELECT count(*) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS target_kpi_snapshot_rows,
  (SELECT count(*) FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS target_queue_summary_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=(SELECT run_id FROM run_context)) AS target_latest_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_archive WHERE module1_run_id=(SELECT run_id FROM run_context)) AS target_archive_rows,
  (SELECT count(*) FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)) AS target_registry_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context) AND evidence_code LIKE 'M2_10_%') AS target_evidence_rows,
  (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS') AS target_acceptance_rows,
  (SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_11%') AS premature_m2_11_tables,
  (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2'
    AND table_name IN ('application_portfolio_performance_snapshot','portfolio_performance_scope_summary',
      'portfolio_kpi_snapshot','servicing_queue_analytics_snapshot','application_portfolio_performance_latest',
      'application_portfolio_performance_archive')
    AND lower(column_name) IN ('production_decision','production_strategy_change','real_funds_moved',
      'external_system_updated','merchant_contact_executed','write_off_posted','collection_agency_referral',
      'legal_action_executed','external_notice_payload','production_adverse_action_notice')) AS prohibited_columns
)
SELECT run_context.run_id,run_context.run_status,run_context.population_id,run_context.as_of_date,
 policy.policy_status,policy.methodology_version,policy.contract_code,policy.contract_version,
 policy.schema_version,policy.source_contract_code AS policy_source_contract_code,
 policy.source_contract_version AS policy_source_contract_version,
 policy.source_schema_version AS policy_source_schema_version,
 policy.source_acceptance_gate_id AS policy_source_acceptance_gate_id,
 policy.source_combined_set_hash AS policy_source_combined_set_hash,policy.configuration_hash,
 source_registry.registry_rows AS source_registry_rows,
 source_registry.contract_status AS source_contract_status,
 source_registry.contract_code AS source_contract_code,
 source_registry.contract_version AS source_contract_version,
 source_registry.schema_version AS source_schema_version,
 source_registry.methodology_version AS source_methodology_version,
 source_registry.combined_set_hash AS source_combined_set_hash,
 source_registry.latest_rows AS source_latest_rows,
 source_registry.archive_rows AS source_archive_rows,
 source_registry.comparison_rows AS source_comparison_rows,
 source_registry.canonical_entities AS source_canonical_entities,
 source_registry.no_payment_activity_rows AS source_no_payment_activity_rows,
 source_registry.reconciled_after_retry_rows AS source_reconciled_after_retry_rows,
 source_registry.review_hold_rows AS source_review_hold_rows,
 source_registry.certified_closed_rows AS source_certified_closed_rows,
 source_registry.certified_reassessment_rows AS source_certified_reassessment_rows,
 source_registry.certified_review_hold_rows AS source_certified_review_hold_rows,
 source_gate.gate_rows AS source_gate_rows,source_gate.gate_status AS source_gate_status,
 source_population.source_rows,source_population.distinct_grain_rows,
 source_population.distinct_applications,source_population.invalid_source_rows,
 source_population.baseline_rows,source_population.stress_rows,
 source_population.closed_stable_rows,source_population.active_reconciled_rows,
 source_population.controlled_review_rows,source_population.certified_account_rows,
 source_population.certified_exposure_amount,source_population.active_exposure_amount,
 source_population.review_hold_exposure_amount,source_population.scheduled_payment_amount,
 source_population.processed_payment_amount,source_population.returned_payment_amount,
 source_population.retry_payment_amount,source_population.reconciliation_variance_amount,
 source_population.exposure_variance_amount,source_population.exception_case_count,
 source_population.resolved_exception_count,source_population.unresolved_exception_count,
 definitions.kpi_definition_rows,definitions.performance_tier_rows,
 definitions.servicing_queue_rows,definitions.reason_rows,definitions.prohibited_definition_flags,
 targets.*,
 CASE WHEN run_context.run_status='M2_9_ACCEPTED'
  AND policy.policy_status='APPROVED' AND policy.methodology_version='M2_10_METHOD_V1'
  AND policy.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND policy.contract_version=1
  AND policy.schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1' AND policy.source_contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'
  AND policy.source_contract_version=1 AND policy.source_schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'
  AND policy.source_acceptance_gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'
  AND policy.source_combined_set_hash='6af76d0059b47623619ebc09330b15fe'
  AND policy.synthetic_data_only_flag AND policy.analytics_only_flag
  AND policy.preserve_m2_9_history_flag AND policy.no_production_decisioning_flag
  AND policy.no_real_funds_movement_flag AND policy.no_external_system_update_flag
  AND policy.no_merchant_contact_flag AND policy.no_write_off_collection_legal_flag
  AND source_registry.registry_rows=1 AND source_registry.contract_status='ACCEPTED'
  AND source_registry.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND source_registry.contract_version=1
  AND source_registry.schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'
  AND source_registry.methodology_version='M2_9_METHOD_V1'
  AND source_registry.combined_set_hash='6af76d0059b47623619ebc09330b15fe'
  AND source_registry.latest_rows=59 AND source_registry.archive_rows=59
  AND source_registry.comparison_rows=15 AND source_registry.canonical_entities=438
  AND source_registry.no_payment_activity_rows=57 AND source_registry.reconciled_after_retry_rows=1
  AND source_registry.review_hold_rows=1 AND source_registry.certified_closed_rows=57
  AND source_registry.certified_reassessment_rows=1 AND source_registry.certified_review_hold_rows=1
  AND source_registry.scheduled_payment_amount=194.25 AND source_registry.processed_payment_amount=194.25
  AND source_registry.returned_payment_amount=27.75 AND source_registry.retry_payment_amount=27.75
  AND source_registry.exception_amount=27.75 AND source_registry.reconciliation_variance_amount=0
  AND source_registry.exposure_variance_amount=0 AND source_registry.active_certified_exposure_amount=323.79
  AND source_registry.review_hold_exposure_amount=461.69
  AND source_registry.portfolio_certified_exposure_amount=785.48
  AND source_registry.exception_opened_rows=1 AND source_registry.exception_resolved_rows=1
  AND source_registry.unresolved_exception_rows=0
  AND source_gate.gate_rows=1 AND source_gate.gate_status='PASS'
  AND source_population.source_rows=59 AND source_population.distinct_grain_rows=59
  AND source_population.invalid_source_rows=0 AND source_population.baseline_rows=44
  AND source_population.stress_rows=15 AND source_population.closed_stable_rows=57
  AND source_population.active_reconciled_rows=1 AND source_population.controlled_review_rows=1
  AND source_population.certified_account_rows=59 AND source_population.certified_exposure_amount=785.48
  AND source_population.active_exposure_amount=323.79 AND source_population.review_hold_exposure_amount=461.69
  AND source_population.scheduled_payment_amount=194.25 AND source_population.processed_payment_amount=194.25
  AND source_population.returned_payment_amount=27.75 AND source_population.retry_payment_amount=27.75
  AND source_population.reconciliation_variance_amount=0 AND source_population.exposure_variance_amount=0
  AND source_population.exception_case_count=1 AND source_population.resolved_exception_count=1
  AND source_population.unresolved_exception_count=0
  AND definitions.kpi_definition_rows=24 AND definitions.performance_tier_rows=3
  AND definitions.servicing_queue_rows=3 AND definitions.reason_rows=24
  AND definitions.prohibited_definition_flags=0
  AND targets.target_source_rows=0 AND targets.target_account_performance_rows=0
  AND targets.target_scope_summary_rows=0 AND targets.target_kpi_snapshot_rows=0
  AND targets.target_queue_summary_rows=0 AND targets.target_latest_rows=0
  AND targets.target_archive_rows=0 AND targets.target_registry_rows=0
  AND targets.target_evidence_rows=0 AND targets.target_acceptance_rows=0
  AND targets.premature_m2_11_tables=0 AND targets.prohibited_columns=0
 THEN 'PASS' ELSE 'FAIL' END AS preflight_status
FROM run_context CROSS JOIN policy CROSS JOIN source_registry CROSS JOIN source_gate
CROSS JOIN source_population CROSS JOIN definitions CROSS JOIN targets;

DO $m2_10_preflight_guard$
DECLARE v record;
BEGIN
 SELECT * INTO v FROM _m2_10_preflight;
 IF v.preflight_status<>'PASS' THEN
  RAISE EXCEPTION 'M2.10 preflight failed: %.',row_to_json(v);
 END IF;
 PERFORM msbf_ctl.m2_10_assert_generation_ready(v.run_id);
END;
$m2_10_preflight_guard$;

SELECT * FROM _m2_10_preflight;
