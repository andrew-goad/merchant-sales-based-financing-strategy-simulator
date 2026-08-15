/***************************************************************************************************
M2.12 — ENTERPRISE PORTFOLIO CERTIFICATION & CONSUMPTION CONTRACT
PROGRAM 222 — End-to-End Certification Generation and Physical Reconciliation

WORK PACKAGE
M2.12 Work Package 2 — SQL Source Correction R3

PROGRAM CLASS
NORMAL

GOVERNING IMPLEMENTATION AUTHORITY
M2_12_Build_WP1_R10.zip
SHA-256: 2e4017c80b03bf7ff691b114654beed0a63dcf677607bde11696f6b5582e6d10
M2_12_WP1_SOURCE_AUTHORITY_R10.md
M2_12_WP2_LITERAL_PROGRAM_STATEMENT_ORDER_CATALOG.csv
M2_12_WP2_LITERAL_COMPILATION_DECISION_MATRIX.csv
M2_12_WP2_SOURCE_AUTHORITY_R3.md
M2_12_WP2_SOURCE_R3_REQUIRED_SOURCE_EDGE_ARRAY_CAST_CORRECTION_R1.md

CONSTRUCTION RULE
The executable SQL below preserves the approved 206-statement order. Statement 92 is regenerated
under M2_12_WP2_SOURCE_R3_REQUIRED_SOURCE_EDGE_ARRAY_CAST_CORRECTION_R1 to convert the governed
pipe-delimited source-edge text into the persistent text[] target. Statements 87, 97, 102, and 107
remain byte-identical to WP2 R2; all other 201 governed literals also remain byte-identical to R2.
Surrounding comments are non-executable traceability metadata only.


HF9 BOUNDED LIVE-EXECUTION CORRECTION AUTHORITY
Program 220 HF4 and Program 221 HF6 completed successfully. The Program 222 HF8 read-only verifier
reconciled all 19 source edges, all 12 stage-boundary nodes, all 70 physical boundary controls, and the
pristine pre-generation state. Program 222 HF8 then failed with SQLSTATE 42702 because a registry-hash
helper used an unqualified module1_run_id while multiple joined helpers exposed that column. The operator
stopped and rolled back.

HF9 corrects the complete related hash-staging defect family rather than only the first failing predicate:
all multi-source module1_run_id predicates are explicitly alias-qualified, all run-status literals are quoted,
the two aggregate hash helpers group by the governed run key, and the earlier single-source tautological
predicate is replaced by the exact accepted-run predicate. The downstream physical reconciler is also aligned
to the authoritative two-field evidence-family key and set-hash preimage used by Statements 116 and 178.
The 206-statement order, persistent mutation
statements, persistent targets, transaction boundaries, and Programs 223-227 remain unchanged.

EXECUTION STATUS
HOTFIX SOURCE CONSTRUCTED
NOT EXECUTED
NOT VALIDATED
NOT ACCEPTED

OPERATOR BOUNDARY
Execute only after the HF9 read-only pre-execution verifier returns the exact required result grids.
Execute the complete Program 222 HF9 file as one script and stop at the first error. Do not add an outer
transaction, concatenate Program 223, issue ad hoc DML/DDL, or run a recovery without separate authority.
***************************************************************************************************/
/* R10 GOVERNED STATEMENT 0001 OF 0206
   statement_code: BEGIN
   phase_code: 00_TRANSACTION
   statement_type: TRANSACTION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
BEGIN;

/* R10 GOVERNED STATEMENT 0002 OF 0206
   statement_code: SEARCH_PATH
   phase_code: 00_TRANSACTION
   statement_type: SESSION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
SET LOCAL search_path = msbf_ctl, msbf_m2, msbf_ref, public;

/* R10 GOVERNED STATEMENT 0003 OF 0206
   statement_code: CREATE_TMP_SRC_M2_12_RUN_CONTEXT
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_run_context ON COMMIT DROP AS
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
WHERE rr.run_code='M1_V0_2_BASELINE_BUILD' AND rr.run_version=1 AND rr.run_status='M2_11_ACCEPTED';

/* R10 GOVERNED STATEMENT 0004 OF 0206
   statement_code: ASSERT_TMP_SRC_M2_12_RUN_CONTEXT
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_src_m2_12_run_context$ BEGIN IF (SELECT count(*) FROM tmp_src_m2_12_run_context) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_src_m2_12_run_context', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_src_m2_12_run_context)::text; END IF; END; $m212_r7_tmp_src_m2_12_run_context$;

/* R10 GOVERNED STATEMENT 0005 OF 0206
   statement_code: INDEX_TMP_SRC_M2_12_RUN_CONTEXT
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_run_context_829f94ae ON tmp_src_m2_12_run_context (module1_run_id);

/* R10 GOVERNED STATEMENT 0006 OF 0206
   statement_code: ANALYZE_TMP_SRC_M2_12_RUN_CONTEXT
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_run_context;

/* R10 GOVERNED STATEMENT 0007 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_NEGATIVE_EVIDENCE_AGGREGATE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_cert_m2_12_negative_evidence_aggregate ON COMMIT DROP AS
WITH agg AS (
 SELECT x.node_sequence::smallint AS node_sequence,x.stage_code::text AS stage_code,
        x.matrix_sequence::smallint AS matrix_sequence,x.evidence_code_pattern::text AS evidence_code_pattern,
        x.expected_pass_count::integer AS expected_pass_count
 FROM jsonb_to_recordset('[{"aggregate_family":"NEGATIVE_CONTROLS","node_sequence":"1","stage_code":"M1_17_G2_FOUNDATION","matrix_sequence":"3","evidence_code_pattern":"M1_17_NEG_%","expected_pass_count":"20","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M1_17_NEG_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"NEGATIVE_CONTROLS","node_sequence":"2","stage_code":"M2_1_ELIGIBILITY_ROUTING","matrix_sequence":"9","evidence_code_pattern":"M2_1_NEG_%","expected_pass_count":"20","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_1_NEG_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"NEGATIVE_CONTROLS","node_sequence":"3","stage_code":"M2_2_PRICING_STRUCTURE","matrix_sequence":"15","evidence_code_pattern":"M2_2_NEG_%","expected_pass_count":"20","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_2_NEG_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"NEGATIVE_CONTROLS","node_sequence":"4","stage_code":"M2_3_FINAL_DECISION","matrix_sequence":"21","evidence_code_pattern":"M2_3_NEG_%","expected_pass_count":"20","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_3_NEG_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"NEGATIVE_CONTROLS","node_sequence":"5","stage_code":"M2_4_PORTFOLIO_ACTIVATION","matrix_sequence":"27","evidence_code_pattern":"M2_4_NEG_%","expected_pass_count":"20","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_4_NEG_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"NEGATIVE_CONTROLS","node_sequence":"6","stage_code":"M2_5_DAILY_MONITORING","matrix_sequence":"33","evidence_code_pattern":"M2_5_NEG_%","expected_pass_count":"20","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_5_NEG_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"NEGATIVE_CONTROLS","node_sequence":"7","stage_code":"M2_6_INTERVENTION_STRATEGY","matrix_sequence":"39","evidence_code_pattern":"M2_6_NEG_%","expected_pass_count":"20","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_6_NEG_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"NEGATIVE_CONTROLS","node_sequence":"8","stage_code":"M2_7_OPERATIONAL_ACTIVATION","matrix_sequence":"45","evidence_code_pattern":"M2_7_NEG_%","expected_pass_count":"20","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_7_NEG_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"NEGATIVE_CONTROLS","node_sequence":"9","stage_code":"M2_8_SERVICING_EXECUTION","matrix_sequence":"51","evidence_code_pattern":"M2_8_NEG_%","expected_pass_count":"20","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_8_NEG_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"NEGATIVE_CONTROLS","node_sequence":"10","stage_code":"M2_9_RECONCILIATION_CERTIFICATION","matrix_sequence":"57","evidence_code_pattern":"M2_9_NEG_%","expected_pass_count":"20","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_9_NEG_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"NEGATIVE_CONTROLS","node_sequence":"11","stage_code":"M2_10_PORTFOLIO_ANALYTICS","matrix_sequence":"63","evidence_code_pattern":"M2_10_NEG_%","expected_pass_count":"20","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_10_NEG_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"NEGATIVE_CONTROLS","node_sequence":"12","stage_code":"M2_11_STRATEGY_SIMULATION","matrix_sequence":"69","evidence_code_pattern":"M2_11_NEG_%","expected_pass_count":"20","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_11_NEG_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"}]'::jsonb)
      AS x(node_sequence smallint,stage_code text,matrix_sequence smallint,evidence_code_pattern text,expected_pass_count integer)
), obs AS (
 SELECT ctx.module1_run_id,agg.*,
        count(e.*) FILTER (WHERE e.status='PASS')::integer AS observed_pass_count,
        count(e.*) FILTER (WHERE e.status<>'PASS')::integer AS observed_nonpass_count,
        md5(coalesce(string_agg(concat_ws('|',e.evidence_code,e.segment_key,e.metric_name,coalesce(e.metric_value_text,e.metric_value_numeric::text),e.status),'|' ORDER BY e.evidence_code,e.segment_key,e.metric_name),'')::text) AS source_evidence_fingerprint
 FROM tmp_src_m2_12_run_context ctx CROSS JOIN agg
 LEFT JOIN msbf_ctl.run_evidence e ON e.run_id=ctx.module1_run_id AND e.evidence_code LIKE agg.evidence_code_pattern
 GROUP BY ctx.module1_run_id,agg.node_sequence,agg.stage_code,agg.matrix_sequence,agg.evidence_code_pattern,agg.expected_pass_count
)
SELECT CASE WHEN observed_pass_count=expected_pass_count AND observed_nonpass_count=0 THEN 'PASS' ELSE 'FAIL' END::text AS aggregate_status,
       node_sequence AS certification_node_sequence,evidence_code_pattern AS evidence_code_or_method_pattern,
       expected_pass_count,matrix_sequence,module1_run_id,observed_nonpass_count,observed_pass_count,
       source_evidence_fingerprint,stage_code
FROM obs
ORDER BY certification_node_sequence;

/* R10 GOVERNED STATEMENT 0008 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_NEGATIVE_EVIDENCE_AGGREGATE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_cert_m2_12_negative_evidence_aggrega$ BEGIN IF (SELECT count(*) FROM tmp_cert_m2_12_negative_evidence_aggregate) <> 12 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_cert_m2_12_negative_evidence_aggregate', DETAIL='expected=12 observed='||(SELECT count(*) FROM tmp_cert_m2_12_negative_evidence_aggregate)::text; END IF; END; $m212_r7_tmp_cert_m2_12_negative_evidence_aggrega$;

/* R10 GOVERNED STATEMENT 0009 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_NEGATIVE_EVIDENCE_AGGREGATE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_negative_evidence_aggregate_8e04379c ON tmp_cert_m2_12_negative_evidence_aggregate (module1_run_id, certification_node_sequence);

/* R10 GOVERNED STATEMENT 0010 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_NEGATIVE_EVIDENCE_AGGREGATE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_negative_evidence_aggregate;

/* R10 GOVERNED STATEMENT 0011 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_POSITIVE_EVIDENCE_AGGREGATE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_cert_m2_12_positive_evidence_aggregate ON COMMIT DROP AS
WITH agg AS (
 SELECT x.node_sequence::smallint AS node_sequence,x.stage_code::text AS stage_code,
        x.matrix_sequence::smallint AS matrix_sequence,x.evidence_code_pattern::text AS evidence_code_pattern,
        x.expected_pass_count::integer AS expected_pass_count
 FROM jsonb_to_recordset('[{"aggregate_family":"POSITIVE_VALIDATION","node_sequence":"1","stage_code":"M1_17_G2_FOUNDATION","matrix_sequence":"2","evidence_code_pattern":"M1_17_POS_%","expected_pass_count":"128","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M1_17_POS_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"POSITIVE_VALIDATION","node_sequence":"2","stage_code":"M2_1_ELIGIBILITY_ROUTING","matrix_sequence":"8","evidence_code_pattern":"M2_1_POS_%","expected_pass_count":"112","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_1_POS_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"POSITIVE_VALIDATION","node_sequence":"3","stage_code":"M2_2_PRICING_STRUCTURE","matrix_sequence":"14","evidence_code_pattern":"M2_2_POS_%","expected_pass_count":"120","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_2_POS_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"POSITIVE_VALIDATION","node_sequence":"4","stage_code":"M2_3_FINAL_DECISION","matrix_sequence":"20","evidence_code_pattern":"M2_3_POS_%","expected_pass_count":"120","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_3_POS_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"POSITIVE_VALIDATION","node_sequence":"5","stage_code":"M2_4_PORTFOLIO_ACTIVATION","matrix_sequence":"26","evidence_code_pattern":"M2_4_POS_%","expected_pass_count":"120","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_4_POS_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"POSITIVE_VALIDATION","node_sequence":"6","stage_code":"M2_5_DAILY_MONITORING","matrix_sequence":"32","evidence_code_pattern":"M2_5_POS_%","expected_pass_count":"120","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_5_POS_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"POSITIVE_VALIDATION","node_sequence":"7","stage_code":"M2_6_INTERVENTION_STRATEGY","matrix_sequence":"38","evidence_code_pattern":"M2_6_POS_%","expected_pass_count":"120","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_6_POS_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"POSITIVE_VALIDATION","node_sequence":"8","stage_code":"M2_7_OPERATIONAL_ACTIVATION","matrix_sequence":"44","evidence_code_pattern":"M2_7_POS_%","expected_pass_count":"120","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_7_POS_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"POSITIVE_VALIDATION","node_sequence":"9","stage_code":"M2_8_SERVICING_EXECUTION","matrix_sequence":"50","evidence_code_pattern":"M2_8_POS_%","expected_pass_count":"120","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_8_POS_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"POSITIVE_VALIDATION","node_sequence":"10","stage_code":"M2_9_RECONCILIATION_CERTIFICATION","matrix_sequence":"56","evidence_code_pattern":"M2_9_POS_%","expected_pass_count":"120","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_9_POS_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"POSITIVE_VALIDATION","node_sequence":"11","stage_code":"M2_10_PORTFOLIO_ANALYTICS","matrix_sequence":"62","evidence_code_pattern":"M2_10_POS_%","expected_pass_count":"120","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_10_POS_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"},{"aggregate_family":"POSITIVE_VALIDATION","node_sequence":"12","stage_code":"M2_11_STRATEGY_SIMULATION","matrix_sequence":"68","evidence_code_pattern":"M2_11_POS_%","expected_pass_count":"120","expected_nonpass_count":"0","source_relation":"msbf_ctl.run_evidence","exact_filter":"run_id=ctx.module1_run_id AND evidence_code LIKE ''M2_11_POS_%''","fingerprint_order":"evidence_code, segment_key, metric_name","required_status":"PASS","method_status":"LOCKED_R3"}]'::jsonb)
      AS x(node_sequence smallint,stage_code text,matrix_sequence smallint,evidence_code_pattern text,expected_pass_count integer)
), obs AS (
 SELECT ctx.module1_run_id,agg.*,
        count(e.*) FILTER (WHERE e.status='PASS')::integer AS observed_pass_count,
        count(e.*) FILTER (WHERE e.status<>'PASS')::integer AS observed_nonpass_count,
        md5(coalesce(string_agg(concat_ws('|',e.evidence_code,e.segment_key,e.metric_name,coalesce(e.metric_value_text,e.metric_value_numeric::text),e.status),'|' ORDER BY e.evidence_code,e.segment_key,e.metric_name),'')::text) AS source_evidence_fingerprint
 FROM tmp_src_m2_12_run_context ctx CROSS JOIN agg
 LEFT JOIN msbf_ctl.run_evidence e ON e.run_id=ctx.module1_run_id AND e.evidence_code LIKE agg.evidence_code_pattern
 GROUP BY ctx.module1_run_id,agg.node_sequence,agg.stage_code,agg.matrix_sequence,agg.evidence_code_pattern,agg.expected_pass_count
)
SELECT CASE WHEN observed_pass_count=expected_pass_count AND observed_nonpass_count=0 THEN 'PASS' ELSE 'FAIL' END::text AS aggregate_status,
       node_sequence AS certification_node_sequence,evidence_code_pattern AS evidence_code_or_method_pattern,
       expected_pass_count,matrix_sequence,module1_run_id,observed_nonpass_count,observed_pass_count,
       source_evidence_fingerprint,stage_code
FROM obs
ORDER BY certification_node_sequence;

/* R10 GOVERNED STATEMENT 0012 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_POSITIVE_EVIDENCE_AGGREGATE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_cert_m2_12_positive_evidence_aggrega$ BEGIN IF (SELECT count(*) FROM tmp_cert_m2_12_positive_evidence_aggregate) <> 12 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_cert_m2_12_positive_evidence_aggregate', DETAIL='expected=12 observed='||(SELECT count(*) FROM tmp_cert_m2_12_positive_evidence_aggregate)::text; END IF; END; $m212_r7_tmp_cert_m2_12_positive_evidence_aggrega$;

/* R10 GOVERNED STATEMENT 0013 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_POSITIVE_EVIDENCE_AGGREGATE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_positive_evidence_aggregate_1277a49a ON tmp_cert_m2_12_positive_evidence_aggregate (module1_run_id, certification_node_sequence);

/* R10 GOVERNED STATEMENT 0014 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_POSITIVE_EVIDENCE_AGGREGATE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_positive_evidence_aggregate;

/* R10 GOVERNED STATEMENT 0015 OF 0206
   statement_code: CREATE_TMP_SRC_M2_12_CAPABILITY_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_capability_design ON COMMIT DROP AS
SELECT v.capability_code::text AS capability_code,
       v.capability_sequence::smallint AS capability_sequence,
       v.certifying_stage_code::text AS certifying_stage_code,
       v.claim_boundary::text AS claim_boundary,
       v.coverage_status_code::text AS coverage_status_code,
       v.legal_or_regulatory_certified_flag::boolean AS legal_or_regulatory_certified_flag,
       ctx.module1_run_id::bigint AS module1_run_id,
       v.notes::text AS notes,
       v.production_action_authorized_flag::boolean AS production_action_authorized_flag
FROM (VALUES
    ('M1_G2_APPLICATION_RISK_FOUNDATION'::text,'1'::text,'M1_17_G2_FOUNDATION'::text,'Accepted application, risk, economics, acquisition, evidence, and scenario foundation.'::text,'IMPLEMENTED_CERTIFIED'::text,'false'::text,'Module 2 source boundary'::text,'false'::text),
    ('ELIGIBILITY_POLICY_ROUTING'::text,'2'::text,'M2_1_ELIGIBILITY_ROUTING'::text,'Governed eligibility gates, policy results, reasons, and routing outcomes.'::text,'IMPLEMENTED_CERTIFIED'::text,'false'::text,'As-built accepted scope'::text,'false'::text),
    ('PRICING_STRUCTURE_COUNTEROFFER'::text,'3'::text,'M2_2_PRICING_STRUCTURE'::text,'Accepted request structures, finite pricing candidates, counteroffer foundations, and scenario results.'::text,'IMPLEMENTED_CERTIFIED'::text,'false'::text,'As-built accepted scope'::text,'false'::text),
    ('FINAL_OFFER_DECISION_AUTHORIZATION'::text,'4'::text,'M2_3_FINAL_DECISION'::text,'Synthetic final offer and decision authorization evidence only.'::text,'IMPLEMENTED_CERTIFIED_SYNTHETIC'::text,'false'::text,'Not a production credit decision'::text,'false'::text),
    ('BOOKING_FUNDING_PORTFOLIO_ACTIVATION'::text,'5'::text,'M2_4_PORTFOLIO_ACTIVATION'::text,'Synthetic booking, funding, account, advance, and portfolio activation records.'::text,'IMPLEMENTED_BOUNDED_SYNTHETIC'::text,'false'::text,'No real booking or funds movement'::text,'false'::text),
    ('DAILY_REMITTANCE_EXPOSURE_MONITORING'::text,'6'::text,'M2_5_DAILY_MONITORING'::text,'Synthetic daily remittance, exposure, monitoring, alert, and portfolio summaries.'::text,'IMPLEMENTED_BOUNDED_SYNTHETIC'::text,'false'::text,'No production ledger or processor execution'::text,'false'::text),
    ('EARLY_WARNING_INTERVENTION_SERVICING'::text,'7'::text,'M2_6_INTERVENTION_STRATEGY'::text,'Synthetic early-warning and servicing-action recommendations.'::text,'IMPLEMENTED_BOUNDED_RECOMMENDATION'::text,'false'::text,'Recommendation evidence only'::text,'false'::text),
    ('OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'::text,'8'::text,'M2_7_OPERATIONAL_ACTIVATION'::text,'Synthetic operational account setup and reassessment evidence.'::text,'IMPLEMENTED_BOUNDED_SYNTHETIC'::text,'false'::text,'No external system update'::text,'false'::text),
    ('SERVICING_PAYMENT_LIFECYCLE_SIMULATION'::text,'9'::text,'M2_8_SERVICING_EXECUTION'::text,'Synthetic payment-processing events and lifecycle transitions.'::text,'IMPLEMENTED_BOUNDED_SYNTHETIC'::text,'false'::text,'No payment-network or bank-account activity'::text,'false'::text),
    ('PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION'::text,'10'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text,'Reconciled synthetic payment evidence and certified synthetic account states.'::text,'IMPLEMENTED_CERTIFIED_SYNTHETIC'::text,'false'::text,'Not production accounting certification'::text,'false'::text),
    ('PORTFOLIO_KPI_SERVICING_ANALYTICS'::text,'11'::text,'M2_10_PORTFOLIO_ANALYTICS'::text,'Governed KPI, performance-tier, servicing-queue, exposure, payment, and exception analytics.'::text,'IMPLEMENTED_CERTIFIED_ANALYTICS'::text,'false'::text,'Synthetic analytics only'::text,'false'::text),
    ('PORTFOLIO_STRATEGY_FRONTIER'::text,'12'::text,'M2_11_STRATEGY_SIMULATION'::text,'Finite deterministic strategy comparison, Pareto frontier, and governance-review priority evidence.'::text,'IMPLEMENTED_CERTIFIED_COMPARATIVE'::text,'false'::text,'Not a champion or deployment decision'::text,'false'::text),
    ('COLLATERAL_GUARANTEE_PACKAGE'::text,'13'::text,'NONE'::text,'Original charter capability not implemented in the accepted M2.1-M2.11 chain.'::text,'DEFERRED_NOT_IMPLEMENTED'::text,'false'::text,'Requires separate future design and data'::text,'false'::text),
    ('COVENANT_PACKAGE_AND_TESTING'::text,'14'::text,'NONE'::text,'Original charter capability not implemented as a governed covenant package or test framework.'::text,'DEFERRED_NOT_IMPLEMENTED'::text,'false'::text,'Requires separate future lifecycle design'::text,'false'::text),
    ('REGULATORY_APPLICABILITY_LEGAL_COMPLIANCE'::text,'15'::text,'NONE'::text,'No jurisdiction, licensing, disclosure, legal-form, UDAAP, fair-lending, or regulatory applicability certification.'::text,'DEFERRED_NOT_CERTIFIED'::text,'false'::text,'Legal/compliance review required before production'::text,'false'::text),
    ('PORTFOLIO_FUNDING_BUDGET_ALLOCATION'::text,'16'::text,'NONE'::text,'No production funding-budget, capital-allocation, or concentration-allocation engine.'::text,'DEFERRED_NOT_IMPLEMENTED'::text,'false'::text,'Strategy exposure comparisons are not allocation authority'::text,'false'::text),
    ('PRODUCTION_DECISION_ACCOUNT_PAYMENT_EXECUTION'::text,'17'::text,'NONE'::text,'No production decision, account creation, payment instruction, processor call, or funds movement.'::text,'PROHIBITED_NOT_AUTHORIZED'::text,'false'::text,'Production execution expressly prohibited'::text,'false'::text),
    ('ACCOUNTING_CECL_CAPITAL_TREASURY'::text,'18'::text,'NONE'::text,'No GAAP accounting, CECL reserve, economic capital, regulatory capital, or treasury certification.'::text,'DEFERRED_NOT_CERTIFIED'::text,'false'::text,'Comparative expected loss and contribution are synthetic'::text,'false'::text),
    ('EMPIRICAL_CAUSAL_OPTIMIZATION_CHAMPION'::text,'19'::text,'NONE'::text,'No causal uplift, calibrated treatment effect, autonomous optimization, production champion, or statistical generalization.'::text,'NOT_SUPPORTED_NOT_AUTHORIZED'::text,'false'::text,'M2.11 priority is governance review only'::text,'false'::text),
    ('CUSTOMER_MERCHANT_NOTICE_ADVERSE_ACTION'::text,'20'::text,'NONE'::text,'No merchant-facing offer, notice, adverse-action communication, collection notice, or legal communication.'::text,'PROHIBITED_NOT_AUTHORIZED'::text,'false'::text,'Synthetic reason evidence is not customer communication'::text,'false'::text)) AS v(capability_code,capability_sequence,certifying_stage_code,claim_boundary,coverage_status_code,legal_or_regulatory_certified_flag,notes,production_action_authorized_flag)
CROSS JOIN tmp_src_m2_12_run_context ctx;

/* R10 GOVERNED STATEMENT 0016 OF 0206
   statement_code: ASSERT_TMP_SRC_M2_12_CAPABILITY_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_src_m2_12_capability_design$ BEGIN IF (SELECT count(*) FROM tmp_src_m2_12_capability_design) <> 20 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_src_m2_12_capability_design', DETAIL='expected=20 observed='||(SELECT count(*) FROM tmp_src_m2_12_capability_design)::text; END IF; END; $m212_r7_tmp_src_m2_12_capability_design$;

/* R10 GOVERNED STATEMENT 0017 OF 0206
   statement_code: INDEX_TMP_SRC_M2_12_CAPABILITY_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_capability_design_78e9fe7a ON tmp_src_m2_12_capability_design (module1_run_id, capability_sequence);

/* R10 GOVERNED STATEMENT 0018 OF 0206
   statement_code: ANALYZE_TMP_SRC_M2_12_CAPABILITY_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_capability_design;

/* R10 GOVERNED STATEMENT 0019 OF 0206
   statement_code: CREATE_TMP_SRC_M2_12_COMPONENT_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_component_design ON COMMIT DROP AS
SELECT v.acceptance_evidence_code::text AS acceptance_evidence_code,
       v.acceptance_gate_id::text AS acceptance_gate_id,
       v.acceptance_gate_review_version::integer AS acceptance_gate_review_version,
       v.archive_business_key_columns::jsonb AS archive_business_key_columns,
       v.archive_relation::text AS archive_relation,
       v.archive_set_hash::text AS archive_set_hash,
       v.certification_node_sequence::smallint AS certification_node_sequence,
       v.component_contract_code::text AS component_contract_code,
       v.component_sequence::smallint AS component_sequence,
       v.contract_set_hash::text AS contract_set_hash,
       v.contract_version::integer AS contract_version,
       v.expected_archive_rows::bigint AS expected_archive_rows,
       v.expected_archive_set_hash::text AS expected_archive_set_hash,
       v.expected_contract_set_hash::text AS expected_contract_set_hash,
       v.expected_latest_rows::bigint AS expected_latest_rows,
       v.expected_latest_set_hash::text AS expected_latest_set_hash,
       v.expected_negative_controls::integer AS expected_negative_controls,
       v.expected_positive_controls::integer AS expected_positive_controls,
       v.expected_registry_row_hash::text AS expected_registry_row_hash,
       v.expected_stage_combined_set_hash::text AS expected_stage_combined_set_hash,
       v.historical_acceptance_method::text AS historical_acceptance_method,
       v.latest_business_grain::text AS latest_business_grain,
       v.latest_business_key_columns::jsonb AS latest_business_key_columns,
       v.latest_relation::text AS latest_relation,
       v.latest_set_hash::text AS latest_set_hash,
       v.methodology_version::text AS methodology_version,
       ctx.module1_run_id::bigint AS module1_run_id,
       v.module_title::text AS module_title,
       v.registry_relation::text AS registry_relation,
       v.registry_row_hash::text AS registry_row_hash,
       v.repository_stage::text AS repository_stage,
       v.required_source_edge_codes::text AS required_source_edge_codes,
       v.required_source_edge_count::smallint AS required_source_edge_count,
       v.required_source_hash_graph::text AS required_source_hash_graph,
       v.schema_version::text AS schema_version,
       v.stage_code::text AS stage_code,
       v.stage_combined_set_hash::text AS stage_combined_set_hash,
       v.stage_expected_canonical_entities::bigint AS stage_expected_canonical_entities
FROM (VALUES
    ('M1_17_ACCEPTANCE_SUMMARY'::text,'G2_M1_CONTRACT'::text,'1'::text,'["module1_run_id","bundle_code","bundle_version"]'::text,'msbf_ctl.m1_17_g2_bundle_archive'::text,'020a5946318d6d73da58f723349ab18c'::text,'1'::text,'M1_G2_CONSUMPTION_BUNDLE'::text,'1'::text,'d9cdb8309efdcc892f0a0c51b3d5fe94'::text,'1'::text,'1'::text,'020a5946318d6d73da58f723349ab18c'::text,'d9cdb8309efdcc892f0a0c51b3d5fe94'::text,'1'::text,'64250f8d027ad78650a1bf5ede7da6e5'::text,'20'::text,'128'::text,'27397e724a7d24a84601d5052f1b0c34'::text,'7d9e466da28cad2551aa99c4c40c912b'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M1_17_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id'::text,'["module1_run_id"]'::text,'msbf_ctl.m1_17_g2_bundle_latest'::text,'64250f8d027ad78650a1bf5ede7da6e5'::text,'M1_17_METHOD_V1'::text,'End-to-End QA, Evidence & G2 Contract Acceptance'::text,'msbf_ctl.m1_17_g2_bundle_registry'::text,'27397e724a7d24a84601d5052f1b0c34'::text,'19_M1_17'::text,'M1_15_TO_M1_17_APPLICATION_CONTRACT|M1_16_TO_M1_17_ACQUISITION_CONTRACT'::text,'2'::text,'Module 1 accepted G2 foundation'::text,'M1_G2_BUNDLE_SCHEMA_V1'::text,'M1_17_G2_FOUNDATION'::text,'7d9e466da28cad2551aa99c4c40c912b'::text,'69'::text),
    ('M2_1_ACCEPTANCE_SUMMARY'::text,'M2_1_ELIGIBILITY_POLICY_ROUTING'::text,'1'::text,'["module1_run_id","contract_code","contract_version","strategy_campaign_code","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_eligibility_routing_archive'::text,'13d7db24aa254d8efe69b28998d91fd4'::text,'2'::text,'M2_ELIGIBILITY_ROUTING_CONSUMPTION'::text,'2'::text,'5ce0574b6e27c4b94b8e65997b40f805'::text,'1'::text,'1500'::text,'13d7db24aa254d8efe69b28998d91fd4'::text,'5ce0574b6e27c4b94b8e65997b40f805'::text,'1500'::text,'f813d2d8bfa4609f83b2bfd181de3e17'::text,'20'::text,'112'::text,'e3fe1ae397c76da8f6ba88649935cfa7'::text,'e5ace7f32060ffb191c7bd0f8dd0c863'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M2_1_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id + strategy_campaign_code + scenario_id + merchant_application_id'::text,'["module1_run_id","strategy_campaign_code","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_eligibility_routing_latest'::text,'f813d2d8bfa4609f83b2bfd181de3e17'::text,'M2_1_METHOD_V1'::text,'Eligibility, Policy Gates & Decision Routing Foundations'::text,'msbf_ctl.m2_1_strategy_contract_registry'::text,'e3fe1ae397c76da8f6ba88649935cfa7'::text,'20_M2_1'::text,'M1_17_TO_M2_1'::text,'1'::text,'M1.17 G2=7d9e466da28cad2551aa99c4c40c912b'::text,'M2_1_ROUTING_SCHEMA_V1'::text,'M2_1_ELIGIBILITY_ROUTING'::text,'e5ace7f32060ffb191c7bd0f8dd0c863'::text,'22541'::text),
    ('M2_2_ACCEPTANCE_SUMMARY'::text,'M2_2_PRICING_STRUCTURE_COUNTEROFFER'::text,'1'::text,'["module1_run_id","contract_code","contract_version","merchant_application_id"]'::text,'msbf_m2.application_request_structure_archive'::text,'c397c86ab234243dc11ab84b9e98eb6f'::text,'3'::text,'M2_REQUEST_STRUCTURE_CONSUMPTION'::text,'3'::text,'89d21438326f33a6df82ee667590497b'::text,'1'::text,'750'::text,'c397c86ab234243dc11ab84b9e98eb6f'::text,'89d21438326f33a6df82ee667590497b'::text,'750'::text,'da27dcb509a8c0bf3bc7a046242a2c02'::text,'20'::text,'120'::text,'32374a67d0f8ead18af4bc18139ffdd6'::text,'bbe83b187b31ea561789797322031fc6'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M2_2_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id + merchant_application_id'::text,'["module1_run_id","merchant_application_id"]'::text,'msbf_m2.application_request_structure_latest'::text,'da27dcb509a8c0bf3bc7a046242a2c02'::text,'M2_2_METHOD_V1'::text,'Pricing, Structure & Counteroffer Foundations'::text,'msbf_ctl.m2_2_pricing_structure_contract_registry'::text,'32374a67d0f8ead18af4bc18139ffdd6'::text,'21_M2_2'::text,'M2_1_TO_M2_2|M1_3_TO_M2_2_REQUEST_AUTHORITY'::text,'2'::text,'M2.1=e5ace7f32060ffb191c7bd0f8dd0c863'::text,'M2_2_REQUEST_STRUCTURE_SCHEMA_V1'::text,'M2_2_PRICING_STRUCTURE'::text,'bbe83b187b31ea561789797322031fc6'::text,'7336'::text),
    ('M2_2_ACCEPTANCE_SUMMARY'::text,'M2_2_PRICING_STRUCTURE_COUNTEROFFER'::text,'1'::text,'["module1_run_id","contract_code","contract_version","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_pricing_structure_archive'::text,'9e43326cd8f79b98c19f02f971fb077f'::text,'3'::text,'M2_PRICING_STRUCTURE_CONSUMPTION'::text,'4'::text,'e2d8c2eeaddbb1a8f7d2baa10b4cdbd3'::text,'1'::text,'1500'::text,'9e43326cd8f79b98c19f02f971fb077f'::text,'e2d8c2eeaddbb1a8f7d2baa10b4cdbd3'::text,'1500'::text,'a69d1fca447bb573040bf697c43ce1af'::text,'20'::text,'120'::text,'32374a67d0f8ead18af4bc18139ffdd6'::text,'bbe83b187b31ea561789797322031fc6'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M2_2_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id + scenario_id + merchant_application_id'::text,'["module1_run_id","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_pricing_structure_latest'::text,'a69d1fca447bb573040bf697c43ce1af'::text,'M2_2_METHOD_V1'::text,'Pricing, Structure & Counteroffer Foundations'::text,'msbf_ctl.m2_2_pricing_structure_contract_registry'::text,'32374a67d0f8ead18af4bc18139ffdd6'::text,'21_M2_2'::text,'M2_1_TO_M2_2|M1_3_TO_M2_2_REQUEST_AUTHORITY'::text,'2'::text,'M2.1=e5ace7f32060ffb191c7bd0f8dd0c863'::text,'M2_2_PRICING_STRUCTURE_SCHEMA_V1'::text,'M2_2_PRICING_STRUCTURE'::text,'bbe83b187b31ea561789797322031fc6'::text,'7336'::text),
    ('M2_3_ACCEPTANCE_SUMMARY'::text,'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'::text,'1'::text,'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_final_offer_decision_archive'::text,'06331f681706a5b9922865ccbe900755'::text,'4'::text,'M2_FINAL_OFFER_DECISION_CONSUMPTION'::text,'5'::text,'cbe8c4a4e5d5e4d6d084ce812a64eb84'::text,'1'::text,'1500'::text,'06331f681706a5b9922865ccbe900755'::text,'cbe8c4a4e5d5e4d6d084ce812a64eb84'::text,'1500'::text,'8f421bd27d52e18770cee8fb8a72edf1'::text,'20'::text,'120'::text,'03ef3d5ffa4c49d982b3877c4002de2d'::text,'bf09349b06ede7e5a2ec830c2f9ffe90'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M2_3_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id + scenario_id + merchant_application_id'::text,'["module1_run_id","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_final_offer_decision_latest'::text,'8f421bd27d52e18770cee8fb8a72edf1'::text,'M2_3_METHOD_V1'::text,'Final Offer & Decision Authorization'::text,'msbf_ctl.m2_3_final_decision_contract_registry'::text,'03ef3d5ffa4c49d982b3877c4002de2d'::text,'22_M2_3'::text,'M2_2_TO_M2_3'::text,'1'::text,'M2.2=bbe83b187b31ea561789797322031fc6'::text,'M2_3_FINAL_DECISION_SCHEMA_V1'::text,'M2_3_FINAL_DECISION'::text,'bf09349b06ede7e5a2ec830c2f9ffe90'::text,'6029'::text),
    ('M2_4_ACCEPTANCE_SUMMARY'::text,'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'::text,'1'::text,'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_booking_funding_activation_archive'::text,'bf72bbed8c76db3ecdc6936e78718e04'::text,'5'::text,'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'::text,'6'::text,'fba075bfd6b24e07dc669d6ce25010f1'::text,'1'::text,'1500'::text,'bf72bbed8c76db3ecdc6936e78718e04'::text,'fba075bfd6b24e07dc669d6ce25010f1'::text,'1500'::text,'f26248c112635ebe5254d614f42332d6'::text,'20'::text,'120'::text,'879e04636699b51113638ec81d76667b'::text,'117450a3eea7bb3d3c74d18cc3c8e96a'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M2_4_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id + scenario_id + merchant_application_id'::text,'["module1_run_id","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_booking_funding_activation_latest'::text,'f26248c112635ebe5254d614f42332d6'::text,'M2_4_METHOD_V1'::text,'Booking, Funding & Portfolio Activation'::text,'msbf_ctl.m2_4_portfolio_activation_contract_registry'::text,'879e04636699b51113638ec81d76667b'::text,'23_M2_4'::text,'M2_3_TO_M2_4'::text,'1'::text,'M2.3=bf09349b06ede7e5a2ec830c2f9ffe90'::text,'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'::text,'M2_4_PORTFOLIO_ACTIVATION'::text,'117450a3eea7bb3d3c74d18cc3c8e96a'::text,'6212'::text),
    ('M2_5_ACCEPTANCE_SUMMARY'::text,'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'::text,'1'::text,'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::text,'msbf_m2.advance_portfolio_monitoring_archive'::text,'c8c22762d49bbd58cf89bae187eaac9f'::text,'6'::text,'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'::text,'7'::text,'decdc18973edb5f29d2e55ca8a139457'::text,'1'::text,'59'::text,'c8c22762d49bbd58cf89bae187eaac9f'::text,'decdc18973edb5f29d2e55ca8a139457'::text,'59'::text,'ddb680b9f00e88483099d90e781337eb'::text,'20'::text,'120'::text,'c50efd2f8ec5bf10216e5da889ff403d'::text,'18e1c444aa1b02ee5bd3539d7c477adc'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M2_5_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id + scenario_id + merchant_application_id'::text,'["module1_run_id","scenario_id","merchant_application_id"]'::text,'msbf_m2.advance_portfolio_monitoring_latest'::text,'ddb680b9f00e88483099d90e781337eb'::text,'M2_5_METHOD_V1'::text,'Daily Remittance, Exposure & Portfolio Monitoring'::text,'msbf_ctl.m2_5_portfolio_monitoring_contract_registry'::text,'c50efd2f8ec5bf10216e5da889ff403d'::text,'24_M2_5'::text,'M2_4_TO_M2_5|M1_6_TO_M2_5_SCENARIO_AUTHORITY'::text,'2'::text,'M2.4=117450a3eea7bb3d3c74d18cc3c8e96a'::text,'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1'::text,'M2_5_DAILY_MONITORING'::text,'18e1c444aa1b02ee5bd3539d7c477adc'::text,'7536'::text),
    ('M2_6_ACCEPTANCE_SUMMARY'::text,'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'::text,'1'::text,'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::text,'msbf_m2.advance_intervention_strategy_archive'::text,'72f26807f4d65fa6f813502df9dde3f0'::text,'7'::text,'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'::text,'8'::text,'5e5c05dbe9d334cd64d4c6c178a7bacf'::text,'1'::text,'59'::text,'72f26807f4d65fa6f813502df9dde3f0'::text,'5e5c05dbe9d334cd64d4c6c178a7bacf'::text,'59'::text,'f3c42642b2a22b68ff2130d7b065afcd'::text,'20'::text,'120'::text,'4f145d5248bbc6ed5c45b172afa4d342'::text,'868125bff29270490cab4d2e55cb1388'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M2_6_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id + scenario_id + merchant_application_id'::text,'["module1_run_id","scenario_id","merchant_application_id"]'::text,'msbf_m2.advance_intervention_strategy_latest'::text,'f3c42642b2a22b68ff2130d7b065afcd'::text,'M2_6_METHOD_V1'::text,'Early Warning, Intervention & Servicing Strategy'::text,'msbf_ctl.m2_6_intervention_strategy_contract_registry'::text,'4f145d5248bbc6ed5c45b172afa4d342'::text,'25_M2_6'::text,'M2_5_TO_M2_6'::text,'1'::text,'M2.5=18e1c444aa1b02ee5bd3539d7c477adc'::text,'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1'::text,'M2_6_INTERVENTION_STRATEGY'::text,'868125bff29270490cab4d2e55cb1388'::text,'284'::text),
    ('M2_7_ACCEPTANCE_SUMMARY'::text,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'::text,'1'::text,'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_operational_activation_archive'::text,'9980f9ff49ca53790ec9af8c6988d44a'::text,'8'::text,'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'::text,'9'::text,'c74d986057de7b01d95d0b92bc820d8c'::text,'1'::text,'59'::text,'9980f9ff49ca53790ec9af8c6988d44a'::text,'c74d986057de7b01d95d0b92bc820d8c'::text,'59'::text,'e1fa837647489de56d66222447420549'::text,'20'::text,'120'::text,'8b210c34bdb12f8fb71638b48b374c14'::text,'c8e3a472afd2a16b1183677324e9db98'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M2_7_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id + scenario_id + merchant_application_id'::text,'["module1_run_id","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_operational_activation_latest'::text,'e1fa837647489de56d66222447420549'::text,'M2_7_METHOD_V1'::text,'Operational Activation & Account Setup'::text,'msbf_ctl.m2_7_operational_activation_contract_registry'::text,'8b210c34bdb12f8fb71638b48b374c14'::text,'26_M2_7'::text,'M2_6_TO_M2_7'::text,'1'::text,'M2.6=868125bff29270490cab4d2e55cb1388'::text,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'::text,'M2_7_OPERATIONAL_ACTIVATION'::text,'c8e3a472afd2a16b1183677324e9db98'::text,'341'::text),
    ('M2_8_ACCEPTANCE_SUMMARY'::text,'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL'::text,'1'::text,'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_servicing_execution_archive'::text,'ea3a63d0bd9069cb5c061d09750d8d32'::text,'9'::text,'M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION'::text,'10'::text,'37bd013240b1cd6a5db49a271c0c8cec'::text,'1'::text,'59'::text,'ea3a63d0bd9069cb5c061d09750d8d32'::text,'37bd013240b1cd6a5db49a271c0c8cec'::text,'59'::text,'9716224077ff6b7468c0b7b2fed6ab73'::text,'20'::text,'120'::text,'03b6c0ca3af4ab9d196e09cefa59be3d'::text,'ab32d80ba20c2c8f0a6ec9ec97c2ed26'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M2_8_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id + scenario_id + merchant_application_id'::text,'["module1_run_id","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_servicing_execution_latest'::text,'9716224077ff6b7468c0b7b2fed6ab73'::text,'M2_8_METHOD_V1'::text,'Servicing Execution Simulation, Payment Processing & Account Lifecycle Control'::text,'msbf_ctl.m2_8_servicing_execution_contract_registry'::text,'03b6c0ca3af4ab9d196e09cefa59be3d'::text,'27_M2_8'::text,'M2_7_TO_M2_8'::text,'1'::text,'M2.7=c8e3a472afd2a16b1183677324e9db98'::text,'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1'::text,'M2_8_SERVICING_EXECUTION'::text,'ab32d80ba20c2c8f0a6ec9ec97c2ed26'::text,'367'::text),
    ('M2_9_ACCEPTANCE_SUMMARY'::text,'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'::text,'1'::text,'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_payment_reconciliation_certification_archive'::text,'0bbe110652afd2a01378d36c596e4379'::text,'10'::text,'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'::text,'11'::text,'5976e2e037a53aa184d29b7bcfeaf09e'::text,'1'::text,'59'::text,'0bbe110652afd2a01378d36c596e4379'::text,'5976e2e037a53aa184d29b7bcfeaf09e'::text,'59'::text,'e1206bb355dac10fa8d97a81637ce965'::text,'20'::text,'120'::text,'6df16ccd5d6d7f7bffbc0ca4a2539140'::text,'6af76d0059b47623619ebc09330b15fe'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M2_9_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id + scenario_id + merchant_application_id'::text,'["module1_run_id","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_payment_reconciliation_certification_latest'::text,'e1206bb355dac10fa8d97a81637ce965'::text,'M2_9_METHOD_V1'::text,'Payment Reconciliation, Exception Resolution & Account State Certification'::text,'msbf_ctl.m2_9_reconciliation_certification_contract_registry'::text,'6df16ccd5d6d7f7bffbc0ca4a2539140'::text,'28_M2_9'::text,'M2_8_TO_M2_9'::text,'1'::text,'M2.8=ab32d80ba20c2c8f0a6ec9ec97c2ed26'::text,'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text,'6af76d0059b47623619ebc09330b15fe'::text,'438'::text),
    ('M2_10_ACCEPTANCE_SUMMARY'::text,'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'::text,'1'::text,'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_portfolio_performance_archive'::text,'105691ceca00acc516296b19a64a1c25'::text,'11'::text,'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'::text,'12'::text,'98771133c07f0bdb9828cf233f32ad2f'::text,'1'::text,'59'::text,'105691ceca00acc516296b19a64a1c25'::text,'98771133c07f0bdb9828cf233f32ad2f'::text,'59'::text,'c34f6721bd7a6818d2492d564611ef2a'::text,'20'::text,'120'::text,'944d8f676a5b7fb58700b2a66309f428'::text,'24fca7263a04397ebf21d30639f9069b'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M2_10_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id + scenario_id + merchant_application_id'::text,'["module1_run_id","scenario_id","merchant_application_id"]'::text,'msbf_m2.application_portfolio_performance_latest'::text,'c34f6721bd7a6818d2492d564611ef2a'::text,'M2_10_METHOD_V1'::text,'Portfolio Performance, KPI & Servicing Analytics'::text,'msbf_ctl.m2_10_portfolio_analytics_contract_registry'::text,'944d8f676a5b7fb58700b2a66309f428'::text,'29_M2_10'::text,'M2_9_TO_M2_10'::text,'1'::text,'M2.9=6af76d0059b47623619ebc09330b15fe'::text,'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'::text,'M2_10_PORTFOLIO_ANALYTICS'::text,'24fca7263a04397ebf21d30639f9069b'::text,'370'::text),
    ('M2_11_ACCEPTANCE_SUMMARY'::text,'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'::text,'1'::text,'["module1_run_id","contract_version","strategy_profile_code","reporting_scope_code"]'::text,'msbf_m2.portfolio_strategy_simulation_archive'::text,'641deff3b776faa419cc6c0489f85024'::text,'12'::text,'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'::text,'13'::text,'19f1a9d842c9cb35617ca03e49445aad'::text,'1'::text,'24'::text,'641deff3b776faa419cc6c0489f85024'::text,'19f1a9d842c9cb35617ca03e49445aad'::text,'24'::text,'634a9894d0241505582e0d89e4c5f27b'::text,'20'::text,'120'::text,'61c22f4f3f2e99905d05958fddf80671'::text,'a67d375b9f9248b3eec8160cf3dc656d'::text,'Current run M2_11_ACCEPTED; registry contract_status ACCEPTED; exact acceptance gate PASS at review_version 1; M2_11_ACCEPTANCE_SUMMARY evidence/provenance present; physical canonical and latest/archive identities reconstructed.'::text,'module1_run_id + strategy_profile_code + reporting_scope_code'::text,'["module1_run_id","strategy_profile_code","reporting_scope_code"]'::text,'msbf_m2.portfolio_strategy_simulation_latest'::text,'634a9894d0241505582e0d89e4c5f27b'::text,'M2_11_METHOD_V1'::text,'Portfolio Optimization & Strategy Simulation'::text,'msbf_ctl.m2_11_portfolio_strategy_contract_registry'::text,'61c22f4f3f2e99905d05958fddf80671'::text,'30_M2_11'::text,'M1_17_TO_M2_11|M2_2_TO_M2_11|M2_4_TO_M2_11|M2_7_TO_M2_11|M2_10_TO_M2_11'::text,'5'::text,'M1.17=7d9e466da28cad2551aa99c4c40c912b|M2.2=bbe83b187b31ea561789797322031fc6|M2.4=117450a3eea7bb3d3c74d18cc3c8e96a|M2.7=c8e3a472afd2a16b1183677324e9db98|M2.10=24fca7263a04397ebf21d30639f9069b'::text,'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1'::text,'M2_11_STRATEGY_SIMULATION'::text,'a67d375b9f9248b3eec8160cf3dc656d'::text,'19298'::text)) AS v(acceptance_evidence_code,acceptance_gate_id,acceptance_gate_review_version,archive_business_key_columns,archive_relation,archive_set_hash,certification_node_sequence,component_contract_code,component_sequence,contract_set_hash,contract_version,expected_archive_rows,expected_archive_set_hash,expected_contract_set_hash,expected_latest_rows,expected_latest_set_hash,expected_negative_controls,expected_positive_controls,expected_registry_row_hash,expected_stage_combined_set_hash,historical_acceptance_method,latest_business_grain,latest_business_key_columns,latest_relation,latest_set_hash,methodology_version,module_title,registry_relation,registry_row_hash,repository_stage,required_source_edge_codes,required_source_edge_count,required_source_hash_graph,schema_version,stage_code,stage_combined_set_hash,stage_expected_canonical_entities)
CROSS JOIN tmp_src_m2_12_run_context ctx;

/* R10 GOVERNED STATEMENT 0020 OF 0206
   statement_code: ASSERT_TMP_SRC_M2_12_COMPONENT_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_src_m2_12_component_design$ BEGIN IF (SELECT count(*) FROM tmp_src_m2_12_component_design) <> 13 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_src_m2_12_component_design', DETAIL='expected=13 observed='||(SELECT count(*) FROM tmp_src_m2_12_component_design)::text; END IF; END; $m212_r7_tmp_src_m2_12_component_design$;

/* R10 GOVERNED STATEMENT 0021 OF 0206
   statement_code: INDEX_TMP_SRC_M2_12_COMPONENT_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_component_design_905a0c20 ON tmp_src_m2_12_component_design (module1_run_id, component_sequence);

/* R10 GOVERNED STATEMENT 0022 OF 0206
   statement_code: ANALYZE_TMP_SRC_M2_12_COMPONENT_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_component_design;

/* R10 GOVERNED STATEMENT 0023 OF 0206
   statement_code: CREATE_TMP_SRC_M2_12_COMPONENT_EDGE_REQUIREMENT
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_component_edge_requirement ON COMMIT DROP AS
SELECT v.certification_node_sequence::smallint AS certification_node_sequence,
       v.component_contract_code::text AS component_contract_code,
       v.component_sequence::smallint AS component_sequence,
       v.contract_version::integer AS contract_version,
       v.edge_code::text AS edge_code,
       ctx.module1_run_id::bigint AS module1_run_id,
       v.required_status::text AS required_status,
       v.requirement_sequence::smallint AS requirement_sequence,
       v.stage_code::text AS stage_code
FROM (VALUES
    ('1'::text,'M1_G2_CONSUMPTION_BUNDLE'::text,'1'::text,'1'::text,'M1_15_TO_M1_17_APPLICATION_CONTRACT'::text,'PASS'::text,'1'::text,'M1_17_G2_FOUNDATION'::text),
    ('1'::text,'M1_G2_CONSUMPTION_BUNDLE'::text,'1'::text,'1'::text,'M1_16_TO_M1_17_ACQUISITION_CONTRACT'::text,'PASS'::text,'2'::text,'M1_17_G2_FOUNDATION'::text),
    ('2'::text,'M2_ELIGIBILITY_ROUTING_CONSUMPTION'::text,'2'::text,'1'::text,'M1_17_TO_M2_1'::text,'PASS'::text,'3'::text,'M2_1_ELIGIBILITY_ROUTING'::text),
    ('3'::text,'M2_REQUEST_STRUCTURE_CONSUMPTION'::text,'3'::text,'1'::text,'M2_1_TO_M2_2'::text,'PASS'::text,'4'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('3'::text,'M2_REQUEST_STRUCTURE_CONSUMPTION'::text,'3'::text,'1'::text,'M1_3_TO_M2_2_REQUEST_AUTHORITY'::text,'PASS'::text,'5'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('3'::text,'M2_PRICING_STRUCTURE_CONSUMPTION'::text,'4'::text,'1'::text,'M2_1_TO_M2_2'::text,'PASS'::text,'6'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('3'::text,'M2_PRICING_STRUCTURE_CONSUMPTION'::text,'4'::text,'1'::text,'M1_3_TO_M2_2_REQUEST_AUTHORITY'::text,'PASS'::text,'7'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('4'::text,'M2_FINAL_OFFER_DECISION_CONSUMPTION'::text,'5'::text,'1'::text,'M2_2_TO_M2_3'::text,'PASS'::text,'8'::text,'M2_3_FINAL_DECISION'::text),
    ('5'::text,'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'::text,'6'::text,'1'::text,'M2_3_TO_M2_4'::text,'PASS'::text,'9'::text,'M2_4_PORTFOLIO_ACTIVATION'::text),
    ('6'::text,'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'::text,'7'::text,'1'::text,'M2_4_TO_M2_5'::text,'PASS'::text,'10'::text,'M2_5_DAILY_MONITORING'::text),
    ('6'::text,'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'::text,'7'::text,'1'::text,'M1_6_TO_M2_5_SCENARIO_AUTHORITY'::text,'PASS'::text,'11'::text,'M2_5_DAILY_MONITORING'::text),
    ('7'::text,'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'::text,'8'::text,'1'::text,'M2_5_TO_M2_6'::text,'PASS'::text,'12'::text,'M2_6_INTERVENTION_STRATEGY'::text),
    ('8'::text,'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'::text,'9'::text,'1'::text,'M2_6_TO_M2_7'::text,'PASS'::text,'13'::text,'M2_7_OPERATIONAL_ACTIVATION'::text),
    ('9'::text,'M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION'::text,'10'::text,'1'::text,'M2_7_TO_M2_8'::text,'PASS'::text,'14'::text,'M2_8_SERVICING_EXECUTION'::text),
    ('10'::text,'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'::text,'11'::text,'1'::text,'M2_8_TO_M2_9'::text,'PASS'::text,'15'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text),
    ('11'::text,'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'::text,'12'::text,'1'::text,'M2_9_TO_M2_10'::text,'PASS'::text,'16'::text,'M2_10_PORTFOLIO_ANALYTICS'::text),
    ('12'::text,'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'::text,'13'::text,'1'::text,'M1_17_TO_M2_11'::text,'PASS'::text,'17'::text,'M2_11_STRATEGY_SIMULATION'::text),
    ('12'::text,'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'::text,'13'::text,'1'::text,'M2_2_TO_M2_11'::text,'PASS'::text,'18'::text,'M2_11_STRATEGY_SIMULATION'::text),
    ('12'::text,'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'::text,'13'::text,'1'::text,'M2_4_TO_M2_11'::text,'PASS'::text,'19'::text,'M2_11_STRATEGY_SIMULATION'::text),
    ('12'::text,'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'::text,'13'::text,'1'::text,'M2_7_TO_M2_11'::text,'PASS'::text,'20'::text,'M2_11_STRATEGY_SIMULATION'::text),
    ('12'::text,'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'::text,'13'::text,'1'::text,'M2_10_TO_M2_11'::text,'PASS'::text,'21'::text,'M2_11_STRATEGY_SIMULATION'::text)) AS v(certification_node_sequence,component_contract_code,component_sequence,contract_version,edge_code,required_status,requirement_sequence,stage_code)
CROSS JOIN tmp_src_m2_12_run_context ctx;

/* R10 GOVERNED STATEMENT 0024 OF 0206
   statement_code: ASSERT_TMP_SRC_M2_12_COMPONENT_EDGE_REQUIREMENT
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_src_m2_12_component_edge_requirement$ BEGIN IF (SELECT count(*) FROM tmp_src_m2_12_component_edge_requirement) <> 21 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_src_m2_12_component_edge_requirement', DETAIL='expected=21 observed='||(SELECT count(*) FROM tmp_src_m2_12_component_edge_requirement)::text; END IF; END; $m212_r7_tmp_src_m2_12_component_edge_requirement$;

/* R10 GOVERNED STATEMENT 0025 OF 0206
   statement_code: INDEX_TMP_SRC_M2_12_COMPONENT_EDGE_REQUIREMENT
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_component_edge_requirement_030469fa ON tmp_src_m2_12_component_edge_requirement (module1_run_id, component_sequence, edge_code);

/* R10 GOVERNED STATEMENT 0026 OF 0206
   statement_code: ANALYZE_TMP_SRC_M2_12_COMPONENT_EDGE_REQUIREMENT
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_component_edge_requirement;

/* R10 GOVERNED STATEMENT 0027 OF 0206
   statement_code: CREATE_TMP_SRC_M2_12_EVIDENCE_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_evidence_design ON COMMIT DROP AS
SELECT v.allowed_certification_status::text AS allowed_certification_status,
       v.applicability_code::text AS applicability_code,
       v.authoritative_source_locator::text AS authoritative_source_locator,
       v.evidence_code_or_method_pattern::text AS evidence_code_or_method_pattern,
       v.evidence_family_code::text AS evidence_family_code,
       v.evidence_family_sequence::smallint AS evidence_family_sequence,
       v.expected_count_or_identity::text AS expected_count_or_identity,
       v.expected_hash::text AS expected_hash,
       v.expected_status::text AS expected_status,
       v.matrix_sequence::smallint AS matrix_sequence,
       ctx.module1_run_id::bigint AS module1_run_id,
       v.node_sequence::smallint AS node_sequence,
       v.rationale::text AS rationale,
       v.stage_code::text AS stage_code
FROM (VALUES
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m1_17_g2_bundle_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence'::text,'M1_17_ACCEPTANCE_SUMMARY'::text,'ACCEPTANCE_LIFECYCLE'::text,'1'::text,'1 registry accepted | 1 gate PASS | 1 acceptance summary'::text,'7d9e466da28cad2551aa99c4c40c912b'::text,'PASS'::text,'1'::text,'1'::text,'Contract registry, exact acceptance gate review version 1, and accepted evidence/provenance jointly prove stage acceptance; historical run status is not assumed to be retained per stage.'::text,'M1_17_G2_FOUNDATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M1_17_POS_%'::text,'POSITIVE_VALIDATION'::text,'2'::text,'128'::text,NULL::text,'PASS'::text,'2'::text,'1'::text,'All 128 governed positive-control evidence rows are mandatory PASS.'::text,'M1_17_G2_FOUNDATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M1_17_NEG_%'::text,'NEGATIVE_CONTROLS'::text,'3'::text,'20'::text,NULL::text,'PASS'::text,'3'::text,'1'::text,'All 20 governed negative-control evidence rows are mandatory PASS.'::text,'M1_17_G2_FOUNDATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m1_17_g2_bundle_registry'::text,'PHYSICAL_CANONICAL_RECONSTRUCTION'::text,'CANONICAL_IDENTITY'::text,'4'::text,'69'::text,'7d9e466da28cad2551aa99c4c40c912b'::text,'PASS'::text,'4'::text,'1'::text,'Reconstruct the stage canonical identity from accepted physical rows using the strongest stage-specific method and reconcile to the registry.'::text,'M1_17_G2_FOUNDATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m1_17_g2_bundle_latest|msbf_ctl.m1_17_g2_bundle_archive'::text,'EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION'::text,'LATEST_ARCHIVE_REPRODUCTION'::text,'5'::text,'1 latest | 1 archive | 0 mismatches'::text,NULL::text,'PASS'::text,'5'::text,'1'::text,'All 1 component contract(s) for the node must reproduce latest to immutable archive exactly.'::text,'M1_17_G2_FOUNDATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m1_17_g2_bundle_registry|msbf_ctl.run_evidence|accepted detail-report boundary output'::text,'M1_17_%BOUNDARY%|M1_17_%BLOCKING%'::text,'STAGE_BOUNDARY'::text,'6'::text,'0 blocking or stage-boundary findings'::text,NULL::text,'PASS'::text,'6'::text,'1'::text,'No accepted stage may contain prohibited production action, unauthorized source, premature downstream object, or unresolved boundary finding.'::text,'M1_17_G2_FOUNDATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_1_strategy_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence'::text,'M2_1_ACCEPTANCE_SUMMARY'::text,'ACCEPTANCE_LIFECYCLE'::text,'1'::text,'1 registry accepted | 1 gate PASS | 1 acceptance summary'::text,'e5ace7f32060ffb191c7bd0f8dd0c863'::text,'PASS'::text,'7'::text,'2'::text,'Contract registry, exact acceptance gate review version 1, and accepted evidence/provenance jointly prove stage acceptance; historical run status is not assumed to be retained per stage.'::text,'M2_1_ELIGIBILITY_ROUTING'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_1_POS_%'::text,'POSITIVE_VALIDATION'::text,'2'::text,'112'::text,NULL::text,'PASS'::text,'8'::text,'2'::text,'All 112 governed positive-control evidence rows are mandatory PASS.'::text,'M2_1_ELIGIBILITY_ROUTING'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_1_NEG_%'::text,'NEGATIVE_CONTROLS'::text,'3'::text,'20'::text,NULL::text,'PASS'::text,'9'::text,'2'::text,'All 20 governed negative-control evidence rows are mandatory PASS.'::text,'M2_1_ELIGIBILITY_ROUTING'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_1_strategy_contract_registry'::text,'PHYSICAL_CANONICAL_RECONSTRUCTION'::text,'CANONICAL_IDENTITY'::text,'4'::text,'22541'::text,'e5ace7f32060ffb191c7bd0f8dd0c863'::text,'PASS'::text,'10'::text,'2'::text,'Reconstruct the stage canonical identity from accepted physical rows using the strongest stage-specific method and reconcile to the registry.'::text,'M2_1_ELIGIBILITY_ROUTING'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_m2.application_eligibility_routing_latest|msbf_m2.application_eligibility_routing_archive'::text,'EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION'::text,'LATEST_ARCHIVE_REPRODUCTION'::text,'5'::text,'1500 latest | 1500 archive | 0 mismatches'::text,NULL::text,'PASS'::text,'11'::text,'2'::text,'All 1 component contract(s) for the node must reproduce latest to immutable archive exactly.'::text,'M2_1_ELIGIBILITY_ROUTING'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_1_strategy_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output'::text,'M2_1_%BOUNDARY%|M2_1_%BLOCKING%'::text,'STAGE_BOUNDARY'::text,'6'::text,'0 blocking or stage-boundary findings'::text,NULL::text,'PASS'::text,'12'::text,'2'::text,'No accepted stage may contain prohibited production action, unauthorized source, premature downstream object, or unresolved boundary finding.'::text,'M2_1_ELIGIBILITY_ROUTING'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_2_pricing_structure_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence'::text,'M2_2_ACCEPTANCE_SUMMARY'::text,'ACCEPTANCE_LIFECYCLE'::text,'1'::text,'1 registry accepted | 1 gate PASS | 1 acceptance summary'::text,'bbe83b187b31ea561789797322031fc6'::text,'PASS'::text,'13'::text,'3'::text,'Contract registry, exact acceptance gate review version 1, and accepted evidence/provenance jointly prove stage acceptance; historical run status is not assumed to be retained per stage.'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_2_POS_%'::text,'POSITIVE_VALIDATION'::text,'2'::text,'120'::text,NULL::text,'PASS'::text,'14'::text,'3'::text,'All 120 governed positive-control evidence rows are mandatory PASS.'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_2_NEG_%'::text,'NEGATIVE_CONTROLS'::text,'3'::text,'20'::text,NULL::text,'PASS'::text,'15'::text,'3'::text,'All 20 governed negative-control evidence rows are mandatory PASS.'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_2_pricing_structure_contract_registry'::text,'PHYSICAL_CANONICAL_RECONSTRUCTION'::text,'CANONICAL_IDENTITY'::text,'4'::text,'7336'::text,'bbe83b187b31ea561789797322031fc6'::text,'PASS'::text,'16'::text,'3'::text,'Reconstruct the stage canonical identity from accepted physical rows using the strongest stage-specific method and reconcile to the registry.'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_m2.application_request_structure_latest|msbf_m2.application_pricing_structure_latest|msbf_m2.application_request_structure_archive|msbf_m2.application_pricing_structure_archive'::text,'EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION'::text,'LATEST_ARCHIVE_REPRODUCTION'::text,'5'::text,'2250 latest | 2250 archive | 0 mismatches'::text,NULL::text,'PASS'::text,'17'::text,'3'::text,'All 2 component contract(s) for the node must reproduce latest to immutable archive exactly.'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_2_pricing_structure_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output'::text,'M2_2_%BOUNDARY%|M2_2_%BLOCKING%'::text,'STAGE_BOUNDARY'::text,'6'::text,'0 blocking or stage-boundary findings'::text,NULL::text,'PASS'::text,'18'::text,'3'::text,'No accepted stage may contain prohibited production action, unauthorized source, premature downstream object, or unresolved boundary finding.'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_3_final_decision_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence'::text,'M2_3_ACCEPTANCE_SUMMARY'::text,'ACCEPTANCE_LIFECYCLE'::text,'1'::text,'1 registry accepted | 1 gate PASS | 1 acceptance summary'::text,'bf09349b06ede7e5a2ec830c2f9ffe90'::text,'PASS'::text,'19'::text,'4'::text,'Contract registry, exact acceptance gate review version 1, and accepted evidence/provenance jointly prove stage acceptance; historical run status is not assumed to be retained per stage.'::text,'M2_3_FINAL_DECISION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_3_POS_%'::text,'POSITIVE_VALIDATION'::text,'2'::text,'120'::text,NULL::text,'PASS'::text,'20'::text,'4'::text,'All 120 governed positive-control evidence rows are mandatory PASS.'::text,'M2_3_FINAL_DECISION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_3_NEG_%'::text,'NEGATIVE_CONTROLS'::text,'3'::text,'20'::text,NULL::text,'PASS'::text,'21'::text,'4'::text,'All 20 governed negative-control evidence rows are mandatory PASS.'::text,'M2_3_FINAL_DECISION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_3_final_decision_contract_registry'::text,'PHYSICAL_CANONICAL_RECONSTRUCTION'::text,'CANONICAL_IDENTITY'::text,'4'::text,'6029'::text,'bf09349b06ede7e5a2ec830c2f9ffe90'::text,'PASS'::text,'22'::text,'4'::text,'Reconstruct the stage canonical identity from accepted physical rows using the strongest stage-specific method and reconcile to the registry.'::text,'M2_3_FINAL_DECISION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_m2.application_final_offer_decision_latest|msbf_m2.application_final_offer_decision_archive'::text,'EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION'::text,'LATEST_ARCHIVE_REPRODUCTION'::text,'5'::text,'1500 latest | 1500 archive | 0 mismatches'::text,NULL::text,'PASS'::text,'23'::text,'4'::text,'All 1 component contract(s) for the node must reproduce latest to immutable archive exactly.'::text,'M2_3_FINAL_DECISION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_3_final_decision_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output'::text,'M2_3_%BOUNDARY%|M2_3_%BLOCKING%'::text,'STAGE_BOUNDARY'::text,'6'::text,'0 blocking or stage-boundary findings'::text,NULL::text,'PASS'::text,'24'::text,'4'::text,'No accepted stage may contain prohibited production action, unauthorized source, premature downstream object, or unresolved boundary finding.'::text,'M2_3_FINAL_DECISION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_4_portfolio_activation_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence'::text,'M2_4_ACCEPTANCE_SUMMARY'::text,'ACCEPTANCE_LIFECYCLE'::text,'1'::text,'1 registry accepted | 1 gate PASS | 1 acceptance summary'::text,'117450a3eea7bb3d3c74d18cc3c8e96a'::text,'PASS'::text,'25'::text,'5'::text,'Contract registry, exact acceptance gate review version 1, and accepted evidence/provenance jointly prove stage acceptance; historical run status is not assumed to be retained per stage.'::text,'M2_4_PORTFOLIO_ACTIVATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_4_POS_%'::text,'POSITIVE_VALIDATION'::text,'2'::text,'120'::text,NULL::text,'PASS'::text,'26'::text,'5'::text,'All 120 governed positive-control evidence rows are mandatory PASS.'::text,'M2_4_PORTFOLIO_ACTIVATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_4_NEG_%'::text,'NEGATIVE_CONTROLS'::text,'3'::text,'20'::text,NULL::text,'PASS'::text,'27'::text,'5'::text,'All 20 governed negative-control evidence rows are mandatory PASS.'::text,'M2_4_PORTFOLIO_ACTIVATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_4_portfolio_activation_contract_registry'::text,'PHYSICAL_CANONICAL_RECONSTRUCTION'::text,'CANONICAL_IDENTITY'::text,'4'::text,'6212'::text,'117450a3eea7bb3d3c74d18cc3c8e96a'::text,'PASS'::text,'28'::text,'5'::text,'Reconstruct the stage canonical identity from accepted physical rows using the strongest stage-specific method and reconcile to the registry.'::text,'M2_4_PORTFOLIO_ACTIVATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_m2.application_booking_funding_activation_latest|msbf_m2.application_booking_funding_activation_archive'::text,'EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION'::text,'LATEST_ARCHIVE_REPRODUCTION'::text,'5'::text,'1500 latest | 1500 archive | 0 mismatches'::text,NULL::text,'PASS'::text,'29'::text,'5'::text,'All 1 component contract(s) for the node must reproduce latest to immutable archive exactly.'::text,'M2_4_PORTFOLIO_ACTIVATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_4_portfolio_activation_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output'::text,'M2_4_%BOUNDARY%|M2_4_%BLOCKING%'::text,'STAGE_BOUNDARY'::text,'6'::text,'0 blocking or stage-boundary findings'::text,NULL::text,'PASS'::text,'30'::text,'5'::text,'No accepted stage may contain prohibited production action, unauthorized source, premature downstream object, or unresolved boundary finding.'::text,'M2_4_PORTFOLIO_ACTIVATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_5_portfolio_monitoring_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence'::text,'M2_5_ACCEPTANCE_SUMMARY'::text,'ACCEPTANCE_LIFECYCLE'::text,'1'::text,'1 registry accepted | 1 gate PASS | 1 acceptance summary'::text,'18e1c444aa1b02ee5bd3539d7c477adc'::text,'PASS'::text,'31'::text,'6'::text,'Contract registry, exact acceptance gate review version 1, and accepted evidence/provenance jointly prove stage acceptance; historical run status is not assumed to be retained per stage.'::text,'M2_5_DAILY_MONITORING'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_5_POS_%'::text,'POSITIVE_VALIDATION'::text,'2'::text,'120'::text,NULL::text,'PASS'::text,'32'::text,'6'::text,'All 120 governed positive-control evidence rows are mandatory PASS.'::text,'M2_5_DAILY_MONITORING'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_5_NEG_%'::text,'NEGATIVE_CONTROLS'::text,'3'::text,'20'::text,NULL::text,'PASS'::text,'33'::text,'6'::text,'All 20 governed negative-control evidence rows are mandatory PASS.'::text,'M2_5_DAILY_MONITORING'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_5_portfolio_monitoring_contract_registry'::text,'PHYSICAL_CANONICAL_RECONSTRUCTION'::text,'CANONICAL_IDENTITY'::text,'4'::text,'7536'::text,'18e1c444aa1b02ee5bd3539d7c477adc'::text,'PASS'::text,'34'::text,'6'::text,'Reconstruct the stage canonical identity from accepted physical rows using the strongest stage-specific method and reconcile to the registry.'::text,'M2_5_DAILY_MONITORING'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_m2.advance_portfolio_monitoring_latest|msbf_m2.advance_portfolio_monitoring_archive'::text,'EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION'::text,'LATEST_ARCHIVE_REPRODUCTION'::text,'5'::text,'59 latest | 59 archive | 0 mismatches'::text,NULL::text,'PASS'::text,'35'::text,'6'::text,'All 1 component contract(s) for the node must reproduce latest to immutable archive exactly.'::text,'M2_5_DAILY_MONITORING'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_5_portfolio_monitoring_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output'::text,'M2_5_%BOUNDARY%|M2_5_%BLOCKING%'::text,'STAGE_BOUNDARY'::text,'6'::text,'0 blocking or stage-boundary findings'::text,NULL::text,'PASS'::text,'36'::text,'6'::text,'No accepted stage may contain prohibited production action, unauthorized source, premature downstream object, or unresolved boundary finding.'::text,'M2_5_DAILY_MONITORING'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_6_intervention_strategy_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence'::text,'M2_6_ACCEPTANCE_SUMMARY'::text,'ACCEPTANCE_LIFECYCLE'::text,'1'::text,'1 registry accepted | 1 gate PASS | 1 acceptance summary'::text,'868125bff29270490cab4d2e55cb1388'::text,'PASS'::text,'37'::text,'7'::text,'Contract registry, exact acceptance gate review version 1, and accepted evidence/provenance jointly prove stage acceptance; historical run status is not assumed to be retained per stage.'::text,'M2_6_INTERVENTION_STRATEGY'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_6_POS_%'::text,'POSITIVE_VALIDATION'::text,'2'::text,'120'::text,NULL::text,'PASS'::text,'38'::text,'7'::text,'All 120 governed positive-control evidence rows are mandatory PASS.'::text,'M2_6_INTERVENTION_STRATEGY'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_6_NEG_%'::text,'NEGATIVE_CONTROLS'::text,'3'::text,'20'::text,NULL::text,'PASS'::text,'39'::text,'7'::text,'All 20 governed negative-control evidence rows are mandatory PASS.'::text,'M2_6_INTERVENTION_STRATEGY'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_6_intervention_strategy_contract_registry'::text,'PHYSICAL_CANONICAL_RECONSTRUCTION'::text,'CANONICAL_IDENTITY'::text,'4'::text,'284'::text,'868125bff29270490cab4d2e55cb1388'::text,'PASS'::text,'40'::text,'7'::text,'Reconstruct the stage canonical identity from accepted physical rows using the strongest stage-specific method and reconcile to the registry.'::text,'M2_6_INTERVENTION_STRATEGY'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_m2.advance_intervention_strategy_latest|msbf_m2.advance_intervention_strategy_archive'::text,'EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION'::text,'LATEST_ARCHIVE_REPRODUCTION'::text,'5'::text,'59 latest | 59 archive | 0 mismatches'::text,NULL::text,'PASS'::text,'41'::text,'7'::text,'All 1 component contract(s) for the node must reproduce latest to immutable archive exactly.'::text,'M2_6_INTERVENTION_STRATEGY'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_6_intervention_strategy_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output'::text,'M2_6_%BOUNDARY%|M2_6_%BLOCKING%'::text,'STAGE_BOUNDARY'::text,'6'::text,'0 blocking or stage-boundary findings'::text,NULL::text,'PASS'::text,'42'::text,'7'::text,'No accepted stage may contain prohibited production action, unauthorized source, premature downstream object, or unresolved boundary finding.'::text,'M2_6_INTERVENTION_STRATEGY'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_7_operational_activation_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence'::text,'M2_7_ACCEPTANCE_SUMMARY'::text,'ACCEPTANCE_LIFECYCLE'::text,'1'::text,'1 registry accepted | 1 gate PASS | 1 acceptance summary'::text,'c8e3a472afd2a16b1183677324e9db98'::text,'PASS'::text,'43'::text,'8'::text,'Contract registry, exact acceptance gate review version 1, and accepted evidence/provenance jointly prove stage acceptance; historical run status is not assumed to be retained per stage.'::text,'M2_7_OPERATIONAL_ACTIVATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_7_POS_%'::text,'POSITIVE_VALIDATION'::text,'2'::text,'120'::text,NULL::text,'PASS'::text,'44'::text,'8'::text,'All 120 governed positive-control evidence rows are mandatory PASS.'::text,'M2_7_OPERATIONAL_ACTIVATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_7_NEG_%'::text,'NEGATIVE_CONTROLS'::text,'3'::text,'20'::text,NULL::text,'PASS'::text,'45'::text,'8'::text,'All 20 governed negative-control evidence rows are mandatory PASS.'::text,'M2_7_OPERATIONAL_ACTIVATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_7_operational_activation_contract_registry'::text,'PHYSICAL_CANONICAL_RECONSTRUCTION'::text,'CANONICAL_IDENTITY'::text,'4'::text,'341'::text,'c8e3a472afd2a16b1183677324e9db98'::text,'PASS'::text,'46'::text,'8'::text,'Reconstruct the stage canonical identity from accepted physical rows using the strongest stage-specific method and reconcile to the registry.'::text,'M2_7_OPERATIONAL_ACTIVATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_m2.application_operational_activation_latest|msbf_m2.application_operational_activation_archive'::text,'EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION'::text,'LATEST_ARCHIVE_REPRODUCTION'::text,'5'::text,'59 latest | 59 archive | 0 mismatches'::text,NULL::text,'PASS'::text,'47'::text,'8'::text,'All 1 component contract(s) for the node must reproduce latest to immutable archive exactly.'::text,'M2_7_OPERATIONAL_ACTIVATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_7_operational_activation_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output'::text,'M2_7_%BOUNDARY%|M2_7_%BLOCKING%'::text,'STAGE_BOUNDARY'::text,'6'::text,'0 blocking or stage-boundary findings'::text,NULL::text,'PASS'::text,'48'::text,'8'::text,'No accepted stage may contain prohibited production action, unauthorized source, premature downstream object, or unresolved boundary finding.'::text,'M2_7_OPERATIONAL_ACTIVATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_8_servicing_execution_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence'::text,'M2_8_ACCEPTANCE_SUMMARY'::text,'ACCEPTANCE_LIFECYCLE'::text,'1'::text,'1 registry accepted | 1 gate PASS | 1 acceptance summary'::text,'ab32d80ba20c2c8f0a6ec9ec97c2ed26'::text,'PASS'::text,'49'::text,'9'::text,'Contract registry, exact acceptance gate review version 1, and accepted evidence/provenance jointly prove stage acceptance; historical run status is not assumed to be retained per stage.'::text,'M2_8_SERVICING_EXECUTION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_8_POS_%'::text,'POSITIVE_VALIDATION'::text,'2'::text,'120'::text,NULL::text,'PASS'::text,'50'::text,'9'::text,'All 120 governed positive-control evidence rows are mandatory PASS.'::text,'M2_8_SERVICING_EXECUTION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_8_NEG_%'::text,'NEGATIVE_CONTROLS'::text,'3'::text,'20'::text,NULL::text,'PASS'::text,'51'::text,'9'::text,'All 20 governed negative-control evidence rows are mandatory PASS.'::text,'M2_8_SERVICING_EXECUTION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_8_servicing_execution_contract_registry'::text,'PHYSICAL_CANONICAL_RECONSTRUCTION'::text,'CANONICAL_IDENTITY'::text,'4'::text,'367'::text,'ab32d80ba20c2c8f0a6ec9ec97c2ed26'::text,'PASS'::text,'52'::text,'9'::text,'Reconstruct the stage canonical identity from accepted physical rows using the strongest stage-specific method and reconcile to the registry.'::text,'M2_8_SERVICING_EXECUTION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_m2.application_servicing_execution_latest|msbf_m2.application_servicing_execution_archive'::text,'EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION'::text,'LATEST_ARCHIVE_REPRODUCTION'::text,'5'::text,'59 latest | 59 archive | 0 mismatches'::text,NULL::text,'PASS'::text,'53'::text,'9'::text,'All 1 component contract(s) for the node must reproduce latest to immutable archive exactly.'::text,'M2_8_SERVICING_EXECUTION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_8_servicing_execution_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output'::text,'M2_8_%BOUNDARY%|M2_8_%BLOCKING%'::text,'STAGE_BOUNDARY'::text,'6'::text,'0 blocking or stage-boundary findings'::text,NULL::text,'PASS'::text,'54'::text,'9'::text,'No accepted stage may contain prohibited production action, unauthorized source, premature downstream object, or unresolved boundary finding.'::text,'M2_8_SERVICING_EXECUTION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_9_reconciliation_certification_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence'::text,'M2_9_ACCEPTANCE_SUMMARY'::text,'ACCEPTANCE_LIFECYCLE'::text,'1'::text,'1 registry accepted | 1 gate PASS | 1 acceptance summary'::text,'6af76d0059b47623619ebc09330b15fe'::text,'PASS'::text,'55'::text,'10'::text,'Contract registry, exact acceptance gate review version 1, and accepted evidence/provenance jointly prove stage acceptance; historical run status is not assumed to be retained per stage.'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_9_POS_%'::text,'POSITIVE_VALIDATION'::text,'2'::text,'120'::text,NULL::text,'PASS'::text,'56'::text,'10'::text,'All 120 governed positive-control evidence rows are mandatory PASS.'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_9_NEG_%'::text,'NEGATIVE_CONTROLS'::text,'3'::text,'20'::text,NULL::text,'PASS'::text,'57'::text,'10'::text,'All 20 governed negative-control evidence rows are mandatory PASS.'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_9_reconciliation_certification_contract_registry'::text,'PHYSICAL_CANONICAL_RECONSTRUCTION'::text,'CANONICAL_IDENTITY'::text,'4'::text,'438'::text,'6af76d0059b47623619ebc09330b15fe'::text,'PASS'::text,'58'::text,'10'::text,'Reconstruct the stage canonical identity from accepted physical rows using the strongest stage-specific method and reconcile to the registry.'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_m2.application_payment_reconciliation_certification_latest|msbf_m2.application_payment_reconciliation_certification_archive'::text,'EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION'::text,'LATEST_ARCHIVE_REPRODUCTION'::text,'5'::text,'59 latest | 59 archive | 0 mismatches'::text,NULL::text,'PASS'::text,'59'::text,'10'::text,'All 1 component contract(s) for the node must reproduce latest to immutable archive exactly.'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_9_reconciliation_certification_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output'::text,'M2_9_%BOUNDARY%|M2_9_%BLOCKING%'::text,'STAGE_BOUNDARY'::text,'6'::text,'0 blocking or stage-boundary findings'::text,NULL::text,'PASS'::text,'60'::text,'10'::text,'No accepted stage may contain prohibited production action, unauthorized source, premature downstream object, or unresolved boundary finding.'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_10_portfolio_analytics_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence'::text,'M2_10_ACCEPTANCE_SUMMARY'::text,'ACCEPTANCE_LIFECYCLE'::text,'1'::text,'1 registry accepted | 1 gate PASS | 1 acceptance summary'::text,'24fca7263a04397ebf21d30639f9069b'::text,'PASS'::text,'61'::text,'11'::text,'Contract registry, exact acceptance gate review version 1, and accepted evidence/provenance jointly prove stage acceptance; historical run status is not assumed to be retained per stage.'::text,'M2_10_PORTFOLIO_ANALYTICS'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_10_POS_%'::text,'POSITIVE_VALIDATION'::text,'2'::text,'120'::text,NULL::text,'PASS'::text,'62'::text,'11'::text,'All 120 governed positive-control evidence rows are mandatory PASS.'::text,'M2_10_PORTFOLIO_ANALYTICS'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_10_NEG_%'::text,'NEGATIVE_CONTROLS'::text,'3'::text,'20'::text,NULL::text,'PASS'::text,'63'::text,'11'::text,'All 20 governed negative-control evidence rows are mandatory PASS.'::text,'M2_10_PORTFOLIO_ANALYTICS'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_10_portfolio_analytics_contract_registry'::text,'PHYSICAL_CANONICAL_RECONSTRUCTION'::text,'CANONICAL_IDENTITY'::text,'4'::text,'370'::text,'24fca7263a04397ebf21d30639f9069b'::text,'PASS'::text,'64'::text,'11'::text,'Reconstruct the stage canonical identity from accepted physical rows using the strongest stage-specific method and reconcile to the registry.'::text,'M2_10_PORTFOLIO_ANALYTICS'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_m2.application_portfolio_performance_latest|msbf_m2.application_portfolio_performance_archive'::text,'EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION'::text,'LATEST_ARCHIVE_REPRODUCTION'::text,'5'::text,'59 latest | 59 archive | 0 mismatches'::text,NULL::text,'PASS'::text,'65'::text,'11'::text,'All 1 component contract(s) for the node must reproduce latest to immutable archive exactly.'::text,'M2_10_PORTFOLIO_ANALYTICS'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_10_portfolio_analytics_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output'::text,'M2_10_%BOUNDARY%|M2_10_%BLOCKING%'::text,'STAGE_BOUNDARY'::text,'6'::text,'0 blocking or stage-boundary findings'::text,NULL::text,'PASS'::text,'66'::text,'11'::text,'No accepted stage may contain prohibited production action, unauthorized source, premature downstream object, or unresolved boundary finding.'::text,'M2_10_PORTFOLIO_ANALYTICS'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_11_portfolio_strategy_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence'::text,'M2_11_ACCEPTANCE_SUMMARY'::text,'ACCEPTANCE_LIFECYCLE'::text,'1'::text,'1 registry accepted | 1 gate PASS | 1 acceptance summary'::text,'a67d375b9f9248b3eec8160cf3dc656d'::text,'PASS'::text,'67'::text,'12'::text,'Contract registry, exact acceptance gate review version 1, and accepted evidence/provenance jointly prove stage acceptance; historical run status is not assumed to be retained per stage.'::text,'M2_11_STRATEGY_SIMULATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_11_POS_%'::text,'POSITIVE_VALIDATION'::text,'2'::text,'120'::text,NULL::text,'PASS'::text,'68'::text,'12'::text,'All 120 governed positive-control evidence rows are mandatory PASS.'::text,'M2_11_STRATEGY_SIMULATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.run_evidence'::text,'M2_11_NEG_%'::text,'NEGATIVE_CONTROLS'::text,'3'::text,'20'::text,NULL::text,'PASS'::text,'69'::text,'12'::text,'All 20 governed negative-control evidence rows are mandatory PASS.'::text,'M2_11_STRATEGY_SIMULATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_11_portfolio_strategy_contract_registry'::text,'PHYSICAL_CANONICAL_RECONSTRUCTION'::text,'CANONICAL_IDENTITY'::text,'4'::text,'19298'::text,'a67d375b9f9248b3eec8160cf3dc656d'::text,'PASS'::text,'70'::text,'12'::text,'Reconstruct the stage canonical identity from accepted physical rows using the strongest stage-specific method and reconcile to the registry.'::text,'M2_11_STRATEGY_SIMULATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_m2.portfolio_strategy_simulation_latest|msbf_m2.portfolio_strategy_simulation_archive'::text,'EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION'::text,'LATEST_ARCHIVE_REPRODUCTION'::text,'5'::text,'24 latest | 24 archive | 0 mismatches'::text,NULL::text,'PASS'::text,'71'::text,'12'::text,'All 1 component contract(s) for the node must reproduce latest to immutable archive exactly.'::text,'M2_11_STRATEGY_SIMULATION'::text),
    ('PASS'::text,'MANDATORY'::text,'msbf_ctl.m2_11_portfolio_strategy_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output'::text,'M2_11_%BOUNDARY%|M2_11_%BLOCKING%'::text,'STAGE_BOUNDARY'::text,'6'::text,'0 blocking or stage-boundary findings'::text,NULL::text,'PASS'::text,'72'::text,'12'::text,'No accepted stage may contain prohibited production action, unauthorized source, premature downstream object, or unresolved boundary finding.'::text,'M2_11_STRATEGY_SIMULATION'::text)) AS v(allowed_certification_status,applicability_code,authoritative_source_locator,evidence_code_or_method_pattern,evidence_family_code,evidence_family_sequence,expected_count_or_identity,expected_hash,expected_status,matrix_sequence,node_sequence,rationale,stage_code)
CROSS JOIN tmp_src_m2_12_run_context ctx;

/* R10 GOVERNED STATEMENT 0028 OF 0206
   statement_code: ASSERT_TMP_SRC_M2_12_EVIDENCE_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_src_m2_12_evidence_design$ BEGIN IF (SELECT count(*) FROM tmp_src_m2_12_evidence_design) <> 72 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_src_m2_12_evidence_design', DETAIL='expected=72 observed='||(SELECT count(*) FROM tmp_src_m2_12_evidence_design)::text; END IF; END; $m212_r7_tmp_src_m2_12_evidence_design$;

/* R10 GOVERNED STATEMENT 0029 OF 0206
   statement_code: INDEX_TMP_SRC_M2_12_EVIDENCE_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_evidence_design_8495b499 ON tmp_src_m2_12_evidence_design (module1_run_id, matrix_sequence);

/* R10 GOVERNED STATEMENT 0030 OF 0206
   statement_code: ANALYZE_TMP_SRC_M2_12_EVIDENCE_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_evidence_design;

/* R10 GOVERNED STATEMENT 0031 OF 0206
   statement_code: CREATE_TMP_SRC_M2_12_NODE_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_node_design ON COMMIT DROP AS
SELECT min(cd.acceptance_evidence_code)::text AS acceptance_evidence_code,
       min(cd.acceptance_gate_id)::text AS acceptance_gate_id,
       min(cd.acceptance_gate_review_version)::integer AS acceptance_gate_review_version,
       min(cd.certification_node_sequence)::integer AS certification_node_sequence,
       min(cd.stage_expected_canonical_entities)::bigint AS expected_canonical_entities,
       min(cd.stage_combined_set_hash)::text AS expected_combined_hash,
       min(cd.expected_negative_controls)::integer AS expected_negative_controls,
       min(cd.expected_positive_controls)::integer AS expected_positive_controls,
       min(cd.historical_acceptance_method)::text AS historical_acceptance_method,
       cd.module1_run_id::bigint AS module1_run_id,
       min(cd.module_title)::text AS module_title,
       min(cd.registry_relation)::text AS registry_relation,
       min(cd.repository_stage)::text AS repository_stage,
       min(cd.required_source_edge_count)::integer AS required_source_edge_count,
       min(cd.stage_code)::text AS stage_code
FROM tmp_src_m2_12_component_design cd
GROUP BY cd.module1_run_id, cd.certification_node_sequence;

/* R10 GOVERNED STATEMENT 0032 OF 0206
   statement_code: ASSERT_TMP_SRC_M2_12_NODE_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_src_m2_12_node_design$ BEGIN IF (SELECT count(*) FROM tmp_src_m2_12_node_design) <> 12 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_src_m2_12_node_design', DETAIL='expected=12 observed='||(SELECT count(*) FROM tmp_src_m2_12_node_design)::text; END IF; END; $m212_r7_tmp_src_m2_12_node_design$;

/* R10 GOVERNED STATEMENT 0033 OF 0206
   statement_code: INDEX_TMP_SRC_M2_12_NODE_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_node_design_e9eef390 ON tmp_src_m2_12_node_design (module1_run_id, certification_node_sequence);

/* R10 GOVERNED STATEMENT 0034 OF 0206
   statement_code: ANALYZE_TMP_SRC_M2_12_NODE_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_node_design;

/* R10 GOVERNED STATEMENT 0035 OF 0206
   statement_code: CREATE_TMP_SRC_M2_12_POLICY_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_policy_observation ON COMMIT DROP AS
SELECT p.policy_profile_id::bigint AS policy_profile_id,
       p.module1_run_id::bigint AS module1_run_id,
       p.policy_code::text AS policy_code,
       p.policy_version::integer AS policy_version,
       p.policy_status::text AS policy_status,
       p.methodology_version::text AS methodology_version,
       p.bundle_code::text AS bundle_code,
       p.bundle_version::integer AS bundle_version,
       p.schema_version::text AS schema_version,
       p.acceptance_gate_id::text AS acceptance_gate_id,
       p.accepted_m2_11_project_sha256::text AS accepted_m2_11_project_sha256,
       p.accepted_m2_11_contract_set_hash::text AS accepted_m2_11_contract_set_hash,
       p.accepted_m2_11_combined_set_hash::text AS accepted_m2_11_combined_set_hash,
       p.accepted_m2_11_registry_row_hash::text AS accepted_m2_11_registry_row_hash,
       p.expected_source_node_rows::integer AS expected_source_node_rows,
       p.expected_component_contract_rows::integer AS expected_component_contract_rows,
       p.expected_source_graph_edge_rows::integer AS expected_source_graph_edge_rows,
       p.expected_evidence_certification_rows::integer AS expected_evidence_certification_rows,
       p.expected_contract_reproduction_rows::integer AS expected_contract_reproduction_rows,
       p.expected_capability_coverage_rows::integer AS expected_capability_coverage_rows,
       p.expected_canonical_family_count::integer AS expected_canonical_family_count,
       p.expected_canonical_entities::integer AS expected_canonical_entities,
       p.expected_application_consumption_rows::bigint AS expected_application_consumption_rows,
       p.expected_operational_account_consumption_rows::integer AS expected_operational_account_consumption_rows,
       p.expected_strategy_scope_consumption_rows::integer AS expected_strategy_scope_consumption_rows,
       p.expected_generation_evidence_rows::integer AS expected_generation_evidence_rows,
       p.expected_positive_controls::integer AS expected_positive_controls,
       p.expected_negative_controls::integer AS expected_negative_controls,
       p.expected_acceptance_requirements::integer AS expected_acceptance_requirements,
       p.expected_detail_result_sets::integer AS expected_detail_result_sets,
       p.synthetic_data_only_flag::boolean AS synthetic_data_only_flag,
       p.no_pii_flag::boolean AS no_pii_flag,
       p.certification_only_flag::boolean AS certification_only_flag,
       p.production_action_authorized_flag::boolean AS production_action_authorized_flag,
       p.external_system_update_authorized_flag::boolean AS external_system_update_authorized_flag,
       p.legal_or_regulatory_certified_flag::boolean AS legal_or_regulatory_certified_flag,
       p.empirical_or_causal_optimization_authorized_flag::boolean AS empirical_or_causal_optimization_authorized_flag,
       p.module3_sql_authorized_flag::boolean AS module3_sql_authorized_flag,
       p.module3_execution_authorized_flag::boolean AS module3_execution_authorized_flag,
       p.configuration_payload::jsonb AS configuration_payload,
       p.configuration_hash::text AS configuration_hash,
       p.row_hash::text AS row_hash,
       p.created_at::timestamptz AS created_at,
       p.updated_at::timestamptz AS updated_at
FROM msbf_ctl.m2_12_policy_profile p
JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=p.module1_run_id
WHERE p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND p.policy_version=1 AND p.policy_status='APPROVED';

/* R10 GOVERNED STATEMENT 0036 OF 0206
   statement_code: ASSERT_TMP_SRC_M2_12_POLICY_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_src_m2_12_policy_observation$ BEGIN IF (SELECT count(*) FROM tmp_src_m2_12_policy_observation) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_src_m2_12_policy_observation', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_src_m2_12_policy_observation)::text; END IF; END; $m212_r7_tmp_src_m2_12_policy_observation$;

/* R10 GOVERNED STATEMENT 0037 OF 0206
   statement_code: INDEX_TMP_SRC_M2_12_POLICY_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_policy_observation_2d97b9e3 ON tmp_src_m2_12_policy_observation (module1_run_id);

/* R10 GOVERNED STATEMENT 0038 OF 0206
   statement_code: ANALYZE_TMP_SRC_M2_12_POLICY_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_policy_observation;

/* R10 GOVERNED STATEMENT 0039 OF 0206
   statement_code: CREATE_TMP_SRC_M2_12_SOURCE_EDGE_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_source_edge_design ON COMMIT DROP AS
SELECT v.certification_method::text AS certification_method,
       v.edge_code::text AS edge_code,
       v.edge_family::text AS edge_family,
       v.edge_role::text AS edge_role,
       v.edge_sequence::smallint AS edge_sequence,
       v.expected_source_hash::text AS expected_source_hash,
       ctx.module1_run_id::bigint AS module1_run_id,
       v.required_status::text AS required_status,
       v.source_acceptance_gate_id::text AS source_acceptance_gate_id,
       v.source_contract_code::text AS source_contract_code,
       v.source_hash_field::text AS source_hash_field,
       v.source_node_code::text AS source_node_code,
       v.source_registry_relation::text AS source_registry_relation,
       v.target_node_code::text AS target_node_code,
       v.target_registry_relation::text AS target_registry_relation
FROM (VALUES
    ('Reconstruct accepted M1.15 registry identity and compare with M1.17 source_m1_15 fields.'::text,'M1_15_TO_M1_17_APPLICATION_CONTRACT'::text,'M1_17_FOUNDATION'::text,'DIRECT_COMPONENT_SOURCE'::text,'1'::text,'fcd2704e17ec0d2e73191ea36061d74b'::text,'PASS'::text,'M1_15_CONSUMPTION_CONTRACT'::text,'M1_APPLICATION_CONSUMPTION'::text,'source_m1_15_combined_hash'::text,'M1_15_APPLICATION_CONSUMPTION'::text,'msbf_ctl.m1_15_consumption_contract_registry'::text,'M1_17_G2_FOUNDATION'::text,'msbf_ctl.m1_17_g2_bundle_registry'::text),
    ('Reconstruct accepted M1.16 registry identity and compare with M1.17 source_m1_16 fields.'::text,'M1_16_TO_M1_17_ACQUISITION_CONTRACT'::text,'M1_17_FOUNDATION'::text,'DIRECT_COMPONENT_SOURCE'::text,'2'::text,'86df51a0ca68d84096d00ff0f1b19f33'::text,'PASS'::text,'M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS'::text,'M1_ACQUISITION_CONSUMPTION'::text,'source_m1_16_combined_hash'::text,'M1_16_ACQUISITION_CONSUMPTION'::text,'msbf_ctl.m1_16_acquisition_contract_registry'::text,'M1_17_G2_FOUNDATION'::text,'msbf_ctl.m1_17_g2_bundle_registry'::text),
    ('Compare accepted M1.17 combined hash with M2.1 recorded G2 source hash.'::text,'M1_17_TO_M2_1'::text,'LINEAR_MODULE2_CHAIN'::text,'PRIMARY_PREDECESSOR'::text,'3'::text,'7d9e466da28cad2551aa99c4c40c912b'::text,'PASS'::text,'G2_M1_CONTRACT'::text,'M1_G2_CONSUMPTION_BUNDLE'::text,'source_g2_combined_hash'::text,'M1_17_G2_FOUNDATION'::text,'msbf_ctl.m1_17_g2_bundle_registry'::text,'M2_1_ELIGIBILITY_ROUTING'::text,'msbf_ctl.m2_1_strategy_contract_registry'::text),
    ('Compare accepted M2.1 combined hash with M2.2 recorded primary source hash.'::text,'M2_1_TO_M2_2'::text,'LINEAR_MODULE2_CHAIN'::text,'PRIMARY_PREDECESSOR'::text,'4'::text,'e5ace7f32060ffb191c7bd0f8dd0c863'::text,'PASS'::text,'M2_1_ELIGIBILITY_POLICY_ROUTING'::text,'M2_ELIGIBILITY_ROUTING_CONSUMPTION'::text,'source_m2_1_combined_hash'::text,'M2_1_ELIGIBILITY_ROUTING'::text,'msbf_ctl.m2_1_strategy_contract_registry'::text,'M2_2_PRICING_STRUCTURE'::text,'msbf_ctl.m2_2_pricing_structure_contract_registry'::text),
    ('Verify M2.2 source_m1_3_gate_id and source_m1_3_application_hash against accepted M1.3 physical evidence.'::text,'M1_3_TO_M2_2_REQUEST_AUTHORITY'::text,'AUXILIARY_ACCEPTED_ANCHOR'::text,'AUXILIARY_APPLICATION_REQUEST_AUTHORITY'::text,'5'::text,'01485256b9b5748fb412743d35ced602'::text,'PASS'::text,'M1_3_APPLICATION_REQUEST'::text,'M1_3_APPLICATION_REQUEST'::text,'source_m1_3_application_hash'::text,'M1_3_APPLICATION_REQUEST'::text,'msbf_ctl.acceptance_gate_result'::text,'M2_2_PRICING_STRUCTURE'::text,'msbf_ctl.m2_2_pricing_structure_contract_registry'::text),
    ('Compare accepted M2.2 combined hash with M2.3 recorded source hash.'::text,'M2_2_TO_M2_3'::text,'LINEAR_MODULE2_CHAIN'::text,'PRIMARY_PREDECESSOR'::text,'6'::text,'bbe83b187b31ea561789797322031fc6'::text,'PASS'::text,'M2_2_PRICING_STRUCTURE_COUNTEROFFER'::text,'M2_PRICING_STRUCTURE_CONSUMPTION'::text,'source_m2_2_combined_hash'::text,'M2_2_PRICING_STRUCTURE'::text,'msbf_ctl.m2_2_pricing_structure_contract_registry'::text,'M2_3_FINAL_DECISION'::text,'msbf_ctl.m2_3_final_decision_contract_registry'::text),
    ('Compare accepted M2.3 combined hash with M2.4 recorded source hash.'::text,'M2_3_TO_M2_4'::text,'LINEAR_MODULE2_CHAIN'::text,'PRIMARY_PREDECESSOR'::text,'7'::text,'bf09349b06ede7e5a2ec830c2f9ffe90'::text,'PASS'::text,'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'::text,'M2_FINAL_OFFER_DECISION_CONSUMPTION'::text,'source_m2_3_combined_hash'::text,'M2_3_FINAL_DECISION'::text,'msbf_ctl.m2_3_final_decision_contract_registry'::text,'M2_4_PORTFOLIO_ACTIVATION'::text,'msbf_ctl.m2_4_portfolio_activation_contract_registry'::text),
    ('Compare accepted M2.4 combined hash with M2.5 recorded primary source hash.'::text,'M2_4_TO_M2_5'::text,'LINEAR_MODULE2_CHAIN'::text,'PRIMARY_PREDECESSOR'::text,'8'::text,'117450a3eea7bb3d3c74d18cc3c8e96a'::text,'PASS'::text,'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'::text,'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'::text,'source_m2_4_combined_hash'::text,'M2_4_PORTFOLIO_ACTIVATION'::text,'msbf_ctl.m2_4_portfolio_activation_contract_registry'::text,'M2_5_DAILY_MONITORING'::text,'msbf_ctl.m2_5_portfolio_monitoring_contract_registry'::text),
    ('Verify M2.5 source_m1_6_acceptance_gate_id and source_m1_6_combined_hash against accepted M1.6 physical evidence.'::text,'M1_6_TO_M2_5_SCENARIO_AUTHORITY'::text,'AUXILIARY_ACCEPTED_ANCHOR'::text,'AUXILIARY_SCENARIO_AUTHORITY'::text,'9'::text,'3f85921bf6fc30ddc6cee146085e58c5'::text,'PASS'::text,'M1_6_MATCHED_SCENARIO_OVERLAYS'::text,'M1_6_MATCHED_SCENARIO_OVERLAYS'::text,'source_m1_6_combined_hash'::text,'M1_6_MATCHED_SCENARIO_OVERLAYS'::text,'msbf_ctl.acceptance_gate_result'::text,'M2_5_DAILY_MONITORING'::text,'msbf_ctl.m2_5_portfolio_monitoring_contract_registry'::text),
    ('Compare accepted M2.5 combined hash with M2.6 recorded source hash.'::text,'M2_5_TO_M2_6'::text,'LINEAR_MODULE2_CHAIN'::text,'PRIMARY_PREDECESSOR'::text,'10'::text,'18e1c444aa1b02ee5bd3539d7c477adc'::text,'PASS'::text,'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'::text,'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'::text,'source_m2_5_combined_hash'::text,'M2_5_DAILY_MONITORING'::text,'msbf_ctl.m2_5_portfolio_monitoring_contract_registry'::text,'M2_6_INTERVENTION_STRATEGY'::text,'msbf_ctl.m2_6_intervention_strategy_contract_registry'::text),
    ('Compare accepted M2.6 combined hash with M2.7 recorded source hash.'::text,'M2_6_TO_M2_7'::text,'LINEAR_MODULE2_CHAIN'::text,'PRIMARY_PREDECESSOR'::text,'11'::text,'868125bff29270490cab4d2e55cb1388'::text,'PASS'::text,'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'::text,'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'::text,'source_combined_set_hash'::text,'M2_6_INTERVENTION_STRATEGY'::text,'msbf_ctl.m2_6_intervention_strategy_contract_registry'::text,'M2_7_OPERATIONAL_ACTIVATION'::text,'msbf_ctl.m2_7_operational_activation_contract_registry'::text),
    ('Compare accepted M2.7 combined hash with M2.8 recorded source hash.'::text,'M2_7_TO_M2_8'::text,'LINEAR_MODULE2_CHAIN'::text,'PRIMARY_PREDECESSOR'::text,'12'::text,'c8e3a472afd2a16b1183677324e9db98'::text,'PASS'::text,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'::text,'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'::text,'source_combined_set_hash'::text,'M2_7_OPERATIONAL_ACTIVATION'::text,'msbf_ctl.m2_7_operational_activation_contract_registry'::text,'M2_8_SERVICING_EXECUTION'::text,'msbf_ctl.m2_8_servicing_execution_contract_registry'::text),
    ('Compare accepted M2.8 combined hash with M2.9 recorded source hash.'::text,'M2_8_TO_M2_9'::text,'LINEAR_MODULE2_CHAIN'::text,'PRIMARY_PREDECESSOR'::text,'13'::text,'ab32d80ba20c2c8f0a6ec9ec97c2ed26'::text,'PASS'::text,'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL'::text,'M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION'::text,'source_combined_set_hash'::text,'M2_8_SERVICING_EXECUTION'::text,'msbf_ctl.m2_8_servicing_execution_contract_registry'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text,'msbf_ctl.m2_9_reconciliation_certification_contract_registry'::text),
    ('Compare accepted M2.9 combined hash with M2.10 recorded source hash.'::text,'M2_9_TO_M2_10'::text,'LINEAR_MODULE2_CHAIN'::text,'PRIMARY_PREDECESSOR'::text,'14'::text,'6af76d0059b47623619ebc09330b15fe'::text,'PASS'::text,'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'::text,'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'::text,'source_combined_set_hash'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text,'msbf_ctl.m2_9_reconciliation_certification_contract_registry'::text,'M2_10_PORTFOLIO_ANALYTICS'::text,'msbf_ctl.m2_10_portfolio_analytics_contract_registry'::text),
    ('Compare accepted M1.17 hash and registry row hash with M2.11 source_m1_17 fields.'::text,'M1_17_TO_M2_11'::text,'M2_11_MULTI_SOURCE_GRAPH'::text,'DIRECT_MULTI_SOURCE'::text,'15'::text,'7d9e466da28cad2551aa99c4c40c912b'::text,'PASS'::text,'G2_M1_CONTRACT'::text,'M1_G2_CONSUMPTION_BUNDLE'::text,'source_m1_17_combined_hash'::text,'M1_17_G2_FOUNDATION'::text,'msbf_ctl.m1_17_g2_bundle_registry'::text,'M2_11_STRATEGY_SIMULATION'::text,'msbf_ctl.m2_11_portfolio_strategy_contract_registry'::text),
    ('Compare accepted M2.2 hash and registry row hash with M2.11 source_m2_2 fields.'::text,'M2_2_TO_M2_11'::text,'M2_11_MULTI_SOURCE_GRAPH'::text,'DIRECT_MULTI_SOURCE'::text,'16'::text,'bbe83b187b31ea561789797322031fc6'::text,'PASS'::text,'M2_2_PRICING_STRUCTURE_COUNTEROFFER'::text,'M2_PRICING_STRUCTURE_CONSUMPTION'::text,'source_m2_2_combined_hash'::text,'M2_2_PRICING_STRUCTURE'::text,'msbf_ctl.m2_2_pricing_structure_contract_registry'::text,'M2_11_STRATEGY_SIMULATION'::text,'msbf_ctl.m2_11_portfolio_strategy_contract_registry'::text),
    ('Compare accepted M2.4 hash and registry row hash with M2.11 source_m2_4 fields.'::text,'M2_4_TO_M2_11'::text,'M2_11_MULTI_SOURCE_GRAPH'::text,'DIRECT_MULTI_SOURCE'::text,'17'::text,'117450a3eea7bb3d3c74d18cc3c8e96a'::text,'PASS'::text,'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'::text,'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'::text,'source_m2_4_combined_hash'::text,'M2_4_PORTFOLIO_ACTIVATION'::text,'msbf_ctl.m2_4_portfolio_activation_contract_registry'::text,'M2_11_STRATEGY_SIMULATION'::text,'msbf_ctl.m2_11_portfolio_strategy_contract_registry'::text),
    ('Compare accepted M2.7 hash and registry row hash with M2.11 source_m2_7 fields.'::text,'M2_7_TO_M2_11'::text,'M2_11_MULTI_SOURCE_GRAPH'::text,'DIRECT_MULTI_SOURCE'::text,'18'::text,'c8e3a472afd2a16b1183677324e9db98'::text,'PASS'::text,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'::text,'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'::text,'source_m2_7_combined_hash'::text,'M2_7_OPERATIONAL_ACTIVATION'::text,'msbf_ctl.m2_7_operational_activation_contract_registry'::text,'M2_11_STRATEGY_SIMULATION'::text,'msbf_ctl.m2_11_portfolio_strategy_contract_registry'::text),
    ('Compare accepted M2.10 hash and registry row hash with M2.11 source_m2_10 fields.'::text,'M2_10_TO_M2_11'::text,'M2_11_MULTI_SOURCE_GRAPH'::text,'DIRECT_MULTI_SOURCE'::text,'19'::text,'24fca7263a04397ebf21d30639f9069b'::text,'PASS'::text,'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'::text,'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'::text,'source_m2_10_combined_hash'::text,'M2_10_PORTFOLIO_ANALYTICS'::text,'msbf_ctl.m2_10_portfolio_analytics_contract_registry'::text,'M2_11_STRATEGY_SIMULATION'::text,'msbf_ctl.m2_11_portfolio_strategy_contract_registry'::text)) AS v(certification_method,edge_code,edge_family,edge_role,edge_sequence,expected_source_hash,required_status,source_acceptance_gate_id,source_contract_code,source_hash_field,source_node_code,source_registry_relation,target_node_code,target_registry_relation)
CROSS JOIN tmp_src_m2_12_run_context ctx;

/* R10 GOVERNED STATEMENT 0040 OF 0206
   statement_code: ASSERT_TMP_SRC_M2_12_SOURCE_EDGE_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_src_m2_12_source_edge_design$ BEGIN IF (SELECT count(*) FROM tmp_src_m2_12_source_edge_design) <> 19 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_src_m2_12_source_edge_design', DETAIL='expected=19 observed='||(SELECT count(*) FROM tmp_src_m2_12_source_edge_design)::text; END IF; END; $m212_r7_tmp_src_m2_12_source_edge_design$;

/* R10 GOVERNED STATEMENT 0041 OF 0206
   statement_code: INDEX_TMP_SRC_M2_12_SOURCE_EDGE_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_source_edge_design_eb906ba4 ON tmp_src_m2_12_source_edge_design (module1_run_id, edge_sequence);

/* R10 GOVERNED STATEMENT 0042 OF 0206
   statement_code: ANALYZE_TMP_SRC_M2_12_SOURCE_EDGE_DESIGN
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_source_edge_design;

/* R10 GOVERNED STATEMENT 0043 OF 0206
   statement_code: CREATE_TMP_SRC_M2_12_SOURCE_EDGE_PHYSICAL
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_source_edge_physical ON COMMIT DROP AS
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m1_15_consumption_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M1_APPLICATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_15_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND tgt.bundle_version=1 AND tgt.bundle_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_15_CONSUMPTION_CONTRACT' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m1_15_consumption_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M1_APPLICATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_15_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND tgt.bundle_version=1 AND tgt.bundle_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m1_16_acquisition_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M1_ACQUISITION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_16_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND tgt.bundle_version=1 AND tgt.bundle_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m1_16_acquisition_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M1_ACQUISITION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_16_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND tgt.bundle_version=1 AND tgt.bundle_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND src.bundle_version=1 AND src.bundle_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_g2_combined_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='G2_M1_CONTRACT' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND src.bundle_version=1 AND src.bundle_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_g2_combined_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_1_combined_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND tgt.request_contract_version=1 AND tgt.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND tgt.pricing_contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_1_combined_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND tgt.request_contract_version=1 AND tgt.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND tgt.pricing_contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT (agr.observed_value::jsonb ->> 'application_set_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_3_APPLICATION_REQUEST' AND agr.review_version=2 AND agr.result_status='PASS'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_3_application_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND tgt.request_contract_version=1 AND tgt.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND tgt.pricing_contract_version=1 AND tgt.source_m1_3_gate_id='M1_3_APPLICATION_REQUEST' AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_3_APPLICATION_REQUEST' AND agr.review_version=2))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT (agr.observed_value::jsonb ->> 'application_set_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_3_APPLICATION_REQUEST' AND agr.review_version=2 AND agr.result_status='PASS') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_3_application_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND tgt.request_contract_version=1 AND tgt.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND tgt.pricing_contract_version=1 AND tgt.source_m1_3_gate_id='M1_3_APPLICATION_REQUEST' AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND src.request_contract_version=1 AND src.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND src.pricing_contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND src.request_contract_version=1 AND src.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND src.pricing_contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_3_combined_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_3_combined_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT tgt.source_m1_6_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.source_m1_6_acceptance_gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT (agr.observed_value::jsonb->>'combined_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND agr.review_version=1 AND agr.result_status='PASS') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_6_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.source_m1_6_acceptance_gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_5_combined_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_5_combined_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND src.bundle_version=1 AND src.bundle_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_17_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='G2_M1_CONTRACT' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND src.bundle_version=1 AND src.bundle_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_17_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND src.request_contract_version=1 AND src.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND src.pricing_contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND src.request_contract_version=1 AND src.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND src.pricing_contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_7_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_7_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
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
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_10_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_10_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_run_context ctx
) x);

/* R10 GOVERNED STATEMENT 0044 OF 0206
   statement_code: ASSERT_TMP_SRC_M2_12_SOURCE_EDGE_PHYSICAL
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_hf7_source_edge_physical_assert$
BEGIN
    IF NOT (
        (SELECT count(*)=19
             AND count(DISTINCT edge_sequence)=19
             AND count(DISTINCT edge_code)=19
             AND min(edge_sequence)=1
             AND max(edge_sequence)=19
             AND bool_and(edge_status='PASS')
         FROM tmp_src_m2_12_source_edge_physical)
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 source graph physical reconstruction mismatch',
            DETAIL=coalesce(
                (SELECT string_agg(
                    'edge_sequence='||edge_sequence::text||
                    '|edge_code='||edge_code||
                    '|expected='||coalesce(expected_source_hash,'<NULL>')||
                    '|observed_source='||coalesce(observed_accepted_source_hash,'<NULL>')||
                    '|observed_target='||coalesce(observed_target_recorded_source_hash,'<NULL>')||
                    '|gate_status='||coalesce(source_gate_status,'<NULL>')||
                    '|source_rows='||source_registry_row_count::text||
                    '|target_rows='||target_registry_row_count::text||
                    '|edge_status='||coalesce(edge_status,'<NULL>'),
                    '; ' ORDER BY edge_sequence)
                 FROM tmp_src_m2_12_source_edge_physical
                 WHERE edge_status IS DISTINCT FROM 'PASS'),
                'rows='||(SELECT count(*) FROM tmp_src_m2_12_source_edge_physical)::text||
                '|distinct_sequences='||(SELECT count(DISTINCT edge_sequence) FROM tmp_src_m2_12_source_edge_physical)::text||
                '|distinct_codes='||(SELECT count(DISTINCT edge_code) FROM tmp_src_m2_12_source_edge_physical)::text),
            HINT='Stop. Preserve the source-edge detail; do not continue to generation persistence.';
    END IF;
END;
$m212_hf7_source_edge_physical_assert$;

/* R10 GOVERNED STATEMENT 0045 OF 0206
   statement_code: INDEX_TMP_SRC_M2_12_SOURCE_EDGE_PHYSICAL
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_source_edge_physical_c96a1b8d ON tmp_src_m2_12_source_edge_physical (edge_sequence);

/* R10 GOVERNED STATEMENT 0046 OF 0206
   statement_code: ANALYZE_TMP_SRC_M2_12_SOURCE_EDGE_PHYSICAL
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_source_edge_physical;

/* R10 GOVERNED STATEMENT 0047 OF 0206
   statement_code: CREATE_TMP_SRC_M2_12_STAGE_BOUNDARY_METHOD
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_stage_boundary_method ON COMMIT DROP AS
SELECT v.acceptance_evidence_code::text AS acceptance_evidence_code,
       v.acceptance_gate_id::text AS acceptance_gate_id,
       v.acceptance_gate_review_version::integer AS acceptance_gate_review_version,
       v.accepted_detail_actual_rows::integer AS accepted_detail_actual_rows,
       v.accepted_detail_expected_rows::integer AS accepted_detail_expected_rows,
       v.accepted_detail_report_authority_path::text AS accepted_detail_report_authority_path,
       v.accepted_detail_report_sha256::text AS accepted_detail_report_sha256,
       v.boundary_pattern_1::text AS boundary_pattern_1,
       v.boundary_pattern_2::text AS boundary_pattern_2,
       v.matrix_sequence::smallint AS matrix_sequence,
       ctx.module1_run_id::bigint AS module1_run_id,
       v.certification_node_sequence::smallint AS node_sequence,
       v.registry_relation::text AS registry_relation,
       v.report_exists_status::text AS report_exists_status,
       v.required_evidence_code_count::integer AS required_evidence_code_count,
       string_to_array(v.required_evidence_codes,'|')::text[] AS required_evidence_codes,
       v.stage_code::text AS stage_code
FROM (VALUES
    ('M1_17_ACCEPTANCE_SUMMARY'::text,'G2_M1_CONTRACT'::text,'1'::text,'0'::text,'0'::text,'19_M1_17/evidence/final/D24_Blocking_Stage_Violations.csv'::text,'4efd6882af220b190426e4a897ba1d1280c3d7af6174290d1d23af36b1fde300'::text,'M1_17_%BOUNDARY%'::text,'M1_17_%BLOCKING%'::text,'6'::text,'1'::text,'msbf_ctl.m1_17_g2_bundle_registry'::text,'PASS'::text,'3'::text,'M1_17_E2E_045_BLOCKING_ERRORS|M1_17_E2E_046_MODULE2_ROWS|M1_17_E2E_047_PII_COLUMNS'::text,'M1_17_G2_FOUNDATION'::text),
    ('M2_1_ACCEPTANCE_SUMMARY'::text,'M2_1_ELIGIBILITY_POLICY_ROUTING'::text,'1'::text,'0'::text,'0'::text,'20_M2_1/evidence/final/24_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Blocking_Errors_And_Stage_Boundary_Violations_20260730.csv'::text,'2a9b9b7b5354d529e19d981854baaffa782083ab5d0fdd2f21ef857f66329efb'::text,'M2_1_%BOUNDARY%'::text,'M2_1_%BLOCKING%'::text,'12'::text,'2'::text,'msbf_ctl.m2_1_strategy_contract_registry'::text,'PASS'::text,'3'::text,'M2_1_POS_109_ZERO_BLOCKING_ERRORS|M2_1_NEG_004_FINAL_OFFER_BOUNDARY|M2_1_NEG_005_ACQUISITION_CREDIT_BOUNDARY'::text,'M2_1_ELIGIBILITY_ROUTING'::text),
    ('M2_2_ACCEPTANCE_SUMMARY'::text,'M2_2_PRICING_STRUCTURE_COUNTEROFFER'::text,'1'::text,'0'::text,'0'::text,'21_M2_2/evidence/final/24_blocking_stage_boundary_violations.csv'::text,'d5e9991bf2fd0248204517bf0b947fa76af898e6d33da117d7f4229cf4ee85cb'::text,'M2_2_%BOUNDARY%'::text,'M2_2_%BLOCKING%'::text,'18'::text,'3'::text,'msbf_ctl.m2_2_pricing_structure_contract_registry'::text,'PASS'::text,'3'::text,'M2_2_POS_012_BOUNDARY_FLAGS|M2_2_NEG_002_FINAL_DECISION_BOUNDARY|M2_2_NEG_003_ACQUISITION_NONCREDIT_BOUNDARY'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('M2_3_ACCEPTANCE_SUMMARY'::text,'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'::text,'1'::text,'0'::text,'0'::text,'22_M2_3/evidence/final/24_blocking_errors_and_stage_boundary_violations.csv'::text,'d5e9991bf2fd0248204517bf0b947fa76af898e6d33da117d7f4229cf4ee85cb'::text,'M2_3_%BOUNDARY%'::text,'M2_3_%BLOCKING%'::text,'24'::text,'4'::text,'msbf_ctl.m2_3_final_decision_contract_registry'::text,'PASS'::text,'6'::text,'M2_3_POLICY_BOUNDARY|M2_3_POS_011_OUTCOME_BOUNDARY_FLAGS|M2_3_POS_012_REASON_BOUNDARY_FLAGS|M2_3_NEG_002_BOOKING_BOUNDARY_FLAG|M2_3_NEG_003_EXTERNAL_NOTICE_BOUNDARY|M2_3_NEG_004_ADVERSE_ACTION_BOUNDARY'::text,'M2_3_FINAL_DECISION'::text),
    ('M2_4_ACCEPTANCE_SUMMARY'::text,'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'::text,'1'::text,'0'::text,'0'::text,'23_M2_4/evidence/final/24_blocking_errors_and_stage_boundary_violations.csv'::text,'d5e9991bf2fd0248204517bf0b947fa76af898e6d33da117d7f4229cf4ee85cb'::text,'M2_4_%BOUNDARY%'::text,'M2_4_%BLOCKING%'::text,'30'::text,'5'::text,'msbf_ctl.m2_4_portfolio_activation_contract_registry'::text,'PASS'::text,'4'::text,'M2_4_POS_060_OPERATIONAL_BOUNDARY_FLAGS|M2_4_NEG_002_REAL_FUNDS_POLICY_BOUNDARY|M2_4_NEG_003_EXTERNAL_NOTICE_POLICY_BOUNDARY|M2_4_NEG_004_ADVERSE_ACTION_POLICY_BOUNDARY'::text,'M2_4_PORTFOLIO_ACTIVATION'::text),
    ('M2_5_ACCEPTANCE_SUMMARY'::text,'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'::text,'1'::text,'0'::text,'0'::text,'24_M2_5/evidence/raw/csv/MSBF_M2_5_Daily_Remittance_Exposure_&_Portfolio_Monitoring_Detail_Report_v0_2R5_Blocking_Errors_And_Stage_Boundary_Violations_20260801.csv'::text,'d5e9991bf2fd0248204517bf0b947fa76af898e6d33da117d7f4229cf4ee85cb'::text,'M2_5_%BOUNDARY%'::text,'M2_5_%BLOCKING%'::text,'36'::text,'6'::text,'msbf_ctl.m2_5_portfolio_monitoring_contract_registry'::text,'PASS'::text,'6'::text,'M2_5_POS_018_REASON_BOUNDARY_FLAGS|M2_5_NEG_002_REAL_DEBIT_BOUNDARY|M2_5_NEG_003_EXTERNAL_NOTICE_BOUNDARY|M2_5_NEG_004_ADVERSE_NOTICE_BOUNDARY|M2_5_NEG_005_WRITE_OFF_RESTRUCTURE_BOUNDARY|M2_5_NEG_006_MONITORING_ONLY_BOUNDARY'::text,'M2_5_DAILY_MONITORING'::text),
    ('M2_6_ACCEPTANCE_SUMMARY'::text,'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'::text,'1'::text,'0'::text,'0'::text,'25_M2_6/evidence/raw/csv/179_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_6_%BOUNDARY%'::text,'M2_6_%BLOCKING%'::text,'42'::text,'7'::text,'msbf_ctl.m2_6_intervention_strategy_contract_registry'::text,'PASS'::text,'4'::text,'M2_6_NEG_017_PAYLOAD_BOUNDARY|M2_6_NEG_018_PAYLOAD_BOUNDARY|M2_6_NEG_019_PAYLOAD_BOUNDARY|M2_6_NEG_020_PAYLOAD_BOUNDARY'::text,'M2_6_INTERVENTION_STRATEGY'::text),
    ('M2_7_ACCEPTANCE_SUMMARY'::text,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'::text,'1'::text,'0'::text,'0'::text,'26_M2_7/evidence/raw/csv/187_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_7_%BOUNDARY%'::text,'M2_7_%BLOCKING%'::text,'48'::text,'8'::text,'msbf_ctl.m2_7_operational_activation_contract_registry'::text,'PASS'::text,'7'::text,'M2_7_POS_018_DEFINITION_BOUNDARY|M2_7_NEG_002_SIMULATED_SETUP_BOUNDARY|M2_7_NEG_003_REAL_ACCOUNT_BOUNDARY|M2_7_NEG_004_PAYMENT_CHANGE_BOUNDARY|M2_7_NEG_005_BANK_DATA_BOUNDARY|M2_7_NEG_006_ACH_NETWORK_BOUNDARY|M2_7_NEG_007_EXTERNAL_NOTICE_BOUNDARY'::text,'M2_7_OPERATIONAL_ACTIVATION'::text),
    ('M2_8_ACCEPTANCE_SUMMARY'::text,'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL'::text,'1'::text,'0'::text,'0'::text,'27_M2_8/evidence/raw/csv/195_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_8_%BOUNDARY%'::text,'M2_8_%BLOCKING%'::text,'54'::text,'9'::text,'msbf_ctl.m2_8_servicing_execution_contract_registry'::text,'PASS'::text,'8'::text,'M2_8_POS_022_DEFINITION_BOUNDARY|M2_8_POS_089_PAYMENT_BOUNDARY|M2_8_POS_095_TRANSITION_BOUNDARY|M2_8_NEG_002_SIMULATION_BOUNDARY|M2_8_NEG_003_REAL_FUNDS_BOUNDARY|M2_8_NEG_004_BANK_DATA_BOUNDARY|M2_8_NEG_005_ACH_NETWORK_BOUNDARY|M2_8_NEG_006_PROCESSOR_CALL_BOUNDARY'::text,'M2_8_SERVICING_EXECUTION'::text),
    ('M2_9_ACCEPTANCE_SUMMARY'::text,'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'::text,'1'::text,'0'::text,'0'::text,'28_M2_9/evidence/raw/csv/203_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_9_%BOUNDARY%'::text,'M2_9_%BLOCKING%'::text,'60'::text,'10'::text,'msbf_ctl.m2_9_reconciliation_certification_contract_registry'::text,'PASS'::text,'10'::text,'M2_9_POS_021_DEFINITION_BOUNDARY|M2_9_POS_069_PAYMENT_RECON_BOUNDARY|M2_9_POS_070_EXCEPTION_BOUNDARY|M2_9_POS_087_ACCOUNT_BOUNDARY|M2_9_POS_095_CERTIFICATION_HASH_BOUNDARY|M2_9_NEG_002_CERTIFICATION_BOUNDARY|M2_9_NEG_003_REAL_FUNDS_BOUNDARY|M2_9_NEG_004_BANK_DATA_BOUNDARY|M2_9_NEG_005_NETWORK_BOUNDARY|M2_9_NEG_006_PROCESSOR_BOUNDARY'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text),
    ('M2_10_ACCEPTANCE_SUMMARY'::text,'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'::text,'1'::text,'0'::text,'0'::text,'29_M2_10/evidence/raw/csv/211_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_10_%BOUNDARY%'::text,'M2_10_%BLOCKING%'::text,'66'::text,'11'::text,'msbf_ctl.m2_10_portfolio_analytics_contract_registry'::text,'PASS'::text,'10'::text,'M2_10_POS_010_POLICY_BOUNDARY|M2_10_POS_021_REASON_BOUNDARY|M2_10_POS_056_PERFORMANCE_BOUNDARY_DECISION|M2_10_POS_057_PERFORMANCE_BOUNDARY_SYSTEM|M2_10_POS_058_PERFORMANCE_BOUNDARY_CONTACT|M2_10_NEG_002_ANALYTICS_BOUNDARY|M2_10_NEG_003_DECISION_BOUNDARY|M2_10_NEG_004_FUNDS_BOUNDARY|M2_10_NEG_005_SYSTEM_BOUNDARY|M2_10_NEG_006_CONTACT_BOUNDARY'::text,'M2_10_PORTFOLIO_ANALYTICS'::text),
    ('M2_11_ACCEPTANCE_SUMMARY'::text,'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'::text,'1'::text,'0'::text,'0'::text,'30_M2_11/10_live_execution_evidence/exports/MSBF_M2_11_Portfolio_Optimization_&_Strategy_Simulation_Detail_Report_v1_Blocking_And_Stage_Boundary_Violations_20260806.csv'::text,'6fe5fce149762a76e6b230832834471ba08efec6a7b2621fbe818a3c74025a1c'::text,'M2_11_%BOUNDARY%'::text,'M2_11_%BLOCKING%'::text,'72'::text,'12'::text,'msbf_ctl.m2_11_portfolio_strategy_contract_registry'::text,'PASS'::text,'6'::text,'M2_11_POS_009_POLICY_BOUNDARY|M2_11_POS_036_CONSTRAINT_BLOCKING|M2_11_POS_120_CANONICAL_BOUNDARY|M2_11_NEG_017_PRODUCTION_ACTION|M2_11_NEG_018_EXTERNAL_BEHAVIOR|M2_11_NEG_020_UNAUTHORIZED_STAGE_SOURCE'::text,'M2_11_STRATEGY_SIMULATION'::text)) AS v(acceptance_evidence_code,acceptance_gate_id,acceptance_gate_review_version,accepted_detail_actual_rows,accepted_detail_expected_rows,accepted_detail_report_authority_path,accepted_detail_report_sha256,boundary_pattern_1,boundary_pattern_2,matrix_sequence,certification_node_sequence,registry_relation,report_exists_status,required_evidence_code_count,required_evidence_codes,stage_code)
CROSS JOIN tmp_src_m2_12_run_context ctx;

/* R10 GOVERNED STATEMENT 0048 OF 0206
   statement_code: ASSERT_TMP_SRC_M2_12_STAGE_BOUNDARY_METHOD
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_src_m2_12_stage_boundary_method$ BEGIN IF (SELECT count(*) FROM tmp_src_m2_12_stage_boundary_method) <> 12 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_src_m2_12_stage_boundary_method', DETAIL='expected=12 observed='||(SELECT count(*) FROM tmp_src_m2_12_stage_boundary_method)::text; END IF; END; $m212_r7_tmp_src_m2_12_stage_boundary_method$;

/* R10 GOVERNED STATEMENT 0049 OF 0206
   statement_code: INDEX_TMP_SRC_M2_12_STAGE_BOUNDARY_METHOD
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_stage_boundary_method_fc9b8625 ON tmp_src_m2_12_stage_boundary_method (module1_run_id, matrix_sequence);

/* R10 GOVERNED STATEMENT 0050 OF 0206
   statement_code: ANALYZE_TMP_SRC_M2_12_STAGE_BOUNDARY_METHOD
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_stage_boundary_method;

/* R10 GOVERNED STATEMENT 0051 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_REPRODUCTION_OBSERVATION_BASE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
CREATE TEMP TABLE tmp_cert_m2_12_reproduction_observation_base ON COMMIT DROP AS
WITH component_rows AS
(
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,bundle_code,bundle_version,count(*) c FROM msbf_ctl.m1_17_g2_bundle_archive WHERE module1_run_id=ctx.module1_run_id AND bundle_version=cd.contract_version GROUP BY module1_run_id,bundle_code,bundle_version HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m1_17_g2_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_ctl.m1_17_g2_bundle_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m1_17_g2_archive_immutable' AND n.nspname||'.'||p.proname='msbf_ctl.m1_17_archive_immutable_guard' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    1::smallint AS certification_node_sequence,
    'M1_G2_CONSUMPTION_BUNDLE'::text AS component_contract_code,
    1::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,count(*) c FROM msbf_ctl.m1_17_g2_bundle_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_latest l FULL JOIN msbf_ctl.m1_17_g2_bundle_archive a ON a.module1_run_id=l.module1_run_id AND a.bundle_code=l.bundle_code AND a.bundle_version=l.bundle_version WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_latest l FULL JOIN msbf_ctl.m1_17_g2_bundle_archive a ON a.module1_run_id=l.module1_run_id AND a.bundle_code=l.bundle_code AND a.bundle_version=l.bundle_version WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.bundle_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5('ARCHIVE|'||a.archive_row_hash) FROM msbf_ctl.m1_17_g2_bundle_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.bundle_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5('LATEST|'||l.contract_row_hash) FROM msbf_ctl.m1_17_g2_bundle_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_latest l FULL JOIN msbf_ctl.m1_17_g2_bundle_archive a ON a.module1_run_id=l.module1_run_id AND a.bundle_code=l.bundle_code AND a.bundle_version=l.bundle_version WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND (((to_jsonb(l)-ARRAY['contract_row_hash','created_at']::text[]) IS DISTINCT FROM (to_jsonb(a)-ARRAY['g2_bundle_archive_id','source_latest_row_hash','archive_row_hash','archived_at','created_at']::text[])) OR (a.source_latest_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m1_17_hash_jsonb(jsonb_build_object('module1_run_id',l.module1_run_id,'bundle_code',l.bundle_code,'bundle_version',l.bundle_version,'schema_version',l.schema_version,'methodology_version',l.methodology_version,'source_contract_count',l.source_contract_count,'integrated_consumption_rows',l.integrated_consumption_rows,'hash_chain_rows',l.hash_chain_rows,'evidence_snapshot_rows',l.evidence_snapshot_rows,'hash_chain_set_hash',l.hash_chain_set_hash,'evidence_set_hash',l.evidence_set_hash))) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m1_17_hash_jsonb(jsonb_build_object('module1_run_id',a.module1_run_id,'bundle_code',a.bundle_code,'bundle_version',a.bundle_version,'schema_version',a.schema_version,'methodology_version',a.methodology_version,'source_contract_count',a.source_contract_count,'integrated_consumption_rows',a.integrated_consumption_rows,'hash_chain_rows',a.hash_chain_rows,'evidence_snapshot_rows',a.evidence_snapshot_rows,'hash_chain_set_hash',a.hash_chain_set_hash,'evidence_set_hash',a.evidence_set_hash,'bundle_payload',a.bundle_payload,'source_latest_row_hash',a.source_latest_row_hash)))))::bigint AS payload_mismatch_count,
    ((SELECT r01.row_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry r01 WHERE r01.module1_run_id = ctx.module1_run_id AND r01.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND r01.bundle_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 1
 AND cd.certification_node_sequence = 1
 AND cd.component_contract_code = 'M1_G2_CONSUMPTION_BUNDLE'
 AND cd.contract_version = 1
)
UNION ALL
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_code,contract_version,strategy_campaign_code,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_code,contract_version,strategy_campaign_code,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m2_1_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_m2.application_eligibility_routing_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_1_archive_immutable' AND n.nspname||'.'||p.proname='msbf_m2.m2_1_reject_archive_mutation' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    2::smallint AS certification_node_sequence,
    'M2_ELIGIBILITY_ROUTING_CONSUMPTION'::text AS component_contract_code,
    2::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,strategy_campaign_code,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,strategy_campaign_code,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_latest l FULL JOIN msbf_m2.application_eligibility_routing_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.strategy_campaign_code=l.strategy_campaign_code AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_latest l FULL JOIN msbf_m2.application_eligibility_routing_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.strategy_campaign_code=l.strategy_campaign_code AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5(string_agg(a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_eligibility_routing_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5(string_agg(l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_eligibility_routing_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_latest l FULL JOIN msbf_m2.application_eligibility_routing_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.strategy_campaign_code=l.strategy_campaign_code AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (a.source_latest_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_1_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_1_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
    ((SELECT r02.row_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry r02 WHERE r02.module1_run_id = ctx.module1_run_id AND r02.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND r02.contract_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 2
 AND cd.certification_node_sequence = 2
 AND cd.component_contract_code = 'M2_ELIGIBILITY_ROUTING_CONSUMPTION'
 AND cd.contract_version = 1
)
UNION ALL
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_code,contract_version,merchant_application_id,count(*) c FROM msbf_m2.application_request_structure_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_code,contract_version,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m2_2_request_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_m2.application_request_structure_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_2_request_archive_immutable' AND n.nspname||'.'||p.proname='msbf_m2.m2_2_reject_request_archive_mutation' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    3::smallint AS certification_node_sequence,
    'M2_REQUEST_STRUCTURE_CONSUMPTION'::text AS component_contract_code,
    3::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,merchant_application_id,count(*) c FROM msbf_m2.application_request_structure_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_latest l FULL JOIN msbf_m2.application_request_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_latest l FULL JOIN msbf_m2.application_request_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5(string_agg(a.archive_row_hash,'|' ORDER BY a.merchant_application_id)) FROM msbf_m2.application_request_structure_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5(string_agg(l.contract_row_hash,'|' ORDER BY l.merchant_application_id)) FROM msbf_m2.application_request_structure_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_latest l FULL JOIN msbf_m2.application_request_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (a.source_latest_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_2_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_2_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
    ((SELECT r03.row_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r03 WHERE r03.module1_run_id = ctx.module1_run_id AND r03.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND r03.request_contract_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 3
 AND cd.certification_node_sequence = 3
 AND cd.component_contract_code = 'M2_REQUEST_STRUCTURE_CONSUMPTION'
 AND cd.contract_version = 1
)
UNION ALL
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_code,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_pricing_structure_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_code,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m2_2_pricing_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_m2.application_pricing_structure_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_2_pricing_archive_immutable' AND n.nspname||'.'||p.proname='msbf_m2.m2_2_reject_pricing_archive_mutation' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    3::smallint AS certification_node_sequence,
    'M2_PRICING_STRUCTURE_CONSUMPTION'::text AS component_contract_code,
    4::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_latest l FULL JOIN msbf_m2.application_pricing_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_latest l FULL JOIN msbf_m2.application_pricing_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5(string_agg(a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_pricing_structure_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5(string_agg(l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_pricing_structure_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_latest l FULL JOIN msbf_m2.application_pricing_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (a.source_latest_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_2_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_2_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
    ((SELECT r04.row_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r04 WHERE r04.module1_run_id = ctx.module1_run_id AND r04.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND r04.pricing_contract_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 4
 AND cd.certification_node_sequence = 3
 AND cd.component_contract_code = 'M2_PRICING_STRUCTURE_CONSUMPTION'
 AND cd.contract_version = 1
)
UNION ALL
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_final_offer_decision_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m2_3_decision_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_m2.application_final_offer_decision_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_3_decision_archive_immutable' AND n.nspname||'.'||p.proname='msbf_ctl.m2_3_archive_immutable' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    4::smallint AS certification_node_sequence,
    'M2_FINAL_OFFER_DECISION_CONSUMPTION'::text AS component_contract_code,
    5::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_latest l FULL JOIN msbf_m2.application_final_offer_decision_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_latest l FULL JOIN msbf_m2.application_final_offer_decision_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_final_offer_decision_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_final_offer_decision_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_latest l FULL JOIN msbf_m2.application_final_offer_decision_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
    ((SELECT r05.row_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry r05 WHERE r05.module1_run_id = ctx.module1_run_id AND r05.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND r05.contract_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 5
 AND cd.certification_node_sequence = 4
 AND cd.component_contract_code = 'M2_FINAL_OFFER_DECISION_CONSUMPTION'
 AND cd.contract_version = 1
)
UNION ALL
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_booking_funding_activation_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m2_4_activation_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_m2.application_booking_funding_activation_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_4_activation_archive_immutable' AND n.nspname||'.'||p.proname='msbf_ctl.m2_4_archive_immutable' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    5::smallint AS certification_node_sequence,
    'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'::text AS component_contract_code,
    6::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_latest l FULL JOIN msbf_m2.application_booking_funding_activation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_latest l FULL JOIN msbf_m2.application_booking_funding_activation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_booking_funding_activation_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_booking_funding_activation_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_latest l FULL JOIN msbf_m2.application_booking_funding_activation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
    ((SELECT r06.row_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry r06 WHERE r06.module1_run_id = ctx.module1_run_id AND r06.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND r06.contract_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 6
 AND cd.certification_node_sequence = 5
 AND cd.component_contract_code = 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
 AND cd.contract_version = 1
)
UNION ALL
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.advance_portfolio_monitoring_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m2_5_monitoring_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_m2.advance_portfolio_monitoring_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_5_monitoring_archive_immutable' AND n.nspname||'.'||p.proname='msbf_ctl.m2_5_archive_immutable' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    6::smallint AS certification_node_sequence,
    'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'::text AS component_contract_code,
    7::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.advance_portfolio_monitoring_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_latest l FULL JOIN msbf_m2.advance_portfolio_monitoring_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_latest l FULL JOIN msbf_m2.advance_portfolio_monitoring_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.advance_portfolio_monitoring_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.advance_portfolio_monitoring_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_latest l FULL JOIN msbf_m2.advance_portfolio_monitoring_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
    ((SELECT r07.row_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry r07 WHERE r07.module1_run_id = ctx.module1_run_id AND r07.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND r07.contract_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 7
 AND cd.certification_node_sequence = 6
 AND cd.component_contract_code = 'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'
 AND cd.contract_version = 1
)
UNION ALL
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.advance_intervention_strategy_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m2_6_strategy_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_m2.advance_intervention_strategy_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_6_strategy_archive_immutable' AND n.nspname||'.'||p.proname='msbf_ctl.m2_6_archive_immutable' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    7::smallint AS certification_node_sequence,
    'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'::text AS component_contract_code,
    8::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.advance_intervention_strategy_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_latest l FULL JOIN msbf_m2.advance_intervention_strategy_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_latest l FULL JOIN msbf_m2.advance_intervention_strategy_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.advance_intervention_strategy_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.advance_intervention_strategy_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_latest l FULL JOIN msbf_m2.advance_intervention_strategy_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_6_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_6_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
    ((SELECT r08.row_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry r08 WHERE r08.module1_run_id = ctx.module1_run_id AND r08.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND r08.contract_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 8
 AND cd.certification_node_sequence = 7
 AND cd.component_contract_code = 'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'
 AND cd.contract_version = 1
)
UNION ALL
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_operational_activation_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m2_7_activation_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_m2.application_operational_activation_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_7_activation_archive_immutable' AND n.nspname||'.'||p.proname='msbf_ctl.m2_7_archive_immutable' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    8::smallint AS certification_node_sequence,
    'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'::text AS component_contract_code,
    9::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_latest l FULL JOIN msbf_m2.application_operational_activation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_latest l FULL JOIN msbf_m2.application_operational_activation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_operational_activation_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_operational_activation_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_latest l FULL JOIN msbf_m2.application_operational_activation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
    ((SELECT r09.row_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry r09 WHERE r09.module1_run_id = ctx.module1_run_id AND r09.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND r09.contract_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 9
 AND cd.certification_node_sequence = 8
 AND cd.component_contract_code = 'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
 AND cd.contract_version = 1
)
UNION ALL
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_servicing_execution_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m2_8_servicing_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_m2.application_servicing_execution_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_8_servicing_archive_immutable' AND n.nspname||'.'||p.proname='msbf_ctl.m2_8_archive_immutable' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    9::smallint AS certification_node_sequence,
    'M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION'::text AS component_contract_code,
    10::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_servicing_execution_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_latest l FULL JOIN msbf_m2.application_servicing_execution_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_latest l FULL JOIN msbf_m2.application_servicing_execution_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_servicing_execution_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_servicing_execution_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_latest l FULL JOIN msbf_m2.application_servicing_execution_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_8_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_8_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
    ((SELECT r10.row_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry r10 WHERE r10.module1_run_id = ctx.module1_run_id AND r10.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND r10.contract_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 10
 AND cd.certification_node_sequence = 9
 AND cd.component_contract_code = 'M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION'
 AND cd.contract_version = 1
)
UNION ALL
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_payment_reconciliation_certification_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m2_9_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_m2.application_payment_reconciliation_certification_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_9_archive_immutable' AND n.nspname||'.'||p.proname='msbf_ctl.m2_9_archive_immutable' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    10::smallint AS certification_node_sequence,
    'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'::text AS component_contract_code,
    11::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_latest l FULL JOIN msbf_m2.application_payment_reconciliation_certification_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_latest l FULL JOIN msbf_m2.application_payment_reconciliation_certification_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_payment_reconciliation_certification_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_payment_reconciliation_certification_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_latest l FULL JOIN msbf_m2.application_payment_reconciliation_certification_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
    ((SELECT r11.row_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry r11 WHERE r11.module1_run_id = ctx.module1_run_id AND r11.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND r11.contract_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 11
 AND cd.certification_node_sequence = 10
 AND cd.component_contract_code = 'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'
 AND cd.contract_version = 1
)
UNION ALL
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_portfolio_performance_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m2_10_portfolio_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_m2.application_portfolio_performance_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_10_portfolio_archive_immutable' AND n.nspname||'.'||p.proname='msbf_ctl.m2_10_archive_immutable' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    11::smallint AS certification_node_sequence,
    'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'::text AS component_contract_code,
    12::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_latest l FULL JOIN msbf_m2.application_portfolio_performance_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_latest l FULL JOIN msbf_m2.application_portfolio_performance_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_portfolio_performance_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_portfolio_performance_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_latest l FULL JOIN msbf_m2.application_portfolio_performance_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
    ((SELECT r12.row_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry r12 WHERE r12.module1_run_id = ctx.module1_run_id AND r12.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND r12.contract_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 12
 AND cd.certification_node_sequence = 11
 AND cd.component_contract_code = 'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'
 AND cd.contract_version = 1
)
UNION ALL
(
SELECT
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,strategy_profile_code,reporting_scope_code,count(*) c FROM msbf_m2.portfolio_strategy_simulation_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,strategy_profile_code,reporting_scope_code HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
    'trg_m2_11_archive_immutable'::text AS archive_trigger_name,
    CASE WHEN ((SELECT count(*)=1 FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE t.tgrelid='msbf_m2.portfolio_strategy_simulation_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_11_archive_immutable' AND n.nspname||'.'||p.proname='msbf_ctl.m2_11_block_archive_mutation' AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))) THEN 'PASS' ELSE 'FAIL' END::text AS archive_trigger_status,
    12::smallint AS certification_node_sequence,
    'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'::text AS component_contract_code,
    13::smallint AS component_sequence,
    1::integer AS contract_version,
    cd.expected_archive_rows::bigint AS expected_archive_rows,
    cd.expected_archive_set_hash::text AS expected_archive_set_hash,
    cd.expected_latest_rows::bigint AS expected_latest_rows,
    cd.expected_latest_set_hash::text AS expected_latest_set_hash,
    (SELECT count(*)::bigint FROM (SELECT module1_run_id,strategy_profile_code,reporting_scope_code,count(*) c FROM msbf_m2.portfolio_strategy_simulation_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,strategy_profile_code,reporting_scope_code HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
    (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_latest l FULL JOIN msbf_m2.portfolio_strategy_simulation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.strategy_profile_code=l.strategy_profile_code AND a.reporting_scope_code=l.reporting_scope_code WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
    (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_latest l FULL JOIN msbf_m2.portfolio_strategy_simulation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.strategy_profile_code=l.strategy_profile_code AND a.reporting_scope_code=l.reporting_scope_code WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
    ctx.module1_run_id::bigint AS module1_run_id,
    (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::bigint AS observed_archive_rows,
    (SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(jsonb_build_object('module1_run_id',a.module1_run_id,'contract_code',a.contract_code,'contract_version',a.contract_version,'strategy_profile_code',a.strategy_profile_code,'reporting_scope_code',a.reporting_scope_code,'contract_payload',a.contract_payload,'source_latest_row_hash',a.contract_row_hash)),'|' ORDER BY a.module1_run_id,a.contract_version,a.reporting_scope_code,a.strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS observed_archive_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_latest l WHERE l.module1_run_id=ctx.module1_run_id)::bigint AS observed_latest_rows,
    (SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at'),'|' ORDER BY l.module1_run_id,l.reporting_scope_code,l.strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS observed_latest_set_hash,
    (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_latest l FULL JOIN msbf_m2.portfolio_strategy_simulation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.strategy_profile_code=l.strategy_profile_code AND a.reporting_scope_code=l.reporting_scope_code WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(jsonb_build_object('module1_run_id',a.module1_run_id,'contract_code',a.contract_code,'contract_version',a.contract_version,'strategy_profile_code',a.strategy_profile_code,'reporting_scope_code',a.reporting_scope_code,'contract_payload',a.contract_payload,'source_latest_row_hash',a.contract_row_hash)))))::bigint AS payload_mismatch_count,
    ((SELECT r13.row_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry r13 WHERE r13.module1_run_id = ctx.module1_run_id AND r13.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND r13.contract_version=1))::text AS source_registry_row_hash
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id = ctx.module1_run_id
 AND cd.component_sequence = 13
 AND cd.certification_node_sequence = 12
 AND cd.component_contract_code = 'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
 AND cd.contract_version = 1
)
)
SELECT
    b.archive_duplicate_key_rows::bigint AS archive_duplicate_key_rows,
    b.archive_trigger_name::text AS archive_trigger_name,
    b.archive_trigger_status::text AS archive_trigger_status,
    b.certification_node_sequence::smallint AS certification_node_sequence,
    b.component_contract_code::text AS component_contract_code,
    b.component_sequence::smallint AS component_sequence,
    b.contract_version::integer AS contract_version,
    b.expected_archive_rows::bigint AS expected_archive_rows,
    b.expected_archive_set_hash::text AS expected_archive_set_hash,
    b.expected_latest_rows::bigint AS expected_latest_rows,
    b.expected_latest_set_hash::text AS expected_latest_set_hash,
    b.latest_duplicate_key_rows::bigint AS latest_duplicate_key_rows,
    b.missing_archive_rows::bigint AS missing_archive_rows,
    b.missing_latest_rows::bigint AS missing_latest_rows,
    b.module1_run_id::bigint AS module1_run_id,
    b.observed_archive_rows::bigint AS observed_archive_rows,
    b.observed_archive_set_hash::text AS observed_archive_set_hash,
    b.observed_latest_rows::bigint AS observed_latest_rows,
    b.observed_latest_set_hash::text AS observed_latest_set_hash,
    b.payload_mismatch_count::bigint AS payload_mismatch_count,
    b.source_registry_row_hash::text AS source_registry_row_hash
FROM component_rows b;

/* R10 GOVERNED STATEMENT 0052 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_REPRODUCTION_OBSERVATION_BASE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
DO $m212_hf7_reproduction_base_assert$
BEGIN
    IF NOT (
        (SELECT count(*)=13
             AND count(DISTINCT (module1_run_id,component_sequence))=13
             AND count(DISTINCT component_sequence)=13
             AND count(DISTINCT (component_contract_code,contract_version))=13
             AND min(component_sequence)=1
             AND max(component_sequence)=13
             AND bool_and(source_registry_row_hash IS NOT NULL)
         FROM tmp_cert_m2_12_reproduction_observation_base)
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 reproduction observation base mismatch',
            DETAIL='rows='||(SELECT count(*) FROM tmp_cert_m2_12_reproduction_observation_base)::text||
                   '|distinct_components='||(SELECT count(DISTINCT component_sequence) FROM tmp_cert_m2_12_reproduction_observation_base)::text||
                   '|null_registry_hashes='||(SELECT count(*) FROM tmp_cert_m2_12_reproduction_observation_base WHERE source_registry_row_hash IS NULL)::text;
    END IF;
END;
$m212_hf7_reproduction_base_assert$;

/* R10 GOVERNED STATEMENT 0053 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_REPRODUCTION_OBSERVATION_BASE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_reproduction_observation_base_fcad36ed ON tmp_cert_m2_12_reproduction_observation_base (module1_run_id, component_sequence);

/* R10 GOVERNED STATEMENT 0054 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_REPRODUCTION_OBSERVATION_BASE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_reproduction_observation_base;

/* R10 GOVERNED STATEMENT 0055 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_SOURCE_EDGE_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
CREATE TEMP TABLE tmp_cert_m2_12_source_edge_observation ON COMMIT DROP AS
WITH edge_rows AS
(
    SELECT
        esrc.edge_code::text AS edge_code,
        esrc.edge_sequence::smallint AS edge_sequence,
        CASE
            WHEN esrc.source_registry_row_count = 1
             AND esrc.target_registry_row_count = 1
             AND esrc.source_gate_status = 'PASS'
             AND esrc.observed_accepted_source_hash = esrc.expected_source_hash
             AND esrc.observed_target_recorded_source_hash = esrc.expected_source_hash
            THEN 'PASS'
            ELSE 'FAIL'
        END::text AS edge_status,
        esrc.expected_source_hash::text AS expected_source_hash,
        esrc.module1_run_id::bigint AS module1_run_id,
        esrc.observed_accepted_source_hash::text AS observed_accepted_source_hash,
        esrc.observed_target_recorded_source_hash::text AS observed_target_recorded_source_hash,
        esrc.source_gate_status::text AS source_gate_status,
        (esrc.observed_accepted_source_hash IS DISTINCT FROM esrc.expected_source_hash)::boolean AS source_hash_mismatch_flag,
        (esrc.observed_target_recorded_source_hash IS DISTINCT FROM esrc.expected_source_hash)::boolean AS target_hash_mismatch_flag,
        esrc.target_node_code::text AS target_node_code
    FROM tmp_src_m2_12_run_context ctx
    JOIN tmp_src_m2_12_source_edge_physical esrc
      ON esrc.module1_run_id = ctx.module1_run_id
    WHERE esrc.edge_sequence BETWEEN 1 AND 19
)
SELECT
    e.edge_code::text AS edge_code,
    e.edge_sequence::smallint AS edge_sequence,
    e.edge_status::text AS edge_status,
    e.expected_source_hash::text AS expected_source_hash,
    e.module1_run_id::bigint AS module1_run_id,
    e.observed_accepted_source_hash::text AS observed_accepted_source_hash,
    e.observed_target_recorded_source_hash::text AS observed_target_recorded_source_hash,
    e.source_gate_status::text AS source_gate_status,
    e.source_hash_mismatch_flag::boolean AS source_hash_mismatch_flag,
    e.target_hash_mismatch_flag::boolean AS target_hash_mismatch_flag,
    e.target_node_code::text AS target_node_code
FROM edge_rows e;

/* R10 GOVERNED STATEMENT 0056 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_SOURCE_EDGE_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
DO $m212_hf7_source_edge_observation_assert$
BEGIN
    IF NOT (
        (SELECT count(*)=19
             AND count(DISTINCT (module1_run_id,edge_sequence))=19
             AND count(DISTINCT edge_sequence)=19
             AND count(DISTINCT edge_code)=19
             AND min(edge_sequence)=1
             AND max(edge_sequence)=19
             AND bool_and(edge_status='PASS')
         FROM tmp_cert_m2_12_source_edge_observation)
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 source-edge certification mismatch',
            DETAIL=coalesce(
                (SELECT string_agg('edge='||edge_sequence::text||':'||edge_code||'|status='||coalesce(edge_status,'<NULL>'), '; ' ORDER BY edge_sequence)
                 FROM tmp_cert_m2_12_source_edge_observation
                 WHERE edge_status IS DISTINCT FROM 'PASS'),
                'rows='||(SELECT count(*) FROM tmp_cert_m2_12_source_edge_observation)::text);
    END IF;
END;
$m212_hf7_source_edge_observation_assert$;

/* R10 GOVERNED STATEMENT 0057 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_SOURCE_EDGE_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_source_edge_observation_de39bd65 ON tmp_cert_m2_12_source_edge_observation (module1_run_id, edge_sequence);

/* R10 GOVERNED STATEMENT 0058 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_SOURCE_EDGE_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_source_edge_observation;

/* R10 GOVERNED STATEMENT 0059 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_STAGE_BOUNDARY_OBSERVATION_BASE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_cert_m2_12_stage_boundary_observation_base ON COMMIT DROP AS
WITH generic_required_evidence AS
(
    SELECT
        sbm.module1_run_id::bigint AS module1_run_id,
        sbm.node_sequence::smallint AS node_sequence,
        sbm.stage_code::text AS stage_code,
        e.evidence_code::text AS evidence_code,
        e.segment_key::text AS segment_key,
        e.metric_name::text AS metric_name,
        coalesce(e.metric_value_text,e.metric_value_numeric::text)::text AS observed_value_text,
        NULL::text AS expected_value_text,
        e.status::text AS evidence_status,
        'msbf_ctl.run_evidence'::text AS source_relation,
        md5(concat_ws('|',e.evidence_code,e.segment_key,e.metric_name,
                      coalesce(e.metric_value_text,e.metric_value_numeric::text),e.status))::text AS source_row_hash
    FROM tmp_src_m2_12_stage_boundary_method sbm
    JOIN msbf_ctl.run_evidence e
      ON e.run_id=sbm.module1_run_id
     AND e.evidence_code=ANY(sbm.required_evidence_codes)
    WHERE sbm.node_sequence<>1
      AND NOT (sbm.node_sequence=4 AND e.evidence_code='M2_3_POLICY_BOUNDARY')
),
m117_required_evidence AS
(
    SELECT
        sbm.module1_run_id::bigint AS module1_run_id,
        sbm.node_sequence::smallint AS node_sequence,
        sbm.stage_code::text AS stage_code,
        e.evidence_code::text AS evidence_code,
        e.evidence_family::text AS segment_key,
        e.metric_name::text AS metric_name,
        e.observed_value_text::text AS observed_value_text,
        e.expected_value_text::text AS expected_value_text,
        CASE
            WHEN e.evidence_status='PASS'
             AND e.observed_value_text IS NOT DISTINCT FROM e.expected_value_text
             AND e.row_hash ~ '^[0-9a-f]{32}$'
            THEN 'PASS' ELSE 'FAIL'
        END::text AS evidence_status,
        'msbf_ctl.m1_17_end_to_end_evidence_snapshot'::text AS source_relation,
        e.row_hash::text AS source_row_hash
    FROM tmp_src_m2_12_stage_boundary_method sbm
    JOIN msbf_ctl.m1_17_end_to_end_evidence_snapshot e
      ON e.module1_run_id=sbm.module1_run_id
     AND e.evidence_code=ANY(sbm.required_evidence_codes)
    WHERE sbm.node_sequence=1
),
m23_boundary_stats AS
(
    SELECT
        sbm.module1_run_id::bigint AS module1_run_id,
        sbm.node_sequence::smallint AS node_sequence,
        sbm.stage_code::text AS stage_code,
        (SELECT count(*)::integer
           FROM msbf_ctl.m2_3_final_decision_contract_registry r
          WHERE r.module1_run_id=sbm.module1_run_id
            AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND r.contract_version=1
            AND r.contract_status='ACCEPTED') AS registry_rows,
        coalesce((SELECT min(r.decision_latest_rows)::bigint
                    FROM msbf_ctl.m2_3_final_decision_contract_registry r
                   WHERE r.module1_run_id=sbm.module1_run_id
                     AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
                     AND r.contract_version=1
                     AND r.contract_status='ACCEPTED'),-1::bigint) AS expected_latest_rows,
        coalesce((SELECT min(r.decision_archive_rows)::bigint
                    FROM msbf_ctl.m2_3_final_decision_contract_registry r
                   WHERE r.module1_run_id=sbm.module1_run_id
                     AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
                     AND r.contract_version=1
                     AND r.contract_status='ACCEPTED'),-1::bigint) AS expected_archive_rows,
        (SELECT count(*)::integer
           FROM msbf_m2.final_decision_reason_definition d
          WHERE d.module1_run_id=sbm.module1_run_id
            AND d.decision_reason_code='M2_3_POLICY_BOUNDARY') AS reason_definition_rows,
        (SELECT count(*)::integer
           FROM msbf_m2.final_decision_reason_definition d
          WHERE d.module1_run_id=sbm.module1_run_id
            AND d.decision_reason_code='M2_3_POLICY_BOUNDARY'
            AND d.mapped_decision_outcome_code='FINAL_OFFER_AUTHORIZED'
            AND d.production_adverse_action_notice_flag=false
            AND d.reason_status='APPROVED'
            AND d.row_hash ~ '^[0-9a-f]{32}$') AS approved_reason_definition_rows,
        (SELECT count(*)::bigint
           FROM msbf_m2.application_final_offer_decision_latest l
          WHERE l.module1_run_id=sbm.module1_run_id
            AND l.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND l.contract_version=1) AS observed_latest_rows,
        (SELECT count(*)::bigint
           FROM msbf_m2.application_final_offer_decision_latest l
          WHERE l.module1_run_id=sbm.module1_run_id
            AND l.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND l.contract_version=1
            AND l.decision_reason_codes ? 'M2_3_POLICY_BOUNDARY') AS latest_marker_rows,
        (SELECT count(*)::bigint
           FROM msbf_m2.application_final_offer_decision_archive a
          WHERE a.module1_run_id=sbm.module1_run_id
            AND a.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND a.contract_version=1) AS observed_archive_rows,
        (SELECT count(*)::bigint
           FROM msbf_m2.application_final_offer_decision_archive a
          WHERE a.module1_run_id=sbm.module1_run_id
            AND a.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND a.contract_version=1
            AND a.decision_reason_codes ? 'M2_3_POLICY_BOUNDARY') AS archive_marker_rows
    FROM tmp_src_m2_12_stage_boundary_method sbm
    WHERE sbm.node_sequence=4
),
m23_boundary_evidence AS
(
    SELECT
        s.module1_run_id::bigint AS module1_run_id,
        s.node_sequence::smallint AS node_sequence,
        s.stage_code::text AS stage_code,
        'M2_3_POLICY_BOUNDARY'::text AS evidence_code,
        'PHYSICAL_BOUNDARY'::text AS segment_key,
        'M2_3_POLICY_BOUNDARY_PHYSICAL_RECONCILIATION'::text AS metric_name,
        format('registry=%s|reason=%s|approved_reason=%s|latest_expected=%s|latest_observed=%s|latest_marker=%s|archive_expected=%s|archive_observed=%s|archive_marker=%s',
               s.registry_rows,s.reason_definition_rows,s.approved_reason_definition_rows,
               s.expected_latest_rows,s.observed_latest_rows,s.latest_marker_rows,
               s.expected_archive_rows,s.observed_archive_rows,s.archive_marker_rows)::text AS observed_value_text,
        'registry=1|reason=1|approved_reason=1|latest_expected=1500|latest_observed=1500|latest_marker=1500|archive_expected=1500|archive_observed=1500|archive_marker=1500'::text AS expected_value_text,
        CASE
            WHEN s.registry_rows=1
             AND s.reason_definition_rows=1
             AND s.approved_reason_definition_rows=1
             AND s.expected_latest_rows=1500
             AND s.observed_latest_rows=s.expected_latest_rows
             AND s.latest_marker_rows=s.expected_latest_rows
             AND s.expected_archive_rows=1500
             AND s.observed_archive_rows=s.expected_archive_rows
             AND s.archive_marker_rows=s.expected_archive_rows
            THEN 'PASS' ELSE 'FAIL'
        END::text AS evidence_status,
        'msbf_ctl.m2_3_final_decision_contract_registry+msbf_m2.final_decision_reason_definition+msbf_m2.application_final_offer_decision_latest+msbf_m2.application_final_offer_decision_archive'::text AS source_relation,
        md5(concat_ws('|',s.registry_rows::text,s.reason_definition_rows::text,s.approved_reason_definition_rows::text,
                      s.expected_latest_rows::text,s.observed_latest_rows::text,s.latest_marker_rows::text,
                      s.expected_archive_rows::text,s.observed_archive_rows::text,s.archive_marker_rows::text))::text AS source_row_hash
    FROM m23_boundary_stats s
),
normalized_required_evidence AS
(
    SELECT * FROM generic_required_evidence
    UNION ALL
    SELECT * FROM m117_required_evidence
    UNION ALL
    SELECT * FROM m23_boundary_evidence
),
acceptance_summary_stats AS
(
    SELECT
        sbm.module1_run_id,
        sbm.node_sequence,
        (SELECT count(*)::integer
           FROM msbf_ctl.run_evidence e
          WHERE e.run_id=sbm.module1_run_id
            AND e.evidence_code=sbm.acceptance_evidence_code) AS acceptance_summary_rows,
        (SELECT count(*)::integer
           FROM msbf_ctl.run_evidence e
          WHERE e.run_id=sbm.module1_run_id
            AND e.evidence_code=sbm.acceptance_evidence_code
            AND e.status='PASS') AS acceptance_summary_pass_rows
    FROM tmp_src_m2_12_stage_boundary_method sbm
),
normalized_stats AS
(
    SELECT
        n.module1_run_id,
        n.node_sequence,
        count(*)::integer AS physical_required_evidence_rows,
        count(DISTINCT n.evidence_code)::integer AS observed_required_evidence_rows,
        (count(*)-count(DISTINCT n.evidence_code))::integer AS duplicate_required_evidence_rows,
        count(*) FILTER (WHERE n.evidence_status<>'PASS')::integer AS nonpass_evidence_rows,
        coalesce(string_agg(n.evidence_code,'|' ORDER BY n.evidence_code)
                 FILTER (WHERE n.evidence_status<>'PASS'),'')::text AS nonpass_evidence_codes,
        string_agg(DISTINCT n.source_relation,'|' ORDER BY n.source_relation)::text AS source_relation_set,
        md5(coalesce(string_agg(concat_ws('|',n.evidence_code,n.segment_key,n.metric_name,
                                          n.observed_value_text,n.expected_value_text,n.evidence_status,
                                          n.source_relation,n.source_row_hash),
                                '|' ORDER BY n.evidence_code,n.source_relation,n.segment_key,n.metric_name),''))::text AS source_evidence_row_hash
    FROM normalized_required_evidence n
    GROUP BY n.module1_run_id,n.node_sequence
),
missing_stats AS
(
    SELECT
        sbm.module1_run_id,
        sbm.node_sequence,
        string_agg(req.evidence_code,'|' ORDER BY req.evidence_code)::text AS missing_required_evidence_codes
    FROM tmp_src_m2_12_stage_boundary_method sbm
    CROSS JOIN LATERAL unnest(sbm.required_evidence_codes) AS req(evidence_code)
    WHERE NOT EXISTS
          (SELECT 1
             FROM normalized_required_evidence n
            WHERE n.module1_run_id=sbm.module1_run_id
              AND n.node_sequence=sbm.node_sequence
              AND n.evidence_code=req.evidence_code)
    GROUP BY sbm.module1_run_id,sbm.node_sequence
),
violation_evidence AS
(
    SELECT DISTINCT
        sbm.module1_run_id,
        sbm.node_sequence,
        e.evidence_code::text AS evidence_code,
        e.status::text AS evidence_status,
        'msbf_ctl.run_evidence'::text AS source_relation
    FROM tmp_src_m2_12_stage_boundary_method sbm
    JOIN msbf_ctl.run_evidence e
      ON e.run_id=sbm.module1_run_id
     AND (e.evidence_code LIKE sbm.boundary_pattern_1 OR e.evidence_code LIKE sbm.boundary_pattern_2)
    WHERE e.status<>'PASS'
    UNION ALL
    SELECT DISTINCT
        sbm.module1_run_id,
        sbm.node_sequence,
        e.evidence_code::text,
        e.evidence_status::text,
        'msbf_ctl.m1_17_end_to_end_evidence_snapshot'::text
    FROM tmp_src_m2_12_stage_boundary_method sbm
    JOIN msbf_ctl.m1_17_end_to_end_evidence_snapshot e
      ON e.module1_run_id=sbm.module1_run_id
     AND (e.evidence_code LIKE sbm.boundary_pattern_1 OR e.evidence_code LIKE sbm.boundary_pattern_2)
    WHERE sbm.node_sequence=1
      AND e.evidence_status<>'PASS'
    UNION ALL
    SELECT
        m.module1_run_id,
        m.node_sequence,
        m.evidence_code,
        m.evidence_status,
        m.source_relation
    FROM m23_boundary_evidence m
    WHERE m.evidence_status<>'PASS'
),
violation_stats AS
(
    SELECT
        v.module1_run_id,
        v.node_sequence,
        count(DISTINCT (v.source_relation,v.evidence_code))::integer AS violation_rows,
        string_agg(DISTINCT v.source_relation||':'||v.evidence_code,'|' ORDER BY v.source_relation||':'||v.evidence_code)::text AS violation_evidence_codes
    FROM violation_evidence v
    GROUP BY v.module1_run_id,v.node_sequence
)
SELECT
       sbm.accepted_detail_actual_rows::integer AS accepted_detail_actual_rows,
       (sbm.report_exists_status='PASS')::boolean AS accepted_detail_report_exists_flag,
       sbm.accepted_detail_report_sha256::text AS accepted_detail_report_sha256,
       ast.acceptance_summary_rows::integer AS acceptance_summary_rows,
       ast.acceptance_summary_pass_rows::integer AS acceptance_summary_pass_rows,
       (ast.acceptance_summary_rows=1
        AND ast.acceptance_summary_pass_rows=1
        AND coalesce(ns.physical_required_evidence_rows,0)=sbm.required_evidence_code_count
        AND coalesce(ns.observed_required_evidence_rows,0)=sbm.required_evidence_code_count
        AND coalesce(ns.duplicate_required_evidence_rows,0)=0
        AND coalesce(ms.missing_required_evidence_codes,'')='')::boolean AS governing_source_present_flag,
       sbm.matrix_sequence::smallint AS matrix_sequence,
       coalesce(ms.missing_required_evidence_codes,'')::text AS missing_required_evidence_codes,
       sbm.module1_run_id::bigint AS module1_run_id,
       sbm.node_sequence::smallint AS node_sequence,
       coalesce(ns.nonpass_evidence_codes,'')::text AS nonpass_evidence_codes,
       coalesce(ns.nonpass_evidence_rows,0)::integer AS nonpass_evidence_rows,
       coalesce(ns.observed_required_evidence_rows,0)::integer AS observed_required_evidence_rows,
       coalesce(ns.physical_required_evidence_rows,0)::integer AS physical_required_evidence_rows,
       coalesce(ns.duplicate_required_evidence_rows,0)::integer AS duplicate_required_evidence_rows,
       sbm.required_evidence_code_count::integer AS required_evidence_rows,
       coalesce(ns.source_evidence_row_hash,md5(''))::text AS source_evidence_row_hash,
       coalesce(ns.source_relation_set,'')::text AS source_relation_set,
       sbm.stage_code::text AS stage_code,
       coalesce(vs.violation_evidence_codes,'')::text AS violation_evidence_codes,
       coalesce(vs.violation_rows,0)::integer AS violation_rows
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_src_m2_12_stage_boundary_method sbm
  ON sbm.module1_run_id=ctx.module1_run_id
JOIN acceptance_summary_stats ast
  ON ast.module1_run_id=sbm.module1_run_id
 AND ast.node_sequence=sbm.node_sequence
LEFT JOIN normalized_stats ns
  ON ns.module1_run_id=sbm.module1_run_id
 AND ns.node_sequence=sbm.node_sequence
LEFT JOIN missing_stats ms
  ON ms.module1_run_id=sbm.module1_run_id
 AND ms.node_sequence=sbm.node_sequence
LEFT JOIN violation_stats vs
  ON vs.module1_run_id=sbm.module1_run_id
 AND vs.node_sequence=sbm.node_sequence;

/* R10 GOVERNED STATEMENT 0060 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_STAGE_BOUNDARY_OBSERVATION_BASE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_hf8_stage_boundary_base_structure_assert$
BEGIN
    IF NOT coalesce(
        (SELECT count(*)=12
             AND count(DISTINCT (module1_run_id,matrix_sequence))=12
             AND count(DISTINCT node_sequence)=12
             AND min(node_sequence)=1
             AND max(node_sequence)=12
             AND sum(required_evidence_rows)=70
         FROM tmp_cert_m2_12_stage_boundary_observation_base),false)
    THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 stage-boundary observation-base structural mismatch',
            DETAIL=format('rows=%s distinct_matrix=%s distinct_nodes=%s required_controls=%s',
                          (SELECT count(*) FROM tmp_cert_m2_12_stage_boundary_observation_base),
                          (SELECT count(DISTINCT (module1_run_id,matrix_sequence)) FROM tmp_cert_m2_12_stage_boundary_observation_base),
                          (SELECT count(DISTINCT node_sequence) FROM tmp_cert_m2_12_stage_boundary_observation_base),
                          (SELECT coalesce(sum(required_evidence_rows),0) FROM tmp_cert_m2_12_stage_boundary_observation_base));
    END IF;
END;
$m212_hf8_stage_boundary_base_structure_assert$;

/* R10 GOVERNED STATEMENT 0061 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_STAGE_BOUNDARY_OBSERVATION_BASE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_stage_boundary_observation_base_930d27f1 ON tmp_cert_m2_12_stage_boundary_observation_base (module1_run_id, matrix_sequence);

/* R10 GOVERNED STATEMENT 0062 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_STAGE_BOUNDARY_OBSERVATION_BASE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_stage_boundary_observation_base;

/* R10 GOVERNED STATEMENT 0063 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_REPRODUCTION_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
CREATE TEMP TABLE tmp_cert_m2_12_reproduction_observation ON COMMIT DROP AS
WITH reproduction_rows AS
(
    SELECT
        rb.archive_duplicate_key_rows::bigint AS archive_duplicate_key_rows,
        rb.archive_trigger_name::text AS archive_trigger_name,
        rb.archive_trigger_status::text AS archive_trigger_status,
        rb.certification_node_sequence::smallint AS certification_node_sequence,
        rb.component_contract_code::text AS component_contract_code,
        rb.component_sequence::smallint AS component_sequence,
        rb.contract_version::integer AS contract_version,
        rb.latest_duplicate_key_rows::bigint AS latest_duplicate_key_rows,
        rb.missing_archive_rows::bigint AS missing_archive_rows,
        rb.missing_latest_rows::bigint AS missing_latest_rows,
        rb.module1_run_id::bigint AS module1_run_id,
        rb.observed_archive_rows::bigint AS observed_archive_rows,
        rb.observed_archive_set_hash::text AS observed_archive_set_hash,
        rb.observed_latest_rows::bigint AS observed_latest_rows,
        rb.observed_latest_set_hash::text AS observed_latest_set_hash,
        rb.payload_mismatch_count::bigint AS payload_mismatch_count,
        CASE
            WHEN rb.observed_latest_rows = rb.expected_latest_rows
             AND rb.observed_archive_rows = rb.expected_archive_rows
             AND rb.observed_latest_set_hash = rb.expected_latest_set_hash
             AND rb.observed_archive_set_hash = rb.expected_archive_set_hash
             AND rb.payload_mismatch_count = 0
             AND rb.missing_latest_rows = 0
             AND rb.missing_archive_rows = 0
             AND rb.latest_duplicate_key_rows = 0
             AND rb.archive_duplicate_key_rows = 0
             AND rb.archive_trigger_status = 'PASS'
            THEN 'PASS'
            ELSE 'FAIL'
        END::text AS reproduction_status,
        rb.source_registry_row_hash::text AS source_registry_row_hash
    FROM tmp_cert_m2_12_reproduction_observation_base rb
    JOIN tmp_src_m2_12_component_design cd
      ON cd.module1_run_id = rb.module1_run_id
     AND cd.component_sequence = rb.component_sequence
     AND cd.certification_node_sequence = rb.certification_node_sequence
     AND cd.component_contract_code = rb.component_contract_code
     AND cd.contract_version = rb.contract_version
)
SELECT
    r.archive_duplicate_key_rows::bigint AS archive_duplicate_key_rows,
    r.archive_trigger_name::text AS archive_trigger_name,
    r.archive_trigger_status::text AS archive_trigger_status,
    r.certification_node_sequence::smallint AS certification_node_sequence,
    r.component_contract_code::text AS component_contract_code,
    r.component_sequence::smallint AS component_sequence,
    r.contract_version::integer AS contract_version,
    r.latest_duplicate_key_rows::bigint AS latest_duplicate_key_rows,
    r.missing_archive_rows::bigint AS missing_archive_rows,
    r.missing_latest_rows::bigint AS missing_latest_rows,
    r.module1_run_id::bigint AS module1_run_id,
    r.observed_archive_rows::bigint AS observed_archive_rows,
    r.observed_archive_set_hash::text AS observed_archive_set_hash,
    r.observed_latest_rows::bigint AS observed_latest_rows,
    r.observed_latest_set_hash::text AS observed_latest_set_hash,
    r.payload_mismatch_count::bigint AS payload_mismatch_count,
    r.reproduction_status::text AS reproduction_status,
    r.source_registry_row_hash::text AS source_registry_row_hash
FROM reproduction_rows r;

/* R10 GOVERNED STATEMENT 0064 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_REPRODUCTION_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
DO $m212_hf7_reproduction_assert$
BEGIN
    IF NOT (
        (SELECT count(*)=13
             AND count(DISTINCT (module1_run_id,component_sequence))=13
             AND count(DISTINCT component_sequence)=13
             AND count(DISTINCT (component_contract_code,contract_version))=13
             AND min(component_sequence)=1
             AND max(component_sequence)=13
             AND bool_and(reproduction_status='PASS')
         FROM tmp_cert_m2_12_reproduction_observation)
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 contract reproduction mismatch',
            DETAIL=coalesce(
                (SELECT string_agg('component='||component_sequence::text||':'||component_contract_code||'|status='||coalesce(reproduction_status,'<NULL>'), '; ' ORDER BY component_sequence)
                 FROM tmp_cert_m2_12_reproduction_observation
                 WHERE reproduction_status IS DISTINCT FROM 'PASS'),
                'rows='||(SELECT count(*) FROM tmp_cert_m2_12_reproduction_observation)::text);
    END IF;
END;
$m212_hf7_reproduction_assert$;

/* R10 GOVERNED STATEMENT 0065 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_REPRODUCTION_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_reproduction_observation_2a379d41 ON tmp_cert_m2_12_reproduction_observation (module1_run_id, component_sequence);

/* R10 GOVERNED STATEMENT 0066 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_REPRODUCTION_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_reproduction_observation;

/* R10 GOVERNED STATEMENT 0067 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_STAGE_BOUNDARY_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_cert_m2_12_stage_boundary_observation ON COMMIT DROP AS
SELECT
       CASE
           WHEN sbb.governing_source_present_flag
            AND sbb.accepted_detail_report_exists_flag
            AND sbb.accepted_detail_actual_rows=0
            AND sbb.acceptance_summary_rows=1
            AND sbb.acceptance_summary_pass_rows=1
            AND sbb.physical_required_evidence_rows=sbb.required_evidence_rows
            AND sbb.observed_required_evidence_rows=sbb.required_evidence_rows
            AND sbb.duplicate_required_evidence_rows=0
            AND sbb.missing_required_evidence_codes=''
            AND sbb.nonpass_evidence_rows=0
            AND sbb.violation_rows=0
           THEN 'PASS' ELSE 'FAIL'
       END::text AS certification_status,
       sbb.governing_source_present_flag::boolean AS governing_source_present_flag,
       sbb.matrix_sequence::smallint AS matrix_sequence,
       sbb.module1_run_id::bigint AS module1_run_id,
       sbb.node_sequence::smallint AS node_sequence,
       sbb.nonpass_evidence_rows::integer AS nonpass_evidence_rows,
       format('required=%s; physical=%s; distinct=%s; duplicates=%s; missing=%s; nonpass=%s; violations=%s; acceptance=%s/%s; report_rows=%s',
              sbb.required_evidence_rows,sbb.physical_required_evidence_rows,sbb.observed_required_evidence_rows,
              sbb.duplicate_required_evidence_rows,coalesce(nullif(sbb.missing_required_evidence_codes,''),'<NONE>'),
              sbb.nonpass_evidence_rows,sbb.violation_rows,sbb.acceptance_summary_pass_rows,sbb.acceptance_summary_rows,
              sbb.accepted_detail_actual_rows)::text AS observed_count_or_identity,
       md5(concat_ws('|',sbb.stage_code,sbb.accepted_detail_report_sha256,
                     sbb.acceptance_summary_rows::text,sbb.acceptance_summary_pass_rows::text,
                     sbb.required_evidence_rows::text,sbb.physical_required_evidence_rows::text,
                     sbb.observed_required_evidence_rows::text,sbb.duplicate_required_evidence_rows::text,
                     sbb.missing_required_evidence_codes,sbb.nonpass_evidence_rows::text,sbb.nonpass_evidence_codes,
                     sbb.violation_rows::text,sbb.violation_evidence_codes,sbb.source_relation_set,
                     sbb.source_evidence_row_hash))::text AS observed_hash,
       sbb.observed_required_evidence_rows::integer AS observed_required_evidence_rows,
       CASE
           WHEN sbb.governing_source_present_flag
            AND sbb.accepted_detail_report_exists_flag
            AND sbb.accepted_detail_actual_rows=0
            AND sbb.acceptance_summary_rows=1
            AND sbb.acceptance_summary_pass_rows=1
            AND sbb.physical_required_evidence_rows=sbb.required_evidence_rows
            AND sbb.observed_required_evidence_rows=sbb.required_evidence_rows
            AND sbb.duplicate_required_evidence_rows=0
            AND sbb.missing_required_evidence_codes=''
            AND sbb.nonpass_evidence_rows=0
            AND sbb.violation_rows=0
           THEN 'PASS' ELSE 'FAIL'
       END::text AS observed_status,
       sbb.required_evidence_rows::integer AS required_evidence_rows,
       sbb.source_evidence_row_hash::text AS source_evidence_row_hash,
       sbb.stage_code::text AS stage_code,
       sbb.violation_rows::integer AS violation_rows,
       sbb.acceptance_summary_rows::integer AS acceptance_summary_rows,
       sbb.acceptance_summary_pass_rows::integer AS acceptance_summary_pass_rows,
       sbb.physical_required_evidence_rows::integer AS physical_required_evidence_rows,
       sbb.duplicate_required_evidence_rows::integer AS duplicate_required_evidence_rows,
       sbb.missing_required_evidence_codes::text AS missing_required_evidence_codes,
       sbb.nonpass_evidence_codes::text AS nonpass_evidence_codes,
       sbb.violation_evidence_codes::text AS violation_evidence_codes,
       sbb.source_relation_set::text AS source_relation_set
FROM tmp_src_m2_12_run_context ctx
JOIN tmp_cert_m2_12_stage_boundary_observation_base sbb
  ON sbb.module1_run_id=ctx.module1_run_id;

/* R10 GOVERNED STATEMENT 0068 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_STAGE_BOUNDARY_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_hf8_stage_boundary_assert$
BEGIN
    IF NOT coalesce(
        (SELECT count(*)=12
             AND count(DISTINCT (module1_run_id,matrix_sequence))=12
             AND count(DISTINCT node_sequence)=12
             AND min(node_sequence)=1
             AND max(node_sequence)=12
             AND bool_and(certification_status='PASS')
         FROM tmp_cert_m2_12_stage_boundary_observation),false)
    THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 stage-boundary certification mismatch',
            DETAIL=coalesce(
                (SELECT string_agg(
                    'node='||node_sequence::text||':'||stage_code||
                    '|status='||coalesce(certification_status,'<NULL>')||
                    '|acceptance='||acceptance_summary_pass_rows::text||'/'||acceptance_summary_rows::text||
                    '|required='||required_evidence_rows::text||
                    '|physical='||physical_required_evidence_rows::text||
                    '|distinct='||observed_required_evidence_rows::text||
                    '|duplicates='||duplicate_required_evidence_rows::text||
                    '|missing='||coalesce(nullif(missing_required_evidence_codes,''),'<NONE>')||
                    '|nonpass='||coalesce(nullif(nonpass_evidence_codes,''),'<NONE>')||
                    '|violations='||coalesce(nullif(violation_evidence_codes,''),'<NONE>')||
                    '|sources='||coalesce(nullif(source_relation_set,''),'<NONE>'),
                    '; ' ORDER BY node_sequence)
                 FROM tmp_cert_m2_12_stage_boundary_observation
                 WHERE certification_status IS DISTINCT FROM 'PASS'),
                'rows='||(SELECT count(*) FROM tmp_cert_m2_12_stage_boundary_observation)::text);
    END IF;
END;
$m212_hf8_stage_boundary_assert$;

/* R10 GOVERNED STATEMENT 0069 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_STAGE_BOUNDARY_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_stage_boundary_observation_cd1dac9c ON tmp_cert_m2_12_stage_boundary_observation (module1_run_id, matrix_sequence);

/* R10 GOVERNED STATEMENT 0070 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_STAGE_BOUNDARY_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_stage_boundary_observation;

/* R10 GOVERNED STATEMENT 0071 OF 0206
   statement_code: CREATE_TMP_SRC_M2_12_COMPONENT_OBSERVATION_BASE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_component_observation_base ON COMMIT DROP AS
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r01.module1_run_id
                    AND e.evidence_code='M1_17_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       1::smallint AS certification_node_sequence,
       r01.bundle_code::text AS component_contract_code,
       1::smallint AS component_sequence,
       r01.bundle_status::text AS contract_status,
       r01.bundle_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r01.module1_run_id
                    AND g.gate_id='G2_M1_CONTRACT'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r01.methodology_version::text AS methodology_version,
       r01.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_archive a WHERE a.module1_run_id=r01.module1_run_id AND a.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND a.bundle_version=r01.bundle_version) AS observed_archive_rows,
       r01.bundle_archive_set_hash::text AS observed_archive_set_hash,
       r01.canonical_entities::bigint AS observed_canonical_entities,
       r01.contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_latest l WHERE l.module1_run_id=r01.module1_run_id AND l.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND l.bundle_version=r01.bundle_version) AS observed_latest_rows,
       r01.bundle_latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r01.module1_run_id
          AND e.evidence_code LIKE 'M1_17_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r01.module1_run_id
          AND e.evidence_code LIKE 'M1_17_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r01.row_hash::text AS observed_registry_row_hash,
       r01.combined_g2_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=1
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r01.schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m1_17_g2_bundle_registry r01
  ON r01.module1_run_id=ctx.module1_run_id
 AND r01.bundle_code='M1_G2_CONSUMPTION_BUNDLE'
 AND r01.bundle_version=1)
UNION ALL
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r02.module1_run_id
                    AND e.evidence_code='M2_1_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       2::smallint AS certification_node_sequence,
       r02.contract_code::text AS component_contract_code,
       2::smallint AS component_sequence,
       r02.contract_status::text AS contract_status,
       r02.contract_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r02.module1_run_id
                    AND g.gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r02.methodology_version::text AS methodology_version,
       r02.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_archive a WHERE a.module1_run_id=r02.module1_run_id AND a.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND a.contract_version=r02.contract_version) AS observed_archive_rows,
       r02.archive_set_hash::text AS observed_archive_set_hash,
       r02.canonical_entities::bigint AS observed_canonical_entities,
       r02.contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_latest l WHERE l.module1_run_id=r02.module1_run_id AND l.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND l.contract_version=r02.contract_version) AS observed_latest_rows,
       r02.latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r02.module1_run_id
          AND e.evidence_code LIKE 'M2_1_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r02.module1_run_id
          AND e.evidence_code LIKE 'M2_1_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r02.row_hash::text AS observed_registry_row_hash,
       r02.combined_set_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=2
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r02.schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m2_1_strategy_contract_registry r02
  ON r02.module1_run_id=ctx.module1_run_id
 AND r02.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION'
 AND r02.contract_version=1)
UNION ALL
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r03.module1_run_id
                    AND e.evidence_code='M2_2_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       3::smallint AS certification_node_sequence,
       r03.request_contract_code::text AS component_contract_code,
       3::smallint AS component_sequence,
       r03.contract_status::text AS contract_status,
       r03.request_contract_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r03.module1_run_id
                    AND g.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r03.methodology_version::text AS methodology_version,
       r03.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_archive a WHERE a.module1_run_id=r03.module1_run_id AND a.contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND a.contract_version=r03.request_contract_version) AS observed_archive_rows,
       r03.request_archive_set_hash::text AS observed_archive_set_hash,
       r03.canonical_entities::bigint AS observed_canonical_entities,
       r03.request_contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_latest l WHERE l.module1_run_id=r03.module1_run_id AND l.contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND l.contract_version=r03.request_contract_version) AS observed_latest_rows,
       r03.request_latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r03.module1_run_id
          AND e.evidence_code LIKE 'M2_2_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r03.module1_run_id
          AND e.evidence_code LIKE 'M2_2_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r03.row_hash::text AS observed_registry_row_hash,
       r03.combined_set_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=3
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r03.request_schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m2_2_pricing_structure_contract_registry r03
  ON r03.module1_run_id=ctx.module1_run_id
 AND r03.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION'
 AND r03.request_contract_version=1)
UNION ALL
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r04.module1_run_id
                    AND e.evidence_code='M2_2_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       3::smallint AS certification_node_sequence,
       r04.pricing_contract_code::text AS component_contract_code,
       4::smallint AS component_sequence,
       r04.contract_status::text AS contract_status,
       r04.pricing_contract_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r04.module1_run_id
                    AND g.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r04.methodology_version::text AS methodology_version,
       r04.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_archive a WHERE a.module1_run_id=r04.module1_run_id AND a.contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND a.contract_version=r04.pricing_contract_version) AS observed_archive_rows,
       r04.pricing_archive_set_hash::text AS observed_archive_set_hash,
       r04.canonical_entities::bigint AS observed_canonical_entities,
       r04.pricing_contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_latest l WHERE l.module1_run_id=r04.module1_run_id AND l.contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND l.contract_version=r04.pricing_contract_version) AS observed_latest_rows,
       r04.pricing_latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r04.module1_run_id
          AND e.evidence_code LIKE 'M2_2_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r04.module1_run_id
          AND e.evidence_code LIKE 'M2_2_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r04.row_hash::text AS observed_registry_row_hash,
       r04.combined_set_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=4
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r04.pricing_schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m2_2_pricing_structure_contract_registry r04
  ON r04.module1_run_id=ctx.module1_run_id
 AND r04.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION'
 AND r04.pricing_contract_version=1)
UNION ALL
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r05.module1_run_id
                    AND e.evidence_code='M2_3_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       4::smallint AS certification_node_sequence,
       r05.contract_code::text AS component_contract_code,
       5::smallint AS component_sequence,
       r05.contract_status::text AS contract_status,
       r05.contract_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r05.module1_run_id
                    AND g.gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r05.methodology_version::text AS methodology_version,
       r05.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_archive a WHERE a.module1_run_id=r05.module1_run_id AND a.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND a.contract_version=r05.contract_version) AS observed_archive_rows,
       r05.decision_archive_set_hash::text AS observed_archive_set_hash,
       r05.canonical_entities::bigint AS observed_canonical_entities,
       r05.contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_latest l WHERE l.module1_run_id=r05.module1_run_id AND l.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND l.contract_version=r05.contract_version) AS observed_latest_rows,
       r05.decision_latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r05.module1_run_id
          AND e.evidence_code LIKE 'M2_3_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r05.module1_run_id
          AND e.evidence_code LIKE 'M2_3_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r05.row_hash::text AS observed_registry_row_hash,
       r05.combined_set_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=5
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r05.schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m2_3_final_decision_contract_registry r05
  ON r05.module1_run_id=ctx.module1_run_id
 AND r05.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
 AND r05.contract_version=1)
UNION ALL
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r06.module1_run_id
                    AND e.evidence_code='M2_4_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       5::smallint AS certification_node_sequence,
       r06.contract_code::text AS component_contract_code,
       6::smallint AS component_sequence,
       r06.contract_status::text AS contract_status,
       r06.contract_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r06.module1_run_id
                    AND g.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r06.methodology_version::text AS methodology_version,
       r06.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_archive a WHERE a.module1_run_id=r06.module1_run_id AND a.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND a.contract_version=r06.contract_version) AS observed_archive_rows,
       r06.activation_archive_set_hash::text AS observed_archive_set_hash,
       r06.canonical_entities::bigint AS observed_canonical_entities,
       r06.contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_latest l WHERE l.module1_run_id=r06.module1_run_id AND l.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND l.contract_version=r06.contract_version) AS observed_latest_rows,
       r06.activation_latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r06.module1_run_id
          AND e.evidence_code LIKE 'M2_4_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r06.module1_run_id
          AND e.evidence_code LIKE 'M2_4_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r06.row_hash::text AS observed_registry_row_hash,
       r06.combined_set_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=6
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r06.schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m2_4_portfolio_activation_contract_registry r06
  ON r06.module1_run_id=ctx.module1_run_id
 AND r06.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
 AND r06.contract_version=1)
UNION ALL
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r07.module1_run_id
                    AND e.evidence_code='M2_5_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       6::smallint AS certification_node_sequence,
       r07.contract_code::text AS component_contract_code,
       7::smallint AS component_sequence,
       r07.contract_status::text AS contract_status,
       r07.contract_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r07.module1_run_id
                    AND g.gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r07.methodology_version::text AS methodology_version,
       r07.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_archive a WHERE a.module1_run_id=r07.module1_run_id AND a.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND a.contract_version=r07.contract_version) AS observed_archive_rows,
       r07.archive_set_hash::text AS observed_archive_set_hash,
       r07.canonical_entities::bigint AS observed_canonical_entities,
       r07.contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_latest l WHERE l.module1_run_id=r07.module1_run_id AND l.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND l.contract_version=r07.contract_version) AS observed_latest_rows,
       r07.latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r07.module1_run_id
          AND e.evidence_code LIKE 'M2_5_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r07.module1_run_id
          AND e.evidence_code LIKE 'M2_5_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r07.row_hash::text AS observed_registry_row_hash,
       r07.combined_set_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=7
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r07.schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m2_5_portfolio_monitoring_contract_registry r07
  ON r07.module1_run_id=ctx.module1_run_id
 AND r07.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'
 AND r07.contract_version=1)
UNION ALL
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r08.module1_run_id
                    AND e.evidence_code='M2_6_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       7::smallint AS certification_node_sequence,
       r08.contract_code::text AS component_contract_code,
       8::smallint AS component_sequence,
       r08.contract_status::text AS contract_status,
       r08.contract_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r08.module1_run_id
                    AND g.gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r08.methodology_version::text AS methodology_version,
       r08.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_archive a WHERE a.module1_run_id=r08.module1_run_id AND a.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND a.contract_version=r08.contract_version) AS observed_archive_rows,
       r08.archive_set_hash::text AS observed_archive_set_hash,
       r08.canonical_entities::bigint AS observed_canonical_entities,
       r08.contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_latest l WHERE l.module1_run_id=r08.module1_run_id AND l.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND l.contract_version=r08.contract_version) AS observed_latest_rows,
       r08.latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r08.module1_run_id
          AND e.evidence_code LIKE 'M2_6_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r08.module1_run_id
          AND e.evidence_code LIKE 'M2_6_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r08.row_hash::text AS observed_registry_row_hash,
       r08.combined_set_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=8
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r08.schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m2_6_intervention_strategy_contract_registry r08
  ON r08.module1_run_id=ctx.module1_run_id
 AND r08.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'
 AND r08.contract_version=1)
UNION ALL
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r09.module1_run_id
                    AND e.evidence_code='M2_7_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       8::smallint AS certification_node_sequence,
       r09.contract_code::text AS component_contract_code,
       9::smallint AS component_sequence,
       r09.contract_status::text AS contract_status,
       r09.contract_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r09.module1_run_id
                    AND g.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r09.methodology_version::text AS methodology_version,
       r09.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_archive a WHERE a.module1_run_id=r09.module1_run_id AND a.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND a.contract_version=r09.contract_version) AS observed_archive_rows,
       r09.archive_set_hash::text AS observed_archive_set_hash,
       r09.canonical_entities::bigint AS observed_canonical_entities,
       r09.contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_latest l WHERE l.module1_run_id=r09.module1_run_id AND l.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND l.contract_version=r09.contract_version) AS observed_latest_rows,
       r09.latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r09.module1_run_id
          AND e.evidence_code LIKE 'M2_7_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r09.module1_run_id
          AND e.evidence_code LIKE 'M2_7_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r09.row_hash::text AS observed_registry_row_hash,
       r09.combined_set_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=9
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r09.schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m2_7_operational_activation_contract_registry r09
  ON r09.module1_run_id=ctx.module1_run_id
 AND r09.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'
 AND r09.contract_version=1)
UNION ALL
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r10.module1_run_id
                    AND e.evidence_code='M2_8_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       9::smallint AS certification_node_sequence,
       r10.contract_code::text AS component_contract_code,
       10::smallint AS component_sequence,
       r10.contract_status::text AS contract_status,
       r10.contract_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r10.module1_run_id
                    AND g.gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r10.methodology_version::text AS methodology_version,
       r10.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_archive a WHERE a.module1_run_id=r10.module1_run_id AND a.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND a.contract_version=r10.contract_version) AS observed_archive_rows,
       r10.archive_set_hash::text AS observed_archive_set_hash,
       r10.canonical_entities::bigint AS observed_canonical_entities,
       r10.contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_latest l WHERE l.module1_run_id=r10.module1_run_id AND l.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND l.contract_version=r10.contract_version) AS observed_latest_rows,
       r10.latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r10.module1_run_id
          AND e.evidence_code LIKE 'M2_8_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r10.module1_run_id
          AND e.evidence_code LIKE 'M2_8_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r10.row_hash::text AS observed_registry_row_hash,
       r10.combined_set_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=10
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r10.schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m2_8_servicing_execution_contract_registry r10
  ON r10.module1_run_id=ctx.module1_run_id
 AND r10.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION'
 AND r10.contract_version=1)
UNION ALL
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r11.module1_run_id
                    AND e.evidence_code='M2_9_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       10::smallint AS certification_node_sequence,
       r11.contract_code::text AS component_contract_code,
       11::smallint AS component_sequence,
       r11.contract_status::text AS contract_status,
       r11.contract_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r11.module1_run_id
                    AND g.gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r11.methodology_version::text AS methodology_version,
       r11.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_archive a WHERE a.module1_run_id=r11.module1_run_id AND a.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND a.contract_version=r11.contract_version) AS observed_archive_rows,
       r11.archive_set_hash::text AS observed_archive_set_hash,
       r11.canonical_entities::bigint AS observed_canonical_entities,
       r11.contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_latest l WHERE l.module1_run_id=r11.module1_run_id AND l.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND l.contract_version=r11.contract_version) AS observed_latest_rows,
       r11.latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r11.module1_run_id
          AND e.evidence_code LIKE 'M2_9_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r11.module1_run_id
          AND e.evidence_code LIKE 'M2_9_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r11.row_hash::text AS observed_registry_row_hash,
       r11.combined_set_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=11
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r11.schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m2_9_reconciliation_certification_contract_registry r11
  ON r11.module1_run_id=ctx.module1_run_id
 AND r11.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'
 AND r11.contract_version=1)
UNION ALL
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r12.module1_run_id
                    AND e.evidence_code='M2_10_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       11::smallint AS certification_node_sequence,
       r12.contract_code::text AS component_contract_code,
       12::smallint AS component_sequence,
       r12.contract_status::text AS contract_status,
       r12.contract_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r12.module1_run_id
                    AND g.gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r12.methodology_version::text AS methodology_version,
       r12.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_archive a WHERE a.module1_run_id=r12.module1_run_id AND a.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND a.contract_version=r12.contract_version) AS observed_archive_rows,
       r12.archive_set_hash::text AS observed_archive_set_hash,
       r12.canonical_entities::bigint AS observed_canonical_entities,
       r12.contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_latest l WHERE l.module1_run_id=r12.module1_run_id AND l.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND l.contract_version=r12.contract_version) AS observed_latest_rows,
       r12.latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r12.module1_run_id
          AND e.evidence_code LIKE 'M2_10_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r12.module1_run_id
          AND e.evidence_code LIKE 'M2_10_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r12.row_hash::text AS observed_registry_row_hash,
       r12.combined_set_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=12
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r12.schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m2_10_portfolio_analytics_contract_registry r12
  ON r12.module1_run_id=ctx.module1_run_id
 AND r12.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'
 AND r12.contract_version=1)
UNION ALL
(SELECT
       CASE WHEN (SELECT count(*) FROM msbf_ctl.run_evidence e
                  WHERE e.run_id=r13.module1_run_id
                    AND e.evidence_code='M2_11_ACCEPTANCE_SUMMARY'
                    AND e.status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS acceptance_evidence_status,
       12::smallint AS certification_node_sequence,
       r13.contract_code::text AS component_contract_code,
       13::smallint AS component_sequence,
       r13.contract_status::text AS contract_status,
       r13.contract_version::integer AS contract_version,
       CASE WHEN (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g
                  WHERE g.run_id=r13.module1_run_id
                    AND g.gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
                    AND g.review_version=1
                    AND g.result_status='PASS')=1
            THEN 'PASS'::text ELSE 'FAIL'::text END AS gate_status,
       r13.methodology_version::text AS methodology_version,
       r13.module1_run_id::bigint AS module1_run_id,
       (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_archive a WHERE a.module1_run_id=r13.module1_run_id AND a.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND a.contract_version=r13.contract_version) AS observed_archive_rows,
       r13.archive_set_hash::text AS observed_archive_set_hash,
       r13.canonical_entities::bigint AS observed_canonical_entities,
       r13.contract_set_hash::text AS observed_contract_set_hash,
       (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_latest l WHERE l.module1_run_id=r13.module1_run_id AND l.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND l.contract_version=r13.contract_version) AS observed_latest_rows,
       r13.latest_set_hash::text AS observed_latest_set_hash,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r13.module1_run_id
          AND e.evidence_code LIKE 'M2_11_NEG_%'
          AND e.status='PASS') AS observed_negative_controls,
       (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
        WHERE e.run_id=r13.module1_run_id
          AND e.evidence_code LIKE 'M2_11_POS_%'
          AND e.status='PASS') AS observed_positive_controls,
       r13.row_hash::text AS observed_registry_row_hash,
       r13.combined_set_hash::text AS observed_stage_combined_set_hash,
       (SELECT count(*)::smallint
        FROM tmp_src_m2_12_component_edge_requirement cer
        JOIN tmp_cert_m2_12_source_edge_observation seo
          ON seo.module1_run_id=cer.module1_run_id
         AND seo.edge_code=cer.edge_code
        WHERE cer.module1_run_id=ctx.module1_run_id
          AND cer.component_sequence=13
          AND cer.required_status='PASS'
          AND seo.edge_status='PASS') AS passed_source_edge_count,
       r13.schema_version::text AS schema_version
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry r13
  ON r13.module1_run_id=ctx.module1_run_id
 AND r13.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
 AND r13.contract_version=1);

/* R10 GOVERNED STATEMENT 0072 OF 0206
   statement_code: ASSERT_TMP_SRC_M2_12_COMPONENT_OBSERVATION_BASE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_hf7_component_observation_base_assert$
BEGIN
    IF NOT (
        (SELECT count(*)=13
             AND count(DISTINCT (module1_run_id,component_sequence))=13
             AND count(DISTINCT component_sequence)=13
             AND count(DISTINCT (component_contract_code,contract_version))=13
             AND min(component_sequence)=1
             AND max(component_sequence)=13
             AND bool_and(contract_status='ACCEPTED')
             AND bool_and(gate_status='PASS')
             AND bool_and(acceptance_evidence_status='PASS')
         FROM tmp_src_m2_12_component_observation_base)
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 component observation base mismatch',
            DETAIL=coalesce(
                (SELECT string_agg(
                    'component='||component_sequence::text||':'||component_contract_code||
                    '|contract_status='||coalesce(contract_status,'<NULL>')||
                    '|gate_status='||coalesce(gate_status,'<NULL>')||
                    '|acceptance_evidence='||coalesce(acceptance_evidence_status,'<NULL>'),
                    '; ' ORDER BY component_sequence)
                 FROM tmp_src_m2_12_component_observation_base
                 WHERE contract_status IS DISTINCT FROM 'ACCEPTED'
                    OR gate_status IS DISTINCT FROM 'PASS'
                    OR acceptance_evidence_status IS DISTINCT FROM 'PASS'),
                'rows='||(SELECT count(*) FROM tmp_src_m2_12_component_observation_base)::text||
                '|distinct_components='||(SELECT count(DISTINCT component_sequence) FROM tmp_src_m2_12_component_observation_base)::text);
    END IF;
END;
$m212_hf7_component_observation_base_assert$;

/* R10 GOVERNED STATEMENT 0073 OF 0206
   statement_code: INDEX_TMP_SRC_M2_12_COMPONENT_OBSERVATION_BASE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_component_observation_base_e3aff984 ON tmp_src_m2_12_component_observation_base (module1_run_id, component_sequence);

/* R10 GOVERNED STATEMENT 0074 OF 0206
   statement_code: ANALYZE_TMP_SRC_M2_12_COMPONENT_OBSERVATION_BASE
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_component_observation_base;

/* R10 GOVERNED STATEMENT 0075 OF 0206
   statement_code: CREATE_TMP_SRC_M2_12_COMPONENT_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_component_observation ON COMMIT DROP AS
SELECT
       cob.acceptance_evidence_status::text AS acceptance_evidence_status,
       cob.certification_node_sequence::smallint AS certification_node_sequence,
       CASE WHEN cob.contract_status='ACCEPTED'
                  AND cob.gate_status='PASS'
                  AND cob.acceptance_evidence_status='PASS'
                  AND cob.schema_version=cd.schema_version
                  AND cob.methodology_version=cd.methodology_version
                  AND cob.observed_canonical_entities=cd.stage_expected_canonical_entities
                  AND cob.observed_latest_rows=cd.expected_latest_rows
                  AND cob.observed_archive_rows=cd.expected_archive_rows
                  AND cob.observed_positive_controls=cd.expected_positive_controls
                  AND cob.observed_negative_controls=cd.expected_negative_controls
                  AND cob.observed_contract_set_hash=cd.expected_contract_set_hash
                  AND cob.observed_stage_combined_set_hash=cd.expected_stage_combined_set_hash
                  AND cob.observed_registry_row_hash=cd.expected_registry_row_hash
                  AND cob.observed_latest_set_hash=cd.expected_latest_set_hash
                  AND cob.observed_archive_set_hash=cd.expected_archive_set_hash
                  AND cob.passed_source_edge_count=cd.required_source_edge_count
            THEN 'PASS'::text ELSE 'FAIL'::text END AS certification_status,
       cob.component_contract_code::text AS component_contract_code,
       cob.component_sequence::smallint AS component_sequence,
       cob.contract_status::text AS contract_status,
       cob.contract_version::integer AS contract_version,
       cob.gate_status::text AS gate_status,
       cob.methodology_version::text AS methodology_version,
       cob.module1_run_id::bigint AS module1_run_id,
       cob.observed_archive_rows::bigint AS observed_archive_rows,
       cob.observed_archive_set_hash::text AS observed_archive_set_hash,
       cob.observed_canonical_entities::bigint AS observed_canonical_entities,
       cob.observed_contract_set_hash::text AS observed_contract_set_hash,
       cob.observed_latest_rows::bigint AS observed_latest_rows,
       cob.observed_latest_set_hash::text AS observed_latest_set_hash,
       cob.observed_negative_controls::integer AS observed_negative_controls,
       cob.observed_positive_controls::integer AS observed_positive_controls,
       cob.observed_registry_row_hash::text AS observed_registry_row_hash,
       cob.observed_stage_combined_set_hash::text AS observed_stage_combined_set_hash,
       cob.passed_source_edge_count::smallint AS passed_source_edge_count,
       cob.schema_version::text AS schema_version
FROM tmp_src_m2_12_component_observation_base cob
JOIN tmp_src_m2_12_component_design cd
  ON cd.module1_run_id=cob.module1_run_id
 AND cd.component_sequence=cob.component_sequence
 AND cd.component_contract_code=cob.component_contract_code
 AND cd.contract_version=cob.contract_version
JOIN tmp_src_m2_12_run_context ctx
  ON ctx.module1_run_id=cob.module1_run_id;

/* R10 GOVERNED STATEMENT 0076 OF 0206
   statement_code: ASSERT_TMP_SRC_M2_12_COMPONENT_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_hf7_component_observation_assert$
BEGIN
    IF NOT (
        (SELECT count(*)=13
             AND count(DISTINCT (module1_run_id,component_sequence))=13
             AND count(DISTINCT component_sequence)=13
             AND count(DISTINCT (component_contract_code,contract_version))=13
             AND min(component_sequence)=1
             AND max(component_sequence)=13
             AND bool_and(certification_status='PASS')
         FROM tmp_src_m2_12_component_observation)
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 component certification mismatch',
            DETAIL=coalesce(
                (SELECT string_agg(
                    'component='||co.component_sequence::text||':'||co.component_contract_code||
                    '|status='||co.certification_status||
                    '|latest='||co.observed_latest_rows::text||'/'||cd.expected_latest_rows::text||
                    '|archive='||co.observed_archive_rows::text||'/'||cd.expected_archive_rows::text||
                    '|positive='||co.observed_positive_controls::text||'/'||cd.expected_positive_controls::text||
                    '|negative='||co.observed_negative_controls::text||'/'||cd.expected_negative_controls::text||
                    '|edges='||co.passed_source_edge_count::text||'/'||cd.required_source_edge_count::text,
                    '; ' ORDER BY co.component_sequence)
                 FROM tmp_src_m2_12_component_observation co
                 JOIN tmp_src_m2_12_component_design cd
                   ON cd.module1_run_id=co.module1_run_id
                  AND cd.component_sequence=co.component_sequence
                 WHERE co.certification_status IS DISTINCT FROM 'PASS'),
                'rows='||(SELECT count(*) FROM tmp_src_m2_12_component_observation)::text);
    END IF;
END;
$m212_hf7_component_observation_assert$;

/* R10 GOVERNED STATEMENT 0077 OF 0206
   statement_code: INDEX_TMP_SRC_M2_12_COMPONENT_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_component_observation_006a6430 ON tmp_src_m2_12_component_observation (module1_run_id, component_sequence);

/* R10 GOVERNED STATEMENT 0078 OF 0206
   statement_code: ANALYZE_TMP_SRC_M2_12_COMPONENT_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_component_observation;

/* R10 GOVERNED STATEMENT 0079 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_EVIDENCE_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
CREATE TEMP TABLE tmp_cert_m2_12_evidence_observation ON COMMIT DROP AS
WITH component_design_node AS
(
    SELECT
        module1_run_id,
        certification_node_sequence,
        count(*)::integer AS expected_component_rows
    FROM tmp_src_m2_12_component_design
    GROUP BY module1_run_id, certification_node_sequence
),
component_node AS
(
    SELECT
        module1_run_id,
        certification_node_sequence,
        count(*)::integer AS component_rows,
        count(*) FILTER (WHERE contract_status = 'ACCEPTED')::integer AS accepted_contract_rows,
        count(*) FILTER (WHERE gate_status = 'PASS')::integer AS gate_pass_rows,
        count(*) FILTER (WHERE acceptance_evidence_status = 'PASS')::integer AS acceptance_pass_rows,
        count(*) FILTER (WHERE certification_status = 'PASS')::integer AS certified_component_rows,
        min(observed_canonical_entities)::bigint AS min_canonical_entities,
        max(observed_canonical_entities)::bigint AS max_canonical_entities,
        min(observed_stage_combined_set_hash)::text AS min_combined_hash,
        max(observed_stage_combined_set_hash)::text AS max_combined_hash,
        min(observed_registry_row_hash)::text AS min_registry_hash,
        max(observed_registry_row_hash)::text AS max_registry_hash,
        md5(
            string_agg(
                concat_ws(
                    '|',
                    component_sequence::text,
                    component_contract_code,
                    contract_version::text,
                    contract_status,
                    gate_status,
                    acceptance_evidence_status,
                    certification_status,
                    coalesce(observed_registry_row_hash, '<NULL>')
                ),
                '|' ORDER BY component_sequence, component_contract_code, contract_version
            )
        )::text AS component_fingerprint,
        md5(
            string_agg(
                coalesce(observed_registry_row_hash, '<NULL>'),
                '|' ORDER BY component_sequence, component_contract_code, contract_version
            )
        )::text AS registry_fingerprint
    FROM tmp_src_m2_12_component_observation
    GROUP BY module1_run_id, certification_node_sequence
),
reproduction_node AS
(
    SELECT
        module1_run_id,
        certification_node_sequence,
        count(*)::integer AS reproduction_rows,
        count(*) FILTER (WHERE reproduction_status = 'PASS')::integer AS reproduction_pass_rows,
        min(source_registry_row_hash)::text AS min_registry_hash,
        max(source_registry_row_hash)::text AS max_registry_hash,
        md5(
            string_agg(
                concat_ws(
                    '|',
                    component_sequence::text,
                    component_contract_code,
                    contract_version::text,
                    reproduction_status,
                    observed_latest_rows::text,
                    observed_archive_rows::text,
                    coalesce(observed_latest_set_hash, '<NULL>'),
                    coalesce(observed_archive_set_hash, '<NULL>'),
                    payload_mismatch_count::text,
                    missing_latest_rows::text,
                    missing_archive_rows::text,
                    latest_duplicate_key_rows::text,
                    archive_duplicate_key_rows::text,
                    archive_trigger_status
                ),
                '|' ORDER BY component_sequence, component_contract_code, contract_version
            )
        )::text AS reproduction_fingerprint
    FROM tmp_cert_m2_12_reproduction_observation
    GROUP BY module1_run_id, certification_node_sequence
),
evidence_rows AS
(
    SELECT
        CASE ed.evidence_family_code
            WHEN 'ACCEPTANCE_LIFECYCLE' THEN
                CASE
                    WHEN cn.component_rows = cdn.expected_component_rows
                     AND cn.accepted_contract_rows = cdn.expected_component_rows
                     AND cn.gate_pass_rows = cdn.expected_component_rows
                     AND cn.acceptance_pass_rows = cdn.expected_component_rows
                    THEN 'PASS' ELSE 'FAIL'
                END
            WHEN 'POSITIVE_VALIDATION' THEN coalesce(pos.aggregate_status, 'FAIL')
            WHEN 'NEGATIVE_CONTROLS' THEN coalesce(neg.aggregate_status, 'FAIL')
            WHEN 'CANONICAL_IDENTITY' THEN
                CASE
                    WHEN cn.component_rows = cdn.expected_component_rows
                     AND cn.min_canonical_entities = nd.expected_canonical_entities
                     AND cn.max_canonical_entities = nd.expected_canonical_entities
                     AND cn.min_combined_hash = nd.expected_combined_hash
                     AND cn.max_combined_hash = nd.expected_combined_hash
                    THEN 'PASS' ELSE 'FAIL'
                END
            WHEN 'LATEST_ARCHIVE_REPRODUCTION' THEN
                CASE
                    WHEN rn.reproduction_rows = cdn.expected_component_rows
                     AND rn.reproduction_pass_rows = cdn.expected_component_rows
                    THEN 'PASS' ELSE 'FAIL'
                END
            WHEN 'STAGE_BOUNDARY' THEN coalesce(sbo.certification_status, 'FAIL')
            ELSE 'FAIL'
        END::text AS certification_status,
        ed.evidence_family_code::text AS evidence_family_code,
        ed.matrix_sequence::smallint AS matrix_sequence,
        CASE
            WHEN
                CASE ed.evidence_family_code
                    WHEN 'ACCEPTANCE_LIFECYCLE' THEN
                        cn.component_rows = cdn.expected_component_rows
                        AND cn.accepted_contract_rows = cdn.expected_component_rows
                        AND cn.gate_pass_rows = cdn.expected_component_rows
                        AND cn.acceptance_pass_rows = cdn.expected_component_rows
                    WHEN 'POSITIVE_VALIDATION' THEN coalesce(pos.aggregate_status, 'FAIL') = 'PASS'
                    WHEN 'NEGATIVE_CONTROLS' THEN coalesce(neg.aggregate_status, 'FAIL') = 'PASS'
                    WHEN 'CANONICAL_IDENTITY' THEN
                        cn.component_rows = cdn.expected_component_rows
                        AND cn.min_canonical_entities = nd.expected_canonical_entities
                        AND cn.max_canonical_entities = nd.expected_canonical_entities
                        AND cn.min_combined_hash = nd.expected_combined_hash
                        AND cn.max_combined_hash = nd.expected_combined_hash
                    WHEN 'LATEST_ARCHIVE_REPRODUCTION' THEN
                        rn.reproduction_rows = cdn.expected_component_rows
                        AND rn.reproduction_pass_rows = cdn.expected_component_rows
                    WHEN 'STAGE_BOUNDARY' THEN coalesce(sbo.certification_status, 'FAIL') = 'PASS'
                    ELSE false
                END
            THEN 0 ELSE 1
        END::integer AS mismatch_count,
        ed.module1_run_id::bigint AS module1_run_id,
        ed.node_sequence::smallint AS node_sequence,
        CASE ed.evidence_family_code
            WHEN 'ACCEPTANCE_LIFECYCLE' THEN
                format(
                    '%s/%s components accepted; %s gate PASS; %s acceptance evidence PASS',
                    coalesce(cn.accepted_contract_rows, 0),
                    cdn.expected_component_rows,
                    coalesce(cn.gate_pass_rows, 0),
                    coalesce(cn.acceptance_pass_rows, 0)
                )
            WHEN 'POSITIVE_VALIDATION' THEN
                format('%s/%s positive controls PASS', coalesce(pos.observed_pass_count, 0), coalesce(pos.expected_pass_count, 0))
            WHEN 'NEGATIVE_CONTROLS' THEN
                format('%s/%s negative controls PASS', coalesce(neg.observed_pass_count, 0), coalesce(neg.expected_pass_count, 0))
            WHEN 'CANONICAL_IDENTITY' THEN
                format('%s entities|%s', coalesce(cn.max_canonical_entities, 0), coalesce(cn.max_combined_hash, '<NULL>'))
            WHEN 'LATEST_ARCHIVE_REPRODUCTION' THEN
                format('%s/%s component reproductions PASS', coalesce(rn.reproduction_pass_rows, 0), cdn.expected_component_rows)
            WHEN 'STAGE_BOUNDARY' THEN coalesce(sbo.observed_count_or_identity, 'MISSING')
            ELSE 'UNSUPPORTED_EVIDENCE_FAMILY'
        END::text AS observed_count_or_identity,
        CASE ed.evidence_family_code
            WHEN 'ACCEPTANCE_LIFECYCLE' THEN cn.component_fingerprint
            WHEN 'POSITIVE_VALIDATION' THEN pos.source_evidence_fingerprint
            WHEN 'NEGATIVE_CONTROLS' THEN neg.source_evidence_fingerprint
            WHEN 'CANONICAL_IDENTITY' THEN md5(concat_ws('|', cn.min_canonical_entities::text, cn.max_canonical_entities::text, cn.min_combined_hash, cn.max_combined_hash))
            WHEN 'LATEST_ARCHIVE_REPRODUCTION' THEN rn.reproduction_fingerprint
            WHEN 'STAGE_BOUNDARY' THEN sbo.observed_hash
            ELSE NULL
        END::text AS observed_hash,
        CASE ed.evidence_family_code
            WHEN 'ACCEPTANCE_LIFECYCLE' THEN
                CASE
                    WHEN cn.component_rows = cdn.expected_component_rows
                     AND cn.accepted_contract_rows = cdn.expected_component_rows
                     AND cn.gate_pass_rows = cdn.expected_component_rows
                     AND cn.acceptance_pass_rows = cdn.expected_component_rows
                    THEN 'PASS' ELSE 'FAIL'
                END
            WHEN 'POSITIVE_VALIDATION' THEN coalesce(pos.aggregate_status, 'FAIL')
            WHEN 'NEGATIVE_CONTROLS' THEN coalesce(neg.aggregate_status, 'FAIL')
            WHEN 'CANONICAL_IDENTITY' THEN
                CASE
                    WHEN cn.component_rows = cdn.expected_component_rows
                     AND cn.min_canonical_entities = nd.expected_canonical_entities
                     AND cn.max_canonical_entities = nd.expected_canonical_entities
                     AND cn.min_combined_hash = nd.expected_combined_hash
                     AND cn.max_combined_hash = nd.expected_combined_hash
                    THEN 'PASS' ELSE 'FAIL'
                END
            WHEN 'LATEST_ARCHIVE_REPRODUCTION' THEN
                CASE
                    WHEN rn.reproduction_rows = cdn.expected_component_rows
                     AND rn.reproduction_pass_rows = cdn.expected_component_rows
                    THEN 'PASS' ELSE 'FAIL'
                END
            WHEN 'STAGE_BOUNDARY' THEN coalesce(sbo.observed_status, 'FAIL')
            ELSE 'FAIL'
        END::text AS observed_status,
        CASE ed.evidence_family_code
            WHEN 'ACCEPTANCE_LIFECYCLE' THEN cn.component_fingerprint
            WHEN 'POSITIVE_VALIDATION' THEN pos.source_evidence_fingerprint
            WHEN 'NEGATIVE_CONTROLS' THEN neg.source_evidence_fingerprint
            WHEN 'CANONICAL_IDENTITY' THEN md5(concat_ws('|', cn.min_canonical_entities::text, cn.max_canonical_entities::text, cn.min_combined_hash, cn.max_combined_hash))
            WHEN 'LATEST_ARCHIVE_REPRODUCTION' THEN rn.reproduction_fingerprint
            WHEN 'STAGE_BOUNDARY' THEN sbo.source_evidence_row_hash
            ELSE NULL
        END::text AS source_evidence_row_hash,
        CASE
            WHEN cn.min_registry_hash IS NOT DISTINCT FROM cn.max_registry_hash
            THEN cn.min_registry_hash
            ELSE cn.registry_fingerprint
        END::text AS source_registry_row_hash
    FROM tmp_src_m2_12_evidence_design ed
    JOIN tmp_src_m2_12_run_context ctx
      ON ctx.module1_run_id = ed.module1_run_id
    JOIN tmp_src_m2_12_node_design nd
      ON nd.module1_run_id = ed.module1_run_id
     AND nd.certification_node_sequence = ed.node_sequence
    JOIN component_design_node cdn
      ON cdn.module1_run_id = ed.module1_run_id
     AND cdn.certification_node_sequence = ed.node_sequence
    LEFT JOIN component_node cn
      ON cn.module1_run_id = ed.module1_run_id
     AND cn.certification_node_sequence = ed.node_sequence
    LEFT JOIN tmp_cert_m2_12_positive_evidence_aggregate pos
      ON pos.module1_run_id = ed.module1_run_id
     AND pos.certification_node_sequence = ed.node_sequence
     AND pos.matrix_sequence = ed.matrix_sequence
    LEFT JOIN tmp_cert_m2_12_negative_evidence_aggregate neg
      ON neg.module1_run_id = ed.module1_run_id
     AND neg.certification_node_sequence = ed.node_sequence
     AND neg.matrix_sequence = ed.matrix_sequence
    LEFT JOIN reproduction_node rn
      ON rn.module1_run_id = ed.module1_run_id
     AND rn.certification_node_sequence = ed.node_sequence
    LEFT JOIN tmp_cert_m2_12_stage_boundary_observation sbo
      ON sbo.module1_run_id = ed.module1_run_id
     AND sbo.node_sequence = ed.node_sequence
     AND sbo.matrix_sequence = ed.matrix_sequence
    WHERE ed.matrix_sequence BETWEEN 1 AND 72
      AND ed.node_sequence BETWEEN 1 AND 12
      AND ed.applicability_code = 'MANDATORY'
      AND ed.allowed_certification_status = 'PASS'
)
SELECT
    e.certification_status::text AS certification_status,
    e.evidence_family_code::text AS evidence_family_code,
    e.matrix_sequence::smallint AS matrix_sequence,
    e.mismatch_count::integer AS mismatch_count,
    e.module1_run_id::bigint AS module1_run_id,
    e.node_sequence::smallint AS node_sequence,
    e.observed_count_or_identity::text AS observed_count_or_identity,
    e.observed_hash::text AS observed_hash,
    e.observed_status::text AS observed_status,
    e.source_evidence_row_hash::text AS source_evidence_row_hash,
    e.source_registry_row_hash::text AS source_registry_row_hash
FROM evidence_rows e;

/* R10 GOVERNED STATEMENT 0080 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_EVIDENCE_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
DO $m212_hf7_evidence_observation_assert$
BEGIN
    IF NOT (
        (SELECT count(*)=72
             AND count(DISTINCT (module1_run_id,matrix_sequence))=72
             AND count(DISTINCT matrix_sequence)=72
             AND count(DISTINCT (node_sequence,evidence_family_code))=72
             AND count(DISTINCT node_sequence)=12
             AND count(DISTINCT evidence_family_code)=6
             AND min(matrix_sequence)=1
             AND max(matrix_sequence)=72
             AND bool_and(certification_status='PASS')
         FROM tmp_cert_m2_12_evidence_observation)
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 evidence certification mismatch',
            DETAIL=coalesce(
                (SELECT string_agg('matrix='||matrix_sequence::text||'|node='||node_sequence::text||'|family='||evidence_family_code||'|status='||coalesce(certification_status,'<NULL>'), '; ' ORDER BY matrix_sequence)
                 FROM tmp_cert_m2_12_evidence_observation
                 WHERE certification_status IS DISTINCT FROM 'PASS'),
                'rows='||(SELECT count(*) FROM tmp_cert_m2_12_evidence_observation)::text);
    END IF;
END;
$m212_hf7_evidence_observation_assert$;

/* R10 GOVERNED STATEMENT 0081 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_EVIDENCE_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_evidence_observation_d72f57b8 ON tmp_cert_m2_12_evidence_observation (module1_run_id, matrix_sequence);

/* R10 GOVERNED STATEMENT 0082 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_EVIDENCE_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_evidence_observation;

/* R10 GOVERNED STATEMENT 0083 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_NODE_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
CREATE TEMP TABLE tmp_cert_m2_12_node_observation ON COMMIT DROP AS
WITH component_design_node AS
(
    SELECT
        module1_run_id,
        certification_node_sequence,
        count(*)::integer AS expected_component_rows
    FROM tmp_src_m2_12_component_design
    GROUP BY module1_run_id, certification_node_sequence
),
component_node AS
(
    SELECT
        module1_run_id,
        certification_node_sequence,
        count(*)::integer AS component_rows,
        count(*) FILTER (WHERE contract_status = 'ACCEPTED')::integer AS accepted_contract_rows,
        count(*) FILTER (WHERE gate_status = 'PASS')::integer AS gate_pass_rows,
        count(*) FILTER (WHERE acceptance_evidence_status = 'PASS')::integer AS acceptance_pass_rows,
        count(*) FILTER (WHERE certification_status = 'PASS')::integer AS certified_component_rows,
        min(observed_canonical_entities)::bigint AS min_canonical_entities,
        max(observed_canonical_entities)::bigint AS max_canonical_entities,
        min(observed_stage_combined_set_hash)::text AS min_combined_hash,
        max(observed_stage_combined_set_hash)::text AS max_combined_hash,
        min(observed_registry_row_hash)::text AS min_registry_hash,
        max(observed_registry_row_hash)::text AS max_registry_hash,
        md5(
            string_agg(
                coalesce(observed_registry_row_hash, '<NULL>'),
                '|' ORDER BY component_sequence, component_contract_code, contract_version
            )
        )::text AS registry_fingerprint
    FROM tmp_src_m2_12_component_observation
    GROUP BY module1_run_id, certification_node_sequence
),
evidence_node AS
(
    SELECT
        module1_run_id,
        node_sequence,
        count(*)::integer AS evidence_rows,
        count(*) FILTER (WHERE certification_status = 'PASS')::integer AS evidence_pass_rows,
        max(certification_status) FILTER (WHERE evidence_family_code = 'ACCEPTANCE_LIFECYCLE')::text AS acceptance_evidence_status,
        max(certification_status) FILTER (WHERE evidence_family_code = 'CANONICAL_IDENTITY')::text AS canonical_identity_status,
        max(certification_status) FILTER (WHERE evidence_family_code = 'STAGE_BOUNDARY')::text AS stage_boundary_status
    FROM tmp_cert_m2_12_evidence_observation
    GROUP BY module1_run_id, node_sequence
),
edge_node AS
(
    SELECT
        module1_run_id,
        target_node_code,
        count(*)::integer AS edge_rows,
        count(*) FILTER (WHERE edge_status = 'PASS')::integer AS passed_edge_rows
    FROM tmp_cert_m2_12_source_edge_observation
    GROUP BY module1_run_id, target_node_code
),
node_rows AS
(
    SELECT
        coalesce(en.acceptance_evidence_status, 'FAIL')::text AS acceptance_evidence_status,
        coalesce(en.canonical_identity_status, 'FAIL')::text AS canonical_identity_status,
        nd.certification_node_sequence::smallint AS certification_node_sequence,
        CASE
            WHEN cn.component_rows = cdn.expected_component_rows
             AND cn.accepted_contract_rows = cdn.expected_component_rows
             AND cn.gate_pass_rows = cdn.expected_component_rows
             AND cn.acceptance_pass_rows = cdn.expected_component_rows
             AND cn.certified_component_rows = cdn.expected_component_rows
             AND en.evidence_rows = 6
             AND en.evidence_pass_rows = 6
             AND coalesce(edn.passed_edge_rows, 0) = nd.required_source_edge_count
             AND pos.aggregate_status = 'PASS'
             AND pos.observed_pass_count = nd.expected_positive_controls
             AND neg.aggregate_status = 'PASS'
             AND neg.observed_pass_count = nd.expected_negative_controls
             AND en.canonical_identity_status = 'PASS'
             AND en.stage_boundary_status = 'PASS'
            THEN 'PASS'
            ELSE 'FAIL'
        END::text AS certification_status,
        CASE
            WHEN cn.component_rows = cdn.expected_component_rows
             AND cn.accepted_contract_rows = cdn.expected_component_rows
            THEN 'ACCEPTED'
            ELSE 'NOT_ACCEPTED'
        END::text AS contract_status,
        CASE
            WHEN cn.component_rows = cdn.expected_component_rows
             AND cn.gate_pass_rows = cdn.expected_component_rows
            THEN 'PASS'
            ELSE 'FAIL'
        END::text AS gate_status,
        format(
            'node=%s; components=%s/%s; evidence=%s/6; edges=%s/%s; positive=%s/%s; negative=%s/%s; canonical=%s; boundary=%s',
            nd.stage_code,
            coalesce(cn.certified_component_rows, 0),
            cdn.expected_component_rows,
            coalesce(en.evidence_pass_rows, 0),
            coalesce(edn.passed_edge_rows, 0),
            nd.required_source_edge_count,
            coalesce(pos.observed_pass_count, 0),
            nd.expected_positive_controls,
            coalesce(neg.observed_pass_count, 0),
            nd.expected_negative_controls,
            coalesce(en.canonical_identity_status, 'FAIL'),
            coalesce(en.stage_boundary_status, 'FAIL')
        )::text AS interpretation,
        nd.module1_run_id::bigint AS module1_run_id,
        CASE
            WHEN cn.min_canonical_entities = cn.max_canonical_entities
            THEN cn.max_canonical_entities
            ELSE NULL
        END::bigint AS observed_canonical_entities,
        CASE
            WHEN cn.min_combined_hash IS NOT DISTINCT FROM cn.max_combined_hash
            THEN cn.max_combined_hash
            ELSE NULL
        END::text AS observed_combined_hash,
        neg.observed_pass_count::integer AS observed_negative_controls,
        pos.observed_pass_count::integer AS observed_positive_controls,
        coalesce(edn.passed_edge_rows, 0)::smallint AS passed_source_edge_count,
        CASE
            WHEN coalesce(edn.passed_edge_rows, 0) = nd.required_source_edge_count
            THEN 'PASS'
            ELSE 'FAIL'
        END::text AS source_graph_status,
        CASE
            WHEN cn.min_registry_hash IS NOT DISTINCT FROM cn.max_registry_hash
            THEN cn.min_registry_hash
            ELSE cn.registry_fingerprint
        END::text AS source_registry_row_hash,
        coalesce(en.stage_boundary_status, 'FAIL')::text AS stage_boundary_status,
        nd.stage_code::text AS stage_code
    FROM tmp_src_m2_12_node_design nd
    JOIN tmp_src_m2_12_run_context ctx
      ON ctx.module1_run_id = nd.module1_run_id
    JOIN component_design_node cdn
      ON cdn.module1_run_id = nd.module1_run_id
     AND cdn.certification_node_sequence = nd.certification_node_sequence
    LEFT JOIN component_node cn
      ON cn.module1_run_id = nd.module1_run_id
     AND cn.certification_node_sequence = nd.certification_node_sequence
    LEFT JOIN evidence_node en
      ON en.module1_run_id = nd.module1_run_id
     AND en.node_sequence = nd.certification_node_sequence
    LEFT JOIN edge_node edn
      ON edn.module1_run_id = nd.module1_run_id
     AND edn.target_node_code = nd.stage_code
    LEFT JOIN tmp_cert_m2_12_positive_evidence_aggregate pos
      ON pos.module1_run_id = nd.module1_run_id
     AND pos.certification_node_sequence = nd.certification_node_sequence
    LEFT JOIN tmp_cert_m2_12_negative_evidence_aggregate neg
      ON neg.module1_run_id = nd.module1_run_id
     AND neg.certification_node_sequence = nd.certification_node_sequence
    WHERE nd.certification_node_sequence BETWEEN 1 AND 12
)
SELECT
    n.acceptance_evidence_status::text AS acceptance_evidence_status,
    n.canonical_identity_status::text AS canonical_identity_status,
    n.certification_node_sequence::smallint AS certification_node_sequence,
    n.certification_status::text AS certification_status,
    n.contract_status::text AS contract_status,
    n.gate_status::text AS gate_status,
    n.interpretation::text AS interpretation,
    n.module1_run_id::bigint AS module1_run_id,
    n.observed_canonical_entities::bigint AS observed_canonical_entities,
    n.observed_combined_hash::text AS observed_combined_hash,
    n.observed_negative_controls::integer AS observed_negative_controls,
    n.observed_positive_controls::integer AS observed_positive_controls,
    n.passed_source_edge_count::smallint AS passed_source_edge_count,
    n.source_graph_status::text AS source_graph_status,
    n.source_registry_row_hash::text AS source_registry_row_hash,
    n.stage_boundary_status::text AS stage_boundary_status,
    n.stage_code::text AS stage_code
FROM node_rows n;

/* R10 GOVERNED STATEMENT 0084 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_NODE_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
DO $m212_hf7_node_observation_assert$
BEGIN
    IF NOT (
        (SELECT count(*)=12
             AND count(DISTINCT (module1_run_id,certification_node_sequence))=12
             AND count(DISTINCT certification_node_sequence)=12
             AND count(DISTINCT stage_code)=12
             AND min(certification_node_sequence)=1
             AND max(certification_node_sequence)=12
             AND bool_and(certification_status='PASS')
         FROM tmp_cert_m2_12_node_observation)
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 node certification mismatch',
            DETAIL=coalesce(
                (SELECT string_agg('node='||certification_node_sequence::text||':'||stage_code||'|status='||coalesce(certification_status,'<NULL>')||'|interpretation='||coalesce(interpretation,'<NULL>'), '; ' ORDER BY certification_node_sequence)
                 FROM tmp_cert_m2_12_node_observation
                 WHERE certification_status IS DISTINCT FROM 'PASS'),
                'rows='||(SELECT count(*) FROM tmp_cert_m2_12_node_observation)::text);
    END IF;
END;
$m212_hf7_node_observation_assert$;

/* R10 GOVERNED STATEMENT 0085 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_NODE_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_node_observation_f5430489 ON tmp_cert_m2_12_node_observation (module1_run_id, certification_node_sequence);

/* R10 GOVERNED STATEMENT 0086 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_NODE_OBSERVATION
   phase_code: 01_02_CONTEXT_BASE_TYPED
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_node_observation;

/* R10 GOVERNED STATEMENT 0087 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_STAGE_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_cert_m2_12_stage_typed ON COMMIT DROP AS
SELECT
    st.module1_run_id,
    st.certification_node_sequence,
    st.stage_code,
    st.repository_stage,
    st.module_title,
    st.registry_relation,
    st.acceptance_gate_id,
    st.acceptance_gate_review_version,
    st.acceptance_evidence_code,
    st.contract_status,
    st.gate_status,
    st.acceptance_evidence_status,
    st.historical_acceptance_method,
    st.expected_canonical_entities,
    st.observed_canonical_entities,
    st.expected_positive_controls,
    st.observed_positive_controls,
    st.expected_negative_controls,
    st.observed_negative_controls,
    st.expected_combined_hash,
    st.observed_combined_hash,
    st.source_registry_row_hash,
    st.required_source_edge_count,
    st.passed_source_edge_count,
    st.source_graph_status,
    st.canonical_identity_status,
    st.stage_boundary_status,
    st.certification_status,
    st.interpretation,
    md5((to_jsonb(st)-'row_hash'-'created_at')::text)::text AS row_hash,
    clock_timestamp()::timestamptz AS created_at
FROM
(
    SELECT
        (ctx.module1_run_id)::bigint AS module1_run_id,
        (nd.certification_node_sequence)::smallint AS certification_node_sequence,
        (nd.stage_code)::text AS stage_code,
        (nd.repository_stage)::text AS repository_stage,
        (nd.module_title)::text AS module_title,
        (nd.registry_relation)::text AS registry_relation,
        (nd.acceptance_gate_id)::text AS acceptance_gate_id,
        (nd.acceptance_gate_review_version)::integer AS acceptance_gate_review_version,
        (nd.acceptance_evidence_code)::text AS acceptance_evidence_code,
        (no.contract_status)::text AS contract_status,
        (no.gate_status)::text AS gate_status,
        (no.acceptance_evidence_status)::text AS acceptance_evidence_status,
        (nd.historical_acceptance_method)::text AS historical_acceptance_method,
        (nd.expected_canonical_entities)::bigint AS expected_canonical_entities,
        (no.observed_canonical_entities)::bigint AS observed_canonical_entities,
        (nd.expected_positive_controls)::integer AS expected_positive_controls,
        (no.observed_positive_controls)::integer AS observed_positive_controls,
        (nd.expected_negative_controls)::integer AS expected_negative_controls,
        (no.observed_negative_controls)::integer AS observed_negative_controls,
        (nd.expected_combined_hash)::text AS expected_combined_hash,
        (no.observed_combined_hash)::text AS observed_combined_hash,
        (no.source_registry_row_hash)::text AS source_registry_row_hash,
        (nd.required_source_edge_count)::smallint AS required_source_edge_count,
        (no.passed_source_edge_count)::smallint AS passed_source_edge_count,
        (no.source_graph_status)::text AS source_graph_status,
        (no.canonical_identity_status)::text AS canonical_identity_status,
        (no.stage_boundary_status)::text AS stage_boundary_status,
        (no.certification_status)::text AS certification_status,
        (no.interpretation)::text AS interpretation
    FROM tmp_src_m2_12_run_context ctx
    JOIN tmp_src_m2_12_node_design nd
      ON nd.module1_run_id = ctx.module1_run_id
    JOIN tmp_cert_m2_12_node_observation no
      ON no.module1_run_id = nd.module1_run_id
     AND no.certification_node_sequence = nd.certification_node_sequence
     AND no.stage_code = nd.stage_code
) AS st;

/* R10 GOVERNED STATEMENT 0088 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_STAGE_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_cert_m2_12_stage_typed$ BEGIN IF (SELECT count(*) FROM tmp_cert_m2_12_stage_typed) <> 12 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_cert_m2_12_stage_typed', DETAIL='expected=12 observed='||(SELECT count(*) FROM tmp_cert_m2_12_stage_typed)::text; END IF; END; $m212_r7_tmp_cert_m2_12_stage_typed$;

/* R10 GOVERNED STATEMENT 0089 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_STAGE_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_stage_typed_37c0ec4b ON tmp_cert_m2_12_stage_typed (module1_run_id, certification_node_sequence, stage_code);

/* R10 GOVERNED STATEMENT 0090 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_STAGE_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_stage_typed;

/* R10 GOVERNED STATEMENT 0091 OF 0206
   statement_code: INSERT_MSBF_M2_MODULE2_STAGE_CERTIFICATION_SNAPSHOT
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: PERSISTENT_INSERT
   source_authority: M2_12_PERSISTENT_INSERT_STATEMENT_COMPILER.csv
*/
INSERT INTO msbf_m2.module2_stage_certification_snapshot (
    "module1_run_id",
    "certification_node_sequence",
    "stage_code",
    "repository_stage",
    "module_title",
    "registry_relation",
    "acceptance_gate_id",
    "acceptance_gate_review_version",
    "acceptance_evidence_code",
    "contract_status",
    "gate_status",
    "acceptance_evidence_status",
    "historical_acceptance_method",
    "expected_canonical_entities",
    "observed_canonical_entities",
    "expected_positive_controls",
    "observed_positive_controls",
    "expected_negative_controls",
    "observed_negative_controls",
    "expected_combined_hash",
    "observed_combined_hash",
    "source_registry_row_hash",
    "required_source_edge_count",
    "passed_source_edge_count",
    "source_graph_status",
    "canonical_identity_status",
    "stage_boundary_status",
    "certification_status",
    "interpretation",
    "row_hash",
    "created_at"
)
SELECT
    src.module1_run_id::bigint,
    src.certification_node_sequence::smallint,
    src.stage_code::text,
    src.repository_stage::text,
    src.module_title::text,
    src.registry_relation::text,
    src.acceptance_gate_id::text,
    src.acceptance_gate_review_version::integer,
    src.acceptance_evidence_code::text,
    src.contract_status::text,
    src.gate_status::text,
    src.acceptance_evidence_status::text,
    src.historical_acceptance_method::text,
    src.expected_canonical_entities::bigint,
    src.observed_canonical_entities::bigint,
    src.expected_positive_controls::integer,
    src.observed_positive_controls::integer,
    src.expected_negative_controls::integer,
    src.observed_negative_controls::integer,
    src.expected_combined_hash::text,
    src.observed_combined_hash::text,
    src.source_registry_row_hash::text,
    src.required_source_edge_count::smallint,
    src.passed_source_edge_count::smallint,
    src.source_graph_status::text,
    src.canonical_identity_status::text,
    src.stage_boundary_status::text,
    src.certification_status::text,
    src.interpretation::text,
    src.row_hash::text,
    src.created_at::timestamptz
FROM tmp_cert_m2_12_stage_typed src;

/* R10 GOVERNED STATEMENT 0092 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_COMPONENT_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_cert_m2_12_component_typed ON COMMIT DROP AS
SELECT
    cc.module1_run_id,
    cc.certification_node_sequence,
    cc.stage_code,
    cc.repository_stage,
    cc.module_title,
    cc.component_sequence,
    cc.component_contract_code,
    cc.contract_version,
    cc.schema_version,
    cc.methodology_version,
    cc.acceptance_gate_id,
    cc.registry_relation,
    cc.latest_relation,
    cc.archive_relation,
    cc.latest_business_grain,
    cc.latest_business_key_columns,
    cc.archive_business_key_columns,
    cc.expected_latest_rows,
    cc.observed_latest_rows,
    cc.expected_archive_rows,
    cc.observed_archive_rows,
    cc.stage_expected_canonical_entities,
    cc.expected_positive_controls,
    cc.observed_positive_controls,
    cc.expected_negative_controls,
    cc.observed_negative_controls,
    cc.expected_contract_set_hash,
    cc.observed_contract_set_hash,
    cc.expected_stage_combined_set_hash,
    cc.observed_stage_combined_set_hash,
    cc.expected_registry_row_hash,
    cc.observed_registry_row_hash,
    cc.expected_latest_set_hash,
    cc.observed_latest_set_hash,
    cc.expected_archive_set_hash,
    cc.observed_archive_set_hash,
    cc.contract_status,
    cc.gate_status,
    cc.acceptance_evidence_code,
    cc.acceptance_evidence_status,
    cc.required_source_edge_codes,
    cc.required_source_edge_count,
    cc.passed_source_edge_count,
    cc.certification_status,
    md5((to_jsonb(cc)-'row_hash'-'created_at')::text)::text AS row_hash,
    clock_timestamp()::timestamptz AS created_at
FROM
(
    SELECT
        (ctx.module1_run_id)::bigint AS module1_run_id,
        (cd.certification_node_sequence)::smallint AS certification_node_sequence,
        (cd.stage_code)::text AS stage_code,
        (cd.repository_stage)::text AS repository_stage,
        (cd.module_title)::text AS module_title,
        (cd.component_sequence)::smallint AS component_sequence,
        (cd.component_contract_code)::text AS component_contract_code,
        (cd.contract_version)::integer AS contract_version,
        (cd.schema_version)::text AS schema_version,
        (cd.methodology_version)::text AS methodology_version,
        (cd.acceptance_gate_id)::text AS acceptance_gate_id,
        (cd.registry_relation)::text AS registry_relation,
        (cd.latest_relation)::text AS latest_relation,
        (cd.archive_relation)::text AS archive_relation,
        (cd.latest_business_grain)::text AS latest_business_grain,
        (cd.latest_business_key_columns)::jsonb AS latest_business_key_columns,
        (cd.archive_business_key_columns)::jsonb AS archive_business_key_columns,
        (cd.expected_latest_rows)::bigint AS expected_latest_rows,
        (co.observed_latest_rows)::bigint AS observed_latest_rows,
        (cd.expected_archive_rows)::bigint AS expected_archive_rows,
        (co.observed_archive_rows)::bigint AS observed_archive_rows,
        (cd.stage_expected_canonical_entities)::bigint AS stage_expected_canonical_entities,
        (cd.expected_positive_controls)::integer AS expected_positive_controls,
        (co.observed_positive_controls)::integer AS observed_positive_controls,
        (cd.expected_negative_controls)::integer AS expected_negative_controls,
        (co.observed_negative_controls)::integer AS observed_negative_controls,
        (cd.expected_contract_set_hash)::text AS expected_contract_set_hash,
        (co.observed_contract_set_hash)::text AS observed_contract_set_hash,
        (cd.expected_stage_combined_set_hash)::text AS expected_stage_combined_set_hash,
        (co.observed_stage_combined_set_hash)::text AS observed_stage_combined_set_hash,
        (cd.expected_registry_row_hash)::text AS expected_registry_row_hash,
        (co.observed_registry_row_hash)::text AS observed_registry_row_hash,
        (cd.expected_latest_set_hash)::text AS expected_latest_set_hash,
        (co.observed_latest_set_hash)::text AS observed_latest_set_hash,
        (cd.expected_archive_set_hash)::text AS expected_archive_set_hash,
        (co.observed_archive_set_hash)::text AS observed_archive_set_hash,
        (co.contract_status)::text AS contract_status,
        (co.gate_status)::text AS gate_status,
        (cd.acceptance_evidence_code)::text AS acceptance_evidence_code,
        (co.acceptance_evidence_status)::text AS acceptance_evidence_status,
        string_to_array(cd.required_source_edge_codes, '|')::text[] AS required_source_edge_codes,
        (cd.required_source_edge_count)::smallint AS required_source_edge_count,
        (co.passed_source_edge_count)::smallint AS passed_source_edge_count,
        (co.certification_status)::text AS certification_status
    FROM tmp_src_m2_12_run_context ctx
    JOIN tmp_src_m2_12_component_design cd
      ON cd.module1_run_id = ctx.module1_run_id
    JOIN tmp_src_m2_12_component_observation co
      ON co.module1_run_id = cd.module1_run_id
     AND co.certification_node_sequence = cd.certification_node_sequence
     AND co.component_sequence = cd.component_sequence
     AND co.component_contract_code = cd.component_contract_code
     AND co.contract_version = cd.contract_version
) AS cc;

/* R10 GOVERNED STATEMENT 0093 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_COMPONENT_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_cert_m2_12_component_typed$ BEGIN IF (SELECT count(*) FROM tmp_cert_m2_12_component_typed) <> 13 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_cert_m2_12_component_typed', DETAIL='expected=13 observed='||(SELECT count(*) FROM tmp_cert_m2_12_component_typed)::text; END IF; END; $m212_r7_tmp_cert_m2_12_component_typed$;

/* R10 GOVERNED STATEMENT 0094 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_COMPONENT_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_component_typed_5c783155 ON tmp_cert_m2_12_component_typed (module1_run_id, component_sequence, component_contract_code, contract_version);

/* R10 GOVERNED STATEMENT 0095 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_COMPONENT_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_component_typed;

/* R10 GOVERNED STATEMENT 0096 OF 0206
   statement_code: INSERT_MSBF_M2_MODULE2_CONTRACT_COMPONENT_SNAPSHOT
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: PERSISTENT_INSERT
   source_authority: M2_12_PERSISTENT_INSERT_STATEMENT_COMPILER.csv
*/
INSERT INTO msbf_m2.module2_contract_component_snapshot (
    "module1_run_id",
    "certification_node_sequence",
    "stage_code",
    "repository_stage",
    "module_title",
    "component_sequence",
    "component_contract_code",
    "contract_version",
    "schema_version",
    "methodology_version",
    "acceptance_gate_id",
    "registry_relation",
    "latest_relation",
    "archive_relation",
    "latest_business_grain",
    "latest_business_key_columns",
    "archive_business_key_columns",
    "expected_latest_rows",
    "observed_latest_rows",
    "expected_archive_rows",
    "observed_archive_rows",
    "stage_expected_canonical_entities",
    "expected_positive_controls",
    "observed_positive_controls",
    "expected_negative_controls",
    "observed_negative_controls",
    "expected_contract_set_hash",
    "observed_contract_set_hash",
    "expected_stage_combined_set_hash",
    "observed_stage_combined_set_hash",
    "expected_registry_row_hash",
    "observed_registry_row_hash",
    "expected_latest_set_hash",
    "observed_latest_set_hash",
    "expected_archive_set_hash",
    "observed_archive_set_hash",
    "contract_status",
    "gate_status",
    "acceptance_evidence_code",
    "acceptance_evidence_status",
    "required_source_edge_codes",
    "required_source_edge_count",
    "passed_source_edge_count",
    "certification_status",
    "row_hash",
    "created_at"
)
SELECT
    src.module1_run_id::bigint,
    src.certification_node_sequence::smallint,
    src.stage_code::text,
    src.repository_stage::text,
    src.module_title::text,
    src.component_sequence::smallint,
    src.component_contract_code::text,
    src.contract_version::integer,
    src.schema_version::text,
    src.methodology_version::text,
    src.acceptance_gate_id::text,
    src.registry_relation::text,
    src.latest_relation::text,
    src.archive_relation::text,
    src.latest_business_grain::text,
    src.latest_business_key_columns::jsonb,
    src.archive_business_key_columns::jsonb,
    src.expected_latest_rows::bigint,
    src.observed_latest_rows::bigint,
    src.expected_archive_rows::bigint,
    src.observed_archive_rows::bigint,
    src.stage_expected_canonical_entities::bigint,
    src.expected_positive_controls::integer,
    src.observed_positive_controls::integer,
    src.expected_negative_controls::integer,
    src.observed_negative_controls::integer,
    src.expected_contract_set_hash::text,
    src.observed_contract_set_hash::text,
    src.expected_stage_combined_set_hash::text,
    src.observed_stage_combined_set_hash::text,
    src.expected_registry_row_hash::text,
    src.observed_registry_row_hash::text,
    src.expected_latest_set_hash::text,
    src.observed_latest_set_hash::text,
    src.expected_archive_set_hash::text,
    src.observed_archive_set_hash::text,
    src.contract_status::text,
    src.gate_status::text,
    src.acceptance_evidence_code::text,
    src.acceptance_evidence_status::text,
    src.required_source_edge_codes::text[],
    src.required_source_edge_count::smallint,
    src.passed_source_edge_count::smallint,
    src.certification_status::text,
    src.row_hash::text,
    src.created_at::timestamptz
FROM tmp_cert_m2_12_component_typed src;

/* R10 GOVERNED STATEMENT 0097 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_EVIDENCE_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_cert_m2_12_evidence_typed ON COMMIT DROP AS
SELECT
    ec.module1_run_id,
    ec.node_sequence,
    ec.stage_code,
    ec.evidence_family_sequence,
    ec.evidence_family_code,
    ec.applicability_code,
    ec.allowed_certification_status,
    ec.authoritative_source_locator,
    ec.evidence_code_or_method_pattern,
    ec.expected_count_or_identity,
    ec.observed_count_or_identity,
    ec.expected_status,
    ec.observed_status,
    ec.expected_hash,
    ec.observed_hash,
    ec.mismatch_count,
    ec.source_registry_row_hash,
    ec.source_evidence_row_hash,
    ec.certification_status,
    ec.interpretation,
    md5((to_jsonb(ec)-'row_hash'-'created_at')::text)::text AS row_hash,
    clock_timestamp()::timestamptz AS created_at
FROM
(
    SELECT
        (ctx.module1_run_id)::bigint AS module1_run_id,
        (ed.node_sequence)::smallint AS node_sequence,
        (ed.stage_code)::text AS stage_code,
        (ed.evidence_family_sequence)::smallint AS evidence_family_sequence,
        (ed.evidence_family_code)::text AS evidence_family_code,
        (ed.applicability_code)::text AS applicability_code,
        (ed.allowed_certification_status)::text AS allowed_certification_status,
        (ed.authoritative_source_locator)::text AS authoritative_source_locator,
        (ed.evidence_code_or_method_pattern)::text AS evidence_code_or_method_pattern,
        (ed.expected_count_or_identity)::text AS expected_count_or_identity,
        (eo.observed_count_or_identity)::text AS observed_count_or_identity,
        (ed.expected_status)::text AS expected_status,
        (eo.observed_status)::text AS observed_status,
        (ed.expected_hash)::text AS expected_hash,
        (eo.observed_hash)::text AS observed_hash,
        (eo.mismatch_count)::bigint AS mismatch_count,
        (eo.source_registry_row_hash)::text AS source_registry_row_hash,
        (eo.source_evidence_row_hash)::text AS source_evidence_row_hash,
        (eo.certification_status)::text AS certification_status,
        (ed.rationale || ' | observed=' || eo.observed_count_or_identity)::text AS interpretation
    FROM tmp_src_m2_12_run_context ctx
    JOIN tmp_src_m2_12_evidence_design ed
      ON ed.module1_run_id = ctx.module1_run_id
    JOIN tmp_cert_m2_12_evidence_observation eo
      ON eo.module1_run_id = ed.module1_run_id
     AND eo.matrix_sequence = ed.matrix_sequence
     AND eo.node_sequence = ed.node_sequence
     AND eo.evidence_family_code = ed.evidence_family_code
) AS ec;

/* R10 GOVERNED STATEMENT 0098 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_EVIDENCE_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_cert_m2_12_evidence_typed$ BEGIN IF (SELECT count(*) FROM tmp_cert_m2_12_evidence_typed) <> 72 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_cert_m2_12_evidence_typed', DETAIL='expected=72 observed='||(SELECT count(*) FROM tmp_cert_m2_12_evidence_typed)::text; END IF; END; $m212_r7_tmp_cert_m2_12_evidence_typed$;

/* R10 GOVERNED STATEMENT 0099 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_EVIDENCE_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_evidence_typed_2a8a38e5 ON tmp_cert_m2_12_evidence_typed (module1_run_id, node_sequence, evidence_family_sequence);

/* R10 GOVERNED STATEMENT 0100 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_EVIDENCE_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_evidence_typed;

/* R10 GOVERNED STATEMENT 0101 OF 0206
   statement_code: INSERT_MSBF_M2_MODULE2_EVIDENCE_CERTIFICATION_SNAPSHOT
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: PERSISTENT_INSERT
   source_authority: M2_12_PERSISTENT_INSERT_STATEMENT_COMPILER.csv
*/
INSERT INTO msbf_m2.module2_evidence_certification_snapshot (
    "module1_run_id",
    "node_sequence",
    "stage_code",
    "evidence_family_sequence",
    "evidence_family_code",
    "applicability_code",
    "allowed_certification_status",
    "authoritative_source_locator",
    "evidence_code_or_method_pattern",
    "expected_count_or_identity",
    "observed_count_or_identity",
    "expected_status",
    "observed_status",
    "expected_hash",
    "observed_hash",
    "mismatch_count",
    "source_registry_row_hash",
    "source_evidence_row_hash",
    "certification_status",
    "interpretation",
    "row_hash",
    "created_at"
)
SELECT
    src.module1_run_id::bigint,
    src.node_sequence::smallint,
    src.stage_code::text,
    src.evidence_family_sequence::smallint,
    src.evidence_family_code::text,
    src.applicability_code::text,
    src.allowed_certification_status::text,
    src.authoritative_source_locator::text,
    src.evidence_code_or_method_pattern::text,
    src.expected_count_or_identity::text,
    src.observed_count_or_identity::text,
    src.expected_status::text,
    src.observed_status::text,
    src.expected_hash::text,
    src.observed_hash::text,
    src.mismatch_count::bigint,
    src.source_registry_row_hash::text,
    src.source_evidence_row_hash::text,
    src.certification_status::text,
    src.interpretation::text,
    src.row_hash::text,
    src.created_at::timestamptz
FROM tmp_cert_m2_12_evidence_typed src;

/* R10 GOVERNED STATEMENT 0102 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_REPRODUCTION_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_cert_m2_12_reproduction_typed ON COMMIT DROP AS
SELECT
    cr.module1_run_id,
    cr.component_sequence,
    cr.stage_code,
    cr.component_contract_code,
    cr.contract_version,
    cr.schema_version,
    cr.methodology_version,
    cr.registry_relation,
    cr.latest_relation,
    cr.archive_relation,
    cr.latest_business_grain,
    cr.latest_business_key_columns,
    cr.archive_business_key_columns,
    cr.expected_latest_rows,
    cr.observed_latest_rows,
    cr.expected_archive_rows,
    cr.observed_archive_rows,
    cr.expected_latest_set_hash,
    cr.observed_latest_set_hash,
    cr.expected_archive_set_hash,
    cr.observed_archive_set_hash,
    cr.payload_mismatch_count,
    cr.missing_latest_rows,
    cr.missing_archive_rows,
    cr.latest_duplicate_key_rows,
    cr.archive_duplicate_key_rows,
    cr.archive_trigger_name,
    cr.archive_trigger_status,
    cr.reproduction_status,
    cr.source_registry_row_hash,
    md5((to_jsonb(cr)-'row_hash'-'created_at')::text)::text AS row_hash,
    clock_timestamp()::timestamptz AS created_at
FROM
(
    SELECT
        (ctx.module1_run_id)::bigint AS module1_run_id,
        (cd.component_sequence)::smallint AS component_sequence,
        (cd.stage_code)::text AS stage_code,
        (cd.component_contract_code)::text AS component_contract_code,
        (cd.contract_version)::integer AS contract_version,
        (cd.schema_version)::text AS schema_version,
        (cd.methodology_version)::text AS methodology_version,
        (cd.registry_relation)::text AS registry_relation,
        (cd.latest_relation)::text AS latest_relation,
        (cd.archive_relation)::text AS archive_relation,
        (cd.latest_business_grain)::text AS latest_business_grain,
        (cd.latest_business_key_columns)::jsonb AS latest_business_key_columns,
        (cd.archive_business_key_columns)::jsonb AS archive_business_key_columns,
        (cd.expected_latest_rows)::bigint AS expected_latest_rows,
        (ro.observed_latest_rows)::bigint AS observed_latest_rows,
        (cd.expected_archive_rows)::bigint AS expected_archive_rows,
        (ro.observed_archive_rows)::bigint AS observed_archive_rows,
        (cd.expected_latest_set_hash)::text AS expected_latest_set_hash,
        (ro.observed_latest_set_hash)::text AS observed_latest_set_hash,
        (cd.expected_archive_set_hash)::text AS expected_archive_set_hash,
        (ro.observed_archive_set_hash)::text AS observed_archive_set_hash,
        (ro.payload_mismatch_count)::bigint AS payload_mismatch_count,
        (ro.missing_latest_rows)::bigint AS missing_latest_rows,
        (ro.missing_archive_rows)::bigint AS missing_archive_rows,
        (ro.latest_duplicate_key_rows)::bigint AS latest_duplicate_key_rows,
        (ro.archive_duplicate_key_rows)::bigint AS archive_duplicate_key_rows,
        (ro.archive_trigger_name)::text AS archive_trigger_name,
        (ro.archive_trigger_status)::text AS archive_trigger_status,
        (ro.reproduction_status)::text AS reproduction_status,
        (ro.source_registry_row_hash)::text AS source_registry_row_hash
    FROM tmp_src_m2_12_run_context ctx
    JOIN tmp_src_m2_12_component_design cd
      ON cd.module1_run_id = ctx.module1_run_id
    JOIN tmp_cert_m2_12_reproduction_observation ro
      ON ro.module1_run_id = cd.module1_run_id
     AND ro.certification_node_sequence = cd.certification_node_sequence
     AND ro.component_sequence = cd.component_sequence
     AND ro.component_contract_code = cd.component_contract_code
     AND ro.contract_version = cd.contract_version
) AS cr;

/* R10 GOVERNED STATEMENT 0103 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_REPRODUCTION_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_cert_m2_12_reproduction_typed$ BEGIN IF (SELECT count(*) FROM tmp_cert_m2_12_reproduction_typed) <> 13 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_cert_m2_12_reproduction_typed', DETAIL='expected=13 observed='||(SELECT count(*) FROM tmp_cert_m2_12_reproduction_typed)::text; END IF; END; $m212_r7_tmp_cert_m2_12_reproduction_typed$;

/* R10 GOVERNED STATEMENT 0104 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_REPRODUCTION_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_reproduction_typed_feadc8ed ON tmp_cert_m2_12_reproduction_typed (module1_run_id, component_sequence, component_contract_code, contract_version);

/* R10 GOVERNED STATEMENT 0105 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_REPRODUCTION_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_reproduction_typed;

/* R10 GOVERNED STATEMENT 0106 OF 0206
   statement_code: INSERT_MSBF_M2_MODULE2_CONTRACT_REPRODUCTION_SNAPSHOT
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: PERSISTENT_INSERT
   source_authority: M2_12_PERSISTENT_INSERT_STATEMENT_COMPILER.csv
*/
INSERT INTO msbf_m2.module2_contract_reproduction_snapshot (
    "module1_run_id",
    "component_sequence",
    "stage_code",
    "component_contract_code",
    "contract_version",
    "schema_version",
    "methodology_version",
    "registry_relation",
    "latest_relation",
    "archive_relation",
    "latest_business_grain",
    "latest_business_key_columns",
    "archive_business_key_columns",
    "expected_latest_rows",
    "observed_latest_rows",
    "expected_archive_rows",
    "observed_archive_rows",
    "expected_latest_set_hash",
    "observed_latest_set_hash",
    "expected_archive_set_hash",
    "observed_archive_set_hash",
    "payload_mismatch_count",
    "missing_latest_rows",
    "missing_archive_rows",
    "latest_duplicate_key_rows",
    "archive_duplicate_key_rows",
    "archive_trigger_name",
    "archive_trigger_status",
    "reproduction_status",
    "source_registry_row_hash",
    "row_hash",
    "created_at"
)
SELECT
    src.module1_run_id::bigint,
    src.component_sequence::smallint,
    src.stage_code::text,
    src.component_contract_code::text,
    src.contract_version::integer,
    src.schema_version::text,
    src.methodology_version::text,
    src.registry_relation::text,
    src.latest_relation::text,
    src.archive_relation::text,
    src.latest_business_grain::text,
    src.latest_business_key_columns::jsonb,
    src.archive_business_key_columns::jsonb,
    src.expected_latest_rows::bigint,
    src.observed_latest_rows::bigint,
    src.expected_archive_rows::bigint,
    src.observed_archive_rows::bigint,
    src.expected_latest_set_hash::text,
    src.observed_latest_set_hash::text,
    src.expected_archive_set_hash::text,
    src.observed_archive_set_hash::text,
    src.payload_mismatch_count::bigint,
    src.missing_latest_rows::bigint,
    src.missing_archive_rows::bigint,
    src.latest_duplicate_key_rows::bigint,
    src.archive_duplicate_key_rows::bigint,
    src.archive_trigger_name::text,
    src.archive_trigger_status::text,
    src.reproduction_status::text,
    src.source_registry_row_hash::text,
    src.row_hash::text,
    src.created_at::timestamptz
FROM tmp_cert_m2_12_reproduction_typed src;

/* R10 GOVERNED STATEMENT 0107 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_CAPABILITY_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_cert_m2_12_capability_typed ON COMMIT DROP AS
SELECT
    cp.module1_run_id,
    cp.capability_sequence,
    cp.capability_code,
    cp.coverage_status_code,
    cp.certifying_stage_code,
    cp.claim_boundary,
    cp.production_action_authorized_flag,
    cp.legal_or_regulatory_certified_flag,
    cp.notes,
    md5((to_jsonb(cp)-'row_hash'-'created_at')::text)::text AS row_hash,
    clock_timestamp()::timestamptz AS created_at
FROM
(
    SELECT
        (ctx.module1_run_id)::bigint AS module1_run_id,
        (cap.capability_sequence)::smallint AS capability_sequence,
        (cap.capability_code)::text AS capability_code,
        (cap.coverage_status_code)::text AS coverage_status_code,
        (cap.certifying_stage_code)::text AS certifying_stage_code,
        (cap.claim_boundary)::text AS claim_boundary,
        (cap.production_action_authorized_flag)::boolean AS production_action_authorized_flag,
        (cap.legal_or_regulatory_certified_flag)::boolean AS legal_or_regulatory_certified_flag,
        (cap.notes)::text AS notes
    FROM tmp_src_m2_12_run_context ctx
    JOIN tmp_src_m2_12_capability_design cap
      ON cap.module1_run_id = ctx.module1_run_id
) AS cp;

/* R10 GOVERNED STATEMENT 0108 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_CAPABILITY_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_cert_m2_12_capability_typed$ BEGIN IF (SELECT count(*) FROM tmp_cert_m2_12_capability_typed) <> 20 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_cert_m2_12_capability_typed', DETAIL='expected=20 observed='||(SELECT count(*) FROM tmp_cert_m2_12_capability_typed)::text; END IF; END; $m212_r7_tmp_cert_m2_12_capability_typed$;

/* R10 GOVERNED STATEMENT 0109 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_CAPABILITY_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_capability_typed_ee55871e ON tmp_cert_m2_12_capability_typed (module1_run_id, capability_sequence, capability_code);

/* R10 GOVERNED STATEMENT 0110 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_CAPABILITY_TYPED
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_capability_typed;

/* R10 GOVERNED STATEMENT 0111 OF 0206
   statement_code: INSERT_MSBF_M2_MODULE2_CAPABILITY_COVERAGE_SNAPSHOT
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: PERSISTENT_INSERT
   source_authority: M2_12_PERSISTENT_INSERT_STATEMENT_COMPILER.csv
*/
INSERT INTO msbf_m2.module2_capability_coverage_snapshot (
    "module1_run_id",
    "capability_sequence",
    "capability_code",
    "coverage_status_code",
    "certifying_stage_code",
    "claim_boundary",
    "production_action_authorized_flag",
    "legal_or_regulatory_certified_flag",
    "notes",
    "row_hash",
    "created_at"
)
SELECT
    src.module1_run_id::bigint,
    src.capability_sequence::smallint,
    src.capability_code::text,
    src.coverage_status_code::text,
    src.certifying_stage_code::text,
    src.claim_boundary::text,
    src.production_action_authorized_flag::boolean,
    src.legal_or_regulatory_certified_flag::boolean,
    src.notes::text,
    src.row_hash::text,
    src.created_at::timestamptz
FROM tmp_cert_m2_12_capability_typed src;

/* R10 GOVERNED STATEMENT 0112 OF 0206
   statement_code: CREATE_TMP_CERT_M2_12_BOUNDARY_AGGREGATE
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_cert_m2_12_boundary_aggregate ON COMMIT DROP AS
(SELECT (SELECT count(*)=20 AND bool_and(production_action_authorized_flag=false AND legal_or_regulatory_certified_flag=false) FROM tmp_cert_m2_12_capability_typed)::boolean AS all_capability_boundary_pass_flag,
       (SELECT count(*)=13 AND bool_and(certification_status='PASS') FROM tmp_cert_m2_12_component_typed)::boolean AS all_component_contract_pass_flag,
       (SELECT count(*)=13 AND bool_and(reproduction_status='PASS') FROM tmp_cert_m2_12_reproduction_typed)::boolean AS all_contract_reproduction_pass_flag,
       (SELECT count(*)=72 AND bool_and(certification_status='PASS') FROM tmp_cert_m2_12_evidence_typed)::boolean AS all_evidence_certification_pass_flag,
       (SELECT count(*)=19 AND bool_and(edge_status='PASS') FROM tmp_cert_m2_12_source_edge_observation)::boolean AS all_source_graph_edges_pass_flag,
       (SELECT count(*)=12 AND bool_and(certification_status='PASS') FROM tmp_cert_m2_12_stage_typed)::boolean AS all_stage_certification_pass_flag,
       (SELECT jsonb_agg(to_jsonb(c)-'row_hash'-'created_at' ORDER BY capability_sequence) FROM tmp_cert_m2_12_capability_typed c)::jsonb AS capability_summary,
       (SELECT jsonb_agg(to_jsonb(c)-'row_hash'-'created_at' ORDER BY capability_sequence) FROM tmp_cert_m2_12_capability_typed c WHERE coverage_status_code NOT IN ('IMPLEMENTED_CERTIFIED_SYNTHETIC','IMPLEMENTED_CERTIFIED_ANALYTICS','IMPLEMENTED_CERTIFIED_COMPARATIVE'))::jsonb AS deferred_capability_payload,
       ctx.module1_run_id::bigint AS module1_run_id,
       jsonb_build_object('synthetic_only',true,'no_legal_certification',true,'no_empirical_or_causal_optimization',true,'module3_not_authorized',true,'deployment_not_authorized',true)::jsonb AS residual_limitation_payload
FROM tmp_src_m2_12_run_context ctx);

/* R10 GOVERNED STATEMENT 0113 OF 0206
   statement_code: ASSERT_TMP_CERT_M2_12_BOUNDARY_AGGREGATE
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_hf8_boundary_aggregate_assert$
BEGIN
    IF NOT coalesce(
        (SELECT count(*)=1
             AND bool_and(coalesce(all_capability_boundary_pass_flag,false))
             AND bool_and(coalesce(all_component_contract_pass_flag,false))
             AND bool_and(coalesce(all_contract_reproduction_pass_flag,false))
             AND bool_and(coalesce(all_evidence_certification_pass_flag,false))
             AND bool_and(coalesce(all_source_graph_edges_pass_flag,false))
             AND bool_and(coalesce(all_stage_certification_pass_flag,false))
         FROM tmp_cert_m2_12_boundary_aggregate),false)
    THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 boundary aggregate prerequisite mismatch',
            DETAIL=format('rows=%s|capability=%s|component=%s|reproduction=%s|evidence=%s|source_graph=%s|stage=%s',
                          (SELECT count(*) FROM tmp_cert_m2_12_boundary_aggregate),
                          coalesce((SELECT all_capability_boundary_pass_flag::text FROM tmp_cert_m2_12_boundary_aggregate),'<NULL>'),
                          coalesce((SELECT all_component_contract_pass_flag::text FROM tmp_cert_m2_12_boundary_aggregate),'<NULL>'),
                          coalesce((SELECT all_contract_reproduction_pass_flag::text FROM tmp_cert_m2_12_boundary_aggregate),'<NULL>'),
                          coalesce((SELECT all_evidence_certification_pass_flag::text FROM tmp_cert_m2_12_boundary_aggregate),'<NULL>'),
                          coalesce((SELECT all_source_graph_edges_pass_flag::text FROM tmp_cert_m2_12_boundary_aggregate),'<NULL>'),
                          coalesce((SELECT all_stage_certification_pass_flag::text FROM tmp_cert_m2_12_boundary_aggregate),'<NULL>'));
    END IF;
END;
$m212_hf8_boundary_aggregate_assert$;

/* R10 GOVERNED STATEMENT 0114 OF 0206
   statement_code: INDEX_TMP_CERT_M2_12_BOUNDARY_AGGREGATE
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_cert_m2_12_boundary_aggregate_0e12e578 ON tmp_cert_m2_12_boundary_aggregate (module1_run_id);

/* R10 GOVERNED STATEMENT 0115 OF 0206
   statement_code: ANALYZE_TMP_CERT_M2_12_BOUNDARY_AGGREGATE
   phase_code: 03_BASE_TYPED_AND_INSERTS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_cert_m2_12_boundary_aggregate;

/* R10 GOVERNED STATEMENT 0116 OF 0206
   statement_code: CREATE_TMP_HASH_M2_12_BASE_SIX
   phase_code: 04_BASE_SET_HASHES
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_hash_m2_12_base_six ON COMMIT DROP AS
(SELECT (SELECT md5(string_agg(cap.capability_sequence::text||'|'||cap.capability_code||'|'||cap.row_hash,'|' ORDER BY cap.capability_sequence,cap.capability_code))::text FROM msbf_m2.module2_capability_coverage_snapshot cap WHERE cap.module1_run_id=ctx.module1_run_id) AS capability_coverage_set_hash,
       (SELECT md5(string_agg(c.component_sequence::text||'|'||c.component_contract_code||'|'||c.contract_version::text||'|'||c.row_hash,'|' ORDER BY c.component_sequence,c.component_contract_code,c.contract_version))::text FROM msbf_m2.module2_contract_component_snapshot c WHERE c.module1_run_id=ctx.module1_run_id) AS contract_component_set_hash,
       (SELECT md5(string_agg(r.component_sequence::text||'|'||r.component_contract_code||'|'||r.contract_version::text||'|'||r.row_hash,'|' ORDER BY r.component_sequence,r.component_contract_code,r.contract_version))::text FROM msbf_m2.module2_contract_reproduction_snapshot r WHERE r.module1_run_id=ctx.module1_run_id) AS contract_reproduction_set_hash,
       (SELECT md5(string_agg(e.node_sequence::text||'|'||e.evidence_family_sequence::text||'|'||e.row_hash,'|' ORDER BY e.node_sequence,e.evidence_family_sequence))::text FROM msbf_m2.module2_evidence_certification_snapshot e WHERE e.module1_run_id=ctx.module1_run_id) AS evidence_certification_set_hash,
       ctx.module1_run_id::bigint AS module1_run_id,
       (SELECT md5(string_agg(p.policy_code||'|'||p.policy_version::text||'|'||p.row_hash,'|' ORDER BY p.policy_code,p.policy_version))::text FROM msbf_ctl.m2_12_policy_profile p WHERE p.module1_run_id=ctx.module1_run_id) AS policy_set_hash,
       (SELECT md5(string_agg(s.certification_node_sequence::text||'|'||s.stage_code||'|'||s.row_hash,'|' ORDER BY s.certification_node_sequence,s.stage_code))::text FROM msbf_m2.module2_stage_certification_snapshot s WHERE s.module1_run_id=ctx.module1_run_id) AS stage_certification_set_hash
FROM tmp_src_m2_12_run_context ctx
WHERE ctx.run_status='M2_11_ACCEPTED');

/* R10 GOVERNED STATEMENT 0117 OF 0206
   statement_code: ASSERT_TMP_HASH_M2_12_BASE_SIX
   phase_code: 04_BASE_SET_HASHES
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_hf8_base_six_hash_assert$
BEGIN
    IF NOT coalesce(
        (SELECT count(*)=1
             AND bool_and(policy_set_hash ~ '^[0-9a-f]{32}$')
             AND bool_and(stage_certification_set_hash ~ '^[0-9a-f]{32}$')
             AND bool_and(contract_component_set_hash ~ '^[0-9a-f]{32}$')
             AND bool_and(evidence_certification_set_hash ~ '^[0-9a-f]{32}$')
             AND bool_and(contract_reproduction_set_hash ~ '^[0-9a-f]{32}$')
             AND bool_and(capability_coverage_set_hash ~ '^[0-9a-f]{32}$')
         FROM tmp_hash_m2_12_base_six),false)
    THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 base-family set-hash construction mismatch',
            DETAIL='Every one of the six base-family hashes must be one 32-character lowercase hexadecimal value.';
    END IF;
END;
$m212_hf8_base_six_hash_assert$;

/* R10 GOVERNED STATEMENT 0118 OF 0206
   statement_code: INDEX_TMP_HASH_M2_12_BASE_SIX
   phase_code: 04_BASE_SET_HASHES
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_hash_m2_12_base_six_c67a897c ON tmp_hash_m2_12_base_six (module1_run_id);

/* R10 GOVERNED STATEMENT 0119 OF 0206
   statement_code: ANALYZE_TMP_HASH_M2_12_BASE_SIX
   phase_code: 04_BASE_SET_HASHES
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_hash_m2_12_base_six;

/* R10 GOVERNED STATEMENT 0120 OF 0206
   statement_code: CREATE_TMP_LATEST_M2_12_G3_SEED
   phase_code: 05_LATEST
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_latest_m2_12_g3_seed ON COMMIT DROP AS
(SELECT 'G3_M2_CONTRACT'::text AS acceptance_gate_id,
       (SELECT count(*)=20 AND bool_and(production_action_authorized_flag=false AND legal_or_regulatory_certified_flag=false) FROM tmp_cert_m2_12_capability_typed) AS all_capability_boundary_pass_flag,
       (SELECT count(*)=13 AND bool_and(certification_status='PASS') FROM tmp_cert_m2_12_component_typed) AS all_component_contract_pass_flag,
       (SELECT count(*)=13 AND bool_and(reproduction_status='PASS') FROM tmp_cert_m2_12_reproduction_typed) AS all_contract_reproduction_pass_flag,
       (SELECT count(*)=72 AND bool_and(certification_status='PASS') FROM tmp_cert_m2_12_evidence_typed) AS all_evidence_certification_pass_flag,
       (SELECT count(*)=19 AND bool_and(edge_status='PASS') FROM tmp_cert_m2_12_source_edge_observation)::boolean AS all_source_graph_edges_pass_flag,
       (SELECT count(*)=12 AND bool_and(certification_status='PASS') FROM tmp_cert_m2_12_stage_typed) AS all_stage_certification_pass_flag,
       1500::bigint AS application_consumption_rows,
       'SYNTHETIC_AS_BUILT_MODULE2_G3'::text AS as_built_certification_scope_code,
       ctx.as_of_date AS as_of_date,
       'M2_G3_CONSUMPTION_BUNDLE'::text AS bundle_code,
       134::integer AS canonical_entity_count,
       9::integer AS canonical_family_count,
       20::integer AS capability_coverage_count,
       (SELECT jsonb_agg(to_jsonb(c)-'row_hash'-'created_at' ORDER BY capability_sequence) FROM tmp_cert_m2_12_capability_typed c) AS capability_summary,
       true::boolean AS certification_only_flag,
       7129::bigint AS component_archive_rows_total,
       13::integer AS component_contract_count,
       7129::bigint AS component_latest_rows_total,
       13::integer AS contract_reproduction_count,
       1::integer AS contract_version,
       (SELECT jsonb_agg(to_jsonb(c)-'row_hash'-'created_at' ORDER BY capability_sequence) FROM tmp_cert_m2_12_capability_typed c WHERE coverage_status_code <> 'IMPLEMENTED_CERTIFIED_SYNTHETIC' AND coverage_status_code <> 'IMPLEMENTED_CERTIFIED_ANALYTICS' AND coverage_status_code <> 'IMPLEMENTED_CERTIFIED_COMPARATIVE') AS deferred_capability_payload,
       false::boolean AS deployment_authorized_flag,
       false::boolean AS empirical_or_causal_optimization_authorized_flag,
       72::integer AS evidence_certification_count,
       false::boolean AS external_system_update_authorized_flag,
       false::boolean AS legal_or_regulatory_certified_flag,
       'M2_12_METHOD_V1'::text AS methodology_version,
       ctx.module1_run_id AS module1_run_id,
       false::boolean AS module3_execution_authorized_flag,
       true::boolean AS no_pii_flag,
       59::integer AS operational_account_consumption_rows,
       false::boolean AS production_action_authorized_flag,
       jsonb_build_object('synthetic_only',true,'no_legal_certification',true,'no_empirical_or_causal_optimization',true,'module3_not_authorized',true,'deployment_not_authorized',true) AS residual_limitation_payload,
       ctx.run_code AS run_code,
       ctx.run_version AS run_version,
       'M2_G3_BUNDLE_SCHEMA_V1'::text AS schema_version,
       19::integer AS source_graph_edge_count,
       m117.bundle_code AS source_m1_17_bundle_code,
       m117.bundle_version AS source_m1_17_bundle_version,
       m117.combined_g2_hash AS source_m1_17_combined_hash,
       m117.row_hash AS source_m1_17_registry_row_hash,
       m117.schema_version AS source_m1_17_schema_version,
       m211.combined_set_hash AS source_m2_11_combined_set_hash,
       m211.contract_code AS source_m2_11_contract_code,
       m211.contract_set_hash AS source_m2_11_contract_set_hash,
       m211.contract_version AS source_m2_11_contract_version,
       m211.methodology_version AS source_m2_11_methodology_version,
       m211.row_hash AS source_m2_11_registry_row_hash,
       m211.schema_version AS source_m2_11_schema_version,
       12::integer AS source_node_count,
       70821::bigint AS stage_local_canonical_reference_total,
       24::integer AS strategy_scope_consumption_rows,
       true::boolean AS synthetic_data_only_flag
FROM tmp_src_m2_12_run_context ctx
JOIN msbf_ctl.m1_17_g2_bundle_registry m117
  ON m117.module1_run_id=ctx.module1_run_id
 AND m117.bundle_code='M1_G2_CONSUMPTION_BUNDLE'
 AND m117.bundle_version=1
 AND m117.bundle_status='ACCEPTED'
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry m211
  ON m211.module1_run_id=ctx.module1_run_id
 AND m211.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
 AND m211.contract_version=1
 AND m211.contract_status='ACCEPTED');

/* R10 GOVERNED STATEMENT 0121 OF 0206
   statement_code: ASSERT_TMP_LATEST_M2_12_G3_SEED
   phase_code: 05_LATEST
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_hf7_g3_seed_assert$
BEGIN
    IF NOT (
        (SELECT count(*)=1
             AND bool_and(all_capability_boundary_pass_flag)
             AND bool_and(all_component_contract_pass_flag)
             AND bool_and(all_contract_reproduction_pass_flag)
             AND bool_and(all_evidence_certification_pass_flag)
             AND bool_and(all_source_graph_edges_pass_flag)
             AND bool_and(all_stage_certification_pass_flag)
             AND bool_and(certification_only_flag)
             AND bool_and(synthetic_data_only_flag)
             AND bool_and(no_pii_flag)
             AND bool_and(NOT deployment_authorized_flag)
             AND bool_and(NOT empirical_or_causal_optimization_authorized_flag)
             AND bool_and(NOT external_system_update_authorized_flag)
             AND bool_and(NOT legal_or_regulatory_certified_flag)
             AND bool_and(NOT module3_execution_authorized_flag)
             AND bool_and(NOT production_action_authorized_flag)
         FROM tmp_latest_m2_12_g3_seed)
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 G3 latest seed prerequisite mismatch',
            DETAIL='rows='||(SELECT count(*) FROM tmp_latest_m2_12_g3_seed)::text||
                   '|failed_stage='||coalesce((SELECT (NOT all_stage_certification_pass_flag)::text FROM tmp_latest_m2_12_g3_seed),'<NULL>')||
                   '|failed_component='||coalesce((SELECT (NOT all_component_contract_pass_flag)::text FROM tmp_latest_m2_12_g3_seed),'<NULL>')||
                   '|failed_evidence='||coalesce((SELECT (NOT all_evidence_certification_pass_flag)::text FROM tmp_latest_m2_12_g3_seed),'<NULL>')||
                   '|failed_reproduction='||coalesce((SELECT (NOT all_contract_reproduction_pass_flag)::text FROM tmp_latest_m2_12_g3_seed),'<NULL>')||
                   '|failed_capability='||coalesce((SELECT (NOT all_capability_boundary_pass_flag)::text FROM tmp_latest_m2_12_g3_seed),'<NULL>')||
                   '|failed_source_graph='||coalesce((SELECT (NOT all_source_graph_edges_pass_flag)::text FROM tmp_latest_m2_12_g3_seed),'<NULL>');
    END IF;
END;
$m212_hf7_g3_seed_assert$;

/* R10 GOVERNED STATEMENT 0122 OF 0206
   statement_code: INDEX_TMP_LATEST_M2_12_G3_SEED
   phase_code: 05_LATEST
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_latest_m2_12_g3_seed_12ab8904 ON tmp_latest_m2_12_g3_seed (module1_run_id);

/* R10 GOVERNED STATEMENT 0123 OF 0206
   statement_code: ANALYZE_TMP_LATEST_M2_12_G3_SEED
   phase_code: 05_LATEST
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_latest_m2_12_g3_seed;

/* R10 GOVERNED STATEMENT 0124 OF 0206
   statement_code: CREATE_TMP_LATEST_M2_12_G3_STABLE_TYPED
   phase_code: 05_LATEST
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_latest_m2_12_g3_stable_typed ON COMMIT DROP AS
SELECT ls.module1_run_id::bigint AS module1_run_id,
       ls.bundle_code::text AS bundle_code,
       ls.contract_version::integer AS contract_version,
       ls.schema_version::text AS schema_version,
       ls.methodology_version::text AS methodology_version,
       ls.acceptance_gate_id::text AS acceptance_gate_id,
       ls.run_code::text AS run_code,
       ls.run_version::integer AS run_version,
       ls.as_of_date::date AS as_of_date,
       ls.source_m1_17_bundle_code::text AS source_m1_17_bundle_code,
       ls.source_m1_17_bundle_version::integer AS source_m1_17_bundle_version,
       ls.source_m1_17_schema_version::text AS source_m1_17_schema_version,
       ls.source_m1_17_combined_hash::text AS source_m1_17_combined_hash,
       ls.source_m1_17_registry_row_hash::text AS source_m1_17_registry_row_hash,
       ls.source_m2_11_contract_code::text AS source_m2_11_contract_code,
       ls.source_m2_11_contract_version::integer AS source_m2_11_contract_version,
       ls.source_m2_11_schema_version::text AS source_m2_11_schema_version,
       ls.source_m2_11_methodology_version::text AS source_m2_11_methodology_version,
       ls.source_m2_11_contract_set_hash::text AS source_m2_11_contract_set_hash,
       ls.source_m2_11_combined_set_hash::text AS source_m2_11_combined_set_hash,
       ls.source_m2_11_registry_row_hash::text AS source_m2_11_registry_row_hash,
       ls.source_node_count::integer AS source_node_count,
       ls.component_contract_count::integer AS component_contract_count,
       ls.source_graph_edge_count::integer AS source_graph_edge_count,
       ls.evidence_certification_count::integer AS evidence_certification_count,
       ls.contract_reproduction_count::integer AS contract_reproduction_count,
       ls.capability_coverage_count::integer AS capability_coverage_count,
       ls.canonical_family_count::integer AS canonical_family_count,
       ls.canonical_entity_count::integer AS canonical_entity_count,
       ls.application_consumption_rows::bigint AS application_consumption_rows,
       ls.operational_account_consumption_rows::integer AS operational_account_consumption_rows,
       ls.strategy_scope_consumption_rows::integer AS strategy_scope_consumption_rows,
       ls.component_latest_rows_total::bigint AS component_latest_rows_total,
       ls.component_archive_rows_total::bigint AS component_archive_rows_total,
       ls.stage_local_canonical_reference_total::bigint AS stage_local_canonical_reference_total,
       ls.all_stage_certification_pass_flag::boolean AS all_stage_certification_pass_flag,
       ls.all_component_contract_pass_flag::boolean AS all_component_contract_pass_flag,
       ls.all_evidence_certification_pass_flag::boolean AS all_evidence_certification_pass_flag,
       ls.all_contract_reproduction_pass_flag::boolean AS all_contract_reproduction_pass_flag,
       ls.all_capability_boundary_pass_flag::boolean AS all_capability_boundary_pass_flag,
       ls.all_source_graph_edges_pass_flag::boolean AS all_source_graph_edges_pass_flag,
       ls.as_built_certification_scope_code::text AS as_built_certification_scope_code,
       ls.capability_summary::jsonb AS capability_summary,
       ls.residual_limitation_payload::jsonb AS residual_limitation_payload,
       ls.deferred_capability_payload::jsonb AS deferred_capability_payload,
       ls.synthetic_data_only_flag::boolean AS synthetic_data_only_flag,
       ls.no_pii_flag::boolean AS no_pii_flag,
       ls.certification_only_flag::boolean AS certification_only_flag,
       ls.production_action_authorized_flag::boolean AS production_action_authorized_flag,
       ls.external_system_update_authorized_flag::boolean AS external_system_update_authorized_flag,
       ls.legal_or_regulatory_certified_flag::boolean AS legal_or_regulatory_certified_flag,
       ls.empirical_or_causal_optimization_authorized_flag::boolean AS empirical_or_causal_optimization_authorized_flag,
       ls.deployment_authorized_flag::boolean AS deployment_authorized_flag,
       ls.module3_execution_authorized_flag::boolean AS module3_execution_authorized_flag,
       h.policy_set_hash::text AS policy_set_hash,
       h.stage_certification_set_hash::text AS stage_certification_set_hash,
       h.contract_component_set_hash::text AS contract_component_set_hash,
       h.evidence_certification_set_hash::text AS evidence_certification_set_hash,
       h.contract_reproduction_set_hash::text AS contract_reproduction_set_hash,
       h.capability_coverage_set_hash::text AS capability_coverage_set_hash
FROM tmp_latest_m2_12_g3_seed ls
JOIN tmp_hash_m2_12_base_six h ON h.module1_run_id=ls.module1_run_id;

/* R10 GOVERNED STATEMENT 0125 OF 0206
   statement_code: ASSERT_TMP_LATEST_M2_12_G3_STABLE_TYPED
   phase_code: 05_LATEST
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_latest_m2_12_g3_stable_typed$ BEGIN IF (SELECT count(*) FROM tmp_latest_m2_12_g3_stable_typed) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_latest_m2_12_g3_stable_typed', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_latest_m2_12_g3_stable_typed)::text; END IF; END; $m212_r7_tmp_latest_m2_12_g3_stable_typed$;

/* R10 GOVERNED STATEMENT 0126 OF 0206
   statement_code: INDEX_TMP_LATEST_M2_12_G3_STABLE_TYPED
   phase_code: 05_LATEST
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_latest_m2_12_g3_stable_typed_86035ffa ON tmp_latest_m2_12_g3_stable_typed (module1_run_id, contract_version);

/* R10 GOVERNED STATEMENT 0127 OF 0206
   statement_code: ANALYZE_TMP_LATEST_M2_12_G3_STABLE_TYPED
   phase_code: 05_LATEST
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_latest_m2_12_g3_stable_typed;

/* R10 GOVERNED STATEMENT 0128 OF 0206
   statement_code: CREATE_TMP_LATEST_M2_12_G3_CONTRACT_HASHED
   phase_code: 05_LATEST
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_latest_m2_12_g3_contract_hashed ON COMMIT DROP AS
(SELECT ls.module1_run_id::bigint AS module1_run_id,
       ls.bundle_code::text AS bundle_code,
       ls.contract_version::integer AS contract_version,
       ls.schema_version::text AS schema_version,
       ls.methodology_version::text AS methodology_version,
       ls.acceptance_gate_id::text AS acceptance_gate_id,
       ls.run_code::text AS run_code,
       ls.run_version::integer AS run_version,
       ls.as_of_date::date AS as_of_date,
       ls.source_m1_17_bundle_code::text AS source_m1_17_bundle_code,
       ls.source_m1_17_bundle_version::integer AS source_m1_17_bundle_version,
       ls.source_m1_17_schema_version::text AS source_m1_17_schema_version,
       ls.source_m1_17_combined_hash::text AS source_m1_17_combined_hash,
       ls.source_m1_17_registry_row_hash::text AS source_m1_17_registry_row_hash,
       ls.source_m2_11_contract_code::text AS source_m2_11_contract_code,
       ls.source_m2_11_contract_version::integer AS source_m2_11_contract_version,
       ls.source_m2_11_schema_version::text AS source_m2_11_schema_version,
       ls.source_m2_11_methodology_version::text AS source_m2_11_methodology_version,
       ls.source_m2_11_contract_set_hash::text AS source_m2_11_contract_set_hash,
       ls.source_m2_11_combined_set_hash::text AS source_m2_11_combined_set_hash,
       ls.source_m2_11_registry_row_hash::text AS source_m2_11_registry_row_hash,
       ls.source_node_count::integer AS source_node_count,
       ls.component_contract_count::integer AS component_contract_count,
       ls.source_graph_edge_count::integer AS source_graph_edge_count,
       ls.evidence_certification_count::integer AS evidence_certification_count,
       ls.contract_reproduction_count::integer AS contract_reproduction_count,
       ls.capability_coverage_count::integer AS capability_coverage_count,
       ls.canonical_family_count::integer AS canonical_family_count,
       ls.canonical_entity_count::integer AS canonical_entity_count,
       ls.application_consumption_rows::bigint AS application_consumption_rows,
       ls.operational_account_consumption_rows::integer AS operational_account_consumption_rows,
       ls.strategy_scope_consumption_rows::integer AS strategy_scope_consumption_rows,
       ls.component_latest_rows_total::bigint AS component_latest_rows_total,
       ls.component_archive_rows_total::bigint AS component_archive_rows_total,
       ls.stage_local_canonical_reference_total::bigint AS stage_local_canonical_reference_total,
       ls.all_stage_certification_pass_flag::boolean AS all_stage_certification_pass_flag,
       ls.all_component_contract_pass_flag::boolean AS all_component_contract_pass_flag,
       ls.all_evidence_certification_pass_flag::boolean AS all_evidence_certification_pass_flag,
       ls.all_contract_reproduction_pass_flag::boolean AS all_contract_reproduction_pass_flag,
       ls.all_capability_boundary_pass_flag::boolean AS all_capability_boundary_pass_flag,
       ls.all_source_graph_edges_pass_flag::boolean AS all_source_graph_edges_pass_flag,
       ls.as_built_certification_scope_code::text AS as_built_certification_scope_code,
       ls.capability_summary::jsonb AS capability_summary,
       ls.residual_limitation_payload::jsonb AS residual_limitation_payload,
       ls.deferred_capability_payload::jsonb AS deferred_capability_payload,
       ls.synthetic_data_only_flag::boolean AS synthetic_data_only_flag,
       ls.no_pii_flag::boolean AS no_pii_flag,
       ls.certification_only_flag::boolean AS certification_only_flag,
       ls.production_action_authorized_flag::boolean AS production_action_authorized_flag,
       ls.external_system_update_authorized_flag::boolean AS external_system_update_authorized_flag,
       ls.legal_or_regulatory_certified_flag::boolean AS legal_or_regulatory_certified_flag,
       ls.empirical_or_causal_optimization_authorized_flag::boolean AS empirical_or_causal_optimization_authorized_flag,
       ls.deployment_authorized_flag::boolean AS deployment_authorized_flag,
       ls.module3_execution_authorized_flag::boolean AS module3_execution_authorized_flag,
       ls.policy_set_hash::text AS policy_set_hash,
       ls.stage_certification_set_hash::text AS stage_certification_set_hash,
       ls.contract_component_set_hash::text AS contract_component_set_hash,
       ls.evidence_certification_set_hash::text AS evidence_certification_set_hash,
       ls.contract_reproduction_set_hash::text AS contract_reproduction_set_hash,
       ls.capability_coverage_set_hash::text AS capability_coverage_set_hash,
       md5((to_jsonb(ls)-'row_hash'-'contract_row_hash'-'created_at')::text)::text AS contract_row_hash
FROM tmp_latest_m2_12_g3_stable_typed ls);

/* R10 GOVERNED STATEMENT 0129 OF 0206
   statement_code: ASSERT_TMP_LATEST_M2_12_G3_CONTRACT_HASHED
   phase_code: 05_LATEST
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_latest_m2_12_g3_contract_hashed$ BEGIN IF (SELECT count(*) FROM tmp_latest_m2_12_g3_contract_hashed) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_latest_m2_12_g3_contract_hashed', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_latest_m2_12_g3_contract_hashed)::text; END IF; END; $m212_r7_tmp_latest_m2_12_g3_contract_hashed$;

/* R10 GOVERNED STATEMENT 0130 OF 0206
   statement_code: INDEX_TMP_LATEST_M2_12_G3_CONTRACT_HASHED
   phase_code: 05_LATEST
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_latest_m2_12_g3_contract_hashed_1afc594d ON tmp_latest_m2_12_g3_contract_hashed (module1_run_id, contract_version);

/* R10 GOVERNED STATEMENT 0131 OF 0206
   statement_code: ANALYZE_TMP_LATEST_M2_12_G3_CONTRACT_HASHED
   phase_code: 05_LATEST
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_latest_m2_12_g3_contract_hashed;

/* R10 GOVERNED STATEMENT 0132 OF 0206
   statement_code: CREATE_TMP_LATEST_M2_12_G3_TYPED
   phase_code: 05_LATEST
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_latest_m2_12_g3_typed ON COMMIT DROP AS
(SELECT lch.module1_run_id::bigint AS module1_run_id,
       lch.bundle_code::text AS bundle_code,
       lch.contract_version::integer AS contract_version,
       lch.schema_version::text AS schema_version,
       lch.methodology_version::text AS methodology_version,
       lch.acceptance_gate_id::text AS acceptance_gate_id,
       lch.run_code::text AS run_code,
       lch.run_version::integer AS run_version,
       lch.as_of_date::date AS as_of_date,
       lch.source_m1_17_bundle_code::text AS source_m1_17_bundle_code,
       lch.source_m1_17_bundle_version::integer AS source_m1_17_bundle_version,
       lch.source_m1_17_schema_version::text AS source_m1_17_schema_version,
       lch.source_m1_17_combined_hash::text AS source_m1_17_combined_hash,
       lch.source_m1_17_registry_row_hash::text AS source_m1_17_registry_row_hash,
       lch.source_m2_11_contract_code::text AS source_m2_11_contract_code,
       lch.source_m2_11_contract_version::integer AS source_m2_11_contract_version,
       lch.source_m2_11_schema_version::text AS source_m2_11_schema_version,
       lch.source_m2_11_methodology_version::text AS source_m2_11_methodology_version,
       lch.source_m2_11_contract_set_hash::text AS source_m2_11_contract_set_hash,
       lch.source_m2_11_combined_set_hash::text AS source_m2_11_combined_set_hash,
       lch.source_m2_11_registry_row_hash::text AS source_m2_11_registry_row_hash,
       lch.source_node_count::integer AS source_node_count,
       lch.component_contract_count::integer AS component_contract_count,
       lch.source_graph_edge_count::integer AS source_graph_edge_count,
       lch.evidence_certification_count::integer AS evidence_certification_count,
       lch.contract_reproduction_count::integer AS contract_reproduction_count,
       lch.capability_coverage_count::integer AS capability_coverage_count,
       lch.canonical_family_count::integer AS canonical_family_count,
       lch.canonical_entity_count::integer AS canonical_entity_count,
       lch.application_consumption_rows::bigint AS application_consumption_rows,
       lch.operational_account_consumption_rows::integer AS operational_account_consumption_rows,
       lch.strategy_scope_consumption_rows::integer AS strategy_scope_consumption_rows,
       lch.component_latest_rows_total::bigint AS component_latest_rows_total,
       lch.component_archive_rows_total::bigint AS component_archive_rows_total,
       lch.stage_local_canonical_reference_total::bigint AS stage_local_canonical_reference_total,
       lch.all_stage_certification_pass_flag::boolean AS all_stage_certification_pass_flag,
       lch.all_component_contract_pass_flag::boolean AS all_component_contract_pass_flag,
       lch.all_evidence_certification_pass_flag::boolean AS all_evidence_certification_pass_flag,
       lch.all_contract_reproduction_pass_flag::boolean AS all_contract_reproduction_pass_flag,
       lch.all_capability_boundary_pass_flag::boolean AS all_capability_boundary_pass_flag,
       lch.all_source_graph_edges_pass_flag::boolean AS all_source_graph_edges_pass_flag,
       lch.as_built_certification_scope_code::text AS as_built_certification_scope_code,
       lch.capability_summary::jsonb AS capability_summary,
       lch.residual_limitation_payload::jsonb AS residual_limitation_payload,
       lch.deferred_capability_payload::jsonb AS deferred_capability_payload,
       lch.synthetic_data_only_flag::boolean AS synthetic_data_only_flag,
       lch.no_pii_flag::boolean AS no_pii_flag,
       lch.certification_only_flag::boolean AS certification_only_flag,
       lch.production_action_authorized_flag::boolean AS production_action_authorized_flag,
       lch.external_system_update_authorized_flag::boolean AS external_system_update_authorized_flag,
       lch.legal_or_regulatory_certified_flag::boolean AS legal_or_regulatory_certified_flag,
       lch.empirical_or_causal_optimization_authorized_flag::boolean AS empirical_or_causal_optimization_authorized_flag,
       lch.deployment_authorized_flag::boolean AS deployment_authorized_flag,
       lch.module3_execution_authorized_flag::boolean AS module3_execution_authorized_flag,
       lch.policy_set_hash::text AS policy_set_hash,
       lch.stage_certification_set_hash::text AS stage_certification_set_hash,
       lch.contract_component_set_hash::text AS contract_component_set_hash,
       lch.evidence_certification_set_hash::text AS evidence_certification_set_hash,
       lch.contract_reproduction_set_hash::text AS contract_reproduction_set_hash,
       lch.capability_coverage_set_hash::text AS capability_coverage_set_hash,
       lch.contract_row_hash::text AS contract_row_hash,
       md5((to_jsonb(lch)-'row_hash'-'created_at')::text)::text AS row_hash,
       transaction_timestamp()::timestamptz AS created_at
FROM tmp_latest_m2_12_g3_contract_hashed lch);

/* R10 GOVERNED STATEMENT 0133 OF 0206
   statement_code: ASSERT_TMP_LATEST_M2_12_G3_TYPED
   phase_code: 05_LATEST
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_latest_m2_12_g3_typed$ BEGIN IF (SELECT count(*) FROM tmp_latest_m2_12_g3_typed) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_latest_m2_12_g3_typed', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_latest_m2_12_g3_typed)::text; END IF; END; $m212_r7_tmp_latest_m2_12_g3_typed$;

/* R10 GOVERNED STATEMENT 0134 OF 0206
   statement_code: INDEX_TMP_LATEST_M2_12_G3_TYPED
   phase_code: 05_LATEST
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_latest_m2_12_g3_typed_ea6635d7 ON tmp_latest_m2_12_g3_typed (module1_run_id, contract_version);

/* R10 GOVERNED STATEMENT 0135 OF 0206
   statement_code: ANALYZE_TMP_LATEST_M2_12_G3_TYPED
   phase_code: 05_LATEST
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_latest_m2_12_g3_typed;

/* R10 GOVERNED STATEMENT 0136 OF 0206
   statement_code: INSERT_LATEST
   phase_code: 05_LATEST
   statement_type: PERSISTENT_INSERT
   source_authority: M2_12_PERSISTENT_INSERT_STATEMENT_COMPILER.csv
*/
INSERT INTO msbf_ctl.m2_12_g3_bundle_latest (
    "module1_run_id",
    "bundle_code",
    "contract_version",
    "schema_version",
    "methodology_version",
    "acceptance_gate_id",
    "run_code",
    "run_version",
    "as_of_date",
    "source_m1_17_bundle_code",
    "source_m1_17_bundle_version",
    "source_m1_17_schema_version",
    "source_m1_17_combined_hash",
    "source_m1_17_registry_row_hash",
    "source_m2_11_contract_code",
    "source_m2_11_contract_version",
    "source_m2_11_schema_version",
    "source_m2_11_methodology_version",
    "source_m2_11_contract_set_hash",
    "source_m2_11_combined_set_hash",
    "source_m2_11_registry_row_hash",
    "source_node_count",
    "component_contract_count",
    "source_graph_edge_count",
    "evidence_certification_count",
    "contract_reproduction_count",
    "capability_coverage_count",
    "canonical_family_count",
    "canonical_entity_count",
    "application_consumption_rows",
    "operational_account_consumption_rows",
    "strategy_scope_consumption_rows",
    "component_latest_rows_total",
    "component_archive_rows_total",
    "stage_local_canonical_reference_total",
    "all_stage_certification_pass_flag",
    "all_component_contract_pass_flag",
    "all_evidence_certification_pass_flag",
    "all_contract_reproduction_pass_flag",
    "all_capability_boundary_pass_flag",
    "all_source_graph_edges_pass_flag",
    "as_built_certification_scope_code",
    "capability_summary",
    "residual_limitation_payload",
    "deferred_capability_payload",
    "synthetic_data_only_flag",
    "no_pii_flag",
    "certification_only_flag",
    "production_action_authorized_flag",
    "external_system_update_authorized_flag",
    "legal_or_regulatory_certified_flag",
    "empirical_or_causal_optimization_authorized_flag",
    "deployment_authorized_flag",
    "module3_execution_authorized_flag",
    "policy_set_hash",
    "stage_certification_set_hash",
    "contract_component_set_hash",
    "evidence_certification_set_hash",
    "contract_reproduction_set_hash",
    "capability_coverage_set_hash",
    "contract_row_hash",
    "row_hash",
    "created_at"
)
SELECT
    src.module1_run_id::bigint,
    src.bundle_code::text,
    src.contract_version::integer,
    src.schema_version::text,
    src.methodology_version::text,
    src.acceptance_gate_id::text,
    src.run_code::text,
    src.run_version::integer,
    src.as_of_date::date,
    src.source_m1_17_bundle_code::text,
    src.source_m1_17_bundle_version::integer,
    src.source_m1_17_schema_version::text,
    src.source_m1_17_combined_hash::text,
    src.source_m1_17_registry_row_hash::text,
    src.source_m2_11_contract_code::text,
    src.source_m2_11_contract_version::integer,
    src.source_m2_11_schema_version::text,
    src.source_m2_11_methodology_version::text,
    src.source_m2_11_contract_set_hash::text,
    src.source_m2_11_combined_set_hash::text,
    src.source_m2_11_registry_row_hash::text,
    src.source_node_count::integer,
    src.component_contract_count::integer,
    src.source_graph_edge_count::integer,
    src.evidence_certification_count::integer,
    src.contract_reproduction_count::integer,
    src.capability_coverage_count::integer,
    src.canonical_family_count::integer,
    src.canonical_entity_count::integer,
    src.application_consumption_rows::bigint,
    src.operational_account_consumption_rows::integer,
    src.strategy_scope_consumption_rows::integer,
    src.component_latest_rows_total::bigint,
    src.component_archive_rows_total::bigint,
    src.stage_local_canonical_reference_total::bigint,
    src.all_stage_certification_pass_flag::boolean,
    src.all_component_contract_pass_flag::boolean,
    src.all_evidence_certification_pass_flag::boolean,
    src.all_contract_reproduction_pass_flag::boolean,
    src.all_capability_boundary_pass_flag::boolean,
    src.all_source_graph_edges_pass_flag::boolean,
    src.as_built_certification_scope_code::text,
    src.capability_summary::jsonb,
    src.residual_limitation_payload::jsonb,
    src.deferred_capability_payload::jsonb,
    src.synthetic_data_only_flag::boolean,
    src.no_pii_flag::boolean,
    src.certification_only_flag::boolean,
    src.production_action_authorized_flag::boolean,
    src.external_system_update_authorized_flag::boolean,
    src.legal_or_regulatory_certified_flag::boolean,
    src.empirical_or_causal_optimization_authorized_flag::boolean,
    src.deployment_authorized_flag::boolean,
    src.module3_execution_authorized_flag::boolean,
    src.policy_set_hash::text,
    src.stage_certification_set_hash::text,
    src.contract_component_set_hash::text,
    src.evidence_certification_set_hash::text,
    src.contract_reproduction_set_hash::text,
    src.capability_coverage_set_hash::text,
    src.contract_row_hash::text,
    src.row_hash::text,
    src.created_at::timestamptz
FROM tmp_latest_m2_12_g3_typed src;

/* R10 GOVERNED STATEMENT 0137 OF 0206
   statement_code: CREATE_TMP_SEQUENCE_M2_12_ARCHIVE_BEFORE
   phase_code: 06_ARCHIVE
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_sequence_m2_12_archive_before ON COMMIT DROP AS
SELECT 'msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq'::text AS sequence_name,
       s.last_value::bigint AS last_value,
       s.is_called::boolean AS is_called
FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq s;

/* R10 GOVERNED STATEMENT 0138 OF 0206
   statement_code: ASSERT_TMP_SEQUENCE_M2_12_ARCHIVE_BEFORE
   phase_code: 06_ARCHIVE
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_sequence_m2_12_archive_before$ BEGIN IF (SELECT count(*) FROM tmp_sequence_m2_12_archive_before) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_sequence_m2_12_archive_before', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_sequence_m2_12_archive_before)::text; END IF; END; $m212_r7_tmp_sequence_m2_12_archive_before$;

/* R10 GOVERNED STATEMENT 0139 OF 0206
   statement_code: INDEX_TMP_SEQUENCE_M2_12_ARCHIVE_BEFORE
   phase_code: 06_ARCHIVE
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_sequence_m2_12_archive_before_7bad967a ON tmp_sequence_m2_12_archive_before (sequence_name);

/* R10 GOVERNED STATEMENT 0140 OF 0206
   statement_code: ANALYZE_TMP_SEQUENCE_M2_12_ARCHIVE_BEFORE
   phase_code: 06_ARCHIVE
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_sequence_m2_12_archive_before;

/* R10 GOVERNED STATEMENT 0141 OF 0206
   statement_code: CREATE_TMP_ARCHIVE_M2_12_G3_STABLE_TYPED
   phase_code: 06_ARCHIVE
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_archive_m2_12_g3_stable_typed ON COMMIT DROP AS
(SELECT lt.module1_run_id::bigint AS module1_run_id,
       lt.bundle_code::text AS bundle_code,
       lt.contract_version::integer AS contract_version,
       lt.schema_version::text AS schema_version,
       lt.methodology_version::text AS methodology_version,
       lt.acceptance_gate_id::text AS acceptance_gate_id,
       lt.row_hash::text AS source_latest_row_hash,
       lt.contract_row_hash::text AS contract_row_hash,
       (to_jsonb(lt)-'created_at')::jsonb AS contract_payload
FROM tmp_latest_m2_12_g3_typed lt);

/* R10 GOVERNED STATEMENT 0142 OF 0206
   statement_code: ASSERT_TMP_ARCHIVE_M2_12_G3_STABLE_TYPED
   phase_code: 06_ARCHIVE
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_archive_m2_12_g3_stable_typed$ BEGIN IF (SELECT count(*) FROM tmp_archive_m2_12_g3_stable_typed) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_archive_m2_12_g3_stable_typed', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_archive_m2_12_g3_stable_typed)::text; END IF; END; $m212_r7_tmp_archive_m2_12_g3_stable_typed$;

/* R10 GOVERNED STATEMENT 0143 OF 0206
   statement_code: INDEX_TMP_ARCHIVE_M2_12_G3_STABLE_TYPED
   phase_code: 06_ARCHIVE
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_archive_m2_12_g3_stable_typed_bd148fc1 ON tmp_archive_m2_12_g3_stable_typed (module1_run_id, contract_version);

/* R10 GOVERNED STATEMENT 0144 OF 0206
   statement_code: ANALYZE_TMP_ARCHIVE_M2_12_G3_STABLE_TYPED
   phase_code: 06_ARCHIVE
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_archive_m2_12_g3_stable_typed;

/* R10 GOVERNED STATEMENT 0145 OF 0206
   statement_code: CREATE_TMP_ARCHIVE_M2_12_G3_TYPED
   phase_code: 06_ARCHIVE
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_archive_m2_12_g3_typed ON COMMIT DROP AS
(SELECT ast.module1_run_id::bigint AS module1_run_id,
       ast.bundle_code::text AS bundle_code,
       ast.contract_version::integer AS contract_version,
       ast.schema_version::text AS schema_version,
       ast.methodology_version::text AS methodology_version,
       ast.acceptance_gate_id::text AS acceptance_gate_id,
       ast.source_latest_row_hash::text AS source_latest_row_hash,
       ast.contract_row_hash::text AS contract_row_hash,
       ast.contract_payload::jsonb AS contract_payload,
       md5((to_jsonb(ast)-'archive_id'-'archive_row_hash'-'created_at')::text)::text AS archive_row_hash,
       transaction_timestamp()::timestamptz AS created_at
FROM tmp_archive_m2_12_g3_stable_typed ast);

/* R10 GOVERNED STATEMENT 0146 OF 0206
   statement_code: ASSERT_TMP_ARCHIVE_M2_12_G3_TYPED
   phase_code: 06_ARCHIVE
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_archive_m2_12_g3_typed$ BEGIN IF (SELECT count(*) FROM tmp_archive_m2_12_g3_typed) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_archive_m2_12_g3_typed', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_archive_m2_12_g3_typed)::text; END IF; END; $m212_r7_tmp_archive_m2_12_g3_typed$;

/* R10 GOVERNED STATEMENT 0147 OF 0206
   statement_code: INDEX_TMP_ARCHIVE_M2_12_G3_TYPED
   phase_code: 06_ARCHIVE
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_archive_m2_12_g3_typed_3cd4c613 ON tmp_archive_m2_12_g3_typed (module1_run_id, contract_version);

/* R10 GOVERNED STATEMENT 0148 OF 0206
   statement_code: ANALYZE_TMP_ARCHIVE_M2_12_G3_TYPED
   phase_code: 06_ARCHIVE
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_archive_m2_12_g3_typed;

/* R10 GOVERNED STATEMENT 0149 OF 0206
   statement_code: INSERT_ARCHIVE
   phase_code: 06_ARCHIVE
   statement_type: PERSISTENT_INSERT
   source_authority: M2_12_PERSISTENT_INSERT_STATEMENT_COMPILER.csv
*/
INSERT INTO msbf_ctl.m2_12_g3_bundle_archive (
    "module1_run_id",
    "bundle_code",
    "contract_version",
    "schema_version",
    "methodology_version",
    "acceptance_gate_id",
    "source_latest_row_hash",
    "contract_row_hash",
    "contract_payload",
    "archive_row_hash",
    "created_at"
)
SELECT
    src.module1_run_id::bigint,
    src.bundle_code::text,
    src.contract_version::integer,
    src.schema_version::text,
    src.methodology_version::text,
    src.acceptance_gate_id::text,
    src.source_latest_row_hash::text,
    src.contract_row_hash::text,
    src.contract_payload::jsonb,
    src.archive_row_hash::text,
    src.created_at::timestamptz
FROM tmp_archive_m2_12_g3_typed src;

/* R10 GOVERNED STATEMENT 0150 OF 0206
   statement_code: CREATE_TMP_SEQUENCE_M2_12_REGISTRY_BEFORE
   phase_code: 07_REGISTRY_HASHES
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_sequence_m2_12_registry_before ON COMMIT DROP AS
SELECT 'msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq'::text AS sequence_name,
       s.last_value::bigint AS last_value,
       s.is_called::boolean AS is_called
FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq s;

/* R10 GOVERNED STATEMENT 0151 OF 0206
   statement_code: ASSERT_TMP_SEQUENCE_M2_12_REGISTRY_BEFORE
   phase_code: 07_REGISTRY_HASHES
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_sequence_m2_12_registry_before$ BEGIN IF (SELECT count(*) FROM tmp_sequence_m2_12_registry_before) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_sequence_m2_12_registry_before', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_sequence_m2_12_registry_before)::text; END IF; END; $m212_r7_tmp_sequence_m2_12_registry_before$;

/* R10 GOVERNED STATEMENT 0152 OF 0206
   statement_code: INDEX_TMP_SEQUENCE_M2_12_REGISTRY_BEFORE
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_sequence_m2_12_registry_before_88ea1c53 ON tmp_sequence_m2_12_registry_before (sequence_name);

/* R10 GOVERNED STATEMENT 0153 OF 0206
   statement_code: ANALYZE_TMP_SEQUENCE_M2_12_REGISTRY_BEFORE
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_sequence_m2_12_registry_before;

/* R10 GOVERNED STATEMENT 0154 OF 0206
   statement_code: CREATE_TMP_REGISTRY_M2_12_G3_SEED
   phase_code: 07_REGISTRY_HASHES
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_registry_m2_12_g3_seed ON COMMIT DROP AS
SELECT 'G3_M2_CONTRACT'::text AS acceptance_gate_id,
       l.all_capability_boundary_pass_flag::boolean AS all_capability_boundary_pass_flag,
       l.all_component_contract_pass_flag::boolean AS all_component_contract_pass_flag,
       l.all_contract_reproduction_pass_flag::boolean AS all_contract_reproduction_pass_flag,
       l.all_evidence_certification_pass_flag::boolean AS all_evidence_certification_pass_flag,
       l.all_source_graph_edges_pass_flag::boolean AS all_source_graph_edges_pass_flag,
       l.all_stage_certification_pass_flag::boolean AS all_stage_certification_pass_flag,
       1500::bigint AS application_consumption_rows,
       'SYNTHETIC_AS_BUILT_MODULE2_G3'::text AS as_built_certification_scope_code,
       'M2_G3_CONSUMPTION_BUNDLE'::text AS bundle_code,
       134::integer AS canonical_entity_count,
       9::integer AS canonical_family_count,
       20::integer AS capability_coverage_count,
       l.capability_summary::jsonb AS capability_summary,
       true::boolean AS certification_only_flag,
       7129::bigint AS component_archive_rows_total,
       13::integer AS component_contract_count,
       7129::bigint AS component_latest_rows_total,
       13::integer AS contract_reproduction_count,
       'GENERATED'::text AS contract_status,
       1::integer AS contract_version,
       l.deferred_capability_payload::jsonb AS deferred_capability_payload,
       false::boolean AS deployment_authorized_flag,
       false::boolean AS empirical_or_causal_optimization_authorized_flag,
       72::integer AS evidence_certification_count,
       false::boolean AS external_system_update_authorized_flag,
       false::boolean AS legal_or_regulatory_certified_flag,
       'M2_12_METHOD_V1'::text AS methodology_version,
       ctx.module1_run_id::bigint AS module1_run_id,
       false::boolean AS module3_execution_authorized_flag,
       true::boolean AS no_pii_flag,
       59::integer AS operational_account_consumption_rows,
       false::boolean AS production_action_authorized_flag,
       l.residual_limitation_payload::jsonb AS residual_limitation_payload,
       'M2_G3_BUNDLE_SCHEMA_V1'::text AS schema_version,
       19::integer AS source_graph_edge_count,
       12::integer AS source_node_count,
       70821::bigint AS stage_local_canonical_reference_total,
       24::integer AS strategy_scope_consumption_rows,
       true::boolean AS synthetic_data_only_flag
FROM tmp_latest_m2_12_g3_typed l
JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=l.module1_run_id;

/* R10 GOVERNED STATEMENT 0155 OF 0206
   statement_code: ASSERT_TMP_REGISTRY_M2_12_G3_SEED
   phase_code: 07_REGISTRY_HASHES
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_registry_m2_12_g3_seed$ BEGIN IF (SELECT count(*) FROM tmp_registry_m2_12_g3_seed) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_registry_m2_12_g3_seed', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_registry_m2_12_g3_seed)::text; END IF; END; $m212_r7_tmp_registry_m2_12_g3_seed$;

/* R10 GOVERNED STATEMENT 0156 OF 0206
   statement_code: INDEX_TMP_REGISTRY_M2_12_G3_SEED
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_registry_m2_12_g3_seed_f12028b7 ON tmp_registry_m2_12_g3_seed (module1_run_id, contract_version);

/* R10 GOVERNED STATEMENT 0157 OF 0206
   statement_code: ANALYZE_TMP_REGISTRY_M2_12_G3_SEED
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_registry_m2_12_g3_seed;

/* R10 GOVERNED STATEMENT 0158 OF 0206
   statement_code: CREATE_TMP_HASH_M2_12_PRE_REGISTRY
   phase_code: 07_REGISTRY_HASHES
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_hash_m2_12_pre_registry ON COMMIT DROP AS
(SELECT (SELECT md5(string_agg(a.bundle_code||'|'||a.contract_version::text||'|'||a.archive_row_hash,'|' ORDER BY a.bundle_code,a.contract_version))::text FROM tmp_archive_m2_12_g3_typed a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=1) AS archive_set_hash,
       b.capability_coverage_set_hash::text AS capability_coverage_set_hash,
       b.contract_component_set_hash::text AS contract_component_set_hash,
       b.contract_reproduction_set_hash::text AS contract_reproduction_set_hash,
       b.evidence_certification_set_hash::text AS evidence_certification_set_hash,
       (SELECT md5(string_agg(l.bundle_code||'|'||l.contract_version::text||'|'||l.row_hash,'|' ORDER BY l.bundle_code,l.contract_version))::text FROM tmp_latest_m2_12_g3_typed l WHERE l.module1_run_id=ctx.module1_run_id AND l.contract_version=1) AS latest_set_hash,
       ctx.module1_run_id::bigint AS module1_run_id,
       b.policy_set_hash::text AS policy_set_hash,
       b.stage_certification_set_hash::text AS stage_certification_set_hash
FROM tmp_archive_m2_12_g3_typed a
CROSS JOIN tmp_hash_m2_12_base_six b
CROSS JOIN tmp_src_m2_12_run_context ctx
WHERE a.module1_run_id=ctx.module1_run_id
  AND a.contract_version=1
  AND b.module1_run_id=ctx.module1_run_id);

/* R10 GOVERNED STATEMENT 0159 OF 0206
   statement_code: ASSERT_TMP_HASH_M2_12_PRE_REGISTRY
   phase_code: 07_REGISTRY_HASHES
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_hash_m2_12_pre_registry$ BEGIN IF (SELECT count(*) FROM tmp_hash_m2_12_pre_registry) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_hash_m2_12_pre_registry', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_hash_m2_12_pre_registry)::text; END IF; END; $m212_r7_tmp_hash_m2_12_pre_registry$;

/* R10 GOVERNED STATEMENT 0160 OF 0206
   statement_code: INDEX_TMP_HASH_M2_12_PRE_REGISTRY
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_hash_m2_12_pre_registry_6ddd7bea ON tmp_hash_m2_12_pre_registry (module1_run_id);

/* R10 GOVERNED STATEMENT 0161 OF 0206
   statement_code: ANALYZE_TMP_HASH_M2_12_PRE_REGISTRY
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_hash_m2_12_pre_registry;

/* R10 GOVERNED STATEMENT 0162 OF 0206
   statement_code: CREATE_TMP_REGISTRY_M2_12_G3_STABLE_TYPED
   phase_code: 07_REGISTRY_HASHES
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_registry_m2_12_g3_stable_typed ON COMMIT DROP AS
SELECT rs.acceptance_gate_id::text AS acceptance_gate_id,
       NULL::timestamptz AS accepted_at,
       po.accepted_m2_11_combined_set_hash::text AS accepted_m2_11_combined_set_hash,
       po.accepted_m2_11_contract_set_hash::text AS accepted_m2_11_contract_set_hash,
       po.accepted_m2_11_project_sha256::text AS accepted_m2_11_project_sha256,
       po.accepted_m2_11_registry_row_hash::text AS accepted_m2_11_registry_row_hash,
       rs.all_capability_boundary_pass_flag::boolean AS all_capability_boundary_pass_flag,
       rs.all_component_contract_pass_flag::boolean AS all_component_contract_pass_flag,
       rs.all_contract_reproduction_pass_flag::boolean AS all_contract_reproduction_pass_flag,
       rs.all_evidence_certification_pass_flag::boolean AS all_evidence_certification_pass_flag,
       rs.all_source_graph_edges_pass_flag::boolean AS all_source_graph_edges_pass_flag,
       rs.all_stage_certification_pass_flag::boolean AS all_stage_certification_pass_flag,
       rs.application_consumption_rows::bigint AS application_consumption_rows,
       a.contract_row_hash::text AS archive_contract_row_hash,
       h.archive_set_hash::text AS archive_set_hash,
       rs.as_built_certification_scope_code::text AS as_built_certification_scope_code,
       rs.bundle_code::text AS bundle_code,
       rs.canonical_entity_count::integer AS canonical_entity_count,
       rs.canonical_family_count::integer AS canonical_family_count,
       rs.capability_coverage_count::integer AS capability_coverage_count,
       h.capability_coverage_set_hash::text AS capability_coverage_set_hash,
       rs.certification_only_flag::boolean AS certification_only_flag,
       rs.component_archive_rows_total::bigint AS component_archive_rows_total,
       rs.component_contract_count::integer AS component_contract_count,
       rs.component_latest_rows_total::bigint AS component_latest_rows_total,
       h.contract_component_set_hash::text AS contract_component_set_hash,
       rs.contract_reproduction_count::integer AS contract_reproduction_count,
       h.contract_reproduction_set_hash::text AS contract_reproduction_set_hash,
       rs.contract_status::text AS contract_status,
       rs.contract_version::integer AS contract_version,
       l.created_at::timestamptz AS created_at,
       rs.deferred_capability_payload::jsonb AS deferred_capability_payload,
       rs.deployment_authorized_flag::boolean AS deployment_authorized_flag,
       rs.empirical_or_causal_optimization_authorized_flag::boolean AS empirical_or_causal_optimization_authorized_flag,
       rs.evidence_certification_count::integer AS evidence_certification_count,
       h.evidence_certification_set_hash::text AS evidence_certification_set_hash,
       rs.external_system_update_authorized_flag::boolean AS external_system_update_authorized_flag,
       l.created_at::timestamptz AS generated_at,
       l.contract_row_hash::text AS latest_contract_row_hash,
       h.latest_set_hash::text AS latest_set_hash,
       rs.legal_or_regulatory_certified_flag::boolean AS legal_or_regulatory_certified_flag,
       rs.methodology_version::text AS methodology_version,
       rs.module1_run_id::bigint AS module1_run_id,
       rs.module3_execution_authorized_flag::boolean AS module3_execution_authorized_flag,
       rs.no_pii_flag::boolean AS no_pii_flag,
       rs.operational_account_consumption_rows::integer AS operational_account_consumption_rows,
       po.policy_code::text AS policy_code,
       po.configuration_hash::text AS policy_configuration_hash,
       h.policy_set_hash::text AS policy_set_hash,
       po.policy_version::integer AS policy_version,
       rs.production_action_authorized_flag::boolean AS production_action_authorized_flag,
       rs.residual_limitation_payload::jsonb AS residual_limitation_payload,
       rs.schema_version::text AS schema_version,
       rs.source_graph_edge_count::integer AS source_graph_edge_count,
       rs.source_node_count::integer AS source_node_count,
       h.stage_certification_set_hash::text AS stage_certification_set_hash,
       rs.stage_local_canonical_reference_total::bigint AS stage_local_canonical_reference_total,
       rs.strategy_scope_consumption_rows::integer AS strategy_scope_consumption_rows,
       rs.synthetic_data_only_flag::boolean AS synthetic_data_only_flag,
       l.created_at::timestamptz AS updated_at,
       NULL::timestamptz AS validated_at
FROM tmp_registry_m2_12_g3_seed rs CROSS JOIN tmp_src_m2_12_policy_observation po CROSS JOIN tmp_hash_m2_12_pre_registry h CROSS JOIN tmp_latest_m2_12_g3_typed l CROSS JOIN tmp_archive_m2_12_g3_typed a CROSS JOIN tmp_src_m2_12_run_context ctx
WHERE rs.module1_run_id=ctx.module1_run_id AND rs.module1_run_id=po.module1_run_id AND rs.module1_run_id=h.module1_run_id AND rs.module1_run_id=l.module1_run_id AND rs.module1_run_id=a.module1_run_id AND rs.contract_version=l.contract_version AND rs.contract_version=a.contract_version;

/* R10 GOVERNED STATEMENT 0163 OF 0206
   statement_code: ASSERT_TMP_REGISTRY_M2_12_G3_STABLE_TYPED
   phase_code: 07_REGISTRY_HASHES
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_registry_m2_12_g3_stable_typed$ BEGIN IF (SELECT count(*) FROM tmp_registry_m2_12_g3_stable_typed) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_registry_m2_12_g3_stable_typed', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_registry_m2_12_g3_stable_typed)::text; END IF; END; $m212_r7_tmp_registry_m2_12_g3_stable_typed$;

/* R10 GOVERNED STATEMENT 0164 OF 0206
   statement_code: INDEX_TMP_REGISTRY_M2_12_G3_STABLE_TYPED
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_registry_m2_12_g3_stable_typed_fe018a8f ON tmp_registry_m2_12_g3_stable_typed (module1_run_id, contract_version);

/* R10 GOVERNED STATEMENT 0165 OF 0206
   statement_code: ANALYZE_TMP_REGISTRY_M2_12_G3_STABLE_TYPED
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_registry_m2_12_g3_stable_typed;

/* R10 GOVERNED STATEMENT 0166 OF 0206
   statement_code: CREATE_TMP_REGISTRY_M2_12_G3_PREHASHED
   phase_code: 07_REGISTRY_HASHES
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_registry_m2_12_g3_prehashed ON COMMIT DROP AS
(SELECT s.acceptance_gate_id::text AS acceptance_gate_id,
       s.accepted_at::timestamptz AS accepted_at,
       s.accepted_m2_11_combined_set_hash::text AS accepted_m2_11_combined_set_hash,
       s.accepted_m2_11_contract_set_hash::text AS accepted_m2_11_contract_set_hash,
       s.accepted_m2_11_project_sha256::text AS accepted_m2_11_project_sha256,
       s.accepted_m2_11_registry_row_hash::text AS accepted_m2_11_registry_row_hash,
       s.all_capability_boundary_pass_flag::boolean AS all_capability_boundary_pass_flag,
       s.all_component_contract_pass_flag::boolean AS all_component_contract_pass_flag,
       s.all_contract_reproduction_pass_flag::boolean AS all_contract_reproduction_pass_flag,
       s.all_evidence_certification_pass_flag::boolean AS all_evidence_certification_pass_flag,
       s.all_source_graph_edges_pass_flag::boolean AS all_source_graph_edges_pass_flag,
       s.all_stage_certification_pass_flag::boolean AS all_stage_certification_pass_flag,
       s.application_consumption_rows::bigint AS application_consumption_rows,
       s.archive_contract_row_hash::text AS archive_contract_row_hash,
       s.archive_set_hash::text AS archive_set_hash,
       s.as_built_certification_scope_code::text AS as_built_certification_scope_code,
       s.bundle_code::text AS bundle_code,
       s.canonical_entity_count::integer AS canonical_entity_count,
       s.canonical_family_count::integer AS canonical_family_count,
       s.capability_coverage_count::integer AS capability_coverage_count,
       s.capability_coverage_set_hash::text AS capability_coverage_set_hash,
       s.certification_only_flag::boolean AS certification_only_flag,
       s.component_archive_rows_total::bigint AS component_archive_rows_total,
       s.component_contract_count::integer AS component_contract_count,
       s.component_latest_rows_total::bigint AS component_latest_rows_total,
       s.contract_component_set_hash::text AS contract_component_set_hash,
       s.contract_reproduction_count::integer AS contract_reproduction_count,
       s.contract_reproduction_set_hash::text AS contract_reproduction_set_hash,
       s.contract_status::text AS contract_status,
       s.contract_version::integer AS contract_version,
       s.created_at::timestamptz AS created_at,
       s.deferred_capability_payload::jsonb AS deferred_capability_payload,
       s.deployment_authorized_flag::boolean AS deployment_authorized_flag,
       s.empirical_or_causal_optimization_authorized_flag::boolean AS empirical_or_causal_optimization_authorized_flag,
       s.evidence_certification_count::integer AS evidence_certification_count,
       s.evidence_certification_set_hash::text AS evidence_certification_set_hash,
       s.external_system_update_authorized_flag::boolean AS external_system_update_authorized_flag,
       s.generated_at::timestamptz AS generated_at,
       s.latest_contract_row_hash::text AS latest_contract_row_hash,
       s.latest_set_hash::text AS latest_set_hash,
       s.legal_or_regulatory_certified_flag::boolean AS legal_or_regulatory_certified_flag,
       s.methodology_version::text AS methodology_version,
       s.module1_run_id::bigint AS module1_run_id,
       s.module3_execution_authorized_flag::boolean AS module3_execution_authorized_flag,
       s.no_pii_flag::boolean AS no_pii_flag,
       s.operational_account_consumption_rows::integer AS operational_account_consumption_rows,
       s.policy_code::text AS policy_code,
       s.policy_configuration_hash::text AS policy_configuration_hash,
       s.policy_set_hash::text AS policy_set_hash,
       s.policy_version::integer AS policy_version,
       s.production_action_authorized_flag::boolean AS production_action_authorized_flag,
       s.residual_limitation_payload::jsonb AS residual_limitation_payload,
       md5((to_jsonb(s)-'contract_status'-'generated_at'-'validated_at'-'accepted_at'-'created_at'-'updated_at'-'policy_set_hash'-'stage_certification_set_hash'-'contract_component_set_hash'-'evidence_certification_set_hash'-'contract_reproduction_set_hash'-'capability_coverage_set_hash'-'latest_set_hash'-'archive_set_hash')::text)::text AS row_hash,
       s.schema_version::text AS schema_version,
       s.source_graph_edge_count::integer AS source_graph_edge_count,
       s.source_node_count::integer AS source_node_count,
       s.stage_certification_set_hash::text AS stage_certification_set_hash,
       s.stage_local_canonical_reference_total::bigint AS stage_local_canonical_reference_total,
       s.strategy_scope_consumption_rows::integer AS strategy_scope_consumption_rows,
       s.synthetic_data_only_flag::boolean AS synthetic_data_only_flag,
       s.updated_at::timestamptz AS updated_at,
       s.validated_at::timestamptz AS validated_at
FROM tmp_src_m2_12_run_context ctx
CROSS JOIN tmp_registry_m2_12_g3_stable_typed s
WHERE (s.module1_run_id=ctx.module1_run_id AND s.contract_version=1) AND (s.contract_version=1));

/* R10 GOVERNED STATEMENT 0167 OF 0206
   statement_code: ASSERT_TMP_REGISTRY_M2_12_G3_PREHASHED
   phase_code: 07_REGISTRY_HASHES
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_registry_m2_12_g3_prehashed$ BEGIN IF (SELECT count(*) FROM tmp_registry_m2_12_g3_prehashed) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_registry_m2_12_g3_prehashed', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_registry_m2_12_g3_prehashed)::text; END IF; END; $m212_r7_tmp_registry_m2_12_g3_prehashed$;

/* R10 GOVERNED STATEMENT 0168 OF 0206
   statement_code: INDEX_TMP_REGISTRY_M2_12_G3_PREHASHED
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_registry_m2_12_g3_prehashed_5e4e0bec ON tmp_registry_m2_12_g3_prehashed (module1_run_id, contract_version);

/* R10 GOVERNED STATEMENT 0169 OF 0206
   statement_code: ANALYZE_TMP_REGISTRY_M2_12_G3_PREHASHED
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_registry_m2_12_g3_prehashed;

/* R10 GOVERNED STATEMENT 0170 OF 0206
   statement_code: CREATE_TMP_HASH_M2_12_REGISTRY
   phase_code: 07_REGISTRY_HASHES
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_hash_m2_12_registry ON COMMIT DROP AS
(SELECT ctx.module1_run_id::bigint AS module1_run_id,
       md5(string_agg(r.bundle_code||'|'||r.contract_version::text||'|'||r.row_hash,'|' ORDER BY r.bundle_code,r.contract_version))::text AS registry_set_hash
FROM tmp_src_m2_12_run_context ctx
CROSS JOIN tmp_registry_m2_12_g3_prehashed r
WHERE ctx.run_status='M2_11_ACCEPTED'
  AND r.module1_run_id=ctx.module1_run_id
GROUP BY ctx.module1_run_id);

/* R10 GOVERNED STATEMENT 0171 OF 0206
   statement_code: ASSERT_TMP_HASH_M2_12_REGISTRY
   phase_code: 07_REGISTRY_HASHES
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_hash_m2_12_registry$ BEGIN IF (SELECT count(*) FROM tmp_hash_m2_12_registry) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_hash_m2_12_registry', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_hash_m2_12_registry)::text; END IF; END; $m212_r7_tmp_hash_m2_12_registry$;

/* R10 GOVERNED STATEMENT 0172 OF 0206
   statement_code: INDEX_TMP_HASH_M2_12_REGISTRY
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_hash_m2_12_registry_81430a21 ON tmp_hash_m2_12_registry (module1_run_id);

/* R10 GOVERNED STATEMENT 0173 OF 0206
   statement_code: ANALYZE_TMP_HASH_M2_12_REGISTRY
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_hash_m2_12_registry;

/* R10 GOVERNED STATEMENT 0174 OF 0206
   statement_code: CREATE_TMP_HASH_M2_12_CONTRACT
   phase_code: 07_REGISTRY_HASHES
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_hash_m2_12_contract ON COMMIT DROP AS
(SELECT md5(concat_ws('|',r.bundle_code,r.contract_version::text,r.schema_version,r.methodology_version,r.policy_configuration_hash,r.policy_set_hash,r.stage_certification_set_hash,r.contract_component_set_hash,r.evidence_certification_set_hash,r.contract_reproduction_set_hash,r.capability_coverage_set_hash,r.latest_set_hash,r.archive_set_hash,rh.registry_set_hash,r.latest_contract_row_hash,r.archive_contract_row_hash,r.row_hash,r.accepted_m2_11_contract_set_hash,r.accepted_m2_11_combined_set_hash,r.accepted_m2_11_registry_row_hash))::text AS contract_set_hash,
       ctx.module1_run_id::bigint AS module1_run_id
FROM tmp_src_m2_12_run_context ctx
CROSS JOIN tmp_registry_m2_12_g3_prehashed r
CROSS JOIN tmp_hash_m2_12_registry rh
WHERE ctx.run_status='M2_11_ACCEPTED'
  AND r.module1_run_id=ctx.module1_run_id
  AND rh.module1_run_id=ctx.module1_run_id);

/* R10 GOVERNED STATEMENT 0175 OF 0206
   statement_code: ASSERT_TMP_HASH_M2_12_CONTRACT
   phase_code: 07_REGISTRY_HASHES
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_hash_m2_12_contract$ BEGIN IF (SELECT count(*) FROM tmp_hash_m2_12_contract) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_hash_m2_12_contract', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_hash_m2_12_contract)::text; END IF; END; $m212_r7_tmp_hash_m2_12_contract$;

/* R10 GOVERNED STATEMENT 0176 OF 0206
   statement_code: INDEX_TMP_HASH_M2_12_CONTRACT
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_hash_m2_12_contract_92312293 ON tmp_hash_m2_12_contract (module1_run_id);

/* R10 GOVERNED STATEMENT 0177 OF 0206
   statement_code: ANALYZE_TMP_HASH_M2_12_CONTRACT
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_hash_m2_12_contract;

/* R10 GOVERNED STATEMENT 0178 OF 0206
   statement_code: CREATE_TMP_HASH_M2_12_CANONICAL_ENTITY_SOURCE
   phase_code: 07_REGISTRY_HASHES
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
CREATE TEMP TABLE tmp_hash_m2_12_canonical_entity_source ON COMMIT DROP AS
WITH canonical_rows AS
(
(
SELECT t.module1_run_id, 'POLICY'::text AS entity_type, (t.policy_code||'|'||t.policy_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_policy_profile t CROSS JOIN tmp_src_m2_12_run_context ctx WHERE t.module1_run_id=ctx.module1_run_id
)
UNION ALL
(
SELECT t.module1_run_id, 'STAGE_CERTIFICATION'::text AS entity_type, (t.certification_node_sequence::text||'|'||t.stage_code)::text AS entity_key, t.row_hash::text AS row_hash FROM tmp_cert_m2_12_stage_typed t CROSS JOIN tmp_src_m2_12_run_context ctx WHERE t.module1_run_id=ctx.module1_run_id
)
UNION ALL
(
SELECT t.module1_run_id, 'CONTRACT_COMPONENT'::text AS entity_type, (t.component_sequence::text||'|'||t.component_contract_code||'|'||t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM tmp_cert_m2_12_component_typed t CROSS JOIN tmp_src_m2_12_run_context ctx WHERE t.module1_run_id=ctx.module1_run_id
)
UNION ALL
(
SELECT t.module1_run_id, 'EVIDENCE_CERTIFICATION'::text AS entity_type, (t.node_sequence::text||'|'||t.evidence_family_sequence::text)::text AS entity_key, t.row_hash::text AS row_hash FROM tmp_cert_m2_12_evidence_typed t CROSS JOIN tmp_src_m2_12_run_context ctx WHERE t.module1_run_id=ctx.module1_run_id
)
UNION ALL
(
SELECT t.module1_run_id, 'CONTRACT_REPRODUCTION'::text AS entity_type, (t.component_sequence::text||'|'||t.component_contract_code||'|'||t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM tmp_cert_m2_12_reproduction_typed t CROSS JOIN tmp_src_m2_12_run_context ctx WHERE t.module1_run_id=ctx.module1_run_id
)
UNION ALL
(
SELECT t.module1_run_id, 'CAPABILITY_COVERAGE'::text AS entity_type, (t.capability_sequence::text||'|'||t.capability_code)::text AS entity_key, t.row_hash::text AS row_hash FROM tmp_cert_m2_12_capability_typed t CROSS JOIN tmp_src_m2_12_run_context ctx WHERE t.module1_run_id=ctx.module1_run_id
)
UNION ALL
(
SELECT t.module1_run_id, 'LATEST'::text AS entity_type, (t.bundle_code||'|'||t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM tmp_latest_m2_12_g3_typed t CROSS JOIN tmp_src_m2_12_run_context ctx WHERE t.module1_run_id=ctx.module1_run_id
)
UNION ALL
(
SELECT t.module1_run_id, 'ARCHIVE'::text AS entity_type, (t.bundle_code||'|'||t.contract_version::text)::text AS entity_key, t.archive_row_hash::text AS row_hash FROM tmp_archive_m2_12_g3_typed t CROSS JOIN tmp_src_m2_12_run_context ctx WHERE t.module1_run_id=ctx.module1_run_id
)
UNION ALL
(
SELECT t.module1_run_id, 'REGISTRY'::text AS entity_type, (t.bundle_code||'|'||t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM tmp_registry_m2_12_g3_prehashed t CROSS JOIN tmp_src_m2_12_run_context ctx WHERE t.module1_run_id=ctx.module1_run_id
)
)
SELECT
    c.entity_key::text AS entity_key,
    c.entity_type::text AS entity_type,
    c.module1_run_id::bigint AS module1_run_id,
    c.row_hash::text AS row_hash
FROM canonical_rows c;

/* R10 GOVERNED STATEMENT 0179 OF 0206
   statement_code: ASSERT_TMP_HASH_M2_12_CANONICAL_ENTITY_SOURCE
   phase_code: 07_REGISTRY_HASHES
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
DO $m212_r10_canonical_assert$
BEGIN
    IF NOT (((SELECT count(*) FROM tmp_hash_m2_12_canonical_entity_source)=134) AND ((SELECT count(DISTINCT (module1_run_id,entity_type,entity_key)) FROM tmp_hash_m2_12_canonical_entity_source)=134) AND ((SELECT count(DISTINCT entity_type) FROM tmp_hash_m2_12_canonical_entity_source)=9) AND ((SELECT count(*) FILTER (WHERE entity_type='POLICY')=1
              AND count(*) FILTER (WHERE entity_type='STAGE_CERTIFICATION')=12
              AND count(*) FILTER (WHERE entity_type='CONTRACT_COMPONENT')=13
              AND count(*) FILTER (WHERE entity_type='EVIDENCE_CERTIFICATION')=72
              AND count(*) FILTER (WHERE entity_type='CONTRACT_REPRODUCTION')=13
              AND count(*) FILTER (WHERE entity_type='CAPABILITY_COVERAGE')=20
              AND count(*) FILTER (WHERE entity_type='LATEST')=1
              AND count(*) FILTER (WHERE entity_type='ARCHIVE')=1
              AND count(*) FILTER (WHERE entity_type='REGISTRY')=1
           FROM tmp_hash_m2_12_canonical_entity_source))) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 R10 helper cardinality or business-key mismatch: tmp_hash_m2_12_canonical_entity_source',
            DETAIL='expected_rows=134'||'; '||'observed_rows='||(SELECT count(*) FROM tmp_hash_m2_12_canonical_entity_source)::text;
    END IF;
END;
$m212_r10_canonical_assert$;

/* R10 GOVERNED STATEMENT 0180 OF 0206
   statement_code: INDEX_TMP_HASH_M2_12_CANONICAL_ENTITY_SOURCE
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_hash_m2_12_canonical_entity_source_2946bd70 ON tmp_hash_m2_12_canonical_entity_source (module1_run_id, entity_type, entity_key);

/* R10 GOVERNED STATEMENT 0181 OF 0206
   statement_code: ANALYZE_TMP_HASH_M2_12_CANONICAL_ENTITY_SOURCE
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_hash_m2_12_canonical_entity_source;

/* R10 GOVERNED STATEMENT 0182 OF 0206
   statement_code: CREATE_TMP_HASH_M2_12_COMBINED
   phase_code: 07_REGISTRY_HASHES
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_hash_m2_12_combined ON COMMIT DROP AS
(SELECT md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key))::text AS combined_set_hash,
       ctx.module1_run_id::bigint AS module1_run_id
FROM tmp_src_m2_12_run_context ctx
CROSS JOIN tmp_hash_m2_12_canonical_entity_source u
WHERE ctx.run_status='M2_11_ACCEPTED'
  AND u.module1_run_id=ctx.module1_run_id
GROUP BY ctx.module1_run_id);

/* R10 GOVERNED STATEMENT 0183 OF 0206
   statement_code: ASSERT_TMP_HASH_M2_12_COMBINED
   phase_code: 07_REGISTRY_HASHES
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_hash_m2_12_combined$ BEGIN IF (SELECT count(*) FROM tmp_hash_m2_12_combined) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_hash_m2_12_combined', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_hash_m2_12_combined)::text; END IF; END; $m212_r7_tmp_hash_m2_12_combined$;

/* R10 GOVERNED STATEMENT 0184 OF 0206
   statement_code: INDEX_TMP_HASH_M2_12_COMBINED
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_hash_m2_12_combined_296cf186 ON tmp_hash_m2_12_combined (module1_run_id);

/* R10 GOVERNED STATEMENT 0185 OF 0206
   statement_code: ANALYZE_TMP_HASH_M2_12_COMBINED
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_hash_m2_12_combined;

/* R10 GOVERNED STATEMENT 0186 OF 0206
   statement_code: CREATE_TMP_REGISTRY_M2_12_G3_TYPED
   phase_code: 07_REGISTRY_HASHES
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_registry_m2_12_g3_typed ON COMMIT DROP AS
(SELECT r.module1_run_id::bigint AS module1_run_id,
       r.bundle_code::text AS bundle_code,
       r.contract_version::integer AS contract_version,
       r.schema_version::text AS schema_version,
       r.methodology_version::text AS methodology_version,
       r.acceptance_gate_id::text AS acceptance_gate_id,
       r.policy_code::text AS policy_code,
       r.policy_version::integer AS policy_version,
       r.policy_configuration_hash::text AS policy_configuration_hash,
       r.accepted_m2_11_project_sha256::text AS accepted_m2_11_project_sha256,
       r.accepted_m2_11_contract_set_hash::text AS accepted_m2_11_contract_set_hash,
       r.accepted_m2_11_combined_set_hash::text AS accepted_m2_11_combined_set_hash,
       r.accepted_m2_11_registry_row_hash::text AS accepted_m2_11_registry_row_hash,
       r.source_node_count::integer AS source_node_count,
       r.component_contract_count::integer AS component_contract_count,
       r.source_graph_edge_count::integer AS source_graph_edge_count,
       r.evidence_certification_count::integer AS evidence_certification_count,
       r.contract_reproduction_count::integer AS contract_reproduction_count,
       r.capability_coverage_count::integer AS capability_coverage_count,
       r.canonical_family_count::integer AS canonical_family_count,
       r.canonical_entity_count::integer AS canonical_entity_count,
       r.application_consumption_rows::bigint AS application_consumption_rows,
       r.operational_account_consumption_rows::integer AS operational_account_consumption_rows,
       r.strategy_scope_consumption_rows::integer AS strategy_scope_consumption_rows,
       r.component_latest_rows_total::bigint AS component_latest_rows_total,
       r.component_archive_rows_total::bigint AS component_archive_rows_total,
       r.stage_local_canonical_reference_total::bigint AS stage_local_canonical_reference_total,
       r.all_stage_certification_pass_flag::boolean AS all_stage_certification_pass_flag,
       r.all_component_contract_pass_flag::boolean AS all_component_contract_pass_flag,
       r.all_evidence_certification_pass_flag::boolean AS all_evidence_certification_pass_flag,
       r.all_contract_reproduction_pass_flag::boolean AS all_contract_reproduction_pass_flag,
       r.all_capability_boundary_pass_flag::boolean AS all_capability_boundary_pass_flag,
       r.all_source_graph_edges_pass_flag::boolean AS all_source_graph_edges_pass_flag,
       r.as_built_certification_scope_code::text AS as_built_certification_scope_code,
       r.residual_limitation_payload::jsonb AS residual_limitation_payload,
       r.deferred_capability_payload::jsonb AS deferred_capability_payload,
       r.synthetic_data_only_flag::boolean AS synthetic_data_only_flag,
       r.no_pii_flag::boolean AS no_pii_flag,
       r.certification_only_flag::boolean AS certification_only_flag,
       r.production_action_authorized_flag::boolean AS production_action_authorized_flag,
       r.external_system_update_authorized_flag::boolean AS external_system_update_authorized_flag,
       r.legal_or_regulatory_certified_flag::boolean AS legal_or_regulatory_certified_flag,
       r.empirical_or_causal_optimization_authorized_flag::boolean AS empirical_or_causal_optimization_authorized_flag,
       r.deployment_authorized_flag::boolean AS deployment_authorized_flag,
       r.module3_execution_authorized_flag::boolean AS module3_execution_authorized_flag,
       r.policy_set_hash::text AS policy_set_hash,
       r.stage_certification_set_hash::text AS stage_certification_set_hash,
       r.contract_component_set_hash::text AS contract_component_set_hash,
       r.evidence_certification_set_hash::text AS evidence_certification_set_hash,
       r.contract_reproduction_set_hash::text AS contract_reproduction_set_hash,
       r.capability_coverage_set_hash::text AS capability_coverage_set_hash,
       r.latest_set_hash::text AS latest_set_hash,
       r.archive_set_hash::text AS archive_set_hash,
       rh.registry_set_hash::text AS registry_set_hash,
       r.latest_contract_row_hash::text AS latest_contract_row_hash,
       r.archive_contract_row_hash::text AS archive_contract_row_hash,
       ch.contract_set_hash::text AS contract_set_hash,
       xh.combined_set_hash::text AS combined_set_hash,
       r.contract_status::text AS contract_status,
       r.generated_at::timestamptz AS generated_at,
       r.validated_at::timestamptz AS validated_at,
       r.accepted_at::timestamptz AS accepted_at,
       r.row_hash::text AS row_hash,
       r.created_at::timestamptz AS created_at,
       r.updated_at::timestamptz AS updated_at
FROM tmp_hash_m2_12_contract ch
CROSS JOIN tmp_registry_m2_12_g3_prehashed r
CROSS JOIN tmp_hash_m2_12_registry rh
CROSS JOIN tmp_hash_m2_12_combined xh
WHERE (r.module1_run_id=rh.module1_run_id AND r.module1_run_id=ch.module1_run_id AND r.module1_run_id=xh.module1_run_id) AND (r.contract_version=1));

/* R10 GOVERNED STATEMENT 0187 OF 0206
   statement_code: ASSERT_TMP_REGISTRY_M2_12_G3_TYPED
   phase_code: 07_REGISTRY_HASHES
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_registry_m2_12_g3_typed$ BEGIN IF (SELECT count(*) FROM tmp_registry_m2_12_g3_typed) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_registry_m2_12_g3_typed', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_registry_m2_12_g3_typed)::text; END IF; END; $m212_r7_tmp_registry_m2_12_g3_typed$;

/* R10 GOVERNED STATEMENT 0188 OF 0206
   statement_code: INDEX_TMP_REGISTRY_M2_12_G3_TYPED
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_registry_m2_12_g3_typed_b8aa3b3d ON tmp_registry_m2_12_g3_typed (module1_run_id, contract_version);

/* R10 GOVERNED STATEMENT 0189 OF 0206
   statement_code: ANALYZE_TMP_REGISTRY_M2_12_G3_TYPED
   phase_code: 07_REGISTRY_HASHES
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_registry_m2_12_g3_typed;

/* R10 GOVERNED STATEMENT 0190 OF 0206
   statement_code: INSERT_REGISTRY
   phase_code: 08_REGISTRY_INSERT
   statement_type: PERSISTENT_INSERT
   source_authority: M2_12_PERSISTENT_INSERT_STATEMENT_COMPILER.csv
*/
INSERT INTO msbf_ctl.m2_12_g3_bundle_registry (
    "module1_run_id",
    "bundle_code",
    "contract_version",
    "schema_version",
    "methodology_version",
    "acceptance_gate_id",
    "policy_code",
    "policy_version",
    "policy_configuration_hash",
    "accepted_m2_11_project_sha256",
    "accepted_m2_11_contract_set_hash",
    "accepted_m2_11_combined_set_hash",
    "accepted_m2_11_registry_row_hash",
    "source_node_count",
    "component_contract_count",
    "source_graph_edge_count",
    "evidence_certification_count",
    "contract_reproduction_count",
    "capability_coverage_count",
    "canonical_family_count",
    "canonical_entity_count",
    "application_consumption_rows",
    "operational_account_consumption_rows",
    "strategy_scope_consumption_rows",
    "component_latest_rows_total",
    "component_archive_rows_total",
    "stage_local_canonical_reference_total",
    "all_stage_certification_pass_flag",
    "all_component_contract_pass_flag",
    "all_evidence_certification_pass_flag",
    "all_contract_reproduction_pass_flag",
    "all_capability_boundary_pass_flag",
    "all_source_graph_edges_pass_flag",
    "as_built_certification_scope_code",
    "residual_limitation_payload",
    "deferred_capability_payload",
    "synthetic_data_only_flag",
    "no_pii_flag",
    "certification_only_flag",
    "production_action_authorized_flag",
    "external_system_update_authorized_flag",
    "legal_or_regulatory_certified_flag",
    "empirical_or_causal_optimization_authorized_flag",
    "deployment_authorized_flag",
    "module3_execution_authorized_flag",
    "policy_set_hash",
    "stage_certification_set_hash",
    "contract_component_set_hash",
    "evidence_certification_set_hash",
    "contract_reproduction_set_hash",
    "capability_coverage_set_hash",
    "latest_set_hash",
    "archive_set_hash",
    "registry_set_hash",
    "latest_contract_row_hash",
    "archive_contract_row_hash",
    "contract_set_hash",
    "combined_set_hash",
    "contract_status",
    "generated_at",
    "validated_at",
    "accepted_at",
    "row_hash",
    "created_at",
    "updated_at"
)
SELECT
    src.module1_run_id::bigint,
    src.bundle_code::text,
    src.contract_version::integer,
    src.schema_version::text,
    src.methodology_version::text,
    src.acceptance_gate_id::text,
    src.policy_code::text,
    src.policy_version::integer,
    src.policy_configuration_hash::text,
    src.accepted_m2_11_project_sha256::text,
    src.accepted_m2_11_contract_set_hash::text,
    src.accepted_m2_11_combined_set_hash::text,
    src.accepted_m2_11_registry_row_hash::text,
    src.source_node_count::integer,
    src.component_contract_count::integer,
    src.source_graph_edge_count::integer,
    src.evidence_certification_count::integer,
    src.contract_reproduction_count::integer,
    src.capability_coverage_count::integer,
    src.canonical_family_count::integer,
    src.canonical_entity_count::integer,
    src.application_consumption_rows::bigint,
    src.operational_account_consumption_rows::integer,
    src.strategy_scope_consumption_rows::integer,
    src.component_latest_rows_total::bigint,
    src.component_archive_rows_total::bigint,
    src.stage_local_canonical_reference_total::bigint,
    src.all_stage_certification_pass_flag::boolean,
    src.all_component_contract_pass_flag::boolean,
    src.all_evidence_certification_pass_flag::boolean,
    src.all_contract_reproduction_pass_flag::boolean,
    src.all_capability_boundary_pass_flag::boolean,
    src.all_source_graph_edges_pass_flag::boolean,
    src.as_built_certification_scope_code::text,
    src.residual_limitation_payload::jsonb,
    src.deferred_capability_payload::jsonb,
    src.synthetic_data_only_flag::boolean,
    src.no_pii_flag::boolean,
    src.certification_only_flag::boolean,
    src.production_action_authorized_flag::boolean,
    src.external_system_update_authorized_flag::boolean,
    src.legal_or_regulatory_certified_flag::boolean,
    src.empirical_or_causal_optimization_authorized_flag::boolean,
    src.deployment_authorized_flag::boolean,
    src.module3_execution_authorized_flag::boolean,
    src.policy_set_hash::text,
    src.stage_certification_set_hash::text,
    src.contract_component_set_hash::text,
    src.evidence_certification_set_hash::text,
    src.contract_reproduction_set_hash::text,
    src.capability_coverage_set_hash::text,
    src.latest_set_hash::text,
    src.archive_set_hash::text,
    src.registry_set_hash::text,
    src.latest_contract_row_hash::text,
    src.archive_contract_row_hash::text,
    src.contract_set_hash::text,
    src.combined_set_hash::text,
    src.contract_status::text,
    src.generated_at::timestamptz,
    src.validated_at::timestamptz,
    src.accepted_at::timestamptz,
    src.row_hash::text,
    src.created_at::timestamptz,
    src.updated_at::timestamptz
FROM tmp_registry_m2_12_g3_typed src;

/* R10 GOVERNED STATEMENT 0191 OF 0206
   statement_code: CREATE_TMP_RECONCILE_M2_12_PHYSICAL
   phase_code: 09_PHASE9_RECONSTRUCTION
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_reconcile_m2_12_physical ON COMMIT DROP AS
SELECT
       p.module1_run_id::bigint AS module1_run_id,
       p.family_count_mismatch_count::bigint AS family_count_mismatch_count,
       p.row_hash_mismatch_count::bigint AS row_hash_mismatch_count,
       p.set_hash_mismatch_count::bigint AS set_hash_mismatch_count,
       p.contract_hash_mismatch_count::integer AS contract_hash_mismatch_count,
       p.combined_hash_mismatch_count::integer AS combined_hash_mismatch_count,
       p.sequence_state_mismatch_count::integer AS sequence_state_mismatch_count,
       p.canonical_families::integer AS canonical_families,
       p.canonical_entities::integer AS canonical_entities,
       p.total_mismatch_count::bigint AS total_mismatch_count,
       CASE WHEN p.total_mismatch_count=0 THEN 'PASS'::text ELSE 'FAIL'::text END AS reconciliation_status
FROM (
WITH row_detail AS ((SELECT 'POLICY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, 12::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>12)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, 72::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>72)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, 20::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>20)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'LATEST'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.archive_row_hash IS DISTINCT FROM md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'REGISTRY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'registry_id'-'contract_status'-'generated_at'-'validated_at'-'accepted_at'-'created_at'-'updated_at'-'row_hash'-'policy_set_hash'-'stage_certification_set_hash'-'contract_component_set_hash'-'evidence_certification_set_hash'-'contract_reproduction_set_hash'-'capability_coverage_set_hash'-'latest_set_hash'-'archive_set_hash'-'registry_set_hash'-'contract_set_hash'-'combined_set_hash')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id)),
rowd AS (SELECT sum(family_count_mismatch_count)::bigint family_count_mismatch_count,sum(row_hash_mismatch_count)::bigint row_hash_mismatch_count FROM row_detail),
set_detail AS ((SELECT 'POLICY'::text AS family_code, md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version))::text AS reconstructed_set_hash, r.policy_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version)) IS DISTINCT FROM r.policy_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.policy_set_hash) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code))::text AS reconstructed_set_hash, r.stage_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code)) IS DISTINCT FROM r.stage_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.stage_certification_set_hash) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_component_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_component_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_component_set_hash) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence))::text AS reconstructed_set_hash, r.evidence_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence)) IS DISTINCT FROM r.evidence_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.evidence_certification_set_hash) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_reproduction_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_reproduction_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_reproduction_set_hash) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code))::text AS reconstructed_set_hash, r.capability_coverage_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code)) IS DISTINCT FROM r.capability_coverage_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.capability_coverage_set_hash) UNION ALL (SELECT 'LATEST'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.latest_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.latest_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.latest_set_hash) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.archive_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.archive_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.archive_set_hash) UNION ALL (SELECT 'REGISTRY'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.registry_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.registry_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.registry_set_hash)),
setd AS (SELECT sum(set_hash_mismatch_count)::bigint set_hash_mismatch_count FROM set_detail),
ch AS (SELECT r.module1_run_id,
       md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text))::text AS reconstructed_contract_set_hash,
       r.contract_set_hash::text AS stored_contract_set_hash,
       (md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text)) IS DISTINCT FROM r.contract_set_hash)::integer AS contract_hash_mismatch_count
FROM msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1), cb AS (SELECT u.module1_run_id, count(*)::integer AS canonical_entities, count(DISTINCT u.entity_type)::integer AS canonical_families, md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key))::text AS reconstructed_combined_set_hash, r.combined_set_hash::text AS stored_combined_set_hash, (md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key)) IS DISTINCT FROM r.combined_set_hash)::integer AS combined_hash_mismatch_count FROM (SELECT t.module1_run_id, 'POLICY'::text AS entity_type, concat_ws('|',t.policy_code::text,t.policy_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'STAGE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.certification_node_sequence::text,t.stage_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_COMPONENT'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'EVIDENCE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_REPRODUCTION'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CAPABILITY_COVERAGE'::text AS entity_type, concat_ws('|',t.capability_sequence::text,t.capability_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'LATEST'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'ARCHIVE'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.archive_row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'REGISTRY'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) u JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=u.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY u.module1_run_id,r.combined_set_hash), seq AS (SELECT ctx.module1_run_id,
       p.last_value::bigint AS policy_last_value,p.is_called AS policy_is_called,
       a.last_value::bigint AS archive_last_value,a.is_called AS archive_is_called,
       r.last_value::bigint AS registry_last_value,r.is_called AS registry_is_called,
       ((p.last_value<>1 OR NOT p.is_called)::integer
        +(a.last_value<>1 OR NOT a.is_called)::integer
        +(r.last_value<>1 OR NOT r.is_called)::integer)::integer AS sequence_state_mismatch_count
FROM tmp_src_m2_12_run_context ctx
CROSS JOIN msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r)
SELECT ctx.module1_run_id,
       rowd.family_count_mismatch_count,rowd.row_hash_mismatch_count,setd.set_hash_mismatch_count,
       ch.contract_hash_mismatch_count::integer,cb.combined_hash_mismatch_count::integer,
       seq.sequence_state_mismatch_count::integer,cb.canonical_families::integer,cb.canonical_entities::integer,
       (rowd.family_count_mismatch_count+rowd.row_hash_mismatch_count+setd.set_hash_mismatch_count+ch.contract_hash_mismatch_count+cb.combined_hash_mismatch_count+seq.sequence_state_mismatch_count)::bigint AS total_mismatch_count
FROM tmp_src_m2_12_run_context ctx CROSS JOIN rowd CROSS JOIN setd CROSS JOIN ch CROSS JOIN cb CROSS JOIN seq
) p;

/* R10 GOVERNED STATEMENT 0192 OF 0206
   statement_code: ASSERT_TMP_RECONCILE_M2_12_PHYSICAL
   phase_code: 09_PHASE9_RECONSTRUCTION
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_hf8_physical_reconciliation_assert$
BEGIN
    IF NOT coalesce(
        (SELECT count(*)=1
             AND bool_and(reconciliation_status='PASS')
             AND bool_and(total_mismatch_count=0)
         FROM tmp_reconcile_m2_12_physical),false)
    THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 physical reconciliation mismatch',
            DETAIL=coalesce(
                (SELECT format('family_count=%s|row_hash=%s|set_hash=%s|contract_hash=%s|combined_hash=%s|sequence=%s|total=%s|status=%s',
                               family_count_mismatch_count,row_hash_mismatch_count,set_hash_mismatch_count,
                               contract_hash_mismatch_count,combined_hash_mismatch_count,sequence_state_mismatch_count,
                               total_mismatch_count,reconciliation_status)
                   FROM tmp_reconcile_m2_12_physical),
                'rows='||(SELECT count(*) FROM tmp_reconcile_m2_12_physical)::text);
    END IF;
END;
$m212_hf8_physical_reconciliation_assert$;

/* R10 GOVERNED STATEMENT 0193 OF 0206
   statement_code: INDEX_TMP_RECONCILE_M2_12_PHYSICAL
   phase_code: 09_PHASE9_RECONSTRUCTION
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_reconcile_m2_12_physical_b14ff6b2 ON tmp_reconcile_m2_12_physical (module1_run_id);

/* R10 GOVERNED STATEMENT 0194 OF 0206
   statement_code: ANALYZE_TMP_RECONCILE_M2_12_PHYSICAL
   phase_code: 09_PHASE9_RECONSTRUCTION
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_reconcile_m2_12_physical;

/* R10 GOVERNED STATEMENT 0195 OF 0206
   statement_code: CREATE_TMP_GENERATION_M2_12_EVIDENCE
   phase_code: 10_EVIDENCE
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
CREATE TEMP TABLE tmp_generation_m2_12_evidence ON COMMIT DROP AS
WITH generation_rows AS
(
(SELECT 1::smallint AS evidence_sequence,'M2_12_POLICY_SET_HASH'::text AS evidence_code,(((SELECT policy_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed policy set hash'::text AS expected_value,'HASH'::text AS unit_code,'Approved policy identity.'::text AS interpretation,CASE WHEN ((((SELECT policy_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_reconcile_m2_12_physical)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 2::smallint AS evidence_sequence,'M2_12_STAGE_CERTIFICATION_SET_HASH'::text AS evidence_code,(((SELECT stage_certification_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'Twelve source-node certification rows.'::text AS interpretation,CASE WHEN ((((SELECT stage_certification_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_reconcile_m2_12_physical)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 3::smallint AS evidence_sequence,'M2_12_CONTRACT_COMPONENT_SET_HASH'::text AS evidence_code,(((SELECT contract_component_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'Thirteen component contracts.'::text AS interpretation,CASE WHEN ((((SELECT contract_component_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_reconcile_m2_12_physical)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 4::smallint AS evidence_sequence,'M2_12_EVIDENCE_CERTIFICATION_SET_HASH'::text AS evidence_code,(((SELECT evidence_certification_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'Seventy-two mandatory PASS evidence certifications.'::text AS interpretation,CASE WHEN ((((SELECT evidence_certification_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_reconcile_m2_12_physical)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 5::smallint AS evidence_sequence,'M2_12_CONTRACT_REPRODUCTION_SET_HASH'::text AS evidence_code,(((SELECT contract_reproduction_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'Thirteen exact latest/archive reproductions.'::text AS interpretation,CASE WHEN ((((SELECT contract_reproduction_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_reconcile_m2_12_physical)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 6::smallint AS evidence_sequence,'M2_12_CAPABILITY_COVERAGE_SET_HASH'::text AS evidence_code,(((SELECT capability_coverage_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'Twenty as-built/deferred/prohibited capability rows.'::text AS interpretation,CASE WHEN ((((SELECT capability_coverage_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_reconcile_m2_12_physical)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 7::smallint AS evidence_sequence,'M2_12_LATEST_SET_HASH'::text AS evidence_code,(((SELECT latest_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'One G3 latest row.'::text AS interpretation,CASE WHEN ((((SELECT latest_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_reconcile_m2_12_physical)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 8::smallint AS evidence_sequence,'M2_12_ARCHIVE_SET_HASH'::text AS evidence_code,(((SELECT archive_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'One immutable G3 archive row.'::text AS interpretation,CASE WHEN ((((SELECT archive_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_reconcile_m2_12_physical)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 9::smallint AS evidence_sequence,'M2_12_REGISTRY_SET_HASH'::text AS evidence_code,(((SELECT registry_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals independently reconstructed set hash'::text AS expected_value,'HASH'::text AS unit_code,'One registry row and the ninth canonical-family set hash.'::text AS interpretation,CASE WHEN ((((SELECT registry_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_reconcile_m2_12_physical)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 10::smallint AS evidence_sequence,'M2_12_CONTRACT_SET_HASH'::text AS evidence_code,(((SELECT contract_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals registry and physical reconstruction'::text AS expected_value,'HASH'::text AS unit_code,'Acyclic contract identity over finalized component identities.'::text AS interpretation,CASE WHEN ((((SELECT contract_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_reconcile_m2_12_physical)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 11::smallint AS evidence_sequence,'M2_12_COMBINED_SET_HASH'::text AS evidence_code,(((SELECT combined_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text)::text AS observed_value,'32 lowercase hex; equals registry and independent reconstruction'::text AS expected_value,'HASH'::text AS unit_code,'Final deterministic M2.12 combined identity.'::text AS interpretation,CASE WHEN ((((SELECT combined_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1))::text) ~ '^[0-9a-f]{32}$' AND (SELECT total_mismatch_count=0 FROM tmp_reconcile_m2_12_physical)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 12::smallint AS evidence_sequence,'M2_12_STAGE_CERTIFICATION_ROWS'::text AS evidence_code,(((SELECT count(*)::text FROM msbf_m2.module2_stage_certification_snapshot s JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text)::text AS observed_value,'12'::text AS expected_value,'ROWS'::text AS unit_code,'One row for each of 12 source-certification nodes.'::text AS interpretation,CASE WHEN ((((SELECT count(*)::text FROM msbf_m2.module2_stage_certification_snapshot s JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text) IS NOT DISTINCT FROM '12'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 13::smallint AS evidence_sequence,'M2_12_CONTRACT_COMPONENT_ROWS'::text AS evidence_code,(((SELECT count(*)::text FROM msbf_m2.module2_contract_component_snapshot s JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text)::text AS observed_value,'13'::text AS expected_value,'ROWS'::text AS unit_code,'One row for each component contract, including two M2.2 contracts.'::text AS interpretation,CASE WHEN ((((SELECT count(*)::text FROM msbf_m2.module2_contract_component_snapshot s JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text) IS NOT DISTINCT FROM '13'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 14::smallint AS evidence_sequence,'M2_12_EVIDENCE_CERTIFICATION_ROWS'::text AS evidence_code,(((SELECT count(*)||'|'||count(*) FILTER (WHERE certification_status='PASS')||' PASS|'||count(*) FILTER (WHERE certification_status<>'PASS')||' FAIL' FROM msbf_m2.module2_evidence_certification_snapshot s JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text)::text AS observed_value,'72|72 PASS|0 FAIL'::text AS expected_value,'ROWS'::text AS unit_code,'All six evidence families apply to all 12 nodes.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||count(*) FILTER (WHERE certification_status='PASS')||' PASS|'||count(*) FILTER (WHERE certification_status<>'PASS')||' FAIL' FROM msbf_m2.module2_evidence_certification_snapshot s JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text) IS NOT DISTINCT FROM '72|72 PASS|0 FAIL'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 15::smallint AS evidence_sequence,'M2_12_CONTRACT_REPRODUCTION_ROWS'::text AS evidence_code,(((SELECT count(*)||'|'||sum(payload_mismatch_count+missing_latest_rows+missing_archive_rows+latest_duplicate_key_rows+archive_duplicate_key_rows)||' mismatches' FROM msbf_m2.module2_contract_reproduction_snapshot s JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text)::text AS observed_value,'13|0 mismatches'::text AS expected_value,'ROWS'::text AS unit_code,'One successful reproduction row per component contract.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||sum(payload_mismatch_count+missing_latest_rows+missing_archive_rows+latest_duplicate_key_rows+archive_duplicate_key_rows)||' mismatches' FROM msbf_m2.module2_contract_reproduction_snapshot s JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text) IS NOT DISTINCT FROM '13|0 mismatches'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 16::smallint AS evidence_sequence,'M2_12_CAPABILITY_COVERAGE_ROWS'::text AS evidence_code,(((SELECT count(*)||'|'||count(*) FILTER (WHERE production_action_authorized_flag OR legal_or_regulatory_certified_flag)||' overclaims' FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text)::text AS observed_value,'20|0 overclaims'::text AS expected_value,'ROWS'::text AS unit_code,'Twenty as-built/deferred/prohibited capabilities without overclaim.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||count(*) FILTER (WHERE production_action_authorized_flag OR legal_or_regulatory_certified_flag)||' overclaims' FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id))::text) IS NOT DISTINCT FROM '20|0 overclaims'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 17::smallint AS evidence_sequence,'M2_12_CANONICAL_ENTITIES'::text AS evidence_code,(((SELECT canonical_entities||'|'||canonical_families FROM tmp_reconcile_m2_12_physical))::text)::text AS observed_value,'134|9'::text AS expected_value,'ROWS'::text AS unit_code,'Exactly 134 canonical entities across nine families.'::text AS interpretation,CASE WHEN ((((SELECT canonical_entities||'|'||canonical_families FROM tmp_reconcile_m2_12_physical))::text) IS NOT DISTINCT FROM '134|9'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 18::smallint AS evidence_sequence,'M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL'::text AS evidence_code,(((SELECT sum(observed_latest_rows)||'|'||sum(observed_archive_rows) FROM tmp_src_m2_12_component_observation))::text)::text AS observed_value,'7129|7129'::text AS expected_value,'ROWS'::text AS unit_code,'Combined component latest/archive total; consolidates the former two evidence slots.'::text AS interpretation,CASE WHEN ((((SELECT sum(observed_latest_rows)||'|'||sum(observed_archive_rows) FROM tmp_src_m2_12_component_observation))::text) IS NOT DISTINCT FROM '7129|7129'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 19::smallint AS evidence_sequence,'M2_12_APPLICATION_CONSUMPTION_ROWS'::text AS evidence_code,(((SELECT count(*)||'|'||count(DISTINCT merchant_application_id)||'|'||count(*) FILTER (WHERE scenario_code='BASELINE')||'|'||count(*) FILTER (WHERE scenario_code='RECESSION_ENERGY') FROM msbf_m2.v_m2_12_application_origination_consumption))::text)::text AS observed_value,'1500|750|750|750'::text AS expected_value,'ROWS'::text AS unit_code,'Application view has exact scenario/application grain.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||count(DISTINCT merchant_application_id)||'|'||count(*) FILTER (WHERE scenario_code='BASELINE')||'|'||count(*) FILTER (WHERE scenario_code='RECESSION_ENERGY') FROM msbf_m2.v_m2_12_application_origination_consumption))::text) IS NOT DISTINCT FROM '1500|750|750|750'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 20::smallint AS evidence_sequence,'M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS'::text AS evidence_code,(((SELECT count(*)||'|'||count(DISTINCT merchant_application_id)||'|'||count(*) FILTER (WHERE scenario_code='BASELINE')||'|'||count(*) FILTER (WHERE scenario_code='RECESSION_ENERGY') FROM msbf_m2.v_m2_12_operational_account_consumption))::text)::text AS observed_value,'59|44|44|15'::text AS expected_value,'ROWS'::text AS unit_code,'Operational-account view has exact accepted account grain.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||count(DISTINCT merchant_application_id)||'|'||count(*) FILTER (WHERE scenario_code='BASELINE')||'|'||count(*) FILTER (WHERE scenario_code='RECESSION_ENERGY') FROM msbf_m2.v_m2_12_operational_account_consumption))::text) IS NOT DISTINCT FROM '59|44|44|15'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 21::smallint AS evidence_sequence,'M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS'::text AS evidence_code,(((SELECT count(*)||'|'||count(DISTINCT strategy_profile_code)||'|'||count(DISTINCT reporting_scope_code)||'|'||count(*) FILTER (WHERE governance_priority_code='PRIMARY_GOVERNANCE_REVIEW') FROM msbf_m2.v_m2_12_strategy_scope_consumption))::text)::text AS observed_value,'24|8|3|3'::text AS expected_value,'ROWS'::text AS unit_code,'Strategy-scope view preserves eight strategies and three scopes.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||count(DISTINCT strategy_profile_code)||'|'||count(DISTINCT reporting_scope_code)||'|'||count(*) FILTER (WHERE governance_priority_code='PRIMARY_GOVERNANCE_REVIEW') FROM msbf_m2.v_m2_12_strategy_scope_consumption))::text) IS NOT DISTINCT FROM '24|8|3|3'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 22::smallint AS evidence_sequence,'M2_12_SOURCE_GRAPH_EDGES'::text AS evidence_code,(((SELECT count(*)||'|'||count(*) FILTER (WHERE edge_status<>'PASS') FROM tmp_cert_m2_12_source_edge_observation))::text)::text AS observed_value,'19|0'::text AS expected_value,'ROWS'::text AS unit_code,'Ten linear Module 2, two M1 auxiliary, two M1.17 component, and five M2.11 direct-source edges.'::text AS interpretation,CASE WHEN ((((SELECT count(*)||'|'||count(*) FILTER (WHERE edge_status<>'PASS') FROM tmp_cert_m2_12_source_edge_observation))::text) IS NOT DISTINCT FROM '19|0'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 23::smallint AS evidence_sequence,'M2_12_DETERMINISTIC_MISMATCHES'::text AS evidence_code,(((SELECT total_mismatch_count FROM tmp_reconcile_m2_12_physical))::text)::text AS observed_value,'0'::text AS expected_value,'ROWS'::text AS unit_code,'No deterministic row, set, contract, or combined-hash mismatch.'::text AS interpretation,CASE WHEN ((((SELECT total_mismatch_count FROM tmp_reconcile_m2_12_physical))::text) IS NOT DISTINCT FROM '0'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
UNION ALL
(SELECT 24::smallint AS evidence_sequence,'M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS'::text AS evidence_code,(((SELECT count(*) FROM tmp_cert_m2_12_stage_boundary_observation WHERE certification_status<>'PASS'))::text)::text AS observed_value,'0'::text AS expected_value,'ROWS'::text AS unit_code,'No production action, capability overclaim, unauthorized source, premature Module 3 object, or stage-boundary finding.'::text AS interpretation,CASE WHEN ((((SELECT count(*) FROM tmp_cert_m2_12_stage_boundary_observation WHERE certification_status<>'PASS'))::text) IS NOT DISTINCT FROM '0'::text) THEN 'PASS'::text ELSE 'FAIL'::text END AS status FROM tmp_src_m2_12_run_context ctx)
)
SELECT
    g.evidence_sequence::smallint AS evidence_sequence,
    g.evidence_code::text AS evidence_code,
    g.observed_value::text AS observed_value,
    g.expected_value::text AS expected_value,
    g.unit_code::text AS unit_code,
    g.interpretation::text AS interpretation,
    g.status::text AS status
FROM generation_rows g;

/* R10 GOVERNED STATEMENT 0196 OF 0206
   statement_code: ASSERT_TMP_GENERATION_M2_12_EVIDENCE
   phase_code: 10_EVIDENCE
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R10
*/
DO $m212_hf8_generation_evidence_assert$
BEGIN
    IF NOT coalesce(
        (SELECT count(*)=24
             AND count(DISTINCT evidence_sequence)=24
             AND count(DISTINCT evidence_code)=24
             AND min(evidence_sequence)=1
             AND max(evidence_sequence)=24
             AND bool_and(status='PASS')
         FROM tmp_generation_m2_12_evidence),false)
    THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P222 HF9 generation-evidence certification mismatch',
            DETAIL=coalesce(
                (SELECT string_agg('evidence='||evidence_sequence::text||':'||evidence_code||
                                   '|status='||coalesce(status,'<NULL>')||
                                   '|observed='||coalesce(observed_value,'<NULL>')||
                                   '|expected='||coalesce(expected_value,'<NULL>'),
                                   '; ' ORDER BY evidence_sequence)
                   FROM tmp_generation_m2_12_evidence
                  WHERE status IS DISTINCT FROM 'PASS'),
                format('rows=%s|distinct_sequences=%s|distinct_codes=%s|min=%s|max=%s',
                       (SELECT count(*) FROM tmp_generation_m2_12_evidence),
                       (SELECT count(DISTINCT evidence_sequence) FROM tmp_generation_m2_12_evidence),
                       (SELECT count(DISTINCT evidence_code) FROM tmp_generation_m2_12_evidence),
                       (SELECT min(evidence_sequence) FROM tmp_generation_m2_12_evidence),
                       (SELECT max(evidence_sequence) FROM tmp_generation_m2_12_evidence)));
    END IF;
END;
$m212_hf8_generation_evidence_assert$;

/* R10 GOVERNED STATEMENT 0197 OF 0206
   statement_code: INDEX_TMP_GENERATION_M2_12_EVIDENCE
   phase_code: 10_EVIDENCE
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_generation_m2_12_evidence_ffc1b632 ON tmp_generation_m2_12_evidence (evidence_sequence);

/* R10 GOVERNED STATEMENT 0198 OF 0206
   statement_code: ANALYZE_TMP_GENERATION_M2_12_EVIDENCE
   phase_code: 10_EVIDENCE
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_generation_m2_12_evidence;

/* R10 GOVERNED STATEMENT 0199 OF 0206
   statement_code: INSERT_24_RUN_EVIDENCE
   phase_code: 10_EVIDENCE
   statement_type: PERSISTENT_INSERT
   source_authority: M2_12_PROGRAM_222_RUN_EVIDENCE_INSERT_STATEMENT.md
*/
INSERT INTO msbf_ctl.run_evidence
(
    run_id,evidence_code,segment_key,metric_name,
    metric_value_numeric,metric_value_text,unit_code,status,
    threshold_value_numeric,interpretation
)
SELECT ctx.module1_run_id,ge.evidence_code,'M2_12'::text,ge.evidence_code,
       NULL::numeric(24,10),ge.observed_value,ge.unit_code,ge.status,
       NULL::numeric(24,10),ge.interpretation
FROM tmp_generation_m2_12_evidence ge
CROSS JOIN tmp_src_m2_12_run_context ctx
WHERE ge.status='PASS'
ORDER BY ge.evidence_sequence;

/* R10 GOVERNED STATEMENT 0200 OF 0206
   statement_code: UPDATE_RUN_STATUS
   phase_code: 11_LIFECYCLE
   statement_type: PERSISTENT_UPDATE
   source_authority: M2_12_PROGRAM_222_LIFECYCLE_TRANSITION_SPECIFICATION.csv
*/
DO $m212_r8_p222_lifecycle$
DECLARE
    v_affected_rows bigint;
BEGIN
    UPDATE msbf_ctl.run_registry rr
       SET run_status='M2_12_GENERATED'
      FROM tmp_src_m2_12_run_context ctx
     WHERE rr.run_id=ctx.module1_run_id
       AND rr.run_code='M1_V0_2_BASELINE_BUILD'
       AND rr.run_version=1
       AND rr.run_status='M2_11_ACCEPTED';
    GET DIAGNOSTICS v_affected_rows = ROW_COUNT;
    IF v_affected_rows <> 1 THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 222 lifecycle update affected an unexpected row count', DETAIL='expected=1 observed='||v_affected_rows::text;
    END IF;
END;
$m212_r8_p222_lifecycle$;

/* R10 GOVERNED STATEMENT 0201 OF 0206
   statement_code: CREATE_TMP_GENERATION_M2_12_PERSISTENCE_RESULT
   phase_code: 12_RESULT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_PROGRAM_222_POST_UPDATE_CHECKPOINT_SPECIFICATION.csv
*/
CREATE TEMP TABLE tmp_generation_m2_12_persistence_result ON COMMIT PRESERVE ROWS AS
WITH governed_run AS (
 SELECT rr.run_id,rr.run_status FROM msbf_ctl.run_registry rr JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=rr.run_id
 WHERE rr.run_code='M1_V0_2_BASELINE_BUILD' AND rr.run_version=1
), registry_state AS (
 SELECT r.module1_run_id,r.contract_status,r.registry_id,r.combined_set_hash
 FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id
 WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
), policy_state AS (
 SELECT p.module1_run_id,p.policy_profile_id FROM msbf_ctl.m2_12_policy_profile p
 JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=p.module1_run_id
 WHERE p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND p.policy_version=1 AND p.policy_status='APPROVED'
), archive_state AS (
 SELECT a.module1_run_id,a.archive_id FROM msbf_ctl.m2_12_g3_bundle_archive a
 JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=a.module1_run_id
 WHERE a.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND a.contract_version=1
), expected_evidence AS (
    SELECT ctx.module1_run_id::bigint AS run_id,
           ge.evidence_code::text AS evidence_code,
           'M2_12'::text AS segment_key,
           ge.evidence_code::text AS metric_name,
           NULL::numeric(24,10) AS metric_value_numeric,
           ge.observed_value::text AS metric_value_text,
           ge.unit_code::text AS unit_code,
           ge.status::text AS status,
           NULL::numeric(24,10) AS threshold_value_numeric,
           ge.interpretation::text AS interpretation
    FROM tmp_generation_m2_12_evidence ge CROSS JOIN tmp_src_m2_12_run_context ctx
),
actual_evidence AS (
 SELECT e.run_id,e.evidence_code,e.segment_key,e.metric_name,e.metric_value_numeric,e.metric_value_text,e.unit_code,e.status,e.threshold_value_numeric,e.interpretation
 FROM msbf_ctl.run_evidence e JOIN tmp_src_m2_12_run_context ctx ON ctx.module1_run_id=e.run_id
 WHERE e.evidence_code LIKE 'M2_12_%'
), duplicate_keys AS (
 SELECT ((SELECT count(*) FROM (SELECT run_id,evidence_code,segment_key,count(*) FROM expected_evidence GROUP BY 1,2,3 HAVING count(*)<>1) x)
       +(SELECT count(*) FROM (SELECT run_id,evidence_code,segment_key,count(*) FROM actual_evidence GROUP BY 1,2,3 HAVING count(*)<>1) a))::integer AS n
), exact_key_parity AS (
 SELECT count(*) FILTER (WHERE a.evidence_code IS NULL)::integer AS missing_rows,
        count(*) FILTER (WHERE x.evidence_code IS NULL)::integer AS extra_rows,
        count(*) FILTER (WHERE x.evidence_code IS NOT NULL AND a.evidence_code IS NOT NULL AND (
          x.metric_name IS DISTINCT FROM a.metric_name OR x.metric_value_numeric IS DISTINCT FROM a.metric_value_numeric OR
          x.metric_value_text IS DISTINCT FROM a.metric_value_text OR x.unit_code IS DISTINCT FROM a.unit_code OR
          x.status IS DISTINCT FROM a.status OR x.threshold_value_numeric IS DISTINCT FROM a.threshold_value_numeric OR
          x.interpretation IS DISTINCT FROM a.interpretation))::integer AS field_mismatches
 FROM expected_evidence x FULL JOIN actual_evidence a USING(run_id,evidence_code,segment_key)
), seq AS (
 SELECT (SELECT last_value::text||'|'||is_called::text FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq)::text AS policy_sequence_state,
        (SELECT last_value::text||'|'||is_called::text FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq)::text AS archive_sequence_state,
        (SELECT last_value::text||'|'||is_called::text FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq)::text AS registry_sequence_state
), raw AS (
 SELECT ctx.module1_run_id::bigint AS module1_run_id,
  (SELECT count(*) FROM governed_run)::integer AS governed_run_rows,
  (SELECT min(run_status) FROM governed_run)::text AS final_run_status,
  (SELECT count(*) FROM registry_state)::integer AS g3_registry_rows,
  (SELECT min(contract_status) FROM registry_state)::text AS final_contract_status,
  (SELECT count(*) FROM actual_evidence)::integer AS generation_evidence_rows,
  d.n::integer AS generation_evidence_duplicate_keys,
  p.missing_rows::integer AS generation_evidence_missing_rows,
  p.extra_rows::integer AS generation_evidence_extra_rows,
  p.field_mismatches::integer AS generation_evidence_field_mismatches,
  rp.canonical_families::integer AS canonical_families,
  rp.canonical_entities::integer AS canonical_entities,
  rp.total_mismatch_count::bigint AS phase9_total_mismatch_count,
  seq.policy_sequence_state::text AS policy_sequence_state,
  seq.archive_sequence_state::text AS archive_sequence_state,
  seq.registry_sequence_state::text AS registry_sequence_state,
  (SELECT count(*) FROM msbf_m2.v_m2_12_application_origination_consumption v WHERE v.module1_run_id=ctx.module1_run_id)::bigint AS application_consumption_rows,
  (SELECT count(*) FROM msbf_m2.v_m2_12_operational_account_consumption v WHERE v.module1_run_id=ctx.module1_run_id)::bigint AS operational_account_rows,
  (SELECT count(*) FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=ctx.module1_run_id)::bigint AS strategy_scope_rows,
  (SELECT min(policy_profile_id) FROM policy_state)::bigint AS policy_identity,
  (SELECT min(archive_id) FROM archive_state)::bigint AS archive_identity,
  (SELECT min(registry_id) FROM registry_state)::bigint AS registry_identity,
  (seq.policy_sequence_state||';'||seq.archive_sequence_state||';'||seq.registry_sequence_state)::text AS owned_sequence_states,
  (SELECT min(combined_set_hash) FROM registry_state)::text AS combined_set_hash
 FROM tmp_src_m2_12_run_context ctx
 CROSS JOIN tmp_reconcile_m2_12_physical rp CROSS JOIN exact_key_parity p CROSS JOIN duplicate_keys d CROSS JOIN seq
)
SELECT r.module1_run_id,r.governed_run_rows,r.final_run_status,r.g3_registry_rows,r.final_contract_status,
 r.generation_evidence_rows,r.generation_evidence_duplicate_keys,r.generation_evidence_missing_rows,
 r.generation_evidence_extra_rows,r.generation_evidence_field_mismatches,r.canonical_families,r.canonical_entities,
 r.phase9_total_mismatch_count,r.policy_sequence_state,r.archive_sequence_state,r.registry_sequence_state,
 r.application_consumption_rows,r.operational_account_rows,r.strategy_scope_rows,r.policy_identity,r.archive_identity,
 r.registry_identity,r.owned_sequence_states,r.combined_set_hash,
 CASE WHEN r.governed_run_rows=1 AND r.final_run_status='M2_12_GENERATED'
       AND r.g3_registry_rows=1 AND r.final_contract_status='GENERATED'
       AND r.generation_evidence_rows=24 AND r.generation_evidence_duplicate_keys=0
       AND r.generation_evidence_missing_rows=0 AND r.generation_evidence_extra_rows=0
       AND r.generation_evidence_field_mismatches=0 AND r.phase9_total_mismatch_count=0
       AND r.canonical_families=9 AND r.canonical_entities=134
       AND r.application_consumption_rows=1500 AND r.operational_account_rows=59 AND r.strategy_scope_rows=24
       AND r.policy_identity=1 AND r.archive_identity=1 AND r.registry_identity=1
       AND r.policy_sequence_state='1|true' AND r.archive_sequence_state='1|true' AND r.registry_sequence_state='1|true'
       AND r.combined_set_hash ~ '^[0-9a-f]{32}$'
      THEN 'PASS' ELSE 'FAIL' END::text AS generation_status,
 CASE WHEN r.governed_run_rows=1 AND r.final_run_status='M2_12_GENERATED'
       AND r.g3_registry_rows=1 AND r.final_contract_status='GENERATED'
       AND r.generation_evidence_rows=24 AND r.generation_evidence_duplicate_keys=0
       AND r.generation_evidence_missing_rows=0 AND r.generation_evidence_extra_rows=0
       AND r.generation_evidence_field_mismatches=0 AND r.phase9_total_mismatch_count=0
       AND r.canonical_families=9 AND r.canonical_entities=134
       AND r.application_consumption_rows=1500 AND r.operational_account_rows=59 AND r.strategy_scope_rows=24
       AND r.policy_identity=1 AND r.archive_identity=1 AND r.registry_identity=1
       AND r.policy_sequence_state='1|true' AND r.archive_sequence_state='1|true' AND r.registry_sequence_state='1|true'
       AND r.combined_set_hash ~ '^[0-9a-f]{32}$'
      THEN 'READY_FOR_PROGRAM_223' ELSE 'BLOCKED_POST_UPDATE_CHECKPOINT' END::text AS disposition
FROM raw r;

/* R10 GOVERNED STATEMENT 0202 OF 0206
   statement_code: ASSERT_TMP_GENERATION_M2_12_PERSISTENCE_RESULT
   phase_code: 12_RESULT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_PROGRAM_222_POST_UPDATE_CHECKPOINT_SPECIFICATION.csv
*/
DO $m212_hf8_post_update_checkpoint$
BEGIN
    IF NOT coalesce(
        (SELECT count(*)=1 AND bool_and(generation_status='PASS')
         FROM tmp_generation_m2_12_persistence_result),false)
    THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 222 HF9 post-update persistent checkpoint failed',
            DETAIL=coalesce(
                (SELECT format('run_status=%s|contract_status=%s|evidence=%s|duplicates=%s|missing=%s|extra=%s|field_mismatches=%s|families=%s|entities=%s|physical_mismatches=%s|sequences=%s|consumption=%s/%s/%s|identities=%s/%s/%s|hash=%s|status=%s|disposition=%s',
                               final_run_status,final_contract_status,generation_evidence_rows,
                               generation_evidence_duplicate_keys,generation_evidence_missing_rows,
                               generation_evidence_extra_rows,generation_evidence_field_mismatches,
                               canonical_families,canonical_entities,phase9_total_mismatch_count,
                               owned_sequence_states,application_consumption_rows,operational_account_rows,
                               strategy_scope_rows,policy_identity,archive_identity,registry_identity,
                               combined_set_hash,generation_status,disposition)
                   FROM tmp_generation_m2_12_persistence_result),
                'rows='||(SELECT count(*) FROM tmp_generation_m2_12_persistence_result)::text);
    END IF;
END;
$m212_hf8_post_update_checkpoint$;

/* R10 GOVERNED STATEMENT 0203 OF 0206
   statement_code: INDEX_TMP_GENERATION_M2_12_PERSISTENCE_RESULT
   phase_code: 12_RESULT
   statement_type: TEMP_INDEX
   source_authority: M2_12_PROGRAM_222_POST_UPDATE_CHECKPOINT_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_tmp_generation_m2_12_persistence_result ON tmp_generation_m2_12_persistence_result(module1_run_id);

/* R10 GOVERNED STATEMENT 0204 OF 0206
   statement_code: ANALYZE_TMP_GENERATION_M2_12_PERSISTENCE_RESULT
   phase_code: 12_RESULT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_PROGRAM_222_POST_UPDATE_CHECKPOINT_SPECIFICATION.csv
*/
ANALYZE tmp_generation_m2_12_persistence_result;

/* R10 GOVERNED STATEMENT 0205 OF 0206
   statement_code: PRIMARY_RESULT
   phase_code: 12_RESULT
   statement_type: RESULT_SELECT
   source_authority: M2_12_PROGRAM_PRIMARY_RESULT_STATEMENT_COMPILER.csv
*/
SELECT generation_status,final_run_status,final_contract_status,canonical_families,canonical_entities,generation_evidence_rows,application_consumption_rows,operational_account_rows,strategy_scope_rows,policy_identity,archive_identity,registry_identity,owned_sequence_states,combined_set_hash,disposition FROM tmp_generation_m2_12_persistence_result;

/* R10 GOVERNED STATEMENT 0206 OF 0206
   statement_code: COMMIT
   phase_code: 13_COMMIT
   statement_type: TRANSACTION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
COMMIT;

