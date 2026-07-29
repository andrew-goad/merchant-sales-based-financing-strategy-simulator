/* ============================================================================
MSBF M1.12 Merchant Risk Components & Integrated Risk Proxy — Acceptance Finalizer
Version : v0.2
Purpose : Reconcile final positive/negative evidence, exact row counts, visible
          component/composite identities, matched stress floors, deterministic
          hashes, methodology settings, and downstream boundaries before formal
          acceptance.
Mode    : Writes the formal M1.12 gate result, acceptance summary, and final run
          status. No business evidence is recalculated or modified.
Output  : One filterable acceptance row. acceptance_status and gate_status must
          equal PASS, and final_run_status must equal M1_12_ACCEPTED.
============================================================================ */

BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL statement_timeout='15min';

DROP TABLE IF EXISTS _m1_12_acceptance;
CREATE TEMP TABLE _m1_12_acceptance ON COMMIT PRESERVE ROWS AS
WITH r AS (
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), pos AS (
 SELECT count(*) AS checks,count(*) FILTER(WHERE status='PASS') AS passes,count(*) FILTER(WHERE status='FAIL') AS failures
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_12_POS_%'
), neg AS (
 SELECT count(*) AS controls,count(*) FILTER(WHERE status='PASS') AS passes,count(*) FILTER(WHERE status='FAIL') AS failures
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_12_NEG_%'
), rows AS (
 SELECT
  (SELECT count(*) FROM msbf_m1.application_integrated_risk_proxy_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS snapshots,
  (SELECT count(*) FROM msbf_m1.integrated_risk_component_value WHERE module1_run_id=(SELECT run_id FROM r)) AS components,
  (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.application_integrated_risk_proxy_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS applications,
  (SELECT count(DISTINCT scenario_id) FROM msbf_m1.application_integrated_risk_proxy_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS scenarios,
  (SELECT count(*) FROM msbf_m1.application_integrated_risk_proxy_snapshot s JOIN msbf_ctl.scenario_registry sr USING(scenario_id) WHERE s.module1_run_id=(SELECT run_id FROM r) AND sr.scenario_code='RECESSION_ENERGY' AND s.integrated_risk_score IS NOT NULL AND s.baseline_integrated_risk_score IS NOT NULL AND s.integrated_risk_score<s.baseline_integrated_risk_score) AS stress_score_improvements,
  (SELECT count(*) FROM msbf_m1.application_integrated_risk_proxy_snapshot s JOIN msbf_ctl.scenario_registry sr USING(scenario_id) WHERE s.module1_run_id=(SELECT run_id FROM r) AND sr.scenario_code='RECESSION_ENERGY' AND s.integrated_risk_tier<s.baseline_risk_tier) AS stress_tier_improvements,
  (SELECT count(*) FROM msbf_m1.application_integrated_risk_proxy_snapshot WHERE module1_run_id=(SELECT run_id FROM r) AND integrated_risk_evidence_status='BLOCKED' AND (integrated_risk_score IS NOT NULL OR synthetic_merchant_risk_proxy IS NOT NULL)) AS blocked_proxy_violations,
  (SELECT count(*) FROM msbf_m1.application_integrated_risk_proxy_snapshot WHERE module1_run_id=(SELECT run_id FROM r) AND synthetic_merchant_risk_proxy IS DISTINCT FROM CASE WHEN integrated_risk_score IS NULL THEN NULL ELSE round(integrated_risk_score/100.0,8)::numeric(12,8) END) AS proxy_identity_violations,
  (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
  +(SELECT count(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM r))
  +(SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
  +(SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))
  +(SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS downstream_rows,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors
), comp AS (
 SELECT count(*) AS identity_violations
 FROM msbf_m1.application_integrated_risk_proxy_snapshot s
 JOIN (
   SELECT module1_run_id,scenario_id,merchant_application_id,count(weighted_risk_points) AS available_count,round(sum(weighted_risk_points),6)::numeric(9,6) AS weighted_sum
   FROM msbf_m1.integrated_risk_component_value
   WHERE module1_run_id=(SELECT run_id FROM r)
   GROUP BY module1_run_id,scenario_id,merchant_application_id
 ) c USING(module1_run_id,scenario_id,merchant_application_id)
 JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
 CROSS JOIN (SELECT profile_payload FROM msbf_ctl.policy_profile WHERE profile_code='M1_12_INTEGRATED_RISK_PROXY' AND profile_version=1 AND status='APPROVED') p
 WHERE s.module1_run_id=(SELECT run_id FROM r)
   AND s.integrated_risk_score IS DISTINCT FROM CASE
     WHEN s.integrated_risk_evidence_status='BLOCKED' OR c.available_count<>7 THEN NULL
     WHEN sr.scenario_code='RECESSION_ENERGY' THEN greatest(
       greatest(c.weighted_sum,CASE WHEN s.hard_stop_recommended_flag THEN (p.profile_payload->>'hard_stop_score_floor')::numeric WHEN s.fraud_risk_tier=5 THEN (p.profile_payload->>'fraud_tier_5_score_floor')::numeric ELSE 0 END),
       s.baseline_integrated_risk_score)::numeric(9,6)
     ELSE greatest(c.weighted_sum,CASE WHEN s.hard_stop_recommended_flag THEN (p.profile_payload->>'hard_stop_score_floor')::numeric WHEN s.fraud_risk_tier=5 THEN (p.profile_payload->>'fraud_tier_5_score_floor')::numeric ELSE 0 END)::numeric(9,6)
   END
), actual AS (
 SELECT * FROM msbf_m1.m1_12_actual_snapshot((SELECT run_id FROM r))
 UNION ALL SELECT * FROM msbf_m1.m1_12_actual_component((SELECT run_id FROM r))
), hashes AS (
 SELECT count(*) AS canonical_entities,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM actual WHERE entity_key LIKE 'RISK|%') AS snapshot_hash,
  (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM actual WHERE entity_key LIKE 'COMPONENT|%') AS component_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash
 FROM actual
), stored AS (
 SELECT max(metric_value_text) FILTER(WHERE evidence_code='M1_12_SNAPSHOT_SET_HASH') AS stored_snapshot_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_12_COMPONENT_SET_HASH') AS stored_component_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_12_COMBINED_SET_HASH') AS stored_combined_hash,
        (max(metric_value_numeric) FILTER(WHERE evidence_code='M1_12_CANONICAL_MISMATCH_COUNT'))::bigint AS stored_mismatches
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
), policy AS (
 SELECT profile_payload FROM msbf_ctl.policy_profile
 WHERE profile_code='M1_12_INTEGRATED_RISK_PROXY' AND profile_version=1 AND status='APPROVED'
)
SELECT r.run_id,r.run_status,
       pos.checks AS positive_checks,pos.passes AS positive_passes,pos.failures AS positive_failures,
       neg.controls AS negative_controls,neg.passes AS negative_passes,neg.failures AS negative_failures,
       rows.*,comp.identity_violations AS composite_identity_violations,
       hashes.*,stored.*,
       policy.profile_payload->>'methodology_version' AS methodology_version,
       policy.profile_payload->>'composite_score_basis' AS composite_score_basis,
       (policy.profile_payload->>'stress_risk_score_floor_to_baseline')::boolean AS score_floor_enabled,
       (policy.profile_payload->>'stress_risk_tier_floor_to_baseline')::boolean AS tier_floor_enabled,
       CASE WHEN r.run_status='M1_12_VALIDATED'
         AND pos.checks=80 AND pos.passes=80 AND pos.failures=0
         AND neg.controls=7 AND neg.passes=7 AND neg.failures=0
         AND rows.snapshots=1500 AND rows.components=10500 AND rows.applications=750 AND rows.scenarios=2
         AND rows.stress_score_improvements=0 AND rows.stress_tier_improvements=0
         AND rows.blocked_proxy_violations=0 AND rows.proxy_identity_violations=0
         AND comp.identity_violations=0 AND rows.downstream_rows=0 AND rows.blocking_errors=0
         AND hashes.canonical_entities=12000 AND stored.stored_mismatches=0
         AND hashes.snapshot_hash=stored.stored_snapshot_hash
         AND hashes.component_hash=stored.stored_component_hash
         AND hashes.combined_hash=stored.stored_combined_hash
         AND policy.profile_payload->>'methodology_version'='M1_12_METHOD_V1'
         AND policy.profile_payload->>'composite_score_basis'='SUM_PERSISTED_WEIGHTED_RISK_COMPONENTS'
         AND (policy.profile_payload->>'stress_risk_score_floor_to_baseline')::boolean
         AND (policy.profile_payload->>'stress_risk_tier_floor_to_baseline')::boolean
       THEN 'PASS' ELSE 'FAIL' END AS acceptance_status
FROM r CROSS JOIN pos CROSS JOIN neg CROSS JOIN rows CROSS JOIN comp CROSS JOIN hashes CROSS JOIN stored CROSS JOIN policy;

INSERT INTO msbf_ctl.acceptance_gate_result(
 run_id,gate_id,review_version,result_status,observed_value,threshold_value,finding,residual_limitation,reviewer_role,reviewed_at
)
SELECT run_id,'M1_12_INTEGRATED_RISK_PROXY',
       coalesce((SELECT max(review_version)+1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=a.run_id AND gate_id='M1_12_INTEGRATED_RISK_PROXY'),1),
       acceptance_status,
       format('positive=%s/%s|negative=%s/%s|snapshots=%s|components=%s|canonical=%s|mismatches=%s|composite_identity=%s|score_improvements=%s|tier_improvements=%s',positive_passes,positive_checks,negative_passes,negative_controls,snapshots,components,canonical_entities,stored_mismatches,composite_identity_violations,stress_score_improvements,stress_tier_improvements),
       '80/80 positive; 7/7 negative; 1,500 snapshots; 10,500 components; zero mismatches; zero identity violations; zero stress improvements',
       CASE WHEN acceptance_status='PASS' THEN 'M1.12 transparent risk components and synthetic integrated merchant-risk proxy accepted.' ELSE 'M1.12 acceptance requirements were not fully satisfied.' END,
       'Synthetic transparent risk proxy; not a calibrated probability of default, pricing model, capital model, legal determination, or production underwriting decision.',
       'Independent Validation',clock_timestamp()
FROM _m1_12_acceptance a;

INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
SELECT run_id,'M1_12_ACCEPTANCE_SUMMARY','PORTFOLIO','M1.12 acceptance summary',
       format('positive=%s/%s|negative=%s/%s|snapshots=%s|components=%s|hash=%s',positive_passes,positive_checks,negative_passes,negative_controls,snapshots,components,combined_hash),
       'TEXT',acceptance_status,'Formal M1.12 acceptance summary.'
FROM _m1_12_acceptance
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
 metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,
 metric_value_numeric=NULL,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
 interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry r
SET run_status=CASE WHEN a.acceptance_status='PASS' THEN 'M1_12_ACCEPTED' ELSE 'M1_12_FAILED' END,
    completed_at=CASE WHEN a.acceptance_status='PASS' THEN clock_timestamp() ELSE r.completed_at END,
    notes=coalesce(r.notes,'')||E'\nM1.12 v0.2 acceptance: '||a.acceptance_status||'.'
FROM _m1_12_acceptance a WHERE r.run_id=a.run_id;

COMMIT;

SELECT a.*,r.run_status AS final_run_status,g.review_version,g.result_status AS gate_status
FROM _m1_12_acceptance a
JOIN msbf_ctl.run_registry r USING(run_id)
JOIN LATERAL(
 SELECT * FROM msbf_ctl.acceptance_gate_result x
 WHERE x.run_id=a.run_id AND x.gate_id='M1_12_INTEGRATED_RISK_PROXY'
 ORDER BY review_version DESC LIMIT 1
) g ON true;
