/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.9 — Payment Reconciliation, Exception Resolution
             & Account State Certification

Program     : 203_MSBF_M2_9_Detail_Report_v0_2.sql
Version     : v0.2

Purpose
-------
Produce 24 governed read-only result sets spanning lifecycle, policy,
dictionaries, accepted M2.8 account/payment/transition sources, event and
account reconciliation, exception resolution, state certification, portfolio,
matched stress diagnostics, latest/archive reproduction, registry/canonical
identity, evidence, and zero-row deterministic and blocking exception reports.

Required result
---------------
24 result sets. Result Sets 23 and 24 retain headers and contain zero rows.
============================================================================ */
SET statement_timeout='55min'; SET jit=off;
DROP TABLE IF EXISTS _m2_9_dctx;
CREATE TEMP TABLE _m2_9_dctx ON COMMIT PRESERVE ROWS AS SELECT run_id FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
CREATE INDEX ON _m2_9_dctx(run_id); ANALYZE _m2_9_dctx;
/* Result Set 01 — Lifecycle and Acceptance */
SELECT run.run_id,run.run_code,run.run_version,run.run_status,registry.contract_code,registry.contract_version,
registry.schema_version,registry.methodology_version,registry.contract_status,gate.gate_id,gate.result_status AS gate_status,
registry.generated_at,registry.validated_at,registry.accepted_at
FROM msbf_ctl.run_registry AS run JOIN msbf_ctl.m2_9_reconciliation_certification_contract_registry AS registry
ON registry.module1_run_id=run.run_id LEFT JOIN msbf_ctl.acceptance_gate_result AS gate
ON gate.run_id=run.run_id AND gate.gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND gate.review_version=1
WHERE run.run_id=(SELECT run_id FROM _m2_9_dctx);
/* Result Set 02 — Policy and Accepted M2.8 Source Boundary */
SELECT * FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx);
/* Result Set 03 — Payment Reconciliation Outcome Definitions */
SELECT reconciliation_outcome_code,reconciliation_outcome_rank,reconciliation_certified_flag,exception_resolved_flag,
exception_open_flag,review_hold_certified_flag,real_funds_moved_flag,production_state_updated_flag,
definition_status,description,row_hash FROM msbf_m2.payment_reconciliation_outcome_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx) ORDER BY reconciliation_outcome_rank,reconciliation_outcome_code;
/* Result Set 04 — Exception Resolution Action Definitions */
SELECT resolution_action_code,resolution_action_rank,exception_case_flag,retry_resolution_flag,review_hold_flag,
certification_block_flag,real_funds_moved_flag,external_system_called_flag,definition_status,description,row_hash
FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
ORDER BY resolution_action_rank,resolution_action_code;
/* Result Set 05 — Account State Certification Definitions */
SELECT certification_state_code,certification_state_rank,state_certified_flag,active_state_flag,closed_state_flag,
review_hold_state_flag,production_account_state_flag,definition_status,description,row_hash
FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
ORDER BY certification_state_rank,certification_state_code;
/* Result Set 06 — Reconciliation Reason Definitions */
SELECT reconciliation_reason_code,mapped_outcome_code,mapped_action_code,real_execution_reason_flag,
production_adverse_action_flag,definition_status,description,row_hash
FROM msbf_m2.payment_reconciliation_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
ORDER BY reconciliation_reason_code;
/* Result Set 07 — Entity Counts */
SELECT policy_rows,reconciliation_outcome_rows,resolution_action_rows,certification_state_rows,reason_rows,
account_source_rows,payment_source_rows,transition_source_rows,payment_reconciliation_rows,exception_case_rows,
account_reconciliation_rows,state_certification_rows,portfolio_summary_rows,latest_rows,archive_rows,
comparison_rows,registry_rows,canonical_entities FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry
WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx);
/* Result Set 08 — Accepted M2.8 Account Source Distribution */
SELECT scenario_code,source_servicing_execution_outcome_code,source_final_lifecycle_state_code,count(*) AS source_rows,
round(sum(source_exposure_amount),2) AS source_exposure_amount,round(sum(source_processed_payment_amount),2) AS processed_payment_amount,
round(sum(source_ending_exposure_amount),2) AS ending_exposure_amount
FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
GROUP BY scenario_code,source_servicing_execution_outcome_code,source_final_lifecycle_state_code
ORDER BY scenario_code,source_servicing_execution_outcome_code;
/* Result Set 09 — Accepted M2.8 Payment Event Source */
SELECT scenario_code,merchant_application_id,event_sequence,event_date,payment_event_type_code,payment_status_code,
scheduled_payment_amount,returned_payment_amount,retry_payment_amount,processed_payment_amount,
cumulative_processed_amount,simulated_outstanding_exposure_amount,source_event_row_hash,row_hash
FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
ORDER BY scenario_code,merchant_application_id,event_sequence;
/* Result Set 10 — Accepted M2.8 Transition Source Summary */
SELECT scenario_code,transition_type_code,lifecycle_state_before_code,lifecycle_state_after_code,count(*) AS transition_rows,
min(transition_sequence) AS minimum_transition_sequence,max(transition_sequence) AS maximum_transition_sequence,
min(transition_date) AS first_transition_date,max(transition_date) AS last_transition_date
FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
GROUP BY scenario_code,transition_type_code,lifecycle_state_before_code,lifecycle_state_after_code
ORDER BY scenario_code,minimum_transition_sequence,transition_type_code;
/* Result Set 11 — Payment Event Reconciliation */
SELECT scenario_code,merchant_application_id,synthetic_account_id,event_sequence,event_date,payment_status_code,
scheduled_payment_amount,returned_payment_amount,retry_payment_amount,processed_payment_amount,
expected_effective_processed_amount,reconciliation_variance_amount,event_reconciliation_status_code,
exception_case_required_flag,exception_resolved_flag,synthetic_exception_case_id,
primary_reconciliation_reason_code,source_event_row_hash,row_hash
FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
ORDER BY scenario_code,merchant_application_id,event_sequence;
/* Result Set 12 — Exception Resolution Detail */
SELECT scenario_code,merchant_application_id,synthetic_account_id,synthetic_exception_case_id,
originating_event_sequence,originating_event_date,resolving_event_sequence,resolving_event_date,
exception_amount,exception_status_code,resolution_action_code,exception_open_days,unresolved_exception_flag,
originating_event_row_hash,resolving_event_row_hash,row_hash
FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
ORDER BY scenario_code,merchant_application_id,synthetic_exception_case_id;
/* Result Set 13 — Account Reconciliation Outcome Distribution */
SELECT scenario_code,reconciliation_outcome_code,resolution_action_code,certification_candidate_state_code,
count(*) AS account_rows,count(*) FILTER(WHERE reconciliation_certified_flag) AS certified_rows,
sum(payment_event_count) AS payment_event_rows,sum(exception_case_count) AS exception_case_rows,
sum(unresolved_exception_count) AS unresolved_exception_rows,round(sum(processed_payment_amount),2) AS processed_payment_amount,
round(sum(reconciliation_variance_amount),2) AS reconciliation_variance_amount,
round(sum(source_ending_exposure_amount),2) AS source_ending_exposure_amount,
round(sum(exposure_variance_amount),2) AS exposure_variance_amount
FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
GROUP BY scenario_code,reconciliation_outcome_code,resolution_action_code,certification_candidate_state_code
ORDER BY scenario_code,reconciliation_outcome_code;
/* Result Set 14 — Active and Review Account Reconciliation Detail */
SELECT scenario_code,merchant_application_id,synthetic_account_id,synthetic_advance_id,
source_final_lifecycle_state_code,source_exposure_amount,payment_event_count,settled_event_count,returned_event_count,
retry_event_count,scheduled_payment_amount,processed_payment_amount,returned_payment_amount,retry_payment_amount,
expected_net_processed_amount,reconciliation_variance_amount,source_ending_exposure_amount,
expected_ending_exposure_amount,exposure_variance_amount,exception_case_count,resolved_exception_count,
unresolved_exception_count,reconciliation_outcome_code,resolution_action_code,certification_candidate_state_code,
certification_date,primary_reconciliation_reason_code,reconciliation_reason_codes
FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
AND reconciliation_outcome_code<>'NO_PAYMENT_ACTIVITY_RECONCILED'
ORDER BY scenario_code,merchant_application_id;
/* Result Set 15 — State Certification Distribution */
SELECT scenario_code,certified_state_code,count(*) AS certification_rows,
count(*) FILTER(WHERE state_certified_flag) AS state_certified_rows,
count(*) FILTER(WHERE exception_resolved_flag) AS exception_resolved_rows,
round(sum(certified_exposure_amount),2) AS certified_exposure_amount,
min(certification_date) AS first_certification_date,max(certification_date) AS last_certification_date
FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
GROUP BY scenario_code,certified_state_code ORDER BY scenario_code,certified_state_code;
/* Result Set 16 — State Certification Detail */
SELECT scenario_code,merchant_application_id,synthetic_account_id,synthetic_advance_id,
source_final_lifecycle_state_code,certified_state_code,state_certified_flag,active_state_flag,closed_state_flag,
review_hold_state_flag,exception_resolved_flag,certified_exposure_amount,certification_date,
primary_certification_reason_code,certification_reason_codes,source_account_reconciliation_row_hash,row_hash
FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
ORDER BY scenario_code,certified_state_code,merchant_application_id;
/* Result Set 17 — Portfolio Reconciliation and Certification Summary */
SELECT * FROM msbf_m2.payment_reconciliation_portfolio_summary
WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx) ORDER BY scenario_code;
/* Result Set 18 — Matched Baseline / Stress Comparison */
SELECT merchant_application_id,baseline_reconciliation_outcome_code,stress_reconciliation_outcome_code,
baseline_certified_state_code,stress_certified_state_code,baseline_certification_rank,stress_certification_rank,
baseline_state_certified_flag,stress_state_certified_flag,baseline_certified_exposure_amount,
stress_certified_exposure_amount,stress_certification_permission_improvement_flag,
stress_certification_rank_improvement_flag,stress_exposure_improvement_flag
FROM msbf_m2.v_m2_9_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
ORDER BY merchant_application_id;
/* Result Set 19 — Stress Non-Improvement Summary */
SELECT count(*) AS matched_rows,
count(*) FILTER(WHERE stress_certification_permission_improvement_flag) AS stress_certification_permission_improvements,
count(*) FILTER(WHERE stress_certification_rank_improvement_flag) AS stress_certification_rank_improvements,
count(*) FILTER(WHERE stress_exposure_improvement_flag) AS stress_exposure_improvements
FROM msbf_m2.v_m2_9_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx);
/* Result Set 20 — Latest / Archive Reproduction */
SELECT count(*) AS joined_rows,count(*) FILTER(WHERE latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash
OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at')) AS reproduction_mismatches
FROM msbf_m2.application_payment_reconciliation_certification_latest AS latest
FULL OUTER JOIN msbf_m2.application_payment_reconciliation_certification_archive AS archive
ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version
AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id
WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=(SELECT run_id FROM _m2_9_dctx);
/* Result Set 21 — Contract Registry and Canonical Hash Summary */
SELECT registry.*,canonical.canonical_entities AS physical_canonical_entities,
canonical.combined_set_hash AS physical_combined_set_hash
FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry AS registry
JOIN msbf_m2.v_m2_9_canonical_hash AS canonical ON canonical.module1_run_id=registry.module1_run_id
WHERE registry.module1_run_id=(SELECT run_id FROM _m2_9_dctx);
/* Result Set 22 — Governed Evidence Summary */
SELECT CASE WHEN evidence_code LIKE 'M2_9_POS_%' THEN 'POSITIVE'
WHEN evidence_code LIKE 'M2_9_NEG_%' THEN 'NEGATIVE'
WHEN evidence_code='M2_9_ACCEPTANCE_SUMMARY' THEN 'ACCEPTANCE' ELSE 'GENERATION' END AS family,
status,count(*) AS rows FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_9_dctx)
AND evidence_code LIKE 'M2_9_%' GROUP BY family,status ORDER BY family,status;
/* Result Set 23 — Deterministic Mismatches */
WITH mismatches AS(
SELECT 'POLICY'::text AS entity_type,policy_code||'|v'||policy_version::text AS entity_key,row_hash AS stored_hash,
msbf_ctl.m2_9_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'-'updated_at') AS reconstructed_hash
FROM msbf_ctl.m2_9_policy_profile AS p WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'RECONCILIATION_OUTCOME',reconciliation_outcome_code,row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(o)-'row_hash'-'created_at')
FROM msbf_m2.payment_reconciliation_outcome_definition AS o WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'RESOLUTION_ACTION',resolution_action_code,row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(a)-'row_hash'-'created_at')
FROM msbf_m2.exception_resolution_action_definition AS a WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'CERTIFICATION_STATE',certification_state_code,row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at')
FROM msbf_m2.account_state_certification_definition AS c WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'REASON_DEFINITION',reconciliation_reason_code,row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(r)-'row_hash'-'created_at')
FROM msbf_m2.payment_reconciliation_reason_definition AS r WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'ACCOUNT_SOURCE',scenario_id::text||'|'||merchant_application_id,row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')
FROM msbf_m2.account_reconciliation_source_snapshot AS s WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'PAYMENT_SOURCE',scenario_id::text||'|'||merchant_application_id||'|'||event_sequence::text,row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')
FROM msbf_m2.payment_reconciliation_source_event AS s WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'TRANSITION_SOURCE',scenario_id::text||'|'||merchant_application_id||'|'||transition_sequence::text,row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')
FROM msbf_m2.lifecycle_certification_source_transition AS s WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'PAYMENT_RECONCILIATION',scenario_id::text||'|'||merchant_application_id||'|'||event_sequence::text,row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(r)-'row_hash'-'created_at')
FROM msbf_m2.payment_event_reconciliation_snapshot AS r WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'EXCEPTION_CASE',scenario_id::text||'|'||merchant_application_id||'|'||synthetic_exception_case_id,row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(e)-'row_hash'-'created_at')
FROM msbf_m2.payment_exception_case_snapshot AS e WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'ACCOUNT_RECONCILIATION',scenario_id::text||'|'||merchant_application_id,row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(a)-'row_hash'-'created_at')
FROM msbf_m2.account_payment_reconciliation_snapshot AS a WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'STATE_CERTIFICATION',scenario_id::text||'|'||merchant_application_id,row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at')
FROM msbf_m2.account_state_certification_snapshot AS c WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'PORTFOLIO_SUMMARY',scenario_code,row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at')
FROM msbf_m2.payment_reconciliation_portfolio_summary AS p WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'LATEST',scenario_id::text||'|'||merchant_application_id,contract_row_hash,msbf_ctl.m2_9_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')
FROM msbf_m2.application_payment_reconciliation_certification_latest AS l WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'ARCHIVE',scenario_id::text||'|'||merchant_application_id,archive_row_hash,
msbf_ctl.m2_9_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at')
FROM msbf_m2.application_payment_reconciliation_certification_archive AS a WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
UNION ALL SELECT 'REGISTRY',contract_code||'|v'||contract_version::text,row_hash,msbf_ctl.m2_9_registry_row_hash(to_jsonb(r))
FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry AS r WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx))
SELECT entity_type,entity_key,stored_hash,reconstructed_hash FROM mismatches
WHERE stored_hash IS DISTINCT FROM reconstructed_hash ORDER BY entity_type,entity_key;
/* Result Set 24 — Blocking Errors and Stage-Boundary Violations */
SELECT 'FAILED_EVIDENCE'::text AS violation_type,evidence_code AS detail FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m2_9_dctx) AND evidence_code LIKE 'M2_9_%' AND status='FAIL'
UNION ALL SELECT 'ACCEPTANCE_NOT_PASS',coalesce(result_status,'<NULL>') FROM msbf_ctl.acceptance_gate_result
WHERE run_id=(SELECT run_id FROM _m2_9_dctx) AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND result_status<>'PASS'
UNION ALL SELECT 'PAYMENT_RECONCILIATION_BOUNDARY',scenario_code||'|'||merchant_application_id||'|'||event_sequence::text
FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
AND (real_funds_moved_flag OR external_system_called_flag)
UNION ALL SELECT 'EXCEPTION_BOUNDARY',scenario_code||'|'||merchant_application_id||'|'||synthetic_exception_case_id
FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
AND (real_funds_moved_flag OR external_system_called_flag)
UNION ALL SELECT 'ACCOUNT_RECONCILIATION_BOUNDARY',scenario_code||'|'||merchant_application_id
FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
AND (real_funds_moved_flag OR bank_account_data_present_flag OR ach_or_network_transmitted_flag OR external_processor_called_flag
OR merchant_contact_executed_flag OR write_off_or_collection_flag OR external_notice_generated_flag OR production_adverse_action_flag)
UNION ALL SELECT 'CERTIFICATION_BOUNDARY',scenario_code||'|'||merchant_application_id
FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
AND (real_funds_moved_flag OR production_account_state_flag OR external_system_update_flag)
UNION ALL SELECT 'UNRESOLVED_EXCEPTION',scenario_code||'|'||merchant_application_id||'|'||synthetic_exception_case_id
FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx) AND unresolved_exception_flag
UNION ALL SELECT 'RECONCILIATION_VARIANCE',scenario_code||'|'||merchant_application_id
FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx)
AND (reconciliation_variance_amount<>0 OR exposure_variance_amount<>0)
UNION ALL SELECT 'STRESS_IMPROVEMENT',merchant_application_id FROM msbf_m2.v_m2_9_matched_scenario_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_9_dctx) AND
(stress_certification_permission_improvement_flag OR stress_certification_rank_improvement_flag OR stress_exposure_improvement_flag)
UNION ALL SELECT 'PROHIBITED_COLUMN',table_schema||'.'||table_name||'.'||column_name FROM information_schema.columns
WHERE table_schema='msbf_m2' AND table_name IN('payment_event_reconciliation_snapshot','payment_exception_case_snapshot',
'account_payment_reconciliation_snapshot','account_state_certification_snapshot',
'application_payment_reconciliation_certification_latest','application_payment_reconciliation_certification_archive')
AND lower(column_name) IN('real_bank_account_number','bank_account_number','routing_number','ach_trace_number',
'payment_network_confirmation','processor_authorization_code','external_notice_payload','production_adverse_action_notice')
UNION ALL SELECT 'PREMATURE_M2_10_OBJECT',table_schema||'.'||table_name FROM information_schema.tables
WHERE table_schema IN('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_10%';
