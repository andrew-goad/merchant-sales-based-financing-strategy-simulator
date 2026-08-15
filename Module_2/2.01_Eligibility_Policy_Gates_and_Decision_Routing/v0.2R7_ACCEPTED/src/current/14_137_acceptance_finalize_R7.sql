/* ============================================================================
Revision v0.2R7 correction
- Narrows the contract-registry CTE to the four fields used by acceptance.
- Replaces wildcard CTE projections with explicit output columns.
- Qualifies every control, physical-count, boundary, and hash reference.
- Resolves SQLSTATE 42702 without changing any acceptance threshold,
  lifecycle transition, generated record, evidence row, contract, hash,
  gate result, route, or business outcome.
============================================================================ */

/* ============================================================================
MSBF M2.1 — Eligibility, Policy Gates & Decision Routing Foundations
Program 137 — Acceptance Finalizer (v0.2R7)
Version v0.2R7
Purpose: Independently certify the M2.1 routing contract and issue its gate.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='20min';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m2_1_acceptance;
CREATE TEMP TABLE _m2_1_acceptance ON COMMIT PRESERVE ROWS AS
WITH r AS (
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), c AS (
 SELECT
  contract_status,
  canonical_entities,
  contract_set_hash,
  combined_set_hash
 FROM msbf_ctl.m2_1_strategy_contract_registry
 WHERE module1_run_id=(SELECT run_id FROM r)
), controls AS (
 SELECT
  count(*) FILTER(WHERE evidence_code LIKE 'M2_1_POS_%') AS positive_checks,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_1_POS_%' AND status='PASS') AS positive_passes,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_1_POS_%' AND status<>'PASS') AS positive_failures,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_1_NEG_%') AS negative_checks,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_1_NEG_%' AND status='PASS') AS negative_passes,
  count(*) FILTER(WHERE evidence_code LIKE 'M2_1_NEG_%' AND status<>'PASS') AS negative_failures
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
), physical AS (
 SELECT
  (SELECT count(*) FROM msbf_m2.strategy_campaign WHERE module1_run_id=(SELECT run_id FROM r)) campaign_rows,
  (SELECT count(*) FROM msbf_m2.policy_gate_definition WHERE module1_run_id=(SELECT run_id FROM r)) gate_definition_rows,
  (SELECT count(*) FROM msbf_m2.reason_code_definition WHERE module1_run_id=(SELECT run_id FROM r)) reason_rows,
  (SELECT count(*) FROM msbf_m2.routing_outcome_definition WHERE module1_run_id=(SELECT run_id FROM r)) outcome_rows,
  (SELECT count(*) FROM msbf_m2.application_policy_gate_result WHERE module1_run_id=(SELECT run_id FROM r)) gate_result_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) snapshot_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=(SELECT run_id FROM r)) latest_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=(SELECT run_id FROM r)) archive_rows,
  (SELECT count(*) FROM msbf_m2.v_m2_1_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM r)) comparison_rows,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') blocking_errors,
  (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING') existing_gate_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_snapshot s WHERE s.module1_run_id=(SELECT run_id FROM r) AND s.scenario_code='RECESSION_ENERGY' AND s.final_route_rank<s.baseline_route_rank) stress_route_improvements,
  (SELECT count(*) FROM msbf_m2.application_policy_gate_result g WHERE g.module1_run_id=(SELECT run_id FROM r) AND g.gate_code='GATE_12_ACQUISITION_EVIDENCE' AND g.gate_outcome='FAIL') acquisition_decline_gate_rows,
  (SELECT count(*) FROM msbf_m2.reason_code_definition d WHERE d.module1_run_id=(SELECT run_id FROM r) AND d.reason_category='ACQUISITION' AND d.associated_route_code='DECLINE_POLICY') acquisition_decline_reason_rows,
  (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN ('application_policy_gate_result','application_eligibility_routing_snapshot','application_eligibility_routing_latest','application_eligibility_routing_archive') AND lower(column_name) IN ('approved_amount','factor_rate','apr','remittance_rate','offer_term','approved_term','final_price','funded_flag','funded_outcome','funding_status','adverse_action_code','adverse_action_notice')) prohibited_offer_columns,
  (SELECT count(*) FROM msbf_m2.reason_code_definition d WHERE d.module1_run_id=(SELECT run_id FROM r) AND d.production_adverse_action_flag) production_adverse_action_rows,
  (SELECT count(*) FROM msbf_m2.application_policy_gate_result g WHERE g.module1_run_id=(SELECT run_id FROM r) AND g.gate_code='GATE_05_PROCESSOR_CONTINUITY' AND g.observed_value_text='UNAVAILABLE' AND g.gate_outcome<>'REVIEW') processor_unavailable_mapping_violations,
  (SELECT count(*) FILTER(WHERE row_hash IS DISTINCT FROM msbf_ctl.m2_1_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')) FROM msbf_m2.application_eligibility_routing_snapshot s WHERE module1_run_id=(SELECT run_id FROM r)) snapshot_hash_mismatches,
  (SELECT count(*) FILTER(WHERE contract_row_hash IS DISTINCT FROM msbf_ctl.m2_1_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) FROM msbf_m2.application_eligibility_routing_latest l WHERE module1_run_id=(SELECT run_id FROM r)) latest_hash_mismatches,
  (SELECT count(*) FILTER(WHERE archive_row_hash IS DISTINCT FROM msbf_ctl.m2_1_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at')) FROM msbf_m2.application_eligibility_routing_archive a WHERE module1_run_id=(SELECT run_id FROM r)) archive_hash_mismatches,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_latest l JOIN msbf_m2.application_eligibility_routing_archive a ON a.module1_run_id=l.module1_run_id AND a.strategy_campaign_code=l.strategy_campaign_code AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE l.module1_run_id=(SELECT run_id FROM r) AND (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash OR a.source_latest_row_hash IS DISTINCT FROM l.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at'))) archive_reproduction_mismatches
)
SELECT
 r.run_id,
 r.run_status AS prior_run_status,
 c.contract_status AS prior_contract_status,

 controls.positive_checks,
 controls.positive_passes,
 controls.positive_failures,
 controls.negative_checks,
 controls.negative_passes,
 controls.negative_failures,

 physical.campaign_rows,
 physical.gate_definition_rows,
 physical.reason_rows,
 physical.outcome_rows,
 physical.gate_result_rows,
 physical.snapshot_rows,
 physical.latest_rows,
 physical.archive_rows,
 physical.comparison_rows,
 physical.blocking_errors,
 physical.existing_gate_rows,
 physical.stress_route_improvements,
 physical.acquisition_decline_gate_rows,
 physical.acquisition_decline_reason_rows,
 physical.prohibited_offer_columns,
 physical.production_adverse_action_rows,
 physical.processor_unavailable_mapping_violations,
 physical.snapshot_hash_mismatches,
 physical.latest_hash_mismatches,
 physical.archive_hash_mismatches,
 physical.archive_reproduction_mismatches,

 c.canonical_entities,
 c.contract_set_hash,
 c.combined_set_hash,

 CASE
  WHEN r.run_status='M2_1_VALIDATED'
   AND c.contract_status='VALIDATED'
   AND controls.positive_checks=112
   AND controls.positive_passes=112
   AND controls.positive_failures=0
   AND controls.negative_checks=20
   AND controls.negative_passes=20
   AND controls.negative_failures=0
   AND physical.campaign_rows=1
   AND physical.gate_definition_rows=12
   AND physical.reason_rows=23
   AND physical.outcome_rows=4
   AND physical.gate_result_rows=18000
   AND physical.snapshot_rows=1500
   AND physical.latest_rows=1500
   AND physical.archive_rows=1500
   AND physical.comparison_rows=750
   AND c.canonical_entities=22541
   AND c.contract_set_hash IS NOT NULL
   AND c.combined_set_hash IS NOT NULL
   AND physical.blocking_errors=0
   AND physical.existing_gate_rows=0
   AND physical.stress_route_improvements=0
   AND physical.acquisition_decline_gate_rows=0
   AND physical.acquisition_decline_reason_rows=0
   AND physical.prohibited_offer_columns=0
   AND physical.production_adverse_action_rows=0
   AND physical.processor_unavailable_mapping_violations=0
   AND physical.snapshot_hash_mismatches=0
   AND physical.latest_hash_mismatches=0
   AND physical.archive_hash_mismatches=0
   AND physical.archive_reproduction_mismatches=0
  THEN 'PASS'
  ELSE 'FAIL'
 END AS acceptance_status

FROM r
CROSS JOIN c
CROSS JOIN controls
CROSS JOIN physical;

DO $acceptance_guard$
DECLARE v record;
BEGIN
 PERFORM msbf_ctl.m2_1_assert_acceptance_ready(
     (SELECT run_id FROM _m2_1_acceptance)
 );
 SELECT * INTO v FROM _m2_1_acceptance;
 IF v.acceptance_status<>'PASS' THEN
  RAISE EXCEPTION
   'M2.1 acceptance preconditions failed: %',
   row_to_json(v);
 END IF;
END;
$acceptance_guard$;

DROP TABLE IF EXISTS _m2_1_acceptance_evidence;
CREATE TEMP TABLE _m2_1_acceptance_evidence(
 run_id bigint NOT NULL,evidence_code text NOT NULL,segment_key text NOT NULL,metric_name text NOT NULL,
 metric_value_numeric numeric(24,10),metric_value_text text,unit_code text NOT NULL,status text NOT NULL,interpretation text NOT NULL,
 CHECK(num_nonnulls(metric_value_numeric,metric_value_text)=1)
) ON COMMIT DROP;
INSERT INTO _m2_1_acceptance_evidence
SELECT run_id,'M2_1_ACCEPTANCE_SUMMARY','PORTFOLIO','M2_1_ELIGIBILITY_POLICY_ROUTING_ACCEPTANCE',
       NULL::numeric(24,10),combined_set_hash,'ACCEPTANCE','PASS',
       format('M2.1 accepted: canonical_entities=%s; 112 positive and 20 negative controls passed; routing contract and archive reconciled.',canonical_entities)
FROM _m2_1_acceptance;

UPDATE msbf_ctl.m2_1_strategy_contract_registry
SET contract_status='ACCEPTED',accepted_at=clock_timestamp()
WHERE module1_run_id=(SELECT run_id FROM _m2_1_acceptance);

UPDATE msbf_ctl.run_registry
SET run_status='M2_1_ACCEPTED',notes=coalesce(notes,'')||' | M2.1 Eligibility, Policy Gates & Decision Routing accepted.'
WHERE run_id=(SELECT run_id FROM _m2_1_acceptance);

INSERT INTO msbf_ctl.acceptance_gate_result(
 run_id,gate_id,review_version,result_status,observed_value,threshold_value,finding,residual_limitation,reviewer_role,reviewed_at
)
SELECT run_id,'M2_1_ELIGIBILITY_POLICY_ROUTING',
       coalesce((SELECT max(review_version)+1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=a.run_id AND g.gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING'),1),
       'PASS',combined_set_hash,'112/112 positive; 20/20 negative; zero mismatches',
       'M2.1 governed eligibility and routing contract accepted.',
       'Synthetic strategy foundation only; not final offer pricing, funding approval, production adverse action or legal conclusion.',
       'Independent Validation / Project Owner',clock_timestamp()
FROM _m2_1_acceptance a;

INSERT INTO msbf_ctl.run_evidence(
 run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,interpretation
)
SELECT run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,interpretation
FROM _m2_1_acceptance_evidence
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
 metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,metric_value_text=EXCLUDED.metric_value_text,
 unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

ALTER TABLE _m2_1_acceptance ADD COLUMN final_run_status text,ADD COLUMN final_contract_status text,ADD COLUMN gate_status text;
UPDATE _m2_1_acceptance a
SET final_run_status=(SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=a.run_id),
    final_contract_status=(SELECT contract_status FROM msbf_ctl.m2_1_strategy_contract_registry WHERE module1_run_id=a.run_id),
    gate_status=(SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=a.run_id AND gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING' ORDER BY review_version DESC LIMIT 1)
WHERE a.run_id IS NOT NULL;

DO $final_guard$
DECLARE v record;
BEGIN SELECT * INTO v FROM _m2_1_acceptance;
 IF v.final_run_status<>'M2_1_ACCEPTED' OR v.final_contract_status<>'ACCEPTED' OR v.gate_status<>'PASS' THEN
  RAISE EXCEPTION 'M2.1 final acceptance state failed: %',row_to_json(v);
 END IF;
END;
$final_guard$;

COMMIT;
SELECT * FROM _m2_1_acceptance;
