/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.11 — Portfolio Optimization & Strategy Simulation

Recovery    : 215A_msbf_m2_11_failed_positive_validation_recovery_v1.sql
Version     : v1
Work package: M2.11 Work Package 3

Purpose
-------
Repair only an incomplete or inconsistent Program 215 validation checkpoint.
The recovery deletes partial M2_11_POS evidence and restores mutable run and
contract lifecycle fields to the Program 214 GENERATED checkpoint. It never
regenerates, updates, or deletes canonical M2.11 business rows.

Fail-closed boundaries
----------------------
- Refuses a complete 120/120 committed positive-validation checkpoint.
- Refuses any M2_11 negative-control or acceptance evidence.
- Refuses an already accepted lifecycle.
- Requires an actual partial-evidence or lifecycle inconsistency to repair.
- Reconciles all nineteen canonical family counts and ordered hashes before and
  after recovery and requires zero change.

Execution
---------
Use only after diagnosis. Never place this recovery in the normal execution
chain. Execute as one SQL script and stop on the first error. This source is
statically built and has not been executed by the build environment.
============================================================================ */

BEGIN;
SET LOCAL statement_timeout='20min';
SET LOCAL lock_timeout='15s';
SET LOCAL jit=off;

DROP TABLE IF EXISTS tmp_eval_215a_context;
CREATE TEMP TABLE tmp_eval_215a_context ON COMMIT DROP AS
SELECT r.run_id,r.run_status,c.contract_status,c.contract_version,c.validated_at,
       c.row_hash AS registry_row_hash,c.combined_set_hash,
       (SELECT count(*) FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r.run_id AND e.evidence_code LIKE 'M2_11_POS_%')::bigint AS positive_evidence_rows
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry c
  ON c.module1_run_id=r.run_id AND c.contract_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

DROP TABLE IF EXISTS tmp_eval_215a_before;
CREATE TEMP TABLE tmp_eval_215a_before ON COMMIT DROP AS
SELECT catalog_sequence,object_code,count(*)::bigint AS row_count,
       md5(string_agg(row_hash,'' ORDER BY business_key)) AS ordered_hash
FROM msbf_m2.v_m2_11_canonical_entity_hash_source
WHERE split_part(business_key,'|',1)=(SELECT run_id::text FROM tmp_eval_215a_context)
GROUP BY catalog_sequence,object_code;
CREATE UNIQUE INDEX tmp_eval_215a_before_u1 ON tmp_eval_215a_before(catalog_sequence,object_code);
ANALYZE tmp_eval_215a_before;

DO $m211_recovery_215a_preflight$
DECLARE
 v_rows bigint;
 v_pos_total bigint;
 v_pos_pass bigint;
 v_pos_fail bigint;
BEGIN
 SELECT count(*) INTO v_rows FROM tmp_eval_215a_context;
 IF v_rows<>1 THEN RAISE EXCEPTION 'Recovery 215A requires one M2.11 context; found %',v_rows; END IF;
 IF (SELECT run_status FROM tmp_eval_215a_context)='M2_11_ACCEPTED'
    OR (SELECT contract_status FROM tmp_eval_215a_context)='ACCEPTED' THEN
  RAISE EXCEPTION 'Recovery 215A refuses accepted M2.11 state';
 END IF;
 IF (SELECT run_status FROM tmp_eval_215a_context) NOT IN ('M2_11_GENERATED','M2_11_VALIDATED')
    OR (SELECT contract_status FROM tmp_eval_215a_context) NOT IN ('GENERATED','VALIDATED') THEN
  RAISE EXCEPTION 'Recovery 215A found unsupported lifecycle %/%',
   (SELECT run_status FROM tmp_eval_215a_context),(SELECT contract_status FROM tmp_eval_215a_context);
 END IF;
 SELECT count(*),count(*) FILTER(WHERE status='PASS'),count(*) FILTER(WHERE status='FAIL')
 INTO v_pos_total,v_pos_pass,v_pos_fail
 FROM msbf_ctl.run_evidence
 WHERE run_id=(SELECT run_id FROM tmp_eval_215a_context) AND evidence_code LIKE 'M2_11_POS_%';
 IF v_pos_total=120 AND v_pos_pass=120 AND v_pos_fail=0 THEN
  RAISE EXCEPTION 'Recovery 215A refuses a complete 120/120 positive-validation checkpoint';
 END IF;
 IF EXISTS(SELECT 1 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_215a_context) AND evidence_code LIKE 'M2_11_NEG_%') THEN
  RAISE EXCEPTION 'Recovery 215A refuses state containing M2.11 negative-control evidence';
 END IF;
 IF EXISTS(SELECT 1 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_215a_context) AND evidence_code='M2_11_ACCEPTANCE_SUMMARY')
    OR EXISTS(SELECT 1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_eval_215a_context) AND gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION') THEN
  RAISE EXCEPTION 'Recovery 215A refuses state containing M2.11 acceptance evidence';
 END IF;
 IF v_pos_total=0
    AND (SELECT run_status FROM tmp_eval_215a_context)='M2_11_GENERATED'
    AND (SELECT contract_status FROM tmp_eval_215a_context)='GENERATED'
    AND (SELECT validated_at FROM tmp_eval_215a_context) IS NULL THEN
  RAISE EXCEPTION 'Recovery 215A found no partial validation artifact or lifecycle inconsistency to repair';
 END IF;
 IF (SELECT count(*) FROM tmp_eval_215a_before)<>19
    OR (SELECT sum(row_count) FROM tmp_eval_215a_before)<>19298 THEN
  RAISE EXCEPTION 'Recovery 215A pre-recovery canonical identity mismatch: families %, entities %',
   (SELECT count(*) FROM tmp_eval_215a_before),(SELECT sum(row_count) FROM tmp_eval_215a_before);
 END IF;
