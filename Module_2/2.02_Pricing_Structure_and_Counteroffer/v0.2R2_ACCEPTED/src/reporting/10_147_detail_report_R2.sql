/* ============================================================================
M2.2 Program 147 v0.2R2 — Detailed Report
Twenty-four governed read-only result sets. Result Sets 23 and 24 must retain
headers and contain zero data rows.
============================================================================ */
SET statement_timeout='45min'; SET jit=off;
DROP TABLE IF EXISTS _m2_2_dctx; CREATE TEMP TABLE _m2_2_dctx ON COMMIT PRESERVE ROWS AS SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
/* Result Set 01 — Run, Contract Lifecycle and Acceptance Gate */
SELECT r.run_id,r.run_status,c.contract_status,c.request_contract_code,c.pricing_contract_code,c.methodology_version,g.result_status AS gate_status,c.generated_at,c.validated_at,c.accepted_at FROM _m2_2_dctx r JOIN msbf_ctl.m2_2_pricing_structure_contract_registry c ON c.module1_run_id=r.run_id LEFT JOIN msbf_ctl.acceptance_gate_result g ON g.run_id=r.run_id AND g.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' ORDER BY g.review_version DESC LIMIT 1;
/* Result Set 02 — Policy and Stage Boundary */
SELECT policy_code,policy_status,methodology_version,request_contract_code,request_schema_version,pricing_contract_code,pricing_schema_version,source_m2_1_contract_code,required_source_m2_1_hash,source_m1_3_gate_id,required_source_m1_3_hash,synthetic_data_only_flag,counteroffer_foundation_only_flag,no_final_credit_decision_flag,no_production_adverse_action_flag,no_booking_funding_flag,acquisition_source_noncredit_flag,stress_nonimprovement_flag,request_companion_required_flag,configuration_hash FROM msbf_ctl.m2_2_policy_profile WHERE policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1';
/* Result Set 03 — Candidate Template Definitions */
SELECT candidate_template_code,template_sequence,applicable_route_code,amount_multiplier,remittance_multiplier,payback_multiplier,horizon_multiplier,counteroffer_foundation_flag,active_flag,description,row_hash FROM msbf_m2.pricing_structure_candidate_template WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) ORDER BY applicable_route_code,template_sequence;
/* Result Set 04 — Reason Definitions */
SELECT reason_code,reason_category,associated_disposition_code,reason_priority,display_text,production_adverse_action_flag,active_flag,row_hash FROM msbf_m2.pricing_structure_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) ORDER BY reason_priority,reason_code;
/* Result Set 05 — Disposition Definitions */
SELECT disposition_code,disposition_rank,structure_available_flag,review_required_flag,final_decision_flag,booking_funding_flag,active_flag,description,row_hash FROM msbf_m2.pricing_structure_disposition_definition WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) ORDER BY disposition_rank;
/* Result Set 06 — Entity Cardinality and Grains */
SELECT 'REQUEST_SNAPSHOT' AS entity_type,count(*) AS rows,count(DISTINCT merchant_application_id) AS applications FROM msbf_m2.application_request_structure_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) UNION ALL SELECT 'REQUEST_LATEST',count(*),count(DISTINCT merchant_application_id) FROM msbf_m2.application_request_structure_latest WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) UNION ALL SELECT 'REQUEST_ARCHIVE',count(*),count(DISTINCT merchant_application_id) FROM msbf_m2.application_request_structure_archive WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) UNION ALL SELECT 'CANDIDATE',count(*),count(DISTINCT merchant_application_id) FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) UNION ALL SELECT 'PRICING_SNAPSHOT',count(*),count(DISTINCT merchant_application_id) FROM msbf_m2.application_pricing_structure_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) UNION ALL SELECT 'PRICING_LATEST',count(*),count(DISTINCT merchant_application_id) FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) UNION ALL SELECT 'PRICING_ARCHIVE',count(*),count(DISTINCT merchant_application_id) FROM msbf_m2.application_pricing_structure_archive WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx);
/* Result Set 07 — Requested Structure Distribution */
SELECT requested_expected_payoff_days,application_channel,requested_use_of_proceeds,count(*) AS applications,round(avg(requested_funding_amount),2) AS average_requested_amount,round(avg(requested_remittance_rate),6) AS average_requested_remittance FROM msbf_m2.application_request_structure_latest WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) GROUP BY requested_expected_payoff_days,application_channel,requested_use_of_proceeds ORDER BY applications DESC;
/* Result Set 08 — Candidate Count by Template and Scenario */
SELECT scenario_code,candidate_template_code,source_route_code,count(*) AS candidate_rows,count(*) FILTER(WHERE selected_foundation_flag) AS selected_rows,round(avg(candidate_funding_amount),2) AS average_amount,round(avg(candidate_remittance_rate),6) AS average_remittance,round(avg(candidate_payback_multiple),6) AS average_payback FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) GROUP BY scenario_code,candidate_template_code,source_route_code ORDER BY scenario_code,source_route_code,candidate_template_code;
/* Result Set 09 — Candidate Amount Distribution */
SELECT scenario_code,source_route_code,min(candidate_funding_amount) AS minimum_amount,percentile_cont(0.5) WITHIN GROUP(ORDER BY candidate_funding_amount) AS median_amount,max(candidate_funding_amount) AS maximum_amount,round(avg(amount_to_request_ratio),6) AS average_request_ratio FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) GROUP BY scenario_code,source_route_code ORDER BY scenario_code,source_route_code;
/* Result Set 10 — Candidate Remittance and Payback Distribution */
SELECT scenario_code,source_route_code,min(candidate_remittance_rate) AS minimum_remittance,max(candidate_remittance_rate) AS maximum_remittance,round(avg(candidate_remittance_rate),6) AS average_remittance,min(candidate_payback_multiple) AS minimum_payback,max(candidate_payback_multiple) AS maximum_payback,round(avg(candidate_payback_multiple),6) AS average_payback FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) GROUP BY scenario_code,source_route_code ORDER BY scenario_code,source_route_code;
/* Result Set 11 — Candidate Horizon and Payoff Diagnostics */
SELECT scenario_code,candidate_template_code,min(candidate_collection_horizon_days) AS minimum_horizon,max(candidate_collection_horizon_days) AS maximum_horizon,round(avg(candidate_collection_horizon_days),2) AS average_horizon,round(avg(implied_payoff_days),2) AS average_implied_payoff FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) GROUP BY scenario_code,candidate_template_code ORDER BY scenario_code,candidate_template_code;
/* Result Set 12 — Pricing Disposition by Scenario */
SELECT scenario_code,pricing_disposition_code,structure_available_flag,review_required_flag,count(*) AS rows FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) GROUP BY scenario_code,pricing_disposition_code,structure_available_flag,review_required_flag ORDER BY scenario_code,pricing_disposition_code;
/* Result Set 13 — Selected Template Distribution */
SELECT scenario_code,selected_candidate_template_code,counteroffer_foundation_flag,count(*) AS rows,round(avg(selected_funding_amount),2) AS average_amount,round(avg(selected_remittance_rate),6) AS average_remittance FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) AND structure_available_flag GROUP BY scenario_code,selected_candidate_template_code,counteroffer_foundation_flag ORDER BY scenario_code,selected_candidate_template_code;
/* Result Set 14 — Primary Reason Distribution */
SELECT scenario_code,primary_reason_code,pricing_disposition_code,count(*) AS rows FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) GROUP BY scenario_code,primary_reason_code,pricing_disposition_code ORDER BY scenario_code,rows DESC;
/* Result Set 15 — Matched Baseline Stress Structure Migration */
SELECT baseline_disposition_code,stress_disposition_code,count(*) AS applications,count(*) FILTER(WHERE stress_structure_improvement_flag) AS stress_improvements,round(avg(stress_selected_funding_amount-baseline_selected_funding_amount),2) AS average_amount_delta,round(avg(stress_selected_remittance_rate-baseline_selected_remittance_rate),6) AS average_remittance_delta,round(avg(stress_selected_payback_multiple-baseline_selected_payback_multiple),6) AS average_payback_delta FROM msbf_m2.v_m2_2_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) GROUP BY baseline_disposition_code,stress_disposition_code ORDER BY baseline_disposition_code,stress_disposition_code;
/* Result Set 16 — Stress Non-Improvement Diagnostics */
SELECT
    count(*) AS matched_applications,

    count(*) FILTER
    (
        WHERE stress_structure_improvement_flag
    ) AS stress_improvements,

    count(*) FILTER
    (
        WHERE stress_selected_funding_amount <=
              baseline_selected_funding_amount
           OR stress_selected_funding_amount IS NULL
           OR baseline_selected_funding_amount IS NULL
    ) AS nonincreasing_amount_rows,

    count(*) FILTER
    (
        WHERE stress_selected_remittance_rate >=
              baseline_selected_remittance_rate
           OR stress_selected_remittance_rate IS NULL
           OR baseline_selected_remittance_rate IS NULL
    ) AS nondecreasing_remittance_rows,

    count(*) FILTER
    (
        WHERE stress_selected_payback_multiple >=
              baseline_selected_payback_multiple
           OR stress_selected_payback_multiple IS NULL
           OR baseline_selected_payback_multiple IS NULL
    ) AS nondecreasing_payback_rows,

    count(*) FILTER
    (
        WHERE stress_collection_horizon_days >=
              baseline_collection_horizon_days
           OR stress_collection_horizon_days IS NULL
           OR baseline_collection_horizon_days IS NULL
    ) AS nondecreasing_horizon_rows,

    (
        SELECT count(*)
        FROM msbf_m2.application_pricing_structure_latest
        WHERE module1_run_id =
              (SELECT run_id FROM _m2_2_dctx)
          AND stress_nonimprovement_applied_flag
    ) AS stress_floor_applied_rows

