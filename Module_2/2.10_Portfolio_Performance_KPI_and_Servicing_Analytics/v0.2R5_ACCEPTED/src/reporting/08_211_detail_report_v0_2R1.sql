/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 211_MSBF_M2_10_Detail_Report_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Produce 24 governed read-only result sets spanning lifecycle, policy,
dictionaries, accepted M2.9 source, account performance, KPI and queue
analytics, matched stress diagnostics, latest/archive reproduction, registry
and canonical identity, evidence, and zero-row deterministic and blocking
exception reports.

Required result
---------------
24 result sets. Result Sets 23 and 24 retain headers and contain zero rows.
============================================================================ */

SET statement_timeout='55min';
SET jit=off;
DROP TABLE IF EXISTS _m2_10_dctx;
CREATE TEMP TABLE _m2_10_dctx ON COMMIT PRESERVE ROWS AS
SELECT run_id FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
CREATE INDEX ON _m2_10_dctx(run_id);
ANALYZE _m2_10_dctx;

/* Result Set 01 — Lifecycle and Acceptance */
SELECT run.run_id,run.run_code,run.run_version,run.run_status,
 registry.contract_code,registry.contract_version,registry.schema_version,
 registry.methodology_version,registry.contract_status,gate.gate_id,
 gate.result_status AS gate_status,registry.generated_at,registry.validated_at,
 registry.accepted_at
FROM msbf_ctl.run_registry AS run
JOIN msbf_ctl.m2_10_portfolio_analytics_contract_registry AS registry
 ON registry.module1_run_id=run.run_id
LEFT JOIN msbf_ctl.acceptance_gate_result AS gate
 ON gate.run_id=run.run_id AND gate.gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND gate.review_version=1
WHERE run.run_id=(SELECT run_id FROM _m2_10_dctx);

/* Result Set 02 — Policy and Accepted M2.9 Source Boundary */
SELECT * FROM msbf_ctl.m2_10_policy_profile
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx);

/* Result Set 03 — KPI Definitions */
SELECT kpi_code,kpi_rank,unit_code,zero_denominator_numeric_flag,
 definition_status,description,row_hash
FROM msbf_m2.portfolio_kpi_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
ORDER BY kpi_rank,kpi_code;

/* Result Set 04 — Performance Tier Definitions */
SELECT performance_tier_code,performance_tier_rank,burden_units,
 definition_status,description,row_hash
FROM msbf_m2.portfolio_performance_tier_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
ORDER BY performance_tier_rank,performance_tier_code;

/* Result Set 05 — Servicing Queue Definitions */
SELECT servicing_queue_code,servicing_queue_rank,burden_units,
 manual_review_flag,definition_status,description,row_hash
FROM msbf_m2.servicing_queue_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
ORDER BY servicing_queue_rank,servicing_queue_code;

/* Result Set 06 — Analytics Reason Definitions */
SELECT portfolio_analytics_reason_code,production_action_flag,
 definition_status,description,row_hash
FROM msbf_m2.portfolio_analytics_reason_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
ORDER BY portfolio_analytics_reason_code;

/* Result Set 07 — Entity Counts */
SELECT policy_rows,kpi_definition_rows,performance_tier_rows,
 servicing_queue_rows,reason_rows,source_rows,account_performance_rows,
 scope_summary_rows,kpi_snapshot_rows,queue_summary_rows,latest_rows,
 archive_rows,comparison_rows,registry_rows,canonical_entities
FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx);

/* Result Set 08 — Accepted M2.9 Source Distribution */
SELECT
 scenario_code,reconciliation_outcome_code,certified_state_code,
 state_certified_flag,active_state_flag,closed_state_flag,
 review_hold_state_flag,exception_resolved_flag,
 count(*) AS source_rows,
 round(sum(certified_exposure_amount),2) AS certified_exposure_amount,
 round(sum(scheduled_payment_amount),2) AS scheduled_payment_amount,
 round(sum(processed_payment_amount),2) AS processed_payment_amount,
 round(sum(returned_payment_amount),2) AS returned_payment_amount,
 round(sum(retry_payment_amount),2) AS retry_payment_amount,
 round(sum(abs(reconciliation_variance_amount)),2)
   AS reconciliation_variance_amount,
 round(sum(abs(exposure_variance_amount)),2)
   AS exposure_variance_amount,
 sum(exception_case_count) AS exception_case_count,
 sum(resolved_exception_count) AS resolved_exception_count,
 sum(unresolved_exception_count) AS unresolved_exception_count
