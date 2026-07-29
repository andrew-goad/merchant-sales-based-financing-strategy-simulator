/* ============================================================================
MSBF M1.16 Acquisition Foundations Detailed Report
Program : 123_MSBF_M1_16_Acquisition_Foundations_Detail_Report_v0_2R1.sql
Version : v0.2R3
Purpose : Produce 24 clearly labeled, read-only evidence result sets covering
          governance, source taxonomy, campaigns, funnel, cost ledger,
          attribution, allocation, M1.14 overlap, companion contracts,
          integrated consumption, deterministic reconciliation, and boundaries.
Expected: Result sets 23 and 24 retain headers and contain zero data rows.
============================================================================ */
BEGIN;
SET LOCAL work_mem='96MB';
SET LOCAL jit=off;
SET LOCAL statement_timeout='20min';

DROP TABLE IF EXISTS _m1_16_detail_run;
CREATE TEMP TABLE _m1_16_detail_run ON COMMIT PRESERVE ROWS AS
SELECT run_id,run_code,run_version,run_status,population_id,as_of_date
FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

DROP TABLE IF EXISTS _m1_16_detail_cost;
CREATE TEMP TABLE _m1_16_detail_cost ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run);
CREATE UNIQUE INDEX ON _m1_16_detail_cost(merchant_application_id);

DROP TABLE IF EXISTS _m1_16_detail_attr;
CREATE TEMP TABLE _m1_16_detail_attr ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run);
CREATE UNIQUE INDEX ON _m1_16_detail_attr(merchant_application_id);

DROP TABLE IF EXISTS _m1_16_detail_mismatches;
CREATE TEMP TABLE _m1_16_detail_mismatches(
 entity_type text,entity_key text,stored_hash text,recomputed_hash text,mismatch_reason text
) ON COMMIT PRESERVE ROWS;
INSERT INTO _m1_16_detail_mismatches
SELECT 'SOURCE',acquisition_source_code,row_hash,msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'),'PHYSICAL_ROW_HASH'
FROM msbf_m1.acquisition_source_profile x WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run) AND row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at')
UNION ALL SELECT 'CAMPAIGN',acquisition_campaign_id,row_hash,msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'),'PHYSICAL_ROW_HASH'
FROM msbf_m1.acquisition_marketing_campaign x WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run) AND row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at')
UNION ALL SELECT 'FUNNEL',acquisition_campaign_id||'|'||stage_code,row_hash,msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'),'PHYSICAL_ROW_HASH'
FROM msbf_m1.acquisition_campaign_funnel_stage x WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run) AND row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at')
UNION ALL SELECT 'LEDGER',acquisition_cost_line_id,row_hash,msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'),'PHYSICAL_ROW_HASH'
FROM msbf_m1.acquisition_cost_ledger x WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run) AND row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at')
UNION ALL SELECT 'TOUCHPOINT',merchant_application_id||'|'||touchpoint_sequence,row_hash,msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'),'PHYSICAL_ROW_HASH'
FROM msbf_m1.application_acquisition_touchpoint x WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run) AND row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at')
UNION ALL SELECT 'ATTRIBUTION',merchant_application_id,row_hash,msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'),'PHYSICAL_ROW_HASH'
FROM msbf_m1.application_acquisition_attribution_snapshot x WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run) AND row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at')
UNION ALL SELECT 'COST',merchant_application_id,row_hash,msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'),'PHYSICAL_ROW_HASH'
FROM msbf_m1.application_acquisition_cost_snapshot x WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run) AND row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at')
UNION ALL SELECT 'COMPONENT',merchant_application_id||'|'||cost_component_code,row_hash,msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'),'PHYSICAL_ROW_HASH'
FROM msbf_m1.application_acquisition_cost_component_value x WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run) AND row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at')
UNION ALL SELECT 'LATEST',merchant_application_id,contract_row_hash,msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'contract_row_hash'-'created_at'),'PHYSICAL_ROW_HASH'
FROM msbf_m1.application_acquisition_contract_latest x WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run) AND contract_row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'contract_row_hash'-'created_at')
UNION ALL SELECT 'ARCHIVE',a.merchant_application_id,a.contract_row_hash,l.contract_row_hash,'LATEST_ARCHIVE_REPRODUCTION'
FROM msbf_m1.application_acquisition_contract_archive a
JOIN msbf_m1.application_acquisition_contract_latest l ON l.module1_run_id=a.module1_run_id AND l.merchant_application_id=a.merchant_application_id
WHERE a.module1_run_id=(SELECT run_id FROM _m1_16_detail_run) AND (a.contract_row_hash<>l.contract_row_hash OR a.contract_payload IS DISTINCT FROM to_jsonb(l)-'created_at');

