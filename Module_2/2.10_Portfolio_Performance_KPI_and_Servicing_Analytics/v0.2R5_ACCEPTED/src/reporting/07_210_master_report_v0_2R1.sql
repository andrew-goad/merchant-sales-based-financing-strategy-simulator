/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 210_MSBF_M2_10_Master_Report_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Produce one executive/governance summary row after formal M2.10 acceptance,
reconciling lifecycle, source identity, account facts, KPI and queue posture,
evidence, analytics-only boundaries, latest/archive reproduction, stress
non-improvement, and canonical identity.

Writes
------
None.

Required result
---------------
overall_m2_10_status = PASS.
============================================================================ */

SET statement_timeout='40min';
SET jit=off;

/* ============================================================================
Section 1 — Reconstruct lifecycle, accepted-source, evidence, and mappings
============================================================================ */

WITH run_context AS
(
 SELECT run_id,run_code,run_version,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), policy AS
(
 SELECT * FROM msbf_ctl.m2_10_policy_profile
 WHERE module1_run_id=(SELECT run_id FROM run_context)
), registry AS
(
 SELECT * FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
 WHERE module1_run_id=(SELECT run_id FROM run_context)
), source_registry AS
(
 SELECT contract_status,contract_code,contract_version,schema_version,
  methodology_version,combined_set_hash
 FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry
 WHERE module1_run_id=(SELECT run_id FROM run_context)
), source_gate AS
(
 SELECT result_status AS source_gate_status
 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM run_context)
   AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'
   AND review_version=1
), mapping AS
(
 SELECT count(*)::bigint AS mapping_errors
 FROM msbf_m2.portfolio_performance_source_snapshot AS source
 FULL OUTER JOIN msbf_m2.application_portfolio_performance_snapshot AS performance
   ON performance.module1_run_id=source.module1_run_id
  AND performance.scenario_id=source.scenario_id
  AND performance.merchant_application_id=source.merchant_application_id
 WHERE coalesce(source.module1_run_id,performance.module1_run_id)=(SELECT run_id FROM run_context)
   AND
   (
       source.row_hash IS NULL
       OR performance.row_hash IS NULL
       OR (CASE
        WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
        AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
        AND source.state_certified_flag IS TRUE
        AND source.closed_state_flag IS TRUE
        AND source.active_state_flag IS FALSE
        AND source.review_hold_state_flag IS FALSE
        AND source.exception_resolved_flag IS FALSE
        AND source.exception_case_count=0
        AND source.resolved_exception_count=0
        AND source.unresolved_exception_count=0
        AND source.certified_exposure_amount=0
        AND source.scheduled_payment_amount=0
        AND source.processed_payment_amount=0
        AND source.returned_payment_amount=0
        AND source.retry_payment_amount=0
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'CLOSED_STABLE'
        WHEN source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
        AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
        AND source.state_certified_flag IS TRUE
        AND source.active_state_flag IS TRUE
        AND source.closed_state_flag IS FALSE
        AND source.review_hold_state_flag IS FALSE
        AND source.exception_resolved_flag IS TRUE
        AND source.exception_case_count=1
        AND source.resolved_exception_count=1
        AND source.unresolved_exception_count=0
        AND source.payment_event_count=7
        AND source.settled_event_count=5
        AND source.returned_event_count=1
        AND source.retry_event_count=1
        AND source.certified_exposure_amount=323.79
        AND source.scheduled_payment_amount=194.25
        AND source.processed_payment_amount=194.25
        AND source.returned_payment_amount=27.75
        AND source.retry_payment_amount=27.75
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'ACTIVE_RECONCILED'
        WHEN source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
        AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
        AND source.state_certified_flag IS TRUE
        AND source.review_hold_state_flag IS TRUE
        AND source.active_state_flag IS FALSE
        AND source.closed_state_flag IS FALSE
        AND source.exception_resolved_flag IS FALSE
        AND source.exception_case_count=0
        AND source.resolved_exception_count=0
        AND source.unresolved_exception_count=0
        AND source.certified_exposure_amount=461.69
        AND source.scheduled_payment_amount=0
        AND source.processed_payment_amount=0
        AND source.returned_payment_amount=0
        AND source.retry_payment_amount=0
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'CONTROLLED_REVIEW'
        ELSE 'SOURCE_MAPPING_ERROR'
    END) IS DISTINCT FROM performance.performance_tier_code
       OR (CASE
        WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
        AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
        AND source.state_certified_flag IS TRUE
        AND source.closed_state_flag IS TRUE
        AND source.active_state_flag IS FALSE
        AND source.review_hold_state_flag IS FALSE
        AND source.exception_resolved_flag IS FALSE
        AND source.exception_case_count=0
        AND source.resolved_exception_count=0
        AND source.unresolved_exception_count=0
        AND source.certified_exposure_amount=0
        AND source.scheduled_payment_amount=0
        AND source.processed_payment_amount=0
        AND source.returned_payment_amount=0
        AND source.retry_payment_amount=0
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'NO_SERVICING_REQUIRED'
        WHEN source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
        AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
        AND source.state_certified_flag IS TRUE
        AND source.active_state_flag IS TRUE
        AND source.closed_state_flag IS FALSE
        AND source.review_hold_state_flag IS FALSE
        AND source.exception_resolved_flag IS TRUE
        AND source.exception_case_count=1
        AND source.resolved_exception_count=1
        AND source.unresolved_exception_count=0
        AND source.payment_event_count=7
        AND source.settled_event_count=5
        AND source.returned_event_count=1
        AND source.retry_event_count=1
        AND source.certified_exposure_amount=323.79
        AND source.scheduled_payment_amount=194.25
        AND source.processed_payment_amount=194.25
        AND source.returned_payment_amount=27.75
        AND source.retry_payment_amount=27.75
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'ACTIVE_REASSESSMENT'
        WHEN source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
        AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
        AND source.state_certified_flag IS TRUE
        AND source.review_hold_state_flag IS TRUE
        AND source.active_state_flag IS FALSE
        AND source.closed_state_flag IS FALSE
        AND source.exception_resolved_flag IS FALSE
        AND source.exception_case_count=0
        AND source.resolved_exception_count=0
        AND source.unresolved_exception_count=0
        AND source.certified_exposure_amount=461.69
        AND source.scheduled_payment_amount=0
        AND source.processed_payment_amount=0
        AND source.returned_payment_amount=0
        AND source.retry_payment_amount=0
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'GOVERNANCE_REVIEW_HOLD'
        ELSE 'SOURCE_MAPPING_ERROR'
    END) IS DISTINCT FROM performance.servicing_queue_code
       OR (CASE
        WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
        AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
        AND source.state_certified_flag IS TRUE
        AND source.closed_state_flag IS TRUE
        AND source.active_state_flag IS FALSE
        AND source.review_hold_state_flag IS FALSE
        AND source.exception_resolved_flag IS FALSE
        AND source.exception_case_count=0
        AND source.resolved_exception_count=0
        AND source.unresolved_exception_count=0
        AND source.certified_exposure_amount=0
        AND source.scheduled_payment_amount=0
        AND source.processed_payment_amount=0
        AND source.returned_payment_amount=0
        AND source.retry_payment_amount=0
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'M2_10_REASON_CLOSED_STABLE'
        WHEN source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
        AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
        AND source.state_certified_flag IS TRUE
        AND source.active_state_flag IS TRUE
        AND source.closed_state_flag IS FALSE
        AND source.review_hold_state_flag IS FALSE
        AND source.exception_resolved_flag IS TRUE
        AND source.exception_case_count=1
        AND source.resolved_exception_count=1
        AND source.unresolved_exception_count=0
        AND source.payment_event_count=7
        AND source.settled_event_count=5
        AND source.returned_event_count=1
        AND source.retry_event_count=1
        AND source.certified_exposure_amount=323.79
        AND source.scheduled_payment_amount=194.25
        AND source.processed_payment_amount=194.25
        AND source.returned_payment_amount=27.75
        AND source.retry_payment_amount=27.75
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'M2_10_REASON_ACTIVE_RECONCILED'
        WHEN source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
        AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
        AND source.state_certified_flag IS TRUE
        AND source.review_hold_state_flag IS TRUE
        AND source.active_state_flag IS FALSE
        AND source.closed_state_flag IS FALSE
        AND source.exception_resolved_flag IS FALSE
        AND source.exception_case_count=0
        AND source.resolved_exception_count=0
        AND source.unresolved_exception_count=0
        AND source.certified_exposure_amount=461.69
        AND source.scheduled_payment_amount=0
        AND source.processed_payment_amount=0
        AND source.returned_payment_amount=0
        AND source.retry_payment_amount=0
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'M2_10_REASON_CONTROLLED_REVIEW'
        ELSE 'M2_10_REASON_SOURCE_MAPPING_ERROR'
    END) IS DISTINCT FROM performance.primary_portfolio_reason_code
   )
), gate AS
(
 SELECT result_status AS gate_status FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND review_version=1
), evidence AS
(
 SELECT count(*) FILTER(WHERE evidence_code LIKE 'M2_10_POS_%' AND status='PASS') AS positive_passes,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_POS_%') AS positive_checks,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_NEG_%' AND status='PASS') AS negative_passes,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_NEG_%') AS negative_checks,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_%'
   AND evidence_code NOT LIKE 'M2_10_POS_%' AND evidence_code NOT LIKE 'M2_10_NEG_%'
   AND evidence_code<>'M2_10_ACCEPTANCE_SUMMARY') AS generation_evidence_rows,
  count(*) FILTER(WHERE evidence_code='M2_10_ACCEPTANCE_SUMMARY' AND status='PASS') AS acceptance_evidence_rows,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_%' AND status='FAIL') AS failed_evidence_rows
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context)
), scope AS
(
 SELECT * FROM msbf_m2.portfolio_performance_scope_summary
 WHERE module1_run_id=(SELECT run_id FROM run_context) AND scope_code='PORTFOLIO_ALL'
), diagnostics AS
(
 SELECT
  (SELECT canonical_entities FROM msbf_m2.v_m2_10_canonical_hash
   WHERE module1_run_id=(SELECT run_id FROM run_context)) AS physical_canonical_entities,
  (SELECT combined_set_hash FROM msbf_m2.v_m2_10_canonical_hash
   WHERE module1_run_id=(SELECT run_id FROM run_context)) AS physical_combined_set_hash,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot
   WHERE module1_run_id=(SELECT run_id FROM run_context)
    AND (production_decision_executed_flag OR external_system_updated_flag OR merchant_contact_executed_flag)) AS boundary_rows,
  (SELECT count(*) FROM msbf_m2.v_m2_10_matched_scenario_comparison
   WHERE module1_run_id=(SELECT run_id FROM run_context)
    AND (stress_tier_improvement_flag OR stress_burden_improvement_flag OR stress_exposure_improvement_flag)) AS stress_improvement_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest AS latest
   FULL OUTER JOIN msbf_m2.application_portfolio_performance_archive AS archive
    ON archive.module1_run_id=latest.module1_run_id
   AND archive.contract_version=latest.contract_version
   AND archive.scenario_id=latest.scenario_id
   AND archive.merchant_application_id=latest.merchant_application_id
   WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=(SELECT run_id FROM run_context)
    AND (latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash
     OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at'))) AS archive_mismatches,
  (SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('msbf_ctl','msbf_m2')
   AND lower(table_name) LIKE 'm2_11%') AS premature_m2_11_tables,
  (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2'
   AND table_name IN ('application_portfolio_performance_snapshot','portfolio_performance_scope_summary',
    'portfolio_kpi_snapshot','servicing_queue_analytics_snapshot','application_portfolio_performance_latest',
    'application_portfolio_performance_archive')
   AND lower(column_name) IN ('production_decision','production_strategy_change','real_funds_moved',
    'external_system_updated','merchant_contact_executed','write_off_posted',
    'collection_agency_referral','legal_action_executed','external_notice_payload',
    'production_adverse_action_notice')) AS prohibited_columns,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error
   WHERE run_id=(SELECT run_id FROM run_context) AND severity='BLOCKING') AS blocking_errors
)
/* ============================================================================
Section 2 — Executive governed checkpoint
============================================================================ */

