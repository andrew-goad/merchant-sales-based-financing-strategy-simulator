/* ============================================================================
MSBF M2.1 — Eligibility, Policy Gates & Decision Routing Foundations
Program 139 — Detailed Evidence Report
Version v0.2R7
Read-only; 24 governed result sets. Result Sets 23 and 24 must be empty.
============================================================================ */

-- Result Set 01 — Run, contract lifecycle and acceptance gate
SELECT r.run_code,r.run_version,r.run_status,r.as_of_date,c.contract_code,c.contract_version,c.schema_version,c.contract_status,
       g.gate_id,g.review_version,g.result_status,g.reviewed_at,g.finding,g.residual_limitation
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m2_1_strategy_contract_registry c ON c.module1_run_id=r.run_id
LEFT JOIN LATERAL(SELECT * FROM msbf_ctl.acceptance_gate_result x WHERE x.run_id=r.run_id AND x.gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING' ORDER BY x.review_version DESC LIMIT 1) g ON true
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

-- Result Set 02 — Policy, campaign and registry identity
SELECT p.policy_code,p.methodology_version,p.policy_status,p.configuration_hash,
       c.strategy_campaign_code,c.strategy_campaign_version,c.strategy_campaign_name,c.campaign_status,
       r.contract_code,r.contract_version,r.schema_version,r.source_g2_combined_hash,r.policy_configuration_hash,r.canonical_entities,r.combined_set_hash
FROM msbf_ctl.m2_1_policy_profile p
JOIN msbf_m2.strategy_campaign c ON c.policy_code=p.policy_code
JOIN msbf_ctl.m2_1_strategy_contract_registry r ON r.module1_run_id=c.module1_run_id
WHERE p.policy_code='M2_1_ELIGIBILITY_POLICY_V1';

-- Result Set 03 — Accepted G2 source boundary
SELECT g.bundle_code,g.bundle_version,g.schema_version,g.bundle_status,g.integrated_consumption_rows,g.combined_g2_hash,
       count(v.*) AS source_rows,count(DISTINCT v.merchant_application_id) applications,count(DISTINCT v.scenario_id) scenarios
FROM msbf_ctl.m1_17_g2_bundle_registry g
JOIN msbf_m1.v_m1_17_g2_integrated_consumption v ON v.module1_run_id=g.module1_run_id
WHERE g.module1_run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
GROUP BY g.bundle_code,g.bundle_version,g.schema_version,g.bundle_status,g.integrated_consumption_rows,g.combined_g2_hash;

-- Result Set 04 — Entity cardinality and grains
SELECT entity_name,row_count,distinct_grain_count,row_count-distinct_grain_count AS grain_violations
FROM (VALUES
 ('STRATEGY_CAMPAIGN',(SELECT count(*) FROM msbf_m2.strategy_campaign),(SELECT count(DISTINCT (module1_run_id,strategy_campaign_code,strategy_campaign_version)) FROM msbf_m2.strategy_campaign)),
 ('GATE_DEFINITION',(SELECT count(*) FROM msbf_m2.policy_gate_definition),(SELECT count(DISTINCT (module1_run_id,strategy_campaign_code,gate_code)) FROM msbf_m2.policy_gate_definition)),
 ('REASON_CODE',(SELECT count(*) FROM msbf_m2.reason_code_definition),(SELECT count(DISTINCT (module1_run_id,strategy_campaign_code,reason_code)) FROM msbf_m2.reason_code_definition)),
 ('OUTCOME_DEFINITION',(SELECT count(*) FROM msbf_m2.routing_outcome_definition),(SELECT count(DISTINCT (module1_run_id,strategy_campaign_code,route_code)) FROM msbf_m2.routing_outcome_definition)),
 ('GATE_RESULT',(SELECT count(*) FROM msbf_m2.application_policy_gate_result),(SELECT count(DISTINCT (module1_run_id,strategy_campaign_code,scenario_id,merchant_application_id,gate_code)) FROM msbf_m2.application_policy_gate_result)),
 ('ROUTING_SNAPSHOT',(SELECT count(*) FROM msbf_m2.application_eligibility_routing_snapshot),(SELECT count(DISTINCT (module1_run_id,strategy_campaign_code,scenario_id,merchant_application_id)) FROM msbf_m2.application_eligibility_routing_snapshot)),
 ('LATEST',(SELECT count(*) FROM msbf_m2.application_eligibility_routing_latest),(SELECT count(DISTINCT (module1_run_id,strategy_campaign_code,scenario_id,merchant_application_id)) FROM msbf_m2.application_eligibility_routing_latest)),
 ('ARCHIVE',(SELECT count(*) FROM msbf_m2.application_eligibility_routing_archive),(SELECT count(DISTINCT (module1_run_id,contract_code,contract_version,strategy_campaign_code,scenario_id,merchant_application_id)) FROM msbf_m2.application_eligibility_routing_archive))
) t(entity_name,row_count,distinct_grain_count) ORDER BY entity_name;

-- Result Set 05 — Gate definitions
SELECT gate_sequence,gate_code,gate_name,gate_category,decision_influence_code,source_field_code,pass_rule,review_rule,fail_rule,blocked_rule,hard_stop_capable_flag
FROM msbf_m2.policy_gate_definition ORDER BY gate_sequence;

-- Result Set 06 — Transparent reason-code dictionary
SELECT reason_priority,reason_code,reason_category,source_gate_code,associated_route_code,display_text,production_adverse_action_flag
FROM msbf_m2.reason_code_definition ORDER BY reason_priority DESC,reason_code;

-- Result Set 07 — Routing outcome definitions
SELECT route_rank,route_code,route_name,eligible_for_offer_design_flag,terminal_flag,description
FROM msbf_m2.routing_outcome_definition ORDER BY route_rank;

-- Result Set 08 — Gate outcomes by scenario and gate
SELECT scenario_code,gate_sequence,gate_code,gate_outcome,count(*) AS rows,count(*) FILTER(WHERE hard_stop_flag) AS hard_stops
FROM msbf_m2.application_policy_gate_result GROUP BY scenario_code,gate_sequence,gate_code,gate_outcome ORDER BY scenario_code,gate_sequence,gate_outcome;

-- Result Set 09 — Final route distribution by scenario
SELECT scenario_code,final_route_rank,final_route_code,count(*) AS rows,count(*) FILTER(WHERE hard_stop_flag) hard_stops,
       count(*) FILTER(WHERE stress_floor_applied_flag) stress_floors
FROM msbf_m2.application_eligibility_routing_snapshot GROUP BY scenario_code,final_route_rank,final_route_code ORDER BY scenario_code,final_route_rank;

-- Result Set 10 — Routing evidence status
SELECT scenario_code,routing_evidence_status,count(*) AS rows FROM msbf_m2.application_eligibility_routing_snapshot
GROUP BY scenario_code,routing_evidence_status ORDER BY scenario_code,routing_evidence_status;

-- Result Set 11 — Primary reason distribution
SELECT scenario_code,final_route_code,primary_reason_code,count(*) AS rows
FROM msbf_m2.application_eligibility_routing_snapshot GROUP BY scenario_code,final_route_code,primary_reason_code ORDER BY scenario_code,final_route_code,rows DESC;

-- Result Set 12 — Hard-stop diagnostics
SELECT scenario_code,primary_reason_code,count(*) AS rows FROM msbf_m2.application_eligibility_routing_snapshot
WHERE hard_stop_flag GROUP BY scenario_code,primary_reason_code ORDER BY scenario_code,rows DESC;

-- Result Set 13 — Eligible-for-offer-design population
SELECT scenario_code,count(*) AS rows,count(DISTINCT merchant_application_id) AS applications,
       avg(pass_gate_count)::numeric(12,4) AS avg_pass_gates
FROM msbf_m2.application_eligibility_routing_snapshot WHERE final_route_code='ELIGIBLE_FOR_OFFER_DESIGN' GROUP BY scenario_code ORDER BY scenario_code;

-- Result Set 14 — Manual-review population
SELECT scenario_code,primary_reason_code,count(*) AS rows FROM msbf_m2.application_eligibility_routing_snapshot
WHERE final_route_code='MANUAL_REVIEW' GROUP BY scenario_code,primary_reason_code ORDER BY scenario_code,rows DESC;

-- Result Set 15 — Insufficient-evidence population
SELECT scenario_code,primary_reason_code,count(*) AS rows FROM msbf_m2.application_eligibility_routing_snapshot
WHERE final_route_code='INSUFFICIENT_EVIDENCE' GROUP BY scenario_code,primary_reason_code ORDER BY scenario_code,rows DESC;

-- Result Set 16 — Policy-decline population
SELECT scenario_code,primary_reason_code,count(*) AS rows,count(*) FILTER(WHERE hard_stop_flag) AS hard_stops
FROM msbf_m2.application_eligibility_routing_snapshot WHERE final_route_code='DECLINE_POLICY'
GROUP BY scenario_code,primary_reason_code ORDER BY scenario_code,rows DESC;

-- Result Set 17 — Matched baseline/stress route migration
SELECT baseline_route_code,stress_route_code,count(*) AS applications,
       count(*) FILTER(WHERE stress_route_rank>baseline_route_rank) AS worsenings,
       count(*) FILTER(WHERE stress_route_rank<baseline_route_rank) AS improvements,
       count(*) FILTER(WHERE stress_floor_applied_flag) AS floors
FROM msbf_m2.v_m2_1_matched_scenario_comparison GROUP BY baseline_route_code,stress_route_code ORDER BY baseline_route_code,stress_route_code;

-- Result Set 18 — Stress-floor diagnostics
SELECT stress_floor_applied_flag,stress_worsening_flag,count(*) AS applications
FROM msbf_m2.v_m2_1_matched_scenario_comparison GROUP BY stress_floor_applied_flag,stress_worsening_flag ORDER BY stress_floor_applied_flag,stress_worsening_flag;

-- Result Set 19 — Industry and merchant-size routing diagnostics
SELECT industry_code,merchant_size_tier,scenario_code,final_route_code,count(*) AS rows
FROM msbf_m2.application_eligibility_routing_snapshot GROUP BY industry_code,merchant_size_tier,scenario_code,final_route_code
ORDER BY industry_code,merchant_size_tier,scenario_code,final_route_code;

-- Result Set 20 — Acquisition evidence operational boundary
SELECT g.scenario_code,g.gate_outcome,g.gate_evidence_status,count(*) AS rows,
       count(*) FILTER(WHERE g.gate_outcome='FAIL') AS prohibited_decline_rows
FROM msbf_m2.application_policy_gate_result g WHERE g.gate_code='GATE_12_ACQUISITION_EVIDENCE'
GROUP BY g.scenario_code,g.gate_outcome,g.gate_evidence_status ORDER BY g.scenario_code,g.gate_outcome;

-- Result Set 21 — Latest/archive reproduction
SELECT count(*) AS joined_rows,
       count(*) FILTER(WHERE a.contract_row_hash IS DISTINCT FROM l.contract_row_hash OR a.source_latest_row_hash IS DISTINCT FROM l.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) AS mismatches
FROM msbf_m2.application_eligibility_routing_latest l
JOIN msbf_m2.application_eligibility_routing_archive a
 ON a.module1_run_id=l.module1_run_id AND a.strategy_campaign_code=l.strategy_campaign_code
AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id;

-- Result Set 22 — Governed M2.1 evidence summary
SELECT CASE WHEN evidence_code LIKE 'M2_1_POS_%' THEN 'POSITIVE'
            WHEN evidence_code LIKE 'M2_1_NEG_%' THEN 'NEGATIVE'
            WHEN evidence_code='M2_1_ACCEPTANCE_SUMMARY' THEN 'ACCEPTANCE'
            ELSE 'GENERATION' END AS evidence_family,
       status,count(*) AS rows
FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
AND evidence_code LIKE 'M2_1_%' GROUP BY evidence_family,status ORDER BY evidence_family,status;

-- Result Set 23 — Deterministic mismatches (zero rows required)
SELECT 'SNAPSHOT_ROW_HASH' AS mismatch_type,scenario_id::text||'|'||merchant_application_id AS entity_key,row_hash AS stored_hash,
       msbf_ctl.m2_1_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at') AS reconstructed_hash
FROM msbf_m2.application_eligibility_routing_snapshot s
WHERE row_hash IS DISTINCT FROM msbf_ctl.m2_1_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')
UNION ALL
SELECT 'LATEST_ROW_HASH',scenario_id::text||'|'||merchant_application_id,contract_row_hash,
       msbf_ctl.m2_1_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')
FROM msbf_m2.application_eligibility_routing_latest l
WHERE contract_row_hash IS DISTINCT FROM msbf_ctl.m2_1_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')
UNION ALL
SELECT 'ARCHIVE_REPRODUCTION',a.scenario_id::text||'|'||a.merchant_application_id,a.contract_row_hash,l.contract_row_hash
FROM msbf_m2.application_eligibility_routing_archive a
JOIN msbf_m2.application_eligibility_routing_latest l ON l.module1_run_id=a.module1_run_id AND l.strategy_campaign_code=a.strategy_campaign_code AND l.scenario_id=a.scenario_id AND l.merchant_application_id=a.merchant_application_id
WHERE a.contract_row_hash IS DISTINCT FROM l.contract_row_hash OR a.source_latest_row_hash IS DISTINCT FROM l.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at');

-- Result Set 24 — Blocking errors and stage-boundary violations (zero rows required)
SELECT 'BLOCKING_PROFILE_ERROR' AS violation_type,scope_key AS object_key,error_code AS violation_code,error_message AS details
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1) AND severity='BLOCKING'
UNION ALL
SELECT 'PROHIBITED_OFFER_COLUMN',table_name,column_name,'M2.1 must not publish final offer terms.'
FROM information_schema.columns
WHERE table_schema='msbf_m2' AND table_name IN ('application_eligibility_routing_snapshot','application_eligibility_routing_latest')
AND lower(column_name) ~ '(approved_amount|factor_rate|apr|remittance_rate|offer_term|final_price|funded_flag)'
UNION ALL
SELECT 'ACQUISITION_DECLINE_GATE',gate_code,decision_influence_code,'Acquisition evidence is review-only.'
FROM msbf_m2.policy_gate_definition WHERE gate_code='GATE_12_ACQUISITION_EVIDENCE' AND decision_influence_code<>'REVIEW_ONLY'
UNION ALL
SELECT 'PRODUCTION_ADVERSE_ACTION_FLAG',reason_code,associated_route_code,'M2.1 reason definitions must not be production adverse-action notices.'
FROM msbf_m2.reason_code_definition
WHERE production_adverse_action_flag
UNION ALL
SELECT 'PROCESSOR_UNAVAILABLE_MAPPING',merchant_application_id,gate_outcome,'UNAVAILABLE processor continuity must route to REVIEW.'
FROM msbf_m2.application_policy_gate_result
WHERE gate_code='GATE_05_PROCESSOR_CONTINUITY'
  AND observed_value_text='UNAVAILABLE'
  AND gate_outcome<>'REVIEW'
UNION ALL
SELECT 'STRESS_ROUTE_IMPROVEMENT',merchant_application_id,stress_route_code,'Stress final route improved relative to baseline.'
FROM msbf_m2.v_m2_1_matched_scenario_comparison WHERE stress_route_rank<baseline_route_rank;