COMMIT;

/* 01 — Run, stage, contract lifecycle, and acceptance gate */
SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.population_id,r.as_of_date,
 c.contract_code,c.contract_version,c.schema_version,c.methodology_version,c.contract_status,
 c.generated_at,c.validated_at,c.accepted_at,g.review_version,g.result_status AS gate_status,g.reviewed_at
FROM _m1_16_detail_run r
JOIN msbf_ctl.m1_16_acquisition_contract_registry c ON c.module1_run_id=r.run_id
LEFT JOIN LATERAL (
 SELECT review_version,result_status,reviewed_at FROM msbf_ctl.acceptance_gate_result
 WHERE run_id=r.run_id AND gate_id='M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS' ORDER BY review_version DESC LIMIT 1
) g ON true;

/* 02 — Contract registry, source hashes, counts, and set hashes */
SELECT * FROM msbf_ctl.m1_16_acquisition_contract_registry
WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run);

/* 03 — Entity cardinality and unique grains */
SELECT 'SOURCE_PROFILE' entity_family,count(*) row_count,count(DISTINCT acquisition_source_code) distinct_key_count FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
UNION ALL SELECT 'CAMPAIGN',count(*),count(DISTINCT acquisition_campaign_id) FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
UNION ALL SELECT 'FUNNEL',count(*),count(DISTINCT acquisition_campaign_id||'|'||stage_code) FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
UNION ALL SELECT 'COST_LEDGER',count(*),count(DISTINCT acquisition_cost_line_id) FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
UNION ALL SELECT 'TOUCHPOINT',count(*),count(DISTINCT merchant_application_id||'|'||touchpoint_sequence) FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
UNION ALL SELECT 'ATTRIBUTION',count(*),count(DISTINCT merchant_application_id) FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
UNION ALL SELECT 'COST_SNAPSHOT',count(*),count(DISTINCT merchant_application_id) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
UNION ALL SELECT 'COMPONENT',count(*),count(DISTINCT merchant_application_id||'|'||cost_component_code) FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
UNION ALL SELECT 'LATEST',count(*),count(DISTINCT merchant_application_id) FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
UNION ALL SELECT 'ARCHIVE',count(*),count(DISTINCT merchant_application_id) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
ORDER BY entity_family;

/* 04 — Acquisition-source taxonomy and parent-channel mapping */
SELECT accepted_partner_channel_id,accepted_channel_type,normalized_source_family,source_classification,
 count(*) source_profiles,count(*) FILTER(WHERE third_party_flag) third_party_sources,
 count(*) FILTER(WHERE source_evidence_status='COMPLETE') complete_sources,
 count(*) FILTER(WHERE source_evidence_status='PARTIAL') partial_sources
FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
GROUP BY accepted_partner_channel_id,accepted_channel_type,normalized_source_family,source_classification
ORDER BY accepted_partner_channel_id,normalized_source_family,source_classification;

/* 05 — Campaign inventory, status, dates, and governance */
SELECT acquisition_campaign_id,acquisition_source_code,accepted_partner_channel_id,campaign_family_code,
 campaign_type,campaign_name_synthetic,effective_start_date,effective_end_date,campaign_status,
 approval_status,budget_amount,spend_amount,owner_classification,vendor_partner_code,always_on_flag,campaign_evidence_status
FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
ORDER BY accepted_partner_channel_id,acquisition_campaign_id;

/* 06 — Funnel counts and conversion metrics */
SELECT f.acquisition_campaign_id,c.accepted_partner_channel_id,c.campaign_name_synthetic,
 f.stage_code,f.stage_order,f.stage_count,f.conversion_rate_from_prior,f.applicability_status,f.evidence_status
FROM msbf_m1.acquisition_campaign_funnel_stage f
JOIN msbf_m1.acquisition_marketing_campaign c ON c.module1_run_id=f.module1_run_id AND c.acquisition_campaign_id=f.acquisition_campaign_id
WHERE f.module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
ORDER BY f.acquisition_campaign_id,f.stage_order;

/* 07 — Campaign budget/spend and cost-ledger reconciliation */
SELECT c.acquisition_campaign_id,c.accepted_partner_channel_id,c.budget_amount,c.spend_amount,
 sum(l.gross_cost_amount) FILTER(WHERE NOT l.conditional_flag) incurred_ledger_amount,
 max(l.unit_rate) FILTER(WHERE l.conditional_flag) conditional_rate,
 c.spend_amount-sum(l.gross_cost_amount) FILTER(WHERE NOT l.conditional_flag) reconciliation_difference
