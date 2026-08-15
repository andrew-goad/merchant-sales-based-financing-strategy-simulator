/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 206B_msbf_m2_10_generation_reconciliation_reconstructed_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Read-only reconstruction of Program 206's committed checkpoint if DBeaver
loses or suppresses the successful result tab.

Required result
---------------
generation_reconstruction_status = PASS.
============================================================================ */

WITH run_context AS
(
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), registry AS
(
 SELECT * FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
 WHERE module1_run_id=(SELECT run_id FROM run_context)
), physical AS
(
 SELECT
  (SELECT count(*) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS source_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS account_performance_rows,
  (SELECT count(*) FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM run_context)) AS scope_summary_rows,
  (SELECT count(*) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS kpi_snapshot_rows,
  (SELECT count(*) FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS queue_summary_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=(SELECT run_id FROM run_context)) AS latest_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_archive WHERE module1_run_id=(SELECT run_id FROM run_context)) AS archive_rows,
  (SELECT count(*) FROM msbf_m2.v_m2_10_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context)) AS comparison_rows,
  (SELECT canonical_entities FROM msbf_m2.v_m2_10_canonical_hash WHERE module1_run_id=(SELECT run_id FROM run_context)) AS canonical_entities,
  (SELECT combined_set_hash FROM msbf_m2.v_m2_10_canonical_hash WHERE module1_run_id=(SELECT run_id FROM run_context)) AS physical_combined_set_hash,
  (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context)
    AND evidence_code LIKE 'M2_10_%' AND evidence_code NOT LIKE 'M2_10_POS_%'
    AND evidence_code NOT LIKE 'M2_10_NEG_%' AND evidence_code<>'M2_10_ACCEPTANCE_SUMMARY') AS generation_evidence_rows,
  (SELECT count(*) FROM msbf_m2.v_m2_10_matched_scenario_comparison
    WHERE module1_run_id=(SELECT run_id FROM run_context)
    AND (stress_tier_improvement_flag OR stress_burden_improvement_flag OR stress_exposure_improvement_flag)) AS stress_improvement_rows
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
)
SELECT run_context.run_status,registry.contract_status,physical.*,mapping.mapping_errors,
 registry.portfolio_account_rows,registry.baseline_account_rows,
 registry.stress_account_rows,registry.closed_stable_rows,
 registry.active_reconciled_rows,registry.controlled_review_rows,
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
 registry.policy_set_hash,registry.kpi_definition_set_hash,
 registry.performance_tier_set_hash,registry.servicing_queue_set_hash,
 registry.reason_set_hash,registry.source_set_hash,
 registry.account_performance_set_hash,registry.scope_summary_set_hash,
 registry.kpi_snapshot_set_hash,registry.queue_summary_set_hash,
 registry.latest_set_hash,registry.archive_set_hash,
 registry.contract_set_hash,registry.combined_set_hash,
 CASE WHEN run_context.run_status IN ('M2_10_GENERATED','M2_10_VALIDATED','M2_10_ACCEPTED')
  AND registry.contract_status IN ('GENERATED','VALIDATED','ACCEPTED')
  AND physical.source_rows=59 AND physical.account_performance_rows=59
  AND physical.scope_summary_rows=3 AND physical.kpi_snapshot_rows=72
  AND physical.queue_summary_rows=3 AND physical.latest_rows=59
  AND physical.archive_rows=59 AND physical.comparison_rows=15
  AND physical.canonical_entities=370 AND physical.generation_evidence_rows=24
  AND physical.stress_improvement_rows=0
  AND mapping.mapping_errors=0
  AND registry.portfolio_account_rows=59 AND registry.baseline_account_rows=44
  AND registry.stress_account_rows=15 AND registry.closed_stable_rows=57
  AND registry.active_reconciled_rows=1 AND registry.controlled_review_rows=1
  AND registry.certified_account_rows=59 AND registry.certification_rate=1
  AND registry.certified_exposure_amount=785.48
  AND registry.active_exposure_amount=323.79
  AND registry.review_hold_exposure_amount=461.69
  AND registry.scheduled_payment_amount=194.25
  AND registry.processed_payment_amount=194.25
  AND registry.gross_collection_rate=1
  AND registry.returned_payment_amount=27.75
  AND registry.return_rate=0.142857
  AND registry.retry_payment_amount=27.75 AND registry.retry_cure_rate=1
  AND registry.reconciliation_variance_amount=0
  AND registry.exposure_variance_amount=0
  AND registry.exception_case_count=1 AND registry.resolved_exception_count=1
  AND registry.exception_resolution_rate=1 AND registry.unresolved_exception_count=0
  AND registry.servicing_burden_units=7
  AND registry.average_burden_per_account=0.118644
  AND registry.combined_set_hash IS NOT DISTINCT FROM physical.physical_combined_set_hash
 THEN 'PASS' ELSE 'FAIL' END AS generation_reconstruction_status
FROM run_context CROSS JOIN registry CROSS JOIN physical CROSS JOIN mapping;
