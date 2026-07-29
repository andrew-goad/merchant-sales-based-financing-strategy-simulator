/* ============================================================================
MSBF M1.11 Cash-Flow Archetypes & Operating Resilience — Acceptance Finalizer
Version : v0.2R2
Purpose : Reconcile final positive/negative evidence, row counts, stress floors,
          visible composite identity, deterministic hashes, policy settings,
          and downstream stage boundaries before formal acceptance.
Mode    : Writes the M1.11 gate result, acceptance summary, and final run status.
Output  : One filterable acceptance row. acceptance_status and gate_status must
          equal PASS, and final_run_status must equal M1_11_ACCEPTED.
============================================================================ */

/* 1. Initialize final acceptance reconciliation */
BEGIN; SET LOCAL work_mem='64MB'; SET LOCAL jit=off; SET LOCAL statement_timeout='15min';
DROP TABLE IF EXISTS _m1_11_acceptance;
/* 2. Materialize all acceptance inputs and determine status */
CREATE TEMP TABLE _m1_11_acceptance ON COMMIT PRESERVE ROWS AS
WITH r AS (SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
pos AS (SELECT count(*) checks,count(*) FILTER(WHERE status='PASS') passes,count(*) FILTER(WHERE status='FAIL') failures FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_11_POS_%'),
neg AS (SELECT count(*) controls,count(*) FILTER(WHERE status='PASS') passes,count(*) FILTER(WHERE status='FAIL') failures FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_11_NEG_%'),
rows AS (SELECT
 (SELECT count(*) FROM msbf_m1.application_operating_resilience_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) snapshots,
 (SELECT count(*) FROM msbf_m1.operating_resilience_component_value WHERE module1_run_id=(SELECT run_id FROM r)) components,
 (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.application_operating_resilience_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) applications,
 (SELECT count(DISTINCT scenario_id) FROM msbf_m1.application_operating_resilience_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) scenarios,
 (SELECT count(*) FROM msbf_m1.application_operating_resilience_snapshot s JOIN msbf_ctl.scenario_registry sr USING(scenario_id) WHERE s.module1_run_id=(SELECT run_id FROM r) AND sr.scenario_code='RECESSION_ENERGY' AND s.resilience_tier<s.baseline_resilience_tier) tier_improvements,
 (SELECT count(*) FROM msbf_m1.application_operating_resilience_snapshot s JOIN msbf_ctl.scenario_registry sr USING(scenario_id) WHERE s.module1_run_id=(SELECT run_id FROM r) AND sr.scenario_code='RECESSION_ENERGY' AND s.archetype_risk_rank < CASE s.baseline_archetype_code WHEN 'GROWING' THEN 1 WHEN 'STABLE' THEN 1 WHEN 'SEASONAL' THEN 2 WHEN 'VOLATILE' THEN 3 WHEN 'DECLINING' THEN 4 WHEN 'DISRUPTED' THEN 4 ELSE 5 END) archetype_improvements,
 (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))+(SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))+(SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))+(SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) downstream_rows,
 (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') blocking_errors),
composite AS (SELECT count(*) AS identity_violations FROM msbf_m1.application_operating_resilience_snapshot s JOIN (SELECT module1_run_id,scenario_id,merchant_application_id,round(sum(weighted_score),6)::numeric(9,6) score,count(weighted_score) n FROM msbf_m1.operating_resilience_component_value WHERE module1_run_id=(SELECT run_id FROM r) GROUP BY 1,2,3)c USING(module1_run_id,scenario_id,merchant_application_id) WHERE s.module1_run_id=(SELECT run_id FROM r) AND s.operating_resilience_score IS DISTINCT FROM CASE WHEN s.operating_resilience_evidence_status='BLOCKED' OR c.n<>5 THEN NULL ELSE c.score END),
actual AS (SELECT * FROM msbf_m1.m1_11_actual_resilience((SELECT run_id FROM r)) UNION ALL SELECT * FROM msbf_m1.m1_11_actual_component((SELECT run_id FROM r))),
hashes AS (SELECT count(*) canonical_entities,
 (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM actual WHERE entity_key LIKE 'RESILIENCE|%') snapshot_hash,
 (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM actual WHERE entity_key LIKE 'COMPONENT|%') component_hash,
 (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM actual) combined_hash FROM actual),
stored AS (SELECT max(metric_value_text) FILTER(WHERE evidence_code='M1_11_SNAPSHOT_SET_HASH') stored_snapshot_hash,max(metric_value_text) FILTER(WHERE evidence_code='M1_11_COMPONENT_SET_HASH') stored_component_hash,max(metric_value_text) FILTER(WHERE evidence_code='M1_11_COMBINED_SET_HASH') stored_combined_hash,(max(metric_value_numeric) FILTER(WHERE evidence_code='M1_11_CANONICAL_MISMATCH_COUNT'))::bigint stored_mismatches FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)),
policy AS (SELECT profile_payload FROM msbf_ctl.policy_profile WHERE profile_code='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE' AND profile_version=1 AND status='APPROVED')
SELECT r.run_id,r.run_status,pos.checks positive_checks,pos.passes positive_passes,pos.failures positive_failures,neg.controls negative_controls,neg.passes negative_passes,neg.failures negative_failures,rows.*,hashes.*,stored.*,
 policy.profile_payload->>'methodology_version' methodology_version,policy.profile_payload->>'composite_score_basis' composite_score_basis,(policy.profile_payload->>'stress_resilience_tier_floor_to_baseline')::boolean tier_floor_enabled,(policy.profile_payload->>'stress_archetype_rank_floor_to_baseline')::boolean archetype_floor_enabled,composite.identity_violations AS composite_identity_violations,
 CASE WHEN r.run_status='M1_11_VALIDATED' AND pos.checks=72 AND pos.passes=72 AND pos.failures=0 AND neg.controls=6 AND neg.passes=6 AND neg.failures=0
   AND rows.snapshots=1500 AND rows.components=7500 AND rows.applications=750 AND rows.scenarios=2 AND rows.tier_improvements=0 AND rows.archetype_improvements=0 AND rows.downstream_rows=0 AND rows.blocking_errors=0
   AND hashes.canonical_entities=9000 AND stored.stored_mismatches=0 AND hashes.snapshot_hash=stored.stored_snapshot_hash AND hashes.component_hash=stored.stored_component_hash AND hashes.combined_hash=stored.stored_combined_hash
   AND composite.identity_violations=0 AND policy.profile_payload->>'methodology_version'='M1_11_METHOD_V1_1' AND policy.profile_payload->>'composite_score_basis'='SUM_PERSISTED_WEIGHTED_COMPONENTS' AND (policy.profile_payload->>'stress_resilience_tier_floor_to_baseline')::boolean AND (policy.profile_payload->>'stress_archetype_rank_floor_to_baseline')::boolean
  THEN 'PASS' ELSE 'FAIL' END acceptance_status
FROM r CROSS JOIN pos CROSS JOIN neg CROSS JOIN rows CROSS JOIN composite CROSS JOIN hashes CROSS JOIN stored CROSS JOIN policy;
/* 3. Persist the formal acceptance-gate result */
INSERT INTO msbf_ctl.acceptance_gate_result(run_id,gate_id,review_version,result_status,observed_value,threshold_value,finding,residual_limitation,reviewer_role,reviewed_at)
SELECT run_id,'M1_11_CASHFLOW_ARCHETYPE_RESILIENCE',coalesce((SELECT max(review_version)+1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=a.run_id AND gate_id='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE'),1),acceptance_status,
 format('positive=%s/%s|negative=%s/%s|snapshots=%s|components=%s|canonical=%s|mismatches=%s|composite_identity=%s|tier_improvements=%s|archetype_improvements=%s',positive_passes,positive_checks,negative_passes,negative_controls,snapshots,components,canonical_entities,stored_mismatches,composite_identity_violations,tier_improvements,archetype_improvements),
 '72/72 positive; 6/6 negative; 1,500 snapshots; 7,500 components; zero mismatches; zero composite-identity violations; zero stress improvements',
 CASE WHEN acceptance_status='PASS' THEN 'M1.11 cash-flow archetypes and operating resilience evidence accepted.' ELSE 'M1.11 acceptance requirements were not fully satisfied.' END,
 'Synthetic transparent resilience segmentation; not a calibrated PD, pricing, legal, capital, or production underwriting model.','Independent Validation',clock_timestamp() FROM _m1_11_acceptance a;
/* 4. Persist the acceptance summary */
INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
SELECT run_id,'M1_11_ACCEPTANCE_SUMMARY','PORTFOLIO','M1.11 acceptance summary',format('positive=%s/%s|negative=%s/%s|snapshots=%s|components=%s|hash=%s',positive_passes,positive_checks,negative_passes,negative_controls,snapshots,components,combined_hash),'TEXT',acceptance_status,'Formal M1.11 acceptance summary.' FROM _m1_11_acceptance
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,metric_value_numeric=NULL,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();
/* 5. Advance the governed run to its final M1.11 status */
UPDATE msbf_ctl.run_registry r SET run_status=CASE WHEN a.acceptance_status='PASS' THEN 'M1_11_ACCEPTED' ELSE 'M1_11_FAILED' END,completed_at=CASE WHEN a.acceptance_status='PASS' THEN clock_timestamp() ELSE r.completed_at END,notes=coalesce(r.notes,'')||E'\nM1.11 v0.2R2 acceptance: '||a.acceptance_status||'.' FROM _m1_11_acceptance a WHERE r.run_id=a.run_id;
/* 6. Commit and return the final acceptance record */
COMMIT;
SELECT a.*,r.run_status final_run_status,g.review_version,g.result_status gate_status FROM _m1_11_acceptance a JOIN msbf_ctl.run_registry r USING(run_id) JOIN LATERAL(SELECT * FROM msbf_ctl.acceptance_gate_result x WHERE x.run_id=a.run_id AND x.gate_id='M1_11_CASHFLOW_ARCHETYPE_RESILIENCE' ORDER BY review_version DESC LIMIT 1)g ON true;
