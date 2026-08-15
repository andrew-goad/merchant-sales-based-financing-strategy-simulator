/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 206A_msbf_m2_10_failed_generation_recovery_check_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Read-only proof after failed or cancelled Program 206. Execute ROLLBACK first.
Programs 204 and 205 remain authoritative and every generated M2.10 target
must remain empty.

Required result
---------------
recovery_status = PASS.
============================================================================ */

WITH run_context AS
(
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), source_posture AS
(
 SELECT
  count(*) FILTER(WHERE source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
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
        AND source.exposure_variance_amount=0)::bigint AS closed_rows,
  count(*) FILTER(WHERE source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
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
        AND source.exposure_variance_amount=0)::bigint AS active_rows,
  count(*) FILTER(WHERE source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
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
        AND source.exposure_variance_amount=0)::bigint AS review_rows,
  count(*) FILTER
  (
   WHERE NOT
   (
    (source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
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
        AND source.exposure_variance_amount=0) OR (source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
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
        AND source.exposure_variance_amount=0) OR (source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
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
        AND source.exposure_variance_amount=0)
   )
  )::bigint AS mapping_errors
 FROM msbf_m2.application_payment_reconciliation_certification_latest AS source
 WHERE source.module1_run_id=(SELECT run_id FROM run_context)
), state AS
(
 SELECT
  (SELECT count(*) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS source_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS account_performance_rows,
  (SELECT count(*) FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM run_context)) AS scope_summary_rows,
  (SELECT count(*) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS kpi_snapshot_rows,
  (SELECT count(*) FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS queue_summary_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=(SELECT run_id FROM run_context)) AS latest_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_archive WHERE module1_run_id=(SELECT run_id FROM run_context)) AS archive_rows,
  (SELECT count(*) FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)) AS registry_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context) AND evidence_code LIKE 'M2_10_%') AS evidence_rows,
  (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS') AS acceptance_rows
)
SELECT run_context.run_status,source_posture.*,state.*,
 CASE WHEN run_context.run_status='M2_9_ACCEPTED'
  AND source_posture.closed_rows=57
  AND source_posture.active_rows=1
  AND source_posture.review_rows=1
  AND source_posture.mapping_errors=0
  AND state.source_rows=0 AND state.account_performance_rows=0
  AND state.scope_summary_rows=0 AND state.kpi_snapshot_rows=0
  AND state.queue_summary_rows=0 AND state.latest_rows=0
  AND state.archive_rows=0 AND state.registry_rows=0
  AND state.evidence_rows=0 AND state.acceptance_rows=0
 THEN 'PASS' ELSE 'FAIL' END AS recovery_status
FROM run_context CROSS JOIN source_posture CROSS JOIN state;