FROM msbf_m2.v_m2_2_matched_scenario_comparison

WHERE module1_run_id =
      (SELECT run_id FROM _m2_2_dctx);
/* Result Set 17 — M2.1 Route to M2.2 Disposition */
SELECT source_route_code,pricing_disposition_code,count(*) AS rows FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) GROUP BY source_route_code,pricing_disposition_code ORDER BY source_route_code,pricing_disposition_code;
/* Result Set 18 — Acquisition Economics Diagnostics */
SELECT scenario_code,candidate_template_code,count(*) AS rows,round(avg(acquisition_economics_amount),2) AS average_acquisition_economics,round(avg(expected_loss_amount),2) AS average_expected_loss,round(avg(risk_adjusted_contribution_amount),2) AS average_risk_adjusted_contribution,round(avg(annualized_return_rate),6) AS average_return FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) GROUP BY scenario_code,candidate_template_code ORDER BY scenario_code,candidate_template_code;
/* Result Set 19 — Latest Archive Reproduction */
SELECT 'REQUEST' AS contract_family,count(*) AS joined_rows,count(*) FILTER(WHERE l.contract_row_hash IS DISTINCT FROM a.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) AS reproduction_mismatches FROM msbf_m2.application_request_structure_latest l FULL OUTER JOIN msbf_m2.application_request_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m2_2_dctx) UNION ALL SELECT 'PRICING',count(*),count(*) FILTER(WHERE l.contract_row_hash IS DISTINCT FROM a.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) FROM msbf_m2.application_pricing_structure_latest l FULL OUTER JOIN msbf_m2.application_pricing_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m2_2_dctx);
/* Result Set 20 — Contract Registry and Hash Summary */
SELECT module1_run_id,request_contract_code,request_contract_version,request_schema_version,pricing_contract_code,pricing_contract_version,pricing_schema_version,methodology_version,source_m2_1_combined_hash,source_m1_3_application_hash,policy_configuration_hash,policy_rows,template_rows,reason_rows,disposition_rows,request_snapshot_rows,request_latest_rows,request_archive_rows,candidate_rows,pricing_snapshot_rows,pricing_latest_rows,pricing_archive_rows,comparison_rows,canonical_entities,policy_set_hash,template_set_hash,reason_set_hash,disposition_set_hash,request_snapshot_set_hash,request_latest_set_hash,request_archive_set_hash,candidate_set_hash,pricing_snapshot_set_hash,pricing_latest_set_hash,pricing_archive_set_hash,request_contract_set_hash,pricing_contract_set_hash,combined_set_hash,contract_status,generated_at,validated_at,accepted_at FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx);
/* Result Set 21 — Governed M2.2 Evidence Summary */
SELECT CASE WHEN evidence_code LIKE 'M2_2_POS_%' THEN 'POSITIVE_VALIDATION' WHEN evidence_code LIKE 'M2_2_NEG_%' THEN 'NEGATIVE_CONTROL' WHEN evidence_code='M2_2_ACCEPTANCE_SUMMARY' THEN 'ACCEPTANCE' ELSE 'GENERATION' END AS evidence_family,status,count(*) AS evidence_rows FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_2_dctx) AND evidence_code LIKE 'M2_2_%' GROUP BY evidence_family,status ORDER BY evidence_family,status;
/* Result Set 22 — Sample Pricing and Structure Profiles */
SELECT scenario_code,merchant_application_id,source_route_code,pricing_disposition_code,selected_candidate_template_code,requested_funding_amount,selected_funding_amount,selected_remittance_rate,selected_payback_multiple,selected_collection_horizon_days,selected_amount_to_request_ratio,candidate_count,counteroffer_foundation_flag,primary_reason_code FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) ORDER BY scenario_code,merchant_application_id LIMIT 40;
/* Result Set 23 — Deterministic Mismatches */
SELECT 'REQUEST_SNAPSHOT' AS entity_type,s.merchant_application_id AS entity_key,s.row_hash AS stored_hash,msbf_ctl.m2_2_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at') AS reconstructed_hash FROM msbf_m2.application_request_structure_snapshot s WHERE s.module1_run_id=(SELECT run_id FROM _m2_2_dctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_2_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at') UNION ALL SELECT 'CANDIDATE',c.scenario_id::text||'|'||c.merchant_application_id||'|'||c.candidate_template_code,c.row_hash,msbf_ctl.m2_2_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at') FROM msbf_m2.application_pricing_structure_candidate c WHERE c.module1_run_id=(SELECT run_id FROM _m2_2_dctx) AND c.row_hash IS DISTINCT FROM msbf_ctl.m2_2_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at') UNION ALL SELECT 'PRICING_SNAPSHOT',s.scenario_id::text||'|'||s.merchant_application_id,s.row_hash,msbf_ctl.m2_2_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at') FROM msbf_m2.application_pricing_structure_snapshot s WHERE s.module1_run_id=(SELECT run_id FROM _m2_2_dctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_2_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at');
/* Result Set 24 — Blocking Errors and Stage-Boundary Violations */
SELECT 'FAILED_EVIDENCE' AS violation_type,'msbf_ctl.run_evidence' AS object_name,evidence_code AS violation_detail FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_2_dctx) AND evidence_code LIKE 'M2_2_%' AND status='FAIL' UNION ALL SELECT 'BLOCKING_ERROR','msbf_ctl.profile_resolution_error',error_code FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m2_2_dctx) AND severity='BLOCKING' UNION ALL SELECT 'PROHIBITED_COLUMN',table_schema||'.'||table_name,column_name FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name LIKE 'application_%structure%' AND lower(column_name) IN('approval_flag','decline_flag','final_decision_code','adverse_action_code','booking_status','funding_status') UNION ALL SELECT 'STRESS_IMPROVEMENT','msbf_m2.v_m2_2_matched_scenario_comparison',merchant_application_id FROM msbf_m2.v_m2_2_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_2_dctx) AND stress_structure_improvement_flag;
