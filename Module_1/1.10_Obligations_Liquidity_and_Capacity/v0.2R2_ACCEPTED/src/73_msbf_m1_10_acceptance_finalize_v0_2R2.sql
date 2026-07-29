/* ============================================================================
MSBF M1.10 Obligations, Liquidity & Residual Cash Flow — Acceptance Finalizer
Version : v0.2R2
Purpose : Reconcile persisted M1.10 evidence and issue the formal gate result.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB'; SET LOCAL jit=off; SET LOCAL statement_timeout='15min';
DROP TABLE IF EXISTS _m1_10_acceptance;
CREATE TEMP TABLE _m1_10_acceptance ON COMMIT PRESERVE ROWS AS
WITH r AS (
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), pos AS (
 SELECT count(*) positive_checks,count(*) FILTER(WHERE status='PASS') positive_passes,
        count(*) FILTER(WHERE status='FAIL') positive_failures
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_10_POS_%'
), neg AS (
 SELECT count(*) negative_controls,count(*) FILTER(WHERE status='PASS') negative_passes,
        count(*) FILTER(WHERE status='FAIL') negative_failures
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_10_NEG_%'
), rows AS (
 SELECT
  (SELECT count(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)) obligation_rows,
  (SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) capacity_rows,
  (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) applications,
  (SELECT count(DISTINCT scenario_id) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) scenarios,
  (SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot c JOIN msbf_ctl.scenario_registry s USING(scenario_id)
     WHERE c.module1_run_id=(SELECT run_id FROM r) AND s.scenario_code='RECESSION_ENERGY' AND c.capacity_tier<c.baseline_capacity_tier) stress_improvements,
  (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))+
  (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))+
  (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))+
  (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) downstream_rows,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') blocking_errors
), actual AS (
 SELECT * FROM msbf_m1.m1_10_actual_obligation((SELECT run_id FROM r))
 UNION ALL SELECT * FROM msbf_m1.m1_10_actual_capacity((SELECT run_id FROM r))
), hashes AS (
 SELECT
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER(WHERE entity_key LIKE 'OBLIGATION|%')) obligation_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER(WHERE entity_key LIKE 'CAPACITY|%')) capacity_hash,
  md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) combined_hash,
  count(*) canonical_entities
 FROM actual
), stored AS (
 SELECT
  max(metric_value_text) FILTER(WHERE evidence_code='M1_10_OBLIGATION_SET_HASH') stored_obligation_hash,
  max(metric_value_text) FILTER(WHERE evidence_code='M1_10_CAPACITY_SET_HASH') stored_capacity_hash,
  max(metric_value_text) FILTER(WHERE evidence_code='M1_10_COMBINED_SET_HASH') stored_combined_hash,
  (max(metric_value_numeric) FILTER(WHERE evidence_code='M1_10_CANONICAL_ENTITY_COUNT'))::bigint stored_canonical_entities,
  (max(metric_value_numeric) FILTER(WHERE evidence_code='M1_10_CANONICAL_MISMATCH_COUNT'))::bigint stored_mismatches
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
), policy AS (
 SELECT profile_payload FROM msbf_ctl.policy_profile
 WHERE profile_code='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY' AND profile_version=1 AND status='APPROVED'
)
SELECT r.run_id,r.run_status,pos.*,neg.*,rows.*,hashes.*,stored.*,
       policy.profile_payload->>'methodology_version' methodology_version,
       (policy.profile_payload->>'stress_capacity_tier_floor_to_baseline')::boolean stress_floor_enabled,
       CASE WHEN r.run_status='M1_10_VALIDATED'
          AND pos.positive_checks=70 AND pos.positive_passes=70 AND pos.positive_failures=0
          AND neg.negative_controls=6 AND neg.negative_passes=6 AND neg.negative_failures=0
          AND rows.capacity_rows=1500 AND rows.applications=750 AND rows.scenarios=2
          AND rows.stress_improvements=0 AND rows.downstream_rows=0 AND rows.blocking_errors=0
          AND hashes.canonical_entities=stored.stored_canonical_entities
          AND stored.stored_mismatches=0
          AND hashes.obligation_hash=stored.stored_obligation_hash
          AND hashes.capacity_hash=stored.stored_capacity_hash
          AND hashes.combined_hash=stored.stored_combined_hash
          AND policy.profile_payload->>'methodology_version'='M1_10_METHOD_V1'
          AND (policy.profile_payload->>'stress_capacity_tier_floor_to_baseline')::boolean
        THEN 'PASS' ELSE 'FAIL' END acceptance_status
FROM r CROSS JOIN pos CROSS JOIN neg CROSS JOIN rows CROSS JOIN hashes CROSS JOIN stored CROSS JOIN policy;

INSERT INTO msbf_ctl.acceptance_gate_result(
 run_id,gate_id,review_version,result_status,observed_value,threshold_value,
 finding,residual_limitation,reviewer_role,reviewed_at
)
SELECT a.run_id,'M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY',
       coalesce((SELECT max(review_version)+1 FROM msbf_ctl.acceptance_gate_result
                 WHERE run_id=a.run_id AND gate_id='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY'),1),
       a.acceptance_status,
       format('positive=%s/%s|negative=%s/%s|obligations=%s|capacity=%s|canonical=%s|mismatches=%s|stress_improvements=%s',
          a.positive_passes,a.positive_checks,a.negative_passes,a.negative_controls,a.obligation_rows,
          a.capacity_rows,a.canonical_entities,a.stored_mismatches,a.stress_improvements),
       '70/70 positive; 6/6 negative; 1,500 capacity rows; zero mismatches; zero stress improvements',
       CASE WHEN a.acceptance_status='PASS' THEN 'M1.10 obligations, residual cash flow, liquidity and capacity evidence accepted.'
            ELSE 'M1.10 acceptance requirements were not fully satisfied.' END,
       'Synthetic demonstration evidence; not a calibrated credit, pricing, accounting, capital, legal, or production underwriting model.',
       'Independent Validation',clock_timestamp()
FROM _m1_10_acceptance a;

INSERT INTO msbf_ctl.run_evidence(
 run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation
)
SELECT run_id,'M1_10_ACCEPTANCE_SUMMARY','PORTFOLIO','M1.10 acceptance summary',
       format('positive=%s/%s|negative=%s/%s|capacity=%s|stress_improvements=%s|hash=%s',
         positive_passes,positive_checks,negative_passes,negative_controls,capacity_rows,stress_improvements,combined_hash),
       'TEXT',acceptance_status,
       'Formal M1.10 acceptance summary after independent hash, control, cardinality, stress-floor and boundary reconciliation.'
FROM _m1_10_acceptance
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
 metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,
 unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,
 created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry r
SET run_status=CASE WHEN a.acceptance_status='PASS' THEN 'M1_10_ACCEPTED' ELSE 'M1_10_FAILED' END,
    completed_at=CASE WHEN a.acceptance_status='PASS' THEN clock_timestamp() ELSE r.completed_at END,
    notes=coalesce(r.notes,'')||E'\nM1.10 acceptance finalizer: '||a.acceptance_status||'.'
FROM _m1_10_acceptance a WHERE r.run_id=a.run_id;
COMMIT;
SELECT a.*,r.run_status AS final_run_status,g.gate_id,g.review_version,g.result_status AS gate_status
FROM _m1_10_acceptance a JOIN msbf_ctl.run_registry r USING(run_id)
JOIN LATERAL(SELECT * FROM msbf_ctl.acceptance_gate_result x
 WHERE x.run_id=a.run_id AND x.gate_id='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY'
 ORDER BY review_version DESC LIMIT 1) g ON true;
