/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 209_msbf_m2_10_acceptance_finalize_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Independently verify accepted M2.9 lineage, all positive and negative control
evidence, physical cardinalities, exact performance/KPI/queue posture,
analytics-only boundaries, latest/archive reproduction, stress
non-improvement, canonical identity, and absence of premature downstream
objects before issuing formal M2.10 acceptance.

Required result
---------------
acceptance_status=PASS, final_run_status=M2_10_ACCEPTED,
final_contract_status=ACCEPTED, gate_status=PASS.
============================================================================ */

BEGIN;
SET LOCAL work_mem='160MB';
SET LOCAL statement_timeout='55min';
SET LOCAL jit=off;
/* ============================================================================
Section 1 — Independent acceptance reconstruction
============================================================================ */

DROP TABLE IF EXISTS _m2_10_acceptance;

CREATE TEMP TABLE _m2_10_acceptance ON COMMIT PRESERVE ROWS AS
WITH run_context AS
(
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), registry AS
(
 SELECT * FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
 WHERE module1_run_id=(SELECT run_id FROM run_context)
), source_registry AS
(
 SELECT contract_status,contract_code,contract_version,schema_version,
 methodology_version,combined_set_hash
 FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)
), source_gate AS
(
 SELECT result_status AS gate_status FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM run_context)
   AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND review_version=1
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
), controls AS
(
 SELECT count(*) FILTER(WHERE evidence_code LIKE 'M2_10_POS_%') AS positive_checks,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_POS_%' AND status='PASS') AS positive_passes,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_POS_%' AND status<>'PASS') AS positive_failures,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_NEG_%') AS negative_checks,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_NEG_%' AND status='PASS') AS negative_passes,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_NEG_%' AND status<>'PASS') AS negative_failures,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_%'
    AND evidence_code NOT LIKE 'M2_10_POS_%' AND evidence_code NOT LIKE 'M2_10_NEG_%'
    AND evidence_code<>'M2_10_ACCEPTANCE_SUMMARY') AS generation_evidence_rows,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_10_%' AND status='FAIL') AS failed_evidence_rows
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM run_context)
), physical AS
(
 SELECT
  (SELECT count(*) FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM run_context)) AS policy_rows,
  (SELECT count(*) FROM msbf_m2.portfolio_kpi_definition WHERE module1_run_id=(SELECT run_id FROM run_context)) AS kpi_definition_rows,
  (SELECT count(*) FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=(SELECT run_id FROM run_context)) AS performance_tier_rows,
  (SELECT count(*) FROM msbf_m2.servicing_queue_definition WHERE module1_run_id=(SELECT run_id FROM run_context)) AS servicing_queue_rows,
  (SELECT count(*) FROM msbf_m2.portfolio_analytics_reason_definition WHERE module1_run_id=(SELECT run_id FROM run_context)) AS reason_rows,
  (SELECT count(*) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS source_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS account_performance_rows,
  (SELECT count(*) FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM run_context)) AS scope_summary_rows,
  (SELECT count(*) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS kpi_snapshot_rows,
  (SELECT count(*) FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS queue_summary_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=(SELECT run_id FROM run_context)) AS latest_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_performance_archive WHERE module1_run_id=(SELECT run_id FROM run_context)) AS archive_rows,
  (SELECT count(*) FROM msbf_m2.v_m2_10_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context)) AS comparison_rows,
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
  (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2'
    AND table_name IN ('application_portfolio_performance_snapshot','portfolio_performance_scope_summary',
     'portfolio_kpi_snapshot','servicing_queue_analytics_snapshot','application_portfolio_performance_latest',
     'application_portfolio_performance_archive')
    AND lower(column_name) IN ('production_decision','production_strategy_change','real_funds_moved',
     'external_system_updated','merchant_contact_executed','write_off_posted',
     'collection_agency_referral','legal_action_executed','external_notice_payload',
     'production_adverse_action_notice')) AS prohibited_columns,
  (SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('msbf_ctl','msbf_m2')
     AND lower(table_name) LIKE 'm2_11%') AS premature_m2_11_tables,
  (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS') AS existing_gate_rows,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error
    WHERE run_id=(SELECT run_id FROM run_context) AND severity='BLOCKING') AS blocking_errors,
  (SELECT canonical_entities FROM msbf_m2.v_m2_10_canonical_hash
    WHERE module1_run_id=(SELECT run_id FROM run_context)) AS physical_canonical_entities,
  (SELECT combined_set_hash FROM msbf_m2.v_m2_10_canonical_hash
    WHERE module1_run_id=(SELECT run_id FROM run_context)) AS physical_combined_set_hash
)
SELECT run_context.run_id,run_context.run_status AS prior_run_status,
 registry.contract_status AS prior_contract_status,
 source_registry.contract_status AS source_contract_status,
 source_registry.contract_code AS source_contract_code,
 source_registry.contract_version AS source_contract_version,
 source_registry.schema_version AS source_schema_version,
 source_registry.methodology_version AS source_methodology_version,
 source_registry.combined_set_hash AS source_combined_set_hash,
 source_gate.gate_status AS source_gate_status,mapping.mapping_errors,controls.*,physical.*,
 registry.portfolio_account_rows,registry.baseline_account_rows,registry.stress_account_rows,
 registry.closed_stable_rows,registry.active_reconciled_rows,registry.controlled_review_rows,
 registry.no_servicing_queue_rows,registry.active_reassessment_queue_rows,
 registry.governance_review_queue_rows,registry.certified_account_rows,
 registry.certification_rate,registry.certified_exposure_amount,
 registry.active_exposure_amount,registry.review_hold_exposure_amount,
 registry.scheduled_payment_amount,registry.processed_payment_amount,
 registry.gross_collection_rate,registry.returned_payment_amount,registry.return_rate,
 registry.retry_payment_amount,registry.retry_cure_rate,
 registry.reconciliation_variance_amount,registry.exposure_variance_amount,
 registry.exception_case_count,registry.resolved_exception_count,
 registry.exception_resolution_rate,registry.unresolved_exception_count,
 registry.servicing_burden_units,registry.average_burden_per_account,
 registry.canonical_entities,registry.contract_set_hash,registry.combined_set_hash,
 CASE WHEN run_context.run_status='M2_10_VALIDATED' AND registry.contract_status='VALIDATED'
  AND source_registry.contract_status='ACCEPTED'
  AND source_registry.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND source_registry.contract_version=1
  AND source_registry.schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'
  AND source_registry.methodology_version='M2_9_METHOD_V1'
  AND source_registry.combined_set_hash='6af76d0059b47623619ebc09330b15fe' AND source_gate.gate_status='PASS'
  AND mapping.mapping_errors=0
  AND controls.positive_checks=120 AND controls.positive_passes=120 AND controls.positive_failures=0
  AND controls.negative_checks=20 AND controls.negative_passes=20 AND controls.negative_failures=0
  AND controls.generation_evidence_rows=24 AND controls.failed_evidence_rows=0
  AND physical.policy_rows=1 AND physical.kpi_definition_rows=24
  AND physical.performance_tier_rows=3 AND physical.servicing_queue_rows=3
  AND physical.reason_rows=24 AND physical.source_rows=59
  AND physical.account_performance_rows=59 AND physical.scope_summary_rows=3
  AND physical.kpi_snapshot_rows=72 AND physical.queue_summary_rows=3
  AND physical.latest_rows=59 AND physical.archive_rows=59 AND physical.comparison_rows=15
  AND registry.portfolio_account_rows=59 AND registry.baseline_account_rows=44
  AND registry.stress_account_rows=15 AND registry.closed_stable_rows=57
  AND registry.active_reconciled_rows=1 AND registry.controlled_review_rows=1
  AND registry.no_servicing_queue_rows=57 AND registry.active_reassessment_queue_rows=1
  AND registry.governance_review_queue_rows=1 AND registry.certified_account_rows=59
  AND registry.certification_rate=1 AND registry.certified_exposure_amount=785.48
  AND registry.active_exposure_amount=323.79 AND registry.review_hold_exposure_amount=461.69
  AND registry.scheduled_payment_amount=194.25 AND registry.processed_payment_amount=194.25
  AND registry.gross_collection_rate=1 AND registry.returned_payment_amount=27.75
  AND registry.return_rate=0.142857 AND registry.retry_payment_amount=27.75
  AND registry.retry_cure_rate=1 AND registry.reconciliation_variance_amount=0
  AND registry.exposure_variance_amount=0 AND registry.exception_case_count=1
  AND registry.resolved_exception_count=1 AND registry.exception_resolution_rate=1
  AND registry.unresolved_exception_count=0 AND registry.servicing_burden_units=7
  AND registry.average_burden_per_account=0.118644
  AND physical.boundary_rows=0 AND physical.stress_improvement_rows=0
  AND physical.archive_mismatches=0 AND physical.prohibited_columns=0
  AND physical.premature_m2_11_tables=0 AND physical.existing_gate_rows=0
  AND physical.blocking_errors=0 AND registry.canonical_entities=370
  AND physical.physical_canonical_entities=370
  AND registry.combined_set_hash IS NOT DISTINCT FROM physical.physical_combined_set_hash
  AND registry.contract_set_hash IS NOT NULL AND registry.combined_set_hash IS NOT NULL
 THEN 'PASS' ELSE 'FAIL' END AS acceptance_status