FROM msbf_m1.acquisition_marketing_campaign c
JOIN msbf_m1.acquisition_cost_ledger l ON l.module1_run_id=c.module1_run_id AND l.acquisition_campaign_id=c.acquisition_campaign_id
WHERE c.module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
GROUP BY c.acquisition_campaign_id,c.accepted_partner_channel_id,c.budget_amount,c.spend_amount
ORDER BY c.acquisition_campaign_id;

/* 08 — Cost component, basis, and timing distribution */
SELECT cost_component_code,cost_basis_code,cost_timing_code,conditional_flag,allocable_flag,evidence_status,
 count(*) ledger_lines,sum(gross_cost_amount) gross_cost_amount,min(unit_rate) min_rate,max(unit_rate) max_rate
FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
GROUP BY cost_component_code,cost_basis_code,cost_timing_code,conditional_flag,allocable_flag,evidence_status
ORDER BY cost_timing_code,cost_component_code;

/* 09 — Application touchpoint count, order, and temporal integrity */
SELECT t.merchant_application_id,count(*) touchpoint_count,min(t.touchpoint_timestamp) first_timestamp,
 max(t.touchpoint_timestamp) last_timestamp,count(*) FILTER(WHERE first_touch_flag) first_flags,
 count(*) FILTER(WHERE last_touch_flag) last_flags,count(*) FILTER(WHERE primary_attribution_flag) primary_flags,
 sum(attribution_weight) attribution_weight_sum,
 bool_or(t.touchpoint_timestamp>a.application_date::timestamptz+interval '23 hours 59 minutes 59 seconds') AS future_touchpoint_flag
FROM msbf_m1.application_acquisition_touchpoint t
JOIN msbf_m1.merchant_application a ON a.merchant_application_id=t.merchant_application_id
WHERE t.module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
GROUP BY t.merchant_application_id
ORDER BY t.merchant_application_id;

/* 10 — First, last, primary, and assisted attribution distribution */
SELECT accepted_partner_channel_id,first_touch_source_code,last_touch_source_code,primary_source_code,
 count(*) applications,sum(assisted_touch_count) assisted_touches,avg(touchpoint_count) avg_touchpoints,
 avg(attribution_confidence_score) avg_attribution_confidence
FROM _m1_16_detail_attr
GROUP BY accepted_partner_channel_id,first_touch_source_code,last_touch_source_code,primary_source_code
ORDER BY accepted_partner_channel_id,applications DESC;

/* 11 — Parent-channel alignment and governed exceptions */
SELECT accepted_partner_channel_id,parent_channel_reconciliation_status,attribution_evidence_status,
 fallback_path_code,primary_attribution_reason_code,count(*) applications
FROM _m1_16_detail_attr
GROUP BY accepted_partner_channel_id,parent_channel_reconciliation_status,attribution_evidence_status,
 fallback_path_code,primary_attribution_reason_code
ORDER BY accepted_partner_channel_id,attribution_evidence_status,fallback_path_code;

/* 12 — Attribution confidence, evidence status, and fallback paths */
SELECT attribution_confidence_tier,attribution_evidence_status,fallback_path_code,
 count(*) applications,min(attribution_confidence_score) min_score,avg(attribution_confidence_score) avg_score,
 max(attribution_confidence_score) max_score,avg(touchpoint_count) avg_touchpoints,avg(assisted_touch_count) avg_assisted
FROM _m1_16_detail_attr
GROUP BY attribution_confidence_tier,attribution_evidence_status,fallback_path_code
ORDER BY attribution_evidence_status,attribution_confidence_tier,fallback_path_code;

/* 13 — Direct attributable incurred acquisition cost */
SELECT accepted_partner_channel_id,primary_source_code,primary_campaign_id,count(*) applications,
 sum(paid_media_cost_amount) paid_media,sum(direct_mail_event_outbound_cost_amount) direct_mail,
 sum(purchased_lead_cost_amount) purchased_leads,sum(acquisition_incentive_cost_amount) incentives,
 sum(direct_attributable_incurred_cost_amount) direct_attributable_total,
 avg(direct_attributable_incurred_cost_amount) avg_direct_attributable
FROM _m1_16_detail_cost
GROUP BY accepted_partner_channel_id,primary_source_code,primary_campaign_id
ORDER BY accepted_partner_channel_id,primary_campaign_id;

