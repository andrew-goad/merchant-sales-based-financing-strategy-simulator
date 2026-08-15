/***************************************************************************************************
M2.12 — ENTERPRISE PORTFOLIO CERTIFICATION & CONSUMPTION CONTRACT
PROGRAM 222B — Committed Certification Checkpoint Reconstruction

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
/* R10 GOVERNED STATEMENT 0001 OF 0034
   statement_code: BEGIN
   phase_code: 00_TRANSACTION
   statement_type: TRANSACTION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
BEGIN;

/* R10 GOVERNED STATEMENT 0002 OF 0034
   statement_code: SEARCH_PATH
   phase_code: 00_TRANSACTION
   statement_type: SESSION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
SET LOCAL search_path = msbf_ctl, msbf_m2, msbf_ref, public;

/* R10 GOVERNED STATEMENT 0003 OF 0034
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

/* R10 GOVERNED STATEMENT 0004 OF 0034
   statement_code: ASSERT_TMP_RECOVER_M2_12_GOVERNED_SCOPE
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_recover_m2_12_governed_scope$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_governed_scope) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_recover_m2_12_governed_scope', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_recover_m2_12_governed_scope)::text; END IF; END; $m212_r7_tmp_recover_m2_12_governed_scope$;

/* R10 GOVERNED STATEMENT 0005 OF 0034
   statement_code: INDEX_TMP_RECOVER_M2_12_GOVERNED_SCOPE
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_recover_m2_12_governed_scope_4f110475 ON tmp_recover_m2_12_governed_scope (module1_run_id);

/* R10 GOVERNED STATEMENT 0006 OF 0034
   statement_code: ANALYZE_TMP_RECOVER_M2_12_GOVERNED_SCOPE
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_governed_scope;

/* R10 GOVERNED STATEMENT 0007 OF 0034
   statement_code: CREATE_TMP_RECOVER_M2_12_222B_RUN_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_222b_run_context ON COMMIT DROP AS
SELECT rr.run_id::bigint AS module1_run_id, rr.run_code::text AS run_code,
       rr.run_version::integer AS run_version, rr.run_status::text AS run_status,
       rr.as_of_date::date AS as_of_date,
       m211.contract_set_hash::text AS accepted_m2_11_contract_set_hash,
       m211.combined_set_hash::text AS accepted_m2_11_combined_set_hash,
       m211.row_hash::text AS accepted_m2_11_registry_row_hash
FROM msbf_ctl.run_registry rr
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry m211
  ON m211.module1_run_id=rr.run_id
 AND m211.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
 AND m211.contract_version=1 AND m211.contract_status='ACCEPTED'
WHERE rr.run_code='M1_V0_2_BASELINE_BUILD' AND rr.run_version=1 AND rr.run_status IN ('M2_11_ACCEPTED','M2_12_GENERATED');

/* R10 GOVERNED STATEMENT 0008 OF 0034
   statement_code: ASSERT_TMP_RECOVER_M2_12_222B_RUN_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_recover_m2_12_222b_run_context$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_222b_run_context) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_recover_m2_12_222b_run_context', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_recover_m2_12_222b_run_context)::text; END IF; END; $m212_r7_tmp_recover_m2_12_222b_run_context$;

/* R10 GOVERNED STATEMENT 0009 OF 0034
   statement_code: INDEX_TMP_RECOVER_M2_12_222B_RUN_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_recover_m2_12_222b_run_context_3dbab3d5 ON tmp_recover_m2_12_222b_run_context (module1_run_id);

/* R10 GOVERNED STATEMENT 0010 OF 0034
   statement_code: ANALYZE_TMP_RECOVER_M2_12_222B_RUN_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_222b_run_context;

/* R10 GOVERNED STATEMENT 0011 OF 0034
   statement_code: CREATE_TMP_RECOVER_M2_12_222B_PHASE9_PROOF
   phase_code: 01_CONTEXT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_222b_phase9_proof ON COMMIT DROP AS
WITH row_detail AS ((SELECT 'POLICY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, 12::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>12)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, 72::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>72)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, 20::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>20)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'LATEST'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.archive_row_hash IS DISTINCT FROM md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'REGISTRY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'registry_id'-'contract_status'-'generated_at'-'validated_at'-'accepted_at'-'created_at'-'updated_at'-'row_hash'-'policy_set_hash'-'stage_certification_set_hash'-'contract_component_set_hash'-'evidence_certification_set_hash'-'contract_reproduction_set_hash'-'capability_coverage_set_hash'-'latest_set_hash'-'archive_set_hash'-'registry_set_hash'-'contract_set_hash'-'combined_set_hash')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id)),
rowd AS (SELECT sum(family_count_mismatch_count)::bigint family_count_mismatch_count,sum(row_hash_mismatch_count)::bigint row_hash_mismatch_count FROM row_detail),
set_detail AS ((SELECT 'POLICY'::text AS family_code, md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version))::text AS reconstructed_set_hash, r.policy_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version)) IS DISTINCT FROM r.policy_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.policy_set_hash) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code))::text AS reconstructed_set_hash, r.stage_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code)) IS DISTINCT FROM r.stage_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.stage_certification_set_hash) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_component_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_component_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_component_set_hash) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.evidence_family_code::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence, t.evidence_family_code))::text AS reconstructed_set_hash, r.evidence_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.evidence_family_code::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence, t.evidence_family_code)) IS DISTINCT FROM r.evidence_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.evidence_certification_set_hash) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_reproduction_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_reproduction_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_reproduction_set_hash) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code))::text AS reconstructed_set_hash, r.capability_coverage_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code)) IS DISTINCT FROM r.capability_coverage_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.capability_coverage_set_hash) UNION ALL (SELECT 'LATEST'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.latest_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.latest_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.latest_set_hash) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.archive_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.archive_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.archive_set_hash) UNION ALL (SELECT 'REGISTRY'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.registry_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.registry_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.registry_set_hash)),
setd AS (SELECT sum(set_hash_mismatch_count)::bigint set_hash_mismatch_count FROM set_detail),
ch AS (SELECT r.module1_run_id,
       md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text))::text AS reconstructed_contract_set_hash,
       r.contract_set_hash::text AS stored_contract_set_hash,
       (md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text)) IS DISTINCT FROM r.contract_set_hash)::integer AS contract_hash_mismatch_count
FROM msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1), cb AS (SELECT u.module1_run_id, count(*)::integer AS canonical_entities, count(DISTINCT u.entity_type)::integer AS canonical_families, md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key))::text AS reconstructed_combined_set_hash, r.combined_set_hash::text AS stored_combined_set_hash, (md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key)) IS DISTINCT FROM r.combined_set_hash)::integer AS combined_hash_mismatch_count FROM (SELECT t.module1_run_id, 'POLICY'::text AS entity_type, concat_ws('|',t.policy_code::text,t.policy_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'STAGE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.certification_node_sequence::text,t.stage_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_COMPONENT'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'EVIDENCE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.evidence_family_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_REPRODUCTION'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CAPABILITY_COVERAGE'::text AS entity_type, concat_ws('|',t.capability_sequence::text,t.capability_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'LATEST'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'ARCHIVE'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.archive_row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'REGISTRY'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=t.module1_run_id) u JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=u.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY u.module1_run_id,r.combined_set_hash), seq AS (SELECT ctx.module1_run_id,
       p.last_value::bigint AS policy_last_value,p.is_called AS policy_is_called,
       a.last_value::bigint AS archive_last_value,a.is_called AS archive_is_called,
       r.last_value::bigint AS registry_last_value,r.is_called AS registry_is_called,
       ((p.last_value<>1 OR NOT p.is_called)::integer
        +(a.last_value<>1 OR NOT a.is_called)::integer
        +(r.last_value<>1 OR NOT r.is_called)::integer)::integer AS sequence_state_mismatch_count
FROM tmp_recover_m2_12_222b_run_context ctx
CROSS JOIN msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r)
SELECT ctx.module1_run_id,
       rowd.family_count_mismatch_count,rowd.row_hash_mismatch_count,setd.set_hash_mismatch_count,
       ch.contract_hash_mismatch_count::integer,cb.combined_hash_mismatch_count::integer,
       seq.sequence_state_mismatch_count::integer,cb.canonical_families::integer,cb.canonical_entities::integer,
       (rowd.family_count_mismatch_count+rowd.row_hash_mismatch_count+setd.set_hash_mismatch_count+ch.contract_hash_mismatch_count+cb.combined_hash_mismatch_count+seq.sequence_state_mismatch_count)::bigint AS total_mismatch_count
FROM tmp_recover_m2_12_222b_run_context ctx CROSS JOIN rowd CROSS JOIN setd CROSS JOIN ch CROSS JOIN cb CROSS JOIN seq;

/* R10 GOVERNED STATEMENT 0012 OF 0034
   statement_code: ASSERT_TMP_RECOVER_M2_12_222B_PHASE9_PROOF
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_recover_m2_12_222b_phase9_proof$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_222b_phase9_proof) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_recover_m2_12_222b_phase9_proof', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_recover_m2_12_222b_phase9_proof)::text; END IF; END; $m212_r7_tmp_recover_m2_12_222b_phase9_proof$;

/* R10 GOVERNED STATEMENT 0013 OF 0034
   statement_code: INDEX_TMP_RECOVER_M2_12_222B_PHASE9_PROOF
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_recover_m2_12_222b_phase9_proof_ee472831 ON tmp_recover_m2_12_222b_phase9_proof (module1_run_id);

/* R10 GOVERNED STATEMENT 0014 OF 0034
   statement_code: ANALYZE_TMP_RECOVER_M2_12_222B_PHASE9_PROOF
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_222b_phase9_proof;

/* R10 GOVERNED STATEMENT 0015 OF 0034
   statement_code: CREATE_TMP_RECOVER_M2_12_222B_SOURCE_EDGE_PHYSICAL
   phase_code: 01_CONTEXT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_222b_source_edge_physical ON COMMIT DROP AS
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       1::smallint AS edge_sequence,
       'M1_15_TO_M1_17_APPLICATION_CONTRACT'::text AS edge_code,
       'M1_17_G2_FOUNDATION'::text AS target_node_code,
       'fcd2704e17ec0d2e73191ea36061d74b'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m1_15_consumption_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_15_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_15_CONSUMPTION_CONTRACT' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m1_15_consumption_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_15_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       2::smallint AS edge_sequence,
       'M1_16_TO_M1_17_ACQUISITION_CONTRACT'::text AS edge_code,
       'M1_17_G2_FOUNDATION'::text AS target_node_code,
       '86df51a0ca68d84096d00ff0f1b19f33'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m1_16_acquisition_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_16_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m1_16_acquisition_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_16_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       3::smallint AS edge_sequence,
       'M1_17_TO_M2_1'::text AS edge_code,
       'M2_1_ELIGIBILITY_ROUTING'::text AS target_node_code,
       '7d9e466da28cad2551aa99c4c40c912b'::text AS expected_source_hash,
       ((SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_g2_combined_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='G2_M1_CONTRACT' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_g2_combined_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       4::smallint AS edge_sequence,
       'M2_1_TO_M2_2'::text AS edge_code,
       'M2_2_PRICING_STRUCTURE'::text AS target_node_code,
       'e5ace7f32060ffb191c7bd0f8dd0c863'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_1_combined_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_1_combined_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       5::smallint AS edge_sequence,
       'M1_3_TO_M2_2_REQUEST_AUTHORITY'::text AS edge_code,
       'M2_2_PRICING_STRUCTURE'::text AS target_node_code,
       '01485256b9b5748fb412743d35ced602'::text AS expected_source_hash,
       ((SELECT agr.observed_value::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_3_APPLICATION_REQUEST' AND agr.review_version=2 AND agr.result_status='PASS'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_3_application_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_3_APPLICATION_REQUEST' AND agr.review_version=2))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT agr.observed_value::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_3_APPLICATION_REQUEST' AND agr.review_version=2 AND agr.result_status='PASS') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_3_application_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       6::smallint AS edge_sequence,
       'M2_2_TO_M2_3'::text AS edge_code,
       'M2_3_FINAL_DECISION'::text AS target_node_code,
       'bbe83b187b31ea561789797322031fc6'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       7::smallint AS edge_sequence,
       'M2_3_TO_M2_4'::text AS edge_code,
       'M2_4_PORTFOLIO_ACTIVATION'::text AS target_node_code,
       'bf09349b06ede7e5a2ec830c2f9ffe90'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_3_combined_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_3_combined_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       8::smallint AS edge_sequence,
       'M2_4_TO_M2_5'::text AS edge_code,
       'M2_5_DAILY_MONITORING'::text AS target_node_code,
       '117450a3eea7bb3d3c74d18cc3c8e96a'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       9::smallint AS edge_sequence,
       'M1_6_TO_M2_5_SCENARIO_AUTHORITY'::text AS edge_code,
       'M2_5_DAILY_MONITORING'::text AS target_node_code,
       '3f85921bf6fc30ddc6cee146085e58c5'::text AS expected_source_hash,
       ((SELECT (agr.observed_value::jsonb->>'combined_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND agr.review_version=1 AND agr.result_status='PASS'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_6_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT (agr.observed_value::jsonb->>'combined_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND agr.review_version=1 AND agr.result_status='PASS') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_6_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       10::smallint AS edge_sequence,
       'M2_5_TO_M2_6'::text AS edge_code,
       'M2_6_INTERVENTION_STRATEGY'::text AS target_node_code,
       '18e1c444aa1b02ee5bd3539d7c477adc'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_5_combined_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_5_combined_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       11::smallint AS edge_sequence,
       'M2_6_TO_M2_7'::text AS edge_code,
       'M2_7_OPERATIONAL_ACTIVATION'::text AS target_node_code,
       '868125bff29270490cab4d2e55cb1388'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       12::smallint AS edge_sequence,
       'M2_7_TO_M2_8'::text AS edge_code,
       'M2_8_SERVICING_EXECUTION'::text AS target_node_code,
       'c8e3a472afd2a16b1183677324e9db98'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       13::smallint AS edge_sequence,
       'M2_8_TO_M2_9'::text AS edge_code,
       'M2_9_RECONCILIATION_CERTIFICATION'::text AS target_node_code,
       'ab32d80ba20c2c8f0a6ec9ec97c2ed26'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       14::smallint AS edge_sequence,
       'M2_9_TO_M2_10'::text AS edge_code,
       'M2_10_PORTFOLIO_ANALYTICS'::text AS target_node_code,
       '6af76d0059b47623619ebc09330b15fe'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       15::smallint AS edge_sequence,
       'M1_17_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       '7d9e466da28cad2551aa99c4c40c912b'::text AS expected_source_hash,
       ((SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_17_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='G2_M1_CONTRACT' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_17_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       16::smallint AS edge_sequence,
       'M2_2_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       'bbe83b187b31ea561789797322031fc6'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       17::smallint AS edge_sequence,
       'M2_4_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       '117450a3eea7bb3d3c74d18cc3c8e96a'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       18::smallint AS edge_sequence,
       'M2_7_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       'c8e3a472afd2a16b1183677324e9db98'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_7_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_7_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       19::smallint AS edge_sequence,
       'M2_10_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       '24fca7263a04397ebf21d30639f9069b'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_10_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_10_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_recover_m2_12_222b_run_context ctx
) x);

/* R10 GOVERNED STATEMENT 0016 OF 0034
   statement_code: ASSERT_TMP_RECOVER_M2_12_222B_SOURCE_EDGE_PHYSICAL
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_recover_m2_12_222b_source_edge_physi$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_222b_source_edge_physical) <> 19 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_recover_m2_12_222b_source_edge_physical', DETAIL='expected=19 observed='||(SELECT count(*) FROM tmp_recover_m2_12_222b_source_edge_physical)::text; END IF; END; $m212_r7_tmp_recover_m2_12_222b_source_edge_physi$;

/* R10 GOVERNED STATEMENT 0017 OF 0034
   statement_code: INDEX_TMP_RECOVER_M2_12_222B_SOURCE_EDGE_PHYSICAL
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_recover_m2_12_222b_source_edge_physical_995edd54 ON tmp_recover_m2_12_222b_source_edge_physical (module1_run_id, edge_sequence, edge_code);

/* R10 GOVERNED STATEMENT 0018 OF 0034
   statement_code: ANALYZE_TMP_RECOVER_M2_12_222B_SOURCE_EDGE_PHYSICAL
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_222b_source_edge_physical;

/* R10 GOVERNED STATEMENT 0019 OF 0034
   statement_code: CREATE_TMP_RECOVER_M2_12_222B_EVIDENCE
   phase_code: 01_CONTEXT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_222b_evidence ON COMMIT DROP AS
WITH observed AS (
SELECT 1::smallint AS evidence_sequence,'M2_12_POLICY_SET_HASH'::text AS evidence_code,(((SELECT policy_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed policy set hash'::text AS expected_value,'HASH'::text AS unit_code,'Approved policy identity.'::text AS interpretation,CASE WHEN ((((SELECT policy_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_recover_m2_12_222b_phase9_proof)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 2::smallint AS evidence_sequence,'M2_12_STAGE_CERTIFICATION_SET_HASH'::text AS evidence_code,(((SELECT stage_certification_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'Twelve source-node certification rows.'::text AS interpretation,CASE WHEN ((((SELECT stage_certification_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_recover_m2_12_222b_phase9_proof)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 3::smallint AS evidence_sequence,'M2_12_CONTRACT_COMPONENT_SET_HASH'::text AS evidence_code,(((SELECT contract_component_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'Thirteen component contracts.'::text AS interpretation,CASE WHEN ((((SELECT contract_component_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_recover_m2_12_222b_phase9_proof)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 4::smallint AS evidence_sequence,'M2_12_EVIDENCE_CERTIFICATION_SET_HASH'::text AS evidence_code,(((SELECT evidence_certification_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'Seventy-two mandatory PASS evidence certifications.'::text AS interpretation,CASE WHEN ((((SELECT evidence_certification_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_recover_m2_12_222b_phase9_proof)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 5::smallint AS evidence_sequence,'M2_12_CONTRACT_REPRODUCTION_SET_HASH'::text AS evidence_code,(((SELECT contract_reproduction_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'Thirteen exact latest/archive reproductions.'::text AS interpretation,CASE WHEN ((((SELECT contract_reproduction_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_recover_m2_12_222b_phase9_proof)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 6::smallint AS evidence_sequence,'M2_12_CAPABILITY_COVERAGE_SET_HASH'::text AS evidence_code,(((SELECT capability_coverage_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'Twenty as-built/deferred/prohibited capability rows.'::text AS interpretation,CASE WHEN ((((SELECT capability_coverage_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_recover_m2_12_222b_phase9_proof)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 7::smallint AS evidence_sequence,'M2_12_LATEST_SET_HASH'::text AS evidence_code,(((SELECT latest_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'One G3 latest row.'::text AS interpretation,CASE WHEN ((((SELECT latest_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_recover_m2_12_222b_phase9_proof)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 8::smallint AS evidence_sequence,'M2_12_ARCHIVE_SET_HASH'::text AS evidence_code,(((SELECT archive_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'One immutable G3 archive row.'::text AS interpretation,CASE WHEN ((((SELECT archive_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_recover_m2_12_222b_phase9_proof)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 9::smallint AS evidence_sequence,'M2_12_REGISTRY_SET_HASH'::text AS evidence_code,(((SELECT registry_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'One registry row and the ninth canonical-family set hash.'::text AS interpretation,CASE WHEN ((((SELECT registry_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_recover_m2_12_222b_phase9_proof)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 10::smallint AS evidence_sequence,'M2_12_CONTRACT_SET_HASH'::text AS evidence_code,(((SELECT contract_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals registry and physical reconstruction'::text AS expected_value,'HASH'::text AS unit_code,'Acyclic contract identity over finalized component identities.'::text AS interpretation,CASE WHEN ((((SELECT contract_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_recover_m2_12_222b_phase9_proof)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 11::smallint AS evidence_sequence,'M2_12_COMBINED_SET_HASH'::text AS evidence_code,(((SELECT combined_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals registry and independent reconstruction'::text AS expected_value,'HASH'::text AS unit_code,'Final deterministic M2.12 combined identity.'::text AS interpretation,CASE WHEN ((((SELECT combined_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_recover_m2_12_222b_phase9_proof)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 12::smallint AS evidence_sequence,'M2_12_STAGE_CERTIFICATION_ROWS'::text AS evidence_code,(((SELECT count(*)::text FROM msbf_m2.module2_stage_certification_snapshot s JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text)::text AS observed_value,'12'::text AS expected_value,'ROWS'::text AS unit_code,'One row for each of 12 source-certification nodes.'::text AS interpretation,CASE WHEN ((((SELECT count(*)::text FROM msbf_m2.module2_stage_certification_snapshot s JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text) IS NOT DISTINCT FROM '12'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 13::smallint AS evidence_sequence,'M2_12_CONTRACT_COMPONENT_ROWS'::text AS evidence_code,(((SELECT count(*)::text FROM msbf_m2.module2_contract_component_snapshot s JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text)::text AS observed_value,'13'::text AS expected_value,'ROWS'::text AS unit_code,'One row for each component contract, including two M2.2 contracts.'::text AS interpretation,CASE WHEN ((((SELECT count(*)::text FROM msbf_m2.module2_contract_component_snapshot s JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text) IS NOT DISTINCT FROM '13'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 14::smallint AS evidence_sequence,'M2_12_EVIDENCE_CERTIFICATION_ROWS'::text AS evidence_code,(((SELECT count(*)||'|'||count(*) FILTER (WHERE certification_status='PASS')||' PASS|'||count(*) FILTER (WHERE certification_status<>'PASS')||' FAIL' FROM msbf_m2.module2_evidence_certification_snapshot s JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text)::text AS observed_value,'72|72 PASS|0 FAIL'::text AS expected_value,'ROWS'::text AS unit_code,'All six evidence families apply to all 12 nodes.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||count(*) FILTER (WHERE certification_status='PASS')||' PASS|'||count(*) FILTER (WHERE certification_status<>'PASS')||' FAIL' FROM msbf_m2.module2_evidence_certification_snapshot s JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text) IS NOT DISTINCT FROM '72|72 PASS|0 FAIL'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 15::smallint AS evidence_sequence,'M2_12_CONTRACT_REPRODUCTION_ROWS'::text AS evidence_code,(((SELECT count(*)||'|'||sum(payload_mismatch_count+missing_latest_rows+missing_archive_rows+latest_duplicate_key_rows+archive_duplicate_key_rows)||' mismatches' FROM msbf_m2.module2_contract_reproduction_snapshot s JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text)::text AS observed_value,'13|0 mismatches'::text AS expected_value,'ROWS'::text AS unit_code,'One successful reproduction row per component contract.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||sum(payload_mismatch_count+missing_latest_rows+missing_archive_rows+latest_duplicate_key_rows+archive_duplicate_key_rows)||' mismatches' FROM msbf_m2.module2_contract_reproduction_snapshot s JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text) IS NOT DISTINCT FROM '13|0 mismatches'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 16::smallint AS evidence_sequence,'M2_12_CAPABILITY_COVERAGE_ROWS'::text AS evidence_code,(((SELECT count(*)||'|'||count(*) FILTER (WHERE production_action_authorized_flag OR legal_or_regulatory_certified_flag)||' overclaims' FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text)::text AS observed_value,'20|0 overclaims'::text AS expected_value,'ROWS'::text AS unit_code,'Twenty as-built/deferred/prohibited capabilities without overclaim.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||count(*) FILTER (WHERE production_action_authorized_flag OR legal_or_regulatory_certified_flag)||' overclaims' FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text) IS NOT DISTINCT FROM '20|0 overclaims'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 17::smallint AS evidence_sequence,'M2_12_CANONICAL_ENTITIES'::text AS evidence_code,(((SELECT canonical_entities||'|'||canonical_families FROM tmp_recover_m2_12_222b_phase9_proof))::text)::text AS observed_value,'134|9'::text AS expected_value,'ROWS'::text AS unit_code,'Exactly 134 canonical entities across nine families.'::text AS interpretation,CASE WHEN ((((SELECT canonical_entities||'|'||canonical_families FROM tmp_recover_m2_12_222b_phase9_proof))::text) IS NOT DISTINCT FROM '134|9'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 18::smallint AS evidence_sequence,'M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL'::text AS evidence_code,(((SELECT sum(observed_latest_rows)||'|'||sum(observed_archive_rows) FROM msbf_m2.module2_contract_component_snapshot c WHERE c.module1_run_id=ctx.module1_run_id))::text)::text AS observed_value,'7129|7129'::text AS expected_value,'ROWS'::text AS unit_code,'Combined component latest/archive total; consolidates the former two evidence slots.'::text AS interpretation,CASE WHEN ((((SELECT sum(observed_latest_rows)||'|'||sum(observed_archive_rows) FROM msbf_m2.module2_contract_component_snapshot c WHERE c.module1_run_id=ctx.module1_run_id))::text) IS NOT DISTINCT FROM '7129|7129'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 19::smallint AS evidence_sequence,'M2_12_APPLICATION_CONSUMPTION_ROWS'::text AS evidence_code,(((SELECT count(*)||'|'||count(DISTINCT merchant_application_id)||'|'||count(*) FILTER (WHERE scenario_code='BASELINE')||'|'||count(*) FILTER (WHERE scenario_code='RECESSION_ENERGY') FROM msbf_m2.v_m2_12_application_origination_consumption v WHERE v.module1_run_id=ctx.module1_run_id))::text)::text AS observed_value,'1500|750|750|750'::text AS expected_value,'ROWS'::text AS unit_code,'Application view has exact scenario/application grain.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||count(DISTINCT merchant_application_id)||'|'||count(*) FILTER (WHERE scenario_code='BASELINE')||'|'||count(*) FILTER (WHERE scenario_code='RECESSION_ENERGY') FROM msbf_m2.v_m2_12_application_origination_consumption v WHERE v.module1_run_id=ctx.module1_run_id))::text) IS NOT DISTINCT FROM '1500|750|750|750'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 20::smallint AS evidence_sequence,'M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS'::text AS evidence_code,(((SELECT count(*)||'|'||count(DISTINCT merchant_application_id)||'|'||count(*) FILTER (WHERE scenario_code='BASELINE')||'|'||count(*) FILTER (WHERE scenario_code='RECESSION_ENERGY') FROM msbf_m2.v_m2_12_operational_account_consumption v WHERE v.module1_run_id=ctx.module1_run_id))::text)::text AS observed_value,'59|44|44|15'::text AS expected_value,'ROWS'::text AS unit_code,'Operational-account view has exact accepted account grain.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||count(DISTINCT merchant_application_id)||'|'||count(*) FILTER (WHERE scenario_code='BASELINE')||'|'||count(*) FILTER (WHERE scenario_code='RECESSION_ENERGY') FROM msbf_m2.v_m2_12_operational_account_consumption v WHERE v.module1_run_id=ctx.module1_run_id))::text) IS NOT DISTINCT FROM '59|44|44|15'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 21::smallint AS evidence_sequence,'M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS'::text AS evidence_code,(((SELECT count(*)||'|'||count(DISTINCT strategy_profile_code)||'|'||count(DISTINCT reporting_scope_code)||'|'||count(*) FILTER (WHERE governance_priority_code='PRIMARY_GOVERNANCE_REVIEW') FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=ctx.module1_run_id))::text)::text AS observed_value,'24|8|3|3'::text AS expected_value,'ROWS'::text AS unit_code,'Strategy-scope view preserves eight strategies and three scopes.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||count(DISTINCT strategy_profile_code)||'|'||count(DISTINCT reporting_scope_code)||'|'||count(*) FILTER (WHERE governance_priority_code='PRIMARY_GOVERNANCE_REVIEW') FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=ctx.module1_run_id))::text) IS NOT DISTINCT FROM '24|8|3|3'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 22::smallint AS evidence_sequence,'M2_12_SOURCE_GRAPH_EDGES'::text AS evidence_code,(((SELECT count(*)||'|'||count(*) FILTER (WHERE edge_status<>'PASS') FROM tmp_recover_m2_12_222b_source_edge_physical))::text)::text AS observed_value,'19|0'::text AS expected_value,'ROWS'::text AS unit_code,'Ten linear Module 2, two M1 auxiliary, two M1.17 component, and five M2.11 direct-source edges.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||count(*) FILTER (WHERE edge_status<>'PASS') FROM tmp_recover_m2_12_222b_source_edge_physical))::text) IS NOT DISTINCT FROM '19|0'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 23::smallint AS evidence_sequence,'M2_12_DETERMINISTIC_MISMATCHES'::text AS evidence_code,(((SELECT total_mismatch_count FROM tmp_recover_m2_12_222b_phase9_proof))::text)::text AS observed_value,'0'::text AS expected_value,'ROWS'::text AS unit_code,'No deterministic row, set, contract, or combined-hash mismatch.'::text AS interpretation,CASE WHEN ((((SELECT total_mismatch_count FROM tmp_recover_m2_12_222b_phase9_proof))::text) IS NOT DISTINCT FROM '0'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
UNION ALL
SELECT 24::smallint AS evidence_sequence,'M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS'::text AS evidence_code,(((SELECT count(*) FROM msbf_m2.module2_evidence_certification_snapshot s WHERE s.module1_run_id=ctx.module1_run_id AND s.certification_status<>'PASS'))::text)::text AS observed_value,'0'::text AS expected_value,'ROWS'::text AS unit_code,'No production action, capability overclaim, unauthorized source, premature Module 3 object, or stage-boundary finding.'::text AS interpretation,CASE WHEN ((((SELECT count(*) FROM msbf_m2.module2_evidence_certification_snapshot s WHERE s.module1_run_id=ctx.module1_run_id AND s.certification_status<>'PASS'))::text) IS NOT DISTINCT FROM '0'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_recover_m2_12_222b_run_context ctx
)
SELECT o.evidence_sequence::smallint AS evidence_sequence,ctx.module1_run_id::bigint AS run_id,o.evidence_code::text AS evidence_code,
 'M2_12'::text AS segment_key,o.evidence_code::text AS metric_name,NULL::numeric(24,10) AS metric_value_numeric,o.observed_value::text AS metric_value_text,
 o.unit_code::text AS unit_code,o.status::text AS status,NULL::numeric(24,10) AS threshold_value_numeric,o.interpretation::text AS interpretation
FROM observed o CROSS JOIN tmp_recover_m2_12_222b_run_context ctx;

/* R10 GOVERNED STATEMENT 0020 OF 0034
   statement_code: ASSERT_TMP_RECOVER_M2_12_222B_EVIDENCE
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r8_222b_evidence$
BEGIN
 IF (SELECT count(*) FROM tmp_recover_m2_12_222b_evidence)<>24
    OR (SELECT count(DISTINCT evidence_code) FROM tmp_recover_m2_12_222b_evidence)<>24
    OR EXISTS(SELECT 1 FROM tmp_recover_m2_12_222b_evidence WHERE status<>'PASS' OR num_nonnulls(metric_value_numeric,metric_value_text)<>1) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 222B expected evidence reconstruction failed';
 END IF;
END;
$m212_r8_222b_evidence$;

/* R10 GOVERNED STATEMENT 0021 OF 0034
   statement_code: INDEX_TMP_RECOVER_M2_12_222B_EVIDENCE
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_tmp_recover_m2_12_222b_evidence ON tmp_recover_m2_12_222b_evidence(run_id,evidence_code,segment_key);

/* R10 GOVERNED STATEMENT 0022 OF 0034
   statement_code: ANALYZE_TMP_RECOVER_M2_12_222B_EVIDENCE
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_222b_evidence;

/* R10 GOVERNED STATEMENT 0023 OF 0034
   statement_code: CREATE_TMP_RECOVER_M2_12_222B_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_222b_context ON COMMIT DROP AS
WITH actual AS (
 SELECT e.run_id,e.evidence_code,e.segment_key,e.metric_name,e.metric_value_numeric,e.metric_value_text,e.unit_code,e.status,e.threshold_value_numeric,e.interpretation
 FROM msbf_ctl.run_evidence e JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code LIKE 'M2_12_%'
), dup AS (
 SELECT ((SELECT count(*) FROM (SELECT run_id,evidence_code,segment_key,count(*) FROM tmp_recover_m2_12_222b_evidence GROUP BY 1,2,3 HAVING count(*)<>1) x)
       +(SELECT count(*) FROM (SELECT run_id,evidence_code,segment_key,count(*) FROM actual GROUP BY 1,2,3 HAVING count(*)<>1) a))::integer AS duplicate_business_keys
), exact_key AS (
 SELECT count(*) FILTER(WHERE a.evidence_code IS NULL)::integer AS missing_rows,count(*) FILTER(WHERE x.evidence_code IS NULL)::integer AS extra_rows,
 count(*) FILTER(WHERE x.evidence_code IS NOT NULL AND a.evidence_code IS NOT NULL AND x.metric_name IS DISTINCT FROM a.metric_name)::integer AS segment_metric_mismatches,
 count(*) FILTER(WHERE x.evidence_code IS NOT NULL AND a.evidence_code IS NOT NULL AND (x.unit_code IS DISTINCT FROM a.unit_code OR x.status IS DISTINCT FROM a.status))::integer AS unit_status_mismatches,
 count(*) FILTER(WHERE x.evidence_code IS NOT NULL AND a.evidence_code IS NOT NULL AND (x.metric_value_numeric IS DISTINCT FROM a.metric_value_numeric OR x.metric_value_text IS DISTINCT FROM a.metric_value_text))::integer AS metric_value_mismatches,
 count(*) FILTER(WHERE x.evidence_code IS NOT NULL AND a.evidence_code IS NOT NULL AND x.threshold_value_numeric IS DISTINCT FROM a.threshold_value_numeric)::integer AS threshold_mismatches,
 count(*) FILTER(WHERE x.evidence_code IS NOT NULL AND a.evidence_code IS NOT NULL AND x.interpretation IS DISTINCT FROM a.interpretation)::integer AS interpretation_mismatches
 FROM tmp_recover_m2_12_222b_evidence x FULL JOIN actual a USING(run_id,evidence_code,segment_key)
), code_parity AS (
 SELECT count(*) FILTER(WHERE x.evidence_code IS NULL OR a.evidence_code IS NULL)::integer AS evidence_code_mismatches
 FROM (SELECT DISTINCT run_id,evidence_code FROM tmp_recover_m2_12_222b_evidence) x FULL JOIN (SELECT DISTINCT run_id,evidence_code FROM actual) a USING(run_id,evidence_code)
)
SELECT rc.module1_run_id::bigint,scope.run_status::text,scope.policy_rows::bigint,scope.nonpolicy_rows::bigint,scope.evidence_rows::bigint,scope.gate_rows::bigint,
 p.missing_rows,p.extra_rows,d.duplicate_business_keys,c.evidence_code_mismatches,p.segment_metric_mismatches,p.unit_status_mismatches,p.metric_value_mismatches,p.threshold_mismatches,p.interpretation_mismatches,
 (p.missing_rows+p.extra_rows+d.duplicate_business_keys+c.evidence_code_mismatches+p.segment_metric_mismatches+p.unit_status_mismatches+p.metric_value_mismatches+p.threshold_mismatches+p.interpretation_mismatches)::integer AS evidence_parity_mismatch_count,
 CASE WHEN proof.total_mismatch_count=0 AND scope.policy_rows=1 AND scope.nonpolicy_rows=133 AND scope.gate_rows=0 AND scope.run_status IN('M2_11_ACCEPTED','M2_12_GENERATED') THEN
   CASE WHEN scope.evidence_rows=0 AND scope.run_status='M2_11_ACCEPTED' THEN 'REPAIR_MISSING_EVIDENCE_AND_RUN_STATUS'
        WHEN scope.evidence_rows=24 AND scope.run_status='M2_11_ACCEPTED' AND (p.missing_rows+p.extra_rows+d.duplicate_business_keys+c.evidence_code_mismatches+p.segment_metric_mismatches+p.unit_status_mismatches+p.metric_value_mismatches+p.threshold_mismatches+p.interpretation_mismatches)=0 THEN 'REPAIR_RUN_STATUS_ONLY'
        WHEN scope.evidence_rows=24 AND scope.run_status='M2_12_GENERATED' AND (p.missing_rows+p.extra_rows+d.duplicate_business_keys+c.evidence_code_mismatches+p.segment_metric_mismatches+p.unit_status_mismatches+p.metric_value_mismatches+p.threshold_mismatches+p.interpretation_mismatches)=0 THEN 'NO_ACTION_COMPLETE'
        ELSE 'REFUSE_EVIDENCE_PARITY' END ELSE 'REFUSE_PHYSICAL_PROOF' END::text AS recovery_decision_code,
 (proof.total_mismatch_count=0 AND scope.policy_rows=1 AND scope.nonpolicy_rows=133 AND scope.gate_rows=0 AND ((scope.evidence_rows=0 AND scope.run_status='M2_11_ACCEPTED') OR (scope.evidence_rows=24 AND (p.missing_rows+p.extra_rows+d.duplicate_business_keys+c.evidence_code_mismatches+p.segment_metric_mismatches+p.unit_status_mismatches+p.metric_value_mismatches+p.threshold_mismatches+p.interpretation_mismatches)=0)))::boolean AS recovery_permitted_flag
FROM tmp_recover_m2_12_222b_run_context rc JOIN tmp_recover_m2_12_governed_scope scope ON scope.module1_run_id=rc.module1_run_id JOIN tmp_recover_m2_12_222b_phase9_proof proof ON proof.module1_run_id=rc.module1_run_id CROSS JOIN exact_key p CROSS JOIN dup d CROSS JOIN code_parity c;

/* R10 GOVERNED STATEMENT 0024 OF 0034
   statement_code: ASSERT_TMP_RECOVER_M2_12_222B_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r8_222b_context$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_222b_context)<>1 OR NOT (SELECT recovery_permitted_flag FROM tmp_recover_m2_12_222b_context) THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 222B recovery decision refused by physical/evidence proof'; END IF; END; $m212_r8_222b_context$;

/* R10 GOVERNED STATEMENT 0025 OF 0034
   statement_code: INDEX_TMP_RECOVER_M2_12_222B_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_tmp_recover_m2_12_222b_context ON tmp_recover_m2_12_222b_context(module1_run_id);

/* R10 GOVERNED STATEMENT 0026 OF 0034
   statement_code: ANALYZE_TMP_RECOVER_M2_12_222B_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_222b_context;

/* R10 GOVERNED STATEMENT 0027 OF 0034
   statement_code: RECOVERY_DISPATCH
   phase_code: 02_DISPATCH
   statement_type: RECOVERY_DECISION
   source_authority: M2_12_RECOVERY_DECISION_DISPATCH_COMPILER.csv
*/
DO $m212_r8_222b_dispatch$
DECLARE v_decision text; v_rows bigint;
BEGIN
 SELECT recovery_decision_code INTO STRICT v_decision FROM tmp_recover_m2_12_222b_context;
 IF v_decision='NO_ACTION_COMPLETE' THEN
  IF NOT (SELECT evidence_parity_mismatch_count=0 FROM tmp_recover_m2_12_222b_context) THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 222B NO_ACTION requires exact evidence parity'; END IF;
 ELSIF v_decision='REPAIR_RUN_STATUS_ONLY' THEN
  IF NOT (SELECT evidence_parity_mismatch_count=0 FROM tmp_recover_m2_12_222b_context) THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 222B status repair requires exact evidence parity'; END IF;
  UPDATE msbf_ctl.run_registry rr SET run_status='M2_12_GENERATED' FROM tmp_recover_m2_12_222b_run_context ctx WHERE rr.run_id=ctx.module1_run_id AND rr.run_status='M2_11_ACCEPTED';
  GET DIAGNOSTICS v_rows=ROW_COUNT; IF v_rows<>1 THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 222B run-status repair affected an unexpected row count'; END IF;
 ELSIF v_decision='REPAIR_MISSING_EVIDENCE_AND_RUN_STATUS' THEN
  INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,threshold_value_numeric,interpretation)
  SELECT run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,threshold_value_numeric,interpretation FROM tmp_recover_m2_12_222b_evidence ORDER BY evidence_sequence;
  GET DIAGNOSTICS v_rows=ROW_COUNT; IF v_rows<>24 THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 222B evidence repair inserted an unexpected row count'; END IF;
  UPDATE msbf_ctl.run_registry rr SET run_status='M2_12_GENERATED' FROM tmp_recover_m2_12_222b_run_context ctx WHERE rr.run_id=ctx.module1_run_id AND rr.run_status='M2_11_ACCEPTED';
  GET DIAGNOSTICS v_rows=ROW_COUNT; IF v_rows<>1 THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 222B run-status repair affected an unexpected row count'; END IF;
 ELSE RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 222B recovery refused by physical/evidence proof'; END IF;