FROM msbf_m2.portfolio_performance_source_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
GROUP BY
 scenario_code,reconciliation_outcome_code,certified_state_code,
 state_certified_flag,active_state_flag,closed_state_flag,
 review_hold_state_flag,exception_resolved_flag
ORDER BY scenario_code,reconciliation_outcome_code,certified_state_code;

/* Result Set 09 — Performance Tier Distribution *//* Result Set 09 — Performance Tier Distribution */
SELECT scenario_code,performance_tier_code,count(*) AS account_rows,
 round(sum(certified_exposure_amount),2) AS certified_exposure_amount,
 sum(payment_event_count) AS payment_event_rows,
 round(sum(servicing_burden_units),6) AS servicing_burden_units
FROM msbf_m2.application_portfolio_performance_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
GROUP BY scenario_code,performance_tier_code
ORDER BY scenario_code,performance_tier_code;

/* Result Set 10 — Servicing Queue Distribution */
SELECT scenario_code,servicing_queue_code,count(*) AS account_rows,
 round(sum(certified_exposure_amount),2) AS certified_exposure_amount,
 sum(exception_case_count) AS exception_case_rows,
 round(sum(servicing_burden_units),6) AS servicing_burden_units
FROM msbf_m2.application_portfolio_performance_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
GROUP BY scenario_code,servicing_queue_code
ORDER BY scenario_code,servicing_queue_code;

/* Result Set 11 — Active Reconciled Account Detail */
SELECT performance.scenario_code,performance.merchant_application_id,
 performance.synthetic_account_id,source.reconciliation_outcome_code,
 source.certified_state_code,source.state_certified_flag,
 source.active_state_flag,source.closed_state_flag,
 source.review_hold_state_flag,source.exception_resolved_flag,
 performance.performance_tier_code,performance.servicing_queue_code,
 performance.payment_event_count,performance.settled_event_count,
 performance.returned_event_count,performance.retry_event_count,
 performance.certified_exposure_amount,
 performance.scheduled_payment_amount,performance.processed_payment_amount,
 performance.returned_payment_amount,performance.retry_payment_amount,
 performance.gross_collection_rate,performance.return_rate,
 performance.retry_cure_rate,performance.servicing_burden_units,
 performance.primary_portfolio_reason_code,
 performance.portfolio_reason_codes
FROM msbf_m2.application_portfolio_performance_latest AS performance
JOIN msbf_m2.portfolio_performance_source_snapshot AS source
  ON source.module1_run_id=performance.module1_run_id
 AND source.scenario_id=performance.scenario_id
 AND source.merchant_application_id=performance.merchant_application_id
WHERE performance.module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 AND source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
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
 AND performance.performance_tier_code='ACTIVE_RECONCILED'
 AND performance.servicing_queue_code='ACTIVE_REASSESSMENT';

/* Result Set 12 — Controlled Review Detail */
SELECT performance.scenario_code,performance.merchant_application_id,
 performance.synthetic_account_id,source.reconciliation_outcome_code,
 source.certified_state_code,source.state_certified_flag,
 source.active_state_flag,source.closed_state_flag,
 source.review_hold_state_flag,source.exception_resolved_flag,
 performance.performance_tier_code,performance.servicing_queue_code,
 performance.certified_exposure_amount,
 performance.unresolved_exception_count,
 performance.servicing_burden_units,
 performance.primary_portfolio_reason_code,
 performance.portfolio_reason_codes
FROM msbf_m2.application_portfolio_performance_latest AS performance
JOIN msbf_m2.portfolio_performance_source_snapshot AS source
  ON source.module1_run_id=performance.module1_run_id
 AND source.scenario_id=performance.scenario_id
 AND source.merchant_application_id=performance.merchant_application_id
