/***************************************************************************************************
M2.12 — ENTERPRISE PORTFOLIO CERTIFICATION & CONSUMPTION CONTRACT
PROGRAM 222A — Failed Pre-Commit Certification Generation and Sequence-State Recovery

WORK PACKAGE
M2.12 Work Package 2 — SQL Source Construction R1

PROGRAM CLASS
RECOVERY

GOVERNING IMPLEMENTATION AUTHORITY
M2_12_Build_WP1_R10.zip
SHA-256: 2e4017c80b03bf7ff691b114654beed0a63dcf677607bde11696f6b5582e6d10
M2_12_WP1_SOURCE_AUTHORITY_R10.md
M2_12_WP2_LITERAL_PROGRAM_STATEMENT_ORDER_CATALOG.csv
M2_12_WP2_LITERAL_COMPILATION_DECISION_MATRIX.csv

CONSTRUCTION RULE
The executable SQL below is a direct ordered transcription of the approved R10 literal-statement
authority. No governed statement was added, omitted, duplicated, reordered, or semantically rewritten.
Surrounding comments are non-executable traceability metadata only.

EXECUTION STATUS
STATIC SOURCE ONLY
NOT EXECUTED
NOT VALIDATED
NOT ACCEPTED

OPERATOR BOUNDARY
Do not execute until WP2 receives independent approval and separate live-execution authorization.
Execute the complete file as one script and stop at the first error. Recovery programs are contingency-
only and must not appear in the normal chain or run without diagnosis and explicit authorization.
***************************************************************************************************/
/* R10 GOVERNED STATEMENT 0001 OF 0026
   statement_code: BEGIN
   phase_code: 00_TRANSACTION
   statement_type: TRANSACTION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
BEGIN;

/* R10 GOVERNED STATEMENT 0002 OF 0026
   statement_code: SEARCH_PATH
   phase_code: 00_TRANSACTION
   statement_type: SESSION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
SET LOCAL search_path = msbf_ctl, msbf_m2, msbf_ref, public;

/* R10 GOVERNED STATEMENT 0003 OF 0026
   statement_code: CREATE_TMP_RECOVER_M2_12_GOVERNED_SCOPE
   phase_code: 01_CONTEXT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_governed_scope ON COMMIT DROP AS
SELECT rr.run_id::bigint AS module1_run_id, rr.run_status::text AS run_status,
       ((to_regclass('msbf_ctl.m2_12_policy_profile') IS NOT NULL)::integer
        +(to_regclass('msbf_m2.module2_stage_certification_snapshot') IS NOT NULL)::integer
        +(to_regclass('msbf_m2.module2_contract_component_snapshot') IS NOT NULL)::integer
        +(to_regclass('msbf_m2.module2_evidence_certification_snapshot') IS NOT NULL)::integer
        +(to_regclass('msbf_m2.module2_contract_reproduction_snapshot') IS NOT NULL)::integer
        +(to_regclass('msbf_m2.module2_capability_coverage_snapshot') IS NOT NULL)::integer
        +(to_regclass('msbf_ctl.m2_12_g3_bundle_latest') IS NOT NULL)::integer
        +(to_regclass('msbf_ctl.m2_12_g3_bundle_archive') IS NOT NULL)::integer
        +(to_regclass('msbf_ctl.m2_12_g3_bundle_registry') IS NOT NULL)::integer
        +(to_regprocedure('msbf_ctl.m2_12_reject_g3_archive_mutation()') IS NOT NULL)::integer
        +(EXISTS(SELECT 1 FROM pg_catalog.pg_trigger WHERE tgname='trg_m2_12_g3_archive_immutable' AND NOT tgisinternal))::integer
        +(to_regclass('msbf_m2.v_m2_12_application_origination_consumption') IS NOT NULL)::integer
        +(to_regclass('msbf_m2.v_m2_12_operational_account_consumption') IS NOT NULL)::integer
        +(to_regclass('msbf_m2.v_m2_12_strategy_scope_consumption') IS NOT NULL)::integer
        +(to_regclass('msbf_ctl.v_m2_12_stage_lineage') IS NOT NULL)::integer
        +(to_regclass('msbf_ctl.v_m2_12_component_contract_lineage') IS NOT NULL)::integer
        +(to_regclass('msbf_ctl.v_m2_12_g3_lineage') IS NOT NULL)::integer
        +(to_regclass('msbf_m2.v_m2_12_power_bi_enterprise_portfolio') IS NOT NULL)::integer
        +(to_regclass('msbf_ctl.m2_12_policy_profile_policy_profile_id_seq') IS NOT NULL)::integer
        +(to_regclass('msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq') IS NOT NULL)::integer
        +(to_regclass('msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq') IS NOT NULL)::integer)::integer AS installed_top_level_object_count,
       CASE WHEN to_regclass('msbf_ctl.m2_12_policy_profile') IS NULL THEN 0 ELSE (SELECT count(*) FROM msbf_ctl.m2_12_policy_profile p WHERE p.module1_run_id=rr.run_id) END::bigint AS policy_rows,
       (CASE WHEN to_regclass('msbf_m2.module2_stage_certification_snapshot') IS NULL THEN 0 ELSE (SELECT count(*) FROM msbf_m2.module2_stage_certification_snapshot x WHERE x.module1_run_id=rr.run_id) END
       +CASE WHEN to_regclass('msbf_m2.module2_contract_component_snapshot') IS NULL THEN 0 ELSE (SELECT count(*) FROM msbf_m2.module2_contract_component_snapshot x WHERE x.module1_run_id=rr.run_id) END
       +CASE WHEN to_regclass('msbf_m2.module2_evidence_certification_snapshot') IS NULL THEN 0 ELSE (SELECT count(*) FROM msbf_m2.module2_evidence_certification_snapshot x WHERE x.module1_run_id=rr.run_id) END
       +CASE WHEN to_regclass('msbf_m2.module2_contract_reproduction_snapshot') IS NULL THEN 0 ELSE (SELECT count(*) FROM msbf_m2.module2_contract_reproduction_snapshot x WHERE x.module1_run_id=rr.run_id) END
       +CASE WHEN to_regclass('msbf_m2.module2_capability_coverage_snapshot') IS NULL THEN 0 ELSE (SELECT count(*) FROM msbf_m2.module2_capability_coverage_snapshot x WHERE x.module1_run_id=rr.run_id) END
       +CASE WHEN to_regclass('msbf_ctl.m2_12_g3_bundle_latest') IS NULL THEN 0 ELSE (SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_latest x WHERE x.module1_run_id=rr.run_id) END
       +CASE WHEN to_regclass('msbf_ctl.m2_12_g3_bundle_archive') IS NULL THEN 0 ELSE (SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_archive x WHERE x.module1_run_id=rr.run_id) END
       +CASE WHEN to_regclass('msbf_ctl.m2_12_g3_bundle_registry') IS NULL THEN 0 ELSE (SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_registry x WHERE x.module1_run_id=rr.run_id) END)::bigint AS nonpolicy_rows,
       (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=rr.run_id AND e.segment_key='M2_12' AND e.evidence_code LIKE 'M2_12_%')::bigint AS evidence_rows,
       (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=rr.run_id AND g.gate_id='G3_M2_CONTRACT')::bigint AS gate_rows,
       (to_regclass('msbf_ctl.m2_12_policy_profile') IS NOT NULL) AS policy_table_exists,
       (to_regclass('msbf_ctl.m2_12_g3_bundle_archive') IS NOT NULL) AS archive_table_exists,
       (to_regclass('msbf_ctl.m2_12_g3_bundle_registry') IS NOT NULL) AS registry_table_exists,
       (to_regclass('msbf_ctl.m2_12_policy_profile_policy_profile_id_seq') IS NOT NULL) AS policy_sequence_exists,
       (to_regclass('msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq') IS NOT NULL) AS archive_sequence_exists,
       (to_regclass('msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq') IS NOT NULL) AS registry_sequence_exists,
       CASE WHEN to_regclass('msbf_ctl.m2_12_policy_profile_policy_profile_id_seq') IS NULL THEN NULL ELSE (SELECT last_value FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq) END::bigint AS policy_sequence_last_value,
       CASE WHEN to_regclass('msbf_ctl.m2_12_policy_profile_policy_profile_id_seq') IS NULL THEN NULL ELSE (SELECT is_called FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq) END::boolean AS policy_sequence_is_called,
       CASE WHEN to_regclass('msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq') IS NULL THEN NULL ELSE (SELECT last_value FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq) END::bigint AS archive_sequence_last_value,
       CASE WHEN to_regclass('msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq') IS NULL THEN NULL ELSE (SELECT is_called FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq) END::boolean AS archive_sequence_is_called,
       CASE WHEN to_regclass('msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq') IS NULL THEN NULL ELSE (SELECT last_value FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq) END::bigint AS registry_sequence_last_value,
       CASE WHEN to_regclass('msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq') IS NULL THEN NULL ELSE (SELECT is_called FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq) END::boolean AS registry_sequence_is_called
FROM msbf_ctl.run_registry rr
WHERE rr.run_code='M1_V0_2_BASELINE_BUILD' AND rr.run_version=1;

/* R10 GOVERNED STATEMENT 0004 OF 0026
   statement_code: ASSERT_TMP_RECOVER_M2_12_GOVERNED_SCOPE
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_recover_m2_12_governed_scope$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_governed_scope) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_recover_m2_12_governed_scope', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_recover_m2_12_governed_scope)::text; END IF; END; $m212_r7_tmp_recover_m2_12_governed_scope$;

/* R10 GOVERNED STATEMENT 0005 OF 0026
   statement_code: INDEX_TMP_RECOVER_M2_12_GOVERNED_SCOPE
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_recover_m2_12_governed_scope_4f110475 ON tmp_recover_m2_12_governed_scope (module1_run_id);

/* R10 GOVERNED STATEMENT 0006 OF 0026
   statement_code: ANALYZE_TMP_RECOVER_M2_12_GOVERNED_SCOPE
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_governed_scope;

/* R10 GOVERNED STATEMENT 0007 OF 0026
   statement_code: CREATE_TMP_RECOVER_M2_12_222A_CONTEXT_BASE
   phase_code: 01_CONTEXT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_222a_context_base ON COMMIT DROP AS
SELECT scope.module1_run_id::bigint AS module1_run_id,
       scope.run_status::text AS run_status,
       scope.policy_rows::bigint AS policy_rows,
       scope.nonpolicy_rows::bigint AS nonpolicy_rows,
       scope.evidence_rows::bigint AS evidence_rows
FROM tmp_recover_m2_12_governed_scope scope;

/* R10 GOVERNED STATEMENT 0008 OF 0026
   statement_code: ASSERT_TMP_RECOVER_M2_12_222A_CONTEXT_BASE
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_recover_m2_12_222a_context_base$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_222a_context_base) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_recover_m2_12_222a_context_base', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_recover_m2_12_222a_context_base)::text; END IF; END; $m212_r7_tmp_recover_m2_12_222a_context_base$;

/* R10 GOVERNED STATEMENT 0009 OF 0026
   statement_code: INDEX_TMP_RECOVER_M2_12_222A_CONTEXT_BASE
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_recover_m2_12_222a_context_base_c218154c ON tmp_recover_m2_12_222a_context_base (module1_run_id);

/* R10 GOVERNED STATEMENT 0010 OF 0026
   statement_code: ANALYZE_TMP_RECOVER_M2_12_222A_CONTEXT_BASE
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_222a_context_base;

/* R10 GOVERNED STATEMENT 0011 OF 0026
   statement_code: CREATE_TMP_RECOVER_M2_12_222A_SEQUENCE_BEFORE
   phase_code: 01_CONTEXT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_222a_sequence_before ON COMMIT DROP AS
SELECT 'msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq'::text AS sequence_name,
       (SELECT s.last_value FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq s)::bigint AS last_value,
       (SELECT s.is_called FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq s)::boolean AS is_called
UNION ALL
SELECT 'msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq'::text,
       (SELECT s.last_value FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq s)::bigint,
       (SELECT s.is_called FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq s)::boolean;

/* R10 GOVERNED STATEMENT 0012 OF 0026
   statement_code: ASSERT_TMP_RECOVER_M2_12_222A_SEQUENCE_BEFORE
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_recover_m2_12_222a_sequence_before$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_222a_sequence_before) <> 2 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_recover_m2_12_222a_sequence_before', DETAIL='expected=2 observed='||(SELECT count(*) FROM tmp_recover_m2_12_222a_sequence_before)::text; END IF; END; $m212_r7_tmp_recover_m2_12_222a_sequence_before$;

/* R10 GOVERNED STATEMENT 0013 OF 0026
   statement_code: INDEX_TMP_RECOVER_M2_12_222A_SEQUENCE_BEFORE
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_recover_m2_12_222a_sequence_before_ee5e99af ON tmp_recover_m2_12_222a_sequence_before (sequence_name);

/* R10 GOVERNED STATEMENT 0014 OF 0026
   statement_code: ANALYZE_TMP_RECOVER_M2_12_222A_SEQUENCE_BEFORE
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_222a_sequence_before;

/* R10 GOVERNED STATEMENT 0015 OF 0026
   statement_code: CREATE_TMP_RECOVER_M2_12_222A_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_222a_context ON COMMIT DROP AS
SELECT b.module1_run_id,
       CASE
         WHEN b.run_status='M2_11_ACCEPTED' AND b.policy_rows=1 AND b.nonpolicy_rows=0 AND b.evidence_rows=0
              AND scope.gate_rows=0 AND scope.policy_sequence_exists AND scope.policy_sequence_last_value=1 AND scope.policy_sequence_is_called
              AND scope.archive_sequence_exists AND scope.archive_sequence_last_value=1 AND NOT scope.archive_sequence_is_called
              AND scope.registry_sequence_exists AND scope.registry_sequence_last_value=1 AND NOT scope.registry_sequence_is_called
           THEN 'NO_ACTION_PRISTINE'
         WHEN b.run_status='M2_11_ACCEPTED' AND b.policy_rows=1 AND b.nonpolicy_rows=0 AND b.evidence_rows=0
              AND scope.gate_rows=0 AND scope.policy_sequence_exists AND scope.policy_sequence_last_value=1 AND scope.policy_sequence_is_called
              AND scope.archive_sequence_exists AND scope.registry_sequence_exists
              AND scope.archive_sequence_last_value>=1 AND scope.registry_sequence_last_value>=1
              AND (scope.archive_sequence_last_value<>1 OR scope.archive_sequence_is_called OR scope.registry_sequence_last_value<>1 OR scope.registry_sequence_is_called)
           THEN 'RESTORE_FAILED_GENERATION_SEQUENCES'
         ELSE 'REFUSE_RESIDUE_OR_COMMITTED'
       END::text AS recovery_decision_code,
       (b.run_status='M2_11_ACCEPTED' AND b.policy_rows=1 AND b.nonpolicy_rows=0 AND b.evidence_rows=0 AND scope.gate_rows=0
        AND scope.policy_sequence_exists AND scope.policy_sequence_last_value=1 AND scope.policy_sequence_is_called
        AND scope.archive_sequence_exists AND scope.registry_sequence_exists)::boolean AS recovery_permitted_flag
FROM tmp_recover_m2_12_222a_context_base b
JOIN tmp_recover_m2_12_governed_scope scope ON scope.module1_run_id=b.module1_run_id;

/* R10 GOVERNED STATEMENT 0016 OF 0026
   statement_code: ASSERT_TMP_RECOVER_M2_12_222A_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_recover_m2_12_222a_context$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_222a_context) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_recover_m2_12_222a_context', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_recover_m2_12_222a_context)::text; END IF; END; $m212_r7_tmp_recover_m2_12_222a_context$;

/* R10 GOVERNED STATEMENT 0017 OF 0026
   statement_code: INDEX_TMP_RECOVER_M2_12_222A_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_recover_m2_12_222a_context_09bb366a ON tmp_recover_m2_12_222a_context (module1_run_id);

/* R10 GOVERNED STATEMENT 0018 OF 0026
   statement_code: ANALYZE_TMP_RECOVER_M2_12_222A_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_222a_context;

/* R10 GOVERNED STATEMENT 0019 OF 0026
   statement_code: RECOVERY_DISPATCH
   phase_code: 02_DISPATCH
   statement_type: RECOVERY_DECISION
   source_authority: M2_12_RECOVERY_DECISION_DISPATCH_COMPILER.csv
*/
DO $m212_r7_222a_dispatch$
DECLARE v_decision text;
BEGIN
  SELECT recovery_decision_code INTO STRICT v_decision FROM tmp_recover_m2_12_222a_context;
  IF v_decision='NO_ACTION_PRISTINE' THEN
    NULL;
  ELSIF v_decision='RESTORE_FAILED_GENERATION_SEQUENCES' THEN
  PERFORM setval('msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq'::regclass,1,false);
  PERFORM setval('msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq'::regclass,1,false);
  ELSE
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 222A recovery refused: residue, committed state, or invalid policy sequence';
  END IF;