SELECT run_context.run_code,run_context.run_version,run_context.run_status,
 policy.policy_code,policy.policy_version,policy.policy_status,
 policy.methodology_version,policy.contract_code,policy.contract_version,
 policy.schema_version,policy.source_contract_code,policy.source_contract_version,
 policy.source_schema_version,policy.source_acceptance_gate_id,
 policy.source_combined_set_hash,policy.configuration_hash,
 source_registry.contract_status AS source_contract_status,
 source_registry.contract_code AS physical_source_contract_code,
 source_registry.contract_version AS physical_source_contract_version,
 source_registry.schema_version AS physical_source_schema_version,
 source_registry.methodology_version AS physical_source_methodology_version,
 source_registry.combined_set_hash AS physical_source_combined_set_hash,
 source_gate.source_gate_status,mapping.mapping_errors,
 registry.contract_status,gate.gate_status,
 registry.policy_rows,registry.kpi_definition_rows,registry.performance_tier_rows,
 registry.servicing_queue_rows,registry.reason_rows,registry.source_rows,
 registry.account_performance_rows,registry.scope_summary_rows,
 registry.kpi_snapshot_rows,registry.queue_summary_rows,registry.latest_rows,
 registry.archive_rows,registry.comparison_rows,registry.registry_rows,
 registry.canonical_entities,registry.portfolio_account_rows,
 registry.baseline_account_rows,registry.stress_account_rows,
 registry.closed_stable_rows,registry.active_reconciled_rows,
 registry.controlled_review_rows,registry.no_servicing_queue_rows,
 registry.active_reassessment_queue_rows,registry.governance_review_queue_rows,
 registry.certified_account_rows,registry.certification_rate,
 registry.certified_exposure_amount,registry.active_exposure_amount,
 registry.review_hold_exposure_amount,registry.scheduled_payment_amount,
 registry.processed_payment_amount,registry.gross_collection_rate,
 registry.returned_payment_amount,registry.return_rate,
 registry.retry_payment_amount,registry.retry_cure_rate,
 registry.reconciliation_variance_amount,registry.exposure_variance_amount,
 registry.exception_case_count,registry.resolved_exception_count,
 registry.exception_resolution_rate,registry.unresolved_exception_count,
 registry.servicing_burden_units,registry.average_burden_per_account,
 evidence.positive_passes,evidence.positive_checks,evidence.negative_passes,
 evidence.negative_checks,evidence.generation_evidence_rows,
 evidence.acceptance_evidence_rows,evidence.failed_evidence_rows,
 diagnostics.boundary_rows,diagnostics.physical_canonical_entities,
 diagnostics.stress_improvement_rows,diagnostics.archive_mismatches,
 diagnostics.premature_m2_11_tables,diagnostics.prohibited_columns,
 diagnostics.blocking_errors,
 registry.policy_set_hash,registry.kpi_definition_set_hash,
 registry.performance_tier_set_hash,registry.servicing_queue_set_hash,
 registry.reason_set_hash,registry.source_set_hash,
 registry.account_performance_set_hash,registry.scope_summary_set_hash,
 registry.kpi_snapshot_set_hash,registry.queue_summary_set_hash,
 registry.latest_set_hash,registry.archive_set_hash,
 registry.contract_set_hash,registry.combined_set_hash,
 CASE WHEN run_context.run_status='M2_10_ACCEPTED'
  AND policy.policy_status='APPROVED' AND policy.synthetic_data_only_flag
  AND policy.analytics_only_flag AND policy.preserve_m2_9_history_flag
  AND policy.no_production_decisioning_flag AND policy.no_real_funds_movement_flag
  AND policy.no_external_system_update_flag AND policy.no_merchant_contact_flag
  AND policy.no_write_off_collection_legal_flag
  AND source_registry.contract_status='ACCEPTED'
  AND source_registry.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'
  AND source_registry.contract_version=1
  AND source_registry.schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'
  AND source_registry.methodology_version='M2_9_METHOD_V1'
  AND source_registry.combined_set_hash='6af76d0059b47623619ebc09330b15fe'
  AND source_gate.source_gate_status='PASS'
  AND mapping.mapping_errors=0
  AND registry.contract_status='ACCEPTED' AND gate.gate_status='PASS'
  AND registry.policy_rows=1 AND registry.kpi_definition_rows=24
  AND registry.performance_tier_rows=3 AND registry.servicing_queue_rows=3
  AND registry.reason_rows=24 AND registry.source_rows=59
  AND registry.account_performance_rows=59 AND registry.scope_summary_rows=3
  AND registry.kpi_snapshot_rows=72 AND registry.queue_summary_rows=3
  AND registry.latest_rows=59 AND registry.archive_rows=59
  AND registry.comparison_rows=15 AND registry.registry_rows=1
  AND registry.canonical_entities=370 AND registry.portfolio_account_rows=59
  AND registry.baseline_account_rows=44 AND registry.stress_account_rows=15
  AND registry.closed_stable_rows=57 AND registry.active_reconciled_rows=1
  AND registry.controlled_review_rows=1 AND registry.certified_account_rows=59
  AND registry.certification_rate=1 AND registry.certified_exposure_amount=785.48
  AND registry.active_exposure_amount=323.79
  AND registry.review_hold_exposure_amount=461.69
  AND registry.scheduled_payment_amount=194.25
  AND registry.processed_payment_amount=194.25
  AND registry.gross_collection_rate=1 AND registry.returned_payment_amount=27.75
  AND registry.return_rate=0.142857 AND registry.retry_payment_amount=27.75
  AND registry.retry_cure_rate=1 AND registry.reconciliation_variance_amount=0
  AND registry.exposure_variance_amount=0 AND registry.exception_case_count=1
  AND registry.resolved_exception_count=1 AND registry.exception_resolution_rate=1
  AND registry.unresolved_exception_count=0 AND registry.servicing_burden_units=7
  AND registry.average_burden_per_account=0.118644
  AND evidence.positive_passes=120 AND evidence.positive_checks=120
  AND evidence.negative_passes=20 AND evidence.negative_checks=20
  AND evidence.generation_evidence_rows=24 AND evidence.acceptance_evidence_rows=1
  AND evidence.failed_evidence_rows=0 AND diagnostics.boundary_rows=0
  AND diagnostics.physical_canonical_entities=370
  AND registry.combined_set_hash IS NOT DISTINCT FROM diagnostics.physical_combined_set_hash
  AND diagnostics.stress_improvement_rows=0 AND diagnostics.archive_mismatches=0
  AND diagnostics.premature_m2_11_tables=0
  AND diagnostics.prohibited_columns=0 AND diagnostics.blocking_errors=0
 THEN 'PASS' ELSE 'FAIL' END AS overall_m2_10_status
FROM run_context CROSS JOIN policy CROSS JOIN source_registry CROSS JOIN source_gate
CROSS JOIN mapping CROSS JOIN registry CROSS JOIN gate CROSS JOIN evidence
CROSS JOIN scope CROSS JOIN diagnostics;