WHERE performance.module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 AND source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
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
 AND performance.performance_tier_code='CONTROLLED_REVIEW'
 AND performance.servicing_queue_code='GOVERNANCE_REVIEW_HOLD';

/* Result Set 13 — Closed Stable Detail */
SELECT performance.scenario_code,performance.merchant_application_id,
 performance.synthetic_account_id,source.reconciliation_outcome_code,
 source.certified_state_code,source.state_certified_flag,
 source.active_state_flag,source.closed_state_flag,
 source.review_hold_state_flag,source.exception_resolved_flag,
 performance.performance_tier_code,performance.servicing_queue_code,
 performance.certified_exposure_amount,performance.payment_event_count,
 performance.servicing_burden_units,
 performance.primary_portfolio_reason_code
FROM msbf_m2.application_portfolio_performance_latest AS performance
JOIN msbf_m2.portfolio_performance_source_snapshot AS source
  ON source.module1_run_id=performance.module1_run_id
 AND source.scenario_id=performance.scenario_id
 AND source.merchant_application_id=performance.merchant_application_id
WHERE performance.module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 AND source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
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
 AND performance.performance_tier_code='CLOSED_STABLE'
 AND performance.servicing_queue_code='NO_SERVICING_REQUIRED'
ORDER BY performance.scenario_code,performance.merchant_application_id;

/* Result Set 14 — Portfolio and Scenario Scope Summaries *//* Result Set 14 — Portfolio and Scenario Scope Summaries */
SELECT * FROM msbf_m2.portfolio_performance_scope_summary
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
ORDER BY scope_type,scope_code;

/* Result Set 15 — Portfolio KPI Matrix */
SELECT scope_code,kpi_code,kpi_rank,unit_code,applicable_flag,
 kpi_value_numeric,kpi_value_text,numerator_value,denominator_value,
 primary_portfolio_reason_code
FROM msbf_m2.portfolio_kpi_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 AND scope_code='PORTFOLIO_ALL'
ORDER BY kpi_rank,kpi_code;

/* Result Set 16 — Scenario KPI Matrix */
SELECT scope_code,scenario_code,kpi_code,kpi_rank,unit_code,applicable_flag,
 kpi_value_numeric,kpi_value_text,numerator_value,denominator_value
FROM msbf_m2.portfolio_kpi_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 AND scope_type='SCENARIO'
ORDER BY scope_code,kpi_rank,kpi_code;

/* Result Set 17 — Servicing Queue Analytics */
SELECT * FROM msbf_m2.servicing_queue_analytics_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
ORDER BY servicing_queue_code;

/* Result Set 18 — Matched Baseline / Stress Comparison */
SELECT merchant_application_id,baseline_performance_tier_code,
 stress_performance_tier_code,baseline_performance_tier_rank,
 stress_performance_tier_rank,baseline_servicing_burden_units,
 stress_servicing_burden_units,baseline_certified_exposure_amount,
 stress_certified_exposure_amount,stress_tier_improvement_flag,
 stress_burden_improvement_flag,stress_exposure_improvement_flag
FROM msbf_m2.v_m2_10_matched_scenario_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
ORDER BY merchant_application_id;

/* Result Set 19 — Stress Non-Improvement Summary */
SELECT count(*) AS matched_rows,
 count(*) FILTER(WHERE stress_tier_improvement_flag) AS stress_tier_improvements,
 count(*) FILTER(WHERE stress_burden_improvement_flag) AS stress_burden_improvements,
 count(*) FILTER(WHERE stress_exposure_improvement_flag) AS stress_exposure_improvements
FROM msbf_m2.v_m2_10_matched_scenario_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx);