/* 14 — Internal sales/RM, agency/technology, and overhead allocation */
SELECT accepted_partner_channel_id,primary_campaign_id,count(*) applications,
 sum(internal_sales_rm_cost_amount) internal_sales_rm,
 sum(agency_creative_tech_cost_amount) agency_creative_tech,
 sum(campaign_overhead_cost_amount) campaign_overhead,
 sum(internally_allocated_acquisition_cost_amount) internally_allocated_total,
 avg(internally_allocated_acquisition_cost_amount) avg_internally_allocated
FROM _m1_16_detail_cost
GROUP BY accepted_partner_channel_id,primary_campaign_id
ORDER BY accepted_partner_channel_id,primary_campaign_id;

/* 15 — Detailed conditional partner/broker cost */
SELECT accepted_partner_channel_id,primary_campaign_id,count(*) applications,
 min(accepted_m1_14_acquisition_cost_rate) min_legacy_rate,
 avg(accepted_m1_14_acquisition_cost_rate) avg_legacy_rate,
 max(accepted_m1_14_acquisition_cost_rate) max_legacy_rate,
 sum(detailed_conditional_partner_broker_cost_amount) conditional_if_booked,
 avg(detailed_conditional_partner_broker_cost_amount) avg_conditional_if_booked
FROM _m1_16_detail_cost
GROUP BY accepted_partner_channel_id,primary_campaign_id
ORDER BY accepted_partner_channel_id,primary_campaign_id;

/* 16 — Accepted M1.14 legacy rate/amount inheritance by channel */
SELECT accepted_partner_channel_id,count(*) applications,
 min(accepted_m1_14_acquisition_cost_rate) min_rate,avg(accepted_m1_14_acquisition_cost_rate) avg_rate,
 max(accepted_m1_14_acquisition_cost_rate) max_rate,sum(accepted_m1_14_acquisition_cost_amount) legacy_amount,
 count(DISTINCT m1_14_baseline_row_hash) baseline_hashes,count(DISTINCT m1_14_stress_row_hash) stress_hashes
FROM _m1_16_detail_cost
GROUP BY accepted_partner_channel_id ORDER BY accepted_partner_channel_id;

/* 17 — Legacy scope, overlap, unmapped legacy, incremental, and enhanced totals */
SELECT accepted_partner_channel_id,legacy_m1_14_cost_scope_code,overlap_evidence_status,
 acquisition_contract_evidence_status,count(*) applications,
 sum(accepted_m1_14_acquisition_cost_amount) legacy_cost,
 sum(mapped_detailed_cost_potentially_represented) mapped_detailed,
 sum(identified_legacy_overlap_amount) identified_overlap,
 sum(unmapped_legacy_proxy_amount) unmapped_legacy,
 sum(incremental_acquisition_cost_beyond_m1_14) incremental_beyond_m1_14,
 sum(enhanced_total_acquisition_cost_if_booked) enhanced_total_if_booked
FROM _m1_16_detail_cost
GROUP BY accepted_partner_channel_id,legacy_m1_14_cost_scope_code,overlap_evidence_status,acquisition_contract_evidence_status
ORDER BY accepted_partner_channel_id,acquisition_contract_evidence_status;

/* 18 — Direct-attributable versus fully loaded cost by source and campaign */
SELECT accepted_partner_channel_id,primary_source_code,primary_campaign_id,count(*) applications,
 sum(direct_attributable_incurred_cost_amount) direct_attributable,
 sum(internally_allocated_acquisition_cost_amount) internal_allocated,
 sum(total_incurred_pre_application_cost_amount) total_incurred,
 sum(detailed_total_acquisition_cost_if_booked) detailed_total_if_booked,
 sum(enhanced_total_acquisition_cost_if_booked) enhanced_total_if_booked
FROM _m1_16_detail_cost
GROUP BY accepted_partner_channel_id,primary_source_code,primary_campaign_id
ORDER BY accepted_partner_channel_id,primary_campaign_id;

/* 19 — Acquisition evidence status and blocking reasons */
SELECT acquisition_contract_evidence_status,attribution_evidence_status,cost_evidence_status,
 overlap_evidence_status,fallback_path_code,primary_cost_reason_code,count(*) applications,
 sum(detailed_total_acquisition_cost_if_booked) known_detailed_total,
 sum(enhanced_total_acquisition_cost_if_booked) supported_enhanced_total
