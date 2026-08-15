/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 207A_msbf_m2_10_failed_positive_validation_recovery_check_v0_2R2.sql
Version     : v0.2R2

Purpose
-------
Run only after stopping a failed Program 207 and executing ROLLBACK. Prove that
no partial validation, negative, or acceptance evidence remains; that the
committed Program 206 population remains exact; and that its accepted
generation combined hash remains available before the corrected validation.

Required result
---------------
recovery_status = PASS.
============================================================================ */

WITH run_context AS
(
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), registry AS
(
 SELECT contract_status,source_rows,account_performance_rows,scope_summary_rows,
  kpi_snapshot_rows,queue_summary_rows,latest_rows,archive_rows,comparison_rows,
  canonical_entities,combined_set_hash
 FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
 WHERE module1_run_id=(SELECT run_id FROM run_context)
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
), evidence AS
(
 SELECT count(*) FILTER(WHERE evidence_code LIKE 'M2_10_POS_%') AS positive_rows,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_NEG_%') AS negative_rows,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_%'
   AND evidence_code NOT LIKE 'M2_10_POS_%' AND evidence_code NOT LIKE 'M2_10_NEG_%'
   AND evidence_code<>'M2_10_ACCEPTANCE_SUMMARY') AS generation_rows,
  count(*) FILTER(WHERE evidence_code='M2_10_ACCEPTANCE_SUMMARY') AS acceptance_rows
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context)
), gate AS
(
 SELECT count(*) AS gate_rows FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
)
SELECT run_context.run_status,registry.*,mapping.mapping_errors,evidence.*,gate.gate_rows,
 CASE WHEN run_context.run_status='M2_10_GENERATED' AND registry.contract_status='GENERATED'
  AND registry.source_rows=59 AND registry.account_performance_rows=59
  AND registry.scope_summary_rows=3 AND registry.kpi_snapshot_rows=72
  AND registry.queue_summary_rows=3 AND registry.latest_rows=59
  AND registry.archive_rows=59 AND registry.comparison_rows=15
  AND registry.canonical_entities=370 AND mapping.mapping_errors=0
  AND evidence.positive_rows=0
  AND evidence.negative_rows=0 AND evidence.generation_rows=24
  AND evidence.acceptance_rows=0 AND gate.gate_rows=0
 THEN 'PASS' ELSE 'FAIL' END AS recovery_status
FROM run_context CROSS JOIN registry CROSS JOIN mapping CROSS JOIN evidence CROSS JOIN gate;