/* Result Set 20 — Latest / Archive Reproduction */
SELECT count(*) AS joined_rows,
 count(*) FILTER(WHERE latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash
  OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at')) AS reproduction_mismatches
FROM msbf_m2.application_portfolio_performance_latest AS latest
FULL OUTER JOIN msbf_m2.application_portfolio_performance_archive AS archive
 ON archive.module1_run_id=latest.module1_run_id
AND archive.contract_version=latest.contract_version
AND archive.scenario_id=latest.scenario_id
AND archive.merchant_application_id=latest.merchant_application_id
WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=
 (SELECT run_id FROM _m2_10_dctx);

/* Result Set 21 — Contract Registry and Canonical Hash */
SELECT registry.*,canonical.canonical_entities AS physical_canonical_entities,
 canonical.combined_set_hash AS physical_combined_set_hash
FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry AS registry
JOIN msbf_m2.v_m2_10_canonical_hash AS canonical
 ON canonical.module1_run_id=registry.module1_run_id
WHERE registry.module1_run_id=(SELECT run_id FROM _m2_10_dctx);

/* Result Set 22 — Governed Evidence Summary */
SELECT CASE WHEN evidence_code LIKE 'M2_10_POS_%' THEN 'POSITIVE'
  WHEN evidence_code LIKE 'M2_10_NEG_%' THEN 'NEGATIVE'
  WHEN evidence_code='M2_10_ACCEPTANCE_SUMMARY' THEN 'ACCEPTANCE'
  ELSE 'GENERATION' END AS family,status,count(*) AS rows
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m2_10_dctx) AND evidence_code LIKE 'M2_10_%'
GROUP BY family,status ORDER BY family,status;

/* Result Set 23 — Deterministic Mismatches */
WITH mismatches AS
(
 SELECT 'POLICY'::text AS entity_type,policy_code||'|v'||policy_version::text AS entity_key,
  row_hash AS stored_hash,msbf_ctl.m2_10_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'-'updated_at') AS reconstructed_hash
 FROM msbf_ctl.m2_10_policy_profile AS p WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 UNION ALL SELECT 'KPI_DEFINITION',kpi_code,row_hash,msbf_ctl.m2_10_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')
 FROM msbf_m2.portfolio_kpi_definition AS d WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 UNION ALL SELECT 'PERFORMANCE_TIER_DEFINITION',performance_tier_code,row_hash,msbf_ctl.m2_10_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')
 FROM msbf_m2.portfolio_performance_tier_definition AS d WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 UNION ALL SELECT 'SERVICING_QUEUE_DEFINITION',servicing_queue_code,row_hash,msbf_ctl.m2_10_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')
 FROM msbf_m2.servicing_queue_definition AS d WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 UNION ALL SELECT 'REASON_DEFINITION',portfolio_analytics_reason_code,row_hash,msbf_ctl.m2_10_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')
 FROM msbf_m2.portfolio_analytics_reason_definition AS d WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 UNION ALL SELECT 'SOURCE',scenario_id::text||'|'||merchant_application_id,row_hash,msbf_ctl.m2_10_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')
 FROM msbf_m2.portfolio_performance_source_snapshot AS s WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 UNION ALL SELECT 'ACCOUNT_PERFORMANCE',scenario_id::text||'|'||merchant_application_id,row_hash,msbf_ctl.m2_10_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at')
 FROM msbf_m2.application_portfolio_performance_snapshot AS p WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 UNION ALL SELECT 'SCOPE_SUMMARY',scope_code,row_hash,msbf_ctl.m2_10_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')
 FROM msbf_m2.portfolio_performance_scope_summary AS s WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 UNION ALL SELECT 'KPI_SNAPSHOT',scope_code||'|'||kpi_code,row_hash,msbf_ctl.m2_10_hash_jsonb(to_jsonb(k)-'row_hash'-'created_at')
 FROM msbf_m2.portfolio_kpi_snapshot AS k WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 UNION ALL SELECT 'QUEUE_SUMMARY',servicing_queue_code,row_hash,msbf_ctl.m2_10_hash_jsonb(to_jsonb(q)-'row_hash'-'created_at')
 FROM msbf_m2.servicing_queue_analytics_snapshot AS q WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 UNION ALL SELECT 'LATEST',scenario_id::text||'|'||merchant_application_id,contract_row_hash,msbf_ctl.m2_10_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')
 FROM msbf_m2.application_portfolio_performance_latest AS l WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 UNION ALL SELECT 'ARCHIVE',scenario_id::text||'|'||merchant_application_id,archive_row_hash,msbf_ctl.m2_10_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at')
 FROM msbf_m2.application_portfolio_performance_archive AS a WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 UNION ALL SELECT 'REGISTRY',contract_code||'|v'||contract_version::text,row_hash,msbf_ctl.m2_10_registry_row_hash(to_jsonb(r))
 FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry AS r WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
)
SELECT entity_type,entity_key,stored_hash,reconstructed_hash
FROM mismatches WHERE stored_hash IS DISTINCT FROM reconstructed_hash
ORDER BY entity_type,entity_key;

