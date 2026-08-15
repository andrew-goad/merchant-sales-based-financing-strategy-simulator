/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 204A_msbf_m2_10_failed_schema_policy_recovery_check_v0_2.sql
Version     : v0.2

Purpose
-------
Read-only proof that a failed Program 204 transaction left no M2.10 control or
business objects, evidence, or acceptance records while accepted M2.9 remains
unchanged.

Required result
---------------
recovery_status = PASS.
============================================================================ */

WITH run_context AS
(
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), source_registry AS
(
 SELECT count(*)::bigint AS registry_rows,max(contract_status) AS contract_status,
        max(contract_code) AS contract_code,max(contract_version) AS contract_version,
        max(schema_version) AS schema_version,max(methodology_version) AS methodology_version,
        max(combined_set_hash) AS combined_set_hash
 FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM run_context)
), source_gate AS
(
 SELECT count(*)::bigint AS gate_rows,max(result_status) AS gate_status
 FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM run_context)
   AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND review_version=1
), object_state AS
(
 SELECT count(*) FILTER(WHERE table_schema='msbf_ctl' AND table_name IN
        ('m2_10_policy_profile','m2_10_portfolio_analytics_contract_registry')) AS control_tables,
        count(*) FILTER(WHERE table_schema='msbf_m2' AND table_name IN
        ('portfolio_kpi_definition','portfolio_performance_tier_definition',
         'servicing_queue_definition','portfolio_analytics_reason_definition',
         'portfolio_performance_source_snapshot','application_portfolio_performance_snapshot',
         'portfolio_performance_scope_summary','portfolio_kpi_snapshot',
         'servicing_queue_analytics_snapshot','application_portfolio_performance_latest',
         'application_portfolio_performance_archive')) AS business_tables
 FROM information_schema.tables
), row_state AS
(
 SELECT (SELECT count(*) FROM msbf_ctl.run_evidence
         WHERE run_id=(SELECT run_id FROM run_context) AND evidence_code LIKE 'M2_10_%') AS evidence_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
         WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS') AS acceptance_rows,
        (SELECT count(*) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS') AS gate_catalog_rows
)
SELECT run_context.run_status,source_registry.registry_rows AS source_registry_rows,
 source_registry.contract_status AS source_contract_status,
 source_registry.contract_code AS source_contract_code,
 source_registry.contract_version AS source_contract_version,
 source_registry.schema_version AS source_schema_version,
 source_registry.methodology_version AS source_methodology_version,
 source_registry.combined_set_hash AS source_combined_set_hash,
 source_gate.gate_rows AS source_gate_rows,source_gate.gate_status AS source_gate_status,
 object_state.control_tables,object_state.business_tables,row_state.evidence_rows,
 row_state.acceptance_rows,row_state.gate_catalog_rows,
 CASE WHEN run_context.run_status='M2_9_ACCEPTED'
  AND source_registry.registry_rows=1 AND source_registry.contract_status='ACCEPTED'
  AND source_registry.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'
  AND source_registry.contract_version=1 AND source_registry.schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'
  AND source_registry.methodology_version='M2_9_METHOD_V1'
  AND source_registry.combined_set_hash='6af76d0059b47623619ebc09330b15fe'
  AND source_gate.gate_rows=1 AND source_gate.gate_status='PASS'
  AND object_state.control_tables=0 AND object_state.business_tables=0
  AND row_state.evidence_rows=0 AND row_state.acceptance_rows=0
  AND row_state.gate_catalog_rows=0 THEN 'PASS' ELSE 'FAIL' END AS recovery_status
FROM run_context CROSS JOIN source_registry CROSS JOIN source_gate
CROSS JOIN object_state CROSS JOIN row_state;