END;
$m212_r8_222b_dispatch$;

/* R10 GOVERNED STATEMENT 0028 OF 0034
   statement_code: CREATE_TMP_RECOVER_M2_12_222B_RESULT
   phase_code: 03_RESULT_STATE
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_recover_m2_12_222b_result ON COMMIT DROP AS
SELECT '222B'::text AS recovery_program,
       c.recovery_decision_code::text AS recovery_decision_code,
       CASE WHEN c.recovery_permitted_flag THEN 'PASS' ELSE 'FAIL' END::text AS recovery_status,
       CASE WHEN to_regclass('msbf_ctl.m2_12_policy_profile_policy_profile_id_seq') IS NULL THEN 'NOT_PRESENT' ELSE (SELECT s.last_value::text||'|'||s.is_called::text FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq s) END::text AS policy_sequence_state,
       CASE WHEN to_regclass('msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq') IS NULL THEN 'NOT_PRESENT' ELSE (SELECT s.last_value::text||'|'||s.is_called::text FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq s) END::text AS archive_sequence_state,
       CASE WHEN to_regclass('msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq') IS NULL THEN 'NOT_PRESENT' ELSE (SELECT s.last_value::text||'|'||s.is_called::text FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq s) END::text AS registry_sequence_state,
       CASE c.recovery_decision_code WHEN 'NO_ACTION_PRISTINE' THEN 'PASS_NO_ACTION' WHEN 'NO_ACTION_COMPLETE' THEN 'PASS_NO_ACTION' WHEN 'RECOVER_FAILED_INSTALL' THEN 'PASS_RECOVERED' WHEN 'RESTORE_FAILED_GENERATION_SEQUENCES' THEN 'PASS_RECOVERED' WHEN 'REPAIR_MISSING_EVIDENCE_AND_RUN_STATUS' THEN 'PASS_RECOVERED' WHEN 'REPAIR_RUN_STATUS_ONLY' THEN 'PASS_RECOVERED' ELSE 'FAIL_CLOSED' END::text AS disposition
FROM tmp_recover_m2_12_222b_context c;

/* R10 GOVERNED STATEMENT 0029 OF 0034
   statement_code: ASSERT_TMP_RECOVER_M2_12_222B_RESULT
   phase_code: 03_RESULT_STATE
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_recover_m2_12_222b_result$ BEGIN IF (SELECT count(*) FROM tmp_recover_m2_12_222b_result) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_recover_m2_12_222b_result', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_recover_m2_12_222b_result)::text; END IF; END; $m212_r7_tmp_recover_m2_12_222b_result$;

/* R10 GOVERNED STATEMENT 0030 OF 0034
   statement_code: INDEX_TMP_RECOVER_M2_12_222B_RESULT
   phase_code: 03_RESULT_STATE
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_recover_m2_12_222b_result_227957f2 ON tmp_recover_m2_12_222b_result (recovery_program);

/* R10 GOVERNED STATEMENT 0031 OF 0034
   statement_code: ANALYZE_TMP_RECOVER_M2_12_222B_RESULT
   phase_code: 03_RESULT_STATE
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_recover_m2_12_222b_result;

/* R10 GOVERNED STATEMENT 0032 OF 0034
   statement_code: RECOVERY_POSTCONDITION
   phase_code: 04_POSTCONDITION
   statement_type: POSTFLIGHT
   source_authority: M2_12_RECOVERY_DECISION_DISPATCH_COMPILER.csv
*/
DO $m212_r8_222b_postflight$
DECLARE v_mismatch bigint;
BEGIN
 WITH actual AS (SELECT e.run_id,e.evidence_code,e.segment_key,e.metric_name,e.metric_value_numeric,e.metric_value_text,e.unit_code,e.status,e.threshold_value_numeric,e.interpretation FROM msbf_ctl.run_evidence e JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code LIKE 'M2_12_%'),
 dup AS (SELECT ((SELECT count(*) FROM (SELECT run_id,evidence_code,segment_key,count(*) FROM tmp_recover_m2_12_222b_evidence GROUP BY 1,2,3 HAVING count(*)<>1)x)+(SELECT count(*) FROM (SELECT run_id,evidence_code,segment_key,count(*) FROM actual GROUP BY 1,2,3 HAVING count(*)<>1)a))::bigint n),
 parity AS (SELECT count(*) FILTER(WHERE a.evidence_code IS NULL OR x.evidence_code IS NULL OR x.metric_name IS DISTINCT FROM a.metric_name OR x.metric_value_numeric IS DISTINCT FROM a.metric_value_numeric OR x.metric_value_text IS DISTINCT FROM a.metric_value_text OR x.unit_code IS DISTINCT FROM a.unit_code OR x.status IS DISTINCT FROM a.status OR x.threshold_value_numeric IS DISTINCT FROM a.threshold_value_numeric OR x.interpretation IS DISTINCT FROM a.interpretation)::bigint n FROM tmp_recover_m2_12_222b_evidence x FULL JOIN actual a USING(run_id,evidence_code,segment_key))
 SELECT dup.n+parity.n INTO v_mismatch FROM dup CROSS JOIN parity;
 IF v_mismatch<>0 THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 222B postflight evidence parity failed'; END IF;
 IF (SELECT count(*) FROM msbf_ctl.run_registry rr JOIN tmp_recover_m2_12_222b_run_context ctx ON ctx.module1_run_id=rr.run_id WHERE rr.run_status='M2_12_GENERATED')<>1 THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='M2.12 222B postflight lifecycle failed'; END IF;
END;
$m212_r8_222b_postflight$;

/* R10 GOVERNED STATEMENT 0033 OF 0034
   statement_code: PRIMARY_RESULT
   phase_code: 05_RESULT
   statement_type: RESULT_SELECT
   source_authority: M2_12_PROGRAM_PRIMARY_RESULT_STATEMENT_COMPILER.csv
*/
SELECT recovery_program,recovery_decision_code,recovery_status,policy_sequence_state,archive_sequence_state,registry_sequence_state,disposition
FROM tmp_recover_m2_12_222b_result;

/* R10 GOVERNED STATEMENT 0034 OF 0034
   statement_code: COMMIT
   phase_code: 06_COMMIT
   statement_type: TRANSACTION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
COMMIT;

