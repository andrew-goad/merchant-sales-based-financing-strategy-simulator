/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.6 — Early Warning, Intervention & Servicing Strategy

Program     : 179_MSBF_M2_6_Detail_Report_v0_2.sql
Version     : v0.2

Purpose
-------
Produce 24 read-only detail result sets. Result Sets 23 and 24 must retain
headers and contain zero rows after acceptance.

Writes
------
None.
============================================================================ */
SET statement_timeout='45min'; SET jit=off;
DROP TABLE IF EXISTS _m2_6_dctx;
CREATE TEMP TABLE _m2_6_dctx ON COMMIT PRESERVE ROWS AS SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
/* Result Set 01 — Lifecycle and Acceptance */
SELECT run.run_id, run.run_code, run.run_version, run.run_status, registry.contract_status, gate.result_status AS gate_status, registry.generated_at, registry.validated_at, registry.accepted_at FROM msbf_ctl.run_registry AS run JOIN msbf_ctl.m2_6_intervention_strategy_contract_registry AS registry ON registry.module1_run_id=run.run_id LEFT JOIN msbf_ctl.acceptance_gate_result AS gate ON gate.run_id=run.run_id AND gate.gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY' AND gate.review_version=1 WHERE run.run_id=(SELECT run_id FROM _m2_6_dctx);

/* Result Set 02 — Policy and Source Boundary */
SELECT policy.* FROM msbf_ctl.m2_6_policy_profile AS policy WHERE policy.module1_run_id=(SELECT run_id FROM _m2_6_dctx);

/* Result Set 03 — Outcome Definitions */
SELECT * FROM msbf_m2.intervention_strategy_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) ORDER BY strategy_outcome_rank;

/* Result Set 04 — Action Definitions */
SELECT * FROM msbf_m2.intervention_servicing_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) ORDER BY servicing_action_rank;

/* Result Set 05 — Reason Definitions */
SELECT * FROM msbf_m2.intervention_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) ORDER BY intervention_reason_code;

/* Result Set 06 — Entity Counts */
SELECT policy_rows,outcome_rows,action_rows,reason_rows,source_rows,strategy_rows,portfolio_summary_rows,latest_rows,archive_rows,comparison_rows,registry_rows,canonical_entities FROM msbf_ctl.m2_6_intervention_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx);

/* Result Set 07 — Accepted M2.5 Source Distribution */
SELECT scenario_code, latest_monitoring_status_code, paid_off_flag, count(*) AS rows, round(sum(remaining_receivable_amount),2) AS remaining_receivable FROM msbf_m2.advance_intervention_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) GROUP BY scenario_code, latest_monitoring_status_code, paid_off_flag ORDER BY scenario_code, latest_monitoring_status_code;

/* Result Set 08 — Strategy Outcome Distribution */
SELECT scenario_code, strategy_outcome_code, count(*) AS rows, round(sum(recommended_action_exposure_amount),2) AS recommended_action_exposure FROM msbf_m2.advance_intervention_strategy_latest WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) GROUP BY scenario_code, strategy_outcome_code ORDER BY scenario_code, strategy_outcome_code;

/* Result Set 09 — Servicing Action Distribution */
SELECT scenario_code, servicing_action_code, servicing_queue_code, count(*) AS rows, round(sum(recommended_action_exposure_amount),2) AS recommended_action_exposure FROM msbf_m2.advance_intervention_strategy_latest WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) GROUP BY scenario_code, servicing_action_code, servicing_queue_code ORDER BY scenario_code, servicing_action_code;

/* Result Set 10 — Recommended Action Detail */
SELECT scenario_code, synthetic_account_id, synthetic_advance_id, strategy_outcome_code, servicing_action_code, recommended_action_exposure_amount, temporary_remittance_rate_factor, review_remittance_rate, recommended_review_duration_days, reassessment_interval_days, primary_intervention_reason_code FROM msbf_m2.advance_intervention_strategy_latest WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) AND recommended_action_flag ORDER BY recommended_action_exposure_amount DESC;

/* Result Set 11 — Closed No Action Detail */
SELECT scenario_code, count(*) AS closed_rows FROM msbf_m2.advance_intervention_strategy_latest WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) AND strategy_outcome_code='CLOSED_NO_FURTHER_ACTION' GROUP BY scenario_code ORDER BY scenario_code;

/* Result Set 12 — Portfolio Strategy Summary */
SELECT * FROM msbf_m2.portfolio_intervention_strategy_summary WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) ORDER BY scenario_code;

/* Result Set 13 — Matched Baseline Stress Comparison */
SELECT * FROM msbf_m2.v_m2_6_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) ORDER BY merchant_application_id;

/* Result Set 14 — Stress Non Improvement Summary */
SELECT count(*) AS matched_rows, count(*) FILTER (WHERE stress_strategy_improvement_flag) AS stress_strategy_improvements, count(*) FILTER (WHERE stress_action_improvement_flag) AS stress_action_improvements FROM msbf_m2.v_m2_6_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx);

/* Result Set 15 — Reason Payload Distribution */
SELECT reason_code, count(*) AS strategy_rows FROM msbf_m2.advance_intervention_strategy_latest AS latest CROSS JOIN LATERAL jsonb_array_elements_text(latest.intervention_reason_codes) AS reason(reason_code) WHERE latest.module1_run_id=(SELECT run_id FROM _m2_6_dctx) GROUP BY reason_code ORDER BY strategy_rows DESC, reason_code;