END;
$m211_recovery_215a_preflight$;

DO $m211_recovery_215a_mutation$
DECLARE
 v_rows bigint;
BEGIN
 DELETE FROM msbf_ctl.run_evidence
 WHERE run_id=(SELECT run_id FROM tmp_eval_215a_context)
   AND evidence_code LIKE 'M2_11_POS_%';
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>(SELECT positive_evidence_rows FROM tmp_eval_215a_context) THEN
  RAISE EXCEPTION 'Recovery 215A positive-evidence delete expected % rows; deleted %',
   (SELECT positive_evidence_rows FROM tmp_eval_215a_context),v_rows;
 END IF;

 UPDATE msbf_ctl.m2_11_portfolio_strategy_contract_registry
 SET contract_status='GENERATED',validated_at=NULL
 WHERE module1_run_id=(SELECT run_id FROM tmp_eval_215a_context)
   AND contract_version=1 AND contract_status IN ('GENERATED','VALIDATED');
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>1 THEN
  RAISE EXCEPTION 'Recovery 215A registry lifecycle reset expected 1 row; updated %',v_rows;
 END IF;

 UPDATE msbf_ctl.run_registry
 SET run_status='M2_11_GENERATED'
 WHERE run_id=(SELECT run_id FROM tmp_eval_215a_context)
   AND run_status IN ('M2_11_GENERATED','M2_11_VALIDATED');
 GET DIAGNOSTICS v_rows=ROW_COUNT;
 IF v_rows<>1 THEN
  RAISE EXCEPTION 'Recovery 215A run lifecycle reset expected 1 row; updated %',v_rows;
 END IF;
END;
$m211_recovery_215a_mutation$;

DROP TABLE IF EXISTS tmp_eval_215a_after;
CREATE TEMP TABLE tmp_eval_215a_after ON COMMIT DROP AS
SELECT catalog_sequence,object_code,count(*)::bigint AS row_count,
       md5(string_agg(row_hash,'' ORDER BY business_key)) AS ordered_hash
FROM msbf_m2.v_m2_11_canonical_entity_hash_source
WHERE split_part(business_key,'|',1)=(SELECT run_id::text FROM tmp_eval_215a_context)
GROUP BY catalog_sequence,object_code;
CREATE UNIQUE INDEX tmp_eval_215a_after_u1 ON tmp_eval_215a_after(catalog_sequence,object_code);
ANALYZE tmp_eval_215a_after;

DO $m211_recovery_215a_postflight$
DECLARE
 v_mismatch bigint;
BEGIN
 SELECT count(*) INTO v_mismatch
 FROM tmp_eval_215a_before b
 FULL JOIN tmp_eval_215a_after a USING(catalog_sequence,object_code)
 WHERE b.object_code IS NULL OR a.object_code IS NULL
    OR b.row_count IS DISTINCT FROM a.row_count
    OR b.ordered_hash IS DISTINCT FROM a.ordered_hash;
 IF v_mismatch<>0 THEN
  RAISE EXCEPTION 'Recovery 215A changed canonical business identity for % object families',v_mismatch;
 END IF;
 IF (SELECT count(*) FROM tmp_eval_215a_after)<>19 OR (SELECT sum(row_count) FROM tmp_eval_215a_after)<>19298 THEN
  RAISE EXCEPTION 'Recovery 215A post-recovery canonical identity mismatch';
 END IF;
 IF EXISTS(SELECT 1 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM tmp_eval_215a_context) AND evidence_code LIKE 'M2_11_POS_%') THEN
  RAISE EXCEPTION 'Recovery 215A failed to remove partial positive-validation evidence';
 END IF;
 IF (SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=(SELECT run_id FROM tmp_eval_215a_context))<>'M2_11_GENERATED'
    OR (SELECT contract_status FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
        WHERE module1_run_id=(SELECT run_id FROM tmp_eval_215a_context) AND contract_version=1)<>'GENERATED'
    OR (SELECT validated_at FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
        WHERE module1_run_id=(SELECT run_id FROM tmp_eval_215a_context) AND contract_version=1) IS NOT NULL THEN
  RAISE EXCEPTION 'Recovery 215A failed to restore the GENERATED lifecycle checkpoint';
 END IF;
 IF (SELECT row_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
     WHERE module1_run_id=(SELECT run_id FROM tmp_eval_215a_context) AND contract_version=1)
    IS DISTINCT FROM (SELECT registry_row_hash FROM tmp_eval_215a_context) THEN
  RAISE EXCEPTION 'Recovery 215A changed immutable registry identity';
 END IF;
 IF (SELECT combined_set_hash FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
     WHERE module1_run_id=(SELECT run_id FROM tmp_eval_215a_context) AND contract_version=1)
    IS DISTINCT FROM (SELECT combined_set_hash FROM tmp_eval_215a_context) THEN
  RAISE EXCEPTION 'Recovery 215A changed immutable registry combined-set identity';
 END IF;
END;
$m211_recovery_215a_postflight$;

COMMIT;

SELECT
 'M2_11_RECOVERY_215A_COMPLETE'::text AS recovery_status,
 19::integer AS canonical_families_verified,
 19298::bigint AS canonical_entities_verified,
 'M2_11_GENERATED'::text AS restored_run_status,
 'GENERATED'::text AS restored_contract_status,
 'VALIDATION_STATE_ONLY'::text AS mutation_boundary;
