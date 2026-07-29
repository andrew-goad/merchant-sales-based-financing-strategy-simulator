/* ============================================================================
MSBF M1.16 Acquisition Foundations Master Report
Program : 122_MSBF_M1_16_Acquisition_Foundations_Master_Report_v0_2R1.sql
Version : v0.2R3
Purpose : Produce one executive acceptance and portfolio-economics summary from
          persisted M1.16 physical records and governed evidence.
Safety  : Read-only. Does not regenerate attribution or cost logic.
============================================================================ */
SET statement_timeout='15min';
SET work_mem='64MB';

WITH r AS (
 SELECT run_id,run_code,run_version,run_status,population_id,as_of_date
 FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), c AS (
 SELECT * FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)
), pos AS (
 SELECT count(*) checks,count(*) FILTER(WHERE status='PASS') passes,count(*) FILTER(WHERE status='FAIL') failures
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_16_POS_%'
), neg AS (
 SELECT count(*) controls,count(*) FILTER(WHERE status='PASS') passes,count(*) FILTER(WHERE status='FAIL') failures
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_16_NEG_%'
), evidence AS (
 SELECT
  count(*) FILTER(WHERE acquisition_contract_evidence_status='COMPLETE') complete_rows,
  count(*) FILTER(WHERE acquisition_contract_evidence_status='PARTIAL') partial_rows,
  count(*) FILTER(WHERE acquisition_contract_evidence_status='BLOCKED') blocked_rows,
  count(*) FILTER(WHERE attribution_evidence_status='COMPLETE') complete_attribution_rows,
  count(*) FILTER(WHERE cost_evidence_status='COMPLETE') complete_cost_rows,
  count(*) FILTER(WHERE overlap_evidence_status='BLOCKED') blocked_overlap_rows,
  sum(direct_attributable_incurred_cost_amount) direct_incurred_cost,
  sum(internally_allocated_acquisition_cost_amount) internal_allocated_cost,
  sum(total_incurred_pre_application_cost_amount) detailed_incurred_cost,
  sum(detailed_conditional_partner_broker_cost_amount) detailed_conditional_cost,
  sum(detailed_total_acquisition_cost_if_booked) detailed_total_if_booked,
  sum(accepted_m1_14_acquisition_cost_amount) accepted_m1_14_legacy_cost,
  sum(identified_legacy_overlap_amount) identified_overlap,
  sum(unmapped_legacy_proxy_amount) unmapped_legacy_proxy,
  sum(incremental_acquisition_cost_beyond_m1_14) incremental_beyond_m1_14,
  sum(enhanced_total_acquisition_cost_if_booked) enhanced_total_if_booked
 FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM r)
), allocation AS (
 SELECT coalesce(sum(l.gross_cost_amount),0) incurred_ledger,
        coalesce((SELECT sum(total_incurred_pre_application_cost_amount) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM r)),0) allocated_incurred
 FROM msbf_m1.acquisition_cost_ledger l
 WHERE l.module1_run_id=(SELECT run_id FROM r) AND NOT l.conditional_flag
), mismatch AS (
 SELECT
  (SELECT count(*) FROM msbf_m1.acquisition_source_profile x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.acquisition_marketing_campaign x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.acquisition_campaign_funnel_stage x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.acquisition_cost_ledger x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.application_acquisition_touchpoint x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.application_acquisition_attribution_snapshot x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.application_acquisition_cost_snapshot x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.application_acquisition_cost_component_value x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.application_acquisition_contract_latest x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.contract_row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'contract_row_hash'-'created_at')) deterministic_mismatches,
  (SELECT count(*) FROM msbf_m1.application_acquisition_contract_archive a
   JOIN msbf_m1.application_acquisition_contract_latest l ON l.module1_run_id=a.module1_run_id AND l.merchant_application_id=a.merchant_application_id
   WHERE a.module1_run_id=(SELECT run_id FROM r) AND (a.contract_row_hash<>l.contract_row_hash OR a.contract_payload IS DISTINCT FROM to_jsonb(l)-'created_at')) archive_mismatches,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') blocking_errors
), gate AS (
 SELECT result_status,review_version FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS' ORDER BY review_version DESC LIMIT 1
)
SELECT
 clock_timestamp() AS report_timestamp,current_database() AS database_name,current_user AS database_user,
 r.run_id,r.run_code,r.run_version,r.run_status,r.population_id,r.as_of_date,
 c.methodology_version,c.contract_code,c.contract_version,c.schema_version,c.contract_status,
 c.source_m1_14_combined_hash,c.source_m1_15_combined_hash,c.policy_configuration_hash,
 c.source_profile_row_count,c.campaign_row_count,c.funnel_row_count,c.cost_ledger_row_count,
 c.touchpoint_row_count,c.attribution_row_count,c.cost_snapshot_row_count,c.component_row_count,
 c.latest_row_count,c.archive_row_count,
 (SELECT count(*) FROM msbf_m1.v_m1_16_module1_integrated_consumption WHERE module1_run_id=r.run_id) integrated_view_rows,
 evidence.complete_rows,evidence.partial_rows,evidence.blocked_rows,
 evidence.complete_attribution_rows,evidence.complete_cost_rows,evidence.blocked_overlap_rows,
 evidence.direct_incurred_cost,evidence.internal_allocated_cost,evidence.detailed_incurred_cost,
 evidence.detailed_conditional_cost,evidence.detailed_total_if_booked,evidence.accepted_m1_14_legacy_cost,
 evidence.identified_overlap,evidence.unmapped_legacy_proxy,evidence.incremental_beyond_m1_14,
 evidence.enhanced_total_if_booked,
 allocation.incurred_ledger,allocation.allocated_incurred,
 round(allocation.allocated_incurred-allocation.incurred_ledger,2) AS campaign_allocation_difference,
 pos.checks AS positive_controls_expected,pos.passes AS positive_controls_passed,pos.failures AS positive_controls_failed,
 neg.controls AS negative_controls_expected,neg.passes AS negative_controls_passed,neg.failures AS negative_controls_failed,
 mismatch.deterministic_mismatches,mismatch.archive_mismatches,mismatch.blocking_errors,
 c.source_profile_set_hash,c.campaign_set_hash,c.funnel_set_hash,c.cost_ledger_set_hash,
 c.touchpoint_set_hash,c.attribution_set_hash,c.cost_snapshot_set_hash,c.component_set_hash,
 c.latest_set_hash,c.archive_set_hash,c.contract_set_hash,c.combined_set_hash,
 gate.review_version AS acceptance_review_version,gate.result_status AS acceptance_gate_status,
 CASE WHEN r.run_status='M1_16_ACCEPTED' AND c.contract_status='ACCEPTED'
       AND gate.result_status='PASS'
       AND pos.checks=112 AND pos.passes=112 AND pos.failures=0
       AND neg.controls=20 AND neg.passes=20 AND neg.failures=0
       AND mismatch.deterministic_mismatches=0 AND mismatch.archive_mismatches=0 AND mismatch.blocking_errors=0
       AND round(allocation.allocated_incurred-allocation.incurred_ledger,2)=0
      THEN 'PASS' ELSE 'FAIL' END AS overall_m1_16_status
FROM r CROSS JOIN c CROSS JOIN pos CROSS JOIN neg CROSS JOIN evidence CROSS JOIN allocation CROSS JOIN mismatch LEFT JOIN gate ON true;
