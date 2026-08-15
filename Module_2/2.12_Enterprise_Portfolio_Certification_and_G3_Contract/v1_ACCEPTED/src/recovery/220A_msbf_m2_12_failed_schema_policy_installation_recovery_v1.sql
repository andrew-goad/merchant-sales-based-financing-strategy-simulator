/***************************************************************************************************
M2.12 — ENTERPRISE PORTFOLIO CERTIFICATION & CONSUMPTION CONTRACT
PROGRAM 220A — Failed Schema/Policy Installation Recovery

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
/* R10 GOVERNED STATEMENT 0001 OF 0022
   statement_code: BEGIN
   phase_code: 00_TRANSACTION
   statement_type: TRANSACTION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
BEGIN;

/* R10 GOVERNED STATEMENT 0002 OF 0022
   statement_code: SEARCH_PATH
   phase_code: 00_TRANSACTION
   statement_type: SESSION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
SET LOCAL search_path = msbf_ctl, msbf_m2, msbf_ref, public;

/* R10 GOVERNED STATEMENT 0003 OF 0022
   statement_code: CREATE_TMP_RECOVER_M2_12_220A_CONTEXT_BASE
   phase_code: 01_CONTEXT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_220a_context_base ON COMMIT DROP AS
SELECT rr.run_id::bigint AS module1_run_id,rr.run_status::text AS run_status,
 (SELECT count(*)::integer FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('msbf_ctl','msbf_m2') AND c.relkind='r' AND c.relname IN ('m2_12_policy_profile','module2_stage_certification_snapshot','module2_contract_component_snapshot','module2_evidence_certification_snapshot','module2_contract_reproduction_snapshot','module2_capability_coverage_snapshot','m2_12_g3_bundle_latest','m2_12_g3_bundle_archive','m2_12_g3_bundle_registry')) AS installed_table_count,
 (SELECT count(*)::integer FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('msbf_ctl','msbf_m2') AND c.relkind='v' AND c.relname IN ('v_m2_12_application_origination_consumption','v_m2_12_operational_account_consumption','v_m2_12_strategy_scope_consumption','v_m2_12_stage_lineage','v_m2_12_component_contract_lineage','v_m2_12_g3_lineage','v_m2_12_power_bi_enterprise_portfolio')) AS installed_view_count,
 (SELECT count(*)::integer FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='msbf_ctl' AND p.proname='m2_12_reject_g3_archive_mutation' AND p.pronargs=0) AS installed_function_count,
 (SELECT count(*)::integer FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_class c ON c.oid=t.tgrelid JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE NOT t.tgisinternal AND n.nspname='msbf_ctl' AND c.relname='m2_12_g3_bundle_archive' AND t.tgname='trg_m2_12_g3_archive_immutable') AS installed_trigger_count,
 (SELECT count(*)::integer FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('msbf_ctl','msbf_m2') AND c.relkind='i' AND c.relname IN ('ix_m212_archive_contract','ix_m212_latest_contract','ix_m212_registry_status','ix_m212_capability_status','ix_m212_component_status','ix_m212_reproduction_status','ix_m212_evidence_family','ix_m212_stage_status')) AS installed_index_count,
 (SELECT count(*)::integer FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='msbf_ctl' AND c.relkind='S' AND c.relname IN ('m2_12_policy_profile_policy_profile_id_seq','m2_12_g3_bundle_archive_archive_id_seq','m2_12_g3_bundle_registry_registry_id_seq')) AS installed_sequence_count,
 0::bigint AS policy_rows,0::bigint AS nonpolicy_rows,
 (SELECT count(*)::bigint FROM msbf_ctl.run_evidence e WHERE e.run_id=rr.run_id AND e.evidence_code LIKE 'M2_12_%') AS evidence_rows,
 (SELECT count(*)::bigint FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=rr.run_id AND g.gate_id='G3_M2_CONTRACT') AS gate_rows,
 NULL::bigint AS policy_sequence_last_value,NULL::boolean AS policy_sequence_is_called,NULL::bigint AS archive_sequence_last_value,NULL::boolean AS archive_sequence_is_called,NULL::bigint AS registry_sequence_last_value,NULL::boolean AS registry_sequence_is_called
FROM msbf_ctl.run_registry rr WHERE rr.run_code='M1_V0_2_BASELINE_BUILD' AND rr.run_version=1;

/* R10 GOVERNED STATEMENT 0004 OF 0022
   statement_code: ASSERT_TMP_RECOVER_M2_12_220A_CONTEXT_BASE
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r8_220a_context_assert$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_220a_context_base)<>1 THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 220A context row count mismatch'; END IF; END; $m212_r8_220a_context_assert$;

/* R10 GOVERNED STATEMENT 0005 OF 0022
   statement_code: INDEX_TMP_RECOVER_M2_12_220A_CONTEXT_BASE
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_tmp_recover_m2_12_220a_context_base ON tmp_recover_m2_12_220a_context_base(module1_run_id);

/* R10 GOVERNED STATEMENT 0006 OF 0022
   statement_code: ANALYZE_TMP_RECOVER_M2_12_220A_CONTEXT_BASE
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_220a_context_base;

/* R10 GOVERNED STATEMENT 0007 OF 0022
   statement_code: OBSERVE_220A_DYNAMIC_STATE
   phase_code: 01_CONTEXT
   statement_type: DYNAMIC_OBSERVATION
   source_authority: M2_12_PROGRAM_220A_ABSENT_OBJECT_DYNAMIC_OBSERVATION_SPECIFICATION.csv
*/
DO $m212_r8_220a_dynamic$
DECLARE v_run bigint; v_count bigint; v_last bigint; v_called boolean;
BEGIN
 SELECT module1_run_id INTO STRICT v_run FROM tmp_recover_m2_12_220a_context_base;
 IF to_regclass('msbf_ctl.m2_12_policy_profile') IS NOT NULL THEN EXECUTE 'SELECT count(*) FROM msbf_ctl.m2_12_policy_profile WHERE module1_run_id=$1' INTO v_count USING v_run; UPDATE tmp_recover_m2_12_220a_context_base SET policy_rows=v_count; END IF;
 v_count:=0;
 IF to_regclass('msbf_m2.module2_stage_certification_snapshot') IS NOT NULL THEN EXECUTE 'SELECT count(*) FROM msbf_m2.module2_stage_certification_snapshot WHERE module1_run_id=$1' INTO v_count USING v_run; END IF;
 IF to_regclass('msbf_m2.module2_contract_component_snapshot') IS NOT NULL THEN EXECUTE 'SELECT $1+count(*) FROM msbf_m2.module2_contract_component_snapshot WHERE module1_run_id=$2' INTO v_count USING v_count,v_run; END IF;
 IF to_regclass('msbf_m2.module2_evidence_certification_snapshot') IS NOT NULL THEN EXECUTE 'SELECT $1+count(*) FROM msbf_m2.module2_evidence_certification_snapshot WHERE module1_run_id=$2' INTO v_count USING v_count,v_run; END IF;
 IF to_regclass('msbf_m2.module2_contract_reproduction_snapshot') IS NOT NULL THEN EXECUTE 'SELECT $1+count(*) FROM msbf_m2.module2_contract_reproduction_snapshot WHERE module1_run_id=$2' INTO v_count USING v_count,v_run; END IF;
 IF to_regclass('msbf_m2.module2_capability_coverage_snapshot') IS NOT NULL THEN EXECUTE 'SELECT $1+count(*) FROM msbf_m2.module2_capability_coverage_snapshot WHERE module1_run_id=$2' INTO v_count USING v_count,v_run; END IF;
 IF to_regclass('msbf_ctl.m2_12_g3_bundle_latest') IS NOT NULL THEN EXECUTE 'SELECT $1+count(*) FROM msbf_ctl.m2_12_g3_bundle_latest WHERE module1_run_id=$2' INTO v_count USING v_count,v_run; END IF;
 IF to_regclass('msbf_ctl.m2_12_g3_bundle_archive') IS NOT NULL THEN EXECUTE 'SELECT $1+count(*) FROM msbf_ctl.m2_12_g3_bundle_archive WHERE module1_run_id=$2' INTO v_count USING v_count,v_run; END IF;
 IF to_regclass('msbf_ctl.m2_12_g3_bundle_registry') IS NOT NULL THEN EXECUTE 'SELECT $1+count(*) FROM msbf_ctl.m2_12_g3_bundle_registry WHERE module1_run_id=$2' INTO v_count USING v_count,v_run; END IF;
 UPDATE tmp_recover_m2_12_220a_context_base SET nonpolicy_rows=v_count;
 IF to_regclass('msbf_ctl.m2_12_policy_profile_policy_profile_id_seq') IS NOT NULL THEN EXECUTE 'SELECT last_value,is_called FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq' INTO v_last,v_called; UPDATE tmp_recover_m2_12_220a_context_base SET policy_sequence_last_value=v_last,policy_sequence_is_called=v_called; END IF;
 IF to_regclass('msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq') IS NOT NULL THEN EXECUTE 'SELECT last_value,is_called FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq' INTO v_last,v_called; UPDATE tmp_recover_m2_12_220a_context_base SET archive_sequence_last_value=v_last,archive_sequence_is_called=v_called; END IF;
 IF to_regclass('msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq') IS NOT NULL THEN EXECUTE 'SELECT last_value,is_called FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq' INTO v_last,v_called; UPDATE tmp_recover_m2_12_220a_context_base SET registry_sequence_last_value=v_last,registry_sequence_is_called=v_called; END IF;
