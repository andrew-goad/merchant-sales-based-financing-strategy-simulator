/***************************************************************************************************
M2.12 — ENTERPRISE PORTFOLIO CERTIFICATION & CONSUMPTION CONTRACT
PROGRAM 220 — Schema, Policy, Certification Structures, G3 Bundle, Triggers and Views

WORK PACKAGE
M2.12 Work Package 2 — SQL Source Correction R4

PROGRAM CLASS
NORMAL

GOVERNING IMPLEMENTATION AUTHORITY
M2_12_Build_WP1_R10.zip
SHA-256: 2e4017c80b03bf7ff691b114654beed0a63dcf677607bde11696f6b5582e6d10
M2_12_WP1_SOURCE_AUTHORITY_R10.md
M2_12_WP2_LITERAL_PROGRAM_STATEMENT_ORDER_CATALOG.csv
M2_12_WP2_LITERAL_COMPILATION_DECISION_MATRIX.csv
M2_12_WP2_SOURCE_AUTHORITY_R4.md
M2_12_WP2_SOURCE_R4_CAPABILITY_STATUS_DOMAIN_CORRECTION_R1.md

CONSTRUCTION RULE
The executable SQL below preserves the approved 473-statement order. Statements 12 and 425 are
regenerated under M2_12_WP2_SOURCE_R4_CAPABILITY_STATUS_DOMAIN_CORRECTION_R1 so the physical
capability-status CHECK and its structural postflight match the frozen ten-status capability catalog.
The other 471 governed statement literals remain byte-identical to WP2 Source R3. Surrounding
comments are non-executable traceability metadata only.

LIVE-EXECUTION HOTFIX HF1
The original WP2 Source R4 byte stream failed during controlled Program 220 execution with
SQLSTATE 42803 because seven consecutive view top-level-object postflight aggregates referenced
outer column c.oid from a correlated subquery outside an aggregate argument. HF1 rewrites only
P220_PF_0012_TOP_LEVEL_OBJECT through P220_PF_0018_TOP_LEVEL_OBJECT as a two-level catalog query:
the inner nonaggregate row query computes the temporary-dependency flag per view OID; the outer
aggregate preserves the exact count/relkind/relpersistence/no-temporary-dependency assertions.
No persistent DDL literal, policy-row literal, transaction boundary, statement identity, statement
order, expected result, recovery source, or downstream program is changed.


LIVE-EXECUTION HOTFIX HF2
HF1 resolved the prior SQLSTATE 42803 view-postflight defect, then the controlled rerun reached
P220_PF_0064_PERSISTENT_COLUMN and failed closed with SQLSTATE P0001. The physical column exists;
the postflight compared pg_catalog.format_type(...) to PostgreSQL input alias 'timestamptz'. Catalog
formatting returns the canonical display name 'timestamp with time zone'. The same latent display-name
mismatch existed in fourteen timestamp-column postflights. HF2 changes only those fourteen expected
catalog-format literals. Actual column DDL remains timestamptz; no persistent DDL, object identity,
nullability, default, policy row, transaction boundary, statement order, expected successful checkpoint,
recovery source, or downstream program is changed.


LIVE-EXECUTION HOTFIX HF3
HF2 retained the prior corrections, then the controlled rerun failed before commit with SQLSTATE 42883:
operator does not exist: name[] = text[]. PostgreSQL catalog column pg_attribute.attname has type name,
so array_agg(a.attname ...) produces name[]; the structural postflights compared or assigned those arrays
as text[]. HF3 casts a.attname to text inside all sixty-eight affected array aggregates spanning thirty-eight
governed constraint/index and persistent-view postflight blocks. The catalog assertion remains an ordered
text column-name comparison. No persistent DDL, object identity, policy row, transaction boundary, statement
order, expected successful checkpoint, recovery source, or downstream program is changed.


LIVE-EXECUTION HOTFIX HF4
HF3 retained the prior corrections, then the controlled rerun reached the first deep constraint structural
postflight and failed closed at P220_STRUCT_CONSTRAINT_PK_M212_POLICY_PROFILE. PostgreSQL 15 records an
ordinary top-level PRIMARY KEY or UNIQUE constraint with pg_constraint.connoinherit=true; a top-level
FOREIGN KEY on an ordinary non-partitioned table is likewise recorded with connoinherit=true. HF3 asserted
false for all twenty-three PRIMARY KEY, UNIQUE, and FOREIGN KEY structural blocks. HF4 corrects that one
catalog expectation in all twenty-three affected blocks. The thirty-four CHECK constraints continue to
assert connoinherit=false because their DDL does not specify NO INHERIT. An expanded review also reconciles
all fifty-seven constraints, eight standalone indexes, three identity sequences, seven views, the archive
function and trigger, the exact policy row, the primary result, and the final COMMIT. No persistent DDL,
constraint definition, index definition, view definition, policy row, transaction boundary, statement order,
expected successful checkpoint, recovery source, or downstream program is changed.

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
/* R10 GOVERNED STATEMENT 0001 OF 0473
   statement_code: BEGIN
   phase_code: 00_TRANSACTION
   statement_type: TRANSACTION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
BEGIN;

/* R10 GOVERNED STATEMENT 0002 OF 0473
   statement_code: SEARCH_PATH
   phase_code: 00_TRANSACTION
   statement_type: SESSION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
SET LOCAL search_path = msbf_ctl, msbf_m2, msbf_ref, public;

/* R10 GOVERNED STATEMENT 0003 OF 0473
   statement_code: CREATE_TMP_INSTALL_M2_12_RUN_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_install_m2_12_run_context ON COMMIT DROP AS
SELECT rr.run_id::bigint AS module1_run_id,
       rr.run_code::text AS run_code,
       rr.run_version::integer AS run_version,
       rr.run_status::text AS run_status,
       rr.as_of_date::date AS as_of_date,
       m211.contract_set_hash::text AS accepted_m2_11_contract_set_hash,
       m211.combined_set_hash::text AS accepted_m2_11_combined_set_hash,
       m211.row_hash::text AS accepted_m2_11_registry_row_hash,
       '92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc'::text AS accepted_m2_11_project_sha256
FROM msbf_ctl.run_registry rr
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry m211
  ON m211.module1_run_id=rr.run_id
 AND m211.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
 AND m211.contract_version=1
 AND m211.contract_status='ACCEPTED'
WHERE rr.run_code='M1_V0_2_BASELINE_BUILD'
  AND rr.run_version=1
  AND rr.run_status='M2_11_ACCEPTED';

/* R10 GOVERNED STATEMENT 0004 OF 0473
   statement_code: ASSERT_TMP_INSTALL_M2_12_RUN_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_install_m2_12_run_context$ BEGIN IF (SELECT count(*) FROM tmp_install_m2_12_run_context) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_install_m2_12_run_context', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_install_m2_12_run_context)::text; END IF; END; $m212_r7_tmp_install_m2_12_run_context$;

/* R10 GOVERNED STATEMENT 0005 OF 0473
   statement_code: INDEX_TMP_INSTALL_M2_12_RUN_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_install_m2_12_run_context_d3a826d6 ON tmp_install_m2_12_run_context (module1_run_id);

/* R10 GOVERNED STATEMENT 0006 OF 0473
   statement_code: ANALYZE_TMP_INSTALL_M2_12_RUN_CONTEXT
   phase_code: 01_CONTEXT
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_install_m2_12_run_context;

/* R10 GOVERNED STATEMENT 0007 OF 0473
   statement_code: P220_CREATE_TABLE_01
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE TABLE msbf_ctl.m2_12_policy_profile (
    "policy_profile_id" bigint GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME msbf_ctl.m2_12_policy_profile_policy_profile_id_seq) NOT NULL,
    "module1_run_id" bigint NOT NULL,
    "policy_code" text NOT NULL,
    "policy_version" integer NOT NULL,
    "policy_status" text NOT NULL,
    "methodology_version" text NOT NULL,
    "bundle_code" text NOT NULL,
    "bundle_version" integer NOT NULL,
    "schema_version" text NOT NULL,
    "acceptance_gate_id" text NOT NULL,
    "accepted_m2_11_project_sha256" text NOT NULL,
    "accepted_m2_11_contract_set_hash" text NOT NULL,
    "accepted_m2_11_combined_set_hash" text NOT NULL,
    "accepted_m2_11_registry_row_hash" text NOT NULL,
    "expected_source_node_rows" integer NOT NULL,
    "expected_component_contract_rows" integer NOT NULL,
    "expected_source_graph_edge_rows" integer NOT NULL,
    "expected_evidence_certification_rows" integer NOT NULL,
    "expected_contract_reproduction_rows" integer NOT NULL,
    "expected_capability_coverage_rows" integer NOT NULL,
    "expected_canonical_family_count" integer NOT NULL,
    "expected_canonical_entities" integer NOT NULL,
    "expected_application_consumption_rows" bigint NOT NULL,
    "expected_operational_account_consumption_rows" integer NOT NULL,
    "expected_strategy_scope_consumption_rows" integer NOT NULL,
    "expected_generation_evidence_rows" integer NOT NULL,
    "expected_positive_controls" integer NOT NULL,
    "expected_negative_controls" integer NOT NULL,
    "expected_acceptance_requirements" integer NOT NULL,
    "expected_detail_result_sets" integer NOT NULL,
    "synthetic_data_only_flag" boolean NOT NULL,
    "no_pii_flag" boolean NOT NULL,
    "certification_only_flag" boolean NOT NULL,
    "production_action_authorized_flag" boolean NOT NULL,
    "external_system_update_authorized_flag" boolean NOT NULL,
    "legal_or_regulatory_certified_flag" boolean NOT NULL,
    "empirical_or_causal_optimization_authorized_flag" boolean NOT NULL,
    "module3_sql_authorized_flag" boolean NOT NULL,
    "module3_execution_authorized_flag" boolean NOT NULL,
    "configuration_payload" jsonb NOT NULL,
    "configuration_hash" text NOT NULL,
    "row_hash" text NOT NULL,
    "created_at" timestamptz DEFAULT clock_timestamp() NOT NULL,
    "updated_at" timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT "pk_m212_policy_profile" PRIMARY KEY (policy_profile_id),
    CONSTRAINT "uq_m212_policy_business" UNIQUE (module1_run_id, policy_code, policy_version),
    CONSTRAINT "fk_m212_policy_run" FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT,
    CONSTRAINT "ck_m212_policy_identity" CHECK (policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND policy_version=1 AND policy_status='APPROVED' AND methodology_version='M2_12_METHOD_V1' AND bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND bundle_version=1 AND schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND acceptance_gate_id='G3_M2_CONTRACT'),
    CONSTRAINT "ck_m212_policy_counts" CHECK (expected_source_node_rows=12 AND expected_component_contract_rows=13 AND expected_source_graph_edge_rows=19 AND expected_evidence_certification_rows=72 AND expected_contract_reproduction_rows=13 AND expected_capability_coverage_rows=20 AND expected_canonical_family_count=9 AND expected_canonical_entities=134 AND expected_application_consumption_rows=1500 AND expected_operational_account_consumption_rows=59 AND expected_strategy_scope_consumption_rows=24 AND expected_generation_evidence_rows=24 AND expected_positive_controls=128 AND expected_negative_controls=20 AND expected_acceptance_requirements=48 AND expected_detail_result_sets=24),
    CONSTRAINT "ck_m212_policy_boundaries" CHECK (synthetic_data_only_flag AND no_pii_flag AND certification_only_flag AND NOT production_action_authorized_flag AND NOT external_system_update_authorized_flag AND NOT legal_or_regulatory_certified_flag AND NOT empirical_or_causal_optimization_authorized_flag AND NOT module3_sql_authorized_flag AND NOT module3_execution_authorized_flag),
    CONSTRAINT "ck_m212_policy_hashes" CHECK (accepted_m2_11_project_sha256 ~ '^[0-9a-f]{64}$' AND accepted_m2_11_contract_set_hash ~ '^[0-9a-f]{32}$' AND accepted_m2_11_combined_set_hash ~ '^[0-9a-f]{32}$' AND accepted_m2_11_registry_row_hash ~ '^[0-9a-f]{32}$' AND configuration_hash ~ '^[0-9a-f]{32}$' AND row_hash ~ '^[0-9a-f]{32}$')
);

/* R10 GOVERNED STATEMENT 0008 OF 0473
   statement_code: P220_CREATE_TABLE_02
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE TABLE msbf_m2.module2_stage_certification_snapshot (
    "module1_run_id" bigint NOT NULL,
    "certification_node_sequence" smallint NOT NULL,
    "stage_code" text NOT NULL,
    "repository_stage" text NOT NULL,
    "module_title" text NOT NULL,
    "registry_relation" text NOT NULL,
    "acceptance_gate_id" text NOT NULL,
    "acceptance_gate_review_version" integer NOT NULL,
    "acceptance_evidence_code" text NOT NULL,
    "contract_status" text NOT NULL,
    "gate_status" text NOT NULL,
    "acceptance_evidence_status" text NOT NULL,
    "historical_acceptance_method" text NOT NULL,
    "expected_canonical_entities" bigint NOT NULL,
    "observed_canonical_entities" bigint NOT NULL,
    "expected_positive_controls" integer NOT NULL,
    "observed_positive_controls" integer NOT NULL,
    "expected_negative_controls" integer NOT NULL,
    "observed_negative_controls" integer NOT NULL,
    "expected_combined_hash" text NOT NULL,
    "observed_combined_hash" text NOT NULL,
    "source_registry_row_hash" text NOT NULL,
    "required_source_edge_count" smallint NOT NULL,
    "passed_source_edge_count" smallint NOT NULL,
    "source_graph_status" text NOT NULL,
    "canonical_identity_status" text NOT NULL,
    "stage_boundary_status" text NOT NULL,
    "certification_status" text NOT NULL,
    "interpretation" text NOT NULL,
    "row_hash" text NOT NULL,
    "created_at" timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT "pk_m212_stage_cert" PRIMARY KEY (module1_run_id, certification_node_sequence, stage_code),
    CONSTRAINT "fk_m212_stage_run" FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT,
    CONSTRAINT "ck_m212_stage_seq" CHECK (certification_node_sequence BETWEEN 1 AND 12 AND acceptance_gate_review_version=1 AND required_source_edge_count>=0 AND passed_source_edge_count>=0),
    CONSTRAINT "ck_m212_stage_status" CHECK (contract_status='ACCEPTED' AND gate_status='PASS' AND acceptance_evidence_status='PASS' AND source_graph_status='PASS' AND canonical_identity_status='PASS' AND stage_boundary_status='PASS' AND certification_status='PASS'),
    CONSTRAINT "ck_m212_stage_hashes" CHECK (expected_combined_hash ~ '^[0-9a-f]{32}$' AND observed_combined_hash ~ '^[0-9a-f]{32}$' AND source_registry_row_hash ~ '^[0-9a-f]{32}$' AND row_hash ~ '^[0-9a-f]{32}$')
);

/* R10 GOVERNED STATEMENT 0009 OF 0473
   statement_code: P220_CREATE_TABLE_03
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE TABLE msbf_m2.module2_contract_component_snapshot (
    "module1_run_id" bigint NOT NULL,
    "certification_node_sequence" smallint NOT NULL,
    "stage_code" text NOT NULL,
    "repository_stage" text NOT NULL,
    "module_title" text NOT NULL,
    "component_sequence" smallint NOT NULL,
    "component_contract_code" text NOT NULL,
    "contract_version" integer NOT NULL,
    "schema_version" text NOT NULL,
    "methodology_version" text NOT NULL,
    "acceptance_gate_id" text NOT NULL,
    "registry_relation" text NOT NULL,
    "latest_relation" text NOT NULL,
    "archive_relation" text NOT NULL,
    "latest_business_grain" text NOT NULL,
    "latest_business_key_columns" jsonb NOT NULL,
    "archive_business_key_columns" jsonb NOT NULL,
    "expected_latest_rows" bigint NOT NULL,
    "observed_latest_rows" bigint NOT NULL,
    "expected_archive_rows" bigint NOT NULL,
    "observed_archive_rows" bigint NOT NULL,
    "stage_expected_canonical_entities" bigint NOT NULL,
    "expected_positive_controls" integer NOT NULL,
    "observed_positive_controls" integer NOT NULL,
    "expected_negative_controls" integer NOT NULL,
    "observed_negative_controls" integer NOT NULL,
    "expected_contract_set_hash" text NOT NULL,
    "observed_contract_set_hash" text NOT NULL,
    "expected_stage_combined_set_hash" text NOT NULL,
    "observed_stage_combined_set_hash" text NOT NULL,
    "expected_registry_row_hash" text NOT NULL,
    "observed_registry_row_hash" text NOT NULL,
    "expected_latest_set_hash" text NOT NULL,
    "observed_latest_set_hash" text NOT NULL,
    "expected_archive_set_hash" text NOT NULL,
    "observed_archive_set_hash" text NOT NULL,
    "contract_status" text NOT NULL,
    "gate_status" text NOT NULL,
    "acceptance_evidence_code" text NOT NULL,
    "acceptance_evidence_status" text NOT NULL,
    "required_source_edge_codes" text[] NOT NULL,
    "required_source_edge_count" smallint NOT NULL,
    "passed_source_edge_count" smallint NOT NULL,
    "certification_status" text NOT NULL,
    "row_hash" text NOT NULL,
    "created_at" timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT "pk_m212_component" PRIMARY KEY (module1_run_id, component_sequence, component_contract_code, contract_version),
    CONSTRAINT "fk_m212_component_run" FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT,
    CONSTRAINT "ck_m212_component_seq" CHECK (component_sequence BETWEEN 1 AND 13 AND certification_node_sequence BETWEEN 1 AND 12 AND contract_version=1),
    CONSTRAINT "ck_m212_component_counts" CHECK (expected_latest_rows>=0 AND observed_latest_rows=expected_latest_rows AND expected_archive_rows>=0 AND observed_archive_rows=expected_archive_rows AND observed_positive_controls=expected_positive_controls AND observed_negative_controls=expected_negative_controls AND passed_source_edge_count=required_source_edge_count),
    CONSTRAINT "ck_m212_component_status" CHECK (contract_status='ACCEPTED' AND gate_status='PASS' AND acceptance_evidence_status='PASS' AND certification_status='PASS'),
    CONSTRAINT "ck_m212_component_hashes" CHECK (expected_contract_set_hash=observed_contract_set_hash AND expected_stage_combined_set_hash=observed_stage_combined_set_hash AND expected_registry_row_hash=observed_registry_row_hash AND expected_latest_set_hash=observed_latest_set_hash AND expected_archive_set_hash=observed_archive_set_hash AND row_hash ~ '^[0-9a-f]{32}$')
);

/* R10 GOVERNED STATEMENT 0010 OF 0473
   statement_code: P220_CREATE_TABLE_04
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE TABLE msbf_m2.module2_evidence_certification_snapshot (
    "module1_run_id" bigint NOT NULL,
    "node_sequence" smallint NOT NULL,
    "stage_code" text NOT NULL,
    "evidence_family_sequence" smallint NOT NULL,
    "evidence_family_code" text NOT NULL,
    "applicability_code" text NOT NULL,
    "allowed_certification_status" text NOT NULL,
    "authoritative_source_locator" text NOT NULL,
    "evidence_code_or_method_pattern" text NOT NULL,
    "expected_count_or_identity" text NOT NULL,
    "observed_count_or_identity" text NOT NULL,
    "expected_status" text NOT NULL,
    "observed_status" text NOT NULL,
    "expected_hash" text,
    "observed_hash" text,
    "mismatch_count" bigint NOT NULL,
    "source_registry_row_hash" text NOT NULL,
    "source_evidence_row_hash" text,
    "certification_status" text NOT NULL,
    "interpretation" text NOT NULL,
    "row_hash" text NOT NULL,
    "created_at" timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT "pk_m212_evidence" PRIMARY KEY (module1_run_id, node_sequence, evidence_family_sequence, evidence_family_code),
    CONSTRAINT "fk_m212_evidence_run" FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT,
    CONSTRAINT "ck_m212_evidence_seq" CHECK (node_sequence BETWEEN 1 AND 12 AND evidence_family_sequence BETWEEN 1 AND 6),
    CONSTRAINT "ck_m212_evidence_mandatory" CHECK (applicability_code='MANDATORY' AND allowed_certification_status='PASS' AND expected_status='PASS' AND observed_status='PASS' AND mismatch_count=0 AND certification_status='PASS'),
    CONSTRAINT "ck_m212_evidence_hashes" CHECK (source_registry_row_hash ~ '^[0-9a-f]{32}$' AND (source_evidence_row_hash IS NULL OR source_evidence_row_hash ~ '^[0-9a-f]{32}$') AND (expected_hash='' OR expected_hash ~ '^[0-9a-f]{32}$') AND (observed_hash IS NULL OR observed_hash ~ '^[0-9a-f]{32}$') AND row_hash ~ '^[0-9a-f]{32}$')
);

/* R10 GOVERNED STATEMENT 0011 OF 0473
   statement_code: P220_CREATE_TABLE_05
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE TABLE msbf_m2.module2_contract_reproduction_snapshot (
    "module1_run_id" bigint NOT NULL,
    "component_sequence" smallint NOT NULL,
    "stage_code" text NOT NULL,
    "component_contract_code" text NOT NULL,
    "contract_version" integer NOT NULL,
    "schema_version" text NOT NULL,
    "methodology_version" text NOT NULL,
    "registry_relation" text NOT NULL,
    "latest_relation" text NOT NULL,
    "archive_relation" text NOT NULL,
    "latest_business_grain" text NOT NULL,
    "latest_business_key_columns" jsonb NOT NULL,
    "archive_business_key_columns" jsonb NOT NULL,
    "expected_latest_rows" bigint NOT NULL,
    "observed_latest_rows" bigint NOT NULL,
    "expected_archive_rows" bigint NOT NULL,
    "observed_archive_rows" bigint NOT NULL,
    "expected_latest_set_hash" text NOT NULL,
    "observed_latest_set_hash" text NOT NULL,
    "expected_archive_set_hash" text NOT NULL,
    "observed_archive_set_hash" text NOT NULL,
    "payload_mismatch_count" bigint NOT NULL,
    "missing_latest_rows" bigint NOT NULL,
    "missing_archive_rows" bigint NOT NULL,
    "latest_duplicate_key_rows" bigint NOT NULL,
    "archive_duplicate_key_rows" bigint NOT NULL,
    "archive_trigger_name" text NOT NULL,
    "archive_trigger_status" text NOT NULL,
    "reproduction_status" text NOT NULL,
    "source_registry_row_hash" text NOT NULL,
    "row_hash" text NOT NULL,
    "created_at" timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT "pk_m212_reproduction" PRIMARY KEY (module1_run_id, component_sequence, component_contract_code, contract_version),
    CONSTRAINT "fk_m212_reproduction_run" FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT,
    CONSTRAINT "ck_m212_reproduction_counts" CHECK (observed_latest_rows=expected_latest_rows AND observed_archive_rows=expected_archive_rows AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0 AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0),
    CONSTRAINT "ck_m212_reproduction_status" CHECK (archive_trigger_status='PASS' AND reproduction_status='PASS'),
    CONSTRAINT "ck_m212_reproduction_hashes" CHECK (expected_latest_set_hash=observed_latest_set_hash AND expected_archive_set_hash=observed_archive_set_hash AND source_registry_row_hash ~ '^[0-9a-f]{32}$' AND row_hash ~ '^[0-9a-f]{32}$')
);

/* R10 GOVERNED STATEMENT 0012 OF 0473
   statement_code: P220_CREATE_TABLE_06
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE TABLE msbf_m2.module2_capability_coverage_snapshot (
    "module1_run_id" bigint NOT NULL,
    "capability_sequence" smallint NOT NULL,
    "capability_code" text NOT NULL,
    "coverage_status_code" text NOT NULL,
    "certifying_stage_code" text NOT NULL,
    "claim_boundary" text NOT NULL,
    "production_action_authorized_flag" boolean NOT NULL,
    "legal_or_regulatory_certified_flag" boolean NOT NULL,
    "notes" text NOT NULL,
    "row_hash" text NOT NULL,
    "created_at" timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT "pk_m212_capability" PRIMARY KEY (module1_run_id, capability_sequence, capability_code),
    CONSTRAINT "fk_m212_capability_run" FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT,
    CONSTRAINT "ck_m212_capability_seq" CHECK (capability_sequence BETWEEN 1 AND 20),
    CONSTRAINT "ck_m212_capability_status" CHECK (coverage_status_code IN ('IMPLEMENTED_BOUNDED_SYNTHETIC','IMPLEMENTED_CERTIFIED_SYNTHETIC','IMPLEMENTED_CERTIFIED_ANALYTICS','IMPLEMENTED_CERTIFIED_COMPARATIVE','IMPLEMENTED_CERTIFIED','IMPLEMENTED_BOUNDED_RECOMMENDATION','DEFERRED_NOT_IMPLEMENTED','DEFERRED_NOT_CERTIFIED','PROHIBITED_NOT_AUTHORIZED','NOT_SUPPORTED_NOT_AUTHORIZED')),
    CONSTRAINT "ck_m212_capability_boundary" CHECK (NOT production_action_authorized_flag AND NOT legal_or_regulatory_certified_flag),
    CONSTRAINT "ck_m212_capability_hash" CHECK (row_hash ~ '^[0-9a-f]{32}$')
);

/* R10 GOVERNED STATEMENT 0013 OF 0473
   statement_code: P220_CREATE_TABLE_07
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE TABLE msbf_ctl.m2_12_g3_bundle_latest (
    "module1_run_id" bigint NOT NULL,
    "bundle_code" text NOT NULL,
    "contract_version" integer NOT NULL,
    "schema_version" text NOT NULL,
    "methodology_version" text NOT NULL,
    "acceptance_gate_id" text NOT NULL,
    "run_code" text NOT NULL,
    "run_version" integer NOT NULL,
    "as_of_date" date NOT NULL,
    "source_m1_17_bundle_code" text NOT NULL,
    "source_m1_17_bundle_version" integer NOT NULL,
    "source_m1_17_schema_version" text NOT NULL,
    "source_m1_17_combined_hash" text NOT NULL,
    "source_m1_17_registry_row_hash" text NOT NULL,
    "source_m2_11_contract_code" text NOT NULL,
    "source_m2_11_contract_version" integer NOT NULL,
    "source_m2_11_schema_version" text NOT NULL,
    "source_m2_11_methodology_version" text NOT NULL,
    "source_m2_11_contract_set_hash" text NOT NULL,
    "source_m2_11_combined_set_hash" text NOT NULL,
    "source_m2_11_registry_row_hash" text NOT NULL,
    "source_node_count" integer NOT NULL,
    "component_contract_count" integer NOT NULL,
    "source_graph_edge_count" integer NOT NULL,
    "evidence_certification_count" integer NOT NULL,
    "contract_reproduction_count" integer NOT NULL,
    "capability_coverage_count" integer NOT NULL,
    "canonical_family_count" integer NOT NULL,
    "canonical_entity_count" integer NOT NULL,
    "application_consumption_rows" bigint NOT NULL,
    "operational_account_consumption_rows" integer NOT NULL,
    "strategy_scope_consumption_rows" integer NOT NULL,
    "component_latest_rows_total" bigint NOT NULL,
    "component_archive_rows_total" bigint NOT NULL,
    "stage_local_canonical_reference_total" bigint NOT NULL,
    "all_stage_certification_pass_flag" boolean NOT NULL,
    "all_component_contract_pass_flag" boolean NOT NULL,
    "all_evidence_certification_pass_flag" boolean NOT NULL,
    "all_contract_reproduction_pass_flag" boolean NOT NULL,
    "all_capability_boundary_pass_flag" boolean NOT NULL,
    "all_source_graph_edges_pass_flag" boolean NOT NULL,
    "as_built_certification_scope_code" text NOT NULL,
    "capability_summary" jsonb NOT NULL,
    "residual_limitation_payload" jsonb NOT NULL,
    "deferred_capability_payload" jsonb NOT NULL,
    "synthetic_data_only_flag" boolean NOT NULL,
    "no_pii_flag" boolean NOT NULL,
    "certification_only_flag" boolean NOT NULL,
    "production_action_authorized_flag" boolean NOT NULL,
    "external_system_update_authorized_flag" boolean NOT NULL,
    "legal_or_regulatory_certified_flag" boolean NOT NULL,
    "empirical_or_causal_optimization_authorized_flag" boolean NOT NULL,
    "deployment_authorized_flag" boolean NOT NULL,
    "module3_execution_authorized_flag" boolean NOT NULL,
    "policy_set_hash" text NOT NULL,
    "stage_certification_set_hash" text NOT NULL,
    "contract_component_set_hash" text NOT NULL,
    "evidence_certification_set_hash" text NOT NULL,
    "contract_reproduction_set_hash" text NOT NULL,
    "capability_coverage_set_hash" text NOT NULL,
    "contract_row_hash" text NOT NULL,
    "row_hash" text NOT NULL,
    "created_at" timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT "pk_m212_g3_latest" PRIMARY KEY (module1_run_id),
    CONSTRAINT "uq_m212_g3_latest_business" UNIQUE (module1_run_id, bundle_code, contract_version),
    CONSTRAINT "fk_m212_g3_latest_run" FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT,
    CONSTRAINT "ck_m212_g3_latest_identity" CHECK (bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND contract_version=1 AND schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND methodology_version='M2_12_METHOD_V1' AND acceptance_gate_id='G3_M2_CONTRACT'),
    CONSTRAINT "ck_m212_g3_latest_counts" CHECK (source_node_count=12 AND component_contract_count=13 AND source_graph_edge_count=19 AND evidence_certification_count=72 AND contract_reproduction_count=13 AND capability_coverage_count=20 AND canonical_family_count=9 AND canonical_entity_count=134 AND application_consumption_rows=1500 AND operational_account_consumption_rows=59 AND strategy_scope_consumption_rows=24 AND component_latest_rows_total=7129 AND component_archive_rows_total=7129 AND stage_local_canonical_reference_total=70821),
    CONSTRAINT "ck_m212_g3_latest_pass" CHECK (all_stage_certification_pass_flag AND all_component_contract_pass_flag AND all_evidence_certification_pass_flag AND all_contract_reproduction_pass_flag AND all_capability_boundary_pass_flag AND all_source_graph_edges_pass_flag),
    CONSTRAINT "ck_m212_g3_latest_boundary" CHECK (synthetic_data_only_flag AND no_pii_flag AND certification_only_flag AND NOT production_action_authorized_flag AND NOT external_system_update_authorized_flag AND NOT legal_or_regulatory_certified_flag AND NOT empirical_or_causal_optimization_authorized_flag AND NOT deployment_authorized_flag AND NOT module3_execution_authorized_flag),
    CONSTRAINT "ck_m212_g3_latest_hashes" CHECK (source_m1_17_combined_hash ~ '^[0-9a-f]{32}$' AND source_m1_17_registry_row_hash ~ '^[0-9a-f]{32}$' AND source_m2_11_contract_set_hash ~ '^[0-9a-f]{32}$' AND source_m2_11_combined_set_hash ~ '^[0-9a-f]{32}$' AND source_m2_11_registry_row_hash ~ '^[0-9a-f]{32}$' AND policy_set_hash ~ '^[0-9a-f]{32}$' AND stage_certification_set_hash ~ '^[0-9a-f]{32}$' AND contract_component_set_hash ~ '^[0-9a-f]{32}$' AND evidence_certification_set_hash ~ '^[0-9a-f]{32}$' AND contract_reproduction_set_hash ~ '^[0-9a-f]{32}$' AND capability_coverage_set_hash ~ '^[0-9a-f]{32}$' AND contract_row_hash ~ '^[0-9a-f]{32}$' AND row_hash ~ '^[0-9a-f]{32}$')
);

/* R10 GOVERNED STATEMENT 0014 OF 0473
   statement_code: P220_CREATE_TABLE_08
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE TABLE msbf_ctl.m2_12_g3_bundle_archive (
    "archive_id" bigint GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq) NOT NULL,
    "module1_run_id" bigint NOT NULL,
    "bundle_code" text NOT NULL,
    "contract_version" integer NOT NULL,
    "schema_version" text NOT NULL,
    "methodology_version" text NOT NULL,
    "acceptance_gate_id" text NOT NULL,
    "source_latest_row_hash" text NOT NULL,
    "contract_row_hash" text NOT NULL,
    "contract_payload" jsonb NOT NULL,
    "archive_row_hash" text NOT NULL,
    "created_at" timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT "pk_m212_g3_archive" PRIMARY KEY (archive_id),
    CONSTRAINT "uq_m212_g3_archive_business" UNIQUE (module1_run_id, bundle_code, contract_version),
    CONSTRAINT "fk_m212_g3_archive_run" FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT,
    CONSTRAINT "ck_m212_g3_archive_identity" CHECK (bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND contract_version=1 AND schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND methodology_version='M2_12_METHOD_V1' AND acceptance_gate_id='G3_M2_CONTRACT'),
    CONSTRAINT "ck_m212_g3_archive_hashes" CHECK (source_latest_row_hash ~ '^[0-9a-f]{32}$' AND contract_row_hash ~ '^[0-9a-f]{32}$' AND archive_row_hash ~ '^[0-9a-f]{32}$')
);

/* R10 GOVERNED STATEMENT 0015 OF 0473
   statement_code: P220_CREATE_TABLE_09
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE TABLE msbf_ctl.m2_12_g3_bundle_registry (
    "registry_id" bigint GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq) NOT NULL,
    "module1_run_id" bigint NOT NULL,
    "bundle_code" text NOT NULL,
    "contract_version" integer NOT NULL,
    "schema_version" text NOT NULL,
    "methodology_version" text NOT NULL,
    "acceptance_gate_id" text NOT NULL,
    "policy_code" text NOT NULL,
    "policy_version" integer NOT NULL,
    "policy_configuration_hash" text NOT NULL,
    "accepted_m2_11_project_sha256" text NOT NULL,
    "accepted_m2_11_contract_set_hash" text NOT NULL,
    "accepted_m2_11_combined_set_hash" text NOT NULL,
    "accepted_m2_11_registry_row_hash" text NOT NULL,
    "source_node_count" integer NOT NULL,
    "component_contract_count" integer NOT NULL,
    "source_graph_edge_count" integer NOT NULL,
    "evidence_certification_count" integer NOT NULL,
    "contract_reproduction_count" integer NOT NULL,
    "capability_coverage_count" integer NOT NULL,
    "canonical_family_count" integer NOT NULL,
    "canonical_entity_count" integer NOT NULL,
    "application_consumption_rows" bigint NOT NULL,
    "operational_account_consumption_rows" integer NOT NULL,
    "strategy_scope_consumption_rows" integer NOT NULL,
    "component_latest_rows_total" bigint NOT NULL,
    "component_archive_rows_total" bigint NOT NULL,
    "stage_local_canonical_reference_total" bigint NOT NULL,
    "all_stage_certification_pass_flag" boolean NOT NULL,
    "all_component_contract_pass_flag" boolean NOT NULL,
    "all_evidence_certification_pass_flag" boolean NOT NULL,
    "all_contract_reproduction_pass_flag" boolean NOT NULL,
    "all_capability_boundary_pass_flag" boolean NOT NULL,
    "all_source_graph_edges_pass_flag" boolean NOT NULL,
    "as_built_certification_scope_code" text NOT NULL,
    "residual_limitation_payload" jsonb NOT NULL,
    "deferred_capability_payload" jsonb NOT NULL,
    "synthetic_data_only_flag" boolean NOT NULL,
    "no_pii_flag" boolean NOT NULL,
    "certification_only_flag" boolean NOT NULL,
    "production_action_authorized_flag" boolean NOT NULL,
    "external_system_update_authorized_flag" boolean NOT NULL,
    "legal_or_regulatory_certified_flag" boolean NOT NULL,
    "empirical_or_causal_optimization_authorized_flag" boolean NOT NULL,
    "deployment_authorized_flag" boolean NOT NULL,
    "module3_execution_authorized_flag" boolean NOT NULL,
    "policy_set_hash" text NOT NULL,
    "stage_certification_set_hash" text NOT NULL,
    "contract_component_set_hash" text NOT NULL,
    "evidence_certification_set_hash" text NOT NULL,
    "contract_reproduction_set_hash" text NOT NULL,
    "capability_coverage_set_hash" text NOT NULL,
    "latest_set_hash" text NOT NULL,
    "archive_set_hash" text NOT NULL,
    "registry_set_hash" text NOT NULL,
    "latest_contract_row_hash" text NOT NULL,
    "archive_contract_row_hash" text NOT NULL,
    "contract_set_hash" text NOT NULL,
    "combined_set_hash" text NOT NULL,
    "contract_status" text NOT NULL,
    "generated_at" timestamptz,
    "validated_at" timestamptz,
    "accepted_at" timestamptz,
    "row_hash" text NOT NULL,
    "created_at" timestamptz DEFAULT clock_timestamp() NOT NULL,
    "updated_at" timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT "pk_m212_g3_registry" PRIMARY KEY (registry_id),
    CONSTRAINT "uq_m212_g3_registry_business" UNIQUE (module1_run_id, bundle_code, contract_version),
    CONSTRAINT "fk_m212_g3_registry_run" FOREIGN KEY (module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT,
    CONSTRAINT "fk_m212_g3_registry_policy" FOREIGN KEY (module1_run_id, policy_code, policy_version) REFERENCES msbf_ctl.m2_12_policy_profile(module1_run_id, policy_code, policy_version) ON DELETE RESTRICT,
    CONSTRAINT "ck_m212_g3_registry_identity" CHECK (bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND contract_version=1 AND schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND methodology_version='M2_12_METHOD_V1' AND acceptance_gate_id='G3_M2_CONTRACT'),
    CONSTRAINT "ck_m212_g3_registry_counts" CHECK (source_node_count=12 AND component_contract_count=13 AND source_graph_edge_count=19 AND evidence_certification_count=72 AND contract_reproduction_count=13 AND capability_coverage_count=20 AND canonical_family_count=9 AND canonical_entity_count=134 AND application_consumption_rows=1500 AND operational_account_consumption_rows=59 AND strategy_scope_consumption_rows=24 AND component_latest_rows_total=7129 AND component_archive_rows_total=7129 AND stage_local_canonical_reference_total=70821),
    CONSTRAINT "ck_m212_g3_registry_pass" CHECK (all_stage_certification_pass_flag AND all_component_contract_pass_flag AND all_evidence_certification_pass_flag AND all_contract_reproduction_pass_flag AND all_capability_boundary_pass_flag AND all_source_graph_edges_pass_flag),
    CONSTRAINT "ck_m212_g3_registry_boundary" CHECK (synthetic_data_only_flag AND no_pii_flag AND certification_only_flag AND NOT production_action_authorized_flag AND NOT external_system_update_authorized_flag AND NOT legal_or_regulatory_certified_flag AND NOT empirical_or_causal_optimization_authorized_flag AND NOT deployment_authorized_flag AND NOT module3_execution_authorized_flag),
    CONSTRAINT "ck_m212_g3_registry_status" CHECK (contract_status IN ('GENERATING','GENERATED','VALIDATED','ACCEPTED') AND (contract_status<>'GENERATING' OR (generated_at IS NULL AND validated_at IS NULL AND accepted_at IS NULL)) AND (contract_status<>'GENERATED' OR generated_at IS NOT NULL) AND (contract_status<>'VALIDATED' OR (generated_at IS NOT NULL AND validated_at IS NOT NULL)) AND (contract_status<>'ACCEPTED' OR (generated_at IS NOT NULL AND validated_at IS NOT NULL AND accepted_at IS NOT NULL))),
    CONSTRAINT "ck_m212_g3_registry_hashes" CHECK (accepted_m2_11_project_sha256 ~ '^[0-9a-f]{64}$' AND accepted_m2_11_contract_set_hash ~ '^[0-9a-f]{32}$' AND accepted_m2_11_combined_set_hash ~ '^[0-9a-f]{32}$' AND accepted_m2_11_registry_row_hash ~ '^[0-9a-f]{32}$' AND policy_set_hash ~ '^[0-9a-f]{32}$' AND stage_certification_set_hash ~ '^[0-9a-f]{32}$' AND contract_component_set_hash ~ '^[0-9a-f]{32}$' AND evidence_certification_set_hash ~ '^[0-9a-f]{32}$' AND contract_reproduction_set_hash ~ '^[0-9a-f]{32}$' AND capability_coverage_set_hash ~ '^[0-9a-f]{32}$' AND latest_set_hash ~ '^[0-9a-f]{32}$' AND archive_set_hash ~ '^[0-9a-f]{32}$' AND registry_set_hash ~ '^[0-9a-f]{32}$' AND latest_contract_row_hash ~ '^[0-9a-f]{32}$' AND archive_contract_row_hash ~ '^[0-9a-f]{32}$' AND contract_set_hash ~ '^[0-9a-f]{32}$' AND combined_set_hash ~ '^[0-9a-f]{32}$' AND row_hash ~ '^[0-9a-f]{32}$')
);

/* R10 GOVERNED STATEMENT 0016 OF 0473
   statement_code: P220_CREATE_ARCHIVE_GUARD_FUNCTION
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE FUNCTION msbf_ctl.m2_12_reject_g3_archive_mutation()
RETURNS trigger
LANGUAGE plpgsql
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
SET search_path = pg_catalog, msbf_ctl, msbf_m2
AS $m212_archive_guard$
BEGIN
    RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'M2.12 immutable G3 archive rejects UPDATE or DELETE',
        DETAIL = format('relation=%I.%I operation=%s', TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP),
        HINT = 'Do not mutate msbf_ctl.m2_12_g3_bundle_archive; a new contract version requires a separately approved source and design freeze.';
    RETURN NULL;
END;
$m212_archive_guard$;

/* R10 GOVERNED STATEMENT 0017 OF 0473
   statement_code: P220_CREATE_INDEX_11
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE INDEX ix_m212_archive_contract ON msbf_ctl.m2_12_g3_bundle_archive (bundle_code, contract_version, module1_run_id);

/* R10 GOVERNED STATEMENT 0018 OF 0473
   statement_code: P220_CREATE_INDEX_12
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE INDEX ix_m212_latest_contract ON msbf_ctl.m2_12_g3_bundle_latest (bundle_code, contract_version, module1_run_id);

/* R10 GOVERNED STATEMENT 0019 OF 0473
   statement_code: P220_CREATE_INDEX_13
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE INDEX ix_m212_registry_status ON msbf_ctl.m2_12_g3_bundle_registry (contract_status, module1_run_id, contract_version);

/* R10 GOVERNED STATEMENT 0020 OF 0473
   statement_code: P220_CREATE_INDEX_14
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE INDEX ix_m212_capability_status ON msbf_m2.module2_capability_coverage_snapshot (module1_run_id, coverage_status_code, capability_sequence);

/* R10 GOVERNED STATEMENT 0021 OF 0473
   statement_code: P220_CREATE_INDEX_15
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE INDEX ix_m212_component_status ON msbf_m2.module2_contract_component_snapshot (module1_run_id, certification_status, component_sequence);

/* R10 GOVERNED STATEMENT 0022 OF 0473
   statement_code: P220_CREATE_INDEX_16
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE INDEX ix_m212_reproduction_status ON msbf_m2.module2_contract_reproduction_snapshot (module1_run_id, reproduction_status, component_sequence);

/* R10 GOVERNED STATEMENT 0023 OF 0473
   statement_code: P220_CREATE_INDEX_17
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE INDEX ix_m212_evidence_family ON msbf_m2.module2_evidence_certification_snapshot (module1_run_id, evidence_family_code, certification_status, node_sequence);

/* R10 GOVERNED STATEMENT 0024 OF 0473
   statement_code: P220_CREATE_INDEX_18
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE INDEX ix_m212_stage_status ON msbf_m2.module2_stage_certification_snapshot (module1_run_id, certification_status, certification_node_sequence);

/* R10 GOVERNED STATEMENT 0025 OF 0473
   statement_code: P220_CREATE_ARCHIVE_GUARD_TRIGGER
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE TRIGGER trg_m2_12_g3_archive_immutable
BEFORE UPDATE OR DELETE ON msbf_ctl.m2_12_g3_bundle_archive
FOR EACH ROW
EXECUTE FUNCTION msbf_ctl.m2_12_reject_g3_archive_mutation();

/* R10 GOVERNED STATEMENT 0026 OF 0473
   statement_code: P220_CREATE_VIEW_20
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE OR REPLACE VIEW msbf_m2.v_m2_12_application_origination_consumption AS
SELECT
    CAST(g2.module1_run_id AS bigint) AS "module1_run_id",
    CAST(g2.scenario_id AS bigint) AS "scenario_id",
    CAST(g2.scenario_code AS text) AS "scenario_code",
    CAST(g2.merchant_application_id AS text) AS "merchant_application_id",
    CAST(g2.population_id AS text) AS "population_id",
    CAST(g2.merchant_id AS text) AS "merchant_id",
    CAST(g2.as_of_date AS date) AS "as_of_date",
    CAST(g2.industry_code AS text) AS "industry_code",
    CAST(g2.merchant_size_tier AS text) AS "merchant_size_tier",
    CAST(g2.relationship_stage AS text) AS "relationship_stage",
    CAST(g2.partner_channel_id AS text) AS "partner_channel_id",
    CAST(g2.channel_type AS text) AS "channel_type",
    CAST(g2.source_confidence_score AS numeric(9,6)) AS "source_confidence_score",
    CAST(g2.data_confidence_tier AS text) AS "data_confidence_tier",
    CAST(g2.verification_disposition AS text) AS "verification_disposition",
    CAST(g2.fraud_risk_tier AS smallint) AS "fraud_risk_tier",
    CAST(g2.processor_continuity_status AS text) AS "processor_continuity_status",
    CAST(g2.avg_daily_eligible_sales_30d AS numeric(18,2)) AS "avg_daily_eligible_sales_30d",
    CAST(g2.average_available_balance_30d AS numeric(18,2)) AS "average_available_balance_30d",
    CAST(g2.capacity_tier AS smallint) AS "capacity_tier",
    CAST(g2.affordability_status AS text) AS "affordability_status",
    CAST(g2.archetype_code AS text) AS "archetype_code",
    CAST(g2.operating_resilience_score AS numeric(12,6)) AS "operating_resilience_score",
    CAST(g2.resilience_tier AS smallint) AS "resilience_tier",
    CAST(g2.integrated_risk_score AS numeric(12,6)) AS "integrated_risk_score",
    CAST(g2.synthetic_merchant_risk_proxy AS numeric(12,8)) AS "synthetic_merchant_risk_proxy",
    CAST(g2.integrated_risk_tier AS smallint) AS "integrated_risk_tier",
    CAST(g2.path_weighted_ead_amount AS numeric(18,2)) AS "path_weighted_ead_amount",
    CAST(g2.lgd_input_rate AS numeric(12,8)) AS "lgd_input_rate",
    CAST(g2.schedule_adjusted_comparative_expected_loss_amount AS numeric(18,2)) AS "schedule_adjusted_comparative_expected_loss_amount",
    CAST(g2.risk_adjusted_contribution_amount AS numeric(18,2)) AS "risk_adjusted_contribution_amount",
    CAST(g2.annualized_risk_adjusted_return_rate AS numeric(12,8)) AS "annualized_risk_adjusted_return_rate",
    CAST(g2.economic_tier AS smallint) AS "economic_tier",
    CAST(g2.economic_status AS text) AS "economic_status",
    CAST(g2.hard_stop_recommended_flag AS boolean) AS "hard_stop_recommended_flag",
    CAST(g2.manual_review_recommended_flag AS boolean) AS "manual_review_recommended_flag",
    CAST(g2.m1_15_contract_evidence_status AS text) AS "m1_15_contract_evidence_status",
    CAST(g2.m1_15_contract_row_hash AS text) AS "m1_15_contract_row_hash",
    CAST(g2.primary_source_code AS text) AS "primary_source_code",
    CAST(g2.primary_campaign_id AS text) AS "primary_campaign_id",
    CAST(g2.attribution_confidence_score AS numeric(9,6)) AS "attribution_confidence_score",
    CAST(g2.attribution_confidence_tier AS text) AS "attribution_confidence_tier",
    CAST(g2.touchpoint_count AS smallint) AS "touchpoint_count",
    CAST(g2.assisted_touch_count AS smallint) AS "assisted_touch_count",
    CAST(g2.attribution_evidence_status AS text) AS "attribution_evidence_status",
    CAST(g2.direct_attributable_incurred_cost_amount AS numeric(18,2)) AS "direct_attributable_incurred_cost_amount",
    CAST(g2.internally_allocated_acquisition_cost_amount AS numeric(18,2)) AS "internally_allocated_acquisition_cost_amount",
    CAST(g2.total_incurred_pre_application_cost_amount AS numeric(18,2)) AS "total_incurred_pre_application_cost_amount",
    CAST(g2.detailed_conditional_partner_broker_cost_amount AS numeric(18,2)) AS "detailed_conditional_partner_broker_cost_amount",
    CAST(g2.detailed_total_acquisition_cost_if_booked AS numeric(18,2)) AS "detailed_total_acquisition_cost_if_booked",
    CAST(g2.accepted_m1_14_acquisition_cost_amount AS numeric(18,2)) AS "accepted_m1_14_acquisition_cost_amount",
    CAST(g2.identified_legacy_overlap_amount AS numeric(18,2)) AS "identified_legacy_overlap_amount",
    CAST(g2.unmapped_legacy_proxy_amount AS numeric(18,2)) AS "unmapped_legacy_proxy_amount",
    CAST(g2.incremental_acquisition_cost_beyond_m1_14 AS numeric(18,2)) AS "incremental_acquisition_cost_beyond_m1_14",
    CAST(g2.enhanced_total_acquisition_cost_if_booked AS numeric(18,2)) AS "enhanced_total_acquisition_cost_if_booked",
    CAST(g2.cost_evidence_status AS text) AS "cost_evidence_status",
    CAST(g2.overlap_evidence_status AS text) AS "overlap_evidence_status",
    CAST(g2.acquisition_contract_evidence_status AS text) AS "acquisition_contract_evidence_status",
    CAST(g2.m1_16_contract_row_hash AS text) AS "m1_16_contract_row_hash",
    CAST(app.application_date AS date) AS "application_date",
    CAST(app.processor_account_id AS text) AS "processor_account_id",
    CAST(app.application_status AS text) AS "m1_3_application_status",
    CAST(app.request_hash AS text) AS "m1_3_request_hash",
    CAST(m21.contract_code AS text) AS "m2_1_contract_code",
    CAST(m21.contract_version AS integer) AS "m2_1_contract_version",
    CAST(m21.schema_version AS text) AS "m2_1_schema_version",
    CAST(m21.methodology_version AS text) AS "m2_1_methodology_version",
    CAST(m21.strategy_campaign_code AS text) AS "m2_1_strategy_campaign_code",
    CAST(m21.strategy_campaign_version AS integer) AS "m2_1_strategy_campaign_version",
    CAST(m21.final_route_code AS text) AS "m2_1_final_route_code",
    CAST(m21.final_route_rank AS integer) AS "m2_1_final_route_rank",
    CAST(m21.independent_route_code AS text) AS "m2_1_independent_route_code",
    CAST(m21.independent_route_rank AS integer) AS "m2_1_independent_route_rank",
    CAST(m21.baseline_route_code AS text) AS "m2_1_baseline_route_code",
    CAST(m21.baseline_route_rank AS integer) AS "m2_1_baseline_route_rank",
    CAST(m21.eligible_for_offer_design_flag AS boolean) AS "m2_1_eligible_for_offer_design_flag",
    CAST(m21.hard_stop_flag AS boolean) AS "m2_1_hard_stop_flag",
    CAST(m21.stress_floor_applied_flag AS boolean) AS "m2_1_stress_floor_applied_flag",
    CAST(m21.stress_worsening_flag AS boolean) AS "m2_1_stress_worsening_flag",
    CAST(m21.pass_gate_count AS integer) AS "m2_1_pass_gate_count",
    CAST(m21.review_gate_count AS integer) AS "m2_1_review_gate_count",
    CAST(m21.blocked_gate_count AS integer) AS "m2_1_blocked_gate_count",
    CAST(m21.fail_gate_count AS integer) AS "m2_1_fail_gate_count",
    CAST(m21.primary_reason_code AS text) AS "m2_1_primary_reason_code",
    CAST(m21.secondary_reason_code AS text) AS "m2_1_secondary_reason_code",
    CAST(m21.tertiary_reason_code AS text) AS "m2_1_tertiary_reason_code",
    CAST(m21.reason_codes AS jsonb) AS "m2_1_reason_codes",
    CAST(m21.routing_evidence_status AS text) AS "m2_1_routing_evidence_status",
    CAST(m21.source_m1_15_contract_row_hash AS text) AS "m2_1_source_m1_15_contract_row_hash",
    CAST(m21.source_m1_16_contract_row_hash AS text) AS "m2_1_source_m1_16_contract_row_hash",
    CAST(m21.source_g2_combined_hash AS text) AS "m2_1_source_g2_combined_hash",
    CAST(m21.policy_configuration_hash AS text) AS "m2_1_policy_configuration_hash",
    CAST(m21.contract_row_hash AS text) AS "m2_1_contract_row_hash",
    CAST(m22r.contract_code AS text) AS "m2_2_request_contract_code",
    CAST(m22r.contract_version AS integer) AS "m2_2_request_contract_version",
    CAST(m22r.schema_version AS text) AS "m2_2_request_schema_version",
    CAST(m22r.methodology_version AS text) AS "m2_2_request_methodology_version",
    CAST(m22r.requested_funding_amount AS numeric(18,2)) AS "m2_2_request_requested_funding_amount",
    CAST(m22r.requested_remittance_rate AS numeric(9,6)) AS "m2_2_request_requested_remittance_rate",
    CAST(m22r.requested_expected_payoff_days AS integer) AS "m2_2_request_requested_expected_payoff_days",
    CAST(m22r.requested_total_repayment_amount AS numeric(18,2)) AS "m2_2_request_requested_total_repayment_amount",
    CAST(m22r.requested_finance_charge_amount AS numeric(18,2)) AS "m2_2_request_requested_finance_charge_amount",
    CAST(m22r.requested_payback_multiple AS numeric(9,6)) AS "m2_2_request_requested_payback_multiple",
    CAST(m22r.requested_use_of_proceeds AS text) AS "m2_2_request_requested_use_of_proceeds",
    CAST(m22r.application_channel AS text) AS "m2_2_request_application_channel",
    CAST(m22r.source_request_hash AS text) AS "m2_2_request_source_request_hash",
    CAST(m22r.source_snapshot_row_hash AS text) AS "m2_2_request_source_snapshot_row_hash",
    CAST(m22r.source_m1_3_application_hash AS text) AS "m2_2_request_source_m1_3_application_hash",
    CAST(m22r.policy_configuration_hash AS text) AS "m2_2_request_policy_configuration_hash",
    CAST(m22r.contract_row_hash AS text) AS "m2_2_request_contract_row_hash",
    CAST(m22p.contract_code AS text) AS "m2_2_pricing_contract_code",
    CAST(m22p.contract_version AS integer) AS "m2_2_pricing_contract_version",
    CAST(m22p.schema_version AS text) AS "m2_2_pricing_schema_version",
    CAST(m22p.methodology_version AS text) AS "m2_2_pricing_methodology_version",
    CAST(m22p.source_route_code AS text) AS "m2_2_pricing_source_route_code",
    CAST(m22p.source_route_rank AS integer) AS "m2_2_pricing_source_route_rank",
    CAST(m22p.pricing_disposition_code AS text) AS "m2_2_pricing_pricing_disposition_code",
    CAST(m22p.structure_available_flag AS boolean) AS "m2_2_pricing_structure_available_flag",
    CAST(m22p.review_required_flag AS boolean) AS "m2_2_pricing_review_required_flag",
    CAST(m22p.selected_candidate_template_code AS text) AS "m2_2_pricing_selected_candidate_template_code",
    CAST(m22p.selected_candidate_row_hash AS text) AS "m2_2_pricing_selected_candidate_row_hash",
    CAST(m22p.requested_funding_amount AS numeric(18,2)) AS "m2_2_pricing_requested_funding_amount",
    CAST(m22p.selected_funding_amount AS numeric(18,2)) AS "m2_2_pricing_selected_funding_amount",
    CAST(m22p.selected_remittance_rate AS numeric(9,6)) AS "m2_2_pricing_selected_remittance_rate",
    CAST(m22p.selected_payback_multiple AS numeric(9,6)) AS "m2_2_pricing_selected_payback_multiple",
    CAST(m22p.selected_collection_horizon_days AS integer) AS "m2_2_pricing_selected_collection_horizon_days",
    CAST(m22p.selected_total_repayment_amount AS numeric(18,2)) AS "m2_2_pricing_selected_total_repayment_amount",
    CAST(m22p.selected_finance_charge_amount AS numeric(18,2)) AS "m2_2_pricing_selected_finance_charge_amount",
    CAST(m22p.selected_implied_daily_collection_amount AS numeric(18,2)) AS "m2_2_pricing_selected_implied_daily_collection_amount",
    CAST(m22p.selected_implied_payoff_days AS numeric(18,4)) AS "m2_2_pricing_selected_implied_payoff_days",
    CAST(m22p.selected_amount_to_request_ratio AS numeric(12,8)) AS "m2_2_pricing_selected_amount_to_request_ratio",
    CAST(m22p.candidate_count AS integer) AS "m2_2_pricing_candidate_count",
    CAST(m22p.counteroffer_foundation_flag AS boolean) AS "m2_2_pricing_counteroffer_foundation_flag",
    CAST(m22p.stress_nonimprovement_applied_flag AS boolean) AS "m2_2_pricing_stress_nonimprovement_applied_flag",
    CAST(m22p.primary_reason_code AS text) AS "m2_2_pricing_primary_reason_code",
    CAST(m22p.reason_codes AS jsonb) AS "m2_2_pricing_reason_codes",
    CAST(m22p.routing_evidence_status AS text) AS "m2_2_pricing_routing_evidence_status",
    CAST(m22p.source_m2_1_contract_row_hash AS text) AS "m2_2_pricing_source_m2_1_contract_row_hash",
    CAST(m22p.source_request_contract_row_hash AS text) AS "m2_2_pricing_source_request_contract_row_hash",
    CAST(m22p.source_g2_combined_hash AS text) AS "m2_2_pricing_source_g2_combined_hash",
    CAST(m22p.policy_configuration_hash AS text) AS "m2_2_pricing_policy_configuration_hash",
    CAST(m22p.source_snapshot_row_hash AS text) AS "m2_2_pricing_source_snapshot_row_hash",
    CAST(m22p.contract_row_hash AS text) AS "m2_2_pricing_contract_row_hash",
    CAST(m23.contract_code AS text) AS "m2_3_contract_code",
    CAST(m23.contract_version AS integer) AS "m2_3_contract_version",
    CAST(m23.schema_version AS text) AS "m2_3_schema_version",
    CAST(m23.methodology_version AS text) AS "m2_3_methodology_version",
    CAST(m23.source_pricing_disposition_code AS text) AS "m2_3_source_pricing_disposition_code",
    CAST(m23.final_decision_outcome_code AS text) AS "m2_3_final_decision_outcome_code",
    CAST(m23.final_decision_rank AS integer) AS "m2_3_final_decision_rank",
    CAST(m23.final_offer_authorized_flag AS boolean) AS "m2_3_final_offer_authorized_flag",
    CAST(m23.counteroffer_review_required_flag AS boolean) AS "m2_3_counteroffer_review_required_flag",
    CAST(m23.decline_authorized_flag AS boolean) AS "m2_3_decline_authorized_flag",
    CAST(m23.manual_review_required_flag AS boolean) AS "m2_3_manual_review_required_flag",
    CAST(m23.final_offer_amount AS numeric(18,2)) AS "m2_3_final_offer_amount",
    CAST(m23.final_remittance_rate AS numeric(9,6)) AS "m2_3_final_remittance_rate",
    CAST(m23.final_payback_multiple AS numeric(9,6)) AS "m2_3_final_payback_multiple",
    CAST(m23.final_collection_horizon_days AS integer) AS "m2_3_final_collection_horizon_days",
    CAST(m23.final_total_repayment_amount AS numeric(18,2)) AS "m2_3_final_total_repayment_amount",
    CAST(m23.final_finance_charge_amount AS numeric(18,2)) AS "m2_3_final_finance_charge_amount",
    CAST(m23.final_implied_daily_collection_amount AS numeric(18,2)) AS "m2_3_final_implied_daily_collection_amount",
    CAST(m23.final_implied_payoff_days AS numeric(18,4)) AS "m2_3_final_implied_payoff_days",
    CAST(m23.final_offer_expiration_days AS integer) AS "m2_3_final_offer_expiration_days",
    CAST(m23.final_authorization_evidence_status AS text) AS "m2_3_final_authorization_evidence_status",
    CAST(m23.primary_decision_reason_code AS text) AS "m2_3_primary_decision_reason_code",
    CAST(m23.decision_reason_codes AS jsonb) AS "m2_3_decision_reason_codes",
    CAST(m23.source_m2_2_contract_row_hash AS text) AS "m2_3_source_m2_2_contract_row_hash",
    CAST(m23.source_request_contract_row_hash AS text) AS "m2_3_source_request_contract_row_hash",
    CAST(m23.source_g2_combined_hash AS text) AS "m2_3_source_g2_combined_hash",
    CAST(m23.source_snapshot_row_hash AS text) AS "m2_3_source_snapshot_row_hash",
    CAST(m23.snapshot_row_hash AS text) AS "m2_3_snapshot_row_hash",
    CAST(m23.policy_configuration_hash AS text) AS "m2_3_policy_configuration_hash",
    CAST(m23.contract_row_hash AS text) AS "m2_3_contract_row_hash",
    CAST(m24.contract_code AS text) AS "m2_4_contract_code",
    CAST(m24.contract_version AS integer) AS "m2_4_contract_version",
    CAST(m24.schema_version AS text) AS "m2_4_schema_version",
    CAST(m24.methodology_version AS text) AS "m2_4_methodology_version",
    CAST(m24.source_final_decision_outcome_code AS text) AS "m2_4_source_final_decision_outcome_code",
    CAST(m24.activation_outcome_code AS text) AS "m2_4_activation_outcome_code",
    CAST(m24.activation_outcome_rank AS integer) AS "m2_4_activation_outcome_rank",
    CAST(m24.booking_eligible_flag AS boolean) AS "m2_4_booking_eligible_flag",
    CAST(m24.booking_authorized_flag AS boolean) AS "m2_4_booking_authorized_flag",
    CAST(m24.funding_authorized_flag AS boolean) AS "m2_4_funding_authorized_flag",
    CAST(m24.funding_completed_flag AS boolean) AS "m2_4_funding_completed_flag",
    CAST(m24.portfolio_activated_flag AS boolean) AS "m2_4_portfolio_activated_flag",
    CAST(m24.operational_review_required_flag AS boolean) AS "m2_4_operational_review_required_flag",
    CAST(m24.synthetic_offer_acceptance_assumed_flag AS boolean) AS "m2_4_synthetic_offer_acceptance_assumed_flag",
    CAST(m24.real_funds_movement_flag AS boolean) AS "m2_4_real_funds_movement_flag",
    CAST(m24.external_notice_generation_authorized_flag AS boolean) AS "m2_4_external_notice_generation_authorized_flag",
    CAST(m24.external_notice_transmitted_flag AS boolean) AS "m2_4_external_notice_transmitted_flag",
    CAST(m24.production_adverse_action_notice_flag AS boolean) AS "m2_4_production_adverse_action_notice_flag",
    CAST(m24.synthetic_account_id AS text) AS "m2_4_synthetic_account_id",
    CAST(m24.synthetic_advance_id AS text) AS "m2_4_synthetic_advance_id",
    CAST(m24.booked_amount AS numeric(18,2)) AS "m2_4_booked_amount",
    CAST(m24.funded_amount AS numeric(18,2)) AS "m2_4_funded_amount",
    CAST(m24.activation_remittance_rate AS numeric(9,6)) AS "m2_4_activation_remittance_rate",
    CAST(m24.activation_payback_multiple AS numeric(9,6)) AS "m2_4_activation_payback_multiple",
    CAST(m24.activation_collection_horizon_days AS integer) AS "m2_4_activation_collection_horizon_days",
    CAST(m24.activation_total_repayment_amount AS numeric(18,2)) AS "m2_4_activation_total_repayment_amount",
    CAST(m24.activation_finance_charge_amount AS numeric(18,2)) AS "m2_4_activation_finance_charge_amount",
    CAST(m24.activation_implied_daily_collection_amount AS numeric(18,2)) AS "m2_4_activation_implied_daily_collection_amount",
    CAST(m24.activation_implied_payoff_days AS numeric(18,4)) AS "m2_4_activation_implied_payoff_days",
    CAST(m24.booking_date AS date) AS "m2_4_booking_date",
    CAST(m24.funding_date AS date) AS "m2_4_funding_date",
    CAST(m24.portfolio_activation_date AS date) AS "m2_4_portfolio_activation_date",
    CAST(m24.first_expected_remittance_date AS date) AS "m2_4_first_expected_remittance_date",
    CAST(m24.monitoring_start_date AS date) AS "m2_4_monitoring_start_date",
    CAST(m24.activation_evidence_status AS text) AS "m2_4_activation_evidence_status",
    CAST(m24.notice_control_code AS text) AS "m2_4_notice_control_code",
    CAST(m24.primary_activation_reason_code AS text) AS "m2_4_primary_activation_reason_code",
    CAST(m24.activation_reason_codes AS jsonb) AS "m2_4_activation_reason_codes",
    CAST(m24.source_m2_3_contract_row_hash AS text) AS "m2_4_source_m2_3_contract_row_hash",
    CAST(m24.source_m2_2_contract_row_hash AS text) AS "m2_4_source_m2_2_contract_row_hash",
    CAST(m24.source_g2_combined_hash AS text) AS "m2_4_source_g2_combined_hash",
    CAST(m24.source_snapshot_row_hash AS text) AS "m2_4_source_snapshot_row_hash",
    CAST(m24.snapshot_row_hash AS text) AS "m2_4_snapshot_row_hash",
    CAST(m24.policy_configuration_hash AS text) AS "m2_4_policy_configuration_hash",
    CAST(m24.contract_row_hash AS text) AS "m2_4_contract_row_hash",
    CAST(m21.final_route_code AS text) AS "eligibility_status",
    CAST(m22p.pricing_disposition_code AS text) AS "pricing_disposition",
    CAST(m23.final_decision_outcome_code AS text) AS "final_decision_outcome",
    CAST(m24.activation_outcome_code AS text) AS "activation_outcome",
    CAST((CASE GREATEST(
CASE COALESCE(g2.m1_15_contract_evidence_status,'BLOCKED') WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END,
CASE COALESCE(g2.acquisition_contract_evidence_status,'BLOCKED') WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END,
CASE COALESCE(m21.routing_evidence_status,'BLOCKED') WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END,
CASE COALESCE(m22p.routing_evidence_status,'BLOCKED') WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END,
CASE COALESCE(m23.final_authorization_evidence_status,'BLOCKED') WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END,
CASE COALESCE(m24.activation_evidence_status,'BLOCKED') WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END)
WHEN 1 THEN 'COMPLETE' WHEN 2 THEN 'PARTIAL' ELSE 'BLOCKED' END) AS text) AS "evidence_status"
FROM msbf_m1.v_m1_17_g2_integrated_consumption g2
LEFT JOIN msbf_m1.merchant_application app
  ON app.created_by_run_id=g2.module1_run_id AND app.merchant_application_id=g2.merchant_application_id
LEFT JOIN msbf_m2.application_eligibility_routing_latest m21
  ON m21.module1_run_id=g2.module1_run_id AND m21.scenario_id=g2.scenario_id AND m21.merchant_application_id=g2.merchant_application_id AND m21.strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE'
LEFT JOIN msbf_m2.application_request_structure_latest m22r
  ON m22r.module1_run_id=g2.module1_run_id AND m22r.merchant_application_id=g2.merchant_application_id
LEFT JOIN msbf_m2.application_pricing_structure_latest m22p
  ON m22p.module1_run_id=g2.module1_run_id AND m22p.scenario_id=g2.scenario_id AND m22p.merchant_application_id=g2.merchant_application_id
LEFT JOIN msbf_m2.application_final_offer_decision_latest m23
  ON m23.module1_run_id=g2.module1_run_id AND m23.scenario_id=g2.scenario_id AND m23.merchant_application_id=g2.merchant_application_id
LEFT JOIN msbf_m2.application_booking_funding_activation_latest m24
  ON m24.module1_run_id=g2.module1_run_id AND m24.scenario_id=g2.scenario_id AND m24.merchant_application_id=g2.merchant_application_id
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=g2.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED');

/* R10 GOVERNED STATEMENT 0027 OF 0473
   statement_code: P220_CREATE_VIEW_21
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE OR REPLACE VIEW msbf_m2.v_m2_12_operational_account_consumption AS
SELECT
    CAST(m24.module1_run_id AS bigint) AS "module1_run_id",
    CAST(m24.scenario_id AS bigint) AS "scenario_id",
    CAST(m24.scenario_code AS text) AS "scenario_code",
    CAST(m24.merchant_application_id AS text) AS "merchant_application_id",
    CAST(m24.merchant_id AS text) AS "merchant_id",
    CAST(m24.synthetic_account_id AS text) AS "synthetic_account_id",
    CAST(m24.synthetic_advance_id AS text) AS "synthetic_advance_id",
    CAST(m24.contract_code AS text) AS "m2_4_contract_code",
    CAST(m24.contract_version AS integer) AS "m2_4_contract_version",
    CAST(m24.schema_version AS text) AS "m2_4_schema_version",
    CAST(m24.methodology_version AS text) AS "m2_4_methodology_version",
    CAST(m24.population_id AS text) AS "m2_4_population_id",
    CAST(m24.as_of_date AS date) AS "m2_4_as_of_date",
    CAST(m24.source_final_decision_outcome_code AS text) AS "m2_4_source_final_decision_outcome_code",
    CAST(m24.activation_outcome_code AS text) AS "m2_4_activation_outcome_code",
    CAST(m24.activation_outcome_rank AS integer) AS "m2_4_activation_outcome_rank",
    CAST(m24.booking_eligible_flag AS boolean) AS "m2_4_booking_eligible_flag",
    CAST(m24.booking_authorized_flag AS boolean) AS "m2_4_booking_authorized_flag",
    CAST(m24.funding_authorized_flag AS boolean) AS "m2_4_funding_authorized_flag",
    CAST(m24.funding_completed_flag AS boolean) AS "m2_4_funding_completed_flag",
    CAST(m24.portfolio_activated_flag AS boolean) AS "m2_4_portfolio_activated_flag",
    CAST(m24.operational_review_required_flag AS boolean) AS "m2_4_operational_review_required_flag",
    CAST(m24.synthetic_offer_acceptance_assumed_flag AS boolean) AS "m2_4_synthetic_offer_acceptance_assumed_flag",
    CAST(m24.real_funds_movement_flag AS boolean) AS "m2_4_real_funds_movement_flag",
    CAST(m24.external_notice_generation_authorized_flag AS boolean) AS "m2_4_external_notice_generation_authorized_flag",
    CAST(m24.external_notice_transmitted_flag AS boolean) AS "m2_4_external_notice_transmitted_flag",
    CAST(m24.production_adverse_action_notice_flag AS boolean) AS "m2_4_production_adverse_action_notice_flag",
    CAST(m24.booked_amount AS numeric(18,2)) AS "m2_4_booked_amount",
    CAST(m24.funded_amount AS numeric(18,2)) AS "m2_4_funded_amount",
    CAST(m24.activation_remittance_rate AS numeric(9,6)) AS "m2_4_activation_remittance_rate",
    CAST(m24.activation_payback_multiple AS numeric(9,6)) AS "m2_4_activation_payback_multiple",
    CAST(m24.activation_collection_horizon_days AS integer) AS "m2_4_activation_collection_horizon_days",
    CAST(m24.activation_total_repayment_amount AS numeric(18,2)) AS "m2_4_activation_total_repayment_amount",
    CAST(m24.activation_finance_charge_amount AS numeric(18,2)) AS "m2_4_activation_finance_charge_amount",
    CAST(m24.activation_implied_daily_collection_amount AS numeric(18,2)) AS "m2_4_activation_implied_daily_collection_amount",
    CAST(m24.activation_implied_payoff_days AS numeric(18,4)) AS "m2_4_activation_implied_payoff_days",
    CAST(m24.booking_date AS date) AS "m2_4_booking_date",
    CAST(m24.funding_date AS date) AS "m2_4_funding_date",
    CAST(m24.portfolio_activation_date AS date) AS "m2_4_portfolio_activation_date",
    CAST(m24.first_expected_remittance_date AS date) AS "m2_4_first_expected_remittance_date",
    CAST(m24.monitoring_start_date AS date) AS "m2_4_monitoring_start_date",
    CAST(m24.activation_evidence_status AS text) AS "m2_4_activation_evidence_status",
    CAST(m24.notice_control_code AS text) AS "m2_4_notice_control_code",
    CAST(m24.primary_activation_reason_code AS text) AS "m2_4_primary_activation_reason_code",
    CAST(m24.activation_reason_codes AS jsonb) AS "m2_4_activation_reason_codes",
    CAST(m24.source_m2_3_contract_row_hash AS text) AS "m2_4_source_m2_3_contract_row_hash",
    CAST(m24.source_m2_2_contract_row_hash AS text) AS "m2_4_source_m2_2_contract_row_hash",
    CAST(m24.source_g2_combined_hash AS text) AS "m2_4_source_g2_combined_hash",
    CAST(m24.source_snapshot_row_hash AS text) AS "m2_4_source_snapshot_row_hash",
    CAST(m24.snapshot_row_hash AS text) AS "m2_4_snapshot_row_hash",
    CAST(m24.policy_configuration_hash AS text) AS "m2_4_policy_configuration_hash",
    CAST(m24.contract_row_hash AS text) AS "m2_4_contract_row_hash",
    CAST(m25.contract_code AS text) AS "m2_5_contract_code",
    CAST(m25.contract_version AS integer) AS "m2_5_contract_version",
    CAST(m25.schema_version AS text) AS "m2_5_schema_version",
    CAST(m25.methodology_version AS text) AS "m2_5_methodology_version",
    CAST(m25.monitoring_horizon_days AS integer) AS "m2_5_monitoring_horizon_days",
    CAST(m25.latest_monitoring_day_index AS integer) AS "m2_5_latest_monitoring_day_index",
    CAST(m25.latest_monitoring_date AS date) AS "m2_5_latest_monitoring_date",
    CAST(m25.latest_monitoring_status_code AS text) AS "m2_5_latest_monitoring_status_code",
    CAST(m25.latest_monitoring_status_rank AS integer) AS "m2_5_latest_monitoring_status_rank",
    CAST(m25.latest_raw_monitoring_status_code AS text) AS "m2_5_latest_raw_monitoring_status_code",
    CAST(m25.latest_raw_monitoring_status_rank AS integer) AS "m2_5_latest_raw_monitoring_status_rank",
    CAST(m25.stress_status_floor_applied_flag AS boolean) AS "m2_5_stress_status_floor_applied_flag",
    CAST(m25.paid_off_flag AS boolean) AS "m2_5_paid_off_flag",
    CAST(m25.payoff_day_index AS integer) AS "m2_5_payoff_day_index",
    CAST(m25.cumulative_remittance_amount AS numeric(18,2)) AS "m2_5_cumulative_remittance_amount",
    CAST(m25.remaining_receivable_amount AS numeric(18,2)) AS "m2_5_remaining_receivable_amount",
    CAST(m25.principal_exposure_proxy AS numeric(18,2)) AS "m2_5_principal_exposure_proxy",
    CAST(m25.unearned_finance_charge_proxy AS numeric(18,2)) AS "m2_5_unearned_finance_charge_proxy",
    CAST(m25.cumulative_expected_remittance_amount AS numeric(18,2)) AS "m2_5_cumulative_expected_remittance_amount",
    CAST(m25.cumulative_shortfall_amount AS numeric(18,2)) AS "m2_5_cumulative_shortfall_amount",
    CAST(m25.cumulative_pace_ratio AS numeric(12,8)) AS "m2_5_cumulative_pace_ratio",
    CAST(m25.trailing_7_day_remittance_amount AS numeric(18,2)) AS "m2_5_trailing_7_day_remittance_amount",
    CAST(m25.trailing_30_day_remittance_amount AS numeric(18,2)) AS "m2_5_trailing_30_day_remittance_amount",
    CAST(m25.days_since_last_positive_remittance AS integer) AS "m2_5_days_since_last_positive_remittance",
    CAST(m25.zero_sales_streak_days AS integer) AS "m2_5_zero_sales_streak_days",
    CAST(m25.current_available_balance AS numeric(18,2)) AS "m2_5_current_available_balance",
    CAST(m25.current_nsf_count AS smallint) AS "m2_5_current_nsf_count",
    CAST(m25.active_alert_count AS integer) AS "m2_5_active_alert_count",
    CAST(m25.primary_monitoring_reason_code AS text) AS "m2_5_primary_monitoring_reason_code",
    CAST(m25.alert_payload AS jsonb) AS "m2_5_alert_payload",
    CAST(m25.source_daily_row_hash AS text) AS "m2_5_source_daily_row_hash",
    CAST(m25.source_m2_4_contract_row_hash AS text) AS "m2_5_source_m2_4_contract_row_hash",
    CAST(m25.source_advance_row_hash AS text) AS "m2_5_source_advance_row_hash",
    CAST(m25.source_portfolio_row_hash AS text) AS "m2_5_source_portfolio_row_hash",
    CAST(m25.policy_configuration_hash AS text) AS "m2_5_policy_configuration_hash",
    CAST(m25.contract_row_hash AS text) AS "m2_5_contract_row_hash",
    CAST(m26.contract_code AS text) AS "m2_6_contract_code",
    CAST(m26.contract_version AS integer) AS "m2_6_contract_version",
    CAST(m26.schema_version AS text) AS "m2_6_schema_version",
    CAST(m26.methodology_version AS text) AS "m2_6_methodology_version",
    CAST(m26.strategy_outcome_code AS text) AS "m2_6_strategy_outcome_code",
    CAST(m26.strategy_outcome_rank AS integer) AS "m2_6_strategy_outcome_rank",
    CAST(m26.servicing_action_code AS text) AS "m2_6_servicing_action_code",
    CAST(m26.servicing_priority_rank AS integer) AS "m2_6_servicing_priority_rank",
    CAST(m26.servicing_queue_code AS text) AS "m2_6_servicing_queue_code",
    CAST(m26.recommended_action_flag AS boolean) AS "m2_6_recommended_action_flag",
    CAST(m26.review_required_flag AS boolean) AS "m2_6_review_required_flag",
    CAST(m26.temporary_adjustment_review_flag AS boolean) AS "m2_6_temporary_adjustment_review_flag",
    CAST(m26.workout_review_flag AS boolean) AS "m2_6_workout_review_flag",
    CAST(m26.recovery_review_flag AS boolean) AS "m2_6_recovery_review_flag",
    CAST(m26.recommended_action_exposure_amount AS numeric(18,2)) AS "m2_6_recommended_action_exposure_amount",
    CAST(m26.temporary_remittance_rate_factor AS numeric(9,6)) AS "m2_6_temporary_remittance_rate_factor",
    CAST(m26.review_remittance_rate AS numeric(9,6)) AS "m2_6_review_remittance_rate",
    CAST(m26.recommended_review_duration_days AS integer) AS "m2_6_recommended_review_duration_days",
    CAST(m26.reassessment_interval_days AS integer) AS "m2_6_reassessment_interval_days",
    CAST(m26.primary_intervention_reason_code AS text) AS "m2_6_primary_intervention_reason_code",
    CAST(m26.intervention_reason_codes AS jsonb) AS "m2_6_intervention_reason_codes",
    CAST(m26.source_m2_5_contract_row_hash AS text) AS "m2_6_source_m2_5_contract_row_hash",
    CAST(m26.source_snapshot_row_hash AS text) AS "m2_6_source_snapshot_row_hash",
    CAST(m26.strategy_snapshot_row_hash AS text) AS "m2_6_strategy_snapshot_row_hash",
    CAST(m26.policy_configuration_hash AS text) AS "m2_6_policy_configuration_hash",
    CAST(m26.contract_row_hash AS text) AS "m2_6_contract_row_hash",
    CAST(m27.contract_code AS text) AS "m2_7_contract_code",
    CAST(m27.contract_version AS integer) AS "m2_7_contract_version",
    CAST(m27.schema_version AS text) AS "m2_7_schema_version",
    CAST(m27.methodology_version AS text) AS "m2_7_methodology_version",
    CAST(m27.source_strategy_outcome_code AS text) AS "m2_7_source_strategy_outcome_code",
    CAST(m27.source_servicing_action_code AS text) AS "m2_7_source_servicing_action_code",
    CAST(m27.source_recommended_action_exposure_amount AS numeric(18,2)) AS "m2_7_source_recommended_action_exposure_amount",
    CAST(m27.operational_setup_outcome_code AS text) AS "m2_7_operational_setup_outcome_code",
    CAST(m27.operational_setup_action_code AS text) AS "m2_7_operational_setup_action_code",
    CAST(m27.operational_setup_priority_rank AS integer) AS "m2_7_operational_setup_priority_rank",
    CAST(m27.operational_setup_queue_code AS text) AS "m2_7_operational_setup_queue_code",
    CAST(m27.account_setup_status_code AS text) AS "m2_7_account_setup_status_code",
    CAST(m27.setup_authorized_flag AS boolean) AS "m2_7_setup_authorized_flag",
    CAST(m27.blueprint_created_flag AS boolean) AS "m2_7_blueprint_created_flag",
    CAST(m27.setup_review_required_flag AS boolean) AS "m2_7_setup_review_required_flag",
    CAST(m27.no_setup_required_flag AS boolean) AS "m2_7_no_setup_required_flag",
    CAST(m27.synthetic_operational_case_id AS text) AS "m2_7_synthetic_operational_case_id",
    CAST(m27.synthetic_account_setup_id AS text) AS "m2_7_synthetic_account_setup_id",
    CAST(m27.synthetic_servicing_plan_id AS text) AS "m2_7_synthetic_servicing_plan_id",
    CAST(m27.operational_activation_date AS date) AS "m2_7_operational_activation_date",
    CAST(m27.next_reassessment_date AS date) AS "m2_7_next_reassessment_date",
    CAST(m27.applied_temporary_payment_factor AS numeric(9,6)) AS "m2_7_applied_temporary_payment_factor",
    CAST(m27.applied_setup_duration_days AS integer) AS "m2_7_applied_setup_duration_days",
    CAST(m27.applied_reassessment_interval_days AS integer) AS "m2_7_applied_reassessment_interval_days",
    CAST(m27.primary_setup_reason_code AS text) AS "m2_7_primary_setup_reason_code",
    CAST(m27.setup_reason_codes AS jsonb) AS "m2_7_setup_reason_codes",
    CAST(m27.setup_parameter_payload AS jsonb) AS "m2_7_setup_parameter_payload",
    CAST(m27.source_contract_row_hash AS text) AS "m2_7_source_contract_row_hash",
    CAST(m27.source_snapshot_row_hash AS text) AS "m2_7_source_snapshot_row_hash",
    CAST(m27.activation_snapshot_row_hash AS text) AS "m2_7_activation_snapshot_row_hash",
    CAST(m27.account_setup_snapshot_row_hash AS text) AS "m2_7_account_setup_snapshot_row_hash",
    CAST(m27.policy_configuration_hash AS text) AS "m2_7_policy_configuration_hash",
    CAST(m27.contract_row_hash AS text) AS "m2_7_contract_row_hash",
    CAST(m28.contract_code AS text) AS "m2_8_contract_code",
    CAST(m28.contract_version AS integer) AS "m2_8_contract_version",
    CAST(m28.schema_version AS text) AS "m2_8_schema_version",
    CAST(m28.methodology_version AS text) AS "m2_8_methodology_version",
    CAST(m28.source_operational_setup_outcome_code AS text) AS "m2_8_source_operational_setup_outcome_code",
    CAST(m28.source_operational_setup_action_code AS text) AS "m2_8_source_operational_setup_action_code",
    CAST(m28.source_account_setup_status_code AS text) AS "m2_8_source_account_setup_status_code",
    CAST(m28.source_exposure_amount AS numeric(18,2)) AS "m2_8_source_exposure_amount",
    CAST(m28.servicing_execution_outcome_code AS text) AS "m2_8_servicing_execution_outcome_code",
    CAST(m28.servicing_execution_action_code AS text) AS "m2_8_servicing_execution_action_code",
    CAST(m28.servicing_execution_priority_rank AS integer) AS "m2_8_servicing_execution_priority_rank",
    CAST(m28.servicing_execution_queue_code AS text) AS "m2_8_servicing_execution_queue_code",
    CAST(m28.processing_authorized_flag AS boolean) AS "m2_8_processing_authorized_flag",
    CAST(m28.processing_review_required_flag AS boolean) AS "m2_8_processing_review_required_flag",
    CAST(m28.no_processing_required_flag AS boolean) AS "m2_8_no_processing_required_flag",
    CAST(m28.synthetic_servicing_execution_id AS text) AS "m2_8_synthetic_servicing_execution_id",
    CAST(m28.initial_lifecycle_state_code AS text) AS "m2_8_initial_lifecycle_state_code",
    CAST(m28.final_lifecycle_state_code AS text) AS "m2_8_final_lifecycle_state_code",
    CAST(m28.payment_event_count AS integer) AS "m2_8_payment_event_count",
    CAST(m28.settled_event_count AS integer) AS "m2_8_settled_event_count",
    CAST(m28.returned_event_count AS integer) AS "m2_8_returned_event_count",
    CAST(m28.retry_event_count AS integer) AS "m2_8_retry_event_count",
    CAST(m28.standard_daily_payment_amount AS numeric(18,2)) AS "m2_8_standard_daily_payment_amount",
    CAST(m28.temporary_daily_payment_amount AS numeric(18,2)) AS "m2_8_temporary_daily_payment_amount",
    CAST(m28.scheduled_payment_amount AS numeric(18,2)) AS "m2_8_scheduled_payment_amount",
    CAST(m28.processed_payment_amount AS numeric(18,2)) AS "m2_8_processed_payment_amount",
    CAST(m28.returned_payment_amount AS numeric(18,2)) AS "m2_8_returned_payment_amount",
    CAST(m28.retry_payment_amount AS numeric(18,2)) AS "m2_8_retry_payment_amount",
    CAST(m28.ending_simulated_exposure_amount AS numeric(18,2)) AS "m2_8_ending_simulated_exposure_amount",
    CAST(m28.primary_execution_reason_code AS text) AS "m2_8_primary_execution_reason_code",
    CAST(m28.execution_reason_codes AS jsonb) AS "m2_8_execution_reason_codes",
    CAST(m28.source_contract_row_hash AS text) AS "m2_8_source_contract_row_hash",
    CAST(m28.source_snapshot_row_hash AS text) AS "m2_8_source_snapshot_row_hash",
    CAST(m28.execution_snapshot_row_hash AS text) AS "m2_8_execution_snapshot_row_hash",
    CAST(m28.policy_configuration_hash AS text) AS "m2_8_policy_configuration_hash",
    CAST(m28.contract_row_hash AS text) AS "m2_8_contract_row_hash",
    CAST(m29.contract_code AS text) AS "m2_9_contract_code",
    CAST(m29.contract_version AS integer) AS "m2_9_contract_version",
    CAST(m29.schema_version AS text) AS "m2_9_schema_version",
    CAST(m29.methodology_version AS text) AS "m2_9_methodology_version",
    CAST(m29.source_final_lifecycle_state_code AS text) AS "m2_9_source_final_lifecycle_state_code",
    CAST(m29.source_exposure_amount AS numeric(18,2)) AS "m2_9_source_exposure_amount",
    CAST(m29.payment_event_count AS integer) AS "m2_9_payment_event_count",
    CAST(m29.settled_event_count AS integer) AS "m2_9_settled_event_count",
    CAST(m29.returned_event_count AS integer) AS "m2_9_returned_event_count",
    CAST(m29.retry_event_count AS integer) AS "m2_9_retry_event_count",
    CAST(m29.scheduled_payment_amount AS numeric(18,2)) AS "m2_9_scheduled_payment_amount",
    CAST(m29.processed_payment_amount AS numeric(18,2)) AS "m2_9_processed_payment_amount",
    CAST(m29.returned_payment_amount AS numeric(18,2)) AS "m2_9_returned_payment_amount",
    CAST(m29.retry_payment_amount AS numeric(18,2)) AS "m2_9_retry_payment_amount",
    CAST(m29.expected_net_processed_amount AS numeric(18,2)) AS "m2_9_expected_net_processed_amount",
    CAST(m29.reconciliation_variance_amount AS numeric(18,2)) AS "m2_9_reconciliation_variance_amount",
    CAST(m29.source_ending_exposure_amount AS numeric(18,2)) AS "m2_9_source_ending_exposure_amount",
    CAST(m29.expected_ending_exposure_amount AS numeric(18,2)) AS "m2_9_expected_ending_exposure_amount",
    CAST(m29.exposure_variance_amount AS numeric(18,2)) AS "m2_9_exposure_variance_amount",
    CAST(m29.exception_case_count AS integer) AS "m2_9_exception_case_count",
    CAST(m29.resolved_exception_count AS integer) AS "m2_9_resolved_exception_count",
    CAST(m29.unresolved_exception_count AS integer) AS "m2_9_unresolved_exception_count",
    CAST(m29.reconciliation_outcome_code AS text) AS "m2_9_reconciliation_outcome_code",
    CAST(m29.resolution_action_code AS text) AS "m2_9_resolution_action_code",
    CAST(m29.certified_state_code AS text) AS "m2_9_certified_state_code",
    CAST(m29.state_certified_flag AS boolean) AS "m2_9_state_certified_flag",
    CAST(m29.active_state_flag AS boolean) AS "m2_9_active_state_flag",
    CAST(m29.closed_state_flag AS boolean) AS "m2_9_closed_state_flag",
    CAST(m29.review_hold_state_flag AS boolean) AS "m2_9_review_hold_state_flag",
    CAST(m29.exception_resolved_flag AS boolean) AS "m2_9_exception_resolved_flag",
    CAST(m29.certified_exposure_amount AS numeric(18,2)) AS "m2_9_certified_exposure_amount",
    CAST(m29.certification_date AS date) AS "m2_9_certification_date",
    CAST(m29.primary_reconciliation_reason_code AS text) AS "m2_9_primary_reconciliation_reason_code",
    CAST(m29.reconciliation_reason_codes AS jsonb) AS "m2_9_reconciliation_reason_codes",
    CAST(m29.source_contract_row_hash AS text) AS "m2_9_source_contract_row_hash",
    CAST(m29.account_source_row_hash AS text) AS "m2_9_account_source_row_hash",
    CAST(m29.account_reconciliation_row_hash AS text) AS "m2_9_account_reconciliation_row_hash",
    CAST(m29.state_certification_row_hash AS text) AS "m2_9_state_certification_row_hash",
    CAST(m29.policy_configuration_hash AS text) AS "m2_9_policy_configuration_hash",
    CAST(m29.contract_row_hash AS text) AS "m2_9_contract_row_hash",
    CAST(m210.contract_code AS text) AS "m2_10_contract_code",
    CAST(m210.contract_version AS integer) AS "m2_10_contract_version",
    CAST(m210.schema_version AS text) AS "m2_10_schema_version",
    CAST(m210.methodology_version AS text) AS "m2_10_methodology_version",
    CAST(m210.source_final_lifecycle_state_code AS text) AS "m2_10_source_final_lifecycle_state_code",
    CAST(m210.certified_state_code AS text) AS "m2_10_certified_state_code",
    CAST(m210.state_certified_flag AS boolean) AS "m2_10_state_certified_flag",
    CAST(m210.performance_tier_code AS text) AS "m2_10_performance_tier_code",
    CAST(m210.servicing_queue_code AS text) AS "m2_10_servicing_queue_code",
    CAST(m210.payment_activity_flag AS boolean) AS "m2_10_payment_activity_flag",
    CAST(m210.exception_incident_flag AS boolean) AS "m2_10_exception_incident_flag",
    CAST(m210.exception_resolved_flag AS boolean) AS "m2_10_exception_resolved_flag",
    CAST(m210.payment_event_count AS integer) AS "m2_10_payment_event_count",
    CAST(m210.settled_event_count AS integer) AS "m2_10_settled_event_count",
    CAST(m210.returned_event_count AS integer) AS "m2_10_returned_event_count",
    CAST(m210.retry_event_count AS integer) AS "m2_10_retry_event_count",
    CAST(m210.exception_case_count AS integer) AS "m2_10_exception_case_count",
    CAST(m210.resolved_exception_count AS integer) AS "m2_10_resolved_exception_count",
    CAST(m210.unresolved_exception_count AS integer) AS "m2_10_unresolved_exception_count",
    CAST(m210.source_exposure_amount AS numeric(18,2)) AS "m2_10_source_exposure_amount",
    CAST(m210.certified_exposure_amount AS numeric(18,2)) AS "m2_10_certified_exposure_amount",
    CAST(m210.scheduled_payment_amount AS numeric(18,2)) AS "m2_10_scheduled_payment_amount",
    CAST(m210.processed_payment_amount AS numeric(18,2)) AS "m2_10_processed_payment_amount",
    CAST(m210.returned_payment_amount AS numeric(18,2)) AS "m2_10_returned_payment_amount",
    CAST(m210.retry_payment_amount AS numeric(18,2)) AS "m2_10_retry_payment_amount",
    CAST(m210.reconciliation_variance_amount AS numeric(18,2)) AS "m2_10_reconciliation_variance_amount",
    CAST(m210.exposure_variance_amount AS numeric(18,2)) AS "m2_10_exposure_variance_amount",
    CAST(m210.gross_collection_rate AS numeric(18,6)) AS "m2_10_gross_collection_rate",
    CAST(m210.return_rate AS numeric(18,6)) AS "m2_10_return_rate",
    CAST(m210.retry_cure_rate AS numeric(18,6)) AS "m2_10_retry_cure_rate",
    CAST(m210.exposure_retention_rate AS numeric(18,6)) AS "m2_10_exposure_retention_rate",
    CAST(m210.servicing_burden_units AS numeric(12,6)) AS "m2_10_servicing_burden_units",
    CAST(m210.primary_portfolio_reason_code AS text) AS "m2_10_primary_portfolio_reason_code",
    CAST(m210.portfolio_reason_codes AS jsonb) AS "m2_10_portfolio_reason_codes",
    CAST(m210.source_contract_row_hash AS text) AS "m2_10_source_contract_row_hash",
    CAST(m210.source_snapshot_row_hash AS text) AS "m2_10_source_snapshot_row_hash",
    CAST(m210.performance_snapshot_row_hash AS text) AS "m2_10_performance_snapshot_row_hash",
    CAST(m210.policy_configuration_hash AS text) AS "m2_10_policy_configuration_hash",
    CAST(m210.contract_row_hash AS text) AS "m2_10_contract_row_hash",
    CAST(m24.activation_outcome_code AS text) AS "activation_outcome",
    CAST(m25.latest_monitoring_status_code AS text) AS "monitoring_state",
    CAST(m26.strategy_outcome_code AS text) AS "intervention_posture",
    CAST(m27.account_setup_status_code AS text) AS "operational_setup_state",
    CAST(m28.final_lifecycle_state_code AS text) AS "lifecycle_state",
    CAST(m29.certified_state_code AS text) AS "certified_state",
    CAST(m210.performance_tier_code AS text) AS "performance_tier",
    CAST(m210.servicing_queue_code AS text) AS "servicing_queue",
    CAST(m210.certified_exposure_amount AS numeric(18,2)) AS "certified_exposure_amount",
    CAST(m210.servicing_burden_units AS numeric(18,6)) AS "servicing_burden_units"
FROM msbf_m2.application_booking_funding_activation_latest m24
LEFT JOIN msbf_m2.advance_portfolio_monitoring_latest m25
  ON m25.module1_run_id=m24.module1_run_id AND m25.scenario_id=m24.scenario_id AND m25.merchant_application_id=m24.merchant_application_id AND m25.synthetic_account_id=m24.synthetic_account_id AND m25.synthetic_advance_id=m24.synthetic_advance_id
LEFT JOIN msbf_m2.advance_intervention_strategy_latest m26
  ON m26.module1_run_id=m24.module1_run_id AND m26.scenario_id=m24.scenario_id AND m26.merchant_application_id=m24.merchant_application_id AND m26.synthetic_account_id=m24.synthetic_account_id AND m26.synthetic_advance_id=m24.synthetic_advance_id
LEFT JOIN msbf_m2.application_operational_activation_latest m27
  ON m27.module1_run_id=m24.module1_run_id AND m27.scenario_id=m24.scenario_id AND m27.merchant_application_id=m24.merchant_application_id AND m27.synthetic_account_id=m24.synthetic_account_id AND m27.synthetic_advance_id=m24.synthetic_advance_id
LEFT JOIN msbf_m2.application_servicing_execution_latest m28
  ON m28.module1_run_id=m24.module1_run_id AND m28.scenario_id=m24.scenario_id AND m28.merchant_application_id=m24.merchant_application_id AND m28.synthetic_account_id=m24.synthetic_account_id AND m28.synthetic_advance_id=m24.synthetic_advance_id
LEFT JOIN msbf_m2.application_payment_reconciliation_certification_latest m29
  ON m29.module1_run_id=m24.module1_run_id AND m29.scenario_id=m24.scenario_id AND m29.merchant_application_id=m24.merchant_application_id AND m29.synthetic_account_id=m24.synthetic_account_id AND m29.synthetic_advance_id=m24.synthetic_advance_id
LEFT JOIN msbf_m2.application_portfolio_performance_latest m210
  ON m210.module1_run_id=m24.module1_run_id AND m210.scenario_id=m24.scenario_id AND m210.merchant_application_id=m24.merchant_application_id AND m210.synthetic_account_id=m24.synthetic_account_id AND m210.synthetic_advance_id=m24.synthetic_advance_id
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=m24.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED') AND m24.portfolio_activated_flag=true AND m24.synthetic_account_id IS NOT NULL AND m24.synthetic_advance_id IS NOT NULL;

/* R10 GOVERNED STATEMENT 0028 OF 0473
   statement_code: P220_CREATE_VIEW_22
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE OR REPLACE VIEW msbf_m2.v_m2_12_strategy_scope_consumption AS
SELECT
    CAST(m211.module1_run_id AS bigint) AS "module1_run_id",
    CAST(m211.contract_code AS text) AS "contract_code",
    CAST(m211.contract_version AS integer) AS "contract_version",
    CAST(m211.schema_version AS text) AS "schema_version",
    CAST(m211.methodology_version AS text) AS "methodology_version",
    CAST(m211.strategy_profile_code AS text) AS "strategy_profile_code",
    CAST(m211.reporting_scope_code AS text) AS "reporting_scope_code",
    CAST(m211.source_m1_17_contract_code AS text) AS "source_m1_17_contract_code",
    CAST(m211.source_m1_17_contract_version AS integer) AS "source_m1_17_contract_version",
    CAST(m211.source_m1_17_schema_version AS text) AS "source_m1_17_schema_version",
    CAST(m211.source_m1_17_methodology_version AS text) AS "source_m1_17_methodology_version",
    CAST(m211.source_m1_17_combined_hash AS text) AS "source_m1_17_combined_hash",
    CAST(m211.source_m2_2_contract_code AS text) AS "source_m2_2_contract_code",
    CAST(m211.source_m2_2_contract_version AS integer) AS "source_m2_2_contract_version",
    CAST(m211.source_m2_2_schema_version AS text) AS "source_m2_2_schema_version",
    CAST(m211.source_m2_2_methodology_version AS text) AS "source_m2_2_methodology_version",
    CAST(m211.source_m2_2_combined_hash AS text) AS "source_m2_2_combined_hash",
    CAST(m211.source_m2_4_contract_code AS text) AS "source_m2_4_contract_code",
    CAST(m211.source_m2_4_contract_version AS integer) AS "source_m2_4_contract_version",
    CAST(m211.source_m2_4_schema_version AS text) AS "source_m2_4_schema_version",
    CAST(m211.source_m2_4_methodology_version AS text) AS "source_m2_4_methodology_version",
    CAST(m211.source_m2_4_combined_hash AS text) AS "source_m2_4_combined_hash",
    CAST(m211.source_m2_7_contract_code AS text) AS "source_m2_7_contract_code",
    CAST(m211.source_m2_7_contract_version AS integer) AS "source_m2_7_contract_version",
    CAST(m211.source_m2_7_schema_version AS text) AS "source_m2_7_schema_version",
    CAST(m211.source_m2_7_methodology_version AS text) AS "source_m2_7_methodology_version",
    CAST(m211.source_m2_7_combined_hash AS text) AS "source_m2_7_combined_hash",
    CAST(m211.source_m2_10_contract_code AS text) AS "source_m2_10_contract_code",
    CAST(m211.source_m2_10_contract_version AS integer) AS "source_m2_10_contract_version",
    CAST(m211.source_m2_10_schema_version AS text) AS "source_m2_10_schema_version",
    CAST(m211.source_m2_10_methodology_version AS text) AS "source_m2_10_methodology_version",
    CAST(m211.source_m2_10_combined_hash AS text) AS "source_m2_10_combined_hash",
    CAST(m211.application_rows AS bigint) AS "application_rows",
    CAST(m211.access_selected_rows AS bigint) AS "access_selected_rows",
    CAST(m211.controlled_review_rows AS bigint) AS "controlled_review_rows",
    CAST(m211.strategy_restriction_rows AS bigint) AS "strategy_restriction_rows",
    CAST(m211.no_feasible_candidate_rows AS bigint) AS "no_feasible_candidate_rows",
    CAST(m211.insufficient_evidence_rows AS bigint) AS "insufficient_evidence_rows",
    CAST(m211.policy_decline_rows AS bigint) AS "policy_decline_rows",
    CAST(m211.blocked_source_rows AS bigint) AS "blocked_source_rows",
    CAST(m211.servicing_account_rows AS bigint) AS "servicing_account_rows",
    CAST(m211.servicing_distinct_application_rows AS bigint) AS "servicing_distinct_application_rows",
    CAST(m211.hard_constraint_violation_count AS bigint) AS "hard_constraint_violation_count",
    CAST(m211.source_risk_improvement_violation_count AS bigint) AS "source_risk_improvement_violation_count",
    CAST(m211.source_return_improvement_violation_count AS bigint) AS "source_return_improvement_violation_count",
    CAST(m211.strategy_access_improvement_violation_count AS bigint) AS "strategy_access_improvement_violation_count",
    CAST(m211.strategy_feasibility_improvement_violation_count AS bigint) AS "strategy_feasibility_improvement_violation_count",
    CAST(m211.comparable_payment_burden_improvement_violation_count AS bigint) AS "comparable_payment_burden_improvement_violation_count",
    CAST(m211.comparable_servicing_burden_improvement_violation_count AS bigint) AS "comparable_servicing_burden_improvement_violation_count",
    CAST(m211.stress_improvement_violation_count AS bigint) AS "stress_improvement_violation_count",
    CAST(m211.stress_strategy_restriction_rows AS bigint) AS "stress_strategy_restriction_rows",
    CAST(m211.absolute_workload_reduction_rows AS bigint) AS "absolute_workload_reduction_rows",
    CAST(m211.access_rate AS numeric(18,10)) AS "access_rate",
    CAST(m211.selected_exposure_amount AS numeric(24,2)) AS "selected_exposure_amount",
    CAST(m211.finance_charge_amount AS numeric(24,2)) AS "finance_charge_amount",
    CAST(m211.expected_loss_amount AS numeric(24,2)) AS "expected_loss_amount",
    CAST(m211.expected_loss_density AS numeric(18,10)) AS "expected_loss_density",
    CAST(m211.risk_adjusted_contribution AS numeric(24,2)) AS "risk_adjusted_contribution",
    CAST(m211.annualized_risk_adjusted_return AS numeric(18,10)) AS "annualized_risk_adjusted_return",
    CAST(m211.servicing_burden_units AS numeric(24,6)) AS "servicing_burden_units",
    CAST(m211.payment_burden_rate AS numeric(18,10)) AS "payment_burden_rate",
    CAST(m211.scope_strategy_score AS numeric(22,12)) AS "scope_strategy_score",
    CAST(m211.governance_balance_score AS numeric(22,12)) AS "governance_balance_score",
    CAST(m211.strategy_evidence_status AS text) AS "strategy_evidence_status",
    CAST(m211.stress_nonimprovement_pass_flag AS boolean) AS "stress_nonimprovement_pass_flag",
    CAST(m211.frontier_eligible_flag AS boolean) AS "frontier_eligible_flag",
    CAST(m211.non_dominated_flag AS boolean) AS "non_dominated_flag",
    CAST(m211.frontier_rank AS integer) AS "frontier_rank",
    CAST(m211.governance_review_priority_code AS text) AS "governance_review_priority_code",
    CAST(m211.primary_governance_review_flag AS boolean) AS "primary_governance_review_flag",
    CAST(m211.servicing_burden_coverage_code AS text) AS "servicing_burden_coverage_code",
    CAST(m211.new_access_servicing_burden_estimated_flag AS boolean) AS "new_access_servicing_burden_estimated_flag",
    CAST(m211.baseline_access_rate_delta AS numeric(18,10)) AS "baseline_access_rate_delta",
    CAST(m211.baseline_selected_exposure_amount_delta AS numeric(24,2)) AS "baseline_selected_exposure_amount_delta",
    CAST(m211.baseline_finance_charge_amount_delta AS numeric(24,2)) AS "baseline_finance_charge_amount_delta",
    CAST(m211.baseline_expected_loss_density_delta AS numeric(18,10)) AS "baseline_expected_loss_density_delta",
    CAST(m211.baseline_risk_adjusted_contribution_delta AS numeric(24,2)) AS "baseline_risk_adjusted_contribution_delta",
    CAST(m211.baseline_annualized_risk_adjusted_return_delta AS numeric(18,10)) AS "baseline_annualized_risk_adjusted_return_delta",
    CAST(m211.baseline_servicing_burden_units_delta AS numeric(24,6)) AS "baseline_servicing_burden_units_delta",
    CAST(m211.baseline_payment_burden_rate_delta AS numeric(18,10)) AS "baseline_payment_burden_rate_delta",
    CAST(m211.primary_reason_code AS text) AS "primary_reason_code",
    CAST(m211.reason_codes AS jsonb) AS "reason_codes",
    CAST(m211.strategy_summary_row_hash AS text) AS "strategy_summary_row_hash",
    CAST(m211.frontier_row_hash AS text) AS "frontier_row_hash",
    CAST(m211.comparison_row_hash AS text) AS "comparison_row_hash",
    CAST(m211.contract_row_hash AS text) AS "contract_row_hash",
    CAST(g3.bundle_code AS text) AS "g3_bundle_code",
    CAST(g3.contract_version AS integer) AS "g3_contract_version",
    CAST(g3.schema_version AS text) AS "g3_schema_version",
    CAST(g3.methodology_version AS text) AS "g3_methodology_version",
    CAST(g3.acceptance_gate_id AS text) AS "g3_acceptance_gate_id",
    CAST(gr.contract_status AS text) AS "g3_contract_status",
    CAST(gr.contract_set_hash AS text) AS "g3_contract_set_hash",
    CAST(gr.combined_set_hash AS text) AS "g3_combined_set_hash",
    CAST(gr.row_hash AS text) AS "g3_registry_row_hash",
    CAST(g3.deployment_authorized_flag AS boolean) AS "deployment_authorized_flag",
    CAST(g3.module3_execution_authorized_flag AS boolean) AS "module3_execution_authorized_flag",
    CAST(m211.contract_row_hash AS text) AS "source_contract_row_hash",
    CAST(m211.application_rows AS bigint) AS "application_count",
    CAST(m211.annualized_risk_adjusted_return AS numeric(28,10)) AS "annualized_return",
    CAST((CASE WHEN m211.non_dominated_flag THEN 'NON_DOMINATED' ELSE 'DOMINATED' END) AS text) AS "dominance_status",
    CAST(m211.governance_review_priority_code AS text) AS "governance_priority_code"
FROM msbf_m2.portfolio_strategy_simulation_latest m211
LEFT JOIN msbf_ctl.m2_12_g3_bundle_latest g3
  ON g3.module1_run_id=m211.module1_run_id AND g3.contract_version=1
LEFT JOIN msbf_ctl.m2_12_g3_bundle_registry gr
  ON gr.module1_run_id=m211.module1_run_id AND gr.contract_version=g3.contract_version
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=m211.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED');

/* R10 GOVERNED STATEMENT 0029 OF 0473
   statement_code: P220_CREATE_VIEW_23
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE OR REPLACE VIEW msbf_ctl.v_m2_12_stage_lineage AS
SELECT
    CAST(s.module1_run_id AS bigint) AS "module1_run_id",
    CAST(s.certification_node_sequence AS smallint) AS "certification_node_sequence",
    CAST(s.stage_code AS text) AS "stage_code",
    CAST(s.repository_stage AS text) AS "repository_stage",
    CAST(s.module_title AS text) AS "module_title",
    CAST(s.registry_relation AS text) AS "registry_relation",
    CAST(s.acceptance_gate_id AS text) AS "acceptance_gate_id",
    CAST(s.acceptance_gate_review_version AS integer) AS "acceptance_gate_review_version",
    CAST(s.acceptance_evidence_code AS text) AS "acceptance_evidence_code",
    CAST(s.contract_status AS text) AS "contract_status",
    CAST(s.gate_status AS text) AS "gate_status",
    CAST(s.acceptance_evidence_status AS text) AS "acceptance_evidence_status",
    CAST(s.historical_acceptance_method AS text) AS "historical_acceptance_method",
    CAST(s.expected_canonical_entities AS bigint) AS "expected_canonical_entities",
    CAST(s.observed_canonical_entities AS bigint) AS "observed_canonical_entities",
    CAST(s.expected_positive_controls AS integer) AS "expected_positive_controls",
    CAST(s.observed_positive_controls AS integer) AS "observed_positive_controls",
    CAST(s.expected_negative_controls AS integer) AS "expected_negative_controls",
    CAST(s.observed_negative_controls AS integer) AS "observed_negative_controls",
    CAST(s.expected_combined_hash AS text) AS "expected_combined_hash",
    CAST(s.observed_combined_hash AS text) AS "observed_combined_hash",
    CAST(s.source_registry_row_hash AS text) AS "source_registry_row_hash",
    CAST(s.required_source_edge_count AS smallint) AS "required_source_edge_count",
    CAST(s.passed_source_edge_count AS smallint) AS "passed_source_edge_count",
    CAST(s.source_graph_status AS text) AS "source_graph_status",
    CAST(s.canonical_identity_status AS text) AS "canonical_identity_status",
    CAST(s.stage_boundary_status AS text) AS "stage_boundary_status",
    CAST(s.certification_status AS text) AS "certification_status",
    CAST(s.interpretation AS text) AS "interpretation",
    CAST(s.row_hash AS text) AS "row_hash",
    CAST(r.bundle_code AS text) AS "g3_bundle_code",
    CAST(r.contract_version AS integer) AS "g3_contract_version",
    CAST(r.contract_status AS text) AS "g3_contract_status",
    CAST(r.combined_set_hash AS text) AS "g3_combined_set_hash"
FROM msbf_m2.module2_stage_certification_snapshot s
LEFT JOIN msbf_ctl.m2_12_g3_bundle_registry r
  ON r.module1_run_id=s.module1_run_id AND r.contract_version=1
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=s.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED');

/* R10 GOVERNED STATEMENT 0030 OF 0473
   statement_code: P220_CREATE_VIEW_24
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE OR REPLACE VIEW msbf_ctl.v_m2_12_component_contract_lineage AS
SELECT
    CAST(c.module1_run_id AS bigint) AS "module1_run_id",
    CAST(c.certification_node_sequence AS smallint) AS "certification_node_sequence",
    CAST(c.stage_code AS text) AS "stage_code",
    CAST(c.repository_stage AS text) AS "repository_stage",
    CAST(c.module_title AS text) AS "module_title",
    CAST(c.component_sequence AS smallint) AS "component_sequence",
    CAST(c.component_contract_code AS text) AS "component_contract_code",
    CAST(c.contract_version AS integer) AS "contract_version",
    CAST(c.schema_version AS text) AS "schema_version",
    CAST(c.methodology_version AS text) AS "methodology_version",
    CAST(c.acceptance_gate_id AS text) AS "acceptance_gate_id",
    CAST(c.registry_relation AS text) AS "registry_relation",
    CAST(c.latest_relation AS text) AS "latest_relation",
    CAST(c.archive_relation AS text) AS "archive_relation",
    CAST(c.latest_business_grain AS text) AS "latest_business_grain",
    CAST(c.latest_business_key_columns AS jsonb) AS "latest_business_key_columns",
    CAST(c.archive_business_key_columns AS jsonb) AS "archive_business_key_columns",
    CAST(c.expected_latest_rows AS bigint) AS "expected_latest_rows",
    CAST(c.observed_latest_rows AS bigint) AS "observed_latest_rows",
    CAST(c.expected_archive_rows AS bigint) AS "expected_archive_rows",
    CAST(c.observed_archive_rows AS bigint) AS "observed_archive_rows",
    CAST(c.stage_expected_canonical_entities AS bigint) AS "stage_expected_canonical_entities",
    CAST(c.expected_positive_controls AS integer) AS "expected_positive_controls",
    CAST(c.observed_positive_controls AS integer) AS "observed_positive_controls",
    CAST(c.expected_negative_controls AS integer) AS "expected_negative_controls",
    CAST(c.observed_negative_controls AS integer) AS "observed_negative_controls",
    CAST(c.expected_contract_set_hash AS text) AS "expected_contract_set_hash",
    CAST(c.observed_contract_set_hash AS text) AS "observed_contract_set_hash",
    CAST(c.expected_stage_combined_set_hash AS text) AS "expected_stage_combined_set_hash",
    CAST(c.observed_stage_combined_set_hash AS text) AS "observed_stage_combined_set_hash",
    CAST(c.expected_registry_row_hash AS text) AS "expected_registry_row_hash",
    CAST(c.observed_registry_row_hash AS text) AS "observed_registry_row_hash",
    CAST(c.expected_latest_set_hash AS text) AS "expected_latest_set_hash",
    CAST(c.observed_latest_set_hash AS text) AS "observed_latest_set_hash",
    CAST(c.expected_archive_set_hash AS text) AS "expected_archive_set_hash",
    CAST(c.observed_archive_set_hash AS text) AS "observed_archive_set_hash",
    CAST(c.contract_status AS text) AS "contract_status",
    CAST(c.gate_status AS text) AS "gate_status",
    CAST(c.acceptance_evidence_code AS text) AS "acceptance_evidence_code",
    CAST(c.acceptance_evidence_status AS text) AS "acceptance_evidence_status",
    CAST(c.required_source_edge_codes AS text[]) AS "required_source_edge_codes",
    CAST(c.required_source_edge_count AS smallint) AS "required_source_edge_count",
    CAST(c.passed_source_edge_count AS smallint) AS "passed_source_edge_count",
    CAST(c.certification_status AS text) AS "certification_status",
    CAST(c.row_hash AS text) AS "row_hash",
    CAST(r.bundle_code AS text) AS "g3_bundle_code",
    CAST(r.contract_version AS integer) AS "g3_contract_version",
    CAST(r.contract_status AS text) AS "g3_contract_status",
    CAST(r.combined_set_hash AS text) AS "g3_combined_set_hash"
FROM msbf_m2.module2_contract_component_snapshot c
LEFT JOIN msbf_ctl.m2_12_g3_bundle_registry r
  ON r.module1_run_id=c.module1_run_id AND r.contract_version=1
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=c.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED');

/* R10 GOVERNED STATEMENT 0031 OF 0473
   statement_code: P220_CREATE_VIEW_25
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE OR REPLACE VIEW msbf_ctl.v_m2_12_g3_lineage AS
SELECT
    CAST(r.module1_run_id AS bigint) AS "module1_run_id",
    CAST(r.bundle_code AS text) AS "bundle_code",
    CAST(r.contract_version AS integer) AS "contract_version",
    CAST(r.schema_version AS text) AS "schema_version",
    CAST(r.methodology_version AS text) AS "methodology_version",
    CAST(r.acceptance_gate_id AS text) AS "acceptance_gate_id",
    CAST(r.policy_code AS text) AS "policy_code",
    CAST(r.policy_version AS integer) AS "policy_version",
    CAST(r.policy_configuration_hash AS text) AS "policy_configuration_hash",
    CAST(r.accepted_m2_11_project_sha256 AS text) AS "accepted_m2_11_project_sha256",
    CAST(r.accepted_m2_11_contract_set_hash AS text) AS "accepted_m2_11_contract_set_hash",
    CAST(r.accepted_m2_11_combined_set_hash AS text) AS "accepted_m2_11_combined_set_hash",
    CAST(r.accepted_m2_11_registry_row_hash AS text) AS "accepted_m2_11_registry_row_hash",
    CAST(r.source_node_count AS integer) AS "source_node_count",
    CAST(r.component_contract_count AS integer) AS "component_contract_count",
    CAST(r.source_graph_edge_count AS integer) AS "source_graph_edge_count",
    CAST(r.evidence_certification_count AS integer) AS "evidence_certification_count",
    CAST(r.contract_reproduction_count AS integer) AS "contract_reproduction_count",
    CAST(r.capability_coverage_count AS integer) AS "capability_coverage_count",
    CAST(r.canonical_family_count AS integer) AS "canonical_family_count",
    CAST(r.canonical_entity_count AS integer) AS "canonical_entity_count",
    CAST(r.application_consumption_rows AS bigint) AS "application_consumption_rows",
    CAST(r.operational_account_consumption_rows AS integer) AS "operational_account_consumption_rows",
    CAST(r.strategy_scope_consumption_rows AS integer) AS "strategy_scope_consumption_rows",
    CAST(r.component_latest_rows_total AS bigint) AS "component_latest_rows_total",
    CAST(r.component_archive_rows_total AS bigint) AS "component_archive_rows_total",
    CAST(r.stage_local_canonical_reference_total AS bigint) AS "stage_local_canonical_reference_total",
    CAST(r.all_stage_certification_pass_flag AS boolean) AS "all_stage_certification_pass_flag",
    CAST(r.all_component_contract_pass_flag AS boolean) AS "all_component_contract_pass_flag",
    CAST(r.all_evidence_certification_pass_flag AS boolean) AS "all_evidence_certification_pass_flag",
    CAST(r.all_contract_reproduction_pass_flag AS boolean) AS "all_contract_reproduction_pass_flag",
    CAST(r.all_capability_boundary_pass_flag AS boolean) AS "all_capability_boundary_pass_flag",
    CAST(r.all_source_graph_edges_pass_flag AS boolean) AS "all_source_graph_edges_pass_flag",
    CAST(r.as_built_certification_scope_code AS text) AS "as_built_certification_scope_code",
    CAST(r.residual_limitation_payload AS jsonb) AS "residual_limitation_payload",
    CAST(r.deferred_capability_payload AS jsonb) AS "deferred_capability_payload",
    CAST(r.synthetic_data_only_flag AS boolean) AS "synthetic_data_only_flag",
    CAST(r.no_pii_flag AS boolean) AS "no_pii_flag",
    CAST(r.certification_only_flag AS boolean) AS "certification_only_flag",
    CAST(r.production_action_authorized_flag AS boolean) AS "production_action_authorized_flag",
    CAST(r.external_system_update_authorized_flag AS boolean) AS "external_system_update_authorized_flag",
    CAST(r.legal_or_regulatory_certified_flag AS boolean) AS "legal_or_regulatory_certified_flag",
    CAST(r.empirical_or_causal_optimization_authorized_flag AS boolean) AS "empirical_or_causal_optimization_authorized_flag",
    CAST(r.deployment_authorized_flag AS boolean) AS "deployment_authorized_flag",
    CAST(r.module3_execution_authorized_flag AS boolean) AS "module3_execution_authorized_flag",
    CAST(r.policy_set_hash AS text) AS "policy_set_hash",
    CAST(r.stage_certification_set_hash AS text) AS "stage_certification_set_hash",
    CAST(r.contract_component_set_hash AS text) AS "contract_component_set_hash",
    CAST(r.evidence_certification_set_hash AS text) AS "evidence_certification_set_hash",
    CAST(r.contract_reproduction_set_hash AS text) AS "contract_reproduction_set_hash",
    CAST(r.capability_coverage_set_hash AS text) AS "capability_coverage_set_hash",
    CAST(r.latest_set_hash AS text) AS "latest_set_hash",
    CAST(r.archive_set_hash AS text) AS "archive_set_hash",
    CAST(r.registry_set_hash AS text) AS "registry_set_hash",
    CAST(r.latest_contract_row_hash AS text) AS "latest_contract_row_hash",
    CAST(r.archive_contract_row_hash AS text) AS "archive_contract_row_hash",
    CAST(r.contract_set_hash AS text) AS "contract_set_hash",
    CAST(r.combined_set_hash AS text) AS "combined_set_hash",
    CAST(r.contract_status AS text) AS "contract_status",
    CAST(r.generated_at AS timestamptz) AS "generated_at",
    CAST(r.validated_at AS timestamptz) AS "validated_at",
    CAST(r.accepted_at AS timestamptz) AS "accepted_at",
    CAST(r.row_hash AS text) AS "row_hash"
FROM msbf_ctl.m2_12_g3_bundle_registry r
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=r.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED') AND r.contract_version=1;

/* R10 GOVERNED STATEMENT 0032 OF 0473
   statement_code: P220_CREATE_VIEW_26
   phase_code: 02_DDL
   statement_type: PERSISTENT_DDL
   source_authority: M2_12_PROGRAM_220_LITERAL_DDL_STATEMENT_CATALOG.csv
*/
CREATE OR REPLACE VIEW msbf_m2.v_m2_12_power_bi_enterprise_portfolio AS
SELECT
    CAST(s.module1_run_id AS bigint) AS "module1_run_id",
    CAST(s.contract_code AS text) AS "contract_code",
    CAST(s.contract_version AS integer) AS "contract_version",
    CAST(s.schema_version AS text) AS "schema_version",
    CAST(s.methodology_version AS text) AS "methodology_version",
    CAST(s.strategy_profile_code AS text) AS "strategy_profile_code",
    CAST(s.reporting_scope_code AS text) AS "reporting_scope_code",
    CAST(s.source_m1_17_contract_code AS text) AS "source_m1_17_contract_code",
    CAST(s.source_m1_17_contract_version AS integer) AS "source_m1_17_contract_version",
    CAST(s.source_m1_17_schema_version AS text) AS "source_m1_17_schema_version",
    CAST(s.source_m1_17_methodology_version AS text) AS "source_m1_17_methodology_version",
    CAST(s.source_m1_17_combined_hash AS text) AS "source_m1_17_combined_hash",
    CAST(s.source_m2_2_contract_code AS text) AS "source_m2_2_contract_code",
    CAST(s.source_m2_2_contract_version AS integer) AS "source_m2_2_contract_version",
    CAST(s.source_m2_2_schema_version AS text) AS "source_m2_2_schema_version",
    CAST(s.source_m2_2_methodology_version AS text) AS "source_m2_2_methodology_version",
    CAST(s.source_m2_2_combined_hash AS text) AS "source_m2_2_combined_hash",
    CAST(s.source_m2_4_contract_code AS text) AS "source_m2_4_contract_code",
    CAST(s.source_m2_4_contract_version AS integer) AS "source_m2_4_contract_version",
    CAST(s.source_m2_4_schema_version AS text) AS "source_m2_4_schema_version",
    CAST(s.source_m2_4_methodology_version AS text) AS "source_m2_4_methodology_version",
    CAST(s.source_m2_4_combined_hash AS text) AS "source_m2_4_combined_hash",
    CAST(s.source_m2_7_contract_code AS text) AS "source_m2_7_contract_code",
    CAST(s.source_m2_7_contract_version AS integer) AS "source_m2_7_contract_version",
    CAST(s.source_m2_7_schema_version AS text) AS "source_m2_7_schema_version",
    CAST(s.source_m2_7_methodology_version AS text) AS "source_m2_7_methodology_version",
    CAST(s.source_m2_7_combined_hash AS text) AS "source_m2_7_combined_hash",
    CAST(s.source_m2_10_contract_code AS text) AS "source_m2_10_contract_code",
    CAST(s.source_m2_10_contract_version AS integer) AS "source_m2_10_contract_version",
    CAST(s.source_m2_10_schema_version AS text) AS "source_m2_10_schema_version",
    CAST(s.source_m2_10_methodology_version AS text) AS "source_m2_10_methodology_version",
    CAST(s.source_m2_10_combined_hash AS text) AS "source_m2_10_combined_hash",
    CAST(s.application_rows AS bigint) AS "application_rows",
    CAST(s.access_selected_rows AS bigint) AS "access_selected_rows",
    CAST(s.controlled_review_rows AS bigint) AS "controlled_review_rows",
    CAST(s.strategy_restriction_rows AS bigint) AS "strategy_restriction_rows",
    CAST(s.no_feasible_candidate_rows AS bigint) AS "no_feasible_candidate_rows",
    CAST(s.insufficient_evidence_rows AS bigint) AS "insufficient_evidence_rows",
    CAST(s.policy_decline_rows AS bigint) AS "policy_decline_rows",
    CAST(s.blocked_source_rows AS bigint) AS "blocked_source_rows",
    CAST(s.servicing_account_rows AS bigint) AS "servicing_account_rows",
    CAST(s.servicing_distinct_application_rows AS bigint) AS "servicing_distinct_application_rows",
    CAST(s.hard_constraint_violation_count AS bigint) AS "hard_constraint_violation_count",
    CAST(s.source_risk_improvement_violation_count AS bigint) AS "source_risk_improvement_violation_count",
    CAST(s.source_return_improvement_violation_count AS bigint) AS "source_return_improvement_violation_count",
    CAST(s.strategy_access_improvement_violation_count AS bigint) AS "strategy_access_improvement_violation_count",
    CAST(s.strategy_feasibility_improvement_violation_count AS bigint) AS "strategy_feasibility_improvement_violation_count",
    CAST(s.comparable_payment_burden_improvement_violation_count AS bigint) AS "comparable_payment_burden_improvement_violation_count",
    CAST(s.comparable_servicing_burden_improvement_violation_count AS bigint) AS "comparable_servicing_burden_improvement_violation_count",
    CAST(s.stress_improvement_violation_count AS bigint) AS "stress_improvement_violation_count",
    CAST(s.stress_strategy_restriction_rows AS bigint) AS "stress_strategy_restriction_rows",
    CAST(s.absolute_workload_reduction_rows AS bigint) AS "absolute_workload_reduction_rows",
    CAST(s.access_rate AS numeric(18,10)) AS "access_rate",
    CAST(s.selected_exposure_amount AS numeric(24,2)) AS "selected_exposure_amount",
    CAST(s.finance_charge_amount AS numeric(24,2)) AS "finance_charge_amount",
    CAST(s.expected_loss_amount AS numeric(24,2)) AS "expected_loss_amount",
    CAST(s.expected_loss_density AS numeric(18,10)) AS "expected_loss_density",
    CAST(s.risk_adjusted_contribution AS numeric(24,2)) AS "risk_adjusted_contribution",
    CAST(s.annualized_risk_adjusted_return AS numeric(18,10)) AS "annualized_risk_adjusted_return",
    CAST(s.servicing_burden_units AS numeric(24,6)) AS "servicing_burden_units",
    CAST(s.payment_burden_rate AS numeric(18,10)) AS "payment_burden_rate",
    CAST(s.scope_strategy_score AS numeric(22,12)) AS "scope_strategy_score",
    CAST(s.governance_balance_score AS numeric(22,12)) AS "governance_balance_score",
    CAST(s.strategy_evidence_status AS text) AS "strategy_evidence_status",
    CAST(s.stress_nonimprovement_pass_flag AS boolean) AS "stress_nonimprovement_pass_flag",
    CAST(s.frontier_eligible_flag AS boolean) AS "frontier_eligible_flag",
    CAST(s.non_dominated_flag AS boolean) AS "non_dominated_flag",
    CAST(s.frontier_rank AS integer) AS "frontier_rank",
    CAST(s.governance_review_priority_code AS text) AS "governance_review_priority_code",
    CAST(s.primary_governance_review_flag AS boolean) AS "primary_governance_review_flag",
    CAST(s.servicing_burden_coverage_code AS text) AS "servicing_burden_coverage_code",
    CAST(s.new_access_servicing_burden_estimated_flag AS boolean) AS "new_access_servicing_burden_estimated_flag",
    CAST(s.baseline_access_rate_delta AS numeric(18,10)) AS "baseline_access_rate_delta",
    CAST(s.baseline_selected_exposure_amount_delta AS numeric(24,2)) AS "baseline_selected_exposure_amount_delta",
    CAST(s.baseline_finance_charge_amount_delta AS numeric(24,2)) AS "baseline_finance_charge_amount_delta",
    CAST(s.baseline_expected_loss_density_delta AS numeric(18,10)) AS "baseline_expected_loss_density_delta",
    CAST(s.baseline_risk_adjusted_contribution_delta AS numeric(24,2)) AS "baseline_risk_adjusted_contribution_delta",
    CAST(s.baseline_annualized_risk_adjusted_return_delta AS numeric(18,10)) AS "baseline_annualized_risk_adjusted_return_delta",
    CAST(s.baseline_servicing_burden_units_delta AS numeric(24,6)) AS "baseline_servicing_burden_units_delta",
    CAST(s.baseline_payment_burden_rate_delta AS numeric(18,10)) AS "baseline_payment_burden_rate_delta",
    CAST(s.primary_reason_code AS text) AS "primary_reason_code",
    CAST(s.reason_codes AS jsonb) AS "reason_codes",
    CAST(s.strategy_summary_row_hash AS text) AS "strategy_summary_row_hash",
    CAST(s.frontier_row_hash AS text) AS "frontier_row_hash",
    CAST(s.comparison_row_hash AS text) AS "comparison_row_hash",
    CAST(s.contract_row_hash AS text) AS "contract_row_hash",
    CAST(s.g3_bundle_code AS text) AS "g3_bundle_code",
    CAST(s.g3_contract_version AS integer) AS "g3_contract_version",
    CAST(s.g3_schema_version AS text) AS "g3_schema_version",
    CAST(s.g3_methodology_version AS text) AS "g3_methodology_version",
    CAST(s.g3_acceptance_gate_id AS text) AS "g3_acceptance_gate_id",
    CAST(s.g3_contract_status AS text) AS "g3_contract_status",
    CAST(s.g3_contract_set_hash AS text) AS "g3_contract_set_hash",
    CAST(s.g3_combined_set_hash AS text) AS "g3_combined_set_hash",
    CAST(s.g3_registry_row_hash AS text) AS "g3_registry_row_hash",
    CAST(s.deployment_authorized_flag AS boolean) AS "deployment_authorized_flag",
    CAST(s.module3_execution_authorized_flag AS boolean) AS "module3_execution_authorized_flag",
    CAST(s.source_contract_row_hash AS text) AS "source_contract_row_hash",
    CAST(s.application_count AS bigint) AS "application_count",
    CAST(s.annualized_return AS numeric(28,10)) AS "annualized_return",
    CAST(s.dominance_status AS text) AS "dominance_status",
    CAST(s.governance_priority_code AS text) AS "governance_priority_code"
FROM msbf_m2.v_m2_12_strategy_scope_consumption s
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=s.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED');

/* R10 GOVERNED STATEMENT 0033 OF 0473
   statement_code: CREATE_TMP_SRC_M2_12_POLICY_SEED_BASE
   phase_code: 03_POLICY_CONSTRUCTION
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_policy_seed_base ON COMMIT DROP AS
SELECT 'G3_M2_CONTRACT'::text AS acceptance_gate_id,
       ictx.accepted_m2_11_combined_set_hash::text AS accepted_m2_11_combined_set_hash,
       ictx.accepted_m2_11_contract_set_hash::text AS accepted_m2_11_contract_set_hash,
       '92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc'::text AS accepted_m2_11_project_sha256,
       ictx.accepted_m2_11_registry_row_hash::text AS accepted_m2_11_registry_row_hash,
       'M2_G3_CONSUMPTION_BUNDLE'::text AS bundle_code,
       1::integer AS bundle_version,
       true::boolean AS certification_only_flag,
       jsonb_build_object(
'module_identity',jsonb_build_object(
 'stage_code','31_M2_12','methodology_version','M2_12_METHOD_V1',
 'policy_code','M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1','policy_version',1,
 'bundle_code','M2_G3_CONSUMPTION_BUNDLE','bundle_version',1,
 'schema_version','M2_G3_BUNDLE_SCHEMA_V1','acceptance_gate_id','G3_M2_CONTRACT'),
'accepted_baseline',jsonb_build_object(
 'project_sha256','92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc',
 'contract_set_hash',ictx.accepted_m2_11_contract_set_hash,'combined_set_hash',ictx.accepted_m2_11_combined_set_hash,
 'registry_row_hash',ictx.accepted_m2_11_registry_row_hash),
'expected_design_counts',jsonb_build_object(
 'source_nodes',12,'component_contracts',13,'source_graph_edges',19,
 'evidence_certifications',72,'contract_reproductions',13,'capability_rows',20,
 'canonical_families',9,'canonical_entities',134,'application_consumption_rows',1500,
 'operational_account_consumption_rows',59,'strategy_scope_consumption_rows',24,
 'generation_evidence_rows',24,'positive_controls',128,'negative_controls',20,
 'acceptance_requirements',48,'detail_result_sets',24),
'boundary_flags',jsonb_build_object(
 'synthetic_data_only',true,'no_pii',true,'certification_only',true,
 'production_action_authorized',false,'external_system_update_authorized',false,
 'legal_or_regulatory_certified',false,
 'empirical_or_causal_optimization_authorized',false,
 'module3_sql_authorized',false,'module3_execution_authorized',false)
)::jsonb AS configuration_payload,
       false::boolean AS empirical_or_causal_optimization_authorized_flag,
       48::integer AS expected_acceptance_requirements,
       1500::bigint AS expected_application_consumption_rows,
       134::integer AS expected_canonical_entities,
       9::integer AS expected_canonical_family_count,
       20::integer AS expected_capability_coverage_rows,
       13::integer AS expected_component_contract_rows,
       13::integer AS expected_contract_reproduction_rows,
       24::integer AS expected_detail_result_sets,
       72::integer AS expected_evidence_certification_rows,
       24::integer AS expected_generation_evidence_rows,
       20::integer AS expected_negative_controls,
       59::integer AS expected_operational_account_consumption_rows,
       128::integer AS expected_positive_controls,
       19::integer AS expected_source_graph_edge_rows,
       12::integer AS expected_source_node_rows,
       24::integer AS expected_strategy_scope_consumption_rows,
       false::boolean AS external_system_update_authorized_flag,
       false::boolean AS legal_or_regulatory_certified_flag,
       'M2_12_METHOD_V1'::text AS methodology_version,
       ictx.module1_run_id::bigint AS module1_run_id,
       false::boolean AS module3_execution_authorized_flag,
       false::boolean AS module3_sql_authorized_flag,
       true::boolean AS no_pii_flag,
       'M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1'::text AS policy_code,
       'APPROVED'::text AS policy_status,
       1::integer AS policy_version,
       false::boolean AS production_action_authorized_flag,
       'M2_G3_BUNDLE_SCHEMA_V1'::text AS schema_version,
       true::boolean AS synthetic_data_only_flag
FROM tmp_install_m2_12_run_context ictx;

/* R10 GOVERNED STATEMENT 0034 OF 0473
   statement_code: ASSERT_TMP_SRC_M2_12_POLICY_SEED_BASE
   phase_code: 03_POLICY_CONSTRUCTION
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_src_m2_12_policy_seed_base$ BEGIN IF (SELECT count(*) FROM tmp_src_m2_12_policy_seed_base) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_src_m2_12_policy_seed_base', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_src_m2_12_policy_seed_base)::text; END IF; END; $m212_r7_tmp_src_m2_12_policy_seed_base$;

/* R10 GOVERNED STATEMENT 0035 OF 0473
   statement_code: INDEX_TMP_SRC_M2_12_POLICY_SEED_BASE
   phase_code: 03_POLICY_CONSTRUCTION
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_policy_seed_base_fe0a131a ON tmp_src_m2_12_policy_seed_base (module1_run_id);

/* R10 GOVERNED STATEMENT 0036 OF 0473
   statement_code: ANALYZE_TMP_SRC_M2_12_POLICY_SEED_BASE
   phase_code: 03_POLICY_CONSTRUCTION
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_policy_seed_base;

/* R10 GOVERNED STATEMENT 0037 OF 0473
   statement_code: CREATE_TMP_SRC_M2_12_POLICY_SEED
   phase_code: 03_POLICY_CONSTRUCTION
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_policy_seed ON COMMIT DROP AS
SELECT psb.acceptance_gate_id AS acceptance_gate_id,
       psb.accepted_m2_11_combined_set_hash AS accepted_m2_11_combined_set_hash,
       psb.accepted_m2_11_contract_set_hash AS accepted_m2_11_contract_set_hash,
       psb.accepted_m2_11_project_sha256 AS accepted_m2_11_project_sha256,
       psb.accepted_m2_11_registry_row_hash AS accepted_m2_11_registry_row_hash,
       psb.bundle_code AS bundle_code,
       psb.bundle_version AS bundle_version,
       psb.certification_only_flag AS certification_only_flag,
       md5(psb.configuration_payload::text)::text AS configuration_hash,
       psb.configuration_payload AS configuration_payload,
       psb.empirical_or_causal_optimization_authorized_flag AS empirical_or_causal_optimization_authorized_flag,
       psb.expected_acceptance_requirements AS expected_acceptance_requirements,
       psb.expected_application_consumption_rows AS expected_application_consumption_rows,
       psb.expected_canonical_entities AS expected_canonical_entities,
       psb.expected_canonical_family_count AS expected_canonical_family_count,
       psb.expected_capability_coverage_rows AS expected_capability_coverage_rows,
       psb.expected_component_contract_rows AS expected_component_contract_rows,
       psb.expected_contract_reproduction_rows AS expected_contract_reproduction_rows,
       psb.expected_detail_result_sets AS expected_detail_result_sets,
       psb.expected_evidence_certification_rows AS expected_evidence_certification_rows,
       psb.expected_generation_evidence_rows AS expected_generation_evidence_rows,
       psb.expected_negative_controls AS expected_negative_controls,
       psb.expected_operational_account_consumption_rows AS expected_operational_account_consumption_rows,
       psb.expected_positive_controls AS expected_positive_controls,
       psb.expected_source_graph_edge_rows AS expected_source_graph_edge_rows,
       psb.expected_source_node_rows AS expected_source_node_rows,
       psb.expected_strategy_scope_consumption_rows AS expected_strategy_scope_consumption_rows,
       psb.external_system_update_authorized_flag AS external_system_update_authorized_flag,
       psb.legal_or_regulatory_certified_flag AS legal_or_regulatory_certified_flag,
       psb.methodology_version AS methodology_version,
       psb.module1_run_id AS module1_run_id,
       psb.module3_execution_authorized_flag AS module3_execution_authorized_flag,
       psb.module3_sql_authorized_flag AS module3_sql_authorized_flag,
       psb.no_pii_flag AS no_pii_flag,
       psb.policy_code AS policy_code,
       psb.policy_status AS policy_status,
       psb.policy_version AS policy_version,
       psb.production_action_authorized_flag AS production_action_authorized_flag,
       psb.schema_version AS schema_version,
       psb.synthetic_data_only_flag AS synthetic_data_only_flag
FROM tmp_src_m2_12_policy_seed_base psb;

/* R10 GOVERNED STATEMENT 0038 OF 0473
   statement_code: ASSERT_TMP_SRC_M2_12_POLICY_SEED
   phase_code: 03_POLICY_CONSTRUCTION
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_src_m2_12_policy_seed$ BEGIN IF (SELECT count(*) FROM tmp_src_m2_12_policy_seed) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_src_m2_12_policy_seed', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_src_m2_12_policy_seed)::text; END IF; END; $m212_r7_tmp_src_m2_12_policy_seed$;

/* R10 GOVERNED STATEMENT 0039 OF 0473
   statement_code: INDEX_TMP_SRC_M2_12_POLICY_SEED
   phase_code: 03_POLICY_CONSTRUCTION
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_policy_seed_93c2ccf4 ON tmp_src_m2_12_policy_seed (module1_run_id);

/* R10 GOVERNED STATEMENT 0040 OF 0473
   statement_code: ANALYZE_TMP_SRC_M2_12_POLICY_SEED
   phase_code: 03_POLICY_CONSTRUCTION
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_policy_seed;

/* R10 GOVERNED STATEMENT 0041 OF 0473
   statement_code: CREATE_TMP_SRC_M2_12_POLICY_TYPED
   phase_code: 03_POLICY_CONSTRUCTION
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_src_m2_12_policy_typed ON COMMIT DROP AS
SELECT pseed.module1_run_id::bigint AS module1_run_id,
       pseed.policy_code::text AS policy_code,
       pseed.policy_version::integer AS policy_version,
       pseed.policy_status::text AS policy_status,
       pseed.methodology_version::text AS methodology_version,
       pseed.bundle_code::text AS bundle_code,
       pseed.bundle_version::integer AS bundle_version,
       pseed.schema_version::text AS schema_version,
       pseed.acceptance_gate_id::text AS acceptance_gate_id,
       pseed.accepted_m2_11_project_sha256::text AS accepted_m2_11_project_sha256,
       pseed.accepted_m2_11_contract_set_hash::text AS accepted_m2_11_contract_set_hash,
       pseed.accepted_m2_11_combined_set_hash::text AS accepted_m2_11_combined_set_hash,
       pseed.accepted_m2_11_registry_row_hash::text AS accepted_m2_11_registry_row_hash,
       pseed.expected_source_node_rows::integer AS expected_source_node_rows,
       pseed.expected_component_contract_rows::integer AS expected_component_contract_rows,
       pseed.expected_source_graph_edge_rows::integer AS expected_source_graph_edge_rows,
       pseed.expected_evidence_certification_rows::integer AS expected_evidence_certification_rows,
       pseed.expected_contract_reproduction_rows::integer AS expected_contract_reproduction_rows,
       pseed.expected_capability_coverage_rows::integer AS expected_capability_coverage_rows,
       pseed.expected_canonical_family_count::integer AS expected_canonical_family_count,
       pseed.expected_canonical_entities::integer AS expected_canonical_entities,
       pseed.expected_application_consumption_rows::bigint AS expected_application_consumption_rows,
       pseed.expected_operational_account_consumption_rows::integer AS expected_operational_account_consumption_rows,
       pseed.expected_strategy_scope_consumption_rows::integer AS expected_strategy_scope_consumption_rows,
       pseed.expected_generation_evidence_rows::integer AS expected_generation_evidence_rows,
       pseed.expected_positive_controls::integer AS expected_positive_controls,
       pseed.expected_negative_controls::integer AS expected_negative_controls,
       pseed.expected_acceptance_requirements::integer AS expected_acceptance_requirements,
       pseed.expected_detail_result_sets::integer AS expected_detail_result_sets,
       pseed.synthetic_data_only_flag::boolean AS synthetic_data_only_flag,
       pseed.no_pii_flag::boolean AS no_pii_flag,
       pseed.certification_only_flag::boolean AS certification_only_flag,
       pseed.production_action_authorized_flag::boolean AS production_action_authorized_flag,
       pseed.external_system_update_authorized_flag::boolean AS external_system_update_authorized_flag,
       pseed.legal_or_regulatory_certified_flag::boolean AS legal_or_regulatory_certified_flag,
       pseed.empirical_or_causal_optimization_authorized_flag::boolean AS empirical_or_causal_optimization_authorized_flag,
       pseed.module3_sql_authorized_flag::boolean AS module3_sql_authorized_flag,
       pseed.module3_execution_authorized_flag::boolean AS module3_execution_authorized_flag,
       pseed.configuration_payload::jsonb AS configuration_payload,
       pseed.configuration_hash::text AS configuration_hash,
       md5((to_jsonb(pseed)-'row_hash'-'created_at'-'updated_at')::text)::text AS row_hash,
       clock_timestamp()::timestamptz AS created_at,
       clock_timestamp()::timestamptz AS updated_at
FROM tmp_src_m2_12_policy_seed pseed;

/* R10 GOVERNED STATEMENT 0042 OF 0473
   statement_code: ASSERT_TMP_SRC_M2_12_POLICY_TYPED
   phase_code: 03_POLICY_CONSTRUCTION
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_src_m2_12_policy_typed$ BEGIN IF (SELECT count(*) FROM tmp_src_m2_12_policy_typed) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_src_m2_12_policy_typed', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_src_m2_12_policy_typed)::text; END IF; END; $m212_r7_tmp_src_m2_12_policy_typed$;

/* R10 GOVERNED STATEMENT 0043 OF 0473
   statement_code: INDEX_TMP_SRC_M2_12_POLICY_TYPED
   phase_code: 03_POLICY_CONSTRUCTION
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_src_m2_12_policy_typed_d99f6b38 ON tmp_src_m2_12_policy_typed (module1_run_id);

/* R10 GOVERNED STATEMENT 0044 OF 0473
   statement_code: ANALYZE_TMP_SRC_M2_12_POLICY_TYPED
   phase_code: 03_POLICY_CONSTRUCTION
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_src_m2_12_policy_typed;

/* R10 GOVERNED STATEMENT 0045 OF 0473
   statement_code: INSERT_POLICY
   phase_code: 04_POLICY_INSERT
   statement_type: PERSISTENT_INSERT
   source_authority: M2_12_PERSISTENT_INSERT_STATEMENT_COMPILER.csv
*/
INSERT INTO msbf_ctl.m2_12_policy_profile (
    "module1_run_id",
    "policy_code",
    "policy_version",
    "policy_status",
    "methodology_version",
    "bundle_code",
    "bundle_version",
    "schema_version",
    "acceptance_gate_id",
    "accepted_m2_11_project_sha256",
    "accepted_m2_11_contract_set_hash",
    "accepted_m2_11_combined_set_hash",
    "accepted_m2_11_registry_row_hash",
    "expected_source_node_rows",
    "expected_component_contract_rows",
    "expected_source_graph_edge_rows",
    "expected_evidence_certification_rows",
    "expected_contract_reproduction_rows",
    "expected_capability_coverage_rows",
    "expected_canonical_family_count",
    "expected_canonical_entities",
    "expected_application_consumption_rows",
    "expected_operational_account_consumption_rows",
    "expected_strategy_scope_consumption_rows",
    "expected_generation_evidence_rows",
    "expected_positive_controls",
    "expected_negative_controls",
    "expected_acceptance_requirements",
    "expected_detail_result_sets",
    "synthetic_data_only_flag",
    "no_pii_flag",
    "certification_only_flag",
    "production_action_authorized_flag",
    "external_system_update_authorized_flag",
    "legal_or_regulatory_certified_flag",
    "empirical_or_causal_optimization_authorized_flag",
    "module3_sql_authorized_flag",
    "module3_execution_authorized_flag",
    "configuration_payload",
    "configuration_hash",
    "row_hash",
    "created_at",
    "updated_at"
)
SELECT
    src.module1_run_id::bigint,
    src.policy_code::text,
    src.policy_version::integer,
    src.policy_status::text,
    src.methodology_version::text,
    src.bundle_code::text,
    src.bundle_version::integer,
    src.schema_version::text,
    src.acceptance_gate_id::text,
    src.accepted_m2_11_project_sha256::text,
    src.accepted_m2_11_contract_set_hash::text,
    src.accepted_m2_11_combined_set_hash::text,
    src.accepted_m2_11_registry_row_hash::text,
    src.expected_source_node_rows::integer,
    src.expected_component_contract_rows::integer,
    src.expected_source_graph_edge_rows::integer,
    src.expected_evidence_certification_rows::integer,
    src.expected_contract_reproduction_rows::integer,
    src.expected_capability_coverage_rows::integer,
    src.expected_canonical_family_count::integer,
    src.expected_canonical_entities::integer,
    src.expected_application_consumption_rows::bigint,
    src.expected_operational_account_consumption_rows::integer,
    src.expected_strategy_scope_consumption_rows::integer,
    src.expected_generation_evidence_rows::integer,
    src.expected_positive_controls::integer,
    src.expected_negative_controls::integer,
    src.expected_acceptance_requirements::integer,
    src.expected_detail_result_sets::integer,
    src.synthetic_data_only_flag::boolean,
    src.no_pii_flag::boolean,
    src.certification_only_flag::boolean,
    src.production_action_authorized_flag::boolean,
    src.external_system_update_authorized_flag::boolean,
    src.legal_or_regulatory_certified_flag::boolean,
    src.empirical_or_causal_optimization_authorized_flag::boolean,
    src.module3_sql_authorized_flag::boolean,
    src.module3_execution_authorized_flag::boolean,
    src.configuration_payload::jsonb,
    src.configuration_hash::text,
    src.row_hash::text,
    src.created_at::timestamptz,
    src.updated_at::timestamptz
FROM tmp_src_m2_12_policy_typed src;

/* R10 GOVERNED STATEMENT 0046 OF 0473
   statement_code: P220_PF_0001_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0001$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_ctl.m2_12_policy_profile') IS NOT NULL AND (SELECT relkind='r' FROM pg_catalog.pg_class WHERE oid='msbf_ctl.m2_12_policy_profile'::regclass) AND (SELECT count(*) FROM pg_catalog.pg_attribute WHERE attrelid='msbf_ctl.m2_12_policy_profile'::regclass AND attnum>0 AND NOT attisdropped)=44), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0001_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0001_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0001$;

/* R10 GOVERNED STATEMENT 0047 OF 0473
   statement_code: P220_PF_0002_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0002$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_m2.module2_stage_certification_snapshot') IS NOT NULL AND (SELECT relkind='r' FROM pg_catalog.pg_class WHERE oid='msbf_m2.module2_stage_certification_snapshot'::regclass) AND (SELECT count(*) FROM pg_catalog.pg_attribute WHERE attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass AND attnum>0 AND NOT attisdropped)=31), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0002_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0002_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0002$;

/* R10 GOVERNED STATEMENT 0048 OF 0473
   statement_code: P220_PF_0003_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0003$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_m2.module2_contract_component_snapshot') IS NOT NULL AND (SELECT relkind='r' FROM pg_catalog.pg_class WHERE oid='msbf_m2.module2_contract_component_snapshot'::regclass) AND (SELECT count(*) FROM pg_catalog.pg_attribute WHERE attrelid='msbf_m2.module2_contract_component_snapshot'::regclass AND attnum>0 AND NOT attisdropped)=46), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0003_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0003_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0003$;

/* R10 GOVERNED STATEMENT 0049 OF 0473
   statement_code: P220_PF_0004_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0004$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_m2.module2_evidence_certification_snapshot') IS NOT NULL AND (SELECT relkind='r' FROM pg_catalog.pg_class WHERE oid='msbf_m2.module2_evidence_certification_snapshot'::regclass) AND (SELECT count(*) FROM pg_catalog.pg_attribute WHERE attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass AND attnum>0 AND NOT attisdropped)=22), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0004_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0004_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0004$;

/* R10 GOVERNED STATEMENT 0050 OF 0473
   statement_code: P220_PF_0005_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0005$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_m2.module2_contract_reproduction_snapshot') IS NOT NULL AND (SELECT relkind='r' FROM pg_catalog.pg_class WHERE oid='msbf_m2.module2_contract_reproduction_snapshot'::regclass) AND (SELECT count(*) FROM pg_catalog.pg_attribute WHERE attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass AND attnum>0 AND NOT attisdropped)=32), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0005_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0005_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0005$;

/* R10 GOVERNED STATEMENT 0051 OF 0473
   statement_code: P220_PF_0006_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0006$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_m2.module2_capability_coverage_snapshot') IS NOT NULL AND (SELECT relkind='r' FROM pg_catalog.pg_class WHERE oid='msbf_m2.module2_capability_coverage_snapshot'::regclass) AND (SELECT count(*) FROM pg_catalog.pg_attribute WHERE attrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass AND attnum>0 AND NOT attisdropped)=11), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0006_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0006_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0006$;

/* R10 GOVERNED STATEMENT 0052 OF 0473
   statement_code: P220_PF_0007_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0007$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_ctl.m2_12_g3_bundle_latest') IS NOT NULL AND (SELECT relkind='r' FROM pg_catalog.pg_class WHERE oid='msbf_ctl.m2_12_g3_bundle_latest'::regclass) AND (SELECT count(*) FROM pg_catalog.pg_attribute WHERE attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass AND attnum>0 AND NOT attisdropped)=63), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0007_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0007_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0007$;

/* R10 GOVERNED STATEMENT 0053 OF 0473
   statement_code: P220_PF_0008_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0008$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_ctl.m2_12_g3_bundle_archive') IS NOT NULL AND (SELECT relkind='r' FROM pg_catalog.pg_class WHERE oid='msbf_ctl.m2_12_g3_bundle_archive'::regclass) AND (SELECT count(*) FROM pg_catalog.pg_attribute WHERE attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass AND attnum>0 AND NOT attisdropped)=12), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0008_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0008_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0008$;

/* R10 GOVERNED STATEMENT 0054 OF 0473
   statement_code: P220_PF_0009_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0009$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_ctl.m2_12_g3_bundle_registry') IS NOT NULL AND (SELECT relkind='r' FROM pg_catalog.pg_class WHERE oid='msbf_ctl.m2_12_g3_bundle_registry'::regclass) AND (SELECT count(*) FROM pg_catalog.pg_attribute WHERE attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass AND attnum>0 AND NOT attisdropped)=66), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0009_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0009_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0009$;

/* R10 GOVERNED STATEMENT 0055 OF 0473
   statement_code: P220_PF_0010_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0010$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(p.prorettype='trigger'::regtype)
   AND bool_and(p.provolatile='v')
   AND bool_and(NOT p.prosecdef)
   AND bool_and(p.proparallel='u')
   AND bool_and(l.lanname='plpgsql')
   AND bool_and(coalesce(array_to_string(p.proconfig,','),'')='search_path=pg_catalog, msbf_ctl, msbf_m2')
   AND bool_and(md5(btrim(regexp_replace(p.prosrc,'\s+',' ','g')))='3277d5b941073aee0b5e52374808ac6d')
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
JOIN pg_catalog.pg_language l ON l.oid=p.prolang
WHERE n.nspname='msbf_ctl'
  AND p.proname='m2_12_reject_g3_archive_mutation'
  AND p.pronargs=0), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0010_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0010_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0010$;

/* R10 GOVERNED STATEMENT 0056 OF 0473
   statement_code: P220_PF_0011_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0011$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(t.tgtype=27)
   AND bool_and(t.tgenabled='O')
   AND bool_and(n.nspname='msbf_ctl')
   AND bool_and(p.proname='m2_12_reject_g3_archive_mutation')
   AND bool_and(p.pronargs=0)
FROM pg_catalog.pg_trigger t
JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid
JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
WHERE t.tgrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND NOT t.tgisinternal
  AND t.tgname='trg_m2_12_g3_archive_immutable'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0011_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0011_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0011$;

/* R10 GOVERNED STATEMENT 0057 OF 0473
   statement_code: P220_PF_0012_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_pf_0012_top_level_object$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(view_catalog.relkind='v' AND view_catalog.relpersistence='p')
   AND bool_and(NOT view_catalog.has_temporary_dependency)
FROM (
    SELECT c.relkind,
           c.relpersistence,
           EXISTS (
               SELECT 1
               FROM pg_catalog.pg_rewrite r
               JOIN pg_catalog.pg_depend d
                 ON d.classid='pg_catalog.pg_rewrite'::regclass
                AND d.objid=r.oid
                AND d.refclassid='pg_catalog.pg_class'::regclass
               JOIN pg_catalog.pg_class dc ON dc.oid=d.refobjid
               JOIN pg_catalog.pg_namespace dn ON dn.oid=dc.relnamespace
               WHERE r.ev_class=c.oid
                 AND r.rulename='_RETURN'
                 AND dn.nspname LIKE 'pg_temp_%'
           ) AS has_temporary_dependency
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='msbf_m2'
      AND c.relname='v_m2_12_application_origination_consumption'
) view_catalog), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 installation postflight failed',
            DETAIL = 'check_code=P220_PF_0012_TOP_LEVEL_OBJECT',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_pf_0012_top_level_object$;

/* R10 GOVERNED STATEMENT 0058 OF 0473
   statement_code: P220_PF_0013_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_pf_0013_top_level_object$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(view_catalog.relkind='v' AND view_catalog.relpersistence='p')
   AND bool_and(NOT view_catalog.has_temporary_dependency)
FROM (
    SELECT c.relkind,
           c.relpersistence,
           EXISTS (
               SELECT 1
               FROM pg_catalog.pg_rewrite r
               JOIN pg_catalog.pg_depend d
                 ON d.classid='pg_catalog.pg_rewrite'::regclass
                AND d.objid=r.oid
                AND d.refclassid='pg_catalog.pg_class'::regclass
               JOIN pg_catalog.pg_class dc ON dc.oid=d.refobjid
               JOIN pg_catalog.pg_namespace dn ON dn.oid=dc.relnamespace
               WHERE r.ev_class=c.oid
                 AND r.rulename='_RETURN'
                 AND dn.nspname LIKE 'pg_temp_%'
           ) AS has_temporary_dependency
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='msbf_m2'
      AND c.relname='v_m2_12_operational_account_consumption'
) view_catalog), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 installation postflight failed',
            DETAIL = 'check_code=P220_PF_0013_TOP_LEVEL_OBJECT',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_pf_0013_top_level_object$;

/* R10 GOVERNED STATEMENT 0059 OF 0473
   statement_code: P220_PF_0014_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_pf_0014_top_level_object$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(view_catalog.relkind='v' AND view_catalog.relpersistence='p')
   AND bool_and(NOT view_catalog.has_temporary_dependency)
FROM (
    SELECT c.relkind,
           c.relpersistence,
           EXISTS (
               SELECT 1
               FROM pg_catalog.pg_rewrite r
               JOIN pg_catalog.pg_depend d
                 ON d.classid='pg_catalog.pg_rewrite'::regclass
                AND d.objid=r.oid
                AND d.refclassid='pg_catalog.pg_class'::regclass
               JOIN pg_catalog.pg_class dc ON dc.oid=d.refobjid
               JOIN pg_catalog.pg_namespace dn ON dn.oid=dc.relnamespace
               WHERE r.ev_class=c.oid
                 AND r.rulename='_RETURN'
                 AND dn.nspname LIKE 'pg_temp_%'
           ) AS has_temporary_dependency
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='msbf_m2'
      AND c.relname='v_m2_12_strategy_scope_consumption'
) view_catalog), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 installation postflight failed',
            DETAIL = 'check_code=P220_PF_0014_TOP_LEVEL_OBJECT',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_pf_0014_top_level_object$;

/* R10 GOVERNED STATEMENT 0060 OF 0473
   statement_code: P220_PF_0015_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_pf_0015_top_level_object$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(view_catalog.relkind='v' AND view_catalog.relpersistence='p')
   AND bool_and(NOT view_catalog.has_temporary_dependency)
FROM (
    SELECT c.relkind,
           c.relpersistence,
           EXISTS (
               SELECT 1
               FROM pg_catalog.pg_rewrite r
               JOIN pg_catalog.pg_depend d
                 ON d.classid='pg_catalog.pg_rewrite'::regclass
                AND d.objid=r.oid
                AND d.refclassid='pg_catalog.pg_class'::regclass
               JOIN pg_catalog.pg_class dc ON dc.oid=d.refobjid
               JOIN pg_catalog.pg_namespace dn ON dn.oid=dc.relnamespace
               WHERE r.ev_class=c.oid
                 AND r.rulename='_RETURN'
                 AND dn.nspname LIKE 'pg_temp_%'
           ) AS has_temporary_dependency
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='msbf_ctl'
      AND c.relname='v_m2_12_stage_lineage'
) view_catalog), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 installation postflight failed',
            DETAIL = 'check_code=P220_PF_0015_TOP_LEVEL_OBJECT',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_pf_0015_top_level_object$;

/* R10 GOVERNED STATEMENT 0061 OF 0473
   statement_code: P220_PF_0016_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_pf_0016_top_level_object$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(view_catalog.relkind='v' AND view_catalog.relpersistence='p')
   AND bool_and(NOT view_catalog.has_temporary_dependency)
FROM (
    SELECT c.relkind,
           c.relpersistence,
           EXISTS (
               SELECT 1
               FROM pg_catalog.pg_rewrite r
               JOIN pg_catalog.pg_depend d
                 ON d.classid='pg_catalog.pg_rewrite'::regclass
                AND d.objid=r.oid
                AND d.refclassid='pg_catalog.pg_class'::regclass
               JOIN pg_catalog.pg_class dc ON dc.oid=d.refobjid
               JOIN pg_catalog.pg_namespace dn ON dn.oid=dc.relnamespace
               WHERE r.ev_class=c.oid
                 AND r.rulename='_RETURN'
                 AND dn.nspname LIKE 'pg_temp_%'
           ) AS has_temporary_dependency
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='msbf_ctl'
      AND c.relname='v_m2_12_component_contract_lineage'
) view_catalog), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 installation postflight failed',
            DETAIL = 'check_code=P220_PF_0016_TOP_LEVEL_OBJECT',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_pf_0016_top_level_object$;

/* R10 GOVERNED STATEMENT 0062 OF 0473
   statement_code: P220_PF_0017_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_pf_0017_top_level_object$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(view_catalog.relkind='v' AND view_catalog.relpersistence='p')
   AND bool_and(NOT view_catalog.has_temporary_dependency)
FROM (
    SELECT c.relkind,
           c.relpersistence,
           EXISTS (
               SELECT 1
               FROM pg_catalog.pg_rewrite r
               JOIN pg_catalog.pg_depend d
                 ON d.classid='pg_catalog.pg_rewrite'::regclass
                AND d.objid=r.oid
                AND d.refclassid='pg_catalog.pg_class'::regclass
               JOIN pg_catalog.pg_class dc ON dc.oid=d.refobjid
               JOIN pg_catalog.pg_namespace dn ON dn.oid=dc.relnamespace
               WHERE r.ev_class=c.oid
                 AND r.rulename='_RETURN'
                 AND dn.nspname LIKE 'pg_temp_%'
           ) AS has_temporary_dependency
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='msbf_ctl'
      AND c.relname='v_m2_12_g3_lineage'
) view_catalog), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 installation postflight failed',
            DETAIL = 'check_code=P220_PF_0017_TOP_LEVEL_OBJECT',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_pf_0017_top_level_object$;

/* R10 GOVERNED STATEMENT 0063 OF 0473
   statement_code: P220_PF_0018_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_pf_0018_top_level_object$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(view_catalog.relkind='v' AND view_catalog.relpersistence='p')
   AND bool_and(NOT view_catalog.has_temporary_dependency)
FROM (
    SELECT c.relkind,
           c.relpersistence,
           EXISTS (
               SELECT 1
               FROM pg_catalog.pg_rewrite r
               JOIN pg_catalog.pg_depend d
                 ON d.classid='pg_catalog.pg_rewrite'::regclass
                AND d.objid=r.oid
                AND d.refclassid='pg_catalog.pg_class'::regclass
               JOIN pg_catalog.pg_class dc ON dc.oid=d.refobjid
               JOIN pg_catalog.pg_namespace dn ON dn.oid=dc.relnamespace
               WHERE r.ev_class=c.oid
                 AND r.rulename='_RETURN'
                 AND dn.nspname LIKE 'pg_temp_%'
           ) AS has_temporary_dependency
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='msbf_m2'
      AND c.relname='v_m2_12_power_bi_enterprise_portfolio'
) view_catalog), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 installation postflight failed',
            DETAIL = 'check_code=P220_PF_0018_TOP_LEVEL_OBJECT',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_pf_0018_top_level_object$;

/* R10 GOVERNED STATEMENT 0064 OF 0473
   statement_code: P220_PF_0019_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0019$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_ctl.m2_12_policy_profile_policy_profile_id_seq') IS NOT NULL
   AND pg_get_serial_sequence('msbf_ctl.m2_12_policy_profile','policy_profile_id')='msbf_ctl.m2_12_policy_profile_policy_profile_id_seq'
   AND EXISTS (
       SELECT 1
       FROM pg_catalog.pg_attribute a
       WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
         AND a.attname='policy_profile_id'
         AND a.attidentity='a'
         AND a.attnotnull
   )
   AND EXISTS (
       SELECT 1 FROM pg_catalog.pg_depend d
       WHERE d.objid='msbf_ctl.m2_12_policy_profile_policy_profile_id_seq'::regclass
         AND d.refobjid='msbf_ctl.m2_12_policy_profile'::regclass
         AND d.deptype='i'
   )), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0019_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0019_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0019$;

/* R10 GOVERNED STATEMENT 0065 OF 0473
   statement_code: P220_PF_0020_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0020$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq') IS NOT NULL
   AND pg_get_serial_sequence('msbf_ctl.m2_12_g3_bundle_archive','archive_id')='msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq'
   AND EXISTS (
       SELECT 1
       FROM pg_catalog.pg_attribute a
       WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
         AND a.attname='archive_id'
         AND a.attidentity='a'
         AND a.attnotnull
   )
   AND EXISTS (
       SELECT 1 FROM pg_catalog.pg_depend d
       WHERE d.objid='msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq'::regclass
         AND d.refobjid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
         AND d.deptype='i'
   )), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0020_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0020_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0020$;

/* R10 GOVERNED STATEMENT 0066 OF 0473
   statement_code: P220_PF_0021_TOP_LEVEL_OBJECT
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0021$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq') IS NOT NULL
   AND pg_get_serial_sequence('msbf_ctl.m2_12_g3_bundle_registry','registry_id')='msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq'
   AND EXISTS (
       SELECT 1
       FROM pg_catalog.pg_attribute a
       WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
         AND a.attname='registry_id'
         AND a.attidentity='a'
         AND a.attnotnull
   )
   AND EXISTS (
       SELECT 1 FROM pg_catalog.pg_depend d
       WHERE d.objid='msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq'::regclass
         AND d.refobjid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
         AND d.deptype='i'
   )), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0021_TOP_LEVEL_OBJECT',
            DETAIL='check_code=P220_PF_0021_TOP_LEVEL_OBJECT';
    END IF;
END;
$m212_r8_p220_pf_0021$;

/* R10 GOVERNED STATEMENT 0067 OF 0473
   statement_code: P220_PF_0022_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0022$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='a')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=1
  AND NOT a.attisdropped
  AND a.attname='policy_profile_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0022_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0022_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0022$;

/* R10 GOVERNED STATEMENT 0068 OF 0473
   statement_code: P220_PF_0023_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0023$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=2
  AND NOT a.attisdropped
  AND a.attname='module1_run_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0023_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0023_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0023$;

/* R10 GOVERNED STATEMENT 0069 OF 0473
   statement_code: P220_PF_0024_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0024$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=3
  AND NOT a.attisdropped
  AND a.attname='policy_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0024_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0024_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0024$;

/* R10 GOVERNED STATEMENT 0070 OF 0473
   statement_code: P220_PF_0025_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0025$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=4
  AND NOT a.attisdropped
  AND a.attname='policy_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0025_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0025_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0025$;

/* R10 GOVERNED STATEMENT 0071 OF 0473
   statement_code: P220_PF_0026_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0026$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=5
  AND NOT a.attisdropped
  AND a.attname='policy_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0026_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0026_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0026$;

/* R10 GOVERNED STATEMENT 0072 OF 0473
   statement_code: P220_PF_0027_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0027$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=6
  AND NOT a.attisdropped
  AND a.attname='methodology_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0027_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0027_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0027$;

/* R10 GOVERNED STATEMENT 0073 OF 0473
   statement_code: P220_PF_0028_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0028$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=7
  AND NOT a.attisdropped
  AND a.attname='bundle_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0028_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0028_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0028$;

/* R10 GOVERNED STATEMENT 0074 OF 0473
   statement_code: P220_PF_0029_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0029$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=8
  AND NOT a.attisdropped
  AND a.attname='bundle_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0029_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0029_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0029$;

/* R10 GOVERNED STATEMENT 0075 OF 0473
   statement_code: P220_PF_0030_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0030$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=9
  AND NOT a.attisdropped
  AND a.attname='schema_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0030_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0030_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0030$;

/* R10 GOVERNED STATEMENT 0076 OF 0473
   statement_code: P220_PF_0031_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0031$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=10
  AND NOT a.attisdropped
  AND a.attname='acceptance_gate_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0031_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0031_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0031$;

/* R10 GOVERNED STATEMENT 0077 OF 0473
   statement_code: P220_PF_0032_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0032$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=11
  AND NOT a.attisdropped
  AND a.attname='accepted_m2_11_project_sha256'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0032_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0032_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0032$;

/* R10 GOVERNED STATEMENT 0078 OF 0473
   statement_code: P220_PF_0033_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0033$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=12
  AND NOT a.attisdropped
  AND a.attname='accepted_m2_11_contract_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0033_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0033_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0033$;

/* R10 GOVERNED STATEMENT 0079 OF 0473
   statement_code: P220_PF_0034_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0034$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=13
  AND NOT a.attisdropped
  AND a.attname='accepted_m2_11_combined_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0034_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0034_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0034$;

/* R10 GOVERNED STATEMENT 0080 OF 0473
   statement_code: P220_PF_0035_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0035$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=14
  AND NOT a.attisdropped
  AND a.attname='accepted_m2_11_registry_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0035_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0035_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0035$;

/* R10 GOVERNED STATEMENT 0081 OF 0473
   statement_code: P220_PF_0036_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0036$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=15
  AND NOT a.attisdropped
  AND a.attname='expected_source_node_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0036_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0036_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0036$;

/* R10 GOVERNED STATEMENT 0082 OF 0473
   statement_code: P220_PF_0037_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0037$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=16
  AND NOT a.attisdropped
  AND a.attname='expected_component_contract_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0037_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0037_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0037$;

/* R10 GOVERNED STATEMENT 0083 OF 0473
   statement_code: P220_PF_0038_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0038$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=17
  AND NOT a.attisdropped
  AND a.attname='expected_source_graph_edge_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0038_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0038_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0038$;

/* R10 GOVERNED STATEMENT 0084 OF 0473
   statement_code: P220_PF_0039_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0039$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=18
  AND NOT a.attisdropped
  AND a.attname='expected_evidence_certification_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0039_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0039_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0039$;

/* R10 GOVERNED STATEMENT 0085 OF 0473
   statement_code: P220_PF_0040_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0040$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=19
  AND NOT a.attisdropped
  AND a.attname='expected_contract_reproduction_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0040_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0040_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0040$;

/* R10 GOVERNED STATEMENT 0086 OF 0473
   statement_code: P220_PF_0041_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0041$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=20
  AND NOT a.attisdropped
  AND a.attname='expected_capability_coverage_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0041_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0041_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0041$;

/* R10 GOVERNED STATEMENT 0087 OF 0473
   statement_code: P220_PF_0042_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0042$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=21
  AND NOT a.attisdropped
  AND a.attname='expected_canonical_family_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0042_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0042_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0042$;

/* R10 GOVERNED STATEMENT 0088 OF 0473
   statement_code: P220_PF_0043_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0043$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=22
  AND NOT a.attisdropped
  AND a.attname='expected_canonical_entities'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0043_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0043_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0043$;

/* R10 GOVERNED STATEMENT 0089 OF 0473
   statement_code: P220_PF_0044_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0044$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=23
  AND NOT a.attisdropped
  AND a.attname='expected_application_consumption_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0044_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0044_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0044$;

/* R10 GOVERNED STATEMENT 0090 OF 0473
   statement_code: P220_PF_0045_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0045$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=24
  AND NOT a.attisdropped
  AND a.attname='expected_operational_account_consumption_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0045_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0045_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0045$;

/* R10 GOVERNED STATEMENT 0091 OF 0473
   statement_code: P220_PF_0046_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0046$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=25
  AND NOT a.attisdropped
  AND a.attname='expected_strategy_scope_consumption_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0046_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0046_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0046$;

/* R10 GOVERNED STATEMENT 0092 OF 0473
   statement_code: P220_PF_0047_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0047$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=26
  AND NOT a.attisdropped
  AND a.attname='expected_generation_evidence_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0047_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0047_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0047$;

/* R10 GOVERNED STATEMENT 0093 OF 0473
   statement_code: P220_PF_0048_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0048$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=27
  AND NOT a.attisdropped
  AND a.attname='expected_positive_controls'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0048_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0048_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0048$;

/* R10 GOVERNED STATEMENT 0094 OF 0473
   statement_code: P220_PF_0049_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0049$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=28
  AND NOT a.attisdropped
  AND a.attname='expected_negative_controls'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0049_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0049_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0049$;

/* R10 GOVERNED STATEMENT 0095 OF 0473
   statement_code: P220_PF_0050_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0050$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=29
  AND NOT a.attisdropped
  AND a.attname='expected_acceptance_requirements'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0050_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0050_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0050$;

/* R10 GOVERNED STATEMENT 0096 OF 0473
   statement_code: P220_PF_0051_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0051$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=30
  AND NOT a.attisdropped
  AND a.attname='expected_detail_result_sets'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0051_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0051_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0051$;

/* R10 GOVERNED STATEMENT 0097 OF 0473
   statement_code: P220_PF_0052_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0052$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=31
  AND NOT a.attisdropped
  AND a.attname='synthetic_data_only_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0052_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0052_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0052$;

/* R10 GOVERNED STATEMENT 0098 OF 0473
   statement_code: P220_PF_0053_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0053$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=32
  AND NOT a.attisdropped
  AND a.attname='no_pii_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0053_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0053_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0053$;

/* R10 GOVERNED STATEMENT 0099 OF 0473
   statement_code: P220_PF_0054_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0054$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=33
  AND NOT a.attisdropped
  AND a.attname='certification_only_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0054_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0054_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0054$;

/* R10 GOVERNED STATEMENT 0100 OF 0473
   statement_code: P220_PF_0055_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0055$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=34
  AND NOT a.attisdropped
  AND a.attname='production_action_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0055_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0055_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0055$;

/* R10 GOVERNED STATEMENT 0101 OF 0473
   statement_code: P220_PF_0056_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0056$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=35
  AND NOT a.attisdropped
  AND a.attname='external_system_update_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0056_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0056_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0056$;

/* R10 GOVERNED STATEMENT 0102 OF 0473
   statement_code: P220_PF_0057_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0057$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=36
  AND NOT a.attisdropped
  AND a.attname='legal_or_regulatory_certified_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0057_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0057_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0057$;

/* R10 GOVERNED STATEMENT 0103 OF 0473
   statement_code: P220_PF_0058_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0058$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=37
  AND NOT a.attisdropped
  AND a.attname='empirical_or_causal_optimization_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0058_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0058_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0058$;

/* R10 GOVERNED STATEMENT 0104 OF 0473
   statement_code: P220_PF_0059_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0059$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=38
  AND NOT a.attisdropped
  AND a.attname='module3_sql_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0059_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0059_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0059$;

/* R10 GOVERNED STATEMENT 0105 OF 0473
   statement_code: P220_PF_0060_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0060$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=39
  AND NOT a.attisdropped
  AND a.attname='module3_execution_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0060_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0060_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0060$;

/* R10 GOVERNED STATEMENT 0106 OF 0473
   statement_code: P220_PF_0061_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0061$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='jsonb')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=40
  AND NOT a.attisdropped
  AND a.attname='configuration_payload'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0061_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0061_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0061$;

/* R10 GOVERNED STATEMENT 0107 OF 0473
   statement_code: P220_PF_0062_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0062$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=41
  AND NOT a.attisdropped
  AND a.attname='configuration_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0062_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0062_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0062$;

/* R10 GOVERNED STATEMENT 0108 OF 0473
   statement_code: P220_PF_0063_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0063$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=42
  AND NOT a.attisdropped
  AND a.attname='row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0063_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0063_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0063$;

/* R10 GOVERNED STATEMENT 0109 OF 0473
   statement_code: P220_PF_0064_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0064$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=43
  AND NOT a.attisdropped
  AND a.attname='created_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0064_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0064_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0064$;

/* R10 GOVERNED STATEMENT 0110 OF 0473
   statement_code: P220_PF_0065_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0065$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
  AND a.attnum=44
  AND NOT a.attisdropped
  AND a.attname='updated_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0065_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0065_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0065$;

/* R10 GOVERNED STATEMENT 0111 OF 0473
   statement_code: P220_PF_0066_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0066$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=1
  AND NOT a.attisdropped
  AND a.attname='module1_run_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0066_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0066_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0066$;

/* R10 GOVERNED STATEMENT 0112 OF 0473
   statement_code: P220_PF_0067_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0067$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='smallint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=2
  AND NOT a.attisdropped
  AND a.attname='certification_node_sequence'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0067_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0067_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0067$;

/* R10 GOVERNED STATEMENT 0113 OF 0473
   statement_code: P220_PF_0068_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0068$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=3
  AND NOT a.attisdropped
  AND a.attname='stage_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0068_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0068_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0068$;

/* R10 GOVERNED STATEMENT 0114 OF 0473
   statement_code: P220_PF_0069_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0069$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=4
  AND NOT a.attisdropped
  AND a.attname='repository_stage'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0069_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0069_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0069$;

/* R10 GOVERNED STATEMENT 0115 OF 0473
   statement_code: P220_PF_0070_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0070$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=5
  AND NOT a.attisdropped
  AND a.attname='module_title'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0070_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0070_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0070$;

/* R10 GOVERNED STATEMENT 0116 OF 0473
   statement_code: P220_PF_0071_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0071$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=6
  AND NOT a.attisdropped
  AND a.attname='registry_relation'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0071_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0071_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0071$;

/* R10 GOVERNED STATEMENT 0117 OF 0473
   statement_code: P220_PF_0072_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0072$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=7
  AND NOT a.attisdropped
  AND a.attname='acceptance_gate_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0072_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0072_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0072$;

/* R10 GOVERNED STATEMENT 0118 OF 0473
   statement_code: P220_PF_0073_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0073$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=8
  AND NOT a.attisdropped
  AND a.attname='acceptance_gate_review_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0073_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0073_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0073$;

/* R10 GOVERNED STATEMENT 0119 OF 0473
   statement_code: P220_PF_0074_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0074$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=9
  AND NOT a.attisdropped
  AND a.attname='acceptance_evidence_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0074_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0074_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0074$;

/* R10 GOVERNED STATEMENT 0120 OF 0473
   statement_code: P220_PF_0075_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0075$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=10
  AND NOT a.attisdropped
  AND a.attname='contract_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0075_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0075_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0075$;

/* R10 GOVERNED STATEMENT 0121 OF 0473
   statement_code: P220_PF_0076_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0076$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=11
  AND NOT a.attisdropped
  AND a.attname='gate_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0076_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0076_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0076$;

/* R10 GOVERNED STATEMENT 0122 OF 0473
   statement_code: P220_PF_0077_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0077$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=12
  AND NOT a.attisdropped
  AND a.attname='acceptance_evidence_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0077_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0077_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0077$;

/* R10 GOVERNED STATEMENT 0123 OF 0473
   statement_code: P220_PF_0078_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0078$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=13
  AND NOT a.attisdropped
  AND a.attname='historical_acceptance_method'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0078_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0078_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0078$;

/* R10 GOVERNED STATEMENT 0124 OF 0473
   statement_code: P220_PF_0079_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0079$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=14
  AND NOT a.attisdropped
  AND a.attname='expected_canonical_entities'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0079_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0079_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0079$;

/* R10 GOVERNED STATEMENT 0125 OF 0473
   statement_code: P220_PF_0080_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0080$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=15
  AND NOT a.attisdropped
  AND a.attname='observed_canonical_entities'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0080_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0080_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0080$;

/* R10 GOVERNED STATEMENT 0126 OF 0473
   statement_code: P220_PF_0081_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0081$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=16
  AND NOT a.attisdropped
  AND a.attname='expected_positive_controls'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0081_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0081_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0081$;

/* R10 GOVERNED STATEMENT 0127 OF 0473
   statement_code: P220_PF_0082_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0082$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=17
  AND NOT a.attisdropped
  AND a.attname='observed_positive_controls'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0082_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0082_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0082$;

/* R10 GOVERNED STATEMENT 0128 OF 0473
   statement_code: P220_PF_0083_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0083$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=18
  AND NOT a.attisdropped
  AND a.attname='expected_negative_controls'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0083_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0083_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0083$;

/* R10 GOVERNED STATEMENT 0129 OF 0473
   statement_code: P220_PF_0084_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0084$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=19
  AND NOT a.attisdropped
  AND a.attname='observed_negative_controls'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0084_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0084_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0084$;

/* R10 GOVERNED STATEMENT 0130 OF 0473
   statement_code: P220_PF_0085_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0085$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=20
  AND NOT a.attisdropped
  AND a.attname='expected_combined_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0085_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0085_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0085$;

/* R10 GOVERNED STATEMENT 0131 OF 0473
   statement_code: P220_PF_0086_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0086$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=21
  AND NOT a.attisdropped
  AND a.attname='observed_combined_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0086_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0086_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0086$;

/* R10 GOVERNED STATEMENT 0132 OF 0473
   statement_code: P220_PF_0087_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0087$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=22
  AND NOT a.attisdropped
  AND a.attname='source_registry_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0087_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0087_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0087$;

/* R10 GOVERNED STATEMENT 0133 OF 0473
   statement_code: P220_PF_0088_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0088$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='smallint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=23
  AND NOT a.attisdropped
  AND a.attname='required_source_edge_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0088_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0088_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0088$;

/* R10 GOVERNED STATEMENT 0134 OF 0473
   statement_code: P220_PF_0089_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0089$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='smallint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=24
  AND NOT a.attisdropped
  AND a.attname='passed_source_edge_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0089_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0089_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0089$;

/* R10 GOVERNED STATEMENT 0135 OF 0473
   statement_code: P220_PF_0090_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0090$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=25
  AND NOT a.attisdropped
  AND a.attname='source_graph_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0090_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0090_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0090$;

/* R10 GOVERNED STATEMENT 0136 OF 0473
   statement_code: P220_PF_0091_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0091$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=26
  AND NOT a.attisdropped
  AND a.attname='canonical_identity_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0091_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0091_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0091$;

/* R10 GOVERNED STATEMENT 0137 OF 0473
   statement_code: P220_PF_0092_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0092$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=27
  AND NOT a.attisdropped
  AND a.attname='stage_boundary_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0092_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0092_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0092$;

/* R10 GOVERNED STATEMENT 0138 OF 0473
   statement_code: P220_PF_0093_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0093$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=28
  AND NOT a.attisdropped
  AND a.attname='certification_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0093_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0093_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0093$;

/* R10 GOVERNED STATEMENT 0139 OF 0473
   statement_code: P220_PF_0094_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0094$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=29
  AND NOT a.attisdropped
  AND a.attname='interpretation'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0094_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0094_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0094$;

/* R10 GOVERNED STATEMENT 0140 OF 0473
   statement_code: P220_PF_0095_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0095$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=30
  AND NOT a.attisdropped
  AND a.attname='row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0095_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0095_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0095$;

/* R10 GOVERNED STATEMENT 0141 OF 0473
   statement_code: P220_PF_0096_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0096$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_stage_certification_snapshot'::regclass
  AND a.attnum=31
  AND NOT a.attisdropped
  AND a.attname='created_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0096_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0096_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0096$;

/* R10 GOVERNED STATEMENT 0142 OF 0473
   statement_code: P220_PF_0097_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0097$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=1
  AND NOT a.attisdropped
  AND a.attname='module1_run_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0097_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0097_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0097$;

/* R10 GOVERNED STATEMENT 0143 OF 0473
   statement_code: P220_PF_0098_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0098$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='smallint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=2
  AND NOT a.attisdropped
  AND a.attname='certification_node_sequence'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0098_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0098_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0098$;

/* R10 GOVERNED STATEMENT 0144 OF 0473
   statement_code: P220_PF_0099_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0099$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=3
  AND NOT a.attisdropped
  AND a.attname='stage_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0099_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0099_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0099$;

/* R10 GOVERNED STATEMENT 0145 OF 0473
   statement_code: P220_PF_0100_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0100$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=4
  AND NOT a.attisdropped
  AND a.attname='repository_stage'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0100_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0100_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0100$;

/* R10 GOVERNED STATEMENT 0146 OF 0473
   statement_code: P220_PF_0101_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0101$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=5
  AND NOT a.attisdropped
  AND a.attname='module_title'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0101_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0101_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0101$;

/* R10 GOVERNED STATEMENT 0147 OF 0473
   statement_code: P220_PF_0102_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0102$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='smallint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=6
  AND NOT a.attisdropped
  AND a.attname='component_sequence'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0102_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0102_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0102$;

/* R10 GOVERNED STATEMENT 0148 OF 0473
   statement_code: P220_PF_0103_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0103$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=7
  AND NOT a.attisdropped
  AND a.attname='component_contract_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0103_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0103_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0103$;

/* R10 GOVERNED STATEMENT 0149 OF 0473
   statement_code: P220_PF_0104_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0104$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=8
  AND NOT a.attisdropped
  AND a.attname='contract_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0104_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0104_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0104$;

/* R10 GOVERNED STATEMENT 0150 OF 0473
   statement_code: P220_PF_0105_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0105$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=9
  AND NOT a.attisdropped
  AND a.attname='schema_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0105_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0105_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0105$;

/* R10 GOVERNED STATEMENT 0151 OF 0473
   statement_code: P220_PF_0106_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0106$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=10
  AND NOT a.attisdropped
  AND a.attname='methodology_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0106_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0106_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0106$;

/* R10 GOVERNED STATEMENT 0152 OF 0473
   statement_code: P220_PF_0107_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0107$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=11
  AND NOT a.attisdropped
  AND a.attname='acceptance_gate_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0107_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0107_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0107$;

/* R10 GOVERNED STATEMENT 0153 OF 0473
   statement_code: P220_PF_0108_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0108$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=12
  AND NOT a.attisdropped
  AND a.attname='registry_relation'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0108_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0108_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0108$;

/* R10 GOVERNED STATEMENT 0154 OF 0473
   statement_code: P220_PF_0109_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0109$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=13
  AND NOT a.attisdropped
  AND a.attname='latest_relation'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0109_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0109_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0109$;

/* R10 GOVERNED STATEMENT 0155 OF 0473
   statement_code: P220_PF_0110_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0110$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=14
  AND NOT a.attisdropped
  AND a.attname='archive_relation'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0110_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0110_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0110$;

/* R10 GOVERNED STATEMENT 0156 OF 0473
   statement_code: P220_PF_0111_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0111$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=15
  AND NOT a.attisdropped
  AND a.attname='latest_business_grain'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0111_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0111_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0111$;

/* R10 GOVERNED STATEMENT 0157 OF 0473
   statement_code: P220_PF_0112_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0112$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='jsonb')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=16
  AND NOT a.attisdropped
  AND a.attname='latest_business_key_columns'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0112_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0112_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0112$;

/* R10 GOVERNED STATEMENT 0158 OF 0473
   statement_code: P220_PF_0113_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0113$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='jsonb')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=17
  AND NOT a.attisdropped
  AND a.attname='archive_business_key_columns'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0113_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0113_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0113$;

/* R10 GOVERNED STATEMENT 0159 OF 0473
   statement_code: P220_PF_0114_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0114$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=18
  AND NOT a.attisdropped
  AND a.attname='expected_latest_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0114_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0114_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0114$;

/* R10 GOVERNED STATEMENT 0160 OF 0473
   statement_code: P220_PF_0115_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0115$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=19
  AND NOT a.attisdropped
  AND a.attname='observed_latest_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0115_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0115_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0115$;

/* R10 GOVERNED STATEMENT 0161 OF 0473
   statement_code: P220_PF_0116_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0116$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=20
  AND NOT a.attisdropped
  AND a.attname='expected_archive_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0116_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0116_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0116$;

/* R10 GOVERNED STATEMENT 0162 OF 0473
   statement_code: P220_PF_0117_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0117$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=21
  AND NOT a.attisdropped
  AND a.attname='observed_archive_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0117_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0117_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0117$;

/* R10 GOVERNED STATEMENT 0163 OF 0473
   statement_code: P220_PF_0118_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0118$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=22
  AND NOT a.attisdropped
  AND a.attname='stage_expected_canonical_entities'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0118_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0118_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0118$;

/* R10 GOVERNED STATEMENT 0164 OF 0473
   statement_code: P220_PF_0119_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0119$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=23
  AND NOT a.attisdropped
  AND a.attname='expected_positive_controls'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0119_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0119_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0119$;

/* R10 GOVERNED STATEMENT 0165 OF 0473
   statement_code: P220_PF_0120_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0120$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=24
  AND NOT a.attisdropped
  AND a.attname='observed_positive_controls'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0120_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0120_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0120$;

/* R10 GOVERNED STATEMENT 0166 OF 0473
   statement_code: P220_PF_0121_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0121$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=25
  AND NOT a.attisdropped
  AND a.attname='expected_negative_controls'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0121_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0121_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0121$;

/* R10 GOVERNED STATEMENT 0167 OF 0473
   statement_code: P220_PF_0122_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0122$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=26
  AND NOT a.attisdropped
  AND a.attname='observed_negative_controls'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0122_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0122_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0122$;

/* R10 GOVERNED STATEMENT 0168 OF 0473
   statement_code: P220_PF_0123_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0123$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=27
  AND NOT a.attisdropped
  AND a.attname='expected_contract_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0123_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0123_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0123$;

/* R10 GOVERNED STATEMENT 0169 OF 0473
   statement_code: P220_PF_0124_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0124$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=28
  AND NOT a.attisdropped
  AND a.attname='observed_contract_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0124_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0124_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0124$;

/* R10 GOVERNED STATEMENT 0170 OF 0473
   statement_code: P220_PF_0125_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0125$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=29
  AND NOT a.attisdropped
  AND a.attname='expected_stage_combined_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0125_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0125_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0125$;

/* R10 GOVERNED STATEMENT 0171 OF 0473
   statement_code: P220_PF_0126_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0126$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=30
  AND NOT a.attisdropped
  AND a.attname='observed_stage_combined_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0126_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0126_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0126$;

/* R10 GOVERNED STATEMENT 0172 OF 0473
   statement_code: P220_PF_0127_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0127$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=31
  AND NOT a.attisdropped
  AND a.attname='expected_registry_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0127_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0127_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0127$;

/* R10 GOVERNED STATEMENT 0173 OF 0473
   statement_code: P220_PF_0128_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0128$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=32
  AND NOT a.attisdropped
  AND a.attname='observed_registry_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0128_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0128_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0128$;

/* R10 GOVERNED STATEMENT 0174 OF 0473
   statement_code: P220_PF_0129_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0129$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=33
  AND NOT a.attisdropped
  AND a.attname='expected_latest_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0129_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0129_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0129$;

/* R10 GOVERNED STATEMENT 0175 OF 0473
   statement_code: P220_PF_0130_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0130$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=34
  AND NOT a.attisdropped
  AND a.attname='observed_latest_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0130_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0130_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0130$;

/* R10 GOVERNED STATEMENT 0176 OF 0473
   statement_code: P220_PF_0131_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0131$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=35
  AND NOT a.attisdropped
  AND a.attname='expected_archive_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0131_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0131_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0131$;

/* R10 GOVERNED STATEMENT 0177 OF 0473
   statement_code: P220_PF_0132_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0132$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=36
  AND NOT a.attisdropped
  AND a.attname='observed_archive_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0132_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0132_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0132$;

/* R10 GOVERNED STATEMENT 0178 OF 0473
   statement_code: P220_PF_0133_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0133$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=37
  AND NOT a.attisdropped
  AND a.attname='contract_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0133_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0133_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0133$;

/* R10 GOVERNED STATEMENT 0179 OF 0473
   statement_code: P220_PF_0134_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0134$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=38
  AND NOT a.attisdropped
  AND a.attname='gate_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0134_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0134_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0134$;

/* R10 GOVERNED STATEMENT 0180 OF 0473
   statement_code: P220_PF_0135_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0135$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=39
  AND NOT a.attisdropped
  AND a.attname='acceptance_evidence_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0135_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0135_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0135$;

/* R10 GOVERNED STATEMENT 0181 OF 0473
   statement_code: P220_PF_0136_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0136$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=40
  AND NOT a.attisdropped
  AND a.attname='acceptance_evidence_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0136_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0136_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0136$;

/* R10 GOVERNED STATEMENT 0182 OF 0473
   statement_code: P220_PF_0137_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0137$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text[]')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=41
  AND NOT a.attisdropped
  AND a.attname='required_source_edge_codes'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0137_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0137_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0137$;

/* R10 GOVERNED STATEMENT 0183 OF 0473
   statement_code: P220_PF_0138_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0138$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='smallint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=42
  AND NOT a.attisdropped
  AND a.attname='required_source_edge_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0138_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0138_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0138$;

/* R10 GOVERNED STATEMENT 0184 OF 0473
   statement_code: P220_PF_0139_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0139$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='smallint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=43
  AND NOT a.attisdropped
  AND a.attname='passed_source_edge_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0139_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0139_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0139$;

/* R10 GOVERNED STATEMENT 0185 OF 0473
   statement_code: P220_PF_0140_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0140$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=44
  AND NOT a.attisdropped
  AND a.attname='certification_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0140_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0140_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0140$;

/* R10 GOVERNED STATEMENT 0186 OF 0473
   statement_code: P220_PF_0141_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0141$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=45
  AND NOT a.attisdropped
  AND a.attname='row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0141_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0141_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0141$;

/* R10 GOVERNED STATEMENT 0187 OF 0473
   statement_code: P220_PF_0142_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0142$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_component_snapshot'::regclass
  AND a.attnum=46
  AND NOT a.attisdropped
  AND a.attname='created_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0142_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0142_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0142$;

/* R10 GOVERNED STATEMENT 0188 OF 0473
   statement_code: P220_PF_0143_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0143$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=1
  AND NOT a.attisdropped
  AND a.attname='module1_run_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0143_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0143_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0143$;

/* R10 GOVERNED STATEMENT 0189 OF 0473
   statement_code: P220_PF_0144_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0144$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='smallint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=2
  AND NOT a.attisdropped
  AND a.attname='node_sequence'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0144_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0144_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0144$;

/* R10 GOVERNED STATEMENT 0190 OF 0473
   statement_code: P220_PF_0145_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0145$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=3
  AND NOT a.attisdropped
  AND a.attname='stage_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0145_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0145_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0145$;

/* R10 GOVERNED STATEMENT 0191 OF 0473
   statement_code: P220_PF_0146_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0146$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='smallint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=4
  AND NOT a.attisdropped
  AND a.attname='evidence_family_sequence'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0146_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0146_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0146$;

/* R10 GOVERNED STATEMENT 0192 OF 0473
   statement_code: P220_PF_0147_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0147$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=5
  AND NOT a.attisdropped
  AND a.attname='evidence_family_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0147_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0147_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0147$;

/* R10 GOVERNED STATEMENT 0193 OF 0473
   statement_code: P220_PF_0148_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0148$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=6
  AND NOT a.attisdropped
  AND a.attname='applicability_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0148_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0148_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0148$;

/* R10 GOVERNED STATEMENT 0194 OF 0473
   statement_code: P220_PF_0149_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0149$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=7
  AND NOT a.attisdropped
  AND a.attname='allowed_certification_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0149_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0149_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0149$;

/* R10 GOVERNED STATEMENT 0195 OF 0473
   statement_code: P220_PF_0150_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0150$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=8
  AND NOT a.attisdropped
  AND a.attname='authoritative_source_locator'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0150_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0150_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0150$;

/* R10 GOVERNED STATEMENT 0196 OF 0473
   statement_code: P220_PF_0151_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0151$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=9
  AND NOT a.attisdropped
  AND a.attname='evidence_code_or_method_pattern'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0151_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0151_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0151$;

/* R10 GOVERNED STATEMENT 0197 OF 0473
   statement_code: P220_PF_0152_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0152$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=10
  AND NOT a.attisdropped
  AND a.attname='expected_count_or_identity'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0152_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0152_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0152$;

/* R10 GOVERNED STATEMENT 0198 OF 0473
   statement_code: P220_PF_0153_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0153$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=11
  AND NOT a.attisdropped
  AND a.attname='observed_count_or_identity'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0153_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0153_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0153$;

/* R10 GOVERNED STATEMENT 0199 OF 0473
   statement_code: P220_PF_0154_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0154$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=12
  AND NOT a.attisdropped
  AND a.attname='expected_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0154_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0154_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0154$;

/* R10 GOVERNED STATEMENT 0200 OF 0473
   statement_code: P220_PF_0155_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0155$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=13
  AND NOT a.attisdropped
  AND a.attname='observed_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0155_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0155_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0155$;

/* R10 GOVERNED STATEMENT 0201 OF 0473
   statement_code: P220_PF_0156_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0156$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=false)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=14
  AND NOT a.attisdropped
  AND a.attname='expected_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0156_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0156_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0156$;

/* R10 GOVERNED STATEMENT 0202 OF 0473
   statement_code: P220_PF_0157_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0157$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=false)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=15
  AND NOT a.attisdropped
  AND a.attname='observed_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0157_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0157_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0157$;

/* R10 GOVERNED STATEMENT 0203 OF 0473
   statement_code: P220_PF_0158_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0158$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=16
  AND NOT a.attisdropped
  AND a.attname='mismatch_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0158_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0158_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0158$;

/* R10 GOVERNED STATEMENT 0204 OF 0473
   statement_code: P220_PF_0159_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0159$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=17
  AND NOT a.attisdropped
  AND a.attname='source_registry_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0159_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0159_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0159$;

/* R10 GOVERNED STATEMENT 0205 OF 0473
   statement_code: P220_PF_0160_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0160$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=false)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=18
  AND NOT a.attisdropped
  AND a.attname='source_evidence_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0160_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0160_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0160$;

/* R10 GOVERNED STATEMENT 0206 OF 0473
   statement_code: P220_PF_0161_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0161$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=19
  AND NOT a.attisdropped
  AND a.attname='certification_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0161_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0161_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0161$;

/* R10 GOVERNED STATEMENT 0207 OF 0473
   statement_code: P220_PF_0162_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0162$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=20
  AND NOT a.attisdropped
  AND a.attname='interpretation'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0162_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0162_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0162$;

/* R10 GOVERNED STATEMENT 0208 OF 0473
   statement_code: P220_PF_0163_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0163$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=21
  AND NOT a.attisdropped
  AND a.attname='row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0163_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0163_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0163$;

/* R10 GOVERNED STATEMENT 0209 OF 0473
   statement_code: P220_PF_0164_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0164$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass
  AND a.attnum=22
  AND NOT a.attisdropped
  AND a.attname='created_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0164_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0164_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0164$;

/* R10 GOVERNED STATEMENT 0210 OF 0473
   statement_code: P220_PF_0165_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0165$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=1
  AND NOT a.attisdropped
  AND a.attname='module1_run_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0165_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0165_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0165$;

/* R10 GOVERNED STATEMENT 0211 OF 0473
   statement_code: P220_PF_0166_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0166$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='smallint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=2
  AND NOT a.attisdropped
  AND a.attname='component_sequence'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0166_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0166_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0166$;

/* R10 GOVERNED STATEMENT 0212 OF 0473
   statement_code: P220_PF_0167_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0167$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=3
  AND NOT a.attisdropped
  AND a.attname='stage_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0167_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0167_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0167$;

/* R10 GOVERNED STATEMENT 0213 OF 0473
   statement_code: P220_PF_0168_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0168$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=4
  AND NOT a.attisdropped
  AND a.attname='component_contract_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0168_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0168_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0168$;

/* R10 GOVERNED STATEMENT 0214 OF 0473
   statement_code: P220_PF_0169_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0169$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=5
  AND NOT a.attisdropped
  AND a.attname='contract_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0169_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0169_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0169$;

/* R10 GOVERNED STATEMENT 0215 OF 0473
   statement_code: P220_PF_0170_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0170$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=6
  AND NOT a.attisdropped
  AND a.attname='schema_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0170_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0170_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0170$;

/* R10 GOVERNED STATEMENT 0216 OF 0473
   statement_code: P220_PF_0171_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0171$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=7
  AND NOT a.attisdropped
  AND a.attname='methodology_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0171_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0171_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0171$;

/* R10 GOVERNED STATEMENT 0217 OF 0473
   statement_code: P220_PF_0172_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0172$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=8
  AND NOT a.attisdropped
  AND a.attname='registry_relation'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0172_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0172_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0172$;

/* R10 GOVERNED STATEMENT 0218 OF 0473
   statement_code: P220_PF_0173_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0173$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=9
  AND NOT a.attisdropped
  AND a.attname='latest_relation'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0173_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0173_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0173$;

/* R10 GOVERNED STATEMENT 0219 OF 0473
   statement_code: P220_PF_0174_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0174$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=10
  AND NOT a.attisdropped
  AND a.attname='archive_relation'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0174_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0174_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0174$;

/* R10 GOVERNED STATEMENT 0220 OF 0473
   statement_code: P220_PF_0175_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0175$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=11
  AND NOT a.attisdropped
  AND a.attname='latest_business_grain'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0175_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0175_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0175$;

/* R10 GOVERNED STATEMENT 0221 OF 0473
   statement_code: P220_PF_0176_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0176$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='jsonb')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=12
  AND NOT a.attisdropped
  AND a.attname='latest_business_key_columns'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0176_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0176_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0176$;

/* R10 GOVERNED STATEMENT 0222 OF 0473
   statement_code: P220_PF_0177_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0177$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='jsonb')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=13
  AND NOT a.attisdropped
  AND a.attname='archive_business_key_columns'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0177_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0177_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0177$;

/* R10 GOVERNED STATEMENT 0223 OF 0473
   statement_code: P220_PF_0178_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0178$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=14
  AND NOT a.attisdropped
  AND a.attname='expected_latest_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0178_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0178_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0178$;

/* R10 GOVERNED STATEMENT 0224 OF 0473
   statement_code: P220_PF_0179_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0179$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=15
  AND NOT a.attisdropped
  AND a.attname='observed_latest_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0179_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0179_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0179$;

/* R10 GOVERNED STATEMENT 0225 OF 0473
   statement_code: P220_PF_0180_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0180$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=16
  AND NOT a.attisdropped
  AND a.attname='expected_archive_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0180_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0180_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0180$;

/* R10 GOVERNED STATEMENT 0226 OF 0473
   statement_code: P220_PF_0181_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0181$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=17
  AND NOT a.attisdropped
  AND a.attname='observed_archive_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0181_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0181_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0181$;

/* R10 GOVERNED STATEMENT 0227 OF 0473
   statement_code: P220_PF_0182_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0182$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=18
  AND NOT a.attisdropped
  AND a.attname='expected_latest_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0182_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0182_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0182$;

/* R10 GOVERNED STATEMENT 0228 OF 0473
   statement_code: P220_PF_0183_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0183$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=19
  AND NOT a.attisdropped
  AND a.attname='observed_latest_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0183_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0183_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0183$;

/* R10 GOVERNED STATEMENT 0229 OF 0473
   statement_code: P220_PF_0184_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0184$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=20
  AND NOT a.attisdropped
  AND a.attname='expected_archive_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0184_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0184_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0184$;

/* R10 GOVERNED STATEMENT 0230 OF 0473
   statement_code: P220_PF_0185_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0185$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=21
  AND NOT a.attisdropped
  AND a.attname='observed_archive_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0185_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0185_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0185$;

/* R10 GOVERNED STATEMENT 0231 OF 0473
   statement_code: P220_PF_0186_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0186$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=22
  AND NOT a.attisdropped
  AND a.attname='payload_mismatch_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0186_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0186_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0186$;

/* R10 GOVERNED STATEMENT 0232 OF 0473
   statement_code: P220_PF_0187_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0187$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=23
  AND NOT a.attisdropped
  AND a.attname='missing_latest_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0187_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0187_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0187$;

/* R10 GOVERNED STATEMENT 0233 OF 0473
   statement_code: P220_PF_0188_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0188$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=24
  AND NOT a.attisdropped
  AND a.attname='missing_archive_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0188_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0188_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0188$;

/* R10 GOVERNED STATEMENT 0234 OF 0473
   statement_code: P220_PF_0189_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0189$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=25
  AND NOT a.attisdropped
  AND a.attname='latest_duplicate_key_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0189_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0189_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0189$;

/* R10 GOVERNED STATEMENT 0235 OF 0473
   statement_code: P220_PF_0190_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0190$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=26
  AND NOT a.attisdropped
  AND a.attname='archive_duplicate_key_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0190_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0190_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0190$;

/* R10 GOVERNED STATEMENT 0236 OF 0473
   statement_code: P220_PF_0191_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0191$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=27
  AND NOT a.attisdropped
  AND a.attname='archive_trigger_name'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0191_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0191_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0191$;

/* R10 GOVERNED STATEMENT 0237 OF 0473
   statement_code: P220_PF_0192_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0192$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=28
  AND NOT a.attisdropped
  AND a.attname='archive_trigger_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0192_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0192_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0192$;

/* R10 GOVERNED STATEMENT 0238 OF 0473
   statement_code: P220_PF_0193_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0193$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=29
  AND NOT a.attisdropped
  AND a.attname='reproduction_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0193_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0193_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0193$;

/* R10 GOVERNED STATEMENT 0239 OF 0473
   statement_code: P220_PF_0194_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0194$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=30
  AND NOT a.attisdropped
  AND a.attname='source_registry_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0194_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0194_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0194$;

/* R10 GOVERNED STATEMENT 0240 OF 0473
   statement_code: P220_PF_0195_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0195$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=31
  AND NOT a.attisdropped
  AND a.attname='row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0195_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0195_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0195$;

/* R10 GOVERNED STATEMENT 0241 OF 0473
   statement_code: P220_PF_0196_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0196$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass
  AND a.attnum=32
  AND NOT a.attisdropped
  AND a.attname='created_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0196_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0196_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0196$;

/* R10 GOVERNED STATEMENT 0242 OF 0473
   statement_code: P220_PF_0197_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0197$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass
  AND a.attnum=1
  AND NOT a.attisdropped
  AND a.attname='module1_run_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0197_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0197_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0197$;

/* R10 GOVERNED STATEMENT 0243 OF 0473
   statement_code: P220_PF_0198_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0198$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='smallint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass
  AND a.attnum=2
  AND NOT a.attisdropped
  AND a.attname='capability_sequence'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0198_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0198_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0198$;

/* R10 GOVERNED STATEMENT 0244 OF 0473
   statement_code: P220_PF_0199_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0199$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass
  AND a.attnum=3
  AND NOT a.attisdropped
  AND a.attname='capability_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0199_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0199_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0199$;

/* R10 GOVERNED STATEMENT 0245 OF 0473
   statement_code: P220_PF_0200_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0200$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass
  AND a.attnum=4
  AND NOT a.attisdropped
  AND a.attname='coverage_status_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0200_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0200_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0200$;

/* R10 GOVERNED STATEMENT 0246 OF 0473
   statement_code: P220_PF_0201_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0201$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass
  AND a.attnum=5
  AND NOT a.attisdropped
  AND a.attname='certifying_stage_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0201_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0201_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0201$;

/* R10 GOVERNED STATEMENT 0247 OF 0473
   statement_code: P220_PF_0202_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0202$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass
  AND a.attnum=6
  AND NOT a.attisdropped
  AND a.attname='claim_boundary'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0202_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0202_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0202$;

/* R10 GOVERNED STATEMENT 0248 OF 0473
   statement_code: P220_PF_0203_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0203$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass
  AND a.attnum=7
  AND NOT a.attisdropped
  AND a.attname='production_action_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0203_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0203_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0203$;

/* R10 GOVERNED STATEMENT 0249 OF 0473
   statement_code: P220_PF_0204_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0204$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass
  AND a.attnum=8
  AND NOT a.attisdropped
  AND a.attname='legal_or_regulatory_certified_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0204_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0204_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0204$;

/* R10 GOVERNED STATEMENT 0250 OF 0473
   statement_code: P220_PF_0205_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0205$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass
  AND a.attnum=9
  AND NOT a.attisdropped
  AND a.attname='notes'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0205_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0205_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0205$;

/* R10 GOVERNED STATEMENT 0251 OF 0473
   statement_code: P220_PF_0206_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0206$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass
  AND a.attnum=10
  AND NOT a.attisdropped
  AND a.attname='row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0206_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0206_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0206$;

/* R10 GOVERNED STATEMENT 0252 OF 0473
   statement_code: P220_PF_0207_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0207$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass
  AND a.attnum=11
  AND NOT a.attisdropped
  AND a.attname='created_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0207_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0207_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0207$;

/* R10 GOVERNED STATEMENT 0253 OF 0473
   statement_code: P220_PF_0208_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0208$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=1
  AND NOT a.attisdropped
  AND a.attname='module1_run_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0208_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0208_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0208$;

/* R10 GOVERNED STATEMENT 0254 OF 0473
   statement_code: P220_PF_0209_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0209$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=2
  AND NOT a.attisdropped
  AND a.attname='bundle_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0209_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0209_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0209$;

/* R10 GOVERNED STATEMENT 0255 OF 0473
   statement_code: P220_PF_0210_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0210$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=3
  AND NOT a.attisdropped
  AND a.attname='contract_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0210_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0210_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0210$;

/* R10 GOVERNED STATEMENT 0256 OF 0473
   statement_code: P220_PF_0211_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0211$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=4
  AND NOT a.attisdropped
  AND a.attname='schema_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0211_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0211_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0211$;

/* R10 GOVERNED STATEMENT 0257 OF 0473
   statement_code: P220_PF_0212_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0212$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=5
  AND NOT a.attisdropped
  AND a.attname='methodology_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0212_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0212_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0212$;

/* R10 GOVERNED STATEMENT 0258 OF 0473
   statement_code: P220_PF_0213_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0213$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=6
  AND NOT a.attisdropped
  AND a.attname='acceptance_gate_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0213_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0213_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0213$;

/* R10 GOVERNED STATEMENT 0259 OF 0473
   statement_code: P220_PF_0214_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0214$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=7
  AND NOT a.attisdropped
  AND a.attname='run_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0214_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0214_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0214$;

/* R10 GOVERNED STATEMENT 0260 OF 0473
   statement_code: P220_PF_0215_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0215$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=8
  AND NOT a.attisdropped
  AND a.attname='run_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0215_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0215_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0215$;

/* R10 GOVERNED STATEMENT 0261 OF 0473
   statement_code: P220_PF_0216_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0216$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='date')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=9
  AND NOT a.attisdropped
  AND a.attname='as_of_date'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0216_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0216_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0216$;

/* R10 GOVERNED STATEMENT 0262 OF 0473
   statement_code: P220_PF_0217_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0217$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=10
  AND NOT a.attisdropped
  AND a.attname='source_m1_17_bundle_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0217_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0217_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0217$;

/* R10 GOVERNED STATEMENT 0263 OF 0473
   statement_code: P220_PF_0218_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0218$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=11
  AND NOT a.attisdropped
  AND a.attname='source_m1_17_bundle_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0218_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0218_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0218$;

/* R10 GOVERNED STATEMENT 0264 OF 0473
   statement_code: P220_PF_0219_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0219$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=12
  AND NOT a.attisdropped
  AND a.attname='source_m1_17_schema_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0219_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0219_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0219$;

/* R10 GOVERNED STATEMENT 0265 OF 0473
   statement_code: P220_PF_0220_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0220$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=13
  AND NOT a.attisdropped
  AND a.attname='source_m1_17_combined_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0220_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0220_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0220$;

/* R10 GOVERNED STATEMENT 0266 OF 0473
   statement_code: P220_PF_0221_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0221$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=14
  AND NOT a.attisdropped
  AND a.attname='source_m1_17_registry_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0221_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0221_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0221$;

/* R10 GOVERNED STATEMENT 0267 OF 0473
   statement_code: P220_PF_0222_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0222$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=15
  AND NOT a.attisdropped
  AND a.attname='source_m2_11_contract_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0222_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0222_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0222$;

/* R10 GOVERNED STATEMENT 0268 OF 0473
   statement_code: P220_PF_0223_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0223$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=16
  AND NOT a.attisdropped
  AND a.attname='source_m2_11_contract_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0223_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0223_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0223$;

/* R10 GOVERNED STATEMENT 0269 OF 0473
   statement_code: P220_PF_0224_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0224$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=17
  AND NOT a.attisdropped
  AND a.attname='source_m2_11_schema_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0224_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0224_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0224$;

/* R10 GOVERNED STATEMENT 0270 OF 0473
   statement_code: P220_PF_0225_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0225$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=18
  AND NOT a.attisdropped
  AND a.attname='source_m2_11_methodology_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0225_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0225_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0225$;

/* R10 GOVERNED STATEMENT 0271 OF 0473
   statement_code: P220_PF_0226_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0226$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=19
  AND NOT a.attisdropped
  AND a.attname='source_m2_11_contract_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0226_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0226_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0226$;

/* R10 GOVERNED STATEMENT 0272 OF 0473
   statement_code: P220_PF_0227_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0227$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=20
  AND NOT a.attisdropped
  AND a.attname='source_m2_11_combined_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0227_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0227_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0227$;

/* R10 GOVERNED STATEMENT 0273 OF 0473
   statement_code: P220_PF_0228_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0228$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=21
  AND NOT a.attisdropped
  AND a.attname='source_m2_11_registry_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0228_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0228_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0228$;

/* R10 GOVERNED STATEMENT 0274 OF 0473
   statement_code: P220_PF_0229_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0229$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=22
  AND NOT a.attisdropped
  AND a.attname='source_node_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0229_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0229_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0229$;

/* R10 GOVERNED STATEMENT 0275 OF 0473
   statement_code: P220_PF_0230_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0230$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=23
  AND NOT a.attisdropped
  AND a.attname='component_contract_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0230_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0230_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0230$;

/* R10 GOVERNED STATEMENT 0276 OF 0473
   statement_code: P220_PF_0231_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0231$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=24
  AND NOT a.attisdropped
  AND a.attname='source_graph_edge_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0231_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0231_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0231$;

/* R10 GOVERNED STATEMENT 0277 OF 0473
   statement_code: P220_PF_0232_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0232$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=25
  AND NOT a.attisdropped
  AND a.attname='evidence_certification_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0232_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0232_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0232$;

/* R10 GOVERNED STATEMENT 0278 OF 0473
   statement_code: P220_PF_0233_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0233$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=26
  AND NOT a.attisdropped
  AND a.attname='contract_reproduction_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0233_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0233_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0233$;

/* R10 GOVERNED STATEMENT 0279 OF 0473
   statement_code: P220_PF_0234_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0234$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=27
  AND NOT a.attisdropped
  AND a.attname='capability_coverage_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0234_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0234_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0234$;

/* R10 GOVERNED STATEMENT 0280 OF 0473
   statement_code: P220_PF_0235_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0235$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=28
  AND NOT a.attisdropped
  AND a.attname='canonical_family_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0235_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0235_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0235$;

/* R10 GOVERNED STATEMENT 0281 OF 0473
   statement_code: P220_PF_0236_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0236$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=29
  AND NOT a.attisdropped
  AND a.attname='canonical_entity_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0236_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0236_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0236$;

/* R10 GOVERNED STATEMENT 0282 OF 0473
   statement_code: P220_PF_0237_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0237$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=30
  AND NOT a.attisdropped
  AND a.attname='application_consumption_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0237_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0237_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0237$;

/* R10 GOVERNED STATEMENT 0283 OF 0473
   statement_code: P220_PF_0238_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0238$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=31
  AND NOT a.attisdropped
  AND a.attname='operational_account_consumption_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0238_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0238_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0238$;

/* R10 GOVERNED STATEMENT 0284 OF 0473
   statement_code: P220_PF_0239_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0239$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=32
  AND NOT a.attisdropped
  AND a.attname='strategy_scope_consumption_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0239_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0239_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0239$;

/* R10 GOVERNED STATEMENT 0285 OF 0473
   statement_code: P220_PF_0240_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0240$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=33
  AND NOT a.attisdropped
  AND a.attname='component_latest_rows_total'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0240_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0240_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0240$;

/* R10 GOVERNED STATEMENT 0286 OF 0473
   statement_code: P220_PF_0241_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0241$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=34
  AND NOT a.attisdropped
  AND a.attname='component_archive_rows_total'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0241_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0241_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0241$;

/* R10 GOVERNED STATEMENT 0287 OF 0473
   statement_code: P220_PF_0242_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0242$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=35
  AND NOT a.attisdropped
  AND a.attname='stage_local_canonical_reference_total'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0242_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0242_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0242$;

/* R10 GOVERNED STATEMENT 0288 OF 0473
   statement_code: P220_PF_0243_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0243$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=36
  AND NOT a.attisdropped
  AND a.attname='all_stage_certification_pass_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0243_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0243_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0243$;

/* R10 GOVERNED STATEMENT 0289 OF 0473
   statement_code: P220_PF_0244_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0244$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=37
  AND NOT a.attisdropped
  AND a.attname='all_component_contract_pass_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0244_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0244_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0244$;

/* R10 GOVERNED STATEMENT 0290 OF 0473
   statement_code: P220_PF_0245_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0245$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=38
  AND NOT a.attisdropped
  AND a.attname='all_evidence_certification_pass_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0245_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0245_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0245$;

/* R10 GOVERNED STATEMENT 0291 OF 0473
   statement_code: P220_PF_0246_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0246$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=39
  AND NOT a.attisdropped
  AND a.attname='all_contract_reproduction_pass_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0246_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0246_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0246$;

/* R10 GOVERNED STATEMENT 0292 OF 0473
   statement_code: P220_PF_0247_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0247$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=40
  AND NOT a.attisdropped
  AND a.attname='all_capability_boundary_pass_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0247_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0247_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0247$;

/* R10 GOVERNED STATEMENT 0293 OF 0473
   statement_code: P220_PF_0248_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0248$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=41
  AND NOT a.attisdropped
  AND a.attname='all_source_graph_edges_pass_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0248_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0248_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0248$;

/* R10 GOVERNED STATEMENT 0294 OF 0473
   statement_code: P220_PF_0249_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0249$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=42
  AND NOT a.attisdropped
  AND a.attname='as_built_certification_scope_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0249_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0249_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0249$;

/* R10 GOVERNED STATEMENT 0295 OF 0473
   statement_code: P220_PF_0250_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0250$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='jsonb')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=43
  AND NOT a.attisdropped
  AND a.attname='capability_summary'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0250_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0250_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0250$;

/* R10 GOVERNED STATEMENT 0296 OF 0473
   statement_code: P220_PF_0251_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0251$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='jsonb')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=44
  AND NOT a.attisdropped
  AND a.attname='residual_limitation_payload'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0251_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0251_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0251$;

/* R10 GOVERNED STATEMENT 0297 OF 0473
   statement_code: P220_PF_0252_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0252$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='jsonb')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=45
  AND NOT a.attisdropped
  AND a.attname='deferred_capability_payload'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0252_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0252_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0252$;

/* R10 GOVERNED STATEMENT 0298 OF 0473
   statement_code: P220_PF_0253_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0253$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=46
  AND NOT a.attisdropped
  AND a.attname='synthetic_data_only_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0253_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0253_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0253$;

/* R10 GOVERNED STATEMENT 0299 OF 0473
   statement_code: P220_PF_0254_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0254$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=47
  AND NOT a.attisdropped
  AND a.attname='no_pii_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0254_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0254_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0254$;

/* R10 GOVERNED STATEMENT 0300 OF 0473
   statement_code: P220_PF_0255_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0255$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=48
  AND NOT a.attisdropped
  AND a.attname='certification_only_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0255_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0255_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0255$;

/* R10 GOVERNED STATEMENT 0301 OF 0473
   statement_code: P220_PF_0256_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0256$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=49
  AND NOT a.attisdropped
  AND a.attname='production_action_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0256_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0256_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0256$;

/* R10 GOVERNED STATEMENT 0302 OF 0473
   statement_code: P220_PF_0257_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0257$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=50
  AND NOT a.attisdropped
  AND a.attname='external_system_update_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0257_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0257_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0257$;

/* R10 GOVERNED STATEMENT 0303 OF 0473
   statement_code: P220_PF_0258_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0258$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=51
  AND NOT a.attisdropped
  AND a.attname='legal_or_regulatory_certified_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0258_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0258_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0258$;

/* R10 GOVERNED STATEMENT 0304 OF 0473
   statement_code: P220_PF_0259_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0259$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=52
  AND NOT a.attisdropped
  AND a.attname='empirical_or_causal_optimization_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0259_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0259_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0259$;

/* R10 GOVERNED STATEMENT 0305 OF 0473
   statement_code: P220_PF_0260_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0260$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=53
  AND NOT a.attisdropped
  AND a.attname='deployment_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0260_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0260_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0260$;

/* R10 GOVERNED STATEMENT 0306 OF 0473
   statement_code: P220_PF_0261_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0261$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=54
  AND NOT a.attisdropped
  AND a.attname='module3_execution_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0261_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0261_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0261$;

/* R10 GOVERNED STATEMENT 0307 OF 0473
   statement_code: P220_PF_0262_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0262$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=55
  AND NOT a.attisdropped
  AND a.attname='policy_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0262_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0262_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0262$;

/* R10 GOVERNED STATEMENT 0308 OF 0473
   statement_code: P220_PF_0263_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0263$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=56
  AND NOT a.attisdropped
  AND a.attname='stage_certification_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0263_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0263_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0263$;

/* R10 GOVERNED STATEMENT 0309 OF 0473
   statement_code: P220_PF_0264_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0264$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=57
  AND NOT a.attisdropped
  AND a.attname='contract_component_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0264_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0264_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0264$;

/* R10 GOVERNED STATEMENT 0310 OF 0473
   statement_code: P220_PF_0265_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0265$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=58
  AND NOT a.attisdropped
  AND a.attname='evidence_certification_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0265_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0265_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0265$;

/* R10 GOVERNED STATEMENT 0311 OF 0473
   statement_code: P220_PF_0266_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0266$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=59
  AND NOT a.attisdropped
  AND a.attname='contract_reproduction_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0266_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0266_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0266$;

/* R10 GOVERNED STATEMENT 0312 OF 0473
   statement_code: P220_PF_0267_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0267$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=60
  AND NOT a.attisdropped
  AND a.attname='capability_coverage_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0267_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0267_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0267$;

/* R10 GOVERNED STATEMENT 0313 OF 0473
   statement_code: P220_PF_0268_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0268$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=61
  AND NOT a.attisdropped
  AND a.attname='contract_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0268_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0268_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0268$;

/* R10 GOVERNED STATEMENT 0314 OF 0473
   statement_code: P220_PF_0269_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0269$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=62
  AND NOT a.attisdropped
  AND a.attname='row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0269_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0269_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0269$;

/* R10 GOVERNED STATEMENT 0315 OF 0473
   statement_code: P220_PF_0270_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0270$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass
  AND a.attnum=63
  AND NOT a.attisdropped
  AND a.attname='created_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0270_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0270_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0270$;

/* R10 GOVERNED STATEMENT 0316 OF 0473
   statement_code: P220_PF_0271_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0271$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='a')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND a.attnum=1
  AND NOT a.attisdropped
  AND a.attname='archive_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0271_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0271_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0271$;

/* R10 GOVERNED STATEMENT 0317 OF 0473
   statement_code: P220_PF_0272_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0272$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND a.attnum=2
  AND NOT a.attisdropped
  AND a.attname='module1_run_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0272_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0272_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0272$;

/* R10 GOVERNED STATEMENT 0318 OF 0473
   statement_code: P220_PF_0273_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0273$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND a.attnum=3
  AND NOT a.attisdropped
  AND a.attname='bundle_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0273_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0273_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0273$;

/* R10 GOVERNED STATEMENT 0319 OF 0473
   statement_code: P220_PF_0274_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0274$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND a.attnum=4
  AND NOT a.attisdropped
  AND a.attname='contract_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0274_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0274_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0274$;

/* R10 GOVERNED STATEMENT 0320 OF 0473
   statement_code: P220_PF_0275_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0275$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND a.attnum=5
  AND NOT a.attisdropped
  AND a.attname='schema_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0275_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0275_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0275$;

/* R10 GOVERNED STATEMENT 0321 OF 0473
   statement_code: P220_PF_0276_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0276$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND a.attnum=6
  AND NOT a.attisdropped
  AND a.attname='methodology_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0276_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0276_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0276$;

/* R10 GOVERNED STATEMENT 0322 OF 0473
   statement_code: P220_PF_0277_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0277$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND a.attnum=7
  AND NOT a.attisdropped
  AND a.attname='acceptance_gate_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0277_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0277_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0277$;

/* R10 GOVERNED STATEMENT 0323 OF 0473
   statement_code: P220_PF_0278_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0278$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND a.attnum=8
  AND NOT a.attisdropped
  AND a.attname='source_latest_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0278_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0278_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0278$;

/* R10 GOVERNED STATEMENT 0324 OF 0473
   statement_code: P220_PF_0279_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0279$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND a.attnum=9
  AND NOT a.attisdropped
  AND a.attname='contract_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0279_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0279_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0279$;

/* R10 GOVERNED STATEMENT 0325 OF 0473
   statement_code: P220_PF_0280_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0280$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='jsonb')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND a.attnum=10
  AND NOT a.attisdropped
  AND a.attname='contract_payload'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0280_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0280_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0280$;

/* R10 GOVERNED STATEMENT 0326 OF 0473
   statement_code: P220_PF_0281_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0281$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND a.attnum=11
  AND NOT a.attisdropped
  AND a.attname='archive_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0281_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0281_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0281$;

/* R10 GOVERNED STATEMENT 0327 OF 0473
   statement_code: P220_PF_0282_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0282$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND a.attnum=12
  AND NOT a.attisdropped
  AND a.attname='created_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0282_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0282_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0282$;

/* R10 GOVERNED STATEMENT 0328 OF 0473
   statement_code: P220_PF_0283_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0283$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='a')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=1
  AND NOT a.attisdropped
  AND a.attname='registry_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0283_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0283_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0283$;

/* R10 GOVERNED STATEMENT 0329 OF 0473
   statement_code: P220_PF_0284_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0284$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=2
  AND NOT a.attisdropped
  AND a.attname='module1_run_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0284_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0284_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0284$;

/* R10 GOVERNED STATEMENT 0330 OF 0473
   statement_code: P220_PF_0285_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0285$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=3
  AND NOT a.attisdropped
  AND a.attname='bundle_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0285_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0285_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0285$;

/* R10 GOVERNED STATEMENT 0331 OF 0473
   statement_code: P220_PF_0286_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0286$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=4
  AND NOT a.attisdropped
  AND a.attname='contract_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0286_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0286_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0286$;

/* R10 GOVERNED STATEMENT 0332 OF 0473
   statement_code: P220_PF_0287_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0287$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=5
  AND NOT a.attisdropped
  AND a.attname='schema_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0287_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0287_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0287$;

/* R10 GOVERNED STATEMENT 0333 OF 0473
   statement_code: P220_PF_0288_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0288$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=6
  AND NOT a.attisdropped
  AND a.attname='methodology_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0288_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0288_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0288$;

/* R10 GOVERNED STATEMENT 0334 OF 0473
   statement_code: P220_PF_0289_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0289$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=7
  AND NOT a.attisdropped
  AND a.attname='acceptance_gate_id'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0289_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0289_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0289$;

/* R10 GOVERNED STATEMENT 0335 OF 0473
   statement_code: P220_PF_0290_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0290$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=8
  AND NOT a.attisdropped
  AND a.attname='policy_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0290_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0290_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0290$;

/* R10 GOVERNED STATEMENT 0336 OF 0473
   statement_code: P220_PF_0291_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0291$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=9
  AND NOT a.attisdropped
  AND a.attname='policy_version'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0291_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0291_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0291$;

/* R10 GOVERNED STATEMENT 0337 OF 0473
   statement_code: P220_PF_0292_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0292$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=10
  AND NOT a.attisdropped
  AND a.attname='policy_configuration_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0292_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0292_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0292$;

/* R10 GOVERNED STATEMENT 0338 OF 0473
   statement_code: P220_PF_0293_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0293$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=11
  AND NOT a.attisdropped
  AND a.attname='accepted_m2_11_project_sha256'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0293_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0293_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0293$;

/* R10 GOVERNED STATEMENT 0339 OF 0473
   statement_code: P220_PF_0294_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0294$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=12
  AND NOT a.attisdropped
  AND a.attname='accepted_m2_11_contract_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0294_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0294_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0294$;

/* R10 GOVERNED STATEMENT 0340 OF 0473
   statement_code: P220_PF_0295_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0295$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=13
  AND NOT a.attisdropped
  AND a.attname='accepted_m2_11_combined_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0295_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0295_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0295$;

/* R10 GOVERNED STATEMENT 0341 OF 0473
   statement_code: P220_PF_0296_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0296$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=14
  AND NOT a.attisdropped
  AND a.attname='accepted_m2_11_registry_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0296_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0296_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0296$;

/* R10 GOVERNED STATEMENT 0342 OF 0473
   statement_code: P220_PF_0297_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0297$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=15
  AND NOT a.attisdropped
  AND a.attname='source_node_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0297_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0297_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0297$;

/* R10 GOVERNED STATEMENT 0343 OF 0473
   statement_code: P220_PF_0298_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0298$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=16
  AND NOT a.attisdropped
  AND a.attname='component_contract_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0298_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0298_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0298$;

/* R10 GOVERNED STATEMENT 0344 OF 0473
   statement_code: P220_PF_0299_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0299$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=17
  AND NOT a.attisdropped
  AND a.attname='source_graph_edge_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0299_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0299_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0299$;

/* R10 GOVERNED STATEMENT 0345 OF 0473
   statement_code: P220_PF_0300_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0300$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=18
  AND NOT a.attisdropped
  AND a.attname='evidence_certification_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0300_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0300_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0300$;

/* R10 GOVERNED STATEMENT 0346 OF 0473
   statement_code: P220_PF_0301_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0301$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=19
  AND NOT a.attisdropped
  AND a.attname='contract_reproduction_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0301_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0301_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0301$;

/* R10 GOVERNED STATEMENT 0347 OF 0473
   statement_code: P220_PF_0302_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0302$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=20
  AND NOT a.attisdropped
  AND a.attname='capability_coverage_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0302_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0302_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0302$;

/* R10 GOVERNED STATEMENT 0348 OF 0473
   statement_code: P220_PF_0303_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0303$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=21
  AND NOT a.attisdropped
  AND a.attname='canonical_family_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0303_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0303_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0303$;

/* R10 GOVERNED STATEMENT 0349 OF 0473
   statement_code: P220_PF_0304_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0304$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=22
  AND NOT a.attisdropped
  AND a.attname='canonical_entity_count'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0304_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0304_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0304$;

/* R10 GOVERNED STATEMENT 0350 OF 0473
   statement_code: P220_PF_0305_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0305$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=23
  AND NOT a.attisdropped
  AND a.attname='application_consumption_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0305_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0305_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0305$;

/* R10 GOVERNED STATEMENT 0351 OF 0473
   statement_code: P220_PF_0306_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0306$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=24
  AND NOT a.attisdropped
  AND a.attname='operational_account_consumption_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0306_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0306_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0306$;

/* R10 GOVERNED STATEMENT 0352 OF 0473
   statement_code: P220_PF_0307_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0307$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='integer')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=25
  AND NOT a.attisdropped
  AND a.attname='strategy_scope_consumption_rows'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0307_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0307_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0307$;

/* R10 GOVERNED STATEMENT 0353 OF 0473
   statement_code: P220_PF_0308_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0308$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=26
  AND NOT a.attisdropped
  AND a.attname='component_latest_rows_total'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0308_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0308_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0308$;

/* R10 GOVERNED STATEMENT 0354 OF 0473
   statement_code: P220_PF_0309_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0309$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=27
  AND NOT a.attisdropped
  AND a.attname='component_archive_rows_total'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0309_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0309_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0309$;

/* R10 GOVERNED STATEMENT 0355 OF 0473
   statement_code: P220_PF_0310_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0310$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='bigint')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=28
  AND NOT a.attisdropped
  AND a.attname='stage_local_canonical_reference_total'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0310_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0310_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0310$;

/* R10 GOVERNED STATEMENT 0356 OF 0473
   statement_code: P220_PF_0311_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0311$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=29
  AND NOT a.attisdropped
  AND a.attname='all_stage_certification_pass_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0311_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0311_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0311$;

/* R10 GOVERNED STATEMENT 0357 OF 0473
   statement_code: P220_PF_0312_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0312$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=30
  AND NOT a.attisdropped
  AND a.attname='all_component_contract_pass_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0312_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0312_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0312$;

/* R10 GOVERNED STATEMENT 0358 OF 0473
   statement_code: P220_PF_0313_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0313$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=31
  AND NOT a.attisdropped
  AND a.attname='all_evidence_certification_pass_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0313_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0313_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0313$;

/* R10 GOVERNED STATEMENT 0359 OF 0473
   statement_code: P220_PF_0314_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0314$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=32
  AND NOT a.attisdropped
  AND a.attname='all_contract_reproduction_pass_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0314_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0314_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0314$;

/* R10 GOVERNED STATEMENT 0360 OF 0473
   statement_code: P220_PF_0315_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0315$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=33
  AND NOT a.attisdropped
  AND a.attname='all_capability_boundary_pass_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0315_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0315_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0315$;

/* R10 GOVERNED STATEMENT 0361 OF 0473
   statement_code: P220_PF_0316_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0316$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=34
  AND NOT a.attisdropped
  AND a.attname='all_source_graph_edges_pass_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0316_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0316_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0316$;

/* R10 GOVERNED STATEMENT 0362 OF 0473
   statement_code: P220_PF_0317_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0317$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=35
  AND NOT a.attisdropped
  AND a.attname='as_built_certification_scope_code'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0317_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0317_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0317$;

/* R10 GOVERNED STATEMENT 0363 OF 0473
   statement_code: P220_PF_0318_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0318$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='jsonb')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=36
  AND NOT a.attisdropped
  AND a.attname='residual_limitation_payload'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0318_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0318_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0318$;

/* R10 GOVERNED STATEMENT 0364 OF 0473
   statement_code: P220_PF_0319_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0319$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='jsonb')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=37
  AND NOT a.attisdropped
  AND a.attname='deferred_capability_payload'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0319_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0319_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0319$;

/* R10 GOVERNED STATEMENT 0365 OF 0473
   statement_code: P220_PF_0320_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0320$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=38
  AND NOT a.attisdropped
  AND a.attname='synthetic_data_only_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0320_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0320_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0320$;

/* R10 GOVERNED STATEMENT 0366 OF 0473
   statement_code: P220_PF_0321_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0321$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=39
  AND NOT a.attisdropped
  AND a.attname='no_pii_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0321_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0321_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0321$;

/* R10 GOVERNED STATEMENT 0367 OF 0473
   statement_code: P220_PF_0322_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0322$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=40
  AND NOT a.attisdropped
  AND a.attname='certification_only_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0322_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0322_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0322$;

/* R10 GOVERNED STATEMENT 0368 OF 0473
   statement_code: P220_PF_0323_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0323$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=41
  AND NOT a.attisdropped
  AND a.attname='production_action_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0323_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0323_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0323$;

/* R10 GOVERNED STATEMENT 0369 OF 0473
   statement_code: P220_PF_0324_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0324$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=42
  AND NOT a.attisdropped
  AND a.attname='external_system_update_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0324_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0324_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0324$;

/* R10 GOVERNED STATEMENT 0370 OF 0473
   statement_code: P220_PF_0325_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0325$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=43
  AND NOT a.attisdropped
  AND a.attname='legal_or_regulatory_certified_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0325_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0325_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0325$;

/* R10 GOVERNED STATEMENT 0371 OF 0473
   statement_code: P220_PF_0326_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0326$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=44
  AND NOT a.attisdropped
  AND a.attname='empirical_or_causal_optimization_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0326_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0326_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0326$;

/* R10 GOVERNED STATEMENT 0372 OF 0473
   statement_code: P220_PF_0327_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0327$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=45
  AND NOT a.attisdropped
  AND a.attname='deployment_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0327_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0327_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0327$;

/* R10 GOVERNED STATEMENT 0373 OF 0473
   statement_code: P220_PF_0328_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0328$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='boolean')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=46
  AND NOT a.attisdropped
  AND a.attname='module3_execution_authorized_flag'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0328_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0328_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0328$;

/* R10 GOVERNED STATEMENT 0374 OF 0473
   statement_code: P220_PF_0329_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0329$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=47
  AND NOT a.attisdropped
  AND a.attname='policy_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0329_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0329_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0329$;

/* R10 GOVERNED STATEMENT 0375 OF 0473
   statement_code: P220_PF_0330_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0330$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=48
  AND NOT a.attisdropped
  AND a.attname='stage_certification_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0330_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0330_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0330$;

/* R10 GOVERNED STATEMENT 0376 OF 0473
   statement_code: P220_PF_0331_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0331$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=49
  AND NOT a.attisdropped
  AND a.attname='contract_component_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0331_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0331_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0331$;

/* R10 GOVERNED STATEMENT 0377 OF 0473
   statement_code: P220_PF_0332_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0332$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=50
  AND NOT a.attisdropped
  AND a.attname='evidence_certification_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0332_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0332_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0332$;

/* R10 GOVERNED STATEMENT 0378 OF 0473
   statement_code: P220_PF_0333_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0333$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=51
  AND NOT a.attisdropped
  AND a.attname='contract_reproduction_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0333_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0333_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0333$;

/* R10 GOVERNED STATEMENT 0379 OF 0473
   statement_code: P220_PF_0334_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0334$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=52
  AND NOT a.attisdropped
  AND a.attname='capability_coverage_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0334_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0334_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0334$;

/* R10 GOVERNED STATEMENT 0380 OF 0473
   statement_code: P220_PF_0335_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0335$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=53
  AND NOT a.attisdropped
  AND a.attname='latest_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0335_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0335_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0335$;

/* R10 GOVERNED STATEMENT 0381 OF 0473
   statement_code: P220_PF_0336_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0336$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=54
  AND NOT a.attisdropped
  AND a.attname='archive_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0336_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0336_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0336$;

/* R10 GOVERNED STATEMENT 0382 OF 0473
   statement_code: P220_PF_0337_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0337$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=55
  AND NOT a.attisdropped
  AND a.attname='registry_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0337_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0337_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0337$;

/* R10 GOVERNED STATEMENT 0383 OF 0473
   statement_code: P220_PF_0338_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0338$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=56
  AND NOT a.attisdropped
  AND a.attname='latest_contract_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0338_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0338_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0338$;

/* R10 GOVERNED STATEMENT 0384 OF 0473
   statement_code: P220_PF_0339_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0339$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=57
  AND NOT a.attisdropped
  AND a.attname='archive_contract_row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0339_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0339_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0339$;

/* R10 GOVERNED STATEMENT 0385 OF 0473
   statement_code: P220_PF_0340_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0340$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=58
  AND NOT a.attisdropped
  AND a.attname='contract_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0340_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0340_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0340$;

/* R10 GOVERNED STATEMENT 0386 OF 0473
   statement_code: P220_PF_0341_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0341$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=59
  AND NOT a.attisdropped
  AND a.attname='combined_set_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0341_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0341_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0341$;

/* R10 GOVERNED STATEMENT 0387 OF 0473
   statement_code: P220_PF_0342_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0342$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=60
  AND NOT a.attisdropped
  AND a.attname='contract_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0342_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0342_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0342$;

/* R10 GOVERNED STATEMENT 0388 OF 0473
   statement_code: P220_PF_0343_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0343$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=false)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=61
  AND NOT a.attisdropped
  AND a.attname='generated_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0343_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0343_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0343$;

/* R10 GOVERNED STATEMENT 0389 OF 0473
   statement_code: P220_PF_0344_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0344$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=false)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=62
  AND NOT a.attisdropped
  AND a.attname='validated_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0344_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0344_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0344$;

/* R10 GOVERNED STATEMENT 0390 OF 0473
   statement_code: P220_PF_0345_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0345$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=false)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=63
  AND NOT a.attisdropped
  AND a.attname='accepted_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0345_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0345_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0345$;

/* R10 GOVERNED STATEMENT 0391 OF 0473
   statement_code: P220_PF_0346_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0346$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='text')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=64
  AND NOT a.attisdropped
  AND a.attname='row_hash'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0346_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0346_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0346$;

/* R10 GOVERNED STATEMENT 0392 OF 0473
   statement_code: P220_PF_0347_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0347$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=65
  AND NOT a.attisdropped
  AND a.attname='created_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0347_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0347_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0347$;

/* R10 GOVERNED STATEMENT 0393 OF 0473
   statement_code: P220_PF_0348_PERSISTENT_COLUMN
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0348$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(pg_catalog.format_type(a.atttypid,a.atttypmod)='timestamp with time zone')
   AND bool_and(a.attnotnull=true)
   AND bool_and(a.attidentity='')
FROM pg_catalog.pg_attribute a
WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
  AND a.attnum=66
  AND NOT a.attisdropped
  AND a.attname='updated_at'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0348_PERSISTENT_COLUMN',
            DETAIL='check_code=P220_PF_0348_PERSISTENT_COLUMN';
    END IF;
END;
$m212_r8_p220_pf_0348$;

/* R10 GOVERNED STATEMENT 0394 OF 0473
   statement_code: P220_PF_0349_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_pk_m212_policy_profile$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='p')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['policy_profile_id']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS TRUE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=1 AND i.indnatts=1)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['policy_profile_id']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[1]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_policy_profile' AND c.conname='pk_m212_policy_profile'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_PK_M212_POLICY_PROFILE',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_pk_m212_policy_profile$;

/* R10 GOVERNED STATEMENT 0395 OF 0473
   statement_code: P220_PF_0350_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_uq_m212_policy_business$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='u')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id','policy_code','policy_version']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS FALSE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','policy_code','policy_version']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_policy_profile' AND c.conname='uq_m212_policy_business'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_UQ_M212_POLICY_BUSINESS',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_uq_m212_policy_business$;

/* R10 GOVERNED STATEMENT 0396 OF 0473
   statement_code: P220_PF_0351_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_fk_m212_policy_run$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='f')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id']::text[])
   AND bool_and(rn.nspname='msbf_ctl' AND rt.relname='run_registry')
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(c.confkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.confrelid AND a.attnum=k.attnum)=ARRAY['run_id']::text[])
   AND bool_and(c.confupdtype='a' AND c.confdeltype='r' AND c.confmatchtype='s')
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_class rt ON rt.oid=c.confrelid
JOIN pg_catalog.pg_namespace rn ON rn.oid=rt.relnamespace
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_policy_profile' AND c.conname='fk_m212_policy_run'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_FK_M212_POLICY_RUN',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_fk_m212_policy_run$;

/* R10 GOVERNED STATEMENT 0397 OF 0473
   statement_code: P220_PF_0352_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_004$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_004;
    CREATE TEMP TABLE tmp_pf_ck_004 (LIKE msbf_ctl.m2_12_policy_profile) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_004 ADD CONSTRAINT expected_ck_004 CHECK (policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND policy_version=1 AND policy_status='APPROVED' AND methodology_version='M2_12_METHOD_V1' AND bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND bundle_version=1 AND schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND acceptance_gate_id='G3_M2_CONTRACT');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_policy_profile' AND c.conname='ck_m212_policy_identity';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_policy_profile'::regclass AND c.conname='ck_m212_policy_identity';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_004'::regclass AND c.conname='expected_ck_004';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_policy_profile::ck_m212_policy_identity',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_004;
END;
$m212_r9_ck_004$;

/* R10 GOVERNED STATEMENT 0398 OF 0473
   statement_code: P220_PF_0353_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_005$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_005;
    CREATE TEMP TABLE tmp_pf_ck_005 (LIKE msbf_ctl.m2_12_policy_profile) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_005 ADD CONSTRAINT expected_ck_005 CHECK (expected_source_node_rows=12 AND expected_component_contract_rows=13 AND expected_source_graph_edge_rows=19 AND expected_evidence_certification_rows=72 AND expected_contract_reproduction_rows=13 AND expected_capability_coverage_rows=20 AND expected_canonical_family_count=9 AND expected_canonical_entities=134 AND expected_application_consumption_rows=1500 AND expected_operational_account_consumption_rows=59 AND expected_strategy_scope_consumption_rows=24 AND expected_generation_evidence_rows=24 AND expected_positive_controls=128 AND expected_negative_controls=20 AND expected_acceptance_requirements=48 AND expected_detail_result_sets=24);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_policy_profile' AND c.conname='ck_m212_policy_counts';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_policy_profile'::regclass AND c.conname='ck_m212_policy_counts';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_005'::regclass AND c.conname='expected_ck_005';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_policy_profile::ck_m212_policy_counts',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_005;
END;
$m212_r9_ck_005$;

/* R10 GOVERNED STATEMENT 0399 OF 0473
   statement_code: P220_PF_0354_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_006$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_006;
    CREATE TEMP TABLE tmp_pf_ck_006 (LIKE msbf_ctl.m2_12_policy_profile) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_006 ADD CONSTRAINT expected_ck_006 CHECK (synthetic_data_only_flag AND no_pii_flag AND certification_only_flag AND NOT production_action_authorized_flag AND NOT external_system_update_authorized_flag AND NOT legal_or_regulatory_certified_flag AND NOT empirical_or_causal_optimization_authorized_flag AND NOT module3_sql_authorized_flag AND NOT module3_execution_authorized_flag);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_policy_profile' AND c.conname='ck_m212_policy_boundaries';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_policy_profile'::regclass AND c.conname='ck_m212_policy_boundaries';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_006'::regclass AND c.conname='expected_ck_006';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_policy_profile::ck_m212_policy_boundaries',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_006;
END;
$m212_r9_ck_006$;

/* R10 GOVERNED STATEMENT 0400 OF 0473
   statement_code: P220_PF_0355_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_007$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_007;
    CREATE TEMP TABLE tmp_pf_ck_007 (LIKE msbf_ctl.m2_12_policy_profile) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_007 ADD CONSTRAINT expected_ck_007 CHECK (accepted_m2_11_project_sha256 ~ '^[0-9a-f]{64}$' AND accepted_m2_11_contract_set_hash ~ '^[0-9a-f]{32}$' AND accepted_m2_11_combined_set_hash ~ '^[0-9a-f]{32}$' AND accepted_m2_11_registry_row_hash ~ '^[0-9a-f]{32}$' AND configuration_hash ~ '^[0-9a-f]{32}$' AND row_hash ~ '^[0-9a-f]{32}$');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_policy_profile' AND c.conname='ck_m212_policy_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_policy_profile'::regclass AND c.conname='ck_m212_policy_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_007'::regclass AND c.conname='expected_ck_007';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_policy_profile::ck_m212_policy_hashes',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_007;
END;
$m212_r9_ck_007$;

/* R10 GOVERNED STATEMENT 0401 OF 0473
   statement_code: P220_PF_0356_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_pk_m212_stage_cert$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='p')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id','certification_node_sequence','stage_code']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS TRUE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','certification_node_sequence','stage_code']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_m2' AND t.relname='module2_stage_certification_snapshot' AND c.conname='pk_m212_stage_cert'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_PK_M212_STAGE_CERT',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_pk_m212_stage_cert$;

/* R10 GOVERNED STATEMENT 0402 OF 0473
   statement_code: P220_PF_0357_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_fk_m212_stage_run$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='f')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id']::text[])
   AND bool_and(rn.nspname='msbf_ctl' AND rt.relname='run_registry')
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(c.confkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.confrelid AND a.attnum=k.attnum)=ARRAY['run_id']::text[])
   AND bool_and(c.confupdtype='a' AND c.confdeltype='r' AND c.confmatchtype='s')
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_class rt ON rt.oid=c.confrelid
JOIN pg_catalog.pg_namespace rn ON rn.oid=rt.relnamespace
WHERE n.nspname='msbf_m2' AND t.relname='module2_stage_certification_snapshot' AND c.conname='fk_m212_stage_run'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_FK_M212_STAGE_RUN',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_fk_m212_stage_run$;

/* R10 GOVERNED STATEMENT 0403 OF 0473
   statement_code: P220_PF_0358_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_010$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_010;
    CREATE TEMP TABLE tmp_pf_ck_010 (LIKE msbf_m2.module2_stage_certification_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_010 ADD CONSTRAINT expected_ck_010 CHECK (certification_node_sequence BETWEEN 1 AND 12 AND acceptance_gate_review_version=1 AND required_source_edge_count>=0 AND passed_source_edge_count>=0);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_stage_certification_snapshot' AND c.conname='ck_m212_stage_seq';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_stage_certification_snapshot'::regclass AND c.conname='ck_m212_stage_seq';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_010'::regclass AND c.conname='expected_ck_010';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_stage_certification_snapshot::ck_m212_stage_seq',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_010;
END;
$m212_r9_ck_010$;

/* R10 GOVERNED STATEMENT 0404 OF 0473
   statement_code: P220_PF_0359_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_011$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_011;
    CREATE TEMP TABLE tmp_pf_ck_011 (LIKE msbf_m2.module2_stage_certification_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_011 ADD CONSTRAINT expected_ck_011 CHECK (contract_status='ACCEPTED' AND gate_status='PASS' AND acceptance_evidence_status='PASS' AND source_graph_status='PASS' AND canonical_identity_status='PASS' AND stage_boundary_status='PASS' AND certification_status='PASS');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_stage_certification_snapshot' AND c.conname='ck_m212_stage_status';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_stage_certification_snapshot'::regclass AND c.conname='ck_m212_stage_status';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_011'::regclass AND c.conname='expected_ck_011';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_stage_certification_snapshot::ck_m212_stage_status',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_011;
END;
$m212_r9_ck_011$;

/* R10 GOVERNED STATEMENT 0405 OF 0473
   statement_code: P220_PF_0360_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_012$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_012;
    CREATE TEMP TABLE tmp_pf_ck_012 (LIKE msbf_m2.module2_stage_certification_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_012 ADD CONSTRAINT expected_ck_012 CHECK (expected_combined_hash ~ '^[0-9a-f]{32}$' AND observed_combined_hash ~ '^[0-9a-f]{32}$' AND source_registry_row_hash ~ '^[0-9a-f]{32}$' AND row_hash ~ '^[0-9a-f]{32}$');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_stage_certification_snapshot' AND c.conname='ck_m212_stage_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_stage_certification_snapshot'::regclass AND c.conname='ck_m212_stage_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_012'::regclass AND c.conname='expected_ck_012';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_stage_certification_snapshot::ck_m212_stage_hashes',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_012;
END;
$m212_r9_ck_012$;

/* R10 GOVERNED STATEMENT 0406 OF 0473
   statement_code: P220_PF_0361_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_pk_m212_component$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='p')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id','component_sequence','component_contract_code','contract_version']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS TRUE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=4 AND i.indnatts=4)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','component_sequence','component_contract_code','contract_version']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[4]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_m2' AND t.relname='module2_contract_component_snapshot' AND c.conname='pk_m212_component'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_PK_M212_COMPONENT',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_pk_m212_component$;

/* R10 GOVERNED STATEMENT 0407 OF 0473
   statement_code: P220_PF_0362_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_fk_m212_component_run$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='f')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id']::text[])
   AND bool_and(rn.nspname='msbf_ctl' AND rt.relname='run_registry')
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(c.confkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.confrelid AND a.attnum=k.attnum)=ARRAY['run_id']::text[])
   AND bool_and(c.confupdtype='a' AND c.confdeltype='r' AND c.confmatchtype='s')
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_class rt ON rt.oid=c.confrelid
JOIN pg_catalog.pg_namespace rn ON rn.oid=rt.relnamespace
WHERE n.nspname='msbf_m2' AND t.relname='module2_contract_component_snapshot' AND c.conname='fk_m212_component_run'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_FK_M212_COMPONENT_RUN',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_fk_m212_component_run$;

/* R10 GOVERNED STATEMENT 0408 OF 0473
   statement_code: P220_PF_0363_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_015$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_015;
    CREATE TEMP TABLE tmp_pf_ck_015 (LIKE msbf_m2.module2_contract_component_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_015 ADD CONSTRAINT expected_ck_015 CHECK (component_sequence BETWEEN 1 AND 13 AND certification_node_sequence BETWEEN 1 AND 12 AND contract_version=1);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_contract_component_snapshot' AND c.conname='ck_m212_component_seq';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_contract_component_snapshot'::regclass AND c.conname='ck_m212_component_seq';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_015'::regclass AND c.conname='expected_ck_015';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_contract_component_snapshot::ck_m212_component_seq',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_015;
END;
$m212_r9_ck_015$;

/* R10 GOVERNED STATEMENT 0409 OF 0473
   statement_code: P220_PF_0364_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_016$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_016;
    CREATE TEMP TABLE tmp_pf_ck_016 (LIKE msbf_m2.module2_contract_component_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_016 ADD CONSTRAINT expected_ck_016 CHECK (expected_latest_rows>=0 AND observed_latest_rows=expected_latest_rows AND expected_archive_rows>=0 AND observed_archive_rows=expected_archive_rows AND observed_positive_controls=expected_positive_controls AND observed_negative_controls=expected_negative_controls AND passed_source_edge_count=required_source_edge_count);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_contract_component_snapshot' AND c.conname='ck_m212_component_counts';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_contract_component_snapshot'::regclass AND c.conname='ck_m212_component_counts';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_016'::regclass AND c.conname='expected_ck_016';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_contract_component_snapshot::ck_m212_component_counts',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_016;
END;
$m212_r9_ck_016$;

/* R10 GOVERNED STATEMENT 0410 OF 0473
   statement_code: P220_PF_0365_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_017$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_017;
    CREATE TEMP TABLE tmp_pf_ck_017 (LIKE msbf_m2.module2_contract_component_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_017 ADD CONSTRAINT expected_ck_017 CHECK (contract_status='ACCEPTED' AND gate_status='PASS' AND acceptance_evidence_status='PASS' AND certification_status='PASS');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_contract_component_snapshot' AND c.conname='ck_m212_component_status';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_contract_component_snapshot'::regclass AND c.conname='ck_m212_component_status';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_017'::regclass AND c.conname='expected_ck_017';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_contract_component_snapshot::ck_m212_component_status',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_017;
END;
$m212_r9_ck_017$;

/* R10 GOVERNED STATEMENT 0411 OF 0473
   statement_code: P220_PF_0366_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_018$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_018;
    CREATE TEMP TABLE tmp_pf_ck_018 (LIKE msbf_m2.module2_contract_component_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_018 ADD CONSTRAINT expected_ck_018 CHECK (expected_contract_set_hash=observed_contract_set_hash AND expected_stage_combined_set_hash=observed_stage_combined_set_hash AND expected_registry_row_hash=observed_registry_row_hash AND expected_latest_set_hash=observed_latest_set_hash AND expected_archive_set_hash=observed_archive_set_hash AND row_hash ~ '^[0-9a-f]{32}$');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_contract_component_snapshot' AND c.conname='ck_m212_component_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_contract_component_snapshot'::regclass AND c.conname='ck_m212_component_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_018'::regclass AND c.conname='expected_ck_018';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_contract_component_snapshot::ck_m212_component_hashes',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_018;
END;
$m212_r9_ck_018$;

/* R10 GOVERNED STATEMENT 0412 OF 0473
   statement_code: P220_PF_0367_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_pk_m212_evidence$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='p')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id','node_sequence','evidence_family_sequence','evidence_family_code']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS TRUE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=4 AND i.indnatts=4)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','node_sequence','evidence_family_sequence','evidence_family_code']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[4]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_m2' AND t.relname='module2_evidence_certification_snapshot' AND c.conname='pk_m212_evidence'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_PK_M212_EVIDENCE',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_pk_m212_evidence$;

/* R10 GOVERNED STATEMENT 0413 OF 0473
   statement_code: P220_PF_0368_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_fk_m212_evidence_run$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='f')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id']::text[])
   AND bool_and(rn.nspname='msbf_ctl' AND rt.relname='run_registry')
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(c.confkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.confrelid AND a.attnum=k.attnum)=ARRAY['run_id']::text[])
   AND bool_and(c.confupdtype='a' AND c.confdeltype='r' AND c.confmatchtype='s')
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_class rt ON rt.oid=c.confrelid
JOIN pg_catalog.pg_namespace rn ON rn.oid=rt.relnamespace
WHERE n.nspname='msbf_m2' AND t.relname='module2_evidence_certification_snapshot' AND c.conname='fk_m212_evidence_run'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_FK_M212_EVIDENCE_RUN',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_fk_m212_evidence_run$;

/* R10 GOVERNED STATEMENT 0414 OF 0473
   statement_code: P220_PF_0369_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_021$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_021;
    CREATE TEMP TABLE tmp_pf_ck_021 (LIKE msbf_m2.module2_evidence_certification_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_021 ADD CONSTRAINT expected_ck_021 CHECK (node_sequence BETWEEN 1 AND 12 AND evidence_family_sequence BETWEEN 1 AND 6);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_evidence_certification_snapshot' AND c.conname='ck_m212_evidence_seq';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass AND c.conname='ck_m212_evidence_seq';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_021'::regclass AND c.conname='expected_ck_021';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_evidence_certification_snapshot::ck_m212_evidence_seq',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_021;
END;
$m212_r9_ck_021$;

/* R10 GOVERNED STATEMENT 0415 OF 0473
   statement_code: P220_PF_0370_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_022$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_022;
    CREATE TEMP TABLE tmp_pf_ck_022 (LIKE msbf_m2.module2_evidence_certification_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_022 ADD CONSTRAINT expected_ck_022 CHECK (applicability_code='MANDATORY' AND allowed_certification_status='PASS' AND expected_status='PASS' AND observed_status='PASS' AND mismatch_count=0 AND certification_status='PASS');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_evidence_certification_snapshot' AND c.conname='ck_m212_evidence_mandatory';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass AND c.conname='ck_m212_evidence_mandatory';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_022'::regclass AND c.conname='expected_ck_022';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_evidence_certification_snapshot::ck_m212_evidence_mandatory',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_022;
END;
$m212_r9_ck_022$;

/* R10 GOVERNED STATEMENT 0416 OF 0473
   statement_code: P220_PF_0371_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_023$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_023;
    CREATE TEMP TABLE tmp_pf_ck_023 (LIKE msbf_m2.module2_evidence_certification_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_023 ADD CONSTRAINT expected_ck_023 CHECK (source_registry_row_hash ~ '^[0-9a-f]{32}$' AND (source_evidence_row_hash IS NULL OR source_evidence_row_hash ~ '^[0-9a-f]{32}$') AND (expected_hash='' OR expected_hash ~ '^[0-9a-f]{32}$') AND (observed_hash IS NULL OR observed_hash ~ '^[0-9a-f]{32}$') AND row_hash ~ '^[0-9a-f]{32}$');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_evidence_certification_snapshot' AND c.conname='ck_m212_evidence_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_evidence_certification_snapshot'::regclass AND c.conname='ck_m212_evidence_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_023'::regclass AND c.conname='expected_ck_023';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_evidence_certification_snapshot::ck_m212_evidence_hashes',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_023;
END;
$m212_r9_ck_023$;

/* R10 GOVERNED STATEMENT 0417 OF 0473
   statement_code: P220_PF_0372_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_pk_m212_reproduction$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='p')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id','component_sequence','component_contract_code','contract_version']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS TRUE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=4 AND i.indnatts=4)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','component_sequence','component_contract_code','contract_version']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[4]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_m2' AND t.relname='module2_contract_reproduction_snapshot' AND c.conname='pk_m212_reproduction'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_PK_M212_REPRODUCTION',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_pk_m212_reproduction$;

/* R10 GOVERNED STATEMENT 0418 OF 0473
   statement_code: P220_PF_0373_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_fk_m212_reproduction_run$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='f')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id']::text[])
   AND bool_and(rn.nspname='msbf_ctl' AND rt.relname='run_registry')
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(c.confkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.confrelid AND a.attnum=k.attnum)=ARRAY['run_id']::text[])
   AND bool_and(c.confupdtype='a' AND c.confdeltype='r' AND c.confmatchtype='s')
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_class rt ON rt.oid=c.confrelid
JOIN pg_catalog.pg_namespace rn ON rn.oid=rt.relnamespace
WHERE n.nspname='msbf_m2' AND t.relname='module2_contract_reproduction_snapshot' AND c.conname='fk_m212_reproduction_run'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_FK_M212_REPRODUCTION_RUN',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_fk_m212_reproduction_run$;

/* R10 GOVERNED STATEMENT 0419 OF 0473
   statement_code: P220_PF_0374_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_026$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_026;
    CREATE TEMP TABLE tmp_pf_ck_026 (LIKE msbf_m2.module2_contract_reproduction_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_026 ADD CONSTRAINT expected_ck_026 CHECK (observed_latest_rows=expected_latest_rows AND observed_archive_rows=expected_archive_rows AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0 AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_contract_reproduction_snapshot' AND c.conname='ck_m212_reproduction_counts';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass AND c.conname='ck_m212_reproduction_counts';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_026'::regclass AND c.conname='expected_ck_026';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_contract_reproduction_snapshot::ck_m212_reproduction_counts',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_026;
END;
$m212_r9_ck_026$;

/* R10 GOVERNED STATEMENT 0420 OF 0473
   statement_code: P220_PF_0375_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_027$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_027;
    CREATE TEMP TABLE tmp_pf_ck_027 (LIKE msbf_m2.module2_contract_reproduction_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_027 ADD CONSTRAINT expected_ck_027 CHECK (archive_trigger_status='PASS' AND reproduction_status='PASS');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_contract_reproduction_snapshot' AND c.conname='ck_m212_reproduction_status';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass AND c.conname='ck_m212_reproduction_status';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_027'::regclass AND c.conname='expected_ck_027';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_contract_reproduction_snapshot::ck_m212_reproduction_status',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_027;
END;
$m212_r9_ck_027$;

/* R10 GOVERNED STATEMENT 0421 OF 0473
   statement_code: P220_PF_0376_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_028$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_028;
    CREATE TEMP TABLE tmp_pf_ck_028 (LIKE msbf_m2.module2_contract_reproduction_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_028 ADD CONSTRAINT expected_ck_028 CHECK (expected_latest_set_hash=observed_latest_set_hash AND expected_archive_set_hash=observed_archive_set_hash AND source_registry_row_hash ~ '^[0-9a-f]{32}$' AND row_hash ~ '^[0-9a-f]{32}$');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_contract_reproduction_snapshot' AND c.conname='ck_m212_reproduction_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_contract_reproduction_snapshot'::regclass AND c.conname='ck_m212_reproduction_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_028'::regclass AND c.conname='expected_ck_028';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_contract_reproduction_snapshot::ck_m212_reproduction_hashes',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_028;
END;
$m212_r9_ck_028$;

/* R10 GOVERNED STATEMENT 0422 OF 0473
   statement_code: P220_PF_0377_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_pk_m212_capability$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='p')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id','capability_sequence','capability_code']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS TRUE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','capability_sequence','capability_code']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_m2' AND t.relname='module2_capability_coverage_snapshot' AND c.conname='pk_m212_capability'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_PK_M212_CAPABILITY',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_pk_m212_capability$;

/* R10 GOVERNED STATEMENT 0423 OF 0473
   statement_code: P220_PF_0378_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_fk_m212_capability_run$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='f')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id']::text[])
   AND bool_and(rn.nspname='msbf_ctl' AND rt.relname='run_registry')
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(c.confkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.confrelid AND a.attnum=k.attnum)=ARRAY['run_id']::text[])
   AND bool_and(c.confupdtype='a' AND c.confdeltype='r' AND c.confmatchtype='s')
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_class rt ON rt.oid=c.confrelid
JOIN pg_catalog.pg_namespace rn ON rn.oid=rt.relnamespace
WHERE n.nspname='msbf_m2' AND t.relname='module2_capability_coverage_snapshot' AND c.conname='fk_m212_capability_run'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_FK_M212_CAPABILITY_RUN',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_fk_m212_capability_run$;

/* R10 GOVERNED STATEMENT 0424 OF 0473
   statement_code: P220_PF_0379_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_031$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_031;
    CREATE TEMP TABLE tmp_pf_ck_031 (LIKE msbf_m2.module2_capability_coverage_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_031 ADD CONSTRAINT expected_ck_031 CHECK (capability_sequence BETWEEN 1 AND 20);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_capability_coverage_snapshot' AND c.conname='ck_m212_capability_seq';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass AND c.conname='ck_m212_capability_seq';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_031'::regclass AND c.conname='expected_ck_031';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_capability_coverage_snapshot::ck_m212_capability_seq',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_031;
END;
$m212_r9_ck_031$;

/* R10 GOVERNED STATEMENT 0425 OF 0473
   statement_code: P220_PF_0380_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_032$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_032;
    CREATE TEMP TABLE tmp_pf_ck_032 (LIKE msbf_m2.module2_capability_coverage_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_032 ADD CONSTRAINT expected_ck_032 CHECK (coverage_status_code IN ('IMPLEMENTED_BOUNDED_SYNTHETIC','IMPLEMENTED_CERTIFIED_SYNTHETIC','IMPLEMENTED_CERTIFIED_ANALYTICS','IMPLEMENTED_CERTIFIED_COMPARATIVE','IMPLEMENTED_CERTIFIED','IMPLEMENTED_BOUNDED_RECOMMENDATION','DEFERRED_NOT_IMPLEMENTED','DEFERRED_NOT_CERTIFIED','PROHIBITED_NOT_AUTHORIZED','NOT_SUPPORTED_NOT_AUTHORIZED'));

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_capability_coverage_snapshot' AND c.conname='ck_m212_capability_status';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass AND c.conname='ck_m212_capability_status';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_032'::regclass AND c.conname='expected_ck_032';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_capability_coverage_snapshot::ck_m212_capability_status',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_032;
END;
$m212_r9_ck_032$;

/* R10 GOVERNED STATEMENT 0426 OF 0473
   statement_code: P220_PF_0381_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_033$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_033;
    CREATE TEMP TABLE tmp_pf_ck_033 (LIKE msbf_m2.module2_capability_coverage_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_033 ADD CONSTRAINT expected_ck_033 CHECK (NOT production_action_authorized_flag AND NOT legal_or_regulatory_certified_flag);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_capability_coverage_snapshot' AND c.conname='ck_m212_capability_boundary';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass AND c.conname='ck_m212_capability_boundary';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_033'::regclass AND c.conname='expected_ck_033';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_capability_coverage_snapshot::ck_m212_capability_boundary',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_033;
END;
$m212_r9_ck_033$;

/* R10 GOVERNED STATEMENT 0427 OF 0473
   statement_code: P220_PF_0382_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_034$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_034;
    CREATE TEMP TABLE tmp_pf_ck_034 (LIKE msbf_m2.module2_capability_coverage_snapshot) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_034 ADD CONSTRAINT expected_ck_034 CHECK (row_hash ~ '^[0-9a-f]{32}$');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_m2' AND t.relname='module2_capability_coverage_snapshot' AND c.conname='ck_m212_capability_hash';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_m2.module2_capability_coverage_snapshot'::regclass AND c.conname='ck_m212_capability_hash';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_034'::regclass AND c.conname='expected_ck_034';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_m2.module2_capability_coverage_snapshot::ck_m212_capability_hash',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_034;
END;
$m212_r9_ck_034$;

/* R10 GOVERNED STATEMENT 0428 OF 0473
   statement_code: P220_PF_0383_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_pk_m212_g3_latest$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='p')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS TRUE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=1 AND i.indnatts=1)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[1]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_latest' AND c.conname='pk_m212_g3_latest'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_PK_M212_G3_LATEST',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_pk_m212_g3_latest$;

/* R10 GOVERNED STATEMENT 0429 OF 0473
   statement_code: P220_PF_0384_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_uq_m212_g3_latest_busines$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='u')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id','bundle_code','contract_version']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS FALSE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','bundle_code','contract_version']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_latest' AND c.conname='uq_m212_g3_latest_business'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_UQ_M212_G3_LATEST_BUSINESS',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_uq_m212_g3_latest_busines$;

/* R10 GOVERNED STATEMENT 0430 OF 0473
   statement_code: P220_PF_0385_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_fk_m212_g3_latest_run$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='f')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id']::text[])
   AND bool_and(rn.nspname='msbf_ctl' AND rt.relname='run_registry')
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(c.confkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.confrelid AND a.attnum=k.attnum)=ARRAY['run_id']::text[])
   AND bool_and(c.confupdtype='a' AND c.confdeltype='r' AND c.confmatchtype='s')
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_class rt ON rt.oid=c.confrelid
JOIN pg_catalog.pg_namespace rn ON rn.oid=rt.relnamespace
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_latest' AND c.conname='fk_m212_g3_latest_run'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_FK_M212_G3_LATEST_RUN',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_fk_m212_g3_latest_run$;

/* R10 GOVERNED STATEMENT 0431 OF 0473
   statement_code: P220_PF_0386_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_038$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_038;
    CREATE TEMP TABLE tmp_pf_ck_038 (LIKE msbf_ctl.m2_12_g3_bundle_latest) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_038 ADD CONSTRAINT expected_ck_038 CHECK (bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND contract_version=1 AND schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND methodology_version='M2_12_METHOD_V1' AND acceptance_gate_id='G3_M2_CONTRACT');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_latest' AND c.conname='ck_m212_g3_latest_identity';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass AND c.conname='ck_m212_g3_latest_identity';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_038'::regclass AND c.conname='expected_ck_038';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_latest::ck_m212_g3_latest_identity',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_038;
END;
$m212_r9_ck_038$;

/* R10 GOVERNED STATEMENT 0432 OF 0473
   statement_code: P220_PF_0387_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_039$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_039;
    CREATE TEMP TABLE tmp_pf_ck_039 (LIKE msbf_ctl.m2_12_g3_bundle_latest) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_039 ADD CONSTRAINT expected_ck_039 CHECK (source_node_count=12 AND component_contract_count=13 AND source_graph_edge_count=19 AND evidence_certification_count=72 AND contract_reproduction_count=13 AND capability_coverage_count=20 AND canonical_family_count=9 AND canonical_entity_count=134 AND application_consumption_rows=1500 AND operational_account_consumption_rows=59 AND strategy_scope_consumption_rows=24 AND component_latest_rows_total=7129 AND component_archive_rows_total=7129 AND stage_local_canonical_reference_total=70821);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_latest' AND c.conname='ck_m212_g3_latest_counts';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass AND c.conname='ck_m212_g3_latest_counts';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_039'::regclass AND c.conname='expected_ck_039';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_latest::ck_m212_g3_latest_counts',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_039;
END;
$m212_r9_ck_039$;

/* R10 GOVERNED STATEMENT 0433 OF 0473
   statement_code: P220_PF_0388_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_040$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_040;
    CREATE TEMP TABLE tmp_pf_ck_040 (LIKE msbf_ctl.m2_12_g3_bundle_latest) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_040 ADD CONSTRAINT expected_ck_040 CHECK (all_stage_certification_pass_flag AND all_component_contract_pass_flag AND all_evidence_certification_pass_flag AND all_contract_reproduction_pass_flag AND all_capability_boundary_pass_flag AND all_source_graph_edges_pass_flag);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_latest' AND c.conname='ck_m212_g3_latest_pass';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass AND c.conname='ck_m212_g3_latest_pass';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_040'::regclass AND c.conname='expected_ck_040';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_latest::ck_m212_g3_latest_pass',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_040;
END;
$m212_r9_ck_040$;

/* R10 GOVERNED STATEMENT 0434 OF 0473
   statement_code: P220_PF_0389_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_041$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_041;
    CREATE TEMP TABLE tmp_pf_ck_041 (LIKE msbf_ctl.m2_12_g3_bundle_latest) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_041 ADD CONSTRAINT expected_ck_041 CHECK (synthetic_data_only_flag AND no_pii_flag AND certification_only_flag AND NOT production_action_authorized_flag AND NOT external_system_update_authorized_flag AND NOT legal_or_regulatory_certified_flag AND NOT empirical_or_causal_optimization_authorized_flag AND NOT deployment_authorized_flag AND NOT module3_execution_authorized_flag);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_latest' AND c.conname='ck_m212_g3_latest_boundary';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass AND c.conname='ck_m212_g3_latest_boundary';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_041'::regclass AND c.conname='expected_ck_041';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_latest::ck_m212_g3_latest_boundary',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_041;
END;
$m212_r9_ck_041$;

/* R10 GOVERNED STATEMENT 0435 OF 0473
   statement_code: P220_PF_0390_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_042$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_042;
    CREATE TEMP TABLE tmp_pf_ck_042 (LIKE msbf_ctl.m2_12_g3_bundle_latest) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_042 ADD CONSTRAINT expected_ck_042 CHECK (source_m1_17_combined_hash ~ '^[0-9a-f]{32}$' AND source_m1_17_registry_row_hash ~ '^[0-9a-f]{32}$' AND source_m2_11_contract_set_hash ~ '^[0-9a-f]{32}$' AND source_m2_11_combined_set_hash ~ '^[0-9a-f]{32}$' AND source_m2_11_registry_row_hash ~ '^[0-9a-f]{32}$' AND policy_set_hash ~ '^[0-9a-f]{32}$' AND stage_certification_set_hash ~ '^[0-9a-f]{32}$' AND contract_component_set_hash ~ '^[0-9a-f]{32}$' AND evidence_certification_set_hash ~ '^[0-9a-f]{32}$' AND contract_reproduction_set_hash ~ '^[0-9a-f]{32}$' AND capability_coverage_set_hash ~ '^[0-9a-f]{32}$' AND contract_row_hash ~ '^[0-9a-f]{32}$' AND row_hash ~ '^[0-9a-f]{32}$');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_latest' AND c.conname='ck_m212_g3_latest_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_latest'::regclass AND c.conname='ck_m212_g3_latest_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_042'::regclass AND c.conname='expected_ck_042';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_latest::ck_m212_g3_latest_hashes',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_042;
END;
$m212_r9_ck_042$;

/* R10 GOVERNED STATEMENT 0436 OF 0473
   statement_code: P220_PF_0391_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_pk_m212_g3_archive$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='p')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['archive_id']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS TRUE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=1 AND i.indnatts=1)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['archive_id']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[1]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_archive' AND c.conname='pk_m212_g3_archive'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_PK_M212_G3_ARCHIVE',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_pk_m212_g3_archive$;

/* R10 GOVERNED STATEMENT 0437 OF 0473
   statement_code: P220_PF_0392_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_uq_m212_g3_archive_busine$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='u')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id','bundle_code','contract_version']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS FALSE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','bundle_code','contract_version']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_archive' AND c.conname='uq_m212_g3_archive_business'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_UQ_M212_G3_ARCHIVE_BUSINESS',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_uq_m212_g3_archive_busine$;

/* R10 GOVERNED STATEMENT 0438 OF 0473
   statement_code: P220_PF_0393_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_fk_m212_g3_archive_run$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='f')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id']::text[])
   AND bool_and(rn.nspname='msbf_ctl' AND rt.relname='run_registry')
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(c.confkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.confrelid AND a.attnum=k.attnum)=ARRAY['run_id']::text[])
   AND bool_and(c.confupdtype='a' AND c.confdeltype='r' AND c.confmatchtype='s')
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_class rt ON rt.oid=c.confrelid
JOIN pg_catalog.pg_namespace rn ON rn.oid=rt.relnamespace
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_archive' AND c.conname='fk_m212_g3_archive_run'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_FK_M212_G3_ARCHIVE_RUN',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_fk_m212_g3_archive_run$;

/* R10 GOVERNED STATEMENT 0439 OF 0473
   statement_code: P220_PF_0394_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_046$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_046;
    CREATE TEMP TABLE tmp_pf_ck_046 (LIKE msbf_ctl.m2_12_g3_bundle_archive) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_046 ADD CONSTRAINT expected_ck_046 CHECK (bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND contract_version=1 AND schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND methodology_version='M2_12_METHOD_V1' AND acceptance_gate_id='G3_M2_CONTRACT');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_archive' AND c.conname='ck_m212_g3_archive_identity';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass AND c.conname='ck_m212_g3_archive_identity';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_046'::regclass AND c.conname='expected_ck_046';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_archive::ck_m212_g3_archive_identity',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_046;
END;
$m212_r9_ck_046$;

/* R10 GOVERNED STATEMENT 0440 OF 0473
   statement_code: P220_PF_0395_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_047$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_047;
    CREATE TEMP TABLE tmp_pf_ck_047 (LIKE msbf_ctl.m2_12_g3_bundle_archive) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_047 ADD CONSTRAINT expected_ck_047 CHECK (source_latest_row_hash ~ '^[0-9a-f]{32}$' AND contract_row_hash ~ '^[0-9a-f]{32}$' AND archive_row_hash ~ '^[0-9a-f]{32}$');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_archive' AND c.conname='ck_m212_g3_archive_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass AND c.conname='ck_m212_g3_archive_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_047'::regclass AND c.conname='expected_ck_047';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_archive::ck_m212_g3_archive_hashes',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_047;
END;
$m212_r9_ck_047$;

/* R10 GOVERNED STATEMENT 0441 OF 0473
   statement_code: P220_PF_0396_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_pk_m212_g3_registry$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='p')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['registry_id']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS TRUE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=1 AND i.indnatts=1)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['registry_id']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[1]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_registry' AND c.conname='pk_m212_g3_registry'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_PK_M212_G3_REGISTRY',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_pk_m212_g3_registry$;

/* R10 GOVERNED STATEMENT 0442 OF 0473
   statement_code: P220_PF_0397_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_uq_m212_g3_registry_busin$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='u')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id','bundle_code','contract_version']::text[])
   AND bool_and(c.conindid<>0)
   AND bool_and(i.indisunique)
   AND bool_and(i.indisprimary IS FALSE)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and(am.amname='btree')
   AND bool_and(ix.relnamespace=t.relnamespace)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','bundle_code','contract_version']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ix.relam)))
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_index i ON i.indexrelid=c.conindid
JOIN pg_catalog.pg_class ix ON ix.oid=i.indexrelid
JOIN pg_catalog.pg_am am ON am.oid=ix.relam
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_registry' AND c.conname='uq_m212_g3_registry_business'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_UQ_M212_G3_REGISTRY_BUSINESS',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_uq_m212_g3_registry_busin$;

/* R10 GOVERNED STATEMENT 0443 OF 0473
   statement_code: P220_PF_0398_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_fk_m212_g3_registry_run$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='f')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id']::text[])
   AND bool_and(rn.nspname='msbf_ctl' AND rt.relname='run_registry')
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(c.confkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.confrelid AND a.attnum=k.attnum)=ARRAY['run_id']::text[])
   AND bool_and(c.confupdtype='a' AND c.confdeltype='r' AND c.confmatchtype='s')
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_class rt ON rt.oid=c.confrelid
JOIN pg_catalog.pg_namespace rn ON rn.oid=rt.relnamespace
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_registry' AND c.conname='fk_m212_g3_registry_run'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_FK_M212_G3_REGISTRY_RUN',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_fk_m212_g3_registry_run$;

/* R10 GOVERNED STATEMENT 0444 OF 0473
   statement_code: P220_PF_0399_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_constraint_fk_m212_g3_registry_polic$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(c.contype='f')
   AND bool_and(c.convalidated)
   AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
   AND bool_and(c.connoinherit)
   AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
   AND bool_and((SELECT coalesce(array_agg(a.attname::text ORDER BY k.ord),ARRAY[]::text[])
                 FROM unnest(c.conkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id','policy_code','policy_version']::text[])
   AND bool_and(rn.nspname='msbf_ctl' AND rt.relname='m2_12_policy_profile')
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(c.confkey) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=c.confrelid AND a.attnum=k.attnum)=ARRAY['module1_run_id','policy_code','policy_version']::text[])
   AND bool_and(c.confupdtype='a' AND c.confdeltype='r' AND c.confmatchtype='s')
FROM pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
JOIN pg_catalog.pg_class rt ON rt.oid=c.confrelid
JOIN pg_catalog.pg_namespace rn ON rn.oid=rt.relnamespace
WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_registry' AND c.conname='fk_m212_g3_registry_policy'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 constraint structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_CONSTRAINT_FK_M212_G3_REGISTRY_POLICY',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_constraint_fk_m212_g3_registry_polic$;

/* R10 GOVERNED STATEMENT 0445 OF 0473
   statement_code: P220_PF_0400_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_052$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_052;
    CREATE TEMP TABLE tmp_pf_ck_052 (LIKE msbf_ctl.m2_12_g3_bundle_registry) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_052 ADD CONSTRAINT expected_ck_052 CHECK (bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND contract_version=1 AND schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND methodology_version='M2_12_METHOD_V1' AND acceptance_gate_id='G3_M2_CONTRACT');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_registry' AND c.conname='ck_m212_g3_registry_identity';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass AND c.conname='ck_m212_g3_registry_identity';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_052'::regclass AND c.conname='expected_ck_052';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_registry::ck_m212_g3_registry_identity',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_052;
END;
$m212_r9_ck_052$;

/* R10 GOVERNED STATEMENT 0446 OF 0473
   statement_code: P220_PF_0401_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_053$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_053;
    CREATE TEMP TABLE tmp_pf_ck_053 (LIKE msbf_ctl.m2_12_g3_bundle_registry) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_053 ADD CONSTRAINT expected_ck_053 CHECK (source_node_count=12 AND component_contract_count=13 AND source_graph_edge_count=19 AND evidence_certification_count=72 AND contract_reproduction_count=13 AND capability_coverage_count=20 AND canonical_family_count=9 AND canonical_entity_count=134 AND application_consumption_rows=1500 AND operational_account_consumption_rows=59 AND strategy_scope_consumption_rows=24 AND component_latest_rows_total=7129 AND component_archive_rows_total=7129 AND stage_local_canonical_reference_total=70821);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_registry' AND c.conname='ck_m212_g3_registry_counts';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass AND c.conname='ck_m212_g3_registry_counts';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_053'::regclass AND c.conname='expected_ck_053';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_registry::ck_m212_g3_registry_counts',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_053;
END;
$m212_r9_ck_053$;

/* R10 GOVERNED STATEMENT 0447 OF 0473
   statement_code: P220_PF_0402_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_054$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_054;
    CREATE TEMP TABLE tmp_pf_ck_054 (LIKE msbf_ctl.m2_12_g3_bundle_registry) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_054 ADD CONSTRAINT expected_ck_054 CHECK (all_stage_certification_pass_flag AND all_component_contract_pass_flag AND all_evidence_certification_pass_flag AND all_contract_reproduction_pass_flag AND all_capability_boundary_pass_flag AND all_source_graph_edges_pass_flag);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_registry' AND c.conname='ck_m212_g3_registry_pass';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass AND c.conname='ck_m212_g3_registry_pass';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_054'::regclass AND c.conname='expected_ck_054';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_registry::ck_m212_g3_registry_pass',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_054;
END;
$m212_r9_ck_054$;

/* R10 GOVERNED STATEMENT 0448 OF 0473
   statement_code: P220_PF_0403_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_055$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_055;
    CREATE TEMP TABLE tmp_pf_ck_055 (LIKE msbf_ctl.m2_12_g3_bundle_registry) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_055 ADD CONSTRAINT expected_ck_055 CHECK (synthetic_data_only_flag AND no_pii_flag AND certification_only_flag AND NOT production_action_authorized_flag AND NOT external_system_update_authorized_flag AND NOT legal_or_regulatory_certified_flag AND NOT empirical_or_causal_optimization_authorized_flag AND NOT deployment_authorized_flag AND NOT module3_execution_authorized_flag);

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_registry' AND c.conname='ck_m212_g3_registry_boundary';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass AND c.conname='ck_m212_g3_registry_boundary';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_055'::regclass AND c.conname='expected_ck_055';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_registry::ck_m212_g3_registry_boundary',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_055;
END;
$m212_r9_ck_055$;

/* R10 GOVERNED STATEMENT 0449 OF 0473
   statement_code: P220_PF_0404_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_056$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_056;
    CREATE TEMP TABLE tmp_pf_ck_056 (LIKE msbf_ctl.m2_12_g3_bundle_registry) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_056 ADD CONSTRAINT expected_ck_056 CHECK (contract_status IN ('GENERATING','GENERATED','VALIDATED','ACCEPTED') AND (contract_status<>'GENERATING' OR (generated_at IS NULL AND validated_at IS NULL AND accepted_at IS NULL)) AND (contract_status<>'GENERATED' OR generated_at IS NOT NULL) AND (contract_status<>'VALIDATED' OR (generated_at IS NOT NULL AND validated_at IS NOT NULL)) AND (contract_status<>'ACCEPTED' OR (generated_at IS NOT NULL AND validated_at IS NOT NULL AND accepted_at IS NOT NULL)));

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_registry' AND c.conname='ck_m212_g3_registry_status';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass AND c.conname='ck_m212_g3_registry_status';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_056'::regclass AND c.conname='expected_ck_056';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_registry::ck_m212_g3_registry_status',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_056;
END;
$m212_r9_ck_056$;

/* R10 GOVERNED STATEMENT 0450 OF 0473
   statement_code: P220_PF_0405_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_ck_057$
DECLARE
    v_meta_ok boolean;
    v_actual_tree text;
    v_expected_tree text;
    v_actual_key smallint[];
    v_expected_key smallint[];
BEGIN
    DROP TABLE IF EXISTS pg_temp.tmp_pf_ck_057;
    CREATE TEMP TABLE tmp_pf_ck_057 (LIKE msbf_ctl.m2_12_g3_bundle_registry) ON COMMIT DROP;
    ALTER TABLE pg_temp.tmp_pf_ck_057 ADD CONSTRAINT expected_ck_057 CHECK (accepted_m2_11_project_sha256 ~ '^[0-9a-f]{64}$' AND accepted_m2_11_contract_set_hash ~ '^[0-9a-f]{32}$' AND accepted_m2_11_combined_set_hash ~ '^[0-9a-f]{32}$' AND accepted_m2_11_registry_row_hash ~ '^[0-9a-f]{32}$' AND policy_set_hash ~ '^[0-9a-f]{32}$' AND stage_certification_set_hash ~ '^[0-9a-f]{32}$' AND contract_component_set_hash ~ '^[0-9a-f]{32}$' AND evidence_certification_set_hash ~ '^[0-9a-f]{32}$' AND contract_reproduction_set_hash ~ '^[0-9a-f]{32}$' AND capability_coverage_set_hash ~ '^[0-9a-f]{32}$' AND latest_set_hash ~ '^[0-9a-f]{32}$' AND archive_set_hash ~ '^[0-9a-f]{32}$' AND registry_set_hash ~ '^[0-9a-f]{32}$' AND latest_contract_row_hash ~ '^[0-9a-f]{32}$' AND archive_contract_row_hash ~ '^[0-9a-f]{32}$' AND contract_set_hash ~ '^[0-9a-f]{32}$' AND combined_set_hash ~ '^[0-9a-f]{32}$' AND row_hash ~ '^[0-9a-f]{32}$');

    SELECT count(*)=1
       AND bool_and(c.contype='c')
       AND bool_and(c.convalidated)
       AND bool_and(NOT c.condeferrable AND NOT c.condeferred)
       AND bool_and(NOT c.connoinherit)
       AND bool_and(c.conislocal AND c.coninhcount=0 AND c.conparentid=0)
      INTO v_meta_ok
      FROM pg_catalog.pg_constraint c
      JOIN pg_catalog.pg_class t ON t.oid=c.conrelid
      JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace
     WHERE n.nspname='msbf_ctl' AND t.relname='m2_12_g3_bundle_registry' AND c.conname='ck_m212_g3_registry_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_actual_tree, v_actual_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass AND c.conname='ck_m212_g3_registry_hashes';

    SELECT regexp_replace(c.conbin::text, ':location -?[0-9]+', ':location -1', 'g'), c.conkey
      INTO v_expected_tree, v_expected_key
      FROM pg_catalog.pg_constraint c
     WHERE c.conrelid='pg_temp.tmp_pf_ck_057'::regclass AND c.conname='expected_ck_057';

    IF NOT COALESCE(v_meta_ok,false)
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_actual_key IS DISTINCT FROM v_expected_key THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 CHECK structural postflight failed',
            DETAIL='constraint=msbf_ctl.m2_12_g3_bundle_registry::ck_m212_g3_registry_hashes',
            HINT='Compare parsed pg_constraint.conbin trees and exact constrained-column attnums; decompiled text is diagnostic only.';
    END IF;
    DROP TABLE pg_temp.tmp_pf_ck_057;
END;
$m212_r9_ck_057$;

/* R10 GOVERNED STATEMENT 0451 OF 0473
   statement_code: P220_PF_0406_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_index_ix_m212_stage_status$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(tn.nspname='msbf_m2')
   AND bool_and(t.relname='module2_stage_certification_snapshot')
   AND bool_and(insp.nspname='msbf_m2')
   AND bool_and(ic.relname='ix_m212_stage_status')
   AND bool_and(am.amname='btree')
   AND bool_and(i.indisunique IS FALSE)
   AND bool_and(NOT i.indisprimary)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','certification_status','certification_node_sequence']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ic.relam)))
FROM pg_catalog.pg_index i
JOIN pg_catalog.pg_class ic ON ic.oid=i.indexrelid
JOIN pg_catalog.pg_namespace insp ON insp.oid=ic.relnamespace
JOIN pg_catalog.pg_class t ON t.oid=i.indrelid
JOIN pg_catalog.pg_namespace tn ON tn.oid=t.relnamespace
JOIN pg_catalog.pg_am am ON am.oid=ic.relam
WHERE insp.nspname='msbf_m2' AND ic.relname='ix_m212_stage_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 index structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_INDEX_IX_M212_STAGE_STATUS',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_index_ix_m212_stage_status$;

/* R10 GOVERNED STATEMENT 0452 OF 0473
   statement_code: P220_PF_0407_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_index_ix_m212_component_status$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(tn.nspname='msbf_m2')
   AND bool_and(t.relname='module2_contract_component_snapshot')
   AND bool_and(insp.nspname='msbf_m2')
   AND bool_and(ic.relname='ix_m212_component_status')
   AND bool_and(am.amname='btree')
   AND bool_and(i.indisunique IS FALSE)
   AND bool_and(NOT i.indisprimary)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','certification_status','component_sequence']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ic.relam)))
FROM pg_catalog.pg_index i
JOIN pg_catalog.pg_class ic ON ic.oid=i.indexrelid
JOIN pg_catalog.pg_namespace insp ON insp.oid=ic.relnamespace
JOIN pg_catalog.pg_class t ON t.oid=i.indrelid
JOIN pg_catalog.pg_namespace tn ON tn.oid=t.relnamespace
JOIN pg_catalog.pg_am am ON am.oid=ic.relam
WHERE insp.nspname='msbf_m2' AND ic.relname='ix_m212_component_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 index structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_INDEX_IX_M212_COMPONENT_STATUS',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_index_ix_m212_component_status$;

/* R10 GOVERNED STATEMENT 0453 OF 0473
   statement_code: P220_PF_0408_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_index_ix_m212_evidence_family$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(tn.nspname='msbf_m2')
   AND bool_and(t.relname='module2_evidence_certification_snapshot')
   AND bool_and(insp.nspname='msbf_m2')
   AND bool_and(ic.relname='ix_m212_evidence_family')
   AND bool_and(am.amname='btree')
   AND bool_and(i.indisunique IS FALSE)
   AND bool_and(NOT i.indisprimary)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=4 AND i.indnatts=4)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','evidence_family_code','certification_status','node_sequence']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[4]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ic.relam)))
FROM pg_catalog.pg_index i
JOIN pg_catalog.pg_class ic ON ic.oid=i.indexrelid
JOIN pg_catalog.pg_namespace insp ON insp.oid=ic.relnamespace
JOIN pg_catalog.pg_class t ON t.oid=i.indrelid
JOIN pg_catalog.pg_namespace tn ON tn.oid=t.relnamespace
JOIN pg_catalog.pg_am am ON am.oid=ic.relam
WHERE insp.nspname='msbf_m2' AND ic.relname='ix_m212_evidence_family'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 index structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_INDEX_IX_M212_EVIDENCE_FAMILY',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_index_ix_m212_evidence_family$;

/* R10 GOVERNED STATEMENT 0454 OF 0473
   statement_code: P220_PF_0409_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_index_ix_m212_reproduction_status$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(tn.nspname='msbf_m2')
   AND bool_and(t.relname='module2_contract_reproduction_snapshot')
   AND bool_and(insp.nspname='msbf_m2')
   AND bool_and(ic.relname='ix_m212_reproduction_status')
   AND bool_and(am.amname='btree')
   AND bool_and(i.indisunique IS FALSE)
   AND bool_and(NOT i.indisprimary)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','reproduction_status','component_sequence']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ic.relam)))
FROM pg_catalog.pg_index i
JOIN pg_catalog.pg_class ic ON ic.oid=i.indexrelid
JOIN pg_catalog.pg_namespace insp ON insp.oid=ic.relnamespace
JOIN pg_catalog.pg_class t ON t.oid=i.indrelid
JOIN pg_catalog.pg_namespace tn ON tn.oid=t.relnamespace
JOIN pg_catalog.pg_am am ON am.oid=ic.relam
WHERE insp.nspname='msbf_m2' AND ic.relname='ix_m212_reproduction_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 index structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_INDEX_IX_M212_REPRODUCTION_STATUS',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_index_ix_m212_reproduction_status$;

/* R10 GOVERNED STATEMENT 0455 OF 0473
   statement_code: P220_PF_0410_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_index_ix_m212_capability_status$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(tn.nspname='msbf_m2')
   AND bool_and(t.relname='module2_capability_coverage_snapshot')
   AND bool_and(insp.nspname='msbf_m2')
   AND bool_and(ic.relname='ix_m212_capability_status')
   AND bool_and(am.amname='btree')
   AND bool_and(i.indisunique IS FALSE)
   AND bool_and(NOT i.indisprimary)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['module1_run_id','coverage_status_code','capability_sequence']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ic.relam)))
FROM pg_catalog.pg_index i
JOIN pg_catalog.pg_class ic ON ic.oid=i.indexrelid
JOIN pg_catalog.pg_namespace insp ON insp.oid=ic.relnamespace
JOIN pg_catalog.pg_class t ON t.oid=i.indrelid
JOIN pg_catalog.pg_namespace tn ON tn.oid=t.relnamespace
JOIN pg_catalog.pg_am am ON am.oid=ic.relam
WHERE insp.nspname='msbf_m2' AND ic.relname='ix_m212_capability_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 index structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_INDEX_IX_M212_CAPABILITY_STATUS',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_index_ix_m212_capability_status$;

/* R10 GOVERNED STATEMENT 0456 OF 0473
   statement_code: P220_PF_0411_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_index_ix_m212_latest_contract$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(tn.nspname='msbf_ctl')
   AND bool_and(t.relname='m2_12_g3_bundle_latest')
   AND bool_and(insp.nspname='msbf_ctl')
   AND bool_and(ic.relname='ix_m212_latest_contract')
   AND bool_and(am.amname='btree')
   AND bool_and(i.indisunique IS FALSE)
   AND bool_and(NOT i.indisprimary)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['bundle_code','contract_version','module1_run_id']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ic.relam)))
FROM pg_catalog.pg_index i
JOIN pg_catalog.pg_class ic ON ic.oid=i.indexrelid
JOIN pg_catalog.pg_namespace insp ON insp.oid=ic.relnamespace
JOIN pg_catalog.pg_class t ON t.oid=i.indrelid
JOIN pg_catalog.pg_namespace tn ON tn.oid=t.relnamespace
JOIN pg_catalog.pg_am am ON am.oid=ic.relam
WHERE insp.nspname='msbf_ctl' AND ic.relname='ix_m212_latest_contract'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 index structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_INDEX_IX_M212_LATEST_CONTRACT',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_index_ix_m212_latest_contract$;

/* R10 GOVERNED STATEMENT 0457 OF 0473
   statement_code: P220_PF_0412_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_index_ix_m212_archive_contract$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(tn.nspname='msbf_ctl')
   AND bool_and(t.relname='m2_12_g3_bundle_archive')
   AND bool_and(insp.nspname='msbf_ctl')
   AND bool_and(ic.relname='ix_m212_archive_contract')
   AND bool_and(am.amname='btree')
   AND bool_and(i.indisunique IS FALSE)
   AND bool_and(NOT i.indisprimary)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['bundle_code','contract_version','module1_run_id']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ic.relam)))
FROM pg_catalog.pg_index i
JOIN pg_catalog.pg_class ic ON ic.oid=i.indexrelid
JOIN pg_catalog.pg_namespace insp ON insp.oid=ic.relnamespace
JOIN pg_catalog.pg_class t ON t.oid=i.indrelid
JOIN pg_catalog.pg_namespace tn ON tn.oid=t.relnamespace
JOIN pg_catalog.pg_am am ON am.oid=ic.relam
WHERE insp.nspname='msbf_ctl' AND ic.relname='ix_m212_archive_contract'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 index structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_INDEX_IX_M212_ARCHIVE_CONTRACT',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_index_ix_m212_archive_contract$;

/* R10 GOVERNED STATEMENT 0458 OF 0473
   statement_code: P220_PF_0413_CONSTRAINT_OR_INDEX
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_p220_struct_index_ix_m212_registry_status$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(tn.nspname='msbf_ctl')
   AND bool_and(t.relname='m2_12_g3_bundle_registry')
   AND bool_and(insp.nspname='msbf_ctl')
   AND bool_and(ic.relname='ix_m212_registry_status')
   AND bool_and(am.amname='btree')
   AND bool_and(i.indisunique IS FALSE)
   AND bool_and(NOT i.indisprimary)
   AND bool_and(NOT i.indnullsnotdistinct)
   AND bool_and(i.indimmediate)
   AND bool_and(NOT i.indisexclusion AND NOT i.indisclustered AND NOT i.indisreplident)
   AND bool_and(i.indisvalid AND i.indisready AND i.indislive)
   AND bool_and(i.indnkeyatts=3 AND i.indnatts=3)
   AND bool_and(i.indexprs IS NULL AND i.indpred IS NULL)
   AND bool_and((SELECT array_agg(a.attname::text ORDER BY k.ord)
                 FROM unnest(i.indkey::smallint[]) WITH ORDINALITY k(attnum,ord)
                 JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
                 WHERE k.ord<=i.indnkeyatts)=ARRAY['contract_status','module1_run_id','contract_version']::text[])
   AND bool_and((SELECT coalesce(array_agg(o.opt ORDER BY o.ord),ARRAY[]::smallint[])
                 FROM unnest(i.indoption::smallint[]) WITH ORDINALITY o(opt,ord)
                 WHERE o.ord<=i.indnkeyatts)=array_fill(0::smallint,ARRAY[3]))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indkey::smallint[], i.indcollation::oid[]) WITH ORDINALITY k(attnum,collation_oid,ord)
        JOIN pg_catalog.pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=k.attnum
        WHERE k.ord<=i.indnkeyatts
          AND k.collation_oid IS DISTINCT FROM a.attcollation))
   AND bool_and(NOT EXISTS (
        SELECT 1
        FROM unnest(i.indclass::oid[]) WITH ORDINALITY oc(opcoid,ord)
        JOIN pg_catalog.pg_opclass opc ON opc.oid=oc.opcoid
        WHERE oc.ord<=i.indnkeyatts
          AND (NOT opc.opcdefault OR opc.opcmethod IS DISTINCT FROM ic.relam)))
FROM pg_catalog.pg_index i
JOIN pg_catalog.pg_class ic ON ic.oid=i.indexrelid
JOIN pg_catalog.pg_namespace insp ON insp.oid=ic.relnamespace
JOIN pg_catalog.pg_class t ON t.oid=i.indrelid
JOIN pg_catalog.pg_namespace tn ON tn.oid=t.relnamespace
JOIN pg_catalog.pg_am am ON am.oid=ic.relam
WHERE insp.nspname='msbf_ctl' AND ic.relname='ix_m212_registry_status'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'M2.12 Program 220 index structural postflight failed',
            DETAIL = 'check_code=P220_STRUCT_INDEX_IX_M212_REGISTRY_STATUS',
            HINT = 'Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.';
    END IF;
END;
$m212_r9_p220_struct_index_ix_m212_registry_status$;

/* R10 GOVERNED STATEMENT 0459 OF 0473
   statement_code: P220_PF_0414_IDENTITY_SEQUENCE
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0414$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_ctl.m2_12_policy_profile_policy_profile_id_seq') IS NOT NULL
   AND pg_get_serial_sequence('msbf_ctl.m2_12_policy_profile','policy_profile_id')='msbf_ctl.m2_12_policy_profile_policy_profile_id_seq'
   AND EXISTS (
       SELECT 1
       FROM pg_catalog.pg_attribute a
       WHERE a.attrelid='msbf_ctl.m2_12_policy_profile'::regclass
         AND a.attname='policy_profile_id'
         AND a.attidentity='a'
         AND a.attnotnull
   )
   AND EXISTS (
       SELECT 1 FROM pg_catalog.pg_depend d
       WHERE d.objid='msbf_ctl.m2_12_policy_profile_policy_profile_id_seq'::regclass
         AND d.refobjid='msbf_ctl.m2_12_policy_profile'::regclass
         AND d.deptype='i'
   )), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0414_IDENTITY_SEQUENCE',
            DETAIL='check_code=P220_PF_0414_IDENTITY_SEQUENCE';
    END IF;
END;
$m212_r8_p220_pf_0414$;

/* R10 GOVERNED STATEMENT 0460 OF 0473
   statement_code: P220_PF_0415_IDENTITY_SEQUENCE
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0415$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq') IS NOT NULL
   AND pg_get_serial_sequence('msbf_ctl.m2_12_g3_bundle_archive','archive_id')='msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq'
   AND EXISTS (
       SELECT 1
       FROM pg_catalog.pg_attribute a
       WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
         AND a.attname='archive_id'
         AND a.attidentity='a'
         AND a.attnotnull
   )
   AND EXISTS (
       SELECT 1 FROM pg_catalog.pg_depend d
       WHERE d.objid='msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq'::regclass
         AND d.refobjid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
         AND d.deptype='i'
   )), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0415_IDENTITY_SEQUENCE',
            DETAIL='check_code=P220_PF_0415_IDENTITY_SEQUENCE';
    END IF;
END;
$m212_r8_p220_pf_0415$;

/* R10 GOVERNED STATEMENT 0461 OF 0473
   statement_code: P220_PF_0416_IDENTITY_SEQUENCE
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0416$
BEGIN
    IF NOT COALESCE((SELECT to_regclass('msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq') IS NOT NULL
   AND pg_get_serial_sequence('msbf_ctl.m2_12_g3_bundle_registry','registry_id')='msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq'
   AND EXISTS (
       SELECT 1
       FROM pg_catalog.pg_attribute a
       WHERE a.attrelid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
         AND a.attname='registry_id'
         AND a.attidentity='a'
         AND a.attnotnull
   )
   AND EXISTS (
       SELECT 1 FROM pg_catalog.pg_depend d
       WHERE d.objid='msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq'::regclass
         AND d.refobjid='msbf_ctl.m2_12_g3_bundle_registry'::regclass
         AND d.deptype='i'
   )), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0416_IDENTITY_SEQUENCE',
            DETAIL='check_code=P220_PF_0416_IDENTITY_SEQUENCE';
    END IF;
END;
$m212_r8_p220_pf_0416$;

/* R10 GOVERNED STATEMENT 0462 OF 0473
   statement_code: P220_PF_0417_PERSISTENT_VIEW
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_view_01$
DECLARE
    v_actual_oid oid;
    v_expected_oid oid;
    v_actual_names text[];
    v_expected_names text[];
    v_actual_types text[];
    v_expected_types text[];
    v_actual_deps text[];
    v_expected_deps text[];
    v_actual_tree text;
    v_expected_tree text;
    v_temp_dep_count bigint;
BEGIN
    DROP VIEW IF EXISTS pg_temp.m2_12_pf_view_01;
    EXECUTE $m212_r9_view_sql_01$CREATE TEMP VIEW m2_12_pf_view_01 AS
SELECT
    CAST(g2.module1_run_id AS bigint) AS "module1_run_id",
    CAST(g2.scenario_id AS bigint) AS "scenario_id",
    CAST(g2.scenario_code AS text) AS "scenario_code",
    CAST(g2.merchant_application_id AS text) AS "merchant_application_id",
    CAST(g2.population_id AS text) AS "population_id",
    CAST(g2.merchant_id AS text) AS "merchant_id",
    CAST(g2.as_of_date AS date) AS "as_of_date",
    CAST(g2.industry_code AS text) AS "industry_code",
    CAST(g2.merchant_size_tier AS text) AS "merchant_size_tier",
    CAST(g2.relationship_stage AS text) AS "relationship_stage",
    CAST(g2.partner_channel_id AS text) AS "partner_channel_id",
    CAST(g2.channel_type AS text) AS "channel_type",
    CAST(g2.source_confidence_score AS numeric(9,6)) AS "source_confidence_score",
    CAST(g2.data_confidence_tier AS text) AS "data_confidence_tier",
    CAST(g2.verification_disposition AS text) AS "verification_disposition",
    CAST(g2.fraud_risk_tier AS smallint) AS "fraud_risk_tier",
    CAST(g2.processor_continuity_status AS text) AS "processor_continuity_status",
    CAST(g2.avg_daily_eligible_sales_30d AS numeric(18,2)) AS "avg_daily_eligible_sales_30d",
    CAST(g2.average_available_balance_30d AS numeric(18,2)) AS "average_available_balance_30d",
    CAST(g2.capacity_tier AS smallint) AS "capacity_tier",
    CAST(g2.affordability_status AS text) AS "affordability_status",
    CAST(g2.archetype_code AS text) AS "archetype_code",
    CAST(g2.operating_resilience_score AS numeric(12,6)) AS "operating_resilience_score",
    CAST(g2.resilience_tier AS smallint) AS "resilience_tier",
    CAST(g2.integrated_risk_score AS numeric(12,6)) AS "integrated_risk_score",
    CAST(g2.synthetic_merchant_risk_proxy AS numeric(12,8)) AS "synthetic_merchant_risk_proxy",
    CAST(g2.integrated_risk_tier AS smallint) AS "integrated_risk_tier",
    CAST(g2.path_weighted_ead_amount AS numeric(18,2)) AS "path_weighted_ead_amount",
    CAST(g2.lgd_input_rate AS numeric(12,8)) AS "lgd_input_rate",
    CAST(g2.schedule_adjusted_comparative_expected_loss_amount AS numeric(18,2)) AS "schedule_adjusted_comparative_expected_loss_amount",
    CAST(g2.risk_adjusted_contribution_amount AS numeric(18,2)) AS "risk_adjusted_contribution_amount",
    CAST(g2.annualized_risk_adjusted_return_rate AS numeric(12,8)) AS "annualized_risk_adjusted_return_rate",
    CAST(g2.economic_tier AS smallint) AS "economic_tier",
    CAST(g2.economic_status AS text) AS "economic_status",
    CAST(g2.hard_stop_recommended_flag AS boolean) AS "hard_stop_recommended_flag",
    CAST(g2.manual_review_recommended_flag AS boolean) AS "manual_review_recommended_flag",
    CAST(g2.m1_15_contract_evidence_status AS text) AS "m1_15_contract_evidence_status",
    CAST(g2.m1_15_contract_row_hash AS text) AS "m1_15_contract_row_hash",
    CAST(g2.primary_source_code AS text) AS "primary_source_code",
    CAST(g2.primary_campaign_id AS text) AS "primary_campaign_id",
    CAST(g2.attribution_confidence_score AS numeric(9,6)) AS "attribution_confidence_score",
    CAST(g2.attribution_confidence_tier AS text) AS "attribution_confidence_tier",
    CAST(g2.touchpoint_count AS smallint) AS "touchpoint_count",
    CAST(g2.assisted_touch_count AS smallint) AS "assisted_touch_count",
    CAST(g2.attribution_evidence_status AS text) AS "attribution_evidence_status",
    CAST(g2.direct_attributable_incurred_cost_amount AS numeric(18,2)) AS "direct_attributable_incurred_cost_amount",
    CAST(g2.internally_allocated_acquisition_cost_amount AS numeric(18,2)) AS "internally_allocated_acquisition_cost_amount",
    CAST(g2.total_incurred_pre_application_cost_amount AS numeric(18,2)) AS "total_incurred_pre_application_cost_amount",
    CAST(g2.detailed_conditional_partner_broker_cost_amount AS numeric(18,2)) AS "detailed_conditional_partner_broker_cost_amount",
    CAST(g2.detailed_total_acquisition_cost_if_booked AS numeric(18,2)) AS "detailed_total_acquisition_cost_if_booked",
    CAST(g2.accepted_m1_14_acquisition_cost_amount AS numeric(18,2)) AS "accepted_m1_14_acquisition_cost_amount",
    CAST(g2.identified_legacy_overlap_amount AS numeric(18,2)) AS "identified_legacy_overlap_amount",
    CAST(g2.unmapped_legacy_proxy_amount AS numeric(18,2)) AS "unmapped_legacy_proxy_amount",
    CAST(g2.incremental_acquisition_cost_beyond_m1_14 AS numeric(18,2)) AS "incremental_acquisition_cost_beyond_m1_14",
    CAST(g2.enhanced_total_acquisition_cost_if_booked AS numeric(18,2)) AS "enhanced_total_acquisition_cost_if_booked",
    CAST(g2.cost_evidence_status AS text) AS "cost_evidence_status",
    CAST(g2.overlap_evidence_status AS text) AS "overlap_evidence_status",
    CAST(g2.acquisition_contract_evidence_status AS text) AS "acquisition_contract_evidence_status",
    CAST(g2.m1_16_contract_row_hash AS text) AS "m1_16_contract_row_hash",
    CAST(app.application_date AS date) AS "application_date",
    CAST(app.processor_account_id AS text) AS "processor_account_id",
    CAST(app.application_status AS text) AS "m1_3_application_status",
    CAST(app.request_hash AS text) AS "m1_3_request_hash",
    CAST(m21.contract_code AS text) AS "m2_1_contract_code",
    CAST(m21.contract_version AS integer) AS "m2_1_contract_version",
    CAST(m21.schema_version AS text) AS "m2_1_schema_version",
    CAST(m21.methodology_version AS text) AS "m2_1_methodology_version",
    CAST(m21.strategy_campaign_code AS text) AS "m2_1_strategy_campaign_code",
    CAST(m21.strategy_campaign_version AS integer) AS "m2_1_strategy_campaign_version",
    CAST(m21.final_route_code AS text) AS "m2_1_final_route_code",
    CAST(m21.final_route_rank AS integer) AS "m2_1_final_route_rank",
    CAST(m21.independent_route_code AS text) AS "m2_1_independent_route_code",
    CAST(m21.independent_route_rank AS integer) AS "m2_1_independent_route_rank",
    CAST(m21.baseline_route_code AS text) AS "m2_1_baseline_route_code",
    CAST(m21.baseline_route_rank AS integer) AS "m2_1_baseline_route_rank",
    CAST(m21.eligible_for_offer_design_flag AS boolean) AS "m2_1_eligible_for_offer_design_flag",
    CAST(m21.hard_stop_flag AS boolean) AS "m2_1_hard_stop_flag",
    CAST(m21.stress_floor_applied_flag AS boolean) AS "m2_1_stress_floor_applied_flag",
    CAST(m21.stress_worsening_flag AS boolean) AS "m2_1_stress_worsening_flag",
    CAST(m21.pass_gate_count AS integer) AS "m2_1_pass_gate_count",
    CAST(m21.review_gate_count AS integer) AS "m2_1_review_gate_count",
    CAST(m21.blocked_gate_count AS integer) AS "m2_1_blocked_gate_count",
    CAST(m21.fail_gate_count AS integer) AS "m2_1_fail_gate_count",
    CAST(m21.primary_reason_code AS text) AS "m2_1_primary_reason_code",
    CAST(m21.secondary_reason_code AS text) AS "m2_1_secondary_reason_code",
    CAST(m21.tertiary_reason_code AS text) AS "m2_1_tertiary_reason_code",
    CAST(m21.reason_codes AS jsonb) AS "m2_1_reason_codes",
    CAST(m21.routing_evidence_status AS text) AS "m2_1_routing_evidence_status",
    CAST(m21.source_m1_15_contract_row_hash AS text) AS "m2_1_source_m1_15_contract_row_hash",
    CAST(m21.source_m1_16_contract_row_hash AS text) AS "m2_1_source_m1_16_contract_row_hash",
    CAST(m21.source_g2_combined_hash AS text) AS "m2_1_source_g2_combined_hash",
    CAST(m21.policy_configuration_hash AS text) AS "m2_1_policy_configuration_hash",
    CAST(m21.contract_row_hash AS text) AS "m2_1_contract_row_hash",
    CAST(m22r.contract_code AS text) AS "m2_2_request_contract_code",
    CAST(m22r.contract_version AS integer) AS "m2_2_request_contract_version",
    CAST(m22r.schema_version AS text) AS "m2_2_request_schema_version",
    CAST(m22r.methodology_version AS text) AS "m2_2_request_methodology_version",
    CAST(m22r.requested_funding_amount AS numeric(18,2)) AS "m2_2_request_requested_funding_amount",
    CAST(m22r.requested_remittance_rate AS numeric(9,6)) AS "m2_2_request_requested_remittance_rate",
    CAST(m22r.requested_expected_payoff_days AS integer) AS "m2_2_request_requested_expected_payoff_days",
    CAST(m22r.requested_total_repayment_amount AS numeric(18,2)) AS "m2_2_request_requested_total_repayment_amount",
    CAST(m22r.requested_finance_charge_amount AS numeric(18,2)) AS "m2_2_request_requested_finance_charge_amount",
    CAST(m22r.requested_payback_multiple AS numeric(9,6)) AS "m2_2_request_requested_payback_multiple",
    CAST(m22r.requested_use_of_proceeds AS text) AS "m2_2_request_requested_use_of_proceeds",
    CAST(m22r.application_channel AS text) AS "m2_2_request_application_channel",
    CAST(m22r.source_request_hash AS text) AS "m2_2_request_source_request_hash",
    CAST(m22r.source_snapshot_row_hash AS text) AS "m2_2_request_source_snapshot_row_hash",
    CAST(m22r.source_m1_3_application_hash AS text) AS "m2_2_request_source_m1_3_application_hash",
    CAST(m22r.policy_configuration_hash AS text) AS "m2_2_request_policy_configuration_hash",
    CAST(m22r.contract_row_hash AS text) AS "m2_2_request_contract_row_hash",
    CAST(m22p.contract_code AS text) AS "m2_2_pricing_contract_code",
    CAST(m22p.contract_version AS integer) AS "m2_2_pricing_contract_version",
    CAST(m22p.schema_version AS text) AS "m2_2_pricing_schema_version",
    CAST(m22p.methodology_version AS text) AS "m2_2_pricing_methodology_version",
    CAST(m22p.source_route_code AS text) AS "m2_2_pricing_source_route_code",
    CAST(m22p.source_route_rank AS integer) AS "m2_2_pricing_source_route_rank",
    CAST(m22p.pricing_disposition_code AS text) AS "m2_2_pricing_pricing_disposition_code",
    CAST(m22p.structure_available_flag AS boolean) AS "m2_2_pricing_structure_available_flag",
    CAST(m22p.review_required_flag AS boolean) AS "m2_2_pricing_review_required_flag",
    CAST(m22p.selected_candidate_template_code AS text) AS "m2_2_pricing_selected_candidate_template_code",
    CAST(m22p.selected_candidate_row_hash AS text) AS "m2_2_pricing_selected_candidate_row_hash",
    CAST(m22p.requested_funding_amount AS numeric(18,2)) AS "m2_2_pricing_requested_funding_amount",
    CAST(m22p.selected_funding_amount AS numeric(18,2)) AS "m2_2_pricing_selected_funding_amount",
    CAST(m22p.selected_remittance_rate AS numeric(9,6)) AS "m2_2_pricing_selected_remittance_rate",
    CAST(m22p.selected_payback_multiple AS numeric(9,6)) AS "m2_2_pricing_selected_payback_multiple",
    CAST(m22p.selected_collection_horizon_days AS integer) AS "m2_2_pricing_selected_collection_horizon_days",
    CAST(m22p.selected_total_repayment_amount AS numeric(18,2)) AS "m2_2_pricing_selected_total_repayment_amount",
    CAST(m22p.selected_finance_charge_amount AS numeric(18,2)) AS "m2_2_pricing_selected_finance_charge_amount",
    CAST(m22p.selected_implied_daily_collection_amount AS numeric(18,2)) AS "m2_2_pricing_selected_implied_daily_collection_amount",
    CAST(m22p.selected_implied_payoff_days AS numeric(18,4)) AS "m2_2_pricing_selected_implied_payoff_days",
    CAST(m22p.selected_amount_to_request_ratio AS numeric(12,8)) AS "m2_2_pricing_selected_amount_to_request_ratio",
    CAST(m22p.candidate_count AS integer) AS "m2_2_pricing_candidate_count",
    CAST(m22p.counteroffer_foundation_flag AS boolean) AS "m2_2_pricing_counteroffer_foundation_flag",
    CAST(m22p.stress_nonimprovement_applied_flag AS boolean) AS "m2_2_pricing_stress_nonimprovement_applied_flag",
    CAST(m22p.primary_reason_code AS text) AS "m2_2_pricing_primary_reason_code",
    CAST(m22p.reason_codes AS jsonb) AS "m2_2_pricing_reason_codes",
    CAST(m22p.routing_evidence_status AS text) AS "m2_2_pricing_routing_evidence_status",
    CAST(m22p.source_m2_1_contract_row_hash AS text) AS "m2_2_pricing_source_m2_1_contract_row_hash",
    CAST(m22p.source_request_contract_row_hash AS text) AS "m2_2_pricing_source_request_contract_row_hash",
    CAST(m22p.source_g2_combined_hash AS text) AS "m2_2_pricing_source_g2_combined_hash",
    CAST(m22p.policy_configuration_hash AS text) AS "m2_2_pricing_policy_configuration_hash",
    CAST(m22p.source_snapshot_row_hash AS text) AS "m2_2_pricing_source_snapshot_row_hash",
    CAST(m22p.contract_row_hash AS text) AS "m2_2_pricing_contract_row_hash",
    CAST(m23.contract_code AS text) AS "m2_3_contract_code",
    CAST(m23.contract_version AS integer) AS "m2_3_contract_version",
    CAST(m23.schema_version AS text) AS "m2_3_schema_version",
    CAST(m23.methodology_version AS text) AS "m2_3_methodology_version",
    CAST(m23.source_pricing_disposition_code AS text) AS "m2_3_source_pricing_disposition_code",
    CAST(m23.final_decision_outcome_code AS text) AS "m2_3_final_decision_outcome_code",
    CAST(m23.final_decision_rank AS integer) AS "m2_3_final_decision_rank",
    CAST(m23.final_offer_authorized_flag AS boolean) AS "m2_3_final_offer_authorized_flag",
    CAST(m23.counteroffer_review_required_flag AS boolean) AS "m2_3_counteroffer_review_required_flag",
    CAST(m23.decline_authorized_flag AS boolean) AS "m2_3_decline_authorized_flag",
    CAST(m23.manual_review_required_flag AS boolean) AS "m2_3_manual_review_required_flag",
    CAST(m23.final_offer_amount AS numeric(18,2)) AS "m2_3_final_offer_amount",
    CAST(m23.final_remittance_rate AS numeric(9,6)) AS "m2_3_final_remittance_rate",
    CAST(m23.final_payback_multiple AS numeric(9,6)) AS "m2_3_final_payback_multiple",
    CAST(m23.final_collection_horizon_days AS integer) AS "m2_3_final_collection_horizon_days",
    CAST(m23.final_total_repayment_amount AS numeric(18,2)) AS "m2_3_final_total_repayment_amount",
    CAST(m23.final_finance_charge_amount AS numeric(18,2)) AS "m2_3_final_finance_charge_amount",
    CAST(m23.final_implied_daily_collection_amount AS numeric(18,2)) AS "m2_3_final_implied_daily_collection_amount",
    CAST(m23.final_implied_payoff_days AS numeric(18,4)) AS "m2_3_final_implied_payoff_days",
    CAST(m23.final_offer_expiration_days AS integer) AS "m2_3_final_offer_expiration_days",
    CAST(m23.final_authorization_evidence_status AS text) AS "m2_3_final_authorization_evidence_status",
    CAST(m23.primary_decision_reason_code AS text) AS "m2_3_primary_decision_reason_code",
    CAST(m23.decision_reason_codes AS jsonb) AS "m2_3_decision_reason_codes",
    CAST(m23.source_m2_2_contract_row_hash AS text) AS "m2_3_source_m2_2_contract_row_hash",
    CAST(m23.source_request_contract_row_hash AS text) AS "m2_3_source_request_contract_row_hash",
    CAST(m23.source_g2_combined_hash AS text) AS "m2_3_source_g2_combined_hash",
    CAST(m23.source_snapshot_row_hash AS text) AS "m2_3_source_snapshot_row_hash",
    CAST(m23.snapshot_row_hash AS text) AS "m2_3_snapshot_row_hash",
    CAST(m23.policy_configuration_hash AS text) AS "m2_3_policy_configuration_hash",
    CAST(m23.contract_row_hash AS text) AS "m2_3_contract_row_hash",
    CAST(m24.contract_code AS text) AS "m2_4_contract_code",
    CAST(m24.contract_version AS integer) AS "m2_4_contract_version",
    CAST(m24.schema_version AS text) AS "m2_4_schema_version",
    CAST(m24.methodology_version AS text) AS "m2_4_methodology_version",
    CAST(m24.source_final_decision_outcome_code AS text) AS "m2_4_source_final_decision_outcome_code",
    CAST(m24.activation_outcome_code AS text) AS "m2_4_activation_outcome_code",
    CAST(m24.activation_outcome_rank AS integer) AS "m2_4_activation_outcome_rank",
    CAST(m24.booking_eligible_flag AS boolean) AS "m2_4_booking_eligible_flag",
    CAST(m24.booking_authorized_flag AS boolean) AS "m2_4_booking_authorized_flag",
    CAST(m24.funding_authorized_flag AS boolean) AS "m2_4_funding_authorized_flag",
    CAST(m24.funding_completed_flag AS boolean) AS "m2_4_funding_completed_flag",
    CAST(m24.portfolio_activated_flag AS boolean) AS "m2_4_portfolio_activated_flag",
    CAST(m24.operational_review_required_flag AS boolean) AS "m2_4_operational_review_required_flag",
    CAST(m24.synthetic_offer_acceptance_assumed_flag AS boolean) AS "m2_4_synthetic_offer_acceptance_assumed_flag",
    CAST(m24.real_funds_movement_flag AS boolean) AS "m2_4_real_funds_movement_flag",
    CAST(m24.external_notice_generation_authorized_flag AS boolean) AS "m2_4_external_notice_generation_authorized_flag",
    CAST(m24.external_notice_transmitted_flag AS boolean) AS "m2_4_external_notice_transmitted_flag",
    CAST(m24.production_adverse_action_notice_flag AS boolean) AS "m2_4_production_adverse_action_notice_flag",
    CAST(m24.synthetic_account_id AS text) AS "m2_4_synthetic_account_id",
    CAST(m24.synthetic_advance_id AS text) AS "m2_4_synthetic_advance_id",
    CAST(m24.booked_amount AS numeric(18,2)) AS "m2_4_booked_amount",
    CAST(m24.funded_amount AS numeric(18,2)) AS "m2_4_funded_amount",
    CAST(m24.activation_remittance_rate AS numeric(9,6)) AS "m2_4_activation_remittance_rate",
    CAST(m24.activation_payback_multiple AS numeric(9,6)) AS "m2_4_activation_payback_multiple",
    CAST(m24.activation_collection_horizon_days AS integer) AS "m2_4_activation_collection_horizon_days",
    CAST(m24.activation_total_repayment_amount AS numeric(18,2)) AS "m2_4_activation_total_repayment_amount",
    CAST(m24.activation_finance_charge_amount AS numeric(18,2)) AS "m2_4_activation_finance_charge_amount",
    CAST(m24.activation_implied_daily_collection_amount AS numeric(18,2)) AS "m2_4_activation_implied_daily_collection_amount",
    CAST(m24.activation_implied_payoff_days AS numeric(18,4)) AS "m2_4_activation_implied_payoff_days",
    CAST(m24.booking_date AS date) AS "m2_4_booking_date",
    CAST(m24.funding_date AS date) AS "m2_4_funding_date",
    CAST(m24.portfolio_activation_date AS date) AS "m2_4_portfolio_activation_date",
    CAST(m24.first_expected_remittance_date AS date) AS "m2_4_first_expected_remittance_date",
    CAST(m24.monitoring_start_date AS date) AS "m2_4_monitoring_start_date",
    CAST(m24.activation_evidence_status AS text) AS "m2_4_activation_evidence_status",
    CAST(m24.notice_control_code AS text) AS "m2_4_notice_control_code",
    CAST(m24.primary_activation_reason_code AS text) AS "m2_4_primary_activation_reason_code",
    CAST(m24.activation_reason_codes AS jsonb) AS "m2_4_activation_reason_codes",
    CAST(m24.source_m2_3_contract_row_hash AS text) AS "m2_4_source_m2_3_contract_row_hash",
    CAST(m24.source_m2_2_contract_row_hash AS text) AS "m2_4_source_m2_2_contract_row_hash",
    CAST(m24.source_g2_combined_hash AS text) AS "m2_4_source_g2_combined_hash",
    CAST(m24.source_snapshot_row_hash AS text) AS "m2_4_source_snapshot_row_hash",
    CAST(m24.snapshot_row_hash AS text) AS "m2_4_snapshot_row_hash",
    CAST(m24.policy_configuration_hash AS text) AS "m2_4_policy_configuration_hash",
    CAST(m24.contract_row_hash AS text) AS "m2_4_contract_row_hash",
    CAST(m21.final_route_code AS text) AS "eligibility_status",
    CAST(m22p.pricing_disposition_code AS text) AS "pricing_disposition",
    CAST(m23.final_decision_outcome_code AS text) AS "final_decision_outcome",
    CAST(m24.activation_outcome_code AS text) AS "activation_outcome",
    CAST((CASE GREATEST(
CASE COALESCE(g2.m1_15_contract_evidence_status,'BLOCKED') WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END,
CASE COALESCE(g2.acquisition_contract_evidence_status,'BLOCKED') WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END,
CASE COALESCE(m21.routing_evidence_status,'BLOCKED') WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END,
CASE COALESCE(m22p.routing_evidence_status,'BLOCKED') WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END,
CASE COALESCE(m23.final_authorization_evidence_status,'BLOCKED') WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END,
CASE COALESCE(m24.activation_evidence_status,'BLOCKED') WHEN 'COMPLETE' THEN 1 WHEN 'PARTIAL' THEN 2 ELSE 3 END)
WHEN 1 THEN 'COMPLETE' WHEN 2 THEN 'PARTIAL' ELSE 'BLOCKED' END) AS text) AS "evidence_status"
FROM msbf_m1.v_m1_17_g2_integrated_consumption g2
LEFT JOIN msbf_m1.merchant_application app
  ON app.created_by_run_id=g2.module1_run_id AND app.merchant_application_id=g2.merchant_application_id
LEFT JOIN msbf_m2.application_eligibility_routing_latest m21
  ON m21.module1_run_id=g2.module1_run_id AND m21.scenario_id=g2.scenario_id AND m21.merchant_application_id=g2.merchant_application_id AND m21.strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE'
LEFT JOIN msbf_m2.application_request_structure_latest m22r
  ON m22r.module1_run_id=g2.module1_run_id AND m22r.merchant_application_id=g2.merchant_application_id
LEFT JOIN msbf_m2.application_pricing_structure_latest m22p
  ON m22p.module1_run_id=g2.module1_run_id AND m22p.scenario_id=g2.scenario_id AND m22p.merchant_application_id=g2.merchant_application_id
LEFT JOIN msbf_m2.application_final_offer_decision_latest m23
  ON m23.module1_run_id=g2.module1_run_id AND m23.scenario_id=g2.scenario_id AND m23.merchant_application_id=g2.merchant_application_id
LEFT JOIN msbf_m2.application_booking_funding_activation_latest m24
  ON m24.module1_run_id=g2.module1_run_id AND m24.scenario_id=g2.scenario_id AND m24.merchant_application_id=g2.merchant_application_id
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=g2.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED');$m212_r9_view_sql_01$;

    v_actual_oid := to_regclass('msbf_m2.v_m2_12_application_origination_consumption');
    v_expected_oid := to_regclass('pg_temp.m2_12_pf_view_01');
    IF v_actual_oid IS NULL OR v_expected_oid IS NULL THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_m2.v_m2_12_application_origination_consumption missing actual or expected parsed relation';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class WHERE oid=v_actual_oid AND relkind='v' AND relpersistence='p') THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_m2.v_m2_12_application_origination_consumption relkind/relpersistence mismatch';
    END IF;

    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_actual_names,v_actual_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_actual_oid AND a.attnum>0 AND NOT a.attisdropped;
    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_expected_names,v_expected_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_expected_oid AND a.attnum>0 AND NOT a.attisdropped;

    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_actual_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND c.oid<>v_actual_oid AND c.relkind IN ('r','p','v','m');
    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_expected_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN' AND c.oid<>v_expected_oid AND c.relkind IN ('r','p','v','m');

    SELECT count(*) INTO v_temp_dep_count
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND n.nspname LIKE 'pg_temp_%';

    SELECT r.ev_action::text INTO v_actual_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN';
    SELECT r.ev_action::text INTO v_expected_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN';
    v_actual_tree := regexp_replace(v_actual_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_expected_tree := regexp_replace(v_expected_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_actual_tree := replace(v_actual_tree, ':relid '||v_actual_oid::text, ':relid 0');
    v_expected_tree := replace(v_expected_tree, ':relid '||v_expected_oid::text, ':relid 0');
    v_actual_tree := replace(v_actual_tree, 'v_m2_12_application_origination_consumption', '__TARGET_VIEW__');
    v_expected_tree := replace(v_expected_tree, 'm2_12_pf_view_01', '__TARGET_VIEW__');

    IF v_actual_names IS DISTINCT FROM v_expected_names
       OR v_actual_types IS DISTINCT FROM v_expected_types
       OR v_actual_deps IS DISTINCT FROM v_expected_deps
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_temp_dep_count<>0 THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 view structural postflight failed',
            DETAIL='view=msbf_m2.v_m2_12_application_origination_consumption',
            HINT='Compare exact ordered columns/types, persistent relation dependencies, normalized pg_rewrite parse trees, and absence of temporary dependencies. Decompiled text is diagnostic only.';
    END IF;
    DROP VIEW pg_temp.m2_12_pf_view_01;
END;
$m212_r9_view_01$;

/* R10 GOVERNED STATEMENT 0463 OF 0473
   statement_code: P220_PF_0418_PERSISTENT_VIEW
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_view_02$
DECLARE
    v_actual_oid oid;
    v_expected_oid oid;
    v_actual_names text[];
    v_expected_names text[];
    v_actual_types text[];
    v_expected_types text[];
    v_actual_deps text[];
    v_expected_deps text[];
    v_actual_tree text;
    v_expected_tree text;
    v_temp_dep_count bigint;
BEGIN
    DROP VIEW IF EXISTS pg_temp.m2_12_pf_view_02;
    EXECUTE $m212_r9_view_sql_02$CREATE TEMP VIEW m2_12_pf_view_02 AS
SELECT
    CAST(m24.module1_run_id AS bigint) AS "module1_run_id",
    CAST(m24.scenario_id AS bigint) AS "scenario_id",
    CAST(m24.scenario_code AS text) AS "scenario_code",
    CAST(m24.merchant_application_id AS text) AS "merchant_application_id",
    CAST(m24.merchant_id AS text) AS "merchant_id",
    CAST(m24.synthetic_account_id AS text) AS "synthetic_account_id",
    CAST(m24.synthetic_advance_id AS text) AS "synthetic_advance_id",
    CAST(m24.contract_code AS text) AS "m2_4_contract_code",
    CAST(m24.contract_version AS integer) AS "m2_4_contract_version",
    CAST(m24.schema_version AS text) AS "m2_4_schema_version",
    CAST(m24.methodology_version AS text) AS "m2_4_methodology_version",
    CAST(m24.population_id AS text) AS "m2_4_population_id",
    CAST(m24.as_of_date AS date) AS "m2_4_as_of_date",
    CAST(m24.source_final_decision_outcome_code AS text) AS "m2_4_source_final_decision_outcome_code",
    CAST(m24.activation_outcome_code AS text) AS "m2_4_activation_outcome_code",
    CAST(m24.activation_outcome_rank AS integer) AS "m2_4_activation_outcome_rank",
    CAST(m24.booking_eligible_flag AS boolean) AS "m2_4_booking_eligible_flag",
    CAST(m24.booking_authorized_flag AS boolean) AS "m2_4_booking_authorized_flag",
    CAST(m24.funding_authorized_flag AS boolean) AS "m2_4_funding_authorized_flag",
    CAST(m24.funding_completed_flag AS boolean) AS "m2_4_funding_completed_flag",
    CAST(m24.portfolio_activated_flag AS boolean) AS "m2_4_portfolio_activated_flag",
    CAST(m24.operational_review_required_flag AS boolean) AS "m2_4_operational_review_required_flag",
    CAST(m24.synthetic_offer_acceptance_assumed_flag AS boolean) AS "m2_4_synthetic_offer_acceptance_assumed_flag",
    CAST(m24.real_funds_movement_flag AS boolean) AS "m2_4_real_funds_movement_flag",
    CAST(m24.external_notice_generation_authorized_flag AS boolean) AS "m2_4_external_notice_generation_authorized_flag",
    CAST(m24.external_notice_transmitted_flag AS boolean) AS "m2_4_external_notice_transmitted_flag",
    CAST(m24.production_adverse_action_notice_flag AS boolean) AS "m2_4_production_adverse_action_notice_flag",
    CAST(m24.booked_amount AS numeric(18,2)) AS "m2_4_booked_amount",
    CAST(m24.funded_amount AS numeric(18,2)) AS "m2_4_funded_amount",
    CAST(m24.activation_remittance_rate AS numeric(9,6)) AS "m2_4_activation_remittance_rate",
    CAST(m24.activation_payback_multiple AS numeric(9,6)) AS "m2_4_activation_payback_multiple",
    CAST(m24.activation_collection_horizon_days AS integer) AS "m2_4_activation_collection_horizon_days",
    CAST(m24.activation_total_repayment_amount AS numeric(18,2)) AS "m2_4_activation_total_repayment_amount",
    CAST(m24.activation_finance_charge_amount AS numeric(18,2)) AS "m2_4_activation_finance_charge_amount",
    CAST(m24.activation_implied_daily_collection_amount AS numeric(18,2)) AS "m2_4_activation_implied_daily_collection_amount",
    CAST(m24.activation_implied_payoff_days AS numeric(18,4)) AS "m2_4_activation_implied_payoff_days",
    CAST(m24.booking_date AS date) AS "m2_4_booking_date",
    CAST(m24.funding_date AS date) AS "m2_4_funding_date",
    CAST(m24.portfolio_activation_date AS date) AS "m2_4_portfolio_activation_date",
    CAST(m24.first_expected_remittance_date AS date) AS "m2_4_first_expected_remittance_date",
    CAST(m24.monitoring_start_date AS date) AS "m2_4_monitoring_start_date",
    CAST(m24.activation_evidence_status AS text) AS "m2_4_activation_evidence_status",
    CAST(m24.notice_control_code AS text) AS "m2_4_notice_control_code",
    CAST(m24.primary_activation_reason_code AS text) AS "m2_4_primary_activation_reason_code",
    CAST(m24.activation_reason_codes AS jsonb) AS "m2_4_activation_reason_codes",
    CAST(m24.source_m2_3_contract_row_hash AS text) AS "m2_4_source_m2_3_contract_row_hash",
    CAST(m24.source_m2_2_contract_row_hash AS text) AS "m2_4_source_m2_2_contract_row_hash",
    CAST(m24.source_g2_combined_hash AS text) AS "m2_4_source_g2_combined_hash",
    CAST(m24.source_snapshot_row_hash AS text) AS "m2_4_source_snapshot_row_hash",
    CAST(m24.snapshot_row_hash AS text) AS "m2_4_snapshot_row_hash",
    CAST(m24.policy_configuration_hash AS text) AS "m2_4_policy_configuration_hash",
    CAST(m24.contract_row_hash AS text) AS "m2_4_contract_row_hash",
    CAST(m25.contract_code AS text) AS "m2_5_contract_code",
    CAST(m25.contract_version AS integer) AS "m2_5_contract_version",
    CAST(m25.schema_version AS text) AS "m2_5_schema_version",
    CAST(m25.methodology_version AS text) AS "m2_5_methodology_version",
    CAST(m25.monitoring_horizon_days AS integer) AS "m2_5_monitoring_horizon_days",
    CAST(m25.latest_monitoring_day_index AS integer) AS "m2_5_latest_monitoring_day_index",
    CAST(m25.latest_monitoring_date AS date) AS "m2_5_latest_monitoring_date",
    CAST(m25.latest_monitoring_status_code AS text) AS "m2_5_latest_monitoring_status_code",
    CAST(m25.latest_monitoring_status_rank AS integer) AS "m2_5_latest_monitoring_status_rank",
    CAST(m25.latest_raw_monitoring_status_code AS text) AS "m2_5_latest_raw_monitoring_status_code",
    CAST(m25.latest_raw_monitoring_status_rank AS integer) AS "m2_5_latest_raw_monitoring_status_rank",
    CAST(m25.stress_status_floor_applied_flag AS boolean) AS "m2_5_stress_status_floor_applied_flag",
    CAST(m25.paid_off_flag AS boolean) AS "m2_5_paid_off_flag",
    CAST(m25.payoff_day_index AS integer) AS "m2_5_payoff_day_index",
    CAST(m25.cumulative_remittance_amount AS numeric(18,2)) AS "m2_5_cumulative_remittance_amount",
    CAST(m25.remaining_receivable_amount AS numeric(18,2)) AS "m2_5_remaining_receivable_amount",
    CAST(m25.principal_exposure_proxy AS numeric(18,2)) AS "m2_5_principal_exposure_proxy",
    CAST(m25.unearned_finance_charge_proxy AS numeric(18,2)) AS "m2_5_unearned_finance_charge_proxy",
    CAST(m25.cumulative_expected_remittance_amount AS numeric(18,2)) AS "m2_5_cumulative_expected_remittance_amount",
    CAST(m25.cumulative_shortfall_amount AS numeric(18,2)) AS "m2_5_cumulative_shortfall_amount",
    CAST(m25.cumulative_pace_ratio AS numeric(12,8)) AS "m2_5_cumulative_pace_ratio",
    CAST(m25.trailing_7_day_remittance_amount AS numeric(18,2)) AS "m2_5_trailing_7_day_remittance_amount",
    CAST(m25.trailing_30_day_remittance_amount AS numeric(18,2)) AS "m2_5_trailing_30_day_remittance_amount",
    CAST(m25.days_since_last_positive_remittance AS integer) AS "m2_5_days_since_last_positive_remittance",
    CAST(m25.zero_sales_streak_days AS integer) AS "m2_5_zero_sales_streak_days",
    CAST(m25.current_available_balance AS numeric(18,2)) AS "m2_5_current_available_balance",
    CAST(m25.current_nsf_count AS smallint) AS "m2_5_current_nsf_count",
    CAST(m25.active_alert_count AS integer) AS "m2_5_active_alert_count",
    CAST(m25.primary_monitoring_reason_code AS text) AS "m2_5_primary_monitoring_reason_code",
    CAST(m25.alert_payload AS jsonb) AS "m2_5_alert_payload",
    CAST(m25.source_daily_row_hash AS text) AS "m2_5_source_daily_row_hash",
    CAST(m25.source_m2_4_contract_row_hash AS text) AS "m2_5_source_m2_4_contract_row_hash",
    CAST(m25.source_advance_row_hash AS text) AS "m2_5_source_advance_row_hash",
    CAST(m25.source_portfolio_row_hash AS text) AS "m2_5_source_portfolio_row_hash",
    CAST(m25.policy_configuration_hash AS text) AS "m2_5_policy_configuration_hash",
    CAST(m25.contract_row_hash AS text) AS "m2_5_contract_row_hash",
    CAST(m26.contract_code AS text) AS "m2_6_contract_code",
    CAST(m26.contract_version AS integer) AS "m2_6_contract_version",
    CAST(m26.schema_version AS text) AS "m2_6_schema_version",
    CAST(m26.methodology_version AS text) AS "m2_6_methodology_version",
    CAST(m26.strategy_outcome_code AS text) AS "m2_6_strategy_outcome_code",
    CAST(m26.strategy_outcome_rank AS integer) AS "m2_6_strategy_outcome_rank",
    CAST(m26.servicing_action_code AS text) AS "m2_6_servicing_action_code",
    CAST(m26.servicing_priority_rank AS integer) AS "m2_6_servicing_priority_rank",
    CAST(m26.servicing_queue_code AS text) AS "m2_6_servicing_queue_code",
    CAST(m26.recommended_action_flag AS boolean) AS "m2_6_recommended_action_flag",
    CAST(m26.review_required_flag AS boolean) AS "m2_6_review_required_flag",
    CAST(m26.temporary_adjustment_review_flag AS boolean) AS "m2_6_temporary_adjustment_review_flag",
    CAST(m26.workout_review_flag AS boolean) AS "m2_6_workout_review_flag",
    CAST(m26.recovery_review_flag AS boolean) AS "m2_6_recovery_review_flag",
    CAST(m26.recommended_action_exposure_amount AS numeric(18,2)) AS "m2_6_recommended_action_exposure_amount",
    CAST(m26.temporary_remittance_rate_factor AS numeric(9,6)) AS "m2_6_temporary_remittance_rate_factor",
    CAST(m26.review_remittance_rate AS numeric(9,6)) AS "m2_6_review_remittance_rate",
    CAST(m26.recommended_review_duration_days AS integer) AS "m2_6_recommended_review_duration_days",
    CAST(m26.reassessment_interval_days AS integer) AS "m2_6_reassessment_interval_days",
    CAST(m26.primary_intervention_reason_code AS text) AS "m2_6_primary_intervention_reason_code",
    CAST(m26.intervention_reason_codes AS jsonb) AS "m2_6_intervention_reason_codes",
    CAST(m26.source_m2_5_contract_row_hash AS text) AS "m2_6_source_m2_5_contract_row_hash",
    CAST(m26.source_snapshot_row_hash AS text) AS "m2_6_source_snapshot_row_hash",
    CAST(m26.strategy_snapshot_row_hash AS text) AS "m2_6_strategy_snapshot_row_hash",
    CAST(m26.policy_configuration_hash AS text) AS "m2_6_policy_configuration_hash",
    CAST(m26.contract_row_hash AS text) AS "m2_6_contract_row_hash",
    CAST(m27.contract_code AS text) AS "m2_7_contract_code",
    CAST(m27.contract_version AS integer) AS "m2_7_contract_version",
    CAST(m27.schema_version AS text) AS "m2_7_schema_version",
    CAST(m27.methodology_version AS text) AS "m2_7_methodology_version",
    CAST(m27.source_strategy_outcome_code AS text) AS "m2_7_source_strategy_outcome_code",
    CAST(m27.source_servicing_action_code AS text) AS "m2_7_source_servicing_action_code",
    CAST(m27.source_recommended_action_exposure_amount AS numeric(18,2)) AS "m2_7_source_recommended_action_exposure_amount",
    CAST(m27.operational_setup_outcome_code AS text) AS "m2_7_operational_setup_outcome_code",
    CAST(m27.operational_setup_action_code AS text) AS "m2_7_operational_setup_action_code",
    CAST(m27.operational_setup_priority_rank AS integer) AS "m2_7_operational_setup_priority_rank",
    CAST(m27.operational_setup_queue_code AS text) AS "m2_7_operational_setup_queue_code",
    CAST(m27.account_setup_status_code AS text) AS "m2_7_account_setup_status_code",
    CAST(m27.setup_authorized_flag AS boolean) AS "m2_7_setup_authorized_flag",
    CAST(m27.blueprint_created_flag AS boolean) AS "m2_7_blueprint_created_flag",
    CAST(m27.setup_review_required_flag AS boolean) AS "m2_7_setup_review_required_flag",
    CAST(m27.no_setup_required_flag AS boolean) AS "m2_7_no_setup_required_flag",
    CAST(m27.synthetic_operational_case_id AS text) AS "m2_7_synthetic_operational_case_id",
    CAST(m27.synthetic_account_setup_id AS text) AS "m2_7_synthetic_account_setup_id",
    CAST(m27.synthetic_servicing_plan_id AS text) AS "m2_7_synthetic_servicing_plan_id",
    CAST(m27.operational_activation_date AS date) AS "m2_7_operational_activation_date",
    CAST(m27.next_reassessment_date AS date) AS "m2_7_next_reassessment_date",
    CAST(m27.applied_temporary_payment_factor AS numeric(9,6)) AS "m2_7_applied_temporary_payment_factor",
    CAST(m27.applied_setup_duration_days AS integer) AS "m2_7_applied_setup_duration_days",
    CAST(m27.applied_reassessment_interval_days AS integer) AS "m2_7_applied_reassessment_interval_days",
    CAST(m27.primary_setup_reason_code AS text) AS "m2_7_primary_setup_reason_code",
    CAST(m27.setup_reason_codes AS jsonb) AS "m2_7_setup_reason_codes",
    CAST(m27.setup_parameter_payload AS jsonb) AS "m2_7_setup_parameter_payload",
    CAST(m27.source_contract_row_hash AS text) AS "m2_7_source_contract_row_hash",
    CAST(m27.source_snapshot_row_hash AS text) AS "m2_7_source_snapshot_row_hash",
    CAST(m27.activation_snapshot_row_hash AS text) AS "m2_7_activation_snapshot_row_hash",
    CAST(m27.account_setup_snapshot_row_hash AS text) AS "m2_7_account_setup_snapshot_row_hash",
    CAST(m27.policy_configuration_hash AS text) AS "m2_7_policy_configuration_hash",
    CAST(m27.contract_row_hash AS text) AS "m2_7_contract_row_hash",
    CAST(m28.contract_code AS text) AS "m2_8_contract_code",
    CAST(m28.contract_version AS integer) AS "m2_8_contract_version",
    CAST(m28.schema_version AS text) AS "m2_8_schema_version",
    CAST(m28.methodology_version AS text) AS "m2_8_methodology_version",
    CAST(m28.source_operational_setup_outcome_code AS text) AS "m2_8_source_operational_setup_outcome_code",
    CAST(m28.source_operational_setup_action_code AS text) AS "m2_8_source_operational_setup_action_code",
    CAST(m28.source_account_setup_status_code AS text) AS "m2_8_source_account_setup_status_code",
    CAST(m28.source_exposure_amount AS numeric(18,2)) AS "m2_8_source_exposure_amount",
    CAST(m28.servicing_execution_outcome_code AS text) AS "m2_8_servicing_execution_outcome_code",
    CAST(m28.servicing_execution_action_code AS text) AS "m2_8_servicing_execution_action_code",
    CAST(m28.servicing_execution_priority_rank AS integer) AS "m2_8_servicing_execution_priority_rank",
    CAST(m28.servicing_execution_queue_code AS text) AS "m2_8_servicing_execution_queue_code",
    CAST(m28.processing_authorized_flag AS boolean) AS "m2_8_processing_authorized_flag",
    CAST(m28.processing_review_required_flag AS boolean) AS "m2_8_processing_review_required_flag",
    CAST(m28.no_processing_required_flag AS boolean) AS "m2_8_no_processing_required_flag",
    CAST(m28.synthetic_servicing_execution_id AS text) AS "m2_8_synthetic_servicing_execution_id",
    CAST(m28.initial_lifecycle_state_code AS text) AS "m2_8_initial_lifecycle_state_code",
    CAST(m28.final_lifecycle_state_code AS text) AS "m2_8_final_lifecycle_state_code",
    CAST(m28.payment_event_count AS integer) AS "m2_8_payment_event_count",
    CAST(m28.settled_event_count AS integer) AS "m2_8_settled_event_count",
    CAST(m28.returned_event_count AS integer) AS "m2_8_returned_event_count",
    CAST(m28.retry_event_count AS integer) AS "m2_8_retry_event_count",
    CAST(m28.standard_daily_payment_amount AS numeric(18,2)) AS "m2_8_standard_daily_payment_amount",
    CAST(m28.temporary_daily_payment_amount AS numeric(18,2)) AS "m2_8_temporary_daily_payment_amount",
    CAST(m28.scheduled_payment_amount AS numeric(18,2)) AS "m2_8_scheduled_payment_amount",
    CAST(m28.processed_payment_amount AS numeric(18,2)) AS "m2_8_processed_payment_amount",
    CAST(m28.returned_payment_amount AS numeric(18,2)) AS "m2_8_returned_payment_amount",
    CAST(m28.retry_payment_amount AS numeric(18,2)) AS "m2_8_retry_payment_amount",
    CAST(m28.ending_simulated_exposure_amount AS numeric(18,2)) AS "m2_8_ending_simulated_exposure_amount",
    CAST(m28.primary_execution_reason_code AS text) AS "m2_8_primary_execution_reason_code",
    CAST(m28.execution_reason_codes AS jsonb) AS "m2_8_execution_reason_codes",
    CAST(m28.source_contract_row_hash AS text) AS "m2_8_source_contract_row_hash",
    CAST(m28.source_snapshot_row_hash AS text) AS "m2_8_source_snapshot_row_hash",
    CAST(m28.execution_snapshot_row_hash AS text) AS "m2_8_execution_snapshot_row_hash",
    CAST(m28.policy_configuration_hash AS text) AS "m2_8_policy_configuration_hash",
    CAST(m28.contract_row_hash AS text) AS "m2_8_contract_row_hash",
    CAST(m29.contract_code AS text) AS "m2_9_contract_code",
    CAST(m29.contract_version AS integer) AS "m2_9_contract_version",
    CAST(m29.schema_version AS text) AS "m2_9_schema_version",
    CAST(m29.methodology_version AS text) AS "m2_9_methodology_version",
    CAST(m29.source_final_lifecycle_state_code AS text) AS "m2_9_source_final_lifecycle_state_code",
    CAST(m29.source_exposure_amount AS numeric(18,2)) AS "m2_9_source_exposure_amount",
    CAST(m29.payment_event_count AS integer) AS "m2_9_payment_event_count",
    CAST(m29.settled_event_count AS integer) AS "m2_9_settled_event_count",
    CAST(m29.returned_event_count AS integer) AS "m2_9_returned_event_count",
    CAST(m29.retry_event_count AS integer) AS "m2_9_retry_event_count",
    CAST(m29.scheduled_payment_amount AS numeric(18,2)) AS "m2_9_scheduled_payment_amount",
    CAST(m29.processed_payment_amount AS numeric(18,2)) AS "m2_9_processed_payment_amount",
    CAST(m29.returned_payment_amount AS numeric(18,2)) AS "m2_9_returned_payment_amount",
    CAST(m29.retry_payment_amount AS numeric(18,2)) AS "m2_9_retry_payment_amount",
    CAST(m29.expected_net_processed_amount AS numeric(18,2)) AS "m2_9_expected_net_processed_amount",
    CAST(m29.reconciliation_variance_amount AS numeric(18,2)) AS "m2_9_reconciliation_variance_amount",
    CAST(m29.source_ending_exposure_amount AS numeric(18,2)) AS "m2_9_source_ending_exposure_amount",
    CAST(m29.expected_ending_exposure_amount AS numeric(18,2)) AS "m2_9_expected_ending_exposure_amount",
    CAST(m29.exposure_variance_amount AS numeric(18,2)) AS "m2_9_exposure_variance_amount",
    CAST(m29.exception_case_count AS integer) AS "m2_9_exception_case_count",
    CAST(m29.resolved_exception_count AS integer) AS "m2_9_resolved_exception_count",
    CAST(m29.unresolved_exception_count AS integer) AS "m2_9_unresolved_exception_count",
    CAST(m29.reconciliation_outcome_code AS text) AS "m2_9_reconciliation_outcome_code",
    CAST(m29.resolution_action_code AS text) AS "m2_9_resolution_action_code",
    CAST(m29.certified_state_code AS text) AS "m2_9_certified_state_code",
    CAST(m29.state_certified_flag AS boolean) AS "m2_9_state_certified_flag",
    CAST(m29.active_state_flag AS boolean) AS "m2_9_active_state_flag",
    CAST(m29.closed_state_flag AS boolean) AS "m2_9_closed_state_flag",
    CAST(m29.review_hold_state_flag AS boolean) AS "m2_9_review_hold_state_flag",
    CAST(m29.exception_resolved_flag AS boolean) AS "m2_9_exception_resolved_flag",
    CAST(m29.certified_exposure_amount AS numeric(18,2)) AS "m2_9_certified_exposure_amount",
    CAST(m29.certification_date AS date) AS "m2_9_certification_date",
    CAST(m29.primary_reconciliation_reason_code AS text) AS "m2_9_primary_reconciliation_reason_code",
    CAST(m29.reconciliation_reason_codes AS jsonb) AS "m2_9_reconciliation_reason_codes",
    CAST(m29.source_contract_row_hash AS text) AS "m2_9_source_contract_row_hash",
    CAST(m29.account_source_row_hash AS text) AS "m2_9_account_source_row_hash",
    CAST(m29.account_reconciliation_row_hash AS text) AS "m2_9_account_reconciliation_row_hash",
    CAST(m29.state_certification_row_hash AS text) AS "m2_9_state_certification_row_hash",
    CAST(m29.policy_configuration_hash AS text) AS "m2_9_policy_configuration_hash",
    CAST(m29.contract_row_hash AS text) AS "m2_9_contract_row_hash",
    CAST(m210.contract_code AS text) AS "m2_10_contract_code",
    CAST(m210.contract_version AS integer) AS "m2_10_contract_version",
    CAST(m210.schema_version AS text) AS "m2_10_schema_version",
    CAST(m210.methodology_version AS text) AS "m2_10_methodology_version",
    CAST(m210.source_final_lifecycle_state_code AS text) AS "m2_10_source_final_lifecycle_state_code",
    CAST(m210.certified_state_code AS text) AS "m2_10_certified_state_code",
    CAST(m210.state_certified_flag AS boolean) AS "m2_10_state_certified_flag",
    CAST(m210.performance_tier_code AS text) AS "m2_10_performance_tier_code",
    CAST(m210.servicing_queue_code AS text) AS "m2_10_servicing_queue_code",
    CAST(m210.payment_activity_flag AS boolean) AS "m2_10_payment_activity_flag",
    CAST(m210.exception_incident_flag AS boolean) AS "m2_10_exception_incident_flag",
    CAST(m210.exception_resolved_flag AS boolean) AS "m2_10_exception_resolved_flag",
    CAST(m210.payment_event_count AS integer) AS "m2_10_payment_event_count",
    CAST(m210.settled_event_count AS integer) AS "m2_10_settled_event_count",
    CAST(m210.returned_event_count AS integer) AS "m2_10_returned_event_count",
    CAST(m210.retry_event_count AS integer) AS "m2_10_retry_event_count",
    CAST(m210.exception_case_count AS integer) AS "m2_10_exception_case_count",
    CAST(m210.resolved_exception_count AS integer) AS "m2_10_resolved_exception_count",
    CAST(m210.unresolved_exception_count AS integer) AS "m2_10_unresolved_exception_count",
    CAST(m210.source_exposure_amount AS numeric(18,2)) AS "m2_10_source_exposure_amount",
    CAST(m210.certified_exposure_amount AS numeric(18,2)) AS "m2_10_certified_exposure_amount",
    CAST(m210.scheduled_payment_amount AS numeric(18,2)) AS "m2_10_scheduled_payment_amount",
    CAST(m210.processed_payment_amount AS numeric(18,2)) AS "m2_10_processed_payment_amount",
    CAST(m210.returned_payment_amount AS numeric(18,2)) AS "m2_10_returned_payment_amount",
    CAST(m210.retry_payment_amount AS numeric(18,2)) AS "m2_10_retry_payment_amount",
    CAST(m210.reconciliation_variance_amount AS numeric(18,2)) AS "m2_10_reconciliation_variance_amount",
    CAST(m210.exposure_variance_amount AS numeric(18,2)) AS "m2_10_exposure_variance_amount",
    CAST(m210.gross_collection_rate AS numeric(18,6)) AS "m2_10_gross_collection_rate",
    CAST(m210.return_rate AS numeric(18,6)) AS "m2_10_return_rate",
    CAST(m210.retry_cure_rate AS numeric(18,6)) AS "m2_10_retry_cure_rate",
    CAST(m210.exposure_retention_rate AS numeric(18,6)) AS "m2_10_exposure_retention_rate",
    CAST(m210.servicing_burden_units AS numeric(12,6)) AS "m2_10_servicing_burden_units",
    CAST(m210.primary_portfolio_reason_code AS text) AS "m2_10_primary_portfolio_reason_code",
    CAST(m210.portfolio_reason_codes AS jsonb) AS "m2_10_portfolio_reason_codes",
    CAST(m210.source_contract_row_hash AS text) AS "m2_10_source_contract_row_hash",
    CAST(m210.source_snapshot_row_hash AS text) AS "m2_10_source_snapshot_row_hash",
    CAST(m210.performance_snapshot_row_hash AS text) AS "m2_10_performance_snapshot_row_hash",
    CAST(m210.policy_configuration_hash AS text) AS "m2_10_policy_configuration_hash",
    CAST(m210.contract_row_hash AS text) AS "m2_10_contract_row_hash",
    CAST(m24.activation_outcome_code AS text) AS "activation_outcome",
    CAST(m25.latest_monitoring_status_code AS text) AS "monitoring_state",
    CAST(m26.strategy_outcome_code AS text) AS "intervention_posture",
    CAST(m27.account_setup_status_code AS text) AS "operational_setup_state",
    CAST(m28.final_lifecycle_state_code AS text) AS "lifecycle_state",
    CAST(m29.certified_state_code AS text) AS "certified_state",
    CAST(m210.performance_tier_code AS text) AS "performance_tier",
    CAST(m210.servicing_queue_code AS text) AS "servicing_queue",
    CAST(m210.certified_exposure_amount AS numeric(18,2)) AS "certified_exposure_amount",
    CAST(m210.servicing_burden_units AS numeric(18,6)) AS "servicing_burden_units"
FROM msbf_m2.application_booking_funding_activation_latest m24
LEFT JOIN msbf_m2.advance_portfolio_monitoring_latest m25
  ON m25.module1_run_id=m24.module1_run_id AND m25.scenario_id=m24.scenario_id AND m25.merchant_application_id=m24.merchant_application_id AND m25.synthetic_account_id=m24.synthetic_account_id AND m25.synthetic_advance_id=m24.synthetic_advance_id
LEFT JOIN msbf_m2.advance_intervention_strategy_latest m26
  ON m26.module1_run_id=m24.module1_run_id AND m26.scenario_id=m24.scenario_id AND m26.merchant_application_id=m24.merchant_application_id AND m26.synthetic_account_id=m24.synthetic_account_id AND m26.synthetic_advance_id=m24.synthetic_advance_id
LEFT JOIN msbf_m2.application_operational_activation_latest m27
  ON m27.module1_run_id=m24.module1_run_id AND m27.scenario_id=m24.scenario_id AND m27.merchant_application_id=m24.merchant_application_id AND m27.synthetic_account_id=m24.synthetic_account_id AND m27.synthetic_advance_id=m24.synthetic_advance_id
LEFT JOIN msbf_m2.application_servicing_execution_latest m28
  ON m28.module1_run_id=m24.module1_run_id AND m28.scenario_id=m24.scenario_id AND m28.merchant_application_id=m24.merchant_application_id AND m28.synthetic_account_id=m24.synthetic_account_id AND m28.synthetic_advance_id=m24.synthetic_advance_id
LEFT JOIN msbf_m2.application_payment_reconciliation_certification_latest m29
  ON m29.module1_run_id=m24.module1_run_id AND m29.scenario_id=m24.scenario_id AND m29.merchant_application_id=m24.merchant_application_id AND m29.synthetic_account_id=m24.synthetic_account_id AND m29.synthetic_advance_id=m24.synthetic_advance_id
LEFT JOIN msbf_m2.application_portfolio_performance_latest m210
  ON m210.module1_run_id=m24.module1_run_id AND m210.scenario_id=m24.scenario_id AND m210.merchant_application_id=m24.merchant_application_id AND m210.synthetic_account_id=m24.synthetic_account_id AND m210.synthetic_advance_id=m24.synthetic_advance_id
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=m24.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED') AND m24.portfolio_activated_flag=true AND m24.synthetic_account_id IS NOT NULL AND m24.synthetic_advance_id IS NOT NULL;$m212_r9_view_sql_02$;

    v_actual_oid := to_regclass('msbf_m2.v_m2_12_operational_account_consumption');
    v_expected_oid := to_regclass('pg_temp.m2_12_pf_view_02');
    IF v_actual_oid IS NULL OR v_expected_oid IS NULL THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_m2.v_m2_12_operational_account_consumption missing actual or expected parsed relation';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class WHERE oid=v_actual_oid AND relkind='v' AND relpersistence='p') THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_m2.v_m2_12_operational_account_consumption relkind/relpersistence mismatch';
    END IF;

    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_actual_names,v_actual_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_actual_oid AND a.attnum>0 AND NOT a.attisdropped;
    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_expected_names,v_expected_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_expected_oid AND a.attnum>0 AND NOT a.attisdropped;

    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_actual_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND c.oid<>v_actual_oid AND c.relkind IN ('r','p','v','m');
    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_expected_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN' AND c.oid<>v_expected_oid AND c.relkind IN ('r','p','v','m');

    SELECT count(*) INTO v_temp_dep_count
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND n.nspname LIKE 'pg_temp_%';

    SELECT r.ev_action::text INTO v_actual_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN';
    SELECT r.ev_action::text INTO v_expected_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN';
    v_actual_tree := regexp_replace(v_actual_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_expected_tree := regexp_replace(v_expected_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_actual_tree := replace(v_actual_tree, ':relid '||v_actual_oid::text, ':relid 0');
    v_expected_tree := replace(v_expected_tree, ':relid '||v_expected_oid::text, ':relid 0');
    v_actual_tree := replace(v_actual_tree, 'v_m2_12_operational_account_consumption', '__TARGET_VIEW__');
    v_expected_tree := replace(v_expected_tree, 'm2_12_pf_view_02', '__TARGET_VIEW__');

    IF v_actual_names IS DISTINCT FROM v_expected_names
       OR v_actual_types IS DISTINCT FROM v_expected_types
       OR v_actual_deps IS DISTINCT FROM v_expected_deps
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_temp_dep_count<>0 THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 view structural postflight failed',
            DETAIL='view=msbf_m2.v_m2_12_operational_account_consumption',
            HINT='Compare exact ordered columns/types, persistent relation dependencies, normalized pg_rewrite parse trees, and absence of temporary dependencies. Decompiled text is diagnostic only.';
    END IF;
    DROP VIEW pg_temp.m2_12_pf_view_02;
END;
$m212_r9_view_02$;

/* R10 GOVERNED STATEMENT 0464 OF 0473
   statement_code: P220_PF_0419_PERSISTENT_VIEW
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_view_03$
DECLARE
    v_actual_oid oid;
    v_expected_oid oid;
    v_actual_names text[];
    v_expected_names text[];
    v_actual_types text[];
    v_expected_types text[];
    v_actual_deps text[];
    v_expected_deps text[];
    v_actual_tree text;
    v_expected_tree text;
    v_temp_dep_count bigint;
BEGIN
    DROP VIEW IF EXISTS pg_temp.m2_12_pf_view_03;
    EXECUTE $m212_r9_view_sql_03$CREATE TEMP VIEW m2_12_pf_view_03 AS
SELECT
    CAST(m211.module1_run_id AS bigint) AS "module1_run_id",
    CAST(m211.contract_code AS text) AS "contract_code",
    CAST(m211.contract_version AS integer) AS "contract_version",
    CAST(m211.schema_version AS text) AS "schema_version",
    CAST(m211.methodology_version AS text) AS "methodology_version",
    CAST(m211.strategy_profile_code AS text) AS "strategy_profile_code",
    CAST(m211.reporting_scope_code AS text) AS "reporting_scope_code",
    CAST(m211.source_m1_17_contract_code AS text) AS "source_m1_17_contract_code",
    CAST(m211.source_m1_17_contract_version AS integer) AS "source_m1_17_contract_version",
    CAST(m211.source_m1_17_schema_version AS text) AS "source_m1_17_schema_version",
    CAST(m211.source_m1_17_methodology_version AS text) AS "source_m1_17_methodology_version",
    CAST(m211.source_m1_17_combined_hash AS text) AS "source_m1_17_combined_hash",
    CAST(m211.source_m2_2_contract_code AS text) AS "source_m2_2_contract_code",
    CAST(m211.source_m2_2_contract_version AS integer) AS "source_m2_2_contract_version",
    CAST(m211.source_m2_2_schema_version AS text) AS "source_m2_2_schema_version",
    CAST(m211.source_m2_2_methodology_version AS text) AS "source_m2_2_methodology_version",
    CAST(m211.source_m2_2_combined_hash AS text) AS "source_m2_2_combined_hash",
    CAST(m211.source_m2_4_contract_code AS text) AS "source_m2_4_contract_code",
    CAST(m211.source_m2_4_contract_version AS integer) AS "source_m2_4_contract_version",
    CAST(m211.source_m2_4_schema_version AS text) AS "source_m2_4_schema_version",
    CAST(m211.source_m2_4_methodology_version AS text) AS "source_m2_4_methodology_version",
    CAST(m211.source_m2_4_combined_hash AS text) AS "source_m2_4_combined_hash",
    CAST(m211.source_m2_7_contract_code AS text) AS "source_m2_7_contract_code",
    CAST(m211.source_m2_7_contract_version AS integer) AS "source_m2_7_contract_version",
    CAST(m211.source_m2_7_schema_version AS text) AS "source_m2_7_schema_version",
    CAST(m211.source_m2_7_methodology_version AS text) AS "source_m2_7_methodology_version",
    CAST(m211.source_m2_7_combined_hash AS text) AS "source_m2_7_combined_hash",
    CAST(m211.source_m2_10_contract_code AS text) AS "source_m2_10_contract_code",
    CAST(m211.source_m2_10_contract_version AS integer) AS "source_m2_10_contract_version",
    CAST(m211.source_m2_10_schema_version AS text) AS "source_m2_10_schema_version",
    CAST(m211.source_m2_10_methodology_version AS text) AS "source_m2_10_methodology_version",
    CAST(m211.source_m2_10_combined_hash AS text) AS "source_m2_10_combined_hash",
    CAST(m211.application_rows AS bigint) AS "application_rows",
    CAST(m211.access_selected_rows AS bigint) AS "access_selected_rows",
    CAST(m211.controlled_review_rows AS bigint) AS "controlled_review_rows",
    CAST(m211.strategy_restriction_rows AS bigint) AS "strategy_restriction_rows",
    CAST(m211.no_feasible_candidate_rows AS bigint) AS "no_feasible_candidate_rows",
    CAST(m211.insufficient_evidence_rows AS bigint) AS "insufficient_evidence_rows",
    CAST(m211.policy_decline_rows AS bigint) AS "policy_decline_rows",
    CAST(m211.blocked_source_rows AS bigint) AS "blocked_source_rows",
    CAST(m211.servicing_account_rows AS bigint) AS "servicing_account_rows",
    CAST(m211.servicing_distinct_application_rows AS bigint) AS "servicing_distinct_application_rows",
    CAST(m211.hard_constraint_violation_count AS bigint) AS "hard_constraint_violation_count",
    CAST(m211.source_risk_improvement_violation_count AS bigint) AS "source_risk_improvement_violation_count",
    CAST(m211.source_return_improvement_violation_count AS bigint) AS "source_return_improvement_violation_count",
    CAST(m211.strategy_access_improvement_violation_count AS bigint) AS "strategy_access_improvement_violation_count",
    CAST(m211.strategy_feasibility_improvement_violation_count AS bigint) AS "strategy_feasibility_improvement_violation_count",
    CAST(m211.comparable_payment_burden_improvement_violation_count AS bigint) AS "comparable_payment_burden_improvement_violation_count",
    CAST(m211.comparable_servicing_burden_improvement_violation_count AS bigint) AS "comparable_servicing_burden_improvement_violation_count",
    CAST(m211.stress_improvement_violation_count AS bigint) AS "stress_improvement_violation_count",
    CAST(m211.stress_strategy_restriction_rows AS bigint) AS "stress_strategy_restriction_rows",
    CAST(m211.absolute_workload_reduction_rows AS bigint) AS "absolute_workload_reduction_rows",
    CAST(m211.access_rate AS numeric(18,10)) AS "access_rate",
    CAST(m211.selected_exposure_amount AS numeric(24,2)) AS "selected_exposure_amount",
    CAST(m211.finance_charge_amount AS numeric(24,2)) AS "finance_charge_amount",
    CAST(m211.expected_loss_amount AS numeric(24,2)) AS "expected_loss_amount",
    CAST(m211.expected_loss_density AS numeric(18,10)) AS "expected_loss_density",
    CAST(m211.risk_adjusted_contribution AS numeric(24,2)) AS "risk_adjusted_contribution",
    CAST(m211.annualized_risk_adjusted_return AS numeric(18,10)) AS "annualized_risk_adjusted_return",
    CAST(m211.servicing_burden_units AS numeric(24,6)) AS "servicing_burden_units",
    CAST(m211.payment_burden_rate AS numeric(18,10)) AS "payment_burden_rate",
    CAST(m211.scope_strategy_score AS numeric(22,12)) AS "scope_strategy_score",
    CAST(m211.governance_balance_score AS numeric(22,12)) AS "governance_balance_score",
    CAST(m211.strategy_evidence_status AS text) AS "strategy_evidence_status",
    CAST(m211.stress_nonimprovement_pass_flag AS boolean) AS "stress_nonimprovement_pass_flag",
    CAST(m211.frontier_eligible_flag AS boolean) AS "frontier_eligible_flag",
    CAST(m211.non_dominated_flag AS boolean) AS "non_dominated_flag",
    CAST(m211.frontier_rank AS integer) AS "frontier_rank",
    CAST(m211.governance_review_priority_code AS text) AS "governance_review_priority_code",
    CAST(m211.primary_governance_review_flag AS boolean) AS "primary_governance_review_flag",
    CAST(m211.servicing_burden_coverage_code AS text) AS "servicing_burden_coverage_code",
    CAST(m211.new_access_servicing_burden_estimated_flag AS boolean) AS "new_access_servicing_burden_estimated_flag",
    CAST(m211.baseline_access_rate_delta AS numeric(18,10)) AS "baseline_access_rate_delta",
    CAST(m211.baseline_selected_exposure_amount_delta AS numeric(24,2)) AS "baseline_selected_exposure_amount_delta",
    CAST(m211.baseline_finance_charge_amount_delta AS numeric(24,2)) AS "baseline_finance_charge_amount_delta",
    CAST(m211.baseline_expected_loss_density_delta AS numeric(18,10)) AS "baseline_expected_loss_density_delta",
    CAST(m211.baseline_risk_adjusted_contribution_delta AS numeric(24,2)) AS "baseline_risk_adjusted_contribution_delta",
    CAST(m211.baseline_annualized_risk_adjusted_return_delta AS numeric(18,10)) AS "baseline_annualized_risk_adjusted_return_delta",
    CAST(m211.baseline_servicing_burden_units_delta AS numeric(24,6)) AS "baseline_servicing_burden_units_delta",
    CAST(m211.baseline_payment_burden_rate_delta AS numeric(18,10)) AS "baseline_payment_burden_rate_delta",
    CAST(m211.primary_reason_code AS text) AS "primary_reason_code",
    CAST(m211.reason_codes AS jsonb) AS "reason_codes",
    CAST(m211.strategy_summary_row_hash AS text) AS "strategy_summary_row_hash",
    CAST(m211.frontier_row_hash AS text) AS "frontier_row_hash",
    CAST(m211.comparison_row_hash AS text) AS "comparison_row_hash",
    CAST(m211.contract_row_hash AS text) AS "contract_row_hash",
    CAST(g3.bundle_code AS text) AS "g3_bundle_code",
    CAST(g3.contract_version AS integer) AS "g3_contract_version",
    CAST(g3.schema_version AS text) AS "g3_schema_version",
    CAST(g3.methodology_version AS text) AS "g3_methodology_version",
    CAST(g3.acceptance_gate_id AS text) AS "g3_acceptance_gate_id",
    CAST(gr.contract_status AS text) AS "g3_contract_status",
    CAST(gr.contract_set_hash AS text) AS "g3_contract_set_hash",
    CAST(gr.combined_set_hash AS text) AS "g3_combined_set_hash",
    CAST(gr.row_hash AS text) AS "g3_registry_row_hash",
    CAST(g3.deployment_authorized_flag AS boolean) AS "deployment_authorized_flag",
    CAST(g3.module3_execution_authorized_flag AS boolean) AS "module3_execution_authorized_flag",
    CAST(m211.contract_row_hash AS text) AS "source_contract_row_hash",
    CAST(m211.application_rows AS bigint) AS "application_count",
    CAST(m211.annualized_risk_adjusted_return AS numeric(28,10)) AS "annualized_return",
    CAST((CASE WHEN m211.non_dominated_flag THEN 'NON_DOMINATED' ELSE 'DOMINATED' END) AS text) AS "dominance_status",
    CAST(m211.governance_review_priority_code AS text) AS "governance_priority_code"
FROM msbf_m2.portfolio_strategy_simulation_latest m211
LEFT JOIN msbf_ctl.m2_12_g3_bundle_latest g3
  ON g3.module1_run_id=m211.module1_run_id AND g3.contract_version=1
LEFT JOIN msbf_ctl.m2_12_g3_bundle_registry gr
  ON gr.module1_run_id=m211.module1_run_id AND gr.contract_version=g3.contract_version
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=m211.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED');$m212_r9_view_sql_03$;

    v_actual_oid := to_regclass('msbf_m2.v_m2_12_strategy_scope_consumption');
    v_expected_oid := to_regclass('pg_temp.m2_12_pf_view_03');
    IF v_actual_oid IS NULL OR v_expected_oid IS NULL THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_m2.v_m2_12_strategy_scope_consumption missing actual or expected parsed relation';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class WHERE oid=v_actual_oid AND relkind='v' AND relpersistence='p') THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_m2.v_m2_12_strategy_scope_consumption relkind/relpersistence mismatch';
    END IF;

    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_actual_names,v_actual_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_actual_oid AND a.attnum>0 AND NOT a.attisdropped;
    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_expected_names,v_expected_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_expected_oid AND a.attnum>0 AND NOT a.attisdropped;

    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_actual_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND c.oid<>v_actual_oid AND c.relkind IN ('r','p','v','m');
    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_expected_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN' AND c.oid<>v_expected_oid AND c.relkind IN ('r','p','v','m');

    SELECT count(*) INTO v_temp_dep_count
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND n.nspname LIKE 'pg_temp_%';

    SELECT r.ev_action::text INTO v_actual_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN';
    SELECT r.ev_action::text INTO v_expected_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN';
    v_actual_tree := regexp_replace(v_actual_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_expected_tree := regexp_replace(v_expected_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_actual_tree := replace(v_actual_tree, ':relid '||v_actual_oid::text, ':relid 0');
    v_expected_tree := replace(v_expected_tree, ':relid '||v_expected_oid::text, ':relid 0');
    v_actual_tree := replace(v_actual_tree, 'v_m2_12_strategy_scope_consumption', '__TARGET_VIEW__');
    v_expected_tree := replace(v_expected_tree, 'm2_12_pf_view_03', '__TARGET_VIEW__');

    IF v_actual_names IS DISTINCT FROM v_expected_names
       OR v_actual_types IS DISTINCT FROM v_expected_types
       OR v_actual_deps IS DISTINCT FROM v_expected_deps
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_temp_dep_count<>0 THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 view structural postflight failed',
            DETAIL='view=msbf_m2.v_m2_12_strategy_scope_consumption',
            HINT='Compare exact ordered columns/types, persistent relation dependencies, normalized pg_rewrite parse trees, and absence of temporary dependencies. Decompiled text is diagnostic only.';
    END IF;
    DROP VIEW pg_temp.m2_12_pf_view_03;
END;
$m212_r9_view_03$;

/* R10 GOVERNED STATEMENT 0465 OF 0473
   statement_code: P220_PF_0420_PERSISTENT_VIEW
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_view_04$
DECLARE
    v_actual_oid oid;
    v_expected_oid oid;
    v_actual_names text[];
    v_expected_names text[];
    v_actual_types text[];
    v_expected_types text[];
    v_actual_deps text[];
    v_expected_deps text[];
    v_actual_tree text;
    v_expected_tree text;
    v_temp_dep_count bigint;
BEGIN
    DROP VIEW IF EXISTS pg_temp.m2_12_pf_view_04;
    EXECUTE $m212_r9_view_sql_04$CREATE TEMP VIEW m2_12_pf_view_04 AS
SELECT
    CAST(s.module1_run_id AS bigint) AS "module1_run_id",
    CAST(s.certification_node_sequence AS smallint) AS "certification_node_sequence",
    CAST(s.stage_code AS text) AS "stage_code",
    CAST(s.repository_stage AS text) AS "repository_stage",
    CAST(s.module_title AS text) AS "module_title",
    CAST(s.registry_relation AS text) AS "registry_relation",
    CAST(s.acceptance_gate_id AS text) AS "acceptance_gate_id",
    CAST(s.acceptance_gate_review_version AS integer) AS "acceptance_gate_review_version",
    CAST(s.acceptance_evidence_code AS text) AS "acceptance_evidence_code",
    CAST(s.contract_status AS text) AS "contract_status",
    CAST(s.gate_status AS text) AS "gate_status",
    CAST(s.acceptance_evidence_status AS text) AS "acceptance_evidence_status",
    CAST(s.historical_acceptance_method AS text) AS "historical_acceptance_method",
    CAST(s.expected_canonical_entities AS bigint) AS "expected_canonical_entities",
    CAST(s.observed_canonical_entities AS bigint) AS "observed_canonical_entities",
    CAST(s.expected_positive_controls AS integer) AS "expected_positive_controls",
    CAST(s.observed_positive_controls AS integer) AS "observed_positive_controls",
    CAST(s.expected_negative_controls AS integer) AS "expected_negative_controls",
    CAST(s.observed_negative_controls AS integer) AS "observed_negative_controls",
    CAST(s.expected_combined_hash AS text) AS "expected_combined_hash",
    CAST(s.observed_combined_hash AS text) AS "observed_combined_hash",
    CAST(s.source_registry_row_hash AS text) AS "source_registry_row_hash",
    CAST(s.required_source_edge_count AS smallint) AS "required_source_edge_count",
    CAST(s.passed_source_edge_count AS smallint) AS "passed_source_edge_count",
    CAST(s.source_graph_status AS text) AS "source_graph_status",
    CAST(s.canonical_identity_status AS text) AS "canonical_identity_status",
    CAST(s.stage_boundary_status AS text) AS "stage_boundary_status",
    CAST(s.certification_status AS text) AS "certification_status",
    CAST(s.interpretation AS text) AS "interpretation",
    CAST(s.row_hash AS text) AS "row_hash",
    CAST(r.bundle_code AS text) AS "g3_bundle_code",
    CAST(r.contract_version AS integer) AS "g3_contract_version",
    CAST(r.contract_status AS text) AS "g3_contract_status",
    CAST(r.combined_set_hash AS text) AS "g3_combined_set_hash"
FROM msbf_m2.module2_stage_certification_snapshot s
LEFT JOIN msbf_ctl.m2_12_g3_bundle_registry r
  ON r.module1_run_id=s.module1_run_id AND r.contract_version=1
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=s.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED');$m212_r9_view_sql_04$;

    v_actual_oid := to_regclass('msbf_ctl.v_m2_12_stage_lineage');
    v_expected_oid := to_regclass('pg_temp.m2_12_pf_view_04');
    IF v_actual_oid IS NULL OR v_expected_oid IS NULL THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_ctl.v_m2_12_stage_lineage missing actual or expected parsed relation';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class WHERE oid=v_actual_oid AND relkind='v' AND relpersistence='p') THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_ctl.v_m2_12_stage_lineage relkind/relpersistence mismatch';
    END IF;

    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_actual_names,v_actual_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_actual_oid AND a.attnum>0 AND NOT a.attisdropped;
    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_expected_names,v_expected_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_expected_oid AND a.attnum>0 AND NOT a.attisdropped;

    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_actual_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND c.oid<>v_actual_oid AND c.relkind IN ('r','p','v','m');
    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_expected_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN' AND c.oid<>v_expected_oid AND c.relkind IN ('r','p','v','m');

    SELECT count(*) INTO v_temp_dep_count
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND n.nspname LIKE 'pg_temp_%';

    SELECT r.ev_action::text INTO v_actual_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN';
    SELECT r.ev_action::text INTO v_expected_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN';
    v_actual_tree := regexp_replace(v_actual_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_expected_tree := regexp_replace(v_expected_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_actual_tree := replace(v_actual_tree, ':relid '||v_actual_oid::text, ':relid 0');
    v_expected_tree := replace(v_expected_tree, ':relid '||v_expected_oid::text, ':relid 0');
    v_actual_tree := replace(v_actual_tree, 'v_m2_12_stage_lineage', '__TARGET_VIEW__');
    v_expected_tree := replace(v_expected_tree, 'm2_12_pf_view_04', '__TARGET_VIEW__');

    IF v_actual_names IS DISTINCT FROM v_expected_names
       OR v_actual_types IS DISTINCT FROM v_expected_types
       OR v_actual_deps IS DISTINCT FROM v_expected_deps
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_temp_dep_count<>0 THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 view structural postflight failed',
            DETAIL='view=msbf_ctl.v_m2_12_stage_lineage',
            HINT='Compare exact ordered columns/types, persistent relation dependencies, normalized pg_rewrite parse trees, and absence of temporary dependencies. Decompiled text is diagnostic only.';
    END IF;
    DROP VIEW pg_temp.m2_12_pf_view_04;
END;
$m212_r9_view_04$;

/* R10 GOVERNED STATEMENT 0466 OF 0473
   statement_code: P220_PF_0421_PERSISTENT_VIEW
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_view_05$
DECLARE
    v_actual_oid oid;
    v_expected_oid oid;
    v_actual_names text[];
    v_expected_names text[];
    v_actual_types text[];
    v_expected_types text[];
    v_actual_deps text[];
    v_expected_deps text[];
    v_actual_tree text;
    v_expected_tree text;
    v_temp_dep_count bigint;
BEGIN
    DROP VIEW IF EXISTS pg_temp.m2_12_pf_view_05;
    EXECUTE $m212_r9_view_sql_05$CREATE TEMP VIEW m2_12_pf_view_05 AS
SELECT
    CAST(c.module1_run_id AS bigint) AS "module1_run_id",
    CAST(c.certification_node_sequence AS smallint) AS "certification_node_sequence",
    CAST(c.stage_code AS text) AS "stage_code",
    CAST(c.repository_stage AS text) AS "repository_stage",
    CAST(c.module_title AS text) AS "module_title",
    CAST(c.component_sequence AS smallint) AS "component_sequence",
    CAST(c.component_contract_code AS text) AS "component_contract_code",
    CAST(c.contract_version AS integer) AS "contract_version",
    CAST(c.schema_version AS text) AS "schema_version",
    CAST(c.methodology_version AS text) AS "methodology_version",
    CAST(c.acceptance_gate_id AS text) AS "acceptance_gate_id",
    CAST(c.registry_relation AS text) AS "registry_relation",
    CAST(c.latest_relation AS text) AS "latest_relation",
    CAST(c.archive_relation AS text) AS "archive_relation",
    CAST(c.latest_business_grain AS text) AS "latest_business_grain",
    CAST(c.latest_business_key_columns AS jsonb) AS "latest_business_key_columns",
    CAST(c.archive_business_key_columns AS jsonb) AS "archive_business_key_columns",
    CAST(c.expected_latest_rows AS bigint) AS "expected_latest_rows",
    CAST(c.observed_latest_rows AS bigint) AS "observed_latest_rows",
    CAST(c.expected_archive_rows AS bigint) AS "expected_archive_rows",
    CAST(c.observed_archive_rows AS bigint) AS "observed_archive_rows",
    CAST(c.stage_expected_canonical_entities AS bigint) AS "stage_expected_canonical_entities",
    CAST(c.expected_positive_controls AS integer) AS "expected_positive_controls",
    CAST(c.observed_positive_controls AS integer) AS "observed_positive_controls",
    CAST(c.expected_negative_controls AS integer) AS "expected_negative_controls",
    CAST(c.observed_negative_controls AS integer) AS "observed_negative_controls",
    CAST(c.expected_contract_set_hash AS text) AS "expected_contract_set_hash",
    CAST(c.observed_contract_set_hash AS text) AS "observed_contract_set_hash",
    CAST(c.expected_stage_combined_set_hash AS text) AS "expected_stage_combined_set_hash",
    CAST(c.observed_stage_combined_set_hash AS text) AS "observed_stage_combined_set_hash",
    CAST(c.expected_registry_row_hash AS text) AS "expected_registry_row_hash",
    CAST(c.observed_registry_row_hash AS text) AS "observed_registry_row_hash",
    CAST(c.expected_latest_set_hash AS text) AS "expected_latest_set_hash",
    CAST(c.observed_latest_set_hash AS text) AS "observed_latest_set_hash",
    CAST(c.expected_archive_set_hash AS text) AS "expected_archive_set_hash",
    CAST(c.observed_archive_set_hash AS text) AS "observed_archive_set_hash",
    CAST(c.contract_status AS text) AS "contract_status",
    CAST(c.gate_status AS text) AS "gate_status",
    CAST(c.acceptance_evidence_code AS text) AS "acceptance_evidence_code",
    CAST(c.acceptance_evidence_status AS text) AS "acceptance_evidence_status",
    CAST(c.required_source_edge_codes AS text[]) AS "required_source_edge_codes",
    CAST(c.required_source_edge_count AS smallint) AS "required_source_edge_count",
    CAST(c.passed_source_edge_count AS smallint) AS "passed_source_edge_count",
    CAST(c.certification_status AS text) AS "certification_status",
    CAST(c.row_hash AS text) AS "row_hash",
    CAST(r.bundle_code AS text) AS "g3_bundle_code",
    CAST(r.contract_version AS integer) AS "g3_contract_version",
    CAST(r.contract_status AS text) AS "g3_contract_status",
    CAST(r.combined_set_hash AS text) AS "g3_combined_set_hash"
FROM msbf_m2.module2_contract_component_snapshot c
LEFT JOIN msbf_ctl.m2_12_g3_bundle_registry r
  ON r.module1_run_id=c.module1_run_id AND r.contract_version=1
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=c.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED');$m212_r9_view_sql_05$;

    v_actual_oid := to_regclass('msbf_ctl.v_m2_12_component_contract_lineage');
    v_expected_oid := to_regclass('pg_temp.m2_12_pf_view_05');
    IF v_actual_oid IS NULL OR v_expected_oid IS NULL THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_ctl.v_m2_12_component_contract_lineage missing actual or expected parsed relation';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class WHERE oid=v_actual_oid AND relkind='v' AND relpersistence='p') THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_ctl.v_m2_12_component_contract_lineage relkind/relpersistence mismatch';
    END IF;

    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_actual_names,v_actual_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_actual_oid AND a.attnum>0 AND NOT a.attisdropped;
    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_expected_names,v_expected_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_expected_oid AND a.attnum>0 AND NOT a.attisdropped;

    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_actual_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND c.oid<>v_actual_oid AND c.relkind IN ('r','p','v','m');
    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_expected_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN' AND c.oid<>v_expected_oid AND c.relkind IN ('r','p','v','m');

    SELECT count(*) INTO v_temp_dep_count
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND n.nspname LIKE 'pg_temp_%';

    SELECT r.ev_action::text INTO v_actual_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN';
    SELECT r.ev_action::text INTO v_expected_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN';
    v_actual_tree := regexp_replace(v_actual_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_expected_tree := regexp_replace(v_expected_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_actual_tree := replace(v_actual_tree, ':relid '||v_actual_oid::text, ':relid 0');
    v_expected_tree := replace(v_expected_tree, ':relid '||v_expected_oid::text, ':relid 0');
    v_actual_tree := replace(v_actual_tree, 'v_m2_12_component_contract_lineage', '__TARGET_VIEW__');
    v_expected_tree := replace(v_expected_tree, 'm2_12_pf_view_05', '__TARGET_VIEW__');

    IF v_actual_names IS DISTINCT FROM v_expected_names
       OR v_actual_types IS DISTINCT FROM v_expected_types
       OR v_actual_deps IS DISTINCT FROM v_expected_deps
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_temp_dep_count<>0 THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 view structural postflight failed',
            DETAIL='view=msbf_ctl.v_m2_12_component_contract_lineage',
            HINT='Compare exact ordered columns/types, persistent relation dependencies, normalized pg_rewrite parse trees, and absence of temporary dependencies. Decompiled text is diagnostic only.';
    END IF;
    DROP VIEW pg_temp.m2_12_pf_view_05;
END;
$m212_r9_view_05$;

/* R10 GOVERNED STATEMENT 0467 OF 0473
   statement_code: P220_PF_0422_PERSISTENT_VIEW
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_view_06$
DECLARE
    v_actual_oid oid;
    v_expected_oid oid;
    v_actual_names text[];
    v_expected_names text[];
    v_actual_types text[];
    v_expected_types text[];
    v_actual_deps text[];
    v_expected_deps text[];
    v_actual_tree text;
    v_expected_tree text;
    v_temp_dep_count bigint;
BEGIN
    DROP VIEW IF EXISTS pg_temp.m2_12_pf_view_06;
    EXECUTE $m212_r9_view_sql_06$CREATE TEMP VIEW m2_12_pf_view_06 AS
SELECT
    CAST(r.module1_run_id AS bigint) AS "module1_run_id",
    CAST(r.bundle_code AS text) AS "bundle_code",
    CAST(r.contract_version AS integer) AS "contract_version",
    CAST(r.schema_version AS text) AS "schema_version",
    CAST(r.methodology_version AS text) AS "methodology_version",
    CAST(r.acceptance_gate_id AS text) AS "acceptance_gate_id",
    CAST(r.policy_code AS text) AS "policy_code",
    CAST(r.policy_version AS integer) AS "policy_version",
    CAST(r.policy_configuration_hash AS text) AS "policy_configuration_hash",
    CAST(r.accepted_m2_11_project_sha256 AS text) AS "accepted_m2_11_project_sha256",
    CAST(r.accepted_m2_11_contract_set_hash AS text) AS "accepted_m2_11_contract_set_hash",
    CAST(r.accepted_m2_11_combined_set_hash AS text) AS "accepted_m2_11_combined_set_hash",
    CAST(r.accepted_m2_11_registry_row_hash AS text) AS "accepted_m2_11_registry_row_hash",
    CAST(r.source_node_count AS integer) AS "source_node_count",
    CAST(r.component_contract_count AS integer) AS "component_contract_count",
    CAST(r.source_graph_edge_count AS integer) AS "source_graph_edge_count",
    CAST(r.evidence_certification_count AS integer) AS "evidence_certification_count",
    CAST(r.contract_reproduction_count AS integer) AS "contract_reproduction_count",
    CAST(r.capability_coverage_count AS integer) AS "capability_coverage_count",
    CAST(r.canonical_family_count AS integer) AS "canonical_family_count",
    CAST(r.canonical_entity_count AS integer) AS "canonical_entity_count",
    CAST(r.application_consumption_rows AS bigint) AS "application_consumption_rows",
    CAST(r.operational_account_consumption_rows AS integer) AS "operational_account_consumption_rows",
    CAST(r.strategy_scope_consumption_rows AS integer) AS "strategy_scope_consumption_rows",
    CAST(r.component_latest_rows_total AS bigint) AS "component_latest_rows_total",
    CAST(r.component_archive_rows_total AS bigint) AS "component_archive_rows_total",
    CAST(r.stage_local_canonical_reference_total AS bigint) AS "stage_local_canonical_reference_total",
    CAST(r.all_stage_certification_pass_flag AS boolean) AS "all_stage_certification_pass_flag",
    CAST(r.all_component_contract_pass_flag AS boolean) AS "all_component_contract_pass_flag",
    CAST(r.all_evidence_certification_pass_flag AS boolean) AS "all_evidence_certification_pass_flag",
    CAST(r.all_contract_reproduction_pass_flag AS boolean) AS "all_contract_reproduction_pass_flag",
    CAST(r.all_capability_boundary_pass_flag AS boolean) AS "all_capability_boundary_pass_flag",
    CAST(r.all_source_graph_edges_pass_flag AS boolean) AS "all_source_graph_edges_pass_flag",
    CAST(r.as_built_certification_scope_code AS text) AS "as_built_certification_scope_code",
    CAST(r.residual_limitation_payload AS jsonb) AS "residual_limitation_payload",
    CAST(r.deferred_capability_payload AS jsonb) AS "deferred_capability_payload",
    CAST(r.synthetic_data_only_flag AS boolean) AS "synthetic_data_only_flag",
    CAST(r.no_pii_flag AS boolean) AS "no_pii_flag",
    CAST(r.certification_only_flag AS boolean) AS "certification_only_flag",
    CAST(r.production_action_authorized_flag AS boolean) AS "production_action_authorized_flag",
    CAST(r.external_system_update_authorized_flag AS boolean) AS "external_system_update_authorized_flag",
    CAST(r.legal_or_regulatory_certified_flag AS boolean) AS "legal_or_regulatory_certified_flag",
    CAST(r.empirical_or_causal_optimization_authorized_flag AS boolean) AS "empirical_or_causal_optimization_authorized_flag",
    CAST(r.deployment_authorized_flag AS boolean) AS "deployment_authorized_flag",
    CAST(r.module3_execution_authorized_flag AS boolean) AS "module3_execution_authorized_flag",
    CAST(r.policy_set_hash AS text) AS "policy_set_hash",
    CAST(r.stage_certification_set_hash AS text) AS "stage_certification_set_hash",
    CAST(r.contract_component_set_hash AS text) AS "contract_component_set_hash",
    CAST(r.evidence_certification_set_hash AS text) AS "evidence_certification_set_hash",
    CAST(r.contract_reproduction_set_hash AS text) AS "contract_reproduction_set_hash",
    CAST(r.capability_coverage_set_hash AS text) AS "capability_coverage_set_hash",
    CAST(r.latest_set_hash AS text) AS "latest_set_hash",
    CAST(r.archive_set_hash AS text) AS "archive_set_hash",
    CAST(r.registry_set_hash AS text) AS "registry_set_hash",
    CAST(r.latest_contract_row_hash AS text) AS "latest_contract_row_hash",
    CAST(r.archive_contract_row_hash AS text) AS "archive_contract_row_hash",
    CAST(r.contract_set_hash AS text) AS "contract_set_hash",
    CAST(r.combined_set_hash AS text) AS "combined_set_hash",
    CAST(r.contract_status AS text) AS "contract_status",
    CAST(r.generated_at AS timestamptz) AS "generated_at",
    CAST(r.validated_at AS timestamptz) AS "validated_at",
    CAST(r.accepted_at AS timestamptz) AS "accepted_at",
    CAST(r.row_hash AS text) AS "row_hash"
FROM msbf_ctl.m2_12_g3_bundle_registry r
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=r.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED') AND r.contract_version=1;$m212_r9_view_sql_06$;

    v_actual_oid := to_regclass('msbf_ctl.v_m2_12_g3_lineage');
    v_expected_oid := to_regclass('pg_temp.m2_12_pf_view_06');
    IF v_actual_oid IS NULL OR v_expected_oid IS NULL THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_ctl.v_m2_12_g3_lineage missing actual or expected parsed relation';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class WHERE oid=v_actual_oid AND relkind='v' AND relpersistence='p') THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_ctl.v_m2_12_g3_lineage relkind/relpersistence mismatch';
    END IF;

    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_actual_names,v_actual_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_actual_oid AND a.attnum>0 AND NOT a.attisdropped;
    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_expected_names,v_expected_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_expected_oid AND a.attnum>0 AND NOT a.attisdropped;

    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_actual_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND c.oid<>v_actual_oid AND c.relkind IN ('r','p','v','m');
    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_expected_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN' AND c.oid<>v_expected_oid AND c.relkind IN ('r','p','v','m');

    SELECT count(*) INTO v_temp_dep_count
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND n.nspname LIKE 'pg_temp_%';

    SELECT r.ev_action::text INTO v_actual_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN';
    SELECT r.ev_action::text INTO v_expected_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN';
    v_actual_tree := regexp_replace(v_actual_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_expected_tree := regexp_replace(v_expected_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_actual_tree := replace(v_actual_tree, ':relid '||v_actual_oid::text, ':relid 0');
    v_expected_tree := replace(v_expected_tree, ':relid '||v_expected_oid::text, ':relid 0');
    v_actual_tree := replace(v_actual_tree, 'v_m2_12_g3_lineage', '__TARGET_VIEW__');
    v_expected_tree := replace(v_expected_tree, 'm2_12_pf_view_06', '__TARGET_VIEW__');

    IF v_actual_names IS DISTINCT FROM v_expected_names
       OR v_actual_types IS DISTINCT FROM v_expected_types
       OR v_actual_deps IS DISTINCT FROM v_expected_deps
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_temp_dep_count<>0 THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 view structural postflight failed',
            DETAIL='view=msbf_ctl.v_m2_12_g3_lineage',
            HINT='Compare exact ordered columns/types, persistent relation dependencies, normalized pg_rewrite parse trees, and absence of temporary dependencies. Decompiled text is diagnostic only.';
    END IF;
    DROP VIEW pg_temp.m2_12_pf_view_06;
END;
$m212_r9_view_06$;

/* R10 GOVERNED STATEMENT 0468 OF 0473
   statement_code: P220_PF_0423_PERSISTENT_VIEW
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r9_view_07$
DECLARE
    v_actual_oid oid;
    v_expected_oid oid;
    v_actual_names text[];
    v_expected_names text[];
    v_actual_types text[];
    v_expected_types text[];
    v_actual_deps text[];
    v_expected_deps text[];
    v_actual_tree text;
    v_expected_tree text;
    v_temp_dep_count bigint;
BEGIN
    DROP VIEW IF EXISTS pg_temp.m2_12_pf_view_07;
    EXECUTE $m212_r9_view_sql_07$CREATE TEMP VIEW m2_12_pf_view_07 AS
SELECT
    CAST(s.module1_run_id AS bigint) AS "module1_run_id",
    CAST(s.contract_code AS text) AS "contract_code",
    CAST(s.contract_version AS integer) AS "contract_version",
    CAST(s.schema_version AS text) AS "schema_version",
    CAST(s.methodology_version AS text) AS "methodology_version",
    CAST(s.strategy_profile_code AS text) AS "strategy_profile_code",
    CAST(s.reporting_scope_code AS text) AS "reporting_scope_code",
    CAST(s.source_m1_17_contract_code AS text) AS "source_m1_17_contract_code",
    CAST(s.source_m1_17_contract_version AS integer) AS "source_m1_17_contract_version",
    CAST(s.source_m1_17_schema_version AS text) AS "source_m1_17_schema_version",
    CAST(s.source_m1_17_methodology_version AS text) AS "source_m1_17_methodology_version",
    CAST(s.source_m1_17_combined_hash AS text) AS "source_m1_17_combined_hash",
    CAST(s.source_m2_2_contract_code AS text) AS "source_m2_2_contract_code",
    CAST(s.source_m2_2_contract_version AS integer) AS "source_m2_2_contract_version",
    CAST(s.source_m2_2_schema_version AS text) AS "source_m2_2_schema_version",
    CAST(s.source_m2_2_methodology_version AS text) AS "source_m2_2_methodology_version",
    CAST(s.source_m2_2_combined_hash AS text) AS "source_m2_2_combined_hash",
    CAST(s.source_m2_4_contract_code AS text) AS "source_m2_4_contract_code",
    CAST(s.source_m2_4_contract_version AS integer) AS "source_m2_4_contract_version",
    CAST(s.source_m2_4_schema_version AS text) AS "source_m2_4_schema_version",
    CAST(s.source_m2_4_methodology_version AS text) AS "source_m2_4_methodology_version",
    CAST(s.source_m2_4_combined_hash AS text) AS "source_m2_4_combined_hash",
    CAST(s.source_m2_7_contract_code AS text) AS "source_m2_7_contract_code",
    CAST(s.source_m2_7_contract_version AS integer) AS "source_m2_7_contract_version",
    CAST(s.source_m2_7_schema_version AS text) AS "source_m2_7_schema_version",
    CAST(s.source_m2_7_methodology_version AS text) AS "source_m2_7_methodology_version",
    CAST(s.source_m2_7_combined_hash AS text) AS "source_m2_7_combined_hash",
    CAST(s.source_m2_10_contract_code AS text) AS "source_m2_10_contract_code",
    CAST(s.source_m2_10_contract_version AS integer) AS "source_m2_10_contract_version",
    CAST(s.source_m2_10_schema_version AS text) AS "source_m2_10_schema_version",
    CAST(s.source_m2_10_methodology_version AS text) AS "source_m2_10_methodology_version",
    CAST(s.source_m2_10_combined_hash AS text) AS "source_m2_10_combined_hash",
    CAST(s.application_rows AS bigint) AS "application_rows",
    CAST(s.access_selected_rows AS bigint) AS "access_selected_rows",
    CAST(s.controlled_review_rows AS bigint) AS "controlled_review_rows",
    CAST(s.strategy_restriction_rows AS bigint) AS "strategy_restriction_rows",
    CAST(s.no_feasible_candidate_rows AS bigint) AS "no_feasible_candidate_rows",
    CAST(s.insufficient_evidence_rows AS bigint) AS "insufficient_evidence_rows",
    CAST(s.policy_decline_rows AS bigint) AS "policy_decline_rows",
    CAST(s.blocked_source_rows AS bigint) AS "blocked_source_rows",
    CAST(s.servicing_account_rows AS bigint) AS "servicing_account_rows",
    CAST(s.servicing_distinct_application_rows AS bigint) AS "servicing_distinct_application_rows",
    CAST(s.hard_constraint_violation_count AS bigint) AS "hard_constraint_violation_count",
    CAST(s.source_risk_improvement_violation_count AS bigint) AS "source_risk_improvement_violation_count",
    CAST(s.source_return_improvement_violation_count AS bigint) AS "source_return_improvement_violation_count",
    CAST(s.strategy_access_improvement_violation_count AS bigint) AS "strategy_access_improvement_violation_count",
    CAST(s.strategy_feasibility_improvement_violation_count AS bigint) AS "strategy_feasibility_improvement_violation_count",
    CAST(s.comparable_payment_burden_improvement_violation_count AS bigint) AS "comparable_payment_burden_improvement_violation_count",
    CAST(s.comparable_servicing_burden_improvement_violation_count AS bigint) AS "comparable_servicing_burden_improvement_violation_count",
    CAST(s.stress_improvement_violation_count AS bigint) AS "stress_improvement_violation_count",
    CAST(s.stress_strategy_restriction_rows AS bigint) AS "stress_strategy_restriction_rows",
    CAST(s.absolute_workload_reduction_rows AS bigint) AS "absolute_workload_reduction_rows",
    CAST(s.access_rate AS numeric(18,10)) AS "access_rate",
    CAST(s.selected_exposure_amount AS numeric(24,2)) AS "selected_exposure_amount",
    CAST(s.finance_charge_amount AS numeric(24,2)) AS "finance_charge_amount",
    CAST(s.expected_loss_amount AS numeric(24,2)) AS "expected_loss_amount",
    CAST(s.expected_loss_density AS numeric(18,10)) AS "expected_loss_density",
    CAST(s.risk_adjusted_contribution AS numeric(24,2)) AS "risk_adjusted_contribution",
    CAST(s.annualized_risk_adjusted_return AS numeric(18,10)) AS "annualized_risk_adjusted_return",
    CAST(s.servicing_burden_units AS numeric(24,6)) AS "servicing_burden_units",
    CAST(s.payment_burden_rate AS numeric(18,10)) AS "payment_burden_rate",
    CAST(s.scope_strategy_score AS numeric(22,12)) AS "scope_strategy_score",
    CAST(s.governance_balance_score AS numeric(22,12)) AS "governance_balance_score",
    CAST(s.strategy_evidence_status AS text) AS "strategy_evidence_status",
    CAST(s.stress_nonimprovement_pass_flag AS boolean) AS "stress_nonimprovement_pass_flag",
    CAST(s.frontier_eligible_flag AS boolean) AS "frontier_eligible_flag",
    CAST(s.non_dominated_flag AS boolean) AS "non_dominated_flag",
    CAST(s.frontier_rank AS integer) AS "frontier_rank",
    CAST(s.governance_review_priority_code AS text) AS "governance_review_priority_code",
    CAST(s.primary_governance_review_flag AS boolean) AS "primary_governance_review_flag",
    CAST(s.servicing_burden_coverage_code AS text) AS "servicing_burden_coverage_code",
    CAST(s.new_access_servicing_burden_estimated_flag AS boolean) AS "new_access_servicing_burden_estimated_flag",
    CAST(s.baseline_access_rate_delta AS numeric(18,10)) AS "baseline_access_rate_delta",
    CAST(s.baseline_selected_exposure_amount_delta AS numeric(24,2)) AS "baseline_selected_exposure_amount_delta",
    CAST(s.baseline_finance_charge_amount_delta AS numeric(24,2)) AS "baseline_finance_charge_amount_delta",
    CAST(s.baseline_expected_loss_density_delta AS numeric(18,10)) AS "baseline_expected_loss_density_delta",
    CAST(s.baseline_risk_adjusted_contribution_delta AS numeric(24,2)) AS "baseline_risk_adjusted_contribution_delta",
    CAST(s.baseline_annualized_risk_adjusted_return_delta AS numeric(18,10)) AS "baseline_annualized_risk_adjusted_return_delta",
    CAST(s.baseline_servicing_burden_units_delta AS numeric(24,6)) AS "baseline_servicing_burden_units_delta",
    CAST(s.baseline_payment_burden_rate_delta AS numeric(18,10)) AS "baseline_payment_burden_rate_delta",
    CAST(s.primary_reason_code AS text) AS "primary_reason_code",
    CAST(s.reason_codes AS jsonb) AS "reason_codes",
    CAST(s.strategy_summary_row_hash AS text) AS "strategy_summary_row_hash",
    CAST(s.frontier_row_hash AS text) AS "frontier_row_hash",
    CAST(s.comparison_row_hash AS text) AS "comparison_row_hash",
    CAST(s.contract_row_hash AS text) AS "contract_row_hash",
    CAST(s.g3_bundle_code AS text) AS "g3_bundle_code",
    CAST(s.g3_contract_version AS integer) AS "g3_contract_version",
    CAST(s.g3_schema_version AS text) AS "g3_schema_version",
    CAST(s.g3_methodology_version AS text) AS "g3_methodology_version",
    CAST(s.g3_acceptance_gate_id AS text) AS "g3_acceptance_gate_id",
    CAST(s.g3_contract_status AS text) AS "g3_contract_status",
    CAST(s.g3_contract_set_hash AS text) AS "g3_contract_set_hash",
    CAST(s.g3_combined_set_hash AS text) AS "g3_combined_set_hash",
    CAST(s.g3_registry_row_hash AS text) AS "g3_registry_row_hash",
    CAST(s.deployment_authorized_flag AS boolean) AS "deployment_authorized_flag",
    CAST(s.module3_execution_authorized_flag AS boolean) AS "module3_execution_authorized_flag",
    CAST(s.source_contract_row_hash AS text) AS "source_contract_row_hash",
    CAST(s.application_count AS bigint) AS "application_count",
    CAST(s.annualized_return AS numeric(28,10)) AS "annualized_return",
    CAST(s.dominance_status AS text) AS "dominance_status",
    CAST(s.governance_priority_code AS text) AS "governance_priority_code"
FROM msbf_m2.v_m2_12_strategy_scope_consumption s
WHERE EXISTS (SELECT 1 FROM msbf_ctl.m2_12_policy_profile scope_policy WHERE scope_policy.module1_run_id=s.module1_run_id AND scope_policy.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND scope_policy.policy_version=1 AND scope_policy.policy_status='APPROVED');$m212_r9_view_sql_07$;

    v_actual_oid := to_regclass('msbf_m2.v_m2_12_power_bi_enterprise_portfolio');
    v_expected_oid := to_regclass('pg_temp.m2_12_pf_view_07');
    IF v_actual_oid IS NULL OR v_expected_oid IS NULL THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_m2.v_m2_12_power_bi_enterprise_portfolio missing actual or expected parsed relation';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class WHERE oid=v_actual_oid AND relkind='v' AND relpersistence='p') THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 220 view structural postflight failed', DETAIL='view=msbf_m2.v_m2_12_power_bi_enterprise_portfolio relkind/relpersistence mismatch';
    END IF;

    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_actual_names,v_actual_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_actual_oid AND a.attnum>0 AND NOT a.attisdropped;
    SELECT array_agg(a.attname::text ORDER BY a.attnum), array_agg(pg_catalog.format_type(a.atttypid,a.atttypmod) ORDER BY a.attnum)
      INTO v_expected_names,v_expected_types
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid=v_expected_oid AND a.attnum>0 AND NOT a.attisdropped;

    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_actual_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND c.oid<>v_actual_oid AND c.relkind IN ('r','p','v','m');
    SELECT coalesce(array_agg(DISTINCT format('%I.%I',n.nspname,c.relname) ORDER BY format('%I.%I',n.nspname,c.relname)),ARRAY[]::text[])
      INTO v_expected_deps
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN' AND c.oid<>v_expected_oid AND c.relkind IN ('r','p','v','m');

    SELECT count(*) INTO v_temp_dep_count
      FROM pg_catalog.pg_rewrite r
      JOIN pg_catalog.pg_depend d ON d.classid='pg_catalog.pg_rewrite'::regclass AND d.objid=r.oid AND d.refclassid='pg_catalog.pg_class'::regclass
      JOIN pg_catalog.pg_class c ON c.oid=d.refobjid
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
     WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN' AND n.nspname LIKE 'pg_temp_%';

    SELECT r.ev_action::text INTO v_actual_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_actual_oid AND r.rulename='_RETURN';
    SELECT r.ev_action::text INTO v_expected_tree FROM pg_catalog.pg_rewrite r WHERE r.ev_class=v_expected_oid AND r.rulename='_RETURN';
    v_actual_tree := regexp_replace(v_actual_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_expected_tree := regexp_replace(v_expected_tree, ':location -?[0-9]+', ':location -1', 'g');
    v_actual_tree := replace(v_actual_tree, ':relid '||v_actual_oid::text, ':relid 0');
    v_expected_tree := replace(v_expected_tree, ':relid '||v_expected_oid::text, ':relid 0');
    v_actual_tree := replace(v_actual_tree, 'v_m2_12_power_bi_enterprise_portfolio', '__TARGET_VIEW__');
    v_expected_tree := replace(v_expected_tree, 'm2_12_pf_view_07', '__TARGET_VIEW__');

    IF v_actual_names IS DISTINCT FROM v_expected_names
       OR v_actual_types IS DISTINCT FROM v_expected_types
       OR v_actual_deps IS DISTINCT FROM v_expected_deps
       OR v_actual_tree IS DISTINCT FROM v_expected_tree
       OR v_temp_dep_count<>0 THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 view structural postflight failed',
            DETAIL='view=msbf_m2.v_m2_12_power_bi_enterprise_portfolio',
            HINT='Compare exact ordered columns/types, persistent relation dependencies, normalized pg_rewrite parse trees, and absence of temporary dependencies. Decompiled text is diagnostic only.';
    END IF;
    DROP VIEW pg_temp.m2_12_pf_view_07;
END;
$m212_r9_view_07$;

/* R10 GOVERNED STATEMENT 0469 OF 0473
   statement_code: P220_PF_0424_ARCHIVE_FUNCTION
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0424$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(p.prorettype='trigger'::regtype)
   AND bool_and(p.provolatile='v')
   AND bool_and(NOT p.prosecdef)
   AND bool_and(p.proparallel='u')
   AND bool_and(l.lanname='plpgsql')
   AND bool_and(coalesce(array_to_string(p.proconfig,','),'')='search_path=pg_catalog, msbf_ctl, msbf_m2')
   AND bool_and(md5(btrim(regexp_replace(p.prosrc,'\s+',' ','g')))='3277d5b941073aee0b5e52374808ac6d')
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
JOIN pg_catalog.pg_language l ON l.oid=p.prolang
WHERE n.nspname='msbf_ctl'
  AND p.proname='m2_12_reject_g3_archive_mutation'
  AND p.pronargs=0), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0424_ARCHIVE_FUNCTION',
            DETAIL='check_code=P220_PF_0424_ARCHIVE_FUNCTION';
    END IF;
END;
$m212_r8_p220_pf_0424$;

/* R10 GOVERNED STATEMENT 0470 OF 0473
   statement_code: P220_PF_0425_ARCHIVE_TRIGGER
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0425$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
   AND bool_and(t.tgtype=27)
   AND bool_and(t.tgenabled='O')
   AND bool_and(n.nspname='msbf_ctl')
   AND bool_and(p.proname='m2_12_reject_g3_archive_mutation')
   AND bool_and(p.pronargs=0)
FROM pg_catalog.pg_trigger t
JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid
JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
WHERE t.tgrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
  AND NOT t.tgisinternal
  AND t.tgname='trg_m2_12_g3_archive_immutable'), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0425_ARCHIVE_TRIGGER',
            DETAIL='check_code=P220_PF_0425_ARCHIVE_TRIGGER';
    END IF;
END;
$m212_r8_p220_pf_0425$;

/* R10 GOVERNED STATEMENT 0471 OF 0473
   statement_code: P220_PF_0426_EXACT_POLICY_ROW
   phase_code: 05_POSTFLIGHT
   statement_type: POSTFLIGHT_CHECK
   source_authority: M2_12_PROGRAM_220_POSTFLIGHT_EXECUTION_COMPILER.csv
*/
DO $m212_r8_p220_pf_0426$
BEGIN
    IF NOT COALESCE((SELECT count(*)=1
AND bool_and(pp.policy_profile_id=1)
AND bool_and(pp.policy_code=src.policy_code)
AND bool_and(pp.policy_version=src.policy_version)
AND bool_and(pp.policy_status='APPROVED')
AND bool_and(pp.configuration_hash=src.configuration_hash)
AND bool_and(pp.row_hash=src.row_hash)
AND bool_and(pp.accepted_m2_11_project_sha256=src.accepted_m2_11_project_sha256)
AND bool_and(pp.accepted_m2_11_contract_set_hash=src.accepted_m2_11_contract_set_hash)
AND bool_and(pp.accepted_m2_11_combined_set_hash=src.accepted_m2_11_combined_set_hash)
AND bool_and(pp.accepted_m2_11_registry_row_hash=src.accepted_m2_11_registry_row_hash)
AND (SELECT s.last_value=1 AND s.is_called FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq s)
FROM msbf_ctl.m2_12_policy_profile pp
JOIN tmp_src_m2_12_policy_typed src ON src.module1_run_id=pp.module1_run_id
WHERE pp.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND pp.policy_version=1), false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 220 installation postflight failed: P220_PF_0426_EXACT_POLICY_ROW',
            DETAIL='check_code=P220_PF_0426_EXACT_POLICY_ROW';
    END IF;
END;
$m212_r8_p220_pf_0426$;

/* R10 GOVERNED STATEMENT 0472 OF 0473
   statement_code: PRIMARY_RESULT
   phase_code: 06_RESULT
   statement_type: RESULT_SELECT
   source_authority: M2_12_PROGRAM_PRIMARY_RESULT_STATEMENT_COMPILER.csv
*/
SELECT
    'PASS'::text AS "installation_status",
    ctx.run_code::text AS "run_code",
    ctx.run_version::integer AS "run_version",
    21::integer AS "installed_top_level_objects",
    26::integer AS "executable_ddl_statements",
    (SELECT count(*)::integer FROM msbf_ctl.m2_12_policy_profile pp WHERE pp.module1_run_id=ctx.module1_run_id) AS "policy_rows",
    0::integer AS "nonpolicy_rows",
    (SELECT pp.policy_profile_id::bigint FROM msbf_ctl.m2_12_policy_profile pp WHERE pp.module1_run_id=ctx.module1_run_id AND pp.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND pp.policy_version=1) AS "policy_identity",
    p.last_value::text||'|'||p.is_called::text AS "policy_sequence_state",
    'READY_FOR_PROGRAM_221'::text AS "disposition"
FROM tmp_install_m2_12_run_context ctx
CROSS JOIN msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p;

/* R10 GOVERNED STATEMENT 0473 OF 0473
   statement_code: COMMIT
   phase_code: 07_COMMIT
   statement_type: TRANSACTION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
COMMIT;