END;
$m212_r7_222a_dispatch$;

/* R10 GOVERNED STATEMENT 0020 OF 0026
   statement_code: CREATE_TMP_RECOVER_M2_12_222A_RESULT
   phase_code: 03_RESULT_STATE
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_222a_result ON COMMIT DROP AS
SELECT '222A'::text AS recovery_program,
       c.recovery_decision_code::text AS recovery_decision_code,
       CASE WHEN c.recovery_permitted_flag THEN 'PASS' ELSE 'FAIL' END::text AS recovery_status,
       CASE WHEN to_regclass('msbf_ctl.m2_12_policy_profile_policy_profile_id_seq') IS NULL THEN 'NOT_PRESENT' ELSE (SELECT s.last_value::text||'|'||s.is_called::text FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq s) END::text AS policy_sequence_state,
       CASE WHEN to_regclass('msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq') IS NULL THEN 'NOT_PRESENT' ELSE (SELECT s.last_value::text||'|'||s.is_called::text FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq s) END::text AS archive_sequence_state,
       CASE WHEN to_regclass('msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq') IS NULL THEN 'NOT_PRESENT' ELSE (SELECT s.last_value::text||'|'||s.is_called::text FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq s) END::text AS registry_sequence_state,
       CASE c.recovery_decision_code WHEN 'NO_ACTION_PRISTINE' THEN 'PASS_NO_ACTION' WHEN 'NO_ACTION_COMPLETE' THEN 'PASS_NO_ACTION' WHEN 'RECOVER_FAILED_INSTALL' THEN 'PASS_RECOVERED' WHEN 'RESTORE_FAILED_GENERATION_SEQUENCES' THEN 'PASS_RECOVERED' WHEN 'REPAIR_MISSING_EVIDENCE_AND_RUN_STATUS' THEN 'PASS_RECOVERED' WHEN 'REPAIR_RUN_STATUS_ONLY' THEN 'PASS_RECOVERED' ELSE 'FAIL_CLOSED' END::text AS disposition
FROM tmp_recover_m2_12_222a_context c;

/* R10 GOVERNED STATEMENT 0021 OF 0026
   statement_code: ASSERT_TMP_RECOVER_M2_12_222A_RESULT
   phase_code: 03_RESULT_STATE
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_recover_m2_12_222a_result$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_222a_result) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_recover_m2_12_222a_result', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_recover_m2_12_222a_result)::text; END IF; END; $m212_r7_tmp_recover_m2_12_222a_result$;

/* R10 GOVERNED STATEMENT 0022 OF 0026
   statement_code: INDEX_TMP_RECOVER_M2_12_222A_RESULT
   phase_code: 03_RESULT_STATE
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_recover_m2_12_222a_result_1979a178 ON tmp_recover_m2_12_222a_result (recovery_program);

/* R10 GOVERNED STATEMENT 0023 OF 0026
   statement_code: ANALYZE_TMP_RECOVER_M2_12_222A_RESULT
   phase_code: 03_RESULT_STATE
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_222a_result;

/* R10 GOVERNED STATEMENT 0024 OF 0026
   statement_code: RECOVERY_POSTCONDITION
   phase_code: 04_POSTCONDITION
   statement_type: POSTFLIGHT
   source_authority: M2_12_RECOVERY_DECISION_DISPATCH_COMPILER.csv
*/
DO $m212_r7_222a_post$
BEGIN
 IF (SELECT count(*) FROM msbf_ctl.m2_12_policy_profile p JOIN msbf_ctl.run_registry rr ON rr.run_id=p.module1_run_id WHERE rr.run_code='M1_V0_2_BASELINE_BUILD' AND rr.run_version=1)<>1
 OR (SELECT last_value<>1 OR NOT is_called FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq)
 OR (SELECT last_value<>1 OR is_called FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq)
 OR (SELECT last_value<>1 OR is_called FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq)
 OR (SELECT run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)<>'M2_11_ACCEPTED'
 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 222A postcondition failed'; END IF;
END;
$m212_r7_222a_post$;

/* R10 GOVERNED STATEMENT 0025 OF 0026
   statement_code: PRIMARY_RESULT
   phase_code: 05_RESULT
   statement_type: RESULT_SELECT
   source_authority: M2_12_PROGRAM_PRIMARY_RESULT_STATEMENT_COMPILER.csv
*/
SELECT recovery_program,recovery_decision_code,recovery_status,policy_sequence_state,archive_sequence_state,registry_sequence_state,disposition
FROM tmp_recover_m2_12_222a_result;

/* R10 GOVERNED STATEMENT 0026 OF 0026
   statement_code: COMMIT
   phase_code: 06_COMMIT
   statement_type: TRANSACTION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
COMMIT;