END;
$m212_r8_220a_dynamic$;

/* R10 GOVERNED STATEMENT 0008 OF 0022
   statement_code: CREATE_TMP_RECOVER_M2_12_220A_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_220a_context ON COMMIT DROP AS
SELECT b.module1_run_id::bigint AS module1_run_id,
 CASE
  WHEN b.run_status='M2_11_ACCEPTED' AND b.policy_rows=0 AND b.nonpolicy_rows=0 AND b.evidence_rows=0 AND b.gate_rows=0
   AND (b.installed_table_count+b.installed_view_count+b.installed_function_count+b.installed_trigger_count+b.installed_index_count+b.installed_sequence_count)=0
   THEN 'NO_ACTION_PRISTINE'
  WHEN b.run_status='M2_11_ACCEPTED' AND b.policy_rows=0 AND b.nonpolicy_rows=0 AND b.evidence_rows=0 AND b.gate_rows=0
   AND (b.installed_table_count+b.installed_view_count+b.installed_function_count+b.installed_trigger_count+b.installed_index_count+b.installed_sequence_count)>0
   THEN 'RECOVER_FAILED_INSTALL'
  ELSE 'REFUSE_COMMITTED_OR_AMBIGUOUS' END::text AS recovery_decision_code,
 (b.run_status='M2_11_ACCEPTED' AND b.policy_rows=0 AND b.nonpolicy_rows=0 AND b.evidence_rows=0 AND b.gate_rows=0)::boolean AS recovery_permitted_flag
FROM tmp_recover_m2_12_220a_context_base b;

/* R10 GOVERNED STATEMENT 0009 OF 0022
   statement_code: ASSERT_TMP_RECOVER_M2_12_220A_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r8_220a_context$
BEGIN
 IF (SELECT count(*) FROM tmp_recover_m2_12_220a_context)<>1 OR NOT (SELECT recovery_permitted_flag FROM tmp_recover_m2_12_220a_context) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 220A recovery context refused by exact catalog/dynamic state';
 END IF;
END;
$m212_r8_220a_context$;

/* R10 GOVERNED STATEMENT 0010 OF 0022
   statement_code: INDEX_TMP_RECOVER_M2_12_220A_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_tmp_recover_m2_12_220a_context ON tmp_recover_m2_12_220a_context(module1_run_id);

/* R10 GOVERNED STATEMENT 0011 OF 0022
   statement_code: ANALYZE_TMP_RECOVER_M2_12_220A_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_220a_context;

/* R10 GOVERNED STATEMENT 0012 OF 0022
   statement_code: RECOVERY_DISPATCH
   phase_code: 02_DISPATCH
   statement_type: RECOVERY_DECISION
   source_authority: M2_12_RECOVERY_DECISION_DISPATCH_COMPILER.csv
*/
DO $m212_r8_220a_dispatch$
DECLARE v_decision text;
BEGIN
 SELECT recovery_decision_code INTO STRICT v_decision FROM tmp_recover_m2_12_220a_context;
 IF v_decision='NO_ACTION_PRISTINE' THEN NULL;
 ELSIF v_decision='RECOVER_FAILED_INSTALL' THEN
  EXECUTE 'DROP VIEW IF EXISTS msbf_m2.v_m2_12_power_bi_enterprise_portfolio';
  EXECUTE 'DROP VIEW IF EXISTS msbf_ctl.v_m2_12_g3_lineage';
  EXECUTE 'DROP VIEW IF EXISTS msbf_ctl.v_m2_12_component_contract_lineage';
  EXECUTE 'DROP VIEW IF EXISTS msbf_ctl.v_m2_12_stage_lineage';
  EXECUTE 'DROP VIEW IF EXISTS msbf_m2.v_m2_12_strategy_scope_consumption';
  EXECUTE 'DROP VIEW IF EXISTS msbf_m2.v_m2_12_operational_account_consumption';
  EXECUTE 'DROP VIEW IF EXISTS msbf_m2.v_m2_12_application_origination_consumption';
  IF to_regclass('msbf_ctl.m2_12_g3_bundle_archive') IS NOT NULL THEN EXECUTE 'DROP TRIGGER IF EXISTS trg_m2_12_g3_archive_immutable ON msbf_ctl.m2_12_g3_bundle_archive'; END IF;
  EXECUTE 'DROP TABLE IF EXISTS msbf_ctl.m2_12_g3_bundle_registry';
  EXECUTE 'DROP TABLE IF EXISTS msbf_ctl.m2_12_g3_bundle_archive';
  EXECUTE 'DROP TABLE IF EXISTS msbf_ctl.m2_12_g3_bundle_latest';
  EXECUTE 'DROP TABLE IF EXISTS msbf_m2.module2_capability_coverage_snapshot';
  EXECUTE 'DROP TABLE IF EXISTS msbf_m2.module2_contract_reproduction_snapshot';
  EXECUTE 'DROP TABLE IF EXISTS msbf_m2.module2_evidence_certification_snapshot';
  EXECUTE 'DROP TABLE IF EXISTS msbf_m2.module2_contract_component_snapshot';
  EXECUTE 'DROP TABLE IF EXISTS msbf_m2.module2_stage_certification_snapshot';
  EXECUTE 'DROP TABLE IF EXISTS msbf_ctl.m2_12_policy_profile';
  EXECUTE 'DROP FUNCTION IF EXISTS msbf_ctl.m2_12_reject_g3_archive_mutation()';
 ELSE
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 220A recovery refused: ambiguous state';
 END IF;