FROM run_context CROSS JOIN registry CROSS JOIN source_registry CROSS JOIN source_gate
CROSS JOIN mapping CROSS JOIN controls CROSS JOIN physical;

/* ============================================================================
Section 2 — Fail-closed acceptance guard
============================================================================ */

DO $m2_10_acceptance_guard$
DECLARE v record;
BEGIN
 SELECT * INTO v FROM _m2_10_acceptance;
 IF v.acceptance_status<>'PASS' THEN
  RAISE EXCEPTION 'M2.10 acceptance preconditions failed: %.',row_to_json(v);
 END IF;
 PERFORM msbf_ctl.m2_10_assert_acceptance_ready(v.run_id);
END;
$m2_10_acceptance_guard$;

/* ============================================================================
Section 3 — Persist accepted lifecycle, gate, and evidence
============================================================================ */

UPDATE msbf_ctl.m2_10_portfolio_analytics_contract_registry
SET contract_status='ACCEPTED',accepted_at=clock_timestamp()
WHERE module1_run_id=(SELECT run_id FROM _m2_10_acceptance);
UPDATE msbf_ctl.run_registry SET run_status='M2_10_ACCEPTED',
 notes=coalesce(notes,'')||' | M2.10 portfolio performance, KPI, and servicing analytics accepted.'
