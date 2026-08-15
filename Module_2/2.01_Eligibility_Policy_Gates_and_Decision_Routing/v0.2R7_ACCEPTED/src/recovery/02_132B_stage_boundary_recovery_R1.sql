/* ============================================================================
MSBF M2.1 — Eligibility, Policy Gates & Decision Routing Foundations
Program 132B — Failed Stage-Boundary Preflight Recovery and Reference Repair
Version v0.2R1

Purpose
Verify the exact pre-generation state after the v0.2 Program 133 false-positive
stage-boundary failure, prove that the single broad `adverse_action` match is
the governed `reason_code_definition.production_adverse_action_flag`, confirm
that every such flag is false, repair the processor-continuity definition so
UNAVAILABLE is not treated as a passing state, and preserve all application-
level targets as pristine.

Normal sequence
ROLLBACK failed Program 133 → run 132B → run Programs 133–139 v0.2R1.
============================================================================ */
BEGIN;
SET LOCAL statement_timeout='15min';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m2_1_r1_recovery;
CREATE TEMP TABLE _m2_1_r1_recovery ON COMMIT PRESERVE ROWS AS
WITH r AS (
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), p AS (
 SELECT policy_status,configuration_hash FROM msbf_ctl.m2_1_policy_profile
 WHERE policy_code='M2_1_ELIGIBILITY_POLICY_V1'
), g5 AS (
 SELECT review_rule,blocked_rule,row_hash
 FROM msbf_m2.policy_gate_definition
 WHERE module1_run_id=(SELECT run_id FROM r)
   AND strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE'
   AND gate_code='GATE_05_PROCESSOR_CONTINUITY'
), diagnostic AS (
 SELECT
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema='msbf_m2'
     AND lower(column_name) ~ '(apr|factor_rate|approved_amount|offer_amount|remittance_rate|adverse_action|funded_outcome)')
      AS original_broad_prohibited_columns,
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema='msbf_m2'
     AND table_name='reason_code_definition'
     AND column_name='production_adverse_action_flag')
      AS adverse_action_governance_columns,
  (SELECT count(*) FROM msbf_m2.reason_code_definition
   WHERE module1_run_id=(SELECT run_id FROM r)
     AND production_adverse_action_flag)
      AS production_adverse_action_rows,
  (SELECT count(*) FROM information_schema.columns
   WHERE table_schema='msbf_m2'
     AND table_name IN ('application_policy_gate_result','application_eligibility_routing_snapshot','application_eligibility_routing_latest','application_eligibility_routing_archive')
     AND lower(column_name) IN ('apr','factor_rate','approved_amount','offer_amount','remittance_rate','offer_term','approved_term','final_price','funded_flag','funded_outcome','funding_status','booking_status','adverse_action_code','adverse_action_notice'))
      AS corrected_prohibited_application_columns
), targets AS (
 SELECT
  (SELECT count(*) FROM msbf_m2.application_policy_gate_result WHERE module1_run_id=(SELECT run_id FROM r)) gate_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) snapshot_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=(SELECT run_id FROM r)) latest_rows,
  (SELECT count(*) FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=(SELECT run_id FROM r)) archive_rows,
  (SELECT count(*) FROM msbf_ctl.m2_1_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)) registry_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M2_1_%') evidence_rows,
  (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING') acceptance_rows,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') blocking_errors,
  (SELECT count(*) FROM information_schema.tables WHERE table_schema='msbf_m2' AND table_name LIKE 'm2_2%') m2_2_tables
)
SELECT r.run_id,r.run_status,p.policy_status,p.configuration_hash,
       g5.review_rule AS prior_g5_review_rule,g5.blocked_rule AS prior_g5_blocked_rule,
       g5.row_hash AS prior_g5_row_hash,diagnostic.*,targets.*
FROM r CROSS JOIN p CROSS JOIN g5 CROSS JOIN diagnostic CROSS JOIN targets;

DO $guard$
DECLARE v record;
BEGIN
 SELECT * INTO v FROM _m2_1_r1_recovery;
 IF v.run_status<>'M1_17_ACCEPTED' OR v.policy_status<>'APPROVED'
    OR v.original_broad_prohibited_columns<>1
    OR v.adverse_action_governance_columns<>1
    OR v.production_adverse_action_rows<>0
    OR v.corrected_prohibited_application_columns<>0
    OR v.gate_rows<>0 OR v.snapshot_rows<>0 OR v.latest_rows<>0
    OR v.archive_rows<>0 OR v.registry_rows<>0 OR v.evidence_rows<>0
    OR v.acceptance_rows<>0 OR v.blocking_errors<>0 OR v.m2_2_tables<>0 THEN
  RAISE EXCEPTION 'M2.1 v0.2R1 recovery preconditions failed: %',row_to_json(v);
 END IF;
END;
$guard$;

UPDATE msbf_m2.policy_gate_definition
SET review_rule='WATCH, DISRUPTED, or UNAVAILABLE'
WHERE module1_run_id=(SELECT run_id FROM _m2_1_r1_recovery)
  AND strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE'
  AND gate_code='GATE_05_PROCESSOR_CONTINUITY';

UPDATE msbf_m2.policy_gate_definition AS d
SET row_hash=msbf_ctl.m2_1_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')
WHERE d.module1_run_id=(SELECT run_id FROM _m2_1_r1_recovery)
  AND d.strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE'
  AND d.gate_code='GATE_05_PROCESSOR_CONTINUITY';

ALTER TABLE _m2_1_r1_recovery
 ADD COLUMN final_g5_review_rule text,
 ADD COLUMN final_g5_row_hash text,
 ADD COLUMN final_g5_hash_mismatches bigint,
 ADD COLUMN recovery_status text;

UPDATE _m2_1_r1_recovery AS r
SET final_g5_review_rule=(SELECT review_rule FROM msbf_m2.policy_gate_definition WHERE module1_run_id=r.run_id AND strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE' AND gate_code='GATE_05_PROCESSOR_CONTINUITY'),
    final_g5_row_hash=(SELECT row_hash FROM msbf_m2.policy_gate_definition WHERE module1_run_id=r.run_id AND strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE' AND gate_code='GATE_05_PROCESSOR_CONTINUITY'),
    final_g5_hash_mismatches=(SELECT count(*) FROM msbf_m2.policy_gate_definition AS d WHERE d.module1_run_id=r.run_id AND d.strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE' AND d.gate_code='GATE_05_PROCESSOR_CONTINUITY' AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_1_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')),
    recovery_status='PASS'
WHERE r.run_id IS NOT NULL;

DO $final_guard$
DECLARE v record;
BEGIN
 SELECT * INTO v FROM _m2_1_r1_recovery;
 IF v.final_g5_review_rule<>'WATCH, DISRUPTED, or UNAVAILABLE'
    OR v.final_g5_row_hash IS NULL OR v.final_g5_hash_mismatches<>0 THEN
  RAISE EXCEPTION 'M2.1 v0.2R1 final recovery state failed: %',row_to_json(v);
 END IF;
END;
$final_guard$;

COMMIT;
SELECT * FROM _m2_1_r1_recovery;