END;
$m212_r8_220a_dispatch$;

/* R10 GOVERNED STATEMENT 0013 OF 0022
   statement_code: CREATE_TMP_RECOVER_M2_12_220A_POSTCONDITION
   phase_code: 03_POSTCONDITION
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_220a_postcondition ON COMMIT DROP AS
SELECT obs.module1_run_id::bigint AS module1_run_id,
 (SELECT count(*)::integer FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('msbf_ctl','msbf_m2') AND c.relkind='r' AND c.relname IN ('m2_12_policy_profile','module2_stage_certification_snapshot','module2_contract_component_snapshot','module2_evidence_certification_snapshot','module2_contract_reproduction_snapshot','module2_capability_coverage_snapshot','m2_12_g3_bundle_latest','m2_12_g3_bundle_archive','m2_12_g3_bundle_registry')) AS remaining_tables,
 (SELECT count(*)::integer FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('msbf_ctl','msbf_m2') AND c.relkind='v' AND c.relname IN ('v_m2_12_application_origination_consumption','v_m2_12_operational_account_consumption','v_m2_12_strategy_scope_consumption','v_m2_12_stage_lineage','v_m2_12_component_contract_lineage','v_m2_12_g3_lineage','v_m2_12_power_bi_enterprise_portfolio')) AS remaining_views,
 (SELECT count(*)::integer FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='msbf_ctl' AND p.proname='m2_12_reject_g3_archive_mutation') AS remaining_functions,
 (SELECT count(*)::integer FROM pg_catalog.pg_trigger t WHERE NOT t.tgisinternal AND t.tgname='trg_m2_12_g3_archive_immutable') AS remaining_triggers,
 (SELECT count(*)::integer FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('msbf_ctl','msbf_m2') AND c.relkind='i' AND c.relname IN ('ix_m212_archive_contract','ix_m212_latest_contract','ix_m212_registry_status','ix_m212_capability_status','ix_m212_component_status','ix_m212_reproduction_status','ix_m212_evidence_family','ix_m212_stage_status')) AS remaining_indexes,
 (SELECT count(*)::integer FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='msbf_ctl' AND c.relkind='S' AND c.relname IN ('m2_12_policy_profile_policy_profile_id_seq','m2_12_g3_bundle_archive_archive_id_seq','m2_12_g3_bundle_registry_registry_id_seq')) AS remaining_sequences,
 (SELECT count(*)::bigint FROM msbf_ctl.run_evidence e WHERE e.run_id=obs.module1_run_id AND e.evidence_code LIKE 'M2_12_%') AS remaining_evidence_rows,
 (SELECT count(*)::bigint FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=obs.module1_run_id AND g.gate_id='G3_M2_CONTRACT') AS remaining_gate_rows,
 CASE WHEN (SELECT count(*) FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('msbf_ctl','msbf_m2') AND c.relname LIKE '%m2_12%')=0
 AND (SELECT count(*) FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='msbf_ctl' AND p.proname='m2_12_reject_g3_archive_mutation')=0
 AND (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=obs.module1_run_id AND e.evidence_code LIKE 'M2_12_%')=0
 AND (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=obs.module1_run_id AND g.gate_id='G3_M2_CONTRACT')=0 THEN 'PASS' ELSE 'FAIL' END::text AS pristine_status
FROM tmp_recover_m2_12_220a_context_base obs;

/* R10 GOVERNED STATEMENT 0014 OF 0022
   statement_code: ASSERT_TMP_RECOVER_M2_12_220A_POSTCONDITION
   phase_code: 03_POSTCONDITION
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r8_220a_post$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_220a_postcondition)<>1 OR NOT (SELECT pristine_status='PASS' FROM tmp_recover_m2_12_220a_postcondition) THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 220A complete pristine-object postcondition failed'; END IF; END; $m212_r8_220a_post$;

/* R10 GOVERNED STATEMENT 0015 OF 0022
   statement_code: INDEX_TMP_RECOVER_M2_12_220A_POSTCONDITION
   phase_code: 03_POSTCONDITION
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_tmp_recover_m2_12_220a_postcondition ON tmp_recover_m2_12_220a_postcondition(module1_run_id);

/* R10 GOVERNED STATEMENT 0016 OF 0022
   statement_code: ANALYZE_TMP_RECOVER_M2_12_220A_POSTCONDITION
   phase_code: 03_POSTCONDITION
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_220a_postcondition;

/* R10 GOVERNED STATEMENT 0017 OF 0022
   statement_code: CREATE_TMP_RECOVER_M2_12_220A_RESULT
   phase_code: 04_RESULT_STATE
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_220a_result ON COMMIT DROP AS
SELECT '220A'::text AS recovery_program,c.recovery_decision_code::text AS recovery_decision_code,
 CASE WHEN p.pristine_status='PASS' THEN 'PASS' ELSE 'FAIL' END::text AS recovery_status,
 'NOT_PRESENT'::text AS policy_sequence_state,'NOT_PRESENT'::text AS archive_sequence_state,'NOT_PRESENT'::text AS registry_sequence_state,
 CASE WHEN p.pristine_status='PASS' THEN 'PROGRAM_220_PRISTINE' ELSE 'RECOVERY_POSTCONDITION_FAILED' END::text AS disposition
FROM tmp_recover_m2_12_220a_context c CROSS JOIN tmp_recover_m2_12_220a_postcondition p;

/* R10 GOVERNED STATEMENT 0018 OF 0022
   statement_code: ASSERT_TMP_RECOVER_M2_12_220A_RESULT
   phase_code: 04_RESULT_STATE
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r8_220a_result$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_220a_result)<>1 THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 220A result row mismatch'; END IF; END; $m212_r8_220a_result$;

/* R10 GOVERNED STATEMENT 0019 OF 0022
   statement_code: INDEX_TMP_RECOVER_M2_12_220A_RESULT
   phase_code: 04_RESULT_STATE
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_tmp_recover_m2_12_220a_result ON tmp_recover_m2_12_220a_result(recovery_program);

/* R10 GOVERNED STATEMENT 0020 OF 0022
   statement_code: ANALYZE_TMP_RECOVER_M2_12_220A_RESULT
   phase_code: 04_RESULT_STATE
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_220a_result;

/* R10 GOVERNED STATEMENT 0021 OF 0022
   statement_code: PRIMARY_RESULT
   phase_code: 05_RESULT
   statement_type: RESULT_SELECT
   source_authority: M2_12_PROGRAM_PRIMARY_RESULT_STATEMENT_COMPILER.csv
*/
SELECT recovery_program,recovery_decision_code,recovery_status,policy_sequence_state,archive_sequence_state,registry_sequence_state,disposition FROM tmp_recover_m2_12_220a_result;

/* R10 GOVERNED STATEMENT 0022 OF 0022
   statement_code: COMMIT
   phase_code: 06_COMMIT
   statement_type: TRANSACTION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
COMMIT;