FROM _m1_16_detail_cost
GROUP BY acquisition_contract_evidence_status,attribution_evidence_status,cost_evidence_status,
 overlap_evidence_status,fallback_path_code,primary_cost_reason_code
ORDER BY acquisition_contract_evidence_status,fallback_path_code,primary_cost_reason_code;

/* 20 — Industry, merchant size, and relationship-stage acquisition diagnostics */
SELECT m.industry_code,m.merchant_size_tier,m.relationship_stage,a.accepted_partner_channel_id,
 a.primary_source_code,count(*) applications,avg(a.attribution_confidence_score) avg_attribution_confidence,
 avg(c.total_incurred_pre_application_cost_amount) avg_incurred_cost,
 avg(c.detailed_total_acquisition_cost_if_booked) avg_detailed_if_booked,
 avg(c.enhanced_total_acquisition_cost_if_booked) avg_enhanced_if_booked
FROM msbf_m1.application_module1_latest m
JOIN _m1_16_detail_attr a ON a.module1_run_id=m.module1_run_id AND a.merchant_application_id=m.merchant_application_id
JOIN _m1_16_detail_cost c ON c.module1_run_id=m.module1_run_id AND c.merchant_application_id=m.merchant_application_id
WHERE m.module1_run_id=(SELECT run_id FROM _m1_16_detail_run) AND m.scenario_code='BASELINE'
GROUP BY m.industry_code,m.merchant_size_tier,m.relationship_stage,a.accepted_partner_channel_id,a.primary_source_code
ORDER BY m.industry_code,m.merchant_size_tier,m.relationship_stage,a.accepted_partner_channel_id;

/* 21 — Integrated M1.15/M1.16 scenario-aware consumption diagnostics */
SELECT scenario_code,count(*) integrated_rows,count(DISTINCT merchant_application_id) applications,
 avg(source_confidence_score) avg_source_confidence,avg(operating_resilience_score) avg_resilience,
 avg(integrated_risk_score) avg_integrated_risk,avg(path_weighted_ead_amount) avg_path_ead,
 avg(lgd_input_rate) avg_lgd,avg(schedule_adjusted_comparative_expected_loss_amount) avg_comparative_loss,
 avg(risk_adjusted_contribution_amount) avg_risk_adjusted_contribution,
 avg(annualized_risk_adjusted_return_rate) avg_annualized_return,
 avg(total_incurred_pre_application_cost_amount) avg_incurred_acquisition_cost,
 avg(enhanced_total_acquisition_cost_if_booked) avg_enhanced_acquisition_cost
FROM msbf_m1.v_m1_16_module1_integrated_consumption
WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run)
GROUP BY scenario_code ORDER BY scenario_code;

/* 22 — Governed M1.16 evidence and validation summary */
SELECT evidence_code,metric_name,status,metric_value_numeric,metric_value_text,unit_code,interpretation,created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m1_16_detail_run) AND evidence_code LIKE 'M1_16_%'
ORDER BY evidence_code;

/* 23 — Deterministic mismatches: zero data rows required */
SELECT entity_type,entity_key,stored_hash,recomputed_hash,mismatch_reason
FROM _m1_16_detail_mismatches ORDER BY entity_type,entity_key;

/* 24 — Blocking errors, stage-boundary violations, and unauthorized mutation: zero rows required */
SELECT 'PROFILE_RESOLUTION_ERROR'::text AS finding_type,error_code::text AS finding_code,
 severity::text AS severity,error_message::text AS finding_detail,profile_domain::text AS object_name
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM _m1_16_detail_run) AND severity='BLOCKING'
UNION ALL
SELECT 'UNAUTHORIZED_MODULE2_OBJECT'::text,table_name::text,'BLOCKING'::text,
 'M1.16 must not create pricing, approval, offer, funding, CAC payback, LTV, or optimization outputs.'::text,
 (table_schema||'.'||table_name)::text
FROM information_schema.tables
WHERE table_schema='msbf_m1' AND table_name LIKE 'm1_16%'
  AND lower(table_name) ~ '(pricing|approval|offer|funded|payback|ltv|optimization|decision)'
UNION ALL
SELECT 'UPSTREAM_CARDINALITY_DRIFT'::text,'M1_15_LATEST_COUNT'::text,'BLOCKING'::text,
 'Accepted M1.15 latest count differs from 1,500.'::text,'msbf_m1.application_module1_latest'::text
WHERE (SELECT count(*) FROM msbf_m1.application_module1_latest WHERE module1_run_id=(SELECT run_id FROM _m1_16_detail_run))<>1500;