/* Result Set 24 — Blocking Errors and Stage-Boundary Violations */
SELECT 'FAILED_EVIDENCE'::text AS violation_type,evidence_code AS detail
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m2_10_dctx)
 AND evidence_code LIKE 'M2_10_%' AND status='FAIL'
UNION ALL SELECT 'ACCEPTANCE_NOT_PASS',coalesce(result_status,'<NULL>')
FROM msbf_ctl.acceptance_gate_result
WHERE run_id=(SELECT run_id FROM _m2_10_dctx) AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
 AND result_status<>'PASS'
UNION ALL SELECT 'ANALYTICS_BOUNDARY',scenario_code||'|'||merchant_application_id
FROM msbf_m2.application_portfolio_performance_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 AND (production_decision_executed_flag OR external_system_updated_flag OR merchant_contact_executed_flag)
UNION ALL SELECT 'STRESS_IMPROVEMENT',merchant_application_id
FROM msbf_m2.v_m2_10_matched_scenario_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_10_dctx)
 AND (stress_tier_improvement_flag OR stress_burden_improvement_flag OR stress_exposure_improvement_flag)
UNION ALL
SELECT 'SOURCE_MAPPING_VIOLATION',
 coalesce(source.scenario_code,performance.scenario_code,'<NULL>')||'|'||
 coalesce(source.merchant_application_id,performance.merchant_application_id,'<NULL>')
FROM msbf_m2.portfolio_performance_source_snapshot AS source
FULL OUTER JOIN msbf_m2.application_portfolio_performance_snapshot AS performance
 ON performance.module1_run_id=source.module1_run_id
AND performance.scenario_id=source.scenario_id
AND performance.merchant_application_id=source.merchant_application_id
WHERE coalesce(source.module1_run_id,performance.module1_run_id)=
 (SELECT run_id FROM _m2_10_dctx)
 AND
 (
  source.row_hash IS NULL OR performance.row_hash IS NULL
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
UNION ALL
SELECT 'LATEST_ARCHIVE_MISMATCH',
 coalesce(latest.scenario_code,archive.scenario_code,'<NULL>')||'|'||
 coalesce(latest.merchant_application_id,archive.merchant_application_id,'<NULL>')
FROM msbf_m2.application_portfolio_performance_latest AS latest
FULL OUTER JOIN msbf_m2.application_portfolio_performance_archive AS archive
 ON archive.module1_run_id=latest.module1_run_id
AND archive.contract_version=latest.contract_version
AND archive.scenario_id=latest.scenario_id
AND archive.merchant_application_id=latest.merchant_application_id
WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=
 (SELECT run_id FROM _m2_10_dctx)
 AND
 (
  latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash
  OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at')
 )
UNION ALL
SELECT 'PROHIBITED_COLUMN',table_schema||'.'||table_name||'.'||column_name
FROM information_schema.columns
WHERE table_schema='msbf_m2'
 AND table_name IN
 ('application_portfolio_performance_snapshot','portfolio_performance_scope_summary',
  'portfolio_kpi_snapshot','servicing_queue_analytics_snapshot',
  'application_portfolio_performance_latest',
  'application_portfolio_performance_archive')
 AND lower(column_name) IN
 ('production_decision','production_strategy_change','real_funds_moved',
  'external_system_updated','merchant_contact_executed','write_off_posted',
  'collection_agency_referral','legal_action_executed','external_notice_payload',
  'production_adverse_action_notice')
UNION ALL
SELECT 'BLOCKING_PROFILE_ERROR',error_code
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM _m2_10_dctx)
 AND severity='BLOCKING'
UNION ALL SELECT 'PREMATURE_M2_11_OBJECT',table_schema||'.'||table_name
FROM information_schema.tables
WHERE table_schema IN ('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_11%';