/* Result Set 16 — Review Term Validation */
SELECT temporary_adjustment_review_flag, count(*) AS rows, min(temporary_remittance_rate_factor) AS min_factor, max(temporary_remittance_rate_factor) AS max_factor, min(recommended_review_duration_days) AS min_duration, max(recommended_review_duration_days) AS max_duration FROM msbf_m2.advance_intervention_strategy_latest WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) GROUP BY temporary_adjustment_review_flag ORDER BY temporary_adjustment_review_flag DESC;

/* Result Set 17 — Recommendation Only Boundary */
SELECT count(*) AS rows, count(*) FILTER (WHERE recommended_action_flag) AS recommended_rows, 0 AS executed_servicing_actions FROM msbf_m2.advance_intervention_strategy_latest WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx);

/* Result Set 18 — Latest Archive Reproduction */
SELECT count(*) AS joined_rows, count(*) FILTER (WHERE latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at')) AS reproduction_mismatches FROM msbf_m2.advance_intervention_strategy_latest AS latest FULL OUTER JOIN msbf_m2.advance_intervention_strategy_archive AS archive ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=(SELECT run_id FROM _m2_6_dctx);

/* Result Set 19 — Contract Registry Hash Summary */
SELECT * FROM msbf_ctl.m2_6_intervention_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx);

/* Result Set 20 — Canonical Hash Summary */
SELECT * FROM msbf_m2.v_m2_6_canonical_hash WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx);

/* Result Set 21 — Governed Evidence Summary */
SELECT CASE WHEN evidence_code LIKE 'M2_6_POS_%' THEN 'POSITIVE' WHEN evidence_code LIKE 'M2_6_NEG_%' THEN 'NEGATIVE' WHEN evidence_code='M2_6_ACCEPTANCE_SUMMARY' THEN 'ACCEPTANCE' ELSE 'GENERATION' END AS family, status, count(*) AS rows FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_6_dctx) AND evidence_code LIKE 'M2_6_%' GROUP BY family,status ORDER BY family,status;

/* Result Set 22 — Power BI Strategy Consumption Sample */
SELECT * FROM msbf_m2.v_m2_6_power_bi_intervention_strategy WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) ORDER BY recommended_action_flag DESC, recommended_action_exposure_amount DESC, synthetic_advance_id LIMIT 40;

/* Result Set 23 — Deterministic Mismatches */
WITH mismatches AS (SELECT 'POLICY'::text AS entity_type, policy.policy_code AS entity_key, policy.row_hash AS stored_hash, msbf_ctl.m2_6_hash_jsonb(to_jsonb(policy)-'row_hash'-'created_at'-'updated_at') AS reconstructed_hash FROM msbf_ctl.m2_6_policy_profile AS policy WHERE policy.module1_run_id=(SELECT run_id FROM _m2_6_dctx) UNION ALL SELECT 'SOURCE', scenario_id::text||'|'||merchant_application_id, row_hash, msbf_ctl.m2_6_hash_jsonb(to_jsonb(source)-'row_hash'-'created_at') FROM msbf_m2.advance_intervention_source_snapshot AS source WHERE source.module1_run_id=(SELECT run_id FROM _m2_6_dctx) UNION ALL SELECT 'STRATEGY', scenario_id::text||'|'||merchant_application_id, row_hash, msbf_ctl.m2_6_hash_jsonb(to_jsonb(strategy)-'row_hash'-'created_at') FROM msbf_m2.advance_intervention_strategy_snapshot AS strategy WHERE strategy.module1_run_id=(SELECT run_id FROM _m2_6_dctx) UNION ALL SELECT 'LATEST', scenario_id::text||'|'||merchant_application_id, contract_row_hash, msbf_ctl.m2_6_hash_jsonb(to_jsonb(latest)-'contract_row_hash'-'created_at') FROM msbf_m2.advance_intervention_strategy_latest AS latest WHERE latest.module1_run_id=(SELECT run_id FROM _m2_6_dctx) UNION ALL SELECT 'ARCHIVE', scenario_id::text||'|'||merchant_application_id, archive_row_hash, msbf_ctl.m2_6_hash_jsonb(to_jsonb(archive)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at') FROM msbf_m2.advance_intervention_strategy_archive AS archive WHERE archive.module1_run_id=(SELECT run_id FROM _m2_6_dctx) UNION ALL SELECT 'REGISTRY', contract_code, row_hash, msbf_ctl.m2_6_registry_row_hash(to_jsonb(registry)) FROM msbf_ctl.m2_6_intervention_strategy_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_6_dctx)) SELECT * FROM mismatches WHERE stored_hash IS DISTINCT FROM reconstructed_hash ORDER BY entity_type, entity_key;

/* Result Set 24 — Blocking Errors and Stage-Boundary Violations */
SELECT 'FAILED_EVIDENCE'::text AS violation_type, evidence_code AS detail FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_6_dctx) AND evidence_code LIKE 'M2_6_%' AND status='FAIL' UNION ALL SELECT 'STRESS_IMPROVEMENT', merchant_application_id FROM msbf_m2.v_m2_6_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) AND (stress_strategy_improvement_flag OR stress_action_improvement_flag) UNION ALL SELECT 'EXECUTED_SERVICING_FLAG', merchant_application_id FROM msbf_m2.advance_intervention_strategy_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_6_dctx) AND (merchant_contact_executed_flag OR payment_change_executed_flag OR write_off_or_charge_off_executed_flag OR legal_or_collection_action_executed_flag OR external_notice_generated_flag OR production_adverse_action_notice_flag) UNION ALL SELECT 'PREMATURE_M2_7_OBJECT', table_name FROM information_schema.tables WHERE table_schema IN ('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_7%';