WHERE run_id=(SELECT run_id FROM _m2_10_acceptance);

INSERT INTO msbf_ctl.acceptance_gate_result
(run_id,gate_id,review_version,result_status,observed_value,threshold_value,
 finding,residual_limitation,reviewer_role)
SELECT run_id,'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS',1,'PASS',combined_set_hash,
 '120/120 positive; 20/20 negative; exact M2.9 lineage; 59 account facts; 72 KPI facts; three queues; zero production, archive, stress, or stage-boundary violations',
 'M2.10 portfolio performance, KPI, and servicing analytics accepted.',
 'Synthetic analytics only; no production decisions, account actions, funds movement, external system update, contact, collections, legal execution, or notice generation.',
 'Independent Validation / Project Owner'
FROM _m2_10_acceptance;

INSERT INTO msbf_ctl.run_evidence
(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
 metric_value_text,unit_code,status,interpretation)
SELECT run_id,'M2_10_ACCEPTANCE_SUMMARY','PORTFOLIO',
 'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_ACCEPTANCE',
 NULL::numeric(28,10),combined_set_hash,'ACCEPTANCE','PASS',
 'Formal M2.10 acceptance with exact M2.9 lineage, 120 positive controls, 20 negative controls, 370 canonical entities, 72 KPI facts, three queues, and zero production, stress, archive, or stage-boundary exceptions.'
FROM _m2_10_acceptance;

/* ============================================================================
Section 4 — Reconstruct final accepted state
============================================================================ */

ALTER TABLE _m2_10_acceptance
ADD COLUMN final_run_status text,ADD COLUMN final_contract_status text,ADD COLUMN gate_status text;
UPDATE _m2_10_acceptance AS acceptance SET
 final_run_status=(SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=acceptance.run_id),
 final_contract_status=(SELECT contract_status FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=acceptance.run_id),
 gate_status=(SELECT result_status FROM msbf_ctl.acceptance_gate_result
  WHERE run_id=acceptance.run_id AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND review_version=1)
WHERE acceptance.run_id IS NOT NULL;

DO $m2_10_final_guard$
DECLARE v record;
BEGIN
 SELECT final_run_status,final_contract_status,gate_status INTO v FROM _m2_10_acceptance;
 IF v.final_run_status<>'M2_10_ACCEPTED' OR v.final_contract_status<>'ACCEPTED'
  OR v.gate_status<>'PASS' THEN RAISE EXCEPTION 'M2.10 final state failed: %.',row_to_json(v);
 END IF;
END;
$m2_10_final_guard$;

COMMIT;
SELECT * FROM _m2_10_acceptance;
